/*-- Last Change Revision: $Rev: 2028457 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:53 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_aol_backoffice_news IS
    FUNCTION get_institutions
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_institutions OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem as últimas notícias nas várias línguas
    *
    * @param i_prof          profissional
    * @param i_lang          língua
    * @param o_institution   instituições
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/11/06
       ********************************************************************************************/

    FUNCTION get_languages
    (
        i_prof      IN profissional,
        i_lang      IN language.id_language%TYPE,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem os idiomas em que o portal existe
    *
    * @param i_prof          profissional
    * @param i_lang          língua
    * @param o_languages     idiomas
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/11/15
       ********************************************************************************************/

    FUNCTION get_latest_news
    (
        i_prof        IN profissional,
        i_lang        IN language.id_language%TYPE,
        o_latest_news OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem as últimas notícias nas várias línguas
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param o_lates_news    ultimas notícias
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_news_archive
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_news_archive OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem as últimas notícias nas várias línguas
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param o_news_archive  todas as noticias
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_news
    (
        i_prof       IN profissional,
        i_lang       IN language.id_language%TYPE,
        i_id_news    IN NUMBER,
        o_news       OUT pk_types.cursor_type,
        o_news_text  OUT pk_types.cursor_type,
        o_theme_list OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem a informação de uma noticia
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param i_id_news       id da noticia
    * @param o_news          info da notícia
    * @param o_news_text     texto da notícia
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION set_news
    (
        i_prof                    IN profissional,
        i_lang                    IN language.id_language%TYPE,
        i_id_news                 IN NUMBER,
        i_flg_available           IN VARCHAR2,
        i_id_institution          IN NUMBER,
        i_id_image                IN NUMBER,
        i_id_style                IN NUMBER,
        i_flg_type                IN VARCHAR2,
        i_id_related_content_type IN NUMBER,
        i_id_content              IN NUMBER,
        i_date_desc               IN VARCHAR2,
        o_id_news                 OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cria uma noticia
    *
    * @param i_prof                            profissional
    * @param i_lang                            lingua
    * @param i_id_news                         id da noticia
    * @param i_flg_available                   disponibilidade do registo
    * @param i_id_institution                  id da instituição
    * @param i_id_image                        imagem da noticia
    * @param i_id_style                        estilo da noticia
    * @param i_flg_type                        tipo da noticia
    * @param i_id_related_content_type         tipo de conteudo a apresentar quando a imagem é clicada
    * @param i_id_content                      id do conteudo a apresentar
    * @param o_id_text                         id da noticia inserida
    * @param o_error                           erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION set_news_text
    (
        i_prof               IN profissional,
        i_lang               IN language.id_language%TYPE,
        i_id_news_text       IN NUMBER,
        i_id_news            IN NUMBER,
        i_flg_available      IN VARCHAR2,
        i_id_language        IN NUMBER,
        i_desc_news_title    IN VARCHAR2,
        i_desc_news_subtitle IN VARCHAR2,
        i_desc_news_text     IN VARCHAR2,
        i_date_desc          IN VARCHAR2,
        o_id_news_text       OUT NUMBER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cria um texto de uma noticia
    *
    * @param i_prof               profissional
    * @param i_lang               lingua
    * @param i_id_news_text       id do texto da noticia
    * @param i_id_news            id da noticia
    * @param i_flg_available      disponibilidade do registo
    * @param i_id_language        lingua do texto
    * @param i_desc_news_title    titulo da noticia
    * @param i_desc_news_subtitle subtitulo da noticia
    * @param i_desc_news_text     texto da noticia
    * @param o_id_news_text       id do texto da noticia criado
    * @param o_error              erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION set_image
    (
        i_prof      IN profissional,
        i_lang      IN language.id_language%TYPE,
        i_id_image  IN NUMBER,
        i_mime_type IN VARCHAR2,
        i_file_name IN VARCHAR2,
        o_id_image  OUT NUMBER,
        o_file_name OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cria uma imagem
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param i_id_image      id da imagem
    * @param i_mime_type     tipo de conteudo
    * @param i_file_name     nome do ficheiro
    * @param o_id_image      id da imagem criada
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_theme
    (
        i_prof  IN profissional,
        i_lang  IN language.id_language%TYPE,
        o_theme OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem os temas existentes
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param o_theme         informação dos temas
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_content_type
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        o_content_type OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem os tipo de conteudo
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param o_content_type  informação do conteudo
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_content
    (
        i_prof             IN profissional,
        i_lang             IN language.id_language%TYPE,
        i_flg_content_type IN VARCHAR2,
        o_content          OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem os conteudos de um determinado tipo
    *
    * @param i_prof             profissional
    * @param i_lang             lingua
    * @param i_flg_content_type tipo do conteudo
    * @param o_content          informação do conteudo
    * @param o_error            erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
       ********************************************************************************************/

    FUNCTION get_style
    (
        i_prof  IN profissional,
        i_lang  IN language.id_language%TYPE,
        o_style OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem os estilos existentes
    *
    * @param i_prof          profissional
    * @param i_lang          lingua
    * @param o_style         informação dos estilos
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/10/18
    ********************************************************************************************/

    FUNCTION set_theme
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_id_news       IN NUMBER,
        i_theme_list    IN table_number,
        i_flg_available IN table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Obtem as últimas notícias nas várias línguas
    *
    * @param i_prof          profissional
    * @param i_lang          idioma
    * @param i_id_news       id da noticia
    * @param i_theme_list    temas
    * @param i_flg_availabel diponibilidade dos temas
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/11/15
       ********************************************************************************************/
    FUNCTION get_news_archive_search
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_language      IN language.id_language%TYPE,
        i_init_date     IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_search_string IN VARCHAR2,
        i_flg_location  IN VARCHAR2,
        o_news          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Pesquisa uma string em todas as notícias
    *
    * @param i_prof          profissional
    * @param i_lang          idioma    
    * @param i_init_date     data de início
    * @param i_end_date      data do fim da pesquisa
    * @param i_search_string frase a pesquisar
    * @param i_flg_location  local a pesquisar
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/11/19
       ********************************************************************************************/

    FUNCTION get_latest_news_search
    (
        i_prof          IN profissional,
        i_lang          IN language.id_language%TYPE,
        i_language      IN language.id_language%TYPE,
        i_init_date     IN VARCHAR2,
        i_end_date      IN VARCHAR2,
        i_search_string IN VARCHAR2,
        i_flg_location  IN VARCHAR2,
        o_news          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Pesquisa uma string nas últimas notícias
    *
    * @param i_prof          profissional
    * @param i_lang          idioma    
    * @param i_init_date     data de início
    * @param i_end_date      data do fim da pesquisa
    * @param i_search_string frase a pesquisar
    * @param i_flg_location  local a pesquisar
    * @param o_error         erro
    *
    * @return                Return boolean
    *
    * @author                José Vilas Boas
    * @version               1.0
    * @since                 2007/11/19
       ********************************************************************************************/

    g_error VARCHAR2(2000);
END pk_aol_backoffice_news;
/
