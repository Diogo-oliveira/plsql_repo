/*-- Last Change Revision: $Rev: 1826619 $*/
/*-- Last Change by: $Author: anna.kurowska $*/
/*-- Date of last change: $Date: 2018-02-22 01:22:57 +0000 (qui, 22 fev 2018) $*/

CREATE OR REPLACE PACKAGE pk_touch_option_out IS

    -- Author  : MIGUEL.LEITE
    -- Created : 23-03-2012 14:42:48
    -- Purpose : Touch Option functions to be used by other modules

    -- Public type declarations
    SUBTYPE t_rec_epis_edition_log IS pk_touch_option_core.t_rec_epis_edition_log;
    SUBTYPE t_coll_epis_edition_log IS pk_touch_option_core.t_coll_epis_edition_log;
    SUBTYPE t_rec_plain_text_entry IS pk_touch_option_core.t_rec_plain_text_entry;
    SUBTYPE t_coll_plain_text_entry IS pk_touch_option_core.t_coll_plain_text_entry;
    SUBTYPE t_cur_plain_text_entry IS pk_touch_option_core.t_cur_plain_text_entry;
    SUBTYPE t_rec_macro_info IS pk_doc_macro.t_rec_macro_info;
    SUBTYPE t_coll_rec_macro_info IS pk_doc_macro.t_coll_rec_macro_info;
    SUBTYPE t_cur_macro_info IS pk_doc_macro.t_cur_macro_info;

    -- Public constant declarations

    -- Public variable declarations

    -- Public function and procedure declarations

    /**
    * Returns list of editions done in a documentation entry
    *
    * @param   i_lang                 Professional preferred language
    * @param   i_prof                 Professional identification and its context (institution and software)
    * @param   i_epis_documentation   ID documentation entry 
    *
    * @return  Collection of t_rec_epis_edition_log
    *
    * @catches 
    * @throws  
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1
    * @since   09-03-2012
    */
    FUNCTION get_epis_doc_edition_log
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN t_coll_epis_edition_log;

    /**
    * Returns the possible actions for a documentation entry in a touch option area
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_epis_documentation    Entry ID
    * @param   i_flg_table_origin      Entry table origin
    * @param   i_flg_write             Write permission
    * @param   i_flg_no_changes        Permission for "No changes" action
    * @param   i_show_disabled_actions Allow invalid actions to be returned, but disabled <FLG_ACTIVE == 'N'>
    * @param   o_actions               Actions information
    *
    * @value   i_flg_table_origin      {*} 'D'  EPIS_DOCUMENTATION {*} 'A'  EPIS_ANAMNESIS {*} 'S'  EPIS_REVIEW_SYSTEMS {*} 'O'  EPIS_OBSERVATION {*} 'R' EPIS_RECOMEND {*} 'F' PAT_FAM_SOC_HIST {*} 'G' EPIS_DIAGNOSIS {*} 'U' SR_SURGERY_RECORD
    * @value   i_flg_write             {*} 'Y'  YES {*} 'N'  NO
    * @value   i_flg_no_changes        {*} 'Y'  YES {*} 'N'  NO
    * @value   i_show_disabled_actions {*} 'Y'  YES {*} 'N'  NO
    * @param   i_nr_record             Number of allowed record 
    *
    * @author  MIGUEL.LEITE
    * @version V2.6.2.1
    * @since   20-03-2012 14:59:41
    */
    PROCEDURE get_entry_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_documentation    IN epis_documentation.id_epis_documentation%TYPE,
        i_flg_table_origin      IN VARCHAR2,
        i_flg_write             IN VARCHAR2,
        i_flg_update            IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_flg_no_changes        IN VARCHAR2,
        i_show_disabled_actions IN VARCHAR2,
        i_nr_record             IN NUMBER DEFAULT NULL,
        o_actions               OUT pk_types.cursor_type
    );

    /**
    * Gets the template name associated to a given id_epis_documentation.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_documentation  Epis_documentation ID
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                19-09-2011
    */

    FUNCTION get_doc_template_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Gets the template name associated to a given id_doc_template
    *
    * @param    i_lang              Language ID
    * @param    i_doc_template      Template ID
    *
    * @return  Record with info about documentation type to be used
    *
    * @author  ARIEL.MACHADO
    * @version
    * @since   01/13/2014
    */

    FUNCTION get_doc_template_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_doc_template IN doc_template.id_doc_template%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /**
    * Returns the content of a set of Touch-option documentation entries in plain-text format
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_documentation_list   List of id_pis_documentation to retrieve
    * @param   i_use_html_format           Use HTML tags to format output. Default: No
    * @param   o_entries                   Cursor with the content of entries in plain text format
    *
    * @value   i_use_html_format           {*} 'Y'  Use HTML tags {*} 'N'  No HTML tags
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.3
    * @since   26-06-2012
    */
    PROCEDURE get_plain_text_entries
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_epis_documentation_list IN table_number,
        i_use_html_format         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_entries                 OUT t_cur_plain_text_entry
    );

    /**
    * Returns a list of prefilled templates created by the professional for a specified template and area.
    *
    * @param i_lang             Professional preferred language 
    * @param i_prof             Professional identification and its context (institution and software)
    * @param i_doc_area         Area ID
    * @param i_doc_template     Template ID
    * @param o_doc_macro_list   Cursor with a list of identifiers and descriptions of available prefilled templates
    *
    * @author  ARIEL.MACHADO
    * @version 2.6.2.1.3
    * @since   13-09-2012
    */
    PROCEDURE get_doc_macros_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_doc_area       IN doc_macro_version.id_doc_area%TYPE,
        i_doc_template   IN doc_macro_version.id_doc_template%TYPE,
        o_doc_macro_list OUT t_cur_macro_info
    );
    /**
    * Returns true if a template is bilateral false otherwise
    *
    * @param i_epis_documentation     The documentation episode id
    *
    * @return  Returns true if a template is bilateral false otherwise
    *    
    * @author  ARIEL.MACHADO
    * @version 2.6.4
    * @since   2014-11-05
    */
    FUNCTION has_layout(i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE) RETURN VARCHAR2;

END pk_touch_option_out;
/
