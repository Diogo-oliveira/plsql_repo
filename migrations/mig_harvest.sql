
DECLARE

    l_res_id_harvest            table_number;
    l_res_id_analysis_harvest   table_number;
    l_res_id_prof_harvest       table_number;
    l_res_id_prof_mov_tube      table_number;
    l_res_id_prof_receive_tube  table_number;
    l_res_id_room_harvest       table_number;
    l_res_id_room_receive_tube  table_number;
    l_res_id_prof_cancels       table_number;
    l_res_barcode               table_number;
    l_res_id_episode_write      table_number;
    l_res_flg_chargeable        table_number;
    l_res_id_cancel_reason      table_number;
    l_res_id_rep_coll_reason    table_number;
    l_res_dt_harvest_tstz       table_timestamp_tstz;
    l_res_dt_mov_begin_tstz     table_timestamp_tstz;
    l_res_dt_lab_reception_tstz table_timestamp_tstz;
    l_res_dt_cancel_tstz        table_timestamp_tstz;
    l_res_flg_status            table_varchar;
    l_res_flg_orig_harvest      table_varchar;
    l_res_dt_harvest_reg_tstz   table_varchar;
    l_res_id_harvest_group      table_varchar;
    l_res_flg_print             table_varchar;
    l_res_create_user           table_varchar;
    l_res_create_time           table_timestamp_tstz;
    l_res_create_institution    table_number;
    l_res_update_user           table_varchar;
    l_res_update_time           table_timestamp_tstz;
    l_res_update_institution    table_number;
    l_res_id_body_part          table_number;

    l_req_episode         table_number;
    l_req_id_visit        table_number;
    l_req_id_patient      table_number;
    l_req_id_room         table_number;
    l_req_id_room_harvest table_number;
    l_req_id_prof_writes  table_number;
    l_req_id_institution  table_number;
    l_req_id_software     table_number;

    l_new_harvest_ids table_number := table_number();
    l_old_id_harvest  table_number;

    i_prof         profissional;
    i_lang         PLS_INTEGER;
    l_count_result PLS_INTEGER;

    l_harvest_group  harvest.id_harvest_group%TYPE;
    l_new_id_harvest harvest.id_harvest%TYPE;
    lab_exception EXCEPTION;
    g_error VARCHAR2(4000 CHAR);
    o_error t_error_out;

    l_harvest_rowids          table_varchar;
    l_analysis_harvest_rowids table_varchar;

