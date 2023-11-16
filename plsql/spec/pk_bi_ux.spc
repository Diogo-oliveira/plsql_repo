/*-- Last Change Revision: $Rev: 2009819 $*/
/*-- Last Change by: $Author: ana.moita $*/
/*-- Date of last change: $Date: 2022-02-24 17:15:04 +0000 (qui, 24 fev 2022) $*/

CREATE OR REPLACE PACKAGE pk_bi_ux IS

    /******************************************************************************
    * This function is used to return ADW information to PFH products
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional logged in to app
    * @param o_adw_info        Cursor with the following info
    *                          (institution, episode_time, sum_total_episodes, sum_active_episodes, breaches)
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  BI
    * @version                 v2.6.4.3
    * @since                   2015-01-29
    *
    ******************************************************************************/
    FUNCTION get_adw_header_info
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_adw_info OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_breach_label
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_label OUT VARCHAR,				
        o_tooltip OUT VARCHAR,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_presc_credits
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_label OUT VARCHAR2,
        o_value OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_presc_credits_avail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_available    OUT VARCHAR2,
        o_refresh_time OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    g_error         VARCHAR2(2000);
    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(10) := 'PK_BI_UX';

END pk_bi_ux;
/
