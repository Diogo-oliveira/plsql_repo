/*-- Last Change Revision: $Rev: 2027500 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prescription_int IS

    -- ***************************************************************************************
    -- PRIVATE PACKAGE VARIABLES
    -- ***************************************************************************************
    g_package_owner VARCHAR2(30);
    g_package_name  VARCHAR2(30);


    /********************************************************************************************
     * Cancel a prescription (not used by Flash).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_det         Prescription ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancelation notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/

    FUNCTION call_cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_det_status   drug_presc_det.flg_status%TYPE;
        l_id_plan      drug_presc_plan.id_drug_presc_plan%TYPE;
        l_char         VARCHAR2(1);
        l_cancel_plan  BOOLEAN := FALSE;
        l_id_epis_type epis_type.id_epis_type%TYPE;
        l_error        VARCHAR2(4000);
    
        l_rows     table_varchar;
        l_rowsdpdu table_varchar;
    
        l_flg_ci              drug_presc_det.flg_ci%TYPE;
        l_flg_cheaper         drug_presc_det.flg_cheaper%TYPE;
        l_flg_justif          drug_presc_det.flg_justif%TYPE;
        l_flg_interac_allergy drug_presc_det.flg_interac_allergy%TYPE;
        l_flg_attention       drug_presc_det.flg_attention%TYPE;
        l_id_drug_presc_det   drug_presc_det.id_drug_presc_det%TYPE;
    
        l_del_alert VARCHAR2(1) := NULL;
    
        l_st VARCHAR2(255);
    
        CURSOR c_det IS
            SELECT p.id_drug_prescription, d.flg_take_type, p.id_episode, d.flg_status
              FROM drug_presc_det d, drug_prescription p
             WHERE d.id_drug_presc_det = i_drug_presc_det
               AND p.id_drug_prescription = d.id_drug_prescription;
        r_det c_det%ROWTYPE;
    
        CURSOR c_take_cont IS
            SELECT id_drug_presc_plan
              FROM drug_presc_plan
             WHERE id_drug_presc_det = i_drug_presc_det
               AND flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend);
    
        CURSOR c_take IS
            SELECT 'X'
              FROM drug_presc_plan
             WHERE id_drug_presc_det = i_drug_presc_det
               AND flg_status = g_presc_plan_stat_adm;
    
        CURSOR c_req(i_drug_presc IN drug_prescription.id_drug_prescription%TYPE) IS
            SELECT 'X'
              FROM drug_presc_det
             WHERE id_drug_presc_det != i_drug_presc_det
               AND id_drug_prescription = i_drug_presc
               AND flg_status != g_det_can;
    
        CURSOR c_req_fin(i_drug_presc IN drug_prescription.id_drug_prescription%TYPE) IS
            SELECT 'X'
              FROM drug_presc_det
             WHERE id_drug_presc_det != i_drug_presc_det
               AND id_drug_prescription = i_drug_presc
               AND flg_status NOT IN (g_det_fin, g_det_intr);
    
        l_interac_med   VARCHAR2(1);
        l_related_presc table_number := table_number();
        l_related_med   table_number := table_number();
        l_type          table_varchar := table_varchar();
        l_related_req   table_number := table_number();
        l_related_drug  table_number := table_number();
        l_type_req      table_varchar := table_varchar();
        l_id_pat        NUMBER;
        i               NUMBER := 1;
    
        l_flg_att_aux prescription_pharm.flg_attention%TYPE;
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_DET';
        OPEN c_det;
        FETCH c_det
            INTO r_det;
        CLOSE c_det;
    
        IF r_det.flg_status != g_det_can
        THEN
        
            IF r_det.flg_take_type = g_presc_take_sos
            THEN
                l_det_status := g_det_intr;
            
                -- Eliminação do alerta de toma
                -- l_del_alert := g_yes; -- NÃO É PRECISO PORQUE NÃO TEM REGISTO CRIADO NA DPP
            
            ELSIF r_det.flg_take_type = g_presc_take_cont
            THEN
                g_error := 'OPEN C_TAKE_CONT';
                OPEN c_take_cont;
                FETCH c_take_cont
                    INTO l_id_plan;
                g_found := c_take_cont%FOUND;
                CLOSE c_take_cont;
            
                IF g_found
                THEN
                    l_cancel_plan := TRUE;
                    l_det_status  := g_det_can;
                ELSE
                    l_det_status := g_det_intr;
                END IF;
            
                -- Eliminação do alerta de toma
                l_del_alert := g_yes;
            
            ELSE
                g_error := 'OPEN C_TAKE';
                OPEN c_take;
                FETCH c_take
                    INTO l_char;
                g_found := c_take%FOUND;
                CLOSE c_take;
            
                IF g_found
                THEN
                    l_det_status := g_det_intr;
                ELSE
                    l_det_status := g_det_can;
                END IF;
                l_cancel_plan := TRUE;
            
                -- Eliminação do alerta de toma
                l_del_alert := g_yes;
            
                g_error := 'OPEN C_TAKE_CONT';
                OPEN c_take_cont;
                FETCH c_take_cont
                    INTO l_id_plan;
                g_found := c_take_cont%FOUND;
                CLOSE c_take_cont;
            END IF;
        
            IF l_cancel_plan
            THEN
                g_error := 'UPDATE DRUG_PRESC_PLAN';
                ts_drug_presc_plan.upd(id_drug_presc_plan_in => l_id_plan,
                                       flg_status_in         => g_presc_plan_stat_can,
                                       dt_cancel_tstz_in     => g_sysdate_tstz,
                                       dt_cancel_tstz_nin    => FALSE,
                                       id_prof_cancel_in     => i_prof.id,
                                       id_prof_cancel_nin    => FALSE,
                                       --                                       id_episode_in         => i_episode,
                                       --                                       id_episode_nin        => FALSE,
                                       rows_out => l_rows);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'DRUG_PRESC_PLAN',
                                              l_rows,
                                              o_error,
                                              table_varchar('FLG_STATUS', 'DT_CANCEL_TSTZ', 'ID_PROF_CANCEL'));
            END IF;
        
            -- CJV
        
            i := 1;
        
            g_error := 'UPDATE DRUG_PRESC_DET';
            l_rows  := table_varchar();
            ts_drug_presc_det.upd(id_drug_presc_det_in => i_drug_presc_det,
                                  flg_modified_in      => CAST(NULL AS VARCHAR2),
                                  flg_modified_nin     => FALSE,
                                  flg_status_in        => l_det_status,
                                  dt_cancel_tstz_in    => g_sysdate_tstz,
                                  dt_cancel_tstz_nin   => FALSE,
                                  id_prof_cancel_in    => i_prof.id,
                                  id_prof_cancel_nin   => FALSE,
                                  notes_cancel_in      => i_notes,
                                  notes_cancel_nin     => FALSE,
                                  rows_out             => l_rows);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'DRUG_PRESC_PLAN',
                                          l_rows,
                                          o_error,
                                          table_varchar('FLG_STATUS',
                                                        'DT_CANCEL_TSTZ',
                                                        'ID_PROF_CANCEL',
                                                        'FLG_MODIFIED'));
        
            -- José Brito 28/05/2008 Remover tarefa de Co-Sign
            g_error := 'CALL TO PK_CO_SIGN_TASK.REMOVE_CO_SIGN_TASK';
            IF NOT pk_co_sign.remove_co_sign_task(i_lang     => i_lang,
                                                  i_prof     => i_prof,
                                                  i_episode  => r_det.id_episode,
                                                  i_id_task  => i_drug_presc_det,
                                                  i_flg_type => g_cosign_type_drug_presc,
                                                  o_error    => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            -- <DENORM Fábio>
            IF l_rowsdpdu != NULL
            THEN
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'DRUG_PRESC_PLAN',
                                              l_rowsdpdu,
                                              o_error,
                                              table_varchar('FLG_ATTENTION', 'DT_INTERAC_MED'));
            END IF;
        
            -- Pesquisa a existência de outros detalhes do mm cabeçalho, ñ cancelados
            g_error := 'OPEN C_REQ';
            OPEN c_req(r_det.id_drug_prescription);
            FETCH c_req
                INTO l_char;
            g_found := c_req%NOTFOUND;
            CLOSE c_req;
        
            IF g_found
            THEN
                -- Se ñ há + detalhes ñ cancelados, pode-se cancelar o cabeçalho
                g_error := 'UPDATE DRUG_PRESCRIPTION(1)';
                l_rows  := table_varchar();
                ts_drug_prescription.upd(flg_status_in      => g_drug_canc,
                                         id_prof_cancel_in  => i_prof.id,
                                         id_prof_cancel_nin => FALSE,
                                         dt_cancel_tstz_in  => g_sysdate_tstz,
                                         dt_cancel_tstz_nin => FALSE,
                                         where_in           => 'id_drug_prescription = ' || r_det.id_drug_prescription ||
                                                               ' AND flg_status != ''' || g_drug_canc || '''',
                                         rows_out           => l_rows);
            
                t_data_gov_mnt.process_update(i_lang,
                                              i_prof,
                                              'DRUG_PRESCRIPTION',
                                              l_rows,
                                              o_error,
                                              table_varchar('FLG_STATUS', 'ID_PROF_CANCEL', 'DT_CANCEL_TSTZ'));
            
            ELSE
                -- Pesquisa a existência de outros detalhes do mm cabeçalho, ñ finalizados
                g_error := 'OPEN C_REQ_FIN';
                OPEN c_req_fin(r_det.id_drug_prescription);
                FETCH c_req_fin
                    INTO l_char;
                g_found := c_req_fin%NOTFOUND;
                CLOSE c_req_fin;
            
                IF g_found
                THEN
                    -- Se ñ há + detalhes ñ finalizados, o cabeçalho fica finalizados
                    g_error := 'UPDATE DRUG_PRESCRIPTION(2)';
                    /* <DENORM Fábio> */
                    l_rows := table_varchar();
                    ts_drug_prescription.upd(id_drug_prescription_in => r_det.id_drug_prescription,
                                             flg_status_in           => g_drug_res,
                                             rows_out                => l_rows);
                
                    t_data_gov_mnt.process_update(i_lang,
                                                  i_prof,
                                                  'DRUG_PRESCRIPTION',
                                                  l_rows,
                                                  o_error,
                                                  table_varchar('FLG_STATUS'));
                END IF;
            END IF;
        
            --Verifica se o tipo de episódio é de Bloco Operatório. Se sim, insere requisição nas checklists
            --Apenas o bloco operatório tem Checklists.
            BEGIN
                SELECT id_epis_type
                  INTO l_id_epis_type
                  FROM episode
                 WHERE id_episode = r_det.id_episode;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_epis_type := NULL;
            END;
        
            IF l_del_alert = g_yes
            THEN
            
                pk_medication_core.print_medication_logs('delete_medication_alerts 10', pk_medication_core.c_log_debug);
                pk_alertlog.log_debug('DELETED  - Parameters for Alert id :' || 10 || '.' || ' i_id_episode: ' ||
                                      r_det.id_episode || ' i_id_record: ' || l_id_plan);
                IF NOT pk_medication_core.delete_medication_alerts(i_lang           => i_lang,
                                                                   i_prof           => i_prof,
                                                                   i_id_episode     => r_det.id_episode,
                                                                   i_id_record      => l_id_plan,
                                                                   i_dpd_flg_status => r_det.flg_status,
                                                                   i_dpp_flg_status => g_presc_plan_stat_can,
                                                                   i_med_type       => g_drug,
                                                                   o_error          => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
            END IF;
        
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => r_det.id_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => NULL,
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            g_error := 'CALL TO PK_PRESCRIPTION_INT.UPDATE_DRUG_PRESC_TASK';
            IF NOT pk_medication_core.update_drug_presc_task(i_lang          => i_lang,
                                                             i_episode       => r_det.id_episode,
                                                             i_prof          => i_prof,
                                                             i_prof_cat_type => NULL,
                                                             o_error         => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            g_error := 'CALL TO PK_GRID.DELETE_EPIS_GRID_TASK';
            IF NOT pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => r_det.id_episode, o_error => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
        END IF; --FLG_STATUS
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'CALL_CANCEL_PRESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;

    /********************************************************************************************
     * Cancel a prescription.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_det         Prescription ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancelation notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/

    FUNCTION cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        IF NOT cancel_presc(i_lang           => i_lang,
                            i_drug_presc_det => i_drug_presc_det,
                            i_prof           => i_prof,
                            i_notes          => i_notes,
                            i_commit         => g_yes,
                            o_error          => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'CANCEL_PRESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_presc;
    --

    FUNCTION cancel_presc
    (
        i_lang           IN language.id_language%TYPE,
        i_drug_presc_det IN drug_presc_det.id_drug_presc_det%TYPE,
        i_prof           IN profissional,
        i_notes          IN drug_presc_det.notes_cancel%TYPE,
        i_commit         IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_get_last_status IS
            SELECT drd.flg_status, dp.id_episode
              FROM drug_presc_det drd, drug_prescription dp
             WHERE drd.id_drug_presc_det = i_drug_presc_det
               AND drd.id_drug_prescription = dp.id_drug_prescription;
    
        rec_get_last_status c_get_last_status%ROWTYPE;
    
    BEGIN
    
        g_error := 'PK_PRESCRIPTION_INT.CALL_CANCEL_PRESC';
        IF NOT pk_prescription_int.call_cancel_presc(i_lang           => i_lang,
                                                     i_drug_presc_det => i_drug_presc_det,
                                                     i_prof           => i_prof,
                                                     i_notes          => i_notes,
                                                     o_error          => o_error)
        THEN
            --ROLLBACK;
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                ROLLBACK;
            END IF;
        
            raise_application_error(-20001, o_error.ora_sqlerrm);
        
        END IF;
        OPEN c_get_last_status;
        FETCH c_get_last_status
            INTO rec_get_last_status;
    
        IF NOT pk_medication_current.update_status_with_commit(i_lang,
                                                               rec_get_last_status.id_episode,
                                                               i_prof,
                                                               pk_medication_current.g_local,
                                                               rec_get_last_status.flg_status,
                                                               g_det_can,
                                                               i_drug_presc_det,
                                                               i_commit,
                                                               o_error)
        THEN
            CLOSE c_get_last_status;
            --
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                ROLLBACK;
            END IF;
        
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
        CLOSE c_get_last_status;
    
        --ALERT-169123 - Sets the reconcile information. When creating/changing medication, the reconcile status will go always to Partially reconciled
        IF NOT pk_prescription.set_reconcile_detail(i_lang            => i_lang,
                                                    i_prof            => i_prof,
                                                    i_episode         => rec_get_last_status.id_episode,
                                                    i_action          => pk_prescription.g_set_part_reconciled, --Set as Partially reconciled
                                                    i_reconcile_notes => NULL,
                                                    i_dt_reconcile    => NULL, --will by actual time
                                                    o_error           => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        --COMMIT
        IF i_commit IS NULL
           OR i_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            --
            IF i_commit IS NULL
               OR i_commit = g_yes
            THEN
                pk_utils.undo_changes;
            END IF;
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'CANCEL_PRESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_presc;
   
/********************************************************************************************
     * Update table GRID_TASK.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_episode                Episode ID
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2006/01/20
    **********************************************************************************************/

    FUNCTION insert_drug_presc_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error          VARCHAR2(4000);
        l_mess1          VARCHAR2(100);
        l_mess1_old      VARCHAR2(100);
        l_type_old       VARCHAR2(1);
        l_mess2          VARCHAR2(100);
        l_epis           episode.id_episode%TYPE;
        l_task           VARCHAR2(1);
        l_grid_task      grid_task%ROWTYPE;
        l_short_presc    sys_shortcut.id_sys_shortcut%TYPE;
        l_short_fluids   sys_shortcut.id_sys_shortcut%TYPE;
        l_exist          VARCHAR2(1);
        l_grid_task_betw grid_task_between%ROWTYPE;
        l_version        VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        -- Obter ID do atalho dos IV fluídos
        CURSOR c_short_fluids IS
            SELECT id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = 'IVFLUIDS_LIST'
               AND a.id_software = i_prof.software
                  --AND id_institution IN (0, i_prof.institution)
               AND a.id_institution = (SELECT MAX(b.id_institution)
                                         FROM sys_shortcut b
                                        WHERE b.id_software = a.id_software
                                          AND b.id_institution IN (0, i_prof.institution)
                                          AND b.intern_name = a.intern_name
                                          AND b.id_parent IS NULL)
               AND a.id_parent IS NULL
             ORDER BY a.id_institution DESC;
    
        -- Obter ID do atalho dos medicamentos
        CURSOR c_short_presc IS
            SELECT id_sys_shortcut
              FROM sys_shortcut a
             WHERE a.intern_name = 'GRID_DRUG_ADMIN'
               AND a.id_software = i_prof.software
                  --AND id_institution IN (0, i_prof.institution)
               AND a.id_institution = (SELECT MAX(b.id_institution)
                                         FROM sys_shortcut b
                                        WHERE b.id_software = a.id_software
                                          AND b.id_institution IN (0, i_prof.institution)
                                          AND b.intern_name = a.intern_name
                                          AND b.id_parent IS NULL)
               AND a.id_parent IS NULL
             ORDER BY a.id_institution DESC;
    
        --
        CURSOR c_drug IS
            SELECT epis.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   d.flg_type
              FROM mi_med d, drug_prescription dp, episode epis, drug_presc_det dpd, drug_presc_plan dpp
             WHERE dp.id_episode = i_episode
               AND d.id_drug = dpd.id_drug
               AND d.flg_type != g_drug
               AND d.vers = l_version
               AND epis.id_episode = dp.id_episode
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
                  --não queremos considerar estamos de suspensos ou interrompidos
               AND dpd.flg_status NOT IN (g_presc_det_sus, g_presc_det_intr)
            UNION ALL
            SELECT epis.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   d.flg_type
              FROM mi_med d, drug_prescription dp, episode epis, drug_presc_det dpd, drug_presc_plan dpp
             WHERE dp.id_episode = i_episode
               AND d.id_drug = dpd.id_drug
               AND d.flg_type = g_drug
               AND d.vers = l_version
               AND epis.id_episode = dp.id_episode
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
                  --não queremos considerar estamos de suspensos ou interrompidos
               AND dpd.flg_status NOT IN (g_presc_det_sus, g_presc_det_intr)
            UNION ALL
            SELECT epis.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   'M' --tipo medicamento
              FROM other_product op, drug_prescription dp, episode epis, drug_presc_det dpd, drug_presc_plan dpp
             WHERE dp.id_episode = i_episode
               AND op.id_other_product = dpd.id_other_product
               AND op.vers = l_version
               AND epis.id_episode = dp.id_episode
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
                  --não queremos considerar estamos de suspensos ou interrompidos
               AND dpd.flg_status NOT IN (g_presc_det_sus, g_presc_det_intr)
            UNION ALL
            --compounds
            SELECT epis.flg_status epis_status,
                   dp.flg_time,
                   decode(nvl(dp.id_episode_origin, 0), 0, dpp.dt_plan_tstz, dp.dt_begin_tstz) dt_begin,
                   dpp.flg_status,
                   dp.dt_drug_prescription_tstz dt_req,
                   epis.dt_begin_tstz epis_dt_begin,
                   NULL img_name,
                   'M' --tipo medicamento
              FROM combination_compound cc, drug_prescription dp, episode epis, drug_presc_det dpd, drug_presc_plan dpp
             WHERE dp.id_episode = i_episode
               AND cc.id_combination_compound = dpd.id_combination_compound
               AND cc.vers = l_version
               AND epis.id_episode = dp.id_episode
               AND dpd.id_drug_prescription = dp.id_drug_prescription
               AND dpp.id_drug_presc_det = dpd.id_drug_presc_det
               AND dpp.flg_status IN (g_presc_plan_stat_req, g_presc_plan_stat_pend)
                  --não queremos considerar estamos de suspensos ou interrompidos
               AND dpd.flg_status NOT IN (g_presc_det_sus, g_presc_det_intr)
             ORDER BY flg_time, dt_req; --2, 5;
    
    BEGIN
        --
        g_error := 'OPEN C_SHORT_FLUIDS';
        OPEN c_short_fluids;
        FETCH c_short_fluids
            INTO l_short_fluids;
        CLOSE c_short_fluids;
    
        g_error := 'OPEN C_SHORT_PRESC';
        OPEN c_short_presc;
        FETCH c_short_presc
            INTO l_short_presc;
        CLOSE c_short_presc;
    
        -- Corre todas as prescrições encontradas.
        -- Para cada, obtem a cadeia de caracteres. Nas instâncias consecutivas do loop
        -- compara-se cada string com a anterior e determina-se a prioridade
        g_error := 'LOOP C_DRUG';
        FOR cur IN c_drug
        LOOP
            g_error := 'GET L_MESS2';
            l_mess2 := pk_grid.get_string_task(i_lang        => i_lang,
                                               i_prof        => i_prof,
                                               i_epis_status => cur.epis_status,
                                               i_flg_time    => cur.flg_time,
                                               i_flg_status  => cur.flg_status,
                                               i_dt_begin    => cur.dt_begin,
                                               i_dt_req      => cur.dt_req,
                                               i_icon_name   => cur.img_name,
                                               i_rank        => NULL,
                                               o_error       => o_error);
            IF o_error IS NOT NULL
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            g_error := 'GET L_MESS1';
            IF l_mess1 IS NOT NULL
            THEN
                l_mess1_old := l_mess1;
                l_mess1     := pk_grid.get_prioritary_task(i_lang,
                                                           l_mess1,
                                                           l_mess2,
                                                           'DRUG_PRESCRIPTION.FLG_STATUS',
                                                           g_flg_doctor);
            END IF;
        
            IF l_mess1_old IS NOT NULL
            THEN
                IF l_mess1 = l_mess1_old
                THEN
                    l_type_old := l_type_old;
                ELSE
                    l_type_old := cur.flg_type;
                END IF;
            ELSE
                l_type_old := cur.flg_type;
            END IF;
        
            l_mess1 := nvl(l_mess1, l_mess2);
        
            IF cur.flg_time = 'B'
            THEN
                l_exist := 'Y';
            END IF;
        
        END LOOP;
    
        g_error := 'GET SHORTCUT';
        IF l_mess1 IS NOT NULL
        THEN
            IF l_type_old = g_drug
            THEN
                l_mess1 := l_short_presc || '|' || l_mess1;
            ELSE
                l_mess1 := l_short_fluids || '|' || l_mess1;
            END IF;
        END IF;
    
        l_grid_task.id_episode := i_episode;
        l_grid_task.drug_presc := l_mess1;
    
        --Actualiza estado da tarefa em GRID_TASK para o episódio correspondente
        IF NOT pk_grid.update_grid_task(i_lang => i_lang, i_grid_task => l_grid_task, o_error => o_error)
        THEN
            raise_application_error(-20001, o_error.ora_sqlerrm);
        END IF;
    
        IF l_exist = 'Y'
        THEN
            l_grid_task_betw.id_episode := i_episode;
            l_grid_task_betw.flg_drug   := l_exist;
        
            --Actualiza estado da tarefa em GRID_TASK_BETWEEN para o episódio correspondente
            IF NOT pk_grid.update_nurse_task(i_lang => i_lang, i_grid_task => l_grid_task_betw, o_error => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'INSERT_DRUG_PRESC_TASK',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END;
------------------------------------Registo da Origem do Medicamento-------------------------

    ----------------------------------------------------------------------------------------------------------
    /** @headcom
    * faz op set no ecran de cancelamento de prescrições
    *
    *
    * @param      I_LANG              língua registada como preferência do profissional.
    * @param      I_PROF            object (ID do profissional, ID da instituição, ID do software).
    * @param      i_drug_presc_det    lista de ids
    * @param      i_subject           lista de subjects
    * @param      i_notes           notas
    * @param      i_id_cancel_reason  tipo de cancelamento
    * @param      o_error             erro
    *
    * @return     boolean
    * @author     Pedro Albuquerque
    * @version    0.1
    * @since      2009/03/20
    */

    FUNCTION set_cancel_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_presc_det   IN table_number,
        i_subject          IN table_varchar,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_flg_commit       IN VARCHAR2,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status        table_varchar;
        l_id_episode        table_number;
        l_id_drug_presc_det table_number;
        l_id_drug           table_varchar;
        l_id_other_product  table_varchar;
    
    BEGIN
    
        BEGIN
            g_error := 'get flg_status';
            SELECT dpd.flg_status, dp.id_episode, dpd.id_drug_presc_det, dpd.id_drug, dpd.id_other_product
              BULK COLLECT
              INTO l_flg_status, l_id_episode, l_id_drug_presc_det, l_id_drug, l_id_other_product
              FROM drug_presc_det dpd, drug_prescription dp
             WHERE dpd.id_drug_presc_det IN (SELECT *
                                               FROM TABLE(i_drug_presc_det))
               AND dpd.id_drug_prescription = dp.id_drug_prescription;
        
        EXCEPTION
            WHEN no_data_found THEN
                raise_application_error(-20001, g_error);
        END;
    
        FOR i IN 1 .. l_id_drug_presc_det.count
        LOOP
            g_error := 'PK_PRESCRIPTION_INT.CALL_CANCEL_PRESC';
            IF NOT pk_prescription_int.call_cancel_presc(i_lang           => i_lang,
                                                         i_drug_presc_det => l_id_drug_presc_det(i),
                                                         i_prof           => i_prof,
                                                         i_notes          => i_notes,
                                                         o_error          => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            --This function uses commit = 'N' by default.
            IF NOT pk_medication_current.update_status_all(i_lang             => i_lang,
                                                           i_epis             => l_id_episode(i),
                                                           i_prof             => i_prof,
                                                           i_type             => table_varchar(i_subject(i)),
                                                           begin_status       => table_varchar(l_flg_status(i)),
                                                           end_status         => table_varchar(g_det_can),
                                                           i_id_presc         => table_number(l_id_drug_presc_det(i)),
                                                           i_cancel_reason    => i_cancel_reason,
                                                           i_id_cancel_reason => i_id_cancel_reason,
                                                           i_notes            => i_notes,
                                                           o_error            => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            --ALERT-153406
            pk_icnp_fo_api_db.set_sugg_status_cancel(i_lang         => i_lang,
                                                     i_prof         => i_prof,
                                                     i_request_id   => l_id_drug_presc_det(i),
                                                     i_task_type_id => CASE
                                                                           WHEN l_id_drug(i) IS NOT NULL THEN
                                                                            pk_alert_constant.g_task_med_local
                                                                           WHEN l_id_other_product(i) IS NOT NULL THEN
                                                                            pk_alert_constant.g_task_med_local_op
                                                                       END,
                                                     i_sysdate_tstz => current_timestamp);
        
        END LOOP;
    
        FOR l_rec IN (SELECT DISTINCT column_value AS id_episode
                        FROM TABLE(l_id_episode)) --Loop over distinct episodes
        LOOP
            --ALERT-169123 - Sets the reconcile information. When creating/changing medication, the reconcile status will go always to Partially reconciled
            IF NOT pk_prescription.set_reconcile_detail(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_episode         => l_rec.id_episode,
                                                        i_action          => pk_prescription.g_set_part_reconciled, --Set as Partially reconciled
                                                        i_reconcile_notes => NULL,
                                                        i_dt_reconcile    => NULL, --will by actual time
                                                        o_error           => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        IF i_flg_commit = g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'SET_CANCEL_PRESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_cancel_presc;

    FUNCTION set_cancel_presc
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_drug_presc_det   IN table_number,
        i_subject          IN table_varchar,
        i_notes            IN drug_presc_det.notes_cancel%TYPE,
        i_cancel_reason    IN VARCHAR2,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_flg_status        table_varchar;
        l_id_episode        table_number;
        l_id_drug_presc_det table_number;
    
    BEGIN
    
        BEGIN
            g_error := 'get flg_status';
            SELECT drd.flg_status, dp.id_episode, drd.id_drug_presc_det
              BULK COLLECT
              INTO l_flg_status, l_id_episode, l_id_drug_presc_det
              FROM drug_presc_det drd, drug_prescription dp
             WHERE drd.id_drug_presc_det IN (SELECT *
                                               FROM TABLE(i_drug_presc_det))
               AND drd.id_drug_prescription = dp.id_drug_prescription;
        
        EXCEPTION
            WHEN no_data_found THEN
                raise_application_error(-20001, g_error);
        END;
    
        FOR i IN 1 .. l_id_drug_presc_det.count
        LOOP
            g_error := 'PK_PRESCRIPTION_INT.CALL_CANCEL_PRESC';
            IF NOT pk_prescription_int.call_cancel_presc(i_lang           => i_lang,
                                                         i_drug_presc_det => l_id_drug_presc_det(i),
                                                         i_prof           => i_prof,
                                                         i_notes          => i_notes,
                                                         o_error          => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        
            IF NOT pk_medication_current.update_status(i_lang,
                                                       l_id_episode(i),
                                                       i_prof,
                                                       i_subject(i),
                                                       l_flg_status(i),
                                                       g_det_can,
                                                       l_id_drug_presc_det(i),
                                                       i_cancel_reason,
                                                       i_id_cancel_reason,
                                                       i_notes,
                                                       o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        FOR l_rec IN (SELECT DISTINCT column_value AS id_episode
                        FROM TABLE(l_id_episode)) --Loop over distinct episodes
        LOOP
            --ALERT-169123 - Sets the reconcile information. When creating/changing medication, the reconcile status will go always to Partially reconciled
            IF NOT pk_prescription.set_reconcile_detail(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_episode         => l_rec.id_episode,
                                                        i_action          => pk_prescription.g_set_part_reconciled, --Set as Partially reconciled
                                                        i_reconcile_notes => NULL,
                                                        i_dt_reconcile    => NULL, --will by actual time
                                                        o_error           => o_error)
            THEN
                raise_application_error(-20001, o_error.ora_sqlerrm);
            END IF;
        END LOOP;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'SET_CANCEL_PRESC',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END set_cancel_presc;

    /********************************************************************************************
     * Cancels the administration of a take.
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_drug_presc_plan        Planned administration ID
     * @param i_dt_next                Next administration date
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_notes                  Cancel notes
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         Nuno Antunes
     * @version                        0.1
     * @since                          2011/01/03
    **********************************************************************************************/
    FUNCTION cancel_adm_take
    (
        i_lang                IN language.id_language%TYPE,
        i_drug_presc_plan     IN drug_presc_plan.id_drug_presc_plan%TYPE,
        i_dt_next             IN VARCHAR2,
        i_prof                IN profissional,
        i_notes               IN drug_presc_plan.notes%TYPE,
        i_id_cancel_reason    IN drug_presc_plan.id_cancel_reason%TYPE,
        i_cancel_reason_descr IN drug_presc_plan.cancel_reason_descr%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_version VARCHAR2(10) := pk_sysconfig.get_config('PRESCRIPTION_TYPE', i_prof);
    
        CURSOR c_det IS
            SELECT nvl(dpd.interval, 0) INTERVAL,
                   dpd.dosage,
                   dpd.id_drug_presc_det,
                   d.id_episode,
                   dpp.dt_plan_tstz,
                   dpp.flg_status,
                   d.id_drug_prescription,
                   d.flg_time,
                   d.dt_begin_tstz,
                   dpd.flg_status AS dpd_status,
                   pk_medication_core.get_medication_name(i_lang, i_prof, mi.id_drug, g_local, NULL) AS l_med_descr,
                   dpp.id_presc_dir_dosefreq,
                   dpd.id_presc_directions,
                   dpd.flg_take_type
              FROM drug_presc_det dpd, drug_presc_plan dpp, drug_prescription d, mi_med mi
             WHERE dpp.id_drug_presc_plan = i_drug_presc_plan
               AND dpd.id_drug_presc_det = dpp.id_drug_presc_det
               AND d.id_drug_prescription = dpd.id_drug_prescription
               AND mi.id_drug = dpd.id_drug
               AND dpd.vers = mi.vers
               AND mi.vers = l_version
            UNION
            --outros produtos
            SELECT nvl(dpd.interval, 0) INTERVAL,
                   dpd.dosage,
                   dpd.id_drug_presc_det,
                   d.id_episode,
                   dpp.dt_plan_tstz,
                   dpp.flg_status,
                   d.id_drug_prescription,
                   d.flg_time,
                   d.dt_begin_tstz,
                   dpd.flg_status AS dpd_status,
                   pk_medication_core.get_medication_name(i_lang, i_prof, op.id_other_product, g_other_prod, NULL) AS l_med_descr,
                   dpp.id_presc_dir_dosefreq,
                   dpd.id_presc_directions,
                   dpd.flg_take_type
              FROM drug_presc_det dpd, drug_presc_plan dpp, drug_prescription d, other_product op
             WHERE dpp.id_drug_presc_plan = i_drug_presc_plan
               AND dpd.id_drug_presc_det = dpp.id_drug_presc_det
               AND d.id_drug_prescription = dpd.id_drug_prescription
               AND op.id_other_product = dpd.id_other_product
               AND dpd.vers = op.vers
               AND op.vers = l_version
            UNION
            --compound medication
            SELECT nvl(dpd.interval, 0) INTERVAL,
                   dpd.dosage,
                   dpd.id_drug_presc_det,
                   d.id_episode,
                   dpp.dt_plan_tstz,
                   dpp.flg_status,
                   d.id_drug_prescription,
                   d.flg_time,
                   d.dt_begin_tstz,
                   dpd.flg_status AS dpd_status,
                   cc.name AS l_med_descr,
                   dpp.id_presc_dir_dosefreq,
                   dpd.id_presc_directions,
                   dpd.flg_take_type
              FROM drug_presc_det dpd, drug_presc_plan dpp, drug_prescription d, combination_compound cc
             WHERE dpp.id_drug_presc_plan = i_drug_presc_plan
               AND dpd.id_drug_presc_det = dpp.id_drug_presc_det
               AND d.id_drug_prescription = dpd.id_drug_prescription
               AND cc.id_combination_compound = dpd.id_combination_compound
               AND dpd.vers = cc.vers
               AND cc.vers = l_version;
    
        r_det c_det%ROWTYPE;
    
        l_id_epis_type epis_type.id_epis_type%TYPE;
        l_error        VARCHAR2(2000);
        l_dt_next      VARCHAR2(24) := i_dt_next;
        --l_sr_chklist_det sr_chklist_det%ROWTYPE;
        l_rows      table_varchar;
        l_del_alert VARCHAR2(1) := NULL;
        l_presc_dpp drug_presc_plan.id_drug_presc_plan%TYPE;
    
        l_dt_plan               drug_presc_plan.dt_plan_tstz%TYPE;
        l_id_presc_dir_dosefreq presc_dir_dosefreq.id_presc_dir_dosefreq%TYPE;
    
    BEGIN
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'OPEN C_DET';
        OPEN c_det;
        FETCH c_det
            INTO r_det;
        CLOSE c_det;
    
        IF r_det.flg_status IN (g_presc_plan_stat_adm, 'T')
        THEN
        
            g_error := 'UPDATE DRUG_PRESC_PLAN';
            ts_drug_presc_plan.upd(flg_status_in           => g_presc_plan_stat_adm_cancel,
                                   dt_cancel_tstz_in       => g_sysdate_tstz,
                                   id_prof_cancel_in       => i_prof.id,
                                   notes_cancel_in         => i_notes,
                                   id_drug_presc_plan_in   => i_drug_presc_plan,
                                   dt_cancel_tstz_nin      => FALSE,
                                   id_prof_cancel_nin      => FALSE,
                                   notes_cancel_nin        => FALSE,
                                   id_cancel_reason_in     => i_id_cancel_reason,
                                   cancel_reason_descr_in  => i_cancel_reason_descr,
                                   id_cancel_reason_nin    => FALSE,
                                   cancel_reason_descr_nin => FALSE,
                                   rows_out                => l_rows);
        
            g_error := 'CREATE HIST';
            INSERT INTO prescription_instr_hist
                (id_prescription_instr_hist,
                 id_presc,
                 flg_type_presc,
                 id_professional,
                 id_institution,
                 id_software,
                 last_update_tstz,
                 prescription_table,
                 flg_status_old,
                 flg_status_new,
                 flg_change,
                 notes,
                 cancel_reason,
                 id_cancel_reason,
                 id_presc_directions)
            VALUES
                (seq_prescription_instr_hist.nextval,
                 r_det.id_drug_presc_det,
                 'A',
                 i_prof.id,
                 i_prof.institution,
                 i_prof.software,
                 g_sysdate_tstz,
                 'DRUG_PRESC_PLAN',
                 r_det.flg_status,
                 g_presc_plan_stat_adm_cancel,
                 'S',
                 i_notes,
                 i_cancel_reason_descr,
                 i_id_cancel_reason,
                 r_det.id_presc_directions);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'DRUG_PRESC_PLAN',
                                          l_rows,
                                          o_error,
                                          table_varchar('FLG_STATUS',
                                                        'DT_CANCEL_TSTZ',
                                                        'ID_PROF_CANCEL',
                                                        'NOTES_CANCEL',
                                                        'ID_CANCEL_REASON',
                                                        'CANCEL_REASON_DESCR'));
        
            --Suppressed planned dose if exists
            DELETE FROM drug_presc_plan dpp
             WHERE dpp.id_drug_presc_det = r_det.id_drug_presc_det
               AND dpp.id_drug_presc_plan =
                   (SELECT MAX(dpp_1.id_drug_presc_plan)
                      FROM drug_presc_plan dpp_1
                     WHERE dpp_1.id_drug_presc_det = r_det.id_drug_presc_det
                       AND dpp_1.flg_status IN (g_presc_plan_stat_req, pk_prescription_int.g_presc_plan_stat_pend));
        
            IF r_det.flg_take_type != 'S'
            THEN
                g_error := 'INSERT INTO DRUG_PRESC_PLAN';
                ts_drug_presc_plan.ins(id_drug_presc_det_in     => r_det.id_drug_presc_det,
                                       dt_plan_tstz_in          => r_det.dt_plan_tstz,
                                       dosage_in                => nvl(r_det.dosage, 0),
                                       flg_status_in            => g_presc_plan_stat_pend,
                                       id_drug_presc_plan_out   => l_presc_dpp,
                                       id_presc_dir_dosefreq_in => r_det.id_presc_dir_dosefreq, --l_id_presc_dir_dosefreq
                                       rows_out                 => l_rows);
            
                t_data_gov_mnt.process_insert(i_lang, i_prof, 'DRUG_PRESC_PLAN', l_rows, o_error);
            
                IF r_det.dpd_status = pk_medication_core.g_presc_det_fin
                THEN
                    UPDATE drug_presc_det dpd
                       SET dpd.flg_status = pk_medication_core.g_presc_det_req
                     WHERE dpd.id_drug_presc_det = r_det.id_drug_presc_det;
                END IF;
            
                pk_medication_core.print_medication_logs('set_medication_alerts 10', pk_medication_core.c_log_debug);
                pk_alertlog.log_debug('CREATED  - Parameters for Alert id :' || 10 || '.' || ' i_id_episode: ' ||
                                      r_det.id_episode || ' i_id_record: ' || l_presc_dpp);
                IF NOT pk_medication_core.set_medication_alerts(i_lang           => i_lang,
                                                                i_prof           => i_prof,
                                                                i_id_episode     => r_det.id_episode,
                                                                i_id_record      => l_presc_dpp,
                                                                i_dt_record      => l_dt_plan,
                                                                i_dpd_flg_status => r_det.dpd_status,
                                                                i_dpp_flg_status => g_presc_plan_stat_pend,
                                                                i_med_type       => g_drug,
                                                                i_alert_message  => r_det.l_med_descr,
                                                                i_institution    => i_prof.institution,
                                                                i_software       => i_prof.software,
                                                                o_error          => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => r_det.id_episode,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                g_error := 'CALL TO PK_PRESCRIPTION_INT.UPDATE_DRUG_PRESC_TASK';
                IF NOT pk_medication_core.update_drug_presc_task(i_lang          => i_lang,
                                                                 i_episode       => r_det.id_episode,
                                                                 i_prof          => i_prof,
                                                                 i_prof_cat_type => NULL,
                                                                 o_error         => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
                END IF;
            
                g_error := 'CALL TO PK_GRID.DELETE_EPIS_GRID_TASK';
                IF NOT
                    pk_grid.delete_epis_grid_task(i_lang => i_lang, i_episode => r_det.id_episode, o_error => o_error)
                THEN
                    raise_application_error(-20001, o_error.ora_sqlerrm);
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
                                              i_function => 'CANCEL_ADM_TAKE',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END cancel_adm_take;
    
    /********************************************************************************************
     * Update cosign columns (not used by Flash).
     *
     * @param i_lang                   Preferred language ID for this professional
     * @param i_prof                   Object (professional ID, institution ID, software ID)
     * @param i_prof_cat_type          Professional's category type
     * @param i_table                  Name of the table to update
     * @param id_table                 ID of the record to update
     * @param i_co_sign                Columns to update
     * @param o_error                  Error message
     *
     * @return                         true or false on success or error
     *
     * @author                         SS
     * @version                        0.1
     * @since                          2007/10/26
    **********************************************************************************************/

    FUNCTION update_co_sign
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_table         IN VARCHAR2,
        id_table        IN NUMBER,
        i_co_sign       IN co_sign_obj,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_diag professional.id_professional%TYPE := i_prof.id;
        l_desc_cat  pk_translation.t_desc_translation;
        l_flg_cat   category.flg_type%TYPE;
        l_error     VARCHAR2(100);
    
        l_rows table_varchar;
    BEGIN
    
        IF i_table = 'DRUG_REQ_DET'
        THEN
            l_error := 'UPDATE drug_req_det 1';
            UPDATE drug_req_det
               SET dt_order        = i_co_sign.dt_order,
                   id_prof_order   = i_co_sign.id_prof_order,
                   id_order_type   = i_co_sign.id_order_type,
                   flg_co_sign     = i_co_sign.flg_co_sign,
                   dt_co_sign      = i_co_sign.dt_co_sign,
                   notes_co_sign   = i_co_sign.notes_co_sign,
                   id_prof_co_sign = i_co_sign.id_prof_co_sign
             WHERE id_drug_req_det = id_table;
        ELSIF i_table = 'DRUG_PRESC_DET'
        THEN
            l_error := 'UPDATE drug_presc_det 2';
            /* <DENORM Fábio> */
            ts_drug_presc_det.upd(id_drug_presc_det_in => id_table,
                                  dt_order_in          => i_co_sign.dt_order,
                                  dt_order_nin         => FALSE,
                                  id_prof_order_in     => i_co_sign.id_prof_order,
                                  id_prof_order_nin    => FALSE,
                                  id_order_type_in     => i_co_sign.id_order_type,
                                  id_order_type_nin    => FALSE,
                                  flg_co_sign_in       => i_co_sign.flg_co_sign,
                                  flg_co_sign_nin      => FALSE,
                                  dt_co_sign_in        => i_co_sign.dt_co_sign,
                                  dt_co_sign_nin       => FALSE,
                                  notes_co_sign_in     => i_co_sign.notes_co_sign,
                                  notes_co_sign_nin    => FALSE,
                                  id_prof_co_sign_in   => i_co_sign.id_prof_co_sign,
                                  id_prof_co_sign_nin  => FALSE,
                                  rows_out             => l_rows);
        
            t_data_gov_mnt.process_update(i_lang,
                                          i_prof,
                                          'DRUG_PRESC_DET',
                                          l_rows,
                                          o_error,
                                          table_varchar('DT_ORDER',
                                                        'ID_PROF_ORDER',
                                                        'ID_ORDER_TYPE',
                                                        'FLG_CO_SIGN',
                                                        'DT_CO_SIGN',
                                                        'NOTES_CO_SIGN',
                                                        'ID_PROF_CO_SIGN'));
        
        ELSIF i_table = 'PRESCRIPTION_PHARM'
        THEN
            l_error := 'UPDATE prescription_pharm 2';
            ts_prescription_pharm.upd(id_prescription_pharm_in => id_table,
                                      dt_order_in              => i_co_sign.dt_order,
                                      dt_order_nin             => FALSE,
                                      id_prof_order_in         => i_co_sign.id_prof_order,
                                      id_prof_order_nin        => FALSE,
                                      id_order_type_in         => i_co_sign.id_order_type,
                                      id_order_type_nin        => FALSE,
                                      flg_co_sign_in           => i_co_sign.flg_co_sign,
                                      flg_co_sign_nin          => FALSE,
                                      dt_co_sign_in            => i_co_sign.dt_co_sign,
                                      dt_co_sign_nin           => FALSE,
                                      notes_co_sign_in         => i_co_sign.notes_co_sign,
                                      notes_co_sign_nin        => FALSE,
                                      id_prof_co_sign_in       => i_co_sign.id_prof_co_sign,
                                      id_prof_co_sign_nin      => FALSE,
                                      rows_out                 => l_rows);
        
            t_data_gov_mnt.process_update(i_lang, i_prof, 'PRESCRIPTION_PHARM', l_rows, o_error);
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
        
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_PRESCRIPTION_INT',
                                              i_function => 'UPDATE_CO_SIGN',
                                              o_error    => o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        
    END update_co_sign;

BEGIN

    -- Log startup
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_found := FALSE;

    g_drug_pend    := 'D';
    g_drug_req     := 'R';
    g_drug_canc    := 'C';
    g_drug_exec    := 'E';
    g_drug_res     := 'F';
    g_drug_part    := 'P';
    g_drug_rejeita := 'J';

    g_drug_det_pend := 'D';
    g_drug_det_req  := 'R';
    g_drug_det_exec := 'E';
    g_drug_det_fini := 'F';
    g_drug_det_part := 'P';
    g_drug_det_canc := 'C';
    g_drug_det_desc := 'I';

    g_drug_sup_prep    := 'E';
    g_drug_sup_ppt     := 'O';
    g_drug_sup_trans   := 'T';
    g_drug_sup_exec    := 'F';
    g_drug_sup_canc    := 'C';
    g_drug_sup_aux     := 'A';
    g_drug_sup_end_aux := 'B';
    g_drug_sup_utente  := 'U';

    g_flg_available := 'Y';

    g_drug_available     := 'Y';
    g_pharma_class_avail := 'Y';
    g_pharma_avail       := 'Y';
    g_drug_form_avail    := 'Y';
    g_drug_route_avail   := 'Y';
    g_drug_execute       := 'R';
    g_drug_freq          := 'M';

    g_icon     := 'I';
    g_date     := 'D';
    g_no_color := 'X';

    g_flg_other := 'O';

    g_room_pref := 'Y';

    g_cancel_rea_area      := 'MEDICATION_CANCEL';
    g_discontinue_rea_area := 'MEDICATION_DISCONTINUE';
    g_hold_rea_area        := 'MEDICATION_HOLD';

    -- NOVAS VARIÁVEIS GLOBAIS PARA A FERRAMENTA DE PRESCRIÇÃO

    g_flg_freq := 'M';
    g_flg_pesq := 'P';
    g_no       := 'N';
    g_yes      := 'Y';
    g_read     := 'R';

    g_flg_int     := 'I';
    g_flg_adm     := 'A';
    g_flg_unidose := 'U';
    g_flg_ext     := 'E';

    g_flg_manip_ext   := 'ME';
    g_flg_manip_int   := 'MI';
    g_flg_dietary_ext := 'DE';
    g_flg_dietary_int := 'DI';

    g_total_return   := 'T';
    g_partial_return := 'D';

    g_presc_take_sos  := 'S';
    g_presc_take_nor  := 'N';
    g_presc_take_uni  := 'U';
    g_presc_take_cont := 'C';
    g_presc_take_eter := 'A';
    g_presc_take_irre := 'P';

    g_flg_temp := 'T';

    g_det_temp   := 'T';
    g_det_req    := 'R';
    g_det_pend   := 'D';
    g_det_exe    := 'E';
    g_det_fin    := 'F';
    g_det_can    := 'C';
    g_det_intr   := 'I';
    g_det_reject := 'J';
    g_det_susp   := 'S';

    g_drug := 'M';

    g_selected := 'S';

    g_flg_time_epis := 'E';
    g_flg_time_next := 'N';
    g_flg_time_betw := 'B';

    g_presc_type_int := 'I';

    g_presc_plan_stat_adm        := 'A';
    g_presc_plan_stat_nadm       := 'N';
    g_presc_plan_stat_pend       := 'D';
    g_presc_plan_stat_req        := 'R';
    g_presc_plan_stat_can        := 'C';
    g_presc_plan_stat_adm_cancel := 'U';

    g_flg_doctor     := 'D';
    g_flg_nurse      := 'N';
    g_flg_pharmacist := 'P';
    g_flg_aux        := 'O';
    g_flg_phys       := 'F';
    g_flg_tec        := 'T';

    g_color_red := 'R';

    ----- header
    g_patient_active     := 'A';
    g_pat_blood_active   := 'A';
    g_default_hplan_y    := 'Y';
    g_hplan_active       := 'A';
    g_epis_cancel        := 'C';
    g_no_triage          := 'N';
    g_epis_diag_act      := 'A';
    g_pat_allergy_cancel := 'C';
    g_pat_habit_cancel   := 'C';
    g_pat_problem_cancel := 'C';
    g_pat_notes_cancel   := 'C';
    g_category_avail     := 'Y';
    g_cat_prof           := 'Y';

    g_movem_term := 'F';

    g_flg_without := 'YF';

    g_inp_software     := 11;
    g_tolerance_time   := 0.003;
    g_drug_presc_det_n := 'N';
    g_drug_presc_det_u := 'U';
    g_drug_presc_det_c := 'C';
    g_drug_presc_det_a := 'A';
    g_drug_presc_det_s := 'S';
    g_flg_co_sign      := 'N';

    g_domain_take := 'DRUG_PRESC_DET.FLG_TAKE_TYPE';
    g_domain_time := 'DRUG_PRESCRIPTION.FLG_TIME';

    g_flg_new_fluid := 'N';
    g_drug_interv   := 'M';

    g_presc_flg_type := 'PRESCRIPTION.FLG_TYPE';

    g_domain_status := 'DRUG_PRESC_DET.FLG_STATUS';

    g_active := 'A';

    g_advanced_input     := 43;
    g_all_institution    := 0;
    g_all_software       := 0;
    g_multichoice_keypad := 'L';
    g_num_keypad         := 'N';
    g_date_keypad        := 'DT';

    g_version := 'PT';

    g_flg_therapeutic := 'T';

    g_drug_presc_det := 'DRUG_PRESC_DET';

    g_dosage := 'P';

    g_min_unit_measure   := 10374;
    g_hours_unit_measure := 1041;
    g_day_unit_measure   := 1039;
    g_week_unit_measure  := 10375;

    g_hour_seconds       := 3600;
    g_minute_seconds     := 60;
    g_day_seconds        := 86400;
    g_week_seconds       := 604800;
    g_presc_det_req_hosp := 'H';
    g_qty_for_24h        := 'D';
    g_total_qty          := 'T';
    g_time_duration      := 'DURATION';
    g_time_freq          := 'FREQUENCY';
    g_flg_type_i         := 'I';

    g_flg_cancel := 'C';

END pk_prescription_int;
/
