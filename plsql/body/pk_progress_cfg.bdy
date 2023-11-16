/*-- Last Change Revision: $Rev: 2054564 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-13 15:43:38 +0000 (sex, 13 jan 2023) $*/
CREATE OR REPLACE PACKAGE BODY pk_progress_cfg AS
    /**************************************************************************
    * set data blocks configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/

    FUNCTION set_inst_dblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_DBLOCK';
    
        CURSOR c_get_dblock_records IS
            SELECT DISTINCT i_id_institution              id_institution,
                            pdm.id_software,
                            i_id_department               id_department,
                            i_id_dep_clin_serv            id_dep_clin_serv,
                            pdm.id_pn_soap_block,
                            pdm.id_pn_data_block,
                            pk_alert_constant.g_available flg_available,
                            pdm.rank,
                            pdm.flg_import,
                            pdm.flg_select,
                            pdm.flg_scope,
                            NULL                          code_message_title,
                            NULL                          create_user,
                            NULL                          create_time,
                            NULL                          create_institution,
                            NULL                          update_user,
                            NULL                          update_institution,
                            NULL                          update_time,
                            pdm.flg_actions_available,
                            pdm.flg_line_on_boxes,
                            pdm.gender,
                            pdm.age_min,
                            pdm.age_max,
                            pdm.flg_pregnant,
                            pdm.id_pn_note_type,
                            pdm.flg_outside_period,
                            pdm.days_available_period,
                            pdm.flg_mandatory,
                            pdm.flg_cp_no_changes_import,
                            pdm.flg_import_date,
                            pdm.flg_group_on_import,
                            pdm.id_pndb_parent,
                            pdm.flg_struct_type,
                            pdm.flg_show_title,
                            pdm.flg_show_sub_title,
                            pdm.flg_data_removable,
                            pdm.auto_pop_exec_prof_cat,
                            pdm.flg_focus,
                            pdm.flg_editable,
                            pdm.flg_group_select_filter,
                            pdm.id_task_type,
                            pdm.flg_order_type,
                            pdm.flg_signature,
                            pdm.flg_min_value,
                            pdm.flg_default_value,
                            pdm.flg_max_value,
                            pdm.flg_format,
                            pdm.flg_validation,
                            pdm.id_pndb_related,
                            pdm.id_swf_file_viewer,
                            pdm.value_viewer,
                            pdm.min_days_period,
                            pdm.max_days_period,
                            pdm.default_days_period,
                            pdm.flg_exc_sum_page_da,
                            pdm.flg_group_type,
                            pdm.desc_function
              FROM pn_dblock_mkt pdm
             WHERE pdm.id_software = nvl(i_id_software, pdm.id_software)
               AND pdm.id_pn_note_type = nvl(i_id_pn_note_type, pdm.id_pn_note_type)
               AND pdm.id_market = nvl(i_id_market, pdm.id_market);
    
        TYPE t_dblock_records IS TABLE OF c_get_dblock_records%ROWTYPE;
        l_dblock_records t_dblock_records;
    
    BEGIN
    
        g_error := 'OPEN C_GET_DBLOCK_RECORDS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_dblock_records;
        LOOP
            g_error := 'FETCH C_GET_DBLOCK_RECORDS CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_dblock_records BULK COLLECT
                INTO l_dblock_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_DBLOCK_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
        
            EXIT WHEN c_get_dblock_records%NOTFOUND;
        END LOOP;
        FOR i IN 1 .. l_dblock_records.count
        LOOP
            INSERT INTO pn_dblock_soft_inst
            VALUES l_dblock_records
                (i);
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_dblock;

    /**************************************************************************
    * set SOAP blocks configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_sblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_SBLOCK';
    
        CURSOR c_get_sblock_records IS
            SELECT DISTINCT i_id_institution       id_institution,
                            psm.id_software,
                            i_id_department        id_department,
                            i_id_dep_clin_serv     id_dep_clin_serv,
                            psm.id_pn_soap_block,
                            psm.rank,
                            NULL                   create_user,
                            NULL                   create_time,
                            NULL                   create_institution,
                            NULL                   update_user,
                            NULL                   update_institution,
                            NULL                   update_time,
                            psm.flg_execute_import,
                            psm.flg_show_title,
                            psm.id_pn_note_type,
                            psm.id_swf_file_viewer,
                            psm.value_viewer
              FROM pn_sblock_mkt psm
             WHERE psm.id_software = nvl(i_id_software, psm.id_software)
               AND psm.id_pn_note_type = nvl(i_id_pn_note_type, psm.id_pn_note_type)
               AND psm.id_market = nvl(i_id_market, psm.id_market);
    
        TYPE t_sblock_records IS TABLE OF c_get_sblock_records%ROWTYPE;
        l_sblock_records t_sblock_records;
    
    BEGIN
    
        g_error := 'OPEN C_GET_SBLOCK_RECORDS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_sblock_records;
        LOOP
            g_error := 'FETCH C_GET_SBLOCK_RECORDS CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_sblock_records BULK COLLECT
                INTO l_sblock_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_SBLOCK_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
            EXIT WHEN c_get_sblock_records%NOTFOUND;
        END LOOP;
    
        FOR i IN 1 .. l_sblock_records.count
        LOOP
            INSERT INTO pn_sblock_soft_inst
            VALUES l_sblock_records
                (i);
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_sblock;

    /**************************************************************************
    * set blocks/buttons configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note Type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_button
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_BUTTON';
    
    BEGIN
    
        g_error := 'MERGE PN_BUTTON_SOFT_INST';
        MERGE INTO pn_button_soft_inst a
        USING (SELECT DISTINCT i_id_institution              id_institution,
                               pbm.id_software,
                               i_id_department               id_department,
                               i_id_dep_clin_serv            id_dep_clin_serv,
                               pbm.id_pn_soap_block,
                               pbm.id_conf_button_block,
                               pk_alert_constant.g_available flg_available,
                               pbm.rank,
                               pbm.id_pn_note_type,
                               pbm.id_parent,
                               pbm.gender,
                               pbm.age_min,
                               pbm.age_max,
                               pbm.flg_activation
                 FROM pn_button_mkt pbm
                WHERE pbm.id_software = nvl(i_id_software, pbm.id_software)
                  AND pbm.id_pn_note_type = nvl(i_id_pn_note_type, pbm.id_pn_note_type)
                  AND pbm.id_market = nvl(i_id_market, pbm.id_market)) b
        ON (a.id_institution = b.id_institution AND a.id_software = b.id_software AND a.id_department = b.id_department AND a.id_dep_clin_serv = b.id_dep_clin_serv AND a.id_pn_note_type = b.id_pn_note_type AND a.id_pn_soap_block = b.id_pn_soap_block AND a.id_conf_button_block = b.id_conf_button_block)
        WHEN MATCHED THEN
            UPDATE
               SET a.flg_available  = b.flg_available,
                   a.rank           = b.rank,
                   a.id_parent      = b.id_parent,
                   a.gender         = b.gender,
                   a.age_min        = b.age_min,
                   a.age_max        = b.age_max,
                   a.flg_activation = b.flg_activation
        WHEN NOT MATCHED THEN
            INSERT
                (a.id_institution,
                 a.id_software,
                 a.id_department,
                 a.id_dep_clin_serv,
                 a.id_pn_soap_block,
                 a.id_conf_button_block,
                 a.flg_available,
                 a.rank,
                 a.id_pn_note_type,
                 a.id_parent,
                 a.gender,
                 a.age_min,
                 a.age_max,
                 a.flg_activation)
            VALUES
                (b.id_institution,
                 b.id_software,
                 b.id_department,
                 b.id_dep_clin_serv,
                 b.id_pn_soap_block,
                 b.id_conf_button_block,
                 b.flg_available,
                 b.rank,
                 b.id_pn_note_type,
                 b.id_parent,
                 b.gender,
                 b.age_min,
                 b.age_max,
                 b.flg_activation);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_button;

    /**************************************************************************
    * set profile_template access buttons for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_prof_soap_button
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_PROF_SOAP_BUTTON';
    
    BEGIN
    
        g_error := 'MERGE PROF_CONF_BUTTON_BLOCK';
        MERGE INTO pn_prof_soap_button a
        USING (SELECT DISTINCT pcbb.id_profile_template,
                               pcbb.id_conf_button_block,
                               i_id_institution id_institution,
                               id_category,
                               id_software,
                               flg_config_type
                 FROM prof_conf_button_block pcbb
                WHERE (pcbb.id_software = nvl(i_id_software, pcbb.id_software) OR
                      pcbb.id_profile_template IN (SELECT *
                                                      FROM TABLE(i_id_profile_templates)))
                  AND pcbb.id_market = nvl(i_id_market, pcbb.id_market)
                  AND NOT EXISTS (SELECT 1
                         FROM pn_prof_soap_button p
                        WHERE p.id_conf_button_block = pcbb.id_conf_button_block
                          AND p.id_institution = i_id_institution
                          AND p.id_profile_template = pcbb.id_profile_template
                          AND p.id_software = pcbb.id_software)) b
        ON (a.id_profile_template = b.id_profile_template AND a.id_conf_button_block = b.id_conf_button_block AND a.id_institution = b.id_institution AND a.id_category = b.id_category AND a.id_software = b.id_software AND a.flg_config_type = b.flg_config_type)
        WHEN NOT MATCHED THEN
            INSERT
                (a.id_profile_template,
                 a.id_conf_button_block,
                 a.id_institution,
                 a.id_category,
                 a.id_software,
                 a.flg_config_type)
            VALUES
                (b.id_profile_template,
                 b.id_conf_button_block,
                 b.id_institution,
                 b.id_category,
                 b.id_software,
                 b.flg_config_type);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_prof_soap_button;

    /**************************************************************************
    * create progress notes (SOAP)  for a specific institution
    * This function will be create the SOAP block, data blocks, buttons,
    * profile access and free text blocks configurations
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_pn_area             Area ID
    * @param i_id_market              Market id of the original records that will be copied
    * @param i_flg_single_page        Y - for single pafe congigs, N- for ambulatory SOAP configs
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION create_inst_prog_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        i_id_department        IN department.id_department%TYPE,
        i_id_dep_clin_serv     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type      IN pn_dblock_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_pn_area           IN pn_area_mkt.id_pn_area%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE,
        i_flg_single_page      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30) := 'CREATE_INST_PROG_NOTES';
        l_exception EXCEPTION;
    
    BEGIN
        IF (i_flg_single_page = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL SET_INST_DBLOCK';
            pk_alertlog.log_debug(g_error);
            IF NOT set_inst_area(i_lang             => i_lang,
                                 i_prof             => i_prof,
                                 i_id_institution   => i_id_institution,
                                 i_id_software      => i_id_software,
                                 i_id_market        => i_id_market,
                                 i_id_department    => i_id_department,
                                 i_id_dep_clin_serv => i_id_dep_clin_serv,
                                 i_id_pn_area       => i_id_pn_area,
                                 o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        
            g_error := 'CALL SET_INST_DBLOCK';
            pk_alertlog.log_debug(g_error);
            IF NOT set_inst_note_type(i_lang                 => i_lang,
                                      i_prof                 => i_prof,
                                      i_id_institution       => i_id_institution,
                                      i_id_software          => i_id_software,
                                      i_id_market            => i_id_market,
                                      i_id_profile_templates => i_id_profile_templates,
                                      i_id_department        => i_id_department,
                                      i_id_dep_clin_serv     => i_id_dep_clin_serv,
                                      i_id_pn_note_type      => i_id_pn_note_type,
                                      o_error                => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        g_error := 'CALL SET_INST_DBLOCK';
        pk_alertlog.log_debug(g_error);
        IF NOT set_inst_dblock(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_institution   => i_id_institution,
                               i_id_software      => i_id_software,
                               i_id_department    => i_id_department,
                               i_id_dep_clin_serv => i_id_dep_clin_serv,
                               i_id_pn_note_type  => i_id_pn_note_type,
                               i_id_market        => i_id_market,
                               o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL SET_INST_SBLOCK';
        pk_alertlog.log_debug(g_error);
        IF NOT set_inst_sblock(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_institution   => i_id_institution,
                               i_id_software      => i_id_software,
                               i_id_department    => i_id_department,
                               i_id_dep_clin_serv => i_id_dep_clin_serv,
                               i_id_pn_note_type  => i_id_pn_note_type,
                               i_id_market        => i_id_market,
                               o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'CALL SET_INST_BUTTON';
        pk_alertlog.log_debug(g_error);
        IF NOT set_inst_button(i_lang             => i_lang,
                               i_prof             => i_prof,
                               i_id_institution   => i_id_institution,
                               i_id_software      => i_id_software,
                               i_id_department    => i_id_department,
                               i_id_dep_clin_serv => i_id_dep_clin_serv,
                               i_id_pn_note_type  => i_id_pn_note_type,
                               i_id_market        => i_id_market,
                               o_error            => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF (i_flg_single_page = pk_alert_constant.g_yes)
        THEN
            g_error := 'CALL set_inst_task_types';
            pk_alertlog.log_debug(g_error);
            IF NOT set_inst_task_types(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_id_institution   => i_id_institution,
                                       i_id_software      => i_id_software,
                                       i_id_department    => i_id_department,
                                       i_id_dep_clin_serv => i_id_dep_clin_serv,
                                       i_id_pn_note_type  => i_id_pn_note_type,
                                       i_id_market        => i_id_market,
                                       o_error            => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END create_inst_prog_notes;

    /**************************************************************************
    * Associate profile_template access for the buttons and free text for a specific institution
    *                                                  
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/16                                 
    **************************************************************************/
    FUNCTION set_inst_prof_temp_association
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30) := 'SET_INST_PROF_TEMP_ASSOCIATION';
        l_exception EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL SET_INST_PROF_SOAP_BUTTON';
        pk_alertlog.log_debug(g_error);
        IF NOT set_inst_prof_soap_button(i_lang                 => i_lang,
                                         i_prof                 => i_prof,
                                         i_id_institution       => i_id_institution,
                                         i_id_software          => i_id_software,
                                         i_id_market            => i_id_market,
                                         i_id_profile_templates => i_id_profile_templates,
                                         o_error                => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_prof_temp_association;

    /**************************************************************************
    * set Note Types configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Ant? Neto
    * @version                        2.6.1.2
    * @since                          12-Aug-2011
    **************************************************************************/
    FUNCTION set_inst_note_type
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_software          IN software.id_software%TYPE DEFAULT NULL,
        i_id_market            IN market.id_market%TYPE DEFAULT NULL,
        i_id_profile_templates IN table_number,
        i_id_department        IN department.id_department%TYPE,
        i_id_dep_clin_serv     IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type      IN pn_note_type_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_NOTE_TYPE';
    
        CURSOR c_get_note_type_records IS
            SELECT DISTINCT id_pn_area,
                            id_pn_note_type,
                            i_id_institution              id_institution,
                            id_software,
                            id_category,
                            id_profile_template,
                            i_id_department               id_department,
                            i_id_dep_clin_serv            id_dep_clin_serv,
                            flg_config_type,
                            pk_alert_constant.g_available flg_available,
                            rank,
                            max_nr_notes,
                            max_nr_draft_notes,
                            max_nr_draft_addendums,
                            flg_addend_other_prof,
                            flg_show_empty_blocks,
                            flg_import_available,
                            flg_sign_off_login_avail,
                            flg_last_24h,
                            flg_dictation_editable,
                            flg_clear_information,
                            flg_review_all,
                            flg_import_first,
                            flg_write,
                            flg_copy_edit_replace,
                            gender,
                            age_min,
                            age_max,
                            flg_expand_sblocks,
                            flg_synchronized,
                            flg_show_import_menu,
                            NULL                          create_user,
                            NULL                          create_time,
                            NULL                          create_institution,
                            NULL                          update_user,
                            NULL                          update_institution,
                            NULL                          update_time,
                            flg_edit_other_prof,
                            flg_create_on_app,
                            flg_edit_after_disch,
                            flg_discharge_warning,
                            flg_autopop_warning,
                            flg_remove_warning,
                            flg_disch_warning_option,
                            flg_review_warning,
                            flg_review_warn_option,
                            flg_import_warning,
                            flg_help_save,
                            flg_edit_only_last,
                            flg_save_only_screen,
                            flg_status_available,
                            flg_partial_warning,
                            flg_remove_on_ok,
                            editable_nr_min,
                            flg_suggest_concept,
                            flg_review_on_ok,
                            flg_partial_load,
                            flg_sign_off,
                            flg_cancel,
                            flg_submit,
                            flg_calendar_view,
                            cal_delay_time,
                            cal_expect_date,
                            flg_cal_type,
                            flg_cal_time_filter,
                            cal_icu_delay_time,
                            flg_sync_after_disch,
                            flg_edit_condition,
                            flg_patient_id_warning,
                            flg_show_signature,
                            flg_show_free_text
              FROM pn_note_type_mkt pntmkt
             WHERE (pntmkt.id_software = nvl(i_id_software, pntmkt.id_software) OR
                   pntmkt.id_profile_template IN (SELECT *
                                                     FROM TABLE(i_id_profile_templates)))
               AND pntmkt.id_pn_note_type = nvl(i_id_pn_note_type, pntmkt.id_pn_note_type)
               AND pntmkt.id_market = nvl(i_id_market, pntmkt.id_market);
    
        TYPE t_note_type_records IS TABLE OF c_get_note_type_records%ROWTYPE;
        l_note_type_records t_note_type_records;
    
    BEGIN
    
        g_error := 'OPEN C_GET_NOTE_TYPE_RECORDS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_note_type_records;
        LOOP
            g_error := 'FETCH C_GET_NOTE_TYPE_RECORDS CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_note_type_records BULK COLLECT
                INTO l_note_type_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_NOTE_TYPE_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
            EXIT WHEN c_get_note_type_records%NOTFOUND;
        END LOOP;
    
        FOR i IN 1 .. l_note_type_records.count
        LOOP
            INSERT INTO pn_note_type_soft_inst
            VALUES l_note_type_records
                (i);
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_note_type;

    /**************************************************************************
    * set Area configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_area             Area ID
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Ant? Neto
    * @version                        2.6.1.2
    * @since                          12-Aug-2011
    **************************************************************************/
    FUNCTION set_inst_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_area       IN pn_area_mkt.id_pn_area%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_AREA';
    
        CURSOR c_get_area_records IS
            SELECT DISTINCT id_pn_area,
                            id_software,
                            i_id_institution              id_institution,
                            i_id_department               id_department,
                            i_id_dep_clin_serv            id_dep_clin_serv,
                            nr_rec_page_summary,
                            data_sort_summary,
                            nr_rec_page_hist,
                            flg_report_title_type,
                            pk_alert_constant.g_available flg_available,
                            NULL                          create_user,
                            NULL                          create_time,
                            NULL                          create_institution,
                            NULL                          update_user,
                            NULL                          update_institution,
                            NULL                          update_time,
                            summary_default_filter,
                            time_to_close_note,
                            time_to_start_docum,
                            id_report
              FROM pn_area_mkt pnamkt
             WHERE pnamkt.id_software = nvl(i_id_software, pnamkt.id_software)
               AND pnamkt.id_pn_area = nvl(i_id_pn_area, pnamkt.id_pn_area)
               AND pnamkt.id_market = nvl(i_id_market, pnamkt.id_market);
    
        TYPE t_area_records IS TABLE OF c_get_area_records%ROWTYPE;
        l_area_records t_area_records;
    
    BEGIN
    
        g_error := 'OPEN C_GET_AREA_RECORDS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_area_records;
        LOOP
            g_error := 'FETCH C_GET_AREA_RECORDS CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_area_records BULK COLLECT
                INTO l_area_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_AREA_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
            EXIT WHEN c_get_area_records%NOTFOUND;
        END LOOP;
        FOR i IN 1 .. l_area_records.count
        LOOP
            INSERT INTO pn_area_soft_inst
            VALUES l_area_records
                (i);
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_area;

    /**************************************************************************
    * set Note Types configurations for a specific institution to apply configurations for warning screens
    *                                                                         
    * @param   i_lang                          Language Identifier
    * @param   i_prof                          Profissional Identifier
    * @param   i_id_institution                Institution Identifier
    * @param   i_id_software                   Software Identifier
    * @param   i_id_department                 Department Identifier
    * @param   i_id_dep_clin_serv              Department Clinical Service Identifier
    * @param   i_id_pn_area                    Note Area Identifier
    * @param   i_id_pn_note_type               List of Note type Identifier
    * @param   i_flg_discharge_warning         In the discharge should appear an warning indicating the tasks that were not reviewed in the current visit
    * @param   i_flg_disch_warning_option      Indicate whether the options are checked with reMove or reView
    * @param   i_flg_autopop_warning           In the edition screen should appear the warning bar explaning which info is auto-populated
    * @param   i_flg_review_warning            In the review functionality should appear a warning indicating the data selected to be reviewd
    * @param   i_flg_review_warn_option        Indicate whether the options are checked with reMove or reView
    * @param   i_flg_import_warning            In the import functionality should appear a warning indicating the data to review
    *
    * @param   o_error                         Error message
    *
    * @value   i_flg_discharge_warning         {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_disch_warning_option      {*} 'M'- Remove {*} 'V'- Review
    * @value   i_flg_autopop_warning           {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_review_warning            {*} 'Y'- Yes {*} 'N'- No
    * @value   i_flg_review_warn_option        {*} 'M'- Remove {*} 'V'- Review
    * @value   i_flg_import_warning            {*} 'Y'- Yes {*} 'N'- No
    *
    * @author                         Ant? Neto
    * @version                        2.6.2
    * @since                          01-Mar-2012
    **************************************************************************/
    FUNCTION set_inst_note_warnings
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_institution           IN institution.id_institution%TYPE,
        i_id_software              IN software.id_software%TYPE DEFAULT NULL,
        i_id_department            IN department.id_department%TYPE,
        i_id_dep_clin_serv         IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_area               IN pn_note_type_mkt.id_pn_area%TYPE DEFAULT NULL,
        i_id_pn_note_type          IN table_number DEFAULT NULL,
        i_flg_discharge_warning    IN pn_note_type_soft_inst.flg_discharge_warning%TYPE DEFAULT NULL,
        i_flg_disch_warning_option IN pn_note_type_soft_inst.flg_disch_warning_option%TYPE DEFAULT NULL,
        i_flg_autopop_warning      IN pn_note_type_soft_inst.flg_autopop_warning%TYPE DEFAULT NULL,
        i_flg_review_warning       IN pn_note_type_soft_inst.flg_review_warning%TYPE DEFAULT NULL,
        i_flg_review_warn_option   IN pn_note_type_soft_inst.flg_review_warn_option%TYPE DEFAULT NULL,
        i_flg_import_warning       IN pn_note_type_soft_inst.flg_import_warning%TYPE DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_NOTE_WARNINGS';
    
        CURSOR c_get_note_type_records IS
            SELECT DISTINCT id_pn_area,
                            id_pn_note_type,
                            i_id_institution id_institution,
                            nvl(i_id_software, id_software) id_software,
                            id_category,
                            id_profile_template,
                            i_id_department id_department,
                            i_id_dep_clin_serv id_dep_clin_serv,
                            flg_config_type,
                            pk_alert_constant.g_available flg_available,
                            rank,
                            max_nr_notes,
                            max_nr_draft_notes,
                            max_nr_draft_addendums,
                            flg_addend_other_prof,
                            flg_show_empty_blocks,
                            flg_import_available,
                            flg_sign_off_login_avail,
                            flg_last_24h,
                            flg_dictation_editable,
                            flg_clear_information,
                            flg_review_all,
                            flg_import_first,
                            flg_write,
                            flg_copy_edit_replace,
                            gender,
                            age_min,
                            age_max,
                            flg_expand_sblocks,
                            flg_synchronized,
                            flg_show_import_menu,
                            flg_edit_other_prof,
                            flg_create_on_app,
                            flg_edit_after_disch,
                            nvl(i_flg_discharge_warning, flg_discharge_warning) flg_discharge_warning,
                            nvl(i_flg_autopop_warning, flg_autopop_warning) flg_autopop_warning,
                            flg_remove_warning,
                            nvl(i_flg_disch_warning_option, flg_disch_warning_option) flg_disch_warning_option,
                            nvl(i_flg_review_warning, flg_review_warning) flg_review_warning,
                            nvl(i_flg_review_warn_option, flg_review_warn_option) flg_review_warn_option,
                            nvl(i_flg_import_warning, flg_import_warning) flg_import_warning,
                            flg_help_save,
                            flg_edit_only_last,
                            flg_save_only_screen,
                            flg_status_available,
                            flg_partial_warning,
                            flg_remove_on_ok,
                            editable_nr_min,
                            flg_suggest_concept,
                            flg_review_on_ok
              FROM pn_note_type_mkt pntmkt
             WHERE pntmkt.id_software = nvl(i_id_software, pntmkt.id_software)
               AND (pntmkt.id_pn_note_type IN (SELECT column_value
                                                 FROM TABLE(i_id_pn_note_type)) OR i_id_pn_note_type IS NULL)
               AND pntmkt.id_pn_area = nvl(i_id_pn_area, pntmkt.id_pn_area);
    
        TYPE t_note_type_records IS TABLE OF c_get_note_type_records%ROWTYPE;
        l_note_type_records t_note_type_records;
        l_num_records       PLS_INTEGER;
    BEGIN
    
        g_error := 'OPEN C_GET_NOTE_TYPE_RECORDS CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_note_type_records;
        LOOP
            g_error := 'FETCH C_GET_NOTE_TYPE_RECORDS CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_note_type_records BULK COLLECT
                INTO l_note_type_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_NOTE_TYPE_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
            l_num_records := l_note_type_records.count;
            FORALL i IN 1 .. l_num_records
                MERGE INTO pn_note_type_soft_inst si
                USING (SELECT
                       
                        l_note_type_records(i).id_institution id_institution,
                        l_note_type_records(i).id_software id_software,
                        l_note_type_records(i).id_pn_area id_pn_area,
                        l_note_type_records(i).id_pn_note_type id_pn_note_type,
                        l_note_type_records(i).id_category id_category,
                        l_note_type_records(i).flg_config_type flg_config_type,
                        l_note_type_records(i).id_profile_template id_profile_template,
                        l_note_type_records(i).id_department id_department,
                        l_note_type_records(i).id_dep_clin_serv id_dep_clin_serv
                       
                         FROM dual
                       
                       ) args
                ON (si.id_institution = args.id_institution AND si.id_software = args.id_software AND si.id_pn_area = args.id_pn_area AND si.id_pn_note_type = args.id_pn_note_type AND si.id_category = args.id_category AND si.flg_config_type = args.flg_config_type AND si.id_profile_template = args.id_profile_template AND nvl(si.id_department, 0) = nvl(args.id_department, 0) AND nvl(si.id_dep_clin_serv, 0) = nvl(args.id_dep_clin_serv, 0))
                
                WHEN MATCHED THEN
                    UPDATE
                       SET --
                           si.flg_discharge_warning = nvl(i_flg_discharge_warning, si.flg_discharge_warning), --
                           si.flg_disch_warning_option = nvl(i_flg_disch_warning_option, si.flg_disch_warning_option), --
                           si.flg_autopop_warning      = nvl(i_flg_autopop_warning, si.flg_autopop_warning), --
                           si.flg_review_warning       = nvl(i_flg_review_warning, si.flg_review_warning), --
                           si.flg_review_warn_option   = nvl(i_flg_review_warn_option, si.flg_review_warn_option), --
                           si.flg_import_warning       = nvl(i_flg_import_warning, si.flg_import_warning)
                    
                
                WHEN NOT MATCHED THEN
                    INSERT
                        (id_pn_area,
                         id_pn_note_type,
                         id_institution,
                         id_software,
                         id_category,
                         id_profile_template,
                         id_department,
                         id_dep_clin_serv,
                         flg_config_type,
                         flg_available,
                         rank,
                         max_nr_notes,
                         max_nr_draft_notes,
                         max_nr_draft_addendums,
                         flg_addend_other_prof,
                         flg_show_empty_blocks,
                         flg_import_available,
                         flg_sign_off_login_avail,
                         flg_last_24h,
                         flg_dictation_editable,
                         flg_clear_information,
                         flg_review_all,
                         flg_import_first,
                         flg_write,
                         flg_copy_edit_replace,
                         gender,
                         age_min,
                         age_max,
                         flg_expand_sblocks,
                         flg_synchronized,
                         flg_show_import_menu,
                         flg_edit_other_prof,
                         flg_create_on_app,
                         flg_edit_after_disch,
                         flg_discharge_warning,
                         flg_autopop_warning,
                         flg_remove_warning,
                         flg_disch_warning_option,
                         flg_review_warning,
                         flg_review_warn_option,
                         flg_import_warning,
                         flg_help_save,
                         flg_edit_only_last,
                         flg_save_only_screen,
                         flg_status_available,
                         flg_partial_warning,
                         flg_remove_on_ok,
                         editable_nr_min,
                         flg_suggest_concept,
                         flg_review_on_ok)
                    VALUES
                        (l_note_type_records(i).id_pn_area,
                         l_note_type_records(i).id_pn_note_type,
                         l_note_type_records(i).id_institution,
                         l_note_type_records(i).id_software,
                         l_note_type_records(i).id_category,
                         l_note_type_records(i).id_profile_template,
                         l_note_type_records(i).id_department,
                         l_note_type_records(i).id_dep_clin_serv,
                         l_note_type_records(i).flg_config_type,
                         l_note_type_records(i).flg_available,
                         l_note_type_records(i).rank,
                         l_note_type_records(i).max_nr_notes,
                         l_note_type_records(i).max_nr_draft_notes,
                         l_note_type_records(i).max_nr_draft_addendums,
                         l_note_type_records(i).flg_addend_other_prof,
                         l_note_type_records(i).flg_show_empty_blocks,
                         l_note_type_records(i).flg_import_available,
                         l_note_type_records(i).flg_sign_off_login_avail,
                         l_note_type_records(i).flg_last_24h,
                         l_note_type_records(i).flg_dictation_editable,
                         l_note_type_records(i).flg_clear_information,
                         l_note_type_records(i).flg_review_all,
                         l_note_type_records(i).flg_import_first,
                         l_note_type_records(i).flg_write,
                         l_note_type_records(i).flg_copy_edit_replace,
                         l_note_type_records(i).gender,
                         l_note_type_records(i).age_min,
                         l_note_type_records(i).age_max,
                         l_note_type_records(i).flg_expand_sblocks,
                         l_note_type_records(i).flg_synchronized,
                         l_note_type_records(i).flg_show_import_menu,
                         l_note_type_records(i).flg_edit_other_prof,
                         l_note_type_records(i).flg_create_on_app,
                         l_note_type_records(i).flg_edit_after_disch,
                         l_note_type_records(i).flg_discharge_warning,
                         l_note_type_records(i).flg_autopop_warning,
                         l_note_type_records(i).flg_remove_warning,
                         l_note_type_records(i).flg_disch_warning_option,
                         l_note_type_records(i).flg_review_warning,
                         l_note_type_records(i).flg_review_warn_option,
                         l_note_type_records(i).flg_import_warning,
                         l_note_type_records(i).flg_help_save,
                         l_note_type_records(i).flg_edit_only_last,
                         l_note_type_records(i).flg_save_only_screen,
                         l_note_type_records(i).flg_status_available,
                         l_note_type_records(i).flg_partial_warning,
                         l_note_type_records(i).flg_remove_on_ok,
                         l_note_type_records(i).editable_nr_min,
                         l_note_type_records(i).flg_suggest_concept,
                         l_note_type_records(i).flg_review_on_ok);
        
            EXIT WHEN c_get_note_type_records%NOTFOUND;
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_note_warnings;

    /**************************************************************************
    * set Task Types configurations for a specific institution
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_institution         Institution ID
    * @param i_id_software            Software ID                         
    * @param i_id_department          Department ID   
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_note_type        Note type ID
    * @param i_id_market              Market id of the original records that will be copied
    *
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          22-May-2012
    **************************************************************************/
    FUNCTION set_inst_task_types
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_software      IN software.id_software%TYPE DEFAULT NULL,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type_mkt.id_pn_note_type%TYPE DEFAULT NULL,
        i_id_market        IN market.id_market%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'SET_INST_NOTE_TYPE';
    
        CURSOR c_get_task_type_records IS
            SELECT DISTINCT pdtmkt.id_pn_data_block,
                            pdtmkt.id_pn_soap_block,
                            pdtmkt.id_pn_note_type,
                            nvl(i_id_software, id_software) id_software,
                            i_id_institution id_institution,
                            i_id_department id_department,
                            i_id_dep_clin_serv id_dep_clin_serv,
                            pdtmkt.flg_auto_populated,
                            NULL create_user,
                            NULL create_time,
                            NULL create_institution,
                            NULL update_user,
                            NULL update_institution,
                            NULL update_time,
                            pk_alert_constant.g_available flg_available,
                            pdtmkt.id_task_type,
                            pdtmkt.flg_selected,
                            pdtmkt.flg_import_filter,
                            pdtmkt.last_n_records_nr,
                            pdtmkt.flg_shortcut_filter,
                            pdtmkt.flg_synchronized,
                            pdtmkt.review_cat,
                            pdtmkt.flg_review_avail,
                            pdtmkt.flg_description,
                            pdtmkt.description_condition,
                            pdtmkt.flg_dt_task,
                            pdtmkt.id_task_related
              FROM pn_dblock_ttp_mkt pdtmkt
             WHERE pdtmkt.id_software = nvl(i_id_software, pdtmkt.id_software)
               AND pdtmkt.id_pn_note_type = nvl(i_id_pn_note_type, pdtmkt.id_pn_note_type)
               AND pdtmkt.id_market = nvl(i_id_market, pdtmkt.id_market);
    
        TYPE t_task_type_records IS TABLE OF c_get_task_type_records%ROWTYPE;
        l_task_type_records t_task_type_records;
    
    BEGIN
    
        g_error := 'OPEN c_get_task_type_records CURSOR';
        pk_alertlog.log_debug(g_error);
        OPEN c_get_task_type_records;
        LOOP
            g_error := 'FETCH c_get_task_type_records CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH c_get_task_type_records BULK COLLECT
                INTO l_task_type_records LIMIT g_limit;
        
            g_error := 'INSERT RECORDS INTO PN_DBLOCK_TTP_SOFT_INST TABLE';
            pk_alertlog.log_debug(g_error);
            EXIT WHEN c_get_task_type_records%NOTFOUND;
        END LOOP;
        FOR i IN 1 .. l_task_type_records.count
        LOOP
            INSERT INTO pn_dblock_ttp_soft_inst
            VALUES l_task_type_records
                (i);
        
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
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END set_inst_task_types;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_progress_cfg;
/