BEGIN

    g_error := 'SELECTS HARVEST/REQUISITION DATA';
    SELECT DISTINCT resultset.id_harvest,
                    resultset.id_analysis_harvest,
                    resultset.id_prof_harvest,
                    resultset.id_body_part,
                    resultset.id_prof_mov_tube,
                    resultset.id_prof_receive_tube,
                    resultset.id_room_harvest,
                    resultset.id_room_receive_tube,
                    resultset.id_prof_cancels,
                    resultset.barcode,
                    resultset.id_episode_write,
                    resultset.flg_chargeable,
                    resultset.id_cancel_reason,
                    resultset.id_rep_coll_reason,
                    resultset.flg_status,
                    resultset.flg_orig_harvest,
                    resultset.id_harvest_group,
                    resultset.flg_print,
                    resultset.dt_harvest_tstz,
                    resultset.dt_mov_begin_tstz,
                    resultset.dt_lab_reception_tstz,
                    resultset.dt_cancel_tstz,
                    resultset.create_user,
                    resultset.create_time,
                    resultset.create_institution,
                    resultset.update_user,
                    resultset.update_time,
                    resultset.update_institution,
                    ar.id_episode,
                    ar.id_visit,
                    ar.id_patient,
                    ard.id_room_req, --id_room
                    ard.id_room, -- id_room_harvest  
                    ar.id_prof_writes,
                    ar.id_institution,
                    ei.id_software,
                    ar.dt_req_tstz BULK COLLECT
      INTO l_res_id_harvest,
           l_res_id_analysis_harvest,
           l_res_id_prof_harvest,
           l_res_id_body_part,
           l_res_id_prof_mov_tube,
           l_res_id_prof_receive_tube,
           l_res_id_room_harvest,
           l_res_id_room_receive_tube,
           l_res_id_prof_cancels,
           l_res_barcode,
           l_res_id_episode_write,
           l_res_flg_chargeable,
           l_res_id_cancel_reason,
           l_res_id_rep_coll_reason,
           l_res_flg_status,
           l_res_flg_orig_harvest,
           l_res_id_harvest_group,
           l_res_flg_print,
           l_res_dt_harvest_tstz,
           l_res_dt_mov_begin_tstz,
           l_res_dt_lab_reception_tstz,
           l_res_dt_cancel_tstz,
           l_res_create_user,
           l_res_create_time,
           l_res_create_institution,
           l_res_update_user,
           l_res_update_time,
           l_res_update_institution,
           l_req_episode,
           l_req_id_visit,
           l_req_id_patient,
           l_req_id_room,
           l_req_id_room_harvest,
           l_req_id_prof_writes,
           l_req_id_institution,
           l_req_id_software,
           l_res_dt_harvest_reg_tstz
      FROM analysis_req_det ard,
           analysis_req ar,
           epis_info ei,
           (SELECT DISTINCT ah.id_harvest,
                            ah.id_analysis_harvest,
                            h.id_prof_harvest,  
                            h.flg_status,
                            h.id_body_part, 
                            h.id_prof_mov_tube, 
                            h.id_prof_receive_tube, 
                            h.id_room_harvest, 
                            h.id_room_receive_tube, 
                            h.id_prof_cancels, 
                            h.barcode, 
                            h.id_episode_write,  
                            h.flg_chargeable, 
                            h.id_patient,
                            h.flg_print,
                            h.dt_harvest_tstz,
                            h.dt_mov_begin_tstz,
                            h.dt_lab_reception_tstz,
                            h.dt_cancel_tstz,
                            h.id_cancel_reason, 
                            h.flg_orig_harvest,
                            h.id_harvest_group,
                            h.id_rep_coll_reason, 
                            h.id_episode,
                            h.create_user,
                            h.create_time,
                            h.create_institution,
                            h.update_user,
                            h.update_time,
                            h.update_institution,
                            ah.id_analysis_req_det
              FROM harvest h, analysis_harvest ah
             WHERE h.id_harvest = ah.id_harvest) resultset
     WHERE ard.id_analysis_req_det = resultset.id_analysis_req_det
       AND ar.id_episode != resultset.id_episode
       AND ar.id_patient != resultset.id_patient
       AND ar.id_analysis_req = ard.id_analysis_req
       AND ar.id_episode = ei.id_episode;

    g_error := 'SELECT OLD ID_HARVEST';
    SELECT ah.id_harvest BULK COLLECT
      INTO l_old_id_harvest
      FROM analysis_harvest ah
     WHERE ah.id_analysis_harvest IN (SELECT *
                                        FROM TABLE(l_res_id_analysis_harvest));

    g_error := 'ENTER PROCESS CYCLE';
    IF l_res_id_analysis_harvest.count != 0 AND (l_old_id_harvest.count = l_res_id_analysis_harvest.count)
    THEN
        
        g_error := 'Error on process loop : l_res_id_analysis_harvest.count = ' || l_res_id_analysis_harvest.count;    
        FOR i IN 1 .. l_res_id_analysis_harvest.count
        LOOP
        
            i_prof := profissional(l_req_id_prof_writes(i), l_req_id_institution(i), l_req_id_software(i));
            i_lang := to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                        l_req_id_institution(i),
                                                        l_req_id_software(i)));
            SELECT seq_harvest.nextval
              INTO l_new_id_harvest
              FROM dual;
        
            l_new_harvest_ids.extend;
            l_new_harvest_ids(l_new_harvest_ids.count) := l_new_id_harvest;
        
            g_error := 'INSERT INTO HARVEST';
            INSERT INTO harvest
                (id_harvest,
                 id_episode,
                 id_prof_harvest,
                 flg_status,
                 num_recipient,
                 notes,
                 id_body_part,
                 id_prof_mov_tube,
                 id_prof_receive_tube,
                 id_room_harvest,
                 id_room_receive_tube,
                 id_prof_cancels,
                 notes_cancel,
                 barcode,
                 id_institution,
                 id_episode_write,
                 dt_harvest_tstz,
                 dt_mov_begin_tstz,
                 dt_lab_reception_tstz,
                 dt_cancel_tstz,
                 flg_chargeable,
                 id_visit,
                 id_patient,
                 flg_print,
                 create_user,
                 create_time,
                 create_institution,
                 update_user,
                 update_time,
                 update_institution,
                 id_cancel_reason,
                 flg_orig_harvest,
                 dt_harvest_reg_tstz,
                 id_harvest_group,
                 id_rep_coll_reason)
            VALUES
                (l_new_id_harvest,
                 l_req_episode(i),
                 l_res_id_prof_harvest(i),
                 l_res_flg_status(i),
                 1,
                 NULL, --notes
                 l_res_id_body_part(i), --body_part
                 l_res_id_prof_mov_tube(i),
                 l_res_id_prof_receive_tube(i),
                 l_req_id_room_harvest(i),
                 l_req_id_room(i), -- id_room_receive_tube
                 l_res_id_prof_cancels(i),
                 NULL, --notes_cancel
                 l_res_barcode(i),
                 l_req_id_institution(i),
                 l_res_id_episode_write(i),
                 l_res_dt_harvest_tstz(i),
                 l_res_dt_mov_begin_tstz(i),
                 l_res_dt_lab_reception_tstz(i),
                 l_res_dt_cancel_tstz(i),
                 l_res_flg_chargeable(i),
                 l_req_id_visit(i), --id_visit
                 l_req_id_patient(i),
                 l_res_flg_print(i),
                 l_res_create_user(i), --create_user
                 l_res_create_time(i),
                 l_res_create_institution(i),
                 l_res_update_user(i),
                 l_res_update_time(i),
                 l_res_update_institution(i),
                 l_res_id_cancel_reason(i),
                 l_res_flg_orig_harvest(i),
                 l_res_dt_harvest_reg_tstz(i),
                 l_res_id_harvest_group(i),
                 l_res_id_rep_coll_reason(i));
        
            g_error := 'UPDATE ANALYSIS_HARVEST';
            UPDATE analysis_harvest ah
               SET ah.id_harvest = l_new_id_harvest
             WHERE ah.id_analysis_harvest = l_res_id_analysis_harvest(i);
        
        END LOOP;


    --checks if the changes were sucessfull
    g_error := 'Checking sucessfull changes';
    SELECT COUNT(*)
      INTO l_count_result
      FROM analysis_req_det ard,
           analysis_req ar,
           epis_info ei,
           (SELECT DISTINCT ah.id_harvest,
                            ah.id_analysis_harvest,
                            h.id_prof_harvest,  
                            h.flg_status,
                            h.id_body_part, 
                            h.id_prof_mov_tube, 
                            h.id_prof_receive_tube, 
                            h.id_room_harvest, 
                            h.id_room_receive_tube, 
                            h.id_prof_cancels, 
                            h.barcode, 
                            h.id_episode_write,  
                            h.flg_chargeable, 
                            h.id_patient,
                            h.flg_print,
                            h.dt_harvest_tstz,
                            h.dt_mov_begin_tstz,
                            h.dt_lab_reception_tstz,
                            h.dt_cancel_tstz,
                            h.id_cancel_reason, 
                            h.flg_orig_harvest,
                            h.id_harvest_group,
                            h.id_rep_coll_reason, 
                            h.id_episode,
                            h.create_user,
                            h.create_time,
                            h.create_institution,
                            h.update_user,
                            h.update_time,
                            h.update_institution,
                            h.id_body_part,
                            ah.id_analysis_req_det
              FROM harvest h, analysis_harvest ah
             WHERE h.id_harvest = ah.id_harvest) resultset
     WHERE ard.id_analysis_req_det = resultset.id_analysis_req_det
       AND ar.id_episode != resultset.id_episode
       AND ar.id_patient != resultset.id_patient
       AND ar.id_analysis_req = ard.id_analysis_req
       AND ar.id_episode = ei.id_episode;
   
    --the changes are sucessfull if no results are found
    IF l_count_result = 0
    THEN
        dbms_output.put_line('Success!Manual commit is now required!');
