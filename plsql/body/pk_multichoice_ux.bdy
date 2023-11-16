/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE BODY pk_multichoice_ux IS

    /********************************************************************************************
    * Get multichoice options by a multichoice type  
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_multichoice_type                       Multichoice type CODE Ex: PAT_PREGNANCY.FLG_STATUS (<table>.<column>)
    * @param o_multichoice_options              All multichoice options information
    * @param o_error                            An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.5
    * @since                          14-Jul-2014
    **********************************************************************************************/

    FUNCTION get_multichoice_options
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_multichoice_type    IN VARCHAR2,
        o_multichoice_options OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_error     VARCHAR2(100 CHAR);
        l_func_name VARCHAR2(1000) := 'get_multichoice_options';
    BEGIN
        l_error := 'CALL PK_API_EDIS.GET_MULTICHOICE_OPTIONS TO GET MULTICHOICE OPTINONS';
        RETURN pk_api_multichoice.get_multichoice_options(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_multichoice_type    => i_multichoice_type,
                                                          o_multichoice_options => o_multichoice_options,
                                                          o_error               => o_error);
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              l_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_multichoice_options;

BEGIN
    -- Initialization
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
END pk_multichoice_ux;
/
