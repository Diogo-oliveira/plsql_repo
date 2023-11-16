/*-- Last Change Revision: $Rev: 2029425 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE t_transfer_institution IS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END t_transfer_institution;
/
