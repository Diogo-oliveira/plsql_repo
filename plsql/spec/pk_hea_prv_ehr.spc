/*-- Last Change Revision: $Rev: 1857962 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-30 11:49:08 +0100 (seg, 30 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_ehr IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var;

    /**
    * Returns the ehr value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_patient          Patient Id
    * @param i_id_child_episode    Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_epis_type        Episode type Id
    * @param i_id_profile          Profile template Id
    * @param i_flg_area            System application area flag
    * @param i_tag                 Tag to be replaced
    * @param o_data_rec            Tag's data
    *
    * @return                      The ehr value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_child_episode IN episode.id_episode%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_id_profile       IN profile_template.id_profile_template%TYPE,
        i_flg_area         IN sys_application_area.flg_area%TYPE,
        i_tag              IN header_tag.internal_name%TYPE,
        o_data_rec         OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the ehr value for the tag given as parameter.
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    * @param i_id_patient          Patient Id
    * @param i_id_episode          Episode Id
    * @param i_id_child_episode    Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_epis_type        Episode type Id
    * @param i_id_profile          Profile template Id
    * @param i_flg_area            System application area flag
    * @param i_tag                 Tag to be replaced
    *
    * @return                      The ehr value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_child_episode IN episode.id_episode%TYPE,
        i_id_epis_type     IN epis_type.id_epis_type%TYPE,
        i_id_profile       IN profile_template.id_profile_template%TYPE,
        i_flg_area         IN sys_application_area.flg_area%TYPE,
        i_tag              IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the icon name with the prefix "icon-" , EMR-463
    *
    * @param i_icon_name           Icon name
    *
    * @return                      Icon name with the prefix "icon-"
    *
    * @author   Alexander Camilo
    * @version  1
    * @since    2018/03/15
    */
    FUNCTION set_icon_prefix(i_icon_name IN VARCHAR2) RETURN VARCHAR2;

    /**
    * Returns the EHR value for blood type (NEW)
    *
    * @param i_flg_area            System application area flag
    * @param o_blood_type          
    *
    * @return                      The EHR value
    *
    * @author  Fábio Martins
    * @version  2.7
    * @since    2018/02/22
    */
    FUNCTION get_blood_type_new
    (
        i_flg_area   IN sys_application_area.flg_area%TYPE,
        o_blood_type OUT VARCHAR
    ) RETURN BOOLEAN;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_id_patient patient.id_patient%TYPE;

    g_habits             NUMBER;
    g_allergies          NUMBER;
    g_prev_med_hist      NUMBER;
    g_prev_epis          NUMBER;
    g_blood_type         VARCHAR2(100 CHAR);
    g_relev_notes        NUMBER;
    g_adv_dir_has        VARCHAR2(1 CHAR);
    g_adv_dir_shortcut   NUMBER;
    g_adv_dir_alert      VARCHAR2(1 CHAR);
    g_epis_type_software NUMBER;
    g_ehr_access         VARCHAR2(1 CHAR);
    g_shortcut_area      VARCHAR2(32 CHAR);
    g_epis_is_cancelled  VARCHAR2(1 CHAR);
    g_pat_alerts_has     VARCHAR2(1 CHAR);
END;
/
