/*-- Last Change Revision: $Rev: 2028940 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_save AS
    /******************************************************************************
       NAME:       pk_save
       PURPOSE:
    
       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        05-04-2005             1. Created this package.
    ******************************************************************************/

    /******************************************************************************
    * Same as SET_TEMP_DEFINITIVE. Just for INTERNAL USE by database.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito
    * @version                 0.1
    * @since                   2009/01/09
    *
    ******************************************************************************/
    FUNCTION call_set_temp_definitive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
    * Alterar flags de registos Temporários (T) para Definitvos (D) para um determinado episódio
    * e determinado professional. Um profissional só pode passar para definitivos os temporários
    * que lhe pertençam.
    * Se o parâmetro I_ID_EPISODE não estiver preenchido, altera para todos os episódios do profissional.
    *
    * ALTER: não verificar por profissional. Ao passar para definitivos passa todos mesmo que
    * tenham sido registados por outro profissional. UPDATE para as tabelas EPIS_RECOMEND e NURSE_DISCHARGE.
    * 
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  RB
    * @version                 0.1
    * @since                   2005/04/05
    *
    * @alter                   SS
    * @version                 0.2
    * @since                   2006/10/12
    *
    * @alter                   José Brito
    * @version                 0.3
    * @since                   2009/01/09
    *
    ******************************************************************************/
    FUNCTION set_temp_definitive
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE set_temp_definitive;

    FUNCTION check_temp_definitive
    (
        i_lang     IN language.id_language%TYPE,
        i_episode  IN epis_anamnesis.id_episode%TYPE,
        i_flg_type IN epis_anamnesis.flg_type%TYPE,
        i_prof     IN profissional,
        o_id       OUT epis_anamnesis.id_epis_anamnesis%TYPE,
        o_exist    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Verificar se os registos já passaram de temporários para definitivos 
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional 
               I_EPISODE - ID do episódio
             I_FLG_TYPE - C: queixa 
                  A: anamnese 
                  O: exame físico 
              Saida: O_ID: ID do último registo definitivo registado antes da passagem de temporários para definitivos
             O_EXIST - Y: se já passaram a definitivos
                   N: caso contrário 
             O_ERROR - erro 
      
      CRIAÇÃO: SS 2006/10/12 
      NOTAS: 
    *********************************************************************************/

    FUNCTION get_exist_rec_temp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION check_exist_rec_temp
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_exist_temp_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_prof              IN profissional,
        i_flg_type          IN epis_anamnesis.flg_type%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_exist_temp_observation
    (
        i_lang                IN language.id_language%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_prof                IN profissional,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION get_exist_temp_obs_exam
    (
        i_lang       IN language.id_language%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2;

    FUNCTION upd_temp_epis_observation
    (
        i_lang             IN language.id_language%TYPE,
        i_epis_observation IN epis_observation%ROWTYPE,
        i_dt_str           IN VARCHAR2,
        i_prof             IN profissional,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_flg_temp_epis_obs
    (
        i_lang                IN language.id_language%TYPE,
        i_id_epis_observation IN epis_observation.id_epis_observation%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_temp_epis_obs_exam
    (
        i_lang          IN language.id_language%TYPE,
        i_epis_obs_exam IN epis_obs_exam%ROWTYPE,
        i_dt_str        IN VARCHAR2,
        i_prof          IN profissional,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_flg_temp_epis_obs_exam
    (
        i_lang             IN language.id_language%TYPE,
        i_id_epis_obs_exam IN epis_obs_exam.id_epis_obs_exam%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_temp_epis_anamnesis
    (
        i_lang           IN language.id_language%TYPE,
        i_epis_anamnesis IN epis_anamnesis%ROWTYPE,
        i_dt_str         IN VARCHAR2,
        i_prof           IN profissional,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_flg_temp_epis_anamnesis
    (
        i_lang              IN language.id_language%TYPE,
        i_id_epis_anamnesis IN epis_anamnesis.id_epis_anamnesis%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    g_error       VARCHAR2(2000);
    g_flg_temp    epis_anamnesis.flg_temp%TYPE;
    g_flg_def     epis_anamnesis.flg_temp%TYPE;
    g_found_true  VARCHAR2(1);
    g_found_false VARCHAR2(1);
    g_found       BOOLEAN;

    g_complaint epis_anamnesis.desc_epis_anamnesis%TYPE;
    g_anamnesis epis_anamnesis.desc_epis_anamnesis%TYPE;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_package_name  VARCHAR2(30);
    g_package_owner VARCHAR2(30);

END pk_save;
/
