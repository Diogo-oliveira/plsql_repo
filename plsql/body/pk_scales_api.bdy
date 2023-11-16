/*-- Last Change Revision: $Rev: 2027651 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:54 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_scales_api IS

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    -- Function and procedure implementations

    /**
    * Rebuild the grid task assessment tools values.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_doc_area                   Doc_area id         
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION rebuild_grid_task
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_doc_area IN doc_area.id_doc_area%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_grid_doc_area sys_config.value%TYPE;
    BEGIN
        g_error := 'REBUILD GRID TASK.';
        pk_alertlog.log_debug(g_error);
        FOR rec IN (SELECT e.id_episode
                      FROM episode e
                    /*JOIN epis_documentation ed
                    ON ed.id_episode = e.id_episode*/
                     WHERE e.id_epis_type = pk_alert_constant.g_epis_type_inpatient
                          --AND ed.id_doc_area = i_doc_area
                       AND e.id_institution = i_prof.institution)
        LOOP
        
            g_error := 'CALL update_scales_task: i_doc_area: ' || i_doc_area || ' i_episode: ' || rec.id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_inp_nurse.update_scales_task(i_lang     => i_lang,
                                                   i_episode  => rec.id_episode,
                                                   i_doc_area => i_doc_area,
                                                   i_prof     => i_prof,
                                                   o_error    => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'REBUILD_GRID_TASK',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END rebuild_grid_task;

    /**
    * Set the doc area of the assessment tool that should appear in the patients grids.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_institution             Institution id
    * @param   i_id_software                Software id
    * @param   i_doc_area                   Doc_area id     
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   21-Jul-2011
    */
    FUNCTION set_grids_area_config
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_grid_doc_area  sys_config.value%TYPE;
        l_count          PLS_INTEGER;
        l_sys_config_row sys_config%ROWTYPE;
    BEGIN
        g_error := 'GET SYS_CONFIG DATA';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT sf.*
              INTO l_sys_config_row
              FROM sys_config sf
             WHERE sf.id_sys_config = pk_scales_constant.g_grids_doc_area_sc
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_sys_config_row.client_configuration   := pk_alert_constant.g_no;
                l_sys_config_row.internal_configuration := pk_alert_constant.g_yes;
                l_sys_config_row.global_configuration   := pk_alert_constant.g_no;
        END;
    
        g_error := 'CALL pk_sysconfig.insert_into_sysconfig. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        pk_sysconfig.insert_into_sysconfig(i_idsysconfig     => pk_scales_constant.g_grids_doc_area_sc,
                                           i_value           => i_doc_area,
                                           i_institution     => i_id_institution,
                                           i_software        => i_id_software,
                                           i_desc            => l_sys_config_row.desc_sys_config,
                                           i_fill_type       => l_sys_config_row.fill_type,
                                           i_client_config   => l_sys_config_row.client_configuration,
                                           i_internal_config => l_sys_config_row.internal_configuration,
                                           i_global_config   => l_sys_config_row.global_configuration,
                                           i_schema          => l_sys_config_row.flg_schema);
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_GRIDS_AREA_CONFIG',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_grids_area_config;

    /**
    * Rebuild the grid task assessment tools values.
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_institution             Institution id     
    * @param   i_id_software                Software id
    * @param   i_doc_area                   Doc_area id
    * @param   o_error                      Error message
    *
    * @return  True or False on success or error
    *
    * @author  Sofia Mendes
    * @version 2.6.1.2
    * @since   08-Jul-2011
    */
    FUNCTION set_grids_assessment_tool
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_doc_area       IN doc_area.id_doc_area%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_grid_doc_area sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL set_grids_area_config. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT set_grids_area_config(i_lang           => i_lang,
                                     i_prof           => i_prof,
                                     i_id_institution => i_id_institution,
                                     i_id_software    => i_id_software,
                                     i_doc_area       => i_doc_area,
                                     o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL rebuild_grid_task. i_doc_area: ' || i_doc_area;
        pk_alertlog.log_debug(g_error);
        IF NOT rebuild_grid_task(i_lang     => i_lang,
                                 i_prof     => profissional(i_prof.id, i_id_institution, i_id_software),
                                 i_doc_area => i_doc_area,
                                 o_error    => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.reset_error_state;
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'SET_GRIDS_ASSESSMENT_TOOL',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_grids_assessment_tool;

    /********************************************************************************************
    * Returns the info registered in the documentation regarding a patient, an episode or an visit.
    * For a patient scope: i_flg_scope = P and i_scope regards to id_patient
    * For a visit scope: i_flg_scope = V and i_scope regards to id_visit
    * For an episode scope: i_flg_scope = E and i_scope regards to id_episode    
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID
    * @param i_episode                the episode ID
    * @param i_scope                  Scope ID (Episode ID; Visit ID; Patient ID)
    * @param i_scope_type             Scope type (by episode; by visit; by patient)
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          06-Jan-2010
    **********************************************************************************************/
    FUNCTION get_scales_list
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2 DEFAULT 'E',
        o_scales_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_scales_core.get_scales_list. i_doc_area: ' || i_doc_area || ' i_scope: ' || i_scope ||
                   ' i_scope_type: ' || i_scope_type;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_scales_list(i_lang        => i_lang,
                                              i_prof        => i_prof,
                                              i_doc_area    => i_doc_area,
                                              i_scope       => i_scope,
                                              i_scope_type  => i_scope_type,
                                              o_scales_list => o_scales_list,
                                              o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_scales_list_pat',
                                              o_error);
            pk_types.open_my_cursor(o_scales_list);
            RETURN FALSE;
    END get_scales_list;

    /********************************************************************************************
    * Devolve toda a informação registada na Documentation para um paciente, relativamente às escalas
    *
    * @param i_lang                   The language ID
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_doc_area               the doc area ID    
    * @param o_scales_list            Cursor with the scales info register
    * @param o_error                  Error message
    *                        
    * @return                         true or false on success or error
    * 
    * @author                         Luís Maia
    * @version                        1.0
    * @since                          2008/10/27
    **********************************************************************************************/
    FUNCTION get_scales_list_pat
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_doc_area    IN NUMBER,
        i_id_episode  IN NUMBER,
        o_scales_list OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_scales_core.get_scales_list_pat. i_doc_area = ' || i_doc_area || '; i_id_episode:' ||
                   i_id_episode;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_scales_list_pat(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_doc_area    => i_doc_area,
                                                  i_id_episode  => i_id_episode,
                                                  o_scales_list => o_scales_list,
                                                  o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
        -- 
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_scales_list_pat',
                                              o_error);
            pk_types.open_my_cursor(o_scales_list);
            RETURN FALSE;
    END get_scales_list_pat;

    /********************************************************************************************
    *  Get the documented assessment scales description "Title: score"
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_episode                  Episode Id
    * @param i_id_scales                Scales Id
    * @param o_ass_scales               Cursor with description in the format: "Title: score"
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Nuno Alves
    * @version                         2.6.3.8.2
    * @since                           27-04-2015
    **********************************************************************************************/
    FUNCTION get_epis_ass_scales_scores
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_tbl_episode     IN table_number,
        i_show_all_scores IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_ass_scales      OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL pk_scales_core.get_epis_ass_scales_scores';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_scales_core.get_epis_ass_scales_scores(i_lang            => i_lang,
                                                         i_prof            => i_prof,
                                                         i_tbl_episode     => i_tbl_episode,
                                                         i_show_all_scores => i_show_all_scores,
                                                         o_ass_scales      => o_ass_scales,
                                                         o_error           => o_error)
        THEN
            RETURN FALSE;
        END IF;
        --
        RETURN TRUE;
    END get_epis_ass_scales_scores;
BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_scales_api;
/
