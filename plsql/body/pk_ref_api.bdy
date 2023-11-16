/*-- Last Change Revision: $Rev: 2027567 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:37 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ref_api AS

    g_error         VARCHAR2(1000 CHAR);
    g_package_name  VARCHAR2(50 CHAR);
    g_package_owner VARCHAR2(50 CHAR);

    g_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
    g_exception    EXCEPTION;
    g_exception_np EXCEPTION;
    g_retval BOOLEAN;
    --g_found  BOOLEAN;

    /**
    * Get professional id and nick name for a given professional num_order
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_prof_num_order  professional order number 
    * @param   i_prof_cat  professional category
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION get_prof_name
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_num_order IN professional.num_order%TYPE,
        i_prof_cat       IN category.id_category%TYPE,
        o_info           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFO / i_prof_num_order=' || i_prof_num_order || ' i_prof_cat=' || i_prof_cat;
        OPEN o_info FOR
            SELECT t.id_professional, pk_prof_utils.get_name(i_lang, t.id_professional) name
              FROM (SELECT p.id_professional
                      FROM professional p
                      JOIN prof_cat pc
                        ON (p.id_professional = pc.id_professional)
                     WHERE p.num_order = i_prof_num_order
                       AND pc.id_category = i_prof_cat) t
             ORDER BY name;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_PROF_NAME',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_prof_name;

    /**
    * Get all available institutions
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   o_info  output
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION get_inst_orig
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'OPEN O_INFO';
        OPEN o_info FOR
            SELECT t.id_institution,
                   nvl(t.abbreviation, pk_translation.get_translation(i_lang, t.code_institution)) abbreviation,
                   pk_translation.get_translation(i_lang, t.code_institution) desc_institution
              FROM (SELECT i.id_institution, i.abbreviation, i.code_institution
                      FROM institution i
                     WHERE i.flg_available = pk_ref_constant.g_yes) t
             ORDER BY abbreviation;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_INST_ORIG',
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_info);
            RETURN FALSE;
    END get_inst_orig;

    /**
    * Insert/Update table REF_ORG_DATA 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_ref_orig_data ref_orig_data to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION set_ref_orig_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_ref_orig_data IN ref_orig_data%ROWTYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'MERGE INTO ref_orig_data / ID_REF=' || i_ref_orig_data.id_external_request;
        MERGE INTO ref_orig_data t
        USING (SELECT i_ref_orig_data.id_external_request id_external_request,
                      i_ref_orig_data.id_professional     id_professional,
                      --i_ref_orig_data.num_order           num_order,
                      --i_ref_orig_data.prof_name           prof_name,
                      --i_ref_orig_data.id_institution      id_institution,
                      i_ref_orig_data.institution_name institution_name,
                      --i_ref_orig_data.id_prof_create   id_prof_create, -- same as p1_external_request.id_prof_created
                      i_ref_orig_data.dt_create dt_create
                 FROM dual) args
        ON (t.id_external_request = args.id_external_request)
        WHEN MATCHED THEN
            UPDATE
               SET t.id_professional = args.id_professional,
                   --t.num_order       = args.num_order,
                   --t.prof_name       = args.prof_name,
                   --t.id_institution   = args.id_institution,
                   t.institution_name = args.institution_name,
                   --t.id_prof_create   = args.id_prof_create,
                   t.dt_create = args.dt_create
        WHEN NOT MATCHED THEN
            INSERT
                (id_external_request,
                 id_professional,
                 --num_order,
                 --prof_name,
                 --id_institution,
                 institution_name,
                 --id_prof_create,
                 dt_create)
            VALUES
                (args.id_external_request,
                 args.id_professional,
                 --args.num_order,
                 --args.prof_name,
                 --args.id_institution,
                 args.institution_name,
                 --args.id_prof_create,
                 args.dt_create);
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_ORIG_DATA',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END set_ref_orig_data;

    /**
    * Insert/Update table P1_DETAIL 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_p1_detail p1_detail to insert/update
    * @param   o_detail id_p1_detail to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */
    FUNCTION set_p1_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_p1_detail IN p1_detail%ROWTYPE,
        o_id_detail OUT p1_detail.id_detail%TYPE,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_p1_detail p1_detail%ROWTYPE;
    BEGIN
        g_error                     := 'Init set_p1_detail';
        l_p1_detail                 := i_p1_detail;
        l_p1_detail.dt_insert_tstz  := nvl(l_p1_detail.dt_insert_tstz, pk_ref_utils.get_sysdate);
        l_p1_detail.id_professional := nvl(l_p1_detail.id_professional, i_prof.id);
        l_p1_detail.id_institution  := nvl(l_p1_detail.id_institution, i_prof.institution);
        l_p1_detail.flg_status      := nvl(l_p1_detail.flg_status, pk_ref_constant.g_detail_status_a);
    
        o_id_detail := seq_p1_detail.nextval;
    
        MERGE INTO p1_detail t
        USING (SELECT l_p1_detail.id_detail           id_detail,
                      l_p1_detail.id_external_request id_external_request,
                      l_p1_detail.text                text,
                      l_p1_detail.flg_type            flg_type,
                      l_p1_detail.id_professional     id_professional,
                      l_p1_detail.id_institution      id_institution,
                      l_p1_detail.id_tracking         id_tracking,
                      l_p1_detail.flg_status          flg_status,
                      l_p1_detail.dt_insert_tstz      dt_insert_tstz,
                      l_p1_detail.id_group            id_group
                 FROM dual) args
        ON (t.id_detail = args.id_detail)
        WHEN MATCHED THEN
            UPDATE
               SET t.id_external_request = args.id_external_request,
                   t.text                = args.text,
                   t.flg_type            = args.flg_type,
                   t.id_professional     = args.id_professional,
                   t.id_institution      = args.id_institution,
                   t.id_tracking         = args.id_tracking,
                   t.flg_status          = args.flg_status,
                   t.dt_insert_tstz      = args.dt_insert_tstz,
                   t.id_group            = args.id_group
        WHEN NOT MATCHED THEN
            INSERT
                (id_detail,
                 id_external_request,
                 text,
                 flg_type,
                 id_professional,
                 id_institution,
                 id_tracking,
                 flg_status,
                 dt_insert_tstz,
                 id_group)
            VALUES
                (o_id_detail,
                 args.id_external_request,
                 args.text,
                 args.flg_type,
                 args.id_professional,
                 args.id_institution,
                 args.id_tracking,
                 args.flg_status,
                 args.dt_insert_tstz,
                 args.id_group);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_P1_DETAIL',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_p1_detail;

    /**
    * Insert/Update table P1_TASK_DONE 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_p1_task_done p1_task_done to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION set_p1_task_done
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_p1_task_done IN p1_task_done%ROWTYPE,
        o_id_task_done OUT p1_task_done.id_task_done%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var p1_task_done.id_task_done%TYPE;
    BEGIN
    
        g_error := 'Init set_p1_task_done / ID_REF=' || i_p1_task_done.id_external_request;
        SELECT seq_p1_task_done.nextval
          INTO l_var
          FROM dual;
    
        MERGE INTO p1_task_done t
        USING (SELECT i_p1_task_done.id_task_done        id_task_done,
                      i_p1_task_done.id_prof_exec        id_prof_exec,
                      i_p1_task_done.id_task             id_task,
                      i_p1_task_done.id_external_request id_external_request,
                      i_p1_task_done.flg_task_done       flg_task_done,
                      i_p1_task_done.flg_type            flg_type,
                      i_p1_task_done.notes               notes,
                      i_p1_task_done.dt_completed_tstz   dt_completed_tstz,
                      i_p1_task_done.dt_inserted_tstz    dt_inserted_tstz,
                      i_p1_task_done.flg_status          flg_status,
                      i_p1_task_done.id_group            id_group,
                      i_p1_task_done.id_professional     id_professional,
                      i_p1_task_done.id_institution      id_institution,
                      i_p1_task_done.id_inst_exec        id_inst_exec
                 FROM dual) args
        ON (t.id_task_done = args.id_task_done)
        WHEN MATCHED THEN
            UPDATE
               SET t.id_prof_exec        = args.id_prof_exec,
                   t.id_task             = args.id_task,
                   t.id_external_request = args.id_external_request,
                   t.flg_task_done       = args.flg_task_done,
                   t.flg_type            = args.flg_type,
                   t.notes               = args.notes,
                   t.dt_completed_tstz   = args.dt_completed_tstz,
                   t.dt_inserted_tstz    = args.dt_inserted_tstz,
                   t.flg_status          = args.flg_status,
                   t.id_group            = args.id_group,
                   t.id_professional     = args.id_professional,
                   t.id_institution      = args.id_institution,
                   t.id_inst_exec        = args.id_inst_exec
        WHEN NOT MATCHED THEN
            INSERT
                (id_task_done,
                 id_prof_exec,
                 id_task,
                 id_external_request,
                 flg_task_done,
                 flg_type,
                 notes,
                 dt_completed_tstz,
                 dt_inserted_tstz,
                 flg_status,
                 id_group,
                 id_professional,
                 id_institution,
                 id_inst_exec)
            VALUES
                (l_var,
                 args.id_prof_exec,
                 args.id_task,
                 args.id_external_request,
                 args.flg_task_done,
                 args.flg_type,
                 args.notes,
                 args.dt_completed_tstz,
                 args.dt_inserted_tstz,
                 args.flg_status,
                 args.id_group,
                 args.id_professional,
                 args.id_institution,
                 args.id_inst_exec);
    
        o_id_task_done := l_var;
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_P1_TASK_DONE',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_p1_task_done;

    /**
    * Insert/Update table P1_EXR_DIAGNOSIS 
    *
    * @param   i_lang language associated to the professional executing the request
    * @param   i_prof professional id, institution and software
    * @param   i_p1_exr_diagnosis p1_exr_diagnosis to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   22-06-2009
    */

    FUNCTION set_p1_exr_diagnosis
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_p1_exr_diagnosis    IN p1_exr_diagnosis%ROWTYPE,
        o_id_p1_exr_diagnosis OUT p1_exr_diagnosis.id_exr_diagnosis%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error               := 'Init set_p1_exr_diagnosis / ID_REF=' || i_p1_exr_diagnosis.id_external_request;
        o_id_p1_exr_diagnosis := seq_p1_exr_diagnosis.nextval;
    
        MERGE INTO p1_exr_diagnosis t
        USING (SELECT i_p1_exr_diagnosis.id_exr_diagnosis    id_exr_diagnosis,
                      i_p1_exr_diagnosis.id_external_request id_external_request,
                      i_p1_exr_diagnosis.id_diagnosis        id_diagnosis,
                      i_p1_exr_diagnosis.id_professional     id_professional,
                      i_p1_exr_diagnosis.id_institution      id_institution,
                      i_p1_exr_diagnosis.flg_type            flg_type,
                      i_p1_exr_diagnosis.flg_status          flg_status,
                      i_p1_exr_diagnosis.dt_insert_tstz      dt_insert_tstz,
                      i_p1_exr_diagnosis.desc_diagnosis      desc_diagnosis,
                      --i_p1_exr_diagnosis.dt_probl_begin_tstz dt_probl_begin_tstz
                      i_p1_exr_diagnosis.year_begin         year_begin,
                      i_p1_exr_diagnosis.month_begin        month_begin,
                      i_p1_exr_diagnosis.day_begin          day_begin,
                      i_p1_exr_diagnosis.id_alert_diagnosis id_alert_diagnosis
                 FROM dual) args
        ON (t.id_exr_diagnosis = args.id_exr_diagnosis)
        WHEN MATCHED THEN
            UPDATE
               SET t.id_external_request = args.id_external_request,
                   t.id_diagnosis        = args.id_diagnosis,
                   t.id_professional     = args.id_professional,
                   t.id_institution      = args.id_institution,
                   t.flg_type            = args.flg_type,
                   t.flg_status          = args.flg_status,
                   t.dt_insert_tstz      = args.dt_insert_tstz,
                   t.desc_diagnosis      = args.desc_diagnosis,
                   --t.dt_probl_begin_tstz = args.dt_probl_begin_tstz
                   t.year_begin         = args.year_begin,
                   t.month_begin        = args.month_begin,
                   t.day_begin          = args.day_begin,
                   t.id_alert_diagnosis = args.id_alert_diagnosis
        WHEN NOT MATCHED THEN
            INSERT
                (id_exr_diagnosis,
                 id_external_request,
                 id_diagnosis,
                 id_alert_diagnosis,
                 id_professional,
                 id_institution,
                 flg_type,
                 flg_status,
                 dt_insert_tstz,
                 desc_diagnosis,
                 --dt_probl_begin_tstz
                 year_begin,
                 month_begin,
                 day_begin)
            VALUES
                (o_id_p1_exr_diagnosis,
                 args.id_external_request,
                 args.id_diagnosis,
                 args.id_alert_diagnosis,
                 args.id_professional,
                 args.id_institution,
                 args.flg_type,
                 args.flg_status,
                 args.dt_insert_tstz,
                 args.desc_diagnosis,
                 --args.dt_probl_begin_tstz
                 args.year_begin,
                 args.month_begin,
                 args.day_begin);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_P1_EXR_DIAGNOSIS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_p1_exr_diagnosis;

    /**
    * Inserts/Updates table REF_MAP 
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data to insert or update
    * @param   o_id_ref_map Identifiers created/changed
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   28-10-2009
    */
    FUNCTION set_ref_map
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_ref_map    IN ref_map%ROWTYPE,
        o_id_ref_map OUT ref_map.id_ref_map%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_var ref_map.id_ref_map%TYPE;
    BEGIN
        g_error := 'Init set_ref_map / ID_REF=' || i_ref_map.id_external_request;
        SELECT seq_ref_map.nextval
          INTO l_var
          FROM dual;
    
        MERGE INTO ref_map t
        USING (SELECT i_ref_map.id_ref_map          id_ref_map,
                      i_ref_map.id_external_request id_external_request,
                      i_ref_map.id_schedule         id_schedule,
                      i_ref_map.id_episode          id_episode,
                      i_ref_map.flg_status          flg_status
                 FROM dual) args
        ON (t.id_ref_map = args.id_ref_map)
        WHEN MATCHED THEN
            UPDATE
               SET t.id_external_request = args.id_external_request,
                   t.id_schedule         = args.id_schedule,
                   t.id_episode          = args.id_episode,
                   t.flg_status          = args.flg_status
        WHEN NOT MATCHED THEN
            INSERT
                (id_ref_map, id_external_request, id_schedule, id_episode, flg_status)
            VALUES
                (l_var, args.id_external_request, args.id_schedule, args.id_episode, args.flg_status);
    
        o_id_ref_map := l_var;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MAP',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_map;

    /**
    * Update column flg_migrated ( table p1_external_request)
    * Used when BDNP interface is available ALERT-191066
    *
    * @param  I_LANG                 Language associated to the professional executing the request
    * @param  I_PROF                 Professional id, institution and software    
    * @param  i_id_external_request  Referral identifier
    * @param  i_flg_migrated         Flag indicating if it was migrated
    * @param   O_ERROR an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-8-2011
    */
    FUNCTION set_referral_flg_migrated
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_external_request IN p1_external_request.id_external_request%TYPE,
        i_flg_migrated        IN p1_external_request.flg_migrated%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    BEGIN
        g_error := 'Init set_referral_flg_migrated / i_prof=' || pk_utils.to_string(i_prof) || ' ID_REF=' ||
                   i_id_external_request || ' i_flg_flg_migrated = ' || i_flg_migrated;
        pk_alertlog.log_debug(g_error);
    
        IF i_flg_migrated IS NULL
           OR i_flg_migrated NOT IN (pk_ref_constant.g_bdnp_msg_s,
                                     pk_ref_constant.g_bdnp_msg_w,
                                     pk_ref_constant.g_bdnp_msg_e,
                                     pk_ref_constant.g_bdnp_mig_n,
                                     pk_ref_constant.g_bdnp_mig_x)
        THEN
            g_error := 'Value not allowed / i_flg_migrated=' || i_flg_migrated;
            RAISE g_exception;
        END IF;
    
        g_error := 'Call ts_p1_external_request.upd i_flg_migrated= ' || i_flg_migrated || 'id_external_request=' ||
                   i_id_external_request;
        ts_p1_external_request.upd(id_external_request_in => i_id_external_request,
                                   flg_migrated_in        => i_flg_migrated,
                                   handle_error_in        => TRUE,
                                   rows_out               => l_rowids);
    
        g_error := 'Call t_data_gov_mnt.process_update i_table_name=P1_EXTERNAL_REQUEST';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'P1_EXTERNAL_REQUEST',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            RETURN pk_alert_exceptions.process_error(i_lang     => i_lang,
                                                     i_sqlcode  => SQLCODE,
                                                     i_sqlerrm  => SQLERRM,
                                                     i_message  => g_error,
                                                     i_owner    => g_package_owner,
                                                     i_package  => g_package_name,
                                                     i_function => 'SET_REFERRAL_FLG_MIGRATED',
                                                     o_error    => o_error);
    END set_referral_flg_migrated;

    /**
    * Creates an active REF_MAP record 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_schedule    Schedule identifier
    * @param   i_id_episode     Episode identifier
    * @param   o_id_ref_map     REF_MAP identifier     
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   09-12-2009
    */
    FUNCTION create_ref_map
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_ref      IN ref_map.id_external_request%TYPE,
        i_id_schedule IN ref_map.id_schedule%TYPE DEFAULT NULL,
        i_id_episode  IN ref_map.id_episode%TYPE,
        o_id_ref_map  OUT ref_map.id_ref_map%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_map_row ref_map%ROWTYPE;
    BEGIN
        g_error                           := 'Init create_ref_map / ID_REF=' || i_id_ref || ' ID_SCHEDULE=' ||
                                             i_id_schedule || ' ID_EPISODE=' || i_id_episode;
        l_ref_map_row.id_external_request := i_id_ref;
        l_ref_map_row.id_schedule         := i_id_schedule;
        l_ref_map_row.id_episode          := i_id_episode;
        l_ref_map_row.flg_status          := pk_ref_constant.g_active;
    
        g_error  := 'Call set_ref_map / ID_REF=' || l_ref_map_row.id_external_request || ' ID_SCHEDULE=' ||
                    l_ref_map_row.id_schedule || ' ID_EPISODE=' || l_ref_map_row.id_episode || ' FLG_STATUS=' ||
                    l_ref_map_row.flg_status;
        g_retval := set_ref_map(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_ref_map    => l_ref_map_row,
                                o_id_ref_map => o_id_ref_map,
                                o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_MAP',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_ref_map;

    /**
    * Cancels REF_MAP record 
    *
    * @param   i_lang       Language associated to the professional executing the request
    * @param   i_prof       Professional id, institution and software
    * @param   i_ref_map    Record data 
    * @param   o_error      An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   03-11-2009
    */
    FUNCTION cancel_ref_map
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ref_map_row IN ref_map%ROWTYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ref_map_row ref_map%ROWTYPE;
        l_id_ref_map  ref_map.id_ref_map%TYPE;
    BEGIN
    
        g_error                  := 'Init cancel_ref_map / ID_REF=' || i_ref_map_row.id_external_request;
        l_ref_map_row            := i_ref_map_row;
        l_ref_map_row.flg_status := pk_ref_constant.g_cancelled;
    
        g_error  := 'Call set_ref_map / ID_REF_MAP=' || l_ref_map_row.id_ref_map || ' ID_REF=' ||
                    l_ref_map_row.id_external_request || ' ID_SCHEDULE=' || l_ref_map_row.id_schedule || ' ID_EPISODE=' ||
                    l_ref_map_row.id_episode || ' FLG_STATUS=' || l_ref_map_row.flg_status;
        g_retval := set_ref_map(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_ref_map    => l_ref_map_row,
                                o_id_ref_map => l_id_ref_map,
                                o_error      => o_error);
    
        IF NOT g_retval
        THEN
            RAISE g_exception_np;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_warn(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CANCEL_REF_MAP',
                                              o_error    => o_error);
            RETURN FALSE;
    END cancel_ref_map;

    /**
    * Insert/Update table p1_specaility 
    *
    * @param   i_lang                         language associated to the professional executing the request
    * @param   i_id_speciality                p1_specaility to insert/update
    * @param   i_id_content                   p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update        
    * @param   i_id_parent                    p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update
    * @param   i_id_parent                    p1_specaility to insert/update    
    * @param   o_p1_specaility p1_specaility to insert/update
    * @param   o_error an error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   24-01-2011
    */
    FUNCTION set_p1_speciality
    (
        i_lang          IN language.id_language%TYPE,
        i_id_speciality IN p1_speciality.id_speciality%TYPE,
        i_id_content    IN p1_speciality.id_content%TYPE,
        i_id_parent     IN p1_speciality.id_parent%TYPE,
        i_flg_available IN p1_speciality.flg_available%TYPE DEFAULT 'Y',
        i_gender        IN p1_speciality.gender%TYPE,
        i_age_min       IN p1_speciality.age_min%TYPE,
        i_age_max       IN p1_speciality.age_max%TYPE,
        i_trans_array   IN table_table_varchar,
        o_id_spec       OUT p1_speciality.id_speciality%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_lang language.id_language%TYPE;
    BEGIN
        IF i_id_speciality IS NULL
        THEN
            g_error := 'i_id_speciality is null';
            RAISE g_exception;
        END IF;
    
        g_error := 'MERGE p1_speciality = ' || i_id_speciality;
        MERGE INTO p1_speciality t
        USING (SELECT i_id_speciality id_speciality,
                      pk_ref_constant.g_p1_speciality_code || i_id_speciality code_speciality,
                      i_flg_available flg_available,
                      i_gender gender,
                      i_age_min age_min,
                      i_age_max i_age_max,
                      i_id_content id_content,
                      i_id_parent id_parent
                 FROM dual) args
        ON (t.id_speciality = args.id_speciality)
        WHEN MATCHED THEN
            UPDATE
               SET t.flg_available = args.flg_available,
                   t.gender        = args.gender,
                   t.age_min       = args.age_min,
                   t.age_max       = args.i_age_max,
                   t.id_parent     = args.id_parent,
                   t.id_content    = args.id_content
        WHEN NOT MATCHED THEN
            INSERT
                (id_speciality, code_speciality, flg_available, gender, age_min, age_max, id_content, id_parent)
            VALUES
                (args.id_speciality,
                 args.code_speciality,
                 args.flg_available,
                 args.gender,
                 args.age_min,
                 args.i_age_max,
                 args.id_content,
                 args.id_parent);
    
        o_id_spec := i_id_speciality;
    
        IF i_trans_array.count > 0
        THEN
            <<loop>>
            FOR i IN 1 .. i_trans_array.count
            LOOP
                l_lang := to_number(i_trans_array(i) (1));
                pk_translation.insert_into_translation(i_lang       => l_lang,
                                                       i_code_trans => pk_ref_constant.g_p1_speciality_code ||
                                                                       i_id_speciality,
                                                       i_desc_trans => i_trans_array(i) (2));
            END LOOP;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_P1_SPECAILITY',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_p1_speciality;

    /**
    * Creates a record in table REF_MIG_INST_DEST
    *
    * @param   i_lang                         Language associated to the professional executing the request
    * @param   i_prof                         Professional id, institution and software
    * @param   i_id_ref                       Referral identifier
    * @param   i_id_inst_dest_new             New destination institution identifier
    * @param   i_flg_result                   Flag indicating if the referral was successfully migrated
    * @param   i_dt_create                    Migration date     
    * @param   i_error_desc                   Error description (in case the migration was not successful)
    * @param   o_error                        An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   18-06-2012
    */
    FUNCTION create_ref_mig_inst
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_ref           IN ref_mig_inst_dest.id_external_request%TYPE,
        i_id_inst_dest_new IN ref_mig_inst_dest.id_inst_dest_new%TYPE,
        i_flg_result       IN ref_mig_inst_dest.flg_result%TYPE,
        i_dt_create        IN ref_mig_inst_dest.dt_create%TYPE DEFAULT current_timestamp,
        i_error_desc       IN ref_mig_inst_dest.error_desc%TYPE DEFAULT NULL,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_row ref_mig_inst_dest%ROWTYPE;
    BEGIN
        g_error                   := 'Init create_ref_mig_inst / ID_REF=' || i_id_ref || ' i_id_inst_dest_new=' ||
                                     i_id_inst_dest_new || ' i_flg_result=' || i_flg_result;
        l_row.id_external_request := i_id_ref;
        l_row.id_inst_dest_new    := i_id_inst_dest_new;
        l_row.flg_result          := i_flg_result;
        l_row.dt_create           := i_dt_create;
        l_row.error_desc          := i_error_desc;
    
        g_error := 'INSERT INTO ref_mig_inst_dest / ID_REF=' || i_id_ref || ' i_id_inst_dest_new=' ||
                   i_id_inst_dest_new || ' i_flg_result=' || i_flg_result;
        INSERT INTO ref_mig_inst_dest
        VALUES l_row;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CREATE_REF_MIG_INST',
                                              o_error    => o_error);
            RETURN FALSE;
    END create_ref_mig_inst;

    /**
    * Updates FLG_PROCESSED in table REF_MIG_INST_DEST_DATA
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref         Referral identifier
    * @param   i_id_inst_dest   Destination institution identifier
    * @param   i_flg_processed  Flag indicating if the referral was successfully processed or not
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Ana Monteiro
    * @version 1.0
    * @since   07-09-2012
    */
    FUNCTION set_ref_mig_inst_data
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_ref        IN ref_mig_inst_dest_data.id_external_request%TYPE,
        i_id_inst_dest  IN ref_mig_inst_dest_data.id_inst_dest%TYPE,
        i_flg_processed IN ref_mig_inst_dest_data.flg_processed%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Init set_ref_mig_inst_data / ID_REF=' || i_id_ref || ' i_id_inst_dest=' || i_id_inst_dest ||
                   ' i_FLG_PROCESSED=' || i_flg_processed;
        UPDATE ref_mig_inst_dest_data
           SET flg_processed = i_flg_processed
         WHERE id_external_request = i_id_ref
           AND id_inst_dest = i_id_inst_dest;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_MIG_INST_DATA',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_mig_inst_data;

    /**
    * Set Referral comments
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_prof_data      Professional data    
    * @param   i_id_ref         Referral identifier
    * @param   i_id_ref_comment Referral comment id
    * @param   i_text           Text comment
    * @param   i_flg_status     Comment status
    * @param   i_dt_comment     Comment date 
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   05-07-2013
    **/

    FUNCTION set_ref_comments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_prof_data      IN t_rec_prof_data,
        i_id_ref         IN p1_external_request.id_external_request%TYPE,
        i_id_ref_comment IN ref_comments.id_ref_comment%TYPE,
        i_text           IN CLOB,
        i_flg_status     IN ref_comments.flg_status%TYPE,
        i_dt_comment     IN ref_comments.dt_comment%TYPE,
        o_id_ref_comment OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_check_comment
        (
            x_id_ref_comment ref_comments.id_ref_comment%TYPE,
            x_id_ref         p1_external_request.id_external_request%TYPE,
            x_id_prof        professional.id_professional%TYPE,
            x_id_inst        institution.id_institution%TYPE
        ) IS
            SELECT COUNT(1) val
              FROM ref_comments rc
             WHERE rc.id_ref_comment = x_id_ref_comment
               AND rc.id_external_request = x_id_ref
               AND rc.id_professional = x_id_prof
               AND rc.flg_status = pk_ref_constant.g_active_comment;
    
        l_check_comment c_check_comment%ROWTYPE;
        l_flg_type      ref_comments.flg_type%TYPE;
        l_ref_context   t_rec_ref_context;
        l_dt_comment    ref_comments.dt_comment%TYPE;
        l_params        VARCHAR2(1000 CHAR);
    
        l_ref_comments_row ref_comments%ROWTYPE;
        l_rowids           table_varchar;
    BEGIN
        l_params := 'PK_REF_API.SET_REF_COMMENTS / I_PROF=' || pk_utils.to_string(i_prof) || ' ID_REF=' || i_id_ref;
    
        g_error       := 'CALL pk_ref_utils.get_ref_context';
        l_ref_context := pk_ref_utils.get_ref_context;
        l_dt_comment  := coalesce(l_ref_context.dt_system_date, i_dt_comment, current_timestamp);
    
        IF i_prof_data.id_category = pk_ref_constant.g_cat_id_med
        THEN
            l_flg_type := pk_ref_constant.g_clinical_comment;
        ELSE
            l_flg_type := pk_ref_constant.g_administrative_comment;
        END IF;
    
        -- check data before insert or update records
        g_error := 'OPEN c_check_comment /  X_ID_REF_COMMENT=' || i_id_ref_comment || ', X_ID_REF=' || i_id_ref ||
                   ', X_ID_PROF=' || i_prof.id || ', X_ID_INST=' || i_prof.institution;
        pk_alertlog.log_info(g_error);
        OPEN c_check_comment(i_id_ref_comment, i_id_ref, i_prof.id, i_prof.institution);
        FETCH c_check_comment
            INTO l_check_comment;
        CLOSE c_check_comment;
    
        IF l_check_comment.val > 0
           OR i_flg_status = pk_ref_constant.g_active_comment
        THEN
            o_id_ref_comment := table_number();
            o_id_ref_comment.extend;
            l_rowids := table_varchar();
            IF i_id_ref_comment IS NULL
               AND i_flg_status = pk_ref_constant.g_active_comment
            THEN
                g_error                                := 'Set vals for ts_ref_comments.ins';
                l_ref_comments_row.id_ref_comment      := ts_ref_comments.next_key();
                l_ref_comments_row.id_external_request := i_id_ref;
                l_ref_comments_row.flg_type            := l_flg_type;
                l_ref_comments_row.id_professional     := i_prof.id;
                l_ref_comments_row.id_institution      := i_prof.institution;
                l_ref_comments_row.flg_status          := pk_ref_constant.g_active_comment;
                l_ref_comments_row.id_software         := i_prof.software;
                l_ref_comments_row.dt_comment          := l_dt_comment;
            
                o_id_ref_comment(1) := l_ref_comments_row.id_ref_comment;
            
                g_error := 'Call ts_ref_comments.ins';
                ts_ref_comments.ins(rec_in => l_ref_comments_row, handle_error_in => TRUE, rows_out => l_rowids);
            
                g_error := 'Call Process_insert REF_COMMENTS';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'REF_COMMENTS',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                g_error := 'Call pk_translation.insert_translation_trs / ' || pk_ref_constant.g_ref_comments_code ||
                           l_ref_comments_row.id_ref_comment;
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => pk_ref_constant.g_ref_comments_code ||
                                                                  l_ref_comments_row.id_ref_comment,
                                                      i_desc   => i_text,
                                                      i_module => 'REF_COMMENTS');
            
                g_error := 'Call pk_ia_event_referral.referral_comment_new / I_ID_REF_COMMENT=' ||
                           l_ref_comments_row.id_ref_comment;
                pk_ia_event_referral.referral_comment_new(i_id_ref_comment  => l_ref_comments_row.id_ref_comment,
                                                          i_id_institution  => i_prof.institution,
                                                          i_id_professional => i_prof.id,
                                                          i_id_software     => i_prof.software,
                                                          i_id_language     => i_lang);
            
            ELSIF i_id_ref_comment IS NOT NULL
                  AND i_flg_status = pk_ref_constant.g_canceled_comment
            THEN
                g_error := 'UPDATE ref_comments / I_ID_REF_COMMENT=' || i_id_ref_comment || ', FLG_STATUS=' ||
                           i_flg_status || ', DT_COMMENT_CANCELED=' || l_dt_comment || ', ID_INSTITUTION_CANCELED=' ||
                           i_prof.institution;
            
                g_error := 'Call ts_ref_comments.upd flg_status_in=||' || pk_ref_constant.g_canceled_comment;
                ts_ref_comments.upd(flg_status_in              => pk_ref_constant.g_canceled_comment,
                                    dt_comment_canceled_in     => l_dt_comment,
                                    id_institution_canceled_in => i_prof.institution,
                                    where_in                   => 'id_ref_comment = ' || i_id_ref_comment ||
                                                                  ' AND id_professional = ' || i_prof.id ||
                                                                  ' AND id_external_request= ' || i_id_ref ||
                                                                  ' AND flg_type = ''' || l_flg_type || '''',
                                    rows_out                   => l_rowids);
            
                g_error := 'Process_update REF_COMMENTS';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'REF_COMMENTS',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                o_id_ref_comment(1) := i_id_ref_comment;
            
                g_error := 'Call pk_ia_event_referral.referral_comment_cancel / I_ID_REF_COMMENT=' || i_id_ref_comment;
                pk_ia_event_referral.referral_comment_cancel(i_id_ref_comment  => i_id_ref_comment,
                                                             i_id_institution  => i_prof.institution,
                                                             i_id_professional => i_prof.id,
                                                             i_id_software     => i_prof.software,
                                                             i_id_language     => i_lang);
            
            ELSIF i_id_ref_comment IS NOT NULL
                  AND i_flg_status = pk_ref_constant.g_outdated_comment
            THEN
                o_id_ref_comment(1) := i_id_ref_comment;
                o_id_ref_comment.extend;
            
                g_error := 'UPDATE ref_comments / I_ID_REF_COMMENT=' || i_id_ref_comment || ', FLG_STATUS=' ||
                           i_flg_status || ', DATE_COMMENT_OUTDATED=' || l_dt_comment;
            
                g_error := 'Call ts_ref_comments.upd flg_status_in=' || pk_ref_constant.g_outdated_comment;
                ts_ref_comments.upd(flg_status_in              => pk_ref_constant.g_outdated_comment,
                                    dt_comment_outdated_in     => l_dt_comment,
                                    id_institution_outdated_in => i_prof.institution,
                                    where_in                   => 'id_ref_comment= ' || i_id_ref_comment ||
                                                                  ' AND id_professional = ' || i_prof.id ||
                                                                  ' AND id_external_request = ' || i_id_ref ||
                                                                  ' AND flg_type = ''' || l_flg_type || '''',
                                    rows_out                   => l_rowids);
                g_error := 'Process_update REF_COMMENTS';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'REF_COMMENTS',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                g_error := 'Call pk_ia_event_referral.referral_comment_update / I_ID_REF_COMMENT=' || i_id_ref_comment;
                pk_ia_event_referral.referral_comment_update(i_id_ref_comment  => i_id_ref_comment,
                                                             i_id_institution  => i_prof.institution,
                                                             i_id_professional => i_prof.id,
                                                             i_id_software     => i_prof.software,
                                                             i_id_language     => i_lang);
            
                g_error := 'INSERT  ref_comments / ID_REF_COMMENT=' || o_id_ref_comment(2) || ', ID_EXTERNAL_REQUEST=' ||
                           i_id_ref;
            
                g_error := 'Set vals for ts_ref_comments.ins';
                l_rowids := table_varchar();
                l_ref_comments_row.id_ref_comment := ts_ref_comments.next_key();
                o_id_ref_comment(2) := l_ref_comments_row.id_ref_comment;
                l_ref_comments_row.id_external_request := i_id_ref;
                l_ref_comments_row.flg_type := l_flg_type;
                l_ref_comments_row.id_professional := i_prof.id;
                l_ref_comments_row.id_institution := i_prof.institution;
                l_ref_comments_row.id_software := i_prof.software;
                l_ref_comments_row.flg_status := pk_ref_constant.g_active_comment;
                l_ref_comments_row.dt_comment := l_dt_comment;
            
                g_error := 'Call ts_ref_comments.ins';
                ts_ref_comments.ins(rec_in => l_ref_comments_row, handle_error_in => TRUE, rows_out => l_rowids);
            
                g_error := 'Process_insert REF_COMMENTS';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'REF_COMMENTS',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
                g_error := 'Call pk_translation.insert_translation_trs / ' || pk_ref_constant.g_ref_comments_code ||
                           l_ref_comments_row.id_ref_comment;
                pk_translation.insert_translation_trs(i_lang   => i_lang,
                                                      i_code   => pk_ref_constant.g_ref_comments_code ||
                                                                  l_ref_comments_row.id_ref_comment,
                                                      i_desc   => i_text,
                                                      i_module => 'REF_COMMENTS');
            
                g_error := 'Call pk_ia_event_referral.referral_comment_new / I_ID_REF_COMMENT=' ||
                           l_ref_comments_row.id_ref_comment;
                pk_ia_event_referral.referral_comment_new(i_id_ref_comment  => l_ref_comments_row.id_ref_comment,
                                                          i_id_institution  => i_prof.institution,
                                                          i_id_professional => i_prof.id,
                                                          i_id_software     => i_prof.software,
                                                          i_id_language     => i_lang);
            
            ELSE
                g_error := l_params || ' Invalid Option';
                RAISE g_exception_np;
            END IF;
        ELSE
            g_error := l_params || ' Invalid Option';
            RAISE g_exception_np;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_COMMENTS',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_comments;

    /**
    * Set Referral comments read 
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional id, institution and software
    * @param   i_id_ref_comment   
    * @param   i_flg_status
    * @param   i_flg_type
    * @param   i_read    
    
    * @param   o_id_ref_comment Referral comment ids
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   18-07-2013
    **/

    FUNCTION set_ref_comments_read
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_ref_comment      IN ref_comments.id_ref_comment%TYPE,
        i_flg_status          IN ref_comments.flg_status%TYPE,
        i_flg_type            IN ref_comments.flg_type%TYPE,
        i_read                IN OUT BOOLEAN,
        o_id_ref_comment_read OUT ref_comments_read.id_ref_comment_read%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_my_last_read
        (
            x_id_ref_comment ref_comments.id_ref_comment%TYPE,
            x_id_prof        professional.id_professional%TYPE,
            x_flg_type       ref_comments.flg_type%TYPE
        ) IS
            SELECT COUNT(rcr.id_ref_comment_read) val
              FROM ref_comments_read rcr
              JOIN ref_comments rc
                ON (rcr.id_ref_comment = rc.id_ref_comment)
             WHERE rcr.id_professional = x_id_prof
               AND rcr.id_ref_comment = x_id_ref_comment
               AND rc.flg_status = pk_ref_constant.g_active_comment
               AND rc.flg_type = x_flg_type;
    
        l_my_last_read_row c_my_last_read%ROWTYPE;
    
        l_ref_comments_read_row ref_comments_read%ROWTYPE;
        l_rowids                table_varchar;
    BEGIN
        g_sysdate_tstz := pk_ref_utils.get_sysdate;
        g_error        := 'Open c_my_last_read / ID_REF_COMMENT=' || i_id_ref_comment || ', ID_PROFESSIONAL=' ||
                          i_prof.id || ', FLG_TYPE=' || i_flg_type;
        OPEN c_my_last_read(i_id_ref_comment, i_prof.id, i_flg_type);
        FETCH c_my_last_read
            INTO l_my_last_read_row;
        CLOSE c_my_last_read;
    
        IF NOT i_read
           AND l_my_last_read_row.val = 0
           AND i_flg_status = pk_ref_constant.g_active_comment
        THEN
            g_error                                     := 'Call ts_ref_comments_read.next_key';
            l_ref_comments_read_row.id_ref_comment_read := ts_ref_comments_read.next_key();
            l_ref_comments_read_row.id_ref_comment      := i_id_ref_comment;
            l_ref_comments_read_row.id_professional     := i_prof.id;
            l_ref_comments_read_row.id_institution      := i_prof.institution;
            l_ref_comments_read_row.dt_comment_read     := g_sysdate_tstz;
        
            g_error := 'ts_ref_comments_read.ins / ID_REF_COMMENT=' || i_id_ref_comment || ', ID_PROFESSIONAL=' ||
                       i_prof.id || ', ID_INSTITUTION=' || i_prof.institution || ', DT_COMMENT_READ=' || g_sysdate_tstz;
            ts_ref_comments_read.ins(rec_in => l_ref_comments_read_row, handle_error_in => TRUE, rows_out => l_rowids);
        
            g_error := 'Call Process_insert REF_COMMENTS_READ';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REF_COMMENTS_READ',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            i_read := TRUE;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception_np THEN
            pk_alertlog.log_debug(g_error);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REF_COMMENTS_READ',
                                              o_error    => o_error);
            RETURN FALSE;
    END set_ref_comments_read;

    /**
    * Indicates for each MCDT, whether it is a chronic disease or not (FLG_ALD)
    *
    * @param   i_lang           Language associated to the professional executing the request
    * @param   i_prof           Professional, institution and software ids
    * @param   i_ref            Referral identifier    
    * @param   i_mcdt_ald       Chronic disease information for each MCDT (FLG_ALD) [id_mcdt|id_sample_type|flg_ald]
    * @param   o_p1_exr_temp    
    * @param   o_error          An error message, set when return=false
    *
    * @RETURN  TRUE if sucess, FALSE otherwise
    * @author  Joana Barroso
    * @version 1.0
    * @since   23-09-2012
    */
    FUNCTION set_p1_exr_flg_ald
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ref         IN p1_external_request.id_external_request%TYPE,
        i_mcdt_ald    IN table_table_varchar,
        o_p1_exr_temp OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name          VARCHAR2(0100 CHAR) := 'SET_P1_EXR_FLG_ALD';
        l_params             VARCHAR2(1000 CHAR);
        l_mcdt_ald           table_table_varchar;
        l_flg_tab            table_varchar;
        l_id_tab             table_number;
        l_id_sample_type_tab table_number;
    
        l_idx_id_mcdt CONSTANT PLS_INTEGER := 1;
        l_idx_id_st   CONSTANT PLS_INTEGER := 2;
        l_idx_id_flg  CONSTANT PLS_INTEGER := 3;
    BEGIN
        -- init vars
        l_params             := 'i_prof=' || pk_utils.to_string(i_prof);
        g_error              := 'Init ' || l_func_name || ' / ' || l_params;
        l_mcdt_ald           := table_table_varchar();
        l_flg_tab            := table_varchar();
        l_id_tab             := table_number();
        l_id_sample_type_tab := table_number();
    
        g_error := 'SELECT * BULK COLLECT / ' || l_params;
        SELECT *
          BULK COLLECT
          INTO l_mcdt_ald
          FROM TABLE(CAST(i_mcdt_ald AS table_table_varchar));
    
        l_flg_tab.extend(l_mcdt_ald.count);
        l_id_tab.extend(l_mcdt_ald.count);
        l_id_sample_type_tab.extend(l_mcdt_ald.count);
    
        g_error := 'FOR i IN 1 .. ' || l_mcdt_ald.count || ' / ' || l_params;
        <<tables>>
        FOR i IN 1 .. l_mcdt_ald.count
        LOOP
            l_id_tab(i) := to_number(l_mcdt_ald(i) (l_idx_id_mcdt));
            l_id_sample_type_tab(i) := to_number(l_mcdt_ald(i) (l_idx_id_st));
            l_flg_tab(i) := l_mcdt_ald(i) (l_idx_id_flg);
        END LOOP tables;
    
        g_error := 'FORALL i IN 1 .. ' || l_id_tab.count || ' / ' || l_params;
        FORALL i IN 1 .. l_id_tab.count
            UPDATE p1_exr_temp pet
               SET pet.flg_ald = l_flg_tab(i)
             WHERE pet.id_exr_temp IN
                   (SELECT pett.id_exr_temp
                      FROM p1_external_request per
                      JOIN p1_exr_temp pett
                        ON (per.id_external_request = pett.id_external_request)
                     WHERE per.id_external_request = i_ref
                       AND (
                           -- labtests
                            (pett.id_analysis = l_id_tab(i) AND pett.id_sample_type = l_id_sample_type_tab(i) AND
                            per.flg_type = pk_ref_constant.g_p1_type_a)
                           -- exams
                            OR (pett.id_exam = l_id_tab(i) AND
                            per.flg_type IN (pk_ref_constant.g_p1_type_e, pk_ref_constant.g_p1_type_i))
                           -- interv/rehab
                            OR (pett.id_intervention = l_id_tab(i) AND
                            per.flg_type IN (pk_ref_constant.g_p1_type_p, pk_ref_constant.g_p1_type_f))));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END set_p1_exr_flg_ald;

    FUNCTION get_ref_exam_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM p1_external_request per
         INNER JOIN p1_exr_temp pet
            ON pet.id_external_request = per.id_external_request
         INNER JOIN exams_ea eea
            ON eea.id_exam_req_det = pet.id_exam_req_det
         WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND per.flg_type = pk_exam_constant.g_type_img
           AND eea.flg_time IN
               (pk_exam_constant.g_flg_time_e, pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
           AND per.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_p);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             INNER JOIN p1_exr_temp pet
                ON pet.id_external_request = per.id_external_request
             INNER JOIN exams_ea eea
                ON eea.id_exam_req_det = pet.id_exam_req_det
             WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.flg_type = pk_exam_constant.g_type_img
               AND eea.flg_time IN
                   (pk_exam_constant.g_flg_time_e, pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND per.flg_status IN (pk_ref_constant.g_p1_status_o);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             WHERE per.flg_type = pk_exam_constant.g_type_img
               AND per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.print_nr > 0;
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_completed;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_not_started;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_ref_exam_viewer_checklist;

    FUNCTION get_ref_lab_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM p1_external_request per
         INNER JOIN p1_exr_temp pet
            ON pet.id_external_request = per.id_external_request
         INNER JOIN lab_tests_ea lte
            ON lte.id_analysis_req_det = pet.id_analysis_req_det
         WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND per.flg_type = pk_lab_tests_constant.g_analysis_alias
           AND lte.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_e, pk_lab_tests_constant.g_flg_time_b)
           AND per.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_p);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             INNER JOIN p1_exr_temp pet
                ON pet.id_external_request = per.id_external_request
             INNER JOIN lab_tests_ea lte
                ON lte.id_analysis_req_det = pet.id_analysis_req_det
             WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.flg_type = pk_lab_tests_constant.g_analysis_alias
               AND lte.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_e, pk_lab_tests_constant.g_flg_time_b)
               AND per.flg_status IN (pk_ref_constant.g_p1_status_o);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             WHERE per.flg_type = pk_lab_tests_constant.g_analysis_alias
               AND per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.print_nr > 0;
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_completed;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_not_started;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_ref_lab_viewer_checklist;

    FUNCTION get_ref_ot_ex_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM p1_external_request per
         INNER JOIN p1_exr_temp pet
            ON pet.id_external_request = per.id_external_request
         INNER JOIN exams_ea eea
            ON eea.id_exam_req_det = pet.id_exam_req_det
         WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND per.flg_type = pk_exam_constant.g_type_exm
           AND eea.flg_time IN
               (pk_exam_constant.g_flg_time_e, pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
           AND per.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_p);
    
        IF l_count > 0
        THEN
        
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             INNER JOIN p1_exr_temp pet
                ON pet.id_external_request = per.id_external_request
             INNER JOIN exams_ea eea
                ON eea.id_exam_req_det = pet.id_exam_req_det
             WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.flg_type = pk_exam_constant.g_type_exm
               AND eea.flg_time IN
                   (pk_exam_constant.g_flg_time_e, pk_exam_constant.g_flg_time_b, pk_exam_constant.g_flg_time_d)
               AND per.flg_status IN (pk_ref_constant.g_p1_status_o);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_completed;
            END IF;
        ELSE
        
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             WHERE per.flg_type = pk_exam_constant.g_type_exm
               AND per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.print_nr > 0;
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_completed;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_not_started;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_ref_ot_ex_viewer_checklist;

    FUNCTION get_ref_proc_viewer_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        i_scope_type IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
        l_episode table_number;
    
        l_count NUMBER := 0;
    
    BEGIN
    
        l_episode := pk_episode.get_scope(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_patient    => i_patient,
                                          i_episode    => i_episode,
                                          i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_count
          FROM p1_external_request per
         INNER JOIN p1_exr_temp pet
            ON pet.id_external_request = per.id_external_request
         INNER JOIN procedures_ea pea
            ON pea.id_interv_presc_det = pet.id_interv_presc_det
         WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                   *
                                    FROM TABLE(l_episode) t)
           AND per.flg_type = pk_procedures_constant.g_type_interv
           AND pea.flg_time IN (pk_procedures_constant.g_flg_time_e, pk_procedures_constant.g_flg_time_b)
           AND per.flg_status IN (pk_ref_constant.g_p1_status_o, pk_ref_constant.g_p1_status_p);
    
        IF l_count > 0
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             INNER JOIN p1_exr_temp pet
                ON pet.id_external_request = per.id_external_request
             INNER JOIN procedures_ea pea
                ON pea.id_interv_presc_det = pet.id_interv_presc_det
             WHERE per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.flg_type = pk_procedures_constant.g_type_interv
               AND pea.flg_time IN (pk_procedures_constant.g_flg_time_e, pk_procedures_constant.g_flg_time_b)
               AND per.flg_status IN (pk_ref_constant.g_p1_status_p);
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_completed;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_ongoing;
            END IF;
        ELSE
            SELECT COUNT(*)
              INTO l_count
              FROM p1_external_request per
             WHERE per.flg_type = pk_procedures_constant.g_type_interv
               AND per.id_episode IN (SELECT /*+opt_estimate (table t rows=1)*/
                                       *
                                        FROM TABLE(l_episode) t)
               AND per.print_nr > 0;
        
            IF l_count > 0
            THEN
                RETURN pk_viewer_checklist.g_checklist_completed;
            ELSE
                RETURN pk_viewer_checklist.g_checklist_not_started;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_viewer_checklist.g_checklist_not_started;
    END get_ref_proc_viewer_checklist;

BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_ref_api;
/
