CREATE OR REPLACE PACKAGE pk_prognosis_ux IS

    -- Author  : ELISABETE.BUGALHO
    -- Created : 10/01/2023 08:59:12
    -- Purpose : UX Layer for prognosis

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
    
        FUNCTION get_prognosis_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_epis_prognosis    OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

END pk_prognosis_ux;
