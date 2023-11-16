/*-- Last Change Revision: $Rev: 2027747 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:11 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_surg_record AS

    -- *************************************
    FUNCTION get_config
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_config IS
        t_cfg                 t_config;
        l_cat                 NUMBER;
        l_id_market           NUMBER;
        l_id_profile_template NUMBER;
    BEGIN
    
        l_id_market           := pk_utils.get_institution_market(i_lang           => i_lang,
                                                                 i_id_institution => i_prof.institution);
        l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        l_cat                 := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
    
        -- obtain configuration
        t_cfg := pk_core_config.get_config(i_area             => k_sr_time_cfg_table,
                                           i_prof             => i_prof,
                                           i_market           => l_id_market,
                                           i_category         => l_cat,
                                           i_profile_template => l_id_profile_template,
                                           i_prof_dcs         => NULL,
                                           i_episode_dcs      => NULL);
    
        RETURN t_cfg;
    
    END get_config;

    /********************************************************************************************
    * Obter as intervenções agendadas para o Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_dt_sr_entry      Data de entrada no bloco operatório
    * @param o_dt_room_entry    Data de entrada na sala operatória
    * @param o_dt_room_exit     Data de saída da sala operatória
    * @param o_dt_sr_entry_d    Data de entrada no bloco operatório (formato date)
    * @param o_dt_room_entry_d  Data de entrada na sala operatória  (formato date)
    * @param o_dt_room_exit_d   Data de saída da sala operatória  (formato date)
    * @param o_interv           Array com as intervenções agendadas
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION get_surg_rec_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        o_dt_sr_entry     OUT VARCHAR2,
        o_dt_room_entry   OUT VARCHAR2,
        o_dt_room_exit    OUT VARCHAR2,
        o_dt_sr_entry_d   OUT VARCHAR2,
        o_dt_room_entry_d OUT VARCHAR2,
        o_dt_room_exit_d  OUT VARCHAR2,
        o_interv          OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dt IS
            SELECT pk_date_utils.date_char_tsz(i_lang, rec.dt_sr_entry_tstz, i_prof.institution, i_prof.software) dt_sr_entry,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_sr_entry_tstz, i_prof) dt_sr_entry_d,
                   pk_date_utils.date_char_tsz(i_lang, rec.dt_room_entry_tstz, i_prof.institution, i_prof.software) dt_room_entry,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_room_entry_tstz, i_prof) dt_room_entry_d,
                   pk_date_utils.date_char_tsz(i_lang, rec.dt_room_exit_tstz, i_prof.institution, i_prof.software) dt_room_exit,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_room_exit_tstz, i_prof) dt_room_exit_d
              FROM schedule_sr s
              JOIN sr_surgery_record rec
                ON rec.id_schedule_sr = s.id_schedule_sr
             WHERE s.id_episode = i_episode;
    
    BEGIN
    
        --Obtém as datas das entradas/saídas do paciente no bloco e na sala
        g_error := 'GET SR ENTRY/EXIST DATES';
        pk_alertlog.log_debug(g_error);
        OPEN c_dt;
        FETCH c_dt
            INTO o_dt_sr_entry, o_dt_sr_entry_d, o_dt_room_entry, o_dt_room_entry_d, o_dt_room_exit, o_dt_room_exit_d;
        CLOSE c_dt;
    
        --Obtém array de intervenções agendadas para o episódio
        g_error := 'GET EPIS INTERVENTIONS';
        pk_alertlog.log_debug(g_error);
        OPEN o_interv FOR
            SELECT i.id_intervention,
                   ei.id_sr_epis_interv,
                   pk_translation.get_translation(i_lang, i.code_intervention) desc_interv,
                   pk_date_utils.date_char_tsz(i_lang, ei.dt_interv_start_tstz, i_prof.institution, i_prof.software) dt_interv_start,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_interv_start_tstz, i_prof) dt_interv_start_h_h,
                   pk_date_utils.date_char_tsz(i_lang, ei.dt_interv_end_tstz, i_prof.institution, i_prof.software) dt_interv_end,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_interv_end_tstz, i_prof) dt_interv_end_h,
                   ei.flg_status,
                   decode(ei.flg_status, g_interv_can, 2, 1) ord_status
              FROM sr_epis_interv ei
              JOIN intervention i
                ON i.id_intervention = ei.id_sr_intervention
             WHERE ei.id_episode = i_episode
             ORDER BY decode(ei.flg_status, g_interv_can, 2, 1), 3, 2;
    
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
                                              'GET_SURG_REC_INTERV',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            RETURN FALSE;
        
    END get_surg_rec_interv;

    /********************************************************************************************
    * Guarda as datas das intervenções agendadas no Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_dt_sr_entry      Data de entrada no bloco operatório
    * @param i_dt_room_entry    Data de entrada na sala operatória
    * @param i_dt_room_exit     Data de saída da sala operatória
    * @param i_sr_intervention  Cursor com os IDs das intervenções
    * @param i_dt_interv_start  Cursor com datas de início das intervenções
    * @param i_dt_interv_end    Cursor com datas de fim das intervenções
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION set_surg_rec_interv
    (
        i_lang            IN language.id_language%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_prof            IN profissional,
        i_dt_sr_entry     IN VARCHAR2,
        i_dt_room_entry   IN VARCHAR2,
        i_dt_room_exit    IN VARCHAR2,
        i_sr_intervention IN table_number,
        i_dt_interv_start IN table_varchar,
        i_dt_interv_end   IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_sr_entry       TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_room_entry     TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_room_exit      TIMESTAMP WITH LOCAL TIME ZONE;
        l_rows_ei           table_varchar;
        l_rowids            table_varchar;
        l_sei_flg_status    table_varchar;
        l_id_sr_epis_interv table_number;
        l_func_name         VARCHAR2(0200 CHAR);
        l_exception   EXCEPTION;
        err_exception EXCEPTION;
    BEGIN
        --Converte datas
        l_dt_sr_entry   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_sr_entry, NULL);
        l_dt_room_entry := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_room_entry, NULL);
        l_dt_room_exit  := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_room_exit, NULL);
        g_sysdate_tstz  := current_timestamp;
    
        --Actualiza datas de entrada/saída no bloco e na sala
        g_error := 'UPDATE SURGERY RECORD DATES';
        pk_alertlog.log_debug(g_error);
        UPDATE sr_surgery_record
           SET dt_sr_entry_tstz   = l_dt_sr_entry,
               dt_room_entry_tstz = l_dt_room_entry,
               dt_room_exit_tstz  = l_dt_room_exit
         WHERE id_schedule_sr = (SELECT id_schedule_sr
                                   FROM schedule_sr
                                  WHERE id_episode = i_episode);
    
        ts_epis_info.upd(id_episode_in          => i_episode,
                         dt_room_entry_tstz_in  => l_dt_room_entry,
                         dt_room_entry_tstz_nin => FALSE,
                         rows_out               => l_rows_ei);
        COMMIT;
    
        --Actualiza datas de início e fim das itervenções
        g_error := 'UPDATE INTERVENTION DATES';
        pk_alertlog.log_debug(g_error);
    
        <<lup_thru_sr_intervention>>
        FOR i IN 1 .. i_sr_intervention.count
        LOOP
        
            g_error := 'get l_id_sr_epis_interv, l_sei_flg_status';
            SELECT sei.id_sr_epis_interv, sei.flg_status
              BULK COLLECT
              INTO l_id_sr_epis_interv, l_sei_flg_status
              FROM sr_epis_interv sei
             WHERE sei.id_episode = i_episode
               AND sei.id_sr_intervention = i_sr_intervention(i)
               AND sei.flg_status != g_interv_can;
        
            <<lup_thru_sr_epis_interv>>
            FOR k IN 1 .. l_id_sr_epis_interv.count
            LOOP
                IF l_sei_flg_status(k) IS NOT NULL
                THEN
                    g_error := 'call ts_sr_epis_interv.upd';
                    ts_sr_epis_interv.upd(dt_interv_start_tstz_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_interv_end(i),
                                                                                                    NULL),
                                          dt_interv_start_tstz_nin => FALSE,
                                          dt_interv_end_tstz_in    => pk_date_utils.get_string_tstz(i_lang,
                                                                                                    i_prof,
                                                                                                    i_dt_interv_end(i),
                                                                                                    NULL),
                                          dt_interv_end_tstz_nin   => FALSE,
                                          
                                          where_in => 'id_sr_epis_interv = ' || l_id_sr_epis_interv(k),
                                          rows_out => l_rowids);
                
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
                                                                  i_id_sr_epis_interv => l_id_sr_epis_interv(k),
                                                                  i_flg_status_new    => l_sei_flg_status(k),
                                                                  i_flg_status_old    => l_sei_flg_status(k),
                                                                  o_error             => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            END LOOP lup_thru_sr_epis_interv;
        
        END LOOP lup_thru_sr_intervention;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
        
            l_func_name := 'SET_SURG_REC_INTERV';
            RAISE err_exception;
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
            l_func_name := 'PK_VISIT.SET_FIRST_OBS';
            RAISE err_exception;
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
                l_func_name := 'PK_VISIT.SET_EPIS_PROF_REC';
                RAISE err_exception;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN err_exception THEN
            pk_alert_exceptions.reset_error_state;
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
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_REC_INTERV',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_surg_rec_interv;

    /********************************************************************************************
    * Obter as descrições do Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_flg_type         Tipo de notas. Valores possíveis: R- Registo de intervenção, N - Notas
    * 
    * @param o_surg_rec         Array com as notas
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION get_surg_rec_desc
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        i_prof     IN profissional,
        i_flg_type IN sr_surgery_rec_det.flg_type%TYPE,
        o_surg_rec OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Obtém array de registos de intervenção / notas
        g_error := 'GET O_SURG_REC ARRAY';
        pk_alertlog.log_debug(g_error);
        OPEN o_surg_rec FOR
            SELECT d.notes,
                   pk_date_utils.date_send_tsz(i_lang, d.dt_reg_tstz, i_prof) dt_reg,
                   p.nick_name,
                   r.id_surgery_record,
                   pk_date_utils.date_char_tsz(i_lang, d.dt_reg_tstz, i_prof.institution, i_prof.software) dt_notes
              FROM sr_surgery_rec_det d, sr_surgery_record r, professional p
             WHERE r.id_schedule_sr = (SELECT id_schedule_sr
                                         FROM schedule_sr
                                        WHERE id_episode = i_episode)
               AND d.id_surgery_record(+) = r.id_surgery_record
               AND d.flg_type(+) = i_flg_type
               AND p.id_professional(+) = d.id_professional
             ORDER BY d.dt_reg_tstz;
    
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
                                              'GET_SURG_REC_DESC',
                                              o_error);
            pk_types.open_my_cursor(o_surg_rec);
            RETURN FALSE;
        
    END get_surg_rec_desc;

    /********************************************************************************************
    * Guarda as descrições do Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_surgery_record   ID do registo de intervenção
    * @param i_flg_type         Tipo de notas. Valores possíveis: R- Registo de intervenção, N - Notas
    * @param i_notes            Registo de intervenção ou notas, de acordo com o FLG_TYPE
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION set_surg_rec_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_surgery_record IN sr_surgery_rec_det.id_surgery_record%TYPE,
        i_flg_type       IN sr_surgery_rec_det.flg_type%TYPE,
        i_notes          IN sr_surgery_rec_det.notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR(0200 CHAR);
        my_exception EXCEPTION;
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Guarda o registo de intervenção ou as notas se estiverem preenchidas
        g_error := 'INSERT SR_SURGERY_REC_DET';
        pk_alertlog.log_debug(g_error);
        IF i_notes IS NOT NULL
        THEN
            INSERT INTO sr_surgery_rec_det
                (id_sr_surgery_rec_det, id_surgery_record, id_professional, dt_reg_tstz, notes, flg_type)
            VALUES
                (seq_sr_surgery_rec_det.nextval, i_surgery_record, i_prof.id, g_sysdate_tstz, i_notes, i_flg_type);
        END IF;
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            l_func_name := 'PK_SR_OUTPUT.UPDATE_DT_LAST_INTERACTION';
            RAISE my_exception;
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
                l_func_name := 'PK_VISIT.SET_EPIS_PROF_REC';
                RAISE my_exception;
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
            l_func_name := 'PK_VISIT.SET_FIRST_OBS';
            RAISE my_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.reset_error_state;
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
        
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_REC_DESC',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_surg_rec_desc;

    /********************************************************************************************
    * Obter as intervenções agendadas para o Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * 
    * @param o_dt_rcv_entry     Data de entrada no Recobro
    * @param o_dt_rcv_exit      Data de saída do Recobro
    * @param o_dt_sr_exit       Data de saída do bloco
    * @param o_dt_rcv_entry_d   Data de entrada no Recobro (formato date)
    * @param o_dt_rcv_exit_d    Data de saída do Recobro (formato date)
    * @param o_dt_sr_exit_d     Data de saída do bloco (formato date)
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION get_surg_rec_interv_end
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        o_dt_rcv_entry   OUT VARCHAR2,
        o_dt_rcv_exit    OUT VARCHAR2,
        o_dt_sr_exit     OUT VARCHAR2,
        o_dt_rcv_entry_d OUT VARCHAR2,
        o_dt_rcv_exit_d  OUT VARCHAR2,
        o_dt_sr_exit_d   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_dt IS
            SELECT pk_date_utils.date_char_tsz(i_lang, rec.dt_rcv_entry_tstz, i_prof.institution, i_prof.software) dt_rcv_entry,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_rcv_entry_tstz, i_prof) dt_rcv_entry_d,
                   pk_date_utils.date_char_tsz(i_lang, rec.dt_rcv_exit_tstz, i_prof.institution, i_prof.software) dt_rcv_exit,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_rcv_exit_tstz, i_prof) dt_rcv_exit_d,
                   pk_date_utils.date_char_tsz(i_lang, rec.dt_sr_exit_tstz, i_prof.institution, i_prof.software) dt_sr_exit,
                   pk_date_utils.date_send_tsz(i_lang, rec.dt_sr_exit_tstz, i_prof) dt_sr_exit_d
              FROM schedule_sr s
              JOIN sr_surgery_record rec
                ON rec.id_schedule_sr = s.id_schedule_sr
             WHERE s.id_episode = i_episode;
    
    BEGIN
    
        --Obtém as datas das entradas/saídas do paciente no bloco e na sala
        g_error := 'GET SR ENTRY/EXIST DATES';
        pk_alertlog.log_debug(g_error);
        OPEN c_dt;
        FETCH c_dt
            INTO o_dt_rcv_entry, o_dt_rcv_entry_d, o_dt_rcv_exit, o_dt_rcv_exit_d, o_dt_sr_exit, o_dt_sr_exit_d;
        CLOSE c_dt;
    
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
                                              'GET_SURG_REC_INTERV_END',
                                              o_error);
        
            RETURN FALSE;
        
    END get_surg_rec_interv_end;

    /********************************************************************************************
    * Guarda as datas das intervenções agendadas no Registo de Intervenção
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_dt_rcv_entry     Data de entrada no Recobro
    * @param i_dt_rcv_exit      Data de saída do Recobro
    * @param i_dt_sr_exit       Data de saída do Bloco
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/08
       ********************************************************************************************/

    FUNCTION set_surg_rec_interv_end
    (
        i_lang         IN language.id_language%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_prof         IN profissional,
        i_dt_rcv_entry IN VARCHAR2,
        i_dt_rcv_exit  IN VARCHAR2,
        i_dt_sr_exit   IN VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(0200 CHAR);
        my_exception EXCEPTION;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        --Actualiza datas de entrada/saída no recobro e no bloco
        g_error := 'UPDATE SURGERY RECORD DATES';
        pk_alertlog.log_debug(g_error);
        UPDATE sr_surgery_record
           SET dt_rcv_entry_tstz = i_dt_rcv_entry, dt_rcv_exit_tstz = i_dt_rcv_exit, dt_sr_exit_tstz = i_dt_sr_exit
         WHERE id_schedule_sr = (SELECT id_schedule_sr
                                   FROM schedule_sr
                                  WHERE id_episode = i_episode);
    
        --Actualiza data da última intercção do episódio
        g_error := 'UPDATE DT_LAST_INTERACTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_output.update_dt_last_interaction(i_lang    => i_lang,
                                                       i_episode => i_episode,
                                                       i_dt_last => g_sysdate_tstz,
                                                       o_error   => o_error)
        THEN
            l_func_name := 'PK_SR_OUTPUT.UPDATE_DT_LAST_INTERACTION';
            RAISE my_exception;
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
            l_func_name := 'PK_VISIT.SET_FIRST_OBS';
            RAISE my_exception;
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
                l_func_name := 'PK_VISIT.SET_EPIS_PROF_REC';
                RAISE my_exception;
            END IF;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN my_exception THEN
            pk_alert_exceptions.reset_error_state;
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
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURG_REC_INTERV_END',
                                              o_error);
            pk_utils.undo_changes();
            RETURN FALSE;
        
    END set_surg_rec_interv_end;

    /********************************************************************************************
    * Obter a lista de valores possíveis para a Resposta Verbal
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_prof             ID do profissional, instituição e software
    * @param i_field            Nome da coluna a preencher. Por exemplo: 'SR_NURSE_REC.FLG_RESP_VERB'
    * 
    * @param o_list             Array de valores possíveis para a Resposta Verbal
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/10
       ********************************************************************************************/

    FUNCTION get_field_values_list
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_field   IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --Obtém as listas de valores possíveis para um determinado campo
        g_error := 'OPEN LIST CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN o_list FOR
            SELECT desc_val label, val data, NULL flg_defaul
              FROM sys_domain
             WHERE code_domain = i_field
               AND domain_owner = pk_sysdomain.k_default_schema
               AND id_language = i_lang
               AND flg_available = 'Y'
             ORDER BY desc_val;
    
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
                                              'GET_FILED_VALUES_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_field_values_list;

    /********************************************************************************************
    * Criação/Alteração de uma definição de tempo operatório. A função irá verificar se existe para 
    *  a instituição e software definidos já existe um tempo operatório com o FLG_TYPE definido. 
    *  Caso exista, actualiza a informação, caso contrário insere um novo registo.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do episódio
    * @param i_institution      ID da insituição
    * @param i_flg_type         Tipo do tempo operatório
    * @param i_rank             Rank para ordenações
    * @param i_name             Nome para a língua definida
    * @param i_available        Y-Disponível; N-Não disponível
    * @param i_flg_pat_status   Estado para onde deve mudar o paciente quando se introduz o tempo operatório, 
    *                            caso este exista
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/06
       ********************************************************************************************/

    ------------------
    ------------------ DEPRECATED FUNCTION
    ------------------

    FUNCTION set_surgery_time_def
    (
        i_lang           IN language.id_language%TYPE,
        i_software       IN software.id_software%TYPE,
        i_institution    IN institution.id_institution%TYPE,
        i_flg_type       IN sr_surgery_time.flg_type%TYPE,
        i_rank           IN NUMBER,
        i_name           IN pk_translation.t_desc_translation,
        i_available      IN sr_surgery_time.flg_available%TYPE,
        i_flg_pat_status IN sr_surgery_time.flg_pat_status%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        dbms_output.put_line('DEPRECATED FUNCTION');
    END set_surgery_time_def;

    /********************************************************************************************
    * Obtém os tempos operatórios para um dado episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_software         Id do software
    * @param i_institution      Id da instituição
    * @param i_episode          Id do episódio
    * 
    * @param o_surgery_time_def Cursor com as categorias de tempos operatórios definidos para o 
    *                            software e instituição definidos.
    * @param o_surgery_times    Cursor com os tempos operatórios para o episódio definido.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/07
       ********************************************************************************************/

    FUNCTION get_surgery_times
    (
        i_lang             IN language.id_language%TYPE,
        i_software         IN software.id_software%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        t_cfg  t_config := t_config(0, 0);
        l_prof profissional := profissional(0, i_institution, i_software);
    BEGIN
        g_error := 'OPEN O_SURGERY_TIME_DEF';
        pk_alertlog.log_debug(g_error);
    
        -- get configuration id
        t_cfg := get_config(i_lang => i_lang, i_prof => l_prof);
    
        -- CMF get record configured
        OPEN o_surgery_time_def FOR
            SELECT xmain.*
              FROM (SELECT v.id_record id_sr_surgery_time,
                           CASE
                                WHEN desc_sst IS NULL THEN
                                 pk_translation.get_translation(i_lang, v.code_sst)
                                ELSE
                                 desc_sst
                            END description,
                           v.flg_type,
                           v.rank
                      FROM v_surgery_time_cfg v
                     WHERE v.id_config = t_cfg.id_config
                       AND v.id_inst_owner = t_cfg.id_inst_owner
                       AND rownum > 0) xmain
             ORDER BY xmain.rank, xmain.description;
    
        g_error := 'OPEN O_SURGERY_TIMES';
        pk_alertlog.log_debug(g_error);
        OPEN o_surgery_times FOR
            SELECT id_sr_surgery_time,
                   pk_date_utils.date_char_tsz(i_lang, dt_surgery_time_det_tstz, i_institution, i_software) AS dt_surgery_time_det,
                   pk_date_utils.date_send_tsz(i_lang, dt_surgery_time_det_tstz, i_institution, i_software) AS dt_surgery_time_det_str,
                   p.nick_name,
                   (SELECT COUNT(1)
                      FROM sr_surgery_time_det sr2
                     WHERE sr2.id_sr_surgery_time = sr1.id_sr_surgery_time
                       AND sr2.id_episode = i_episode) AS total_records
              FROM sr_surgery_time_det sr1
              JOIN professional p
                ON p.id_professional = sr1.id_professional
             WHERE flg_status = g_status_available
               AND id_episode = i_episode;
    
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
                                              'GET_SURGERY_TIMES',
                                              o_error);
            pk_types.open_my_cursor(o_surgery_time_def);
            pk_types.open_my_cursor(o_surgery_times);
            RETURN FALSE;
        
    END get_surgery_times;

    /********************************************************************************************
    * Obtém os tempos operatórios para um dado episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_software         Id do software
    * @param i_institution      Id da instituição
    * @param i_sr_surgery_time  ID da categoria de tempo operatório
    * @param i_episode          Id do episódio
    * 
    * @param o_surgery_time_det Cursor com todos os tempos registados para a categoria definida
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/07
       ********************************************************************************************/

    FUNCTION get_surgery_time_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_sr_surgery_time  IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        o_surgery_time_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_date_label     sys_message.desc_message%TYPE;
        l_register_label sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_date_label     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SR_OPERATIVE_TIMES_M002');
        l_register_label := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SR_OPERATIVE_TIMES_M001');
    
        g_error := 'OPEN O_SURGERY_TIME_DET';
        pk_alertlog.log_debug(g_error);
        OPEN o_surgery_time_det FOR
            SELECT pk_sysdomain.get_domain(g_sr_surgery_time_det_status, sstd.flg_status, i_lang) state_desc,
                   l_date_label date_label,
                   pk_date_utils.date_char_tsz(i_lang, dt_surgery_time_det_tstz, i_prof.institution, i_prof.software) dt_surgery_time_det,
                   l_register_label || pk_prof_utils.get_detail_signature(i_lang,
                                                                           i_prof,
                                                                           id_episode,
                                                                           CASE
                                                                               WHEN sstd.flg_status = g_status_available THEN
                                                                                dt_reg_tstz
                                                                               ELSE
                                                                                dt_cancel_tstz
                                                                           END,
                                                                           id_professional) record_signature
              FROM sr_surgery_time_det sstd
             WHERE sstd.id_sr_surgery_time = i_sr_surgery_time
               AND sstd.id_episode = i_episode
             ORDER BY flg_status, dt_reg_tstz DESC;
    
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
                                              'GET_SURGERY_TIME_DET',
                                              o_error);
            pk_types.open_my_cursor(o_surgery_time_det);
        
            RETURN FALSE;
    END get_surgery_time_det;

    /********************************************************************************************
    * Obtém os tempos operatórios para um dado episódio.
    *
    * @param i_lang             Id do idioma
    * @param i_sr_surgery_time  ID da categoria de tempo operatório
    * @param i_episode          Id do episódio
    * @param i_dt_surgery_time  Data a registar
    * @param i_prof             ID do profissional, instituição e software
    * @param i_test             Permite apenas fazer a validação se o tempo operatório pode ser inserido, 
    *                           sem alterar dados. Valores possíveis:
    *                                            Y- Apenas faz validação.
    *                                            N- Execução normal da função
    * @param i_dt_reg           Data da criação do registo dos tempos
    * 
    * @param o_flg_show         Indica se existe uma mensagem para mostrar ao utilizador
    * @param o_msg_result       Mensagem a apresentar
    * @param o_title            Título da mensagem
    * @param o_button           Botões a apresentar. N - Botão de não confirmação
    *                                                C - validate/read button
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/07
       ********************************************************************************************/
    FUNCTION get_flg_type(i_sr_surgery_time IN NUMBER) RETURN VARCHAR2 IS
        tbl_type table_varchar;
        l_return VARCHAR2(0050 CHAR);
    BEGIN
    
        SELECT sst.flg_type
          BULK COLLECT
          INTO tbl_type
          FROM sr_surgery_time sst
         WHERE sst.id_sr_surgery_time = i_sr_surgery_time;
    
        IF tbl_type.count > 0
        THEN
            l_return := tbl_type(1);
        END IF;
    
        RETURN l_return;
    
    END get_flg_type;

    -- **********************************
    FUNCTION set_surgery_time
    (
        i_lang                   IN language.id_language%TYPE,
        i_sr_surgery_time        IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_dt_surgery_time        IN VARCHAR2,
        i_prof                   IN profissional,
        i_test                   IN VARCHAR2,
        i_dt_reg                 IN VARCHAR2 DEFAULT NULL,
        i_transaction_id         IN VARCHAR2,
        o_flg_show               OUT VARCHAR2,
        o_msg_result             OUT VARCHAR2,
        o_title                  OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_flg_refresh            OUT VARCHAR2,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_sr_surg_time_det sr_surgery_time_det.id_sr_surgery_time_det%TYPE;
        l_found_id_surg_time  sr_surgery_time.id_sr_surgery_time%TYPE;
        l_found_rank          sr_surgery_time.rank%TYPE;
        l_i_rank              sr_surgery_time.rank%TYPE;
        l_new_flg_status      sr_surgery_time.flg_pat_status%TYPE;
        l_new_status_rank     sys_domain.rank%TYPE;
        l_curr_flg_status     sr_surgery_time.flg_pat_status%TYPE;
        l_curr_status_rank    sys_domain.rank%TYPE;
        l_aux                 VARCHAR2(512);
        l_ret                 BOOLEAN;
        l_surg_flg_type       sr_surgery_time.flg_type%TYPE;
        --l_dt_surgery_time         TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_reg                  TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_sr_surgery_time      sr_surgery_time.id_sr_surgery_time%TYPE;
        l_flg_type                sr_surgery_time.flg_type%TYPE;
        l_new_flg_type            sr_surgery_time.flg_type%TYPE;
        l_allowed_anesthesia_time sys_config.value%TYPE;
    
        k_ini_surgery CONSTANT VARCHAR2(0100 CHAR) := 'INI_SURGERY';
        k_end_surgery CONSTANT VARCHAR2(0100 CHAR) := 'END_SURGERY';
    
        l_rows_ei table_varchar;
    
        l_ins_order sr_surgery_time_det.ins_order%TYPE;
        l_repeated_times_exception EXCEPTION;
        l_transaction_id    VARCHAR2(4000);
        l_sei_flg_status    table_varchar;
        l_id_sr_epis_interv table_number;
        l_rowids            table_varchar;
        l_exception EXCEPTION;
    
        -- cmf
        t_cfg             t_config := t_config(0, 0);
        l_rank            NUMBER;
        l_dt_surgery_time TIMESTAMP WITH TIME ZONE;
    
        --
        l_init_state VARCHAR2(4 CHAR);
    
        -- Cursor para validar se existe algum tempo operatório anterior a este na sequencia com data posterior à data a introduzir
        -- ou tempo operatório posterior a este com data anterior à data a introduzir.
        CURSOR c_sequential_date
        (
            i_order_rank      IN NUMBER,
            i_dt_surgery_time IN TIMESTAMP WITH TIME ZONE
        ) IS
            SELECT std.id_sr_surgery_time, xv.rank found_rank, i_order_rank i_rank, xv.flg_type
              FROM sr_surgery_time_det std
              JOIN (SELECT v.*
                      FROM v_surgery_time_cfg v
                     WHERE v.id_config = t_cfg.id_config
                       AND v.id_inst_owner = t_cfg.id_inst_owner) xv
                ON xv.id_record = std.id_sr_surgery_time
             WHERE std.id_episode = i_episode
               AND std.flg_status = g_status_available
               AND std.id_sr_surgery_time != i_sr_surgery_time
               AND ((
                   -- check if rank is lower than current, and dt_surgery greater than current
                    (xv.rank < i_order_rank) AND (std.dt_surgery_time_det_tstz > i_dt_surgery_time) AND
                    (std.dt_surgery_time_det_tstz IS NOT NULL)) OR
                   (
                   -- check if rank is greater than current, and dt_surgery lower than current
                    (xv.rank > i_order_rank) AND (std.dt_surgery_time_det_tstz < i_dt_surgery_time) AND
                    (std.dt_surgery_time_det_tstz IS NOT NULL)))
             ORDER BY xv.rank;
    
        -- Cursor para obter o novo estado para o paciente (
        --    caso esteja associada uma mudança de estado à categoria de tempo operatório e
        --  caso o tempo operatório a ser introduzido seja o maior introduzido na sequência de tempos operatórios )
        CURSOR c_get_new_pat_status(t_cfg IN t_config) IS
            SELECT vv.flg_pat_status, vv.order_rank
              FROM (SELECT v.flg_pat_status, v.rank order_rank
                      FROM v_surgery_time_cfg v
                     WHERE v.id_record = i_sr_surgery_time
                       AND v.id_config = t_cfg.id_config
                       AND v.id_inst_owner = t_cfg.id_inst_owner
                       AND rownum > 0) vv
             ORDER BY vv.order_rank DESC;
    
        -- Cursor para obter o estado actual do paciente
        CURSOR c_get_pat_status(t_cfg IN t_config) IS
            SELECT pt.flg_pat_status, cfg.rank
              FROM sr_pat_status pt
              JOIN (SELECT v.*
                      FROM v_surgery_time_cfg v
                     WHERE v.id_config = t_cfg.id_config
                       AND v.id_inst_owner = t_cfg.id_inst_owner
                       AND rownum > 0) cfg
                ON cfg.flg_pat_status = pt.flg_pat_status
             WHERE pt.id_episode = i_episode
             ORDER BY pt.dt_status_tstz DESC;
    
        -- ******************************************
        CURSOR c_get_pat_status_aw IS
            SELECT pt.flg_pat_status
              FROM sr_pat_status pt
             WHERE pt.id_episode = i_episode
             ORDER BY pt.dt_status_tstz DESC;
    
        FUNCTION get_rank
        (
            i_surgery_time IN NUMBER,
            i_tcg          IN t_config
        ) RETURN NUMBER IS
            tbl_num table_number;
            l_num   NUMBER;
        BEGIN
        
            SELECT to_number(rank)
              BULK COLLECT
              INTO tbl_num
              FROM v_surgery_time_cfg v
             WHERE v.id_config = i_tcg.id_config
               AND v.id_inst_owner = i_tcg.id_inst_owner
               AND v.id_record = i_surgery_time;
        
            IF tbl_num.count > 0
            THEN
                l_num := tbl_num(1);
            END IF;
        
            RETURN l_num;
        
        END get_rank;
    
        -- ********************************************************     
        FUNCTION get_msg_result
        (
            i_found_rank         IN NUMBER,
            i_rank               IN NUMBER,
            i_found_id_surg_time IN NUMBER
        ) RETURN VARCHAR2 IS
            l_code_message VARCHAR2(0200 CHAR);
            k_code CONSTANT VARCHAR2(0100 CHAR) := 'SR_SURGERY_TIME.CODE_SR_SURGERY_TIME.';
            l_msg VARCHAR2(4000);
        BEGIN
        
            IF (i_found_rank < i_rank)
            THEN
                -- MSG: A data introduzida não pode ser anterior à data de <Nome Categoria>
                l_code_message := 'SURGERY_ROOM_M020';
            ELSE
                -- MSG: A data introduzida não pode ser posterior à data de <Nome Categoria>
                l_code_message := 'SURGERY_ROOM_M021';
            END IF;
        
            l_msg := pk_translation.get_translation(i_lang, k_code || i_found_id_surg_time);
            l_msg := pk_message.get_message(i_lang, l_code_message) || chr(32) || l_msg;
        
            RETURN l_msg;
        
        END get_msg_result;
    
        -- ********************************************************
        PROCEDURE ins_surgery_time_det(i_dt_surgery_time IN TIMESTAMP WITH TIME ZONE) IS
            tbl_id                table_number;
            tbl_order             table_number;
            l_ins_order           NUMBER;
            l_id_sr_surg_time_det NUMBER;
        BEGIN
        
            g_error := 'CHECK ACTIVE SURG TIME';
            pk_alertlog.log_debug(g_error);
        
            SELECT id_sr_surgery_time_det, ins_order
              BULK COLLECT
              INTO tbl_id, tbl_order
              FROM sr_surgery_time_det
             WHERE id_sr_surgery_time = i_sr_surgery_time
               AND id_episode = i_episode
               AND flg_status = g_status_available;
        
            IF tbl_id.count > 0
            THEN
            
                l_id_sr_surg_time_det := tbl_id(1);
                l_ins_order           := tbl_order(1);
            
                g_error := 'CANCEL ACTIVE SURG_TIME_DET';
                pk_alertlog.log_debug(g_error);
                UPDATE sr_surgery_time_det
                   SET flg_status = g_status_cancel, id_prof_cancel = i_prof.id, dt_cancel_tstz = g_sysdate_tstz
                 WHERE id_sr_surgery_time_det = l_id_sr_surg_time_det;
            
                g_error := 'CALL PK_IA_EVENT_COMMON.SURGERY_TIME_CANCEL';
                pk_alertlog.log_debug(g_error);
                pk_ia_event_common.surgery_time_cancel(i_id_institution         => i_prof.institution,
                                                       i_id_sr_surgery_time_det => l_id_sr_surg_time_det,
                                                       i_id_sr_surgery_time     => i_sr_surgery_time,
                                                       i_id_episode             => i_episode);
            
            END IF;
        
            o_id_sr_surgery_time_det := seq_sr_surgery_time_det.nextval;
        
            g_error := 'INSERT SURG_TIME_DET';
            pk_alertlog.log_debug(g_error);
            BEGIN
                INSERT INTO sr_surgery_time_det
                    (id_sr_surgery_time_det,
                     id_sr_surgery_time,
                     id_episode,
                     dt_surgery_time_det_tstz,
                     id_professional,
                     dt_reg_tstz,
                     flg_status,
                     ins_order)
                VALUES
                    (o_id_sr_surgery_time_det,
                     i_sr_surgery_time,
                     i_episode,
                     i_dt_surgery_time,
                     i_prof.id,
                     nvl(l_dt_reg, g_sysdate_tstz),
                     g_status_available,
                     nvl(l_ins_order, 0) + 1);
            EXCEPTION
                WHEN dup_val_on_index THEN
                    RAISE l_repeated_times_exception;
            END;
        
            g_error := 'UPDATE EPIS_INFO DT_SURGERY_TIME';
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in               => i_episode,
                             dt_surgery_time_det_tstz_in => i_dt_surgery_time,
                             rows_out                    => l_rows_ei);
        
            g_error := 'CALL PK_IA_EVENT_COMMON.SURGERY_TIME_NEW';
            pk_alertlog.log_debug(g_error);
            pk_ia_event_common.surgery_time_new(i_id_institution         => i_prof.institution,
                                                i_id_sr_surgery_time_det => o_id_sr_surgery_time_det,
                                                i_id_sr_surgery_time     => i_sr_surgery_time,
                                                i_id_episode             => i_episode);
        
        END ins_surgery_time_det;
    
        -- *****************************************************************
        PROCEDURE do_flg_show_when_no
        (
            i_prof            IN profissional,
            i_dt_surgery_time IN TIMESTAMP WITH TIME ZONE
        ) IS
            --l_return VARCHAR2(0050 CHAR);
            k_2chr CONSTANT VARCHAR2(0010 CHAR) := chr(13) || chr(13);
            tbl_tmp table_varchar := table_varchar('', '', '');
            k_code CONSTANT VARCHAR2(0200 CHAR) := 'SR_SURGERY_TIME.CODE_SR_SURGERY_TIME.' ||
                                                   to_char(i_sr_surgery_time);
        BEGIN
        
            IF (o_flg_show = pk_alert_constant.g_no)
            THEN
            
                o_flg_show := pk_alert_constant.g_yes;
                o_title    := pk_message.get_message(i_lang, 'SR_LABEL_T338');
                o_button   := 'NC';
            
                tbl_tmp(1) := pk_message.get_message(i_lang, 'SR_LABEL_T339') || k_2chr;
                tbl_tmp(2) := pk_translation.get_translation(i_lang, k_code) || ': ';
                tbl_tmp(3) := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                          i_date => i_dt_surgery_time,
                                                          i_inst => i_prof.institution,
                                                          i_soft => i_prof.software);
            
                o_msg_result := tbl_tmp(1) || tbl_tmp(2) || tbl_tmp(3);
            
            END IF;
        
        END do_flg_show_when_no;
    
        -- *******************************************************************    
        PROCEDURE get_epis_interv_flg(i_episode IN NUMBER) IS
        BEGIN
        
            SELECT sei.id_sr_epis_interv, sei.flg_status
              BULK COLLECT
              INTO l_id_sr_epis_interv, l_sei_flg_status
              FROM sr_epis_interv sei
             WHERE id_episode_context = i_episode
               AND flg_status != g_interv_can;
        
        END get_epis_interv_flg;
    
        -- **********************************************************************
    
        PROCEDURE do_stuff_surgery(i_mode IN VARCHAR2) IS
            l_flag VARCHAR2(0010 CHAR);
        
            -- **********************************************
            FUNCTION get_flag_from_mode
            (
                i_mode       IN VARCHAR2,
                i_flg_status IN VARCHAR2
            ) RETURN VARCHAR2 IS
                l_return VARCHAR2(0010 CHAR);
            BEGIN
            
                IF i_mode = k_ini_surgery
                THEN
                
                    IF i_flg_status = g_interv_status_requisition
                    THEN
                        l_return := g_interv_status_execution;
                    ELSE
                        l_return := i_flg_status;
                    END IF;
                ELSE
                
                    IF i_flg_status IN (g_interv_status_requisition, g_interv_status_execution)
                    THEN
                        l_return := g_interv_status_finished;
                    ELSE
                        l_return := i_flg_status;
                    END IF;
                
                END IF;
            
                RETURN l_return;
            
            END get_flag_from_mode;
            -- ####################################################
        
        BEGIN
        
            g_error := 'get l_flg_status';
            pk_alertlog.log_debug(g_error);
        
            get_epis_interv_flg(i_episode => i_episode);
        
            -- Only changes to Excecution if intervention is in Requisition status
            -- and begin updating the end date
            <<lup_thru_sr_epis_interv>>
            FOR i IN 1 .. l_id_sr_epis_interv.count
            LOOP
            
                IF l_sei_flg_status(i) IS NOT NULL
                THEN
                
                    l_flag := get_flag_from_mode(i_mode => i_mode, i_flg_status => l_sei_flg_status(i));
                
                    g_error := 'call  ts_sr_epis_interv.upd';
                    ts_sr_epis_interv.upd(flg_status_in            => l_flag,
                                          dt_interv_start_tstz_in  => l_dt_surgery_time,
                                          dt_interv_start_tstz_nin => FALSE,
                                          where_in                 => 'id_sr_epis_interv = ' || l_id_sr_epis_interv(i),
                                          rows_out                 => l_rowids);
                
                    g_error := 'call  t_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'SR_EPIS_INTERV',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                
                    g_error := 'call pk_sr_output.set_ia_event_prescription';
                    IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_flg_action        => 'U',
                                                                  i_id_sr_epis_interv => l_id_sr_epis_interv(i),
                                                                  i_flg_status_new    => l_flag,
                                                                  i_flg_status_old    => l_sei_flg_status(i),
                                                                  o_error             => o_error)
                    THEN
                        RAISE l_exception;
                    END IF;
                
                END IF;
            
            END LOOP lup_thru_sr_epis_interv;
        
        END do_stuff_surgery;
        -- ##########################################################
    
        -- **********************************************************
        FUNCTION do_exception
        (
            i_code IN NUMBER,
            i_errm IN VARCHAR2
        ) RETURN BOOLEAN IS
        BEGIN
        
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              i_code,
                                              i_errm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURGERY_TIME',
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        END do_exception;
    
    BEGIN
    
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        o_flg_show     := pk_alert_constant.g_no;
        o_flg_refresh  := pk_alert_constant.g_no; -- flag to know if the flash should do or not refresh the grid
        --Converter datas
        l_dt_surgery_time := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_surgery_time, NULL);
        l_dt_reg          := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_reg, NULL);
    
        g_error := 'get SR_ALLOWED_ANESTHESIA_OPERATIVE_TIMES sys_config';
        pk_alertlog.log_debug(g_error);
        l_allowed_anesthesia_time := pk_sysconfig.get_config('SR_ALLOWED_ANESTHESIA_OPERATIVE_TIMES', i_prof);
    
        t_cfg := get_config(i_lang, i_prof);
    
        l_dt_surgery_time := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_surgery_time, NULL);
    
        l_rank := get_rank(i_surgery_time => i_sr_surgery_time, i_tcg => t_cfg);
    
        -- Valida se a data a introduzir é válida.
        g_error := 'OPEN C_SEQUENTIAL_DATE';
        pk_alertlog.log_debug(g_error);
        OPEN c_sequential_date(i_order_rank => l_rank, i_dt_surgery_time => l_dt_surgery_time);
        FETCH c_sequential_date
            INTO l_found_id_surg_time, l_found_rank, l_i_rank, l_flg_type;
        g_found := c_sequential_date%FOUND;
        CLOSE c_sequential_date;
    
        --get operative time type
        l_new_flg_type := get_flg_type(i_sr_surgery_time => i_sr_surgery_time);
    
        IF g_found
        THEN
            -- check if can the anesthesia start date be prior of patient's entry to the OR
            IF NOT ((l_new_flg_type IN (g_type_anest_start, g_type_patient_ent_room) AND
                l_flg_type IN (g_type_patient_ent_room, g_type_anest_start) AND
                l_allowed_anesthesia_time = pk_alert_constant.g_yes))
            THEN
                -- A data não pode ser introduzida.
                o_flg_show := pk_alert_constant.g_yes;
                o_title    := pk_message.get_message(i_lang, 'SURGERY_ROOM_M014');
                o_button   := 'C';
            
                o_msg_result := get_msg_result(i_found_rank         => l_found_rank,
                                               i_rank               => l_i_rank,
                                               i_found_id_surg_time => l_found_id_surg_time);
            
                -- FLOW INTERRUPTION *******************
                RETURN TRUE;
                -- FLOW INTERRUPTION *******************
            END IF;
        END IF;
    
        -- Apenas insere a informação se a função não foi chamada em modo de teste.
        IF (i_test = g_value_y)
        THEN
        
            do_flg_show_when_no(i_prof => i_prof, i_dt_surgery_time => l_dt_surgery_time);
        
        ELSE
        
            ins_surgery_time_det(i_dt_surgery_time => l_dt_surgery_time);
        
            -- Valida se o estado do paciente deve ser alterado
            g_error := 'OPEN C_GET_NEW PAT_STATUS';
            pk_alertlog.log_debug(g_error);
            OPEN c_get_new_pat_status(t_cfg => t_cfg);
            FETCH c_get_new_pat_status
                INTO l_new_flg_status, l_new_status_rank;
            CLOSE c_get_new_pat_status;
        
            -- Obtém o estado actual do paciente da PAT_STATUS
            g_error := 'OPEN C_GET_PAT_STATUS';
            pk_alertlog.log_debug(g_error);
            OPEN c_get_pat_status(t_cfg => t_cfg);
            FETCH c_get_pat_status
                INTO l_curr_flg_status, l_curr_status_rank;
            CLOSE c_get_pat_status;
        
            IF l_curr_flg_status IS NULL
            THEN
            
                OPEN c_get_pat_status_aw;
                FETCH c_get_pat_status_aw
                    INTO l_init_state;
                CLOSE c_get_pat_status_aw;
            
            END IF;
        
            IF (nvl(l_new_flg_status, '@') <> '@')
            THEN
                IF l_new_flg_status <> nvl(l_curr_flg_status, '@')
                   AND l_new_status_rank > nvl(l_curr_status_rank, 0)
                THEN
                    -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
                    g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
                    pk_alertlog.log_debug(g_error);
                    l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
                
                    -- Altera o estado do paciente
                    g_error := 'SET PAT STATUS';
                    pk_alertlog.log_debug(g_error);
                    l_ret := pk_sr_grid.call_set_pat_status(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            i_episode        => i_episode,
                                                            i_flg_status_new => l_new_flg_status,
                                                            i_flg_status_old => coalesce(l_init_state, l_curr_flg_status),
                                                            i_test           => g_value_n,
                                                            i_transaction_id => l_transaction_id,
                                                            o_flg_show       => l_aux,
                                                            o_msg_title      => l_aux,
                                                            o_msg_text       => l_aux,
                                                            o_button         => l_aux,
                                                            o_error          => o_error);
                
                    g_error := 'CHANGE THE STATUS FLG_REFRESH';
                    pk_alertlog.log_debug(g_error);
                    o_flg_refresh := pk_alert_constant.g_yes;
                END IF;
            END IF;
        
            g_error := 'Check episode begin_date_tstz';
            pk_alertlog.log_debug(g_error);
            IF ((nvl(l_new_flg_status, l_curr_flg_status) = l_curr_flg_status AND
               l_curr_flg_status IN (pk_sr_grid.g_pat_status_v,
                                       pk_sr_grid.g_pat_status_p,
                                       pk_sr_grid.g_pat_status_r,
                                       pk_sr_grid.g_pat_status_s,
                                       pk_sr_grid.g_pat_status_f,
                                       pk_sr_grid.g_pat_status_y,
                                       pk_sr_grid.g_pat_status_d)) OR
               l_init_state IN (pk_sr_grid.g_pat_status_a, pk_sr_grid.g_pat_status_t, pk_sr_grid.g_pat_status_w))
            THEN
                g_error := 'Function get_sr_surgery_time';
                pk_alertlog.log_debug(g_error);
                l_id_sr_surgery_time := pk_sr_visit.get_sr_surgery_time(i_lang, i_prof, i_episode);
            
                IF (l_id_sr_surgery_time = i_sr_surgery_time)
                THEN
                    g_error := 'Update episode begin_date_tstz';
                    pk_alertlog.log_debug(g_error);
                    l_ret := pk_sr_visit.set_epis_admission(i_lang  => i_lang,
                                                            i_prof  => i_prof,
                                                            i_epis  => i_episode,
                                                            o_error => o_error);
                END IF;
            END IF;
        
            -- If the surgery time being set corresponds to the begining or end of surgery, the status on SR_EPIS_INTERV table will be updated.
            g_error := 'SELECT FLG_TYPE';
            pk_alertlog.log_debug(g_error);
            l_surg_flg_type := get_flg_type(i_sr_surgery_time => i_sr_surgery_time);
        
            -- Beginning of surgery
            IF nvl(l_surg_flg_type, '@') = g_type_surg_begin
            THEN
                g_error := 'get l_flg_status';
                pk_alertlog.log_debug(g_error);
            
                do_stuff_surgery(i_mode => k_ini_surgery);
            
            END IF;
            -- End of surgery
            IF nvl(l_surg_flg_type, '@') = g_type_surg_end
            THEN
            
                do_stuff_surgery(i_mode => k_end_surgery);
            
                g_error := 'CALL PK_SR_SURG_RECORD.SET_SURG_PROCESS_STATUS FOR ID_EPISODE: ' || i_episode;
                pk_alertlog.log_debug(g_error);
                IF NOT pk_sr_surg_record.set_surg_process_status(i_lang    => i_lang,
                                                                 i_prof    => i_prof,
                                                                 i_episode => i_episode,
                                                                 i_status  => pk_sr_approval.g_completed_surgery,
                                                                 o_error   => o_error)
                THEN
                    RETURN do_exception(i_code => SQLCODE, i_errm => SQLERRM);
                
                END IF;
            
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
                    RETURN do_exception(i_code => SQLCODE, i_errm => SQLERRM);
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
                RETURN do_exception(i_code => SQLCODE, i_errm => SQLERRM);
            END IF;
        
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.DO_COMMIT FOR ID_TRANSACTION: ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_repeated_times_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              'SURGERY_ROOM_M031',
                                              pk_message.get_message(i_lang, 'SURGERY_ROOM_M031'),
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_SURGERY_TIME',
                                              'U',
                                              pk_message.get_message(i_lang, 'SURGERY_ROOM_M033'),
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            RETURN do_exception(i_code => SQLCODE, i_errm => SQLERRM);
    END set_surgery_time;

    -- telmo 16-12-2010. overloading necessario para uso do flash
    FUNCTION set_surgery_time
    (
        i_lang                   IN language.id_language%TYPE,
        i_sr_surgery_time        IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_dt_surgery_time        IN VARCHAR2,
        i_prof                   IN profissional,
        i_test                   IN VARCHAR2,
        i_dt_reg                 IN VARCHAR2 DEFAULT NULL,
        o_flg_show               OUT VARCHAR2,
        o_msg_result             OUT VARCHAR2,
        o_title                  OUT VARCHAR2,
        o_button                 OUT VARCHAR2,
        o_flg_refresh            OUT VARCHAR2,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_transaction_id VARCHAR2(4000);
        l_ext_exception EXCEPTION;
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'CALL SET_SURGERY_TIME FOR ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT set_surgery_time(i_lang                   => i_lang,
                                i_sr_surgery_time        => i_sr_surgery_time,
                                i_episode                => i_episode,
                                i_dt_surgery_time        => i_dt_surgery_time,
                                i_prof                   => i_prof,
                                i_test                   => i_test,
                                i_dt_reg                 => i_dt_reg,
                                i_transaction_id         => l_transaction_id,
                                o_flg_show               => o_flg_show,
                                o_msg_result             => o_msg_result,
                                o_title                  => o_title,
                                o_button                 => o_button,
                                o_flg_refresh            => o_flg_refresh,
                                o_id_sr_surgery_time_det => o_id_sr_surgery_time_det,
                                o_error                  => o_error)
        THEN
            RAISE l_ext_exception;
        END IF;
    
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.DO_COMMIT FOR ID_TRANSACTION: ' || l_transaction_id;
        pk_alertlog.log_debug(g_error);
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_ext_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
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
                                              'GET_RECEIVE_STATUS',
                                              o_error);
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END set_surgery_time;

    /********************************************************************************************
    * Obtém a data de registo default para uma categoria de tempos operatórios e um episódio. 
    *   A data default é obtida do último registo activo e caso este não exista, a data de sistema.
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, instituição e software
    * @param i_sr_surgery_time  ID da categoria de tempo operatório
    * @param i_episode          Id do episódio
    * 
    * @param o_date             Data default a usar na criação de um novo registo
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/07
       ********************************************************************************************/

    FUNCTION get_surg_time_default_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        o_date            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_active_date VARCHAR2(50); --TIMESTAMP WITH LOCAL TIME ZONE;
        tbl_date      table_varchar;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_ACTIVE_TIME';
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_date_utils.date_send_tsz(i_lang, dt_surgery_time_det_tstz, i_prof) dt_surgery_time_det
          BULK COLLECT
          INTO tbl_date
          FROM sr_surgery_time_det
         WHERE flg_status = g_status_available
           AND id_sr_surgery_time = i_sr_surgery_time
           AND id_episode = i_episode;
    
        IF tbl_date.count > 0
        THEN
            l_active_date := tbl_date(1);
        ELSE
            l_active_date := pk_date_utils.get_timestamp_str(i_lang, i_prof, g_sysdate_tstz, NULL);
        END IF;
    
        o_date := l_active_date;
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
                                              'GET_SURG_TIME_DEFAULT_DATE',
                                              o_error);
            RETURN FALSE;
    END get_surg_time_default_date;

    /**************************************************************************
    * Update the surgical record                                              *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    *                                                                         *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        1.0                                     *
    * @since                          2009/10/16                              *
    **************************************************************************/

    FUNCTION set_surg_process_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_status  IN sr_surgery_record.flg_sr_proc%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name         VARCHAR(32) := 'SET_SURG_PROCESS_STATUS';
        l_rowsid            table_varchar;
        l_id_surgery_record sr_surgery_record.id_surgery_record%TYPE;
        l_flg_sr_proc       sr_surgery_record.flg_sr_proc%TYPE;
        excep   EXCEPTION;
        excep_b EXCEPTION;
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET THE ID_SURGERY_RECORD for episode : ' || i_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_surgery_record, flg_sr_proc
              INTO l_id_surgery_record, l_flg_sr_proc
              FROM sr_surgery_record ssr
             WHERE ssr.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                RAISE excep_b;
        END;
    
        pk_alertlog.log_info(text            => 'Begin execution of ID_SURGERY_RECORD :' || l_id_surgery_record,
                             object_name     => 'PK_SR_SURG_RECORD',
                             sub_object_name => l_func_name);
    
        --if the new status is the same the current status, is not necessary execute the update.
        IF nvl(i_status, '@') != nvl(l_flg_sr_proc, '@')
        THEN
            g_error := 'UPDATE SR_SURGERY_RECORD FOR ID_SURGERY_RECORD: ' || l_id_surgery_record || 'AND THE EPISODE: ' ||
                       i_episode;
            pk_alertlog.log_debug(g_error);
            ts_sr_surgery_record.upd(flg_sr_proc_in    => i_status,
                                     dt_flg_sr_proc_in => g_sysdate_tstz,
                                     where_in          => 'id_episode = ' || i_episode,
                                     rows_out          => l_rowsid);
        
            -- insert status into log table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            pk_alertlog.log_info(text            => 'Begin execution of:',
                                 object_name     => 'PK_SR_SURG_RECORD',
                                 sub_object_name => l_func_name);
        
            IF NOT t_ti_log.ins_log(i_lang,
                                    i_prof,
                                    i_episode,
                                    i_status,
                                    l_id_surgery_record,
                                    g_surgery_process_type,
                                    o_error)
            THEN
                RAISE excep;
            END IF;
        
            g_error := 'CALL PK_VISIT.PK_SR_FIRST_OBS';
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
                RAISE excep;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN excep_b THEN
            pk_alertlog.log_error(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            --pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_surg_process_status;

    /**************************************************************************
    * Returns the surgery estimated duration                                  *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_episode                    episode id                          *
    * @param i_duration                   estimated surgery duration          *
    * @param o_error                      Error message                       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Filipe Silva                            *
    * @version                        2.5.7.7.1                               *
    * @since                          2010/04/06                              *
    **************************************************************************/

    FUNCTION get_surg_est_dur
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN schedule_sr.id_episode%TYPE,
        i_duration IN schedule_sr.duration%TYPE
    ) RETURN VARCHAR IS
        l_duration schedule_sr.duration%TYPE;
        tbl_val    table_number;
        l_return   VARCHAR2(1000 CHAR);
    
        -- *********************************************
        FUNCTION calc_duration(i_duration IN NUMBER) RETURN VARCHAR2 IS
        BEGIN
        
            RETURN ltrim(to_char(trunc(i_duration / 60), '00') || ':' || ltrim(to_char(MOD(i_duration, 60), '00')) ||
                         pk_message.get_message(i_lang, 'HOURS_SIGN'));
        
        END calc_duration;
    
    BEGIN
    
        IF i_duration IS NOT NULL
        THEN
            l_duration := i_duration;
            RETURN calc_duration(i_duration => l_duration);
        ELSE
            SELECT duration
              BULK COLLECT
              INTO tbl_val
              FROM schedule_sr sr
             WHERE sr.id_episode = i_episode;
        
            IF tbl_val.count > 0
            THEN
                l_duration := tbl_val(1);
            END IF;
        
        END IF;
    
        l_return := '---';
        IF l_duration IS NOT NULL
        THEN
            l_return := calc_duration(i_duration => l_duration);
        END IF;
    
        RETURN l_return;
    
    END get_surg_est_dur;

    /********************************************************************************************
    * Get surgery time for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    * 
    * @param o_surgery_time_def Cursor with all type of surgery times.
    * @param o_surgery_times    Cursor with surgery times by visit.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Jorge Canossa
    * @since                    2010/10/24
       ********************************************************************************************/

    FUNCTION get_surgery_times_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_begin      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end        TIMESTAMP WITH LOCAL TIME ZONE;
        l_function_name VARCHAR2(30) := 'GET_SURGERY_TIMES_VISIT';
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.institution:' || i_prof.institution || ' i_prof.software:' ||
                   i_prof.software || ' i_prof.id:' || i_prof.id || ' i_id_visit:' || i_id_visit || ' i_dt_begin:' ||
                   i_dt_begin || ' i_dt_end:' || i_dt_end;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'GET DATES TSTZ';
        pk_alertlog.log_debug(g_error);
        l_dt_begin := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_begin, NULL);
        l_dt_end   := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_end, NULL);
    
        g_error := 'OPEN O_SURGERY_TIME_DEF';
        -- cmf
        pk_alertlog.log_debug(g_error);
        OPEN o_surgery_time_def FOR
            SELECT id_sr_surgery_time,
                   pk_translation.get_translation(i_lang, code_sr_surgery_time) AS description,
                   flg_type,
                   rank
              FROM sr_surgery_time
             WHERE id_software = pk_alert_constant.g_soft_oris
               AND id_institution IN (i_prof.id, 0)
               AND flg_available = pk_alert_constant.g_yes
             ORDER BY rank;
    
        g_error := 'OPEN O_SURGERY_TIMES';
        pk_alertlog.log_debug(g_error);
        OPEN o_surgery_times FOR
            SELECT e.id_episode,
                   sr.id_sr_surgery_time,
                   pk_translation.get_translation(i_lang, st.code_sr_surgery_time) AS description,
                   pk_date_utils.date_send_tsz(i_lang, sr.dt_surgery_time_det_tstz, i_prof.institution, i_prof.software) AS dt_surgery_time_det,
                   sr.flg_status,
                   pk_sysdomain.get_domain(g_sr_surgery_time_det_status, sr.flg_status, i_lang) AS flg_status_desc,
                   pk_sysdomain.get_img(i_lang, g_sr_surgery_time_det_status, sr.flg_status) AS icon
              FROM episode e
             INNER JOIN sr_surgery_time_det sr
                ON e.id_episode = sr.id_episode
             INNER JOIN sr_surgery_time st
                ON sr.id_sr_surgery_time = st.id_sr_surgery_time
              LEFT JOIN professional p
                ON p.id_professional = sr.id_professional
             WHERE sr.flg_status = pk_alert_constant.g_active
               AND e.id_visit = i_id_visit
               AND ((i_dt_begin IS NULL AND i_dt_end IS NULL) OR
                   (i_dt_begin IS NOT NULL AND i_dt_end IS NOT NULL AND sr.dt_surgery_time_det_tstz >= l_dt_begin AND
                   sr.dt_surgery_time_det_tstz <= l_dt_end));
    
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
            pk_types.open_my_cursor(o_surgery_time_def);
            pk_types.open_my_cursor(o_surgery_times);
            RETURN FALSE;
    END get_surgery_times_visit;

    /**
    * Get information (entries) about surgeries done to patient's family members 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_current_episode    Current episode ID
    * @param   i_patient            Patient ID
    * @param   i_order              Indicates the chronological order of records returned ('ASC' Ascending , 'DESC' Descending) Default 'DESC'
    *
    * @return  Information about entries (professional, record date, status, etc.)
    *
    * @author  ARIEL.MACHADO & FILIPE.SILVA
    * @version v2.6.0.4
    * @since   11/23/2010
    */
    FUNCTION tf_surgery_pat_family_reg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_current_episode IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_order           IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN pk_touch_option.t_coll_doc_area_register
        PIPELINED IS
        l_coll_register pk_touch_option.t_coll_doc_area_register;
        CURSOR c_register IS
            SELECT decode(i_order, 'DESC', 1, 'ASC', -1, 1) * (current_timestamp - data_record.surgical_date) order_by_default,
                   trunc(SYSDATE) order_default,
                   data_record.id_surgery_record id_epis_documentation,
                   NULL PARENT,
                   NULL id_doc_template,
                   NULL template_desc,
                   pk_date_utils.date_send_tsz(i_lang, data_record.surgical_date, i_prof) dt_creation,
                   data_record.surgical_date dt_creation_tstz,
                   pk_date_utils.date_char_tsz(i_lang, data_record.surgical_date, i_prof.institution, i_prof.software) dt_register,
                   data_record.prof_team_leader id_professional,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, data_record.prof_team_leader) nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    data_record.prof_team_leader,
                                                    data_record.surgical_date,
                                                    data_record.id_episode) desc_speciality,
                   pk_summary_page.g_doc_area_past_fam id_doc_area,
                   pk_alert_constant.g_active flg_status,
                   NULL desc_status,
                   data_record.id_episode,
                   decode(data_record.id_episode, i_current_episode, pk_alert_constant.g_yes, pk_alert_constant.g_no) flg_current_episode,
                   NULL notes,
                   pk_date_utils.date_send_tsz(i_lang, data_record.surgical_date, i_prof.institution, i_prof.software) dt_last_update,
                   data_record.surgical_date dt_last_update_tstz,
                   pk_alert_constant.g_no flg_detail,
                   pk_alert_constant.g_yes flg_external,
                   pk_summary_page.g_free_text flg_type_register,
                   pk_touch_option.g_flg_tab_origin_surg_record flg_table_origin,
                   NULL flg_reviewed,
                   NULL id_prof_cancel,
                   NULL dt_cancel_tstz,
                   NULL id_cancel_reason,
                   NULL cancel_reason,
                   NULL cancel_notes,
                   NULL flg_edition_type,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, data_record.prof_team_leader) nick_name_prof_create,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    data_record.prof_team_leader,
                                                    data_record.surgical_date,
                                                    data_record.id_episode) desc_speciality_prof_create,
                   NULL dt_clinical,
                   NULL dt_clinical_chr,
                   NULL signature
              FROM (SELECT ssr.id_surgery_record,
                           coalesce((SELECT dt_surgery_time_det_tstz
                                      FROM (SELECT sstd.dt_surgery_time_det_tstz,
                                                   sstd.id_episode,
                                                   rank() over(PARTITION BY sstd.id_episode ORDER BY sstd.dt_surgery_time_det_tstz DESC) rank_num
                                              FROM sr_surgery_time_det sstd
                                             WHERE sstd.id_sr_surgery_time IN (3, 4))
                                     WHERE rank_num = 1
                                       AND id_episode = ssr.id_episode
                                       AND rownum < 2),
                                    ss.dt_target_tstz,
                                    ss.dt_interv_preview_tstz) surgical_date,
                           ssr.id_episode,
                           (SELECT td.id_professional
                              FROM sr_prof_team_det td
                             WHERE td.id_episode_context = ssr.id_episode
                               AND td.id_professional = td.id_prof_team_leader
                               AND td.flg_status = pk_alert_constant.g_active
                               AND rownum < 2) prof_team_leader
                      FROM (SELECT pfm.id_pat_related
                              FROM pat_family_member pfm
                             INNER JOIN family_relationship fr
                                ON fr.id_family_relationship = pfm.id_family_relationship
                             WHERE pfm.id_patient = i_patient
                               AND pfm.flg_status = pk_alert_constant.g_active) pfam
                     INNER JOIN episode e
                        ON e.id_patient = pfam.id_pat_related
                     INNER JOIN sr_surgery_record ssr
                        ON e.id_episode = ssr.id_episode
                     INNER JOIN schedule_sr ss
                        ON ssr.id_schedule_sr = ss.id_schedule_sr
                     WHERE pk_sr_approval.get_status_surg_proc(i_lang, i_prof, e.id_episode) = pk_sr_approval.g_done) data_record
             ORDER BY order_by_default;
    
    BEGIN
        OPEN c_register;
        LOOP
            FETCH c_register BULK COLLECT
                INTO l_coll_register LIMIT 500;
            FOR i IN 1 .. l_coll_register.count
            LOOP
                PIPE ROW(l_coll_register(i));
            END LOOP;
            EXIT WHEN c_register%NOTFOUND;
        END LOOP;
        CLOSE c_register;
    
        RETURN;
    END tf_surgery_pat_family_reg;

    /**
    * Get information (entries values) about surgeries done to patient's family members 
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_patient            Patient ID
    *
    * @return  Information about data values saved in entries
    *
    * @author  ARIEL.MACHADO & FILIPE.SILVA
    * @version v2.6.0.4
    * @since   11/23/2010
    */
    FUNCTION tf_surgery_pat_family_val
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN pk_touch_option.t_coll_doc_area_val
        PIPELINED IS
        l_coll_val pk_touch_option.t_coll_doc_area_val;
        l_surgery  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'SUMMARY_M033');
        CURSOR c_val IS
            SELECT data_record.id_surgery_record id_epis_documentation,
                   NULL PARENT,
                   NULL id_documentation,
                   NULL id_doc_component,
                   NULL id_doc_element_crit,
                   pk_date_utils.date_send_tsz(i_lang, data_record.surgical_date, i_prof) dt_reg,
                   NULL desc_component,
                   NULL flg_type,
                   pk_sr_clinical_info.get_proposed_surgery(i_lang,
                                                            data_record.id_episode,
                                                            i_prof,
                                                            pk_alert_constant.g_no) || ' (' ||
                   data_record.desc_relationship || ', ' ||
                   pk_patient.get_pat_name(i_lang, i_prof, data_record.id_pat_related, data_record.id_episode) || ', ' ||
                   l_surgery || ', ' ||
                   pk_date_utils.dt_chr_tsz(i_lang, data_record.surgical_date, i_prof.institution, i_prof.software) || ')' desc_element,
                   NULL desc_element_view,
                   NULL VALUE,
                   NULL flg_type_element,
                   pk_summary_page.g_doc_area_past_fam id_doc_area,
                   NULL rank_component,
                   NULL rank_element,
                   NULL internal_name,
                   NULL desc_quantifier,
                   NULL desc_quantification,
                   NULL desc_qualification,
                   NULL display_format,
                   NULL separator,
                   pk_touch_option.g_flg_tab_origin_surg_record flg_table_origin,
                   NULL flg_status, --ALERT-65600
                   NULL value_id,
                   NULL signature
              FROM (SELECT ssr.id_surgery_record,
                           coalesce((SELECT dt_surgery_time_det_tstz
                                      FROM (SELECT sstd.dt_surgery_time_det_tstz,
                                                   sstd.id_episode,
                                                   rank() over(PARTITION BY sstd.id_episode ORDER BY sstd.dt_surgery_time_det_tstz DESC) rank_num
                                              FROM sr_surgery_time_det sstd
                                             WHERE sstd.id_sr_surgery_time IN (3, 4))
                                     WHERE rank_num = 1
                                       AND id_episode = ssr.id_episode
                                       AND rownum < 2),
                                    ss.dt_target_tstz,
                                    ss.dt_interv_preview_tstz) surgical_date,
                           ssr.id_episode,
                           (SELECT td.id_professional
                              FROM sr_prof_team_det td
                             WHERE td.id_episode_context = ssr.id_episode
                               AND td.id_professional = td.id_prof_team_leader
                               AND td.flg_status = pk_alert_constant.g_active
                               AND rownum < 2) prof_team_leader,
                           pfam.id_pat_related,
                           pfam.desc_relationship
                      FROM (SELECT pfm.id_pat_related,
                                   pk_translation.get_translation(i_lang, fr.code_family_relationship) desc_relationship
                              FROM pat_family_member pfm
                             INNER JOIN family_relationship fr
                                ON fr.id_family_relationship = pfm.id_family_relationship
                             WHERE pfm.id_patient = i_patient
                               AND pfm.flg_status = pk_alert_constant.g_active) pfam
                     INNER JOIN episode e
                        ON e.id_patient = pfam.id_pat_related
                     INNER JOIN sr_surgery_record ssr
                        ON e.id_episode = ssr.id_episode
                     INNER JOIN schedule_sr ss
                        ON ssr.id_schedule_sr = ss.id_schedule_sr
                     WHERE pk_sr_approval.get_status_surg_proc(i_lang, i_prof, e.id_episode) = pk_sr_approval.g_done --Surgery done 
                    ) data_record;
    BEGIN
        OPEN c_val;
        LOOP
            FETCH c_val BULK COLLECT
                INTO l_coll_val LIMIT 500;
            FOR i IN 1 .. l_coll_val.count
            LOOP
                PIPE ROW(l_coll_val(i));
            END LOOP;
            EXIT WHEN c_val%NOTFOUND;
        END LOOP;
        CLOSE c_val;
    
        RETURN;
    END tf_surgery_pat_family_val;

    /*******************************************************************************************************************************************
    * GET_SURGERY_TIME          Returns a surgery time of a given type
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE             Episode Identifier
    * @param I_FLG_TYPE               Surgery time type
    * @param O_DT_SURGERY_TIME        Surgery time
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.1
    * @since                          23-Mai-2011
    *******************************************************************************************************************************************/
    FUNCTION get_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_type        IN sr_surgery_time.flg_type%TYPE,
        o_dt_surgery_time OUT sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        tbl_time table_timestamp;
    BEGIN
        g_error := 'GET SURGERY TIME. i_id_episode: ' || i_id_episode || ' i_flg_type: ' || i_flg_type;
        pk_alertlog.log_debug(g_error);
        SELECT sstd.dt_surgery_time_det_tstz
          BULK COLLECT
          INTO tbl_time
          FROM sr_surgery_time_det sstd
          JOIN sr_surgery_time srt
            ON srt.id_sr_surgery_time = sstd.id_sr_surgery_time
         WHERE sstd.id_episode = i_id_episode
           AND srt.flg_type = i_flg_type
           AND sstd.flg_status = pk_alert_constant.g_active;
    
        IF tbl_time.count > 0
        THEN
            o_dt_surgery_time := tbl_time(1);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            o_dt_surgery_time := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SURGERY_TIME',
                                              o_error);
            RETURN FALSE;
    END get_surgery_time;

    /*******************************************************************************************************************************************
    * ins_surgery_time_cfg            insert configuration into config_table
    *
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_config              adequate id_config
    * @param i_inst_owner             inst_owner of id_config
    * @param i_id_sr_surgery_time     id_sr_surgery_time to onfigure ( will be id_record in CONFIG_TABLE )
    * @param i_rank                   sorting value
    * @param i_desc_sst               alternative description
    * @param i_flg_pat_status         Patient status that patient must assumed on SR_PAT_STATUS, when operative time for this category is filled.
    *
    * @raises                         generic error
    *
    * @author                         Sherlock
    * @version                        2.7.1
    * @since                          17-05-2017
    *******************************************************************************************************************************************/
    PROCEDURE ins_surgery_time_cfg
    (
        i_id_config          IN NUMBER,
        i_inst_owner         IN NUMBER DEFAULT 0,
        i_id_sr_surgery_time IN NUMBER,
        i_rank               IN NUMBER,
        i_desc_sst           IN VARCHAR2,
        i_flg_pat_status     IN VARCHAR2
    ) IS
        --k_func_name CONSTANT VARCHAR2(0050 CHAR) := 'INS_SURGERY_TIME_CFG';
    BEGIN
    
        -- obtain configuration
        IF i_id_config IS NOT NULL
        THEN
        
            pk_core_config.insert_into_config_table(i_config_table  => k_sr_time_cfg_table,
                                                    i_id_record     => i_id_sr_surgery_time,
                                                    i_id_config     => i_id_config,
                                                    i_id_inst_owner => i_inst_owner,
                                                    i_field_01      => i_rank,
                                                    i_field_02      => i_desc_sst,
                                                    i_field_03      => i_flg_pat_status);
        END IF;
    
    END ins_surgery_time_cfg;

    PROCEDURE ins_surgery_time
    (
        i_id_sr_surgery_time IN NUMBER,
        i_flg_type           IN VARCHAR2,
        i_flg_val_prev       IN VARCHAR2
    ) IS
        -- force record to this value. No other value can be create ( for legacy reason )
        k_id_software    CONSTANT NUMBER := 2;
        k_id_institution CONSTANT NUMBER := 0;
        xrow sr_surgery_time%ROWTYPE;
        k_code CONSTANT VARCHAR2(0200 CHAR) := 'SR_SURGERY_TIME.CODE_SR_SURGERY_TIME.';
        k_yes  CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    BEGIN
    
        IF i_id_sr_surgery_time IS NOT NULL
        THEN
        
            xrow.id_sr_surgery_time   := i_id_sr_surgery_time;
            xrow.code_sr_surgery_time := k_code || to_char(xrow.id_sr_surgery_time);
            xrow.id_software          := k_id_software;
            xrow.id_institution       := k_id_institution;
            xrow.flg_type             := i_flg_type;
            xrow.flg_available        := k_yes;
            xrow.rank                 := 0;
            xrow.flg_pat_status       := NULL;
            xrow.flg_val_prev         := i_flg_val_prev;
        
            INSERT INTO sr_surgery_time
                (id_sr_surgery_time,
                 code_sr_surgery_time,
                 id_software,
                 id_institution,
                 flg_type,
                 flg_available,
                 rank,
                 flg_pat_status,
                 flg_val_prev)
            VALUES
                (xrow.id_sr_surgery_time,
                 xrow.code_sr_surgery_time,
                 xrow.id_software,
                 xrow.id_institution,
                 xrow.flg_type,
                 xrow.flg_available,
                 xrow.rank,
                 xrow.flg_pat_status,
                 xrow.flg_val_prev);
        END IF;
    
    END ins_surgery_time;

    PROCEDURE upd_surgery_time
    (
        i_id_sr_surgery_time IN NUMBER,
        i_flg_type           IN VARCHAR2,
        i_flg_val_prev       IN VARCHAR2
    ) IS
    BEGIN
    
        UPDATE sr_surgery_time sst
           SET flg_type = i_flg_type, flg_val_prev = i_flg_val_prev
         WHERE sst.id_sr_surgery_time = i_id_sr_surgery_time;
    
    END upd_surgery_time;

    /*******************************************************************************************************************************************
    * ins_surgery_time                insert/update into sr_surgery_time
    *
    * @param i_id_sr_surgery_time     id given for record
    * @param i_flg_type               unique code. Works as identifier
    * @param i_flg_val_prev           Indicates if is necessary to fill the previous operative times. Values Y- Yes; N - No
    *
    * @raises                         generic error
    *
    * @author                         Sherlock
    * @version                        2.7.1
    * @since                          17-05-2017
    *******************************************************************************************************************************************/
    PROCEDURE set_surgery_time
    (
        i_id_sr_surgery_time IN NUMBER,
        i_flg_type           IN VARCHAR2,
        i_flg_val_prev       IN VARCHAR2
    ) IS
    
    BEGIN
    
        upd_surgery_time(i_id_sr_surgery_time => i_id_sr_surgery_time,
                         i_flg_type           => i_flg_type,
                         i_flg_val_prev       => i_flg_val_prev);
    
        IF SQL%ROWCOUNT = 0
        THEN
            ins_surgery_time(i_id_sr_surgery_time => i_id_sr_surgery_time,
                             i_flg_type           => i_flg_type,
                             i_flg_val_prev       => i_flg_val_prev);
        END IF;
    
    END set_surgery_time;

    /*******************************************************************************************************************************************
    * Insert surgery times...
    *
    * @author                         Alexis Nascimento
    * @version                        2.7.1
    * @since                          13-10-2017
    *******************************************************************************************************************************************/

    FUNCTION set_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_sr_surgery_time IN NUMBER,
        i_dt_surgery_time IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_show               VARCHAR2(10 CHAR);
        l_msg_result             VARCHAR2(1000 CHAR);
        l_title                  VARCHAR2(1000 CHAR);
        l_button                 VARCHAR2(1000 CHAR);
        l_flg_refresh            VARCHAR2(1000 CHAR);
        l_id_sr_surgery_time_det NUMBER(24);
    
        l_internal_error EXCEPTION;
    
    BEGIN
    
        IF NOT pk_sr_surg_record.set_surgery_time(i_lang                   => i_lang,
                                                  i_sr_surgery_time        => i_sr_surgery_time,
                                                  i_episode                => i_episode,
                                                  i_dt_surgery_time        => i_dt_surgery_time,
                                                  i_prof                   => i_prof,
                                                  i_test                   => 'N',
                                                  i_dt_reg                 => NULL,
                                                  o_flg_show               => l_flg_show,
                                                  o_msg_result             => l_msg_result,
                                                  o_title                  => l_title,
                                                  o_button                 => l_button,
                                                  o_flg_refresh            => l_flg_refresh,
                                                  o_id_sr_surgery_time_det => l_id_sr_surgery_time_det,
                                                  o_error                  => o_error)
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
                                              'SET_SURGERY_TIME',
                                              o_error);
            RETURN FALSE;
        
    END set_surgery_time;

    /*************************************************************************
    * Get all surgery time detail as string
    *
    * @param i_lang       language idenfier
    * @param i_prof       profesional idenfier
    * @param i_epis       episode idenfier
    *
    * @return VARCHAR2  return all surgery time detal as string
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    ************************************************************************/
    FUNCTION get_surgery_time_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_des     table_varchar;
        l_des_det VARCHAR2(2000 CHAR) := NULL;
        l_error   t_error_out;
    BEGIN
        g_error := 'CALL PR_SURG_RECORD.GET_SURGERY_TIME_DET';
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_translation.get_translation(i_lang, sst.code_sr_surgery_time) || g_colon ||
               pk_date_utils.date_char_tsz(i_lang, sstd.dt_surgery_time_det_tstz, i_prof.institution, i_prof.software) surgery_time
          BULK COLLECT
          INTO l_des
          FROM sr_surgery_time_det sstd
         INNER JOIN sr_surgery_time sst
            ON sst.id_sr_surgery_time = sstd.id_sr_surgery_time
         WHERE sstd.id_episode = i_episode;
    
        FOR i IN 1 .. l_des.count
        LOOP
            IF (i = l_des.count)
            THEN
                l_des_det := l_des_det || l_des(i);
            ELSE
                l_des_det := l_des_det || l_des(i) || g_new_line;
            END IF;
        END LOOP;
        l_des_det := l_des_det || g_new_line;
    
        RETURN l_des_det;
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
                                              'GET_SURGERY_TIME_DET',
                                              l_error);
            RETURN NULL;
    END get_surgery_time_det;

    /*************************************************************************
    * Get all surgery team detail
    *
    * @param i_lang       language idenfier
    * @param i_prof       profesional idenfier
    * @param i_episode       episode idenfier
    *
    * @return VARCHAR2  return all surgery member and prof category
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    ************************************************************************/
    FUNCTION get_sr_prof_team_det
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_det               VARCHAR2(2000 CHAR) := NULL;
        l_id_prof                table_number := table_number();
        l_prof_name              table_varchar := table_varchar();
        l_prof_category          table_varchar := table_varchar();
        l_id_sr_epis_interv      table_number := table_number();
        l_prof_team_name         table_varchar := table_varchar();
        l_last_id_sr_epis_interv NUMBER(24) := NULL;
    
        l_title_prof_name  VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'SURGERY_RECORD_M019',
                                                                       i_prof      => i_prof);
        l_title_role_name  VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'SURGERY_RECORD_M020',
                                                                       i_prof      => i_prof);
        l_title_team_staff VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'SURGERY_RECORD_M014',
                                                                       i_prof      => i_prof);
        l_error            t_error_out;
    BEGIN
        g_error := 'CALL PR_SURG_RECORD.GET_SR_PROF_TEAM_DET';
        pk_alertlog.log_debug(g_error);
    
        SELECT DISTINCT sptd.id_sr_epis_interv,
                        pt.prof_team_name,
                        p.name prof_name,
                        pk_translation.get_translation(i_lang,
                                                       'CATEGORY_SUB.CODE_CATEGORY_SUB.' || sptd.id_category_sub) prof_category
          BULK COLLECT
          INTO l_id_sr_epis_interv, l_prof_team_name, l_prof_name, l_prof_category
          FROM sr_prof_team_det sptd
         INNER JOIN sr_epis_interv sei
            ON sei.id_episode = sptd.id_episode
           AND sei.id_sr_epis_interv = sptd.id_sr_epis_interv
         INNER JOIN professional p
            ON p.id_professional = sptd.id_professional
          LEFT OUTER JOIN prof_team pt
            ON pt.id_prof_team = sptd.id_prof_team
         WHERE sptd.id_episode = i_episode
         ORDER BY sptd.id_sr_epis_interv;
    
        FOR i IN 1 .. l_prof_name.count
        LOOP
            IF (i = 1)
            THEN
                l_desc_det := l_desc_det || l_title_team_staff || g_new_line;
            END IF;
        
            IF (l_last_id_sr_epis_interv <> l_id_sr_epis_interv(i) AND i <> 1)
            THEN
                l_desc_det := l_desc_det || g_new_line;
            END IF;
        
            IF (i = l_prof_name.count)
            THEN
                l_desc_det := l_desc_det || l_title_prof_name || g_colon || l_prof_name(i) || g_new_line ||
                              l_title_role_name || g_colon || l_prof_category(i);
            ELSE
                l_desc_det := l_desc_det || l_title_prof_name || g_colon || l_prof_name(i) || g_new_line ||
                              l_title_role_name || g_colon || l_prof_category(i) || g_new_line;
            END IF;
        
            l_last_id_sr_epis_interv := l_id_sr_epis_interv(i);
        
        END LOOP;
    
        RETURN l_desc_det;
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
                                              'GET_SR_PROF_TIME_DET',
                                              l_error);
            RETURN NULL;
    END get_sr_prof_team_det;

    /********************************************************************************************
    * Get surgery record brief description
    *
    * @param i_lang                    language idenfier
    * @param i_prof                    profesional idenfier
    * @param i_episode                 episode idenfier
    * @param i_patient                 patient idenfier
    *
    * @return CLOB
    *
    * @author             Kelsey Lai
    * @version            2.7.2.6
    * @since              2018-02-23
    **********************************************************************************************/
    FUNCTION get_sr_brief_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_patient IN patient.id_patient%TYPE
    ) RETURN CLOB IS
        l_sr_interv_name  table_varchar;
        l_diagnosis_desc  table_varchar;
        l_wound_desc      VARCHAR2(100 CHAR);
        l_findings_desc   CLOB;
        l_int_wound       documentation.internal_name%TYPE := 'INT_WOUND';
        l_int_findings    documentation.internal_name%TYPE := 'INT_FIND';
        l_brief_sr_record CLOB;
        l_title           VARCHAR2(50 CHAR);
        l_error           t_error_out;
    BEGIN
        g_error := 'PK_SR_SURG_RECORD.GET_SR_BRIEF_DESC';
        --get intervention name
        BEGIN
            SELECT pk_translation.get_translation(i_lang, i.code_intervention) sr_interv_name
              BULK COLLECT
              INTO l_sr_interv_name
              FROM episode e
             INNER JOIN sr_epis_interv sei
                ON sei.id_episode = e.id_episode
             INNER JOIN intervention i
                ON i.id_intervention = sei.id_sr_intervention
             WHERE e.id_episode = i_episode
               AND e.flg_ehr = pk_visit.g_flg_ehr_n
               AND e.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND e.flg_status <> pk_alert_constant.g_cancelled
             ORDER BY sei.id_sr_epis_interv;
        EXCEPTION
            WHEN no_data_found THEN
                l_sr_interv_name := NULL;
        END;
    
        g_error := 'call pk_diagnosis.std_diag_desc';
        --get diagnosis description
        BEGIN
            SELECT pk_diagnosis.std_diag_desc(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_id_diagnosis        => d.id_diagnosis,
                                              i_code                => d.code_icd,
                                              i_flg_other           => d.flg_other,
                                              i_desc_epis_diagnosis => pk_translation.get_translation(i_lang,
                                                                                                      d.code_diagnosis),
                                              i_flg_std_diag        => pk_alert_constant.g_yes)
              BULK COLLECT
              INTO l_diagnosis_desc
              FROM episode e
             INNER JOIN schedule_sr ss
                ON ss.id_episode = e.id_episode
             INNER JOIN diagnosis d
                ON d.id_diagnosis = ss.id_diagnosis
             WHERE e.id_episode = i_episode
               AND e.flg_ehr = pk_visit.g_flg_ehr_n
               AND e.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND e.flg_status <> pk_alert_constant.g_cancelled;
        EXCEPTION
            WHEN no_data_found THEN
                l_diagnosis_desc := NULL;
        END;
    
        g_error := 'call pk_touch_option.get_template_value findings';
        --get finding and wound description
        l_findings_desc := pk_touch_option.get_template_value(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_episode         => i_episode,
                                                              i_doc_area        => pk_summary_page.g_doc_area_sur_record,
                                                              i_doc_int_name    => l_int_findings,
                                                              i_show_id_content => pk_alert_constant.g_no,
                                                              i_show_doc_title  => pk_alert_constant.g_no);
        g_error         := 'call pk_touch_option.get_template_value wound';
        l_wound_desc    := pk_touch_option.get_template_value(i_lang            => i_lang,
                                                              i_prof            => i_prof,
                                                              i_patient         => i_patient,
                                                              i_episode         => i_episode,
                                                              i_doc_area        => pk_summary_page.g_doc_area_sur_record,
                                                              i_doc_int_name    => l_int_wound,
                                                              i_show_id_content => pk_alert_constant.g_no,
                                                              i_show_doc_title  => pk_alert_constant.g_no);
        --associated Surgery name
        IF (l_sr_interv_name.count > 0)
        THEN
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M003', i_prof => i_prof);
        
            l_brief_sr_record := l_brief_sr_record || l_title || g_colon;
            FOR i IN 1 .. l_sr_interv_name.count
            LOOP
                IF (i <> l_sr_interv_name.count)
                THEN
                    l_brief_sr_record := l_brief_sr_record || l_sr_interv_name(i) || g_comma;
                ELSE
                    l_brief_sr_record := l_brief_sr_record || l_sr_interv_name(i) || g_new_line;
                END IF;
            END LOOP;
        END IF;
    
        --associated diagnosis
        IF (l_diagnosis_desc.count > 0)
        THEN
            l_title           := pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => 'SURGERY_RECORD_M008',
                                                        i_prof      => i_prof);
            l_brief_sr_record := l_brief_sr_record || l_title || g_colon;
            FOR i IN 1 .. l_diagnosis_desc.count
            LOOP
                IF (i <> l_diagnosis_desc.count)
                THEN
                    l_brief_sr_record := l_brief_sr_record || l_diagnosis_desc(i) || g_comma;
                ELSE
                    l_brief_sr_record := l_brief_sr_record || l_diagnosis_desc(i) || g_new_line;
                END IF;
            END LOOP;
        END IF;
    
        -- associated surgical wound classifications and finding
        IF (l_wound_desc IS NOT NULL)
        THEN
            l_title           := pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => 'SURGERY_RECORD_M011',
                                                        i_prof      => i_prof);
            l_brief_sr_record := l_brief_sr_record || l_title || g_colon || l_wound_desc || g_new_line;
        END IF;
        IF (l_findings_desc IS NOT NULL)
        THEN
            l_title           := pk_message.get_message(i_lang      => i_lang,
                                                        i_code_mess => 'SURGERY_RECORD_M010',
                                                        i_prof      => i_prof);
            l_brief_sr_record := l_brief_sr_record || l_title || g_colon || l_findings_desc || g_new_line;
        END IF;
    
        RETURN l_brief_sr_record;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SR_BRIEF_DESC',
                                              l_error);
            RETURN NULL;
    END get_sr_brief_desc;

    /********************************************************************************************
    * Get surgery record brief description as cursor
    *
    * @param i_lang                    language idenfier
    * @param i_prof                    profesional idenfier
    * @param i_epis                    episode idenfier
    * @param o_brief_surgery_record    all surgery record
    * @param o_error                   t_error_out type error
    *
    * @return cursor_type
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-12-15
    **********************************************************************************************/
    FUNCTION get_sr_brief_det
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_epis                 IN table_number,
        i_patient              IN patient.id_patient%TYPE,
        o_brief_surgery_record OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'pk_sr_surg_record.get_sr_brief_det';
        OPEN o_brief_surgery_record FOR
            SELECT pk_sr_surg_record.get_sr_brief_desc(i_lang    => i_lang,
                                                       i_prof    => i_prof,
                                                       i_episode => e.id_episode,
                                                       i_patient => i_patient) sr_record,
                   e.id_episode id_episode
              FROM episode e
             WHERE e.id_episode IN (SELECT /*+opt_estimate (table t, scale_rows=1)*/
                                     column_value
                                      FROM TABLE(i_epis) t)
               AND e.id_epis_type = pk_alert_constant.g_epis_type_operating
               AND e.flg_status <> pk_alert_constant.g_cancelled;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_brief_surgery_record);
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_SR_BRIEF_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_sr_brief_det;

    /********************************************************************************************
    * Get all surgery record as cursor
    *
    * @param i_lang             language idenfier
    * @param i_prof             profesional idenfier
    * @param i_epis             episode idenfier
    * @param o_surgery_record   all surgery record
    * @param o_error            t_error_out type error
    *
    * @return cursor_type
    *
    * @author             Kelsey Lai
    * @version            2.7.2.0
    * @since              2017-11-15
    **********************************************************************************************/
    FUNCTION get_surgery_record_det
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_epis           IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        o_surgery_record OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sur_desc_info    table_varchar := table_varchar();
        l_id_episode       table_number := table_number();
        l_flg_type         table_varchar := table_varchar();
        l_flg_sched        table_varchar := table_varchar();
        l_duration         table_varchar := table_varchar();
        l_room             table_varchar := table_varchar();
        l_surgery_timd_det table_varchar := table_varchar();
        l_sr_req_prof_name table_varchar := table_varchar();
        l_sr_sch_prof_name table_varchar := table_varchar();
        l_prof_team_det    table_varchar := table_varchar();
        l_prof_team_name   table_varchar := table_varchar();
        l_signature        table_varchar := table_varchar();
        l_title            VARCHAR2(50 CHAR);
        l_unit_measure_min CONSTANT unit_measure.id_unit_measure%TYPE := 7712;
        l_minute  VARCHAR2(50 CHAR);
        l_display BOOLEAN := FALSE;
    BEGIN
        g_error := 'CALL PR_SURG_RECORD.GET_SURGERY_RECORD_DET';
        pk_alertlog.log_debug(g_error);
    
        SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
          INTO l_minute
          FROM unit_measure um
         WHERE um.id_unit_measure = l_unit_measure_min;
    
        SELECT e.id_episode,
               CASE
                    WHEN sei.flg_type = pk_sr_planning.g_epis_interv_type_p THEN
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M001', i_prof => i_prof)
                    WHEN sei.flg_type = pk_sr_planning.g_epis_interv_type_s THEN
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M002', i_prof => i_prof)
                END flg_type,
               CASE
                    WHEN ss.flg_status = pk_schedule_oris.g_notscheduled THEN
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M017', i_prof => i_prof)
                    WHEN ss.flg_status = pk_schedule_oris.g_scheduled THEN
                     pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M018', i_prof => i_prof)
                END flg_sched,
               ss.duration duration,
               pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || s.id_room) room,
               pk_sr_surg_record.get_surgery_time_det(i_lang => i_lang, i_prof => i_prof, i_episode => e.id_episode) surgery_timd_det,
               pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => sei.id_prof_req) req_prof_name,
               pk_prof_utils.get_name(i_lang => i_lang, i_prof_id => s.id_prof_schedules) sr_sch_prof_name,
               pk_sr_surg_record.get_sr_prof_team_det(i_lang => i_lang, i_prof => i_prof, i_episode => e.id_episode) prof_team_det,
               
               (SELECT DISTINCT pt.prof_team_name
                  FROM sr_prof_team_det sptd
                 INNER JOIN sr_epis_interv sei2
                    ON sei2.id_episode = sptd.id_episode
                   AND sei2.id_sr_epis_interv = sptd.id_sr_epis_interv
                  LEFT OUTER JOIN prof_team pt
                    ON pt.id_prof_team = sptd.id_prof_team
                 WHERE sptd.id_episode = e.id_episode
                   AND sptd.id_sr_epis_interv = sei.id_sr_epis_interv
                   AND sptd.flg_status = pk_alert_constant.g_active) prof_team_name,
               pk_prof_utils.get_detail_signature(i_lang, i_prof, sei.id_episode, sei.dt_req_tstz, sei.id_prof_req) signature
        
          BULK COLLECT
          INTO l_id_episode,
               l_flg_type,
               l_flg_sched,
               l_duration,
               l_room,
               l_surgery_timd_det,
               l_sr_req_prof_name,
               l_sr_sch_prof_name,
               l_prof_team_det,
               l_prof_team_name,
               l_signature
          FROM episode e
         INNER JOIN sr_epis_interv sei
            ON sei.id_episode = e.id_episode
          LEFT OUTER JOIN schedule_sr ss
            ON ss.id_episode = e.id_episode
           AND ss.id_patient = i_patient
          LEFT OUTER JOIN schedule s
            ON s.id_schedule = ss.id_schedule
         WHERE e.id_episode = i_epis
           AND e.flg_ehr = pk_visit.g_flg_ehr_n
           AND e.id_epis_type = pk_alert_constant.g_epis_type_operating
           AND e.flg_status <> pk_alert_constant.g_cancelled
         ORDER BY sei.id_sr_epis_interv;
    
        --if no data just retrun
        IF (l_id_episode.count <= 0)
        THEN
            RETURN TRUE;
        END IF;
    
        -- Surgery type
        -- Check value, if has no data, don't display
        FOR i IN 1 .. l_flg_type.count
        LOOP
            IF (l_flg_type(i) IS NOT NULL)
            THEN
                l_display := TRUE;
            END IF;
        END LOOP;
    
        IF (l_display = TRUE)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M004', i_prof => i_prof);
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon;
        
            FOR j IN 1 .. l_flg_type.count
            LOOP
                IF (j <> l_flg_type.count)
                THEN
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) || l_flg_type(j) ||
                                                              g_comma;
                ELSE
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) || l_flg_type(j);
                END IF;
            END LOOP;
        END IF;
        l_display := FALSE;
    
        -- Schedule type
        IF (l_flg_sched(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M005', i_prof => i_prof);
        
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon || l_flg_sched(1);
        
        END IF;
    
        -- Duration
        IF (l_duration(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M006', i_prof => i_prof);
        
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon || ltrim(to_char(l_duration(1), '9999999')) || ' ' ||
                                                      l_minute;
        
        END IF;
        -- Room
        IF (l_room(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M007', i_prof => i_prof);
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon || l_room(1);
        
        END IF;
    
        -- Surgery team name
        FOR i IN 1 .. l_prof_team_name.count
        LOOP
            IF (l_prof_team_name(i) IS NOT NULL)
            THEN
                l_display := TRUE;
            END IF;
        END LOOP;
    
        IF (l_display = TRUE)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M015', i_prof => i_prof);
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon;
            FOR j IN 1 .. l_prof_team_name.count
            LOOP
                IF (j <> l_prof_team_name.count)
                THEN
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) ||
                                                              l_prof_team_name(j) || g_comma;
                ELSE
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) ||
                                                              l_prof_team_name(j);
                END IF;
            END LOOP;
        END IF;
        l_display := FALSE;
    
        -- Surgery time detail
        IF (l_surgery_timd_det(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M009', i_prof => i_prof);
            l_sur_desc_info(l_sur_desc_info.count) := l_title;
            l_sur_desc_info.extend(1);
        
            l_sur_desc_info(l_sur_desc_info.count) := l_surgery_timd_det(1);
        
        END IF;
    
        -- Request professional name
        FOR i IN 1 .. l_sr_req_prof_name.count
        LOOP
            IF (l_sr_req_prof_name(i) IS NOT NULL)
            THEN
                l_display := TRUE;
            END IF;
        END LOOP;
    
        IF (l_display = TRUE)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M012', i_prof => i_prof);
        
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon;
        
            FOR j IN 1 .. l_sr_req_prof_name.count
            LOOP
                IF (j <> l_sr_req_prof_name.count)
                THEN
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) ||
                                                              l_sr_req_prof_name(j) || g_comma;
                ELSE
                    l_sur_desc_info(l_sur_desc_info.count) := l_sur_desc_info(l_sur_desc_info.count) ||
                                                              l_sr_req_prof_name(j);
                END IF;
            END LOOP;
        END IF;
        l_display := FALSE;
    
        -- Schedule professional name
        IF (l_sr_sch_prof_name(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'SURGERY_RECORD_M013', i_prof => i_prof);
            l_sur_desc_info(l_sur_desc_info.count) := l_title || g_colon || l_sr_sch_prof_name(1);
        
        END IF;
    
        -- Surgery team member and prof category
        IF (l_prof_team_det(1) IS NOT NULL)
        THEN
            l_sur_desc_info.extend(1);
            l_title := ' ';
            l_sur_desc_info(l_sur_desc_info.count) := l_title;
            l_sur_desc_info.extend(1);
            l_sur_desc_info(l_sur_desc_info.count) := l_prof_team_det(1);
        END IF;
    
        IF (l_sur_desc_info.count > 0)
        THEN
            OPEN o_surgery_record FOR
                SELECT /*+opt_estimate (table t, scale_rows=1)*/
                 t.column_value desc_info
                  FROM TABLE(l_sur_desc_info) t;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                pk_types.open_my_cursor(o_surgery_record);
                -- setting language, setting error content into input object, setting package information
                l_error_in.set_all(i_lang,
                                   SQLCODE,
                                   SQLERRM,
                                   g_error,
                                   g_package_owner,
                                   g_package_name,
                                   'GET_SURGERY_RECORD_DET');
                l_ret := pk_alert_exceptions.process_error(l_error_in, o_error);
                RETURN FALSE;
            END;
    END get_surgery_record_det;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_sr_surg_record;
/