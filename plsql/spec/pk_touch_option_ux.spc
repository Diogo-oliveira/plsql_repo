/*-- Last Change Revision: $Rev: 2044267 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-08-09 14:44:58 +0100 (ter, 09 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_touch_option_ux AS

    /**
    * Guarda as preferencias do metodo de input preferido do profissional para um conjunto de doc areas, 
      mediante software e instituição.Utilizado no backoffice do utilizador
    *
    * @param i_lang           id da lingua
    * @param i_prof           objecto com info do utilizador
    * @param i_institution    id da instituição de onde se le a preferencia
    * @param i_software       id do software onde é apresentada a doc_area
    * @param i_doc_areas      table_number com ids das doc_areas
    * @param i_flg_modes      table_varchar com metodo de input preferido para a respectiva doc_area
    * @param o_error          Error message
    *                        
    * @return                 true or false on success or error
    *
    * @author                 João Eiras
    * @version                1.0   
    * @since                  24-05-2007
    */

    FUNCTION set_prof_touch_options_mode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_institutions IN table_number,
        i_softwares    IN table_number,
        i_doc_areas    IN table_number,
        i_flg_modes    IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Devolve a lista de doc_area a que este profissional tem acesso, mediante software e instituição, 
      e os respectivos valores das preferencias do
      metodo de input (documentation ou texto livre)
    *
    * @param i_lang                 id da lingua
    * @param i_prof                 objecto com info do utilizador
    * @param i_institution          id da instituição de onde se le a preferencia
    * @param i_software             id do software onde é apresentada a doc_area
    * @param o_options              cursor com doc_areas e preferencias
    * @param o_error                Error message
    *                        
    * @return                       true or false on success or error
    *
    * @author                       João Eiras
    * @version                      1.0   
    * @since                        24-05-2007
    */

    FUNCTION get_prof_touch_options_mode
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        o_options     OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Obter softwares a que o utilizador tem acesso        
    *
    * @param i_lang id da lingua
    * @param i_prof objecto do utilizador
    * @param i_inst id da instituição
    * @param o_list lista de softwares
    * @param o_erro variavel com mensagem de erro
    * @return                    true (sucess), false (error)
    *
    * @author João Eiras, 26-09-2007
    * @since 2.4.0
    * @version 1.0
    */

    FUNCTION get_touch_option_software
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error           VARCHAR2(4000);

END pk_touch_option_ux;
/
