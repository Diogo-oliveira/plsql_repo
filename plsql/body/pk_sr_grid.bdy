/*-- Last Change Revision: $Rev: 2027732 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_grid IS

    g_pck_name CONSTANT VARCHAR2(12) := 'PK_SR_GRID';
    g_type_room VARCHAR2(1 CHAR) := 'R';
    g_type_sch  VARCHAR2(1 CHAR) := 'S';
    /********************************************************************************************
    * Obter a o agendamento do dia do Bloco Operatório, independentemente do perfil do
    *   profissional que acede.
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema.
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_grid        Array de agendamentos
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2005/07/11
       ********************************************************************************************/

    FUNCTION get_daily_schedule
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_str TIMESTAMP WITH TIME ZONE;
        l_dt     TIMESTAMP WITH TIME ZONE;
    
    BEGIN
    
        l_dt_str := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL);
    
        --        l_dt := trunc(nvl(i_dt, SYSDATE));
        l_dt := pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_str, current_timestamp), NULL);
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   pk_date_utils.date_char_tsz(i_lang, s.dt_target_tstz, i_prof.institution, i_prof.software) dt_interv_schd,
                   pk_date_utils.date_char_hour_tsz(i_lang, s.dt_target_tstz, i_prof.institution, i_prof.software) hour_interv_schd,
                   pk_date_utils.dt_chr_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) dt_interv_preview,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    s.dt_interv_preview_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_interv_preview,
                   nvl(pk_date_utils.date_char_hour_tsz(i_lang,
                                                        ei.dt_room_entry_tstz,
                                                        i_prof.institution,
                                                        i_prof.software),
                       0) hour_interv_start,
                   nvl(pk_date_utils.get_elapsed_sysdate_tsz(i_lang, ei.dt_room_entry_tstz), 0) dt_elapsed_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   pk_date_utils.date_char_hour_tsz(i_lang, current_timestamp, i_prof.institution, i_prof.software) hour_system,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   --decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) photo,
                   --p.name pat_name,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention, --FSILVA 30-06-2009
                   pl.nick_name prof_leader,
                   pa.nick_name prof_anest,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_room,
                   nvl(sr.flg_status, 'F') room_state,
                   pk_sysdomain.get_img(i_lang, 'ROOM_SCHEDULED.FLG_STATUS', sr.flg_status) room_icon,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) room_abbreviation,
                   pk_translation.get_translation(i_lang, d.code_department) desc_dept_origin,
                   ps.nick_name prof_origin,
                   pk_translation.get_translation(i_lang, sp.code_speciality) || ' / ' || d.abbreviation || ' / ' ||
                   i.abbreviation desc_origin,
                   --RS TIMEZONE
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req) hemo_req_status,
                   --pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   nvl(pk_sysdomain.get_img(i_lang,
                                            'SR_SURGERY_ROOM.FLG_PAT_STATUS',
                                            nvl(ei.flg_pat_status, g_pat_status_pend)),
                       pk_sysdomain.get_img(i_lang, 'SR_SURGERY_ROOM.FLG_PAT_STATUS', g_pat_status_pend)) pat_status,
                   p.id_patient
              FROM schedule_sr      s,
                   patient          p,
                   room             r,
                   speciality       sp,
                   sr_prof_team_det td,
                   professional     pl,
                   --dep_clin_serv    dcs,
                   sr_prof_team_det td2,
                   professional     pa,
                   department       d,
                   institution      i,
                   professional     ps,
                   room_scheduled   sr,
                   --  sr_surgery_record rec,
                   grid_task gt,
                   episode   epis,
                   epis_info ei --sr_intervention it,
             WHERE s.dt_target_tstz BETWEEN l_dt AND l_dt + 0.99999
               AND s.id_institution = i_prof.institution
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND r.id_room(+) = sr.id_room
               AND ei.id_schedule = s.id_schedule
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --AND dcs.id_dep_clin_serv = ei.id_dcs_requested
                  --AND d.id_department = dcs.id_department
               AND d.id_department = epis.id_department_requested
                  --
               AND sp.id_speciality(+) = s.id_speciality
               AND td.id_episode = s.id_episode
               AND td.id_professional = td.id_prof_team_leader
               AND td.id_sr_prof_team_det = (SELECT MIN(id_sr_prof_team_det)
                                               FROM sr_prof_team_det x
                                              WHERE x.id_episode = td.id_episode
                                                AND x.id_professional = x.id_prof_team_leader
                                                AND flg_status = flg_status_a)
               AND pl.id_professional = td.id_prof_team_leader
               AND td2.id_episode = s.id_episode
               AND td2.id_category_sub = g_prof_anest_categ --5 Anestesista
               AND pa.id_professional = td2.id_professional
               AND i.id_institution = ei.id_instit_requested
               AND ps.id_professional = ei.id_prof_schedules
                  --                 and it.id_sr_intervention = s.id_sr_intervention
                  --   AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND epis.id_episode = ei.id_episode
               AND epis.flg_status != g_epis_inactive
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND gt.id_episode(+) = epis.id_episode
             ORDER BY s.dt_interv_preview_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DAILY_SCHEDULE',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Check if the episode needs to be updated.
    *
    * @param      i_lang                  Language ID
    * @param      i_prof                  ALERT Professional    
    * @param      i_n_flg_pat_status      New value for flg_pat_status
    * @param      i_o_flg_pat_status      Old value for flg_pat_status
    * @param      o_upd                   VARCHAR2 - C (cancel admission), A (Create new admission), I (Do nothing)
    * @param      O_ERROR an error message, set when return=false    
    *
    *
    * @return              TRUE/FALSE
    * @author  Ricardo Nuno Almeida
    * @version 2.5.0.7
    * @since   2009/10/23
    **********************************************************************************************/
    FUNCTION check_pat_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_n_flg_pat_status IN sr_pat_status.flg_pat_status%TYPE,
        i_o_flg_pat_status IN sr_pat_status.flg_pat_status%TYPE,
        o_upd              OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CHECK PAT STATUS';
        pk_alertlog.log_debug(g_error, g_package_name);
    
        IF (i_n_flg_pat_status IN (g_pat_status_a, g_pat_status_w, g_pat_status_l, g_pat_status_t) AND
           i_o_flg_pat_status IN (g_pat_status_v,
                                   g_pat_status_p,
                                   g_pat_status_r,
                                   g_pat_status_s,
                                   g_pat_status_f,
                                   g_pat_status_y,
                                   g_pat_status_d))
        THEN
            o_upd := 'C';
        ELSIF (i_n_flg_pat_status IN (g_pat_status_v,
                                      g_pat_status_p,
                                      g_pat_status_r,
                                      g_pat_status_s,
                                      g_pat_status_f,
                                      g_pat_status_y,
                                      g_pat_status_d) AND
              i_o_flg_pat_status IN (g_pat_status_a, g_pat_status_w, g_pat_status_l, g_pat_status_t))
        THEN
            o_upd := 'A';
        ELSE
            o_upd := 'I';
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
                                              'CHECK_PAT_STATUS',
                                              o_error);
            RETURN FALSE;
    END check_pat_status;

    /********************************************************************************************
    * Obter a lista de pacientes com cirurgia em planeamento mas ainda não agendada
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_grid        array de agendamentos
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2005/12/28
       ********************************************************************************************/
    FUNCTION get_grid_pat_in_planning
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Constroi cursor com a grelha de pacientes em planeamento mas sem agendamento
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_episode,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof) pat_age,
                   --decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) photo,
                   -- p.name pat_name,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   --                              pk_translation.get_translation(I_LANG, it.code_sr_intervention) desc_intervention,
                   pk_diagnosis.std_diag_desc(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_id_diagnosis => d.id_diagnosis,
                                              i_code         => d.code_icd,
                                              i_flg_other    => d.flg_other,
                                              i_flg_std_diag => pk_alert_constant.g_yes) desc_diagnosis,
                   pa.nick_name prof_reg,
                   --RS TIMEZONE
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req) hemo_req_status,
                   --pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   p.id_patient
              FROM schedule_sr       s,
                   sr_surgery_record rec,
                   patient           p,
                   professional      pa,
                   institution       i,
                   diagnosis         d,
                   grid_task         gt,
                   episode           epis,
                   epis_info         ei --sr_intervention it,
             WHERE s.id_prof_reg = i_prof.id
               AND s.id_schedule IS NULL
               AND s.id_institution = i_prof.institution
               AND rec.id_schedule_sr = s.id_schedule_sr
               AND rec.flg_state = 'T'
               AND p.id_patient = rec.id_patient
               AND pa.id_professional = s.id_prof_reg
               AND i.id_institution = s.id_institution
               AND d.id_diagnosis = s.id_diagnosis
               AND ei.id_schedule = s.id_schedule
               AND epis.id_episode = ei.id_episode
               AND epis.flg_status != g_epis_inactive
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND gt.id_episode(+) = epis.id_episode;
    
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
                                              'GET_GRID_PAT_IN_PLANNING',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter a o agendamento do dia do Bloco Operatório, para o Auxiliar. Devolve todas as
    *   intervenções do dia do bloco com workflows activos.
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_grid        Array de agendamentos
    * @param o_room        Array de estados possíveis das salas
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/07
       ********************************************************************************************/

    FUNCTION get_grid_aux_all_patients
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_str TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_hand_off_type      sys_config.value%TYPE;
        l_domain_sr_r_status sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_dt_str := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL);
    
        --Obtem os estados possíveis das salas
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT s.desc_val label, s.val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s;
    
        --Se não é passada uma data, assume a data de sistema
        --        l_dt := trunc(nvl(i_dt, SYSDATE));
        l_dt := pk_date_utils.trunc_insttimezone(i_prof, nvl(l_dt_str, current_timestamp), NULL);
    
        --Constroi cursor com a grelha do médico cirurgião
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   pk_date_utils.dt_chr_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) dt_interv_preview,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
                   decode(pk_date_utils.trunc_insttimezone(i_prof, s.dt_interv_preview_tstz, NULL),
                          pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL),
                          pk_date_utils.date_char_hour_tsz(i_lang,
                                                           s.dt_interv_preview_tstz,
                                                           i_prof.institution,
                                                           i_prof.software),
                          pk_date_utils.trunc_dt_char_tsz(i_lang,
                                                          s.dt_interv_preview_tstz,
                                                          i_prof.institution,
                                                          i_prof.software)) hour_interv_preview,
                   nvl(pk_date_utils.date_char_hour_tsz(i_lang,
                                                        st.dt_interv_start_tstz,
                                                        i_prof.institution,
                                                        i_prof.software),
                       0) hour_interv_start,
                   nvl(pk_date_utils.get_elapsed_sysdate_tsz(i_lang, m.dt_status_tstz), 0) dt_elapsed_time,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   p.id_patient,
                   --p.name pat_name,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
                   --decode(pk_patphoto.check_blob(p.id_patient), 'N', '', pk_patphoto.get_pat_foto(p.id_patient, i_prof)) photo,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) photo,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_room,
                   nvl(m.flg_status, 'F') room_status_det,
                   r.id_room,
                   pk_sysdomain.get_img(i_lang, 'SR_ROOM_STATUS.FLG_STATUS', nvl(m.flg_status, 'F')) room_status,
                   --                   to_char(m.dt_status, 'YYYYMMDDHH24MISS') dt_room_status,
                   pk_date_utils.date_send_tsz(i_lang, m.dt_status_tstz, i_prof) dt_room_status,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) room_abbreviation,
                   decode(ei.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, aux.desc_drug_req)
                      FROM dual) desc_drug_req,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, aux.desc_harvest)
                      FROM dual) desc_harvest,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, aux.desc_cli_rec_req)
                      FROM dual) desc_cli_rec_req,
                   (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, aux.desc_mov)
                      FROM dual) desc_mov,
                   gt.supplies desc_supplies,
                   s.flg_status flg_surg_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   gt.hemo_req
              FROM schedule_sr s,
                   --  schedule h,
                   patient        p,
                   room           r,
                   institution    i,
                   room_scheduled sr,
                   -- sr_surgery_record rec,
                   grid_task gt,
                   episode epis,
                   epis_info ei,
                   sys_shortcut sh,
                   v_sr_grid_aux_schedule aux,
                   (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                       FROM room r, sr_room_status s
                      WHERE /*r.id_department = l_sr_dept AND*/
                      s.id_room(+) = r.id_room
                   AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR s.id_sr_room_state IS NULL)) m,
                   (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                      FROM sr_surgery_time st, sr_surgery_time_det std
                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                       AND st.flg_type = flg_interv_start
                       AND std.flg_status = flg_status_a) st
             WHERE s.dt_target_tstz BETWEEN l_dt AND l_dt + 0.99999
               AND s.id_institution = i_prof.institution
               AND aux.id_software = i_prof.software
               AND aux.id_instit_requested = i_prof.institution
               AND m.id_room(+) = r.id_room
               AND s.id_episode = aux.id_episode(+)
                  --               AND h.id_schedule = s.id_schedule
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND r.id_room(+) = sr.id_room
               AND i.id_institution = s.id_institution
                  -- AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND ei.id_schedule(+) = s.id_schedule
               AND epis.id_episode = s.id_episode
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr != g_flg_ehr
               AND gt.id_episode(+) = epis.id_episode
               AND st.id_episode(+) = epis.id_episode
               AND sh.intern_name(+) = 'SR_OK_GRID_AUX'
               AND sh.id_software(+) = i_prof.software
             ORDER BY s.dt_target_tstz;
    
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
                                              'GET_GRID_AUX_ALL_PATIENTS',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
        
    END;

    /**
    * Get a grid's date bounds for a given day.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_dt           grid input date (current date is used when null)
    * @param o_dt_min       minimum date
    * @param o_dt_max       maximum date
    *
    * @author               Elisabete Bugalho
    * @version               2.7.1.0
    * @since                2017/04/10
    */
    PROCEDURE get_date_bounds
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt     IN VARCHAR2,
        o_dt_min OUT schedule_outp.dt_target_tstz%TYPE,
        o_dt_max OUT schedule_outp.dt_target_tstz%TYPE
    ) IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
        o_dt_min       := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                           i_timestamp => nvl(pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                                            i_prof      => i_prof,
                                                                                                            i_timestamp => i_dt,
                                                                                                            i_timezone  => NULL),
                                                                              g_sysdate_tstz));
        -- the date max as to be 23:59:59 (that in seconds is 86399 seconds)                                                                        
        o_dt_max := pk_date_utils.add_to_ltstz(i_timestamp => o_dt_min,
                                               i_amount    => g_day_in_seconds,
                                               i_unit      => 'SECOND');
    
    END get_date_bounds;
    /********************************************************************************************
    * Obter o estado da sala para o episódio
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_room        ID da sala
    * @param i_episode     ID do episódio
    * @param i_dt          Data. se for nula, considera a data de sistema
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/26
       ********************************************************************************************/

    FUNCTION get_room_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_room    IN room.id_room%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt      IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_status  sr_room_status.flg_status%TYPE;
        l_episode episode.id_episode%TYPE;
        l_dt_str  TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_dt_str := pk_date_utils.trunc_insttimezone(i_prof,
                                                     pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt, NULL),
                                                     NULL);
    
        --Obtem o estado da sala
        g_error := 'GET ROOM STATUS';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT s.flg_status
              INTO l_status
              FROM sr_room_status s
             WHERE s.id_room = i_room
               AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR s.id_sr_room_state IS NULL);
        
        EXCEPTION
            WHEN no_data_found THEN
                l_status := NULL;
        END;
    
        --Se existe status para esta sala, obtem o episódio a que pertence
        IF l_status IS NOT NULL
        THEN
            BEGIN
                SELECT s.id_episode
                  INTO l_episode
                  FROM schedule_sr s, room_scheduled r, sr_surgery_record rec
                 WHERE s.dt_target_tstz BETWEEN l_dt_str AND l_dt_str + 0.99999
                   AND r.id_schedule = s.id_schedule
                   AND r.id_room = i_room
                   AND rec.id_schedule_sr = s.id_schedule_sr
                   AND rec.dt_room_exit_tstz IS NULL
                   AND s.dt_target_tstz = (SELECT MIN(s1.dt_target_tstz)
                                             FROM schedule_sr s1, room_scheduled r1, sr_surgery_record rec1
                                            WHERE s.dt_target_tstz BETWEEN l_dt_str AND l_dt_str + 0.99999
                                              AND r1.id_schedule = s1.id_schedule
                                              AND r1.id_room = r.id_room
                                              AND rec1.id_schedule_sr = s1.id_schedule_sr
                                              AND rec1.dt_room_exit_tstz IS NULL);
            
            EXCEPTION
                WHEN too_many_rows THEN
                    l_episode := NULL;
                WHEN no_data_found THEN
                    l_episode := NULL;
            END;
        END IF;
    
        IF l_episode = i_episode
        THEN
            RETURN l_status;
        ELSE
            RETURN NULL;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /********************************************************************************************
    * Obter o agendamento do dia do Bloco Operatório, para o Cirurgião e Anestesista - Vista 1
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema
    * @param i_prof        Id do profissional, instituição e software
    * @param i_type        Indica se se pretende ver apenas os agendamentos aos quais o profissional
    *                       está alocado ou todos os agendamentos. Valores possíveis:
    *                            A - Todos os agendamentos
    *                            P - Agendamentos do profissional
    * 
    * @param o_grid        Array de agendamentos
    * @param o_room        Array de estados possíveis das salas
    * @param o_pat         Array de estados possíveis do paciente
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/12
    * @altered by          Filipe Silva
    * @date                2009/07/29
    * @Notas               ALERT-38050  Se o estado do paciente for S (em cirurgia) e haja registo 
    * de data/hora inicio cirurgia então mostrar a data de cirurgia (sr_surgery_time_det) senão mostra
    * a data/hora da alteração de estado 'S' (sr_pat_status)
       ********************************************************************************************/

    FUNCTION get_grid_surg_v1
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat             category.flg_type%TYPE;
        l_hand_off_type        sys_config.value%TYPE;
        l_dt_min               schedule_sr.dt_target_tstz%TYPE;
        l_dt_max               schedule_sr.dt_target_tstz%TYPE;
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_domain_sr_r_status   sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        --Obtem os estados possíveis das salas
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT s.desc_val label, s.val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s;
    
        --Obtem os estados possíveis do paciente
        g_error := 'GET PAT CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_pat FOR
            SELECT s.desc_val label, s.val data
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_pat_status, NULL)) s;
    
        --Constroi cursor com a grelha do médico cirurgião
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled, --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
                   pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    s.dt_interv_preview_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_interv_preview,
                   nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, i_prof), 0) hour_interv_start,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_sched_room,
                   pk_sysdomain.get_img(i_lang, 'SR_ROOM_STATUS.FLG_STATUS', nvl(m.flg_status, 'F')) room_status,
                   nvl(m.flg_status, 'F') room_status_det,
                   r.id_room,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) photo,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   pk_episode.get_epis_room(i_lang, i_prof, epis.id_episode) desc_room,
                   pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc) desc_drug_presc,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat) desc_exam_req,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat) desc_analysis_req,
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     epis.id_visit,
                                                                                                                     g_task_analysis,
                                                                                                                     l_prof_cat),
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     epis.id_visit,
                                                                                                                     g_task_exam,
                                                                                                                     l_prof_cat),
                                                                                      g_analysis_exam_icon_grid_rank,
                                                                                      pk_alert_constant.g_cat_type_doc)) desc_analysis_exam_req,
                   decode(s.id_episode, m.id_episode, nvl(m.flg_status, 'F'), NULL) room_state,
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req) hemo_req_status,
                   --pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_sysdomain.get_img(i_lang,
                                        'SR_SURGERY_ROOM.FLG_PAT_STATUS',
                                        nvl(rec.flg_pat_status, g_pat_status_pend)) pat_status,
                   nvl(rec.flg_pat_status, g_pat_status_pend) pat_status_det,
                   pk_date_utils.date_send_tsz(i_lang, m.dt_status_tstz, i_prof) dt_room_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               /*BEGIN ALERT-38050*/
                                               decode(rec.flg_pat_status,
                                                      'S',
                                                      nvl(st.dt_interv_start_tstz,
                                                          (SELECT decode(ps.flg_pat_status,
                                                                         g_pat_status_l,
                                                                         ps.dt_status_tstz,
                                                                         g_pat_status_s,
                                                                         ps.dt_status_tstz,
                                                                         NULL) dt_status_tstz
                                                             FROM sr_pat_status ps
                                                            WHERE ps.id_episode = epis.id_episode
                                                              AND ps.flg_pat_status = rec.flg_pat_status
                                                              AND ps.dt_status_tstz =
                                                                  (SELECT MAX(ps1.dt_status_tstz)
                                                                     FROM sr_pat_status ps1
                                                                    WHERE ps1.id_episode = ps.id_episode
                                                                      AND ps1.flg_pat_status = ps.flg_pat_status))),
                                                      (SELECT decode(ps.flg_pat_status,
                                                                     g_pat_status_l,
                                                                     ps.dt_status_tstz,
                                                                     g_pat_status_s,
                                                                     ps.dt_status_tstz,
                                                                     NULL) dt_status_tstz
                                                         FROM sr_pat_status ps
                                                        WHERE ps.id_episode = epis.id_episode
                                                          AND ps.flg_pat_status = rec.flg_pat_status
                                                          AND ps.dt_status_tstz =
                                                              (SELECT MAX(ps1.dt_status_tstz)
                                                                 FROM sr_pat_status ps1
                                                                WHERE ps1.id_episode = ps.id_episode
                                                                  AND ps1.flg_pat_status = ps.flg_pat_status)))
                                               /*END ALERT-38050*/,
                                               i_prof) dt_pat_status,
                   s.flg_status flg_surg_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule),
                          pk_alert_constant.g_no,
                          decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                  i_prof,
                                                                                                  epis.id_episode,
                                                                                                  l_prof_cat,
                                                                                                  l_hand_off_type,
                                                                                                  pk_alert_constant.g_yes),
                                                              i_prof.id),
                                 -1,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) prof_follow_remove
              FROM schedule_sr s,
                   schedule h,
                   patient p,
                   room r,
                   institution i,
                   room_scheduled sr,
                   sr_surgery_record rec,
                   grid_task gt,
                   episode epis,
                   (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                      FROM room r, sr_room_status s
                     WHERE s.id_room(+) = r.id_room
                       AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR
                            s.id_sr_room_state IS NULL)) m,
                   (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                      FROM sr_surgery_time st, sr_surgery_time_det std
                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                       AND st.flg_type = flg_interv_start
                       AND std.flg_status = flg_status_a) st
             WHERE s.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND s.id_institution = i_prof.institution
               AND (((EXISTS (SELECT 1
                                FROM sr_prof_team_det td1
                               WHERE td1.id_episode_context = s.id_episode
                                 AND td1.id_professional = i_prof.id
                                 AND td1.flg_status = g_active) AND i_type = g_my_patients) OR
                   i_prof.id IN
                   (SELECT /*+opt_estimate (table t rows=1)*/
                       column_value
                        FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                        i_prof,
                                                                        epis.id_episode,
                                                                        l_prof_cat,
                                                                        l_hand_off_type,
                                                                        pk_alert_constant.g_yes)) t)) OR
                   (i_type = g_all_patients) OR
                   (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                   pk_alert_constant.g_yes))
               AND h.id_schedule = s.id_schedule
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND r.id_room(+) = sr.id_room
               AND m.id_room(+) = sr.id_room
               AND i.id_institution = s.id_institution
               AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND epis.id_episode = s.id_episode
               AND gt.id_episode(+) = epis.id_episode
               AND st.id_episode(+) = epis.id_episode
               AND epis.flg_ehr != g_flg_ehr -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
             ORDER BY s.dt_target_tstz;
    
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
                                              'GET_GRID_SURG_MY_PATIENTS_V1',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Obter o agendamento do dia do Bloco Operatório, para o Cirurgião e Anestesista - Vista 2
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema
    * @param i_prof        Id do profissional, instituição e software
    * @param i_type        Indica se se pretende ver apenas os agendamentos aos quais o profissional
    *                       está alocado ou todos os agendamentos. Valores possíveis:
    *                            A - Todos os agendamentos
    *                            P - Agendamentos do profissional
    * 
    * @param o_grid        Array de agendamentos
    * @param o_room        Array de estados possíveis das salas
    * @param o_pat         Array de estados possíveis do paciente
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/12
       ********************************************************************************************/

    FUNCTION get_grid_surg_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hand_off_type sys_config.value%TYPE;
        l_prof_cat      category.flg_type%TYPE;
    
        l_dt_min               schedule_sr.dt_target_tstz%TYPE;
        l_dt_max               schedule_sr.dt_target_tstz%TYPE;
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_domain_sr_r_status   sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        --Obtem os estados possíveis das salas
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT s.desc_val label, s.val data, s.img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s;
    
        --Obtem os estados possíveis do paciente
        g_error := 'GET PAT CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_pat FOR
            SELECT s.desc_val label, s.val data, s.img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_pat_status, NULL)) s;
    
        --Constroi cursor com a grelha do médico cirurgião
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    s.dt_interv_preview_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_interv_preview,
                   nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, i_prof), 0) hour_interv_start,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_room,
                   sr.flg_status room_status,
                   r.id_room,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) photo,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, s.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   pk_sr_clinical_info.get_summary_diagnosis(i_lang, i_prof, s.id_episode) desc_diagnosis,
                   pk_sr_tools.get_team_profissional(i_lang, i_prof, epis.id_episode) prof_name,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   NULL desc_obs,
                   s.flg_status flg_surg_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   '(' || pk_sr_tools.get_epis_team_number(i_lang, i_prof, epis.id_episode) || ')' team_number,
                   pk_sr_tools.get_principal_team(i_lang, i_prof, epis.id_episode) desc_team,
                   pk_sr_tools.get_team_grid_tooltip(i_lang, i_prof, epis.id_episode) name_prof_tooltip,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule),
                          pk_alert_constant.g_no,
                          decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                  i_prof,
                                                                                                  epis.id_episode,
                                                                                                  l_prof_cat,
                                                                                                  l_hand_off_type,
                                                                                                  pk_alert_constant.g_yes),
                                                              i_prof.id),
                                 -1,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) prof_follow_remove
              FROM schedule_sr s,
                   schedule h,
                   patient p,
                   room r,
                   room_scheduled sr,
                   episode epis,
                   sr_surgery_record rec,
                   (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                      FROM room r, sr_room_status s
                     WHERE s.id_room(+) = r.id_room
                       AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR
                            s.id_sr_room_state IS NULL)) m,
                   (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                      FROM sr_surgery_time st, sr_surgery_time_det std
                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                       AND st.flg_type = flg_interv_start
                       AND std.flg_status = flg_status_a) st
             WHERE s.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND s.id_institution = i_prof.institution
               AND (((EXISTS (SELECT 1
                                FROM sr_prof_team_det td1
                               WHERE td1.id_episode_context = s.id_episode
                                 AND td1.id_professional = i_prof.id
                                 AND td1.flg_status = g_active) AND i_type = g_my_patients) OR
                   i_prof.id IN
                   (SELECT /*+opt_estimate (table t rows=1)*/
                       column_value
                        FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                        i_prof,
                                                                        epis.id_episode,
                                                                        l_prof_cat,
                                                                        l_hand_off_type,
                                                                        pk_alert_constant.g_yes)) t)) OR
                   (i_type = g_all_patients) OR
                   (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                   pk_alert_constant.g_yes))
               AND h.id_schedule = s.id_schedule
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND sr.id_room = m.id_room(+)
               AND r.id_room(+) = sr.id_room
               AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND epis.id_episode = s.id_episode
               AND st.id_episode(+) = epis.id_episode
               AND epis.flg_ehr != g_flg_ehr -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
             ORDER BY s.dt_target_tstz;
    
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
                                              'GET_GRID_SURG_MY_PATIENTS_V2',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_pat);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Obter a informação relativa à equipa de profissionais agendados para um episódio de cirurgia.
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_prof        Array de profissionais agendados para um episódio
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/12
       ********************************************************************************************/

    FUNCTION get_grid_prof_team_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Abre o cursor
        g_error := 'OPEN PROF DESC CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_prof FOR
            SELECT td.id_sr_prof_team_det,
                   td.id_professional,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) professional_photo,
                   p.nick_name prof_name,
                   pk_translation.get_translation(i_lang, cs.code_category_sub) catg_desc,
                   pk_translation.get_translation(i_lang, s.code_speciality) speciality_desc
              FROM sr_prof_team_det td, category_sub cs, professional p, speciality s
             WHERE td.id_episode = i_episode
               AND p.id_professional = td.id_professional
               AND cs.id_category_sub = td.id_category_sub
               AND s.id_speciality(+) = p.id_speciality
               AND td.flg_status = flg_status_a
             ORDER BY cs.rank;
    
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
                                              'GET_GRID_PROF_TEAM_DESC',
                                              o_error);
            pk_types.open_my_cursor(o_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados,
    *  para pessoal clínico (médicos e enfermeiros) - VISTA 1
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/08/23
    * @altered by               Filipe Silva
    * @date                     2009/07/07
    * @Notas                    Change the date format because the grid is too small (ALERT - 29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_surg_actv_v1
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(32000);
    
        l_prof_cat category.flg_type%TYPE;
    
        l_hand_off_type sys_config.value%TYPE;
    
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => 'DATE_FORMAT_M011');
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show              := 'N';
        g_sysdate               := SYSDATE;
        g_sysdate_tstz          := current_timestamp;
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                g_error := 'call pk_search.get_criteria_condition';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_SURG_ACTV_V1',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT COUNT(DISTINCT EPIS.ID_EPISODE) ' || 'from schedule_sr sp,  patient pat, room r, ' ||
                   'room_scheduled sr,  ' || 'grid_task gt, episode epis,  ' || 'epis_info ei, ' ||
                   'sr_room_status s, ' ||
                   '( select std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' ||
                   'from sr_surgery_time st, sr_surgery_time_det std ' ||
                   'where st.ID_SR_SURGERY_TIME = std.id_sr_surgery_time ' || 'and st.FLG_TYPE = ''' ||
                   flg_interv_start || '''' || 'and std.FLG_STATUS=''' || flg_status_a || ''' ) st, ' ||
                   'clin_record cr, professional p, sr_prof_team_det spt ' || 'where sp.id_institution = :1 ' ||
                   'and pat.id_patient = sp.id_patient ' || 'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' || 'and r.id_room(+) = sr.id_room ' ||
                   'AND (s.id_room(+) = r.id_room and (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) FROM sr_room_status s1 WHERE s1.id_room = s.id_room) ' ||
                   'OR NOT EXISTS (SELECT 1 FROM sr_room_status s1 WHERE s1.id_room = s.id_room))) ' ||
                   'and ei.id_episode = sp.id_episode ' || 'and epis.id_episode = sp.id_episode  ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                   'and epis.flg_status = :2 ' || 'and gt.id_episode (+) = epis.id_episode ' ||
                   'and cr.id_patient(+) = pat.id_patient ' || 'and cr.id_institution(+) = :4 ' ||
                   'and spt.id_episode(+) = epis.id_episode ' || 'and spt.flg_status(+) =''' || flg_status_a || ''' ' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and st.id_episode(+) = epis.id_episode ' || 'and sp.flg_status = ''' || g_active || ''' ' ||
                   'and sp.dt_target_tstz is not null ' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE ' || i_prof.institution || ',' || g_active || ',' || i_prof.institution || ',' ||
                   i_prof.institution || ',' || i_prof.institution || ',' || i_prof.software;
    
        pk_alertlog.log_info(text            => 'call pk_sr_grid.get_search_grid_surg_actv_v1' || g_error,
                             object_name     => 'PK_SR_GRID',
                             sub_object_name => 'get_search_grid_surg_actv_v1');
    
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.institution, g_active, i_prof.institution;
    
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'select t.id_schedule_sp id_schedule, ' || -- EMR-1491
                   't.id_episode_sp id_episode, ' || --
                   'decode(t.flg_urgency, ''Y'', ''U'', decode(t.id_sched_sr_parent, null, ''N'', ''R'')) flg_rescheduled, ' || --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), t.dt_interv_preview_tstz, null), ' || --
                   'pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), current_timestamp, null), ' || --
                   'pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_interv_preview_tstz, new PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), ' || --
                   ' pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_interv_preview_tstz, new PROFISSIONAL( ' ||
                   i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                   ' ))) hour_interv_preview_send, ' || --                  
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), t.dt_interv_preview_tstz, null), ' || --
                   'pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), current_timestamp, null), ' || --
                   'pk_date_utils.date_char_hour_tsz(' || i_lang || ', t.dt_interv_preview_tstz, ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   'pk_date_utils.to_char_insttimezone(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.dt_interv_preview_tstz, ''' ||
                   l_date_format_m011 || ''')) hour_interv_preview, ' || --
                   'pk_date_utils.to_char_insttimezone(' || i_lang || ',profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ',' || i_prof.software || '), t.dt_interv_preview_tstz, ''' ||
                   l_date_format_m011 || ''') short_dt_interv,' || --                   
                   'nvl(pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_interv_start_tstz, PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.software || ',' || i_prof.institution || ')), 0) hour_interv_start,  ' || --
                   'nvl(t.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', t.code_abbreviation)) desc_sched_room,  ' || --
                   'pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_ROOM_STATUS.FLG_STATUS'', nvl(t.flg_status_s, ''F'')) room_status, ' || --
                   'nvl(t.flg_status_s, ''F'') room_status_det, ' || -- 
                   't.id_room, ' || -- 
                  --LMAIA 16-05-2009
                   'pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', t.gender,' || i_lang || ') gender, ' || --
                  -- END
                   'pk_patient.get_pat_age(' || i_lang || ', t.id_patient, ' || i_prof.institution || ', ' ||
                   i_prof.software || ') pat_age, ' || --
                   'pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), t.id_patient, t.id_episode_e, t.id_schedule_sr) photo, ' || --
                   't.id_patient, ' || --
                   'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), t.id_patient, t.id_episode_e, t.id_schedule_sr) pat_name, ' || --
                   'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), t.id_patient, t.id_episode_e) name_pat_to_sort, ' || --
                   'pk_patient.get_julian_age(' || i_lang || ', t.dt_birth, t.age) pat_age_for_order_by, ' || --
                   'pk_hand_off_api.get_resp_icons(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.id_episode_e, ''' || l_hand_off_type ||
                   ''') resp_icons, ' || 'pk_adt.get_pat_non_disc_options(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.id_patient) pat_ndo, ' || --
                   'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.id_patient) pat_nd_icon, ' || --
                   'nvl(pk_sr_clinical_info.get_proposed_surgery  (' || i_lang || ', t.id_episode_e, profissional(' ||
                   i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '),''' ||
                   pk_alert_constant.g_no || '''), ' || -- FSILVA
                   '        pk_message.get_message(' || i_lang || ', ''SR_LABEL_T347''))     desc_intervention, ' || --
                   '''' || g_date_hour_send_format || ''' dt_server, ' || --
                   'pk_episode.get_epis_room(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), id_episode_e) desc_room, ' || --
                   'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.drug_presc) desc_drug_presc, ' || --
                   'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.ID_VISIT, ''' || g_task_exam || ''',''' ||
                   l_prof_cat || ''') DESC_EXAM_REQ, ' || 'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), t.ID_VISIT, ''' ||
                   g_task_analysis || ''',''' || l_prof_cat || ''') DESC_ANALYSIS_REQ, ' || --                   
                   'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ',
                                                           profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '),
                                                          pk_grid.get_prioritary_task(' || i_lang || ',
                                                                                      PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                                                                                      pk_grid.visit_grid_task_str_nc(' ||
                   i_lang || ',
                                                                                                                     PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                                                                                                                     id_visit,
                                                                                                                     ''' ||
                   g_task_analysis || ''',
                                                                                                                     ''' ||
                   l_prof_cat ||
                   '''),
                                                                                      pk_grid.visit_grid_task_str_nc(' ||
                   i_lang || ',
                                                                                                                     PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                                                                                                                     id_visit,
                                                                                                                     ''' ||
                   g_task_exam || ''',
                                                                                                                     ''' ||
                   l_prof_cat ||
                   '''),
                                                                                      ''' ||
                   g_analysis_exam_icon_grid_rank || ''',
                                                                                      ''' ||
                   pk_alert_constant.g_cat_type_doc || ''')) desc_analysis_exam_req, ' || --
                   'decode(t.id_episode_sp, t.id_episode_s, nvl(t.flg_status_s, ''F''), null)  room_state, ' || --
                   'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), t.hemo_req ) hemo_req_status, ' || --
                   'pk_supplies_external_api_db.get_surg_supplies_reg(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '),t.id_episode_e,t.material_req) material_req_status, ' || --
                   'pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_SURGERY_ROOM.FLG_PAT_STATUS'', nvl(t.flg_pat_status,  ''' || g_pat_status_pend ||
                   ''')) pat_status, ' || -- 
                   'nvl(t.flg_pat_status,  ''' || g_pat_status_pend || ''') pat_status_det, ' || --
                   'pk_date_utils.date_send_tsz(' || i_lang || ', t.dt_status_tstz, profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || ')) dt_room_status,  ' || --
                   'pk_date_utils.to_char_insttimezone(profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || '), (select decode(ps.flg_pat_status, ''' || g_pat_status_l ||
                   ''', ps.dt_status_tstz, ''' || g_pat_status_s ||
                   ''', ps.dt_status_tstz, null)  from sr_pat_status ps  ' ||
                   '        where ps.id_episode = t.id_episode_e ' ||
                   '        and ps.flg_pat_status = t.flg_pat_status ' ||
                   '        and ps.dt_status_tstz = (select max(ps1.dt_status_tstz) from sr_pat_status ps1 ' ||
                   '                               where ps1.id_episode = ps.id_episode ' ||
                   '                               and ps1.flg_pat_status = ps.flg_pat_status)), null) dt_pat_status, ' ||
                   't.flg_status_sp flg_surg_status, t.dt_begin_tstz ' ||
                  --outer select
                   'from (SELECT DISTINCT sp.id_schedule id_schedule_sp, sp.id_episode id_episode_sp, ei.flg_urgency, sp.id_sched_sr_parent, sp.dt_interv_preview_tstz, ' ||
                   'st.dt_interv_start_tstz, r.desc_room_abbreviation, r.code_abbreviation, s.flg_status flg_status_s, r.id_room, ' ||
                   'pat.gender, pat.id_patient, sr.id_schedule id_schedule_sr, pat.dt_birth, pat.age, epis.id_episode id_episode_e, ' ||
                   'gt.drug_presc, epis.id_visit, s.id_episode id_episode_s, gt.hemo_req, epis.id_episode id_episode_ei, ' ||
                   'gt.material_req, ei.flg_pat_status, s.dt_status_tstz, sp.flg_status flg_status_sp, epis.dt_begin_tstz ' ||
                  --inner select
                   ' from schedule_sr sp,  patient pat, room r, room_scheduled sr,  ' ||
                   'grid_task gt, episode epis, professional p, sr_prof_team_det spt, ' || 'epis_info ei, ' ||
                   'sr_room_status s, ' ||
                   '( select std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' ||
                   'from sr_surgery_time st, sr_surgery_time_det std ' ||
                   'where st.ID_SR_SURGERY_TIME = std.id_sr_surgery_time ' || 'and st.FLG_TYPE = ''' ||
                   flg_interv_start || '''' || 'and std.FLG_STATUS=''' || flg_status_a || ''' ) st, ' ||
                   'clin_record cr ' || 'where sp.id_institution = ' || i_prof.institution || ' ' ||
                   'and pat.id_patient = sp.id_patient ' || 'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' || 'and r.id_room(+) = sr.id_room ' ||
                   'AND (s.id_room(+) = r.id_room and (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) FROM sr_room_status s1 WHERE s1.id_room = s.id_room) ' ||
                   'OR NOT EXISTS (SELECT 1 FROM sr_room_status s1 WHERE s1.id_room = s.id_room))) ' ||
                   'and ei.id_episode = sp.id_episode ' || 'and epis.id_episode = sp.id_episode ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                   'and epis.flg_status = ''' || g_active || '''' || ' ' || 'and gt.id_episode (+) = epis.id_episode ' ||
                   'and cr.id_patient(+) = pat.id_patient ' || 'and cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                   'and spt.id_episode(+) = epis.id_episode ' || 'and spt.flg_status(+) =''' || flg_status_a || '''' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and st.id_episode (+) = epis.id_episode ' || 'and sp.flg_status = ''' || g_active || '''' ||
                   ' and sp.dt_target_tstz is not null ' || l_where || ') t ORDER BY T.DT_BEGIN_TSTZ ';
    
        OPEN o_pat FOR aux_sql;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_ACTV_V1', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_ACTV_V1', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_SURG_ACTV_V1',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados,
    *  para pessoal clínico (médicos e enfermeiros) - VISTA 2
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/08/23
    * @altered by               Filipe Silva
    * @date                     2009/07/07
    * @Notas                    Change the date format because the grid is too small (ALERT-29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_surg_actv_v2
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(32000);
    
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_external_sys  VARCHAR2(4000 CHAR) := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => 'DATE_FORMAT_M011');
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show              := 'N';
        g_sysdate               := SYSDATE;
        g_sysdate_tstz          := current_timestamp;
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error := 'SET WHERE';
            pk_alertlog.log_debug(g_error);
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                g_error := 'CALL PK_SEARCH.GET_CRITERIA_CONDITION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_SURG_ACTV_V2',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'select COUNT(EPIS.ID_EPISODE) from schedule_sr sp,  patient pat, room r, ' || 'room_scheduled sr,' ||
                   'episode epis, professional p, sr_prof_team_det spt, epis_ext_sys ees, ' || 'epis_info ei, ' ||
                   '(select r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' ||
                   'from room r, sr_room_status s ' || 'where s.id_room(+) = r.id_room ' ||
                   'and (s.id_sr_room_state = (select max(id_sr_room_state) from sr_room_status s1 where s1.id_room = s.id_room) ' ||
                   'or not exists (select 1 from sr_room_status s1 where s1.id_room = s.id_room))) m, ' ||
                   '( select std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' ||
                   'from sr_surgery_time st, sr_surgery_time_det std ' ||
                   'where st.ID_SR_SURGERY_TIME = std.id_sr_surgery_time ' || 'and st.FLG_TYPE = ''' ||
                   flg_interv_start || '''' || 'and std.FLG_STATUS=''' || flg_status_a || ''' ) st, ' ||
                   '( select distinct id_patient, id_institution, num_clin_record from clin_record ) cr, pat_soc_attributes psa ' ||
                   'where sp.id_institution = ' || i_prof.institution || ' ' || 'and pat.id_patient = sp.id_patient ' ||
                   'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' || 'and r.id_room(+) = sr.id_room ' ||
                   'and m.id_room(+) = r.id_room ' || 'and ei.id_episode(+) = sp.id_episode ' ||
                   'and epis.id_episode = sp.id_episode ' || 'and epis.flg_status = ''' || g_active || '''' || ' ' ||
                   'and psa.id_patient (+) = pat.id_patient ' || ' and psa.id_institution(+) = ' || i_prof.institution ||
                   'and cr.id_patient(+) = pat.id_patient ' || 'and cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                   'and spt.id_episode(+) = epis.id_episode ' || 'and spt.flg_status(+)=''' || flg_status_a || '''' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and ees.id_episode(+) = epis.id_episode ' || 'and ees.id_institution(+) = ' || i_prof.institution ||
                   ' and ees.id_external_sys(+) = ' || l_id_external_sys || ' ' ||
                   'and st.id_episode (+) = epis.id_episode ' || 'and sp.flg_status = ''' || g_active || '''' ||
                   'and sp.dt_target_tstz is not null ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --'and v.id_visit = epis.id_visit ' ||
                   l_where || ' ORDER BY EPIS.DT_BEGIN_TSTZ ';
    
        g_error := 'GET EXECUTE IMMEDIATE';
        pk_alertlog.log_debug(g_error);
        EXECUTE IMMEDIATE aux_sql
            INTO l_count;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'select sp.id_schedule, sp.id_episode, ' ||
                   'decode(ei.flg_urgency, ''Y'', ''U'', decode(sp.id_sched_sr_parent, null, ''N'', ''R'')) flg_rescheduled, ' || --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), sp.dt_interv_preview_tstz, null), ' ||
                   'pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), current_timestamp, null), pk_date_utils.date_send_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz,new PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || ' pk_date_utils.date_send_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz, new PROFISSIONAL( ' || i_prof.id || ', ' || i_prof.institution || ', ' ||
                   i_prof.software || ' ))) hour_interv_preview_send, ' ||
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), sp.dt_interv_preview_tstz), ' ||
                   'pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), current_timestamp, null), pk_date_utils.date_char_hour_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz, ' || i_prof.institution || ', ' || i_prof.software || '), ' ||
                   'pk_date_utils.to_char_insttimezone(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), sp.dt_interv_preview_tstz,''' ||
                   l_date_format_m011 || ''')) hour_interv_preview, ' || --
                   'pk_date_utils.to_char_insttimezone(' || i_lang || ',profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ',' || i_prof.software || '), sp.dt_interv_preview_tstz, ''' ||
                   l_date_format_m011 || ''') short_dt_interv,' || --
                   'nvl(pk_date_utils.date_send_tsz(' || i_lang || ', st.dt_interv_start_tstz, PROFISSIONAL(' ||
                   i_prof.id || ',' || i_prof.software || ',' || i_prof.institution || ')), 0) hour_interv_start,  ' ||
                   'nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) desc_room,  ' || 'sr.flg_status room_status, ' || 'r.id_room, ' || --
                  --LMAIA 16-05-2009
                  --'pat.gender, ' || --
                   'pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender,' || i_lang || ') gender, ' || --
                  -- END
                   'pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                   i_prof.software || ') pat_age, ' ||
                  --'decode(pk_patphoto.check_blob(pat.id_patient), ''N'', '''', pk_patphoto.get_pat_foto(pat.id_patient, ' ||
                  --i_prof.institution || ', ' || i_prof.software || ')) photo, ' || 'pat.id_patient, ' ||
                   'pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), pat.id_patient, epis.id_episode, sp.id_schedule) photo, ' || --
                   'pat.id_patient, ' ||
                  --'pat.name pat_name, ' || 
                   'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), pat.id_patient, epis.id_episode, sp.id_schedule) pat_name, ' || --
                   'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), pat.id_patient, epis.id_episode) name_pat_to_sort, ' || --
                   'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || -- 
                   'pk_hand_off_api.get_resp_icons(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), epis.id_episode, ''' || l_hand_off_type ||
                   ''') resp_icons, ' || 'pk_adt.get_pat_non_disc_options(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_ndo, ' || --
                   'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_nd_icon, ' || --
                   'nvl(pk_sr_clinical_info.get_proposed_surgery  (' || i_lang || ', epis.id_episode, profissional(' ||
                   i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '),''' ||
                   pk_alert_constant.g_no || '''), ' || '        pk_message.get_message(' || i_lang ||
                   ', ''SR_LABEL_T347''))     desc_intervention, ' || 'pk_sr_clinical_info.get_summary_diagnosis(' ||
                   i_lang || ', PROFISSIONAL(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                   '), sp.id_episode) desc_diagnosis, ' || 'nvl(pk_date_utils.date_send_tsz(' || i_lang ||
                   ', ei.dt_room_entry_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.software || ',' ||
                   i_prof.institution || ')), 0) hour_interv_start_send,  ' || --para obter a data de início da cirurgia
                   '''' || g_date_hour_send_format || ''' dt_server, ' ||
                  -- 
                   'pk_sr_tools.get_team_profissional(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), epis.id_episode) prof_name, ' || --
                   'concat(concat(''('', ' || 'to_char(pk_sr_tools.get_epis_team_number(' || i_lang ||
                   ', profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software ||
                   '), epis.id_episode))),' || ''')'')' || ' team_number, ' || --
                   'pk_sr_tools.get_principal_team(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), epis.id_episode) desc_team, ' || --
                   'pk_sr_tools.get_team_grid_tooltip(' || i_lang || ', profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || '), epis.id_episode) name_prof_tooltip, ' || --
                  --                                       
                   'null desc_obs, ' || 'sp.flg_status flg_surg_status ' ||
                   'from schedule_sr sp,  patient pat, room r, room_scheduled sr, ' || --visit v, 
                   'episode epis, professional p, sr_prof_team_det spt, epis_ext_sys ees, epis_info ei, ' ||
                   '(select r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' ||
                   'from room r, sr_room_status s ' ||
                  --'where r.id_department = ' || l_sr_dept || ' ' ||
                   'where s.id_room(+) = r.id_room ' ||
                   'and (s.id_sr_room_state = (select max(id_sr_room_state) from sr_room_status s1 where s1.id_room = s.id_room) ' ||
                   'or not exists (select 1 from sr_room_status s1 where s1.id_room = s.id_room))) m, ' ||
                   '( select std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' ||
                   'from sr_surgery_time st, sr_surgery_time_det std ' ||
                   'where st.ID_SR_SURGERY_TIME = std.id_sr_surgery_time ' || 'and st.FLG_TYPE = ''' ||
                   flg_interv_start || '''' || 'and std.FLG_STATUS=''' || flg_status_a || ''' ) st, ' ||
                   '( select distinct id_patient, id_institution, num_clin_record from clin_record ) cr, pat_soc_attributes psa ' ||
                   'where sp.id_institution = ' || i_prof.institution || ' ' || 'and pat.id_patient = sp.id_patient ' ||
                   'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' || 'and r.id_room(+) = sr.id_room ' ||
                   'and m.id_room(+) = r.id_room ' || 'and ei.id_episode(+) = sp.id_episode ' ||
                   'and epis.id_episode = sp.id_episode ' || 'and epis.flg_status = ''' || g_active || '''' || ' ' ||
                   'and psa.id_patient (+) = pat.id_patient ' || ' and psa.id_institution(+) = ' || i_prof.institution ||
                   'and cr.id_patient(+) = pat.id_patient ' || 'and cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                   'and spt.id_episode(+) = epis.id_episode ' || 'and spt.flg_status(+)=''' || flg_status_a || '''' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and ees.id_episode(+) = epis.id_episode ' || 'and ees.id_institution(+) = ' || i_prof.institution ||
                   ' and ees.id_external_sys(+) = ' || l_id_external_sys || ' ' ||
                   'and st.id_episode (+) = epis.id_episode ' || 'and sp.flg_status = ''' || g_active || '''' ||
                   'and sp.dt_target_tstz is not null ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --'and v.id_visit = epis.id_visit ' ||
                   l_where || ' ORDER BY EPIS.DT_BEGIN_TSTZ ';
    
        OPEN o_pat FOR aux_sql;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_ACTV_V2', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_ACTV_V2', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_SURG_ACTV_V2',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados,
    *  para pessoal clínico (médicos e enfermeiros) - VISTA 1
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/08/23
    * @altered by                Filipe Silva
    * @date                      2009/07/07
    * @Notas                     Change the date format because the grid is too small (ALERT-29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_surg_inactv_v1
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        l_from       VARCHAR2(32767);
        l_hint       VARCHAR2(32767);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(32000);
    
        l_prof_cat category.flg_type%TYPE;
    
        l_grp_insts     table_number;
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_external_sys  VARCHAR2(4000 CHAR) := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => 'DATE_FORMAT_M011');
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show              := 'N';
        g_sysdate               := SYSDATE;
        g_sysdate_tstz          := current_timestamp;
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error := 'SET WHERE';
            pk_alertlog.log_debug(g_error);
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                g_error := 'CALL PK_SEARCH.GET_CRITERIA_CONDITION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_SURG_INACTV_V1',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            
                g_error := 'GET FROM';
                IF NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                          i_crit_val => i_crit_val,
                                          i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          o_from     => l_from,
                                          o_hint     => l_hint)
                THEN
                    l_from := NULL;
                END IF;
            END IF;
        END LOOP;
    
        IF l_from IS NULL
        THEN
            l_from := ' JOIN patient pat ON pat.id_patient = t.id_patient ';
        END IF;
    
        g_error := 'GET INSTs GRP';
        pk_alertlog.log_debug(g_error);
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
    
        aux_sql := 'SELECT COUNT(epis.id_episode) ' || --
                   '  FROM schedule_sr t ' || l_from || --
                   '  JOIN institution i ' || --
                   '    ON i.id_institution = t.id_institution ' || --
                   '  JOIN epis_info ei ' || --
                   '    ON ei.id_episode = t.id_episode ' || --
                   '  JOIN episode epis ' || --
                   '    ON epis.id_episode = t.id_episode ' || --
                   '  LEFT JOIN room_scheduled sr ' || --
                   '    ON sr.id_schedule = t.id_schedule ' || --
                   '  LEFT JOIN room r ' || --
                   '    ON r.id_room = sr.id_room ' || --
                   '  LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '               FROM room r ' || --
                   '               LEFT JOIN sr_room_status s ' || --
                   '                 ON s.id_room = r.id_room ' || --
                   '              WHERE (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                             FROM sr_room_status s1 ' || --
                   '                                            WHERE s1.id_room = s.id_room) OR NOT EXISTS ' || --
                   '                     (SELECT 1 ' || --
                   '                        FROM sr_room_status s1 ' || --
                   '                       WHERE s1.id_room = s.id_room))) m ' || --
                   '    ON m.id_room = r.id_room ' || --
                   '  LEFT JOIN diagnosis d ' || --
                   '    ON d.id_diagnosis = t.id_diagnosis ' || --
                   '  LEFT JOIN grid_task gt ' || --
                   '    ON gt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN pat_soc_attributes psa ' || --
                   '    ON psa.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN (SELECT DISTINCT id_patient, id_institution, num_clin_record ' || --
                   '               FROM clin_record) cr ' || --
                   '    ON cr.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN sr_prof_team_det spt ' || --
                   '    ON spt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN epis_ext_sys ees ' || --
                   '    ON ees.id_episode = epis.id_episode ' || --
                   ' WHERE t.id_institution IN (SELECT * ' || --
                   '                              FROM TABLE(:1)) ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = t.id_schedule)) ' || --
                   '   AND epis.flg_status = :2 ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:3)) OR psa.id_institution IS NULL) ' || --
                   '   AND (cr.id_institution IN (SELECT * ' || --
                   '                                FROM TABLE(:4)) OR cr.id_institution IS NULL) ' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || flg_status_a || ''')) ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:5)) OR ees.id_institution IS NULL) ' || --
                   '   AND (ees.id_external_sys = ' || l_id_external_sys || ' OR ees.id_external_sys IS NULL) ' ||
                   l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        pk_alertlog.log_debug(g_error);
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING l_grp_insts, pk_alert_constant.g_inactive, l_grp_insts, l_grp_insts, l_grp_insts;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT t.id_schedule, ' || --
                   '       t.id_episode, ' || --
                   '       decode(ei.flg_urgency, ''Y'', ''U'', decode(t.id_sched_sr_parent, NULL, ''N'', ''R'')) flg_rescheduled, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               t.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          t.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          t.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '))) hour_interv_preview_send, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               t.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_char_hour_tsz(' || i_lang || ', t.dt_interv_preview_tstz, ' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '              pk_date_utils.to_char_insttimezone(' || i_lang || ', ' || --
                   '                                                 profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                 t.dt_interv_preview_tstz, ' || --
                   '                                                 ''' || l_date_format_m011 ||
                   ''')) hour_interv_preview, ' || --
                   '       pk_date_utils.to_char_insttimezone(' || i_lang || ', ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          t.dt_interv_preview_tstz, ' || --
                   '                                          ''' || l_date_format_m011 || ''') short_dt_interv, ' || --
                   '       nvl(pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                       st.dt_interv_start_tstz, ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || --
                   '           0) hour_interv_start, ' || --
                   '       nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) desc_sched_room, ' || --
                   '       pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_ROOM_STATUS.FLG_STATUS'', nvl(m.flg_status, ''F'')) room_status, ' || --
                   '       nvl(m.flg_status, ''F'') room_status_det, ' || --
                   '       r.id_room, ' || --
                   '       pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                   '       pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ',' ||
                   i_prof.software || ') pat_age, ' || --
                   '       pk_patphoto.get_pat_photo(' || i_lang || ', ' || --
                   '                                 profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                 pat.id_patient, ' || --
                   '                                 epis.id_episode, ' || --
                   '                                 t.id_schedule) photo, ' || --
                   '       pat.id_patient, ' || --
                   '       pk_patient.get_pat_name(' || i_lang || ', ' || --
                   '                               profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                               pat.id_patient, ' || --
                   '                               epis.id_episode, ' || --
                   '                               t.id_schedule) pat_name, ' || --
                   '       pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient, ' || --
                   '                                       epis.id_episode) name_pat_to_sort, ' || --
                   '       pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                   '       pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || --
                   '                                      profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                      epis.id_episode, ' || --
                   '                                      ''' || l_hand_off_type || ''') resp_icons, ' || --
                   '       pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient) pat_ndo, ' || --
                   '       pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          pat.id_patient) pat_nd_icon, ' || --
                   '       pk_sr_clinical_info.get_proposed_surgery(' || i_lang || ', ' || --
                   '                                                epis.id_episode, ' || --
                   '                                                profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                ''' || pk_alert_constant.g_no ||
                   ''') desc_intervention, ' || --
                   '       ''' || g_date_hour_send_format || ''' dt_server, ' || --
                   '       pk_episode.get_epis_room(' || i_lang || ', ' || --
                   '                                profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                epis.id_episode) desc_room, ' || --
                   '       pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', ' || --
                   '                                              profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                              gt.drug_presc) desc_drug_presc, ' || --
                   '       pk_grid.visit_grid_task_str(' || i_lang || ', ' || --
                   '                                   profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                   epis.id_visit, ' || --
                   '                                   ''' || g_task_exam || ''', ' || --
                   '                                   ''' || l_prof_cat || ''') desc_exam_req, ' || --
                   '       pk_grid.visit_grid_task_str(' || i_lang || ', ' || --
                   '                                   profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                   epis.id_visit, ' || --
                   '                                   ''' || g_task_analysis || ''', ' || --
                   '                                   ''' || l_prof_cat || ''') desc_analysis_req, ' || --
                   '       pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', ' || --
                   '                                              profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                              pk_grid.get_prioritary_task(' || i_lang || ', ' || --
                   '                                                                          profissional(' ||
                   i_prof.id || ', ' || --
                   '                                                                                       ' ||
                   i_prof.institution || ', ' || --
                   '                                                                                       ' ||
                   i_prof.software || '), ' || --
                   '                                                                          pk_grid.visit_grid_task_str_nc(' ||
                   i_lang || ', ' || --
                   '                                                                                                         profissional(' ||
                   i_prof.id || ', ' || --
                   '                                                                                                                      ' ||
                   i_prof.institution || ', ' || --
                   '                                                                                                                      ' ||
                   i_prof.software || '), ' || --
                   '                                                                                                         epis.id_visit, ' || --
                   '                                                                                                         ''' ||
                   g_task_analysis || ''', ' || --
                   '                                                                                                         ''' ||
                   l_prof_cat || '''), ' || --
                   '                                                                          pk_grid.visit_grid_task_str_nc(' ||
                   i_lang || ', ' || --
                   '                                                                                                         profissional(' ||
                   i_prof.id || ', ' || --
                   '                                                                                                                      ' ||
                   i_prof.institution || ', ' || --
                   '                                                                                                                      ' ||
                   i_prof.software || '), ' || --
                   '                                                                                                         epis.id_visit, ' || --
                   '                                                                                                         ''' ||
                   g_task_exam || ''', ' || --
                   '                                                                                                         ''' ||
                   l_prof_cat || '''), ' || --
                   '                                                                          ''' ||
                   g_analysis_exam_icon_grid_rank || ''', ' || --
                   '                                                                          ''' ||
                   pk_alert_constant.g_cat_type_doc || ''')) desc_analysis_exam_req, ' || --
                   '       decode(t.id_episode, m.id_episode, nvl(m.flg_status, ''F''), NULL) room_state, ' || --
                   '       pk_grid.convert_grid_task_str(' || i_lang || ', ' || --
                   '                                     profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                     gt.hemo_req) hemo_req_status, ' || --
                   '       pk_supplies_external_api_db.get_surg_supplies_reg(' || i_lang || ', ' || --
                   '                                                         profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                         epis.id_episode, ' || --
                   '                                                         gt.material_req) material_req_status, ' || --
                   '       pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_SURGERY_ROOM.FLG_PAT_STATUS'', nvl(ei.flg_pat_status, ''' || g_pat_status_pend ||
                   ''')) pat_status, ' || --
                   '       nvl(ei.flg_pat_status, ''' || g_pat_status_pend || ''') pat_status_det, ' || --
                   '       pk_date_utils.to_char_insttimezone(profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          (SELECT decode(ps.flg_pat_status, ' || --
                   '                                                         ''' || g_pat_status_l || ''', ' || --
                   '                                                         ps.dt_status_tstz, ' || --
                   '                                                         ''' || g_pat_status_s || ''', ' || --
                   '                                                         ps.dt_status_tstz, ' || --
                   '                                                         NULL) ' || --
                   '                                             FROM sr_pat_status ps ' || --
                   '                                            WHERE ps.id_episode = epis.id_episode ' || --
                   '                                              AND ps.flg_pat_status = ei.flg_pat_status ' || --
                   '                                              AND ps.dt_status_tstz = ' || --
                   '                                                  (SELECT MAX(ps1.dt_status_tstz) ' || --
                   '                                                     FROM sr_pat_status ps1 ' || --
                   '                                                    WHERE ps1.id_episode = ps.id_episode ' || --
                   '                                                      AND ps1.flg_pat_status = ps.flg_pat_status)), ' || --
                   '                                          NULL) dt_pat_status, ' || --
                   '       t.flg_status flg_surg_status ' || --
                   '  FROM schedule_sr t ' || l_from || --
                   '  JOIN institution i ' || --
                   '    ON i.id_institution = t.id_institution ' || --
                   '  JOIN episode epis ' || --
                   '    ON epis.id_episode = t.id_episode ' || --
                   '  JOIN epis_info ei ' || --
                   '    ON ei.id_episode = t.id_episode ' || --
                   '  LEFT JOIN grid_task gt ' || --
                   '    ON gt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN room_scheduled sr ' || --
                   '    ON sr.id_schedule = t.id_schedule ' || --
                   '  LEFT JOIN room r ' || --
                   '    ON r.id_room = sr.id_room ' || --
                   '  LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '               FROM room r ' || --
                   '               LEFT JOIN sr_room_status s ' || --
                   '                 ON s.id_room = r.id_room ' || --
                   '              WHERE (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                             FROM sr_room_status s1 ' || --
                   '                                            WHERE s1.id_room = s.id_room) OR NOT EXISTS ' || --
                   '                     (SELECT 1 ' || --
                   '                        FROM sr_room_status s1 ' || --
                   '                       WHERE s1.id_room = s.id_room))) m ' || --
                   '    ON m.id_room = r.id_room ' || --
                   '  LEFT JOIN (SELECT DISTINCT id_patient, num_clin_record ' || --
                   '               FROM clin_record ' || --
                   '              WHERE id_institution IN (SELECT * ' || --
                   '                                         FROM TABLE(:1))) cr ' || --
                   '    ON cr.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' || --
                   '               FROM sr_surgery_time st, sr_surgery_time_det std ' || --
                   '              WHERE st.id_sr_surgery_time = std.id_sr_surgery_time ' || --
                   '                AND st.flg_type = ''' || flg_interv_start || '''' || --
                   '                AND std.flg_status = ''' || flg_status_a || ''') st ' || --
                   '    ON st.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN sr_prof_team_det spt ' || --
                   '    ON spt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN pat_soc_attributes psa ' || --
                   '    ON psa.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN epis_ext_sys ees ' || --
                   '    ON ees.id_episode = epis.id_episode ' || --
                   ' WHERE t.id_institution IN (SELECT * ' || --
                   '                              FROM TABLE(:2)) ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = t.id_schedule)) ' || --
                   '   AND epis.flg_status = ''' || pk_alert_constant.g_inactive || ''' ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:3)) OR psa.id_institution IS NULL) ' || --
                   '   AND (spt.flg_status = ''' || flg_status_a || ''' OR spt.flg_status IS NULL) ' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || flg_status_a || ''')) ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:4)) OR ees.id_institution IS NULL) ' || --
                   '   AND (ees.id_external_sys = ' || l_id_external_sys || ' OR ees.id_external_sys IS NULL) ' ||
                   l_where || --
                   ' ORDER BY epis.dt_begin_tstz ';
    
        OPEN o_pat FOR aux_sql
            USING l_grp_insts, l_grp_insts, l_grp_insts, l_grp_insts;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_INACTV_V1', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_INACTV_V1', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_SURG_INACTV_V1',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_search_grid_surg_inactv_v1;

    /********************************************************************************************
    * Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados,
    *  para pessoal clínico (médicos e enfermeiros) - VISTA 2
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/08/23
    * @altered by                Filipe Silva
    * @date                      2009/07/07
    * @Notas                     Change the date format because the grid is too small (ALERT-29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_surg_inactv_v2
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        l_from       VARCHAR2(32767);
        l_hint       VARCHAR2(32767);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.value%TYPE;
        aux_sql      VARCHAR2(32000);
    
        l_grp_insts     table_number;
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_external_sys  VARCHAR2(4000 CHAR) := pk_sysconfig.get_config('ID_EXTERNAL_SYS',
                                                                          i_prof.institution,
                                                                          i_prof.software);
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang, 'DATE_FORMAT_M011');
    
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show              := 'N';
        g_sysdate               := SYSDATE;
        g_sysdate_tstz          := current_timestamp;
        l_limit                 := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error := 'SET WHERE';
            pk_alertlog.log_debug(g_error);
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                g_error := 'call pk_search.get_criteria_condition';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_SURG_INACTV_V2',
                                                      o_error);
                
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            
                g_error := 'GET FROM';
                IF NOT pk_search.get_from(i_criteria => i_id_sys_btn_crit,
                                          i_crit_val => i_crit_val,
                                          i_lang     => i_lang,
                                          i_prof     => i_prof,
                                          o_from     => l_from,
                                          o_hint     => l_hint)
                THEN
                    l_from := NULL;
                END IF;
            END IF;
        END LOOP;
    
        IF l_from IS NULL
        THEN
            l_from := ' JOIN patient pat ON pat.id_patient = sp.id_patient ';
        END IF;
    
        g_error := 'GET INSTs GRP';
        pk_alertlog.log_debug(g_error);
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT COUNT(epis.id_episode) ' || --
                   '  FROM schedule_sr sp ' || l_from || --
                   '  JOIN institution i ' || --
                   '    ON i.id_institution = sp.id_institution ' || --
                   '  JOIN epis_info ei ' || --
                   '    ON ei.id_episode = sp.id_episode ' || --
                   '  JOIN episode epis ' || --
                   '    ON epis.id_episode = sp.id_episode ' || --
                   '  LEFT JOIN room_scheduled sr ' || --
                   '    ON sr.id_schedule = sp.id_schedule ' || --
                   '  LEFT JOIN room r ' || --
                   '    ON r.id_room = sr.id_room ' || --
                   '  LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '               FROM room r ' || --
                   '               LEFT JOIN sr_room_status s ' || --
                   '                 ON s.id_room = r.id_room ' || --
                   '              WHERE (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                             FROM sr_room_status s1 ' || --
                   '                                            WHERE s1.id_room = s.id_room) OR NOT EXISTS ' || --
                   '                     (SELECT 1 ' || --
                   '                        FROM sr_room_status s1 ' || --
                   '                       WHERE s1.id_room = s.id_room))) m ' || --
                   '    ON m.id_room = r.id_room ' || --
                   '  LEFT JOIN diagnosis d ' || --
                   '    ON d.id_diagnosis = sp.id_diagnosis ' || --
                   '  LEFT JOIN grid_task gt ' || --
                   '    ON gt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN pat_soc_attributes psa ' || --
                   '    ON psa.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN (SELECT DISTINCT id_patient, id_institution, num_clin_record ' || --
                   '               FROM clin_record) cr ' || --
                   '    ON cr.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN sr_prof_team_det spt ' || --
                   '    ON spt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN epis_ext_sys ees ' || --
                   '    ON ees.id_episode = epis.id_episode ' || --
                   ' WHERE sp.id_institution IN (SELECT * ' || --
                   '                              FROM TABLE(:1)) ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = sp.id_schedule)) ' || --
                   '   AND epis.flg_status = :2 ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:3)) OR psa.id_institution IS NULL) ' || --
                   '   AND (cr.id_institution IN (SELECT * ' || --
                   '                                FROM TABLE(:4)) OR cr.id_institution IS NULL) ' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || flg_status_a || ''')) ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:5)) OR ees.id_institution IS NULL) ' || --
                   '   AND (ees.id_external_sys = ' || l_id_external_sys || ' OR ees.id_external_sys IS NULL) ' ||
                   l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE 1';
        pk_alertlog.log_debug(g_error);
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING l_grp_insts, pk_alert_constant.g_inactive, l_grp_insts, l_grp_insts, l_grp_insts;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT sp.id_schedule, ' || --
                   '       sp.id_episode, ' || --
                   '       decode(ei.flg_urgency, ''Y'', ''U'', decode(sp.id_sched_sr_parent, NULL, ''N'', ''R'')) flg_rescheduled, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               sp.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          sp.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          sp.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '))) hour_interv_preview_send, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               sp.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_char_hour_tsz(' || i_lang || ', sp.dt_interv_preview_tstz, ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || --
                   '              pk_date_utils.to_char_insttimezone(' || i_lang || ', ' || --
                   '                                                 profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                 sp.dt_interv_preview_tstz, ' || --
                   '                                                 ''' || l_date_format_m011 ||
                   ''')) hour_interv_preview, ' || --
                   '       pk_date_utils.to_char_insttimezone(' || i_lang || ', ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          sp.dt_interv_preview_tstz, ' || --
                   '                                          ''' || l_date_format_m011 || ''') short_dt_interv, ' || --
                   '       nvl(pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                       st.dt_interv_start_tstz, ' || --
                   '                                       profissional(' || i_prof.id || ', ' || i_prof.software || ', ' ||
                   i_prof.institution || ')), ' || --
                   '           0) hour_interv_start, ' || --
                   '       nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) desc_room, ' || --
                   '       sr.flg_status room_status, ' || --
                   '       r.id_room, ' || --
                   '       pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                   '       pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                   i_prof.software || ') pat_age, ' || --
                   '       pk_patphoto.get_pat_photo(' || i_lang || ', ' || --
                   '                                 profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                 pat.id_patient, ' || --
                   '                                 epis.id_episode, ' || --
                   '                                 sp.id_schedule) photo, ' || --
                   '       pat.id_patient, ' || --
                   '       pk_patient.get_pat_name(' || i_lang || ', ' || --
                   '                               profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                               pat.id_patient, ' || --
                   '                               epis.id_episode, ' || --
                   '                               sp.id_schedule) pat_name, ' || --
                   '       pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient, ' || --
                   '                                       epis.id_episode) name_pat_to_sort, ' || --
                   '       pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                   '       pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || --
                   '                                      profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                      epis.id_episode, ' || --
                   '                                      ''' || l_hand_off_type || ''') resp_icons, ' || --
                   '       pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient) pat_ndo, ' || --
                   '       pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          pat.id_patient) pat_nd_icon, ' || --
                   '       nvl(pk_sr_clinical_info.get_proposed_surgery(' || i_lang || ', ' || --
                   '                                                    epis.id_episode, ' || --
                   '                                                    profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                    ''' || pk_alert_constant.g_no || '''), ' || --
                   '           pk_message.get_message(' || i_lang || ', ''SR_LABEL_T347'')) desc_intervention, ' || --
                   '       pk_sr_clinical_info.get_summary_diagnosis(' || i_lang || ', ' || --
                   '                                                 profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                 sp.id_episode) desc_diagnosis, ' || --
                   '       ''' || g_date_hour_send_format || ''' dt_server, ' || --
                   '       pk_sr_tools.get_team_profissional(' || i_lang || ', ' || --
                   '                                         profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                         epis.id_episode) prof_name, ' || --
                   '       concat(concat(''('', ' || --
                   '                     to_char(pk_sr_tools.get_epis_team_number(' || i_lang || ', ' || --
                   '                                                              profissional(' || i_prof.id || ', ' || --
                   '                                                                           ' || i_prof.institution || ', ' || --
                   '                                                                           ' || i_prof.software ||
                   '), ' || --
                   '                                                              epis.id_episode))), ' || --
                   '              '')'') team_number, ' || --                 
                   '       pk_sr_tools.get_principal_team(' || i_lang || ', ' || --
                   '                                      profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                      epis.id_episode) desc_team, ' || --
                   '       pk_sr_tools.get_team_grid_tooltip(' || i_lang || ', ' || --
                   '                                         profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                         epis.id_episode) name_prof_tooltip, ' || --
                   '       NULL desc_obs, ' || --
                   '       sp.flg_status flg_surg_status ' || --
                  
                   '  FROM schedule_sr sp ' || l_from || --
                   '  JOIN institution i ' || --
                   '    ON i.id_institution = sp.id_institution ' || --
                   '  JOIN episode epis ' || --
                   '    ON epis.id_episode = sp.id_episode ' || --
                   '  JOIN epis_info ei ' || --
                   '    ON ei.id_episode = sp.id_episode ' || --
                   '  LEFT JOIN grid_task gt ' || --
                   '    ON gt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN room_scheduled sr ' || --
                   '    ON sr.id_schedule = sp.id_schedule ' || --
                   '  LEFT JOIN room r ' || --
                   '    ON r.id_room = sr.id_room ' || --
                   '  LEFT JOIN (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '               FROM room r ' || --
                   '               LEFT JOIN sr_room_status s ' || --
                   '                 ON s.id_room = r.id_room ' || --
                   '              WHERE (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                             FROM sr_room_status s1 ' || --
                   '                                            WHERE s1.id_room = s.id_room) OR NOT EXISTS ' || --
                   '                     (SELECT 1 ' || --
                   '                        FROM sr_room_status s1 ' || --
                   '                       WHERE s1.id_room = s.id_room))) m ' || --
                   '    ON m.id_room = r.id_room ' || --
                   '  LEFT JOIN (SELECT DISTINCT id_patient, num_clin_record ' || --
                   '               FROM clin_record ' || --
                   '              WHERE id_institution IN (SELECT * ' || --
                   '                                         FROM TABLE(:1))) cr ' || --
                   '    ON cr.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' || --
                   '               FROM sr_surgery_time st, sr_surgery_time_det std ' || --
                   '              WHERE st.id_sr_surgery_time = std.id_sr_surgery_time ' || --
                   '                AND st.flg_type = ''' || flg_interv_start || '''' || --
                   '                AND std.flg_status = ''' || flg_status_a || ''') st ' || --
                   '    ON st.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN sr_prof_team_det spt ' || --
                   '    ON spt.id_episode = epis.id_episode ' || --
                   '  LEFT JOIN pat_soc_attributes psa ' || --
                   '    ON psa.id_patient = pat.id_patient ' || --
                   '  LEFT JOIN epis_ext_sys ees ' || --
                   '    ON ees.id_episode = epis.id_episode ' || --
                   ' WHERE sp.id_institution IN (SELECT * ' || --
                   '                              FROM TABLE(:2)) ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = sp.id_schedule)) ' || --
                   '   AND epis.flg_status = ''' || pk_alert_constant.g_inactive || ''' ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:3)) OR psa.id_institution IS NULL) ' || --
                   '   AND (spt.flg_status = ''' || flg_status_a || ''' OR spt.flg_status IS NULL) ' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || flg_status_a || ''')) ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:4)) OR ees.id_institution IS NULL) ' || --
                   '   AND (ees.id_external_sys = ' || l_id_external_sys || ' OR ees.id_external_sys IS NULL) ' ||
                   l_where || --
                   ' ORDER BY epis.dt_begin_tstz ';
    
        g_error := 'GET EXECUTE IMMEDIATE 2';
        OPEN o_pat FOR aux_sql
            USING l_grp_insts, l_grp_insts, l_grp_insts, l_grp_insts;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_INACTV_V2', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_SURG_INACTV_V2', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_SURG_INACTV_V2',
                                              o_error);
        
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Guarda o estado de um paciente. O estado do paciente é guardado na tabela de histórico de estados, 
    * de forma a permitir a consulta posterior do tempo em que um paciente esteve em cada estado. 
    * O seu estado actual é também guardado na tabela SR_SURGERY_RECORD.
    *
    * @param i_lang               Id do idioma
    * @param i_prof               Id do profissional, instituição e software
    * @param i_episode            Id do episódio
    * @param i_flg_status_new     Estado actual do paciente
    * @param i_flg_status_old     Anterior estado do paciente
    * @param i_test               Indica se deve validar o o estado do paciente
    * 
    * @param o_flg_show           Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title          Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text           Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button             Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error              Mensagem de erro
    *
    * @return                     TRUE/FALSE
    *
    * @author                     Rui Batista
    * @since                      2006/06/09
    *
    * @alter                      José Brito
    * @since                      2008/08/29
    *
    * @alter                      José Antunes
    * @since                      2008/11/05
       ********************************************************************************************/
    FUNCTION call_set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_cancel_notes   IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
        i_transaction_id IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_error VARCHAR2(2000);
    
        l_rows               table_varchar;
        l_rowsei             table_varchar;
        srg_exception        EXCEPTION;
        l_id_schedule        schedule_sr.id_schedule%TYPE;
        l_id_schedule_sr     schedule_sr.id_schedule_sr%TYPE;
        l_id_pos_consult_req sr_pos_schedule.id_pos_consult_req%TYPE;
        l_upd                VARCHAR2(1);
        l_flg_sched          schedule_sr.flg_sched%TYPE;
    
        l_id_patient       patient.id_patient%TYPE;
        l_id_dep_clin_serv sys_config.value%TYPE;
        l_dt_pos_suggested VARCHAR2(4000);
        l_req_notes        sr_pos_schedule.req_notes%TYPE;
        l_transaction_id   VARCHAR2(4000);
    
        l_ext_value          epis_ext_sys.value%TYPE;
        l_external_sys_exist sys_config.value%TYPE := pk_sysconfig.get_config('EXTERNAL_SYSTEM_EXIST', i_prof);
        l_id_ext_sys         sys_config.value%TYPE := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof);
        l_exists_ext         VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_epis_type          episode.id_epis_type%TYPE;
        l_flg_ehr            episode.flg_ehr%TYPE;
    
    BEGIN
    
        --raise_application_error(-20001, 'teste');
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Insere o novo estado do paciente na tabela de histórico, se o estado foi alterado
        IF nvl(i_flg_status_new, '@') != nvl(i_flg_status_old, '@')
        THEN
        
            --Valida o novo estado
            g_error := 'VALIDATE NEW PATIENT STATUS';
            pk_alertlog.log_debug(g_error);
            IF i_test = 'Y'
            THEN
                g_error := 'call pk_sr_grid.val_pat_status for id_episode: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_grid.val_pat_status(i_lang      => i_lang,
                                                 i_episode   => i_episode,
                                                 i_prof      => i_prof,
                                                 i_status    => i_flg_status_new,
                                                 o_flg_show  => o_flg_show,
                                                 o_msg_title => o_msg_title,
                                                 o_msg_text  => o_msg_text,
                                                 o_button    => o_button,
                                                 o_error     => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CALL_SET_PAT_STATUS',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                --Se a validação encontrou potenciais problemas sai para mostrar a mensagem
                IF o_flg_show = 'Y'
                THEN
                    RETURN TRUE;
                END IF;
            END IF;
        
            g_error := 'INSERT SR_PAT_STATUS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO sr_pat_status
                (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
            VALUES
                (seq_sr_pat_status.nextval, i_episode, i_prof.id, i_flg_status_new, g_sysdate_tstz);
        
            --Actualiza estado actual
            g_error := 'UPDATE SR_SURGERY_RECORD';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_surgery_record
               SET flg_pat_status = i_flg_status_new
             WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                        FROM schedule_sr
                                       WHERE id_episode = i_episode);
        
            g_error := 'call ts_epis_info.upd for id_episode: ' || i_episode;
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in     => i_episode,
                             flg_pat_status_in => i_flg_status_new,
                             flg_status_nin    => FALSE,
                             rows_out          => l_rowsei);
        
            g_error := 'FETCH ID_SCHEDULE, ID_SCHEDULE_SR, ID_PATIENT ';
            pk_alertlog.log_debug(g_error);
            SELECT id_schedule, id_schedule_sr, id_patient
              INTO l_id_schedule, l_id_schedule_sr, l_id_patient
              FROM schedule_sr
             WHERE id_episode = i_episode;
        
            -- Se o novo estado do paciente é 'Cirurgia cancelada', actualiza o estado do episódio para Cancelado e cancela o agendamento.
            IF i_flg_status_new = g_pat_status_c
            THEN
                g_error := 'UPDATE EPISODE';
                pk_alertlog.log_debug(g_error);
                /* <DENORM Fábio> */
                l_rows := table_varchar();
                ts_episode.upd(id_episode_in      => i_episode,
                               flg_status_in      => i_flg_status_new,
                               id_prof_cancel_in  => i_prof.id,
                               dt_cancel_tstz_in  => g_sysdate_tstz,
                               flg_status_nin     => FALSE,
                               id_prof_cancel_nin => FALSE,
                               dt_cancel_tstz_nin => FALSE,
                               rows_out           => l_rows);
            
                g_error := 'CALL PROCESS_UPDATE FOR EPISODE TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_CANCEL',
                                                                              'DT_CANCEL_TSTZ'));
            
                -- Telmo 30-08-2010. To ensure the following cancel works, we need to de-register first. If it was not registered, 
                -- no error is returned.
                g_error := 'FETCH ID_SCHEDULE';
                pk_alertlog.log_debug(g_error);
                SELECT id_schedule, a.flg_sched
                  INTO l_id_schedule, l_flg_sched
                  FROM schedule_sr a
                 WHERE id_episode = i_episode;
            
                -- get id_patient foist
                g_error := 'FETCH ID_PATIENT';
                pk_alertlog.log_debug(g_error);
                SELECT id_patient, a.id_epis_type, a.flg_ehr
                  INTO l_id_patient, l_epis_type, l_flg_ehr
                  FROM episode a
                 WHERE id_episode = i_episode;
            
                g_error := 'call pk_schedule_api_upstream.cancel_scheduler_registration for id_schedule: ' ||
                           l_id_schedule || ' and id_transaction : ' || l_transaction_id;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_api_upstream.cancel_scheduler_registration(i_lang           => i_lang,
                                                                              i_prof           => i_prof,
                                                                              i_id_schedule    => l_id_schedule,
                                                                              i_id_patient     => l_id_patient,
                                                                              i_transaction_id => l_transaction_id,
                                                                              o_error          => o_error)
                THEN
                    RAISE srg_exception;
                END IF;
            
                -- Removida chamada à função PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULE no ambito de ALERT-278978
            
                g_error := 'UPDATE SCHEDULE_SR';
                pk_alertlog.log_debug(g_error);
                l_rows := table_varchar();
            
                g_error := 'call ts_schedule_sr.upd for id_schedule: ' || l_id_schedule;
                pk_alertlog.log_debug(g_error);
                ts_schedule_sr.upd(id_sr_cancel_reason_in  => i_cancel_reason,
                                   id_sr_cancel_reason_nin => FALSE,
                                   notes_cancel_in         => i_cancel_notes,
                                   notes_cancel_nin        => FALSE,
                                   where_in                => 'id_schedule = ' || l_id_schedule ||
                                                              ' AND flg_status = ''' ||
                                                              pk_schedule.g_sched_status_cancelled || '''',
                                   rows_out                => l_rows);
            
                IF l_flg_sched = pk_alert_constant.g_no
                THEN
                    ts_schedule_sr.upd(id_sr_cancel_reason_in  => i_cancel_reason,
                                       id_sr_cancel_reason_nin => FALSE,
                                       notes_cancel_in         => i_cancel_notes,
                                       notes_cancel_nin        => FALSE,
                                       flg_status_in           => pk_schedule.g_sched_status_cancelled,
                                       flg_status_nin          => FALSE,
                                       
                                       where_in => 'id_schedule = ' || l_id_schedule,
                                       rows_out => l_rows);
                END IF;
            
                g_error := 'CALL PROCESS_UPDATE FOR SCHEDULE_SR TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SCHEDULE_SR',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('ID_SR_CANCEL_REASON', 'NOTES_CANCEL'));
            
                g_error := 'Remove POS CONSULT_REQ';
                pk_alertlog.log_debug(g_error);
                BEGIN
                    SELECT id_pos_consult_req
                      INTO l_id_pos_consult_req
                      FROM (SELECT sps.id_pos_consult_req,
                                   rank() over(ORDER BY sps.dt_req DESC, sps.dt_reg DESC) rank_origin
                            
                              FROM sr_pos_schedule sps
                             WHERE sps.id_schedule_sr = l_id_schedule_sr)
                     WHERE rank_origin = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_id_pos_consult_req := NULL;
                END;
            
                IF l_id_pos_consult_req IS NOT NULL
                THEN
                    g_error := 'CALL PK_SR_POS.SET_POS_APPOINTMENT_REQ FOR ID_POS_CONSULT_REQ: ' ||
                               l_id_pos_consult_req;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_pos.set_pos_appointment_req(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_patient          => NULL,
                                                             i_episode          => NULL,
                                                             i_flg_edit         => pk_sr_pos.g_flg_remove,
                                                             i_dep_clin_serv    => NULL,
                                                             i_dt_scheduled_str => NULL,
                                                             i_notes_req        => NULL,
                                                             io_consult_req     => l_id_pos_consult_req,
                                                             o_error            => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                END IF;
            
                g_error := 'CALL PK_SR_SURG_RECORD.SET_SURG_PROCESS_STATUS FOR ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => pk_sr_approval.g_cancel_surgery,
                                                                 o_error   => o_error)
                THEN
                    RAISE srg_exception;
                END IF;
            
                g_error := 'CALL TS_EPIS_INFO.UPD FOR ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                ts_epis_info.upd(id_episode_in       => i_episode,
                                 flg_dsch_status_in  => i_flg_status_new,
                                 flg_dsch_status_nin => FALSE,
                                 rows_out            => l_rowsei);
            
                --Call ALERT_INTER event cancel
                alert_inter.pk_ia_event_schedule.surgery_request_cancel(i_id_institution => i_prof.institution,
                                                                        i_id_schedule_sr => l_id_schedule_sr);
            
            ELSE
            
                g_error := 'CALL CHECK_PAT_STATUS';
                pk_alertlog.log_debug(g_error);
                IF NOT check_pat_status(i_lang, i_prof, i_flg_status_new, i_flg_status_old, l_upd, o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                IF l_upd = 'A'
                THEN
                    g_error := 'CALL pk_sr_visit.set_epis_admission for id_episode: ' || i_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_visit.set_epis_admission(i_lang  => i_lang,
                                                          i_prof  => i_prof,
                                                          i_epis  => i_episode,
                                                          o_error => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                ELSIF l_upd = 'C'
                THEN
                    g_error := 'CALL pk_sr_visit.cancel_epis_admission for id_episode: ' || i_episode;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_visit.cancel_epis_admission(i_lang  => i_lang,
                                                             i_prof  => i_prof,
                                                             i_epis  => i_episode,
                                                             o_error => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            
            END IF;
        
            -- Se o estado anterior era Cirurgia Cancelada, tem que reactivar o episódio e o agendamento
            IF i_flg_status_old = g_pat_status_c
            THEN
                g_error := 'UPDATE EPISODE';
                /* <DENORM Fábio> */
                l_rows  := table_varchar();
                g_error := 'CALL ts_episode.upd for id_episode: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                ts_episode.upd(id_prof_cancel_in => CAST(NULL AS NUMBER), id_prof_cancel_nin => FALSE, dt_cancel_tstz_in => CAST(NULL AS TIMESTAMP WITH LOCAL TIME ZONE), dt_cancel_tstz_nin => FALSE, flg_status_in => flg_status_a, flg_status_nin => FALSE, rows_out => l_rows, where_in => 'id_episode = ' || i_episode || ' AND flg_status = ''' || flg_status_c || '''');
            
                g_error := 'PROCESS_UPDATE FOR EPISODE TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPISODE',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_CANCEL',
                                                                              'DT_CANCEL_TSTZ'));
            
                g_error := 'UPDATE SCHEDULE_SR FLG_STATUS';
                pk_alertlog.log_debug(g_error);
                l_rows := table_varchar();
                ts_schedule_sr.upd(flg_status_in      => flg_status_a,
                                   flg_status_nin     => FALSE,
                                   id_prof_cancel_in  => NULL,
                                   id_prof_cancel_nin => FALSE,
                                   dt_cancel_tstz_in  => NULL,
                                   dt_cancel_tstz_nin => FALSE,
                                   where_in           => 'id_episode = ' || i_episode || ' AND flg_status = ''' ||
                                                         flg_status_c || '''',
                                   rows_out           => l_rows);
            
                g_error := 'PROCESS_UPDATE FOR SCHEDULE_SR TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'SCHEDULE_SR',
                                              i_rowids       => l_rows,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_CANCEL',
                                                                              'DT_CANCEL_TSTZ'));
            
                g_error := 'UPDATE SCHEDULE';
                pk_alertlog.log_debug(g_error);
                UPDATE schedule
                   SET flg_status = flg_status_a, id_prof_cancel = NULL, dt_cancel_tstz = NULL
                 WHERE id_schedule = (SELECT id_schedule
                                        FROM schedule_sr
                                       WHERE id_episode = i_episode);
            
                g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.reactivate_canceled_sched';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_api_upstream.reactivate_canceled_sched(i_lang           => i_lang,
                                                                          i_prof           => i_prof,
                                                                          i_id_schedule    => l_id_schedule,
                                                                          i_transaction_id => l_transaction_id,
                                                                          o_error          => o_error)
                THEN
                    RAISE srg_exception;
                END IF;
            
                g_error := 'Add POS CONSULT_REQ';
                pk_alertlog.log_debug(g_error);
                SELECT sps.id_pos_consult_req,
                       pk_sysconfig.get_config('POS_ID_DEP_CLIN_SERV', i_prof),
                       pk_date_utils.date_send_tsz(i_lang, sps.dt_pos_suggested, i_prof),
                       sps.req_notes
                  INTO l_id_pos_consult_req, l_id_dep_clin_serv, l_dt_pos_suggested, l_req_notes
                  FROM (SELECT sps1.id_pos_consult_req,
                               sps1.req_notes,
                               sps1.dt_pos_suggested,
                               sps1.id_sr_pos_schedule,
                               rank() over(ORDER BY sps1.dt_req DESC, sps1.dt_reg DESC) rank_sps
                          FROM sr_pos_schedule sps1
                         WHERE sps1.id_schedule_sr = l_id_schedule_sr) sps
                 WHERE sps.rank_sps = 1;
            
                IF l_id_pos_consult_req IS NOT NULL
                THEN
                    g_error := 'CALL pk_sr_pos.set_pos_appointment_req for id_pos_consult_req: ' ||
                               l_id_pos_consult_req;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_sr_pos.set_pos_appointment_req(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_patient          => l_id_patient,
                                                             i_episode          => i_episode,
                                                             i_flg_edit         => pk_sr_pos.g_flg_edit,
                                                             i_dep_clin_serv    => l_id_dep_clin_serv,
                                                             i_dt_scheduled_str => l_dt_pos_suggested,
                                                             i_notes_req        => l_req_notes,
                                                             io_consult_req     => l_id_pos_consult_req,
                                                             o_error            => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                END IF;
            END IF;
        
            -- REGISTER (efectivar) SCHEDULE IN SCHEDULER 
            g_error := 'REGISTER IN SCHEDULER';
            pk_alertlog.log_debug(g_error);
            IF i_flg_status_new <> g_pat_status_a
            THEN
                SELECT id_patient
                  INTO l_id_patient
                  FROM episode
                 WHERE id_episode = i_episode;
            
                g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.REGISTER_SCHEDULE';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                                  i_prof           => i_prof,
                                                                  i_id_schedule    => l_id_schedule,
                                                                  i_id_patient     => l_id_patient,
                                                                  i_transaction_id => l_transaction_id,
                                                                  o_error          => o_error)
                THEN
                    RAISE srg_exception;
                END IF;
            END IF;
        
            --Actualiza data da última intercção do episódio
            g_error := 'UPDATE DT_LAST_INTERACTION';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.c_update_dt_last_interaction(i_lang    => i_lang,
                                                             i_episode => i_episode,
                                                             i_dt_last => g_sysdate_tstz,
                                                             o_error   => o_error)
            THEN
            
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CALL_SET_PAT_STATUS',
                                                  o_error);
                RETURN FALSE;
            END IF;
        
            --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
            IF nvl(i_episode, 0) != 0
               AND i_prof.id IS NOT NULL
            THEN
                g_error := 'UPDATE EPIS_PROF_REC';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_visit.call_set_epis_prof_rec(i_lang     => i_lang,
                                                       i_prof     => i_prof,
                                                       i_episode  => i_episode,
                                                       i_patient  => NULL,
                                                       i_flg_type => g_flg_type_rec,
                                                       o_error    => o_error)
                THEN
                
                    --ROLLBACK;
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CALL_SET_PAT_STATUS',
                                                      o_error);
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'CALL TO PK_SR_APPROVAL.CHECK_CHANGE_STATUS';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_approval.check_change_status(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_episode    => i_episode,
                                                      i_old_status => i_flg_status_old,
                                                      i_new_status => i_flg_status_new,
                                                      o_error      => o_error)
            THEN
                RAISE srg_exception;
            END IF;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
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
                                                  'CALL_SET_PAT_STATUS',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            SELECT id_patient, a.id_epis_type, a.flg_ehr
              INTO l_id_patient, l_epis_type, l_flg_ehr
              FROM episode a
             WHERE id_episode = i_episode;
        
            IF l_external_sys_exist = pk_alert_constant.g_yes
            THEN
                BEGIN
                    SELECT ees.value
                      INTO l_ext_value
                      FROM epis_ext_sys ees
                      JOIN episode e
                        ON e.id_episode = ees.id_episode
                     WHERE ees.id_institution = i_prof.institution
                       AND ees.id_episode = i_episode
                       AND e.id_epis_type = l_epis_type
                       AND ees.id_external_sys = l_id_ext_sys;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_ext_value  := NULL;
                        l_exists_ext := pk_alert_constant.g_no;
                END;
            
                IF l_id_ext_sys = pk_sysconfig.get_config('ADT_EXTERNAL_SYS_IDENTIFIER', i_prof)
                   AND l_ext_value IS NULL
                THEN
                    IF l_exists_ext = pk_alert_constant.g_no
                       AND l_flg_ehr <> pk_ehr_access.g_flg_ehr_scheduled
                    THEN
                        INSERT INTO epis_ext_sys
                            (id_epis_ext_sys,
                             id_external_sys,
                             id_episode,
                             VALUE,
                             id_institution,
                             id_epis_type,
                             cod_epis_type_ext)
                        VALUES
                            (seq_epis_ext_sys.nextval,
                             l_id_ext_sys,
                             i_episode,
                             NULL,
                             i_prof.institution,
                             nvl(l_epis_type, pk_sysconfig.get_config('EPIS_TYPE', i_prof)),
                             decode(i_prof.software,
                                    8,
                                    'URG',
                                    29,
                                    'URG',
                                    11,
                                    'INT',
                                    1,
                                    'CON',
                                    3,
                                    'CON',
                                    12,
                                    'CON',
                                    'XXX'));
                    END IF;
                
                    pk_ia_event_common.amb_adm_from_alert_adt_new(i_id_institution  => i_prof.institution,
                                                                  i_id_professional => i_prof.id,
                                                                  i_id_episode      => i_episode);
                END IF;
            
            END IF;
        
            --COMMIT;
            IF i_transaction_id IS NULL
               AND l_transaction_id IS NOT NULL
            THEN
                g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.DO_COMMIT FOR ID_TRANSACTION : ' || l_transaction_id;
                pk_alertlog.log_debug(g_error);
                pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CALL_SET_PAT_STATUS',
                                              o_error);
            --pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;
    --

    /********************************************************************************************
    * Guarda o estado de um paciente. O estado do paciente é guardado na tabela de histórico de estados, 
    * de forma a permitir a consulta posterior do tempo em que um paciente esteve em cada estado. 
    * O seu estado actual é também guardado na tabela SR_SURGERY_RECORD.
    *
    * @param i_lang               Id do idioma
    * @param i_prof               Id do profissional, instituição e software
    * @param i_episode            Id do episódio
    * @param i_flg_status_new     Estado actual do paciente
    * @param i_flg_status_old     Anterior estado do paciente
    * @param i_test               Indica se deve validar o o estado do paciente
    * @param i_transaction_id     New Scheduler transaction ID
    * 
    * @param o_flg_show           Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title          Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text           Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button             Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error              Mensagem de erro
    *
    * @return                     TRUE/FALSE
    *
    * @author                     Rui Batista
    * @since                      2006/06/09
    *
    * @alter                      José Brito
    * @since                      2008/08/29
    *
    * @alter                      José Antunes
    * @since                      2008/11/05
       ********************************************************************************************/
    /*    -- 15-12-2010 deprecated by Telmo 
        FUNCTION call_set_pat_status
        (
            i_lang           IN language.id_language%TYPE,
            i_prof           IN profissional,
            i_episode        IN episode.id_episode%TYPE,
            i_flg_status_new IN VARCHAR2,
            i_flg_status_old IN VARCHAR2,
            i_test           IN VARCHAR2,
            i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
            i_cancel_notes   IN schedule_sr.notes_cancel%TYPE DEFAULT NULL,
            i_transaction_id IN VARCHAR2,
            o_flg_show       OUT VARCHAR2,
            o_msg_title      OUT VARCHAR2,
            o_msg_text       OUT VARCHAR2,
            o_button         OUT VARCHAR2,
            o_error          OUT t_error_out
        ) RETURN BOOLEAN IS
        
            --l_error VARCHAR2(2000);
        
            l_rows   table_varchar;
            l_rowsei table_varchar;
            srg_exception EXCEPTION;
            l_id_schedule schedule_sr.id_schedule%TYPE;
            l_upd         VARCHAR2(1);
            l_id_patient  episode.id_patient%TYPE;
        
            l_transaction_id VARCHAR2(4000);
        BEGIN
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
        
            g_sysdate      := SYSDATE;
            g_sysdate_tstz := current_timestamp;
        
            --Insere o novo estado do paciente na tabela de histórico, se o estado foi alterado
            IF nvl(i_flg_status_new, '@') != nvl(i_flg_status_old, '@')
            THEN
            
                --Valida o novo estado
                g_error := 'VALIDATE NEW PATIENT STATUS';
                IF i_test = 'Y'
                THEN
                    IF NOT pk_sr_grid.val_pat_status(i_lang      => i_lang,
                                                     i_episode   => i_episode,
                                                     i_prof      => i_prof,
                                                     i_status    => i_flg_status_new,
                                                     o_flg_show  => o_flg_show,
                                                     o_msg_title => o_msg_title,
                                                     o_msg_text  => o_msg_text,
                                                     o_button    => o_button,
                                                     o_error     => o_error)
                    THEN
                        pk_alert_exceptions.reset_error_state;
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'CALL_SET_PAT_STATUS',
                                                          o_error);
                        pk_utils.undo_changes;
                        RETURN FALSE;
                    END IF;
                
                    --Se a validação encontrou potenciais problemas sai para mostrar a mensagem
                    IF o_flg_show = 'Y'
                    THEN
                        RETURN TRUE;
                    END IF;
                END IF;
            
                g_error := 'INSERT SR_PAT_STATUS';
                INSERT INTO sr_pat_status
                    (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
                VALUES
                    (seq_sr_pat_status.nextval, i_episode, i_prof.id, i_flg_status_new, g_sysdate_tstz);
            
                --Actualiza estado actual
                g_error := 'UPDATE SR_SURGERY_RECORD';
                UPDATE sr_surgery_record
                   SET flg_pat_status = i_flg_status_new
                 WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                            FROM schedule_sr
                                           WHERE id_episode = i_episode);
            
                ts_epis_info.upd(id_episode_in     => i_episode,
                                 flg_pat_status_in => i_flg_status_new,
                                 flg_status_nin    => FALSE,
                                 rows_out          => l_rowsei);
            
                -- Se o novo estado do paciente é 'Cirurgia cancelada', actualiza o estado do episódio para Cancelado e cancela o agendamento.
                IF i_flg_status_new = g_pat_status_c
                THEN
                    g_error := 'UPDATE EPISODE';
                    -- <DENORM Fábio> 
                    l_rows := table_varchar();
                    ts_episode.upd(id_episode_in      => i_episode,
                                   flg_status_in      => i_flg_status_new,
                                   id_prof_cancel_in  => i_prof.id,
                                   dt_cancel_tstz_in  => g_sysdate_tstz,
                                   flg_status_nin     => FALSE,
                                   id_prof_cancel_nin => FALSE,
                                   dt_cancel_tstz_nin => FALSE,
                                   rows_out           => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPISODE',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS',
                                                                                  'ID_PROF_CANCEL',
                                                                                  'DT_CANCEL_TSTZ'));
                
                    g_error := 'FETCH ID_SCHEDULE';
                    SELECT id_schedule
                      INTO l_id_schedule
                      FROM schedule_sr
                     WHERE id_episode = i_episode;
                
                    -- Telmo 30-08-2010. To ensure the following cancel works, we need to de-register first. If it was not registered, 
                    -- no error is returned.
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULER_REGISTRATION';
                    -- get id_patient foist
                    SELECT id_patient
                      INTO l_id_patient
                      FROM episode
                     WHERE id_episode = i_episode;
                
                    IF NOT pk_schedule_api_upstream.cancel_scheduler_registration(i_lang           => i_lang,
                                                                                  i_prof           => i_prof,
                                                                                  i_id_schedule    => l_id_schedule,
                                                                                  i_id_patient     => l_id_patient,
                                                                                  i_transaction_id => l_transaction_id,
                                                                                  o_error          => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.CANCEL_SCHEDULE';
                    IF NOT pk_schedule_api_upstream.cancel_schedule(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_id_schedule      => l_id_schedule,
                                                                    i_id_cancel_reason => NULL,
                                                                    i_transaction_id   => l_transaction_id,
                                                                    o_error            => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                
                    UPDATE schedule_sr ss
                       SET ss.id_sr_cancel_reason = i_cancel_reason, ss.notes_cancel = i_cancel_notes
                     WHERE ss.id_schedule = l_id_schedule
                       AND flg_status = pk_schedule.g_sched_status_cancelled;
                
                    IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                     i_prof    => i_prof,
                                                                     i_episode => i_episode,
                                                                     i_status  => pk_sr_approval.g_cancel_surgery,
                                                                     o_error   => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                
                    ts_epis_info.upd(id_episode_in       => i_episode,
                                     flg_dsch_status_in  => i_flg_status_new,
                                     flg_dsch_status_nin => FALSE,
                                     rows_out            => l_rowsei);
                
                ELSE
                    IF NOT check_pat_status(i_lang, i_prof, i_flg_status_new, i_flg_status_old, l_upd, o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    IF l_upd = 'A'
                    THEN
                        IF NOT pk_sr_visit.set_epis_admission(i_lang  => i_lang,
                                                              i_prof  => i_prof,
                                                              i_epis  => i_episode,
                                                              o_error => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    ELSIF l_upd = 'C'
                    THEN
                        IF NOT pk_sr_visit.cancel_epis_admission(i_lang  => i_lang,
                                                                 i_prof  => i_prof,
                                                                 i_epis  => i_episode,
                                                                 o_error => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                END IF;
            
                -- Se o estado anterior era Cirurgia Cancelada, tem que reactivar o episódio e o agendamento
                IF i_flg_status_old = g_pat_status_c
                THEN
                    g_error := 'UPDATE EPISODE';
                    -- <DENORM Fábio> 
                    l_rows := table_varchar();
                    ts_episode.upd(id_prof_cancel_in => CAST(NULL AS NUMBER), id_prof_cancel_nin => FALSE, dt_cancel_tstz_in => CAST(NULL AS TIMESTAMP
                        WITH LOCAL TIME ZONE),
                        dt_cancel_tstz_nin => FALSE,
                        flg_status_in => flg_status_a,
                        flg_status_nin => FALSE,
                        rows_out => l_rows,
                        where_in =>
                         'id_episode = ' || i_episode ||
                         ' AND flg_status = ''' || flg_status_c ||
                         '''');
                
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPISODE',
                                                  i_rowids       => l_rows,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('FLG_STATUS',
                                                                                  'ID_PROF_CANCEL',
                                                                                  'DT_CANCEL_TSTZ'));
                
                    g_error := 'UPDATE SCHEDULE_SR';
                    UPDATE schedule_sr
                       SET flg_status = flg_status_a, id_prof_cancel = NULL, dt_cancel_tstz = NULL
                     WHERE id_episode = i_episode
                       AND flg_status = flg_status_c;
                
                    g_error := 'UPDATE SCHEDULE';
                    UPDATE schedule
                       SET flg_status = flg_status_a, id_prof_cancel = NULL, dt_cancel_tstz = NULL
                     WHERE id_schedule = (SELECT id_schedule
                                            FROM schedule_sr
                                           WHERE id_episode = i_episode);
                
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.reactivate_canceled_sched';
                    IF NOT pk_schedule_api_upstream.reactivate_canceled_sched(i_lang           => i_lang,
                                                                              i_prof           => i_prof,
                                                                              i_id_schedule    => l_id_schedule,
                                                                              i_transaction_id => l_transaction_id,
                                                                              o_error          => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                END IF;
            
                -- REGISTER (efectivar) SCHEDULE IN SCHEDULER 
                g_error := 'REGISTER IN SCHEDULER';
                IF i_flg_status_new <> g_pat_status_a
                THEN
                    SELECT id_patient
                      INTO l_id_patient
                      FROM episode
                     WHERE id_episode = i_episode;
                
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.REGISTER_SCHEDULE';
                    IF NOT pk_schedule_api_upstream.register_schedule(i_lang           => i_lang,
                                                                      i_prof           => i_prof,
                                                                      i_id_schedule    => l_id_schedule,
                                                                      i_id_patient     => l_id_patient,
                                                                      i_transaction_id => l_transaction_id,
                                                                      o_error          => o_error)
                    THEN
                        RAISE srg_exception;
                    END IF;
                END IF;
            
                --Actualiza data da última intercção do episódio
                g_error := 'UPDATE DT_LAST_INTERACTION';
                IF NOT pk_sr_output.c_update_dt_last_interaction(i_lang    => i_lang,
                                                                 i_episode => i_episode,
                                                                 i_dt_last => g_sysdate_tstz,
                                                                 o_error   => o_error)
                THEN
                
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'CALL_SET_PAT_STATUS',
                                                      o_error);
                    RETURN FALSE;
                END IF;
            
                --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
                IF nvl(i_episode, 0) != 0
                   AND i_prof.id IS NOT NULL
                THEN
                    g_error := 'UPDATE EPIS_PROF_REC';
                    IF NOT pk_visit.call_set_epis_prof_rec(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_episode  => i_episode,
                                                           i_patient  => NULL,
                                                           i_flg_type => g_flg_type_rec,
                                                           o_error    => o_error)
                    THEN
                    
                        --ROLLBACK;
                        pk_alert_exceptions.reset_error_state;
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'CALL_SET_PAT_STATUS',
                                                          o_error);
                        RETURN FALSE;
                    END IF;
                END IF;
            
                g_error := 'CALL TO PK_SR_APPROVAL.CHECK_CHANGE_STATUS';
            
                IF NOT pk_sr_approval.check_change_status(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_episode    => i_episode,
                                                          i_old_status => i_flg_status_old,
                                                          i_new_status => i_flg_status_new,
                                                          o_error      => o_error)
                THEN
                    RAISE srg_exception;
                END IF;
            
                g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
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
                                                      'CALL_SET_PAT_STATUS',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                --COMMIT;
            
                IF i_transaction_id IS NULL
                   AND l_transaction_id IS NOT NULL
                THEN
                    pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
                END IF;
            
            END IF;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN srg_exception THEN
                pk_alert_exceptions.reset_error_state;
                pk_utils.undo_changes;
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
            
            WHEN OTHERS THEN
                -- Unexpected error
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'CALL_SET_PAT_STATUS',
                                                  o_error);
                --pk_utils.undo_changes;
                pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
                RETURN FALSE;
        END call_set_pat_status;
    */

    /********************************************************************************************
    * Função criada para remover ROLLBACK/COMMIT da função CALL_SET_PAT_STATUS, que é chamada pela
    * função de cancelamento de episódios: PK_VISIT.CANCEL_EPISODE.
    *
    * @param i_lang               Id do idioma
    * @param i_prof               Id do profissional, instituição e software
    * @param i_episode            Id do episódio
    * @param i_flg_status_new     Estado actual do paciente
    * @param i_flg_status_old     Anterior estado do paciente
    * @param i_test               Indica se deve validar o o estado do paciente
    * 
    * @param o_flg_show           Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title          Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text           Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button             Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error              Mensagem de erro
    *
    * @return                     TRUE/FALSE
    *
    * @author                     Rui Batista
    * @since                      2006/06/09
    *
    * @alter                      José Brito
    * @since                      2008/08/29
       ********************************************************************************************/
    FUNCTION set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_ext_exception  EXCEPTION;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL call_set_pat_status for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT call_set_pat_status(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => i_episode,
                                   i_flg_status_new => i_flg_status_new,
                                   i_flg_status_old => i_flg_status_old,
                                   i_test           => i_test,
                                   i_transaction_id => l_transaction_id,
                                   o_flg_show       => o_flg_show,
                                   o_msg_title      => o_msg_title,
                                   o_msg_text       => o_msg_text,
                                   o_button         => o_button,
                                   o_error          => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'CALL pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    FUNCTION set_pat_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status_new IN VARCHAR2,
        i_flg_status_old IN VARCHAR2,
        i_test           IN VARCHAR2,
        i_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes   IN schedule_sr.notes_cancel%TYPE,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg_text       OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_ext_exception  EXCEPTION;
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL call_set_pat_status for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT call_set_pat_status(i_lang           => i_lang,
                                   i_prof           => i_prof,
                                   i_episode        => i_episode,
                                   i_flg_status_new => i_flg_status_new,
                                   i_flg_status_old => i_flg_status_old,
                                   i_test           => i_test,
                                   i_cancel_reason  => i_cancel_reason,
                                   i_cancel_notes   => i_cancel_notes,
                                   i_transaction_id => l_transaction_id,
                                   o_flg_show       => o_flg_show,
                                   o_msg_title      => o_msg_title,
                                   o_msg_text       => o_msg_text,
                                   o_button         => o_button,
                                   o_error          => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'CALL pk_schedule_api_upstream.do_commit for id_transaction ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    --
    /********************************************************************************************
    * Guarda as notas de estado de um paciente. O estado do paciente é guardado na tabela de 
    * histórico de estados, de forma a permitir a consulta posterior do tempo em que um paciente 
    * esteve em cada estado. O seu estado actual é também guardado na tabela SR_SURGERY_RECORD
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_episode     Id do episódio
    * @param i_notes       Notas
    * 
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/09
       ********************************************************************************************/

    FUNCTION set_pat_status_notes
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_notes   IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --l_error VARCHAR2(2000);
    
    BEGIN
        g_sysdate := SYSDATE;
        g_sysdate := current_timestamp;
    
        --Se as notas estiverem preenchidas, guarda-as
        g_error := 'INSERT SR_PAT_STATUS_NOTES';
        pk_alertlog.log_debug(g_error);
        IF i_notes IS NOT NULL
        THEN
            INSERT INTO sr_pat_status_notes
                (id_sr_pat_status_notes, id_episode, id_professional, dt_reg_tstz, notes)
            VALUES
                (seq_sr_pat_status_notes.nextval, i_episode, i_prof.id, g_sysdate_tstz, i_notes);
        
            --Actualiza data da última intercção do episódio
            g_error := 'UPDATE DT_LAST_INTERACTION';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                           i_episode => i_episode,
                                                           i_dt_last => g_sysdate_tstz,
                                                           o_error   => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_PAT_STATUS_NOTES',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
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
                                                  'SET_PAT_STATUS_NOTES',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            COMMIT;
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
                                              'SET_PAT_STATUS_NOTES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de estados possíveis de um paciente. O FLG_STATUS recebe o valor do estado actual 
    * do paciente de forma a que este não seja mostrado na lista. Assim, não é permitido actualizar o 
    * estado de um paciente para o mesmo que estava anteriormente.
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_flg_status  Estado actual do paciente
    * 
    * @param o_status      Lista de estados
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/08
       ********************************************************************************************/

    FUNCTION get_pat_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN VARCHAR2,
        o_status     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
    
    BEGIN
    
        --Obtem os estados possíveis de um paciente
        g_error := 'GET PAT STATUS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_status FOR
            SELECT desc_val label, val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_pat_status, NULL)) s
             WHERE s.val NOT IN (g_pat_status_c, nvl(i_flg_status, '@'));
    
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
                                              'GET_PAT_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_status);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter o estado do paciente e as notas. O estado do paciente é guardado nas tabelas SR_SURGERY_RECORD 
    * (último estado) e SR_PAT_STATUS. Como aqui apenas queremos o último, vamos obtê-lo na SR_SURGERY_RECORD
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_pat_status  Estado do paciente
    * @param o_pat_notes   Notas de estado do paciente
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/08
       ********************************************************************************************/

    FUNCTION get_pat_status_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_pat_status OUT VARCHAR2,
        o_pat_notes  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_stat IS
            SELECT pk_sysdomain.get_domain('SR_SURGERY_ROOM.FLG_PAT_STATUS', rec.flg_pat_status, i_lang) desc_status
              FROM schedule_sr s, sr_surgery_record rec
             WHERE s.id_episode = i_episode
               AND rec.id_schedule_sr = s.id_schedule_sr;
    
    BEGIN
    
        --Obtém o estado do paciente
        g_error := 'GET PATIENT STATUS';
        OPEN c_stat;
        FETCH c_stat
            INTO o_pat_status;
        CLOSE c_stat;
    
        --Abre cursor com as notas do estado do paciente
        g_error := 'OPEN O_PAT_NOTES CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_pat_notes FOR
            SELECT pk_date_utils.date_send_tsz(i_lang, n.dt_reg_tstz, i_prof) dt_reg,
                   pk_date_utils.date_char_tsz(i_lang, n.dt_reg_tstz, i_prof.institution, i_prof.software) dt_notes,
                   notes,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) nick_name
              FROM sr_pat_status_notes n, professional p
             WHERE n.id_episode = i_episode
               AND p.id_professional = n.id_professional
             ORDER BY n.dt_reg_tstz;
    
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
                                              'GET_PAT_STATUS_NOTES',
                                              o_error);
            pk_types.open_my_cursor(o_pat_notes);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de salas e respectivos estados.
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_prof        Id do profissional, instituição e software
    * 
    * @param o_room        Lista de salas
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/05
       ********************************************************************************************/

    FUNCTION get_room_status
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        o_room    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtem as salas e respectivos estados
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT r.id_room,
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) desc_room,
                   s.flg_status,
                   pk_sysdomain.get_domain('SR_ROOM_STATUS.FLG_STATUS', s.flg_status, i_lang) ||
                   decode(s.flg_status,
                          g_room_status_d,
                          ' (' || nvl(pk_date_utils.get_elapsed_sysdate_tsz(i_lang, s.dt_status_tstz), 0) || ')',
                          '') desc_status
              FROM room r, sr_room_status s
             WHERE /*r.id_department = l_sr_dept AND */
             r.id_room = (SELECT id_room
                            FROM room_scheduled d
                           WHERE d.id_schedule = (SELECT id_schedule
                                                    FROM schedule_sr
                                                   WHERE id_episode = i_episode))
             AND s.id_room(+) = r.id_room
             AND (s.id_sr_room_state = (SELECT MAX(id_sr_room_state)
                                      FROM sr_room_status s1
                                     WHERE s1.id_room = s.id_room) OR NOT EXISTS
              (SELECT 1
                 FROM sr_room_status s1
                WHERE s1.id_room = s.id_room))
             ORDER BY r.rank, 2;
    
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
                                              'GET_ROOM_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obtem a lista de estados possíveis de uma sala.
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_flg_status  Estado actual da sala
    * 
    * @param o_room        Lista de salas
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/07
       ********************************************************************************************/

    FUNCTION get_room_status_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN VARCHAR2,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_domain_sr_r_status sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
    
        --Obtem as salas e respectivos estados
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT desc_val label, val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s
             WHERE s.val NOT IN (nvl(i_flg_status, '@'));
    
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
                                              'GET_ROOM_STATUS_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_room);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Guarda o estado de uma sala.
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_room        Id da sala
    * @param i_prof        Id do profissional, instituição e software
    * @param i_status      Estado da sala
    * @param i_notes       Notas
    * @param i_test        Indica se deve validar o número de profissionais por categoria
    * 
    * @param o_flg_show    Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title   Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text    Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button      Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/06/05
       ********************************************************************************************/

    FUNCTION set_room_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_room      IN room.id_room%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        i_notes     IN VARCHAR2,
        i_test      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_old_room_status sr_room_status.flg_status%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Obtem o estado anterior da sala
        g_error := 'GET OLD ROOM STATUS';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT MIN(s.flg_status)
              INTO l_old_room_status
              FROM sr_room_status s
             WHERE s.id_room = i_room
               AND s.id_sr_room_state = (SELECT MAX(id_sr_room_state)
                                           FROM sr_room_status s1
                                          WHERE s1.id_room = s.id_room);
        EXCEPTION
            WHEN no_data_found THEN
                l_old_room_status := NULL;
        END;
    
        IF nvl(l_old_room_status, '@') != i_status
        THEN
            --Valida o novo estado
            g_error := 'VALIDATE NEW ROOM STATUS';
            pk_alertlog.log_debug(g_error);
            IF i_test = 'Y'
            THEN
                g_error := 'CALL PK_SR_GRID.VAL_ROOM_STATUS FOR ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_grid.val_room_status(i_lang      => i_lang,
                                                  i_episode   => i_episode,
                                                  i_room      => i_room,
                                                  i_prof      => i_prof,
                                                  i_status    => i_status,
                                                  o_flg_show  => o_flg_show,
                                                  o_msg_title => o_msg_title,
                                                  o_msg_text  => o_msg_text,
                                                  o_button    => o_button,
                                                  o_error     => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_ROOM_STATUS',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
                END IF;
            
                --Se a validação encontrou potenciais problemas sai para mostrar a mensagem
                IF o_flg_show = 'Y'
                THEN
                    RETURN TRUE;
                END IF;
            END IF;
        
            --Guarda o novo estado
            g_error := 'INSERT SR_ROOM_STATUS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO sr_room_status
                (id_sr_room_state, id_room, id_episode, flg_status, id_professional, dt_status_tstz, notes)
            VALUES
                (seq_sr_room_status.nextval, i_room, i_episode, i_status, i_prof.id, g_sysdate_tstz, i_notes);
        
            --Actualiza o estado na tabela room_scheduled
            g_error := 'update room_scheduled';
            pk_alertlog.log_debug(g_error);
            UPDATE room_scheduled
               SET dt_start_tstz = decode(i_status, 'B', g_sysdate_tstz, dt_start_tstz)
            --, flg_status = i_status
             WHERE id_room = i_room
               AND id_schedule = (SELECT id_schedule
                                    FROM schedule_sr
                                   WHERE id_episode = i_episode);
        
            /*ts_epis_info.upd(id_episode_in           => i_episode,
            room_sch_flg_status_in  => i_status,
            room_sch_flg_status_nin => FALSE,
            rows_out                => l_rowsid);*/
        
            --Actualiza data da última intercção do episódio
            g_error := 'UPDATE DT_LAST_INTERACTION';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                           i_episode => i_episode,
                                                           i_dt_last => g_sysdate_tstz,
                                                           o_error   => o_error)
            THEN
                pk_alert_exceptions.reset_error_state;
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  'SET_ROOM_STATUS',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            --Actualiza a tabela de registo dos profissionais que efectuaram registos neste episódio
            IF nvl(i_episode, 0) != 0
               AND i_prof.id IS NOT NULL
            THEN
                g_error := 'UPDATE EPIS_PROF_REC';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_visit.set_epis_prof_rec(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  i_episode  => i_episode,
                                                  i_patient  => NULL,
                                                  i_flg_type => g_flg_type_rec,
                                                  o_error    => o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'SET_ROOM_STATUS',
                                                      o_error);
                    RETURN FALSE;
                END IF;
            END IF;
        
            g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
            pk_alertlog.log_debug(g_error);
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
                                                  'SET_ROOM_STATUS',
                                                  o_error);
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
            COMMIT;
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
                                              'SET_ROOM_STATUS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Valida o novo estado de uma sala.
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_room        Id da sala
    * @param i_prof        Id do profissional, instituição e software
    * @param i_status      Estado da sala
    * 
    * @param o_flg_show    Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title   Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text    Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button      Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/10/18
       ********************************************************************************************/

    FUNCTION val_room_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_room      IN room.id_room%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_status sr_pat_status.flg_pat_status%TYPE;
        l_count      PLS_INTEGER;
    
    BEGIN
    
        --Verifica o estado do paciente do episódio alterado
        --Obtem o estado do paciente
        g_error := 'GET PAT STATUS';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT nvl(flg_pat_status, g_pat_status_a)
              INTO l_pat_status
              FROM sr_pat_status s
             WHERE s.id_episode = i_episode
               AND s.dt_status_tstz = (SELECT MAX(s1.dt_status_tstz)
                                         FROM sr_pat_status s1
                                        WHERE s1.id_episode = i_episode);
        EXCEPTION
            WHEN no_data_found THEN
                l_pat_status := g_pat_status_a;
        END;
    
        --PROC_WRITE_LOG ( 'pk_sr_grid.txt',null, 'entrou - 1', l_error);
    
        --Se o estado da sala for B-Ocupada, o paciente tem que estar num dos seguintes estados:
        -- P- Em preparação, R- Preparado para a cirurgia, S- Em cirurgia, F- Terminou a cirurgia
        g_error := 'VAL ROOM STATUS - B';
        pk_alertlog.log_debug(g_error);
        IF i_status = g_room_status_b
           AND l_pat_status NOT IN (g_pat_status_p, g_pat_status_r, g_pat_status_s, g_pat_status_f)
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T260');
            o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T261');
            o_button    := 'NC';
            RETURN TRUE;
        END IF;
    
        --Se o estado da sala for diferente de B- Ocupada, o paciente não pode estar no estado S- Em Cirurgia
        IF i_status != g_room_status_b
           AND l_pat_status = g_pat_status_s
        THEN
            o_flg_show  := 'Y';
            o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T260');
            o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T267');
            o_button    := 'NC';
            RETURN TRUE;
        END IF;
    
        --Verifica os restantes pacientes da mesma sala
        IF i_status = g_room_status_b
        THEN
            --Verifica se há pacientes na sala com estado inválido
            g_error := 'VAL ROOM ALL PAT 1';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(*)
              INTO l_count
              FROM schedule_sr s, room_scheduled rs, sr_pat_status ps
             WHERE s.dt_target_tstz BETWEEN pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) AND
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) + 0.99999
                  --s.dt_target BETWEEN trunc(SYSDATE) AND trunc(SYSDATE) + 0.99999
               AND s.id_institution = i_prof.institution
               AND rs.id_schedule(+) = s.id_schedule
               AND rs.id_room = i_room
               AND ps.id_episode = s.id_episode
               AND ps.dt_status_tstz = (SELECT MAX(ps1.dt_status_tstz)
                                          FROM sr_pat_status ps1
                                         WHERE ps1.id_episode = ps.id_episode)
               AND ps.flg_pat_status IN (g_pat_status_p, g_pat_status_r, g_pat_status_s, g_pat_status_f);
        
            IF l_count = 0
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T260');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T268');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        
        ELSIF i_status != g_room_status_b
        THEN
            --Verifica se há pacientes na sala com estado válido
            g_error := 'VAL ROOM ALL PAT 2';
            pk_alertlog.log_debug(g_error);
            SELECT COUNT(*)
              INTO l_count
              FROM schedule_sr s, room_scheduled rs, sr_pat_status ps
             WHERE s.dt_target_tstz BETWEEN pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) AND
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL) + 0.99999
                  --s.dt_target BETWEEN trunc(SYSDATE) AND trunc(SYSDATE) + 0.99999
               AND s.id_institution = i_prof.institution
               AND rs.id_schedule(+) = s.id_schedule
               AND rs.id_room = i_room
               AND ps.id_episode = s.id_episode
               AND ps.dt_status_tstz = (SELECT MAX(ps1.dt_status_tstz)
                                          FROM sr_pat_status ps1
                                         WHERE ps1.id_episode = ps.id_episode)
               AND ps.flg_pat_status = g_pat_status_s;
        
            IF l_count != 0
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T260');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T269');
                o_button    := 'NC';
                RETURN TRUE;
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
                                              'VAL_ROOM_STATUS',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Valida o novo estado de um paciente.
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_prof        Id do profissional, instituição e software
    * @param i_status      Estado da sala
    * 
    * @param o_flg_show    Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title   Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text    Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button      Botões a mostrar: N - não, R - lido, C - confirmado
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/10/18
       ********************************************************************************************/

    FUNCTION val_pat_status
    (
        i_lang      IN language.id_language%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_prof      IN profissional,
        i_status    IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_count    PLS_INTEGER;
        l_status   sr_receive.flg_status%TYPE;
        l_manual   sr_receive.flg_manual%TYPE;
        l_id_visit visit.id_visit%TYPE;
    
    BEGIN
    
        l_id_visit := pk_episode.get_id_visit(i_episode => i_episode);
    
        --Se o estado do doente for "Pedido de transporte para o Bloco", verifica se existe um pedido de transporte do doente para o bloco
        g_error := 'VALIDATE TRANSPORT REQUEST';
        pk_alertlog.log_debug(g_error);
        IF i_status = g_pat_status_l
        THEN
            --Procura pedido de transporte do paciente
            SELECT COUNT(*)
              INTO l_count
              FROM movement m, department d, room r, episode e
             WHERE m.id_episode = e.id_episode
               AND m.flg_status IN ('R', 'P') --requisitado ou pendente
               AND d.flg_type = 'S' --Bloco operatório
               AND d.id_institution = i_prof.institution
               AND r.id_department = d.id_department
               AND r.id_room = m.id_room_to
               AND e.id_visit = l_id_visit;
        
            IF nvl(l_count, 0) = 0
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T262');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T263');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        END IF;
    
        --Se o estado do doente for "Em transporte para o bloco", verifica se existe algum transporte em execução
        g_error := 'VALIDATE TRANSPORT EXEC';
        pk_alertlog.log_debug(g_error);
        IF i_status = g_pat_status_t
        THEN
            --Procura execução de transporte do paciente
            SELECT COUNT(*)
              INTO l_count
              FROM movement m, department d, room r, episode e
             WHERE m.id_episode = e.id_episode
               AND m.flg_status = 'T' --em transporte
               AND d.flg_type = 'S' --Bloco operatório
               AND d.id_institution = i_prof.institution
               AND r.id_department = d.id_department
               AND r.id_room = m.id_room_to
               AND e.id_visit = l_id_visit;
        
            IF nvl(l_count, 0) = 0
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T262');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T264');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        END IF;
    
        --Se o estado do doente for  "Acolhido no bloco" , "Em preparação", "Preparado para cirurgia", "Em cirurgia",
        --   verifica se já foi feito o acolhimento do doente no bloco
        g_error := 'VALIDATE ASSESSMENT';
        pk_alertlog.log_debug(g_error);
        IF i_status IN (g_pat_status_v, g_pat_status_p, g_pat_status_r, g_pat_status_s)
        THEN
            --Verifica se o OK para acolhimento já foi dado        
            g_error := 'GET_SR_RECEIVE';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_procedures.get_sr_receive(i_lang    => i_lang,
                                                   i_episode => i_episode,
                                                   o_status  => l_status,
                                                   o_manual  => l_manual,
                                                   o_error   => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            IF nvl(l_status, 'N') = 'N'
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T262');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T265');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        END IF;
    
        --Se o estado do doente for "Preparado para cirurgia" ou "Em cirurgia", verifica se tem a nota de consentimento assinada
        g_error := 'VALIDATE SIGNED CONSENT';
        pk_alertlog.log_debug(g_error);
        IF i_status IN (g_pat_status_r, g_pat_status_s)
        THEN
            NULL; --Ainda não há onde validar se a nota de consentimento está assinada
        END IF;
    
        --Se o estado do doente for "Terminou a cirurgia", verifica se alguma vez esteve no estado "Em cirurgia"
        g_error := 'VALIDATE SURGERY';
        pk_alertlog.log_debug(g_error);
        IF i_status = g_pat_status_f
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM sr_pat_status ps
             WHERE ps.id_episode = i_episode
               AND flg_pat_status = g_pat_status_s;
        
            IF nvl(l_count, 0) = 0
            THEN
                o_flg_show  := 'Y';
                o_msg_title := pk_message.get_message(i_lang, 'SR_LABEL_T262');
                o_msg_text  := pk_message.get_message(i_lang, 'SR_LABEL_T266');
                o_button    := 'NC';
                RETURN TRUE;
            END IF;
        END IF;
    
        --Faltam ainda validar os restantes estados mas para já ainda não temos como o fazer porque as funcionalidades ainda
        --não foram desenvolvidas
    
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
                                              'VAL_PAT_STATUS',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Obter o agendamento do dia do Bloco Operatório, para o enfermeiro. Devolve todas as
    *  intervenções do dia a que o profissional esteja agendado - VISTA 1.
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema
    * @param i_prof        Id do profissional, instituição e software
    * @param i_type        Indica se se pretende ver apenas os agendamentos aos quais o profissional
    *                      está alocado ou todos os agendamentos. Valores possíveis:
    *                                   A - Todos os agendamentos
    *                                   P - Agendamentos do profissional
    * 
    * @param o_grid        Array de agendamentos
    * @param o_room        Array de estados possíveis das salas
    * @param o_pat         Array de estados possíveis do paciente
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/12
    * @date                2009/07/29
    * @Notas               ALERT-38050  Se o estado do paciente for S (em cirurgia) e haja registo 
    * de data/hora inicio cirurgia então mostrar a data de cirurgia (sr_surgery_time_det) senão mostra
    * a data/hora da alteração de estado 'S' (sr_pat_status)
       ********************************************************************************************/

    FUNCTION get_grid_nurse_v1
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof_cat category.flg_type%TYPE;
    
        l_hand_off_type sys_config.value%TYPE;
        l_dt_min        schedule_sr.dt_target_tstz%TYPE;
        l_dt_max        schedule_sr.dt_target_tstz%TYPE;
    
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_domain_sr_r_status   sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        --Obtem os estados possíveis das salas
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_room FOR
            SELECT s.desc_val label, s.val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s;
    
        --Obtem os estados possíveis do paciente
        g_error := 'GET PAT CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_pat FOR
            SELECT s.desc_val label, s.val data, img_name icon
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_pat_status, NULL)) s;
    
        --Constroi cursor com a grelha do enfermeiro
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled, --Indica se a cirurgia foi reagendada para ter uma visualização gráfica diferente
                   pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    s.dt_interv_preview_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_interv_preview,
                   nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, i_prof), 0) hour_interv_start,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_sched_room,
                   pk_sysdomain.get_img(i_lang, 'SR_ROOM_STATUS.FLG_STATUS', nvl(m.flg_status, 'F')) room_status,
                   nvl(m.flg_status, 'F') room_status_det,
                   r.id_room,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) photo,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   pk_episode.get_epis_room(i_lang, i_prof, epis.id_episode) desc_room,
                   pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.drug_presc) desc_drug_presc,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_exam, l_prof_cat) desc_exam_req,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_analysis, l_prof_cat) desc_analysis_req,
                   pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                          i_prof,
                                                          pk_grid.get_prioritary_task(i_lang,
                                                                                      i_prof,
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     epis.id_visit,
                                                                                                                     g_task_analysis,
                                                                                                                     l_prof_cat),
                                                                                      pk_grid.visit_grid_task_str_nc(i_lang,
                                                                                                                     i_prof,
                                                                                                                     epis.id_visit,
                                                                                                                     g_task_exam,
                                                                                                                     l_prof_cat),
                                                                                      g_analysis_exam_icon_grid_rank,
                                                                                      pk_alert_constant.g_cat_type_nurse)) desc_analysis_exam_req,
                   decode(s.id_episode, m.id_episode, nvl(m.flg_status, 'F'), NULL) room_state,
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.hemo_req) hemo_req_status,
                   --pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_supplies_external_api_db.get_surg_supplies_reg(i_lang, i_prof, epis.id_episode, gt.material_req) material_req_status,
                   pk_sysdomain.get_img(i_lang,
                                        'SR_SURGERY_ROOM.FLG_PAT_STATUS',
                                        nvl(rec.flg_pat_status, g_pat_status_pend)) pat_status,
                   nvl(rec.flg_pat_status, g_pat_status_pend) pat_status_det,
                   pk_date_utils.date_send_tsz(i_lang, m.dt_status_tstz, i_prof) dt_room_status,
                   pk_date_utils.date_send_tsz(i_lang,
                                               /*BEGIN ALERT-38050*/
                                               decode(rec.flg_pat_status,
                                                      'S',
                                                      nvl(st.dt_interv_start_tstz,
                                                          (SELECT decode(ps.flg_pat_status,
                                                                         g_pat_status_l,
                                                                         ps.dt_status_tstz,
                                                                         g_pat_status_s,
                                                                         ps.dt_status_tstz,
                                                                         NULL) dt_status_tstz
                                                             FROM sr_pat_status ps
                                                            WHERE ps.id_episode = epis.id_episode
                                                              AND ps.flg_pat_status = rec.flg_pat_status
                                                              AND ps.dt_status_tstz =
                                                                  (SELECT MAX(ps1.dt_status_tstz)
                                                                     FROM sr_pat_status ps1
                                                                    WHERE ps1.id_episode = ps.id_episode
                                                                      AND ps1.flg_pat_status = ps.flg_pat_status))),
                                                      (SELECT decode(ps.flg_pat_status,
                                                                     g_pat_status_l,
                                                                     ps.dt_status_tstz,
                                                                     g_pat_status_s,
                                                                     ps.dt_status_tstz,
                                                                     NULL) dt_status_tstz
                                                         FROM sr_pat_status ps
                                                        WHERE ps.id_episode = epis.id_episode
                                                          AND ps.flg_pat_status = rec.flg_pat_status
                                                          AND ps.dt_status_tstz =
                                                              (SELECT MAX(ps1.dt_status_tstz)
                                                                 FROM sr_pat_status ps1
                                                                WHERE ps1.id_episode = ps.id_episode
                                                                  AND ps1.flg_pat_status = ps.flg_pat_status)))
                                               /*END ALERT-38050*/,
                                               i_prof) dt_pat_status,
                   s.flg_status flg_surg_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule),
                          pk_alert_constant.g_no,
                          decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                  i_prof,
                                                                                                  epis.id_episode,
                                                                                                  l_prof_cat,
                                                                                                  l_hand_off_type,
                                                                                                  pk_alert_constant.g_yes),
                                                              i_prof.id),
                                 -1,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) prof_follow_remove
              FROM schedule_sr s,
                   schedule h,
                   patient p,
                   room r,
                   room_scheduled sr,
                   sr_surgery_record rec,
                   grid_task gt,
                   episode epis,
                   epis_info ei,
                   (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                      FROM room r, sr_room_status s
                     WHERE s.id_room(+) = r.id_room
                       AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR
                            s.id_sr_room_state IS NULL)) m,
                   (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                      FROM sr_surgery_time st, sr_surgery_time_det std
                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                       AND st.flg_type = flg_interv_start
                       AND std.flg_status = flg_status_a) st
             WHERE s.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND s.id_institution = i_prof.institution
               AND ((EXISTS
                    (SELECT 1
                        FROM prof_room pr, room r1
                       WHERE pr.id_professional = i_prof.id
                         AND r1.id_room = pr.id_room
                         AND (pr.id_room = r.id_room OR
                             pr.id_room = (SELECT ei.id_room
                                              FROM epis_info ei
                                             WHERE ei.id_episode = epis.id_episode))) AND i_type = g_my_patients) OR
                   (i_type = g_all_patients) OR
                   (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                   pk_alert_constant.g_yes))
               AND h.id_schedule = s.id_schedule
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND sr.flg_status(+) = g_active
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND r.id_room(+) = sr.id_room
               AND m.id_room(+) = sr.id_room
               AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND ei.id_schedule(+) = s.id_schedule
               AND epis.id_episode = s.id_episode
               AND gt.id_episode(+) = epis.id_episode
               AND st.id_episode(+) = epis.id_episode
               AND epis.flg_ehr != g_flg_ehr -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
             ORDER BY s.dt_target_tstz;
    
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
                                              'GET_GRID_NURSE_V1',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_room);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Obter o agendamento do dia do Bloco Operatório, para o enfermeiro. Devolve todas as
    *  intervenções do dia a que o profissional esteja agendado - VISTA 2.
    *
    * @param i_lang        Id do idioma
    * @param i_dt          Data. se for nula, considera a data de sistema
    * @param i_prof        Id do profissional, instituição e software
    * @param i_type        Indica se se pretende ver apenas os agendamentos aos quais o profissional
    *                      está alocado ou todos os agendamentos. Valores possíveis:
    *                                   A - Todos os agendamentos
    *                                   P - Agendamentos do profissional
    * 
    * @param o_grid        Array de agendamentos
    * @param o_room        Array de estados possíveis das salas
    * @param o_pat         Array de estados possíveis do paciente
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/09/12
       ********************************************************************************************/

    FUNCTION get_grid_nurse_v2
    (
        i_lang  IN language.id_language%TYPE,
        i_dt    IN VARCHAR2,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_grid  OUT pk_types.cursor_type,
        o_room  OUT pk_types.cursor_type,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hand_off_type        sys_config.value%TYPE;
        l_prof_cat             category.flg_type%TYPE;
        l_dt_min               schedule_sr.dt_target_tstz%TYPE;
        l_dt_max               schedule_sr.dt_target_tstz%TYPE;
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_domain_sr_r_status   sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
    
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
        get_date_bounds(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt, o_dt_min => l_dt_min, o_dt_max => l_dt_max);
    
        --Obtem os estados possíveis das salas
        g_error := 'GET ROOM CURSOR';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_room FOR
            SELECT s.desc_val label, s.val data, img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_r_status, NULL)) s;
    
        --Obtem os estados possíveis do paciente
        g_error := 'GET PAT CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_pat FOR
            SELECT s.desc_val label, s.val data, img_name
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, l_domain_sr_pat_status, NULL)) s;
    
        --Constroi cursor com a grelha do enfermeiro
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_grid FOR
            SELECT s.id_schedule,
                   s.id_episode,
                   decode(h.flg_urgency, 'Y', 'U', decode(s.id_sched_sr_parent, NULL, 'N', 'R')) flg_rescheduled,
                   pk_date_utils.date_send_tsz(i_lang, s.dt_interv_preview_tstz, i_prof) hour_interv_preview_send,
                   pk_date_utils.date_char_hour_tsz(i_lang,
                                                    s.dt_interv_preview_tstz,
                                                    i_prof.institution,
                                                    i_prof.software) hour_interv_preview,
                   nvl(pk_date_utils.date_send_tsz(i_lang, st.dt_interv_start_tstz, i_prof), 0) hour_interv_start,
                   nvl(r.desc_room_abbreviation, pk_translation.get_translation(i_lang, r.code_abbreviation)) desc_room,
                   sr.flg_status room_status,
                   r.id_room,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', p.gender, i_lang) gender, -- LMAIA 16-05-2009
                   pk_patient.get_pat_age(i_lang, p.id_patient, i_prof.institution, i_prof.software) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) photo,
                   p.id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, p.id_patient, epis.id_episode, h.id_schedule) pat_name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, p.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, p.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, p.id_patient) pat_nd_icon,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, epis.id_episode, i_prof, pk_alert_constant.g_no) desc_intervention,
                   pk_sr_clinical_info.get_summary_diagnosis(i_lang, i_prof, s.id_episode) desc_diagnosis,
                   (SELECT decode(pt.prof_team_name, NULL, NULL, pt.prof_team_name || chr(10)) ||
                           pk_prof_utils.get_name_signature(i_lang, i_prof, td.id_prof_team_leader)
                      FROM professional pf, sr_prof_team_det td, prof_team pt
                     WHERE td.id_episode = s.id_episode
                       AND td.id_professional = td.id_prof_team_leader
                       AND td.flg_status = g_active
                       AND pf.id_professional = td.id_prof_team_leader
                       AND pt.id_prof_team(+) = td.id_prof_team
                       AND rownum < 2) prof_name,
                   pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof) dt_server,
                   NULL desc_obs,
                   s.flg_status flg_surg_status,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   '(' || pk_sr_tools.get_epis_team_number(i_lang, i_prof, epis.id_episode) || ')' team_number,
                   pk_sr_tools.get_principal_team(i_lang, i_prof, epis.id_episode) desc_team,
                   pk_sr_tools.get_team_grid_tooltip(i_lang, i_prof, epis.id_episode) name_prof_tooltip,
                   decode(pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule),
                          pk_alert_constant.g_no,
                          decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                                  i_prof,
                                                                                                  epis.id_episode,
                                                                                                  l_prof_cat,
                                                                                                  l_hand_off_type,
                                                                                                  pk_alert_constant.g_yes),
                                                              i_prof.id),
                                 -1,
                                 pk_alert_constant.g_yes,
                                 pk_alert_constant.g_no),
                          pk_alert_constant.g_no) prof_follow_add,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) prof_follow_remove
              FROM schedule_sr s,
                   schedule h,
                   patient p,
                   room r,
                   room_scheduled sr,
                   episode epis,
                   epis_info ei,
                   sr_surgery_record rec,
                   (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode
                      FROM room r, sr_room_status s
                     WHERE s.id_room(+) = r.id_room
                       AND (s.id_sr_room_state = get_last_room_status(s.id_room, g_type_room) OR
                            s.id_sr_room_state IS NULL)) m,
                   (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz
                      FROM sr_surgery_time st, sr_surgery_time_det std
                     WHERE st.id_sr_surgery_time = std.id_sr_surgery_time
                       AND st.flg_type = flg_interv_start
                       AND std.flg_status = flg_status_a) st
             WHERE s.dt_target_tstz BETWEEN l_dt_min AND l_dt_max
               AND s.id_institution = i_prof.institution
               AND ((EXISTS
                    (SELECT 1
                        FROM prof_room pr, room r1
                       WHERE pr.id_professional = i_prof.id
                         AND r1.id_room = pr.id_room
                         AND (pr.id_room = r.id_room OR
                             pr.id_room = (SELECT ei.id_room
                                              FROM epis_info ei
                                             WHERE ei.id_episode = epis.id_episode))) AND i_type = g_my_patients) OR
                   (i_type = g_all_patients) OR
                   (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                   pk_alert_constant.g_yes))
               AND h.id_schedule = s.id_schedule
               AND p.id_patient = s.id_patient
               AND sr.id_schedule(+) = s.id_schedule
               AND sr.flg_status(+) = g_active
               AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                   sr.id_room_scheduled IS NULL)
               AND r.id_room(+) = sr.id_room
               AND m.id_room(+) = sr.id_room
               AND rec.id_schedule_sr(+) = s.id_schedule_sr
               AND ei.id_schedule(+) = s.id_schedule
               AND epis.id_episode = s.id_episode
               AND st.id_episode(+) = epis.id_episode
               AND epis.flg_ehr != g_flg_ehr -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
             ORDER BY s.dt_target_tstz;
    
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
                                              'GET_GRID_NURSE_V2',
                                              o_error);
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_room);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados,
    *  para os auxiliares.
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/11/19
    * @altered by                Filipe Silva
    * @date                      2009/07/07
    * @Notas                     Change the date format because the grid is too small (ALERT-29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_aux_actv
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      NUMBER; --sys_config.value%TYPE;
        aux_sql      VARCHAR2(32000);
    
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_external_sys  VARCHAR2(4000 CHAR) := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => 'DATE_FORMAT_M011');
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show              := 'N';
        g_sysdate               := SYSDATE;
        g_sysdate_tstz          := current_timestamp;
    
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error := 'SET WHERE';
            pk_alertlog.log_debug(g_error);
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error := 'call pk_search.get_criteria_condition';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_AUX_ACTV',
                                                      o_error);
                    RETURN FALSE;
                
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || 'from schedule_sr sp,  patient pat, room r, ' ||
                   'institution i, room_scheduled sr,  ' ||
                   'grid_task gt, episode epis, professional p, sr_prof_team_det spt,  ' || 'epis_info ei, ' ||
                   '(select r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' ||
                   'from room r, sr_room_status s ' || 'where s.id_room(+) = r.id_room ' ||
                   'and (s.id_sr_room_state = (select max(id_sr_room_state) from sr_room_status s1 where s1.id_room = s.id_room) ' ||
                   'or not exists (select 1 from sr_room_status s1 where s1.id_room = s.id_room))) m, ' ||
                   'clin_record cr, pat_soc_attributes psa, epis_ext_sys ees ' || 'where sp.id_institution = :1 ' ||
                   'and pat.id_patient = sp.id_patient ' || 'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' ||
                   'and r.id_room(+) = sr.id_room and m.id_room(+) = r.id_room ' ||
                   'and i.id_institution = sp.id_institution ' || 'and ei.id_episode(+) = sp.id_episode ' ||
                   'and epis.id_episode = sp.id_episode ' || 'and epis.flg_status = :2 ' ||
                   'and gt.id_episode (+) = epis.id_episode ' || 'and psa.id_patient (+) = pat.id_patient ' ||
                   ' and psa.id_institution(+) = :3 ' || 'and cr.id_patient(+) = pat.id_patient ' ||
                   'and cr.id_institution(+) = :4 ' || 'and spt.id_episode(+) = epis.id_episode ' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and ees.id_episode(+) = epis.id_episode ' || 'and ees.id_institution(+) = ' || i_prof.institution ||
                   ' and ees.id_external_sys(+) = ' || l_id_external_sys || ' ' || 'and sp.flg_status = ''' || g_active || '''' ||
                   ' and sp.dt_target_tstz is not null ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --'and v.id_visit = epis.id_visit ' ||
                   l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        pk_alertlog.log_debug(g_error);
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.institution, g_active, i_prof.institution, i_prof.institution;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'select sp.id_schedule, sp.id_episode, ' || 'pk_date_utils.dt_chr_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')) dt_interv_preview,  ' ||
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software ||
                   '), sp.dt_interv_preview_tstz, null), pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), current_timestamp, null), pk_date_utils.date_send_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || 'pk_date_utils.date_send_tsz(' || i_lang ||
                   ', sp.dt_interv_preview_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '))) hour_interv_preview_send, ' ||
                   'decode(pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software ||
                   '), sp.dt_interv_preview_tstz, null), pk_date_utils.trunc_insttimezone(PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), sysdate, null), pk_date_utils.date_char_hour_tsz(' || i_lang || ', sp.dt_interv_preview_tstz, ' ||
                   i_prof.institution || ', ' || i_prof.software || '), ' || 'pk_date_utils.to_char_insttimezone(' ||
                   i_lang || ',PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software ||
                   '), sp.dt_interv_preview_tstz, ''' || l_date_format_m011 || ''')) hour_interv_preview,' ||
                   'nvl(pk_date_utils.date_char_hour_tsz(' || i_lang || ', st.dt_interv_start_tstz, ' ||
                   i_prof.institution || ', ' || i_prof.software || '), 0) hour_interv_start, ' ||
                   'nvl(pk_date_utils.get_elapsed_sysdate_tsz(' || i_lang ||
                   ', m.dt_status_tstz), 0) dt_elapsed_time, ' || 'pk_date_utils.date_send_tsz(' || i_lang ||
                   ', current_timestamp, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')) dt_server, ' || --
                  --LMAIA 16-05-2009
                   'pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender,' || i_lang || ') gender, ' || --
                  -- END
                   'pat.id_patient,' || --
                   'pk_patient.get_pat_name(' || i_lang || ', profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), pat.id_patient, epis.id_episode, sp.id_schedule) pat_name, ' || --
                   'pk_patient.get_pat_name_to_sort(' || i_lang || ', profissional(' || i_prof.id || ',' || --
                   i_prof.institution || ',' || i_prof.software || --
                   '), pat.id_patient, epis.id_episode) name_pat_to_sort, ' || --
                   'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                   'pk_hand_off_api.get_resp_icons(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), epis.id_episode, ''' || l_hand_off_type ||
                   ''') resp_icons, ' || --
                   'pk_adt.get_pat_non_disc_options(' || i_lang || ',profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_ndo, ' || --
                   'pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), pat.id_patient) pat_nd_icon, ' || --
                   'pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ', ' ||
                   i_prof.software || ') pat_age,  ' || --
                   'pk_patphoto.get_pat_photo(' || i_lang || ', profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software ||
                   '), pat.id_patient, epis.id_episode, sp.id_schedule) photo, gt.hemo_req, ' || --
                   'nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) desc_room,  ' || 'nvl(m.flg_status, ''F'') room_status_det,  ' ||
                   'r.id_room, ' || 'pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_ROOM_STATUS.FLG_STATUS'', nvl(m.flg_status, ''F'') ) room_status,  ' ||
                   'pk_date_utils.date_send_tsz(' || i_lang || ', m.dt_status_tstz, profissional(' || i_prof.id || ', ' ||
                   i_prof.institution || ', ' || i_prof.software || ')) dt_room_status,  ' ||
                   'nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation))  room_abbreviation, ' ||
                   'decode(ei.flg_urgency, ''Y'', ''U'', decode(sp.id_sched_sr_parent, null, ''N'', ''R'')) flg_rescheduled, ' ||
                   'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), aux.DESC_DRUG_REQ) DESC_DRUG_REQ, ' ||
                   'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), aux.DESC_HARVEST) DESC_HARVEST, ' ||
                   'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), aux.DESC_CLI_REC_REQ) DESC_CLI_REC_REQ, ' ||
                   'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), aux.desc_mov) DESC_MOV, ' ||
                   'sp.flg_status flg_surg_status, ' || 'gt.supplies desc_supplies ' ||
                   'from schedule_sr sp,  patient pat, room r, institution i, room_scheduled sr,   ' ||
                   'grid_task gt, episode epis, epis_info ei, v_sr_grid_aux_schedule aux, epis_ext_sys ees, ' ||
                   ' (select r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' ||
                   'from room r, sr_room_status s ' || 'where s.id_room(+) = r.id_room ' ||
                   'and (s.id_sr_room_state = (select max(id_sr_room_state) from sr_room_status s1 where s1.id_room = s.id_room) ' ||
                   '  or not exists (select 1 from sr_room_status s1 where s1.id_room = s.id_room))) m, ' ||
                   '( select std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' ||
                   'from sr_surgery_time st, sr_surgery_time_det std ' ||
                   'where st.id_sr_surgery_time = std.id_sr_surgery_time ' || 'and st.flg_type = ''' ||
                   flg_interv_start || '''' || 'and std.flg_status=''' || flg_status_a || ''' ) st, ' ||
                   'clin_record cr, pat_soc_attributes psa, professional p, sr_prof_team_det spt  ' ||
                   'where sp.id_institution = ' || i_prof.institution || ' ' || 'and aux.id_software(+) = ' ||
                   i_prof.software || ' ' || 'and aux.id_instit_requested(+) = ' || i_prof.institution || ' ' ||
                   'and m.id_room(+) = r.id_room ' || 'and sp.id_episode = aux.id_episode(+) ' ||
                   'and pat.id_patient = sp.id_patient ' || 'and sr.id_schedule(+) = sp.id_schedule ' ||
                   'AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS  (SELECT 1 ' ||
                   '    FROM room_scheduled  WHERE id_schedule = sp.id_schedule)) ' || 'and r.id_room(+) = sr.id_room ' ||
                   'and i.id_institution = sp.id_institution ' || 'and ei.id_episode(+) = sp.id_episode ' ||
                   'and epis.id_episode = sp.id_episode ' || 'and epis.flg_status = ''' || g_active || '''' || ' ' ||
                   'and gt.id_episode (+) = epis.id_episode ' || 'and psa.id_patient (+) = pat.id_patient ' ||
                   'and psa.id_institution(+) = ' || i_prof.institution || ' and cr.id_patient(+) = pat.id_patient ' ||
                   'and cr.id_institution(+) = ' || i_prof.institution || ' ' ||
                   'and spt.id_episode(+) = epis.id_episode ' || 'and spt.flg_status(+) =''' || flg_status_a || '''' ||
                   'and (spt.id_professional = spt.id_prof_team_leader ' ||
                   ' or not exists (select 1 from sr_prof_team_det spt1 where spt1.id_episode = epis.id_episode and flg_status=''' ||
                   flg_status_a || ''')) ' || 'and p.id_professional(+) = spt.id_prof_team_leader ' ||
                   'and ees.id_episode(+) = epis.id_episode ' || 'and ees.id_institution(+) = ' || i_prof.institution ||
                   ' and ees.id_external_sys(+) = ' || l_id_external_sys || ' ' ||
                   'and st.id_episode (+) = epis.id_episode ' || 'and sp.flg_status = ''' || g_active || '''' ||
                   ' and sp.dt_target_tstz is not null ' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                  --'and v.id_visit = epis.id_visit ' ||
                   l_where || 'order by sp.dt_target_tstz ';
    
        OPEN o_pat FOR aux_sql;
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_AUX_ACTV', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_AUX_ACTV', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_AUX_ACTV',
                                              o_error);
        
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Efectuar pesquisa de doentes INACTIVOS, de acordo com os critérios seleccionados,
    *  para os auxiliares.
    *
    * @param i_lang              Id do idioma
    * @param i_id_sys_btn_crit   Lista de ID'S de critérios de pesquisa.
    * @param i_crit_val          Lista de valores dos critérios de pesquisa
    * @param i_instit            Instituição
    * @param i_epis_type         Tipo de consulta
    * @param i_dt                Data a pesquisar. Se for null assume a data de sistema
    * @param i_prof              Id do profissional, instituição e software
    * @param i_prof_cat_type     Tipo de categoria do profissional
    * 
    * @param o_flg_show          Indica se deve mostrar a mensagem
    * @param o_msg               Mensagem de validação a mostrar
    * @param o_msg_title         Título da mensagem de validação
    * @param o_button            Botões a disponibilizar
    * @param o_pat               Doentes activos
    * @param o_mess_no_result    Mensagem quando a pesquisa não devolver resultados
    * @param o_wait_icon         Nome do icone a mostrar quando não há data prevista para a realização da cirurgia
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/11/19
    * @altered by                Filipe Silva
    * @date                      2009/07/07
    * @Notas                     Change the date format because the grid is too small (ALERT-29499)
       ********************************************************************************************/

    FUNCTION get_search_grid_aux_inactv
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_wait_icon       OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      NUMBER;
        aux_sql      VARCHAR2(32000);
    
        l_grp_insts     table_number;
        l_hand_off_type sys_config.value%TYPE;
    
        l_id_external_sys  VARCHAR2(4000 CHAR) := pk_sysconfig.get_config(i_code_cf   => 'ID_EXTERNAL_SYS',
                                                                          i_prof_inst => i_prof.institution,
                                                                          i_prof_soft => i_prof.software);
        l_date_format_m011 VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                         i_code_mess => 'DATE_FORMAT_M011');
    
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        o_wait_icon := g_waiting_icon;
    
        g_sysdate_tstz          := current_timestamp;
        g_sysdate_char          := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        g_date_hour_send_format := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        o_flg_show              := 'N';
        l_limit                 := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --lê critérios de pesquisa e preenche cláusula where
            g_error := 'SET WHERE';
            pk_alertlog.log_debug(g_error);
            v_where_cond := NULL;
        
            IF i_id_sys_btn_crit(i) IS NOT NULL
            THEN
                g_error := 'CALL PK_SEARCH.GET_CRITERIA_CONDITION';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    pk_alert_exceptions.reset_error_state;
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_package_owner,
                                                      g_package_name,
                                                      'GET_SEARCH_GRID_AUX_INACTIV',
                                                      o_error);
                    RETURN FALSE;
                END IF;
            
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'GET INSTs GRP';
        pk_alertlog.log_debug(g_error);
        SELECT column_value
          BULK COLLECT
          INTO l_grp_insts
          FROM TABLE(pk_list.tf_get_all_inst_group(i_prof.institution, g_inst_grp_flg_rel_adt));
    
        g_error := 'GET COUNT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT COUNT(epis.id_episode) ' || --
                   '  FROM schedule_sr t, ' || --
                   '       patient pat, ' || --
                   '       room r, ' || --
                   '       institution i, ' || --
                   '       room_scheduled sr, ' || --
                   '       grid_task gt, ' || --
                   '       episode epis, ' || --
                   '       epis_info ei, ' || --
                   '       (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '          FROM room r, sr_room_status s ' || --
                   '         WHERE s.id_room(+) = r.id_room ' || --
                   '           AND (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                        FROM sr_room_status s1 ' || --
                   '                                       WHERE s1.id_room = s.id_room) OR NOT EXISTS (SELECT 1 ' || --
                   '                   FROM sr_room_status s1 ' || --
                   '                  WHERE s1.id_room = s.id_room))) m, ' || --
                   '       clin_record cr, ' || --
                   '       pat_soc_attributes psa, ' || --
                   '       epis_ext_sys ees, ' || --
                   '       professional p, ' || --
                   '       sr_prof_team_det spt ' || --
                   ' WHERE t.id_institution IN (SELECT * ' || --
                   '                               FROM TABLE(:1)) ' || --
                   '   AND pat.id_patient = t.id_patient ' || --
                   '   AND sr.id_schedule(+) = t.id_schedule ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = t.id_schedule)) ' || --
                   '   AND r.id_room(+) = sr.id_room ' || --
                   '   AND m.id_room(+) = r.id_room ' || --
                   '   AND i.id_institution = t.id_institution ' || --
                   '   AND ei.id_episode(+) = t.id_episode ' || --
                   '   AND epis.id_episode = t.id_episode ' || --
                   '   AND epis.flg_status != :2 ' || --
                   '   AND gt.id_episode(+) = epis.id_episode ' || --
                   '   AND psa.id_patient(+) = pat.id_patient ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:3)) OR psa.id_institution IS NULL) ' || --
                   '   AND cr.id_patient(+) = pat.id_patient ' || --
                   '   AND (cr.id_institution IN (SELECT * ' || --
                   '                                FROM TABLE(:4)) OR cr.id_institution IS NULL) ' || --
                   '   AND spt.id_episode(+) = epis.id_episode ' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || flg_status_a || ''')) ' || --
                   '   AND p.id_professional(+) = spt.id_prof_team_leader ' || --
                   '   AND ees.id_episode(+) = epis.id_episode ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:5)) OR ees.id_institution IS NULL) ' || --
                   '   AND ees.id_external_sys(+) = ' || l_id_external_sys || ' ' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE COUNT';
        pk_alertlog.log_debug(g_error);
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING l_grp_insts, g_active, l_grp_insts, l_grp_insts, l_grp_insts;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        pk_alertlog.log_debug(g_error);
        aux_sql := 'SELECT t.id_schedule, ' || --
                   '       t.id_episode, ' || --
                   '       pk_date_utils.dt_chr_tsz(' || i_lang || ', ' || --
                   '                                t.dt_interv_preview_tstz, ' || --
                   '                                profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')) dt_interv_preview, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               t.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          t.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')), ' || --
                   '              pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                          t.dt_interv_preview_tstz, ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '))) hour_interv_preview_send, ' || --
                   '       decode(pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               t.dt_interv_preview_tstz, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.trunc_insttimezone(profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                               current_timestamp, ' || --
                   '                                               NULL), ' || --
                   '              pk_date_utils.date_char_hour_tsz(' || i_lang || ', t.dt_interv_preview_tstz, ' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '              pk_date_utils.to_char_insttimezone(' || i_lang || ', ' || --
                   '                                                 profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                                 t.dt_interv_preview_tstz, ' || --
                   '                                                 ''' || l_date_format_m011 ||
                   ''')) hour_interv_preview, ' || --
                   '       nvl(pk_date_utils.date_char_hour_tsz(' || i_lang || ', st.dt_interv_start_tstz, ' ||
                   i_prof.institution || ',' || i_prof.software || '), 0) hour_interv_start, ' || --
                   '       nvl(pk_date_utils.get_elapsed_sysdate_tsz(' || i_lang ||
                   ', m.dt_status_tstz), 0) dt_elapsed_time, ' || --
                   '       pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                   current_timestamp, ' || --
                   '                                   profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')) dt_server, ' || --
                   '       gt.hemo_req, ' || --
                   '       pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
                   '       pat.id_patient, ' || --
                   '       pk_patient.get_pat_name(' || i_lang || ', ' || --
                   '                               profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                               pat.id_patient, ' || --
                   '                               epis.id_episode, ' || --
                   '                               t.id_schedule) pat_name, ' || --
                   '       pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient, ' || --
                   '                                       epis.id_episode) name_pat_to_sort, ' || --
                   '       pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
                   '       pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || --
                   '                                      profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                      epis.id_episode, ' || --
                   '                                      ''' || l_hand_off_type || ''') resp_icons, ' || --
                   '       pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || --
                   '                                       profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                       pat.id_patient) pat_ndo, ' || --
                   '       pk_patient.get_pat_age(' || i_lang || ', pat.id_patient, ' || i_prof.institution || ',' ||
                   i_prof.software || ') pat_age, ' || --
                   '       pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || --
                   '                                          profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                          pat.id_patient) pat_nd_icon, ' || --
                   '       pk_patphoto.get_pat_photo(' || i_lang || ', ' || --
                   '                                 profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                 pat.id_patient, ' || --
                   '                                 epis.id_episode, ' || --
                   '                                 t.id_schedule) photo, ' || --
                   '       nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) desc_room, ' || --
                   '       nvl(m.flg_status, ''F'') room_status_det, ' || --
                   '       r.id_room, ' || --
                   '       pk_sysdomain.get_img(' || i_lang ||
                   ', ''SR_ROOM_STATUS.FLG_STATUS'', nvl(m.flg_status, ''F'')) room_status, ' || --
                   '       pk_date_utils.date_send_tsz(' || i_lang || ', ' || --
                   '                                   m.dt_status_tstz, ' || --
                   '                                   profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || ')) dt_room_status, ' || --
                   '       nvl(r.desc_room_abbreviation, pk_translation.get_translation(' || i_lang ||
                   ', r.code_abbreviation)) room_abbreviation, ' || --
                   '       decode(ei.flg_urgency, ''Y'', ''U'', decode(t.id_sched_sr_parent, NULL, ''N'', ''R'')) flg_rescheduled, ' || --
                   '       pk_grid.convert_grid_task_str(' || i_lang || ', ' || --
                   '                                     profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                     aux.desc_drug_req) desc_drug_req, ' || --
                   '       pk_grid.convert_grid_task_str(' || i_lang || ', ' || --
                   '                                     profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                     aux.desc_harvest) desc_harvest, ' || --
                   '       pk_grid.convert_grid_task_str(' || i_lang || ', ' || --
                   '                                     profissional(' || i_prof.id || ',' || i_prof.institution || ',' ||
                   i_prof.software || '), ' || --
                   '                                     aux.desc_cli_rec_req) desc_cli_rec_req, ' || --
                   '       pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', ' || --
                   '                                              profissional(' || i_prof.id || ',' ||
                   i_prof.institution || ',' || i_prof.software || '), ' || --
                   '                                              aux.desc_mov) desc_mov, ' || --
                   '       t.flg_status flg_surg_status, ' || --
                   '       gt.supplies desc_supplies ' || --
                   '  FROM schedule_sr t, ' || --
                   '       patient pat, ' || --
                   '       room r, ' || --
                   '       institution i, ' || --
                   '       room_scheduled sr, ' || --
                   '       grid_task gt, ' || --
                   '       episode epis, ' || --
                   '       epis_info ei, ' || --
                   '       v_sr_grid_aux_schedule aux, ' || --
                   '       epis_ext_sys ees, ' || --
                   '       (SELECT r.id_room, s.flg_status, s.dt_status_tstz, s.id_episode ' || --
                   '          FROM room r, sr_room_status s ' || --
                   '         WHERE s.id_room(+) = r.id_room ' || --
                   '           AND (s.id_sr_room_state = (SELECT MAX(id_sr_room_state) ' || --
                   '                                        FROM sr_room_status s1 ' || --
                   '                                       WHERE s1.id_room = s.id_room) OR NOT EXISTS (SELECT 1 ' || --
                   '                   FROM sr_room_status s1 ' || --
                   '                  WHERE s1.id_room = s.id_room))) m, ' || --
                   '       (SELECT std.id_episode, std.dt_surgery_time_det_tstz dt_interv_start_tstz ' || --
                   '          FROM sr_surgery_time st, sr_surgery_time_det std ' || --
                   '         WHERE st.id_sr_surgery_time = std.id_sr_surgery_time ' || --
                   '           AND st.flg_type = ''' || flg_interv_start || '''' || --
                   '           AND std.flg_status = ''' || flg_status_a || ''') st, ' || --
                   '       clin_record cr, ' || --
                   '       pat_soc_attributes psa, ' || --
                   '       sr_prof_team_det spt ' || --
                   ' WHERE t.id_institution IN (SELECT * ' || --
                   '                               FROM TABLE(:l_grp_insts)) ' || --
                   '   AND aux.id_software(+) = ' || i_prof.software || --
                   '   AND (aux.id_instit_requested IN (SELECT * ' || --
                   '                                      FROM TABLE(:l_grp_insts)) OR aux.id_instit_requested IS NULL) ' || --
                   '   AND m.id_room(+) = r.id_room ' || --
                   '   AND t.id_episode = aux.id_episode(+) ' || --
                   '   AND pat.id_patient = t.id_patient ' || --
                   '   AND sr.id_schedule(+) = t.id_schedule ' || --
                   '   AND (sr.id_room_scheduled = ei.id_room_scheduled OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM room_scheduled ' || --
                   '          WHERE id_schedule = t.id_schedule)) ' || --
                   '   AND r.id_room(+) = sr.id_room ' || --
                   '   AND i.id_institution = t.id_institution ' || --
                   '   AND ei.id_schedule(+) = t.id_schedule ' || --
                   '   AND epis.id_episode = t.id_episode ' || --
                   '   AND epis.flg_status != ''' || g_active || '''' || --
                   '   AND gt.id_episode(+) = epis.id_episode ' || --
                   '   AND psa.id_patient(+) = pat.id_patient ' || --
                   '   AND (psa.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:l_grp_insts)) OR psa.id_institution IS NULL) ' || --
                   '   AND cr.id_patient(+) = pat.id_patient ' || --
                   '   AND (cr.id_institution IN (SELECT * ' || --
                   '                                FROM TABLE(:l_grp_insts)) OR cr.id_institution IS NULL) ' || --
                   '   AND spt.id_episode(+) = epis.id_episode ' || --
                   '   AND spt.flg_status = ''' || g_active || '''' || --
                   '   AND (spt.id_professional = spt.id_prof_team_leader OR NOT EXISTS ' || --
                   '        (SELECT 1 ' || --
                   '           FROM sr_prof_team_det spt1 ' || --
                   '          WHERE spt1.id_episode = epis.id_episode ' || --
                   '            AND flg_status = ''' || g_active || ''')) ' || --
                   '   AND ees.id_episode(+) = epis.id_episode ' || --
                   '   AND (ees.id_institution IN (SELECT * ' || --
                   '                                 FROM TABLE(:l_grp_insts)) OR ees.id_institution IS NULL) ' || --
                   '   AND ees.id_external_sys(+) = ' || l_id_external_sys || --
                   '   AND st.id_episode(+) = epis.id_episode ' || l_where || --
                   ' ORDER BY t.dt_target_tstz ';
    
        g_error := 'OPEN O_PAT';
        OPEN o_pat FOR aux_sql
            USING l_grp_insts, l_grp_insts, l_grp_insts, l_grp_insts, l_grp_insts;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_noresults THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.noresult_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_AUX_INACTV', o_error);
        WHEN pk_search.e_overlimit THEN
            pk_types.open_my_cursor(o_pat);
        
            RETURN pk_search.overlimit_handler(i_lang, i_prof, g_pck_name, 'GET_SEARCH_GRID_AUX_INACTV', o_error);
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SEARCH_GRID_AUX_INACTV',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
    END;

    /**************************************************************************
    * Returns the list of consents to be handled by the administrative        *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_notes                      notes                               *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_consent_list               Cursor of consent list              *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/10/21                              *
    **************************************************************************/
    FUNCTION get_consent_admin_grid
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_consent_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_gap_hours     NUMBER;
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        g_sysdate_tstz := current_timestamp;
    
        l_gap_hours := to_number(nvl(pk_sysconfig.get_config('SR_CONSENT_ADM_GRID_TIME_WINDOW', i_prof), 24));
    
        g_error := 'open o_consent_list cursor';
        pk_alertlog.log_debug(g_error);
        OPEN o_consent_list FOR
            SELECT ss.id_schedule_sr,
                   ss.id_episode,
                   ss.id_patient,
                   nvl(sc.flg_status, g_sr_consent_o) flg_status,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, ss.id_patient, epis.id_episode, ss.id_schedule) photo,
                   (SELECT pk_patient.get_gender(i_lang, gender) gender
                      FROM patient
                     WHERE id_patient = ss.id_patient) gender,
                   pk_patient.get_pat_age(i_lang, ss.id_patient, i_prof) pat_age,
                   pk_patient.get_pat_name(i_lang, i_prof, ss.id_patient, ss.id_episode, ss.id_schedule) name,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, ss.id_patient, ss.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, ss.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, ss.id_patient) pat_nd_icon,
                   pk_patient.get_pat_short_name(ss.id_patient) name_short,
                   pk_hea_prv_aux.get_process(i_lang, i_prof, ss.id_patient, pi.id_pat_identifier) clin_proc_desc,
                   (CASE
                        WHEN pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                                  i_prof,
                                                                  nvl(epis.id_prev_episode, epis.id_episode),
                                                                  nvl(epis.id_prev_epis_type, epis.id_epis_type),
                                                                  ', ') IS NOT NULL THEN
                         pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                              i_prof,
                                                              nvl(epis.id_prev_epis_type, epis.id_epis_type)) || ' (' ||
                         pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                              i_prof,
                                                              nvl(epis.id_prev_episode, epis.id_episode),
                                                              nvl(epis.id_prev_epis_type, epis.id_epis_type),
                                                              ', ') || ')'
                        ELSE
                         pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                              i_prof,
                                                              nvl(epis.id_prev_epis_type, epis.id_epis_type))
                    END) origin_desc,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang, ss.id_episode, i_prof, pk_alert_constant.g_no) ps_desc,
                   (SELECT pk_date_utils.dt_chr_date_hour(i_lang, sei.dt_req_tstz, i_prof)
                      FROM sr_epis_interv sei
                     WHERE sei.id_episode = ss.id_episode
                       AND sei.flg_status != g_sr_epis_interv_c
                       AND rownum = 1) dt_req,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, ss.id_prof_reg) prof_name,
                   pk_utils.get_status_string_immediate(i_lang,
                                                        i_prof,
                                                        pk_alert_constant.g_display_type_icon,
                                                        nvl(sc.flg_status, g_sr_consent_o),
                                                        NULL,
                                                        NULL,
                                                        'SR_CONSENT.FLG_STATUS',
                                                        NULL,
                                                        pk_alert_constant.g_color_null,
                                                        pk_alert_constant.g_color_icon_dark_grey,
                                                        NULL,
                                                        NULL,
                                                        NULL,
                                                        g_sysdate_tstz) icon_name,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons
              FROM schedule_sr ss
              JOIN sr_surgery_record ssr
                ON ssr.id_schedule_sr = ss.id_schedule_sr
              JOIN pat_identifier pi
                ON pi.id_patient = ss.id_patient
               AND pi.id_institution = ss.id_institution
              JOIN episode epis
                ON epis.id_episode = ss.id_episode
              LEFT JOIN (SELECT sc.id_sr_consent, sc.id_schedule_sr, sc.flg_status, sc.dt_reg
                           FROM sr_consent sc
                          WHERE flg_status != pk_alert_constant.g_schedule_sr_status_i) sc
                ON sc.id_schedule_sr = ss.id_schedule_sr
             WHERE ss.flg_status = pk_alert_constant.g_schedule_sr_status_a
               AND ss.id_institution = i_prof.institution
               AND ssr.flg_sr_proc IN (g_sr_proc_p, g_sr_proc_a)
                  --@TODO validate by physician sign and patient sign ???              
               AND (sc.flg_status IS NULL OR
                   (sc.flg_status = g_sr_consent_a AND sc.dt_reg > (g_sysdate_tstz - l_gap_hours / 24)));
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_consent_list);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_CONSENT_ADMIN_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_consent_list);
            RETURN FALSE;
    END get_consent_admin_grid;

    /************************************************************************************************
    * Returns the list POS to physician validate                                                    *
    *                                                                                               *
    * @param i_lang                       language id                                               *
    * @param i_prof                       professional, software and                                *
    *                                     institution ids                                           *
    * @param i_type                       type of search: D - Scheduled consults  for the physician,*
    *                                     C -Scheduled consults for the physician's clinical service*
    *                                                                                               *
    * @param o_POS_list                   Cursor of POS list                                        *
    * @param o_error                      Error message                                             *
    *                                                                                               *
    * @return                            Returns boolean                                            *
    *                                                                                               *
    * @author                            Filipe Silva                                               *
    * @version                           2.6.0.1                                                    *
    * @since                             2010/04/15                                                 *
    *************************************************************************************************/
    FUNCTION get_open_pos_grid
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_type     IN VARCHAR2,
        o_pos_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_sr_pos_status sr_pos_status.id_sr_pos_status%TYPE;
        l_gap_hours        NUMBER;
        l_prof_cat         category.flg_type%TYPE;
        l_hand_off_type    sys_config.value%TYPE;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        l_gap_hours    := to_number(nvl(pk_sysconfig.get_config('POS_OUTP_GRID_TIME', i_prof), 24));
        l_prof_cat     := pk_edis_list.get_prof_cat(i_prof);
    
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'GET ID_SR_POS_STATUS';
        pk_alertlog.log_debug(g_error);
        pk_alertlog.log_debug(g_error);
        SELECT t.id_sr_pos_status
          INTO l_id_sr_pos_status
          FROM (SELECT sps.id_sr_pos_status, rank() over(ORDER BY sps.id_institution DESC) origin_rank
                  FROM sr_pos_status sps
                 WHERE sps.id_institution IN (0, i_prof.institution)
                   AND sps.flg_status = pk_alert_constant.g_sr_pos_status_nd
                   AND sps.flg_available = pk_alert_constant.g_available) t
         WHERE t.origin_rank = 1;
    
        g_error := 'OPEN CURSOR O_POS_LIST';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_pos_list FOR
            SELECT t.id_patient,
                   t.id_schedule,
                   t.id_sr_episode,
                   t.id_episode,
                   t.photo,
                   t.pat_name,
                   t.pat_ndo,
                   t.pat_nd_icon,
                   t.pat_age,
                   t.pat_gender,
                   t.desc_prof_req,
                   t.dt_surg_proc,
                   t.pos_appointment,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, t.id_visit, g_task_analysis, l_prof_cat) analysis_results,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, t.id_visit, g_task_exam, l_prof_cat) exams_results,
                   t.pos_status,
                   t.desc_intervention,
                   g_sysdate_char dt_server,
                   t.name_pat_to_sort,
                   t.pat_age_for_order_by,
                   t.resp_icons
              FROM (SELECT sr.id_patient,
                           s.id_schedule,
                           sr.id_episode id_sr_episode,
                           e.id_episode,
                           e.id_visit,
                           pk_patphoto.get_pat_photo(i_lang, i_prof, sr.id_patient, sr.id_episode, sr.id_schedule) photo,
                           pk_patient.get_pat_name(i_lang, i_prof, sr.id_patient, sr.id_episode, sr.id_schedule) pat_name,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, sr.id_patient, sr.id_episode) name_pat_to_sort,
                           pk_patient.get_julian_age(i_lang, p.dt_birth, p.age) pat_age_for_order_by,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, sr.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, sr.id_patient) pat_nd_icon,
                           pk_patient.get_pat_age(i_lang, sr.id_patient, i_prof) pat_age,
                           pk_patient.get_pat_gender(sr.id_patient) pat_gender,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, sr.id_prof_reg) desc_prof_req,
                           pk_date_utils.date_char_tsz(i_lang, sr.dt_target_tstz, i_prof.institution, i_prof.software) dt_surg_proc,
                           pk_date_utils.date_char_tsz(i_lang, s.dt_begin_tstz, i_prof.institution, i_prof.software) pos_appointment,
                           check_analysis_results(i_lang, i_prof, e.id_episode) analysis,
                           check_exams_results(i_lang, i_prof, e.id_episode) exams,
                           pk_surgery_request.get_sr_pos_status_str(i_lang,
                                                                    i_prof,
                                                                    sps.flg_status,
                                                                    sps.id_sr_pos_status,
                                                                    sr.id_waiting_list,
                                                                    sr.id_schedule_sr) pos_status,
                           pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                    sr.id_episode,
                                                                    i_prof,
                                                                    pk_alert_constant.g_no) desc_intervention,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons
                      FROM schedule_sr sr
                      JOIN sr_pos_schedule sps
                        ON sps.id_schedule_sr = sr.id_schedule_sr
                       AND sps.flg_status = g_active
                       AND (sps.id_sr_pos_status = l_id_sr_pos_status OR
                           sps.id_sr_pos_status != l_id_sr_pos_status AND
                           sps.dt_reg > current_timestamp - l_gap_hours / 24)
                      JOIN sr_pos_status sp
                        ON sp.id_sr_pos_status = sps.id_sr_pos_status
                      JOIN consult_req cr
                        ON cr.id_consult_req = sps.id_pos_consult_req
                       AND cr.id_episode = sr.id_episode
                       AND cr.flg_status != pk_alert_constant.g_cancelled
                      JOIN schedule s
                        ON s.id_schedule = cr.id_schedule
                       AND s.flg_status != pk_grid.g_sched_canc
                      JOIN epis_info ei
                        ON ei.id_schedule = cr.id_schedule
                      JOIN episode e
                        ON e.id_episode = ei.id_episode
                       AND e.flg_status != pk_alert_constant.g_cancelled
                      JOIN schedule_outp so
                        ON so.id_schedule = s.id_schedule
                      JOIN sch_prof_outp spo
                        ON spo.id_schedule_outp = so.id_schedule_outp
                      JOIN patient p
                        ON p.id_patient = sr.id_patient
                     WHERE ((i_type = g_consult_dep_clin_serv AND EXISTS
                            (SELECT 0
                                FROM prof_dep_clin_serv pdcs
                               WHERE pdcs.id_professional = i_prof.id
                                 AND pdcs.flg_status = pk_grid.g_selected
                                 AND pdcs.id_dep_clin_serv = s.id_dcs_requested)) OR
                           (i_type = g_scheduled_consult AND nvl(ei.id_professional, spo.id_professional) = i_prof.id))) t
             WHERE t.analysis = pk_alert_constant.get_yes
               AND t.exams = pk_alert_constant.get_yes
             ORDER BY t.pos_appointment DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_types.open_my_cursor(o_pos_list);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_OPEN_POS_GRID',
                                              o_error);
            pk_types.open_my_cursor(o_pos_list);
            RETURN FALSE;
    END get_open_pos_grid;

    /*************************************************************************\
    * Name :                 check_analysis_results                           *
    * Description:           Returns a flg  validating if all labtest         *
    *                        requests have results                            *
    *                        (USED BY ORIS PRODUCT)                           *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_id_episode    Input - Episode ID                               *
    *                                                                         *
    * @author                                                                 *
    * @version               2.6.0.1                                          *
    * @since                 2010/04/14                                       *
    \*************************************************************************/
    FUNCTION check_analysis_results
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_rec   VARCHAR2(1);
        l_error t_error_out;
    
    BEGIN
    
        SELECT (CASE
                    WHEN (COUNT(*) = 0 OR MAX(str_grid) IS NOT NULL) THEN
                     pk_alert_constant.g_yes
                    ELSE
                     pk_alert_constant.g_no
                END) show_rec
          INTO l_rec
          FROM (SELECT (CASE
                            WHEN type_stat = 'RESULT' THEN
                             CASE
                                 WHEN (SUM(stat_count) over(PARTITION BY type_stat) != total_stat_count) THEN
                                  NULL
                                 ELSE
                                  pk_alert_constant.g_yes
                             END
                            ELSE
                             NULL
                        END) str_grid
                  FROM (SELECT lte.flg_status_det,
                               (CASE
                                    WHEN lte.flg_status_det IN
                                         (pk_alert_constant.g_analysis_det_read, pk_alert_constant.g_analysis_det_result) THEN
                                     'RESULT'
                                    ELSE
                                     lte.flg_status_det
                                END) type_stat,
                               COUNT(lte.id_analysis_req_det) stat_count,
                               SUM(COUNT(lte.id_analysis_req_det)) over(ORDER BY id_episode) total_stat_count
                          FROM lab_tests_ea lte
                         WHERE lte.id_episode = i_id_episode
                           AND lte.flg_status_det NOT IN (pk_alert_constant.g_analysis_det_canc,
                                                          pk_alert_constant.g_analysis_det_review,
                                                          pk_alert_constant.g_analysis_det_ext)
                         GROUP BY lte.id_episode, lte.flg_status_det));
    
        RETURN l_rec;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_ANALYSIS_RESULTS',
                                              l_error);
            RETURN pk_alert_constant.g_no;
        
    END check_analysis_results;

    /*************************************************************************\
    * Name :                 check_exams_results                              *
    * Description:           Returns a flg  validating if all labtest         *
    *                        if all exams requests have results               *
    *                        (USED BY ORIS PRODUCT)                           *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_id_episode    Input - Episode ID                               *
    *                                                                         *
    * @author                                                                 *
    * @version               2.6.0.1                                          *
    * @since                 2010/04/14                                       *
    \*************************************************************************/
    FUNCTION check_exams_results
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_rec   VARCHAR2(1);
        l_error t_error_out;
    
    BEGIN
        SELECT (CASE
                    WHEN (COUNT(*) = 0 OR MAX(str_grid) IS NOT NULL) THEN
                     pk_alert_constant.g_yes
                    ELSE
                     pk_alert_constant.g_no
                END) show_rec
          INTO l_rec
          FROM (SELECT (CASE
                            WHEN type_stat = 'RESULT' THEN
                             CASE
                                 WHEN (SUM(stat_count) over(PARTITION BY type_stat) != total_stat_count) THEN
                                  NULL
                                 ELSE
                                  pk_alert_constant.g_yes
                             END
                            ELSE
                             NULL
                        END) str_grid
                  FROM (SELECT ee.flg_status_det,
                               (CASE
                                    WHEN ee.flg_status_det IN
                                         (pk_alert_constant.g_exam_det_result, pk_alert_constant.g_exam_det_read) THEN
                                     'RESULT'
                                    ELSE
                                     ee.flg_status_det
                                END) type_stat,
                               COUNT(ee.id_exam_req_det) stat_count,
                               SUM(COUNT(ee.id_exam_req_det)) over(ORDER BY id_episode) total_stat_count
                          FROM exams_ea ee
                         WHERE ee.id_episode = i_id_episode
                           AND ee.flg_status_det NOT IN
                               (pk_alert_constant.g_exam_det_canc, pk_alert_constant.g_exam_det_ext)
                         GROUP BY ee.id_episode, ee.flg_status_det));
    
        RETURN l_rec;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_EXAMS_RESULTS',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END check_exams_results;

    PROCEDURE initialize_params
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        k_lang             CONSTANT NUMBER(24) := 1;
        k_prof_id          CONSTANT NUMBER(24) := 2;
        k_prof_institution CONSTANT NUMBER(24) := 3;
        k_prof_software    CONSTANT NUMBER(24) := 4;
        k_episode          CONSTANT NUMBER(24) := 5;
        k_patient          CONSTANT NUMBER(24) := 6;
    
        g_yes                CONSTANT VARCHAR2(1 CHAR) := 'Y';
        l_msg_edis_grid_m003 CONSTANT sys_message.code_message%TYPE := 'EDIS_GRID_M003';
        l_prof               CONSTANT profissional := profissional(i_context_ids(k_prof_id),
                                                                   i_context_ids(k_prof_institution),
                                                                   i_context_ids(k_prof_software));
        l_lang               CONSTANT language.id_language%TYPE := i_context_ids(k_lang);
        l_patient            CONSTANT patient.id_patient%TYPE := i_context_ids(k_patient);
        l_episode            CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    
    BEGIN
    
        CASE i_name
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, o_vc2);
            WHEN 'g_yes' THEN
                o_vc2 := g_yes;
            WHEN 'l_msg_edis_grid_m003' THEN
                o_vc2 := l_msg_edis_grid_m003;
            WHEN 'l_dt_str' THEN
                o_tstz := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, NULL);
        END CASE;
    END initialize_params;

    /********************************************************************************************** 
    * Returns a list of days with appointments
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           Type of schedule for professional
    *                            A - All Schedule
    *                            P - Professional Schedule
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                Elisabete Bugalho
    * @Version               2.7.1.01
    * @since                 2017/04/10
    **********************************************************************************************/
    FUNCTION grid_surg_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
        l_dt_current       VARCHAR2(200);
    
        l_handoff_type sys_config.value%TYPE;
        l_prof_cat     category.flg_type%TYPE;
    
        l_sysdate_char_short VARCHAR2(8);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
        l_dt_current         := pk_date_utils.date_send_tsz(i_lang,
                                                            pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                            i_prof);
        ---------------------------------
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + CAST(l_num_days_forward AS NUMBER));
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT date_desc, date_tstz, decode(date_tstz, l_dt_current, 'Y', 'N') today
              FROM (SELECT pk_grid_amb.get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                            pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                       FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz) AS sp_date,
                                    s.dt_target_tstz
                               FROM schedule_sr       s,
                                    schedule          h,
                                    patient           p,
                                    room              r,
                                    institution       i,
                                    room_scheduled    sr,
                                    sr_surgery_record rec,
                                    episode           epis
                              WHERE s.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                AND s.id_institution = i_prof.institution
                                AND (((EXISTS (SELECT 1
                                                 FROM sr_prof_team_det td1
                                                WHERE td1.id_episode_context = s.id_episode
                                                  AND td1.id_professional = i_prof.id
                                                  AND td1.flg_status = g_active) AND i_type = g_my_patients) OR
                                    i_prof.id IN
                                    (SELECT column_value
                                         FROM TABLE(pk_hand_off_core.get_responsibles_id(i_lang,
                                                                                         i_prof,
                                                                                         epis.id_episode,
                                                                                         l_prof_cat,
                                                                                         l_handoff_type,
                                                                                         pk_alert_constant.g_yes)))) OR
                                    (i_type = g_all_patients) OR
                                    (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                                    pk_alert_constant.g_yes))
                                AND h.id_schedule = s.id_schedule
                                AND p.id_patient = s.id_patient
                                AND sr.id_schedule(+) = s.id_schedule
                                AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                                    sr.id_room_scheduled IS NULL)
                                AND r.id_room(+) = sr.id_room
                                AND i.id_institution = s.id_institution
                                AND rec.id_schedule_sr(+) = s.id_schedule_sr
                                AND epis.id_episode = s.id_episode
                                AND epis.flg_ehr != g_flg_ehr)
                     UNION -- union with current date in case there's no appoitment for today
                     (SELECT pk_grid_amb.get_extense_day_desc(i_lang,
                                                             pk_date_utils.date_send_tsz(i_lang,
                                                                                         pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                          g_sysdate_tstz),
                                                                                         i_prof)) date_desc,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                        i_prof) date_tstz
                       FROM dual))
             ORDER BY date_tstz;
    
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
                                              'GRID_SURG_DATES',
                                              o_error);
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
        
    END grid_surg_dates;

    FUNCTION get_last_room_status
    (
        i_record IN NUMBER,
        i_type   IN VARCHAR2
    ) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    
    BEGIN
    
        SELECT id
          BULK COLLECT
          INTO tbl_id
          FROM (SELECT id_sr_room_state id, s1.dt_status_tstz
                  FROM sr_room_status s1
                 WHERE s1.id_room = i_record
                   AND g_type_room = i_type
                UNION ALL
                SELECT id_room_scheduled id, rs.dt_room_scheduled_tstz dt_status_tstz
                  FROM room_scheduled rs
                 WHERE rs.id_schedule = i_record
                   AND g_type_sch = i_type
                   AND flg_status = g_active)
         ORDER BY dt_status_tstz DESC;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_last_room_status;

    /********************************************************************************************** 
    * Returns a list of days with appointments for nurse grids
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_type           Type of schedule for professional
    *                            A - All Schedule
    *                            P - Professional Schedule
    * @param o_date           days list
    * @param o_error          error
    *
    * @return                 false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                Elisabete Bugalho
    * @Version               2.7.1.01
    * @since                 2017/04/11
    **********************************************************************************************/
    FUNCTION get_grid_nurse_dates
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_date  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_num_days_back    sys_config.value%TYPE;
        l_num_days_forward sys_config.value%TYPE;
        l_dt_current       VARCHAR2(200);
    
        l_handoff_type sys_config.value%TYPE;
        l_prof_cat     category.flg_type%TYPE;
    
        l_sysdate_char_short VARCHAR2(8);
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        pk_hand_off_core.get_hand_off_type(i_lang => i_lang, i_prof => i_prof, io_hand_off_type => l_handoff_type);
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        l_sysdate_char_short := pk_date_utils.to_char_insttimezone(i_prof, g_sysdate_tstz, 'YYYYMMDD');
        l_dt_current         := pk_date_utils.date_send_tsz(i_lang,
                                                            pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                            i_prof);
        ---------------------------------
        g_error            := 'GET NUM DAYS';
        l_num_days_back    := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_BACK', i_prof);
        l_num_days_forward := pk_sysconfig.get_config('NUM_DAYS_CARE_GRID_NAVIGATION_FORWARD', i_prof);
    
        IF l_num_days_back <= 0
        THEN
            l_num_days_back := 10;
        END IF;
        IF l_num_days_forward <= 0
        THEN
            l_num_days_forward := 10;
        END IF;
    
        l_dt_begin := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz - CAST(l_num_days_back AS NUMBER));
        l_dt_end   := pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz + CAST(l_num_days_forward AS NUMBER));
    
        g_error := 'OPEN O_DATE';
        OPEN o_date FOR
            SELECT date_desc, date_tstz, decode(date_tstz, l_dt_current, 'Y', 'N') today
              FROM (SELECT pk_grid_amb.get_extense_day_desc(i_lang, pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof)) date_desc,
                            pk_date_utils.date_send_tsz(i_lang, sp_date, i_prof) date_tstz
                       FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz) AS sp_date,
                                    s.dt_target_tstz
                               FROM schedule_sr       s,
                                    schedule          h,
                                    patient           p,
                                    room              r,
                                    institution       i,
                                    room_scheduled    sr,
                                    sr_surgery_record rec,
                                    episode           epis,
                                    epis_info         ei
                              WHERE s.dt_target_tstz BETWEEN l_dt_begin AND l_dt_end
                                AND s.id_institution = i_prof.institution
                                AND ((EXISTS (SELECT 1
                                                FROM prof_room pr, room r1
                                               WHERE pr.id_professional = i_prof.id
                                                 AND r1.id_room = pr.id_room
                                                 AND (pr.id_room = r.id_room)) AND i_type = g_my_patients) OR
                                    (i_type = g_all_patients) OR
                                    (pk_prof_follow.get_follow_episode_by_me(i_prof, epis.id_episode, s.id_schedule) =
                                    pk_alert_constant.g_yes))
                                AND h.id_schedule = s.id_schedule
                                AND p.id_patient = s.id_patient
                                AND sr.id_schedule(+) = s.id_schedule
                                AND sr.flg_status(+) = g_active
                                AND (sr.id_room_scheduled = get_last_room_status(s.id_schedule, g_type_sch) OR
                                    sr.id_room_scheduled IS NULL)
                                AND r.id_room(+) = sr.id_room
                                AND i.id_institution = s.id_institution
                                AND rec.id_schedule_sr(+) = s.id_schedule_sr
                                AND ei.id_schedule(+) = s.id_schedule
                                AND epis.id_episode = s.id_episode
                                AND epis.flg_ehr != g_flg_ehr)
                     UNION -- union with current date in case there's no appoitment for today
                     (SELECT pk_grid_amb.get_extense_day_desc(i_lang,
                                                             pk_date_utils.date_send_tsz(i_lang,
                                                                                         pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                          g_sysdate_tstz),
                                                                                         i_prof)) date_desc,
                            pk_date_utils.date_send_tsz(i_lang,
                                                        pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                                        i_prof) date_tstz
                       FROM dual))
             ORDER BY date_tstz;
    
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
                                              'GET_grid_NURSE_dates',
                                              o_error);
            pk_types.open_my_cursor(o_date);
            RETURN FALSE;
        
    END get_grid_nurse_dates;

    FUNCTION get_value_for_clinical_q
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_content           IN VARCHAR2,
        i_type              IN VARCHAR2
    ) RETURN VARCHAR2 AS
    
        l_ret VARCHAR2(20 CHAR);
    
    BEGIN
    
        IF i_type = 'P'
        THEN
            BEGIN
                SELECT '0xD77300'
                  INTO l_ret
                  FROM sr_interv_quest_response siqr
                 INNER JOIN questionnaire_response qr
                    ON siqr.id_questionnaire = qr.id_questionnaire
                   AND siqr.id_response = qr.id_response
                 WHERE siqr.id_sr_epis_interv = i_id_sr_epis_interv
                   AND qr.id_content = i_content;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := NULL;
            END;
        ELSE
            BEGIN
                SELECT pk_mcdt.get_response_alias(i_lang, i_prof, 'RESPONSE.CODE_RESPONSE.' || qr.id_response)
                  INTO l_ret
                  FROM sr_interv_quest_response siqr
                 INNER JOIN questionnaire_response qr
                    ON siqr.id_questionnaire = qr.id_questionnaire
                   AND siqr.id_response = qr.id_response
                 WHERE siqr.id_sr_epis_interv = i_id_sr_epis_interv
                   AND qr.id_content = i_content;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := pk_sysdomain.get_domain(i_code_dom => 'YES_NO',
                                                     i_val      => pk_alert_constant.g_no,
                                                     i_lang     => i_lang);
            END;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_value_for_clinical_q;

    FUNCTION get_sr_grid_tracking_view
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_room         IN VARCHAR2,
        i_pat_states   IN VARCHAR2,
        i_page         IN NUMBER,
        i_id_room      IN room.id_room%TYPE,
        i_waiting_room IN VARCHAR2,
        o_grid         OUT pk_types.cursor_type,
        o_room_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_prof profissional := profissional(NULL, i_institution, pk_alert_constant.g_soft_oris);
    
        l_tbl_id_room    table_varchar;
        l_tbl_pat_states table_varchar;
        l_time_disch_rec NUMBER := pk_sysconfig.get_config('SR_TRV_TIME_DISCH_RECOVERY',
                                                           profissional(0, i_institution, 0));
    
        l_domain_sr_pat_status sys_domain.code_domain%TYPE := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        l_domain_sr_r_status   sys_domain.code_domain%TYPE := 'SR_ROOM_STATUS.FLG_STATUS';
        l_domain_pat_gender    sys_domain.code_domain%TYPE := 'PATIENT.GENDER.ABBR';
    
        l_id_content sys_config.value%TYPE := pk_sysconfig.get_config('SR_TRV_ID_CONTENT',
                                                                      profissional(0, i_institution, 0));
    
        l_tbl_id_content table_varchar;
        l_cnt_allergy    VARCHAR2(30 CHAR);
        l_cnt_biopsy     VARCHAR2(30 CHAR);
        l_sysdate        TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
    
        l_min_room NUMBER := CASE
                                 WHEN i_page = 1 THEN
                                  1
                                 ELSE
                                  1 + (i_page - 1) * 6
                             END;
        l_max_room NUMBER := i_page * 6;
    
    BEGIN
    
        l_tbl_id_room    := pk_string_utils.str_split(i_list => i_room, i_delim => '|');
        l_tbl_pat_states := pk_string_utils.str_split(i_list => i_pat_states, i_delim => '|');
        l_tbl_id_content := pk_string_utils.str_split(i_list => l_id_content, i_delim => '|');
    
        IF l_tbl_id_content IS NOT NULL
           AND l_tbl_id_content.count > 0
        THEN
            l_cnt_biopsy  := l_tbl_id_content(1);
            l_cnt_allergy := l_tbl_id_content(2);
        END IF;
    
        IF i_waiting_room = pk_alert_constant.g_yes
        THEN
        
            l_tbl_pat_states := table_varchar(pk_sr_grid.g_pat_status_v,
                                              pk_sr_grid.g_pat_status_f,
                                              pk_sr_grid.g_pat_status_y,
                                              pk_sr_grid.g_pat_status_d,
                                              pk_sr_grid.g_pat_status_p,
                                              pk_sr_grid.g_pat_status_r,
                                              pk_sr_grid.g_pat_status_s);
        END IF;
    
        OPEN o_room_list FOR
            SELECT r.id_room, pk_translation.get_translation(i_lang, r.code_room) desc_sched_room, r.flg_available
              FROM room r
             WHERE r.id_room IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  column_value
                                   FROM TABLE(l_tbl_id_room) t);
    
        OPEN o_grid FOR
            SELECT *
              FROM (SELECT t_epis.type_surgical,
                           t_epis.id_episode,
                           t_epis.id_room,
                           t_epis.gender,
                           t_epis.pat_age,
                           t_epis.id_patient,
                           decode(i_waiting_room,
                                  pk_alert_constant.g_yes,
                                  regexp_replace(t_epis.pat_name, '(^| )([^ ])([^ ])*', '\2. '),
                                  t_epis.pat_name) pat_name,
                           t_epis.pat_status,
                           t_epis.rank,
                           t_epis.desc_intervention,
                           t_epis.prof_name,
                           t_epis.hour_interv,
                           t_epis.need_biopsy,
                           t_epis.hour_interv_bg_color,
                           t_epis.duration,
                           t_epis.precaution_color
                      FROM (SELECT DISTINCT 'E' type_surgical,
                                            e.id_episode,
                                            nvl(rs.id_room, ro.id_room) id_room,
                                            pk_sysdomain.get_domain(l_domain_pat_gender, p.gender, i_lang) gender,
                                            pk_patient.get_pat_age(i_lang,
                                                                   p.id_patient,
                                                                   l_prof.institution,
                                                                   l_prof.software) pat_age,
                                            p.id_patient,
                                            pk_patient.get_pat_name(i_lang,
                                                                    profissional(0, l_prof.institution, l_prof.software),
                                                                    p.id_patient,
                                                                    e.id_episode,
                                                                    ss.id_schedule) pat_name,
                                            pk_sysdomain.get_img(i_lang,
                                                                 l_domain_sr_pat_status,
                                                                 nvl(decode(i_waiting_room,
                                                                            pk_alert_constant.g_yes,
                                                                            decode(srsr.flg_pat_status,
                                                                                   pk_sr_grid.g_pat_status_p,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   pk_sr_grid.g_pat_status_r,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   pk_sr_grid.g_pat_status_s,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   srsr.flg_pat_status),
                                                                            srsr.flg_pat_status),
                                                                     pk_sr_grid.g_pat_status_pend)) pat_status,
                                            pk_sysdomain.get_rank(i_lang, l_domain_sr_pat_status, srsr.flg_pat_status) rank,
                                            pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                     e.id_episode,
                                                                                     l_prof,
                                                                                     pk_alert_constant.g_no) desc_intervention,
                                            pk_prof_utils.get_name(i_lang, sptd.id_prof_team_leader) prof_name,
                                            pk_date_utils.date_hourmin_tsz(i_lang,
                                                                           ss.dt_interv_preview_tstz,
                                                                           l_prof.institution,
                                                                           l_prof.software) hour_interv,
                                            pk_sr_grid.get_value_for_clinical_q(i_lang,
                                                                                l_prof,
                                                                                sei.id_sr_epis_interv,
                                                                                l_cnt_biopsy,
                                                                                'B') need_biopsy,
                                            '0xC3000A' hour_interv_bg_color,
                                            to_char(trunc(SYSDATE) + ss.duration / 24 / 60, 'hh24:mi') duration,
                                            pk_sr_grid.get_value_for_clinical_q(i_lang,
                                                                                l_prof,
                                                                                sei.id_sr_epis_interv,
                                                                                l_cnt_allergy,
                                                                                'P') precaution_color
                              FROM episode e
                             INNER JOIN patient p
                                ON p.id_patient = e.id_patient
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
                              LEFT JOIN sr_prof_team_det sptd
                                ON sptd.id_episode_context = ei.id_episode
                              LEFT OUTER JOIN room ro
                                ON ro.id_room = ei.id_room
                             INNER JOIN sr_epis_interv sei
                                ON sei.id_episode_context = e.id_episode
                             WHERE e.id_epis_type = pk_alert_constant.g_epis_type_operating
                               AND ((i_id_room IS NOT NULL AND ss.dt_interv_preview_tstz BETWEEN trunc(l_sysdate) AND
                                   trunc(l_sysdate + 1) AND nvl(rs.id_room, ro.id_room) = i_id_room) OR
                                   (i_id_room IS NULL AND
                                   nvl(rs.id_room, ro.id_room) IN
                                   (SELECT column_value
                                        FROM (SELECT column_value, rownum rn /*+opt_estimate (table t rows=1)*/
                                                FROM TABLE(l_tbl_id_room)
                                               ORDER BY 1) t
                                       WHERE rn BETWEEN l_min_room AND l_max_room) AND
                                   ((ss.dt_interv_preview_tstz BETWEEN trunc(l_sysdate) AND trunc(l_sysdate + 1) AND
                                   srsr.flg_pat_status NOT IN (pk_sr_grid.g_pat_status_o, pk_sr_grid.g_pat_status_d)) OR
                                   (srsr.dt_flg_sr_proc + numtodsinterval(l_time_disch_rec, 'MINUTE') >= l_sysdate AND
                                   srsr.flg_pat_status = pk_sr_grid.g_pat_status_d) OR
                                   ss.dt_interv_preview_tstz BETWEEN l_sysdate AND trunc(l_sysdate + 1) AND
                                   srsr.flg_pat_status = pk_sr_grid.g_pat_status_o)))
                               AND srsr.flg_pat_status IN (SELECT column_value /*+opt_estimate (table t rows=1)*/
                                                             FROM TABLE(l_tbl_pat_states) t)) t_epis
                     WHERE id_episode NOT IN (SELECT ssr.id_episode
                                                FROM schedule_sr ssr
                                               INNER JOIN waiting_list wtl
                                                  ON wtl.id_waiting_list = ssr.id_waiting_list
                                                LEFT JOIN sr_pos_schedule pos
                                                  ON pos.id_schedule_sr = ssr.id_schedule_sr
                                               INNER JOIN episode e
                                                  ON ssr.id_patient = e.id_patient
                                               WHERE e.id_episode = e.id_episode
                                                 AND e.id_visit = e.id_visit
                                                 AND e.id_patient = e.id_patient)
                    UNION
                    SELECT t.type_surgical,
                           t.id_episode,
                           t.id_room,
                           t.gender,
                           t.pat_age,
                           t.id_patient,
                           decode(i_waiting_room,
                                  pk_alert_constant.g_yes,
                                  regexp_replace(t.pat_name, '(^| )([^ ])([^ ])*', '\2. '),
                                  t.pat_name) pat_name,
                           t.pat_status,
                           t.rank,
                           t.desc_intervention,
                           t.prof_name,
                           t.hour_interv,
                           t.need_biopsy,
                           t.hour_interv_bg_color,
                           t.duration,
                           precaution_color
                      FROM (SELECT DISTINCT CASE
                                                 WHEN wul.duration <= 1 THEN
                                                  'U'
                                                 ELSE
                                                  'P'
                                             END type_surgical,
                                            epis.id_episode,
                                            nvl(rs.id_room, ro.id_room) id_room,
                                            --ro.id_room id_room,
                                            pk_sysdomain.get_domain(l_domain_pat_gender, p.gender, i_lang) gender,
                                            pk_patient.get_pat_age(i_lang,
                                                                   p.id_patient,
                                                                   l_prof.institution,
                                                                   l_prof.software) pat_age,
                                            p.id_patient,
                                            pk_patient.get_pat_name(i_lang,
                                                                    profissional(0, l_prof.institution, l_prof.software),
                                                                    p.id_patient,
                                                                    epis.id_episode,
                                                                    ssr.id_schedule) pat_name,
                                            pk_sysdomain.get_img(i_lang,
                                                                 l_domain_sr_pat_status,
                                                                 nvl(decode(i_waiting_room,
                                                                            pk_alert_constant.g_yes,
                                                                            decode(srsr.flg_pat_status,
                                                                                   pk_sr_grid.g_pat_status_p,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   pk_sr_grid.g_pat_status_r,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   pk_sr_grid.g_pat_status_s,
                                                                                   pk_sr_grid.g_pat_status_v,
                                                                                   srsr.flg_pat_status),
                                                                            srsr.flg_pat_status),
                                                                     pk_sr_grid.g_pat_status_pend)) pat_status,
                                            pk_sysdomain.get_rank(i_lang, l_domain_sr_pat_status, srsr.flg_pat_status) rank,
                                            pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                                                     epis.id_episode,
                                                                                     l_prof,
                                                                                     pk_alert_constant.g_no) desc_intervention,
                                            pk_prof_utils.get_name(i_lang, sptd.id_prof_team_leader) prof_name,
                                            pk_date_utils.date_hourmin_tsz(i_lang,
                                                                           ssr.dt_interv_preview_tstz,
                                                                           l_prof.institution,
                                                                           l_prof.software) hour_interv,
                                            pk_sr_grid.get_value_for_clinical_q(i_lang,
                                                                                l_prof,
                                                                                sei.id_sr_epis_interv,
                                                                                l_cnt_biopsy,
                                                                                'B') need_biopsy,
                                            CASE
                                                 WHEN wul.duration <= 1 THEN
                                                  '0xF5D200'
                                                 ELSE
                                                  NULL
                                             END hour_interv_bg_color,
                                            to_char(trunc(SYSDATE) + ssr.duration / 24 / 60, 'hh24:mi') duration,
                                            pk_sr_grid.get_value_for_clinical_q(i_lang,
                                                                                l_prof,
                                                                                sei.id_sr_epis_interv,
                                                                                l_cnt_allergy,
                                                                                'P') precaution_color
                              FROM schedule_sr ssr
                             INNER JOIN waiting_list wtl
                                ON wtl.id_waiting_list = ssr.id_waiting_list
                             INNER JOIN wtl_urg_level wul
                                ON wtl.id_wtl_urg_level = wul.id_wtl_urg_level
                              LEFT JOIN sr_pos_schedule pos
                                ON pos.id_schedule_sr = ssr.id_schedule_sr
                              LEFT JOIN (SELECT id_sr_pos_status, flg_status
                                          FROM (SELECT sps1.id_sr_pos_status,
                                                       sps1.flg_status,
                                                       rank() over(ORDER BY sps1.id_institution DESC) origin_rank
                                                  FROM sr_pos_status sps1
                                                 WHERE sps1.id_institution IN (0, l_prof.institution))
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
                             INNER JOIN episode epis
                                ON ssr.id_episode = epis.id_episode
                             INNER JOIN epis_info ei
                                ON ei.id_episode = epis.id_episode
                              LEFT OUTER JOIN room ro
                                ON ro.id_room = ei.id_room
                             INNER JOIN patient p
                                ON p.id_patient = epis.id_patient
                              LEFT JOIN sr_prof_team_det sptd
                                ON sptd.id_episode_context = epis.id_episode
                             INNER JOIN sr_epis_interv sei
                                ON sei.id_episode_context = epis.id_episode
                             WHERE ((i_id_room IS NOT NULL AND ssr.dt_interv_preview_tstz BETWEEN trunc(l_sysdate) AND
                                   trunc(l_sysdate + 1) AND nvl(rs.id_room, ro.id_room) = i_id_room) OR
                                   (i_id_room IS NULL AND
                                   nvl(rs.id_room, ro.id_room) IN
                                   (SELECT column_value
                                        FROM (SELECT column_value, rownum rn /*+opt_estimate (table t rows=1)*/
                                                FROM TABLE(l_tbl_id_room)
                                               ORDER BY 1) t
                                       WHERE rn BETWEEN l_min_room AND l_max_room) AND
                                   ((ssr.dt_interv_preview_tstz BETWEEN trunc(l_sysdate) AND trunc(l_sysdate + 1) AND
                                   srsr.flg_pat_status NOT IN (pk_sr_grid.g_pat_status_o, pk_sr_grid.g_pat_status_d)) OR
                                   (srsr.dt_flg_sr_proc + numtodsinterval(l_time_disch_rec, 'MINUTE') >= l_sysdate AND
                                   srsr.flg_pat_status = pk_sr_grid.g_pat_status_d) OR
                                   ssr.dt_interv_preview_tstz BETWEEN l_sysdate AND trunc(l_sysdate + 1) AND
                                   srsr.flg_pat_status IN (pk_sr_grid.g_pat_status_o))))
                               AND srsr.flg_pat_status IN (SELECT column_value /*+opt_estimate (table t rows=1)*/
                                                             FROM TABLE(l_tbl_pat_states) t)) t
                     ORDER BY type_surgical DESC, rank, hour_interv)
             ORDER BY hour_interv;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        
    END get_sr_grid_tracking_view;
    -- EMR-437
    PROCEDURE setsql(i_sql IN VARCHAR2) IS
    BEGIN
        g_sql := i_sql;
    END;
    /**
    * Initialize parameters to be used in the grid query of ORIS
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/04/19
    */
    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_prof_cat                     category.flg_type%TYPE;
        l_hand_off_type                sys_config.value%TYPE;
        g_task_analysis                VARCHAR2(1) := 'A';
        g_task_exam                    VARCHAR2(1) := 'E';
        g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';
        g_pat_status_pend              VARCHAR2(1) := 'A';
        prof_yn                        VARCHAR2(1) := 'Y';
        l_str_date                     VARCHAR2(20);
        l_sel_date                     TIMESTAMP;
        l_date_lesser_limit            TIMESTAMP WITH LOCAL TIME ZONE;
    
        o_error t_error_out;
    
    BEGIN
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_institution', l_prof.institution);
        pk_context_api.set_parameter('i_software', l_prof.software);
    
        IF i_context_keys IS NOT NULL
           AND i_context_keys.count > 0
        THEN
            -- There is a date to use as filter
            l_str_date := i_context_keys(1);
            l_sel_date := to_timestamp(l_str_date, 'YYYYMMDDHH24MISS');
            pk_context_api.set_parameter('i_dt', l_str_date);
        
        ELSE
            l_sel_date := current_timestamp;
        END IF;
    
        g_error := 'PK_SR_GRID, parameter:' || i_name || ' not found';
        CASE i_name
        
            WHEN 'g_flg_ehr' THEN
                o_vc2 := g_flg_ehr;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'g_task_harvest' THEN
                o_vc2 := g_task_harvest;
            
            WHEN 'current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'flg_epis_disch' THEN
                o_vc2 := 'I';
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'l_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'i_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'l_date_lesser_limit' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                o_tstz              := l_date_lesser_limit;
            
            WHEN 'l_date_upper_limit' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                o_tstz              := pk_date_utils.add_days_to_tstz(l_date_lesser_limit, 1);
            
            WHEN 'g_prof_dep_status' THEN
                o_vc2 := 'S';
            WHEN 'dish_status' THEN
                o_vc2 := flg_status_a;
            WHEN 'g_active' THEN
                o_vc2 := g_active;
            WHEN 'g_analysis_exam_icon_grid_rank' THEN
                o_vc2 := g_analysis_exam_icon_grid_rank;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_pat_status_pend' THEN
                o_vc2 := g_pat_status_pend;
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            WHEN 'l_prof_cat' THEN
                l_prof_cat := pk_edis_list.get_prof_cat(l_prof);
                o_vc2      := l_prof_cat;
            WHEN 'l_dt_min' THEN
                o_tstz := CAST(trunc(to_date(l_str_date, 'yyyymmddHH24miss'), 'DD') AS TIMESTAMP);
            WHEN 'l_dt_max' THEN
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => CAST(trunc(to_date(l_str_date, 'yyyymmddHH24miss'),
                                                                               'DD') AS TIMESTAMP),
                                                     i_amount    => 86399,
                                                     i_unit      => 'second');
            WHEN 'disch_status_p' THEN
                o_vc2 := pk_alert_constant.g_epis_status_pendent;
            
            ELSE
                g_error := 'ERROR, variable not expected:' || i_name;
                dbms_output.put_line(g_error);
                pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => 'ALERT',
                                                  i_package  => 'PK_SR_GRID',
                                                  i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                                  o_error    => o_error);
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_GRID',
                                              i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                              o_error    => o_error);
    END;

    -- END EMR-437

    FUNCTION inactivate_surgery_admission
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_inst        IN institution.id_institution%TYPE,
        i_ids_exclude IN OUT table_number,
        o_has_error   OUT BOOLEAN,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cancel_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_CANCEL_REASON',
                                                                      i_prof    => i_prof);
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'SURGERY_INACTIVATE');
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_send_cancel_event sys_config.value%TYPE := nvl(pk_sysconfig.get_config(i_prof    => i_prof,
                                                                                 i_code_cf => 'SEND_CANCEL_EVENT'),
                                                         pk_alert_constant.g_yes);
    
        l_tbl_episode      table_number;
        l_tbl_waiting_list table_number;
        l_final_status     table_varchar;
        l_opinion_hist     opinion_hist.id_opinion_hist%TYPE;
    
        l_flg_show  VARCHAR2(10 CHAR);
        l_msg_title VARCHAR2(100 CHAR);
        l_msg_text  VARCHAR2(1000 CHAR);
        l_button    VARCHAR2(100 CHAR);
    
        l_error           t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_waiting_list) sent in i_ids_exclude       
        CURSOR c_sr_adm(ids_exclude IN table_number) IS
            SELECT *
              FROM (SELECT t.id_episode, t.id_waiting_list, cfg.field_04 final_status
                      FROM (SELECT e.id_episode,
                                   we.id_waiting_list,
                                   e.flg_status,
                                   coalesce(ss.dt_target_tstz, wl.dt_dpb, e.dt_begin_tstz) dt_begin_tstz
                              FROM episode e
                             INNER JOIN epis_info ei
                                ON ei.id_episode = e.id_episode
                             INNER JOIN schedule_sr ss
                                ON ss.id_episode = e.id_episode
                             INNER JOIN institution i
                                ON i.id_institution = e.id_institution
                             INNER JOIN sr_surgery_record srsr
                                ON ss.id_schedule_sr = srsr.id_schedule_sr
                              LEFT OUTER JOIN wtl_epis we
                                ON we.id_episode = e.id_episode
                              LEFT OUTER JOIN waiting_list wl
                                ON wl.id_waiting_list = we.id_waiting_list
                             WHERE e.id_epis_type = pk_alert_constant.g_epis_type_operating
                               AND e.flg_status NOT IN
                                   (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
                               AND e.id_institution = i_inst
                                  --Don't cancel the scheduled episodes 
                                 AND (ei.id_schedule IS NULL OR ei.id_schedule = -1)
                                 AND (wl.flg_status NOT IN
                                     (pk_wtl_prv_core.g_wtlist_status_partial,
                                       pk_wtl_prv_core.g_wtlist_status_schedule,
                                       pk_wtl_prv_core.g_wtlist_status_cancelled) OR wl.flg_status IS NULL)
                              UNION
                              SELECT epis.id_episode,
                                     wtl.id_waiting_list,
                                     epis.flg_status,
                                     coalesce(ssr.dt_target_tstz, wtl.dt_dpb, epis.dt_begin_tstz) dt_begin_tstz
                                FROM schedule_sr ssr
                               INNER JOIN waiting_list wtl
                                  ON wtl.id_waiting_list = ssr.id_waiting_list
                                LEFT JOIN wtl_epis we
                                  ON wtl.id_waiting_list = we.id_waiting_list
                                LEFT JOIN sr_pos_schedule pos
                                  ON pos.id_schedule_sr = ssr.id_schedule_sr
                               INNER JOIN institution i
                                  ON i.id_institution = ssr.id_institution
                               INNER JOIN sr_surgery_record srsr
                                  ON ssr.id_schedule_sr = srsr.id_schedule_sr
                               INNER JOIN episode epis
                                  ON ssr.id_episode = epis.id_episode
                               INNER JOIN epis_info ei
                                  ON ei.id_episode = epis.id_episode
                               WHERE epis.flg_status NOT IN
                                     (pk_alert_constant.g_epis_status_cancel, pk_alert_constant.g_epis_status_inactive)
                                 AND epis.id_institution = i_inst
                                    --Don't cancel the scheduled episodes 
                               AND (ei.id_schedule IS NULL OR ei.id_schedule = -1)
                               AND (wtl.flg_status NOT IN
                                   (pk_wtl_prv_core.g_wtlist_status_partial,
                                     pk_wtl_prv_core.g_wtlist_status_schedule,
                                     pk_wtl_prv_core.g_wtlist_status_cancelled) OR wtl.flg_status IS NULL)) t
                     INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = t.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = t.id_waiting_list
                     WHERE pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                            i_timestamp => (pk_date_utils.add_to_ltstz(i_timestamp => t.dt_begin_tstz,
                                                                                                       i_amount    => cfg.field_02,
                                                                                                       i_unit      => cfg.field_03))) <=
                           pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp)
                       AND id_waiting_list IS NOT NULL --This clause will not consider the Emergent requests
                       AND t_ids.column_value IS NULL) tt
             WHERE rownum <= l_max_rows;
    
    BEGIN
    
        o_has_error := FALSE;
    
        OPEN c_sr_adm(i_ids_exclude);
        FETCH c_sr_adm BULK COLLECT
            INTO l_tbl_episode, l_tbl_waiting_list, l_final_status;
        CLOSE c_sr_adm;
    
        IF l_tbl_episode.count > 0
        THEN
            FOR i IN l_tbl_episode.first .. l_tbl_episode.last
            LOOP
                IF l_final_status(i) = pk_alert_constant.g_cancelled
                THEN
                    IF l_tbl_waiting_list(i) IS NOT NULL
                    THEN
                        SAVEPOINT init_cancel;
                        IF NOT pk_wtl_api_ui.cancel_wtlist(i_lang             => i_lang,
                                                           i_prof             => i_prof,
                                                           i_wtl_id           => l_tbl_waiting_list(i),
                                                           i_id_cancel_reason => l_cancel_id,
                                                           i_notes_cancel     => NULL,
                                                           o_error            => l_error)
                        THEN
                            ROLLBACK TO init_cancel;
                        
                            --If, for the given id_waiting_list, an error is generated, o_has_error is set as TRUE,
                            --this way, the loop cicle may continue, but the system will know that at least one error has happened
                            o_has_error := TRUE;
                        
                            --A log for the id_waiting_list that raised the error must be generated 
                            pk_alert_exceptions.reset_error_state;
                            l_error.err_desc := 'ERROR CALLING PK_WTL_API_UI.CANCEL_WTLIST FOR RECORD ' ||
                                                l_tbl_waiting_list(i);
                            pk_alert_exceptions.process_error(i_lang,
                                                              SQLCODE,
                                                              SQLERRM,
                                                              l_error.err_desc,
                                                              'ALERT',
                                                              'PK_sR_GRID',
                                                              'INACTIVATESURGERY_ADMISSION',
                                                              o_error);
                        
                            --The array for the ids (id_waiting_list) that raised the error is incremented
                            l_tbl_error_ids.extend();
                            l_tbl_error_ids(l_tbl_error_ids.count) := l_tbl_waiting_list(i);
                        
                            CONTINUE;
                        END IF;
                    
                        /* The following code was commented because it was decided that Emergent surgeries withou a discharge should not be cancelled.
                        However, in the future, if it is decided that it should be assessed if those episodes have been initiated in
                        order to know if they are to be cancelled or inactivated, such logic should be implemented, the cursor should be changed
                        and the following code uncommented.
                        */
                        /*                    ELSE
                        IF NOT pk_sr_grid.set_pat_status(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_episode        => l_tbl_episode(i),
                                                         i_flg_status_new => pk_alert_constant.g_cancelled,
                                                         i_flg_status_old => NULL,
                                                         i_test           => pk_alert_constant.g_no,
                                                         i_cancel_reason  => l_cancel_id,
                                                         i_cancel_notes   => NULL,
                                                         o_flg_show       => l_flg_show,
                                                         o_msg_title      => l_msg_title,
                                                         o_msg_text       => l_msg_text,
                                                         o_button         => l_button,
                                                         o_error          => l_error)
                        THEN
                            CONTINUE;
                        END IF;*/
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_waiting_list has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_waiting_list) that could not
                    --be inactivated with the current call of the function
                    i_ids_exclude.extend();
                    i_ids_exclude(i_ids_exclude.count) := l_tbl_error_ids(i);
                END LOOP;
            
                --Since no inactivations were performed with the current call, a new call to this function is performed,
                --however, this time, the array i_ids_exclude will include a list of ids that cannot be fetched by the cursor
                --on the next call. The recursion will be perfomed until at least one record is inactivated, or the cursor
                --has no more records to fetch.
                --Note: i_ids_exclude is incremented and is an IN OUT parameter, therefore, 
                --it will hold all the ids that were not inactivated from ALL calls.            
                IF NOT pk_sr_grid.inactivate_surgery_admission(i_lang        => i_lang,
                                                               i_prof        => i_prof,
                                                               i_inst        => i_inst,
                                                               i_ids_exclude => i_ids_exclude,
                                                               o_has_error   => o_has_error,
                                                               o_error       => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              'ALERT',
                                              'PK_SR_GRID',
                                              'INACTIVATE_SURGERY_ADMISSION',
                                              l_error);
            RETURN FALSE;
    END inactivate_surgery_admission;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END;
/
