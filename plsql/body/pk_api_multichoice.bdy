/*-- Last Change Revision: $Rev: 2054558 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-13 14:59:46 +0000 (sex, 13 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_multichoice IS

    /********************************************************************************************
    * Get multichoice options by a multichoice type  
    * @i_lang                                   Language
    * @i_prof                                   Professional information
    * @i_multichoice_type                       Multichoice type CODE Ex: PAT_PREGNANCY.FLG_STATUS (<table>.<column>)
    *
    * @returns table type t_tbl_multichoice_option, which contains the following information:
    * id_multichoice_option - multichoice option identifier, desc_option - multichoice option description,
    * id_content - Content identifier and finnaly rank number - allows items sort.
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
        l_error     VARCHAR2(1000 CHAR);
        l_func_name VARCHAR2(1000 CHAR) := 'GET_MULTICHOICE_OPTIONS';
        l_var       t_tbl_multichoice_option := NEW t_tbl_multichoice_option();
    BEGIN
    
        l_var := pk_multichoice.tf_multichoice_options(i_lang, i_prof, i_multichoice_type => i_multichoice_type);
    
        l_error := 'CALL ALERT_CORE_FUNC.PK_MULTICHOICE TO GET MULTICHOICE OPTIONS / SORT ITEMS BY RANK ';
        OPEN o_multichoice_options FOR
            SELECT id_multichoice_option data, desc_option label, id_content, rank, flg_notes
              FROM TABLE(l_var) mult_opts
             ORDER BY mult_opts.rank ASC, mult_opts.desc_option;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_multichoice_options;

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
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar IS
    
    BEGIN
    
        /*call alert_core_func.pk_multichoice to get all multichoice options by multichoice code*/
        RETURN pk_multichoice.get_all_mult_option(i_lang => i_lang, i_prof => i_prof);
    
    END get_all_mult_option;

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
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        /*call alert_core_func.pk_multichoice to get multichoice option description by option id*/
        RETURN pk_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                          i_prof      => i_prof,
                                                          i_id_option => i_id_option);
    
    END get_multichoice_option_desc;

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
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_code_option IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        /*call alert_core_func.pk_multichoice to get multichoice option description by option id*/
        RETURN pk_multichoice.get_multichoice_option_desc(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_code_option => i_code_option);
    
    END get_multichoice_option_desc;

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
    ) RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_multichoice.get_multichoice_option_rank(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_multichoice_type => i_multichoice_type,
                                                          i_id_option        => i_id_option);
    
    END get_multichoice_option_rank;

BEGIN
    -- Initialization
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_package_owner, name => g_package_name);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package_name);
END pk_api_multichoice;
/
