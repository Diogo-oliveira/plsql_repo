/*-- Last Change Revision: $Rev: 2001943 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2021-11-24 16:20:34 +0000 (qua, 24 nov 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_guidelines IS

    /*******************************************************************************************************************************************
    * Get get_guidprot_progress_notes
    *                                                                                                                                         
    * @param LANG                     Id language                                                                                             
    * @param I_PROF                   Profissional, institution and software identifiers                                                      
    * @param i_patient                Id Patient    
    * @param I_EPISODE                Episode identifier                                                                                      
    * @param o_guidprot               Returns array with info of Guidelines and Protocols                                                     
    *                                                                                                                                         
    * @return                         Return false if any error ocurred and return true otherwise                                             
    *                                                                                                                                         
    * @raises                                                                                                                                 
    *                                                                                                                                         
    * @author                         Teresa Coutinho                                                                                         
    * @version                         1.0                                                                                                    
    * @since                          2009/03/27                                                                                              
    *******************************************************************************************************************************************/
    FUNCTION get_guidprot_progress_notes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_guidprot OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        function_error EXCEPTION;
    
        l_func_name VARCHAR2(64) := 'get_guidprot_progress_notes';
        l_msg_guid  sys_message.desc_message%TYPE;
        l_msg_prot  sys_message.desc_message%TYPE;
    
    BEGIN
        l_msg_guid := pk_message.get_message(i_lang, 'PROGRESS_NOTES_T053') || ' ';
        l_msg_prot := pk_message.get_message(i_lang, 'PROGRESS_NOTES_T054') || ' ';
    
        g_error := 'OPEN CURSOR o_guidprot';
        OPEN o_guidprot FOR
            SELECT l_msg_prot || p.protocol_desc || ' (' ||
                   pk_protocol.get_link_id_str(i_lang,
                                               i_prof,
                                               p.id_protocol,
                                               pk_protocol.g_protocol_link_type,
                                               g_separator_link_str) || ')' descr
              FROM protocol p, protocol_process pp
             WHERE p.id_protocol = pp.id_protocol
               AND (pp.id_episode = i_episode OR
                   (pp.id_patient = i_patient AND nvl(pp.id_episode, -1) = -1 AND pp.flg_status != g_recommended_flag))
               AND p.flg_status != g_cancelled_flag
               AND pp.flg_status != g_cancelled_flag
            UNION ALL
            SELECT l_msg_guid || g.guideline_desc || ' (' ||
                   pk_guidelines.get_link_id_str(i_lang,
                                                 i_prof,
                                                 g.id_guideline,
                                                 pk_guidelines.g_guide_link_type,
                                                 g_separator_link_str) || ')' descr
              FROM guideline g, guideline_process gp
             WHERE g.id_guideline = gp.id_guideline
               AND (gp.id_episode = i_episode OR
                   (gp.id_patient = i_patient AND nvl(gp.id_episode, -1) = -1 AND gp.flg_status != g_recommended_flag))
               AND g.flg_status != g_cancelled_flag
               AND gp.flg_status != g_cancelled_flag;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_guidprot);
            RETURN FALSE;
        
    END get_guidprot_progress_notes;

    /********************************************************************************************
    * get all guidelines applied to a patient within an episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 patient ID
    * @param       i_episode                 episode ID
    * @param       i_flg_status              guideline process status
    * @param       o_guidelines_list         list of guidelines 
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2011/02/11
    ********************************************************************************************/
    FUNCTION get_applied_guidelines_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_patient         IN patient.id_patient%TYPE,
        i_episode         IN episode.id_episode%TYPE,
        i_flg_status      IN guideline_process.flg_status%TYPE,
        o_guidelines_list OUT t_cur_applied_guidelines,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- open cursor with applied guidelines
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guidelines_list FOR
            SELECT DISTINCT g.guideline_desc AS guideline_title,
                            '(' || pk_guidelines.get_link_id_str(i_lang,
                                                                 i_prof,
                                                                 g.id_guideline,
                                                                 pk_guidelines.g_guide_link_type,
                                                                 g_separator_link_str) || ')' AS guideline_type,
                            -- date when this guideline was applied to the patient
                            gb.dt_guideline_batch AS guideline_date,
                            -- returns id professional only if this guideline was manually recommended by a professional
                            decode(gb.batch_type, g_batch_1p_1g, gp.id_professional, NULL) AS id_professional,
                            gp.id_guideline_process,
                            gp.dt_status AS dt_last_update
              FROM guideline g
              JOIN guideline_process gp
                ON g.id_guideline = gp.id_guideline
              JOIN guideline_batch gb
                ON gp.id_batch = gb.id_batch
             WHERE g.id_guideline = gp.id_guideline
               AND (gp.id_episode = i_episode OR (gp.id_patient = i_patient AND nvl(gp.id_episode, -1) = -1))
               AND gp.flg_status NOT IN (g_cancelled_flag, g_recommended_flag)
               AND gp.flg_status = nvl(i_flg_status, gp.flg_status);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_APPLIED_GUIDELINES_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_applied_guidelines_list;

    /********************************************************************************************
    * get frequent guidelines by institution
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_guidelines_frequent     cursor with all guidelines information (id_guideline, pathology_desc, guideline_desc, type_desc, flg_missing_data, flg_status, array(id_software, flg_type, type_desc))
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/20
    ********************************************************************************************/
    FUNCTION get_guidelines_frequent
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_guidelines_frequent   OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_sw_list pk_types.cursor_type;
        l_swlist         table_number;
        l_swlistnames    table_varchar;
    
        e_error_sw_list EXCEPTION;
    
    BEGIN
    
        -- creating software list cursor   
        g_error := 'GETTING SOFTWARE LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- getting software list
        IF (get_guidelines_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
        THEN
        
            FETCH l_cursor_sw_list BULK COLLECT
                INTO l_swlist, l_swlistnames;
            CLOSE l_cursor_sw_list;
        
            -- openning o_guideline_frequent cursor   
            g_error := 'OPEN CURSOR';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            OPEN o_guidelines_frequent FOR
                SELECT glines.guid_id,
                       glines.pathology_desc,
                       glines.guid_desc,
                       glines.type_desc,
                       glines.flg_missing_data,
                       glines.flg_status,
                       CAST(COLLECT(decode(substr(to_char(glines.swid) || g_separator_collection || sw_list.flg_type ||
                                                  g_separator_collection || sw_list.flg_type_desc,
                                                  -2),
                                           ',,',
                                           to_char(glines.swid) || g_separator_collection || g_undefined ||
                                           g_separator_collection ||
                                           pk_sysdomain.get_domain(g_guideline_enable_sysdomain, g_undefined, i_lang),
                                           to_char(glines.swid) || g_separator_collection || sw_list.flg_type ||
                                           g_separator_collection || sw_list.flg_type_desc)) AS table_varchar) values_desc
                  FROM (SELECT guid.id_guideline guid_id,
                               pk_guidelines.get_link_id_str(i_lang,
                                                             NULL,
                                                             guid.id_guideline,
                                                             pk_guidelines.g_guide_link_pathol,
                                                             g_separator_link_str) pathology_desc,
                               guid.guideline_desc guid_desc,
                               pk_guidelines.get_link_id_str(i_lang,
                                                             NULL,
                                                             guid.id_guideline,
                                                             pk_guidelines.g_guide_link_type,
                                                             g_separator_link_str) type_desc,
                               get_guideline_bo_status(guid.id_guideline, i_target_id_institution, l_swlist) flg_missing_data,
                               decode(guid.id_institution,
                                      pk_guidelines.g_all_institution,
                                      g_default_flag,
                                      decode(guid.flg_status,
                                             pk_guidelines.g_guideline_deleted,
                                             g_cancelled_flag,
                                             g_normal_flag)) flg_status,
                               allsw.column_value swid
                          FROM guideline guid,
                               (SELECT column_value
                                  FROM TABLE(l_swlist)) allsw
                         WHERE guid.id_institution IN (i_target_id_institution, pk_guidelines.g_all_institution)
                           AND guid.flg_status NOT IN
                               (pk_guidelines.g_guideline_temp, pk_guidelines.g_guideline_deprecated)) glines
                  LEFT OUTER JOIN (SELECT DISTINCT g.id_guideline idguid,
                                                   sd.id_software idsw,
                                                   decode(gf.id_guideline, NULL, g_searcheable, g_frequent) flg_type,
                                                   decode(gf.id_guideline,
                                                          NULL,
                                                          pk_sysdomain.get_domain(g_guideline_enable_sysdomain,
                                                                                  g_searcheable,
                                                                                  i_lang),
                                                          pk_sysdomain.get_domain(g_guideline_enable_sysdomain,
                                                                                  g_frequent,
                                                                                  i_lang)) flg_type_desc
                                     FROM guideline g
                                    INNER JOIN guideline_link glnk
                                       ON glnk.id_guideline = g.id_guideline
                                    INNER JOIN dept
                                       ON dept.id_dept = glnk.id_link
                                      AND dept.id_institution = g.id_institution
                                    INNER JOIN software_dept sd
                                       ON sd.id_dept = dept.id_dept
                                     LEFT OUTER JOIN guideline_frequent gf
                                       ON gf.id_guideline = g.id_guideline
                                      AND gf.id_institution = g.id_institution
                                      AND gf.id_software IN (sd.id_software, pk_guidelines.g_all_software)
                                    WHERE g.id_institution = i_target_id_institution
                                      AND sd.id_software IN (SELECT column_value
                                                               FROM TABLE(l_swlist))
                                      AND g.flg_status NOT IN
                                          (pk_guidelines.g_guideline_temp, pk_guidelines.g_guideline_deprecated)
                                      AND glnk.link_type = pk_guidelines.g_guide_link_envi) sw_list
                    ON sw_list.idguid = glines.guid_id
                   AND sw_list.idsw = glines.swid
                 GROUP BY glines.guid_id,
                          glines.pathology_desc,
                          glines.guid_desc,
                          glines.type_desc,
                          glines.flg_missing_data,
                          glines.flg_status
                 ORDER BY glines.pathology_desc, glines.guid_desc;
        
            RETURN TRUE;
        
        ELSE
            RAISE e_error_sw_list;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINES_FREQUENT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guidelines_frequent);
            -- return failure of function
            RETURN FALSE;
        
    END get_guidelines_frequent;

    /********************************************************************************************
    * set guideline as frequent or non frequent
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_guideline            guideline id
    * @param       i_id_institution          institution id
    * @param       i_id_software             software id to wich the guideline frequentness will be updated
    * @param       i_flg_status              turn on/off frequent status for given guideline id
    * @param       o_error                   error message
    *
    * @value       i_flg_status              {*} F frequent (activate frequent) {*} S searchable (deactivate frequent)    
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/02
    ********************************************************************************************/
    FUNCTION set_guideline_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_flg_status     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor_sw_list pk_types.cursor_type;
        l_swlist         table_number;
        l_swlistnames    table_varchar;
    
        l_guideline_freq guideline_frequent.id_guideline%TYPE;
    
        e_undefined_status EXCEPTION;
        e_frequent         EXCEPTION;
        e_not_frequent     EXCEPTION;
        e_error_sw_list    EXCEPTION;
    
    BEGIN
    
        -- get current frequent guidelines(if any)   
        g_error := 'GETTING CURRENT GUIDELINE FREQUENT ID';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        BEGIN
            SELECT gf.id_guideline
              INTO l_guideline_freq
              FROM guideline_frequent gf
             WHERE gf.id_guideline = i_id_guideline
               AND gf.id_institution = i_id_institution
               AND gf.id_software IN (i_id_software, pk_guidelines.g_all_software)
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_guideline_freq := -1;
        END;
    
        IF (i_flg_status = g_activate)
        THEN
            IF l_guideline_freq = -1
            THEN
                -- insert frequent guideline
                g_error := 'INSERTING FREQUENT GUIDELINE';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                INSERT INTO guideline_frequent
                    (rank, id_guideline, id_institution, id_software)
                VALUES
                    (g_def_guideline_frequent_rank, i_id_guideline, i_id_institution, i_id_software);
            ELSE
                RAISE e_frequent;
            END IF;
        ELSIF (i_flg_status = g_deactivate)
        THEN
            IF l_guideline_freq != -1
            THEN
                -- delete frequent guideline   
                g_error := 'DELETING FREQUENT GUIDELINE';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                DELETE guideline_frequent gf
                 WHERE gf.id_guideline = i_id_guideline
                   AND gf.id_institution = i_id_institution
                   AND gf.id_software = i_id_software;
            
                IF SQL%NOTFOUND
                THEN
                    -- delete master frequent guideline (sw id = 0)
                    g_error := 'DELETING MASTER FREQUENT GUIDELINE';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    DELETE guideline_frequent gf
                     WHERE gf.id_guideline = i_id_guideline
                       AND gf.id_institution = i_id_institution
                       AND gf.id_software = pk_guidelines.g_all_software;
                
                    -- creating frequent guidelines for all other than specified SW id   
                    g_error := 'INSERTING FREQUENT GUIDELINES (LOOP)';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    -- activation loop for other SWs below
                
                    -- getting software list
                    IF (get_guidelines_software_list(i_lang, i_prof, i_id_institution, l_cursor_sw_list, o_error))
                    THEN
                    
                        FETCH l_cursor_sw_list BULK COLLECT
                            INTO l_swlist, l_swlistnames;
                        CLOSE l_cursor_sw_list;
                    
                        FOR rec IN (SELECT column_value
                                      FROM TABLE(l_swlist))
                        LOOP
                            IF rec.column_value != i_id_software
                            THEN
                                INSERT INTO guideline_frequent
                                    (rank, id_guideline, id_institution, id_software)
                                VALUES
                                    (g_def_guideline_frequent_rank, i_id_guideline, i_id_institution, rec.column_value);
                            END IF;
                        END LOOP;
                    
                    ELSE
                        RAISE e_error_sw_list;
                    END IF;
                END IF;
            ELSE
                RAISE e_not_frequent;
            END IF;
        ELSE
            RAISE e_undefined_status;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN e_frequent THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / guideline already set to frequent',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_FREQUENT',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
        WHEN e_not_frequent THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / guideline already set to not frequent',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_FREQUENT',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
        WHEN e_undefined_status THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / flag status not known',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_FREQUENT',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_FREQUENT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_frequent;

    /********************************************************************************************
    * copy or duplicate guideline
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_guideline            source guideline id
    * @param       o_guideline               new guideline id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/25
    ********************************************************************************************/
    FUNCTION copy_guideline
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline             OUT guideline.id_guideline%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_guid_sw guideline.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        -- duplicating guidelines based on source guideline id   
        g_error := 'COPYING GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.create_guideline(i_lang,
                                                   profissional(i_prof.id, i_target_id_institution, l_guid_sw),
                                                   i_id_guideline,
                                                   g_duplicate_flag,
                                                   o_guideline,
                                                   o_error);
    
        IF l_result = TRUE
        THEN
            -- setting target guideline id        
            g_error := 'SETTING GUIDELINE';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            l_result := pk_guidelines.set_guideline(i_lang, i_prof, o_guideline, o_error);
        
            IF l_result = TRUE
            THEN
                RETURN TRUE;
            END IF;
        END IF;
    
        RAISE e_undefined_error;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'COPY_GUIDELINE',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END copy_guideline;

    /********************************************************************************************
    * cancel guideline / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_guideline            guideline id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/25
    ********************************************************************************************/
    FUNCTION cancel_guideline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_guideline IN guideline.id_guideline%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
        -- cancel guidelines by guideline id   
        g_error := 'CANCEL GUIDELINE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.cancel_guideline(i_lang, i_prof, i_id_guideline, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CANCEL_GUIDELINE',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END cancel_guideline;

    /********************************************************************************************
    * get guideline main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_main             guideline main attributes cursor
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/23
    ********************************************************************************************/
    FUNCTION get_guideline_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_main        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cursor_sw_list pk_types.cursor_type;
    
        l_sw_id   software.id_software%TYPE;
        l_sw_name software.name%TYPE;
    
        l_result BOOLEAN;
        e_error_sw_list  EXCEPTION;
        e_error_get_main EXCEPTION;
    
    BEGIN
        -- creating software list cursor   
        g_error := 'GETTING SOFTWARE LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- getting software list
        IF (get_guidelines_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
        THEN
        
            l_sw_id := 0; -- default state is: no CARE product for this institution
            LOOP
                FETCH l_cursor_sw_list
                    INTO l_sw_id, l_sw_name;
                EXIT WHEN l_cursor_sw_list%NOTFOUND OR l_sw_id = pk_alert_constant.g_soft_primary_care;
            END LOOP;
        
            -- getting guideline main details   
            g_error := 'GET GUIDELINE MAIN';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            IF l_sw_id = pk_alert_constant.g_soft_primary_care
            THEN
                l_result := pk_guidelines.get_guideline_main(i_lang,
                                                             profissional(NULL,
                                                                          NULL,
                                                                          pk_alert_constant.g_soft_primary_care),
                                                             i_id_guideline,
                                                             o_guideline_main,
                                                             o_error);
            ELSE
                l_result := pk_guidelines.get_guideline_main(i_lang, NULL, i_id_guideline, o_guideline_main, o_error);
            END IF;
        
            IF l_result = FALSE
            THEN
                RAISE e_error_get_main;
            END IF;
        
        ELSE
            RAISE e_error_sw_list;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        -- On any error
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_MAIN',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_main);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_main;

    /********************************************************************************************
    * get software list to wich guidelines are available
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_id_software             cursor with all softwares used by guidelines in target institution
    * @param       o_error                   error message
    *
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/02/18
    ********************************************************************************************/
    FUNCTION get_guidelines_software_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_id_software           OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        --OPEN o_id_software FOR 
        OPEN o_id_software FOR
            SELECT sw.id_software, sw.name
              FROM software_institution swi
             INNER JOIN software sw
                ON sw.id_software = swi.id_software
             WHERE id_institution = i_target_id_institution
               AND flg_mni = g_mni_flg
               AND flg_viewer = g_viewer_flg
               AND sw.id_software IN (pk_alert_constant.g_soft_outpatient,
                                      pk_alert_constant.g_soft_oris,
                                      pk_alert_constant.g_soft_primary_care,
                                      pk_alert_constant.g_soft_edis,
                                      pk_alert_constant.g_soft_inpatient,
                                      pk_alert_constant.g_soft_private_practice,
                                      pk_alert_constant.g_soft_ubu);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINES_SOFTWARE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_id_software);
            -- return failure of function
            RETURN FALSE;
        
    END get_guidelines_software_list;

    /********************************************************************************************
    * get multichoice for gender
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_criteria_type              criteria type
    * @param      o_guideline_gender           cursor with all genders
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    *********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_criteria_type    IN guideline_criteria.criteria_type%TYPE,
        o_guideline_gender OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GENDER LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_gender_list(i_lang, i_prof, i_criteria_type, o_guideline_gender, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GENDER_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_gender);
            -- return failure of function
            RETURN FALSE;
        
    END get_gender_list;

    /********************************************************************************************
    * get multichoice for languages
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_languages                  cursor with all languages
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_language_list
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_languages OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET LANGUAGE LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_language_list(i_lang, i_prof, o_languages, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_LANGUAGE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_languages);
            -- return failure of function
            RETURN FALSE;
        
    END get_language_list;

    /********************************************************************************************
    * get multichoice for guideline types
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_type             cursor with all guideline types
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_guideline   IN guideline.id_guideline%TYPE,
        o_guideline_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE TYPES LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_type_list(i_lang, i_prof, i_id_guideline, o_guideline_type, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TYPE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_type);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_type_list;

    /********************************************************************************************
    * get multichoice for environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_environment      cursor with all environment availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION get_guideline_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_environment OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE ENVIRONMENT LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_environment_list(i_lang,
                                                                 profissional(NULL, i_target_id_institution, NULL),
                                                                 i_id_guideline,
                                                                 o_guideline_environment,
                                                                 o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_ENVIRONMENT_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_environment);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_environment_list;

    /********************************************************************************************
    * get multichoice for professional
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_professional     cursor with all professional categories availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE PROFESSIONAL LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_prof_list(i_lang,
                                                          i_prof,
                                                          i_id_guideline,
                                                          o_guideline_professional,
                                                          o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_prof_list;

    /********************************************************************************************
    * get multichoice for ebm (evidence based medicine)
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_ebm              cursor with all ebm values availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_ebm_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_guideline  IN guideline.id_guideline%TYPE,
        o_guideline_ebm OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE EBM LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_ebm_list(i_lang, i_prof, i_id_guideline, o_guideline_ebm, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_EBM_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_ebm);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_ebm_list;

    /********************************************************************************************
    * get multichoice for type of media
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_guideline_tm               cursor with all types of media
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_type_media_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_guideline_tm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET TYPES OF MEDIA LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_type_media_list(i_lang, i_prof, o_guideline_tm, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_TYPE_MEDIA_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_tm);
            -- return failure of function
            RETURN FALSE;
        
    END get_type_media_list;

    /********************************************************************************************
    * get multichoice for professionals that will be able to edit guidelines
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_guideline               id of guideline.        
    * @param      o_guideline_professional     cursor with all professional categories availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_edit_prof_list
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_guideline           IN guideline.id_guideline%TYPE,
        o_guideline_professional OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE PROFESSIONALS EDIT LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_edit_prof_list(i_lang,
                                                               i_prof,
                                                               i_id_guideline,
                                                               o_guideline_professional,
                                                               o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_EDIT_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_edit_prof_list;

    /********************************************************************************************
    * get multichoice for types of guideline recommendation
    *
    * @param      i_lang                  preferred language id for this professional
    * @param      i_prof                  object (id of professional, id of institution, id of software)
    * @param      o_guideline_rec_mode    cursor with types of recommendation
    * @param      o_error                 error message
    *
    * @return     boolean                 true or false on success or error
    *
    * @author                             Carlos Loureiro
    * @version                            1.0
    * @since                              2009/02/25
    ********************************************************************************************/
    FUNCTION get_guideline_type_rec_list
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        o_guideline_type_rec OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET TYPES OF RECOMMENDATION LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_type_rec_list(i_lang, i_prof, o_guideline_type_rec, o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TYPE_REC_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_type_rec);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_type_rec_list;

    /********************************************************************************************
    * get guideline criteria
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      i_criteria_type              criteria type: inclusion / exclusion
    * @param      o_guideline_criteria         cursor for guideline criteria
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_criteria
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_criteria_type         IN guideline_criteria.criteria_type%TYPE,
        o_guideline_criteria    OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_guid_sw guideline.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        g_error := 'GET GUIDELINE CRITERIA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_criteria(i_lang,
                                                         profissional(NULL, i_target_id_institution, l_guid_sw),
                                                         i_id_guideline,
                                                         i_criteria_type,
                                                         o_guideline_criteria,
                                                         o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CRITERIA',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_criteria);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_criteria;

    /********************************************************************************************
    * get guideline task
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_task             cursor for guideline tasks
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_task
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_task        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_guid_sw guideline.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        g_error := 'GET GUIDELINE TASK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_task(i_lang,
                                                     profissional(NULL, i_target_id_institution, l_guid_sw),
                                                     i_id_guideline,
                                                     o_guideline_task,
                                                     o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_TASK',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_task);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_task;

    /********************************************************************************************
    * get guideline context
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      o_guideline_context          cursor for guideline context
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_context
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_context     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_guid_sw guideline.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        g_error := 'GET GUIDELINE CONTEXT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.get_guideline_context(i_lang,
                                                        profissional(NULL, i_target_id_institution, l_guid_sw),
                                                        i_id_guideline,
                                                        o_guideline_context,
                                                        o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_CONTEXT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_guideline_context);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_context;

    /********************************************************************************************
    * get list of images for a specific guideline
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      i_id_guideline_context_image  id of guideline image
    * @param      i_id_guideline                id of guideline
    * @param      o_context_images              images
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/02/26
    ********************************************************************************************/
    FUNCTION get_context_images
    (
        i_lang                       IN NUMBER,
        i_prof                       IN profissional,
        i_target_id_institution      IN institution.id_institution%TYPE,
        i_id_guideline_context_image IN guideline_context_image.id_guideline_context_image%TYPE,
        i_id_guideline               IN guideline_context_image.id_guideline%TYPE,
        o_context_images             OUT pk_types.cursor_type,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_guid_sw guideline.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        g_error := 'GET CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines_attach.get_context_images(i_lang,
                                                            profissional(NULL, i_target_id_institution, l_guid_sw),
                                                            i_id_guideline_context_image,
                                                            i_id_guideline,
                                                            o_context_images,
                                                            o_error);
    
        IF l_result = FALSE
        THEN
            RAISE e_undefined_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_CONTEXT_IMAGES',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_context_images);
            -- return failure of function
            RETURN FALSE;
        
    END get_context_images;

    /********************************************************************************************
    * get multichoice for specialty
    *
    * @param      i_lang                      preferred language id for this professional
    * @param      i_prof                      object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution     target institution id
    * @param      i_id_guideline              id of guideline.
    * @param      o_guideline_specialty       cursor with all specialty available
    * @param      o_error                     error
    *
    * @return     boolean                     true or false on success or error
    *
    * @author                                 Carlos Loureiro
    * @version                                1.0
    * @since                                  2009/02/26
    ********************************************************************************************/
    FUNCTION get_guideline_specialty_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        o_guideline_specialty   OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
        l_sw_id   software.id_software%TYPE;
        l_sw_name software.name%TYPE;
    
        l_cursor_sw_list pk_types.cursor_type;
    
        e_error_get_spec_list EXCEPTION;
        e_error_sw_list       EXCEPTION;
    
    BEGIN
    
        -- creating software list cursor   
        g_error := 'GETTING SOFTWARE LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- getting software list
        IF (get_guidelines_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
        THEN
        
            l_sw_id := 0; -- default state is: no CARE product for this institution
            LOOP
                FETCH l_cursor_sw_list
                    INTO l_sw_id, l_sw_name;
                EXIT WHEN l_cursor_sw_list%NOTFOUND OR l_sw_id = pk_alert_constant.g_soft_primary_care;
            END LOOP;
        
            g_error := 'GET SPECIALTY LIST';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            IF l_sw_id = pk_alert_constant.g_soft_primary_care
            THEN
                l_result := pk_guidelines.get_guideline_specialty_list(i_lang,
                                                                       profissional(NULL,
                                                                                    i_target_id_institution,
                                                                                    pk_alert_constant.g_soft_primary_care),
                                                                       i_id_guideline,
                                                                       o_guideline_specialty,
                                                                       o_error);
            ELSE
                l_result := pk_guidelines.get_guideline_specialty_list(i_lang,
                                                                       profissional(NULL,
                                                                                    i_target_id_institution,
                                                                                    pk_guidelines.g_all_software),
                                                                       i_id_guideline,
                                                                       o_guideline_specialty,
                                                                       o_error);
            END IF;
        
            IF l_result = FALSE
            THEN
                RAISE e_error_get_spec_list;
            END IF;
        
        ELSE
            RAISE e_error_sw_list;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_SPECIALTY_LIST',
                                              o_error);
            -- open cursors for java
            pk_types.open_my_cursor(o_guideline_specialty);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_specialty_list;

    /********************************************************************************************
    * set specific guideline main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_guideline               guideline id
    * @param      i_guideline_desc             guideline description       
    * @param      i_id_guideline_type          guideline type id list
    * @param      i_link_environment           guideline environment link list
    * @param      i_link_specialty             guideline specialty link list
    * @param      i_link_professional          guideline professional link list
    * @param      i_link_edit_prof             guideline edit professional link list
    * @param      i_type_recommendation        guideline type of recommendation
    * @param      o_id_guideline               guideline id associated with the new version
    * @param      o_error                      error message
    *
    * @value      i_type_recommendation        sys_domain where code_domain='GUIDELINE.FLG_TYPE_RECOMMENDATION'
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION set_guideline_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_guideline_desc        IN guideline.guideline_desc%TYPE,
        i_link_type             IN table_number,
        i_link_environment      IN table_number,
        i_link_specialty        IN table_number,
        i_link_professional     IN table_number,
        i_link_edit_prof        IN table_number,
        i_type_recommendation   IN guideline.flg_type_recommendation%TYPE,
        o_id_guideline          OUT guideline.id_guideline%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
        l_guid_sw guideline.id_software%TYPE;
    
        e_create_guidel_error EXCEPTION;
        e_set_guid_main_error EXCEPTION;
        e_set_guideline_error EXCEPTION;
    
    BEGIN
    
        -- use guideline software id as input for calling the next function
        SELECT guid.id_software
          INTO l_guid_sw
          FROM guideline guid
         WHERE guid.id_guideline = i_id_guideline;
    
        -- creating new version guideline based on input guideline id   
        g_error := 'CREATING NEW GUIDELINE VERSION';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_guidelines.create_guideline(i_lang,
                                                   profissional(i_prof.id, i_target_id_institution, l_guid_sw),
                                                   i_id_guideline,
                                                   g_new_version_flag,
                                                   o_id_guideline,
                                                   o_error);
    
        IF l_result = TRUE
        THEN
            -- setting new attributes to the new version of the guideline
            g_error := 'SET GUIDELINE MAIN';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            l_result := pk_guidelines.set_guideline_main(i_lang,
                                                         i_prof,
                                                         o_id_guideline,
                                                         i_guideline_desc,
                                                         i_link_type,
                                                         i_link_environment,
                                                         i_link_specialty,
                                                         i_link_professional,
                                                         i_link_edit_prof,
                                                         i_type_recommendation,
                                                         o_error);
        
            IF l_result = TRUE
            THEN
                -- finalize guideline
                g_error := 'SET GUIDELINE';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                l_result := pk_guidelines.set_guideline(i_lang, i_prof, o_id_guideline, o_error);
            
                IF l_result = FALSE
                THEN
                    RAISE e_set_guideline_error;
                END IF;
            ELSE
                RAISE e_set_guid_main_error;
            END IF;
        ELSE
            RAISE e_create_guidel_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_GUIDELINE_MAIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_guideline_main;

    /********************************************************************************************
    * get available guideline items to be shown
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      o_items                       list of items to be shown
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/02/27
    ********************************************************************************************/
    FUNCTION get_guideline_items
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_items                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GUIDELINE ITEMS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_items FOR
            SELECT DISTINCT item, flg_item_type
              FROM (SELECT item,
                           flg_item_type,
                           first_value(gisi.flg_available) over(PARTITION BY gisi.item, gisi.flg_item_type ORDER BY(gisi.id_software + gisi.id_institution) DESC, gisi.flg_available) AS flg_avail
                      FROM guideline_item_soft_inst gisi
                     WHERE gisi.id_institution IN (pk_guidelines.g_all_institution, i_target_id_institution)) guide_item
             WHERE flg_avail = pk_guidelines.g_available
               AND ((guide_item.flg_item_type = pk_guidelines.g_guideline_item_criteria AND
                   guide_item.item NOT IN (SELECT id_guideline_criteria_type
                                               FROM guideline_criteria_type)) OR
                   guide_item.flg_item_type = pk_guidelines.g_guideline_item_tasks);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_ITEMS',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_items);
            -- return failure of function
            RETURN FALSE;
        
    END get_guideline_items;

    /********************************************************************************************
    * get guideline missing flag status for backoffice use (internal use only)
    *
    * @param      i_id_guideline               guideline id
    * @param      i_target_id_institution      target institution id
    * @param      i_sw_list                    list of allowed softwares    
    *
    * @return     varchar2                     backoffice missing flag status
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/05
    ********************************************************************************************/
    FUNCTION get_guideline_bo_status
    (
        i_id_guideline          IN guideline.id_guideline%TYPE,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_sw_list               IN table_number
    ) RETURN VARCHAR2 IS
    
        l_result PLS_INTEGER;
        l_sw_id  software.id_software%TYPE;
    
    BEGIN
        -- validate if target institution uses care software (zero if not found)
        BEGIN
            SELECT sw.column_value
              INTO l_sw_id
              FROM TABLE(i_sw_list) sw
             WHERE sw.column_value = pk_alert_constant.g_soft_primary_care;
        EXCEPTION
            WHEN no_data_found THEN
                l_sw_id := pk_guidelines.g_all_software;
        END;
    
        -- validate if configured SWs are available in target institution 
        -- (greater than zero means that some configured SW's are not present in institiution)
        SELECT COUNT(sd.id_software)
          INTO l_result
          FROM guideline_link gl
         INNER JOIN software_dept sd
            ON sd.id_software_dept = gl.id_link
         WHERE gl.id_guideline = i_id_guideline
           AND gl.link_type = pk_guidelines.g_guide_link_envi
           AND sd.id_software NOT IN (SELECT column_value
                                        FROM TABLE(i_sw_list));
    
        IF l_result = 0
        THEN
            IF l_sw_id = pk_alert_constant.g_soft_primary_care
            THEN
                -- check if guideline's clinical services exists in target institution
                SELECT COUNT(cs.id_clinical_service)
                  INTO l_result
                  FROM guideline_link gl
                 INNER JOIN clinical_service cs
                    ON gl.id_link = cs.id_clinical_service
                 WHERE gl.id_guideline = i_id_guideline
                   AND gl.link_type = pk_guidelines.g_guide_link_spec
                   AND cs.id_clinical_service NOT IN
                       (SELECT DISTINCT cserv.id_clinical_service
                          FROM clinical_service cserv
                         INNER JOIN dep_clin_serv dcs
                            ON dcs.id_clinical_service = cserv.id_clinical_service
                         INNER JOIN department dep
                            ON dep.id_dept = dcs.id_department
                         INNER JOIN dept
                            ON dept.id_dept = dep.id_dept
                           AND dept.id_institution = dep.id_institution
                         INNER JOIN software_dept swdept
                            ON swdept.id_dept = dept.id_dept
                         WHERE cserv.flg_available = g_available
                           AND dcs.flg_available = g_available
                           AND dep.flg_available = g_available
                           AND dept.flg_available = g_available
                           AND dept.id_institution = i_target_id_institution
                           AND swdept.id_software = pk_alert_constant.g_soft_primary_care);
            
                IF l_result = 0
                THEN
                    RETURN g_missing_flg_no;
                END IF;
            ELSE
                -- check if guideline's assigned specialities exists in target institution
                SELECT COUNT(s.id_speciality)
                  INTO l_result
                  FROM guideline_link gl
                 INNER JOIN speciality s
                    ON gl.id_link = s.id_speciality
                 WHERE gl.id_guideline = i_id_guideline
                   AND gl.link_type = pk_guidelines.g_guide_link_spec
                   AND s.id_speciality NOT IN
                       (SELECT nvl(prof.id_speciality, -1)
                          FROM prof_soft_inst psi
                         INNER JOIN professional prof
                            ON psi.id_professional = prof.id_professional
                         INNER JOIN prof_institution pi
                            ON psi.id_institution = pi.id_institution
                           AND prof.id_professional = pi.id_professional
                         WHERE psi.id_institution = i_target_id_institution
                           AND pi.flg_state = g_professional_active
                           AND prof.flg_state = g_professional_active
                           AND psi.id_software IN (pk_alert_constant.g_soft_outpatient,
                                                   pk_alert_constant.g_soft_oris,
                                                   pk_alert_constant.g_soft_edis,
                                                   pk_alert_constant.g_soft_inpatient,
                                                   pk_alert_constant.g_soft_private_practice,
                                                   pk_alert_constant.g_soft_ubu));
            
                IF l_result = 0
                THEN
                    RETURN g_missing_flg_no;
                END IF;
            END IF;
        END IF;
    
        RETURN g_missing_flg_yes;
    
    END get_guideline_bo_status;

    /********************************************************************************************
    * clear particular guideline processes or clear all guidelines processes related with
    * a list of patients or guidelines
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_guidelines              guidelines array    
    * @param       i_guideline_processes     guideline processes array        
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_guideline_processes
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_patients            IN table_number DEFAULT NULL,
        i_guidelines          IN table_number DEFAULT NULL,
        i_guideline_processes IN table_number DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_guid IS
            SELECT gp.id_guideline_process
              FROM guideline_process gp
             WHERE gp.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                      column_value AS VALUE
                                       FROM TABLE(i_patients) pat)
                OR gp.id_guideline IN (SELECT /*+ OPT_ESTIMATE(table guids rows = 1)*/
                                        column_value AS VALUE
                                         FROM TABLE(i_guidelines) guids)
                OR gp.id_guideline_process IN
                   (SELECT /*+ OPT_ESTIMATE(table guid_procs rows = 1)*/
                     column_value AS VALUE
                      FROM TABLE(i_guideline_processes) guid_procs);
    
        l_guideline_processes table_number;
    
    BEGIN
    
        g_error := 'CLEAR GUIDELINE PROCESSES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        g_error := 'GET ALL GUIDELINE PROCESSES TO REMOVE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN c_guid;
        FETCH c_guid BULK COLLECT
            INTO l_guideline_processes;
        CLOSE c_guid;
    
        g_error := 'DEL GUIDELINE_PROCESS_TASK_HIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_guideline_processes.last
            DELETE guideline_process_task_hist gpth
             WHERE gpth.id_guideline_process_task IN
                   (SELECT gpt.id_guideline_process_task
                      FROM guideline_process_task gpt
                     WHERE gpt.id_guideline_process = l_guideline_processes(i));
    
        g_error := 'DEL GUIDELINE_PROCESS_TASK_DET';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_guideline_processes.last
            DELETE guideline_process_task_det gptd
             WHERE gptd.id_guideline_process_task IN
                   (SELECT gpt.id_guideline_process_task
                      FROM guideline_process_task gpt
                     WHERE gpt.id_guideline_process = l_guideline_processes(i));
    
        g_error := 'DEL GUIDELINE_PROCESS_TASK';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_guideline_processes.last
            DELETE FROM guideline_process_task gpt
             WHERE gpt.id_guideline_process = l_guideline_processes(i);
    
        g_error := 'DEL GUIDELINE_PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_guideline_processes.last
            DELETE FROM guideline_process gp
             WHERE gp.id_guideline_process = l_guideline_processes(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CLEAR_GUIDELINE_PROCESSES',
                                              o_error);
            RETURN FALSE;
    END clear_guideline_processes;

    /********************************************************************************************
    * delete a list of guidelines and its processes
    *
    * @param       i_lang         preferred language id for this professional
    * @param       i_prof         professional id structure
    * @param       i_guidelines   guideline IDs
    * @param       o_error        error message
    *        
    * @return      boolean        true on success, otherwise false    
    *   
    * @author                     Tiago Silva
    * @since                      2010/11/02
    ********************************************************************************************/
    FUNCTION delete_guidelines
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_guidelines IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'DELETE GUIDELINES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- deprecate guidelines (guidelines shouldn't be deleted)
        UPDATE guideline
           SET flg_status = pk_guidelines.g_guideline_deprecated
         WHERE id_guideline IN (SELECT /*+ OPT_ESTIMATE(table guids rows = 1)*/
                                 column_value AS VALUE
                                  FROM TABLE(i_guidelines) guids);
    
        -- clear all guidelines processes related with these guidelines    
        IF NOT clear_guideline_processes(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_guidelines => i_guidelines,
                                         o_error      => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'DELETE_GUIDELINES',
                                              o_error);
            RETURN FALSE;
    END delete_guidelines;

    /********************************************************************************************
    * get guideline/task process details for a given patient
    * API for REPORTS
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      o_guideline_process          cursor with guideline process main information / context
    * @param      o_guideline_process_detail   cursor with all process tasks help information / context
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   12-Nov-2010
    ********************************************************************************************/
    FUNCTION get_guideline_process_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_patient                  IN guideline_process.id_patient%TYPE,
        o_guideline_process        OUT pk_types.cursor_type,
        o_guideline_process_detail OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_guid_process table_number;
        l_exception EXCEPTION;
    
    BEGIN
        g_error := 'update guideline processes and associated tasks';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        IF NOT pk_guidelines.update_all_guide_proc_status(i_lang, i_prof, i_patient, o_error)
        THEN
            RAISE l_exception;
        END IF;
        COMMIT;
    
        g_error := 'get guideline processes';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        SELECT gp.id_guideline_process
          BULK COLLECT
          INTO l_guid_process
          FROM guideline guid
          JOIN guideline_process gp
            ON guid.id_guideline = gp.id_guideline
         WHERE gp.id_patient = i_patient
           AND EXISTS
         (SELECT 1
                  FROM guideline_process_task gpt
                 WHERE gpt.id_guideline_process = gp.id_guideline_process
                   AND gpt.flg_status_last NOT IN (pk_guidelines.g_process_recommended, pk_guidelines.g_process_pending));
    
        g_error := 'GET CURSOR O_GUIDELINE_MAIN';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_process FOR
            SELECT guid_proc.id_guideline_process,
                   guid.id_guideline,
                   guid.guideline_desc,
                   pk_guidelines.get_link_id_str(i_lang,
                                                 i_prof,
                                                 guid.id_guideline,
                                                 pk_guidelines.g_guide_link_pathol,
                                                 pk_guidelines.g_separator2) pathology_desc,
                   guid_proc.flg_status,
                   decode(guid_proc.flg_status,
                          pk_guidelines.g_process_canceled,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc.id_prof_cancel),
                          NULL) AS prof_cancel,
                   decode(guid_proc.flg_status,
                          pk_guidelines.g_process_canceled,
                          pk_prof_utils.get_prof_speciality(i_lang,
                                                            profissional(guid_proc.id_prof_cancel,
                                                                         i_prof.institution,
                                                                         i_prof.software)),
                          NULL) prof_spec_cancel,
                   nvl2(id_cancel_reason,
                        pk_translation.get_translation(i_lang, 'CANCEL_REASON.CODE_CANCEL_REASON.' || id_cancel_reason),
                        NULL) AS cancel_reason,
                   guid_proc.cancel_notes,
                   decode(guid_proc.flg_status,
                          pk_guidelines.g_process_canceled,
                          pk_date_utils.date_send_tsz(i_lang, guid_proc.dt_status, i_prof),
                          NULL) AS cancel_date_raw,
                   decode(guid_proc.flg_status,
                          pk_guidelines.g_process_canceled,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                             guid_proc.dt_status,
                                                             i_prof.institution,
                                                             i_prof.software),
                          NULL) AS cancel_date
              FROM guideline guid
              JOIN guideline_process guid_proc
                ON guid_proc.id_guideline = guid.id_guideline
             WHERE guid_proc.id_guideline_process IN
                   (SELECT /*+opt_estimate(table tgp rows=1)*/
                     column_value
                      FROM TABLE(l_guid_process) tgp);
    
        g_error := 'GET CURSOR O_GUIDELINE_DETAIL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_guideline_process_detail FOR
            SELECT guid_proc.id_guideline_process,
                   guid_proc_task.id_guideline_process_task,
                   guid_proc_task.task_type,
                   pk_sysdomain.get_domain(pk_guidelines.g_domain_task_type, guid_proc_task.task_type, i_lang) AS task_type_desc,
                   guid_proc_task.id_task,
                   decode(guid_proc_task.task_type,
                          pk_guidelines.g_task_patient_education,
                          CASE guid_proc_task.id_task
                              WHEN '-1' THEN
                               guid_proc_task.task_notes
                              ELSE
                               pk_patient_education_api_db.get_nurse_teach_topic_title(i_lang,
                                                                                       i_prof,
                                                                                       guid_proc_task.id_task)
                          END,
                          pk_guidelines.g_task_spec,
                          pk_guidelines.get_task_id_desc(i_lang,
                                                         i_prof,
                                                         guid_proc_task.id_task,
                                                         guid_proc_task.task_type,
                                                         guid_proc_task.task_codification) ||
                          decode(guid_proc_task.id_task_attach,
                                 '-1', -- physician = <any>
                                 '',
                                 nvl2(pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach),
                                      ' (' ||
                                      pk_prof_utils.get_name_signature(i_lang, i_prof, guid_proc_task.id_task_attach) || ')',
                                      NULL)),
                          pk_guidelines.get_task_id_desc(i_lang,
                                                         i_prof,
                                                         guid_proc_task.id_task,
                                                         guid_proc_task.task_type,
                                                         guid_proc_task.task_codification)) AS task_desc,
                   guid_proc_task_hst.flg_status_new,
                   pk_sysdomain.get_domain(pk_guidelines.g_domain_flg_guideline_task,
                                           guid_proc_task_hst.flg_status_new,
                                           i_lang) AS flg_status_new_desc,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang,
                                                      guid_proc_task_hst.dt_status_change,
                                                      i_prof.institution,
                                                      i_prof.software) AS dt_status_change,
                   guid_proc_task_hst.dt_status_change AS dt_status_change_tstz,
                   pk_date_utils.date_send_tsz(i_lang,
                                               guid_proc_task_hst.dt_status_change,
                                               i_prof.institution,
                                               i_prof.software) AS dt_status_raw,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, prof.id_professional) AS nick_name,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    guid_proc_task.id_professional,
                                                    guid_proc_task.dt_request,
                                                    NULL) AS request_author_spec,
                   nvl2(guid_proc_task_hst.id_cancel_reason,
                        pk_translation.get_translation(i_lang,
                                                       'CANCEL_REASON.CODE_CANCEL_REASON.' ||
                                                       guid_proc_task_hst.id_cancel_reason),
                        NULL) AS cancel_reason,
                   guid_proc_task_hst.cancel_notes
              FROM guideline_process_task_hist guid_proc_task_hst,
                   guideline_process_task      guid_proc_task,
                   guideline_process           guid_proc,
                   professional                prof
             WHERE guid_proc_task_hst.id_guideline_process_task = guid_proc_task.id_guideline_process_task
               AND guid_proc.id_guideline_process = guid_proc_task.id_guideline_process
               AND prof.id_professional = guid_proc_task_hst.id_professional
               AND guid_proc_task.flg_status_last NOT IN
                   (pk_guidelines.g_process_recommended, pk_guidelines.g_process_pending)
               AND guid_proc.id_guideline_process IN
                   (SELECT /*+opt_estimate(table tgp rows=1)*/
                     column_value
                      FROM TABLE(l_guid_process) tgp);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_GUIDELINE_PROCESS_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_guideline_process);
            pk_types.open_my_cursor(o_guideline_process_detail);
            RETURN FALSE;
    END get_guideline_process_detail;

/********************************************************************************************/
/********************************************************************************************/
/********************************************************************************************/

BEGIN

    -- Logging mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);

END pk_api_guidelines;
/
