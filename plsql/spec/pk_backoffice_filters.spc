/*-- Last Change Revision: $Rev: 2028517 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:16 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_backoffice_filters IS
    -- Author  : Rui.Gomes
    -- Created : 19-09-2011 16:17:41
    -- Purpose : Store auxiliary Methods to new filter, search and paging component 
    /********************************************************************************************
    * get_prof_match_search            Gets mapping contexts in professional match 
    *
    * @param i_context_ids             predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals            all remaining contexts array(configurable with bind variable definition)
    * @param i_name                    Filter name
    * @param o_vc2                     Output variable type varchar2
    * @param o_num                     Output variable type NUMBER
    * @param o_id                      Output variable type Id
    * @param o_tstz                    Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author                          RMGM
    * @version                         2.6.1.2
    * @since                           15-Sep-2011
    *
    **********************************************************************************************/
    PROCEDURE get_prof_match_search
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );
    /********************************************************************************************
    * get_prof_match_search            Gets mapping contexts in professional match 
    *
    * @param i_context_ids             predefined contexts array(prof_id, institution, patient, episode, etç)
    * @param i_context_vals            all remaining contexts array(configurable with bind variable definition)
    * @param i_name                    Filter name
    * @param o_vc2                     Output variable type varchar2
    * @param o_num                     Output variable type NUMBER
    * @param o_id                      Output variable type Id
    * @param o_tstz                    Output variable type TIMESTAMP WITH LOCAL TIME ZONE
    *
    * @author                          RMGM
    * @version                         2.6.1.2
    * @since                           15-Sep-2011
    *
    **********************************************************************************************/
    PROCEDURE get_cda_map_search
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    );
    PROCEDURE get_message_map
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids  IN table_number,
        i_context_vals IN table_varchar,
        i_name         IN VARCHAR2,
        o_vc2          OUT VARCHAR2,
        o_num          OUT NUMBER,
        o_id           OUT NUMBER,
        o_tstz         OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) ;

END pk_backoffice_filters;
/
