/*-- Last Change Revision: $Rev: 2052673 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2022-12-12 10:53:55 +0000 (seg, 12 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY t_ti_log AS

    g_error        VARCHAR(4000);
    g_package_name VARCHAR2(50) := pk_alertlog.who_am_i;
    g_pk_owner     VARCHAR2(50) := 'ALERT';

    FUNCTION next_seq RETURN NUMBER IS
    
        l_next NUMBER;
    
    BEGIN
    
        SELECT seq_ti_log.nextval
          INTO l_next
          FROM dual;
    
        RETURN l_next;
    
    END next_seq;

    FUNCTION ins_log
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_status IN ti_log.flg_status%TYPE,
        i_id_record  IN ti_log.id_record%TYPE,
        i_flg_type   IN ti_log.flg_type%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        ts_ti_log.ins(id_episode_in       => i_id_episode,
                      id_professional_in  => i_prof.id,
                      flg_status_in       => i_flg_status,
                      id_record_in        => i_id_record,
                      flg_type_in         => i_flg_type,
                      dt_creation_tstz_in => current_timestamp,
                      rows_out            => l_rows);
    
        t_data_gov_mnt.process_insert(i_lang, i_prof, 'TI_LOG', l_rows, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'INS_LOG',
                                              o_error);
            RETURN FALSE;
    END ins_log;

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
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        ts_ti_log.upd(id_ti_log_in         => i_id_ti_log,
                      id_episode_in        => i_id_episode,
                      id_professional_in   => i_prof.id,
                      flg_status_in        => i_flg_status,
                      id_record_in         => i_id_record,
                      flg_type_in          => i_flg_type,
                      dt_creation_tstz_in  => current_timestamp,
                      id_episode_nin       => FALSE,
                      id_professional_nin  => FALSE,
                      id_record_nin        => FALSE,
                      flg_type_nin         => FALSE,
                      dt_creation_tstz_nin => FALSE,
                      rows_out             => l_rows);
    
        t_data_gov_mnt.process_update(i_lang, i_prof, 'TI_LOG', l_rows, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'UPD_LOG',
                                              o_error);
            RETURN FALSE;
    END upd_log;

    FUNCTION del_log
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_id_ti_log IN ti_log.id_ti_log%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_rows table_varchar;
    
    BEGIN
    
        ts_ti_log.del(id_ti_log_in => i_id_ti_log, rows_out => l_rows);
    
        t_data_gov_mnt.process_delete(i_lang, i_prof, 'TI_LOG', l_rows, o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'DEL_LOG',
                                              o_error);
            RETURN FALSE;
    END del_log;

    FUNCTION get_epis_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_status   IN ti_log.flg_status%TYPE,
        i_id_record    IN ti_log.id_record%TYPE,
        i_flg_type     IN ti_log.flg_type%TYPE
    ) RETURN NUMBER IS
    
        l_id_epis_type epis_type.id_epis_type%TYPE;
    
        l_error t_error_out;
    BEGIN
    
        BEGIN
        
            SELECT nvl(t.id_epis_type, i_id_epis_type)
              INTO l_id_epis_type
              FROM (SELECT epi.id_epis_type, rank() over(ORDER BY tl.id_ti_log) rn
                      FROM ti_log tl
                      JOIN episode epi
                        ON tl.id_episode = epi.id_episode
                     WHERE tl.id_record = i_id_record
                       AND tl.flg_type = i_flg_type
                       AND tl.flg_status = i_flg_status) t
             WHERE t.rn = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_type := NULL;
            
        END;
    
        RETURN l_id_epis_type;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'get_epis_type',
                                              l_error);
            RETURN NULL;
    END get_epis_type;

    FUNCTION get_epis_type_soft
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_type IN epis_type.id_epis_type%TYPE,
        i_flg_status   IN ti_log.flg_status%TYPE,
        i_id_record    IN ti_log.id_record%TYPE,
        i_flg_type     IN ti_log.flg_type%TYPE
    ) RETURN NUMBER IS
    
        l_id_software software.id_software%TYPE;
    
        l_error t_error_out;
    
    BEGIN
        l_id_software := pk_episode.get_soft_by_epis_type(get_epis_type(i_lang,
                                                                        i_prof,
                                                                        i_id_epis_type,
                                                                        i_flg_status,
                                                                        i_id_record,
                                                                        i_flg_type),
                                                          i_prof.institution);
    
        RETURN l_id_software;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := pk_message.get_message(i_lang, 'COMMON_M001');
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_EPIS_TYPE_SOFT',
                                              l_error);
            RETURN NULL;
    END get_epis_type_soft;

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
    ) RETURN VARCHAR2 IS
    
        l_ret sys_message.desc_message%TYPE;
    
        l_error t_error_out;
    
    BEGIN
    
        g_error := 'begin';
        l_ret   := i_desc;
    
        -- se é diferente retorna a origem concatenado
        IF i_id_epis_type !=
           nvl(t_ti_log.get_epis_type(i_lang, i_prof, i_id_epis_type, i_flg_status, i_id_record, i_flg_type),
               i_id_epis_type)
        THEN
            g_error := 'concat origin epis_type';
            l_ret   := l_ret || ' - (' || pk_message.get_message(i_lang,
                                                                 profissional(i_prof.id,
                                                                              i_prof.institution,
                                                                              t_ti_log.get_epis_type_soft(i_lang,
                                                                                                          i_prof,
                                                                                                          i_id_epis_type,
                                                                                                          i_flg_status,
                                                                                                          i_id_record,
                                                                                                          i_flg_type)),
                                                                 
                                                                 'IMAGE_T009') || ')';
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'GET_DESC_WITH_ORIGIN',
                                              l_error);
            RETURN NULL;
    END get_desc_with_origin;

BEGIN

    pk_alertlog.who_am_i(g_pk_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END t_ti_log;
/
