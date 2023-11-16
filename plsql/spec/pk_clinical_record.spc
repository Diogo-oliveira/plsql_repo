/*-- Last Change Revision: $Rev: 2028565 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_clinical_record IS

    FUNCTION create_clinical_rec_req
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN cli_rec_req.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_prof_req       IN profissional,
        i_dt_begin       IN VARCHAR2,
        i_notes          IN cli_rec_req.notes%TYPE,
        i_flg_time       IN cli_rec_req.flg_time%TYPE,
        i_prof_cat_type  IN category.flg_type%TYPE,
        i_id_clin_record IN table_number,
        i_notes_det      IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cli_rec_req_det
    (
        i_lang               IN language.id_language%TYPE,
        i_id_cli_rec_req_det IN cli_rec_req_mov.id_cli_rec_req_det%TYPE,
        i_notes              IN cli_rec_req_mov.notes%TYPE,
        i_prof               IN profissional,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_cli_rec_req
    (
        i_lang               IN language.id_language%TYPE,
        i_id_cli_rec_req     IN cli_rec_req.id_cli_rec_req%TYPE,
        i_id_cli_rec_req_det IN cli_rec_req_det.id_cli_rec_req_det%TYPE,
        i_prof               IN profissional,
        i_prof_cat_type      IN category.flg_type%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_clin_rec_req_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_clin_rec_req_task
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_cli_rec_canc cli_rec_req.flg_status%TYPE;
    g_cli_rec_pend cli_rec_req.flg_status%TYPE;
    g_cli_rec_req  cli_rec_req.flg_status%TYPE;
    g_cli_rec_exec cli_rec_req.flg_status%TYPE;
    g_cli_rec_par  cli_rec_req.flg_status%TYPE;
    g_cli_rec_term cli_rec_req.flg_status%TYPE;

    g_cli_rec_det_canc cli_rec_req_det.flg_status%TYPE;
    g_cli_rec_det_pend cli_rec_req_det.flg_status%TYPE;
    g_cli_rec_det_req  cli_rec_req_det.flg_status%TYPE;
    g_cli_rec_det_exec cli_rec_req_det.flg_status%TYPE;
    g_cli_rec_det_par  cli_rec_req_det.flg_status%TYPE;
    g_cli_rec_det_term cli_rec_req_det.flg_status%TYPE;

    g_cli_rec_mov_exec  cli_rec_req_mov.flg_status%TYPE;
    g_cli_rec_mov_ppt   cli_rec_req_mov.flg_status%TYPE;
    g_cli_rec_mov_trans cli_rec_req_mov.flg_status%TYPE;
    g_cli_rec_mov_term  cli_rec_req_mov.flg_status%TYPE;
    g_cli_rec_mov_canc  cli_rec_req_mov.flg_status%TYPE;

    g_flg_time_epis cli_rec_req.flg_time%TYPE;
    --G_FLG_TIME_NEXT     CLI_REC_REQ.FLG_TIME%TYPE;

    g_icon     VARCHAR2(1);
    g_date     VARCHAR2(1);
    g_no_color VARCHAR2(1);
END;
/
