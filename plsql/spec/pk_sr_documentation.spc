/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_sr_documentation AS

    /**************************************************************************
    * Sets documentation values associated with an area (doc_area)            *
    * of a template (doc_template).                                           *
    * Allows for new, edit and agree epis documentation.                      *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_prof_cat_type              professional category               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_flg_type                   A Agree, E edit, N - new            *
    * @param i_id_documentation           array with id documentation,        *
    * @param i_id_doc_element             array with doc elements             *
    * @param i_id_doc_element_crit        array with doc elements crit        *
    * @param i_value                      array with values                   *
    * @param i_notes                      note                                *
    * @param i_id_doc_element_qualif      array with doc elements qualif      *
    * @param i_epis_context               context id (Ex:id_interv_presc_det, *
    *                                     id_exam...)                         *
    * @param i_summary_and_notes          template summary to be included on  *
    *                                     clinical notes                      *
    * @param i_episode_context            context episode id  used in         *
    *                                     preoperative ORIS area by OUTP, INP,*
    *                                     EDIS                                *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_flg_show                   Flag to show warn message           *
    * @param o_msg                        Message to be displayde in popup    *
    * @param o_msg_title                  Title do message window             *
    * @param o_button                     Type of button on popup msg         *
    * @param o_epis_documentation         Created epis documentation id       *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/09/07                              *
    **************************************************************************/
    FUNCTION set_sr_epis_documentation
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_prof_cat_type         IN category.flg_type%TYPE,
        i_epis                  IN episode.id_episode%TYPE,
        i_doc_area              IN doc_area.id_doc_area%TYPE,
        i_doc_template          IN doc_template.id_doc_template%TYPE,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_type              IN VARCHAR2,
        i_id_documentation      IN table_number,
        i_id_doc_element        IN table_number,
        i_id_doc_element_crit   IN table_number,
        i_value                 IN table_varchar,
        i_notes                 IN epis_documentation.notes%TYPE,
        i_id_doc_element_qualif IN table_table_number,
        i_epis_context          IN epis_documentation.id_epis_context%TYPE,
        i_summary_and_notes     IN epis_recomend.desc_epis_recomend_clob%TYPE,
        i_episode_context       IN epis_documentation.id_episode_context%TYPE,
        i_flg_val_group         IN sr_surgery_validation.flg_group%TYPE,
        i_test                  IN VARCHAR2,
        i_vs_element_list       IN table_number DEFAULT NULL,
        i_vs_save_mode_list     IN table_varchar DEFAULT NULL,
        i_vs_list               IN table_number DEFAULT NULL,
        i_vs_value_list         IN table_number DEFAULT NULL,
        i_vs_uom_list           IN table_number DEFAULT NULL,
        i_vs_scales_list        IN table_number DEFAULT NULL,
        i_vs_date_list          IN table_varchar DEFAULT NULL,
        i_vs_read_list          IN table_number DEFAULT NULL,
        i_id_edit_reason        IN table_number DEFAULT NULL,
        i_notes_edit            IN table_clob DEFAULT NULL,
        o_flg_show              OUT VARCHAR2,
        o_msg                   OUT VARCHAR2,
        o_msg_title             OUT VARCHAR2,
        o_button                OUT VARCHAR2,
        o_epis_documentation    OUT epis_documentation.id_epis_documentation%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Cancels an episode documentation                                        *
    *                                                                         *
    * @param i_lang                       language id                         *
    * @param i_prof                       professional, software and          *
    *                                     institution ids                     *
    * @param i_epis                       Episode Id                          *
    * @param i_epis_documentation         epis documentation id               *
    * @param i_doc_area                   doc_area id                         *
    * @param i_doc_template               doc_template id                     *
    * @param i_flg_val_group              String to filter de group of rules  *
    * @param i_notes                      notes                               *
    * @param i_test                       Flag to execute validation          *
    *                                                                         *
    * @param o_error                      Error message                       *
    * @param o_flg_show                   Flag to show warn message           *
    * @param o_msg_title                  Title do message window             *
    * @param o_msg_text                   Message to be displayde in popup    *
    * @param o_button                     Type of button on popup msg         *
    *                                                                         *
    * @return                         Returns boolean                         *
    *                                                                         *
    * @author                         Gustavo Serrano                         *
    * @version                        1.0                                     *
    * @since                          2009/09/15                              *
    **************************************************************************/
    FUNCTION cancel_sr_epis_documentation
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis               IN episode.id_episode%TYPE,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_area           IN doc_area.id_doc_area%TYPE,
        i_doc_template       IN doc_template.id_doc_template%TYPE,
        i_flg_val_group      IN sr_surgery_validation.flg_group%TYPE,
        i_notes              IN VARCHAR2,
        i_test               IN VARCHAR2,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_flg_type_val  VARCHAR2(1) := 'V';
    g_flg_type_exp  VARCHAR2(1) := 'E';
    g_flg_type_chk  VARCHAR2(1) := 'C';
    g_flg_group_amb VARCHAR2(4) := 'AMB';
    g_flg_type_amb  VARCHAR(30) := 'SURGERY_TYPE.AMB';

    g_doc_area_pre_op_assessment NUMBER := 7;

    g_package_owner VARCHAR2(30) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_SR_DOCUMENTATION';
END pk_sr_documentation;
/
