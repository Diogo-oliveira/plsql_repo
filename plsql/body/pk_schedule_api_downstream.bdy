/*-- Last Change Revision: $Rev: 2053893 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-30 14:20:45 +0000 (sex, 30 dez 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_schedule_api_downstream IS

    -- Private type declarations  

    -- Private constant declarations
    k_alert_hhc_approve_sched CONSTANT NUMBER := 332;
    k_alert_hhc_undo_sched    CONSTANT NUMBER := 333;

    -- Private variable declarations
    g_invalid_data     EXCEPTION;
    g_inv_data_msg     VARCHAR2(200);
    g_func_exception   EXCEPTION;
    g_invalid_schedule EXCEPTION;

    --****************** Alertas for HHC
    FUNCTION create_alert_event
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_sys_alert     IN NUMBER,
        i_id_sys_alert_del IN NUMBER,
        i_id_schedule      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION generate_hhc_alerts
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER,
        i_flg_status  IN VARCHAR2
    ) RETURN BOOLEAN;

    -- Function and procedure implementations

    /* private function for getting id_content mappings to event and dcs.
    *
    */
    PROCEDURE get_appointment_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_appointment IN appointment.id_appointment%TYPE,
        i_id_department  IN dep_clin_serv.id_department%TYPE,
        o_id_sch_event   OUT appointment.id_sch_event%TYPE,
        o_id_dcs         OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_flg_avail      OUT appointment.flg_available%TYPE,
        o_exists         OUT BOOLEAN,
        o_trans          OUT translation.desc_lang_1%TYPE
    ) IS
    BEGIN
        o_exists := TRUE;
    
        g_error := 'GET ID_APPOINTMENT DATA';
        SELECT c.id_sch_event,
               c.flg_available,
               pk_translation.get_translation(i_lang, c.code_appointment),
               (SELECT dcs.id_dep_clin_serv
                  FROM dep_clin_serv dcs
                 WHERE dcs.id_clinical_service = c.id_clinical_service
                   AND dcs.id_department = i_id_department
                   AND rownum = 1)
          INTO o_id_sch_event, o_flg_avail, o_trans, o_id_dcs
          FROM appointment c
         WHERE c.id_appointment = i_id_appointment
           AND rownum = 1;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_exists := FALSE;
    END get_appointment_data;

    /*
    * retorna a flg_available da exam para o exam fornecido.
    * retorna a traducao para eventual uso em mensagem de erro.
    * retorna o_exists = false se o exame nao foi encontrado e true se foi.
    */
    PROCEDURE get_exam_availability
    (
        i_lang       IN language.id_language%TYPE,
        i_id_content IN exam.id_content%TYPE,
        o_flg_avail  OUT exam.flg_available%TYPE,
        o_exists     OUT BOOLEAN,
        o_trans      OUT translation.desc_lang_1%TYPE
    ) IS
    BEGIN
        o_exists := TRUE;
    
        g_error := 'GET EXAM.FLG_AVAILABLE';
        SELECT flg_available, pk_translation.get_translation(i_lang, e.code_exam)
          INTO o_flg_avail, o_trans
          FROM exam e
         WHERE e.id_content = TRIM(i_id_content)
           AND e.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_exists := FALSE;
    END get_exam_availability;

    /* extract id_content from event id and dcs
    *
    */
    FUNCTION get_appointment
    (
        i_id_sch_event IN NUMBER,
        i_clin_serv    IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_app       table_varchar;
        l_appointment VARCHAR2(200 CHAR);
    BEGIN
    
        SELECT id_appointment
          BULK COLLECT
          INTO tbl_app
          FROM appointment a
         WHERE a.id_sch_event = i_id_sch_event
           AND a.id_clinical_service = i_clin_serv
           AND a.flg_available = pk_alert_constant.g_yes;
    
        IF tbl_app.count > 0
        THEN
            l_appointment := tbl_app(1);
        END IF;
    
        RETURN l_appointment;
    
    END get_appointment;

    PROCEDURE get_clin_serv_inst
    (
        i_dcs       IN NUMBER,
        o_clin_serv OUT NUMBER,
        o_inst      OUT NUMBER
    ) IS
        v_id_cs   dep_clin_serv.id_clinical_service%TYPE;
        v_id_inst department.id_institution%TYPE;
    
        tbl_data table_number;
        tbl_inst table_number;
    BEGIN
    
        SELECT dcs.id_clinical_service, d.id_institution
          BULK COLLECT
          INTO tbl_data, tbl_inst
          FROM dep_clin_serv dcs
          JOIN department d
            ON dcs.id_department = d.id_department
         WHERE dcs.id_dep_clin_serv = i_dcs;
    
        IF tbl_data.count > 0
        THEN
            o_clin_serv := tbl_data(1);
            o_inst      := tbl_inst(1);
        END IF;
    
    END get_clin_serv_inst;

    PROCEDURE get_id_content_base
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sch_event    IN appointment.id_sch_event%TYPE,
        i_id_dcs          IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_content      OUT appointment.id_appointment%TYPE,
        o_sch_event_avail OUT VARCHAR2
    ) IS
        v_id_cs           dep_clin_serv.id_clinical_service%TYPE;
        v_id_inst         department.id_institution%TYPE;
        l_sch_event_avail VARCHAR2(0100 CHAR);
    BEGIN
    
        get_clin_serv_inst(i_dcs => i_id_dcs, o_clin_serv => v_id_cs, o_inst => v_id_inst);
    
        IF v_id_cs IS NULL
        THEN
            RAISE no_data_found;
        END IF;
    
        l_sch_event_avail := pk_schedule_common.get_sch_event_avail(i_id_sch_event, v_id_inst, i_prof.software);
    
        IF l_sch_event_avail = pk_alert_constant.g_yes
        THEN
            o_id_content := get_appointment(i_id_sch_event => i_id_sch_event, i_clin_serv => v_id_cs);
        END IF;
    
        IF o_id_content IS NULL
        THEN
            RAISE no_data_found;
        END IF;
    
        o_sch_event_avail := l_sch_event_avail;
    
    END get_id_content_base;

    -- CMF ****
    FUNCTION get_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN appointment.id_sch_event%TYPE,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_content   OUT appointment.id_appointment%TYPE,
        o_flg_proceed  OUT VARCHAR2,
        o_flg_show     OUT VARCHAR2,
        o_msg_title    OUT VARCHAR2,
        o_msg          OUT VARCHAR2,
        o_button       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        v_id_cs           dep_clin_serv.id_clinical_service%TYPE;
        v_id_inst         department.id_institution%TYPE;
        l_sch_event_avail VARCHAR2(0010 CHAR);
        l_id_content      VARCHAR2(200 CHAR);
        l_msg             VARCHAR2(4000);
    
        PROCEDURE process_error_true
        (
            i_lang IN NUMBER,
            i_text IN VARCHAR2,
            i_msg  IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alertlog.log_error(text => i_text, object_name => g_package_name, owner => g_package_owner);
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
            o_msg       := pk_message.get_message(i_lang, i_msg);
            o_button    := pk_schedule.g_check_button;
        
        END process_error_true;
    
    BEGIN
        o_flg_proceed := pk_alert_constant.g_no;
        o_flg_show    := pk_alert_constant.g_no;
    
        get_id_content_base(i_lang            => i_lang,
                            i_prof            => i_prof,
                            i_id_sch_event    => i_id_sch_event,
                            i_id_dcs          => i_id_dcs,
                            o_id_content      => l_id_content,
                            o_sch_event_avail => l_sch_event_avail);
    
        IF l_sch_event_avail = pk_alert_constant.g_no
        THEN
            l_msg := 'GET EVENT CONFIG - EVENT ID ' || i_id_sch_event || ' NOT ALLOWED IN INSTITUTION ' || v_id_inst;
            process_error_true(i_lang => i_lang, i_text => l_msg, i_msg => g_event_not_config);
            RETURN TRUE;
        END IF;
    
        g_error      := 'GET ID_CONTENT';
        o_id_content := l_id_content;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            l_msg := 'GET APPOINTMENT ID FOR event id ' || i_id_sch_event || ' and dcs = ' || i_id_dcs;
            process_error_true(i_lang => i_lang, i_text => l_msg, i_msg => g_sched_msg_no_appointment);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ID_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_content;

    -- CMF 2 ****************
    FUNCTION get_id_content
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_event IN appointment.id_sch_event%TYPE,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_id_content   OUT appointment.id_appointment%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        v_id_cs           dep_clin_serv.id_clinical_service%TYPE;
        v_id_inst         department.id_institution%TYPE;
        l_sch_event_avail VARCHAR2(0010 CHAR);
        no_dcs            EXCEPTION;
        no_app            EXCEPTION;
    BEGIN
    
        get_id_content_base(i_lang            => i_lang,
                            i_prof            => i_prof,
                            i_id_sch_event    => i_id_sch_event,
                            i_id_dcs          => i_id_dcs,
                            o_id_content      => o_id_content,
                            o_sch_event_avail => l_sch_event_avail);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_CONTENT',
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_CONTENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_content;

    /* To be used by UI functions or functions that need to retrieve a id_content
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_dep_type          sch. type. C=physician app, N=nurse app, etc.
    * @param i_flg_occurr        F= first appointment, S=subsequent,  O=both
    * @param i_id_dcs            dep clin serv id
    * @param i_flg_prof           Y = this is a consult req with a specific target prof.  N = no specific target prof (specialty appoint)
    * @param o_id_content        id content as needed by scheduler 3. comes from appointment table
    * @param o_flg_proceed        Indicates if further action is to be performed by Flash.
    * @param o_flg_show           Set if a message is displayed or not
    * @param o_msg_title          Message title
    * @param o_msg                Message body to be displayed in flash
    * @param o_button             message popup buttons
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @date                       23-04-2010
    */
    FUNCTION get_id_content
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_dep_type       IN sch_event.dep_type%TYPE,
        i_flg_occurr     IN sch_event.flg_occurrence%TYPE,
        i_id_dcs         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_prof       IN VARCHAR2,
        i_domain_p1_type IN VARCHAR2 DEFAULT NULL,
        o_id_content     OUT appointment.id_appointment%TYPE,
        o_flg_proceed    OUT VARCHAR2,
        o_flg_show       OUT VARCHAR2,
        o_msg_title      OUT VARCHAR2,
        o_msg            OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sch_event sch_event.id_sch_event%TYPE;
    
        l_tbl_config t_tbl_config_table := pk_core_config.get_values_by_mkt_inst_sw(i_lang,
                                                                                    i_prof,
                                                                                    'FUTURE_EVENTS_SCH_EVENT_DEFAULT');
    
    BEGIN
        o_flg_show    := pk_alert_constant.g_no;
        o_flg_proceed := pk_alert_constant.g_no;
    
        BEGIN
            g_error := 'GET EVENT ID';
            SELECT id_sch_event
              INTO l_id_sch_event
              FROM (SELECT id_sch_event
                      FROM sch_event e
                     WHERE e.dep_type = i_dep_type
                          -- g_event_occurrence_sub_first = first OR subsequent. I am converting this to First only
                       AND ((i_flg_occurr = pk_schedule.g_event_occurrence_sub_first AND
                           e.flg_occurrence = pk_schedule.g_event_occurrence_first) OR e.flg_occurrence = i_flg_occurr)
                       AND e.flg_target_professional = i_flg_prof
                     ORDER BY id_sch_event)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                pk_alertlog.log_error(text        => 'GET EVENT ID FOR dep_type ' || i_dep_type ||
                                                     ' and flg_occurrence = ' || i_flg_occurr ||
                                                     ' and flg_target_professional = Y',
                                      object_name => g_package_name,
                                      owner       => g_package_owner);
                o_flg_show   := pk_alert_constant.g_yes;
                o_msg_title  := pk_message.get_message(i_lang, pk_schedule.g_sched_msg_warning_title);
                o_msg        := pk_message.get_message(i_lang, g_sched_msg_no_appointment);
                o_button     := pk_schedule.g_check_button;
                o_id_content := NULL;
                RETURN TRUE;
        END;
    
        IF i_domain_p1_type IS NOT NULL
        THEN
            FOR i IN 1 .. l_tbl_config.count
            LOOP
                IF l_tbl_config(i).field_01 = i_domain_p1_type
                THEN
                    l_id_sch_event := l_tbl_config(i).field_02;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        g_error := 'GET APPOINTMENT ID CONTENT';
        IF NOT pk_schedule_api_downstream.get_id_content(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_sch_event => l_id_sch_event,
                                                         i_id_dcs       => i_id_dcs,
                                                         o_id_content   => o_id_content,
                                                         o_flg_proceed  => o_flg_proceed,
                                                         o_flg_show     => o_flg_show,
                                                         o_msg_title    => o_msg_title,
                                                         o_msg          => o_msg,
                                                         o_button       => o_button,
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
                                              'GET_ID_CONTENT',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_id_content;

    /*
    * Gets id_schedule external (first id)
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_schedule        Schedule identifier
    * @param o_error              An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @version 1.0
    * @since   21-10-2009
    */
    FUNCTION get_schedule_id_ext
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule OUT sch_api_map_ids.id_schedule_ext%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_map_sch IS
            SELECT id_schedule_ext
              FROM sch_api_map_ids
             WHERE id_schedule_pfh = i_id_schedule
               AND rownum = 1
             ORDER BY id_schedule_ext DESC;
    
    BEGIN
    
        -- Telmo. comentei porque o t_error_out foi alterado de 5 para 7 campos. E porque nao faz sentido esta init.
        --        o_error := t_error_out(NULL, NULL, NULL, NULL, NULL, NULL);
    
        g_error := 'OPEN c_map_sch';
        OPEN c_map_sch;
        FETCH c_map_sch
            INTO o_id_schedule;
        CLOSE c_map_sch;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_SCHEDULE_ID_EXT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_schedule_id_ext;

    /* private function for getting event config values max_profs, min_profs, max_patients
    *
    */
    FUNCTION get_event_config
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_event     IN sch_event.id_sch_event%TYPE,
        o_num_max_pat  OUT sch_event.num_max_patients%TYPE,
        o_num_max_prof OUT sch_event.num_max_profs%TYPE,
        o_num_min_prof OUT sch_event.num_min_profs%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET EVENT CONFIG VALUES';
        SELECT s.num_max_patients, s.num_max_profs, s.num_min_profs
          INTO o_num_max_pat, o_num_max_prof, o_num_min_prof
          FROM sch_event s
         WHERE s.id_sch_event = i_id_event;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_EVENT_CONFIG',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_event_config;

    /*
    *
    */
    FUNCTION string_to_tstz
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_date  IN VARCHAR2,
        o_date  OUT TIMESTAMP WITH TIME ZONE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_date IS NULL
        THEN
            RETURN TRUE;
        ELSE
            g_error := 'CALL PK_DATE_UTILS.GET_STRING_TSTZ';
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_date,
                                                 i_timezone  => NULL,
                                                 i_mask      => g_datetimeformat,
                                                 o_timestamp => o_date,
                                                 o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- tive de acrescentar isto porque a get_string_tstz esta mal feita. Quando se passa data invalida ela termina com sucesso mas
            -- com o return_value da funcao nulo.
            IF o_date IS NULL
            THEN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => -2001,
                                                  i_sqlerrm  => 'INVALID TIMESTAMP (' || i_date || ')',
                                                  i_message  => 'CALL PK_DATE_UTILS.GET_STRING_TSTZ',
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => 'STRING_TO_TSTZ',
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    END string_to_tstz;

    /*
    *   remover esta funcao
    */
    FUNCTION get_id_sch_event
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_sch_type IN sch_event.dep_type%TYPE,
        o_id_sch_event OUT sch_event.id_sch_event%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET EVENT ID';
        SELECT id_sch_event
          INTO o_id_sch_event
          FROM sch_event se
         WHERE se.dep_type = i_flg_sch_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_ID_SCH_EVENT',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_id_sch_event;

    /*
    *
    */
    FUNCTION get_pfh_ids(i_id_ext sch_api_map_ids.id_schedule_ext%TYPE) RETURN table_number IS
        l_ret table_number := table_number();
    BEGIN
        IF i_id_ext IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'GET PFH SCHEDULE IDS';
        SELECT id_schedule_pfh
          BULK COLLECT
          INTO l_ret
          FROM sch_api_map_ids
         WHERE id_schedule_ext = i_id_ext;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_pfh_ids;

    /* Telmo 14-01-2013 - evolucao da get_pfh_ids. devolve nested table de sch_api_map_ids%rowtype.
    *  usado no update_schedule.
    */
    FUNCTION get_pfh_rows(i_id_ext sch_api_map_ids.id_schedule_ext%TYPE) RETURN t_sch_api_map_ids IS
        l_ret t_sch_api_map_ids;
    BEGIN
        IF i_id_ext IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'GET_PFH_ROWS - GET PFH SCHEDULE IDS with i_id_ext=' || i_id_ext;
        SELECT *
          BULK COLLECT
          INTO l_ret
          FROM sch_api_map_ids
         WHERE id_schedule_ext = i_id_ext;
    
        RETURN l_ret;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_pfh_rows;

    /*
    * PRIVATE FUNCTION. convert sch_type into event. Error handling absence is intended.
    * NOTE: CAN ONLY BE USED FOR SINGLE EVENT SCHEDULING TYPES LIKE E,X,IN,S
    */
    FUNCTION get_event_from_sch_type
    (
        i_sch_type IN sch_event.dep_type%TYPE,
        i_id_inst  IN sch_event_inst_soft.id_institution%TYPE,
        i_id_soft  IN sch_event_inst_soft.id_software%TYPE
    ) RETURN sch_event.id_sch_event%TYPE IS
        l_id_sch_event sch_event.id_sch_event%TYPE;
    BEGIN
        g_error := 'GET EVENT FROM SCH_TYPE';
        SELECT se.id_sch_event
          INTO l_id_sch_event
          FROM sch_event se
         WHERE se.dep_type = i_sch_type
           AND pk_schedule_common.get_sch_event_avail(se.id_sch_event, i_id_inst, i_id_soft) = pk_alert_constant.g_yes
           AND rownum = 1;
        RETURN l_id_sch_event;
    
    END get_event_from_sch_type;
    /*
    * PRIVATE FUNCTION. returns true if all resource's dt_begin and dt_end are equal. If one of them is different return false.
      Error handling absence is intended.
    */
    FUNCTION compare_resource_dates
    (
        i_resources     t_resources,
        i_id_sch_proc   NUMBER,
        i_resource_type VARCHAR2
    ) RETURN BOOLEAN IS
        dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
        i        PLS_INTEGER;
    
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'COMPARE RESOURCE DATES';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources(i).id_schedule_procedure = i_id_sch_proc
                AND (i_resource_type IS NULL OR i_resources(i).id_resource_type = i_resource_type)
            THEN
                IF dt_begin IS NULL
                THEN
                    dt_begin := i_resources(i).dt_begin;
                    dt_end   := i_resources(i).dt_end;
                ELSE
                    IF dt_begin <> i_resources(i).dt_begin
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    IF dt_end <> i_resources(i).dt_end
                    THEN
                        RETURN FALSE;
                    END IF;
                END IF;
            END IF;
            i := i_resources.next(i);
        END LOOP;
    
        RETURN TRUE;
    END compare_resource_dates;

    /*
    *
    */
    FUNCTION count_persons(i_persons t_persons) RETURN NUMBER IS
    BEGIN
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            RETURN 0;
        ELSE
            RETURN i_persons.count;
        END IF;
    END count_persons;

    /*
    *
    */
    FUNCTION count_profs
    (
        i_resources   t_resources,
        i_id_sch_proc NUMBER
    ) RETURN NUMBER IS
        l_retval NUMBER := 0;
        i        PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
        THEN
            RETURN 0;
        END IF;
        g_error := 'COUNT PROFS';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources(i).id_schedule_procedure = i_id_sch_proc
                AND i_resources(i).id_resource_type = g_res_type_prof
                AND i_resources(i).id_resource > -1
            THEN
                l_retval := l_retval + 1;
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN l_retval;
    END count_profs;

    /*
    *
    */
    FUNCTION get_id_room
    (
        i_resources   t_resources,
        i_id_sch_proc NUMBER
    ) RETURN NUMBER IS
        l_retval NUMBER;
        i        PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
           OR i_id_sch_proc IS NULL
        THEN
            RETURN NULL;
        END IF;
        g_error := 'GET ROOM ID';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources(i).id_schedule_procedure = i_id_sch_proc
                AND i_resources(i).id_resource_type = g_res_type_room
                AND i_resources(i).id_resource > -1
            THEN
                l_retval := i_resources(i).id_resource;
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN l_retval;
    END get_id_room;

    /*
    *
    */
    FUNCTION get_ids_persons(i_persons t_persons) RETURN table_number IS
        l_tab table_number := table_number();
        i     PLS_INTEGER;
    BEGIN
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            RETURN l_tab;
        END IF;
        g_error := 'GET PERSONS IDS';
        i       := i_persons.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_persons.exists(i)
            THEN
                l_tab.extend;
                l_tab(l_tab.last) := i_persons(i).id_patient;
            END IF;
            i := i_persons.next(i);
        END LOOP;
        RETURN l_tab;
    END get_ids_persons;

    /*
    *
    */
    FUNCTION get_ids_profs
    (
        i_resources   t_resources,
        i_id_sch_proc NUMBER
    ) RETURN table_number IS
        l_tab table_number := table_number();
        i     PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
           OR i_id_sch_proc IS NULL
        THEN
            RETURN l_tab;
        END IF;
        g_error := 'GET PROF IDS';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources.exists(i)
               AND i_resources(i).id_schedule_procedure = i_id_sch_proc
               AND i_resources(i).id_resource_type = g_res_type_prof
               AND i_resources(i).id_resource > -1
            THEN
                l_tab.extend;
                l_tab(l_tab.last) := i_resources(i).id_resource;
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN l_tab;
    END get_ids_profs;

    /* Telmo 16-01-2013 - collect all profs that belong to the given id_schedule_procedure
    *
    */
    FUNCTION get_profs
    (
        i_resources   t_resources,
        i_id_sch_proc NUMBER
    ) RETURN t_resources IS
        l_res t_resources := t_resources();
        i     PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
           OR i_id_sch_proc IS NULL
        THEN
            RETURN l_res;
        END IF;
        g_error := 'GET PROF IDS';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources.exists(i)
               AND i_resources(i).id_schedule_procedure = i_id_sch_proc
               AND i_resources(i).id_resource_type = g_res_type_prof
               AND i_resources(i).id_resource > -1
            THEN
                l_res.extend;
                l_res(l_res.last) := i_resources(i);
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN l_res;
    END get_profs;

    /*
    *
    */
    FUNCTION get_first_resource_data
    (
        i_resources     t_resources,
        i_id_sch_proc   NUMBER,
        i_resource_type VARCHAR2
    ) RETURN t_resource IS
        i PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
        THEN
            RETURN NULL;
        END IF;
        g_error := 'GET FIRST RESOURCE DATA';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources(i).id_schedule_procedure = i_id_sch_proc
                AND i_resources(i).id_resource_type = i_resource_type
                AND i_resources(i).id_resource > -1
            THEN
                RETURN i_resources(i);
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN NULL;
    END get_first_resource_data;

    /*
    *
    */
    FUNCTION get_first_procedure_data
    (
        i_procedures   t_procedures,
        i_flg_sch_type VARCHAR2
    ) RETURN t_procedure IS
        i     PLS_INTEGER;
        l_ret t_procedure;
    BEGIN
        IF i_procedures IS NULL
           OR i_procedures.count = 0
        THEN
            RETURN l_ret;
        END IF;
        g_error := 'GET FIRST PROCEDURE DATA';
        i       := i_procedures.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedures(i).flg_sch_type = i_flg_sch_type
            THEN
                RETURN i_procedures(i);
            END IF;
            i := i_procedures.next(i);
        END LOOP;
        RETURN NULL;
    END get_first_procedure_data;

    /*
    *
    */
    FUNCTION get_first_person_data(i_persons t_persons) RETURN t_person IS
        i     PLS_INTEGER;
        l_ret t_person;
    BEGIN
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            RETURN l_ret;
        END IF;
        g_error := 'GET FIRST PERSON DATA';
        i       := i_persons.first;
        IF i IS NOT NULL
        THEN
            RETURN i_persons(i);
        ELSE
            RETURN NULL;
        END IF;
    END get_first_person_data;

    /*
    *
    */
    FUNCTION get_person_data
    (
        i_persons    t_persons,
        i_id_patient NUMBER
    ) RETURN t_person IS
        i     PLS_INTEGER;
        l_ret t_person;
    BEGIN
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            RETURN l_ret;
        END IF;
        g_error := 'GET PERSON DATA';
        i       := i_persons.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_persons(i).id_patient = i_id_patient
            THEN
                RETURN i_persons(i);
            END IF;
            i := i_persons.next(i);
        END LOOP;
        RETURN l_ret;
    END get_person_data;

    /*
    *
    */
    FUNCTION get_exam_id(i_id_content IN VARCHAR2) RETURN exam.id_exam%TYPE IS
        l_ret exam.id_exam%TYPE;
    BEGIN
        SELECT id_exam
          INTO l_ret
          FROM exam e
         WHERE e.id_content = TRIM(i_id_content)
           AND e.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
        RETURN l_ret;
    END get_exam_id;

    /*
    *
    */
    FUNCTION get_wl_type(i_id_wl IN waiting_list.id_waiting_list%TYPE) RETURN waiting_list.flg_type%TYPE IS
        l_ret waiting_list.flg_type%TYPE;
    BEGIN
        SELECT flg_type
          INTO l_ret
          FROM waiting_list
         WHERE id_waiting_list = i_id_wl;
        RETURN l_ret;
    END get_wl_type;

    /*
    *
    */
    FUNCTION validate_procedures
    (
        i_procedures IN t_procedures,
        o_errmsg     OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        i       PLS_INTEGER;
        l_dummy sch_dep_type.dep_type%TYPE;
    BEGIN
        g_error := 'VALIDATE_PROCEDURES';
    
        -- at least one procedure needed check
        IF i_procedures IS NULL
           OR i_procedures.count = 0
        THEN
            o_errmsg := 'AT LEAST ONE PROCEDURE NEEDED';
            RETURN FALSE;
        END IF;
    
        -- validate mandatory fields inside each procedure
        i := i_procedures.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedures.exists(i)
            THEN
                -- check id_schedule_procedure
                IF i_procedures(i).id_schedule_procedure IS NULL
                THEN
                    o_errmsg := 'PROCEDURE.ID_SCHEDULE_PROCEDURE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check flg_sch_type
                IF i_procedures(i).flg_sch_type IS NULL
                THEN
                    o_errmsg := 'PROCEDURE.FLG_SCH_TYPE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
            
                -- check if flg_sch_type is valid according to table sch_dep_type
                BEGIN
                    SELECT dep_type
                      INTO l_dummy
                      FROM sch_dep_type d
                     WHERE d.dep_type = i_procedures(i).flg_sch_type;
                EXCEPTION
                    WHEN no_data_found THEN
                        o_errmsg := 'PROCEDURE.FLG_SCH_TYPE VALUE ''' || i_procedures(i).flg_sch_type ||
                                    ''' IS NOT VALID';
                        RETURN FALSE;
                END;
            END IF;
            i := i_procedures.next(i);
        END LOOP;
        RETURN TRUE;
    END validate_procedures;

    /*
    *
    */
    FUNCTION validate_persons
    (
        i_persons IN t_persons,
        o_errmsg  OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        i PLS_INTEGER;
    BEGIN
        g_error := 'VALIDATE_PERSONS';
    
        -- at least one person needed check
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            o_errmsg := 'AT LEAST ONE PERSON NEEDED';
            RETURN FALSE;
        END IF;
    
        -- validate mandatory fields inside each person
        i := i_persons.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_persons.exists(i)
            THEN
                -- check id_patient
                IF i_persons(i).id_patient IS NULL
                THEN
                    o_errmsg := 'PERSON.ID_PATIENT IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check id_instit_requests
                IF i_persons(i).id_instit_requests IS NULL
                THEN
                    o_errmsg := 'PERSON.ID_INSTIT_REQUESTS IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check id_prof_schedules
                IF i_persons(i).id_prof_schedules IS NULL
                THEN
                    o_errmsg := 'PERSON.ID_PROF_SCHEDULES IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check dt_schedule
                IF i_persons(i).dt_schedule IS NULL
                THEN
                    o_errmsg := 'PERSON.DT_SCHEDULE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
            
            END IF;
            i := i_persons.next(i);
        END LOOP;
        RETURN TRUE;
    END validate_persons;

    /*
    *
    */
    FUNCTION validate_resources
    (
        i_resources IN t_resources,
        o_errmsg    OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        i PLS_INTEGER;
    BEGIN
        g_error := 'VALIDATE_RESOURCES';
    
        -- at least one procedure needed check
        IF i_resources IS NULL
           OR i_resources.count = 0
        THEN
            o_errmsg := 'AT LEAST ONE RESOURCE NEEDED';
            RETURN FALSE;
        END IF;
    
        -- validate mandatory fields inside each procedure
        i := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources.exists(i)
            THEN
                -- check id_schedule_procedure
                IF i_resources(i).id_schedule_procedure IS NULL
                THEN
                    o_errmsg := 'RESOURCE.ID_SCHEDULE_PROCEDURE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check id_resource
                IF i_resources(i).id_resource IS NULL
                THEN
                    o_errmsg := 'RESOURCE.ID_RESOURCE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check id_resource_type
                IF i_resources(i).id_resource_type IS NULL
                THEN
                    o_errmsg := 'RESOURCE.ID_RESOURCE_TYPE IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
                -- check dt_begin
                IF i_resources(i).dt_begin IS NULL
                THEN
                    o_errmsg := 'RESOURCE.DT_BEGIN IS MANDATORY (INDEX #' || i || ')';
                    RETURN FALSE;
                END IF;
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN TRUE;
    END validate_resources;

    /*
    *
    */
    FUNCTION validate_procedure_reqs
    (
        i_procedures     IN t_procedures,
        i_procedure_reqs IN t_procedure_reqs,
        o_errmsg         OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        i      PLS_INTEGER;
        j      PLS_INTEGER;
        l_pass BOOLEAN := FALSE;
    BEGIN
        g_error := 'VALIDATE_PROCEDURE_REQS';
    
        -- one procedure_req needed for each procedure with flg_sch_type = S, IN
        i := i_procedures.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedures.exists(i)
            THEN
            
                IF i_procedures(i).flg_sch_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_sr,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_inp,
                                     pk_schedule_common.g_sch_dept_flg_dep_type_pm)
                THEN
                    -- we have a Surgery/inpatient procedure and no procedure_reqs.
                    IF i_procedure_reqs IS NULL
                       OR i_procedure_reqs.count = 0
                    THEN
                        o_errmsg := 'PROCEDURE #' || i_procedures(i).id_schedule_procedure ||
                                    ' MUST HAVE A PROCEDURE_REQ';
                        RETURN FALSE;
                    END IF;
                
                    j := i_procedure_reqs.first;
                    WHILE j IS NOT NULL
                    LOOP
                        IF i_procedure_reqs.exists(j)
                        THEN
                            IF i_procedure_reqs(j).id_schedule_procedure = i_procedures(i).id_schedule_procedure
                            THEN
                                l_pass := TRUE;
                                -- we have found the right procedure_req, but does it have what it got?
                                -- check id_patient
                                IF i_procedure_reqs(j).id_patient IS NULL
                                THEN
                                    o_errmsg := 'PROCEDURE_REQ.ID_PATIENT IS MANDATORY (INDEX #' || j || ')';
                                    RETURN FALSE;
                                END IF;
                                -- check id
                                IF i_procedure_reqs(j).id IS NULL
                                THEN
                                    o_errmsg := 'PROCEDURE_REQ.ID IS MANDATORY (INDEX #' || j || ')';
                                    RETURN FALSE;
                                END IF;
                                -- check id type
                                IF i_procedure_reqs(j).id_type IS NULL
                                THEN
                                    o_errmsg := 'PROCEDURE_REQ.ID_TYPE IS MANDATORY (INDEX #' || j || ')';
                                    RETURN FALSE;
                                END IF;
                                -- check id type against flg_sch_type
                                IF (i_procedures(i)
                                   .flg_sch_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_sr,
                                                     pk_schedule_common.g_sch_dept_flg_dep_type_inp) AND i_procedure_reqs(j)
                                   .id_type <> g_proc_req_type_wl)
                                   OR (i_procedures(i).flg_sch_type IN (pk_schedule_common.g_sch_dept_flg_dep_type_pm) AND i_procedure_reqs(j)
                                   .id_type <> g_proc_req_type_req)
                                THEN
                                    o_errmsg := 'PROCEDURE_REQ.ID_TYPE IS INCONSISTENT WITH FLG_SCH_TYPE (INDEX #' || j || ')';
                                    RETURN FALSE;
                                END IF;
                            END IF;
                        END IF;
                        j := i_procedure_reqs.next(j);
                    END LOOP;
                    -- we have a Surgery/inpatient procedure and some procedure_reqs, but none belongs to our procedure
                    IF l_pass = FALSE
                    THEN
                        o_errmsg := 'PROCEDURE #' || i_procedures(i).id_schedule_procedure ||
                                    ' MUST HAVE A PROCEDURE_REQ';
                        RETURN FALSE;
                    END IF;
                
                END IF;
            
            END IF;
            i := i_procedures.next(i);
        END LOOP;
    
        RETURN TRUE;
    END validate_procedure_reqs;

    /*
    *
    */
    FUNCTION get_message
    (
        i_lang     language.id_language%TYPE,
        i_prof     profissional,
        i_code_msg sys_message.code_message%TYPE
    ) RETURN sys_message.desc_message%TYPE IS
    BEGIN
        IF TRIM(i_code_msg) IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN nvl(pk_message.get_message(i_lang, i_prof, i_code_msg), i_code_msg);
        END IF;
    END get_message;

    /*
    *
    */
    FUNCTION get_prof_leader
    (
        i_resources   t_resources,
        i_id_sch_proc NUMBER
    ) RETURN t_resource IS
        l_retval t_resource;
        i        PLS_INTEGER;
    BEGIN
        IF i_resources IS NULL
           OR i_resources.count = 0
           OR i_id_sch_proc IS NULL
        THEN
            RETURN l_retval;
        END IF;
        g_error := 'ITERATE resources TO GET PROFESSIONAL LEADER';
        i       := i_resources.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_resources(i).id_schedule_procedure = i_id_sch_proc
                AND i_resources(i).id_resource_type = g_res_type_prof
                AND i_resources(i).id_resource > -1
            THEN
                IF nvl(i_resources(i).flg_leader, pk_alert_constant.g_no) = pk_alert_constant.g_yes
                THEN
                    RETURN i_resources(i); -- encontrou e sai
                ELSIF l_retval.id_schedule_procedure IS NULL
                THEN
                    -- nao encontrou. se e' o primeiro prof fica esse por defeito
                    l_retval := i_resources(i);
                END IF;
            END IF;
            i := i_resources.next(i);
        END LOOP;
        RETURN l_retval;
    END get_prof_leader;

    /*
    *
    */
    FUNCTION get_sch_flg_status(i_ext_flg_status VARCHAR2) RETURN schedule.flg_status%TYPE IS
    BEGIN
        CASE i_ext_flg_status
        --            WHEN g_ext_flg_status_available THEN
        --                RETURN NULL;
        --            WHEN g_ext_flg_status_scheduled THEN
        --                RETURN pk_schedule.g_status_scheduled;
            WHEN g_ext_flg_status_temporary THEN
                RETURN pk_schedule.g_status_scheduled;
                --            WHEN g_ext_flg_status_planned THEN
        --                RETURN NULL;
        --            WHEN g_ext_flg_status_canceled THEN
        --                RETURN pk_schedule.g_status_canceled;
        --            WHEN g_ext_flg_status_pending THEN
        --                RETURN NULL;
            ELSE
                RETURN i_ext_flg_status;
        END CASE;
    END get_sch_flg_status;

    /*
    *
    */
    FUNCTION get_sch_flg_tempor(i_ext_flg_status VARCHAR2) RETURN VARCHAR2 IS
    BEGIN
        CASE i_ext_flg_status
            WHEN g_ext_flg_status_temporary THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
        END CASE;
    END get_sch_flg_tempor;

    /*
    *
    */
    FUNCTION get_person
    (
        i_persons            t_persons,
        i_id_schedule_person NUMBER
    ) RETURN t_person IS
        i     PLS_INTEGER;
        l_ret t_person;
    BEGIN
        g_error := 'VALIDATE INPUT i_persons';
        IF i_persons IS NULL
           OR i_persons.count = 0
        THEN
            RETURN l_ret;
        END IF;
    
        g_error := 'GET PERSON';
        i       := i_persons.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_persons(i).id_schedule_person = i_id_schedule_person
            THEN
                RETURN i_persons(i);
            END IF;
            i := i_persons.next(i);
        END LOOP;
        -- se chegar aqui nao encontrou
        RETURN l_ret;
    END get_person;

    /*
    *
    */
    FUNCTION get_procedure
    (
        i_procedures            t_procedures,
        i_id_schedule_procedure NUMBER
    ) RETURN t_procedure IS
        i     PLS_INTEGER;
        l_ret t_procedure;
    BEGIN
        g_error := 'VALIDATE INPUT i_procedures';
        IF i_procedures IS NULL
           OR i_procedures.count = 0
        THEN
            RETURN l_ret;
        END IF;
    
        g_error := 'GET PROCEDURE';
        i       := i_procedures.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedures(i).id_schedule_procedure = i_id_schedule_procedure
            THEN
                RETURN i_procedures(i);
            END IF;
            i := i_procedures.next(i);
        END LOOP;
        -- se chegar aqui nao encontrou
        RETURN l_ret;
    END get_procedure;

    /*
    *
    */
    FUNCTION get_procedure_req
    (
        i_procedure_reqs        t_procedure_reqs,
        i_id_schedule_procedure NUMBER,
        i_id_patient            NUMBER
    ) RETURN t_procedure_req IS
        i     PLS_INTEGER;
        l_ret t_procedure_req;
    BEGIN
        g_error := 'VALIDATE INPUT i_procedure_reqs';
        IF i_procedure_reqs IS NULL
           OR i_procedure_reqs.count = 0
        THEN
            RETURN l_ret;
        END IF;
    
        g_error := 'GET PROCEDURE_REQ';
        i       := i_procedure_reqs.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedure_reqs(i).id_schedule_procedure = i_id_schedule_procedure
                AND i_procedure_reqs(i).id_patient = i_id_patient
            THEN
                RETURN i_procedure_reqs(i);
            END IF;
            i := i_procedure_reqs.next(i);
        END LOOP;
        -- se chegar aqui nao encontrou
        RETURN l_ret;
    END get_procedure_req;

    /*
    *
    */
    FUNCTION get_procedure_req_data
    (
        i_procedure_reqs        t_procedure_reqs,
        i_id_schedule_procedure NUMBER,
        i_id_patient            NUMBER,
        i_id_type               VARCHAR2
    ) RETURN t_procedure_req IS
        i     PLS_INTEGER;
        l_ret t_procedure_req;
    BEGIN
        g_error := 'GET_PROCEDURE_REQ_DATA';
        IF i_procedure_reqs IS NULL
           OR i_procedure_reqs.count = 0
        THEN
            RETURN l_ret;
        END IF;
    
        g_error := 'GET PROCEDURE_REQ';
        i       := i_procedure_reqs.first;
        WHILE i IS NOT NULL
        LOOP
            IF i_procedure_reqs(i).id_schedule_procedure = i_id_schedule_procedure
                AND i_procedure_reqs(i).id_patient = i_id_patient
                AND i_procedure_reqs(i).id_type = i_id_type
            THEN
                RETURN i_procedure_reqs(i);
            END IF;
            i := i_procedure_reqs.next(i);
        END LOOP;
        -- se chegar aqui nao encontrou
        RETURN l_ret;
    END get_procedure_req_data;

    /*
    * MAXIMUS INQUISITORIUM
    * nao tem exception handling para que seja feito nos invocadores create_schedule e update_schedule.
    */
    PROCEDURE customs_inspection
    (
        i_lang                INTEGER,
        i_prof                profissional,
        i_id_sch_ext          sch_api_map_ids.id_schedule_ext%TYPE,
        i_flg_status          schedule.flg_status%TYPE,
        i_id_instit_requested institution.id_institution%TYPE,
        i_id_dep_requested    dep_clin_serv.id_department%TYPE,
        i_procedures          t_procedures,
        i_persons             t_persons,
        i_resources           t_resources,
        i_procedure_reqs      t_procedure_reqs,
        o_exists_surg_proc    OUT BOOLEAN
    ) IS
        l_func_name     VARCHAR2(30) := $$PLSQL_UNIT;
        l_pivot         PLS_INTEGER;
        l_exists        BOOLEAN;
        l_desc_trans    translation.desc_lang_1%TYPE;
        l_flg_av        VARCHAR2(2);
        l_error         t_error_out;
        l_num_max_pat   sch_event.num_max_patients%TYPE;
        l_num_max_prof  sch_event.num_max_profs%TYPE;
        l_num_min_prof  sch_event.num_min_profs%TYPE;
        l_id_sch_event  sch_event.id_sch_event%TYPE;
        l_id_dcs        schedule.id_dcs_requested%TYPE;
        l_num_persons   PLS_INTEGER := count_persons(i_persons);
        l_num_profs     PLS_INTEGER;
        l_is_inp_sched  BOOLEAN;
        l_is_surg_sched BOOLEAN;
        l_id_room       NUMBER;
    BEGIN
        o_exists_surg_proc := FALSE;
    
        -- basic input existence validation
        g_error := l_func_name || ' - VALIDATE PROCEDURES DATA';
        IF NOT validate_procedures(i_procedures, g_inv_data_msg)
        THEN
            RAISE g_invalid_data;
        END IF;
    
        g_error := l_func_name || ' - VALIDATE PERSON DATA';
        IF NOT validate_persons(i_persons, g_inv_data_msg)
        THEN
            RAISE g_invalid_data;
        END IF;
    
        g_error := l_func_name || ' - VALIDATE PROCEDURE_REQS DATA';
        IF NOT validate_procedure_reqs(i_procedures, i_procedure_reqs, g_inv_data_msg)
        THEN
            RAISE g_invalid_data;
        END IF;
    
        g_error := l_func_name || ' - VALIDATE SCHEDULER ID';
        IF pk_schedule_api_upstream.is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
           AND i_id_sch_ext IS NULL
        THEN
            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_sch_id); --'Scheduler ID (I_ID_SCH_EXT) is mandatory';
            RAISE g_invalid_data;
        END IF;
    
        g_error := l_func_name || ' - VALIDATE flg_status';
        IF i_flg_status IS NULL
        THEN
            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_status); --'Status (i_flg_status) is mandatory';
            RAISE g_invalid_data;
        END IF;
    
        g_error := l_func_name || ' - VALIDATE i_id_instit_requested';
        IF i_id_instit_requested IS NULL
        THEN
            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_req_inst); --'Requested institution is mandatory';
            RAISE g_invalid_data;
        END IF;
    
        -- cycle procedures for validations
        l_pivot := i_procedures.first;
        WHILE l_pivot IS NOT NULL
        LOOP
            IF i_procedures.exists(l_pivot)
            THEN
                -- this validation must be inside the loop
                -- alert-248915: id_dcs_requested can only be null for exams/other exams
                -- sch-8193: ... and for lab stuff
                g_error := l_func_name || ' - VALIDATE id_dcs_requested';
                IF i_procedures(l_pivot).id_dcs_requested IS NULL
                    AND pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type) NOT IN
                    (pk_schedule_common.g_sch_dept_flg_dep_type_exam,
                         pk_schedule_common.g_sch_dept_flg_dep_type_anls,
                         pk_schedule_common.g_sch_dept_flg_dep_type_inp)
                THEN
                    g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_req_service); --'Requested service is mandatory';
                    RAISE g_invalid_data;
                END IF;
            
                -- calc profs number for this procedure
                g_error     := l_func_name || ' - CALL COUNT_PROFS';
                l_num_profs := count_profs(i_resources, i_procedures(l_pivot).id_schedule_procedure);
            
                -- get flg_available for exams and other exams
                IF pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type) =
                   pk_schedule_common.g_sch_dept_flg_dep_type_exam
                THEN
                    -- pegar a flg_available do exam e a propria existencia
                    g_error := l_func_name || ' - CALL GET_EXAM_AVAILABILITY with i_id_content ' || i_procedures(l_pivot).id_content;
                    get_exam_availability(i_lang       => i_lang,
                                          i_id_content => i_procedures(l_pivot).id_content,
                                          o_flg_avail  => l_flg_av,
                                          o_exists     => l_exists,
                                          o_trans      => l_desc_trans);
                
                    g_error        := l_func_name || ' - CALL GET_EVENT_FROM_SCH_TYPE with i_sch_type=' || i_procedures(l_pivot).flg_sch_type ||
                                      ', i_id_inst=' || i_id_instit_requested || ', i_id_soft=' || i_prof.software;
                    l_id_sch_event := get_event_from_sch_type(i_procedures(l_pivot).flg_sch_type,
                                                              i_id_instit_requested,
                                                              i_prof.software);
                
                ELSIF pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type) =
                      pk_schedule_common.g_sch_dept_flg_dep_type_cons
                THEN
                    -- pegar dados do appointment
                    g_error := l_func_name || ' - CALL GET_APPOINTMENT_DATA';
                    get_appointment_data(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_appointment => i_procedures(l_pivot).id_content,
                                         i_id_department  => i_id_dep_requested,
                                         o_id_sch_event   => l_id_sch_event,
                                         o_id_dcs         => l_id_dcs,
                                         o_flg_avail      => l_flg_av,
                                         o_exists         => l_exists,
                                         o_trans          => l_desc_trans);
                
                ELSE
                    g_error        := l_func_name || ' - CALL GET_EVENT_FROM_SCH_TYPE with i_sch_type=' || i_procedures(l_pivot).flg_sch_type ||
                                      ', i_id_inst=' || i_id_instit_requested || ', i_id_soft=' || i_prof.software;
                    l_id_sch_event := get_event_from_sch_type(i_procedures(l_pivot).flg_sch_type,
                                                              i_id_instit_requested,
                                                              i_prof.software);
                END IF;
            
                -- validate if the procedure's flg_available is Y
                IF l_flg_av = pk_alert_constant.g_no
                THEN
                    g_error := l_func_name || ' - CALL pk_schedule.replace_tokens';
                    IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                                      i_string       => pk_message.get_message(i_lang,
                                                                                               g_sched_msg_event_not_avail),
                                                      i_tokens       => table_varchar('@1'),
                                                      i_replacements => table_varchar(l_desc_trans),
                                                      o_string       => g_inv_data_msg,
                                                      o_error        => l_error)
                    THEN
                        g_inv_data_msg := l_error.ora_sqlerrm;
                    END IF;
                    RAISE g_invalid_data;
                END IF;
            
                -- validate if the procedure exists
                IF NOT l_exists
                THEN
                    g_error := l_func_name || ' - CALL pk_schedule.replace_tokens';
                    IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                                      i_string       => pk_message.get_message(i_lang,
                                                                                               g_sched_msg_event_not_exist),
                                                      i_tokens       => table_varchar('@1'),
                                                      i_replacements => table_varchar(i_procedures(l_pivot).id_content),
                                                      o_string       => g_inv_data_msg,
                                                      o_error        => l_error)
                    THEN
                        g_inv_data_msg := l_error.ora_sqlerrm;
                    END IF;
                    RAISE g_invalid_data;
                END IF;
            
                IF (pk_schedule_api_upstream.is_scheduler_installed(i_prof) <> pk_alert_constant.g_yes)
                THEN
                    -- get event config values
                    g_error := l_func_name || ' - GET_EVENT_CONFIG with i_id_event ' || l_id_sch_event;
                    IF NOT get_event_config(i_lang         => i_lang,
                                            i_prof         => i_prof,
                                            i_id_event     => l_id_sch_event,
                                            o_num_max_pat  => l_num_max_pat,
                                            o_num_max_prof => l_num_max_prof,
                                            o_num_min_prof => l_num_min_prof,
                                            o_error        => l_error)
                    THEN
                        g_inv_data_msg := l_error.ora_sqlerrm;
                        RAISE g_func_exception;
                    END IF;
                
                    -- validate tentative schedule #persons against event max num patients config
                    IF l_num_max_pat IS NOT NULL
                       AND l_num_persons > l_num_max_pat
                    THEN
                        -- SCH_T812 Este agendamento com múltiplos pacientes não é permitido
                        g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_max_pat_violated);
                        RAISE g_invalid_schedule;
                    END IF;
                
                    -- validate tentative schedule #profs against event max num patients config
                    IF l_num_max_prof = 0
                       AND l_num_profs > l_num_max_prof
                    THEN
                        -- SCH_T815 Não é permitido realizar este agendamento com um profissional
                        g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_no_prof_violated);
                        RAISE g_invalid_schedule;
                    END IF;
                
                    -- validate tentative schedule #profs against event max num patients config
                    IF l_num_max_prof IS NOT NULL
                       AND l_num_profs > l_num_max_prof
                    THEN
                        -- SCH_T814 Não é permitido realizar este agendamento com multiplos profissionais
                        g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_max_prof_violated);
                        RAISE g_invalid_schedule;
                    END IF;
                
                    -- validate tentative schedule #profs against event min num patients config
                    IF l_num_min_prof IS NOT NULL
                       AND l_num_profs < l_num_min_prof
                    THEN
                        -- SCH_T813 Não é permitido realizar este agendamento sem um profissional
                        g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_min_prof_violated);
                        RAISE g_invalid_schedule;
                    END IF;
                END IF;
                -- see if its a inp schedule
                l_is_inp_sched := i_procedures(l_pivot).flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp;
            
                -- validate procedure type mixing. Oris type not allowed when mixed with other types
                l_is_surg_sched := l_is_surg_sched AND
                                   (i_procedures(l_pivot).flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_sr);
            
                IF i_procedures(l_pivot).flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_sr
                THEN
                    o_exists_surg_proc := TRUE;
                
                    -- validate room. It cannot change
                    IF l_id_room IS NULL
                    THEN
                        l_id_room := get_id_room(i_resources, i_procedures(l_pivot).id_schedule_procedure);
                    ELSE
                        IF l_id_room <> get_id_room(i_resources, i_procedures(l_pivot).id_schedule_procedure)
                        THEN
                            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_one_room_only); --'Only one room allowed in a surgery schedule';
                            RAISE g_invalid_data;
                        END IF;
                    END IF;
                END IF;
            
            END IF;
            l_pivot := i_procedures.next(l_pivot);
        END LOOP;
    
        -- special validation for surgery/inp scheduling. Only 1 patient allowed
        IF l_num_persons > 1
           AND (l_is_surg_sched OR l_is_inp_sched)
        THEN
            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_max_pat_violated);
            RAISE g_invalid_schedule;
        END IF;
    
        -- another special validation for surgery scheduling. Do not allow surgery procs mixed with non-surgery procs
        IF NOT l_is_surg_sched
           AND o_exists_surg_proc
        THEN
            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_mixed_surg_procs);
            RAISE g_invalid_schedule;
        END IF;
    
        IF l_is_surg_sched
           OR l_is_inp_sched
        THEN
            -- validar existencia de um procedure_req com o id WL
            g_error := l_func_name || ' - CHECK PROCEDURE_REQUEST EXISTENCE';
            IF i_procedure_reqs IS NULL
               OR i_procedure_reqs.count = 0
            THEN
                g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_proc_req); --'Surgery/Inpatient appointment - one procedure_request is needed';
                RAISE g_invalid_data;
            END IF;
        END IF;
    
    END customs_inspection;

    /*
    * Telmo 01-02-2013 - gerador de requisicao de exame.
    * A partir de agora independente da create_schedule_exam.
    */
    FUNCTION create_exam_req
    (
        i_lang             NUMBER,
        i_prof             profissional,
        i_id_schedule      schedule.id_schedule%TYPE,
        i_id_inst          schedule.id_instit_requested%TYPE,
        i_ids_exams        table_number,
        i_dt_begin         VARCHAR2,
        i_id_patient       patient.id_patient%TYPE,
        i_flg_status       schedule.flg_status%TYPE,
        i_id_episode       episode.id_episode%TYPE,
        o_ids_exam_req     OUT table_number,
        o_ids_exam_req_det OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := $$PLSQL_UNIT;
        ld_exam_req_det        table_number := table_number();
        ld_flg_type            table_varchar := table_varchar();
        ld_codification        table_number := table_number();
        ld_dt_req              table_varchar := table_varchar();
        ld_flg_time            table_varchar := table_varchar();
        ld_dt_begin            table_varchar := table_varchar();
        ld_dt_begin_limit      table_varchar := table_varchar();
        ld_episode_destination table_number := table_number();
        ld_order_recurrence    table_number := table_number();
        ld_priority            table_varchar := table_varchar();
        ld_flg_prn             table_varchar := table_varchar();
        ld_notes_prn           table_varchar := table_varchar();
        ld_flg_fasting         table_varchar := table_varchar();
        ld_notes               table_varchar := table_varchar();
        ld_notes_scheduler     table_varchar := table_varchar();
        ld_notes_technician    table_varchar := table_varchar();
        ld_notes_patient       table_varchar := table_varchar();
        ld_diagnosis_notes     table_varchar := table_varchar();
        ld_diagnosis           pk_edis_types.table_in_epis_diagnosis := pk_edis_types.table_in_epis_diagnosis();
        ld_laterality          table_varchar := table_varchar();
        --        ld_diagnosis_desc          table_table_varchar := table_table_varchar();
        ld_exec_room               table_number := table_number();
        ld_exec_institution        table_number := table_number();
        ld_clinical_purpose        table_number := table_number();
        ld_health_plan             table_number := table_number();
        ld_prof_order              table_number := table_number();
        ld_dt_order                table_varchar := table_varchar();
        ld_order_type              table_number := table_number();
        ld_clinical_question       table_table_number := table_table_number();
        ld_response                table_table_varchar := table_table_varchar();
        ld_clinical_question_notes table_table_varchar := table_table_varchar();
        ld_clinical_decision_rule  table_number := table_number();
        ld_task_dependency         table_number := table_number();
        ld_flg_task_depending      table_varchar := table_varchar();
        ld_episode_followup_app    table_number := table_number();
        ld_schedule_followup_app   table_number := table_number();
        ld_event_followup_app      table_number := table_number();
        l_dt_req                   VARCHAR2(30);
        l_flg_proceed              VARCHAR2(1);
        l_flg_show                 VARCHAR2(1);
        l_msg                      VARCHAR2(200);
        l_msg_title                VARCHAR2(200);
        l_button                   VARCHAR2(200);
    BEGIN
        IF nvl(cardinality(i_ids_exams), 0) = 0
        THEN
            RETURN TRUE;
        END IF;
    
        -- inicializar vars. Tem de ter o mesmo tamanho da minha lista de exames
        g_error := l_func_name || ' - INIT create_exam_order input params';
        ld_exam_req_det.extend(i_ids_exams.count); -- tudo a null
        ld_flg_type.extend(i_ids_exams.count); -- tudo com E
        ld_codification.extend(i_ids_exams.count); -- tudo a null
        ld_dt_req.extend(i_ids_exams.count); -- tudo a null
        ld_flg_time.extend(i_ids_exams.count); -- tudo com g_flg_time_e
        ld_dt_begin.extend(i_ids_exams.count); -- tudo com i_dt_begin
        ld_dt_begin_limit.extend(i_ids_exams.count); -- tudo a null
        ld_episode_destination.extend(i_ids_exams.count); -- tudo a null
        ld_order_recurrence.extend(i_ids_exams.count); -- tudo a null
        ld_priority.extend(i_ids_exams.count); -- tudo com N
        ld_flg_prn.extend(i_ids_exams.count); -- tudo a null
        ld_notes_prn.extend(i_ids_exams.count); -- tudo a null
        ld_flg_fasting.extend(i_ids_exams.count); -- tudo a null
        ld_notes.extend(i_ids_exams.count); -- tudo a null
        ld_notes_scheduler.extend(i_ids_exams.count); -- tudo a null
        ld_notes_technician.extend(i_ids_exams.count); -- tudo a null
        ld_notes_patient.extend(i_ids_exams.count); -- tudo a null
        ld_diagnosis_notes.extend(i_ids_exams.count); -- tudo a null
        ld_diagnosis.extend(i_ids_exams.count); -- tudo com table_number()
        ld_laterality.extend(i_ids_exams.count);
        --        ld_diagnosis_desc.extend(i_ids_exams.count); -- tudo com table_varchar()
        ld_exec_room.extend(i_ids_exams.count); -- tudo a null
        ld_exec_institution.extend(i_ids_exams.count); -- tudo com i_id_inst
        ld_clinical_purpose.extend(i_ids_exams.count); -- tudo a null
        ld_health_plan.extend(i_ids_exams.count); -- tudo a null
        ld_prof_order.extend(i_ids_exams.count); -- tudo a null
        ld_dt_order.extend(i_ids_exams.count); -- tudo a null
        ld_order_type.extend(i_ids_exams.count); -- tudo a null
        ld_clinical_question.extend(i_ids_exams.count); -- tudo com table_number(NULL)
        ld_response.extend(i_ids_exams.count); -- tudo com table_varchar('')
        ld_clinical_question_notes.extend(i_ids_exams.count); -- tudo com table_varchar('')
        ld_clinical_decision_rule.extend(i_ids_exams.count); -- tudo a null
        ld_task_dependency.extend(i_ids_exams.count); -- tudo a null
        ld_flg_task_depending.extend(i_ids_exams.count); -- tudo com ''
        ld_episode_followup_app.extend(i_ids_exams.count); -- tudo a null
        ld_schedule_followup_app.extend(i_ids_exams.count); -- tudo a null
        ld_event_followup_app.extend(i_ids_exams.count); -- tudo a null
    
        -- settar data da requisicao de acordo com a regra [se dt_begin < data actual entao i_dt_req = i_dt_begin]
        IF to_timestamp(i_dt_begin, 'YYYYMMDDHH24MISS') < current_timestamp
        THEN
            l_dt_req := i_dt_begin;
        END IF;
    
        -- set vars
        g_error := l_func_name || ' - SET create_exam_order INPUT PARAMS VALUES';
        FOR k IN 1 .. i_ids_exams.count
        LOOP
            ld_exam_req_det(k) := NULL;
            ld_flg_type(k) := 'E';
            ld_codification(k) := NULL;
            ld_dt_req(k) := l_dt_req;
            ld_flg_time(k) := pk_exam_constant.g_flg_time_e;
            ld_dt_begin(k) := i_dt_begin;
            ld_dt_begin_limit(k) := NULL;
            ld_episode_destination(k) := NULL;
            ld_order_recurrence(k) := NULL;
            ld_priority(k) := 'N';
            ld_flg_prn(k) := NULL;
            ld_notes_prn(k) := NULL;
            ld_flg_fasting(k) := NULL;
            ld_notes(k) := NULL;
            ld_notes_scheduler(k) := NULL;
            ld_notes_technician(k) := NULL;
            ld_notes_patient(k) := NULL;
            ld_diagnosis_notes(k) := NULL;
            ld_laterality(k) := NULL;
            ld_exec_room(k) := NULL;
            ld_exec_institution(k) := i_id_inst;
            ld_clinical_purpose(k) := NULL;
            ld_health_plan(k) := NULL;
            ld_prof_order(k) := NULL;
            ld_dt_order(k) := NULL;
            ld_order_type(k) := NULL;
            ld_clinical_question(k) := table_number(NULL);
            ld_response(k) := table_varchar('');
            ld_clinical_question_notes(k) := table_varchar('');
            ld_clinical_decision_rule(k) := NULL;
            ld_task_dependency(k) := NULL;
            ld_flg_task_depending(k) := '';
            ld_episode_followup_app(k) := NULL;
            ld_schedule_followup_app(k) := NULL;
            ld_event_followup_app(k) := NULL;
        END LOOP;
    
        g_error := l_func_name || ' - CALL PK_EXAMS_API_DB.CREATE_EXAM_ORDER';
        IF NOT pk_exams_api_db.create_exam_order(i_lang                    => i_lang,
                                                 i_prof                    => i_prof,
                                                 i_patient                 => i_id_patient,
                                                 i_episode                 => i_id_episode,
                                                 i_exam_req                => NULL,
                                                 i_exam_req_det            => ld_exam_req_det,
                                                 i_exam                    => i_ids_exams,
                                                 i_flg_type                => ld_flg_type,
                                                 i_dt_req                  => ld_dt_req,
                                                 i_flg_time                => ld_flg_time,
                                                 i_dt_begin                => ld_dt_begin,
                                                 i_dt_begin_limit          => ld_dt_begin_limit,
                                                 i_episode_destination     => ld_episode_destination,
                                                 i_order_recurrence        => ld_order_recurrence,
                                                 i_priority                => ld_priority,
                                                 i_flg_prn                 => ld_flg_prn,
                                                 i_notes_prn               => ld_notes_prn,
                                                 i_flg_fasting             => ld_flg_fasting,
                                                 i_notes                   => ld_notes,
                                                 i_notes_scheduler         => ld_notes_scheduler,
                                                 i_notes_technician        => ld_notes_technician,
                                                 i_notes_patient           => ld_notes_patient,
                                                 i_diagnosis_notes         => ld_diagnosis_notes,
                                                 i_diagnosis               => ld_diagnosis,
                                                 i_laterality              => ld_laterality,
                                                 i_exec_room               => ld_exec_room,
                                                 i_exec_institution        => ld_exec_institution,
                                                 i_clinical_purpose        => ld_clinical_purpose,
                                                 i_codification            => ld_codification,
                                                 i_health_plan             => ld_health_plan,
                                                 i_prof_order              => ld_prof_order,
                                                 i_dt_order                => ld_dt_order,
                                                 i_order_type              => ld_order_type,
                                                 i_clinical_question       => ld_clinical_question,
                                                 i_response                => ld_response,
                                                 i_clinical_question_notes => ld_clinical_question_notes,
                                                 i_clinical_decision_rule  => ld_clinical_decision_rule,
                                                 i_flg_origin_req          => 'S',
                                                 i_task_dependency         => ld_task_dependency,
                                                 i_flg_task_depending      => ld_flg_task_depending,
                                                 i_episode_followup_app    => ld_episode_followup_app,
                                                 i_schedule_followup_app   => ld_schedule_followup_app,
                                                 i_event_followup_app      => ld_event_followup_app,
                                                 i_test                    => pk_alert_constant.g_no,
                                                 o_flg_show                => l_flg_show,
                                                 o_msg_title               => l_msg_title,
                                                 o_msg_req                 => l_msg,
                                                 o_button                  => l_button,
                                                 o_exam_req_array          => o_ids_exam_req,
                                                 o_exam_req_det_array      => o_ids_exam_req_det,
                                                 o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_flg_show = pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    END create_exam_req;

    FUNCTION create_lab_test_req
    (
        i_lang                    NUMBER,
        i_prof                    profissional,
        i_analysis_req_origin     analysis_req.id_analysis_req%TYPE,
        i_analysis_req_det_origin table_number,
        i_dt_begin                VARCHAR2,
        i_id_patient              patient.id_patient%TYPE,
        i_id_episode              episode.id_episode%TYPE,
        o_ids_lab_test_req        OUT table_number,
        o_ids_lab_test_req_det    OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(32) := $$PLSQL_UNIT;
        r_analysis_req     analysis_req%ROWTYPE;
        r_analysis_req_det analysis_req_det%ROWTYPE;
    
        l_tbl_analysis    table_number := table_number();
        l_tbl_sample_type table_number := table_number();
    
        l_tbl_analysis_req_det_dummy  table_number := table_number();
        l_tbl_analysis_req_det        table_number := table_number();
        l_tbl_analysis_req_det_parent table_number := table_number();
        l_tbl_analysis_group          table_table_varchar := table_table_varchar();
        l_tbl_flg_type                table_varchar := table_varchar();
        l_tbl_dt_req                  table_varchar := table_varchar();
        l_tbl_flg_time                table_varchar := table_varchar();
        l_tbl_dt_begin                table_varchar := table_varchar();
        l_tbl_dt_begin_limit          table_varchar := table_varchar();
        l_tbl_episode_destination     table_number := table_number();
        l_tbl_order_recurrence        table_number := table_number();
        l_tbl_priority                table_varchar := table_varchar();
        l_tbl_flg_prn                 table_varchar := table_varchar();
        l_tbl_notes_prn               table_varchar := table_varchar();
        l_tbl_body_location           table_table_number := table_table_number();
        l_tbl_laterality              table_table_varchar := table_table_varchar();
        l_tbl_collection_room         table_number := table_number();
        l_tbl_notes                   table_varchar := table_varchar();
        l_tbl_notes_scheduler         table_varchar := table_varchar();
        l_tbl_notes_technician        table_varchar := table_varchar();
        l_tbl_notes_patient           table_varchar := table_varchar();
        l_tbl_diagnosis_notes         table_varchar := table_varchar();
        l_tbl_exec_institution        table_number := table_number();
        l_tbl_clinical_purpose        table_number := table_number();
        l_tbl_clinical_purpose_notes  table_varchar := table_varchar();
        l_tbl_flg_col_inst            table_varchar := table_varchar();
        l_tbl_flg_fasting             table_varchar := table_varchar();
        l_tbl_lab_req                 table_number := table_number();
        l_tbl_prof_cc                 table_table_varchar := table_table_varchar();
        l_tbl_prof_bcc                table_table_varchar := table_table_varchar();
        l_tbl_codification            table_number := table_number();
        l_tbl_health_plan             table_number := table_number();
        l_tbl_exemption               table_number := table_number();
        l_tbl_prof_order              table_number := table_number();
        l_tbl_dt_order                table_varchar := table_varchar();
        l_tbl_order_type              table_number := table_number();
        l_tbl_clinical_question       table_table_number := table_table_number();
        l_tbl_response                table_table_varchar := table_table_varchar();
        l_tbl_clinical_question_notes table_table_varchar := table_table_varchar();
        l_tbl_clinical_decision_rule  table_number := table_number();
        l_tbl_task_dependency         table_number := table_number();
        l_tbl_flg_task_depending      table_varchar := table_varchar();
        l_tbl_episode_followup_app    table_number := table_number();
        l_tbl_schedule_followup_app   table_number := table_number();
        l_tbl_event_followup_app      table_number := table_number();
    
        l_flg_show               VARCHAR2(1);
        l_msg_title              VARCHAR2(1000);
        l_msg_req                VARCHAR2(4000);
        l_button                 VARCHAR2(1000);
        l_analysis_req_array     table_number;
        l_analysis_req_det_array table_number;
        l_analysis_req_par_array table_number;
    BEGIN
    
        IF nvl(cardinality(i_analysis_req_det_origin), 0) = 0
        THEN
            RETURN TRUE;
        END IF;
    
        SELECT ar.*
          INTO r_analysis_req
          FROM analysis_req ar
         WHERE ar.id_analysis_req = i_analysis_req_origin;
    
        SELECT ard.id_analysis_req_det, ard.id_analysis, ard.id_sample_type
          BULK COLLECT
          INTO l_tbl_analysis_req_det, l_tbl_analysis, l_tbl_sample_type
          FROM analysis_req_det ard
         WHERE ard.id_analysis_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                            t.column_value
                                             FROM TABLE(i_analysis_req_det_origin) t);
    
        FOR i IN l_tbl_analysis.first .. l_tbl_analysis.last
        LOOP
            l_tbl_analysis_req_det_dummy.extend();
            l_tbl_analysis_req_det_dummy(l_tbl_analysis_req_det_dummy.count) := NULL;
        
            l_tbl_analysis_req_det_parent.extend();
            l_tbl_analysis_req_det_parent(l_tbl_analysis_req_det_parent.count) := NULL;
        
            l_tbl_analysis_group.extend();
            l_tbl_analysis_group(l_tbl_analysis_group.count) := table_varchar(NULL);
        
            l_tbl_flg_type.extend();
            l_tbl_flg_type(l_tbl_flg_type.count) := 'A'; --A - Lab tests
        
            l_tbl_dt_req.extend();
            -- settar data da requisicao de acordo com a regra [se dt_begin < data actual entao i_dt_req = i_dt_begin]
            IF to_timestamp(i_dt_begin, 'YYYYMMDDHH24MISS') < current_timestamp
            THEN
                l_tbl_dt_req(l_tbl_dt_req.count) := i_dt_begin;
            ELSE
                l_tbl_dt_req(l_tbl_dt_req.count) := NULL;
            END IF;
        
            l_tbl_flg_time.extend();
            l_tbl_flg_time(l_tbl_flg_time.count) := r_analysis_req.flg_time;
        
            l_tbl_dt_begin.extend();
            l_tbl_dt_begin(l_tbl_dt_begin.count) := i_dt_begin;
        
            l_tbl_dt_begin_limit.extend();
            l_tbl_dt_begin_limit(l_tbl_dt_begin_limit.count) := NULL;
        
            l_tbl_episode_destination.extend();
            l_tbl_episode_destination(l_tbl_episode_destination.count) := r_analysis_req.id_episode_destination;
        
            l_tbl_priority.extend();
            l_tbl_priority(l_tbl_priority.count) := r_analysis_req.flg_priority;
        
            l_tbl_body_location.extend();
            l_tbl_body_location(l_tbl_body_location.count) := table_number(NULL);
        
            l_tbl_laterality.extend();
            l_tbl_laterality(l_tbl_laterality.count) := table_varchar(NULL);
        
            SELECT ar.*
              INTO r_analysis_req_det
              FROM analysis_req_det ar
             WHERE ar.id_analysis_req_det = l_tbl_analysis_req_det(i);
        
            l_tbl_collection_room.extend();
            l_tbl_collection_room(l_tbl_collection_room.count) := r_analysis_req_det.id_room;
        
            l_tbl_order_recurrence.extend();
            l_tbl_order_recurrence(l_tbl_order_recurrence.count) := r_analysis_req_det.id_order_recurrence;
        
            l_tbl_flg_prn.extend();
            l_tbl_flg_prn(l_tbl_flg_prn.count) := r_analysis_req_det.flg_prn;
        
            l_tbl_notes_prn.extend();
            l_tbl_notes_prn(l_tbl_notes_prn.count) := to_char(r_analysis_req_det.notes_prn);
        
            l_tbl_notes.extend();
            l_tbl_notes(l_tbl_notes.count) := r_analysis_req_det.notes;
        
            l_tbl_notes_scheduler.extend();
            l_tbl_notes_scheduler(l_tbl_notes_scheduler.count) := r_analysis_req_det.notes_scheduler;
        
            l_tbl_notes_technician.extend();
            l_tbl_notes_technician(l_tbl_notes_technician.count) := r_analysis_req_det.notes_scheduler;
        
            l_tbl_notes_patient.extend();
            l_tbl_notes_patient(l_tbl_notes_patient.count) := r_analysis_req_det.notes_patient;
        
            l_tbl_diagnosis_notes.extend();
            l_tbl_diagnosis_notes(l_tbl_diagnosis_notes.count) := r_analysis_req_det.diagnosis_notes;
        
            l_tbl_exec_institution.extend();
            l_tbl_exec_institution(l_tbl_exec_institution.count) := r_analysis_req_det.id_exec_institution;
        
            l_tbl_clinical_purpose.extend();
            l_tbl_clinical_purpose(l_tbl_clinical_purpose.count) := r_analysis_req_det.id_clinical_purpose;
        
            l_tbl_clinical_purpose_notes.extend();
            l_tbl_clinical_purpose_notes(l_tbl_clinical_purpose_notes.count) := r_analysis_req_det.clinical_purpose_notes;
        
            l_tbl_flg_col_inst.extend();
            l_tbl_flg_col_inst(l_tbl_flg_col_inst.count) := r_analysis_req_det.flg_col_inst;
        
            l_tbl_flg_fasting.extend();
            l_tbl_flg_fasting(l_tbl_flg_fasting.count) := r_analysis_req_det.flg_fasting;
        
            l_tbl_lab_req.extend();
            l_tbl_lab_req(l_tbl_lab_req.count) := NULL;
        
            l_tbl_prof_cc.extend();
            l_tbl_prof_cc(l_tbl_prof_cc.count) := table_varchar(NULL);
        
            l_tbl_prof_bcc.extend();
            l_tbl_prof_bcc(l_tbl_prof_bcc.count) := table_varchar(NULL);
        
            l_tbl_codification.extend();
            l_tbl_codification(l_tbl_codification.count) := r_analysis_req_det.id_analysis_codification;
        
            l_tbl_health_plan.extend();
            l_tbl_health_plan(l_tbl_health_plan.count) := r_analysis_req_det.id_pat_health_plan;
        
            l_tbl_exemption.extend();
            l_tbl_exemption(l_tbl_exemption.count) := r_analysis_req_det.id_pat_exemption;
        
            l_tbl_prof_order.extend();
            l_tbl_prof_order(l_tbl_prof_order.count) := NULL;
        
            l_tbl_dt_order.extend();
            l_tbl_dt_order(l_tbl_dt_order.count) := NULL;
        
            l_tbl_order_type .extend();
            l_tbl_order_type(l_tbl_order_type.count) := NULL;
        
            l_tbl_clinical_question.extend();
            l_tbl_clinical_question(l_tbl_clinical_question.count) := table_number(NULL);
        
            l_tbl_response.extend();
            l_tbl_response(l_tbl_response.count) := table_varchar(NULL);
        
            l_tbl_clinical_question_notes.extend();
            l_tbl_clinical_question_notes(l_tbl_clinical_question_notes.count) := table_varchar(NULL);
        
            l_tbl_clinical_decision_rule.extend();
            l_tbl_clinical_decision_rule(l_tbl_clinical_decision_rule.count) := NULL;
        
            l_tbl_task_dependency.extend();
            l_tbl_task_dependency(l_tbl_task_dependency.count) := NULL;
        
            l_tbl_flg_task_depending.extend();
            l_tbl_flg_task_depending(l_tbl_flg_task_depending.count) := NULL;
        
            l_tbl_episode_followup_app.extend();
            l_tbl_episode_followup_app(l_tbl_episode_followup_app.count) := NULL;
        
            l_tbl_schedule_followup_app.extend();
            l_tbl_schedule_followup_app(l_tbl_schedule_followup_app.count) := NULL;
        
            l_tbl_event_followup_app.extend();
            l_tbl_event_followup_app(l_tbl_event_followup_app.count) := NULL;
        END LOOP;
    
        g_error := l_func_name || ' - CALL PK_LAB_TESTS_API_DB.CREATE_LAB_TEST_ORDER';
        IF NOT pk_lab_tests_api_db.create_lab_test_order(i_lang                    => i_lang,
                                                         i_prof                    => profissional(r_analysis_req.id_prof_writes,
                                                                                                   r_analysis_req.id_institution,
                                                                                                   pk_episode.get_episode_software(i_lang       => i_lang,
                                                                                                                                   i_prof       => i_prof,
                                                                                                                                   i_id_episode => nvl(r_analysis_req.id_episode_origin,
                                                                                                                                                       r_analysis_req.id_episode))),
                                                         i_patient                 => i_id_patient,
                                                         i_episode                 => i_id_episode,
                                                         i_analysis_req            => NULL,
                                                         i_analysis_req_det        => l_tbl_analysis_req_det_dummy,
                                                         i_analysis_req_det_parent => l_tbl_analysis_req_det_parent,
                                                         i_harvest                 => NULL,
                                                         i_analysis                => l_tbl_analysis,
                                                         i_analysis_group          => l_tbl_analysis_group,
                                                         i_flg_type                => l_tbl_flg_type,
                                                         i_dt_req                  => l_tbl_dt_req,
                                                         i_flg_time                => l_tbl_flg_time,
                                                         i_dt_begin                => l_tbl_dt_begin,
                                                         i_dt_begin_limit          => l_tbl_dt_begin_limit,
                                                         i_episode_destination     => l_tbl_episode_destination,
                                                         i_order_recurrence        => l_tbl_order_recurrence,
                                                         i_priority                => l_tbl_priority,
                                                         i_flg_prn                 => l_tbl_flg_prn,
                                                         i_notes_prn               => l_tbl_notes_prn,
                                                         i_specimen                => l_tbl_sample_type,
                                                         i_body_location           => l_tbl_body_location,
                                                         i_laterality              => l_tbl_laterality,
                                                         i_collection_room         => l_tbl_collection_room,
                                                         i_notes                   => l_tbl_notes,
                                                         i_notes_scheduler         => l_tbl_notes_scheduler,
                                                         i_notes_technician        => l_tbl_notes_technician,
                                                         i_notes_patient           => l_tbl_notes_patient,
                                                         i_diagnosis_notes         => l_tbl_diagnosis_notes,
                                                         i_diagnosis               => NULL,
                                                         i_exec_institution        => l_tbl_exec_institution,
                                                         i_clinical_purpose        => l_tbl_clinical_purpose,
                                                         i_clinical_purpose_notes  => l_tbl_clinical_purpose_notes,
                                                         i_flg_col_inst            => l_tbl_flg_col_inst,
                                                         i_flg_fasting             => l_tbl_flg_fasting,
                                                         i_lab_req                 => l_tbl_lab_req,
                                                         i_prof_cc                 => l_tbl_prof_cc,
                                                         i_prof_bcc                => l_tbl_prof_bcc,
                                                         i_codification            => l_tbl_codification,
                                                         i_health_plan             => l_tbl_health_plan,
                                                         i_exemption               => l_tbl_exemption,
                                                         i_prof_order              => l_tbl_prof_order,
                                                         i_dt_order                => l_tbl_dt_order,
                                                         i_order_type              => l_tbl_order_type,
                                                         i_clinical_question       => l_tbl_clinical_question,
                                                         i_response                => l_tbl_response,
                                                         i_clinical_question_notes => l_tbl_clinical_question_notes,
                                                         i_clinical_decision_rule  => l_tbl_clinical_decision_rule,
                                                         i_flg_origin_req          => 'S',
                                                         i_task_dependency         => l_tbl_task_dependency,
                                                         i_flg_task_depending      => l_tbl_flg_task_depending,
                                                         i_episode_followup_app    => l_tbl_episode_followup_app,
                                                         i_schedule_followup_app   => l_tbl_schedule_followup_app,
                                                         i_event_followup_app      => l_tbl_event_followup_app,
                                                         i_test                    => pk_alert_constant.g_no,
                                                         o_flg_show                => l_flg_show,
                                                         o_msg_title               => l_msg_title,
                                                         o_msg_req                 => l_msg_req,
                                                         o_button                  => l_button,
                                                         o_analysis_req_array      => l_analysis_req_array,
                                                         o_analysis_req_det_array  => l_analysis_req_det_array,
                                                         o_analysis_req_par_array  => l_analysis_req_par_array,
                                                         o_error                   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_flg_show = pk_alert_constant.g_yes
        THEN
            RETURN FALSE;
        END IF;
    
        o_ids_lab_test_req     := l_analysis_req_array;
        o_ids_lab_test_req_det := l_analysis_req_det_array;
    
        RETURN TRUE;
    
    END create_lab_test_req;

    /*
    * error handling e' feito na create_schedule
    */
    FUNCTION create_schedule_internal
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_sch_ext           IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_id_instit_requests   IN schedule.id_instit_requests%TYPE,
        i_id_instit_requested  IN schedule.id_instit_requested%TYPE,
        i_id_dcs_requests      IN schedule.id_dcs_requests%TYPE,
        i_id_dcs_requested     IN schedule.id_dcs_requested%TYPE,
        i_id_prof_requests     IN schedule.id_prof_requests%TYPE,
        i_id_prof_schedules    IN schedule.id_prof_schedules%TYPE,
        i_flg_status           IN schedule.flg_status%TYPE,
        i_id_sch_event         IN schedule.id_sch_event%TYPE,
        i_schedule_notes       IN schedule.schedule_notes%TYPE,
        i_id_lang_preferred    IN schedule.id_lang_preferred%TYPE,
        i_id_reason            IN schedule.id_reason%TYPE,
        i_id_origin            IN schedule.id_origin%TYPE,
        i_id_room              IN schedule.id_room%TYPE,
        i_flg_notification     IN schedule.flg_notification%TYPE,
        i_id_schedule_ref      IN schedule.id_schedule_ref%TYPE,
        i_flg_vacancy          IN schedule.flg_vacancy%TYPE,
        i_flg_sch_type         IN schedule.flg_sch_type%TYPE,
        i_reason_notes         IN schedule.reason_notes%TYPE,
        i_dt_begin             IN schedule.dt_begin_tstz%TYPE,
        i_dt_end               IN schedule.dt_end_tstz%TYPE,
        i_dt_request           IN schedule.dt_request_tstz%TYPE,
        i_flg_schedule_via     IN schedule.flg_schedule_via%TYPE,
        i_id_prof_notif        IN schedule.id_prof_notification%TYPE,
        i_dt_notification      IN schedule.dt_notification_tstz%TYPE,
        i_flg_notification_via IN schedule.flg_notification_via%TYPE,
        i_flg_request_type     IN schedule.flg_request_type%TYPE,
        i_id_episode           IN schedule.id_episode%TYPE,
        i_id_multidisc         IN schedule.id_multidisc%TYPE,
        i_id_group             IN schedule.id_group%TYPE,
        i_patients             IN t_persons,
        i_ids_profs            IN table_number,
        i_id_prof_leader       IN sch_resource.id_professional%TYPE,
        i_id_sch_procedure     IN NUMBER, -- e' o alert_apsschdlr_tr.schedule_procedure.id_schedule_procedure
        i_flg_reason_type      IN schedule.flg_reason_type%TYPE,
        i_video_link           IN schedule.video_link%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN schedule.id_schedule%TYPE IS
        l_func_name VARCHAR2(31) := 'CREATE_SCHEDULE_INTERNAL';
        l_id_sch    schedule.id_schedule%TYPE;
        i           PLS_INTEGER;
        --        l_reason_notes schedule.reason_notes%TYPE;
        l_id_leader      sch_resource.id_professional%TYPE;
        l_leader_found   BOOLEAN := FALSE;
        l_patient        t_person;
        l_no_patient     EXCEPTION;
        l_bool           BOOLEAN;
        l_no_patient_msg VARCHAR2(200);
    BEGIN
    
        g_error  := 'CREATE_SCHEDULE_INTERNAL - TS_SCHEDULE.INS';
        l_id_sch := ts_schedule.ins(id_instit_requests_in     => i_id_instit_requests,
                                    id_instit_requested_in    => i_id_instit_requested,
                                    id_dcs_requests_in        => i_id_dcs_requests,
                                    id_dcs_requested_in       => i_id_dcs_requested,
                                    id_prof_requests_in       => i_id_prof_requests,
                                    id_prof_schedules_in      => i_id_prof_schedules,
                                    flg_status_in             => get_sch_flg_status(i_flg_status),
                                    id_prof_cancel_in         => NULL,
                                    schedule_notes_in         => i_schedule_notes,
                                    id_cancel_reason_in       => NULL,
                                    id_lang_translator_in     => i_id_lang_preferred,
                                    id_lang_preferred_in      => i_id_lang_preferred,
                                    id_sch_event_in           => i_id_sch_event,
                                    id_reason_in              => i_id_reason,
                                    id_origin_in              => i_id_origin,
                                    id_room_in                => i_id_room,
                                    flg_urgency_in            => pk_alert_constant.g_no,
                                    schedule_cancel_notes_in  => NULL,
                                    flg_notification_in       => nvl(i_flg_notification,
                                                                     pk_schedule.g_sched_flg_notif_pending),
                                    id_schedule_ref_in        => i_id_schedule_ref,
                                    flg_vacancy_in            => i_flg_vacancy,
                                    flg_sch_type_in           => i_flg_sch_type,
                                    reason_notes_in           => i_reason_notes, --l_reason_notes,
                                    dt_begin_tstz_in          => i_dt_begin,
                                    dt_cancel_tstz_in         => NULL,
                                    dt_end_tstz_in            => i_dt_end,
                                    dt_request_tstz_in        => i_dt_request,
                                    dt_schedule_tstz_in       => g_sysdate_tstz,
                                    flg_instructions_in       => NULL,
                                    flg_schedule_via_in       => i_flg_schedule_via,
                                    id_prof_notification_in   => i_id_prof_notif,
                                    dt_notification_tstz_in   => i_dt_notification,
                                    flg_notification_via_in   => i_flg_notification_via,
                                    id_sch_consult_vacancy_in => NULL,
                                    flg_request_type_in       => i_flg_request_type,
                                    id_episode_in             => i_id_episode, -- pode vir do exterior ou ser obtido e passado pelos create_schedule_xxxx
                                    id_schedule_recursion_in  => NULL,
                                    create_user_in            => NULL,
                                    create_time_in            => NULL,
                                    create_institution_in     => NULL,
                                    update_user_in            => NULL,
                                    update_time_in            => NULL,
                                    update_institution_in     => NULL,
                                    flg_present_in            => NULL,
                                    id_multidisc_in           => i_id_multidisc,
                                    id_sch_combi_detail_in    => NULL,
                                    id_group_in               => i_id_group,
                                    flg_reason_type_in        => i_flg_reason_type,
                                    video_link_in             => i_video_link,
                                    handle_error_in           => FALSE);
    
        -- inserir pacientes
        g_error := 'CREATE_SCHEDULE_INTERNAL - TS_SCH_GROUP.INS';
        IF i_patients IS NOT NULL
           AND i_patients.count > 0
        THEN
            i := i_patients.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_patients(i).id_patient IS NULL
                THEN
                    l_no_patient_msg := 'CREATE_SCHEDULE_INTERNAL - NULL PATIENT FOR ID_SCHEDULE ' || l_id_sch;
                    RAISE l_no_patient;
                END IF;
                ts_sch_group.ins(id_schedule_in        => l_id_sch,
                                 id_patient_in         => i_patients(i).id_patient,
                                 create_user_in        => NULL,
                                 create_time_in        => NULL,
                                 create_institution_in => NULL,
                                 update_user_in        => NULL,
                                 update_time_in        => NULL,
                                 update_institution_in => NULL,
                                 flg_ref_type_in       => i_patients(i).flg_ref_type,
                                 id_prof_ref_in        => i_patients(i).id_prof_referrer_ext,
                                 id_inst_ref_in        => i_patients(i).id_inst_referrer_ext,
                                 id_cancel_reason_in   => i_patients(i).id_noshow_reason,
                                 no_show_notes_in      => i_patients(i).noshow_notes,
                                 flg_contact_type_in   => i_patients(i).flg_contact_type,
                                 id_health_plan_in     => i_patients(i).id_health_plan,
                                 auth_code_in          => i_patients(i).auth_code,
                                 dt_auth_code_exp_in   => i_patients(i).dt_auth_code_exp,
                                 pat_instructions_in   => i_patients(i).pat_instructions,
                                 handle_error_in       => FALSE);
                i := i_patients.next(i);
            END LOOP;
        ELSE
            l_no_patient_msg := 'CREATE_SCHEDULE_INTERNAL - NO PATIENTS FOR ID_SCHEDULE ' || l_id_sch;
            RAISE l_no_patient;
        END IF;
    
        -- inserir profs
        g_error := 'CREATE_SCHEDULE_INTERNAL - TS_SCH_RESOURCE.INS';
        IF i_ids_profs IS NOT NULL
           AND i_ids_profs.count > 0
        THEN
            i := i_ids_profs.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_ids_profs(i) > -1
                THEN
                    -- decide leader
                    g_error := 'CREATE_SCHEDULE_INTERNAL - DECIDE LEADER';
                    IF i_id_prof_leader IS NOT NULL
                    THEN
                        l_leader_found := TRUE;
                        l_id_leader    := i_id_prof_leader;
                    ELSIF NOT l_leader_found
                    THEN
                        l_leader_found := TRUE;
                        l_id_leader    := i_ids_profs(i);
                    END IF;
                
                    ts_sch_resource.ins(id_schedule_in            => l_id_sch,
                                        id_institution_in         => i_id_instit_requested,
                                        id_professional_in        => i_ids_profs(i),
                                        dt_sch_resource_tstz_in   => g_sysdate_tstz,
                                        create_user_in            => NULL,
                                        create_time_in            => NULL,
                                        create_institution_in     => NULL,
                                        update_user_in            => NULL,
                                        update_time_in            => NULL,
                                        update_institution_in     => NULL,
                                        flg_leader_in             => (CASE
                                                                         WHEN l_id_leader = i_ids_profs(i) THEN
                                                                          pk_alert_constant.g_yes
                                                                         ELSE
                                                                          pk_alert_constant.g_no
                                                                     END),
                                        id_sch_consult_vacancy_in => NULL,
                                        handle_error_in           => FALSE);
                END IF;
                i := i_ids_profs.next(i);
            END LOOP;
        END IF;
    
        -- mapear ids na sch_api_map_ids
        IF i_id_sch_ext IS NOT NULL --pk_schedule_api_upstream.is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
        THEN
            g_error := 'CREATE_SCHEDULE_INTERNAL - TS_SCH_MAP_API_IDS.ins';
            ts_sch_api_map_ids.ins(id_schedule_pfh_in       => l_id_sch,
                                   id_schedule_ext_in       => i_id_sch_ext,
                                   create_user_in           => NULL,
                                   create_time_in           => NULL,
                                   create_institution_in    => NULL,
                                   update_user_in           => NULL,
                                   update_time_in           => NULL,
                                   update_institution_in    => NULL,
                                   handle_error_in          => FALSE,
                                   id_schedule_procedure_in => i_id_sch_procedure);
        END IF;
    
        RETURN l_id_sch;
    
    EXCEPTION
        WHEN l_no_patient THEN
            pk_alertlog.log_fatal(text => l_no_patient_msg, object_name => g_package_name, owner => g_package_owner);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -3049,
                                              i_sqlerrm  => l_no_patient_msg,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN NULL;
    END create_schedule_internal;

    /*
    *
    */
    FUNCTION create_schedule_outp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_prof_schedules IN professional.id_professional%TYPE,
        i_id_patient        IN sch_group.id_patient%TYPE,
        i_id_dep_clin_serv  IN schedule.id_dcs_requested%TYPE,
        i_id_sch_event      IN schedule.id_sch_event%TYPE,
        i_id_prof           IN sch_resource.id_professional%TYPE,
        i_dt_begin          IN schedule.dt_begin_tstz%TYPE,
        i_schedule_notes    IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_institution    IN institution.id_institution%TYPE DEFAULT NULL,
        i_id_episode        IN consult_req.id_episode%TYPE DEFAULT NULL,
        i_flg_sched_type    IN schedule_outp.flg_sched_type%TYPE DEFAULT NULL,
        i_procedure_reqs    IN t_procedure_reqs,
        i_id_schedule_proc  IN NUMBER,
        i_persons           IN t_persons,
        i_dt_referral       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := $$PLSQL_UNIT;
        o_consult_req_rec      consult_req%ROWTYPE;
        o_consult_req_prof_rec consult_req_prof%ROWTYPE;
        l_schedule_interface   BOOLEAN;
        l_flg_sched_type       schedule_outp.flg_sched_type%TYPE := NULL;
        l_func_exception       EXCEPTION;
        l_id_institution       institution.id_institution%TYPE := i_id_institution;
        l_outp_software_conf   VARCHAR2(32) := 'SOFTWARE_ID_OUTP';
        l_care_software_conf   VARCHAR2(32) := 'SOFTWARE_ID_CARE';
        l_inp_software_conf    VARCHAR2(32) := 'SOFTWARE_ID_INP';
        l_edis_software_conf   VARCHAR2(32) := 'SOFTWARE_ID_EDIS';
        l_oris_software_conf   VARCHAR2(32) := 'SOFTWARE_ID_ORIS';
        l_id_software          sys_config.value%TYPE;
        l_id_software_care     sys_config.value%TYPE;
        l_id_software_edis     sys_config.value%TYPE;
        l_id_software_oris     sys_config.value%TYPE;
        l_id_software_inp      sys_config.value%TYPE;
        l_id_software_outp     sys_config.value%TYPE;
        l_flg_type             schedule_outp.flg_type%TYPE;
        l_epis_type            sys_config.value%TYPE;
        l_flg_sched            schedule_outp.flg_sched%TYPE;
        l_target_prof          sch_event.flg_target_professional%TYPE;
        l_compare              NUMBER;
        l_date_compare         VARCHAR2(1);
        l_id_schedule_outp     schedule_outp.id_schedule_outp%TYPE;
        l_rows_ei              table_varchar;
        i                      PLS_INTEGER;
        l_procreq              t_procedure_req;
        l_flg_state            schedule_outp.flg_state%TYPE := pk_schedule.g_status_scheduled;
        l_dep_type             sch_event.dep_type%TYPE;
    
        --ehr access
        l_id_access_context ehr_access_context.id_ehr_access_context%TYPE;
        l_dummy_n           NUMBER;
        l_dummy_v           VARCHAR2(4000 CHAR);
    
        l_epis_type_nurse sys_config.value%TYPE;
    BEGIN
        IF (i_id_institution IS NULL)
        THEN
            l_id_institution := i_prof.institution;
        END IF;
    
        -- Check if there is an interface with an external system
        g_error := l_func_name || ' - PK_SCHEDULE_COMMON.CHECK_INTERFACE_EXISTENCE';
        IF NOT pk_schedule_common.exist_interface(i_lang   => i_lang,
                                                  i_prof   => i_prof,
                                                  o_exists => l_schedule_interface,
                                                  o_error  => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := l_func_name || ' - GET INPATIENT SOFTWARE';
        -- Get the inpatient software
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => l_inp_software_conf,
                                             i_id_institution => l_id_institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => l_id_software_inp,
                                             o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := l_func_name || ' - GET EDIS SOFTWARE';
        -- Get the edis software
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => l_edis_software_conf,
                                             i_id_institution => l_id_institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => l_id_software_edis,
                                             o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := l_func_name || ' - GET ORIS SOFTWARE';
        -- Get the oris software
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => l_oris_software_conf,
                                             i_id_institution => l_id_institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => l_id_software_oris,
                                             o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := l_func_name || ' - GET OUTP SOFTWARE';
        -- Get the outpatient software
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => l_outp_software_conf,
                                             i_id_institution => l_id_institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => l_id_software_outp,
                                             o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- get the event dep_type
        g_error := l_func_name || ' - GET EVENT DEP_TYPE VALUE';
        SELECT dep_type
          INTO l_dep_type
          FROM sch_event se
         WHERE se.id_sch_event = i_id_sch_event;
    
        IF i_prof.software IN (l_id_software_inp, l_id_software_edis, l_id_software_oris, l_id_software_outp)
           AND l_dep_type = g_dep_type_phys_app
        THEN
            l_id_software := l_id_software_outp;
        ELSE
            -- Create the appointment using the software configured in sch_event_soft
            BEGIN
                SELECT id_software_dest
                  INTO l_id_software
                  FROM (SELECT id_software_dest, row_number() over(ORDER BY ses.id_software DESC) line_number
                          FROM sch_event_soft ses
                         WHERE ses.id_software IN (pk_alert_constant.g_soft_all, i_prof.software)
                           AND ses.id_sch_event = i_id_sch_event)
                 WHERE line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_software := i_prof.software;
            END;
        END IF;
    
        l_epis_type_nurse := pk_sysconfig.get_config(i_code_cf => 'ID_EPIS_TYPE_NURSE',
                                                     i_prof    => profissional(i_prof.id,
                                                                               i_prof.institution,
                                                                               l_id_software));
    
        -- Get episode type
        g_error := l_func_name || ' - GET EPISODE TYPE';
        IF NOT pk_schedule_common.get_sch_event_epis_type(i_lang,
                                                          i_id_sch_event => i_id_sch_event,
                                                          i_id_inst      => l_id_institution,
                                                          i_id_software  => i_prof.software, -- aqui tem mesmo de ser o i_prof.software e nao o l_id_software
                                                          o_epis_type    => l_epis_type,
                                                          o_error        => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        g_error := l_func_name || ' - GET EPIS TYPE CONFIG';
        IF l_epis_type IS NULL
           AND NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                                 i_id_sysconfig   => pk_schedule.g_sched_epis_type_config,
                                                 i_id_institution => l_id_institution,
                                                 i_id_software    => to_number(i_prof.software),
                                                 o_config         => l_epis_type,
                                                 o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- Get the CARE software
        g_error := l_func_name || ' - GET CARE SOFTWARE';
        IF NOT pk_schedule_common.get_config(i_lang           => i_lang,
                                             i_id_sysconfig   => l_care_software_conf,
                                             i_id_institution => l_id_institution,
                                             i_id_software    => i_prof.software,
                                             o_config         => l_id_software_care,
                                             o_error          => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF l_id_software_care = i_prof.software
           AND l_epis_type != l_epis_type_nurse
        THEN
            g_error := l_func_name || ' - COMPARE DATES';
            SELECT pk_date_utils.get_timestamp_diff(pk_date_utils.trunc_insttimezone(profissional(i_id_prof_schedules,
                                                                                                  l_id_institution,
                                                                                                  i_prof.software),
                                                                                     i_dt_begin),
                                                    pk_date_utils.trunc_insttimezone(profissional(i_id_prof_schedules,
                                                                                                  l_id_institution,
                                                                                                  i_prof.software),
                                                                                     g_sysdate_tstz))
              INTO l_compare
              FROM dual;
            IF l_compare >= 1
            THEN
                l_date_compare := pk_schedule_common.g_date_greater;
            ELSE
                l_date_compare := pk_schedule_common.g_date_minor;
            END IF;
            -- Get event type and target
            g_error := l_func_name || ' - GET EVENT TYPE AND TARGET';
            SELECT CASE
                        WHEN se.flg_is_group = pk_alert_constant.g_yes THEN
                         se.flg_schedule_outp_type
                        WHEN se.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cm THEN
                         se.flg_schedule_outp_type
                        ELSE
                         decode(i_flg_sched_type,
                                pk_schedule_common.g_val_spresenca,
                                pk_schedule_common.g_val_indirect,
                                decode(l_date_compare,
                                       pk_schedule_common.g_date_greater,
                                       decode(se.flg_occurrence,
                                              pk_schedule.g_event_occurrence_first,
                                              pk_schedule_common.g_val_fprogramada,
                                              pk_schedule_common.g_val_programada),
                                       decode(se.flg_occurrence,
                                              pk_schedule.g_event_occurrence_first,
                                              pk_schedule_common.g_val_fdia,
                                              pk_schedule_common.g_val_dia)))
                    END flg_schedule_outp_type,
                   se.flg_target_professional,
                   decode(se.flg_occurrence,
                          pk_schedule.g_event_occurrence_first,
                          pk_schedule_outp.g_schedule_outp_flg_type_first,
                          pk_schedule.g_event_occurrence_subs,
                          pk_schedule_outp.g_schedule_outp_flg_type_subs,
                          '')
              INTO l_flg_sched, l_target_prof, l_flg_type
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event
               AND pk_schedule_common.get_sch_event_avail(i_id_sch_event, i_id_institution, i_prof.software) =
                   pk_alert_constant.g_yes;
        ELSE
            g_error := l_func_name || ' - GET EVENT TYPE AND TARGET';
            -- Get event type and target
            SELECT se.flg_schedule_outp_type,
                   se.flg_target_professional,
                   decode(se.flg_occurrence,
                          pk_schedule.g_event_occurrence_first,
                          pk_schedule_outp.g_schedule_outp_flg_type_first,
                          pk_schedule.g_event_occurrence_subs,
                          pk_schedule_outp.g_schedule_outp_flg_type_subs,
                          '')
              INTO l_flg_sched, l_target_prof, l_flg_type
              FROM sch_event se
             WHERE se.id_sch_event = i_id_sch_event
               AND pk_schedule_common.get_sch_event_avail(i_id_sch_event, i_id_institution, i_prof.software) =
                   pk_alert_constant.g_yes;
        
        END IF;
    
        -- calc flg_state based on the existence of patients no-show
        g_error := l_func_name || ' - CALC FLG_STATE';
        IF i_persons IS NOT NULL
           AND i_persons.count > 0
        THEN
            i := i_persons.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_persons(i).id_noshow_reason IS NOT NULL
                THEN
                    l_flg_state := 'B';
                END IF;
            
                i := i_persons.next(i);
            END LOOP;
        END IF;
    
        g_error := l_func_name || ' - TS_SCHEDULE_OUTP.INS';
        -- Create outpatient-specific schedule
        ts_schedule_outp.ins(id_schedule_in        => i_id_schedule,
                             flg_state_in          => l_flg_state,
                             flg_sched_in          => l_flg_sched,
                             id_software_in        => to_number(l_id_software),
                             id_epis_type_in       => l_epis_type,
                             flg_type_in           => l_flg_type,
                             dt_target_tstz_in     => i_dt_begin,
                             flg_sched_type_in     => i_flg_sched_type,
                             create_user_in        => NULL,
                             create_time_in        => NULL,
                             create_institution_in => NULL,
                             update_user_in        => NULL,
                             update_time_in        => NULL,
                             update_institution_in => NULL,
                             id_schedule_outp_out  => l_id_schedule_outp,
                             handle_error_in       => FALSE);
    
        -- Create outpatient schedule's professional
        IF nvl(i_id_prof, -1) > -1
        THEN
            g_error := l_func_name || ' - TS_SCH_PROF_OUTP.INS';
            ts_sch_prof_outp.ins(id_professional_in    => i_id_prof,
                                 id_schedule_outp_in   => l_id_schedule_outp,
                                 create_user_in        => NULL,
                                 create_time_in        => NULL,
                                 create_institution_in => NULL,
                                 update_user_in        => NULL,
                                 update_time_in        => NULL,
                                 update_institution_in => NULL,
                                 handle_error_in       => FALSE);
        
            g_error := l_func_name || ' - TS_EPIS_INFO.UPD';
            ts_epis_info.upd(sch_prof_outp_id_prof_in => i_id_prof,
                             where_in                 => 'ID_SCHEDULE_OUTP = ' || l_id_schedule_outp,
                             rows_out                 => l_rows_ei,
                             handle_error_in          => FALSE);
        
            g_error := l_func_name || ' - T_DATA_GOV_MNT.PROCESS UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => profissional(0, 0, 0),
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rows_ei,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('SCH_PROF_OUTP_ID_PROF'));
        
        END IF;
    
        -- link to referral this schedule id to the supplied external request ids
        IF i_persons IS NOT NULL
           AND i_persons.count > 0
        THEN
            i := i_persons.first;
            WHILE i IS NOT NULL
            LOOP
                -- procurar pelo id_external_request para mandar
                g_error   := l_func_name || ' - GET_PROCEDURE_REQ_DATA';
                l_procreq := get_procedure_req_data(i_procedure_reqs        => i_procedure_reqs,
                                                    i_id_schedule_procedure => i_id_schedule_proc,
                                                    i_id_patient            => i_persons(i).id_patient,
                                                    i_id_type               => g_proc_req_type_ref);
            
                IF l_procreq.id IS NOT NULL
                THEN
                    g_error := l_func_name || ' - CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE with id_external_request: ' ||
                               l_procreq.id;
                    IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_id_ref   => l_procreq.id,
                                                           i_schedule => i_id_schedule,
                                                           i_notes    => i_schedule_notes,
                                                           i_episode  => NULL, --i_id_episode, -- retirado ate se garantir a passagem dum id de confianca
                                                           i_date     => coalesce(i_dt_referral, current_timestamp),
                                                           o_error    => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                END IF;
            
                i := i_persons.next(i);
            END LOOP;
        END IF;
    
        -- Create data in consult request if there are no interfaces and ALERT is not the primary application for schedules
        IF NOT l_schedule_interface
        THEN
            g_error := l_func_name || ' - PK_SCHEDULE_COMMON.NEW_CONSULT_REQ';
            IF NOT pk_schedule_common.new_consult_req(i_lang                => i_lang,
                                                      i_dt_consult_req_tstz => current_timestamp,
                                                      i_id_patient          => i_id_patient,
                                                      i_id_instit_requests  => i_prof.institution,
                                                      i_id_inst_requested   => l_id_institution,
                                                      i_id_episode          => NULL, --i_id_episode,-- retirado ate se garantir a passagem dum id de confianca
                                                      i_id_prof_req         => i_prof.id,
                                                      i_dt_scheduled_tstz   => i_dt_begin,
                                                      i_notes_admin         => i_schedule_notes,
                                                      i_id_prof_cancel      => NULL,
                                                      i_dt_cancel_tstz      => NULL,
                                                      i_notes_cancel        => NULL,
                                                      i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                                      i_id_prof_requested   => i_id_prof,
                                                      i_id_schedule         => i_id_schedule,
                                                      i_flg_status          => pk_consult_req.g_consult_req_stat_reply,
                                                      o_consult_req_rec     => o_consult_req_rec,
                                                      o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            g_error := l_func_name || ' - PK_SCHEDULE_COMMON.NEW_CONSULT_REQ_PROF';
            IF NOT pk_schedule_common.new_consult_req_prof(i_lang                     => i_lang,
                                                           i_dt_consult_req_prof_tstz => current_timestamp,
                                                           i_id_consult_req           => o_consult_req_rec.id_consult_req,
                                                           i_id_professional          => i_prof.id,
                                                           i_denial_justif            => NULL,
                                                           i_flg_status               => pk_schedule.g_status_scheduled,
                                                           i_dt_scheduled_tstz        => i_dt_begin,
                                                           o_consult_req_prof_rec     => o_consult_req_prof_rec,
                                                           o_error                    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule_outp;

    /*
    *
    */
    FUNCTION create_schedule_exam
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_ids_exam_req_dets IN table_number,
        i_dt_begin          IN schedule.dt_begin_tstz%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_ids_exams         IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_flg_status        IN schedule.flg_status%TYPE,
        i_id_inst           IN schedule.id_instit_requested%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name           VARCHAR2(32) := $$PLSQL_UNIT;
        l_sched_exam_rec      schedule_exam%ROWTYPE;
        l_flg_preparation     VARCHAR2(1 CHAR); --exam.flg_pat_prep%TYPE;
        l_prep_desc           sys_domain.desc_val%TYPE;
        l_func_exception      EXCEPTION;
        l_id_exam             exam.id_exam%TYPE;
        l_id_exam_req         exam_req.id_exam_req%TYPE;
        l_id_exam_req_det     exam_req_det.id_exam_req_det%TYPE;
        l_status              exam_req_det.flg_status%TYPE;
        l_o_ids_exam_req      table_number;
        l_o_ids_exam_req_det  table_number;
        i                     PLS_INTEGER;
        l_mismatched_ids      EXCEPTION;
        l_mism_msg            sys_message.desc_message%TYPE;
        l_dummy               VARCHAR2(4000);
        l_ret_val             BOOLEAN;
        l_err_instance_id_out NUMBER(24);
        l_dt_begin            VARCHAR2(30) := pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
    
        l_count      PLS_INTEGER := 0;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        -- sem isto nada feito. Nao valido a i_ids_exam_req_dets porque pode vir nula, com 0 elementos ou com 1..l_ids_exams.count elementos
        IF nvl(cardinality(i_ids_exams), 0) = 0
        THEN
            RETURN TRUE;
        END IF;
    
        -- ciclar os exames
        i := i_ids_exams.first;
        WHILE i IS NOT NULL
        LOOP
            g_error   := l_func_name || ' - GET id_exam from collection i_ids_exams item ' || i;
            l_id_exam := i_ids_exams(i);
        
            l_id_exam_req := NULL;
        
            g_error           := l_func_name || ' - GET id_exam_req_det from collection i_ids_exam_req_dets item ' || i;
            l_id_exam_req_det := i_ids_exam_req_dets(i);
        
            -- se ja temos req, conferir se o exame que vem associado a esta req_det esta' correcto
            IF l_id_exam_req_det IS NOT NULL
            THEN
                -- isto verifica se o id_exam fornecido e' realmente o que consta na requisicao. Se nao for aborta 
                BEGIN
                    g_error := l_func_name || ' - GET ID_EXAM FROM EXAM_REQ_DET. i_id_exam_req_det=' ||
                               l_id_exam_req_det;
                    SELECT d.id_exam, d.id_exam_req
                      INTO l_id_exam, l_id_exam_req
                      FROM exam_req_det d
                     WHERE d.id_exam_req_det = l_id_exam_req_det
                       AND d.id_exam = l_id_exam;
                
                    l_o_ids_exam_req := table_number(l_id_exam_req);
                
                    l_count := 0;
                    SELECT COUNT(1)
                      INTO l_count
                      FROM schedule_exam se
                      JOIN schedule s
                        ON s.id_schedule = se.id_schedule
                     WHERE se.id_exam_req = l_id_exam_req
                       AND se.id_exam = l_id_exam
                       AND s.flg_status NOT IN ('C');
                
                    --Se a requisição já tem um agendamento, é necessário criar uma nova requisição.
                    --Isto acontece nas requisições com recorrência, o 1º agendamento fica com a req original,
                    --os subsequentes têm que ter uma requisição nova
                    IF l_count >= 1
                    THEN
                        SELECT er.id_episode
                          INTO l_id_episode
                          FROM exam_req er
                         WHERE er.id_exam_req = l_id_exam_req;
                    
                        g_error := l_func_name || ' - CALL CREATE_EXAM_REQ FOR id_exam=' || l_id_exam;
                        IF NOT create_exam_req(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => i_id_schedule,
                                               i_id_inst          => i_id_inst,
                                               i_ids_exams        => table_number(l_id_exam),
                                               i_dt_begin         => l_dt_begin,
                                               i_id_patient       => i_id_patient,
                                               i_flg_status       => i_flg_status,
                                               i_id_episode       => l_id_episode,
                                               o_ids_exam_req     => l_o_ids_exam_req,
                                               o_ids_exam_req_det => l_o_ids_exam_req_det,
                                               o_error            => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE l_mismatched_ids;
                END;
                -- se nao temos req para este exame vamos criar uma
            ELSE
                g_error := l_func_name || ' - CALL CREATE_EXAM_REQ FOR id_exam=' || l_id_exam;
                IF NOT create_exam_req(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_schedule      => i_id_schedule,
                                       i_id_inst          => i_id_inst,
                                       i_ids_exams        => table_number(l_id_exam),
                                       i_dt_begin         => l_dt_begin,
                                       i_id_patient       => i_id_patient,
                                       i_flg_status       => i_flg_status,
                                       i_id_episode       => i_id_episode,
                                       o_ids_exam_req     => l_o_ids_exam_req,
                                       o_ids_exam_req_det => l_o_ids_exam_req_det,
                                       o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- Check if the exam needs the patient to perform any preparation steps.
            g_error := l_func_name || ' - CALL PK_SCHEDULE_EXAM.HAS_PREPARATION';
            IF NOT pk_schedule_exam.has_preparation(i_lang      => i_lang,
                                                    i_id_exam   => l_id_exam,
                                                    o_flg_prep  => l_flg_preparation,
                                                    o_prep_desc => l_prep_desc,
                                                    o_error     => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- O l_id_exam_req precisa de ser obtido de novo
            -- porque se acabou de ser criado pela create_exam_order pode dar-se o caso de esta ter devolvido mais que 1 valor na o_exam_req_array
            g_error := l_func_name || ' - GET REQ ID. ID_PATIENT=' || to_char(i_id_patient) || ' ID_EXAM=' || l_id_exam;
            SELECT erd.id_exam_req, erd.id_exam_req_det
              INTO l_id_exam_req, l_id_exam_req_det
              FROM exam_req_det erd
              JOIN exam_req er
                ON erd.id_exam_req = er.id_exam_req
             WHERE er.id_patient = i_id_patient
               AND erd.id_exam = l_id_exam
               AND er.id_exam_req IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_o_ids_exam_req) t);
        
            -- Create exam-specific schedule
            g_error := l_func_name || ' - CALL TS_SCHEDULE_EXAM.INS';
            ts_schedule_exam.ins(id_schedule_in        => i_id_schedule,
                                 id_exam_in            => l_id_exam,
                                 flg_preparation_in    => l_flg_preparation,
                                 id_exam_req_in        => l_id_exam_req,
                                 create_user_in        => NULL,
                                 create_time_in        => NULL,
                                 create_institution_in => NULL,
                                 update_user_in        => NULL,
                                 update_time_in        => NULL,
                                 update_institution_in => NULL,
                                 handle_error_in       => FALSE);
        
            -- settar data do agendamento na req.
            -- Isto e' preciso nos casos em que a req. ja' existe e portanto nao foi criada nesta funcao
            g_error := l_func_name || ' - CALL PK_EXAMS_API_DB.SET_EXAM_DATE';
            IF NOT pk_exams_api_db.set_exam_date(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_exam_req        => l_id_exam_req,
                                                 i_dt_begin        => l_dt_begin, --
                                                 i_notes_scheduler => NULL, --
                                                 o_error           => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            SELECT erd.flg_status
              INTO l_status
              FROM exam_req_det erd
             WHERE erd.id_exam_req_det = l_id_exam_req_det;
        
            IF l_status != 'A'
            THEN
                -- settar status da requisicao
                g_error := l_func_name || ' - CALL PK_EXAMS_API_DB.SET_EXAM_STATUS';
                IF NOT pk_exams_api_db.set_exam_status(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_exam_req_det    => table_number(l_id_exam_req_det),
                                                       i_status          => 'A',
                                                       i_notes           => NULL,
                                                       i_notes_scheduler => NULL,
                                                       o_error           => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            i := i_ids_exams.next(i);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_mismatched_ids THEN
            l_mism_msg := pk_message.get_message(i_lang, g_sched_msg_exam_req_mismatch);
        
            l_ret_val := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                            i_func_proc_name => l_func_name,
                                                            i_package_name   => g_package_name,
                                                            i_package_error  => 5550,
                                                            i_sql_error      => l_mism_msg,
                                                            i_log_on         => TRUE,
                                                            o_error          => l_dummy);
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 5550,
                                   ora_sqlerrm         => l_mism_msg,
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule_exam;

    /*
    * NOTA: nao existe na sch3 o conceito de agendamento temporario (é quando o planner está a criar agendamentos oris/inp).
    * por isso aqui assume-se que sao todos definitivos tirando indicacao expressa em contrario no i_flg_tempor.
    */
    FUNCTION create_schedule_inp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_wl               IN waiting_list.id_waiting_list%TYPE,
        i_id_bed              IN schedule_bed.id_bed%TYPE,
        i_flg_sch_type        IN schedule.flg_sch_type%TYPE,
        i_id_schedule         IN schedule.id_schedule%TYPE,
        i_flg_tempor          IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_episode          IN wtl_epis.id_episode%TYPE,
        i_id_patient          IN sch_group.id_patient%TYPE,
        i_dt_end              IN VARCHAR2,
        i_id_room             IN schedule.id_room%TYPE,
        i_id_external_request IN waiting_list.id_external_request%TYPE,
        i_schedule_notes      IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_dt_referral         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := $$PLSQL_UNIT;
        l_func_exception EXCEPTION;
        l_dummy          sch_consult_vacancy.id_sch_consult_vacancy%TYPE;
        l_id_room        bed.id_room%TYPE := i_id_room;
        l_rowids         table_varchar;
    BEGIN
    
        -- get room if not supplied. Se nao encontrar vai para o when others principal
        g_error := l_func_name || ' - GET ROOM ID';
        IF l_id_room IS NULL
           AND i_id_bed IS NOT NULL
        THEN
            SELECT id_room
              INTO l_id_room
              FROM bed
             WHERE id_bed = i_id_bed;
        END IF;
    
        -- inserir na schedule_bed
        g_error := l_func_name || ' - TS_SCHEDULE_BED.INS';
        ts_schedule_bed.ins(id_schedule_in        => i_id_schedule,
                            id_bed_in             => i_id_bed,
                            id_waiting_list_in    => i_id_wl,
                            flg_temporary_in      => i_flg_tempor,
                            flg_conflict_in       => pk_alert_constant.g_no,
                            create_user_in        => NULL,
                            create_institution_in => NULL,
                            update_user_in        => NULL,
                            update_institution_in => NULL,
                            create_time_in        => NULL,
                            update_time_in        => NULL,
                            handle_error_in       => FALSE);
    
        -- update WL
        g_error := l_func_name || ' - PK_WTL_PBL_CORE.SET_SCHEDULE';
        IF NOT pk_wtl_pbl_core.set_schedule(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_wtlist   => i_id_wl,
                                            i_id_episode  => i_id_episode,
                                            i_id_schedule => i_id_schedule,
                                            o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- update epis_info
        g_error := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in   => i_id_episode,
                         id_schedule_in  => i_id_schedule,
                         id_schedule_nin => FALSE,
                         rows_out        => l_rowids);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE EPIS_INFO';
        --Process the events associated to an update on epis_info                         
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF (i_id_external_request IS NOT NULL)
        THEN
            g_error := l_func_name || ' - CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE with id_external_request: ' ||
                       i_id_external_request;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, owner => g_package_owner);
        
            IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_ref   => i_id_external_request,
                                                   i_schedule => i_id_schedule,
                                                   i_notes    => i_schedule_notes,
                                                   i_episode  => i_id_episode,
                                                   i_date     => coalesce(i_dt_referral, current_timestamp),
                                                   o_error    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule_inp;

    /*
    * NOTA: nao existe na sch3 o conceito de agendamento temporario (é quando o planner está a criar agendamentos oris/inp).
    * por isso aqui assume-se que sao todos definitivos tirando indicacao expressa em contrario no i_flg_tempor.
    */
    FUNCTION create_schedule_oris
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_sch_ext            IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_dt_begin              IN schedule.dt_begin_tstz%TYPE,
        i_dt_end                IN schedule.dt_end_tstz%TYPE,
        i_id_wl                 IN NUMBER,
        i_id_room               IN schedule.id_room%TYPE DEFAULT NULL,
        i_id_instit_requests    IN schedule.id_instit_requests%TYPE DEFAULT NULL,
        i_id_instit_requested   IN schedule.id_instit_requested%TYPE,
        i_id_dcs_requests       IN schedule.id_dcs_requests%TYPE DEFAULT NULL,
        i_dcs_list              IN table_number,
        i_id_prof_requests      IN schedule.id_prof_requests%TYPE DEFAULT NULL,
        i_id_prof_schedules     IN schedule.id_prof_schedules%TYPE DEFAULT NULL,
        i_flg_status            IN schedule.flg_status%TYPE,
        i_id_sch_event          IN schedule.id_sch_event%TYPE,
        i_schedule_notes        IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_id_lang_preferred     IN schedule.id_lang_preferred%TYPE DEFAULT NULL,
        i_id_reason             IN schedule.id_reason%TYPE DEFAULT NULL,
        i_id_origin             IN schedule.id_origin%TYPE DEFAULT NULL,
        i_flg_notification      IN schedule.flg_notification%TYPE DEFAULT NULL,
        i_id_schedule_ref       IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_id_inst               IN institution.id_institution%TYPE,
        i_flg_vacancy           IN schedule.flg_vacancy%TYPE,
        i_notes                 IN schedule.schedule_notes%TYPE DEFAULT NULL,
        i_flg_sch_type          IN schedule.flg_sch_type%TYPE,
        i_reason_notes          IN schedule.reason_notes%TYPE DEFAULT NULL,
        i_dt_request            IN schedule.dt_request_tstz%TYPE DEFAULT NULL,
        i_flg_schedule_via      IN schedule.flg_schedule_via%TYPE DEFAULT NULL,
        i_id_prof_notif         IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        i_dt_notification       IN schedule.dt_notification_tstz%TYPE DEFAULT NULL,
        i_flg_notification_via  IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        i_flg_request_type      IN schedule.flg_request_type%TYPE DEFAULT NULL,
        i_id_episode            IN schedule.id_episode%TYPE DEFAULT NULL,
        i_persons               IN t_persons,
        i_id_profs_list         IN table_number,
        i_prof_leader           IN t_resource,
        i_dt_referral           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_schedule_procedure IN NUMBER,
        i_flg_reason_type       IN schedule.flg_reason_type%TYPE,
        o_id_schedule           OUT schedule.id_schedule%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name            VARCHAR2(32) := $$PLSQL_UNIT;
        l_id_patient           schedule_sr.id_patient%TYPE;
        l_dcs_list             table_number;
        l_id_profs_list        table_number;
        l_id_sch_event         sch_event.id_sch_event%TYPE;
        l_flg_urgency          VARCHAR2(1);
        l_duration             NUMBER;
        l_dpb                  waiting_list.dt_dpb%TYPE;
        l_dpa                  waiting_list.dt_dpa%TYPE;
        l_pref_dt_begin        TIMESTAMP WITH LOCAL TIME ZONE;
        l_pref_dt_end          TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_type             waiting_list.flg_type%TYPE;
        l_flg_status           waiting_list.flg_status%TYPE;
        l_dt_surgery           waiting_list.dt_surgery%TYPE;
        l_min_inform_time      waiting_list.min_inform_time%TYPE;
        l_id_urg_level         waiting_list.id_wtl_urg_level%TYPE;
        l_episodes             pk_wtl_pbl_core.t_rec_episodes;
        l_id_schedule          schedule.id_schedule%TYPE;
        l_id_episode           schedule.id_episode%TYPE;
        l_rec_dcss             pk_wtl_pbl_core.t_rec_dcss;
        i                      INTEGER;
        l_id_external_request  waiting_list.id_external_request%TYPE;
        l_func_exception       EXCEPTION;
        l_id_sch_sr            schedule_sr.id_schedule_sr%TYPE;
        l_notification_default sch_dcs_notification.notification_default%TYPE;
        l_patient              t_person;
        l_patients             t_persons;
        l_rowids               table_varchar;
    
    BEGIN
        -- fetch WL data
        g_error := l_func_name || ' - CALL PK_WTL_PBL_CORE.GET_DATA';
        IF NOT pk_wtl_pbl_core.get_data(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_id_waiting_list     => i_id_wl,
                                        o_id_patient          => l_id_patient,
                                        o_flg_type            => l_flg_type,
                                        o_flg_status          => l_flg_status,
                                        o_dpb                 => l_dpb,
                                        o_dpa                 => l_dpa,
                                        o_dt_surgery          => l_dt_surgery,
                                        o_min_inform_time     => l_min_inform_time,
                                        o_id_urgency_lev      => l_id_urg_level,
                                        o_id_external_request => l_id_external_request,
                                        o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- obter dados do episodio (dcs, id_schedule e id_episode)
        g_error := l_func_name || ' - PK_SCHEDULE_ORIS.GET_EPIS_STUFF';
        IF NOT pk_schedule_oris.get_epis_stuff(i_lang     => i_lang,
                                               i_prof     => i_prof,
                                               i_id_wl    => i_id_wl,
                                               o_dcs_list => l_dcs_list,
                                               o_id_sch   => l_id_schedule,
                                               o_id_epis  => l_id_episode,
                                               o_error    => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- a lista de dcs que vem de fora ainda tem prioridade
        IF i_dcs_list IS NOT NULL
           AND i_dcs_list.exists(1)
           AND TRIM(i_dcs_list(1)) IS NOT NULL
        THEN
            l_dcs_list := i_dcs_list;
        END IF;
    
        -- obter person a partir do id_patient para passar ao create_schedule_internal
        g_error   := l_func_name || ' - GET_PERSON_DATA';
        l_patient := get_person_data(i_persons, l_id_patient);
    
        -- validar se encontrou
        IF l_patient.id_patient IS NULL
        THEN
            RAISE l_func_exception;
        END IF;
    
        l_patients := t_persons(l_patient);
    
        IF l_id_schedule IS NULL
        THEN
        
            --criar canalizaçao basica
            g_error       := l_func_name || ' - CREATE_SCHEDULE_INTERNAL';
            o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_id_sch_ext           => i_id_sch_ext,
                                                      i_id_instit_requests   => i_id_instit_requests,
                                                      i_id_instit_requested  => i_id_instit_requested,
                                                      i_id_dcs_requests      => i_id_dcs_requests,
                                                      i_id_dcs_requested     => i_dcs_list(1),
                                                      i_id_prof_requests     => i_id_prof_requests,
                                                      i_id_prof_schedules    => i_id_prof_schedules,
                                                      i_flg_status           => i_flg_status,
                                                      i_id_sch_event         => i_id_sch_event,
                                                      i_schedule_notes       => i_schedule_notes,
                                                      i_id_lang_preferred    => i_id_lang_preferred,
                                                      i_id_reason            => i_id_reason,
                                                      i_id_origin            => i_id_origin,
                                                      i_id_room              => i_id_room,
                                                      i_flg_notification     => i_flg_notification,
                                                      i_id_schedule_ref      => i_id_schedule_ref,
                                                      i_flg_vacancy          => i_flg_vacancy,
                                                      i_flg_sch_type         => i_flg_sch_type,
                                                      i_reason_notes         => i_reason_notes,
                                                      i_dt_begin             => i_dt_begin,
                                                      i_dt_end               => i_dt_end,
                                                      i_dt_request           => i_dt_request,
                                                      i_flg_schedule_via     => i_flg_schedule_via,
                                                      i_id_prof_notif        => i_id_prof_notif,
                                                      i_dt_notification      => i_dt_notification,
                                                      i_flg_notification_via => i_flg_notification_via,
                                                      i_flg_request_type     => i_flg_request_type,
                                                      i_id_episode           => l_id_episode,
                                                      i_id_multidisc         => NULL,
                                                      i_patients             => l_patients,
                                                      i_ids_profs            => i_id_profs_list,
                                                      i_id_prof_leader       => i_prof_leader.id_resource,
                                                      i_id_group             => NULL,
                                                      i_id_sch_procedure     => i_id_schedule_procedure,
                                                      i_flg_reason_type      => i_flg_reason_type,
                                                      o_error                => o_error);
        
            IF i_id_schedule_ref IS NOT NULL
            THEN
                g_error := l_func_name || ' - GET ID_SCHEDULE_SR';
                BEGIN
                    SELECT id_schedule_sr
                      INTO l_id_sch_sr
                      FROM schedule_sr
                     WHERE id_schedule = i_id_schedule_ref
                       AND rownum = 1;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            IF l_id_sch_sr IS NULL
            THEN
                g_error       := l_func_name || ' - TS_SCHEDULE_SR.INS';
                o_id_schedule := ts_schedule_sr.ins(id_sched_sr_parent_in     => NULL,
                                                    id_schedule_in            => o_id_schedule,
                                                    id_episode_in             => l_id_episode,
                                                    id_patient_in             => l_id_patient,
                                                    duration_in               => NULL,
                                                    id_diagnosis_in           => NULL,
                                                    id_speciality_in          => NULL,
                                                    flg_status_in             => pk_alert_constant.g_active,
                                                    flg_sched_in              => pk_schedule_oris.g_scheduled,
                                                    id_dept_dest_in           => NULL,
                                                    prev_recovery_time_in     => NULL,
                                                    id_sr_cancel_reason_in    => NULL,
                                                    id_prof_cancel_in         => NULL,
                                                    notes_cancel_in           => NULL,
                                                    id_prof_reg_in            => NULL,
                                                    id_institution_in         => i_id_inst,
                                                    adw_last_update_in        => NULL,
                                                    dt_target_tstz_in         => i_dt_begin,
                                                    dt_interv_preview_tstz_in => i_dt_begin,
                                                    dt_cancel_tstz_in         => NULL,
                                                    id_waiting_list_in        => i_id_wl,
                                                    flg_temporary_in          => get_sch_flg_tempor(i_flg_status),
                                                    icu_in                    => NULL,
                                                    notes_in                  => NULL,
                                                    create_user_in            => NULL,
                                                    create_time_in            => NULL,
                                                    create_institution_in     => NULL,
                                                    update_user_in            => NULL,
                                                    update_time_in            => NULL,
                                                    update_institution_in     => NULL,
                                                    adm_needed_in             => NULL,
                                                    handle_error_in           => FALSE,
                                                    rows_out                  => l_rowids);
            
                t_data_gov_mnt.process_insert(i_lang, NULL, 'SCHEDULE_SR', l_rowids, o_error);
            
            ELSE
                g_error  := l_func_name || ' - TS_SCHEDULE_SR.UPD';
                l_rowids := table_varchar();
                ts_schedule_sr.upd(id_schedule_sr_in          => l_id_sch_sr,
                                   id_sched_sr_parent_in      => NULL,
                                   id_sched_sr_parent_nin     => TRUE,
                                   id_schedule_in             => o_id_schedule,
                                   id_schedule_nin            => TRUE,
                                   id_episode_in              => NULL,
                                   id_episode_nin             => TRUE,
                                   id_patient_in              => NULL,
                                   id_patient_nin             => TRUE,
                                   duration_in                => round(trunc(pk_date_utils.get_timestamp_diff(i_dt_end,
                                                                                                              i_dt_begin),
                                                                             pk_schedule.g_max_decimal_prec) * 1440,
                                                                       0),
                                   duration_nin               => TRUE,
                                   id_diagnosis_in            => NULL,
                                   id_diagnosis_nin           => TRUE,
                                   id_speciality_in           => NULL,
                                   id_speciality_nin          => TRUE,
                                   flg_status_in              => pk_schedule.g_status_scheduled,
                                   flg_status_nin             => TRUE,
                                   flg_sched_in               => NULL,
                                   flg_sched_nin              => TRUE,
                                   id_dept_dest_in            => NULL,
                                   id_dept_dest_nin           => TRUE,
                                   prev_recovery_time_in      => NULL,
                                   prev_recovery_time_nin     => TRUE,
                                   id_sr_cancel_reason_in     => NULL,
                                   id_sr_cancel_reason_nin    => TRUE,
                                   id_prof_cancel_in          => NULL,
                                   id_prof_cancel_nin         => TRUE,
                                   notes_cancel_in            => NULL,
                                   notes_cancel_nin           => TRUE,
                                   id_prof_reg_in             => NULL,
                                   id_prof_reg_nin            => TRUE,
                                   id_institution_in          => NULL,
                                   id_institution_nin         => TRUE,
                                   adw_last_update_in         => NULL,
                                   adw_last_update_nin        => TRUE,
                                   dt_target_tstz_in          => i_dt_begin,
                                   dt_target_tstz_nin         => TRUE,
                                   dt_interv_preview_tstz_in  => i_dt_begin,
                                   dt_interv_preview_tstz_nin => TRUE,
                                   dt_cancel_tstz_in          => NULL,
                                   dt_cancel_tstz_nin         => TRUE,
                                   id_waiting_list_in         => i_id_wl,
                                   id_waiting_list_nin        => TRUE,
                                   flg_temporary_in           => get_sch_flg_tempor(i_flg_status),
                                   flg_temporary_nin          => TRUE,
                                   icu_in                     => NULL,
                                   icu_nin                    => TRUE,
                                   notes_in                   => NULL,
                                   notes_nin                  => TRUE,
                                   create_user_in             => NULL,
                                   create_user_nin            => TRUE,
                                   create_time_in             => NULL,
                                   create_time_nin            => TRUE,
                                   create_institution_in      => NULL,
                                   create_institution_nin     => TRUE,
                                   update_user_in             => NULL,
                                   update_user_nin            => TRUE,
                                   update_time_in             => NULL,
                                   update_time_nin            => TRUE,
                                   update_institution_in      => NULL,
                                   update_institution_nin     => TRUE,
                                   adm_needed_in              => NULL,
                                   adm_needed_nin             => TRUE,
                                   handle_error_in            => FALSE,
                                   rows_out                   => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => NULL,
                                              i_table_name => 'SCHEDULE_SR',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        ELSE
            -- repor o flg_notification como estava inhantes
            g_error := l_func_name || ' - PK_SCHEDULE_COMMON.GET_NOTIFICATION_DEFAULT';
            IF NOT pk_schedule_common.get_notification_default(i_lang             => i_lang,
                                                               i_id_dep_clin_serv => l_dcs_list(1),
                                                               o_default_value    => l_notification_default,
                                                               o_error            => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            --actualizar a schedule
            g_error := l_func_name || ' - TS_SCHEDULE.UPD';
            ts_schedule.upd(id_schedule_in             => l_id_schedule,
                            id_instit_requests_in      => NULL,
                            id_instit_requests_nin     => TRUE,
                            id_instit_requested_in     => NULL,
                            id_instit_requested_nin    => TRUE,
                            id_dcs_requests_in         => NULL,
                            id_dcs_requests_nin        => TRUE,
                            id_dcs_requested_in        => NULL,
                            id_dcs_requested_nin       => TRUE,
                            id_prof_requests_in        => NULL,
                            id_prof_requests_nin       => TRUE,
                            id_prof_schedules_in       => i_prof.id,
                            id_prof_schedules_nin      => TRUE,
                            flg_status_in              => pk_schedule.g_status_scheduled,
                            flg_status_nin             => TRUE,
                            id_prof_cancel_in          => NULL,
                            id_prof_cancel_nin         => FALSE,
                            schedule_notes_in          => NULL,
                            schedule_notes_nin         => TRUE,
                            id_cancel_reason_in        => NULL,
                            id_cancel_reason_nin       => FALSE,
                            id_lang_translator_in      => NULL,
                            id_lang_translator_nin     => TRUE,
                            id_lang_preferred_in       => NULL,
                            id_lang_preferred_nin      => TRUE,
                            id_sch_event_in            => l_id_sch_event,
                            id_sch_event_nin           => TRUE,
                            id_reason_in               => NULL,
                            id_reason_nin              => TRUE,
                            id_origin_in               => NULL,
                            id_origin_nin              => TRUE,
                            id_room_in                 => i_id_room,
                            id_room_nin                => TRUE,
                            flg_urgency_in             => NULL,
                            flg_urgency_nin            => TRUE,
                            schedule_cancel_notes_in   => NULL,
                            schedule_cancel_notes_nin  => FALSE,
                            flg_notification_in        => l_notification_default,
                            flg_notification_nin       => TRUE,
                            id_schedule_ref_in         => i_id_schedule_ref,
                            id_schedule_ref_nin        => TRUE,
                            flg_vacancy_in             => nvl(i_flg_vacancy, pk_schedule_common.g_sched_vacancy_routine),
                            flg_vacancy_nin            => TRUE,
                            flg_sch_type_in            => i_flg_sch_type,
                            flg_sch_type_nin           => TRUE,
                            reason_notes_in            => NULL,
                            reason_notes_nin           => TRUE,
                            dt_begin_tstz_in           => i_dt_begin,
                            dt_begin_tstz_nin          => TRUE,
                            dt_cancel_tstz_in          => NULL,
                            dt_cancel_tstz_nin         => FALSE,
                            dt_end_tstz_in             => i_dt_end,
                            dt_end_tstz_nin            => TRUE,
                            dt_request_tstz_in         => NULL,
                            dt_request_tstz_nin        => TRUE,
                            dt_schedule_tstz_in        => NULL,
                            dt_schedule_tstz_nin       => TRUE,
                            flg_instructions_in        => NULL,
                            flg_instructions_nin       => TRUE,
                            flg_schedule_via_in        => NULL,
                            flg_schedule_via_nin       => TRUE,
                            id_prof_notification_in    => NULL,
                            id_prof_notification_nin   => TRUE,
                            dt_notification_tstz_in    => NULL,
                            dt_notification_tstz_nin   => TRUE,
                            flg_notification_via_in    => NULL,
                            flg_notification_via_nin   => TRUE,
                            id_sch_consult_vacancy_in  => NULL,
                            id_sch_consult_vacancy_nin => TRUE,
                            flg_request_type_in        => NULL,
                            flg_request_type_nin       => TRUE,
                            id_episode_in              => l_id_episode,
                            id_episode_nin             => TRUE,
                            id_schedule_recursion_in   => NULL,
                            id_schedule_recursion_nin  => TRUE,
                            create_user_in             => NULL,
                            create_user_nin            => TRUE,
                            create_time_in             => NULL,
                            create_time_nin            => TRUE,
                            create_institution_in      => NULL,
                            create_institution_nin     => TRUE,
                            update_user_in             => NULL,
                            update_user_nin            => TRUE,
                            update_time_in             => NULL,
                            update_time_nin            => TRUE,
                            update_institution_in      => NULL,
                            update_institution_nin     => TRUE,
                            flg_present_in             => NULL,
                            flg_present_nin            => TRUE,
                            id_multidisc_in            => NULL,
                            id_multidisc_nin           => TRUE,
                            id_sch_combi_detail_in     => NULL,
                            id_sch_combi_detail_nin    => TRUE,
                            flg_reason_type_in         => NULL,
                            flg_reason_type_nin        => TRUE,
                            handle_error_in            => FALSE);
        
            -- pegar o id_schedule_sr
            g_error := l_func_name || ' - GET ID_SCHEDULE_SR';
            SELECT id_schedule_sr
              INTO l_id_sch_sr
              FROM schedule_sr
             WHERE id_schedule = l_id_schedule;
        
            -- actualizar a schedule_sr
            l_rowids := table_varchar();
            g_error  := l_func_name || ' - TS_SCHEDULE_SR.UPD';
            ts_schedule_sr.upd(id_schedule_sr_in          => l_id_sch_sr,
                               id_sched_sr_parent_in      => NULL,
                               id_sched_sr_parent_nin     => TRUE,
                               id_schedule_in             => NULL,
                               id_schedule_nin            => TRUE,
                               id_episode_in              => NULL,
                               id_episode_nin             => TRUE,
                               id_patient_in              => NULL,
                               id_patient_nin             => TRUE,
                               duration_in                => round(trunc(pk_date_utils.get_timestamp_diff(i_dt_end,
                                                                                                          i_dt_begin),
                                                                         pk_schedule.g_max_decimal_prec) * 1440,
                                                                   0),
                               duration_nin               => TRUE,
                               id_diagnosis_in            => NULL,
                               id_diagnosis_nin           => TRUE,
                               id_speciality_in           => NULL,
                               id_speciality_nin          => TRUE,
                               flg_status_in              => pk_schedule.g_status_scheduled,
                               flg_status_nin             => TRUE,
                               flg_sched_in               => pk_schedule.g_status_scheduled,
                               flg_sched_nin              => TRUE,
                               id_dept_dest_in            => NULL,
                               id_dept_dest_nin           => TRUE,
                               prev_recovery_time_in      => NULL,
                               prev_recovery_time_nin     => TRUE,
                               id_sr_cancel_reason_in     => NULL,
                               id_sr_cancel_reason_nin    => TRUE,
                               id_prof_cancel_in          => NULL,
                               id_prof_cancel_nin         => TRUE,
                               notes_cancel_in            => NULL,
                               notes_cancel_nin           => TRUE,
                               id_prof_reg_in             => NULL,
                               id_prof_reg_nin            => TRUE,
                               id_institution_in          => NULL,
                               id_institution_nin         => TRUE,
                               adw_last_update_in         => NULL,
                               adw_last_update_nin        => TRUE,
                               dt_target_tstz_in          => i_dt_begin,
                               dt_target_tstz_nin         => TRUE,
                               dt_interv_preview_tstz_in  => i_dt_begin,
                               dt_interv_preview_tstz_nin => TRUE,
                               dt_cancel_tstz_in          => NULL,
                               dt_cancel_tstz_nin         => TRUE,
                               id_waiting_list_in         => i_id_wl,
                               id_waiting_list_nin        => TRUE,
                               flg_temporary_in           => get_sch_flg_tempor(i_flg_status),
                               flg_temporary_nin          => TRUE,
                               icu_in                     => NULL,
                               icu_nin                    => TRUE,
                               notes_in                   => i_notes,
                               notes_nin                  => TRUE,
                               create_user_in             => NULL,
                               create_user_nin            => TRUE,
                               create_time_in             => NULL,
                               create_time_nin            => TRUE,
                               create_institution_in      => NULL,
                               create_institution_nin     => TRUE,
                               update_user_in             => NULL,
                               update_user_nin            => TRUE,
                               update_time_in             => NULL,
                               update_time_nin            => TRUE,
                               update_institution_in      => NULL,
                               update_institution_nin     => TRUE,
                               adm_needed_in              => NULL,
                               adm_needed_nin             => TRUE,
                               handle_error_in            => FALSE,
                               rows_out                   => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => NULL,
                                          i_table_name => 'SCHEDULE_SR',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            -- inserir na sch_group
            g_error := l_func_name || ' - MERGE INTO SCH_GROUP';
            MERGE INTO sch_group g
            USING (SELECT l_id_schedule                  id_schedule,
                          l_id_patient                   i_id_pat,
                          l_patient.flg_ref_type         frt,
                          l_patient.id_prof_referrer_ext pref,
                          l_patient.id_inst_referrer_ext iref
                     FROM dual) d
            ON (g.id_schedule = d.id_schedule AND g.id_patient = d.i_id_pat)
            WHEN NOT MATCHED THEN
                INSERT
                    (id_group, id_schedule, id_patient, flg_ref_type, id_prof_ref, id_inst_ref)
                VALUES
                    (seq_sch_group.nextval, d.id_schedule, d.i_id_pat, d.frt, d.pref, d.iref);
        
            -- inserir na sch_resource
            g_error := l_func_name || ' - MERGE INTO SCH_RESOURCE';
        
            IF i_id_profs_list IS NOT NULL
               AND i_id_profs_list.count > 0
            THEN
            
                MERGE INTO sch_resource r
                USING (SELECT l_id_schedule id_schedule, i_id_inst id_ins, column_value id_prof
                         FROM TABLE(i_id_profs_list)
                        WHERE column_value IS NOT NULL) d
                ON (r.id_schedule = d.id_schedule AND r.id_professional = d.id_prof)
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sch_resource, id_schedule, id_institution, id_professional, dt_sch_resource_tstz)
                    VALUES
                        (seq_sch_resource.nextval, d.id_schedule, d.id_ins, d.id_prof, current_timestamp);
            
            END IF;
        
            -- mapear ids na sch_api_map_ids. needs protection againt inserting existing pairs id_schedule_pfh|id_schedule_ext.
            -- this can happen when updating a oris schedule. For example, changing the scheduled room.
            IF i_id_sch_ext IS NOT NULL -- pk_schedule_api_upstream.is_scheduler_installed(i_prof) = pk_alert_constant.g_yes
            THEN
                BEGIN
                    g_error := l_func_name || ' - CALL TS_SCH_MAP_API_IDS.ins';
                    ts_sch_api_map_ids.ins(id_schedule_pfh_in       => l_id_schedule,
                                           id_schedule_ext_in       => i_id_sch_ext,
                                           create_user_in           => NULL,
                                           create_time_in           => NULL,
                                           create_institution_in    => NULL,
                                           update_user_in           => NULL,
                                           update_time_in           => NULL,
                                           update_institution_in    => NULL,
                                           handle_error_in          => FALSE,
                                           id_schedule_procedure_in => i_id_schedule_procedure);
                EXCEPTION
                    WHEN dup_val_on_index THEN
                        NULL;
                END;
            END IF;
        
        END IF;
    
        -- add room in room_scheduled
        g_error := l_func_name || ' - CALL PK_SCHEDULE_ORIS.UPD_ROOM_SCHEDULED';
        IF NOT pk_schedule_oris.upd_room_scheduled(i_lang        => i_lang,
                                                   i_id_schedule => nvl(l_id_schedule, o_id_schedule),
                                                   i_id_room     => i_id_room,
                                                   i_prof        => i_prof,
                                                   o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- update WL
        g_error := l_func_name || ' - CALL PK_WTL_PBL_CORE.SET_SCHEDULE';
        pk_alertlog.log_warn(text        => 'PK_WTL_PBL_CORE.SET_SCHEDULE INPUT: i_id_wtlist=' || i_id_wl ||
                                            ', i_id_episode=' || l_id_episode || ', l_id_schedule=' || l_id_schedule ||
                                            ', o_id_schedule=' || o_id_schedule,
                             object_name => g_package_name,
                             owner       => g_package_owner);
    
        IF NOT pk_wtl_pbl_core.set_schedule(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_wtlist   => i_id_wl,
                                            i_id_episode  => l_id_episode,
                                            i_id_schedule => nvl(l_id_schedule, o_id_schedule),
                                            o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- update epis_info
        l_rowids := table_varchar();
        g_error  := 'UPDATE EPIS_INFO';
        ts_epis_info.upd(id_episode_in   => i_id_episode,
                         id_schedule_in  => nvl(l_id_schedule, o_id_schedule),
                         id_schedule_nin => FALSE,
                         rows_out        => l_rowids);
    
        g_error := 'CALL T_DATA_GOV_MNT.PROCESS_UPDATE EPIS_INFO';
        --Process the events associated to an update on epis_info                         
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPIS_INFO',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        -- update referral status
        IF (l_id_external_request IS NOT NULL)
        THEN
            g_error := l_func_name || ' - CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE with id_external_request=' ||
                       l_id_external_request || ', i_episode=' || l_id_episode;
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, owner => g_package_owner);
            IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                   i_prof     => i_prof,
                                                   i_id_ref   => l_id_external_request,
                                                   i_schedule => nvl(l_id_schedule, o_id_schedule),
                                                   i_notes    => i_schedule_notes,
                                                   i_episode  => l_id_episode,
                                                   i_date     => coalesce(i_dt_referral, current_timestamp),
                                                   o_error    => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        -- assegurar que devolve 
        o_id_schedule := nvl(o_id_schedule, l_id_schedule);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule_oris;

    /*
    *
    */
    FUNCTION create_schedule_mfr
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_schedule       IN rehab_schedule.id_schedule%TYPE,
        i_id_prof           IN rehab_schedule.id_professional%TYPE,
        i_id_rehab_sch_need IN rehab_schedule.id_rehab_sch_need%TYPE,
        i_dt_schedule       IN rehab_schedule.dt_schedule%TYPE,
        i_id_rehab_group    IN sch_rehab_group.id_rehab_group%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := $$PLSQL_UNIT;
        rec         rehab_schedule%ROWTYPE;
        rec2        sch_rehab_group%ROWTYPE;
        i           PLS_INTEGER;
    BEGIN
        -- caso: PROF
        IF i_id_prof IS NOT NULL
        THEN
            rec.id_rehab_sch_need := i_id_rehab_sch_need;
            rec.id_professional   := i_id_prof;
            rec.id_schedule       := i_id_schedule;
            rec.dt_schedule       := i_dt_schedule;
            rec.flg_status        := pk_rehab.g_rehab_schedule_scheduled;
        
            g_error := l_func_name || ' - CALL TS_REHAB_SCHEDULE.INS';
            ts_rehab_schedule.ins(rec_in => rec, gen_pky_in => TRUE, sequence_in => NULL, handle_error_in => FALSE);
        
            g_error := l_func_name || ' - CALL PK_REHAB.SET_ALLOC_PROF_SCH_NEED WITH i_id_rehab_sch_need=' ||
                       i_id_rehab_sch_need || ', i_id_resp=' || i_id_rehab_group || ', i_type=' ||
                       pk_rehab.g_list_type_prof_abbr;
            IF NOT pk_rehab.set_alloc_prof_sch_need(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_rehab_sch_need => i_id_rehab_sch_need,
                                                    i_id_resp           => i_id_prof,
                                                    i_type              => pk_rehab.g_list_type_prof_abbr,
                                                    o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
            -- CASO: GRUPO
        ELSIF i_id_rehab_group IS NOT NULL
        THEN
        
            --Insert the record in rehab_schedule with id_professional = NULL in order for the patient to be shown on the grids.
            rec.id_rehab_sch_need := i_id_rehab_sch_need;
            rec.id_professional   := NULL;
            rec.id_schedule       := i_id_schedule;
            rec.dt_schedule       := i_dt_schedule;
            rec.flg_status        := pk_rehab.g_rehab_schedule_scheduled;
        
            g_error := l_func_name || ' - CALL TS_REHAB_SCHEDULE.INS';
            ts_rehab_schedule.ins(rec_in => rec, gen_pky_in => TRUE, sequence_in => NULL, handle_error_in => FALSE);
            -------   
        
            g_error                := l_func_name || ' - CALL TS_SCH_REHAB_GROUP.INS WITH i_id_schedule=' ||
                                      i_id_schedule || ', i_id_rehab_group= ' || i_id_rehab_group;
            rec2.id_schedule       := i_id_schedule;
            rec2.id_rehab_group    := i_id_rehab_group;
            rec2.id_rehab_sch_need := i_id_rehab_sch_need;
            rec2.flg_status        := pk_rehab.g_rehab_schedule_scheduled;
            ts_sch_rehab_group.ins(rec_in => rec2, sequence_in => NULL, handle_error_in => FALSE);
        
            g_error := l_func_name || ' - CALL PK_REHAB.SET_ALLOC_PROF_SCH_NEED WITH i_id_rehab_sch_need=' ||
                       i_id_rehab_sch_need || ', i_id_resp=' || i_id_rehab_group || ', i_type=' ||
                       pk_rehab.g_list_type_group_abbr;
            IF NOT pk_rehab.set_alloc_prof_sch_need(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_rehab_sch_need => i_id_rehab_sch_need,
                                                    i_id_resp           => i_id_rehab_group,
                                                    i_type              => pk_rehab.g_list_type_group_abbr,
                                                    o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        ELSE
            rec.id_rehab_sch_need := i_id_rehab_sch_need;
            rec.id_schedule       := i_id_schedule;
            rec.dt_schedule       := i_dt_schedule;
            rec.flg_status        := pk_rehab.g_rehab_schedule_scheduled;
        
            g_error := l_func_name || ' - CALL TS_REHAB_SCHEDULE.INS';
            ts_rehab_schedule.ins(rec_in => rec, gen_pky_in => TRUE, sequence_in => NULL, handle_error_in => FALSE);
        
            g_error := l_func_name || ' - CALL PK_REHAB.SET_ALLOC_PROF_SCH_NEED WITH i_id_rehab_sch_need=' ||
                       i_id_rehab_sch_need || ', i_id_resp=' || i_id_rehab_group || ', i_type=' ||
                       pk_rehab.g_list_type_prof_abbr;
            IF NOT pk_rehab.set_alloc_prof_sch_need(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_id_rehab_sch_need => i_id_rehab_sch_need,
                                                    i_id_resp           => i_id_prof,
                                                    i_type              => pk_rehab.g_list_type_prof_abbr,
                                                    o_error             => o_error)
            THEN
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN TRUE;
    END create_schedule_mfr;

    /*
    *
    */
    FUNCTION create_schedule_lab
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule_analysis.id_schedule%TYPE,
        i_procedure_reqs   IN t_procedure_reqs,
        i_id_sch_procedure IN NUMBER,
        i_id_patient       IN NUMBER,
        i_dt_begin         IN analysis_req_det.dt_target_tstz%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                   VARCHAR2(32) := $$PLSQL_UNIT;
        k                             PLS_INTEGER;
        l_id_pat_ar                   analysis_req.id_patient%TYPE;
        l_rowids                      table_varchar;
        l_ids_req_det                 table_number;
        l_exception                   EXCEPTION;
        l_ret_val                     BOOLEAN;
        l_dummy                       VARCHAR2(4000);
        l_err_instance_id_out         NUMBER(24);
        l_count                       PLS_INTEGER;
        l_tbl_analysis_req            table_number;
        l_tbl_analysis_req_det        table_number;
        l_tbl_analysis_req_det_output table_number;
        l_id_episode                  episode.id_episode%TYPE;
        l_dt_begin                    VARCHAR2(30) := pk_date_utils.date_send_tsz(i_lang, i_dt_begin, i_prof);
    BEGIN
        IF nvl(cardinality(i_procedure_reqs), 0) > 0
        THEN
            k := i_procedure_reqs.first;
            WHILE k IS NOT NULL
            LOOP
                IF i_procedure_reqs(k).id_schedule_procedure = i_id_sch_procedure
                THEN
                    g_error := l_func_name || ' - GET ANALYSIS_REQ.ID_PATIENT';
                    BEGIN
                        SELECT id_patient
                          INTO l_id_pat_ar
                          FROM analysis_req h
                         WHERE h.id_analysis_req = i_procedure_reqs(k).id
                           AND h.id_patient = i_id_patient;
                    EXCEPTION
                        WHEN no_data_found THEN
                            RAISE l_exception;
                    END;
                
                    l_tbl_analysis_req_det := table_number();
                    SELECT ard.id_analysis_req_det
                      BULK COLLECT
                      INTO l_tbl_analysis_req_det
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = i_procedure_reqs(k).id
                       AND ard.flg_status NOT IN (pk_alert_constant.g_cancelled);
                
                    l_count := 0;
                    SELECT COUNT(1)
                      INTO l_count
                      FROM schedule_analysis sa
                      JOIN schedule s
                        ON s.id_schedule = sa.id_schedule
                     WHERE sa.id_analysis_req = i_procedure_reqs(k).id
                       AND s.flg_status NOT IN (pk_alert_constant.g_cancelled);
                
                    --Se a requisição já tem um agendamento, é necessário criar uma nova requisição.
                    --Isto acontece nas requisições com recorrência, o 1º agendamento fica com a req original,
                    --os subsequentes têm que ter uma requisição nova 
                    IF l_count > 0
                    THEN
                        l_tbl_analysis_req            := table_number();
                        l_tbl_analysis_req_det_output := table_number();
                    
                        SELECT nvl(ar.id_episode, ar.id_episode_origin)
                          INTO l_id_episode
                          FROM analysis_req ar
                         WHERE ar.id_analysis_req = i_procedure_reqs(k).id;
                    
                        g_error := l_func_name || ' - CREATE LAB TEST REQUEST';
                        IF NOT pk_schedule_api_downstream.create_lab_test_req(i_lang                    => i_lang,
                                                                              i_prof                    => i_prof,
                                                                              i_analysis_req_origin     => i_procedure_reqs(k).id,
                                                                              i_analysis_req_det_origin => l_tbl_analysis_req_det,
                                                                              i_dt_begin                => l_dt_begin,
                                                                              i_id_patient              => i_id_patient,
                                                                              i_id_episode              => l_id_episode,
                                                                              o_ids_lab_test_req        => l_tbl_analysis_req,
                                                                              o_ids_lab_test_req_det    => l_tbl_analysis_req_det_output,
                                                                              o_error                   => o_error)
                        THEN
                            pk_alertlog.log_error(g_error);
                            RETURN FALSE;
                        END IF;
                    
                        IF l_tbl_analysis_req.exists(1)
                        THEN
                            g_error := l_func_name || ' - INSERT INTO SCHEDULE_ANALYSIS';
                            ts_schedule_analysis.ins(id_schedule_in     => i_id_schedule,
                                                     id_analysis_req_in => l_tbl_analysis_req(1),
                                                     handle_error_in    => FALSE,
                                                     rows_out           => l_rowids);
                        
                            -- settar estado da requisicao
                            g_error := l_func_name || ' - call pk_lab_tests_api_db.set_lab_test_status';
                            IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                                           i_prof             => i_prof,
                                                                           i_analysis_req_det => l_tbl_analysis_req_det_output,
                                                                           i_status           => pk_lab_tests_constant.g_analysis_sched,
                                                                           o_error            => o_error)
                            THEN
                                pk_alertlog.log_error(g_error);
                                pk_utils.undo_changes;
                                RETURN FALSE;
                            END IF;
                        
                            -- settar data de execuçao 
                            g_error := l_func_name || ' - call pk_lab_tests_api_db.set_lab_test_date';
                            IF NOT pk_lab_tests_api_db.set_lab_test_date(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_analysis_req_det => l_tbl_analysis_req_det_output,
                                                                         i_dt_begin         => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                           i_dt_begin,
                                                                                                                           i_prof),
                                                                         i_notes_scheduler  => NULL,
                                                                         o_error            => o_error)
                            THEN
                                pk_alertlog.log_error(g_error);
                                pk_utils.undo_changes;
                                RETURN FALSE;
                            END IF;
                        ELSE
                            pk_alertlog.log_error('L_TBL_ANALYSIS_REQ IS NOT VALID');
                            pk_utils.undo_changes;
                            RETURN FALSE;
                        END IF;
                    ELSE
                        g_error := l_func_name || ' - INSERT INTO SCHEDULE_ANALYSIS';
                        ts_schedule_analysis.ins(id_schedule_in     => i_id_schedule,
                                                 id_analysis_req_in => i_procedure_reqs(k).id,
                                                 handle_error_in    => FALSE,
                                                 rows_out           => l_rowids);
                    
                        -- obter todas as req dets desta req
                        g_error := l_func_name || ' - GET COLLECTION OF id_analysis_req_det FOR id_analysis_req=' || i_procedure_reqs(k).id;
                        SELECT id_analysis_req_det
                          BULK COLLECT
                          INTO l_ids_req_det
                          FROM analysis_req_det r
                         WHERE r.id_analysis_req = i_procedure_reqs(k).id
                           AND r.flg_status = pk_lab_tests_constant.g_analysis_tosched;
                    
                        -- settar estado da requisicao
                        g_error := l_func_name || ' - call pk_lab_tests_api_db.set_lab_test_status';
                        IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                                       i_prof             => i_prof,
                                                                       i_analysis_req_det => l_ids_req_det,
                                                                       i_status           => pk_lab_tests_constant.g_analysis_sched,
                                                                       o_error            => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    
                        -- settar data de execuçao 
                        g_error := l_func_name || ' - call pk_lab_tests_api_db.set_lab_test_date';
                        IF NOT pk_lab_tests_api_db.set_lab_test_date(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_analysis_req_det => l_ids_req_det,
                                                                     i_dt_begin         => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                       i_dt_begin,
                                                                                                                       i_prof),
                                                                     i_notes_scheduler  => NULL,
                                                                     o_error            => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                    END IF;
                END IF;
            
                k := i_procedure_reqs.next(k);
            END LOOP;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            l_ret_val := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                            i_func_proc_name => l_func_name,
                                                            i_package_name   => g_package_name,
                                                            i_package_error  => 6690,
                                                            i_sql_error      => pk_message.get_message(i_lang,
                                                                                                       g_sched_msg_harv_patient),
                                                            i_log_on         => TRUE,
                                                            o_error          => l_dummy);
        
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 6690,
                                   ora_sqlerrm         => pk_message.get_message(i_lang, g_sched_msg_harv_patient),
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule_lab;

    /*
    *
    */
    FUNCTION create_schedule
    (
        i_lang                IN language.id_language%TYPE, -- i_lang
        i_prof                IN profissional, -- i_prof
        i_id_sch_ext          IN NUMBER, -- SCHEDULE.ID_SCHEDULE
        i_flg_status          IN schedule.flg_status%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE, -- SERVICE.ID_FACILITY
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE, -- ? SCHEDULE_FLG_VACANCY ?
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_sch_ref          IN schedule.id_schedule_ref%TYPE DEFAULT NULL,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_dt_referral         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_prof_resp           IN epis_multi_prof_resp.id_professional%TYPE DEFAULT NULL,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'CREATE_SCHEDULE';
        l_func_exception      EXCEPTION;
        l_exception           EXCEPTION;
        l_pivot               PLS_INTEGER;
        l_retval              BOOLEAN;
        l_wl_type             waiting_list.flg_type%TYPE;
        i                     PLS_INTEGER;
        l_dt_begin            TIMESTAMP WITH TIME ZONE;
        l_dt_end              TIMESTAMP WITH TIME ZONE;
        l_dt_request          TIMESTAMP WITH TIME ZONE;
        l_dt_notification     TIMESTAMP WITH TIME ZONE;
        l_num_persons         NUMBER := count_persons(i_persons);
        l_num_profs_tab       pk_utils.hashtable_pls_integer;
        l_id_sch_event_tab    pk_utils.hashtable_pls_integer;
        l_id_dcs              dep_clin_serv.id_dep_clin_serv%TYPE;
        l_dummy               VARCHAR2(4000);
        l_err_instance_id_out NUMBER(24);
        --        l_ret_val             BOOLEAN;
        l_is_surg_sched    BOOLEAN := TRUE;
        l_is_inp_sched     BOOLEAN := TRUE;
        l_exists_surg_proc BOOLEAN := FALSE;
        l_proc_req         t_procedure_req;
        l_room             t_resource;
        l_epis_to_exec     episode.id_episode%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_exam_procs       table_number := table_number();
        l_oexam_procs      table_number := table_number();
        l_exists           BOOLEAN; -- dummy
        l_flg_av           VARCHAR2(1); --dummy
        l_desc_trans       translation.desc_lang_1%TYPE; --dummy    
        l_id_sch_proc_main NUMBER;
        l_id_episode_main  epis_info.id_episode%TYPE;
        l_transaction_id   VARCHAR2(4000);
        l_bool             BOOLEAN;
    
        -- time trial
        t1 NUMBER;
        t2 NUMBER;
    
        -- INNER FUNCTIONS AND PROCS
        PROCEDURE inner_upd_reqs
        (
            i_id_schedule schedule.id_schedule%TYPE,
            i_id_patient  sch_group.id_patient%TYPE
        ) IS
            u        PLS_INTEGER;
            l_rowids table_varchar := table_varchar();
        
            l_prof_dest         sch_prof_outp.id_professional%TYPE;
            l_id_schedule_cr    consult_req.id_schedule%TYPE;
            l_flg_status_cr     consult_req.flg_status%TYPE;
            l_flg_recurrence_cr consult_req.flg_recurrence%TYPE;
        BEGIN
            --valida
            IF i_procedure_reqs IS NULL
               OR i_procedure_reqs.count = 0
            THEN
                RETURN;
            END IF;
        
            -- todas as reqs deste procedure devem ser actualizadas
            u := i_procedure_reqs.first;
            WHILE u IS NOT NULL
            LOOP
                IF i_procedure_reqs(u).id_schedule_procedure = i_procedures(l_pivot).id_schedule_procedure
                    AND i_procedure_reqs(u).id IS NOT NULL
                    AND i_procedure_reqs(u).id_type = g_proc_req_type_req
                    AND i_procedure_reqs(u).id_patient = i_id_patient
                THEN
                
                    SELECT cr.id_episode_to_exec, cr.id_schedule, cr.flg_status, cr.flg_recurrence
                      INTO l_epis_to_exec, l_id_schedule_cr, l_flg_status_cr, l_flg_recurrence_cr
                      FROM consult_req cr
                     WHERE cr.id_consult_req = i_procedure_reqs(u).id;
                
                    IF l_id_schedule_cr IS NULL
                    --    AND (l_flg_recurrence_cr IS NULL OR l_flg_recurrence_cr <> 'N')
                    THEN
                        g_error := l_func_name || ' - INNER_UPD_REQS - TS_CONSULT_REQ.UPD';
                        ts_consult_req.upd(id_consult_req_in => i_procedure_reqs(u).id,
                                           flg_status_in     => 'S',
                                           id_schedule_in    => i_id_schedule,
                                           dt_last_update_in => current_timestamp,
                                           rows_out          => l_rowids);
                    
                        g_error := l_func_name || ' - INNER_UPD_REQS - T_DATA_GOV_MNT.PROCESS_UPDATE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'CONSULT_REQ',
                                                      i_rowids     => l_rowids,
                                                      o_error      => o_error);
                    
                        l_rowids := table_varchar();
                    
                        IF l_epis_to_exec IS NOT NULL
                        THEN
                            l_id_visit := pk_visit.get_visit(i_episode => l_epis_to_exec, o_error => o_error);
                        
                            --Update the order set scheduled episode with the active state
                            g_error := l_func_name || ' - INNER_UPD_REQS - UPDATE EPISODE';
                            ts_episode.upd(id_episode_in => l_epis_to_exec,
                                           flg_status_in => pk_visit.g_epis_active,
                                           rows_out      => l_rowids);
                        
                            g_error := l_func_name || ' - INNER_UPD_REQS - PROCESS_UPDATE 1';
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'EPISODE',
                                                          i_rowids     => l_rowids,
                                                          o_error      => o_error);
                        
                            l_rowids := table_varchar();
                            -- ALERT-294458 - update visit to active            
                            g_error  := 'UPDATE VISIT';
                            l_rowids := table_varchar();
                            ts_visit.upd(flg_status_in   => pk_visit.g_visit_active,
                                         flg_status_nin  => FALSE,
                                         dt_end_tstz_in  => NULL,
                                         dt_end_tstz_nin => FALSE,
                                         where_in        => 'id_visit = ' || l_id_visit || ' AND flg_status != ''' ||
                                                            pk_visit.g_visit_active || ''' ',
                                         rows_out        => l_rowids);
                        
                            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                          i_prof         => i_prof,
                                                          i_table_name   => 'VISIT',
                                                          i_rowids       => l_rowids,
                                                          o_error        => o_error,
                                                          i_list_columns => table_varchar('FLG_STATUS', 'DT_END_TSTZ'));
                        
                            l_rowids := table_varchar();
                        
                            --Update the epis_info with the already create order set temporary episode
                        
                            BEGIN
                                g_error := l_func_name || ' - INNER_UPD_REQS - GET PROFESSIONAL';
                                BEGIN
                                    SELECT spo.id_professional
                                      INTO l_prof_dest
                                      FROM schedule_outp so
                                      JOIN sch_prof_outp spo
                                        ON spo.id_schedule_outp = so.id_schedule_outp
                                     WHERE so.id_schedule = i_id_schedule;
                                EXCEPTION
                                    WHEN no_data_found THEN
                                        l_prof_dest := NULL;
                                END;
                            
                                g_error := l_func_name || ' - INNER_UPD_REQS - UPDATE EPIS_INFO';
                                ts_epis_info.upd(id_schedule_in      => i_id_schedule,
                                                 id_professional_in  => l_prof_dest,
                                                 id_professional_nin => FALSE,
                                                 where_in            => ' id_episode = ' || l_epis_to_exec,
                                                 rows_out            => l_rowids);
                            
                                g_error := l_func_name || ' - INNER_UPD_REQS - PROCESS_UPDATE 2';
                                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                              i_prof       => i_prof,
                                                              i_table_name => 'EPIS_INFO',
                                                              i_rowids     => l_rowids,
                                                              o_error      => o_error);
                            EXCEPTION
                                WHEN no_data_found THEN
                                    RAISE l_exception;
                            END;
                        END IF;
                    END IF;
                END IF;
                u := i_procedure_reqs.next(u);
            END LOOP;
        
        END inner_upd_reqs;
    
        -- set patient trial
        PROCEDURE inner_set_trial
        (
            i_id_patient NUMBER,
            i_id_episode NUMBER,
            i_id_trial   NUMBER
        ) IS
        BEGIN
            g_error := l_func_name || ' - INNER_SET_TRIAL - CALL SET_SCHEDULE_TRIAL';
            IF NOT pk_trials.set_scheduled_trial(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_id_patient => i_id_patient,
                                                 i_id_episode => i_id_episode,
                                                 i_id_trial   => i_id_trial,
                                                 o_error      => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END inner_set_trial;
    
        FUNCTION inner_create_episode
        (
            i_id_schedule      IN schedule.id_schedule%TYPE,
            i_id_patient       IN epis_info.id_patient%TYPE,
            i_id_dep_clin_serv IN NUMBER DEFAULT NULL,
            i_flg_rehab        IN VARCHAR2 DEFAULT NULL,
            i_id_epis_origin   IN NUMBER DEFAULT NULL,
            i_id_rehab_presc   IN NUMBER DEFAULT NULL,
            o_id_episode       OUT epis_info.id_episode%TYPE,
            o_error            OUT t_error_out
        ) RETURN BOOLEAN IS
            l_id_software             schedule_outp.id_software%TYPE;
            l_id_access_context       ehr_access_context.id_ehr_access_context%TYPE;
            l_dummy_v                 VARCHAR2(4000 CHAR);
            l_id_rehab_epis_encounter rehab_epis_encounter.id_rehab_epis_encounter%TYPE;
            l_id_rehab_epis_enc_hist  rehab_epis_enc_hist.id_rehab_epis_enc_hist%TYPE;
            l_rows                    table_varchar;
        BEGIN
            g_error := l_func_name || ' - INNER_CREATE_EPISODE - GET SCHEDULE_OUTP.ID_SOFTWARE id_schedule = ' ||
                       i_id_schedule;
            IF i_flg_rehab IS NULL
            THEN
                SELECT so.id_software
                  INTO l_id_software
                  FROM schedule_outp so
                 WHERE so.id_schedule = i_id_schedule;
            ELSE
                l_id_software := pk_alert_constant.g_soft_rehab;
            END IF;
            g_error := l_func_name || ' - INNER_CREATE_EPISODE - GET id_ehr_access_context id_software = ' ||
                       l_id_software;
            SELECT *
              INTO l_id_access_context
              FROM (SELECT e.id_ehr_access_context
                      FROM ehr_access_context e
                      JOIN ehr_access_context_soft es
                        ON es.id_ehr_access_context = e.id_ehr_access_context
                     WHERE es.id_software IN (0, l_id_software)
                       AND e.flg_type = 'S'
                     ORDER BY es.id_software DESC)
             WHERE rownum <= 1;
        
            -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
            g_error          := l_func_name || ' - CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
        
            g_error := l_func_name || ' - CREATE_SCHEDULE_OUTP - PK_EHR_ACCESS.CREATE_EHR_ACCESS';
            IF NOT pk_ehr_access.create_ehr_access_no_commit(i_lang             => i_lang,
                                                             i_prof             => i_prof,
                                                             i_id_patient       => i_id_patient,
                                                             i_id_episode       => NULL,
                                                             i_id_schedule      => i_id_schedule,
                                                             i_access_area      => l_id_access_context,
                                                             i_access_type      => 'F',
                                                             i_id_access_reason => NULL,
                                                             i_access_text      => NULL,
                                                             i_new_ehr_event    => NULL,
                                                             i_id_dep_clin_serv => i_id_dep_clin_serv, --NULL,
                                                             i_transaction_id   => l_transaction_id,
                                                             o_episode          => o_id_episode,
                                                             o_flg_show         => l_dummy_v,
                                                             o_msg_title        => l_dummy_v,
                                                             o_msg              => l_dummy_v,
                                                             o_button           => l_dummy_v,
                                                             o_error            => o_error)
            THEN
                RETURN FALSE;
            END IF;
            IF i_flg_rehab = pk_alert_constant.g_yes
            THEN
            
                l_id_rehab_epis_encounter := ts_rehab_epis_encounter.next_key;
                ts_rehab_epis_encounter.ins(id_rehab_epis_encounter_in => l_id_rehab_epis_encounter,
                                            id_episode_origin_in       => i_id_epis_origin,
                                            id_episode_rehab_in        => o_id_episode,
                                            flg_status_in              => 'A',
                                            flg_rehab_workflow_type_in => 'S',
                                            dt_creation_in             => g_sysdate_tstz,
                                            dt_last_update_in          => g_sysdate_tstz,
                                            id_prof_creation_in        => i_prof.id,
                                            id_rehab_sch_need_in       => i_id_rehab_presc,
                                            rows_out                   => l_rows);
            
                l_id_rehab_epis_enc_hist := ts_rehab_epis_enc_hist.next_key;
                ts_rehab_epis_enc_hist.ins(id_rehab_epis_enc_hist_in  => l_id_rehab_epis_enc_hist,
                                           id_rehab_epis_encounter_in => l_id_rehab_epis_encounter,
                                           id_episode_origin_in       => i_id_epis_origin,
                                           id_episode_rehab_in        => o_id_episode,
                                           flg_status_in              => 'A',
                                           flg_rehab_workflow_type_in => 'S',
                                           dt_creation_in             => g_sysdate_tstz,
                                           dt_last_update_in          => g_sysdate_tstz,
                                           id_prof_creation_in        => i_prof.id,
                                           id_rehab_sch_need_in       => i_id_rehab_presc,
                                           rows_out                   => l_rows);
            END IF;
            RETURN TRUE;
        EXCEPTION
            WHEN OTHERS THEN
                RETURN FALSE;
        END inner_create_episode;
    
        -- tratamento de schedule_procedures do tipo C, N, U, AS
        FUNCTION inner_procedure_outp(o_error OUT t_error_out) RETURN BOOLEAN IS
            l_equal_dates  BOOLEAN := compare_resource_dates(i_resources,
                                                             i_procedures(l_pivot).id_schedule_procedure,
                                                             g_res_type_prof);
            l_id_room      NUMBER := get_id_room(i_resources, i_procedures(l_pivot).id_schedule_procedure);
            l_persons      table_number := get_ids_persons(i_persons);
            l_profs        table_number := get_ids_profs(i_resources, i_procedures(l_pivot).id_schedule_procedure);
            l_first_person t_person := get_first_person_data(i_persons);
        
            o_id_schedule             schedule.id_schedule%TYPE;
            l_prof_leader             t_resource := get_prof_leader(i_resources,
                                                                    i_procedures(l_pivot).id_schedule_procedure);
            l_rowids                  table_varchar;
            i                         PLS_INTEGER;
            z                         PLS_INTEGER;
            l_id_multidisc            schedule.id_multidisc%TYPE;
            l_event_dep_type          sch_event.dep_type%TYPE;
            l_event                   sch_event%ROWTYPE;
            l_flg_show                VARCHAR2(1 CHAR);
            l_msg_title               sys_message.desc_message%TYPE;
            l_msg_body                sys_message.desc_message%TYPE;
            l_id_epis_prof_resp       epis_prof_resp.id_epis_prof_resp%TYPE;
            l_id_epis_multi_prof_resp epis_multi_prof_resp.id_epis_multi_prof_resp%TYPE;
            l_exception_ext           EXCEPTION;
            l_id_software             software.id_software%TYPE;
        
        BEGIN
            g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - GET EVENT DATA. id_sch_event=' ||
                       l_id_sch_event_tab(l_pivot);
            l_event := pk_schedule_common.get_event_data(l_id_sch_event_tab(l_pivot));
        
            -- para ser multidisciplinar mesmo todos os profs devem ter a mesma data inicio
            IF l_event.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cm
               AND l_equal_dates
            THEN
                -- Get nextval from <seq_sch_group_multidisc> sequence
                g_error := l_func_name ||
                           ' - INNER_PROCEDURE_OUTP - GET MULTIDISC SEQUENCE ID - for grouping schedules';
                SELECT seq_sch_group_multidisc.nextval
                  INTO l_id_multidisc
                  FROM dual;
                -- se os profs nao partilham mesma data inicio lança exception
            ELSIF l_event.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cm
                  AND NOT l_equal_dates
            THEN
                -- SCH_T820 Nao e' permitido realizar este agendamento multidisciplinar com diferentes datas...
                g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_multi_bad_dates);
                RAISE g_invalid_data;
            END IF;
        
            -- caso especial - agendamento s multidisciplinares. cria 1 agendamento com n profs na sch_resource
            IF l_event.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_cm
               OR l_event.dep_type = pk_schedule_common.g_sch_dept_flg_dep_type_hc
            THEN
                --                t1 := dbms_utility.get_time;
            
                g_error    := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_BEGIN';
                l_dt_begin := i_dt_begin;
            
                g_error  := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_END';
                l_dt_end := i_dt_end;
            
                g_error      := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_REQUEST';
                l_dt_request := l_first_person.dt_request;
            
                g_error           := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_NOTIFICATION';
                l_dt_notification := l_first_person.dt_notification;
            
                g_error       := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_INTERNAL';
                o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_id_sch_ext           => i_id_sch_ext,
                                                          i_id_instit_requests   => l_first_person.id_instit_requests,
                                                          i_id_instit_requested  => i_id_instit_requested,
                                                          i_id_dcs_requests      => l_first_person.id_dcs_requests,
                                                          i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                        l_id_dcs),
                                                          i_id_prof_requests     => nvl(l_first_person.id_prof_requests,
                                                                                        l_first_person.id_prof_referrer_ext),
                                                          i_id_prof_schedules    => l_first_person.id_prof_schedules,
                                                          i_flg_status           => i_flg_status,
                                                          i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                          i_schedule_notes       => l_first_person.notes,
                                                          i_id_lang_preferred    => l_first_person.id_lang_translator,
                                                          i_id_reason            => l_first_person.id_reason,
                                                          i_id_origin            => l_first_person.id_origin,
                                                          i_id_room              => l_id_room,
                                                          i_flg_notification     => l_first_person.flg_notification,
                                                          i_id_schedule_ref      => i_id_sch_ref,
                                                          i_flg_vacancy          => i_flg_vacancy,
                                                          i_flg_sch_type         => l_event_dep_type,
                                                          i_reason_notes         => l_first_person.reason_notes,
                                                          i_dt_begin             => l_dt_begin,
                                                          i_dt_end               => l_dt_end,
                                                          i_dt_request           => l_dt_request,
                                                          i_flg_schedule_via     => l_first_person.flg_schedule_via,
                                                          i_id_prof_notif        => l_first_person.id_prof_notification,
                                                          i_dt_notification      => l_dt_notification,
                                                          i_flg_notification_via => l_first_person.flg_notification_via,
                                                          i_flg_request_type     => l_first_person.flg_request_type,
                                                          i_id_episode           => NULL, --i_id_episode,
                                                          i_id_multidisc         => l_id_multidisc,
                                                          i_patients             => i_persons,
                                                          i_ids_profs            => l_profs,
                                                          i_id_prof_leader       => l_prof_leader.id_resource,
                                                          i_id_group             => NULL,
                                                          i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                          i_flg_reason_type      => l_first_person.flg_reason_type,
                                                          i_video_link           => i_video_link,
                                                          o_error                => o_error);
                --                t2 := dbms_utility.get_time;
                --                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->MULTIDISC->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
            
                -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
                IF o_id_schedule IS NULL
                   AND o_error IS NOT NULL
                THEN
                    RETURN FALSE;
                END IF;
            
                --                t1 := dbms_utility.get_time;
                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_OUTP';
                IF NOT create_schedule_outp(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_id_schedule       => o_id_schedule,
                                            i_id_prof_schedules => l_first_person.id_prof_schedules,
                                            i_id_patient        => l_first_person.id_patient,
                                            i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested, l_id_dcs),
                                            i_id_sch_event      => l_id_sch_event_tab(l_pivot),
                                            i_id_prof           => l_prof_leader.id_resource,
                                            i_dt_begin          => l_dt_begin,
                                            i_schedule_notes    => l_first_person.notes,
                                            i_id_institution    => i_id_instit_requested,
                                            i_id_episode        => i_id_episode,
                                            i_flg_sched_type    => NULL,
                                            i_procedure_reqs    => i_procedure_reqs,
                                            i_id_schedule_proc  => i_procedures(l_pivot).id_schedule_procedure,
                                            i_persons           => i_persons,
                                            i_dt_referral       => i_dt_referral,
                                            o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --                t2 := dbms_utility.get_time;
                --                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->MULTIDISC->CREATE_SCHEDULE_OUTP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
            
                -- todas as reqs deste procedure devem ser actualizadas
                --                t1 := dbms_utility.get_time;
                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - INNER_UPD_REQS';
                inner_upd_reqs(o_id_schedule, i_persons(1).id_patient);
                --                t2 := dbms_utility.get_time;
                --                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->MULTIDISC->INNER_UPD_REQS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
            
                --              t1 := dbms_utility.get_time;
                g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                IF NOT inner_create_episode(i_id_schedule      => o_id_schedule,
                                            i_id_patient       => l_first_person.id_patient,
                                            i_id_dep_clin_serv => nvl(i_procedures(l_pivot).id_dcs_requested, l_id_dcs),
                                            o_id_episode       => l_id_episode_main,
                                            o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
                l_bool := generate_hhc_alerts(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_schedule => o_id_schedule,
                                              i_flg_status  => i_flg_status);
            
                -- backup full schedule
                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || o_id_schedule;
                pk_schedule_common.backup_all(i_id_sch => o_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
            
                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - ADD ID TO OUTPUT TABLE';
                o_ids_schedule.extend;
                o_ids_schedule(o_ids_schedule.last) := o_id_schedule;
            
                -- caso especial - agendamentos de grupo. cria 1 agendamento por paciente.
                -- ATENCAO: estou a assumir que a configuracao do evento 10 tem num_min_profs = 1.
                -- Se esse valor passar para zero e' preciso programar esse caso
            ELSIF l_event.flg_is_group = pk_alert_constant.g_yes
            THEN
            
                z := i_persons.first;
                WHILE z IS NOT NULL
                LOOP
                
                    IF l_profs IS NOT NULL
                       AND l_profs.count > 0
                    THEN
                        i := i_resources.first;
                        WHILE i IS NOT NULL
                        LOOP
                            IF i_resources.exists(i)
                               AND i_resources(i).id_schedule_procedure = i_procedures(l_pivot).id_schedule_procedure
                               AND i_resources(i).id_resource_type = g_res_type_prof
                               AND i_resources(i).id_resource > -1
                            THEN
                            
                                --                                t1 := dbms_utility.get_time;
                                g_error    := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_BEGIN';
                                l_dt_begin := i_resources(i).dt_begin;
                            
                                g_error  := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_END';
                                l_dt_end := i_resources(i).dt_end;
                            
                                g_error       := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_INTERNAL';
                                o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                                          i_prof                 => i_prof,
                                                                          i_id_sch_ext           => i_id_sch_ext,
                                                                          i_id_instit_requests   => i_persons(z).id_instit_requests,
                                                                          i_id_instit_requested  => i_id_instit_requested,
                                                                          i_id_dcs_requests      => i_persons(z).id_dcs_requests,
                                                                          i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                        l_id_dcs),
                                                                          i_id_prof_requests     => nvl(i_persons(z).id_prof_requests,
                                                                                                        i_persons(z).id_prof_referrer_ext),
                                                                          i_id_prof_schedules    => i_persons(z).id_prof_schedules,
                                                                          i_flg_status           => i_flg_status,
                                                                          i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                                          i_schedule_notes       => i_persons(z).notes,
                                                                          i_id_lang_preferred    => i_persons(z).id_lang_translator,
                                                                          i_id_reason            => i_persons(z).id_reason,
                                                                          i_id_origin            => i_persons(z).id_origin,
                                                                          i_id_room              => l_id_room,
                                                                          i_flg_notification     => i_persons(z).flg_notification,
                                                                          i_id_schedule_ref      => i_id_sch_ref,
                                                                          i_flg_vacancy          => i_flg_vacancy,
                                                                          i_flg_sch_type         => l_event.dep_type,
                                                                          i_reason_notes         => i_persons(z).reason_notes,
                                                                          i_dt_begin             => l_dt_begin,
                                                                          i_dt_end               => l_dt_end,
                                                                          i_dt_request           => i_persons(z).dt_request,
                                                                          i_flg_schedule_via     => i_persons(z).flg_schedule_via,
                                                                          i_id_prof_notif        => i_persons(z).id_prof_notification,
                                                                          i_dt_notification      => i_persons(z).dt_notification,
                                                                          i_flg_notification_via => i_persons(z).flg_notification_via,
                                                                          i_flg_request_type     => i_persons(z).flg_request_type,
                                                                          i_id_episode           => NULL, -- i_id_episode,
                                                                          i_id_multidisc         => NULL,
                                                                          i_patients             => t_persons(i_persons(z)),
                                                                          i_ids_profs            => table_number(i_resources(i).id_resource),
                                                                          i_id_prof_leader       => i_resources(i).id_resource,
                                                                          i_id_group             => i_id_sch_ext,
                                                                          i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                                          i_flg_reason_type      => i_persons(z).flg_reason_type,
                                                                          i_video_link           => i_video_link,
                                                                          o_error                => o_error);
                                --                                t2 := dbms_utility.get_time;
                                --                                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GROUP->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                                --                                                      'PK_SCHEDULE_API_DOWNSTREAM', null);
                            
                                -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
                                IF o_id_schedule IS NULL
                                   AND o_error IS NOT NULL
                                THEN
                                    RETURN FALSE;
                                END IF;
                            
                                --                                t1 := dbms_utility.get_time;
                                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_OUTP';
                                IF NOT create_schedule_outp(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_id_schedule       => o_id_schedule,
                                                            i_id_prof_schedules => i_persons(z).id_prof_schedules,
                                                            i_id_patient        => i_persons(z).id_patient,
                                                            i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                       l_id_dcs),
                                                            i_id_sch_event      => l_id_sch_event_tab(l_pivot),
                                                            i_id_prof           => i_resources(i).id_resource,
                                                            i_dt_begin          => l_dt_begin,
                                                            i_schedule_notes    => i_persons(z).notes,
                                                            i_id_institution    => i_id_instit_requested,
                                                            i_id_episode        => i_id_episode,
                                                            i_flg_sched_type    => NULL,
                                                            i_procedure_reqs    => i_procedure_reqs,
                                                            i_id_schedule_proc  => i_procedures(l_pivot).id_schedule_procedure,
                                                            i_persons           => t_persons(i_persons(z)),
                                                            i_dt_referral       => i_dt_referral,
                                                            o_error             => o_error)
                                THEN
                                    RETURN FALSE;
                                END IF;
                            
                                --                                t2 := dbms_utility.get_time;
                                --                                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GROUP->CREATE_SCHEDULE_OUTP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                                --                                                      'PK_SCHEDULE_API_DOWNSTREAM', null);
                            
                                --                                t1 := dbms_utility.get_time;
                                -- todas as reqs deste procedure devem ser actualizadas
                                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - INNER_UPD_REQS';
                                inner_upd_reqs(o_id_schedule, i_persons(z).id_patient);
                                --                                t2 := dbms_utility.get_time;
                                --                                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GROUP->INNER_UPD_REQS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                                --                                                       'PK_SCHEDULE_API_DOWNSTREAM', null);
                            
                                --                                t1 := dbms_utility.get_time;
                                g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                                IF NOT inner_create_episode(i_id_schedule => o_id_schedule,
                                                            i_id_patient  => i_persons(z).id_patient,
                                                            o_id_episode  => l_id_episode_main,
                                                            o_error       => o_error)
                                THEN
                                    RETURN FALSE;
                                END IF;
                            
                                --                                t2 := dbms_utility.get_time;
                                --                                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GROUP->EPISODE STUFF] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                                --                                                      'PK_SCHEDULE_API_DOWNSTREAM', null);
                            
                                --                                t1 := dbms_utility.get_time;
                                -- trial dial mundial
                                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - TRIAL DIAL';
                                IF i_persons(z).id_trial IS NOT NULL
                                    AND l_id_episode_main IS NOT NULL
                                THEN
                                    inner_set_trial(i_id_patient => i_persons(z).id_patient,
                                                    i_id_episode => l_id_episode_main,
                                                    i_id_trial   => i_persons(z).id_trial);
                                END IF;
                            
                                --                                t2 := dbms_utility.get_time;
                                --                                pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GROUP->INNER_SET_TRIAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                                --                                                      'PK_SCHEDULE_API_DOWNSTREAM', null);
                            
                                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - ADD ID TO OUTPUT TABLE';
                                o_ids_schedule.extend;
                                o_ids_schedule(o_ids_schedule.last) := o_id_schedule;
                            
                                -- backup full schedule
                                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' ||
                                           o_id_schedule;
                                pk_schedule_common.backup_all(i_id_sch    => o_id_schedule,
                                                              i_dt_update => NULL,
                                                              i_id_prof_u => NULL);
                            
                            END IF;
                        
                            i := i_resources.next(i);
                        END LOOP;
                    END IF;
                    z := i_persons.next(z);
                END LOOP;
            
                -- CASO HABITUAL. todos os outros eventos
            ELSE
                g_error      := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_REQUEST';
                l_dt_request := l_first_person.dt_request;
            
                g_error           := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_NOTIFICATION';
                l_dt_notification := l_first_person.dt_notification;
            
                -- criar 1 agendamento por prof
                IF l_profs IS NOT NULL
                   AND l_profs.count > 0
                THEN
                    i := i_resources.first;
                    WHILE i IS NOT NULL
                    LOOP
                        IF i_resources.exists(i)
                           AND i_resources(i).id_schedule_procedure = i_procedures(l_pivot).id_schedule_procedure
                           AND i_resources(i).id_resource_type = g_res_type_prof
                           AND i_resources(i).id_resource > -1
                        THEN
                        
                            --                            t1 := dbms_utility.get_time;
                        
                            g_error    := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_BEGIN';
                            l_dt_begin := i_resources(i).dt_begin;
                        
                            g_error  := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_END';
                            l_dt_end := i_resources(i).dt_end;
                        
                            g_error       := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_INTERNAL';
                            o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                                      i_prof                 => i_prof,
                                                                      i_id_sch_ext           => i_id_sch_ext,
                                                                      i_id_instit_requests   => l_first_person.id_instit_requests,
                                                                      i_id_instit_requested  => i_id_instit_requested,
                                                                      i_id_dcs_requests      => l_first_person.id_dcs_requests,
                                                                      i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                    l_id_dcs),
                                                                      i_id_prof_requests     => nvl(l_first_person.id_prof_requests,
                                                                                                    l_first_person.id_prof_referrer_ext),
                                                                      i_id_prof_schedules    => l_first_person.id_prof_schedules,
                                                                      i_flg_status           => i_flg_status,
                                                                      i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                                      i_schedule_notes       => l_first_person.notes,
                                                                      i_id_lang_preferred    => l_first_person.id_lang_translator,
                                                                      i_id_reason            => l_first_person.id_reason,
                                                                      i_id_origin            => l_first_person.id_origin,
                                                                      i_id_room              => l_id_room,
                                                                      i_flg_notification     => l_first_person.flg_notification,
                                                                      i_id_schedule_ref      => i_id_sch_ref,
                                                                      i_flg_vacancy          => i_flg_vacancy,
                                                                      i_flg_sch_type         => i_procedures(l_pivot).flg_sch_type,
                                                                      i_reason_notes         => l_first_person.reason_notes,
                                                                      i_dt_begin             => l_dt_begin,
                                                                      i_dt_end               => l_dt_end,
                                                                      i_dt_request           => l_dt_request,
                                                                      i_flg_schedule_via     => l_first_person.flg_schedule_via,
                                                                      i_id_prof_notif        => l_first_person.id_prof_notification,
                                                                      i_dt_notification      => l_dt_notification,
                                                                      i_flg_notification_via => l_first_person.flg_notification_via,
                                                                      i_flg_request_type     => l_first_person.flg_request_type,
                                                                      i_id_episode           => NULL, --i_id_episode,
                                                                      i_id_multidisc         => NULL,
                                                                      i_patients             => i_persons,
                                                                      i_ids_profs            => table_number(i_resources(i).id_resource),
                                                                      i_id_prof_leader       => i_resources(i).id_resource,
                                                                      i_id_group             => NULL,
                                                                      i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                                      i_flg_reason_type      => l_first_person.flg_reason_type,
                                                                      i_video_link           => i_video_link,
                                                                      o_error                => o_error);
                        
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                            -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
                            IF o_id_schedule IS NULL
                               AND o_error IS NOT NULL
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            --                            t1 := dbms_utility.get_time;
                            g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - CREATE_SCHEDULE_OUTP';
                            IF NOT create_schedule_outp(i_lang              => i_lang,
                                                        i_prof              => i_prof,
                                                        i_id_schedule       => o_id_schedule,
                                                        i_id_prof_schedules => l_first_person.id_prof_schedules,
                                                        i_id_patient        => l_first_person.id_patient,
                                                        i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                   l_id_dcs),
                                                        i_id_sch_event      => l_id_sch_event_tab(l_pivot),
                                                        i_id_prof           => i_resources(i).id_resource,
                                                        i_dt_begin          => l_dt_begin,
                                                        i_schedule_notes    => l_first_person.notes,
                                                        i_id_institution    => i_id_instit_requested,
                                                        i_id_episode        => i_id_episode,
                                                        i_flg_sched_type    => NULL,
                                                        i_procedure_reqs    => i_procedure_reqs,
                                                        i_id_schedule_proc  => i_procedures(l_pivot).id_schedule_procedure,
                                                        i_persons           => i_persons,
                                                        i_dt_referral       => i_dt_referral,
                                                        o_error             => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC->CREATE_SCHEDULE_OUTP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                   'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                            --                            t1 := dbms_utility.get_time;
                            -- todas as reqs deste procedure devem ser actualizadas
                            g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - INNER_UPD_REQS';
                            inner_upd_reqs(o_id_schedule, l_first_person.id_patient);
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC->INNER_UPD_REQS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                            --                          t1 := dbms_utility.get_time;
                            g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                            IF NOT inner_create_episode(i_id_schedule      => o_id_schedule,
                                                        i_id_patient       => l_first_person.id_patient,
                                                        i_id_dep_clin_serv => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                  l_id_dcs),
                                                        o_id_episode       => l_id_episode_main,
                                                        o_error            => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC->EPISODE STUFF] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                            --                            t1 := dbms_utility.get_time;
                            -- trial dial mondial
                            IF l_first_person.id_trial IS NOT NULL
                               AND l_id_episode_main IS NOT NULL
                            THEN
                                g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - TRIAL DIAL';
                                inner_set_trial(i_id_patient => l_first_person.id_patient,
                                                i_id_episode => l_id_episode_main,
                                                i_id_trial   => l_first_person.id_trial);
                            END IF;
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC->INNER_SET_TRIAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                            /*     g_error := ' PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP first i_prof_resp: ' || i_prof_resp ||
                                       ' episode:' || l_id_episode_main;
                            alertlog.pk_alertlog.log_debug(text            => g_error,
                                                           object_name     => g_package_name,
                                                           sub_object_name => l_func_name);
                            
                                                       IF i_prof_resp IS NOT NULL
                            THEN
                                IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                                              i_prof                    => i_prof,
                                                                              i_id_episode              => l_id_episode_main,
                                                                              i_id_prof_resp            => i_prof_resp,
                                                                              i_id_speciality           => pk_prof_utils.get_prof_speciality_id(i_lang => i_lang,
                                                                                                                                                i_prof => profissional(i_prof_resp,
                                                                                                                                                                             i_prof.institution,
                                                                                                                                                                             i_prof.software)),
                                                                              i_notes                   => NULL,
                                                                              i_dt_reg                  => current_timestamp,
                                                                              o_flg_show                => l_flg_show,
                                                                              o_msg_title               => l_msg_title,
                                                                              o_msg_body                => l_msg_body,
                                                                              o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                                              o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                              o_error                   => o_error)
                                THEN
                                    RETURN FALSE; -- direct return in order to keep possible user error messages
                                END IF;
                            END IF;*/
                        
                            g_error := 'CALL pk_hand_off_api.set_overall_responsability. i_id_prof_resp: ' ||
                                       i_prof_resp;
                            pk_alertlog.log_info(text            => g_error,
                                                 object_name     => g_package_name,
                                                 sub_object_name => l_func_name);
                            IF i_prof_resp IS NOT NULL
                               AND NOT pk_hand_off_api.set_overall_responsability(i_lang              => i_lang,
                                                                                  i_prof              => i_prof,
                                                                                  i_id_prof_admitting => profissional(i_prof_resp,
                                                                                                                      i_prof.institution,
                                                                                                                      i_prof.software),
                                                                                  i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                             l_id_dcs),
                                                                                  i_id_episode        => l_id_episode_main,
                                                                                  i_dt_reg            => current_timestamp,
                                                                                  o_error             => o_error)
                            THEN
                                RETURN FALSE; -- direct return in order to keep possible user error messages
                            END IF;
                            -- backup full schedule
                            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' ||
                                       o_id_schedule;
                            pk_schedule_common.backup_all(i_id_sch    => o_id_schedule,
                                                          i_dt_update => NULL,
                                                          i_id_prof_u => NULL);
                        
                            g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - ADD ID TO OUTPUT TABLE';
                            o_ids_schedule.extend;
                            o_ids_schedule(o_ids_schedule.last) := o_id_schedule;
                        
                        END IF;
                        i := i_resources.next(i);
                    END LOOP;
                
                    -- quando nao ha profs cria-se 1 agendamento com datas de inicio e fim iguais a i_dt_begin e i_dt_end
                ELSE
                    --                    t1 := dbms_utility.get_time;
                
                    g_error    := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_BEGIN';
                    l_dt_begin := i_dt_begin;
                
                    g_error  := l_func_name || ' - INNER_PROCEDURE_OUTP - SET DT_END';
                    l_dt_end := i_dt_end;
                
                    g_error       := l_func_name || ' - INNER_PROCEDURE_OUTP - CALL CREATE_SCHEDULE_INTERNAL';
                    o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_id_sch_ext           => i_id_sch_ext,
                                                              i_id_instit_requests   => l_first_person.id_instit_requests,
                                                              i_id_instit_requested  => i_id_instit_requested,
                                                              i_id_dcs_requests      => l_first_person.id_dcs_requests,
                                                              i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                            l_id_dcs),
                                                              i_id_prof_requests     => nvl(l_first_person.id_prof_requests,
                                                                                            l_first_person.id_prof_referrer_ext),
                                                              i_id_prof_schedules    => l_first_person.id_prof_schedules,
                                                              i_flg_status           => i_flg_status,
                                                              i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                              i_schedule_notes       => l_first_person.notes,
                                                              i_id_lang_preferred    => l_first_person.id_lang_translator,
                                                              i_id_reason            => l_first_person.id_reason,
                                                              i_id_origin            => l_first_person.id_origin,
                                                              i_id_room              => l_id_room,
                                                              i_flg_notification     => l_first_person.flg_notification,
                                                              i_id_schedule_ref      => i_id_sch_ref,
                                                              i_flg_vacancy          => i_flg_vacancy,
                                                              i_flg_sch_type         => i_procedures(l_pivot).flg_sch_type,
                                                              i_reason_notes         => l_first_person.reason_notes,
                                                              i_dt_begin             => l_dt_begin,
                                                              i_dt_end               => l_dt_end,
                                                              i_dt_request           => l_dt_request,
                                                              i_flg_schedule_via     => l_first_person.flg_schedule_via,
                                                              i_id_prof_notif        => l_first_person.id_prof_notification,
                                                              i_dt_notification      => l_dt_notification,
                                                              i_flg_notification_via => l_first_person.flg_notification_via,
                                                              i_flg_request_type     => l_first_person.flg_request_type,
                                                              i_id_episode           => NULL, --i_id_episode,
                                                              i_id_multidisc         => NULL,
                                                              i_patients             => i_persons,
                                                              i_ids_profs            => NULL,
                                                              i_id_prof_leader       => NULL,
                                                              i_id_group             => NULL,
                                                              i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                              i_flg_reason_type      => l_first_person.flg_reason_type,
                                                              i_video_link           => i_video_link,
                                                              o_error                => o_error);
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC PROFLESS->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
                    IF o_id_schedule IS NULL
                       AND o_error IS NOT NULL
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    --                    t1 := dbms_utility.get_time;
                    g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - CALL CREATE_SCHEDULE_OUTP';
                    IF NOT
                        create_schedule_outp(i_lang              => i_lang,
                                             i_prof              => i_prof,
                                             i_id_schedule       => o_id_schedule,
                                             i_id_prof_schedules => l_first_person.id_prof_schedules,
                                             i_id_patient        => l_first_person.id_patient,
                                             i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested, l_id_dcs),
                                             i_id_sch_event      => l_id_sch_event_tab(l_pivot),
                                             i_id_prof           => NULL,
                                             i_dt_begin          => l_dt_begin,
                                             i_schedule_notes    => l_first_person.notes,
                                             i_id_institution    => i_id_instit_requested,
                                             i_id_episode        => i_id_episode,
                                             i_flg_sched_type    => NULL,
                                             i_procedure_reqs    => i_procedure_reqs,
                                             i_id_schedule_proc  => i_procedures(l_pivot).id_schedule_procedure,
                                             i_persons           => i_persons,
                                             i_dt_referral       => i_dt_referral,
                                             o_error             => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC PROFLESS->CREATE_SCHEDULE_OUTP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    --                    t1 := dbms_utility.get_time;
                    -- todas as reqs deste procedure devem ser actualizadas
                    g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - CALL INNER_UPD_REQS';
                    inner_upd_reqs(o_id_schedule, l_first_person.id_patient);
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC PROFLESS->INNER_UPD_REQS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    --                  t1 := dbms_utility.get_time;
                    g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                    IF NOT inner_create_episode(i_id_schedule => o_id_schedule,
                                                i_id_patient  => l_first_person.id_patient,
                                                o_id_episode  => l_id_episode_main,
                                                o_error       => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC PROFLESS->EPISODE STUFF] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    --                    t1 := dbms_utility.get_time;
                
                    -- trial dial mondial
                    g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - TRIAL DIAL';
                    IF l_first_person.id_trial IS NOT NULL
                       AND l_id_episode_main IS NOT NULL
                    THEN
                        inner_set_trial(i_id_patient => l_first_person.id_patient,
                                        i_id_episode => l_id_episode_main,
                                        i_id_trial   => l_first_person.id_trial);
                    END IF;
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_OUTP->GENERIC PROFLESS->INNER_SET_TRIAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    /*   g_error := 'PK_HAND_OFF_CORE.CALL_SET_OVERALL_RESP  second i_prof_resp: ' || i_prof_resp ||
                               ' episode:' || l_id_episode_main;
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_package_name,
                                                   sub_object_name => l_func_name);
                    
                                        IF i_prof_resp IS NOT NULL
                    THEN
                        IF NOT pk_hand_off_core.call_set_overall_resp(i_lang                    => i_lang,
                                                                      i_prof                    => i_prof,
                                                                      i_id_episode              => l_id_episode_main,
                                                                      i_id_prof_resp            => i_prof_resp,
                                                                      i_id_speciality           => pk_prof_utils.get_prof_speciality_id(i_lang => i_lang,
                                                                                                                                        i_prof => profissional(i_prof_resp,
                                                                                                                                                                     i_prof.institution,
                                                                                                                                                                     i_prof.software)),
                                                                      i_notes                   => NULL,
                                                                      i_dt_reg                  => current_timestamp,
                                                                      o_flg_show                => l_flg_show,
                                                                      o_msg_title               => l_msg_title,
                                                                      o_msg_body                => l_msg_body,
                                                                      o_id_epis_prof_resp       => l_id_epis_prof_resp,
                                                                      o_id_epis_multi_prof_resp => l_id_epis_multi_prof_resp,
                                                                      o_error                   => o_error)
                        THEN
                            RETURN FALSE; -- direct return in order to keep possible user error messages
                        END IF;
                    END IF;*/
                    g_error := 'CALL pk_hand_off_api.set_overall_responsability. i_id_prof_resp: ' || i_prof_resp;
                    pk_alertlog.log_info(text            => g_error,
                                         object_name     => g_package_name,
                                         sub_object_name => l_func_name);
                    IF i_prof_resp IS NOT NULL
                       AND NOT pk_hand_off_api.set_overall_responsability(i_lang              => i_lang,
                                                                          i_prof              => i_prof,
                                                                          i_id_prof_admitting => profissional(i_prof_resp,
                                                                                                              i_prof.institution,
                                                                                                              i_prof.software),
                                                                          i_id_dep_clin_serv  => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                     l_id_dcs),
                                                                          i_id_episode        => l_id_episode_main,
                                                                          i_dt_reg            => current_timestamp,
                                                                          o_error             => o_error)
                    THEN
                        RETURN FALSE; -- direct return in order to keep possible user error messages
                    END IF;
                
                    -- backup full schedule
                    g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || o_id_schedule;
                    pk_schedule_common.backup_all(i_id_sch => o_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
                
                    g_error := l_func_name || ' - INNER_PROCEDURE_OUTP - ADD ID TO OUTPUT TABLE';
                    o_ids_schedule.extend;
                    o_ids_schedule(o_ids_schedule.last) := o_id_schedule;
                END IF;
            END IF;
        
            RETURN TRUE;
        END inner_procedure_outp;
    
        -- tratamento de schedule_procedures do tipo E, X
        FUNCTION inner_procedure_exam
        (
            i_proc_idx IN table_number, --coleccao contendo todos os indices da i_procedures que sao procedures de exames
            o_error    OUT t_error_out
        ) RETURN BOOLEAN IS
            l_func_name        VARCHAR2(32) := 'INNER_PROCEDURE_EXAM';
            i                  PLS_INTEGER;
            i2                 PLS_INTEGER;
            l_id_schedule      schedule.id_schedule%TYPE;
            l_id_room          NUMBER;
            l_proc_req         t_procedure_req;
            l_ids_prof         table_number := table_number();
            l_profs_temp       table_number := table_number();
            l_id_dcs_requested NUMBER;
            l_id_exam          NUMBER;
            l_ids_exam         table_number := table_number();
            l_ids_req          table_number := table_number();
        BEGIN
            -- check input
            IF i_proc_idx IS NULL
               OR i_proc_idx.count = 0
            THEN
                RETURN TRUE;
            END IF;
        
            -- main loop on persons - one schedule per person to be created
            i := i_persons.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_persons.exists(i)
                THEN
                
                    -- cycle the input procedures to extract data.
                    --            t1 := dbms_utility.get_time;
                    i2 := i_proc_idx.first;
                    WHILE i2 IS NOT NULL
                    LOOP
                        -- room. Picks the first found
                        IF l_id_room IS NULL
                        THEN
                            g_error   := l_func_name || ' - GET ROOM ID';
                            l_id_room := get_id_room(i_resources, i_procedures(i_proc_idx(i2)).id_schedule_procedure);
                        END IF;
                    
                        -- id_dcs_requested. Pick the foist
                        IF l_id_dcs_requested IS NULL
                        THEN
                            g_error := l_func_name || ' - GET REQUESTED DCS ID';
                            -- ag. de exames nao precisam do dcs. mas para respeitar constraint defeita para -1. -1 e' um dcs versionado
                            l_id_dcs_requested := nvl(i_procedures(i_proc_idx(i2)).id_dcs_requested, -1);
                        END IF;
                    
                        -- profs
                        g_error      := l_func_name || ' - GET PROFS IDS';
                        l_profs_temp := get_ids_profs(i_resources, i_procedures(i_proc_idx(i2)).id_schedule_procedure);
                        l_ids_prof   := l_ids_prof MULTISET UNION DISTINCT l_profs_temp; -- reuniao das 2 collections, excluir repetidos
                    
                        -- exam ids
                        g_error   := l_func_name || ' - GET EXAM ID';
                        l_id_exam := get_exam_id(i_procedures(i_proc_idx(i2)).id_content);
                        l_ids_exam.extend;
                        l_ids_exam(l_ids_exam.last) := l_id_exam;
                    
                        -- requisitions
                        g_error    := l_func_name || ' - GET PROCEDURE REQ';
                        l_proc_req := get_procedure_req(i_procedure_reqs,
                                                        i_procedures    (i_proc_idx(i2)).id_schedule_procedure,
                                                        i_persons       (i).id_patient);
                    
                        l_ids_req.extend;
                        l_ids_req(l_ids_req.last) := l_proc_req.id; -- adiciona sempre requisicao a' lista mesmo que seja null. e' essencial estar assim
                    
                        i2 := i_proc_idx.next(i2);
                    END LOOP;
                    --            t2 := dbms_utility.get_time;
                    --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_EXAM->EXTRACT DATA] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    --                    t1 := dbms_utility.get_time;
                    l_dt_request      := i_persons(i).dt_request;
                    l_dt_notification := i_persons(i).dt_notification;
                
                    g_error       := l_func_name || ' - CALL CREATE_SCHEDULE_INTERNAL';
                    l_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_id_sch_ext           => i_id_sch_ext,
                                                              i_id_instit_requests   => i_persons(i).id_instit_requests,
                                                              i_id_instit_requested  => i_id_instit_requested,
                                                              i_id_dcs_requests      => i_persons(i).id_dcs_requests,
                                                              i_id_dcs_requested     => l_id_dcs_requested,
                                                              i_id_prof_requests     => i_persons(i).id_prof_requests,
                                                              i_id_prof_schedules    => i_persons(i).id_prof_schedules,
                                                              i_flg_status           => i_flg_status,
                                                              i_id_sch_event         => l_id_sch_event_tab(i_proc_idx(1)), -- sao todos iguais por isso pego o primeiro
                                                              i_schedule_notes       => i_persons(i).notes,
                                                              i_id_lang_preferred    => i_persons(i).id_lang_translator,
                                                              i_id_reason            => i_persons(i).id_reason,
                                                              i_id_origin            => i_persons(i).id_origin,
                                                              i_id_room              => l_id_room,
                                                              i_flg_notification     => i_persons(i).flg_notification,
                                                              i_id_schedule_ref      => i_id_sch_ref,
                                                              i_flg_vacancy          => i_flg_vacancy,
                                                              i_flg_sch_type         => i_procedures(i_proc_idx(1)).flg_sch_type, -- sao todos iguais por isso pego o primeiro
                                                              i_reason_notes         => i_persons(i).reason_notes,
                                                              i_dt_begin             => i_dt_begin,
                                                              i_dt_end               => i_dt_end,
                                                              i_dt_request           => l_dt_request,
                                                              i_flg_schedule_via     => i_persons(i).flg_schedule_via,
                                                              i_id_prof_notif        => i_persons(i).id_prof_notification,
                                                              i_dt_notification      => l_dt_notification,
                                                              i_flg_notification_via => i_persons(i).flg_notification_via,
                                                              i_flg_request_type     => i_persons(i).flg_request_type,
                                                              i_id_episode           => i_id_episode,
                                                              i_id_multidisc         => NULL,
                                                              i_patients             => t_persons(i_persons(i)),
                                                              i_ids_profs            => l_ids_prof,
                                                              i_id_prof_leader       => NULL,
                                                              i_id_group             => NULL,
                                                              i_id_sch_procedure     => i_procedures(i_proc_idx(1)).id_schedule_procedure,
                                                              i_flg_reason_type      => i_persons(i).flg_reason_type,
                                                              o_error                => o_error);
                
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_EXAM->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
                    IF l_id_schedule IS NULL
                       AND o_error IS NOT NULL
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    --                    t1 := dbms_utility.get_time;
                    g_error := l_func_name || ' - CALL CREATE_SCHEDULE_EXAM';
                    IF NOT create_schedule_exam(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_schedule       => l_id_schedule,
                                                i_ids_exam_req_dets => l_ids_req,
                                                i_dt_begin          => i_dt_begin,
                                                i_id_episode        => l_id_episode_main,
                                                i_ids_exams         => l_ids_exam,
                                                i_id_patient        => i_persons(i).id_patient,
                                                i_flg_status        => i_flg_status,
                                                i_id_inst           => i_id_instit_requested,
                                                o_error             => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_EXAM->CREATE_SCHEDULE_EXAM] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    -- backup full schedule
                    g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || l_id_schedule;
                    pk_schedule_common.backup_all(i_id_sch => l_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
                
                    g_error := l_func_name || ' - ADD ID TO OUTPUT TABLE';
                    o_ids_schedule.extend;
                    o_ids_schedule(o_ids_schedule.last) := l_id_schedule;
                
                END IF;
                i := i_persons.next(i);
            END LOOP;
        
            RETURN TRUE;
        END inner_procedure_exam;
    
        -- tratamento de schedule_procedures do tipo IN
        FUNCTION inner_procedure_inp
        (
            i_proc_req IN t_procedure_req,
            o_error    OUT t_error_out
        ) RETURN BOOLEAN IS
            i                     PLS_INTEGER;
            l_id_schedule         schedule.id_schedule%TYPE;
            l_proc                t_procedure;
            l_bed                 t_resource;
            l_id_room             room.id_room%TYPE;
            l_person              t_person := get_person(i_persons, i_proc_req.id_schedule_person);
            l_procedure           t_procedure := get_procedure(i_procedures, i_proc_req.id_schedule_procedure);
            l_id_patient          waiting_list.id_patient%TYPE;
            l_id_adm_indic        adm_request.id_adm_indication%TYPE;
            l_id_prof_dest        adm_request.id_dest_prof%TYPE;
            l_id_dest_inst        adm_request.id_dest_inst%TYPE;
            l_id_department       adm_request.id_department%TYPE;
            l_id_dcs              adm_request.id_dep_clin_serv%TYPE;
            l_id_room_type        adm_request.id_room_type%TYPE;
            l_id_pref_room        adm_request.id_pref_room%TYPE;
            l_id_adm_type         adm_request.id_admission_type%TYPE;
            l_flg_mix_nurs        adm_request.flg_mixed_nursing%TYPE;
            l_id_bed_type         adm_request.id_bed_type%TYPE;
            l_dt_admission        adm_request.dt_admission%TYPE;
            l_id_episode          adm_request.id_dest_episode%TYPE;
            l_exp_duration        adm_request.expected_duration%TYPE;
            l_id_external_request waiting_list.id_external_request%TYPE;
            l_id_sch_event        sch_event.id_sch_event%TYPE;
        BEGIN
        
            -- get bed resource from inpatient procedure
            g_error := l_func_name || ' - INNER_PROCEDURE_INP - GET BED DATA';
            l_bed   := get_first_resource_data(i_resources     => i_resources,
                                               i_id_sch_proc   => l_procedure.id_schedule_procedure,
                                               i_resource_type => g_res_type_bed);
            /* -- ALERT-298820
                        IF l_bed.id_schedule_procedure IS NULL
                        THEN
                            g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_bed_resource); --'MISSING BED RESOURCE';
                            RAISE g_invalid_data;
                        END IF;
            */
        
            --            t1 := dbms_utility.get_time;
        
            -- obtain the bed's room
            IF l_bed.id_resource IS NOT NULL
            THEN
                g_error := l_func_name || ' - INNER_PROCEDURE_INP - GET ID_ROOM';
                SELECT id_room
                  INTO l_id_room
                  FROM bed b
                 WHERE b.id_bed = l_bed.id_resource;
            END IF;
        
            g_error    := l_func_name || ' - INNER_PROCEDURE_INP - GET DT_BEGIN';
            l_dt_begin := nvl(l_bed.dt_begin, i_dt_begin);
        
            g_error  := l_func_name || ' - INNER_PROCEDURE_INP - GET DT_END';
            l_dt_end := nvl(l_bed.dt_end, i_dt_end);
        
            g_error      := l_func_name || ' - INNER_PROCEDURE_INP - GET DT_REQUEST';
            l_dt_request := l_person.dt_request;
        
            g_error           := l_func_name || ' - INNER_PROCEDURE_INP - GET DT_NOTIFICATION';
            l_dt_notification := l_person.dt_notification;
        
            -- fetch admission data
            g_error := l_func_name || ' - INNER_PROCEDURE_INP - CALL PK_SCHEDULE_INP.ADM_REQUEST_DATA';
            IF NOT pk_schedule_inp.get_adm_request_data(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_wl               => i_proc_req.id,
                                                        i_unscheduled         => pk_alert_constant.g_yes,
                                                        o_id_patient          => l_id_patient,
                                                        o_id_adm_indic        => l_id_adm_indic,
                                                        o_id_prof_dest        => l_id_prof_dest,
                                                        o_id_dest_inst        => l_id_dest_inst,
                                                        o_id_department       => l_id_department,
                                                        o_id_dcs              => l_id_dcs,
                                                        o_id_room_type        => l_id_room_type,
                                                        o_id_pref_room        => l_id_pref_room,
                                                        o_id_adm_type         => l_id_adm_type,
                                                        o_flg_mix_nurs        => l_flg_mix_nurs,
                                                        o_id_bed_type         => l_id_bed_type,
                                                        o_dt_admission        => l_dt_admission,
                                                        o_id_episode          => l_id_episode,
                                                        o_exp_duration        => l_exp_duration,
                                                        o_id_external_request => l_id_external_request,
                                                        o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- nao precisa do dcs. mas para respeitar constraint defeita para -1. -1 e' um dcs versionado
            l_procedure.id_dcs_requested := nvl(l_procedure.id_dcs_requested, -1);
        
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_INP->GET_ADM_REQUEST_DATA] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            --            t1 := dbms_utility.get_time;
            g_error       := l_func_name || ' - INNER_PROCEDURE_INP - CALL CREATE_SCHEDULE_INTERNAL';
            l_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                      i_prof                 => i_prof,
                                                      i_id_sch_ext           => i_id_sch_ext,
                                                      i_id_instit_requests   => l_person.id_instit_requests,
                                                      i_id_instit_requested  => i_id_instit_requested,
                                                      i_id_dcs_requests      => l_person.id_dcs_requests,
                                                      i_id_dcs_requested     => l_procedure.id_dcs_requested,
                                                      i_id_prof_requests     => l_person.id_prof_requests,
                                                      i_id_prof_schedules    => l_person.id_prof_schedules,
                                                      i_flg_status           => i_flg_status,
                                                      i_id_sch_event         => nvl(get_event_from_sch_type(l_procedure.flg_sch_type,
                                                                                                            i_id_instit_requested,
                                                                                                            i_prof.software),
                                                                                    17),
                                                      i_schedule_notes       => l_person.notes,
                                                      i_id_lang_preferred    => l_person.id_lang_translator,
                                                      i_id_reason            => l_person.id_reason,
                                                      i_id_origin            => l_person.id_origin,
                                                      i_id_room              => l_id_room,
                                                      i_flg_notification     => l_person.flg_notification,
                                                      i_id_schedule_ref      => i_id_sch_ref,
                                                      i_flg_vacancy          => i_flg_vacancy,
                                                      i_flg_sch_type         => pk_schedule_common.g_sch_dept_flg_dep_type_inp,
                                                      i_reason_notes         => l_person.reason_notes,
                                                      i_dt_begin             => l_dt_begin,
                                                      i_dt_end               => l_dt_end,
                                                      i_dt_request           => l_dt_request,
                                                      i_flg_schedule_via     => l_person.flg_schedule_via,
                                                      i_id_prof_notif        => l_person.id_prof_notification,
                                                      i_dt_notification      => l_dt_notification,
                                                      i_flg_notification_via => l_person.flg_notification_via,
                                                      i_flg_request_type     => l_person.flg_request_type,
                                                      i_id_episode           => l_id_episode,
                                                      i_id_multidisc         => NULL,
                                                      i_patients             => t_persons(l_person),
                                                      i_ids_profs            => get_ids_profs(i_resources,
                                                                                              i_proc_req.id_schedule_procedure),
                                                      i_id_prof_leader       => NULL,
                                                      i_id_group             => NULL,
                                                      i_id_sch_procedure     => i_proc_req.id_schedule_procedure,
                                                      i_flg_reason_type      => l_person.flg_reason_type,
                                                      o_error                => o_error);
        
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_INP->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            -- controlo de erro especifico que possa vir do pk_visit.set_first_obs
            IF l_id_schedule IS NULL
               AND o_error IS NOT NULL
            THEN
                RETURN FALSE;
            END IF;
        
            --            t1 := dbms_utility.get_time;
            g_error := l_func_name || ' - INNER_PROCEDURE_INP - CALL CREATE_SCHEDULE_INP';
            IF NOT create_schedule_inp(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_wl               => i_proc_req.id,
                                       i_id_bed              => l_bed.id_resource,
                                       i_flg_sch_type        => pk_schedule_common.g_sch_dept_flg_dep_type_inp,
                                       i_id_schedule         => l_id_schedule,
                                       i_flg_tempor          => get_sch_flg_tempor(i_flg_status),
                                       i_id_episode          => l_id_episode,
                                       i_id_patient          => l_person.id_patient,
                                       i_dt_end              => l_dt_end, -- é mesmo assim
                                       i_id_room             => l_id_room,
                                       i_id_external_request => l_id_external_request,
                                       i_schedule_notes      => l_person.notes,
                                       i_dt_referral         => i_dt_referral,
                                       o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_INP->CREATE_SCHEDULE_INP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            -- backup full schedule
            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || l_id_schedule;
            pk_schedule_common.backup_all(i_id_sch => l_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
        
            g_error := l_func_name || ' - INNER_PROCEDURE_INP - ADD ID TO OUTPUT TABLE';
            o_ids_schedule.extend;
            o_ids_schedule(o_ids_schedule.last) := l_id_schedule;
        
            RETURN TRUE;
        END inner_procedure_inp;
    
        -- tratamento de schedule_procedures do tipo S
        FUNCTION inner_procedure_oris
        (
            i_proc_req IN t_procedure_req,
            o_error    OUT t_error_out
        ) RETURN BOOLEAN IS
            l_id_schedule schedule.id_schedule%TYPE;
            i             PLS_INTEGER;
            l_room        t_resource;
            l_prof_leader t_resource := get_prof_leader(i_resources, i_proc_req.id_schedule_procedure);
            l_person      t_person := get_person(i_persons, i_proc_req.id_schedule_person);
            l_procedure   t_procedure := get_procedure(i_procedures, i_proc_req.id_schedule_procedure);
            l_dt_tmp      TIMESTAMP WITH TIME ZONE;
        BEGIN
        
            g_error    := l_func_name || ' - INNER_PROCEDURE_ORIS - CALCULATE DT_BEGIN AND DT_END';
            l_dt_begin := NULL;
            l_dt_end   := NULL;
            i          := i_procedures.first;
        
            WHILE i IS NOT NULL
            LOOP
                IF i_procedures.exists(i)
                THEN
                    g_error := l_func_name || ' - INNER_PROCEDURE_ORIS - GET ROOM DATA';
                    l_room  := get_first_resource_data(i_resources     => i_resources,
                                                       i_id_sch_proc   => i_procedures(i).id_schedule_procedure,
                                                       i_resource_type => g_res_type_room);
                
                    /*
                                        IF l_room.id_schedule_procedure IS NULL THEN
                                            l_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_room_resource); --'MISSING ROOM RESOURCE';
                                            RAISE l_invalid_data;
                                        END IF;
                    */
                
                    IF l_room.id_schedule_procedure IS NOT NULL
                    THEN
                        g_error  := l_func_name || ' - INNER_PROCEDURE_ORIS - GET DT_BEGIN';
                        l_dt_tmp := l_room.dt_begin;
                    
                        l_dt_begin := least(nvl(l_dt_begin, l_dt_tmp), l_dt_tmp);
                    
                        g_error  := l_func_name || ' - INNER_PROCEDURE_ORIS - GET DT_END';
                        l_dt_tmp := l_room.dt_end;
                    
                        l_dt_end := greatest(nvl(l_dt_end, l_dt_tmp), l_dt_tmp);
                    END IF;
                END IF;
                i := i_procedures.next(i);
            END LOOP;
        
            -- para o caso de nao haver recursos do tipo sala usa-se as datas principais
            IF l_dt_begin IS NULL
            THEN
                l_dt_begin := i_dt_begin;
            END IF;
        
            IF l_dt_end IS NULL
            THEN
                l_dt_end := i_dt_end;
            END IF;
        
            --            t1 := dbms_utility.get_time;
        
            g_error := l_func_name || ' - INNER_PROCEDURE_ORIS - GET DT_REQUEST';
            IF NOT string_to_tstz(i_lang, i_prof, l_person.dt_request, l_dt_request, o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := l_func_name || ' - INNER_PROCEDURE_ORIS - GET DT_NOTIFICATION';
            IF NOT string_to_tstz(i_lang, i_prof, l_person.dt_notification, l_dt_notification, o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := l_func_name || ' - INNER_PROCEDURE_ORIS - CREATE_SCHEDULE_ORIS';
            IF NOT create_schedule_oris(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_id_sch_ext            => i_id_sch_ext,
                                        i_dt_begin              => l_dt_begin,
                                        i_dt_end                => l_dt_end,
                                        i_id_wl                 => i_proc_req.id,
                                        i_id_room               => l_room.id_resource,
                                        i_id_instit_requests    => l_person.id_instit_requests,
                                        i_id_instit_requested   => i_id_instit_requested,
                                        i_id_dcs_requests       => l_person.id_dcs_requests,
                                        i_dcs_list              => table_number(l_procedure.id_dcs_requested),
                                        i_id_prof_requests      => l_person.id_prof_requests,
                                        i_id_prof_schedules     => l_person.id_prof_schedules,
                                        i_flg_status            => i_flg_status,
                                        i_id_sch_event          => nvl(get_event_from_sch_type(l_procedure.flg_sch_type,
                                                                                               i_id_instit_requested,
                                                                                               i_prof.software),
                                                                       14),
                                        i_schedule_notes        => l_person.notes,
                                        i_id_lang_preferred     => l_person.id_lang_translator,
                                        i_id_reason             => l_person.id_reason,
                                        i_id_origin             => l_person.id_origin,
                                        i_flg_notification      => l_person.flg_notification,
                                        i_id_schedule_ref       => i_id_sch_ref,
                                        i_id_inst               => i_id_instit_requested,
                                        i_flg_vacancy           => i_flg_vacancy,
                                        i_notes                 => l_person.notes,
                                        i_flg_sch_type          => pk_schedule_common.g_sch_dept_flg_dep_type_sr,
                                        i_reason_notes          => l_person.reason_notes,
                                        i_dt_request            => l_dt_request,
                                        i_flg_schedule_via      => l_person.flg_schedule_via,
                                        i_id_prof_notif         => l_person.id_prof_notification,
                                        i_dt_notification       => l_person.dt_notification,
                                        i_flg_notification_via  => l_person.flg_notification_via,
                                        i_flg_request_type      => l_person.flg_request_type,
                                        i_id_episode            => i_id_episode,
                                        i_persons               => i_persons,
                                        i_id_profs_list         => get_ids_profs(i_resources,
                                                                                 l_procedure.id_schedule_procedure),
                                        i_prof_leader           => l_prof_leader,
                                        i_dt_referral           => i_dt_referral,
                                        i_id_schedule_procedure => i_proc_req.id_schedule_procedure,
                                        i_flg_reason_type       => l_person.flg_reason_type,
                                        o_id_schedule           => l_id_schedule,
                                        o_error                 => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_ORIS->CREATE_SCHEDULE_ORIS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            -- backup full schedule
            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || l_id_schedule;
            pk_schedule_common.backup_all(i_id_sch => l_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
        
            g_error := l_func_name || ' - ADD ID TO OUTPUT TABLE';
            o_ids_schedule.extend;
            o_ids_schedule(o_ids_schedule.last) := l_id_schedule;
        
            RETURN TRUE;
        END inner_procedure_oris;
    
        -- tratamento de agendamentos MFR (tipo = PM)
        FUNCTION inner_procedure_mfr(o_error OUT t_error_out) RETURN BOOLEAN IS
            l_id_room           NUMBER := get_id_room(i_resources, i_procedures(l_pivot).id_schedule_procedure);
            o_id_schedule       schedule.id_schedule%TYPE;
            l_rowids            table_varchar;
            i                   PLS_INTEGER;
            k                   PLS_INTEGER;
            l_proc_req          t_procedure_req;
            l_has_resources     BOOLEAN := FALSE;
            l_id_episode_origin episode.id_episode%TYPE;
        BEGIN
        
            -- ciclo principal - persons
            IF i_persons IS NOT NULL
               AND i_persons.count > 0
            THEN
                k := i_persons.first;
                WHILE k IS NOT NULL
                LOOP
                
                    -- get the rehab req id from i_procedure_reqs
                    g_error    := l_func_name || ' - INNER_PROCEDURE_MFR - GET_PROCEDURE_REQ_DATA';
                    l_proc_req := get_procedure_req_data(i_procedure_reqs,
                                                         i_procedures       (l_pivot).id_schedule_procedure,
                                                         i_persons          (k).id_patient,
                                                         g_proc_req_type_req);
                
                    g_error      := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_REQUEST';
                    l_dt_request := i_persons(k).dt_request;
                
                    g_error           := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_NOTIFICATION';
                    l_dt_notification := i_persons(k).dt_notification;
                
                    -- ciclar os profs e rehab groups e agendar para cada um
                    i := i_resources.first;
                    WHILE i IS NOT NULL
                    LOOP
                        IF i_resources.exists(i)
                           AND i_resources(i).id_schedule_procedure = i_procedures(l_pivot).id_schedule_procedure
                           AND i_resources(i).id_resource_type IN (g_res_type_prof, g_res_type_rgroup)
                           AND i_resources(i).id_resource > -1 -- e' um recurso real entao entra...
                        THEN
                            --                            t1 := dbms_utility.get_time;
                        
                            l_has_resources := TRUE;
                        
                            g_error    := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_BEGIN';
                            l_dt_begin := i_resources(i).dt_begin;
                        
                            g_error  := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_END';
                            l_dt_end := i_resources(i).dt_end;
                        
                            g_error       := l_func_name || ' - INNER_PROCEDURE_MFR - CALL CREATE_SCHEDULE_INTERNAL';
                            o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                                      i_prof                 => i_prof,
                                                                      i_id_sch_ext           => i_id_sch_ext,
                                                                      i_id_instit_requests   => i_persons(k).id_instit_requests,
                                                                      i_id_instit_requested  => i_id_instit_requested,
                                                                      i_id_dcs_requests      => i_persons(k).id_dcs_requests,
                                                                      i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                    l_id_dcs),
                                                                      i_id_prof_requests     => i_persons(k).id_prof_requests,
                                                                      i_id_prof_schedules    => i_persons(k).id_prof_schedules,
                                                                      i_flg_status           => i_flg_status,
                                                                      i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                                      i_schedule_notes       => i_persons(k).notes,
                                                                      i_id_lang_preferred    => i_persons(k).id_lang_translator,
                                                                      i_id_reason            => i_persons(k).id_reason,
                                                                      i_id_origin            => i_persons(k).id_origin,
                                                                      i_id_room              => l_id_room,
                                                                      i_flg_notification     => i_persons(k).flg_notification,
                                                                      i_id_schedule_ref      => i_id_sch_ref,
                                                                      i_flg_vacancy          => i_flg_vacancy,
                                                                      i_flg_sch_type         => i_procedures(l_pivot).flg_sch_type,
                                                                      i_reason_notes         => i_persons(k).reason_notes,
                                                                      i_dt_begin             => l_dt_begin,
                                                                      i_dt_end               => l_dt_end,
                                                                      i_dt_request           => l_dt_request,
                                                                      i_flg_schedule_via     => i_persons(k).flg_schedule_via,
                                                                      i_id_prof_notif        => i_persons(k).id_prof_notification,
                                                                      i_dt_notification      => l_dt_notification,
                                                                      i_flg_notification_via => i_persons(k).flg_notification_via,
                                                                      i_flg_request_type     => i_persons(k).flg_request_type,
                                                                      i_id_episode           => i_id_episode,
                                                                      i_id_multidisc         => NULL,
                                                                      i_patients             => t_persons(i_persons(k)),
                                                                      i_ids_profs            => CASE
                                                                                                 i_resources(i).id_resource_type
                                                                                                    WHEN g_res_type_prof THEN
                                                                                                     table_number(i_resources(i).id_resource)
                                                                                                    ELSE
                                                                                                     NULL
                                                                                                END,
                                                                      i_id_prof_leader       => i_resources(i).id_resource,
                                                                      i_id_group             => NULL,
                                                                      i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                                      i_flg_reason_type      => i_persons(k).flg_reason_type,
                                                                      i_video_link           => i_video_link,
                                                                      o_error                => o_error);
                        
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_MFR->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                            -- controlo de erro especifico
                            IF o_id_schedule IS NULL
                               AND o_error IS NOT NULL
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            --                            t1 := dbms_utility.get_time;
                            g_error := l_func_name || ' - INNER_PROCEDURE_MFR - CALL CREATE_SCHEDULE_MFR';
                            IF NOT create_schedule_mfr(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_id_schedule       => o_id_schedule,
                                                       i_id_prof           => CASE i_resources(i).id_resource_type
                                                                                  WHEN g_res_type_prof THEN
                                                                                   i_resources(i).id_resource
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                       i_id_rehab_sch_need => l_proc_req.id,
                                                       i_dt_schedule       => NULL,
                                                       i_id_rehab_group    => CASE i_resources(i).id_resource_type
                                                                                  WHEN g_res_type_rgroup THEN
                                                                                   i_resources(i).id_resource
                                                                                  ELSE
                                                                                   NULL
                                                                              END,
                                                       o_error             => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                        
                            g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                            SELECT DISTINCT rs.id_episode_origin
                              INTO l_id_episode_origin
                              FROM rehab_sch_need rs
                             WHERE rs.id_rehab_sch_need = l_proc_req.id;
                            IF NOT inner_create_episode(i_id_schedule      => o_id_schedule,
                                                        i_id_patient       => l_proc_req.id_patient,
                                                        i_id_dep_clin_serv => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                  l_id_dcs),
                                                        i_flg_rehab        => pk_alert_constant.g_yes,
                                                        i_id_epis_origin   => l_id_episode_origin,
                                                        i_id_rehab_presc   => l_proc_req.id,
                                                        o_id_episode       => l_id_episode_main,
                                                        o_error            => o_error)
                            THEN
                                RETURN FALSE;
                            END IF;
                            -- backup full schedule
                            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' ||
                                       o_id_schedule;
                            pk_schedule_common.backup_all(i_id_sch    => o_id_schedule,
                                                          i_dt_update => NULL,
                                                          i_id_prof_u => NULL);
                        
                            --                            t2 := dbms_utility.get_time;
                            --                            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_MFR->CREATE_SCHEDULE_MFR] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                            --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                        
                        END IF;
                    
                        i := i_resources.next(i);
                    END LOOP;
                
                    -- nao ha profs nem rehab groups. vai usar a i_Dt_begin e i_dt_end
                    IF NOT l_has_resources
                    THEN
                        --                        t1 := dbms_utility.get_time;
                    
                        g_error    := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_BEGIN';
                        l_dt_begin := i_dt_begin;
                    
                        g_error  := l_func_name || ' - INNER_PROCEDURE_MFR - GET DT_END';
                        l_dt_end := i_dt_end;
                    
                        g_error       := l_func_name || ' - INNER_PROCEDURE_MFR - CALL CREATE_SCHEDULE_INTERNAL';
                        o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                                  i_prof                 => i_prof,
                                                                  i_id_sch_ext           => i_id_sch_ext,
                                                                  i_id_instit_requests   => i_persons(k).id_instit_requests,
                                                                  i_id_instit_requested  => i_id_instit_requested,
                                                                  i_id_dcs_requests      => i_persons(k).id_dcs_requests,
                                                                  i_id_dcs_requested     => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                                                l_id_dcs),
                                                                  i_id_prof_requests     => i_persons(k).id_prof_requests,
                                                                  i_id_prof_schedules    => i_persons(k).id_prof_schedules,
                                                                  i_flg_status           => i_flg_status,
                                                                  i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                                  i_schedule_notes       => i_persons(k).notes,
                                                                  i_id_lang_preferred    => i_persons(k).id_lang_translator,
                                                                  i_id_reason            => i_persons(k).id_reason,
                                                                  i_id_origin            => i_persons(k).id_origin,
                                                                  i_id_room              => l_id_room,
                                                                  i_flg_notification     => i_persons(k).flg_notification,
                                                                  i_id_schedule_ref      => i_id_sch_ref,
                                                                  i_flg_vacancy          => i_flg_vacancy,
                                                                  i_flg_sch_type         => i_procedures(l_pivot).flg_sch_type,
                                                                  i_reason_notes         => i_persons(k).reason_notes,
                                                                  i_dt_begin             => l_dt_begin,
                                                                  i_dt_end               => l_dt_end,
                                                                  i_dt_request           => l_dt_request,
                                                                  i_flg_schedule_via     => i_persons(k).flg_schedule_via,
                                                                  i_id_prof_notif        => i_persons(k).id_prof_notification,
                                                                  i_dt_notification      => l_dt_notification,
                                                                  i_flg_notification_via => i_persons(k).flg_notification_via,
                                                                  i_flg_request_type     => i_persons(k).flg_request_type,
                                                                  i_id_episode           => i_id_episode,
                                                                  i_id_multidisc         => NULL,
                                                                  i_patients             => t_persons(i_persons(k)),
                                                                  i_ids_profs            => NULL,
                                                                  i_id_prof_leader       => NULL,
                                                                  i_id_group             => NULL,
                                                                  i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                                  i_flg_reason_type      => i_persons(k).flg_reason_type,
                                                                  o_error                => o_error);
                        --                        t2 := dbms_utility.get_time;
                        --                        pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_MFR NO RESOURCES->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                        --                                              'PK_SCHEDULE_API_DOWNSTREAM', null);
                    
                        -- controlo de erro especifico
                        IF o_id_schedule IS NULL
                           AND o_error IS NOT NULL
                        THEN
                            RETURN FALSE;
                        END IF;
                    
                        --                        t1 := dbms_utility.get_time;
                    
                        g_error := l_func_name || 'INNER_PROCEDURE_MFR - CREATE_SCHEDULE_MFR';
                        IF NOT create_schedule_mfr(i_lang              => i_lang,
                                                   i_prof              => i_prof,
                                                   i_id_schedule       => o_id_schedule,
                                                   i_id_prof           => NULL,
                                                   i_id_rehab_sch_need => l_proc_req.id,
                                                   i_dt_schedule       => NULL,
                                                   i_id_rehab_group    => NULL,
                                                   o_error             => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                        SELECT DISTINCT rs.id_episode_origin
                          INTO l_id_episode_origin
                          FROM rehab_sch_need rs
                         WHERE rs.id_rehab_sch_need = l_proc_req.id;
                    
                        g_error := l_func_name || ' - INNER_CREATE_EPISODE';
                        IF NOT inner_create_episode(i_id_schedule      => o_id_schedule,
                                                    i_id_patient       => l_proc_req.id_patient,
                                                    i_id_dep_clin_serv => nvl(i_procedures(l_pivot).id_dcs_requested,
                                                                              l_id_dcs),
                                                    i_flg_rehab        => pk_alert_constant.g_yes,
                                                    i_id_epis_origin   => l_id_episode_origin,
                                                    i_id_rehab_presc   => l_proc_req.id,
                                                    o_id_episode       => l_id_episode_main,
                                                    o_error            => o_error)
                        THEN
                            RETURN FALSE;
                        END IF;
                        -- backup full schedule
                        g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' ||
                                   o_id_schedule;
                        pk_schedule_common.backup_all(i_id_sch    => o_id_schedule,
                                                      i_dt_update => NULL,
                                                      i_id_prof_u => NULL);
                    
                        --                        t2 := dbms_utility.get_time;
                        --                        pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_MFR NO RESOURCES->CREATE_SCHEDULE_MFR] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                        --                                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
                    END IF;
                
                    k := i_persons.next(k);
                END LOOP;
            END IF;
        
            RETURN TRUE;
        END inner_procedure_mfr;
    
        -- tratamento de agendamentos LAB (tipo = A)
        FUNCTION inner_procedure_lab(o_error OUT t_error_out) RETURN BOOLEAN IS
            l_room             t_resource;
            l_ids_prof         table_number;
            l_prof_lead        t_resource;
            o_id_schedule      schedule.id_schedule%TYPE;
            i                  PLS_INTEGER;
            k                  PLS_INTEGER;
            l_id_dcs_requested NUMBER;
        BEGIN
            -- find the procedure's room. Since pfh schedule table accepts only one, others will be ignored
            g_error := l_func_name || ' - INNER_PROCEDURE_LAB - get room data';
            l_room  := get_first_resource_data(i_resources,
                                               i_procedures(l_pivot).id_schedule_procedure,
                                               g_res_type_room);
        
            -- late-hour validation. Lab scheduler specific
            /*            g_error := 'INNER_PROCEDURE_LAB - validate room id existence';
                        IF l_room.id_resource IS NULL
                        THEN
                            l_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_no_room);
                            RAISE l_invalid_schedule;
                        END IF;
            */
            -- gather prof ids
            g_error    := l_func_name || ' - INNER_PROCEDURE_LAB - get scheduled professional ids';
            l_ids_prof := get_ids_profs(i_resources, i_procedures(l_pivot).id_schedule_procedure);
        
            -- get prof leader id
            g_error     := l_func_name || ' - INNER_PROCEDURE_LAB - get professional leader id';
            l_prof_lead := get_prof_leader(i_resources, i_procedures(l_pivot).id_schedule_procedure);
        
            -- id_dcs_requested. Pick the foist
            IF l_id_dcs_requested IS NULL
            THEN
                g_error := l_func_name || ' -INNER_PROCEDURE_LAB - GET REQUESTED DCS ID';
                -- nao precisa do dcs. mas para respeitar constraint defeita para -1. -1 e' um dcs versionado
                l_id_dcs_requested := nvl(i_procedures(l_pivot).id_dcs_requested, -1);
            END IF;
        
            -- ciclo principal - persons
            IF i_persons IS NOT NULL
               AND i_persons.count > 0
            THEN
                i := i_persons.first;
                WHILE i IS NOT NULL
                LOOP
                    --                    t1 := dbms_utility.get_time;
                
                    g_error    := l_func_name || ' - INNER_PROCEDURE_LAB - GET DT_BEGIN';
                    l_dt_begin := nvl(l_room.dt_begin, i_dt_begin);
                
                    g_error  := l_func_name || ' - INNER_PROCEDURE_LAB - GET DT_END';
                    l_dt_end := nvl(l_room.dt_end, i_dt_end);
                
                    g_error       := l_func_name || ' - INNER_PROCEDURE_LAB - CALL CREATE_SCHEDULE_INTERNAL';
                    o_id_schedule := create_schedule_internal(i_lang                 => i_lang,
                                                              i_prof                 => i_prof,
                                                              i_id_sch_ext           => i_id_sch_ext,
                                                              i_id_instit_requests   => i_persons(i).id_instit_requests,
                                                              i_id_instit_requested  => i_id_instit_requested,
                                                              i_id_dcs_requests      => i_persons(i).id_dcs_requests,
                                                              i_id_dcs_requested     => l_id_dcs_requested,
                                                              i_id_prof_requests     => i_persons(i).id_prof_requests,
                                                              i_id_prof_schedules    => i_persons(i).id_prof_schedules,
                                                              i_flg_status           => i_flg_status,
                                                              i_id_sch_event         => l_id_sch_event_tab(l_pivot),
                                                              i_schedule_notes       => i_persons(i).notes,
                                                              i_id_lang_preferred    => i_persons(i).id_lang_translator,
                                                              i_id_reason            => i_persons(i).id_reason,
                                                              i_id_origin            => i_persons(i).id_origin,
                                                              i_id_room              => l_room.id_resource,
                                                              i_flg_notification     => i_persons(i).flg_notification,
                                                              i_id_schedule_ref      => i_id_sch_ref,
                                                              i_flg_vacancy          => i_flg_vacancy,
                                                              i_flg_sch_type         => i_procedures(l_pivot).flg_sch_type,
                                                              i_reason_notes         => i_persons(i).reason_notes,
                                                              i_dt_begin             => l_dt_begin,
                                                              i_dt_end               => l_dt_end,
                                                              i_dt_request           => i_persons(i).dt_request,
                                                              i_flg_schedule_via     => i_persons(i).flg_schedule_via,
                                                              i_id_prof_notif        => i_persons(i).id_prof_notification,
                                                              i_dt_notification      => l_dt_notification,
                                                              i_flg_notification_via => i_persons(i).flg_notification_via,
                                                              i_flg_request_type     => i_persons(i).flg_request_type,
                                                              i_id_episode           => i_id_episode,
                                                              i_id_multidisc         => NULL,
                                                              i_patients             => t_persons(i_persons(i)),
                                                              i_ids_profs            => l_ids_prof,
                                                              i_id_prof_leader       => l_prof_lead.id_resource,
                                                              i_id_group             => NULL,
                                                              i_id_sch_procedure     => i_procedures(l_pivot).id_schedule_procedure,
                                                              i_flg_reason_type      => i_persons(i).flg_reason_type,
                                                              o_error                => o_error);
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_LAB->CREATE_SCHEDULE_INTERNAL] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    -- controlo de erro especifico
                    IF o_id_schedule IS NULL
                       AND o_error IS NOT NULL
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    --                    t1 := dbms_utility.get_time;
                    -- link this schedule to all lab reqs (id_harvest's) in this procedure
                    g_error := l_func_name || ' - INNER_PROCEDURE_LAB - CALL CREATE_SCHEDULE_LAB';
                    IF NOT create_schedule_lab(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_schedule      => o_id_schedule,
                                               i_procedure_reqs   => i_procedure_reqs,
                                               i_id_sch_procedure => i_procedures(l_pivot).id_schedule_procedure,
                                               i_id_patient       => i_persons(i).id_patient,
                                               i_dt_begin         => l_dt_begin,
                                               o_error            => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    --                    t2 := dbms_utility.get_time;
                    --                    pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER_PROCEDURE_LAB->INSERT INTO SCHEDULE_ANALYSIS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
                    --                                          'PK_SCHEDULE_API_DOWNSTREAM', null);
                
                    -- backup full schedule
                    g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || o_id_schedule;
                    pk_schedule_common.backup_all(i_id_sch => o_id_schedule, i_dt_update => NULL, i_id_prof_u => NULL);
                    i := i_persons.next(i);
                END LOOP;
            END IF;
        
            RETURN TRUE;
        END inner_procedure_lab;
    
    BEGIN
        g_error := 'CREATE_SCHEDULE: i_prof(:' || pk_utils.to_string(i_input => i_prof) || ') i_episode:' ||
                   i_id_episode || ' i_prof_resp:' || i_prof_resp;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, owner => g_package_owner);
    
        --        t1 := dbms_utility.get_time;
    
        customs_inspection(i_lang                => i_lang,
                           i_prof                => i_prof,
                           i_id_sch_ext          => i_id_sch_ext,
                           i_flg_status          => i_flg_status,
                           i_id_instit_requested => i_id_instit_requested,
                           i_id_dep_requested    => i_id_dep_requested,
                           i_procedures          => i_procedures,
                           i_persons             => i_persons,
                           i_resources           => i_resources,
                           i_procedure_reqs      => i_procedure_reqs,
                           o_exists_surg_proc    => l_exists_surg_proc);
    
        o_ids_schedule := table_number();
    
        --        t2 := dbms_utility.get_time;
        --        pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 1 VALIDATION] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
        --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
    
        --        t1 := dbms_utility.get_time;
    
        -- cycle procedures for data extraction
        l_pivot := i_procedures.first;
        WHILE l_pivot IS NOT NULL
        LOOP
            IF i_procedures.exists(l_pivot)
            THEN
            
                -- calc profs number for this procedure
                l_num_profs_tab(l_pivot) := count_profs(i_resources, i_procedures(l_pivot).id_schedule_procedure);
            
                -- get flg_available for exams and other exams
                IF pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type) =
                   pk_schedule_common.g_sch_dept_flg_dep_type_exam
                THEN
                
                    /*                    -- pegar a flg_available do exam e a propria existencia
                                        g_error := l_func_name || ' - GET_EXAM_AVAILABILITY with i_id_content ' || i_procedures(l_pivot).id_content;
                                        get_exam_availability(i_lang       => i_lang,
                                                               i_id_content => i_procedures(l_pivot).id_content,
                                                               o_flg_avail  => l_flg_av,
                                                               o_exists     => l_exists,
                                                               o_trans      => l_desc_trans);
                    */
                    g_error := l_func_name || ' - CALL get_event_from_sch_type with i_sch_type=' || i_procedures(l_pivot).flg_sch_type ||
                               ', i_id_inst=' || i_id_instit_requested || ', i_id_software=' || i_prof.software;
                    l_id_sch_event_tab(l_pivot) := get_event_from_sch_type(i_procedures(l_pivot).flg_sch_type,
                                                                           i_id_instit_requested,
                                                                           i_prof.software);
                
                ELSIF pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type) =
                      pk_schedule_common.g_sch_dept_flg_dep_type_cons
                THEN
                    -- pegar dados do appointment
                    g_error := 'CREATE_SCHEDULE - GET_ID_CONTENT_DATA';
                    get_appointment_data(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_id_appointment => i_procedures(l_pivot).id_content,
                                         i_id_department  => i_id_dep_requested,
                                         o_id_sch_event   => l_id_sch_event_tab(l_pivot),
                                         o_id_dcs         => l_id_dcs,
                                         o_flg_avail      => l_flg_av,
                                         o_exists         => l_exists,
                                         o_trans          => l_desc_trans);
                
                ELSE
                    g_error := l_func_name || ' - CALL get_event_from_sch_type with i_sch_type=' || i_procedures(l_pivot).flg_sch_type ||
                               ', i_id_inst=' || i_id_instit_requested || ', i_id_software=' || i_prof.software;
                    l_id_sch_event_tab(l_pivot) := get_event_from_sch_type(i_procedures(l_pivot).flg_sch_type,
                                                                           i_id_instit_requested,
                                                                           i_prof.software);
                END IF;
            
                -- lets see if its a inp schedule
                l_is_inp_sched := i_procedures(l_pivot).flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp;
            
                -- validate procedure type mixing. Oris type not allowed when mixed with other types
                l_is_surg_sched := l_is_surg_sched AND
                                   (i_procedures(l_pivot).flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_sr);
            
                -- not really a validation. store the main id_schedule_procedure
                IF i_procedures(l_pivot).flg_main_proc = pk_alert_constant.g_yes
                    AND l_id_sch_proc_main IS NULL
                THEN
                    l_id_sch_proc_main := i_procedures(l_pivot).id_schedule_procedure;
                END IF;
            END IF;
            l_pivot := i_procedures.next(l_pivot);
        END LOOP;
    
        --        t2 := dbms_utility.get_time;
        --        pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 2 PROCEDURE VALIDATION] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
        --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
    
        ------------------------
        -- Now it is time for schedule creation. Cycle again the procedures.
        -- Each procedure will start a new schedule, except for Surgery procedures.
        IF l_is_surg_sched
           OR l_is_inp_sched
        THEN
            -- get req data
            g_error := l_func_name || ' - GET PROPER PROCEDURE_REQUEST';
            i       := i_procedure_reqs.first;
            WHILE i IS NOT NULL
            LOOP
                IF i_procedure_reqs.exists(i)
                   AND i_procedure_reqs(i).id IS NOT NULL
                   AND i_procedure_reqs(i).id_type = g_proc_req_type_wl
                THEN
                    l_proc_req := i_procedure_reqs(i);
                END IF;
                i := i_procedure_reqs.next(i);
            END LOOP;
        
            g_error := l_func_name || ' - PROPER PROCEDURE_REQUEST NOT FOUND';
            IF l_proc_req.id_schedule_procedure IS NULL
            THEN
                g_inv_data_msg := pk_message.get_message(i_lang, g_sched_msg_miss_wl_proc_req); --'Surgery/Inpatient appointment - waiting list procedure request is needed';
                RAISE g_invalid_data;
            END IF;
        
            --            t1 := dbms_utility.get_time;
            g_error := l_func_name || ' - CALL INNER_PROCEDURE_ORIS';
            IF l_is_surg_sched
               AND NOT inner_procedure_oris(l_proc_req, o_error)
            THEN
                RAISE l_func_exception;
            END IF;
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER PROCEDURE ORIS] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            --            t1 := dbms_utility.get_time;
            g_error := l_func_name || ' - CALL INNER_PROCEDURE_INP';
            IF l_is_inp_sched
               AND NOT inner_procedure_inp(l_proc_req, o_error)
            THEN
                RAISE l_func_exception;
            END IF;
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 3 INNER PROCEDURE INP] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
        
        ELSE
            -- criar o main procedure primeiro. Assume-se que so' ha' um
            l_pivot := i_procedures.first;
            WHILE l_pivot IS NOT NULL
            LOOP
                IF i_procedures.exists(l_pivot)
                   AND i_procedures(l_pivot).id_schedule_procedure = nvl(l_id_sch_proc_main, -199)
                THEN
                    g_error := l_func_name || ' - FORK FLG_SCH_TYPE GROUP - CREATE MAIN PROCEDURE';
                    CASE pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type)
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_cons THEN
                            l_retval := inner_procedure_outp(o_error);
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_exam THEN
                            -- em vez de chamar a inner_procedure_exam reune os procedures de exames
                            l_exam_procs.extend;
                            l_exam_procs(l_exam_procs.last) := l_pivot;
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_oexams THEN
                            -- em vez de chamar a inner_procedure_exam reune os procedures de outros exames
                            l_oexam_procs.extend;
                            l_oexam_procs(l_oexam_procs.last) := l_pivot;
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_pm THEN
                            l_retval := inner_procedure_mfr(o_error);
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_anls THEN
                            l_retval := inner_procedure_lab(o_error);
                        ELSE
                            -- se entrou aqui e' porque nao e' reconhecido
                            l_retval := TRUE;
                    END CASE;
                
                    IF NOT l_retval
                    THEN
                        RAISE l_func_exception;
                    END IF;
                
                END IF;
                l_pivot := i_procedures.next(l_pivot);
            END LOOP;
        
            -- criar a descendencia e orfaos
            l_pivot := i_procedures.first;
            WHILE l_pivot IS NOT NULL
            LOOP
                IF i_procedures.exists(l_pivot)
                   AND i_procedures(l_pivot).id_schedule_procedure <> nvl(l_id_sch_proc_main, -199)
                THEN
                    g_error := l_func_name || ' - FORK FLG_SCH_TYPE GROUP';
                    CASE pk_schedule_common.get_dep_type_group(i_procedures(l_pivot).flg_sch_type)
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_cons THEN
                            l_retval := inner_procedure_outp(o_error);
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_exam THEN
                            -- em vez de chamar a inner_procedure_exam reune os procedures de exames
                            l_exam_procs.extend;
                            l_exam_procs(l_exam_procs.last) := l_pivot;
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_oexams THEN
                            -- em vez de chamar a inner_procedure_exam reune os procedures de outros exames
                            l_oexam_procs.extend;
                            l_oexam_procs(l_oexam_procs.last) := l_pivot;
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_pm THEN
                            l_retval := inner_procedure_mfr(o_error);
                        WHEN pk_schedule_common.g_sch_dept_flg_dep_type_anls THEN
                            l_retval := inner_procedure_lab(o_error);
                        ELSE
                            -- se entrou aqui e' porque nao e' reconhecido
                            l_retval := TRUE;
                    END CASE;
                
                    IF NOT l_retval
                    THEN
                        RAISE l_func_exception;
                    END IF;
                
                END IF;
                l_pivot := i_procedures.next(l_pivot);
            END LOOP;
        
            -- processar agora todos os procedures de exames
            --            t1 := dbms_utility.get_time;
            IF NOT inner_procedure_exam(l_exam_procs, o_error)
            THEN
                RAISE l_func_exception;
            END IF;
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 4 INNER PROCEDURE EXAM] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
            -- processar agora todos os procedures de outros exames
            --            t1 := dbms_utility.get_time;
            IF NOT inner_procedure_exam(l_oexam_procs, o_error)
            THEN
                RAISE l_func_exception;
            END IF;
            --            t2 := dbms_utility.get_time;
            --            pk_alertlog.log_debug('CREATE_SCHEDULE [STEP 4 INNER PROCEDURE OTHER EXAM] ext.id= ' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
            --                                  'PK_SCHEDULE_API_DOWNSTREAM', null);
        
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_func_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_invalid_data THEN
            l_retval := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                           i_func_proc_name => l_func_name,
                                                           i_package_name   => g_package_name,
                                                           i_package_error  => 5550,
                                                           i_sql_error      => g_inv_data_msg,
                                                           i_log_on         => TRUE,
                                                           o_error          => l_dummy);
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 5550,
                                   ora_sqlerrm         => g_inv_data_msg,
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN g_invalid_schedule THEN
            l_retval := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                           i_func_proc_name => l_func_name,
                                                           i_package_name   => g_package_name,
                                                           i_package_error  => 6660,
                                                           i_sql_error      => g_inv_data_msg,
                                                           i_log_on         => TRUE,
                                                           o_error          => l_dummy);
        
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 6660,
                                   ora_sqlerrm         => g_inv_data_msg,
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_schedule;

    /*
    *  este cancel_schedule e' a mula de carga - aqui se processa efectivamente um cancelamento.
    * Recebe um id_schedule local (pfh)
    */
    FUNCTION cancel_schedule_internal
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date      IN schedule.dt_cancel_tstz%TYPE,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_updating         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_referral      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_referral_reason  IN p1_reason_code.id_reason_code%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := $$PLSQL_UNIT;
        l_func_exception      EXCEPTION;
        l_req_exception       EXCEPTION;
        l_no_proceed          EXCEPTION;
        l_rowids              table_varchar := table_varchar();
        l_id_external_request p1_external_request.id_external_request%TYPE;
    
        l_sch_row    schedule%ROWTYPE;
        l_sch_sr_row schedule_sr%ROWTYPE;
    
        l_id_wl        schedule_bed.id_waiting_list%TYPE;
        l_id_bed       schedule_bed.id_bed%TYPE;
        l_flg_conflict schedule_bed.flg_conflict%TYPE;
    
        l_id_patient          patient.id_patient%TYPE;
        i                     PLS_INTEGER;
        l_cat_flg_type        category.flg_type%TYPE;
        l_flg_show            VARCHAR2(200);
        l_msg_req             VARCHAR2(200);
        l_msg_result          VARCHAR2(200);
        l_msg_title           VARCHAR2(200);
        l_id_exam_req         schedule_exam.id_exam_req%TYPE;
        l_proceed             VARCHAR2(1);
        l_ids_rs              table_number;
        l_ids_sch_need        table_number;
        saer                  sys_alert_event%ROWTYPE;
        l_cat                 profile_template.id_category%TYPE;
        l_row_consult_req     consult_req%ROWTYPE;
        l_id_consult_req_hist consult_req_hist.id_consult_req_hist%TYPE;
        l_dummy_tv            table_varchar;
        l_id_episode          episode.id_episode%TYPE;
        l_transaction_id      VARCHAR2(4000);
        l_desc_cancel_reason  episode.desc_cancel_reason%TYPE;
        l_count_records       NUMBER(24);
    
        CURSOR c_idexamreq(id_sch schedule_exam.id_schedule%TYPE) IS
            SELECT se.id_exam_req
              FROM schedule_exam se
              JOIN exam_req er
                ON se.id_exam_req = er.id_exam_req
             WHERE se.id_schedule = id_sch
               AND er.flg_time = pk_exam_constant.g_flg_time_e
               AND er.id_episode IS NULL
               AND er.flg_status <> pk_exam_constant.g_exam_cancel; -- ALERT-224382
    
        CURSOR c_idexamreq_type_b(id_sch schedule_exam.id_schedule%TYPE) IS
            SELECT se.id_exam_req
              FROM schedule_exam se
              JOIN exam_req er
                ON se.id_exam_req = er.id_exam_req
             WHERE se.id_schedule = id_sch
               AND er.flg_time <> pk_exam_constant.g_flg_time_e
               AND er.id_episode IS NULL
               AND er.flg_status <> pk_exam_constant.g_exam_cancel; -- ALERT-224382
    BEGIN
    
        -- Alter the schedule
        g_error                         := l_func_name || ' - TS_SCHEDULE.UPD';
        l_sch_row.id_schedule           := i_id_schedule;
        l_sch_row.flg_status            := pk_schedule.g_sched_status_cancelled;
        l_sch_row.id_prof_cancel        := i_id_professional;
        l_sch_row.id_cancel_reason      := i_id_cancel_reason;
        l_sch_row.schedule_cancel_notes := i_cancel_notes;
        l_sch_row.dt_cancel_tstz        := nvl(i_cancel_date, current_timestamp);
        ts_schedule.upd(rec_in => l_sch_row, handle_error_in => FALSE);
    
        --get sch type
        g_error := l_func_name || ' - GET flg_sch_type';
        SELECT flg_sch_type
          INTO l_sch_row.flg_sch_type
          FROM schedule
         WHERE id_schedule = i_id_schedule;
    
        -- cancel episode
        BEGIN
            SELECT e.id_episode, e.desc_cancel_reason
              INTO l_id_episode, l_desc_cancel_reason
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
             WHERE ei.id_schedule = i_id_schedule
               AND e.flg_status = pk_schedule.g_episode_active
                  --ALERT-320523 INP & ORIS episode can't be cancelled by the scheduler
               AND e.id_epis_type NOT IN
                   (pk_alert_constant.g_epis_type_inpatient, pk_alert_constant.g_epis_type_operating)
               AND e.flg_ehr = pk_schedule.g_schedule_ehr
               AND rownum = 1;
        
            g_error          := l_func_name || ' - CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
            l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
        
            g_error := l_func_name || ' - call PK_VISIT.CALL_CANCEL_EPISODE';
            IF NOT pk_visit.call_cancel_episode(i_lang           => i_lang,
                                                i_id_episode     => l_id_episode,
                                                i_prof           => i_prof,
                                                i_cancel_reason  => substr(l_desc_cancel_reason || nvl(i_cancel_notes, ''),
                                                                           1,
                                                                           4000),
                                                i_cancel_type    => 'S',
                                                i_dt_cancel      => nvl(i_cancel_date, current_timestamp),
                                                i_transaction_id => l_transaction_id,
                                                i_goto_sch       => FALSE,
                                                o_error          => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL; -- no episode, no harm 
        END;
    
        /*        
                g_error := l_func_name || ' - PK_SCHEDULE.CANCEL_SCH_EPIS_EHR';
                IF NOT pk_schedule.cancel_sch_epis_ehr(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_id_schedule  => i_id_schedule,
                                                       i_sysdate      => i_cancel_date,
                                                       i_sysdate_tstz => nvl(i_cancel_date, g_sysdate_tstz),
                                                       o_error        => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
        */
    
        BEGIN
            -- returns id_external_request associated to i_id_schedule
            g_error := l_func_name || ' - PK_REF_EXT_SYS.GET_REFERRAL_ID with id_schedule=' || i_id_schedule;
            IF NOT pk_ref_ext_sys.get_referral_id(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_schedule         => i_id_schedule,
                                                  o_id_external_request => l_id_external_request,
                                                  o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF l_id_external_request IS NOT NULL
            THEN
                g_error := l_func_name || ' - PK_REF_EXT_SYS.CANCEL_REF_SCHEDULE WITH ID_EXTERNAL_REQUEST = ' ||
                           l_id_external_request;
                IF NOT pk_ref_ext_sys.cancel_ref_schedule(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_id_ref         => l_id_external_request,
                                                          i_schedule       => i_id_schedule,
                                                          i_notes          => i_cancel_notes,
                                                          i_date           => coalesce(i_dt_referral,
                                                                                       i_cancel_date,
                                                                                       current_timestamp),
                                                          i_id_reason_code => i_referral_reason,
                                                          o_error          => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        END;
    
        -- cancel requisition IF this is a pure cancelation
        IF nvl(i_updating, pk_alert_constant.g_no) = pk_alert_constant.g_no
        THEN
            BEGIN
                g_error := l_func_name || ' - GET consult_req row';
                SELECT r.*
                  INTO l_row_consult_req
                  FROM consult_req r
                 WHERE r.id_schedule = i_id_schedule;
            EXCEPTION
                WHEN no_data_found THEN
                    l_row_consult_req.id_consult_req := NULL;
            END;
        
            IF l_row_consult_req.id_consult_req IS NOT NULL
            THEN
                g_error := l_func_name || ' - TS_CONSULT_REQ_HIST.INS';
                ts_consult_req_hist.ins(id_consult_req_in        => l_row_consult_req.id_consult_req,
                                        consult_type_in          => l_row_consult_req.consult_type,
                                        id_clinical_service_in   => l_row_consult_req.id_clinical_service,
                                        id_patient_in            => l_row_consult_req.id_patient,
                                        id_instit_requests_in    => l_row_consult_req.id_instit_requests,
                                        id_inst_requested_in     => l_row_consult_req.id_instit_requests,
                                        id_episode_in            => l_row_consult_req.id_episode,
                                        id_prof_req_in           => l_row_consult_req.id_prof_req,
                                        id_prof_auth_in          => l_row_consult_req.id_prof_auth,
                                        id_prof_appr_in          => l_row_consult_req.id_prof_appr,
                                        id_prof_proc_in          => l_row_consult_req.id_prof_proc,
                                        notes_in                 => l_row_consult_req.notes,
                                        id_prof_cancel_in        => l_row_consult_req.id_prof_cancel,
                                        notes_cancel_in          => l_row_consult_req.notes_cancel,
                                        id_dep_clin_serv_in      => l_row_consult_req.id_dep_clin_serv,
                                        id_prof_requested_in     => l_row_consult_req.id_prof_requested,
                                        flg_status_in            => l_row_consult_req.flg_status,
                                        notes_admin_in           => l_row_consult_req.notes_admin,
                                        id_schedule_in           => l_row_consult_req.id_schedule,
                                        dt_consult_req_tstz_in   => l_row_consult_req.dt_consult_req_tstz,
                                        dt_scheduled_tstz_in     => l_row_consult_req.dt_scheduled_tstz,
                                        dt_cancel_tstz_in        => l_row_consult_req.dt_cancel_tstz,
                                        next_visit_in_notes_in   => l_row_consult_req.next_visit_in_notes,
                                        flg_instructions_in      => l_row_consult_req.flg_instructions,
                                        id_complaint_in          => l_row_consult_req.id_complaint,
                                        flg_type_date_in         => l_row_consult_req.flg_type_date,
                                        status_flg_in            => l_row_consult_req.status_flg,
                                        status_icon_in           => l_row_consult_req.status_icon,
                                        status_msg_in            => l_row_consult_req.status_msg,
                                        status_str_in            => l_row_consult_req.status_str,
                                        reason_for_visit_in      => l_row_consult_req.reason_for_visit,
                                        create_user_in           => NULL,
                                        create_time_in           => NULL,
                                        create_institution_in    => NULL,
                                        update_user_in           => NULL,
                                        update_time_in           => NULL,
                                        update_institution_in    => NULL,
                                        flg_type_in              => l_row_consult_req.flg_type,
                                        id_cancel_reason_in      => l_row_consult_req.id_cancel_reason,
                                        id_epis_documentation_in => l_row_consult_req.id_epis_documentation,
                                        id_epis_type_in          => l_row_consult_req.id_epis_type,
                                        dt_last_update_in        => l_row_consult_req.dt_last_update,
                                        id_prof_last_update_in   => l_row_consult_req.id_prof_last_update,
                                        id_inst_last_update_in   => l_row_consult_req.id_inst_last_update,
                                        id_sch_event_in          => l_row_consult_req.id_sch_event,
                                        dt_begin_event_in        => l_row_consult_req.dt_begin_event,
                                        dt_end_event_in          => l_row_consult_req.dt_end_event,
                                        flg_priority_in          => l_row_consult_req.flg_priority,
                                        flg_contact_type_in      => l_row_consult_req.flg_contact_type,
                                        instructions_in          => l_row_consult_req.instructions,
                                        id_room_in               => l_row_consult_req.id_room,
                                        flg_request_type_in      => l_row_consult_req.flg_request_type,
                                        flg_req_resp_in          => l_row_consult_req.flg_req_resp,
                                        request_reason_in        => l_row_consult_req.request_reason,
                                        id_language_in           => l_row_consult_req.id_language,
                                        flg_recurrence_in        => l_row_consult_req.flg_recurrence,
                                        frequency_in             => l_row_consult_req.frequency,
                                        dt_rec_begin_in          => l_row_consult_req.dt_rec_begin,
                                        dt_rec_end_in            => l_row_consult_req.dt_rec_end,
                                        nr_events_in             => l_row_consult_req.nr_events,
                                        week_day_in              => l_row_consult_req.week_day,
                                        week_nr_in               => l_row_consult_req.week_nr,
                                        month_day_in             => l_row_consult_req.month_day,
                                        month_nr_in              => l_row_consult_req.month_nr,
                                        id_soft_reg_by_in        => l_row_consult_req.id_soft_reg_by,
                                        id_consult_req_hist_out  => l_id_consult_req_hist,
                                        handle_error_in          => TRUE,
                                        rows_out                 => l_dummy_tv);
            
                g_error := l_func_name || ' - TS_CONSULT_REQ.UPD';
                ts_consult_req.upd(id_consult_req_in => l_row_consult_req.id_consult_req,
                                   flg_status_in     => 'P',
                                   id_schedule_in    => NULL,
                                   id_schedule_nin   => FALSE,
                                   dt_last_update_in => current_timestamp,
                                   rows_out          => l_rowids);
            
                g_error := l_func_name || ' - T_DATA_GOV_MNT.PROCESS_UPDATE';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'CONSULT_REQ',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            END IF;
        END IF;
    
        -- codigo especifico da agenda inpatient
        IF l_sch_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
        THEN
            g_error := l_func_name || ' - GET WL ID';
            SELECT sb.id_waiting_list, sb.id_bed, sb.flg_conflict
              INTO l_id_wl, l_id_bed, l_flg_conflict
              FROM schedule_bed sb
             WHERE sb.id_schedule = i_id_schedule;
        
            g_error := l_func_name || ' - PK_WTL_PBL_CORE.CANCEL_SCHEDULE';
            IF NOT pk_wtl_pbl_core.cancel_schedule(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_wtlist   => l_id_wl,
                                                   i_id_schedule => i_id_schedule,
                                                   o_error       => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        END IF;
    
        -- codigo especifico da agenda oris
        IF l_sch_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_sr
        THEN
            BEGIN
                -- get schedule data
                g_error := l_func_name || ' - GET schedule_sr data with i_id_schedule=' || i_id_schedule;
                SELECT ssr.id_waiting_list, ssr.id_schedule_sr
                  INTO l_id_wl, l_sch_sr_row.id_schedule_sr
                  FROM schedule s
                  JOIN schedule_sr ssr
                    ON s.id_schedule = ssr.id_schedule
                 WHERE s.id_schedule = i_id_schedule;
            
                -- update WTL stuff
                g_error := l_func_name || ' - PK_WTL_PBL_CORE.CANCEL_SCHEDULE';
                IF NOT pk_wtl_pbl_core.cancel_schedule(i_lang        => i_lang,
                                                       i_prof        => i_prof,
                                                       i_id_wtlist   => l_id_wl,
                                                       i_id_schedule => i_id_schedule,
                                                       o_error       => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                -- update schedule_sr 
                g_error                     := l_func_name || ' - TS_SCHEDULE_SR.UPD';
                l_sch_sr_row.id_prof_cancel := i_id_professional;
                l_sch_sr_row.notes_cancel   := i_cancel_notes;
                l_sch_sr_row.dt_cancel_tstz := nvl(i_cancel_date, g_sysdate_tstz);
                l_sch_sr_row.flg_status     := pk_schedule.g_sched_status_cancelled;
                ts_schedule_sr.upd(rec_in => l_sch_sr_row, handle_error_in => TRUE, rows_out => l_rowids);
            
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => NULL,
                                              i_table_name   => 'SCHEDULE_SR',
                                              i_rowids       => l_rowids,
                                              o_error        => o_error,
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_CANCEL',
                                                                              'NOTES_CANCEL',
                                                                              'DT_CANCEL_TSTZ'));
            
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        END IF;
    
        -- codigo especifico da agenda mfr
        IF l_sch_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
        THEN
        
            SELECT COUNT(*)
              INTO l_count_records
              FROM rehab_schedule rs
             WHERE rs.id_schedule = i_id_schedule
               AND rs.flg_status = 'A';
        
            IF l_count_records > 0
            THEN
                -- fetch rehab_schedule pk
                g_error := l_func_name || ' - GET REHAB_SCHEDULE PK VALUE';
                SELECT id_rehab_schedule, rs.id_rehab_sch_need
                  BULK COLLECT
                  INTO l_ids_rs, l_ids_sch_need
                  FROM rehab_schedule rs
                 WHERE rs.id_schedule = i_id_schedule;
            
                g_error := l_func_name || ' - CANCEL ALL rehab_schedule rows';
                i       := l_ids_rs.first;
                WHILE i IS NOT NULL
                LOOP
                    ts_rehab_schedule.upd(id_rehab_schedule_in => l_ids_rs(i),
                                          flg_status_in        => pk_rehab.g_rehab_schedule_cancel,
                                          handle_error_in      => FALSE);
                    i := l_ids_rs.next(i);
                END LOOP;
            
                BEGIN
                    IF l_ids_sch_need IS NOT NULL
                       AND l_ids_sch_need.count > 0
                    THEN
                        FOR i IN 1 .. l_ids_sch_need.count
                        LOOP
                            IF l_ids_sch_need(i) IS NOT NULL
                            THEN
                                ts_rehab_sch_need.upd(id_rehab_sch_need_in => l_ids_sch_need(i),
                                                      flg_status_in        => pk_rehab.g_rehab_sch_need_wait_sch,
                                                      handle_error_in      => FALSE);
                            END IF;
                        END LOOP;
                    
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
            ELSE
                -- fetch sch_rehab_group pk
                g_error := l_func_name || ' - GET REHAB_SCHEDULE_GROUP PK VALUE';
                SELECT rsg.id_rehab_group
                  BULK COLLECT
                  INTO l_ids_rs
                  FROM sch_rehab_group rsg
                 WHERE rsg.id_schedule = i_id_schedule;
            
                g_error := l_func_name || ' - CANCEL ALL rehab_schedule_group rows';
                i       := l_ids_rs.first;
                WHILE i IS NOT NULL
                LOOP
                    l_rowids := table_varchar();
                    ts_sch_rehab_group.upd(id_rehab_group_in      => l_ids_rs(i),
                                           id_schedule_in         => i_id_schedule,
                                           create_user_in         => NULL,
                                           create_user_nin        => TRUE,
                                           create_time_in         => NULL,
                                           create_time_nin        => TRUE,
                                           create_institution_in  => NULL,
                                           create_institution_nin => TRUE,
                                           update_user_in         => NULL,
                                           update_user_nin        => TRUE,
                                           update_time_in         => NULL,
                                           update_time_nin        => TRUE,
                                           update_institution_in  => NULL,
                                           update_institution_nin => TRUE,
                                           id_rehab_sch_need_in   => NULL,
                                           id_rehab_sch_need_nin  => TRUE,
                                           flg_status_in          => pk_rehab.g_rehab_schedule_cancel,
                                           flg_status_nin         => TRUE,
                                           handle_error_in        => FALSE,
                                           rows_out               => l_rowids);
                    i := l_ids_rs.next(i);
                END LOOP;
            END IF;
        END IF;
    
        -- codigo especifico da agenda exames e outros exames
        IF l_sch_row.flg_sch_type IN
           (pk_schedule_common.g_sch_dept_flg_dep_type_exam, pk_schedule_common.g_sch_dept_flg_dep_type_oexams)
           AND i_cancel_exam_req = pk_alert_constant.g_yes
        THEN
        
            -- check if we can cancel these schedules
            g_error := l_func_name || ' - CALL GET_REQS_STATUS';
            IF NOT pk_schedule_exam.get_reqs_status(i_lang, i_prof, i_id_schedule, l_proceed, o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF l_proceed = pk_alert_constant.g_no
            THEN
                RAISE l_no_proceed;
            END IF;
        
            -- cancelar a requisicao do exame caso seja do tipo E.
            -- o cursor impoe essa regra. As do tipo E sao as reqs criadas pela integracao (ver a create_schedule_exam)
            OPEN c_idexamreq(i_id_schedule);
            LOOP
                FETCH c_idexamreq
                    INTO l_id_exam_req;
                EXIT WHEN c_idexamreq%NOTFOUND;
            
                IF l_id_exam_req IS NOT NULL
                THEN
                    -- data needed for the job
                    g_error := l_func_name || ' - GET CATEGORY.FLG_TYPE';
                    SELECT cat.flg_type
                      INTO l_cat_flg_type
                      FROM category cat, prof_cat pc
                     WHERE pc.id_professional = i_prof.id
                       AND pc.id_institution = i_prof.institution
                       AND cat.id_category = pc.id_category;
                
                    -- cancel exam req
                    g_error := l_func_name || ' - CALL PK_EXAMS_API_DB.CANCEL_EXAM_REQ';
                    IF NOT pk_exams_api_db.cancel_exam_order(i_lang           => i_lang,
                                                             i_prof           => i_prof,
                                                             i_exam_req       => table_number(l_id_exam_req),
                                                             i_cancel_reason  => NULL,
                                                             i_cancel_notes   => i_cancel_notes,
                                                             i_prof_order     => NULL,
                                                             i_dt_order       => NULL,
                                                             i_order_type     => NULL,
                                                             i_flg_schedule   => pk_alert_constant.g_no,
                                                             i_transaction_id => l_transaction_id,
                                                             o_error          => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                END IF;
            
                IF l_flg_show = pk_alert_constant.g_yes
                THEN
                    RAISE l_req_exception;
                END IF;
            END LOOP;
            CLOSE c_idexamreq;
        
            -- a seguir trata das requisicoes que nao sao do tipo E.
            -- nestas muda-se o estado de volta para 'por agendar' e limpa-se a data agendada
            g_error := l_func_name || ' - PROCESS TYPE B EXAM REQS';
            OPEN c_idexamreq_type_b(i_id_schedule);
            LOOP
                FETCH c_idexamreq_type_b
                    INTO l_id_exam_req;
                EXIT WHEN c_idexamreq_type_b%NOTFOUND;
            
                IF NOT pk_exams_api_db.cancel_exam_schedule(i_lang     => i_lang,
                                                            i_prof     => i_prof,
                                                            i_exam_req => l_id_exam_req,
                                                            o_error    => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            END LOOP;
            CLOSE c_idexamreq_type_b;
        END IF;
    
        -- codigo especifico da agenda lab
        IF l_sch_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_anls
        THEN
        
            -- cancelar requisicao: obter todos os req_dets
            DECLARE
                l_ids_req table_number;
            BEGIN
                g_error := l_func_name || ' - GET COLLECTION OF id_analysis_req_det FOR id_schedule=' || i_id_schedule;
                SELECT sa.id_analysis_req
                  BULK COLLECT
                  INTO l_ids_req
                  FROM analysis_req r
                  JOIN schedule_analysis sa
                    ON r.id_analysis_req = sa.id_analysis_req
                 WHERE sa.id_schedule = i_id_schedule
                   AND r.id_episode IS NULL;
            
                -- cancelar requisicao: uma a uma as que estao associadas ao agendamento
                FOR indx IN 1 .. l_ids_req.count
                LOOP
                    IF NOT pk_lab_tests_core.cancel_lab_test_schedule(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_analysis_req => l_ids_req(indx),
                                                                      o_error        => o_error)
                    THEN
                        RAISE l_func_exception;
                    END IF;
                END LOOP;
            END;
        END IF;
    
        -- gerar alerta se for um cancelamento puro
        IF nvl(i_updating, pk_alert_constant.g_no) = pk_alert_constant.g_no
        THEN
            -- find the cancelation prof current profile category
            g_error := l_func_name || ' - FIND THE CANCELATION PROF CURRENT PROFILE CATEGORY';
            BEGIN
                SELECT nvl(pt.id_category, -1)
                  INTO l_cat
                  FROM prof_profile_template ppt
                  JOIN profile_template pt
                    ON ppt.id_profile_template = pt.id_profile_template
                 WHERE ppt.id_professional = i_prof.id
                   AND ppt.id_software = i_prof.software
                   AND ppt.id_institution = i_prof.institution
                   AND pt.flg_available = pk_alert_constant.g_yes
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_cat := -1;
            END;
        
            -- proceed only if this is not a registrar
            IF l_cat <> 4
            THEN
                -- find patient first
                IF l_id_patient IS NULL
                THEN
                    BEGIN
                        g_error := l_func_name || ' - FIND PATIENT ID FOR ALERT CREATION id_sch_pfh=' || i_id_schedule;
                        SELECT id_patient
                          INTO l_id_patient
                          FROM sch_group sg
                         WHERE sg.id_schedule = i_id_schedule
                           AND sg.id_cancel_reason IS NULL
                           AND rownum = 1;
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END IF;
            
                IF l_id_patient IS NOT NULL
                THEN
                    -- prepare alert data
                    saer.id_sys_alert   := g_id_sys_alert_cancel;
                    saer.id_software    := i_prof.software;
                    saer.id_institution := i_prof.institution;
                    saer.id_patient     := l_id_patient;
                    saer.id_record      := i_id_schedule;
                    saer.dt_record      := nvl(i_cancel_date, g_sysdate_tstz);
                    saer.flg_visible    := 'Y';
                    saer.id_visit       := -1;
                    saer.id_episode     := -1;
                
                    g_error := l_func_name || ' - INSERT ALERT EVENT. id_sys_alert=' || saer.id_sys_alert ||
                               ', id_software=' || saer.id_software || ', id_institution=' || saer.id_institution ||
                               ', id_patient=' || saer.id_patient || ', id_record=' || saer.id_record;
                    IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => saer,
                                                            o_error           => o_error)
                    THEN
                        -- optei por nao lancar excepcao para nao comprometer o cancelamento
                        pk_alertlog.log_error(text        => g_error || ' failed. cause=' || o_error.ora_sqlerrm,
                                              object_name => g_package_name,
                                              owner       => g_package_owner);
                    END IF;
                END IF;
            END IF;
        END IF;
    
        -- backup full schedule
        g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || i_id_schedule;
        pk_schedule_common.backup_all(i_id_sch    => i_id_schedule,
                                      i_dt_update => current_timestamp,
                                      i_id_prof_u => i_prof.id);
    
        IF l_transaction_id IS NOT NULL
        THEN
            pk_schedule_api_upstream.do_commit(i_id_transaction => l_transaction_id, i_prof => i_prof);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_req_exception THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20005,
                                              i_sqlerrm  => l_msg_req,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN l_no_proceed THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20004,
                                              i_sqlerrm  => 'O estado da requisição do agendamento ' || i_id_schedule ||
                                                            ' não permite o seu cancelamento',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(i_id_transaction => l_transaction_id, i_prof => i_prof);
            RETURN FALSE;
    END cancel_schedule_internal;

    /*
    * cancel_schedule principal. Usado pelo intf_alert para cancelamentos vindos do scheduler 3
    */
    FUNCTION cancel_schedule
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN NUMBER,
        i_ids_patient      IN table_number,
        i_id_professional  IN professional.id_professional%TYPE,
        i_id_cancel_reason IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes     IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date      IN schedule.dt_cancel_tstz%TYPE,
        i_cancel_exam_req  IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_updating         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_referral      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := $$PLSQL_UNIT;
        l_func_exception EXCEPTION;
        l_no_pfh_id      EXCEPTION;
        l_ids_sch_pfh    table_number;
        i                PLS_INTEGER;
        --        t1                 NUMBER;
        --        t2                 NUMBER;
    BEGIN
    
        --        t1 := dbms_utility.get_time;
    
        -- get internal ids
        g_error := l_func_name || ' - GET PFH IDS. i_id_sch_ext=' || i_id_sch_ext || ', i_ids_patient=' ||
                   pk_utils.concat_table(i_ids_patient, ',');
        IF NOT get_pfh_ids(i_lang        => i_lang,
                           i_prof        => i_prof,
                           i_id_sch_ext  => i_id_sch_ext,
                           i_ids_patient => i_ids_patient,
                           o_result      => l_ids_sch_pfh,
                           o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF nvl(cardinality(l_ids_sch_pfh), 0) = 0
        THEN
            RAISE l_no_pfh_id;
        END IF;
    
        i := l_ids_sch_pfh.first;
        WHILE i IS NOT NULL
        LOOP
            g_error := l_func_name || ' - CALL CANCEL_SCHEDULE_INTERNAL WITH i_id_schedule= ' || l_ids_sch_pfh(i);
            IF NOT cancel_schedule_internal(i_lang             => i_lang,
                                            i_prof             => i_prof,
                                            i_id_schedule      => l_ids_sch_pfh(i),
                                            i_id_professional  => i_id_professional,
                                            i_id_cancel_reason => i_id_cancel_reason,
                                            i_cancel_notes     => i_cancel_notes,
                                            i_cancel_date      => i_cancel_date,
                                            i_cancel_exam_req  => i_cancel_exam_req,
                                            i_updating         => i_updating,
                                            i_dt_referral      => i_dt_referral,
                                            o_error            => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- virou
            i := l_ids_sch_pfh.next(i);
        END LOOP;
    
        --        t2 := dbms_utility.get_time;
        --        pk_alertlog.log_debug('CANCEL_SCHEDULE ext.id=' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
        --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_schedule;

    --***********************************************************
    -- generate_hhc_alerts ( i_lang => i_lang, i_prof => i_prof, i_id_schedule => l_schedule_rows(1).id_schedule );
    FUNCTION generate_hhc_alerts
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER,
        i_flg_status  IN VARCHAR2
    ) RETURN BOOLEAN IS
        l_id_sys_alert     NUMBER;
        l_id_sys_alert_del NUMBER;
        l_bool             BOOLEAN := TRUE;
        l_error            t_error_out;
    BEGIN
    
        --****************** Alertas for HHC
        CASE i_flg_status
            WHEN pk_schedule.g_sched_status_scheduled THEN
                l_id_sys_alert     := k_alert_hhc_approve_sched;
                l_id_sys_alert_del := k_alert_hhc_undo_sched;
            WHEN pk_schedule.g_sched_status_pend_approval THEN
                l_id_sys_alert     := k_alert_hhc_undo_sched;
                l_id_sys_alert_del := k_alert_hhc_approve_sched;
            ELSE
                l_id_sys_alert     := NULL;
                l_id_sys_alert_del := NULL;
        END CASE;
    
        IF l_id_sys_alert IS NOT NULL
        THEN
        
            l_bool := create_alert_event(i_lang             => i_lang,
                                         i_prof             => i_prof,
                                         i_id_sys_alert     => l_id_sys_alert,
                                         i_id_sys_alert_del => l_id_sys_alert_del,
                                         i_id_schedule      => i_id_schedule,
                                         o_error            => l_error);
        
        END IF;
    
        RETURN l_bool;
    
    END generate_hhc_alerts;

    /*
    *
    */
    FUNCTION update_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sch_ext          IN NUMBER,
        i_flg_status          IN schedule.flg_status%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_id_cancel_reason    IN sch_cancel_reason.id_sch_cancel_reason%TYPE,
        i_cancel_notes        IN schedule.schedule_cancel_notes%TYPE,
        i_cancel_date         IN VARCHAR2,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := 'UPDATE_SCHEDULE';
        l_func_exception EXCEPTION;
        l_no_pfh_id      EXCEPTION;
        l_pfh_rows       t_sch_api_map_ids;
        i                PLS_INTEGER;
        h                PLS_INTEGER;
        j                PLS_INTEGER;
        --        t1                      NUMBER;
        --        t2                      NUMBER;
        l_dt_update           schedule_hist.dt_update%TYPE := current_timestamp;
        l_schedule_row        schedule%ROWTYPE;
        l_person              t_person;
        l_schedule_rows       ts_schedule.schedule_tc;
        l_id_room             schedule.id_room%TYPE;
        l_sch_group_rows      ts_sch_group.sch_group_tc;
        l_sch_group_ins_rows  ts_sch_group.sch_group_tc;
        l_sch_group_upd_rows  ts_sch_group.sch_group_tc;
        l_current_ids         table_number := table_number();
        l_new_ids             table_number := table_number();
        l_to_delete           table_number := table_number();
        l_to_insert           table_number := table_number();
        l_to_update           table_number := table_number();
        l_id_schedule_outp    schedule_outp.id_schedule_outp%TYPE;
        l_sch_resource_rows   ts_sch_resource.sch_resource_tc;
        l_sch_prof_outp_rows  ts_sch_prof_outp.sch_prof_outp_tc;
        l_profs               t_resources := t_resources();
        l_bed                 t_resource;
        l_schedule_bed_rows   ts_schedule_bed.schedule_bed_tc;
        l_rehab_group         t_resource;
        l_rehab_group_rows    ts_sch_rehab_group.sch_rehab_group_tc;
        l_id_prof_leader      sch_resource.id_professional%TYPE;
        l_exists_surg_proc    BOOLEAN; -- useless
        l_retval              BOOLEAN;
        l_dummy               VARCHAR2(4000);
        l_err_instance_id_out NUMBER;
        l_event               sch_event%ROWTYPE;
        l_id_epis_type        NUMBER;
        l_flg_count           NUMBER;
    
        FUNCTION get_epis_type(i_id_schedule IN NUMBER) RETURN NUMBER IS
            tbl_id   table_number;
            l_return NUMBER;
        BEGIN
        
            SELECT e.id_epis_type
              BULK COLLECT
              INTO tbl_id
              FROM episode e
              JOIN epis_info ei
                ON ei.id_episode = e.id_episode
             WHERE ei.id_schedule = i_id_schedule;
        
            IF tbl_id.count > 0
            THEN
                l_return := tbl_id(1);
            END IF;
        
            RETURN l_return;
        
        END get_epis_type;
    
        -- group appointments specific logic
        PROCEDURE inner_update_group_sch IS
            l_func_name VARCHAR2(32) := 'INNER_UPDATE_GROUP_SCH';
        BEGIN
            -- get current schedule patient new data from i_persons
            g_error  := l_func_name || ' - GET_PERSON_DATA(1). pfh id=' || l_pfh_rows(i).id_schedule_pfh ||
                        ', id_patient=' || l_current_ids(1);
            l_person := get_person_data(i_persons, l_current_ids(1)); -- e' agendamento de grupo, so' ha' 1 paciente por ag
        
            -- not found means this patient is no longer in this group. lets cancel his appointment
            IF l_person.id_patient IS NULL
            THEN
                IF NOT cancel_schedule(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_sch_ext       => i_id_sch_ext,
                                       i_ids_patient      => table_number(l_current_ids(1)),
                                       i_id_professional  => i_prof.id,
                                       i_id_cancel_reason => 9,
                                       i_cancel_notes     => NULL,
                                       i_cancel_date      => to_timestamp_tz(i_cancel_date, 'yyyymmddhh24miss'),
                                       i_cancel_exam_req  => pk_alert_constant.g_yes,
                                       i_updating         => pk_alert_constant.g_yes,
                                       o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
            ELSE
                -- found. lets update the schedule
                -- get new id_room
                g_error   := l_func_name || ' - GET NEW ID_ROOM. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                l_id_room := get_id_room(i_resources, l_pfh_rows(i).id_schedule_procedure);
            
                -- prepare schedule data. Columns assigned with l_schedule_row.<> are the ones that see their value unchanged. 
                l_schedule_rows.delete;
                l_schedule_rows(1).id_schedule := l_pfh_rows(i).id_schedule_pfh;
                l_schedule_rows(1).id_instit_requests := l_person.id_instit_requests;
                l_schedule_rows(1).id_instit_requested := i_id_instit_requested;
                l_schedule_rows(1).id_dcs_requests := l_person.id_dcs_requests;
                l_schedule_rows(1).id_dcs_requested := l_schedule_row.id_dcs_requested; --!
                l_schedule_rows(1).id_prof_requests := l_person.id_prof_requests;
                l_schedule_rows(1).id_prof_schedules := l_person.id_prof_schedules;
                l_schedule_rows(1).flg_urgency := l_schedule_row.flg_urgency;
            
                l_schedule_rows(1).flg_status := i_flg_status; --l_schedule_row.flg_status;
                l_schedule_rows(1).video_link := i_video_link;
            
                l_schedule_rows(1).id_prof_cancel := l_schedule_row.id_prof_cancel;
                l_schedule_rows(1).schedule_notes := l_person.notes;
                l_schedule_rows(1).id_cancel_reason := l_schedule_row.id_cancel_reason;
                l_schedule_rows(1).id_lang_translator := l_schedule_row.id_lang_translator;
                l_schedule_rows(1).id_lang_preferred := l_person.id_lang_translator;
                l_schedule_rows(1).id_sch_event := l_schedule_row.id_sch_event;
                l_schedule_rows(1).id_reason := l_person.id_reason;
                l_schedule_rows(1).id_origin := l_person.id_origin;
                l_schedule_rows(1).id_room := nvl(l_id_room, l_schedule_row.id_room);
                l_schedule_rows(1).schedule_cancel_notes := l_schedule_row.schedule_cancel_notes;
                l_schedule_rows(1).flg_notification := l_person.flg_notification;
                l_schedule_rows(1).id_schedule_ref := l_schedule_row.id_schedule_ref;
                l_schedule_rows(1).flg_vacancy := i_flg_vacancy;
                l_schedule_rows(1).flg_sch_type := l_schedule_row.flg_sch_type;
                l_schedule_rows(1).reason_notes := l_person.reason_notes;
                l_schedule_rows(1).dt_begin_tstz := l_schedule_row.dt_begin_tstz;
                l_schedule_rows(1).dt_cancel_tstz := l_schedule_row.dt_cancel_tstz;
                l_schedule_rows(1).dt_end_tstz := l_schedule_row.dt_end_tstz;
                l_schedule_rows(1).dt_request_tstz := l_schedule_row.dt_request_tstz;
                l_schedule_rows(1).dt_schedule_tstz := l_schedule_row.dt_schedule_tstz;
                l_schedule_rows(1).flg_schedule_via := l_person.flg_schedule_via;
                l_schedule_rows(1).flg_instructions := l_schedule_row.flg_instructions;
                l_schedule_rows(1).id_sch_consult_vacancy := l_schedule_row.id_sch_consult_vacancy;
                l_schedule_rows(1).flg_notification_via := l_person.flg_notification_via;
                l_schedule_rows(1).id_prof_notification := l_person.id_prof_notification;
                l_schedule_rows(1).dt_notification_tstz := l_person.dt_notification;
                l_schedule_rows(1).flg_request_type := l_person.flg_request_type;
                l_schedule_rows(1).id_episode := l_schedule_row.id_episode;
                l_schedule_rows(1).id_schedule_recursion := l_schedule_row.id_schedule_recursion;
                l_schedule_rows(1).id_sch_combi_detail := l_schedule_row.id_sch_combi_detail;
                l_schedule_rows(1).flg_present := l_schedule_row.flg_present;
                l_schedule_rows(1).id_multidisc := l_schedule_row.id_multidisc;
                l_schedule_rows(1).id_resched_reason := l_schedule_row.id_resched_reason;
                l_schedule_rows(1).id_prof_resched := l_schedule_row.id_prof_resched;
                l_schedule_rows(1).dt_resched_date := l_schedule_row.dt_resched_date;
                l_schedule_rows(1).resched_notes := l_schedule_row.resched_notes;
                l_schedule_rows(1).id_group := l_schedule_row.id_group;
                l_schedule_rows(1).flg_reason_type := l_person.flg_reason_type;
            
                -- update schedule table
                g_error := l_func_name || ' - UPDATE SCHEDULE TABLE. id_schedule = ' || l_pfh_rows(i).id_schedule_pfh;
                ts_schedule.upd(col_in            => l_schedule_rows,
                                ignore_if_null_in => FALSE, -- novos valores com null sao assim gravados 
                                handle_error_in   => FALSE);
            
                -- update sch_group table
                --copy field values to a accepted type
                l_sch_group_upd_rows.delete;
                l_sch_group_upd_rows(1).id_schedule := l_pfh_rows(i).id_schedule_pfh;
                l_sch_group_upd_rows(1).id_patient := l_person.id_patient;
                l_sch_group_upd_rows(1).flg_ref_type := l_person.flg_ref_type;
                l_sch_group_upd_rows(1).id_prof_ref := l_person.id_prof_referrer_ext;
                l_sch_group_upd_rows(1).id_inst_ref := l_person.id_inst_referrer_ext;
                l_sch_group_upd_rows(1).id_cancel_reason := l_person.id_noshow_reason;
                l_sch_group_upd_rows(1).no_show_notes := l_person.noshow_notes;
                l_sch_group_upd_rows(1).flg_contact_type := l_person.flg_contact_type;
                l_sch_group_upd_rows(1).id_health_plan := l_person.id_health_plan;
                l_sch_group_upd_rows(1).auth_code := l_person.auth_code;
                l_sch_group_upd_rows(1).dt_auth_code_exp := l_person.dt_auth_code_exp;
                l_sch_group_upd_rows(1).pat_instructions := l_person.pat_instructions;
                l_sch_group_upd_rows(1).id_group := l_sch_group_rows(1).id_group;
            
                --update
                g_error := l_func_name || ' - UPDATE SCH_GROUP TABLE. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                ts_sch_group.upd(col_in            => l_sch_group_upd_rows,
                                 ignore_if_null_in => FALSE, -- novos valores com null sao assim gravados 
                                 handle_error_in   => FALSE);
            
            END IF;
        END inner_update_group_sch;
    
        -- non-group appointments logic
        PROCEDURE inner_update_generic_sch IS
            l_func_name      VARCHAR2(32) := 'INNER_UPDATE_GENERIC_SCH';
            l_old_id_patient sch_group.id_patient%TYPE;
            l_new_id_patient sch_group.id_patient%TYPE;
            l_id_epis_type   NUMBER;
            l_bool           BOOLEAN;
        
            l_id_prev_episode NUMBER;
            l_id_epis_hhc_req NUMBER;
            l_pat             NUMBER;
        
        BEGIN
            -- get main patient data. his data is needed for the schedule table update
            g_error  := l_func_name || ' - GET PATIENT DATA. pfh id=' || l_pfh_rows(i).id_schedule_pfh;
            l_person := get_first_person_data(i_persons);
        
            -- get new id_room
            g_error   := l_func_name || ' - GET NEW ID_ROOM. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
            l_id_room := get_id_room(i_resources, l_pfh_rows(i).id_schedule_procedure);
        
            -- prepare schedule data. Columns assigned with l_schedule_row.<> are the ones that see their value unchanged. 
            l_schedule_rows(1).id_schedule := l_pfh_rows(i).id_schedule_pfh;
            l_schedule_rows(1).id_instit_requests := l_person.id_instit_requests;
            l_schedule_rows(1).id_instit_requested := i_id_instit_requested;
            l_schedule_rows(1).id_dcs_requests := l_person.id_dcs_requests;
            l_schedule_rows(1).id_dcs_requested := l_schedule_row.id_dcs_requested; --!
            l_schedule_rows(1).id_prof_requests := l_person.id_prof_requests;
            l_schedule_rows(1).id_prof_schedules := l_person.id_prof_schedules;
            l_schedule_rows(1).flg_urgency := l_schedule_row.flg_urgency;
            l_schedule_rows(1).flg_status := i_flg_status; --l_schedule_row.flg_status;
            l_schedule_rows(1).video_link := i_video_link;
            l_schedule_rows(1).id_prof_cancel := l_schedule_row.id_prof_cancel;
            l_schedule_rows(1).schedule_notes := l_person.notes;
            l_schedule_rows(1).id_cancel_reason := l_schedule_row.id_cancel_reason;
            l_schedule_rows(1).id_lang_translator := l_schedule_row.id_lang_translator;
            l_schedule_rows(1).id_lang_preferred := l_person.id_lang_translator;
            l_schedule_rows(1).id_sch_event := l_schedule_row.id_sch_event;
            l_schedule_rows(1).id_reason := l_person.id_reason;
            l_schedule_rows(1).id_origin := l_person.id_origin;
            l_schedule_rows(1).id_room := nvl(l_id_room, l_schedule_row.id_room);
            l_schedule_rows(1).schedule_cancel_notes := l_schedule_row.schedule_cancel_notes;
            l_schedule_rows(1).flg_notification := l_person.flg_notification;
            l_schedule_rows(1).id_schedule_ref := l_schedule_row.id_schedule_ref;
            l_schedule_rows(1).flg_vacancy := i_flg_vacancy;
            l_schedule_rows(1).flg_sch_type := l_schedule_row.flg_sch_type;
            l_schedule_rows(1).reason_notes := l_person.reason_notes;
            l_schedule_rows(1).dt_begin_tstz := l_schedule_row.dt_begin_tstz;
            l_schedule_rows(1).dt_cancel_tstz := l_schedule_row.dt_cancel_tstz;
            l_schedule_rows(1).dt_end_tstz := l_schedule_row.dt_end_tstz;
            l_schedule_rows(1).dt_request_tstz := l_schedule_row.dt_request_tstz;
            l_schedule_rows(1).dt_schedule_tstz := l_schedule_row.dt_schedule_tstz;
            l_schedule_rows(1).flg_schedule_via := l_person.flg_schedule_via;
            l_schedule_rows(1).flg_instructions := l_schedule_row.flg_instructions;
            l_schedule_rows(1).id_sch_consult_vacancy := l_schedule_row.id_sch_consult_vacancy;
            l_schedule_rows(1).flg_notification_via := l_person.flg_notification_via;
            l_schedule_rows(1).id_prof_notification := l_person.id_prof_notification;
            l_schedule_rows(1).dt_notification_tstz := l_person.dt_notification;
            l_schedule_rows(1).flg_request_type := l_person.flg_request_type;
            l_schedule_rows(1).id_episode := l_schedule_row.id_episode;
            l_schedule_rows(1).id_schedule_recursion := l_schedule_row.id_schedule_recursion;
            l_schedule_rows(1).id_sch_combi_detail := l_schedule_row.id_sch_combi_detail;
            l_schedule_rows(1).flg_present := l_schedule_row.flg_present;
            l_schedule_rows(1).id_multidisc := l_schedule_row.id_multidisc;
            l_schedule_rows(1).id_resched_reason := l_schedule_row.id_resched_reason;
            l_schedule_rows(1).id_prof_resched := l_schedule_row.id_prof_resched;
            l_schedule_rows(1).dt_resched_date := l_schedule_row.dt_resched_date;
            l_schedule_rows(1).resched_notes := l_schedule_row.resched_notes;
            l_schedule_rows(1).id_group := l_schedule_row.id_group;
            l_schedule_rows(1).flg_reason_type := l_person.flg_reason_type;
        
            -- update schedule table
            g_error := l_func_name || ' - UPDATE SCHEDULE TABLE. id_schedule = ' || l_pfh_rows(i).id_schedule_pfh;
            ts_schedule.upd(col_in            => l_schedule_rows,
                            ignore_if_null_in => FALSE, -- novos valores com null sao assim gravados 
                            handle_error_in   => FALSE);
        
            -- passemos agora a' sch_group 
            -- determinar o que e' para apagar, inserir e actualizar
            l_to_update := l_current_ids MULTISET INTERSECT l_new_ids;
            l_to_delete := l_current_ids MULTISET except l_new_ids;
            l_to_insert := l_new_ids MULTISET except l_current_ids;
        
            -- inserir novos pacientes
            j := l_to_insert.first;
            WHILE j IS NOT NULL
            LOOP
                -- get patient's new data
                g_error          := l_func_name || ' - GET_PERSON_DATA(2). pfh id=' || l_pfh_rows(i).id_schedule_pfh ||
                                    ', id_patient=' || l_to_insert(j);
                l_person         := get_person_data(i_persons, l_to_insert(j));
                l_new_id_patient := l_to_insert(j);
                --copy field values to a accepted type
                l_sch_group_ins_rows(j).id_group := ts_sch_group.next_key;
                l_sch_group_ins_rows(j).id_schedule := l_pfh_rows(i).id_schedule_pfh;
                l_sch_group_ins_rows(j).id_patient := l_person.id_patient;
                l_sch_group_ins_rows(j).flg_ref_type := l_person.flg_ref_type;
                l_sch_group_ins_rows(j).id_prof_ref := l_person.id_prof_referrer_ext;
                l_sch_group_ins_rows(j).id_inst_ref := l_person.id_inst_referrer_ext;
                l_sch_group_ins_rows(j).id_cancel_reason := l_person.id_noshow_reason;
                l_sch_group_ins_rows(j).no_show_notes := l_person.noshow_notes;
                l_sch_group_ins_rows(j).flg_contact_type := l_person.flg_contact_type;
                l_sch_group_ins_rows(j).id_health_plan := l_person.id_health_plan;
                l_sch_group_ins_rows(j).auth_code := l_person.auth_code;
                l_sch_group_ins_rows(j).dt_auth_code_exp := l_person.dt_auth_code_exp;
                l_sch_group_ins_rows(j).pat_instructions := l_person.pat_instructions;
                j := l_to_insert.next(j);
            END LOOP;
        
            IF l_sch_group_ins_rows.count > 0
            THEN
                g_error := l_func_name || ' - CALL TS_SCH_GROUP.INS with id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                ts_sch_group.ins(rows_in => l_sch_group_ins_rows, handle_error_in => FALSE);
            END IF;
        
            -- apagar os ausentes 
            j := l_to_delete.first;
            WHILE j IS NOT NULL
            LOOP
                g_error := l_func_name || ' - CALL TS_SCH_GROUP.del_SGP_IDSCH_IDPAT_UIDX with id_schedule=' || l_pfh_rows(i).id_schedule_pfh ||
                           ', id_patient=' || l_to_delete(j);
                ts_sch_group.del_sgp_idsch_idpat_uidx(id_patient_in   => l_to_delete(j),
                                                      id_schedule_in  => l_pfh_rows(i).id_schedule_pfh,
                                                      handle_error_in => FALSE);
            
                l_old_id_patient := l_to_delete(j);
                j                := l_to_delete.next(j);
            END LOOP;
        
            -- actualizar os presentes
            j := l_to_update.first;
            WHILE j IS NOT NULL
            LOOP
                -- get patient's new data
                g_error  := l_func_name || ' - GET_PERSON_DATA(3). id_schedule=' || l_pfh_rows(i).id_schedule_pfh ||
                            '  id_patient=' || l_to_update(j);
                l_person := get_person_data(i_persons, l_to_update(j));
            
                -- encontrar o id_group deste paciente. Esta' no mesmo indice da l_current_ids
                g_error := l_func_name || ' - FIND ID_GROUP for id_schedule=' || l_pfh_rows(i).id_schedule_pfh ||
                           ', id_patient=' || l_to_update(j);
                h       := l_current_ids.first;
                WHILE h IS NOT NULL
                LOOP
                    IF l_current_ids(h) = l_to_update(j)
                    THEN
                        l_sch_group_upd_rows(j).id_group := l_sch_group_rows(h).id_group;
                    END IF;
                    h := l_current_ids.next(h);
                END LOOP;
                --copy field values to a accepted type
                l_sch_group_upd_rows(j).id_schedule := l_pfh_rows(i).id_schedule_pfh;
                l_sch_group_upd_rows(j).id_patient := l_person.id_patient;
                l_sch_group_upd_rows(j).flg_ref_type := l_person.flg_ref_type;
                l_sch_group_upd_rows(j).id_prof_ref := l_person.id_prof_referrer_ext;
                l_sch_group_upd_rows(j).id_inst_ref := l_person.id_inst_referrer_ext;
                l_sch_group_upd_rows(j).id_cancel_reason := l_person.id_noshow_reason;
                l_sch_group_upd_rows(j).no_show_notes := l_person.noshow_notes;
                l_sch_group_upd_rows(j).flg_contact_type := l_person.flg_contact_type;
                l_sch_group_upd_rows(j).id_health_plan := l_person.id_health_plan;
                l_sch_group_upd_rows(j).auth_code := l_person.auth_code;
                l_sch_group_upd_rows(j).dt_auth_code_exp := l_person.dt_auth_code_exp;
                l_sch_group_upd_rows(j).pat_instructions := l_person.pat_instructions;
                j := l_to_update.next(j);
            END LOOP;
            --update
            IF l_sch_group_upd_rows.count > 0
            THEN
                g_error := l_func_name || ' - UPDATE SCH_GROUP TABLE. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                ts_sch_group.upd(col_in            => l_sch_group_upd_rows,
                                 ignore_if_null_in => FALSE, -- novos valores com null sao assim gravados 
                                 handle_error_in   => FALSE);
            END IF;
        
            -- alterar paciente no episodio (alert-276749)
            g_error := l_func_name || ' - CALL pk_api_patient.intf_update_patient with i_old_id_patient=' ||
                       l_old_id_patient || ', i_new_id_patient=' || l_new_id_patient;
            IF l_old_id_patient IS NOT NULL
               AND l_new_id_patient IS NOT NULL
            THEN
                IF NOT pk_api_patient.intf_update_patient(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_old_id_patient => l_old_id_patient,
                                                          i_new_id_patient => l_new_id_patient,
                                                          o_error          => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            l_id_epis_type := get_epis_type(i_id_schedule => l_pfh_rows(i).id_schedule_pfh);
            IF l_id_epis_type = pk_alert_constant.g_epis_type_home_health_care
            THEN
            
                -- hhc request approved only if schdule is approved
                IF i_flg_status = pk_schedule.g_sched_status_scheduled
                THEN
                    pk_alertlog.log_debug(text        => 'UPDATE HHC TO INPROGRESS',
                                          object_name => g_package_name,
                                          owner       => g_package_owner);
                    l_pat             := l_person.id_patient;
                    l_id_prev_episode := pk_hhc_core.get_active_hhc_episode(i_patient => l_pat);
                    l_id_epis_hhc_req := pk_hhc_core.get_active_hhc_request(i_patient => l_pat);
                
                    l_bool := pk_hhc_core.set_status_in_progress(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_id_epis_hhc_req => l_id_epis_hhc_req,
                                                                 o_error           => o_error);
                    IF NOT l_bool
                    THEN
                        pk_utils.undo_changes;
                        RAISE l_func_exception;
                    END IF;
                
                END IF;
            
                l_bool := generate_hhc_alerts(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_id_schedule => l_pfh_rows(i).id_schedule_pfh,
                                              i_flg_status  => i_flg_status);
            END IF;
        
        END inner_update_generic_sch;
    
    BEGIN
        --        t1 := dbms_utility.get_time;
        -- major validatzion
        customs_inspection(i_lang                => i_lang,
                           i_prof                => i_prof,
                           i_id_sch_ext          => i_id_sch_ext,
                           i_flg_status          => i_flg_status,
                           i_id_instit_requested => i_id_instit_requested,
                           i_id_dep_requested    => i_id_dep_requested,
                           i_procedures          => i_procedures,
                           i_persons             => i_persons,
                           i_resources           => i_resources,
                           i_procedure_reqs      => i_procedure_reqs,
                           o_exists_surg_proc    => l_exists_surg_proc);
    
        -- get current pfh scheduler ids related to this external id
        g_error    := l_func_name || ' - GET PFH ID';
        l_pfh_rows := get_pfh_rows(i_id_sch_ext);
    
        -- get new(after update) id_patients
        g_error   := l_func_name || ' - GET NEW ID_PATIENTS FROM i_persons';
        l_new_ids := get_ids_persons(i_persons);
    
        -- loop all ids found
        IF cardinality(l_pfh_rows) > 0
        THEN
        
            i := l_pfh_rows.first;
            WHILE i IS NOT NULL
            LOOP
            
                -- init. this is a loop so we do not want pesky values creeping up from the previous iteration
                l_schedule_rows.delete;
                l_sch_group_rows.delete;
                l_sch_group_ins_rows.delete;
                l_sch_group_upd_rows.delete;
                l_current_ids.delete;
                l_to_delete.delete;
                l_to_insert.delete;
                l_to_update.delete;
                l_id_room := NULL;
                l_sch_resource_rows.delete;
                l_profs.delete;
                l_sch_prof_outp_rows.delete;
                l_schedule_bed_rows.delete;
                l_bed.id_resource         := NULL;
                l_rehab_group.id_resource := NULL;
                l_rehab_group_rows.delete;
                l_id_prof_leader := NULL;
            
                -- get current id_schedule patients data. The patients themselves cannot change under an update, only their attributes.
                -- UPDATE: BUT THEY CAN CHANGE UNDER AN ADT MATCH, WHICH ALSO CALLS THIS FUNCTION.
                g_error := l_func_name || ' - GET CURRENT SCH_GROUP RECORDS. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                -- if this schedule is in a group, this bulk collect gets at most 1 row. 
                -- if this schedule is not in a group, this bulk collect may get more than 1 row.
                SELECT g.*
                  BULK COLLECT
                  INTO l_sch_group_rows
                  FROM sch_group g
                 WHERE g.id_schedule = l_pfh_rows(i).id_schedule_pfh;
            
                g_error := l_func_name || ' - GET CURRENT PATIENT IDS. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                SELECT g.id_patient
                  BULK COLLECT
                  INTO l_current_ids
                  FROM sch_group g
                 WHERE g.id_schedule = l_pfh_rows(i).id_schedule_pfh;
            
                -- get this schedule' data
                g_error := l_func_name || ' - GET SCHEDULE DATA. id_schedule = ' || l_pfh_rows(i).id_schedule_pfh;
                SELECT s.*
                  INTO l_schedule_row
                  FROM schedule s
                 WHERE s.id_schedule = l_pfh_rows(i).id_schedule_pfh;
            
                -- major crossroad
                g_error := l_func_name || ' - GET event data. id_sch_event= ' || l_schedule_row.id_sch_event;
                l_event := pk_schedule_common.get_event_data(l_schedule_row.id_sch_event);
            
                IF l_event.flg_is_group = pk_alert_constant.g_yes
                THEN
                    inner_update_group_sch;
                ELSE
                    inner_update_generic_sch;
                END IF;
            
                -- SCH_RESOURCE E SCH_PROF_OUTP - actualizar os profissionais deste agendamento
                -- para simplificar, vou apagar os registos na sch_resource e inserir tudo de novo
                -- id_schedule_outp needed
                g_error := l_func_name || ' - GET ID_SCHEDULE_OUTP. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                BEGIN
                    SELECT id_schedule_outp
                      INTO l_id_schedule_outp
                      FROM schedule_outp so
                     WHERE so.id_schedule = l_pfh_rows(i).id_schedule_pfh;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
            
                -- apagar primeiro
                g_error := l_func_name || ' - DELETE CURRENT RESOURCE ROWS. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                ts_sch_resource.del_by_col(colname_in      => 'ID_SCHEDULE',
                                           colvalue_in     => to_char(l_pfh_rows(i).id_schedule_pfh),
                                           handle_error_in => TRUE);
            
                -- nesta so' se o agendamento e' de consulta - existe id_schedule_outp
                IF l_id_schedule_outp IS NOT NULL
                THEN
                    g_error := l_func_name || ' - DELETE CURRENT SCH_PROF_OUTP ROWS. pfh id= ' || l_pfh_rows(i).id_schedule_pfh;
                    ts_sch_prof_outp.del_by(where_clause_in => ' id_schedule_outp =' || l_id_schedule_outp,
                                            handle_error_in => TRUE);
                END IF;
            
                -- pegar os profs que chegam da agenda
                g_error := l_func_name || ' - GET PROFS. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                l_profs := get_profs(i_resources, l_pfh_rows(i).id_schedule_procedure);
            
                -- converter numa sch_resource_tc e numa sch_prof_outp_tc
                g_error        := l_func_name ||
                                  ' - CONVERT t_resources INTO ts_sch_resource.sch_resource_tc AND ts_sch_prof_outp.sch_prof_outp_tc. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                l_id_epis_type := get_epis_type(l_pfh_rows(i).id_schedule_pfh);
                l_flg_count    := 0;
                h              := l_profs.first;
                WHILE h IS NOT NULL
                LOOP
                    l_flg_count := l_flg_count + 1;
                    l_sch_resource_rows(h).id_sch_resource := ts_sch_resource.next_key();
                    l_sch_resource_rows(h).id_schedule := l_pfh_rows(i).id_schedule_pfh;
                    l_sch_resource_rows(h).id_institution := i_id_instit_requested;
                    l_sch_resource_rows(h).id_professional := l_profs(h).id_resource;
                    l_sch_resource_rows(h).dt_sch_resource_tstz := l_dt_update;
                    l_sch_resource_rows(h).flg_leader := l_profs(h).flg_leader;
                    --capture leader prof id
                    l_id_prof_leader := CASE l_profs(h).flg_leader
                                            WHEN pk_alert_constant.g_yes THEN
                                             l_profs(h).id_resource
                                            ELSE
                                             l_id_prof_leader
                                        END;
                
                    IF l_id_schedule_outp IS NOT NULL
                    THEN
                    
                        IF l_id_epis_type = pk_alert_constant.g_epis_type_home_health_care
                        THEN
                        
                            IF l_profs(h).flg_leader = pk_alert_constant.g_yes
                            THEN
                                l_sch_prof_outp_rows(1).id_sch_prof_outp := seq_sch_prof_outp.nextval; -- este ts_ nao tem a funcao next_key !
                                l_sch_prof_outp_rows(1).id_schedule_outp := l_id_schedule_outp;
                                l_sch_prof_outp_rows(1).id_professional := l_id_prof_leader;
                            END IF;
                        ELSE
                        
                            l_sch_prof_outp_rows(h).id_sch_prof_outp := seq_sch_prof_outp.nextval; -- este ts_ nao tem a funcao next_key !
                            l_sch_prof_outp_rows(h).id_schedule_outp := l_id_schedule_outp;
                            l_sch_prof_outp_rows(h).id_professional := l_profs(h).id_resource;
                        END IF;
                    END IF;
                    h := l_profs.next(h);
                END LOOP;
            
                -- ready to roll
                g_error := l_func_name || ' - INSERT INTO SCH_RESOURCE. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                ts_sch_resource.ins(rows_in => l_sch_resource_rows, handle_error_in => FALSE);
            
                IF l_id_schedule_outp IS NOT NULL
                THEN
                    g_error := l_func_name || ' - INSERT INTO SCH_PROF_OUTP. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                    ts_sch_prof_outp.ins(rows_in => l_sch_prof_outp_rows, handle_error_in => FALSE);
                
                    -- update epis_info      
                    g_error := l_func_name || ' - UPDATE EPIS_INFO. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                    ts_epis_info.upd(sch_prof_outp_id_prof_in => l_id_prof_leader,
                                     id_professional_in       => l_id_prof_leader,
                                     where_in                 => 'ID_SCHEDULE_OUTP = ' || l_id_schedule_outp,
                                     handle_error_in          => FALSE);
                END IF;
            
                -- SCHEDULE_BED
                IF l_schedule_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_inp
                THEN
                    -- let's see if there's a bed over yonder
                    g_error := l_func_name || ' - GET BED data. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                    l_bed   := get_first_resource_data(i_resources     => i_resources,
                                                       i_id_sch_proc   => l_pfh_rows(i).id_schedule_procedure,
                                                       i_resource_type => g_res_type_bed);
                
                    -- if so, fetch current schedule_bed row and update it
                    IF l_bed.id_resource IS NOT NULL
                    THEN
                        g_error := l_func_name || ' - GET SCHEDULE_BED data. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                        SELECT *
                          BULK COLLECT
                          INTO l_schedule_bed_rows
                          FROM schedule_bed s
                         WHERE s.id_schedule = l_pfh_rows(i).id_schedule_pfh;
                    
                        l_schedule_bed_rows(1).id_bed := l_bed.id_resource;
                        l_schedule_bed_rows(1).flg_temporary := get_sch_flg_tempor(i_flg_status);
                    
                        g_error := l_func_name || ' - UPDATE SCHEDULE_BED. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                        ts_schedule_bed.upd(col_in            => l_schedule_bed_rows,
                                            ignore_if_null_in => TRUE,
                                            handle_error_in   => FALSE);
                    END IF;
                END IF;
            
                --SCH_REHAB_GROUP
                IF l_schedule_row.flg_sch_type = pk_schedule_common.g_sch_dept_flg_dep_type_pm
                THEN
                    g_error       := l_func_name || ' - GET REHAB GROUP resource. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                    l_rehab_group := get_first_resource_data(i_resources     => i_resources,
                                                             i_id_sch_proc   => l_pfh_rows(i).id_schedule_procedure,
                                                             i_resource_type => g_res_type_rgroup);
                
                    IF l_rehab_group.id_resource IS NOT NULL
                    THEN
                        g_error := l_func_name || ' - GET SCH_REHAB_GROUP data. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                        SELECT *
                          BULK COLLECT
                          INTO l_rehab_group_rows
                          FROM sch_rehab_group s
                         WHERE s.id_schedule = l_pfh_rows(i).id_schedule_pfh;
                    
                        l_rehab_group_rows(1).id_rehab_group := l_rehab_group.id_resource;
                    
                        g_error := l_func_name || ' - UPDATE SCH_REHAB_GROUP. id_schedule=' || l_pfh_rows(i).id_schedule_pfh;
                        ts_sch_rehab_group.upd(col_in            => l_rehab_group_rows,
                                               ignore_if_null_in => TRUE,
                                               handle_error_in   => FALSE);
                    END IF;
                END IF;
            
                -- backup full schedule
                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || l_pfh_rows(i).id_schedule_pfh;
                pk_schedule_common.backup_all(i_id_sch    => l_pfh_rows(i).id_schedule_pfh,
                                              i_dt_update => current_timestamp,
                                              i_id_prof_u => i_prof.id);
            
                -- virou
                i := l_pfh_rows.next(i);
            END LOOP;
        ELSE
            RAISE l_no_pfh_id;
        END IF;
    
        -- falta inserir novos pacientes no grupo, se houver. Isto e' feito apos fim do ciclo dos ags actuais.
        IF l_event.flg_is_group = pk_alert_constant.g_yes
        THEN
            -- pegar os actuais
            g_error := l_func_name || ' - GET CURRENT PATIENT IDS. pfh id= ' || l_schedule_row.id_schedule;
            SELECT g.id_patient
              BULK COLLECT
              INTO l_current_ids
              FROM sch_group g
              JOIN schedule s
                ON g.id_schedule = s.id_schedule
             WHERE s.id_group = i_id_sch_ext
               AND s.flg_status <> pk_schedule.g_sched_status_cancelled;
        
            -- ver se ha pacientes novos no grupo. Se houver criar agendamentos individuais. o i_id_sch_ext e' o id unificador
            l_to_insert := l_new_ids MULTISET except l_current_ids;
            FOR indx IN 1 .. l_to_insert.count
            LOOP
            
                g_error  := l_func_name || ' - GET_PERSON_DATA(4). id_patient=' || l_to_insert(indx);
                l_person := get_person_data(i_persons, l_to_insert(indx));
            
                g_error := l_func_name || ' - CREATE_SCHEDULE. i_id_sch_ext=' || i_id_sch_ext || ', id_patient=' ||
                           l_to_insert(indx);
                IF NOT create_schedule(i_lang                => i_lang,
                                       i_prof                => i_prof,
                                       i_id_sch_ext          => i_id_sch_ext,
                                       i_flg_status          => i_flg_status,
                                       i_id_instit_requested => i_id_instit_requested,
                                       i_id_dep_requested    => i_id_dep_requested,
                                       i_flg_vacancy         => i_flg_vacancy,
                                       i_procedures          => i_procedures,
                                       i_resources           => i_resources,
                                       i_persons             => t_persons(l_person),
                                       i_procedure_reqs      => i_procedure_reqs,
                                       i_id_episode          => i_id_episode,
                                       i_id_sch_ref          => NULL,
                                       i_dt_begin            => i_dt_begin,
                                       i_dt_end              => i_dt_end,
                                       i_dt_referral         => NULL,
                                       o_ids_schedule        => l_to_delete, -- dummy
                                       o_error               => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END LOOP;
        END IF;
    
        --        t2 := dbms_utility.get_time;
        --        pk_alertlog.log_debug('UPDATE_SCHEDULE ext.id=' || i_id_sch_ext || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
        --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN g_invalid_data THEN
            l_retval := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                           i_func_proc_name => l_func_name,
                                                           i_package_name   => g_package_name,
                                                           i_package_error  => 5550,
                                                           i_sql_error      => g_inv_data_msg,
                                                           i_log_on         => TRUE,
                                                           o_error          => l_dummy);
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 5550,
                                   ora_sqlerrm         => g_inv_data_msg,
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            --            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN g_invalid_schedule THEN
            l_retval := pk_alert_exceptions.error_handling(i_lang           => i_lang,
                                                           i_func_proc_name => l_func_name,
                                                           i_package_name   => g_package_name,
                                                           i_package_error  => 6660,
                                                           i_sql_error      => g_inv_data_msg,
                                                           i_log_on         => TRUE,
                                                           o_error          => l_dummy);
        
            -- defini manualmente o o_error para nao ser poluido pelo process_error. A mensagem em l_inv_data_msg e' para ser mostrada ao user
            o_error := t_error_out(ora_sqlcode         => 6660,
                                   ora_sqlerrm         => g_inv_data_msg,
                                   err_desc            => NULL,
                                   err_action          => NULL,
                                   log_id              => NULL,
                                   err_instance_id_out => l_err_instance_id_out,
                                   msg_title           => NULL,
                                   flg_msg_type        => NULL);
            --            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_schedule;

    /*
    * Deletes the schedule from a temporary patient
    */
    FUNCTION update_schedule_patient
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'UPDATE_SCHEDULE_PATIENT';
    
    BEGIN
    
        g_error := 'DELETE SCHEDULE';
        DELETE FROM schedule
         WHERE id_schedule = i_id_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END update_schedule_patient;

    /*
    * updates the old schedule tables with proc and dates
    */
    FUNCTION update_sch_proc_and_dates
    (
        i_lang             IN language.id_language%TYPE,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        i_dt_begin_tstz    IN schedule.dt_begin_tstz%TYPE,
        i_dt_end_tszt      IN schedule.dt_end_tstz%TYPE,
        i_dep_clin_serv    IN dep_clin_serv.id_clinical_service%TYPE,
        i_flg_request_type IN schedule.flg_request_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'UPDATE_SCH_PROC_AND_DATES';
    
    BEGIN
    
        IF i_id_schedule IS NOT NULL
        THEN
            UPDATE schedule s
               SET s.flg_request_type = i_flg_request_type,
                   s.dt_begin_tstz    = i_dt_begin_tstz,
                   s.dt_end_tstz      = i_dt_end_tszt,
                   s.id_dcs_requested = i_dep_clin_serv
             WHERE s.id_schedule = i_id_schedule;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        
    END update_sch_proc_and_dates;

    /* new search function for surgery waiting list.
    * This function uses pk_wtl_pbl_core functions to do the job.
    * To be used by inter_alert
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_inst->i_patid available search fields
    * @param i_page              pagination info. page is a relative number to the rows per page value
    * @param i_rows_per_page     pagination info. page size
    * @param o_result            output collection
    * @param o_rowcount          absolute row count. Ignores i_start and i_offset
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      12-01-2012
    */
    FUNCTION search_wl_surg
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_ids_inst           IN table_number,
        i_id_department      IN NUMBER, -- id servico
        i_id_clinicalservice IN NUMBER, -- id_cs especialidade
        i_ids_content        IN table_varchar, -- ids content dos procedimentos cirurgicos
        i_ids_prefsurgeons   IN table_number, -- ids_surgeons
        i_dtbeginmin         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpb
        i_dtbeginmax         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpa
        i_ids_cancelreason   IN table_number, -- ids cancel reasons
        i_flgsstatus         IN table_varchar, -- admission status
        i_minexpecteddur     IN NUMBER, -- min expected duration (horas)
        i_maxexpecteddur     IN NUMBER, -- max expected duration (horas)
        i_flgpos             IN VARCHAR2, -- POS (Y/N)
        i_patminage          IN NUMBER, -- patient min age
        i_patmaxage          IN NUMBER, -- patient max age
        i_patgender          IN VARCHAR2, -- patient gender
        i_patid              IN NUMBER, -- patient id
        i_page               IN NUMBER DEFAULT 1,
        i_rows_per_page      IN NUMBER DEFAULT 20,
        o_result             OUT t_wl_search_row_coll,
        o_rowcount           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEARCH_WL_SURG';
        l_ids_procs table_number;
    
        -- inner function to convert procedures id_contents into id_procedures
        FUNCTION inner_get_ids_proc(ids table_varchar) RETURN table_number IS
            l_ret table_number;
        BEGIN
            IF ids IS NULL
               OR ids.count = 0
            THEN
                RETURN NULL;
            END IF;
        
            SELECT id_intervention
              BULK COLLECT
              INTO l_ret
              FROM intervention si
             WHERE si.id_content IN (SELECT column_value
                                       FROM TABLE(ids));
        
            RETURN l_ret;
        END inner_get_ids_proc;
    
    BEGIN
    
        -- if they sent us surg procedures id_contents, we need to convert them into id_sr_intervention ids
        IF i_ids_content IS NOT NULL
           AND i_ids_content.count > 0
        THEN
            g_error     := l_func_name || ' - CONVERT ID_CONTENTS TO ID_SR_INTERVENTIONS';
            l_ids_procs := inner_get_ids_proc(i_ids_content);
        END IF;
    
        -- call search
        g_error := l_func_name || ' - CALL pk_wtl_pbl_core.search_wl_surg';
        IF NOT pk_wtl_pbl_core.search_wl_surg(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_idsinstitutions     => i_ids_inst,
                                              i_iddepartment        => i_id_department,
                                              i_idclinicalservice   => i_id_clinicalservice,
                                              i_idsprocedures       => l_ids_procs,
                                              i_idsprefsurgeons     => i_ids_prefsurgeons,
                                              i_dtbeginmin          => i_dtbeginmin,
                                              i_dtbeginmax          => i_dtbeginmax,
                                              i_idscancelreason     => i_ids_cancelreason,
                                              i_flgsstatus          => i_flgsstatus,
                                              i_minexpectedduration => i_minexpecteddur,
                                              i_maxexpectedduration => i_maxexpecteddur,
                                              i_flgpos              => i_flgpos,
                                              i_patminage           => i_patminage,
                                              i_patmaxage           => i_patmaxage,
                                              i_patgender           => i_patgender,
                                              i_idpatient           => i_patid,
                                              i_page                => i_page,
                                              i_rows_per_page       => i_rows_per_page,
                                              o_result              => o_result,
                                              o_rowcount            => o_rowcount,
                                              o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END search_wl_surg;

    /* new search function for admission waiting list.
    * This function uses pk_wtl_pbl_core functions to do the job.
    * To be used by inter_alert
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_ids_inst->i_patid available search fields
    * @param i_page              pagination info. page is a relative number to the rows per page value
    * @param i_rows_per_page     pagination info. page size
    * @param o_result            output collection
    * @param o_rowcount          absolute row count. Ignores i_start and i_offset
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.2
    *  @since                      12-01-2012
    */
    FUNCTION search_wl_adm
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_idsinst            IN table_number,
        i_id_department      IN NUMBER, -- id servico
        i_id_clinicalservice IN NUMBER, -- id_cs especialidade
        i_ids_admprof        IN table_number, -- ids adm profs
        i_dtbeginmin         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpb
        i_dtbeginmax         IN TIMESTAMP WITH LOCAL TIME ZONE, -- dpa
        i_ids_cancelreason   IN table_number, -- ids cancel reasons
        i_flgsstatus         IN table_varchar, -- surg status
        i_idsindforadmission IN table_number, -- ids Indications for admission
        i_minexpecteddur     IN NUMBER, -- min expected duration (horas)
        i_maxexpecteddur     IN NUMBER, -- max expected duration (horas)
        i_patminage          IN NUMBER, -- patient min age
        i_patmaxage          IN NUMBER, -- patient max age
        i_patgender          IN VARCHAR2, -- patient gender
        i_patid              IN NUMBER, -- patient id
        i_page               IN NUMBER DEFAULT 1,
        i_rows_per_page      IN NUMBER DEFAULT 20,
        o_result             OUT t_wl_search_row_coll,
        o_rowcount           OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SEARCH_WL_SURG';
    BEGIN
    
        g_error := l_func_name || ' - CALL pk_wtl_pbl_core.search_wl_surg';
        IF NOT pk_wtl_pbl_core.search_wl_adm(i_lang                => i_lang,
                                             i_prof                => i_prof,
                                             i_idsinstitutions     => i_idsinst,
                                             i_iddepartment        => i_id_department,
                                             i_idclinicalservice   => i_id_clinicalservice,
                                             i_idsadmphys          => i_ids_admprof,
                                             i_dtbeginmin          => i_dtbeginmin,
                                             i_dtbeginmax          => i_dtbeginmax,
                                             i_idscancelreason     => i_ids_cancelreason,
                                             i_flgsstatus          => i_flgsstatus,
                                             i_idsindicadm         => i_idsindforadmission,
                                             i_minexpectedduration => i_minexpecteddur,
                                             i_maxexpectedduration => i_maxexpecteddur,
                                             i_patminage           => i_patminage,
                                             i_patmaxage           => i_patmaxage,
                                             i_patgender           => i_patgender,
                                             i_idpatient           => i_patid,
                                             i_page                => i_page,
                                             i_rows_per_page       => i_rows_per_page,
                                             o_result              => o_result,
                                             o_rowcount            => o_rowcount,
                                             o_error               => o_error)
        THEN
            RETURN FALSE;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END search_wl_adm;

    /* PRIVATE FUNCTION. TIS THE ONE THAT DOES THE JOB
    */
    FUNCTION update_notif
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_sch_ext     IN NUMBER,
        i_id_patient     IN sch_group.id_patient%TYPE,
        i_flg_notif      IN schedule.flg_notification%TYPE,
        i_flg_notif_via  IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        i_flg_notif_date IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_id_prof_notif  IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(32) := 'UPDATE_NOTIF';
        l_flg_notification    schedule.flg_notification%TYPE;
        l_flg_status          schedule.flg_status%TYPE;
        l_id_external_request p1_external_request.id_external_request%TYPE;
        l_func_exception      EXCEPTION;
        l_flg_notif_via       schedule.flg_notification_via%TYPE := i_flg_notif_via;
        l_ids_sch_pfh         table_number;
        l_no_pfh_id           EXCEPTION;
        i                     PLS_INTEGER;
        l_dummy               sch_group.id_patient%TYPE;
        l_do_update           BOOLEAN;
    BEGIN
    
        -- get internal ids
        g_error       := 'CANCEL_SCHEDULE - GET PFH ID';
        l_ids_sch_pfh := get_pfh_ids(i_id_sch_ext);
    
        IF l_ids_sch_pfh IS NULL
           OR l_ids_sch_pfh.count = 0
        THEN
            RAISE l_no_pfh_id;
        END IF;
    
        i := l_ids_sch_pfh.first;
        WHILE i IS NOT NULL
        LOOP
        
            -- Check if schedule exists
            g_error := 'GET FLG_NOTIFICATION';
            SELECT flg_notification, flg_status, nvl(flg_notification_via, i_flg_notif_via)
              INTO l_flg_notification, l_flg_status, l_flg_notif_via
              FROM schedule
             WHERE id_schedule = l_ids_sch_pfh(i);
        
            -- if a patient was sent only update if he/she belongs to this appointment
            IF i_id_patient IS NOT NULL
            THEN
                BEGIN
                    SELECT 1
                      INTO l_dummy
                      FROM sch_group sg
                     WHERE sg.id_schedule = l_ids_sch_pfh(i)
                       AND sg.id_patient = i_id_patient;
                    l_do_update := TRUE;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_do_update := FALSE;
                END;
            ELSE
                l_do_update := TRUE;
            END IF;
        
            IF l_do_update
            THEN
            
                g_error := 'UPDATE SCHEDULE';
                IF i_flg_notif = pk_schedule.g_sched_flg_notif_pending
                THEN
                    ts_schedule.upd(id_schedule_in             => l_ids_sch_pfh(i),
                                    id_instit_requests_in      => NULL,
                                    id_instit_requests_nin     => TRUE,
                                    id_instit_requested_in     => NULL,
                                    id_instit_requested_nin    => TRUE,
                                    id_dcs_requests_in         => NULL,
                                    id_dcs_requests_nin        => TRUE,
                                    id_dcs_requested_in        => NULL,
                                    id_dcs_requested_nin       => TRUE,
                                    id_prof_requests_in        => NULL,
                                    id_prof_requests_nin       => TRUE,
                                    id_prof_schedules_in       => NULL,
                                    id_prof_schedules_nin      => TRUE,
                                    flg_status_in              => NULL,
                                    flg_status_nin             => TRUE,
                                    id_prof_cancel_in          => NULL,
                                    id_prof_cancel_nin         => TRUE,
                                    schedule_notes_in          => NULL,
                                    schedule_notes_nin         => TRUE,
                                    id_cancel_reason_in        => NULL,
                                    id_cancel_reason_nin       => TRUE,
                                    id_lang_translator_in      => NULL,
                                    id_lang_translator_nin     => TRUE,
                                    id_lang_preferred_in       => NULL,
                                    id_lang_preferred_nin      => TRUE,
                                    id_sch_event_in            => NULL,
                                    id_sch_event_nin           => TRUE,
                                    id_reason_in               => NULL,
                                    id_reason_nin              => TRUE,
                                    id_origin_in               => NULL,
                                    id_origin_nin              => TRUE,
                                    id_room_in                 => NULL,
                                    id_room_nin                => TRUE,
                                    flg_urgency_in             => NULL,
                                    flg_urgency_nin            => TRUE,
                                    schedule_cancel_notes_in   => NULL,
                                    schedule_cancel_notes_nin  => TRUE,
                                    flg_notification_in        => i_flg_notif,
                                    flg_notification_nin       => TRUE,
                                    id_schedule_ref_in         => NULL,
                                    id_schedule_ref_nin        => TRUE,
                                    flg_vacancy_in             => NULL,
                                    flg_vacancy_nin            => TRUE,
                                    flg_sch_type_in            => NULL,
                                    flg_sch_type_nin           => TRUE,
                                    reason_notes_in            => NULL,
                                    reason_notes_nin           => TRUE,
                                    dt_begin_tstz_in           => NULL,
                                    dt_begin_tstz_nin          => TRUE,
                                    dt_cancel_tstz_in          => NULL,
                                    dt_cancel_tstz_nin         => TRUE,
                                    dt_end_tstz_in             => NULL,
                                    dt_end_tstz_nin            => TRUE,
                                    dt_request_tstz_in         => NULL,
                                    dt_request_tstz_nin        => TRUE,
                                    dt_schedule_tstz_in        => NULL,
                                    dt_schedule_tstz_nin       => TRUE,
                                    flg_instructions_in        => NULL,
                                    flg_instructions_nin       => TRUE,
                                    flg_schedule_via_in        => NULL,
                                    flg_schedule_via_nin       => TRUE,
                                    id_prof_notification_in    => NULL,
                                    id_prof_notification_nin   => FALSE,
                                    dt_notification_tstz_in    => NULL,
                                    dt_notification_tstz_nin   => FALSE,
                                    flg_notification_via_in    => NULL,
                                    flg_notification_via_nin   => FALSE,
                                    id_sch_consult_vacancy_in  => NULL,
                                    id_sch_consult_vacancy_nin => TRUE,
                                    flg_request_type_in        => NULL,
                                    flg_request_type_nin       => TRUE,
                                    id_episode_in              => NULL,
                                    id_episode_nin             => TRUE,
                                    id_schedule_recursion_in   => NULL,
                                    id_schedule_recursion_nin  => TRUE,
                                    create_user_in             => NULL,
                                    create_user_nin            => TRUE,
                                    create_time_in             => NULL,
                                    create_time_nin            => TRUE,
                                    create_institution_in      => NULL,
                                    create_institution_nin     => TRUE,
                                    update_user_in             => NULL,
                                    update_user_nin            => TRUE,
                                    update_time_in             => NULL,
                                    update_time_nin            => TRUE,
                                    update_institution_in      => NULL,
                                    update_institution_nin     => TRUE,
                                    flg_present_in             => NULL,
                                    flg_present_nin            => TRUE,
                                    id_multidisc_in            => NULL,
                                    id_multidisc_nin           => TRUE,
                                    id_sch_combi_detail_in     => NULL,
                                    id_sch_combi_detail_nin    => TRUE,
                                    flg_reason_type_in         => NULL,
                                    flg_reason_type_nin        => TRUE,
                                    handle_error_in            => TRUE);
                ELSE
                    ts_schedule.upd(id_schedule_in             => l_ids_sch_pfh(i),
                                    id_instit_requests_in      => NULL,
                                    id_instit_requests_nin     => TRUE,
                                    id_instit_requested_in     => NULL,
                                    id_instit_requested_nin    => TRUE,
                                    id_dcs_requests_in         => NULL,
                                    id_dcs_requests_nin        => TRUE,
                                    id_dcs_requested_in        => NULL,
                                    id_dcs_requested_nin       => TRUE,
                                    id_prof_requests_in        => NULL,
                                    id_prof_requests_nin       => TRUE,
                                    id_prof_schedules_in       => NULL,
                                    id_prof_schedules_nin      => TRUE,
                                    flg_status_in              => NULL,
                                    flg_status_nin             => TRUE,
                                    id_prof_cancel_in          => NULL,
                                    id_prof_cancel_nin         => TRUE,
                                    schedule_notes_in          => NULL,
                                    schedule_notes_nin         => TRUE,
                                    id_cancel_reason_in        => NULL,
                                    id_cancel_reason_nin       => TRUE,
                                    id_lang_translator_in      => NULL,
                                    id_lang_translator_nin     => TRUE,
                                    id_lang_preferred_in       => NULL,
                                    id_lang_preferred_nin      => TRUE,
                                    id_sch_event_in            => NULL,
                                    id_sch_event_nin           => TRUE,
                                    id_reason_in               => NULL,
                                    id_reason_nin              => TRUE,
                                    id_origin_in               => NULL,
                                    id_origin_nin              => TRUE,
                                    id_room_in                 => NULL,
                                    id_room_nin                => TRUE,
                                    flg_urgency_in             => NULL,
                                    flg_urgency_nin            => TRUE,
                                    schedule_cancel_notes_in   => NULL,
                                    schedule_cancel_notes_nin  => TRUE,
                                    flg_notification_in        => i_flg_notif,
                                    flg_notification_nin       => TRUE,
                                    id_schedule_ref_in         => NULL,
                                    id_schedule_ref_nin        => TRUE,
                                    flg_vacancy_in             => NULL,
                                    flg_vacancy_nin            => TRUE,
                                    flg_sch_type_in            => NULL,
                                    flg_sch_type_nin           => TRUE,
                                    reason_notes_in            => NULL,
                                    reason_notes_nin           => TRUE,
                                    dt_begin_tstz_in           => NULL,
                                    dt_begin_tstz_nin          => TRUE,
                                    dt_cancel_tstz_in          => NULL,
                                    dt_cancel_tstz_nin         => TRUE,
                                    dt_end_tstz_in             => NULL,
                                    dt_end_tstz_nin            => TRUE,
                                    dt_request_tstz_in         => NULL,
                                    dt_request_tstz_nin        => TRUE,
                                    dt_schedule_tstz_in        => NULL,
                                    dt_schedule_tstz_nin       => TRUE,
                                    flg_instructions_in        => NULL,
                                    flg_instructions_nin       => TRUE,
                                    flg_schedule_via_in        => NULL,
                                    flg_schedule_via_nin       => TRUE,
                                    id_prof_notification_in    => i_id_prof_notif,
                                    id_prof_notification_nin   => TRUE,
                                    dt_notification_tstz_in    => i_flg_notif_date,
                                    dt_notification_tstz_nin   => TRUE,
                                    flg_notification_via_in    => l_flg_notif_via,
                                    flg_notification_via_nin   => TRUE,
                                    id_sch_consult_vacancy_in  => NULL,
                                    id_sch_consult_vacancy_nin => TRUE,
                                    flg_request_type_in        => NULL,
                                    flg_request_type_nin       => TRUE,
                                    id_episode_in              => NULL,
                                    id_episode_nin             => TRUE,
                                    id_schedule_recursion_in   => NULL,
                                    id_schedule_recursion_nin  => TRUE,
                                    create_user_in             => NULL,
                                    create_user_nin            => TRUE,
                                    create_time_in             => NULL,
                                    create_time_nin            => TRUE,
                                    create_institution_in      => NULL,
                                    create_institution_nin     => TRUE,
                                    update_user_in             => NULL,
                                    update_user_nin            => TRUE,
                                    update_time_in             => NULL,
                                    update_time_nin            => TRUE,
                                    update_institution_in      => NULL,
                                    update_institution_nin     => TRUE,
                                    flg_present_in             => NULL,
                                    flg_present_nin            => TRUE,
                                    id_multidisc_in            => NULL,
                                    id_multidisc_nin           => TRUE,
                                    id_sch_combi_detail_in     => NULL,
                                    id_sch_combi_detail_nin    => TRUE,
                                    flg_reason_type_in         => NULL,
                                    flg_reason_type_nin        => TRUE,
                                    handle_error_in            => TRUE);
                END IF;
            
                -- returns id_external_request associated to i_id_schedule
                g_error := 'UPDATE_NOTIF - PK_REF_EXT_SYS.GET_REFERRAL_ID with id_schedule=' || l_ids_sch_pfh(i);
                IF NOT pk_ref_ext_sys.get_referral_id(i_lang                => i_lang,
                                                      i_prof                => i_prof,
                                                      i_id_schedule         => l_ids_sch_pfh(i),
                                                      o_id_external_request => l_id_external_request,
                                                      o_error               => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            
                IF l_id_external_request IS NOT NULL
                THEN
                
                    g_error := 'CALL UPDATE_REFERRAL_STATUS';
                    IF i_flg_notif IN (pk_schedule.g_notification_conf, pk_schedule.g_notification_notif)
                    THEN
                        g_error := 'CALL PK_REF_EXT_SYS.SET_REF_NOTIFY';
                        IF NOT pk_ref_ext_sys.set_ref_notify(i_lang     => i_lang,
                                                             i_prof     => i_prof,
                                                             i_id_ref   => l_id_external_request,
                                                             i_schedule => l_ids_sch_pfh(i),
                                                             i_notes    => NULL, -- todo: add notes
                                                             i_date     => NULL, -- todo: add operation date
                                                             o_error    => o_error)
                        THEN
                            RAISE l_func_exception;
                        END IF;
                    
                    ELSIF i_flg_notif IN (pk_schedule.g_sched_flg_notif_pending)
                    THEN
                    
                        g_error := 'CALL PK_REF_EXT_SYS.SET_REF_SCHEDULE';
                        IF NOT pk_ref_ext_sys.set_ref_schedule(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_id_ref   => l_id_external_request,
                                                               i_schedule => l_ids_sch_pfh(i),
                                                               i_notes    => NULL, -- todo: add notes
                                                               i_episode  => NULL,
                                                               i_date     => NULL, -- todo: add operation date
                                                               o_error    => o_error)
                        THEN
                            RAISE l_func_exception;
                        END IF;
                    END IF;
                ELSE
                    NULL; -- Se nao existe P1, nao tem que actualizar o estado
                END IF;
            END IF;
        
            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. id_schedule = ' || l_ids_sch_pfh(i);
            pk_schedule_common.backup_all(i_id_sch    => l_ids_sch_pfh(i),
                                          i_dt_update => current_timestamp,
                                          i_id_prof_u => i_prof.id);
            i := l_ids_sch_pfh.next(i);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_notif;

    /*
    * notify person
    */
    FUNCTION notify_person
    (
        i_lang                 IN language.id_language%TYPE,
        i_flg_notification     IN schedule.flg_notification%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_flg_notification_via IN sys_domain.val%TYPE,
        i_id_professional      IN professional.id_professional%TYPE,
        i_dt_notification      IN schedule.dt_notification_tstz%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name VARCHAR2(32) := 'NOTIFY_PERSON';
    
    BEGIN
    
        g_error := 'CALL UPDATE SCHEDULE';
        UPDATE schedule s
           SET s.flg_notification     = i_flg_notification,
               s.dt_notification_tstz = i_dt_notification,
               s.id_prof_notification = i_id_professional,
               s.flg_notification_via = i_flg_notification_via
         WHERE id_schedule = i_id_schedule;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END notify_person;

    /*  set new notification status to Confirmed
    */
    FUNCTION set_notif_confirmed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN update_notif(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_sch_ext     => i_id_sch_ext,
                            i_id_patient     => i_id_patient,
                            i_flg_notif      => pk_schedule.g_sched_flg_notif_confirmed,
                            i_flg_notif_via  => NULL,
                            i_flg_notif_date => NULL,
                            i_id_prof_notif  => NULL,
                            o_error          => o_error);
    
    END set_notif_confirmed;

    /*  set new notification status to Not confirmed (it is a regression from status Confirmed
    */
    FUNCTION set_notif_unconfirmed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN update_notif(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_sch_ext     => i_id_sch_ext,
                            i_id_patient     => i_id_patient,
                            i_flg_notif      => pk_schedule.g_sched_flg_notif_notified,
                            i_flg_notif_via  => NULL,
                            i_flg_notif_date => NULL,
                            i_id_prof_notif  => NULL,
                            o_error          => o_error);
    
    END set_notif_unconfirmed;

    /*  set new notification status to Notified
    */
    FUNCTION set_notif_notified
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_sch_ext    IN NUMBER,
        i_id_patient    IN sch_group.id_patient%TYPE,
        i_flg_notif_via IN schedule.flg_notification_via%TYPE DEFAULT NULL,
        i_notif_date    IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_id_prof_notif IN schedule.id_prof_notification%TYPE DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN update_notif(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_sch_ext     => i_id_sch_ext,
                            i_id_patient     => i_id_patient,
                            i_flg_notif      => pk_schedule.g_sched_flg_notif_notified,
                            i_flg_notif_via  => i_flg_notif_via,
                            i_flg_notif_date => i_notif_date,
                            i_id_prof_notif  => i_id_prof_notif,
                            o_error          => o_error);
    END set_notif_notified;

    /*  set new notification status to Not notified
    */
    FUNCTION set_notif_pending
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN NUMBER,
        i_id_patient IN sch_group.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN update_notif(i_lang           => i_lang,
                            i_prof           => i_prof,
                            i_id_sch_ext     => i_id_sch_ext,
                            i_id_patient     => i_id_patient,
                            i_flg_notif      => pk_schedule.g_sched_flg_notif_pending,
                            i_flg_notif_via  => NULL,
                            i_flg_notif_date => NULL,
                            i_id_prof_notif  => NULL,
                            o_error          => o_error);
    END set_notif_pending;

    /* returns list of suitable professionals to be used in the waiting list search.
    * This list fills the 'recurso(s) humano(s)' combo box within the search screen.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_wl_type           can be S-surgery, B-bed, A-all, null-all
    * @param i_dt_begin            if not null only wl entries over this date are considered
    * @param i_dt_end             if not null only wl entries under this date are considered
    * @param i_ids_dcs            list of dcs to filter profs. NUll = all profs
    * @param o_result            output collection
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6
    * @since                      27-01-2010
    */
    FUNCTION get_wl_profs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_wl_type  IN VARCHAR2,
        i_dt_begin IN VARCHAR2,
        i_dt_end   IN VARCHAR2,
        i_ids_dcs  IN table_number,
        o_result   OUT t_wl_profs,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name    VARCHAR2(32) := 'GET_WL_PROFS';
        l_row          t_wl_prof := t_wl_prof(NULL, NULL);
        l_innercurrrow PLS_INTEGER := 0;
        l_list         pk_types.cursor_type;
        l_dt_begin     TIMESTAMP WITH TIME ZONE;
        l_dt_end       TIMESTAMP WITH TIME ZONE;
    BEGIN
    
        -- convert dates
        g_error := 'CALL STRING_TO_TSTZ FOR dt_begin';
        IF NOT string_to_tstz(i_lang, i_prof, i_dt_begin, l_dt_begin, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL STRING_TO_TSTZ FOR dt_end';
        IF NOT string_to_tstz(i_lang, i_prof, i_dt_end, l_dt_end, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET RESULT ROWS CURSOR';
        IF NOT pk_wtl_pbl_core.get_wl_profs(i_lang    => i_lang,
                                            i_prof    => i_prof,
                                            i_wl_type => i_wl_type,
                                            i_dt_dpb  => l_dt_begin,
                                            i_dt_dpa  => l_dt_end,
                                            i_ids_dcs => i_ids_dcs,
                                            o_result  => l_list,
                                            o_error   => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'VALIDATE CURSOR';
        IF l_list IS NULL
           OR NOT l_list%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'ITERATE & TRANSFORM';
        FETCH l_list BULK COLLECT
            INTO o_result;
        CLOSE l_list;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_wl_profs;

    /* returns list of schedule reasons to be shown when scheduling.
    * New 2014 MY
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_patient         needed by the native function
    * @param i_id_software       search field. IF null then all softwares are game. NOT the same as i_prof.software
    * @param i_text_search       search field. Used for text searches in the title and description fields
    * @param i_id_episode         needed by the native function
    * @param i_id_consult_req     needed by the native function
    * @param i_input_type         if not null, then this function only needs to return the translation for i_input_id
    * @param i_input_id           if not null, then this function only needs to return the translation for i_input_id
    * @param o_output            output collection 
    * @param o_output_type       R= reasons (sample texts + prof sample texts),  C= complaints
    * @param o_max_rows_exceeded if not null then the max rows limit was exceeded
    * @param o_error             error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.3
    * @since                      11-09-2013
    */
    FUNCTION get_schedule_reasons
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_software       IN software.id_software%TYPE,
        i_text_search       IN VARCHAR2,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_consult_req    IN consult_req.id_consult_req%TYPE,
        i_input_type        IN VARCHAR2 DEFAULT NULL,
        i_input_id          IN NUMBER DEFAULT NULL,
        o_output            OUT t_schedule_reasons,
        o_output_type       OUT VARCHAR2,
        o_max_rows_exceeded OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := $$PLSQL_UNIT;
        l_reasons         pk_types.cursor_type;
        l_reason_req      consult_req.reason_for_visit%TYPE;
        l_reason_ep       VARCHAR2(4000);
        l_schedule_reason t_schedule_reason;
        l_rownum          INTEGER := 1;
        l_max_rows        INTEGER;
        l_retval          BOOLEAN;
    
        FUNCTION inner_get_reasons RETURN BOOLEAN IS
            l_gender patient.gender%TYPE;
            l_age    NUMBER(3);
            l_cat    prof_cat.id_category%TYPE;
            CURSOR c_cat IS
                SELECT id_category
                  FROM prof_cat
                 WHERE id_professional = i_prof.id
                   AND id_institution = i_prof.institution;
        
        BEGIN
            -- this code is based upon function pk_schedule.get_schedule_reasons
            -- get reason specified in the requisition, if it exists
            IF i_id_consult_req IS NOT NULL
            THEN
                g_error := l_func_name || ' - CALL PK_CONSULT_REQ.GET_CONSULT_REQ_REASON FOR i_consult_req = ' ||
                           i_id_consult_req;
                IF NOT pk_consult_req.get_consult_req_reason(i_lang           => i_lang,
                                                             i_id_consult_req => i_id_consult_req,
                                                             o_reason         => l_reason_req,
                                                             o_error          => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
            -- get reason specified in the episode, if it exists
            IF i_id_episode IS NOT NULL
            THEN
                g_error     := l_func_name || ' - CALL PK_CLINICAL_INFO.GET_EPIS_REASON_FOR_VISIT FOR i_episode = ' ||
                               i_id_episode;
                l_reason_ep := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                           i_prof        => i_prof,
                                                                                                           i_id_episode  => i_id_episode,
                                                                                                           i_id_schedule => NULL),
                                                                4000);
            END IF;
        
            -- Get patient age and gender
            IF i_id_patient IS NOT NULL
            THEN
                BEGIN
                    g_error := l_func_name || ' - GET PATIENT AGE AND GENDER';
                    SELECT gender, nvl(months_between(current_timestamp, dt_birth) / 12, 0)
                      INTO l_gender, l_age
                      FROM patient
                     WHERE id_patient = i_id_patient;
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
            g_error := l_func_name || ' - OPEN CURSOR c_cat';
            OPEN c_cat;
            FETCH c_cat
                INTO l_cat;
            CLOSE c_cat;
        
            -- vou usar sql dinamico por motivo de performance. Quero eliminar os OR 
            g_error := l_func_name || ' - OPEN sys_reftype l_reasons';
        
            OPEN l_reasons FOR
                SELECT t_schedule_reason(aidi, title, text, order_field, origin, id_software)
                  FROM (
                         -- MOTIVO VISITA DA REQUISIÇAO. Se existir aparece no topo da lista
                         SELECT i_id_consult_req      aidi, -- o id e'' o da propria requisicao 
                                 l_reason_req          title,
                                 l_reason_req          text,
                                 2                     order_field,
                                 g_sch_reason_type_req origin,
                                 NULL                  id_software
                           FROM dual
                          WHERE l_reason_req IS NOT NULL
                         -- MOTIVO DA VISITA DO EPISODIO. Se existir aparece no topo da lista
                         UNION ALL -- estes union all melhoram a performance porque evitam um sort-unique no exec plan
                         SELECT i_id_episode, -- o id e' o do proprio episodio
                                l_reason_ep,
                                l_reason_ep,
                                2,
                                g_sch_reason_type_epi,
                                NULL
                          FROM dual
                         WHERE l_reason_ep IS NOT NULL
                        UNION ALL
                        SELECT *
                          FROM (
                                 -- MOTIVOS DA SAMPLE_TEXT
                                 SELECT st.id_sample_text aidi,
                                         pk_translation.get_translation(i_lang, st.code_title_sample_text) title,
                                         pk_translation.get_translation(i_lang, st.code_desc_sample_text) text,
                                         9 order_field,
                                         g_sch_reason_type_r origin,
                                         stt.id_software
                                   FROM sample_text_type stt
                                  INNER JOIN sample_text_soft_inst stsi
                                     ON stt.id_sample_text_type = stsi.id_sample_text_type
                                  INNER JOIN sample_text st
                                     ON st.id_sample_text = stsi.id_sample_text
                                  WHERE upper(stt.intern_name_sample_text_type) =
                                        upper(pk_schedule.g_complaint_sample_text_type)
                                    AND (i_id_software IS NULL OR stsi.id_software = i_id_software)
                                    AND st.flg_available = pk_alert_constant.g_yes
                                    AND stt.flg_available = pk_alert_constant.g_yes
                                    AND stsi.id_institution = i_prof.institution
                                    AND stsi.flg_available = pk_alert_constant.g_yes
                                    AND EXISTS (SELECT 1
                                           FROM sample_text_type_cat sttc
                                          WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                                            AND sttc.id_category = l_cat
                                            AND sttc.id_institution IN (0, i_prof.institution))
                                    AND ((l_gender IS NOT NULL AND nvl(st.gender, 'I') IN ('I', l_gender)) OR
                                         l_gender IS NULL OR l_gender = 'I')
                                    AND (nvl(l_age, 0) BETWEEN nvl(st.age_min, 0) AND
                                         nvl(st.age_max, nvl(l_age, 0)) OR nvl(l_age, 0) = 0)
                                 -- MOTIVOS DA SAMPLE_TEXT_PROF
                                 UNION ALL
                                 SELECT stf.id_sample_text_prof,
                                         stf.title_sample_text_prof,
                                         pk_string_utils.clob_to_sqlvarchar2(stf.desc_sample_text_prof),
                                         9,
                                         g_sch_reason_type_rp,
                                         stt.id_software
                                   FROM sample_text_type stt
                                  INNER JOIN sample_text_prof stf
                                     ON stt.id_sample_text_type = stf.id_sample_text_type
                                  WHERE upper(stt.intern_name_sample_text_type) =
                                        upper(pk_schedule.g_complaint_sample_text_type)
                                    AND (i_id_software IS NULL OR stf.id_software = i_id_software)
                                    AND stf.id_professional = i_prof.id
                                    AND stf.id_institution = i_prof.institution
                                    AND EXISTS (SELECT 1
                                           FROM sample_text_type_cat sttc
                                          WHERE sttc.id_sample_text_type = stt.id_sample_text_type
                                            AND sttc.id_category = l_cat
                                            AND sttc.id_institution IN (0, i_prof.institution))) t1
                         WHERE t1.title IS NOT NULL) w
                 WHERE TRIM(i_text_search) IS NULL
                    OR lower(w.title) LIKE '%' || lower(REPLACE(TRIM(i_text_search), ' ', '%')) || '%'
                    OR lower(w.text) LIKE '%' || lower(REPLACE(TRIM(i_text_search), ' ', '%')) || '%';
        
            RETURN TRUE;
        END inner_get_reasons;
    
        FUNCTION inner_get_complaints RETURN BOOLEAN IS
            l_max_sch_event NUMBER;
            l_id_event      sch_event.id_sch_event%TYPE;
            l_dcs_list      table_number;
            l_comp_type     VARCHAR2(10);
        BEGIN
            g_error := 'FIND DCS from schedule';
            BEGIN
                SELECT sh.id_sch_event
                  INTO l_id_event
                  FROM epis_info ei
                  JOIN schedule sh
                    ON ei.id_schedule = sh.id_schedule
                 WHERE ei.id_episode = i_id_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error    := 'FIND DCS from episode';
                    l_id_event := NULL;
            END;
        
            SELECT dcs.id_dep_clin_serv
              BULK COLLECT
              INTO l_dcs_list
              FROM dep_clin_serv dcs, clinical_service cli, prof_dep_clin_serv pdc, department dpt
             WHERE dcs.id_dep_clin_serv = pdc.id_dep_clin_serv
               AND pdc.id_professional = i_prof.id
               AND dcs.id_clinical_service = cli.id_clinical_service
               AND dcs.id_department = dcs.id_department
               AND cli.flg_available = pk_complaint.g_available
               AND dpt.id_department = dcs.id_department
               AND dpt.flg_available = pk_complaint.g_available
               AND dpt.id_institution = i_prof.institution
               AND pdc.flg_status = pk_complaint.g_selected;
        
            SELECT MAX(d.id_sch_event)
              INTO l_max_sch_event
              FROM doc_template_context d
             WHERE d.id_institution IN (i_prof.institution, 0)
               AND id_software = i_prof.software
               AND d.flg_type = pk_complaint.g_flg_type_ct
               AND (l_id_event IS NULL OR d.id_sch_event IN (l_id_event, 0))
               AND d.id_dep_clin_serv IN (SELECT *
                                            FROM TABLE(l_dcs_list));
        
            BEGIN
                SELECT CASE sc.value
                           WHEN 'PROFILE_TEMPLATE' THEN
                            pk_complaint.g_flg_type_c
                           WHEN 'DEP_CLIN_SERV' THEN
                            pk_complaint.g_flg_type_ct
                           ELSE
                            pk_complaint.g_flg_type_ct
                       END
                  INTO l_comp_type
                  FROM sys_config sc
                 WHERE sc.id_sys_config = 'COMPLAINT_FILTER'
                   AND sc.id_institution IN (0, i_prof.institution)
                   AND sc.id_software IN (0, i_prof.software);
            EXCEPTION
                WHEN no_data_found THEN
                    l_comp_type := pk_complaint.g_flg_type_ct;
            END;
        
            OPEN l_reasons FOR
                SELECT t_schedule_reason(tbl.id_complaint,
                                         tbl.desc_complaint,
                                         NULL,
                                         1,
                                         g_sch_reason_type_c,
                                         tbl.id_software)
                  FROM (SELECT c.id_complaint, --
                               pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                               ppt.id_software,
                               0 rank
                          FROM complaint c,
                               prof_profile_template ppt,
                               epis_complaint ec,
                               (SELECT d.id_context,
                                       MAX(d.id_institution) id_institution,
                                       d.id_software,
                                       d.id_dep_clin_serv,
                                       d.id_profile_template,
                                       d.flg_type,
                                       dcs.id_clinical_service
                                  FROM doc_template_context d, dep_clin_serv dcs
                                 WHERE d.id_institution IN (i_prof.institution, 0)
                                   AND dcs.id_dep_clin_serv = d.id_dep_clin_serv
                                   AND d.id_software = i_prof.software
                                   AND d.id_dep_clin_serv IN (SELECT *
                                                                FROM TABLE(l_dcs_list))
                                   AND (d.id_sch_event IS NULL OR d.id_sch_event = l_max_sch_event)
                                   AND d.flg_type = l_comp_type --pk_complaint.g_flg_type_ct
                                 GROUP BY id_context,
                                          id_software,
                                          d.id_dep_clin_serv,
                                          d.id_profile_template,
                                          d.flg_type,
                                          dcs.id_clinical_service) dtc2
                         WHERE c.id_complaint = dtc2.id_context
                           AND c.flg_available = pk_complaint.g_available
                              -- ligação ao profile_template
                           AND ppt.id_profile_template = dtc2.id_profile_template
                           AND ppt.id_professional = i_prof.id
                           AND ppt.id_institution = i_prof.institution
                              --                         AND ppt.id_software = i_prof.software -- para para o output
                              --ver se há queixa 
                           AND ec.id_complaint(+) = dtc2.id_context
                           AND ec.id_episode(+) = i_id_episode
                           AND ec.flg_status(+) = pk_complaint.g_active) tbl
                 WHERE tbl.desc_complaint IS NOT NULL
                   AND lower(tbl.desc_complaint) LIKE
                       '%' || lower(REPLACE(TRIM(nvl(i_text_search, tbl.desc_complaint)), ' ', '%')) || '%'
                 GROUP BY tbl.id_complaint, tbl.desc_complaint, tbl.id_software, tbl.rank
                 ORDER BY rank, desc_complaint;
        
            RETURN TRUE;
        END inner_get_complaints;
    
        PROCEDURE inner_add_row(i_rou t_schedule_reason) IS
        BEGIN
            o_output.extend;
            o_output(o_output.last) := i_rou;
        END inner_add_row;
    
    BEGIN
    
        -- If it is being asked only one id, get it and leave
        IF i_input_type IS NOT NULL
           AND i_input_id IS NOT NULL
        THEN
            o_output_type := i_input_type;
        
            CASE i_input_type
                WHEN g_sch_reason_type_r THEN
                    g_error := l_func_name || ' - GET REASON FOR id_sample_text = ' || i_input_id;
                    OPEN l_reasons FOR
                        SELECT t_schedule_reason(st.id_sample_text,
                                                 pk_translation.get_translation(i_lang, st.code_title_sample_text),
                                                 pk_translation.get_translation(i_lang, st.code_desc_sample_text),
                                                 NULL,
                                                 g_sch_reason_type_r,
                                                 NULL)
                          FROM sample_text st
                         WHERE st.id_sample_text = i_input_id;
                WHEN g_sch_reason_type_rp THEN
                    g_error := l_func_name || ' - GET PROFESSIONAL REASON FOR id_sample_text_prof = ' || i_input_id;
                    OPEN l_reasons FOR
                        SELECT t_schedule_reason(stp.id_sample_text_prof,
                                                 stp.title_sample_text_prof,
                                                 pk_string_utils.clob_to_sqlvarchar2(stp.desc_sample_text_prof),
                                                 NULL,
                                                 g_sch_reason_type_rp,
                                                 NULL)
                          FROM sample_text_prof stp
                         WHERE stp.id_sample_text_prof = i_input_id;
                WHEN g_sch_reason_type_c THEN
                    g_error := l_func_name || ' - GET COMPLAINT FOR id_complaint = ' || i_input_id;
                    OPEN l_reasons FOR
                        SELECT t_schedule_reason(c.id_complaint,
                                                 pk_translation.get_translation(i_lang, c.code_complaint),
                                                 NULL,
                                                 NULL,
                                                 g_sch_reason_type_c,
                                                 NULL)
                          FROM complaint c
                         WHERE c.id_complaint = i_input_id;
                WHEN g_sch_reason_type_req THEN
                    g_error := l_func_name || ' - GET REASON FOR id_consult_req = ' || i_input_id;
                    IF NOT pk_consult_req.get_consult_req_reason(i_lang           => i_lang,
                                                                 i_id_consult_req => i_input_id,
                                                                 o_reason         => l_reason_req,
                                                                 o_error          => o_error)
                    THEN
                        RETURN FALSE;
                    END IF;
                
                    OPEN l_reasons FOR
                        SELECT t_schedule_reason(i_input_id, l_reason_req, NULL, NULL, g_sch_reason_type_req, NULL)
                          FROM dual;
                WHEN g_sch_reason_type_epi THEN
                    g_error     := l_func_name || ' - CALL PK_CLINICAL_INFO.GET_EPIS_REASON_FOR_VISIT FOR i_episode = ' ||
                                   i_id_episode;
                    l_reason_ep := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                               i_prof        => i_prof,
                                                                                                               i_id_episode  => i_input_id,
                                                                                                               i_id_schedule => NULL),
                                                                    4000);
                
                    OPEN l_reasons FOR
                        SELECT t_schedule_reason(i_input_id, l_reason_ep, NULL, NULL, g_sch_reason_type_epi, NULL)
                          FROM dual;
                ELSE
                    pk_types.open_my_cursor(l_reasons);
            END CASE;
        
        ELSE
            -- it is being asked to return the full list - give'm the whole nine yards
            g_error  := 'GET ' || g_sch_reasons_config || ' FROM SYS_CONFIG';
            l_retval := pk_sysconfig.get_config(g_sch_reasons_config, i_prof, o_output_type);
            IF NOT l_retval
               OR o_output_type IS NULL
            THEN
                pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => 'Null value or inexistent key ' || g_sch_reasons_config ||
                                                                ' in SYS_CONFIG',
                                                  i_message  => g_error,
                                                  i_owner    => g_package_owner,
                                                  i_package  => g_package_name,
                                                  i_function => l_func_name,
                                                  o_error    => o_error);
                RETURN FALSE;
            END IF;
        
            -- get sys config max rows
            g_error := 'GET ' || g_sch_reasons_max_rows || ' FROM SYS_CONFIG';
            IF NOT pk_sysconfig.get_config(g_sch_reasons_max_rows, i_prof, l_max_rows)
            THEN
                l_max_rows := g_sch_reasons_max_rows_safe;
            END IF;
        
            -- na sys_config so' temos 2 origens possiveis. 'C' para complaints e 'R' para todas as reasons sample_texts
            IF o_output_type = g_sch_reason_type_r
            THEN
                IF NOT inner_get_reasons
                THEN
                    RETURN FALSE;
                END IF;
            ELSIF o_output_type = g_sch_reason_type_c
            THEN
                IF NOT inner_get_complaints
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- validate data existance
        g_error := 'VALIDATE CURSOR';
        IF l_reasons IS NULL
           OR NOT l_reasons%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        o_output := t_schedule_reasons();
    
        -- iterate and package
        g_error := 'ITERATE & TRANSFORM';
        WHILE l_rownum <= l_max_rows
        LOOP
            FETCH l_reasons
                INTO l_schedule_reason;
            EXIT WHEN l_reasons%NOTFOUND;
            inner_add_row(l_schedule_reason);
            l_rownum := l_rownum + 1;
        END LOOP;
        CLOSE l_reasons;
    
        IF l_rownum > l_max_rows
        THEN
            -- FILL OUTPUT WARNING MSG
            IF NOT pk_schedule.replace_tokens(i_lang         => i_lang,
                                              i_string       => pk_message.get_message(i_lang      => i_lang,
                                                                                       i_code_mess => g_sched_msg_max_rows),
                                              i_tokens       => table_varchar('@1'),
                                              i_replacements => table_varchar(to_char(l_max_rows)),
                                              o_string       => o_max_rows_exceeded,
                                              o_error        => o_error)
            THEN
                RETURN FALSE;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_schedule_reasons;

    /** Gets scheduled details */
    FUNCTION get_schedule_details
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_schedule      IN schedule.id_schedule%TYPE,
        o_schedule_details OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(32) := 'GET_SCHEDULE_DETAILS';
        l_id_schedule_ext schedule.id_schedule%TYPE;
    BEGIN
    
        g_error := 'Get schedule ID';
        IF NOT get_schedule_id_ext(i_lang        => i_lang,
                                   i_id_schedule => i_id_schedule,
                                   o_id_schedule => l_id_schedule_ext,
                                   o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN o_schedule_details FOR';
        -- Open cursor
        OPEN o_schedule_details FOR
            SELECT pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_vacancy_domain, s.flg_vacancy) desc_type,
                   pk_schedule.string_date(i_lang, i_prof, s.dt_begin_tstz) || ' ' ||
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_begin_tstz, g_default_time_mask_msg) desc_time,
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_end_tstz, g_default_time_mask_msg) end_time,
                   pk_schedule.string_duration(i_lang, s.dt_begin_tstz, s.dt_end_tstz) desc_duration,
                   pk_schedule.string_room(i_lang, s.id_room) desc_room,
                   pk_schedule.get_domain_desc(i_lang, pk_schedule.g_schedule_flg_status_domain, s.flg_status) desc_status,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, s.id_prof_schedules) desc_scheduling_prof,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    s.id_prof_schedules,
                                                    s.dt_schedule_tstz,
                                                    s.id_episode) desc_spec_sch_prof,
                   s.dt_schedule_tstz dt_schedule,
                   s.schedule_notes notes,
                   pk_schedule.string_language(i_lang, s.id_lang_preferred) desc_lang_preferred,
                   pk_schedule.string_language(i_lang, s.id_lang_translator) desc_lang_translator,
                   pk_schedule.string_origin(i_lang, s.id_origin) desc_origin,
                   CASE
                        WHEN s.id_reason IS NOT NULL THEN
                         pk_schedule.string_reason(i_lang, i_prof, s.id_reason, s.flg_reason_type)
                        ELSE
                         s.reason_notes
                    END desc_reason,
                   s.id_cancel_reason,
                   pk_translation.get_translation(1, 'SCH_CANCEL_REASON.CODE_CANCEL_REASON.' || s.id_cancel_reason) ||
                   chr(13) || s.schedule_cancel_notes AS schedule_cancel_notes,
                   s.flg_schedule_via,
                   s.flg_request_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, s.id_prof_cancel) author_cancel,
                   pk_date_utils.dt_chr_tsz(i_lang, s.dt_schedule_tstz, i_prof.institution, i_prof.software) schedule_date,
                   pk_date_utils.to_char_insttimezone(i_prof, s.dt_schedule_tstz, g_default_time_mask_msg) schedule_time,
                   pk_schedule.string_clin_serv_by_dcs(i_lang, s.id_dcs_requested) dcs_description,
                   pk_schedule.string_sch_event(i_lang, s.id_sch_event) event_description,
                   s.id_lang_translator,
                   s.id_lang_preferred,
                   s.id_reason,
                   s.id_origin,
                   s.id_room,
                   s.id_episode,
                   s.flg_vacancy,
                   s.flg_request_type,
                   s.flg_schedule_via,
                   scv.max_vacancies AS max_vacancies
              FROM schedule s, schedule_outp so, sch_consult_vacancy scv
             WHERE s.id_schedule = l_id_schedule_ext
               AND so.id_schedule(+) = s.id_schedule
               AND s.id_sch_consult_vacancy = scv.id_sch_consult_vacancy(+);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_schedule_details);
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END get_schedule_details;

    /*  finishes an exam/other exam schedule by setting the associated exam requisition.
    *    the workflow is: choose exams in imaging software -> choose to schedule them -> scheduler opens ->
    *    each schedule created is replicated in PFH via integration code, with status = V (temporary) ->
    *    close scheduler -> ok button pressed -> create requisitions -> confirm pending schedule up and down ->
    *    associate down schedule with requisitions
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext          external schedule id
    * @param i_id_patient          scheduled patient
    * @param i_ids_exam            list of exam ids
    * @param i_ids_exam_req        list of exam req ids
    * @param o_error               error data
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.6
    * @date    20-04-2010
    */
    FUNCTION set_schedule_exam_reqs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sch_ext   IN sch_api_map_ids.id_schedule_ext%TYPE,
        i_id_patient   IN patient.id_patient%TYPE,
        i_ids_exam     IN table_number,
        i_ids_exam_req IN table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ids_sch_pfh          table_number;
        l_id_pat               sch_group.id_patient%TYPE;
        i                      PLS_INTEGER;
        j                      PLS_INTEGER;
        l_ids_sch_not_found    EXCEPTION;
        l_diff_count_exam_reqs EXCEPTION;
        l_func_exception       EXCEPTION;
        l_flg_preparation      VARCHAR2(1 CHAR); --exam.flg_pat_prep%TYPE;
        l_prep_desc            sys_domain.desc_val%TYPE;
        l_func_name            VARCHAR2(32) := 'SET_SCHEDULE_EXAM_REQS';
        l_dt_begin             VARCHAR2(200);
    BEGIN
    
        -- get internal ids
        g_error       := 'SET_SCHEDULE_EXAM_REQS - GET PFH ID';
        l_ids_sch_pfh := get_pfh_ids(i_id_sch_ext);
    
        -- iterar ids agendamentos locais
        IF l_ids_sch_pfh IS NOT NULL
           AND l_ids_sch_pfh.count > 0
        THEN
            i := l_ids_sch_pfh.first;
            WHILE i IS NOT NULL
            LOOP
                BEGIN
                    -- obter paciente deste agendamento local
                    g_error := 'SET_SCHEDULE_EXAM_REQS - GET PATIENT ID';
                    SELECT id_patient
                      INTO l_id_pat
                      FROM sch_group sg
                     WHERE sg.id_schedule = l_ids_sch_pfh(i)
                       AND sg.id_patient = i_id_patient
                       AND rownum = 1;
                
                    -- obter paciente deste agendamento local
                    g_error := 'SET_SCHEDULE_EXAM_REQS - GET PATIENT ID';
                    SELECT pk_date_utils.date_send_tsz(i_lang, dt_begin_tstz, i_prof)
                      INTO l_dt_begin
                      FROM schedule s
                     WHERE s.id_schedule = l_ids_sch_pfh(i);
                
                    -- fazer update dos exames pertencentes a este ag. local com os ids das reqs passados
                    IF i_ids_exam IS NOT NULL
                       AND i_ids_exam.count > 0
                       AND i_ids_exam_req IS NOT NULL
                       AND i_ids_exam_req.count = i_ids_exam.count
                    THEN
                    
                        j := i_ids_exam.first;
                        WHILE j IS NOT NULL
                        LOOP
                        
                            -- Check if the exam needs the patient to perform any preparation steps.
                            g_error := 'SET_SCHEDULE_EXAM_REQS - PK_SCHEDULE_EXAM.HAS_PREPARATION';
                            IF NOT pk_schedule_exam.has_preparation(i_lang      => i_lang,
                                                                    i_id_exam   => i_ids_exam(j),
                                                                    o_flg_prep  => l_flg_preparation,
                                                                    o_prep_desc => l_prep_desc,
                                                                    o_error     => o_error)
                            THEN
                                RAISE l_func_exception;
                            END IF;
                        
                            -- main update
                            g_error := 'SET_SCHEDULE_EXAM_REQS - TS_SCHEDULE_EXAM.UPD';
                            ts_schedule_exam.upd(id_schedule_in         => NULL,
                                                 id_schedule_nin        => TRUE,
                                                 id_exam_in             => NULL,
                                                 id_exam_nin            => TRUE,
                                                 flg_preparation_in     => l_flg_preparation,
                                                 flg_preparation_nin    => TRUE,
                                                 id_exam_req_in         => i_ids_exam_req(j),
                                                 id_exam_req_nin        => TRUE,
                                                 create_user_in         => NULL,
                                                 create_user_nin        => TRUE,
                                                 create_time_in         => NULL,
                                                 create_time_nin        => TRUE,
                                                 create_institution_in  => NULL,
                                                 create_institution_nin => TRUE,
                                                 update_user_in         => pk_prof_utils.get_name_signature(i_lang,
                                                                                                            i_prof,
                                                                                                            i_prof.id),
                                                 update_user_nin        => FALSE,
                                                 update_time_in         => g_sysdate_tstz,
                                                 update_time_nin        => FALSE,
                                                 update_institution_in  => i_prof.institution,
                                                 update_institution_nin => FALSE,
                                                 where_in               => 'id_schedule = ' || l_ids_sch_pfh(i) ||
                                                                           ' and id_exam = ' || i_ids_exam(j),
                                                 handle_error_in        => FALSE);
                        
                            -- settar data do agendamento na req.
                            g_error := 'SET_SCHEDULE_EXAM_REQS - PK_EXAMS_API_DB.SET_EXAM_DATE';
                            IF NOT pk_exams_api_db.set_exam_date(i_lang            => i_lang,
                                                                 i_prof            => i_prof,
                                                                 i_exam_req        => i_ids_exam_req(j),
                                                                 i_dt_begin        => l_dt_begin,
                                                                 i_notes_scheduler => NULL,
                                                                 o_error           => o_error)
                            THEN
                                RAISE l_func_exception;
                            END IF;
                        
                            j := i_ids_exam.next(j);
                        END LOOP;
                    
                    ELSE
                        RAISE l_diff_count_exam_reqs;
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        -- nao encontrou o paciente fornecido neste agendamento local -> nao pertence a este ag.
                        l_id_pat := NULL;
                END;
            
                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || l_ids_sch_pfh(i);
                pk_schedule_common.backup_all(i_id_sch    => l_ids_sch_pfh(i),
                                              i_dt_update => current_timestamp,
                                              i_id_prof_u => i_prof.id);
                i := l_ids_sch_pfh.next(i);
            END LOOP;
        
        ELSE
            RAISE l_ids_sch_not_found;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_diff_count_exam_reqs THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -20032,
                                              i_sqlerrm  => 'O número de exames fornecido difere do número de requisições fornecido',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_ids_sch_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -20033,
                                              i_sqlerrm  => 'O id do agendamento externo ' || i_id_sch_ext ||
                                                            ' fornecido não tem agendamentos locais',
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_schedule_exam_reqs;

    /* check if there is a row in appointment table for specified event and clinical service
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_sch_event       event id
    * @param i_id_clin_service    clinical service id
    *
    * @RETURN  Y / N
    *
    * @author  Telmo
    * @version 2.6
    * @since   23-04-2010
    */
    FUNCTION get_appointment_exists
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_sch_event    IN appointment.id_sch_event%TYPE,
        i_id_clin_service IN appointment.id_clinical_service%TYPE
    ) RETURN VARCHAR2 IS
        l_retval VARCHAR2(1);
        o_error  t_error_out;
    BEGIN
        g_error := 'GET_APPOINTMENT_EXISTS';
        SELECT pk_alert_constant.g_yes
          INTO l_retval
          FROM appointment a
         WHERE a.id_sch_event = i_id_sch_event
           AND a.id_clinical_service = i_id_clin_service
           AND a.flg_available = pk_alert_constant.g_yes
           AND rownum = 1;
    
        RETURN l_retval;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN pk_alert_constant.g_no;
            -- nao tem when others para o invocador saber se isto deu erro
    END get_appointment_exists;

    /* function to be used as data source for the intf_alert service that will feed the
    *  status combo box in the scheduler waiting list search window.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses
    * @param o_result             output collection made of t search_status cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      01-06-2010
    */
    FUNCTION get_search_status
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_statuses,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_rec1 IS RECORD(
            data        VARCHAR2(20),
            label       VARCHAR2(200),
            flg_select  VARCHAR2(1),
            order_field NUMBER);
        l_rec t_rec1;
    
        l_func_name     VARCHAR2(32) := 'GET_SEARCH_STATUS';
        l_row           t_search_status;
        l_innercurrrow  PLS_INTEGER := 0;
        l_list          pk_types.cursor_type;
        l_invalid_scope EXCEPTION;
    
        PROCEDURE inner_add_row(i_rou t_search_status) IS
        BEGIN
            o_result.extend;
            o_result(o_result.last) := i_rou;
        END inner_add_row;
    
    BEGIN
    
        g_error := 'FORK search scope';
        CASE i_search_scope
            WHEN g_search_scope_inp THEN
                g_error := 'GET_SEARCH_STATUS - CALL PK_SCHEDULE_INP.GET_SURGERY_STATUS';
                IF NOT pk_schedule_inp.get_surgery_status(i_lang   => i_lang,
                                                          i_prof   => i_prof,
                                                          o_status => l_list,
                                                          o_error  => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            WHEN g_search_scope_surg THEN
                g_error := 'GET_SEARCH_STATUS - CALL PK_SCHEDULE_ORIS.GET_REQUISITION_STATUS';
                IF NOT pk_schedule_oris.get_requisition_status(i_lang => i_lang, o_status => l_list, o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                RAISE l_invalid_scope;
        END CASE;
    
        g_error := 'VALIDATE CURSOR';
        IF l_list IS NULL
           OR NOT l_list%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        o_result := t_search_statuses();
    
        g_error := 'ITERATE & TRANSFORM';
        LOOP
            FETCH l_list
                INTO l_rec;
            EXIT WHEN l_list%NOTFOUND;
            IF l_rec.data <> '-10'
            THEN
                l_row.id          := l_rec.data;
                l_row.description := l_rec.label;
                inner_add_row(l_row);
            END IF;
        END LOOP;
        CLOSE l_list;
        RETURN TRUE;
    EXCEPTION
        WHEN l_invalid_scope THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -25005,
                                              i_sqlerrm  => 'invalid i_search_scope value ' || i_search_scope,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_search_status;

    /* function to be used as data source for the intf_alert service that will feed the
    *  responsible professional (inp=admission physicians; surg=pref surgeons) combo box in the scheduler waiting list search window.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_inst           search in this institutions
    * @param i_id_dcs             dcs where to look. can be null
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses  C= outp appointments
    * @param o_result             output collection made of t search_status cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      04-06-2010
    */
    FUNCTION get_search_profs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ids_inst     IN table_number,
        i_id_dcs       IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_profs,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_rec1 IS RECORD(
            data        NUMBER(24),
            label       VARCHAR2(4000),
            flg_select  VARCHAR2(1),
            order_field NUMBER(9));
        l_rec t_rec1;
    
        TYPE t_rec2 IS RECORD(
            data        NUMBER(24),
            label       VARCHAR2(4000),
            flg_select  VARCHAR2(1),
            order_field NUMBER(9),
            addict_info CLOB);
        l_rec2 t_rec2;
    
        l_func_name     VARCHAR2(32) := 'GET_SEARCH_PROFS';
        l_row           t_search_prof := t_search_prof(NULL, NULL);
        l_innercurrrow  PLS_INTEGER := 0;
        l_list          pk_types.cursor_type;
        l_invalid_scope EXCEPTION;
    
        PROCEDURE inner_add_row(i_rou t_search_prof) IS
        BEGIN
            o_result.extend;
            o_result(o_result.last) := i_rou;
        END inner_add_row;
    BEGIN
        g_error := 'FORK search scope';
        CASE i_search_scope
            WHEN g_search_scope_inp THEN
                g_error := 'GET_SEARCH_PROFS - CALL PK_SCHEDULE_INP.GET_PHYSICIANS';
                IF NOT pk_schedule_inp.get_physicians(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_locations => i_ids_inst,
                                                      o_data      => l_list,
                                                      o_error     => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            WHEN g_search_scope_surg THEN
                g_error := 'GET_SEARCH_PROFS - CALL PK_SURGERY_REQUEST.GET_SURGEONS_BY_DEP_CLIN_SERV';
                IF NOT pk_surgery_request.get_surgeons_by_dep_clin_serv(i_lang     => i_lang,
                                                                   i_prof     => i_prof,
                                                                   i_inst     => (CASE
                                                                                     WHEN i_ids_inst IS NOT NULL
                                                                                          AND i_ids_inst.count > 0 THEN
                                                                                      i_ids_inst(1)
                                                                                     ELSE
                                                                                      NULL
                                                                                 END),
                                                                   i_id_dcs   => i_id_dcs,
                                                                   o_surgeons => l_list,
                                                                   o_error    => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            WHEN g_search_scope_cons THEN
                g_error := 'GET_SEARCH_PROFS - GET CONSULT PHYSICIANS';
                OPEN l_list FOR
                    SELECT p.id_professional,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, p.id_professional) name_prof,
                           NULL,
                           NULL
                      FROM professional p
                     WHERE EXISTS (SELECT 0
                              FROM prof_dep_clin_serv pdcs
                              JOIN prof_institution pi
                                ON (pi.id_professional = pdcs.id_professional)
                              JOIN dep_clin_serv dcs
                                ON (pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv)
                              JOIN department d
                                ON (d.id_department = dcs.id_department AND d.id_institution = pi.id_institution)
                             WHERE d.id_institution IN (SELECT column_value
                                                          FROM TABLE(i_ids_inst))
                               AND pdcs.id_professional = p.id_professional
                               AND pdcs.flg_status = 'S'
                               AND pi.flg_state = pk_alert_constant.g_active
                               AND pk_prof_utils.get_category(i_lang,
                                                              profissional(p.id_professional,
                                                                           pi.id_institution,
                                                                           pk_alert_constant.g_soft_outpatient)) =
                                   pk_alert_constant.g_cat_type_doc
                               AND instr(d.flg_type, 'C') > 0)
                     ORDER BY name_prof;
            ELSE
                RAISE l_invalid_scope;
        END CASE;
    
        g_error := 'VALIDATE CURSOR';
        IF l_list IS NULL
           OR NOT l_list%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        o_result := t_search_profs();
    
        g_error := 'ITERATE & TRANSFORM';
        IF i_search_scope = g_search_scope_surg
        THEN
            LOOP
                FETCH l_list
                    INTO l_rec2;
                EXIT WHEN l_list%NOTFOUND;
                IF l_rec2.data <> '-10'
                THEN
                    l_row.id   := l_rec2.data;
                    l_row.name := l_rec2.label;
                    inner_add_row(l_row);
                END IF;
            END LOOP;
        ELSE
            LOOP
                FETCH l_list
                    INTO l_rec;
                EXIT WHEN l_list%NOTFOUND;
                IF l_rec.data <> '-10'
                THEN
                    l_row.id   := l_rec.data;
                    l_row.name := l_rec.label;
                    inner_add_row(l_row);
                END IF;
            END LOOP;
        END IF;
        CLOSE l_list;
        RETURN TRUE;
    EXCEPTION
        WHEN l_invalid_scope THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -25005,
                                              i_sqlerrm  => 'invalid i_search_scope value ' || i_search_scope,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_search_profs;

    /* function to be used as data source for the intf_alert service that will feed the
    *  services combo box in the scheduler waiting list search window. A service is a department
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_ids_inst           search in this institutions
    * @param i_search_scope       IN= inpatient statuses  S= surgery statuses  C= outp appointments
    * @param o_result             output collection made of t search_status cells
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      04-06-2010
    */
    FUNCTION get_search_services
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_ids_inst     IN table_number,
        i_search_scope IN VARCHAR2,
        o_result       OUT t_search_services,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_rec1 IS RECORD(
            id          NUMBER(24),
            description VARCHAR2(4000));
        l_rec t_rec1;
    
        l_func_name     VARCHAR2(32) := 'GET_SEARCH_SERVICES';
        l_row           t_search_service;
        l_innercurrrow  PLS_INTEGER := 0;
        l_list          pk_types.cursor_type;
        l_invalid_scope EXCEPTION;
    
        -- inner proc
        PROCEDURE inner_add_row(i_rou t_search_service) IS
        BEGIN
            o_result.extend;
            o_result(o_result.last) := i_rou;
        END inner_add_row;
    
        -- inner function for type C and S
        FUNCTION inner_get_dep_list
        (
            i_flg_type   IN VARCHAR2,
            o_department OUT pk_types.cursor_type,
            o_error      OUT t_error_out
        ) RETURN BOOLEAN IS
            l_exists NUMBER(1) := 1;
        BEGIN
            g_error := 'GET_SEARCH_SERVICES - CALL INNER_GET_DEP_LIST WITH FLG_TYPE = ' || i_flg_type;
        
            IF i_ids_inst IS NULL
               OR i_ids_inst.count = 0
            THEN
                l_exists := 0;
            END IF;
        
            g_error := 'GET CURSOR';
            OPEN o_department FOR
                SELECT id_department, pk_translation.get_translation(i_lang, code_department) department
                  FROM department d
                 WHERE (l_exists = 0 OR
                       (d.id_institution IN (SELECT *
                                                FROM TABLE(i_ids_inst))))
                   AND regexp_instr(d.flg_type, i_flg_type) > 0
                   AND d.flg_available = pk_alert_constant.g_available
                 ORDER BY department;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_func_name || ' (INNER_GET_DEP_LIST)',
                                                  o_error);
                RETURN FALSE;
        END inner_get_dep_list;
    
        -- inner function for type E
        FUNCTION inner_get_dep_list_ex
        (
            o_department OUT pk_types.cursor_type,
            o_error      OUT t_error_out
        ) RETURN BOOLEAN IS
            l_exists NUMBER(1) := 1;
        BEGIN
            g_error := 'GET_SEARCH_SERVICES - CALL INNER_GET_DEP_LIST_EX';
        
            IF i_ids_inst IS NULL
               OR i_ids_inst.count = 0
            THEN
                l_exists := 0;
            END IF;
        
            g_error := 'GET CURSOR';
            OPEN o_department FOR
                SELECT DISTINCT r.id_department, pk_translation.get_translation(i_lang, code_department) department
                  FROM exam_room er
                  JOIN room r
                    ON er.id_room = r.id_room
                  JOIN department d
                    ON r.id_department = d.id_department
                 WHERE (l_exists = 0 OR
                       (d.id_institution IN (SELECT *
                                                FROM TABLE(i_ids_inst))))
                   AND r.flg_available = pk_alert_constant.g_yes
                   AND r.flg_status = pk_alert_constant.g_active
                   AND d.flg_available = pk_alert_constant.g_available
                   AND er.flg_available = pk_alert_constant.g_available
                 ORDER BY department;
        
            RETURN TRUE;
        
        EXCEPTION
            WHEN OTHERS THEN
                pk_alert_exceptions.process_error(i_lang,
                                                  SQLCODE,
                                                  SQLERRM,
                                                  g_error,
                                                  g_package_owner,
                                                  g_package_name,
                                                  l_func_name || ' (INNER_GET_DEP_LIST_EX)',
                                                  o_error);
                RETURN FALSE;
        END inner_get_dep_list_ex;
    
    BEGIN
    
        g_error := 'FORK search scope';
        CASE i_search_scope
            WHEN g_search_scope_inp THEN
                g_error := 'GET_SEARCH_SERVICES - CALL PK_ADMISSION_REQUEST.GET_DEPARTMENT_LIST';
                -- FUNÇAO NOVA AQUI. DEVE SER OVERLOAD DA pk_admission_request.get_department_list QUE ACEITE N INSTITS OU NULL
                IF NOT pk_admission_request.get_department_list(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_ids_inst   => i_ids_inst,
                                                                o_department => l_list,
                                                                o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            WHEN g_search_scope_surg THEN
                IF NOT inner_get_dep_list(i_flg_type => g_search_scope_surg, o_department => l_list, o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            WHEN g_search_scope_cons THEN
                --flg_type 'C' for Outpatient events and flg_type 'M' for Physiotherapy events
                IF NOT inner_get_dep_list(i_flg_type   => (g_search_scope_cons || '|' || g_search_scope_phys),
                                          o_department => l_list,
                                          o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            WHEN g_search_scope_exam THEN
                IF NOT inner_get_dep_list_ex(o_department => l_list, o_error => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            WHEN 'PR' THEN
                IF NOT inner_get_dep_list(i_flg_type   => (g_search_scope_cons || '|' || g_search_scope_phys || '|' ||
                                                          g_search_scope_surg || '|' || g_search_scope_inp),
                                          o_department => l_list,
                                          o_error      => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            ELSE
                RAISE l_invalid_scope;
        END CASE;
    
        g_error := 'VALIDATE CURSOR';
        IF l_list IS NULL
           OR NOT l_list%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        o_result := t_search_services();
    
        g_error := 'ITERATE & TRANSFORM';
        LOOP
            FETCH l_list
                INTO l_rec;
            EXIT WHEN l_list%NOTFOUND;
            IF l_rec.id <> -10
            THEN
                l_row.id          := l_rec.id;
                l_row.description := l_rec.description;
                inner_add_row(l_row);
            END IF;
        END LOOP;
    
        CLOSE l_list;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_invalid_scope THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -25005,
                                              i_sqlerrm  => 'invalid i_search_scope value ' || i_search_scope,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_search_services;

    -- nova versao deve substituir a que esta acima
    FUNCTION get_search_adm_indics
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_id_cs  IN dep_clin_serv.id_clinical_service%TYPE,
        o_result OUT t_search_adm_indics,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        TYPE t_rec1 IS RECORD(
            id          NUMBER(24),
            description VARCHAR2(4000));
        l_rec          t_rec1;
        l_func_name    VARCHAR2(32) := 'GET_SEARCH_ADM_INDICS';
        l_row          t_search_adm_indic;
        l_innercurrrow PLS_INTEGER := 0;
        l_list         pk_types.cursor_type;
    
        PROCEDURE inner_add_row(i_rou t_search_adm_indic) IS
        BEGIN
            o_result.extend;
            o_result(o_result.last) := i_rou;
        END inner_add_row;
    BEGIN
    
        o_result := t_search_adm_indics();
    
        IF i_id_cs IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'GET_SEARCH_ADM_INDICS - CALL PK_ADMISSION_REQUEST.GET_ADM_INDICATION_LIST';
        IF NOT pk_admission_request.get_adm_indication_list(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_clin_serv   => i_id_cs,
                                                            o_indications => l_list,
                                                            o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'VALIDATE CURSOR';
        IF l_list IS NULL
           OR NOT l_list%ISOPEN
        THEN
            RETURN TRUE;
        END IF;
    
        g_error := 'ITERATE & TRANSFORM';
        LOOP
            FETCH l_list
                INTO l_rec;
            EXIT WHEN l_list%NOTFOUND;
            IF l_rec.id <> '-10'
            THEN
                l_row.id          := l_rec.id;
                l_row.description := l_rec.description;
                inner_add_row(l_row);
            END IF;
        END LOOP;
        CLOSE l_list;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_search_adm_indics;

    /*  universal function for returning the detail of a requisition. Requisitions can be of several types
    * and for that reason return different details. The waiting list is also present here.
    * Output is a collection of sections. Each one has its own detail - pairs field name - field value.
    *
    * @param i_lang               Language identifier
    * @param i_prof               Professional data: id, institution and software
    * @param i_id_req             requisition id. varchar because requisition come from several places and have different datatypes
    * @param i_req_type           req. type. Identifies where and how to get the data
    * @param o_result             output structured as a collection of types
    * @param o_error              error info
    *
    * @return                     true / false
    *
    * @author                     Telmo
    * @version                    2.6.0.3
    * @since                      06-07-2010
    */
    FUNCTION get_req_detail
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_id_req   IN VARCHAR2,
        i_req_type IN VARCHAR2,
        o_result   OUT t_detail,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(200) := 'GET_REQ_DETAIL';
        l_invalid_type    EXCEPTION;
        l_cur             pk_types.cursor_type;
        l_sections        t_sections;
        l_section         t_section;
        l_section_details t_section_details;
        l_section_detail  t_section_detail;
        l_dep_type_group  sch_dep_type.dep_type_group%TYPE;
    
        -- adicionar section_detail na collection l_section_details
        PROCEDURE inner_add_section_detail
        (
            i_colname  VARCHAR2,
            i_colvalue VARCHAR2
        ) IS
        BEGIN
            IF i_colname IS NULL -- atencao nao fazer aqui TRIM do i_colname
            THEN
                RETURN;
            END IF;
            l_section_detail.col_name  := i_colname;
            l_section_detail.col_value := i_colvalue;
            IF l_section_details IS NULL
            THEN
                l_section_details := t_section_details(l_section_detail);
            ELSE
                l_section_details.extend;
                l_section_details(l_section_details.last) := l_section_detail;
            END IF;
        END inner_add_section_detail;
    
        -- adicionar section na collection l_sections
        PROCEDURE inner_add_section
        (
            i_title           VARCHAR2,
            i_section_details t_section_details
        ) IS
        BEGIN
            l_section.title           := i_title;
            l_section.section_details := i_section_details;
        
            IF l_sections IS NULL
            THEN
                l_sections := t_sections(l_section);
            ELSE
                l_sections.extend;
                l_sections(l_sections.last) := l_section;
            END IF;
        END inner_add_section;
    
        -- PHYSICIAN & DERIVATIVES INNER FUNCTION
        FUNCTION inner_get_c_detail RETURN BOOLEAN IS
            TYPE t_row IS RECORD(
                inst_req_to    table_varchar,
                dep_clin_serv  table_varchar,
                sch_event      table_varchar,
                prof_req_to    table_varchar,
                complaint      table_varchar,
                event_date     table_varchar,
                priority       table_varchar,
                contact_type   table_varchar,
                notes          table_varchar,
                instructions   table_clob,
                room           table_varchar,
                request_type   table_varchar,
                req_resp       table_varchar,
                lang           table_varchar,
                approval_prof  table_varchar,
                request_reason table_varchar,
                recurrence     table_varchar,
                frequency      table_varchar,
                dt_rec_begin   table_varchar,
                dt_rec_end     table_varchar,
                nr_event       table_varchar,
                week_day       table_varchar,
                week_nr        table_varchar,
                month_day      table_varchar,
                month_nr       table_varchar,
                status         table_varchar,
                cancel_notes   table_varchar,
                cancel_reason  table_varchar,
                registered     table_varchar);
        
            l_row   t_row;
            l_dummy pk_types.cursor_type;
        BEGIN
            -- get detail data
            g_error := 'GET_REQ_DETAIL - CALL PK_EVENTS.GET_EVENT_GENERAL';
            IF NOT pk_events.get_event_general(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_consult_req => i_id_req,
                                               o_req_det     => l_dummy,
                                               o_event       => l_cur,
                                               o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- get main title for detail screen
            g_error        := 'GET title FOR i_req_type = ' || i_req_type;
            o_result.title := pk_message.get_message(i_lang, 'SCH_T205');
        
            -- validate cursor
            g_error := 'VALIDATE cursor l_cur';
            IF l_cur IS NULL
               OR NOT l_cur%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM';
            FETCH l_cur
                INTO l_row;
            IF NOT l_cur%NOTFOUND
            THEN
                IF l_row.inst_req_to IS NOT NULL
                   AND l_row.inst_req_to.count >= 3
                THEN
                    inner_add_section_detail(l_row.inst_req_to(2), l_row.inst_req_to(3));
                END IF;
                IF l_row.dep_clin_serv IS NOT NULL
                   AND l_row.dep_clin_serv.count >= 3
                THEN
                    inner_add_section_detail(l_row.dep_clin_serv(2), l_row.dep_clin_serv(3));
                END IF;
                IF l_row.sch_event IS NOT NULL
                   AND l_row.sch_event.count >= 3
                THEN
                    inner_add_section_detail(l_row.sch_event(2), l_row.sch_event(3));
                END IF;
                IF l_row.prof_req_to IS NOT NULL
                   AND l_row.prof_req_to.count >= 3
                THEN
                    inner_add_section_detail(l_row.prof_req_to(2), l_row.prof_req_to(3));
                END IF;
                IF l_row.complaint IS NOT NULL
                   AND l_row.complaint.count >= 3
                THEN
                    inner_add_section_detail(l_row.complaint(2), l_row.complaint(3));
                END IF;
                IF l_row.event_date IS NOT NULL
                   AND l_row.event_date.count >= 3
                THEN
                    inner_add_section_detail(l_row.event_date(2), l_row.event_date(3));
                END IF;
                IF l_row.priority IS NOT NULL
                   AND l_row.priority.count >= 3
                THEN
                    inner_add_section_detail(l_row.priority(2), l_row.priority(3));
                END IF;
                IF l_row.contact_type IS NOT NULL
                   AND l_row.contact_type.count >= 3
                THEN
                    inner_add_section_detail(l_row.contact_type(2), l_row.contact_type(3));
                END IF;
                IF l_row.notes IS NOT NULL
                   AND l_row.notes.count >= 3
                THEN
                    inner_add_section_detail(l_row.notes(2), l_row.notes(3));
                END IF;
                IF l_row.instructions IS NOT NULL
                   AND l_row.instructions.count >= 3
                THEN
                    inner_add_section_detail(l_row.instructions(2), l_row.instructions(3));
                END IF;
                IF l_row.room IS NOT NULL
                   AND l_row.room.count >= 3
                THEN
                    inner_add_section_detail(l_row.room(2), l_row.room(3));
                END IF;
                IF l_row.request_type IS NOT NULL
                   AND l_row.request_type.count >= 3
                THEN
                    inner_add_section_detail(l_row.request_type(2), l_row.request_type(3));
                END IF;
                IF l_row.req_resp IS NOT NULL
                   AND l_row.req_resp.count >= 3
                THEN
                    inner_add_section_detail(l_row.req_resp(2), l_row.req_resp(3));
                END IF;
                IF l_row.lang IS NOT NULL
                   AND l_row.lang.count >= 3
                THEN
                    inner_add_section_detail(l_row.lang(2), l_row.lang(3));
                END IF;
                IF l_row.approval_prof IS NOT NULL
                   AND l_row.approval_prof.count >= 3
                THEN
                    inner_add_section_detail(l_row.approval_prof(2), l_row.approval_prof(3));
                END IF;
                IF l_row.request_reason IS NOT NULL
                   AND l_row.request_reason.count >= 3
                THEN
                    inner_add_section_detail(l_row.request_reason(2), l_row.request_reason(3));
                END IF;
                IF l_row.recurrence IS NOT NULL
                   AND l_row.recurrence.count >= 3
                THEN
                    inner_add_section_detail(l_row.recurrence(2), l_row.recurrence(3));
                END IF;
                IF l_row.frequency IS NOT NULL
                   AND l_row.frequency.count >= 3
                THEN
                    inner_add_section_detail(l_row.frequency(2), l_row.frequency(3));
                END IF;
                IF l_row.dt_rec_begin IS NOT NULL
                   AND l_row.dt_rec_begin.count >= 3
                THEN
                    inner_add_section_detail(l_row.dt_rec_begin(2), l_row.dt_rec_begin(3));
                END IF;
                IF l_row.dt_rec_end IS NOT NULL
                   AND l_row.dt_rec_end.count >= 3
                THEN
                    inner_add_section_detail(l_row.dt_rec_end(2), l_row.dt_rec_end(3));
                END IF;
                IF l_row.nr_event IS NOT NULL
                   AND l_row.nr_event.count >= 3
                THEN
                    inner_add_section_detail(l_row.nr_event(2), l_row.nr_event(3));
                END IF;
                IF l_row.week_day IS NOT NULL
                   AND l_row.week_day.count >= 3
                THEN
                    inner_add_section_detail(l_row.week_day(2), l_row.week_day(3));
                END IF;
                IF l_row.week_nr IS NOT NULL
                   AND l_row.week_nr.count >= 3
                THEN
                    inner_add_section_detail(l_row.week_nr(2), l_row.week_nr(3));
                END IF;
                IF l_row.month_day IS NOT NULL
                   AND l_row.month_day.count >= 3
                THEN
                    inner_add_section_detail(l_row.month_day(2), l_row.month_day(3));
                END IF;
                IF l_row.month_nr IS NOT NULL
                   AND l_row.month_nr.count >= 3
                THEN
                    inner_add_section_detail(l_row.month_nr(2), l_row.month_nr(3));
                END IF;
                IF l_row.status IS NOT NULL
                   AND l_row.status.count >= 3
                THEN
                    inner_add_section_detail(l_row.status(2), l_row.status(3));
                END IF;
                IF l_row.cancel_notes IS NOT NULL
                   AND l_row.cancel_notes.count >= 3
                THEN
                    inner_add_section_detail(l_row.cancel_notes(2), l_row.cancel_notes(3));
                END IF;
                IF l_row.cancel_reason IS NOT NULL
                   AND l_row.cancel_reason.count >= 3
                THEN
                    inner_add_section_detail(l_row.cancel_reason(2), l_row.cancel_reason(3));
                END IF;
                IF l_row.registered IS NOT NULL
                   AND l_row.registered.count >= 3
                THEN
                    inner_add_section_detail(l_row.registered(2), l_row.registered(3));
                END IF;
            
            END IF;
            CLOSE l_cur;
        
            -- pack it up
            l_section.title           := '';
            l_section.section_details := l_section_details;
            o_result.sections         := t_sections(l_section);
        
            RETURN TRUE;
        END inner_get_c_detail;
    
        -- LAB REQ DETAIL INNER FUNCTION 
        FUNCTION inner_get_a_detail RETURN BOOLEAN IS
            TYPE t_order IS RECORD(
                id_analysis_req NUMBER,
                registry        VARCHAR2(32767),
                num_order       VARCHAR2(32767),
                priority        VARCHAR2(32767),
                desc_status     VARCHAR2(32767),
                desc_time       VARCHAR2(32767),
                desc_analysis   CLOB,
                cancel_reason   VARCHAR2(32767),
                notes_cancel    VARCHAR2(32767),
                dt_ord          VARCHAR2(32767));
            l_order t_order;
        
            TYPE t_barcode IS RECORD(
                id_analysis_req NUMBER,
                barcode         VARCHAR2(32767));
            l_barcode t_barcode;
        
            l_cur_order   pk_types.cursor_type;
            l_cur_barcode pk_types.cursor_type;
            l_cur_history pk_types.cursor_type;
        
        BEGIN
            -- get detail data
            g_error := 'GET_REQ_DETAIL - CALL PK_LAB_TESTS_API_DB.GET_LAB_TEST_ORDER_DETAIL with i_analysis_req=' ||
                       i_id_req;
            IF NOT pk_lab_tests_api_db.get_lab_test_order_detail(i_lang                   => i_lang,
                                                                 i_prof                   => i_prof,
                                                                 i_analysis_req           => i_id_req,
                                                                 o_lab_test_order         => l_cur_order,
                                                                 o_lab_test_order_barcode => l_cur_barcode,
                                                                 o_lab_test_order_history => l_cur_history,
                                                                 o_error                  => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- validate cursor 
            g_error := 'VALIDATE cursor l_cur_order';
            IF l_cur_order IS NULL
               OR NOT l_cur_order%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- validate cursor 
            g_error := 'VALIDATE cursor l_cur_barcode';
            IF l_cur_barcode IS NULL
               OR NOT l_cur_barcode%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform barcode fields. These will go into the main section as simple fields
            g_error := 'ITERATE & TRANSFORM CURSOR l_cur_barcode';
            FETCH l_cur_barcode
                INTO l_barcode;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM CURSOR l_cur_order';
            FETCH l_cur_order
                INTO l_order;
        
            IF NOT l_cur_order%NOTFOUND
            THEN
                --prioridade
                inner_add_section_detail(regexp_substr(l_order.priority, '</?.+>'),
                                         substr(l_order.priority,
                                                regexp_instr(l_order.priority, '</.+>') +
                                                length(regexp_substr(l_order.priority, '</.+>')),
                                                40000));
                --estado
                inner_add_section_detail(regexp_substr(l_order.desc_status, '</?.+>'),
                                         substr(l_order.desc_status,
                                                regexp_instr(l_order.desc_status, '</.+>') +
                                                length(regexp_substr(l_order.desc_status, '</.+>')),
                                                40000));
                --para executar
                inner_add_section_detail(regexp_substr(l_order.desc_time, '</?.+>'),
                                         substr(l_order.desc_time,
                                                regexp_instr(l_order.desc_time, '</.+>') +
                                                length(regexp_substr(l_order.desc_time, '</.+>')),
                                                40000));
                --analise(s)
                inner_add_section_detail(regexp_substr(l_order.desc_analysis, '</?.+>'),
                                         substr(l_order.desc_analysis,
                                                regexp_instr(l_order.desc_analysis, '</.+>') +
                                                length(regexp_substr(l_order.desc_analysis, '</.+>')),
                                                40000));
            
                -- barcode
                IF NOT l_cur_barcode%NOTFOUND
                THEN
                    inner_add_section_detail(l_barcode.barcode, '');
                    --                 inner_add_section_detail(regexp_substr(l_barcode.barcode, '</?.+>'), 
                    --                                          substr(l_barcode.barcode, regexp_instr(l_barcode.barcode, '</.+>') + length(regexp_substr(l_barcode.barcode, '</.+>')), 40000));
                END IF;
            
                -- registado. este nao tem label
                inner_add_section_detail(l_order.registry, ''); -- coloquei o valor no parametro da label senao nao aparece
            
                --titulo principal e titulo da seccao
                l_section.title           := pk_message.get_message(i_lang, 'LAB_TESTS_T067');
                l_section.section_details := l_section_details;
                o_result.sections         := t_sections(l_section);
                o_result.title            := l_order.num_order;
            END IF;
            -- close cursors
            CLOSE l_cur_order;
            CLOSE l_cur_barcode;
        
            RETURN TRUE;
        END inner_get_a_detail;
    
        -- EXAM REQ DETAIL INNER FUNCTION
        FUNCTION inner_get_e_detail RETURN BOOLEAN IS
            TYPE t_order IS RECORD(
                id_exam_req   NUMBER,
                registry      VARCHAR2(32767),
                num_order     VARCHAR2(32767),
                priority      VARCHAR2(32767),
                desc_status   VARCHAR2(32767),
                desc_time     VARCHAR2(32767),
                desc_exam     CLOB,
                cancel_reason VARCHAR2(32767),
                notes_cancel  VARCHAR2(32767),
                dt_ord        VARCHAR2(32767));
            l_order t_order;
        
            TYPE t_barcode IS RECORD(
                id_analysis_req NUMBER,
                barcode         VARCHAR2(32767));
            l_barcode t_barcode;
        
            l_cur_order   pk_types.cursor_type;
            l_cur_barcode pk_types.cursor_type;
            l_cur_history pk_types.cursor_type;
            l_id_exam_req exam_req_det.id_exam_req%TYPE;
        
        BEGIN
            BEGIN
                SELECT er.id_exam_req
                  INTO l_id_exam_req
                  FROM exam_req_det er
                 WHERE er.id_exam_req_det = i_id_req;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_exam_req := i_id_req;
            END;
        
            -- get detail data
            g_error := 'GET_REQ_DETAIL - CALL PK_EXAMS_API_DB.GET_DET_EXAM';
            IF NOT pk_exams_api_db.get_exam_order_detail(i_lang               => i_lang,
                                                         i_prof               => i_prof,
                                                         i_exam_req           => l_id_exam_req,
                                                         o_exam_order         => l_cur_order,
                                                         o_exam_order_barcode => l_cur_barcode,
                                                         o_exam_order_history => l_cur_history,
                                                         o_error              => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error        := 'GET title FOR i_req_type = ' || i_req_type;
            o_result.title := pk_message.get_message(i_lang, 'EXAM_REQ_T016');
        
            -- validate cursor 
            g_error := 'VALIDATE cursor l_cur_order';
            IF l_cur_order IS NULL
               OR NOT l_cur_order%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- validate cursor 
            g_error := 'VALIDATE cursor l_cur_barcode';
            IF l_cur_barcode IS NULL
               OR NOT l_cur_barcode%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform barcode fields. These will go into the main section as simple fields
            g_error := 'ITERATE & TRANSFORM CURSOR l_cur_barcode';
            FETCH l_cur_barcode
                INTO l_barcode;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM CURSOR l_cur_order';
            FETCH l_cur_order
                INTO l_order;
        
            IF NOT l_cur_order%NOTFOUND
            THEN
                --prioridade
                inner_add_section_detail(regexp_substr(l_order.priority, '</?.+>'),
                                         substr(l_order.priority,
                                                regexp_instr(l_order.priority, '</.+>') +
                                                length(regexp_substr(l_order.priority, '</.+>')),
                                                40000));
                --estado
                inner_add_section_detail(regexp_substr(l_order.desc_status, '</?.+>'),
                                         substr(l_order.desc_status,
                                                regexp_instr(l_order.desc_status, '</.+>') +
                                                length(regexp_substr(l_order.desc_status, '</.+>')),
                                                40000));
                --para executar
                inner_add_section_detail(regexp_substr(l_order.desc_time, '</?.+>'),
                                         substr(l_order.desc_time,
                                                regexp_instr(l_order.desc_time, '</.+>') +
                                                length(regexp_substr(l_order.desc_time, '</.+>')),
                                                40000));
                --exame(s)
                inner_add_section_detail(regexp_substr(l_order.desc_exam, '</?.+>'),
                                         substr(l_order.desc_exam,
                                                regexp_instr(l_order.desc_exam, '</.+>') +
                                                length(regexp_substr(l_order.desc_exam, '</.+>')),
                                                40000));
            
                -- barcode
                IF NOT l_cur_barcode%NOTFOUND
                THEN
                    inner_add_section_detail(l_barcode.barcode, '');
                    --                 inner_add_section_detail(regexp_substr(l_barcode.barcode, '</?.+>'), 
                    --                                          substr(l_barcode.barcode, regexp_instr(l_barcode.barcode, '</.+>') + length(regexp_substr(l_barcode.barcode, '</.+>')), 40000));
                END IF;
            
                -- registado. este nao tem label
                inner_add_section_detail(l_order.registry, ''); -- coloquei o valor no parametro da label senao nao aparece
            
                --titulo principal e titulo da seccao
                l_section.title           := pk_message.get_message(i_lang, 'EXAMS_T022');
                l_section.section_details := l_section_details;
                o_result.sections         := t_sections(l_section);
                o_result.title            := l_order.num_order;
            END IF;
            -- close cursors
            CLOSE l_cur_order;
            CLOSE l_cur_barcode;
        
            RETURN TRUE;
        END inner_get_e_detail;
    
        -- OTHER EXAM REQ DETAIL INNER FUNCTION
        FUNCTION inner_get_x_detail RETURN BOOLEAN IS
        BEGIN
        
            g_error        := 'GET title FOR i_req_type = ' || i_req_type;
            o_result.title := pk_message.get_message(i_lang, 'EXAM_REQ_T018');
        
            RETURN TRUE;
        END inner_get_x_detail;
    
        -- WAITING LIST REQ DETAIL INNER FUNCTION
        FUNCTION inner_get_wl_detail RETURN BOOLEAN IS
            l_dummy pk_types.cursor_type;
        
            CURSOR l_cur IS
                SELECT t.*, wl.flg_type
                  FROM wtl_adm_surg_tmptab t
                  JOIN waiting_list wl
                    ON t.id_wtlist = wl.id_waiting_list
                 ORDER BY id_wtlist, ordem;
        
            l_rec l_cur%ROWTYPE;
        BEGIN
        
            o_result.title := ''; -- nao descobri qualquer titulo na pesquisa na wl
        
            -- get detail data (outsourcing)
            g_error := 'TRUNCATE TEMPORARY TABLE';
            EXECUTE IMMEDIATE 'TRUNCATE TABLE wtl_adm_surg_tmptab';
        
            g_error := 'GET RAW DATA';
            IF NOT pk_wtl_pbl_core.get_wtlist_summary(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_id_wtlist => i_id_req,
                                                      o_data      => l_dummy,
                                                      o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            g_error := 'OPEN l_cur CURSOR';
            OPEN l_cur;
            LOOP
                FETCH l_cur
                    INTO l_rec;
                EXIT WHEN l_cur%NOTFOUND;
            
                IF l_rec.id_label = -1
                THEN
                    -- primeiro finaliza bloco anterior
                    IF l_section_details IS NOT NULL
                    THEN
                        inner_add_section(l_section.title, l_section_details);
                    END IF;
                    -- depois inicia novo bloco
                    l_section.title   := l_rec.bloco;
                    l_section_details := NULL;
                ELSIF l_rec.id_label IN (pk_wtl_prv_core.ix_out_id_regim,
                                         pk_wtl_prv_core.ix_out_id_benef,
                                         pk_wtl_prv_core.ix_out_id_precau,
                                         pk_wtl_prv_core.ix_out_id_contact)
                THEN
                    inner_add_section_detail(pk_translation.get_translation(i_lang,
                                                                            pk_wtl_prv_core.ix_out_names(l_rec.id_label)),
                                             l_rec.data);
                ELSIF l_rec.id_label NOT IN (pk_wtl_prv_core.ix_out_id_adm_service,
                                             pk_wtl_prv_core.ix_out_id_adm_type,
                                             pk_wtl_prv_core.ix_out_id_room_type,
                                             pk_wtl_prv_core.ix_out_id_bed_type,
                                             pk_wtl_prv_core.ix_out_id_pref_room)
                THEN
                    -- novo par field name, field value
                    IF (pk_utils.get_institution_market(i_lang, i_prof.institution) = 12 --CHILE
                       AND l_rec.id_label NOT IN (pk_wtl_prv_core.ix_out_room_type,
                                                   pk_wtl_prv_core.ix_out_mix_nurs,
                                                   pk_wtl_prv_core.ix_out_pref_room,
                                                   pk_wtl_prv_core.ix_out_nurs_int_need,
                                                   pk_wtl_prv_core.ix_out_nurs_int_loc,
                                                   pk_wtl_prv_core.ix_out_sugg_int_date,
                                                   pk_wtl_prv_core.ix_out_dang_contam,
                                                   pk_wtl_prv_core.ix_out_pref_time,
                                                   pk_wtl_prv_core.ix_out_pref_time_reason,
                                                   pk_wtl_prv_core.ix_out_adm_date,
                                                   -- pk_wtl_prv_core.ix_out_unav_start,
                                                   -- pk_wtl_prv_core.ix_out_duration,
                                                   pk_wtl_prv_core.ix_out_dt_surgery))
                    THEN
                        g_error := 'TRANSFORM DATA TO t_search_wl_result_rows FORM';
                        inner_add_section_detail(get_message(i_lang,
                                                             i_prof,
                                                             pk_wtl_prv_core.ix_out_names(l_rec.id_label)),
                                                 l_rec.data);
                    ELSIF (pk_utils.get_institution_market(16, i_prof.institution) <> 12)
                    THEN
                        g_error := 'TRANSFORM DATA TO t_search_wl_result_rows FORM';
                        inner_add_section_detail(get_message(i_lang,
                                                             i_prof,
                                                             pk_wtl_prv_core.ix_out_names(l_rec.id_label)),
                                                 l_rec.data);
                    
                    END IF;
                END IF;
            END LOOP;
            CLOSE l_cur;
        
            -- finalizar ultimo bloco porque ficou em aberto
            inner_add_section(l_section.title, l_section_details);
        
            -- compor output final
            o_result.sections := l_sections;
        
            RETURN TRUE;
        END inner_get_wl_detail;
    
        -- REFERRAL REQ DETAIL INNER FUNCTION
        FUNCTION inner_get_r_detail RETURN BOOLEAN IS
            l_detail           pk_ref_core.row_detail_cur;
            l_text             pk_types.cursor_type;
            l_problem          pk_types.cursor_type;
            l_diagnosis        pk_types.cursor_type;
            l_mcdt             pk_types.cursor_type;
            l_needs            pk_types.cursor_type;
            l_info             pk_types.cursor_type;
            l_notes_status     pk_types.cursor_type;
            l_notes_status_det pk_types.cursor_type;
            l_answer           pk_types.cursor_type;
            l_title_status     VARCHAR2(200);
            l_can_cancel       VARCHAR2(200);
            l_editable         VARCHAR2(200);
            l_ref_orig_data    pk_types.cursor_type;
            i                  PLS_INTEGER;
        
            l_row_detail pk_ref_core.t_row_detail_rec;
        
            TYPE t_row_notes IS RECORD(
                id_tracking NUMBER,
                title       VARCHAR2(200),
                text        VARCHAR2(200),
                prof_name   VARCHAR2(200),
                prof_spec   VARCHAR2(200),
                dt_insert   VARCHAR2(200),
                dt          VARCHAR2(200));
        
            l_row_notes t_row_notes;
        
            TYPE t_row_notes_det IS RECORD(
                rank        NUMBER,
                id_tracking NUMBER,
                title       VARCHAR2(200),
                text        VARCHAR2(200));
        
            l_row_notes_det t_row_notes_det;
        
            TYPE t_rows_notes_det IS TABLE OF t_row_notes_det;
        
            l_rows_notes_det t_rows_notes_det;
        
            TYPE t_row_needs IS RECORD(
                label_group   VARCHAR2(200),
                label         VARCHAR2(200),
                id_task       NUMBER,
                desc_task     VARCHAR2(200),
                flg_task_done VARCHAR2(1),
                dt_insert     VARCHAR2(200),
                prof_name     VARCHAR2(200),
                prof_spec     VARCHAR2(200),
                flg_status    VARCHAR2(1),
                id_group      NUMBER,
                id_task_done  NUMBER);
        
            l_row_needs t_row_needs;
        
            TYPE t_row_info IS RECORD(
                label_group   VARCHAR2(200),
                label         VARCHAR2(200),
                id_task       NUMBER,
                desc_task     VARCHAR2(200),
                flg_task_done VARCHAR2(1),
                dt_insert     VARCHAR2(200),
                prof_name     VARCHAR2(200),
                prof_spec     VARCHAR2(200),
                flg_status    VARCHAR2(1),
                id_group      NUMBER,
                id_task_done  NUMBER);
            l_row_info t_row_info;
        
        BEGIN
        
            -- get detail data
            g_error := 'GET_REQ_DETAIL - CALL pk_ref_ext_sys.GET_REFERRAL';
            IF NOT pk_ref_ext_sys.get_referral(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_id_ext_req    => i_id_req,
                                               i_status_detail => NULL,
                                               -- i_flg_labels       => 'N',
                                               o_detail           => l_detail,
                                               o_text             => l_text,
                                               o_problem          => l_problem,
                                               o_diagnosis        => l_diagnosis,
                                               o_mcdt             => l_mcdt,
                                               o_needs            => l_needs,
                                               o_info             => l_info,
                                               o_notes_status     => l_notes_status,
                                               o_notes_status_det => l_notes_status_det,
                                               o_answer           => l_answer,
                                               o_ref_orig_data    => l_ref_orig_data,
                                               o_title_status     => l_title_status,
                                               --o_editable         => l_editable,
                                               o_can_cancel => l_can_cancel,
                                               o_error      => o_error)
            THEN
                pk_alertlog.log_error(text => g_error, object_name => g_package_name, owner => g_package_owner);
                RETURN FALSE;
            END IF;
        
            -- obter titulo principal
            g_error        := 'GET title FOR i_req_type = ' || i_req_type;
            o_result.title := pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T078');
        
            -- SECCAO 'PEDIDO'
            -- obter titulo da seccao
            g_error         := 'GET title FOR section PEDIDO';
            l_section.title := pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T069');
        
            -- validate cursor
            g_error := 'VALIDATE cursor l_detail';
            IF l_detail IS NULL
               OR NOT l_detail%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM l_detail';
            FETCH l_detail
                INTO l_row_detail;
        
            IF NOT l_detail%NOTFOUND
            THEN
                inner_add_section_detail(l_row_detail.label_referral_number || ' ', l_row_detail.num_req);
                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_INFO_T002') || ' ', l_row_detail.dt_p1);
                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_EXT_SYS_T004') || ' ',
                                         l_row_detail.prof_name_request || ' (' || l_row_detail.prof_spec_request || ')');
                inner_add_section_detail(l_row_detail.label_spec || ' ', l_row_detail.spec_name);
                IF l_row_detail.sub_spec_name IS NOT NULL
                   AND l_row_detail.label_sub_spec IS NOT NULL
                THEN
                    inner_add_section_detail(l_row_detail.label_sub_spec || ' ', l_row_detail.sub_spec_name);
                END IF;
                inner_add_section_detail(l_row_detail.label_institution || ' ',
                                         l_row_detail.inst_abbrev || ' - ' || l_row_detail.inst_name);
                inner_add_section_detail(l_row_detail.inst_type_label || ' ', l_row_detail.type_ins);
                inner_add_section_detail(l_row_detail.ref_line_label || ' ', l_row_detail.ref_line);
                inner_add_section_detail(l_row_detail.wait_days_label || ' ', l_row_detail.wait_days);
                inner_add_section_detail(l_row_detail.label_home || ' ', l_row_detail.desc_home);
                inner_add_section_detail(l_row_detail.label_priority || ' ', l_row_detail.desc_priority);
                inner_add_section_detail(l_row_detail.label_status || ' ',
                                         l_row_detail.desc_status || '(' || l_row_detail.dt_elapsed || ')');
            END IF;
            CLOSE l_detail;
        
            IF l_section_details IS NOT NULL
               AND l_section_details.count > 0
            THEN
                l_section.section_details := l_section_details;
                o_result.sections         := t_sections(l_section);
            END IF;
        
            -- SECCAO 'NECESSIDADES ADICIONAIS' (aqui sao 2 cursores)
            -- obter titulo da seccao
            g_error         := 'GET title FOR section NECESSIDADES ADICIONAIS';
            l_section.title := pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T057');
        
            -- limpar seccao anterior
            l_section_details := NULL;
        
            -- validate cursor
            g_error := 'VALIDATE cursor l_needs';
            IF l_needs IS NULL
               OR NOT l_needs%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM l_needs';
            LOOP
                FETCH l_needs
                    INTO l_row_needs;
                EXIT WHEN l_needs%NOTFOUND;
            
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T001') || ': ',
                --                                         l_row_needs.dt_insert);
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_EXT_SYS_T004') || ': ',
                --                                         l_row_needs.prof_name || ' (' || l_row_needs.prof_spec || ')');
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T034') || ': ',
                --                                         l_row_needs.prof_spec);
                inner_add_section_detail(l_row_needs.label || ': ', l_row_needs.desc_task);
            END LOOP;
            CLOSE l_needs;
        
            -- validate cursor
            g_error := 'VALIDATE cursor l_info';
            IF l_info IS NULL
               OR NOT l_info%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- extract and transform detail fields
            g_error := 'ITERATE & TRANSFORM l_info';
            LOOP
                FETCH l_info
                    INTO l_row_info;
                EXIT WHEN l_info%NOTFOUND;
            
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T001') || ': ',
                --                                         l_row_info.dt_insert);
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_EXT_SYS_T004') || ': ',
                --                                         l_row_info.prof_name || ' (' || l_row_info.prof_spec || ')');
                --                inner_add_section_detail(pk_message.get_message(i_lang, 'P1_DOCTOR_REQ_T034') || ': ',
                --                                         l_row_info.prof_spec);
                inner_add_section_detail(l_row_info.label || ': ', l_row_info.desc_task);
            END LOOP;
            CLOSE l_info;
        
            IF l_section_details IS NOT NULL
               AND l_section_details.count > 0
            THEN
                l_section.section_details := l_section_details;
                o_result.sections.extend;
                o_result.sections(o_result.sections.last) := l_section;
            END IF;
            RETURN TRUE;
        
        END inner_get_r_detail;
    
        -- TRIALS DETAIL
        FUNCTION inner_get_t_detail RETURN BOOLEAN IS
            l_trial        pk_types.cursor_type;
            l_responsibles pk_types.cursor_type;
            l_title        sys_message.desc_message%TYPE;
            i              PLS_INTEGER;
        
            TYPE t_row_trial IS RECORD(
                id_trial   NUMBER,
                trial_name table_varchar,
                trial_code table_varchar);
        
            l_row_trial t_row_trial;
        
            TYPE t_row_responsible IS RECORD(
                id_trial       NUMBER,
                title          table_varchar,
                responsible    table_varchar,
                contact_first  table_varchar,
                contact_second table_varchar);
        
            l_row_responsible t_row_responsible;
        
            TYPE t_rows_responsible IS TABLE OF t_row_responsible;
        
            l_rows_responsible t_rows_responsible;
        
            l_resp_title_shown BOOLEAN := FALSE;
        
        BEGIN
            -- get detail data
            g_error := 'GET_REQ_DETAIL - CALL PK_TRIALS.GET_PAT_TRIALS';
            IF NOT pk_trials.get_pat_trials_details(i_lang        => i_lang,
                                                    i_prof        => i_prof,
                                                    i_id_patient  => i_id_req,
                                                    o_trial       => l_trial,
                                                    o_responsible => l_responsibles,
                                                    o_error       => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            -- validate cursor
            g_error := 'VALIDATE cursor l_trial';
            IF l_trial IS NULL
               OR NOT l_trial%ISOPEN
            THEN
                RETURN FALSE;
            END IF;
        
            -- collect all responsibles data right away - because i need to iterate it more than once
            g_error := 'COLLECT RESPONSIBLES';
            LOOP
                FETCH l_responsibles
                    INTO l_row_responsible;
                EXIT WHEN l_responsibles%NOTFOUND;
                IF l_rows_responsible IS NULL
                THEN
                    l_rows_responsible := t_rows_responsible(l_row_responsible);
                ELSE
                    l_rows_responsible.extend;
                    l_rows_responsible(l_rows_responsible.last) := l_row_responsible;
                END IF;
            END LOOP;
        
            -- CICLO 1 - iterar os trials. 1 trial => 1 t_section
            -- I.E.T. = iterate, extract and transform
            g_error := 'ITERATE, EXTRACT AND TRANSFORM l_trial';
            LOOP
                FETCH l_trial
                    INTO l_row_trial;
                EXIT WHEN l_trial%NOTFOUND;
            
                -- limpar seccao anterior
                l_section_details  := NULL;
                l_resp_title_shown := FALSE;
            
                -- titulo da section
                g_error := 'GET section title FOR id_trial ' || l_row_trial.id_trial;
                IF l_row_trial.trial_name IS NOT NULL
                   AND l_row_trial.trial_name.count >= 3
                THEN
                    l_section.title := l_row_trial.trial_name(3);
                END IF;
            
                -- detalhes da section. code + responsibles
            
                -- code
                IF l_row_trial.trial_code IS NOT NULL
                   AND l_row_trial.trial_code.count >= 3
                   AND TRIM(l_row_trial.trial_code(3)) IS NOT NULL
                THEN
                    inner_add_section_detail(nvl(TRIM(l_row_trial.trial_code(2)), l_row_trial.trial_code(3)),
                                             CASE WHEN TRIM(l_row_trial.trial_code(2)) IS NULL THEN ' ' ELSE
                                             l_row_trial.trial_code(3) END);
                END IF;
            
                -- CICLO 2 - iterar os responsibles. 1 responsible => 1 t_section_detail
                i := l_rows_responsible.first;
                WHILE i IS NOT NULL
                LOOP
                    -- so usa os que pertencem ao trial actual (ciclo 1)
                    IF l_rows_responsible(i).id_trial = l_row_trial.id_trial
                    THEN
                    
                        -- 'responsible' header. to be shown only once
                        IF l_rows_responsible(i).title IS NOT NULL
                            AND l_rows_responsible(i).title.count >= 3
                            AND l_resp_title_shown = FALSE
                        THEN
                            inner_add_section_detail(nvl(TRIM(l_rows_responsible(i).title(2)),
                                                         l_rows_responsible(i).title(3)),
                                                     CASE WHEN TRIM(l_rows_responsible(i).title(2)) IS NULL THEN ' ' ELSE l_rows_responsible(i).title(3) END);
                            l_resp_title_shown := TRUE;
                        END IF;
                    
                        -- responsible name
                        IF l_rows_responsible(i).responsible IS NOT NULL
                            AND l_rows_responsible(i).responsible.count >= 3
                        THEN
                            inner_add_section_detail(nvl(TRIM(l_rows_responsible(i).responsible(2)),
                                                         l_rows_responsible(i).responsible(3)),
                                                     CASE WHEN TRIM(l_rows_responsible(i).responsible(2)) IS NULL THEN ' ' ELSE l_rows_responsible(i).responsible(3) END);
                        END IF;
                    
                        -- contact_first
                        IF l_rows_responsible(i).contact_first IS NOT NULL
                            AND l_rows_responsible(i).contact_first.count >= 3
                        THEN
                            inner_add_section_detail(nvl(TRIM(l_rows_responsible(i).contact_first(2)),
                                                         l_rows_responsible(i).contact_first(3)),
                                                     CASE WHEN TRIM(l_rows_responsible(i).contact_first(2)) IS NULL THEN ' ' ELSE l_rows_responsible(i).contact_first(3) END);
                        END IF;
                    
                        -- contact_second
                        IF l_rows_responsible(i).contact_second IS NOT NULL
                            AND l_rows_responsible(i).contact_second.count >= 3
                        THEN
                            inner_add_section_detail(nvl(TRIM(l_rows_responsible(i).contact_second(2)),
                                                         l_rows_responsible(i).contact_second(3)),
                                                     CASE WHEN TRIM(l_rows_responsible(i).contact_second(2)) IS NULL THEN ' ' ELSE l_rows_responsible(i).contact_second(3) END);
                        END IF;
                    
                    END IF;
                    i := l_rows_responsible.next(i);
                END LOOP;
            
                IF l_section_details.count > 0
                THEN
                    l_section.section_details := l_section_details;
                    IF o_result.sections IS NULL
                    THEN
                        o_result.sections := t_sections(l_section);
                        -- obter titulo principal. So e settado se houver pelo menos 1 trial (pedido da katia). dai estar neste sitio.
                        g_error        := 'GET title FOR i_req_type = ' || i_req_type;
                        o_result.title := pk_message.get_message(i_lang, 'TRIALS_T076');
                    ELSE
                        o_result.sections.extend;
                        o_result.sections(o_result.sections.last) := l_section;
                    END IF;
                END IF;
            
            END LOOP;
            CLOSE l_trial;
        
            RETURN TRUE;
        
        END inner_get_t_detail;
    
    BEGIN
    
        g_error := 'FORK i_req_type';
        CASE i_req_type
            WHEN g_req_det_waiting_list THEN
                RETURN inner_get_wl_detail;
            WHEN g_req_det_referral THEN
                RETURN inner_get_r_detail;
            WHEN g_req_det_trial THEN
                RETURN inner_get_t_detail;
            WHEN g_req_det_lab THEN
                RETURN inner_get_a_detail;
            ELSE
                BEGIN
                    SELECT dep_type_group
                      INTO l_dep_type_group
                      FROM sch_dep_type
                     WHERE dep_type = i_req_type;
                
                    CASE l_dep_type_group
                        WHEN g_req_det_consult THEN
                            RETURN inner_get_c_detail;
                        WHEN g_req_det_exam THEN
                            RETURN inner_get_e_detail;
                        ELSE
                            RAISE l_invalid_type;
                    END CASE;
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE l_invalid_type;
                END;
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_invalid_type THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => -27700,
                                              i_sqlerrm  => 'UNKNOWN REQUISITION TYPE - ' || i_req_type,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_req_detail;

    /*
    * private function to be used by set_patient_no_show and set_patient_undo_no_show.
    * All this s*** is needed to notify the rehab data model of the change in the appointment.
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_schedule                 schedule id
    * @param i_id_patient                  patient id
    * @param i_from_state                  can be 'C' or 'E'
    * @param i_to_state                    can be 'C' or 'E'
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.6
    * @date    11-07-2013
    */
    FUNCTION set_rehab_no_show
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_id_patient  IN rehab_plan.id_patient%TYPE,
        i_from_state  IN VARCHAR2,
        i_to_state    IN VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(32) := $$PLSQL_UNIT;
        l_id_episode     episode.id_episode%TYPE;
        l_dep_type       sch_event.dep_type%TYPE;
        l_rehab_schedule rehab_schedule%ROWTYPE;
        l_id_epis_origin rehab_epis_encounter.id_episode_origin%TYPE;
    BEGIN
        -- get dep type
        g_error := l_func_name || ' - GET DEP_TYPE FOR id_schedule=' || i_id_schedule;
        SELECT nvl(s.flg_sch_type, se.dep_type)
          INTO l_dep_type
          FROM schedule s
          JOIN sch_event se
            ON s.id_sch_event = se.id_sch_event
         WHERE s.id_schedule = i_id_schedule;
    
        -- proceed only if its a rehab session or appointment
        CASE l_dep_type
        -- SESSOES MFR
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_pm THEN
                -- get ingredients. no_data_Found sao apanhados pelo when others principal
                g_error := l_func_name || ' - GET REHAB_SCHEDULE ROW with id_schedule=' || i_id_schedule;
                SELECT *
                  INTO l_rehab_schedule
                  FROM rehab_schedule rs
                 WHERE rs.id_schedule = i_id_schedule;
            
                --get id_episode_origin. no_data_Found sao apanhados pelo when others principal
                g_error := l_func_name || ' - GET id_epis_origin FROM rehab_epis_encounter WITH id_schedule=' ||
                           i_id_schedule;
                BEGIN
                    SELECT ree.id_episode_origin
                      INTO l_id_epis_origin
                      FROM rehab_epis_encounter ree
                      JOIN epis_info ei
                        ON ei.id_episode = ree.id_episode_origin
                     WHERE ei.id_schedule = i_id_schedule;
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := l_func_name || ' - GET id_epis_origin FROM rehab_sch_need WITH id_schedule=' ||
                                   i_id_schedule;
                        SELECT rsn.id_episode_origin
                          INTO l_id_epis_origin
                          FROM rehab_sch_need rsn
                          JOIN rehab_schedule rs
                            ON rsn.id_rehab_sch_need = rs.id_rehab_sch_need
                         WHERE rs.id_schedule = i_id_schedule;
                END;
            
                g_error := l_func_name || ' - CALL PK_REHAB.SET_REHAB_WF_CHANGE_NOCOMMIT with id_patient=' ||
                           i_id_patient || ',dep_type=' || l_dep_type || ',id_rehab_presc=' ||
                           l_rehab_schedule.id_rehab_sch_need || ',id_rehab_schedule=' ||
                           l_rehab_schedule.id_rehab_schedule || ',id_schedule=' || i_id_schedule ||
                           ', i_id_epis_origin=' || l_id_epis_origin;
                IF NOT pk_rehab.set_rehab_wf_change_nocommit(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_patient        => i_id_patient,
                                                             i_workflow_type     => 'S',
                                                             i_from_state        => i_from_state,
                                                             i_to_state          => i_to_state,
                                                             i_id_rehab_grid     => NULL,
                                                             i_id_rehab_presc    => l_rehab_schedule.id_rehab_sch_need,
                                                             i_id_epis_origin    => l_id_epis_origin,
                                                             i_id_rehab_schedule => l_rehab_schedule.id_rehab_schedule,
                                                             i_id_schedule       => i_id_schedule,
                                                             i_id_cancel_reason  => NULL,
                                                             i_cancel_notes      => NULL,
                                                             i_transaction_id    => NULL,
                                                             o_id_episode        => l_id_episode,
                                                             o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
        -- consultas MFR
            WHEN pk_schedule_common.g_sch_dept_flg_dep_type_cr THEN
                --get id_episode_origin
                g_error := l_func_name || ' - GET id_epis_origin with id_schedule=' || i_id_schedule;
                SELECT ei.id_episode
                  INTO l_id_epis_origin
                  FROM epis_info ei
                 WHERE ei.id_schedule = i_id_schedule;
            
                g_error := l_func_name || ' - CALL PK_REHAB.SET_REHAB_WF_CHANGE_NOCOMMIT with id_patient=' ||
                           i_id_patient || ',dep_type=' || l_dep_type || ',id_rehab_presc=' ||
                           l_rehab_schedule.id_rehab_sch_need || ',id_rehab_schedule=' ||
                           l_rehab_schedule.id_rehab_schedule || ',id_schedule=' || i_id_schedule ||
                           ', i_id_epis_origin=' || l_id_epis_origin;
                IF NOT pk_rehab.set_rehab_wf_change_nocommit(i_lang              => i_lang,
                                                             i_prof              => i_prof,
                                                             i_id_patient        => i_id_patient,
                                                             i_workflow_type     => 'A',
                                                             i_from_state        => i_from_state,
                                                             i_to_state          => i_to_state,
                                                             i_id_rehab_grid     => NULL,
                                                             i_id_rehab_presc    => NULL,
                                                             i_id_epis_origin    => l_id_epis_origin,
                                                             i_id_rehab_schedule => NULL,
                                                             i_id_schedule       => i_id_schedule,
                                                             i_id_cancel_reason  => NULL,
                                                             i_cancel_notes      => NULL,
                                                             i_transaction_id    => NULL,
                                                             o_id_episode        => l_id_episode,
                                                             o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
        -- tudo o resto vai mais cedo para casa
            ELSE
                RETURN TRUE;
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20033,
                                              i_sqlerrm  => 'Could not find essential data to complete the operation',
                                              i_message  => g_error, -- o g_error identifica qual das queries acima resultou neste NDF
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
            -- outras excepcoes sao tratadas no caller desta funcao
    END set_rehab_no_show;

    /*
    * scheduler 3 notifies PFH about a scheduled patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param i_id_cancel_reason            no-show reason id. Comes from table cancel_reason
    * @param i_notes                       optional notes
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.2
    * @date    25-02-2011
    */
    FUNCTION set_patient_no_show
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(32) := 'SET_PATIENT_NO_SHOW';
        l_so_row                   schedule_outp%ROWTYPE;
        l_ids_sch_pfh              table_number;
        l_func_exception           EXCEPTION;
        l_no_pfh_id                EXCEPTION;
        l_pat_not_found            EXCEPTION;
        l_dep_type_group_not_found EXCEPTION;
        l_id_external_request      p1_external_request.id_external_request%TYPE;
        i                          PLS_INTEGER;
        l_rows_out                 table_varchar;
        l_dep_type                 schedule.flg_sch_type%TYPE;
        l_dep_type_group           sch_dep_type.dep_type_group%TYPE;
        l_ids                      table_number;
    BEGIN
        -- get internal ids
        g_error := l_func_name || ' - GET PFH SCH IDS. i_id_sch_ext=' || i_id_sch_ext || ', i_id_patient=' ||
                   i_id_patient;
        IF NOT get_pfh_ids(i_lang        => i_lang,
                           i_prof        => i_prof,
                           i_id_sch_ext  => i_id_sch_ext,
                           i_ids_patient => table_number(i_id_patient),
                           o_result      => l_ids_sch_pfh,
                           o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF nvl(cardinality(l_ids_sch_pfh), 0) = 0
        THEN
            RAISE l_no_pfh_id;
        END IF;
    
        -- iterar os agendamentos encontrados
        i := l_ids_sch_pfh.first;
        WHILE i IS NOT NULL
        LOOP
            l_rows_out := table_varchar(); -- reset collection
        
            -- get this schedule dep_type
            g_error := l_func_name || ' - CALL pk_schedule_common.get_sch_epis_type. i_id_schedule=' ||
                       l_ids_sch_pfh(i);
            IF NOT pk_schedule_common.get_dep_type(i_lang        => i_lang,
                                                   i_id_schedule => l_ids_sch_pfh(i),
                                                   o_dep_type    => l_dep_type,
                                                   o_error       => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- now find the group it belongs to
            g_error          := l_func_name || ' - CALL pk_schedule_common.get_dep_type_group. i_dep_type=' ||
                                l_dep_type;
            l_dep_type_group := pk_schedule_common.get_dep_type_group(l_dep_type);
        
            -- validate merchandise
            IF l_dep_type_group IS NULL
            THEN
                RAISE l_dep_type_group_not_found;
            END IF;
        
            -- actualizar campos no_show na sch_group caso o paciente do registo seja igual ao fornecido
            g_error := l_func_name || ' - UPDATE SCH_GROUP NO-SHOW COLUMNS FOR i_id_patient=' || to_char(i_id_patient) ||
                       ', l_ids_sch_pfh(i)=' || l_ids_sch_pfh(i);
            ts_sch_group.upd(id_cancel_reason_in  => i_id_cancel_reason,
                             id_cancel_reason_nin => FALSE,
                             no_show_notes_in     => i_notes,
                             no_show_notes_nin    => FALSE,
                             where_in             => 'id_patient=' || to_char(i_id_patient) || ' AND id_schedule=' ||
                                                     l_ids_sch_pfh(i),
                             handle_error_in      => FALSE,
                             rows_out             => l_rows_out);
        
            IF l_rows_out.count = 0
            THEN
                RAISE l_pat_not_found;
            END IF;
        
            -- Consultas e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons
            THEN
                BEGIN
                    -- actualiza schedule_outp.flg_state
                    l_so_row.id_schedule_outp := NULL;
                    g_error                   := l_func_name || ' - GET ID_SCHEDULE_OUTP FOR l_ids_sch_pfh(i)=' ||
                                                 l_ids_sch_pfh(i);
                    SELECT id_schedule_outp
                      INTO l_so_row.id_schedule_outp
                      FROM schedule_outp so
                     WHERE so.id_schedule = l_ids_sch_pfh(i)
                       AND rownum = 1;
                
                    g_error              := l_func_name || ' - UPDATE SCHEDULE_OUTP.FLG_STATE FOR l_ids_sch_pfh(i)=' ||
                                            l_ids_sch_pfh(i);
                    l_so_row.id_schedule := l_ids_sch_pfh(i);
                    l_so_row.flg_state   := 'B';
                    ts_schedule_outp.upd(rec_in => l_so_row, handle_error_in => FALSE);
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL; -- nao encontrou registo na schedule_outp
                END;
            END IF;
        
            -- sessoes e consultas rehab. note que aqui nao e' usado o grupo porque o grupo das CR e' C
            IF l_dep_type IN
               (pk_schedule_common.g_sch_dept_flg_dep_type_pm, pk_schedule_common.g_sch_dept_flg_dep_type_cr)
               AND i_prof.software <> pk_alert_constant.g_soft_resptherap
            THEN
                -- actualiza algures no software rehab se for consulta ou sessao de reabilitacao
                g_error := l_func_name || ' - CALL SET_REHAB_NO_SHOW with i_id_schedule=' || l_ids_sch_pfh(i) ||
                           ', i_id_patient=' || i_id_patient || ', i_from_state=' || pk_rehab.g_rehab_session_executed ||
                           ', i_to_state=' || pk_rehab.g_rehab_session_canceled;
                IF NOT set_rehab_no_show(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_id_schedule => l_ids_sch_pfh(i),
                                         i_id_patient  => i_id_patient,
                                         i_from_state  => pk_rehab.g_rehab_session_executed, --'E',
                                         i_to_state    => pk_rehab.g_rehab_session_canceled, --'C'
                                         o_error       => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- exames e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_exam
            THEN
            
                g_error := l_func_name || ' - get id_exam_req_det for id_schedule=' || l_ids_sch_pfh(i);
                SELECT erd.id_exam_req_det
                  BULK COLLECT
                  INTO l_ids
                  FROM schedule_exam se
                  JOIN exam_req_det erd
                    ON erd.id_exam_req = se.id_exam_req
                   AND erd.id_exam = se.id_exam
                 WHERE se.id_schedule = l_ids_sch_pfh(i);
            
                g_error := l_func_name || ' - CALL pk_exams_api_db.set_exam_status';
                IF NOT pk_exams_api_db.set_exam_status(i_lang, i_prof, l_ids, 'NR', NULL, NULL, o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- lab e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_anls
            THEN
            
                -- obter ingredientes
                g_error := l_func_name || ' - get for id_schedule=' || l_ids_sch_pfh(i);
                SELECT ard.id_analysis_req_det
                  BULK COLLECT
                  INTO l_ids
                  FROM schedule_analysis sa
                  JOIN analysis_req_det ard
                    ON sa.id_analysis_req = ard.id_analysis_req
                 WHERE sa.id_schedule = l_ids_sch_pfh(i);
            
                g_error := l_func_name || ' - CALL pk_lab_tests_api_db.set_lab_test_status';
                IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_analysis_req_det => l_ids,
                                                               i_status           => 'NR',
                                                               o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- notificar referral
            g_error := l_func_name || ' - PK_REF_EXT_SYS.GET_REFERRAL_ID WITH ID_SCHEDULE= ' || l_ids_sch_pfh(i);
            IF NOT pk_ref_ext_sys.get_referral_id(i_lang                => i_lang,
                                                  i_prof                => i_prof,
                                                  i_id_schedule         => l_ids_sch_pfh(i),
                                                  o_id_external_request => l_id_external_request,
                                                  o_error               => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            IF l_id_external_request IS NOT NULL
            THEN
                g_error := l_func_name || ' - PK_REF_EXT_SYS.CANCEL_REF_SCHEDULE WITH ID_EXTERNAL_REQUEST= ' ||
                           l_id_external_request;
                IF NOT pk_ref_ext_sys.set_ref_no_show(i_lang   => i_lang,
                                                      i_prof   => i_prof,
                                                      i_id_ref => l_id_external_request,
                                                      i_notes  => i_notes,
                                                      i_reason => i_id_cancel_reason,
                                                      o_error  => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- gravar alteracao no historico
            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || l_ids_sch_pfh(i);
            pk_schedule_common.backup_all(i_id_sch    => l_ids_sch_pfh(i),
                                          i_dt_update => current_timestamp,
                                          i_id_prof_u => i_prof.id);
        
            -- virou
            i := l_ids_sch_pfh.next(i);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_pat_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20004,
                                              i_sqlerrm  => 'Patient not found in sch_group. id_schedule=' ||
                                                            l_ids_sch_pfh(i) || ', id_patient=' || i_id_patient ||
                                                            ', id externo=' || i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_dep_type_group_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20005,
                                              i_sqlerrm  => 'dep_type_group is null for dep_type= ' || l_dep_type,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_patient_no_show;

    /*
    * scheduler 3 notifies PFH to undo a patient no-show
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.2
    * @date    01-03-2011
    */
    FUNCTION set_patient_undo_no_show
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN schedule.id_schedule%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name                VARCHAR2(32) := $$PLSQL_UNIT;
        l_so_row                   schedule_outp%ROWTYPE;
        l_ids_sch_pfh              table_number;
        l_no_pfh_id                EXCEPTION;
        i                          PLS_INTEGER;
        l_pat_not_found            EXCEPTION;
        l_rows_out                 table_varchar;
        l_func_exception           EXCEPTION;
        l_dep_type_group_not_found EXCEPTION;
        l_dep_type                 schedule.flg_sch_type%TYPE;
        l_dep_type_group           sch_dep_type.dep_type_group%TYPE;
        l_ids                      table_number;
    BEGIN
        -- get internal ids
        g_error := l_func_name || ' - GET PFH SCH IDS. i_id_sch_ext=' || i_id_sch_ext || ', i_id_patient=' ||
                   i_id_patient;
        IF NOT get_pfh_ids(i_lang        => i_lang,
                           i_prof        => i_prof,
                           i_id_sch_ext  => i_id_sch_ext,
                           i_ids_patient => table_number(i_id_patient),
                           o_result      => l_ids_sch_pfh,
                           o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        IF nvl(cardinality(l_ids_sch_pfh), 0) = 0
        THEN
            RAISE l_no_pfh_id;
        END IF;
    
        -- iterar os agendamentos encontrados
        i := l_ids_sch_pfh.first;
        WHILE i IS NOT NULL
        LOOP
            l_rows_out := table_varchar(); -- reset collection
        
            -- get this schedule dep_type
            g_error := l_func_name || ' - CALL pk_schedule_common.get_sch_epis_type. i_id_schedule=' ||
                       l_ids_sch_pfh(i);
            IF NOT pk_schedule_common.get_dep_type(i_lang        => i_lang,
                                                   i_id_schedule => l_ids_sch_pfh(i),
                                                   o_dep_type    => l_dep_type,
                                                   o_error       => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- now find the group it belongs to
            g_error          := l_func_name || ' - CALL pk_schedule_common.get_dep_type_group. i_dep_type=' ||
                                l_dep_type;
            l_dep_type_group := pk_schedule_common.get_dep_type_group(l_dep_type);
        
            -- validate merchandise
            IF l_dep_type_group IS NULL
            THEN
                RAISE l_dep_type_group_not_found;
            END IF;
        
            -- actualizar campos no_show na sch_group caso o paciente do registo seja igual ao fornecido
            g_error := l_func_name || ' - RESET SCH_GROUP NO-SHOW COLUMNS FOR i_id_patient=' || to_char(i_id_patient) ||
                       ', l_ids_sch_pfh(i)=' || l_ids_sch_pfh(i);
            ts_sch_group.upd(id_cancel_reason_in  => NULL,
                             id_cancel_reason_nin => FALSE,
                             no_show_notes_in     => NULL,
                             no_show_notes_nin    => FALSE,
                             where_in             => 'id_patient=' || to_char(i_id_patient) || ' AND id_schedule=' ||
                                                     l_ids_sch_pfh(i),
                             handle_error_in      => FALSE,
                             rows_out             => l_rows_out);
        
            IF l_rows_out.count = 0
            THEN
                RAISE l_pat_not_found;
            END IF;
        
            -- Consultas e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_cons
            THEN
                BEGIN
                    -- actualiza schedule_outp.flg_state
                    l_so_row.id_schedule_outp := NULL;
                    g_error                   := l_func_name || ' - GET ID_SCHEDULE_OUTP FOR l_ids_sch_pfh(i)=' ||
                                                 l_ids_sch_pfh(i);
                    SELECT id_schedule_outp
                      INTO l_so_row.id_schedule_outp
                      FROM schedule_outp so
                     WHERE so.id_schedule = l_ids_sch_pfh(i)
                       AND rownum = 1;
                
                    g_error              := l_func_name || ' - UPDATE SCHEDULE_OUTP.FLG_STATE FOR l_ids_sch_pfh(i)=' ||
                                            l_ids_sch_pfh(i);
                    l_so_row.id_schedule := l_ids_sch_pfh(i);
                    l_so_row.flg_state   := 'A';
                    ts_schedule_outp.upd(rec_in => l_so_row, handle_error_in => FALSE);
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL; -- nao encontrou registo na schedule_outp. Pode ser porque nao e' consulta
                END;
            END IF;
        
            -- sessoes e consultas rehab. note que aqui nao e' usado o grupo porque o grupo das CR e' C
            IF l_dep_type IN
               (pk_schedule_common.g_sch_dept_flg_dep_type_pm, pk_schedule_common.g_sch_dept_flg_dep_type_cr)
            THEN
                -- actualiza algures no software rehab se for consulta ou sessao de reabilitacao
                g_error := l_func_name || ' - CALL SET_REHAB_NO_SHOW with i_id_schedule=' || l_ids_sch_pfh(i) ||
                           ', i_id_patient=' || i_id_patient || ', i_from_state=' || pk_rehab.g_rehab_session_canceled ||
                           ', i_to_state=' || pk_rehab.g_rehab_session_executed;
                IF NOT set_rehab_no_show(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_id_schedule => l_ids_sch_pfh(i),
                                         i_id_patient  => i_id_patient,
                                         i_from_state  => pk_rehab.g_rehab_session_canceled, --'C'
                                         i_to_state    => pk_rehab.g_rehab_session_executed, --'E',
                                         o_error       => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- exames e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_exam
            THEN
            
                g_error := l_func_name || ' - get id_exam_req_det for id_schedule=' || l_ids_sch_pfh(i);
                SELECT erd.id_exam_req_det
                  BULK COLLECT
                  INTO l_ids
                  FROM schedule_exam se
                  JOIN exam_req_det erd
                    ON erd.id_exam_req = se.id_exam_req
                   AND erd.id_exam = se.id_exam
                 WHERE se.id_schedule = l_ids_sch_pfh(i);
            
                g_error := l_func_name || ' - CALL pk_exams_api_db.set_exam_status';
                IF NOT pk_exams_api_db.set_exam_status(i_lang, i_prof, l_ids, 'A', NULL, NULL, o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- lab e derivados
            IF l_dep_type_group = pk_schedule_common.g_sch_dept_flg_dep_type_anls
            THEN
            
                -- obter ingredientes
                g_error := l_func_name || ' - get for id_schedule=' || l_ids_sch_pfh(i);
                SELECT ard.id_analysis
                  BULK COLLECT
                  INTO l_ids
                  FROM schedule_analysis sa
                  JOIN analysis_req_det ard
                    ON sa.id_analysis_req = ard.id_analysis_req
                 WHERE sa.id_schedule = l_ids_sch_pfh(i);
            
                g_error := l_func_name || ' - CALL pk_lab_tests_api_db.set_lab_test_status';
                IF NOT pk_lab_tests_api_db.set_lab_test_status(i_lang             => i_lang,
                                                               i_prof             => i_prof,
                                                               i_analysis_req_det => l_ids,
                                                               i_status           => 'A',
                                                               o_error            => o_error)
                THEN
                    RAISE l_func_exception;
                END IF;
            END IF;
        
            -- gravar alteracao no historico
            g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || l_ids_sch_pfh(i);
            pk_schedule_common.backup_all(i_id_sch    => l_ids_sch_pfh(i),
                                          i_dt_update => current_timestamp,
                                          i_id_prof_u => i_prof.id);
        
            -- virou
            i := l_ids_sch_pfh.next(i);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_pat_not_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20004,
                                              i_sqlerrm  => 'Patient not found in sch_group. id_schedule=' ||
                                                            l_ids_sch_pfh(i) || ', id_patient=' || i_id_patient ||
                                                            ', id externo=' || i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_patient_undo_no_show;

    /*
    * scheduler 3 wants to cancel a specific patient that is part of a group schedule
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.1
    * @date    07-03-2011
    */
    FUNCTION cancel_group_schedule_patient
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sch_ext       IN schedule.id_schedule%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_prof_cancel   IN schedule.id_prof_cancel%TYPE,
        i_id_cancel_reason IN sch_group.id_cancel_reason%TYPE,
        i_notes            IN sch_group.no_show_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(32) := 'CANCEL_GROUP_SCHEDULE_PATIENT';
        l_ids_sch_pfh table_number;
        l_no_pfh_id   EXCEPTION;
        i             PLS_INTEGER;
        l_dummy       PLS_INTEGER;
    BEGIN
        -- get internal ids
        g_error       := l_func_name || ' - GET PFH SCH IDs';
        l_ids_sch_pfh := get_pfh_ids(i_id_sch_ext);
    
        IF l_ids_sch_pfh IS NULL
           OR l_ids_sch_pfh.count = 0
        THEN
            RAISE l_no_pfh_id;
        END IF;
    
        -- iterar os agendamentos encontrados
        i := l_ids_sch_pfh.first;
        WHILE i IS NOT NULL
              AND i_id_patient IS NOT NULL
        LOOP
            BEGIN
                SELECT 1
                  INTO l_dummy
                  FROM sch_group sg
                 WHERE sg.id_schedule = l_ids_sch_pfh(i)
                   AND sg.id_patient = i_id_patient;
            
                -- chegando aqui e' porque encontrou o agendamento deste paciente. Cancelar
                IF NOT cancel_schedule_internal(i_lang             => i_lang,
                                                i_prof             => i_prof,
                                                i_id_schedule      => l_ids_sch_pfh(i),
                                                i_id_professional  => i_id_prof_cancel,
                                                i_id_cancel_reason => i_id_cancel_reason,
                                                i_cancel_notes     => i_notes,
                                                i_cancel_date      => NULL,
                                                i_cancel_exam_req  => pk_alert_constant.g_yes,
                                                i_updating         => pk_alert_constant.g_no,
                                                o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    -- not found = no problemo
                    NULL;
            END;
        
            -- virou
            i := l_ids_sch_pfh.next(i);
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_group_schedule_patient;

    /*
    * returns a list of all pfh schedule ids that are linked to the supplied scheduler external id
    * and patient id. This is a generic function that can have potentially many uses. Its first use
    * is to give support to the Scheduler patient registration (efectivacao)
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_id_patient                  patient id
    * @param o_result                      table_number with pfh schedule ids
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.0.5.3.1
    * @date    22-03-2011
    */
    FUNCTION get_pfh_ids
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_sch_ext IN schedule.id_schedule%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        o_result     OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(32) := 'GET_PFH_IDS';
        l_no_pfh_id EXCEPTION;
        i           PLS_INTEGER;
        l_ids       table_number;
    BEGIN
        g_error := l_func_name || ' - GET PFH SCHEDULE IDS for i_id_sch_ext=' || i_id_sch_ext || ', i_id_patient=' ||
                   i_id_patient;
        SELECT DISTINCT id_schedule_pfh
          BULK COLLECT
          INTO o_result
          FROM sch_api_map_ids m
          JOIN sch_group sg
            ON m.id_schedule_pfh = sg.id_schedule
         WHERE m.id_schedule_ext = i_id_sch_ext
           AND sg.id_patient = i_id_patient;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_pfh_ids;

    /*
    * reschedule schedule to be called by scheduler 3. The reschedule in scheduler 3 cancel the actual scheduling and create new one. 
    * The reschedule does not recycle all the stuff related to the old record. See more info below.
    *
    * @param i_lang                language id
    * @param i_prof                profissional id, institution and software
    * @param i_id_sch_ext_old      external schedule id that's mapped to a local schedule id, this one to be canceled
    * @param i_id_sch_ext_new      newly created external schedule id, will be mapped to a new one here in pfh
    * @param i_flg_status          initial schedule status for the new one
    * @param i_id_instit_requested target institution for the new one
    * @param i_id_dep_requested    target department for the new one
    * @param i_flg_vacancy         schedule type  can be routine, urgency or unplanned for the new one
    * @param i_procedures          procedures being scheduled
    * @param i_resources           procedures resources
    * @param i_persons             target patients
    * @param i_procedure_reqs      requisition or WL entry per procedure
    * @param i_id_episode          episode (optional) needed for pfh operations
    * @param i_id_prof_resched     professional doing the reschedule
    * @param i_id_resched_reason   reschedule reason id (see table sch_resched_reason)
    * @param i_resched_notes       reschedule notes
    * @param i_resched_date        reschedule date. if null uses sys date
    * @param i_dt_begin            new schedule global start date
    * @param i_dt_end              new schedule global end date
    * @param o_ids_schedule        newly created schedule ids
    * @param o_error               error data
    *
    * return true /false
    *
    * @author  Telmo
    * @version 2.6.1.5
    * @date    09-11-2011
    */
    FUNCTION reschedule_schedule
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_sch_ext_old      IN NUMBER,
        i_id_sch_ext_new      IN NUMBER,
        i_flg_status          IN schedule.flg_status%TYPE,
        i_id_instit_requested IN institution.id_institution%TYPE,
        i_id_dep_requested    IN dep_clin_serv.id_department%TYPE,
        i_flg_vacancy         IN schedule.flg_vacancy%TYPE,
        i_procedures          IN t_procedures,
        i_resources           IN t_resources,
        i_persons             IN t_persons,
        i_procedure_reqs      IN t_procedure_reqs,
        i_id_episode          IN schedule.id_episode%TYPE,
        i_id_prof_resched     IN professional.id_professional%TYPE,
        i_id_resched_reason   IN sch_resched_reason.id_resched_reason%TYPE,
        i_resched_notes       IN VARCHAR2,
        i_resched_date        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_begin            IN schedule.dt_begin_tstz%TYPE,
        i_dt_end              IN schedule.dt_end_tstz%TYPE,
        i_video_link          IN schedule.video_link%TYPE DEFAULT NULL, -- map to schedule.video_link
        o_ids_schedule        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(32) := $$PLSQL_UNIT;
        l_func_exception    EXCEPTION;
        l_no_pfh_id         EXCEPTION;
        l_ids_pfh           table_number;
        i                   PLS_INTEGER;
        l_old_dt_begin_tstz schedule.dt_begin_tstz%TYPE;
        l_id_patient        sch_group.id_patient%TYPE;
        l_cancel_date       schedule.dt_cancel_tstz%TYPE;
        l_cat               profile_template.id_category%TYPE;
        saer                sys_alert_event%ROWTYPE;
        l_row_schedule      schedule%ROWTYPE;
        l_ids_patient       table_number;
        --        t1                     NUMBER;
        --        t2                     NUMBER;
    BEGIN
        --        t1 := dbms_utility.get_time;
    
        -- extract id_patient list
        g_error       := l_func_name || ' - EXTRACT ID_PATIENT LIST';
        l_ids_patient := get_ids_persons(i_persons);
    
        -- get current pfh scheduler id related to this external id. THE EXTERNAL ID REMAINS THE SAME BUT THE PFH ID CHANGES
        g_error := l_func_name || ' - GET PFH IDS. i_id_sch_ext=' || i_id_sch_ext_old || ', i_ids_patient=' ||
                   pk_utils.concat_table(l_ids_patient, ',');
        IF NOT get_pfh_ids(i_lang        => i_lang,
                           i_prof        => i_prof,
                           i_id_sch_ext  => i_id_sch_ext_old,
                           i_ids_patient => l_ids_patient,
                           o_result      => l_ids_pfh,
                           o_error       => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- the schedule cancelation part will be performed only if there are ids on both sides of the pond
        IF nvl(cardinality(l_ids_pfh), 0) > 0
        THEN
            -- cancel over yonder
            g_error := l_func_name || ' - CANCEL_SCHEDULE';
            IF NOT cancel_schedule(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_sch_ext       => i_id_sch_ext_old,
                                   i_ids_patient      => l_ids_patient,
                                   i_id_professional  => NULL,
                                   i_id_cancel_reason => NULL,
                                   i_cancel_notes     => NULL,
                                   i_cancel_date      => NULL,
                                   i_updating         => pk_alert_constant.g_yes,
                                   o_error            => o_error)
            THEN
                RAISE l_func_exception;
            END IF;
        
            -- fill reschedule columns. Same values goes for everybody
            l_row_schedule.id_resched_reason := i_id_resched_reason;
            l_row_schedule.id_prof_resched   := nvl(i_id_prof_resched, i_prof.id);
            l_row_schedule.resched_notes     := i_resched_notes;
            l_row_schedule.dt_resched_date   := nvl(i_resched_date, current_timestamp);
        
            i := l_ids_pfh.first;
            WHILE i IS NOT NULL
            LOOP
                g_error                    := l_func_name || ' - FILL RESCHEDULE COLUMNS FOR id_schedule= ' ||
                                              l_ids_pfh(i);
                l_row_schedule.id_schedule := l_ids_pfh(i);
                ts_schedule.upd(rec_in => l_row_schedule, handle_error_in => FALSE);
            
                -- gravar alteracao no historico
                g_error := l_func_name || ' - CALL PK_SCHEDULE_COMMON.BACKUP_ALL. i_id_sch=' || l_ids_pfh(i);
                pk_schedule_common.backup_all(i_id_sch    => l_ids_pfh(i),
                                              i_dt_update => current_timestamp,
                                              i_id_prof_u => i_prof.id);
            
                -- virou
                i := l_ids_pfh.next(i);
            END LOOP;
        END IF;
    
        -- insert
        g_error := l_func_name || ' - CREATE_SCHEDULE';
        IF NOT create_schedule(i_lang                => i_lang,
                               i_prof                => i_prof,
                               i_id_sch_ext          => i_id_sch_ext_new,
                               i_flg_status          => i_flg_status,
                               i_id_instit_requested => i_id_instit_requested,
                               i_id_dep_requested    => i_id_dep_requested,
                               i_flg_vacancy         => i_flg_vacancy,
                               i_procedures          => i_procedures,
                               i_resources           => i_resources,
                               i_persons             => i_persons,
                               i_procedure_reqs      => i_procedure_reqs,
                               i_id_episode          => i_id_episode,
                               i_dt_begin            => i_dt_begin,
                               i_dt_end              => i_dt_end,
                               i_id_sch_ref          => CASE nvl(cardinality(l_ids_pfh), 0)
                                                            WHEN 0 THEN
                                                             NULL
                                                            ELSE
                                                             l_ids_pfh(1)
                                                        END,
                               i_video_link          => i_video_link,
                               o_ids_schedule        => o_ids_schedule,
                               o_error               => o_error)
        THEN
            RAISE l_func_exception;
        END IF;
    
        -- NOTA IMPORTANTE: NO RESCHEDULE NAO SE APROVEITA O EPISODIO DO AGENDAMENTO CANCELADO,
        -- COMO ACONTECIA NO UPDATE. DECISAO INICIAL DE IMPLEMENTAÇAO MINHA E DA KTM. E' PRECISO DISCUTIR
        -- COM OS ENTENDIDOS EM EPISODIOS
    
        -- codigo para eventual geracao de alerta de reagendamento
        IF nvl(cardinality(l_ids_pfh), 0) > 0
        THEN
            i := l_ids_pfh.first;
            WHILE i IS NOT NULL
            LOOP
                BEGIN
                    -- obter data de inicio de cada agendamento cancelado
                    g_error := l_func_name || ' - GET DT_BEGIN_TSTZ FOR ID_SCHEDULE=' || l_ids_pfh(i);
                    SELECT dt_begin_tstz
                      INTO l_old_dt_begin_tstz
                      FROM schedule s
                     WHERE s.id_schedule = l_ids_pfh(i);
                
                    -- determinar se aconteceu um reagendamento. e' quando a data de inicio muda
                    IF l_old_dt_begin_tstz <> nvl(i_dt_begin, l_old_dt_begin_tstz)
                    THEN
                    
                        -- find the cancelation prof current profile category
                        g_error := l_func_name || ' - FIND THE UPDATING PROF CURRENT PROFILE CATEGORY';
                        BEGIN
                            SELECT nvl(pt.id_category, -1)
                              INTO l_cat
                              FROM prof_profile_template ppt
                              JOIN profile_template pt
                                ON ppt.id_profile_template = pt.id_profile_template
                             WHERE ppt.id_professional = i_prof.id
                               AND ppt.id_software = i_prof.software
                               AND ppt.id_institution = i_prof.institution
                               AND pt.flg_available = pk_alert_constant.g_yes
                               AND rownum = 1;
                        EXCEPTION
                            WHEN no_data_found THEN
                                l_cat := -1;
                        END;
                    
                        -- proceed only if this is not a registrar
                        IF l_cat <> 4
                        THEN
                        
                            BEGIN
                                g_error := l_func_name || ' - FIND PATIENT ID FOR ALERT CREATION id_sch_pfh=' ||
                                           l_ids_pfh(i);
                                SELECT sg.id_patient, s.dt_cancel_tstz
                                  INTO l_id_patient, l_cancel_date
                                  FROM sch_group sg
                                  JOIN schedule s
                                    ON sg.id_schedule = s.id_schedule
                                 WHERE sg.id_schedule = l_ids_pfh(i)
                                   AND sg.id_cancel_reason IS NULL
                                   AND rownum = 1;
                            
                                -- prepare alert data
                                saer.id_sys_alert   := g_id_sys_alert_resched;
                                saer.id_software    := i_prof.software;
                                saer.id_institution := i_prof.institution;
                                saer.id_patient     := l_id_patient;
                                saer.id_record      := l_ids_pfh(i);
                                saer.dt_record      := l_cancel_date;
                                saer.flg_visible    := pk_alert_constant.g_yes;
                                saer.id_visit       := -1;
                                saer.id_episode     := -1;
                            
                                g_error := l_func_name || ' - INSERT ALERT EVENT. id_sys_alert=' || saer.id_sys_alert ||
                                           ', id_software=' || saer.id_software || ', id_institution=' ||
                                           saer.id_institution || ', id_patient=' || saer.id_patient || ', id_record=' ||
                                           saer.id_record;
                                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                                        i_prof            => i_prof,
                                                                        i_sys_alert_event => saer,
                                                                        o_error           => o_error)
                                THEN
                                    -- optei por nao lancar excepcao para nao comprometer o cancelamento
                                    pk_alertlog.log_error(text        => g_error || ' failed. cause=' ||
                                                                         o_error.ora_sqlerrm,
                                                          object_name => g_package_name,
                                                          owner       => g_package_owner);
                                END IF;
                            
                            EXCEPTION
                                WHEN no_data_found THEN
                                    NULL;
                            END;
                        
                        END IF;
                    
                    END IF;
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL; -- qualquer problemas na criacao dos alertas nao deve comprometer o update_schedule
                END;
                i := l_ids_pfh.next(i);
            END LOOP;
        END IF;
    
        --        t2 := dbms_utility.get_time;
        --        pk_alertlog.log_debug('RESCHEDULE_SCHEDULE ext.id=' || i_id_sch_ext_old || ' time=' || round(((t2 - t1) / 100) * 1000, 2) || ' ms', 
        --                                'PK_SCHEDULE_API_DOWNSTREAM', null);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_no_pfh_id THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => 20003,
                                              i_sqlerrm  => 'Não foi encontrado PFH ID para o ID externo ' ||
                                                            i_id_sch_ext_old,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN l_func_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END reschedule_schedule;

    /* returns the same data as search_wl_bfs, but only for a specified id.
    * This is suposed to be used by the scheduler to retrieve data about the other not yet scheduled
    * half of a waiting list entry.
    *
    * @param i_lang              Language ID
    * @param i_prof              Professional ID/Institution ID/Software ID
    * @param i_id_req            ID to lookup for
    * @param i_wl_type           which half is needed? B=admission, S=surgery
    * @param o_result            returns a collection t_wl_search_row_coll, like search_wl_bfs
    * @param o_error             error info
    *
    *  @return                     true / false
    *
    *  @author                     Telmo
    *  @version                    2.6.1.6
    *  @date                       06-12-2011
    */
    FUNCTION get_wl_req_data
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_req  waiting_list.id_waiting_list%TYPE,
        i_wl_type waiting_list.flg_type%TYPE,
        o_result  OUT t_wl_search_row_coll,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(31) := 'GET_WL_REQ_DATA';
    BEGIN
        -- se o id_req for valido mas o o_result vier vazio, e' porque esse id esta' ja' agendado
        -- para o wl_type passado.
        IF i_id_req IS NULL
           OR i_wl_type NOT IN (pk_wtl_prv_core.g_wtlist_type_surgery, pk_wtl_prv_core.g_wtlist_type_bed)
        THEN
            o_result := t_wl_search_row_coll();
            RETURN TRUE;
        END IF;
    
        o_result := pk_wtl_pbl_core.get_output_bfs(i_wl_type      => i_wl_type,
                                                   i_ids          => table_number(i_id_req),
                                                   i_order_clause => NULL);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_wl_req_data;

    /*
    * returns a list of all pfh schedule ids that are linked to the supplied scheduler external id
    * and one of the patient ids. Needed in ALERT-275305
    *
    * @param i_lang                        Language identifier
    * @param i_prof                        Professional data: id, institution and software
    * @param i_id_sch_ext                  external schedule id
    * @param i_ids_patient                 patient id list
    * @param o_result                      table_number with pfh schedule ids
    * @param o_error                       error info
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    *
    * @author  Telmo
    * @version 2.6.3.11
    * @date    07-02-2014
    */
    FUNCTION get_pfh_ids
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sch_ext  IN schedule.id_schedule%TYPE,
        i_ids_patient IN table_number,
        o_result      OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := $$PLSQL_UNIT;
    BEGIN
        g_error := l_func_name || ' - GET PFH SCHEDULE IDS for i_id_sch_ext=' || i_id_sch_ext || ', i_ids_patient=' ||
                   pk_utils.concat_table(i_ids_patient, ',');
    
        SELECT DISTINCT id_schedule_pfh
          BULK COLLECT
          INTO o_result
          FROM sch_api_map_ids m
          JOIN schedule s
            ON s.id_schedule = m.id_schedule_pfh
          JOIN sch_group sg
            ON s.id_schedule = sg.id_schedule
          JOIN TABLE(i_ids_patient) p
            ON sg.id_patient = p.column_value
         WHERE m.id_schedule_ext = i_id_sch_ext;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_pfh_ids;

    /*
    * Gets id_schedule_resource
    *
    * @param i_lang                  Language identifier
    * @param i_prof                  Professional data: id, institution and software
    * @param i_id_schedule           Schedule (PFH) identifier
    * @param o_id_schedule_resource  Scheduler resource identifier              
    * @param o_error                 An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Nuno Amorim
    * @since   28/11/2017
    */
    FUNCTION get_schedule_id_resource
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_schedule          IN sch_api_map_ids.id_schedule_pfh%TYPE,
        o_id_schedule_resource OUT NUMBER,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_SCHEDULE_ID_RESOURCE';
    
    BEGIN
    
        SELECT sr.id_schedule_resource
          INTO o_id_schedule_resource
          FROM sch_api_map_ids sami
          JOIN alert_apsschdlr_tr.schedule_procedure sp
            ON sp.id_schedule = sami.id_schedule_ext
          JOIN alert_apsschdlr_tr.schedule_resource sr
            ON sr.id_schedule_procedure = sp.id_schedule_procedure
         WHERE sami.id_schedule_pfh = i_id_schedule
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_schedule_resource := NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_schedule_id_resource;

    /* 
    *  function to be used as data source for the interalert service that will feed the
    *  scheduler allowing to display the preferential Service and Clinical Service
    *  of the professional in the waiting list search window.
    *
    * @param i_lang                  Language identifier
    * @param i_prof                  Professional data: id, institution and software
    * @param i_software              Software Identifier
    * @param o_id_dep_clin_serv      Department Clinical Service identifier              
    * @param o_department            Department identifier 
    * @param o_clinical_service      Clinical Service identifier 
    * @param o_error                 An error message, set when return=false
    *
    * @return                        Boolean
    *
    * @author                     Nuno Amorim
    * @version                    2.7.4.7
    * @since                      24-01-2019
    */
    FUNCTION get_prof_default_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_software         IN software.id_software%TYPE,
        o_id_dep_clin_serv OUT dep_clin_serv.id_dep_clin_serv%TYPE,
        o_department       OUT department.id_department%TYPE,
        o_clinical_service OUT clinical_service.id_clinical_service%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PROF_DEFAULT_DCS';
    BEGIN
    
        IF NOT pk_prof_utils.get_prof_default_dcs(i_lang             => i_lang,
                                                  i_prof             => i_prof,
                                                  i_software         => i_software,
                                                  o_id_dep_clin_serv => o_id_dep_clin_serv,
                                                  o_department       => o_department,
                                                  o_clinical_service => o_clinical_service,
                                                  o_error            => o_error)
        THEN
            RETURN FALSE;
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
                                              i_function => l_func_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_prof_default_dcs;

    --****************** Alertas for HHC
    FUNCTION create_alert_event
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_id_sys_alert     IN NUMBER,
        i_id_sys_alert_del IN NUMBER,
        i_id_schedule      IN NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        r_epis episode%ROWTYPE;
        saer   sys_alert_event%ROWTYPE;
        l_bool BOOLEAN;
        k_epis_type_hhc CONSTANT NUMBER := pk_alert_constant.g_epis_type_home_health_care;
        l_error t_error_out;
    
        -- *****************************************
        FUNCTION get_id_episode_by_schedule(i_id_schedule IN NUMBER) RETURN NUMBER IS
            tbl_id_episode table_number;
            l_id_episode   NUMBER;
        BEGIN
            SELECT id_episode
              BULK COLLECT
              INTO tbl_id_episode
              FROM epis_info
             WHERE id_schedule = i_id_schedule;
        
            IF tbl_id_episode.count > 0
            THEN
                l_id_episode := tbl_id_episode(1);
            END IF;
        
            RETURN l_id_episode;
        
        END get_id_episode_by_schedule;
    
        -- ***********************************
        FUNCTION get_episode_row(i_id_episode IN NUMBER) RETURN episode%ROWTYPE IS
            xrow episode%ROWTYPE;
        BEGIN
            SELECT e.*
              INTO xrow
              FROM episode e
             WHERE e.id_episode = i_id_episode;
        
            RETURN xrow;
        END get_episode_row;
    
    BEGIN
    
        saer.id_episode := get_id_episode_by_schedule(i_id_schedule);
    
        IF saer.id_episode IS NOT NULL
        THEN
        
            r_epis := get_episode_row(i_id_episode => saer.id_episode);
        
            IF r_epis.id_epis_type = k_epis_type_hhc
            THEN
            
                -- prepare alert data
                saer.id_sys_alert   := i_id_sys_alert;
                saer.id_software    := i_prof.software;
                saer.id_institution := i_prof.institution;
                saer.id_patient     := r_epis.id_patient;
                saer.id_record      := i_id_schedule;
                saer.dt_record      := current_timestamp;
                saer.flg_visible    := pk_alert_constant.g_yes;
                saer.id_visit       := r_epis.id_visit;
            
                l_bool := pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                           i_prof            => i_prof,
                                                           i_sys_alert_event => saer,
                                                           o_error           => l_error);
            
                IF NOT l_bool
                THEN
                    -- if alert gives error, log it, but do not invalidate operation
                    pk_alertlog.log_error(text        => 'Alert failed ' || i_id_sys_alert || ' cause=' ||
                                                         l_error.ora_sqlerrm,
                                          object_name => g_package_name,
                                          owner       => g_package_owner);
                END IF;
            
                saer.id_sys_alert := i_id_sys_alert_del;
                l_bool            := pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                                      i_prof            => i_prof,
                                                                      i_sys_alert_event => saer,
                                                                      o_error           => l_error);
                IF NOT l_bool
                THEN
                    -- if alert gives error, log it, but do not invalidate operation
                    pk_alertlog.log_error(text        => 'Removing Alert failed ' || i_id_sys_alert_del || ' cause=' ||
                                                         l_error.ora_sqlerrm,
                                          object_name => g_package_name,
                                          owner       => g_package_owner);
                END IF;
            
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END create_alert_event;

    /* create schedule to be used by scheduler 3. When a schedule is created there, it is propagated
    * in PFH. Scheduler 3 does that  by calling INTF_ALERT code that in turn calls this function.
    *
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    09-12-2020
    */
    FUNCTION create_schedule_collection
    (
        i_t_schedules  IN t_schedules,
        o_ids_schedule OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_ids_schedules table_number;
        l_t_error       t_error_out;
    
    BEGIN
        FOR i IN 1 .. i_t_schedules.count
        LOOP
            IF NOT pk_schedule_api_downstream.create_schedule(i_lang                => i_t_schedules(i).id_lang,
                                                              i_prof                => i_t_schedules(i).prof,
                                                              i_id_sch_ext          => i_t_schedules(i).id_sch_ext,
                                                              i_flg_status          => i_t_schedules(i).flg_status,
                                                              i_id_instit_requested => i_t_schedules(i).id_instit_requested,
                                                              i_id_dep_requested    => i_t_schedules(i).id_dep_requested,
                                                              i_flg_vacancy         => i_t_schedules(i).flg_vacancy,
                                                              i_procedures          => i_t_schedules(i).procedures,
                                                              i_resources           => i_t_schedules(i).resources,
                                                              i_persons             => i_t_schedules(i).persons,
                                                              i_procedure_reqs      => i_t_schedules(i).procedure_reqs,
                                                              i_id_episode          => i_t_schedules(i).id_episode,
                                                              i_id_sch_ref          => i_t_schedules(i).id_sch_ref,
                                                              i_dt_begin            => i_t_schedules(i).dt_begin,
                                                              i_dt_end              => i_t_schedules(i).dt_end,
                                                              i_dt_referral         => i_t_schedules(i).dt_referral,
                                                              i_prof_resp           => i_t_schedules(i).prof_resp,
                                                              i_video_link          => i_t_schedules(i).video_link,
                                                              o_ids_schedule        => o_ids_schedule,
                                                              o_error               => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    END create_schedule_collection;

    /*
    * reschedule schedule to be called by scheduler . The reschedule in scheduler  is different than the update in that a new
    * record is created and the old one canceled. The update does not create a new record.
    * this functions allways cancels the existing schedule(s) and creates new ones.
    * 
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    14-12-2020
    */
    FUNCTION reschedule_schedule_collection
    (
        i_t_schedules  IN t_schedules,
        o_ids_schedule OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        FOR i IN 1 .. i_t_schedules.count
        LOOP
            IF NOT pk_schedule_api_downstream.reschedule_schedule(i_lang                => i_t_schedules(i).id_lang,
                                                                  i_prof                => i_t_schedules(i).prof,
                                                                  i_id_sch_ext_old      => i_t_schedules(i).id_sch_ext_old,
                                                                  i_id_sch_ext_new      => i_t_schedules(i).id_sch_ext,
                                                                  i_flg_status          => i_t_schedules(i).flg_status,
                                                                  i_id_instit_requested => i_t_schedules(i).id_instit_requested,
                                                                  i_id_dep_requested    => i_t_schedules(i).id_dep_requested,
                                                                  i_flg_vacancy         => i_t_schedules(i).flg_vacancy,
                                                                  i_procedures          => i_t_schedules(i).procedures,
                                                                  i_resources           => i_t_schedules(i).resources,
                                                                  i_persons             => i_t_schedules(i).persons,
                                                                  i_procedure_reqs      => i_t_schedules(i).procedure_reqs,
                                                                  i_id_episode          => i_t_schedules(i).id_episode,
                                                                  i_id_prof_resched     => i_t_schedules(i).id_sch_ref,
                                                                  i_id_resched_reason   => i_t_schedules(i).id_resched_reason,
                                                                  i_resched_notes       => i_t_schedules(i).resched_notes,
                                                                  i_resched_date        => i_t_schedules(i).resched_date,
                                                                  i_dt_begin            => i_t_schedules(i).dt_begin,
                                                                  i_dt_end              => i_t_schedules(i).dt_end,
                                                                  i_video_link          => i_t_schedules(i).video_link,
                                                                  o_ids_schedule        => o_ids_schedule,
                                                                  o_error               => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    END reschedule_schedule_collection;

    /*
    * update schedule to be used by scheduler. When a schedule is update there, it is propagated
    * in PFH. Scheduler does that  by calling INTF_ALERT code that in turn calls this function.
    * this update is used by a large spectrum of scheduler actions. ex. adding/removing resources, changing procedure(s),
    * changing dates, etc.
    *
    * @param i_t_schedules          t_schedules
    *
    * return true /false
    *
    * @author  Miguel Monteiro
    * @version 2.8.2.1
    * @date    14-12-2020
    */
    FUNCTION update_schedule_collection
    (
        i_t_schedules  IN t_schedules,
        o_ids_schedule OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        FOR i IN 1 .. i_t_schedules.count
        LOOP
            IF NOT pk_schedule_api_downstream.update_schedule(i_lang                => i_t_schedules(i).id_lang,
                                                              i_prof                => i_t_schedules(i).prof,
                                                              i_id_sch_ext          => i_t_schedules(i).id_sch_ext,
                                                              i_flg_status          => i_t_schedules(i).flg_status,
                                                              i_id_instit_requested => i_t_schedules(i).id_instit_requested,
                                                              i_id_dep_requested    => i_t_schedules(i).id_dep_requested,
                                                              i_flg_vacancy         => i_t_schedules(i).flg_vacancy,
                                                              i_procedures          => i_t_schedules(i).procedures,
                                                              i_resources           => i_t_schedules(i).resources,
                                                              i_persons             => i_t_schedules(i).persons,
                                                              i_procedure_reqs      => i_t_schedules(i).procedure_reqs,
                                                              i_id_episode          => i_t_schedules(i).id_episode,
                                                              i_id_prof_cancel      => NULL,
                                                              i_id_cancel_reason    => NULL,
                                                              i_cancel_notes        => NULL,
                                                              i_cancel_date         => NULL,
                                                              i_dt_begin            => i_t_schedules(i).dt_begin,
                                                              i_dt_end              => i_t_schedules(i).dt_end,
                                                              i_video_link          => i_t_schedules(i).video_link,
                                                              o_ids_schedule        => o_ids_schedule,
                                                              o_error               => o_error)
            THEN
            
                RETURN FALSE;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    END update_schedule_collection;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name, owner => g_package_owner);
END pk_schedule_api_downstream;
/