--        COMMIT;

    --if results are found, there is inconsistent data on the database 
    -- and process should be run again or further analysis will be required    
    ELSE
        dbms_output.put_line('Problems updating.Reverting changes.');
        dbms_output.put_line('Warning: no rollback was issued.Manual commit is required.');
    
        g_error := 'UPDATE ANALYSIS_HARVEST';
        FOR i in 1..l_res_id_analysis_harvest.count LOOP 
               
               UPDATE analysis_harvest ah
                 SET ah.id_harvest = l_old_id_harvest(i)
               WHERE ah.id_analysis_harvest = l_res_id_analysis_harvest(i);
        
        END LOOP; 

        g_error := 'DELETE FROM HARVEST';
        DELETE FROM harvest h
         WHERE h.id_harvest IN (SELECT *
                                  FROM TABLE(l_new_harvest_ids));
    
    END IF;

   ELSE 
       dbms_output.put_line('No changes were made.');
   
   END IF;
   
   
EXCEPTION
    WHEN lab_exception THEN
        dbms_output.put_line(g_error);
        dbms_output.put_line(SQLERRM);
    WHEN OTHERS THEN
        dbms_output.put_line(g_error);
        dbms_output.put_line(SQLERRM);
    
END;
/

-- CHANGED BY: carlos.nogueira
-- CHANGE DATE: 14/abr/2011 
-- CHANGE REASON: ALERT-172705

