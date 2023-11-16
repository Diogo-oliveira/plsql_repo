/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_diet IS

    /**********************************************************************************************
    * Returns the menu items for the add (+) buttons
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_subject               Menu identifier
    * @param i_state                 Menu state
    * @param i_episode               Id episode
    * @param o_menu                  Menu items
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita lopes
    * @version                       2.5
    * @since                         2009/03/30
    **********************************************************************************************/
    FUNCTION get_menu_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_subject    IN action.subject%TYPE,
        i_state      IN action.from_state%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_menu       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_subject:' || i_subject || ']', g_package_name, 'GET_MENU_DIET');
    
        IF i_subject = 'DIET_TYPE'
        THEN
            g_error := 'OPEN MENU';
            OPEN o_menu FOR
                SELECT dt.id_diet_type id_action,
                       NULL id_parent,
                       dt.rank "LEVEL",
                       NULL to_state,
                       pk_translation.get_translation(i_lang, dt.code_diet_type) desc_action,
                       NULL icon,
                       g_active flg_active,
                       decode(dt.id_diet_type,
                              g_diet_type_inst,
                              'DIET_INSTITUTIONALIZED',
                              g_diet_type_pers,
                              'DIET_PERSONALIZED',
                              g_diet_type_defi,
                              'DIET_PREDEFINED') action
                  FROM diet_type dt
                 WHERE dt.flg_available = g_flg_available
                 ORDER BY dt.rank;
        ELSIF i_subject = 'DIET_SCHEDULE'
        THEN
            g_error := 'OPEN MENU';
            OPEN o_menu FOR
                SELECT ds.id_diet_schedule id_action,
                       NULL id_parent,
                       ds.rank "LEVEL",
                       NULL to_state,
                       pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_action,
                       NULL icon,
                       g_active flg_active,
                       'DIET_SCHEDULE' action
                  FROM diet_schedule ds
                 WHERE ds.flg_available = g_flg_available
                 ORDER BY ds.rank;
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
                                              'GET_MENU_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_menu);
            RETURN FALSE;
        
    END get_menu_diet;

    /**********************************************************************************************
    * Returns the type of food and the food for building a diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet_type          Id of type of diet 
    * @param i_id_diet_parent        id of type of food (parent) for getting food
    * @param o_diet                  Cursor with the food
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/01
    **********************************************************************************************/
    FUNCTION get_diet_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet_type   IN diet_type.id_diet_type%TYPE,
        i_id_diet_parent IN diet.id_diet%TYPE,
        o_diet           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_diet_child IS
            SELECT COUNT(id_diet)
              FROM diet d
             WHERE d.id_diet_parent = i_id_diet_parent
               AND pk_translation.get_translation(i_lang, d.code_diet) IS NOT NULL;
        l_num_diet     NUMBER;
        l_id_diet_type NUMBER;
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet_type' || i_id_diet_type || ' :i_id_diet_parent' || i_id_diet_parent || ']',
                              g_package_name,
                              'GET_DIET_LIST');
    
        IF i_id_diet_type = g_diet_type_defi
        THEN
            l_id_diet_type := g_diet_type_pers;
        ELSE
            l_id_diet_type := i_id_diet_type;
        END IF;
    
        IF i_id_diet_parent IS NULL -- main food (type of diet)
        THEN
            g_error := 'GET PARENT DIET ';
            OPEN o_diet FOR
                SELECT DISTINCT d.id_diet,
                                pk_translation.get_translation(i_lang, d.code_diet) desc_diet,
                                get_diet_description_title(i_lang, i_prof, d.id_diet) desc_diet_viewer,
                                i_id_diet_parent id_parent,
                                d.quantity_default,
                                NULL id_unit_quantity,
                                NULL desc_unit_quant,
                                d.energy_quantity_value,
                                NULL id_unit_energy,
                                NULL desc_unit_energy,
                                d.rank
                  FROM diet d, unit_measure u, unit_measure ue, diet_instit_soft dis
                 WHERE d.id_diet_parent IS NULL
                   AND d.flg_available = g_flg_available
                   AND id_diet_type = l_id_diet_type
                   AND d.id_unit_measure = u.id_unit_measure(+)
                   AND d.id_unit_measure_energy = ue.id_unit_measure(+)
                   AND d.id_diet = dis.id_diet
                   AND dis.flg_available = g_yes
                   AND nvl(dis.id_institution, 0) IN (0, i_prof.institution)
                   AND nvl(dis.id_software, 0) IN (0, i_prof.software)
                 ORDER BY rank, desc_diet;
        ELSE
            -- 
            g_error := 'GET DIET ';
            OPEN c_diet_child;
            FETCH c_diet_child
                INTO l_num_diet;
            CLOSE c_diet_child;
        
            IF l_num_diet > 0
            THEN
                OPEN o_diet FOR
                    SELECT DISTINCT d.id_diet,
                                    pk_translation.get_translation(i_lang, d.code_diet) desc_diet,
                                    get_diet_description_title(i_lang, i_prof, d.id_diet) desc_diet_viewer,
                                    i_id_diet_parent id_parent,
                                    d.quantity_default,
                                    d.id_unit_measure id_unit_quantity,
                                    pk_translation.get_translation(i_lang, u.code_unit_measure) desc_unit_quant,
                                    d.energy_quantity_value,
                                    d.id_unit_measure_energy id_unit_energy,
                                    pk_translation.get_translation(i_lang, ue.code_unit_measure) desc_unit_energy,
                                    d.rank
                      FROM diet d, unit_measure u, unit_measure ue, diet_instit_soft dis
                     WHERE d.id_diet_parent = i_id_diet_parent
                       AND d.flg_available = g_flg_available
                       AND id_diet_type = l_id_diet_type
                       AND d.id_unit_measure = u.id_unit_measure(+)
                       AND d.id_diet = dis.id_diet
                       AND dis.flg_available = g_yes
                       AND d.id_unit_measure_energy = ue.id_unit_measure(+)
                       AND nvl(dis.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(dis.id_software, 0) IN (0, i_prof.software)
                     ORDER BY rank, desc_diet;
            ELSE
                --doesn't has child
                OPEN o_diet FOR
                    SELECT DISTINCT d.id_diet,
                                    pk_translation.get_translation(i_lang, d.code_diet) desc_diet,
                                    get_diet_description_title(i_lang, i_prof, d.id_diet) desc_diet_viewer,
                                    i_id_diet_parent id_parent,
                                    d.quantity_default,
                                    d.id_unit_measure id_unit_quantity,
                                    pk_translation.get_translation(i_lang, u.code_unit_measure) desc_unit_quant,
                                    d.energy_quantity_value,
                                    d.id_unit_measure_energy id_unit_energy,
                                    pk_translation.get_translation(i_lang, ue.code_unit_measure) desc_unit_energy,
                                    d.rank
                      FROM diet d, unit_measure u, unit_measure ue, diet_instit_soft dis
                     WHERE d.id_diet = i_id_diet_parent
                       AND d.flg_available = g_flg_available
                       AND id_diet_type = l_id_diet_type
                       AND d.id_unit_measure = u.id_unit_measure(+)
                       AND d.id_unit_measure_energy = ue.id_unit_measure(+)
                       AND d.id_diet = dis.id_diet
                       AND dis.flg_available = g_yes
                       AND nvl(dis.id_institution, 0) IN (0, i_prof.institution)
                       AND nvl(dis.id_software, 0) IN (0, i_prof.software)
                     ORDER BY rank, desc_diet;
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
                                              'GET_DIET_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
    END get_diet_list;

    /**********************************************************************************************
    * Returns the diet for the episode
    *
    * @param i_lang                  Language ID
    * @param i_episode               ID Episode
    * @param i_type                  Type of information (T - Type of Diet, N - Name of diet) 
    
    * @param o_error                 Error message
    *
    * @return                        A String with active diets
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/07
    **********************************************************************************************/
    FUNCTION get_active_diet
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_type         IN VARCHAR2,
        i_id_epis_diet IN epis_diet_req.id_epis_diet_req%TYPE,
        i_start_date   IN VARCHAR2,
        i_end_date     IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN VARCHAR2 IS
        l_active_diet VARCHAR2(4000);
        l_start_date  TIMESTAMP WITH TIME ZONE;
        l_end_date    TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        l_end_date   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
    
        pk_alertlog.log_debug('PARAMS[:i_type' || i_type || ':i_episode' || i_episode || ']',
                              g_package_name,
                              'GET_ACTIVE_DIET');
        IF i_type = g_flg_diet_t
        THEN
            g_sysdate_tstz := current_timestamp;
        
            SELECT DISTINCT pk_translation.get_translation(i_lang, dt.code_diet_type)
              INTO l_active_diet
              FROM epis_diet_req edr, diet_type dt
             WHERE edr.id_diet_type = dt.id_diet_type
               AND edr.flg_status = g_flg_diet_status_r
               AND id_episode = i_episode
               AND current_timestamp BETWEEN edr.dt_inicial AND nvl(edr.dt_end, current_timestamp)
               AND (edr.id_epis_diet_req != i_id_epis_diet OR i_id_epis_diet IS NULL)
               AND ((l_start_date BETWEEN edr.dt_inicial AND edr.dt_end) OR
                   (l_end_date BETWEEN edr.dt_inicial AND edr.dt_end) OR
                   (l_start_date <= edr.dt_inicial AND l_end_date >= edr.dt_end) OR
                   (l_start_date <= edr.dt_inicial AND i_end_date IS NULL) OR
                   (l_start_date >= edr.dt_inicial AND edr.dt_end IS NULL))
               AND NOT EXISTS (SELECT 1
                      FROM epis_diet_req e
                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
               AND rownum = 1;
        
        ELSE
        
            SELECT DISTINCT decode(dt.id_diet_type,
                                   g_diet_type_inst,
                                   pk_translation.get_translation(i_lang, dt.code_diet_type),
                                   edr.desc_diet)
              INTO l_active_diet
              FROM epis_diet_req edr, diet_type dt
             WHERE edr.id_diet_type = dt.id_diet_type
               AND (edr.id_epis_diet_req != i_id_epis_diet OR i_id_epis_diet IS NULL)
               AND edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s)
               AND id_episode = i_episode
               AND NOT EXISTS (SELECT 1
                      FROM epis_diet_req e
                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
               AND ((l_start_date BETWEEN edr.dt_inicial AND edr.dt_end) OR
                   (l_end_date BETWEEN edr.dt_inicial AND edr.dt_end) OR
                   (l_start_date <= edr.dt_inicial AND l_end_date >= edr.dt_end) OR
                   (l_start_date <= edr.dt_inicial AND i_end_date IS NULL) OR
                   (l_start_date >= edr.dt_inicial AND edr.dt_end IS NULL))
               AND rownum = 1
             ORDER BY 1;
        
        END IF;
        RETURN l_active_diet;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIVE_DIET',
                                              o_error);
            RETURN NULL;
    END get_active_diet;

    /**********************************************************************************************
    * Creates one diet for the patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       Flg institution
    * @param i_resume_notes          Resume notes
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/01
    **********************************************************************************************/
    FUNCTION create_epis_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'Y',
        i_resume_notes       IN epis_diet_req.resume_notes%TYPE DEFAULT NULL,
        i_flg_status_default IN epis_diet_req.flg_status%TYPE DEFAULT 'R',
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_rows             table_varchar;
        l_rows_det         table_varchar;
        l_id_epis_diet_req epis_diet_req.id_epis_diet_req%TYPE;
        l_id_epis_diet_det epis_diet_det.id_epis_diet_det%TYPE;
    
        CURSOR c_epis_type IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        CURSOR c_diet_name IS
            SELECT pk_translation.get_translation(i_lang, code_diet_type)
              FROM diet_type
             WHERE id_diet_type = i_id_diet_type;
    
        CURSOR c_diet_status IS
            SELECT flg_status
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_epis_diet;
    
        l_epis_type       episode.id_epis_type%TYPE;
        l_active_diet     VARCHAR2(4000);
        l_diet_name       epis_diet_req.desc_diet%TYPE;
        l_notes_cancel    sys_message.desc_message%TYPE;
        l_flg_institution epis_diet_req.flg_institution%TYPE;
        l_diet_status_cur epis_diet_req.flg_status%TYPE;
        l_diet_status     epis_diet_req.flg_status%TYPE := g_flg_diet_status_r;
        l_dt_begin_str    VARCHAR2(14);
        l_dt_end_str      VARCHAR2(14);
    
        l_task_os order_set_task.id_task_type%TYPE;
    
        l_flg_status epis_diet_req.flg_status%TYPE;
    
    BEGIN
        pk_alertlog.log_debug('CREATE_EPIS_DIET : PARAMS[:i_type_diet:' || i_id_diet_type || ' :i_id_epis_diet:' ||
                              i_id_epis_diet || ' :i_id_patient' || i_patient || ' ]',
                              g_package_name,
                              'GET_DIET');
    
        g_error := 'CONVERT DATES';
    
        l_dt_begin_str := i_dt_begin_str;
    
        l_dt_end_str := i_dt_end_str;
    
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_begin_str, NULL);
        l_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_end_str, NULL);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        l_notes_cancel := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_M014');
    
        g_error := 'OPEN c_epis_type';
        OPEN c_epis_type;
        FETCH c_epis_type
            INTO l_epis_type;
        CLOSE c_epis_type;
        IF i_id_diet_type = g_diet_type_inst
        THEN
            g_error := 'OPEN c_diet_name';
            OPEN c_diet_name;
            FETCH c_diet_name
                INTO l_diet_name;
            CLOSE c_diet_name;
        
            l_task_os := g_odst_task_instit_diet;
        
        ELSE
            l_diet_name := i_desc_diet;
            IF i_id_diet_type = g_diet_type_defi
            THEN
                l_task_os := g_odst_task_predef_diet;
            END IF;
        END IF;
        IF l_epis_type IN (g_epis_type_inpt, g_epis_type_edis)
        THEN
            l_flg_institution := nvl(i_flg_institution, g_no);
        ELSE
            l_flg_institution := nvl(i_flg_institution, g_yes);
        END IF;
    
        --editing an existing diet:
        IF i_id_epis_diet IS NOT NULL
        THEN
            OPEN c_diet_status;
            FETCH c_diet_status
                INTO l_diet_status_cur;
            CLOSE c_diet_status;
            --IF the diet is in draft state, keep the same state  
            IF l_diet_status_cur = g_flg_diet_status_t
            THEN
                l_diet_status := l_diet_status_cur;
            END IF;
        ELSE
            IF i_flg_status_default IS NOT NULL
            THEN
                l_diet_status := i_flg_status_default;
            END IF;
        END IF;
    
        IF l_diet_status_cur = g_flg_diet_status_o
        THEN
            g_error := 'CALL TS_EPIS_DIET_REQ.UPD';
            ts_epis_diet_req.upd(id_diet_type_in        => i_id_diet_type,
                                 id_episode_in          => i_episode,
                                 id_patient_in          => i_patient,
                                 id_professional_in     => i_prof.id,
                                 desc_diet_in           => i_desc_diet,
                                 flg_status_in          => g_flg_diet_status_o,
                                 notes_in               => i_notes,
                                 food_plan_in           => i_food_plan,
                                 flg_help_in            => i_flg_help,
                                 dt_creation_in         => g_sysdate_tstz,
                                 dt_inicial_in          => l_dt_begin_tstz,
                                 dt_end_in              => l_dt_end_tstz,
                                 flg_institution_in     => i_flg_institution,
                                 id_diet_prof_instit_in => i_id_diet_predefined,
                                 resume_notes_in        => i_resume_notes,
                                 id_epis_diet_req_in    => i_id_epis_diet,
                                 rows_out               => l_rows);
            pk_alertlog.log_debug('CREATE_EPIS_DIET: Update diet:' || i_id_epis_diet,
                                  g_package_name,
                                  'CREATE_EPIS_DIET');
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
            ts_epis_diet_det.del_edd_edr_fk(id_epis_diet_req_in => i_id_epis_diet);
        
            o_id_epis_diet := i_id_epis_diet;
        
        ELSE
            g_error := 'CALL TS_EPIS_DIET_REQ.INS';
            ts_epis_diet_req.ins(id_diet_type_in            => i_id_diet_type,
                                 id_episode_in              => i_episode,
                                 id_patient_in              => i_patient,
                                 id_professional_in         => i_prof.id,
                                 desc_diet_in               => i_desc_diet,
                                 flg_status_in              => l_diet_status,
                                 notes_in                   => i_notes,
                                 food_plan_in               => i_food_plan,
                                 flg_help_in                => i_flg_help,
                                 dt_creation_in             => g_sysdate_tstz,
                                 dt_inicial_in              => l_dt_begin_tstz,
                                 dt_end_in                  => l_dt_end_tstz,
                                 flg_institution_in         => i_flg_institution,
                                 id_diet_prof_instit_in     => i_id_diet_predefined,
                                 id_epis_diet_req_parent_in => i_id_epis_diet,
                                 resume_notes_in            => i_resume_notes,
                                 id_epis_diet_req_out       => o_id_epis_diet,
                                 rows_out                   => l_rows);
            pk_alertlog.log_debug('CREATE_EPIS_DIET: Inserted diet:' || o_id_epis_diet,
                                  g_package_name,
                                  'CREATE_EPIS_DIET');
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END IF;
    
        g_error := 'AFTER TS_EPIS_DIET_REQ.INS';
        -- update reference  order sets that are using this diet
        IF i_id_epis_diet IS NOT NULL
           AND i_id_diet_type != g_diet_type_pers -- update only if already associated with the patient
        THEN
        
            IF NOT pk_api_order_sets.update_task_proc_reference(i_lang,
                                                                i_prof,
                                                                l_task_os,
                                                                i_id_epis_diet,
                                                                o_id_epis_diet,
                                                                o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_id_diet_schedule.count > 0
        THEN
            -- insert the diet detail
            FOR i IN i_id_diet_schedule.first .. i_id_diet_schedule.last
            LOOP
                IF i_id_diet(i) IS NOT NULL
                THEN
                    g_error := 'CALL ts_epis_diet_det.ins';
                    ts_epis_diet_det.ins(id_epis_diet_req_in  => o_id_epis_diet,
                                         notes_in             => i_notes_diet(i),
                                         id_diet_schedule_in  => i_id_diet_schedule(i),
                                         dt_diet_schedule_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_dt_hour(i),
                                                                                               NULL),
                                         id_diet_in           => i_id_diet(i),
                                         quantity_in          => i_quantity(i),
                                         id_unit_measure_in   => i_id_unit(i),
                                         id_epis_diet_det_out => l_id_epis_diet_det,
                                         rows_out             => l_rows_det);
                END IF;
            END LOOP;
        END IF;
        pk_alertlog.log_debug('CREATE_EPIS_DIET: Inserted diet_det ' || i_id_diet_schedule.count || ' records',
                              g_package_name,
                              'CREATE_EPIS_DIET');
    
        IF l_epis_type = g_epis_type_inpt
        THEN
            pk_alertlog.log_debug('CREATE_EPIS_DIET: INPT DIET', g_package_name, 'CREATE_EPIS_DIET');
        
            g_error       := 'EPIS_TYPE = INP';
            l_active_diet := get_active_diet(i_lang,
                                             i_prof,
                                             i_episode,
                                             g_flg_diet_t,
                                             i_id_epis_diet,
                                             i_dt_begin_str,
                                             i_dt_end_str,
                                             o_error);
            -- UPDATE THE EPISODE DIET ON EPIS_INFO
            l_rows  := table_varchar();
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(id_episode_in => i_episode,
                             desc_diet_in  => l_active_diet,
                             desc_diet_nin => FALSE,
                             rows_out      => l_rows);
        END IF;
    
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => i_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_EPIS_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CREATE_EPIS_DIET');
            RETURN FALSE;
        
    END create_epis_diet;

    /**********************************************************************************************
    * Creates one diet for the patient (with transaction control)
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_predefined    id of predefined diet 
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_commit                commits or not the db transaction in the end
    * @param i_flg_institution       flg that indicates if it is available out of the institution
    * @param i_flg_share             flg that indicates if it is shared with other users
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/01
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE, --5
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE, --10
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number, --15
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_commit             IN VARCHAR2, --20
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_flg_status_default IN epis_diet_req.flg_status%TYPE DEFAULT 'R',
        i_flg_order_set      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_force          IN VARCHAR2 DEFAULT pk_alert_constant.g_no, --25
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status        epis_diet_req.flg_status%TYPE;
        l_exists_diet       VARCHAR2(1000 CHAR);
        l_multiple_diet_cfg sys_config.value%TYPE := pk_sysconfig.get_config('DIET_MULTIPLE', i_prof);
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[:Diet_Type: ' || i_id_diet_type || ']', g_package_name, 'CREATE_DIET');
    
        l_exists_diet := get_active_diet(i_lang,
                                         i_prof,
                                         i_episode,
                                         NULL,
                                         i_id_epis_diet,
                                         i_dt_begin_str,
                                         i_dt_end_str,
                                         o_error);
    
        IF l_exists_diet IS NOT NULL
           AND i_flg_order_set = pk_alert_constant.g_no
           AND l_multiple_diet_cfg = pk_alert_constant.g_no
        THEN
            --o_msg_warning := 'TESADASDASDASDAS';
            o_msg_warning := pk_message.get_message(i_lang, 'DIET_T141');
            RETURN TRUE;
        END IF;
    
        IF i_id_diet_type IN (g_diet_type_defi, g_diet_type_inst)
           AND i_patient IS NULL
        THEN
            g_error := 'CALL CREATE_DIET_PREF';
            IF NOT create_diet_pref(i_lang                => i_lang,
                                    i_prof                => i_prof,
                                    i_id_diet_prof_instit => i_id_epis_diet,
                                    i_id_diet_type        => i_id_diet_type,
                                    i_desc_diet           => i_desc_diet,
                                    i_food_plan           => i_food_plan,
                                    i_flg_help            => i_flg_help,
                                    i_flg_institution     => i_flg_institution,
                                    i_flg_share           => i_flg_share,
                                    i_notes               => i_notes,
                                    i_id_diet_schedule    => i_id_diet_schedule,
                                    i_id_diet             => i_id_diet,
                                    i_quantity            => i_quantity,
                                    i_id_unit             => i_id_unit,
                                    i_notes_diet          => i_notes_diet,
                                    i_dt_hour             => i_dt_hour,
                                    o_id_diet_prof        => o_id_epis_diet,
                                    o_error               => o_error)
            THEN
                --  RAISE g_exception;
                ROLLBACK;
                RETURN FALSE;
            END IF;
        ELSE
            g_error := 'CALL CREATE_EPIS_DIET_INTERNAL';
            pk_alertlog.log_debug(g_error);
            IF NOT create_epis_diet(i_lang               => i_lang,
                                    i_prof               => i_prof,
                                    i_patient            => i_patient,
                                    i_episode            => i_episode,
                                    i_id_epis_diet       => i_id_epis_diet,
                                    i_id_diet_type       => i_id_diet_type,
                                    i_desc_diet          => i_desc_diet,
                                    i_dt_begin_str       => i_dt_begin_str,
                                    i_dt_end_str         => i_dt_end_str,
                                    i_food_plan          => i_food_plan,
                                    i_flg_help           => i_flg_help,
                                    i_notes              => i_notes,
                                    i_id_diet_predefined => i_id_diet_predefined,
                                    i_id_diet_schedule   => i_id_diet_schedule,
                                    i_id_diet            => i_id_diet,
                                    i_quantity           => i_quantity,
                                    i_id_unit            => i_id_unit,
                                    i_notes_diet         => i_notes_diet,
                                    i_dt_hour            => i_dt_hour,
                                    i_flg_institution    => i_flg_institution,
                                    i_flg_status_default => i_flg_status_default,
                                    o_id_epis_diet       => o_id_epis_diet,
                                    o_error              => o_error)
            THEN
                --  RAISE g_exception;
                ROLLBACK;
                RETURN FALSE;
            END IF;
        
            BEGIN
                SELECT edr.flg_status
                  INTO l_flg_status
                  FROM epis_diet_req edr
                 WHERE edr.id_epis_diet_req = o_id_epis_diet;
            EXCEPTION
                WHEN no_data_found THEN
                    l_flg_status := NULL;
            END;
        
            IF l_flg_status != g_flg_diet_status_o
            THEN
                --Synchronize CPOE tasks
                g_error := 'CALL SYNC_TASK : ' || o_id_epis_diet;
                IF NOT sync_task(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_episode          => i_episode,
                                 i_task_type        => i_id_diet_type,
                                 i_task_request     => o_id_epis_diet,
                                 i_task_request_old => i_id_epis_diet,
                                 i_dt_task          => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                                     i_prof      => i_prof,
                                                                                     i_timestamp => i_dt_begin_str,
                                                                                     i_timezone  => NULL),
                                 o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
        END IF;
    
        -- transaction control
        IF i_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_diet;

    /**********************************************************************************************
    * creates one diet for the patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_predefined    id of predefined diet 
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       flg that indicates if it is available out of the institution
    * @param i_flg_share             flg that indicates if it is shared with other users
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/23
    **********************************************************************************************/
    FUNCTION create_diet
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_flg_order_set      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_flg_force          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_warning        OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_multiple_diet_cfg sys_config.value%TYPE := pk_sysconfig.get_config('DIET_MULTIPLE', i_prof);
    BEGIN
    
        l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin_str, NULL);
        l_end_date   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end_str, NULL);
    
        IF i_flg_force = pk_alert_constant.g_yes
           AND l_multiple_diet_cfg = pk_alert_constant.g_no
        THEN
        
            FOR reg IN (SELECT edr.id_epis_diet_req
                          FROM epis_diet_req edr
                         WHERE edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s)
                           AND ((l_start_date BETWEEN
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_inicial) AND
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_end)) OR
                               (l_end_date BETWEEN
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_inicial) AND
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_end)) OR
                               (l_start_date <=
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_inicial) AND
                               l_end_date >=
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_end)) OR
                               (l_start_date <=
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                          i_inst      => i_prof.institution,
                                                                          i_timestamp => edr.dt_inicial) AND
                               i_dt_end_str IS NULL) OR (l_start_date >=
                               pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                   i_inst      => i_prof.institution,
                                                                                                   i_timestamp => edr.dt_inicial) AND
                               edr.dt_end IS NULL))
                              
                           AND id_episode = i_episode)
            LOOP
                IF NOT cancel_diet(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_id_diet => reg.id_epis_diet_req,
                                   i_notes   => NULL,
                                   i_reason  => NULL,
                                   o_error   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END LOOP;
        END IF;
    
        -- call create_diet with commit control
        IF NOT create_diet(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_patient            => i_patient,
                           i_episode            => i_episode,
                           i_id_epis_diet       => i_id_epis_diet,
                           i_id_diet_type       => i_id_diet_type,
                           i_desc_diet          => i_desc_diet,
                           i_dt_begin_str       => i_dt_begin_str,
                           i_dt_end_str         => i_dt_end_str,
                           i_food_plan          => i_food_plan,
                           i_flg_help           => i_flg_help,
                           i_notes              => i_notes,
                           i_id_diet_predefined => i_id_diet_predefined,
                           i_id_diet_schedule   => i_id_diet_schedule,
                           i_id_diet            => i_id_diet,
                           i_quantity           => i_quantity,
                           i_id_unit            => i_id_unit,
                           i_notes_diet         => i_notes_diet,
                           i_dt_hour            => i_dt_hour,
                           i_commit             => g_yes,
                           i_flg_institution    => i_flg_institution,
                           i_flg_share          => i_flg_share,
                           i_flg_order_set      => i_flg_order_set,
                           i_flg_force          => i_flg_force,
                           o_id_epis_diet       => o_id_epis_diet,
                           o_msg_warning        => o_msg_warning,
                           o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              'CREATE_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END create_diet;

    /**********************************************************************************************
    * Creates one predefined diet for the professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_desc_diet             Description of diet
    * @param i_food_plan             Food plan 
    * @param i_flg_SHARE             Flag that indicates if professional want's to share is diet(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param o_id_DIET_PROF          ID of predefined diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/02
    **********************************************************************************************/
    FUNCTION create_diet_pref
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_id_diet_type        IN diet_type.id_diet_type%TYPE,
        i_desc_diet           IN diet_prof_instit.desc_diet%TYPE,
        i_food_plan           IN diet_prof_instit.food_plan%TYPE,
        i_flg_help            IN diet_prof_instit.flg_help%TYPE,
        i_flg_institution     IN diet_prof_instit.flg_institution%TYPE,
        i_flg_share           IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        i_notes               IN diet_prof_instit.notes%TYPE,
        i_id_diet_schedule    IN table_number,
        i_id_diet             IN table_number,
        i_quantity            IN table_number,
        i_id_unit             IN table_number,
        i_notes_diet          IN table_varchar,
        i_dt_hour             IN table_varchar,
        o_id_diet_prof        OUT diet_prof_instit.id_diet_prof_instit%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rows             table_varchar;
        l_rows_det         table_varchar;
        l_rows_pref        table_varchar;
        l_id_diet_pref_def diet_prof_instit_det.id_diet_prof_instit_det%TYPE;
        l_where            VARCHAR2(200);
        l_id_diet_prof     diet_prof_pref.id_diet_prof_pref%TYPE;
        l_id_prof          diet_prof_pref.id_prof_pref%TYPE;
        l_diet_name        diet_prof_instit.desc_diet%TYPE;
        l_task_type        order_set_task.id_task_type%TYPE;
    
        CURSOR c_diet_name IS
            SELECT pk_translation.get_translation(i_lang, code_diet_type)
              FROM diet_type
             WHERE id_diet_type = i_id_diet_type;
    
        CURSOR c_diet_pref IS
            SELECT id_diet_prof_pref, id_prof_pref
              FROM diet_prof_pref
             WHERE id_diet_prof_instit = i_id_diet_prof_instit;
    
        CURSOR c_diet_status IS
            SELECT flg_status
              FROM diet_prof_instit
             WHERE id_diet_prof_instit = i_id_diet_prof_instit;
    
        l_diet_status     diet_prof_instit.flg_status%TYPE;
        l_diet_status_cur diet_prof_instit.flg_status%TYPE;
        l_count           NUMBER;
    
    BEGIN
        pk_alertlog.log_debug('CREATE_DIET_PREF', g_package_name);
    
        IF i_id_diet_type = g_diet_type_inst
        THEN
            g_error := 'OPEN c_diet_name';
            OPEN c_diet_name;
            FETCH c_diet_name
                INTO l_diet_name;
            CLOSE c_diet_name;
        
            l_task_type   := g_odst_task_instit_diet;
            l_diet_status := g_flg_diet_status_o;
        ELSE
            l_diet_name := i_desc_diet;
        
            l_task_type := g_odst_task_predef_diet;
        
            l_diet_status := g_flg_diet_status_a;
        END IF;
    
        pk_alertlog.log_debug('CREATE_DIET_PREF: determine Flg_status', g_package_name, 'CREATE_DIET_PREF');
    
        OPEN c_diet_status;
        FETCH c_diet_status
            INTO l_diet_status_cur;
        CLOSE c_diet_status;
    
        pk_alertlog.log_debug('CREATE_DIET_PREF: Flg_status:' || l_diet_status_cur, g_package_name, 'CREATE_DIET_PREF');
    
        IF l_diet_status_cur = g_flg_diet_status_o
        THEN
            ts_diet_prof_instit.upd(id_diet_prof_instit_in => i_id_diet_prof_instit,
                                    id_diet_type_in        => i_id_diet_type,
                                    desc_diet_in           => l_diet_name,
                                    flg_status_in          => g_flg_diet_status_o,
                                    food_plan_in           => i_food_plan,
                                    flg_share_in           => nvl(i_flg_share, g_no),
                                    id_prof_create_in      => i_prof.id,
                                    id_institution_in      => i_prof.institution,
                                    notes_in               => i_notes,
                                    dt_creation_in         => g_sysdate_tstz,
                                    flg_help_in            => i_flg_help,
                                    flg_institution_in     => i_flg_institution,
                                    rows_out               => l_rows);
        
            pk_alertlog.log_debug('Update:' || i_id_diet_prof_instit, g_package_name, 'CREATE_DIET_PREF');
            SELECT COUNT(*)
              INTO l_count
              FROM diet_prof_instit_det dpid
             WHERE dpid.id_diet_prof_instit = i_id_diet_prof_instit;
        
            IF l_count > 0
            THEN
                ts_diet_prof_instit_det.del_dpid_dpi_fk(id_diet_prof_instit_in => i_id_diet_prof_instit);
            END IF;
            o_id_diet_prof := i_id_diet_prof_instit;
        
        ELSE
        
            g_sysdate_tstz := current_timestamp;
            -- INACTIVATE PREVIOUS DIET 
            g_error := 'INSERT DIET_PROF_INSTIT';
            ts_diet_prof_instit.ins(id_diet_type_in         => i_id_diet_type,
                                    desc_diet_in            => l_diet_name,
                                    flg_status_in           => l_diet_status,
                                    food_plan_in            => i_food_plan,
                                    flg_share_in            => nvl(i_flg_share, g_no),
                                    id_prof_create_in       => i_prof.id,
                                    id_institution_in       => i_prof.institution,
                                    notes_in                => i_notes,
                                    dt_creation_in          => g_sysdate_tstz,
                                    id_diet_prof_parent_in  => i_id_diet_prof_instit,
                                    flg_help_in             => i_flg_help,
                                    flg_institution_in      => i_flg_institution,
                                    id_diet_prof_instit_out => o_id_diet_prof,
                                    rows_out                => l_rows);
        
            pk_alertlog.log_debug('CREATE_DIET_PREF: Inserted diet:' || o_id_diet_prof,
                                  g_package_name,
                                  'CREATE_DIET_PREF');
        END IF;
    
        IF i_id_diet_schedule.count > 0
        THEN
            FOR i IN i_id_diet_schedule.first .. i_id_diet_schedule.last
            LOOP
                IF i_id_diet(i) IS NOT NULL
                THEN
                    g_error := 'INSERT DIET_PROF_INSTIT_DET';
                    ts_diet_prof_instit_det.ins(id_diet_prof_instit_in      => o_id_diet_prof,
                                                notes_in                    => i_notes_diet(i),
                                                id_diet_schedule_in         => i_id_diet_schedule(i),
                                                dt_diet_schedule_in         => pk_date_utils.get_string_tstz(i_lang,
                                                                                                             i_prof,
                                                                                                             i_dt_hour(i),
                                                                                                             NULL),
                                                id_diet_in                  => i_id_diet(i),
                                                quantity_in                 => i_quantity(i),
                                                id_unit_measure_in          => i_id_unit(i),
                                                id_diet_prof_instit_det_out => l_id_diet_pref_def,
                                                rows_out                    => l_rows_det);
                
                END IF;
            END LOOP;
        END IF;
        pk_alertlog.log_debug('CREATE_DIET_PREF: Inserted diet_det:' || i_id_diet_schedule.count || ' records',
                              g_package_name,
                              'CREATE_DIET_PREF');
    
        IF i_id_diet_type = g_diet_type_defi
        THEN
            IF i_id_diet_prof_instit IS NOT NULL
            THEN
                -- UPDATE ONE DIET - deactive the diet to be edited
                g_error := 'UPDATE DIET';
                ts_diet_prof_instit.upd(id_diet_prof_instit_in => i_id_diet_prof_instit,
                                        flg_status_in          => g_flg_diet_status_c,
                                        id_prof_cancel_in      => i_prof.id,
                                        dt_cancel_in           => g_sysdate_tstz,
                                        rows_out               => l_rows);
            
                OPEN c_diet_pref;
                LOOP
                    FETCH c_diet_pref
                        INTO l_id_diet_prof, l_id_prof;
                    EXIT WHEN c_diet_pref%NOTFOUND;
                    -- deactivate preferenced diet for user  
                    g_error := 'CANCEL PREFERENCE DIET';
                    l_where := 'ID_DIET_PROF_INSTIT = ' || i_id_diet_prof_instit;
                    ts_diet_prof_pref.upd(id_diet_prof_pref_in => l_id_diet_prof,
                                          flg_status_in        => g_no,
                                          dt_cancel_in         => g_sysdate_tstz,
                                          rows_out             => l_rows_pref);
                    -- insert new diet preference
                    g_error := 'ADD NEW PREFERENCE DIET';
                    ts_diet_prof_pref.ins(id_diet_prof_instit_in => o_id_diet_prof,
                                          id_prof_pref_in        => l_id_prof,
                                          flg_status_in          => g_yes,
                                          dt_creation_in         => g_sysdate_tstz,
                                          rows_out               => l_rows_pref);
                END LOOP;
            
                -- update references for all order sets that are using this diet
                IF NOT pk_api_order_sets.update_task_reference(i_lang,
                                                               i_prof,
                                                               l_task_type,
                                                               i_id_diet_prof_instit,
                                                               o_id_diet_prof,
                                                               o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
            
                -- INSERT  new diet and add'it to my preferenced
                g_error := 'ADD NEW PREFERENCE DIET';
                ts_diet_prof_pref.ins(id_diet_prof_instit_in => o_id_diet_prof,
                                      id_prof_pref_in        => i_prof.id,
                                      flg_status_in          => g_yes,
                                      dt_creation_in         => g_sysdate_tstz,
                                      rows_out               => l_rows_pref);
            
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
                                              'CREATE_EPIS_DIET_PREF',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CREATE_EPIS_DIET_PREF');
            RETURN FALSE;
    END create_diet_pref;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN NUMBER,
        o_diet_register OUT NOCOPY pk_types.cursor_type,
        o_diet          OUT NOCOPY pk_types.cursor_type,
        o_diet_food     OUT NOCOPY pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type  episode.id_epis_type%TYPE;
        l_flg_action VARCHAR2(1);
    BEGIN
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_epis_type := NULL;
        END;
        IF l_epis_type IN (g_epis_type_inpt, g_epis_type_edis)
        THEN
            l_flg_action := g_yes;
        ELSE
            l_flg_action := g_no;
        END IF;
    
        g_error := 'CALL GET_DIET_SUMMARY_INT';
        pk_alertlog.log_debug(g_error);
        IF NOT get_diet_summary(i_lang            => i_lang,
                                i_prof            => i_prof,
                                i_scope           => i_patient,
                                i_flg_scope       => pk_alert_constant.g_scope_type_patient,
                                i_start_date      => NULL,
                                i_end_date        => NULL,
                                i_cancelled       => pk_alert_constant.g_yes,
                                i_crit_type       => g_diet_crit_type_all_a,
                                i_flg_report      => pk_alert_constant.g_no,
                                i_current_episode => i_episode,
                                i_id_diet         => i_id_diet,
                                i_flg_epis_type   => l_flg_action,
                                o_diet_register   => o_diet_register,
                                o_diet            => o_diet,
                                o_diet_food       => o_diet_food,
                                o_error           => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_DIET_SUMMARY',
                                              o_error);
        
            RETURN FALSE;
        
    END get_diet_summary;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_flg_scope       IN VARCHAR2,
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_cancelled       IN VARCHAR2,
        i_crit_type       IN VARCHAR2,
        i_flg_report      IN VARCHAR2,
        i_current_episode IN episode.id_episode%TYPE,
        i_id_diet         IN NUMBER,
        i_flg_epis_type   IN VARCHAR2,
        o_diet_register   OUT pk_types.cursor_type,
        o_diet            OUT pk_types.cursor_type,
        o_diet_food       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_type      sys_message.desc_message%TYPE;
        l_diet_name      sys_message.desc_message%TYPE;
        l_dt_inicio      sys_message.desc_message%TYPE;
        l_dt_end         sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_plan           sys_message.desc_message%TYPE;
        l_help           sys_message.desc_message%TYPE;
        l_schedule       sys_message.desc_message%TYPE;
        l_food           sys_message.desc_message%TYPE;
        l_type_food      sys_message.desc_message%TYPE;
        l_share          sys_message.desc_message%TYPE;
        l_institution    sys_message.desc_message%TYPE;
        l_desc_interrupt sys_message.desc_message%TYPE;
        l_id_prof_alert  sys_config.value%TYPE;
        l_diet_active    sys_message.desc_message%TYPE;
        l_diet_suspend   sys_message.desc_message%TYPE;
        l_diet_completed sys_message.desc_message%TYPE;
        l_diet_state     sys_message.desc_message%TYPE;
        l_diet_canceled  sys_message.desc_message%TYPE;
        l_diet_schedule  sys_message.desc_message%TYPE;
        l_diet_draft     sys_message.desc_message%TYPE;
        l_diet_expired   sys_message.desc_message%TYPE;
        l_epis_type      episode.id_epis_type%TYPE;
        l_flg_action     VARCHAR2(1);
    
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
    
        e_invalid_argument EXCEPTION;
    
    BEGIN
        pk_alertlog.log_debug('GET_DIET_SUMMARY', g_package_name);
    
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        --convert string to date format
        IF i_start_date IS NOT NULL
        THEN
            l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            l_end_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
        END IF;
    
        g_sysdate_tstz := current_timestamp;
        l_diet_type    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T048');
        l_diet_name    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T049');
        l_dt_inicio    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T050');
        l_dt_end       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T051');
        l_notes        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T045');
        l_plan         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T068');
        l_help         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T053');
        l_schedule     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T029') || ':';
        l_food         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T046');
        l_type_food    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T069');
        l_share        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T073');
        l_institution  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T070');
    
        l_diet_active    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T086');
        l_diet_suspend   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T087');
        l_diet_completed := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T088');
        l_diet_state     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T084');
        l_diet_canceled  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T094');
        l_diet_schedule  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T095');
        --
        l_diet_draft   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T107');
        l_diet_expired := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T108');
        --
        l_id_prof_alert := pk_sysconfig.get_config(i_code_cf => 'ID_PROF_ALERT', i_prof => i_prof);
    
        IF i_id_diet IS NULL -- details of diets of patient
        THEN
            g_error := 'OPEN CURSOR O_DIET_REGISTER (patient)';
            -- PROFESSIONAL THAT REGISTER THE DIET
            OPEN o_diet_register FOR
                SELECT id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_action, i_prof) dt_register,
                       id_professional,
                       nick_name,
                       desc_speciality,
                       flg_status_bd,
                       flg_status,
                       flg_current_episode,
                       flg_detail,
                       id_diet_type,
                       desc_diet_title,
                       desc_diet,
                       decode(id_diet_type, g_diet_type_inst, i_flg_epis_type, g_yes) flg_action,
                       decode(id_diet_type,
                              g_diet_type_inst,
                              decode(i_flg_epis_type,
                                     g_yes,
                                     decode(flg_status,
                                            g_flg_diet_status_a,
                                            l_flg_action,
                                            g_flg_diet_status_h,
                                            i_flg_epis_type,
                                            g_no)),
                              decode(flg_status, g_flg_diet_status_a, g_yes, g_flg_diet_status_h, g_yes, g_no)) flg_cancel
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               edr.id_professional,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional)) nick_name,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_professional,
                                                                       edr.dt_creation,
                                                                       NULL)) desc_speciality,
                               edr.flg_status flg_status_bd,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_f) flg_status,
                               decode(edr.id_episode, i_current_episode, g_yes, g_no) flg_current_episode,
                               g_yes flg_detail,
                               edr.id_diet_type,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_translation.get_translation(i_lang, dt.code_diet_type),
                                      htf.escape_sc(edr.desc_diet)) desc_diet_title,
                               htf.escape_sc(desc_diet) desc_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      3,
                                      g_flg_diet_status_c,
                                      5,
                                      decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                             'G',
                                             2,
                                             decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                                    'L',
                                                    4,
                                                    1))) rank
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND
                               edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s, g_flg_diet_status_c)))
                           AND NOT EXISTS (SELECT 1
                                  FROM epis_diet_req e
                                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent))
                 ORDER BY rank, dt_action DESC;
        
            -- DETAIL OF DIET
            g_error := 'OPEN CURSOR O_DIET (patient)';
            OPEN o_diet FOR
                SELECT id_diet,
                       diet_status_title,
                       diet_status,
                       diet_type_title,
                       desc_diet_type,
                       diet_name_title,
                       diet_name,
                       dt_initial_title,
                       dt_initial,
                       decode(dt_end, NULL, NULL, dt_end_title) dt_end_title,
                       dt_end,
                       notes_title,
                       notes,
                       food_plan_title,
                       food_plan,
                       decode(desc_help, NULL, NULL, desc_help_title) desc_help_title,
                       desc_help,
                       flg_help,
                       desc_institution_title,
                       desc_institution,
                       flg_institution
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               l_diet_state diet_status_title,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req) diet_status,
                               l_diet_type diet_type_title,
                               pk_translation.get_translation(i_lang, dt.code_diet_type) desc_diet_type,
                               decode(edr.desc_diet, NULL, NULL, l_diet_name) diet_name_title,
                               htf.escape_sc(edr.desc_diet) diet_name,
                               l_dt_inicio dt_initial_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                               l_dt_end dt_end_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software) dt_end,
                               l_notes notes_title,
                               htf.escape_sc(edr.notes) notes,
                               decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan) food_plan_title,
                               edr.food_plan || decode(edr.food_plan,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                          FROM unit_measure um
                                                         WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                               l_help desc_help_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                               edr.flg_help,
                               decode(edr.flg_institution, NULL, NULL, l_institution) desc_institution_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution,
                               edr.flg_institution
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                              
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND
                               edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s, g_flg_diet_status_c)))
                              
                           AND NOT EXISTS (SELECT 1
                                  FROM epis_diet_req e
                                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent))
                 ORDER BY dt_action DESC;
            g_error := 'OPEN CURSOR O_DIET_FOOD (patient)';
            -- cursor with the detail of diet
        
            -- gets the food
            OPEN o_diet_food FOR
                SELECT DISTINCT edr.id_epis_diet_req id_diet,
                                pk_date_utils.get_timestamp_str(i_lang,
                                                                i_prof,
                                                                decode(edr.flg_status,
                                                                       g_flg_diet_status_s,
                                                                       edr.dt_cancel,
                                                                       g_flg_diet_status_c,
                                                                       edr.dt_cancel,
                                                                       edr.dt_creation),
                                                                NULL) dt_creation_food,
                                ds.rank,
                                ds.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                l_schedule schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, edd.dt_diet_schedule, i_prof) meal_hour,
                                decode(edr.id_diet_type, g_diet_type_inst, l_type_food, l_food) food_title,
                                pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) ||
                                    decode(' ||
                                                         edr.id_diet_type || ',' || g_diet_type_inst || ',
                                           NULL,
                                           '', '' || edd2.quantity ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                           decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                               FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                              WHERE edd2.id_diet = d.id_diet
                                AND edd2.id_epis_diet_req = ' ||
                                                         edd.id_epis_diet_req || '
                                AND edd2.id_diet_schedule = ' ||
                                                         edd.id_diet_schedule || '
                                AND edd2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                         '<BR>') lst_food
                  FROM epis_diet_req edr
                 INNER JOIN epis_diet_det edd
                    ON edr.id_epis_diet_req = edd.id_epis_diet_req
                 INNER JOIN diet_schedule ds
                    ON edd.id_diet_schedule = ds.id_diet_schedule
                 INNER JOIN episode epis
                    ON edr.id_episode = epis.id_episode
                 WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                   AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                   AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                   AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND nvl(l_end_date, edr.dt_creation)
                   AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                       edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s)) OR
                       (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                       i_flg_report = pk_alert_constant.g_no) AND
                       edr.flg_status IN (g_flg_diet_status_r, g_flg_diet_status_s, g_flg_diet_status_c)))
                      
                   AND NOT EXISTS (SELECT 1
                          FROM epis_diet_req e
                         WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                 ORDER BY dt_creation_food DESC, rank ASC;
        
        ELSE
            g_error := 'OPEN CURSOR O_DIET_REGISTER (patient)';
            -- PROFESSIONAL THAT REGISTER THE DIET
            OPEN o_diet_register FOR
                SELECT id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_action, i_prof) dt_register,
                       id_professional,
                       nick_name,
                       desc_speciality,
                       flg_status_bd,
                       flg_status,
                       flg_current_episode,
                       flg_detail,
                       id_diet_type,
                       desc_diet_title,
                       desc_diet
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               edr.id_professional,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional)) nick_name,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_professional,
                                                                       edr.dt_creation,
                                                                       NULL)) desc_speciality,
                               edr.flg_status flg_status_bd,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_f) flg_status,
                               decode(edr.id_episode, i_current_episode, g_yes, g_no) flg_current_episode,
                               g_yes flg_detail,
                               edr.id_diet_type,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_translation.get_translation(i_lang, dt.code_diet_type),
                                      htf.escape_sc(edr.desc_diet)) desc_diet_title,
                               htf.escape_sc(desc_diet) desc_diet
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.id_epis_diet_req = i_id_diet
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_c)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND edr.flg_status NOT IN (g_flg_diet_status_t))))
                 ORDER BY dt_action DESC;
        
            -- DETAIL OF DIET
            g_error := 'OPEN CURSOR O_DIET (patient)';
            OPEN o_diet FOR
                SELECT id_diet,
                       diet_status_title,
                       diet_status,
                       diet_type_title,
                       desc_diet_type,
                       diet_name_title,
                       diet_name,
                       dt_initial_title,
                       dt_initial,
                       dt_end_title,
                       dt_end,
                       notes_title,
                       notes,
                       food_plan_title,
                       food_plan,
                       desc_help_title,
                       desc_help,
                       flg_help,
                       desc_institution_title,
                       desc_institution,
                       flg_institution
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               l_diet_state diet_status_title,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req) diet_status,
                               l_diet_type diet_type_title,
                               pk_translation.get_translation(i_lang, dt.code_diet_type) desc_diet_type,
                               decode(edr.desc_diet, NULL, NULL, l_diet_name) diet_name_title,
                               htf.escape_sc(edr.desc_diet) diet_name,
                               l_dt_inicio dt_initial_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                               l_dt_end dt_end_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software) dt_end,
                               l_notes notes_title,
                               htf.escape_sc(edr.notes) notes,
                               decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan) food_plan_title,
                               edr.food_plan || decode(edr.food_plan,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                          FROM unit_measure um
                                                         WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                               l_help desc_help_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                               edr.flg_help,
                               decode(edr.flg_institution, NULL, NULL, l_institution) desc_institution_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution,
                               edr.flg_institution
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.id_epis_diet_req = i_id_diet
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_c)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND edr.flg_status NOT IN (g_flg_diet_status_t))))
                 ORDER BY dt_action DESC;
            g_error := 'OPEN CURSOR O_DIET_FOOD (patient)';
        
            -- gets the food
            OPEN o_diet_food FOR
                SELECT DISTINCT edr.id_epis_diet_req id_diet,
                                pk_date_utils.get_timestamp_str(i_lang,
                                                                i_prof,
                                                                decode(edr.flg_status,
                                                                       g_flg_diet_status_s,
                                                                       edr.dt_cancel,
                                                                       g_flg_diet_status_c,
                                                                       edr.dt_cancel,
                                                                       edr.dt_creation),
                                                                NULL) dt_creation_food,
                                ds.rank,
                                ds.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                l_schedule schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, edd.dt_diet_schedule, i_prof) meal_hour,
                                decode(edr.id_diet_type, g_diet_type_inst, l_type_food, l_food) food_title,
                                pk_utils.query_to_string('SELECT  pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) ||
                                    decode(' ||
                                                         edr.id_diet_type || ',' || g_diet_type_inst || ',
                                           NULL,
                                           '', '' || edd2.quantity ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                           decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                               FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                              WHERE edd2.id_diet = d.id_diet
                                AND edd2.id_epis_diet_req = ' ||
                                                         edd.id_epis_diet_req || '
                                AND edd2.id_diet_schedule = ' ||
                                                         edd.id_diet_schedule || '
                                AND edd2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                         '<BR>') lst_food
                  FROM epis_diet_req edr
                 INNER JOIN epis_diet_det edd
                    ON edr.id_epis_diet_req = edd.id_epis_diet_req
                 INNER JOIN diet_schedule ds
                    ON edd.id_diet_schedule = ds.id_diet_schedule
                 INNER JOIN episode epis
                    ON edr.id_episode = epis.id_episode
                 WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                   AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                   AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                   AND edr.id_epis_diet_req = i_id_diet
                   AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND nvl(l_end_date, edr.dt_creation)
                   AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                       edr.flg_status NOT IN (g_flg_diet_status_c)) OR
                       (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                       i_flg_report = pk_alert_constant.g_no)))
                
                 ORDER BY dt_creation_food DESC, rank ASC;
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
                                              'GET_DIET_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet_register);
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_food);
            RETURN FALSE;
        
    END get_diet_summary;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_diet               ID diet (For pre-defined diet tools menu)
    * @param i_flg_type              Type of summary - H History, E - Episode
    *
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/

    FUNCTION get_diet_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN NUMBER,
        i_flg_type      IN VARCHAR2 DEFAULT 'H',
        o_diet_register OUT pk_types.cursor_type,
        o_diet          OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_type  episode.id_epis_type%TYPE;
        l_flg_action VARCHAR2(1);
    
    BEGIN
    
        BEGIN
            SELECT e.id_epis_type
              INTO l_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_epis_type := NULL;
        END;
    
        l_flg_action := g_yes;
    
        g_error := 'CALL GET_DIET_SUMMARY_TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT get_diet_summary_type(i_lang            => i_lang,
                                     i_prof            => i_prof,
                                     i_scope           => i_episode,
                                     i_flg_scope       => pk_alert_constant.g_scope_type_episode,
                                     i_start_date      => NULL,
                                     i_end_date        => NULL,
                                     i_cancelled       => pk_alert_constant.g_yes,
                                     i_crit_type       => g_diet_crit_type_all_a,
                                     i_flg_report      => pk_alert_constant.g_no,
                                     i_current_episode => i_episode,
                                     i_id_diet         => i_id_diet,
                                     i_flg_type        => i_flg_type,
                                     i_flg_epis_type   => l_flg_action,
                                     o_diet_register   => o_diet_register,
                                     o_diet            => o_diet,
                                     o_diet_food       => o_diet_food,
                                     o_error           => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_DIET_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet_register);
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_food);
            RETURN FALSE;
        
    END get_diet_summary;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param I_LANG                  Language ID
    * @param I_PROF                  Professional's details    
    * @param I_SCOPE                 Scope ID
    *                                    E-Episode ID
    *                                    V-Visit ID
    *                                    P-Patient ID
    * @param I_FLG_SCOPE             Scope type
    *                                    E-Episode
    *                                    V-Visit
    *                                    P-Patient
    * @param I_START_DATE            Start date for temporal filtering
    * @param I_END_DATE              End date for temporal filtering
    * @param I_CANCELLED             Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param I_CRIT_TYPE             Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...) 
    * @param I_FLG_REPORT            Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param I_CURRENT_EPISODE       Current Episode Identifier
    * @param I_ID_DIET               ID diet (For pre-defined diet tools menu)
    * @param I_FLG_TYPE              Type of summary - H History, E - Episode
    * @param I_FLG_EPIS_TYPE         If INP or EDIS Episode receives 'Y' otherwise 'N'
    *
    * @param O_DIET_REGISTER         Cursor with the name of diet and the register
    * @param O_DIET                  Cursor with the description of diet 
    * @param O_DIET_FOOD             Cursor with de detail of diet
    * @param O_ERROR                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/03
    **********************************************************************************************/
    FUNCTION get_diet_summary_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_flg_scope       IN VARCHAR2,
        i_start_date      IN VARCHAR2,
        i_end_date        IN VARCHAR2,
        i_cancelled       IN VARCHAR2,
        i_crit_type       IN VARCHAR2,
        i_flg_report      IN VARCHAR2,
        i_current_episode IN episode.id_episode%TYPE,
        i_id_diet         IN NUMBER,
        i_flg_type        IN VARCHAR2 DEFAULT 'H',
        i_flg_epis_type   IN VARCHAR2,
        o_diet_register   OUT pk_types.cursor_type,
        o_diet            OUT pk_types.cursor_type,
        o_diet_food       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_type      sys_message.desc_message%TYPE;
        l_diet_name      sys_message.desc_message%TYPE;
        l_diet_inst_name sys_message.desc_message%TYPE;
        l_dt_inicio      sys_message.desc_message%TYPE;
        l_dt_end         sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_plan           sys_message.desc_message%TYPE;
        l_help           sys_message.desc_message%TYPE;
        l_schedule       sys_message.desc_message%TYPE;
        l_food           sys_message.desc_message%TYPE;
        l_type_food      sys_message.desc_message%TYPE;
        l_institution    sys_message.desc_message%TYPE;
        l_diet_state     sys_message.desc_message%TYPE;
        l_title          VARCHAR2(4000);
    
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        e_invalid_argument EXCEPTION;
    
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        --convert string to date format
        IF i_start_date IS NOT NULL
        THEN
            l_start_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_start_date, NULL);
        END IF;
        IF i_end_date IS NOT NULL
        THEN
            l_end_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_end_date, NULL);
        END IF;
    
        pk_alertlog.log_debug('PARAMS[:i_flg_type:' || i_flg_type || ']', g_package_name, 'GET_DIET_SUMMARY');
    
        g_sysdate_tstz   := current_timestamp;
        l_diet_type      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T048');
        l_diet_name      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T049');
        l_diet_inst_name := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T137');
        l_dt_inicio      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T050');
        l_dt_end         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T051');
        l_notes          := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T045');
        l_plan           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T068');
        l_help           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T053');
        l_schedule       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T029') || ':';
        l_food           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T046');
        l_type_food      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T069');
        l_institution    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T070');
    
        l_diet_state := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T084');
    
        IF i_id_diet IS NULL -- details of diets of patient
        THEN
            g_error := 'OPEN CURSOR O_DIET_REGISTER (patient)';
            -- PROFESSIONAL THAT REGISTER THE DIET
            OPEN o_diet_register FOR
                SELECT id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_action, i_prof) dt_register,
                       id_professional,
                       nick_name,
                       desc_speciality,
                       flg_status_bd,
                       flg_status,
                       flg_current_episode,
                       flg_detail,
                       id_diet_type,
                       desc_diet_title,
                       desc_diet,
                       decode(id_diet_type, g_diet_type_inst, i_flg_epis_type, g_yes) flg_action,
                       decode(id_diet_type,
                              g_diet_type_inst,
                              decode(i_flg_epis_type,
                                     g_yes,
                                     decode(flg_status,
                                            g_flg_diet_status_a,
                                            i_flg_epis_type,
                                            g_flg_diet_status_h,
                                            i_flg_epis_type,
                                            g_no)),
                              decode(flg_status, g_flg_diet_status_a, g_yes, g_flg_diet_status_h, g_yes, g_no)) flg_cancel
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_i,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               edr.id_professional,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      g_flg_diet_status_i,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional)) nick_name,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      g_flg_diet_status_i,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_professional,
                                                                       edr.dt_creation,
                                                                       NULL)) desc_speciality,
                               edr.flg_status flg_status_bd,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_f) flg_status,
                               decode(edr.id_episode, i_current_episode, g_yes, g_no) flg_current_episode,
                               g_yes flg_detail,
                               edr.id_diet_type,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_translation.get_translation(i_lang, dt.code_diet_type),
                                      htf.escape_sc(edr.desc_diet)) desc_diet_title,
                               htf.escape_sc(desc_diet) desc_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      3,
                                      g_flg_diet_status_i,
                                      3,
                                      g_flg_diet_status_c,
                                      5,
                                      decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                             'G',
                                             2,
                                             decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                                    'L',
                                                    4,
                                                    1))) rank
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o, g_flg_diet_status_c)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no)
                               
                               AND edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o)
                               
                               ))
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM epis_diet_req e
                                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                           AND ((i_flg_type = 'E' AND edr.id_episode = i_current_episode) OR i_flg_type = 'H'))
                 ORDER BY rank, dt_action DESC;
        
            -- DETAIL OF DIET
            g_error := 'OPEN CURSOR O_DIET (patient)';
            OPEN o_diet FOR
                SELECT id_diet,
                       diet_status_title,
                       diet_status,
                       diet_type_title,
                       desc_diet_type,
                       diet_name_title,
                       diet_name,
                       dt_initial_title,
                       dt_initial,
                       decode(dt_end, NULL, NULL, dt_end_title) dt_end_title,
                       dt_end,
                       notes_title,
                       notes,
                       food_plan_title,
                       food_plan,
                       decode(desc_help, NULL, NULL, desc_help_title) desc_help_title,
                       desc_help,
                       flg_help,
                       desc_institution_title,
                       desc_institution,
                       flg_institution
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_i,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               l_diet_state diet_status_title,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req) diet_status,
                               l_diet_type diet_type_title,
                               pk_translation.get_translation(i_lang, dt.code_diet_type) desc_diet_type,
                               decode(edr.id_diet_type, g_diet_type_inst, l_diet_inst_name, l_diet_name) diet_name_title,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_diet.get_diet_title(i_lang, i_prof, edr.id_epis_diet_req),
                                      htf.escape_sc(edr.desc_diet)) diet_name,
                               l_dt_inicio dt_initial_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                               l_dt_end dt_end_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software) dt_end,
                               l_notes notes_title,
                               htf.escape_sc(edr.notes) notes,
                               decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan) food_plan_title,
                               edr.food_plan || decode(edr.food_plan,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                          FROM unit_measure um
                                                         WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                               l_help desc_help_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                               edr.flg_help,
                               decode(edr.flg_institution, NULL, NULL, l_institution) desc_institution_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution,
                               edr.flg_institution
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o, g_flg_diet_status_c)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o)))
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM epis_diet_req e
                                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                           AND ((i_flg_type = 'E' AND edr.id_episode = i_current_episode) OR i_flg_type = 'H'))
                 ORDER BY dt_action DESC;
            g_error := 'OPEN CURSOR O_DIET_FOOD (patient)';
            -- cursor with the detail of diet
        
            -- gets the food
            OPEN o_diet_food FOR
                SELECT DISTINCT edr.id_epis_diet_req id_diet,
                                pk_date_utils.get_timestamp_str(i_lang,
                                                                i_prof,
                                                                decode(edr.flg_status,
                                                                       g_flg_diet_status_s,
                                                                       edr.dt_cancel,
                                                                       g_flg_diet_status_c,
                                                                       edr.dt_cancel,
                                                                       edr.dt_creation),
                                                                NULL) dt_creation_food,
                                ds.rank,
                                ds.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                l_schedule schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, edd.dt_diet_schedule, i_prof) meal_hour,
                                decode(edr.id_diet_type, g_diet_type_inst, l_type_food, l_food) food_title,
                                pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) ||
                                    decode(' ||
                                                         edr.id_diet_type || ',' || g_diet_type_inst || ',
                                           NULL,
                                           '', '' || edd2.quantity ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                           decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                               FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                              WHERE edd2.id_diet = d.id_diet
                                AND edd2.id_epis_diet_req = ' ||
                                                         edd.id_epis_diet_req || '
                                AND edd2.id_diet_schedule = ' ||
                                                         edd.id_diet_schedule || '
                                AND edd2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                         '<BR>') lst_food
                  FROM epis_diet_req edr
                 INNER JOIN epis_diet_det edd
                    ON edr.id_epis_diet_req = edd.id_epis_diet_req
                 INNER JOIN diet_schedule ds
                    ON edd.id_diet_schedule = ds.id_diet_schedule
                 INNER JOIN episode epis
                    ON edr.id_episode = epis.id_episode
                 WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                   AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                   AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                   AND edd.id_diet_schedule <> g_diet_title
                   AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND nvl(l_end_date, edr.dt_creation)
                   AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                       edr.flg_status NOT IN (g_flg_diet_status_c)) OR
                       ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                       i_flg_report = pk_alert_constant.g_no))
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epis_diet_req e
                         WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                   AND ((i_flg_type = 'E' AND edr.id_episode = i_current_episode) OR i_flg_type = 'H')
                 ORDER BY dt_creation_food DESC, rank ASC;
        ELSE
            g_error := 'OPEN CURSOR O_DIET_REGISTER (patient)';
            -- PROFESSIONAL THAT REGISTER THE DIET
            OPEN o_diet_register FOR
                SELECT id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_action, i_prof) dt_register,
                       id_professional,
                       nick_name,
                       desc_speciality,
                       flg_status_bd,
                       flg_status,
                       flg_current_episode,
                       flg_detail,
                       id_diet_type,
                       desc_diet_title,
                       desc_diet
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               edr.id_professional,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel),
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional)) nick_name,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      g_flg_diet_status_c,
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_prof_cancel,
                                                                       edr.dt_cancel,
                                                                       NULL),
                                      pk_prof_utils.get_spec_signature(i_lang,
                                                                       i_prof,
                                                                       edr.id_professional,
                                                                       edr.dt_creation,
                                                                       NULL)) desc_speciality,
                               edr.flg_status flg_status_bd,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_f) flg_status,
                               decode(edr.id_episode, i_current_episode, g_yes, g_no) flg_current_episode,
                               g_yes flg_detail,
                               edr.id_diet_type,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_translation.get_translation(i_lang, dt.code_diet_type),
                                      htf.escape_sc(edr.desc_diet)) desc_diet_title,
                               htf.escape_sc(desc_diet) desc_diet
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_c)) OR
                               ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no))
                           AND edr.id_epis_diet_req = i_id_diet)
                 ORDER BY dt_action DESC;
        
            -- DETAIL OF DIET
            g_error := 'OPEN CURSOR O_DIET (patient)';
            OPEN o_diet FOR
                SELECT id_diet,
                       diet_status_title,
                       diet_status,
                       diet_type_title,
                       desc_diet_type,
                       diet_name_title,
                       diet_name,
                       dt_initial_title,
                       dt_initial,
                       dt_end_title,
                       dt_end,
                       notes_title,
                       notes,
                       food_plan_title,
                       food_plan,
                       desc_help_title,
                       desc_help,
                       flg_help,
                       desc_institution_title,
                       desc_institution,
                       flg_institution
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      edr.dt_cancel,
                                      g_flg_diet_status_c,
                                      edr.dt_cancel,
                                      edr.dt_creation) dt_action,
                               l_diet_state diet_status_title,
                               get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req) diet_status,
                               l_diet_type diet_type_title,
                               pk_translation.get_translation(i_lang, dt.code_diet_type) desc_diet_type,
                               decode(edr.id_diet_type, g_diet_type_inst, l_diet_inst_name, l_diet_name) diet_name_title,
                               htf.escape_sc(decode(edr.desc_diet,
                                                    NULL,
                                                    pk_diet.get_diet_title(i_lang, i_prof, edr.id_epis_diet_req),
                                                    edr.desc_diet)) diet_name,
                               l_dt_inicio dt_initial_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                               l_dt_end dt_end_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software) dt_end,
                               l_notes notes_title,
                               htf.escape_sc(edr.notes) notes,
                               decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan) food_plan_title,
                               edr.food_plan || decode(edr.food_plan,
                                                       NULL,
                                                       NULL,
                                                       (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                          FROM unit_measure um
                                                         WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                               l_help desc_help_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                               edr.flg_help,
                               decode(edr.flg_institution, NULL, NULL, l_institution) desc_institution_title,
                               pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution,
                               edr.flg_institution
                          FROM epis_diet_req edr
                         INNER JOIN diet_type dt
                            ON edr.id_diet_type = dt.id_diet_type
                         INNER JOIN episode epis
                            ON edr.id_episode = epis.id_episode
                         WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                           AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND
                               nvl(l_end_date, edr.dt_creation)
                           AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o, g_flg_diet_status_c)) OR
                               (((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                               i_flg_report = pk_alert_constant.g_no) AND
                               edr.flg_status NOT IN (g_flg_diet_status_t, g_flg_diet_status_o)))
                              
                           AND edr.id_epis_diet_req = i_id_diet)
                 ORDER BY dt_action DESC;
            g_error := 'OPEN CURSOR O_DIET_FOOD (patient)';
        
            -- gets the food
            OPEN o_diet_food FOR
                SELECT DISTINCT edr.id_epis_diet_req id_diet,
                                pk_date_utils.get_timestamp_str(i_lang,
                                                                i_prof,
                                                                decode(edr.flg_status,
                                                                       g_flg_diet_status_s,
                                                                       edr.dt_cancel,
                                                                       g_flg_diet_status_c,
                                                                       edr.dt_cancel,
                                                                       edr.dt_creation),
                                                                NULL) dt_creation_food,
                                ds.rank,
                                ds.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                l_schedule schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, edd.dt_diet_schedule, i_prof) meal_hour,
                                decode(edr.id_diet_type, g_diet_type_inst, l_type_food, l_food) food_title,
                                pk_utils.query_to_string('SELECT  pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) ||
                                    decode(' ||
                                                         edr.id_diet_type || ',' || g_diet_type_inst || ',
                                           NULL,
                                           '', '' || edd2.quantity ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                           decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                               FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                              WHERE edd2.id_diet = d.id_diet
                                AND edd2.id_epis_diet_req = ' ||
                                                         edd.id_epis_diet_req || '
                                AND edd2.id_diet_schedule = ' ||
                                                         edd.id_diet_schedule || '
                                AND edd2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                         '<BR>') lst_food
                  FROM epis_diet_req edr
                 INNER JOIN epis_diet_det edd
                    ON edr.id_epis_diet_req = edd.id_epis_diet_req
                 INNER JOIN diet_schedule ds
                    ON edd.id_diet_schedule = ds.id_diet_schedule
                 INNER JOIN episode epis
                    ON edr.id_episode = epis.id_episode
                 WHERE epis.id_episode = nvl(l_id_episode, epis.id_episode)
                   AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                   AND epis.id_patient = nvl(l_id_patient, epis.id_patient)
                   AND edd.id_diet_schedule <> g_diet_title
                   AND edr.dt_creation BETWEEN nvl(l_start_date, edr.dt_creation) AND nvl(l_end_date, edr.dt_creation)
                   AND ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_no AND
                       edr.flg_status NOT IN (g_flg_diet_status_c)) OR
                       ((i_flg_report = pk_alert_constant.g_yes AND i_cancelled = pk_alert_constant.g_yes) OR
                       i_flg_report = pk_alert_constant.g_no))
                   AND edr.id_epis_diet_req = i_id_diet
                 ORDER BY dt_creation_food DESC, rank ASC;
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
                                              'GET_DIET_SUMMARY_INT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet_register);
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_food);
            RETURN FALSE;
        
    END get_diet_summary_type;

    /**********************************************************************************************
    * Gets the summary of the diets of this patient
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient (from tools this is null)
    * @param i_episode               ID Episode
    * @param i_id_diet               ID DIET
    * @param o_diet_register         Cursor with the name of diet and the register
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_food             Cursor with de detail of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/06
    **********************************************************************************************/

    FUNCTION get_diet_summary_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_id_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        o_diet_register OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_type      sys_message.desc_message%TYPE;
        l_diet_name      sys_message.desc_message%TYPE;
        l_diet_inst_name sys_message.desc_message%TYPE;
        l_dt_inicio      sys_message.desc_message%TYPE;
        l_dt_end         sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_plan           sys_message.desc_message%TYPE;
        l_help           sys_message.desc_message%TYPE;
        l_schedule       sys_message.desc_message%TYPE;
        l_food           sys_message.desc_message%TYPE;
        l_type_food      sys_message.desc_message%TYPE;
        l_institution    sys_message.desc_message%TYPE;
        l_notes_cancel   sys_message.desc_message%TYPE;
        l_edited         sys_message.desc_message%TYPE;
        l_resume         sys_message.desc_message%TYPE;
        l_created        sys_message.desc_message%TYPE;
        l_interrupted    sys_message.desc_message%TYPE;
        l_share          sys_message.desc_message%TYPE;
        l_desc_interrupt sys_message.desc_message%TYPE;
        l_prescribed     sys_message.desc_message%TYPE;
        l_diet_active    sys_message.desc_message%TYPE;
        l_diet_inactive  sys_message.desc_message%TYPE;
        l_diet_completed sys_message.desc_message%TYPE;
        l_diet_state     sys_message.desc_message%TYPE;
        l_canceled       sys_message.desc_message%TYPE;
        l_draft          sys_message.desc_message%TYPE;
        l_expired        sys_message.desc_message%TYPE;
        l_completed      sys_message.desc_message%TYPE;
        l_diet_descont   sys_message.desc_message%TYPE;
        l_descont_title  sys_message.desc_message%TYPE;
    
        l_id_prof_alert sys_config.value%TYPE;
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet:' || i_id_diet || ']', g_package_name, 'GET_DIET_SUMMARY_DET');
    
        l_diet_type      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T048');
        l_diet_name      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T049');
        l_diet_inst_name := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T137');
        l_dt_inicio      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T050');
        l_dt_end         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T051');
        l_notes          := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T045');
        l_plan           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T068');
        l_help           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T053');
        l_schedule       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T029') || ':';
        l_food           := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T046');
        l_type_food      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T069');
        l_institution    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T070');
        l_notes_cancel   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T085');
        l_desc_interrupt := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_M014');
        l_edited         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T054');
        l_interrupted    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T056');
        l_created        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T055');
        l_resume         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T057');
        l_share          := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T073');
        l_prescribed     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T079');
        l_canceled       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T090');
        l_draft          := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T110');
        l_expired        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T111');
        l_completed      := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T138');
    
        l_diet_active    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T086');
        l_diet_inactive  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T087');
        l_diet_completed := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T088');
        l_diet_state     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T084');
        l_diet_descont   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T139');
        l_descont_title  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T140');
    
        l_id_prof_alert := pk_sysconfig.get_config(i_code_cf => 'ID_PROF_ALERT', i_prof => i_prof);
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'OPEN CURSOR O_DIET_REGISTER';
    
        IF i_patient IS NOT NULL
        THEN
        
            OPEN o_diet_register FOR
                SELECT id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_tstz, i_prof) dt_register,
                       pk_date_utils.get_timestamp_str(i_lang, i_prof, dt_tstz, NULL) dt_register_ts,
                       id_professional,
                       nick_name,
                       desc_speciality,
                       flg_show_info,
                       flg_status,
                       desc_diet_title,
                       decode(diet_status, NULL, NULL, l_diet_state) diet_status_title,
                       diet_status,
                       decode(desc_diet_type, NULL, NULL, diet_type_title) diet_type_title,
                       desc_diet_type,
                       decode(diet_name, NULL, NULL, diet_name_title) diet_name_title,
                       diet_name,
                       decode(dt_initial, NULL, NULL, dt_initial_title) dt_initial_title,
                       dt_initial,
                       decode(dt_end, NULL, NULL, dt_end_title) dt_end_title,
                       dt_end,
                       decode(notes, NULL, NULL, notes_title) notes_title,
                       notes,
                       decode(food_plan, NULL, NULL, food_plan_title) food_plan_title,
                       food_plan,
                       decode(desc_help, NULL, NULL, desc_help_title) desc_help_title,
                       desc_help,
                       decode(desc_institution, NULL, NULL, desc_institution_title) desc_institution_title,
                       desc_institution,
                       decode(desc_share, NULL, NULL, flg_share_title) flg_share_title,
                       desc_share,
                       decode(reason_cancel, NULL, NULL, reason_cancel_title) reason_cancel_title,
                       reason_cancel,
                       decode(notes_cancel, NULL, NULL, notes_cancel_diet_title) notes_cancel_diet_title,
                       notes_cancel,
                       flg_institution,
                       flg_help
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               edr.dt_creation dt_tstz,
                               decode((SELECT COUNT(1)
                                        FROM epis_diet_req edr2
                                       WHERE edr2.id_epis_diet_req_parent = edr.id_epis_diet_req),
                                      0,
                                      decode(edr.flg_status,
                                             g_flg_diet_status_s,
                                             NULL,
                                             g_flg_diet_status_c,
                                             NULL,
                                             pk_diet.get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req)),
                                      NULL) diet_status,
                               edr.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_professional) nick_name,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                edr.id_professional,
                                                                edr.dt_creation,
                                                                NULL) desc_speciality,
                               decode(edr1.flg_status, g_flg_diet_status_s, g_no, g_yes) flg_show_info,
                               decode(edr.flg_status, g_flg_diet_status_c, g_flg_diet_status_r, edr.flg_status) flg_status,
                               decode(edr.id_epis_diet_req_parent,
                                      NULL,
                                      decode(edr.flg_status, g_flg_diet_status_t, l_draft, l_prescribed),
                                      decode(edr.flg_status,
                                             g_flg_diet_status_x,
                                             l_expired,
                                             decode(edr1.flg_status,
                                                    g_flg_diet_status_t,
                                                    decode(edr.flg_status, g_flg_diet_status_t, l_edited, l_prescribed),
                                                    g_flg_diet_status_s,
                                                    l_resume,
                                                    g_flg_diet_status_r,
                                                    l_edited,
                                                    g_flg_diet_status_f,
                                                    l_completed,
                                                    l_interrupted))) desc_diet_title,
                               decode(edr1.flg_status, g_flg_diet_status_s, NULL, l_diet_type) diet_type_title,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      pk_translation.get_translation(i_lang, dt.code_diet_type)) desc_diet_type,
                               decode(edr1.flg_status, g_flg_diet_status_s, NULL, l_diet_inst_name) diet_name_title,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      g_flg_diet_status_i,
                                      NULL,
                                      decode(edr.id_diet_type,
                                             g_diet_type_inst,
                                             pk_diet.get_diet_title(i_lang, i_prof, edr.id_epis_diet_req),
                                             htf.escape_sc(edr.desc_diet))) diet_name,
                               l_dt_inicio dt_initial_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                               l_dt_end dt_end_title,
                               pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software) dt_end,
                               l_notes notes_title,
                               htf.escape_sc(decode(edr1.flg_status, g_flg_diet_status_s, edr.resume_notes, edr.notes)) notes,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      g_flg_diet_status_i,
                                      NULL,
                                      decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan)) food_plan_title,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      g_flg_diet_status_i,
                                      NULL,
                                      edr.food_plan ||
                                      decode(edr.food_plan,
                                             NULL,
                                             NULL,
                                             (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                FROM unit_measure um
                                               WHERE id_unit_measure = g_id_unit_kcal))) food_plan,
                               decode(edr1.flg_status, g_flg_diet_status_s, NULL, l_help) desc_help_title,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang)) desc_help,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      decode(edr.flg_institution, NULL, NULL, l_institution)) desc_institution_title,
                               decode(edr1.flg_status,
                                      g_flg_diet_status_s,
                                      NULL,
                                      pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang)) desc_institution,
                               NULL flg_share_title,
                               NULL desc_share,
                               NULL reason_cancel_title,
                               NULL reason_cancel,
                               NULL notes_cancel_diet_title,
                               NULL notes_cancel,
                               edr.flg_institution,
                               edr.flg_help
                          FROM epis_diet_req edr, diet_type dt, epis_diet_req edr1
                         WHERE edr.id_patient = i_patient
                           AND edr.id_diet_type = dt.id_diet_type
                           AND edr1.id_epis_diet_req(+) = edr.id_epis_diet_req_parent
                           AND edr.id_epis_diet_req IN
                               (SELECT id_epis_diet_req
                                  FROM epis_diet_req edr2
                                 START WITH id_epis_diet_req = i_id_diet
                                CONNECT BY PRIOR edr2.id_epis_diet_req_parent = edr2.id_epis_diet_req)
                        UNION
                        SELECT edr.id_epis_diet_req id_diet,
                               edr.dt_cancel dt_tstz,
                               decode(edr.flg_status,
                                      g_flg_diet_status_c,
                                      pk_diet.get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req),
                                      g_flg_diet_status_s,
                                      decode((SELECT COUNT(1)
                                               FROM epis_diet_req edr2
                                              WHERE edr2.id_epis_diet_req_parent = edr.id_epis_diet_req),
                                             0,
                                             pk_diet.get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req),
                                             NULL)) diet_status,
                               edr.id_professional,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, edr.id_prof_cancel) nick_name,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                edr.id_prof_cancel,
                                                                edr.dt_creation,
                                                                NULL) desc_speciality,
                               g_no flg_show_info,
                               edr.flg_status,
                               decode(flg_status,
                                      g_flg_diet_status_c,
                                      l_canceled,
                                      g_flg_diet_status_i,
                                      l_diet_descont,
                                      l_interrupted) desc_diet_title,
                               NULL diet_type_title,
                               NULL desc_diet_type,
                               NULL diet_name_title,
                               NULL diet_name,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      l_dt_inicio,
                                      g_flg_diet_status_i,
                                      l_dt_inicio,
                                      NULL) dt_initial_title,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_date_utils.date_char_tsz(i_lang,
                                                                  edr.dt_initial_suspend,
                                                                  i_prof.institution,
                                                                  i_prof.software),
                                      NULL) dt_initial,
                               decode(edr.flg_status, g_flg_diet_status_s, l_dt_end, g_flg_diet_status_i, l_dt_end, NULL) dt_end_title,
                               decode(edr.flg_status,
                                      g_flg_diet_status_s,
                                      pk_date_utils.dt_chr_tsz(i_lang, edr.dt_end_suspend, i_prof),
                                      NULL) dt_end,
                               NULL notes_title,
                               NULL notes,
                               NULL food_plan_title,
                               NULL food_plan,
                               NULL desc_help_title,
                               NULL desc_help,
                               NULL desc_institution_title,
                               NULL desc_institution,
                               NULL flg_share_title,
                               NULL desc_share,
                               decode(edr.flg_status, g_flg_diet_status_i, l_descont_title, l_notes_cancel) reason_cancel_title,
                               decode(edr.id_cancel_reason,
                                      NULL,
                                      NULL,
                                      (SELECT pk_translation.get_translation(i_lang, cr.code_cancel_reason)
                                         FROM cancel_reason cr
                                        WHERE cr.id_cancel_reason = edr.id_cancel_reason)) cancel_reason,
                               l_notes notes_cancel_diet_title,
                               decode(edr.id_prof_cancel,
                                      l_id_prof_alert,
                                      pk_message.get_message(i_lang, 'DIET_M014'),
                                      edr.notes_cancel) notes_cancel,
                               edr.flg_institution,
                               edr.flg_help
                          FROM epis_diet_req edr, diet_type dt
                         WHERE edr.id_patient = i_patient
                           AND edr.id_diet_type = dt.id_diet_type
                           AND edr.flg_status IN (g_flg_diet_status_s, g_flg_diet_status_c, g_flg_diet_status_i)
                           AND edr.id_epis_diet_req IN
                               (SELECT id_epis_diet_req
                                  FROM epis_diet_req edr2
                                 START WITH id_epis_diet_req = i_id_diet
                                CONNECT BY PRIOR edr2.id_epis_diet_req_parent = edr2.id_epis_diet_req))
                 ORDER BY dt_tstz DESC;
        
            g_error := 'OPEN CURSOR O_DIET_FOOD';
            -- cursor with the detail of diet
            OPEN o_diet_food FOR
                SELECT DISTINCT edr.id_epis_diet_req id_diet,
                                pk_date_utils.get_timestamp_str(i_lang, i_prof, edr.dt_creation, NULL) dt_creation_food,
                                rank,
                                edd.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                decode(edd.dt_diet_schedule, NULL, NULL, l_schedule) schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, edd.dt_diet_schedule, i_prof) meal_hour,
                                decode(edr.id_diet_type, g_diet_type_inst, l_type_food, l_food) food_title,
                                pk_utils.query_to_string('SELECT  pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) ||
                                decode(' || edr.id_diet_type || ',' ||
                                                         g_diet_type_inst || ',
                                       NULL,
                                       '', '' || edd2.quantity ||
                                       pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) 
                                                         || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                       decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                           FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                          WHERE edd2.id_diet = d.id_diet
                            AND edd2.id_epis_diet_req = ' ||
                                                         edd.id_epis_diet_req || '
                            AND edd2.id_diet_schedule = ' ||
                                                         edd.id_diet_schedule || '
                            AND edd2.id_unit_measure = um.id_unit_measure(+)
                             AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                          ORDER BY food',
                                                         '<BR>') lst_food
                  FROM epis_diet_req edr, epis_diet_det edd, diet_schedule ds
                 WHERE edr.id_patient = i_patient
                   AND edd.id_diet_schedule = ds.id_diet_schedule
                   AND edd.id_diet_schedule <> g_diet_title
                   AND edr.id_epis_diet_req = edd.id_epis_diet_req
                   AND edr.id_epis_diet_req IN
                       (SELECT id_epis_diet_req
                          FROM epis_diet_req edr2
                         START WITH id_epis_diet_req = i_id_diet
                        CONNECT BY PRIOR edr2.id_epis_diet_req_parent = edr2.id_epis_diet_req)
                
                 ORDER BY edr.id_epis_diet_req DESC, rank ASC;
        ELSE
            -- detail of a pre-defined diet
            g_error := 'OPEN CURSOR O_DIET_REGISTER (pre-defined diet)';
            OPEN o_diet_register FOR
            
                SELECT dpi.id_diet_prof_instit id_diet,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dpi.dt_creation, i_prof) dt_register,
                       dpi.id_prof_create id_professional,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, dpi.id_prof_create) nick_name,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, dpi.id_prof_create, dpi.dt_creation, NULL) desc_speciality,
                       g_yes flg_show_info,
                       decode(id_diet_prof_parent, NULL, l_created, l_edited) desc_diet_title,
                       NULL diet_status_title,
                       NULL diet_status,
                       l_diet_type diet_type_title,
                       (SELECT pk_translation.get_translation(i_lang, code_diet_type)
                          FROM diet_type
                         WHERE id_diet_type = g_diet_type_defi) desc_diet_type,
                       l_diet_name diet_name_title,
                       htf.escape_sc(dpi.desc_diet) diet_name,
                       NULL dt_initial_title,
                       NULL dt_initial,
                       NULL dt_end_title,
                       NULL dt_end,
                       decode(dpi.notes, NULL, NULL, l_notes) notes_title,
                       htf.escape_sc(dpi.notes) notes,
                       l_plan food_plan_title,
                       dpi.food_plan || decode(dpi.food_plan,
                                               NULL,
                                               NULL,
                                               (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                  FROM unit_measure um
                                                 WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                       NULL desc_help_title,
                       NULL desc_help,
                       NULL desc_institution_title,
                       NULL desc_institution,
                       l_share flg_share_title,
                       pk_sysdomain.get_domain(g_yes_no, dpi.flg_share, i_lang) desc_share,
                       NULL reason_cancel_title,
                       NULL reason_cancel,
                       NULL notes_cancel_diet_title,
                       NULL notes_cancel
                  FROM diet_prof_instit dpi
                 WHERE dpi.id_diet_prof_instit IN
                       (SELECT dpi3.id_diet_prof_instit
                          FROM diet_prof_instit dpi3
                         START WITH dpi3.id_diet_prof_instit = i_id_diet
                        CONNECT BY dpi3.id_diet_prof_instit = PRIOR dpi3.id_diet_prof_parent)
                 ORDER BY dpi.dt_creation DESC;
        
            g_error := 'OPEN CURSOR O_DIET (pre-defined diet)';
        
            OPEN o_diet_food FOR
                SELECT DISTINCT dpi.id_diet_prof_instit id_diet,
                                pk_date_utils.get_timestamp_str(i_lang, i_prof, dpi.dt_creation, NULL) dt_creation_food,
                                ds.rank,
                                ds.id_diet_schedule,
                                pk_translation.get_translation(i_lang, ds.code_diet_schedule) desc_meal,
                                l_schedule schedule_title,
                                pk_date_utils.dt_chr_hour_tsz(i_lang, dpid.dt_diet_schedule, i_prof) meal_hour,
                                l_food food_title,
                                pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                         ', d.code_diet) || '', '' || dpid2.quantity ||
                                    pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', um.code_unit_measure) || ''; '' ||
                                    pk_diet.get_food_energy(dpid2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                    pk_translation.get_translation(' ||
                                                         i_lang ||
                                                         ', ume.code_unit_measure) ||
                                    decode(dpid2.notes, NULL, ''.'', ''; '') || dpid2.notes food
                               FROM diet_prof_instit_det dpid2, diet d, unit_measure um, unit_measure ume
                              WHERE dpid2.id_diet = d.id_diet
                                AND dpid2.id_diet_prof_instit = ' ||
                                                         dpid.id_diet_prof_instit || '
                                AND dpid2.id_diet_schedule = ' ||
                                                         dpid.id_diet_schedule || '
                                AND dpid2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                         '<BR>') lst_food
                  FROM diet_prof_instit dpi, diet_prof_instit_det dpid, diet_schedule ds
                 WHERE dpi.id_diet_prof_instit IN
                       (SELECT dpi3.id_diet_prof_instit
                          FROM diet_prof_instit dpi3
                         START WITH dpi3.id_diet_prof_instit = i_id_diet
                        CONNECT BY dpi3.id_diet_prof_instit = PRIOR dpi3.id_diet_prof_parent)
                   AND dpid.id_diet_schedule = ds.id_diet_schedule
                   AND dpi.id_diet_prof_instit = dpid.id_diet_prof_instit
                 ORDER BY dpi.id_diet_prof_instit DESC, ds.rank ASC;
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
                                              'GET_DIET_SUMMARY_DET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet_register);
            pk_types.open_my_cursor(o_diet_food);
            RETURN FALSE;
        
    END get_diet_summary_det;

    /**********************************************************************************************
    * Gets the scheduled hour of meals in the institution
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param o_schedule              Cursor with the meal hour
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/07
    **********************************************************************************************/
    FUNCTION get_schedule_default_time
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_schedule OUT pk_types.cursor_type,
        o_error    OUT t_error_out
        
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('GET_SCHEDULE_DEFAULT_TIME', g_package_name);
    
        g_error := 'GET CURSOR O_SCHEDULE';
        OPEN o_schedule FOR
            SELECT des.id_diet_schedule,
                   des.rank,
                   pk_date_utils.to_char_insttimezone(i_prof, dest.dt_schedule, 'YYYYMMDDHH24MISS') meal_hour
              FROM diet_schedule des, diet_schedule_time dest
             WHERE des.id_diet_schedule = dest.id_diet_schedule(+)
               AND nvl(dest.id_institution, 0) IN (0, i_prof.institution)
               AND nvl(dest.id_software, 0) IN (0, i_prof.software)
               AND nvl(dest.flg_available, g_flg_available) = g_flg_available
               AND nvl(des.flg_available, g_flg_available) = g_flg_available
             ORDER BY des.rank;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SCHEDULE_DEFAULT_TIME',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_schedule);
            RETURN FALSE;
        
    END get_schedule_default_time;

    /**********************************************************************************************
    * Cancels a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be canceled
    * @param i_notes                 Cancel Notes 
    * @param i_reason                ID Reason for cancelation
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/08
    **********************************************************************************************/

    FUNCTION cancel_diet
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_diet     IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes       IN epis_diet_req.notes_cancel%TYPE,
        i_reason      IN epis_diet_req.id_cancel_reason%TYPE,
        i_auto_cancel IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode  episode.id_episode%TYPE;
        l_id_patient  episode.id_patient%TYPE;
        l_epis_type   episode.id_epis_type%TYPE;
        l_active_diet VARCHAR2(4000);
        l_rows        table_varchar;
        l_flg_status  epis_diet_req.flg_status%TYPE;
    
        l_epis_diet_det table_number;
    
        CURSOR c_diet_episode(v_sysdate_tstz epis_diet_req.dt_inicial%TYPE) IS
            SELECT id_episode,
                   id_patient,
                   decode(edr.flg_status,
                          g_flg_diet_status_s,
                          g_flg_diet_status_s,
                          g_flg_diet_status_c,
                          g_flg_diet_status_c,
                          g_flg_diet_status_x,
                          g_flg_diet_status_x,
                          g_flg_diet_status_t,
                          g_flg_diet_status_t,
                          g_flg_diet_status_o,
                          g_flg_diet_status_o,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, v_sysdate_tstz),
                                 g_flg_date_g,
                                 g_flg_diet_status_h,
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, v_sysdate_tstz),
                                        g_flg_date_l,
                                        g_flg_diet_status_f,
                                        g_flg_diet_status_a))) flg_status
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_id_diet;
    
        CURSOR c_episode_type IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = l_id_episode;
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet:' || i_id_diet || ' :i_reason:' || i_reason || ']',
                              g_package_name,
                              'CANCEL_DIET');
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_diet_episode';
        OPEN c_diet_episode(g_sysdate_tstz);
        FETCH c_diet_episode
            INTO l_id_episode, l_id_patient, l_flg_status;
        CLOSE c_diet_episode;
    
        -- se for temporaria pode ser apagada
        IF l_flg_status = g_flg_diet_status_o
        THEN
        
            SELECT epd.id_epis_diet_det
              BULK COLLECT
              INTO l_epis_diet_det
              FROM epis_diet_det epd
             WHERE epd.id_epis_diet_req = i_id_diet;
        
            g_error := 'Delete all details for Diet ' || i_id_diet || '. Number of detais: ' || l_epis_diet_det.count;
            --Delete all details for this Diet!
            IF l_epis_diet_det.count > 0
            THEN
                FOR j IN l_epis_diet_det.first .. l_epis_diet_det.last
                LOOP
                    ts_epis_diet_det.del(id_epis_diet_det_in => l_epis_diet_det(j));
                    pk_alertlog.log_debug('DELETE temporary DIET DET: :' || l_epis_diet_det(j),
                                          g_package_name,
                                          'DELETE temprorary DIET');
                
                END LOOP;
                --End of Delete all details for this Diet!
            END IF;
            --Delete the Diet
            ts_epis_diet_req.del(id_epis_diet_req_in => i_id_diet);
            pk_alertlog.log_debug('DELETE temporary DIET: Deleted temporary diet:' || i_id_diet,
                                  g_package_name,
                                  'DELETE temporary DIET');
        
        ELSIF l_flg_status NOT IN (g_flg_diet_status_c, g_flg_diet_status_f /*, g_flg_diet_status_s*/)
              OR i_auto_cancel = pk_alert_constant.g_yes
        THEN
            g_error := 'CANCEL DIET';
            ts_epis_diet_req.upd(id_epis_diet_req_in => i_id_diet,
                                 flg_status_in       => g_flg_diet_status_c,
                                 notes_cancel_in     => i_notes,
                                 dt_cancel_in        => g_sysdate_tstz,
                                 id_prof_cancel_in   => i_prof.id,
                                 id_cancel_reason_in => i_reason,
                                 rows_out            => l_rows);
        
            g_error := 'CALL TO PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error := 'OPEN c_episode_type';
            OPEN c_episode_type;
            FETCH c_episode_type
                INTO l_epis_type;
            CLOSE c_episode_type;
        
            IF l_epis_type = g_epis_type_inpt
            THEN
                g_error := 'GET GET_ACTIVE_DIET';
            
                l_active_diet := pk_diet.get_active_diet(i_lang,
                                                         i_prof,
                                                         l_id_episode,
                                                         g_flg_diet_t,
                                                         i_id_diet,
                                                         NULL,
                                                         NULL,
                                                         o_error);
                -- UPDATE THE EPISODE DIET ON EPIS_INFO
                l_rows  := table_varchar();
                g_error := 'UPDATE EPIS_INFO';
                ts_epis_info.upd(id_episode_in => l_id_episode,
                                 desc_diet_in  => l_active_diet,
                                 desc_diet_nin => FALSE,
                                 rows_out      => l_rows);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INFO',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END IF;
        END IF;
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => l_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CANCEL_DIET');
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_diet;

    FUNCTION cancel_diet_internal
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_diet IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes   IN epis_diet_req.notes_cancel%TYPE,
        i_reason  IN epis_diet_req.id_cancel_reason%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode  episode.id_episode%TYPE;
        l_id_patient  episode.id_patient%TYPE;
        l_epis_type   episode.id_epis_type%TYPE;
        l_active_diet VARCHAR2(4000);
        l_rows        table_varchar;
        l_flg_status  epis_diet_req.flg_status%TYPE;
    
        l_epis_diet_det table_number;
    
        CURSOR c_diet_episode(v_sysdate_tstz epis_diet_req.dt_inicial%TYPE) IS
            SELECT id_episode,
                   id_patient,
                   decode(edr.flg_status,
                          g_flg_diet_status_s,
                          g_flg_diet_status_s,
                          g_flg_diet_status_c,
                          g_flg_diet_status_c,
                          g_flg_diet_status_x,
                          g_flg_diet_status_x,
                          g_flg_diet_status_t,
                          g_flg_diet_status_t,
                          g_flg_diet_status_o,
                          g_flg_diet_status_o,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, v_sysdate_tstz),
                                 g_flg_date_g,
                                 g_flg_diet_status_h,
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, v_sysdate_tstz),
                                        g_flg_date_l,
                                        g_flg_diet_status_f,
                                        g_flg_diet_status_a))) flg_status
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_id_diet;
    
        CURSOR c_episode_type IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = l_id_episode;
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet:' || i_id_diet || ' :i_reason:' || i_reason || ']',
                              g_package_name,
                              'CANCEL_DIET');
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN c_diet_episode';
        OPEN c_diet_episode(g_sysdate_tstz);
        FETCH c_diet_episode
            INTO l_id_episode, l_id_patient, l_flg_status;
        CLOSE c_diet_episode;
    
        -- se for temporaria pode ser apagada
        IF l_flg_status = g_flg_diet_status_o
        THEN
        
            SELECT epd.id_epis_diet_det
              BULK COLLECT
              INTO l_epis_diet_det
              FROM epis_diet_det epd
             WHERE epd.id_epis_diet_req = i_id_diet;
        
            g_error := 'Delete all details for Diet ' || i_id_diet || '. Number of detais: ' || l_epis_diet_det.count;
            --Delete all details for this Diet!
            IF l_epis_diet_det.count > 0
            THEN
                FOR j IN l_epis_diet_det.first .. l_epis_diet_det.last
                LOOP
                    ts_epis_diet_det.del(id_epis_diet_det_in => l_epis_diet_det(j));
                    pk_alertlog.log_debug('DELETE temporary DIET DET: :' || l_epis_diet_det(j),
                                          g_package_name,
                                          'DELETE temprorary DIET');
                
                END LOOP;
                --End of Delete all details for this Diet!
            END IF;
            --Delete the Diet
            ts_epis_diet_req.del(id_epis_diet_req_in => i_id_diet);
            pk_alertlog.log_debug('DELETE temporary DIET: Deleted temporary diet:' || i_id_diet,
                                  g_package_name,
                                  'DELETE temporary DIET');
        
        ELSIF l_flg_status NOT IN (g_flg_diet_status_c, g_flg_diet_status_f, g_flg_diet_status_s)
        THEN
            g_error := 'CANCEL DIET';
            ts_epis_diet_req.upd(id_epis_diet_req_in => i_id_diet,
                                 flg_status_in       => g_flg_diet_status_c,
                                 notes_cancel_in     => i_notes,
                                 dt_cancel_in        => g_sysdate_tstz,
                                 id_prof_cancel_in   => i_prof.id,
                                 id_cancel_reason_in => i_reason,
                                 rows_out            => l_rows);
        
            g_error := 'CALL TO PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            g_error := 'OPEN c_episode_type';
            OPEN c_episode_type;
            FETCH c_episode_type
                INTO l_epis_type;
            CLOSE c_episode_type;
        
            IF l_epis_type = g_epis_type_inpt
            THEN
                g_error := 'GET GET_ACTIVE_DIET';
            
                l_active_diet := get_active_diet(i_lang,
                                                 i_prof,
                                                 l_id_episode,
                                                 g_flg_diet_t,
                                                 i_id_diet,
                                                 NULL,
                                                 NULL,
                                                 o_error);
                -- UPDATE THE EPISODE DIET ON EPIS_INFO
                l_rows  := table_varchar();
                g_error := 'UPDATE EPIS_INFO';
                ts_epis_info.upd(id_episode_in => l_id_episode,
                                 desc_diet_in  => l_active_diet,
                                 desc_diet_nin => FALSE,
                                 rows_out      => l_rows);
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_INFO',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END IF;
        END IF;
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => l_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
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
                                              'CANCEL_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CANCEL_DIET');
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_diet_internal;

    /**********************************************************************************************
    * Gets the information of a determined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type_diet             Type of diet (1 - Institucionalizada, 2 - Personalizada, 3 - Pre-definida)
    * @param i_id_diet               ID DIET
    
    * @param o_diet                  Cursor with the description of diet and the register
    * @param o_diet_schedule         Cursor with schedule of diet.
    * @param o_diet_food             Cursor with de detail of diet.
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/09
    **********************************************************************************************/

    FUNCTION get_diet
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_diet     IN diet_type.id_diet_type%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_diet       IN NUMBER,
        o_diet          OUT pk_types.cursor_type,
        o_diet_schedule OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_type_diet:' || i_type_diet || ' :i_id_diet:' || i_id_diet || ' :i_id_patient' ||
                              i_id_patient || ' ]',
                              g_package_name,
                              'GET_DIET');
        IF (i_type_diet = g_diet_type_defi OR i_type_diet = g_diet_type_inst)
           AND i_id_patient IS NULL
        THEN
            g_error := 'OPEN o_diet (pre-defined diet)';
            OPEN o_diet FOR
                SELECT dpi.id_diet_prof_instit id_diet,
                       dpi.desc_diet,
                       NULL dt_inicial,
                       NULL dt_end,
                       dpi.food_plan,
                       dpi.flg_help flg_help,
                       pk_sysdomain.get_domain(g_yes_no, dpi.flg_help, i_lang) desc_help,
                       dpi.notes notes,
                       dpi.flg_share,
                       pk_sysdomain.get_domain(g_yes_no, dpi.flg_share, i_lang) desc_share,
                       dpi.flg_institution flg_institution,
                       pk_sysdomain.get_domain(g_yes_no, dpi.flg_institution, i_lang) desc_institution
                  FROM diet_prof_instit dpi
                 WHERE dpi.id_diet_prof_instit = i_id_diet;
        
            g_error := 'OPEN o_diet_schedule (pre-defined diet)';
            --obter o hor?o das refei?s    
            OPEN o_diet_schedule FOR
                SELECT DISTINCT dpid.id_diet_schedule,
                                ds.rank,
                                pk_date_utils.to_char_insttimezone(i_prof, dpid.dt_diet_schedule, 'YYYYMMDDHH24MISS') meal_hour
                  FROM diet_prof_instit dpi, diet_prof_instit_det dpid, diet_schedule ds
                 WHERE dpi.id_diet_prof_instit = i_id_diet
                   AND dpi.id_diet_prof_instit = dpid.id_diet_prof_instit
                   AND dpid.id_diet_schedule = ds.id_diet_schedule
                 ORDER BY ds.rank;
        
            g_error := 'OPEN o_diet_food';
            -- obter os alimentos que compoem a refei?
            OPEN o_diet_food FOR
                SELECT dpid.id_diet_schedule,
                       ds.rank diet_rank,
                       d.id_diet,
                       d.id_diet_parent,
                       pk_translation.get_translation(i_lang, d.code_diet) desc_diet,
                       dpid.notes,
                       dpid.quantity,
                       pk_translation.get_translation(i_lang, um.code_unit_measure) desc_unit,
                       dpid.id_unit_measure id_unit_quantity,
                       d.quantity_default,
                       d.id_unit_measure id_unit_default,
                       pk_translation.get_translation(i_lang, umd.code_unit_measure) desc_unit_default,
                       d.energy_quantity_value energy_default,
                       pk_translation.get_translation(i_lang, ume.code_unit_measure) desc_unit_energy,
                       d.id_unit_measure_energy id_unit_energy
                  FROM diet_prof_instit     dpi,
                       diet_prof_instit_det dpid,
                       diet                 d,
                       diet_schedule        ds,
                       unit_measure         um,
                       unit_measure         umd,
                       unit_measure         ume
                 WHERE dpi.id_diet_prof_instit = i_id_diet
                   AND dpi.id_diet_prof_instit = dpid.id_diet_prof_instit
                   AND dpid.id_diet = d.id_diet
                   AND dpid.id_diet_schedule = ds.id_diet_schedule
                   AND dpid.id_unit_measure = um.id_unit_measure(+)
                   AND d.id_unit_measure = umd.id_unit_measure(+)
                   AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                 ORDER BY diet_rank, desc_diet;
        ELSE
            g_error := 'OPEN o_diet';
            OPEN o_diet FOR
                SELECT edr.id_epis_diet_req id_diet,
                       edr.desc_diet desc_diet,
                       pk_date_utils.to_char_insttimezone(i_prof, edr.dt_inicial, 'YYYYMMDDHH24MISS') dt_inicial,
                       pk_date_utils.to_char_insttimezone(i_prof, edr.dt_end, 'YYYYMMDDHH24MISS') dt_end,
                       edr.food_plan,
                       edr.flg_help,
                       pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                       edr.notes notes,
                       NULL flg_share,
                       NULL desc_share,
                       edr.flg_institution,
                       pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution
                  FROM epis_diet_req edr
                 WHERE edr.id_epis_diet_req = i_id_diet;
        
            g_error := 'OPEN o_diet_schedule';
            --obter o hor?o das refei?s    
            OPEN o_diet_schedule FOR
                SELECT DISTINCT ds.id_diet_schedule,
                                ds.rank,
                                pk_date_utils.to_char_insttimezone(i_prof, edd.dt_diet_schedule, 'YYYYMMDDHH24MISS') meal_hour
                  FROM (SELECT *
                          FROM epis_diet_det e
                         WHERE e.id_epis_diet_req = i_id_diet) edd
                 RIGHT JOIN (SELECT d.*
                               FROM diet_schedule d
                              WHERE d.flg_available = g_flg_available) ds
                    ON (edd.id_diet_schedule = ds.id_diet_schedule)
                 ORDER BY ds.rank;
        
            g_error := 'OPEN o_diet_food';
            -- obter os alimentos que compoem a refei?
            OPEN o_diet_food FOR
                SELECT edd.id_diet_schedule,
                       ds.rank diet_rank,
                       d.id_diet,
                       decode(d.id_diet_parent, NULL, d.id_diet, d.id_diet_parent) id_diet_parent,
                       pk_translation.get_translation(i_lang, d.code_diet) desc_diet,
                       get_diet_description_title(i_lang, i_prof, d.id_diet) desc_diet_viewer,
                       edd.notes,
                       edd.quantity,
                       pk_translation.get_translation(i_lang, um.code_unit_measure) desc_unit,
                       edd.id_unit_measure id_unit_quantity,
                       d.quantity_default,
                       d.id_unit_measure id_unit_default,
                       pk_translation.get_translation(i_lang, umd.code_unit_measure) desc_unit_default,
                       d.energy_quantity_value energy_default,
                       pk_translation.get_translation(i_lang, ume.code_unit_measure) desc_unit_energy,
                       d.id_unit_measure_energy id_unit_energy
                  FROM epis_diet_req edr,
                       epis_diet_det edd,
                       diet          d,
                       diet_schedule ds,
                       unit_measure  um,
                       unit_measure  umd,
                       unit_measure  ume
                 WHERE edr.id_epis_diet_req = i_id_diet
                   AND edr.id_epis_diet_req = edd.id_epis_diet_req
                   AND edd.id_diet = d.id_diet
                   AND edd.id_diet_schedule = ds.id_diet_schedule
                   AND edd.id_unit_measure = um.id_unit_measure(+)
                   AND d.id_unit_measure = umd.id_unit_measure(+)
                   AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                 ORDER BY diet_rank, desc_diet;
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
                                              'GET_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_schedule);
            pk_types.open_my_cursor(o_diet_food);
            RETURN FALSE;
        
    END get_diet;

    /**********************************************************************************************
    * Gets the list of pre-defined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_type                  Type od pre-defined diets(P - Professional/I-Institution)
    
    * @param o_diet                  Cursor with the description of diet and the register
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/08
    **********************************************************************************************/
    FUNCTION get_diet_prof_choice
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_type  IN VARCHAR2,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_type:' || i_type || ' ]', g_package_name, 'GET_DIET_PROF_CHOICE');
        IF i_type = g_diet_prof_p
        THEN
            OPEN o_diet FOR
                SELECT DISTINCT dpi.id_diet_prof_instit,
                                dpi.desc_diet desc_diet,
                                pk_prof_utils.get_name_signature(i_lang, i_prof, dpi.id_prof_create) professional,
                                decode(dpi.id_diet_prof_parent,
                                       NULL,
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dpi.dt_creation, i_prof),
                                       pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                          (SELECT connect_by_root dt_creation
                                                                             FROM diet_prof_instit dpi2
                                                                            WHERE dpi2.id_diet_prof_instit =
                                                                                  dpi.id_diet_prof_instit
                                                                           CONNECT BY PRIOR dpi2.id_diet_prof_instit =
                                                                                       dpi2.id_diet_prof_parent
                                                                            START WITH dpi2.id_diet_prof_parent IS NULL),
                                                                          i_prof)) dt_creation,
                                pk_date_utils.dt_chr_date_hour_tsz(i_lang, dpi.dt_creation, i_prof) dt_last_date,
                                decode((SELECT COUNT(1)
                                         FROM diet_prof_pref
                                        WHERE id_prof_pref = dpi.id_prof_create
                                          AND id_diet_prof_instit = dpi.id_diet_prof_instit
                                          AND flg_status = g_yes),
                                       0,
                                       g_inactive,
                                       g_active) flg_status,
                                g_yes flg_edit,
                                dpi.flg_status diet_status,
                                pk_date_utils.to_char_insttimezone(i_prof, dpi.dt_creation, 'YYYYMMDDHH24MISS') dt_last_date_str
                  FROM diet_prof_instit dpi
                 WHERE dpi.flg_status = g_flg_diet_status_a
                   AND dpi.id_prof_create = i_prof.id
                   AND dpi.id_institution = i_prof.institution;
        
        ELSE
            -- pREDEFINED DIET IN THE INSTITUTION THAR ARE SHARED
            OPEN o_diet FOR
            
                SELECT dpi.id_diet_prof_instit,
                       dpi.desc_diet desc_diet,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, dpi.id_prof_create) professional,
                       decode(dpi.id_diet_prof_parent,
                              NULL,
                              pk_date_utils.dt_chr_date_hour_tsz(i_lang, dpi.dt_creation, i_prof),
                              pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                                 (SELECT connect_by_root dt_creation
                                                                    FROM diet_prof_instit dpi2
                                                                   WHERE dpi2.id_diet_prof_instit =
                                                                         dpi.id_diet_prof_instit
                                                                  CONNECT BY PRIOR dpi2.id_diet_prof_instit =
                                                                              dpi2.id_diet_prof_parent
                                                                   START WITH dpi2.id_diet_prof_parent IS NULL),
                                                                 i_prof)) dt_creation,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, dpi.dt_creation, i_prof) dt_last_date,
                       decode(((SELECT COUNT(1)
                                  FROM diet_prof_pref
                                 WHERE id_prof_pref = i_prof.id
                                   AND id_diet_prof_instit = dpi.id_diet_prof_instit
                                   AND flg_status = g_yes)),
                              0,
                              g_inactive,
                              g_active) flg_status,
                       g_no flg_edit,
                       dpi.flg_status diet_status,
                       pk_date_utils.to_char_insttimezone(i_prof, dpi.dt_creation, 'YYYYMMDDHH24MISS') dt_last_date_str
                  FROM diet_prof_instit dpi
                 WHERE dpi.flg_status = g_flg_diet_status_a
                   AND dpi.id_prof_create <> i_prof.id
                   AND dpi.id_institution = i_prof.institution
                   AND dpi.flg_share = g_yes;
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
                                              'GET_DIET_PROF_CHOICE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
    END get_diet_prof_choice;

    /**********************************************************************************************
    * Cancel one pre-defined diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet               id of diet
    * @param O_FLG_SHOW              Y - existe msg para mostrar; N - ?iste
    * @param O_MSG                   mensagem no caso de a dieta estar activa para outros profissionais
    * @param O_MSG_TITLE             - T?lo da msg a mostrar ao utilizador, 
    * @param O_BUTTON - Bot?a mostrar: N - n? R - lido, C - confirmado
                            Tb pode mostrar combina?s destes, qd ?/ mostrar
                          + do q 1 bot?   
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/09
    **********************************************************************************************/
    FUNCTION cancel_diet_pref
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_diet   IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg       OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_active_diet IS
            SELECT COUNT(1)
              FROM diet_prof_pref dpp
             WHERE dpp.id_diet_prof_instit = i_id_diet
               AND dpp.id_prof_pref <> i_prof.id
               AND flg_status = g_yes;
        CURSOR c_diet_preference IS
            SELECT id_diet_prof_pref
              FROM diet_prof_pref
             WHERE id_diet_prof_instit = i_id_diet
               AND id_prof_pref = i_prof.id
               AND flg_status = g_yes;
        l_num_diet     NUMBER;
        l_rows         table_varchar;
        l_id_diet_pref diet_prof_pref.id_diet_prof_pref%TYPE;
        l_found        BOOLEAN;
        l_rows_pref    table_varchar;
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet:' || i_id_diet || ' ]', g_package_name, 'CANCEL_DIET_PREF');
        g_sysdate_tstz := current_timestamp;
        o_flg_show     := 'N';
        -- verify if the diet is the preference os others users
        g_error := 'OPEN C_ACTIVE_DIET';
        OPEN c_active_diet;
        FETCH c_active_diet
            INTO l_num_diet;
        CLOSE c_active_diet;
        IF l_num_diet > 0
        THEN
            o_flg_show  := 'Y';
            o_msg       := pk_message.get_message(i_lang, 'DIET_M013');
            o_msg_title := pk_message.get_message(i_lang, 'COMMON_T013');
            o_button    := 'R';
            RETURN TRUE;
        END IF;
        -- cancel the diet
        ts_diet_prof_instit.upd(id_diet_prof_instit_in => i_id_diet,
                                flg_status_in          => g_flg_diet_status_c,
                                id_prof_cancel_in      => i_prof.id,
                                dt_cancel_in           => g_sysdate_tstz,
                                rows_out               => l_rows);
    
        OPEN c_diet_preference;
        FETCH c_diet_preference
            INTO l_id_diet_pref;
        l_found := c_diet_preference%FOUND;
        CLOSE c_diet_preference;
        IF l_found
        THEN
            -- REMOVE THE DIET FROM MY PREFERENCES
            ts_diet_prof_pref.upd(id_diet_prof_pref_in => l_id_diet_pref,
                                  flg_status_in        => g_no,
                                  dt_cancel_in         => g_sysdate_tstz,
                                  rows_out             => l_rows_pref);
        END IF;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIET_PREF',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || g_error, g_package_name, 'CANCEL_DIET_PREF');
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_diet_pref;

    FUNCTION get_food_energy
    (
        i_quantity         IN NUMBER,
        i_quantity_default IN NUMBER,
        i_energy           IN NUMBER
    ) RETURN NUMBER IS
    
    BEGIN
        RETURN round((i_energy * i_quantity) / i_quantity_default, 3);
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * Set's the list of preferred diet of the professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet               list of diet's
    * @param i_selected              list of status diet
    
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/13
    **********************************************************************************************/
    FUNCTION set_diet_preference
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_diet  IN table_number,
        i_selected IN table_varchar,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num     NUMBER;
        l_rows    table_varchar;
        l_id_diet diet_prof_pref.id_diet_prof_pref%TYPE;
    BEGIN
        pk_alertlog.log_debug('SET_DIET_PREFERENCE', g_package_name);
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'LOOP I_ID_DIET';
        FOR i IN i_id_diet.first .. i_id_diet.last
        LOOP
            SELECT COUNT(1) -- verify if this diet is already a active preference for user 
              INTO l_num
              FROM diet_prof_pref
             WHERE id_diet_prof_instit = i_id_diet(i)
               AND id_prof_pref = i_prof.id
               AND flg_status = g_yes;
        
            IF i_selected(i) = g_active -- if it is selected
            THEN
                IF l_num = 0
                THEN
                    ts_diet_prof_pref.ins(id_diet_prof_instit_in => i_id_diet(i),
                                          id_prof_pref_in        => i_prof.id,
                                          flg_status_in          => g_yes,
                                          dt_creation_in         => g_sysdate_tstz,
                                          rows_out               => l_rows);
                END IF;
            ELSE
                -- not selected
                IF l_num > 0
                THEN
                    BEGIN
                        SELECT id_diet_prof_pref
                          INTO l_id_diet
                          FROM diet_prof_pref
                         WHERE id_diet_prof_instit = i_id_diet(i)
                           AND id_prof_pref = i_prof.id
                           AND flg_status = g_yes;
                        -- deselect the diet   
                        ts_diet_prof_pref.upd(id_diet_prof_pref_in => l_id_diet,
                                              flg_status_in        => g_no,
                                              dt_cancel_in         => g_sysdate_tstz,
                                              rows_out             => l_rows);
                    EXCEPTION
                        WHEN too_many_rows THEN
                        
                            -- deselect the diet   
                            ts_diet_prof_pref.upd(flg_status_in => g_no,
                                                  dt_cancel_in  => g_sysdate_tstz,
                                                  where_in      => 'id_diet_prof_instit=' || i_id_diet(i) ||
                                                                   ' AND id_prof_pref= ' || i_prof.id ||
                                                                   ' AND flg_status=''' || g_yes || '''');
                    END;
                
                END IF;
            END IF;
        END LOOP;
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DIET_PREFERENCE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_diet_preference;

    /**********************************************************************************************
    * Gets the list of preferenced diets of professional
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param o_diet                  Cursor with the lists os prefered diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/15
    **********************************************************************************************/
    FUNCTION get_diet_prof_pref
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_diet  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        pk_alertlog.log_debug('GET_DIET_PROF_PREF', g_package_name);
        g_error := 'OPEN o_diet';
        OPEN o_diet FOR
            SELECT DISTINCT dpi.id_diet_prof_instit id_diet, dpi.desc_diet
              FROM diet_prof_instit dpi, diet_prof_pref dpp
             WHERE dpi.id_diet_prof_instit = dpp.id_diet_prof_instit
               AND dpp.flg_status = g_yes
               AND dpi.flg_status = g_flg_diet_status_a
               AND dpp.id_prof_pref = i_prof.id
               AND dpi.id_institution = i_prof.institution;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIET_PROF_PREF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
        
    END get_diet_prof_pref;

    /**********************************************************************************************
    * Set's the status of actives diets when discharge
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID Episode
    *
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/04/21
    **********************************************************************************************/

    FUNCTION set_diet_interrupt
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_visit IN episode.id_visit%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_prof_alert sys_config.value%TYPE;
        l_rows          table_varchar := table_varchar();
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_visit' || i_visit || ']', g_package_name, 'SET_DIET_INTERRUPT');
    
        g_sysdate_tstz := current_timestamp;
        g_error        := 'UPDATE EPIS_DIET_REQ';
        -- get the alert professional for inactivate diet
        l_id_prof_alert := pk_sysconfig.get_config(i_code_cf => 'ID_PROF_ALERT', i_prof => i_prof);
        -- get notes for automatic inactive diet
        --  l_notes := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_M014');
        ts_epis_diet_req.upd(flg_status_in         => g_flg_diet_status_s,
                             id_prof_cancel_in     => l_id_prof_alert,
                             dt_cancel_in          => g_sysdate_tstz,
                             id_cancel_reason_in   => pk_cancel_reason.c_reason_other,
                             dt_initial_suspend_in => g_sysdate_tstz,
                             where_in              => 'id_episode IN (SELECT id_episode  FROM episode WHERE id_visit = ' ||
                                                      i_visit || ') and flg_institution=''' || g_no ||
                                                      ''' and flg_status=''' || g_flg_diet_status_r || '''',
                             rows_out              => l_rows);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIET_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_DIET_INTERRUPT',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'SET_DIET_INTERRUPT');
        
            RETURN FALSE;
        
    END set_diet_interrupt;

    /**********************************************************************************************
    * Returns the diet for the episode
    *
    * @param i_lang                  Language ID
    * @param i_episode               ID Episode
    * @param i_type                  Type of information (T - Type of Diet, N - Name of diet) 
    
    *
    * @return                        A String with active diets
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/11
    **********************************************************************************************/
    FUNCTION get_active_diet
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_type    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_active_diet VARCHAR2(4000);
        l_error       t_error_out;
    BEGIN
        l_active_diet := pk_diet.get_active_diet(i_lang         => i_lang,
                                                 i_prof         => NULL,
                                                 i_episode      => i_episode,
                                                 i_type         => i_type,
                                                 i_id_epis_diet => NULL,
                                                 i_start_date   => NULL,
                                                 i_end_date     => NULL,
                                                 o_error        => l_error);
    
        RETURN l_active_diet;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_active_diet;

    /**********************************************************************************************
    * Returns the status of a diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details 
    * @param i_diet                  ID of the diet 
    
    *
    * @return                        A String with the status of a diet
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION get_diet_status
    (
        i_lang IN language.id_language%TYPE,
        i_prof profissional,
        i_diet IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2 IS
        CURSOR c_diet IS
            SELECT flg_status, dt_creation, id_epis_diet_req_parent, dt_inicial, dt_end
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_diet;
    
        l_flg_status  epis_diet_req.flg_status%TYPE;
        l_dt_creation epis_diet_req.dt_creation%TYPE;
        l_id_parent   epis_diet_req.id_epis_diet_req_parent%TYPE;
        l_dt_initial  epis_diet_req.dt_inicial%TYPE;
        l_dt_end      epis_diet_req.dt_end%TYPE;
    
        l_compare            VARCHAR2(1);
        l_dt_creation_parent epis_diet_req.dt_creation%TYPE;
    BEGIN
    
        g_error := 'OPEN c_diet';
        OPEN c_diet;
        FETCH c_diet
            INTO l_flg_status, l_dt_creation, l_id_parent, l_dt_initial, l_dt_end;
        CLOSE c_diet;
        --
        IF l_flg_status IN (g_flg_diet_status_c, g_flg_diet_status_s, g_flg_diet_status_i)
        THEN
            RETURN NULL;
        ELSE
            l_compare := pk_date_utils.compare_dates_tsz(i_prof, l_dt_initial, current_timestamp);
            IF l_compare = g_flg_date_g
            THEN
                RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T095');
            ELSE
                l_compare := pk_date_utils.compare_dates_tsz(i_prof, l_dt_end, current_timestamp);
                IF l_compare = g_flg_date_l
                THEN
                    RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T088');
                ELSE
                    RETURN pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T086');
                END IF;
            END IF;
        END IF;
    
    END get_diet_status;

    /**********************************************************************************************
    * Returns the current state of a diet (i_status_type = 'D') or 
    * the status of the diet i_status_type = 'F').  
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details 
    * @param i_diet                  ID of the diet 
    * @param i_status_type           'D' - diet state, 'F' - diet flag status 
    *
    * @return                        A String with the current state/status
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/18
    **********************************************************************************************/
    FUNCTION get_processed_diet_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        profissional,
        i_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_status_type IN VARCHAR DEFAULT 'D'
    ) RETURN VARCHAR2 IS
        l_status_processed sys_message.desc_message%TYPE;
    
        l_diet_active    sys_message.desc_message%TYPE;
        l_diet_suspend   sys_message.desc_message%TYPE;
        l_diet_completed sys_message.desc_message%TYPE;
        l_diet_state     sys_message.desc_message%TYPE;
        l_diet_canceled  sys_message.desc_message%TYPE;
        l_diet_schedule  sys_message.desc_message%TYPE;
        l_diet_draft     sys_message.desc_message%TYPE;
        l_diet_expired   sys_message.desc_message%TYPE;
        l_diet_descont   sys_message.desc_message%TYPE;
        --
        l_error t_error_out;
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        l_diet_active := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T086');
    
        l_diet_suspend   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T087');
        l_diet_completed := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T088');
        l_diet_state     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T084');
        l_diet_canceled  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T094');
        l_diet_schedule  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T095');
        --
        l_diet_draft   := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T107');
        l_diet_expired := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T108');
        l_diet_descont := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T139');
    
        --
        IF i_status_type = g_status_type_f
        THEN
            g_error := 'Get current diet flag status';
            SELECT decode(edr.flg_status,
                          g_flg_diet_status_s,
                          g_flg_diet_status_s,
                          g_flg_diet_status_c,
                          g_flg_diet_status_c,
                          g_flg_diet_status_x,
                          g_flg_diet_status_x,
                          g_flg_diet_status_t,
                          g_flg_diet_status_t,
                          g_flg_diet_status_i,
                          g_flg_diet_status_i,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                 'G',
                                 g_flg_diet_status_h,
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                        'L',
                                        g_flg_diet_status_f,
                                        g_flg_diet_status_a))) flg_status
              INTO l_status_processed
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_diet;
        ELSIF i_status_type = g_status_type_c
        THEN
            g_error := 'Get current cpoe diet flag state';
            SELECT decode(decode(edr.flg_status,
                                 g_flg_diet_status_s,
                                 g_flg_diet_status_s,
                                 g_flg_diet_status_c,
                                 g_flg_diet_status_c,
                                 g_flg_diet_status_t,
                                 g_flg_diet_status_t,
                                 g_flg_diet_status_x,
                                 g_flg_diet_status_x,
                                 g_flg_diet_status_o,
                                 g_flg_diet_status_o,
                                 g_flg_diet_status_i,
                                 g_flg_diet_status_i,
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                        g_flg_date_g,
                                        g_flg_diet_status_h,
                                        decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                               g_flg_date_l,
                                               g_flg_diet_status_f,
                                               g_flg_diet_status_a))),
                          g_flg_diet_status_s,
                          g_flg_diet_status_s,
                          g_flg_diet_status_i,
                          g_flg_diet_status_i,
                          g_flg_diet_status_c,
                          g_cpoe_diet_status_c,
                          g_flg_diet_status_f,
                          g_cpoe_diet_status_i,
                          g_flg_diet_status_h,
                          g_cpoe_diet_status_a,
                          g_flg_diet_status_t,
                          g_cpoe_diet_status_d,
                          g_flg_diet_status_x,
                          g_cpoe_diet_status_i,
                          g_flg_diet_status_o,
                          g_flg_diet_status_o,
                          g_cpoe_diet_status_a) cpoe_status
              INTO l_status_processed
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_diet;
        ELSE
            g_error := 'Get current diet state';
            SELECT decode(decode(edr.flg_status,
                                 g_flg_diet_status_s,
                                 g_flg_diet_status_s,
                                 g_flg_diet_status_c,
                                 g_flg_diet_status_c,
                                 g_flg_diet_status_x,
                                 g_flg_diet_status_x,
                                 g_flg_diet_status_i,
                                 g_flg_diet_status_i,
                                 g_flg_diet_status_t,
                                 g_flg_diet_status_t,
                                 decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                        g_flg_date_g,
                                        g_flg_diet_status_h,
                                        decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                               g_flg_date_l,
                                               g_flg_diet_status_f,
                                               g_flg_diet_status_a))),
                          g_flg_diet_status_s,
                          l_diet_suspend,
                          g_flg_diet_status_c,
                          l_diet_canceled,
                          g_flg_diet_status_f,
                          l_diet_completed,
                          g_flg_diet_status_h,
                          l_diet_schedule,
                          g_flg_diet_status_t,
                          l_diet_draft,
                          g_flg_diet_status_x,
                          l_diet_expired,
                          g_flg_diet_status_i,
                          l_diet_descont,
                          l_diet_active) diet_status
              INTO l_status_processed
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_diet;
        END IF;
    
        RETURN l_status_processed;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_processed_diet_status',
                                              l_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM,
                                  g_package_name,
                                  'get_processed_diet_status');
            RETURN NULL;
    END get_processed_diet_status;
    --

    /**********************************************************************************************
    * returns the status of a diet (overload created for order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional's details 
    * @param i_diet                  id of the diet 
    * @param o_status_string         diet flg status (pre-processed)
    * @param o_flag_canceled         indicates if it is canceled
    * @param o_flag_finished         indicates if it is finished
    * @param o_error                 error structure    
    *
    * @return                        boolean with return status
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/22
    **********************************************************************************************/
    FUNCTION get_diet_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diet          IN epis_diet_req.id_epis_diet_req%TYPE,
        o_status_string OUT VARCHAR2,
        o_flag_canceled OUT VARCHAR2,
        o_flag_finished OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diet(v_sysdate_tstz epis_diet_req.dt_inicial%TYPE) IS
            SELECT get_diet_status_str(i_lang,
                                       i_prof,
                                       decode(edr.flg_status,
                                              g_flg_diet_status_s,
                                              g_flg_diet_status_s,
                                              g_flg_diet_status_c,
                                              g_flg_diet_status_c,
                                              g_flg_diet_status_x,
                                              g_flg_diet_status_x,
                                              g_flg_diet_status_i,
                                              g_flg_diet_status_i,
                                              g_flg_diet_status_t,
                                              g_flg_diet_status_t,
                                              g_flg_diet_status_o,
                                              g_flg_diet_status_o,
                                              decode(pk_date_utils.compare_dates_tsz(i_prof,
                                                                                     edr.dt_inicial,
                                                                                     v_sysdate_tstz),
                                                     g_flg_date_g,
                                                     g_flg_diet_status_h,
                                                     decode(pk_date_utils.compare_dates_tsz(i_prof,
                                                                                            edr.dt_end,
                                                                                            v_sysdate_tstz),
                                                            g_flg_date_l,
                                                            g_flg_diet_status_f,
                                                            g_flg_diet_status_a))),
                                       edr.dt_inicial,
                                       edr.dt_end,
                                       g_sysdate_tstz) status_str,
                   flg_status,
                   dt_inicial,
                   dt_end
              FROM epis_diet_req edr
             WHERE id_epis_diet_req = i_diet;
    
        l_flg_status    epis_diet_req.flg_status%TYPE;
        l_dt_initial    epis_diet_req.dt_inicial%TYPE;
        l_dt_end        epis_diet_req.dt_end%TYPE;
        l_status_string VARCHAR2(2000);
    
        l_compare VARCHAR2(1);
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_diet(g_sysdate_tstz);
        FETCH c_diet
            INTO l_status_string, l_flg_status, l_dt_initial, l_dt_end;
        CLOSE c_diet;
    
        -- canceled (a suspended diet can be executed again, so order sets won't consider it canceled)
        IF l_flg_status = g_flg_diet_status_c
        THEN
            o_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_display_type => pk_alert_constant.g_display_type_icon,
                                                                    i_flg_state    => pk_order_sets.g_order_set_proc_tsk_canceled,
                                                                    i_value_text   => NULL,
                                                                    i_value_date   => NULL,
                                                                    i_value_icon   => pk_order_sets.g_odst_ptsk_flg_status_domain);
            o_flag_canceled := g_yes;
            o_flag_finished := g_no;
        ELSIF l_flg_status IN (g_flg_diet_status_t, g_flg_diet_status_x)
        THEN
            o_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                    i_prof         => i_prof,
                                                                    i_display_type => pk_alert_constant.g_display_type_icon,
                                                                    i_flg_state    => l_flg_status,
                                                                    i_value_text   => NULL,
                                                                    i_value_date   => NULL,
                                                                    i_value_icon   => 'EPIS_DIET_REQ.FLG_STATUS');
        
        ELSE
            l_compare := pk_date_utils.compare_dates_tsz(i_prof, l_dt_initial, current_timestamp);
            -- scheduled
            IF l_compare = g_flg_date_g
            THEN
                o_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                        i_prof         => i_prof,
                                                                        i_display_type => pk_alert_constant.g_display_type_text,
                                                                        i_flg_state    => NULL,
                                                                        i_value_text   => pk_order_sets.g_order_set_proc_tsk_sched_msg,
                                                                        i_value_date   => NULL,
                                                                        i_value_icon   => NULL,
                                                                        i_back_color   => pk_alert_constant.g_color_green);
                o_flag_canceled := g_no;
                o_flag_finished := g_no;
            ELSE
                l_compare := pk_date_utils.compare_dates_tsz(i_prof, l_dt_end, current_timestamp);
                -- finished
                IF l_compare = g_flg_date_l
                THEN
                    o_status_string := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                                            i_prof         => i_prof,
                                                                            i_display_type => pk_alert_constant.g_display_type_icon,
                                                                            i_flg_state    => pk_order_sets.g_order_set_proc_tsk_finished,
                                                                            i_value_text   => NULL,
                                                                            i_value_date   => NULL,
                                                                            i_value_icon   => pk_order_sets.g_odst_ptsk_flg_status_domain);
                    o_flag_canceled := g_no;
                    o_flag_finished := g_yes;
                ELSE
                    -- active (or suspended)
                    o_status_string := l_status_string;
                    o_flag_canceled := g_no;
                    o_flag_finished := g_no;
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
                                              'GET_DIET_STATUS',
                                              o_error);
            RETURN FALSE;
    END get_diet_status;

    /**********************************************************************************************
    * returns the status of a diet (overload created for order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional's details 
    * @param i_diet                  id of the diet 
    * @param o_status_string         diet flg status (pre-processed)
    * @param o_flag_canceled         indicates if it is canceled
    * @param o_flag_finished         indicates if it is finished
    * @param o_error                 error structure    
    *
    * @return                        boolean with return status
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2011/11/08
    **********************************************************************************************/
    FUNCTION get_diet_status_internal
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_diet IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_result BOOLEAN;
    
        l_flg_finished    VARCHAR2(1 CHAR) := g_no;
        l_flg_canceled    VARCHAR2(1 CHAR) := g_no;
        l_o_status_string VARCHAR2(200);
        l_error           t_error_out;
    
    BEGIN
    
        IF NOT
            pk_diet.get_diet_status(i_lang, i_prof, i_diet, l_o_status_string, l_flg_canceled, l_flg_finished, l_error)
        THEN
            RETURN NULL;
        ELSE
            RETURN l_o_status_string;
        END IF;
    
    END get_diet_status_internal;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be suspended
    * @param i_notes                 Suspend Notes 
    * @param i_reason                ID Reason for suspend
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION suspend_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_reason         IN epis_diet_req.id_cancel_reason%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT suspend_diet(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_diet        => i_id_diet,
                            i_notes          => i_notes,
                            i_reason         => i_reason,
                            i_dt_initial_str => i_dt_initial_str,
                            i_dt_end_str     => i_dt_end_str,
                            i_commit         => pk_alert_constant.g_yes,
                            o_error          => o_error)
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
                                              'SUSPEND_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'SUSPEND_DIET');
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END suspend_diet;

    /**********************************************************************************************
    * Suspend a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    
    * @param i_id_diet               ID Diet to be suspended
    * @param i_notes                 Suspend Notes 
    * @param i_reason                ID Reason for suspend
    * @param i_dt_initial            Initial date for suspend
    * @param i_dt_end                End date for suspend
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION suspend_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_reason         IN epis_diet_req.id_cancel_reason%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_force_cancel   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode  episode.id_episode%TYPE;
        l_id_patient  episode.id_patient%TYPE;
        l_epis_type   episode.id_epis_type%TYPE;
        l_active_diet VARCHAR2(4000);
        l_rows        table_varchar;
    
        CURSOR c_diet_episode IS
            SELECT id_episode, id_patient
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_diet;
    
        CURSOR c_episode_type IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = l_id_episode;
    
        l_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_begin_str  VARCHAR2(14);
        l_dt_end_str    VARCHAR2(14);
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet' || i_id_diet || ']', g_package_name, 'SUSPEND_DIET');
    
        g_error := 'CONVERT DATES';
    
        l_dt_begin_str := i_dt_initial_str;
    
        IF i_dt_end_str IS NOT NULL
        THEN
            IF substr(i_dt_end_str, 1, 8) = substr(i_dt_initial_str, 1, 8)
            THEN
                l_dt_end_str := substr(i_dt_end_str, 1, 8) || '235900';
            ELSE
                l_dt_end_str := substr(i_dt_end_str, 1, 8) || '000000';
            END IF;
        ELSE
            l_dt_end_str := i_dt_end_str;
        END IF;
    
        g_sysdate_tstz := current_timestamp;
    
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_begin_str, NULL);
        l_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_end_str, NULL);
    
        g_error := 'OPEN c_diet_episode';
        OPEN c_diet_episode;
        FETCH c_diet_episode
            INTO l_id_episode, l_id_patient;
        CLOSE c_diet_episode;
    
        g_error := 'SUSPEND DIET';
        ts_epis_diet_req.upd(id_epis_diet_req_in   => i_id_diet,
                             flg_status_in         => CASE
                                                          WHEN i_force_cancel = pk_alert_constant.g_no THEN
                                                           g_flg_diet_status_s
                                                          ELSE
                                                           g_flg_diet_status_i
                                                      END,
                             notes_cancel_in       => i_notes,
                             dt_cancel_in          => g_sysdate_tstz,
                             id_prof_cancel_in     => i_prof.id,
                             id_cancel_reason_in   => i_reason,
                             dt_initial_suspend_in => l_dt_begin_tstz,
                             dt_end_suspend_in     => l_dt_end_tstz,
                             rows_out              => l_rows);
    
        g_error := 'CALL TO PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIET_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'OPEN c_episode_type';
        OPEN c_episode_type;
        FETCH c_episode_type
            INTO l_epis_type;
        CLOSE c_episode_type;
    
        IF l_epis_type = g_epis_type_inpt
        THEN
            g_error := 'GET GET_ACTIVE_DIET';
        
            l_active_diet := get_active_diet(i_lang, i_prof, l_id_episode, g_flg_diet_t, i_id_diet, NULL, NULL, o_error);
            -- UPDATE THE EPISODE DIET ON EPIS_INFO
            l_rows  := table_varchar();
            g_error := 'UPDATE EPIS_INFO';
            ts_epis_info.upd(id_episode_in => l_id_episode,
                             desc_diet_in  => l_active_diet,
                             desc_diet_nin => FALSE,
                             rows_out      => l_rows);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
        END IF;
    
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => l_id_episode,
                                      i_pat                 => l_id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SUSPEND_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'SUSPEND_DIET');
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
    END suspend_diet;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID EPISODE
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT resume_diet(i_lang           => i_lang,
                           i_prof           => i_prof,
                           i_episode        => i_episode,
                           i_id_diet        => i_id_diet,
                           i_notes          => i_notes,
                           i_dt_initial_str => i_dt_initial_str,
                           i_dt_end_str     => i_dt_end_str,
                           i_commit         => pk_alert_constant.g_yes,
                           o_error          => o_error)
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
                                              'RESUME_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'RESUME_DIET');
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END resume_diet;

    /**********************************************************************************************
    * Resume a diet 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID EPISODE
    * @param i_id_diet               ID Diet to be resumed
    * @param i_notes                 Resume Notes 
    * @param i_dt_initial            Initial date for resume
    * @param i_dt_end                End date for resume
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/15
    **********************************************************************************************/
    FUNCTION resume_diet
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_diet        IN epis_diet_req.id_epis_diet_req%TYPE,
        i_notes          IN epis_diet_req.notes_cancel%TYPE,
        i_dt_initial_str IN VARCHAR2,
        i_dt_end_str     IN VARCHAR2,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_begin_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_diet IS
            SELECT id_patient, id_diet_type, desc_diet, food_plan, flg_help, notes, flg_institution
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_diet;
    
        l_diet             c_diet%ROWTYPE;
        l_diet_req         epis_diet_req.id_epis_diet_req%TYPE;
        l_id_diet_schedule table_number;
        l_id_diet          table_number;
        l_quantity         table_number;
        l_id_unit          table_number;
        l_notes_diet       table_varchar;
        l_dt_hour          table_varchar;
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_id_diet' || i_id_diet || ']', g_package_name, 'RESUME_DIET');
    
        --  create_epis_diet(i_lang => i_lang
        g_error := 'OPEN CURSOR C_DIET';
        OPEN c_diet;
        FETCH c_diet
            INTO l_diet;
        CLOSE c_diet;
    
        g_error := 'GET DIET DETAIL';
        SELECT id_diet_schedule,
               id_diet,
               pk_date_utils.to_char_insttimezone(i_prof, dt_diet_schedule, 'YYYYMMDDHH24MISS'),
               quantity,
               id_unit_measure,
               notes
          BULK COLLECT
          INTO l_id_diet_schedule, l_id_diet, l_dt_hour, l_quantity, l_id_unit, l_notes_diet
          FROM epis_diet_det
         WHERE id_epis_diet_req = i_id_diet;
    
        g_error := 'CREATE EPIS_DIET';
        IF NOT create_epis_diet(i_lang               => i_lang,
                                i_prof               => i_prof,
                                i_patient            => l_diet.id_patient,
                                i_episode            => i_episode,
                                i_id_epis_diet       => i_id_diet,
                                i_id_diet_type       => l_diet.id_diet_type,
                                i_desc_diet          => l_diet.desc_diet,
                                i_dt_begin_str       => i_dt_initial_str,
                                i_dt_end_str         => i_dt_end_str,
                                i_food_plan          => l_diet.food_plan,
                                i_flg_help           => l_diet.flg_help,
                                i_notes              => l_diet.notes,
                                i_id_diet_predefined => NULL,
                                i_id_diet_schedule   => l_id_diet_schedule,
                                i_id_diet            => l_id_diet,
                                i_quantity           => l_quantity,
                                i_id_unit            => l_id_unit,
                                i_notes_diet         => l_notes_diet,
                                i_dt_hour            => l_dt_hour,
                                i_flg_institution    => l_diet.flg_institution,
                                i_resume_notes       => i_notes,
                                o_id_epis_diet       => l_diet_req,
                                o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Synchronize CPOE tasks
        g_error := 'CALL SYNC_TASK : ' || l_diet_req;
        IF NOT sync_task(i_lang             => i_lang,
                         i_prof             => i_prof,
                         i_episode          => i_episode,
                         i_task_type        => l_diet.id_diet_type,
                         i_task_request     => l_diet_req,
                         i_task_request_old => i_id_diet,
                         i_dt_task          => pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                             i_prof      => i_prof,
                                                                             i_timestamp => i_dt_initial_str,
                                                                             i_timezone  => NULL),
                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
        IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_pat                 => l_diet.id_patient,
                                      i_prof                => i_prof,
                                      i_prof_cat_type       => NULL,
                                      i_dt_last_interaction => g_sysdate_tstz,
                                      i_dt_first_obs        => g_sysdate_tstz,
                                      o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
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
                                              'RESUME_DIET',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'RESUME_DIET');
        
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END resume_diet;

    /**********************************************************************************************
    * Gets the unit for suspend duration 
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param o_duration_units        cursor with the units
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/21
    **********************************************************************************************/

    FUNCTION get_suspend_unit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_duration_units OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_market institution.id_market%TYPE := pk_core.get_inst_mkt(i_prof.institution);
    BEGIN
        g_error := 'OPEN o_duration_units';
        OPEN o_duration_units FOR
            SELECT aux.id, aux.label, aux.flg_default
              FROM (SELECT to_char(u.id_unit_measure) id,
                           pk_translation.get_translation(i_lang, u.code_unit_measure) label,
                           decode(u.id_unit_measure, g_id_unit_days, 'Y', 'N') flg_default,
                           row_number() over(PARTITION BY u.id_unit_measure ORDER BY decode(uomg.id_market, l_market, 1, 2)) line_number,
                           uomg.rank
                      FROM unit_measure u
                      JOIN unit_measure_group uomg
                        ON uomg.id_unit_measure = u.id_unit_measure
                     WHERE u.id_unit_measure IN (g_id_unit_days, g_id_unit_months, g_id_unit_weeks)) aux
             WHERE aux.line_number = 1
             ORDER BY aux.rank;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SUSPEND_UNIT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_duration_units);
            RETURN FALSE;
        
    END get_suspend_unit;

    /**********************************************************************************************
    * Gets a flat that indicates the questions in that are visible in the diet
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Id Type diet
    * @param i_Episode               ID episode
    * @param o_flg_visible           F ? First (Help) S ? Second (Institution), B ? Both; N - None 
    * @param o_flg_mandatory         Indicates if fields are mandatory
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/05/21
    **********************************************************************************************/
    FUNCTION get_type_episode_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_diet_type     IN diet_type.id_diet_type%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_flg_visible   OUT VARCHAR2,
        o_flg_mandatory OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_type IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
        l_epis_type     episode.id_epis_type%TYPE;
        l_flg_mandatory VARCHAR2(1);
    BEGIN
    
        l_flg_mandatory := pk_sysconfig.get_config(i_code_cf => 'DIET_FIELDS_MANDATORY', i_prof => i_prof);
        o_flg_mandatory := nvl(l_flg_mandatory, g_yes);
        IF i_episode IS NULL
        THEN
            o_flg_visible := 'N';
        ELSE
            g_error := 'OPEN C_EPIS_TYPE';
            OPEN c_epis_type;
            FETCH c_epis_type
                INTO l_epis_type;
            IF c_epis_type%NOTFOUND
            THEN
                o_flg_visible := 'N';
            END IF;
            CLOSE c_epis_type;
            IF l_epis_type IN (g_epis_type_inpt, g_epis_type_edis)
            THEN
                o_flg_visible := 'B';
            ELSE
                o_flg_visible := 'N';
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
                                              'GET_TYPE_EPISODE_STATUS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_type_episode_status;

    FUNCTION migracao RETURN BOOLEAN IS
        CURSOR c_epis_diet IS
            SELECT id_epis_diet,
                   id_diet,
                   ed.id_episode,
                   id_professional,
                   ed.flg_status,
                   notes,
                   ed.id_prof_cancel,
                   notes_cancel,
                   id_prof_inter,
                   notes_inter,
                   flg_help,
                   dt_creation_tstz,
                   ed.dt_cancel_tstz,
                   dt_inter_tstz,
                   dt_initial_tstz,
                   ed.dt_end_tstz,
                   e.flg_status flg_status_episode,
                   e.id_patient,
                   decode(id_diet, NULL, ed.desc_diet, NULL) desc_diet
              FROM epis_diet ed, episode e
             WHERE ed.id_episode = e.id_episode
               AND e.id_episode = 333509
             ORDER BY 1;
        CURSOR c_diet_name IS
            SELECT pk_translation.get_translation(1, code_diet_type)
              FROM diet_type
             WHERE id_diet_type = 1;
    
        l_id_diet_type       diet_type.id_diet_type%TYPE;
        l_diet_name          epis_diet_req.desc_diet%TYPE;
        l_id_diet            epis_diet_req.id_epis_diet_req%TYPE;
        l_diet_status        epis_diet_req.flg_status%TYPE;
        l_notes              epis_diet_req.notes_cancel%TYPE;
        l_notes_desc         sys_message.desc_message%TYPE;
        l_id_professional    epis_diet_req.id_prof_cancel%TYPE;
        id_prof_alert        sys_config.value%TYPE;
        l_sysdate_tstz       TIMESTAMP WITH TIME ZONE;
        l_notes_cancel       epis_diet_req.notes_cancel%TYPE;
        l_id_reason          epis_diet_req.id_cancel_reason%TYPE;
        l_automatic_reason   epis_diet_req.notes_cancel%TYPE;
        l_dt_initial_suspend epis_diet_req.dt_initial_suspend%TYPE;
    BEGIN
        l_id_diet_type := 1;
        OPEN c_diet_name;
        FETCH c_diet_name
            INTO l_diet_name;
        CLOSE c_diet_name;
        g_sysdate_tstz := current_timestamp;
        id_prof_alert  := pk_sysconfig.get_config('ID_PROF_ALERT', profissional(NULL, NULL, NULL));
    
        FOR c_cur_epis_diet IN c_epis_diet
        LOOP
            -- 
            l_id_reason          := NULL;
            l_dt_initial_suspend := NULL;
            IF c_cur_epis_diet.flg_status = 'R'
               AND c_cur_epis_diet.flg_status_episode = 'I'
            THEN
                BEGIN
                    SELECT d.dt_admin_tstz
                      INTO l_dt_initial_suspend
                      FROM discharge d
                     WHERE d.id_episode = c_cur_epis_diet.id_episode
                       AND d.flg_status = 'A'
                       AND d.flg_status_adm = pk_alert_constant.g_active;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_dt_initial_suspend := NULL;
                END;
                l_diet_status     := 'S';
                l_id_professional := id_prof_alert;
                l_sysdate_tstz    := g_sysdate_tstz;
                l_notes_cancel    := NULL;
                l_id_reason       := 57;
            ELSIF c_cur_epis_diet.flg_status = 'C'
            THEN
                l_diet_status     := 'C';
                l_id_professional := c_cur_epis_diet.id_prof_cancel;
                l_sysdate_tstz    := c_cur_epis_diet.dt_cancel_tstz;
                l_notes_cancel    := c_cur_epis_diet.notes_cancel;
                l_id_reason       := 51;
            ELSIF c_cur_epis_diet.flg_status = 'I'
            THEN
                l_diet_status        := 'S';
                l_id_professional    := c_cur_epis_diet.id_prof_inter;
                l_sysdate_tstz       := c_cur_epis_diet.dt_inter_tstz;
                l_notes_cancel       := c_cur_epis_diet.notes_inter;
                l_dt_initial_suspend := c_cur_epis_diet.dt_inter_tstz;
                l_id_reason          := 57;
            ELSE
                l_diet_status     := c_cur_epis_diet.flg_status;
                l_id_professional := NULL;
                l_sysdate_tstz    := NULL;
                l_notes_cancel    := NULL;
            END IF;
        
            ts_epis_diet_req.ins(id_diet_type_in       => l_id_diet_type,
                                 id_episode_in         => c_cur_epis_diet.id_episode,
                                 id_patient_in         => c_cur_epis_diet.id_patient,
                                 id_professional_in    => c_cur_epis_diet.id_professional,
                                 desc_diet_in          => c_cur_epis_diet.desc_diet,
                                 flg_status_in         => l_diet_status,
                                 notes_in              => c_cur_epis_diet.notes,
                                 flg_help_in           => c_cur_epis_diet.flg_help,
                                 dt_creation_in        => c_cur_epis_diet.dt_creation_tstz,
                                 dt_inicial_in         => c_cur_epis_diet.dt_initial_tstz,
                                 dt_end_in             => c_cur_epis_diet.dt_end_tstz,
                                 id_prof_cancel_in     => l_id_professional,
                                 notes_cancel_in       => l_notes_cancel,
                                 id_cancel_reason_in   => l_id_reason,
                                 flg_institution_in    => 'N',
                                 dt_initial_suspend_in => l_dt_initial_suspend,
                                 id_epis_diet_req_out  => l_id_diet);
        
            IF c_cur_epis_diet.id_diet IS NOT NULL
            THEN
                FOR i IN 1 .. 6
                LOOP
                    INSERT INTO epis_diet_det
                        (id_epis_diet_det, id_epis_diet_req, id_diet_schedule, id_diet)
                    VALUES
                        (seq_epis_diet_det.nextval, l_id_diet, i, c_cur_epis_diet.id_diet);
                END LOOP;
            END IF;
        END LOOP;
        RETURN TRUE;
    END;

    /**********************************************************************************************
    * check if diet can be executed or not (order sets feature)
    *
    * @param i_lang                  language id
    * @param i_prof                  professional details
    * @param i_diet                  id of diet to be checked
    * @param o_flg_conflict          conflict status 
    * @param o_error                 error message
    *
    * @return                        true on success, false otherwise
    *                        
    * @author                        Carlos Loureiro
    * @version                       1.0
    * @since                         2009/07/23
    **********************************************************************************************/
    FUNCTION check_diet_conflict
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_diet_type    IN diet_type.id_diet_type%TYPE,
        i_diet_ref     IN NUMBER,
        o_flg_conflict OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_type episode.id_epis_type%TYPE;
        l_count     NUMBER;
    BEGIN
        IF i_diet_type = g_diet_type_inst
        THEN
            BEGIN
                SELECT e.id_epis_type
                  INTO l_epis_type
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_epis_type := NULL;
            END;
            IF l_epis_type IN (g_epis_type_inpt, g_epis_type_edis)
            THEN
                o_flg_conflict := g_no;
            ELSE
                o_flg_conflict := g_yes;
            END IF;
        ELSE
            g_error := 'GET DIET CONFLICT STATUS';
            SELECT COUNT(1)
              INTO l_count
              FROM diet_prof_instit dpi
              JOIN diet_prof_pref dpp
                ON dpi.id_diet_prof_instit = dpp.id_diet_prof_instit
             WHERE dpi.id_diet_prof_instit = i_diet_ref
               AND dpp.flg_status = g_yes
               AND dpi.flg_status = g_flg_diet_status_a
               AND dpp.id_prof_pref = i_prof.id
               AND dpi.id_institution = i_prof.institution;
        
            IF l_count > 0
            THEN
                o_flg_conflict := g_no;
            ELSE
                o_flg_conflict := g_yes;
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
                                              'GET_DIET_PROF_PREF',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END check_diet_conflict;

    /**********************************************************************************************
    * Gets the list of active diets for kitchen
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_department         ID department
    * @param i_id_dep_serv           ID of department service
    *
    * @param o_diet                  Cursor with all active diets 
    * @param o_diet_totals           Cursor with the totals of diets
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/08/20
    **********************************************************************************************/

    FUNCTION get_active_diet_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN dept.id_dept%TYPE,
        i_id_dep_serv   IN department.id_department%TYPE,
        o_diet          OUT pk_types.cursor_type,
        o_diet_totals   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
        pk_alertlog.log_debug('PARAMS[:i_id_department' || i_id_department || ']',
                              g_package_name,
                              'GET_ACTIVE_DIET_LIST');
    
        g_error := 'OPEN CURSOR O_DIET';
        OPEN o_diet FOR
            SELECT DISTINCT *
              FROM (SELECT p.id_patient,
                           e.id_episode,
                           p.name patient_name,
                           edr.id_epis_diet_req id_diet,
                           decode(edr.flg_status,
                                  g_flg_diet_status_s,
                                  edr.dt_cancel,
                                  g_flg_diet_status_c,
                                  edr.dt_cancel,
                                  edr.dt_creation) dt_action,
                           decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, current_timestamp),
                                  'G',
                                  g_flg_diet_status_h,
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, current_timestamp),
                                         'L',
                                         g_flg_diet_status_f,
                                         g_flg_diet_status_a)) flg_status,
                           edr.id_diet_type,
                           ds.id_diet_schedule,
                           pk_translation.get_translation(i_lang, ds.code_diet_schedule) meal_name,
                           pk_translation.get_translation(i_lang, de.code_dept) department_name,
                           pk_translation.get_translation(i_lang, d.code_department) service_name,
                           nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) room_name,
                           nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) bed_name,
                           decode(edr.id_diet_type,
                                  g_diet_type_inst,
                                  pk_translation.get_translation(i_lang, dt.code_diet_type),
                                  edr.desc_diet) desc_diet_title,
                           edr.desc_diet,
                           r.id_room,
                           b.id_bed,
                           edr.notes,
                           edr.flg_help,
                           edr.flg_institution,
                           edr.food_plan,
                           pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                    ', d.code_diet) ||
                                    decode(' || edr.id_diet_type ||
                                                    ', 1,
                                           NULL,
                                           '', '' || edd2.quantity ||
                                           pk_translation.get_translation(' ||
                                                    i_lang ||
                                                    ', um.code_unit_measure) || ''; '' ||
                                           pk_diet.get_food_energy(edd2.quantity, d.quantity_default, d.energy_quantity_value) ||
                                           pk_translation.get_translation(' ||
                                                    i_lang ||
                                                    ', ume.code_unit_measure) ||
                                           decode(edd2.notes, NULL, ''.'', ''; '') || edd2.notes) food
                               FROM epis_diet_det edd2, diet d, unit_measure um, unit_measure ume
                              WHERE edd2.id_diet = d.id_diet
                                AND edd2.id_epis_diet_req = ' ||
                                                    edd.id_epis_diet_req || '
                                AND edd2.id_diet_schedule = ' ||
                                                    edd.id_diet_schedule || '
                                AND edd2.id_unit_measure = um.id_unit_measure(+)
                                AND d.id_unit_measure_energy = ume.id_unit_measure(+)
                              ORDER BY food',
                                                    '<br>') lst_food
                      FROM epis_diet_req edr,
                           epis_diet_det edd,
                           diet_type     dt,
                           diet_schedule ds,
                           episode       e,
                           epis_info     ei,
                           department    d,
                           room          r,
                           dept          de,
                           bed           b,
                           patient       p,
                           visit         v
                     WHERE edr.id_episode = e.id_episode
                       AND e.id_episode = ei.id_episode
                       AND d.id_department = i_id_dep_serv
                       AND edr.id_epis_diet_req = edd.id_epis_diet_req
                       AND edd.id_diet_schedule = ds.id_diet_schedule
                       AND ei.id_bed = b.id_bed
                       AND b.id_room = r.id_room
                       AND d.id_department = r.id_department
                       AND dt.id_diet_type = edr.id_diet_type
                       AND d.id_dept = de.id_dept
                       AND de.id_dept = i_id_department
                       AND ei.id_patient = p.id_patient
                       AND edr.flg_status = g_flg_diet_status_r
                       AND ei.flg_status NOT IN (g_episode_status_d, g_episode_status_m, g_episode_status_a)
                       AND e.id_visit = v.id_visit
                       AND v.flg_status != g_visit_status_i
                       AND NOT EXISTS (SELECT 1
                              FROM epis_diet_req e
                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                       AND edr.id_diet_type = dt.id_diet_type
                       AND rownum > 0)
             WHERE flg_status = g_flg_diet_status_a
             ORDER BY id_diet_type, id_diet_schedule, id_room;
    
        g_error := 'OPEN o_diet_totals';
        OPEN o_diet_totals FOR
            SELECT id_diet_type,
                   id_diet_schedule,
                   pk_translation.get_translation(i_lang, diet_parent) diet_parent_name,
                   pk_translation.get_translation(i_lang, diet_code) diet_name,
                   quantity,
                   pk_translation.get_translation(i_lang, unit_code) quantity_desc,
                   total,
                   id_diet_parent,
                   id_diet
              FROM (SELECT t.diet_code,
                           t.diet_parent,
                           SUM(t.quantity) quantity,
                           COUNT(1) total,
                           t.id_diet_type,
                           t.id_diet_schedule,
                           t.unit_code,
                           t.id_diet,
                           t.id_diet_parent
                      FROM (SELECT d.code_diet          diet_code,
                                   dp.code_diet         diet_parent,
                                   edd.quantity         quantity,
                                   dt.id_diet_type      id_diet_type,
                                   ds.id_diet_schedule  id_diet_schedule,
                                   um.code_unit_measure unit_code,
                                   d.id_diet            id_diet,
                                   dp.id_diet           id_diet_parent,
                                   edr.dt_inicial       dt_inicial,
                                   edr.dt_end           dt_end,
                                   dp.code_diet         dp_code_diet
                              FROM epis_diet_req edr,
                                   epis_diet_det edd,
                                   diet_type     dt,
                                   diet          d,
                                   diet          dp,
                                   diet_schedule ds,
                                   episode       e,
                                   epis_info     ei,
                                   department    d,
                                   room          r,
                                   dept          de,
                                   bed           b,
                                   patient       p,
                                   visit         v,
                                   unit_measure  um
                             WHERE edr.id_episode = e.id_episode
                               AND e.id_episode = ei.id_episode
                               AND d.id_department = i_id_dep_serv
                               AND edr.id_epis_diet_req = edd.id_epis_diet_req
                               AND edd.id_diet_schedule = ds.id_diet_schedule
                               AND edd.id_diet = d.id_diet
                               AND d.id_diet_parent = dp.id_diet(+)
                               AND ei.id_bed = b.id_bed
                               AND b.id_room = r.id_room
                               AND d.id_department = r.id_department
                               AND d.id_dept = de.id_dept
                               AND de.id_dept = i_id_department
                               AND ei.id_patient = p.id_patient
                               AND edr.flg_status = g_flg_diet_status_r
                               AND ei.flg_status NOT IN (g_episode_status_d, g_episode_status_m, g_episode_status_a)
                               AND e.id_visit = v.id_visit
                               AND v.flg_status != g_visit_status_i
                               AND edd.id_unit_measure = um.id_unit_measure(+)
                               AND NOT EXISTS (SELECT 1
                                      FROM epis_diet_req e
                                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                               AND edr.id_diet_type = dt.id_diet_type
                               AND rownum > 0) t
                     WHERE decode(pk_date_utils.compare_dates_tsz(i_prof, t.dt_inicial, current_timestamp),
                                  'G',
                                  g_flg_diet_status_h,
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, t.dt_end, current_timestamp),
                                         'L',
                                         g_flg_diet_status_f,
                                         g_flg_diet_status_a)) = g_flg_diet_status_a
                     GROUP BY t.id_diet_type,
                              t.id_diet_schedule,
                              t.diet_parent,
                              t.diet_code,
                              t.unit_code,
                              t.id_diet,
                              t.id_diet_parent)
             ORDER BY id_diet_type, id_diet_schedule, diet_parent_name, diet_name;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIVE_DIET_LIST',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_totals);
            RETURN FALSE;
        
    END get_active_diet_list;

    /**********************************************************************************************
    * Gets the last active diet of a episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @param o_diet                  Cursor with the last active diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Elisabete Bugalho
    * @version                       2.5
    * @since                         2009/09/01
    **********************************************************************************************/
    FUNCTION get_last_active_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_diet       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'OPEN o_diet';
        pk_alertlog.log_debug('PARAMS[:i_id_episode' || i_id_episode || ']', g_package_name, 'GET_LAST_ACTIVE_DIET');
        OPEN o_diet FOR
            SELECT id_diet,
                   pk_translation.get_translation(i_lang, code_diet_type) diet_type,
                   desc_diet,
                   flg_help,
                   pk_sysdomain.get_domain(g_yes_no, flg_help, i_lang) desc_help,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_inicial, i_prof) dt_initial,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_end, i_prof) dt_end
              FROM (SELECT edr.id_epis_diet_req id_diet,
                           edr.dt_creation      dt_action,
                           edr.id_diet_type,
                           code_diet_type,
                           edr.desc_diet,
                           edr.flg_help,
                           edr.dt_inicial,
                           edr.dt_end
                      FROM epis_diet_req edr, diet_type dt
                     WHERE edr.id_episode = i_id_episode
                       AND edr.flg_status IN (g_flg_diet_status_r)
                       AND NOT EXISTS
                     (SELECT 1
                              FROM epis_diet_req e
                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                       AND edr.id_diet_type = dt.id_diet_type
                       AND decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, current_timestamp),
                                  'G',
                                  g_flg_diet_status_h,
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, current_timestamp),
                                         'L',
                                         g_flg_diet_status_f,
                                         g_flg_diet_status_a)) = g_flg_diet_status_a
                     ORDER BY dt_action DESC)
             WHERE rownum = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_ACTIVE_DIET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            RETURN FALSE;
        
    END get_last_active_diet;

    /**********************************************************************************************
    * Returns 1 if is an nutritionist episode, 0 other else
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @return                        True or False
    *                        
    * @author                        Rita Lopes
    * @version                       2.5.0.6
    * @since                         2009/09/22
    **********************************************************************************************/
    FUNCTION get_nutritionist_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_episode    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_epis_type IS
            SELECT id_epis_type
              FROM episode
             WHERE id_episode = i_id_episode;
        --
        l_epis_type       epis_type.id_epis_type%TYPE;
        l_epis_type_nutri epis_type.id_epis_type%TYPE;
        --
    BEGIN
        g_error := 'OPEN C_EPIS_TYPE';
        OPEN c_epis_type;
        FETCH c_epis_type
            INTO l_epis_type;
        CLOSE c_epis_type;
    
        g_error           := 'EPIS_TYPE_NUTRI';
        l_epis_type_nutri := pk_sysconfig.get_config('ID_EPIS_TYPE_NUTRITIONIST', i_prof);
    
        IF l_epis_type = l_epis_type_nutri
        THEN
            o_episode := 1;
        ELSE
            o_episode := 0;
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
                                              'GET_NUTRITIONITS_EPISODE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_nutritionist_episode;

    /**********************************************************************************************
    * CPOE - Computerized physician order entry
    * Retrieves the diets list to be shown in the main CPOE grid 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_patient                patient id
    * @param i_episode                episode id
    * @param i_task_request           task id to be returned
    * @param i_filter_tstz            timestamp filter 
    * @param i_filter_status          status filter  
    * @param o_task_list              array with diets list
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2009/10/27
    **********************************************************************************************/
    FUNCTION get_task_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_varchar,
        i_flg_report    IN VARCHAR2 DEFAULT 'N',
        i_dt_begin      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_dt_end        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_plan_list     OUT pk_types.cursor_type,
        o_task_list     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --
    
        l_diet_active    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T086');
        l_diet_suspend   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T087');
        l_diet_completed sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T088');
        l_diet_state     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T084');
        l_diet_canceled  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T094');
        l_diet_schedule  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T095');
        l_diet_begin     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T112');
        l_diet_end       sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T113');
        l_diet_all_meal  sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T114');
        l_diet_notes     sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'DIET_T045');
    
        l_help sys_message.desc_message%TYPE := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T053');
    
        l_institution sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                              i_code_mess => 'DIET_T070');
    
        l_cancelled_task_filter_interval sys_config.value%TYPE := pk_sysconfig.get_config('CPOE_CANCELLED_TASK_FILTER_INTERVAL',
                                                                                          i_prof);
        l_cancelled_task_filter_tstz     TIMESTAMP WITH LOCAL TIME ZONE;
    
    BEGIN
    
        l_cancelled_task_filter_tstz := current_timestamp -
                                        numtodsinterval(to_number(l_cancelled_task_filter_interval), 'DAY');
        --
    
        pk_alertlog.log_debug('PARAMS[:i_patient:' || i_patient || ' :i_episode:' || i_episode || ' ]',
                              g_package_name,
                              'GET_TASK_LIST');
    
        g_sysdate_tstz := current_timestamp;
        OPEN o_task_list FOR
            SELECT task_type,
                   -- truncate task description to 600 characters
                   (CASE
                        WHEN length(task_description) > 600 THEN
                         substr(task_description, 1, 597) || '...'
                        ELSE
                         task_description
                    END) AS task_description,
                   id_professional,
                   icon_warning,
                   status_str,
                   id_request,
                   start_date_tstz,
                   end_date_tstz,
                   creation_date_tstz,
                   flg_status,
                   flg_cancel,
                   flg_conflit,
                   id_task,
                   --New Fields for CPOE API in Reports
                   --ALERT-78874 (AN)
                   task_title,
                   task_instructions,
                   task_notes,
                   NULL drug_dose,
                   NULL drug_route,
                   NULL drug_take_in_case,
                   task_status,
                   NULL AS instr_bg_color,
                   NULL AS instr_bg_alpha,
                   NULL AS task_icon,
                   pk_alert_constant.g_no AS flg_need_ack,
                   NULL AS edit_icon,
                   NULL AS action_desc,
                   NULL AS previous_status,
                   decode(id_task,
                          g_diet_type_inst,
                          pk_diet.g_odst_task_instit_diet,
                          g_diet_type_pers,
                          pk_diet.g_odst_task_predef_diet,
                          g_diet_type_defi,
                          pk_diet.g_odst_task_predef_diet) AS id_task_type_source,
                   NULL AS id_task_dependency,
                   decode(flg_status, g_flg_diet_status_c, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_rep_cancel,
                   'Y' flg_prn_conditional
              FROM (SELECT task_type,
                           (SELECT get_diet_description_internal2(i_lang,
                                                                  i_prof,
                                                                  id_epis_diet_req,
                                                                  g_diet_descr_format_l,
                                                                  pk_alert_constant.g_no,
                                                                  pk_alert_constant.g_yes,
                                                                  i_flg_report)
                              FROM dual) task_description,
                           id_professional,
                           icon_warning,
                           status_str,
                           id_request,
                           start_date_tstz,
                           end_date_tstz,
                           creation_date_tstz,
                           flg_status,
                           flg_cancel,
                           flg_conflit,
                           id_diet_type id_task,
                           --New Fields for CPOE API in Reports
                           --ALERT-78874 (AN)
                           decode(i_flg_report,
                                  pk_alert_constant.g_yes,
                                  (SELECT get_diet_description_internal(i_lang,
                                                                        i_prof,
                                                                        id_diet_type,
                                                                        desc_diet,
                                                                        pk_alert_constant.g_no)
                                     FROM dual)) task_title,
                           decode(i_flg_report,
                                   pk_alert_constant.g_yes,
                                   CASE
                                       WHEN length(status_desc || task_food_instructions) > 1000 THEN
                                        substr(status_desc || task_food_instructions, 1, 997) || '...'
                                       ELSE
                                        status_desc || task_food_instructions
                                   END) task_instructions,
                           decode(i_flg_report,
                                  pk_alert_constant.g_yes,
                                  decode(desc_help_title, NULL, NULL, desc_help_title || chr(13)) ||
                                  decode(desc_institution, NULL, NULL, desc_institution || chr(13)) || notes) task_notes,
                           decode(i_flg_report, pk_alert_constant.g_yes, task_status) task_status,
                           decode(i_flg_report, pk_alert_constant.g_yes, task_status) status_desc
                      FROM (SELECT task_type,
                                   id_epis_diet_req,
                                   id_diet_type,
                                   desc_diet,
                                   id_professional,
                                   icon_warning,
                                   status_str,
                                   id_request,
                                   start_date_tstz,
                                   end_date_tstz,
                                   creation_date_tstz,
                                   flg_status,
                                   flg_cancel,
                                   flg_conflit,
                                   notes,
                                   cancel_date_tstz,
                                   --New Fields for CPOE API in Reports
                                   --ALERT-78874 (AN)
                                   (SELECT get_diet_description_internal(i_lang, i_prof, id_diet_type, desc_diet)
                                      FROM dual) diet_description,
                                   (SELECT get_task_instructions_internal(i_lang,
                                                                          i_prof,
                                                                          id_request,
                                                                          pk_alert_constant.g_yes)
                                      FROM dual) task_instructions,
                                   decode(i_flg_report,
                                          pk_alert_constant.g_yes,
                                          get_task_food_instructions(i_lang, i_prof, id_request, chr(13))) task_food_instructions,
                                   decode(i_flg_report,
                                          pk_alert_constant.g_yes,
                                          decode(flg_help,
                                                 NULL,
                                                 NULL,
                                                 l_help || ' ' || pk_sysdomain.get_domain(g_yes_no, flg_help, i_lang))) desc_help_title,
                                   decode(i_flg_report,
                                          pk_alert_constant.g_yes,
                                          decode(flg_institution,
                                                 NULL,
                                                 NULL,
                                                 l_institution || ' ' ||
                                                 pk_sysdomain.get_domain(g_yes_no, flg_institution, i_lang))) desc_institution,
                                   task_status,
                                   status_desc
                              FROM (SELECT edr.id_diet_type task_type,
                                           edr.id_epis_diet_req,
                                           edr.id_diet_type,
                                           edr.desc_diet,
                                           decode(edr.flg_status,
                                                  g_flg_diet_status_i,
                                                  edr.id_prof_cancel,
                                                  g_flg_diet_status_c,
                                                  edr.id_prof_cancel,
                                                  edr.id_professional) id_professional,
                                           '' icon_warning,
                                           (SELECT get_diet_status_internal(i_lang, i_prof, edr.id_epis_diet_req)
                                              FROM dual) status_str,
                                           edr.id_epis_diet_req id_request,
                                           edr.dt_inicial start_date_tstz,
                                           edr.dt_end end_date_tstz,
                                           decode(edr.flg_status,
                                                  g_flg_diet_status_i,
                                                  edr.dt_cancel,
                                                  g_flg_diet_status_c,
                                                  edr.dt_cancel,
                                                  edr.dt_creation) creation_date_tstz,
                                           (SELECT get_processed_diet_status(i_lang,
                                                                             i_prof,
                                                                             edr.id_epis_diet_req,
                                                                             g_status_type_c)
                                              FROM dual) flg_status,
                                           decode(edr.flg_status,
                                                  g_flg_diet_status_s,
                                                  3,
                                                  g_flg_diet_status_c,
                                                  6,
                                                  g_flg_diet_status_x,
                                                  5,
                                                  g_flg_diet_status_t,
                                                  7,
                                                  decode(pk_date_utils.compare_dates_tsz(i_prof,
                                                                                         edr.dt_inicial,
                                                                                         g_sysdate_tstz),
                                                         'G',
                                                         2,
                                                         decode(pk_date_utils.compare_dates_tsz(i_prof,
                                                                                                edr.dt_end,
                                                                                                g_sysdate_tstz),
                                                                'L',
                                                                4,
                                                                1))) rank,
                                           --diets that can be cancelled: all expect 
                                           decode(edr.flg_status,
                                                  g_flg_diet_status_c,
                                                  g_no,
                                                  g_flg_diet_status_f,
                                                  g_no,
                                                  g_flg_diet_status_s,
                                                  g_no,
                                                  g_flg_diet_status_x,
                                                  g_no,
                                                  decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                                         g_flg_date_l,
                                                         g_no,
                                                         g_yes)) flg_cancel,
                                           --get_drafts_conflicts(i_lang, i_prof, i_episode, edr.id_epis_diet_req) 
                                           --according to the client requests, there are no conflicts in the diets activation
                                           --OA 17/09/2010.
                                           g_no          flg_conflit,
                                           edr.notes,
                                           edr.dt_cancel cancel_date_tstz,
                                           --New Fields for CPOE API in Reports
                                           --ALERT-78874 (AN)
                                           edr.flg_help,
                                           edr.flg_institution,
                                           decode(i_flg_report,
                                                  pk_alert_constant.g_yes,
                                                  get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req)) task_status,
                                           decode(edr.flg_status,
                                                  g_flg_diet_status_s,
                                                  pk_message.get_message(i_lang, 'REP_COMM_ORDERS_REVIEW_002') || ' - ',
                                                  NULL) status_desc
                                      FROM epis_diet_req edr, diet_type dt
                                     WHERE edr.id_patient = i_patient
                                       AND NOT EXISTS (SELECT 1
                                              FROM epis_diet_req e
                                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                                       AND edr.flg_status != g_flg_diet_status_o
                                       AND edr.id_diet_type = dt.id_diet_type
                                       AND edr.id_episode IN
                                           (SELECT id_episode
                                              FROM episode
                                             WHERE id_visit = pk_episode.get_id_visit(i_episode)))
                             WHERE (flg_status NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                        t.column_value
                                                         FROM TABLE(i_filter_status) t) OR
                                   (end_date_tstz > i_filter_tstz AND flg_status != g_flg_diet_status_c) OR
                                   (cancel_date_tstz > l_cancelled_task_filter_tstz AND flg_status = g_flg_diet_status_c))
                               AND (i_task_request IS NULL OR
                                   id_epis_diet_req IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                                          d.column_value
                                                           FROM TABLE(i_task_request) d))
                             ORDER BY rank, start_date_tstz));
    
        IF i_flg_report = pk_alert_constant.g_yes
        THEN
        
            IF NOT get_order_plan_report(i_lang          => i_lang,
                                         i_prof          => i_prof,
                                         i_episode       => i_episode,
                                         i_task_request  => i_task_request,
                                         i_cpoe_dt_begin => i_dt_begin,
                                         i_cpoe_dt_end   => i_dt_end,
                                         o_plan_rep      => o_plan_list,
                                         o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASK_LIST',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_task_list;
    --

    /*
    * Build status string for diet requests.
    * Used internally, and for EA logic only.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_flg_status     diet request status
    * @param i_dt_inicial     diet start date
    * @param i_sys_date       system date
    * @param o_status_str     string
    * @param o_status_msg     message code
    * @param o_status_icon    icon
    * @param o_status_flg     flag
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.2
    * @since                  2012/04/19
    */
    PROCEDURE build_status_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_status  IN epis_diet_req.flg_status%TYPE,
        i_dt_inicial  IN epis_diet_req.dt_inicial%TYPE,
        i_sys_date    IN epis_diet_req.dt_inicial%TYPE,
        o_status_str  OUT sys_domain.desc_val%TYPE,
        o_status_msg  OUT sys_domain.code_domain%TYPE,
        o_status_icon OUT sys_domain.img_name%TYPE,
        o_status_flg  OUT sys_domain.val%TYPE
    ) IS
        l_display_type VARCHAR2(2 CHAR);
        l_value_date   sys_domain.desc_val%TYPE;
        l_value_icon   sys_domain.code_domain%TYPE;
        l_back_color   VARCHAR2(8 CHAR);
    BEGIN
        IF i_flg_status = g_flg_diet_status_h
        THEN
            l_display_type := pk_alert_constant.g_display_type_date;
            l_value_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_dt_inicial, i_prof => i_prof);
            l_value_icon   := NULL;
            l_back_color   := pk_alert_constant.g_color_green;
        ELSIF i_flg_status = g_flg_diet_status_x
        THEN
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_value_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_sys_date, i_prof => i_prof);
            l_value_icon   := 'EPIS_DIET_REQ.FLG_STATUS';
            l_back_color   := NULL;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
            l_value_date   := pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => i_sys_date, i_prof => i_prof);
            l_value_icon   := 'EPIS_DIET_REQ.FLG_STATUS';
            l_back_color   := NULL;
        END IF;
    
        pk_utils.build_status_string(i_display_type => l_display_type,
                                     i_flg_state    => i_flg_status,
                                     i_value_date   => l_value_date,
                                     i_value_icon   => l_value_icon,
                                     i_back_color   => l_back_color,
                                     o_status_str   => o_status_str,
                                     o_status_msg   => o_status_msg,
                                     o_status_icon  => o_status_icon,
                                     o_status_flg   => o_status_flg);
    END build_status_str;

    /**********************************************************************************************
    * Gets the status string for all the diets status
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_flg_status             diet flag status
    * @param i_dt_inicial             diet begin date
    * @param i_dt_end                 diet end date
    * @param i_sys_date               current system date
    * @param o_error                  Error message
    *
    * @return                         the 'normalized' status string
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2009/10/27
    **********************************************************************************************/
    FUNCTION get_diet_status_str
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_status IN epis_diet_req.flg_status%TYPE,
        i_dt_inicial IN epis_diet_req.dt_inicial%TYPE,
        i_dt_end     IN epis_diet_req.dt_end%TYPE,
        i_sys_date   IN epis_diet_req.dt_inicial%TYPE
    ) RETURN VARCHAR IS
        --
        l_error       t_error_out;
        l_status_str  sys_domain.desc_val%TYPE;
        l_status_msg  sys_domain.code_domain%TYPE;
        l_status_icon sys_domain.img_name%TYPE;
        l_status_flg  sys_domain.val%TYPE;
    BEGIN
        --
    
        pk_alertlog.log_debug('PARAMS[:i_flg_status:' || i_flg_status || ' :i_dt_inicial:' || i_dt_inicial ||
                              ' :i_sys_date:' || i_sys_date || ' ]',
                              g_package_name,
                              'get_diet_status_str');
    
        build_status_str(i_lang        => i_lang,
                         i_prof        => i_prof,
                         i_flg_status  => i_flg_status,
                         i_dt_inicial  => i_dt_inicial,
                         i_sys_date    => i_sys_date,
                         o_status_str  => l_status_str,
                         o_status_msg  => l_status_msg,
                         o_status_icon => l_status_icon,
                         o_status_flg  => l_status_flg);
    
        RETURN pk_utils.get_status_string(i_lang        => i_lang,
                                          i_prof        => i_prof,
                                          i_status_str  => l_status_str,
                                          i_status_msg  => l_status_msg,
                                          i_status_icon => l_status_icon,
                                          i_status_flg  => l_status_flg);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DIET_STATUS_STR',
                                              o_error    => l_error);
            pk_alert_exceptions.reset_error_state;
            RETURN NULL;
    END get_diet_status_str;
    --

    /*----------------------CPOE development-------------------------------*/
    /******************************************************************************************** 
    * synchronize requested task with cpoe processes  
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_task_type               cpoe task type id 
    * @param       i_task_request            task request id (also used for drafts) 
    * @param       i_task_request_old        task request id for previous diet state, when applicable
    * @param       i_dt_task                 Date task sync
    * @param       o_error                   error message 
    * 
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Orlando Antunes
    * @version                        1.0
    * @since                          2009/11/16    
    ********************************************************************************************/
    FUNCTION sync_task
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_task_type        IN cpoe_task_type.id_task_type%TYPE,
        i_task_request     IN cpoe_process_task.id_task_request%TYPE,
        i_task_request_old IN cpoe_process_task.id_task_request%TYPE DEFAULT NULL,
        i_dt_task          IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_task_type_cpoe cpoe_task_type.id_task_type%TYPE;
    BEGIN
    
        pk_alertlog.log_debug('SYNC_TASK: task_type = ' || i_task_type || ', i_task_request = ' || i_task_request);
        --convertion between diet types and cpoe diet types
        CASE
            WHEN i_task_type = g_diet_type_inst THEN
                l_task_type_cpoe := g_cpoe_diet_type_inst;
            WHEN i_task_type = g_diet_type_pers THEN
                l_task_type_cpoe := g_cpoe_diet_type_pers;
            ELSE
                l_task_type_cpoe := g_cpoe_diet_type_defi;
        END CASE;
    
        IF i_task_request_old IS NOT NULL
        THEN
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => l_task_type_cpoe,
                                     i_old_task_request     => i_task_request_old,
                                     i_new_task_request     => i_task_request,
                                     i_task_start_timestamp => i_dt_task,
                                     o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                     i_prof                 => i_prof,
                                     i_episode              => i_episode,
                                     i_task_type            => l_task_type_cpoe,
                                     i_task_request         => i_task_request,
                                     i_task_start_timestamp => i_dt_task,
                                     o_error                => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SYNC_TASK',
                                              o_error    => o_error);
            RETURN FALSE;
    END sync_task;
    --

    /**********************************************************************************************
    * Creates one diet for the patient, in draf state
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       Flg institution
    * @param i_resume_notes          Resume notes
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16
    **********************************************************************************************/
    FUNCTION create_draft
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'Y',
        i_resume_notes       IN epis_diet_req.resume_notes%TYPE DEFAULT NULL,
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin_tstz    TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_rows             table_varchar;
        l_rows_det         table_varchar;
        l_id_epis_diet_req epis_diet_req.id_epis_diet_req%TYPE;
        l_id_epis_diet_det epis_diet_det.id_epis_diet_det%TYPE;
    
        CURSOR c_epis_type IS
            SELECT e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        CURSOR c_diet_name IS
            SELECT pk_translation.get_translation(i_lang, code_diet_type)
              FROM diet_type
             WHERE id_diet_type = i_id_diet_type;
    
        CURSOR c_diet_status IS
            SELECT flg_status
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_epis_diet;
    
        l_epis_type       episode.id_epis_type%TYPE;
        l_active_diet     VARCHAR2(4000);
        l_diet_name       epis_diet_req.desc_diet%TYPE;
        l_notes_cancel    sys_message.desc_message%TYPE;
        l_flg_institution epis_diet_req.flg_institution%TYPE;
        l_diet_status_cur epis_diet_req.flg_status%TYPE;
        l_diet_status     epis_diet_req.flg_status%TYPE;
        l_dt_begin_str    VARCHAR2(14);
        l_dt_end_str      VARCHAR2(14);
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    BEGIN
        pk_alertlog.log_debug('CREATE_EPIS_DIET', g_package_name);
        g_error := 'CONVERT DATES';
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        l_dt_begin_str := i_dt_begin_str;
    
        IF i_dt_end_str IS NOT NULL
        THEN
            IF substr(i_dt_end_str, 1, 8) = substr(i_dt_begin_str, 1, 8)
            THEN
                l_dt_end_str := substr(i_dt_end_str, 1, 8) || '235900';
            ELSE
                l_dt_end_str := substr(i_dt_end_str, 1, 8) || '000000';
            END IF;
        ELSE
            l_dt_end_str := i_dt_end_str;
        END IF;
    
        l_dt_begin_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_begin_str, NULL);
        l_dt_end_tstz   := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_end_str, NULL);
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        l_notes_cancel := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_M014');
    
        g_error := 'OPEN c_epis_type';
        --TODO: create function
        OPEN c_epis_type;
        FETCH c_epis_type
            INTO l_epis_type;
        CLOSE c_epis_type;
    
        --TODO: create function
        IF i_id_diet_type = g_diet_type_inst
        THEN
            g_error := 'OPEN c_diet_name';
            OPEN c_diet_name;
            FETCH c_diet_name
                INTO l_diet_name;
            CLOSE c_diet_name;
        ELSE
            l_diet_name := i_desc_diet;
        END IF;
    
        IF l_epis_type IN (g_epis_type_inpt, g_epis_type_edis)
        THEN
            l_flg_institution := nvl(i_flg_institution, g_no);
        ELSE
            l_flg_institution := nvl(i_flg_institution, g_yes);
        END IF;
    
        g_error := 'CALL TS_EPIS_DIET_REQ.INS';
        ts_epis_diet_req.ins(id_diet_type_in            => i_id_diet_type,
                             id_episode_in              => i_episode,
                             id_patient_in              => i_patient,
                             id_professional_in         => i_prof.id,
                             desc_diet_in               => i_desc_diet,
                             flg_status_in              => g_flg_diet_status_t,
                             notes_in                   => i_notes,
                             food_plan_in               => i_food_plan,
                             flg_help_in                => i_flg_help,
                             dt_creation_in             => g_sysdate_tstz,
                             dt_inicial_in              => l_dt_begin_tstz,
                             dt_end_in                  => l_dt_end_tstz,
                             flg_institution_in         => i_flg_institution,
                             id_diet_prof_instit_in     => i_id_diet_predefined,
                             id_epis_diet_req_parent_in => i_id_epis_diet,
                             resume_notes_in            => i_resume_notes,
                             id_epis_diet_req_out       => o_id_epis_diet,
                             rows_out                   => l_rows);
        pk_alertlog.log_debug('CREATE_EPIS_DIET: Inserted draft diet:' || o_id_epis_diet,
                              g_package_name,
                              'CREATE_EPIS_DIET');
    
        IF i_id_diet_schedule.count > 0
        THEN
            -- insert the diet detail
            FOR i IN i_id_diet_schedule.first .. i_id_diet_schedule.last
            LOOP
                IF i_id_diet(i) IS NOT NULL
                THEN
                    g_error := 'CALL ts_epis_diet_det.ins';
                    ts_epis_diet_det.ins(id_epis_diet_req_in  => o_id_epis_diet,
                                         notes_in             => i_notes_diet(i),
                                         id_diet_schedule_in  => i_id_diet_schedule(i),
                                         dt_diet_schedule_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                               i_prof,
                                                                                               i_dt_hour(i),
                                                                                               NULL),
                                         id_diet_in           => i_id_diet(i),
                                         quantity_in          => i_quantity(i),
                                         id_unit_measure_in   => i_id_unit(i),
                                         id_epis_diet_det_out => l_id_epis_diet_det,
                                         rows_out             => l_rows_det);
                END IF;
            END LOOP;
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := i_patient;
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        pk_alertlog.log_debug('CREATE_EPIS_DIET: Inserted draft diet_det ' || i_id_diet_schedule.count || ' records',
                              g_package_name,
                              'CREATE_EPIS_DIET');
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_DRAFT',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CREATE_EPIS_DIET');
            RETURN FALSE;
    END create_draft;
    --
    /**********************************************************************************************
    * Deletes diets for the patient. The diets to delete must be in draf/temporary state.
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_episode               ID Episode
    * @param i_draf                  List of draft deits to delete
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/13
    **********************************************************************************************/
    FUNCTION cancel_draft
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN table_number,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        --related
        l_epis_diet_det_ids    table_number;
        l_hie_id_epis_diet_req table_number;
        l_epis_diet_det_state  epis_diet_req.flg_status%TYPE;
    
    BEGIN
        pk_alertlog.log_debug('DELETE DRAFT/TEMPORARY', g_package_name);
    
        FOR i IN i_draft.first .. i_draft.last
        LOOP
            --validate the draft state
            SELECT edr.flg_status
              INTO l_epis_diet_det_state
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_draft(i);
        
            pk_alertlog.log_debug('CURRENT DIET STATE: ' || l_epis_diet_det_state,
                                  g_package_name,
                                  'DELETE DRAFT/TEMPORARY DIET');
            --
            g_error := 'Diet ' || i_draft(i) || ' is not in draft/temporary state.';
            IF l_epis_diet_det_state NOT IN (g_flg_diet_status_t, g_flg_diet_status_o)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error := 'Get all details for Diet ' || i_draft(i);
            --delete diet drat details:
            SELECT edd.id_epis_diet_det
              BULK COLLECT
              INTO l_epis_diet_det_ids
              FROM epis_diet_det edd
             WHERE edd.id_epis_diet_req = i_draft(i);
        
            g_error := 'Delete all details for Diet ' || i_draft(i) || '. Number of detais: ' ||
                       l_epis_diet_det_ids.count;
            --Delete all details for this Diet!
            IF l_epis_diet_det_ids.count > 0
            THEN
                FOR j IN l_epis_diet_det_ids.first .. l_epis_diet_det_ids.last
                LOOP
                    ts_epis_diet_det.del(id_epis_diet_det_in => l_epis_diet_det_ids(j));
                    pk_alertlog.log_debug('DELETE DRAFT/TEMPORARY DIET DET: :' || l_epis_diet_det_ids(j),
                                          g_package_name,
                                          'DELETE DRAFT/TEMPORARY DIET');
                
                END LOOP;
                --End of Delete all details for this Diet!
            END IF;
        
            --remove all history
            SELECT edr.id_epis_diet_req
              BULK COLLECT
              INTO l_hie_id_epis_diet_req
              FROM epis_diet_req edr
             START WITH edr.id_epis_diet_req = i_draft(i)
            CONNECT BY PRIOR edr.id_epis_diet_req_parent = edr.id_epis_diet_req;
        
            IF l_hie_id_epis_diet_req.count > 0
            THEN
                FOR k IN l_hie_id_epis_diet_req.first .. l_hie_id_epis_diet_req.last
                LOOP
                    ts_epis_diet_req.del(id_epis_diet_req_in => l_hie_id_epis_diet_req(k));
                END LOOP;
            END IF;
        
            pk_alertlog.log_debug('DELETE DRAFT/TEMPORARY DIET: Deleted draft/temporary diet:' || i_draft(i),
                                  g_package_name,
                                  'DELETE DRAFT/TEMPORARY DIET');
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
                                              'CANCEL_DRAFT',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CANCEL_DRAFT');
            RETURN FALSE;
    END cancel_draft;
    --

    /******************************************************************************************** 
    * Creates new records in diets tabels to keep the histoty of changes 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_diets                   array of selected draft diets  
    * @param       i_flg_commit              transaction control 
    * @param       o_error                   error message 
    * 
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction 
    *                                        {*} 'N' transaction control is done outside  
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/19
    **********************************************************************************************/
    FUNCTION create_diet_history
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_commit IN VARCHAR2 DEFAULT 'N',
        o_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diet(i_id_diet epis_diet_req.id_epis_diet_req%TYPE) IS
            SELECT id_patient, id_diet_type, desc_diet, food_plan, flg_help, notes, flg_institution, dt_inicial, dt_end
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_diet;
        --     
        l_diet             c_diet%ROWTYPE;
        l_diet_req         epis_diet_req.id_epis_diet_req%TYPE;
        l_id_diet_schedule table_number;
        l_id_diet          table_number;
        l_dt_hour          table_varchar;
        l_quantity         table_number;
        l_id_unit          table_number;
        l_notes_diet       table_varchar;
    
    BEGIN
        pk_alertlog.log_debug('CREATE DIET HISTORY', g_package_name);
    
        --  create_epis_diet(i_lang => i_lang
        --Get current diet information
        g_error := 'OPEN CURSOR C_DIET';
        OPEN c_diet(i_diet);
        FETCH c_diet
            INTO l_diet;
        CLOSE c_diet;
        ----Get current diet details information
        g_error := 'GET DIET DETAIL';
        SELECT id_diet_schedule,
               id_diet,
               pk_date_utils.to_char_insttimezone(i_prof, dt_diet_schedule, 'YYYYMMDDHH24MISS'),
               quantity,
               id_unit_measure,
               notes
          BULK COLLECT
          INTO l_id_diet_schedule, l_id_diet, l_dt_hour, l_quantity, l_id_unit, l_notes_diet
          FROM epis_diet_det
         WHERE id_epis_diet_req = i_diet;
    
        --Insert new record for the diet, with the previous one as parent!
        g_error := 'CREATE EPIS_DIET';
        IF NOT create_epis_diet(i_lang               => i_lang,
                                i_prof               => i_prof,
                                i_patient            => l_diet.id_patient,
                                i_episode            => i_episode,
                                i_id_epis_diet       => i_diet,
                                i_id_diet_type       => l_diet.id_diet_type,
                                i_desc_diet          => l_diet.desc_diet,
                                i_dt_begin_str       => pk_date_utils.date_send_tsz(i_lang,
                                                                                    l_diet.dt_inicial,
                                                                                    i_prof.institution,
                                                                                    i_prof.software),
                                i_dt_end_str         => pk_date_utils.date_send_tsz(i_lang,
                                                                                    l_diet.dt_end,
                                                                                    i_prof.institution,
                                                                                    i_prof.software),
                                i_food_plan          => l_diet.food_plan,
                                i_flg_help           => l_diet.flg_help,
                                i_notes              => l_diet.notes,
                                i_id_diet_predefined => NULL,
                                i_id_diet_schedule   => l_id_diet_schedule,
                                i_id_diet            => l_id_diet,
                                i_quantity           => l_quantity,
                                i_id_unit            => l_id_unit,
                                i_notes_diet         => l_notes_diet,
                                i_dt_hour            => l_dt_hour,
                                i_flg_institution    => l_diet.flg_institution,
                                i_resume_notes       => NULL,
                                o_id_epis_diet       => o_diet,
                                o_error              => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlcode);
        END IF;
    
        pk_alertlog.log_debug('CREATE DIET HISTORY:' || i_diet, g_package_name, 'CREATE DIET HISTORY');
    
        IF i_flg_commit = 'Y'
        THEN
            COMMIT;
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
                                              'CREATE_DIET_HISTORY',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CREATE_DIET_HISTORY');
            RETURN FALSE;
    END create_diet_history;
    --

    /******************************************************************************************** 
    * activates a set of draft Diets (task goes from draft to active workflow) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draft                   array of selected draft diets  
    * @param       i_flg_commit              transaction control
    * @param       o_created_tasks           array of created taksk requests       
    * @param       o_error                   error message 
    * 
    * @value       i_flg_commit              {*} 'Y' commit/rollback the transaction 
    *                                        {*} 'N' transaction control is done outside  
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/13
    **********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        i_flg_commit    IN VARCHAR2,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_req epis_diet_req.id_epis_diet_req%TYPE;
    
        CURSOR c_diet(i_id_diet epis_diet_req.id_epis_diet_req%TYPE) IS
            SELECT id_diet_type, dt_inicial, dt_end
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_diet;
    
        l_id_diet_type  epis_diet_req.id_diet_type%TYPE;
        l_dt_begin      epis_diet_req.dt_inicial%TYPE;
        l_dt_end        epis_diet_req.dt_end%TYPE;
        l_rows          table_varchar;
        l_created_tasks table_number := table_number();
        l_dt_task       TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_task_type       cpoe_task_type.id_task_type%TYPE;
        l_count_rel_tasks NUMBER;
    
        l_draft          table_number;
        l_id_request_val interv_presc_det.id_interv_presc_det%TYPE;
        l_exception EXCEPTION;
    BEGIN
        pk_alertlog.log_debug('ACTIVATE DRAFT', g_package_name);
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN i_draft.first .. i_draft.last
        LOOP
        
            BEGIN
                SELECT a.id_task_orig, a.id_task_type
                  INTO l_count_rel_tasks, l_task_type
                  FROM cpoe_tasks_relation a
                 WHERE a.id_task_dest = i_draft(i)
                   AND a.id_task_type IN (pk_cpoe.g_task_type_diet,
                                          pk_cpoe.g_task_type_diet_inst,
                                          pk_cpoe.g_task_type_diet_spec,
                                          pk_cpoe.g_task_type_diet_predefined)
                   AND a.flg_type = 'AD';
            EXCEPTION
                WHEN no_data_found THEN
                    l_count_rel_tasks := 0;
            END;
        
            IF l_count_rel_tasks > 0
            THEN
                SELECT m.dt_end
                  INTO l_dt_end
                  FROM epis_diet_req m
                 WHERE m.id_epis_diet_req = l_count_rel_tasks;
            END IF;
        
            IF l_count_rel_tasks > 0
               AND (l_dt_end IS NULL OR (l_dt_end IS NOT NULL AND l_dt_end > g_sysdate_tstz))
            THEN
            
                IF NOT pk_cpoe.sync_active_to_next(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_episode   => i_episode,
                                                   i_task_type => l_task_type,
                                                   i_request   => i_draft(i),
                                                   o_error     => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                l_draft := i_draft;
            
                FOR i IN 1 .. l_draft.count
                LOOP
                    IF l_draft(i) = i_draft(i)
                    THEN
                        SELECT a.id_task_orig
                          INTO l_id_request_val
                          FROM cpoe_tasks_relation a
                         WHERE a.id_task_dest = i_draft(i);
                        l_draft(i) := l_id_request_val;
                    END IF;
                END LOOP;
            
                IF NOT cancel_draft(i_lang    => i_lang,
                                    i_prof    => i_prof,
                                    i_episode => i_episode,
                                    i_draft   => table_number(i_draft(i)),
                                    o_error   => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                o_created_tasks := l_draft;
            
                RETURN TRUE;
            END IF;
        
            IF NOT create_diet_history(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => NULL,
                                       i_episode => i_episode,
                                       i_diet    => i_draft(i),
                                       o_diet    => l_diet_req,
                                       o_error   => o_error)
            
            THEN
                RAISE g_exception;
            END IF;
        
            --update the dt_begin and dt_end of the prescription, if the start date in greater than the current date.
            --get diet type
            OPEN c_diet(l_diet_req);
            FETCH c_diet
                INTO l_id_diet_type, l_dt_begin, l_dt_end;
            CLOSE c_diet;
        
            IF l_dt_begin IS NOT NULL
               AND l_dt_begin < pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz)
            THEN
                pk_alertlog.log_debug('ACTIVATE DRAFT DIET: Activated draft diet:' || l_diet_req,
                                      g_package_name,
                                      'ACTIVATE DRAFT DIET');
                ts_epis_diet_req.upd(id_epis_diet_req_in => l_diet_req,
                                     flg_status_in       => g_flg_diet_status_r,
                                     dt_inicial_in       => pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz),
                                     dt_end_in           => CASE
                                                                WHEN l_dt_end IS NOT NULL THEN
                                                                 l_dt_end + (pk_date_utils.trunc_insttimezone(i_prof, g_sysdate_tstz) -
                                                                 l_dt_begin)
                                                                ELSE
                                                                 NULL
                                                            END,
                                     rows_out            => l_rows);
            
                l_dt_task := g_sysdate_tstz;
            ELSE
                pk_alertlog.log_debug('ACTIVATE DRAFT DIET: Activated draft diet:' || l_diet_req,
                                      g_package_name,
                                      'ACTIVATE DRAFT DIET');
                ts_epis_diet_req.upd(id_epis_diet_req_in => l_diet_req,
                                     flg_status_in       => g_flg_diet_status_r,
                                     rows_out            => l_rows);
            
                l_dt_task := l_dt_begin;
            END IF;
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            --Synchronize CPOE tasks for draft diets
            g_error := 'CALL SYNC_TASK : ' || l_diet_req;
            IF NOT sync_task(i_lang         => i_lang,
                             i_prof         => i_prof,
                             i_episode      => i_episode,
                             i_task_type    => l_id_diet_type,
                             i_task_request => l_diet_req,
                             i_dt_task      => l_dt_task,
                             o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_created_tasks.extend;
            l_created_tasks(i) := l_diet_req;
        END LOOP;
    
        --
        IF i_flg_commit = 'Y'
        THEN
            COMMIT;
        END IF;
        o_created_tasks := l_created_tasks;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'ACTIVATE_DRAFTS');
            RETURN FALSE;
    END activate_drafts;
    --

    /******************************************************************************************** 
    * Set the select diet in an expired state 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16    
    ********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_req epis_diet_req.id_epis_diet_req%TYPE;
    BEGIN
        pk_alertlog.log_debug('EXPIRE TASK', g_package_name);
    
        FOR i IN i_task_requests.first .. i_task_requests.last
        LOOP
            IF NOT expire_task(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_episode      => i_episode,
                               i_task_request => i_task_requests(i),
                               o_error        => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'EXPIRE_TASK',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'EXPIRE_TASK');
            RETURN FALSE;
    END expire_task;
    --

    /******************************************************************************************** 
    * Set the select diet in an expired state 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16    
    ********************************************************************************************/
    FUNCTION expire_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_req epis_diet_req.id_epis_diet_req%TYPE;
        l_rows     table_varchar;
    
        CURSOR c_diet IS
            SELECT id_patient, id_diet_type
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_task_request;
        l_diet c_diet%ROWTYPE;
    
    BEGIN
        pk_alertlog.log_debug('EXPIRE TASK', g_package_name);
    
        IF get_processed_diet_status(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_diet        => i_task_request,
                                     i_status_type => g_status_type_f) IN
           (g_flg_diet_status_c, g_flg_diet_status_f, g_flg_diet_status_i, g_flg_diet_status_x)
        THEN
            pk_alertlog.log_debug('The diet ' || i_task_request || ' cannot be expired.',
                                  g_package_name,
                                  'EXPIRE TASK DIET');
        ELSE
            g_error := 'OPEN CURSOR C_DIET';
            OPEN c_diet;
            FETCH c_diet
                INTO l_diet;
            CLOSE c_diet;
        
            IF NOT create_diet_history(i_lang    => i_lang,
                                       i_prof    => i_prof,
                                       i_patient => NULL,
                                       i_episode => i_episode,
                                       i_diet    => i_task_request,
                                       o_diet    => l_diet_req,
                                       o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
            --TODO: validate this implementation
            --TODO: validate this implementation
            ts_epis_diet_req.upd(id_epis_diet_req_in => i_task_request,
                                 flg_status_in       => g_flg_diet_status_x,
                                 dt_end_in           => g_sysdate_tstz,
                                 rows_out            => l_rows);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_DIET_REQ',
                                          i_rowids     => l_rows,
                                          o_error      => o_error);
        
            --Synchronize CPOE tasks
            g_error := 'CALL SYNC_TASK : ' || l_diet_req;
            IF NOT sync_task(i_lang             => i_lang,
                             i_prof             => i_prof,
                             i_episode          => i_episode,
                             i_task_type        => l_diet.id_diet_type,
                             i_task_request     => l_diet_req,
                             i_task_request_old => i_task_request,
                             i_dt_task          => g_sysdate_tstz,
                             o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            pk_alertlog.log_debug('EXPIRE TASK DIET: expired diet:' || l_diet_req, g_package_name, 'EXPIRE TASK DIET');
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
                                              'EXPIRE_TASK',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'EXPIRE_TASK');
            RETURN FALSE;
    END expire_task;
    --

    /******************************************************************************************** 
    * Get diets parameters needed to fill edit screen  
    * 
    * @param       i_lang                  Preferred language id for this professional 
    * @param       i_prof                  Professional id structure
    * @param       i_type_diet             Type of diet (1 - Institucionalizada, 2 - Personalizada, 3 - Pre-definida)
    * @param       i_id_diet               ID DIET
    *
    * @param       o_diet                  Cursor with the description of diet and the register
    * @param       o_diet_schedule         Cursor with schedule of diet.
    * @param       o_diet_food             Cursor with de detail of diet.
    * @param       o_error                 Error message
    *         
    * @return      boolean                 True on success, otherwise false     
    *
    * @author                              Orlando Antunes
    * @version                             2.5
    * @since                               2009/11/13
    ********************************************************************************************/
    FUNCTION get_task_parameters
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_diet     IN diet_type.id_diet_type%TYPE,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_diet       IN NUMBER,
        o_diet          OUT pk_types.cursor_type,
        o_diet_schedule OUT pk_types.cursor_type,
        o_diet_food     OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_diet(i_lang          => i_lang,
                        i_prof          => i_prof,
                        i_type_diet     => i_type_diet,
                        i_id_patient    => i_id_patient,
                        i_id_diet       => i_id_diet,
                        o_diet          => o_diet,
                        o_diet_schedule => o_diet_schedule,
                        o_diet_food     => o_diet_food,
                        o_error         => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_TASK_PARAMETERS',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'GET_TASK_PARAMETERS');
            RETURN FALSE;
    END get_task_parameters;
    --

    /**********************************************************************************************
    * Save the diet information, after editing
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_id_epis_diet          ID of Epis diet(used in EDIT one diet)
    * @param i_id_diet_type          Id of type of diet 
    * @param i_desc_diet             Description of diet
    * @param i_dt_begin_str          Begin date
    * @param i_dt_end_str            End date
    * @param i_food_plan             Food plan 
    * @param i_flg_help              Patient necessity(Y/N)
    * @param i_notes                 Diet notes
    * @param i_id_diet_schedule      id of diet schedule (launch, breakfeast)
    * @param i_id_diet               If of diet..
    * @param i_quantity              quantity 
    * @param i_id_unit               Id of unit
    * @param i_notes_diet            Notes of food
    * @param i_dt_hour               Hour of meal
    * @param i_flg_institution       Flg institution
    * @param i_resume_notes          Resume notes
    * @param o_id_epis_diet          ID of diet
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16
    **********************************************************************************************/
    FUNCTION set_task_parameters
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_id_epis_diet       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_id_diet_type       IN diet_type.id_diet_type%TYPE,
        i_desc_diet          IN epis_diet_req.desc_diet%TYPE,
        i_dt_begin_str       IN VARCHAR2,
        i_dt_end_str         IN VARCHAR2,
        i_food_plan          IN epis_diet_req.food_plan%TYPE,
        i_flg_help           IN epis_diet_req.flg_help%TYPE,
        i_notes              IN epis_diet_req.notes%TYPE,
        i_id_diet_predefined IN epis_diet_req.id_diet_prof_instit%TYPE,
        i_id_diet_schedule   IN table_number,
        i_id_diet            IN table_number,
        i_quantity           IN table_number,
        i_id_unit            IN table_number,
        i_notes_diet         IN table_varchar,
        i_dt_hour            IN table_varchar,
        i_flg_institution    IN epis_diet_req.flg_institution%TYPE DEFAULT 'N',
        i_flg_share          IN diet_prof_instit.flg_share%TYPE DEFAULT 'N',
        o_id_epis_diet       OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_msg_warning VARCHAR2(1000 CHAR);
    BEGIN
        -- call create_diet with commit control
        IF NOT create_diet(i_lang               => i_lang,
                           i_prof               => i_prof,
                           i_patient            => i_patient,
                           i_episode            => i_episode,
                           i_id_epis_diet       => i_id_epis_diet,
                           i_id_diet_type       => i_id_diet_type,
                           i_desc_diet          => i_desc_diet,
                           i_dt_begin_str       => i_dt_begin_str,
                           i_dt_end_str         => i_dt_end_str,
                           i_food_plan          => i_food_plan,
                           i_flg_help           => i_flg_help,
                           i_notes              => i_notes,
                           i_id_diet_predefined => i_id_diet_predefined,
                           i_id_diet_schedule   => i_id_diet_schedule,
                           i_id_diet            => i_id_diet,
                           i_quantity           => i_quantity,
                           i_id_unit            => i_id_unit,
                           i_notes_diet         => i_notes_diet,
                           i_dt_hour            => i_dt_hour,
                           i_commit             => g_no,
                           i_flg_institution    => i_flg_institution,
                           i_flg_share          => i_flg_share,
                           o_id_epis_diet       => o_id_epis_diet,
                           o_msg_warning        => l_msg_warning,
                           o_error              => o_error)
        THEN
            RAISE g_exception;
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
                                              'SET_TASK_PARAMETERS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_task_parameters;
    --

    /******************************************************************************************** 
    * Get available actions for a requested diet 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id 
    * @param       i_task_request            task request id (also used for drafts) 
    * @param       o_actions_list            list of available actions for the task request 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16    
    ********************************************************************************************/
    FUNCTION get_task_actions
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN epis_diet_req.id_epis_diet_req%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diet IS
            SELECT get_processed_diet_status(i_lang, i_prof, i_task_request, g_status_type_f)
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_task_request;
    
        l_diet_status epis_diet_req.flg_status%TYPE;
    
    BEGIN
    
        OPEN c_diet;
        FETCH c_diet
            INTO l_diet_status;
        CLOSE c_diet;
    
        IF NOT pk_action.get_actions_with_exceptions(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_subject    => 'DIET',
                                                     i_from_state => l_diet_status,
                                                     o_actions    => o_actions,
                                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_ACTIONS',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'GET_TASK_ACTIONS');
            RETURN FALSE;
    END get_task_actions;
    --

    /******************************************************************************************** 
    * Copy diet to draft (from an existing active/inactive task) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id (current episode) 
    * @param       i_task_request            task request id (used for active/inactive tasks) 
    * @param       o_draft                   draft id 
    * @param       o_error                   error message 
    * 
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/16     
    ********************************************************************************************/
    FUNCTION copy_to_draft
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_task_request         IN epis_diet_req.id_epis_diet_req%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_draft                OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_diet_req_row epis_diet_req%ROWTYPE;
        l_epis_diet_det_row epis_diet_det%ROWTYPE;
        l_rows              table_varchar;
        l_rows_det          table_varchar;
    
        l_epis_diet_dets table_number;
    
        l_id_epis_diet_det epis_diet_det.id_epis_diet_det%TYPE;
    
        l_dt_initial epis_diet_req.dt_inicial%TYPE;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    BEGIN
        --current dates
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
    
        SELECT *
          INTO l_epis_diet_req_row
          FROM epis_diet_req edr
         WHERE edr.id_epis_diet_req = i_task_request;
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_initial := i_task_start_timestamp;
        ELSE
            l_dt_initial := l_epis_diet_req_row.dt_inicial;
        END IF;
    
        --
        g_error := 'CALL TS_EPIS_DIET_REQ.INS ' ||
                   pk_date_utils.date_send_tsz(i_lang,
                                               l_epis_diet_req_row.dt_inicial,
                                               i_prof.institution,
                                               i_prof.software);
        ts_epis_diet_req.ins(id_diet_type_in            => l_epis_diet_req_row.id_diet_type,
                             id_episode_in              => i_episode,
                             id_patient_in              => l_epis_diet_req_row.id_patient,
                             id_professional_in         => i_prof.id,
                             desc_diet_in               => l_epis_diet_req_row.desc_diet,
                             flg_status_in              => g_flg_diet_status_t,
                             notes_in                   => l_epis_diet_req_row.notes,
                             food_plan_in               => l_epis_diet_req_row.food_plan,
                             flg_help_in                => l_epis_diet_req_row.flg_help,
                             dt_creation_in             => g_sysdate_tstz,
                             dt_inicial_in              => l_dt_initial,
                             dt_end_in                  => l_epis_diet_req_row.dt_end,
                             flg_institution_in         => l_epis_diet_req_row.flg_institution,
                             id_diet_prof_instit_in     => l_epis_diet_req_row.id_diet_prof_instit,
                             id_epis_diet_req_parent_in => NULL,
                             resume_notes_in            => l_epis_diet_req_row.resume_notes,
                             id_epis_diet_req_out       => o_draft,
                             rows_out                   => l_rows);
        pk_alertlog.log_debug('CREATE_EPIS_DIET_COPY_TO_DRAFT: Inserted diet:' || o_draft,
                              g_package_name,
                              'CREATE_EPIS_DIET');
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIET_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        --get all details for the existing diet
    
        SELECT edd.id_epis_diet_det
          BULK COLLECT
          INTO l_epis_diet_dets
          FROM epis_diet_req edr, epis_diet_det edd
         WHERE edr.id_epis_diet_req = i_task_request
           AND edd.id_epis_diet_req = edr.id_epis_diet_req;
    
        IF l_epis_diet_dets.count <> 0
        THEN
            --create the details for the new diet!
            --insert the diet detail
            FOR i IN l_epis_diet_dets.first .. l_epis_diet_dets.last
            LOOP
                SELECT *
                  INTO l_epis_diet_det_row
                  FROM epis_diet_det edd
                 WHERE edd.id_epis_diet_det = l_epis_diet_dets(i);
            
                g_error := 'CALL ts_epis_diet_det.ins';
                ts_epis_diet_det.ins(id_epis_diet_req_in  => o_draft,
                                     notes_in             => l_epis_diet_det_row.notes,
                                     id_diet_schedule_in  => l_epis_diet_det_row.id_diet_schedule,
                                     dt_diet_schedule_in  => l_epis_diet_det_row.dt_diet_schedule,
                                     id_diet_in           => l_epis_diet_det_row.id_diet,
                                     quantity_in          => l_epis_diet_det_row.quantity,
                                     id_unit_measure_in   => l_epis_diet_det_row.id_unit_measure,
                                     id_epis_diet_det_out => l_id_epis_diet_det,
                                     rows_out             => l_rows_det);
            END LOOP;
        
        END IF;
    
        IF l_flg_profile = pk_prof_utils.g_flg_profile_template_student
        THEN
            l_sys_alert_event.id_sys_alert    := pk_alert_constant.g_alert_cpoe_draft;
            l_sys_alert_event.id_software     := i_prof.software;
            l_sys_alert_event.id_institution  := i_prof.institution;
            l_sys_alert_event.id_episode      := i_episode;
            l_sys_alert_event.id_patient      := pk_episode.get_epis_patient(i_lang    => i_lang,
                                                                             i_prof    => i_prof,
                                                                             i_episode => i_episode);
            l_sys_alert_event.id_record       := i_episode;
            l_sys_alert_event.id_visit        := pk_visit.get_visit(i_episode => i_episode, o_error => o_error);
            l_sys_alert_event.dt_record       := current_timestamp;
            l_sys_alert_event.id_professional := pk_hand_off.get_episode_responsible(i_lang       => i_lang,
                                                                                     i_prof       => i_prof,
                                                                                     i_id_episode => i_episode,
                                                                                     o_error      => o_error);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_sys_alert_event => l_sys_alert_event,
                                                    o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'COPY_TO_DRAFT',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'COPY_TO_DRAFT');
            RETURN FALSE;
    END copy_to_draft;
    --

    FUNCTION get_drafts_conflicts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_draft   IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_epis_diet_det_state    epis_diet_req.flg_status%TYPE;
        l_epis_diet_det_dt_start epis_diet_req.dt_inicial%TYPE;
        l_epis_diet_det_dt_end   epis_diet_req.dt_end%TYPE;
        l_conflit                VARCHAR2(1);
    
        l_error t_error_out;
    BEGIN
        pk_alertlog.log_debug('CHECK_DRAFTS_CONFLICTS', g_package_name);
        g_sysdate_tstz := current_timestamp;
    
        --validate the draft state
        SELECT edr.flg_status, edr.dt_inicial, edr.dt_end
          INTO l_epis_diet_det_state, l_epis_diet_det_dt_start, l_epis_diet_det_dt_end
          FROM epis_diet_req edr
         WHERE edr.id_epis_diet_req = i_draft;
    
        pk_alertlog.log_debug('CURRENT DIET STATE: ' || l_epis_diet_det_state,
                              g_package_name,
                              'CHECK DRAFTS CONFLICTS');
    
        g_error := 'Diet ' || i_draft || ' is not in draft state.';
        --
        IF l_epis_diet_det_state <> g_flg_diet_status_t
        THEN
            l_conflit := 'N';
        ELSIF (l_epis_diet_det_dt_end IS NULL OR l_epis_diet_det_dt_end > g_sysdate_tstz)
              AND (l_epis_diet_det_dt_start IS NULL OR
              trunc(l_epis_diet_det_dt_start, 'DDD') >= trunc(g_sysdate_tstz, 'DDD'))
        THEN
            l_conflit := 'N';
        ELSE
            l_conflit := 'Y';
        END IF;
        RETURN l_conflit;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CHECK_DRAFTS_CONFLICTS',
                                              l_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CHECK_DRAFTS_CONFLICTS');
            RETURN NULL;
    END get_drafts_conflicts;
    --

    /******************************************************************************************** 
    * Check conflicts upon created drafts (verify if drafts can be requested or not) 
    * 
    * @param       i_lang                    preferred language id for this professional 
    * @param       i_prof                    professional id structure 
    * @param       i_episode                 episode id  
    * @param       i_draftt                   draft id 
    * @param       o_flg_conflict            array of draft conflicts indicators 
    * @param       o_msg_title               array of message titles 
    * @param       o_msg_text                array of message texts 
    * @param       o_button                  array of buttons to show (it can have more than one button) 
    * @param       o_error                   error message 
    * 
    * @value       o_flg_conflict            {*} 'Y' the draft has conflicts  
    *                                        {*} 'N' no conflicts found 
    *    
    * @value       o_button                  {*} 'N' NO button is displayed 
    *                                        {*} 'R' READ button is displayed    
    *                                        {*} 'C' CONFIRM button is displayed 
    *                                        {*} Example: 'NC' NO/CONFIRM buttons are displayed 
    *         
    * @return                        True on success, false otherwise
    *
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/17       
    ********************************************************************************************/
    FUNCTION check_drafts_conflicts
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_draft        IN epis_diet_req.id_epis_diet_req%TYPE,
        o_flg_conflict OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg_text     OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_conflit VARCHAR2(1);
    BEGIN
    
        l_conflit := pk_alert_constant.g_no;
        --according to the client requests, there are no conflicts in the diets activation
        --OA 17/09/2010.
    
        IF l_conflit = 'N'
        THEN
            o_flg_conflict := 'N';
            o_msg_title    := NULL;
            o_msg_text     := NULL;
            o_button       := NULL;
        ELSE
            o_flg_conflict := 'Y';
            o_msg_title    := pk_message.get_message(i_lang, 'COMMON_T013');
            o_msg_text     := pk_message.get_message(i_lang, 'DIET_T109');
            o_button       := 'R';
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
                                              'CHECK_DRAFTS_CONFLICTS',
                                              o_error);
            pk_alertlog.log_error('ERROR:' || g_error || ' SQL:' || SQLERRM, g_package_name, 'CHECK_DRAFTS_CONFLICTS');
            RETURN FALSE;
    END check_drafts_conflicts;
    --
    /**********************************************************************************************
    * Get the diet description to be shown in the grids
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/27
    **********************************************************************************************/
    FUNCTION get_diet_description
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_diet_type  IN diet_type.id_diet_type%TYPE,
        i_diet_name  IN epis_diet_req.desc_diet%TYPE,
        o_diet_descr OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_diet_type:' || i_diet_type || 'i_diet_name:' || i_diet_name || ']',
                              g_package_name,
                              'GET_MENU_DIET');
        --
        IF NOT get_diet_description(i_lang        => i_lang,
                                    i_prof        => i_prof,
                                    i_diet_type   => i_diet_type,
                                    i_diet_name   => i_diet_name,
                                    i_flg_default => pk_alert_constant.g_yes,
                                    o_diet_descr  => o_diet_descr,
                                    o_error       => o_error)
        THEN
            RAISE g_exception;
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
                                              'GET_DIET_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END get_diet_description;

    /**********************************************************************************************
    * Get the diet description to be shown in the grids
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/27
    **********************************************************************************************/
    FUNCTION get_diet_description
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN diet_type.id_diet_type%TYPE,
        i_diet_name   IN epis_diet_req.desc_diet%TYPE,
        i_flg_default IN VARCHAR2 DEFAULT 'Y',
        o_diet_descr  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        pk_alertlog.log_debug('PARAMS[:i_diet_type:' || i_diet_type || 'i_diet_name:' || i_diet_name || ']',
                              g_package_name,
                              'GET_MENU_DIET');
        --
        o_diet_descr := get_diet_description_internal(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_diet_type   => i_diet_type,
                                                      i_diet_name   => i_diet_name,
                                                      i_flg_default => i_flg_default);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIET_DESCRIPTION',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_diet_description;
    --

    /**********************************************************************************************
    * Get the diet description to be shown in the grids
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/27
    **********************************************************************************************/
    FUNCTION get_diet_description_internal
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN diet_type.id_diet_type%TYPE,
        i_diet_name   IN epis_diet_req.desc_diet%TYPE,
        i_flg_default IN VARCHAR2 DEFAULT 'Y'
    )
    
     RETURN VARCHAR2 IS
        l_diet_descr VARCHAR2(4000);
    BEGIN
        --
        SELECT decode(i_flg_default, g_yes, '<b>', '') ||
               pk_translation.get_translation(i_lang, 'DIET_TYPE.CODE_DIET_TYPE.' || i_diet_type) ||
               decode(i_diet_name,
                      NULL,
                      decode(i_flg_default, g_yes, '</b>', ''),
                      ':' || decode(i_flg_default, g_yes, '</b>') || ' ' || htf.escape_sc(i_diet_name)) task_description
          INTO l_diet_descr
          FROM dual;
    
        RETURN l_diet_descr;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diet_description_internal;
    --

    /********************************************************************************************
    * Get patient's Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_diagnosis_prof        Professional that creates/edit the diagnosis
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_interv_plan_prof      Professional that creates/edit the intervention plan
    * @ param o_follow_up             Follow up notes for the current episode
    * @ param o_follow_up_prof        Professional that creates the follow up notes
    * @ param o_diet                  Patient diets
    * @ param o_diet_prof             Professional that prescribes the diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_evaluation_tools_prof Professional that creates the evaluation
    * @ param o_dietitian_report         dietitian report
    * @ param o_dietitian_report_prof    Professional that creates/edit the dietitian report
    * @ param o_dietitian_request        dietitian request
    * @ param o_dietitian_request_prof   Professional that creates/edit the dietitian request
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/01/21
    **********************************************************************************************/
    FUNCTION get_dietitian_summary
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --request
        o_dietitian_request      OUT pk_types.cursor_type,
        o_dietitian_request_prof OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_temp_cur                    pk_types.cursor_type;
        l_dietitian_summary_view_type VARCHAR2(1 CHAR);
        l_category                    category.flg_type%TYPE;
        --
    BEGIN
    
        -- get view type
        l_dietitian_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                    := pk_prof_utils.get_category(i_lang, i_prof);
    
        g_error := 'CALL get_dietitian_requests_summary';
        IF NOT get_dietitian_requests_summary(i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              i_episode       => i_episode,
                                              o_requests      => o_dietitian_request,
                                              o_requests_prof => o_dietitian_request_prof,
                                              o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dietitian_request);
            pk_types.open_my_cursor(o_dietitian_request_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DIETITIAN_SUMMARY',
                                                     o_error);
        
    END get_dietitian_summary;
    --

    /********************************************************************************************
    * Get patient's EHR Dietitian Summary. This includes information of:
    *    - Diagnosis
    *    - Intervention plan
    *    - Follow up notes
    *    - Diets
    *    - Evaluation tools
    *    - Dietitian report
    *    - Dietitian requests
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @param i_episode                ID Episode
    * 
    * @ param o_screen_labels         Labels
    * @ param o_episodes_det          List of patient's episodes
    * @ param o_diagnosis             Patient's diagnosis list
    * @ param o_interv_plan           Patient's intevention plan list
    * @ param o_follow_up             Follow up notes list
    * @ param o_diet                  Patient diets
    * @ param o_evaluation_tools      List of evaluation tools
    * @ param o_dietitian_report         dietitian report list
    * @ param o_dietitian_request        dietitian requests list
    * @ param o_request_origin        Y/N  - Indicates if the episode started with a request 
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_ehr
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_pat  IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --labels
        o_screen_labels OUT pk_types.cursor_type,
        --list of episodes
        o_episodes_det OUT pk_types.cursor_type,
        --request
        o_dietitian_request OUT pk_types.cursor_type,
        --
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_temp_cur pk_types.cursor_type;
        l_episodes table_number;
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    
        l_dietitian_summary_view_type VARCHAR2(1 CHAR);
        l_category                    category.flg_type%TYPE;
    BEGIN
        pk_alertlog.log_debug('GET_dietitian_SUMMARY_EHR - get all labels for the dietitian status screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T121', 'PARAMEDICAL_T001'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        OPEN o_screen_labels FOR
            SELECT t_table_message_array('DIET_T121') ehr_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T001') dietitian_request_header
              FROM dual;
    
        IF NOT pk_social.get_epis_by_type_and_pat(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_pat       => i_id_pat,
                                                  i_id_epis_type => table_number(pk_alert_constant.g_epis_type_dietitian),
                                                  o_episodes_ids => l_episodes,
                                                  o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        IF NOT get_dietitian_episodes_det(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_id_pat       => i_id_pat,
                                          o_episodes_det => o_episodes_det,
                                          o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
    
        -- get view type
        l_dietitian_summary_view_type := pk_sysconfig.get_config(i_code_cf => 'SUMMARY_VIEW_ALL', i_prof => i_prof);
        l_category                    := pk_prof_utils.get_category(i_lang, i_prof);
        g_error                       := 'Get only the information that the profissional can see';
        IF l_category <> pk_alert_constant.g_cat_type_nutritionist
           AND l_dietitian_summary_view_type = pk_alert_constant.g_no
        THEN
            pk_types.open_my_cursor(o_dietitian_request);
        ELSE
        
            g_error := 'CALL GET_DIETITIAN_REQUESTS_SUM_EHR';
            IF NOT get_dietitian_requests_sum_ehr(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_episode       => l_episodes,
                                                  o_requests      => o_dietitian_request,
                                                  o_requests_prof => l_temp_cur,
                                                  o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        CLOSE l_temp_cur;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_screen_labels);
            pk_types.open_my_cursor(o_dietitian_request);
            pk_types.close_cursor_if_opened(i_cursor => l_temp_cur);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DIETITIAN_SUMMARY_EHR',
                                                     o_error);
        
    END get_dietitian_summary_ehr;
    --
    /********************************************************************************************
    * Get the dietitian summary screen labels
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param o_dietitian_summary_labels   Social summary screen labels  
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/
    **********************************************************************************************/
    FUNCTION get_dietitian_summary_labels
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        o_dietitian_summary_labels OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        t_table_message_array pk_paramedical_prof_core.table_message_array;
    BEGIN
        g_error := 'GET LABELS';
        pk_alertlog.log_debug('GET_DIETITIAN_SUMMARY_LABELS - get all labels for the dietitian summary screen');
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T118', 'PARAMEDICAL_T001'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
    
        --    
        OPEN o_dietitian_summary_labels FOR
            SELECT t_table_message_array('DIET_T118') dietitian_summary_main_header,
                   t_table_message_array('PARAMEDICAL_T001') dietitian_request_header
              FROM dual;
        --      
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_dietitian_summary_labels);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_DIETITIAN_SUMMARY_LABELS',
                                                     o_error);
        
    END get_dietitian_summary_labels;
    --

    /**********************************************************************************************
    * Get the diet description to be shown in the grids
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_epis_diet_req      Diet order identifier
    * @param i_diet_descr_format     Format of returned description
    * @param i_grouped               To be grouped the severals foods by meals for institutionalized diets
    *
    * @return                        Diet description
    *                        
    * @author                        Orlando Antunes
    * @version                       2.5
    * @since                         2009/11/27
    **********************************************************************************************/
    FUNCTION get_diet_description_internal2
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_diet_req  IN epis_diet_req.id_epis_diet_req%TYPE,
        i_diet_descr_format IN VARCHAR2 DEFAULT ('S'),
        i_grouped           IN VARCHAR2 DEFAULT ('N'),
        i_show_all_meal     IN VARCHAR2 DEFAULT ('Y'),
        i_flg_report        IN VARCHAR2 DEFAULT ('N')
    ) RETURN CLOB IS
        l_diet_descr CLOB;
    
        l_diet_notes    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T045');
        l_diet_begin    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T112');
        l_diet_end      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T113');
        l_diet_all_meal sys_message.desc_message%TYPE;
    BEGIN
        IF i_show_all_meal = pk_alert_constant.g_yes
        THEN
            l_diet_all_meal := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T114') || ' ';
        END IF;
    
        --short diet description
        IF i_diet_descr_format = g_diet_descr_format_s
        THEN
            SELECT '<b>' || pk_translation.get_translation(i_lang, 'DIET_TYPE.CODE_DIET_TYPE.' || edr.id_diet_type) ||
                   decode(edr.desc_diet, NULL, '</b>', ':</b> ' || htf.escape_sc(edr.desc_diet)) task_description
              INTO l_diet_descr
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_id_epis_diet_req;
        ELSIF i_diet_descr_format = g_diet_descr_format_m
        THEN
            --diet description - meals only
            SELECT decode(edr.id_diet_type,
                          g_diet_type_inst,
                          decode((SELECT COUNT(DISTINCT id_diet)
                                   FROM epis_diet_det
                                  WHERE id_epis_diet_req = edr.id_epis_diet_req),
                                 1,
                                 --institutionalized and only with one record
                                 l_diet_all_meal || (SELECT get_diet_description_title(i_lang, i_prof, d.id_diet)
                                                       FROM epis_diet_det edd, diet d
                                                      WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                                        AND edd.id_diet = d.id_diet
                                                        AND rownum = 1),
                                 decode(i_grouped,
                                        pk_alert_constant.g_no,
                                        --institutionalized and more than one record not grouped
                                        pk_utils.query_to_string('
                           SELECT  PK_TRANSLATION.get_translation(' ||
                                                                 i_lang ||
                                                                 ',DS.CODE_DIET_SCHEDULE) || '': '' ||  PK_TRANSLATION.get_translation(' ||
                                                                 i_lang ||
                                                                 ',D.CODE_DIET)
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                                 edr.id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ORDER BY DS.RANK',
                                                                 '; '),
                                        --institutionalized and more than one record grouped
                                        pk_utils.query_to_string('
                           select  meal  from (
                           
                           SELECT distinct  PK_TRANSLATION.get_translation(' ||
                                                                 i_lang ||
                                                                 ',DS.CODE_DIET_SCHEDULE) || '': '' ||  pk_diet.get_diet_description_title(' ||
                                                                 i_lang || ', profissional(' || i_prof.id || ',' ||
                                                                 i_prof.institution || ',' || i_prof.software ||
                                                                 '),D.ID_DIET) meal, DS.RANK
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                                 edr.id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ) t_int ORDER BY RANK',
                                                                 '; '))),
                          --not institutionalized
                          pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct PK_TRANSLATION.get_translation(' ||
                                                   i_lang ||
                                                   ',CODE_DIET_SCHEDULE) meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                   i_lang ||
                                                   ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', um.code_unit_measure)
                                          from epis_diet_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_epis_diet_req= ' ||
                                                   edr.id_epis_diet_req || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from epis_diet_det edd, diet_schedule ds
                                        where edd.id_epis_diet_req = ' ||
                                                   edr.id_epis_diet_req || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
                                        order by ds.rank)',
                                                   '; ')
                          
                          ) task_description
              INTO l_diet_descr
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_id_epis_diet_req;
        
        ELSIF i_diet_descr_format = g_diet_descr_format_sp
        THEN
            --diet description - meals only
            SELECT decode(edr.id_diet_type,
                          g_diet_type_inst,
                          decode((SELECT COUNT(DISTINCT id_diet)
                                   FROM epis_diet_det
                                  WHERE id_epis_diet_req = edr.id_epis_diet_req),
                                 1,
                                 --institutionalized and only with one record
                                 (SELECT get_diet_description_title(i_lang, i_prof, d.id_diet)
                                    FROM epis_diet_det edd, diet d
                                   WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                     AND edd.id_diet = d.id_diet
                                     AND rownum = 1),
                                 decode(i_grouped,
                                        pk_alert_constant.g_no,
                                        --institutionalized and more than one record not grouped
                                        pk_utils.query_to_string('
                           SELECT   PK_TRANSLATION.get_translation(' ||
                                                                 i_lang ||
                                                                 ',D.CODE_DIET)
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                                 edr.id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ORDER BY DS.RANK',
                                                                 '; '),
                                        --institutionalized and more than one record grouped
                                        pk_utils.query_to_string('
                           select  meal  from (
                           
                           SELECT distinct pk_diet.get_diet_description_title(' ||
                                                                 i_lang || ', profissional(' || i_prof.id || ',' ||
                                                                 i_prof.institution || ',' || i_prof.software ||
                                                                 '),D.ID_DIET) meal, DS.RANK
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                                 edr.id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ) t_int ORDER BY RANK',
                                                                 '; '))),
                          --not institutionalized
                          pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                   i_lang ||
                                                   ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', um.code_unit_measure)
                                          from epis_diet_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_epis_diet_req= ' ||
                                                   edr.id_epis_diet_req || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from epis_diet_det edd, diet_schedule ds
                                        where edd.id_epis_diet_req = ' ||
                                                   edr.id_epis_diet_req || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
                                        order by ds.rank)',
                                                   '; ')
                          
                          ) task_description
              INTO l_diet_descr
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_id_epis_diet_req;
        
        ELSE
            --complete diet description(used in 'cpoe') AND...
            SELECT '<b>' || pk_translation.get_translation(i_lang, 'DIET_TYPE.CODE_DIET_TYPE.' || edr.id_diet_type) ||
                    decode(edr.desc_diet, NULL, '</b>', ':</b> ' || htf.escape_sc(edr.desc_diet)) ||
                   /*  decode(edr.flg_status,
                   g_flg_diet_status_s,
                   ' (' || pk_message.get_message(i_lang, 'REP_COMM_ORDERS_REVIEW_002') || ')',
                   NULL) ||*/
                    chr(10) ||
                    decode(edr.id_diet_type,
                           g_diet_type_inst,
                           decode((SELECT COUNT(DISTINCT id_diet)
                                    FROM epis_diet_det
                                   WHERE id_epis_diet_req = edr.id_epis_diet_req),
                                  1,
                                  l_diet_all_meal || (SELECT get_diet_description_title(i_lang, i_prof, d.id_diet)
                                                        FROM epis_diet_det edd, diet d
                                                       WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                                         AND edd.id_diet = d.id_diet
                                                         AND rownum = 1),
                                  pk_utils.query_to_string('
                            SELECT  PK_TRANSLATION.get_translation(' ||
                                                           i_lang ||
                                                           ',DS.CODE_DIET_SCHEDULE) || '': '' ||  pk_diet.get_diet_description_title(' ||
                                                           i_lang || ', profissional(' || i_prof.id || ',' ||
                                                           i_prof.institution || ',' || i_prof.software ||
                                                           '),D.ID_DIET)
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                           edr.id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
													 AND EDD.ID_DIET_SCHEDULE = 7
                           ORDER BY DS.RANK',
                                                           '; ')),
                           pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct PK_TRANSLATION.get_translation(' ||
                                                    i_lang ||
                                                    ',CODE_DIET_SCHEDULE) meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                    i_lang ||
                                                    ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                    i_lang ||
                                                    ', um.code_unit_measure)
                                          from epis_diet_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_epis_diet_req= ' ||
                                                    edr.id_epis_diet_req || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from epis_diet_det edd, diet_schedule ds
                                        where edd.id_epis_diet_req = ' ||
                                                    edr.id_epis_diet_req || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
																				                           AND EDD.ID_DIET_SCHEDULE = 7
                                        order by ds.rank)',
                                                    '; ')
                           
                           ) ||
                    decode(i_flg_report,
                           pk_alert_constant.g_no,
                           chr(10) || l_diet_begin ||
                           pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) ||
                           decode(edr.dt_end,
                                  NULL,
                                  NULL,
                                  '; ' || l_diet_end ||
                                  pk_date_utils.date_char_tsz(i_lang, edr.dt_end, i_prof.institution, i_prof.software)) ||
                           decode(dbms_lob.getlength(to_clob(edr.notes)),
                                  NULL,
                                  NULL,
                                  chr(10) || l_diet_notes || ' ' || dbms_lob.substr(to_clob(edr.notes), 3800))) task_description
              INTO l_diet_descr
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_id_epis_diet_req;
        
        END IF;
        --
        RETURN l_diet_descr;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diet_description_internal2;
    --

    /**********************************************************************************************
    * Gets the summary of the diets to be used in the generic summary page
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_patient               ID Patient
    * @param i_episode               ID Episode
    * @param i_flg_type              Diet type
    *
    * @param o_diet                  Cursor with the description of diet 
    * @param o_diet_prof             Cursor with the prof details
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Orlando Antunes
    * @version                       2.6.0.1
    * @since                         2010/04/03
    **********************************************************************************************/
    FUNCTION get_diet_general_summary
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        i_episode   IN episode.id_episode%TYPE,
        i_flg_type  IN VARCHAR2 DEFAULT 'H',
        o_diet      OUT pk_types.cursor_type,
        o_diet_prof OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_diet_type      sys_message.desc_message%TYPE;
        l_diet_name      sys_message.desc_message%TYPE;
        l_dt_inicio      sys_message.desc_message%TYPE;
        l_dt_end         sys_message.desc_message%TYPE;
        l_notes          sys_message.desc_message%TYPE;
        l_plan           sys_message.desc_message%TYPE;
        l_help           sys_message.desc_message%TYPE;
        l_schedule       sys_message.desc_message%TYPE;
        l_food           sys_message.desc_message%TYPE;
        l_type_food      sys_message.desc_message%TYPE;
        l_share          sys_message.desc_message%TYPE;
        l_institution    sys_message.desc_message%TYPE;
        l_meals          sys_message.desc_message%TYPE;
        l_desc_interrupt sys_message.desc_message%TYPE;
        l_last_update    sys_message.desc_message%TYPE;
        l_id_prof_alert  sys_config.value%TYPE;
    
        l_diet_expired sys_message.desc_message%TYPE;
    BEGIN
        pk_alertlog.log_debug('GET_DIET_SUMMARY', g_package_name);
        g_sysdate_tstz := current_timestamp;
        l_diet_type    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T048');
        l_diet_name    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T049');
        l_dt_inicio    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T050');
        l_dt_end       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T051');
        l_notes        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T045');
        l_plan         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T068');
        l_help         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T053');
        l_schedule     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T029');
        l_food         := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T046');
        l_type_food    := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T069');
        l_share        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T073');
        l_institution  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T070');
        l_meals        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T120');
        l_last_update  := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PAST_HISTORY_M006');
        --
        l_id_prof_alert := pk_sysconfig.get_config(i_code_cf => 'ID_PROF_ALERT', i_prof => i_prof);
    
        g_error := 'OPEN CURSOR O_DIET_REGISTER (patient)';
        -- PROFESSIONAL THAT REGISTER THE DIET
        OPEN o_diet_prof FOR
            SELECT id_diet id, pk_date_utils.dt_chr_date_hour_tsz(i_lang, dt_action, i_prof) dt, prof_sign, flg_status
              FROM (SELECT edr.id_epis_diet_req id_diet,
                           decode(edr.flg_status,
                                  g_flg_diet_status_s,
                                  edr.dt_cancel,
                                  g_flg_diet_status_c,
                                  edr.dt_cancel,
                                  edr.dt_creation) dt_action,
                           decode(edr.flg_status,
                                  g_flg_diet_status_s,
                                  pk_tools.get_prof_description(i_lang, i_prof, edr.id_prof_cancel, edr.dt_cancel, NULL),
                                  g_flg_diet_status_c,
                                  pk_tools.get_prof_description(i_lang, i_prof, edr.id_prof_cancel, edr.dt_cancel, NULL),
                                  pk_tools.get_prof_description(i_lang,
                                                                i_prof,
                                                                edr.id_professional,
                                                                edr.dt_creation,
                                                                NULL)) prof_sign,
                           edr.flg_status flg_status_bd,
                           get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_f) flg_status,
                           decode(edr.flg_status,
                                  g_flg_diet_status_s,
                                  3,
                                  g_flg_diet_status_c,
                                  5,
                                  decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                         'G',
                                         2,
                                         decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                                'L',
                                                4,
                                                1))) rank
                      FROM epis_diet_req edr, diet_type dt, episode e
                     WHERE edr.id_patient = i_patient
                       AND edr.flg_status NOT IN (g_flg_diet_status_t)
                       AND NOT EXISTS (SELECT 1
                              FROM epis_diet_req e
                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                       AND edr.id_diet_type = dt.id_diet_type
                       AND ((i_flg_type = 'E' AND edr.id_episode = i_episode) OR i_flg_type = 'H')
                       AND edr.id_episode = e.id_episode
                       AND e.id_epis_type = g_epis_type_nutri)
            
             ORDER BY rank, dt_action DESC;
    
        -- DETAIL OF DIET
        g_error := 'OPEN CURSOR O_DIET (patient)';
        OPEN o_diet FOR
            SELECT id_diet id,
                   --this information can be presented in the ehr, for this episode
                   id_episode,
                   --type
                   pk_paramedical_prof_core.c_open_bold_html || l_diet_type ||
                   pk_paramedical_prof_core.c_close_bold_html || pk_paramedical_prof_core.c_whitespace ||
                   desc_diet_type desc_type,
                   --name
                   decode(id_diet_type,
                          g_diet_type_inst,
                          NULL,
                          pk_paramedical_prof_core.c_open_bold_html || l_diet_name ||
                          pk_paramedical_prof_core.c_close_bold_html || pk_paramedical_prof_core.c_whitespace ||
                          nvl(diet_name, pk_paramedical_prof_core.c_dashes)) desc_name,
                   --dt_begin
                   pk_paramedical_prof_core.c_open_bold_html || l_dt_inicio ||
                   pk_paramedical_prof_core.c_close_bold_html || pk_paramedical_prof_core.c_whitespace ||
                   nvl(dt_initial, pk_paramedical_prof_core.c_dashes) desc_dt_initial,
                   --dt_end
                   pk_paramedical_prof_core.c_open_bold_html || l_dt_end || pk_paramedical_prof_core.c_close_bold_html ||
                   pk_paramedical_prof_core.c_whitespace || nvl(dt_end, pk_paramedical_prof_core.c_dashes) desc_dt_end,
                   --foof_plan
                   decode(food_plan,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.c_open_bold_html || l_plan ||
                          pk_paramedical_prof_core.c_close_bold_html || pk_paramedical_prof_core.c_whitespace ||
                          food_plan) desc_plan,
                   --help
                   decode(desc_help,
                          NULL,
                          NULL,
                          pk_paramedical_prof_core.c_open_bold_html || l_help ||
                          pk_paramedical_prof_core.c_close_bold_html || pk_paramedical_prof_core.c_whitespace ||
                          desc_help) desc_help,
                   --notes
                   pk_paramedical_prof_core.c_open_bold_html || l_notes || pk_paramedical_prof_core.c_close_bold_html ||
                   pk_paramedical_prof_core.c_whitespace || nvl(notes, pk_paramedical_prof_core.c_dashes) desc_notes,
                   --meals
                   pk_paramedical_prof_core.format_str_header_w_colon(l_meals) ||
                   nvl(meals, pk_paramedical_prof_core.c_dashes) desc_meals,
                   last_update last_update_info
              FROM (SELECT edr.id_epis_diet_req id_diet,
                           edr.id_episode,
                           l_diet_type diet_type_title,
                           pk_translation.get_translation(i_lang, dt.code_diet_type) desc_diet_type,
                           decode(edr.desc_diet, NULL, NULL, l_diet_name) diet_name_title,
                           edr.desc_diet diet_name,
                           l_dt_inicio dt_initial_title,
                           pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) dt_initial,
                           l_dt_end dt_end_title,
                           pk_date_utils.dt_chr_tsz(i_lang, edr.dt_end, i_prof) dt_end,
                           edr.notes notes,
                           decode(edr.id_diet_type, g_diet_type_inst, NULL, l_plan) food_plan_title,
                           edr.food_plan || decode(edr.food_plan,
                                                   NULL,
                                                   NULL,
                                                   (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                                                      FROM unit_measure um
                                                     WHERE id_unit_measure = g_id_unit_kcal)) food_plan,
                           
                           pk_sysdomain.get_domain(g_yes_no, edr.flg_help, i_lang) desc_help,
                           decode(edr.flg_institution, NULL, NULL, l_institution) desc_institution_title,
                           pk_sysdomain.get_domain(g_yes_no, edr.flg_institution, i_lang) desc_institution,
                           edr.flg_institution,
                           get_diet_description_internal2(i_lang, i_prof, edr.id_epis_diet_req, 'M') meals,
                           decode(edr.flg_status,
                                  g_flg_diet_status_s,
                                  edr.dt_cancel,
                                  g_flg_diet_status_c,
                                  edr.dt_cancel,
                                  edr.dt_creation) dt_action,
                           edr.id_diet_type,
                           pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                             i_prof,
                                                                             decode(edr.flg_status,
                                                                                    g_flg_diet_status_s,
                                                                                    edr.dt_cancel,
                                                                                    g_flg_diet_status_c,
                                                                                    edr.dt_cancel,
                                                                                    edr.dt_creation),
                                                                             decode(edr.flg_status,
                                                                                    g_flg_diet_status_s,
                                                                                    edr.id_prof_cancel,
                                                                                    g_flg_diet_status_c,
                                                                                    edr.id_prof_cancel,
                                                                                    edr.id_professional),
                                                                             decode(edr.flg_status,
                                                                                    g_flg_diet_status_s,
                                                                                    edr.dt_cancel,
                                                                                    g_flg_diet_status_c,
                                                                                    edr.dt_cancel,
                                                                                    edr.dt_creation)) last_update
                      FROM epis_diet_req edr, diet_type dt, episode e
                     WHERE edr.id_patient = i_patient
                       AND edr.flg_status NOT IN (g_flg_diet_status_s, g_flg_diet_status_c, g_flg_diet_status_t)
                       AND edr.id_diet_type = dt.id_diet_type
                       AND NOT EXISTS (SELECT 1
                              FROM epis_diet_req e
                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                       AND ((i_flg_type = 'E' AND edr.id_episode = i_episode) OR i_flg_type = 'H')
                       AND edr.id_episode = e.id_episode
                          
                       AND e.id_epis_type = g_epis_type_nutri)
            
             ORDER BY dt_action DESC;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DIET_GENERAL_SUMMARY',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_diet);
            pk_types.open_my_cursor(o_diet_prof);
            RETURN FALSE;
        
    END get_diet_general_summary;
    --

    /********************************************************************************************
    * Get the episodes detail information 
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_pat                 Patient ID
    * @ param o_episodes_det          List of episodes detail
    * @ param o_error 
    
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/15
    **********************************************************************************************/
    FUNCTION get_dietitian_episodes_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_pat       IN patient.id_patient%TYPE,
        o_episodes_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET_DIETITIAN_EPISODES_DET - Begin';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_episodes_det FOR
            SELECT epi.id_episode id_episode,
                   pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt,
                   pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_str,
                   pk_tools.get_prof_description(i_lang, i_prof, ei.id_professional, epi.dt_creation, NULL) prof_sign,
                   pk_message.get_message(i_lang, 'DIET_T121') epis_det_desc
              FROM episode epi
              JOIN epis_info ei
                ON epi.id_episode = ei.id_episode
             WHERE epi.id_epis_type = pk_alert_constant.g_epis_type_dietitian
               AND epi.id_patient = i_id_pat
               AND epi.flg_status <> pk_alert_constant.g_flg_status_c
             ORDER BY epi.dt_begin_tstz;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_episodes_det);
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_dietitian_episodes_det',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_dietitian_episodes_det;

    /********************************************************************************************
    * Get the evaluation tools template info for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_patient               Patient ID 
    * @ param i_episode               Episode ID
    * @ param o_evaluation_tools      Cursor evaluation tools history
    * @ param o_evaluation_tools_prof Cursor with prof history information for the 
    *                                 given evaluation tools
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION get_evaluation_tools_summary
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_patient               IN patient.id_patient%TYPE,
        i_episode               IN table_number,
        i_is_ehr                IN VARCHAR2 DEFAULT ('N'),
        o_evaluation_tools      OUT pk_types.cursor_type,
        o_evaluation_tools_prof OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT get_templates_summary(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_patient            => i_patient,
                                     i_episode            => i_episode,
                                     i_id_summary_page    => 34,
                                     i_summary_page_scope => pk_diet.g_templates_info_scope_p,
                                     i_is_ehr             => i_is_ehr,
                                     o_template           => o_evaluation_tools,
                                     o_template_prof      => o_evaluation_tools_prof,
                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_evaluation_tools);
            pk_types.open_my_cursor(o_evaluation_tools_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_EVALUATION_TOOLS_SUMMARY',
                                                     o_error);
        
    END get_evaluation_tools_summary;
    --

    /********************************************************************************************
    * Get the evaluation tools template info for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_patient               Patient ID 
    * @ param i_episode               Episode ID
    * @ param o_evaluation_tools      Cursor evaluation tools history
    * @ param o_evaluation_tools_prof Cursor with prof history information for the 
    *                                 given evaluation tools
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION get_nutrition_assessments_sum
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_patient                    IN patient.id_patient%TYPE,
        i_episode                    IN table_number,
        i_is_ehr                     IN VARCHAR2 DEFAULT ('N'),
        o_nutrition_assessments      OUT pk_types.cursor_type,
        o_nutrition_assessments_prof OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF NOT get_templates_summary(i_lang               => i_lang,
                                     i_prof               => i_prof,
                                     i_patient            => i_patient,
                                     i_episode            => i_episode,
                                     i_id_summary_page    => 39,
                                     i_summary_page_scope => pk_diet.g_templates_info_scope_e,
                                     i_is_ehr             => i_is_ehr,
                                     o_template           => o_nutrition_assessments,
                                     o_template_prof      => o_nutrition_assessments_prof,
                                     o_error              => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_nutrition_assessments);
            pk_types.open_my_cursor(o_nutrition_assessments_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_NUTRITION_ASSESSMENTS_SUM',
                                                     o_error);
        
    END get_nutrition_assessments_sum;

    /********************************************************************************************
    * Get the evaluation tools template info for the summary screen.
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_patient               Patient ID 
    * @ param i_episode               Episode ID
    * @ param o_evaluation_tools      Cursor evaluation tools history
    * @ param o_evaluation_tools_prof Cursor with prof history information for the 
    *                                 given evaluation tools
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/04/14
    **********************************************************************************************/
    FUNCTION get_templates_summary
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN table_number,
        i_id_summary_page    IN summary_page.id_summary_page%TYPE,
        i_summary_page_scope IN VARCHAR2 DEFAULT ('E'),
        i_is_ehr             IN VARCHAR2 DEFAULT ('N'),
        o_template           OUT pk_types.cursor_type,
        o_template_prof      OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        --cursors
        l_sections           pk_summary_page.t_cur_section;
        l_sections_tab       pk_summary_page.t_coll_section;
        l_doc_area_register  pk_types.cursor_type;
        l_doc_area_val       pk_types.cursor_type;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
        l_doc_scales         pk_types.cursor_type;
    
        TYPE l_interval IS TABLE OF INTERVAL DAY(9) TO SECOND;
    
        --dummy variables
        l_dummy_str       table_varchar := table_varchar();
        l_dummy_number    table_number := table_number();
        l_dummy_date      table_date := table_date();
        l_dummy_timestamp table_timestamp_tz := table_timestamp_tz();
        l_dummy_interval  l_interval := l_interval();
    
        --get_professionals
        l_id             table_number := table_number();
        l_prof_id        table_number := table_number();
        l_prof_dt        table_varchar := table_varchar();
        l_flg_status     table_varchar := table_varchar();
        l_templ_name     table_varchar := table_varchar();
        l_templ_notes    table_clob := table_clob();
        l_templ_prof_id  table_number := table_number();
        l_doc_area       table_number := table_number();
        l_dt_creation    table_varchar := table_varchar();
        l_dt_last_update table_varchar := table_varchar();
    
        --get_template_details
        l_templ_id               table_number := table_number();
        l_templ_comp_desc        table_varchar := table_varchar();
        w_last_l_templ_comp_desc VARCHAR2(4000);
        l_templ_elem_desc        table_varchar := table_varchar();
    
        --get_scales
        l_scale_id   table_number := table_number();
        l_scale_desc table_varchar := table_varchar();
    
        --counters
        l_template_index      PLS_INTEGER := 0;
        l_template_prof_index PLS_INTEGER := 0;
    
        --prof info to be returned
        l_template_prof_info_table t_tbl_rec_template_prof_info := t_tbl_rec_template_prof_info();
        --templates info to be returned
        l_template_info_table t_tbl_rec_template_info := t_tbl_rec_template_info();
    
        l_value_template_desc CLOB;
        l_templ_id_new        NUMBER := 0;
    
        TYPE tab_template IS TABLE OF CLOB INDEX BY VARCHAR2(100 CHAR);
        TYPE tab_notes IS TABLE OF CLOB INDEX BY VARCHAR2(100 CHAR);
        l_tab_template_name tab_template;
    
        --TYPE tab_template_score IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(100 CHAR);
        l_tab_template_score tab_template;
    
        --TYPE tab_template_notes IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(100 CHAR);
        l_tab_template_notes tab_notes;
    
        --TYPE tab_template_title IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY VARCHAR2(100 CHAR);
        l_tab_template_title tab_template;
    
        l_tab_template_status tab_template;
    
        l_tab_template_dt_creation tab_template;
    
        l_tab_template_dt_last_update tab_template;
    
        l_tab_template_prof tab_template;
        --            
    
        TYPE tab_section_title IS TABLE OF VARCHAR2(32700 CHAR) INDEX BY PLS_INTEGER;
        l_tab_section_title tab_section_title;
    
        l_tab_template_ids tab_template;
    
        l_template_name_str    CLOB;
        l_template_message_str sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DOCUMENTATION_M040');
        l_template_notas_str   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => 'DOCUMENTATION_T010');
    BEGIN
        g_error := 'CALL pk_summary_page.get_summary_page_sections: ' || i_id_summary_page;
        pk_alertlog.log_debug(g_error);
    
        --get_all_summary_pages for a given summary page:
        IF NOT pk_summary_page.get_summary_page_sections(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_id_summary_page => i_id_summary_page,
                                                         i_pat             => i_patient,
                                                         o_sections        => l_sections,
                                                         o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH l_sections';
        pk_alertlog.log_debug(g_error);
        --
        FETCH l_sections BULK COLLECT
            INTO l_sections_tab;
        CLOSE l_sections;
        FOR e IN 1 .. i_episode.count
        LOOP
        
            FOR i IN 1 .. l_sections_tab.count
            LOOP
                pk_alertlog.log_debug('Sections found: ' || l_sections_tab(i).id_doc_area || ' - ' || l_sections_tab(i).translated_code);
                --
                l_tab_section_title(l_sections_tab(i).id_doc_area) := l_sections_tab(i).translated_code;
                --
                IF i_summary_page_scope = pk_diet.g_templates_info_scope_p
                THEN
                    --Get information for the patient scope
                    g_error := 'CALL TO GET_SUMM_PAGE_DOC_AREA_PAT';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_summary_page.get_summ_page_doc_area_pat(i_lang               => i_lang,
                                                                      i_prof               => i_prof,
                                                                      i_episode            => i_episode(e),
                                                                      i_doc_area           => l_sections_tab(i).id_doc_area,
                                                                      o_doc_area_register  => l_doc_area_register,
                                                                      o_doc_area_val       => l_doc_area_val,
                                                                      o_template_layouts   => l_template_layouts,
                                                                      o_doc_area_component => l_doc_area_component,
                                                                      o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                ELSE
                    g_error := 'CALL TO GET_SUMM_PAGE_DOC_AREA_VALUE';
                    pk_alertlog.log_debug(g_error);
                    --Get information for the episode scope
                    IF NOT pk_summary_page.get_summ_page_doc_area_value(i_lang               => i_lang,
                                                                        i_prof               => i_prof,
                                                                        i_episode            => i_episode(e),
                                                                        i_doc_area           => l_sections_tab(i).id_doc_area,
                                                                        o_doc_area_register  => l_doc_area_register,
                                                                        o_doc_area_val       => l_doc_area_val,
                                                                        o_template_layouts   => l_template_layouts,
                                                                        o_doc_area_component => l_doc_area_component,
                                                                        o_error              => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                --PROF
                IF i_summary_page_scope = pk_diet.g_templates_info_scope_p
                THEN
                    g_error := 'FETCH l_doc_area_register scope P';
                    pk_alertlog.log_debug(g_error);
                    FETCH l_doc_area_register BULK COLLECT
                        INTO l_dummy_interval,
                             l_dummy_date,
                             l_id,
                             l_dummy_number,
                             l_templ_prof_id,
                             l_templ_name,
                             l_dt_creation,
                             l_dummy_timestamp,
                             l_prof_dt,
                             l_prof_id,
                             l_dummy_str,
                             l_dummy_str,
                             l_doc_area,
                             l_flg_status,
                             l_dummy_str,
                             l_dummy_number,
                             l_dummy_str,
                             l_templ_notes,
                             l_dt_last_update,
                             l_dummy_timestamp,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str;
                    CLOSE l_doc_area_register;
                ELSE
                    g_error := 'FETCH l_doc_area_register scope E';
                    pk_alertlog.log_debug(g_error);
                    FETCH l_doc_area_register BULK COLLECT
                        INTO l_dummy_interval,
                             l_dummy_date,
                             l_id,
                             l_dummy_number,
                             l_templ_prof_id,
                             l_templ_name,
                             l_dt_creation,
                             l_dummy_timestamp,
                             l_prof_dt,
                             l_prof_id,
                             l_dummy_str,
                             l_dummy_str,
                             l_doc_area,
                             l_flg_status,
                             l_dummy_str,
                             l_dummy_number,
                             l_dummy_str,
                             l_templ_notes,
                             l_dt_last_update,
                             l_dummy_timestamp,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str,
                             l_dummy_str;
                    CLOSE l_doc_area_register;
                END IF;
            
                FOR j IN 1 .. l_id.count
                LOOP
                    l_tab_template_status(l_id(j)) := l_flg_status(j);
                    --prof and data for each template
                    l_tab_template_prof(l_id(j)) := to_clob(l_prof_id(j));
                    --
                    l_tab_template_dt_creation(l_id(j)) := l_dt_creation(j);
                    l_tab_template_dt_last_update(l_id(j)) := l_dt_last_update(j);
                    IF l_flg_status(j) = pk_alert_constant.g_flg_status_a
                    THEN
                        -- ONLY FOR ACTIVE DATA
                        pk_alertlog.log_debug('Profs found: ' || l_id(j) || ' - ' || l_templ_name(j));
                    
                        l_tab_template_name(l_id(j)) := l_templ_name(j);
                        l_tab_template_notes(l_id(j)) := l_templ_notes(j);
                    
                        IF l_tab_section_title.exists(l_doc_area(j))
                        THEN
                            --add only for the first template for each area
                            l_tab_template_title(l_id(j)) := '<b>' || l_tab_section_title(l_doc_area(j)) || '</b>' ||
                                                             chr(10) || chr(10);
                            l_tab_section_title.delete(l_doc_area(j));
                        ELSE
                            l_tab_template_title(l_id(j)) := NULL;
                        END IF;
                    
                        l_template_prof_info_table.extend;
                        l_template_index := l_template_index + 1;
                        l_template_prof_info_table(l_template_index) := t_rec_template_prof_info(l_id(j),
                                                                                                 l_prof_dt(j),
                                                                                                 pk_tools.get_prof_description(i_lang,
                                                                                                                               i_prof,
                                                                                                                               l_prof_id(j),
                                                                                                                               NULL,
                                                                                                                               NULL),
                                                                                                 l_flg_status(j));
                    END IF;
                END LOOP;
            
                --SCALES:
                IF NOT pk_scales_api.get_scales_list_pat(i_lang,
                                                         i_prof,
                                                         l_sections_tab(i).id_doc_area,
                                                         i_episode(e),
                                                         l_doc_scales,
                                                         o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                g_error := 'FETCH l_doc_scales';
                FETCH l_doc_scales BULK COLLECT
                    INTO l_scale_id,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_str,
                         l_scale_desc,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_timestamp,
                         l_dummy_str;
                CLOSE l_doc_scales;
            
                FOR x IN 1 .. l_scale_id.count
                LOOP
                    l_tab_template_score(l_scale_id(x)) := TRIM(chr(10) FROM l_scale_desc(x));
                    --
                    pk_alertlog.log_debug('Scale : ' || l_scale_id(x) || '-' || l_scale_desc(x));
                END LOOP;
            
                --TEMPLATE:
                g_error := 'FETCH l_doc_area_val';
                FETCH l_doc_area_val BULK COLLECT
                    INTO l_templ_id,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_str,
                         l_templ_comp_desc,
                         l_dummy_str,
                         l_templ_elem_desc,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_number,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str,
                         l_dummy_str;
                CLOSE l_doc_area_val;
            
                FOR k IN 1 .. l_templ_id.count
                LOOP
                    --only active data is shown
                    IF l_tab_template_status.exists(l_templ_id(k))
                    THEN
                        pk_alertlog.log_debug('Templates found: ' || l_templ_id(k) || ' - ' || l_templ_comp_desc(k) || '-' ||
                                              l_templ_elem_desc(k));
                        l_tab_template_ids(l_templ_id(k)) := to_clob(l_templ_id(k));
                        IF l_templ_id_new <> l_templ_id(k)
                        THEN
                            --concat info for each template
                            l_templ_id_new := l_templ_id(k);
                        
                            --section title
                            IF l_tab_template_title.exists(l_templ_id(k))
                            THEN
                                l_template_name_str := l_tab_template_title(l_templ_id(k));
                            
                            ELSE
                                l_template_name_str := NULL;
                            END IF;
                            --
                            IF l_tab_template_score.exists(l_templ_id(k))
                            THEN
                                l_template_name_str := l_template_name_str || '<b>' ||
                                                       l_tab_template_score(l_templ_id(k)) || '</b>' || chr(10);
                            ELSE
                                l_template_name_str := l_template_name_str;
                            END IF;
                            --
                            IF l_tab_template_name.exists(l_templ_id(k))
                               AND l_tab_template_name(l_templ_id(k)) IS NOT NULL
                            THEN
                                l_template_name_str := l_template_name_str ||
                                                       pk_paramedical_prof_core.format_str_header_w_colon(l_template_message_str) ||
                                                       htf.escape_sc(l_tab_template_name(l_templ_id(k))) || chr(10);
                            ELSE
                                l_template_name_str := l_template_name_str;
                            END IF;
                        
                            --add the template name:
                            l_value_template_desc := l_template_name_str ||
                                                     pk_paramedical_prof_core.format_str_header_w_colon(l_templ_comp_desc(k)) ||
                                                     htf.escape_sc(l_templ_elem_desc(k));
                        
                            l_template_info_table.extend;
                            l_template_prof_index := l_template_prof_index + 1;
                            l_template_info_table(l_template_prof_index) := t_rec_template_info(l_templ_id(k),
                                                                                                i_episode(e),
                                                                                                l_value_template_desc);
                        ELSE
                        
                            -- ALERT-223691 - 30-04-2013 - M?o Mineiro - Duplicated template titles. Solution: No description no titles.                        
                        
                            IF htf.escape_sc(l_templ_elem_desc(k)) IS NOT NULL
                            THEN
                                IF w_last_l_templ_comp_desc != l_templ_comp_desc(k)
                                THEN
                                    l_value_template_desc := l_value_template_desc || chr(10);
                                    l_value_template_desc := l_value_template_desc ||
                                                             pk_paramedical_prof_core.format_str_header_w_colon(l_templ_comp_desc(k));
                                END IF;
                            
                                l_value_template_desc := l_value_template_desc || htf.escape_sc(l_templ_elem_desc(k));
                                l_value_template_desc := l_value_template_desc || '; ';
                            
                                l_template_info_table(l_template_prof_index) := t_rec_template_info(l_templ_id(k),
                                                                                                    i_episode(e),
                                                                                                    l_value_template_desc);
                            
                            END IF;
                        
                        END IF;
                    END IF;
                
                    w_last_l_templ_comp_desc := l_templ_comp_desc(k);
                
                END LOOP;
                ----
            
                --free text:
                FOR a IN 1 .. l_id.count
                LOOP
                    --we found prof and not the template
                    g_error := 'add free text';
                    IF NOT l_tab_template_ids.exists(l_id(a))
                       AND l_tab_template_status(l_id(a)) = pk_alert_constant.g_flg_status_a
                    THEN
                        IF l_tab_template_notes.exists(l_id(a))
                           AND l_tab_template_notes(l_id(a)) IS NOT NULL
                        THEN
                            pk_alertlog.log_debug('Free text: ' || l_id(a));
                            l_template_info_table.extend;
                            l_template_prof_index := l_template_prof_index + 1;
                            IF l_templ_prof_id(a) IS NULL
                            THEN
                                l_template_info_table(l_template_prof_index) := t_rec_template_info(l_id(a),
                                                                                                    i_episode(e),
                                                                                                    l_tab_template_title(l_id(a)) ||
                                                                                                    htf.escape_sc(l_tab_template_notes(l_id(a))) || CASE
                                                                                                        WHEN i_is_ehr = pk_alert_constant.g_yes THEN
                                                                                                         chr(10) ||
                                                                                                         pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                                                                                                           i_prof,
                                                                                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                                         i_prof,
                                                                                                                                                                                         l_tab_template_dt_creation(l_id(a)),
                                                                                                                                                                                         NULL),
                                                                                                                                                           to_number(l_tab_template_prof(l_id(a))),
                                                                                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                                         i_prof,
                                                                                                                                                                                         l_tab_template_dt_last_update(l_id(a)),
                                                                                                                                                                                         NULL),
                                                                                                                                                           i_episode(e))
                                                                                                        ELSE
                                                                                                         ''
                                                                                                    END);
                            ELSE
                                --Add template but only with notes
                                l_template_info_table(l_template_prof_index) := t_rec_template_info(l_id(a),
                                                                                                    i_episode(e),
                                                                                                    l_tab_template_title(l_id(a)) ||
                                                                                                    pk_paramedical_prof_core.format_str_header_w_colon(l_template_message_str) ||
                                                                                                    l_tab_template_name(l_id(a)) || chr(10) ||
                                                                                                    chr(10) ||
                                                                                                    pk_paramedical_prof_core.format_str_header_w_colon(l_template_notas_str) ||
                                                                                                    htf.escape_sc(l_tab_template_notes(l_id(a))) || CASE
                                                                                                        WHEN i_is_ehr = pk_alert_constant.g_yes THEN
                                                                                                         chr(10) ||
                                                                                                         pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                                                                                                           i_prof,
                                                                                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                                         i_prof,
                                                                                                                                                                                         l_tab_template_dt_creation(l_id(a)),
                                                                                                                                                                                         NULL),
                                                                                                                                                           to_number(l_tab_template_prof(l_id(a))),
                                                                                                                                                           pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                                                         i_prof,
                                                                                                                                                                                         l_tab_template_dt_last_update(l_id(a)),
                                                                                                                                                                                         NULL),
                                                                                                                                                           i_episode(e))
                                                                                                        ELSE
                                                                                                         ''
                                                                                                    END);
                            END IF;
                        END IF;
                    END IF;
                END LOOP;
            END LOOP;
        
            --add notes:
            FOR z IN 1 .. l_template_info_table.count
            LOOP
                pk_alertlog.log_debug('Add notes for the template: ' || l_template_info_table(z).id);
                IF l_tab_template_notes.exists(l_template_info_table(z).id)
                  --and not for templates with only notes
                   AND l_tab_template_ids.exists(l_template_info_table(z).id)
                THEN
                    IF dbms_lob.getlength(l_tab_template_notes(l_template_info_table(z).id)) != 0
                    THEN
                        l_template_info_table(z) := t_rec_template_info(l_template_info_table(z).id,
                                                                        l_template_info_table(z).id_episode,
                                                                        l_template_info_table(z).desc_template || chr(10) || chr(10) ||
                                                                         pk_paramedical_prof_core.format_str_header_w_colon(l_template_notas_str) ||
                                                                         htf.escape_sc(l_tab_template_notes(l_template_info_table(z).id)) || CASE
                                                                             WHEN i_is_ehr = pk_alert_constant.g_yes THEN
                                                                              chr(10) ||
                                                                              pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                                                                                i_prof,
                                                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                              i_prof,
                                                                                                                                                              l_tab_template_dt_creation(l_template_info_table(z).id),
                                                                                                                                                              NULL),
                                                                                                                                to_number(l_tab_template_prof(l_template_info_table(z).id)),
                                                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                              i_prof,
                                                                                                                                                              l_tab_template_dt_last_update(l_template_info_table(z).id),
                                                                                                                                                              NULL),
                                                                                                                                l_template_info_table(z).id_episode)
                                                                             ELSE
                                                                              ''
                                                                         END);
                    ELSE
                        l_template_info_table(z) := t_rec_template_info(l_template_info_table(z).id,
                                                                        l_template_info_table(z).id_episode,
                                                                        l_template_info_table(z).desc_template || CASE
                                                                             WHEN i_is_ehr = pk_alert_constant.g_yes THEN
                                                                              chr(10) ||
                                                                              pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                                                                                i_prof,
                                                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                              i_prof,
                                                                                                                                                              l_tab_template_dt_creation(l_template_info_table(z).id),
                                                                                                                                                              NULL),
                                                                                                                                to_number(l_tab_template_prof(l_template_info_table(z).id)),
                                                                                                                                pk_date_utils.get_string_tstz(i_lang,
                                                                                                                                                              i_prof,
                                                                                                                                                              l_tab_template_dt_last_update(l_template_info_table(z).id),
                                                                                                                                                              NULL),
                                                                                                                                l_template_info_table(z).id_episode)
                                                                             ELSE
                                                                              ''
                                                                         END);
                    END IF;
                END IF;
            END LOOP;
        END LOOP;
        --
        OPEN o_template FOR
            SELECT t.*
              FROM TABLE(l_template_info_table) t
             ORDER BY t.id DESC;
    
        OPEN o_template_prof FOR
            SELECT *
              FROM TABLE(l_template_prof_info_table);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_template);
            pk_types.open_my_cursor(o_template_prof);
            -- Unexpected error
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_TEMPLATES_SUMMARY',
                                                     o_error);
        
    END get_templates_summary;
    --

    /********************************************************************************************
    * Get nutritian episode origin type
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @ param i_id_epis               Episode ID
    *
    * @return                         A for appointments or R for requests
    *
    * @author                          Orlando Antunes
    * @version                         0.1
    * @since                           2010/03/24
    **********************************************************************************************/
    FUNCTION get_nutritian_epis_origin_type
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_epis IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        --
        l_social_epis      VARCHAR2(1 CHAR);
        l_count            PLS_INTEGER;
        l_count_apointment PLS_INTEGER;
    BEGIN
        g_error := 'GET_SOCIAL_EPIS_TYPE BEGIN';
        pk_alertlog.log_debug(g_error);
        --
        SELECT COUNT(*)
          INTO l_count
          FROM opinion o
         WHERE o.id_episode_answer = i_id_epis;
        --
        SELECT COUNT(*)
          INTO l_count_apointment
          FROM epis_info ei
          JOIN consult_req cr
            ON (ei.id_schedule = cr.id_schedule)
         WHERE ei.id_episode = i_id_epis;
        --
    
        IF l_count <> 0
        THEN
            --request
            l_social_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_r;
        ELSIF l_count_apointment <> 0
        THEN
            --appointment request
            l_social_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_c;
        ELSE
            --appointment
            l_social_epis := pk_paramedical_prof_core.g_paramedical_epis_origin_a;
        END IF;
        RETURN l_social_epis;
    EXCEPTION
        WHEN OTHERS THEN
            --
            RETURN l_social_epis;
    END get_nutritian_epis_origin_type;
    --

    /*
    * Get Nutritian requests list.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_requests_prof  requests cursor prof
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Orlando Antnes
    * @version                 2.6.0.1
    * @since                  2010/04/16
    */
    FUNCTION get_dietitian_requests_summary
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        g_error := 'GET_SOCIAL_REQUESTS_SUMMARY BEGIN';
        pk_alertlog.log_debug(g_error);
    
        IF get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'R'
        THEN
            IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                              i_code_msg_arr => table_varchar('DIET_T009',
                                                                                              'CONSULT_REQUEST_T003',
                                                                                              'CONSULT_REQUEST_T024',
                                                                                              'CONSULT_REQUEST_T004',
                                                                                              'SCH_T004'),
                                                              i_prof         => i_prof,
                                                              o_desc_msg_arr => t_table_message_array)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            g_error := 'OPEN o_requests';
            OPEN o_requests FOR
                SELECT o.id_opinion        id,
                       o.id_episode_answer id_episode,
                       --
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T024')) ||
                       nvl((SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                             FROM clinical_service cs
                            WHERE cs.id_clinical_service = o.id_clinical_service),
                           pk_paramedical_prof_core.c_dashes) request_type,
                       --reason
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T003')) ||
                       nvl(decode(o.id_opinion_type,
                                  pk_opinion.g_ot_case_manager,
                                  pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                                  o.desc_problem),
                           pk_paramedical_prof_core.c_dashes) request_reason,
                       --origin
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T004')) ||
                       pk_translation.get_translation(i_lang, et.code_epis_type) || pk_opinion.g_dash ||
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) || ' (' ||
                       nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                           pk_paramedical_prof_core.c_dashes) || ')' request_origin,
                       --profissional      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                       nvl2(o.id_prof_questioned,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                            l_label_any_prof) name_prof_request_type,
                       --notas
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) ||
                       nvl(o.notes, pk_paramedical_prof_core.c_dashes) prof_answers,
                       pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                         i_prof,
                                                                         o.dt_problem_tstz,
                                                                         op.id_professional,
                                                                         o.dt_last_update,
                                                                         o.id_episode) last_update_info
                  FROM opinion o
                  LEFT OUTER JOIN opinion_prof op
                    ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
                  LEFT OUTER JOIN opinion_type ot
                    ON ot.id_opinion_type = o.id_opinion_type
                  LEFT OUTER JOIN episode e
                    ON e.id_episode = o.id_episode
                  LEFT OUTER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                  LEFT OUTER JOIN clinical_service cs
                    ON cs.id_clinical_service = o.id_clinical_service
                 WHERE o.id_episode_answer = i_episode
                 ORDER BY o.dt_approved DESC;
        
            --
            g_error := 'OPEN o_requests_prof';
            OPEN o_requests_prof FOR
                SELECT o.id_opinion id,
                       o.id_episode_answer id_episode,
                       pk_tools.get_prof_description(i_lang, i_prof, op.id_professional, o.dt_last_update, o.id_episode) prof_sign,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) dt,
                       o.flg_state flg_status,
                       pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang) desc_status
                  FROM opinion o
                  LEFT OUTER JOIN opinion_prof op
                    ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
                  LEFT OUTER JOIN opinion_type ot
                    ON ot.id_opinion_type = o.id_opinion_type
                  LEFT OUTER JOIN episode e
                    ON e.id_episode = o.id_episode
                  LEFT OUTER JOIN epis_type et
                    ON et.id_epis_type = e.id_epis_type
                  LEFT OUTER JOIN clinical_service cs
                    ON cs.id_clinical_service = o.id_clinical_service
                 WHERE o.id_episode_answer = i_episode
                 ORDER BY o.dt_problem_tstz DESC;
            --
        ELSIF pk_diet.get_nutritian_epis_origin_type(i_lang, i_prof, i_episode) = 'C'
        THEN
        
            IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                              i_code_msg_arr => table_varchar('DIET_T009',
                                                                                              'CONSULT_REQ_T015',
                                                                                              'CONSULT_REQUEST_T024',
                                                                                              'SCH_T004'),
                                                              i_prof         => i_prof,
                                                              o_desc_msg_arr => t_table_message_array)
            THEN
                RAISE g_exception;
            END IF;
        
            --
            g_error := 'OPEN o_requests';
            OPEN o_requests FOR
                SELECT cr.id_consult_req id,
                       ei.id_episode     id_episode,
                       --reason
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQ_T015')) ||
                       cr.notes request_reason,
                       --profissional      
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                       nvl2(crp.id_professional,
                            pk_prof_utils.get_name_signature(i_lang, i_prof, crp.id_professional),
                            l_label_any_prof) name_prof_request_type,
                       --notas
                       pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) ||
                       crp.denial_justif prof_answers
                  FROM epis_info ei
                  JOIN consult_req cr
                    ON (ei.id_schedule = cr.id_schedule)
                  JOIN consult_req_prof crp
                    ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
                 WHERE ei.id_episode = i_episode
                 ORDER BY cr.dt_scheduled_tstz DESC;
        
            --
            g_error := 'OPEN o_requests_prof';
            OPEN o_requests_prof FOR
                SELECT cr.id_consult_req id,
                       ei.id_episode id_episode,
                       pk_tools.get_prof_description(i_lang,
                                                     i_prof,
                                                     cr.id_prof_req,
                                                     crp.dt_consult_req_prof_tstz,
                                                     ei.id_episode) prof_sign,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt,
                       crp.flg_status flg_status,
                       pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', crp.flg_status, i_lang) desc_status
                  FROM epis_info ei
                  JOIN consult_req cr
                    ON (ei.id_schedule = cr.id_schedule)
                  JOIN consult_req_prof crp
                    ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
                 WHERE ei.id_episode = i_episode
                 ORDER BY cr.dt_scheduled_tstz DESC;
            --
        ELSE
            --this episode is an appointment
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DIETITIAN_REQUESTS_SUMMARY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
            RETURN FALSE;
    END get_dietitian_requests_summary;

    /*
    * Get Nutritian requests list based on get_dietitian_requests_summary
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        list of episodes
    * @param o_requests       requests cursor
    * @param o_requests_prof  requests cursor prof
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Elisabete Bugalho
    * @version                 2.6.0.3
    * @since                  2010/12/06
    */
    FUNCTION get_dietitian_requests_sum_ehr
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN table_number,
        o_requests      OUT pk_types.cursor_type,
        o_requests_prof OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        t_table_message_array pk_paramedical_prof_core.table_message_array;
        l_label_any_prof      sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                      i_prof,
                                                                                      'CONSULT_REQUEST_T021');
    BEGIN
        g_error := 'GET_DIETITIAN_REQUESTS_SUMMARY_EHR BEGIN';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_paramedical_prof_core.get_message_array(i_lang         => i_lang,
                                                          i_code_msg_arr => table_varchar('DIET_T009',
                                                                                          'CONSULT_REQUEST_T003',
                                                                                          'CONSULT_REQUEST_T024',
                                                                                          'CONSULT_REQUEST_T004',
                                                                                          'SCH_T004',
                                                                                          'CONSULT_REQ_T015'),
                                                          i_prof         => i_prof,
                                                          o_desc_msg_arr => t_table_message_array)
        THEN
            RAISE g_exception;
        END IF;
        OPEN o_requests FOR
            SELECT o.id_opinion        id,
                   o.id_episode_answer id_episode,
                   --
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T024')) ||
                   nvl((SELECT pk_translation.get_translation(i_lang, cs.code_clinical_service)
                         FROM clinical_service cs
                        WHERE cs.id_clinical_service = o.id_clinical_service),
                       pk_paramedical_prof_core.c_dashes) request_type,
                   --reason
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T003')) ||
                   nvl(decode(o.id_opinion_type,
                              pk_opinion.g_ot_case_manager,
                              pk_opinion.get_cm_req_reason(i_lang, i_prof, o.id_opinion),
                              o.desc_problem),
                       pk_paramedical_prof_core.c_dashes) request_reason,
                   --origin
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQUEST_T004')) ||
                   pk_translation.get_translation(i_lang, et.code_epis_type) || pk_opinion.g_dash ||
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, o.id_prof_questions, NULL, o.id_episode) || ' (' ||
                   nvl(pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questions),
                       pk_paramedical_prof_core.c_dashes) || ')' request_origin,
                   --profissional      
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                   nvl2(o.id_prof_questioned,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, o.id_prof_questioned),
                        l_label_any_prof) name_prof_request_type,
                   --notas
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) ||
                   nvl(pk_string_utils.clob_to_sqlvarchar2(o.notes), pk_paramedical_prof_core.c_dashes) prof_answers,
                   pk_paramedical_prof_core.get_ehr_last_update_info(i_lang,
                                                                     i_prof,
                                                                     o.dt_problem_tstz,
                                                                     op.id_professional,
                                                                     o.dt_last_update,
                                                                     o.id_episode) last_update_info
              FROM opinion o
              LEFT OUTER JOIN opinion_prof op
                ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
              LEFT OUTER JOIN opinion_type ot
                ON ot.id_opinion_type = o.id_opinion_type
              LEFT OUTER JOIN episode e
                ON e.id_episode = o.id_episode
              LEFT OUTER JOIN epis_type et
                ON et.id_epis_type = e.id_epis_type
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
             WHERE o.id_episode_answer IN (SELECT column_value
                                             FROM TABLE(i_episode))
            UNION
            SELECT cr.id_consult_req id,
                   ei.id_episode     id_episode,
                   NULL              request_type,
                   --reason
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('CONSULT_REQ_T015')) ||
                   cr.notes request_reason,
                   NULL request_origin,
                   --profissional      
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('SCH_T004')) ||
                   nvl2(crp.id_professional,
                        pk_prof_utils.get_name_signature(i_lang, i_prof, crp.id_professional),
                        l_label_any_prof) name_prof_request_type,
                   --notas
                   pk_paramedical_prof_core.format_str_header_w_colon(t_table_message_array('DIET_T009')) ||
                   crp.denial_justif prof_answers,
                   NULL last_update_info
              FROM epis_info ei
              JOIN consult_req cr
                ON (ei.id_schedule = cr.id_schedule)
              JOIN consult_req_prof crp
                ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
             WHERE ei.id_episode IN (SELECT column_value
                                       FROM TABLE(i_episode));
    
        g_error := 'OPEN o_requests_prof';
        OPEN o_requests_prof FOR
            SELECT o.id_opinion id,
                   o.id_episode_answer id_episode,
                   pk_tools.get_prof_description(i_lang, i_prof, op.id_professional, o.dt_last_update, o.id_episode) prof_sign,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, o.dt_problem_tstz, i_prof) dt,
                   o.flg_state flg_status,
                   pk_sysdomain.get_domain('OPINION.FLG_STATE', o.flg_state, i_lang) desc_status
              FROM opinion o
              LEFT OUTER JOIN opinion_prof op
                ON (o.id_opinion = op.id_opinion AND op.flg_type = 'E')
              LEFT OUTER JOIN opinion_type ot
                ON ot.id_opinion_type = o.id_opinion_type
              LEFT OUTER JOIN episode e
                ON e.id_episode = o.id_episode
              LEFT OUTER JOIN epis_type et
                ON et.id_epis_type = e.id_epis_type
              LEFT OUTER JOIN clinical_service cs
                ON cs.id_clinical_service = o.id_clinical_service
             WHERE o.id_episode_answer IN (SELECT column_value
                                             FROM TABLE(i_episode))
            UNION
            SELECT cr.id_consult_req id,
                   ei.id_episode id_episode,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 cr.id_prof_req,
                                                 crp.dt_consult_req_prof_tstz,
                                                 ei.id_episode) prof_sign,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, cr.dt_consult_req_tstz, i_prof) dt,
                   crp.flg_status flg_status,
                   pk_sysdomain.get_domain('CONSULT_REQ.FLG_STATUS', crp.flg_status, i_lang) desc_status
              FROM epis_info ei
              JOIN consult_req cr
                ON (ei.id_schedule = cr.id_schedule)
              JOIN consult_req_prof crp
                ON (crp.id_consult_req = cr.id_consult_req AND crp.flg_status = 'A')
             WHERE ei.id_episode IN (SELECT column_value
                                       FROM TABLE(i_episode));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_DIETITIAN_REQUESTS_SUMMARY',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_requests);
            pk_types.open_my_cursor(o_requests_prof);
            RETURN FALSE;
    END get_dietitian_requests_sum_ehr;

    /********************************************************************************************
    * Get the Follow-up requests summary, concatenated as a String (CLOB).
    * The information includes: Diagnosis, Intervention plans, Follow-up notes and Social report
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_patient                Patient ID
    * @ param i_episode               Episode ID (Epis type = Social Worker)
    * @ param o_follow_up_request_summary  Array with all information, where each 
    *                                      position has a diferent type of data.
    *
    * @param o_error                  Error Message
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.1
    * @since                           2010/04/21
    **********************************************************************************************/
    FUNCTION get_follow_up_req_sum_str
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        o_follow_up_request_summary OUT table_clob,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_follow_up_request_summary table_clob := table_clob();
        l_summary_temp              CLOB;
        l_summary_index             PLS_INTEGER := 1;
    BEGIN
        pk_alertlog.log_debug('GET_FOLLOW_UP_REQ_SUM_STR - get follow up requests summary as a string!');
        --title
        g_error := 'Get title';
        l_follow_up_request_summary.extend;
        l_follow_up_request_summary(l_summary_index) := pk_message.get_message(i_lang, 'CONSULT_REQUEST_T031') ||
                                                        '<br>';
        l_summary_index := l_summary_index + 1;
    
        --create complete summary:
        g_error := 'Get Diagnosis summary str';
        --1 - Diagnosis
        IF NOT pk_paramedical_prof_core.get_summ_page_diag_str(i_lang          => i_lang,
                                                               i_prof          => i_prof,
                                                               i_patient       => i_patient,
                                                               i_episode       => i_episode,
                                                               i_opinion_type  => pk_opinion.g_ot_dietitian,
                                                               o_diagnosis_str => l_summary_temp,
                                                               o_error         => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
        g_error := 'Get Intervention plan summary str';
        --2 - Intervention plans
        IF NOT pk_paramedical_prof_core.get_interv_plan_summary_str(i_lang                 => i_lang,
                                                                    i_prof                 => i_prof,
                                                                    i_patient              => i_patient,
                                                                    i_episode              => i_episode,
                                                                    i_opinion_type         => pk_opinion.g_ot_dietitian,
                                                                    o_interv_plan_summ_str => l_summary_temp,
                                                                    o_error                => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
    
        g_error := 'Get Follow up notes summary str';
        --3 - Follow-up notes
        IF NOT pk_paramedical_prof_core.get_followup_notes_str(i_lang      => i_lang,
                                                               i_prof      => i_prof,
                                                               i_episode   => i_episode,
                                                               o_follow_up => l_summary_temp,
                                                               o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
    
        g_error := 'Get Follow up notes summary str';
        --4 - Reports
        IF NOT pk_paramedical_prof_core.get_paramed_report_str(i_lang         => i_lang,
                                                               i_prof         => i_prof,
                                                               i_episode      => i_episode,
                                                               i_opinion_type => pk_opinion.g_ot_dietitian,
                                                               o_report       => l_summary_temp,
                                                               o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_summary_temp IS NOT NULL
        THEN
            l_follow_up_request_summary.extend;
            l_follow_up_request_summary(l_summary_index) := l_summary_temp;
            l_summary_index := l_summary_index + 1;
        END IF;
        --
        o_follow_up_request_summary := l_follow_up_request_summary;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang,
                                                     SQLCODE,
                                                     SQLERRM,
                                                     g_error,
                                                     g_package_owner,
                                                     g_package_name,
                                                     'GET_FOLLOW_UP_REQ_SUM_STR',
                                                     o_error);
        
    END get_follow_up_req_sum_str;
    --

    /********************************************************************************************
    * Get all active Diets available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return       tf_tasks_list            table of tr_tasks_list
    *
    * @author                                Orlando Antunes                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_diets
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
        l_ongoing_tasks tf_tasks_list;
    BEGIN
        g_error := 'GET_ONGOING_TASKS_DIETS: i_patient = ' || i_patient;
        pk_alertlog.log_debug(g_error);
    
        SELECT tr_tasks_list(diets.id_task, diets.desc_task, diets.epis_type, diets.dt_task)
          BULK COLLECT
          INTO l_ongoing_tasks
          FROM (SELECT edr.id_epis_diet_req id_task,
                       get_diet_description_internal2(i_lang, i_prof, edr.id_epis_diet_req, g_diet_descr_format_s) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang, edr.dt_creation, i_prof.institution, i_prof.software) dt_task
                  FROM epis_diet_req edr
                  JOIN episode epi
                    ON (epi.id_episode = edr.id_episode)
                  JOIN epis_type et
                    ON (et.id_epis_type = epi.id_epis_type)
                 WHERE edr.id_patient = i_patient
                   AND edr.flg_status NOT IN
                       (g_flg_diet_status_t, g_flg_diet_status_x, g_flg_diet_status_s, g_flg_diet_status_c)
                   AND NOT EXISTS (SELECT 1
                          FROM epis_diet_req e
                         WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                 ORDER BY dt_task DESC) diets;
    
        RETURN l_ongoing_tasks;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ongoing_tasks_diets;
    --

    /********************************************************************************************
    * Suspend a given patient's Diet
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 Diet id
    * @param       i_flg_reason              Reason for the WF suspension: 'D' (Death)
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION suspend_task_diet
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task       IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_reason    IN VARCHAR2,
        i_cancel_reason IN cancel_reason.id_cancel_reason%TYPE DEFAULT NULL,
        i_force_cancel  IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_msg_error     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note                    epis_diet_req.notes_cancel%TYPE;
        l_cancel_reason_id_contet sys_config.value%TYPE;
        l_cancel_reason_id        cancel_reason.id_cancel_reason%TYPE;
    BEGIN
        g_error := 'SUSPEND_TASK_DIET: i_id_task = ' || i_id_task;
        pk_alertlog.log_debug(g_error);
        --
        BEGIN
        
            IF i_cancel_reason IS NULL
            THEN
                g_error                   := 'GET_CANCEL_REASON: i_id_task = ' || i_id_task;
                l_cancel_reason_id_contet := pk_sysconfig.get_config(i_code_cf => 'DIET_SUSPEND_PATIENT_DEATH',
                                                                     i_prof    => i_prof);
                IF l_cancel_reason_id_contet IS NULL
                THEN
                    --bad parametrization
                    RAISE g_exception;
                END IF;
            
                SELECT c.id_cancel_reason
                  INTO l_cancel_reason_id
                  FROM cancel_reason c
                 WHERE c.id_content = l_cancel_reason_id_contet;
                pk_alertlog.log_debug('ID CANCEL REASON TO USE: l_cancel_reason_id = ' || l_cancel_reason_id);
            
            ELSE
                l_cancel_reason_id := i_cancel_reason;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_cancel_reason_id := NULL;
        END;
    
        IF i_flg_reason = pk_death_registry.c_flg_reason_death
        THEN
            l_note := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_death_registry.c_code_msg_death);
        ELSE
            l_note := NULL;
        END IF;
    
        IF NOT suspend_diet(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_diet        => i_id_task,
                            i_notes          => l_note,
                            i_reason         => l_cancel_reason_id,
                            i_dt_initial_str => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                   current_timestamp,
                                                                                   'YYYYMMDDHH24MISS'),
                            i_dt_end_str     => NULL,
                            i_force_cancel   => i_force_cancel,
                            i_commit         => pk_alert_constant.get_no,
                            o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --
        -- There is none situation that makes this cancel impossible
        o_msg_error := NULL;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_msg_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T128');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SUSPEND_TASK_DIET',
                                              o_error);
            RETURN FALSE;
    END suspend_task_diet;
    --

    /********************************************************************************************
    * Reactivate a given patient's Diet, in case of error. 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_task                 epis_positioning id
    * @param       o_msg_error               cursor with all data
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION reactivate_task_diet
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_task   IN epis_diet_req.id_epis_diet_req%TYPE,
        o_msg_error OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        --episode
        l_episode episode.id_episode%TYPE;
        --
        CURSOR c_diet IS
            SELECT e.id_episode
              FROM epis_diet_req e
             WHERE id_epis_diet_req = i_id_task;
    BEGIN
        g_error := 'REACTIVATE_TASK_DIET: i_id_task = ' || i_id_task;
        pk_alertlog.log_debug(g_error);
        --
    
        g_error := 'GET_ID_EPISODE';
        OPEN c_diet;
        FETCH c_diet
            INTO l_episode;
        CLOSE c_diet;
    
        IF NOT resume_diet(i_lang           => i_lang,
                           i_prof           => i_prof,
                           i_episode        => l_episode,
                           i_id_diet        => i_id_task,
                           i_notes          => NULL,
                           i_dt_initial_str => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                  current_timestamp,
                                                                                  'YYYYMMDDHH24MISS'),
                           i_dt_end_str     => NULL,
                           i_commit         => pk_alert_constant.g_no,
                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- There is none situation that makes this reactivation impossible
        o_msg_error := NULL;
        --
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_msg_error := pk_message.get_message(i_lang => i_lang, i_code_mess => 'DIET_T129');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'REACTIVATE_TASK_DIET',
                                              o_error);
            RETURN FALSE;
    END reactivate_task_diet;
    --

    /********************************************************************************************
    * Provide list of reactivatable Diets tasks for the patient death feature. 
    * All Diets must have been suspended due to death and must not have been marked as canceled or finalized.
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_susp_action          SUSP_ACTION ID
    * @param       i_wfstatus                Pretended WF Status (from the SUSP_TASK table)
    *
    * @return      tf_tasks_list (table of tr_tasks_list)
    *
    * @author                                Orlando Antunes
    * @version                               2.6.0.3
    * @since                                 2010/Jun/21
    ********************************************************************************************/
    FUNCTION get_wfstatus_tasks_diets
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_susp_action IN susp_task.id_susp_action%TYPE,
        i_wfstatus       IN susp_task.flg_status%TYPE
    ) RETURN tf_tasks_react_list IS
    
        t tf_tasks_react_list;
    
    BEGIN
        g_error := 'GET_WFSTATUS_TASKS_DIETS: i_id_susp_action = ' || i_id_susp_action;
        pk_alertlog.log_debug(g_error);
    
        SELECT tr_tasks_react_list(id_task, id_susp_task, desc_task, epis_type, dt_task)
          BULK COLLECT
          INTO t
          FROM (SELECT edr.id_epis_diet_req id_task,
                        st.id_susp_task,
                        REPLACE(REPLACE(get_diet_description_internal2(i_lang,
                                                                       i_prof,
                                                                       edr.id_epis_diet_req,
                                                                       g_diet_descr_format_s),
                                        '<b>',
                                        ''),
                                '</b>',
                                '') desc_task,
                        pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                        pk_date_utils.dt_chr_date_hour_tsz(i_lang, edr.dt_creation, i_prof.institution, i_prof.software) dt_task
                   FROM susp_task st
                   JOIN susp_task_diets std
                     ON std.id_susp_task = st.id_susp_task
                   JOIN epis_diet_req edr
                     ON (edr.id_epis_diet_req = std.id_epis_diet_req OR
                        edr.id_epis_diet_req_parent = std.id_epis_diet_req)
                   JOIN episode epi
                     ON (epi.id_episode = edr.id_episode)
                   JOIN epis_type et
                     ON (et.id_epis_type = epi.id_epis_type)
                  WHERE st.id_susp_action = i_id_susp_action
                    AND NOT EXISTS (SELECT 1
                           FROM epis_diet_req e
                          WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                    AND st.flg_status = i_wfstatus
                       --Only the Diets that are not changed after the patient's death are returned
                      --(those that are suspended)
                   AND ((i_wfstatus = g_flg_diet_status_s AND edr.flg_status = g_flg_diet_status_s) OR
                       i_wfstatus <> g_flg_diet_status_s)
                 ORDER BY dt_task DESC);
        RETURN t;
    
    END get_wfstatus_tasks_diets;

    /********************************************************************************************
    * Get Diets tasks status based in their requests
    *
    * @param       i_lang                 language id    
    * @param       i_prof                 professional structure
    * @param       i_episode              episode id
    * @param       i_task_request         array of diets requests
    * @param       o_task_status          cursor with all requested diets tasks status
    * @param       o_error                error structure for exception handling
    *
    * @return      boolean                true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.x
    * @since                              2010/09/16       
    ********************************************************************************************/
    FUNCTION get_task_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN table_number,
        o_task_status  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'pk_diet.get_task_status: i_episode = ' || i_episode;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Open cursor o_task_status';
        OPEN o_task_status FOR
            SELECT edr.id_diet_type task_type,
                   edr.id_epis_diet_req id_task_request,
                   get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req, g_status_type_c) flg_status
              FROM epis_diet_req edr, diet_type dt
             WHERE edr.id_episode = i_episode
               AND NOT EXISTS (SELECT 1
                      FROM epis_diet_req e
                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
               AND edr.id_diet_type = dt.id_diet_type
               AND edr.id_epis_diet_req IN (SELECT /*+ OPT_ESTIMATE(table,t,scale_rows=0.000001)*/
                                             d.column_value
                                              FROM TABLE(i_task_request) d);
    
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
                                              'GET_TASK_STATUS',
                                              o_error);
            pk_types.open_my_cursor(o_task_status);
            RETURN FALSE;
    END get_task_status;
    --

    /**********************************************************************************************
    * Cancel all Diet draft tasks
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return         boolean             true on success, otherwise false
    *
    * @author                             Orlando Antunes
    * @version                            2.5.1.x
    * @since                              2010/09/16       
    ********************************************************************************************/
    FUNCTION cancel_all_drafts
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_drafts table_number;
    BEGIN
        pk_alertlog.log_debug('pk_diet.cancel_all_drafts: i_episode = ' || i_episode);
        g_error := 'Get all Draft Diets';
        SELECT edr.id_epis_diet_req
          BULK COLLECT
          INTO l_drafts
          FROM epis_diet_req edr
         WHERE edr.id_episode = i_episode
           AND NOT EXISTS (SELECT 1
                  FROM epis_diet_req e
                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
           AND edr.flg_status = g_flg_diet_status_t;
    
        IF l_drafts IS NOT NULL
           AND l_drafts.count > 0
        THEN
            IF NOT cancel_draft(i_lang    => i_lang,
                                i_prof    => i_prof,
                                i_episode => i_episode,
                                i_draft   => l_drafts,
                                o_error   => o_error)
            THEN
                RAISE g_exception;
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
                                              'CANCEL_ALL_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END cancel_all_drafts;
    --

    FUNCTION to_string
    (
        i_table     IN table_varchar,
        i_separator IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2 IS
        l_result VARCHAR2(32767) := '';
    BEGIN
        IF i_table IS NULL
        THEN
            l_result := '';
        ELSIF i_table.count = 0
        THEN
            l_result := '';
        ELSE
            FOR i IN 1 .. i_table.count
            LOOP
                l_result := l_result || i_table(i) || i_separator;
            END LOOP;
        END IF;
    
        RETURN l_result;
    
    END to_string;

    /**********************************************************************************************
    * Get active diets (this logic has been copy exactly the same present in inpatient's main grid)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Filipe Silva
    * @version                            2.6.1.2
    * @since                              2011/07/22      
    ********************************************************************************************/
    FUNCTION get_active_diet_description
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_diet_desc    table_varchar;
        l_active_diets VARCHAR2(2000 CHAR);
    
    BEGIN
    
        BEGIN
        
            SELECT decode(edr.id_diet_type,
                          g_diet_type_inst,
                          decode(((SELECT COUNT(DISTINCT pk_utils.query_to_string('SELECT edda.id_diet 
                                                                                     FROM epis_diet_det edda 
                                                                                    WHERE edda.id_diet_schedule = ' ||
                                                                         edd.id_diet_schedule || ' 
                                                                                      AND edda.id_epis_diet_req = ' ||
                                                                         edd.id_epis_diet_req,
                                                                         ', '))
                                     FROM epis_diet_det edd
                                    WHERE id_epis_diet_req = edr.id_epis_diet_req)),
                                 1,
                                 --institutionalized and only with one record
                                 (SELECT pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                  ', d.code_diet)
                                                                     FROM epis_diet_det edd1, diet d
                                                                    WHERE edd1.id_epis_diet_req = ' ||
                                                                  edd.id_epis_diet_req || '
                                                                      AND edd1.id_diet_schedule = ' ||
                                                                  edd.id_diet_schedule || ' 
                                                                      AND edd1.id_diet = d.id_diet',
                                                                  ',')
                                    FROM epis_diet_det edd
                                   WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                     AND rownum = 1),
                                 --institutionalized and more than one record grouped
                                 pk_utils.query_to_string('
                                        SELECT  meal || '': '' || food from (
                                                SELECT distinct  pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',ds.code_diet_schedule) meal, ds.rank,
                                                          pk_utils.query_to_string(''select pk_translation.get_translation(' ||
                                                          i_lang ||
                                                          ',d.code_diet)
                                          FROM epis_diet_det edd1, diet d 
                                         WHERE d.id_diet = edd1.id_diet
                                               AND edd1.id_epis_diet_req= ' ||
                                                          edr.id_epis_diet_req || '
                                               AND edd1.id_diet_schedule='' || ds.id_diet_schedule,'', '') food
                                        FROM epis_diet_det edd,diet_schedule ds, diet d
                                       WHERE edd.id_epis_diet_req = ' ||
                                                          edr.id_epis_diet_req || ' 
                                         AND edd.id_diet_schedule = ds.id_diet_schedule
                                         AND edd.id_diet = d.id_diet
                                       ORDER by ds.rank) t_int',
                                                          '; ')),
                          --not institutionalized
                          pk_utils.query_to_string('
                                        SELECT pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', dt.code_diet_type) || '': '' || desc_diet
                                          FROM epis_diet_req edr 
                                          JOIN  diet_type dt
                                                ON edr.id_diet_type = dt.id_diet_type
                                         WHERE edr.id_epis_diet_req = ' ||
                                                   edr.id_epis_diet_req,
                                                   '; ')
                          
                          ) task_description
              BULK COLLECT
              INTO l_diet_desc
              FROM epis_diet_req edr
             WHERE edr.id_episode = i_id_episode
               AND edr.flg_status = g_flg_diet_status_r
               AND current_timestamp BETWEEN edr.dt_inicial AND nvl(edr.dt_end, current_timestamp)
               AND NOT EXISTS (SELECT 1
                      FROM epis_diet_req e
                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent);
        
            l_active_diets := to_string(i_table => l_diet_desc, i_separator => chr(10));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_active_diets := NULL;
        END;
    
        RETURN l_active_diets;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_active_diet_description;

    --
    /**********************************************************************************************
    * Delete institucionalized diet task for a order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_diet_prof_instit  Id Diet 
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/01
    **********************************************************************************************/
    FUNCTION cancel_diet_orderset
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_diet_prof_inst IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diet_prof_inst_det table_number;
    BEGIN
    
        pk_alertlog.log_debug('CANCEL_DIET_ORDERSET');
    
        FOR i IN i_id_diet_prof_inst.first .. i_id_diet_prof_inst.last
        LOOP
        
            g_error := 'Get all details for Diet ' || i_id_diet_prof_inst(i);
            --delete diet drat details:
            SELECT dpid.id_diet_prof_instit_det
              BULK COLLECT
              INTO l_diet_prof_inst_det
              FROM diet_prof_instit_det dpid
             WHERE dpid.id_diet_prof_instit = i_id_diet_prof_inst(i);
        
            g_error := 'Delete all details for Diet ' || i_id_diet_prof_inst(i) || '. Number of detais: ' ||
                       l_diet_prof_inst_det.count;
            --Delete all details for this Diet!
            IF l_diet_prof_inst_det.count > 0
            THEN
                FOR j IN l_diet_prof_inst_det.first .. l_diet_prof_inst_det.last
                LOOP
                    ts_diet_prof_instit_det.del(id_diet_prof_instit_det_in => l_diet_prof_inst_det(j));
                    pk_alertlog.log_debug('DELETE DRAFT DIET DET: :' || l_diet_prof_inst_det(j),
                                          g_package_name,
                                          'DELETE DRAFT DIET');
                
                END LOOP;
                --End of Delete all details for this Diet!
            END IF;
            --Delete the Diet
            ts_diet_prof_instit.del(id_diet_prof_instit_in => i_id_diet_prof_inst(i));
            pk_alertlog.log_debug('DELETE DRAFT DIET: Deleted draft diet:' || i_id_diet_prof_inst(i),
                                  g_package_name,
                                  'DELETE DRAFT DIET');
        END LOOP;
    
        RETURN TRUE;
        --  
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_DIET_ORDERSET',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_diet_orderset;
    --

    /**********************************************************************************************
    * Duplicate diet for a new order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/01
    **********************************************************************************************/
    FUNCTION duplicate_diet_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_diet_prof_inst IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_id_diet_prof_inst OUT diet_prof_instit.id_diet_prof_instit%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows     table_varchar;
        l_rows_det table_varchar;
    
        l_diet_prof_instit_row     diet_prof_instit%ROWTYPE;
        l_diet_prof_instit_det     table_number;
        l_diet_prof_instit_det_row diet_prof_instit_det%ROWTYPE;
        l_id_diet_prof_instit_det  diet_prof_instit_det.id_diet_prof_instit_det%TYPE;
    
    BEGIN
    
        pk_alertlog.log_debug('DUPLICATE_DIET_TASK');
    
        SELECT *
          INTO l_diet_prof_instit_row
          FROM diet_prof_instit dpi
         WHERE dpi.id_diet_prof_instit = i_id_diet_prof_inst;
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'INSERT DIET_PROF_INSTIT';
        ts_diet_prof_instit.ins(id_diet_type_in         => l_diet_prof_instit_row.id_diet_type,
                                flg_help_in             => l_diet_prof_instit_row.flg_help,
                                flg_institution_in      => l_diet_prof_instit_row.flg_institution,
                                desc_diet_in            => l_diet_prof_instit_row.desc_diet,
                                flg_status_in           => g_flg_diet_status_o,
                                food_plan_in            => l_diet_prof_instit_row.food_plan,
                                flg_share_in            => nvl(l_diet_prof_instit_row.flg_share, g_no),
                                id_prof_create_in       => i_prof.id,
                                id_institution_in       => i_prof.institution,
                                notes_in                => l_diet_prof_instit_row.notes,
                                dt_creation_in          => g_sysdate_tstz,
                                id_diet_prof_instit_out => o_id_diet_prof_inst,
                                rows_out                => l_rows);
    
        pk_alertlog.log_debug('DUPLICATE_DIET_TASK: Inserted diet_prof_instit:' || o_id_diet_prof_inst,
                              g_package_name,
                              'DUPLICATE_DIET_TASK');
    
        SELECT dpid.id_diet_prof_instit_det
          BULK COLLECT
          INTO l_diet_prof_instit_det
          FROM diet_prof_instit dpi, diet_prof_instit_det dpid
         WHERE dpi.id_diet_prof_instit = i_id_diet_prof_inst
           AND dpid.id_diet_prof_instit = dpi.id_diet_prof_instit;
    
        IF l_diet_prof_instit_det.count > 0
        THEN
            FOR i IN l_diet_prof_instit_det.first .. l_diet_prof_instit_det.last
            LOOP
                g_error := 'INSERT DIET_PROF_INSTIT_DET';
                SELECT *
                  INTO l_diet_prof_instit_det_row
                  FROM diet_prof_instit_det dpid
                 WHERE dpid.id_diet_prof_instit_det = l_diet_prof_instit_det(i);
            
                g_error := 'CALL ts_diet_prof_instit.ins';
                ts_diet_prof_instit_det.ins(id_diet_prof_instit_in      => o_id_diet_prof_inst,
                                            notes_in                    => l_diet_prof_instit_det_row.notes,
                                            id_diet_schedule_in         => l_diet_prof_instit_det_row.id_diet_schedule,
                                            dt_diet_schedule_in         => l_diet_prof_instit_det_row.dt_diet_schedule,
                                            id_diet_in                  => l_diet_prof_instit_det_row.id_diet,
                                            quantity_in                 => l_diet_prof_instit_det_row.quantity,
                                            id_unit_measure_in          => l_diet_prof_instit_det_row.id_unit_measure,
                                            id_diet_prof_instit_det_out => l_id_diet_prof_instit_det,
                                            rows_out                    => l_rows_det);
            
            END LOOP;
        END IF;
        pk_alertlog.log_debug('DUPLICATE_DIET_TASK: Inserted diet_prof_instit_det:' || l_diet_prof_instit_det.count ||
                              ' records',
                              g_package_name,
                              'DUPLICATE_DIET_TASK');
    
        RETURN TRUE;
        --  
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'DUPLICATE_DIET_TASK',
                                              o_error);
            --      pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END duplicate_diet_task;

    /**********************************************************************************************
    * Order sets
    * Retrieves the diets instructions to be shown in the order set functionality 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_task_request           task id
    * @param i_separator              the separator to be added between the results
    *
    * @return                         Instructions
    *                        
    * @author                         Ant? Neto
    * @version                        2.5.1.8
    * @since                          16-Sep-2011
    **********************************************************************************************/
    FUNCTION get_task_food_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_separator        IN VARCHAR2 DEFAULT '; '
    ) RETURN VARCHAR2 IS
        --
        l_diet_all_meal sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T114');
    
        l_task_food_list VARCHAR2(4000) := NULL;
    BEGIN
        --
    
        pk_alertlog.log_debug('PARAMS[:i_diet_prof_instit:' || i_diet_prof_instit || ' ]',
                              g_package_name,
                              'GET_TASK_FOOD_INSTRUCTIONS');
    
        BEGIN
            SELECT decode(id_diet_type,
                          g_diet_type_inst,
                          
                          decode((SELECT COUNT(DISTINCT id_diet)
                                   FROM epis_diet_det
                                  WHERE id_epis_diet_req = edr.id_epis_diet_req),
                                 1,
                                 l_diet_all_meal || ' ' || (SELECT pk_translation.get_translation(i_lang, d.code_diet)
                                                              FROM epis_diet_det edd, diet d
                                                             WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                                               AND edd.id_diet = d.id_diet
                                                               AND rownum = 1),
                                 pk_utils.query_to_string('
                           SELECT  PK_TRANSLATION.get_translation(' ||
                                                          i_lang ||
                                                          ',DS.CODE_DIET_SCHEDULE) || '': '' ||  PK_TRANSLATION.get_translation(' ||
                                                          i_lang ||
                                                          ',D.CODE_DIET) || '' ('' || pk_date_utils.dt_chr_hour_tsz( ' ||
                                                          i_lang || ' , edd.dt_diet_schedule, profissional(' || i_prof.id || ',' ||
                                                          i_prof.institution || ',' || i_prof.software ||
                                                          ')) || '')'' 
                           FROM EPIS_DIET_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_EPIS_DIET_REQ = ' ||
                                                          id_epis_diet_req || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
													 AND EDD.ID_DIET_SCHEDULE != 7
                           AND EDD.ID_DIET = D.ID_DIET
                           ORDER BY DS.RANK',
                                                          i_separator)),
                          pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct PK_TRANSLATION.get_translation(' ||
                                                   i_lang ||
                                                   ',CODE_DIET_SCHEDULE) meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                   i_lang ||
                                                   ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                   i_lang ||
                                                   ', um.code_unit_measure)  || '' ('' || pk_date_utils.dt_chr_hour_tsz( ' ||
                                                   i_lang || ' , edd.dt_diet_schedule, profissional(' || i_prof.id || ',' ||
                                                   i_prof.institution || ',' || i_prof.software ||
                                                   ')) || '')'' 
                                          from epis_diet_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_epis_diet_req= ' ||
                                                   id_epis_diet_req || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from epis_diet_det edd, diet_schedule ds
                                        where edd.id_epis_diet_req = ' ||
                                                   id_epis_diet_req || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
							                           AND EDD.ID_DIET_SCHEDULE != 7
                                        order by ds.rank)',
                                                   i_separator)
                          
                          )
              INTO l_task_food_list
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_diet_prof_instit;
        EXCEPTION
            WHEN OTHERS THEN
                l_task_food_list := NULL;
        END;
    
        RETURN l_task_food_list;
    END get_task_food_instructions;

    /**********************************************************************************************
    * Order sets
    * Retrieves the diets instructions to be shown in the order set functionality (backoffice) 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids
    * @param i_task_request           task id
    * @param i_flg_process            Y - Frontofice; N - Backofice
    * @param o_task_list              Instructions
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Rita Lopes
    * @version                        1.0
    * @since                          2011/09/12
    **********************************************************************************************/
    FUNCTION get_task_instructions_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2,
        o_task_instr       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_diet_all_meal sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T114');
        l_diet_notes    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T045');
    
        l_diet_begin             sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                         i_code_mess => 'DIET_T112');
        l_diet_end               sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                         i_code_mess => 'DIET_T113');
        l_task_food_instructions CLOB := NULL;
    BEGIN
        --
    
        pk_alertlog.log_debug('PARAMS[:i_diet_prof_instit:' || i_diet_prof_instit || ' ]',
                              g_package_name,
                              'GET_TASK_INSTRUCTIONS_INTERNAL');
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_process = g_yes
        THEN
            SELECT get_task_food_instructions(i_lang, i_prof, i_diet_prof_instit)
              INTO l_task_food_instructions
              FROM dual;
        
            IF length(l_task_food_instructions) > 0
            THEN
                l_task_food_instructions := l_task_food_instructions || chr(10);
            END IF;
        
            BEGIN
                SELECT l_task_food_instructions || l_diet_begin ||
                       pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) ||
                       decode(edr.dt_end,
                              NULL,
                              NULL,
                              '; ' || l_diet_end || pk_date_utils.dt_chr_tsz(i_lang, edr.dt_end, i_prof)) ||
                       decode(notes, NULL, NULL, chr(10) || l_diet_notes || ' ' || notes)
                  INTO o_task_instr
                  FROM epis_diet_req edr
                 WHERE edr.id_epis_diet_req = i_diet_prof_instit;
            EXCEPTION
                WHEN OTHERS THEN
                    o_task_instr := NULL;
            END;
        ELSE
            -- Backofice      
            BEGIN
                SELECT decode(id_diet_type,
                              g_diet_type_inst,
                              
                              decode((SELECT COUNT(DISTINCT id_diet)
                                       FROM diet_prof_instit_det dpid
                                      WHERE dpid.id_diet_prof_instit = dpi.id_diet_prof_instit),
                                     1,
                                     l_diet_all_meal || ' ' || (SELECT pk_translation.get_translation(i_lang, d.code_diet)
                                                                  FROM diet_prof_instit_det dpid, diet d
                                                                 WHERE dpid.id_diet_prof_instit = dpi.id_diet_prof_instit
                                                                   AND dpid.id_diet = d.id_diet
                                                                   AND rownum = 1),
                                     pk_utils.query_to_string('
                           SELECT  PK_TRANSLATION.get_translation(' ||
                                                              i_lang ||
                                                              ',DS.CODE_DIET_SCHEDULE) || '': '' ||  PK_TRANSLATION.get_translation(' ||
                                                              i_lang ||
                                                              ',D.CODE_DIET)
                           FROM DIET_PROF_INSTIT_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_DIET_PROF_INSTIT = ' ||
                                                              id_diet_prof_instit || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ORDER BY DS.RANK',
                                                              '; ')),
                              pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct PK_TRANSLATION.get_translation(' ||
                                                       i_lang ||
                                                       ',CODE_DIET_SCHEDULE) meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                       i_lang ||
                                                       ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                       i_lang ||
                                                       ', um.code_unit_measure)
                                          from diet_prof_instit_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_diet_prof_instit= ' ||
                                                       id_diet_prof_instit || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from diet_prof_instit_det edd, diet_schedule ds
                                        where edd.id_diet_prof_instit = ' ||
                                                       id_diet_prof_instit || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
                                        order by ds.rank)',
                                                       '; ')
                              
                              ) || decode(notes, NULL, NULL, chr(10) || l_diet_notes || ' ' || notes)
                  INTO o_task_instr
                  FROM diet_prof_instit dpi
                 WHERE dpi.id_diet_prof_instit = i_diet_prof_instit;
            EXCEPTION
                WHEN OTHERS THEN
                    o_task_instr := NULL;
            END;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASK_INSTRUCTIONS_INTERNAL',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_task_instructions_internal;

    FUNCTION get_task_instructions_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        --
        l_diet_all_meal sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T114');
        l_diet_notes    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                i_code_mess => 'DIET_T045');
    
        l_diet_begin sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'DIET_T112');
        l_diet_end   sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                             i_code_mess => 'DIET_T113');
    
        l_task_list              CLOB := NULL;
        l_task_food_instructions CLOB := NULL;
    BEGIN
        --
    
        pk_alertlog.log_debug('PARAMS[:i_diet_prof_instit:' || i_diet_prof_instit || ' ]',
                              g_package_name,
                              'GET_TASK_INSTRUCTIONS_INTERNAL');
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_flg_process = g_yes
        THEN
            SELECT get_task_food_instructions(i_lang, i_prof, i_diet_prof_instit)
              INTO l_task_food_instructions
              FROM dual;
        
            IF length(l_task_food_instructions) > 0
            THEN
                l_task_food_instructions := l_task_food_instructions || chr(10);
            END IF;
        
            BEGIN
                SELECT l_task_food_instructions || l_diet_begin ||
                       pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) ||
                       decode(edr.dt_end,
                              NULL,
                              NULL,
                              '; ' || l_diet_end || pk_date_utils.dt_chr_tsz(i_lang, edr.dt_end, i_prof)) ||
                       decode(notes, NULL, NULL, chr(10) || l_diet_notes || ' ' || notes)
                  INTO l_task_list
                  FROM epis_diet_req edr
                 WHERE edr.id_epis_diet_req = i_diet_prof_instit;
            EXCEPTION
                WHEN OTHERS THEN
                    l_task_list := NULL;
            END;
        ELSE
            -- Backofice      
            BEGIN
                SELECT decode(id_diet_type,
                              g_diet_type_inst,
                              
                              decode((SELECT COUNT(DISTINCT id_diet)
                                       FROM diet_prof_instit_det dpid
                                      WHERE dpid.id_diet_prof_instit = dpi.id_diet_prof_instit),
                                     1,
                                     l_diet_all_meal || ' ' || (SELECT pk_translation.get_translation(i_lang, d.code_diet)
                                                                  FROM diet_prof_instit_det dpid, diet d
                                                                 WHERE dpid.id_diet_prof_instit = dpi.id_diet_prof_instit
                                                                   AND dpid.id_diet = d.id_diet
                                                                   AND rownum = 1),
                                     pk_utils.query_to_string('
                           SELECT  PK_TRANSLATION.get_translation(' ||
                                                              i_lang ||
                                                              ',DS.CODE_DIET_SCHEDULE) || '': '' ||  PK_TRANSLATION.get_translation(' ||
                                                              i_lang ||
                                                              ',D.CODE_DIET)
                           FROM DIET_PROF_INSTIT_DET EDD,DIET_SCHEDULE DS, DIET D
                           WHERE EDD.ID_DIET_PROF_INSTIT = ' ||
                                                              id_diet_prof_instit || ' 
                           AND EDD.ID_DIET_SCHEDULE = DS.ID_DIET_SCHEDULE
                           AND EDD.ID_DIET = D.ID_DIET
                           ORDER BY DS.RANK',
                                                              '; ')),
                              pk_utils.query_to_string('
                                        select meal || '': '' || food from 
                                        (select distinct PK_TRANSLATION.get_translation(' ||
                                                       i_lang ||
                                                       ',CODE_DIET_SCHEDULE) meal,ds.rank,
                                                pk_utils.query_to_string(''select PK_TRANSLATION.get_translation(' ||
                                                       i_lang ||
                                                       ',D.CODE_DIET)  
                                                || '''', '''' || edd1.quantity ||'''' '''' || pk_translation.get_translation(' ||
                                                       i_lang ||
                                                       ', um.code_unit_measure)
                                          from diet_prof_instit_det edd1, diet d , unit_measure um
                                         where d.id_diet = edd1.id_diet
                                               and edd1.id_diet_prof_instit= ' ||
                                                       id_diet_prof_instit || '
                                               and edd1.id_unit_measure = um.id_unit_measure(+)
                                               and edd1.id_diet_schedule='' || ds.id_diet_schedule,''; '') food
                                        from diet_prof_instit_det edd, diet_schedule ds
                                        where edd.id_diet_prof_instit = ' ||
                                                       id_diet_prof_instit || '
                                        and edd.id_diet_schedule = ds.id_diet_schedule
                                        order by ds.rank)',
                                                       '; ')
                              
                              ) || decode(notes, NULL, NULL, chr(10) || l_diet_notes || ' ' || notes)
                  INTO l_task_list
                  FROM diet_prof_instit dpi
                 WHERE dpi.id_diet_prof_instit = i_diet_prof_instit;
            EXCEPTION
                WHEN OTHERS THEN
                    l_task_list := NULL;
            END;
        END IF;
    
        RETURN l_task_list;
    
    END get_task_instructions_internal;

    FUNCTION get_task_instructions
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_diet_prof_instit IN diet_prof_instit.id_diet_prof_instit%TYPE,
        i_flg_process      IN VARCHAR2,
        o_task_instr       OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        IF NOT get_task_instructions_internal(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_diet_prof_instit => i_diet_prof_instit,
                                              i_flg_process      => i_flg_process,
                                              o_task_instr       => o_task_instr,
                                              o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => NULL,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_TASK_INSTRUCTIONS',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_task_instructions;

    /**********************************************************************************************
    * Set diet for a patient on order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Diet type
    * @param i_diet_name             Diet name
    * @param o_diet_descr            Diet description
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/014
    **********************************************************************************************/
    FUNCTION set_pat_diet_task
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_task    IN diet_prof_instit.id_diet_prof_instit%TYPE,
        o_id_task    OUT epis_diet_req.id_epis_diet_req%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_diet_type IS
            SELECT id_diet_type
              FROM diet_prof_instit dpi
             WHERE dpi.id_diet_prof_instit = i_id_task;
        --
        l_diet_type diet_type.id_diet_type%TYPE;
    
        l_o_diet          pk_types.cursor_type;
        l_o_diet_schedule pk_types.cursor_type;
        l_o_diet_food     pk_types.cursor_type;
    
        l_request_result BOOLEAN;
    
        l_dummy_vc       VARCHAR2(4000);
        l_dummy_array_nr table_number;
        l_dummy_array_vc table_varchar;
    
        l_diet_id_diet              diet_prof_instit.id_diet_prof_instit%TYPE;
        l_diet_desc                 diet_prof_instit.desc_diet%TYPE;
        l_diet_food_plan            diet_prof_instit.food_plan%TYPE;
        l_flg_help                  diet_prof_instit.flg_help%TYPE;
        l_diet_notes                diet_prof_instit.notes%TYPE;
        ibt_i_diet_id_diet_schedule table_number;
        ibt_i_diet_id_diet          table_number;
        ibt_i_diet_quantity         table_number;
        ibt_i_diet_id_unit          table_number;
        ibt_i_diet_notes_diet       table_varchar;
        ibt_i_diet_dt_hour          table_varchar;
        ibt_i_diet_sched_id         table_number;
        ibt_i_diet_sched_hour       table_varchar;
    
        l_msg_warning VARCHAR2(1000 CHAR);
        --
        error_unexpected EXCEPTION;
        --
    BEGIN
    
        pk_alertlog.log_debug('SET_PAT_DIET_TASK');
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_diet_type;
        FETCH c_diet_type
            INTO l_diet_type;
        CLOSE c_diet_type;
    
        pk_alertlog.log_debug('SET_PAT_DIET_TASK: diet type:' || l_diet_type, g_package_name, 'SET_PAT_DIET_TASK');
    
        -- get order set diet details to use in create_draft
        l_request_result := get_diet(i_lang          => i_lang,
                                     i_prof          => i_prof,
                                     i_type_diet     => l_diet_type,
                                     i_id_patient    => NULL,
                                     i_id_diet       => i_id_task,
                                     o_diet          => l_o_diet,
                                     o_diet_schedule => l_o_diet_schedule,
                                     o_diet_food     => l_o_diet_food,
                                     o_error         => o_error);
    
        pk_alertlog.log_debug('SET_PAT_DIET_TASK: get_diet', g_package_name, 'SET_PAT_DIET_TASK');
    
        -- exit when an error occurs
        IF (l_request_result = FALSE)
        THEN
            RAISE error_unexpected;
        END IF;
    
        -- Fetch l_o_diet;
        FETCH l_o_diet
            INTO l_diet_id_diet,
                 l_diet_desc,
                 l_flg_help,
                 l_dummy_vc,
                 l_diet_food_plan,
                 l_dummy_vc,
                 l_dummy_vc,
                 l_diet_notes,
                 l_dummy_vc,
                 l_dummy_vc,
                 l_dummy_vc,
                 l_dummy_vc;
        CLOSE l_o_diet;
    
        -- Fetch l_o_diet_schedule;
        FETCH l_o_diet_schedule BULK COLLECT
            INTO ibt_i_diet_sched_id, l_dummy_array_nr, ibt_i_diet_sched_hour;
        CLOSE l_o_diet_schedule;
    
        -- Fetch l_o_diet_food;
        FETCH l_o_diet_food BULK COLLECT
            INTO ibt_i_diet_id_diet_schedule,
                 l_dummy_array_nr,
                 ibt_i_diet_id_diet,
                 l_dummy_array_nr,
                 l_dummy_array_vc,
                 ibt_i_diet_notes_diet,
                 ibt_i_diet_quantity,
                 l_dummy_array_vc,
                 ibt_i_diet_id_unit,
                 l_dummy_array_nr,
                 l_dummy_array_nr,
                 l_dummy_array_vc,
                 l_dummy_array_nr,
                 l_dummy_array_vc,
                 l_dummy_array_nr;
        CLOSE l_o_diet_food;
    
        ibt_i_diet_dt_hour := table_varchar();
        IF ibt_i_diet_id_diet_schedule.count > 0
        THEN
            FOR i1 IN ibt_i_diet_id_diet_schedule.first .. ibt_i_diet_id_diet_schedule.last
            LOOP
                ibt_i_diet_dt_hour.extend();
                IF ibt_i_diet_sched_id.count > 0
                THEN
                    FOR i2 IN ibt_i_diet_sched_id.first .. ibt_i_diet_sched_id.last
                    LOOP
                        IF ibt_i_diet_sched_id(i2) = ibt_i_diet_id_diet_schedule(i1)
                        THEN
                            ibt_i_diet_dt_hour(i1) := ibt_i_diet_sched_hour(i2);
                        END IF;
                    END LOOP;
                END IF;
            END LOOP;
        END IF;
        --        
    
        -- associate diet to patient
        l_request_result := create_diet(i_lang               => i_lang,
                                        i_prof               => i_prof,
                                        i_patient            => i_id_patient,
                                        i_episode            => i_id_episode,
                                        i_id_epis_diet       => NULL,
                                        i_id_diet_type       => l_diet_type,
                                        i_desc_diet          => l_diet_desc,
                                        i_dt_begin_str       => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                i_prof,
                                                                                                g_sysdate_tstz,
                                                                                                NULL),
                                        i_dt_end_str         => pk_date_utils.get_timestamp_str(i_lang,
                                                                                                i_prof,
                                                                                                g_sysdate_tstz,
                                                                                                NULL),
                                        i_food_plan          => l_diet_food_plan,
                                        i_flg_help           => nvl(l_flg_help, g_no),
                                        i_notes              => l_diet_notes,
                                        i_id_diet_predefined => l_diet_id_diet,
                                        i_id_diet_schedule   => ibt_i_diet_id_diet_schedule,
                                        i_id_diet            => ibt_i_diet_id_diet,
                                        i_quantity           => ibt_i_diet_quantity,
                                        i_id_unit            => ibt_i_diet_id_unit,
                                        i_notes_diet         => ibt_i_diet_notes_diet,
                                        i_dt_hour            => ibt_i_diet_dt_hour,
                                        i_commit             => g_no,
                                        -- REVIEW                        
                                        i_flg_institution    => 'Y',
                                        i_flg_share          => NULL,
                                        i_flg_status_default => g_flg_diet_status_o,
                                        i_flg_order_set      => pk_alert_constant.g_yes,
                                        o_id_epis_diet       => o_id_task,
                                        o_msg_warning        => l_msg_warning,
                                        o_error              => o_error);
    
        pk_alertlog.log_debug('SET_PAT_DIET_TASK: id diet:' || o_id_task, g_package_name, 'SET_PAT_DIET_TASK');
        --  
        RETURN TRUE;
        --  
    
    EXCEPTION
        -- external unexpected error
        WHEN error_unexpected THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DIET_TASK',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PAT_DIET_TASK',
                                              o_error);
        
            RETURN FALSE;
    END set_pat_diet_task;

    /**********************************************************************************************
    * Set diet requested for a patient on order set
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_diet_req           Id Diet req
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/14
    **********************************************************************************************/
    FUNCTION set_req_pat_diet_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_diet_req IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_force   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        CURSOR c_diet_status IS
            SELECT flg_status, id_diet_type, id_episode, dt_inicial, dt_end
              FROM epis_diet_req
             WHERE id_epis_diet_req = i_id_diet_req;
        --
        l_flg_status   epis_diet_req.flg_status%TYPE;
        l_id_diet_type epis_diet_req.id_diet_type%TYPE;
        l_id_episode   epis_diet_req.id_episode%TYPE;
        l_dt_inicial   epis_diet_req.dt_inicial%TYPE;
        l_dt_end       epis_diet_req.dt_end%TYPE;
        l_rows         table_varchar;
        l_active_diet  VARCHAR2(1000 CHAR);
    
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_multiple_diet_cfg sys_config.value%TYPE := pk_sysconfig.get_config('DIET_MULTIPLE', i_prof);
    
        --
        error_unexpected EXCEPTION;
        --
    BEGIN
    
        pk_alertlog.log_debug('SET_REQ_PAT_DIET_TASK');
    
        OPEN c_diet_status;
        FETCH c_diet_status
            INTO l_flg_status, l_id_diet_type, l_id_episode, l_dt_inicial, l_dt_end;
        CLOSE c_diet_status;
    
        l_active_diet := get_active_diet(i_lang,
                                         i_prof,
                                         l_id_episode,
                                         l_id_diet_type,
                                         NULL,
                                         pk_date_utils.date_send_tsz(i_lang, l_dt_inicial, i_prof),
                                         pk_date_utils.date_send_tsz(i_lang, l_dt_end, i_prof),
                                         o_error);
    
        IF l_active_diet IS NOT NULL
           AND i_flg_force = pk_alert_constant.g_no
        THEN
            g_error := pk_message.get_message(i_lang, 'DIET_T141');
            RAISE error_unexpected;
        END IF;
    
        l_start_date := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                         i_prof.software,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   l_dt_inicial,
                                                                                                                   i_prof),
                                                                                       NULL));
        l_end_date   := pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                         i_prof.software,
                                                         pk_date_utils.get_string_tstz(i_lang,
                                                                                       i_prof,
                                                                                       pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   l_dt_end,
                                                                                                                   i_prof),
                                                                                       NULL));
    
        IF i_flg_force = pk_alert_constant.g_yes
           AND l_multiple_diet_cfg = pk_alert_constant.g_no
        THEN
        
            FOR reg IN (SELECT edr.id_epis_diet_req
                          FROM epis_diet_req edr
                         WHERE edr.flg_status IN (g_flg_diet_status_r)
                           AND id_episode = l_id_episode
                           AND ((l_start_date BETWEEN pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                       i_prof.software,
                                                                                       pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                                i_inst      => i_prof.institution,
                                                                                                                                i_timestamp => edr.dt_inicial),
                                                                                       NULL) AND
                               pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                           i_inst      => i_prof.institution,
                                                                                                           i_timestamp => edr.dt_end),
                                                                  NULL)) OR
                               (l_end_date BETWEEN pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                     i_prof.software,
                                                                                     pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                              i_inst      => i_prof.institution,
                                                                                                                              i_timestamp => edr.dt_inicial),
                                                                                     NULL) AND
                               pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                  i_prof.software,
                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                           i_inst      => i_prof.institution,
                                                                                                           i_timestamp => edr.dt_end),
                                                                  NULL)) OR
                               (l_start_date <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND
                               l_end_date >= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                i_prof.software,
                                                                                pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                         i_inst      => i_prof.institution,
                                                                                                                         i_timestamp => edr.dt_end),
                                                                                NULL)) OR
                               (l_start_date <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND l_dt_end IS NULL) OR
                               (l_start_date >= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND edr.dt_end IS NULL) OR
                               (l_start_date <= pk_date_utils.trunc_insttimezone(i_prof.institution,
                                                                                  i_prof.software,
                                                                                  pk_date_utils.get_timestamp_insttimezone(i_lang      => i_lang,
                                                                                                                           i_inst      => i_prof.institution,
                                                                                                                           i_timestamp => edr.dt_inicial),
                                                                                  NULL) AND edr.dt_end IS NULL))
                        
                        )
            LOOP
                IF NOT cancel_diet(i_lang    => i_lang,
                                   i_prof    => i_prof,
                                   i_id_diet => reg.id_epis_diet_req,
                                   i_notes   => NULL,
                                   i_reason  => NULL,
                                   o_error   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END LOOP;
        END IF;
    
        pk_alertlog.log_debug('SET_REQ_PAT_DIET_TASK: Find diet status: ' || l_flg_status,
                              g_package_name,
                              'SET_REQ_PAT_DIET_TASK');
        -- exit when an error occurs
        IF (l_flg_status != g_flg_diet_status_o)
        THEN
            RAISE error_unexpected;
        END IF;
        pk_alertlog.log_debug('SET_REQ_PAT_DIET_TASK: Turn diet status R', g_package_name, 'SET_REQ_PAT_DIET_TASK');
        ts_epis_diet_req.upd(id_epis_diet_req_in => i_id_diet_req,
                             flg_status_in       => g_flg_diet_status_r,
                             rows_out            => l_rows);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_DIET_REQ',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        IF NOT sync_task(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_episode      => l_id_episode,
                         i_task_type    => l_id_diet_type,
                         i_task_request => i_id_diet_req,
                         i_dt_task      => l_dt_inicial,
                         o_error        => o_error)
        THEN
            RAISE error_unexpected;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        -- external unexpected error
        WHEN error_unexpected THEN
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              'DIET_ERR001',
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REQ_PAT_DIET_TASK',
                                              o_error);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_REQ_PAT_DIET_TASK',
                                              o_error);
        
            RETURN FALSE;
    END set_req_pat_diet_task;

    FUNCTION check_cancel_diet
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_id_sys_button   sys_button_prop.id_sys_button%TYPE := 6686;
        l_summ_flg_cancel NUMBER := 0;
    
        CURSOR c_diet_cancel IS
            SELECT decode(edr.flg_status,
                          g_flg_diet_status_c,
                          g_no,
                          g_flg_diet_status_f,
                          g_no,
                          g_flg_diet_status_s,
                          g_no,
                          decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                 g_flg_date_l,
                                 g_no,
                                 g_yes)) flg_cancel
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_id_epis_diet_req;
    
        l_diet_cancel VARCHAR2(1);
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_diet_cancel;
        FETCH c_diet_cancel
            INTO l_diet_cancel;
        CLOSE c_diet_cancel; --  fetch   
    
        IF l_diet_cancel = g_no
        THEN
            RETURN pk_alert_constant.g_no;
        ELSE
            SELECT SUM(decode(flg_cancel, pk_alert_constant.g_active, 1, 0))
              INTO l_summ_flg_cancel
              FROM (SELECT pta.flg_cancel
                      FROM sys_button sb, sys_button_prop sbp, profile_templ_access pta, profile_template pt
                     WHERE sb.id_sys_button = sbp.id_sys_button
                       AND sbp.id_sys_button_prop = pta.id_sys_button_prop
                       AND sbp.flg_visible = pk_access.g_sbs_visible
                       AND sb.id_sys_button = l_id_sys_button
                       AND pt.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof)
                          -- adds
                       AND pta.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                       AND pta.flg_add_remove = pk_access.g_flg_type_add -- add
                          -- removes (including exceptions)
                       AND NOT EXISTS (SELECT 1
                              FROM profile_templ_access_exception ptae
                             WHERE ptae.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                               AND ptae.id_sys_button_prop = pta.id_sys_button_prop
                               AND ptae.flg_type = pk_access.g_flg_type_remove
                               AND ptae.id_software IN (i_prof.software, 0)
                               AND ptae.id_institution IN (i_prof.institution, 0))
                       AND NOT EXISTS
                     (SELECT 1
                              FROM profile_templ_access pt_access
                             WHERE pt_access.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                               AND pt_access.id_sys_button_prop = pta.id_sys_button_prop
                               AND pt_access.flg_add_remove = pk_access.g_flg_type_remove)
                    -- Add exceptions
                    UNION ALL
                    SELECT ptae.flg_cancel
                      FROM sys_button sb, sys_button_prop sbp, profile_templ_access_exception ptae, profile_template pt
                     WHERE sb.id_sys_button = sbp.id_sys_button
                       AND sbp.id_sys_button_prop = ptae.id_sys_button_prop
                       AND sbp.flg_visible = pk_access.g_sbs_visible
                       AND sb.id_sys_button = l_id_sys_button
                       AND pt.id_profile_template = pk_prof_utils.get_prof_profile_template(i_prof)
                       AND ptae.id_profile_template IN (pt.id_parent, pt.id_profile_template)
                       AND ptae.flg_type = pk_access.g_flg_type_add
                       AND ptae.id_software IN (i_prof.software, 0)
                       AND ptae.id_institution IN (i_prof.institution, 0));
        
            IF (l_summ_flg_cancel > 0)
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        END IF;
    
    END check_cancel_diet;

    /**********************************************************************************************
    * Returns incial and end date
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_diet_type             Id Diet type
    * @param i_req                   Array de requisicoes
    * @param o_date_limits           Cursor de saida
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        Rita Lopes
    * @version                       2.5
    * @since                         2011/09/21
    **********************************************************************************************/
    FUNCTION get_date_limits
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_diet_type   IN epis_diet_req.id_diet_type%TYPE,
        i_id_req      IN table_number,
        o_date_limits OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        --
    BEGIN
    
        pk_alertlog.log_debug('GET_DATE_LIMITS');
        OPEN o_date_limits FOR
            SELECT edr.id_epis_diet_req, edr.dt_inicial start_date, edr.dt_end end_date
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                             d.column_value
                                              FROM TABLE(i_id_req) d);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATE_LIMITS',
                                              o_error);
            pk_types.open_my_cursor(o_date_limits);
            RETURN FALSE;
    END get_date_limits;

    /**
    * Get diet task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_edr          diet request identifier
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_task_description
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_edr                   IN epis_diet_req.id_epis_diet_req%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE
    ) RETURN CLOB IS
        l_ret        CLOB;
        l_diet_desc  CLOB;
        l_start_date VARCHAR2(50 CHAR);
        l_status     sys_message.desc_message%TYPE;
        l_token_list table_varchar;
    
        CURSOR c_desc IS
            SELECT decode(edr.id_diet_type,
                          g_diet_type_inst,
                          get_diet_description_internal2(i_lang,
                                                         i_prof,
                                                         i_edr,
                                                         g_diet_descr_format_sp,
                                                         pk_alert_constant.g_yes,
                                                         pk_alert_constant.g_no),
                          edr.desc_diet) diet_desc,
                   pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) start_date,
                   get_processed_diet_status(i_lang, i_prof, edr.id_epis_diet_req) diet_status
              FROM epis_diet_req edr
             WHERE edr.id_epis_diet_req = i_edr;
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_diet_desc, l_start_date, l_status;
        CLOSE c_desc;
    
        IF (i_flg_description = pk_prog_notes_constants.g_flg_description_c)
        THEN
            l_token_list := pk_string_utils.str_split(i_list => i_description_condition, i_delim => '|');
            FOR i IN 1 .. l_token_list.last
            LOOP
                IF l_token_list(i) = 'START-DATE'
                   AND l_start_date IS NOT NULL
                THEN
                    IF l_ret IS NULL
                    THEN
                        l_ret := l_start_date;
                    ELSE
                        l_ret := l_ret || pk_prog_notes_constants.g_comma || l_start_date;
                    END IF;
                    IF i = 1
                    THEN
                        l_ret := l_ret || pk_prog_notes_constants.g_space;
                    END IF;
                ELSIF l_token_list(i) = 'DESCRIPTION'
                      AND l_diet_desc IS NOT NULL
                THEN
                    l_ret := l_ret || l_diet_desc;
                END IF;
            END LOOP;
        ELSE
            l_ret := l_diet_desc || pk_prog_notes_constants.g_open_parenthesis || l_start_date ||
                     pk_prog_notes_constants.g_flg_sep || l_status || pk_prog_notes_constants.g_close_parenthesis;
        END IF;
    
        RETURN l_ret;
    END get_task_description;

    /**********************************************************************************************
    * Get active diets (this logic has been copy exactly the same present in inpatient's main grid)
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_episode           episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Elisabete Bugalho
    * @version                            2.6.3.8.2
    * @since                              2013/10/02     
    ********************************************************************************************/
    FUNCTION get_active_diet_tooltip
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
    
        l_diet_desc pk_translation.t_desc_translation;
        l_diet      table_varchar;
        l_dt_inicio sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'DIET_T050');
        l_dt_end    sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'DIET_T051');
        l_plan      sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                            i_code_mess => 'DIET_T068');
    
    BEGIN
    
        BEGIN
            SELECT decode(edr.id_diet_type,
                           g_diet_type_inst,
                           decode(((SELECT COUNT(DISTINCT pk_utils.query_to_string('SELECT edda.id_diet 
                                                                                     FROM epis_diet_det edda 
                                                                                    WHERE edda.id_diet_schedule = ' ||
                                                                          edd.id_diet_schedule || ' 
                                                                                      AND edda.id_epis_diet_req = ' ||
                                                                          edd.id_epis_diet_req,
                                                                          ', '))
                                      FROM epis_diet_det edd
                                     WHERE id_epis_diet_req = edr.id_epis_diet_req)),
                                  1,
                                  --institutionalized and only with one record
                                  (SELECT '<B>' || pk_translation.get_translation(i_lang, dt.code_diet_type) || '</B>' ||
                                          chr(10) ||
                                          pk_utils.query_to_string('SELECT pk_translation.get_translation(' || i_lang ||
                                                                   ', d.code_diet)
                                                                     FROM epis_diet_det edd1, diet d
                                                                    WHERE edd1.id_epis_diet_req = ' ||
                                                                   edd.id_epis_diet_req || '
                                                                      AND edd1.id_diet_schedule = ' ||
                                                                   edd.id_diet_schedule || ' 
                                                                      AND edd1.id_diet = d.id_diet',
                                                                   ',')
                                     FROM epis_diet_det edd
                                    WHERE edd.id_epis_diet_req = edr.id_epis_diet_req
                                      AND rownum = 1),
                                  
                                  --institutionalized and more than one record grouped
                                  '<B>' || pk_translation.get_translation(i_lang, dt.code_diet_type) || '</B>' || chr(10) ||
                                  pk_utils.query_to_string('
                                        SELECT  ''<B>'' || meal || ''</B> : '' || food from (
                                                SELECT distinct  pk_translation.get_translation(' ||
                                                           i_lang ||
                                                           ',ds.code_diet_schedule) meal, ds.rank,
                                                          pk_utils.query_to_string(''select pk_translation.get_translation(' ||
                                                           i_lang ||
                                                           ',d.code_diet)
                                          FROM epis_diet_det edd1, diet d 
                                         WHERE d.id_diet = edd1.id_diet
                                               AND edd1.id_epis_diet_req= ' ||
                                                           edr.id_epis_diet_req || '
                                               AND edd1.id_diet_schedule='' || ds.id_diet_schedule,'', '') food
                                        FROM epis_diet_det edd,diet_schedule ds, diet d
                                       WHERE edd.id_epis_diet_req = ' ||
                                                           edr.id_epis_diet_req || ' 
                                         AND edd.id_diet_schedule = ds.id_diet_schedule
                                         AND edd.id_diet = d.id_diet
                                       ORDER by ds.rank) t_int',
                                                           '; ')),
                           --not institutionalized
                           pk_utils.query_to_string('
                                        SELECT ''<B>'' || pk_translation.get_translation(' ||
                                                    i_lang ||
                                                    ', dt.code_diet_type) || ''</B>: '' || desc_diet
                                          FROM epis_diet_req edr 
                                          JOIN  diet_type dt
                                                ON edr.id_diet_type = dt.id_diet_type
                                         WHERE edr.id_epis_diet_req = ' ||
                                                    edr.id_epis_diet_req,
                                                    '; ')
                           
                           ) || chr(10) || '<B>' || l_dt_inicio || '</B> ' ||
                    pk_date_utils.date_char_tsz(i_lang, edr.dt_inicial, i_prof.institution, i_prof.software) ||
                    decode(edr.dt_end,
                           NULL,
                           NULL,
                           chr(10) || '<B>' || l_dt_end || '</B> ' ||
                           pk_date_utils.dt_chr_tsz(i_lang, edr.dt_end, i_prof)) || CASE
                        WHEN edr.id_diet_type IN (g_diet_type_pers, g_diet_type_defi) THEN
                         chr(10) || '<B>' || l_plan || '</B> ' || edr.food_plan ||
                         (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                            FROM unit_measure um
                           WHERE id_unit_measure = g_id_unit_kcal)
                        ELSE
                         NULL
                    END task_description
              BULK COLLECT
              INTO l_diet
              FROM epis_diet_req edr
              JOIN diet_type dt
                ON edr.id_diet_type = dt.id_diet_type
             WHERE edr.id_episode = i_id_episode
               AND edr.flg_status = g_flg_diet_status_r
               AND current_timestamp BETWEEN edr.dt_inicial AND nvl(edr.dt_end, current_timestamp)
               AND NOT EXISTS (SELECT 1
                      FROM epis_diet_req e
                     WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent);
        
            l_diet_desc := to_string(i_table => l_diet, i_separator => chr(10) || chr(10));
        
        EXCEPTION
            WHEN no_data_found THEN
                l_diet_desc := NULL;
        END;
    
        RETURN l_diet_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        
    END get_active_diet_tooltip;

    /**********************************************************************************************
    * Get diet title of institution diet
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_id_epis_diet_req  req det episode id
    * @param          o_error             error message
    *
    * @return        varchar2
    *
    * @author                             Jorge Silva
    * @version                            2.6.3.10
    * @since                              2014/01/27     
    ********************************************************************************************/
    FUNCTION get_diet_title
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_diet_req IN epis_diet_req.id_epis_diet_req%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_label                  table_varchar := table_varchar();
        l_t_coll_text_delimiter_tuple t_coll_text_delimiter_tuple;
    BEGIN
    
        SELECT pk_string_utils.concat_if_exists(pk_translation.get_translation(i_lang, d1.code_diet),
                                                pk_translation.get_translation(i_lang, d.code_diet),
                                                ' - ')
          BULK COLLECT
          INTO l_desc_label
          FROM epis_diet_det edd
          JOIN diet d
            ON d.id_diet = edd.id_diet
          LEFT JOIN diet d1
            ON d1.id_diet = d.id_diet_parent
         WHERE edd.id_diet_schedule = g_diet_title
           AND edd.id_epis_diet_req = i_id_epis_diet_req;
    
        RETURN pk_utils.concat_table(l_desc_label, ', ');
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diet_title;

    /**********************************************************************************************
    * Get diet title and parent diet title 
    *
    * @param          i_lang              language id    
    * @param          i_prof              professional type
    * @param          i_id_diet           diet id
    *
    * @return        varchar2
    *
    * @author                             Jorge Silva
    * @version                            2.6.3.10
    * @since                              2014/01/27     
    ********************************************************************************************/
    FUNCTION get_diet_description_title
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_diet IN diet.id_diet%TYPE
    ) RETURN VARCHAR2 IS
    
        l_desc_label VARCHAR2(4000 CHAR);
    
    BEGIN
    
        SELECT pk_string_utils.concat_if_exists(pk_translation.get_translation(i_lang, d1.code_diet),
                                                pk_translation.get_translation(i_lang, d.code_diet),
                                                ' - ')
          INTO l_desc_label
          FROM diet d
          LEFT JOIN diet d1
            ON d1.id_diet = d.id_diet_parent
         WHERE d.id_diet = i_id_diet;
    
        RETURN l_desc_label;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_diet_description_title;

    /* *******************************************************************************************
    *  Get current state of diet diagnos for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_diag_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number;
        tbl_status table_varchar := table_varchar(pk_diagnosis.g_ed_flg_status_co,
                                                  pk_diagnosis.g_ed_flg_status_d,
                                                  pk_diagnosis.g_ed_flg_status_p);
    BEGIN
    
        l_status := pk_diagnosis.get_vwr_diag_type_epis(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_scope_type => i_scope_type,
                                                        i_id_episode => i_id_episode,
                                                        i_id_patient => i_id_patient,
                                                        i_epis_type  => pk_alert_constant.g_epis_type_dietitian,
                                                        i_tbl_status => tbl_status);
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_vwr_diag_diet;

    /* *******************************************************************************************
    *  Get current state of diets for viewer checklist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_diet
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_status   VARCHAR2(1 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes table_number;
        l_count    NUMBER;
    BEGIN
    
        SELECT /*+ OPT_ESTIMATE(TABLE tblx ROWS=1) */
         id_episode
          BULK COLLECT
          INTO l_episodes
          FROM (SELECT column_value id_episode
                  FROM TABLE(pk_episode.get_scope(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_patient    => i_id_patient,
                                                  i_episode    => i_id_episode,
                                                  i_flg_filter => i_scope_type))) tblx;
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_diet_req edr
         WHERE edr.flg_status = pk_diet.g_flg_diet_status_r
           AND edr.id_episode IN (SELECT column_value
                                    FROM TABLE(l_episodes));
    
        IF l_count > 0
        THEN
            l_status := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN l_status;
    END get_vwr_diet;

    /* *******************************************************************************************
    *  Get current state of Nutrition  discharge for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author    Elisabete Bugalho                 
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_vwr_nutri_discharge
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_flg_checklist VARCHAR2(0001 CHAR) := pk_viewer_checklist.g_checklist_not_started;
        l_episodes      table_number;
        l_count         NUMBER;
        k_vwr_flg_active CONSTANT VARCHAR2(0001 CHAR) := pk_alert_constant.g_active;
    BEGIN
    
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM discharge d
          JOIN episode e
            ON e.id_episode = d.id_episode
         WHERE d.id_episode IN (SELECT column_value id_episode
                                  FROM TABLE(l_episodes))
           AND e.id_epis_type = pk_alert_constant.g_epis_type_dietitian
           AND d.flg_status = pk_discharge.g_disch_flg_status_active;
    
        IF l_count > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        END IF;
    
        RETURN l_flg_checklist;
    
    END get_vwr_nutri_discharge;

    /**********************************************************************************************
    * Gets the active diets list of a episode
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional's details
    * @param i_id_episode            ID episode
    *
    * @return                        Table with records t_tbl_diet
    *                        
    * @author                        Anna Kurowska
    * @version                       2.7.1
    * @since                         2017/04/03
    **********************************************************************************************/
    FUNCTION get_active_diets
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_tbl_diet IS
        l_tbl_diet t_tbl_diet;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT t_rec_diet(id_epis_diet_req => t.id_diet,
                          id_diet_type     => t.id_diet_type,
                          diet_type        => t.diet_type,
                          dt_initial_str   => t.dt_initial,
                          dt_end_str       => t.dt_end,
                          diet_name        => t.diet_name,
                          flg_status       => t.flg_status)
          BULK COLLECT
          INTO l_tbl_diet
          FROM (SELECT id_diet,
                       id_diet_type,
                       pk_translation.get_translation(i_lang, code_diet_type) diet_type,
                       pk_date_utils.dt_chr_tsz(i_lang, dt_inicial, i_prof) dt_initial,
                       pk_date_utils.dt_chr_tsz(i_lang, dt_end, i_prof) dt_end,
                       diet_name,
                       flg_status
                  FROM (SELECT edr.id_epis_diet_req id_diet,
                               edr.id_diet_type,
                               code_diet_type,
                               edr.dt_inicial,
                               edr.dt_end,
                               decode(edr.id_diet_type,
                                      g_diet_type_inst,
                                      pk_diet.get_diet_title(i_lang, i_prof, edr.id_epis_diet_req),
                                      htf.escape_sc(edr.desc_diet)) diet_name,
                               edr.flg_status
                          FROM epis_diet_req edr, diet_type dt
                         WHERE edr.id_patient = i_patient
                           AND edr.flg_status IN (g_flg_diet_status_r)
                           AND NOT EXISTS
                         (SELECT 1
                                  FROM epis_diet_req e
                                 WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                           AND edr.id_diet_type = dt.id_diet_type
                           AND decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_inicial, g_sysdate_tstz),
                                      'G',
                                      g_flg_diet_status_h,
                                      decode(pk_date_utils.compare_dates_tsz(i_prof, edr.dt_end, g_sysdate_tstz),
                                             'L',
                                             g_flg_diet_status_f,
                                             g_flg_diet_status_a)) = g_flg_diet_status_a
                         ORDER BY edr.dt_creation DESC)) t;
        RETURN l_tbl_diet;
    END get_active_diets;

    FUNCTION inactivate_diet_tasks
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
    
        l_descontinued_cfg sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf => 'INACTIVATE_DISCONTINUED_REASON',
                                                                            i_prof    => i_prof);
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang => NULL,
                                                                                    i_prof => profissional(0, i_inst, 0),
                                                                                    i_area => 'DIET_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_diet_req_det table_number;
        l_final_status table_varchar;
    
        l_msg_error VARCHAR2(200 CHAR);
        l_error     t_error_out;
        g_other_exception EXCEPTION;
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_epis_diet_req) sent in i_ids_exclude
        CURSOR c_diet_req_dets(ids_exclude IN table_number) IS
            SELECT DISTINCT t.id_epis_diet_req, t.field_04 flg_final_status
              FROM (SELECT edr.id_epis_diet_req, cfg.field_04
                      FROM epis_diet_req edr
                     INNER JOIN episode e
                        ON e.id_episode = edr.id_episode
                      LEFT JOIN episode prev_e
                        ON prev_e.id_prev_episode = e.id_episode
                       AND e.id_visit = prev_e.id_visit
                     INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = edr.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = edr.id_epis_diet_req
                     WHERE e.id_institution = i_inst
                       AND e.dt_end_tstz IS NOT NULL
                       AND NOT EXISTS
                     (SELECT 1
                              FROM epis_diet_req e
                             WHERE edr.id_epis_diet_req = e.id_epis_diet_req_parent)
                       AND (prev_e.id_episode IS NULL OR prev_e.flg_status = pk_alert_constant.g_inactive)
                       AND pk_date_utils.trunc_insttimezone(i_prof,
                                                            pk_date_utils.add_to_ltstz(e.dt_end_tstz,
                                                                                       cfg.field_02,
                                                                                       cfg.field_03)) <=
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)
                       AND rownum > 0
                       AND t_ids.column_value IS NULL) t
             WHERE (SELECT pk_diet.get_processed_diet_status(i_lang, i_prof, t.id_epis_diet_req, g_status_type_f)
                      FROM dual) != g_status_type_f
               AND rownum <= l_max_rows;
    
    BEGIN
    
        OPEN c_diet_req_dets(i_ids_exclude);
        FETCH c_diet_req_dets BULK COLLECT
            INTO l_diet_req_det, l_final_status;
        CLOSE c_diet_req_dets;
    
        o_has_error := FALSE;
    
        IF l_diet_req_det.count > 0
        THEN
            FOR i IN 1 .. l_diet_req_det.count
            LOOP
            
                IF l_final_status(i) = pk_diet.g_flg_diet_status_c
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_diet.cancel_diet(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_id_diet     => l_diet_req_det(i),
                                               i_notes       => NULL,
                                               i_reason      => l_cancel_id,
                                               i_auto_cancel => pk_alert_constant.g_yes,
                                               o_error       => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_epis_diet_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_epis_diet_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING  PK_DIET.CANCEL_DIET FOR RECORD ' || l_diet_req_det(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_DIET_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_epis_diet_req) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_diet_req_det(i);
                    
                        CONTINUE;
                    END IF;
                ELSIF l_final_status(i) = pk_diet.g_flg_diet_status_i
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_diet.suspend_task_diet(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_task       => l_diet_req_det(i),
                                                     i_flg_reason    => NULL,
                                                     i_cancel_reason => l_descontinued_id,
                                                     i_force_cancel  => pk_alert_constant.g_yes,
                                                     o_msg_error     => l_msg_error,
                                                     o_error         => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_epis_diet_req, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_epis_diet_req that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_DIET.SUSPEND_TASK_DIET FOR RECORD ' || l_diet_req_det(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_DIET_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_epis_diet_req) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_diet_req_det(i);
                    
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_epis_diet_req has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_epis_diet_req) that could not
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
                IF NOT pk_diet.inactivate_diet_tasks(i_lang        => i_lang,
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
            RETURN FALSE;
    END inactivate_diet_tasks;

    FUNCTION get_order_plan_report
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_request  IN table_number,
        i_cpoe_dt_begin IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_cpoe_dt_end   IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_plan_rep      OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cp_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_cp_end   TIMESTAMP WITH LOCAL TIME ZONE;
        l_tbl_diet table_number;
    
        l_tbl_rec_exec_static t_tbl_cpoe_execution;
        l_last_date           monitorization_vs_plan.dt_plan_tstz%TYPE;
        l_interval            monitorization.interval%TYPE;
        l_calc_last_date      monitorization_vs_plan.dt_plan_tstz%TYPE;
    
        l_error t_error_out;
    BEGIN
    
        IF i_cpoe_dt_begin IS NULL
        THEN
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_episode,
                                                     o_dt_begin_tstz => l_cp_begin,
                                                     o_error         => o_error)
            THEN
                l_cp_begin := current_timestamp;
            END IF;
        ELSE
            l_cp_begin := i_cpoe_dt_begin;
        END IF;
    
        IF i_cpoe_dt_end IS NULL
        THEN
            l_cp_end := nvl(pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_begin, i_days => 1),
                            current_timestamp);
        ELSE
            --l_cp_end :=  pk_date_utils.add_days_to_tstz(i_timestamp => i_cpoe_dt_end, i_days => 1);
            l_cp_end := i_cpoe_dt_end;
        END IF;
    
        OPEN o_plan_rep FOR
            SELECT t.id_epis_diet_req id_prescription,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_inicial, i_prof => i_prof) planned_date,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_inicial, i_prof => i_prof) exec_date,
                   t.notes exec_notes,
                   'N' out_of_period
              FROM epis_diet_req t
             WHERE t.id_episode = i_episode
               AND t.dt_inicial BETWEEN l_cp_begin AND l_cp_end
               AND t.flg_status NOT IN ('D', 'C')
            /*UNION ALL
            SELECT t.id_epis_diet_req id_prescription,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_inicial, i_prof => i_prof) planned_date,
                   pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => t.dt_inicial, i_prof => i_prof) exec_date,
                   t.notes exec_notes,
                   'Y' out_of_period
              FROM epis_diet_req t
             WHERE t.id_episode = i_episode
               AND t.dt_inicial < l_cp_begin
               AND t.flg_status NOT IN ('D', 'C')*/
             ORDER BY planned_date;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error.err_desc,
                                              g_package_owner,
                                              g_package_name,
                                              'INACTIVATE_MONITORZTN_TASKS',
                                              l_error);
            pk_types.open_my_cursor(o_plan_rep);
            RETURN FALSE;
        
    END get_order_plan_report;

    PROCEDURE get_init_parameters
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
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof    CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                        i_context_ids(g_prof_institution),
                                                        i_context_ids(g_prof_software));
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_error t_error_out;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('i_prof_software', l_prof.software);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_id := l_lang;
            ELSE
                NULL;
        END CASE;
    
    END get_init_parameters;

BEGIN
    -- Log initialization.
    -- Initialization
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_diet;
/
