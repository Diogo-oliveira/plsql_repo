/*-- Last Change Revision: $Rev: 1622325 $*/
/*-- Last Change by: $Author: alexandre.dias $*/
/*-- Date of last change: $Date: 2014-08-04 11:05:24 +0100 (seg, 04 ago 2014) $*/

CREATE OR REPLACE PACKAGE pk_api_multichoice IS

    -- Author  : GISELA.COUTO
    -- Created : 7/21/2014 1:26:41 PM
    -- Purpose : 

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
		
		/********************************************************************************************
    * Get all multichoice options descriptions (from translation) by multichoice identifier
    * (multichoice_option.id_multichoice_option)
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_multichoice_type                       Multichoice option identifier
    *
    * @returns table_varchar contains option code_multichoice_option 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.5
    * @since                          14-Jul-2014
    **********************************************************************************************/
		FUNCTION get_all_mult_option
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional
    ) RETURN table_varchar;

    /********************************************************************************************
    * Get multichoice option description (from translation) by option identifier 
    * (multichoice_option.id_multichoice_option)
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_id_option                              Multichoice option identifier
    *
    * @returns multichoice option description 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.5
    * @since                          14-Jul-2014
    **********************************************************************************************/
    FUNCTION get_multichoice_option_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_code_option IN VARCHAR2
    ) RETURN VARCHAR2;
		
		/********************************************************************************************
    * Get multichoice option description (from translation) by multichoice option code 
		* (multichoice_option.code_multichoice_option)
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_id_option                              Multichoice option identifier
    *
    * @returns multichoice option description 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.5
    * @since                          14-Jul-2014
    **********************************************************************************************/
    FUNCTION get_multichoice_option_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_option IN NUMBER
    ) RETURN VARCHAR2;
		
		
		/********************************************************************************************
    * Get multichoice option rank by multichoice option code 
		* (multichoice_option.code_multichoice_option)
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_id_option                              Multichoice option identifier
    *
    * @returns multichoice option rank 
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.5
    * @since                          14-Jul-2014
    **********************************************************************************************/
    FUNCTION get_multichoice_option_rank
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_multichoice_type IN VARCHAR2,
        i_id_option        IN NUMBER
    ) RETURN NUMBER;
		
		


END pk_api_multichoice;
/