-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 22/04/2015 09:11
-- CHANGE REASON: [ALERT-310275] 
DECLARE
    l_lang CONSTANT language.id_language%TYPE := 2;
    l_prof                profissional;
    l_id_co_sign          co_sign.id_co_sign%TYPE;
    l_id_co_sign_hist     co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;
    l_retval              BOOLEAN;
    l_error               t_error_out;

    l_exception EXCEPTION;
    l_error_str VARCHAR2(1000 CHAR);
    l_count     PLS_INTEGER;

    -- returns all comm orders with co-sign
    CURSOR c_comm_order_cosign IS
        SELECT cor.id_comm_order_req,
               cor.id_professional,
               cor.id_institution,
               nvl(ei.id_software,
                   (SELECT etsi.id_software
                      FROM epis_type et
                      JOIN epis_type_soft_inst etsi
                        ON etsi.id_epis_type = et.id_epis_type
                     WHERE et.flg_available = 'Y'
                       AND et.id_epis_type = epis.id_epis_type
                       AND etsi.id_institution = 0)) AS id_software,
               cor.id_episode,
               cor.id_patient,
               -- get first comm order req hist id
               (SELECT DISTINCT first_value(corh.id_comm_order_req_hist) over(ORDER BY corh.dt_status)
                  FROM comm_order_req_hist corh
                 WHERE corh.id_comm_order_req = cor.id_comm_order_req) AS id_comm_order_req_hist,
               cor.id_prof_req,
               cor.dt_req,
               -- co-sign data
               cor.id_order_type,
               cor.id_prof_order,
               cor.dt_order,
               cor.flg_co_sign,
               cor.id_prof_co_sign,
               cor.dt_co_sign,
               cor.notes_co_sign
          FROM comm_order_req cor
          JOIN episode epis
            ON epis.id_episode = cor.id_episode
          JOIN epis_info ei
            ON ei.id_episode = epis.id_episode
         WHERE cor.id_order_type IS NOT NULL
         ORDER BY cor.dt_req;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('######################## ERROR ##########################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || nvl(i_error.ora_sqlcode, SQLCODE));
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || nvl(i_error.ora_sqlerrm, SQLERRM));
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN

    -- create backup table
    l_error_str := 'create backup table';
    SELECT COUNT(1)
      INTO l_count
      FROM user_tables t
     WHERE t.table_name IN ('COMM_ORDER_REQ_CS_BCK', 'COMM_ORDER_REQ_HIST_CS_BCK');

    IF l_count = 0
    THEN
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_HIST_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        -- backup data
        dbms_output.put_line('Backup communication orders co-sign data...');
    
        l_error_str := 'backup COMM_ORDER_REQ table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_CS_BCK AS' || ' SELECT cor.*, current_timestamp AS mig_date' ||
                          ' FROM comm_order_req cor' || ' WHERE cor.id_order_type IS NOT NULL';
    
        l_error_str := 'backup COMM_ORDER_REQ_HIST table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_HIST_CS_BCK AS' ||
                          ' SELECT corh.*, current_timestamp AS mig_date' || ' FROM comm_order_req_hist corh' ||
                          ' WHERE corh.id_order_type IS NOT NULL';
    
        -- migration
        -- get all communication orders with co-sign
        l_error_str := 'get all communication orders with co-sign';
        FOR cor_rec IN c_comm_order_cosign
        LOOP
        
            dbms_output.put_line('Processing communication order [id_comm_order_req=' || cor_rec.id_comm_order_req ||
                                 ']...');
        
            -- check for communication orders' professional                            
            l_prof := profissional(cor_rec.id_professional, cor_rec.id_institution, cor_rec.id_software);
        
            -- create pending co-sign
            l_error_str := 'Calling alert.pk_co_sign_api.set_pending_co_sign_task function';
            l_retval    := pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                                   i_prof                   => l_prof,
                                                                   i_episode                => cor_rec.id_episode,
                                                                   i_id_co_sign             => NULL,
                                                                   i_id_task_type           => pk_alert_constant.g_task_comm_orders,
                                                                   i_id_action              => pk_comm_orders.g_cs_action_add,
                                                                   i_cosign_def_action_type => NULL,
                                                                   i_id_task                => cor_rec.id_comm_order_req_hist,
                                                                   i_id_task_group          => cor_rec.id_comm_order_req,
                                                                   i_id_order_type          => cor_rec.id_order_type,
                                                                   i_id_prof_created        => cor_rec.id_prof_req,
                                                                   i_id_prof_ordered_by     => cor_rec.id_prof_order,
                                                                   i_dt_created             => cor_rec.dt_req,
                                                                   i_dt_ordered_by          => cor_rec.dt_order,
                                                                   o_id_co_sign             => l_id_co_sign,
                                                                   o_id_co_sign_hist        => l_id_co_sign_hist,
                                                                   o_error                  => l_error);
        
            IF NOT l_retval
            THEN
                l_error_str := 'ERROR while calling alert.pk_co_sign.set_task_co_signed' || chr(10) || 'i_lang = ' ||
                               l_lang || chr(10) || 'i_lang = ' || l_lang || chr(10) || 'i_prof = (' ||
                               pk_utils.to_string(l_prof) || ')' || chr(10) || 'i_episode = ' || cor_rec.id_episode ||
                               chr(10) || 'i_id_co_sign = NULL' || chr(10) || 'i_id_task_type = ' ||
                               pk_alert_constant.g_task_comm_orders || chr(10) || 'i_id_action = ' ||
                               pk_comm_orders.g_cs_action_add || chr(10) || 'i_cosign_def_action_type = NULL' ||
                               chr(10) || 'i_id_task = ' || cor_rec.id_comm_order_req_hist || chr(10) ||
                               'i_id_task_group = ' || cor_rec.id_comm_order_req || chr(10) || 'i_id_order_type = ' ||
                               cor_rec.id_order_type || chr(10) || 'i_id_prof_created = ' || cor_rec.id_prof_req ||
                               chr(10) || 'i_id_prof_ordered_by = ' || cor_rec.id_prof_order || chr(10) ||
                               'i_dt_created = ' || cor_rec.dt_req || chr(10) || 'i_dt_ordered_by = ' ||
                               cor_rec.dt_order;
            
                RAISE l_exception;
            END IF;
        
            -- set task as co-signed
            IF cor_rec.flg_co_sign = pk_alert_constant.g_yes
            THEN
                l_error_str := 'Calling alert.pk_co_sign.set_task_co_signed function';
                l_retval    := pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                             i_prof                => l_prof,
                                                             i_episode             => cor_rec.id_episode,
                                                             i_tbl_id_co_sign      => table_number(l_id_co_sign),
                                                             i_id_prof_cosigned    => cor_rec.id_prof_co_sign,
                                                             i_dt_cosigned         => cor_rec.dt_co_sign,
                                                             i_cosign_notes        => cor_rec.notes_co_sign,
                                                             i_flg_made_auth       => pk_alert_constant.g_no,
                                                             o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                             o_error               => l_error);
            
                IF NOT l_retval
                THEN
                    l_error_str := 'ERROR while calling alert.pk_co_sign.set_task_co_signed' || chr(10) || 'i_lang = ' ||
                                   l_lang || chr(10) || 'i_prof = (' || pk_utils.to_string(l_prof) || ')' || chr(10) ||
                                   'i_episode = ' || cor_rec.id_episode || chr(10) || 'i_tbl_id_co_sign = [' ||
                                   pk_utils.to_string(table_number(l_id_co_sign)) || ']' || chr(10) ||
                                   'i_id_prof_cosigned = ' || cor_rec.id_prof_co_sign || chr(10) || 'i_dt_cosigned = ' ||
                                   cor_rec.dt_co_sign || chr(10) || 'i_cosign_notes = ' || cor_rec.notes_co_sign ||
                                   chr(10) || 'i_flg_made_auth = ''' || pk_alert_constant.g_no || '''';
                
                    RAISE l_exception;
                END IF;
            END IF;
        
            dbms_output.put_line('done.');
        
        END LOOP;
    
    ELSE
        dbms_output.put_line('Communication orders co-sign data already migrated.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        handle_error(i_msg => l_error_str, i_error => l_error);
        pk_alert_exceptions.reset_error_state();
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 24/04/2015 17:59
-- CHANGE REASON: [ALERT-310275] 
DECLARE
    l_lang CONSTANT language.id_language%TYPE := 2;
    l_prof                profissional;
    l_id_co_sign          co_sign.id_co_sign%TYPE;
    l_id_co_sign_hist     co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;
    l_retval              BOOLEAN;
    l_error               t_error_out;

    l_exception EXCEPTION;
    l_error_str VARCHAR2(1000 CHAR);
    l_count     PLS_INTEGER;

    -- returns all comm orders with co-sign
    CURSOR c_comm_order_cosign IS
        SELECT cor.id_comm_order_req,
               cor.id_professional,
               cor.id_institution,
               nvl(ei.id_software,
                   (SELECT etsi.id_software
                      FROM epis_type et
                      JOIN epis_type_soft_inst etsi
                        ON etsi.id_epis_type = et.id_epis_type
                     WHERE et.flg_available = 'Y'
                       AND et.id_epis_type = epis.id_epis_type
                       AND etsi.id_institution = 0)) AS id_software,
               cor.id_episode,
               cor.id_patient,
               -- get first comm order req hist id
               (SELECT DISTINCT first_value(corh.id_comm_order_req_hist) over(ORDER BY corh.dt_status)
                  FROM comm_order_req_hist corh
                 WHERE corh.id_comm_order_req = cor.id_comm_order_req) AS id_comm_order_req_hist,
               cor.id_prof_req,
               cor.dt_req,
               -- co-sign data
               cor.id_order_type,
               cor.id_prof_order,
               cor.dt_order,
               cor.flg_co_sign,
               cor.id_prof_co_sign,
               cor.dt_co_sign,
               cor.notes_co_sign
          FROM comm_order_req cor
          JOIN episode epis
            ON epis.id_episode = cor.id_episode
          JOIN epis_info ei
            ON ei.id_episode = epis.id_episode
         WHERE cor.id_order_type IS NOT NULL
   AND cor.id_episode IS NOT NULL
         ORDER BY cor.dt_req;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('######################## ERROR ##########################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || nvl(i_error.ora_sqlcode, SQLCODE));
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || nvl(i_error.ora_sqlerrm, SQLERRM));
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN

    -- create backup table
    l_error_str := 'create backup table';
    SELECT COUNT(1)
      INTO l_count
      FROM user_tables t
     WHERE t.table_name IN ('COMM_ORDER_REQ_CS_BCK', 'COMM_ORDER_REQ_HIST_CS_BCK');

    IF l_count = 0
    THEN
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_HIST_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        -- backup data
        dbms_output.put_line('Backup communication orders co-sign data...');
    
        l_error_str := 'backup COMM_ORDER_REQ table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_CS_BCK AS' || ' SELECT cor.*, current_timestamp AS mig_date' ||
                          ' FROM comm_order_req cor' || ' WHERE cor.id_order_type IS NOT NULL AND cor.id_episode IS NOT NULL';
    
        l_error_str := 'backup COMM_ORDER_REQ_HIST table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_HIST_CS_BCK AS' ||
                          ' SELECT corh.*, current_timestamp AS mig_date' || ' FROM comm_order_req_hist corh' ||
                          ' WHERE corh.id_order_type IS NOT NULL AND corh.id_episode IS NOT NULL';
    
        -- migration
        -- get all communication orders with co-sign
        l_error_str := 'get all communication orders with co-sign';
        FOR cor_rec IN c_comm_order_cosign
        LOOP
        
            dbms_output.put_line('Processing communication order [id_comm_order_req=' || cor_rec.id_comm_order_req ||
                                 ']...');
        
            -- check for communication orders' professional                            
            l_prof := profissional(cor_rec.id_professional, cor_rec.id_institution, cor_rec.id_software);
        
            -- create pending co-sign
            l_error_str := 'Calling alert.pk_co_sign_api.set_pending_co_sign_task function';
            l_retval    := pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                                   i_prof                   => l_prof,
                                                                   i_episode                => cor_rec.id_episode,
                                                                   i_id_co_sign             => NULL,
                                                                   i_id_task_type           => pk_alert_constant.g_task_comm_orders,
                                                                   i_id_action              => pk_comm_orders.g_cs_action_add,
                                                                   i_cosign_def_action_type => NULL,
                                                                   i_id_task                => cor_rec.id_comm_order_req_hist,
                                                                   i_id_task_group          => cor_rec.id_comm_order_req,
                                                                   i_id_order_type          => cor_rec.id_order_type,
                                                                   i_id_prof_created        => cor_rec.id_prof_req,
                                                                   i_id_prof_ordered_by     => cor_rec.id_prof_order,
                                                                   i_dt_created             => cor_rec.dt_req,
                                                                   i_dt_ordered_by          => cor_rec.dt_order,
                                                                   o_id_co_sign             => l_id_co_sign,
                                                                   o_id_co_sign_hist        => l_id_co_sign_hist,
                                                                   o_error                  => l_error);
        
            IF NOT l_retval
            THEN
                l_error_str := 'ERROR while calling alert.pk_co_sign.set_task_co_signed' || chr(10) || 'i_lang = ' ||
                               l_lang || chr(10) || 'i_lang = ' || l_lang || chr(10) || 'i_prof = (' ||
                               pk_utils.to_string(l_prof) || ')' || chr(10) || 'i_episode = ' || cor_rec.id_episode ||
                               chr(10) || 'i_id_co_sign = NULL' || chr(10) || 'i_id_task_type = ' ||
                               pk_alert_constant.g_task_comm_orders || chr(10) || 'i_id_action = ' ||
                               pk_comm_orders.g_cs_action_add || chr(10) || 'i_cosign_def_action_type = NULL' ||
                               chr(10) || 'i_id_task = ' || cor_rec.id_comm_order_req_hist || chr(10) ||
                               'i_id_task_group = ' || cor_rec.id_comm_order_req || chr(10) || 'i_id_order_type = ' ||
                               cor_rec.id_order_type || chr(10) || 'i_id_prof_created = ' || cor_rec.id_prof_req ||
                               chr(10) || 'i_id_prof_ordered_by = ' || cor_rec.id_prof_order || chr(10) ||
                               'i_dt_created = ' || cor_rec.dt_req || chr(10) || 'i_dt_ordered_by = ' ||
                               cor_rec.dt_order;
            
                RAISE l_exception;
            END IF;
        
            -- set task as co-signed
            IF cor_rec.flg_co_sign = pk_alert_constant.g_yes
            THEN
                l_error_str := 'Calling alert.pk_co_sign.set_task_co_signed function';
                l_retval    := pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                             i_prof                => l_prof,
                                                             i_episode             => cor_rec.id_episode,
                                                             i_tbl_id_co_sign      => table_number(l_id_co_sign),
                                                             i_id_prof_cosigned    => cor_rec.id_prof_co_sign,
                                                             i_dt_cosigned         => cor_rec.dt_co_sign,
                                                             i_cosign_notes        => cor_rec.notes_co_sign,
                                                             i_flg_made_auth       => pk_alert_constant.g_no,
                                                             o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                             o_error               => l_error);
            
                IF NOT l_retval
                THEN
                    l_error_str := 'ERROR while calling alert.pk_co_sign.set_task_co_signed' || chr(10) || 'i_lang = ' ||
                                   l_lang || chr(10) || 'i_prof = (' || pk_utils.to_string(l_prof) || ')' || chr(10) ||
                                   'i_episode = ' || cor_rec.id_episode || chr(10) || 'i_tbl_id_co_sign = [' ||
                                   pk_utils.to_string(table_number(l_id_co_sign)) || ']' || chr(10) ||
                                   'i_id_prof_cosigned = ' || cor_rec.id_prof_co_sign || chr(10) || 'i_dt_cosigned = ' ||
                                   cor_rec.dt_co_sign || chr(10) || 'i_cosign_notes = ' || cor_rec.notes_co_sign ||
                                   chr(10) || 'i_flg_made_auth = ''' || pk_alert_constant.g_no || '''';
                
                    RAISE l_exception;
                END IF;
            END IF;
        
            dbms_output.put_line('done.');
        
        END LOOP;
    
    ELSE
        dbms_output.put_line('Communication orders co-sign data already migrated.');
    END IF;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        handle_error(i_msg => l_error_str, i_error => l_error);
        pk_alert_exceptions.reset_error_state();
END;
/
-- CHANGE END: Ana Monteiro

-- CHANGED BY: Tiago Silva
-- CHANGE DATE: 11/05/2015
-- CHANGE REASON: [ALERT-310275] 
DECLARE
    l_lang CONSTANT language.id_language%TYPE := 2;
    l_prof                profissional;
    l_id_co_sign          co_sign.id_co_sign%TYPE;
    l_id_co_sign_hist     co_sign_hist.id_co_sign_hist%TYPE;
    l_tbl_id_co_sign_hist table_number;
    l_retval              BOOLEAN;
    l_error               t_error_out;

    l_exception EXCEPTION;
    l_error_str VARCHAR2(1000 CHAR);
    l_count     PLS_INTEGER;

    -- returns all comm orders with co-sign
    CURSOR c_comm_order_cosign IS
        SELECT *
          FROM (SELECT cor.id_comm_order_req,
                       cor.id_professional,
                       cor.id_institution,
                       nvl(ei.id_software,
                           (SELECT etsi.id_software
                              FROM epis_type et
                              JOIN epis_type_soft_inst etsi
                                ON etsi.id_epis_type = et.id_epis_type
                             WHERE et.flg_available = 'Y'
                               AND et.id_epis_type = epis.id_epis_type
                               AND etsi.id_institution = 0)) AS id_software,
                       cor.id_episode,
                       cor.id_patient,
                       -- obter id_comm_order_req_hist que:
                       -- se o registo de historico (para uma comm_order_req) tiver FLG_ACTION=ORDER, considera este registo, caso contrario considera o registo mais antigo (com os mesmos dados de co-sign)
                       (SELECT DISTINCT first_value(t.id_h) over(PARTITION BY(t.id_comm_order_req) ORDER BY decode(t.flg_action, 'ORDER', 0, 1), t.dt_status ASC) id_task
                          FROM (SELECT corh2.flg_action,
                                       cor2.id_comm_order_req,
                                       (CASE
                                            WHEN (corh2.id_order_type = cor2.id_order_type AND
                                                 corh2.id_prof_order = cor2.id_prof_order AND
                                                 corh2.dt_order = cor2.dt_order) -- co-sign excepto id_order_type in (7,9)
                                                 OR (corh2.id_order_type = cor2.id_order_type AND
                                                 cor2.id_order_type IN (7, 9) AND corh2.id_prof_order IS NULL AND
                                                 cor2.id_prof_order IS NULL AND corh2.dt_order = cor2.dt_order) -- id_prof=null e id_order_type in (7,9)
                                                 OR (corh2.id_order_type = cor2.id_order_type AND
                                                 corh2.id_prof_order IS NULL AND corh2.dt_order IS NULL) -- bug existente nos drafts
                                             THEN
                                             corh2.id_comm_order_req_hist
                                            ELSE
                                             0
                                        END) id_h,
                                       corh2.dt_status
                                  FROM alert.comm_order_req cor2
                                  JOIN alert.comm_order_req_hist corh2
                                    ON cor2.id_comm_order_req = corh2.id_comm_order_req
                                 WHERE cor2.id_order_type IS NOT NULL
                                   AND corh2.flg_action IN ('ORDER', 'EDITION', 'DRAFT')) t
                         WHERE t.id_h != 0
                           AND t.id_comm_order_req = cor.id_comm_order_req) AS id_comm_order_req_hist,
                       cor.id_prof_req,
                       cor.dt_req,
                       -- co-sign data
                       cor.id_order_type,
                       cor.id_prof_order,
                       cor.dt_order,
                       cor.flg_co_sign,
                       cor.id_prof_co_sign,
                       cor.dt_co_sign,
                       cor.notes_co_sign,
                       cor.id_status
                  FROM comm_order_req cor
                  JOIN episode epis
                    ON epis.id_episode = cor.id_episode
                  JOIN epis_info ei
                    ON ei.id_episode = epis.id_episode
                 WHERE cor.id_order_type IS NOT NULL
                   AND cor.id_episode IS NOT NULL) t2
         WHERE t2.id_comm_order_req_hist IS NOT NULL
         ORDER BY t2.dt_req;

    PROCEDURE handle_error
    (
        i_msg   IN VARCHAR2,
        i_error IN t_error_out
    ) IS
    BEGIN
        dbms_output.put_line('######################## ERROR ##########################');
        dbms_output.put_line('I_MSG: ' || i_msg);
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLCODE: ' || nvl(i_error.ora_sqlcode, SQLCODE));
        dbms_output.put_line(' ');
        dbms_output.put_line('ORA_SQLERRM: ' || nvl(i_error.ora_sqlerrm, SQLERRM));
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_DESC: ' || i_error.err_desc);
        dbms_output.put_line(' ');
        dbms_output.put_line('ERR_ACTION: ' || i_error.err_action);
        dbms_output.put_line(' ');
        dbms_output.put_line('LOG_ID: ' || i_error.log_id);
        dbms_output.put_line('*********************************************************');
    END handle_error;

BEGIN

    -- create backup table
    l_error_str := 'create backup table';
    SELECT COUNT(1)
      INTO l_count
      FROM user_tables t
     WHERE t.table_name IN ('COMM_ORDER_REQ_CS_BCK', 'COMM_ORDER_REQ_HIST_CS_BCK');

    IF l_count = 0
    THEN
        -- running the script for the first time
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        pk_frmw_objects.insert_into_frmw_objects(i_owner            => 'ALERT',
                                                 i_obj_name         => 'COMM_ORDER_REQ_HIST_CS_BCK',
                                                 i_obj_type         => 'TABLE',
                                                 i_flg_category     => 'DPC',
                                                 i_responsible_team => 'ORDER TOOLS');
    
        -- backup data
        dbms_output.put_line('Backup communication orders co-sign data...');
    
        l_error_str := 'backup and create COMM_ORDER_REQ table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_CS_BCK AS' || ' SELECT cor.id_comm_order_req,' ||
                          ' cor.id_workflow             ,' || ' cor.id_status               ,' ||
                          ' cor.id_patient              ,' || ' cor.id_episode              ,' ||
                          ' cor.id_concept_type         ,' || ' cor.id_concept_version      ,' ||
                          ' cor.id_cncpt_vrs_inst_owner ,' || ' cor.id_concept_term         ,' ||
                          ' cor.id_cncpt_trm_inst_owner ,' || ' cor.flg_free_text           ,' ||
                          ' cor.desc_concept_term       ,' || ' cor.id_prof_req             ,' ||
                          ' cor.id_inst_req             ,' || ' cor.dt_req                  ,' ||
                          ' cor.notes                   ,' || ' cor.clinical_indication     ,' ||
                          ' cor.flg_clinical_purpose    ,' || ' cor.clinical_purpose_desc   ,' ||
                          ' cor.flg_priority            ,' || ' cor.flg_prn                 ,' ||
                          ' cor.prn_condition           ,' || ' cor.dt_begin                ,' ||
                          ' cor.id_professional         ,' || ' cor.id_institution          ,' ||
                          ' cor.dt_status               ,' || ' cor.id_order_type           ,' ||
                          ' cor.id_prof_order           ,' || ' cor.dt_order                ,' ||
                          ' cor.flg_co_sign             ,' || ' cor.dt_co_sign              ,' ||
                          ' cor.id_prof_co_sign         ,' || ' cor.notes_co_sign           ,' ||
                          ' cor.notes_cancel            ,' || ' cor.id_cancel_reason        ,' ||
                          ' cor.create_user             ,' || ' cor.create_time             ,' ||
                          ' cor.create_institution      ,' || ' cor.update_user             ,' ||
                          ' cor.update_time             ,' || ' cor.update_institution      ,' ||
                          ' cor.flg_need_ack            ,' || ' cor.flg_action              ,' ||
                          ' cor.id_previous_status      , current_timestamp AS mig_date' || ' FROM comm_order_req cor' ||
                          ' WHERE cor.id_order_type IS NOT NULL AND cor.id_episode IS NOT NULL';
    
        l_error_str := 'backup and create COMM_ORDER_REQ_HIST table data';
        EXECUTE IMMEDIATE 'CREATE TABLE COMM_ORDER_REQ_HIST_CS_BCK AS' || ' SELECT corh.id_comm_order_req_hist  ,' ||
                          ' corh.id_comm_order_req       ,' || ' corh.id_workflow             ,' ||
                          ' corh.id_status               ,' || ' corh.id_patient              ,' ||
                          ' corh.id_episode              ,' || ' corh.id_concept_type         ,' ||
                          ' corh.id_concept_version      ,' || ' corh.id_cncpt_vrs_inst_owner ,' ||
                          ' corh.id_concept_term         ,' || ' corh.id_cncpt_trm_inst_owner ,' ||
                          ' corh.flg_free_text           ,' || ' corh.desc_concept_term       ,' ||
                          ' corh.id_prof_req             ,' || ' corh.id_inst_req             ,' ||
                          ' corh.dt_req                  ,' || ' corh.notes                   ,' ||
                          ' corh.clinical_indication     ,' || ' corh.flg_clinical_purpose    ,' ||
                          ' corh.clinical_purpose_desc   ,' || ' corh.flg_priority            ,' ||
                          ' corh.flg_prn                 ,' || ' corh.prn_condition           ,' ||
                          ' corh.dt_begin                ,' || ' corh.id_professional         ,' ||
                          ' corh.id_institution          ,' || ' corh.dt_status               ,' ||
                          ' corh.id_order_type           ,' || ' corh.id_prof_order           ,' ||
                          ' corh.dt_order                ,' || ' corh.flg_co_sign             ,' ||
                          ' corh.dt_co_sign              ,' || ' corh.id_prof_co_sign         ,' ||
                          ' corh.notes_co_sign           ,' || ' corh.notes_cancel            ,' ||
                          ' corh.id_cancel_reason        ,' || ' corh.create_user             ,' ||
                          ' corh.create_time             ,' || ' corh.create_institution      ,' ||
                          ' corh.update_user             ,' || ' corh.update_time             ,' ||
                          ' corh.update_institution      ,' || ' corh.flg_need_ack            ,' ||
                          ' corh.flg_action              ,' || ' corh.id_previous_status      ,' ||
                          ' corh.id_co_sign_hist         , current_timestamp AS mig_date' ||
                          ' FROM comm_order_req_hist corh' ||
                          ' WHERE corh.id_order_type IS NOT NULL AND corh.id_episode IS NOT NULL';
    
    ELSE
        -- running the script fot the nth time
    
        l_error_str := 'backup COMM_ORDER_REQ table data';
        EXECUTE IMMEDIATE 'INSERT INTO COMM_ORDER_REQ_CS_BCK ' || ' SELECT cor.id_comm_order_req, ' ||
                          ' cor.id_workflow             ,' || ' cor.id_status               ,' ||
                          ' cor.id_patient              ,' || ' cor.id_episode              ,' ||
                          ' cor.id_concept_type         ,' || ' cor.id_concept_version      ,' ||
                          ' cor.id_cncpt_vrs_inst_owner ,' || ' cor.id_concept_term         ,' ||
                          ' cor.id_cncpt_trm_inst_owner ,' || ' cor.flg_free_text           ,' ||
                          ' cor.desc_concept_term       ,' || ' cor.id_prof_req             ,' ||
                          ' cor.id_inst_req             ,' || ' cor.dt_req                  ,' ||
                          ' cor.notes                   ,' || ' cor.clinical_indication     ,' ||
                          ' cor.flg_clinical_purpose    ,' || ' cor.clinical_purpose_desc   ,' ||
                          ' cor.flg_priority            ,' || ' cor.flg_prn                 ,' ||
                          ' cor.prn_condition           ,' || ' cor.dt_begin                ,' ||
                          ' cor.id_professional         ,' || ' cor.id_institution          ,' ||
                          ' cor.dt_status               ,' || ' cor.id_order_type           ,' ||
                          ' cor.id_prof_order           ,' || ' cor.dt_order                ,' ||
                          ' cor.flg_co_sign             ,' || ' cor.dt_co_sign              ,' ||
                          ' cor.id_prof_co_sign         ,' || ' cor.notes_co_sign           ,' ||
                          ' cor.notes_cancel            ,' || ' cor.id_cancel_reason        ,' ||
                          ' cor.create_user             ,' || ' cor.create_time             ,' ||
                          ' cor.create_institution      ,' || ' cor.update_user             ,' ||
                          ' cor.update_time             ,' || ' cor.update_institution      ,' ||
                          ' cor.flg_need_ack            ,' || ' cor.flg_action              ,' ||
                          ' cor.id_previous_status      , current_timestamp AS mig_date' || ' FROM comm_order_req cor' ||
                          ' WHERE cor.id_order_type IS NOT NULL AND cor.id_episode IS NOT NULL';
    
        l_error_str := 'backup COMM_ORDER_REQ_HIST table data';
        EXECUTE IMMEDIATE 'INSERT INTO  COMM_ORDER_REQ_HIST_CS_BCK ' || ' SELECT corh.id_comm_order_req_hist, ' ||
                          ' corh.id_comm_order_req       ,' || ' corh.id_workflow             ,' ||
                          ' corh.id_status               ,' || ' corh.id_patient              ,' ||
                          ' corh.id_episode              ,' || ' corh.id_concept_type         ,' ||
                          ' corh.id_concept_version      ,' || ' corh.id_cncpt_vrs_inst_owner ,' ||
                          ' corh.id_concept_term         ,' || ' corh.id_cncpt_trm_inst_owner ,' ||
                          ' corh.flg_free_text           ,' || ' corh.desc_concept_term       ,' ||
                          ' corh.id_prof_req             ,' || ' corh.id_inst_req             ,' ||
                          ' corh.dt_req                  ,' || ' corh.notes                   ,' ||
                          ' corh.clinical_indication     ,' || ' corh.flg_clinical_purpose    ,' ||
                          ' corh.clinical_purpose_desc   ,' || ' corh.flg_priority            ,' ||
                          ' corh.flg_prn                 ,' || ' corh.prn_condition           ,' ||
                          ' corh.dt_begin                ,' || ' corh.id_professional         ,' ||
                          ' corh.id_institution          ,' || ' corh.dt_status               ,' ||
                          ' corh.id_order_type           ,' || ' corh.id_prof_order           ,' ||
                          ' corh.dt_order                ,' || ' corh.flg_co_sign             ,' ||
                          ' corh.dt_co_sign              ,' || ' corh.id_prof_co_sign         ,' ||
                          ' corh.notes_co_sign           ,' || ' corh.notes_cancel            ,' ||
                          ' corh.id_cancel_reason        ,' || ' corh.create_user             ,' ||
                          ' corh.create_time             ,' || ' corh.create_institution      ,' ||
                          ' corh.update_user             ,' || ' corh.update_time             ,' ||
                          ' corh.update_institution      ,' || ' corh.flg_need_ack            ,' ||
                          ' corh.flg_action              ,' || ' corh.id_previous_status      ,' ||
                          ' corh.id_co_sign_hist         , current_timestamp AS mig_date' ||
                          ' FROM comm_order_req_hist corh' ||
                          ' WHERE corh.id_order_type IS NOT NULL AND corh.id_episode IS NOT NULL';
    END IF;

    -- migration
    -- get all communication orders with co-sign
    l_error_str := 'get all communication orders with co-sign';
    FOR cor_rec IN c_comm_order_cosign
    LOOP
    
        dbms_output.put_line('Processing communication order [id_comm_order_req=' || cor_rec.id_comm_order_req ||
                             ']...');
    
        -- check for communication orders' professional                            
        l_prof := profissional(cor_rec.id_professional, cor_rec.id_institution, cor_rec.id_software);
    
        IF cor_rec.id_status = 503
        THEN
            -- create draft co-sign
            l_error_str := 'Calling alert.pk_co_sign_api.set_draft_co_sign_task function';
            l_retval    := pk_co_sign_api.set_draft_co_sign_task(i_lang               => l_lang,
                                                                 i_prof               => l_prof,
                                                                 i_episode            => cor_rec.id_episode,
                                                                 i_id_task_type       => pk_alert_constant.g_task_comm_orders,
                                                                 i_id_task            => cor_rec.id_comm_order_req_hist,
                                                                 i_id_task_group      => cor_rec.id_comm_order_req,
                                                                 i_id_order_type      => cor_rec.id_order_type,
                                                                 i_id_prof_created    => cor_rec.id_prof_req,
                                                                 i_id_prof_ordered_by => cor_rec.id_prof_order,
                                                                 i_dt_created         => cor_rec.dt_req,
                                                                 i_dt_ordered_by      => cor_rec.dt_order,
                                                                 o_id_co_sign         => l_id_co_sign,
                                                                 o_id_co_sign_hist    => l_id_co_sign_hist,
                                                                 o_error              => l_error);
        
            IF NOT l_retval
            THEN
                l_error_str := 'ERROR while calling alert.pk_co_sign.set_draft_co_sign_task' || chr(10) || 'i_lang = ' ||
                               l_lang || chr(10) || 'i_prof = (' || pk_utils.to_string(l_prof) || ')' || chr(10) ||
                               'i_episode = ' || cor_rec.id_episode || chr(10) || 'i_id_task_type = ' ||
                               pk_alert_constant.g_task_comm_orders || chr(10) || 'i_id_task = ' ||
                               cor_rec.id_comm_order_req_hist || chr(10) || 'i_id_task_group = ' ||
                               cor_rec.id_comm_order_req || chr(10) || 'i_id_order_type = ' || cor_rec.id_order_type ||
                               chr(10) || 'i_id_prof_created = ' || cor_rec.id_prof_req || chr(10) ||
                               'i_id_prof_ordered_by = ' || cor_rec.id_prof_order || chr(10) || 'i_dt_created = ' ||
                               cor_rec.dt_req || chr(10) || 'i_dt_ordered_by = ' || cor_rec.dt_order;
            
                RAISE l_exception;
            END IF;
        ELSE
        
            -- create pending co-sign
            l_error_str := 'Calling alert.pk_co_sign_api.set_pending_co_sign_task function';
            l_retval    := pk_co_sign_api.set_pending_co_sign_task(i_lang                   => l_lang,
                                                                   i_prof                   => l_prof,
                                                                   i_episode                => cor_rec.id_episode,
                                                                   i_id_co_sign             => NULL,
                                                                   i_id_co_sign_hist        => NULL,
                                                                   i_id_task_type           => pk_alert_constant.g_task_comm_orders,
                                                                   i_id_action              => pk_comm_orders.g_cs_action_add,
                                                                   i_cosign_def_action_type => NULL,
                                                                   i_id_task                => cor_rec.id_comm_order_req_hist,
                                                                   i_id_task_group          => cor_rec.id_comm_order_req,
                                                                   i_id_order_type          => cor_rec.id_order_type,
                                                                   --
                                                                   i_id_prof_created    => cor_rec.id_prof_req,
                                                                   i_id_prof_ordered_by => cor_rec.id_prof_order,
                                                                   --
                                                                   i_dt_created      => cor_rec.dt_req,
                                                                   i_dt_ordered_by   => cor_rec.dt_order,
                                                                   o_id_co_sign      => l_id_co_sign,
                                                                   o_id_co_sign_hist => l_id_co_sign_hist,
                                                                   o_error           => l_error);
        
            IF NOT l_retval
            THEN
                l_error_str := 'ERROR while calling alert.pk_co_sign.set_pending_co_sign_task' || chr(10) ||
                               'i_lang = ' || l_lang || chr(10) || 'i_prof = (' || pk_utils.to_string(l_prof) || ')' ||
                               chr(10) || 'i_episode = ' || cor_rec.id_episode || chr(10) || 'i_id_co_sign = NULL' ||
                               chr(10) || 'i_id_task_type = ' || pk_alert_constant.g_task_comm_orders || chr(10) ||
                               'i_id_action = ' || pk_comm_orders.g_cs_action_add || chr(10) ||
                               'i_cosign_def_action_type = NULL' || chr(10) || 'i_id_task = ' ||
                               cor_rec.id_comm_order_req_hist || chr(10) || 'i_id_task_group = ' ||
                               cor_rec.id_comm_order_req || chr(10) || 'i_id_order_type = ' || cor_rec.id_order_type ||
                               chr(10) || 'i_id_prof_created = ' || cor_rec.id_prof_req || chr(10) ||
                               'i_id_prof_ordered_by = ' || cor_rec.id_prof_order || chr(10) || 'i_dt_created = ' ||
                               cor_rec.dt_req || chr(10) || 'i_dt_ordered_by = ' || cor_rec.dt_order;
            
                RAISE l_exception;
            END IF;
        
            -- set task as co-signed
            IF cor_rec.flg_co_sign = pk_alert_constant.g_yes
            THEN
                l_error_str := 'Calling alert.pk_co_sign.set_task_co_signed function';
                l_retval    := pk_co_sign.set_task_co_signed(i_lang                => l_lang,
                                                             i_prof                => l_prof,
                                                             i_episode             => cor_rec.id_episode,
                                                             i_tbl_id_co_sign      => table_number(l_id_co_sign),
                                                             i_id_prof_cosigned    => cor_rec.id_prof_co_sign,
                                                             i_dt_cosigned         => cor_rec.dt_co_sign,
                                                             i_cosign_notes        => cor_rec.notes_co_sign,
                                                             i_flg_made_auth       => pk_alert_constant.g_no,
                                                             o_tbl_id_co_sign_hist => l_tbl_id_co_sign_hist,
                                                             o_error               => l_error);
            
                IF NOT l_retval
                THEN
                    l_error_str := 'ERROR while calling alert.pk_co_sign.set_task_co_signed' || chr(10) || 'i_lang = ' ||
                                   l_lang || chr(10) || 'i_prof = (' || pk_utils.to_string(l_prof) || ')' || chr(10) ||
                                   'i_episode = ' || cor_rec.id_episode || chr(10) || 'i_tbl_id_co_sign = [' ||
                                   pk_utils.to_string(table_number(l_id_co_sign)) || ']' || chr(10) ||
                                   'i_id_prof_cosigned = ' || cor_rec.id_prof_co_sign || chr(10) || 'i_dt_cosigned = ' ||
                                   cor_rec.dt_co_sign || chr(10) || 'i_cosign_notes = ' || cor_rec.notes_co_sign ||
                                   chr(10) || 'i_flg_made_auth = ''' || pk_alert_constant.g_no || '''';
                
                    RAISE l_exception;
                END IF;
            END IF;
        
        END IF;
    
        dbms_output.put_line('done.');
    
    END LOOP;

EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        handle_error(i_msg => l_error_str, i_error => l_error);
        pk_alert_exceptions.reset_error_state();
END;
/
-- CHANGE END: Tiago Silva