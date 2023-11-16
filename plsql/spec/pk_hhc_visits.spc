/*-- Last Change Revision: $Rev: 1940287 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2020-03-13 17:24:41 +0000 (sex, 13 mar 2020) $*/

CREATE OR REPLACE PACKAGE pk_hhc_visits IS

    --**************************************************************
    -- aux function to validate actions provided on screen
    FUNCTION check_inactivate_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_state IN table_varchar,
        i_action    IN VARCHAR2
    ) RETURN VARCHAR2 ;

    --**************************************************************
    -- get actions available for screen
    FUNCTION get_visits_actions
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_state IN table_varchar,
        i_subject   IN VARCHAR2,
        o_actions   OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    --**************************************************************
    -- change status of visits ( scheduled, undo )
    FUNCTION set_visit_status
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_ids       IN table_number,
        i_action    IN VARCHAR2,
        i_id_reason IN NUMBER,
        i_rea_note  IN VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_hhc_visits;
/

