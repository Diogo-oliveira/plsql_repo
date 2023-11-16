/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_multichoice_ux IS

    -- Author  : GISELA.COUTO
    -- Created : 7/16/2014 1:43:06 PM
    -- Purpose : Manage information about multichoice content

    /*Global Variables*/
    SUBTYPE obj_name IS VARCHAR2(30 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);
    g_package_owner obj_name;
    g_package_name  obj_name;

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
    ) RETURN BOOLEAN;

END pk_multichoice_ux;
/
