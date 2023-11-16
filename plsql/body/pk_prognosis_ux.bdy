CREATE OR REPLACE PACKAGE BODY pk_prognosis_ux IS
    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);

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
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_prognosis.set_epis_prognosis(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_episode           => i_episode,
                                               i_id_epis_prognosis => i_id_epis_prognosis,
                                               i_id_prognosis      => i_id_prognosis,
                                               i_prognosis_notes   => i_prognosis_notes,
                                               o_id_epis_prognosis => o_id_epis_prognosis,
                                               o_error             => o_error);
    
    END set_epis_prognosis;

    FUNCTION get_prognosis_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_prognosis IN epis_prognosis.id_epis_prognosis%TYPE,
        o_epis_prognosis    OUT NOCOPY pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        RETURN pk_prognosis.get_prognosis_notes(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_id_epis_prognosis => i_id_epis_prognosis,
                                                o_epis_prognosis    => o_epis_prognosis,
                                                o_error             => o_error);
    END get_prognosis_notes;
BEGIN
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_prognosis_ux;
/
