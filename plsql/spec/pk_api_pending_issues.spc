/*-- Last Change Revision: $Rev: 2028479 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_api_pending_issues IS

    -- Author  : SERGIO.CUNHA
    -- Created : 07-04-2009 11:21:32
    -- Purpose : Pending issues API

    /********************************************************************************************
    * Get a list of issues with the associated department
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_institution                 Institution ID
    * @param o_issue_dept                  Cursor of issues and depts
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_issue_dept_info
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN PROFISSIONAL,
        i_id_institution IN institution.id_institution%TYPE,
        o_issue_dept     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get an issue title detail and modifications history
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_issue                       Issue title ID
    * @param o_issue_dept_detail           Cursor of issue title informations detail
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION get_issue_dept_detail_info
    (
        i_lang              IN LANGUAGE.id_language%TYPE,
        i_prof              IN PROFISSIONAL,
        i_issue             IN pending_issue_title.id_pending_issue_title%TYPE,
        o_issue_dept_detail OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set issue title modifications
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_dept                        Array of departments ID
    * @param i_issue                       Array of pending issue title ID
    * @param i_dec_issue                   Array of pending issue title description ID
    * @param o_issue                       Array of pending issue title IDs updated/inserted
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION set_issue_dept
    (
        i_lang       IN LANGUAGE.id_language%TYPE,
        i_prof       IN PROFISSIONAL,
        i_dept       IN TABLE_NUMBER,
        i_issue      IN TABLE_NUMBER,
        i_desc_issue IN TABLE_VARCHAR,
        o_issue      OUT TABLE_NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete selected issue titles
    *
    * @param i_lang                        Language
    * @param i_prof                        Profissional info
    * @param i_issue                       Array of pending issue title ID
    * @param o_issue                       Array of deleted issue title ID
    * @param o_error                       Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       2009/04/07
    ********************************************************************************************/
    FUNCTION cancel_issues
    (
        i_lang  IN LANGUAGE.id_language%TYPE,
        i_prof  IN PROFISSIONAL,
        i_issue IN TABLE_NUMBER,
        o_issue OUT TABLE_NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(2000);

END pk_api_pending_issues;
/
