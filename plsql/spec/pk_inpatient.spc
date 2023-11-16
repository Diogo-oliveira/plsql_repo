/*-- Last Change Revision: $Rev: 2028740 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:38 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_inpatient IS

    /*******************************************************************************************************************************************
    * GET_SERVICES                    GET INPATIENT AVAILABLE DEPARTMENTS WHERE CREATE AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param O_DPT                    Cursor that returns available department
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_services
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_dpt   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_TRANSFER_SERVICES           GET INPATIENT AVAILABLE DEPARTMENTS TO TRANSFER AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEP_CLIN_SERV       dep_clin_serv identifier                   
    * @param O_DPT                    Cursor that returns available department
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         José Silva
    * @version                        1.0
    * @since                          2007/03/19
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_transfer_services
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dpt              OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_CLINICAL_SERVICES           GET INPATIENT AVAILABLE CLINICAL SERVICES WHERE CREATE AN EPISODE
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEPARTMENT          DEPARTMENT identifier                   
    * @param O_DCS                    Cursor that returns available clinical services
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_clinical_services
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_dcs           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_ROOMS                       GET INPATIENT AVAILABLE ROOMS IN AN SPECIFIC DEPARTMENT
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_DEPARTMENT          DEPARTMENT identifier                   
    * @param O_ROO                    Cursor that returns available rooms
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_rooms
    (
        i_lang          IN language.id_language%TYPE,
        i_id_prof       IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_roo           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * GET_BEDS                        GET INPATIENT AVAILABLE BEDS IN AN SPECIFIC ROOM
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_ID_PROF                Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_ROOM                Room identifier                   
    * @param O_BED                    Cursor that returns available beds
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS" and "user_exception"
    * 
    * @author                         Carlos Ferreira
    * @version                        1.0
    * @since                          2006/11/11
    *
    * @author                         Luís Maia
    * @version                        2.5.0.7.5
    * @since                          2009/12/12
    *******************************************************************************************************************************************/
    FUNCTION get_beds
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_bed     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- Constants definition
    g_package_owner VARCHAR2(0050);
    g_package_name  VARCHAR2(0050);
    g_error         VARCHAR2(4000);
    --
    g_dpt_flg_type_inpatient VARCHAR2(0050);

END;
/
