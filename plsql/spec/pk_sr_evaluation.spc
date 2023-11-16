/*-- Last Change Revision: $Rev: 2028979 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:05 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_evaluation AS

    FUNCTION get_eval_item_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_patient    IN patient.id_patient%TYPE,
        i_prof       IN profissional,
        i_sql_cursor IN VARCHAR2,
        i_label      IN VARCHAR2
    ) RETURN VARCHAR2;
    /******************************************************************************
       OBJECTIVO:   Obtem a descrição de um item da avaliação
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                          I_PATIENT - ID do paciente
                                      I_PROF - ID do profissional, instituição e software
                                              I_SQL_CURSOR - SQL a executar para obter a descrição do item de acolhimento
                                              I_LABEL - Label a mostrar para a descrição do item de acolhimento
                           SAIDA:
    
      CRIAÇÃO: RB 2006/09/15
      NOTAS:
    *********************************************************************************/

    FUNCTION get_eval_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem a lista de tipos de avaliações
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                      I_PROF - ID do profissional, software e instituição
                  I_PROF_CAT_TYPE - Categoria do profissional (N-Enfermeiro, D-Médico)
                                              I_SURG_PERIOD - ID do periodo operatório. Valores possíveis:
                                                  1- Pré-operatório
                                                          2- Intra-operatório
                                                          3- Pós-operatório
                           SAIDA:   O_LIST - Lista dos tipos de avaliações
                                O_ERROR - erro
    
      CRIAÇÃO: RB 2006/09/28
      NOTAS:
    *********************************************************************************/

    FUNCTION get_reg_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        i_type          IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obtem a lista de tipos de registos
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                      I_PROF - ID do profissional, software e instituição
                  I_PROF_CAT_TYPE - Categoria do profissional (N-Nurse; D-Doctor, A-Auxiliar)
                                              I_SURG_PERIOD - ID do periodo operatório. Valores possíveis:
                                                  1- Pré-operatório
                                                          2- Intra-operatório
                                                          3- Pós-operatório
                                                          4- Registos que não sejam avaliações
                                              I_TYPE - Tipo de registos. Valores possíveis:
                                                      N- Avaliações de enfermagem
                                                      D- Registos do cirurgião e anestesista
                           SAIDA:   O_LIST - Lista dos tipos de registos
                                O_ERROR - erro
    
      CRIAÇÃO: RB 2006/11/02
      NOTAS:
    *********************************************************************************/

    FUNCTION check_pat_status_period
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_surg_period IN sr_surg_period.id_surg_period%TYPE,
        i_doc_area    IN doc_area.id_doc_area%TYPE,
        o_flg_show    OUT VARCHAR2,
        o_msg_result  OUT VARCHAR2,
        o_title       OUT VARCHAR2,
        o_button      OUT VARCHAR2,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Verifica se é possível realizar avaliaçoes para um dado periodo operatório, baseando-se no estado do paciente
              para determinar qual o estado operatório em que este se encontra.
            A regra é:
              - Se periodo operatorio paciente < I_SURG_PERIOD
                .Mensagem de erro e não pode ser feita a avaliação.
              - Se periodo operatorio paciente = I_SURG_PERIOD
                .Não mostra mensagem
              - Se periodo operatorio paciente > I_SURG_PERIOD
                . Mostra mensagem de aviso com possibilidade do profissional continuar.
    
            EXCEPÇÕES:
              - Se o periodo do operatorio do paciente for 1 (Pré-operatório) e I_SURG_PERIOD=2 e a avaliação for correspondente ao Acolhimento no Bloco,
                deixa continuar, dado que para o paciente passar para o estado de Admitido no bloco é necessário realizar esta avaliação.
    
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                      I_PROF - ID do profissional, software e instituição
                  I_EPISODE - ID do episódio
                                              I_SURG_PERIOD - ID do periodo operatório. Valores possíveis:
                                                  1- Pré-operatório
                                                          2- Intra-operatório
                                                          3- Pós-operatório
                     I_DOC_AREA - ID da avaliação que o profissional está a tentar criar.
                           SAIDA:   O_FLG_SHOW - Indica se existe uma mensagem para mostrar ao utilizador. Valores possíveis:
                                Y - Mostrar a mensagem
                            N - Não mostrar a mensagem
                O_MSG_RESULT - Mensagem a apresentar
                O_TITLE - Título da mensagem
                O_BUTTON - Botões a apresentar. Combinação dos possíveis valores:
                        N - Botão de não confirmação
                        C - Botão de confirmação/lido
                                O_ERROR - erro
    
      CRIAÇÃO: Rui Campos 2006/11/09
      ALTERAÇÕES: Rui Campos 2006/11/22:
                - Adicionado I_DOC_AREA e excepção para Acolhimento no Bloco.
      NOTAS:
    *********************************************************************************/

    FUNCTION check_eval_rule
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_doc_area  IN doc_area.id_doc_area%TYPE,
        o_flg_show  OUT VARCHAR2,
        o_msg_title OUT VARCHAR2,
        o_msg_text  OUT VARCHAR2,
        o_button    OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Valida se existe alguma regra para a avaliação (mensagem a mostrar caso se verifiquem algumas respostas)
              e caso a regra se verifique devolve a mensagem a apresentar.
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                                      I_PROF - ID do profissional, software e instituição
                                              I_EPISODE - ID do episódio
                                              I_DOC_AREA - ID da área
                           SAIDA:   O_FLG_SHOW - Indica se deve ser apresentada mensagem (Y/N)
                    O_MSG_TITLE - Título da mensagem
                O_MSG_TEXT - Texto da mensagem
                O_BUTTON - Botões a apresentar. Combinação de:
                        C - Confirmar/Lido
                        N - Não confirmar
                        R - Lido
                O_ERROR - Erro, caso aconteça
    
      CRIAÇÃO: Rui Campos 2006/11/17
      NOTAS:
    *********************************************************************************/

    FUNCTION get_summ_page_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_prof_cat_type IN category.flg_type%TYPE,
        i_surg_period   IN sr_surg_period.id_surg_period%TYPE,
        i_type          IN VARCHAR2,
        o_list          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get number of records registered in given operative period
    *
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    * @param    i_surg_period    ID of surgical period. Possible values:
    *                              1- Pre-operative
    *                              2- Intra-operative
    *                              3- Pós-operativbe
    *                              4- Requests that are not assessments
    * @param    i_type           Records type. POssible values: E- Assessment, R- Records
    *
    * @return              Count of records
    *
    * @author              Anna Kurowska
    * @since               2016/10/26
    ********************************************************************************************/
    FUNCTION get_eval_register_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope_type  IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        i_patient     IN patient.id_patient%TYPE,
        i_surg_period IN sr_surg_period.id_surg_period%TYPE,
        i_type        IN sr_eval_summ.flg_type%TYPE
    ) RETURN NUMBER;

    g_sysdate DATE;
    g_error   VARCHAR2(2000);
    g_found   BOOLEAN;

    g_available CONSTANT VARCHAR2(1) := 'Y';
    g_value_y   CONSTANT VARCHAR2(1) := 'Y';
    g_value_n   CONSTANT VARCHAR2(1) := 'N';

    g_active CONSTANT VARCHAR2(1) := 'A';
    g_cancel CONSTANT VARCHAR2(1) := 'C';
    g_finish CONSTANT VARCHAR2(1) := 'F';

    g_cat_type_doctor     CONSTANT category.flg_type%TYPE := 'G';
    g_cat_type_anest      CONSTANT category.flg_type%TYPE := 'A';
    g_criteria            CONSTANT VARCHAR2(1) := 'I';
    g_value_document_type CONSTANT PLS_INTEGER := 1;

    g_pre_op_period   CONSTANT PLS_INTEGER := 1;
    g_intra_op_period CONSTANT sr_surg_period.id_surg_period%TYPE := 2;
    g_post_op_period  CONSTANT sr_surg_period.id_surg_period%TYPE := 3;

    g_flg_view_summary CONSTANT doc_element_crit.flg_view%TYPE := 'S';

    g_no_period      CONSTANT NUMBER := 0;
    g_default_period CONSTANT NUMBER := 1; -- Pré-Operatório

    g_access_all CONSTANT category.flg_type%TYPE := 'X';

    g_receive_doc_area CONSTANT doc_area.id_doc_area%TYPE := 7;
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_eval_type_assess CONSTANT sr_eval_summ.flg_type%TYPE := 'E';
    g_eval_type_record CONSTANT sr_eval_summ.flg_type%TYPE := 'R';

END pk_sr_evaluation;
/
