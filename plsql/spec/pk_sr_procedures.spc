/*-- Last Change Revision: $Rev: 2028984 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:07 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_procedures AS

    /********************************************************************************************
    * Actualiza o detalhe da visita p�s-operat�ria
    *
    * @param i_lang             Id do idioma
    * @param i_prof             ID do profissional, institui��o e software
    * 
    * @param o_subcat           Sub-categoria do profissional
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/06/15
    ********************************************************************************************/
    FUNCTION get_prof_subcat
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_subcat OUT VARCHAR2,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obtem a descri��o de um item do acolhimento
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * @param i_prof             ID do profissional, institui��o e software
    * @param i_sql_cursor       SQL a executar para obter a descri��o do item de acolhimento
    * @param i_label            Label a mostrar para a descri��o do item de acolhimento
    * 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Batista
    * @since                    2006/08/18
    ********************************************************************************************/
    FUNCTION get_receive_item_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        
        i_sql_cursor IN VARCHAR2,
        i_label      IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Obt�m a �ltima informa��o, caso exista, na tabela SR_RECEIVE para um dado epis�dio. Caso n�o 
    *   exista a informa��o, as vari�veis de sa�da ter�o os valores default.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * 
    * @param o_status           Indica o estado de admiss�o. (Y- Admitido para cirurgia; N- N�o admitido para cirurgia). Default=N
    * @param o_manual           Indica se a �ltima informa��o � decorrente de interven��o manual ou autom�tica. (Y-Manual; N-Autom�tica). Default=N
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_sr_receive
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_status  OUT VARCHAR2,
        o_manual  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Obt�m o estado de admiss�o no bloco para o epis�dio, indicando se o mesmo � obtido de forma autom�tica 
    *  (verifica��o das respostas �s perguntas obrigat�rias) ou manual (alterado por um profissional).
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * @param i_transaction_id   Transaction ID
    * @param o_status           Indica o estado de admiss�o. (Y- Admitido para cirurgia; N- N�o admitido para cirurgia)
    * @param o_manual           Indica se o estado obtido � obtido a partir de uma altera��o manual por um profissional. 
    *                              (Y- Manual; N- Autom�tico)
    * @param o_title            T�tulo a mostrar no ecr� (Ex: 'Admitido para cirurgia')
    * @param o_status_labels    Cursor com as labels correspondentes a cada valor de status.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_receive_status
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_transaction_id IN VARCHAR2,
        o_status         OUT VARCHAR2,
        o_manual         OUT VARCHAR2,
        o_title          OUT VARCHAR2,
        o_status_labels  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USED BY UX!
    * Obt�m o estado de admiss�o no bloco para o epis�dio, indicando se o mesmo � obtido de forma autom�tica 
    *  (verifica��o das respostas �s perguntas obrigat�rias) ou manual (alterado por um profissional).
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * 
    * @param o_status           Indica o estado de admiss�o. (Y- Admitido para cirurgia; N- N�o admitido para cirurgia)
    * @param o_manual           Indica se o estado obtido � obtido a partir de uma altera��o manual por um profissional. 
    *                              (Y- Manual; N- Autom�tico)
    * @param o_title            T�tulo a mostrar no ecr� (Ex: 'Admitido para cirurgia')
    * @param o_status_labels    Cursor com as labels correspondentes a cada valor de status.
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION get_receive_status
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        o_status        OUT VARCHAR2,
        o_manual        OUT VARCHAR2,
        o_title         OUT VARCHAR2,
        o_status_labels OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Verifica se todas as checklist do master est�o com estado Verificado. Se sim, altera tamb�m
    *   o estado do master para verificado
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * @param i_status           Indica o novo estado a criar. (Y- Admitido; N- N�o admitido)
    * @param i_prof             ID do profissional, institui��o e software
    * @param i_test             Indica se deve ser feita a valida��o
    * 
    * @param o_flg_show         Y - existe msg para mostrar; N - n�o existe   
    * @param o_unverif_items    Cursor com os items n�o verificados
    * @param o_title            T�tulo da mensagem
    * @param o_msg_text         Texto a apresentar no ecr� caso a lista de items n�o verificados n�o contenha elementos.
    * @param o_button           Bot�es a mostrar: N - n�o, R - lido, C - confirmado 
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION set_sr_receive
    (
        i_lang          IN language.id_language%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_status        IN VARCHAR2,
        i_prof          IN profissional,
        i_doc_template  IN doc_template.id_doc_template%TYPE,
        i_test          IN VARCHAR2,
        o_flg_show      OUT VARCHAR2,
        o_unverif_items OUT pk_types.cursor_type,
        o_title         OUT VARCHAR2,
        o_button        OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Fun��o a ser chamada quando h� uma actualiza��o na avalia��o de acolhimento para o bloco. Esta fun��o 
    *   vai validar se o estado de admiss�o � autom�tico e caso seja, valida se as perguntas obrigat�rias 
    *   j� foram respondidas e caso tenham sido, adiciona uma nova entrada � SR_RECEIVE.
    *
    * @param i_lang             Id do idioma
    * @param i_episode          Id do epis�dio
    * @param i_status           Indica o novo estado a criar. (Y- Admitido; N- N�o admitido)
    * @param i_prof             ID do profissional, institui��o e software
    * 
    * @param o_status           Estado da admiss�o (Y-Admitido; N-N�o admitido)
    * @param o_manual           Indica se o estado de admiss�o � decorrente de interven��o manual ou 
    *                            valida��o autom�tica. (Y-Manual; N-Autom�tica)
    * @param o_unverif_items    Cursor com os items n�o verificados
    * @param o_title            Titulo da janela a apresentar caso O_UNVERIF_ITEMS tenha elementos
    * @param o_button           Bot�es a apresentar caso O_UNVERIF_ITEMS tenha elementos.  
    * @param o_error            Mensagem de erro
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Rui Campos
    * @since                    2006/11/02
    ********************************************************************************************/
    FUNCTION update_receive
    (
        i_lang           IN language.id_language%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_prof           IN profissional,
        i_doc_template   IN doc_template.id_doc_template%TYPE,
        i_transaction_id IN VARCHAR2,
        o_status         OUT sr_receive.flg_status%TYPE,
        o_manual         OUT sr_receive.flg_manual%TYPE,
        o_unverif_items  OUT pk_types.cursor_type,
        o_title          OUT VARCHAR2,
        o_button         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --
    -- Constants
    --
    g_sysdate_tstz TIMESTAMP
        WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_found        BOOLEAN;

    g_sr_dept         CONSTANT INTEGER := pk_sysconfig.get_config('SURGERY_ROOM_DEPT', 0, 0);
    g_default_val     CONSTANT VARCHAR2(1) := 'N';
    g_rec_default_val CONSTANT VARCHAR2(1) := 'X';

    g_value_na CONSTANT VARCHAR2(1) := 'A';
    g_value_t  CONSTANT VARCHAR2(1) := 'T';

    g_flg_status_can CONSTANT VARCHAR2(1) := 'C'; --Status Cancelado
    g_flg_status_ter CONSTANT VARCHAR2(1) := 'F'; --Status terminado

    g_cat_type_doctor CONSTANT category.flg_type%TYPE := 'G';
    g_cat_type_anest  CONSTANT category.flg_type%TYPE := 'A';

    g_reserv_req  CONSTANT VARCHAR2(1) := 'R';
    g_reserv_exec CONSTANT VARCHAR2(1) := 'F';
    g_reserv_canc CONSTANT VARCHAR2(1) := 'C';

    g_posit_req  CONSTANT VARCHAR2(1) := 'R';
    g_posit_exec CONSTANT VARCHAR2(1) := 'F';
    g_posit_canc CONSTANT VARCHAR2(1) := 'C';

    g_surg_per_pre CONSTANT VARCHAR2(1) := 'P';

    g_room_status_f CONSTANT VARCHAR2(1) := 'F';
    g_room_status_b CONSTANT VARCHAR2(1) := 'B';
    g_room_status_c CONSTANT VARCHAR2(1) := 'C';
    g_room_status_d CONSTANT VARCHAR2(1) := 'D';

    g_active   CONSTANT VARCHAR2(1) := 'A';
    g_canceled CONSTANT VARCHAR2(1) := 'C';

    g_mandatory_y CONSTANT PLS_INTEGER := 1;
    g_mandatory_n CONSTANT PLS_INTEGER := 0;

    g_pat_status_a CONSTANT VARCHAR2(1) := 'A'; --Estado do paciente: Ausente
    g_pat_status_w CONSTANT VARCHAR2(1) := 'W'; --Estado do paciente: Em espera
    g_pat_status_l CONSTANT VARCHAR2(1) := 'L'; --Estado do paciente: Pedido de transporte para o bloco
    g_pat_status_t CONSTANT VARCHAR2(1) := 'T'; --Estado do paciente: Em transporte para o bloco
    g_pat_status_v CONSTANT VARCHAR2(1) := 'V'; --Estado do paciente: Acolhido no Bloco

    g_receive_doc_area CONSTANT doc_area.id_doc_area%TYPE := 7;
    g_flg_type_rec     CONSTANT epis_prof_rec.flg_type%TYPE := 'R';

    g_exception EXCEPTION; -- CRS 2006/02/16 
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_sr_procedures;
/
