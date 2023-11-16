/*-- Last Change Revision: $Rev: 2028670 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:14 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_edis_viewer IS

    /**
    * Devolve a informação necessária para preencher o ecran com a contagem dos tempos e episódios.
    * Os títulos a apresentar na vista são os seguintes: - WLINE_VIEWER_T001, WLINE_VIEWER_T002, WLINE_VIEWER_T005
    *
    * @param     i_lang         id da lingua
    * @param     i_prof
    * @param     i_department   id do departamento para o qual se listam episódios
    * @param     o_epis         cursor com dados de saida. Colunas: 
    *                             - color cor da triagem
    *                             - color_text cor do texto que sobrepõe a cor da triagem
    *                             - rank número para ordenar as cores
    *                             - num_epis_total número total de episódios por cor
    *                             - num_epis_not_obs número de pacientes por triar ou observar
    *                             - desc_num_epis_not_obs formatação em texto do campo num_epis_not_obs
    *                             - minutes_to_wait tempo de espera para uma dada cor de triagem, ou para ser triado, devidamente formatado
    * @param     o_dt_server    data do servidor
    * @param     o_total_epis   número total de pacientes no departamento
    * @param     o_error        variavel com mensagem de erro    
    *    
    * @return    true or false on success or error
    *  
    * @author    João Eiras
    * @version   2.4.0
    * @since     2007/05/05
    */
    FUNCTION get_wline_data
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_epis        OUT pk_types.cursor_type,
        o_total_epis  OUT NUMBER,
        o_department  OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Formates the passed minutes as HH:MI
    *
    * @param     i_lang      language id
    * @param     i_minutes   the minutes
    *
    * @return    string
    *    
    * @author    João Eiras
    * @version   2.4.0    
    * @since     2007/08/16
    */

    FUNCTION get_format_wait_time
    (
        i_lang    IN language.id_language%TYPE,
        i_minutes IN NUMBER
    ) RETURN VARCHAR2;

    /**
    * Calls PK_SYSCONFIG.GET_CONFIG. This is only an interface function as PK_SYSCONFIG is not a public service
    *
    * @param     i_code_cf config id
    * @param     i_institution institution for where the configuration is to be retrieved
    * @param     o_msg_cf Response containing the configured value
    *
    * @return    true or false on success or error
    *
    * @author    Alexandre Santos
    * @version   2.6.4.2
    * @since     
    */

    FUNCTION get_config
    (
        i_code_cf     IN table_varchar,
        i_institution IN NUMBER,
        o_msg_cf      OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_error VARCHAR2(4000);

    g_triage_color_red CONSTANT triage_color.id_triage_color%TYPE := 2;

END pk_edis_viewer;
/
