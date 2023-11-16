/*-- Last Change Revision: $Rev: 2029038 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_viewer AS

    /*
    * Returns a list of screens for viewer synch
    *
    * @param     i_lang         Language id
    * @param     i_viewer       Viewer id
    * @param     i_prof         Professional
    * @param     o_synch        Cursor
    * @param     o_param        Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Sérgio Santos
    * @version   2.4
    * @since     2006/05/03
    */

    FUNCTION get_synch
    (
        i_lang   IN language.id_language%TYPE,
        i_viewer IN viewer.id_viewer%TYPE,
        i_prof   IN profissional,
        o_synch  OUT pk_types.cursor_type,
        o_param  OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a list of screens for viewer refresh (reload)
    *
    * @param     i_lang         Language id
    * @param     i_viewer       Viewer id
    * @param     i_prof         Professional
    * @param     o_refresh      Cursor
    * @param     o_error        Error message
    
    * @return    true or false on success or error
    *
    * @author    Sérgio Santos
    * @version   2.4
    * @since     2006/05/03
    */

    FUNCTION get_refresh
    (
        i_lang    IN language.id_language%TYPE,
        i_viewer  IN viewer.id_viewer%TYPE,
        i_prof    IN profissional,
        o_refresh OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns the viewer shortcut
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_episode        Episode id
    * @param     i_shortcut       Shortcut id
    * @param     o_sys_shortcut   Shortcut id (null if no shortcut)
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Sérgio Santos
    * @version   2.5.1.2
    * @since     2010/11/08
    */

    FUNCTION get_viewer_shortcut
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_shortcut     IN sys_shortcut.id_sys_shortcut%TYPE,
        o_sys_shortcut OUT sys_shortcut.id_sys_shortcut%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns interval for dates
    *
    * @param     i_lang           Language id
    * @param     i_prof           Professional
    * @param     i_interval       Interval to filter
    * @param     o_dt_begin       Initial date
    * @param     o_dt_end         End date
    * @param     o_error          Error message
    
    * @return    true or false on success or error
    *
    * @author    Sérgio Santos
    * @version   2.5.1.2
    * @since     2010/11/08
    */

    FUNCTION get_date_interval
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_interval IN VARCHAR2,
        o_dt_begin OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_end   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_pat_ehr_ea
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_patient     IN patient.id_patient%TYPE
    ) RETURN pk_types.cursor_type;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;

    g_interval_last24h_d VARCHAR2(1 CHAR) := 'D';
    g_interval_week_w    VARCHAR2(1 CHAR) := 'W';
    g_interval_month_m   VARCHAR2(1 CHAR) := 'M';
    g_interval_all_a     VARCHAR2(1 CHAR) := 'A';

END pk_viewer;
/
