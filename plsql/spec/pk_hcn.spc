/*-- Last Change Revision: $Rev: 2028713 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_hcn IS

    -- Author  : RUI.BATISTA
    -- Created : 03-04-2007 9:48:59
    -- Purpose : Contém as funções necessárias à funcionalidade HCN

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;
    g_active        CONSTANT VARCHAR2(1) := 'A';
    g_cancel        CONSTANT VARCHAR2(1) := 'C';
    g_inactive      CONSTANT VARCHAR2(1) := 'I';
    g_default_y     CONSTANT VARCHAR2(1) := 'Y';
    g_available_y   CONSTANT VARCHAR2(1) := 'Y';
    g_selected      CONSTANT VARCHAR2(1) := 'S';
    g_hcn_available CONSTANT VARCHAR2(1) := 'D';

    g_flg_type_pat  CONSTANT VARCHAR2(1) := 'P';
    g_inp_epis_type CONSTANT epis_type.id_epis_type%TYPE := 5;

    g_yes CONSTANT VARCHAR2(1) := 'Y';
    g_no  CONSTANT VARCHAR2(1) := 'N';

    g_hcn_type_pat    CONSTANT hcn_eval_det.flg_type%TYPE := 'P';
    g_hcn_type_dayoff CONSTANT hcn_eval_det.flg_type%TYPE := 'F';
    g_cat_type_nurse  CONSTANT category.flg_type%TYPE := 'N';

    g_my_serv  CONSTANT VARCHAR2(1) := 'M';
    g_all_serv CONSTANT VARCHAR2(1) := 'A';

    g_diet_requested CONSTANT VARCHAR2(0050) := 'R';
    g_flg_dpt_type   CONSTANT VARCHAR2(1) := 'I';

    g_hcn_doc_area CONSTANT doc_area.id_doc_area%TYPE := 39;

    -- Public type declarations
    TYPE t_rec_hcn_score IS RECORD(
        id_epis_documentation epis_documentation.id_epis_documentation%TYPE,
        id_doc_template       doc_template.id_doc_template%TYPE,
        desc_class            VARCHAR2(4000),
        score                 hcn_eval.total_points%TYPE,
        num_hcn               hcn_def_points.num_hcn%TYPE,
        id_professional       epis_documentation.id_professional%TYPE,
        dt_last_update_tstz   epis_documentation.dt_last_update_tstz%TYPE,
        flg_status            epis_documentation.flg_status%TYPE);

    TYPE t_coll_hcn_score IS TABLE OF t_rec_hcn_score;

    /********************************************************************************************/
    /********************************************************************************************
    * Esta função devolve um array com os pontos de HCN correspondentes a cada item da avaliação
    *
    * @param i_lang        Id do idioma
    * @param i_prof        Id do profissional, instituição e software
    * @param i_episode     Episode id
    * @param i_doc_area    ID da avaliação
    * @param i_id_dept     ID do serviço
    * @param i_doc_templ   ID do template
    *
    * @param o_points      Array com os pontos de HCN correspondentes a cada item da avaliação
    * @param o_hcn         Array com a tabela que relaciona os pontos com as horas de HCN
    * @param o_error       Mensagem de erro
    *
    * @return                Array com os pontos de HCN correspondentes a cada item da avaliação
    *
    * @author                Pedro Lopes
    * @version               1.0
    * @since                 2008/03/17
     ********************************************************************************************/

    FUNCTION get_eval_hcn_points_template
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_episode  IN episode.id_episode%TYPE,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        i_id_dept  IN department.id_department%TYPE,
        i_id_templ IN doc_template.id_doc_template%TYPE,
        o_points   OUT pk_types.cursor_type,
        o_hcn      OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/
    FUNCTION get_eval_summ_page
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_det     OUT pk_types.cursor_type,
        o_eval    OUT pk_types.cursor_type,
        o_id_dept OUT department.id_department%TYPE,
        --        o_id_doc_area OUT doc_area.id_doc_area%TYPE,
        o_doc_area   OUT pk_types.cursor_type,
        o_flg_show   OUT VARCHAR2,
        o_msg_result OUT VARCHAR2,
        o_title      OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/
    FUNCTION get_eval_total_points(i_epis_documentation IN episode.id_episode%TYPE) RETURN NUMBER;

    /********************************************************************************************/
    FUNCTION set_eval_hcn
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_dt_eval    IN VARCHAR2,
        i_department IN department.id_department%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION cancel_eval_hcn
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_eval_hcn_detail
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_eval    OUT pk_types.cursor_type,
        o_det     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_eval_hcn_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_hcn     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_pat_dist
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_pat   OUT pk_types.cursor_type,
        o_nurse OUT pk_types.cursor_type,
        o_rel   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_from_points
    (
        i_prof     IN profissional,
        i_hcn_eval IN hcn_eval.id_hcn_eval%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION set_hcn_eval_det
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_nurse IN table_number,
        i_hcn_eval   IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION cancel_hcn_eval_det
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_hcn_eval IN hcn_eval.id_hcn_eval%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_prof_pat_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        i_type         IN VARCHAR2,
        o_pat          OUT pk_types.cursor_type,
        o_date         OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_service_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_weekly_view
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_department IN department.id_department%TYPE,
        i_date       IN VARCHAR2,
        o_nurse      OUT pk_types.cursor_type,
        o_days       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_from_day
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_professional IN professional.id_professional%TYPE,
        i_date         IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************/

    FUNCTION check_exists_nurse_aloc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_episode            IN episode.id_episode%TYPE,
        i_date               IN VARCHAR2,
        i_type               IN VARCHAR2,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_hcn_eval           OUT hcn_eval.id_hcn_eval%TYPE,
        o_flg_show           OUT VARCHAR2,
        o_msg_title          OUT VARCHAR2,
        o_msg_text           OUT VARCHAR2,
        o_button             OUT VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_aloc_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION set_hcn_prof_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_prof_nurse IN professional.id_professional%TYPE,
        i_date       IN VARCHAR2,
        i_status     IN VARCHAR2,
        i_test       IN VARCHAR2,
        o_flg_show   OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_msg_text   OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_pat_weekly_view
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2,
        i_type    IN VARCHAR2,
        o_pat     OUT pk_types.cursor_type,
        o_days    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_day_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION get_hcn_type_scheduled
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_date         IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************/

    FUNCTION set_hcn_pat_status
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_date      IN VARCHAR2,
        i_type      IN VARCHAR2,
        i_test      IN VARCHAR2,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_eval_item_points
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_documentation IN documentation.id_documentation%TYPE,
        i_date          IN TIMESTAMP WITH TIME ZONE
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION get_hcn_pat_evolution
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_date    IN VARCHAR2,
        o_pat     OUT pk_types.cursor_type,
        o_days    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_eval_total_points
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN TIMESTAMP WITH TIME ZONE --DATE
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION get_hcn_eval_total_hcn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN TIMESTAMP WITH TIME ZONE --VARCHAR2
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION get_hcn_pat_evolution_array
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_date    IN VARCHAR2,
        o_val     OUT table_varchar,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_epis_avg
    (
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************/

    FUNCTION get_hcn_disch_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_date    IN VARCHAR2,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************/

    FUNCTION get_hcn_statistics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_date         IN VARCHAR2,
        i_department   IN department.id_department%TYPE,
        o_tot_hcn_day  OUT VARCHAR2,
        o_tot_hcn_week OUT VARCHAR2,
        o_avg_hcn_day  OUT VARCHAR2,
        o_avg_hcn_week OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * return list of hcn values and scores for the given epis_documentation           
    *                                                                         
    * @param i_lang                   The language ID                         
    * @param i_prof                   Object (professional ID, institution ID,software ID)   
    * @param i_epis_documentation     array with ID_EPIS_DOCUMENTION                        
    *                                                                         
    * @return                         return list of scales epis_documentation       
    *                                                                         
    * @author                         Sofia Mendes                            
    * @version                        2.6.3.8                                
    * @since                          2013/10/21                              
    **************************************************************************/
    FUNCTION tf_hcn_score
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN table_number
    ) RETURN t_coll_hcn_score
        PIPELINED;

    /**********************************************************************************************
    * get actions of the HCN records
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_epis_documentation      Epis documentation id
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  true on success, otherwise false
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                29-Oct-2013
    **********************************************************************************************/
    FUNCTION get_hcn_actions
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        o_actions            OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Check if the epis_documentation is an HCN record
    *
    * @param       i_lang                   preferred language id for this professional
    * @param       i_prof                   professional type
    * @param       i_epis_documentation      Epis documentation id
    * @param       o_actions                actions cursor info 
    * @param       o_error                  error message
    *
    * @return      boolean                  1- It is an hcn record; 0 - otherwise
    *
    * @author                               Sofia Mendes
    * @version                              2.6.2
    * @since                                29-Oct-2013
    **********************************************************************************************/
    FUNCTION check_is_hcn_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Cancel an hcn documentation
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_id_epis_doc            the documentation episode ID to cancelled
    * @param i_test                   Indica se deve mostrar a confirmação de alteração
    * @param o_flg_show               Indica se deve ser mostrada uma mensagem (Y / N)
    * @param o_msg_title              Título da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_msg_text               Texto da mensagem a mostrar ao utilizador, caso O_FLG_SHOW = Y
    * @param o_button                 Botões a mostrar: N - Não, R - lido, C - confirmado 
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.8.3.4
    * @since                          29-10-2013
    **********************************************************************************************/
    FUNCTION cancel_hcn_documentation
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_doc IN epis_documentation.id_epis_documentation%TYPE,
        i_test        IN VARCHAR2,
        o_flg_show    OUT VARCHAR2,
        o_msg_title   OUT VARCHAR2,
        o_msg_text    OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

/********************************************************************************************/

END pk_hcn;
/
