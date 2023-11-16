/*-- Last Change Revision: $Rev: 2028803 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_medication_workflow IS

    -- Author  : RUI.MARANTE
    -- Created : 06-01-2009 09:56:07
    -- Purpose : workflow management

    -- Public type declarations

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations
    FUNCTION get_states_for_scope
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope      IN wfl_state_scope.id_scope%TYPE,
        o_states_cur OUT pk_types.cursor_type,
        o_error      OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION is_state_related
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_from_state IN wfl_state_relate.state%TYPE,
        i_to_state   IN wfl_state_relate.next_state%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_states
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_type     IN wfl_state_scope.flg_type%TYPE,
        i_generic_name IN wfl_state.generic_name%TYPE,
        i_market       IN wfl_state_scope.market%TYPE
    ) RETURN wfl_state.id_state%TYPE;

    FUNCTION get_related_states
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_state              IN wfl_state.id_state%TYPE,
        o_related_states_cur OUT pk_types.cursor_type,
        o_error              OUT VARCHAR2
    ) RETURN BOOLEAN;

    FUNCTION get_scopes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        o_scopes_cur OUT pk_types.cursor_type,
        o_error      OUT VARCHAR2
    ) RETURN BOOLEAN;

    PROCEDURE get_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_profile IN profile_template.id_profile_template%TYPE,
        i_actions IN table_number,
        o_actions OUT pk_types.cursor_type
    );

    FUNCTION get_id_state_from_old_flag
    (
        i_scope    IN wfl_state_scope.id_scope%TYPE,
        i_old_flag IN wfl_state.old_flg%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_old_flag_from_state_id(i_id_state IN wfl_state.id_state%TYPE) RETURN VARCHAR2;

    FUNCTION get_state_translation
    (
        i_lang                IN language.id_language%TYPE,
        i_id_state            IN wfl_state.id_state%TYPE,
        i_flg_complete_transl IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    -- ***** - ***** - ***** - ***** - ***** - ***** - ***** - ***** - ***** - ***** - ***** - ***** -
    -- ***** CONFIGURATION FUNCTIONS!!!!!!!! *****

    PROCEDURE conf_prep_without_validation
    (
        i_id_market IN market.id_market%TYPE,
        i_set_on    IN VARCHAR2 DEFAULT 'N', -- Y - activate  || N - deactivate
        i_flg_type  IN VARCHAR2 -- A | I | U 
    );

    PROCEDURE conf_default_workflow
    (
        i_id_market         IN market.id_market%TYPE,
        i_id_default_market IN market.id_market%TYPE DEFAULT 1,
        i_force_update      IN VARCHAR2 DEFAULT 'N'
    );

END pk_medication_workflow;
/
