/*-- Last Change Revision: $Rev: 2027743 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:10 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_sr_reset AS

    /********************************************************************************************
    * Actualiza as datas/horas dos agendamentos do Bloco Operatório com a data/hora do sistema, 
    *   de forma a que possamos ter sempre nas grelhas os agendamentos do dia.
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/04/10
       ********************************************************************************************/

    FUNCTION sr_act_schedule_date RETURN BOOLEAN IS
    
        l_rowids table_varchar;
        l_error  t_error_out;
    
        CURSOR c1 IS
            SELECT sr.id_schedule_sr,
                   s.rowid                   linha_s,
                   sr.rowid                  linha_sr,
                   r.rowid                   linha_r,
                   rec.rowid                 linha_rec,
                   sr.dt_target_tstz,
                   sr.dt_interv_preview_tstz,
                   r.dt_start_tstz,
                   sr.id_episode,
                   sr.id_institution
              FROM schedule s, schedule_sr sr, room_scheduled r, sr_surgery_record rec
             WHERE sr.id_schedule = s.id_schedule
               AND sr.id_institution != g_instit_lixo
               AND r.id_schedule(+) = s.id_schedule
               AND rec.id_schedule_sr(+) = sr.id_schedule_sr
             ORDER BY sr.id_episode;
    
        CURSOR c3 IS
            SELECT ROWID linha, dt_start_tstz, dt_end_tstz, id_institution
              FROM sr_prof_recov_schd;
    
    BEGIN
        FOR i IN c1
        LOOP
            g_error := 'UPDATE SCHEDULE_SR';
            pk_alertlog.log_debug(g_error);
            l_rowids := table_varchar();
            ts_schedule_sr.upd(dt_target_tstz_in          => (pk_date_utils.trunc_insttimezone(profissional(1,
                                                                                                            i.id_institution,
                                                                                                            g_soft_oris),
                                                                                               current_timestamp,
                                                                                               'DD') +
                                                             (i.dt_target_tstz -
                                                             pk_date_utils.trunc_insttimezone(profissional(1,
                                                                                                             i.id_institution,
                                                                                                             g_soft_oris),
                                                                                                i.dt_target_tstz,
                                                                                                'DD'))),
                               dt_target_tstz_nin         => FALSE,
                               dt_interv_preview_tstz_in  => (pk_date_utils.trunc_insttimezone(profissional(1,
                                                                                                            i.id_institution,
                                                                                                            g_soft_oris),
                                                                                               current_timestamp,
                                                                                               'DD') +
                                                             (i.dt_interv_preview_tstz -
                                                             pk_date_utils.trunc_insttimezone(profissional(1,
                                                                                                             i.id_institution,
                                                                                                             g_soft_oris),
                                                                                                i.dt_interv_preview_tstz,
                                                                                                'DD'))),
                               dt_interv_preview_tstz_nin => FALSE,
                               where_in                   => 'ROWID = ' || i.linha_sr,
                               rows_out                   => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang         => 2,
                                          i_prof         => profissional(1, i.id_institution, g_soft_oris),
                                          i_table_name   => 'SCHEDULE_SR',
                                          i_rowids       => l_rowids,
                                          o_error        => l_error,
                                          i_list_columns => table_varchar('DT_TARGET_TSTZ', 'DT_INTERV_PREVIEW_TSTZ'));
        
            IF i.dt_start_tstz IS NOT NULL
            THEN
                g_error := 'UPDATE ROOM_SCHEDULED';
                pk_alertlog.log_debug(g_error);
                UPDATE room_scheduled
                   SET dt_start_tstz = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                        current_timestamp,
                                                                        'DD') +
                                       (i.dt_start_tstz -
                                        pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                         i.dt_start_tstz,
                                                                         'DD'))
                 WHERE ROWID = i.linha_r;
            END IF;
        
            --Registo de intervenção
            g_error := 'UPDATE SR_SURGERY_RECORD';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_surgery_record
               SET dt_anest_start_tstz = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_anest_start_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_anest_start_tstz,
                                                                           'DD')),
                   dt_anest_end_tstz   = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_anest_end_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_anest_end_tstz,
                                                                           'DD')),
                   dt_sr_entry_tstz    = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_sr_entry_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_sr_entry_tstz,
                                                                           'DD')),
                   dt_sr_exit_tstz     = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_sr_exit_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_sr_exit_tstz,
                                                                           'DD')),
                   dt_room_entry_tstz  = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_room_entry_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_room_entry_tstz,
                                                                           'DD')),
                   dt_room_exit_tstz   = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_room_exit_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_room_exit_tstz,
                                                                           'DD')),
                   dt_rcv_entry_tstz   = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_rcv_entry_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_rcv_entry_tstz,
                                                                           'DD')),
                   dt_rcv_exit_tstz    = pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                          current_timestamp,
                                                                          'DD') +
                                         (dt_rcv_exit_tstz -
                                          pk_date_utils.trunc_insttimezone(profissional(1, i.id_institution, g_soft_oris),
                                                                           dt_rcv_exit_tstz,
                                                                           'DD'))
             WHERE ROWID = i.linha_rec;
        
        END LOOP;
    
        FOR x IN c3
        LOOP
            g_error := 'UPDATE SR_PROF_RECOV_SCHD';
            pk_alertlog.log_debug(g_error);
            UPDATE sr_prof_recov_schd
               SET dt_start_tstz = pk_date_utils.trunc_insttimezone(profissional(1, x.id_institution, g_soft_oris),
                                                                    current_timestamp,
                                                                    'DD') +
                                   (x.dt_start_tstz -
                                    pk_date_utils.trunc_insttimezone(profissional(1, x.id_institution, g_soft_oris),
                                                                     x.dt_start_tstz,
                                                                     'DD')),
                   dt_end_tstz   = pk_date_utils.trunc_insttimezone(profissional(1, x.id_institution, g_soft_oris),
                                                                    current_timestamp,
                                                                    'DD') +
                                   (x.dt_end_tstz -
                                    pk_date_utils.trunc_insttimezone(profissional(1, x.id_institution, g_soft_oris),
                                                                     x.dt_end_tstz,
                                                                     'DD'))
             WHERE ROWID = x.linha;
        
        END LOOP;
    
        --Actualiza salas
        g_error := 'UPDATE SR_ROOM_STATUS';
        pk_alertlog.log_debug(g_error);
        UPDATE sr_room_status
           SET dt_status_tstz = pk_date_utils.trunc_insttimezone(profissional(1, 2, g_soft_oris),
                                                                 current_timestamp,
                                                                 'DD') +
                                (dt_status_tstz -
                                 pk_date_utils.trunc_insttimezone(profissional(1, 2, g_soft_oris), dt_status_tstz, 'DD'))
         WHERE dt_status_tstz IS NOT NULL;
    
        COMMIT;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END sr_act_schedule_date;

END pk_sr_reset;
/
