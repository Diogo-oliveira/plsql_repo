/*-- Last Change Revision: $Rev: 2027375 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:02 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_nch_pbl IS

    -- global variables definition
    g_sysdate_tstz  TIMESTAMP WITH TIME ZONE;
    g_error         VARCHAR2(2000);
    g_package_owner VARCHAR2(32) := '';
    g_package_name  VARCHAR2(32) := '';

    /********************************************************************************************
    * Returns the effective hours of care spent for an episode today
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_id_episode           Episode id
    *
    * @return                       number of minutes actually spent
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_effective_for_today
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN nch_effective.id_episode%TYPE
    ) RETURN NUMBER IS
        l_error     t_error_out;
        l_value_nch NUMBER := 0;
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        SELECT SUM(ne.value)
          INTO l_value_nch
          FROM nch_effective ne
         WHERE ne.id_episode = i_id_episode
           AND trunc(ne.dt_create) = trunc(g_sysdate_tstz);
    
        RETURN l_value_nch;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              'id_episode=' || i_id_episode,
                                              g_package_owner,
                                              g_package_name,
                                              'get_nch_effective_for_today',
                                              l_error);
            RETURN NULL;
    END get_nch_effective_for_today;

    /********************************************************************************************
    * Returns the average nch for a given context
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param o_average_nch          Average nch for a given context
    * @param o_days_average         Number of days used in calculating the average
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_average
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_context  IN VARCHAR2,
        o_average_nch  OUT NUMBER,
        o_days_average OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error        := 'get sysconfig NCH_DAYS_AVERAGE';
        o_days_average := pk_sysconfig.get_config('NCH_DAYS_AVERAGE', i_prof);
    
        g_error := 'average for  days=' || o_days_average;
        CASE i_flg_context
            WHEN g_flg_context_intervention THEN
                SELECT AVG(ne.value)
                  INTO o_average_nch
                  FROM nch_effective ne, nch_effective_intervention nei
                 WHERE ne.id_nch_effective = nei.id_nch_effective
                   AND ne.dt_create > g_sysdate_tstz - o_days_average;
            ELSE
                raise_application_error(-20001, 'Invalid flg_context ' || i_flg_context);
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_AVERAGE',
                                              o_error);
            RETURN FALSE;
    END get_nch_average;

    /********************************************************************************************
    * Returns the effective nch (in minutes) for a given context and institution
    * To be used in SQL
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    *
    * @return                       Effective nch in minutes
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_nch_effective
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        i_id_episode  IN nch_effective.id_episode%TYPE
    ) RETURN NUMBER IS
        l_error     t_error_out;
        l_nch_spent nch_effective.value%TYPE;
    BEGIN
        g_error := 'select nch_effective i_flg_context=' || i_flg_context || ', i_id_context=' || i_id_context;
    
        CASE i_flg_context
            WHEN g_flg_context_intervention THEN
                SELECT ne.value
                  INTO l_nch_spent
                  FROM nch_effective ne, nch_effective_intervention nei
                 WHERE ne.id_episode = i_id_episode
                   AND ne.id_nch_effective = nei.id_nch_effective
                   AND nei.id_incp_interv_plan = i_id_context;
            
            ELSE
                raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
        END CASE;
    
        RETURN l_nch_spent;
    EXCEPTION
        WHEN no_data_found THEN
            -- isn't really an error, it's possible to have episodes without nch
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_EFFECTIVE',
                                              l_error);
            RETURN NULL;
        
    END get_nch_effective;

    /********************************************************************************************
    * Returns the effective nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    * @param o_value                Effective nch in minutes
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_effective
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        i_id_episode  IN nch_effective.id_episode%TYPE,
        o_value       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'select nch_effective i_flg_context=' || i_flg_context || ', i_id_context=' || i_id_context;
    
        CASE i_flg_context
            WHEN g_flg_context_intervention THEN
                SELECT ne.value
                  INTO o_value
                  FROM nch_effective ne, nch_effective_intervention nei
                 WHERE ne.id_episode = i_id_episode
                   AND ne.id_nch_effective = nei.id_nch_effective
                   AND nei.id_incp_interv_plan = i_id_context;
            ELSE
                raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            -- isn't really an error, it's possible to have episodes without nch
            o_value := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_EFFECTIVE',
                                              o_error);
            RETURN FALSE;
    END get_nch_effective;

    /********************************************************************************************
    * Sets the effective nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this hours were spent
    * @param i_id_context           Context id
    * @param i_id_episode           Episode id
    * @param i_value                Effective nch in minutes
    * @param o_id_nch_effective     ID of inserted row
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION set_nch_effective
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_context      IN VARCHAR2,
        i_id_context       IN NUMBER,
        i_id_episode       IN nch_effective.id_episode%TYPE,
        i_value            IN NUMBER,
        o_id_nch_effective OUT nch_effective.id_nch_effective%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        -- Only register when is not null because is the same as the entry not existing
        IF i_value IS NOT NULL
        THEN
        
            g_error := 'seq_nch_effective.NEXTVAL';
            SELECT seq_nch_effective.nextval
              INTO o_id_nch_effective
              FROM dual;
        
            g_error := 'insert into nch_effective';
            CASE i_flg_context
                WHEN g_flg_context_intervention THEN
                    INSERT INTO nch_effective
                        (id_nch_effective, id_episode, VALUE, dt_create, id_create_prof)
                    VALUES
                        (o_id_nch_effective, i_id_episode, i_value, g_sysdate_tstz, i_prof.id);
                    INSERT INTO nch_effective_intervention
                        (id_nch_effective, id_incp_interv_plan)
                    VALUES
                        (o_id_nch_effective, i_id_context);
                ELSE
                    raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
            END CASE;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NCH_EFFECTIVE',
                                              o_error);
            RETURN FALSE;
    END set_nch_effective;

    /********************************************************************************************
    * Returns the estimated nch (in minutes) for a given context and institution
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_flg_context          In what kind of context this estimate is
    * @param i_id_context           Context id
    * @param o_value                Estimated nch in minutes
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_nch_estimated
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_flg_context IN VARCHAR2,
        i_id_context  IN NUMBER,
        o_value       OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        CASE i_flg_context
            WHEN g_flg_context_intervention THEN
                SELECT VALUE
                  INTO o_value
                  FROM (SELECT nei.value, nei.id_institution
                          FROM nch_estimated_inst nei, nch_estimated_inst_interv neii
                         WHERE nei.id_institution IN (0, i_prof.institution)
                           AND nei.id_nch_estimated_inst = neii.id_nch_estimated_inst
                           AND neii.id_composition =
                               (SELECT id_composition
                                  FROM icnp_epis_intervention iei
                                 WHERE iei.id_icnp_epis_interv = i_id_context)
                         ORDER BY nei.id_institution DESC)
                 WHERE rownum = 1;
            
            ELSE
                raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_value := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_ESTIMATED',
                                              o_error);
            RETURN FALSE;
    END get_nch_estimated;

    /********************************************************************************************
    * Sets the estimated nch (in minutes) for a given context and institution
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional
    * @param i_flg_context           In what kind of context this will be used
    * @param i_id_context            Context id
    * @param i_value                 Estimated nch in minutes
    * @param o_id_nch_estimated_inst ID of inserted row
    * @param o_error                 Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       Eduardo Reis 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION set_nch_estimated
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_flg_context           IN VARCHAR2,
        i_id_context            IN NUMBER,
        i_value                 IN NUMBER,
        o_id_nch_estimated_inst OUT nch_estimated_inst.id_nch_estimated_inst%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'seq_nch_estimated_inst.NEXTVAL';
        SELECT seq_nch_estimated_inst.nextval
          INTO o_id_nch_estimated_inst
          FROM dual;
    
        g_error := 'insert into nch_estimated_inst';
        CASE i_flg_context
            WHEN g_flg_context_intervention THEN
                INSERT INTO nch_estimated_inst
                    (id_nch_estimated_inst, id_institution, VALUE, dt_create, id_create_prof)
                VALUES
                    (o_id_nch_estimated_inst, i_prof.institution, i_value, g_sysdate_tstz, i_prof.id);
            
                INSERT INTO nch_estimated_inst_interv
                    (id_nch_estimated_inst, id_composition)
                VALUES
                    (o_id_nch_estimated_inst, i_id_context);
            ELSE
                raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            dbms_output.put_line(SQLCODE || SQLERRM);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_NCH_ESTIMATED',
                                              o_error);
            RETURN FALSE;
    END set_nch_estimated;

    /********************************************************************************************
    * Returns information of the NCH of an episode to be displayed in the viewer. 
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_id_epis              Episode id
    * @param o_data                 Cursor containing the data to be returned to the UX.        
    * @param o_error                Error message
    *
    * @return                       True or false, according to if the execution completes successfully or not.
    *
    * @author                       RicardoNunoAlmeida 
    * @since                        2010/03/18
    ********************************************************************************************/
    FUNCTION get_epis_nch_viewer
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_epis  IN episode.id_episode%TYPE,
        o_data  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_nch_effective NUMBER;
        l_nch_estimated NUMBER;
        l_nch_avg       NUMBER;
        l_nch_avg_days  NUMBER;
    BEGIN
        g_error         := 'GET THE EFFECTIVE NCH';
        l_nch_effective := nvl(pk_nch_pbl.get_nch_effective_for_today(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_episode => i_epis),
                               0);
    
        g_error         := 'GET THE ESTIMATED NCH';
        l_nch_estimated := pk_nch_pbl.get_nch_total(i_lang => i_lang,
                                                    i_prof => i_prof,
                                                    i_epis => i_epis,
                                                    i_date => current_timestamp);
    
        g_error := 'GET THE AVERAGE NCH';
        IF NOT pk_nch_pbl.get_epis_nch_avg(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_epis         => i_epis,
                                           i_flg_context  => NULL,
                                           o_average_nch  => l_nch_avg,
                                           o_days_average => l_nch_avg_days,
                                           o_error        => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'OPEN CURSOR';
        OPEN o_data FOR
            SELECT get_format_nch_info(i_lang, l_nch_effective) nch_effective,
                   get_format_nch_info(i_lang, l_nch_estimated) nch_estimated,
                   get_format_nch_info(i_lang, l_nch_avg) nch_avg,
                   l_nch_avg_days avg_days
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_NCH_VIEWER',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_data);
            RETURN FALSE;
    END get_epis_nch_viewer;

    /********************************************************************************************
    * Returns a formated string with nch information for the provided episode
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_epis                 ID episode
    * @param o_nch                  Formated message containing NCH info.
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       RicardoNunoAlmeida
    * @version                      2.6.0.1
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_epis_nch_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_sys_shortcut IN sys_shortcut.id_sys_shortcut%TYPE,
        o_nch          OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nch_effective nch_effective.value%TYPE;
        l_nch_prev      nch_effective.value%TYPE;
        l_nch           VARCHAR2(200 CHAR);
    BEGIN
    
        g_error         := 'GET VALUES';
        l_nch_effective := get_nch_effective_for_today(i_lang, i_prof, i_epis);
        l_nch_prev      := get_nch_total(i_lang, i_prof, i_epis, current_timestamp);
    
        g_error := 'GET DATA TO BE RETURNED';
        l_nch   := get_format_nch_info(i_lang, l_nch_effective) || ' / ' || CASE nvl(l_nch_prev, -1)
                       WHEN -1 THEN
                        g_undefined_nch
                       ELSE
                        get_format_nch_info(i_lang, l_nch_prev)
                   END;
    
        g_error := 'GET DATA TO BE RETURNED';
        SELECT pk_utils.get_status_string_immediate(i_lang,
                                                    i_prof,
                                                    pk_alert_constant.g_display_type_text,
                                                    NULL,
                                                    l_nch,
                                                    NULL,
                                                    NULL,
                                                    i_sys_shortcut,
                                                    NULL,
                                                    NULL,
                                                    'BIGTEXT',
                                                    NULL,                                                    
                                                    NULL,
                                                    l_nch,
                                                    NULL
                                                    /* st.dt_server*/)
          INTO o_nch
          FROM dual;
        /* o_nch   := i_sys_shortcut || '|xxxxxxxxxxxxxx|T|X|' || get_format_nch_info(i_lang, l_nch_effective) || ' / ' ||
        CASE nvl(l_nch_prev, -1)
            WHEN -1 THEN
             g_undefined_nch
            ELSE
             get_format_nch_info(i_lang, l_nch_prev)
        END;*/
        RETURN TRUE;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_NCH_INFO',
                                              o_error);
            RETURN FALSE;
    END get_epis_nch_info;

    FUNCTION get_epis_nch_info
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_sys_shortcut IN sys_shortcut.id_sys_shortcut%TYPE
    ) RETURN VARCHAR2 IS
        l_err t_error_out;
        l_str VARCHAR2(200 CHAR);
    
    BEGIN
        g_error := 'CALL TO MAIN FUNCTION';
        IF NOT get_epis_nch_info(i_lang         => i_lang,
                                 i_prof         => i_prof,
                                 i_epis         => i_epis,
                                 i_sys_shortcut => i_sys_shortcut,
                                 o_nch          => l_str,
                                 o_error        => l_err)
        THEN
            RETURN NULL;
        END IF;
    
        RETURN l_str;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_NCH_INFO',
                                              l_err);
            RETURN NULL;
    END get_epis_nch_info;

    /**********************************************************************************************
    * Returns the total nch value estimated to a patient, at a given date.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_nch_total
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_epis IN episode.id_episode%TYPE,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_ret PLS_INTEGER;
        l_err t_error_out;
    BEGIN
    
        g_error := 'GET ESTIMATED PATIENT NCH WITH i_epis=' || i_epis;
        pk_alertlog.log_debug(g_error);
        SELECT SUM(nch)
          INTO l_ret
          FROM (SELECT en.nch_value nch
                  FROM epis_nch en
                 WHERE en.id_episode = i_epis
                   AND en.flg_status = pk_alert_constant.g_active
                UNION
                SELECT decode(nvl(bbe.flg_allocation_nch, pk_bmng_constant.g_bmng_allocat_flg_nch_d),
                              pk_bmng_constant.g_bmng_allocat_flg_nch_d,
                              nl.value,
                              pk_nch_pbl.get_nch_level(i_lang, i_prof, nl.id_nch_level, e.dt_begin_tstz, i_date)) nch
                  FROM bmng_bed_ea bbe
                 INNER JOIN nch_level nl
                    ON nl.id_nch_level = bbe.id_nch_level
                 INNER JOIN episode e
                    ON e.id_episode = bbe.id_episode
                  LEFT JOIN epis_nch en
                    ON en.id_episode = bbe.id_episode
                   AND en.flg_status = pk_alert_constant.g_active
                 WHERE bbe.id_episode = i_epis
                   AND en.id_epis_nch IS NULL) data;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_LEVELS',
                                              l_err);
            RETURN NULL;
    END get_nch_total;

    /********************************************************************************************
    * Returns the average effective nch spent on a given episode
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional
    * @param i_epis                 ID episode
    * @param i_flg_context          In what kind of context this hours were spent
    * @param o_average_nch          Average nch for a given context
    * @param o_days_average         Number of days used in calculating the average
    * @param o_error                Error message
    *
    * @return                       True if success, false otherwise
    *
    * @author                       RicardoNunoAlmeida 
    * @since                        2010/03/19
    ********************************************************************************************/
    FUNCTION get_epis_nch_avg
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis         IN episode.id_episode%TYPE,
        i_flg_context  IN VARCHAR2,
        o_average_nch  OUT NUMBER,
        o_days_average OUT NUMBER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        g_error        := 'get sysconfig NCH_DAYS_AVERAGE';
        o_days_average := pk_sysconfig.get_config('NCH_DAYS_AVERAGE', i_prof);
    
        g_error := 'average for days=' || o_days_average;
    
        CASE nvl(i_flg_context, -1)
            WHEN -1 THEN
                SELECT SUM(ne.value) / o_days_average
                  INTO o_average_nch
                  FROM nch_effective ne
                 WHERE ne.id_episode = i_epis
                   AND ne.dt_create > g_sysdate_tstz - o_days_average;
            
            WHEN g_flg_context_intervention THEN
                SELECT SUM(ne.value) / o_days_average
                  INTO o_average_nch
                  FROM nch_effective ne, nch_effective_intervention nei
                 WHERE ne.id_nch_effective = nei.id_nch_effective
                   AND ne.id_episode = i_epis
                   AND ne.dt_create > g_sysdate_tstz - o_days_average;
            ELSE
                raise_application_error(-20001, 'Context not implemented ' || i_flg_context);
        END CASE;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_EPIS_AVG',
                                              o_error);
            RETURN FALSE;
    END get_epis_nch_avg;

    /********************************************************************************************
    * Returns a formated string with nch information for the provided episode
    *
    * @param i_lang                 Language ID
    * @param i_val                  Value the NCH (in minutes) to be formatted.
    *
    * @return                       True if success, false otherwise
    *
    * @author                       RicardoNunoAlmeida 
    * @version                      2.6.0.1 
    * @since                        2010/03/23
    ********************************************************************************************/
    FUNCTION get_format_nch_info
    (
        i_lang language.id_language%TYPE,
        i_val  nch_effective.value%TYPE
    ) RETURN VARCHAR2 IS
        l_round   nch_effective.value%TYPE;
        l_mod     nch_effective.value%TYPE;
        l_c_round VARCHAR2(20 CHAR);
        l_c_mod   VARCHAR2(20 CHAR);
        l_err     t_error_out;
    BEGIN
        g_error := 'GET VALUES';
        IF i_val IS NULL
           OR i_val = 0
        THEN
            l_round := 0;
            l_mod   := 0;
        ELSE
            l_round := floor(i_val / g_hour);
            l_mod   := MOD(i_val, g_hour);
        END IF;
    
        g_error := 'SEASON VALUES';
        IF l_round < 10
        THEN
            l_c_round := '0' || l_round;
        ELSE
            l_c_round := l_round;
        END IF;
    
        IF l_mod < 10
        THEN
            l_c_mod := '0' || l_mod;
        ELSE
            l_c_mod := l_mod;
        END IF;
    
        g_error := 'RETURN FORMATTED STRING';
        RETURN l_c_round || ':' || l_c_mod || pk_message.get_message(i_lang, 'HOURS_SIGN');
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_FORMAT_NCH_INFO',
                                              l_err);
            RETURN NULL;
    END get_format_nch_info;

    /********************************************************************************************************************************************
    * SET_EPIS_NCH             Function that update an EPISODE NCH information if that exists, otherwise create one new registry
    *
    * @param  I_LANG                      Language associated to the professional executing the request
    * @param  I_PROF                      Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPIS_NCH               EPIS NCH identifier that should be updated or created in this function
    * @param  I_ID_EPISODE                Episode identifier
    * @param  I_ID_PATIENT                Patient identifier
    * @param  I_NCH_VALUE                 Number of NCH associated with current episode
    * @param  I_DT_BEGIN                  Date in which current NCH information starts taking efect
    * @param  I_DT_END                    Date in which current NCH information ends it's validation (if I_FLG_ALLOCATION_NCH = 'U')
    * @param  I_FLG_STATUS                FLG_STATUS for this registry
    * @param  I_FLG_TYPE                  FLG_TYPE for this registry
    * @param  I_DT_CREATION               Date in which current registry was created
    * @param  I_NCH_LEVEL                 NCH_LEVEL associated with current registry, if aplicable
    * @param  O_ID_EPIS_NCH               EPIS_NCH identifier witch was updated or created after execute this function
    * @param  O_ERROR                     If an error accurs, this parameter will have information about the error
    *
    * @value  I_FLG_STATUS                {*} 'A'- Active {*} 'O'- Outdated
    * @value  I_FLG_TYPE                  {*} 'T'- Temporary nch value {*} 'D'- Definitive nch value
    * 
    * @return                             Returns TRUE if success, otherwise returns FALSE
    * @raises                             PL/SQL generic erro "OTHERS"
    *
    * @author                             Luís Maia
    * @version                            2.5.0.5
    * @since                              26-Ago-2009
    *
    *******************************************************************************************************************************************/
    FUNCTION set_epis_nch
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_nch  IN epis_nch.id_epis_nch%TYPE,
        i_id_episode   IN epis_nch.id_episode%TYPE,
        i_id_patient   IN epis_nch.id_patient%TYPE,
        i_nch_value    IN epis_nch.nch_value%TYPE,
        i_dt_begin     IN epis_nch.dt_begin%TYPE,
        i_dt_end       IN epis_nch.dt_end%TYPE,
        i_flg_status   IN epis_nch.flg_status%TYPE,
        i_flg_type     IN epis_nch.flg_type%TYPE,
        i_dt_creation  IN epis_nch.dt_creation%TYPE,
        i_id_nch_level IN epis_nch.id_nch_level%TYPE,
        i_reason_notes IN epis_nch.reason_notes%TYPE,
        o_id_epis_nch  OUT epis_nch.id_epis_nch%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        --
        l_epis_nch    epis_nch%ROWTYPE;
        l_id_epis_nch epis_nch.id_epis_nch%TYPE;
        l_rows        table_varchar := table_varchar();
    BEGIN
        --
        IF i_id_epis_nch IS NULL
        THEN
            -- CREATE NEW EPIS_NCH
            g_error := 'CALL TS_EPIS_NCH.NEXT_KEY';
            pk_alertlog.log_debug(g_error);
            l_id_epis_nch := ts_epis_nch.next_key;
            --
            g_error := 'CALL TS_EPIS_NCH.INS WITH ID_EPIS_NCH XX ' || l_id_epis_nch || ' AND NCH_VALUE ' || i_nch_value;
            pk_alertlog.log_debug(g_error);
            ts_epis_nch.ins(id_epis_nch_in      => l_id_epis_nch,
                            id_episode_in       => i_id_episode,
                            id_patient_in       => i_id_patient,
                            nch_value_in        => i_nch_value,
                            dt_begin_in         => i_dt_begin,
                            dt_end_in           => i_dt_end,
                            flg_status_in       => i_flg_status,
                            flg_type_in         => i_flg_type,
                            dt_creation_in      => i_dt_creation,
                            id_prof_creation_in => i_prof.id,
                            id_nch_level_in     => i_id_nch_level,
                            reason_notes_in     => i_reason_notes,
                            rows_out            => l_rows);
        
            g_error := 'PROCESS INSERT WITH ID_EPIS_NCH ' || l_id_epis_nch;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_NCH', l_rows, o_error);
        
        ELSE
            -- Get current bed information
            g_error := 'GET EPIS_NCH RECORD INFORMATION FOR ID_EPIS_NCH ' || i_id_epis_nch;
            pk_alertlog.log_debug(g_error);
            SELECT eh.*
              INTO l_epis_nch
              FROM epis_nch eh
             WHERE eh.id_epis_nch = i_id_epis_nch;
        
            -- Update EPIS_NCH.ROWTYPE with new values
            l_epis_nch.id_episode       := nvl(i_id_episode, l_epis_nch.id_episode);
            l_epis_nch.id_patient       := nvl(i_id_patient, l_epis_nch.id_patient);
            l_epis_nch.nch_value        := nvl(i_nch_value, l_epis_nch.nch_value);
            l_epis_nch.dt_begin         := nvl(i_dt_begin, l_epis_nch.dt_begin);
            l_epis_nch.dt_end           := nvl(i_dt_end, l_epis_nch.dt_end);
            l_epis_nch.flg_status       := nvl(i_flg_status, l_epis_nch.flg_status);
            l_epis_nch.flg_type         := nvl(i_flg_type, l_epis_nch.flg_type);
            l_epis_nch.dt_creation      := nvl(i_dt_creation, current_timestamp);
            l_epis_nch.id_prof_creation := i_prof.id;
            l_epis_nch.id_nch_level     := nvl(i_id_nch_level, l_epis_nch.id_nch_level);
            l_epis_nch.reason_notes     := nvl(i_reason_notes, l_epis_nch.reason_notes);
        
            -- Update old registry to OUTDATED
            g_error := 'OUTDATE REGISTRY: CALL TS_EPIS_NCH.UPD WITH EPIS_NCH ' || i_id_epis_nch;
            pk_alertlog.log_debug(g_error);
            ts_epis_nch.upd(id_epis_nch_in => i_id_epis_nch,
                            flg_status_in  => pk_alert_constant.g_outdated,
                            rows_out       => l_rows);
        
            g_error := 'PROCESS UPDATE FOR ID_EPIS_NCH ' || i_id_epis_nch;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang, i_prof, 'EPIS_NCH', l_rows, o_error);
            l_rows := table_varchar();
        
            -- Insert EPIS_NCH registry
            g_error := 'CALL TS_EPIS_NCH.NEXT_KEY';
            pk_alertlog.log_debug(g_error);
            l_id_epis_nch := ts_epis_nch.next_key;
        
            g_error := 'CALL TS_EPIS_NCH.INS WITH ID_EPIS_NCH X ' || l_id_epis_nch || ' AND NCH_VALUE ' ||
                       l_epis_nch.nch_value;
            pk_alertlog.log_debug(g_error);
            ts_epis_nch.ins(id_epis_nch_in      => l_id_epis_nch,
                            id_episode_in       => l_epis_nch.id_episode,
                            id_patient_in       => l_epis_nch.id_patient,
                            nch_value_in        => l_epis_nch.nch_value,
                            dt_begin_in         => l_epis_nch.dt_begin,
                            dt_end_in           => l_epis_nch.dt_end,
                            flg_status_in       => l_epis_nch.flg_status,
                            flg_type_in         => l_epis_nch.flg_type,
                            dt_creation_in      => l_epis_nch.dt_creation,
                            id_prof_creation_in => l_epis_nch.id_prof_creation,
                            id_nch_level_in     => l_epis_nch.id_nch_level,
                            reason_notes_in     => l_epis_nch.reason_notes,
                            rows_out            => l_rows);
        
            g_error := 'PROCESS INSERT FOR ID_EPIS_NCH ' || l_id_epis_nch;
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_insert(i_lang, i_prof, 'EPIS_NCH', l_rows, o_error);
        END IF;
    
        -- SUCCESS
        o_id_epis_nch := nvl(l_id_epis_nch, i_id_epis_nch);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_EPIS_NCH',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_epis_nch;

    /** 
    * Returns the nch value to the day indicated
    *
    * @param i_lang                     Language ID
    * @param i_prof                     Professional's details
    * @param i_id_adm_indication        Admission indication identifier
    * @param i_nr_day                   Nr of the day in the 
    * @param o_nch_value                NCH value   
    * @param o_id_nch_level             NCH identifier   
    * @param o_error                    Error message
    *
    * @return                           TRUE if success, FALSE otherwise         
    * @author     Sofia Mendes
    * @version    2.5.0.5
    * @since      2009/07/30
    */
    FUNCTION get_nch_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        i_nr_day            IN NUMBER,
        o_nch_value         OUT nch_level.value%TYPE,
        o_id_nch_level      OUT nch_level.id_nch_level%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_previous          NUMBER;
        l_duration          NUMBER;
        l_value             nch_level.value%TYPE;
        l_found             BOOLEAN := FALSE;
        l_cumulated_nr_days NUMBER;
    BEGIN
        g_error := 'SELECT first id_nch_level';
        SELECT nl.id_nch_level, nl.duration, nl.value
          INTO l_previous, l_duration, l_value
          FROM adm_indication admi
          JOIN nch_level nl
            ON admi.id_nch_level = nl.id_nch_level
         WHERE admi.id_adm_indication = i_id_adm_indication;
    
        IF (l_duration IS NULL)
        THEN
            o_nch_value    := l_value;
            o_id_nch_level := l_previous;
            l_found        := TRUE;
        ELSE
            IF (l_duration >= i_nr_day)
            THEN
                o_nch_value    := l_value;
                o_id_nch_level := l_previous;
                l_found        := TRUE;
            END IF;
        END IF;
    
        l_cumulated_nr_days := l_duration;
    
        WHILE (l_found = FALSE AND l_previous IS NOT NULL)
        LOOP
            g_error := 'LOOP THROUGH NCH_LEVEL: l_previous = ' || l_previous;
            BEGIN
                SELECT nl.id_nch_level, nl.duration, nl.value
                  INTO l_previous, l_duration, l_value
                  FROM nch_level nl
                 WHERE nl.id_previous = l_previous;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_previous := NULL;
            END;
        
            IF (l_previous IS NOT NULL)
            THEN
                IF (l_duration IS NULL)
                THEN
                    o_nch_value    := l_value;
                    o_id_nch_level := l_previous;
                    l_found        := TRUE;
                ELSE
                    l_cumulated_nr_days := l_cumulated_nr_days + l_duration;
                    IF (l_cumulated_nr_days >= i_nr_day)
                    THEN
                        o_nch_value    := l_value;
                        o_id_nch_level := l_previous;
                        l_found        := TRUE;
                    END IF;
                END IF;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_VALUE',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nch_value;

    /********************************************************************************************************************************************
    * GET_EPIS_NCH_LEVEL       For current episode and current moment, returns NCH_LEVEL identifier.
    *
    * @param  I_LANG           Language associated to the professional executing the request
    * @param  I_PROF           Professional identification (ID, INSTITUTION, SOFTWARE)
    * @param  I_ID_EPISODE     Episode identifier for getting NCH_LEVEL identifier
    * @param  O_NCH_VALUE      NCH value correspondent to current episode in current moment
    * @param  O_ID_NCH_LEVEL   NCH_LEVEL identifier correspondent to current episode in current moment
    * @param  O_ID_EPIS_NCH    EPIS_NCH identifier
    * @param  O_ERROR          If an error accurs, this parameter will have information about the error
    *
    * @return                  Returns TRUE if success, otherwise returns FALSE
    * @raises                  PL/SQL generic erro "OTHERS"
    *
    * @author                  Luís Maia
    * @version                 2.5.0.6
    * @since                   2009/09/11
    *
    *******************************************************************************************************************************************/
    FUNCTION get_epis_nch_level
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        o_nch_value    OUT nch_level.value%TYPE,
        o_id_nch_level OUT nch_level.id_nch_level%TYPE,
        o_id_epis_nch  OUT epis_nch.id_epis_nch%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_adm_indication      adm_indication.id_adm_indication%TYPE;
        l_inpatient_day          PLS_INTEGER;
        l_dt_begin_sched_episode TIMESTAMP WITH LOCAL TIME ZONE;
        l_epis_nch               epis_nch%ROWTYPE;
        l_id_patient             patient.id_patient%TYPE;
    BEGIN
    
        g_error := 'GET ID_PATIENT FOR ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT epi.id_patient
          INTO l_id_patient
          FROM episode epi
         WHERE epi.id_episode = i_id_episode;
    
        g_error := 'GET EPIS_NCH INFORMATION FOR ID_EPISODE ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT t.*
              INTO l_epis_nch
              FROM (SELECT en.*
                      FROM epis_nch en
                     WHERE en.id_episode = i_id_episode
                       AND en.id_patient = l_id_patient
                       AND en.flg_status = pk_alert_constant.g_active
                     ORDER BY en.id_epis_nch) t
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_nch := NULL;
        END;
        o_id_epis_nch := l_epis_nch.id_epis_nch;
    
        IF l_epis_nch.id_epis_nch IS NOT NULL
        THEN
            g_error := 'GET EPIS_NCH INFORMATION FOR ID_EPISODE ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT ai.id_adm_indication,
                       nvl(ar.dt_admission, pk_schedule_inp.get_sch_dt_begin(i_lang, i_prof, we.id_episode))
                  INTO l_id_adm_indication, l_dt_begin_sched_episode
                  FROM wtl_epis we
                 INNER JOIN adm_request ar
                    ON (ar.id_dest_episode = we.id_episode)
                 INNER JOIN adm_indication ai
                    ON (ai.id_adm_indication = ar.id_adm_indication)
                 WHERE we.id_episode = i_id_episode
                   AND we.id_epis_type = pk_alert_constant.g_epis_type_inpatient;
            
                IF NOT pk_date_utils.get_timestamp_diff(i_lang        => i_lang,
                                                        i_timestamp_1 => current_timestamp,
                                                        i_timestamp_2 => l_dt_begin_sched_episode,
                                                        o_days_diff   => l_inpatient_day,
                                                        o_error       => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    l_id_adm_indication := NULL;
                    l_inpatient_day     := NULL;
            END;
        
            -- DEFINE l_id_nch_level variable
            IF l_id_adm_indication IS NOT NULL
               AND l_inpatient_day IS NOT NULL
            THEN
                g_error := 'CALL GET_NCH_VALUE WITH ID_ADM_INDICATION ' || l_id_adm_indication || ' AND INPATIENT DAY ' ||
                           l_inpatient_day;
                pk_alertlog.log_debug(g_error);
                IF NOT get_nch_value(i_lang              => i_lang,
                                     i_prof              => i_prof,
                                     i_id_adm_indication => l_id_adm_indication,
                                     i_nr_day            => l_inpatient_day,
                                     o_nch_value         => o_nch_value,
                                     o_id_nch_level      => o_id_nch_level,
                                     o_error             => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        END IF;
    
        -- SUCCESS
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_NCH_LEVEL',
                                              o_error);
            RETURN FALSE;
    END get_epis_nch_level;

    /** 
    * Returns the nch first and second value as well as the nch change.
    *
     * @param i_lang                     Language ID
    * @param i_prof                     Professional's details   
    * @param o_error                    Error message
    * @param o_nch_levels               Output cursor
    * @return                           TRUE if success, FALSE otherwise         
    * @author     Sofia Mendes
    * @version    2.5.0.5
    * @since      2009/07/30
    */
    FUNCTION get_nch_levels
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_adm_indication IN adm_indication.id_adm_indication%TYPE,
        o_nch_levels        OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_previous      NUMBER;
        l_count         NUMBER := 1;
        l_id_nch_levels table_number := table_number();
    BEGIN
        g_error := 'SELECT first id_nch_level';
        SELECT nl.id_nch_level
          INTO l_previous
          FROM adm_indication admi
          JOIN nch_level nl
            ON admi.id_nch_level = nl.id_nch_level
         WHERE admi.id_adm_indication = i_id_adm_indication;
    
        l_id_nch_levels.extend(1);
        l_id_nch_levels(l_count) := l_previous;
    
        WHILE (l_previous IS NOT NULL)
        LOOP
            g_error := 'LOOP THROUGH NCH_LEVEL: l_previous = ' || l_previous;
            l_count := l_count + 1;
        
            BEGIN
                SELECT nl.id_nch_level
                  INTO l_previous
                  FROM nch_level nl
                 WHERE nl.id_previous = l_previous;
            EXCEPTION
                WHEN no_data_found THEN
                    l_previous := NULL;
            END;
        
            IF (l_previous IS NOT NULL)
            THEN
                l_id_nch_levels.extend(1);
                l_id_nch_levels(l_count) := l_previous;
            END IF;
        END LOOP;
    
        g_error := 'OPEN o_nch_levels CURSOR';
        OPEN o_nch_levels FOR
            SELECT nl.id_nch_level, nl.value, nl.duration, nl.id_previous
              FROM nch_level nl
             WHERE nl.id_nch_level IN (SELECT column_value
                                         FROM TABLE(l_id_nch_levels));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_LEVELS',
                                              o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_nch_levels;

    /**********************************************************************************************
    * Returns the nch value for the current nch level of an episode.
    *
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_bmng_allocation_bed           ID of the episode's bed allocation.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                RicardoNunoAlmeida
    * @version                               2.5.0.7.5
    * @since                                 2009/07/30
    **********************************************************************************************/
    FUNCTION get_nch_level
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_nch_lvl IN nch_level.id_nch_level%TYPE,
        i_dt_ini  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_ref  IN TIMESTAMP WITH LOCAL TIME ZONE
        
    ) RETURN nch_level.id_nch_level%TYPE IS
    
        l_dt_prov   TIMESTAMP WITH LOCAL TIME ZONE;
        l_nch_lvl   nch_level.id_nch_level%TYPE;
        l_val       nch_level.value%TYPE;
        l_time_unit VARCHAR2(20) := 'HOUR';
        l_err       t_error_out;
    BEGIN
    
        g_error := 'GET NCH';
        SELECT pk_date_utils.add_to_ltstz(i_dt_ini, nl.duration, l_time_unit), nln.id_nch_level, nl.value
          INTO l_dt_prov, l_nch_lvl, l_val
          FROM nch_level nl
          LEFT JOIN nch_level nln
            ON nln.id_previous = nl.id_nch_level
         WHERE nl.id_nch_level = i_nch_lvl;
    
        IF l_dt_prov > i_dt_ref
           OR l_nch_lvl IS NULL
        THEN
            RETURN l_val;
        ELSE
            RETURN pk_nch_pbl.get_nch_level(i_lang, i_prof, l_nch_lvl, l_dt_prov, i_dt_ref);
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_LEVEL',
                                              l_err);
            RETURN NULL;
    END get_nch_level;

    /**********************************************************************************************
    * Returns the total nch value allocated to a patient, at a given date.
    *
    * Note:  currently the function only calculates the NCH for the current time.  The two final arguments are thus useless.
    *        The function is predicted to be complete in version 2.5.0.7.
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_epis                          ID of the episode to check the NCH.
    * @param i_bmng_allocation_bed           ID of the episode's bed allocation.
    * @param i_date                          Reference date to check the episode's NCH value
    *
    * @return                                Number of NCH hours the episode is allocating, or NULL for error.
    *
    * @author                                Sofia 
    * @version                               2.5.0.7
    * @since                                 2009/11/05
    **********************************************************************************************/
    FUNCTION get_nch_total_past
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_epis                IN episode.id_episode%TYPE,
        i_bmng_allocation_bed IN bmng_allocation_bed.id_bmng_allocation_bed%TYPE,
        i_date                IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_ret PLS_INTEGER;
        l_err t_error_out;
    BEGIN
    
        g_error := 'GET ACTUAL PATIENT NCH WITH i_epis=' || i_epis;
        pk_alertlog.log_debug(g_error);
        SELECT nvl(SUM(nch), pk_sysconfig.get_config(pk_bmng_constant.g_bmng_conf_def_nch_pat, i_prof))
          INTO l_ret
          FROM (SELECT en.nch_value nch
                  FROM epis_nch en
                 WHERE en.id_episode = i_epis
                   AND en.flg_status = pk_alert_constant.g_active
                UNION
                SELECT nl.value nch
                  FROM bmng_allocation_bed bab
                --join bmng_action ba on bab.id_bmng_allocation_bed = ba.id_bmng_allocation_bed               
                  LEFT JOIN epis_nch en
                    ON en.id_episode = bab.id_episode
                 INNER JOIN nch_level nl
                    ON nl.id_nch_level = en.id_nch_level
                 WHERE bab.id_episode = i_epis
                   AND en.id_epis_nch IS NULL) data; --TODO: check this last condition
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NCH_LEVELS',
                                              l_err);
            RETURN NULL;
    END get_nch_total_past;

    /**********************************************************************************************
    * Returns the Nursing Care Hours reason notes
    *
    * @param i_lang                          Language ID
    * @param i_prof                          ALERT Professional
    * @param i_episode                       ID of the episode to check the NCH.
    * @param o_error                         Error message
    *
    * @return                                Reason notes
    *
    * @author                                Vanessa Barsottelli 
    * @version                               2.6.4.3
    * @since                                 30/05/2014
    **********************************************************************************************/
    FUNCTION get_nch_reason_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_reason_notes OUT epis_nch.reason_notes%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_NCH_REASON_NOTES';
    BEGIN
    
        g_error := 'GET NCH reason notes for i_episode = ' || i_episode;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        BEGIN
            SELECT en.reason_notes
              INTO o_reason_notes
              FROM epis_nch en
             WHERE en.id_episode = i_episode
               AND en.flg_status = pk_alert_constant.g_active;
        EXCEPTION
            WHEN no_data_found THEN
                o_reason_notes := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_nch_reason_notes;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_nch_pbl;
/
