/*-- Last Change Revision: $Rev: 2028491 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_progress_notes IS

    /**######################################################
      GLOBALS
    ######################################################**/
    g_owner   VARCHAR2(50);
    g_package VARCHAR2(50);
    g_error   VARCHAR2(1000 CHAR);
    g_exception EXCEPTION;
    g_add VARCHAR2(1 CHAR) := 'A';

    FUNCTION interface_ins_prog_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_flg_action      IN VARCHAR2,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd     IN VARCHAR2 DEFAULT g_add,
        i_flg_task_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_reg          IN VARCHAR2,
        i_pn_soap_block   IN table_number,
        i_pn_data_block   IN table_number,
        i_free_text       IN table_varchar,
        i_id_task         IN table_table_number,
        i_id_task_type    IN table_table_number,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION interface_ins_prog_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_flg_action      IN VARCHAR2,
        i_id_pn_note_type IN epis_pn.id_pn_note_type%TYPE,
        i_flg_app_upd     IN VARCHAR2 DEFAULT g_add,
        i_flg_task_parent IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dt_reg          IN VARCHAR2,
        i_pn_soap_block   IN table_number,
        i_pn_data_block   IN table_number,
        i_free_text       IN table_varchar,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION interface_cancel_prog_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_cancel_reason IN NUMBER DEFAULT NULL,
        i_notes_cancel  IN VARCHAR2 DEFAULT NULL,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_progress_notes;
/
