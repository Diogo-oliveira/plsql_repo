/*-- Last Change Revision: $Rev: 2005689 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-17 16:23:02 +0000 (seg, 17 jan 2022) $*/

CREATE OR REPLACE PACKAGE pk_ehr_common IS
    /**
    * Returns the visit name based on the EPIS_TYPE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_epis_type EPIS_TYPE identifier.
    * @param i_is_event     'Y' if is an EHR event. 'N' if is a visit.
    *
    * @return  the visit name based on the EPIS_TYPE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_name_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_is_event     IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /**
    * Returns the visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_sep          The separator for the visit type.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_type_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_sep          IN VARCHAR2,
        o_title        OUT VARCHAR2,
        o_value        OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the visit type based on the EPISODE identifier
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_sep          The separator for the visit type.
    * @param o_title        The title of the visit type.
    * @param o_value        The description of the visit type.
    * @param o_error        Message to be shown to the user in case of error.
    *
    * @return  the visit type based on the EPISODE identifier
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_visit_type_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_sep          IN VARCHAR2
    ) RETURN VARCHAR;

    /**
    * Returns documentation elements for the given DOC_AREA identifier and the given EPISODE identifier 
    *
    * @param i_lang         Language identifier.
    * @param i_prof         The professional record.
    * @param i_id_episode   EPISODE identifier.
    * @param i_id_epis_type EPIS_TYPE identifier.
    * @param i_id_doc_area  DOC_AREA identifier.
    *
    * @return  a table of varchar with the documentation values
    *
    * @author   Eduardo Lourenço
    * @version  2.4.3
    * @since    2008/05/17
    */
    FUNCTION get_doc_area_by_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_epis_type IN episode.id_epis_type%TYPE,
        i_id_doc_area  IN doc_area.id_doc_area%TYPE
    ) RETURN table_varchar;

    /* Stores log error messages. */
    g_error VARCHAR2(4000);
    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_epis_type_outp              CONSTANT epis_type.id_epis_type%TYPE := 1;
    g_epis_type_edis              CONSTANT epis_type.id_epis_type%TYPE := 2;
    g_epis_type_oris              CONSTANT epis_type.id_epis_type%TYPE := 4;
    g_epis_type_inp               CONSTANT epis_type.id_epis_type%TYPE := 5;
    g_epis_type_care              CONSTANT epis_type.id_epis_type%TYPE := 8;
    g_epis_type_sap               CONSTANT epis_type.id_epis_type%TYPE := 9;
    g_epis_type_pp                CONSTANT epis_type.id_epis_type%TYPE := 11;
    g_epis_type_enf_care          CONSTANT epis_type.id_epis_type%TYPE := 14;
    g_epis_type_enf_outp          CONSTANT epis_type.id_epis_type%TYPE := 16;
    g_epis_type_enf_pp            CONSTANT epis_type.id_epis_type%TYPE := 17;
    g_epis_type_social            CONSTANT epis_type.id_epis_type%TYPE := 22;
    g_epis_type_dietitian         CONSTANT epis_type.id_epis_type%TYPE := 18;
    g_epis_type_rehab_session     CONSTANT epis_type.id_epis_type%TYPE := 15;
    g_epis_type_rehab_appointment CONSTANT epis_type.id_epis_type%TYPE := 25;
    g_epis_type_psychologist      CONSTANT epis_type.id_epis_type%TYPE := 26;
    g_epis_type_resp_therapist    CONSTANT epis_type.id_epis_type%TYPE := 27;
    g_epis_type_cdc_appointment   CONSTANT epis_type.id_epis_type%TYPE := 28;
    g_epis_type_home_health_care  CONSTANT epis_type.id_epis_type%TYPE := 50;
    g_epis_type_speech_therapy    CONSTANT epis_type.id_epis_type%TYPE := 29;
    g_epis_type_occup_therapy     CONSTANT epis_type.id_epis_type%TYPE := 30;

    g_epis_type_lab               CONSTANT epis_type.id_epis_type%TYPE := 12;
    g_epis_type_rad               CONSTANT epis_type.id_epis_type%TYPE := 13;
    g_epis_type_exam              CONSTANT epis_type.id_epis_type%TYPE := 21;


    g_doc_area_hpi doc_area.id_doc_area%TYPE := pk_summary_page.g_doc_area_hist_ill;
    g_doc_area_ros doc_area.id_doc_area%TYPE := pk_summary_page.g_doc_area_rev_sys;
    g_doc_area_phy doc_area.id_doc_area%TYPE := pk_summary_page.g_doc_area_phy_exam;

    g_software_all  CONSTANT software.id_software%TYPE := 0;
    g_software_outp CONSTANT software.id_software%TYPE := 1;
    g_software_oris CONSTANT software.id_software%TYPE := 2;
    g_software_care CONSTANT software.id_software%TYPE := 3;
    g_software_edis CONSTANT software.id_software%TYPE := 8;
    g_software_sap  CONSTANT software.id_software%TYPE := 29;
    g_software_inp  CONSTANT software.id_software%TYPE := 11;
    g_software_pp   CONSTANT software.id_software%TYPE := 12;
    g_software_ss   CONSTANT software.id_software%TYPE := 24;

END pk_ehr_common;
/
