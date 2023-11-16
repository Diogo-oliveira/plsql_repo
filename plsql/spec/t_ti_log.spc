/*-- Last Change Revision: $Rev: 2029423 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:51:35 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE t_ti_log AS

    FUNCTION next_seq RETURN NUMBER;

    FUNCTION ins_log
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN ti_log.flg_status%TYPE,
        i_id_record  IN ti_log.id_record%TYPE,
        i_flg_type   IN ti_log.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION upd_log
    (
        i_lang       IN language.id_language%TYPE,
        i_id_ti_log  IN ti_log.id_ti_log%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional,
        i_flg_status IN ti_log.flg_status%TYPE,
        i_id_record  IN ti_log.id_record%TYPE,
        i_flg_type   IN ti_log.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION del_log
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ti_log IN ti_log.id_ti_log%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_status   IN ti_log.flg_status%TYPE,
        i_id_record    IN ti_log.id_record%TYPE,
        i_flg_type     IN ti_log.flg_type%TYPE
    ) RETURN NUMBER;

    FUNCTION get_epis_type_soft
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_status   IN ti_log.flg_status%TYPE,
        i_id_record    IN ti_log.id_record%TYPE,
        i_flg_type     IN ti_log.flg_type%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Returns the i_desc concatenated with the origin epis_type description if it's 
    * different from the one passed in parameter
    *
    * %param i_lang                   id_language
    * %param i_prof                   id_professional
    * %param i_desc                   description
    * %param i_id_epis_type           
    * %param i_flg_status 
    * %param i_id_record 
    * %param i_flg_type 
    *
    * @return                         description
    *
    * @author                         Eduardo Reis
    * @version                        1.0
    * @since                          2010-09-09
    **********************************************************************************************/
    FUNCTION get_desc_with_origin
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_desc         IN VARCHAR2,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_status   IN ti_log.flg_status%TYPE,
        i_id_record    IN ti_log.id_record%TYPE,
        i_flg_type     IN ti_log.flg_type%TYPE
    ) RETURN VARCHAR2;

END t_ti_log;
/
