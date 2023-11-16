/*-- Last Change Revision: $Rev: 2028981 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:06 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sr_output AS
    -- update_sr_chklist_det; insert_sr_chklist_det; update_sr_chklist_det_status; delete_sr_chklist_det

    FUNCTION insert_interv_description
    (
        i_lang                IN language.id_language%TYPE,
        i_sr_epis_interv_desc IN sr_epis_interv_desc%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_interv_description
    (
        i_lang                IN language.id_language%TYPE,
        i_sr_epis_interv_desc IN sr_epis_interv_desc%ROWTYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Insere a descrição da intervenção
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                             I_EPIS_INTERV_DESC - Dados da intervenção
                    SAIDA:   O_ID_SR_EPIS_INTERV_DESC - Registo criado
                             O_ERROR - erro
    
      CRIAÇÃO: 
      NOTAS:
      EDIÇÃO: Sergio Dias
      NOTAS:  6-9-2010
    *********************************************************************************/

    FUNCTION insert_sr_epis_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_epis_interv_desc       IN sr_epis_interv_desc%ROWTYPE,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_sr_reserv_req_status
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sr_reserv_req
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_sr_reserv_req
    (
        i_lang       IN language.id_language%TYPE,
        i_reserv_req IN sr_reserv_req%ROWTYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sr_epis_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv%ROWTYPE,
        i_id_ct_io       IN table_varchar DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_sr_epis_interv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_sr_epis_interv IN sr_epis_interv%ROWTYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt_last IN DATE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    -- José Brito 29/08/2008 Criada para evitar ROLLBACK/COMMIT na interacção com a função de cancelamento de episódios
    FUNCTION c_update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_dt_last IN DATE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Actualiza a data da última interacção do utilizador num episódio (utilizado no ADW)
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                          I_EPISODE - ID do episódio
                                              I_DT_LAST - Data da última alteração
                           SAIDA:   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/04
      NOTAS:
    *********************************************************************************/

    FUNCTION update_dt_last_interaction
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        i_prof    IN profissional,
        i_dt_last IN VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_patient_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_room       IN room.id_room%TYPE,
        i_dt_mov_str IN VARCHAR2,
        i_action     IN VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Actualiza o estado do paciente devido a requisição/início de transportes
       PARAMETROS:  ENTRADA: I_LANG - Língua registada como preferência do profissional
                    I_PROF - ID do profissional, software e instituição
                          I_EPISODE - ID do episódio
                                              I_ROOM - ID da sala de destino do transporte
                                              I_DT_MOV - Data da requisição/início do transporte
                                              I_ACTION - Indica que tipo de acção se trata. Valores possíveis:
                                                  R- Requisição de transporte
                                                          B- Início do transporte
                                                          C- Cancelamento do transporte
                           SAIDA:   O_ERROR - erro
    
      CRIAÇÃO: RB 2006/10/19
      NOTAS:
    *********************************************************************************/

    /********************************************************************************************
    *  Get the closer ORIS episode when I make a request of patient transport
    *
    * @param i_lang        Language ID
    * @param i_prof        Professional  
    * @param i_movement     id_movement
    *
    * @param o_oris_episode ORIS episode
    * @param o_id_room      id room
    * @param o_error       Error message
    *
    * @return              TRUE/FALSE
    *
    * @author              Filipe Silva
    * @since               2009/09/24
     ********************************************************************************************/
    FUNCTION get_oris_episode
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_movement     IN movement.id_movement%TYPE,
        o_oris_episode OUT episode.id_episode%TYPE,
        o_id_room      OUT room.id_room%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sr_epis_interv_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_id_ct_io          IN table_varchar DEFAULT NULL,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /***************************************************************
    * set_ia_event_prescription Logic entry funtion
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    *
    * @author Paulo Teixeira
    * @version 2.6.3.2
    * @since 2013/01/25
    ***************************************************************/
    FUNCTION set_ia_event_prescription
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_flg_action        IN VARCHAR2,
        i_id_sr_epis_interv IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_flg_status_new    IN sr_epis_interv.flg_status%TYPE,
        i_flg_status_old    IN sr_epis_interv.flg_status%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION insert_sr_epis_interv_mod_fact
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv_hist IN sr_epis_interv_hist.id_sr_epis_interv_hist%TYPE,
        i_id_ct_io               IN table_varchar DEFAULT NULL,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_error        VARCHAR2(2000);
    g_sr_dept      INTEGER;
    g_found        BOOLEAN;

    --Estados do paciente
    --A-Ausente, W- Em espera, L- Pedido de transporte para o bloco, T- Em transporte para o bloco, V- Acolhido no bloco, P- Em preparação,
    --R- Preparado para a cirurgia, S- Em cirurgia, F- Terminou a cirurgia, Y- No recobro, D- Alta do Recobro, O- Em transporte para outro local no hospital ou noutra instituição
    g_pat_status_a CONSTANT VARCHAR2(1) := 'A';
    g_pat_status_w CONSTANT VARCHAR2(1) := 'W';
    g_pat_status_l CONSTANT VARCHAR2(1) := 'L';
    g_pat_status_t CONSTANT VARCHAR2(1) := 'T';
    g_pat_status_v CONSTANT VARCHAR2(1) := 'V';
    g_pat_status_p CONSTANT VARCHAR2(1) := 'P';
    g_pat_status_r CONSTANT VARCHAR2(1) := 'R';
    g_pat_status_s CONSTANT VARCHAR2(1) := 'S';
    g_pat_status_f CONSTANT VARCHAR2(1) := 'F';
    g_pat_status_y CONSTANT VARCHAR2(1) := 'Y';

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

END pk_sr_output;
/
