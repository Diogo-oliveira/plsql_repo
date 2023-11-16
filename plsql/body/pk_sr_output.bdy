/*-- Last Change Revision: $Rev: 2027734 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:08 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_output AS

    g_exception EXCEPTION;

    /********************************************************************************************
    * Insere descrições da intervenção para um episódio.
    *
    * @param i_lang                    Id do idioma
    * @param i_sr_epis_interv_desc     Descrição a inserir
    *
    * @param o_error                   Mensagem de erro
    *
    * @return                          TRUE/FALSE
    *
    * @author                          Rui Batista
    * @since                           2005/10/26
       ********************************************************************************************/

    FUNCTION insert_interv_description
    (
        i_lang                IN language.id_language%TYPE,
        i_sr_epis_interv_desc IN sr_epis_interv_desc%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'INSERT SR_EPIS_INTERV_DESC';
        pk_alertlog.log_debug(g_error);
        INSERT INTO sr_epis_interv_desc
            (id_sr_epis_interv_desc,
             desc_interv,
             id_episode,
             id_sr_intervention,
             flg_status,
             dt_interv_desc_tstz,
             id_professional,
             flg_type)
        VALUES
            (seq_sr_epis_interv_desc.nextval,
             i_sr_epis_interv_desc.desc_interv,
             i_sr_epis_interv_desc.id_episode,
             i_sr_epis_interv_desc.id_sr_intervention,
             i_sr_epis_interv_desc.flg_status,
             i_sr_epis_interv_desc.dt_interv_desc_tstz,
             i_sr_epis_interv_desc.id_professional,
             i_sr_epis_interv_desc.flg_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_INTERV_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END insert_interv_description;

    /********************************************************************************************
    * Cancela descrições da intervenção para um episódio
    *
    * @param i_lang                     Id do idioma
    * @param i_sr_epis_interv_desc      Id do registo a cancelar
    *
    * @param o_error                    Mensagem de erro
    *
    * @return                           TRUE/FALSE
    *
    * @author                           Rui Batista
    * @since                            2005/10/26
       ********************************************************************************************/

    FUNCTION cancel_interv_description
    (
        i_lang                IN language.id_language%TYPE,
        i_sr_epis_interv_desc IN sr_epis_interv_desc%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'UPDATE SR_EPIS_INTERV_DESC';
        pk_alertlog.log_debug(g_error);
        UPDATE sr_epis_interv_desc
           SET flg_status     = i_sr_epis_interv_desc.flg_status,
               dt_cancel_tstz = i_sr_epis_interv_desc.dt_cancel_tstz,
               id_prof_cancel = i_sr_epis_interv_desc.id_prof_cancel
         WHERE id_sr_epis_interv_desc = i_sr_epis_interv_desc.id_sr_epis_interv_desc;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_INTERV_DESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END cancel_interv_description;

    /********************************************************************************************
    * Insere um registo de notas na tabela SR_EPIS_INTERV_NOTES
    *
    * @param i_lang              Id do idioma
    * @param I_EPIS_INTERV_DESC  Dados do novo registo
    *
    * @param o_id_sr_epis_interv_desc    Created record ID
    * @param o_error             Mensagem de erro
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Rui Batista
    * @since                     2006/03/14
       ********************************************************************************************/

    FUNCTION insert_sr_epis_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis_interv_desc       IN sr_epis_interv_desc%ROWTYPE,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        SELECT seq_sr_epis_interv_desc.nextval
          INTO o_id_sr_epis_interv_desc
          FROM dual;
    
        g_error := 'INSERT SR_EPIS_INTERV_DESC FOR ID_SR_EPIS_INTERV_DESC ' || o_id_sr_epis_interv_desc;
        pk_alertlog.log_debug(g_error);
        --Insere notas
        INSERT INTO sr_epis_interv_desc
            (id_sr_epis_interv_desc,
             desc_interv,
             id_episode,
             id_sr_intervention,
             flg_status,
             dt_interv_desc_tstz,
             id_professional,
             flg_type,
             id_episode_context,
             id_sr_epis_interv)
        VALUES
            (o_id_sr_epis_interv_desc,
             i_epis_interv_desc.desc_interv,
             i_epis_interv_desc.id_episode,
             i_epis_interv_desc.id_sr_intervention,
             i_epis_interv_desc.flg_status,
             i_epis_interv_desc.dt_interv_desc_tstz,
             i_epis_interv_desc.id_professional,
             i_epis_interv_desc.flg_type,
             i_epis_interv_desc.id_episode_context,
             i_epis_interv_desc.id_sr_epis_interv);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_EPIS_INTERV_DESC',
                                              o_error);
            RETURN FALSE;
    END insert_sr_epis_interv_desc;

    /********************************************************************************************
    * Actualiza o estado de uma reserva na tabela SR_RESERV_REQ
    *
    * @param i_lang        Id do idioma
    * @param i_reserv_req  Registo a actualizar
    * @param i_prof        Id do profissional, institutição e software
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/03/14
       ********************************************************************************************/

    FUNCTION update_sr_reserv_req_status
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Actualiza registo
        g_error := 'UPDATE SR_RESERV_REQ for id_sr_reserv_req: ' || i_reserv_req.id_sr_reserv_req;
        pk_alertlog.log_debug(g_error);
        UPDATE sr_reserv_req
           SET flg_status   = nvl(i_reserv_req.flg_status, flg_status),
               id_prof_exec = i_reserv_req.id_prof_exec,
               dt_exec_tstz = i_reserv_req.dt_exec_tstz
         WHERE id_sr_reserv_req = i_reserv_req.id_sr_reserv_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_SR_RESERV_REQ_STATUS',
                                              o_error);
            RETURN FALSE;
    END update_sr_reserv_req_status;

    /********************************************************************************************
    * Insere uma reserva na tabela SR_RESERV_REQ
    *
    * @param i_lang        Id do idioma
    * @param i_reserv_req  Dados do novo registo
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/03/16
       ********************************************************************************************/

    FUNCTION insert_sr_reserv_req
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Insere notas
        g_error := 'INSERT SR_RESERV_REQ';
        pk_alertlog.log_debug(g_error);
        INSERT INTO sr_reserv_req
            (id_sr_reserv_req,
             id_surg_period,
             id_sr_equip,
             id_episode,
             id_sr_intervention,
             flg_status,
             qty_req,
             dt_req_tstz,
             id_prof_req,
             id_protocols,
             flg_type,
             id_episode_context)
        VALUES
            (i_reserv_req.id_sr_reserv_req,
             i_reserv_req.id_surg_period,
             i_reserv_req.id_sr_equip,
             i_reserv_req.id_episode,
             i_reserv_req.id_sr_intervention,
             i_reserv_req.flg_status,
             i_reserv_req.qty_req,
             i_reserv_req.dt_req_tstz,
             i_reserv_req.id_prof_req,
             i_reserv_req.id_protocols,
             i_reserv_req.flg_type,
             i_reserv_req.id_episode_context);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'INSERT_SR_RESERV_REQ',
                                              o_error);
            RETURN FALSE;
    END insert_sr_reserv_req;

    /********************************************************************************************
    * Cancela uma reserva na tabela SR_RESERV_REQ
    *
    * @param i_lang        Id do idioma
    * @param i_reserv_req  Registo a cancelar
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/03/16
       ********************************************************************************************/

    FUNCTION cancel_sr_reserv_req
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        --Actualiza registo
        g_error := 'UPDATE SR_RESERV_REQ FOR ID_SR_RESERV_REQ: ' || i_reserv_req.id_sr_reserv_req;
        pk_alertlog.log_debug(g_error);
        UPDATE sr_reserv_req
           SET flg_status     = i_reserv_req.flg_status,
               id_prof_cancel = i_reserv_req.id_prof_cancel,
               dt_cancel_tstz = i_reserv_req.dt_cancel_tstz,
               notes_cancel   = i_reserv_req.notes_cancel
         WHERE id_sr_reserv_req = i_reserv_req.id_sr_reserv_req;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'CANCEL_SR_RESERV_REQ',
                                              o_error);
            RETURN FALSE;
    END cancel_sr_reserv_req;

    /********************************************************************************************
    * Insere um registo na tabela SR_EPIS_INTERV
    *
    * @param i_lang             Id do idioma
    * @param i_sr_epis_interv   Dados do novo registo
    *
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/04/24
       ********************************************************************************************/

    FUNCTION insert_sr_epis_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv%ROWTYPE,
        i_id_ct_io       IN table_varchar DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_interv_start        sr_epis_interv.dt_interv_start_tstz%TYPE := NULL;
        l_dt_interv_end          sr_epis_interv.dt_interv_end_tstz%TYPE := NULL;
        l_rows                   table_varchar;
        l_id_sr_epis_interv_hist sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
        l_rowids                 table_varchar;
    
    BEGIN
    
        IF i_sr_epis_interv.dt_interv_start_tstz IS NULL
        THEN
            g_error := 'CALL pk_sr_surg_record.get_surgery_time start date: ' || i_sr_epis_interv.id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_surg_record.get_surgery_time(i_lang            => i_lang,
                                                      i_prof            => NULL,
                                                      i_id_episode      => i_sr_epis_interv.id_episode,
                                                      i_flg_type        => pk_sr_surg_record.g_type_surg_begin,
                                                      o_dt_surgery_time => l_dt_interv_start,
                                                      o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_dt_interv_start := i_sr_epis_interv.dt_interv_start_tstz;
        
        END IF;
    
        IF (i_sr_epis_interv.dt_interv_end_tstz IS NULL)
        THEN
            g_error := 'CALL pk_sr_surg_record.get_surgery_time end date: ' || i_sr_epis_interv.id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_sr_surg_record.get_surgery_time(i_lang            => i_lang,
                                                      i_prof            => NULL,
                                                      i_id_episode      => i_sr_epis_interv.id_episode,
                                                      i_flg_type        => pk_sr_surg_record.g_type_surg_end,
                                                      o_dt_surgery_time => l_dt_interv_end,
                                                      o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            l_dt_interv_end := i_sr_epis_interv.dt_interv_end_tstz;
        END IF;
    
        --Insere registo na tabela SR_EPIS_INTERV
        g_error := 'INSERT SR_EPIS_INTERV FOR ID_SR_EPIS_INTERV: ' || i_sr_epis_interv.id_sr_epis_interv;
        pk_alertlog.log_debug(g_error);
        ts_sr_epis_interv.ins(id_sr_epis_interv_in      => i_sr_epis_interv.id_sr_epis_interv,
                              id_episode_in             => i_sr_epis_interv.id_episode,
                              id_sr_intervention_in     => i_sr_epis_interv.id_sr_intervention,
                              dt_req_tstz_in            => i_sr_epis_interv.dt_req_tstz,
                              id_prof_req_in            => i_sr_epis_interv.id_prof_req,
                              flg_type_in               => i_sr_epis_interv.flg_type,
                              flg_status_in             => i_sr_epis_interv.flg_status,
                              id_episode_context_in     => i_sr_epis_interv.id_episode_context,
                              name_interv_in            => i_sr_epis_interv.name_interv,
                              id_prof_req_unc_in        => i_sr_epis_interv.id_prof_req_unc,
                              dt_req_unc_tstz_in        => i_sr_epis_interv.dt_req_unc_tstz,
                              flg_code_type_in          => i_sr_epis_interv.flg_code_type,
                              laterality_in             => i_sr_epis_interv.laterality,
                              surgical_site_in          => i_sr_epis_interv.surgical_site,
                              flg_surg_request_in       => i_sr_epis_interv.flg_surg_request,
                              id_epis_diagnosis_in      => i_sr_epis_interv.id_epis_diagnosis,
                              notes_in                  => i_sr_epis_interv.notes,
                              dt_interv_start_tstz_in   => l_dt_interv_start,
                              dt_interv_end_tstz_in     => l_dt_interv_end,
                              id_cdr_call_in            => i_sr_epis_interv.id_cdr_call,
                              id_not_order_reason_in    => i_sr_epis_interv.id_not_order_reason,
                              id_interv_codification_in => i_sr_epis_interv.id_interv_codification,
                              rows_out                  => l_rowids);
    
        g_error := 'call t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_EPIS_INTERV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        g_error := 'call set_ia_event_prescription';
        IF NOT set_ia_event_prescription(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_flg_action        => 'I',
                                         i_id_sr_epis_interv => i_sr_epis_interv.id_sr_epis_interv,
                                         i_flg_status_new    => i_sr_epis_interv.flg_status,
                                         i_flg_status_old    => NULL,
                                         o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        ts_sr_epis_interv_hist.ins(id_sr_epis_interv_in       => i_sr_epis_interv.id_sr_epis_interv,
                                   id_episode_in              => i_sr_epis_interv.id_episode,
                                   flg_status_hist_in         => 'A',
                                   id_sr_intervention_in      => i_sr_epis_interv.id_sr_intervention,
                                   dt_req_tstz_in             => i_sr_epis_interv.dt_req_tstz,
                                   id_prof_req_in             => i_sr_epis_interv.id_prof_req,
                                   flg_type_in                => i_sr_epis_interv.flg_type,
                                   flg_status_in              => i_sr_epis_interv.flg_status,
                                   id_episode_context_in      => i_sr_epis_interv.id_episode_context,
                                   name_interv_in             => i_sr_epis_interv.name_interv,
                                   id_prof_req_unc_in         => i_sr_epis_interv.id_prof_req_unc,
                                   dt_req_unc_tstz_in         => i_sr_epis_interv.dt_req_unc_tstz,
                                   flg_code_type_in           => i_sr_epis_interv.flg_code_type,
                                   laterality_in              => i_sr_epis_interv.laterality,
                                   surgical_site_in           => i_sr_epis_interv.surgical_site,
                                   flg_surg_request_in        => i_sr_epis_interv.flg_surg_request,
                                   id_epis_diagnosis_in       => i_sr_epis_interv.id_epis_diagnosis,
                                   notes_in                   => i_sr_epis_interv.notes,
                                   dt_interv_start_tstz_in    => l_dt_interv_start,
                                   dt_interv_end_tstz_in      => l_dt_interv_end,
                                   notes_cancel_in            => i_sr_epis_interv.notes_cancel,
                                   id_prof_cancel_in          => i_sr_epis_interv.id_prof_cancel,
                                   id_sr_cancel_reason_in     => i_sr_epis_interv.id_sr_cancel_reason,
                                   dt_cancel_tstz_in          => i_sr_epis_interv.dt_cancel_tstz,
                                   id_sr_epis_interv_hist_out => l_id_sr_epis_interv_hist,
                                   id_not_order_reason_in     => i_sr_epis_interv.id_not_order_reason,
                                   id_interv_codification_in  => i_sr_epis_interv.id_interv_codification,
                                   rows_out                   => l_rows);
    
        g_error := 'call insert_sr_epis_interv_mod_fact';
        IF NOT insert_sr_epis_interv_mod_fact(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_sr_epis_interv_hist => l_id_sr_epis_interv_hist,
                                              i_id_ct_io               => i_id_ct_io,
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
                                              'INSERT_SR_EPIS_INTERV',
                                              o_error);
            RETURN FALSE;
    END insert_sr_epis_interv;

    /********************************************************************************************
    * Actualiza ou cancela um registo na tabela SR_EPIS_INTERV
    *
    * @param i_lang           Id do idioma
    * @param i_sr_epis_interv Dados do registo a actualizar
    *
    * @param o_error          Mensagem de erro
    *
    * @return                 TRUE/FALSE
    *
    * @author                 Rui Batista
    * @since                  2006/04/24
       ********************************************************************************************/

    FUNCTION update_sr_epis_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv%ROWTYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids         table_varchar;
        l_flg_status_old sr_epis_interv.flg_status%TYPE;
    BEGIN
        g_error := 'get l_flg_status_old';
        BEGIN
            SELECT sei.flg_status
              INTO l_flg_status_old
              FROM sr_epis_interv sei
             WHERE sei.id_sr_epis_interv = i_sr_epis_interv.id_sr_epis_interv;
        EXCEPTION
            WHEN dup_val_on_index THEN
                l_flg_status_old := NULL;
        END;
    
        g_error := 'call ts_sr_epis_interv.upd FOR ID_SR_EPIS_INTERV: ' || i_sr_epis_interv.id_sr_epis_interv;
        pk_alertlog.log_debug(g_error);
        ts_sr_epis_interv.upd(flg_status_in          => i_sr_epis_interv.flg_status,
                              dt_cancel_tstz_in      => i_sr_epis_interv.dt_cancel_tstz,
                              notes_cancel_in        => i_sr_epis_interv.notes_cancel,
                              id_prof_cancel_in      => i_sr_epis_interv.id_prof_cancel,
                              id_sr_cancel_reason_in => i_sr_epis_interv.id_sr_cancel_reason,
                              id_cdr_call_in         => i_sr_epis_interv.id_cdr_call,
                              where_in               => 'id_sr_epis_interv = ' || i_sr_epis_interv.id_sr_epis_interv,
                              rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_EPIS_INTERV',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF NOT set_ia_event_prescription(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_flg_action        => 'U',
                                         i_id_sr_epis_interv => i_sr_epis_interv.id_sr_epis_interv,
                                         i_flg_status_new    => i_sr_epis_interv.flg_status,
                                         i_flg_status_old    => l_flg_status_old,
                                         o_error             => o_error)
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
                                              'UPDATE_SR_EPIS_INTERV',
                                              o_error);
            RETURN FALSE;
    END update_sr_epis_interv;

    /********************************************************************************************
    * Actualiza a data da última interacção do utilizador num episódio (utilizado no ADW)
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Id do episódio
    * @param i_dt_last     Data da última alteração
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/10/04
       ********************************************************************************************/
    FUNCTION update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt_last IN DATE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'call c_update_dt_last_interaction for id_episode: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT c_update_dt_last_interaction(i_lang    => i_lang,
                                            i_episode => i_episode,
                                            i_dt_last => i_dt_last,
                                            o_error   => o_error)
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
                                              'UPDATE_DT_LAST_INTERACTION',
                                              o_error);
        
            RETURN FALSE;
    END update_dt_last_interaction;

    FUNCTION c_update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt_last IN DATE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rowsin table_varchar;
    
    BEGIN
    
        --Actualiza EPIS_TASK com a data da última iteração do utilizador neste episódio
        g_error := 'UPDATE EPIS_INFO FOR ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(g_error);
        ts_epis_info.upd(id_episode_in               => i_episode,
                         dt_last_interaction_tstz_in => to_timestamp_tz(to_char(i_dt_last, 'yyyymmdd hh24miss') ||
                                                                        ' Europe/Lisbon',
                                                                        'yyyymmdd hh24miss TZR'),
                         rows_out                    => l_rowsin);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'C_UPDATE_DT_LAST_INTERACTION',
                                              o_error);
        
            RETURN FALSE;
    END c_update_dt_last_interaction;

    /********************************************************************************************
    * Actualiza a data da última interacção do utilizador num episódio (utilizado no ADW)
    *
    * @param i_lang        Id do idioma
    * @param i_episode     Dados do novo registo
    * @param i_prof        ID do profissional, instituição e software
    * @param i_dt_last     Data da última alteração
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/10/04
       ********************************************************************************************/

    FUNCTION update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_dt_last IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_dt_last TIMESTAMP WITH LOCAL TIME ZONE;
        l_rowsid  table_varchar;
    
    BEGIN
    
        l_dt_last := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_last, NULL);
    
        --Actualiza EPIS_TASK com a data da última iteração do utilizador neste episódio
        g_error := 'UPDATE EPIS_INFO';
        pk_alertlog.log_debug(g_error);
        ts_epis_info.upd(id_episode_in => i_episode, dt_last_interaction_tstz_in => l_dt_last, rows_out => l_rowsid);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'UPDATE_DT_LAST_INTERACTION',
                                              o_error);
        
            RETURN FALSE;
    END update_dt_last_interaction;

    /********************************************************************************************
    * Actualiza o estado do paciente devido a requisição/início de transportes
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Dados do novo registo
    * @param i_episode     ID do episódio
    * @param i_room        ID da sala de destino do transporte
    * @param i_dt_mov_str  Data da requisição/início do transporte
    * @param i_action      Indica que tipo de acção se trata. Valores possíveis:
    *                          R- Requisição de transporte
    *                          B- Início do transporte para o bloco
    *                          F - Fim do transporte para uma sala de recobro
    *                          C- Cancelamento do transporte
    *
    * @param o_error       Mensagem de erro
    *
    * @return              TRUE/FALSE
    *
    * @author              Rui Batista
    * @since               2006/10/19
       ********************************************************************************************/

    FUNCTION set_patient_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_room       IN room.id_room%TYPE,
        i_dt_mov_str IN VARCHAR2,
        i_action     IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_pat_status  sr_pat_status.flg_pat_status%TYPE;
        i_dt_mov      TIMESTAMP WITH LOCAL TIME ZONE;
        l_patstatus_e sr_surgery_record.flg_pat_status%TYPE;
        l_rowsid      table_varchar;
    
    BEGIN
    
        i_dt_mov       := pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_mov_str, NULL);
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        --Obtem o último estado do paciente
        g_error := 'GET LAST PATIENT STATUS';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT DISTINCT nvl(p.flg_pat_status, g_pat_status_a)
              INTO l_pat_status
              FROM sr_pat_status p
             WHERE p.id_episode = i_episode
               AND p.dt_status_tstz = (SELECT MAX(p1.dt_status_tstz)
                                         FROM sr_pat_status p1
                                        WHERE p1.id_episode = i_episode);
        
        EXCEPTION
            WHEN no_data_found THEN
                l_pat_status := g_pat_status_a;
        END;
    
        IF nvl(i_action, 'R') = 'R'
        THEN
            --Requisição de transporte
            --Verifica se o estado do paciente pode ser alterado automaticamente
            IF l_pat_status IN (g_pat_status_a, g_pat_status_w)
            THEN
                --O estado do paciente é, em termos de workflow, "inferior" ao novo estado por isso, pode ser alterado
                g_error := 'INSERT NEW PATIENT STATUS';
                pk_alertlog.log_debug(g_error);
                INSERT INTO sr_pat_status
                    (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
                VALUES
                    (seq_sr_pat_status.nextval, i_episode, i_prof.id, g_pat_status_l, i_dt_mov);
            
                g_error := 'UPDATE SR_SURGERY_RECORD';
                pk_alertlog.log_debug(g_error);
                UPDATE sr_surgery_record
                   SET flg_pat_status = g_pat_status_l
                 WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                            FROM schedule_sr
                                           WHERE id_episode = i_episode);
                l_patstatus_e := g_pat_status_l;
            END IF;
        
        ELSIF nvl(i_action, 'R') = 'B'
        THEN
            --Início de transporte
            --Verifica se o estado do paciente pode ser alterado automaticamente
            IF l_pat_status IN (g_pat_status_a, g_pat_status_w, g_pat_status_l)
            THEN
                --O estado do paciente é, em termos de workflow, "inferior" ao novo estado por isso, pode ser alterado
                g_error := 'INSERT NEW PATIENT STATUS';
                pk_alertlog.log_debug(g_error);
                INSERT INTO sr_pat_status
                    (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
                VALUES
                    (seq_sr_pat_status.nextval, i_episode, i_prof.id, g_pat_status_t, i_dt_mov);
            
                g_error := 'UPDATE SR_SURGERY_RECORD';
                pk_alertlog.log_debug(g_error);
                UPDATE sr_surgery_record
                   SET flg_pat_status = g_pat_status_t
                 WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                            FROM schedule_sr
                                           WHERE id_episode = i_episode);
                l_patstatus_e := g_pat_status_t;
            END IF;
        
        ELSIF nvl(i_action, 'R') = 'F'
        THEN
            --Fim de transporte para o recobro
            --Verifica se o estado do paciente pode ser alterado automaticamente
            IF l_pat_status IN (g_pat_status_a,
                                g_pat_status_w,
                                g_pat_status_l,
                                g_pat_status_t,
                                g_pat_status_v,
                                g_pat_status_p,
                                g_pat_status_r,
                                g_pat_status_s,
                                g_pat_status_f)
            THEN
                --O estado do paciente é, em termos de workflow, "inferior" ao novo estado por isso, pode ser alterado
                g_error := 'INSERT NEW PATIENT STATUS';
                pk_alertlog.log_debug(g_error);
                INSERT INTO sr_pat_status
                    (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
                VALUES
                    (seq_sr_pat_status.nextval, i_episode, i_prof.id, g_pat_status_y, i_dt_mov);
            
                g_error := 'UPDATE SR_SURGERY_RECORD';
                pk_alertlog.log_debug(g_error);
                UPDATE sr_surgery_record
                   SET flg_pat_status = g_pat_status_y
                 WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                            FROM schedule_sr
                                           WHERE id_episode = i_episode);
                l_patstatus_e := g_pat_status_y;
            END IF;
        
        ELSIF nvl(i_action, 'R') = 'C'
        THEN
            --Cancelamento de transporte
            --No caso do cancelamento do transporte, o estado do paciente será o estado que estava anteriormente
            g_error := 'GET LAST PAT STATUS CANCEL';
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT flg_pat_status
                  INTO l_pat_status
                  FROM sr_pat_status p
                 WHERE p.id_episode = i_episode
                   AND p.flg_pat_status NOT IN (g_pat_status_l, g_pat_status_t)
                   AND p.dt_status_tstz =
                       (SELECT MAX(p1.dt_status_tstz)
                          FROM sr_pat_status p1
                         WHERE p1.id_episode = i_episode
                           AND p1.flg_pat_status NOT IN (g_pat_status_l, g_pat_status_t));
            EXCEPTION
                WHEN no_data_found THEN
                    l_pat_status := g_pat_status_a;
            END;
        
            g_error := 'INSERT LAST PATIENT STATUS';
            pk_alertlog.log_debug(g_error);
            INSERT INTO sr_pat_status
                (id_sr_pat_status, id_episode, id_professional, flg_pat_status, dt_status_tstz)
            VALUES
                (seq_sr_pat_status.nextval, i_episode, i_prof.id, l_pat_status, i_dt_mov);
        
            g_error := 'UPDATE SR_SURGERY_RECORD';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_surgery_record
               SET flg_pat_status = l_pat_status
             WHERE id_schedule_sr IN (SELECT id_schedule_sr
                                        FROM schedule_sr
                                       WHERE id_episode = i_episode);
            l_patstatus_e := l_pat_status;
        END IF;
    
        IF l_patstatus_e IS NOT NULL
        THEN
            g_error := 'UPDATE EPIS_INFO';
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in => i_episode, flg_pat_status_in => l_patstatus_e, rows_out => l_rowsid);
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'EPIS_INFO',
                                          i_rowids       => l_rowsid,
                                          o_error        => o_error,
                                          i_list_columns => table_varchar('FLG_PAT_STATUS'));
        
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
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_PATIENT_STATUS',
                                              o_error);
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
                                              'SET_PATIENT_STATUS',
                                              o_error);
            RETURN FALSE;
    END set_patient_status;

    /********************************************************************************************
    *  Get the closer ORIS episode when I make a request of patient transport
    *
    * @param i_lang        Language ID
    * @param i_prof        Professional  
    * @param i_movement     id_movement
    *
    * @param o_oris_episode ORIS episode
    * @param o_id_room      id room
    * @param o_error       Error message
    *
    * @return              TRUE/FALSE
    *
    * @author              Filipe Silva
    * @since               2009/09/24
     ********************************************************************************************/
    FUNCTION get_oris_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_movement     IN movement.id_movement%TYPE,
        o_oris_episode OUT episode.id_episode%TYPE,
        o_id_room      OUT room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_episode
        (
            l_check_future_date VARCHAR2,
            l_gap_hours         NUMBER
        ) IS
            SELECT t2.id_episode
              FROM (SELECT t.*,
                           CASE
                                WHEN t.time_diff < 0 THEN
                                 t.time_diff * -1
                                ELSE
                                 t.time_diff
                            END time_diff2
                      FROM (SELECT e.id_episode,
                                   sr.dt_interv_preview_tstz,
                                   pk_date_utils.get_timestamp_diff(sr.dt_interv_preview_tstz, current_timestamp) time_diff
                              FROM episode e
                             INNER JOIN schedule_sr sr
                                ON sr.id_episode = e.id_episode
                             WHERE e.id_epis_type = pk_alert_constant.g_epis_type_operating
                               AND e.flg_status = pk_alert_constant.g_epis_status_active
                               AND sr.dt_interv_preview_tstz IS NOT NULL
                               AND (e.id_visit, e.id_institution) IN
                                   (SELECT e.id_visit, e.id_institution
                                      FROM movement m
                                      JOIN episode e
                                        ON e.id_episode = m.id_episode
                                     WHERE m.id_movement = i_movement)) t
                     WHERE (l_check_future_date = pk_alert_constant.g_no AND t.time_diff BETWEEN l_gap_hours AND 1)
                        OR (l_check_future_date = pk_alert_constant.g_yes AND t.time_diff > 1)) t2
             ORDER BY t2.time_diff2;
    
        l_notfound      BOOLEAN;
        l_function_name VARCHAR2(30 CHAR) := 'GET_ORIS_EPISODE';
        l_gap_hours     NUMBER;
    
    BEGIN
    
        l_gap_hours := (to_number(nvl(pk_sysconfig.get_config('SR_TRANSPORT_PATIENT_TO_SURGICAL_PROCEDURE', i_prof), 24)));
        l_gap_hours := -l_gap_hours;
    
        g_error := 'GET ID_ROOM_TO FOR ID_MOVEMENT: ' || i_movement;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT id_room_to
              INTO o_id_room
              FROM movement m
             WHERE m.id_movement = i_movement;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_room := NULL;
        END;
    
        g_error := 'GET ORIS EPISODE';
        pk_alertlog.log_debug(g_error);
    
        -- get the id_episode date more closer between yesterday and today
        OPEN c_get_episode(pk_alert_constant.g_no, l_gap_hours);
        FETCH c_get_episode
            INTO o_oris_episode;
        l_notfound := c_get_episode%NOTFOUND;
        CLOSE c_get_episode;
    
        --if there aren't, so get future id_episode date
        IF l_notfound
        THEN
            OPEN c_get_episode(pk_alert_constant.g_yes, l_gap_hours);
            FETCH c_get_episode
                INTO o_oris_episode;
            CLOSE c_get_episode;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_SR_OUTPUT',
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_oris_episode;

    FUNCTION insert_sr_epis_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_ct_io          IN table_varchar DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_update                 VARCHAR2(1) := pk_alert_constant.g_yes;
        l_rows                   table_varchar;
        l_id_sr_epis_interv_hist sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE;
        l_sr_epis_interv         sr_epis_interv%ROWTYPE;
        l_sr_epis_interv_hist    sr_epis_interv_hist%ROWTYPE;
    
    BEGIN
    
        BEGIN
            SELECT *
              INTO l_sr_epis_interv
              FROM sr_epis_interv
             WHERE id_sr_epis_interv = i_id_sr_epis_interv;
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
        END;
    
        BEGIN
            SELECT *
              INTO l_sr_epis_interv_hist
              FROM sr_epis_interv_hist
             WHERE id_sr_epis_interv = i_id_sr_epis_interv
               AND flg_status_hist = pk_alert_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                l_update := pk_alert_constant.g_no;
        END;
    
        IF l_update = pk_alert_constant.g_yes
        THEN
            ts_sr_epis_interv_hist.upd(id_sr_epis_interv_hist_in => l_sr_epis_interv_hist.id_sr_epis_interv_hist,
                                       flg_status_hist_in        => pk_alert_constant.g_outdated,
                                       rows_out                  => l_rows);
        END IF;
    
        ts_sr_epis_interv_hist.ins(id_sr_epis_interv_in       => l_sr_epis_interv.id_sr_epis_interv,
                                   id_episode_in              => l_sr_epis_interv.id_episode,
                                   flg_status_hist_in         => pk_alert_constant.g_active,
                                   id_sr_intervention_in      => l_sr_epis_interv.id_sr_intervention,
                                   dt_req_tstz_in             => l_sr_epis_interv.dt_req_tstz,
                                   id_prof_req_in             => l_sr_epis_interv.id_prof_req,
                                   flg_type_in                => l_sr_epis_interv.flg_type,
                                   flg_status_in              => l_sr_epis_interv.flg_status,
                                   id_episode_context_in      => l_sr_epis_interv.id_episode_context,
                                   name_interv_in             => l_sr_epis_interv.name_interv,
                                   id_prof_req_unc_in         => l_sr_epis_interv.id_prof_req_unc,
                                   dt_req_unc_tstz_in         => l_sr_epis_interv.dt_req_unc_tstz,
                                   flg_code_type_in           => l_sr_epis_interv.flg_code_type,
                                   laterality_in              => l_sr_epis_interv.laterality,
                                   flg_surg_request_in        => l_sr_epis_interv.flg_surg_request,
                                   id_epis_diagnosis_in       => l_sr_epis_interv.id_epis_diagnosis,
                                   notes_in                   => l_sr_epis_interv.notes,
                                   dt_interv_start_tstz_in    => l_sr_epis_interv.dt_interv_start_tstz,
                                   dt_interv_end_tstz_in      => l_sr_epis_interv.dt_interv_start_tstz,
                                   notes_cancel_in            => l_sr_epis_interv.notes_cancel,
                                   id_prof_cancel_in          => l_sr_epis_interv.id_prof_cancel,
                                   id_sr_cancel_reason_in     => l_sr_epis_interv.id_sr_cancel_reason,
                                   dt_cancel_tstz_in          => l_sr_epis_interv.dt_cancel_tstz,
                                   id_sr_epis_interv_hist_out => l_id_sr_epis_interv_hist,
                                   id_not_order_reason_in     => l_sr_epis_interv.id_not_order_reason,
                                   id_interv_codification_in  => l_sr_epis_interv.id_interv_codification,
                                   rows_out                   => l_rows);
    
        g_error := 'call insert_sr_epis_interv_mod_fact';
        IF NOT insert_sr_epis_interv_mod_fact(i_lang                   => i_lang,
                                              i_prof                   => i_prof,
                                              i_id_sr_epis_interv_hist => l_id_sr_epis_interv_hist,
                                              i_id_ct_io               => i_id_ct_io,
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
                                              'INSERT_SR_EPIS_INTERV_HIST',
                                              o_error);
            RETURN FALSE;
    END insert_sr_epis_interv_hist;
    /***************************************************************
    * sr_epis_interv Logic entry funtion
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    *
    * @author Paulo Teixeira
    * @version 2.6.3.2
    * @since 2013/01/25
    ***************************************************************/
    FUNCTION set_ia_event_prescription
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_action        IN VARCHAR2,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_flg_status_new    IN sr_epis_interv.flg_status%TYPE,
        i_flg_status_old    IN sr_epis_interv.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_flg_action = 'I' --insert
        THEN
            g_error := 'call pk_ia_event_prescription.sr_procedure_new';
            pk_ia_event_prescription.sr_procedure_new(i_id_institution    => i_prof.institution,
                                                      i_id_professional   => i_prof.id,
                                                      i_id_software       => i_prof.software,
                                                      i_id_language       => i_lang,
                                                      i_id_sr_epis_interv => i_id_sr_epis_interv);
        
        ELSIF i_flg_action = 'U' --update
        THEN
            IF i_flg_status_new = 'C'
               AND i_flg_status_old <> 'C'
            THEN
                g_error := 'call pk_ia_event_prescription.sr_procedure_cancel';
                pk_ia_event_prescription.sr_procedure_cancel(i_id_institution    => i_prof.institution,
                                                             i_id_professional   => i_prof.id,
                                                             i_id_software       => i_prof.software,
                                                             i_id_language       => i_lang,
                                                             i_id_sr_epis_interv => i_id_sr_epis_interv);
            ELSIF i_flg_status_new = 'F'
                  AND i_flg_status_old <> 'F'
            THEN
                g_error := 'call pk_ia_event_prescription.sr_procedure_completed';
                pk_ia_event_prescription.sr_procedure_completed(i_id_institution    => i_prof.institution,
                                                                i_id_professional   => i_prof.id,
                                                                i_id_software       => i_prof.software,
                                                                i_id_language       => i_lang,
                                                                i_id_sr_epis_interv => i_id_sr_epis_interv);
            ELSE
                g_error := 'call pk_ia_event_prescription.sr_procedure_update';
                pk_ia_event_prescription.sr_procedure_update(i_id_institution    => i_prof.institution,
                                                             i_id_professional   => i_prof.id,
                                                             i_id_software       => i_prof.software,
                                                             i_id_language       => i_lang,
                                                             i_id_sr_epis_interv => i_id_sr_epis_interv);
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
                                              'SET_IA_EVENT_PRESCRIPTION',
                                              o_error);
            RETURN FALSE;
    END set_ia_event_prescription;

    FUNCTION insert_sr_epis_interv_mod_fact
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE,
        i_id_ct_io               IN table_varchar DEFAULT NULL,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows    table_varchar := table_varchar();
        l_tvc_aux table_varchar := table_varchar();
    
    BEGIN
    
        -- begin validations
        IF i_id_ct_io IS NULL
           OR i_id_sr_epis_interv_hist IS NULL
        THEN
            RETURN TRUE;
        END IF;
    
        IF i_id_ct_io.count = 0
        THEN
            RETURN TRUE;
        END IF;
    
        IF i_id_ct_io(1) IS NULL
        THEN
            RETURN TRUE;
        END IF;
        -- end validations
    
        FOR i IN 1 .. i_id_ct_io.count
        LOOP
            g_error   := 'call pk_utils.str_split_l';
            l_tvc_aux := pk_utils.str_split_l(i_id_ct_io(i), '|');
        
            IF l_tvc_aux(1) IS NOT NULL
               AND l_tvc_aux(2) IS NOT NULL
            THEN
                g_error := 'call ts_sr_epis_interv_mod_fact.ins';
                ts_sr_epis_interv_mod_fact.ins(id_sr_epis_interv_hist_in => i_id_sr_epis_interv_hist,
                                               id_concept_term_in        => l_tvc_aux(1),
                                               id_inst_owner_in          => l_tvc_aux(2),
                                               rows_out                  => l_rows);
            
            END IF;
        END LOOP;
    
        g_error := 'call t_data_gov_mnt.process_insert';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'SR_EPIS_INTERV_MOD_FACT',
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
                                              'INSERT_SR_EPIS_INTERV_MOD_FACT',
                                              o_error);
            RETURN FALSE;
    END insert_sr_epis_interv_mod_fact;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_sr_output;
/
