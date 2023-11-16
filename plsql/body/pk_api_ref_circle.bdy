/*-- Last Change Revision: $Rev: 1054688 $*/
/*-- Last Change by: $Author: ana.monteiro $*/
/*-- Date of last change: $Date: 2011-07-20 09:39:32 +0100 (qua, 20 jul 2011) $*/
CREATE OR REPLACE PACKAGE BODY pk_api_ref_circle IS

    /**
    * Associates an ORIS/INP episode to an INP/ORIS or OUTP/Exam Referral type
    * Used by ORIS/INP
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_ref                Referral identifier
    * @param   i_episode            Episode identifier
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    */
    FUNCTION set_ref_map_episode
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_ref     IN p1_external_request.id_external_request%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_ref_map OUT ref_map.id_ref_map%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_ref_map(x_epis IN ref_map.id_episode%TYPE) IS
            SELECT r.*
              FROM ref_map r
             WHERE r.flg_status = pk_ref_constant.g_active
               AND r.id_episode IN (SELECT id_episode
                                      FROM episode e
                                     WHERE id_visit = (SELECT id_visit
                                                         FROM episode
                                                        WHERE id_episode = x_epis));
    
        TYPE t_ref_map IS TABLE OF c_ref_map%ROWTYPE;
        l_ref_map_tab    t_ref_map;
        l_module         sys_config.value%TYPE;
        l_insert_episode PLS_INTEGER;
    BEGIN
        -- Notes:
        -- the same referral can be associated to episodes that belong to different visits
        -- the same episode cannot be associated to different referrals
    
        g_error := 'Init SET_REF_MAP_EPISODE / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
        l_insert_episode := 1; -- assuming that we have to insert ID_EPISODE into ref_map
    
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        g_error := 'MODULE =' || l_module;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                -- this is the circle algorithm:
                --
                --  getting all REF_MAP episodes that belong to visit related to id_episode               
                --  -- ID_EPISODE not found in REF_MAP (insert)
                --    -- inserting record into REF_MAP (id_schedule is null)
                --  
                --  -- ID_EPISODE found in REF_MAP (UPDATE)
                --    
                --    -- for each record of REF_MAP
                --      -- cancel REF_MAP record
                --        -- [SKIP] IF id_schedule is not null (skip this step for now!!!)
                --          -- Check if this referral has more entries on REF_MAP that have id_schedule not null
                --            -- If yes, do nothing
                --            -- If no, cancels referral schedule (PK_REF_EXT_SYS.update_referral_status - A)
                --        
                --        -- [SKIP] IF id_schedule is null
                --          -- do nothing
                --      
                --      -- Creates entry on REF_MAP for the new referral and the existing ID_EPISODE
                --
                --        -- [SKIP] IF id_schedule is not null (skip this step for now!!!)
                --          -- Check if this referral has more entries on REF_MAP that have id_schedule not null
                --            -- If yes, do nothing
                --            -- If no, schedules referral to the existing id_schedule (PK_REF_EXT_SYS.update_referral_status - S)        
                --        
                --        -- [SKIP] IF id_schedule is null
                --          -- do nothing
            
                --------------------------
                --  getting all REF_MAP episodes that belong to visit related to id_episode
                g_error := 'OPEN c_ref_map / ID_EPISODE=' || i_episode;
                OPEN c_ref_map(i_episode);
                FETCH c_ref_map BULK COLLECT
                    INTO l_ref_map_tab;
                -- g_found := c_ref_map%FOUND; -- this doesn't work with BULK COLLECT
                CLOSE c_ref_map;
            
                IF l_ref_map_tab IS NULL
                   OR l_ref_map_tab.count = 0
                THEN
                
                    -- ID_EPISODE not found in REF_MAP (insert)
                
                    --------------------------
                    -- inserting record into REF_MAP (id_schedule is null)
                
                    g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode;
                    g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_ref      => i_ref,
                                                          i_id_schedule => NULL,
                                                          i_id_episode  => i_episode,
                                                          o_id_ref_map  => o_ref_map,
                                                          o_error       => o_error);
                
                    IF NOT g_retval
                    THEN
                        g_error := 'Error: ' || g_error;
                        RAISE g_exception_np;
                    END IF;
                
                ELSE
                
                    -- ID_EPISODE found in REF_MAP (UPDATE)
                
                    FOR i IN 1 .. l_ref_map_tab.count
                    LOOP
                    
                        -- for each record of REF_MAP
                    
                        --------------------------
                        -- cancel REF_MAP record
                        g_error := 'Call PK_REF_API.cancel_ref_map / ID_REF=' || l_ref_map_tab(i).id_external_request ||
                                   ' ID_SCHEDULE=' || l_ref_map_tab(i).id_schedule || ' ID_EPISODE=' || l_ref_map_tab(i)
                                  .id_episode || ' FLG_STATUS=' || l_ref_map_tab(i).flg_status;
                        pk_alertlog.log_debug(g_error);
                        g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_ref_map_row => l_ref_map_tab(i),
                                                              o_error       => o_error);
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                        g_error := 'ID_REF=' || l_ref_map_tab(i).id_external_request || ' ID_EPISODE=' || l_ref_map_tab(i)
                                  .id_episode || ' ID_SCHEDULE=' || l_ref_map_tab(i).id_schedule;
                        pk_alertlog.log_debug(g_error);
                    
                        --------------------------
                        -- Creates entry on REF_MAP for the new referral and the existing ID_EPISODE
                        g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || l_ref_map_tab(i)
                                   .id_episode || ' ID_SCHEDULE=' || l_ref_map_tab(i).id_schedule;
                        g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_ref      => i_ref,
                                                              i_id_schedule => l_ref_map_tab(i).id_schedule,
                                                              i_id_episode  => l_ref_map_tab(i).id_episode,
                                                              o_id_ref_map  => o_ref_map,
                                                              o_error       => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                        -- check if the updated record was id_episode=i_episode
                        IF l_ref_map_tab(i).id_episode = i_episode
                        THEN
                        
                            -- found record with id_episode=i_episode, do not have to insert again
                            l_insert_episode := 0;
                        END IF;
                    
                    END LOOP;
                
                    g_error := 'l_insert_episode=' || l_insert_episode;
                    IF l_insert_episode = 1
                    THEN
                    
                        -- i_episode was not registered yet
                        g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode ||
                                    ' ID_SCHEDULE=NULL';
                        g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_ref      => i_ref,
                                                              i_id_schedule => NULL,
                                                              i_id_episode  => i_episode,
                                                              o_id_ref_map  => o_ref_map,
                                                              o_error       => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                
                END IF;
            ELSE
                -- nothing to be done in generic module
                NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAP_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_map_episode;

    /**
    * Associates an ID_EPISODE to a INP/ORIS Referral type
    * Used by ORIS/INP (to associate to an oris/inp episode)
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_ref                Referral identifier
    * @param   i_episode            Episode identifier
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    *
    FUNCTION set_ref_map_episode
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_ref     IN p1_external_request.id_external_request%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_ref_map OUT ref_map.id_ref_map%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        
    
        CURSOR c_ref(x_id_ref IN p1_external_request.id_external_request%TYPE) IS
            SELECT flg_type
              FROM p1_external_Request
             WHERE id_External_Request = x_id_ref;
    
        
    
        l_ref_map_old_row ref_map%ROWTYPE;
        l_ref_map_new_row ref_map%ROWTYPE;
        l_module          sys_config.VALUE%TYPE;        
        l_insert_episode  PLS_INTEGER;
        
        
        
        ------------------------------------
        CURSOR c_ref_map(x_epis IN ref_map.id_episode%TYPE) IS
            SELECT r.*
              FROM ref_map r
             WHERE r.flg_status = pk_ref_constant.g_active
               AND r.id_episode IN (SELECT id_episode
                                      FROM episode e
                                     WHERE id_visit = (SELECT id_visit
                                                         FROM episode
                                                        WHERE id_episode = x_epis));
                                                        
        TYPE t_ref_map IS TABLE OF c_ref_map%ROWTYPE;
        l_ref_map_tab t_ref_map;
        
        CURSOR c_ref_map_epis(x_id_episode IN ref_map.id_schedule%TYPE) IS
            SELECT *
              FROM ref_map
             WHERE id_episode = x_id_episode
               AND flg_status = pk_ref_constant.g_active;
        
        
        l_id_ref_map      ref_map.id_ref_map%TYPE;
        l_ref_map_row ref_map%ROWTYPE;
    BEGIN
        -- Notes:
        -- the same referral can be associated to episodes that belong to different visits
        -- the same episode cannot be associated to different referrals    
        g_error := 'Init SET_REF_MAP_EPISODE / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
                
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        g_error := 'MODULE =' || l_module;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN                            
            
                
                -- association of an INP/ORIS referral type to an INP/ORIS episode
                
                -- check to see if this episode already exists in REF_MAP (if yes, cancels this record)
                g_error := 'OPEN c_ref / ID_REF=' || i_ref;
                OPEN c_ref_map_epis(i_ref);
                FETCH c_ref_map_epis INTO l_ref_map_row;
                g_found := c_ref_map_epis%FOUND;
                CLOSE c_ref_map_epis;
                
                IF g_found THEN
                
                   -- canceling association of this episode to one referral id
                   g_error  := 'Call pk_ref_api.cancel_ref_map / ID_REF=' || l_ref_map_row.id_external_request || ' ID_EPISODE=' || l_ref_map_row.id_episode 
                   ||' ID_SCHEDULE='||l_ref_map_row.id_schedule||' FLG_STATUS='||l_ref_map_row.flg_status;
                    g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_ref_map_row => l_ref_map_row,
                                                          o_error       => o_error);
                
                    IF NOT g_retval
                    THEN
                        g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || l_id_ref_map;
                        RAISE g_exception_np;
                    END IF;
                
                END IF;
                
                -- inserting record into REF_MAP (id_schedule is null)                
                g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode;
                g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_ref      => i_ref,
                                                      i_id_schedule => NULL,
                                                      i_id_episode  => i_episode,
                                                      o_id_ref_map  => l_id_ref_map,
                                                      o_error       => o_error);
                
                IF NOT g_retval
                THEN
                    g_error := 'Error: ' || g_error;
                    RAISE g_exception_np;
                END IF;     
                
                
                
                
                
                
                
                
                --------------------------
                --  getting all REF_MAP episodes that belong to visit related to id_episode
                g_error := 'OPEN c_ref_map / ID_EPISODE=' || i_episode;
                OPEN c_ref_map(i_episode);
                FETCH c_ref_map BULK COLLECT
                    INTO l_ref_map_tab;
                CLOSE c_ref_map;
            
                IF l_ref_map_tab IS NULL
                   OR l_ref_map_tab.COUNT = 0
                THEN
                
                    -- ID_EPISODE not found in REF_MAP (insert)
                
                    --------------------------
                    -- inserting record into REF_MAP (id_schedule is null)
                
                    g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode;
                    g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                          i_prof        => i_prof,
                                                          i_id_ref      => i_ref,
                                                          i_id_schedule => NULL,
                                                          i_id_episode  => i_episode,
                                                          o_id_ref_map  => l_id_ref_map,
                                                          o_error       => o_error);
                
                    IF NOT g_retval
                    THEN
                        g_error := 'Error: ' || g_error;
                        RAISE g_exception_np;
                    END IF;
                
                ELSE
                
                    -- ID_EPISODE found in REF_MAP (UPDATE)
                
                    FOR i IN 1 .. l_ref_map_tab.COUNT
                    LOOP
                    
                        -- for each record of REF_MAP
                    
                        --------------------------
                        -- cancel REF_MAP record
                        g_error := 'Call PK_REF_API.cancel_ref_map / ID_REF=' || l_ref_map_tab(i)
                                  .id_external_request || ' ID_SCHEUDLE=' || l_ref_map_tab(i)
                                  .id_schedule || ' ID_EPISODE=' || l_ref_map_tab(i)
                                  .id_episode || ' FLG_STATUS=' || l_ref_map_tab(i).flg_status;
                        pk_alertlog.log_debug(g_error);
                        g_retval := pk_ref_api.cancel_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_ref_map_row => l_ref_map_tab(i),
                                                              o_error       => o_error);
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                        g_error := 'ID_REF=' || l_ref_map_tab(i)
                                  .id_external_request || ' ID_EPISODE=' || l_ref_map_tab(i)
                                  .id_episode || ' ID_SCHEDULE=' || l_ref_map_tab(i).id_schedule;
                        pk_alertlog.log_debug(g_error);
                    
                        --------------------------
                        -- Creates entry on REF_MAP for the new referral and the existing ID_EPISODE
                        g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' ||
                                    l_ref_map_tab(i).id_episode || ' ID_SCHEDULE=' || l_ref_map_tab(i).id_schedule;
                        g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_ref      => i_ref,
                                                              i_id_schedule => l_ref_map_tab(i).id_schedule,
                                                              i_id_episode  => l_ref_map_tab(i).id_episode,
                                                              o_id_ref_map  => l_id_ref_map,
                                                              o_error       => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                        -- check if the updated record was id_episode=i_episode
                        IF l_ref_map_tab(i).id_episode = i_episode
                        THEN
                        
                            -- found record with id_episode=i_episode, do not have to insert again
                            l_insert_episode := 0;
                        END IF;
                    
                    END LOOP;
                
                    g_error := 'l_insert_episode=' || l_insert_episode;
                    IF l_insert_episode = 1
                    THEN
                    
                        -- i_episode was not registered yet
                        g_error  := 'Call PK_REF_API.create_ref_map / ID_REF=' || i_ref || ' ID_EPISODE=' || i_episode ||
                                    ' ID_SCHEDULE=NULL';
                        g_retval := pk_ref_api.create_ref_map(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_id_ref      => i_ref,
                                                              i_id_schedule => NULL,
                                                              i_id_episode  => i_episode,
                                                              o_id_ref_map  => l_id_ref_map,
                                                              o_error       => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    END IF;
                
                END IF;
            ELSE
                -- nothing to be done in generic module
                NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
    
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAP_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
    END set_ref_map_episode;
    
    /*    
    * Associates an OUTP/Exam episode to an Exam/OUTP Referral type
    * Used by OUTP/Exam
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_schedule           Schedule identifier
    * @param   i_episode            Episode identifier
    * @param   o_visit              Visit  identifier
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    *
    FUNCTION set_ref_map_from_episode
    (
        i_lang     IN LANGUAGE.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_visit    OUT visit.id_visit%TYPE,
        o_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur_ref_map IS
            SELECT *
              FROM ref_map
             WHERE id_schedule = i_schedule
               AND flg_status = pk_ref_constant.g_active;
    
        l_ref_map_row ref_map%ROWTYPE;
        l_module      sys_config.VALUE%TYPE; -- specifies referral module
    BEGIN
    
        g_error := 'Init SET_REF_MAP_FROM_EPISODE / ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
    
        g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
        l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
    
        g_error := 'MODULE =' || l_module;
        CASE l_module
            WHEN pk_ref_constant.g_sc_ref_module_circle THEN
            
                g_error := 'OPEN c_cur_ref_map / ID_SCHEDULE=' || i_schedule;
                OPEN c_cur_ref_map;
                FETCH c_cur_ref_map
                    INTO l_ref_map_row;
                g_found := c_cur_ref_map%FOUND;
                CLOSE c_cur_ref_map;
            
                g_error := 'IF NOT FOUND 2';
                IF NOT g_found
                THEN
                    g_error := 'REF_MAP NOT FOUND / ID_SCHEDULE=' || i_schedule;
                    RAISE g_exception;
                END IF;
            
                g_error                  := 'l_ref_map_row';
                l_ref_map_row.id_episode := i_episode;
            
                g_error := 'Call pk_ref_api.set_ref_map / ID_EXT_REQ=' || l_ref_map_row.id_external_request ||
                           ' ID_SCHEUDLE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' || l_ref_map_row.id_episode ||
                           ' ID_REF_MAP=' || l_ref_map_row.id_ref_map;
                pk_alertlog.log_debug(g_error);
                g_retval := pk_ref_api.set_ref_map(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_ref_map    => l_ref_map_row,
                                                   o_id_ref_map => o_ref_map,
                                                   o_error      => o_error);
            
                IF NOT g_retval
                THEN
                
                    g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || o_ref_map;
                    RAISE g_exception_np;
                END IF;
            ELSE
                -- nothing to be done in generic module
                NULL;
        END CASE;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAP_FROM_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_ref_map_from_episode;
    
    /*    
    * Associates an OUTP/Exam episode to an Exam/OUTP or INP/ORIS Referral type
    * Used by OUTP/Exam
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_schedule           Schedule identifier
    * @param   i_episode            Episode identifier
    * @param   o_visit              Visit  identifier. Not used.
    * @param   o_ref_map            The association identifier created
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   02-11-2009
    */
    FUNCTION set_ref_map_from_episode
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_schedule IN schedule.id_schedule%TYPE,
        i_episode  IN episode.id_episode%TYPE,
        o_visit    OUT visit.id_visit%TYPE,
        o_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_cur_ref_map IS
            SELECT *
              FROM ref_map
             WHERE id_schedule = i_schedule
               AND flg_status = pk_ref_constant.g_active;
    
        l_ref_map_row         ref_map%ROWTYPE;
        l_module              sys_config.value%TYPE; -- specifies referral module
        l_scheduler_installed sys_config.value%TYPE;
        l_id_ref              p1_external_request.id_external_request%TYPE;
    
        CURSOR c_ref IS
            SELECT id_external_request
              FROM p1_external_request
             WHERE id_schedule = i_schedule;
    BEGIN
    
        g_error := 'Init SET_REF_MAP_FROM_EPISODE / ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
        pk_alertlog.log_debug(g_error);
    
        IF i_schedule IS NOT NULL
        THEN
        
            g_error  := 'Call pk_sysconfig.get_config SYS_CONFIG=' || pk_ref_constant.g_sc_ref_module;
            l_module := pk_sysconfig.get_config(pk_ref_constant.g_sc_ref_module, i_prof);
        
            g_error := 'MODULE =' || l_module;
            CASE l_module
                WHEN pk_ref_constant.g_sc_ref_module_circle THEN
                
                    g_error := 'CIRCLE MODULE / ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
                    pk_alertlog.log_debug(g_error);
                
                    g_error := 'OPEN c_cur_ref_map / ID_SCHEDULE=' || i_schedule;
                    OPEN c_cur_ref_map;
                    FETCH c_cur_ref_map
                        INTO l_ref_map_row;
                    g_found := c_cur_ref_map%FOUND;
                    CLOSE c_cur_ref_map;
                
                    g_error := 'IF NOT FOUND 2';
                    IF NOT g_found
                    THEN
                    
                        -- ACM, 2010-01-25: ALERT-70196 
                        -- this schedule is not associated to any referral
                        -- do not return error in this case, otherwise exams cannot be registered
                        g_error := 'REF_MAP NOT FOUND / ID_SCHEDULE=' || i_schedule;
                        pk_alertlog.log_debug(g_error);
                        --RAISE g_exception;
                    ELSE
                    
                        IF l_ref_map_row.id_episode IS NOT NULL
                        THEN
                            -- ID_EPISODE is not null, this cannot happen: return error
                            g_error := 'ID_EPISODE IS NOT NULL for REF_MAP record / ID_REF_MAP=' ||
                                       l_ref_map_row.id_ref_map || ' ID_REF=' || l_ref_map_row.id_external_request ||
                                       ' ID_EPISODE=' || l_ref_map_row.id_episode || ' ID_SCHEDULE=' ||
                                       l_ref_map_row.id_schedule;
                            RAISE g_exception;
                        END IF;
                    
                        g_error                  := 'l_ref_map_row';
                        l_ref_map_row.id_episode := i_episode;
                    
                        g_error := 'Call pk_ref_api.set_ref_map / ID_EXT_REQ=' || l_ref_map_row.id_external_request ||
                                   ' ID_SCHEUDLE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' ||
                                   l_ref_map_row.id_episode || ' ID_REF_MAP=' || l_ref_map_row.id_ref_map;
                        pk_alertlog.log_debug(g_error);
                        g_retval := pk_ref_api.set_ref_map(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_ref_map    => l_ref_map_row,
                                                           o_id_ref_map => o_ref_map,
                                                           o_error      => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'Error: ' || g_error || ' ID_REF_MAP=' || o_ref_map;
                            RAISE g_exception_np;
                        END IF;
                    
                        -- ACM, 2010-01-26: ALERT-69182
                        -- After updating REF_MAP, check if the referral status needs to be changed
                        g_error  := 'Call PK_REF_EXT_SYS.set_ref_efectiv / ID_REF=' ||
                                    l_ref_map_row.id_external_request;
                        g_retval := pk_ref_ext_sys.set_ref_efectiv(i_lang   => i_lang,
                                                                   i_prof   => i_prof,
                                                                   i_id_ref => l_ref_map_row.id_external_request,
                                                                   i_notes  => NULL,
                                                                   --i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                                   o_error => o_error);
                    
                        IF NOT g_retval
                        THEN
                            g_error := 'ERROR: ' || g_error;
                            RAISE g_exception_np;
                        END IF;
                    
                    END IF;
                ELSE
                    -- ACM, 2010-08-06: ALERT-83871 - REFERRAL Integration With OUTPATIENT    
                    -- find referral id (from id_schedule) and associate id_episode
                    g_error := 'GENERIC MODULE / ID_SCHEDULE=' || i_schedule || ' ID_EPISODE=' || i_episode;
                    pk_alertlog.log_debug(g_error);
                
                    g_error               := 'Call pk_sysconfig.get_config SYS_CONFIG=' ||
                                             pk_ref_constant.g_scheduler3_installed;
                    l_scheduler_installed := pk_sysconfig.get_config(pk_ref_constant.g_scheduler3_installed, i_prof);
                
                    g_error := 'OPEN c_ref / ID_SCHEDULE=' || i_schedule;
                    OPEN c_ref;
                    FETCH c_ref
                        INTO l_id_ref;
                    g_found := c_ref%FOUND;
                    CLOSE c_ref;
                
                    IF l_id_ref IS NOT NULL
                    THEN
                    
                        g_error := 'UPDATE p1_external_request SET id_episode=' || i_episode ||
                                   ' WHERE id_external_request=' || l_id_ref;
                        pk_alertlog.log_debug(g_error);
                    
                        UPDATE p1_external_request
                           SET id_episode = i_episode
                         WHERE id_external_request = l_id_ref;
                    
                        g_error := 'l_scheduler_installed=' || l_scheduler_installed;
                        IF l_scheduler_installed = pk_ref_constant.g_yes
                        THEN
                            -- ALERT-188102
                            -- if scheduler is installed, then update referral status (there is no event from SCHEDULER to Referral to
                            -- change referral status)
                            g_error := 'Call pk_Ref_ext_sys.set_ref_efectiv / ID_REF=' || l_id_ref;
                            pk_alertlog.log_debug(g_error);
                            g_retval := pk_ref_ext_sys.set_ref_efectiv(i_lang   => i_lang,
                                                                       i_prof   => i_prof,
                                                                       i_id_ref => l_id_ref,
                                                                       i_notes  => NULL,
                                                                       --i_date   IN p1_tracking.dt_tracking_tstz%TYPE DEFAULT NULL,
                                                                       o_error => o_error);
                        
                            IF NOT g_retval
                            THEN
                                g_error := 'ERROR: ' || g_error;
                                RAISE g_exception_np;
                            END IF;
                        
                        ELSE
                            -- if no scheduler installed, then there will be an event from sonho to Referral, in order to 
                            -- change referral status. Thus, we only need to update ID_EPISODE here.
                            NULL;
                        
                        END IF;
                    
                    END IF;
                
            END CASE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAP_FROM_EPISODE',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            RETURN FALSE;
        
    END set_ref_map_from_episode;

    /**
    * Gets information of episodes related to the referral
    *
    * @param   i_lang               Language associated to the professional 
    * @param   i_prof               Professional, institution and software ids
    * @param   i_id_ref             Referral identifier
    * @param   o_linked_epis        Episodes information
    * @param   o_error              An error message, set when return=false   
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   30-10-2009
    */
    FUNCTION get_linked_episodes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN p1_external_request.id_external_request%TYPE,
        o_linked_epis OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_all_episodes IS
            SELECT e.id_episode
              FROM episode e
             WHERE e.flg_status != pk_alert_constant.g_cancelled
               AND id_visit IN (SELECT id_visit
                                  FROM episode e
                                  JOIN ref_map r
                                    ON (r.id_episode = e.id_episode AND r.flg_status = pk_ref_constant.g_active)
                                 WHERE r.id_external_request = i_id_ref);
    
        l_all_episodes table_number;
    BEGIN
    
        -- all episodes related to id_visit of episodes present in REF_MAP
        g_error := 'Open c_all_episodes / ID_REF=' || i_id_ref;
        OPEN c_all_episodes;
        FETCH c_all_episodes BULK COLLECT
            INTO l_all_episodes;
        CLOSE c_all_episodes;
    
        g_error := 'Open o_linked_epis';
        OPEN o_linked_epis FOR
            SELECT epis.id_episode,
                   decode(ei.id_professional, NULL, ei.id_first_nurse_resp, ei.id_professional) id_professional,
                   pk_ehr_common.get_visit_name_by_epis(i_lang,
                                                        profissional(ei.id_professional,
                                                                     epis.id_institution,
                                                                     ei.id_software),
                                                        epis.id_epis_type) visit_type,
                   pk_ehr_common.get_visit_type_by_epis(i_lang,
                                                        profissional(ei.id_professional,
                                                                     epis.id_institution,
                                                                     ei.id_software),
                                                        epis.id_episode,
                                                        epis.id_epis_type,
                                                        chr(10)) visit_information,
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    decode(ei.id_professional,
                                                           NULL,
                                                           ei.id_first_nurse_resp,
                                                           ei.id_professional)) nick_name,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_begin,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_end_tstz, i_prof.institution, i_prof.software) dt_end,
                   pk_sysconfig.get_config(g_tl_report, i_prof.institution, i_prof.software) id_report
              FROM episode epis
              JOIN epis_info ei
                ON (epis.id_episode = ei.id_episode)
              JOIN TABLE(CAST(l_all_episodes AS table_number)) tt
                ON (tt.column_value = epis.id_episode);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_warn(g_error);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_LINKED_EPISODES',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state();
            pk_types.open_my_cursor(o_linked_epis);
            RETURN FALSE;
    END get_linked_episodes;
BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_api_ref_circle;
/
