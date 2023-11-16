/*-- Last Change Revision: $Rev: 2048034 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-10-20 15:46:34 +0100 (qui, 20 out 2022) $*/

CREATE OR REPLACE PACKAGE pk_sample_text IS

    g_stext_avail      sample_text.flg_available%TYPE;
    g_stext_type_avail sample_text_type.flg_available%TYPE;
    g_error            VARCHAR2(4000); -- Localização do erro 
    g_found            BOOLEAN;

    g_stext_prof_cancel sample_text_prof.flg_status%TYPE;
    g_stext_prof_active sample_text_prof.flg_status%TYPE;

    g_selected VARCHAR2(1);

    TYPE rec_sample_text IS RECORD(
        rank         sample_text.rank%TYPE,
        title        pk_translation.t_desc_translation,
        text         pk_translation.t_desc_translation,
        code_icd     sample_text.code_icd%TYPE,
        id_diagnosis sample_text.id_diagnosis%TYPE,
        flg_class    sample_text.flg_class%TYPE);

    TYPE cursor_sample IS REF CURSOR RETURN rec_sample_text;

    PROCEDURE open_my_cursor(i_cursor IN OUT cursor_sample);

    FUNCTION get_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT cursor_sample,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_text_epis
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_text_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN alert.profissional,
        o_sample_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_sample_text_prof
    (
        i_lang        IN language.id_language%TYPE,
        i_sample_text IN sample_text_prof.id_sample_text_prof%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_sample_text_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_id_sample_text   IN sample_text_prof.id_sample_text_prof%TYPE,
        i_sample_text_type IN sample_text_prof.id_sample_text_type%TYPE,
        i_prof             IN alert.profissional,
        i_title            IN sample_text_prof.title_sample_text_prof%TYPE,
        i_text             IN sample_text_prof.desc_sample_text_prof%TYPE,
        i_rank             IN sample_text_prof.rank%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sample_text_det
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_prof IN sample_text_prof.id_sample_text_prof%TYPE,
        i_prof             IN alert.profissional,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_large_sample_text
    (
        i_lang             IN language.id_language%TYPE,
        i_sample_text_type IN sample_text_type.intern_name_sample_text_type%TYPE,
        i_patient          IN patient.id_patient%TYPE,
        i_prof             IN alert.profissional,
        i_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        o_sample_text      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_sample_text
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    --***********************************************************************
    FUNCTION get_sample_text_detail
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_area        IN VARCHAR2,
        i_sample_text IN NUMBER,
        o_detail      OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_stext_values
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_patient        IN patient.id_patient%TYPE,
        i_action         IN NUMBER, -- edit, new, submit
        i_root_name      IN VARCHAR2, -- root of dynamic screen
        i_curr_component IN NUMBER,
        i_tbl_id_pk      IN table_number, -- id necessary for identifying pk for editing
        i_tbl_mkt_rel    IN table_number, -- components needed for default/edit
        i_value          IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_sample_text_area
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_core_domain;

    FUNCTION get_dyn_edit2_values
    (
        i_lang       IN NUMBER,
        i_prof           IN profissional,
        i_id_episode IN NUMBER,
        i_id_patient IN NUMBER,
        --
        --i_id_stp     IN NUMBER,
        i_id_stext      IN NUMBER,
        i_id_stext_type IN NUMBER,
        --
        i_root_name IN VARCHAR2
    ) RETURN t_tbl_ds_get_value;

END pk_sample_text;
