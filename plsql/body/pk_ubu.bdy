/*-- Last Change Revision: $Rev: 2027825 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:43:25 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ubu AS

    FUNCTION get_id_ext_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retorna o ID_EPISODE se for do SONHO
           PARAMETROS:  ENTRADA: I_ID_EPISODE - Episódio        
                                 
                        SAIDA:   O_ERROR - erro 
          
          CRIAÇÃO: Teresa Coutinho 2007/07/13
          NOTAS:   
        *********************************************************************************/
        CURSOR c_epis_ext_sys IS
            SELECT ees.id_episode
              FROM epis_ext_sys ees, external_sys es
             WHERE upper(es.intern_name_ext_sys) = 'SONHO'
               AND es.id_external_sys = ees.id_external_sys
               AND ees.id_episode = i_id_episode;
    
        l_epis_ext_sys epis_ext_sys.id_episode%TYPE;
    BEGIN
        g_error := 'OPEN C_EPIS_EXT_SYS';
        OPEN c_epis_ext_sys;
        FETCH c_epis_ext_sys
            INTO l_epis_ext_sys;
        CLOSE c_epis_ext_sys;
    
        RETURN l_epis_ext_sys;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UBU',
                                              'GET_ID_EXT_EPISODE',
                                              o_error);
            RETURN NULL;
    END;

    FUNCTION get_date_transportation(i_id_episode IN episode.id_episode%TYPE) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        /******************************************************************************
                    OBJECTIVO:   Retorna DATA do transporte
                    PARAMETROS:  ENTRADA: I_ID_EPISODE - Episódio 
                                          
                                 SAIDA:   O_ERROR - erro 
                   
                   CRIAÇÃO: Teresa Coutinho 2007/07/13
                   NOTAS:   
        *********************************************************************************/
        CURSOR c_dt_transp IS
            SELECT MIN(t.dt_transportation_tstz)
              FROM transportation t
             WHERE t.id_episode = i_id_episode;
        l_dt_transp transportation.dt_transportation_tstz%TYPE;
    BEGIN
        OPEN c_dt_transp;
        FETCH c_dt_transp
            INTO l_dt_transp;
        CLOSE c_dt_transp;
    
        RETURN l_dt_transp;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
        
    END;

    FUNCTION get_episode_transportation
    (
        i_id_episode IN episode.id_episode%TYPE,
        i_prof       IN profissional DEFAULT NULL,
        -- José Brito 15/10/2008 Added to improve performance on registrar's grid
        i_limit IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retorna ID_EPISODE e a DATA se episodio tiver como episódio anterior um episódio UBU
           PARAMETROS:  ENTRADA: I_ID_EPISODE - Episódio 
                                 I_PROF - Profissional
                                 
                        SAIDA:   O_ERROR - erro 
          
          CRIAÇÃO: Teresa Coutinho 2007/07/13
          NOTAS:   
        *********************************************************************************/
        l_limit TIMESTAMP WITH LOCAL TIME ZONE;
    
        CURSOR c_epis_ext_sys IS
            SELECT 'Y' i_transp
              FROM v_episode_act e, episode ee, transportation t
             WHERE e.id_prev_episode = ee.id_episode
               AND e.id_episode = t.id_episode
               AND e.flg_status_e = g_epis_active
               AND ee.flg_status = g_epis_inactive
               AND e.id_episode = i_id_episode
               AND ee.id_epis_type = g_epis_type_ubu
               AND e.id_epis_type = g_epis_type_urg
               AND (SELECT MAX(d.dt_admin_tstz)
                      FROM discharge d
                     WHERE pk_discharge_core.check_admin_discharge(1, i_prof, NULL, d.flg_status_adm) =
                           pk_alert_constant.g_yes
                       AND d.id_episode = e.id_prev_episode) >= l_limit
            UNION ALL
            SELECT 'N' i_transp
              FROM v_episode_act e, episode ee
             WHERE e.id_prev_episode = ee.id_episode
               AND NOT EXISTS (SELECT 1
                      FROM transportation t
                     WHERE e.id_episode = t.id_episode)
               AND e.flg_status_e = g_epis_active
               AND ee.flg_status = g_epis_inactive
               AND e.id_episode = i_id_episode
               AND ee.id_epis_type = g_epis_type_ubu
               AND e.id_epis_type = g_epis_type_urg
               AND (SELECT MAX(d.dt_admin_tstz)
                      FROM discharge d
                     WHERE pk_discharge_core.check_admin_discharge(1, i_prof, NULL, d.flg_status_adm) =
                           pk_alert_constant.g_yes
                       AND d.id_episode = e.id_prev_episode) >= l_limit;
    
        l_transp VARCHAR2(1);
        l_prof   profissional;
    BEGIN
        IF i_prof IS NULL
        THEN
            l_prof := profissional(NULL, g_default_inst, g_software_ubu);
        ELSE
            l_prof := i_prof;
        END IF;
    
        IF i_limit IS NULL
        THEN
            l_limit := pk_date_utils.add_days_to_tstz(current_timestamp,
                                                      -to_number(pk_sysconfig.get_config('TIME_MAX_ADM_URG_UBU', l_prof) / 24));
        ELSE
            -- José Brito 15/10/2008 Added to improve performance on registrar's grid
            l_limit := i_limit;
        END IF;
    
        g_error := 'OPEN C_EPIS_EXT_SYS';
    
        OPEN c_epis_ext_sys;
        FETCH c_epis_ext_sys
            INTO l_transp;
        CLOSE c_epis_ext_sys;
    
        RETURN l_transp;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END;

    FUNCTION get_admin_discharge_ubu(i_episode IN discharge.id_episode%TYPE) RETURN discharge.dt_admin_tstz%TYPE IS
        /******************************************************************************
           OBJECTIVO:   Retorna a data da alta administrativa
           PARAMETROS:  ENTRADA: I_ID_EPISODE - Episódio      
        
                                 
                        SAIDA:   O_ERROR - erro 
          
          CRIAÇÃO: Teresa Coutinho 2007/07/13
          NOTAS:   
        *********************************************************************************/
        CURSOR c_discharge IS
            SELECT MAX(d.dt_admin_tstz)
              FROM discharge d
             WHERE pk_discharge_core.check_admin_discharge(1, NULL, NULL, d.flg_status_adm) = pk_alert_constant.g_yes
               AND d.id_episode = i_episode;
    
        l_dt_admin discharge.dt_admin_tstz%TYPE;
    BEGIN
        OPEN c_discharge;
        FETCH c_discharge
            INTO l_dt_admin;
        CLOSE c_discharge;
        RETURN l_dt_admin;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.raise_error(error_code_in => SQLCODE, text_in => SQLERRM);
            RETURN NULL;
    END;

    FUNCTION get_flg_unknown
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_error      OUT t_error_out
    ) RETURN VARCHAR2 IS
        /******************************************************************************
           OBJECTIVO:   Retorna o ID_EPISODE se for do SONHO
           PARAMETROS:  ENTRADA: I_ID_EPISODE - Episódio        
                                 
                        SAIDA:   O_ERROR - erro 
          
          CRIAÇÃO: Teresa Coutinho 2007/07/13
          NOTAS:   
        *********************************************************************************/
        CURSOR c_flg_unknown IS
            SELECT flg_unknown
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
    
        l_flg_unknown epis_info.flg_unknown%TYPE;
    BEGIN
        g_error := 'OPEN C_EPIS_EXT_SYS';
        OPEN c_flg_unknown;
        FETCH c_flg_unknown
            INTO l_flg_unknown;
        CLOSE c_flg_unknown;
    
        RETURN l_flg_unknown;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_UBU',
                                              'GET_FLG_UNKNOWN',
                                              o_error);
            RETURN NULL;
    END;
    --
    /**********************************************************************************************
    * Cancelamento automatico via Job dos episodios orientados do centro de saude para o hospital que 
    * nunca foram admitidos no hospital
    *
    * @return                         N/A
    *                        
    * @author                         Odete Monteiro
    * @version                        1.0 
    * @since                          2007/09/11
    **********************************************************************************************/
    PROCEDURE cancel_epis_ubu IS
    
        l_prof       profissional;
        l_date_limit TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_epis_list table_number;
    
        l_rowids table_varchar;
    
        l_error t_error_out;
    
        l_aux VARCHAR2(4000) := '(';
    BEGIN
    
        l_date_limit := pk_date_utils.add_days_to_tstz(current_timestamp,
                                                       -to_number(pk_sysconfig.get_config('TIME_MAX_ADM_URG_UBU', l_prof)) / 24);
    
        l_prof := profissional(NULL, g_default_inst, g_software_ubu);
    
        SELECT e.id_episode
          BULK COLLECT
          INTO l_epis_list
          FROM episode ee, episode e
         WHERE e.id_prev_episode = ee.id_episode
           AND NOT EXISTS (SELECT 1
                  FROM transportation t
                 WHERE e.id_episode = t.id_episode)
           AND e.flg_status = g_epis_active
           AND ee.flg_status = g_epis_inactive
           AND ee.id_epis_type = g_epis_type_ubu
           AND e.id_epis_type = g_epis_type_urg
           AND pk_ubu.get_admin_discharge_ubu(e.id_prev_episode) < l_date_limit;
    
        FOR i IN 1 .. l_epis_list.count
        LOOP
            l_aux := l_aux || l_epis_list(i);
            IF i <> l_epis_list.count
            THEN
                l_aux := l_aux || ',';
            END IF;
        END LOOP;
    
        l_aux := l_aux || ')';
    
        IF l_epis_list.count > 0
        THEN
        
            ts_episode.upd(flg_status_in     => g_epis_cancel,
                           dt_cancel_tstz_in => g_sysdate_tstz,
                           where_in          => 'id_episode in ' || l_aux,
                           rows_out          => l_rowids);
        
            t_data_gov_mnt.process_update(i_lang       => 2,
                                          i_prof       => l_prof,
                                          i_table_name => 'EPISODE',
                                          i_rowids     => l_rowids,
                                          o_error      => l_error);
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_utils.undo_changes;
            NULL;
    END;
BEGIN
    NULL;
END pk_ubu;
/
