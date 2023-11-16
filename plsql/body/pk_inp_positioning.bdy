/*-- Last Change Revision: $Rev: 2050159 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-11-14 15:54:50 +0000 (seg, 14 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_positioning AS

    internal_error_exception EXCEPTION;

    FUNCTION update_epis_posit_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        i_update_plan         IN BOOLEAN DEFAULT TRUE,
        l_rows                OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * cancel_assoc_icnp_interv        De-associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPIS_POSITIONING    ID of Positioning episode
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          28-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION cancel_assoc_icnp_interv
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_icnp_interv EXCEPTION;
    BEGIN
        pk_icnp_fo_api_db.set_sugg_status_cancel(i_lang         => i_lang,
                                                 i_prof         => i_prof,
                                                 i_request_id   => i_id_epis_positioning,
                                                 i_task_type_id => pk_alert_constant.g_task_inp_positioning,
                                                 i_sysdate_tstz => current_timestamp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'ERROR ON PK_ICNP_FO_API_DB.SET_SUGG_STATUS_CANCEL: ' ||
                                              i_id_epis_positioning || ' ' || SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_ASSOC_ICNP_INTERV',
                                              o_error);
            RETURN FALSE;
    END cancel_assoc_icnp_interv;

    /*******************************************************************************************************************************************
    * create_assoc_icnp_interv        Associate Integration of Therapeutic Attitudes
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPIS_POSITIONING    ID of Positioning episode
    * @param I_ID_EPISODE                ID of episode
    * @param I_POSITIONING_TYPES      List of positioning types
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         António Neto
    * @version                        2.6.0.5
    * @since                          28-Feb-2011
    *******************************************************************************************************************************************/
    FUNCTION create_assoc_icnp_interv
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_positioning_types   IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_icnp_sug_interv  table_number;
        l_id_epis_positioning table_number := table_number();
        l_icnp_interv EXCEPTION;
        l_count PLS_INTEGER;
    BEGIN
        l_count := i_positioning_types.count;
        FOR aux IN 1 .. l_count
        LOOP
            l_id_epis_positioning.extend;
            l_id_epis_positioning(aux) := i_id_epis_positioning;
        END LOOP;
    
        pk_icnp_fo_api_db.create_suggs(i_lang               => i_lang,
                                       i_prof               => i_prof,
                                       i_id_episode         => i_id_episode,
                                       i_request_ids        => l_id_epis_positioning,
                                       i_task_ids           => i_positioning_types,
                                       i_task_type_id       => pk_alert_constant.g_task_inp_positioning,
                                       i_sysdate_tstz       => g_sysdate_tstz,
                                       o_id_icnp_sug_interv => l_id_icnp_sug_interv);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              'ERROR ON PK_ICNP_FO_API_DB.CREATE_SUGG: ' || i_id_epis_positioning || ' ' ||
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_SUGG',
                                              o_error);
            RETURN FALSE;
    END create_assoc_icnp_interv;

    /*******************************************************************************************************************************************
    * Name :                          GET_ROT_INTERV_FORMAT
    * Description:                    Function that returns an duration string in an incorrect format (ex: "01:2" or "2:23") in 
    *                                 the correct format (ex: "01:02" or "02:23")
    * 
    * @param I_ROT_INTERV             Duration of rotation interval in positioning functionality
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2009/07/09
    *******************************************************************************************************************************************/
    FUNCTION get_rot_interv_format(i_rot_interv IN epis_positioning.rot_interval%TYPE) RETURN VARCHAR2 IS
        l_rot_interv VARCHAR2(8);
        l_hours      VARCHAR2(8);
        l_minutes    VARCHAR2(8);
    BEGIN
        -- [ALERT-35391] LMAIA
        -- Because rotation interval is recorded in epis_positioning in varchar2 format,
        -- it is necessary guarantee that duration is recorded in propoer format (ex: "01:09")
        l_rot_interv := i_rot_interv;
    
        -- Catch hours and minutes string
        l_hours   := substr(l_rot_interv, 0, instr(l_rot_interv, ':') - 1);
        l_minutes := substr(l_rot_interv, instr(l_rot_interv, ':') + 1);
        -- Correct hours string
        IF length(l_hours) = 1
        THEN
            l_hours := lpad(l_hours, 2, '0');
        END IF;
        -- Correct minutes string
        IF length(l_minutes) = 1
        THEN
            l_minutes := lpad(l_minutes, 2, '0');
        END IF;
        -- Concat hours and minutes strings
        l_rot_interv := l_hours || ':' || l_minutes;
        --
        -- Return original duration in the correct format
        RETURN l_rot_interv;
    END get_rot_interv_format;

    /*******************************************************************************************************************************************
    * Name :                          GET_ROT_INTERV_FORMAT
    * Description:                    Function that returns an duration string in an incorrect format (ex: "01:2" or "2:23") in 
    *                                 the correct format (ex: "01:02" or "02:23")
    * 
    * @param I_ROT_INTERV             Duration of rotation interval in positioning functionality
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1.1
    * @since                          22-Jun-2011
    *******************************************************************************************************************************************/
    FUNCTION get_fomatted_rot_interv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_rot_interv IN epis_positioning.rot_interval%TYPE
    ) RETURN VARCHAR2 IS
        l_rot_interv VARCHAR2(30);
    BEGIN
        g_error := 'CALL rotation interval desc';
        pk_alertlog.log_debug(g_error);
        l_rot_interv := pk_date_utils.dt_chr_hour(i_lang,
                                                  to_date('20000102 ' || get_rot_interv_format(i_rot_interv),
                                                          'YYYYMMDD HH24:MI'),
                                                  i_prof);
    
        RETURN l_rot_interv;
    END get_fomatted_rot_interv;

    FUNCTION get_posit_type_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_post_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar os vários tipos de posicionamento
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 
                          SAIDA: O_POST_LIST - Lista dos tipos de posicionamento
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/15
          NOTAS: 
        *********************************************************************************/
        --                              
    BEGIN
        g_error := 'GET CURSOR O_POST_LIST';
        OPEN o_post_list FOR
            SELECT id_positioning_type, pk_translation.get_translation(i_lang, code_positioning_type) desc_post
              FROM positioning_type
             ORDER BY desc_post ASC;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_POSIT_TYPE_LIST',
                                              o_error);
            --
            pk_types.open_my_cursor(o_post_list);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * returns the status to change the active positioning
    *
    * @param I_ID_EPIS_POSIT          Positioning ID
    *
    * @return                flag Interrupted if with plans executed or Cancelled without
    *
    * @author                António Neto
    * @version               v1.0 
    * @since                 24-Sep-2010
    *********************************************************************************************/
    FUNCTION get_new_status(i_id_epis_posit IN epis_positioning.id_epis_positioning%TYPE)
        RETURN epis_positioning.flg_status%TYPE IS
    
        l_num_plans NUMBER;
    
    BEGIN
        g_error := 'Init GET_NEW_STATUS';
    
        --counts the number of plans of the current positioning
        SELECT COUNT(epp.id_epis_positioning_plan)
          INTO l_num_plans
          FROM epis_positioning_det epd
         INNER JOIN epis_positioning_plan epp
            ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
         WHERE epd.id_epis_positioning = i_id_epis_posit
           AND epp.flg_status NOT IN (g_epis_posit_l, g_epis_posit_d);
    
        --If doesn't have or only one so it's to cancel
        IF l_num_plans IS NULL
           OR l_num_plans <= 1
        THEN
            RETURN g_epis_posit_c;
        ELSE
            --more than one it's to interrupt
            RETURN g_epis_posit_i;
        END IF;
    END get_new_status;

    /********************************************************************************************
    * Register all the requests for positionings
    *
    * @param I_LANG          language id
    * @param I_PROF          professional, software and institution ids
    * @param I_EPISODE       episode id
    * @param I_POSIT         Array with the several positionings
    * @param I_ROT_INTERV    rotation interval duration
    * @param I_ID_ROT_INTERV rotation interval id
    * @param I_FLG_MASSAGE   massage included or not
    * @param I_NOTES         notes
    * @param I_POS_TYPE      type of positioning
    * @param I_FLG_TYPE      flag of positioning
    * @param O_ROWS          list of positionings for the current episode
    * @param O_ERROR         warning/error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Emílio Taborda
    * @version               v1.0 
    * @since                 15-Nov-2006
    *********************************************************************************************/
    FUNCTION create_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_posit                IN table_number,
        i_rot_interv           IN rotation_interval.interval%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage          IN epis_positioning.flg_massage%TYPE,
        i_notes                IN epis_positioning.notes%TYPE,
        i_pos_type             IN positioning_type.id_positioning_type%TYPE DEFAULT NULL,
        i_flg_type             IN epis_positioning.flg_status%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_task_end_timestamp   IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_epis_positioning  IN epis_positioning.id_epis_positioning%TYPE DEFAULT NULL,
        i_flg_origin           IN VARCHAR DEFAULT 'N',
        i_id_episode_sr        IN episode.id_episode%TYPE DEFAULT NULL,
        o_rows                 OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char                VARCHAR2(1);
        l_next_ep             epis_positioning.id_epis_positioning%TYPE;
        l_next_epd            epis_positioning_det.id_epis_positioning_det%TYPE;
        l_next_epp            epis_positioning_plan.id_epis_positioning_plan%TYPE;
        l_cont                NUMBER := 2;
        l_num_lines           PLS_INTEGER;
        l_posit_next          epis_positioning_plan.id_epis_positioning_next%TYPE;
        l_dt_creation_tstz    epis_positioning.dt_creation_tstz%TYPE;
        l_dt_epis_positioning epis_positioning.dt_epis_positioning%TYPE;
        l_pos_type            positioning_type.id_positioning_type%TYPE;
        --
        l_id_epis_posit epis_positioning.id_epis_positioning%TYPE;
        --
        l_rot_interv VARCHAR2(8);
    
        --
        l_rowids                   table_varchar;
        l_rows_epis_posit_det      table_varchar;
        l_rows_epis_posit_plan     table_varchar;
        l_id_epis_positioning_plan table_number := table_number();
    
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_episode
               AND flg_status = g_epis_active;
    
        CURSOR c_epp(l_id_epis_posit epis_positioning.id_epis_positioning%TYPE) IS
            SELECT *
              FROM epis_positioning_plan epp
             WHERE epp.id_epis_positioning_det =
                   (SELECT epd.id_epis_positioning_det
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning = l_id_epis_posit
                       AND epd.id_epis_positioning_det = epp.id_epis_positioning_det)
               AND epp.flg_status = g_epis_posit_e;
    
        l_flg_profile     profile_template.flg_profile%TYPE;
        l_sys_alert_event sys_alert_event%ROWTYPE;
        --
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        l_flg_profile := nvl(pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL), '#');
        --
        -- check if the episode is active
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%NOTFOUND;
        CLOSE c_episode;
    
        IF i_pos_type IS NULL
        THEN
            IF i_posit.count = 1
            THEN
                l_pos_type := 2;
            ELSE
                l_pos_type := 1;
            END IF;
        ELSE
            l_pos_type := i_pos_type;
        END IF;
        --
        IF g_found
        THEN
            --           
            -- [ALERT-35391] LMAIA
            -- Because rotation interval is recorded in epis_positioning in varchar2 format,
            -- it is necessary guarantee that duration is recorded in propoer format (ex: "01:09")
        
            IF i_rot_interv IS NOT NULL
            THEN
                l_rot_interv := get_rot_interv_format(i_rot_interv);
            ELSE
                l_rot_interv := NULL;
            END IF;
        
            --
            IF i_id_epis_positioning IS NULL
            THEN
                g_error   := 'GET SEQ_EPIS_POSITIONING.NEXTVAL';
                l_next_ep := ts_epis_positioning.next_key();
            END IF;
        
            o_rows := table_number(1);
            o_rows(o_rows.count) := nvl(i_id_epis_positioning, l_next_ep);
            --
        
            IF i_task_start_timestamp IS NOT NULL
            THEN
                l_dt_creation_tstz := i_task_start_timestamp;
            ELSE
                l_dt_creation_tstz := g_sysdate_tstz;
            
            END IF;
        
            l_dt_epis_positioning := g_sysdate_tstz;
        
            --
            g_error  := 'INSERT EPIS_POSITIONING';
            l_rowids := table_varchar();
            ts_epis_positioning.ins(id_epis_positioning_in  => l_next_ep,
                                    id_episode_in           => i_episode,
                                    id_professional_in      => i_prof.id,
                                    flg_status_in           => CASE
                                                                   WHEN i_flg_type = g_epis_posit_d THEN
                                                                    i_flg_type
                                                                   ELSE
                                                                    g_epis_posit_r
                                                               END,
                                    flg_massage_in          => nvl(i_flg_massage, g_flg_massage_n),
                                    notes_in                => i_notes,
                                    dt_creation_tstz_in     => g_sysdate_tstz,
                                    rot_interval_in         => l_rot_interv,
                                    id_rotation_interval_in => i_id_rot_interv,
                                    dt_epis_positioning_in  => g_sysdate_tstz,
                                    flg_origin_in           => i_flg_origin,
                                    id_episode_context_in   => i_id_episode_sr,
                                    rows_out                => l_rowids);
        
            IF i_flg_type != g_epis_posit_d
               OR i_flg_type IS NULL
            THEN
                g_error := 'Call create_assoc_icnp_interv';
                IF NOT create_assoc_icnp_interv(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_epis_positioning => l_next_ep,
                                                i_id_episode          => i_episode,
                                                i_positioning_types   => i_posit,
                                                o_error               => o_error)
                THEN
                    RAISE internal_error_exception;
                ELSE
                    IF l_pos_type = g_pos_type_s
                    THEN
                        IF NOT cancel_assoc_icnp_interv(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_epis_positioning => l_next_ep,
                                                        o_error               => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_POSITIONING',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            l_rows_epis_posit_det  := table_varchar();
            l_rows_epis_posit_plan := table_varchar();
        
            -- Array with positionings
            l_num_lines := i_posit.count;
            FOR i IN 1 .. l_num_lines
            LOOP
            
                g_error    := 'GET SEQ_EPIS_POSITIONING_DET.NEXTVAL';
                l_next_epd := ts_epis_positioning_det.next_key();
                --
                l_rowids := table_varchar();
                g_error  := 'INSERT EPIS_POSITIONING_DET';
                ts_epis_positioning_det.ins(id_epis_positioning_det_in => l_next_epd,
                                            id_epis_positioning_in     => l_next_ep,
                                            id_positioning_in          => i_posit(i),
                                            rank_in                    => i,
                                            adw_last_update_in         => g_sysdate_tstz,
                                            id_prof_last_upd_in        => i_prof.id,
                                            dt_epis_positioning_det_in => g_sysdate_tstz,
                                            rows_out                   => l_rowids);
            
                l_rows_epis_posit_det := l_rows_epis_posit_det MULTISET UNION DISTINCT l_rowids;
            
                --
                pk_alertlog.log_debug(text            => 'L_POS_TYPE: ' || l_pos_type,
                                      object_name     => g_package_name,
                                      sub_object_name => 'CREATE_EPIS_POSITIONING');
                --            
                IF l_num_lines > 1
                THEN
                    IF i = l_cont
                    THEN
                    
                        g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL(M)';
                        l_next_epp := ts_epis_positioning_plan.next_key();
                        --
                        g_error  := 'INSERT EPIS_POSITIONING_PLAN(M)';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                                     id_epis_positioning_det_in  => l_posit_next,
                                                     id_epis_positioning_next_in => l_next_epd,
                                                     id_prof_exec_in             => i_prof.id,
                                                     dt_prev_plan_tstz_in        => l_dt_creation_tstz,
                                                     flg_status_in               => CASE
                                                                                        WHEN i_flg_type = g_epis_posit_d THEN
                                                                                         i_flg_type
                                                                                        ELSE
                                                                                         g_epis_posit_e
                                                                                    END,
                                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                                     rows_out                    => l_rowids);
                        l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION DISTINCT l_rowids;
                    ELSE
                        l_posit_next := l_next_epd;
                    END IF;
                ELSE
                    IF i = i_posit.count
                    THEN
                        g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL(S)';
                        l_next_epp := ts_epis_positioning_plan.next_key();
                        --
                        g_error  := 'INSERT EPIS_POSITIONING_PLAN(S)';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                                     id_epis_positioning_det_in  => nvl(l_posit_next, l_next_epd),
                                                     id_epis_positioning_next_in => l_next_epd,
                                                     id_prof_exec_in             => i_prof.id,
                                                     dt_prev_plan_tstz_in        => l_dt_creation_tstz,
                                                     flg_status_in               => g_epis_posit_e,
                                                     notes_in                    => i_notes,
                                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                                     rows_out                    => l_rowids);
                        l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION DISTINCT l_rowids;
                    
                    ELSE
                        l_posit_next := l_next_epd;
                    END IF;
                
                END IF;
            END LOOP;
        
            IF (l_rows_epis_posit_det.count > 0)
            THEN
                g_error := 't_data_gov_mnt call to EPIS_POSITIONING_DET';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_DET',
                                              i_rowids     => l_rows_epis_posit_det,
                                              o_error      => o_error);
            END IF;
        
            IF (l_rows_epis_posit_plan.count > 0)
            THEN
                g_error := 't_data_gov_mnt call to EPIS_POSITIONING_PLAN';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_PLAN',
                                              i_rowids     => l_rows_epis_posit_plan,
                                              o_error      => o_error);
            END IF;
        
            IF nvl(i_flg_type, 'X') != g_epis_posit_d
            THEN
                g_error := 'CALL TO PK_CPOE.SYNC_TASK';
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_episode,
                                         i_task_type            => pk_alert_constant.g_task_type_positioning,
                                         i_task_request         => l_next_ep,
                                         i_task_start_timestamp => l_dt_creation_tstz,
                                         o_error                => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
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
                    RAISE g_other_exception;
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CREATE_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION create_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_id_epis_positioning  IN epis_positioning.id_epis_positioning%TYPE DEFAULT NULL,
        i_tbl_ds_internal_name IN table_varchar DEFAULT NULL,
        i_tbl_val              IN table_table_varchar DEFAULT NULL,
        i_tbl_real_val         IN table_table_varchar DEFAULT NULL,
        i_origin               IN VARCHAR2,
        i_id_episode_sr        IN episode.id_episode%TYPE DEFAULT NULL,
        i_filter_tab           IN VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_posit                table_number := table_number();
        l_limb                 table_number := table_number();
        l_protection           table_number := table_number();
        l_rot_interv           rotation_interval.interval%TYPE;
        l_flg_massage          epis_positioning.flg_massage%TYPE;
        l_notes                epis_positioning.notes%TYPE;
        l_start_time           VARCHAR2(200);
        l_task_start_timestamp TIMESTAMP WITH LOCAL TIME ZONE;
        l_epis_pos             table_number;
    
        l_origin VARCHAR2(2);
    
    BEGIN
    
        FOR i IN i_tbl_ds_internal_name.first .. i_tbl_ds_internal_name.last
        LOOP
            IF i_tbl_ds_internal_name(i) = g_ds_positioning_list
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    IF i_tbl_real_val(i) (j) IS NOT NULL
                    THEN
                        l_posit.extend();
                        l_posit(l_posit.count) := to_number(i_tbl_real_val(i) (j));
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_start_date
            THEN
                l_task_start_timestamp := pk_date_utils.get_string_tstz(i_lang, i_prof, i_tbl_real_val(i) (1), NULL);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_rotation
            THEN
                l_rot_interv := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_massage
            THEN
                l_flg_massage := i_tbl_real_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_notes
            THEN
                l_notes := i_tbl_val(i) (1);
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_limb_list
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    IF i_tbl_real_val(i) (j) IS NOT NULL
                    THEN
                        l_limb.extend();
                        l_limb(l_limb.count) := to_number(i_tbl_real_val(i) (j));
                    END IF;
                END LOOP;
            ELSIF i_tbl_ds_internal_name(i) = g_ds_positioning_protection
            THEN
                FOR j IN i_tbl_real_val(i).first .. i_tbl_real_val(i).last
                LOOP
                    IF i_tbl_real_val(i) (j) IS NOT NULL
                    THEN
                        l_protection.extend();
                        l_protection(l_protection.count) := to_number(i_tbl_real_val(i) (j));
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        IF i_origin = g_ds_sr_root
        THEN
            l_origin := 'SR';
        ELSE
            l_origin := 'N';
        END IF;
    
        IF i_id_epis_positioning IS NULL
        THEN
            IF l_posit.exists(1)
            THEN
                IF l_posit(1) IS NOT NULL
                THEN
                    g_error := 'CALL pk_inp_positioning.create_epis_positioning';
                    IF NOT create_epis_positioning(i_lang                 => i_lang,
                                                   i_prof                 => i_prof,
                                                   i_episode              => i_episode,
                                                   i_posit                => l_posit,
                                                   i_rot_interv           => l_rot_interv,
                                                   i_id_rot_interv        => i_id_rot_interv,
                                                   i_flg_massage          => l_flg_massage,
                                                   i_notes                => l_notes,
                                                   i_flg_type             => i_filter_tab,
                                                   i_task_start_timestamp => l_task_start_timestamp,
                                                   i_id_epis_positioning  => i_id_epis_positioning,
                                                   i_flg_origin           => l_origin,
                                                   i_id_episode_sr        => i_id_episode_sr,
                                                   o_rows                 => l_epis_pos,
                                                   o_error                => o_error)
                    THEN
                        RAISE internal_error_exception;
                    END IF;
                END IF;
            END IF;
        
            IF l_limb.exists(1)
            THEN
                IF l_limb(1) IS NOT NULL
                THEN
                    g_error := 'CALL pk_inp_positioning.create_epis_positioning for limb position';
                    FOR i IN l_limb.first .. l_limb.last
                    LOOP
                        IF NOT create_epis_positioning(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_episode              => i_episode,
                                                       i_posit                => table_number(l_limb(i)),
                                                       i_rot_interv           => NULL, --l_rot_interv,
                                                       i_id_rot_interv        => i_id_rot_interv,
                                                       i_flg_massage          => l_flg_massage,
                                                       i_notes                => l_notes,
                                                       i_flg_type             => i_filter_tab,
                                                       i_task_start_timestamp => l_task_start_timestamp,
                                                       i_id_epis_positioning  => i_id_epis_positioning,
                                                       i_flg_origin           => l_origin,
                                                       i_id_episode_sr        => i_id_episode_sr,
                                                       o_rows                 => l_epis_pos,
                                                       o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
            IF l_protection.exists(1)
            THEN
                IF l_protection(1) IS NOT NULL
                THEN
                    FOR i IN l_protection.first .. l_protection.last
                    LOOP
                        g_error := 'CALL pk_inp_positioning.create_epis_positioning for protection';
                        IF NOT create_epis_positioning(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_episode              => i_episode,
                                                       i_posit                => table_number(l_protection(i)),
                                                       i_rot_interv           => NULL, --l_rot_interv,
                                                       i_id_rot_interv        => i_id_rot_interv,
                                                       i_flg_massage          => l_flg_massage,
                                                       i_notes                => l_notes,
                                                       i_flg_type             => i_filter_tab,
                                                       i_task_start_timestamp => l_task_start_timestamp,
                                                       i_id_epis_positioning  => i_id_epis_positioning,
                                                       i_flg_origin           => l_origin,
                                                       i_id_episode_sr        => i_id_episode_sr,
                                                       o_rows                 => l_epis_pos,
                                                       o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    END LOOP;
                END IF;
            END IF;
        
        ELSE
            IF l_posit.exists(1)
            THEN
                g_error := 'CALL pk_inp_positioning.edit_epis_positioning';
                IF NOT edit_epis_positioning(i_lang                 => i_lang,
                                             i_prof                 => i_prof,
                                             i_episode              => i_episode,
                                             i_epis_positioning     => i_id_epis_positioning,
                                             i_posit                => l_posit,
                                             i_rot_interv           => l_rot_interv,
                                             i_id_rot_interv        => i_id_rot_interv,
                                             i_flg_massage          => l_flg_massage,
                                             i_notes                => l_notes,
                                             i_pos_type             => NULL,
                                             i_flg_type             => i_filter_tab,
                                             i_task_start_timestamp => l_task_start_timestamp,
                                             o_error                => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            END IF;
        
            IF l_limb.exists(1)
            THEN
                FOR i IN l_limb.first .. l_limb.last
                LOOP
                    IF i = 1
                    THEN
                        g_error := 'CALL pk_inp_positioning.edit_epis_positioning for limb position';
                        IF NOT edit_epis_positioning(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_episode              => i_episode,
                                                     i_epis_positioning     => i_id_epis_positioning,
                                                     i_posit                => table_number(l_limb(i)),
                                                     i_rot_interv           => NULL,
                                                     i_id_rot_interv        => i_id_rot_interv,
                                                     i_flg_massage          => l_flg_massage,
                                                     i_notes                => l_notes,
                                                     i_pos_type             => NULL,
                                                     i_flg_type             => i_filter_tab,
                                                     i_task_start_timestamp => l_task_start_timestamp,
                                                     o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    ELSE
                        IF NOT create_epis_positioning(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_episode              => i_episode,
                                                       i_posit                => table_number(l_limb(i)),
                                                       i_rot_interv           => NULL,
                                                       i_id_rot_interv        => i_id_rot_interv,
                                                       i_flg_massage          => l_flg_massage,
                                                       i_notes                => l_notes,
                                                       i_flg_type             => i_filter_tab,
                                                       i_task_start_timestamp => l_task_start_timestamp,
                                                       i_id_epis_positioning  => NULL,
                                                       i_flg_origin           => l_origin,
                                                       i_id_episode_sr        => i_id_episode_sr,
                                                       o_rows                 => l_epis_pos,
                                                       o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    END IF;
                END LOOP;
            END IF;
        
            IF l_protection.exists(1)
            THEN
                FOR i IN l_protection.first .. l_protection.last
                LOOP
                    IF i = 1
                    THEN
                        g_error := 'CALL pk_inp_positioning.edit_epis_positioning for limb position';
                        IF NOT edit_epis_positioning(i_lang                 => i_lang,
                                                     i_prof                 => i_prof,
                                                     i_episode              => i_episode,
                                                     i_epis_positioning     => i_id_epis_positioning,
                                                     i_posit                => table_number(l_protection(i)),
                                                     i_rot_interv           => NULL, --l_rot_interv,
                                                     i_id_rot_interv        => i_id_rot_interv,
                                                     i_flg_massage          => l_flg_massage,
                                                     i_notes                => l_notes,
                                                     i_pos_type             => NULL,
                                                     i_flg_type             => i_filter_tab,
                                                     i_task_start_timestamp => l_task_start_timestamp,
                                                     o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    ELSE
                        IF NOT create_epis_positioning(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_episode              => i_episode,
                                                       i_posit                => table_number(l_protection(i)),
                                                       i_rot_interv           => NULL,
                                                       i_id_rot_interv        => i_id_rot_interv,
                                                       i_flg_massage          => l_flg_massage,
                                                       i_notes                => l_notes,
                                                       i_flg_type             => i_filter_tab,
                                                       i_task_start_timestamp => l_task_start_timestamp,
                                                       i_id_epis_positioning  => NULL,
                                                       i_flg_origin           => l_origin,
                                                       o_rows                 => l_epis_pos,
                                                       o_error                => o_error)
                        THEN
                            RAISE internal_error_exception;
                        END IF;
                    END IF;
                END LOOP;
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
                                              'CREATE_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
    END create_epis_positioning;

    /***************************************************************************************************************
    * Function that executes a positioning movement
    *  
    * 
    * @param      i_lang              language ID
    * @param      i_prof              ALERT profissional 
    * @param      i_epis_pos          ID_EPISODE to check
    * @param      i_dt_exec_str       date os positioning execution
    * @param      i_notes             execution notes
    * @param      i_rot_interv        rotation interval
    * @param      o_error             If an error accurs, this parameter will have information about the error
    *
    *
    * @RETURN                         TRUE or FALSE
    * @author                         Emília Taborda
    * @version                        2.3.6
    * @since                          2006-Nov-15
    * 
    ****************************************************************************************************/
    FUNCTION set_epis_positioning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_pos     IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_exec_str  IN VARCHAR2,
        i_notes        IN epis_positioning.notes%TYPE,
        i_rot_interv   IN epis_positioning.rot_interval%TYPE DEFAULT NULL,
        i_dt_next_exec IN VARCHAR2 DEFAULT NULL,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_rank_max      NUMBER;
        l_rank_min      NUMBER;
        l_rank_det      NUMBER;
        l_epis_pdet     epis_positioning_det.id_epis_positioning_det%TYPE;
        l_epis_pos_det  epis_positioning_det.id_epis_positioning_det%TYPE;
        l_epis_pos_plan epis_positioning_plan.id_epis_positioning_plan%TYPE;
        l_next_epp      epis_positioning_plan.id_epis_positioning_plan%TYPE;
        l_flg_status    epis_positioning.flg_status%TYPE;
        --
        l_interval NUMBER;
        --        l_dt_plan  DATE;
        l_episode episode.id_episode%TYPE;
        --  
        l_dt_exec           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_plan           TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_next_exec_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_rowids              table_varchar;
        l_rows_epis_posit     table_varchar;
        l_epis_positioning_tc ts_epis_positioning.epis_positioning_tc;
        l_id_epis_positioning table_number := table_number();
    
        l_rot_interv epis_positioning.rot_interval%TYPE;
    
        CURSOR c_rank_max_min IS
            SELECT MAX(rank), MIN(rank)
              FROM epis_positioning_det
             WHERE id_epis_positioning = i_epis_pos
               AND flg_outdated = pk_alert_constant.g_no;
        --
        CURSOR c_epis_pos_det(l_rank IN NUMBER) IS
            SELECT id_epis_positioning_det
              FROM epis_positioning_det
             WHERE rank = l_rank
               AND id_epis_positioning = i_epis_pos
               AND flg_outdated = pk_alert_constant.g_no;
        --
        CURSOR c_epis_pos_plan IS
            SELECT epd.rank, epp.id_epis_positioning_plan
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_next
               AND (epp.flg_status = g_epis_posit_e OR
                   (ep.flg_status = g_epis_posit_o AND
                   check_extra_take(i_lang, i_prof, ep.id_episode, ep.id_epis_positioning) = pk_alert_constant.g_yes))
             WHERE ep.id_epis_positioning = i_epis_pos
               AND epd.flg_outdated = pk_alert_constant.g_no;
        --
        CURSOR c_episode IS
            SELECT ep.id_episode, ep.flg_status
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = i_epis_pos
               AND (ep.flg_status IN (g_epis_posit_r, g_epis_posit_e) OR
                   (ep.flg_status = g_epis_posit_o AND
                   check_extra_take(i_lang, i_prof, ep.id_episode, ep.id_epis_positioning) = pk_alert_constant.g_yes));
        --
        CURSOR c_ep IS
            SELECT *
              FROM epis_positioning
             WHERE id_epis_positioning = i_epis_pos
               AND flg_status = g_epis_posit_r;
        --        
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        l_dt_exec := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_exec_str, NULL);
    
        IF i_dt_next_exec IS NOT NULL
        THEN
            l_dt_next_exec_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_next_exec, NULL);
        END IF;
    
        --
        --Tratar o intervalo de tempo
        g_error := 'TREATMENT INTERVAL';
    
        IF i_rot_interv IS NULL
        THEN
            SELECT ep.rot_interval
              INTO l_rot_interv
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = i_epis_pos;
        ELSE
            l_rot_interv := i_rot_interv;
        END IF;
    
        IF l_rot_interv IS NOT NULL
        THEN
            IF instr(l_rot_interv, ':') != 0
            THEN
                l_interval := to_number(to_char(to_date(l_rot_interv, 'HH24:MI'), 'SSSSS'));
            ELSIF l_rot_interv IS NULL
            THEN
                l_interval := l_rot_interv;
            END IF;
        ELSE
            l_interval := NULL;
        END IF;
        --
        IF i_dt_exec_str IS NOT NULL
        THEN
            l_dt_plan := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_exec_str, NULL) +
                         numtodsinterval(l_interval, 'SECOND');
        ELSE
            l_dt_plan := g_sysdate_tstz + numtodsinterval(l_interval, 'SECOND');
        END IF;
        --
        g_error := 'OPEN C_RANK_MAX_MIN';
        OPEN c_rank_max_min;
        FETCH c_rank_max_min
            INTO l_rank_max, l_rank_min; --,L_EPIS_PDET_MAX;
        CLOSE c_rank_max_min;
        --
        g_error := 'OPEN C_EPIS_POS_PLAN';
        OPEN c_epis_pos_plan;
        FETCH c_epis_pos_plan
            INTO l_rank_det, l_epis_pos_plan;
        CLOSE c_epis_pos_plan;
        --
        OPEN c_episode;
        FETCH c_episode
            INTO l_episode, l_flg_status;
        CLOSE c_episode;
        --
        g_error := 'call set_epis_posit_plan_hist function';
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                        i_prof                     => i_prof,
                                        i_id_epis_positioning_plan => table_number(l_epis_pos_plan),
                                        o_error                    => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
        l_rowids := table_varchar();
        ts_epis_positioning_plan.upd(id_epis_positioning_plan_in => l_epis_pos_plan,
                                     flg_status_in               => g_epis_posit_f,
                                     dt_execution_tstz_in        => l_dt_exec,
                                     id_prof_exec_in             => i_prof.id,
                                     notes_in                    => i_notes,
                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                     rows_out                    => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_POSITIONING_PLAN',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS',
                                                                      'DT_EXECUTION_TSTZ',
                                                                      'ID_PROF_EXEC',
                                                                      'NOTES'));
    
        --if active positioning is expired (O) don't update nothing
        IF l_flg_status <> g_epis_posit_o
        THEN
            --
            g_error           := 'UPDATE EPIS_POSITIONING';
            l_rows_epis_posit := table_varchar();
            OPEN c_ep;
            LOOP
                FETCH c_ep BULK COLLECT
                    INTO l_epis_positioning_tc LIMIT 1000;
            
                EXIT WHEN l_epis_positioning_tc.count = 0;
            
                FOR j IN 1 .. l_epis_positioning_tc.count
                LOOP
                    l_epis_positioning_tc(j).flg_status := CASE
                                                               WHEN l_flg_status = g_epis_posit_o THEN
                                                                g_epis_posit_o
                                                               WHEN l_interval IS NULL THEN
                                                                g_epis_posit_f
                                                               ELSE
                                                                g_epis_posit_e
                                                           END;
                    l_epis_positioning_tc(j).dt_epis_positioning := g_sysdate_tstz;
                    l_id_epis_positioning.extend;
                    l_id_epis_positioning(j) := l_epis_positioning_tc(j).id_epis_positioning;
                END LOOP;
            
                IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_epis_positioning => l_id_epis_positioning,
                                                 o_error               => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            
                g_error  := 'UPDATE EPIS_POSITIONING';
                l_rowids := table_varchar();
                ts_epis_positioning.upd(col_in            => l_epis_positioning_tc,
                                        ignore_if_null_in => FALSE,
                                        rows_out          => l_rowids);
            
                l_rows_epis_posit := l_rows_epis_posit MULTISET UNION l_rowids;
            
                --UPDATE EPIS_POSITIONING_DET        
                IF NOT update_epis_posit_det(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => l_id_epis_positioning,
                                             l_rows                => l_rowids,
                                             o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
            END LOOP;
            CLOSE c_ep;
        
            g_error := 'synchronize epis_positioning to epis_positioning_det';
            pk_alertlog.log_debug(g_error);
            IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => l_id_epis_positioning,
                                             i_sysdate_tstz        => g_sysdate_tstz,
                                             o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF l_rows_epis_posit.count > 0
            THEN
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING',
                                              i_rowids       => l_rows_epis_posit,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        END IF;
    
        --if active positioning is expired (O) don't create the next step
        --IF l_interval is null, the positioning is of single executiion. Don't create the next step
        IF l_flg_status <> g_epis_posit_o
           AND l_interval IS NOT NULL
        THEN
            --  
            OPEN c_epis_pos_det(l_rank_det);
            FETCH c_epis_pos_det
                INTO l_epis_pos_det;
            CLOSE c_epis_pos_det;
        
            IF l_rank_max <> l_rank_det
            THEN
                g_error := 'OPEN C_EPIS_POS_DET(MAX)';
                OPEN c_epis_pos_det(l_rank_det + 1);
                FETCH c_epis_pos_det
                    INTO l_epis_pdet;
                CLOSE c_epis_pos_det;
                --
                g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL';
                l_next_epp := ts_epis_positioning_plan.next_key();
                --
                g_error  := 'INSERT EPIS_POSITIONING_PLAN(1)';
                l_rowids := table_varchar();
                ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                             id_epis_positioning_det_in  => l_epis_pos_det,
                                             id_epis_positioning_next_in => l_epis_pdet,
                                             id_prof_exec_in             => i_prof.id,
                                             dt_prev_plan_tstz_in        => l_dt_next_exec_tstz,
                                             flg_status_in               => CASE
                                                                                WHEN l_flg_status = g_epis_posit_o THEN
                                                                                 g_epis_posit_o
                                                                                ELSE
                                                                                 g_epis_posit_e
                                                                            END,
                                             dt_epis_positioning_plan_in => g_sysdate_tstz,
                                             rows_out                    => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_PLAN',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            ELSE
                pk_alertlog.log_error('l_rank_max = l_rank_det');
                g_error := 'OPEN C_EPIS_POS_DET(MIN)';
                OPEN c_epis_pos_det(l_rank_min);
                FETCH c_epis_pos_det
                    INTO l_epis_pdet;
                CLOSE c_epis_pos_det;
                --  
                g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL';
                l_next_epp := ts_epis_positioning_plan.next_key();
            
                --
                g_error  := 'INSERT EPIS_POSITIONING_PLAN(2)';
                l_rowids := table_varchar();
                ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                             id_epis_positioning_det_in  => l_epis_pos_det,
                                             id_epis_positioning_next_in => l_epis_pdet,
                                             id_prof_exec_in             => i_prof.id,
                                             dt_prev_plan_tstz_in        => l_dt_next_exec_tstz,
                                             flg_status_in               => CASE
                                                                                WHEN l_flg_status = g_epis_posit_o THEN
                                                                                 g_epis_posit_o
                                                                                ELSE
                                                                                 g_epis_posit_e
                                                                            END,
                                             dt_epis_positioning_plan_in => g_sysdate_tstz,
                                             rows_out                    => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_PLAN',
                                              i_rowids     => l_rowids,
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
                                              'SET_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION cancel_epis_positioning
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Cancelar um episódio de posicionamento. 
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPIS_POS - ID do episódio de posicionamento
                                 
                          SAIDA: O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/16
          NOTAS: 
        *********************************************************************************/
        --
        l_char    VARCHAR2(1);
        l_episode episode.id_episode%TYPE;
    
        l_rowids                   table_varchar;
        l_rows_epis_posit_plan     table_varchar;
        l_epis_positioning_plan_tc ts_epis_positioning_plan.epis_positioning_plan_tc;
        l_id_epis_positioning_plan table_number := table_number();
        --
        CURSOR c_epis_pos_plan IS
            SELECT 'X'
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
               AND epp.flg_status = g_epis_posit_f
             WHERE ep.id_epis_positioning = i_epis_pos
               AND ep.flg_status = g_epis_posit_e;
        --
        CURSOR c_epis_positioning IS
            SELECT id_episode
              FROM epis_positioning
             WHERE id_epis_positioning = i_epis_pos;
        --
        CURSOR c_epp IS
            SELECT *
              FROM epis_positioning_plan epp
             WHERE epp.id_epis_positioning_det =
                   (SELECT epd.id_epis_positioning_det
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning = i_epis_pos
                       AND epd.id_epis_positioning_det = epp.id_epis_positioning_det);
    
        CURSOR c_epp_e IS
            SELECT *
              FROM epis_positioning_plan epp
             WHERE epp.id_epis_positioning_det =
                   (SELECT epd.id_epis_positioning_det
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning = i_epis_pos
                       AND epd.id_epis_positioning_det = epp.id_epis_positioning_det)
               AND epp.flg_status = g_epis_posit_e;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'OPEN C_EPIS_POS_PLAN';
        OPEN c_epis_pos_plan;
        FETCH c_epis_pos_plan
            INTO l_char;
        g_found := c_epis_pos_plan%FOUND;
        CLOSE c_epis_pos_plan;
        --
        IF NOT g_found
        THEN
            -- Este posicionamento não tem execuções - CANCELAR
            g_error                := 'FETCH ROWTYPE EPIS_POSITIONING_PLAN(1)';
            l_rows_epis_posit_plan := table_varchar();
        
            OPEN c_epp;
            LOOP
                FETCH c_epp BULK COLLECT
                    INTO l_epis_positioning_plan_tc LIMIT 1000;
            
                EXIT WHEN l_epis_positioning_plan_tc.count = 0;
            
                FOR j IN 1 .. l_epis_positioning_plan_tc.count
                LOOP
                    l_epis_positioning_plan_tc(j).flg_status := g_epis_posit_c;
                    l_epis_positioning_plan_tc(j).id_prof_exec := i_prof.id;
                    l_epis_positioning_plan_tc(j).dt_epis_positioning_plan := g_sysdate_tstz;
                    l_id_epis_positioning_plan.extend;
                    l_id_epis_positioning_plan(j) := l_epis_positioning_plan_tc(j).id_epis_positioning_plan;
                END LOOP;
            
                g_error := 'call set_epis_posit_plan_hist function';
                pk_alertlog.log_debug(g_error);
                IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                                i_prof                     => i_prof,
                                                i_id_epis_positioning_plan => l_id_epis_positioning_plan,
                                                o_error                    => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            
                g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
                l_rowids := table_varchar();
                ts_epis_positioning_plan.upd(col_in            => l_epis_positioning_plan_tc,
                                             ignore_if_null_in => FALSE,
                                             rows_out          => l_rowids);
            
                l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION l_rowids;
            END LOOP;
        
            CLOSE c_epp;
        
            IF l_rows_epis_posit_plan.count > 0
            THEN
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING_PLAN',
                                              i_rowids       => l_rows_epis_posit_plan,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
            --
            g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_epis_pos;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => table_number(i_epis_pos),
                                             o_error               => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            g_error  := 'UPDATE EPIS_POSITIONING(1)';
            l_rowids := table_varchar();
            ts_epis_positioning.upd(id_epis_positioning_in => i_epis_pos,
                                    flg_status_in          => g_epis_posit_c,
                                    id_prof_cancel_in      => i_prof.id,
                                    id_cancel_reason_in    => i_id_cancel_reason,
                                    notes_cancel_in        => i_notes,
                                    dt_cancel_tstz_in      => g_sysdate_tstz,
                                    dt_epis_positioning_in => g_sysdate_tstz,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_POSITIONING',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_CANCEL',
                                                                          'NOTES_CANCEL',
                                                                          'DT_CANCEL_TSTZ'));
        
            g_error := 'synchronize epis_positioning to epis_positioning_det';
            pk_alertlog.log_debug(g_error);
            IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => table_number(i_epis_pos),
                                             i_sysdate_tstz        => g_sysdate_tstz,
                                             o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        ELSE
            -- Este posicionamento tem execuções - INTERROMPER
            g_error                := 'FETCH ROWTYPE EPIS_POSITIONING_PLAN(2)';
            l_rows_epis_posit_plan := table_varchar();
        
            OPEN c_epp_e;
            LOOP
                FETCH c_epp_e BULK COLLECT
                    INTO l_epis_positioning_plan_tc LIMIT 1000;
            
                EXIT WHEN l_epis_positioning_plan_tc.count = 0;
            
                FOR j IN 1 .. l_epis_positioning_plan_tc.count
                LOOP
                    l_epis_positioning_plan_tc(j).flg_status := g_epis_posit_i;
                    l_epis_positioning_plan_tc(j).id_prof_exec := i_prof.id;
                    l_epis_positioning_plan_tc(j).dt_epis_positioning_plan := g_sysdate_tstz;
                    l_id_epis_positioning_plan.extend;
                    l_id_epis_positioning_plan(j) := l_epis_positioning_plan_tc(j).id_epis_positioning_plan;
                END LOOP;
            
                g_error := 'call set_epis_posit_plan_hist function';
                pk_alertlog.log_debug(g_error);
                IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                                i_prof                     => i_prof,
                                                i_id_epis_positioning_plan => l_id_epis_positioning_plan,
                                                o_error                    => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
                g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
                l_rowids := table_varchar();
                ts_epis_positioning_plan.upd(col_in            => l_epis_positioning_plan_tc,
                                             ignore_if_null_in => FALSE,
                                             rows_out          => l_rowids);
            
                l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION l_rowids;
            END LOOP;
        
            CLOSE c_epp_e;
        
            IF l_rows_epis_posit_plan.count > 0
            THEN
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING_PLAN',
                                              i_rowids       => l_rows_epis_posit_plan,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
            --
        
            g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_epis_pos;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => table_number(i_epis_pos),
                                             o_error               => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            g_error  := 'UPDATE EPIS_POSITIONING(2)';
            l_rowids := table_varchar();
            ts_epis_positioning.upd(id_epis_positioning_in => i_epis_pos,
                                    flg_status_in          => g_epis_posit_i,
                                    id_prof_inter_in       => i_prof.id,
                                    notes_inter_in         => i_notes,
                                    dt_inter_tstz_in       => g_sysdate_tstz,
                                    dt_epis_positioning_in => g_sysdate_tstz,
                                    rows_out               => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_POSITIONING',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_INTER',
                                                                          'NOTES_INTER',
                                                                          'DT_INTER_TSTZ'));
        
            g_error := 'synchronize epis_positioning to epis_positioning_det';
            pk_alertlog.log_debug(g_error);
            IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => table_number(i_epis_pos),
                                             i_sysdate_tstz        => g_sysdate_tstz,
                                             o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        g_error := 'Call cancel_assoc_icnp_interv';
        IF NOT cancel_assoc_icnp_interv(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_epis_positioning => i_epis_pos,
                                        o_error               => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
        --        
        g_error := 'OPEN C_EPIS_POSITIONING';
        OPEN c_epis_positioning;
        FETCH c_epis_positioning
            INTO l_episode;
        g_found := c_epis_positioning%FOUND;
        CLOSE c_epis_positioning;
        --
        g_error := 'CALL TO PK_CPOE.SYNC_TASK';
        IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                 i_prof                 => i_prof,
                                 i_episode              => l_episode,
                                 i_task_type            => pk_alert_constant.g_task_type_positioning,
                                 i_task_request         => i_epis_pos,
                                 i_task_start_timestamp => g_sysdate_tstz,
                                 o_error                => o_error)
        THEN
            RAISE internal_error_exception;
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
                                              'CANCEL_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
    END;

    FUNCTION get_epis_positioning
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        o_epis_pos OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar os planos de execução dos posicionamentos num episódio. 
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPISODE - ID do episódio
                                 
                          SAIDA: O_EPIS_POS - Listar os planos de execução dos posicionamentos num episódio.
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/15
          NOTAS: 
        *********************************************************************************/
        --  
        l_epis_posit_img_c sys_domain.img_name%TYPE := pk_sysdomain.get_img(i_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_c);
        l_epis_posit_img_f sys_domain.img_name%TYPE := pk_sysdomain.get_img(i_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_f);
        l_epis_posit_img_i sys_domain.img_name%TYPE := pk_sysdomain.get_img(i_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_i);
        l_epis_posit_img_o sys_domain.img_name%TYPE := pk_sysdomain.get_img(i_lang,
                                                                            'EPIS_POSITIONING.FLG_STATUS',
                                                                            g_epis_posit_o);
        --
        l_positioning_m001 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'POSITIONING_M001');
        l_positioning_m002 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'POSITIONING_M002');
    BEGIN
        g_error := 'GET CURSOR O_EPIS_POS';
        pk_alertlog.log_debug(g_error);
        OPEN o_epis_pos FOR
            SELECT ep.id_epis_positioning,
                   ep.flg_status status_epis_posit,
                   epp.id_epis_positioning_plan,
                   epp.flg_status status_epis_posit_plan,
                   epp.id_epis_positioning_det,
                   decode(ep.flg_status,
                          g_epis_posit_o,
                          pk_sysdomain.get_domain('EPIS_POSITIONING.FLG_STATUS', ep.flg_status, i_lang),
                          pk_sysdomain.get_domain('EPIS_POSITIONING_PLAN.FLG_STATUS', epp.flg_status, i_lang)) desc_status_posit_plan,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p
                     INNER JOIN epis_positioning_det epd1
                        ON p.id_positioning = epd1.id_positioning
                     WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_det) desc_pos_first,
                   epp.id_epis_positioning_next,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p
                     INNER JOIN epis_positioning_det epd1
                        ON p.id_positioning = epd1.id_positioning
                     WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_next) desc_pos_next,
                   decode(ep.rot_interval, NULL, NULL, get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)) rotation,
                   pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang) desc_massage,
                   decode(ep.flg_status,
                          g_epis_posit_o,
                          l_epis_posit_img_o,
                          decode(epp.flg_status,
                                 g_epis_posit_r,
                                 pk_date_utils.get_elapsed_abs_tsz(i_lang,
                                                                   nvl(epp.dt_prev_plan_tstz, ep.dt_creation_tstz)),
                                 g_epis_posit_e,
                                 pk_date_utils.get_elapsed_abs_tsz(i_lang,
                                                                   nvl(epp.dt_prev_plan_tstz, ep.dt_creation_tstz)),
                                 g_epis_posit_c,
                                 l_epis_posit_img_c,
                                 g_epis_posit_f,
                                 l_epis_posit_img_f,
                                 l_epis_posit_img_i)) desc_status,
                   decode(ep.flg_status,
                          g_epis_posit_o,
                          'R',
                          decode(pk_date_utils.compare_dates_tsz(i_prof, epp.dt_prev_plan_tstz, current_timestamp),
                                 'G',
                                 'G',
                                 'L',
                                 'R',
                                 'R')) color_status,
                   decode(ep.flg_status, g_epis_posit_o, 'I', decode(epp.flg_status, g_epis_posit_e, 'D', 'I')) flg_text,
                   decode(nvl(ep.notes, nvl(ep.notes_cancel, ep.notes_inter)),
                          NULL,
                          l_positioning_m002,
                          l_positioning_m001) flg_notes,
                   decode(ep.flg_status,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_i,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_f,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_e,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_r,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_d,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_no) flg_cancel,
                   decode(ep.flg_status,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_i,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_f,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_e,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_r,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_d,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_o,
                          check_extra_take(i_lang, i_prof, i_episode, ep.id_epis_positioning),
                          pk_alert_constant.g_no) flg_ok,
                   decode(ep.flg_status,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_i,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_f,
                          pk_alert_constant.g_no,
                          pk_inp_positioning.g_epis_posit_e,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_r,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_d,
                          pk_alert_constant.g_yes,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_alert_constant.g_no,
                          pk_alert_constant.g_no) flg_actions
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
               AND epp.id_epis_positioning_plan IN
                   (SELECT MAX(epp1.id_epis_positioning_plan)
                      FROM epis_positioning_plan epp1
                     WHERE epp1.id_epis_positioning_det IN
                           (SELECT epd1.id_epis_positioning_det
                              FROM epis_positioning_det epd1
                             WHERE epd1.id_epis_positioning = ep.id_epis_positioning))
             WHERE ep.id_episode = i_episode
               AND ep.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
             ORDER BY pk_sysdomain.get_rank(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', epp.flg_status),
                      epp.id_epis_positioning_plan DESC;
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
                                              'GET_EPIS_POSITIONING',
                                              o_error);
            --
            pk_types.open_my_cursor(o_epis_pos);
            RETURN FALSE;
    END;

    FUNCTION get_epis_positioning_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_d OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar o detalhe de um plano de execução de um posicionamento. 
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPIS_POS - ID do episódio do posicionamento
                                 
                          SAIDA: O_EPIS_POS_D - Listar o detalhe de um plano de execução de um posicionamento.
                                 O_ERROR - erro 
          
          CRIAÇÃO: ET 2006/11/15
          NOTAS: 
        *********************************************************************************/
        --
        l_positioning_t029 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'POSITIONING_T029');
    BEGIN
        g_error := 'GET CURSOR O_EPIS_POS_D';
        OPEN o_epis_pos_d FOR
            SELECT t.*,
                   decode(t.status_epis_posit, pk_inp_positioning.g_epis_posit_o, t.notes) notes_epis_posit_exp_rep,
                   decode(t.status_epis_posit, pk_inp_positioning.g_epis_posit_c, t.notes) notes_epis_posit_canc_rep,
                   
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_cancel)) name_prof_canc_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           t.id_prof_cancel,
                                                           t.dt_cancel_tstz,
                                                           t.id_episode)) prof_canc_speciality_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_date_utils.dt_chr_tsz(i_lang, t.dt_cancel_tstz, i_prof)) date_target_canc_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_date_utils.date_char_hour_tsz(i_lang, t.dt_cancel_tstz, i_prof.institution, i_prof.software)) hour_target_canc_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_c,
                          pk_date_utils.date_char_tsz(i_lang, t.dt_cancel_tstz, i_prof.institution, i_prof.software)) dt_target_canc_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_cancel)) name_prof_exp_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           t.id_prof_cancel,
                                                           t.dt_cancel_tstz,
                                                           t.id_episode)) prof_exp_speciality_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_date_utils.dt_chr_tsz(i_lang, t.dt_cancel_tstz, i_prof)) date_target_exp_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_date_utils.date_char_hour_tsz(i_lang, t.dt_cancel_tstz, i_prof.institution, i_prof.software)) hour_target_exp_rep,
                   decode(t.status_epis_posit,
                          pk_inp_positioning.g_epis_posit_o,
                          pk_date_utils.date_char_tsz(i_lang, t.dt_cancel_tstz, i_prof.institution, i_prof.software)) dt_target_exp_rep
              FROM (SELECT decode(ep.rot_interval,
                                  NULL,
                                  NULL,
                                  get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval) /*pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(ep.rot_interval)), i_prof)*/) rotation,
                           ep.id_rotation_interval id_rotation_interval,
                           regexp_substr(ep.rot_interval, '([[:digit:]]*[:]?[[:digit:]]+)?|(h?)') rotation_value,
                           pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang) desc_massage,
                           ep.flg_massage flg_massage,
                           p.nick_name name_prof,
                           pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) date_required,
                           pk_date_utils.dt_chr_tsz(i_lang, ep.dt_creation_tstz, i_prof) date_target,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            ep.dt_creation_tstz,
                                                            i_prof.institution,
                                                            i_prof.software) hour_target,
                           get_positioning_concat(i_lang, i_prof, ep.id_epis_positioning) desc_positioning,
                           (SELECT CAST(COLLECT(to_number(aux.id_positioning)) AS table_number)
                              FROM (SELECT epd.id_positioning
                                      FROM epis_positioning_det epd
                                     INNER JOIN positioning p
                                        ON epd.id_positioning = p.id_positioning
                                     WHERE epd.id_epis_positioning = i_epis_pos
                                       AND epd.flg_outdated = pk_alert_constant.g_no
                                     ORDER BY epd.rank ASC) aux) id_positioning,
                           decode(ep.flg_status,
                                  g_epis_posit_i,
                                  ep.notes_inter,
                                  g_epis_posit_c,
                                  ep.notes_cancel,
                                  g_epis_posit_o,
                                  ep.notes_cancel,
                                  ep.notes) notes,
                           decode(ep.flg_status,
                                  g_epis_posit_i,
                                  pk_message.get_message(i_lang, 'POSITIONING_T016'),
                                  g_epis_posit_c,
                                  pk_message.get_message(i_lang, 'POSITIONING_T015'),
                                  g_epis_posit_o,
                                  l_positioning_t029,
                                  pk_message.get_message(i_lang, 'POSITIONING_T005')) title_notes,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            ep.dt_creation_tstz,
                                                            ep.id_episode) desc_spec,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, current_timestamp, ep.id_episode) desc_spec_by,
                           ep.flg_status status_epis_posit,
                           ep.dt_cancel_tstz,
                           ep.id_prof_cancel,
                           ep.id_episode
                      FROM epis_positioning ep
                      LEFT OUTER JOIN professional p
                        ON ep.id_professional = p.id_professional
                     WHERE ep.id_epis_positioning = i_epis_pos) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSITIONING_DET',
                                              o_error);
            --
            pk_types.open_my_cursor(o_epis_pos_d);
            RETURN FALSE;
    END;

    FUNCTION get_positioning_concat
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        i_dt_epis    IN epis_positioning.dt_epis_positioning%TYPE DEFAULT NULL,
        i_flg_report IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO: Listar de forma concatenada,todos os registos de posicionamentos efectuados para um dado episódio
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPIS_POS - ID do episódio do posicionamento                  
          
          CRIAÇÃO: ET 2006/11/17
          NOTAS: 
        *********************************************************************************/
        l_sep VARCHAR2(1) := ';';
        --
        l_posit_concat VARCHAR2(4000);
        --   
        CURSOR c_posit_concat IS
            SELECT (t.rank || '. ' ||
                   pk_translation.get_translation(i_lang, 'POSITIONING.CODE_POSITIONING.' || t.id_positioning)) desc_positioning
              FROM (SELECT epd.rank, epd.id_positioning
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning = i_epis_pos
                       AND (epd.dt_epis_positioning_det = i_dt_epis OR i_dt_epis IS NULL)
                       AND ((epd.flg_outdated = pk_alert_constant.g_no AND i_flg_report = pk_alert_constant.g_yes) OR
                           i_flg_report = pk_alert_constant.g_no)
                    /*   UNION ALL
                    SELECT epd.rank, epd.id_positioning
                      FROM epis_positioning_det_hist epd
                     WHERE epd.id_epis_positioning = i_epis_pos
                       AND epd.dt_epis_positioning_det = i_dt_epis
                       AND i_dt_epis IS NOT NULL*/
                    ) t
             ORDER BY t.rank;
        --                                     
        --                                    
    
    BEGIN
        g_error := 'OPEN C_POSIT_CONCAT ';
        --
        FOR x_pconcat IN c_posit_concat
        LOOP
            IF l_posit_concat IS NOT NULL
            THEN
                l_posit_concat := l_posit_concat || l_sep || ' ' || x_pconcat.desc_positioning;
            ELSE
                l_posit_concat := x_pconcat.desc_positioning;
            END IF;
        END LOOP;
        --
        RETURN l_posit_concat || '.';
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    FUNCTION get_epis_posit_plan
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        o_epis_pos_plan OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar os planos de posicionamentos para um dado episódio
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPIS_POS - ID do episódio do posicionamento   
                                 
                          SAIDA: O_EPIS_POS_PLAN - Listar os planos de posicionamentos para um dado episódio
                                 O_ERROR - erro                         
          
          CRIAÇÃO: ET 2006/11/17
          NOTAS: 
        *********************************************************************************/
    
    BEGIN
    
        g_error := 'GET CURSOR O_EPIS_POS_PLAN';
        OPEN o_epis_pos_plan FOR
            SELECT t.*,
                   decode(rn,
                          1,
                          pk_date_utils.get_timestamp_str(i_lang, i_prof, t.dt_creation_tstz, NULL),
                          pk_date_utils.get_timestamp_str(i_lang,
                                                          i_prof,
                                                          (t.dt_prev_plan_tstz -
                                                          numtodsinterval(to_number(to_char(to_date(t.rotation,
                                                                                                     'HH24:MI'),
                                                                                             'SSSSS')),
                                                                           'SECOND')),
                                                          NULL)) dt_min_keypad
              FROM (SELECT epp.id_epis_positioning_plan,
                           epp.flg_status status_epis_posit_plan,
                           epp.id_epis_positioning_det,
                           epp.dt_prev_plan_tstz,
                           (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                              FROM positioning p
                             INNER JOIN epis_positioning_det epd1
                                ON p.id_positioning = epd1.id_positioning
                             WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_det) desc_pos_first,
                           epp.id_epis_positioning_next,
                           (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                              FROM positioning p
                             INNER JOIN epis_positioning_det epd1
                                ON p.id_positioning = epd1.id_positioning
                             WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_next) desc_pos_next,
                           pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang) desc_massage,
                           decode(epp.flg_status,
                                  g_epis_posit_r,
                                  pk_date_utils.get_elapsed_abs_tsz(i_lang,
                                                                    nvl(epp.dt_prev_plan_tstz, ep.dt_creation_tstz)),
                                  g_epis_posit_e,
                                  pk_date_utils.get_elapsed_abs_tsz(i_lang,
                                                                    nvl(epp.dt_prev_plan_tstz, ep.dt_creation_tstz)),
                                  g_epis_posit_c,
                                  pk_sysdomain.get_img(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', g_epis_posit_c),
                                  g_epis_posit_o,
                                  pk_sysdomain.get_img(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', g_epis_posit_o),
                                  g_epis_posit_f,
                                  pk_sysdomain.get_img(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', g_epis_posit_f),
                                  pk_sysdomain.get_img(i_lang, 'EPIS_POSITIONING_PLAN.FLG_STATUS', g_epis_posit_i)) desc_status,
                           decode(pk_date_utils.compare_dates_tsz(i_prof, epp.dt_prev_plan_tstz, current_timestamp),
                                  'G',
                                  'G',
                                  'L',
                                  'R',
                                  'R') color_status,
                           decode(epp.flg_status, g_epis_posit_e, 'D', 'I') flg_text,
                           decode(epp.flg_status, g_epis_posit_f, p.nick_name, NULL) name_prof_exec,
                           pk_prof_utils.get_nickname(i_lang, i_prof.id) name_prof_exec_by,
                           ep.rot_interval rotation,
                           ep.dt_creation_tstz,
                           decode(epp.flg_status,
                                  g_epis_posit_f,
                                  pk_date_utils.dt_chr_tsz(i_lang, epp.dt_execution_tstz, i_prof),
                                  NULL) date_target,
                           decode(epp.flg_status,
                                  g_epis_posit_f,
                                  pk_date_utils.date_char_hour_tsz(i_lang,
                                                                   epp.dt_execution_tstz,
                                                                   i_prof.institution,
                                                                   i_prof.software),
                                  NULL) hour_target,
                           decode(epp.notes, NULL, NULL, pk_message.get_message(i_lang, 'COMMON_M008')) title_notes,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            p.id_professional,
                                                            ep.dt_creation_tstz,
                                                            ep.id_episode) desc_spec,
                           pk_prof_utils.get_spec_signature(i_lang, i_prof, i_prof.id, current_timestamp, ep.id_episode) desc_spec_by,
                           pk_date_utils.get_timestamp_str(i_lang,
                                                           i_prof,
                                                           decode(ep.flg_status,
                                                                  g_epis_posit_o,
                                                                  ep.dt_cancel_tstz,
                                                                  current_timestamp),
                                                           NULL) dt_exec_str,
                           decode(ep.flg_status,
                                  g_epis_posit_o,
                                  check_extra_take(i_lang, i_prof, ep.id_episode, ep.id_epis_positioning),
                                  decode(epp.flg_status,
                                         pk_inp_positioning.g_epis_posit_c,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_i,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_f,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_e,
                                         pk_alert_constant.g_yes,
                                         pk_inp_positioning.g_epis_posit_r,
                                         pk_alert_constant.g_yes,
                                         pk_inp_positioning.g_epis_posit_d,
                                         pk_alert_constant.g_yes,
                                         pk_alert_constant.g_no)) flg_ok,
                           decode(ep.flg_status,
                                  g_epis_posit_o,
                                  decode(epp.dt_execution_tstz, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes),
                                  decode(epp.flg_status,
                                         pk_inp_positioning.g_epis_posit_c,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_i,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_f,
                                         pk_alert_constant.g_yes,
                                         pk_inp_positioning.g_epis_posit_e,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_r,
                                         pk_alert_constant.g_no,
                                         pk_inp_positioning.g_epis_posit_d,
                                         pk_alert_constant.g_no,
                                         pk_alert_constant.g_no)) flg_detail,
                           rownum rn
                      FROM epis_positioning ep
                     INNER JOIN epis_positioning_det epd
                        ON ep.id_epis_positioning = epd.id_epis_positioning
                     INNER JOIN epis_positioning_plan epp
                        ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                      LEFT OUTER JOIN professional p
                        ON epp.id_prof_exec = p.id_professional
                     WHERE ep.id_epis_positioning = i_epis_pos
                       AND epp.flg_status NOT IN (g_epis_posit_l, g_epis_posit_d)
                     ORDER BY epp.dt_execution_tstz DESC NULLS FIRST) t;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN',
                                              o_error);
            --
            pk_types.open_my_cursor(o_epis_pos_plan);
        
            RETURN FALSE;
    END;

    FUNCTION get_epis_posit_plan_rank
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_epis_pos                 IN epis_positioning.id_epis_positioning%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE
    ) RETURN NUMBER IS
    
        l_ret NUMBER;
    
    BEGIN
    
        SELECT t.rn
          INTO l_ret
          FROM (SELECT epp.id_epis_positioning_plan, rownum rn
                  FROM epis_positioning ep
                 INNER JOIN epis_positioning_det epd
                    ON ep.id_epis_positioning = epd.id_epis_positioning
                 INNER JOIN epis_positioning_plan epp
                    ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                  LEFT OUTER JOIN professional p
                    ON epp.id_prof_exec = p.id_professional
                 WHERE ep.id_epis_positioning = i_epis_pos
                   AND epp.flg_status NOT IN (g_epis_posit_l, g_epis_posit_d)
                 ORDER BY epp.dt_execution_tstz DESC NULLS FIRST) t
         WHERE t.id_epis_positioning_plan = i_id_epis_positioning_plan;
    
        RETURN l_ret;
    
    END;

    FUNCTION get_epis_posit_plan_det
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pos      IN epis_positioning.id_epis_positioning%TYPE,
        i_epis_pos_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        o_epis_pos_pdet OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
           OBJECTIVO: Listar o detalhe do plano de posicionamento executado
           PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional 
                     I_PROF - ID do profissional, instituição e software
                                 I_EPIS_POS - ID do episódio do posicionamento   
                                 
                          SAIDA: O_EPIS_POS_PDET - Listar o detalhe do plano de posicionamento executado
                                 O_ERROR - erro                         
          
          CRIAÇÃO: ET 2006/11/18
          NOTAS: 
        *********************************************************************************/
    BEGIN
        g_error := 'GET CURSOR O_EPIS_POS_PDET';
        OPEN o_epis_pos_pdet FOR
            SELECT epp.id_epis_positioning_plan,
                   epp.flg_status status_epis_posit_plan,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p
                     INNER JOIN epis_positioning_det epd1
                        ON p.id_positioning = epd1.id_positioning
                     WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_det) desc_pos_first,
                   epp.id_epis_positioning_next,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p
                     INNER JOIN epis_positioning_det epd1
                        ON p.id_positioning = epd1.id_positioning
                     WHERE epd1.id_epis_positioning_det = epp.id_epis_positioning_next) desc_pos_next,
                   epp.notes
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
               AND epp.flg_status IN (g_epis_posit_f, g_epis_posit_o)
               AND epp.id_epis_positioning_plan = i_epis_pos_plan
             WHERE ep.id_epis_positioning = i_epis_pos;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_POSIT_PLAN_DET',
                                              o_error);
            --
            pk_types.open_my_cursor(o_epis_pos_pdet);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * SET_REACTIVATE_POSIT                   Set an epis_positioning back to status after being canceled
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_pos_status              epis_positioning id
    * @param       i_flg_status              new calceled status
    * @param       i_notes                   Status change notes
    * @param       o_error                   error information
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/23
    ********************************************************************************************/
    FUNCTION set_reactivate_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_epis_pos   IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status IN epis_positioning.flg_status%TYPE,
        i_notes      IN epis_positioning.notes%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_positioning_plan_tc ts_epis_positioning_plan.epis_positioning_plan_tc;
        --
        l_rows_epis_posit_plan     table_varchar;
        l_rowids                   table_varchar;
        l_id_epis_positioning_plan table_number := table_number();
        --
        CURSOR c_epp IS
            SELECT *
              FROM epis_positioning_plan epp
             WHERE epp.id_epis_positioning_det =
                   (SELECT epd.id_epis_positioning_det
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning = i_epis_pos
                       AND epd.id_epis_positioning_det = epp.id_epis_positioning_det)
               AND epp.flg_status IN (g_epis_posit_c, g_epis_posit_i);
    BEGIN
        g_error                := 'FETCH ROWTYPE EPIS_POSITIONING_PLAN';
        l_rows_epis_posit_plan := table_varchar();
    
        OPEN c_epp;
        LOOP
            FETCH c_epp BULK COLLECT
                INTO l_epis_positioning_plan_tc LIMIT 1000;
        
            EXIT WHEN l_epis_positioning_plan_tc.count = 0;
        
            FOR j IN 1 .. l_epis_positioning_plan_tc.count
            LOOP
                l_epis_positioning_plan_tc(j).flg_status := g_epis_posit_e;
                l_epis_positioning_plan_tc(j).id_prof_exec := i_prof.id;
                l_epis_positioning_plan_tc(j).dt_epis_positioning_plan := g_sysdate_tstz;
                l_id_epis_positioning_plan.extend;
                l_id_epis_positioning_plan(j) := l_epis_positioning_plan_tc(j).id_epis_positioning_plan;
            END LOOP;
        
            g_error := 'call set_epis_posit_plan_hist function';
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                            i_prof                     => i_prof,
                                            i_id_epis_positioning_plan => l_id_epis_positioning_plan,
                                            o_error                    => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
            l_rowids := table_varchar();
            ts_epis_positioning_plan.upd(col_in            => l_epis_positioning_plan_tc,
                                         ignore_if_null_in => FALSE,
                                         rows_out          => l_rowids);
        
            l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION l_rowids;
        END LOOP;
    
        CLOSE c_epp;
    
        IF l_rows_epis_posit_plan.count > 0
        THEN
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_POSITIONING_PLAN',
                                          i_rowids       => l_rows_epis_posit_plan,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS'));
        END IF;
        --
    
        g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_epis_pos;
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_epis_positioning => table_number(i_epis_pos),
                                         o_error               => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error  := 'UPDATE EPIS_POSITIONING';
        l_rowids := table_varchar();
        ts_epis_positioning.upd(id_epis_positioning_in => i_epis_pos,
                                flg_status_in          => i_flg_status,
                                id_prof_cancel_in      => NULL,
                                id_prof_cancel_nin     => FALSE,
                                id_cancel_reason_in    => NULL,
                                id_cancel_reason_nin   => FALSE,
                                notes_cancel_in        => NULL,
                                notes_cancel_nin       => FALSE,
                                dt_cancel_tstz_in      => NULL,
                                dt_cancel_tstz_nin     => FALSE,
                                id_prof_inter_in       => NULL,
                                id_prof_inter_nin      => FALSE,
                                notes_inter_in         => NULL,
                                notes_inter_nin        => FALSE,
                                dt_inter_tstz_in       => NULL,
                                dt_inter_tstz_nin      => FALSE,
                                dt_epis_positioning_in => g_sysdate_tstz,
                                rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_POSITIONING',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('FLG_STATUS',
                                                                      'ID_PROF_CANCEL',
                                                                      'NOTES_CANCEL',
                                                                      'DT_CANCEL_TSTZ',
                                                                      'ID_PROF_INTER',
                                                                      'NOTES_INTER',
                                                                      'DT_INTER_TSTZ'));
    
        g_error := 'synchronize epis_positioning to epis_positioning_det';
        pk_alertlog.log_debug(g_error);
        IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_epis_positioning => table_number(i_epis_pos),
                                         i_sysdate_tstz        => g_sysdate_tstz,
                                         o_error               => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'SET_REACTIVATE_POSIT',
                                              o_error);
            RETURN FALSE;
    END set_reactivate_posit;

    /********************************************************************************************
    * SET_EPIS_POS_STATUS                    Set an epis_positioning to interrupted
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_pos_status              epis_positioning id
    * @param       i_flg_status              New status ('I' - Discontinued)
    * @param       i_notes                   Status change notes
    * @param       i_id_cancel_reason        Cancel reason ID
    * @param       o_error                   error information
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Emilia Taborda                      
    * @version                               2.4.0                             
    * @since                                 2006/Nov/18       
    *
    * @change                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22    
    ********************************************************************************************/
    FUNCTION set_epis_pos_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_msg_error        OUT VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_char             VARCHAR2(1);
        l_char_det         VARCHAR2(1);
        l_num_active_posit PLS_INTEGER;
        l_episode          episode.id_episode%TYPE;
        l_old_flg_status   epis_positioning.flg_status%TYPE;
        l_new_flg_status   epis_positioning.flg_status%TYPE;
        l_rowids           table_varchar;
        --
        CURSOR c_epis_pos IS
            SELECT flg_status
              FROM epis_positioning
             WHERE id_epis_positioning = i_epis_pos
               AND flg_status IN (g_epis_posit_r, g_epis_posit_e, g_epis_posit_d);
        --
        CURSOR c_epis_pos_plan IS
            SELECT 'X'
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
             WHERE ep.id_epis_positioning = i_epis_pos
               AND ep.flg_status = g_epis_posit_e
               AND epp.flg_status = g_epis_posit_f;
    
        --
        CURSOR c_epis_positioning IS
            SELECT id_episode
              FROM epis_positioning
             WHERE id_epis_positioning = i_epis_pos;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- verificar se o episódio de posicionamento está requisitado ou em curso
        g_error := 'OPEN C_EPIS_POS';
        OPEN c_epis_pos;
        FETCH c_epis_pos
            INTO l_char;
        g_found := c_epis_pos%FOUND;
        CLOSE c_epis_pos;
        --
        IF g_found
           AND i_flg_status <> g_epis_posit_a
        THEN
            g_error := 'OPEN C_EPIS_POS_PLAN';
            OPEN c_epis_pos_plan;
            FETCH c_epis_pos_plan
                INTO l_char_det;
            g_found := c_epis_pos_plan%FOUND;
            CLOSE c_epis_pos_plan;
            --
            IF i_flg_status IN (g_epis_posit_c, g_epis_posit_l, g_epis_posit_o)
            THEN
                IF NOT g_found
                THEN
                    l_new_flg_status := CASE
                                            WHEN i_flg_status = g_epis_posit_o THEN
                                             g_epis_posit_o
                                            WHEN l_char = g_epis_posit_d THEN
                                             g_epis_posit_l
                                            ELSE
                                             g_epis_posit_c
                                        END;
                ELSE
                    l_new_flg_status := CASE
                                            WHEN i_flg_status = g_epis_posit_o THEN
                                             g_epis_posit_o
                                            ELSE
                                             g_epis_posit_i
                                        END;
                END IF;
            
            ELSIF i_flg_status <> g_epis_posit_f
            THEN
                l_new_flg_status := g_epis_posit_i;
            ELSE
                l_new_flg_status := i_flg_status;
            END IF;
        
            g_error := 'call set_cancel_interrupt_posit for id_epis_positioning: ' || i_epis_pos;
            pk_alertlog.log_debug(g_error);
            IF NOT set_cancel_interrupt_posit(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_epis_pos         => i_epis_pos,
                                              i_flg_status       => l_new_flg_status,
                                              i_notes            => i_notes,
                                              i_id_cancel_reason => i_id_cancel_reason,
                                              o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
        END IF;
    
        -- IF tasks are reactivated
        IF i_flg_status = g_epis_posit_a
        THEN
            g_error := 'GET L_NUM_ACTIVE_POSIT';
            SELECT COUNT(1)
              INTO l_num_active_posit
              FROM epis_positioning ep2
             INNER JOIN (SELECT ep.id_episode
                           FROM epis_positioning ep
                          WHERE ep.id_epis_positioning = i_epis_pos) epi
                ON (ep2.id_episode = epi.id_episode)
             WHERE ep2.flg_status IN (g_epis_posit_r, g_epis_posit_e);
        
            IF l_num_active_posit > 0
            -- an error should be returned to user
            THEN
                o_msg_error := to_char(pk_utils.replaceclob(pk_message.get_message(i_lang, 'POSITIONING_T019'),
                                                            '@1',
                                                            get_all_posit_desc(i_lang, i_prof, i_epis_pos)));
                RETURN FALSE;
            ELSIF l_num_active_posit = 0
            -- IF there is one active positioning for this episode, old positioning should not became active again.
            -- This happends because for one episode, only one positioning can be active each time.
            THEN
                g_error := 'GET L_NEW_FLG_STATUS';
                BEGIN
                    SELECT ep.flg_status
                      INTO l_old_flg_status
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = i_epis_pos;
                EXCEPTION
                    WHEN no_data_found THEN
                        RETURN FALSE;
                END;
            
                IF l_old_flg_status = g_epis_posit_c
                THEN
                    l_new_flg_status := g_epis_posit_r;
                ELSE
                    l_new_flg_status := g_epis_posit_e;
                END IF;
            
                IF l_old_flg_status <> g_epis_posit_o
                THEN
                
                    g_error := 'CALL PK_INP_POSITIONING.SET_REACTIVATE_POSIT (i_flg_status=A AND new_status=' ||
                               l_new_flg_status || ')';
                    IF NOT set_reactivate_posit(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_epis_pos   => i_epis_pos,
                                                i_flg_status => l_new_flg_status,
                                                i_notes      => i_notes,
                                                o_error      => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
        
            IF i_flg_status IN (g_epis_posit_c, g_epis_posit_i, g_epis_posit_o)
            THEN
                g_error := 'Call cancel_assoc_icnp_interv';
                IF NOT cancel_assoc_icnp_interv(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_epis_positioning => i_epis_pos,
                                                o_error               => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            END IF;
        END IF;
        --
        --UPDATE EPIS_POSITIONING_DET        
        IF NOT update_epis_posit_det(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_epis_positioning => table_number(i_epis_pos),
                                     i_update_plan         => FALSE,
                                     l_rows                => l_rowids,
                                     o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
        --
        g_error := 'OPEN C_EPIS_POSITIONING';
        OPEN c_epis_positioning;
        FETCH c_epis_positioning
            INTO l_episode;
        CLOSE c_epis_positioning;
    
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
                                              'SET_EPIS_POS_STATUS',
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * GET_ONGOING_TASKS_POSIT                Get all tasks available to cancel when a patient dies
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    *
    * @return       tf_tasks_list            table of tr_tasks_list
    *
    * @author                                Luís Maia                        
    * @version                               2.6.0.3                                    
    * @since                                 2010/May/22       
    ********************************************************************************************/
    FUNCTION get_ongoing_tasks_posit
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN tf_tasks_list IS
        l_ongoing_tasks tf_tasks_list;
    BEGIN
        g_error := 'POPULATE l_ongoing_tasks';
        SELECT tr_tasks_list(posit.id_task, posit.desc_task, posit.epis_type, posit.dt_task)
          BULK COLLECT
          INTO l_ongoing_tasks
          FROM (SELECT ep.id_epis_positioning id_task,
                       get_all_posit_desc(i_lang, i_prof, ep.id_epis_positioning) desc_task,
                       pk_translation.get_translation(i_lang, et.code_epis_type) epis_type,
                       pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                          ep.dt_creation_tstz,
                                                          i_prof.institution,
                                                          i_prof.software) dt_task
                  FROM episode epi
                 INNER JOIN epis_positioning ep
                    ON (ep.id_episode = epi.id_episode)
                 INNER JOIN epis_type et
                    ON (et.id_epis_type = epi.id_epis_type)
                 WHERE epi.id_patient = i_patient
                   AND ep.flg_status IN (g_epis_posit_e, g_epis_posit_r)
                 ORDER BY ep.dt_creation_tstz DESC) posit;
    
        RETURN l_ongoing_tasks;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ongoing_tasks_posit;

    /************************************************************************************************************ 
    * Return positioning description including all positioning sequence
    *
    * @param      i_lang           language ID
    * @param      i_prof           professional information
    * @param      i_episode        episode ID
    *    
    * @author     Luís Maia
    * @version    2.5.0.7
    * @since      2009/11/02
    *
    * @dependencies    This function was developed to Content team
    ***********************************************************************************************************/
    FUNCTION get_all_posit_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE
    ) RETURN VARCHAR2 IS
        l_all_posit_desc VARCHAR2(32000);
        l_interval_title sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                                 i_code_mess => 'INP_POSITIONING_T101') || ': ';
        --
    BEGIN
        --
        g_error := 'GET ALL POSITIONS DESC';
        SELECT pk_utils.concat_table(CAST(MULTISET (SELECT pk_translation.get_translation(i_lang, pos2.code_positioning)
                                             FROM epis_positioning ep2
                                            INNER JOIN epis_positioning_det epd2
                                               ON (epd2.id_epis_positioning = ep2.id_epis_positioning)
                                            INNER JOIN positioning pos2
                                               ON (pos2.id_positioning = epd2.id_positioning)
                                            WHERE ep2.id_epis_positioning = ep.id_epis_positioning
                                            ORDER BY epd2.rank) AS table_varchar),
                                     ', ') || chr(10) ||
               decode(ep.rot_interval,
                      NULL,
                      NULL,
                      l_interval_title || get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)
                      /*pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(ep.rot_interval)), i_prof)*/) task_description
        --
          INTO l_all_posit_desc
        --
          FROM epis_positioning ep --, epis_positioning_det epd, epis_positioning_plan epp
         WHERE ep.id_epis_positioning = i_id_epis_positioning;
        --
        RETURN l_all_posit_desc;
        --
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_all_posit_desc;

    /**************************************************************************
    * Updates existing epis_positioning values                                *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    epis position id                    *
    * @param i_epis_positioning           epis positioning id                 *
    * @param i_posit                      posit id array                      *
    * @param i_rot_interv                 rotation interval value             *
    * @param i_id_rot_interv              rotation interval identifier        *
    * @param i_flg_massage                Massage needed flag                 *
    * @param i_notes                      Notes                               *
    * @param i_pos_type                   Position request type               *
    * @param i_flg_type                   Request identification type         *
    *                                                                         *
    * @param o_error                      Error object                        *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION edit_epis_positioning
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_positioning     IN epis_positioning.id_epis_positioning%TYPE,
        i_posit                IN table_number,
        i_rot_interv           IN rotation_interval.interval%TYPE,
        i_id_rot_interv        IN rotation_interval.id_rotation_interval%TYPE,
        i_flg_massage          IN epis_positioning.flg_massage%TYPE,
        i_notes                IN epis_positioning.notes%TYPE,
        i_pos_type             IN positioning_type.id_positioning_type%TYPE,
        i_flg_type             IN epis_positioning.flg_status%TYPE,
        i_task_start_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        --      
        l_char       VARCHAR2(1);
        l_next_epd   epis_positioning_det.id_epis_positioning_det%TYPE;
        l_next_epp   epis_positioning_plan.id_epis_positioning_plan%TYPE;
        cont         NUMBER := 2;
        l_posit_next epis_positioning_plan.id_epis_positioning_next%TYPE;
        --
        l_pos_type            positioning_type.id_positioning_type%TYPE;
        l_dt_creation_tstz    epis_positioning.dt_creation_tstz%TYPE;
        l_dt_epis_positioning epis_positioning.dt_epis_positioning%TYPE;
    
        l_rot_interv VARCHAR2(8);
    
        --
        l_rowids               table_varchar;
        l_rows_epis_posit_det  table_varchar;
        l_rows_epis_posit_plan table_varchar;
        l_epis_posit_det       table_number;
        l_epis_posit_plan      table_number;
    
        --
        CURSOR c_episode IS
            SELECT 'X'
              FROM episode
             WHERE id_episode = i_episode
               AND flg_status = g_epis_active;
        --                            
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        -- verificar se o episódio está activo
        g_error := 'OPEN C_EPISODE';
        OPEN c_episode;
        FETCH c_episode
            INTO l_char;
        g_found := c_episode%NOTFOUND;
        CLOSE c_episode;
        --
    
        IF i_pos_type IS NULL
        THEN
            IF i_posit.count = 1
            THEN
                l_pos_type := 2;
            ELSE
                l_pos_type := 1;
            END IF;
        ELSE
            l_pos_type := i_pos_type;
        END IF;
    
        IF i_task_start_timestamp IS NOT NULL
        THEN
            l_dt_creation_tstz := i_task_start_timestamp;
        ELSE
            l_dt_creation_tstz := g_sysdate_tstz;
        
        END IF;
    
        l_dt_epis_positioning := g_sysdate_tstz;
    
        IF g_found
        THEN
            --
            -- verificar se o registo está no estado DRAFT
            /*            g_error := 'OPEN C_EPIS_POSIT';
            OPEN c_epis_posit;
            FETCH c_epis_posit
                INTO l_char;
            g_found := c_epis_posit%FOUND;
            CLOSE c_epis_posit;*/
            --
            BEGIN
                SELECT epd.id_epis_positioning_det
                  BULK COLLECT
                  INTO l_epis_posit_det
                  FROM epis_positioning_det epd
                 WHERE epd.id_epis_positioning = i_epis_positioning
                   AND epd.flg_outdated = pk_alert_constant.g_no;
            EXCEPTION
                WHEN no_data_found THEN
                    l_epis_posit_det := table_number();
            END;
        
            BEGIN
                SELECT epp.id_epis_positioning_plan
                  BULK COLLECT
                  INTO l_epis_posit_plan
                  FROM epis_positioning_plan epp
                 WHERE epp.id_epis_positioning_det IN (SELECT /*+ OPT_ESTIMATE (TABLE d ROWS=1)*/
                                                        d.column_value
                                                         FROM TABLE(l_epis_posit_det) d);
            EXCEPTION
                WHEN no_data_found THEN
                    l_epis_posit_plan := table_number();
            END;
        
            g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_epis_positioning;
            pk_alertlog.log_debug(g_error);
            IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_id_epis_positioning => table_number(i_epis_positioning),
                                             o_error               => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
            IF i_rot_interv IS NOT NULL
            THEN
                l_rot_interv := get_rot_interv_format(i_rot_interv);
            ELSE
                l_rot_interv := NULL;
            END IF;
        
            g_error := 'UPDATE EPIS_POSITIONING';
            ts_epis_positioning.upd(id_epis_positioning_in   => i_epis_positioning,
                                    flg_status_in            => CASE
                                                                    WHEN i_flg_type = g_epis_posit_d THEN
                                                                     i_flg_type
                                                                    ELSE
                                                                    
                                                                     g_epis_posit_r
                                                                END,
                                    flg_status_nin           => FALSE,
                                    flg_massage_in           => nvl(i_flg_massage, g_flg_massage_n),
                                    flg_massage_nin          => FALSE,
                                    notes_in                 => i_notes,
                                    notes_nin                => FALSE,
                                    rot_interval_in          => l_rot_interv,
                                    rot_interval_nin         => FALSE,
                                    id_rotation_interval_in  => i_id_rot_interv,
                                    id_rotation_interval_nin => FALSE,
                                    dt_epis_positioning_in   => l_dt_epis_positioning,
                                    rows_out                 => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_POSITIONING',
                                          i_rowids       => l_rowids,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'FLG_MASSAGE',
                                                                          'NOTES',
                                                                          'ROT_INTERVAL',
                                                                          'ID_ROTATION_INTERVAL'));
        
            l_rows_epis_posit_det  := table_varchar();
            l_rows_epis_posit_plan := table_varchar();
            -- Array com os posicionamentos
            FOR i IN 1 .. i_posit.count
            LOOP
                IF i = 1
                THEN
                    g_error := 'CALL SET_EPIS_POSIT_DET_HIST FUNCTION';
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_epis_positioning_plan => l_epis_posit_plan,
                                                    o_error                    => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    l_rowids := table_varchar();
                
                    IF l_epis_posit_plan IS NOT NULL
                       AND l_epis_posit_plan.count > 0
                    THEN
                    
                        FOR l IN l_epis_posit_plan.first .. l_epis_posit_plan.last
                        LOOP
                            ts_epis_positioning_plan.upd(id_epis_positioning_plan_in => l_epis_posit_plan(l),
                                                         id_prof_exec_in             => i_prof.id,
                                                         flg_status_in               => g_epis_posit_o,
                                                         rows_out                    => l_rowids);
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'EPIS_POSITIONING_PLAN',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        END LOOP;
                    END IF;
                
                    g_error := 'CALL SET_EPIS_POSIT_DET_HIST FUNCTION';
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_epis_posit_det_hist(i_lang                    => i_lang,
                                                   i_prof                    => i_prof,
                                                   i_id_epis_positioning_det => l_epis_posit_det,
                                                   o_error                   => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    g_error  := 'DELETE FROM epis_positioning_det';
                    l_rowids := table_varchar();
                    IF l_epis_posit_det IS NOT NULL
                       AND l_epis_posit_det.count > 0
                    THEN
                    
                        FOR b IN l_epis_posit_det.first .. l_epis_posit_det.last
                        LOOP
                        
                            ts_epis_positioning_det.upd(id_epis_positioning_det_in => l_epis_posit_det(b),
                                                        flg_outdated_in            => pk_alert_constant.g_yes,
                                                        rows_out                   => l_rowids);
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'EPIS_POSITIONING_DET',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                        END LOOP;
                    
                    END IF;
                
                END IF;
            
                g_error    := 'GET SEQ_EPIS_POSITIONING_DET.NEXTVAL';
                l_next_epd := ts_epis_positioning_det.next_key();
                --
                l_rowids := table_varchar();
                g_error  := 'INSERT EPIS_POSITIONING_DET';
                ts_epis_positioning_det.ins(id_epis_positioning_det_in => l_next_epd,
                                            id_epis_positioning_in     => i_epis_positioning,
                                            id_positioning_in          => i_posit(i),
                                            rank_in                    => i,
                                            adw_last_update_in         => g_sysdate_tstz,
                                            id_prof_last_upd_in        => i_prof.id,
                                            dt_epis_positioning_det_in => g_sysdate_tstz,
                                            rows_out                   => l_rowids);
            
                l_rows_epis_posit_det := l_rows_epis_posit_det MULTISET UNION DISTINCT l_rowids;
            
                --
                pk_alertlog.log_debug(text            => 'L_POS_TYPE: ' || l_pos_type,
                                      object_name     => g_package_name,
                                      sub_object_name => 'EDIT_EPIS_POSITIONING');
                --
                IF l_pos_type = g_pos_type_s
                THEN
                    IF i = i_posit.count
                    THEN
                        g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL(S)';
                        l_next_epp := ts_epis_positioning_plan.next_key();
                        --
                        g_error  := 'INSERT EPIS_POSITIONING_PLAN(S)';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                                     id_epis_positioning_det_in  => nvl(l_posit_next, l_next_epd),
                                                     id_epis_positioning_next_in => l_next_epd,
                                                     id_prof_exec_in             => i_prof.id,
                                                     dt_prev_plan_tstz_in        => l_dt_creation_tstz,
                                                     flg_status_in               => CASE
                                                                                        WHEN i_flg_type = g_epis_posit_d THEN
                                                                                         i_flg_type
                                                                                        ELSE
                                                                                        --g_epis_posit_f
                                                                                         g_epis_posit_e
                                                                                    END,
                                                     notes_in                    => i_notes,
                                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                                     rows_out                    => l_rowids);
                        l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION DISTINCT l_rowids;
                    
                    ELSE
                        l_posit_next := l_next_epd;
                    END IF;
                
                ELSE
                
                    IF i = cont
                    THEN
                        g_error    := 'GET SEQ_EPIS_POSITIONING_PLAN.NEXTVAL(M)';
                        l_next_epp := ts_epis_positioning_plan.next_key();
                        --
                        g_error  := 'INSERT EPIS_POSITIONING_PLAN(M)';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => l_next_epp,
                                                     id_epis_positioning_det_in  => l_posit_next,
                                                     id_epis_positioning_next_in => l_next_epd,
                                                     id_prof_exec_in             => i_prof.id,
                                                     dt_prev_plan_tstz_in        => l_dt_creation_tstz,
                                                     flg_status_in               => CASE
                                                                                        WHEN i_flg_type = g_epis_posit_d THEN
                                                                                         i_flg_type
                                                                                        ELSE
                                                                                         g_epis_posit_e
                                                                                    END,
                                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                                     rows_out                    => l_rowids);
                        l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION DISTINCT l_rowids;
                    ELSE
                        l_posit_next := l_next_epd;
                    END IF;
                END IF;
            END LOOP;
        
            IF (l_rows_epis_posit_det.count > 0)
            THEN
                g_error := 't_data_gov_mnt call to EPIS_POSITIONING_DET';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_DET',
                                              i_rowids     => l_rows_epis_posit_det,
                                              o_error      => o_error);
            END IF;
        
            IF (l_rows_epis_posit_plan.count > 0)
            THEN
                g_error := 't_data_gov_mnt call to EPIS_POSITIONING_PLAN';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_PLAN',
                                              i_rowids     => l_rows_epis_posit_plan,
                                              o_error      => o_error);
            END IF;
        
            IF i_flg_type <> g_epis_posit_d
            THEN
                g_error := 'CALL TO PK_CPOE.SYNC_TASK';
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_episode,
                                         i_task_type            => pk_alert_constant.g_task_type_positioning,
                                         i_task_request         => i_epis_positioning,
                                         i_task_start_timestamp => g_sysdate_tstz,
                                         o_error                => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'EDIT_EPIS_POSITIONING',
                                              o_error);
            RETURN FALSE;
    END edit_epis_positioning;

    /********************************************************************************************
    * activates a set of draft tasks (task goes from draft to active workflow)
    *
    * @param I_LANG          language id
    * @param I_PROF          professional, software and institution ids
    * @param I_EPISODE       episode id
    * @param I_DRAFT         array of selected drafts
    * @param O_ERROR         warning/error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Gustavo Serrano
    * @version               1.0 
    * @since                 17-Nov-2009
    *********************************************************************************************/
    FUNCTION activate_drafts
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_draft         IN table_number,
        o_created_tasks OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_char                     VARCHAR2(1);
        l_rowids                   table_varchar;
        l_rows_epis_posit_plan     table_varchar;
        l_rows_epis_posit_det      table_varchar;
        l_epis_positioning_plan_tc ts_epis_positioning_plan.epis_positioning_plan_tc;
        l_row_epis_posit_det       epis_positioning_det%ROWTYPE;
        l_id_epis_posit            table_number;
        l_ep_flg_status            epis_positioning.flg_status%TYPE;
        l_epp_flg_status           epis_positioning_plan.flg_status%TYPE;
        l_num_reg                  PLS_INTEGER;
        l_epis_posit_flag          epis_positioning.flg_status%TYPE;
        l_num_lines_posit          PLS_INTEGER;
        l_num_lines_plan           PLS_INTEGER;
        l_num_lines_draft          PLS_INTEGER;
    
        l_next_epd                 epis_positioning_det.id_epis_positioning_det%TYPE;
        l_id_epis_positioning_det  epis_positioning_det.id_epis_positioning_det%TYPE;
        l_id_epis_positioning_next epis_positioning_det.id_epis_positioning_det%TYPE;
    
        l_id_positioning           table_number;
        l_id_epis_positioning_plan table_number := table_number();
    
        l_task_type           cpoe_task_type.id_task_type%TYPE;
        l_epis_pos_flg_status epis_positioning.flg_status%TYPE;
        l_count_rel_tasks     NUMBER;
        l_exception EXCEPTION;
    
        l_draft       table_number;
        l_id_request  interv_presc_det.id_interv_presc_det%TYPE;
        l_msg_error   VARCHAR2(1000 CHAR);
        l_dt_epis_pos epis_positioning.dt_epis_positioning%TYPE;
        --
    
        --
        CURSOR c_epis_posit(l_epis_posit epis_positioning.id_epis_positioning%TYPE) IS
            SELECT 'X', ep.flg_status, ep.dt_epis_positioning
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = l_epis_posit
               AND flg_status = g_epis_posit_d;
    
        CURSOR c_epp(l_id_epis_posit epis_positioning.id_epis_positioning%TYPE) IS
            SELECT epp.*
              FROM epis_positioning_plan epp
             INNER JOIN epis_positioning_det epd
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
             WHERE epd.id_epis_positioning = l_id_epis_posit
               AND epp.flg_status IN (g_epis_posit_e, g_epis_posit_d);
    
        CURSOR c_epd(l_id_epis_posit epis_positioning.id_epis_positioning%TYPE) IS
            SELECT epd.*
              FROM epis_positioning_det epd
             WHERE epd.id_epis_positioning = l_id_epis_posit
               AND epd.flg_outdated = pk_alert_constant.g_no;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        l_id_epis_positioning_plan.delete;
    
        o_created_tasks := i_draft;
    
        l_num_lines_draft := i_draft.count;
        FOR i IN 1 .. l_num_lines_draft
        LOOP
            -- check if there are records in DRAFT
            g_error := 'OPEN C_EPIS_POSIT';
            OPEN c_epis_posit(i_draft(i));
            FETCH c_epis_posit
                INTO l_char, l_epis_pos_flg_status, l_dt_epis_pos;
            g_found := c_epis_posit%FOUND;
            CLOSE c_epis_posit;
        
            l_task_type := pk_cpoe.g_task_type_positioning;
        
            BEGIN
                SELECT a.id_task_orig
                  INTO l_count_rel_tasks
                  FROM cpoe_tasks_relation a
                 WHERE a.id_task_dest = i_draft(i)
                   AND a.id_task_type = l_task_type
                   AND a.flg_type = 'AD';
            EXCEPTION
                WHEN no_data_found THEN
                    l_count_rel_tasks := 0;
            END;
        
            IF l_count_rel_tasks > 0
            THEN
                SELECT a.flg_status
                  INTO l_epis_pos_flg_status
                  FROM epis_positioning a
                 WHERE a.id_epis_positioning = l_count_rel_tasks;
            END IF;
        
            IF l_count_rel_tasks > 0
               AND l_epis_pos_flg_status IN (pk_inp_positioning.g_epis_posit_e, pk_inp_positioning.g_epis_posit_r)
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
                          INTO l_id_request
                          FROM cpoe_tasks_relation a
                         WHERE a.id_task_dest = i_draft(i);
                        l_draft(i) := l_id_request;
                    END IF;
                END LOOP;
            
                IF NOT set_epis_pos_status(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_epis_pos         => i_draft(i),
                                           i_flg_status       => g_epis_posit_l,
                                           i_notes            => NULL,
                                           i_id_cancel_reason => NULL,
                                           o_msg_error        => l_msg_error,
                                           o_error            => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            
                o_created_tasks := l_draft;
            
                RETURN TRUE;
            END IF;
        
            --
            IF g_found
            THEN
                --
                g_error := 'GET NUM OF POSITIONS';
                SELECT COUNT(1)
                  INTO l_num_reg
                  FROM epis_positioning_det epd
                 WHERE epd.id_epis_positioning = i_draft(i)
                   AND epd.flg_outdated = pk_alert_constant.g_no;
            
                --
                IF l_num_reg = 1
                THEN
                    l_ep_flg_status  := g_epis_posit_f;
                    l_epp_flg_status := g_epis_posit_f;
                ELSE
                    l_ep_flg_status  := g_epis_posit_r;
                    l_epp_flg_status := g_epis_posit_e;
                END IF;
            
                g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_draft(i);
                pk_alertlog.log_debug(g_error);
                IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_epis_positioning => table_number(i_draft(i)),
                                                 o_error               => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            
                g_error := 'UPDATE EPIS_POSITIONING';
                ts_epis_positioning.upd(id_epis_positioning_in => i_draft(i),
                                        id_professional_in     => i_prof.id,
                                        flg_status_in          => l_ep_flg_status,
                                        flg_status_nin         => FALSE,
                                        dt_epis_positioning_in => g_sysdate_tstz,
                                        rows_out               => l_rowids);
            
                IF l_epp_flg_status <> g_epis_posit_f
                THEN
                    g_error := 'get id_positioning for id_epis_posit:' || i_draft(i);
                    SELECT epd.id_positioning
                      BULK COLLECT
                      INTO l_id_positioning
                      FROM epis_positioning ep
                     INNER JOIN epis_positioning_det epd
                        ON epd.id_epis_positioning = ep.id_epis_positioning
                     WHERE ep.id_epis_positioning = i_draft(i);
                
                    g_error := 'Call create_assoc_icnp_interv';
                    IF NOT create_assoc_icnp_interv(i_lang                => i_lang,
                                                    i_prof                => i_prof,
                                                    i_id_epis_positioning => i_draft(i),
                                                    i_id_episode          => i_episode,
                                                    i_positioning_types   => l_id_positioning,
                                                    o_error               => o_error)
                    THEN
                        RAISE internal_error_exception;
                    END IF;
                END IF;
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            
                g_error := 'synchronize epis_positioning to epis_positioning_det';
                pk_alertlog.log_debug(g_error);
                IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_epis_positioning => i_draft,
                                                 i_sysdate_tstz        => g_sysdate_tstz,
                                                 o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_rows_epis_posit_det := table_varchar();
                l_rowids              := table_varchar();
                OPEN c_epd(i_draft(i));
                LOOP
                    FETCH c_epd
                        INTO l_row_epis_posit_det;
                    EXIT WHEN c_epd%NOTFOUND;
                
                    ts_epis_positioning_det.upd(id_epis_positioning_det_in => l_row_epis_posit_det.id_epis_positioning_det,
                                                flg_outdated_in            => pk_alert_constant.g_yes,
                                                rows_out                   => l_rowids);
                
                    l_rows_epis_posit_det := l_rowids MULTISET UNION l_rowids;
                
                    l_next_epd := ts_epis_positioning_det.next_key;
                
                    ts_epis_positioning_det.ins(id_epis_positioning_det_in => l_next_epd,
                                                id_epis_positioning_in     => l_row_epis_posit_det.id_epis_positioning,
                                                id_positioning_in          => l_row_epis_posit_det.id_positioning,
                                                rank_in                    => l_row_epis_posit_det.rank,
                                                id_prof_last_upd_in        => i_prof.id,
                                                dt_epis_positioning_det_in => g_sysdate_tstz,
                                                flg_outdated_in            => pk_alert_constant.g_no,
                                                rows_out                   => l_rowids);
                
                    l_rows_epis_posit_det := l_rowids MULTISET UNION l_rowids;
                END LOOP;
                CLOSE c_epd;
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR EPIS_POSITIONING_DET TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING_DET',
                                              i_rowids       => l_rows_epis_posit_det,
                                              i_list_columns => table_varchar('ID_PROF_LAST_UPD',
                                                                              'DT_EPIS_POSITIONING_DET'),
                                              o_error        => o_error);
            
                g_error                := 'FETCH ROWTYPE EPIS_POSITIONING_PLAN';
                l_rows_epis_posit_plan := table_varchar();
            
                OPEN c_epp(i_draft(i));
                LOOP
                    FETCH c_epp BULK COLLECT
                        INTO l_epis_positioning_plan_tc LIMIT 1000;
                
                    EXIT WHEN l_epis_positioning_plan_tc.count = 0;
                
                    l_num_lines_plan := l_epis_positioning_plan_tc.count;
                    FOR j IN 1 .. l_num_lines_plan
                    LOOP
                        l_epis_positioning_plan_tc(j).id_prof_exec := i_prof.id;
                        l_epis_positioning_plan_tc(j).flg_status := l_epp_flg_status;
                        l_epis_positioning_plan_tc(j).dt_epis_positioning_plan := g_sysdate_tstz;
                        l_id_epis_positioning_plan.extend;
                        l_id_epis_positioning_plan(j) := l_epis_positioning_plan_tc(j).id_epis_positioning_plan;
                    END LOOP;
                
                    g_error := 'call set_epis_posit_plan_hist function';
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                                    i_prof                     => i_prof,
                                                    i_id_epis_positioning_plan => l_id_epis_positioning_plan,
                                                    o_error                    => o_error)
                    THEN
                        RAISE internal_error_exception;
                    END IF;
                
                    FOR j IN l_epis_positioning_plan_tc.first .. l_epis_positioning_plan_tc.last
                    LOOP
                        g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.upd(id_epis_positioning_plan_in => l_epis_positioning_plan_tc(j).id_epis_positioning_plan,
                                                     flg_status_in               => g_epis_posit_o,
                                                     rows_out                    => l_rowids);
                    
                        g_error := 'UPDATE L_ID_EPIS_POSITIONING_DET';
                        SELECT epd.id_epis_positioning_det
                          INTO l_id_epis_positioning_det
                          FROM epis_positioning_det epd
                         WHERE epd.id_epis_positioning = i_draft(i)
                           AND rank = 1
                           AND epd.flg_outdated = pk_alert_constant.g_no;
                    
                        g_error := 'UPDATE L_ID_EPIS_POSITIONING_NEXT';
                        IF l_epis_positioning_plan_tc(j).id_epis_positioning_det = l_epis_positioning_plan_tc(j).id_epis_positioning_next
                        THEN
                            l_id_epis_positioning_next := l_id_epis_positioning_det;
                        ELSE
                            SELECT epd.id_epis_positioning_det
                              INTO l_id_epis_positioning_next
                              FROM epis_positioning_det epd
                             WHERE epd.id_epis_positioning = i_draft(i)
                               AND rank = 2
                               AND epd.flg_outdated = pk_alert_constant.g_no;
                        END IF;
                    
                        g_error  := 'INSERT EPIS_POSITIONING_PLAN(M)';
                        l_rowids := table_varchar();
                        ts_epis_positioning_plan.ins(id_epis_positioning_plan_in => seq_epis_positioning_plan.nextval,
                                                     id_epis_positioning_det_in  => l_id_epis_positioning_det,
                                                     id_epis_positioning_next_in => l_id_epis_positioning_next,
                                                     id_prof_exec_in             => l_epis_positioning_plan_tc(j).id_prof_exec,
                                                     dt_prev_plan_tstz_in        => l_epis_positioning_plan_tc(j).dt_prev_plan_tstz,
                                                     flg_status_in               => g_epis_posit_e,
                                                     dt_epis_positioning_plan_in => g_sysdate_tstz,
                                                     rows_out                    => l_rowids);
                    END LOOP;
                
                    l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION l_rowids;
                END LOOP;
            
                CLOSE c_epp;
            
                IF l_rows_epis_posit_plan.count > 0
                THEN
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'EPIS_POSITIONING_PLAN',
                                                  i_rowids       => l_rowids,
                                                  o_error        => o_error,
                                                  i_list_columns => table_varchar('DT_PREV_PLAN_TSTZ'));
                END IF;
            
                SELECT epp.dt_prev_plan_tstz
                  INTO l_dt_epis_pos
                  FROM epis_positioning ep
                 INNER JOIN epis_positioning_det epd
                    ON epd.id_epis_positioning = ep.id_epis_positioning
                 INNER JOIN epis_positioning_plan epp
                    ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                 WHERE ep.id_epis_positioning = i_draft(i)
                   AND epp.flg_status NOT IN (g_epis_posit_l)
                   AND epp.id_epis_positioning_plan IN
                       (SELECT MAX(epp1.id_epis_positioning_plan)
                          FROM epis_positioning_plan epp1
                         WHERE epp1.id_epis_positioning_det IN
                               (SELECT epd1.id_epis_positioning_det
                                  FROM epis_positioning_det epd1
                                 WHERE epd1.id_epis_positioning = ep.id_epis_positioning));
            
                g_error := 'CALL TO PK_CPOE.SYNC_TASK';
                IF NOT pk_cpoe.sync_task(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_episode              => i_episode,
                                         i_task_type            => pk_alert_constant.g_task_type_positioning,
                                         i_task_request         => i_draft(i),
                                         i_task_start_timestamp => l_dt_epis_pos,
                                         o_error                => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN internal_error_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'ACTIVATE_DRAFTS',
                                              o_error);
            RETURN FALSE;
    END activate_drafts;

    /**************************************************************************
    * set new episode when executing match functionality                      *
    *                                                                         *
    * @param       i_lang             preferred language id for this          *
    *                                 professional                            *
    * @param       i_prof             professional id structure               *
    * @param       i_current_episode  episode id                              *
    * @param       i_new_episode      array of selected drafts                *
    * @param       o_error            error message                           *
    *                                                                         *
    * @return      boolean            true on success, otherwise false        *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/11/17                              *
    **************************************************************************/
    FUNCTION set_new_match_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode_temp IN episode.id_episode%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowid_tab table_varchar;
        l_rowids    table_varchar;
        l_epis_pos  epis_positioning.id_epis_positioning%TYPE;
        l_msg_error VARCHAR2(4000) := NULL;
        --
        CURSOR c_epis_pos IS
            SELECT ep.id_epis_positioning
              FROM epis_positioning ep
             WHERE ep.id_episode IN (i_episode_temp, i_episode)
               AND ep.flg_status IN (g_epis_posit_r, g_epis_posit_e)
                  -- Só é efectuado o UPDATE qd existe mais do que um episódio com o estado R ou E
               AND EXISTS (SELECT COUNT(*)
                      FROM epis_positioning ep1
                     WHERE ep1.id_episode IN (i_episode_temp, i_episode)
                       AND ep1.flg_status IN (g_epis_posit_r, g_epis_posit_e) HAVING COUNT(*) > 1)
                  --Será cancelado o episódio com menor data
               AND ep.dt_creation_tstz =
                   (SELECT MIN(ep2.dt_creation_tstz)
                      FROM epis_positioning ep2
                     WHERE ep2.id_episode IN (i_episode_temp, i_episode)
                       AND ep2.flg_status IN (g_epis_posit_r, g_epis_posit_e));
    BEGIN
    
        -- POSITIONING
        -- Nos episódios de posicionamento, pode existir mais do que um episódio activo (requisitado ou em curso),
        -- desta forma torna se necessário garantir que só exista UM episódio nesse estado
        --
        g_error := 'OPEN C_EPIS_POS';
        OPEN c_epis_pos;
        FETCH c_epis_pos
            INTO l_epis_pos;
        CLOSE c_epis_pos;
        --
    
        IF (l_epis_pos IS NOT NULL)
        THEN
            g_error := 'CALL Pk_Inp_Positioning.SET_EPIS_POS_STATUS';
            IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_epis_pos         => l_epis_pos,
                                                          i_flg_status       => g_epis_posit_c,
                                                          i_notes            => NULL,
                                                          i_id_cancel_reason => NULL,
                                                          o_msg_error        => l_msg_error,
                                                          o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        g_error := 'CALL TS_EPIS_POSITIONING_HIST.UPD WITH ID_EPISODE = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        l_rowids := table_varchar();
        ts_epis_positioning_hist.upd(id_episode_in  => i_episode,
                                     id_episode_nin => FALSE,
                                     where_in       => 'id_episode = ' || i_episode_temp,
                                     rows_out       => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_POSITIONING_HIST',
                                      i_rowids       => l_rowids,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
        g_error := 'CALL TS_EPIS_POSITIONING.UPD WITH ID_EPISODE = ' || i_episode_temp;
        pk_alertlog.log_debug(g_error);
        l_rowid_tab := table_varchar();
        ts_epis_positioning.upd(id_episode_in  => i_episode,
                                id_episode_nin => FALSE,
                                where_in       => 'id_episode = ' || i_episode_temp,
                                rows_out       => l_rowid_tab);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'EPIS_POSITIONING',
                                      i_rowids       => l_rowid_tab,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_EPISODE'));
    
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
                                              'SET_NEW_MATCH_EPIS',
                                              o_error);
            RETURN FALSE;
    END set_new_match_epis;

    /********************************************************************************************
    * get detailed task information to be used in CPOE task history view
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_patient                 patient id
    * @param       i_episode                 episode id
    * @param       i_epis_positioning        Epis positioning id
    * @param       o_epis_posit_hist_info    cursor with epis positioning history info (status changes info)
    * @param       o_epis_posit_info         cursor with detailed epis positioning info
    * @param       o_error                   error information
    *
    * @return      boolean                   true on success, otherwise false
    ********************************************************************************************/
    FUNCTION get_task_detail
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_epis_positioning     IN cpoe_process_task.id_task_request%TYPE,
        o_epis_posit_hist_info OUT pk_types.cursor_type,
        o_epis_posit_info      OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(4000) INDEX BY sys_message.code_message%TYPE;
    
        tbl_code_messages t_code_messages;
    
        va_code_messages table_varchar2 := table_varchar2('POSITIONING_T009',
                                                          'POSITIONING_T002',
                                                          'POSITIONING_T004',
                                                          'POSITIONING_T010',
                                                          'POSITIONING_T011',
                                                          'POSITIONING_T016',
                                                          'POSITIONING_T015',
                                                          'POSITIONING_T005',
                                                          'POSITIONING_T029');
    
    BEGIN
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            tbl_code_messages(va_code_messages(i)) := pk_message.get_message(i_lang, va_code_messages(i));
        END LOOP;
    
        g_error := 'Open o_epis_posit_info';
        OPEN o_epis_posit_info FOR
            SELECT tbl_code_messages('POSITIONING_T009'),
                   get_positioning_concat(i_lang, i_prof, ep.id_epis_positioning) desc_positioning,
                   
                   tbl_code_messages('POSITIONING_T002'),
                   decode(ep.rot_interval,
                          NULL,
                          NULL,
                          get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)
                          /*pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(ep.rot_interval)), i_prof)*/) rotation,
                   
                   tbl_code_messages('POSITIONING_T004'),
                   pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang) desc_massage,
                   
                   tbl_code_messages('POSITIONING_T010'),
                   pk_prof_utils.get_nickname(i_lang, ep.id_professional) name_prof,
                   
                   tbl_code_messages('POSITIONING_T011'),
                   pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) date_required,
                   
                   decode(ep.flg_status,
                          g_epis_posit_i,
                          tbl_code_messages('POSITIONING_T016'),
                          g_epis_posit_c,
                          tbl_code_messages('POSITIONING_T015'),
                          g_epis_posit_o,
                          tbl_code_messages('POSITIONING_T029'),
                          tbl_code_messages('POSITIONING_T005')) title_notes,
                   decode(ep.flg_status,
                          g_epis_posit_i,
                          ep.notes_inter,
                          g_epis_posit_c,
                          ep.notes_cancel,
                          g_epis_posit_o,
                          ep.notes_cancel,
                          ep.notes) notes,
                   
                   pk_sysdomain.get_domain('EPIS_POSITIONING.FLG_STATUS', ep.flg_status, i_lang) flg_status_desc,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(ep.flg_status,
                                                      g_epis_posit_i,
                                                      ep.dt_inter_tstz,
                                                      g_epis_posit_c,
                                                      ep.dt_cancel_tstz,
                                                      g_epis_posit_o,
                                                      ep.dt_cancel_tstz,
                                                      ep.dt_creation_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_action,
                   
                   pk_prof_utils.get_nickname(i_lang,
                                              decode(ep.flg_status,
                                                     g_epis_posit_i,
                                                     ep.id_prof_inter,
                                                     g_epis_posit_c,
                                                     ep.id_prof_cancel,
                                                     g_epis_posit_o,
                                                     ep.id_prof_cancel,
                                                     ep.id_professional)) prof_action
              FROM epis_positioning ep
             WHERE ep.id_epis_positioning = i_epis_positioning;
    
        g_error := 'Open o_epis_posit_info';
        OPEN o_epis_posit_hist_info FOR
            SELECT tbl_code_messages('POSITIONING_T009'),
                   get_positioning_hist_concat(i_lang, i_prof, ep.id_epis_positioning) desc_positioning,
                   
                   tbl_code_messages('POSITIONING_T002'),
                   decode(ep.rot_interval,
                          NULL,
                          NULL,
                          get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)
                          /*pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(ep.rot_interval)), i_prof)*/) rotation,
                   
                   tbl_code_messages('POSITIONING_T004'),
                   pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang) desc_massage,
                   
                   tbl_code_messages('POSITIONING_T010'),
                   pk_prof_utils.get_nickname(i_lang, ep.id_professional) name_prof,
                   
                   tbl_code_messages('POSITIONING_T011'),
                   pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) date_required,
                   
                   decode(ep.flg_status,
                          g_epis_posit_i,
                          tbl_code_messages('POSITIONING_T016'),
                          g_epis_posit_c,
                          tbl_code_messages('POSITIONING_T015'),
                          g_epis_posit_o,
                          tbl_code_messages('POSITIONING_T029'),
                          tbl_code_messages('POSITIONING_T005')) title_notes,
                   decode(ep.flg_status,
                          g_epis_posit_i,
                          ep.notes_inter,
                          g_epis_posit_c,
                          ep.notes_cancel,
                          g_epis_posit_o,
                          ep.notes_cancel,
                          ep.notes) notes,
                   
                   pk_sysdomain.get_domain('EPIS_POSITIONING.FLG_STATUS', ep.flg_status, i_lang) flg_status_desc,
                   pk_date_utils.date_char_tsz(i_lang,
                                               decode(ep.flg_status,
                                                      g_epis_posit_i,
                                                      ep.dt_inter_tstz,
                                                      g_epis_posit_c,
                                                      ep.dt_cancel_tstz,
                                                      g_epis_posit_o,
                                                      ep.dt_cancel_tstz,
                                                      ep.dt_creation_tstz),
                                               i_prof.institution,
                                               i_prof.software) dt_action,
                   
                   pk_prof_utils.get_nickname(i_lang,
                                              decode(ep.flg_status,
                                                     g_epis_posit_i,
                                                     ep.id_prof_inter,
                                                     g_epis_posit_c,
                                                     ep.id_prof_cancel,
                                                     g_epis_posit_o,
                                                     ep.id_prof_cancel,
                                                     ep.id_professional)) prof_action
              FROM epis_positioning_hist ep
             WHERE ep.id_epis_positioning = i_epis_positioning;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_TASK_DETAIL',
                                              o_error);
            pk_types.open_cursor_if_closed(o_epis_posit_hist_info);
            pk_types.open_cursor_if_closed(o_epis_posit_info);
            RETURN FALSE;
    END get_task_detail;

    FUNCTION get_positioning_hist_concat
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_epis_pos IN epis_positioning_det_hist.id_epis_positioning%TYPE
    ) RETURN VARCHAR2 IS
    
        l_sep VARCHAR2(1) := ';';
        --
        l_posit_concat VARCHAR2(4000);
        --   
        CURSOR c_posit_concat IS
            SELECT (epd.rank || '. ' || pk_translation.get_translation(i_lang, p.code_positioning)) desc_positioning
              FROM epis_positioning_det_hist epd
             INNER JOIN positioning p
                ON epd.id_positioning = p.id_positioning
             WHERE epd.id_epis_positioning = i_epis_pos
             ORDER BY epd.rank ASC;
        --                                                                      
    BEGIN
        g_error := 'OPEN C_POSIT_CONCAT ';
        --
        FOR x_pconcat IN c_posit_concat
        LOOP
            IF l_posit_concat IS NOT NULL
            THEN
                l_posit_concat := l_posit_concat || l_sep || ' ' || x_pconcat.desc_positioning;
            ELSE
                l_posit_concat := x_pconcat.desc_positioning;
            END IF;
        END LOOP;
        --
        RETURN l_posit_concat || '.';
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**********************************************************************************************
    * get_therapeutic_status         Returns information about a given request
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_id_request            Request ID
    * @param o_description           Description
    * @param o_instructions          Instructions
    * @param o_flg_status            Flg_status Y/N  N: not proceed with nursing intervention
    *                        
    * @author                        António Neto
    * @version                       v2.6.0.5
    * @since                         28-Feb-2011
    **********************************************************************************************/
    PROCEDURE get_therapeutic_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_request   IN NUMBER,
        o_description  OUT VARCHAR2,
        o_instructions OUT VARCHAR2,
        o_flg_status   OUT VARCHAR2
    ) IS
    BEGIN
        g_error := 'i_id_request:' || i_id_request;
        SELECT get_positioning_concat(i_lang, i_prof, ep.id_epis_positioning),
               pk_message.get_message(i_lang, 'POSITIONING_T002') || ': ' ||
               decode(ep.rot_interval,
                      NULL,
                      NULL,
                      get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)
                      /*pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(ep.rot_interval)), i_prof)*/) ||
               decode(ep.flg_massage,
                      NULL,
                      '',
                      '; ' || pk_message.get_message(i_lang, 'POSITIONING_T004') || ': ' ||
                      pk_sysdomain.get_domain(g_yes_no, ep.flg_massage, i_lang)) || '.',
               decode(ep.flg_status,
                      g_epis_posit_c,
                      pk_alert_constant.g_no,
                      g_epis_posit_o,
                      pk_alert_constant.g_no,
                      pk_alert_constant.g_yes)
          INTO o_description, o_instructions, o_flg_status
          FROM epis_positioning ep
         WHERE ep.id_epis_positioning = i_id_request;
    
    END get_therapeutic_status;

    /*********************************************************************************************
    * Saves the current state of a epis_positioning record to the history table.
    * 
    * @param    i_lang                              Language ID
    * @param    i_prof                              Professional
    * @param    i_id_epis_positioning               table number with epis positioning ID
    * 
    * @param    o_error                             error message
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/06
    **********************************************************************************************/

    FUNCTION set_epis_positioning_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name            VARCHAR2(30 CHAR) := 'SET_EPIS_POSITIONING_HIST';
        l_id_epis_positioning_hist epis_positioning_hist.id_epis_positioning_hist%TYPE;
        r_epis_positioning         epis_positioning%ROWTYPE;
        l_rows                     table_varchar;
    
    BEGIN
    
        IF i_id_epis_positioning IS NOT NULL
           AND i_id_epis_positioning.count > 0
        THEN
        
            FOR i IN 1 .. i_id_epis_positioning.count
            LOOP
                SELECT ep.*
                  INTO r_epis_positioning
                  FROM epis_positioning ep
                 WHERE ep.id_epis_positioning = i_id_epis_positioning(i);
            
                l_id_epis_positioning_hist := ts_epis_positioning_hist.next_key;
            
                ts_epis_positioning_hist.ins(id_epis_positioning_hist_in => l_id_epis_positioning_hist,
                                             id_epis_positioning_in      => r_epis_positioning.id_epis_positioning,
                                             id_episode_in               => r_epis_positioning.id_episode,
                                             id_professional_in          => r_epis_positioning.id_professional,
                                             flg_status_in               => r_epis_positioning.flg_status,
                                             flg_massage_in              => r_epis_positioning.flg_massage,
                                             notes_in                    => r_epis_positioning.notes,
                                             id_prof_cancel_in           => r_epis_positioning.id_prof_cancel,
                                             notes_cancel_in             => r_epis_positioning.notes_cancel,
                                             rot_interval_in             => r_epis_positioning.rot_interval,
                                             id_prof_inter_in            => r_epis_positioning.id_prof_inter,
                                             notes_inter_in              => r_epis_positioning.notes_inter,
                                             dt_creation_tstz_in         => r_epis_positioning.dt_creation_tstz,
                                             dt_cancel_tstz_in           => r_epis_positioning.dt_cancel_tstz,
                                             dt_inter_tstz_in            => r_epis_positioning.dt_inter_tstz,
                                             id_rotation_interval_in     => r_epis_positioning.id_rotation_interval,
                                             id_cancel_reason_in         => r_epis_positioning.id_cancel_reason,
                                             dt_epis_positioning_in      => r_epis_positioning.dt_epis_positioning,
                                             flg_origin_in               => r_epis_positioning.flg_origin,
                                             rows_out                    => l_rows);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR EPIS_POSITIONING_HIST TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_HIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END LOOP;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_epis_positioning_hist;

    /********************************************************************************************
    * Get positioning description
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_epis_positioning_det  Epis_positioning_det ID
    *
    * @return      positioning's description
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_positioning_description
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning_det IN epis_positioning_det.id_epis_positioning_det%TYPE
    ) RETURN VARCHAR2 IS
    
        l_posit_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        BEGIN
            SELECT pk_translation.get_translation(i_lang, p.code_positioning)
              INTO l_posit_desc
              FROM epis_positioning_det epd
             INNER JOIN positioning p
                ON p.id_positioning = epd.id_positioning
             WHERE epd.id_epis_positioning_det = i_id_epis_positioning_det;
        EXCEPTION
            WHEN no_data_found THEN
                l_posit_desc := NULL;
        END;
    
        RETURN l_posit_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_positioning_description;

    /********************************************************************************************
    * Get the positioning  detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_positioning       Epis_positioning Id
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1
    * @since                          11-Apr-2011
    **********************************************************************************************/
    FUNCTION get_epis_positioning_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_screen          IN VARCHAR2,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name    VARCHAR2(30) := 'GET_EPIS_POSITIONING_HIST';
        l_limit        PLS_INTEGER := 1000;
        l_counter      PLS_INTEGER := 0;
        l_tbl_lables   table_varchar := table_varchar();
        l_tbl_values   table_varchar := table_varchar();
        l_tbl_types    table_varchar := table_varchar();
        l_tbl_tags_req table_varchar := table_varchar();
        l_tab_hist     t_table_history_data := t_table_history_data();
    
        l_inp_code_messages       t_code_messages;
        l_inp_posit_code_messages table_varchar2 := table_varchar2('POSITIONING_T029',
                                                                   'POSITIONING_T030',
                                                                   'POSITIONING_T023',
                                                                   'POSITIONING_T024',
                                                                   'COMMON_M107',
                                                                   'POSITIONING_T025',
                                                                   'COMMON_M108',
                                                                   'POSITIONING_T026',
                                                                   'POSITIONING_T027',
                                                                   'POSITIONING_T028',
                                                                   'POSITIONING_M003',
                                                                   'POSITIONING_M004',
                                                                   'POSITIONING_M005',
                                                                   'POSITIONING_M006',
                                                                   'POSITIONING_M007',
                                                                   'POSITIONING_M008',
                                                                   'POSITIONING_M009',
                                                                   'POSITIONING_M010',
                                                                   'POSITIONING_M011',
                                                                   'POSITIONING_M012',
                                                                   'POSITIONING_M013',
                                                                   'POSITIONING_M014',
                                                                   'POSITIONING_M015',
                                                                   'POSITIONING_M016',
                                                                   'POSITIONING_M017',
                                                                   'POSITIONING_M018',
                                                                   'POSITIONING_M019',
                                                                   'POSITIONING_M020',
                                                                   'COMMON_M108',
                                                                   'COMMON_M106',
                                                                   'POSITIONING_M021',
                                                                   'POSITIONING_M022',
                                                                   'MED_PRESC_T088',
                                                                   'POSITIONING_M023',
                                                                   'POSITIONING_M024',
                                                                   'POSITIONING_M025');
    
        CURSOR c_get_positionings_req IS
            SELECT *
              FROM (SELECT eph.*
                      FROM epis_positioning_hist eph
                     WHERE eph.id_epis_positioning = i_id_epis_positioning
                       AND i_flg_screen = pk_inp_detail.g_history_h
                    UNION ALL
                    SELECT NULL id_epis_positioning_hist, ep.*
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = i_id_epis_positioning) t
             ORDER BY id_epis_positioning_hist DESC NULLS FIRST;
    
        TYPE c_positioning_req IS TABLE OF c_get_positionings_req%ROWTYPE;
        l_positioning_req  c_positioning_req;
        l_posit_req_struct c_positioning_req := c_positioning_req();
    
        CURSOR c_get_positionings_plan IS
            SELECT *
              FROM (SELECT NULL id_epis_posit_plan_hist, epp.*
                      FROM epis_positioning_det epd
                     INNER JOIN epis_positioning_plan epp
                        ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = i_id_epis_positioning
                       AND epp.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
                    UNION ALL
                    SELECT epph.*
                      FROM epis_positioning_det epd
                     INNER JOIN epis_posit_plan_hist epph
                        ON epph.id_epis_positioning_det = epd.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = i_id_epis_positioning
                       AND epph.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
                       AND i_flg_screen = pk_inp_detail.g_history_h) t
             ORDER BY id_epis_positioning_plan, dt_epis_positioning_plan;
    
        TYPE c_positioning_plan IS TABLE OF c_get_positionings_plan%ROWTYPE;
        l_positioning_plan  c_positioning_plan;
        l_posit_plan_struct c_positioning_plan := c_positioning_plan();
    
    BEGIN
        -- fill all translations in collection
        FOR i IN l_inp_posit_code_messages.first .. l_inp_posit_code_messages.last
        LOOP
            l_inp_code_messages(l_inp_posit_code_messages(i)) := pk_message.get_message(i_lang,
                                                                                        l_inp_posit_code_messages(i));
        END LOOP;
    
        -- get positionings requisition records
        g_error := 'OPEN C_GET_POSITIONINGS_REQ CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_positionings_req;
        LOOP
            FETCH c_get_positionings_req BULK COLLECT
                INTO l_positioning_req LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_req.count
            LOOP
                l_posit_req_struct.extend;
                l_posit_req_struct(l_posit_req_struct.count) := l_positioning_req(i);
            END LOOP;
            EXIT WHEN c_get_positionings_req%NOTFOUND;
        END LOOP;
    
        FOR c IN 1 .. l_posit_req_struct.count
        LOOP
            --last record doesn't need to be compared  
            IF (c = l_posit_req_struct.count)
            THEN
                g_error := 'call get_first_values_req';
                pk_alertlog.log_debug(g_error);
                IF NOT get_first_values_req(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_actual_row => l_posit_req_struct(l_posit_req_struct.count),
                                            i_labels     => l_inp_code_messages,
                                            i_flg_screen => i_flg_screen,
                                            o_tbl_labels => l_tbl_lables,
                                            o_tbl_values => l_tbl_values,
                                            o_tbl_types  => l_tbl_types,
                                            o_tbl_tags   => l_tbl_tags_req)
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
            
                --compare current record with the next record to check what's differences between them
                g_error := 'call get_values_req';
                pk_alertlog.log_debug(g_error);
                IF NOT get_values_req(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_actual_row   => l_posit_req_struct(c),
                                      i_previous_row => l_posit_req_struct(c + 1),
                                      i_labels       => l_inp_code_messages,
                                      o_tbl_labels   => l_tbl_lables,
                                      o_tbl_values   => l_tbl_values,
                                      o_tbl_types    => l_tbl_types,
                                      o_tbl_tags     => l_tbl_tags_req)
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
            l_tab_hist.extend;
            l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec => CASE
                                                                             WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                              l_posit_req_struct(c).id_epis_positioning
                                                                             ELSE
                                                                              l_posit_req_struct(c).id_epis_positioning_hist
                                                                         END,
                                                               
                                                               flg_status      => l_posit_req_struct(c).flg_status,
                                                               date_rec        => l_posit_req_struct(c).dt_epis_positioning,
                                                               tbl_labels      => l_tbl_lables,
                                                               tbl_values      => l_tbl_values,
                                                               tbl_types       => l_tbl_types,
                                                               tbl_info_labels => pk_inp_detail.get_info_labels,
                                                               tbl_info_values => pk_inp_detail.get_info_values(l_posit_req_struct(c).flg_status),
                                                               table_origin    => CASE
                                                                                      WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                                       'EPIS_POSITIONING'
                                                                                      ELSE
                                                                                       'EPIS_POSITIONING_HIST'
                                                                                  END);
        
        END LOOP;
    
        -- get positionings plan records
        OPEN c_get_positionings_plan;
        LOOP
            FETCH c_get_positionings_plan BULK COLLECT
                INTO l_positioning_plan LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_plan.count
            LOOP
                l_posit_plan_struct.extend;
                l_posit_plan_struct(l_posit_plan_struct.count) := l_positioning_plan(i);
            END LOOP;
            EXIT WHEN c_get_positionings_plan%NOTFOUND;
        END LOOP;
    
        FOR j IN 1 .. l_posit_plan_struct.count
        LOOP
        
            --in case is the first record or the current record is different the previous record so isn't necessary
            -- to compare these records
            IF (j = 1 OR
               (l_posit_plan_struct(j - 1).id_epis_positioning_plan != l_posit_plan_struct(j).id_epis_positioning_plan))
            THEN
                -- execution identifier (for example execution (1))
                l_counter := l_counter + 1;
                IF NOT get_first_values_plan(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_actual_row => l_posit_plan_struct(j),
                                             i_counter    => l_counter,
                                             i_labels     => l_inp_code_messages,
                                             i_flg_screen => i_flg_screen,
                                             o_tbl_labels => l_tbl_lables,
                                             o_tbl_values => l_tbl_values,
                                             o_tbl_types  => l_tbl_types,
                                             o_tbl_tags   => l_tbl_tags_req)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
            
                --compare current record with the previous record to check what's differences between them
                IF NOT get_values_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_episode   => i_id_episode,
                                       i_actual_row   => l_posit_plan_struct(j),
                                       i_previous_row => l_posit_plan_struct(j - 1),
                                       i_counter      => l_counter,
                                       i_labels       => l_inp_code_messages,
                                       o_tbl_labels   => l_tbl_lables,
                                       o_tbl_values   => l_tbl_values,
                                       o_tbl_types    => l_tbl_types,
                                       o_tbl_tags     => l_tbl_tags_req)
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        
            l_tab_hist.extend;
            l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => CASE
                                                                                      WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                       l_posit_plan_struct(j).id_epis_positioning_plan
                                                                                      ELSE
                                                                                       l_posit_plan_struct(j).id_epis_posit_plan_hist
                                                                                  END,
                                                               flg_status      => l_posit_plan_struct(j).flg_status,
                                                               date_rec        => l_posit_plan_struct(j).dt_epis_positioning_plan,
                                                               tbl_labels      => l_tbl_lables,
                                                               tbl_values      => l_tbl_values,
                                                               tbl_types       => l_tbl_types,
                                                               tbl_info_labels => pk_inp_detail.get_info_labels,
                                                               tbl_info_values => pk_inp_detail.get_info_values(l_posit_plan_struct(j).flg_status),
                                                               table_origin    => CASE
                                                                                      WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                       'EPIS_POSITIONING_PLAN'
                                                                                      ELSE
                                                                                       'EPIS_POSITIONING_PLAN_HIST'
                                                                                  END);
        
        END LOOP;
    
        g_error := 'OPEN o_hist';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        IF i_flg_screen = pk_inp_detail.g_detail_d
        THEN
            OPEN o_hist FOR
                SELECT t.id_rec          id_epis_positioning,
                       t.tbl_labels      tbl_labels,
                       t.tbl_values      tbl_values,
                       t.tbl_types       tbl_types,
                       t.tbl_info_labels info_labels,
                       t.tbl_info_values info_values
                  FROM TABLE(l_tab_hist) t
                 ORDER BY t.table_origin, t.id_rec;
        ELSE
            OPEN o_hist FOR
                SELECT t.id_rec          id_epis_positioning,
                       t.tbl_labels      tbl_labels,
                       t.tbl_values      tbl_values,
                       t.tbl_types       tbl_types,
                       t.tbl_info_labels info_labels,
                       t.tbl_info_values info_values
                  FROM TABLE(l_tab_hist) t
                 ORDER BY t.date_rec DESC, t.table_origin DESC, t.id_rec DESC;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_positioning_hist;

    /********************************************************************************************
    * Get the fields data to be shown in the detail current information screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning data current record
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_first_values_req
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_actual_row IN epis_positioning_hist%ROWTYPE,
        i_labels     IN t_code_messages,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar,
        o_tbl_tags   OUT table_varchar
    ) RETURN BOOLEAN IS
    
        l_start_date   epis_positioning_plan.dt_prev_plan_tstz%TYPE;
        l_count_record PLS_INTEGER := 0; --To check if the requisition has been updated
    
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
        o_tbl_tags   := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M003'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TITLE');
    
        --status          
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M004'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING.FLG_STATUS',
                                                                         i_val      => i_actual_row.flg_status,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS');
    
        --Positionings
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M005'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => get_positioning_concat(i_lang,
                                                                        i_prof,
                                                                        i_actual_row.id_epis_positioning,
                                                                        i_actual_row.dt_epis_positioning),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POSITIONINGS');
    
        --START DATE
        BEGIN
            SELECT t.dt_prev_plan_tstz
              INTO l_start_date
              FROM (SELECT epp.dt_prev_plan_tstz
                      FROM epis_positioning ep
                      JOIN epis_positioning_det epd
                        ON epd.id_epis_positioning = ep.id_epis_positioning
                       AND epd.dt_epis_positioning_det = ep.dt_epis_positioning
                      JOIN epis_positioning_plan epp
                        ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                     WHERE ep.id_epis_positioning = i_actual_row.id_epis_positioning
                       AND ep.dt_epis_positioning = i_actual_row.dt_epis_positioning
                       AND epd.rank = 1
                    UNION
                    SELECT epph.dt_prev_plan_tstz
                      FROM epis_positioning_hist eph
                      JOIN epis_positioning_det_hist epdh
                        ON epdh.id_epis_positioning = eph.id_epis_positioning
                       AND epdh.dt_epis_positioning_det = eph.dt_epis_positioning
                      JOIN epis_posit_plan_hist epph
                        ON epph.id_epis_positioning_det = epdh.id_epis_positioning_det
                     WHERE eph.id_epis_positioning = i_actual_row.id_epis_positioning
                       AND eph.dt_epis_positioning = i_actual_row.dt_epis_positioning
                       AND epdh.rank = 1
                       AND i_flg_screen = g_flg_screen_history) t;
        
        EXCEPTION
            WHEN OTHERS THEN
                l_start_date := NULL;
        END;
    
        IF l_start_date IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M025'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 l_start_date,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'START_DATE');
        END IF;
    
        --Rotation         
        IF i_actual_row.rot_interval IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M006'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => get_fomatted_rot_interv(i_lang, i_prof, i_actual_row.rot_interval),
                                       --pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(i_actual_row.rot_interval)), i_prof),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'ROTATION');
        END IF;
    
        --Massage     
        IF i_actual_row.flg_massage IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M007'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(g_yes_no, i_actual_row.flg_massage, i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'MASSAGE');
        END IF;
    
        -- notes        
        IF i_actual_row.notes IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M008'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => i_actual_row.notes,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES');
        
        END IF;
    
        --Cancellation info
        IF i_actual_row.flg_status IN (g_epis_posit_c, g_epis_posit_i, g_epis_posit_f)
        THEN
            IF i_actual_row.id_cancel_reason IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => CASE
                                                             WHEN i_actual_row.flg_status = g_epis_posit_i THEN
                                                              i_labels('MED_PRESC_T088')
                                                             WHEN i_actual_row.flg_status = g_epis_posit_f THEN
                                                              i_labels('POSITIONING_M023')
                                                             ELSE
                                                              i_labels('POSITIONING_M009')
                                                         END,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                 i_prof             => i_prof,
                                                                                                 i_id_cancel_reason => i_actual_row.id_cancel_reason),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
                IF i_actual_row.flg_status = g_epis_posit_c
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CANCEL_REASON');
                ELSIF i_actual_row.flg_status = g_epis_posit_i
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'DISCONTINUE_REASON');
                ELSE
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CONCLUSION_REASON');
                END IF;
            
            END IF;
        
            IF i_actual_row.notes_cancel IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => CASE
                                                             WHEN i_actual_row.flg_status = g_epis_posit_f THEN
                                                              i_labels('POSITIONING_M024')
                                                             ELSE
                                                              i_labels('POSITIONING_M010')
                                                         END,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_actual_row.notes_cancel,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
                IF i_actual_row.flg_status = g_epis_posit_c
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CANCEL_NOTES');
                ELSIF i_actual_row.flg_status = g_epis_posit_i
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'DISCONTINUE_NOTES');
                ELSE
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CONCLUSION_NOTES');
                END IF;
            
            END IF;
        END IF;
    
        SELECT COUNT(1)
          INTO l_count_record
          FROM epis_positioning_hist eph
         WHERE eph.id_epis_positioning = i_actual_row.id_epis_positioning;
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_actual_row.id_episode,
                                                                             i_date                => i_actual_row.dt_epis_positioning,
                                                                             i_id_prof_last_change => i_actual_row.id_professional,
                                                                             i_code_desc           => CASE
                                                                                                          WHEN l_count_record > 0
                                                                                                               AND i_flg_screen = g_flg_screen_detail THEN
                                                                                                           'POSITIONING_M027'
                                                                                                          ELSE
                                                                                                           'POSITIONING_M026'
                                                                                                      END),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'SIGNATURE');
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'WHITE_LINE');
    
        RETURN TRUE;
    END get_first_values_req;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the difference between the 
    * different steps performed by the user.
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_previous_row            Epis_positioning_plan data previous record 
    * @param       i_labels                  Structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_values_req
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_actual_row   IN epis_positioning_hist%ROWTYPE,
        i_previous_row IN epis_positioning_hist%ROWTYPE,
        i_labels       IN t_code_messages,
        o_tbl_labels   OUT table_varchar,
        o_tbl_values   OUT table_varchar,
        o_tbl_types    OUT table_varchar,
        o_tbl_tags     OUT table_varchar
    ) RETURN BOOLEAN IS
        l_has_differences      BOOLEAN := FALSE;
        l_actual_positioning   VARCHAR2(1000 CHAR);
        l_previous_positioning VARCHAR2(1000 CHAR);
    
        l_start_date_current epis_positioning_plan.dt_prev_plan_tstz%TYPE;
        l_start_date_prev    epis_positioning_plan.dt_prev_plan_tstz%TYPE;
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
        o_tbl_tags   := table_varchar();
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M014'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => NULL,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TITLE_NEW');
    
        --status
        IF i_actual_row.flg_status <> i_previous_row.flg_status
        THEN
            --new status           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M015'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING.FLG_STATUS',
                                                                             i_val      => i_actual_row.flg_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS_NEW');
        
            --status          
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M004'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING.FLG_STATUS',
                                                                             i_val      => i_previous_row.flg_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            l_has_differences := TRUE;
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS');
        END IF;
    
        --Positionings
        g_error := 'get position''s name of ' || i_actual_row.id_epis_positioning;
        pk_alertlog.log_debug(g_error);
        l_actual_positioning := get_positioning_concat(i_lang,
                                                       i_prof,
                                                       i_actual_row.id_epis_positioning,
                                                       i_actual_row.dt_epis_positioning);
    
        g_error := 'get position''s name of ' || i_previous_row.id_epis_positioning;
        pk_alertlog.log_debug(g_error);
        l_previous_positioning := get_positioning_concat(i_lang,
                                                         i_prof,
                                                         i_previous_row.id_epis_positioning,
                                                         i_previous_row.dt_epis_positioning);
    
        IF l_actual_positioning <> l_previous_positioning
        THEN
            --new value           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M016'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_actual_positioning,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POSITIONINGS_NEW');
        
            --previous value
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M005'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_previous_positioning,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            l_has_differences := TRUE;
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POSITIONINGS');
        END IF;
    
        --rotation
        IF i_actual_row.rot_interval <> i_previous_row.rot_interval
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M017'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => CASE
                                                         WHEN i_actual_row.rot_interval IS NOT NULL THEN
                                                         --pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(i_actual_row.rot_interval)), i_prof)
                                                          get_fomatted_rot_interv(i_lang, i_prof, i_actual_row.rot_interval)
                                                         ELSE
                                                          NULL
                                                     END,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'ROTATION_NEW');
        
            --previous value                
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M006'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => CASE
                                                         WHEN i_previous_row.rot_interval IS NOT NULL THEN
                                                          get_fomatted_rot_interv(i_lang, i_prof, i_previous_row.rot_interval)
                                                     --pk_date_utils.dt_chr_hour(i_lang, to_timestamp(pk_date_utils.g_ref_date || get_rot_interv_format(i_previous_row.rot_interval)), i_prof)
                                                         ELSE
                                                          NULL
                                                     END,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'ROTATION');
        
            l_has_differences := TRUE;
        END IF;
    
        --Massage
        IF i_actual_row.flg_massage <> i_previous_row.flg_massage
        THEN
            --new value           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M018'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(g_yes_no, i_actual_row.flg_massage, i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'MASSAGE_NEW');
        
            --previous value
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M007'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(g_yes_no,
                                                                             i_previous_row.flg_massage,
                                                                             i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'MASSAGE');
        
            l_has_differences := TRUE;
        END IF;
    
        --notes
        IF nvl(i_actual_row.notes, '-1') <> nvl(i_previous_row.notes, '-1')
        THEN
            --new value           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M019'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => nvl(i_actual_row.notes, pk_message.get_message(i_lang, 'PN_M026')),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES_NEW');
        
            --previous value
            IF (i_previous_row.notes IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => i_labels('POSITIONING_M008'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_previous_row.notes,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
                pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES');
            END IF;
        
            l_has_differences := TRUE;
        
        END IF;
    
        --START DATE
        BEGIN
            SELECT coalesce(epp.dt_prev_plan_tstz, epph.dt_prev_plan_tstz)
              INTO l_start_date_current
              FROM (SELECT ep_o.id_epis_positioning, ep_o.dt_epis_positioning
                      FROM epis_positioning ep_o
                     WHERE ep_o.id_epis_positioning = i_actual_row.id_epis_positioning
                    UNION ALL
                    SELECT ep_h.id_epis_positioning, ep_h.dt_epis_positioning
                      FROM epis_positioning_hist ep_h
                     WHERE ep_h.id_epis_positioning = i_actual_row.id_epis_positioning) ep
              JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
               AND epd.dt_epis_positioning_det = ep.dt_epis_positioning
               AND epd.rank = 1
              LEFT JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
              LEFT JOIN epis_posit_plan_hist epph
                ON epph.id_epis_positioning_det = epd.id_epis_positioning_det
             WHERE ep.id_epis_positioning = i_actual_row.id_epis_positioning
               AND ep.dt_epis_positioning = i_actual_row.dt_epis_positioning;
        EXCEPTION
            WHEN OTHERS THEN
                l_start_date_current := NULL;
        END;
    
        BEGIN
            SELECT coalesce(epp.dt_prev_plan_tstz, epph.dt_prev_plan_tstz)
              INTO l_start_date_prev
              FROM (SELECT ep_o.id_epis_positioning, ep_o.dt_epis_positioning
                      FROM epis_positioning ep_o
                     WHERE ep_o.id_epis_positioning = i_previous_row.id_epis_positioning
                    UNION ALL
                    SELECT ep_h.id_epis_positioning, ep_h.dt_epis_positioning
                      FROM epis_positioning_hist ep_h
                     WHERE ep_h.id_epis_positioning = i_previous_row.id_epis_positioning) ep
              JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
               AND epd.dt_epis_positioning_det = ep.dt_epis_positioning
               AND epd.rank = 1
              LEFT JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
              LEFT JOIN epis_posit_plan_hist epph
                ON epph.id_epis_positioning_det = epd.id_epis_positioning_det
             WHERE ep.id_epis_positioning = i_previous_row.id_epis_positioning
               AND ep.dt_epis_positioning = i_previous_row.dt_epis_positioning;
        EXCEPTION
            WHEN OTHERS THEN
                l_start_date_prev := NULL;
        END;
    
        IF l_start_date_current <> l_start_date_prev
           AND l_start_date_current IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M025'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 l_start_date_current,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'START_DATE_NEW');
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M025'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 l_start_date_prev,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'START_DATE');
            l_has_differences := TRUE;
        END IF;
    
        --Cancellation info
        IF i_actual_row.flg_status IN (g_epis_posit_c, g_epis_posit_i, g_epis_posit_f)
        THEN
            IF i_actual_row.id_cancel_reason IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => CASE
                                                             WHEN i_actual_row.flg_status = g_epis_posit_i THEN
                                                              i_labels('MED_PRESC_T088')
                                                             WHEN i_actual_row.flg_status = g_epis_posit_f THEN
                                                              i_labels('POSITIONING_M023')
                                                             ELSE
                                                              i_labels('POSITIONING_M009')
                                                         END,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                                 i_prof             => i_prof,
                                                                                                 i_id_cancel_reason => i_actual_row.id_cancel_reason),
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
                IF i_actual_row.flg_status = g_epis_posit_c
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CANCEL_REASON_NEW');
                ELSIF i_actual_row.flg_status = g_epis_posit_i
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'DISCONTINUE_REASON_NEW');
                ELSE
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CONCLUSION_REASON_NEW');
                END IF;
            
            END IF;
        
            IF i_actual_row.notes_cancel IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => CASE
                                                             WHEN i_actual_row.flg_status = g_epis_posit_f THEN
                                                              i_labels('POSITIONING_M024')
                                                             ELSE
                                                              i_labels('POSITIONING_M010')
                                                         END,
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_actual_row.notes_cancel,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
                IF i_actual_row.flg_status = g_epis_posit_c
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CANCEL_NOTES_NEW');
                ELSIF i_actual_row.flg_status = g_epis_posit_i
                THEN
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'DISCONTINUE_NOTES_NEW');
                ELSE
                    pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'CONCLUSION_NOTES_NEW');
                END IF;
            
            END IF;
        END IF;
    
        -- if there're no differences between records so is necessary to send "no difference" to detail screen
        IF (l_has_differences = FALSE)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M020'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => NULL,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        END IF;
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_actual_row.id_episode,
                                                                             i_date                => i_actual_row.dt_epis_positioning,
                                                                             i_id_prof_last_change => i_actual_row.id_professional,
                                                                             i_code_desc           => 'POSITIONING_M026'),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'SIGNATURE');
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'WHITE_LINE');
    
        RETURN TRUE;
    END get_values_req;

    /********************************************************************************************
    * Get the fields data to be shown in detail current informatio screen 
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_counter                 Counter identifier execution plan
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_first_values_plan
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_actual_row IN epis_posit_plan_hist%ROWTYPE,
        i_counter    IN NUMBER,
        i_labels     IN t_code_messages,
        i_flg_screen IN VARCHAR2,
        o_tbl_labels OUT table_varchar,
        o_tbl_values OUT table_varchar,
        o_tbl_types  OUT table_varchar,
        o_tbl_tags   OUT table_varchar
    ) RETURN BOOLEAN IS
    
        l_counter        VARCHAR2(30 CHAR);
        l_count_editions PLS_INTEGER := 0;
        l_creation_date  epis_positioning.dt_creation_tstz%TYPE;
        l_update_date    epis_positioning.dt_epis_positioning%TYPE;
    
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
        o_tbl_tags   := table_varchar();
    
        IF i_counter IS NULL
        THEN
            l_counter := NULL;
        ELSE
            l_counter := pk_string_utils.surround(i_counter, pk_string_utils.g_pattern_space_parenthesis);
        END IF;
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M011') || l_counter,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_counter,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TITLE');
    
        --status          
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M004'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                         i_val      => i_actual_row.flg_status,
                                                                         i_lang     => i_lang),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS');
    
        --change positioning
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M012'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => get_positioning_description(i_lang,
                                                                             i_prof,
                                                                             i_actual_row.id_epis_positioning_det),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_FROM');
    
        --Change for next positioning        
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M013'),
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => get_positioning_description(i_lang,
                                                                             i_prof,
                                                                             i_actual_row.id_epis_positioning_next),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_content_c);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_TO');
    
        --To be executed on
        IF i_actual_row.dt_execution_tstz IS NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M028'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_prev_plan_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TO_BE_EXECUTED');
        END IF;
    
        --Performed at
        IF i_actual_row.dt_execution_tstz IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M029'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_execution_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'PERFORMED_AT');
        END IF;
    
        -- notes        
        IF i_actual_row.notes IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M008'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => i_actual_row.notes,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES');
        
        END IF;
    
        --signature      
        --Check if there has been an update on the start date, the 1st/2nd positioniong or status  
        --The timestamp of the Execution block should only be updated if there was an update on such info
        IF i_counter = 1
        THEN
            SELECT COUNT(1)
              INTO l_count_editions
              FROM (SELECT DISTINCT t.*
                      FROM (SELECT epp.dt_prev_plan_tstz,
                                   epd.id_positioning,
                                   epd_next.id_positioning AS id_positioning_next,
                                   CASE epp.flg_status
                                       WHEN g_epis_posit_f THEN
                                        epp.flg_status
                                       WHEN g_epis_posit_d THEN
                                        epp.flg_status
                                       ELSE
                                        g_epis_posit_e
                                   END flg_status
                              FROM epis_positioning_plan epp
                              JOIN epis_positioning_det epd
                                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                               AND epd.rank = 1
                              LEFT JOIN epis_positioning_det epd_next
                                ON epd_next.id_epis_positioning_det = epp.id_epis_positioning_next
                               AND epd_next.rank = 2
                             WHERE epd.id_epis_positioning IN
                                   (SELECT id_epis_positioning
                                      FROM epis_positioning_det epdi
                                     WHERE epdi.id_epis_positioning_det = i_actual_row.id_epis_positioning_det)
                            UNION
                            SELECT epp.dt_prev_plan_tstz,
                                   epd.id_positioning,
                                   epd_next.id_positioning AS id_positioning_next,
                                   CASE epp.flg_status
                                       WHEN g_epis_posit_f THEN
                                        epp.flg_status
                                       WHEN g_epis_posit_d THEN
                                        epp.flg_status
                                       ELSE
                                        g_epis_posit_e
                                   END flg_status
                              FROM epis_posit_plan_hist epp
                              JOIN epis_positioning_det epd
                                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
                               AND epd.rank = 1
                              LEFT JOIN epis_positioning_det epd_next
                                ON epd_next.id_epis_positioning_det = epp.id_epis_positioning_next
                               AND epd_next.rank = 2
                             WHERE epd.id_epis_positioning IN
                                   (SELECT id_epis_positioning
                                      FROM epis_positioning_det epdi
                                     WHERE epdi.id_epis_positioning_det = i_actual_row.id_epis_positioning_det)) t);
        END IF;
    
        IF l_count_editions > 1
        THEN
            --If there has been an update on the start date, the 1st/2nd positioniong or the status, check the date of such update 
            SELECT MAX(tt.dt_epis_positioning_det)
              INTO l_update_date
              FROM (SELECT t.*,
                           row_number() over(PARTITION BY t.dt_prev_plan_tstz, t.id_positioning, t.id_positioning_next, t.flg_status ORDER BY t.dt_epis_positioning_det ASC) AS rn
                      FROM (SELECT epdi.id_epis_positioning,
                                   epdi.id_positioning,
                                   epdn.id_positioning AS id_positioning_next,
                                   (SELECT epp.dt_prev_plan_tstz
                                      FROM epis_positioning_plan epp
                                     WHERE epp.id_epis_positioning_det = epdi.id_epis_positioning_det
                                       AND epp.id_epis_positioning_next = epdn.id_epis_positioning_det
                                       AND epp.dt_epis_positioning_plan = epdi.dt_epis_positioning_det) AS dt_prev_plan_tstz,
                                   (SELECT CASE epp.flg_status
                                               WHEN g_epis_posit_f THEN
                                                epp.flg_status
                                               WHEN g_epis_posit_d THEN
                                                epp.flg_status
                                               ELSE
                                                g_epis_posit_e
                                           END flg_status
                                      FROM epis_positioning_plan epp
                                     WHERE epp.id_epis_positioning_det = epdi.id_epis_positioning_det
                                       AND epp.id_epis_positioning_next = epdn.id_epis_positioning_det
                                       AND epp.dt_epis_positioning_plan = epdi.dt_epis_positioning_det) AS flg_status,
                                   epdi.dt_epis_positioning_det,
                                   epdi.flg_outdated
                              FROM epis_positioning_det epdi
                              LEFT JOIN epis_positioning_det epdn
                                ON epdn.id_epis_positioning = epdi.id_epis_positioning
                               AND epdi.dt_epis_positioning_det = epdn.dt_epis_positioning_det
                               AND epdn.rank = 2
                             WHERE epdi.id_epis_positioning IN
                                   (SELECT id_epis_positioning
                                      FROM epis_positioning_det
                                     WHERE id_epis_positioning_det = i_actual_row.id_epis_positioning_det)
                               AND epdi.rank = 1) t) tt;
        
        ELSIF i_counter = 1
        THEN
            SELECT MIN(t.dt_epis_positioning_det)
              INTO l_update_date
              FROM (SELECT epd.dt_epis_positioning_det
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning IN
                           (SELECT id_epis_positioning
                              FROM epis_positioning_det
                             WHERE id_epis_positioning_det = i_actual_row.id_epis_positioning_det)
                       AND epd.rank = 1
                    UNION
                    SELECT epdh.dt_epis_positioning_det
                      FROM epis_positioning_det_hist epdh
                     WHERE epdh.id_epis_positioning IN
                           (SELECT id_epis_positioning
                              FROM epis_positioning_det
                             WHERE id_epis_positioning_det = i_actual_row.id_epis_positioning_det)
                       AND epdh.rank = 1) t;
        END IF;
    
        IF i_flg_screen = g_flg_screen_history
        THEN
            SELECT ep.dt_creation_tstz
              INTO l_creation_date
              FROM epis_positioning_det epd
              JOIN epis_positioning ep
                ON epd.id_epis_positioning = ep.id_epis_positioning
             WHERE epd.id_epis_positioning_det = i_actual_row.id_epis_positioning_det;
        END IF;
    
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_id_episode,
                                                                             i_date                => CASE
                                                                                                          WHEN i_flg_screen = g_flg_screen_detail THEN
                                                                                                           coalesce(l_update_date, i_actual_row.dt_epis_positioning_plan)
                                                                                                          ELSE
                                                                                                           i_actual_row.dt_epis_positioning_plan
                                                                                                      END,
                                                                             i_id_prof_last_change => i_actual_row.id_prof_exec,
                                                                             i_code_desc           => CASE
                                                                                                          WHEN (l_count_editions > 1 OR
                                                                                                               (i_counter > 1 AND i_actual_row.flg_status <> g_epis_posit_e) OR
                                                                                                               i_actual_row.flg_status = g_epis_posit_f)
                                                                                                               AND i_flg_screen = g_flg_screen_detail THEN
                                                                                                           'POSITIONING_M027'
                                                                                                          ELSE
                                                                                                           'POSITIONING_M026'
                                                                                                      END),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'SIGNATURE');
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'WHITE_LINE');
    
        RETURN TRUE;
    END get_first_values_plan;

    /********************************************************************************************
    * Get the fields data to be shown in the history screen related with the difference between the 
    * different steps performed by the user.
    *
    * @param       i_lang                    Language Id
    * @param       i_prof                    Professional information
    * @param       i_id_episode              Episode ID
    * @param       i_actual_row              Epis_positioning_plan data current record
    * @param       i_previous_row            Epis_positioning_plan data previous record 
    * @param       i_counter                 Counter identifier execution plan
    * @param       i_labels                  structure's labels
    *
    * @param       o_tbl_labels              Info labels used in flash to addicional formatting    
    * @param       o_tbl_values              Info values used in flash to addicional formatting
    * @param       o_tbl_types               Info values used in flash to addicional formatting types
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION get_values_plan
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_actual_row   IN epis_posit_plan_hist%ROWTYPE,
        i_previous_row IN epis_posit_plan_hist%ROWTYPE,
        i_counter      IN NUMBER,
        i_labels       IN t_code_messages,
        o_tbl_labels   OUT table_varchar,
        o_tbl_values   OUT table_varchar,
        o_tbl_types    OUT table_varchar,
        o_tbl_tags     OUT table_varchar
    ) RETURN BOOLEAN IS
        l_has_differences  BOOLEAN := FALSE;
        l_counter          VARCHAR2(30 CHAR);
        l_pos_from_prev    VARCHAR2(200);
        l_pos_from_current VARCHAR2(200);
        l_pos_to_prev      VARCHAR2(200);
        l_pos_to_current   VARCHAR2(200);
    BEGIN
        o_tbl_labels := table_varchar();
        o_tbl_values := table_varchar();
        o_tbl_types  := table_varchar();
        o_tbl_tags   := table_varchar();
    
        IF i_counter IS NULL
        THEN
            l_counter := NULL;
        ELSE
            l_counter := pk_string_utils.surround(i_counter, pk_string_utils.g_pattern_space_parenthesis);
        END IF;
    
        --title
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => i_labels('POSITIONING_M022') || l_counter,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => l_counter,
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_title_t);
    
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TITLE_NEW');
    
        --status 
        IF i_actual_row.flg_status <> i_previous_row.flg_status
        THEN
            --new status           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M015'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                             i_val      => i_actual_row.flg_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS_NEW');
        
            --status          
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M004'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_sysdomain.get_domain(i_code_dom => 'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                             i_val      => i_previous_row.flg_status,
                                                                             i_lang     => i_lang),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            l_has_differences := TRUE;
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'STATUS');
        END IF;
    
        --change positioning
        l_pos_from_current := get_positioning_description(i_lang, i_prof, i_actual_row.id_epis_positioning_det);
    
        l_pos_from_prev := get_positioning_description(i_lang, i_prof, i_previous_row.id_epis_positioning_det);
    
        IF l_pos_from_current <> l_pos_from_prev
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M032'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_pos_from_current,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_FROM_NEW');
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M012'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_pos_from_prev,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_FROM');
        
            l_has_differences := TRUE;
        END IF;
    
        --Change for next positioning 
        l_pos_to_current := get_positioning_description(i_lang, i_prof, i_actual_row.id_epis_positioning_next);
    
        l_pos_to_prev := get_positioning_description(i_lang, i_prof, i_previous_row.id_epis_positioning_next);
    
        IF l_pos_to_current <> l_pos_to_prev
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M033'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_pos_to_current,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_TO_NEW');
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M013'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => l_pos_to_prev,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'POS_TO');
        
            l_has_differences := TRUE;
        END IF;
    
        --notes
        IF nvl(i_actual_row.notes, '-1') <> nvl(i_previous_row.notes, '-1')
        THEN
            --new value           
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M019'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => nvl(i_actual_row.notes, i_labels('COMMON_M106')),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_new_content_n);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES_NEW');
        
            --previous value
            IF (i_previous_row.notes IS NOT NULL)
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => i_labels('POSITIONING_M008'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_previous_row.notes,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
                pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'NOTES');
            END IF;
        
            l_has_differences := TRUE;
        END IF;
    
        --Cancellation info
        IF i_actual_row.flg_status IN (g_epis_posit_c)
        THEN
            IF i_actual_row.notes IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => i_labels('POSITIONING_M010'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_actual_row.notes,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
            END IF;
        
            --Cancellation info
        ELSIF i_actual_row.flg_status IN (g_epis_posit_i)
        THEN
        
            IF i_actual_row.notes IS NOT NULL
            THEN
                pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                           i_value_1  => i_labels('POSITIONING_M021'),
                                           io_table_2 => o_tbl_values,
                                           i_value_2  => i_actual_row.notes,
                                           io_table_3 => o_tbl_types,
                                           i_value_3  => pk_inp_detail.g_content_c);
            
            END IF;
        END IF;
    
        --To be executed on
        IF (i_previous_row.dt_prev_plan_tstz <> i_actual_row.dt_prev_plan_tstz)
           AND i_actual_row.flg_status <> 'F'
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M031'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_prev_plan_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TO_BE_EXECUTED_NEW');
        
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M028'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_previous_row.dt_prev_plan_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'TO_BE_EXECUTED');
        
            l_has_differences := TRUE;
        END IF;
    
        --Performed at
        IF i_actual_row.dt_execution_tstz IS NOT NULL
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M030'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => pk_date_utils.date_char_tsz(i_lang,
                                                                                 i_actual_row.dt_execution_tstz,
                                                                                 i_prof.institution,
                                                                                 i_prof.software),
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        
            pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'PERFORMED_AT_NEW');
        END IF;
    
        -- if there're no differences between records so is necessary to send "no difference" to detail screen
        IF (l_has_differences = FALSE)
        THEN
            pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                       i_value_1  => i_labels('POSITIONING_M020'),
                                       io_table_2 => o_tbl_values,
                                       i_value_2  => NULL,
                                       io_table_3 => o_tbl_types,
                                       i_value_3  => pk_inp_detail.g_content_c);
        END IF;
    
        --signature
        pk_inp_detail.add_3_values(io_table_1 => o_tbl_labels,
                                   i_value_1  => NULL,
                                   io_table_2 => o_tbl_values,
                                   i_value_2  => pk_inp_detail.get_signature(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_episode          => i_id_episode,
                                                                             i_date                => i_actual_row.dt_epis_positioning_plan,
                                                                             i_id_prof_last_change => i_actual_row.id_prof_exec,
                                                                             i_code_desc           => 'POSITIONING_M026'),
                                   io_table_3 => o_tbl_types,
                                   i_value_3  => pk_inp_detail.g_signature_s);
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'SIGNATURE');
        pk_inp_detail.add_value(io_table => o_tbl_tags, i_value => 'WHITE_LINE');
        RETURN TRUE;
    END get_values_plan;

    /*********************************************************************************************
    * Saves the current state of a epis_positioning_plan record to the history table.
    * 
    * @param    i_lang                                  Language ID
    * @param    i_prof                                  Professional
    * @param    i_id_epis_positioning_plan              Table number with Epis positioning_plan ID
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/13
    **********************************************************************************************/

    FUNCTION set_epis_posit_plan_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_epis_positioning_plan IN table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name           VARCHAR2(30 CHAR) := 'SET_EPIS_POSIT_PLAN_HIST';
        l_id_epis_posit_plan_hist epis_posit_plan_hist.id_epis_posit_plan_hist%TYPE;
        r_epis_posit_plan         epis_positioning_plan%ROWTYPE;
        l_rows                    table_varchar;
    
    BEGIN
    
        IF i_id_epis_positioning_plan IS NOT NULL
           AND i_id_epis_positioning_plan.count > 0
        THEN
        
            FOR i IN 1 .. i_id_epis_positioning_plan.count
            LOOP
            
                SELECT epp.*
                  INTO r_epis_posit_plan
                  FROM epis_positioning_plan epp
                 WHERE epp.id_epis_positioning_plan = i_id_epis_positioning_plan(i);
            
                l_id_epis_posit_plan_hist := ts_epis_posit_plan_hist.next_key;
            
                ts_epis_posit_plan_hist.ins(id_epis_posit_plan_hist_in  => l_id_epis_posit_plan_hist,
                                            id_epis_positioning_plan_in => r_epis_posit_plan.id_epis_positioning_plan,
                                            id_epis_positioning_det_in  => r_epis_posit_plan.id_epis_positioning_det,
                                            id_epis_positioning_next_in => r_epis_posit_plan.id_epis_positioning_next,
                                            id_prof_exec_in             => r_epis_posit_plan.id_prof_exec,
                                            flg_status_in               => r_epis_posit_plan.flg_status,
                                            notes_in                    => r_epis_posit_plan.notes,
                                            dt_execution_tstz_in        => r_epis_posit_plan.dt_execution_tstz,
                                            dt_prev_plan_tstz_in        => r_epis_posit_plan.dt_prev_plan_tstz,
                                            dt_epis_positioning_plan_in => r_epis_posit_plan.dt_epis_positioning_plan,
                                            rows_out                    => l_rows);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR EPIS_POSIT_PLAN_HIST TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSIT_PLAN_HIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END LOOP;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_epis_posit_plan_hist;

    /********************************************************************************************
    * Get the positioning plan detail and history data.
    *
    * @param   I_LANG                      language associated to the professional executing the request
    * @param   i_prof                      professional
    * @param   i_id_epis_positioning_plan  Epis_positioning_plan Id
    * @param   i_flg_screen                D-detail; H-history    
    * @param   o_data                      Output data    
    * @param   o_error                     Error message
    *                        
    * @return  true or false on success or error
    * 
    * @author                         Filipe Silva
    * @version                        2.6.1
    * @since                          13-Apr-2011
    **********************************************************************************************/
    FUNCTION get_epis_positioning_plan_hist
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_limit             PLS_INTEGER := 1000;
        l_tbl_lables        table_varchar := table_varchar();
        l_tbl_values        table_varchar := table_varchar();
        l_tbl_types         table_varchar := table_varchar();
        l_tab_hist          t_table_history_data := t_table_history_data();
        l_func_name         VARCHAR2(30 CHAR) := 'GET_EPIS_POSITIONING_PLAN_HIST';
        l_inp_code_messages t_code_messages;
    
        l_inp_posit_code_messages table_varchar2 := table_varchar2('POSITIONING_T029',
                                                                   'POSITIONING_T030',
                                                                   'POSITIONING_T023',
                                                                   'POSITIONING_T024',
                                                                   'COMMON_M107',
                                                                   'POSITIONING_T025',
                                                                   'COMMON_M108',
                                                                   'POSITIONING_T026',
                                                                   'POSITIONING_T027',
                                                                   'POSITIONING_T028',
                                                                   'POSITIONING_M003',
                                                                   'POSITIONING_M004',
                                                                   'POSITIONING_M005',
                                                                   'POSITIONING_M006',
                                                                   'POSITIONING_M007',
                                                                   'POSITIONING_M008',
                                                                   'POSITIONING_M009',
                                                                   'POSITIONING_M010',
                                                                   'POSITIONING_M011',
                                                                   'POSITIONING_M012',
                                                                   'POSITIONING_M013',
                                                                   'POSITIONING_M014',
                                                                   'POSITIONING_M015',
                                                                   'POSITIONING_M016',
                                                                   'POSITIONING_M017',
                                                                   'POSITIONING_M018',
                                                                   'POSITIONING_M019',
                                                                   'POSITIONING_M020',
                                                                   'COMMON_M106',
                                                                   'POSITIONING_M021',
                                                                   'POSITIONING_M022');
    
        CURSOR c_get_positioning_plan IS
            SELECT *
              FROM (SELECT NULL id_epis_posit_plan_hist, epp.*
                      FROM epis_positioning_plan epp
                     WHERE epp.id_epis_positioning_plan = i_id_epis_positioning_plan
                       AND epp.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
                    UNION ALL
                    SELECT epph.*
                      FROM epis_posit_plan_hist epph
                     WHERE epph.id_epis_positioning_plan = i_id_epis_positioning_plan
                       AND epph.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
                       AND i_flg_screen = pk_inp_detail.g_history_h) t
             ORDER BY dt_epis_positioning_plan DESC;
    
        TYPE c_positioning_plan IS TABLE OF c_get_positioning_plan%ROWTYPE;
        l_positioning_plan  c_positioning_plan;
        l_posit_plan_struct c_positioning_plan := c_positioning_plan();
        l_tbl_tags          table_varchar;
    
    BEGIN
    
        -- fill all translations in collection
        FOR i IN l_inp_posit_code_messages.first .. l_inp_posit_code_messages.last
        LOOP
            l_inp_code_messages(l_inp_posit_code_messages(i)) := pk_message.get_message(i_lang,
                                                                                        l_inp_posit_code_messages(i));
        END LOOP;
    
        -- get positionings plan records
        OPEN c_get_positioning_plan;
        LOOP
            FETCH c_get_positioning_plan BULK COLLECT
                INTO l_positioning_plan LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_plan.count
            LOOP
                l_posit_plan_struct.extend;
                l_posit_plan_struct(l_posit_plan_struct.count) := l_positioning_plan(i);
            
            END LOOP;
        
            EXIT WHEN c_get_positioning_plan%NOTFOUND;
        END LOOP;
    
        FOR c IN 1 .. l_posit_plan_struct.count
        LOOP
            --last record doesn't need to be compared  
            IF (c = l_posit_plan_struct.count)
            THEN
            
                IF NOT get_first_values_plan(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_actual_row => l_posit_plan_struct(c),
                                             i_counter    => NULL,
                                             i_labels     => l_inp_code_messages,
                                             i_flg_screen => i_flg_screen,
                                             o_tbl_labels => l_tbl_lables,
                                             o_tbl_values => l_tbl_values,
                                             o_tbl_types  => l_tbl_types,
                                             o_tbl_tags   => l_tbl_tags)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                --compare current record with the next record to check what's differences between them
                IF NOT get_values_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_episode   => i_id_episode,
                                       i_actual_row   => l_posit_plan_struct(c),
                                       i_previous_row => l_posit_plan_struct(c + 1),
                                       i_counter      => NULL,
                                       i_labels       => l_inp_code_messages,
                                       o_tbl_labels   => l_tbl_lables,
                                       o_tbl_values   => l_tbl_values,
                                       o_tbl_types    => l_tbl_types,
                                       o_tbl_tags     => l_tbl_tags)
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
            l_tab_hist.extend;
            l_tab_hist(l_tab_hist.count) := t_rec_history_data(id_rec          => l_posit_plan_struct(c).id_epis_positioning_plan,
                                                               flg_status      => l_posit_plan_struct(c).flg_status,
                                                               date_rec        => l_posit_plan_struct(c).dt_epis_positioning_plan,
                                                               tbl_labels      => l_tbl_lables,
                                                               tbl_values      => l_tbl_values,
                                                               tbl_types       => l_tbl_types,
                                                               tbl_info_labels => pk_inp_detail.get_info_labels,
                                                               tbl_info_values => pk_inp_detail.get_info_values(l_posit_plan_struct(c).flg_status),
                                                               table_origin    => NULL);
        
        END LOOP;
    
        g_error := 'OPEN o_hist';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_hist FOR
            SELECT t.id_rec          id_epis_positioning,
                   t.tbl_labels      tbl_labels,
                   t.tbl_values      tbl_values,
                   t.tbl_types       tbl_types,
                   t.tbl_info_labels info_labels,
                   t.tbl_info_values info_values
              FROM TABLE(l_tab_hist) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_positioning_plan_hist;

    FUNCTION get_epis_posit_plan_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_epis_positioning_plan IN epis_positioning_plan.id_epis_positioning_plan%TYPE,
        i_flg_screen               IN VARCHAR2,
        o_hist                     OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         VARCHAR2(30) := 'GET_EPIS_POSIT_PLAN_DETAIL';
        l_limit             PLS_INTEGER := 1000;
        l_tbl_lables        table_varchar := table_varchar();
        l_tbl_values        table_varchar := table_varchar();
        l_tbl_types         table_varchar := table_varchar();
        l_tbl_tbl_tags_exec table_table_varchar := table_table_varchar();
        l_tbl_tags_exec     table_varchar := table_varchar();
        l_tab_hist_exec     t_table_history_data := t_table_history_data();
        ---
        l_exec_data           t_table_history_data := t_table_history_data();
        l_tbl_values_aux_exec table_varchar := table_varchar();
        l_previous_size       NUMBER := 0;
        l_tbl_count           table_number := table_number();
        l_tbl_exec_id         table_number := table_number();
        --
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_inp_code_messages       t_code_messages;
        l_inp_posit_code_messages table_varchar2 := table_varchar2('POSITIONING_T029',
                                                                   'POSITIONING_T030',
                                                                   'POSITIONING_T023',
                                                                   'POSITIONING_T024',
                                                                   'COMMON_M107',
                                                                   'POSITIONING_T025',
                                                                   'COMMON_M108',
                                                                   'POSITIONING_T026',
                                                                   'POSITIONING_T027',
                                                                   'POSITIONING_T028',
                                                                   'POSITIONING_M003',
                                                                   'POSITIONING_M004',
                                                                   'POSITIONING_M005',
                                                                   'POSITIONING_M006',
                                                                   'POSITIONING_M007',
                                                                   'POSITIONING_M008',
                                                                   'POSITIONING_M009',
                                                                   'POSITIONING_M010',
                                                                   'POSITIONING_M011',
                                                                   'POSITIONING_M012',
                                                                   'POSITIONING_M013',
                                                                   'POSITIONING_M014',
                                                                   'POSITIONING_M015',
                                                                   'POSITIONING_M016',
                                                                   'POSITIONING_M017',
                                                                   'POSITIONING_M018',
                                                                   'POSITIONING_M019',
                                                                   'POSITIONING_M020',
                                                                   'COMMON_M108',
                                                                   'COMMON_M106',
                                                                   'POSITIONING_M021',
                                                                   'POSITIONING_M022',
                                                                   'MED_PRESC_T088',
                                                                   'POSITIONING_M023',
                                                                   'POSITIONING_M024',
                                                                   'POSITIONING_M025',
                                                                   'POSITIONING_M028',
                                                                   'POSITIONING_M029',
                                                                   'POSITIONING_M030',
                                                                   'POSITIONING_M031',
                                                                   'POSITIONING_M032',
                                                                   'POSITIONING_M033');
    
        CURSOR c_get_positionings_plan IS
            SELECT *
              FROM (WITH aux_det AS (SELECT epd.id_epis_positioning_det
                                       FROM epis_positioning_det epd
                                       JOIN (SELECT epd.id_epis_positioning, rank
                                              FROM epis_positioning_det epd
                                              JOIN epis_positioning_plan epp
                                                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                                             WHERE epp.id_epis_positioning_plan = i_id_epis_positioning_plan) t
                                         ON t.id_epis_positioning = epd.id_epis_positioning
                                        AND t.rank = epd.rank)
                       SELECT NULL AS id_epis_posit_plan_hist, epp.*
                         FROM epis_positioning_det epd
                        INNER JOIN aux_det ad
                           ON ad.id_epis_positioning_det = epd.id_epis_positioning_det
                        INNER JOIN epis_positioning_plan epp
                           ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                          AND epp.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l, g_epis_posit_o)
                          AND i_flg_screen = g_flg_screen_detail
                       UNION
                       SELECT -1 id_epis_posit_plan_hist, ttt.*
                         FROM (SELECT coalesce(epp.id_epis_positioning_plan, epph.id_epis_positioning_plan) id_epis_positioning_plan,
                                      coalesce(epp.id_epis_positioning_det, epph.id_epis_positioning_det) id_epis_positioning_det,
                                      coalesce(epp.id_epis_positioning_next, epph.id_epis_positioning_next) id_epis_positioning_next,
                                      coalesce(epp.id_prof_exec, epph.id_prof_exec) id_prof_exec,
                                      CASE epp.flg_status
                                          WHEN g_epis_posit_o THEN
                                           g_epis_posit_e
                                          ELSE
                                           coalesce(epp.flg_status, epph.flg_status)
                                      END flg_status,
                                      epp.notes,
                                      coalesce(epp.dt_execution_tstz, epph.dt_execution_tstz) dt_execution_tstz,
                                      coalesce(epp.dt_prev_plan_tstz, epph.dt_prev_plan_tstz) dt_prev_plan_tstz,
                                      epp.create_user,
                                      epp.create_time,
                                      epp.create_institution,
                                      epp.update_user,
                                      epp.update_time,
                                      epp.update_institution,
                                      coalesce(epp.dt_epis_positioning_plan, epph.dt_epis_positioning_plan) dt_epis_positioning_plan
                                 FROM (SELECT t.*,
                                              row_number() over(PARTITION BY t.dt_prev_plan_tstz, t.id_positioning, t.id_positioning_next, t.flg_status ORDER BY t.dt_epis_positioning_plan ASC) AS rn
                                         FROM (SELECT DISTINCT l.*
                                                 FROM (SELECT (SELECT epd.id_positioning
                                                                 FROM epis_positioning_det epd
                                                                WHERE epd.id_epis_positioning_det = p.id_epis_positioning_det) AS id_positioning,
                                                              (SELECT epd.id_positioning
                                                                 FROM epis_positioning_det epd
                                                                WHERE epd.id_epis_positioning_det =
                                                                      p.id_epis_positioning_next) AS id_positioning_next,
                                                              p.dt_prev_plan_tstz,
                                                              p.dt_execution_tstz,
                                                              CASE
                                                                   WHEN p.flg_status = g_epis_posit_o THEN
                                                                    g_epis_posit_e
                                                                   ELSE
                                                                    p.flg_status
                                                               END flg_status,
                                                              p.dt_epis_positioning_plan
                                                         FROM epis_positioning_plan p
                                                         JOIN epis_positioning_det epd
                                                           ON p.id_epis_positioning_det = epd.id_epis_positioning_det
                                                        INNER JOIN aux_det ad
                                                           ON ad.id_epis_positioning_det = epd.id_epis_positioning_det
                                                        WHERE p.flg_status <> g_epis_posit_o
                                                       UNION
                                                       SELECT (SELECT epd.id_positioning
                                                                 FROM epis_positioning_det epd
                                                                WHERE epd.id_epis_positioning_det =
                                                                      eph.id_epis_positioning_det) AS id_positioning,
                                                              (SELECT epd.id_positioning
                                                                 FROM epis_positioning_det epd
                                                                WHERE epd.id_epis_positioning_det =
                                                                      eph.id_epis_positioning_next) AS id_positioning_next,
                                                              eph.dt_prev_plan_tstz,
                                                              eph.dt_execution_tstz,
                                                              CASE
                                                                  WHEN eph.flg_status = g_epis_posit_o THEN
                                                                   g_epis_posit_e
                                                                  ELSE
                                                                   eph.flg_status
                                                              END flg_status,
                                                              eph.dt_epis_positioning_plan
                                                         FROM epis_posit_plan_hist eph
                                                         JOIN epis_positioning_det epd
                                                           ON eph.id_epis_positioning_det = epd.id_epis_positioning_det
                                                        INNER JOIN aux_det ad
                                                           ON ad.id_epis_positioning_det = epd.id_epis_positioning_det
                                                        WHERE eph.flg_status <> g_epis_posit_o) l) t) tt
                                 LEFT JOIN epis_positioning_plan epp
                                   ON epp.dt_epis_positioning_plan = tt.dt_epis_positioning_plan
                                  AND epp.dt_prev_plan_tstz = tt.dt_prev_plan_tstz
                                  AND (epp.dt_execution_tstz = tt.dt_execution_tstz OR
                                      (epp.dt_execution_tstz IS NULL AND tt.dt_execution_tstz IS NULL))
                                  AND id_epis_positioning_det IN (SELECT id_epis_positioning_det
                                                                    FROM aux_det)
                                 LEFT JOIN epis_posit_plan_hist epph
                                   ON epph.dt_epis_positioning_plan = tt.dt_epis_positioning_plan
                                  AND epph.dt_prev_plan_tstz = tt.dt_prev_plan_tstz
                                  AND (epph.dt_execution_tstz = tt.dt_execution_tstz OR
                                      (epph.dt_execution_tstz IS NULL AND tt.dt_execution_tstz IS NULL))
                                  AND epph.id_epis_positioning_det IN (SELECT id_epis_positioning_det
                                                                         FROM aux_det)
                                WHERE tt.rn = 1
                                  AND i_flg_screen = pk_inp_detail.g_history_h) ttt)
                        ORDER BY dt_epis_positioning_plan, id_epis_positioning_plan;
    
    
        TYPE c_positioning_plan IS TABLE OF c_get_positionings_plan%ROWTYPE;
        l_positioning_plan  c_positioning_plan;
        l_posit_plan_struct c_positioning_plan := c_positioning_plan();
    
    BEGIN
        -- fill all translations in collection
        FOR i IN l_inp_posit_code_messages.first .. l_inp_posit_code_messages.last
        LOOP
            l_inp_code_messages(l_inp_posit_code_messages(i)) := pk_message.get_message(i_lang,
                                                                                        l_inp_posit_code_messages(i));
        END LOOP;
    
        -- get positionings plan records
        OPEN c_get_positionings_plan;
        LOOP
            FETCH c_get_positionings_plan BULK COLLECT
                INTO l_positioning_plan LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_plan.count
            LOOP
                l_posit_plan_struct.extend;
                l_posit_plan_struct(l_posit_plan_struct.count) := l_positioning_plan(i);
            END LOOP;
            EXIT WHEN c_get_positionings_plan%NOTFOUND;
        END LOOP;
    
        FOR j IN REVERSE 1 .. l_posit_plan_struct.count
        LOOP
        
            --in case is the first record or the current record is different the previous record so isn't necessary
            -- to compare these records
            l_tbl_tbl_tags_exec.extend();
            IF j = 1
            THEN
                IF NOT get_first_values_plan(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_actual_row => l_posit_plan_struct(j),
                                             i_counter    => NULL,
                                             i_labels     => l_inp_code_messages,
                                             i_flg_screen => i_flg_screen,
                                             o_tbl_labels => l_tbl_lables,
                                             o_tbl_values => l_tbl_values,
                                             o_tbl_types  => l_tbl_types,
                                             o_tbl_tags   => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
            
                --compare current record with the previous record to check what's differences between them
                IF NOT get_values_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_episode   => i_id_episode,
                                       i_actual_row   => l_posit_plan_struct(j),
                                       i_previous_row => l_posit_plan_struct(j - 1),
                                       i_counter      => NULL,
                                       i_labels       => l_inp_code_messages,
                                       o_tbl_labels   => l_tbl_lables,
                                       o_tbl_values   => l_tbl_values,
                                       o_tbl_types    => l_tbl_types,
                                       o_tbl_tags     => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        
            l_tab_hist_exec.extend;
            l_tab_hist_exec(l_tab_hist_exec.count) := t_rec_history_data(id_rec          => CASE
                                                                                                WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                                 l_posit_plan_struct(j).id_epis_positioning_plan
                                                                                                ELSE
                                                                                                 l_posit_plan_struct(j).id_epis_posit_plan_hist
                                                                                            END,
                                                                         flg_status      => l_posit_plan_struct(j).flg_status,
                                                                         date_rec        => l_posit_plan_struct(j).dt_epis_positioning_plan,
                                                                         tbl_labels      => l_tbl_lables,
                                                                         tbl_values      => l_tbl_values,
                                                                         tbl_types       => l_tbl_types,
                                                                         tbl_info_labels => pk_inp_detail.get_info_labels,
                                                                         tbl_info_values => pk_inp_detail.get_info_values(l_posit_plan_struct(j).flg_status),
                                                                         table_origin    => NULL);
        END LOOP;
    
        --OBTAINING EXECUTION DATA
        FOR i IN l_tab_hist_exec.first .. l_tab_hist_exec.last
        LOOP
        
            l_exec_data.extend();
            l_exec_data(l_exec_data.count) := l_tab_hist_exec(i);
        
            l_tbl_values_aux_exec.extend(l_tab_hist_exec(i).tbl_values.count);
        
            FOR j IN 1 .. l_tab_hist_exec(i).tbl_values.count
            LOOP
                l_tbl_values_aux_exec(l_previous_size + j) := l_exec_data(l_exec_data.count).tbl_values(j);
                l_tbl_exec_id.extend();
                l_tbl_exec_id(l_tbl_exec_id.count) := i - 1;
            END LOOP;
            l_tbl_values_aux_exec.extend(); --WHITE_LINE   
            l_tbl_exec_id.extend(); --WHITE_LINE                   
            --    
            l_previous_size := l_previous_size + l_tab_hist_exec(i).tbl_values.count + 1; --+1 FOR WHITE_LINE
            l_tbl_count.extend();
            l_tbl_count(l_tbl_count.count) := l_tab_hist_exec(i).tbl_values.count;
        
        END LOOP;
    
        FOR i IN l_tbl_tbl_tags_exec.first .. l_tbl_tbl_tags_exec.last
        LOOP
            FOR j IN l_tbl_tbl_tags_exec(i).first .. l_tbl_tbl_tags_exec(i).last
            LOOP
                l_tbl_tags_exec.extend();
                l_tbl_tags_exec(l_tbl_tags_exec.count) := l_tbl_tbl_tags_exec(i) (j);
            END LOOP;
        END LOOP;
    
        IF i_flg_screen = g_flg_screen_detail
        THEN
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       id_block || exec_id || ddb.rank,
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_dd_block_data
              FROM (SELECT tt.id_block,
                           tags.column_value AS data_source,
                           tt.column_value   AS data_source_val,
                           rownum            AS exec_id
                      FROM (SELECT t.column_value, rownum AS rn, 2 AS id_block
                              FROM TABLE(l_tbl_values_aux_exec) t) tt
                      JOIN (SELECT column_value, rownum AS rn
                             FROM TABLE(l_tbl_tags_exec)) tags
                        ON tags.rn = tt.rn
                      JOIN (SELECT column_value, rownum AS rn
                             FROM TABLE(l_tbl_exec_id)) t_exec_id
                        ON t_exec_id.rn = tt.rn) dd
              JOIN dd_content ddc
                ON ddc.area = 'POSITIONING'
               AND ddc.data_source = dd.data_source
               AND ddc.id_dd_block = dd.id_block
               AND ddc.flg_available = pk_alert_constant.g_yes
              LEFT JOIN dd_block ddb
                ON ddb.id_dd_block = ddc.id_dd_block
               AND ddb.area = 'POSITIONING'
               AND ddb.flg_available = pk_alert_constant.g_yes
             ORDER BY id_block, exec_id, ddb.rank;
        
            SELECT t_rec_dd_data(CASE
                                      WHEN data_code_message IS NOT NULL THEN
                                       pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                      ELSE
                                       NULL
                                  END, --DESCR
                                  data_source_val, --val
                                  flg_type,
                                  flg_html,
                                  NULL,
                                  flg_clob), --TYPE
                   data_source
              BULK COLLECT
              INTO l_tab_dd_data, l_data_source_list
              FROM (SELECT ddc.data_code_message,
                           flg_type,
                           data_source_val,
                           ddc.data_source,
                           db.rnk,
                           rank,
                           flg_html,
                           flg_clob
                      FROM TABLE(l_tab_dd_block_data) db
                      JOIN dd_content ddc
                        ON ddc.area = 'POSITIONING'
                       AND ddc.data_source = db.data_source
                       AND ddc.id_dd_block = db.id_dd_block
                       AND ddc.flg_available = pk_alert_constant.g_yes
                       AND (db.data_source_val IS NOT NULL OR (flg_type IN ('L1', 'WL'))))
             ORDER BY rnk, rank;
        
            g_error := 'OPEN o_hist';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            OPEN o_hist FOR
                SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
                  FROM (SELECT CASE
                                    WHEN d.val IS NULL THEN
                                     d.descr
                                    WHEN d.descr IS NULL THEN
                                     NULL
                                    WHEN d.flg_type = 'L1' THEN
                                     d.descr || d.val
                                    ELSE
                                     d.descr || ': '
                                END descr,
                               CASE
                                    WHEN d.flg_type = 'L1' THEN
                                     NULL
                                    ELSE
                                     d.val
                                END val,
                               d.flg_type,
                               d.flg_html,
                               d.val_clob,
                               d.flg_clob,
                               d.rn
                          FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                                  FROM TABLE(l_tab_dd_data)) d
                          JOIN (SELECT rownum rn, column_value data_source
                                 FROM TABLE(l_data_source_list)) ds
                            ON ds.rn = d.rn)
                 ORDER BY rn;
        
        ELSE
        
            SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                       id_block || exec_id || rn_req || ddb.rank,
                                       NULL,
                                       NULL,
                                       ddb.condition_val,
                                       NULL,
                                       NULL,
                                       dd.data_source,
                                       dd.data_source_val,
                                       NULL)
              BULK COLLECT
              INTO l_tab_dd_block_data
              FROM (SELECT tt.id_block,
                           tags.column_value AS data_source,
                           tt.column_value   AS data_source_val,
                           rownum            AS exec_id,
                           tt.rn             AS rn_req
                      FROM (SELECT t.column_value, rownum AS rn, 2 AS id_block
                              FROM TABLE(l_tbl_values_aux_exec) t) tt
                      JOIN (SELECT column_value, rownum AS rn
                             FROM TABLE(l_tbl_tags_exec)) tags
                        ON tags.rn = tt.rn
                      JOIN (SELECT column_value, rownum AS rn
                             FROM TABLE(l_tbl_exec_id)) t_exec_id
                        ON t_exec_id.rn = tt.rn) dd
              JOIN dd_content ddc
                ON ddc.area = 'POSITIONING'
               AND ddc.data_source = dd.data_source
               AND ddc.id_dd_block = dd.id_block
               AND ddc.flg_available = pk_alert_constant.g_yes
              LEFT JOIN dd_block ddb
                ON ddb.id_dd_block = ddc.id_dd_block
               AND ddb.area = 'POSITIONING'
               AND ddb.flg_available = pk_alert_constant.g_yes;
        
            SELECT t_rec_dd_data(CASE
                                      WHEN data_code_message IS NOT NULL THEN
                                       pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                      ELSE
                                       NULL
                                  END, --DESCR
                                  data_source_val, --val
                                  flg_type,
                                  flg_html,
                                  NULL,
                                  flg_clob), --TYPE
                   data_source
              BULK COLLECT
              INTO l_tab_dd_data, l_data_source_list
              FROM (SELECT ddc.data_code_message,
                           flg_type,
                           data_source_val,
                           ddc.data_source,
                           db.rnk,
                           rank,
                           flg_html,
                           NULL,
                           flg_clob
                      FROM TABLE(l_tab_dd_block_data) db
                      JOIN dd_content ddc
                        ON ddc.area = 'POSITIONING'
                       AND ddc.data_source = db.data_source
                       AND ddc.id_dd_block = db.id_dd_block
                       AND ddc.flg_available = pk_alert_constant.g_yes
                       AND (db.data_source_val IS NOT NULL OR (flg_type IN ('L1', 'WL'))))
             ORDER BY rnk, rank;
        
            g_error := 'OPEN o_hist';
            alertlog.pk_alertlog.log_info(text            => g_error,
                                          object_name     => g_package_name,
                                          sub_object_name => l_func_name);
        
            OPEN o_hist FOR
                SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
                  FROM (SELECT CASE
                                    WHEN d.val IS NULL THEN
                                     d.descr
                                    WHEN d.descr IS NULL THEN
                                     NULL
                                    WHEN d.flg_type = 'L1' THEN
                                     d.descr || d.val
                                    ELSE
                                     d.descr || ': '
                                END descr,
                               CASE
                                    WHEN d.flg_type = 'L1' THEN
                                     NULL
                                    ELSE
                                     d.val
                                END val,
                               d.flg_type,
                               flg_html,
                               val_clob,
                               flg_clob,
                               d.rn
                          FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                                  FROM TABLE(l_tab_dd_data)) d
                          JOIN (SELECT rownum rn, column_value data_source
                                 FROM TABLE(l_data_source_list)) ds
                            ON ds.rn = d.rn)
                 ORDER BY rn;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_posit_plan_detail;

    /*********************************************************************************************
    * Saves the current state of a epis_positioning_det record to the history table.
    * 
    * @param    i_lang                                  Language ID
    * @param    i_prof                                  Professional
    * @param    i_id_epis_positioning_det               Table number with Epis positioning_det ID
    *    
    * @author              Filipe Silva
    * @version             2.6.1
    * @since               2011/04/15
    **********************************************************************************************/

    FUNCTION set_epis_posit_det_hist
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning_det IN table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name          VARCHAR2(30 CHAR) := 'SET_EPIS_POSIT_DET_HIST';
        l_id_epis_posit_det_hist epis_positioning_det_hist.id_epis_posit_det_hist%TYPE;
        r_epis_posit_det         epis_positioning_det%ROWTYPE;
        l_rows                   table_varchar;
    
    BEGIN
    
        IF i_id_epis_positioning_det IS NOT NULL
           AND i_id_epis_positioning_det.count > 0
        THEN
        
            FOR i IN 1 .. i_id_epis_positioning_det.count
            LOOP
                SELECT epd.*
                  INTO r_epis_posit_det
                  FROM epis_positioning_det epd
                 WHERE epd.id_epis_positioning_det = i_id_epis_positioning_det(i)
                   AND epd.flg_outdated = pk_alert_constant.g_no;
            
                l_id_epis_posit_det_hist := ts_epis_positioning_det_hist.next_key;
            
                ts_epis_positioning_det_hist.ins(id_epis_posit_det_hist_in  => l_id_epis_posit_det_hist,
                                                 id_epis_positioning_det_in => r_epis_posit_det.id_epis_positioning_det,
                                                 id_epis_positioning_in     => r_epis_posit_det.id_epis_positioning,
                                                 id_positioning_in          => r_epis_posit_det.id_positioning,
                                                 rank_in                    => r_epis_posit_det.rank,
                                                 id_prof_last_upd_in        => r_epis_posit_det.id_prof_last_upd,
                                                 dt_epis_positioning_det_in => r_epis_posit_det.dt_epis_positioning_det,
                                                 rows_out                   => l_rows);
            
                g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR EPIS_POSITIONING_DET_HIST TABLE';
                pk_alertlog.log_debug(g_error);
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'EPIS_POSITIONING_DET_HIST',
                                              i_rowids     => l_rows,
                                              o_error      => o_error);
            
            END LOOP;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_epis_posit_det_hist;

    /********************************************************************************************
    * Sets an id_epis_positioning interrupt, cancelled or cancelled drafts.
    * This function was merged : set_posit_cancel and set_posit_interrupt
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_epis_pos                epis_positioning id
    * @param       i_flg_status              Flag status
    * @param       i_notes                   Status change notes
    * @param       i_id_cancel_reason        Cancel reason ID
    *
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/18       
    ********************************************************************************************/
    FUNCTION set_cancel_interrupt_posit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pos         IN epis_positioning.id_epis_positioning%TYPE,
        i_flg_status       IN epis_positioning.flg_status%TYPE,
        i_notes            IN epis_positioning.notes%TYPE,
        i_id_cancel_reason IN epis_positioning.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_epis_positioning_plan_tc ts_epis_positioning_plan.epis_positioning_plan_tc;
        --
        l_rows_epis_posit_plan     table_varchar;
        l_rowids                   table_varchar;
        l_id_epis_positioning_plan table_number := table_number();
        l_function_name            VARCHAR2(30 CHAR) := 'SET_CANCEL_INTERRUPT_POSIT';
        --
        CURSOR c_epp IS
            SELECT epp.*
              FROM epis_positioning_plan epp
             INNER JOIN epis_positioning_det epd
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
             WHERE epd.id_epis_positioning = i_epis_pos
               AND epp.flg_status IN (g_epis_posit_e, g_epis_posit_d);
    
    BEGIN
    
        --If new status is outdated don't update Positioning Plan
        IF i_flg_status <> g_epis_posit_o
        THEN
            g_error                := 'FETCH ROWTYPE EPIS_POSITIONING_PLAN';
            l_rows_epis_posit_plan := table_varchar();
        
            OPEN c_epp;
            LOOP
                FETCH c_epp BULK COLLECT
                    INTO l_epis_positioning_plan_tc LIMIT 1000;
            
                EXIT WHEN l_epis_positioning_plan_tc.count = 0;
            
                FOR j IN 1 .. l_epis_positioning_plan_tc.count
                LOOP
                    l_epis_positioning_plan_tc(j).flg_status := i_flg_status;
                    l_epis_positioning_plan_tc(j).id_prof_exec := i_prof.id;
                    l_epis_positioning_plan_tc(j).dt_epis_positioning_plan := g_sysdate_tstz;
                    l_id_epis_positioning_plan.extend;
                    l_id_epis_positioning_plan(j) := l_epis_positioning_plan_tc(j).id_epis_positioning_plan;
                    IF i_flg_status = g_epis_posit_f
                    THEN
                        l_epis_positioning_plan_tc(j).dt_execution_tstz := g_sysdate_tstz;
                    END IF;
                END LOOP;
            
                g_error := 'call set_epis_posit_plan_hist function';
                pk_alertlog.log_debug(g_error);
                IF NOT set_epis_posit_plan_hist(i_lang                     => i_lang,
                                                i_prof                     => i_prof,
                                                i_id_epis_positioning_plan => l_id_epis_positioning_plan,
                                                o_error                    => o_error)
                THEN
                    RAISE internal_error_exception;
                END IF;
            
                g_error  := 'UPDATE EPIS_POSITIONING_PLAN';
                l_rowids := table_varchar();
                ts_epis_positioning_plan.upd(col_in            => l_epis_positioning_plan_tc,
                                             ignore_if_null_in => FALSE,
                                             rows_out          => l_rowids);
            
                l_rows_epis_posit_plan := l_rows_epis_posit_plan MULTISET UNION l_rowids;
            END LOOP;
        
            CLOSE c_epp;
        
            IF l_rows_epis_posit_plan.count > 0
            THEN
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'EPIS_POSITIONING_PLAN',
                                              i_rowids       => l_rows_epis_posit_plan,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS'));
            END IF;
        END IF;
    
        g_error := 'CALL SET_EPIS_POSITIONING_HIST FOR ID_EPIS_POSITIONING: ' || i_epis_pos;
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_positioning_hist(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_epis_positioning => table_number(i_epis_pos),
                                         o_error               => o_error)
        THEN
            RAISE internal_error_exception;
        END IF;
    
        g_error  := 'UPDATE EPIS_POSITIONING';
        l_rowids := table_varchar();
        ts_epis_positioning.upd(id_epis_positioning_in => i_epis_pos,
                                flg_status_in          => i_flg_status,
                                id_professional_in     => i_prof.id,
                                id_prof_cancel_in      => CASE
                                                              WHEN i_flg_status IN (g_epis_posit_c,
                                                                                    g_epis_posit_o,
                                                                                    g_epis_posit_i,
                                                                                    g_epis_posit_f) THEN
                                                               i_prof.id
                                                          END,
                                notes_cancel_in        => CASE
                                                              WHEN i_flg_status IN (g_epis_posit_c,
                                                                                    g_epis_posit_o,
                                                                                    g_epis_posit_i,
                                                                                    g_epis_posit_f) THEN
                                                               i_notes
                                                          END,
                                id_cancel_reason_in    => CASE
                                                              WHEN i_flg_status IN
                                                                   (g_epis_posit_c, g_epis_posit_i, g_epis_posit_f) THEN
                                                               i_id_cancel_reason
                                                          END,
                                dt_cancel_tstz_in      => CASE
                                                              WHEN i_flg_status IN (g_epis_posit_c,
                                                                                    g_epis_posit_o,
                                                                                    g_epis_posit_i,
                                                                                    g_epis_posit_f) THEN
                                                               g_sysdate_tstz
                                                          END,
                                id_prof_inter_in       => CASE
                                                              WHEN i_flg_status = g_epis_posit_i THEN
                                                               i_prof.id
                                                          END,
                                notes_inter_in         => CASE
                                                              WHEN i_flg_status = g_epis_posit_i THEN
                                                               i_notes
                                                          END,
                                notes_inter_nin        => FALSE,
                                dt_inter_tstz_in       => CASE
                                                              WHEN i_flg_status = g_epis_posit_i THEN
                                                               g_sysdate_tstz
                                                          END,
                                dt_epis_positioning_in => g_sysdate_tstz,
                                rows_out               => l_rowids);
    
        IF i_flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
        THEN
            IF NOT cancel_assoc_icnp_interv(i_lang                => i_lang,
                                            i_prof                => i_prof,
                                            i_id_epis_positioning => i_epis_pos,
                                            o_error               => o_error)
            THEN
                RAISE internal_error_exception;
            END IF;
        
        END IF;
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_POSITIONING',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
        --  
    
        g_error := 'synchronize epis_positioning to epis_positioning_det';
        pk_alertlog.log_debug(g_error);
        IF NOT sync_epis_positioning_det(i_lang                => i_lang,
                                         i_prof                => i_prof,
                                         i_id_epis_positioning => table_number(i_epis_pos),
                                         i_sysdate_tstz        => g_sysdate_tstz,
                                         o_error               => o_error)
        THEN
            RAISE g_other_exception;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_cancel_interrupt_posit;

    /********************************************************************************************
    * Get id_epis_positioning_det 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_epis_positioning     epis_positioning id
    *  
    * @param       o_id_epis_positioning_det    table number with id_epis_positioning_det  
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/19       
    ********************************************************************************************/
    FUNCTION get_id_epis_positioning_det
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_epis_positioning     IN table_number,
        o_id_epis_positioning_det OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_ID_EPIS_POSITIONING_DET';
    
    BEGIN
    
        BEGIN
            SELECT epd.id_epis_positioning_det
              BULK COLLECT
              INTO o_id_epis_positioning_det
              FROM epis_positioning_det epd
             WHERE epd.id_epis_positioning IN (SELECT /*+opt_estimate(table,t1,scale_rows=0.0000001))*/
                                                t1.column_value
                                                 FROM TABLE(i_id_epis_positioning) t1)
               AND epd.flg_outdated = pk_alert_constant.g_no;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_epis_positioning_det := table_number();
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
        
    END get_id_epis_positioning_det;

    /********************************************************************************************
    * Synchronize last_update professional and update date between epis_positioning and epis_positioning_det 
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_epis_positioning     table_number
    * @param       i_sysdate_tstz            timestamp
    *  
    * @param       o_error                   error information
    *   
    *   
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Filipe Silva                        
    * @version                               2.6.1                                    
    * @since                                 2011/Apr/19       
    ********************************************************************************************/
    FUNCTION sync_epis_positioning_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        i_sysdate_tstz        IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name           VARCHAR2(30 CHAR) := 'SYNC_EPIS_POSITIONING_DET';
        l_id_epis_positioning_det table_number;
    
        l_rowid               table_varchar;
        l_rows_epis_posit_det table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'get id_epis_positioning_det';
        pk_alertlog.log_debug(g_error);
        IF NOT get_id_epis_positioning_det(i_lang                    => i_lang,
                                           i_prof                    => i_prof,
                                           i_id_epis_positioning     => i_id_epis_positioning,
                                           o_id_epis_positioning_det => l_id_epis_positioning_det,
                                           o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'set data to history table';
        pk_alertlog.log_debug(g_error);
        IF NOT set_epis_posit_det_hist(i_lang                    => i_lang,
                                       i_prof                    => i_prof,
                                       i_id_epis_positioning_det => l_id_epis_positioning_det,
                                       o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_id_epis_positioning_det IS NOT NULL
           AND l_id_epis_positioning_det.count > 0
        THEN
            FOR i IN 1 .. l_id_epis_positioning_det.count
            LOOP
            
                g_error := 'update epis_positioning_det for id_epis_positioning_det: ' || l_id_epis_positioning_det(i);
                pk_alertlog.log_debug(g_error);
            
                ts_epis_positioning_det.upd(id_epis_positioning_det_in => l_id_epis_positioning_det(i),
                                            id_prof_last_upd_in        => i_prof.id,
                                            rows_out                   => l_rowid);
            
                l_rows_epis_posit_det := l_rows_epis_posit_det MULTISET UNION l_rowid;
            
            END LOOP;
        END IF;
        IF l_rows_epis_posit_det.count > 0
           AND l_rows_epis_posit_det IS NOT NULL
        THEN
        
            g_error := 'CALL T_DATA_GOV_MNT.PROCESS_INSERT FOR EPIS_POSITIONING_DET TABLE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_POSITIONING_DET',
                                          i_rowids       => l_rows_epis_posit_det,
                                          i_list_columns => table_varchar('ID_PROF_LAST_UPD', 'DT_EPIS_POSITIONING_DET'),
                                          o_error        => o_error);
        
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END sync_epis_positioning_det;

    /**
    * Expire tasks action (task will change its state to expired)
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id
    * @param       i_task_requests           array of task request ids to expire
    * @param       o_error                   error message structure
    *
    * @return                                true on success, false otherwise
    * 
    * @author                                António Neto
    * @version                               2.5.1.8
    * @since                                 15-Sep-2011
    */
    FUNCTION expire_task
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_task_requests IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'EXPIRE_TASK';
    
        l_expired_note sys_message.desc_message%TYPE;
    
        l_id_epis_positioning epis_positioning.id_epis_positioning%TYPE;
    
        l_num_tasks PLS_INTEGER;
    
        l_msg_error VARCHAR(4000 CHAR);
    
        error_in_epis_positioning_reg EXCEPTION;
    BEGIN
        -- Sanity check
        IF i_task_requests IS NULL
           OR i_episode IS NULL
        THEN
            g_error := 'Invalid input arguments';
            pk_alertlog.log_warn(text => g_error, object_name => g_package_name, sub_object_name => co_function_name);
            RETURN TRUE;
        END IF;
    
        -- Text to include as cancellation note: "This patient's prescription (CPOE) has expired."
        l_expired_note := pk_message.get_message(i_lang, 'CPOE_M014');
    
        g_sysdate_tstz := current_timestamp;
    
        l_num_tasks := i_task_requests.count;
        --
        FOR i IN 1 .. l_num_tasks
        LOOP
            g_error := 'VALIDATE THAT ID_EPIS_POSITIONING CORRENPONDS TO ID_EPISODE';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT ep.id_epis_positioning
                  INTO l_id_epis_positioning
                  FROM epis_positioning ep
                 WHERE ep.id_epis_positioning = i_task_requests(i)
                   AND ep.id_episode = i_episode
                   AND ep.flg_status IN (pk_inp_positioning.g_epis_posit_r,
                                         pk_inp_positioning.g_epis_posit_e,
                                         pk_inp_positioning.g_epis_posit_d);
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_positioning := NULL;
            END;
        
            IF l_id_epis_positioning IS NOT NULL
            THEN
                BEGIN
                    g_error := 'CALL PK_INP_POSITIONING.SET_EPIS_POS_STATUS';
                    pk_alertlog.log_debug(g_error);
                    IF NOT set_epis_pos_status(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_epis_pos         => i_task_requests(i),
                                               i_flg_status       => g_epis_posit_o,
                                               i_notes            => l_expired_note,
                                               i_id_cancel_reason => NULL,
                                               o_msg_error        => l_msg_error,
                                               o_error            => o_error)
                    THEN
                        RAISE error_in_epis_positioning_reg;
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        RAISE error_in_epis_positioning_reg;
                END;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END expire_task;

    /**********************************************************************************************
    * Check the possibility to be recorded in the system an execution after the task was expired.
    * It was defined that it should be possible to record in the system the last execution made after the task expiration.
    * It should not be possible to record more than one excecution after the task was expired. 
    *
    * @param       i_lang                    Professional preferred language
    * @param       i_prof                    Professional identification and its context (institution and software)
    * @param       i_episode                 Episode ID
    * @param       i_task_request            Task request ID (ID_EPIS_POSITIONING)
    * @param       o_error                   Error information
    *
    * @return                                'Y' An execution is allowed. 'N' No execution is allowed (or the task has not expired).
    *
    * @author                                António Neto
    * @version                               2.5.1.8
    * @since                                 19-Sep-2011
    **********************************************************************************************/
    FUNCTION check_extra_take
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_task_request IN cpoe_process_task.id_task_request%TYPE
    ) RETURN VARCHAR IS
        co_function_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_EXTRA_TAKE';
        l_error                   t_error_out;
        l_execution_allowed       VARCHAR2(1 CHAR);
        l_status                  epis_positioning.flg_status%TYPE;
        l_dt_expire               epis_positioning.dt_cancel_tstz%TYPE;
        l_post_expired_executions NUMBER;
        l_id_epis_positioning_det table_number;
    
    BEGIN
    
        -- Check if the task has expired
        g_error := 'Get status';
        SELECT ep.flg_status,
               ep.dt_cancel_tstz,
               (SELECT CAST(COLLECT(to_number(aux.id_epis_positioning_det)) AS table_number)
                  FROM (SELECT epd.id_epis_positioning_det
                          FROM epis_positioning_det epd
                         WHERE epd.id_epis_positioning = i_task_request) aux)
          INTO l_status, l_dt_expire, l_id_epis_positioning_det
          FROM epis_positioning ep
         WHERE ep.id_epis_positioning = i_task_request
           AND ep.id_episode = i_episode;
    
        -- By default assumes the execution is not allowed
        l_execution_allowed := pk_alert_constant.g_no;
    
        -- Positioning expired 
        IF l_status = g_epis_posit_o
        THEN
        
            -- Check if already exists one execution after the task was expired
            g_error := 'Counting post-expired executions';
            SELECT COUNT(*)
              INTO l_post_expired_executions
              FROM epis_positioning_plan epp
             WHERE epp.id_epis_positioning_det IN
                   (SELECT *
                      FROM TABLE(l_id_epis_positioning_det))
               AND trunc(epp.dt_execution_tstz, 'MI') = trunc(l_dt_expire, 'MI');
        
            -- If there is not one execution after the task has been expired, then execution is allowed
            IF l_post_expired_executions = 0
            THEN
                l_execution_allowed := pk_alert_constant.g_yes;
            END IF;
        
        END IF;
    
        RETURN l_execution_allowed;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => co_function_name,
                                              o_error    => l_error);
            RAISE;
    END check_extra_take;

    /********************************************************************************************
    * Gets the positionings list for reports with timeframe and scope
    *
    * @param   I_LANG                      Language associated to the professional executing the request
    * @param   I_PROF                      Professional Identification
    * @param   I_SCOPE                     Scope ID
    * @param   I_FLG_SCOPE                 Scope type
    * @param   I_START_DATE                Start date for temporal filtering
    * @param   I_END_DATE                  End date for temporal filtering
    * @param   I_CANCELLED                 Indicates whether the records should be returned canceled ('Y' - Yes, 'N' - No)
    * @param   I_CRIT_TYPE                 Flag that indicates if the filter time to consider all records or only during the executions ('A' - All, 'E' - Executions, ...)
    * @param   I_FLG_REPORT                Flag used to remove formatting ('Y' - Yes, 'N' - No)
    * @param   O_POS                       Positioning list
    * @param   O_POS_EXEC                  Executions for Positioning list
    * @param   O_ERROR                     Error message
    *
    * @value   I_SCOPE                     {*} 'E' Episode ID {*} 'V' Visit ID {*} 'P' Patient ID
    * @value   I_FLG_SCOPE                 {*} 'E' Episode {*} 'V' Visit {*} 'P' Patient
    * @value   I_CANCELLED                 {*} 'Y' Yes {*} 'N' No
    * @value   I_CRIT_TYPE                 {*} 'A' All {*} 'E' Executions {*} 'R' requests
    * @value   I_FLG_REPORT                {*} 'Y' Yes {*} 'N' No
    *                        
    * @return                              true or false on success or error
    * 
    * @author                              António Neto
    * @version                             2.5.1.8.1
    * @since                               29-Sep-2011
    **********************************************************************************************/
    FUNCTION get_positioning_rep
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
        i_flg_status IN table_varchar DEFAULT NULL,
        o_pos        OUT pk_types.cursor_type,
        o_pos_exec   OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_patient patient.id_patient%TYPE;
    
        e_invalid_argument EXCEPTION;
    
        l_start_date TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
        l_end_date   TIMESTAMP(6) WITH LOCAL TIME ZONE := NULL;
    
        l_yes    VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_no     VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_yes_no VARCHAR2(6 CHAR) := 'YES_NO';
    
        l_flg_status       table_varchar;
        l_flg_status_count NUMBER := -1;
    
    BEGIN
    
        IF i_flg_status IS NULL
        THEN
            l_flg_status_count := 0;
            l_flg_status       := table_varchar();
        ELSE
            l_flg_status_count := i_flg_status.count;
            l_flg_status       := i_flg_status;
        END IF;
    
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
    
        g_error := 'GET CURSOR O_POS';
        OPEN o_pos FOR
            SELECT ep.id_epis_positioning,
                   pk_tools.get_prof_description(i_lang, i_prof, ep.id_professional, ep.dt_creation_tstz, ep.id_episode) ||
                   ' / ' ||
                   pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) professional,
                   pk_inp_positioning.get_positioning_concat(i_lang,
                                                             i_prof,
                                                             ep.id_epis_positioning,
                                                             NULL,
                                                             pk_alert_constant.g_yes) desc_positioning,
                   epp.id_epis_positioning_plan,
                   ep.flg_status flg_status,
                   epp.id_epis_positioning_det,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p
                     INNER JOIN epis_positioning_det epd1
                        ON p.id_positioning = epd1.id_positioning
                     WHERE p.flg_available = l_yes
                       AND epd1.id_epis_positioning_det = epp.id_epis_positioning_next) desc_pos_next,
                   decode(ep.rot_interval, NULL, NULL, ep.rot_interval || ' ' || 'h') rotation,
                   pk_sysdomain.get_domain(l_yes_no, ep.flg_massage, i_lang) desc_massage,
                   decode(pk_date_utils.compare_dates_tsz(i_prof, epp.dt_prev_plan_tstz, current_timestamp),
                          'G',
                          'G',
                          'L',
                          'R',
                          'R') color_status,
                   decode(epp.flg_status, g_epis_posit_e, g_epis_posit_d, g_epis_posit_i) flg_text,
                   pk_tools.get_prof_description(i_lang, i_prof, ep.id_prof_cancel, ep.dt_cancel_tstz, ep.id_episode) ||
                   ' / ' || pk_date_utils.date_char_tsz(i_lang, ep.dt_cancel_tstz, i_prof.institution, i_prof.software) prof_cancel,
                   pk_tools.get_prof_description(i_lang, i_prof, ep.id_prof_inter, ep.dt_inter_tstz, ep.id_episode) ||
                   ' / ' || pk_date_utils.date_char_tsz(i_lang, ep.dt_inter_tstz, i_prof.institution, i_prof.software) prof_inter,
                   ep.notes_inter,
                   ep.notes,
                   ep.notes_cancel cancel_notes,
                   pk_date_utils.date_send_tsz(i_lang, ep.dt_creation_tstz, i_prof) dt_creation_str
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
             INNER JOIN episode epi
                ON ep.id_episode = epi.id_episode
             WHERE epi.id_episode = nvl(l_id_episode, epi.id_episode)
               AND epi.id_visit = nvl(l_id_visit, epi.id_visit)
               AND epi.id_patient = nvl(l_id_patient, epi.id_patient)
               AND ep.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l)
               AND (ep.flg_status IN (SELECT t1.column_value
                                        FROM TABLE(l_flg_status) t1) OR l_flg_status_count = 0)
               AND (epp.id_epis_positioning_plan IN
                   (SELECT MAX(epp1.id_epis_positioning_plan)
                       FROM epis_positioning ep1
                      INNER JOIN epis_positioning_det epd1
                         ON ep1.id_epis_positioning = epd1.id_epis_positioning
                      INNER JOIN epis_positioning_plan epp1
                         ON epd1.id_epis_positioning_det = epp1.id_epis_positioning_det
                      INNER JOIN episode epi
                         ON ep1.id_episode = epi.id_episode
                      WHERE epi.id_episode = nvl(l_id_episode, epi.id_episode)
                        AND epi.id_visit = nvl(l_id_visit, epi.id_visit)
                        AND epi.id_patient = nvl(l_id_patient, epi.id_patient)
                        AND epp1.flg_status = g_epis_posit_f
                        AND ep1.flg_status IN (g_epis_posit_i, g_epis_posit_f)) OR
                   epp.flg_status IN (g_epis_posit_e, g_epis_posit_i, g_epis_posit_c, g_epis_posit_o))
               AND epp.flg_status != g_epis_posit_i
                  
               AND ( --if not report
                    i_flg_report = l_no OR
                    (
                    --if report
                     i_flg_report = l_yes
                    --
                     AND
                    --
                     (
                     --shows canceled positionings or not whether flag i_cancelled
                      (i_cancelled = l_no AND ep.flg_status <> g_epis_posit_c) OR i_cancelled = l_yes
                     --
                     )
                    --
                     AND
                    --
                     (
                     --shows positionings or not whether flag i_crit_type and the dates (i_start_date and i_end_date)
                     --Shows all the positionings where the req and exec was performed in the period
                      (i_crit_type = g_posit_crit_type_all_a AND
                      ( --
                       ep.dt_creation_tstz BETWEEN nvl(l_start_date, ep.dt_creation_tstz) AND
                       nvl(l_end_date, ep.dt_creation_tstz)
                      --
                       OR epp.dt_execution_tstz BETWEEN nvl(l_start_date, epp.dt_execution_tstz) AND
                       nvl(l_end_date, epp.dt_execution_tstz)
                      --
                       OR (SELECT check_has_executions(ep.id_epis_positioning, l_start_date, l_end_date)
                              FROM dual) = pk_alert_constant.g_yes
                      --
                      )
                      --
                      )
                     --
                      OR
                     --Shows the positionings that where req in the period
                      (i_crit_type = g_posit_crit_type_req_r AND
                      ep.dt_creation_tstz BETWEEN nvl(l_start_date, ep.dt_creation_tstz) AND
                      nvl(l_end_date, ep.dt_creation_tstz))
                     --
                      OR
                     --Shows the positionings that where exec in the period
                      (i_crit_type = g_posit_crit_type_exec_e AND
                      (epp.dt_execution_tstz BETWEEN nvl(l_start_date, epp.dt_execution_tstz) AND
                      nvl(l_end_date, epp.dt_execution_tstz)
                      --
                      OR (SELECT check_has_executions(ep.id_epis_positioning, l_start_date, l_end_date)
                              FROM dual) = pk_alert_constant.g_yes
                      --
                      )
                      --
                      )
                     --
                     )
                    --
                    )
                   --
                   )
             ORDER BY pk_sysdomain.get_rank(i_lang, g_code_flg_status, epp.flg_status), epp.id_epis_positioning_plan;
    
        g_error := 'GET CURSOR O_POS_EXEC';
        OPEN o_pos_exec FOR
            SELECT epp.id_epis_positioning_plan,
                   pk_tools.get_prof_description(i_lang, i_prof, epp.id_prof_exec, epp.dt_execution_tstz, ep.id_episode) ||
                   ' / ' ||
                   pk_date_utils.date_char_tsz(i_lang, epp.dt_execution_tstz, i_prof.institution, i_prof.software) professional,
                   epp.dt_execution_tstz,
                   epp.notes,
                   epp.flg_status status_epis_posit_plan,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p, epis_positioning_det epd1
                     WHERE p.id_positioning = epd1.id_positioning
                       AND p.flg_available = l_yes
                       AND epd1.id_epis_positioning_det = epp.id_epis_positioning_det) desc_pos_first,
                   (SELECT pk_translation.get_translation(i_lang, p.code_positioning)
                      FROM positioning p, epis_positioning_det epd1
                     WHERE p.id_positioning = epd1.id_positioning
                       AND p.flg_available = l_yes
                       AND epd1.id_epis_positioning_det = epp.id_epis_positioning_next) desc_pos_next,
                   ep.id_epis_positioning,
                   pk_date_utils.date_send_tsz(i_lang, epp.dt_execution_tstz, i_prof) dt_execution_str
              FROM epis_positioning ep
             INNER JOIN epis_positioning_det epd
                ON ep.id_epis_positioning = epd.id_epis_positioning
             INNER JOIN epis_positioning_plan epp
                ON epd.id_epis_positioning_det = epp.id_epis_positioning_det
             INNER JOIN episode epi
                ON ep.id_episode = epi.id_episode
             WHERE epi.id_episode = nvl(l_id_episode, epi.id_episode)
               AND epi.id_visit = nvl(l_id_visit, epi.id_visit)
               AND (ep.flg_status IN (SELECT t1.column_value
                                        FROM TABLE(l_flg_status) t1) OR l_flg_status_count = 0)
               AND epi.id_patient = nvl(l_id_patient, epi.id_patient)
               AND epp.flg_status IN (g_epis_posit_f)
               AND ( --if not report
                    i_flg_report = l_no OR
                    (
                    --if report
                     i_flg_report = l_yes
                    --
                     AND
                    --
                     (
                     --shows canceled positionings or not whether flag i_cancelled
                      (i_cancelled = l_no AND ep.flg_status <> g_epis_posit_c) OR i_cancelled = l_yes
                     --
                     )
                    --
                     AND
                    --
                     (
                     --Shows the positionings that where exec in the period
                      (i_crit_type IN (g_posit_crit_type_exec_e, g_posit_crit_type_all_a) AND
                      epp.dt_execution_tstz BETWEEN nvl(l_start_date, epp.dt_execution_tstz) AND
                      nvl(l_end_date, epp.dt_execution_tstz))
                     --
                     )
                    --
                    )
                   --
                   )
             ORDER BY pk_sysdomain.get_rank(i_lang, g_code_flg_status, epp.flg_status), epp.id_epis_positioning_plan;
    
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
                                              'GET_POSITIONING_REP',
                                              o_error);
            --
            pk_types.open_my_cursor(o_pos);
            pk_types.open_my_cursor(o_pos_exec);
            RETURN FALSE;
    END get_positioning_rep;

    /*******************************************************************************************************************************************
    * Checks if there is executions for a positioning episode within a range of dates
    * 
    * @param I_ID_EPIS_POSITIONING    Positioning EPISODE ID
    * @param I_START_DATE             Start date for temporal filtering
    * @param I_END_DATE               End date for temporal filtering
    * 
    * @return                         Returns 'Y' for existing executions otherwise 'N' is returned
    * 
    * @author                         António Neto
    * @version                        2.5.1.8.1
    * @since                          29-Sep-2011
    *******************************************************************************************************************************************/
    FUNCTION check_has_executions
    (
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_start_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    
        l_has_executions VARCHAR2(1 CHAR);
    BEGIN
    
        SELECT decode(COUNT(*), 0, pk_alert_constant.g_no, pk_alert_constant.g_yes)
          INTO l_has_executions
          FROM epis_positioning_det epd1
         INNER JOIN epis_positioning_plan epp1
            ON epd1.id_epis_positioning_det = epp1.id_epis_positioning_det
         WHERE epd1.id_epis_positioning = i_id_epis_positioning
           AND epp1.flg_status = g_epis_posit_f
           AND epp1.dt_execution_tstz IS NOT NULL
           AND epp1.dt_execution_tstz BETWEEN nvl(i_start_date, epp1.dt_execution_tstz) AND
               nvl(i_end_date, epp1.dt_execution_tstz);
    
        RETURN l_has_executions;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END check_has_executions;

    /**
    * Get positioning task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis_positioning         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_description
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN CLOB IS
        l_ret   CLOB;
        l_label sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'POSITIONING_T002');
    
        CURSOR c_desc IS
            SELECT CASE
                        WHEN descr IS NOT NULL
                             AND rotation IS NOT NULL THEN
                         descr || ' - ' || l_label || ': ' || rotation || CASE
                             WHEN dt_creation IS NOT NULL
                                  AND i_desc_type = pk_prog_notes_constants.g_desc_type_l THEN
                              ' (' || dt_creation || ')'
                             ELSE
                              NULL
                         END
                        WHEN descr IS NOT NULL
                             AND rotation IS NULL THEN
                         descr
                        WHEN descr IS NULL
                             AND rotation IS NOT NULL THEN
                         rotation || CASE
                             WHEN dt_creation IS NOT NULL
                                  AND i_desc_type = pk_prog_notes_constants.g_desc_type_l THEN
                              ' (' || dt_creation || ')'
                             ELSE
                              NULL
                         END
                        ELSE
                         NULL
                    END || ' - ' || pk_sysdomain.get_domain(i_lang     => i_lang,
                                                            i_code_dom => 'EPIS_POSITIONING.FLG_STATUS',
                                                            i_val      => flg_status)
              FROM (SELECT get_positionings(i_lang, i_prof, ep.id_epis_positioning, i_desc_type) descr,
                           decode(ep.rot_interval,
                                  NULL,
                                  NULL,
                                  pk_inp_positioning.get_fomatted_rot_interv(i_lang, i_prof, ep.rot_interval)) rotation,
                           pk_date_utils.date_char_tsz(i_lang, ep.dt_creation_tstz, i_prof.institution, i_prof.software) dt_creation,
                           ep.flg_status
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = i_id_epis_positioning);
    BEGIN
        OPEN c_desc;
        FETCH c_desc
            INTO l_ret;
        CLOSE c_desc;
    
        RETURN l_ret;
    END get_description;

    /**
    * Get positioning task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_epis_positioning         diet request identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/04/26
    */
    FUNCTION get_positionings
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        i_desc_type           IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_into table_varchar;
    BEGIN
    
        SELECT epd.rank || '.' || pk_translation.get_translation(i_lang, p.code_positioning)
          BULK COLLECT
          INTO l_into
          FROM epis_positioning_det epd
          JOIN positioning p
            ON p.id_positioning = epd.id_positioning
         WHERE epd.id_epis_positioning = i_id_epis_positioning
         ORDER BY epd.rank ASC;
    
        RETURN pk_utils.concat_table(l_into, '; ', 1, -1);
    END;

    FUNCTION inactivate_positioning_tasks
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
                                                                                    i_area => 'POSITIONING_INACTIVATE');
    
        l_cancel_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                              i_prof,
                                                                                              l_cancel_cfg);
    
        l_descontinued_id cancel_reason.id_cancel_reason%TYPE := pk_cancel_reason.get_id_by_content(i_lang,
                                                                                                    i_prof,
                                                                                                    l_descontinued_cfg);
    
        l_max_rows sys_config.value%TYPE := pk_sysconfig.get_config(i_prof    => i_prof,
                                                                    i_code_cf => 'INACTIVATE_TASKS_MAX_NUMBER_ROWS');
    
        l_positioning_req table_number;
        l_final_status    table_varchar;
    
        l_error t_error_out;
        g_other_exception EXCEPTION;
    
        l_msg_error VARCHAR2(200 CHAR);
    
        l_tbl_error_ids table_number := table_number();
    
        --The cursor will not fetch the records for the ids (id_comm_order_req) sent in i_ids_exclude        
        CURSOR c_positioning_req(ids_exclude IN table_number) IS
            SELECT t.id_epis_positioning, t.field_04 flg_final_status
              FROM (SELECT DISTINCT ep.id_epis_positioning, cfg.field_04, e.dt_end_tstz, cfg.field_02, cfg.field_03
                      FROM epis_positioning ep
                     INNER JOIN epis_positioning_det epd
                        ON ep.id_epis_positioning = epd.id_epis_positioning
                     INNER JOIN episode e
                        ON e.id_episode = ep.id_episode
                      LEFT JOIN (SELECT id_prev_episode, id_visit
                                  FROM episode
                                 WHERE id_episode IS NULL
                                UNION
                                SELECT id_prev_episode, id_visit
                                  FROM episode
                                 WHERE flg_status = pk_alert_constant.g_inactive) prev_e
                        ON prev_e.id_prev_episode = e.id_episode
                       AND e.id_visit = prev_e.id_visit
                     INNER JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 *
                                  FROM TABLE(l_tbl_config) t) cfg
                        ON cfg.field_01 = ep.flg_status
                      LEFT JOIN (SELECT /*+opt_estimate(table t rows=1)*/
                                 t.column_value
                                  FROM TABLE(i_ids_exclude) t) t_ids
                        ON t_ids.column_value = ep.id_epis_positioning
                     WHERE e.id_institution = i_inst
                       AND e.dt_end_tstz IS NOT NULL
                       AND rownum > 0
                       AND t_ids.column_value IS NULL) t
             WHERE pk_date_utils.trunc_insttimezone(i_prof,
                                                    pk_date_utils.add_to_ltstz(t.dt_end_tstz, t.field_02, t.field_03)) <=
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp)
               AND rownum <= l_max_rows;
    
    BEGIN
    
        o_has_error := FALSE;
    
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_positioning_req(i_ids_exclude);
        FETCH c_positioning_req BULK COLLECT
            INTO l_positioning_req, l_final_status;
        CLOSE c_positioning_req;
    
        IF l_positioning_req.count > 0
        THEN
            FOR i IN 1 .. l_positioning_req.count
            LOOP
            
                IF l_final_status(i) IN (pk_inp_positioning.g_epis_posit_i, pk_inp_positioning.g_epis_posit_c)
                THEN
                    SAVEPOINT init_cancel;
                    IF NOT pk_inp_positioning.set_cancel_interrupt_posit(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_epis_pos         => l_positioning_req(i),
                                                                    i_flg_status       => l_final_status(i),
                                                                    i_notes            => NULL,
                                                                    i_id_cancel_reason => CASE
                                                                                              WHEN l_final_status(i) =
                                                                                                   pk_inp_positioning.g_epis_posit_i THEN
                                                                                               l_descontinued_id
                                                                                              ELSE
                                                                                               l_cancel_id
                                                                                          END,
                                                                    o_error            => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_epis_positioning, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_epis_positioning that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_INP_POSITIONING.SET_CANCEL_INTERRUPT_POSIT FOR RECORD ' ||
                                   l_positioning_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_POSITIONING_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_epis_positioning) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_positioning_req(i);
                    
                        CONTINUE;
                    END IF;
                ELSE
                    SAVEPOINT init_cancel;
                    IF NOT pk_inp_positioning.set_epis_pos_status(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_epis_pos         => l_positioning_req(i),
                                                                  i_flg_status       => l_final_status(i),
                                                                  i_notes            => NULL,
                                                                  i_id_cancel_reason => l_cancel_id,
                                                                  
                                                                  o_msg_error => l_msg_error,
                                                                  o_error     => l_error)
                    THEN
                        ROLLBACK TO init_cancel;
                    
                        --If, for the given id_epis_positioning, an error is generated, o_has_error is set as TRUE,
                        --this way, the loop cicle may continue, but the system will know that at least one error has happened
                        o_has_error := TRUE;
                    
                        --A log for the id_epis_positioning that raised the error must be generated 
                        pk_alert_exceptions.reset_error_state;
                        g_error := 'ERROR CALLING PK_INP_POSITIONING.SET_EPIS_POS_STATUS FOR RECORD ' ||
                                   l_positioning_req(i);
                        pk_alert_exceptions.process_error(i_lang,
                                                          SQLCODE,
                                                          SQLERRM,
                                                          g_error,
                                                          g_package_owner,
                                                          g_package_name,
                                                          'INACTIVATE_POSITIONING_TASKS',
                                                          o_error);
                    
                        --The array for the ids (id_epis_positioning) that raised the error is incremented
                        l_tbl_error_ids.extend();
                        l_tbl_error_ids(l_tbl_error_ids.count) := l_positioning_req(i);
                    
                        CONTINUE;
                    END IF;
                END IF;
            END LOOP;
        
            --When the number of error ids match the max number of rows that can be processed for each call,
            --it means that no id_epis_positioning has been inactivated.
            --The next time the Job would be executed, the cursor would fetch the same set fetched on the previous call,
            --and therefore, from this point on, no more records would be inactivated.
            IF l_tbl_error_ids.count = l_max_rows
            THEN
                FOR i IN l_tbl_error_ids.first .. l_tbl_error_ids.last
                LOOP
                    --i_ids_exclude is an IN OUT parameter, and is incremented with the ids (id_epis_positioning) that could not
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
                IF NOT pk_inp_positioning.inactivate_positioning_tasks(i_lang        => i_lang,
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
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'INACTIVATE_POSITIONING_TASKS',
                                              o_error    => o_error);
            RETURN FALSE;
    END inactivate_positioning_tasks;

    PROCEDURE init_params
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
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_id_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_epis_pos epis_positioning.id_epis_positioning%TYPE;
    
        l_epis_posit_img_c sys_domain.img_name%TYPE := pk_sysdomain.get_img(l_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_c);
        l_epis_posit_img_f sys_domain.img_name%TYPE := pk_sysdomain.get_img(l_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_f);
        l_epis_posit_img_i sys_domain.img_name%TYPE := pk_sysdomain.get_img(l_lang,
                                                                            'EPIS_POSITIONING_PLAN.FLG_STATUS',
                                                                            g_epis_posit_i);
        l_epis_posit_img_o sys_domain.img_name%TYPE := pk_sysdomain.get_img(l_lang,
                                                                            'EPIS_POSITIONING.FLG_STATUS',
                                                                            g_epis_posit_o);
    
        l_positioning_m001 sys_message.desc_message%TYPE := pk_message.get_message(l_lang, 'POSITIONING_M001');
        l_positioning_m002 sys_message.desc_message%TYPE := pk_message.get_message(l_lang, 'POSITIONING_M002');
        o_error            t_error_out;
    BEGIN
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_id_episode', l_id_episode);
    
        IF i_context_vals.exists(1)
        THEN
            pk_context_api.set_parameter('l_sr_parent', to_number(i_context_vals(1)));
            pk_context_api.set_parameter('l_epis_pos', to_number(i_context_vals(1))); --Used in Executions grid
        END IF;
    
        IF i_context_vals.exists(2)
        THEN
            IF i_context_vals(2) = g_ds_sr_root
            THEN
                pk_context_api.set_parameter('l_flg_origin', g_flg_origin_sr);
            ELSE
                pk_context_api.set_parameter('l_flg_origin', g_flg_origin_n);
            END IF;
        END IF;
    
        IF i_context_vals.exists(3)
        THEN
            pk_context_api.set_parameter('l_id_episode_sr', to_number(i_context_vals(3)));
        END IF;
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_id_i_prof' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_id_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_id_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_id_episode' THEN
                o_vc2 := to_char(l_id_episode);
            WHEN 'l_epis_posit_img_c' THEN
                o_vc2 := l_epis_posit_img_c;
            WHEN 'l_epis_posit_img_f' THEN
                o_vc2 := l_epis_posit_img_f;
            WHEN 'l_epis_posit_img_i' THEN
                o_vc2 := l_epis_posit_img_i;
            WHEN 'l_epis_posit_img_o' THEN
                o_vc2 := l_epis_posit_img_o;
            WHEN 'l_positioning_m001' THEN
                o_vc2 := l_positioning_m001;
            WHEN 'l_positioning_m002' THEN
                o_vc2 := l_positioning_m002;
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_INP_POSITIONING',
                                              i_function => 'INIT_PARAMS',
                                              o_error    => o_error);
    END init_params;

    FUNCTION get_epis_posit_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_subject           IN action.subject%TYPE,
        i_from_state        IN action.from_state%TYPE,
        id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR o_actions';
    
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table act rows=1)*/
             act.id_action,
             act.id_parent,
             act.level_nr AS "LEVEL", --used to manage the shown' items by Flash
             act.from_state,
             act.to_state, --destination state flag
             act.desc_action, --action's description
             act.icon, --action's icon
             act.flg_default, --default action
             CASE
                  WHEN i_from_state IN ('I', 'C') THEN
                   pk_alert_constant.g_inactive
                  WHEN act.action = 'EDIT'
                       AND i_from_state NOT IN ('R') THEN
                   pk_alert_constant.g_inactive
                  WHEN act.action = 'CONCLUDE'
                       AND i_from_state NOT IN ('E') THEN
                   pk_alert_constant.g_inactive
                  ELSE
                   act.flg_active
              END flg_active, --action's state
             act.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, i_subject, NULL)) act;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_INP_POSITIONING',
                                              'GET_EPIS_POSIT_ACTIONS',
                                              o_error);
        
            pk_utils.undo_changes;
        
            pk_types.open_my_cursor(o_actions);
        
            pk_alert_exceptions.reset_error_state;
        
            RETURN FALSE;
        
    END get_epis_posit_actions;

    FUNCTION get_epis_positioning_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_episode                  IN episode.id_episode%TYPE,
        i_flg_status               IN epis_positioning.flg_status%TYPE,
        i_flg_status_plan          IN epis_positioning_plan.flg_status%TYPE,
        i_dt_creation_tstz         IN epis_positioning.dt_creation_tstz%TYPE,
        i_dt_prev_plan_tstz        IN epis_positioning_plan.dt_prev_plan_tstz%TYPE,
        i_dt_epis_positioning_plan IN epis_positioning_plan.dt_epis_positioning_plan%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
    
        l_display_type  VARCHAR2(200) := '';
        l_back_color    VARCHAR2(200) := '';
        l_status_flg    VARCHAR2(200) := '';
        l_message_style VARCHAR2(200) := '';
        l_message_color VARCHAR2(200) := '';
        l_default_color VARCHAR2(200) := '';
        l_icon_color    VARCHAR2(200) := '';
    
        l_aux VARCHAR2(200);
        -- date
        l_date_begin     VARCHAR2(200);
        l_date_prev_plan VARCHAR2(200);
        --
        l_date_comparison VARCHAR2(1);
    
    BEGIN
        -- l_date_begin
        IF i_flg_status_plan IN (g_epis_posit_r, g_epis_posit_e)
        THEN
            --          pk_alertlog.log_error('i_dt_prev_plan_tstz: ' || i_dt_prev_plan_tstz); 
            l_date_prev_plan := pk_date_utils.to_char_insttimezone(i_prof,
                                                                   i_dt_prev_plan_tstz,
                                                                   pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        
        ELSE
            l_date_begin := pk_date_utils.to_char_insttimezone(i_prof,
                                                               i_dt_creation_tstz,
                                                               pk_alert_constant.g_dt_yyyymmddhh24miss_tzr);
        
        END IF;
    
        IF i_flg_status = g_epis_posit_r
           AND i_flg_status_plan IN (g_epis_posit_e)
        THEN
            l_display_type := pk_alert_constant.g_display_type_date;
        ELSIF i_flg_status = g_epis_posit_e
              AND i_flg_status_plan = g_epis_posit_e
        THEN
            l_display_type := pk_alert_constant.g_display_type_date_icon;
        ELSE
            l_display_type := pk_alert_constant.g_display_type_icon;
        END IF;
    
        -- l_back_color
        IF i_flg_status NOT IN (g_epis_posit_r, g_epis_posit_e)
           OR i_flg_status_plan != g_epis_posit_e
        THEN
            l_back_color := pk_alert_constant.g_color_null;
        ELSE
            l_date_comparison := pk_date_utils.compare_dates_tsz(i_prof, i_dt_prev_plan_tstz, current_timestamp);
        
            IF l_date_comparison = 'G'
            THEN
                l_back_color := pk_alert_constant.g_color_green;
            ELSE
                l_back_color := pk_alert_constant.g_color_red;
            END IF;
        END IF;
    
        IF l_display_type = pk_alert_constant.g_display_type_icon
        THEN
            IF i_flg_status NOT IN (g_epis_posit_d, g_epis_posit_l, g_epis_posit_o)
            THEN
                l_status_flg := i_flg_status_plan;
                l_aux        := 'EPIS_POSITIONING_PLAN.FLG_STATUS';
            ELSE
                l_status_flg := i_flg_status;
                l_aux        := 'EPIS_POSITIONING.FLG_STATUS';
            END IF;
        ELSE
            l_status_flg := i_flg_status;
            l_aux        := NULL;
        END IF;
    
        RETURN pk_utils.get_status_string_immediate(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_display_type  => l_display_type,
                                                    i_flg_state     => l_status_flg,
                                                    i_value_text    => l_aux,
                                                    i_value_date    => nvl(l_date_prev_plan, l_date_begin),
                                                    i_value_icon    => l_aux,
                                                    i_back_color    => l_back_color,
                                                    i_icon_color    => l_icon_color,
                                                    i_message_style => l_message_style,
                                                    i_message_color => l_message_color,
                                                    i_default_color => l_default_color);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE);
    END get_epis_positioning_status;

    FUNCTION get_positioning_request_values
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
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_positioning_request_values';
    
        l_ds_pos_rot_internal_name CONSTANT VARCHAR2(100) := 'DS_POSITIONING_ROTATION';
    
        l_index                  NUMBER := 0;
        l_default_rotation_time  VARCHAR2(50) := '00000101010000';
        l_submited_rotation_time VARCHAR2(50);
    
        l_start_date        epis_positioning.dt_creation_tstz%TYPE;
        l_rotation_interval epis_positioning.rot_interval%TYPE;
        l_rotation_time     VARCHAR2(50);
        l_therapy_massage   epis_positioning.flg_massage%TYPE;
        l_notes             epis_positioning.notes%TYPE;
    
        l_posit_count      NUMBER := 0;
        l_limb_count       NUMBER := 0;
        l_protection_count NUMBER := 0;
    
        l_posit_tag              VARCHAR2(50);
        l_count_epis_positioning NUMBER := 0;
    
    BEGIN
    
        --Determining if we are comming from a new record or editing an existing record
        IF i_tbl_id_pk.exists(1)
        THEN
            SELECT COUNT(0)
              INTO l_count_epis_positioning
              FROM TABLE(i_tbl_id_pk) t
              JOIN epis_positioning ep
                ON ep.id_epis_positioning = t.column_value;
        ELSE
            l_count_epis_positioning := 0;
        END IF;
    
        IF i_action = pk_dyn_form_constant.get_submit_action() --ADDING/EDITING A VALUE IN THE FORM
        THEN
        
            --Determining the ammount of selected positionings (l_posit_count)
            --If only one positioning has been selected, the field 'Rotation interval' must be inactivated
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) IN (g_id_cmpt_mkt_rel_position, g_id_cmpt_mkt_rel_sr_position)
                THEN
                    l_index := i;
                    EXIT;
                END IF;
            END LOOP;
        
            IF l_index > 0
            THEN
                IF i_value(l_index).exists(1)
                THEN
                    IF i_value(l_index) (1) IS NOT NULL
                       AND length(i_value(l_index) (1)) IS NOT NULL
                    THEN
                        l_posit_count := i_value(l_index).count;
                    END IF;
                END IF;
            END IF;
            l_index := 0;
        
            --Determining the ammount of selected limb positionings (l_limb_count)
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) IN (g_id_cmpt_mkt_rel_sr_limb_pos)
                THEN
                    l_index := i;
                    EXIT;
                END IF;
            END LOOP;
        
            IF l_index > 0
            THEN
                IF i_value(l_index).exists(1)
                THEN
                    IF i_value(l_index) (1) IS NOT NULL
                       AND length(i_value(l_index) (1)) IS NOT NULL
                    THEN
                        l_limb_count := i_value(l_index).count;
                    END IF;
                END IF;
            END IF;
            l_index := 0;
        
            --Determining the ammount of selected means of protection (l_protection_count)
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) IN (g_id_cmpt_mkt_rel_sr_protec)
                THEN
                    l_index := i;
                    EXIT;
                END IF;
            END LOOP;
        
            IF l_index > 0
            THEN
                IF i_value(l_index).exists(1)
                THEN
                    IF i_value(l_index) (1) IS NOT NULL
                       AND length(i_value(l_index) (1)) IS NOT NULL
                    THEN
                        l_protection_count := i_value(l_index).count;
                    END IF;
                END IF;
            END IF;
            l_index := 0;
        
            --Determining if a custom rotation interval as been set (l_submited_rotation_time)
            --If no custom interval has been set, then it should be used the default interval '01:00'                        
            FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
            LOOP
                IF i_tbl_mkt_rel(i) IN (g_id_cmpt_mkt_rel_rot_interval, g_id_cmpt_mkt_rel_sr_rot_int)
                THEN
                    l_index := i;
                    EXIT;
                END IF;
            END LOOP;
        
            IF l_index > 0
            THEN
                l_submited_rotation_time := i_value(l_index) (1);
            END IF;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => NULL, --t.id_ds_component_child,
                                       internal_name      => NULL, --t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN internal_name_child = l_ds_pos_rot_internal_name THEN
                                                                  coalesce(l_submited_rotation_time, l_default_rotation_time)
                                                                 ELSE
                                                                  NULL
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => NULL,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                             --Inactivate roation interval if nº of selected positions is less than 2
                                                             --or if we limb or protective positionings                                                                                                                                                                        
                                                                 WHEN l_posit_count < 2
                                                                      AND internal_name_child = l_ds_pos_rot_internal_name THEN
                                                                  'I'
                                                             --IF we are editing the form, only the current positioning field should be active
                                                                 WHEN l_count_epis_positioning > 0
                                                                      AND internal_name_child IN
                                                                      (g_ds_positioning_list, g_ds_positioning_protection, g_ds_positioning_limb_list) THEN
                                                                  'I'
                                                             -- If no value has yet been inserted for positioning, all the fields should be mandatory
                                                                 WHEN (l_posit_count = 0 AND l_limb_count = 0 AND l_protection_count = 0)
                                                                      AND internal_name_child IN
                                                                      (g_ds_positioning_list, g_ds_positioning_protection, g_ds_positioning_limb_list) THEN
                                                                  'M'
                                                             --
                                                                 WHEN internal_name_child IN (g_ds_positioning_list,
                                                                                              g_ds_positioning_protection,
                                                                                              g_ds_positioning_limb_list,
                                                                                              l_ds_pos_rot_internal_name) THEN
                                                                  'A'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE ((d.internal_name = l_ds_pos_rot_internal_name) OR
                   (d.internal_name = g_ds_positioning_limb_list AND l_limb_count = 0) OR
                   (d.internal_name = g_ds_positioning_protection AND l_protection_count = 0) OR
                   (d.internal_name = g_ds_positioning_list AND l_posit_count = 0))
             ORDER BY t.rn;
        
        ELSIF i_action IS NOT NULL
        THEN
            --EDIT FORM
            SELECT epp.dt_prev_plan_tstz, ep.rot_interval, ep.flg_massage, ep.notes
              INTO l_start_date, l_rotation_interval, l_therapy_massage, l_notes
              FROM epis_positioning ep
              JOIN epis_positioning_det epd
                ON epd.id_epis_positioning = ep.id_epis_positioning
               AND epd.dt_epis_positioning_det = ep.dt_epis_positioning
              JOIN epis_positioning_plan epp
                ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
               AND epp.flg_status IN (g_epis_posit_e, g_epis_posit_d)
             WHERE ep.id_epis_positioning IN (SELECT /*+opt_estimate(table a rows=1)*/
                                               column_value
                                                FROM TABLE(i_tbl_id_pk) a);
            BEGIN
                SELECT CASE
                           WHEN t.posit_type = 1 THEN
                            g_ds_positioning_list
                           WHEN t.posit_type = 2 THEN
                            g_ds_positioning_limb_list
                           WHEN t.posit_type = 3 THEN
                            g_ds_positioning_protection
                       END
                  INTO l_posit_tag
                  FROM (SELECT pis.posit_type, rownum AS rn
                          FROM epis_positioning_det epd
                          JOIN positioning p
                            ON p.id_positioning = epd.id_positioning
                          JOIN positioning_instit_soft pis
                            ON pis.id_positioning = p.id_positioning
                           AND pis.id_software = i_prof.software
                           AND pis.id_institution = i_prof.institution
                           AND pis.flg_available = pk_alert_constant.g_yes
                         WHERE epd.id_epis_positioning IN (SELECT /*+opt_estimate(table a rows=1)*/
                                                            column_value
                                                             FROM TABLE(i_tbl_id_pk) a)
                           AND epd.flg_outdated = pk_alert_constant.g_no) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_posit_tag := g_ds_positioning_list;
            END;
        
            IF l_rotation_interval IS NOT NULL
            THEN
                l_rotation_time := '00000101' || substr(l_rotation_interval, 1, 2) || substr(l_rotation_interval, 4, 2) || '00';
            END IF;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => t.id_val,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => t.desc_val,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN l_rotation_interval IS NULL
                                                                      AND internal_name_child = l_ds_pos_rot_internal_name THEN
                                                                  'I'
                                                                 WHEN t.internal_name_child IN
                                                                      (g_ds_positioning_list, g_ds_positioning_limb_list, g_ds_positioning_protection)
                                                                      AND t.internal_name_child <> l_posit_tag THEN
                                                                  'I'
                                                                 ELSE
                                                                  'NA'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           tt.desc_posit AS desc_val,
                           to_char(tt.id_val) id_val,
                           tt.rank_epp
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc
                      JOIN ds_component d
                        ON d.id_ds_component = dc.id_ds_component_child
                      JOIN (SELECT p.id_positioning AS id_val,
                                  pk_translation.get_translation(i_lang, p.code_positioning) AS desc_posit,
                                  l_posit_tag AS ds_internal_name,
                                  epd.rank AS rank_epp
                             FROM epis_positioning ep
                             JOIN epis_positioning_det epd
                               ON epd.id_epis_positioning = ep.id_epis_positioning
                             JOIN positioning p
                               ON p.id_positioning = epd.id_positioning
                            WHERE ep.id_epis_positioning IN (SELECT /*+opt_estimate(table a rows=1)*/
                                                              column_value
                                                               FROM TABLE(i_tbl_id_pk) a)
                              AND epd.flg_outdated = pk_alert_constant.g_no) tt
                        ON tt.ds_internal_name = d.internal_name
                    
                    UNION ALL
                    
                    SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child,
                           CASE
                               WHEN d.internal_name = 'DS_POSITIONING_NOTES' THEN
                                l_notes
                           END desc_val,
                           CASE
                               WHEN d.internal_name = 'DS_POSITIONING_MASSAGE' THEN
                                l_therapy_massage
                               WHEN d.internal_name = 'DS_POSITIONING_START_DATE' THEN
                                pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_start_date, i_prof => i_prof)
                               WHEN d.internal_name = 'DS_POSITIONING_ROTATION' THEN
                                l_rotation_time
                           END id_val,
                           NULL rank_epp
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc
                      JOIN ds_component d
                        ON d.id_ds_component = dc.id_ds_component_child
                     WHERE d.internal_name NOT IN (l_posit_tag)) t
             ORDER BY rank_epp ASC NULLS LAST;
        ELSE
            --NEW FORM
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.internal_name_child = g_ds_positioning_start_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof)
                                                                 WHEN t.internal_name_child = g_ds_positioning_massage THEN
                                                                  pk_alert_constant.g_no
                                                                 ELSE
                                                                  l_default_rotation_time
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => NULL,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => 'NA',
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN
                   (l_ds_pos_rot_internal_name, g_ds_positioning_start_date, g_ds_positioning_massage)
             ORDER BY t.rn;
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_positioning_request_values;

    FUNCTION get_positioning_exec_values
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
        tbl_result t_tbl_ds_get_value := t_tbl_ds_get_value();
        l_db_object_name CONSTANT user_objects.object_name%TYPE := 'get_positioning_exec_values';
    
        l_rotation_interval epis_positioning.rot_interval%TYPE;
        l_interval          NUMBER;
        l_dt_plan           TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_id_epis_positioning     epis_positioning.id_epis_positioning%TYPE;
        l_input_exec_date         VARCHAR(200);
        l_input_next_exec_date    VARCHAR(200);
        l_dt_input_exec_date      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_input_next_exec_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_input_exec_date_format  VARCHAR2(200);
    
        l_dt_input_exec_date_min TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_validation         VARCHAR2(5 CHAR) := pk_alert_constant.g_yes;
        l_err_msg                sys_message.desc_message%TYPE;
    
        l_id_exec_date_mkt_rel      ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
        l_id_next_exec_date_mkt_rel ds_cmpt_mkt_rel.id_ds_cmpt_mkt_rel%TYPE;
    
    BEGIN
        IF i_action IS NULL
        THEN
            g_error := 'TREATMENT INTERVAL';
            BEGIN
                SELECT ep.rot_interval
                  INTO l_rotation_interval
                  FROM epis_positioning_det epd
                  JOIN epis_positioning ep
                    ON ep.id_epis_positioning = epd.id_epis_positioning
                 WHERE epd.id_epis_positioning_det IN (SELECT /*+opt_estimate(table a rows=1)*/
                                                        column_value
                                                         FROM TABLE(i_tbl_id_pk) a);
            EXCEPTION
                WHEN no_data_found THEN
                    l_rotation_interval := NULL;
            END;
        
            IF l_rotation_interval IS NOT NULL
            THEN
                IF instr(l_rotation_interval, ':') != 0
                THEN
                    l_interval := to_number(to_char(to_date(l_rotation_interval, 'HH24:MI'), 'SSSSS'));
                ELSIF l_rotation_interval IS NULL
                THEN
                    l_interval := NULL;
                END IF;
            ELSE
                l_interval := NULL;
            END IF;
            --
            g_error   := 'DT_PLAN';
            l_dt_plan := current_timestamp + numtodsinterval(l_interval, 'SECOND');
        
            --NEW FORM
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                       id_ds_component    => t.id_ds_component_child,
                                       internal_name      => t.internal_name_child,
                                       VALUE              => CASE
                                                                 WHEN t.id_ds_cmpt_mkt_rel = g_id_cmpt_mkt_rel_start_date THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => current_timestamp, i_prof => i_prof)
                                                                 WHEN t.id_ds_cmpt_mkt_rel = g_id_cmpt_mkt_rel_next_exec THEN
                                                                  pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => l_dt_plan, i_prof => i_prof)
                                                             END,
                                       value_clob         => NULL,
                                       min_value          => NULL,
                                       max_value          => NULL,
                                       desc_value         => CASE
                                                                 WHEN t.id_ds_cmpt_mkt_rel = g_id_cmpt_mkt_rel_prof_exec THEN
                                                                  pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => i_prof.id)
                                                             
                                                             END,
                                       desc_clob          => NULL,
                                       id_unit_measure    => NULL,
                                       desc_unit_measure  => NULL,
                                       flg_validation     => pk_alert_constant.g_yes,
                                       err_msg            => NULL,
                                       flg_event_type     => CASE
                                                                 WHEN t.id_ds_cmpt_mkt_rel IN (g_id_cmpt_mkt_rel_prof_exec) THEN
                                                                  'R'
                                                                 WHEN t.id_ds_cmpt_mkt_rel IN (g_id_cmpt_mkt_rel_next_exec)
                                                                      AND l_interval IS NULL THEN
                                                                  'I'
                                                                 ELSE
                                                                  'NA'
                                                             END,
                                       flg_multi_status   => NULL,
                                       idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             ORDER BY t.rn;
        
        ELSE
            --Determine the id_ds_cmpt_mkt_rel of the field 'Performed at'
            SELECT d.id_ds_cmpt_mkt_rel
              INTO l_id_exec_date_mkt_rel
              FROM ds_cmpt_mkt_rel d
             WHERE d.internal_name_child = g_ds_execution_start_date
               AND d.internal_name_parent = g_ds_execution_root;
        
            --Determine the id_ds_cmpt_mkt_rel of the field 'Next execution'  
            SELECT d.id_ds_cmpt_mkt_rel
              INTO l_id_next_exec_date_mkt_rel
              FROM ds_cmpt_mkt_rel d
             WHERE d.internal_name_child = g_ds_next_exec
               AND d.internal_name_parent = g_ds_execution_root;
        
            --Check if the user is inserting a value for the field 'Performed at' or the 'Next execution'
            IF i_curr_component IN (l_id_exec_date_mkt_rel, l_id_next_exec_date_mkt_rel)
            THEN
            
                --Obtain the inserted value (string and time_stamp)
                FOR i IN i_tbl_mkt_rel.first .. i_tbl_mkt_rel.last
                LOOP
                    IF i_tbl_mkt_rel(i) = l_id_exec_date_mkt_rel
                    THEN
                        l_input_exec_date    := i_value(i) (1);
                        l_dt_input_exec_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i) (1), NULL);
                    ELSIF i_tbl_mkt_rel(i) = l_id_next_exec_date_mkt_rel
                    THEN
                        l_input_next_exec_date    := i_value(i) (1);
                        l_dt_input_next_exec_date := pk_date_utils.get_string_tstz(i_lang, i_prof, i_value(i) (1), NULL);
                    END IF;
                END LOOP;
            
                IF i_curr_component = l_id_exec_date_mkt_rel
                THEN
                    --Check the date of the positioning request or, if it exists, the date of last execution
                    --(the date for 'Performed at' cannot be prior to the date of request nor the date of the last execution)
                    SELECT epd_i.id_epis_positioning
                      INTO l_id_epis_positioning
                      FROM epis_positioning_det epd_i
                     WHERE epd_i.id_epis_positioning_det = i_tbl_id_pk(1);
                
                    SELECT MAX(dt_input_exec_date_min)
                      INTO l_dt_input_exec_date_min
                      FROM (SELECT MIN(dt_epis_positioning) AS dt_input_exec_date_min
                              FROM (SELECT ep.dt_epis_positioning
                                      FROM epis_positioning ep
                                     WHERE ep.id_epis_positioning = l_id_epis_positioning
                                    UNION ALL
                                    SELECT eph.dt_epis_positioning
                                      FROM epis_positioning_hist eph
                                     WHERE eph.id_epis_positioning = l_id_epis_positioning)
                            UNION ALL
                            SELECT MAX(epp.dt_execution_tstz) AS dt_input_exec_date_min
                              FROM epis_positioning_plan epp
                             WHERE epp.id_epis_positioning_det IN
                                   (SELECT epd.id_epis_positioning_det
                                      FROM epis_positioning_det epd
                                     WHERE epd.id_epis_positioning = l_id_epis_positioning)
                               AND epp.dt_execution_tstz IS NOT NULL);
                
                    --Normalize the input date and the minimum date (remove the seconds) and check if they are the same.
                    --If they are, no error should be shown.
                    IF pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                              i_date => l_dt_input_exec_date_min,
                                                              i_prof => i_prof) <>
                       pk_date_utils.date_mon_hour_format_tsz(i_lang => i_lang,
                                                              i_date => l_dt_input_exec_date,
                                                              i_prof => i_prof)
                    
                    THEN
                        --Comparing the date of request/last execution with the date set in 'Performed at'            
                        IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                           i_date1 => l_dt_input_exec_date_min,
                                                           i_date2 => l_dt_input_exec_date) = 'G'
                        THEN
                            l_flg_validation     := g_flg_validation_error;
                            l_input_exec_date    := NULL;
                            l_dt_input_exec_date := NULL;
                            l_err_msg            := pk_message.get_message(i_lang, 'POSITIONING_M040');
                        
                            --Comparing the date set in 'Performed at' wit the current date.
                            --The date set in 'Performed at' cannot be a date after the current_date
                        ELSIF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                              i_date1 => l_dt_input_exec_date,
                                                              i_date2 => current_timestamp) = 'G'
                        THEN
                            l_flg_validation     := g_flg_validation_error;
                            l_input_exec_date    := NULL;
                            l_dt_input_exec_date := NULL;
                            l_err_msg            := pk_message.get_message(i_lang, 'POSITIONING_M041');
                        END IF;
                    END IF;
                ELSE
                    --Check if the next exection date is not prior to the current execution date
                    IF pk_date_utils.compare_dates_tsz(i_prof  => i_prof,
                                                       i_date1 => l_dt_input_exec_date,
                                                       i_date2 => l_dt_input_next_exec_date) = 'G'
                    THEN
                        l_flg_validation       := g_flg_validation_error;
                        l_input_next_exec_date := NULL;
                        l_err_msg              := pk_message.get_message(i_lang, 'POSITIONING_M042');
                    END IF;
                END IF;
            END IF;
        
            SELECT t_rec_ds_get_value(id_ds_cmpt_mkt_rel => t.id_ds_cmpt_mkt_rel,
                                      id_ds_component    => t.id_ds_component_child,
                                      internal_name      => t.internal_name_child,
                                      VALUE              => CASE internal_name
                                                                WHEN g_ds_execution_start_date THEN
                                                                 l_input_exec_date
                                                                WHEN g_ds_next_exec THEN
                                                                 l_input_next_exec_date
                                                                ELSE
                                                                 NULL
                                                            END,
                                      value_clob         => NULL,
                                      min_value          => NULL,
                                      max_value          => NULL,
                                      desc_value         => NULL,
                                      desc_clob          => NULL,
                                      id_unit_measure    => NULL,
                                      desc_unit_measure  => NULL,
                                      flg_validation     => l_flg_validation,
                                      err_msg            => l_err_msg,
                                      flg_event_type     => 'M',
                                      flg_multi_status   => NULL,
                                      idx                => 1)
              BULK COLLECT
              INTO tbl_result
              FROM (SELECT dc.id_ds_cmpt_mkt_rel,
                           dc.id_ds_component_child,
                           dc.internal_name_child,
                           dc.flg_event_type,
                           dc.rn,
                           dc.flg_component_type_child
                      FROM TABLE(pk_dyn_form.get_dyn_cfg(i_lang           => i_lang,
                                                         i_prof           => i_prof,
                                                         i_patient        => NULL,
                                                         i_component_name => i_root_name,
                                                         i_action         => NULL)) dc) t
              JOIN ds_component d
                ON d.id_ds_component = t.id_ds_component_child
             WHERE d.internal_name IN (g_ds_execution_start_date, g_ds_next_exec)
               AND t.id_ds_cmpt_mkt_rel = i_curr_component
             ORDER BY t.rn;
        
        END IF;
    
        RETURN tbl_result;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_db_object_name,
                                              o_error);
            RETURN NULL;
    END get_positioning_exec_values;

    FUNCTION get_epis_positioning_detail
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         VARCHAR2(30) := 'GET_EPIS_POSITIONING_DETAIL';
        l_limit             PLS_INTEGER := 1000;
        l_counter           PLS_INTEGER := 0;
        l_tbl_lables        table_varchar := table_varchar();
        l_tbl_values        table_varchar := table_varchar();
        l_tbl_types         table_varchar := table_varchar();
        l_tbl_tags_req      table_varchar := table_varchar();
        l_tbl_tbl_tags_exec table_table_varchar := table_table_varchar();
        l_tbl_tbl_tags_req  table_table_varchar := table_table_varchar();
        l_tbl_tags_exec     table_varchar := table_varchar();
        l_tab_hist_req      t_table_history_data := t_table_history_data();
        l_tab_hist_exec     t_table_history_data := t_table_history_data();
        ---
        l_req_data            t_table_history_data := t_table_history_data();
        l_exec_data           t_table_history_data := t_table_history_data();
        l_tbl_values_aux_req  table_varchar := table_varchar();
        l_tbl_values_aux_exec table_varchar := table_varchar();
        l_previous_size       NUMBER := 0;
        l_tbl_count           table_number := table_number();
        l_tbl_exec_id         table_number := table_number();
        l_tbl_req_id          table_number := table_number();
        --
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_inp_code_messages       t_code_messages;
        l_inp_posit_code_messages table_varchar2 := table_varchar2('POSITIONING_T029',
                                                                   'POSITIONING_T030',
                                                                   'POSITIONING_T023',
                                                                   'POSITIONING_T024',
                                                                   'COMMON_M107',
                                                                   'POSITIONING_T025',
                                                                   'COMMON_M108',
                                                                   'POSITIONING_T026',
                                                                   'POSITIONING_T027',
                                                                   'POSITIONING_T028',
                                                                   'POSITIONING_M003',
                                                                   'POSITIONING_M004',
                                                                   'POSITIONING_M005',
                                                                   'POSITIONING_M006',
                                                                   'POSITIONING_M007',
                                                                   'POSITIONING_M008',
                                                                   'POSITIONING_M009',
                                                                   'POSITIONING_M010',
                                                                   'POSITIONING_M011',
                                                                   'POSITIONING_M012',
                                                                   'POSITIONING_M013',
                                                                   'POSITIONING_M014',
                                                                   'POSITIONING_M015',
                                                                   'POSITIONING_M016',
                                                                   'POSITIONING_M017',
                                                                   'POSITIONING_M018',
                                                                   'POSITIONING_M019',
                                                                   'POSITIONING_M020',
                                                                   'COMMON_M108',
                                                                   'COMMON_M106',
                                                                   'POSITIONING_M021',
                                                                   'POSITIONING_M022',
                                                                   'MED_PRESC_T088',
                                                                   'POSITIONING_M023',
                                                                   'POSITIONING_M024',
                                                                   'POSITIONING_M025',
                                                                   'POSITIONING_M028',
                                                                   'POSITIONING_M029',
                                                                   'POSITIONING_M030',
                                                                   'POSITIONING_M031',
                                                                   'POSITIONING_M032',
                                                                   'POSITIONING_M033');
    
        CURSOR c_get_positionings_req IS
            SELECT *
              FROM (SELECT -1 id_epis_positioning_hist, ep.*
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = i_id_epis_positioning) t
             ORDER BY id_epis_positioning_hist DESC NULLS FIRST;
    
        TYPE c_positioning_req IS TABLE OF c_get_positionings_req%ROWTYPE;
        l_positioning_req  c_positioning_req;
        l_posit_req_struct c_positioning_req := c_positioning_req();
    
        CURSOR c_get_positionings_plan IS
            SELECT *
              FROM (SELECT -1 AS id_epis_posit_plan_hist, epp.*
                      FROM epis_positioning_det epd
                     INNER JOIN epis_positioning_plan epp
                        ON epp.id_epis_positioning_det = epd.id_epis_positioning_det
                     WHERE epd.id_epis_positioning = i_id_epis_positioning
                       AND epp.flg_status NOT IN (g_epis_posit_d, g_epis_posit_l, g_epis_posit_o))
             ORDER BY dt_epis_positioning_plan, id_epis_positioning_plan;
    
        TYPE c_positioning_plan IS TABLE OF c_get_positionings_plan%ROWTYPE;
        l_positioning_plan  c_positioning_plan;
        l_posit_plan_struct c_positioning_plan := c_positioning_plan();
    
    BEGIN
        -- fill all translations in collection
        FOR i IN l_inp_posit_code_messages.first .. l_inp_posit_code_messages.last
        LOOP
            l_inp_code_messages(l_inp_posit_code_messages(i)) := pk_message.get_message(i_lang,
                                                                                        l_inp_posit_code_messages(i));
        END LOOP;
    
        -- get positionings requisition records
        g_error := 'OPEN C_GET_POSITIONINGS_REQ CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_positionings_req;
        LOOP
            FETCH c_get_positionings_req BULK COLLECT
                INTO l_positioning_req LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_req.count
            LOOP
                l_posit_req_struct.extend;
                l_posit_req_struct(l_posit_req_struct.count) := l_positioning_req(i);
            END LOOP;
            EXIT WHEN c_get_positionings_req%NOTFOUND;
        END LOOP;
    
        --FOR c IN 1 .. l_posit_req_struct.count
        FOR c IN REVERSE 1 .. l_posit_req_struct.count
        LOOP
            --last record doesn't need to be compared
            IF (c = l_posit_req_struct.count)
            THEN
                g_error := 'call get_first_values_req';
                pk_alertlog.log_debug(g_error);
                l_tbl_tbl_tags_req.extend();
                IF NOT get_first_values_req(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_actual_row => l_posit_req_struct(l_posit_req_struct.count),
                                            i_labels     => l_inp_code_messages,
                                            i_flg_screen => g_flg_screen_detail,
                                            o_tbl_labels => l_tbl_lables,
                                            o_tbl_values => l_tbl_values,
                                            o_tbl_types  => l_tbl_types,
                                            o_tbl_tags   => l_tbl_tbl_tags_req(l_tbl_tbl_tags_req.count))
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
                l_tbl_tbl_tags_req.extend();
                --compare current record with the next record to check what's differences between them
                g_error := 'call get_values_req';
                pk_alertlog.log_debug(g_error);
                IF NOT get_values_req(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_actual_row   => l_posit_req_struct(c),
                                      i_previous_row => l_posit_req_struct(c + 1),
                                      i_labels       => l_inp_code_messages,
                                      o_tbl_labels   => l_tbl_lables,
                                      o_tbl_values   => l_tbl_values,
                                      o_tbl_types    => l_tbl_types,
                                      o_tbl_tags     => l_tbl_tbl_tags_req(l_tbl_tbl_tags_req.count))
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
            l_tab_hist_req.extend;
            l_tab_hist_req(l_tab_hist_req.count) := t_rec_history_data(id_rec => CASE
                                                                                     WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                                      l_posit_req_struct(c).id_epis_positioning
                                                                                     ELSE
                                                                                      l_posit_req_struct(c).id_epis_positioning_hist
                                                                                 END,
                                                                       
                                                                       flg_status      => l_posit_req_struct(c).flg_status,
                                                                       date_rec        => l_posit_req_struct(c).dt_epis_positioning,
                                                                       tbl_labels      => l_tbl_lables,
                                                                       tbl_values      => l_tbl_values,
                                                                       tbl_types       => l_tbl_types,
                                                                       tbl_info_labels => pk_inp_detail.get_info_labels,
                                                                       tbl_info_values => pk_inp_detail.get_info_values(l_posit_req_struct(c).flg_status),
                                                                       table_origin    => CASE
                                                                                              WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                                               'EPIS_POSITIONING'
                                                                                              ELSE
                                                                                               'EPIS_POSITIONING_HIST'
                                                                                          END);
        
        END LOOP;
    
        -- get positionings plan records
        OPEN c_get_positionings_plan;
        LOOP
            FETCH c_get_positionings_plan BULK COLLECT
                INTO l_positioning_plan LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_plan.count
            LOOP
                l_posit_plan_struct.extend;
                l_posit_plan_struct(l_posit_plan_struct.count) := l_positioning_plan(i);
            END LOOP;
            EXIT WHEN c_get_positionings_plan%NOTFOUND;
        END LOOP;
    
        FOR j IN 1 .. l_posit_plan_struct.count
        LOOP
            --in case is the first record or the current record is different the previous record so isn't necessary
            -- to compare these records
            l_tbl_tbl_tags_exec.extend();
            IF (j = 1)
               OR
               (l_posit_plan_struct(j - 1).id_epis_positioning_plan != l_posit_plan_struct(j).id_epis_positioning_plan)
               OR (l_posit_plan_struct(j).id_epis_posit_plan_hist IS NOT NULL)
            THEN
                -- execution identifier (for example execution (1))
                l_counter := l_counter + 1;
                IF NOT get_first_values_plan(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_actual_row => l_posit_plan_struct(j),
                                             i_counter    => l_counter,
                                             i_labels     => l_inp_code_messages,
                                             i_flg_screen => g_flg_screen_detail,
                                             o_tbl_labels => l_tbl_lables,
                                             o_tbl_values => l_tbl_values,
                                             o_tbl_types  => l_tbl_types,
                                             o_tbl_tags   => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
            
                --compare current record with the previous record to check what's differences between them
                IF NOT get_values_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_episode   => i_id_episode,
                                       i_actual_row   => l_posit_plan_struct(j),
                                       i_previous_row => l_posit_plan_struct(j - 1),
                                       i_counter      => l_counter,
                                       i_labels       => l_inp_code_messages,
                                       o_tbl_labels   => l_tbl_lables,
                                       o_tbl_values   => l_tbl_values,
                                       o_tbl_types    => l_tbl_types,
                                       o_tbl_tags     => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        
            l_tab_hist_exec.extend;
            l_tab_hist_exec(l_tab_hist_exec.count) := t_rec_history_data(id_rec          => CASE
                                                                                                WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                                 l_posit_plan_struct(j).id_epis_positioning_plan
                                                                                                ELSE
                                                                                                 l_posit_plan_struct(j).id_epis_posit_plan_hist
                                                                                            END,
                                                                         flg_status      => l_posit_plan_struct(j).flg_status,
                                                                         date_rec        => l_posit_plan_struct(j).dt_epis_positioning_plan,
                                                                         tbl_labels      => l_tbl_lables,
                                                                         tbl_values      => l_tbl_values,
                                                                         tbl_types       => l_tbl_types,
                                                                         tbl_info_labels => pk_inp_detail.get_info_labels,
                                                                         tbl_info_values => pk_inp_detail.get_info_values(l_posit_plan_struct(j).flg_status),
                                                                         table_origin    => CASE
                                                                                                WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                                 'EPIS_POSITIONING_PLAN'
                                                                                                ELSE
                                                                                                 'EPIS_POSITIONING_PLAN_HIST'
                                                                                            END);
        END LOOP;
    
        --OBTAINING REQUISITION DATA
        FOR i IN l_tab_hist_req.first .. l_tab_hist_req.last
        LOOP
            l_req_data.extend();
            l_req_data(l_req_data.count) := l_tab_hist_req(i);
            l_req_data(l_req_data.count).tbl_values.extend(); --WHITE_LINE
        
            l_tbl_values_aux_req.extend(l_tab_hist_req(i).tbl_values.count);
        
            FOR j IN 1 .. l_tab_hist_req(i).tbl_values.count
            LOOP
                l_tbl_values_aux_req(l_previous_size + j) := l_req_data(l_req_data.count).tbl_values(j);
                l_tbl_req_id.extend();
                l_tbl_req_id(l_tbl_req_id.count) := i - 1;
            END LOOP;
            l_tbl_values_aux_req.extend(); --WHITE_LINE
            l_tbl_req_id.extend(); --WHITE_LINE
        
            l_previous_size := l_previous_size + l_tab_hist_req(i).tbl_values.count + 1; --+1 FOR WHITE_LINE
        END LOOP;
    
        l_previous_size := 0;
    
        --OBTAINING EXECUTION DATA
        IF l_tab_hist_exec.exists(1)
        THEN
            FOR i IN l_tab_hist_exec.first .. l_tab_hist_exec.last
            LOOP
            
                l_exec_data.extend();
                l_exec_data(l_exec_data.count) := l_tab_hist_exec(i);
            
                l_tbl_values_aux_exec.extend(l_tab_hist_exec(i).tbl_values.count);
            
                FOR j IN 1 .. l_tab_hist_exec(i).tbl_values.count
                LOOP
                    l_tbl_values_aux_exec(l_previous_size + j) := l_exec_data(l_exec_data.count).tbl_values(j);
                    l_tbl_exec_id.extend();
                    l_tbl_exec_id(l_tbl_exec_id.count) := i - 1;
                END LOOP;
                l_tbl_values_aux_exec.extend(); --WHITE_LINE
                l_tbl_exec_id.extend(); --WHITE_LINE
                --
                l_previous_size := l_previous_size + l_tab_hist_exec(i).tbl_values.count + 1; --+1 FOR WHITE_LINE
                l_tbl_count.extend();
                l_tbl_count(l_tbl_count.count) := l_tab_hist_exec(i).tbl_values.count;
            
            END LOOP;
        END IF;
    
        FOR i IN l_tbl_tbl_tags_req.first .. l_tbl_tbl_tags_req.last
        LOOP
            FOR j IN l_tbl_tbl_tags_req(i).first .. l_tbl_tbl_tags_req(i).last
            LOOP
                l_tbl_tags_req.extend();
                l_tbl_tags_req(l_tbl_tags_req.count) := l_tbl_tbl_tags_req(i) (j);
            END LOOP;
        END LOOP;
    
        IF l_tab_hist_exec.exists(1)
        THEN
            FOR i IN l_tbl_tbl_tags_exec.first .. l_tbl_tbl_tags_exec.last
            LOOP
                FOR j IN l_tbl_tbl_tags_exec(i).first .. l_tbl_tbl_tags_exec(i).last
                LOOP
                    l_tbl_tags_exec.extend();
                    l_tbl_tags_exec(l_tbl_tags_exec.count) := l_tbl_tbl_tags_exec(i) (j);
                END LOOP;
            END LOOP;
        END IF;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   id_block || exec_id || ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT tt.id_block, tags.column_value AS data_source, tt.column_value AS data_source_val, 0 AS exec_id
                  FROM (SELECT t.column_value, rownum AS rn, 1 AS id_block
                          FROM TABLE(l_tbl_values_aux_req) t) tt
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_tags_req)) tags
                    ON tags.rn = tt.rn
                UNION ALL
                SELECT tt.id_block,
                       tags.column_value AS data_source,
                       tt.column_value   AS data_source_val,
                       rownum            AS exec_id
                  FROM (SELECT t.column_value, rownum AS rn, 2 AS id_block
                          FROM TABLE(l_tbl_values_aux_exec) t) tt
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_tags_exec)) tags
                    ON tags.rn = tt.rn
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_exec_id)) t_exec_id
                    ON t_exec_id.rn = tt.rn) dd
          JOIN dd_content ddc
            ON ddc.area = 'POSITIONING'
           AND ddc.data_source = dd.data_source
           AND ddc.id_dd_block = dd.id_block
           AND ddc.flg_available = pk_alert_constant.g_yes
          LEFT JOIN dd_block ddb
            ON ddb.id_dd_block = ddc.id_dd_block
           AND ddb.area = 'POSITIONING'
           AND ddb.flg_available = pk_alert_constant.g_yes
         ORDER BY id_block, exec_id, ddb.rank;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              data_source_val, --val
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       flg_html,
                       NULL,
                       flg_clob
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.area = 'POSITIONING'
                   AND ddc.data_source = db.data_source
                   AND ddc.id_dd_block = db.id_dd_block
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND (db.data_source_val IS NOT NULL OR (flg_type IN ('L1', 'WL'))))
         ORDER BY rnk, rank;
    
        g_error := 'OPEN o_hist';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        OPEN o_hist FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                WHEN d.flg_type = 'L1' THEN
                                 d.descr || d.val
                                ELSE
                                 d.descr || ': '
                            END descr,
                           CASE
                                WHEN d.flg_type = 'L1' THEN
                                 NULL
                                ELSE
                                 d.val
                            END val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn)
             ORDER BY rn;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_positioning_detail;

    FUNCTION get_epis_positioning_detail_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_positioning IN epis_positioning.id_epis_positioning%TYPE,
        o_hist                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         VARCHAR2(50) := 'GET_EPIS_POSITIONING_DETAIL_HIST';
        l_limit             PLS_INTEGER := 1000;
        l_counter           PLS_INTEGER := 0;
        l_tbl_lables        table_varchar := table_varchar();
        l_tbl_values        table_varchar := table_varchar();
        l_tbl_types         table_varchar := table_varchar();
        l_tbl_tags_req      table_varchar := table_varchar();
        l_tbl_tbl_tags_exec table_table_varchar := table_table_varchar();
        l_tbl_tbl_tags_req  table_table_varchar := table_table_varchar();
        l_tbl_tags_exec     table_varchar := table_varchar();
        l_tab_hist_req      t_table_history_data := t_table_history_data();
        l_tab_hist_exec     t_table_history_data := t_table_history_data();
        ---
        l_req_data            t_table_history_data := t_table_history_data();
        l_exec_data           t_table_history_data := t_table_history_data();
        l_tbl_values_aux_req  table_varchar := table_varchar();
        l_tbl_values_aux_exec table_varchar := table_varchar();
        l_previous_size       NUMBER := 0;
        l_tbl_count           table_number := table_number();
        l_tbl_exec_id         table_number := table_number();
        l_tbl_req_id          table_number := table_number();
        --
        l_tab_dd_block_data t_tab_dd_block_data;
        l_tab_dd_data       t_tab_dd_data := t_tab_dd_data();
        l_data_source_list  table_varchar := table_varchar();
    
        l_inp_code_messages       t_code_messages;
        l_inp_posit_code_messages table_varchar2 := table_varchar2('POSITIONING_T029',
                                                                   'POSITIONING_T030',
                                                                   'POSITIONING_T023',
                                                                   'POSITIONING_T024',
                                                                   'COMMON_M107',
                                                                   'POSITIONING_T025',
                                                                   'COMMON_M108',
                                                                   'POSITIONING_T026',
                                                                   'POSITIONING_T027',
                                                                   'POSITIONING_T028',
                                                                   'POSITIONING_M003',
                                                                   'POSITIONING_M004',
                                                                   'POSITIONING_M005',
                                                                   'POSITIONING_M006',
                                                                   'POSITIONING_M007',
                                                                   'POSITIONING_M008',
                                                                   'POSITIONING_M009',
                                                                   'POSITIONING_M010',
                                                                   'POSITIONING_M011',
                                                                   'POSITIONING_M012',
                                                                   'POSITIONING_M013',
                                                                   'POSITIONING_M014',
                                                                   'POSITIONING_M015',
                                                                   'POSITIONING_M016',
                                                                   'POSITIONING_M017',
                                                                   'POSITIONING_M018',
                                                                   'POSITIONING_M019',
                                                                   'POSITIONING_M020',
                                                                   'COMMON_M108',
                                                                   'COMMON_M106',
                                                                   'POSITIONING_M021',
                                                                   'POSITIONING_M022',
                                                                   'MED_PRESC_T088',
                                                                   'POSITIONING_M023',
                                                                   'POSITIONING_M024',
                                                                   'POSITIONING_M025',
                                                                   'POSITIONING_M028',
                                                                   'POSITIONING_M029',
                                                                   'POSITIONING_M030',
                                                                   'POSITIONING_M031',
                                                                   'POSITIONING_M032',
                                                                   'POSITIONING_M033');
    
        CURSOR c_get_positionings_req IS
            SELECT *
              FROM (SELECT eph.*
                      FROM epis_positioning_hist eph
                     WHERE eph.id_epis_positioning = i_id_epis_positioning
                    UNION ALL
                    SELECT NULL id_epis_positioning_hist, ep.*
                      FROM epis_positioning ep
                     WHERE ep.id_epis_positioning = i_id_epis_positioning) t
             ORDER BY id_epis_positioning_hist DESC NULLS FIRST;
    
        TYPE c_positioning_req IS TABLE OF c_get_positionings_req%ROWTYPE;
        l_positioning_req  c_positioning_req;
        l_posit_req_struct c_positioning_req := c_positioning_req();
    
        CURSOR c_get_positionings_plan IS
            SELECT *
              FROM (SELECT CASE lag(ttt.flg_status, 1) over(ORDER BY ttt.id_epis_positioning_plan ASC)
                               WHEN g_epis_posit_f THEN
                                -1 --dummy value to indicate that it is a new execution
                               ELSE
                                NULL
                           END id_epis_posit_plan_hist,
                           ttt.*
                      FROM (SELECT coalesce(epp.id_epis_positioning_plan, epph.id_epis_positioning_plan) id_epis_positioning_plan,
                                   coalesce(epp.id_epis_positioning_det, epph.id_epis_positioning_det) id_epis_positioning_det,
                                   coalesce(epp.id_epis_positioning_next, epph.id_epis_positioning_next) id_epis_positioning_next,
                                   coalesce(epp.id_prof_exec, epph.id_prof_exec) id_prof_exec,
                                   CASE epp.flg_status
                                       WHEN g_epis_posit_o THEN
                                        decode(epph.flg_status, g_epis_posit_d, g_epis_posit_d, g_epis_posit_e)
                                       ELSE
                                        coalesce(epp.flg_status, epph.flg_status)
                                   END flg_status,
                                   epp.notes,
                                   coalesce(epp.dt_execution_tstz, epph.dt_execution_tstz) dt_execution_tstz,
                                   coalesce(epp.dt_prev_plan_tstz, epph.dt_prev_plan_tstz) dt_prev_plan_tstz,
                                   epp.create_user,
                                   epp.create_time,
                                   epp.create_institution,
                                   epp.update_user,
                                   epp.update_time,
                                   epp.update_institution,
                                   coalesce(epp.dt_epis_positioning_plan, epph.dt_epis_positioning_plan) dt_epis_positioning_plan
                              FROM (SELECT t.*,
                                           row_number() over(PARTITION BY t.dt_prev_plan_tstz, t.id_positioning, t.id_positioning_next, t.flg_status ORDER BY t.dt_epis_positioning_plan ASC) AS rn
                                      FROM (SELECT DISTINCT l.*
                                              FROM (SELECT (SELECT epd.id_positioning
                                                              FROM epis_positioning_det epd
                                                             WHERE epd.id_epis_positioning_det = p.id_epis_positioning_det) AS id_positioning,
                                                           (SELECT epd.id_positioning
                                                              FROM epis_positioning_det epd
                                                             WHERE epd.id_epis_positioning_det = p.id_epis_positioning_next) AS id_positioning_next,
                                                           p.dt_prev_plan_tstz,
                                                           p.dt_execution_tstz,
                                                           CASE
                                                                WHEN p.flg_status = g_epis_posit_o THEN
                                                                 g_epis_posit_e
                                                                ELSE
                                                                 p.flg_status
                                                            END flg_status,
                                                           p.dt_epis_positioning_plan
                                                      FROM epis_positioning_plan p
                                                      JOIN epis_positioning_det epd
                                                        ON p.id_epis_positioning_det = epd.id_epis_positioning_det
                                                     WHERE epd.id_epis_positioning = i_id_epis_positioning
                                                       AND p.flg_status <> g_epis_posit_o
                                                    UNION
                                                    SELECT (SELECT epd.id_positioning
                                                              FROM epis_positioning_det epd
                                                             WHERE epd.id_epis_positioning_det = eph.id_epis_positioning_det) AS id_positioning,
                                                           (SELECT epd.id_positioning
                                                              FROM epis_positioning_det epd
                                                             WHERE epd.id_epis_positioning_det = eph.id_epis_positioning_next) AS id_positioning_next,
                                                           eph.dt_prev_plan_tstz,
                                                           eph.dt_execution_tstz,
                                                           CASE
                                                               WHEN eph.flg_status = g_epis_posit_o THEN
                                                                g_epis_posit_e
                                                               ELSE
                                                                eph.flg_status
                                                           END flg_status,
                                                           eph.dt_epis_positioning_plan
                                                      FROM epis_posit_plan_hist eph
                                                      JOIN epis_positioning_det epd
                                                        ON eph.id_epis_positioning_det = epd.id_epis_positioning_det
                                                     WHERE epd.id_epis_positioning = i_id_epis_positioning
                                                       AND eph.flg_status <> g_epis_posit_o) l) t) tt
                              LEFT JOIN epis_positioning_plan epp
                                ON epp.dt_epis_positioning_plan = tt.dt_epis_positioning_plan
                               AND epp.dt_prev_plan_tstz = tt.dt_prev_plan_tstz
                               AND (epp.dt_execution_tstz = tt.dt_execution_tstz OR
                                   (epp.dt_execution_tstz IS NULL AND tt.dt_execution_tstz IS NULL))
                               AND epp.id_epis_positioning_det IN
                                   (SELECT e.id_epis_positioning_det
                                      FROM epis_positioning_det e
                                     WHERE e.id_epis_positioning IN (i_id_epis_positioning))
                              LEFT JOIN epis_posit_plan_hist epph
                                ON epph.dt_epis_positioning_plan = tt.dt_epis_positioning_plan
                               AND epph.dt_prev_plan_tstz = tt.dt_prev_plan_tstz
                               AND (epph.dt_execution_tstz = tt.dt_execution_tstz OR
                                   (epph.dt_execution_tstz IS NULL AND tt.dt_execution_tstz IS NULL))
                               AND epph.id_epis_positioning_det IN
                                   (SELECT e.id_epis_positioning_det
                                      FROM epis_positioning_det e
                                     WHERE e.id_epis_positioning IN (i_id_epis_positioning))
                             WHERE tt.rn = 1) ttt)
             ORDER BY dt_epis_positioning_plan, id_epis_positioning_plan;
    
        TYPE c_positioning_plan IS TABLE OF c_get_positionings_plan%ROWTYPE;
        l_positioning_plan  c_positioning_plan;
        l_posit_plan_struct c_positioning_plan := c_positioning_plan();
    
        PROCEDURE parse_history IS
            l_rn_tag PLS_INTEGER := 1;
        BEGIN
            DELETE FROM tbl_temp;
        
            FOR i IN l_tbl_values_aux_exec.first .. l_tbl_values_aux_exec.last
            LOOP
                INSERT INTO tbl_temp
                    (num_1, num_2, vc_1, vc_2, vc_3)
                VALUES
                    (1, l_rn_tag, l_tbl_values_aux_exec(i), l_tbl_tags_exec(i), l_tbl_exec_id(i));
            
                IF l_tbl_tags_exec(i) = 'WHITE_LINE'
                THEN
                    l_rn_tag := l_rn_tag + 1;
                END IF;
            END LOOP;
        END parse_history;
    
    BEGIN
        -- fill all translations in collection
        FOR i IN l_inp_posit_code_messages.first .. l_inp_posit_code_messages.last
        LOOP
            l_inp_code_messages(l_inp_posit_code_messages(i)) := pk_message.get_message(i_lang,
                                                                                        l_inp_posit_code_messages(i));
        END LOOP;
    
        -- get positionings requisition records
        g_error := 'OPEN C_GET_POSITIONINGS_REQ CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_positionings_req;
        LOOP
            FETCH c_get_positionings_req BULK COLLECT
                INTO l_positioning_req LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_req.count
            LOOP
                l_posit_req_struct.extend;
                l_posit_req_struct(l_posit_req_struct.count) := l_positioning_req(i);
            END LOOP;
            EXIT WHEN c_get_positionings_req%NOTFOUND;
        END LOOP;
    
        FOR c IN 1 .. l_posit_req_struct.count
        LOOP
            --last record doesn't need to be compared
            IF (c = l_posit_req_struct.count)
            THEN
                g_error := 'call get_first_values_req';
                pk_alertlog.log_debug(g_error);
                l_tbl_tbl_tags_req.extend();
                IF NOT get_first_values_req(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_actual_row => l_posit_req_struct(l_posit_req_struct.count),
                                            i_labels     => l_inp_code_messages,
                                            i_flg_screen => pk_inp_positioning.g_flg_screen_history,
                                            o_tbl_labels => l_tbl_lables,
                                            o_tbl_values => l_tbl_values,
                                            o_tbl_types  => l_tbl_types,
                                            o_tbl_tags   => l_tbl_tbl_tags_req(l_tbl_tbl_tags_req.count))
                THEN
                    RETURN FALSE;
                END IF;
            
            ELSE
                l_tbl_tbl_tags_req.extend();
                --compare current record with the next record to check what's differences between them
                g_error := 'call get_values_req';
                pk_alertlog.log_debug(g_error);
                IF NOT get_values_req(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_actual_row   => l_posit_req_struct(c),
                                      i_previous_row => l_posit_req_struct(c + 1),
                                      i_labels       => l_inp_code_messages,
                                      o_tbl_labels   => l_tbl_lables,
                                      o_tbl_values   => l_tbl_values,
                                      o_tbl_types    => l_tbl_types,
                                      o_tbl_tags     => l_tbl_tbl_tags_req(l_tbl_tbl_tags_req.count))
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            l_tab_hist_req.extend;
            l_tab_hist_req(l_tab_hist_req.count) := t_rec_history_data(id_rec => CASE
                                                                                     WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                                      l_posit_req_struct(c).id_epis_positioning
                                                                                     ELSE
                                                                                      l_posit_req_struct(c).id_epis_positioning_hist
                                                                                 END,
                                                                       
                                                                       flg_status      => l_posit_req_struct(c).flg_status,
                                                                       date_rec        => l_posit_req_struct(c).dt_epis_positioning,
                                                                       tbl_labels      => l_tbl_lables,
                                                                       tbl_values      => l_tbl_values,
                                                                       tbl_types       => l_tbl_types,
                                                                       tbl_info_labels => pk_inp_detail.get_info_labels,
                                                                       tbl_info_values => pk_inp_detail.get_info_values(l_posit_req_struct(c).flg_status),
                                                                       table_origin    => CASE
                                                                                              WHEN l_posit_req_struct(c).id_epis_positioning_hist IS NULL THEN
                                                                                               'EPIS_POSITIONING'
                                                                                              ELSE
                                                                                               'EPIS_POSITIONING_HIST'
                                                                                          END);
        
        END LOOP;
    
        -- get positionings plan records
        OPEN c_get_positionings_plan;
        LOOP
            FETCH c_get_positionings_plan BULK COLLECT
                INTO l_positioning_plan LIMIT l_limit;
        
            FOR i IN 1 .. l_positioning_plan.count
            LOOP
                l_posit_plan_struct.extend;
                l_posit_plan_struct(l_posit_plan_struct.count) := l_positioning_plan(i);
            END LOOP;
            EXIT WHEN c_get_positionings_plan%NOTFOUND;
        END LOOP;
    
        FOR j IN 1 .. l_posit_plan_struct.count
        LOOP
            --in case is the first record or the current record is different the previous record so isn't necessary
            -- to compare these records
            l_tbl_tbl_tags_exec.extend();
            IF (j = 1)
               OR (l_posit_plan_struct(j).id_epis_posit_plan_hist IS NOT NULL)
            THEN
                -- execution identifier (for example execution (1))
                l_counter := l_counter + 1;
                IF NOT get_first_values_plan(i_lang       => i_lang,
                                             i_prof       => i_prof,
                                             i_id_episode => i_id_episode,
                                             i_actual_row => l_posit_plan_struct(j),
                                             i_counter    => l_counter,
                                             i_labels     => l_inp_code_messages,
                                             i_flg_screen => pk_inp_positioning.g_flg_screen_history,
                                             o_tbl_labels => l_tbl_lables,
                                             o_tbl_values => l_tbl_values,
                                             o_tbl_types  => l_tbl_types,
                                             o_tbl_tags   => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
            
                --compare current record with the previous record to check what's differences between them
                IF NOT get_values_plan(i_lang         => i_lang,
                                       i_prof         => i_prof,
                                       i_id_episode   => i_id_episode,
                                       i_actual_row   => l_posit_plan_struct(j),
                                       i_previous_row => l_posit_plan_struct(j - 1),
                                       i_counter      => l_counter,
                                       i_labels       => l_inp_code_messages,
                                       o_tbl_labels   => l_tbl_lables,
                                       o_tbl_values   => l_tbl_values,
                                       o_tbl_types    => l_tbl_types,
                                       o_tbl_tags     => l_tbl_tbl_tags_exec(l_tbl_tbl_tags_exec.count))
                THEN
                    RETURN FALSE;
                END IF;
            
            END IF;
        
            l_tab_hist_exec.extend;
            l_tab_hist_exec(l_tab_hist_exec.count) := t_rec_history_data(id_rec          => CASE
                                                                                                WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                                 l_posit_plan_struct(j).id_epis_positioning_plan
                                                                                                ELSE
                                                                                                 l_posit_plan_struct(j).id_epis_posit_plan_hist
                                                                                            END,
                                                                         flg_status      => l_posit_plan_struct(j).flg_status,
                                                                         date_rec        => l_posit_plan_struct(j).dt_epis_positioning_plan,
                                                                         tbl_labels      => l_tbl_lables,
                                                                         tbl_values      => l_tbl_values,
                                                                         tbl_types       => l_tbl_types,
                                                                         tbl_info_labels => pk_inp_detail.get_info_labels,
                                                                         tbl_info_values => pk_inp_detail.get_info_values(l_posit_plan_struct(j).flg_status),
                                                                         table_origin    => CASE
                                                                                                WHEN l_posit_plan_struct(j).id_epis_posit_plan_hist IS NULL THEN
                                                                                                 'EPIS_POSITIONING_PLAN'
                                                                                                ELSE
                                                                                                 'EPIS_POSITIONING_PLAN_HIST'
                                                                                            END);
        END LOOP;
    
        --OBTAINING REQUISITION DATA
        FOR i IN l_tab_hist_req.first .. l_tab_hist_req.last
        LOOP
            l_req_data.extend();
            l_req_data(l_req_data.count) := l_tab_hist_req(i);
            l_req_data(l_req_data.count).tbl_values.extend(); --WHITE_LINE
        
            l_tbl_values_aux_req.extend(l_tab_hist_req(i).tbl_values.count);
        
            FOR j IN 1 .. l_tab_hist_req(i).tbl_values.count
            LOOP
                l_tbl_values_aux_req(l_previous_size + j) := l_req_data(l_req_data.count).tbl_values(j);
                l_tbl_req_id.extend();
                l_tbl_req_id(l_tbl_req_id.count) := i - 1;
            END LOOP;
            l_tbl_values_aux_req.extend(); --WHITE_LINE
            l_tbl_req_id.extend(); --WHITE_LINE
        
            l_previous_size := l_previous_size + l_tab_hist_req(i).tbl_values.count + 1; --+1 FOR WHITE_LINE
        END LOOP;
    
        l_previous_size := 0;
    
        --OBTAINING EXECUTION DATA
        IF l_tab_hist_exec.exists(1)
        THEN
            FOR i IN l_tab_hist_exec.first .. l_tab_hist_exec.last
            LOOP
            
                l_exec_data.extend();
                l_exec_data(l_exec_data.count) := l_tab_hist_exec(i);
            
                l_tbl_values_aux_exec.extend(l_tab_hist_exec(i).tbl_values.count);
            
                FOR j IN 1 .. l_tab_hist_exec(i).tbl_values.count
                LOOP
                    l_tbl_values_aux_exec(l_previous_size + j) := l_exec_data(l_exec_data.count).tbl_values(j);
                    l_tbl_exec_id.extend();
                    l_tbl_exec_id(l_tbl_exec_id.count) := i - 1;
                END LOOP;
            
                l_tbl_values_aux_exec.extend(); --WHITE_LINE
                l_tbl_exec_id.extend(); --WHITE_LINE
                --
                l_previous_size := l_previous_size + l_tab_hist_exec(i).tbl_values.count + 1; --+1 FOR WHITE_LINE
                l_tbl_count.extend();
                l_tbl_count(l_tbl_count.count) := l_tab_hist_exec(i).tbl_values.count;
            END LOOP;
        END IF;
    
        FOR i IN l_tbl_tbl_tags_req.first .. l_tbl_tbl_tags_req.last
        LOOP
            FOR j IN l_tbl_tbl_tags_req(i).first .. l_tbl_tbl_tags_req(i).last
            LOOP
                l_tbl_tags_req.extend();
                l_tbl_tags_req(l_tbl_tags_req.count) := l_tbl_tbl_tags_req(i) (j);
            END LOOP;
        END LOOP;
    
        IF l_tab_hist_exec.exists(1)
        THEN
            FOR i IN l_tbl_tbl_tags_exec.first .. l_tbl_tbl_tags_exec.last
            LOOP
                FOR j IN l_tbl_tbl_tags_exec(i).first .. l_tbl_tbl_tags_exec(i).last
                LOOP
                    l_tbl_tags_exec.extend();
                    l_tbl_tags_exec(l_tbl_tags_exec.count) := l_tbl_tbl_tags_exec(i) (j);
                END LOOP;
            END LOOP;
        END IF;
    
        --É necessário reverter o histórico por causa da uniformização dos detalhes
        parse_history;
    
        SELECT t_rec_dd_block_data(ddb.id_dd_block,
                                   --id_block || exec_id || rn_req || ddb.rank,
                                   id_block || rn_req || ddb.rank,
                                   NULL,
                                   NULL,
                                   ddb.condition_val,
                                   NULL,
                                   NULL,
                                   dd.data_source,
                                   dd.data_source_val,
                                   NULL)
          BULK COLLECT
          INTO l_tab_dd_block_data
          FROM (SELECT tt.id_block,
                       tags.column_value AS data_source,
                       tt.column_value   AS data_source_val,
                       NULL              AS exec_id,
                       tt.rn             AS rn_req
                  FROM (SELECT t.column_value, rownum AS rn, 1 AS id_block
                          FROM TABLE(l_tbl_values_aux_req) t) tt
                  JOIN (SELECT column_value, rownum AS rn
                         FROM TABLE(l_tbl_tags_req)) tags
                    ON tags.rn = tt.rn
                UNION ALL
                SELECT 2 id_block,
                       tt.vc_2 data_source,
                       tt.vc_1 AS data_source_val,
                       rownum AS exec_id,
                       (tt.num_2 * 100 + tt.num_1) AS rn_req
                  FROM tbl_temp tt) dd
          JOIN dd_content ddc
            ON ddc.area = 'POSITIONING'
           AND ddc.data_source = dd.data_source
           AND ddc.id_dd_block = dd.id_block
           AND ddc.flg_available = pk_alert_constant.g_yes
          LEFT JOIN dd_block ddb
            ON ddb.id_dd_block = ddc.id_dd_block
           AND ddb.area = 'POSITIONING'
           AND ddb.flg_available = pk_alert_constant.g_yes;
    
        SELECT t_rec_dd_data(CASE
                                  WHEN data_code_message IS NOT NULL THEN
                                   pk_message.get_message(i_lang => i_lang, i_code_mess => data_code_message)
                                  ELSE
                                   NULL
                              END, --DESCR
                              data_source_val, --val
                              flg_type,
                              flg_html,
                              NULL,
                              flg_clob), --TYPE
               data_source
          BULK COLLECT
          INTO l_tab_dd_data, l_data_source_list
          FROM (SELECT ddc.data_code_message,
                       flg_type,
                       data_source_val,
                       ddc.data_source,
                       db.rnk,
                       rank,
                       flg_html,
                       flg_clob,
                       ddc.id_dd_block
                  FROM TABLE(l_tab_dd_block_data) db
                  JOIN dd_content ddc
                    ON ddc.area = 'POSITIONING'
                   AND ddc.data_source = db.data_source
                   AND ddc.id_dd_block = db.id_dd_block
                   AND ddc.flg_available = pk_alert_constant.g_yes
                   AND (db.data_source_val IS NOT NULL OR (flg_type IN ('L1', 'WL'))))
         ORDER BY id_dd_block DESC,
                  CASE id_dd_block
                      WHEN 1 THEN
                       rnk
                  END ASC,
                  CASE id_dd_block
                      WHEN 2 THEN
                       rnk
                  END DESC,
                  rank;
    
        g_error := 'OPEN o_hist';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        OPEN o_hist FOR
            SELECT descr, val, flg_type, flg_html, val_clob, flg_clob
              FROM (SELECT CASE
                                WHEN d.val IS NULL THEN
                                 d.descr
                                WHEN d.descr IS NULL THEN
                                 NULL
                                WHEN d.flg_type = 'L1' THEN
                                 d.descr || d.val
                                ELSE
                                 d.descr || ': '
                            END descr,
                           CASE
                                WHEN d.flg_type = 'L1' THEN
                                 NULL
                                ELSE
                                 d.val
                            END val,
                           d.flg_type,
                           flg_html,
                           val_clob,
                           flg_clob,
                           d.rn
                      FROM (SELECT rownum rn, descr, val, flg_type, flg_html, val_clob, flg_clob
                              FROM TABLE(l_tab_dd_data)) d
                      JOIN (SELECT rownum rn, column_value data_source
                             FROM TABLE(l_data_source_list)) ds
                        ON ds.rn = d.rn)
             ORDER BY rn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hist);
            RETURN FALSE;
    END get_epis_positioning_detail_hist;

    FUNCTION update_epis_posit_det
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_positioning IN table_number,
        i_update_plan         IN BOOLEAN DEFAULT TRUE,
        l_rows                OUT table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(50) := 'UPDATE_EPIS_POSIT_DET';
    
        l_next_epd                 epis_positioning_det.id_epis_positioning_det%TYPE;
        l_epis_positioning         epis_positioning_det.id_epis_positioning%TYPE;
        l_id_positioning           epis_positioning_det.id_positioning%TYPE;
        l_rank                     epis_positioning_det.rank%TYPE;
        l_id_epis_positioning_plan epis_positioning_plan.id_epis_positioning_plan%TYPE;
        l_max_rank                 epis_positioning_det.rank%TYPE;
        l_id_epis_posit_next       epis_positioning_det.id_epis_positioning_det%TYPE;
    
        l_tbl_epis_positioning_det     table_number;
        l_tbl_epis_positioning_plan    table_number := table_number();
        l_tbl_epis_positioning_det_aux table_number := table_number();
    
        l_rowids table_varchar;
    BEGIN
    
        --UPDATE EPIS_POSITIONING_DET
        g_error := 'GET L_TBL_EPIS_POSITIONING_DET';
        SELECT epd.id_epis_positioning_det
          BULK COLLECT
          INTO l_tbl_epis_positioning_det
          FROM epis_positioning_det epd
         WHERE epd.id_epis_positioning IN (SELECT *
                                             FROM TABLE(i_id_epis_positioning))
           AND epd.flg_outdated = pk_alert_constant.g_no;
    
        g_error := 'CALLING SET_EPIS_POSIT_DET_HIST';
        IF NOT set_epis_posit_det_hist(i_lang                    => i_lang,
                                       i_prof                    => i_prof,
                                       i_id_epis_positioning_det => l_tbl_epis_positioning_det,
                                       o_error                   => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'UPDATING EPIS_POSITIONING_DET';
        FOR i IN l_tbl_epis_positioning_det.first .. l_tbl_epis_positioning_det.last
        LOOP
        
            ts_epis_positioning_det.upd(id_epis_positioning_det_in => l_tbl_epis_positioning_det(i),
                                        flg_outdated_in            => pk_alert_constant.g_yes,
                                        rows_out                   => l_rowids);
        
            g_error    := 'GET SEQ_EPIS_POSITIONING_DET.NEXTVAL';
            l_next_epd := ts_epis_positioning_det.next_key();
        
            SELECT epd.id_epis_positioning, epd.id_positioning, epd.rank
              INTO l_epis_positioning, l_id_positioning, l_rank
              FROM epis_positioning_det epd
             WHERE epd.id_epis_positioning_det = l_tbl_epis_positioning_det(i);
        
            ts_epis_positioning_det.ins(id_epis_positioning_det_in => l_next_epd,
                                        id_epis_positioning_in     => l_epis_positioning,
                                        id_positioning_in          => l_id_positioning,
                                        rank_in                    => l_rank,
                                        adw_last_update_in         => g_sysdate_tstz,
                                        id_prof_last_upd_in        => i_prof.id,
                                        dt_epis_positioning_det_in => g_sysdate_tstz,
                                        rows_out                   => l_rowids);
        
            IF i_update_plan = TRUE
            THEN
                BEGIN
                    SELECT epp.id_epis_positioning_plan
                      INTO l_id_epis_positioning_plan
                      FROM epis_positioning_plan epp
                     WHERE epp.id_epis_positioning_det = l_tbl_epis_positioning_det(i);
                
                    l_tbl_epis_positioning_plan.extend();
                    l_tbl_epis_positioning_plan(l_tbl_epis_positioning_plan.count) := l_id_epis_positioning_plan;
                
                    l_tbl_epis_positioning_det_aux.extend();
                    l_tbl_epis_positioning_det_aux(l_tbl_epis_positioning_det_aux.count) := l_next_epd;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        CONTINUE;
                END;
            END IF;
        END LOOP;
    
        IF i_update_plan = TRUE
        THEN
            FOR i IN l_tbl_epis_positioning_plan.first .. l_tbl_epis_positioning_plan.last
            LOOP
            
                SELECT MAX(rank)
                  INTO l_max_rank
                  FROM epis_positioning_det epd
                 WHERE epd.id_epis_positioning IN
                       (SELECT epd_i.id_epis_positioning
                          FROM epis_positioning_det epd_i
                         WHERE epd_i.id_epis_positioning_det = l_tbl_epis_positioning_det_aux(i))
                   AND epd.flg_outdated = pk_alert_constant.g_no;
            
                SELECT epd.rank
                  INTO l_rank
                  FROM epis_positioning_det epd
                 WHERE epd.id_epis_positioning_det = l_tbl_epis_positioning_det_aux(i)
                   AND epd.flg_outdated = pk_alert_constant.g_no;
            
                IF l_max_rank = l_rank
                THEN
                    SELECT epd.id_epis_positioning_det
                      INTO l_id_epis_posit_next
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning IN
                           (SELECT epd_i.id_epis_positioning
                              FROM epis_positioning_det epd_i
                             WHERE epd_i.id_epis_positioning_det = l_tbl_epis_positioning_det_aux(i))
                       AND epd.flg_outdated = pk_alert_constant.g_no
                       AND epd.rank = 1;
                ELSE
                    SELECT epd.id_epis_positioning_det
                      INTO l_id_epis_posit_next
                      FROM epis_positioning_det epd
                     WHERE epd.id_epis_positioning IN
                           (SELECT epd_i.id_epis_positioning
                              FROM epis_positioning_det epd_i
                             WHERE epd_i.id_epis_positioning_det = l_tbl_epis_positioning_det_aux(i))
                       AND epd.flg_outdated = pk_alert_constant.g_no
                       AND epd.rank = l_rank + 1;
                END IF;
            
                ts_epis_positioning_plan.upd(id_epis_positioning_plan_in => l_tbl_epis_positioning_plan(i),
                                             id_epis_positioning_det_in  => l_tbl_epis_positioning_det_aux(i),
                                             id_epis_positioning_next_in => l_id_epis_posit_next,
                                             dt_epis_positioning_plan_in => g_sysdate_tstz,
                                             rows_out                    => l_rowids);
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END update_epis_posit_det;

    /********************************************************************************************
    * Check if the positioning record can be cancelled or interrupted
    *
    * @param       i_lang                    language id
    * @param       i_prof                    professional information
    * @param       i_id_episode              Episode ID
    * 
    * @param       o_action                  'C' - to be cancelled; 'I' - to be interrupted
    *
    * @author                                Filipe Silva                       
    * @version                               2.6.1                                    
    * @since                                 2011/04/06       
    ********************************************************************************************/
    FUNCTION check_cancel_interrupt_posit
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN epis_positioning.id_episode%TYPE,
        o_action     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'CHECK_CANCEL_INTERRUPT_POSIT';
        l_count         PLS_INTEGER;
    
    BEGIN
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_positioning ep
         WHERE ep.id_episode = i_id_episode
           AND ep.flg_status = g_epis_posit_r;
    
        IF l_count = 0
        THEN
            o_action := g_epis_posit_i;
        ELSE
            o_action := g_epis_posit_c;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END check_cancel_interrupt_posit;

    FUNCTION get_positioning_rel
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_posit_type IN positioning_instit_soft.posit_type%TYPE,
        o_data       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_POSITIONING_REL';
    
    BEGIN
    
        g_error := 'OPEN o_data';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT t.id_positioning,
                   (CAST(MULTISET
                         (SELECT decode(spr.id_sr_posit, t.id_positioning, spr.id_sr_posit_relation, spr.id_sr_posit)
                            FROM sr_posit_rel spr
                           WHERE (spr.id_sr_posit = t.id_positioning OR spr.id_sr_posit_relation = t.id_positioning)
                             AND spr.flg_available = pk_alert_constant.g_yes
                             AND spr.flg_type = g_flg_type_e) AS table_number)) exclusive_rel
              FROM (SELECT DISTINCT p.id_positioning,
                                    rank() over(ORDER BY pis.id_institution DESC, pis.id_software DESC) origin_rank
                      FROM positioning p
                      JOIN positioning_instit_soft pis
                        ON pis.id_positioning = p.id_positioning
                       AND pis.id_institution = i_prof.institution
                       AND pis.id_software = i_prof.software
                     WHERE p.flg_available = pk_alert_constant.g_yes
                       AND pis.posit_type IS NOT NULL
                       AND pis.posit_type = i_posit_type
                       AND pis.flg_available = pk_alert_constant.g_yes
                       AND pis.id_positioning IN
                           (SELECT spr.id_sr_posit AS id_positioning
                              FROM sr_posit_rel spr
                             WHERE (spr.id_sr_posit = p.id_positioning OR spr.id_sr_posit_relation = p.id_positioning)
                               AND spr.flg_available = pk_alert_constant.g_yes
                               AND spr.flg_type = g_flg_type_e
                            UNION
                            SELECT spr.id_sr_posit_relation AS id_positioning
                              FROM sr_posit_rel spr
                             WHERE (spr.id_sr_posit = p.id_positioning OR spr.id_sr_posit_relation = p.id_positioning)
                               AND spr.flg_available = pk_alert_constant.g_yes
                               AND spr.flg_type = g_flg_type_e)) t
             WHERE t.origin_rank = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(i_cursor => o_data);
            RETURN FALSE;
    END get_positioning_rel;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
    g_flg_available := 'Y';
    --
    g_yes_no     := 'YES_NO';
    g_pos_type_s := 2;
    g_notes_y    := 'YES';
    g_notes_n    := 'NO';
    --
    g_epis_pos_status := 'EPIS_POSITIONING.FLG_STATUS';
    --
    g_flg_doctor := 'D';
    g_date       := 'D';
END pk_inp_positioning;
/
