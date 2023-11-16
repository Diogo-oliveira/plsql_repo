/*-- Last Change Revision: $Rev: 2028925 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:46 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_release_notes AS

    /*
    * Returns a list of ALERT fix's
    *
    * @param i_lang      Prefered language ID
    * @param i_version   Version ID's
    *
    * @param o_list      List of fix's for required versions
    *
    * @return            true or false on success or error
    *
    * @author            Álvaro Vasconcelos
    * @version           2.6.0.5
    * @since             2011/01/31
    */

    FUNCTION get_fixs
    (
        i_lang    IN language.id_language%TYPE,
        i_version IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of ALERT's versions  
    *
    * @param i_lang   Prefered language ID
    *
    * @param o_list   List of versions
    *
    * @return         true or false on success or error
    *
    * @author         Álvaro Vasconcelos
    * @version        2.6.0.5
    * @since          2011/01/31
    */

    FUNCTION get_versions
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of release notes
    *
    * @param i_lang             Prefered language ID
    * @param i_prof             Professional ID
    * @param i_soft             Software ID
    * @param i_prof_template    Profile Template ID
    * @param i_version          Version ID
    * @param i_fix              Fix ID
    * @param i_rn_start_index   Start index for release notes. Used for paging
    * @param i_rn_num_records   Number of release notes for each page
    *
    * @param o_list             List of release notes
    *
    * @return                   true or false on success or error
    *
    * @author                   Álvaro Vasconcelos
    * @version                  2.6.0.5
    * @since                    2011/01/31
    */

    FUNCTION get_release_notes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_soft                  IN table_number,
        i_prof_template         IN table_number,
        i_version               IN table_number,
        i_fix                   IN table_number,
        i_rn_start_index        IN NUMBER DEFAULT 1,
        i_rn_num_records        IN NUMBER DEFAULT 100,
        o_list                  OUT pk_types.cursor_type,
        o_default_soft          OUT pk_types.cursor_type,
        o_default_prof_template OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Searches within release notes
    *
    * @param i_lang             Prefered language ID
    * @param i_prof             Professional ID
    * @param i_soft             Software ID
    * @param i_prof_template    Profile Template ID
    * @param i_version          Version ID
    * @param i_fix              Fix ID
    * @param i_rn_start_index   Start index for release notes. Used for paging
    * @param i_rn_num_records   Number of release notes for each page
    * @param i_search           Text to be searched
    *
    * @param o_list             List of release notes
    *
    * @return                   true or false on success or error
    *
    * @author                   Daniel Ferreira
    * @version                  2.6.2
    * @since                    2011/01/22
    */

    FUNCTION search_release_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_soft           IN table_number,
        i_prof_template  IN table_number,
        i_version        IN table_number,
        i_fix            IN table_number,
        i_rn_start_index IN NUMBER DEFAULT 1,
        i_rn_num_records IN NUMBER DEFAULT 100,
        i_search         IN VARCHAR2 DEFAULT '',
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of profiles templates
    *
    * @param i_lang   Prefered language ID
    * @param i_prof   Professional ID
    *
    * @param o_list   List of profiles templates
    *
    * @return         true or false on success or error
    *
    * @author         Álvaro Vasconcelos
    * @version        2.6.0.5
    * @since          2011/01/31
    */

    FUNCTION get_prof_template_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_soft  IN table_number,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the list of softwares
    *
    * @param i_lang   Prefered language ID
    * @param i_prof   Professional ID
    * @param o_list   List of softwares
    *
    * @return         true or false on success or error
    *
    * @author         Álvaro Vasconcelos
    * @version        2.6.0.5
    * @since          2011/01/31
    */

    FUNCTION get_software_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Inserts a new version
    *
    * @param i_id_version            Version ID
    * @param i_desc_version          Version Description
    * @param i_dt_release            Version date release
    * @param i_id_version_parent     Version ID parent (to define fix's)
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.0.5
    * @since                         2011/02/14
    */

    PROCEDURE insert_version
    (
        i_id_version        IN version.id_version%TYPE,
        i_desc_version      IN version.desc_version%TYPE,
        i_dt_release        IN version.dt_release%TYPE,
        i_id_version_parent IN version.id_version%TYPE
    );

    /*
    * Inserts a new release note
    *
    * @param i_id_fix                Fix ID
    * @param i_id_jira               JIRA issue key
    * @param i_lang                  Languages id array
    * @param i_summ                  Release Notes summarys (should have the same order of i_lang)    
    * @param i_desc                  Release Notes descriptions (should have the same order of i_lang)  
    * @param i_cat                   Release note categories
    * @param i_soft                  Release note softwares
    * @param i_market                Release note markets
    *
    * @author                        Álvaro Vasconcelos
    * @version                       2.6.0.5
    * @since                         2011/02/15
    */

    PROCEDURE insert_release_note
    (
        i_id_fix  IN version.id_version%TYPE,
        i_id_jira IN release_note_fix.id_jira%TYPE,
        i_lang    IN table_number,
        i_summ    IN table_varchar,
        i_desc    IN table_clob,
        i_cat     IN table_number,
        i_soft    IN table_number,
        i_market  IN table_number
    );

    /*
    * Deletes a new release note
    *
    * @param i_id_jira               JIRA issue key
    *
    * @author                        Gustavo Serrano
    * @version                       2.6.0.5
    * @since                         2011/12/09
    */

    PROCEDURE delete_release_note(i_id_jira IN release_note_fix.id_jira%TYPE);

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(1000 CHAR);

END pk_release_notes;
/
