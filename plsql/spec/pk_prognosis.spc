/*-- Last Change Revision: $Rev: 2054552 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-13 14:52:34 +0000 (sex, 13 jan 2023) $*/

CREATE OR REPLACE PACKAGE pk_prognosis IS

    TYPE t_rec_prognosis_cda IS RECORD(
        id_epis_prognosis epis_prognosis.id_epis_prognosis%TYPE,
        flg_status        epis_prognosis.flg_status%TYPE,
        desc_status       VARCHAR2(1000 CHAR),
        prognosis_notes   epis_prognosis.prognosis_notes%TYPE,
        dt_reg_str        VARCHAR2(14 CHAR),
        dt_reg_tstz       epis_prognosis.dt_create%TYPE,
        dt_reg_formatted  VARCHAR2(1000 CHAR));

    TYPE t_coll_prognosis_cda IS TABLE OF t_rec_prognosis_cda;

    FUNCTION set_epis_prognosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        i_id_prognosis      IN epis_prognosis.id_prognosis%TYPE,
        i_prognosis_notes   IN epis_prognosis.prognosis_notes%TYPE,
        o_id_epis_prognosis OUT epis_prognosis.id_epis_prognosis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_epis_prognosis
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        i_id_cancel_reason  IN cancel_reason.id_cancel_reason%TYPE,
        i_notes_cancel      IN epis_prognosis.cancel_notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prognosis_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
         o_epis_prognosis    OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_actions           OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_prognosis_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN NUMBER,
        i_scope_type IN VARCHAR2
    ) RETURN t_coll_prognosis_cda
        PIPELINED;


    FUNCTION get_prognosis_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE        
    ) RETURN CLOB;
    
    PROCEDURE validate_job_tstz;

    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);

    g_error        VARCHAR2(2000 CHAR);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_has_error BOOLEAN;

    g_status_active    CONSTANT epis_prognosis.flg_status%TYPE := 'A';
    g_status_inactive  CONSTANT epis_prognosis.flg_status%TYPE := 'I';
    g_status_cancelled CONSTANT epis_prognosis.flg_status%TYPE := 'C';

    g_exception EXCEPTION;
END pk_prognosis;
/
