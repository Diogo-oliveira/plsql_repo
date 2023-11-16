/*-- Last Change Revision: $Rev: 2028446 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_aih_api_ux IS

    FUNCTION get_section_events_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_component_name IN ds_component.internal_name%TYPE,
        o_section        OUT pk_types.cursor_type,
        o_def_events     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_section_data
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_episode      IN episode.id_episode%TYPE,
        i_ds_component IN ds_component.internal_name%TYPE,
        i_aih_simple   IN aih_simple.id_aih_simple%TYPE,
        i_params       IN CLOB,
        o_section      OUT pk_types.cursor_type,
        o_def_events   OUT pk_types.cursor_type,
        o_events       OUT pk_types.cursor_type,
        o_items_values OUT pk_types.cursor_type,
        o_data_val     OUT CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_aih_simple
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_xml        IN CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_aih_special
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_xml        IN CLOB,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_name  CONSTANT VARCHAR2(6 CHAR) := 'PK_AIH';
    g_package_owner CONSTANT VARCHAR2(5 CHAR) := 'ALERT';
    g_error VARCHAR2(1000 CHAR);

    l_exception EXCEPTION;

END pk_aih_api_ux;
/
