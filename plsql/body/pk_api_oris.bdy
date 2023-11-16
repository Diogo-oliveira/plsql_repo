/*-- Last Change Revision: $Rev: 2026694 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:36 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_oris IS
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(30);
    g_exception     EXCEPTION;

    /********************************************************************************************
    * Creates an episode
    *
    * @param i_lang              Language ID
    * @param i_id_patient        Patient ID
    * @param i_prof              Professional, institution and software IDs
    * @param i_id_visit          Visit ID (may be NULL)
    * @param i_dt_creation       Episode creation date
    * @param i_dt_begin          Episode begin date
    * @param i_id_episode_ext    External episode value
    * @param i_flg_ehr           Episode type: N-Normal, S-Planning, E-EHR
    * @param i_id_dep_clin_serv  Clinic service ID
    * @param i_flg_migration     Migration flag: M-migrated A-normal
    * @param i_id_room           Room to schedule
    * @param i_id_external_sys   External episode identifier
    * @param o_episode_new       Created episode ID
    * @param o_error             Error message
    *
    * @return                    TRUE/FALSE
    *
    * @author                    Sérgio Dias
    * @since                     2010/08/20
    * @Notes                     ALERT-118077
         ********************************************************************************************/
    FUNCTION create_episode
    (
        i_lang             IN language.id_language%TYPE,
        i_id_patient       IN OUT patient.id_patient%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_creation      IN episode.dt_creation%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_id_episode_ext   IN epis_ext_sys.value%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_flg_migration    IN episode.flg_migration%TYPE,
        i_id_room          IN room.id_room%TYPE,
        i_id_external_sys  IN epis_ext_sys.id_external_sys%TYPE DEFAULT NULL,
        o_episode_new      OUT episode.id_episode%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        o_schedule      schedule.id_schedule%TYPE;
        l_function_name VARCHAR2(30) := 'CREATE_EPISODE';
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_id_patient:' || i_id_patient || ' i_prof.software:' || i_prof.software ||
                   ' i_prof.INSTITUTION:' || i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_visit:' ||
                   i_id_visit || 'i_dt_creation:' || i_dt_creation || 'i_dt_begin:' || i_dt_begin ||
                   'i_id_episode_ext:' || i_id_episode_ext || 'i_flg_ehr:' || i_flg_ehr || 'i_id_dep_clin_serv:' ||
                   i_id_dep_clin_serv || 'i_flg_migration:' || i_flg_migration || 'i_id_room:' || i_id_room ||
                   'i_id_external_sys:' || i_id_external_sys;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        --Cria o processo cirúrgico
        g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        IF NOT pk_sr_visit.create_all_surgery_int(i_lang             => i_lang,
                                                  i_patient          => i_id_patient,
                                                  i_prof             => i_prof,
                                                  i_visit            => i_id_visit,
                                                  i_flg_ehr          => i_flg_ehr,
                                                  i_id_dcs_requested => i_id_dep_clin_serv,
                                                  i_dt_creation      => i_dt_creation,
                                                  i_dt_begin         => i_dt_begin,
                                                  i_id_episode_ext   => i_id_episode_ext,
                                                  i_flg_migration    => i_flg_migration,
                                                  i_id_room          => i_id_room,
                                                  i_id_external_sys  => i_id_external_sys,
                                                  o_episode_new      => o_episode_new,
                                                  o_schedule         => o_schedule,
                                                  o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Import professionals in the surgery team
    *
    * @param i_lang             Language ID
    * @param i_prof             Professional, institution and software IDs
    * @param i_id_episode       Associated episode ID
    * @param i_tbl_prof         Professional IDs table 
    * @param i_tbl_catg         Professional sub-categories table
    * @param i_tbl_status       Record status table -     'N' - new record
                                                          'C' - changed record
                                                          'D' - delete record
    * @param i_dt_reg           Team creation time
    
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-118232
         ********************************************************************************************/
    FUNCTION set_sr_prof_team
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_tbl_prof   IN table_number,
        i_tbl_catg   IN table_number,
        i_tbl_status IN table_varchar,
        i_dt_reg     IN sr_prof_team_det.dt_reg_tstz%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_show      VARCHAR2(1);
        l_msg_title     VARCHAR2(4000);
        l_button        VARCHAR2(2);
        l_msg_text      VARCHAR2(4000);
        l_function_name VARCHAR2(30) := 'SET_SR_PROF_TEAM';
    
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_tbl_prof.COUNT:' || i_tbl_prof.count ||
                   'i_tbl_catg.COUNT:' || i_tbl_catg.count || 'i_tbl_status.COUNT:' || i_tbl_status.count ||
                   'i_dt_reg:' || i_dt_reg || 'i_id_episode:' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_TOOLS.SET_SR_PROF_TEAM_DET';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        -- Inserts profesionals into team with i_test = yes to perform tests to the data
        IF NOT pk_sr_tools.set_sr_prof_team_det_no_commit(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_surgery_record  => NULL,
                                                          i_episode         => i_id_episode,
                                                          i_episode_context => NULL,
                                                          i_prof_team       => NULL,
                                                          i_tbl_prof        => i_tbl_prof,
                                                          i_tbl_catg        => i_tbl_catg,
                                                          i_tbl_status      => i_tbl_status,
                                                          i_test            => pk_alert_constant.g_yes,
                                                          i_dt_reg          => i_dt_reg,
                                                          o_flg_show        => l_flg_show,
                                                          o_msg_title       => l_msg_title,
                                                          o_msg_text        => l_msg_text,
                                                          o_button          => l_button,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF l_flg_show = pk_alert_constant.g_yes
        THEN
            g_error := l_msg_title || ' - ' || l_msg_text;
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Insert surgery times
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional, institution and software IDs
    * @param i_id_episode           Associated episode ID
    * @param i_id_sr_surgery_time   Surgery time type ID 
    * @param i_dt_surgery_time_det  Surgery time value
    * @param i_dt_reg               Record creation date
    *
    * @param o_id_sr_surgery_time_det    Created record ID
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-118237
         ********************************************************************************************/
    FUNCTION set_surgery_times
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_surgery_time     IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_dt_surgery_time_det    IN sr_surgery_time_det.dt_surgery_time_det_tstz%TYPE,
        i_dt_reg                 IN sr_surgery_time_det.dt_reg_tstz%TYPE,
        o_id_sr_surgery_time_det OUT sr_surgery_time_det.id_sr_surgery_time_det%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_show       VARCHAR2(1);
        l_flg_refresh    VARCHAR2(1);
        l_msg_title      VARCHAR2(4000);
        l_button         VARCHAR2(2);
        l_msg_text       VARCHAR2(4000);
        l_function_name  VARCHAR2(30) := 'SET_SURGERY_TIMES';
        l_transaction_id VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(NULL, i_prof);
    
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_episode:' || i_id_episode ||
                   'i_id_sr_surgery_time:' || i_id_sr_surgery_time || 'i_dt_surgery_time_det:' || i_dt_surgery_time_det ||
                   'i_dt_reg:' || i_dt_reg;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_SURG_RECORD.SET_SURGERY_TIME TESTING';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        -- 1st call with i_test = yes to test times
        IF NOT pk_sr_surg_record.set_surgery_time(i_lang                   => i_lang,
                                                  i_sr_surgery_time        => i_id_sr_surgery_time,
                                                  i_episode                => i_id_episode,
                                                  i_dt_surgery_time        => pk_date_utils.date_send_tsz(i_lang,
                                                                                                          i_dt_surgery_time_det,
                                                                                                          i_prof),
                                                  i_prof                   => i_prof,
                                                  i_test                   => pk_alert_constant.g_yes,
                                                  i_dt_reg                 => pk_date_utils.date_send_tsz(i_lang,
                                                                                                          i_dt_reg,
                                                                                                          i_prof),
                                                  i_transaction_id         => l_transaction_id,
                                                  o_flg_show               => l_flg_show,
                                                  o_msg_result             => l_msg_text,
                                                  o_title                  => l_msg_title,
                                                  o_button                 => l_button,
                                                  o_flg_refresh            => l_flg_refresh,
                                                  o_id_sr_surgery_time_det => o_id_sr_surgery_time_det,
                                                  o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- If previous test was successful then
        IF l_flg_show = pk_alert_constant.g_no
           OR (l_flg_show = pk_alert_constant.g_yes AND l_button = 'NC')
        THEN
            g_error := 'CALL TO PK_SR_SURG_RECORD.SET_SURGERY_TIME INSERTING';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            -- 2nd call with i_test = no to insert times
            IF NOT pk_sr_surg_record.set_surgery_time(i_lang                   => i_lang,
                                                      i_sr_surgery_time        => i_id_sr_surgery_time,
                                                      i_episode                => i_id_episode,
                                                      i_dt_surgery_time        => pk_date_utils.date_send_tsz(i_lang,
                                                                                                              i_dt_surgery_time_det,
                                                                                                              i_prof),
                                                      i_prof                   => i_prof,
                                                      i_test                   => pk_alert_constant.g_no,
                                                      i_dt_reg                 => pk_date_utils.date_send_tsz(i_lang,
                                                                                                              i_dt_reg,
                                                                                                              i_prof),
                                                      i_transaction_id         => l_transaction_id,
                                                      o_flg_show               => l_flg_show,
                                                      o_msg_result             => l_msg_text,
                                                      o_title                  => l_msg_title,
                                                      o_button                 => l_button,
                                                      o_flg_refresh            => l_flg_refresh,
                                                      o_id_sr_surgery_time_det => o_id_sr_surgery_time_det,
                                                      o_error                  => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := l_msg_title || ' - ' || l_msg_text;
            RAISE g_exception;
        END IF;
    
        IF l_transaction_id IS NOT NULL
        THEN
            g_error := 'call  pk_schedule_api_upstream.do_commit for id_transaction: ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Insert intervention descriptions
    *
    * @param i_lang                 Language ID
    * @param i_prof                 Professional, institution and software IDs
    * @param i_id_episode           Associated episode ID
    * @param I_id_sr_epis_interv    Intervention ID 
    * @param i_desc_intervention    Intervention description
    * @param i_dt_interv_desc       Intervention description insertion date
    *
    * @param o_id_sr_epis_interv_desc    Created record ID
    * @param o_error                     Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-118237
         ********************************************************************************************/
    FUNCTION set_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_epis_interv      IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_desc_intervention      IN sr_epis_interv_desc.desc_interv%TYPE,
        i_dt_interv_desc         IN sr_epis_interv_desc.dt_interv_desc_tstz%TYPE,
        o_id_sr_epis_interv_desc OUT sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_INTERV_DESC';
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_episode:' || i_id_episode ||
                   'i_id_sr_epis_interv:' || i_id_sr_epis_interv || 'i_desc_intervention:' || i_desc_intervention ||
                   'i_dt_interv_desc:' || i_dt_interv_desc;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_SURG_RECORD.SET_SURG_PROCEDURES_DESC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF NOT pk_sr_planning.set_surg_proc_desc_no_commit(i_lang                   => i_lang,
                                                           i_episode                => i_id_episode,
                                                           i_episode_context        => i_id_episode,
                                                           i_sr_epis_interv         => i_id_sr_epis_interv,
                                                           i_prof                   => i_prof,
                                                           i_notes                  => i_desc_intervention,
                                                           i_dt_interv_desc         => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   i_dt_interv_desc,
                                                                                                                   i_prof),
                                                           o_id_sr_epis_interv_desc => o_id_sr_epis_interv_desc,
                                                           o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    *  Imports an intervention  
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_dt_interv_start        Intervention start date
    * @param i_dt_interv_end          Intervention end date
    * @param i_id_episode             Episode ID
    * @param i_id_sr_intervention     Intervention ID
    * @param i_flg_type               Intervention type
    * @param i_flg_status             Intervention status
    * @param i_dt_req                 Request date
    * @param i_name_interv            Intervention name (not coded)
    * @param i_laterality             Laterality
    * @param i_id_diagnosis           Diagnosis ID
    * @param i_notes                  Intervention notes
    * @param i_flg_surg_request       Indicates if this surgical procedure was requested as part of the surgery/admission requests (Yes) or as part of proposed surgery (No)
    * @param i_diag_desc_sp           Desc diagnosis from the diagnosis of the surgical procedures
    
    * @param o_id_sr_epis_interv      Created record ID
    * @param o_error                  Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-116342
         ********************************************************************************************/
    FUNCTION set_epis_surg_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_dt_interv_start    IN sr_epis_interv.dt_interv_start_tstz%TYPE,
        i_dt_interv_end      IN sr_epis_interv.dt_interv_end_tstz%TYPE,
        i_id_episode         IN sr_epis_interv.id_episode%TYPE,
        i_id_sr_intervention IN sr_epis_interv.id_sr_intervention%TYPE,
        i_flg_type           IN sr_epis_interv.flg_type%TYPE,
        i_flg_status         IN sr_epis_interv.flg_status%TYPE,
        i_dt_req             IN sr_epis_interv.dt_req_tstz%TYPE,
        i_name_interv        IN sr_epis_interv.name_interv%TYPE,
        i_laterality         IN sr_epis_interv.laterality%TYPE,
        i_id_diagnosis       IN epis_diagnosis.id_diagnosis%TYPE,
        i_notes              IN sr_epis_interv.notes%TYPE,
        i_flg_surg_request   IN sr_epis_interv.flg_surg_request%TYPE,
        i_diag_desc_sp       IN epis_diagnosis.desc_epis_diagnosis%TYPE, --desc diagnosis from surgical procedure
        o_id_sr_epis_interv  OUT sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'SET_EPIS_SURG_INTERV';
        l_diagnosis     pk_edis_types.rec_in_epis_diagnosis;
    BEGIN
        g_error := 'i_lang:' || i_lang || ', i_prof.software:' || i_prof.software || ', i_prof.INSTITUTION:' ||
                   i_prof.institution || ', i_prof.ID_PROF:' || i_prof.id || ', i_dt_interv_start:' ||
                   i_dt_interv_start || ', i_dt_interv_end:' || i_dt_interv_end || ', i_id_episode:' || i_id_episode ||
                   ', i_id_sr_intervention:' || i_id_sr_intervention || ', i_flg_type:' || i_flg_type ||
                   ', i_flg_status:' || i_flg_status || ', i_dt_req:' || i_dt_req || ', i_name_interv:' ||
                   i_name_interv || ', i_laterality:' || i_laterality || ', i_id_diagnosis:' || i_id_diagnosis ||
                   ', i_diag_desc_sp:' || i_diag_desc_sp || ', i_notes:' || i_notes;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF i_id_sr_intervention IS NULL
        THEN
            -- dealing with a non coded intervention
            g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            IF NOT pk_sr_planning.set_epis_surg_unc_no_commit(i_lang                => i_lang,
                                                              i_id_episode          => i_id_episode,
                                                              i_id_episode_context  => i_id_episode,
                                                              i_name_interv         => table_varchar(i_name_interv),
                                                              i_prof                => i_prof,
                                                              i_id_patient          => NULL,
                                                              i_notes               => i_notes,
                                                              i_dt_interv_start     => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   i_dt_interv_start,
                                                                                                                   i_prof),
                                                              i_dt_interv_end       => pk_date_utils.date_send_tsz(i_lang,
                                                                                                                   i_dt_interv_end,
                                                                                                                   i_prof),
                                                              i_dt_req              => nvl(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                       i_dt_req,
                                                                                                                       i_prof),
                                                                                           current_timestamp),
                                                              i_id_epis_diagnosis   => NULL,
                                                              i_flg_type            => NULL,
                                                              i_laterality          => NULL,
                                                              i_surgical_site       => NULL,
                                                              i_id_not_order_reason => NULL,
                                                              o_id_sr_epis_interv   => o_id_sr_epis_interv,
                                                              o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            -- building object to save diagnoses
            g_error := 'CALL TO PK_DIAGNOSIS.GET_DIAG_REC';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            l_diagnosis := pk_diagnosis.get_diag_rec(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_patient   => NULL,
                                                     i_episode   => i_id_episode,
                                                     i_diagnosis => i_id_diagnosis,
                                                     i_desc_diag => i_diag_desc_sp);
        
            -- dealing with a coded intervention
            g_error := 'CALL TO PK_SR_VISIT.CREATE_ALL_SURGERY';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            IF NOT pk_surgery_request.set_epis_surg_interv_no_commit(i_lang                => i_lang,
                                                                     i_episode             => i_id_episode,
                                                                     i_episode_context     => i_id_episode,
                                                                     i_sr_intervention     => table_number(i_id_sr_intervention),
                                                                     i_codification        => table_number(NULL),
                                                                     i_laterality          => table_varchar(i_laterality),
                                                                     i_surgical_site       => table_varchar(NULL),
                                                                     i_prof                => i_prof,
                                                                     i_sp_notes            => table_varchar(i_notes),
                                                                     i_dt_interv_start     => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                        i_dt_interv_start,
                                                                                                                                        i_prof)),
                                                                     i_dt_interv_end       => table_varchar(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                        i_dt_interv_end,
                                                                                                                                        i_prof)),
                                                                     i_dt_req              => table_varchar(nvl(pk_date_utils.date_send_tsz(i_lang,
                                                                                                                                            i_dt_req,
                                                                                                                                            i_prof),
                                                                                                                current_timestamp)),
                                                                     i_flg_type            => table_varchar(i_flg_type),
                                                                     i_flg_status          => table_varchar(i_flg_status),
                                                                     i_flg_surg_request    => table_varchar(i_flg_surg_request),
                                                                     i_diagnosis_surg_proc => l_diagnosis,
                                                                     i_id_not_order_reason => NULL,
                                                                     o_id_sr_epis_interv   => o_id_sr_epis_interv,
                                                                     o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get surgery time for a specific visit.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_visit         Id visit
    * @param i_dt_begin         Start date for surgery time
    * @param i_dt_end           End date for surgery time
    * 
    * @param o_surgery_time_def Cursor with all type of surgery times.
    * @param o_surgery_times    Cursor with surgery times by visit.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Jorge Canossa
    * @since                    2010/10/24
       ********************************************************************************************/

    FUNCTION get_surgery_times_visit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_visit         IN visit.id_visit%TYPE,
        i_dt_begin         IN VARCHAR2 DEFAULT NULL,
        i_dt_end           IN VARCHAR2 DEFAULT NULL,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_SURGERY_TIMES_VISIT';
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.institution:' || i_prof.institution || ' i_prof.software:' ||
                   i_prof.software || ' i_prof.id:' || i_prof.id || ' i_id_visit:' || i_id_visit || ' i_dt_begin:' ||
                   i_dt_begin || ' i_dt_end:' || i_dt_end;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_SURG_RECORD.GET_SURGERY_TIMES_VISIT';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF NOT pk_sr_surg_record.get_surgery_times_visit(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_visit         => i_id_visit,
                                                         i_dt_begin         => i_dt_begin,
                                                         i_dt_end           => i_dt_end,
                                                         o_surgery_time_def => o_surgery_time_def,
                                                         o_surgery_times    => o_surgery_times,
                                                         o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_surgery_time_def);
            pk_types.open_my_cursor(o_surgery_times);
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
            pk_types.open_my_cursor(o_surgery_time_def);
            pk_types.open_my_cursor(o_surgery_times);
            RETURN FALSE;
    END;

    /********************************************************************************************
     * Set surgery times
     *
     * @param i_lang                 ID language
     * @param i_sr_surgery_time      ID Surgery time type
     * @param i_id_episode           ID episode
     * @param i_dt_surgery_time      Surgery time/date
     * @param i_prof                 Professional, institution and software IDs
     * @param i_test                 Test flag:  Y - validate
     *                                           N - execute 
     * @param i_dt_reg               Record date
     * 
     * @param o_flg_show             Show message: Y/N
     * @param o_msg_result           Message to show
     * @param o_title                Message title
     * @param o_button               Buttons to show: NC - Yes/No button
     *                                            C - Read button 
     * @param o_error                Error message
     *
     * @return                       TRUE/FALSE
     *
     * @author                       Jorge Canossa
     * @since                        2010/09/01
    ********************************************************************************************/

    FUNCTION set_surgery_time
    (
        i_lang            IN language.id_language%TYPE,
        i_sr_surgery_time IN sr_surgery_time.id_sr_surgery_time%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_dt_surgery_time IN VARCHAR2,
        i_prof            IN profissional,
        i_test            IN VARCHAR2,
        i_transaction_id  IN VARCHAR2,
        o_flg_show        OUT VARCHAR2,
        o_msg_result      OUT VARCHAR2,
        o_title           OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_flg_refresh     OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name          VARCHAR2(30) := 'SET_SURGERY_TIME';
        l_id_sr_surgery_time_det sr_surgery_time_det.id_sr_surgery_time_det%TYPE;
        l_transaction_id         VARCHAR2(4000);
    
    BEGIN
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        pk_alertlog.log_debug(g_error);
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(i_transaction_id, i_prof);
    
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.institution:' ||
                   i_prof.institution || ' i_prof.id:' || i_prof.id || 'i_id_episode:' || i_id_episode ||
                   'i_sr_surgery_time:' || i_sr_surgery_time || 'i_dt_surgery_time:' || i_dt_surgery_time || 'i_test:' ||
                   i_test;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_SURG_RECORD.SET_SURGERY_TIME';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF NOT pk_sr_surg_record.set_surgery_time(i_lang                   => i_lang,
                                                  i_sr_surgery_time        => i_sr_surgery_time,
                                                  i_episode                => i_id_episode,
                                                  i_dt_surgery_time        => i_dt_surgery_time,
                                                  i_prof                   => i_prof,
                                                  i_test                   => i_test,
                                                  i_dt_reg                 => NULL,
                                                  i_transaction_id         => l_transaction_id,
                                                  o_flg_show               => o_flg_show,
                                                  o_msg_result             => o_msg_result,
                                                  o_title                  => o_title,
                                                  o_button                 => o_button,
                                                  o_flg_refresh            => o_flg_refresh,
                                                  o_id_sr_surgery_time_det => l_id_sr_surgery_time_det,
                                                  o_error                  => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF i_transaction_id IS NULL
           AND l_transaction_id IS NOT NULL
        THEN
            g_error := 'call  pk_schedule_api_upstream.do_commit for id_transaction: ' || l_transaction_id;
            pk_alertlog.log_debug(g_error);
            pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Updates episode data
    *
    * @param i_id_episode       Episode ID
    * @param i_lang             Language ID
    * @param i_prof             Professional, institution and software IDs
    * @param i_dt_creation      Episode creation date
    * @param i_dt_begin         Episode begin date
    * @param i_flg_ehr          Episode type: N-Normal, S-Planning, E-EHR
    * @param i_id_dep_clin_serv Clinic service ID
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/08/20
    * @Notes                    ALERT-116342
         ********************************************************************************************/
    FUNCTION update_episode
    (
        i_id_episode       IN episode.id_episode%TYPE,
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dt_creation      IN episode.dt_creation%TYPE,
        i_dt_begin         IN episode.dt_begin_tstz%TYPE,
        i_flg_ehr          IN episode.flg_ehr%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'UPDATE_EPISODE';
        l_rowids        table_varchar;
    
    BEGIN
    
        g_error := 'i_id_episode: ' || i_id_episode || 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software ||
                   ' i_prof.INSTITUTION:' || i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_dt_creation:' ||
                   i_dt_creation || 'i_dt_begin:' || i_dt_begin || 'i_flg_ehr:' || i_flg_ehr || 'i_id_dep_clin_serv:' ||
                   i_id_dep_clin_serv;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        -- updates surgery data
        g_error := 'ts_episode.upd';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        ts_episode.upd(id_episode_in    => i_id_episode,
                       dt_creation_in   => i_dt_creation,
                       dt_begin_tstz_in => i_dt_begin,
                       flg_ehr_in       => i_flg_ehr,
                       rows_out         => l_rowids);
    
        g_error := 'PROCESS UPDATE';
        pk_alertlog.log_debug(g_error);
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'EPISODE',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        IF (i_id_episode IS NOT NULL AND (i_id_dep_clin_serv IS NOT NULL OR i_prof IS NOT NULL))
        THEN
            g_error := 'UPDATE EPIS_INFO';
            pk_alertlog.log_debug(g_error);
            ts_epis_info.upd(id_episode_in       => i_id_episode,
                             id_dep_clin_serv_in => i_id_dep_clin_serv,
                             id_professional_in  => i_prof.id,
                             rows_out            => l_rowids);
        
            g_error := 'EPIS_INFO PROCESS_UPDATE';
            pk_alertlog.log_debug(g_error);
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'EPIS_INFO',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END;

    /********************************************************************************************
    *  Updates an intervention  
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Professional data
    * @param i_id_sr_epis_interv      Intervention ID
    * @param i_dt_interv_start        Intervention start date
    * @param i_dt_interv_end          Intervention end date
    * @param i_id_sr_intervention     Intervention code ID
    * @param i_flg_type               Intervention type
    * @param i_flg_status             Intervention status
    * @param i_dt_req                 Request date
    * @param i_name_interv            Intervention name (not coded)
    * @param i_laterality             Laterality
    * @param i_id_diagnosis           Diagnosis ID
    * @param i_notes                  Intervention notes
    * @param i_flg_surg_request       Indicates if this surgical procedure was requested as part of the surgery/admission requests (Yes) or as part of proposed surgery (No)
    * @param i_diag_desc_sp           Desc diagnosis from the diagnosis of the surgical procedures
    
    * @param o_error                  Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/13
    * @Notes                    ALERT-
    ********************************************************************************************/
    FUNCTION update_epis_surg_interv
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_epis_interv  IN sr_epis_interv.id_sr_epis_interv%TYPE,
        i_dt_interv_start    IN sr_epis_interv.dt_interv_start_tstz%TYPE,
        i_dt_interv_end      IN sr_epis_interv.dt_interv_end_tstz%TYPE,
        i_id_sr_intervention IN sr_epis_interv.id_sr_intervention%TYPE,
        i_flg_type           IN sr_epis_interv.flg_type%TYPE,
        i_flg_status         IN sr_epis_interv.flg_status%TYPE,
        i_dt_req             IN sr_epis_interv.dt_req_tstz%TYPE,
        i_name_interv        IN sr_epis_interv.name_interv%TYPE,
        i_laterality         IN sr_epis_interv.laterality%TYPE,
        i_id_diagnosis       IN epis_diagnosis.id_diagnosis%TYPE,
        i_notes              IN sr_epis_interv.notes%TYPE,
        i_flg_surg_request   IN sr_epis_interv.flg_surg_request%TYPE,
        i_diag_desc_sp       IN epis_diagnosis.desc_epis_diagnosis%TYPE, --desc diagnosis from surgical procedure
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name         VARCHAR2(30) := 'UPDATE_EPIS_SURG_INTERV';
        l_id_episode            episode.id_episode%TYPE;
        l_tbl_id_epis_diagnosis pk_edis_types.table_out_epis_diags;
        l_id_epis_diagnosis     epis_diagnosis.id_epis_diagnosis%TYPE;
        l_rowids                table_varchar;
        l_flg_status_old        sr_epis_interv.flg_status%TYPE;
    
    BEGIN
        g_error := 'GET ID_EPISODE: i_id_sr_epis_interv: ' || i_id_sr_epis_interv;
        pk_alertlog.log_debug(g_error);
        SELECT nvl(sei.id_episode_context, sei.id_episode)
          INTO l_id_episode
          FROM sr_epis_interv sei
         WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv;
    
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_sr_epis_interv:' ||
                   i_id_sr_epis_interv || 'i_dt_interv_start:' || i_dt_interv_start || 'i_dt_interv_end:' ||
                   i_dt_interv_end || 'i_id_episode:' || i_id_sr_intervention || 'i_flg_type:' || i_flg_type ||
                   'i_flg_status:' || i_flg_status || 'i_dt_req:' || i_dt_req || 'i_name_interv:' || i_name_interv ||
                   'i_laterality:' || i_laterality || 'i_id_diagnosis:' || i_id_diagnosis || 'i_notes:' || i_notes;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF i_id_sr_intervention IS NULL
        THEN
            -- dealing with a non coded intervention
            g_error := 'UPDATE NON CODED SR_EPIS_INTERV SEI';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            g_error := 'get l_flg_status_old';
            BEGIN
                SELECT sei.flg_status
                  INTO l_flg_status_old
                  FROM sr_epis_interv sei
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv;
            EXCEPTION
                WHEN dup_val_on_index THEN
                    l_flg_status_old := NULL;
            END;
        
            ts_sr_epis_interv.upd(name_interv_in           => i_name_interv,
                                  name_interv_nin          => FALSE,
                                  id_prof_req_in           => i_prof.id,
                                  id_prof_req_nin          => FALSE,
                                  notes_in                 => i_notes,
                                  notes_nin                => FALSE,
                                  dt_interv_start_tstz_in  => i_dt_interv_start,
                                  dt_interv_start_tstz_nin => FALSE,
                                  dt_interv_end_tstz_in    => i_dt_interv_end,
                                  dt_interv_end_tstz_nin   => FALSE,
                                  dt_req_tstz_in           => i_dt_req,
                                  dt_req_tstz_nin          => FALSE,
                                  where_in                 => 'id_sr_epis_interv = ' || i_id_sr_epis_interv,
                                  rows_out                 => l_rowids);
        
            g_error := 'call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_EPIS_INTERV',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'call pk_sr_output.set_ia_event_prescription';
            IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_flg_action        => 'U',
                                                          i_id_sr_epis_interv => i_id_sr_epis_interv,
                                                          i_flg_status_new    => l_flg_status_old,
                                                          i_flg_status_old    => l_flg_status_old,
                                                          o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        ELSE
            -- dealing with a coded intervention
            g_error := 'UPDATE CODED SR_EPIS_INTERV SEI';
            pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
        
            g_error := 'CALL PK_DIAGNOSIS.CREATE_DIAGNOSIS_NO_COMMIT FOR ID_EPISODE ORIS  ' || l_id_episode;
            pk_alertlog.log_debug(g_error);
            -- call function to create/update diagnosis were associated surgical procedure
            IF NOT pk_diagnosis.set_epis_diagnosis(i_lang      => i_lang,
                                                   i_prof      => i_prof,
                                                   i_patient   => pk_episode.get_id_patient(i_episode => l_id_episode),
                                                   i_episode   => l_id_episode,
                                                   i_diagnosis => i_id_diagnosis,
                                                   i_desc_diag => i_diag_desc_sp,
                                                   o_params    => l_tbl_id_epis_diagnosis,
                                                   o_error     => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            l_id_epis_diagnosis := CASE
                                       WHEN l_tbl_id_epis_diagnosis IS NOT NULL
                                            AND l_tbl_id_epis_diagnosis.count > 0 THEN
                                        l_tbl_id_epis_diagnosis(1).id_epis_diagnosis
                                       ELSE
                                        NULL
                                   END;
        
            g_error := 'get l_flg_status_old';
            BEGIN
                SELECT sei.flg_status
                  INTO l_flg_status_old
                  FROM sr_epis_interv sei
                 WHERE sei.id_sr_epis_interv = i_id_sr_epis_interv;
            EXCEPTION
                WHEN dup_val_on_index THEN
                    l_flg_status_old := NULL;
            END;
        
            g_error := 'CALL ts_sr_epis_interv';
            ts_sr_epis_interv.upd(id_sr_intervention_in    => i_id_sr_intervention,
                                  id_sr_intervention_nin   => FALSE,
                                  laterality_in            => i_laterality,
                                  laterality_nin           => FALSE,
                                  id_epis_diagnosis_in     => l_id_epis_diagnosis,
                                  id_epis_diagnosis_nin    => FALSE,
                                  id_prof_req_in           => i_prof.id,
                                  id_prof_req_nin          => FALSE,
                                  notes_in                 => i_notes,
                                  notes_nin                => FALSE,
                                  dt_interv_start_tstz_in  => i_dt_interv_start,
                                  dt_interv_start_tstz_nin => FALSE,
                                  dt_interv_end_tstz_in    => i_dt_interv_end,
                                  dt_interv_end_tstz_nin   => FALSE,
                                  dt_req_tstz_in           => i_dt_req,
                                  dt_req_tstz_nin          => FALSE,
                                  flg_type_in              => i_flg_type,
                                  flg_type_nin             => FALSE,
                                  flg_status_in            => i_flg_status,
                                  flg_status_nin           => FALSE,
                                  flg_surg_request_in      => i_flg_surg_request,
                                  flg_surg_request_nin     => FALSE,
                                  where_in                 => 'id_sr_epis_interv = ' || i_id_sr_epis_interv,
                                  rows_out                 => l_rowids);
        
            g_error := 'call t_data_gov_mnt.process_update';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'SR_EPIS_INTERV',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
        
            g_error := 'call pk_sr_output.set_ia_event_prescription';
            IF NOT pk_sr_output.set_ia_event_prescription(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_flg_action        => 'U',
                                                          i_id_sr_epis_interv => i_id_sr_epis_interv,
                                                          i_flg_status_new    => i_flg_status,
                                                          i_flg_status_old    => l_flg_status_old,
                                                          o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Update intervention descriptions
    *
    * @param i_lang                      Language ID
    * @param i_prof                      Professional, institution and software IDs
    * @param i_id_sr_epis_interv_desc    Intervention description ID
    * @param i_desc_intervention         Intervention description
    * @param i_dt_interv_desc            Intervention description date
    * @param i_id_episode                Episode ID
    * @param i_id_sr_epis_interv         Intervention ID
    *
    *
    * @param o_error                     Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Sérgio Dias
    * @since                    2010/09/13
    * @Notes                    ALERT-118237
         ********************************************************************************************/
    FUNCTION update_interv_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_sr_epis_interv_desc IN sr_epis_interv_desc.id_sr_epis_interv_desc%TYPE,
        i_desc_intervention      IN sr_epis_interv_desc.desc_interv%TYPE,
        i_dt_interv_desc         IN sr_epis_interv_desc.dt_interv_desc_tstz%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_id_sr_epis_interv      IN sr_epis_interv.id_sr_epis_interv%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'UPDATE_INTERV_DESC';
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_sr_epis_interv_desc:' ||
                   i_id_sr_epis_interv_desc || 'i_desc_intervention:' || i_desc_intervention || 'i_dt_interv_desc:' ||
                   i_dt_interv_desc || 'i_id_episode:' || i_id_episode || 'i_id_sr_epis_interv:' || i_id_sr_epis_interv;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'UPDATE SR_EPIS_INTERV_DESC';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        UPDATE sr_epis_interv_desc seid
           SET seid.desc_interv         = i_desc_intervention,
               seid.dt_interv_desc_tstz = i_dt_interv_desc,
               seid.id_professional     = i_prof.id,
               seid.id_episode          = i_id_episode,
               seid.id_episode_context  = i_id_episode,
               seid.id_sr_epis_interv   = i_id_sr_epis_interv
         WHERE seid.id_sr_epis_interv_desc = i_id_sr_epis_interv_desc;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END update_interv_desc;

    /********************************************************************************************
    * Get surgery time for a specific episode.
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_episode       Id episode
    * 
    * @param o_surgery_time_def Cursor with all type of surgery times.
    * @param o_surgery_times    Cursor with surgery times by visit.
    * @param o_error            Error message
    *
    * @return                   TRUE/FALSE
    *
    * @author                   Jorge Canossa
    * @since                    2010/11/10
    ********************************************************************************************/

    FUNCTION get_surgery_times
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        o_surgery_time_def OUT pk_types.cursor_type,
        o_surgery_times    OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_SURGERY_TIMES';
    BEGIN
    
        g_error := 'i_lang:' || i_lang || ' i_prof.institution:' || i_prof.institution || ' i_prof.software:' ||
                   i_prof.software || ' i_prof.id:' || i_prof.id || ' i_id_episode:' || i_id_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        g_error := 'CALL TO PK_SR_SURG_RECORD.GET_SURGERY_TIMES';
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        IF NOT pk_sr_surg_record.get_surgery_times(i_lang             => i_lang,
                                                   i_software         => i_prof.software,
                                                   i_institution      => i_prof.institution,
                                                   i_episode          => i_id_episode,
                                                   o_surgery_time_def => o_surgery_time_def,
                                                   o_surgery_times    => o_surgery_times,
                                                   o_error            => o_error)
        THEN
            RAISE g_exception;
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
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_surgery_time_def);
            pk_types.open_my_cursor(o_surgery_times);
            RETURN FALSE;
    END get_surgery_times;

    /********************************************************************************************
    * Get surgical procedures summary page
    *
    * @param i_lang             Id language
    * @param i_prof             Professional, software and institution ids
    * @param i_id_patient       Patient Id
    * @param o_interv           Data cursor
    * @param o_labels           Labels cursor
    * @param o_error            Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   António Neto
    * @version                  2.6.1
    * @since                    2011-04-08
    *
    *********************************************************************************************/
    FUNCTION get_summ_interv
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        o_interv     OUT NOCOPY pk_types.cursor_type,
        o_labels     OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_call_summ_interv          EXCEPTION;
        o_interv_supplies           pk_types.cursor_type;
        l_interv_clinical_questions pk_types.cursor_type;
    BEGIN
        g_error := 'CALL PK_SR_PLANNING.GET_SUMM_INTERV_API';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.get_summ_interv_api(i_lang                      => i_lang,
                                                  i_prof                      => i_prof,
                                                  i_id_context                => i_id_patient,
                                                  i_flg_type_context          => pk_sr_planning.g_flg_type_context_pat_p,
                                                  o_interv                    => o_interv,
                                                  o_labels                    => o_labels,
                                                  o_interv_supplies           => o_interv_supplies,
                                                  o_interv_clinical_questions => l_interv_clinical_questions,
                                                  o_error                     => o_error)
        THEN
            RAISE l_call_summ_interv;
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
                                              'GET_SUMM_INTERV',
                                              o_error);
            pk_types.open_my_cursor(o_interv);
            pk_types.open_my_cursor(o_labels);
        
            RETURN FALSE;
    END get_summ_interv;

    /********************************************************************************************
    * Checks if some occurrence of a surgery with given surgical procedures was initiated (surgery start date)
    * after the given date.
    *
    * @param i_lang                  Id language
    * @param i_prof                  Professional, software and institution ids
    * @param i_id_patient            Patient Id
    * @param i_id_sr_intervention    Surgical Procedure Id
    * @param i_start_date            Lower date to be considered
    * @param o_flg_started_procedure Y-the surgical procedure was started after the given date. N-otherwise
    * @param o_id_epis_sr_interv     List with the epis_sr_interv
    * @param o_error                 Error Menssage
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sofia Mendes
    * @version                  2.6.1
    * @since                    19-Apr-2011
    *
    *********************************************************************************************/
    FUNCTION check_surg_procedure
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patiet             IN patient.id_patient%TYPE,
        i_id_sr_intervention    IN intervention.id_intervention%TYPE,
        i_start_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_flg_started_procedure OUT VARCHAR2,
        o_id_epis_sr_interv     OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SR_PLANNING.CHECK_SURG_PROCEDURE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.check_surg_procedure(i_lang                  => i_lang,
                                                   i_prof                  => i_prof,
                                                   i_id_patiet             => i_id_patiet,
                                                   i_id_sr_intervention    => i_id_sr_intervention,
                                                   i_start_date            => i_start_date,
                                                   o_flg_started_procedure => o_flg_started_procedure,
                                                   o_id_epis_sr_interv     => o_id_epis_sr_interv,
                                                   o_error                 => o_error)
        THEN
            RAISE l_internal_error;
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
                                              'CHECK_SURG_PROCEDURE',
                                              o_error);
        
            o_flg_started_procedure := pk_alert_constant.g_no;
            o_id_epis_sr_interv     := NULL;
            RETURN FALSE;
    END check_surg_procedure;

    /**************************************************************************
      * List of coded surgical procedures for an institution       
      *                                                                         
      * @param i_lang                   Language ID                             
      * @param i_prof                   Profissional ID                         
      *
      * @param o_surg_proc_list         List of coded surgical procedures 
    * @param o_error                  Error message 
    *           
    * @return                         TRUE/FALSE                                                             
    *
      * @author                         Filipe Silva                            
      * @version                        2.6.1                                 
      * @since                          2011/04/27                              
      **************************************************************************/
    FUNCTION get_coded_surgical_procedures
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_surg_proc_list OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_CODED_SURGICAL_PROCEDURES';
        l_exception     EXCEPTION;
    
    BEGIN
    
        g_error := 'CALL PK_SR_PLANNING.GET_CODED_SURGICAL_PROCEDURES FUNCTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_sr_planning.get_coded_surgical_procedures(i_lang           => i_lang,
                                                            i_prof           => i_prof,
                                                            o_surg_proc_list => o_surg_proc_list,
                                                            o_error          => o_error)
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
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_types.open_my_cursor(o_surg_proc_list);
            RETURN FALSE;
    END get_coded_surgical_procedures;

    /**************************************************************************
    * return coded surgical procedure description       
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_sr_intervention     Intervention ID                       
    *
    * @return                         Surgical procedure description                                                           
    *
    * @author                         Filipe Silva                            
    * @version                        2.6.1                                 
    * @since                          2011/04/27                              
    **************************************************************************/
    FUNCTION get_coded_surg_procedure_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_sr_intervention IN intervention.id_intervention%TYPE
    ) RETURN VARCHAR2 IS
    
        l_surg_proc_desc pk_translation.t_desc_translation;
    
    BEGIN
    
        l_surg_proc_desc := pk_sr_clinical_info.get_coded_surg_procedure_desc(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_id_sr_intervention => i_id_sr_intervention);
    
        RETURN l_surg_proc_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_coded_surg_procedure_desc;

    /**************************************************************************
    * Cancel the surgical procedures and the supplies were chosen by the professional.
    * For the other supplies, will be deleted the association of the surgical procedure.     
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             ORIS episode ID
    * @param i_cancel_reason          Cancel reason surgical procedure
    * @param i_notes                  Cancel notes
    *
    * @param o_error                  Error
    *                                                                         
    * @author                         Rita Lopes                            
    * @since                          2012/07/27                                 
    **************************************************************************/

    FUNCTION set_cancel_epis_surg_proc
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_cancel_reason IN sr_epis_interv.id_sr_cancel_reason%TYPE,
        i_notes         IN VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name      VARCHAR2(30) := 'SET_CANCEL_EPIS_SURG_PROC';
        l_id_supply_workflow table_number := table_number();
        l_id_supply          table_number := table_number();
    
        CURSOR c_epis_interv IS
            SELECT sei.id_sr_epis_interv
              FROM sr_epis_interv sei
             WHERE sei.id_episode_context = i_id_episode
               AND sei.flg_status != 'C';
    
    BEGIN
        g_error := 'i_lang:' || i_lang || ' i_prof.software:' || i_prof.software || ' i_prof.INSTITUTION:' ||
                   i_prof.institution || ' i_prof.ID_PROF:' || i_prof.id || 'i_id_episode:' || i_id_episode ||
                   'i_cancel_reason:' || i_cancel_reason || 'i_cancel_reason:' || i_cancel_reason;
        pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
    
        FOR i IN c_epis_interv
        LOOP
            SELECT sw.id_supply_workflow, sw.id_supply
              BULK COLLECT
              INTO l_id_supply_workflow, l_id_supply
              FROM supply_workflow sw
             WHERE sw.id_context = i.id_sr_epis_interv
               AND sw.flg_context = pk_supplies_constant.g_context_surgery
               AND sw.id_episode = i_id_episode
               AND sw.flg_status NOT IN (pk_supplies_constant.g_sww_cancelled);
        
            IF NOT pk_sr_planning.set_cancel_epis_surg_proc(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_id_sr_epis_interv   => i.id_sr_epis_interv,
                                                            i_sup_to_be_cancelled => l_id_supply,
                                                            i_sr_cancel_reason    => i_cancel_reason,
                                                            i_notes               => i_notes,
                                                            o_error               => o_error)
            THEN
                pk_utils.undo_changes;
                RETURN FALSE;
            END IF;
        
        END LOOP;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_function_name,
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_cancel_epis_surg_proc;

    FUNCTION get_surgery_episodes
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_start_dt IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        i_end_dt   IN TIMESTAMP WITH TIME ZONE DEFAULT NULL,
        o_episodes OUT table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30) := 'GET_SURGERY_EPISODES';
    BEGIN
    
        g_error := 'GET EPISODES FROM PK_SURGERY_REQUEST.GET_SR_EPISODES';
        SELECT t.id_episode
          BULK COLLECT
          INTO o_episodes
          FROM TABLE(pk_surgery_request.get_sr_episodes(i_lang, i_prof, i_patient, i_start_dt, i_end_dt)) t
         WHERE t.flg_status NOT IN (pk_alert_constant.g_adm_req_status_unde, pk_alert_constant.g_adm_req_status_canc);
    
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
    END get_surgery_episodes;

    /********************************************************************************************
    *  Get current state of surgical positioning for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_positionings_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_POSITIONINGS_STATUS';
        l_episodes      table_number := table_number();
        l_cnt_ongoing   NUMBER(24);
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- count all completed items
        SELECT COUNT(srp.flg_status) cnt
          INTO l_cnt_completed
          FROM sr_posit_req srp
         WHERE srp.id_episode_context IN (SELECT *
                                            FROM TABLE(l_episodes))
           AND srp.flg_status <> pk_sr_planning.g_posit_canc;
    
        -- count all ongoing items
        SELECT COUNT(srp.flg_status) cnt
          INTO l_cnt_ongoing
          FROM sr_posit_req srp
         WHERE srp.id_episode IN (SELECT *
                                    FROM TABLE(l_episodes))
           AND srp.flg_status = pk_sr_planning.g_posit_req;
    
        -- fill in viewer checklist flag
        IF l_cnt_ongoing > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
        ELSIF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_positionings_status;

    /********************************************************************************************
    *  Get current state of admission to the operating room for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_sr_receive_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_SR_RECEIVE_STATUS';
        l_episodes      table_number := table_number();
        l_flg_admitted  sr_receive.flg_status%TYPE := pk_alert_constant.g_no;
        l_flg_checklist VARCHAR2(1 CHAR);
        tbl_flag        table_varchar;
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- get admittion status - Y - admitted for surgery
        SELECT r.flg_status
        --  INTO l_flg_admitted
          BULK COLLECT
          INTO tbl_flag
          FROM sr_receive r
         WHERE r.id_episode IN (SELECT *
                                  FROM TABLE(l_episodes))
           AND r.dt_receive_tstz = (SELECT MAX(r1.dt_receive_tstz)
                                      FROM sr_receive r1
                                     WHERE r1.id_episode IN (SELECT *
                                                               FROM TABLE(l_episodes)));
    
        IF tbl_flag.count > 0
        THEN
            l_flg_admitted := tbl_flag(1);
        END IF;
    
        -- fill in viewer checklist flag
        IF l_flg_admitted = pk_alert_constant.g_yes
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_sr_receive_status;

    /********************************************************************************************
    *  Get current state of proposed surgery (surgical procedure) for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_proposed_sr_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_PROPOSED_SR_STATUS';
        l_episodes      table_number := table_number();
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
    
        SELECT COUNT(*)
          INTO l_cnt_completed
          FROM sr_epis_interv
         WHERE id_episode_context IN ((SELECT *
                                        FROM TABLE(l_episodes)))
           AND flg_status <> pk_sr_planning.g_interv_can; --not cancelled
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_proposed_sr_status;

    /********************************************************************************************
    *  Get current state of Pre-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_pre_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        --check template based areas: 
        /* General information (DOC_AREA: 14),
        surgery (DOC_AREA: 2), 
        anesthesia (DOC_AREA: 3), 
        Initial nursing assessment (DOC_AREA: 15),
        On the day of surgery (DOC_AREA: 4), 
        Pre-anesthesia visit (DOC_AREA: 5) 
        Before going to the Operating Room (DOC_AREA: 6)*/
        l_cnt_completed := pk_sr_evaluation.get_eval_register_count(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_scope_type  => i_scope_type,
                                                                    i_episode     => i_episode,
                                                                    i_patient     => i_patient,
                                                                    i_surg_period => pk_sr_evaluation.g_pre_op_period,
                                                                    i_type        => pk_sr_evaluation.g_eval_type_assess);
        /*
        Do not include: 
        Pharmacist assessment (DOC_AREA: 6701)
        POS validation (DOC_AREA: 6702)
         */
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_pre_op_eval_status;

    /********************************************************************************************
    *  Get current state of Intra-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_intra_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_cnt_completed   NUMBER(24);
        l_cnt_total_areas NUMBER(24);
        l_flg_checklist   VARCHAR2(1 CHAR);
    BEGIN
        l_cnt_completed := pk_sr_evaluation.get_eval_register_count(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_scope_type  => i_scope_type,
                                                                    i_episode     => i_episode,
                                                                    i_patient     => i_patient,
                                                                    i_surg_period => pk_sr_evaluation.g_intra_op_period,
                                                                    i_type        => pk_sr_evaluation.g_eval_type_assess);
    
        SELECT COUNT(*)
          INTO l_cnt_total_areas
          FROM sr_eval_type et
         WHERE et.id_surg_period = pk_sr_evaluation.g_intra_op_period;
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            IF l_cnt_completed = l_cnt_total_areas
            THEN
                l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
            ELSE
                l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
            END IF;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_intra_op_eval_status;

    /********************************************************************************************
    *  Get current state of post-operative assessment for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_post_op_eval_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_cnt_completed   NUMBER(24);
        l_cnt_total_areas NUMBER(24);
        l_flg_checklist   VARCHAR2(1 CHAR);
    BEGIN
        l_cnt_completed := pk_sr_evaluation.get_eval_register_count(i_lang        => i_lang,
                                                                    i_prof        => i_prof,
                                                                    i_scope_type  => i_scope_type,
                                                                    i_episode     => i_episode,
                                                                    i_patient     => i_patient,
                                                                    i_surg_period => pk_sr_evaluation.g_post_op_period,
                                                                    i_type        => pk_sr_evaluation.g_eval_type_assess);
    
        SELECT COUNT(*)
          INTO l_cnt_total_areas
          FROM sr_eval_summ sres
          JOIN institution i
            ON i.id_institution = sres.id_institution
          JOIN software s
            ON s.id_software = sres.id_software
         WHERE sres.id_surg_period = pk_sr_evaluation.g_post_op_period
           AND i.id_institution IN (i_prof.institution, 0)
           AND s.id_software IN (i_prof.software, 0)
           AND sres.flg_type = pk_sr_evaluation.g_eval_type_assess; --ID_EVALUATION
    
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            IF l_cnt_completed = l_cnt_total_areas
            THEN
                l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
            ELSE
                l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
            END IF;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_post_op_eval_status;

    /********************************************************************************************
    *  Get current state of intervention record for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_interv_rec_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_cnt_completed        NUMBER(24);
        l_cnt_completed_doc    NUMBER(24);
        l_cnt_completed_interv NUMBER(24);
        l_cnt_total_areas      NUMBER(24);
        l_flg_checklist        VARCHAR2(1 CHAR);
    BEGIN
        -- count all records from documentation 
        l_cnt_completed_doc := pk_sr_evaluation.get_eval_register_count(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_scope_type  => i_scope_type,
                                                                        i_episode     => i_episode,
                                                                        i_patient     => i_patient,
                                                                        i_surg_period => pk_sr_evaluation.g_intra_op_period,
                                                                        i_type        => pk_sr_evaluation.g_eval_type_record);
        --count all surgical procedures 
        l_cnt_completed_interv := pk_sr_planning.get_sr_interv_count(i_lang       => i_lang,
                                                                     i_prof       => i_prof,
                                                                     i_scope_type => i_scope_type,
                                                                     i_episode    => i_episode,
                                                                     i_patient    => i_patient);
        l_cnt_completed        := l_cnt_completed_doc;
        --if exists at least one surg proc add 1 to completed
        IF l_cnt_completed_interv > 0
        THEN
            l_cnt_completed := l_cnt_completed + 1;
        END IF;
        --count all areas
        SELECT COUNT(*)
          INTO l_cnt_total_areas
          FROM sr_eval_summ sres
          JOIN institution i
            ON i.id_institution = sres.id_institution
          JOIN software s
            ON s.id_software = sres.id_software
         WHERE sres.id_surg_period = pk_sr_evaluation.g_intra_op_period
           AND i.id_institution IN (i_prof.institution, 0)
           AND s.id_software IN (i_prof.software, 0)
           AND sres.flg_type = pk_sr_evaluation.g_eval_type_record --ID_EVALUATION
           AND sres.id_sr_eval_summ NOT IN (21); -- not  team
        -- fill in viewer checklist flag
        IF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
        RETURN l_flg_checklist;
    END get_interv_rec_status;
    /********************************************************************************************
    *  Get current state of surgical reserves for viewer checlist 
    *             
    * @param    i_lang           Language ID
    * @param    i_prof           Logged professional structure
    * @param    i_scope_type     Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param    i_id_episode     Episode ID
    * @param    i_id_patient     Patient ID
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                     
    * @version                    
    * @since                              
    **********************************************************************************************/
    FUNCTION get_reserves_viewer_check
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_patient    IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name     VARCHAR2(30 CHAR) := 'GET_RESERVES_VIEWER_CHECK';
        l_episodes      table_number := table_number();
        l_cnt_ongoing   NUMBER(24);
        l_cnt_completed NUMBER(24);
        l_flg_checklist VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET SCOPE EPISODES';
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_episodes := pk_episode.get_scope(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_patient    => i_patient,
                                           i_episode    => i_episode,
                                           i_flg_filter => i_scope_type);
        -- count all completed items
        SELECT COUNT(*) cnt
          INTO l_cnt_completed
          FROM sr_reserv_req srr
         INNER JOIN sr_equip se
            ON srr.id_sr_equip = se.id_sr_equip
         WHERE srr.id_episode IN (SELECT *
                                    FROM TABLE(l_episodes))
           AND srr.flg_status <> pk_sr_planning.g_equip_flg_type_c -- not canceled
           AND se.flg_hemo_yn = pk_alert_constant.g_yes;
    
        -- count all ongoing items
        SELECT COUNT(*) cnt
          INTO l_cnt_ongoing
          FROM sr_reserv_req srr
         INNER JOIN sr_equip se
            ON srr.id_sr_equip = se.id_sr_equip
         WHERE srr.id_episode IN (SELECT *
                                    FROM TABLE(l_episodes))
           AND srr.flg_status = pk_sr_planning.g_equip_flg_type_r -- requested
           AND se.flg_hemo_yn = pk_alert_constant.g_yes;
    
        -- fill in viewer checklist flag
        IF l_cnt_ongoing > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_ongoing;
        ELSIF l_cnt_completed > 0
        THEN
            l_flg_checklist := pk_viewer_checklist.g_checklist_completed;
        ELSE
            l_flg_checklist := pk_viewer_checklist.g_checklist_not_started;
        END IF;
    
        RETURN l_flg_checklist;
    END get_reserves_viewer_check;

    FUNCTION get_oris_episode_by_inpatient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        o_oris_episode OUT table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET EPISODES';
        SELECT we.id_episode
          BULK COLLECT
          INTO o_oris_episode
          FROM wtl_epis we
         WHERE we.id_waiting_list = (SELECT we1.id_waiting_list
                                       FROM wtl_epis we1
                                      WHERE we1.id_episode = i_episode)
           AND we.id_episode != i_episode
           AND we.id_epis_type = pk_alert_constant.g_epis_type_operating;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORIS_EPISODE_BY_INPATIENT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_oris_episode_by_inpatient;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_api_oris;
/
