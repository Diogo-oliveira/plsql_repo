/*-- Last Change Revision: $Rev: 2027265 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:41 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_hidrics_out IS
    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;
    g_function VARCHAR2(128 CHAR);

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_function := 'get_hidric_ways';
        g_error    := 'Init';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
        g_error := 'Execution code';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => g_function);
    
        RETURN pk_inp_hidrics.get_pdms_ways(i_lang, i_prof, i_flg_type, o_hidric_list, o_error);
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => g_function,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hidric_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pdms_ways;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'get_multichoice_lists_pdms';
    
    BEGIN
    
        g_error := 'call get_multichoice_lists_pdms';
        IF NOT pk_inp_hidrics.get_multichoice_lists_pdms(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_hid_flg_type => i_hid_flg_type,
                                                         i_hidrics_type => i_hidrics_type,
                                                         i_way          => i_way,
                                                         o_ways         => o_ways,
                                                         o_hidrics      => o_hidrics,
                                                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_hidrics);
            pk_types.open_my_cursor(o_ways);
            RETURN FALSE;
    END get_multichoice_lists_pdms;

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
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL TO PK_INP_HIDRICS.GET_HIDRICS_TYPE_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_inp_hidrics.get_hidrics_type_list(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    o_hidrict_list => o_hidrict_list,
                                                    o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_hidrics_type_list;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'get_flowsheet_actions';
    BEGIN
    
        g_error := 'call pk_inp_hidrics.get_flowsheet_actions';
        IF NOT pk_inp_hidrics.get_flowsheet_actions(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_hidrics_type  => i_hidrics_type,
                                                    o_create_childs => o_create_childs,
                                                    o_error         => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        --
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_create_childs);
            RETURN FALSE;
    END get_flowsheet_actions;
BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_inp_hidrics_out;
/
