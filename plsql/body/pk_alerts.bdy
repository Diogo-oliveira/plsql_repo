/*-- Last Change Revision: $Rev: 2053268 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-12-15 16:13:24 +0000 (qui, 15 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_alerts IS

    k_yes CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_yes;
    k_no  CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_no;

    CURSOR c_active_alerts_stub IS
        SELECT id_episode,
               id_reg,
               id_institution,
               id_prof,
               dt_req_tstz,
               replace1,
               replace2,
               id_schedule,
               id_sys_alert,
               id_reg_det,
               id_clinical_service,
               id_room,
               id_patient
          FROM sys_alert_det
         WHERE rownum <= 1;

    CURSOR c_inactive_alerts_stub IS
        SELECT id_sys_alert_det
          FROM sys_alert_det
         WHERE rownum <= 1;

    TYPE t_active_alerts IS REF CURSOR RETURN c_active_alerts_stub%ROWTYPE;
    TYPE t_inactive_alerts IS REF CURSOR RETURN c_inactive_alerts_stub%ROWTYPE;

    g_code_msg_not_applicable CONSTANT sys_message.code_message%TYPE := 'N/A';

    FUNCTION get_sql_alert(i_id_sys_alert IN NUMBER) RETURN VARCHAR2 IS
        l_alert_sql CLOB;
    BEGIN
        g_error := 'GET ALERT SQL';
        SELECT a.sql_alert alert_sql
          INTO l_alert_sql
          FROM sys_alert a
         WHERE a.id_sys_alert = i_id_sys_alert;
    
        RETURN l_alert_sql;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(text            => SQLERRM,
                                  object_name     => g_package,
                                  sub_object_name => 'get_sql_alert',
                                  owner           => g_owner);
            RETURN empty_clob();
    END get_sql_alert;

    /*
    * Utility function to create new default sys_alert_event row
    *
    * @return    true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013/10/07
    */
    FUNCTION new_sys_alert_event
    (
        i_id_sys_alert_event sys_alert_event.id_sys_alert_event% TYPE DEFAULT NULL,
        i_id_sys_alert       sys_alert.id_sys_alert% TYPE DEFAULT NULL,
        i_id_software        software.id_software% TYPE DEFAULT 0,
        i_id_institution     institution.id_institution% TYPE DEFAULT 0,
        i_id_patient         patient.id_patient% TYPE DEFAULT -1,
        i_id_visit           visit.id_visit% TYPE DEFAULT -1,
        i_id_episode         episode.id_episode% TYPE DEFAULT -1,
        i_id_record          sys_alert_event.id_record% TYPE DEFAULT -1,
        i_dt_record          sys_alert_event.dt_record% TYPE DEFAULT current_timestamp
        
    ) RETURN sys_alert_event%ROWTYPE IS
        l_sys_alert_event sys_alert_event% ROWTYPE;
    BEGIN
        l_sys_alert_event.id_sys_alert_event := i_id_sys_alert_event;
        l_sys_alert_event.id_sys_alert       := i_id_sys_alert;
        l_sys_alert_event.id_software        := i_id_software;
        l_sys_alert_event.id_institution     := i_id_institution;
        l_sys_alert_event.id_patient         := i_id_patient;
        l_sys_alert_event.id_visit           := i_id_visit;
        l_sys_alert_event.id_episode         := i_id_episode;
        l_sys_alert_event.id_record          := i_id_record;
        l_sys_alert_event.dt_record          := i_dt_record;
        RETURN l_sys_alert_event;
    END;

    /**
    * Gets professional profile_template
    * Assumes that there's only ibe profile_template for user/software/institution.
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional, institution and software ids
    * @param   o_pt an error message, set when return=false
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_profile_template
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_pt    OUT profile_template.id_profile_template%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        r_prf profile_template%ROWTYPE;
    BEGIN
        g_error := 'OPEN o_pt';
        r_prf   := pk_access.get_profile(i_prof);
        o_pt    := r_prf.id_profile_template;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROFILE_TEMPLATE',
                                              o_error);
            RETURN FALSE;
    END get_profile_template;

    /**
    * Gets value from doc_config
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_id_sys_alert alert type id
    * @param   i_profile_template profile id
    *
    * @RETURN
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN sys_alert_config%ROWTYPE IS
    
        CURSOR c
        (
            x_alert sys_alert.id_sys_alert%TYPE,
            x_soft  software.id_software%TYPE,
            x_inst  institution.id_institution%TYPE,
            x_pt    profile_template.id_profile_template%TYPE
        ) IS
            SELECT *
              FROM sys_alert_config c
             WHERE c.id_sys_alert = x_alert
               AND c.id_software IN (x_soft, 0)
               AND c.id_institution IN (x_inst, 0)
               AND c.id_profile_template IN (x_pt, 0)
             ORDER BY id_software DESC, id_institution DESC, id_profile_template DESC;
    
        l_pt               profile_template.id_profile_template%TYPE;
        l_sys_alert_config sys_alert_config%ROWTYPE;
        l_error            t_error_out;
        l_exception        EXCEPTION;
    BEGIN
        -- Obtain profile id if not provided.
        IF i_profile_template IS NULL
        THEN
            g_error  := 'GET PROFILE';
            g_retval := get_profile_template(i_lang, i_prof, l_pt, l_error);
            IF NOT g_retval
            THEN
                RETURN NULL;
            END IF;
        ELSE
            l_pt := i_profile_template;
        END IF;
    
        OPEN c(i_id_sys_alert, i_prof.software, i_prof.institution, l_pt);
        FETCH c
            INTO l_sys_alert_config;
        CLOSE c;
    
        RETURN l_sys_alert_config;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_config;

    /**
    * Gets value for flg_read in doc_config
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_id_sys_alert alert type id
    * @param   i_profile_template profile id
    *
    * @RETURN
    * @author  João Sá
    * @version 2.0
    * @since   28-09-2007
    */
    FUNCTION get_config_flg_read
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2 IS
        l_alert_config_row sys_alert_config%ROWTYPE;
        l_return           VARCHAR2(0050 CHAR);
    BEGIN
    
        l_alert_config_row := get_config(i_lang, i_prof, i_id_sys_alert, i_profile_template);
        IF l_alert_config_row.id_sys_alert_config IS NULL
        THEN
            l_return := g_flg_read_y;
        ELSE
            l_return := l_alert_config_row.flg_read;
        END IF;
    
        RETURN l_return;
    
    END get_config_flg_read;

    /********************************************************************************************
    * Esta função marca os alertas como lidos para um determinado profissional.
    *
    * @param i_lang           Id do idioma
    * @param i_prof           Id do profissional
    * @param i_sys_alert_det  ID do alerta lido
    * @param i_sys_alert      ID do tipo de alerta
    * @param i_test           Indica se deve ser mostrada a mensagem de confirmação
    * @param o_flg_show       Indica se deve ser mostrada a mensagem de confirmação
    * @param o_msg_title      Título da mensagem de confirmação
    * @param o_msg_text       Descrição da mensagem de confirmação
    * @param o_button         Botões a mostrar. N - NÃO, R - LIDO, C - CONFIRMADO ou combinações destes
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE if sucess, FALSE otherwise
    *
    * @author                 Rui Batista
    * @version                1.0
    * @since                  2007/07/11
    ********************************************************************************************/
    FUNCTION set_alert_read
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_sys_alert_det IN sys_alert_det.id_sys_alert_det%TYPE,
        i_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_msg_title     OUT VARCHAR2,
        o_msg_text      OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_alert_config_row sys_alert_config%ROWTYPE;
        l_flg_read         VARCHAR2(0050 CHAR) := g_flg_read_y;
        l_flg_delete       VARCHAR2(0050 CHAR) := g_flg_delete_n;
        e_call EXCEPTION;
        r_prf profile_template%ROWTYPE;
    
        --***************************
        PROCEDURE get_alert_info IS
    BEGIN
    
            l_flg_read   := get_config_flg_read(i_lang,
                                                i_prof,
                                                i_sys_alert,
                                                i_profile_template => r_prf.id_profile_template);
            l_flg_delete := get_config_flg_delete(i_lang,
                                                  i_prof,
                                                  i_sys_alert,
                                                  i_profile_template => r_prf.id_profile_template);
    
        END get_alert_info;
    
        --**************************
        PROCEDURE show_confirm_msg IS
        BEGIN
            o_flg_show  := 'Y';
            o_msg_text  := pk_message.get_message(i_lang, 'V_ALERT_M016');
            o_msg_title := pk_message.get_message(i_lang, 'V_ALERT_M015');
            o_button    := 'NC';
        END show_confirm_msg;
    
        --******************************
        PROCEDURE process_triage IS
        BEGIN
        
            -- Triage safeguarding alert needs to show a popup with information
            IF NOT pk_edis_triage.get_safeguard_info(i_lang               => i_lang,
                                                     i_prof               => i_prof,
                                                     i_id_sys_alert_event => i_sys_alert_det,
                                                     o_msg_title          => o_msg_title,
                                                     o_msg_text           => o_msg_text,
                                                     o_error              => o_error)
            THEN
                RAISE e_call;
            ELSE
                IF o_msg_text IS NOT NULL
                   AND o_msg_title IS NOT NULL
                THEN
                    o_flg_show := 'Y';
                END IF;
            END IF;
    
        END process_triage;
    
        --******************************
        PROCEDURE delete_alert_event IS
        BEGIN
        
            DELETE sys_alert_event
             WHERE id_sys_alert_event = i_sys_alert_det;
        
        END delete_alert_event;
    
        --********************************
        PROCEDURE mark_as_read IS
        BEGIN
        
            --se o tipo de alerta o permitir, define alerta como lido de forma a não aparecer mais a este utilizador
            g_error := 'INSERT ALERT READ INFO';
            --IF l_flg_read = g_flg_read_y
            IF 1 = 1
            THEN
                --Se o registo de leitura do profissional já existir (o que não deve acontecer),
                -- actualiza a data de leitura, senão adiciona o registo.
                MERGE INTO sys_alert_read d
                USING (SELECT i_sys_alert_det id_sys_alert_event, i_prof.id
                         FROM dual) m
                ON (d.id_sys_alert_event = m.id_sys_alert_event AND d.id_professional = i_prof.id)
                WHEN MATCHED THEN
                    UPDATE
                       SET dt_read_tstz = g_sysdate_tstz
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_sys_alert_read, id_sys_alert_event, id_professional, dt_read_tstz)
                    VALUES
                        (seq_sys_alert_read.nextval, i_sys_alert_det, i_prof.id, g_sysdate_tstz);
            END IF;
        
        END mark_as_read;
    
    BEGIN
        o_flg_show     := 'N';
        g_sysdate_tstz := current_timestamp;
        r_prf          := pk_access.get_profile(i_prof);
    
        -- Versão em sys_alert. Usa flg_read de sys_alert!
        get_alert_info();
    
        --Verifica se deve ser mostrada a mensagem de confirmação ao utilizador
        g_error := 'TEST SHOW MESSAGE';
        IF i_test = 'Y'
        THEN
            show_confirm_msg();
        ELSIF i_sys_alert = 311
        THEN
            process_triage();
        END IF;
    
        --se o tipo de alerta o permitir, apagar alertas de forma a não aparecer mais a este utilizador
        IF l_flg_delete = g_flg_delete_y
        THEN
            delete_alert_event();
        ELSE
            mark_as_read();
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_ALERT_READ',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_alert_read;

    /********************************************************************************************
    * Esta função calcula as margem de tempo para o alerta expirar
    *
    * @param i_lang        Id do idioma
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE if sucess, FALSE otherwise
    *
    * @author                Carlos Vieira
    * @version               1.0
    * @since                 2009/04/10
    ********************************************************************************************/
    FUNCTION get_expire_nurse_act_exec
    (
        i_lang        IN NUMBER,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_time_lable  IN VARCHAR2
    ) RETURN NUMBER IS
    BEGIN
        RETURN pk_sysconfig.get_config(i_time_lable, i_institution, i_software);
    END get_expire_nurse_act_exec;

    /********************************************************************************************
    * Esta função gera alertas de diagnósticos de enfermagem - CIPE.
    *
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/20
    ********************************************************************************************/
    FUNCTION alert_icnp_diag
    (
        i_lang  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        c_active_alerts   t_active_alerts;
        c_inactive_alerts t_inactive_alerts;
    
        e_call EXCEPTION;
    
        l_sys_alert sys_alert.id_sys_alert%TYPE := 20;
    BEGIN
        OPEN c_active_alerts FOR
            SELECT ntr.id_episode,
                   ntr.id_nurse_tea_req id_reg,
                   e.id_institution,
                   NULL id_prof,
                   nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) dt_req_tstz,
                   (SELECT pk_sysconfig.get_config('ALERT_ICNP_DIAG_TIMEOUT', e.id_institution, i.id_software)
                      FROM dual) replace1,
                   '' replace2,
                   i.id_schedule,
                   l_sys_alert id_sys_alert,
                   ntr.id_nurse_tea_req id_reg_det,
                   e.id_clinical_service,
                   NULL id_room,
                   e.id_patient
              FROM nurse_tea_req ntr
              JOIN episode e
                ON e.id_episode = ntr.id_episode
              JOIN epis_info i
                ON i.id_episode = e.id_episode
               AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                      FROM dual) = i.id_software
               AND (SELECT pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(alert.profissional(NULL,
                                                                                                              e.id_institution,
                                                                                                              NULL),
                                                                                           current_timestamp,
                                                                                           NULL),
                                                          -pk_sysconfig.get_config('ALERT_EXPIRE_ICNP_DIAG',
                                                                                   e.id_institution,
                                                                                   i.id_software))
                      FROM dual) < pk_date_utils.trunc_insttimezone(alert.profissional(NULL, e.id_institution, NULL),
                                                                    nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz),
                                                                    NULL)
               AND nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) <
                   (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                          - (pk_sysconfig.get_config('ALERT_ICNP_DIAG_TIMEOUT',
                                                                                    e.id_institution,
                                                                                    i.id_software) / (24 * 60)))
                      FROM dual)
             WHERE ntr.flg_status = 'A'
               AND e.flg_status IN (g_epis_active, g_epis_pend);
    
        OPEN c_inactive_alerts FOR
            SELECT id_sys_alert_det
              FROM sys_alert_det
             WHERE id_sys_alert = l_sys_alert
               AND (id_episode, id_reg_det) NOT IN
                   (SELECT ntr.id_episode, ntr.id_nurse_tea_req id_reg_det
                      FROM nurse_tea_req ntr
                      JOIN episode e
                        ON e.id_episode = ntr.id_episode
                      JOIN epis_info i
                        ON (SELECT pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(alert.profissional(NULL,
                                                                                                                      e.id_institution,
                                                                                                                      NULL),
                                                                                                   current_timestamp,
                                                                                                   NULL),
                                                                  -pk_sysconfig.get_config('ALERT_EXPIRE_ICNP_DIAG',
                                                                                           e.id_institution,
                                                                                           i.id_software))
                              FROM dual) <
                           pk_date_utils.trunc_insttimezone(alert.profissional(NULL, e.id_institution, NULL),
                                                            nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz),
                                                            NULL)
                       AND nvl(ntr.dt_begin_tstz, ntr.dt_nurse_tea_req_tstz) <
                           (SELECT pk_date_utils.add_days_to_tstz(current_timestamp,
                                                                  - (pk_sysconfig.get_config('ALERT_ICNP_DIAG_TIMEOUT',
                                                                                            e.id_institution,
                                                                                            i.id_software) / (24 * 60)))
                              FROM dual)
                       AND i.id_episode = e.id_episode
                       AND (SELECT pk_episode.get_soft_by_epis_type(e.id_epis_type, e.id_institution)
                              FROM dual) = i.id_software
                     WHERE ntr.flg_status = 'A'
                       AND e.flg_status IN (g_epis_active, g_epis_pend));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'ALERT_ICNP_DIAG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END alert_icnp_diag;

    /********************************************************************************************
    * Esta função gera um alerta quando existe um episódio temporário no internamento associado
    * a um paciente que já tem episódio permanente
    * @param i_lang          Id do idioma
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/24
    ********************************************************************************************/
    FUNCTION alert_inp_temp_episodes
    (
        i_lang  IN NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof      profissional;
        e_call      EXCEPTION;
        l_sys_alert sys_alert.id_sys_alert%TYPE := 37;
    BEGIN
        FOR active_alerts IN (SELECT meap.id_episode id_episode,
                                     meap.id_episode id_reg,
                                     NULL id_prof,
                                     meap.id_institution id_institution,
                                     meap.id_software,
                                     meap.dt_begin_tstz_e dt_req_tstz,
                                     '' replace1,
                                     '' replace2,
                                     NULL id_schedule,
                                     l_sys_alert id_sys_alert,
                                     meap.id_patient id_reg_det,
                                     NULL id_clinical_service,
                                     NULL id_room,
                                     meap.id_patient
                                FROM v_episode_act meap
                               WHERE meap.id_epis_type = (SELECT pk_sysconfig.get_config('ID_EPIS_TYPE_INPATIENT',
                                                                                         meap.id_institution,
                                                                                         meap.id_software)
                                                            FROM dual)
                                 AND (SELECT pk_date_utils.trunc_insttimezone(alert.profissional(NULL,
                                                                                                 meap.id_institution,
                                                                                                 NULL),
                                                                              current_timestamp,
                                                                              NULL)
                                        FROM dual) >=
                                     pk_date_utils.trunc_insttimezone(alert.profissional(NULL, meap.id_institution, NULL),
                                                                      meap.dt_begin_tstz_e,
                                                                      NULL)
                                 AND meap.flg_status_e = 'A'
                                 AND meap.flg_unknown = 'Y'
                                 AND EXISTS (SELECT 0
                                        FROM episode epis
                                        JOIN visit v
                                          ON epis.id_visit = v.id_visit
                                        JOIN patient p
                                          ON p.id_patient = v.id_patient
                                        JOIN epis_info epo
                                          ON epo.id_episode = epis.id_episode
                                       WHERE p.id_patient = meap.id_patient
                                         AND v.id_institution = meap.id_institution
                                         AND epo.flg_unknown = 'N'
                                         AND epis.flg_status = 'A'))
        LOOP
            l_prof := profissional(active_alerts.id_prof, active_alerts.id_institution, active_alerts.id_software);
        
            IF NOT pk_alerts.insert_sys_alert_event(i_lang                => i_lang,
                                                    i_prof                => l_prof,
                                                    i_sys_alert           => l_sys_alert,
                                                    i_id_episode          => active_alerts.id_episode,
                                                    i_id_record           => active_alerts.id_reg,
                                                    i_dt_record           => active_alerts.dt_req_tstz,
                                                    i_id_professional     => active_alerts.id_prof,
                                                    i_id_room             => active_alerts.id_room,
                                                    i_id_clinical_service => active_alerts.id_clinical_service,
                                                    i_flg_type_dest       => 'C',
                                                    i_replace1            => active_alerts.replace1,
                                                    i_replace2            => active_alerts.replace2,
                                                    o_error               => o_error)
            THEN
                RAISE e_call;
            END IF;
        END LOOP;
    
        FOR inactive_alerts IN (SELECT sad.id_professional id_prof, sad.id_institution, sad.id_software, sad.id_record
                                  FROM sys_alert_event sad
                                 WHERE sad.id_sys_alert = l_sys_alert
                                   AND sad.id_sys_alert_event NOT IN
                                       (SELECT sad1.id_sys_alert_event
                                          FROM sys_alert_event sad1
                                          JOIN (SELECT epi.id_episode, epi.id_patient
                                                 FROM episode epi
                                                INNER JOIN epis_info ei
                                                   ON ei.id_episode = epi.id_episode
                                                  AND (SELECT pk_episode.get_soft_by_epis_type(epi.id_epis_type,
                                                                                               epi.id_institution)
                                                         FROM dual) = ei.id_software
                                                INNER JOIN (SELECT epis.id_institution, COUNT(epis.id_episode) AS total
                                                             FROM episode epis
                                                             JOIN epis_info epo
                                                               ON epo.id_episode = epis.id_episode
                                                            WHERE epo.flg_unknown = 'N'
                                                              AND epis.flg_status = 'A'
                                                              AND rownum > 0
                                                            GROUP BY epis.id_institution) acc
                                                   ON acc.id_institution = epi.id_institution
                                                WHERE (SELECT pk_date_utils.trunc_insttimezone(alert.profissional(NULL,
                                                                                                                  epi.id_institution,
                                                                                                                  NULL),
                                                                                               current_timestamp,
                                                                                               NULL)
                                                         FROM dual) >=
                                                      pk_date_utils.trunc_insttimezone(alert.profissional(NULL,
                                                                                                          epi.id_institution,
                                                                                                          NULL),
                                                                                       epi.dt_begin_tstz,
                                                                                       NULL)
                                                  AND epi.flg_status = 'A'
                                                  AND ei.flg_unknown = 'Y'
                                                  AND acc.total > 0) data
                                            ON sad1.id_episode = data.id_episode
                                           AND sad1.id_patient = data.id_patient))
        LOOP
            l_prof := profissional(inactive_alerts.id_prof, inactive_alerts.id_institution, inactive_alerts.id_software);
        
            IF NOT pk_alerts.delete_sys_alert_event(i_lang         => i_lang,
                                                    i_prof         => l_prof,
                                                    i_id_sys_alert => l_sys_alert,
                                                    i_id_record    => inactive_alerts.id_record,
                                                    o_error        => o_error)
            THEN
                RAISE e_call;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'ALERT_INP_TEMP_EPISODES',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END alert_inp_temp_episodes;

    -- Setting environment vriables
    PROCEDURE set_context_parameters
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_flg_profile   IN VARCHAR2,
        i_hand_off_type IN VARCHAR2
    ) IS
    
    BEGIN
    
        -- set_context_parameters( i_prof => i_prof, i_flg_profile => l_flg_profile, i_hand_off_type => l_hand_off_type );
    
        pk_context_api.set_parameter('i_institution', i_prof.institution);
        pk_context_api.set_parameter('i_prof', i_prof.id);
        pk_context_api.set_parameter('i_software', i_prof.software);
        pk_context_api.set_parameter('i_lang', i_lang);
    
        IF i_flg_profile IS NOT NULL
        THEN
            pk_context_api.set_parameter('l_flg_profile', i_flg_profile);
        END IF;
    
        IF i_hand_off_type IS NOT NULL
        THEN
            pk_context_api.set_parameter('l_hand_off_type', i_hand_off_type);
        END IF;
    
    END set_context_parameters;

    FUNCTION get_epis_info_software
    (
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN NUMBER IS
        tbl_software table_number;
        l_return     NUMBER;
    BEGIN
    
        SELECT ei.id_software
          BULK COLLECT
          INTO tbl_software
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        CASE
            WHEN tbl_software.count = 1 THEN
                l_return := tbl_software(1);
            WHEN tbl_software.count > 1 THEN
                l_return := i_prof.software;
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END get_epis_info_software;

    /********************************************************************************************
    * Esta função obtém os alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_alert         Array com todos os alertas disponíveis para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/12
    ********************************************************************************************/
    FUNCTION get_prof_alerts
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_alert OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        aux_sql pk_types.cursor_type;
        --l_func_name CONSTANT VARCHAR2(30) := 'GET_PROF_ALERTS';
        -- Cursor para obter o query a executar para obter os
        -- alertas disponíveis para o profissional
        -- [JS] 2008/03/12: Por defeito usa codigo antigo
        CURSOR c_prof_views IS
            SELECT a.id_sys_alert, a.sql_alert alert_sql, a.flg_detail
              FROM sys_alert a
              JOIN sys_alert_prof b
                ON b.id_sys_alert = a.id_sys_alert
             WHERE b.id_institution = i_prof.institution
               AND b.id_software = i_prof.software
               AND b.id_professional = i_prof.id
             ORDER BY a.id_sys_alert;
    
        l_aux                sys_alert_temp%ROWTYPE;
        l_id_sys_alert       sys_alert.id_sys_alert%TYPE;
        l_id_software        software.id_software%TYPE;
        l_prof_cat           category.flg_type%TYPE;
        l_flg_profile        profile_template.flg_profile%TYPE;
        l_hand_off_type      sys_config.value%TYPE;
        l_resp_icons_table   table_varchar;
        l_resp_icons_str     VARCHAR2(300);
        l_msg_not_applicable sys_message.desc_message%TYPE;
        l_flg_process        VARCHAR2(0010 CHAR);
    
        tbl_hhc_alerts table_number := table_number(332, 333, 325, 326, 327, 329);
    
        --l_start     PLS_INTEGER;
        l_err_alert VARCHAR2(1000 CHAR);
    
        -- convert clob to varchar2
        FUNCTION clob2varchar(i_str_clob CLOB) RETURN VARCHAR2 IS
            l_str_varchar VARCHAR2(32767);
            l_amount      PLS_INTEGER := 32767;
        
            e_clob2varchar EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_clob2varchar, -06502);
        BEGIN
            -- copy characters of the buffer
            l_str_varchar := to_char(i_str_clob);
            RETURN l_str_varchar;
        
        EXCEPTION
            WHEN e_clob2varchar THEN
                -- copy bytes of the buffer
                dbms_lob.read(i_str_clob, l_amount, 1, l_str_varchar);
                RETURN l_str_varchar;
        END;
    BEGIN
    
        l_flg_process := pk_sysconfig.get_config('PROCESS_GET_PROF_ALERTS', i_prof.institution, i_prof.software);
    
        IF nvl(l_flg_process, pk_alert_constant.g_no) != pk_alert_constant.g_yes
        THEN
            pk_types.open_my_cursor(o_alert);
            RETURN TRUE;
        END IF;
    
        -- Apaga todos os registos da tabela temporária
        DELETE sys_alert_temp;
    
        -- José Brito 27/10/2009 ALERT-39320  Support for multiple hand-off mechanism
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_flg_profile := pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL);
        -- José Brito 25/09/2009 ALERT-45892  EDIS Ancillary profile: Activate OK button in the patient transport alert
        g_error := 'GET PROFESSIONAL CATEGORY';
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        l_msg_not_applicable := pk_message.get_message(i_lang => i_lang, i_code_mess => g_code_msg_not_applicable);
    
        g_error := 'REPLACE BIND VARIABLES';
    
        set_context_parameters(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_flg_profile   => l_flg_profile,
                               i_hand_off_type => l_hand_off_type);
        g_error := 'REPLACED BIND VARIABLES';
    
        --DETERMINA ALERTAS DO PROFISSIONAL/APLICAÇÃO/INSTITUIÇÃO
        FOR i IN c_prof_views
        LOOP
            g_error        := '';
            l_id_sys_alert := i.id_sys_alert;
            l_err_alert    := 'ALERT #' || i.id_sys_alert || '-->';
            g_error        := 'FETCH ALERT ' || l_id_sys_alert;
            OPEN aux_sql FOR clob2varchar(i.alert_sql);
        
            g_error := 'Start LOOP';
            LOOP
            
                FETCH aux_sql
                    INTO l_aux.id_sys_alert_det,
                         l_aux.id_reg,
                         l_aux.id_episode,
                         l_aux.id_institution,
                         l_aux.id_prof, --
                         l_aux.dt_req,
                         l_aux.time,
                         l_aux.message,
                         l_aux.id_room,
                         l_aux.id_patient,
                         l_aux.name_pat,
                         l_aux.pat_ndo,
                         l_aux.pat_nd_icon,
                         l_aux.photo, --
                         l_aux.gender,
                         l_aux.pat_age,
                         l_aux.desc_room,
                         l_aux.date_send,
                         l_aux.desc_epis_anamnesis,
                         l_aux.acuity, --
                         l_aux.rank_acuity,
                         l_aux.id_schedule,
                         l_aux.id_sys_shortcut,
                         l_aux.id_reg_det,
                         l_aux.id_sys_alert, --
                         l_aux.dt_first_obs_tstz,
                         l_aux.fast_track_icon,
                         l_aux.fast_track_color,
                         l_aux.fast_track_status,
                         l_aux.esi_level,
                         l_aux.name_pat_sort,
                         l_resp_icons_table, -- this is used due to function pk_hand_off_api.get_resp_icons
                         l_aux.id_prof_order;
            
                EXIT WHEN aux_sql%NOTFOUND;
            
                l_id_sys_alert := l_aux.id_sys_alert;
            
                -- PEGAR O SOFTWARE DE ORIGEM
                g_error       := 'Software origin';
                l_id_software := get_epis_info_software(i_prof => i_prof, i_episode => l_aux.id_episode);
            
                -- transforms the table_varchar in varchar2 separated by '|' due to function pk_hand_off_api.get_resp_icons
                l_resp_icons_str := pk_utils.concat_table(i_tab       => l_resp_icons_table,
                                                          i_delim     => '|',
                                                          i_start_off => NULL,
                                                          i_length    => NULL);
            
                -- INSERIR RESULTADOS DO SQL ALERT PARA TABELA TEMPORARIA
                g_error := 'INSERT INTO SYS_ALERT_TEMP';
                INSERT INTO sys_alert_temp
                    (id_sys_alert_det,
                     id_reg,
                     id_episode,
                     id_institution,
                     id_prof,
                     dt_req,
                     TIME,
                     message,
                     id_room,
                     id_patient,
                     name_pat,
                     photo,
                     gender,
                     pat_age,
                     desc_room,
                     date_send,
                     desc_epis_anamnesis,
                     acuity,
                     rank_acuity,
                     dt_first_obs_tstz,
                     id_schedule,
                     id_sys_shortcut,
                     id_reg_det,
                     id_sys_alert,
                     flg_detail,
                     id_software_origin,
                     pat_ndo,
                     pat_nd_icon,
                     fast_track_icon,
                     fast_track_color,
                     fast_track_status,
                     esi_level,
                     name_pat_sort,
                     resp_icons,
                     id_prof_order)
                VALUES
                    (l_aux.id_sys_alert_det,
                     l_aux.id_reg,
                     l_aux.id_episode,
                     l_aux.id_institution,
                     l_aux.id_prof,
                     l_aux.dt_req,
                     l_aux.time,
                     l_aux.message,
                     l_aux.id_room,
                     l_aux.id_patient,
                     l_aux.name_pat,
                     l_aux.photo,
                     l_aux.gender,
                     l_aux.pat_age,
                     l_aux.desc_room,
                     l_aux.date_send,
                     l_aux.desc_epis_anamnesis,
                     l_aux.acuity,
                     l_aux.rank_acuity,
                     l_aux.dt_first_obs_tstz,
                     l_aux.id_schedule,
                     decode(pk_sign_off.get_epis_sign_off_state(i_lang, i_prof, l_aux.id_episode),
                            pk_alert_constant.g_no,
                            l_aux.id_sys_shortcut,
                            decode(l_aux.id_sys_alert,
                                   15,
                                   pk_sign_off.g_so_ss_lab,
                                   12,
                                   decode(l_aux.id_sys_shortcut,
                                          11,
                                          pk_sign_off.g_so_ss_exam,
                                          10,
                                          pk_sign_off.g_so_ss_imag),
                                   3,
                                   decode(l_aux.id_sys_shortcut,
                                          11,
                                          pk_sign_off.g_so_ss_exam,
                                          10,
                                          pk_sign_off.g_so_ss_imag),
                                   52,
                                   pk_sign_off.g_so_ss_pend_issues,
                                   pk_sign_off.g_so_addendum)),
                     l_aux.id_reg_det,
                     l_aux.id_sys_alert,
                     i.flg_detail,
                     l_id_software,
                     l_aux.pat_ndo,
                     l_aux.pat_nd_icon,
                     l_aux.fast_track_icon,
                     l_aux.fast_track_color,
                     l_aux.fast_track_status,
                     l_aux.esi_level,
                     l_aux.name_pat_sort,
                     l_resp_icons_str,
                     l_aux.id_prof_order);
            END LOOP;
        
            CLOSE aux_sql;
        
        END LOOP;
        g_error := 'OPEN CURSOR COM RESULTADOS FINAIS';
        OPEN o_alert FOR
            SELECT sat.id_sys_alert_det,
                   sat.id_reg,
                   sat.id_episode,
                   sat.id_institution,
                   sat.id_prof,
                   sat.dt_req,
                   sat.time,
                   sat.message,
                   sat.id_room,
                   sat.id_patient,
                   sat.name_pat,
                   sat.pat_ndo,
                   sat.pat_nd_icon,
                   sat.photo,
                   pk_sysdomain.get_domain('PATIENT.GENDER.ABBR', sat.gender, i_lang) AS gender,
                   sat.pat_age,
                   sat.desc_room,
                   sat.date_send,
                   sat.desc_epis_anamnesis,
                   sat.acuity,
                   sat.rank_acuity,
                   pk_date_utils.date_mon_hour_format_tsz(i_lang, dt_first_obs_tstz, i_prof) dt_first_obs_tstz,
                   sat.id_schedule,
                   sat.id_sys_shortcut,
                   sat.id_reg_det,
                   sat.id_sys_alert,
                   sat.flg_detail,
                   sat.id_software_origin,
                   sat.fast_track_icon,
                   sat.fast_track_color,
                   sat.fast_track_status,
                   sat.esi_level,
                   sat.name_pat_sort,
                   sat.resp_icons,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_age,
                                                              i_episode => sat.id_episode) pat_age_for_order_by,
                   pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_type    => pk_edis_proc.g_sort_type_los,
                                                              i_episode => sat.id_episode) date_send_sort,
                   CASE
                        WHEN sat.id_sys_alert IN (pk_alert_constant.g_alert_hhc_team, pk_opinion.g_alert_end_followup) THEN
                         decode(i_prof.software,
                                pk_alert_constant.g_soft_home_care,
                                pk_alert_constant.get_yes,
                                pk_alert_constant.get_no)
                        WHEN i_prof.software IN (sat.id_software_origin,
                                                 pk_alert_constant.g_soft_labtech,
                                                 pk_alert_constant.g_soft_imgtech,
                                                 pk_alert_constant.g_soft_extech,
                                                 23,
                                                 20,
                                                 33,
                                                 35,
                                                 36,
                                                 43,
                                                 310,
                                                 52) THEN
                         decode(sat.id_episode,
                                -1,
                                decode(sat.id_sys_alert, 52, pk_alert_constant.get_no, pk_alert_constant.get_yes),
                                pk_alert_constant.get_yes)
                    -- Foi acrescentado para contemplar a funcionalidade de MFR
                    -- e mm suposto o medico do OUTP, INP e PP conseguir agir sobre o alerta que vem do software de MFR
                        WHEN i_prof.software IN (1, 11, 12)
                             AND sat.id_software_origin = 36
                             AND sat.id_sys_alert IN (48, 49) THEN
                         pk_alert_constant.get_yes
                        WHEN sat.id_sys_alert IN (53,
                                                  54,
                                                  55,
                                                  56,
                                                  57,
                                                  58,
                                                  59,
                                                  62,
                                                  -- 63,
                                                  pk_opinion.g_alert_needs_approval,
                                                  pk_opinion.g_alert_approval_reply,
                                                  pk_opinion.g_alert_acceptance_reply,
                                                  pk_epis_er_law_core.g_ges_sys_alert) THEN
                         pk_alert_constant.get_yes
                        WHEN sat.id_sys_alert = 63
                             AND (sat.id_episode = -1 OR sat.id_episode IS NULL) THEN
                         pk_alert_constant.get_no
                        WHEN i_prof.software = 1
                            --[OA - 2010/01/13]
                            --Nutrition appointment - 43
                            --Opinion request with origen in INPATIENT/EDIS episodes - 8 and 11
                             AND sat.id_software_origin IN (43, 310, 8, 11)
                             AND sat.id_sys_alert = 18 THEN
                         pk_alert_constant.get_yes
                    -- José Brito 25/09/2009 ALERT-45892  EDIS Ancillary profile: Activate OK button in the patient transport alert
                        WHEN sat.id_sys_alert IN (5, 9, 13)
                             AND sat.id_software_origin = 11
                             AND i_prof.software = 8
                             AND l_prof_cat = 'O' THEN
                         pk_alert_constant.get_yes
                    -- Social worker profiles: OK must only be enabled for the 85 and 89 alert
                        WHEN i_prof.software = pk_alert_constant.g_soft_social
                             AND sat.id_sys_alert IN (85, 89, 52) THEN
                         CASE
                             WHEN sat.id_sys_alert = 52
                                  AND l_prof_cat = pk_alert_constant.g_flg_profile_religious THEN
                              pk_alert_constant.g_no
                             ELSE
                              pk_alert_constant.g_yes
                         END
                    -- Activity Therapist profile: OK must only be enabled for the 95 alert
                        WHEN i_prof.software = pk_alert_constant.g_soft_act_therapist
                             AND sat.id_sys_alert IN (95) THEN
                         pk_alert_constant.g_yes
                    -- Case manager profile: OK must only be enabled for the 52 alert
                        WHEN i_prof.software = pk_alert_constant.g_soft_case_manager
                             AND sat.id_sys_alert = 52 THEN
                         pk_alert_constant.g_yes
                    -- scheduler 3 cancel and reschedule alerts
                        WHEN sat.id_sys_alert IN (102, 103) THEN
                         pk_alert_constant.g_yes
                    -- Referral    alerts
                        WHEN i_prof.software = pk_alert_constant.g_soft_referral THEN
                         pk_alert_constant.g_yes
                    -- Imaging and Others Exams must only be enabled for the 3 alert
                        WHEN i_prof.software = 1
                             AND sat.id_software_origin IN (25, 15)
                             AND sat.id_sys_alert = 3 THEN
                         pk_alert_constant.get_yes
                        WHEN i_prof.software = 39 THEN
                         pk_alert_constant.get_yes
                        WHEN (sat.id_sys_alert MEMBER OF tbl_hhc_alerts) THEN
                         pk_alert_constant.get_yes
                        ELSE
                         pk_alert_constant.get_no
                    END flg_ok_enabled,
                   --ASantos 21-11-20011
                   --ALERT-195554 - Chile | Ability to interface information regarding management of GES
                   CASE
                        WHEN sat.id_sys_alert = pk_epis_er_law_core.g_ges_sys_alert THEN
                         pk_epis_er_law_api.get_ges_url(i_lang => i_lang, i_prof => i_prof, i_patient => sat.id_patient)
                        ELSE
                         NULL
                    END url_ges_ext_app,
                   pk_prof_follow.get_follow_episode_by_me(i_prof, sat.id_episode, nvl(sat.id_schedule, -1)) prof_follow_remove,
                   nvl(pk_episode.get_epis_clinical_serv(i_lang, i_prof, sat.id_episode), l_msg_not_applicable) clinical_service,
                   nvl(pk_prof_utils.get_name_signature(1, i_prof, sat.id_prof_order), l_msg_not_applicable) prof_name,
                   nvl(pk_episode.get_epis_clinical_serv(i_lang, i_prof, sat.id_episode), '') clinical_service_order,
                   nvl(pk_prof_utils.get_name_signature(1, i_prof, sat.id_prof_order), '') prof_name_order,
                   pk_hhc_core.get_id_hhc_req_by_epis(i_id_episode => sat.id_episode) id_epis_hhc_req
              FROM sys_alert_temp sat
             ORDER BY sat.dt_req ASC;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              l_err_alert || SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_ALERTS',
                                              o_error);
            pk_types.open_my_cursor(o_alert);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_prof_alerts;

    /********************************************************************************************
    * Esta função determina o número de alertas disponíveis para o profissional.
    *
    * @param i_lang          Id do idioma
    * @param i_prof          ID do profissional, instituição e software
    * @param o_num_alerts    Número de alertas disponível para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/25
    ********************************************************************************************/
    FUNCTION get_prof_alerts_count
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_num_alerts OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        aux_sql pk_types.cursor_type;
    
        k_sp         CONSTANT VARCHAR2(0010 CHAR) := chr(32);
        k_sql_prefix CONSTANT VARCHAR2(1000 CHAR) := 'SELECT COUNT(*) XCOUNT FROM ';
        l_sql VARCHAR2(4000);
    
        CURSOR c_prof_views IS
            SELECT a.id_sys_alert, a.sql_count
              FROM sys_alert a
              JOIN sys_alert_prof b
                ON b.id_sys_alert = a.id_sys_alert
             WHERE b.id_institution = i_prof.institution
               AND b.id_software = i_prof.software
               AND b.id_professional = i_prof.id;
    
        l_hand_off_type sys_config.value%TYPE;
        l_flg_profile   profile_template.flg_profile%TYPE;
        l_flg_process   VARCHAR2(0001 CHAR);
        l_num_alerts    NUMBER := 0;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_flg_process := pk_sysconfig.get_config('PROCESS_GET_PROF_ALERTS_COUNT', i_prof.institution, i_prof.software);
    
        IF nvl(l_flg_process, pk_alert_constant.g_no) != pk_alert_constant.g_yes
        THEN
            o_num_alerts := 0;
            RETURN TRUE;
        END IF;
    
        -- Apaga todos os registos da tabela temporária
        DELETE sys_alert_temp;
        l_num_alerts := 0;
    
        -- José Brito 27/10/2009 ALERT-39320  Support for multiple hand-off mechanism
        g_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_flg_profile := pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL);
    
        set_context_parameters(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_flg_profile   => l_flg_profile,
                               i_hand_off_type => l_hand_off_type);
    
        --DETERMINA ALERTAS DO PROFISSIONAL/APLICAÇÃO/INSTITUIÇÃO
        <<lup_thru_prof_alerts>>
        FOR i IN c_prof_views
        LOOP
        
            IF i.sql_count IS NOT NULL
            THEN
                l_sql := k_sql_prefix || k_sp || i.sql_count;
            ELSE
                CONTINUE lup_thru_prof_alerts;
            END IF;
        
            OPEN aux_sql FOR l_sql;
        
            LOOP
                FETCH aux_sql
                    INTO l_count;
            
                EXIT WHEN aux_sql%NOTFOUND;
            
                IF aux_sql%FOUND
                THEN
                    l_num_alerts := l_num_alerts + l_count;
                END IF;
            
                l_count := 0;
            
            END LOOP;
        
            CLOSE aux_sql;
        
        END LOOP lup_thru_prof_alerts;
    
        o_num_alerts := l_num_alerts;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_ALERTS_COUNT',
                                              o_error);
            pk_utils.undo_changes;
            o_num_alerts := 0;
            RETURN FALSE;
    END get_prof_alerts_count;

    /********************************************************************************************
    * Esta função determina o ID do shortcut para um alerta.
    *
    * @param i_prof          ID do profissional, instituição e software
    * @param i_sys_alert     ID do tipo de alerta
    * @param o_num_alerts    Número de alertas disponível para o profissional
    * @param o_error         Mensagem de erro
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Rui Batista
    * @version               1.0
    * @since                 2007/07/25
    ********************************************************************************************/
    FUNCTION get_alerts_shortcut
    (
        i_prof      IN profissional,
        i_sys_alert IN sys_alert.id_sys_alert%TYPE
    ) RETURN PLS_INTEGER IS
    
        l_shortcut sys_alert_config.id_sys_shortcut%TYPE;
    
        CURSOR c_short IS
            SELECT sas.id_sys_shortcut
              FROM sys_alert_config sas
             WHERE id_sys_alert = i_sys_alert
               AND id_institution IN (0, i_prof.institution)
               AND id_software IN (0, i_prof.software)
               AND nvl(sas.id_profile_template, 0) IN
                   (SELECT 0
                      FROM dual
                    UNION ALL
                    SELECT ppt.id_profile_template
                      FROM prof_profile_template ppt, profile_template pt
                     WHERE ppt.id_professional = i_prof.id
                       AND ppt.id_software = i_prof.software
                       AND ppt.id_institution = i_prof.institution
                       AND pt.id_profile_template = ppt.id_profile_template
                       AND pt.id_software = i_prof.software)
             ORDER BY sas.id_software DESC, sas.id_institution DESC;
    
    BEGIN
    
        OPEN c_short;
        FETCH c_short
            INTO l_shortcut;
        CLOSE c_short;
    
        RETURN l_shortcut;
    END;

    /**
    * Gets alert message to display
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional, institution and software ids
    * @param i_id_sys_alert    Alert ID
    * @param i_replace1        Replace field #1
    * @param i_replace2        Replace field #2
    * @param i_translate       Translate i_replace1 Y/N
    *
    * @RETURN
    * @author  Rui Batista
    * @version 1.0
    * @since   18-03-2008
    * @changed 2.4.4 Rui Spratley
    */
    FUNCTION get_alert_message
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_replace1     IN VARCHAR2,
        i_replace2     IN VARCHAR2,
        i_translate    IN VARCHAR2 DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
        l_return    VARCHAR2(4000);
        tbl_message table_varchar;
    BEGIN
    
        SELECT pk_alerts.do_alert_message(i_lang          => i_lang,
                                          i_flg_duplicate => sac.flg_duplicate,
                                          i_msg_dup_no    => sac.msg_dup_no,
                                          i_msg_dup_yes   => sac.msg_dup_yes,
                                          i_translate     => i_translate,
                                          i_replace1      => i_replace1,
                                          i_replace2      => i_replace2) message
          BULK COLLECT
          INTO tbl_message
          FROM sys_alert_prof sap
          JOIN sys_alert_config sac
            ON sac.id_software = sap.id_software
             WHERE sap.id_professional = i_prof.id
               AND sap.id_software = i_prof.software
               AND sap.id_institution = i_prof.institution
               AND sap.id_sys_alert = i_id_sys_alert
               AND sac.id_sys_alert = sap.id_sys_alert
               AND sac.id_institution IN (sap.id_institution, 0)
               AND sac.id_profile_template = sap.id_profile_template
             ORDER BY sac.id_institution DESC, sac.id_software DESC;
    
        IF tbl_message.count > 0
        THEN
            l_return := tbl_message(1);
        END IF;
    
        RETURN l_return;
    
    END get_alert_message;

    /**
    * Gets alert message just like it will be displayed
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional, institution and software ids
    * @param i_id_sys_alert          Alert ID
    * @param i_id_sys_alert_event    Alert event ID
    *
    * @author  Tiago Silva
    * @version 1.0
    * @since   01-05-2009
    */
    FUNCTION get_sms_alert_message
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sys_alert       IN sys_alert.id_sys_alert%TYPE,
        i_id_sys_alert_event IN sys_alert_event.id_sys_alert_event%TYPE
    ) RETURN VARCHAR2 IS
    
        l_alert_sql  CLOB;
        c_alert_sql  pk_types.cursor_type;
        l_alert_data sys_alert_temp%ROWTYPE;
    
        -- convert clob to varchar2
        FUNCTION clob2varchar(i_str_clob CLOB) RETURN VARCHAR2 IS
            l_str_varchar VARCHAR2(32767);
            l_amount      PLS_INTEGER := 32767;
        
            e_clob2varchar EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_clob2varchar, -06502);
        BEGIN
            -- copy characters of the buffer
            l_str_varchar := to_char(i_str_clob);
            RETURN l_str_varchar;
        
        EXCEPTION
            WHEN e_clob2varchar THEN
                -- copy bytes of the buffer
                dbms_lob.read(i_str_clob, l_amount, 1, l_str_varchar);
                RETURN l_str_varchar;
        END;
    BEGIN
    
        g_error     := 'GET ALERT SQL';
        l_alert_sql := get_sql_alert(i_id_sys_alert => i_id_sys_alert);
    
        g_error := 'REPLACE BIND VARIABLES';
    
        set_context_parameters(i_lang => i_lang, i_prof => i_prof, i_flg_profile => NULL, i_hand_off_type => NULL);
    
        /*
            pk_context_api.set_parameter('i_institution', i_prof.institution);
            pk_context_api.set_parameter('i_prof', i_prof.id);
            pk_context_api.set_parameter('i_software', i_prof.software);
            pk_context_api.set_parameter('i_lang', i_lang);
        */
    
        g_error := 'FETCH ALERT SQL CURSOR';
    
        OPEN c_alert_sql FOR clob2varchar(l_alert_sql);
    
        LOOP
            FETCH c_alert_sql
                INTO l_alert_data.id_sys_alert_det,
                     l_alert_data.id_reg,
                     l_alert_data.id_episode,
                     l_alert_data.id_institution,
                     l_alert_data.id_prof, --
                     l_alert_data.dt_req,
                     l_alert_data.time,
                     l_alert_data.message,
                     l_alert_data.id_room,
                     l_alert_data.id_patient,
                     l_alert_data.name_pat,
                     l_alert_data.pat_ndo,
                     l_alert_data.pat_nd_icon,
                     l_alert_data.photo, --
                     l_alert_data.gender,
                     l_alert_data.pat_age,
                     l_alert_data.desc_room,
                     l_alert_data.date_send,
                     l_alert_data.desc_epis_anamnesis,
                     l_alert_data.acuity, --
                     l_alert_data.rank_acuity,
                     l_alert_data.id_schedule,
                     l_alert_data.id_sys_shortcut,
                     l_alert_data.id_reg_det,
                     l_alert_data.id_sys_alert, --
                     l_alert_data.dt_first_obs_tstz,
                     l_alert_data.fast_track_icon,
                     l_alert_data.fast_track_color,
                     l_alert_data.fast_track_status,
                     l_alert_data.esi_level;
        
            EXIT WHEN c_alert_sql%NOTFOUND OR(l_alert_data.id_sys_alert_det = i_id_sys_alert_event);
        END LOOP;
    
        CLOSE c_alert_sql;
    
        RETURN l_alert_data.message;
    END get_sms_alert_message;

    /********************************************************************************************
    * Inserts on record into the event table.
    * In this case the visit id and the patient id are obtained from the episode.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_sys_alert           Record to insert
    * @param i_id_episode          Episode ID
    * @param i_id_record           Detail ID (eg. id_analysis_req_det for harvest alerts)
    * @param i_dt_record           Record date (eg. analysis_req_det.dt_begin for harvest alerts)
    * @param i_id_professional     Professional ID (if the alert has a well defined target, null otherwise)
    * @param i_id_room             Room ID (id the alert is to be shown to every professional of a room, null otherwise)
    * @param i_id_clinical_service Clinical Service ID (id the alert is to be shown to every professional of a clinical service, null otherwise)
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
    *                               C- Clinical Service, R- room
    * @param i_replace1            Replace value for alert message
    * @param i_replace2            Replace value for alert message
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION get_room_by_episode(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_room table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_room
          BULK COLLECT
          INTO tbl_room
          FROM epis_info
         WHERE id_episode = i_episode;
    
        IF tbl_room.count > 0
        THEN
        
            l_return := tbl_room(1);
        
        END IF;
    
        RETURN l_return;
    
    END get_room_by_episode;

    FUNCTION get_clin_serv_by_episode(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_ids  table_number;
        l_return NUMBER;
    BEGIN
    
        --get episode's id_clinical_service
        g_error := 'GET EPISODE ID_CLINICAL_SERVICE';
        SELECT id_clinical_service
          BULK COLLECT
          INTO tbl_ids
          FROM episode
         WHERE id_episode = i_episode;
    
        IF tbl_ids.count > 0
        THEN
            l_return := tbl_ids(1);
        END IF;
    
        RETURN l_return;
    
    END get_clin_serv_by_episode;

    FUNCTION get_dcs_by_episode(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_dcs  table_number;
        l_return NUMBER;
    BEGIN
        SELECT id_dep_clin_serv
          BULK COLLECT
          INTO tbl_dcs
          FROM epis_info
         WHERE id_episode = i_episode;
    
        IF tbl_dcs.count > 0
        THEN
            l_return := tbl_dcs(1);
        END IF;
    
        RETURN l_return;
    
    END get_dcs_by_episode;

    PROCEDURE purge_all_alerts IS
        o_error t_error_out;
        l_bool  BOOLEAN;
    BEGIN
        l_bool := pk_alerts.purge_daily(i_lang => default_language, i_prof => profissional(0, 0, 0), o_error => o_error);
    END purge_all_alerts;

    /********************************************************************************************
    * Deletes records from the event table .
    *
    * @param i_lang                Language Id
    * @param i_episode             Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION purge_daily
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional DEFAULT profissional(0, 0, 0),
        i_purge_day IN TIMESTAMP WITH TIME ZONE DEFAULT current_timestamp,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_days           NUMBER(24);
        delete_exception EXCEPTION;
    
        CURSOR c_episode IS
            SELECT e.id_episode
              FROM episode e, sys_alert_event s
             WHERE flg_status NOT IN (g_epis_active, g_epis_pend)
               AND pk_date_utils.diff_timestamp(i_purge_day,
                                                nvl(e.dt_end_tstz, pk_date_utils.add_days_to_tstz(current_timestamp, 10))) >=
                   l_days
               AND s.id_episode = e.id_episode;
    BEGIN
        pk_alertlog.log_debug('Delete purge tables: purge_sys_alert_event');
        DELETE purge_sys_alert_event;
    
        pk_alertlog.log_debug('Delete purge tables: purge_sys_alert_read');
        DELETE purge_sys_alert_read;
    
        pk_alertlog.log_debug('DAYS_TO_PURGE_ALERTS');
        IF NOT pk_sysconfig.get_config('DAYS_TO_PURGE_ALERTS', i_prof.institution, i_prof.software, l_days)
        THEN
            pk_alertlog.log_warn('DAYS_TO_PURGE_ALERTS');
        END IF;
    
        pk_alertlog.log_debug('l_days IS NULL');
        IF l_days IS NULL
        THEN
            --se nao existir parametrização, são considerados 3 dias após a alta para apagar os alertas
            l_days := 3;
        END IF;
    
        pk_alertlog.log_debug('FOR c IN c_episode');
        FOR c IN c_episode
        LOOP
            BEGIN
                pk_alertlog.log_debug('insert purge tables: purge_sys_alert_event');
                INSERT INTO purge_sys_alert_event
                    (id_purge_sys_alert_event,
                     id_sys_alert,
                     id_software,
                     id_institution,
                     id_patient,
                     id_visit,
                     id_episode,
                     id_record,
                     dt_record,
                     id_professional,
                     id_room,
                     id_clinical_service,
                     flg_visible,
                     replace1,
                     replace2,
                     id_dep_clin_serv,
                     last_update_date)
                    SELECT id_sys_alert_event,
                           id_sys_alert,
                           id_software,
                           id_institution,
                           id_patient,
                           id_visit,
                           id_episode,
                           id_record,
                           dt_record,
                           id_professional,
                           id_room,
                           id_clinical_service,
                           flg_visible,
                           replace1,
                           replace2,
                           id_dep_clin_serv,
                           SYSDATE
                      FROM sys_alert_event
                     WHERE id_episode = c.id_episode;
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_owner,
                                                      g_package,
                                                      'PURGE_DAILY',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
            END;
        
            BEGIN
                pk_alertlog.log_debug('insert purge tables: purge_sys_alert_read');
                INSERT INTO purge_sys_alert_read
                    (id_purge_sys_alert_read,
                     id_sys_alert_det,
                     id_professional,
                     dt_read_tstz,
                     id_sys_alert_event,
                     last_update_date)
                    SELECT id_purge_sys_alert_read,
                           id_sys_alert_det,
                           id_professional,
                           dt_read_tstz,
                           id_sys_alert_event,
                           SYSDATE
                      FROM purge_sys_alert_read ps
                     WHERE id_sys_alert_event IN (SELECT id_sys_alert_event
                                                    FROM sys_alert_event e
                                                   WHERE e.id_episode = c.id_episode);
            EXCEPTION
                WHEN OTHERS THEN
                    pk_alert_exceptions.process_error(i_lang,
                                                      SQLCODE,
                                                      SQLERRM,
                                                      g_error,
                                                      g_owner,
                                                      g_package,
                                                      'PURGE_DAILY',
                                                      o_error);
                    pk_utils.undo_changes;
                    RETURN FALSE;
            END;
        
            pk_alertlog.log_debug('delete_sys_alert_event_episode');
            IF NOT delete_sys_alert_event_episode(i_lang, i_prof, c.id_episode, g_yes, o_error)
            THEN
                RAISE delete_exception;
            END IF;
        END LOOP;
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN delete_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error ||
                                              pk_message.get_message(i_lang,
                                                                     ' common_m001 ' || 'delete_sys_alert_event_episode'),
                                              g_owner,
                                              g_package,
                                              'PURGE_DAILY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'PURGE_DAILY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Deletes records from the event table .
    *
    * @param i_lang                Language Id
    * @param i_episode             Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event_episode
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_delete  IN VARCHAR2 DEFAULT 'N',
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF i_delete = g_no
        THEN
            pk_alertlog.log_debug('i_delete = g_no');
            -- All but the the first (oldest) are set o 'N'
            UPDATE sys_alert_event s
               SET flg_visible = g_no
             WHERE s.id_episode = i_episode
               AND flg_visible = g_yes;
        ELSE
            pk_alertlog.log_debug('DELETE FROM SYS_ALERT_READ');
        
            --Eliminar informação de leitura do alerta pelos profissionais
            g_error := 'DELETE FROM SYS_ALERT_READ';
            DELETE FROM sys_alert_read r
             WHERE id_sys_alert_event IN (SELECT id_sys_alert_event
                                            FROM sys_alert_event e
                                           WHERE e.id_episode = i_episode);
        
            pk_alertlog.log_debug('sys_alert_event');
        
            -- Eliminar registo para o tipo de alerta, episodio e id_record indicados.
            g_error := 'DELETE FROM SYS_ALERT_EVENT';
            DELETE FROM sys_alert_event e
             WHERE e.id_episode = i_episode;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_SYS_ALERT_EVENT_EPISODE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Deletes records from the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_
        (
            x_alert sys_alert.id_sys_alert%TYPE,
            x_epis  episode.id_episode%TYPE
        ) IS
            SELECT e.id_sys_alert_event
              FROM sys_alert_event e
             WHERE e.id_sys_alert = x_alert
               AND e.id_episode = x_epis
             ORDER BY e.dt_record;
    
        CURSOR p_
        (
            x_alert        sys_alert.id_sys_alert%TYPE,
            x_epis         episode.id_episode%TYPE,
            x_professional professional.id_professional%TYPE
        ) IS
            SELECT e.id_sys_alert_event
              FROM sys_alert_event e
             WHERE e.id_sys_alert = x_alert
               AND e.id_episode = x_epis
               AND (e.id_professional = x_professional AND x_professional IS NOT NULL AND e.id_professional IS NOT NULL)
                OR (x_professional IS NULL AND e.id_professional IS NULL)
             ORDER BY e.dt_record;
    
        l_alert_config_row       sys_alert_config%ROWTYPE;
        l_id_sys_alert_event     sys_alert_event.id_sys_alert_event%TYPE;
        l_tab_id_sys_alert_event table_number := table_number();
        l_delete_all             sys_config.desc_sys_config%TYPE;
    
    BEGIN
    
        l_delete_all := nvl(pk_sysconfig.get_config('ALERT_DELETE_ALL_PROF', i_prof), pk_alert_constant.g_yes);
        --Obtém o registo a eliminar
        g_error := 'GET ID_SYS_ALERT_EVENT';
        IF i_sys_alert_event.id_sys_alert_event IS NOT NULL
        THEN
            l_tab_id_sys_alert_event := table_number(i_sys_alert_event.id_sys_alert_event);
        ELSE
            BEGIN
                IF l_delete_all = pk_alert_constant.g_yes
                THEN
                    --Obtém o registo a eliminar
                    SELECT e.id_sys_alert_event
                      BULK COLLECT
                      INTO l_tab_id_sys_alert_event
                      FROM sys_alert_event e
                     WHERE e.id_sys_alert = i_sys_alert_event.id_sys_alert
                          --added this filter to avoid deleting records from other institutions
                       AND e.id_institution = i_prof.institution
                       AND e.id_record = i_sys_alert_event.id_record;
                ELSE
                    --Obtém o registo a eliminar
                    SELECT e.id_sys_alert_event
                      BULK COLLECT
                      INTO l_tab_id_sys_alert_event
                      FROM sys_alert_event e
                     WHERE e.id_sys_alert = i_sys_alert_event.id_sys_alert
                          --added this filter to avoid deleting records from other institutions
                       AND e.id_institution = i_prof.institution
                       AND e.id_record = i_sys_alert_event.id_record
                       AND (e.id_professional IS NULL OR
                           (e.id_professional IS NOT NULL AND e.id_professional = i_prof.id));
                
                END IF;
            EXCEPTION
                WHEN no_data_found THEN
                    --Não encontrou registo a eliminar. Sai sem fazer nada
                    RETURN TRUE;
            END;
        END IF;
    
        -- Eliminar informação de leitura do alerta pelos profissionais
        g_error := 'DELETE FROM SYS_ALERT_READ';
        DELETE FROM sys_alert_read
         WHERE id_sys_alert_event IN (SELECT /*+ opt_estimate(table t rows=1*/
                                       column_value
                                        FROM TABLE(l_tab_id_sys_alert_event) t);
    
        -- Eliminar registo para o tipo de alerta, episodio e id_record indicados.
        g_error := 'DELETE FROM SYS_ALERT_EVENT';
        DELETE FROM sys_alert_event e
         WHERE id_sys_alert_event IN (SELECT /*+ opt_estimate(table t rows=1*/
                                       column_value
                                        FROM TABLE(l_tab_id_sys_alert_event) t);
    
        pk_alerts_api_crm.delete_notification(l_tab_id_sys_alert_event);
    
        -- Get configuration for this type of alert
        g_error            := 'GET ALERT CONFIG';
        l_alert_config_row := get_config(i_lang, i_prof, i_sys_alert_event.id_sys_alert, NULL);
        IF l_alert_config_row.id_sys_alert_config IS NULL
        THEN
            pk_alertlog.log_warn('Alert id: ' || i_sys_alert_event.id_sys_alert || ' not configured for software: ' ||
                                 i_prof.software || ' and institution: ' || i_prof.institution);
            RETURN TRUE;
        END IF;
    
        -- If can't have duplicates...
        IF l_alert_config_row.flg_duplicate = g_no
        THEN
            IF l_delete_all = pk_alert_constant.g_no
            THEN
                OPEN p_(i_sys_alert_event.id_sys_alert, i_sys_alert_event.id_episode, i_prof.id);
                FETCH p_
                    INTO l_id_sys_alert_event;
                CLOSE p_;
                -- All but the the first (oldest) are set o 'N'
                UPDATE sys_alert_event se
                   SET flg_visible = g_no
                 WHERE id_episode = i_sys_alert_event.id_episode
                   AND id_sys_alert = i_sys_alert_event.id_sys_alert
                   AND id_sys_alert_event != l_id_sys_alert_event
                   AND ((se.id_professional = i_prof.id AND se.id_professional IS NOT NULL) OR
                       se.id_professional IS NULL)
                   AND flg_visible = g_yes;
            ELSE
                OPEN c_(i_sys_alert_event.id_sys_alert, i_sys_alert_event.id_episode);
                FETCH c_
                    INTO l_id_sys_alert_event;
                CLOSE c_;
                -- All but the the first (oldest) are set o 'N'
                UPDATE sys_alert_event se
                   SET flg_visible = g_no
                 WHERE id_episode = i_sys_alert_event.id_episode
                   AND id_sys_alert = i_sys_alert_event.id_sys_alert
                   AND id_sys_alert_event != l_id_sys_alert_event
                   AND flg_visible = g_yes;
            END IF;
            -- The first (oldest) is set o 'Y'
            UPDATE sys_alert_event
               SET flg_visible = g_yes
             WHERE id_sys_alert_event = l_id_sys_alert_event
               AND flg_visible = g_no;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_SYS_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Deletes records from the event table.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution and software ids
    * @param i_id_sys_alert        Sys_alert_event id
    * @param i_id_record           Record id
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Paulo Fonseca
    * @version                     2.5.0.2
    * @since                       2009/04/20
    ********************************************************************************************/
    FUNCTION delete_sys_alert_event
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert_event.id_sys_alert%TYPE,
        i_id_record    IN sys_alert_event.id_record%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
    BEGIN
    
        l_sys_alert_event.id_sys_alert := i_id_sys_alert;
        l_sys_alert_event.id_record    := i_id_record;
    
        RETURN pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_sys_alert_event => l_sys_alert_event,
                                                o_error           => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'DELETE_SYS_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /**************************************************************************
    * Returns the list of event details for a given alert event
    *
    * @param   i_lang                     language
    * @param   i_prof                     id_do profissional, instituição e software
    * @param   i_id_sys_alert_event       ID do evento
    * @param   o_sys_alert_event_details  List of collected specimens
    * @param   o_error                    error message
    *
    *
    * @author  Paulo Almeida
    * @since   2008/08/08
    **************************************************************************/
    FUNCTION get_sys_alert_event_details
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_sys_alert_event      IN sys_alert_event_detail.id_sys_alert_event%TYPE,
        o_sys_alert_event_details OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_sys_alert_event_details FOR
            SELECT id_sys_alert_event,
                   id_sys_alert_event_detail,
                   pk_date_utils.date_char_tsz(i_lang,
                                               dt_sys_alert_event_detail_tstz,
                                               i_prof.institution,
                                               i_prof.software) dt_event,
                   id_professional,
                   prof_nick_name,
                   desc_detail,
                   id_detail_group,
                   desc_detail_group
              FROM sys_alert_event_detail
             WHERE id_sys_alert_event = i_id_sys_alert_event;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_SYS_ALERT_EVENT_DETAILS',
                                              o_error);
            pk_types.open_my_cursor(o_sys_alert_event_details);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_sys_alert_event_details;

    /**************************************************************************
    * Sets the correct professional for a determine alert
    *
    * @param   i_lang                     language
    * @param   i_prof                     id_do profissional, instituição e software
    * @param   i_id_sys_alert             ID do alert
    * @param   i_episode                  Id of episode
    * @param   i_professional             id of professional
    * @param   o_error                    error message
    *
    *
    * @author  Elisabete Bugalho
    * @since   16-04-2010
    **************************************************************************/
    FUNCTION set_alert_professional
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_professional IN professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'UPDATE alert';
    
        UPDATE sys_alert_event
           SET id_professional = i_professional
         WHERE id_sys_alert = i_id_sys_alert
           AND id_episode = i_episode
           AND id_professional IS NOT NULL;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_ALERT_PROFESSIONAL',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_alert_professional;

    /**
    * Gets alert configuration as type (t_tbl_alert_config)
    *
    * @param   i_lang language
    * @param   i_prof professional, institution and software ids
    * @param   i_id_sys_alert alert type id
    * @param   i_profile_template profile id
    *
    * @RETURN  t_tbl_alert_config
    * @author  João Sá
    * @version 1.0
    * @since   02-10-2013
    */
    FUNCTION get_config_as_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN t_tbl_alert_config IS
        l_sac_row sys_alert_config%ROWTYPE;
        l_tbl t_tbl_alert_config;
    BEGIN
        l_sac_row := get_config(i_lang, i_prof, i_id_sys_alert, i_profile_template);
    
        SELECT t_rec_alert_config(id_sys_alert_config  => l_sac_row.id_sys_alert_config,
                                  id_sys_alert         => l_sac_row.id_sys_alert,
                                  id_software          => l_sac_row.id_software,
                                  id_institution       => l_sac_row.id_institution,
                                  id_profile_template  => l_sac_row.id_profile_template,
                                  id_sys_shortcut      => l_sac_row.id_sys_shortcut,
                                  id_shortcut_pk       => l_sac_row.id_shortcut_pk,
                                  flg_read             => l_sac_row.flg_read,
                                  flg_duplicate        => l_sac_row.flg_duplicate,
                                  msg_dup_yes          => l_sac_row.msg_dup_yes,
                                  msg_dup_no           => l_sac_row.msg_dup_no,
                                  flg_sms              => l_sac_row.flg_sms,
                                  flg_email            => l_sac_row.flg_email,
                                  flg_im               => l_sac_row.flg_im,
                                  flg_notification_all => l_sac_row.flg_notification_all,
                                  flg_delete           => l_sac_row.flg_delete)
          BULK COLLECT
          INTO l_tbl
          FROM dual;
    
        RETURN l_tbl;
    
    END get_config_as_type;

    /*
    * Function used by the idp to create an user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id
    * @param o_error              Error message
    * @return                     true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013-10-29
    */
    FUNCTION insert_evt_user_blocked
    (
        i_lang            IN NUMBER,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row sys_alert_event%ROWTYPE := new_sys_alert_event();
        g_error           VARCHAR2(1000 CHAR);
        g_other_exception EXCEPTION;
    BEGIN
    
        -- Software and Institution 0, user is blocked for all softwares and institutions
        l_alert_event_row.id_sys_alert := g_alert_user_blocked;
        l_alert_event_row.id_record    := i_id_professional;
    
        g_error := 'INSERT INTO SYS_ALERT_EVENT';
    
        IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => profissional(0, 0, 0),
                                                i_sys_alert_event => l_alert_event_row,
                                                o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'insert_evt_user_blocked',
                                              o_error);
            RETURN FALSE;
    END insert_evt_user_blocked;

    /*
    * Function to delete user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id
    * @param o_error              Error message
    * @return                     true or false on success or error
    *
    * @author    Joao Sa
    * @version   2.6.3
    * @since     2013-10-29
    */
    FUNCTION delete_evt_user_blocked
    (
        i_lang            IN NUMBER,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row sys_alert_event% ROWTYPE := new_sys_alert_event();
        g_error           VARCHAR2(1000 CHAR);
        g_other_exception EXCEPTION;
    BEGIN
    
        -- Software and Institution 0, user is blocked for all softwares and institutions
        l_alert_event_row.id_sys_alert := pk_alerts.g_alert_user_blocked;
        l_alert_event_row.id_record    := i_id_professional;
    
        g_error := 'DELETE SYS_ALERT_EVENT';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => profissional(0, 0, 0),
                                                i_sys_alert_event => l_alert_event_row,
                                                o_error           => o_error)
        THEN
            g_error := o_error.err_desc;
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'delete_evt_user_blocked',
                                              o_error);
            RETURN FALSE;
    END delete_evt_user_blocked;
    /* set Generated Report alert */
    FUNCTION insert_evt_gen_report
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_cda_req IN cda_req.id_cda_req%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_alert_event_row sys_alert_event% ROWTYPE := new_sys_alert_event();
        l_exception EXCEPTION;
    BEGIN
    
        -- Software and Institution 0, user is blocked for all softwares and institutions
        l_alert_event_row.id_sys_alert    := 312;
        l_alert_event_row.id_record       := i_cda_req;
        l_alert_event_row.id_institution  := i_prof.institution;
        l_alert_event_row.id_professional := i_prof.id;
    
        g_error := 'INSERT INTO SYS_ALERT_EVENT';
        IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => i_prof,
                                                i_sys_alert_event => l_alert_event_row,
                                                o_error           => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INSERT_EVT_GEN_REPORT',
                                              o_error);
            RETURN FALSE;
    END insert_evt_gen_report;
    /*
    * Function to delete user blocked alert
    *
    * @param i_lang               Language id
    * @param i_id_professional    Blocked professional id
    * @param o_error              Error message
    * @return                     true or false on success or error
    *
    * @author    Rui Gomes
    * @version   2.6.34.0
    * @since     2014-05-08
    */
    FUNCTION delete_evt_gen_report
    (
        i_lang           IN NUMBER,
        i_id_cda_req     IN cda_req.id_cda_req%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_alert_event_row sys_alert_event% ROWTYPE := new_sys_alert_event();
        g_error           VARCHAR2(1000 CHAR);
        g_other_exception EXCEPTION;
    BEGIN
    
        -- Software and Institution 0, user is blocked for all softwares and institutions
        l_alert_event_row.id_sys_alert   := 312;
        l_alert_event_row.id_record      := i_id_cda_req;
        l_alert_event_row.id_institution := i_id_institution;
    
        g_error := 'DELETE SYS_ALERT_EVENT';
        IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                i_prof            => profissional(0, i_id_institution, 0),
                                                i_sys_alert_event => l_alert_event_row,
                                                o_error           => o_error)
        THEN
            g_error := o_error.err_desc;
            RAISE g_other_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'delete_evt_gen_report',
                                              o_error);
            RETURN FALSE;
    END delete_evt_gen_report;

    FUNCTION is_event_version(i_id_sys_alert IN sys_alert.id_sys_alert%TYPE) RETURN BOOLEAN IS
    BEGIN
        RETURN TRUE;
    END is_event_version;

    /*
    * Match sys_alert_events
    *
    * @param i_lang               Language id
    * @param i_prof               Professional
    * @param i_id_episode         Old episode identifier
    * @param i_id_episode_new     New episode identifier
    * @param i_id_sys_alert       Sys_alert identifier
    * @param o_error              Error message
    * @return                     true or false on success or error
    *
    * @author    Gisela Couto
    * @version   2.6.4
    * @since     2015-01-14
    */
    FUNCTION match_sys_alert_event
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_episode     IN sys_alert_event.id_episode%TYPE,
        i_id_episode_new IN sys_alert_event.id_episode%TYPE,
        i_id_sys_alert   IN sys_alert.id_sys_alert%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(100 CHAR) := 'MATCH_SYS_ALERT_EVENT';
    BEGIN
    
        g_error := 'UPDATE SYS_ALERT_EVENTS';
        UPDATE sys_alert_event sae
           SET sae.id_episode = i_id_episode_new
         WHERE sae.id_episode = i_id_episode
           AND sae.id_sys_alert = i_id_sys_alert;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error || '-' || SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END match_sys_alert_event;

    FUNCTION get_id_sys_alert
    (
        i_prof       IN profissional,
        i_id_profile IN profile_template.id_profile_template%TYPE
    ) RETURN table_number IS
        l_tbl table_number := table_number();
    BEGIN
    
        SELECT DISTINCT c.id_sys_alert
          BULK COLLECT
          INTO l_tbl
          FROM sys_alert_config c
         WHERE c.id_profile_template = i_id_profile
           AND c.id_software IN (i_prof.software, 0)
           AND c.id_institution IN (i_prof.institution, 0);
    
        RETURN l_tbl;
    
    END get_id_sys_alert;

    /**
    *  Set user alerts
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION set_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_service          IN department.id_department%TYPE DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_tbl      table_number := table_number();
        l_alerts   table_number := table_number();
        l_no_alert VARCHAR2(1 CHAR);
        num        PLS_INTEGER;
    
        -- IF Enabled, no alerts should be configured
        l_id_scfg        sys_config.id_sys_config%TYPE := 'NO_ALERTS_BY_DEFAULT';
        l_def_alerts_val sys_config.value%TYPE;
    
        FUNCTION check_privs_profs(i_alert IN NUMBER) RETURN NUMBER IS
            l_count NUMBER;
        BEGIN
        
            SELECT COUNT(*)
              INTO l_count
              FROM sys_alert_prof
             WHERE id_professional = i_id_prof.id
               AND id_institution = i_id_prof.institution
               AND id_software = i_id_prof.software
               AND id_sys_alert = i_alert;
        
            RETURN l_count;
        
        END check_privs_profs;
    
        --
        PROCEDURE insert_all_alerts IS
        BEGIN
        
            FORALL i IN 1 .. l_alerts.count
            --Dá permissões ao profissional aos alertas que ele ainda não tem
                INSERT INTO sys_alert_prof
                    (id_sys_alert_prof,
                     id_sys_alert,
                     id_profile_template,
                     id_institution,
                     id_professional,
                     id_software)
                VALUES
                    (seq_sys_alert_prof.nextval,
                     l_alerts(i),
                     i_id_profile_template,
                     i_id_prof.institution,
                     i_id_prof.id,
                     i_id_prof.software);
        END insert_all_alerts;
    
    BEGIN
    
        g_error          := 'GET ALERTS SYSTEM CONFIG PERMISSION';
        l_def_alerts_val := pk_sysconfig.get_config(l_id_scfg, i_id_prof.institution, i_id_prof.software);
    
        g_error          := 'GET ALERTS DEFAULT CONFIG PERMISSION BY PROFILE/ SERVICE';
        l_no_alert       := get_no_alert_validation(i_id_prof, i_id_profile_template, i_id_service);
    
        IF (l_no_alert != g_field_available OR l_def_alerts_val = g_field_available)
        THEN
            g_error := 'GET ALERTS DEFAULT CONFIG BY PROFILE/ SERVICE';
            l_tbl   := get_serv_sys_alert(i_id_prof, i_id_profile_template, i_id_service);
            IF l_tbl.count = 0
            THEN
                l_tbl   := get_id_sys_alert(i_id_prof, i_id_profile_template);
            END IF;
        
            <<loop_thru_alerts>>
            FOR i IN 1 .. l_tbl.count
            LOOP
                IF l_tbl(i) IS NOT NULL
                THEN
                    --verifica se o profissional já tem permissões para o perfil
                    num := check_privs_profs(l_tbl(i));
                
                    IF num = 0
                    THEN
                        l_alerts.extend;
                        l_alerts(l_alerts.count) := l_tbl(i);
                    END IF;
                
                END IF;
            END LOOP loop_thru_alerts;
        
            insert_all_alerts();
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'SET_PROF_ALERTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_prof_alerts;

    -- private
    PROCEDURE del_sys_alert_prof
    (
        i_prof_id     IN NUMBER,
        i_institution IN NUMBER,
        i_software    IN NUMBER
    ) IS
    BEGIN
        DELETE FROM sys_alert_prof
         WHERE id_professional = i_prof_id
           AND id_institution = i_institution
           AND id_software = i_software;
    END del_sys_alert_prof;

    /**
    *  Delete alerts from user accordingly to the profiles, software and institution been removed beeing removed.
    *
    * @param i_lang                Language
    * @param i_id_prof             Professional, institution, software ids.
    * @param i_id_profile_template Profile id for this user
    * @param o_error               Error message
    *
    * @return     boolean
    * @author     JS
    * @version    0.1
    * @since      2008/03/11
    */
    FUNCTION del_prof_alerts
    (
        i_lang                IN language.id_language%TYPE,
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        --se o template a retirar ao profissional não for indicado, elimina as permissões deste profissional a TODOS os alertas
        del_sys_alert_prof(i_prof_id     => i_id_prof.id,
                           i_institution => i_id_prof.institution,
                           i_software    => i_id_prof.software);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'DEL_PROF_ALERTS',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END del_prof_alerts;

    /**
    *  Changes alerts from user accordingly to the profiles, software and institution.
    *
    * @param i_lang                    Language
    * @param i_id_prof                 Professional, institution, software ids.
    * @param i_id_profile_template_old Old Profile id for this user
    * @param i_id_profile_template_new New Profile id for this user
    * @param o_error                   Error message
    *
    * @return     boolean
    * @author     Paulo Teixeira
    * @version    0.1
    * @since      2010-08-17
    */
    FUNCTION change_prof_alerts
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_prof                 IN profissional,
        i_id_profile_template_old IN profile_template.id_profile_template%TYPE,
        i_id_profile_template_new IN profile_template.id_profile_template%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_alert_prof IS
            SELECT sap.id_sys_alert, sap.id_sys_alert_prof
              FROM sys_alert_prof sap
             WHERE sap.id_professional = i_id_prof.id
               AND sap.id_institution = i_id_prof.institution
               AND sap.id_profile_template = i_id_profile_template_old;
    
        l_tbl_upd table_number := table_number();
        l_tbl_del table_number := table_number();
        num       PLS_INTEGER;
    
        FUNCTION check_cfg_alert(i_id_sys_alert IN NUMBER) RETURN NUMBER IS
            l_count NUMBER;
    BEGIN
    
            SELECT COUNT(1)
              INTO num
              FROM sys_alert_config sac
             WHERE sac.id_profile_template = i_id_profile_template_new
               AND sac.id_software IN (i_id_prof.software, 0)
               AND sac.id_institution IN (i_id_prof.institution, 0)
               AND sac.id_sys_alert = i_id_sys_alert;
        
            RETURN l_count;
        
        END check_cfg_alert;
    
    BEGIN
    
        FOR i IN c_alert_prof
        LOOP
        
            num := check_cfg_alert(i.id_sys_alert);
        
            IF num > 0
            THEN
                l_tbl_upd.extend;
                l_tbl_upd(l_tbl_upd.count) := i.id_sys_alert;
            ELSE
                l_tbl_del.extend;
                l_tbl_del(l_tbl_del.count) := i.id_sys_alert;
            END IF;
        
        END LOOP;
    
        FORALL i IN l_tbl_upd.first .. l_tbl_upd.last
            UPDATE sys_alert_prof sap
               SET sap.id_profile_template = i_id_profile_template_new
             WHERE sap.id_sys_alert_prof = l_tbl_upd(i);
    
        FORALL i IN l_tbl_del.first .. l_tbl_del.last
            DELETE FROM sys_alert_prof sap
             WHERE sap.id_sys_alert_prof = l_tbl_del(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHANGE_PROF_ALERTS',
                                              o_error);
            RETURN FALSE;
    END change_prof_alerts;

    /********************************************************************************************
    * Get all alert id by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_serv_sys_alert
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN table_number IS
        ret_tbl table_number := table_number();
    BEGIN
        g_error := 'GET ALL SERVICE ALERT CONFIGURATION';
        SELECT sa.id_sys_alert
          BULK COLLECT
          INTO ret_tbl
          FROM sys_alert sa
         WHERE EXISTS
         (SELECT 0
                  FROM sys_alert_department sad
                 WHERE sad.id_profile_template = i_id_profile_template
                   AND sad.id_institution = i_id_prof.institution
                   AND EXISTS
                 (SELECT 0
                          FROM prof_dep_clin_serv pdcs
                         INNER JOIN dep_clin_serv dcs
                            ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_field_available)
                         INNER JOIN department sv
                            ON (sv.id_department = dcs.id_department AND sv.flg_available = g_field_available)
                         INNER JOIN clinical_service cs
                            ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_field_available)
                         WHERE pdcs.id_professional = i_id_prof.id
                           AND dcs.id_department = sad.id_department)
                   AND sad.id_sys_alert = sa.id_sys_alert)
        UNION
        SELECT id_sys_alert
          FROM sys_alert_department sad
         WHERE sad.id_profile_template = i_id_profile_template
           AND sad.id_institution = i_id_prof.institution
           AND EXISTS
         (SELECT 0
                  FROM prof_dep_clin_serv pdcs
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_field_available)
                 INNER JOIN department sv
                    ON (sv.id_department = dcs.id_department AND sv.flg_available = g_field_available)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_field_available)
                 WHERE pdcs.id_professional = i_id_prof.id
                   AND dcs.id_department = sad.id_department);
    
        RETURN ret_tbl;
    
    END get_serv_sys_alert;

    /********************************************************************************************
    * Get all No alerts configuration flg by service config
    *
    * @param i_id_prof                professional identifier array
    * @param i_id_profile_template    Profile Template ID
    * @param i_service                Service ID
    *
    * @return                         table of alert ids
    *
    * @author                         RMGM
    * @version                        2.6.2
    * @since                          2012/11/06
    **********************************************************************************************/
    FUNCTION get_no_alert_validation
    (
        i_id_prof             IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_service             IN department.id_department%TYPE
    ) RETURN VARCHAR2 IS
        -- support vars
        l_no_alert        VARCHAR2(1);
        l_valid_prof_serv NUMBER := 0;
        l_count_templ_flg NUMBER := 0;
        -- support arrays
        l_prof_serv_list table_number := table_number();
    BEGIN
        g_error := 'GET ALL PROFESSIONAL ' || i_id_prof.id || ' SERVICE CONFIGURATION';
        SELECT d.id_department
          BULK COLLECT
          INTO l_prof_serv_list
          FROM department d
         WHERE d.id_institution = i_id_prof.institution
           AND d.flg_available = g_field_available
           AND EXISTS
         (SELECT 0
                  FROM prof_dep_clin_serv pdcs
                 INNER JOIN dep_clin_serv dcs
                    ON (dcs.id_dep_clin_serv = pdcs.id_dep_clin_serv AND dcs.flg_available = g_field_available)
                 INNER JOIN department sv
                    ON (sv.id_department = dcs.id_department AND sv.flg_available = g_field_available)
                 INNER JOIN clinical_service cs
                    ON (cs.id_clinical_service = dcs.id_clinical_service AND cs.flg_available = g_field_available)
                 WHERE pdcs.id_professional = i_id_prof.id
                   AND dcs.id_department = d.id_department
                   AND pdcs.id_institution = d.id_institution);
    
        g_error := 'CHECK IF PROF ' || i_id_prof.id || ' SERVICE IS THE REQUIRED TO CONFIG ' || i_service;
        SELECT COUNT(1)
          INTO l_valid_prof_serv
          FROM TABLE(CAST(l_prof_serv_list AS table_number)) serv_list
         WHERE serv_list.column_value = i_service;
    
        IF l_valid_prof_serv != 0
        THEN
        
            g_error := 'CHECK IF PROF ' || i_id_prof.id || ' SERVICE HAVE ALERTS OR NOT ' || i_service;
            SELECT nvl((SELECT sad.flg_no_alert
                         FROM sys_alert_department sad
                        WHERE sad.id_profile_template = i_id_profile_template
                          AND sad.id_department = i_service
                          AND sad.id_institution = i_id_prof.institution
                          AND sad.id_sys_alert IS NULL),
                       'N')
              INTO l_no_alert
              FROM dual;
        
            g_error := 'CHECK IF PROF ' || i_id_prof.id || ' SERVICES ' || i_service ||
                       'HAVE ALERTS OR NOT TO PROFILE CONFIG ' || i_id_profile_template;
            SELECT COUNT(1)
              INTO l_count_templ_flg
              FROM sys_alert_department sad
             WHERE sad.id_profile_template = i_id_profile_template
               AND sad.id_department IN (SELECT /*+ opt_estimate(TABLE p rows = 1) */
                                          column_value
                                           FROM TABLE(CAST(l_prof_serv_list AS table_number)) p)
               AND sad.id_institution = i_id_prof.institution
               AND sad.flg_no_alert = 'N';
        
            IF (l_no_alert = g_field_available AND l_count_templ_flg > 0)
            THEN
                l_no_alert := 'N';
            END IF;
        ELSE
            l_no_alert := 'N';
        END IF;
    
        RETURN l_no_alert;
    END get_no_alert_validation;

    PROCEDURE init_params_list
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
    
        l_hand_off_type sys_config.value%TYPE;
        --l_reason_grid   VARCHAR2(1);
        --l_category      category.id_category%TYPE;
        --l_type_opinion  opinion_type.id_opinion_type%TYPE;
        o_error         t_error_out;
        g_error         VARCHAR2(250);
    
        PROCEDURE set_context IS
            l_flg_profile   VARCHAR2(4000);
            l_hand_off_type VARCHAR2(4000);
            l_flg_process   VARCHAR2(4000);
        BEGIN
        
            l_flg_process := pk_sysconfig.get_config('PROCESS_GET_PROF_ALERTS', l_prof.institution, l_prof.software);
        
            IF nvl(l_flg_process, pk_alert_constant.g_no) = pk_alert_constant.g_yes
            THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                l_flg_profile := pk_hand_off_core.get_flg_profile(l_lang, l_prof, NULL);
            
                set_context_parameters(i_lang          => l_lang,
                                       i_prof          => l_prof,
                                       i_flg_profile   => l_flg_profile,
                                       i_hand_off_type => l_hand_off_type);
            END IF;
        
        END set_context;
    
    BEGIN
    
        set_context();
    
        CASE i_name
        
            WHEN 'i_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'i_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'i_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'i_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_msg_not_applicable' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => g_code_msg_not_applicable);
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_ALERTS',
                                              i_function => 'INIT_PARAMS_LIST',
                                              o_error    => o_error);
    END init_params_list;

    FUNCTION do_resp_icons
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        l_id_software NUMBER;
        l_id_episode  NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
    
        l_id_episode := i_num01(1);
    
        --l_id_software := get_epis_info_software(i_prof => i_prof, i_episode => l_id_episode);
    
        l_return := pk_utils.concat_table(i_tab => i_var01, i_delim => '|', i_start_off => NULL, i_length => NULL);
    
        RETURN l_return;
    
    END do_resp_icons;

    FUNCTION do_sys_shortcut
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        l_id_sys_shortcut NUMBER;
        l_id_episode      NUMBER;
        l_id_sys_alert    NUMBER;
        l_return          VARCHAR2(4000);
        l_flag            VARCHAR2(0010 CHAR);
        k_no              VARCHAR2(0001 CHAR) := 'N';
        --k_yes             VARCHAR2(0001 CHAR) := 'Y';
    
        FUNCTION set_order_shortcut(i_id_shortcut IN NUMBER) RETURN VARCHAR2 IS
            l_return VARCHAR2(0050 CHAR);
        BEGIN
        
            IF l_id_sys_shortcut = 11
            THEN
                l_return := pk_sign_off.g_so_ss_exam;
            END IF;
            IF l_id_sys_shortcut = 10
            THEN
                l_return := pk_sign_off.g_so_ss_imag;
            END IF;
        
            RETURN l_return;
        
        END set_order_shortcut;
    
    BEGIN
    
        l_id_episode      := i_num01(1);
        l_id_sys_shortcut := i_num01(2);
        l_id_sys_alert    := i_num01(3);
    
        l_flag := pk_sign_off.get_epis_sign_off_state(i_lang, i_prof, l_id_episode);
    
        IF l_flag = k_no
        THEN
            l_return := l_id_sys_shortcut;
        ELSE
        
            CASE l_id_sys_alert
                WHEN 15 THEN
                    l_return := pk_sign_off.g_so_ss_lab;
                WHEN 12 THEN
                    l_return := set_order_shortcut(i_id_shortcut => l_id_sys_shortcut);
                WHEN 3 THEN
                    l_return := set_order_shortcut(i_id_shortcut => l_id_sys_shortcut);
                WHEN 52 THEN
                    l_return := pk_sign_off.g_so_ss_pend_issues;
                ELSE
                    l_return := pk_sign_off.g_so_addendum;
            END CASE;
        
        END IF;
    
        RETURN l_return;
    
    END do_sys_shortcut;

    FUNCTION do_flg_ok
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        --l_id_sys_shortcut    NUMBER;
        l_id_software_origin NUMBER;
        l_id_episode         NUMBER;
        l_id_sys_alert       NUMBER;
        l_prof_cat           VARCHAR2(0010 CHAR);
        l_return             VARCHAR2(4000);
        tbl_hhc_alerts       table_number := table_number(332, 333, 325, 326, 327, 329);
        k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    BEGIN
    
        l_id_episode         := i_num01(1);
        l_id_sys_alert       := i_num01(2);
        l_id_software_origin := get_epis_info_software(i_prof => i_prof, i_episode => l_id_episode);
    
        l_return := k_no;
    
        IF l_id_sys_alert IN (pk_alert_constant.g_alert_hhc_team, pk_opinion.g_alert_end_followup)
        THEN
        
            IF i_prof.software = pk_alert_constant.g_soft_home_care
            THEN
                l_return := k_yes;
            END IF;
        
        ELSIF i_prof.software IN (l_id_software_origin,
                                  pk_alert_constant.g_soft_labtech,
                                  pk_alert_constant.g_soft_imgtech,
                                  pk_alert_constant.g_soft_extech,
                                  23,
                                  20,
                                  33,
                                  35,
                                  36,
                                  43,
                                  310,
                                  52)
        THEN
            IF l_id_episode = -1
            THEN
                IF l_id_sys_alert != 52
                THEN
                    l_return := k_yes;
                END IF;
            ELSE
                l_return := k_yes;
            END IF;
        
        ELSIF i_prof.software IN (1, 11, 12)
              AND l_id_software_origin = 36
              AND l_id_sys_alert IN (48, 49)
        THEN
            l_return := k_yes;
        
        ELSIF l_id_sys_alert IN (53,
                                 54,
                                 55,
                                 56,
                                 57,
                                 58,
                                 59,
                                 62,
                                 pk_opinion.g_alert_needs_approval,
                                 pk_opinion.g_alert_approval_reply,
                                 pk_opinion.g_alert_acceptance_reply,
                                 pk_epis_er_law_core.g_ges_sys_alert)
        THEN
            l_return := k_yes;
        
        ELSIF l_id_sys_alert = 63
              AND (l_id_episode = -1 OR l_id_episode IS NULL)
        THEN
            l_return := k_no;
        
        ELSIF i_prof.software = 1
              AND l_id_software_origin IN (43, 310, 8, 11)
              AND l_id_sys_alert = 18
        THEN
            --[OA - 2010/01/13]
            --Nutrition appointment - 43
            --Opinion request with origen in INPATIENT/EDIS episodes - 8 and 11
            l_return := k_yes;
        
        ELSIF l_id_sys_alert IN (5, 9, 13)
              AND l_id_software_origin = 11
              AND i_prof.software = 8
        THEN
        
            -- José Brito 25/09/2009 ALERT-45892  EDIS Ancillary profile: Activate OK button in the patient transport alert
            l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            IF l_prof_cat = 'O'
            THEN
                l_return := k_yes;
            END IF;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_social
              AND l_id_sys_alert IN (85, 89, 52)
        THEN
        
            -- Social worker profiles: OK must only be enabled for the 85 and 89 alert
            l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            IF l_id_sys_alert = 52
               AND l_prof_cat = pk_alert_constant.g_flg_profile_religious
            THEN
                l_return := k_no;
            ELSE
                l_return := k_yes;
            END IF;
            -- Activity Therapist profile: OK must only be enabled for the 95 alert
        ELSIF i_prof.software = pk_alert_constant.g_soft_act_therapist
              AND l_id_sys_alert IN (95)
        THEN
            l_return := k_yes;
        
        ELSIF i_prof.software = pk_alert_constant.g_soft_case_manager
              AND l_id_sys_alert = 52
        THEN
            -- Case manager profile: OK must only be enabled for the 52 alert
            l_return := k_yes;
        ELSIF l_id_sys_alert IN (102, 103)
        THEN
            -- scheduler 3 cancel and reschedule alerts
            l_return := k_yes;
        ELSIF i_prof.software = pk_alert_constant.g_soft_referral
        THEN
            -- Referral    alerts
            l_return := k_yes;
        ELSIF i_prof.software = 1
              AND l_id_software_origin IN (25, 15)
              AND l_id_sys_alert = 3
        THEN
            -- Imaging and Others Exams must only be enabled for the 3 alert
            l_return := k_yes;
        ELSIF i_prof.software = 39
        THEN
            l_return := k_yes;
        ELSIF (l_id_sys_alert MEMBER OF tbl_hhc_alerts)
        THEN
            l_return := k_yes;
        ELSE
            l_return := k_no;
        END IF;
    
        RETURN l_return;
    
    END do_flg_ok;

    FUNCTION do_url_ges_ext_app
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_patient   NUMBER;
        l_id_sys_alert NUMBER;
        l_return       VARCHAR2(4000);
    BEGIN
    
        l_id_patient   := i_num01(1);
        l_id_sys_alert := i_num01(2);
    
        IF l_id_sys_alert = pk_epis_er_law_core.g_ges_sys_alert
        THEN
            l_return := pk_epis_er_law_api.get_ges_url(i_lang => i_lang, i_prof => i_prof, i_patient => l_id_patient);
        END IF;
    
        RETURN l_return;
    
    END do_url_ges_ext_app;

    FUNCTION transform
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        -- case_01
        CASE upper(i_code)
            WHEN 'RESP_ICONS' THEN
                l_return := do_resp_icons(i_lang => i_lang, i_prof => i_prof, i_num01 => i_num01, i_var01 => i_var01);
            WHEN 'SYS_SHORTCUT' THEN
                l_return := do_sys_shortcut(i_lang => i_lang, i_prof => i_prof, i_num01 => i_num01, i_var01 => i_var01);
            WHEN 'FLG_OK' THEN
                l_return := do_sys_shortcut(i_lang => i_lang, i_prof => i_prof, i_num01 => i_num01, i_var01 => i_var01);
            WHEN 'URL_GES_EXT_APP' THEN
                l_return := do_url_ges_ext_app(i_lang  => i_lang,
                                               i_prof  => i_prof,
                                               i_num01 => i_num01,
                                               i_var01 => i_var01);
            ELSE
                l_return := NULL;
        END CASE; -- end case_01
    
        RETURN l_return;
    
    END transform;

    FUNCTION get_patient_alerts_count
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_sys_alert IN sys_alert.id_sys_alert%TYPE,
        i_id_patient   IN patient.id_patient%TYPE
    ) RETURN NUMBER IS
        l_error t_error_out;
        l_count NUMBER := 0;
    
    BEGIN
        SELECT COUNT(1)
          INTO l_count
          FROM sys_alert_event sae
         WHERE sae.id_sys_alert = i_id_sys_alert
           AND sae.id_patient = i_id_patient
           AND NOT EXISTS (SELECT 1
                  FROM sys_alert_read sar
                 WHERE sae.id_sys_alert_event = sar.id_sys_alert_event);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PATIENT_ALERTS_COUNT',
                                              l_error);
    END get_patient_alerts_count;

    /********************************************************************************************
    * Inserts on record into the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/

    FUNCTION get_count_alert_duplicates
    (
        i_id_sys_alert IN NUMBER,
        i_id_episode   IN NUMBER,
        i_id_prof      IN NUMBER
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM sys_alert_event e
         WHERE e.id_sys_alert = i_id_sys_alert
           AND e.id_episode = i_id_episode
           AND e.flg_visible = g_yes
           AND ((e.id_professional = i_id_prof AND i_id_prof IS NOT NULL AND e.id_professional IS NOT NULL) OR
               (i_id_prof IS NULL));
    
        RETURN l_count;
    
    END get_count_alert_duplicates;

    FUNCTION get_count_record_visible
    (
        i_alert        IN NUMBER,
        i_epis         IN NUMBER,
        i_professional IN NUMBER,
        i_id_record    IN NUMBER
    ) RETURN NUMBER IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM sys_alert_event e
         WHERE e.id_sys_alert = i_alert
           AND e.id_episode = i_epis
           AND e.flg_visible = g_yes
           AND ((e.id_professional = i_professional AND i_professional IS NOT NULL AND e.id_professional IS NOT NULL) OR
               (i_professional IS NULL))
           AND id_record = i_id_record;
    
        RETURN l_count;
    
    END get_count_record_visible;

    FUNCTION insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sys_alert_event sys_alert_event.id_sys_alert_event%TYPE;
    BEGIN
    
        RETURN insert_sys_alert_event(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_sys_alert_event    => i_sys_alert_event,
                                      o_id_sys_alert_event => l_id_sys_alert_event,
                                      o_error              => o_error);
    
    END insert_sys_alert_event;

    FUNCTION insert_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_sys_alert_event    IN sys_alert_event%ROWTYPE,
        o_id_sys_alert_event OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_config_row sys_alert_config%ROWTYPE;
        l_count_duplicate  NUMBER DEFAULT 0;
        l_flg_visible      sys_alert_event.flg_visible%TYPE DEFAULT g_yes;
    
        --l_crm_alerts sys_config.value%TYPE := pk_sysconfig.get_config('CRM_ALERTS', i_prof);
    
        -- sms local variables
        l_sms_message       VARCHAR2(4000);
        l_dest_num_sms      sys_config.value%TYPE;
        --l_error_code        VARCHAR2(4000);
        --l_error_description VARCHAR2(4000);
        --l_used_total        NUMBER;
        --l_used_accumulated  NUMBER;
        --l_used_periodic     NUMBER;
        --l_batch_id          NUMBER;
        --l_sms_id            table_number;
        --l_original_position table_number;
        --l_credits_used      table_number;
        --l_destination       table_varchar;
        --l_date_routed       table_varchar;
        --l_bad_destination   table_varchar;
        l_record_count      NUMBER;
    
        l_id_sys_alert_event sys_alert_event.id_sys_alert_event%TYPE;
    
        err_sending_sms EXCEPTION;
    
    BEGIN
    
        g_error            := 'GET ALERT CONFIG';
        l_alert_config_row := get_config(i_lang, i_prof, i_sys_alert_event.id_sys_alert, NULL);
    
        -- If alert can't be duplicated (by episode)...
        IF nvl(l_alert_config_row.flg_duplicate, g_yes) = g_no
        THEN
        
            l_count_duplicate := get_count_alert_duplicates(i_sys_alert_event.id_sys_alert,
                                                            i_sys_alert_event.id_episode,
                                                            i_sys_alert_event.id_professional);
        
            -- Found visible records
            IF l_count_duplicate > 0
            THEN
            
                l_record_count := get_count_record_visible(i_sys_alert_event.id_sys_alert,
                                                           i_sys_alert_event.id_episode,
                                                           i_sys_alert_event.id_professional,
                                                           i_sys_alert_event.id_record);
            
                IF l_record_count = 0
                THEN
                    l_flg_visible := g_no;
                END IF;
            END IF;
        END IF;
    
        IF i_sys_alert_event.id_sys_alert_event IS NULL
        THEN
            l_id_sys_alert_event := seq_sys_alert_event.nextval;
        END IF;
    
        g_error := 'MERGE SYS_ALERT_EVENT';
        MERGE INTO sys_alert_event d
        USING (SELECT i_sys_alert_event.id_sys_alert id_sys_alert,
                      i_sys_alert_event.id_software id_software,
                      i_sys_alert_event.id_institution id_institution,
                      i_sys_alert_event.id_patient id_patient,
                      i_sys_alert_event.id_visit id_visit,
                      i_sys_alert_event.id_episode id_episode,
                      i_sys_alert_event.id_record id_record,
                      nvl(i_sys_alert_event.dt_record, SYSDATE) dt_record,
                      i_sys_alert_event.id_professional id_professional,
                      i_sys_alert_event.id_room id_room,
                      i_sys_alert_event.id_clinical_service id_clinical_service,
                      l_flg_visible flg_visible,
                      i_sys_alert_event.replace1 replace1,
                      i_sys_alert_event.replace2 replace2,
                      i_sys_alert_event.id_dep_clin_serv id_dep_clin_serv,
                      i_sys_alert_event.id_intf_type id_intf_type,
                      i_sys_alert_event.id_prof_order id_prof_order,
                      current_timestamp dt_creation
                 FROM sys_alert
                WHERE id_sys_alert = i_sys_alert_event.id_sys_alert) m
        ON (d.id_sys_alert = m.id_sys_alert AND d.id_episode = m.id_episode AND d.id_record = m.id_record AND ((d.id_professional IS NULL AND m.id_professional IS NULL) OR d.id_professional = m.id_professional))
        WHEN MATCHED THEN
            UPDATE
               SET d.dt_record           = nvl(m.dt_record, SYSDATE),
                   d.id_room             = m.id_room,
                   d.id_clinical_service = m.id_clinical_service,
                   d.replace1            = m.replace1,
                   d.replace2            = m.replace2,
                   d.id_dep_clin_serv    = m.id_dep_clin_serv,
                   d.flg_visible         = m.flg_visible,
                   d.id_intf_type        = m.id_intf_type,
                   d.id_prof_order       = m.id_prof_order
        WHEN NOT MATCHED THEN
            INSERT
                (id_sys_alert_event,
                 id_sys_alert,
                 id_software,
                 id_institution,
                 id_patient,
                 id_visit,
                 id_episode,
                 id_record,
                 dt_record,
                 id_professional,
                 id_room,
                 id_clinical_service,
                 flg_visible,
                 replace1,
                 replace2,
                 id_dep_clin_serv,
                 id_intf_type,
                 id_prof_order,
                 dt_creation)
            VALUES
                (l_id_sys_alert_event,
                 m.id_sys_alert,
                 m.id_software,
                 m.id_institution,
                 m.id_patient,
                 m.id_visit,
                 m.id_episode,
                 m.id_record,
                 m.dt_record,
                 m.id_professional,
                 m.id_room,
                 m.id_clinical_service,
                 m.flg_visible,
                 m.replace1,
                 m.replace2,
                 m.id_dep_clin_serv,
                 m.id_intf_type,
                 m.id_prof_order,
                 m.dt_creation);
    
        g_error := 'GET SYS_ALERT_EVENT ID';
        SELECT sae.id_sys_alert_event
          INTO l_id_sys_alert_event
          FROM sys_alert_event sae
         WHERE sae.id_sys_alert = i_sys_alert_event.id_sys_alert
           AND sae.id_episode = i_sys_alert_event.id_episode
           AND sae.id_record = i_sys_alert_event.id_record
           AND nvl(sae.id_professional, -999) = nvl(i_sys_alert_event.id_professional, -999);
    
        IF i_sys_alert_event.id_sys_alert_event IS NULL
        THEN
            o_id_sys_alert_event := l_id_sys_alert_event;
        ELSE
            o_id_sys_alert_event := i_sys_alert_event.id_sys_alert_event;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_sending_sms THEN
            pk_alertlog.log_error('An error occurs when trying to send alert SMS to the destination number ' ||
                                  l_dest_num_sms || ' (alert id: ' || i_sys_alert_event.id_sys_alert ||
                                  ', software id: ' || i_prof.software || ', institution id: ' || i_prof.institution ||
                                  ', id_sys_alert_event: ' || l_id_sys_alert_event || '): ' || l_sms_message);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INSERT_SYS_ALERT_EVENT',
                                              o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
    END insert_sys_alert_event;

    /********************************************************************************************
    * Inserts on record into the event table.
    * In this case the visit id and the patient id are obtained from the episode.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional, institution, software
    * @param i_sys_alert           Record to insert
    * @param i_id_episode          Episode ID
    * @param i_id_record           Detail ID (eg. id_analysis_req_det for harvest alerts)
    * @param i_dt_record           Record date (eg. analysis_req_det.dt_begin for harvest alerts)
    * @param i_id_professional     Professional ID (if the alert has a well defined target, null otherwise)
    * @param i_id_room             Room ID (id the alert is to be shown to every professional of a room, null otherwise)
    * @param i_id_clinical_service Clinical Service ID (id the alert is to be shown to every professional of a clinical service, null otherwise)
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
    *                               C- Clinical Service, R- room
    * @param i_replace1            Replace value for alert message
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_sys_alert           IN sys_alert.id_sys_alert%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_record           IN sys_alert_event.id_record%TYPE,
        i_dt_record           IN sys_alert_event.dt_record%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_room             IN room.id_room%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_type_dest       IN VARCHAR2,
        i_replace1            IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'CALL insert_sys_alert_event';
        RETURN insert_sys_alert_event(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_sys_alert           => i_sys_alert,
                                      i_id_episode          => i_id_episode,
                                      i_id_record           => i_id_record,
                                      i_dt_record           => i_dt_record,
                                      i_id_professional     => i_id_professional,
                                      i_id_room             => i_id_room,
                                      i_id_clinical_service => i_id_clinical_service,
                                      i_flg_type_dest       => i_flg_type_dest,
                                      i_replace1            => i_replace1,
                                      i_replace2            => NULL,
                                      i_prof_order          => NULL,
                                      o_error               => o_error);
    
    END insert_sys_alert_event;

    /********************************************************************************************
    * Inserts on record into the event table.
    *
    * @param i_lang                Language Id
    * @param i_sys_alert_event     Record to insert
    * @param i_flg_type_dest       Target of the alert, when IDs are not available. Accepted values:
    *                               C- Clinical Service, R- room
    * @param o_error               Error message
    *
    * @return                      TRUE if sucess, FALSE otherwise
    *
    * @author                      Joao Sa
    * @version                     1.0
    * @since                       2008/03/12
    ********************************************************************************************/
    FUNCTION insert_sys_alert_event
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_sys_alert_event IN sys_alert_event%ROWTYPE,
        i_flg_type_dest   IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sys_alert_event sys_alert_event.id_sys_alert_event%TYPE;
    BEGIN
    
        g_error := 'CALL insert_sys_alert_event';
        RETURN insert_sys_alert_event(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_sys_alert_event    => i_sys_alert_event,
                                      i_flg_type_dest      => i_flg_type_dest,
                                      o_id_sys_alert_event => l_id_sys_alert_event,
                                      o_error              => o_error);
    
    END insert_sys_alert_event;

    FUNCTION insert_sys_alert_event
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_sys_alert           IN sys_alert.id_sys_alert%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_record           IN sys_alert_event.id_record%TYPE,
        i_dt_record           IN sys_alert_event.dt_record%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_id_room             IN room.id_room%TYPE,
        i_id_clinical_service IN clinical_service.id_clinical_service%TYPE,
        i_flg_type_dest       IN VARCHAR2,
        i_replace1            IN VARCHAR2,
        i_replace2            IN VARCHAR2,
        i_prof_order          IN NUMBER DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row    sys_alert_event%ROWTYPE;
        l_id_sys_alert_event NUMBER;
    
    BEGIN
    
        l_alert_event_row.id_sys_alert        := i_sys_alert;
        l_alert_event_row.id_software         := i_prof.software;
        l_alert_event_row.id_institution      := i_prof.institution;
        l_alert_event_row.id_episode          := i_id_episode;
        l_alert_event_row.id_record           := i_id_record;
        l_alert_event_row.dt_record           := i_dt_record;
        l_alert_event_row.id_professional     := i_id_professional;
        l_alert_event_row.id_room             := i_id_room;
        l_alert_event_row.id_clinical_service := i_id_clinical_service;
        l_alert_event_row.replace1            := i_replace1;
        l_alert_event_row.replace2            := i_replace2;
        l_alert_event_row.id_prof_order       := i_prof_order;
    
        RETURN insert_sys_alert_event(i_lang               => i_lang,
                                      i_prof               => i_prof,
                                      i_sys_alert_event    => l_alert_event_row,
                                      i_flg_type_dest      => i_flg_type_dest,
                                      o_id_sys_alert_event => l_id_sys_alert_event,
                                      o_error              => o_error);
    
    END insert_sys_alert_event;

    FUNCTION insert_sys_alert_event
    (
        i_lang               IN NUMBER,
        i_prof               IN profissional,
        i_sys_alert_event    IN sys_alert_event%ROWTYPE,
        i_flg_type_dest      IN VARCHAR2,
        o_id_sys_alert_event OUT sys_alert_event.id_sys_alert_event%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_alert_event_row     sys_alert_event%ROWTYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_clinical_service clinical_service.id_clinical_service%TYPE;
        l_id_room             room.id_room%TYPE;
    
        --****************************************
        PROCEDURE get_info_episode(i_episode IN NUMBER) IS
            tbl_visit   table_number;
            tbl_patient table_number;
        BEGIN
        
            SELECT id_visit, id_patient
              BULK COLLECT
              INTO tbl_visit, tbl_patient
              FROM episode
             WHERE id_episode = i_episode;
        
            IF tbl_visit.count > 0
            THEN
                l_alert_event_row.id_visit   := tbl_visit(1);
                l_alert_event_row.id_patient := tbl_patient(1);
            END IF;
        
        END get_info_episode;
    
        --**********************************
        PROCEDURE assign_basic_values IS
        BEGIN
        
            l_id_clinical_service := i_sys_alert_event.id_clinical_service;
            l_id_room             := i_sys_alert_event.id_room;
            l_id_dep_clin_serv    := i_sys_alert_event.id_dep_clin_serv;
        
        END assign_basic_values;
    
        --*********************************
        PROCEDURE reset_basic_values IS
        BEGIN
        
            l_id_clinical_service := NULL;
            l_id_room             := NULL;
            l_id_dep_clin_serv    := NULL;
        
        END reset_basic_values;
    
    BEGIN
        --Get target values when not available
    
        reset_basic_values();
        assign_basic_values();
        CASE i_flg_type_dest
            WHEN 'R' THEN
            
                IF i_sys_alert_event.id_room IS NULL
                THEN
                    l_id_room := get_room_by_episode(i_episode => i_sys_alert_event.id_episode);
                END IF;
            WHEN 'C' THEN
            
                IF i_sys_alert_event.id_clinical_service IS NULL
                THEN
                    l_id_clinical_service := get_clin_serv_by_episode(i_episode => i_sys_alert_event.id_episode);
                END IF;
            
            WHEN 'D' THEN
                IF i_sys_alert_event.id_dep_clin_serv IS NULL
                THEN
                    l_id_dep_clin_serv := get_dcs_by_episode(i_episode => i_sys_alert_event.id_episode);
                END IF;
            ELSE
                NULL;
        END CASE;
    
        l_alert_event_row.id_sys_alert        := i_sys_alert_event.id_sys_alert;
        l_alert_event_row.id_software         := i_prof.software;
        l_alert_event_row.id_institution      := i_prof.institution;
        l_alert_event_row.id_episode          := i_sys_alert_event.id_episode;
        l_alert_event_row.id_patient          := i_sys_alert_event.id_patient;
        l_alert_event_row.id_visit            := i_sys_alert_event.id_visit;
        l_alert_event_row.id_record           := i_sys_alert_event.id_record;
        l_alert_event_row.dt_record           := i_sys_alert_event.dt_record;
        l_alert_event_row.id_professional     := i_sys_alert_event.id_professional;
        l_alert_event_row.id_room             := l_id_room;
        l_alert_event_row.id_clinical_service := l_id_clinical_service;
        l_alert_event_row.replace1            := i_sys_alert_event.replace1;
        l_alert_event_row.replace2            := i_sys_alert_event.replace2;
        l_alert_event_row.id_dep_clin_serv    := l_id_dep_clin_serv;
        l_alert_event_row.id_intf_type        := i_sys_alert_event.id_intf_type;
        l_alert_event_row.id_prof_order       := i_sys_alert_event.id_prof_order;
    
        IF i_sys_alert_event.id_visit IS NULL
           OR i_sys_alert_event.id_patient IS NULL
        THEN
        
            get_info_episode(i_episode => i_sys_alert_event.id_episode);
        
        END IF;
    
        RETURN insert_sys_alert_event(i_lang, i_prof, l_alert_event_row, o_id_sys_alert_event, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'INSERT_SYS_ALERT_EVENT',
                                              o_error);
            RETURN FALSE;
    END insert_sys_alert_event;

    FUNCTION check_if_alert_expired
    (
        i_prof         IN profissional,
        i_dt_creation  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_sys_alert IN NUMBER
    ) RETURN NUMBER IS
        tbl_days table_number;
        l_date   TIMESTAMP WITH LOCAL TIME ZONE;
        l_days   NUMBER;
        l_return NUMBER := 1;
        k_nvl_value CONSTANT NUMBER := 100;
    BEGIN
    
        SELECT coalesce(b.days_for_expiration, sa.days_for_expiration)
          BULK COLLECT
          INTO tbl_days
          FROM sys_alert_prof b
          JOIN sys_alert sa
            ON sa.id_sys_alert = b.id_sys_alert
         WHERE b.id_professional = i_prof.id
           AND b.id_institution = i_prof.institution
           AND b.id_software = i_prof.software
           AND b.id_sys_alert = i_id_sys_alert;
    
        IF tbl_days.count > 0
        THEN
            l_days := coalesce(tbl_days(1), k_nvl_value);
        ELSE
            l_days := k_nvl_value;
        END IF;
    
        l_date := i_dt_creation + numtodsinterval(l_days, 'DAY');
    
        IF l_date < current_timestamp
        THEN
            l_return := -1;
        END IF;
    
        RETURN l_return;
    
    END check_if_alert_expired;

    --*****************************************************
    FUNCTION get_flg_ok_enabled
    (
        i_prof               IN profissional,
        i_id_episode         IN NUMBER,
        i_sys_alert          IN NUMBER,
        i_id_software_origin IN NUMBER
    ) RETURN VARCHAR2 IS
        k_yes                CONSTANT VARCHAR2(0010 CHAR) := 'Y';
        k_no                 CONSTANT VARCHAR2(0010 CHAR) := 'N';
        k_alert_hhc_team     CONSTANT NUMBER := pk_alert_constant.g_alert_hhc_team;
        k_alert_end_followup CONSTANT NUMBER := pk_opinion.g_alert_end_followup;
        k_soft_home_care     CONSTANT NUMBER := pk_alert_constant.g_soft_home_care;
    
        k_soft_labtech           CONSTANT NUMBER := pk_alert_constant.g_soft_labtech;
        k_soft_imgtech           CONSTANT NUMBER := pk_alert_constant.g_soft_imgtech;
        k_soft_extech            CONSTANT NUMBER := pk_alert_constant.g_soft_extech;
        k_alert_needs_approval   CONSTANT NUMBER := pk_opinion.g_alert_needs_approval;
        k_alert_approval_reply   CONSTANT NUMBER := pk_opinion.g_alert_approval_reply;
        k_alert_acceptance_reply CONSTANT NUMBER := pk_opinion.g_alert_acceptance_reply;
        k_ges_sys_alert          CONSTANT NUMBER := pk_epis_er_law_core.g_ges_sys_alert;
        k_soft_social            CONSTANT NUMBER := pk_alert_constant.g_soft_social;
        k_flg_profile_religious  CONSTANT VARCHAR2(0010 CHAR) := pk_alert_constant.g_flg_profile_religious;
        k_soft_act_therapist     CONSTANT NUMBER := pk_alert_constant.g_soft_act_therapist;
        k_soft_case_manager      CONSTANT NUMBER := pk_alert_constant.g_soft_case_manager;
        k_soft_referral          CONSTANT NUMBER := pk_alert_constant.g_soft_referral;
    
        l_prof_cat     VARCHAR2(0010 CHAR);
        l_return       VARCHAR2(4000);
        tbl_grp01      table_number := table_number(k_alert_hhc_team, k_alert_end_followup);
        tbl_grp02      table_number := table_number(k_soft_labtech,
                                                    k_soft_imgtech,
                                                    k_soft_extech,
                                                    23,
                                                    20,
                                                    33,
                                                    35,
                                                    36,
                                                    43,
                                                    310,
                                                    52);
        tbl_grp03      table_number := table_number(53,
                                                    54,
                                                    55,
                                                    56,
                                                    57,
                                                    58,
                                                    59,
                                                    62,
                                                    k_alert_needs_approval,
                                                    k_alert_approval_reply,
                                                    k_alert_acceptance_reply,
                                                    k_ges_sys_alert);
        tbl_hhc_alerts table_number := table_number(332, 333, 325, 326, 327, 329);
    
    BEGIN
    
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        CASE
            WHEN (i_sys_alert MEMBER OF tbl_grp01) THEN
            
                l_return := k_no;
                IF i_prof.software = k_soft_home_care
                THEN
                    l_return := k_yes;
                END IF;
            
            WHEN (i_prof.software MEMBER OF tbl_grp02)
                 OR (i_prof.software = i_id_software_origin) THEN
            
                l_return := k_yes;
                IF i_id_episode = -1
                THEN
                
                    l_return := k_yes;
                    IF i_sys_alert = 52
                    THEN
                        l_return := k_no;
                    END IF;
                END IF;
            WHEN i_prof.software IN (1, 11, 12)
                 AND i_id_software_origin = 36
                 AND i_sys_alert IN (48, 49) THEN
                l_return := k_yes;
            
            WHEN i_sys_alert MEMBER OF tbl_grp03 THEN
                l_return := k_yes;
            
            WHEN i_sys_alert = 63
                 AND (i_id_episode = -1 OR i_id_episode IS NULL) THEN
                l_return := k_no;
            
            WHEN i_prof.software = 1
                 AND i_id_software_origin IN (43, 310, 8, 11)
                 AND i_sys_alert = 18 THEN
                l_return := k_yes;
            
            WHEN i_sys_alert IN (5, 9, 13)
                 AND i_id_software_origin = 11
                 AND i_prof.software = 8
                 AND l_prof_cat = 'O' THEN
                l_return := k_yes;
            
            WHEN (i_prof.software = k_soft_social)
                 AND i_sys_alert IN (85, 89, 52) THEN
            
                l_return := k_yes;
                IF i_sys_alert = 52
                   AND l_prof_cat = k_flg_profile_religious
                THEN
                    l_return := k_no;
                END IF;
            
            WHEN i_prof.software = k_soft_act_therapist
                 AND i_sys_alert IN (95) THEN
                l_return := k_yes;
            
            WHEN i_prof.software = k_soft_case_manager
                 AND i_sys_alert = 52 THEN
                l_return := k_yes;
            
            WHEN i_sys_alert IN (102, 103) THEN
                l_return := k_yes;
            
            WHEN i_prof.software = k_soft_referral THEN
                l_return := k_yes;
            
            WHEN i_prof.software = 1
                 AND i_id_software_origin IN (25, 15)
                 AND i_sys_alert = 3 THEN
                l_return := k_yes;
            
            WHEN i_prof.software = 39 THEN
                l_return := k_yes;
            WHEN (i_sys_alert MEMBER OF tbl_hhc_alerts) THEN
                l_return := k_yes;
            ELSE
                l_return := k_no;
        END CASE;
    
        RETURN l_return;
    
    END get_flg_ok_enabled;

    PROCEDURE init_par_alerts
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
        --k_pos_episode      CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        --l_msg               VARCHAR2(4000);
        --l_id_episode        NUMBER := -9999999;
        tf_alerts    t_tbl_alert := t_tbl_alert();
        l_time       VARCHAR2(1000 CHAR);
        --l_id_sys_alert_type NUMBER;
    
        --*******************************************
        FUNCTION get_alert_type RETURN VARCHAR2 IS
            l_return VARCHAR2(0200 CHAR);
        BEGIN
        
            <<lup_thru_keys>>
            FOR i IN 1 .. i_context_keys.count
            LOOP
            
                IF i_context_keys(i) = 'ALERTS_GROUP'
                THEN
                    l_return := i_context_vals(i);
                    EXIT lup_thru_keys;
                END IF;
            
            END LOOP lup_thru_keys;
        
            RETURN l_return;
        
        END get_alert_type;
    
    BEGIN
    
        tf_alerts := pk_alerts.tf_get_prof_alerts(i_lang => l_lang, i_prof => l_prof);
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'msg_not_applicable' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'N/A');
            WHEN 'l_id_sys_alert_type' THEN
                o_vc2 := get_alert_type();
            WHEN 'l_today' THEN
                l_time := to_char(current_timestamp, 'YYYYMMDD') || '000000';
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => l_time,
                                                        i_timezone  => NULL);
            ELSE
                NULL;
        END CASE;
    
    END init_par_alerts;

    --*******************
    FUNCTION tf_get_prof_alerts
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
        --o_alert OUT pk_types.cursor_type,
    ) RETURN t_tbl_alert IS
    
        --g_code_msg_not_applicable CONSTANT VARCHAR2(0010 CHAR) := 'N/A';
    
        tbl_return t_tbl_alert := t_tbl_alert();
        --l_error    VARCHAR2(4000);
        aux_sql pk_types.cursor_type;
    
        CURSOR c_prof_views IS
            SELECT a.id_sys_alert, a.sql_alert alert_sql, a.flg_detail
              FROM sys_alert a
              JOIN sys_alert_prof b
                ON b.id_sys_alert = a.id_sys_alert
             WHERE b.id_institution = i_prof.institution
               AND b.id_software = i_prof.software
               AND b.id_professional = i_prof.id
             ORDER BY a.id_sys_alert;
    
        l_aux          sys_alert_temp%ROWTYPE;
        l_id_sys_alert sys_alert.id_sys_alert%TYPE;
        l_id_software  software.id_software%TYPE;
        --l_prof_cat           category.flg_type%TYPE;
        l_flg_profile      profile_template.flg_profile%TYPE;
        l_hand_off_type    sys_config.value%TYPE;
        l_resp_icons_table table_varchar;
        l_resp_icons_str   VARCHAR2(300);
        --l_msg_not_applicable sys_message.desc_message%TYPE;
        l_flg_process VARCHAR2(0010 CHAR);
    
        --tbl_hhc_alerts table_number := table_number(332, 333, 325, 326, 327, 329);
    
        --l_start     PLS_INTEGER;
        l_err_alert VARCHAR2(1000 CHAR);
    
        --***************************************
        FUNCTION get_epis_info_software
        (
            i_prof    IN profissional,
            i_episode IN NUMBER
        ) RETURN NUMBER IS
            tbl_software table_number;
            l_return     NUMBER;
        BEGIN
        
            SELECT ei.id_software
              BULK COLLECT
              INTO tbl_software
              FROM epis_info ei
             WHERE ei.id_episode = i_episode;
        
            CASE
                WHEN tbl_software.count = 1 THEN
                    l_return := tbl_software(1);
                WHEN tbl_software.count > 1 THEN
                    l_return := i_prof.software;
                ELSE
                    l_return := NULL;
            END CASE;
        
            RETURN l_return;
        
        END get_epis_info_software;
    
        --************************
        FUNCTION clob2varchar(i_str_clob CLOB) RETURN VARCHAR2 IS
            l_str_varchar VARCHAR2(32767);
            l_amount      PLS_INTEGER := 32767;
        
            e_clob2varchar EXCEPTION;
            PRAGMA EXCEPTION_INIT(e_clob2varchar, -06502);
        BEGIN
            -- copy characters of the buffer
            l_str_varchar := to_char(i_str_clob);
            RETURN l_str_varchar;
        
        EXCEPTION
            WHEN e_clob2varchar THEN
                -- copy bytes of the buffer
                dbms_lob.read(i_str_clob, l_amount, 1, l_str_varchar);
                RETURN l_str_varchar;
        END clob2varchar;
    BEGIN
    
        l_flg_process := pk_sysconfig.get_config('PROCESS_GET_PROF_ALERTS', i_prof.institution, i_prof.software);
    
        IF nvl(l_flg_process, k_no) != k_yes
        THEN
            RETURN t_tbl_alert();
        END IF;
    
        -- Apaga todos os registos da tabela temporária
        DELETE sys_alert_temp;
    
        -- José Brito 27/10/2009 ALERT-39320  Support for multiple hand-off mechanism
        --l_error := 'GET CONFIGURATIONS';
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
        l_flg_profile := pk_hand_off_core.get_flg_profile(i_lang, i_prof, NULL);
    
        set_context_parameters(i_lang          => i_lang,
                               i_prof          => i_prof,
                               i_flg_profile   => l_flg_profile,
                               i_hand_off_type => l_hand_off_type);
    
        --DETERMINA ALERTAS DO PROFISSIONAL/APLICAÇÃO/INSTITUIÇÃO
        FOR i IN c_prof_views
        LOOP
            --l_error        := '';
            l_id_sys_alert := i.id_sys_alert;
            l_err_alert    := 'ALERT #' || i.id_sys_alert || '-->';
            --l_error        := 'FETCH ALERT ' || l_id_sys_alert;
            OPEN aux_sql FOR clob2varchar(i.alert_sql);
        
            --l_error := 'Start LOOP';
            LOOP
            
                FETCH aux_sql
                    INTO l_aux.id_sys_alert_det,
                         l_aux.id_reg,
                         l_aux.id_episode,
                         l_aux.id_institution,
                         l_aux.id_prof, --
                         l_aux.dt_req,
                         l_aux.time,
                         l_aux.message,
                         l_aux.id_room,
                         l_aux.id_patient,
                         l_aux.name_pat,
                         l_aux.pat_ndo,
                         l_aux.pat_nd_icon,
                         l_aux.photo, --
                         l_aux.gender,
                         l_aux.pat_age,
                         l_aux.desc_room,
                         l_aux.date_send,
                         l_aux.desc_epis_anamnesis,
                         l_aux.acuity, --
                         l_aux.rank_acuity,
                         l_aux.id_schedule,
                         l_aux.id_sys_shortcut,
                         l_aux.id_reg_det,
                         l_aux.id_sys_alert, --
                         l_aux.dt_first_obs_tstz,
                         l_aux.fast_track_icon,
                         l_aux.fast_track_color,
                         l_aux.fast_track_status,
                         l_aux.esi_level,
                         l_aux.name_pat_sort,
                         l_resp_icons_table, -- this is used due to function pk_hand_off_api.get_resp_icons
                         l_aux.id_prof_order;
            
                EXIT WHEN aux_sql%NOTFOUND;
            
                l_id_sys_alert := l_aux.id_sys_alert;
            
                -- PEGAR O SOFTWARE DE ORIGEM
                --l_error       := 'Software origin';
                l_id_software := get_epis_info_software(i_prof => i_prof, i_episode => l_aux.id_episode);
            
                -- transforms the table_varchar in varchar2 separated by '|' due to function pk_hand_off_api.get_resp_icons
                l_resp_icons_str := pk_utils.concat_table(i_tab       => l_resp_icons_table,
                                                          i_delim     => '|',
                                                          i_start_off => NULL,
                                                          i_length    => NULL);
            
                -- INSERIR RESULTADOS DO SQL ALERT PARA TABELA TEMPORARIA
                --l_error := 'INSERT INTO SYS_ALERT_TEMP';
                INSERT INTO sys_alert_temp
                    (id_sys_alert_det,
                     id_reg,
                     id_episode,
                     id_institution,
                     id_prof,
                     dt_req,
                     --dt_req_tstz,
                     TIME,
                     message,
                     id_room,
                     id_patient,
                     name_pat,
                     photo,
                     gender,
                     pat_age,
                     desc_room,
                     date_send,
                     desc_epis_anamnesis,
                     acuity,
                     rank_acuity,
                     dt_first_obs_tstz,
                     id_schedule,
                     id_sys_shortcut,
                     id_reg_det,
                     id_sys_alert,
                     flg_detail,
                     id_software_origin,
                     pat_ndo,
                     pat_nd_icon,
                     fast_track_icon,
                     fast_track_color,
                     fast_track_status,
                     esi_level,
                     name_pat_sort,
                     resp_icons,
                     id_prof_order)
                VALUES
                    (l_aux.id_sys_alert_det,
                     l_aux.id_reg,
                     l_aux.id_episode,
                     l_aux.id_institution,
                     l_aux.id_prof,
                     l_aux.dt_req,
                     l_aux.time,
                     l_aux.message,
                     l_aux.id_room,
                     l_aux.id_patient,
                     l_aux.name_pat,
                     l_aux.photo,
                     l_aux.gender,
                     l_aux.pat_age,
                     l_aux.desc_room,
                     l_aux.date_send,
                     l_aux.desc_epis_anamnesis,
                     l_aux.acuity,
                     l_aux.rank_acuity,
                     l_aux.dt_first_obs_tstz,
                     l_aux.id_schedule,
                     decode(pk_sign_off.get_epis_sign_off_state(i_lang, i_prof, l_aux.id_episode),
                            pk_alert_constant.g_no,
                            l_aux.id_sys_shortcut,
                            decode(l_aux.id_sys_alert,
                                   15,
                                   pk_sign_off.g_so_ss_lab,
                                   12,
                                   decode(l_aux.id_sys_shortcut,
                                          11,
                                          pk_sign_off.g_so_ss_exam,
                                          10,
                                          pk_sign_off.g_so_ss_imag),
                                   3,
                                   decode(l_aux.id_sys_shortcut,
                                          11,
                                          pk_sign_off.g_so_ss_exam,
                                          10,
                                          pk_sign_off.g_so_ss_imag),
                                   52,
                                   pk_sign_off.g_so_ss_pend_issues,
                                   pk_sign_off.g_so_addendum)),
                     l_aux.id_reg_det,
                     l_aux.id_sys_alert,
                     i.flg_detail,
                     l_id_software,
                     l_aux.pat_ndo,
                     l_aux.pat_nd_icon,
                     l_aux.fast_track_icon,
                     l_aux.fast_track_color,
                     l_aux.fast_track_status,
                     l_aux.esi_level,
                     l_aux.name_pat_sort,
                     l_resp_icons_str,
                     l_aux.id_prof_order);
            END LOOP;
        
            CLOSE aux_sql;
        
        END LOOP;
    
        --l_error := 'OPEN CURSOR COM RESULTADOS FINAIS';
        SELECT t_rec_alert(id_sys_alert_det    => sat.id_sys_alert_det,
                           acuity              => sat.acuity,
                           date_send           => sat.date_send,
                           desc_epis_anamnesis => sat.desc_epis_anamnesis,
                           desc_room           => sat.desc_room,
                           dt_first_obs_tstz   => sat.dt_first_obs_tstz,
                           dt_req              => sat.dt_req,
                           esi_level           => sat.esi_level,
                           fast_track_color    => sat.fast_track_color,
                           fast_track_icon     => sat.fast_track_icon,
                           fast_track_status   => sat.fast_track_status,
                           flg_detail          => sat.flg_detail,
                           id_episode          => sat.id_episode,
                           gender              => sat.gender,
                           id_institution      => sat.id_institution,
                           id_patient          => sat.id_patient,
                           id_prof             => sat.id_prof,
                           id_prof_order       => sat.id_prof_order,
                           id_reg              => sat.id_reg,
                           id_reg_det          => sat.id_reg_det,
                           id_room             => sat.id_room,
                           id_schedule         => sat.id_schedule,
                           id_software_origin  => sat.id_software_origin,
                           id_sys_alert        => sat.id_sys_alert,
                           id_sys_shortcut     => sat.id_sys_shortcut,
                           message             => sat.message,
                           name_pat            => sat.name_pat,
                           name_pat_sort       => sat.name_pat_sort,
                           pat_age             => sat.pat_age,
                           pat_ndo             => sat.pat_ndo,
                           pat_nd_icon         => sat.pat_nd_icon,
                           photo               => sat.photo,
                           rank_acuity         => sat.rank_acuity,
                           resp_icons          => sat.resp_icons,
                           TIME                => sat.time)
          BULK COLLECT
          INTO tbl_return
          FROM sys_alert_temp sat
         ORDER BY sat.dt_req ASC;
    
        COMMIT;
    
        RETURN tbl_return;
    
    END tf_get_prof_alerts;

    FUNCTION set_selected_alert_read
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_sys_alert_det IN table_number,
        i_sys_alert     IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        --l_bool_total BOOLEAN := TRUE;
        --l_bool       BOOLEAN;
        --l_flg_show   VARCHAR2(4000);
        --l_msg_title  VARCHAR2(4000);
        --l_msg_text   VARCHAR2(4000);
        --l_button     VARCHAR2(4000);
        --l_error      t_error_out;
    
        err_process_alerts EXCEPTION;
    
        --*********************************
        PROCEDURE process_error
        (
            i_code IN NUMBER,
            i_errm IN VARCHAR2
        ) IS
        BEGIN
        
            pk_alert_exceptions.process_error(i_lang,
                                              i_code,
                                              i_errm,
                                              i_errm,
                                              'ALERT',
                                              'PK_ALERTS',
                                              'SET_ALL_ALERT_READ',
                                              o_error);
        
        END process_error;
    
    BEGIN
    
        /*
        FORALL i IN 1 .. i_sys_alert_det.count
            DELETE sys_alert_event
             WHERE id_sys_alert_event = i_sys_alert_det(i);
        */
    
        FOR i IN 1 .. i_sys_alert_det.count
        LOOP
        
            UPDATE sys_alert_read
               SET dt_read_tstz = current_timestamp
             WHERE id_sys_alert_event = i_sys_alert_det(i)
               AND id_professional = i_prof.id;
        
            IF SQL%ROWCOUNT = 0
            THEN
            
                INSERT INTO sys_alert_read
                    (id_sys_alert_read, id_sys_alert_event, id_professional, dt_read_tstz)
                VALUES
                    (seq_sys_alert_read.nextval, i_sys_alert_det(i), i_prof.id, current_timestamp);
            
            END IF;
        
        END LOOP;
        
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            process_error(i_code => SQLCODE, i_errm => SQLERRM);
            RETURN FALSE;
    END set_selected_alert_read;

    FUNCTION set_all_alert_read
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        tf_alerts   t_tbl_alert := t_tbl_alert();
        l_bool      BOOLEAN;
        l_flg_show  VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_msg_text  VARCHAR2(4000);
        l_button    VARCHAR2(4000);
        l_error     t_error_out;
        l_id_sys_alert_det NUMBER;
    
    BEGIN
    
        tf_alerts := pk_alerts.tf_get_prof_alerts(i_lang => i_lang, i_prof => i_prof);
    
        <<lup_thru_alerts>>
        FOR i IN 1 .. tf_alerts.count
        LOOP
            l_id_sys_alert_det := tf_alerts(i).id_sys_alert_det;
        
            UPDATE sys_alert_read
               SET dt_read_tstz = current_timestamp
             WHERE id_sys_alert_event = l_id_sys_alert_det
               AND id_professional = i_prof.id;
        
            IF SQL%ROWCOUNT = 0
            THEN
            
                INSERT INTO sys_alert_read
                    (id_sys_alert_read, id_sys_alert_event, id_professional, dt_read_tstz)
                VALUES
                    (seq_sys_alert_read.nextval, l_id_sys_alert_det, i_prof.id, current_timestamp);
            
            END IF;
        
        END LOOP lup_thru_alerts;
    
        RETURN TRUE;
    
    END set_all_alert_read;

    --************************************************************
    FUNCTION get_epis_type(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
    
        SELECT id_epis_type
          BULK COLLECT
          INTO tbl_id
          FROM episode
         WHERE id_episode = i_episode;
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_epis_type;

    --***********************************************************
    FUNCTION get_anamnesis
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_text    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_id_epis_type NUMBER;
        k_epis_type_oris CONSTANT NUMBER := pk_alert_constant.g_epis_type_operating;
        l_return VARCHAR2(4000);
    BEGIN
    
        l_id_epis_type := get_epis_type(i_episode);
    
        IF l_id_epis_type = k_epis_type_oris
        THEN
            l_return := 'ORIS**' || pk_sr_clinical_info.get_proposed_surgery(i_lang, i_episode, i_prof, 'N');
        ELSE
            l_return := i_text;
        END IF;
    
        RETURN l_return;
    
    END get_anamnesis;

    -- 
    -- **********************************************
    FUNCTION set_alert_read_x_days
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        tf_alerts   t_tbl_alert := t_tbl_alert();
        l_bool      BOOLEAN;
        l_flg_show  VARCHAR2(4000);
        l_msg_title VARCHAR2(4000);
        l_msg_text  VARCHAR2(4000);
        l_button    VARCHAR2(4000);
        l_error     t_error_out;
        l_date      TIMESTAMP WITH LOCAL TIME ZONE;
        k_config CONSTANT VARCHAR2(0200 CHAR) := 'ALERT_DAYS_LIMIT_FOR_CLEANING';
        l_days_limit NUMBER;
        --l_bool    boolean;
        l_id_sys_alert_det NUMBER;
    
        --****************************************
        FUNCTION get_alert_date(i_alert IN NUMBER) RETURN TIMESTAMP
            WITH LOCAL TIME ZONE IS
            l_return TIMESTAMP WITH LOCAL TIME ZONE;
        BEGIN
        
            SELECT x.dt_creation
              INTO l_return
              FROM sys_alert_event x
             WHERE x.id_sys_alert_event = i_alert;
        
            RETURN l_return;
        
        END get_alert_date;
    
    BEGIN
    
        l_days_limit := pk_sysconfig.get_config(k_config, i_prof.institution, i_prof.software);
    
        tf_alerts := pk_alerts.tf_get_prof_alerts(i_lang => i_lang, i_prof => i_prof);
    
        <<lup_thru_alerts>>
        FOR i IN 1 .. tf_alerts.count
        LOOP
        
            l_id_sys_alert_det := tf_alerts(i).id_sys_alert_det;
            l_date             := get_alert_date(l_id_sys_alert_det);
            l_bool := (l_date + numtodsinterval(l_days_limit, 'DAY')) < current_timestamp;
        
            IF l_bool
            THEN
            
                DELETE sys_alert_event
                 WHERE id_sys_alert_event = l_id_sys_alert_det;
            
            END IF;
        
        END LOOP lup_thru_alerts;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              SQLERRM,
                                              'ALERT',
                                              'PK_ALERTS',
                                              'SET_ALERT_READ_X_DAYS',
                                              o_error);
            RETURN FALSE;
    END set_alert_read_x_days;

    FUNCTION get_alert_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_alert   IN NUMBER,
        i_subject    IN table_varchar,
        i_from_state IN table_varchar,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        k_config CONSTANT VARCHAR2(0200 CHAR) := 'ALERT_DAYS_LIMIT_FOR_CLEANING';
        l_days NUMBER;
        k_disabled CONSTANT VARCHAR2(0010 CHAR) := 'I';
    BEGIN
    
        l_days := pk_sysconfig.get_config(k_config, i_prof.institution, i_prof.software);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT act.id_action,
                   act.id_parent,
                   act.level_nr,
                   act.to_state,
                   decode(act.action, 'ALERT_READ_X_DAYS', REPLACE(act.desc_action, '@1', l_days), act.desc_action) desc_action,
                   act.icon,
                   act.flg_default,
				   act.flg_active,
                   act.action,
                   rownum rank
              FROM (pk_action.tf_get_actions_base(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_subject    => i_subject,
                                                  i_from_state => i_from_state) act)
             ORDER BY act.level_nr, act.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS',
                                              o_error);
            pk_utils.undo_changes;
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_alert_actions;

    FUNCTION do_alert_message
    (
        i_lang          IN NUMBER,
        i_flg_duplicate IN VARCHAR2,
        i_msg_dup_no    IN VARCHAR2,
        i_msg_dup_yes   IN VARCHAR2,
        i_translate     IN VARCHAR2,
        i_replace1      IN VARCHAR2,
        i_replace2      IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_msg       VARCHAR2(4000);
        l_replace1  VARCHAR2(4000);
        l_return    VARCHAR2(4000);
        l_dup_value VARCHAR2(0200 CHAR);
        k_yes CONSTANT VARCHAR2(0100 CHAR) := 'Y';
        k_no  CONSTANT VARCHAR2(0100 CHAR) := 'N';
    BEGIN
    
        IF i_flg_duplicate = k_no
        THEN
            l_dup_value := i_msg_dup_no;
        ELSE
            l_dup_value := i_msg_dup_yes;
        END IF;
    
        l_msg := pk_message.get_message(i_lang, l_dup_value);
    
        IF i_translate = k_yes
        THEN
            l_replace1 := pk_translation.get_translation(i_lang, i_replace1);
        ELSE
            l_replace1 := i_replace1;
        END IF;
    
        l_msg    := REPLACE(l_msg, '@1', l_replace1);
        l_return := REPLACE(l_msg, '@2', i_replace2);
    
        RETURN l_return;
    
    END do_alert_message;

    FUNCTION get_config_flg_delete
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_sys_alert     IN sys_alert.id_sys_alert%TYPE,
        i_profile_template IN profile_template.id_profile_template%TYPE
    ) RETURN VARCHAR2 IS
        l_alert_config_row sys_alert_config%ROWTYPE;
        l_return           VARCHAR2(0050 CHAR);
    BEGIN
    
        l_alert_config_row := get_config(i_lang, i_prof, i_id_sys_alert, i_profile_template);
        IF l_alert_config_row.id_sys_alert_config IS NULL
        THEN
            l_return := k_no;
        ELSE
            l_return := l_alert_config_row.flg_delete;
        END IF;
    
        RETURN l_return;
    
    END get_config_flg_delete;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_owner, g_package);
    pk_alertlog.log_init(object_name => g_package, owner => g_owner);

END pk_alerts;
/
