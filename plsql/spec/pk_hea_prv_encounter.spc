/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_encounter IS

    /**
    * Returns the label for 'Encounter date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_time_spent
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Encounter date'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    12-10-2009
    */
    FUNCTION get_encounter_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the episode/encounter value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_encounter         Encounter ID
    * @param i_id_epis_type         Episode type Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data    
    *
    * @return                       The episode value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_area     IN sys_application_area.flg_area%TYPE,
        i_tag          IN header_tag.internal_name%TYPE,
        o_data_rec     OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the episode value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_encounter         Encounter ID
    * @param i_id_epis_type         Episode type Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The encounter value
    *
    * @author   Elisabete Bugalho
    * @version  2.5.0.7
    * @since    09-10-2009
    */
    FUNCTION get_value
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_encounter IN epis_encounter.id_epis_encounter%TYPE,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_area     IN sys_application_area.flg_area%TYPE,
        i_tag          IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_lang language.id_language%TYPE;
    g_prof profissional;

    g_mng_plan_a          VARCHAR2(1) := 'A';
    g_domain_enc_flg_type sys_domain.code_domain%TYPE := 'EPIS_ENCOUNTER.FLG_TYPE';
END;
/
