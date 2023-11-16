/*-- Last Change Revision: $Rev: 2026815 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:59 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_bird_eye_view AS
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas da urgência
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_emergency_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'OPEN CURSOR O_PATIENT';
        OPEN o_patient FOR
            SELECT epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   pat.id_patient,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   ei.id_professional prof_doctor,
                   ei.id_first_nurse_resp prof_nurse,
                   p.nick_name name_prof,
                   p.initials init_prof,
                   pn.nick_name name_nurse,
                   pn.initials init_nurse,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, NULL) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   -- Display number of responsible PHYSICIANS for the episode, 
                   -- if institution is using the multiple hand-off mechanism,
                   -- along with the name of the main responsible for the patient.
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_grid)
                      FROM dual) name_prof,
                   -- Only display the name of the responsible nurse, for all hand-off mechanisms
                   pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                   -- Team name
                   (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                               i_prof,
                                                               epis.id_department,
                                                               ei.id_software,
                                                               ei.id_professional,
                                                               ei.id_first_nurse_resp)
                      FROM dual) prof_team,
                   -- Display text in tooltips
                   -- 1) Responsible physician(s)
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_tooltip)
                      FROM dual) name_prof_tooltip,
                   -- 2) Responsible nurse
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_nurse,
                                                                 epis.id_episode,
                                                                 ei.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_tooltip)
                      FROM dual) name_nurse_tooltip,
                   -- 3) Responsible team 
                   (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_hand_off_type,
                                                         NULL)
                      FROM dual) prof_team_tooltip
              FROM episode       epis,
                   epis_info     ei,
                   patient       pat,
                   department    d,
                   software_dept sd,
                   room          ro,
                   professional  p,
                   professional  pn
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
                  -- José Brito 18/08/2008 Mostrar episódios do UBU no Bird's Eye View 
               AND epis.id_epis_type IN (2, 9) -- g_epis_type
                  --
               AND epis.id_patient = pat.id_patient
               AND p.id_professional(+) = ei.id_professional
               AND pn.id_professional(+) = ei.id_first_nurse_resp
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = epis.id_institution
               AND sd.id_dept = d.id_dept
                  --
               AND sd.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EMERGENCY_PAT',
                                                       o_error);
            pk_types.open_my_cursor(o_patient);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas de private practice
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         paulo teixeira
    * @version                        1.0 
    * @since                          2010/10/14
    **********************************************************************************************/
    FUNCTION get_private_practice_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'OPEN CURSOR O_PATIENT';
        OPEN o_patient FOR
            SELECT epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   pat.id_patient,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   ei.id_professional prof_doctor,
                   ei.id_first_nurse_resp prof_nurse,
                   p.nick_name name_prof,
                   p.initials init_prof,
                   pn.nick_name name_nurse,
                   pn.initials init_nurse,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, NULL) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   -- Display number of responsible PHYSICIANS for the episode, 
                   -- if institution is using the multiple hand-off mechanism,
                   -- along with the name of the main responsible for the patient.
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_grid)
                      FROM dual) name_prof,
                   -- Only display the name of the responsible nurse, for all hand-off mechanisms
                   pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                   -- Team name
                   (SELECT pk_prof_teams.get_prof_current_team(i_lang,
                                                               i_prof,
                                                               epis.id_department,
                                                               ei.id_software,
                                                               ei.id_professional,
                                                               ei.id_first_nurse_resp)
                      FROM dual) prof_team,
                   -- Display text in tooltips
                   -- 1) Responsible physician(s)
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_tooltip)
                      FROM dual) name_prof_tooltip,
                   -- 2) Responsible nurse
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_nurse,
                                                                 epis.id_episode,
                                                                 ei.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 pk_inp_grid.g_show_in_tooltip)
                      FROM dual) name_nurse_tooltip,
                   -- 3) Responsible team 
                   (SELECT pk_hand_off_core.get_team_str(i_lang,
                                                         i_prof,
                                                         epis.id_department,
                                                         ei.id_software,
                                                         ei.id_professional,
                                                         ei.id_first_nurse_resp,
                                                         l_hand_off_type,
                                                         NULL)
                      FROM dual) prof_team_tooltip
              FROM episode       epis,
                   epis_info     ei,
                   patient       pat,
                   department    d,
                   software_dept sd,
                   room          ro,
                   professional  p,
                   professional  pn
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
                  -- José Brito 18/08/2008 Mostrar episódios do UBU no Bird's Eye View 
               AND epis.id_epis_type IN (17, 11) -- g_epis_type
                  --
               AND epis.id_patient = pat.id_patient
               AND p.id_professional(+) = ei.id_professional
               AND pn.id_professional(+) = ei.id_first_nurse_resp
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = epis.id_institution
               AND sd.id_dept = d.id_dept
                  --
               AND sd.id_software = i_prof.software
               AND epis.id_institution = i_prof.institution
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
               AND NOT EXISTS (SELECT 1
                      FROM discharge dis
                     WHERE dis.id_episode = epis.id_episode
                       AND dis.flg_status NOT IN ('C', 'P'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_PRIVATE_PRACTICE_PAT',
                                                       o_error);
            pk_types.open_my_cursor(o_patient);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_private_practice_pat;
    --
    /**********************************************************************************************
    * Obter o departamento por defeito para a instituição ou o departmento onde está a especialidade preferencial do profissional
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_depart                 cursor with department default
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/03
    **********************************************************************************************/
    FUNCTION get_dep_floor_default
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_depart OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_department department.id_department%TYPE;
        --
        -- Departamento por defeito para a instituição / software / profissional
        CURSOR c_dep_prof IS
            SELECT dp.id_department
              FROM department dp, software_dept sd, dep_clin_serv dcs, prof_dep_clin_serv pdcs
             WHERE dp.id_institution = i_prof.institution
               AND pdcs.id_professional = i_prof.id
               AND pdcs.flg_default = g_yes
               AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
               AND dcs.id_department = dp.id_department
               AND sd.id_dept = dp.id_dept
               AND sd.id_software = i_prof.software;
    
        -- Departamento por defeito para a instituição / software
        CURSOR c_dep IS
            SELECT id_department
              FROM department dp, software_dept sd
             WHERE dp.id_institution = i_prof.institution
               AND dp.flg_available = g_flg_available
               AND sd.id_dept = dp.id_dept
               AND sd.id_software = i_prof.software
               AND dp.flg_default = g_yes
               AND nvl(dp.id_software, i_prof.software) = i_prof.software;
    BEGIN
        g_error := 'OPEN CURSOR C_DEP_PROF';
        OPEN c_dep_prof;
        FETCH c_dep_prof
            INTO l_department;
        CLOSE c_dep_prof;
        --    
        IF l_department IS NULL
        THEN
            g_error := 'OPEN CURSOR C_DEP';
            OPEN c_dep;
            FETCH c_dep
                INTO l_department;
            CLOSE c_dep;
        END IF;
        --
        g_error := 'OPEN CURSOR O_DEPART';
        OPEN o_depart FOR
            SELECT fi.id_floors_institution, fi.id_floors, fd.id_department, fd.id_floors_department
              FROM floors_department fd, floors_institution fi
             WHERE fd.id_floors_institution = fi.id_floors_institution
               AND fi.id_institution = i_prof.institution
               AND nvl(fd.flg_dep_default, g_flg_default) = g_flg_default
               AND fd.id_department = l_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_DEP_FLOOR_DEFAULT',
                                                       o_error);
        
            pk_types.open_my_cursor(o_depart);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Listagem de todos os departamentos da instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_department             cursor with all departments 
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_view_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_department OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN CURSOR O_DEPARTMENT';
        OPEN o_department FOR
            SELECT id_department, pk_translation.get_translation(i_lang, code_department) desc_department
              FROM department
             WHERE id_institution = i_prof.institution
               AND flg_available = g_flg_available
             ORDER BY desc_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_BEYES_VIEW_DEP',
                                                       o_error);
        
            pk_types.open_my_cursor(o_department);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Listagem de todos os andares da instituição 
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_floors                 cursor with all floors
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/19
    **********************************************************************************************/
    FUNCTION get_beyes_view_floors
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_floors OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR O_FLOORS';
        OPEN o_floors FOR
            SELECT f.id_floors,
                   pk_translation.get_translation(i_lang, f.code_floors) desc_floors,
                   fi.id_floors_institution,
                   f.image_plant,
                   b.id_building,
                   pk_translation.get_translation(i_lang, b.code_building) desc_building
              FROM floors f, floors_institution fi, building b
             WHERE fi.id_institution = i_prof.institution
               AND fi.id_floors = f.id_floors
               AND fi.flg_available = g_floors_avail
               AND b.id_building(+) = fi.id_building
               AND f.flg_available = g_floors_avail
             ORDER BY desc_floors;
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_BEYES_VIEW_FLOOR',
                                                       o_error);
        
            pk_types.open_my_cursor(o_floors);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listagem de os departamentos e salas de um andar
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_inst            floor institution id
    * @param i_department             department id
    * @param o_floors_dep             cursor with all floors department
    * @param o_rooms                  cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         João Eiras
    * @version                        1.0 
    * @since                          
    **********************************************************************************************/
    FUNCTION get_beyes_floors_dep_rooms
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_floors_inst IN floors_institution.id_floors_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_floors_dep  OUT pk_types.cursor_type,
        o_rooms       OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_def_department department.id_department%TYPE;
    BEGIN
    
        IF i_floors_inst IS NOT NULL
        THEN
            BEGIN
                g_error := 'GET DEFAULT DEPARTMENT (PROF)';
                SELECT dp.id_department
                  INTO l_def_department
                  FROM department dp, software_dept sd, dep_clin_serv dcs, prof_dep_clin_serv pdcs
                 WHERE dp.id_institution = i_prof.institution
                   AND pdcs.id_professional = i_prof.id
                   AND pdcs.flg_default = g_yes
                   AND pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                   AND dcs.id_department = dp.id_department
                   AND sd.id_dept = dp.id_dept
                   AND sd.id_software = i_prof.software
                   AND rownum < 2;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'GET DEFAULT DEPARTMENT';
                    SELECT id_department
                      INTO l_def_department
                      FROM floors_department
                     WHERE flg_dep_default = g_yes
                       AND id_floors_institution = i_floors_inst;
            END;
            --        
            g_error := 'OPEN O_FLOORS_DEP (1)';
            OPEN o_floors_dep FOR
                SELECT fd.id_floors_department,
                       fd.id_department,
                       pk_translation.get_translation(i_lang, d.code_department) desc_department,
                       decode(fd.id_department, l_def_department, g_yes, g_no) flg_available,
                       CAST(MULTISET (SELECT to_char(t.position_x)
                               FROM (SELECT position_x, id_floors_department
                                       FROM floors_dep_position
                                      ORDER BY rank) t
                              WHERE t.id_floors_department = fd.id_floors_department) AS table_number) coords_x,
                       CAST(MULTISET (SELECT to_char(t.position_y)
                               FROM (SELECT position_y, id_floors_department
                                       FROM floors_dep_position
                                      ORDER BY rank) t
                              WHERE t.id_floors_department = fd.id_floors_department) AS table_number) coords_y
                  FROM floors_department fd, department d
                 WHERE fd.id_floors_institution = i_floors_inst
                   AND d.id_department = fd.id_department
                   AND fd.flg_available = 'Y'
                   AND d.flg_available = g_flg_available
                   AND EXISTS (SELECT 0
                          FROM floors_dep_position fdp
                         WHERE fdp.id_floors_department = fd.id_floors_department);
        
            g_error := 'OPEN O_ROOMS';
            OPEN o_rooms FOR
                SELECT id_floors_department,
                       id_room,
                       nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, code_abbreviation)),
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, code_room))) desc_room,
                       ro.capacity,
                       pk_bird_eye_view.get_patient_count(i_prof, id_room) total_pat,
                       CAST(MULTISET (SELECT to_char(t.position_x)
                               FROM (SELECT position_x, id_room
                                       FROM room_dep_position rdp
                                      ORDER BY rank) t
                              WHERE t.id_room = ro.id_room) AS table_number) coords_x,
                       CAST(MULTISET (SELECT to_char(t.position_y)
                               FROM (SELECT position_y, id_room
                                       FROM room_dep_position rdp
                                      ORDER BY rank) t
                              WHERE t.id_room = ro.id_room) AS table_number) coords_y
                  FROM (SELECT ro2.*
                          FROM floors_department fd, department d, room ro2
                         WHERE fd.id_floors_institution = i_floors_inst
                           AND fd.flg_available = 'Y'
                           AND d.id_department = fd.id_department
                           AND d.flg_available = g_flg_available
                           AND d.id_institution = i_prof.institution
                           AND EXISTS (SELECT 0
                                  FROM floors_dep_position fdp
                                 WHERE fdp.id_floors_department = fd.id_floors_department)
                           AND ro2.id_floors_department = fd.id_floors_department
                           AND ro2.id_department = fd.id_department
                           AND ro2.flg_available = g_flg_available) ro
                 WHERE EXISTS (SELECT 0
                          FROM room_dep_position rdp
                         WHERE rdp.id_room = ro.id_room);
        
        ELSIF i_department IS NOT NULL
        THEN
            g_error := 'NOT IMPLEMENTED';
            RAISE g_exception;
        ELSE
            g_error := 'INVALID ARGS';
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_BEYES_FLOORS_DEP_ROOMS',
                                                       o_error);
            pk_types.open_my_cursor(o_floors_dep);
            pk_types.open_my_cursor(o_rooms);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_beyes_floors_dep_rooms;
    --
    /**********************************************************************************************
    * Listagem de todas as salas de um dado departamento para a instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id   
    * @param o_val_x                  cursor with all value x
    * @param o_val_y                  cursor with all value y   
    * @param o_room                   cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_dep_room
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        o_val_x      OUT table_varchar,
        o_val_y      OUT table_varchar,
        o_room       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_array_valx VARCHAR2(4000);
        l_array_valy VARCHAR2(4000);
        i            NUMBER := 0;
        cont         NUMBER;
        l_sep        VARCHAR2(1) := ';';
        l_value      VARCHAR2(20);
        l_val_xy     VARCHAR2(9) := 'FALSE';
        l_table_dpt  table_varchar;
        l_sys_config sys_config.id_sys_config%TYPE := 'BIRDS_EYE_VIEW_SOFT';
    
        CURSOR c_room IS
            SELECT ro.id_room
              FROM room ro, department d
             WHERE ro.id_department = d.id_department
               AND d.id_institution = i_prof.institution
               AND ro.id_floors_department = i_floors_dep
               AND ro.flg_available = g_flg_available
             ORDER BY 1;
    
        CURSOR c_valxy(l_room IN room.id_room%TYPE) IS
            SELECT position_x, position_y
              FROM room_dep_position
             WHERE id_room = l_room
             ORDER BY rank;
    BEGIN
        g_error := 'GET CONFIGURATIONS';
        -- Departamento por defeitopara a instituição e software
        g_dep_default := pk_sysconfig.get_config('BIRD_EYE_VIEW_DEP', i_prof);
    
        g_error := 'INICIALIZAÇÃO DOS ARRAYS';
        o_val_x := table_varchar(); -- inicialização do vector
        o_val_y := table_varchar(); -- inicialização do vector
    
        SELECT pk_sysconfig.get_config(i_code_cf => l_sys_config, i_prof => i_prof)
          BULK COLLECT
          INTO l_table_dpt
          FROM dual;
    
        g_error := 'OPEN C_ROOM';
        FOR x_room IN c_room
        LOOP
            l_array_valx := NULL;
            l_array_valy := NULL;
            l_value      := 'FALSE';
            cont         := 0;
        
            FOR x_valxy IN c_valxy(x_room.id_room)
            LOOP
                l_value := 'TRUE'; -- Tem valores
                IF nvl(cont, 0) = 0
                THEN
                    -- 1º contagem de salas, então 1ª posião o ID da SALA
                    IF l_array_valx IS NULL
                    THEN
                        l_array_valx := x_room.id_room;
                        l_array_valy := x_room.id_room;
                    END IF;
                END IF;
            
                l_array_valx := l_array_valx || l_sep || x_valxy.position_x;
                l_array_valy := l_array_valy || l_sep || x_valxy.position_y;
                cont         := cont + 1;
            END LOOP;
        
            IF l_value = 'FALSE'
               AND nvl(cont, 0) > 0
            THEN
                l_array_valx := l_array_valx || l_sep || '';
                l_array_valy := l_array_valy || l_sep || '';
            END IF;
        
            IF nvl(cont, 0) > 0
            THEN
                i := i + 1;
                o_val_x.extend; -- o array O_DESC_VITAL_SIGN tem mais uma linha
                o_val_y.extend;
            END IF;
        
            l_val_xy := 'TRUE';
        
            IF l_val_xy = 'TRUE'
               AND nvl(cont, 0) > 0
            THEN
                -- nova linha para ambos ARRAY
                o_val_x(i) := l_array_valx || l_sep;
                o_val_y(i) := l_array_valy || l_sep;
                l_val_xy := 'FALSE';
            END IF;
        END LOOP;
    
        g_error := 'OPEN CURSOR O_ROOM';
        OPEN o_room FOR
            SELECT id_floors_department,
                   id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, code_room))) desc_room,
                   ro.capacity,
                   pk_bird_eye_view.get_patient_count(i_prof, id_room) total_pat,
                   decode(sd.id_software, i_prof.software, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_room_consult
              FROM room ro, department d, software_dept sd
             WHERE ro.id_floors_department = i_floors_dep
               AND ro.flg_available = g_flg_available
               AND ro.id_department = d.id_department
               AND d.id_institution = i_prof.institution
               AND d.id_dept = sd.id_dept
               AND sd.id_software IN (pk_alert_constant.g_soft_outpatient,
                                      pk_alert_constant.g_soft_oris,
                                      pk_alert_constant.g_soft_primary_care,
                                      pk_alert_constant.g_soft_edis,
                                      pk_alert_constant.g_soft_inpatient,
                                      pk_alert_constant.g_soft_private_practice,
                                      pk_alert_constant.g_soft_ubu)
             ORDER BY id_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_types.open_my_cursor(o_room);
            o_val_x := table_varchar();
            o_val_y := table_varchar();
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BEYES_DEP_ROOM',
                                              o_error);
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Listagem dos departamentos de um andar
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors                 floor id
    * @param i_department             department id
    * @param o_val_x                  cursor with all value x
    * @param o_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION get_beyes_floors_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors     IN floors_institution.id_floors_institution%TYPE,
        i_department IN department.id_department%TYPE,
        o_val_x      OUT table_varchar,
        o_val_y      OUT table_varchar,
        o_floors_dep OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_array_valx VARCHAR2(4000);
        l_array_valy VARCHAR2(4000);
        i            NUMBER := 0;
        cont         NUMBER;
        l_sep        VARCHAR2(1) := ';';
        l_value      VARCHAR2(20);
        l_val_xy     VARCHAR2(9) := 'FALSE';
        l_table_dpt  table_varchar;
        l_sys_config sys_config.id_sys_config%TYPE;
    
        CURSOR c_dep IS
            SELECT fd.id_floors_department
              FROM floors_department fd, department d
             WHERE fd.id_floors_institution = i_floors
               AND d.id_department = fd.id_department
               AND fd.flg_available = 'Y'
               AND d.flg_available = g_flg_available
             ORDER BY 1;
    
        CURSOR c_valxy(l_floors_department IN floors_department.id_floors_department%TYPE) IS
            SELECT position_x, position_y
              FROM floors_dep_position
             WHERE id_floors_department = l_floors_department
             ORDER BY rank;
    BEGIN
    
        IF i_floors IS NOT NULL
        THEN
        
            l_sys_config := 'BIRDS_EYE_VIEW_SOFT';
        
            g_error := 'INICIALIZAÇÃO DOS ARRAYS';
            o_val_x := table_varchar(); -- inicialização do vector
            o_val_y := table_varchar(); -- inicialização do vector
        
            g_error := 'GET DPT.FLG_TYPE USING BIRDS EYE VIEW';
            SELECT sc.value
              BULK COLLECT
              INTO l_table_dpt
              FROM sys_config sc
             WHERE sc.id_sys_config = l_sys_config;
        
            g_error := 'OPEN C_DEP';
            FOR x_dep IN c_dep
            LOOP
                l_array_valx := NULL;
                l_array_valy := NULL;
                l_value      := 'FALSE';
                cont         := 0;
            
                FOR x_valxy IN c_valxy(x_dep.id_floors_department)
                LOOP
                    l_value := 'TRUE'; -- Tem valores
                    --
                    IF nvl(cont, 0) = 0
                    THEN
                        -- 1º contagem de salas, então 1ª posião o ID da SALA
                        IF l_array_valx IS NULL
                        THEN
                            l_array_valx := x_dep.id_floors_department;
                            l_array_valy := x_dep.id_floors_department;
                        END IF;
                    END IF;
                
                    l_array_valx := l_array_valx || l_sep || x_valxy.position_x;
                    l_array_valy := l_array_valy || l_sep || x_valxy.position_y;
                    cont         := cont + 1;
                END LOOP;
            
                IF l_value = 'FALSE'
                   AND nvl(cont, 0) > 0
                THEN
                    l_array_valx := l_array_valx || l_sep || '';
                    l_array_valy := l_array_valy || l_sep || '';
                END IF;
            
                IF nvl(cont, 0) > 0
                THEN
                    i := i + 1;
                    o_val_x.extend; -- o array O_DESC_VITAL_SIGN tem mais uma linha
                    o_val_y.extend;
                END IF;
            
                l_val_xy := 'TRUE';
            
                IF l_val_xy = 'TRUE'
                   AND nvl(cont, 0) > 0
                THEN
                    -- nova linha para ambos ARRAY
                    o_val_x(i) := l_array_valx || l_sep;
                    o_val_y(i) := l_array_valy || l_sep;
                    l_val_xy := 'FALSE';
                END IF;
            END LOOP;
        
            g_error := 'OPEN CURSOR O_FLOORS_DEP (F)';
            OPEN o_floors_dep FOR
                SELECT fd.id_floors_department,
                       fd.id_department,
                       pk_translation.get_translation(i_lang, d.code_department) desc_department,
                       decode(d.flg_default, g_yes, g_yes, g_no) flg_default,
                       decode(check_dpt_type(d.flg_type, l_table_dpt), 1, g_yes, 0, g_no) flg_available,
                       de.id_dept,
                       pk_translation.get_translation(i_lang, de.code_dept) dec_dept
                  FROM floors_department fd, department d, dept de
                 WHERE fd.id_floors_institution = i_floors
                   AND d.id_department = fd.id_department
                   AND fd.flg_available = g_floors_avail
                   AND d.flg_available = g_flg_available
                   AND d.id_dept = de.id_dept
                 ORDER BY 1;
        ELSE
            g_error := 'OPEN CURSOR O_FLOORS_DEP (D)';
            OPEN o_floors_dep FOR
                SELECT fd.id_floors_department,
                       fd.id_floors_institution,
                       pk_translation.get_translation(i_lang, f.code_floors) desc_floors,
                       decode(d.flg_default, g_yes, g_yes, g_no) flg_default,
                       decode(check_dpt_type(d.flg_type, l_table_dpt), 1, g_yes, 0, g_no) flg_available,
                       de.id_dept,
                       pk_translation.get_translation(i_lang, de.code_dept) dec_dept
                  FROM floors_department fd, floors f, floors_institution fi, department d, dept de
                 WHERE fd.id_department = i_department
                   AND fi.id_floors_institution = fd.id_floors_institution
                   AND fi.flg_available = g_floors_avail
                   AND fd.id_department = d.id_department
                   AND d.id_dept = de.id_dept
                 ORDER BY desc_floors;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            o_val_x := table_varchar();
            o_val_y := table_varchar();
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BEYES_FLOOR_DEP',
                                              o_error);
            pk_types.open_my_cursor(o_floors_dep);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Check if the given department has BIRDS EYE VIEW SUPPORT
    *   
    * @param i_flg_type_dpt           department type
    * @param i_type_list              list of supported departments
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2007/12/26
    **********************************************************************************************/
    FUNCTION check_dpt_type
    (
        i_flg_type_dpt IN department.flg_type%TYPE,
        i_type_list    IN table_varchar
    ) RETURN NUMBER IS
    
        l_ret NUMBER;
    
    BEGIN
    
        l_ret := 0;
    
        SELECT 1
          INTO l_ret
          FROM TABLE(i_type_list) a
         WHERE instr(i_flg_type_dpt, a.column_value) > 0;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            RETURN l_ret;
    END check_dpt_type;
    --
    /**********************************************************************************************
    * Registar as posições dos andares para cada departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id
    * @param i_val_x                  cursor with all value x
    * @param i_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION set_beyes_floors_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        i_val_x      IN table_number,
        i_val_y      IN table_number,
        o_floors_dep OUT floors_department.id_floors_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char VARCHAR2(1);
        l_next floors_dep_position.id_floors_dep_position%TYPE;
    
        CURSOR c_floor_dep IS
            SELECT 'X'
              FROM floors_department
             WHERE id_floors_department = i_floors_dep
               AND flg_available = g_floors_avail;
    BEGIN
    
        -- Verificar se o andar/departamento está activo
        g_error := 'GET CURSOR C_FLOOR_DEP';
        OPEN c_floor_dep;
        FETCH c_floor_dep
            INTO l_char;
        g_found := c_floor_dep%FOUND;
        CLOSE c_floor_dep;
    
        IF g_found
        THEN
            ------- ARRAY DOS VALORES X --------
            FOR i IN 1 .. i_val_x.count
            LOOP
                g_error := 'GET SEQ_FLOORS_DEP_POSITION.NEXTVAL';
                SELECT seq_floors_dep_position.nextval
                  INTO l_next
                  FROM dual;
                --
                g_error := ' INSERIR FLOORS_DEP_POSITION ';
                INSERT INTO floors_dep_position
                    (id_floors_dep_position, id_floors_department, position_x, position_y, rank)
                VALUES
                    (l_next, i_floors_dep, i_val_x(i), i_val_y(i), i);
            END LOOP;
        END IF;
    
        o_floors_dep := i_floors_dep;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BEYES_FLOORS_DEP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Registar as posições dos andares para cada departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             floor department id
    * @param i_room                   room id       
    * @param i_val_x                  cursor with all value x
    * @param i_val_y                  cursor with all value y   
    * @param o_floors_dep             cursor with all floors department
    * @param o_room                   cursor with all rooms   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/18
    **********************************************************************************************/
    FUNCTION set_beyes_room_dep
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_department.id_floors_department%TYPE,
        i_room       IN room.id_room%TYPE,
        i_val_x      IN table_number,
        i_val_y      IN table_number,
        o_floors_dep OUT floors_department.id_floors_department%TYPE,
        o_room       OUT room.id_room%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char VARCHAR2(1);
        l_next room_dep_position.id_room_dep_position%TYPE;
    
        CURSOR c_floor_dep IS
            SELECT 'X'
              FROM floors_department
             WHERE id_floors_department = i_floors_dep
               AND flg_available = g_floors_avail;
    BEGIN
    
        -- Verificar se o andar/departamento está activo
        g_error := 'GET CURSOR C_FLOOR_DEP';
        OPEN c_floor_dep;
        FETCH c_floor_dep
            INTO l_char;
        g_found := c_floor_dep%FOUND;
        CLOSE c_floor_dep;
        --
        IF g_found
        THEN
            ------- ARRAY DOS VALORES X --------
            -- Identificar qual a última posição do array. Será este a posição
            FOR i IN 1 .. i_val_x.count
            LOOP
                g_error := 'GET SEQ_ROOM_DEP_POSITION.NEXTVAL';
                SELECT seq_room_dep_position.nextval
                  INTO l_next
                  FROM dual;
                --
                /*X:=I_VAL_X(I);
                Y:=I_VAL_Y(I);
                L_VAL_X:=To_Number(REPLACE(X,',','.'));
                L_VAL_Y:=To_Number(REPLACE(Y,',','.'));*/
                --
                g_error := ' INSERIR ROOM_DEP_POSITION ';
                INSERT INTO room_dep_position
                    (id_room_dep_position, position_x, position_y, id_room, rank)
                VALUES
                    (l_next,
                     i_val_x(i), --L_VAL_X,--LTrim(RTrim(I_VAL_X(I))),
                     i_val_y(i), --L_VAL_Y,--LTrim(RTrim(I_VAL_Y(I))),
                     i_room,
                     i);
            END LOOP;
        END IF;
    
        COMMIT;
    
        o_floors_dep := i_floors_dep;
        o_room       := i_room;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_BEYES_ROOM_DEP',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Obter o nome da instituição
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_institution            institution id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/09/21
    **********************************************************************************************/
    FUNCTION get_beyes_institution
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_institution OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN CURSOR O_INSTITUTION';
        OPEN o_institution FOR
            SELECT id_institution, pk_translation.get_translation(i_lang, code_institution) desc_institution
              FROM institution
             WHERE id_institution = i_prof.institution;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_BEYES_INSTITUTION',
                                                       o_error);
            pk_types.open_my_cursor(o_institution);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Contagem de pacientes por sala
    *   
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/10/04
    **********************************************************************************************/
    FUNCTION get_patient_count
    (
        i_prof IN profissional,
        i_room IN room.id_room%TYPE
    ) RETURN NUMBER IS
        l_cont_pat NUMBER(5) := 0;
    BEGIN
        g_software_inp := pk_sysconfig.get_config('SOFTWARE_ID_INP', i_prof);
        --
        IF i_prof.software = g_software_inp
        THEN
            g_epis_type := pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT', i_prof);
            --
            g_error := 'GET C_PAT_CONT (1)';
            SELECT COUNT(DISTINCT epis.id_episode)
              INTO l_cont_pat
              FROM episode epis, patient pat, epis_info ei, bed, bmng_allocation_bed bab
             WHERE epis.flg_status = g_epis_active
               AND epis.id_epis_type = g_epis_type
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND ei.id_bed = bed.id_bed
               AND bed.id_room = i_room
               AND epis.id_patient = pat.id_patient
               AND epis.id_episode = ei.id_episode
               AND bed.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_o
               AND bab.id_episode = ei.id_episode
               AND bab.flg_outdated = pk_alert_constant.g_no;
        
        ELSE
            g_error := 'GET C_PAT_CONT (2)';
            SELECT COUNT(DISTINCT t.id_episode)
              INTO l_cont_pat
              FROM (SELECT epis.id_episode, epis.id_epis_type, epis.id_institution
                      FROM episode epis, epis_info ei
                     WHERE ei.id_room = i_room
                       AND epis.id_episode = ei.id_episode
                       AND epis.flg_status = g_epis_active
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                       AND epis.flg_ehr = g_flg_ehr_normal
                       AND nvl(ei.id_software, 0) = i_prof.software
                       AND epis.id_institution = i_prof.institution
                       AND rownum > 0) t
             WHERE pk_episode.get_soft_by_epis_type(t.id_epis_type, t.id_institution) = i_prof.software;
        END IF;
    
        RETURN l_cont_pat;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END;

    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do bloco operatório
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param o_patient                cursor with all patient
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Batista
    * @version                        1.0 
    * @since                          2006/10/31
    **********************************************************************************************/
    FUNCTION get_sr_pat
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_patient OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_hand_off_type sys_config.value%TYPE;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error := 'OPEN CURSOR O_PATIENT';
        OPEN o_patient FOR
            SELECT 1 flg_order,
                   1 flg_order2,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   pat.id_patient id_prof,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_prof,
                   'PatientSRIcon' name_icon,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epis.id_episode, NULL) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   'Y' flg_patient,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon
              FROM episode epis, epis_info ei, patient pat, department d, software_dept sd, room ro, schedule_sr s
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND ei.id_software = i_prof.software
               AND epis.id_patient = pat.id_patient
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = i_prof.institution
               AND d.id_dept = sd.id_dept
               AND epis.id_institution = i_prof.institution
               AND sd.id_software = i_prof.software
               AND s.id_episode = epis.id_episode
               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz, NULL) BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) AND
                   pk_date_utils.add_days_to_tstz(g_sysdate_tstz, 0.99999)
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
            --profissionais agendados (médicos)
            UNION ALL
            SELECT 2 flg_order,
                   cs.rank flg_order2,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   p.id_professional id_prof,
                   p.nick_name name_prof,
                   'DoctorIcon' icon_name,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   'N' flg_patient,
                   '' pat_ndo,
                   '' pat_nd_icon
              FROM episode          epis,
                   epis_info        ei,
                   department       d,
                   software_dept    sd,
                   room             ro,
                   sr_prof_team_det td,
                   professional     p,
                   category_sub     cs,
                   category         c,
                   schedule_sr      s
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.id_epis_type = g_sr_epis_type
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = i_prof.institution
               AND d.id_dept = sd.id_dept
               AND epis.id_institution = i_prof.institution
               AND sd.id_software = i_prof.software
               AND td.id_episode = epis.id_episode
               AND td.flg_status = g_status_active
               AND p.id_professional = td.id_professional
               AND cs.id_category_sub = td.id_category_sub
               AND c.id_category = cs.id_category
               AND c.flg_type = 'D' --Médico
               AND s.id_episode = epis.id_episode
               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz, NULL) BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) AND
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL),
                                                  0.99999)
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
            UNION ALL
            --ENFERMEIROS
            SELECT 3 flg_order,
                   cs.rank flg_order2,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   p.id_professional id_prof,
                   p.nick_name name_prof,
                   'NurseIcon' name_icon,
                   pk_profphoto.get_prof_photo(profissional(p.id_professional, i_prof.institution, i_prof.software)) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons,
                   'N' flg_patient,
                   '' pat_ndo,
                   '' pat_nd_icon
              FROM episode       epis,
                   epis_info     ei,
                   department    d,
                   software_dept sd,
                   room          ro,
                   prof_room     pr,
                   professional  p,
                   category_sub  cs,
                   category      c,
                   sr_prof_shift sh,
                   schedule_sr   s
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.id_epis_type = g_sr_epis_type
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = i_prof.institution
               AND d.id_dept = sd.id_dept
               AND epis.id_institution = i_prof.institution
               AND sd.id_software = i_prof.software
               AND pr.id_room = ro.id_room
               AND p.id_professional = pr.id_professional
               AND cs.id_category_sub = pr.id_category_sub
               AND c.id_category = cs.id_category
               AND c.flg_type = 'N' --Enfermeiro
               AND sh.id_sr_prof_shift = pr.id_sr_prof_shift
               AND s.id_episode = epis.id_episode
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz, NULL) BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) AND
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL),
                                                  0.99999)
                  --AND SYSDATE >= to_date(to_char(trunc(SYSDATE), 'yyyymmdd') || ' ' || sh.hour_start, 'yyyymmdd hh24:mi')
               AND g_sysdate_tstz >
                   pk_date_utils.get_string_tstz(i_lang,
                                                 i_prof,
                                                 to_char(pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) ||
                                                         REPLACE(sh.hour_start, ':', '') || '00'),
                                                 NULL)
               AND ((g_sysdate_tstz <
                   pk_date_utils.get_string_tstz(i_lang,
                                                   i_prof,
                                                   to_char(pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) ||
                                                           REPLACE(sh.hour_end, ':', '') || '00'),
                                                   NULL) AND sh.hour_start <= sh.hour_end) OR
                   (g_sysdate_tstz < pk_date_utils.get_string_tstz(i_lang,
                                                                    i_prof,
                                                                    to_char(pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                                            g_sysdate_tstz,
                                                                                                                                            NULL),
                                                                                                           1) ||
                                                                            REPLACE(sh.hour_end, ':', '') || '00'),
                                                                    NULL) AND sh.hour_start > sh.hour_end))
               AND sh.hour_start IS NOT NULL
            -- Materiais requisitados (Apenas os que têm FLG_SCHEDULE=Y)
            UNION ALL
            SELECT 4 flg_order,
                   1 flg_order2,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   ro.id_room,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   srr.id_sr_equip id_material,
                   pk_translation.get_translation(1, se.code_equip) desc_material,
                   'MaterialReqIcon' name_icon,
                   NULL photo,
                   NULL resp_icons,
                   'N' flg_patient,
                   '' pat_ndo,
                   '' pat_nd_icon
              FROM episode       epis,
                   epis_info     ei,
                   room          ro,
                   department    d,
                   software_dept sd,
                   sr_equip      se,
                   sr_reserv_req srr,
                   schedule_sr   s
             WHERE epis.id_episode = ei.id_episode
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.id_epis_type = g_sr_epis_type
               AND ro.id_room = ei.id_room
               AND d.id_department = ro.id_department
               AND d.id_institution = i_prof.institution
               AND d.id_dept = sd.id_dept
               AND epis.id_institution = i_prof.institution
               AND sd.id_software = i_prof.software
               AND srr.id_episode = ei.id_episode
               AND srr.id_sr_equip = se.id_sr_equip
               AND se.flg_schedule_yn = g_flg_schedule
               AND srr.flg_status <> g_status_cancel
               AND s.id_episode = epis.id_episode
               AND pk_date_utils.trunc_insttimezone(i_prof, s.dt_target_tstz, NULL) BETWEEN
                   pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL) AND
                   pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz, NULL),
                                                  0.99999)
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
             ORDER BY 1, 2;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_EMERGENCY_PAT',
                                                       o_error);
            pk_types.open_my_cursor(o_patient);
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do bloco operatório
    *   
    * @param i_lang                   the id language
    * @param i_id_room                room id                   
    * @param i_prof                   professional, software and institution ids
    * @param o_surgery                cursor with surgery rooms
    * @param o_patient                cursor with all patient
    * @param o_professionals          cursor with all professionals   
    * @param o_materials              cursor with all materials of room   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rui Campos
    * @version                        1.0 
    * @since                          2006/11/08
    **********************************************************************************************/
    FUNCTION get_sr_room_info
    (
        i_lang          IN language.id_language%TYPE,
        i_id_room       IN room.id_room%TYPE,
        i_prof          IN profissional,
        o_surgery       OUT pk_types.cursor_type,
        o_patient       OUT pk_types.cursor_type,
        o_professionals OUT pk_types.cursor_type,
        o_materials     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_SURGERY';
        OPEN o_surgery FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T341') title,
                   epis.id_episode,
                   epis.id_patient,
                   si.id_intervention,
                   pk_translation.get_translation(1, code_intervention) desc_surg
              FROM episode epis, epis_info ei, sr_epis_interv sei, intervention si
             WHERE epis.id_episode = ei.id_episode
               AND ei.id_room = i_id_room
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.flg_status = g_epis_active
               AND ei.id_software = i_prof.software
               AND epis.id_epis_type = g_sr_epis_type
               AND epis.id_institution = i_prof.institution
               AND sei.id_episode = ei.id_episode
               AND si.id_intervention = sei.id_sr_intervention
               AND sei.flg_status <> g_status_cancel
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
             ORDER BY sei.dt_req_tstz;
    
        g_error := 'OPEN O_PATIENT';
        OPEN o_patient FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T090') title,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   pat.id_patient id_patient,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon
              FROM episode epis, epis_info ei, patient pat, epis_type_soft_inst etsi
             WHERE epis.id_episode = ei.id_episode
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND ei.id_room = i_id_room
               AND epis.id_epis_type = etsi.id_epis_type
               AND epis.flg_status = g_epis_active
               AND epis.id_epis_type = g_sr_epis_type
               AND epis.id_patient = pat.id_patient
               AND epis.id_institution = i_prof.institution
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software;
    
        g_error := 'OPEN CURSOR O_PROFESSIONALS';
        OPEN o_professionals FOR
            SELECT 1 flg_order,
                   cs.rank flg_order2,
                   pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T340') title,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   p.id_professional id_prof,
                   p.nick_name name_prof
              FROM episode epis, epis_info ei, sr_prof_team_det td, professional p, category_sub cs, category c
             WHERE ei.id_room = i_id_room
               AND epis.id_episode = ei.id_episode
               AND epis.id_epis_type = epis.id_epis_type
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
                  --AND et.id_software = i_prof.software
               AND epis.id_epis_type = g_sr_epis_type
               AND td.id_episode = epis.id_episode
               AND td.flg_status = g_status_active
               AND p.id_professional = td.id_professional
               AND cs.id_category_sub = td.id_category_sub
               AND c.id_category = cs.id_category
               AND c.flg_type = 'D' --Médico
               AND epis.id_institution = i_prof.institution
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
            UNION ALL
            --enfermeiros
            SELECT 3 flg_order,
                   cs.rank flg_order2,
                   pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T340') title,
                   epis.id_episode,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   p.id_professional id_prof,
                   p.nick_name name_prof
              FROM episode       epis,
                   epis_info     ei,
                   prof_room     pr,
                   professional  p,
                   category_sub  cs,
                   category      c,
                   sr_prof_shift sh
             WHERE ei.id_room = i_id_room
               AND epis.id_episode = ei.id_episode
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.flg_status = g_epis_active
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = i_prof.software
               AND epis.id_epis_type = g_sr_epis_type
               AND epis.id_institution = i_prof.institution
               AND pr.id_room = ei.id_room
               AND pr.flg_pref = g_flg_pref
               AND p.id_professional = pr.id_professional
               AND cs.id_category_sub = pr.id_category_sub
               AND c.id_category = cs.id_category
               AND c.flg_type = 'N' --Enfermeiro
               AND sh.id_sr_prof_shift = pr.id_sr_prof_shift
                  --               AND SYSDATE >= to_date(to_char(trunc(SYSDATE), 'yyyymmdd') || ' ' || sh.hour_start, 'yyyymmdd hh24:mi')
                  --               AND ((SYSDATE < to_date(to_char(trunc(SYSDATE), 'yyyymmdd') || ' ' || sh.hour_end, 'yyyymmdd hh24:mi') AND
                  --                   sh.hour_start <= sh.hour_end) OR
                  --                   (SYSDATE <
                  --                   to_date(to_char(trunc(SYSDATE + 1), 'yyyymmdd') || ' ' || sh.hour_end, 'yyyymmdd hh24:mi') AND
                  --                   sh.hour_start > sh.hour_end))
               AND current_timestamp > pk_date_utils.get_string_tstz(i_lang,
                                                                     i_prof,
                                                                     to_char(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                              current_timestamp,
                                                                                                              NULL) ||
                                                                             REPLACE(sh.hour_start, ':', '') || '00'),
                                                                     NULL)
               AND ((current_timestamp < pk_date_utils.get_string_tstz(i_lang,
                                                                       i_prof,
                                                                       to_char(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                current_timestamp,
                                                                                                                NULL) ||
                                                                               REPLACE(sh.hour_end, ':', '') || '00'),
                                                                       NULL) AND sh.hour_start <= sh.hour_end) OR
                   (current_timestamp < pk_date_utils.get_string_tstz(i_lang,
                                                                       i_prof,
                                                                       to_char(pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                                               current_timestamp,
                                                                                                                                               NULL),
                                                                                                              1) ||
                                                                               REPLACE(sh.hour_end, ':', '') || '00'),
                                                                       NULL) AND sh.hour_start > sh.hour_end))
               AND sh.hour_start IS NOT NULL
             ORDER BY 1, 2;
    
        g_error := 'OPEN O_MATERIALS';
        OPEN o_materials FOR
            SELECT pk_message.get_message(i_lang, i_prof, 'SR_LABEL_T342') title,
                   epis.id_episode,
                   epis.id_patient,
                   srr.id_sr_equip,
                   pk_translation.get_translation(1, se.code_equip) desc_material,
                   srr.qty_req
              FROM episode epis, epis_info ei, sr_equip se, sr_reserv_req srr
             WHERE epis.id_episode = ei.id_episode
               AND ei.id_room = i_id_room
               AND epis.flg_status = g_epis_active
                  -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR 
               AND epis.flg_ehr = g_flg_ehr_normal
               AND epis.id_epis_type = g_sr_epis_type
               AND epis.id_institution = i_prof.institution
               AND srr.id_episode = ei.id_episode
               AND srr.id_sr_equip = se.id_sr_equip
               AND se.flg_schedule_yn = g_flg_schedule
               AND srr.flg_status <> g_status_cancel
             ORDER BY srr.dt_req_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_SR_ROOM_INFO',
                                                       o_error);
        
            pk_types.open_my_cursor(o_surgery);
            pk_types.open_my_cursor(o_patient);
            pk_types.open_my_cursor(o_professionals);
            pk_types.open_my_cursor(o_materials);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;
    --
    /**********************************************************************************************
    * Eliminar as posições para uma determinada sala
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_room                   room id   
    * @param o_room                   cursor with all rooms
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2006/11/08
    **********************************************************************************************/
    FUNCTION delete_room_dep_pos
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_room  IN room.id_room%TYPE,
        o_room  OUT room.id_room%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        --
        CURSOR c_room_dep IS
            SELECT 'X'
              FROM room_dep_position
             WHERE id_room = i_room;
    BEGIN
        -- Verificar se a sala existe
        g_error := 'GET CURSOR C_ROOM_DEP';
        OPEN c_room_dep;
        FETCH c_room_dep
            INTO l_char;
        g_found := c_room_dep%FOUND;
        CLOSE c_room_dep;
        --
        IF g_found
        THEN
            DELETE room_dep_position
             WHERE id_room = i_room;
        END IF;
    
        COMMIT;
    
        o_room := i_room;
    
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
                                              'DELETE_FLOORS_DEP_POS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Listagem de todos os pacientes alocados ás salas do internamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floor                  floor id    
    * @param o_pat                    cursor with all patients
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         
    * @version                        1.0 
    * @since                          
    **********************************************************************************************/
    FUNCTION get_inp_pat
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_floor IN NUMBER,
        o_pat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type     NUMBER;
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        --
        l_epis_type := 5;
        --            
        OPEN o_pat FOR
        
            SELECT p.id_patient id_patient,
                   p.gender gender,
                   pk_patient.get_pat_age(i_lang, p.dt_birth, p.dt_deceased, p.age, i_prof.institution, i_prof.software) pat_age,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, p.id_patient, e.id_episode, NULL) photo,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, e.id_episode, l_hand_off_type) resp_icons,
                   e.id_episode,
                   r.id_room,
                   r.capacity,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) desc_bed,
                   decode(p.id_patient, NULL, 'INPfreeBed', 'patientINPIcon') icon,
                   pk_patient.get_pat_name(i_lang, i_prof, e.id_patient, e.id_episode) name_pat,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, e.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, e.id_patient) pat_nd_icon
              FROM room r
             INNER JOIN floors_department fd
                ON fd.id_department = r.id_department
             INNER JOIN department d
                ON d.id_department = fd.id_department
             INNER JOIN (SELECT bed.id_bed, bed.id_room, bed.code_bed, bed.desc_bed, bed.rank
                           FROM bed, room r, floors_department fd
                          WHERE bed.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_v
                            AND bed.flg_available = pk_alert_constant.g_yes
                            AND r.id_room = bed.id_room
                            AND r.id_floors_department = fd.id_floors_department
                            AND fd.id_floors_institution = nvl(i_floor, fd.id_floors_institution)
                          GROUP BY bed.id_bed, bed.id_room, bed.code_bed, bed.desc_bed, bed.rank
                         UNION ALL
                         SELECT bed.id_bed, bed.id_room, bed.code_bed, bed.desc_bed, bed.rank
                           FROM bed, epis_info epo, bmng_allocation_bed ab, room r, floors_department fd
                          WHERE ab.id_bed = bed.id_bed
                            AND r.id_room = bed.id_room
                            AND bed.flg_available = pk_alert_constant.g_yes
                            AND r.id_floors_department = fd.id_floors_department
                            AND fd.id_floors_institution = nvl(i_floor, fd.id_floors_institution)
                            AND bed.flg_status = pk_bmng_constant.g_bmng_bed_flg_status_o
                            AND ab.id_episode = epo.id_episode
                            AND ab.flg_outdated = pk_alert_constant.g_no) b
                ON r.id_room = b.id_room
            --              LEFT JOIN epis_info ei ON ei.id_bed = b.id_bed
              LEFT JOIN bmng_allocation_bed ei
                ON ei.id_bed = b.id_bed
               AND ei.flg_outdated = pk_alert_constant.g_no
              LEFT JOIN episode e
                ON e.id_episode = ei.id_episode
               AND e.flg_ehr = g_flg_ehr_normal
               AND e.flg_status = g_epis_active
               AND e.id_epis_type = l_epis_type
              LEFT JOIN patient p
                ON e.id_patient = p.id_patient
             WHERE fd.id_floors_institution = nvl(i_floor, fd.id_floors_institution)
               AND r.flg_available = g_flg_available
               AND d.flg_available = g_flg_available
               AND d.id_institution = i_prof.institution
               AND instr(d.flg_type, 'I') > 0
             ORDER BY b.rank ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                --Inicialization of object for input 
                l_error_in t_error_in := t_error_in();
            
            BEGIN
            
                -- setting language, setting error content into input object, setting package information 
                l_error_in.set_all(i_lang, SQLCODE, SQLERRM, g_error, 'ALERT', 'PK_BIRD_EYE_ROOM', 'GET_INP_PAT');
            
                -- execute error processing 
                g_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
            
                -- return failure of function_dummy 
            END;
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_INP_PAT',
                                                       o_error);
            RETURN FALSE;
    END get_inp_pat;
    --
    /**********************************************************************************************
    * Eliminar as posições de um determinado departamento
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_dep             professional department id    
    * @param o_floors_dep             cursor with all floors department
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/02
    **********************************************************************************************/
    FUNCTION delete_floors_dep_pos
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_floors_dep IN floors_dep_position.id_floors_department%TYPE,
        o_floors_dep OUT floors_dep_position.id_floors_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        --
        CURSOR c_floors_dep IS
            SELECT 'X'
              FROM floors_dep_position
             WHERE id_floors_department = i_floors_dep;
    BEGIN
        -- Verificar se a sala existe
        g_error := 'GET CURSOR C_FLOORS_DEP';
        OPEN c_floors_dep;
        FETCH c_floors_dep
            INTO l_char;
        g_found := c_floors_dep%FOUND;
        CLOSE c_floors_dep;
        --
        IF g_found
        THEN
            DELETE floors_dep_position
             WHERE id_floors_department = i_floors_dep;
        END IF;
    
        COMMIT;
    
        o_floors_dep := i_floors_dep;
    
        RETURN TRUE;
        --
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DELETE_FLOORS_DEP_POS',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;
    --
    /**********************************************************************************************
    * Registar o departamento por defeito
    *   
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_floors_inst            floor institution id    
    * @param i_department             department id
    * @param o_floors_inst            cursor with all floors institution
    * @param o_department             cursor with all departments   
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Emilia Taborda
    * @version                        1.0 
    * @since                          2007/02/06
    **********************************************************************************************/
    FUNCTION set_default_department
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_floors_inst IN floors_institution.id_floors_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_floors_inst OUT floors_institution.id_floors_institution%TYPE,
        o_department  OUT department.id_department%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char VARCHAR2(1);
        l_dept department.id_dept%TYPE;
        --
        CURSOR c_floors_dep IS
            SELECT 'X'
              FROM floors_department
             WHERE id_floors_institution = i_floors_inst
               AND flg_dep_default = g_yes;
        --
        CURSOR c_dept IS
            SELECT dpt.id_dept
              FROM department dpt
             WHERE dpt.id_department = i_department;
    BEGIN
        g_error := 'OPEN C_FLOORS_DEP';
        OPEN c_floors_dep;
        FETCH c_floors_dep
            INTO l_char;
        g_found := c_floors_dep%FOUND;
        CLOSE c_floors_dep;
        --
        g_error := 'OPEN C_FLOORS_DEP';
        OPEN c_dept;
        FETCH c_dept
            INTO l_dept;
        CLOSE c_dept;
        --
        IF g_found
        THEN
            g_error := 'UPDATE FLOORS_DEPARTMENT - 1';
            UPDATE floors_department
               SET flg_dep_default = NULL
             WHERE id_floors_institution = i_floors_inst;
        END IF;
        --
        g_error := 'UPDATE FLOORS_DEPARTMENT - 2';
        UPDATE floors_department
           SET flg_dep_default = g_yes
         WHERE id_department = i_department
           AND id_floors_institution = i_floors_inst;
        --
        g_error := 'UPDATE DEPARTMENT - 1';
        UPDATE department dpt
           SET dpt.flg_default = NULL
         WHERE dpt.id_dept = l_dept;
    
        UPDATE department dpt
           SET dpt.flg_default = g_yes
         WHERE dpt.id_department = i_department;
    
        COMMIT;
        --
        o_floors_inst := i_floors_inst;
        o_department  := i_department;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DEFAULT_DEPARTMENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

BEGIN
    g_floors_avail  := 'Y';
    g_flg_max       := 'Y';
    g_epis_type     := 2;
    g_epis_active   := 'A';
    g_flg_default   := 'Y';
    g_flg_available := 'Y';
    --
    g_yes := 'Y';
    g_no  := 'N';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_bird_eye_view;
/