DECLARE

    l_res_id_harvest            table_number;
    l_res_id_analysis_harvest   table_number;
    l_res_id_prof_harvest       table_number;
    l_res_id_prof_mov_tube      table_number;
    l_res_id_prof_receive_tube  table_number;
    l_res_id_room_harvest       table_number;
    l_res_id_room_receive_tube  table_number;
    l_res_id_prof_cancels       table_number;
    l_res_barcode               table_number;
    l_res_id_episode_write      table_number;
    l_res_flg_chargeable        table_number;
    l_res_id_cancel_reason      table_number;
    l_res_id_rep_coll_reason    table_number;
    l_res_dt_harvest_tstz       table_timestamp_tstz;
    l_res_dt_mov_begin_tstz     table_timestamp_tstz;
    l_res_dt_lab_reception_tstz table_timestamp_tstz;
    l_res_dt_cancel_tstz        table_timestamp_tstz;
    l_res_flg_status            table_varchar;
    l_res_flg_orig_harvest      table_varchar;
    l_res_dt_harvest_reg_tstz   table_varchar;
    l_res_id_harvest_group      table_varchar;
    l_res_flg_print             table_varchar;
    l_res_create_user           table_varchar;
    l_res_create_time           table_timestamp_tstz;
    l_res_create_institution    table_number;
    l_res_update_user           table_varchar;
    l_res_update_time           table_timestamp_tstz;
    l_res_update_institution    table_number;
    l_res_id_body_part          table_number;

    l_req_episode         table_number;
    l_req_id_visit        table_number;
    l_req_id_patient      table_number;
    l_req_id_room         table_number;
    l_req_id_room_harvest table_number;
    l_req_id_prof_writes  table_number;
    l_req_id_institution  table_number;
    l_req_id_software     table_number;

    l_new_harvest_ids table_number := table_number();
    l_old_id_harvest  table_number;

    i_prof         profissional;
    i_lang         PLS_INTEGER;
    l_count_result PLS_INTEGER;

    l_harvest_group  harvest.id_harvest_group%TYPE;
    l_new_id_harvest harvest.id_harvest%TYPE;
    lab_exception EXCEPTION;
    g_error VARCHAR2(4000 CHAR);
    o_error t_error_out;

    l_harvest_rowids          table_varchar;
    l_analysis_harvest_rowids table_varchar;

