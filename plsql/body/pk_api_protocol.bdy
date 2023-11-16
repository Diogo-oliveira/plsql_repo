pk_api_gpk_api_gui/*-- Last Change Revision: $Rev: 1943325 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2020-03-27 17:05:56 +0000 (sex, 27 mar 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_protocol IS

    /********************************************************************************************
    * get all protocols applied to a patient within an episode
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patient                 patient ID
    * @param       i_episode                 episode ID
    * @param       i_flg_status              protocol process status
    * @param       o_protocols_list          list of protocols
    * @param       o_error                   error message
    *
    * @return      boolean                   true on success, otherwise false
    *
    * @author                                Tiago Silva
    * @since                                 2011/02/11
    ********************************************************************************************/
    FUNCTION get_applied_protocols_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_episode        IN episode.id_episode%TYPE,
        i_flg_status     IN guideline_process.flg_status%TYPE,
        o_protocols_list OUT t_cur_applied_protocols,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        -- open cursor with applied protocols
        g_error := 'OPEN CURSOR';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_protocols_list FOR
            SELECT p.protocol_desc AS protocol_title,
                   '(' || pk_protocol.get_link_id_str(i_lang,
                                                      i_prof,
                                                      p.id_protocol,
                                                      pk_protocol.g_protocol_link_type,
                                                      g_separator_link_str) || ')' AS protocol_type,
                   -- date when this protocol was applied to the patient
                   pb.dt_protocol_batch AS protocol_date,
                   -- returns id professional only if this protocol was manually recommended by a professional
                   decode(pb.batch_type, g_batch_1p_1g, pp.id_professional, NULL) AS id_professional,
                   pp.id_protocol_process,
                   pp.dt_status AS dt_last_update
              FROM protocol p
              JOIN protocol_process pp
                ON p.id_protocol = pp.id_protocol
              JOIN protocol_batch pb
                ON pp.id_protocol_batch = pb.id_protocol_batch
             WHERE p.id_protocol = pp.id_protocol
               AND (pp.id_episode = i_episode OR (pp.id_patient = i_patient AND nvl(pp.id_episode, -1) = -1))
               AND pp.flg_status NOT IN (g_cancelled_flag, pk_protocol.g_process_recommended)
               AND pp.flg_status = nvl(i_flg_status, pp.flg_status);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_APPLIED_PROTOCOLS_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_applied_protocols_list;

    /********************************************************************************************
    * get frequent protocols by institution
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_protocols_frequent      cursor with all protocols information (id_protocols, pathology_desc, protocol_desc, type_desc, flg_missing_data, flg_status, array(id_software, flg_type, type_desc))
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocols_frequent
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_protocols_frequent    OUT pk_types.cursor_type,
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
        IF (get_protocols_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
        THEN
        
            FETCH l_cursor_sw_list BULK COLLECT
                INTO l_swlist, l_swlistnames;
            CLOSE l_cursor_sw_list;
        
            -- openning o_protocol_frequent cursor   
            g_error := 'OPEN CURSOR';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            OPEN o_protocols_frequent FOR
                SELECT pcols.prot_id,
                       pcols.pathology_desc,
                       pcols.prot_desc,
                       pcols.type_desc,
                       pcols.flg_missing_data,
                       pcols.flg_status,
                       CAST(COLLECT(decode(substr(to_char(pcols.swid) || g_separator_collection || sw_list.flg_type ||
                                                  g_separator_collection || sw_list.flg_type_desc,
                                                  -2),
                                           ',,',
                                           to_char(pcols.swid) || g_separator_collection || g_undefined ||
                                           g_separator_collection ||
                                           pk_sysdomain.get_domain(g_protocol_enable_sysdomain, g_undefined, i_lang),
                                           to_char(pcols.swid) || g_separator_collection || sw_list.flg_type ||
                                           g_separator_collection || sw_list.flg_type_desc)) AS table_varchar) values_desc
                  FROM (SELECT prot.id_protocol prot_id,
                               pk_protocol.get_link_id_str(i_lang,
                                                           NULL,
                                                           prot.id_protocol,
                                                           pk_protocol.g_protocol_link_pathol,
                                                           g_separator_link_str) pathology_desc,
                               prot.protocol_desc prot_desc,
                               pk_protocol.get_link_id_str(i_lang,
                                                           NULL,
                                                           prot.id_protocol,
                                                           pk_protocol.g_protocol_link_type,
                                                           g_separator_link_str) type_desc,
                               get_protocol_bo_status(prot.id_protocol, i_target_id_institution, l_swlist) flg_missing_data,
                               decode(prot.id_institution,
                                      pk_protocol.g_all_institution,
                                      g_default_flag,
                                      decode(prot.flg_status,
                                             pk_protocol.g_protocol_deleted,
                                             g_cancelled_flag,
                                             g_normal_flag)) flg_status,
                               allsw.column_value swid
                          FROM protocol prot,
                               (SELECT column_value
                                  FROM TABLE(l_swlist)) allsw
                         WHERE prot.id_institution IN (i_target_id_institution, pk_protocol.g_all_institution)
                           AND prot.flg_status NOT IN (pk_protocol.g_protocol_temp, pk_protocol.g_protocol_deprecated)) pcols
                  LEFT OUTER JOIN (SELECT DISTINCT p.id_protocol idprot,
                                                   sd.id_software idsw,
                                                   decode(pf.id_protocol, NULL, g_searcheable, g_frequent) flg_type,
                                                   decode(pf.id_protocol,
                                                          NULL,
                                                          pk_sysdomain.get_domain(g_protocol_enable_sysdomain,
                                                                                  g_searcheable,
                                                                                  i_lang),
                                                          pk_sysdomain.get_domain(g_protocol_enable_sysdomain,
                                                                                  g_frequent,
                                                                                  i_lang)) flg_type_desc
                                     FROM protocol p
                                    INNER JOIN protocol_link plnk
                                       ON plnk.id_protocol = p.id_protocol
                                    INNER JOIN dept
                                       ON dept.id_dept = plnk.id_link
                                      AND dept.id_institution = p.id_institution
                                    INNER JOIN software_dept sd
                                       ON sd.id_dept = dept.id_dept
                                     LEFT OUTER JOIN protocol_frequent pf
                                       ON pf.id_protocol = p.id_protocol
                                      AND pf.id_institution = p.id_institution
                                      AND pf.id_software IN (sd.id_software, pk_protocol.g_all_software)
                                    WHERE p.id_institution = i_target_id_institution
                                      AND sd.id_software IN (SELECT column_value
                                                               FROM TABLE(l_swlist))
                                      AND p.flg_status NOT IN
                                          (pk_protocol.g_protocol_temp, pk_protocol.g_protocol_deprecated)
                                      AND plnk.link_type = pk_protocol.g_protocol_link_envi) sw_list
                    ON sw_list.idprot = pcols.prot_id
                   AND sw_list.idsw = pcols.swid
                 GROUP BY pcols.prot_id,
                          pcols.pathology_desc,
                          pcols.prot_desc,
                          pcols.type_desc,
                          pcols.flg_missing_data,
                          pcols.flg_status
                 ORDER BY pcols.pathology_desc, pcols.prot_desc;
        
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
                                              'GET_PROTOCOLS_FREQUENT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocols_frequent);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocols_frequent;

    /********************************************************************************************
    * set protocol as frequent or non frequent
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_id_protocol             protocol id
    * @param       i_id_institution          institution id
    * @param       i_id_software             software id to wich the protocol frequentness will be updated
    * @param       i_flg_status              turn on/off frequent status for given protocol id
    * @param       o_error                   error message
    *
    * @value       i_flg_status              {*} F frequent (activate frequent) {*} S searchable (deactivate frequent)
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION set_protocol_frequent
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_protocol    IN protocol.id_protocol%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_flg_status     IN VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_cursor_sw_list pk_types.cursor_type;
        l_swlist         table_number;
        l_swlistnames    table_varchar;
    
        l_protocol_freq protocol_frequent.id_protocol%TYPE;
    
        e_undefined_status EXCEPTION;
        e_frequent         EXCEPTION;
        e_not_frequent     EXCEPTION;
        e_error_sw_list    EXCEPTION;
    
    BEGIN
    
        -- get current frequent protocols (if any)   
        g_error := 'GETTING CURRENT PROTOCOL FREQUENT ID';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        BEGIN
            SELECT pf.id_protocol
              INTO l_protocol_freq
              FROM protocol_frequent pf
             WHERE pf.id_protocol = i_id_protocol
               AND pf.id_institution = i_id_institution
               AND pf.id_software IN (i_id_software, pk_protocol.g_all_software)
               AND rownum = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                l_protocol_freq := -1;
        END;
    
        IF (i_flg_status = g_activate)
        THEN
            IF l_protocol_freq = -1
            THEN
                -- insert frequent protocol
                g_error := 'INSERTING FREQUENT PROTOCOL';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                INSERT INTO protocol_frequent
                    (rank, id_protocol, id_institution, id_software)
                VALUES
                    (g_def_protocol_frequent_rank, i_id_protocol, i_id_institution, i_id_software);
            ELSE
                RAISE e_frequent;
            END IF;
        ELSIF (i_flg_status = g_deactivate)
        THEN
            IF l_protocol_freq != -1
            THEN
                -- delete frequent protocol   
                g_error := 'DELETING FREQUENT PROTOCOL';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                DELETE protocol_frequent pf
                 WHERE pf.id_protocol = i_id_protocol
                   AND pf.id_institution = i_id_institution
                   AND pf.id_software = i_id_software;
            
                IF SQL%NOTFOUND
                THEN
                    -- delete master frequent protocol (sw id = 0)
                    g_error := 'DELETING MASTER FREQUENT PROTOCOL';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    DELETE protocol_frequent pf
                     WHERE pf.id_protocol = i_id_protocol
                       AND pf.id_institution = i_id_institution
                       AND pf.id_software = pk_protocol.g_all_software;
                
                    -- creating frequent protocols for all other than specified SW id   
                    g_error := 'INSERTING FREQUENT PROTOCOLS (LOOP)';
                    pk_alertlog.log_debug(g_error, g_log_object_name);
                
                    -- activation loop for other SWs below
                
                    -- getting software list
                    IF (get_protocols_software_list(i_lang, i_prof, i_id_institution, l_cursor_sw_list, o_error))
                    THEN
                    
                        FETCH l_cursor_sw_list BULK COLLECT
                            INTO l_swlist, l_swlistnames;
                        CLOSE l_cursor_sw_list;
                    
                        FOR rec IN (SELECT column_value
                                      FROM TABLE(l_swlist))
                        LOOP
                            IF rec.column_value != i_id_software
                            THEN
                                INSERT INTO protocol_frequent
                                    (rank, id_protocol, id_institution, id_software)
                                VALUES
                                    (g_def_protocol_frequent_rank, i_id_protocol, i_id_institution, rec.column_value);
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
                                              g_error || ' / protocol already set to frequent',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_PROTOCOL_FREQUENT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
        WHEN e_not_frequent THEN
            -- setting error content
            pk_alert_exceptions.process_error(i_lang,
                                              NULL,
                                              NULL,
                                              g_error || ' / protocol already set to not frequent',
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'SET_PROTOCOL_FREQUENT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
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
                                              'SET_PROTOCOL_FREQUENT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
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
                                              'SET_PROTOCOL_FREQUENT',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_protocol_frequent;

    /********************************************************************************************
    * copy or duplicate protocol
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_target_id_institution   target institution id
    * @param       i_id_protocol             source protocol id
    * @param       o_protocol                new protocol id
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION copy_protocol
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol              OUT protocol.id_protocol%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_prot_sw protocol.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use protocol software id as input for calling the next function
        SELECT prot.id_software
          INTO l_prot_sw
          FROM protocol prot
         WHERE prot.id_protocol = i_id_protocol;
    
        -- duplicating protocols based on source protocol id   
        g_error := 'COPYING PROTOCOL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.create_protocol(i_lang,
                                                profissional(i_prof.id, i_target_id_institution, l_prot_sw),
                                                i_id_protocol,
                                                g_duplicate_flag,
                                                o_protocol,
                                                o_error);
    
        IF l_result = TRUE
        THEN
            -- setting target protocol id        
            g_error := 'SETTING PROTOCOL';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            l_result := pk_protocol.set_protocol(i_lang, i_prof, o_protocol, o_error);
        
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
                                              'COPY_PROTOCOL',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END copy_protocol;

    /********************************************************************************************
    * cancel protocol / mark as deleted
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    object (id of professional, id of institution, id of software)
    * @param       i_id_protocol             protocol id to cancel
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION cancel_protocol
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_protocol IN protocol.id_protocol%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
        -- cancel protocols by protocol id   
        g_error := 'CANCEL PROTOCOL';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.cancel_protocol(i_lang, i_prof, i_id_protocol, o_error);
    
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
                                              'CANCEL_PROTOCOL',
                                              o_error);
            -- return failure of function
            RETURN FALSE;
        
    END cancel_protocol;

    /********************************************************************************************
    * get protocol main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_main              protocol main attributes cursor
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_main         OUT pk_types.cursor_type,
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
        IF (get_protocols_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
        THEN
        
            l_sw_id := 0; -- default state is: no CARE product for this institution
            LOOP
                FETCH l_cursor_sw_list
                    INTO l_sw_id, l_sw_name;
                EXIT WHEN l_cursor_sw_list%NOTFOUND OR l_sw_id = pk_alert_constant.g_soft_primary_care;
            END LOOP;
        
            -- getting protocol main details   
            g_error := 'GET PROTOCOL MAIN';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            IF l_sw_id = pk_alert_constant.g_soft_primary_care
            THEN
                dbms_output.put_line('ok');
                l_result := pk_protocol.get_protocol_main(i_lang,
                                                          profissional(NULL, NULL, pk_alert_constant.g_soft_primary_care),
                                                          i_id_protocol,
                                                          o_protocol_main,
                                                          o_error);
            ELSE
                l_result := pk_protocol.get_protocol_main(i_lang, NULL, i_id_protocol, o_protocol_main, o_error);
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
                                              'GET_PROTOCOL_MAIN',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_main);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_main;

    /********************************************************************************************
    * get software list to wich protocols are available
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_target_id_institution   target institution id
    * @param       o_id_software             cursor with all softwares used by protocols in target institution
    * @param       o_error                   error message
    *
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @version                               1.0
    * @since                                 2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocols_software_list
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
    
        OPEN o_id_software FOR
            SELECT sw.id_software, sw.name
              FROM software_institution swi
             INNER JOIN software sw
                ON sw.id_software = swi.id_software
             WHERE id_institution = i_target_id_institution
               AND flg_mni = 'Y'
               AND flg_viewer = 'N'
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
                                              'GET_PROTOCOLS_SOFTWARE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_id_software);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocols_software_list;

    /********************************************************************************************
    * get multichoice for gender
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_criteria_type              criteria type
    * @param      o_protocol_gender            cursor with all genders
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    *********************************************************************************************/
    FUNCTION get_gender_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_criteria_type   IN protocol_criteria.criteria_type%TYPE,
        o_protocol_gender OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET GENDER LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_gender_list(i_lang, i_prof, i_criteria_type, o_protocol_gender, o_error);
    
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
            pk_types.open_my_cursor(o_protocol_gender);
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
    * @since                                   2009/03/03
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
    
        l_result := pk_protocol.get_language_list(i_lang, i_prof, o_languages, o_error);
    
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
    * get multichoice for protocol types
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_type              cursor with all protocol types
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_type_list
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_protocol   IN protocol.id_protocol%TYPE,
        o_protocol_type OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL TYPES LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_type_list(i_lang, i_prof, i_id_protocol, o_protocol_type, o_error);
    
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
                                              'GET_PROTOCOL_TYPE_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_type);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_type_list;

    /********************************************************************************************
    * get multichoice for environment
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_environment       cursor with all environment availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION get_protocol_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_environment  OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL ENVIRONMENT LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_environment_list(i_lang,
                                                              profissional(NULL, i_target_id_institution, NULL),
                                                              i_id_protocol,
                                                              o_protocol_environment,
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
                                              'GET_PROTOCOL_ENVIRONMENT_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_environment);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_environment_list;

    /********************************************************************************************
    * get multichoice for professional
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol
    * @param      o_protocol_professional      cursor with all professional categories availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL PROFESSIONAL LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_prof_list(i_lang, i_prof, i_id_protocol, o_protocol_professional, o_error);
    
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
                                              'GET_PROTOCOL_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_prof_list;

    /********************************************************************************************
    * get multichoice for ebm (evidence based medicine)
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol         
    * @param      o_protocol_ebm               cursor with all ebm values availables
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_ebm_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_protocol  IN protocol.id_protocol%TYPE,
        o_protocol_ebm OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL EBM LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_ebm_list(i_lang, i_prof, i_id_protocol, o_protocol_ebm, o_error);
    
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
                                              'GET_PROTOCOL_EBM_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_ebm);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_ebm_list;

    /********************************************************************************************
    * get multichoice for type of media
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      o_protocol_tm                cursor with all types of media
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_type_media_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_protocol_tm OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET TYPES OF MEDIA LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_type_media_list(i_lang, i_prof, o_protocol_tm, o_error);
    
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
            pk_types.open_my_cursor(o_protocol_tm);
            -- return failure of function
            RETURN FALSE;
        
    END get_type_media_list;

    /********************************************************************************************
    * get multichoice for professionals that will be able to edit protocols
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                id of the protocol        
    * @param      o_protocol_professional      cursor with all professional categories availables
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_edit_prof_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_professional OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL PROFESSIONALS EDIT LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_edit_prof_list(i_lang,
                                                            i_prof,
                                                            i_id_protocol,
                                                            o_protocol_professional,
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
                                              'GET_PROTOCOL_EDIT_PROF_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_professional);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_edit_prof_list;

    /********************************************************************************************
    * get multichoice for types of protocol recommendation
    *
    * @param      i_lang                  preferred language id for this professional
    * @param      i_prof                  object (id of professional, id of institution, id of software)
    * @param      o_protocol_rec_mode     cursor with types of recommendation
    * @param      o_error                 error message
    *
    * @return     boolean                 true or false on success or error
    *
    * @author                             Carlos Loureiro
    * @version                            1.0
    * @since                              2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_type_rec_list
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        o_protocol_type_rec OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET TYPES OF RECOMMENDATION LIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_type_rec_list(i_lang, i_prof, o_protocol_type_rec, o_error);
    
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
                                              'GET_PROTOCOL_TYPE_REC_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_type_rec);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_type_rec_list;

    /********************************************************************************************
    * get protocol criteria
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      i_criteria_type              criteria type: inclusion / exclusion
    * @param      o_protocol_criteria          cursor for protocol criteria
    * @param      o_error                      error
    *
    * @value      i_criteria_type              {*} I inclusion {*} E exclusion
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_criteria
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        i_criteria_type         IN protocol_criteria.criteria_type%TYPE,
        o_protocol_criteria     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_prot_sw protocol.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use protocol software id as input for calling the next function
        SELECT prot.id_software
          INTO l_prot_sw
          FROM protocol prot
         WHERE prot.id_protocol = i_id_protocol;
    
        g_error := 'GET PROTOCOL CRITERIA';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_criteria(i_lang,
                                                      profissional(NULL, i_target_id_institution, l_prot_sw),
                                                      i_id_protocol,
                                                      i_criteria_type,
                                                      o_protocol_criteria,
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
                                              'GET_PROTOCOL_CRITERIA',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_criteria);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_criteria;

    /********************************************************************************************
    * get protocol context
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_context           cursor for protocol context
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_context
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_context      OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_prot_sw protocol.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use protocol software id as input for calling the next function
        SELECT prot.id_software
          INTO l_prot_sw
          FROM protocol prot
         WHERE prot.id_protocol = i_id_protocol;
    
        g_error := 'GET PROTOCOL CONTEXT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_context(i_lang,
                                                     profissional(NULL, i_target_id_institution, l_prot_sw),
                                                     i_id_protocol,
                                                     o_protocol_context,
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
                                              'GET_PROTOCOL_CONTEXT',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_context);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_context;

    /********************************************************************************************
    * get list of images for a specific protocol
    *
    * @param      i_lang                        preferred language id for this professional
    * @param      i_prof                        object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution       target institution id
    * @param      i_id_protocol_context_image   id of protocol image
    * @param      i_id_protocol                 id of protocol
    * @param      o_context_images              images
    * @param      o_error                       error message
    *
    * @return     boolean                       true or false on success or error
    *
    * @author                                   Carlos Loureiro
    * @version                                  1.0
    * @since                                    2009/03/03
    ********************************************************************************************/
    FUNCTION get_context_images
    (
        i_lang                      IN NUMBER,
        i_prof                      IN profissional,
        i_target_id_institution     IN institution.id_institution%TYPE,
        i_id_protocol_context_image IN protocol_context_image.id_protocol_context_image%TYPE,
        i_id_protocol               IN protocol_context_image.id_protocol%TYPE,
        o_context_images            OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result  BOOLEAN;
        l_prot_sw protocol.id_software%TYPE;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        -- use protocol software id as input for calling the next function
        SELECT prot.id_software
          INTO l_prot_sw
          FROM protocol prot
         WHERE prot.id_protocol = i_id_protocol;
    
        g_error := 'GET CONTEXT IMAGES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol_attach.get_context_images(i_lang,
                                                          profissional(NULL, i_target_id_institution, l_prot_sw),
                                                          i_id_protocol_context_image,
                                                          i_id_protocol,
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
    * @param      i_id_protocol               id of the protocol
    * @param      o_protocol_specialty        cursor with all specialty available
    * @param      o_error                     error
    *
    * @return     boolean                     true or false on success or error
    *
    * @author                                 Carlos Loureiro
    * @version                                1.0
    * @since                                  2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_specialty_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        o_protocol_specialty    OUT pk_types.cursor_type,
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
        IF (get_protocols_software_list(i_lang, i_prof, i_target_id_institution, l_cursor_sw_list, o_error))
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
                l_result := pk_protocol.get_protocol_specialty_list(i_lang,
                                                                    profissional(NULL,
                                                                                 i_target_id_institution,
                                                                                 pk_alert_constant.g_soft_primary_care),
                                                                    i_id_protocol,
                                                                    o_protocol_specialty,
                                                                    o_error);
            ELSE
                l_result := pk_protocol.get_protocol_specialty_list(i_lang,
                                                                    profissional(NULL,
                                                                                 i_target_id_institution,
                                                                                 pk_protocol.g_all_software),
                                                                    i_id_protocol,
                                                                    o_protocol_specialty,
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
                                              'GET_PROTOCOL_SPECIALTY_LIST',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_specialty);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_specialty_list;

    /********************************************************************************************
    * set specific protocol main attributes
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_target_id_institution      target institution id
    * @param      i_id_protocol                protocol id
    * @param      i_protocol_desc              protocol description       
    * @param      i_id_protocol_type           protocol type id list
    * @param      i_link_environment           protocol environment link list
    * @param      i_link_specialty             protocol specialty link list
    * @param      i_link_professional          protocol professional link list
    * @param      i_link_edit_prof             protocol edit professional link list
    * @param      i_type_recommendation        protocol type of recommendation
    * @param      o_id_protocol                protocol id associated with the new version
    * @param      o_error                      error message
    *
    * @value      i_type_recommendation        sys_domain where code_domain='PROTOCOL.FLG_TYPE_RECOMMENDATION'
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/04
    ********************************************************************************************/
    FUNCTION set_protocol_main
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        i_id_protocol           IN protocol.id_protocol%TYPE,
        i_protocol_desc         IN protocol.protocol_desc%TYPE,
        i_link_type             IN table_number,
        i_link_environment      IN table_number,
        i_link_specialty        IN table_number,
        i_link_professional     IN table_number,
        i_link_edit_prof        IN table_number,
        i_type_recommendation   IN protocol.flg_type_recommendation%TYPE,
        o_id_protocol           OUT protocol.id_protocol%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
        l_prot_sw protocol.id_software%TYPE;
    
        e_create_protoc_error EXCEPTION;
        e_set_prot_main_error EXCEPTION;
        e_set_protocol_error  EXCEPTION;
    
    BEGIN
    
        -- use protocol software id as input for calling the next function
        SELECT prot.id_software
          INTO l_prot_sw
          FROM protocol prot
         WHERE prot.id_protocol = i_id_protocol;
    
        -- creating new version protocol based on input protocol id   
        g_error := 'CREATING NEW PROTOCOL VERSION';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.create_protocol(i_lang,
                                                profissional(i_prof.id, i_target_id_institution, l_prot_sw),
                                                i_id_protocol,
                                                g_new_version_flag,
                                                o_id_protocol,
                                                o_error);
    
        IF l_result = TRUE
        THEN
            -- setting new attributes to the new version of the protocol   
            g_error := 'SET PROTOCOL MAIN';
            pk_alertlog.log_debug(g_error, g_log_object_name);
        
            l_result := pk_protocol.set_protocol_main(i_lang,
                                                      i_prof,
                                                      o_id_protocol,
                                                      i_protocol_desc,
                                                      i_link_type,
                                                      i_link_environment,
                                                      i_link_specialty,
                                                      i_link_professional,
                                                      i_link_edit_prof,
                                                      i_type_recommendation,
                                                      o_error);
        
            IF l_result = TRUE
            THEN
                -- finalize protocol
                g_error := 'SET PROTOCOL';
                pk_alertlog.log_debug(g_error, g_log_object_name);
            
                l_result := pk_protocol.set_protocol(i_lang, i_prof, o_id_protocol, o_error);
            
                IF l_result = FALSE
                THEN
                    RAISE e_set_protocol_error;
                END IF;
            
            ELSE
                RAISE e_set_prot_main_error;
            END IF;
        ELSE
            RAISE e_create_protoc_error;
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
                                              'SET_PROTOCOL_MAIN',
                                              o_error);
            -- undo changes (rollback)
            pk_utils.undo_changes;
            -- return failure of function
            RETURN FALSE;
        
    END set_protocol_main;

    /********************************************************************************************
    * get available protocol items to be shown
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
    * @since                                    2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_items
    (
        i_lang                  IN NUMBER,
        i_prof                  IN profissional,
        i_target_id_institution IN institution.id_institution%TYPE,
        o_items                 OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL ITEMS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN o_items FOR
            SELECT DISTINCT item, flg_item_type
              FROM (SELECT item,
                           flg_item_type,
                           first_value(pisi.flg_available) over(PARTITION BY pisi.item, pisi.flg_item_type ORDER BY(pisi.id_software + pisi.id_institution) DESC, pisi.flg_available) AS flg_avail
                      FROM protocol_item_soft_inst pisi
                     WHERE pisi.id_institution IN (pk_protocol.g_all_institution, i_target_id_institution)) prot_item
             WHERE flg_avail = pk_protocol.g_available
               AND ((prot_item.flg_item_type = pk_protocol.g_protocol_item_criteria AND
                   prot_item.item NOT IN (SELECT id_protocol_criteria_type
                                              FROM protocol_criteria_type)) OR
                   prot_item.flg_item_type = pk_protocol.g_protocol_item_tasks);
    
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
                                              'GET_PROTOCOL_ITEMS',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_items);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_items;

    /********************************************************************************************
    * get protocol diagram structure
    *
    * @param      i_lang                       prefered language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_protocol                protocol id
    * @param      o_protocol_elements          cursor for protocol elements
    * @param      o_protocol_details           cursor for protocol elements details as tasks
    * @param      o_protocol_relation          cursor for protocol relations    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/03
    ********************************************************************************************/
    FUNCTION get_protocol_diagram
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_protocol              IN protocol.id_protocol%TYPE,
        o_protocol_elements        OUT pk_types.cursor_type,
        o_protocol_element_details OUT pk_types.cursor_type,
        o_protocol_relations       OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_result BOOLEAN;
    
        e_undefined_error EXCEPTION;
    
    BEGIN
    
        g_error := 'GET PROTOCOL STRUCTURE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        l_result := pk_protocol.get_protocol_structure(i_lang,
                                                       i_prof,
                                                       i_id_protocol,
                                                       o_protocol_elements,
                                                       o_protocol_element_details,
                                                       o_protocol_relations,
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
                                              'GET_PROTOCOL_DIAGRAM',
                                              o_error);
            -- open cursors for java                
            pk_types.open_my_cursor(o_protocol_elements);
            pk_types.open_my_cursor(o_protocol_element_details);
            pk_types.open_my_cursor(o_protocol_relations);
            -- return failure of function
            RETURN FALSE;
        
    END get_protocol_diagram;

    /********************************************************************************************
    * get protocol missing flag status for backoffice use (internal use only)
    *
    * @param      i_id_protocol                protocol id
    * @param      i_target_id_institution      target institution id
    * @param      i_sw_list                    list of allowed softwares  
    *
    * @return     varchar2                     backoffice missing flag status
    *
    * @author                                  Carlos Loureiro
    * @version                                 1.0
    * @since                                   2009/03/05
    ********************************************************************************************/
    FUNCTION get_protocol_bo_status
    (
        i_id_protocol           IN protocol.id_protocol%TYPE,
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
                l_sw_id := pk_protocol.g_all_software;
        END;
    
        -- validate if configured SWs are available in target institution 
        -- (greater than zero means that some configured SW's are not present in institiution)
        SELECT COUNT(sd.id_software)
          INTO l_result
          FROM protocol_link pl
         INNER JOIN software_dept sd
            ON sd.id_software_dept = pl.id_link
         WHERE pl.id_protocol = i_id_protocol
           AND pl.link_type = pk_protocol.g_protocol_link_envi
           AND sd.id_software NOT IN (SELECT column_value
                                        FROM TABLE(i_sw_list));
    
        IF l_result = 0
        THEN
            IF l_sw_id = pk_alert_constant.g_soft_primary_care
            THEN
                -- check if protocol's clinical services exists in target institution
                SELECT COUNT(cs.id_clinical_service)
                  INTO l_result
                  FROM protocol_link pl
                 INNER JOIN clinical_service cs
                    ON pl.id_link = cs.id_clinical_service
                 WHERE pl.id_protocol = i_id_protocol
                   AND pl.link_type = pk_protocol.g_protocol_link_spec
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
                -- check if protocol's assigned specialities exists in target institution
                SELECT COUNT(s.id_speciality)
                  INTO l_result
                  FROM protocol_link pl
                 INNER JOIN speciality s
                    ON pl.id_link = s.id_speciality
                 WHERE pl.id_protocol = i_id_protocol
                   AND pl.link_type = pk_protocol.g_protocol_link_spec
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
    
    END get_protocol_bo_status;

    /********************************************************************************************
    * clear particular protocol processes or clear all protocols processes related with
    * a list of patients or protocols
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_patients                patients array
    * @param       i_protocols               protocols array    
    * @param       i_protocol_processes      protocol processes array         
    * @param       o_error                   error message
    *        
    * @return      boolean                   true on success, otherwise false    
    *   
    * @author                                Tiago Silva
    * @since                                 2010/11/02
    ********************************************************************************************/
    FUNCTION clear_protocol_processes
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patients           IN table_number DEFAULT NULL,
        i_protocols          IN table_number DEFAULT NULL,
        i_protocol_processes IN table_number DEFAULT NULL,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_prot IS
            SELECT gp.id_protocol_process
              FROM protocol_process gp
             WHERE gp.id_patient IN (SELECT /*+ OPT_ESTIMATE(table pat rows = 1)*/
                                      column_value AS VALUE
                                       FROM TABLE(i_patients) pat)
                OR gp.id_protocol IN (SELECT /*+ OPT_ESTIMATE(table prots rows = 1)*/
                                       column_value AS VALUE
                                        FROM TABLE(i_protocols) prots)
                OR gp.id_protocol_process IN (SELECT /*+ OPT_ESTIMATE(table prot_procs rows = 1)*/
                                               column_value AS VALUE
                                                FROM TABLE(i_protocol_processes) prot_procs);
    
        l_protocol_processes table_number;
    BEGIN
    
        g_error := 'CLEAR PROTOCOL PROCESSES';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        g_error := 'GET ALL PROTOCOL PROCESSES TO REMOVE';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        OPEN c_prot;
        FETCH c_prot BULK COLLECT
            INTO l_protocol_processes;
        CLOSE c_prot;
    
        g_error := 'DEL PROTOCOL_PROCESS_ELEMENT_HIST';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_protocol_processes.last
            DELETE protocol_process_element_hist ppeh
             WHERE ppeh.id_protocol_process_elem IN
                   (SELECT ppe.id_protocol_process_elem
                      FROM protocol_process_element ppe
                     WHERE ppe.id_protocol_process = l_protocol_processes(i));
    
        g_error := 'DEL PROTOCOL_PROCESS_TASK_DET';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_protocol_processes.last
            DELETE protocol_process_task_det pptd
             WHERE pptd.id_protocol_process_elem IN
                   (SELECT ppe.id_protocol_process_elem
                      FROM protocol_process_element ppe
                     WHERE ppe.id_protocol_process = l_protocol_processes(i));
    
        g_error := 'DEL PROTOCOL_PROCESS_ELEMENT';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_protocol_processes.last
            DELETE FROM protocol_process_element ppe
             WHERE ppe.id_protocol_process = l_protocol_processes(i);
    
        g_error := 'DEL PROTOCOL_PROCESS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        FORALL i IN 1 .. l_protocol_processes.last
            DELETE FROM protocol_process pp
             WHERE pp.id_protocol_process = l_protocol_processes(i);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'CLEAR_PROTOCOL_PROCESSES',
                                              o_error);
            RETURN FALSE;
    END clear_protocol_processes;

    /********************************************************************************************
    * delete a list of protocols and its processes
    *
    * @param       i_lang        preferred language id for this professional
    * @param       i_prof        professional id structure
    * @param       i_protocols   protocol IDs
    * @param       o_error       error message
    *        
    * @return      boolean       true on success, otherwise false    
    *   
    * @author                    Tiago Silva
    * @since                     2010/11/02
    ********************************************************************************************/
    FUNCTION delete_protocols
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_protocols IN table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'DELETE PROTOCOLS';
        pk_alertlog.log_debug(g_error, g_log_object_name);
    
        -- deprecate protocols (protocols shouldn't be deleted)
        UPDATE protocol
           SET flg_status = pk_protocol.g_protocol_deprecated
         WHERE id_protocol IN (SELECT /*+ OPT_ESTIMATE(table prots rows = 1)*/
                                column_value AS VALUE
                                 FROM TABLE(i_protocols) prots);
    
        -- clear all protocols processes related with these protocols
        IF NOT
            clear_protocol_processes(i_lang => i_lang, i_prof => i_prof, i_protocols => i_protocols, o_error => o_error)
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
                                              'DELETE_PROTOCOLS',
                                              o_error);
            RETURN FALSE;
    END delete_protocols;

    /********************************************************************************************
    * get protocol process details for a given patient
    * API for REPORTS
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      o_protocol_process           cursor with protocol process main information / context
    * @param      o_error                      error
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   12-Mar-2011
    ********************************************************************************************/
    FUNCTION get_protocol_process_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_patient          IN protocol_process.id_patient%TYPE,
        o_protocol_process OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_exception EXCEPTION;
    BEGIN
        g_error := 'update protocol processes and associated tasks';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        IF (NOT pk_protocol.update_all_prot_proc_status(i_lang, i_prof, i_patient, o_error))
        THEN
            RAISE l_exception;
        END IF;
        COMMIT;
    
        g_error := 'process o_protocol_process cursor';
        pk_alertlog.log_debug(g_error, g_log_object_name);
        OPEN o_protocol_process FOR
            SELECT p.id_protocol,
                   pp.id_protocol_process,
                   pp.flg_status,
                   pk_protocol.get_link_id_str(i_lang,
                                               i_prof,
                                               p.id_protocol,
                                               pk_protocol.g_protocol_link_pathol,
                                               pk_protocol.g_separator) AS desc_pathology,
                   p.protocol_desc AS protocol_title,
                   pk_protocol.get_link_id_str(i_lang,
                                               i_prof,
                                               p.id_protocol,
                                               pk_protocol.g_protocol_link_type,
                                               pk_protocol.g_separator) type_desc,
                   pk_translation.get_translation(i_lang, ebm.code_ebm) AS desc_ebm,
                   pk_sysdomain.get_domain(pk_protocol.g_domain_flg_protocol, pp.flg_status, i_lang) AS desc_status,
                   pk_tools.get_prof_description(i_lang,
                                                 i_prof,
                                                 pp.id_professional,
                                                 pb.dt_protocol_batch,
                                                 pp.id_episode) AS request_author_desc,
                   pk_date_utils.date_send_tsz(i_lang, pb.dt_protocol_batch, i_prof) request_date_raw,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, pb.dt_protocol_batch, i_prof.institution, i_prof.software) request_date,
                   decode(pb.batch_type, g_batch_1p_1g, pk_protocol.g_no, pk_protocol.g_yes) AS flg_auto_recommendation,
                   decode(pp.flg_status,
                          pk_protocol.g_process_canceled,
                          pk_prof_utils.get_name_signature(i_lang, i_prof, pp.id_prof_cancel),
                          NULL) AS prof_cancel,
                   decode(pp.flg_status,
                          pk_protocol.g_process_canceled,
                          pk_prof_utils.get_prof_speciality(i_lang,
                                                            profissional(pp.id_prof_cancel,
                                                                         i_prof.institution,
                                                                         i_prof.software)),
                          NULL) prof_spec_cancel,
                   nvl2(pp.id_cancel_reason,
                        pk_translation.get_translation(i_lang,
                                                       'CANCEL_REASON.CODE_CANCEL_REASON.' || pp.id_cancel_reason),
                        NULL) AS cancel_reason,
                   pp.cancel_notes,
                   decode(pp.flg_status,
                          pk_protocol.g_process_canceled,
                          pk_date_utils.date_send_tsz(i_lang, pp.dt_status, i_prof),
                          NULL) AS cancel_date_raw,
                   decode(pp.flg_status,
                          pk_protocol.g_process_canceled,
                          pk_date_utils.dt_chr_date_hour_tsz(i_lang, pp.dt_status, i_prof.institution, i_prof.software),
                          NULL) AS cancel_date
              FROM protocol p
              JOIN protocol_process pp
                ON p.id_protocol = pp.id_protocol
               AND pp.flg_nested_protocol = pk_protocol.g_not_nested_protocol
              JOIN protocol_batch pb
                ON pb.id_protocol_batch = pp.id_protocol_batch
              LEFT JOIN ebm
                ON p.id_ebm = ebm.id_ebm
             WHERE pp.id_patient = i_patient;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_log_object_owner,
                                              g_log_object_name,
                                              'GET_PROTOCOL_PROCESS_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_protocol_process);
            RETURN FALSE;
    END get_protocol_process_detail;

BEGIN

    -- Logging mechanism
    pk_alertlog.who_am_i(g_log_object_owner, g_log_object_name);
    pk_alertlog.log_init(g_log_object_name);

END pk_api_protocol;
/
