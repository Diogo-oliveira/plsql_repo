/*-- Last Change Revision: $Rev: 2028750 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:42 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inp_hidrics_out AS

    /********************************************************************************************
    * Get_pdms_ways                  Gets Hidric ways
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_FLG_type              Hidric flag Type
    *
    * @return                        Returns the Hidric Last Resul
    *
    * @author                        Miguel Gomes
    * @since                         29-AGO-2013
    * @version                       2.6.3.9
    ********************************************************************************************/
    FUNCTION get_pdms_ways
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_type    IN way.flg_type%TYPE,
        o_hidric_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_multichoice_lists_pdms                  Gets Hidric and ways
    *
    * @param I_LANG               Language ID for translations
    * @param I_PROF               Professional vector of information (professional ID, institution ID, software ID)
    * @param i_hid_flg_type       Hidrics flg_type (Administration or Elimination)
    * @param i_hidrics_type       Hidrics type ID
    * @param i_way                Way id
    * @param o_ways               ways cursor
    * @param o_hidrics            hidrics cursor
    * @param o_error              If an error accurs, this parameter will have information about the error
    *
    * @return                        TRUE if success, FALSE otherwise
    *
    * @author                        Paulo teixeira
    * @since                         2013-09-13
    * @version                       2.6.3
    ********************************************************************************************/
    FUNCTION get_multichoice_lists_pdms
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_hid_flg_type IN hidrics.flg_type%TYPE,
        i_hidrics_type IN hidrics_type.id_hidrics_type%TYPE DEFAULT NULL,
        i_way          IN way.id_way%TYPE DEFAULT NULL,
        o_ways         OUT pk_types.cursor_type,
        o_hidrics      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;
    /*******************************************************************************************************************************************
    * get_hidrics_type_list           Function that returns the list of available hidrics
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_HIDRICS_LIST           Cursor that returns the list of hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_type_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_hidrict_list OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_flowsheet_actions           Get all actions for the flowsheet screen
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_hidrics_type           Hidrics type ID
    * @param O_CREATE_CHILDS          Child actions for the 'Fluid type' option in the create button
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                         José Silva
    * @version                        2.6.0.3
    * @since                          2010/05/31
    *******************************************************************************************************************************************/
    FUNCTION get_flowsheet_actions
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_hidrics_type  IN hidrics_type.id_hidrics_type%TYPE,
        o_create_childs OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
END pk_inp_hidrics_out;
/
