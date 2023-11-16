/*-- Last Change Revision: $Rev: 2028431 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_transfer_institution IS

    g_package_name VARCHAR2(32);

    FUNCTION error_handling
    (
        i_lang           IN language.id_language%TYPE,
        i_func_proc_name IN VARCHAR2,
        i_error          IN VARCHAR2,
        i_sqlerror       IN VARCHAR2,
        i_rollback       IN BOOLEAN,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        o_error.err_desc := g_package_name || '.' || i_func_proc_name || ' / ' || i_error;
    
        pk_alert_exceptions.raise_error(error_code_in => SQLCODE,
                                        text_in       => i_error,
                                        name1_in      => 'OWNER',
                                        value1_in     => 'ALERT',
                                        name2_in      => 'PACKAGE',
                                        value2_in     => g_package_name,
                                        name3_in      => 'FUNCTION',
                                        value3_in     => i_func_proc_name);
    
        IF i_rollback = TRUE
        THEN
            pk_utils.undo_changes;
        END IF;
    
        RETURN FALSE;
    END error_handling;

    FUNCTION ins_transfer_institution
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_creation_tstz    IN transfer_institution.dt_creation_tstz%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_id_institution_orig IN transfer_institution.id_institution_origin%TYPE,
        i_id_institution_dest IN transfer_institution.id_institution_dest%TYPE,
        i_id_transp_entity    IN transfer_institution.id_transp_entity%TYPE,
        i_notes               IN transfer_institution.notes%TYPE,
        i_flg_status          IN transfer_institution.flg_status%TYPE,
        i_id_dep_clin_serv    IN transfer_institution.id_dep_clin_serv%TYPE,
        i_id_transfer_option  IN transfer_institution.id_transfer_option%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ti_rec transfer_institution%ROWTYPE;
        l_rowids table_varchar := table_varchar();
    BEGIN
    
        l_ti_rec.id_institution_origin := i_id_institution_orig;
        l_ti_rec.id_institution_dest   := i_id_institution_dest;
        l_ti_rec.dt_creation_tstz      := i_dt_creation_tstz;
        l_ti_rec.id_transp_entity      := i_id_transp_entity;
        l_ti_rec.notes                 := i_notes;
        l_ti_rec.flg_status            := i_flg_status;
        l_ti_rec.id_prof_reg           := i_prof.id;
        l_ti_rec.id_episode            := i_id_episode;
        l_ti_rec.id_patient            := i_id_patient;
        l_ti_rec.id_dep_clin_serv      := i_id_dep_clin_serv;
        l_ti_rec.id_transfer_option    := i_id_transfer_option;
    
        ts_transfer_institution.ins(rec_in => l_ti_rec, rows_out => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TRANSFER_INSTITUTION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'INS_TRANSFER_INSTITUTION', NULL, SQLERRM, TRUE, o_error);
    END ins_transfer_institution;

    FUNCTION upd_transfer_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_dt_creation      IN transfer_institution.dt_creation_tstz%TYPE,
        i_prof_begin       IN transfer_institution.id_prof_begin%TYPE,
        i_prof_end         IN transfer_institution.id_prof_end%TYPE,
        i_prof_cancel      IN transfer_institution.id_prof_cancel%TYPE,
        i_dt_begin         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_cancel        IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_status       IN ti_log.flg_status%TYPE,
        i_notes_cancel     IN transfer_institution.notes_cancel%TYPE,
        i_id_cancel_reason IN transfer_institution.id_cancel_reason%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar := table_varchar();
    BEGIN
    
        ts_transfer_institution.upd(id_episode_in        => i_id_episode,
                                    dt_creation_tstz_in  => i_dt_creation,
                                    id_prof_begin_in     => i_prof_begin,
                                    id_prof_begin_nin    => TRUE,
                                    id_prof_end_in       => i_prof_end,
                                    id_prof_end_nin      => TRUE,
                                    id_prof_cancel_in    => i_prof_cancel,
                                    id_prof_cancel_nin   => TRUE,
                                    dt_begin_tstz_in     => i_dt_begin,
                                    dt_begin_tstz_nin    => TRUE,
                                    dt_end_tstz_in       => i_dt_end,
                                    dt_end_tstz_nin      => TRUE,
                                    dt_cancel_tstz_in    => i_dt_cancel,
                                    dt_cancel_tstz_nin   => TRUE,
                                    flg_status_in        => i_flg_status,
                                    flg_status_nin       => FALSE,
                                    notes_cancel_in      => i_notes_cancel,
                                    notes_cancel_nin     => TRUE,
                                    id_cancel_reason_in  => i_id_cancel_reason,
                                    id_cancel_reason_nin => TRUE,
                                    rows_out             => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'TRANSFER_INSTITUTION',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN error_handling(i_lang, 'UPD_TRANSFER_INSTITUTION', NULL, SQLERRM, TRUE, o_error);
    END upd_transfer_institution;

BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);

END t_transfer_institution;
/