BEGIN

    g_error := 'SELECTS HARVEST/REQUISITION DATA';
    SELECT DISTINCT resultset.id_harvest,
                    resultset.id_analysis_harvest,
                    resultset.id_prof_harvest,
                    resultset.id_body_part,
                    resultset.id_prof_mov_tube,
                    resultset.id_prof_receive_tube,
                    resultset.id_room_harvest,
                    resultset.id_room_receive_tube,
                    resultset.id_prof_cancels,
                    resultset.barcode,
                    resultset.id_episode_write,
                    resultset.flg_chargeable,
                    resultset.id_cancel_reason,
                    resultset.id_rep_coll_reason,
                    resultset.flg_status,
                    resultset.flg_orig_harvest,
                    resultset.id_harvest_group,
                    resultset.flg_print,
                    resultset.dt_harvest_tstz,
                    resultset.dt_mov_begin_tstz,
                    resultset.dt_lab_reception_tstz,
                    resultset.dt_cancel_tstz,
                    resultset.create_user,
                    resultset.create_time,
                    resultset.create_institution,
                    resultset.update_user,
                    resultset.update_time,
                    resultset.update_institution,
                    ar.id_episode,
                    ar.id_visit,
                    ar.id_patient,
                    ard.id_room_req, --id_room
                    ard.id_room, -- id_room_harvest  
                    ar.id_prof_writes,
                    ar.id_institution,
                    ei.id_software,
                    ar.dt_req_tstz BULK COLLECT
      INTO l_res_id_harvest,
           l_res_id_analysis_harvest,
           l_res_id_prof_harvest,
           l_res_id_body_part,
           l_res_id_prof_mov_tube,
           l_res_id_prof_receive_tube,
           l_res_id_room_harvest,
           l_res_id_room_receive_tube,
           l_res_id_prof_cancels,
           l_res_barcode,
           l_res_id_episode_write,
           l_res_flg_chargeable,
           l_res_id_cancel_reason,
           l_res_id_rep_coll_reason,
           l_res_flg_status,
           l_res_flg_orig_harvest,
           l_res_id_harvest_group,
           l_res_flg_print,
           l_res_dt_harvest_tstz,
           l_res_dt_mov_begin_tstz,
           l_res_dt_lab_reception_tstz,
           l_res_dt_cancel_tstz,
           l_res_create_user,
           l_res_create_time,
           l_res_create_institution,
           l_res_update_user,
           l_res_update_time,
           l_res_update_institution,
           l_req_episode,
           l_req_id_visit,
           l_req_id_patient,
           l_req_id_room,
           l_req_id_room_harvest,
           l_req_id_prof_writes,
           l_req_id_institution,
           l_req_id_software,
           l_res_dt_harvest_reg_tstz
      FROM analysis_req_det ard,
           analysis_req ar,
           epis_info ei,
           (SELECT DISTINCT ah.id_harvest,
                            ah.id_analysis_harvest,
                            h.id_prof_harvest,  
                            h.flg_status,
                            h.id_body_part, 
                            h.id_prof_mov_tube, 
                            h.id_prof_receive_tube, 
                            h.id_room_harvest, 
                            h.id_room_receive_tube, 
                            h.id_prof_cancels, 
                            h.barcode, 
                            h.id_episode_write,  
                            h.flg_chargeable, 
                            h.id_patient,
                            h.flg_print,
                            h.dt_harvest_tstz,
                            h.dt_mov_begin_tstz,
                            h.dt_lab_reception_tstz,
                            h.dt_cancel_tstz,
                            h.id_cancel_reason, 
                            h.flg_orig_harvest,
                            h.id_harvest_group,
                            h.id_rep_coll_reason, 
                            h.id_episode,
                            h.create_user,
                            h.create_time,
                            h.create_institution,
                            h.update_user,
                            h.update_time,
                            h.update_institution,
                            ah.id_analysis_req_det
              FROM harvest h, analysis_harvest ah
             WHERE h.id_harvest = ah.id_harvest) resultset
     WHERE ard.id_analysis_req_det = resultset.id_analysis_req_det
       AND ar.id_episode != resultset.id_episode
       AND ar.id_patient != resultset.id_patient
       AND ar.id_analysis_req = ard.id_analysis_req
       AND ar.id_episode = ei.id_episode;

    g_error := 'SELECT OLD ID_HARVEST';
    SELECT ah.id_harvest BULK COLLECT
      INTO l_old_id_harvest
      FROM analysis_harvest ah
     WHERE ah.id_analysis_harvest IN (SELECT *
                                        FROM TABLE(l_res_id_analysis_harvest));

    g_error := 'ENTER PROCESS CYCLE';
    IF l_res_id_analysis_harvest.count != 0 AND (l_old_id_harvest.count = l_res_id_analysis_harvest.count)
    THEN
        
        g_error := 'Error on process loop : l_res_id_analysis_harvest.count = ' || l_res_id_analysis_harvest.count;    
        FOR i IN 1 .. l_res_id_analysis_harvest.count
        LOOP
        
            i_prof := profissional(l_req_id_prof_writes(i), l_req_id_institution(i), l_req_id_software(i));
            i_lang := to_number(pk_sysconfig.get_config(pk_alert_constant.g_sys_config_def_language,
                                                        l_req_id_institution(i),
                                                        l_req_id_software(i)));
            SELECT seq_harvest.nextval
              INTO l_new_id_harvest
              FROM dual;
        
            l_new_harvest_ids.extend;
            l_new_harvest_ids(l_new_harvest_ids.count) := l_new_id_harvest;
        
            g_error := 'INSERT INTO HARVEST';
            INSERT INTO harvest
                (id_harvest,
                 id_episode,
                 id_prof_harvest,
                 flg_status,
                 num_recipient,
                 notes,
                 id_body_part,
                 id_prof_mov_tube,
                 id_prof_receive_tube,
                 id_room_harvest,
                 id_room_receive_tube,
                 id_prof_cancels,
                 notes_cancel,
                 barcode,
                 id_institution,
                 id_episode_write,
                 dt_harvest_tstz,
                 dt_mov_begin_tstz,
                 dt_lab_reception_tstz,
                 dt_cancel_tstz,
                 flg_chargeable,
                 id_visit,
                 id_patient,
                 flg_print,
                 create_user,
                 create_time,
                 create_institution,
                 update_user,
                 update_time,
                 update_institution,
                 id_cancel_reason,
                 flg_orig_harvest,
                 dt_harvest_reg_tstz,
                 id_harvest_group,
                 id_rep_coll_reason)
            VALUES
                (l_new_id_harvest,
                 l_req_episode(i),
                 l_res_id_prof_harvest(i),
                 l_res_flg_status(i),
                 1,
                 NULL, --notes
                 l_res_id_body_part(i), --body_part
                 l_res_id_prof_mov_tube(i),
                 l_res_id_prof_receive_tube(i),
                 l_req_id_room_harvest(i),
                 l_req_id_room(i), -- id_room_receive_tube
                 l_res_id_prof_cancels(i),
                 NULL, --notes_cancel
                 l_res_barcode(i),
                 l_req_id_institution(i),
                 l_res_id_episode_write(i),
                 l_res_dt_harvest_tstz(i),
                 l_res_dt_mov_begin_tstz(i),
                 l_res_dt_lab_reception_tstz(i),
                 l_res_dt_cancel_tstz(i),
                 l_res_flg_chargeable(i),
                 l_req_id_visit(i), --id_visit
                 l_req_id_patient(i),
                 l_res_flg_print(i),
                 l_res_create_user(i), --create_user
                 l_res_create_time(i),
                 l_res_create_institution(i),
                 l_res_update_user(i),
                 l_res_update_time(i),
                 l_res_update_institution(i),
                 l_res_id_cancel_reason(i),
                 l_res_flg_orig_harvest(i),
                 l_res_dt_harvest_reg_tstz(i),
                 l_res_id_harvest_group(i),
                 l_res_id_rep_coll_reason(i));
        
            g_error := 'UPDATE ANALYSIS_HARVEST';
            UPDATE analysis_harvest ah
               SET ah.id_harvest = l_new_id_harvest
             WHERE ah.id_analysis_harvest = l_res_id_analysis_harvest(i);
        
        END LOOP;


    --checks if the changes were sucessfull
    g_error := 'Checking sucessfull changes';
    SELECT COUNT(*)
      INTO l_count_result
      FROM analysis_req_det ard,
           analysis_req ar,
           epis_info ei,
           (SELECT DISTINCT ah.id_harvest,
                            ah.id_analysis_harvest,
                            h.id_prof_harvest,  
                            h.flg_status,
                            h.id_body_part, 
                            h.id_prof_mov_tube, 
                            h.id_prof_receive_tube, 
                            h.id_room_harvest, 
                            h.id_room_receive_tube, 
                            h.id_prof_cancels, 
                            h.barcode, 
                            h.id_episode_write,  
                            h.flg_chargeable, 
                            h.id_patient,
                            h.flg_print,
                            h.dt_harvest_tstz,
                            h.dt_mov_begin_tstz,
                            h.dt_lab_reception_tstz,
                            h.dt_cancel_tstz,
                            h.id_cancel_reason, 
                            h.flg_orig_harvest,
                            h.id_harvest_group,
                            h.id_rep_coll_reason, 
                            h.id_episode,
                            h.create_user,
                            h.create_time,
                            h.create_institution,
                            h.update_user,
                            h.update_time,
                            h.update_institution,
                            h.id_body_part,
                            ah.id_analysis_req_det
              FROM harvest h, analysis_harvest ah
             WHERE h.id_harvest = ah.id_harvest) resultset
     WHERE ard.id_analysis_req_det = resultset.id_analysis_req_det
       AND ar.id_episode != resultset.id_episode
       AND ar.id_patient != resultset.id_patient
       AND ar.id_analysis_req = ard.id_analysis_req
       AND ar.id_episode = ei.id_episode;
   
    --the changes are sucessfull if no results are found
    IF l_count_result = 0
    THEN
        dbms_output.put_line('Success!Manual commit is now required!');
--        COMMIT;

    --if results are found, there is inconsistent data on the database 
    -- and process should be run again or further analysis will be required    
    ELSE
        dbms_output.put_line('Problems updating.Reverting changes.');
        dbms_output.put_line('Warning: no rollback was issued.Manual commit is required.');
    
        g_error := 'UPDATE ANALYSIS_HARVEST';
        FOR i in 1..l_res_id_analysis_harvest.count LOOP 
               
               UPDATE analysis_harvest ah
                 SET ah.id_harvest = l_old_id_harvest(i)
               WHERE ah.id_analysis_harvest = l_res_id_analysis_harvest(i);
        
        END LOOP; 

        g_error := 'DELETE FROM HARVEST';
        DELETE FROM harvest h
         WHERE h.id_harvest IN (SELECT *
                                  FROM TABLE(l_new_harvest_ids));
    
    END IF;

   ELSE 
       dbms_output.put_line('No changes were made.');
   
   END IF;
   
   
EXCEPTION
    WHEN lab_exception THEN
        dbms_output.put_line(g_error);
        dbms_output.put_line(SQLERRM);
    WHEN OTHERS THEN
        dbms_output.put_line(g_error);
        dbms_output.put_line(SQLERRM);
    
END;
/

-- CHANGE END
