/*-- Last Change Revision: $Rev: 2028527 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_backoffice_sample_text IS

    -- Author  : BRUNO.MARTINS
    -- Created : 12-11-2008 11:42:32
    -- Purpose : Parametrização de Textos predefinidos

    /********************************************************************************************
    * Public Function. Get Sample Text List
    *
    * @param      I_LANG                     Language identification
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type
    * @param      O_STT_LIST             Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/13
    *******************************************************************************************/
    FUNCTION get_sample_text_list
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_sample_text_type_id IN sample_text.id_sample_text_type%TYPE,
        o_stt_list            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Public Function. Get Sample Text Type List
    *
    * @param      I_LANG                     Language identification
    * @param      I_SOFTWARE                 Software
    * @param      I_SEARCH                   String to search for   
    * @param      O_INFO                    Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_type_list
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_software IN sample_text_type.id_software%TYPE,
        i_search   IN VARCHAR2,
        o_info     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Public Function. Get Sample Text Details
    *
    * @param      I_LANG                     Language identification
    * @param      I_SAMPLE_TEXT_ID         Sample Text ID
    * @param      O_STT_LIST             Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/13
    *******************************************************************************************/
    FUNCTION get_sample_text_details
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_sample_text_id      IN sample_text.id_sample_text%TYPE,
        o_sample_text_details OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Public Function. Get Sample Text By DCS
    *
    * @param      I_LANG                     Language identification
    * @param      I_DCS                      Department Clinical Service ID
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type ID
    * @param      I_SEARCH                   String to search for 
    * @param      O_ST_LIST                  Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_by_dcs
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_dcs                 IN NUMBER,
        i_sample_text_type_id IN NUMBER,
        i_search              IN VARCHAR2,
        o_st_list             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Public Function. Get Sample Text Type By Category
    *
    * @param      I_LANG                     Language identification
    * @param      I_INSTITUTION              Institution Identifier
    * @param      I_SAMPLE_TEXT_TYPE_ID      Sample Text Type ID
    * @param      I_SEARCH                   String to search for
    * @param      O_STT_LIST                 Cursor with the sample text list
    * @param      O_ERROR                    Error
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/17
    *******************************************************************************************/
    FUNCTION get_sample_text_type_by_cat
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_institution         IN NUMBER,
        i_sample_text_type_id IN NUMBER,
        i_search              IN VARCHAR2,
        o_stt_list            OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sample Text Category management
    *
    * @param i_lang                  Prefered language ID
    * @param i_institution           Institution identifier
    * @param i_sample_text_type_id   Array of Sample Text Type ID's
    * @param i_category_id           Array of array of Category ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @return                      true on succes, false on error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/12
    ********************************************************************************************/
    FUNCTION set_sample_text_cat
    (
        i_lang                IN LANGUAGE.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_sample_text_type_id IN table_number,
        i_category_id         IN table_table_number,
        i_select              IN table_table_varchar,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sample Text Freq management
    *
    * @param i_lang                  Prefered language ID
    * @param i_dep_clin_serv         Array of Department/Clinical Service ID's
    * @param i_sample_text_id        Array of array of Sample Text ID's
    * @param i_select                Array of array of Flags(Y - insert; N - delete)
    * @param o_error                 Error
    *
    *
    * @return                      true on succes, false on error
    *
    * @author                      BM
    * @version                     1.0
    * @since                       2008/11/12
    ********************************************************************************************/
    FUNCTION set_sample_text_freq
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_dep_clin_serv  IN table_number,
        i_sample_text_id IN table_table_varchar,
        i_select         IN table_table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Software's Sample Text List
    * 
    * @param      I_LANG                       Identificação do Idioma
    * @param      I_ID_DEPT                    Identificação do Departamento
    * @param      I_ID_INSTITUTION             Identificação da Instituição
    * @param      O_DCS_LIST                   Cursor com a Informação da Listagem dos serviços
    * @param      O_ERROR                      Erro
    *
    * @return     boolean
    * @author     BM
    * @version    1.0
    * @since      2008/11/18
    */
    FUNCTION get_dept_dcs_list
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_id_dept        IN department.id_dept%TYPE,
        i_id_institution IN department.id_institution%TYPE,
        o_dcs_list       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

END pk_backoffice_sample_text;
/
