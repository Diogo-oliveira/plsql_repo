/*-- Last Change Revision: $Rev: 2055211 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-12 10:01:40 +0000 (dom, 12 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_lab_tests_harvest_core IS

    FUNCTION create_harvest_pending
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_patient          IN patient.id_patient%TYPE,
        i_episode          IN harvest.id_episode%TYPE,
        i_analysis_req     IN analysis_req.id_analysis_req%TYPE, --5
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_body_location    IN harvest.id_body_part%TYPE,
        i_laterality       IN harvest.flg_laterality%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_harvest IS
            SELECT aci.interval, aci.order_collection, aci.id_sample_recipient, ard.flg_status ard_flg_status
              FROM analysis_req_det ard, analysis_instit_soft ais, analysis_collection ac, analysis_collection_int aci
             WHERE ard.id_analysis_req_det = i_analysis_req_det
               AND ard.id_analysis = ais.id_analysis
               AND ard.id_sample_type = ais.id_sample_type
               AND ais.id_institution = i_prof.institution
               AND ais.id_software = i_prof.software
               AND ais.flg_available = pk_lab_tests_constant.g_available
               AND ais.flg_type IN (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
               AND ais.id_analysis_instit_soft = ac.id_analysis_instit_soft
               AND ac.flg_available = pk_lab_tests_constant.g_available
               AND ac.flg_status = pk_lab_tests_constant.g_active
               AND ac.id_analysis_collection = aci.id_analysis_collection
               AND aci.flg_available = pk_lab_tests_constant.g_available
             ORDER BY aci.order_collection;
    
        l_harvest c_harvest%ROWTYPE;
    
        l_current_id_harvest  harvest.id_harvest%TYPE;
        l_new_id_harvest      harvest.id_harvest%TYPE;
        l_harvest_group       harvest.id_harvest_group%TYPE;
        l_id_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
        l_id_analysis         analysis.id_analysis%TYPE;
        l_id_sample_type      sample_type.id_sample_type%TYPE;
        l_id_sample_recipient sample_recipient.id_sample_recipient%TYPE;
        l_num_recipient       analysis_instit_recipient.num_recipient%TYPE;
        l_flg_time            analysis_req_det.flg_time_harvest%TYPE;
        l_dt_target           analysis_req_det.dt_target_tstz%TYPE;
        l_id_room             room.id_room%TYPE;
        l_exec_institution    harvest.id_institution%TYPE;
        l_id_room_harvest     harvest.id_room_harvest%TYPE;
        l_flg_col_inst        harvest.flg_col_inst%TYPE;
        l_order_recurrence    analysis_req_det.id_order_recurrence%TYPE;
        l_episode             episode.id_episode%TYPE;
        l_flg_status          analysis_req_det.flg_status%TYPE;
        l_visit               visit.id_visit%TYPE;
    
        l_flg_recipient_dep   sys_config.value%TYPE := pk_sysconfig.get_config('RECIPIENT_DEPENDS_ON_LAB', i_prof);
        l_harvest_combine_gap sys_config.value%TYPE := pk_sysconfig.get_config('HARVEST_COMBINE_GAP', i_prof);
    
        l_generate_barcode sys_config.value%TYPE := pk_sysconfig.get_config('GENERATE_BARCODE_HARVEST', i_prof);
        l_barcode          VARCHAR2(50 CHAR);
        l_hashmap          pk_ia_external_info.tt_table_varchar;
    
        l_count_analysis_harvest NUMBER;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        OPEN c_harvest;
        FETCH c_harvest
            INTO l_harvest;
        g_found := c_harvest%FOUND;
        CLOSE c_harvest;
    
        IF g_found
        THEN
        
            FOR rec IN c_harvest
            LOOP
                -- Get Lab Test Request Data
                g_error := '1. Get Lab Test Request Data - With more than one collection';
                BEGIN
                    SELECT ard.id_analysis,
                           ard.id_sample_type,
                           decode(l_flg_recipient_dep,
                                  pk_lab_tests_constant.g_yes,
                                  decode(air.id_room, ard.id_room_req, air.id_sample_recipient, NULL),
                                  air.id_sample_recipient) id_sample_recipient,
                           air.num_recipient,
                           ard.flg_time_harvest,
                           pk_date_utils.add_to_ltstz(nvl(pk_date_utils.trunc_insttimezone(i_prof, l_dt_target, 'MI'),
                                                          pk_date_utils.trunc_insttimezone(i_prof,
                                                                                           ard.dt_target_tstz,
                                                                                           'MI')),
                                                      rec.interval,
                                                      'MINUTE') dt_harvest,
                           ard.id_room_req id_room,
                           ard.id_exec_institution id_exec_institution,
                           ard.id_room id_room_harvest,
                           ard.flg_col_inst,
                           ard.id_order_recurrence,
                           ar.id_episode,
                           ard.flg_status
                      INTO l_id_analysis,
                           l_id_sample_type,
                           l_id_sample_recipient,
                           l_num_recipient,
                           l_flg_time,
                           l_dt_target,
                           l_id_room,
                           l_exec_institution,
                           l_id_room_harvest,
                           l_flg_col_inst,
                           l_order_recurrence,
                           l_episode,
                           l_flg_status
                      FROM analysis_req_det          ard,
                           analysis_req              ar,
                           analysis_instit_soft      ais,
                           analysis_instit_recipient air
                     WHERE ard.id_analysis_req_det = i_analysis_req_det
                       AND ard.id_analysis_req = ar.id_analysis_req
                       AND ard.id_analysis = ais.id_analysis
                       AND ard.id_sample_type = ais.id_sample_type
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software
                       AND ais.flg_available = pk_lab_tests_constant.g_available
                       AND ais.flg_type IN
                           (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
                       AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                       AND ((rec.id_sample_recipient IS NOT NULL AND air.id_sample_recipient = rec.id_sample_recipient) OR
                           (rec.id_sample_recipient IS NULL AND air.flg_default = pk_lab_tests_constant.g_yes));
                EXCEPTION
                    WHEN no_data_found THEN
                        RAISE g_other_exception;
                END;
            
                l_visit := pk_visit.get_visit(l_episode, o_error);
            
                -- Check if any Harvest is Suitable to be Used for the Lab Test Requested
                g_error := 'Check if any Harvest is Suitable to be Used for the Lab Test Requested';
                IF l_harvest_combine_gap != 0
                   AND l_flg_status != pk_lab_tests_constant.g_analysis_draft
                THEN
                    BEGIN
                        SELECT t.id_harvest, t.num_recipient
                          INTO l_current_id_harvest, l_num_recipient
                          FROM (SELECT h.id_harvest,
                                       ah.num_recipient,
                                       ard.id_order_recurrence,
                                       MIN(pk_date_utils.trunc_insttimezone(i_prof, ard.dt_target_tstz, 'MI')) over(PARTITION BY h.id_harvest) AS min_dt_target
                                  FROM (SELECT *
                                          FROM analysis_harvest ah
                                         WHERE NOT EXISTS (SELECT 1
                                                  FROM analysis_harvest ah1
                                                 WHERE ah1.id_analysis_req_det = i_analysis_req_det
                                                   AND ah1.id_harvest = ah.id_harvest)) ah,
                                       harvest h,
                                       analysis_req_det ard,
                                       analysis_req ar
                                 WHERE h.id_patient = i_patient
                                   AND h.flg_status = pk_lab_tests_constant.g_harvest_pending
                                   AND h.id_harvest = ah.id_harvest
                                   AND (h.id_body_part = i_body_location OR
                                       (h.id_body_part IS NULL AND i_body_location IS NULL))
                                   AND (h.flg_laterality = i_laterality OR
                                       (h.flg_laterality IS NULL AND i_laterality IS NULL))
                                   AND (h.id_room_harvest = l_id_room_harvest OR
                                       (h.id_room_harvest IS NULL AND h.flg_col_inst = pk_lab_tests_constant.g_yes))
                                   AND (h.id_room_receive_tube = l_id_room OR
                                       (h.id_room_receive_tube IS NULL AND h.id_institution = l_exec_institution))
                                   AND ah.id_sample_recipient = l_id_sample_recipient
                                   AND ah.id_analysis_req_det = ard.id_analysis_req_det
                                   AND ard.flg_time_harvest = l_flg_time
                                   AND ard.flg_status != pk_lab_tests_constant.g_harvest_cancel
                                   AND ard.flg_prn = pk_lab_tests_constant.g_no
                                   AND ((ard.id_analysis_req = i_analysis_req AND l_order_recurrence IS NOT NULL) OR
                                       l_order_recurrence IS NULL)
                                   AND ard.id_sample_type = l_id_sample_type
                                   AND ard.id_analysis_req = ar.id_analysis_req
                                   AND ar.id_visit = l_visit
                                 ORDER BY dt_harvest_reg_tstz DESC) t
                         WHERE (l_dt_target BETWEEN min_dt_target AND
                               pk_date_utils.add_to_ltstz(min_dt_target, l_harvest_combine_gap, 'HOUR'))
                           AND rownum = 1;
                    
                        SELECT COUNT(1)
                          INTO l_count_analysis_harvest
                          FROM analysis_harvest a
                         INNER JOIN analysis_req_det b
                            ON a.id_analysis_req_det = b.id_analysis_req_det
                         WHERE a.id_harvest = l_current_id_harvest
                           AND b.id_analysis = l_id_analysis;
                    
                        IF l_count_analysis_harvest > 0
                        THEN
                            l_current_id_harvest := NULL;
                            l_num_recipient      := nvl(l_num_recipient, 1);
                        END IF;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_current_id_harvest := NULL;
                            l_num_recipient      := nvl(l_num_recipient, 1);
                    END;
                ELSE
                    l_current_id_harvest := NULL;
                    l_num_recipient      := nvl(l_num_recipient, 1);
                END IF;
            
                IF l_current_id_harvest IS NOT NULL
                THEN
                    -- Link Lab Test Request to a Existing Harvest to be Collected 
                    g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                    ts_analysis_harvest.ins(id_analysis_harvest_out => l_id_analysis_harvest,
                                            id_analysis_req_det_in  => i_analysis_req_det,
                                            id_harvest_in           => l_current_id_harvest,
                                            id_sample_recipient_in  => l_id_sample_recipient,
                                            num_recipient_in        => l_num_recipient,
                                            flg_status_in           => pk_lab_tests_constant.g_active,
                                            rows_out                => l_rows_out);
                
                ELSE
                
                    -- Get new ID_HARVEST_GROUP
                    g_error := 'Get new ID_HARVEST_GROUP';
                    SELECT seq_harvest_group.nextval
                      INTO l_harvest_group
                      FROM dual;
                
                    -- Create New Harvest
                    g_error := 'CALL TS_HARVEST.INS';
                    ts_harvest.ins(id_harvest_out          => l_new_id_harvest,
                                   id_harvest_group_in     => l_harvest_group,
                                   id_patient_in           => i_patient,
                                   id_episode_in           => i_episode,
                                   id_visit_in             => pk_visit.get_visit(i_episode, o_error),
                                   flg_status_in           => CASE
                                                                  WHEN l_harvest.ard_flg_status = pk_lab_tests_constant.g_analysis_draft THEN
                                                                   pk_lab_tests_constant.g_harvest_suspended
                                                                  ELSE
                                                                   CASE
                                                                       WHEN l_visit IS NOT NULL THEN
                                                                        CASE
                                                                            WHEN rec.order_collection = 0 THEN
                                                                             pk_lab_tests_constant.g_harvest_pending
                                                                            ELSE
                                                                             pk_lab_tests_constant.g_harvest_waiting
                                                                        END
                                                                       ELSE
                                                                        pk_lab_tests_constant.g_harvest_suspended
                                                                   END
                                                              END,
                                   dt_harvest_reg_tstz_in  => g_sysdate_tstz,
                                   dt_begin_harvest_in     => l_dt_target,
                                   num_recipient_in        => l_num_recipient,
                                   id_body_part_in         => i_body_location,
                                   flg_laterality_in       => i_laterality,
                                   flg_col_inst_in         => l_flg_col_inst,
                                   id_room_harvest_in      => l_id_room_harvest,
                                   id_institution_in       => CASE
                                                                  WHEN l_exec_institution IS NOT NULL THEN
                                                                   l_exec_institution
                                                                  ELSE
                                                                   i_prof.institution
                                                              END,
                                   id_room_receive_tube_in => l_id_room,
                                   flg_orig_harvest_in     => NULL,
                                   rows_out                => l_rows_out);
                
                    -- Harvest Data Governance Process
                    g_error := 'CALL PROCESS_INSERT FOR HARVEST';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    IF rec.order_collection = 0
                    THEN
                        g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_PENDING';
                        pk_ia_event_lab.harvest_pending(i_id_harvest     => l_new_id_harvest,
                                                        i_id_institution => i_prof.institution,
                                                        i_flg_old_status => NULL);
                    ELSE
                        g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_WAITING';
                        pk_ia_event_lab.harvest_waiting(i_id_harvest     => l_new_id_harvest,
                                                        i_id_institution => i_prof.institution);
                    END IF;
                
                    IF i_episode IS NOT NULL
                    THEN
                        -- Insert on Status Log Table
                        g_error := 'CALL T_TI_LOG.INS_LOG';
                        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_episode => i_episode,
                                           i_flg_status => CASE
                                                               WHEN rec.order_collection = 0 THEN
                                                                pk_lab_tests_constant.g_harvest_pending
                                                               ELSE
                                                                pk_lab_tests_constant.g_harvest_waiting
                                                           END,
                                           i_id_record  => l_new_id_harvest,
                                           i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                           o_error      => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                
                    l_rows_out := NULL;
                    -- Link Harvest Created to Lab Test Request
                    g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                    ts_analysis_harvest.ins(id_analysis_harvest_out => l_id_analysis_harvest,
                                            id_analysis_req_det_in  => i_analysis_req_det,
                                            id_harvest_in           => l_new_id_harvest,
                                            id_sample_recipient_in  => l_id_sample_recipient,
                                            num_recipient_in        => l_num_recipient,
                                            flg_status_in           => pk_lab_tests_constant.g_active,
                                            rows_out                => l_rows_out);
                
                    -- Check if Barcode is to be generated by the External System
                    IF l_generate_barcode = pk_lab_tests_constant.g_yes
                    THEN
                        g_error := 'Check GENERATE_BARCODE_HARVEST Configuration';
                        IF pk_sysconfig.get_config('GENERATE_BARCODE_IN_HARVEST', i_prof) = pk_lab_tests_constant.g_no
                        THEN
                            g_error := 'HASHMAP PARAMETERS';
                            l_hashmap('id_harvest') := table_varchar(to_char(l_new_id_harvest));
                        
                            g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_BARCODE_CODE';
                            IF NOT pk_ia_external_info.get_lab_barcode_code(i_prof    => i_prof,
                                                                            i_hashmap => l_hashmap,
                                                                            o_barcode => l_barcode,
                                                                            o_error   => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    END IF;
                END IF;
            
                -- Analysis Harvest Data Governance Process
                g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            END LOOP;
        ELSE
        
            -- Get Lab Test Request Data
            g_error := '2. Get Lab Test Request Data - one collection';
            BEGIN
                SELECT ard.id_analysis,
                       ard.id_sample_type,
                       decode(l_flg_recipient_dep,
                              pk_lab_tests_constant.g_yes,
                              decode(air.id_room, ard.id_room_req, air.id_sample_recipient, NULL),
                              air.id_sample_recipient) id_sample_recipient,
                       air.num_recipient,
                       ard.flg_time_harvest,
                       pk_date_utils.trunc_insttimezone(i_prof, ard.dt_target_tstz, 'MI') dt_target_tstz,
                       ard.id_room_req id_room,
                       ard.id_exec_institution id_exec_institution,
                       ard.id_room id_room_harvest,
                       ard.flg_col_inst,
                       ard.id_order_recurrence,
                       ar.id_episode,
                       ard.flg_status
                  INTO l_id_analysis,
                       l_id_sample_type,
                       l_id_sample_recipient,
                       l_num_recipient,
                       l_flg_time,
                       l_dt_target,
                       l_id_room,
                       l_exec_institution,
                       l_id_room_harvest,
                       l_flg_col_inst,
                       l_order_recurrence,
                       l_episode,
                       l_flg_status
                  FROM analysis_req_det ard, analysis_req ar, analysis_instit_soft ais, analysis_instit_recipient air
                 WHERE ard.id_analysis_req_det = i_analysis_req_det
                   AND ard.id_analysis_req = ar.id_analysis_req
                   AND ard.id_analysis = ais.id_analysis
                   AND ard.id_sample_type = ais.id_sample_type
                   AND ais.id_institution = i_prof.institution
                   AND ais.id_software = i_prof.software
                   AND ais.flg_available = pk_lab_tests_constant.g_available
                   AND ais.flg_type IN
                       (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
                   AND ais.id_analysis_instit_soft = air.id_analysis_instit_soft
                   AND air.flg_default = pk_lab_tests_constant.g_yes;
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE g_other_exception;
            END;
        
            l_visit := pk_visit.get_visit(l_episode, o_error);
        
            -- Check if any Harvest is Suitable to be Used for the Lab Test Requested
            g_error := 'Check if any Harvest is Suitable to be Used for the Lab Test Requested';
            IF l_harvest_combine_gap != 0
               AND l_flg_status != pk_lab_tests_constant.g_analysis_draft
            THEN
                BEGIN
                    SELECT t.id_harvest, t.num_recipient
                      INTO l_current_id_harvest, l_num_recipient
                      FROM (SELECT h.id_harvest,
                                   ah.num_recipient,
                                   ard.id_order_recurrence,
                                   MIN(pk_date_utils.trunc_insttimezone(i_prof, ard.dt_target_tstz, 'MI')) over(PARTITION BY h.id_harvest) AS min_dt_target
                              FROM (SELECT *
                                      FROM analysis_harvest ah
                                     WHERE NOT EXISTS (SELECT 1
                                              FROM analysis_harvest ah1
                                             WHERE ah1.id_analysis_req_det = i_analysis_req_det
                                               AND ah1.id_harvest = ah.id_harvest)) ah,
                                   harvest h,
                                   analysis_req_det ard,
                                   analysis_req ar
                             WHERE h.id_patient = i_patient
                               AND h.flg_status = pk_lab_tests_constant.g_harvest_pending
                               AND h.id_harvest = ah.id_harvest
                               AND (h.id_body_part = i_body_location OR
                                   (h.id_body_part IS NULL AND i_body_location IS NULL))
                               AND (h.flg_laterality = i_laterality OR
                                   (h.flg_laterality IS NULL AND i_laterality IS NULL))
                               AND (h.id_room_harvest = l_id_room_harvest OR
                                   (h.id_room_harvest IS NULL AND h.flg_col_inst = pk_lab_tests_constant.g_yes))
                               AND (h.id_room_receive_tube = l_id_room OR
                                   (h.id_room_receive_tube IS NULL AND h.id_institution = l_exec_institution))
                               AND ah.id_sample_recipient = l_id_sample_recipient
                               AND ah.id_analysis_req_det = ard.id_analysis_req_det
                               AND ard.flg_time_harvest = l_flg_time
                               AND ard.flg_status != pk_lab_tests_constant.g_harvest_cancel
                               AND ard.flg_prn = pk_lab_tests_constant.g_no
                               AND ((ard.id_analysis_req = i_analysis_req AND l_order_recurrence IS NOT NULL) OR
                                   l_order_recurrence IS NULL)
                               AND ard.id_sample_type = l_id_sample_type
                               AND ard.id_analysis_req = ar.id_analysis_req
                               AND ar.id_visit = l_visit
                             ORDER BY dt_harvest_reg_tstz DESC) t
                     WHERE (l_dt_target BETWEEN min_dt_target AND
                           pk_date_utils.add_to_ltstz(min_dt_target, l_harvest_combine_gap, 'HOUR'))
                       AND rownum = 1;
                
                    SELECT COUNT(1)
                      INTO l_count_analysis_harvest
                      FROM analysis_harvest a
                     INNER JOIN analysis_req_det b
                        ON a.id_analysis_req_det = b.id_analysis_req_det
                     WHERE a.id_harvest = l_current_id_harvest
                       AND b.id_analysis = l_id_analysis;
                
                    IF l_count_analysis_harvest > 0
                    THEN
                        l_current_id_harvest := NULL;
                        l_num_recipient      := nvl(l_num_recipient, 1);
                    END IF;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_current_id_harvest := NULL;
                        l_num_recipient      := nvl(l_num_recipient, 1);
                END;
            ELSE
                l_current_id_harvest := NULL;
                l_num_recipient      := nvl(l_num_recipient, 1);
            END IF;
        
            IF l_current_id_harvest IS NOT NULL
            THEN
            
                -- Link Lab Test Request to a Existing Harvest to be Collected 
                g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                ts_analysis_harvest.ins(id_analysis_harvest_out => l_id_analysis_harvest,
                                        id_analysis_req_det_in  => i_analysis_req_det,
                                        id_harvest_in           => l_current_id_harvest,
                                        id_sample_recipient_in  => l_id_sample_recipient,
                                        num_recipient_in        => l_num_recipient,
                                        flg_status_in           => pk_lab_tests_constant.g_active,
                                        rows_out                => l_rows_out);
            
            ELSE
            
                -- Get new ID_HARVEST_GROUP
                g_error := 'Get new ID_HARVEST_GROUP';
                SELECT seq_harvest_group.nextval
                  INTO l_harvest_group
                  FROM dual;
            
                -- Create New Harvest
                g_error := 'CALL TS_HARVEST.INS';
                ts_harvest.ins(id_harvest_out          => l_new_id_harvest,
                               id_harvest_group_in     => l_harvest_group,
                               id_patient_in           => i_patient,
                               id_episode_in           => i_episode,
                               id_visit_in             => pk_visit.get_visit(i_episode, o_error),
                               flg_status_in           => CASE
                                                              WHEN l_visit IS NOT NULL THEN
                                                               pk_lab_tests_constant.g_harvest_pending
                                                              ELSE
                                                               pk_lab_tests_constant.g_harvest_suspended
                                                          END,
                               dt_harvest_reg_tstz_in  => g_sysdate_tstz,
                               num_recipient_in        => l_num_recipient,
                               id_body_part_in         => i_body_location,
                               flg_laterality_in       => i_laterality,
                               flg_col_inst_in         => l_flg_col_inst,
                               id_room_harvest_in      => l_id_room_harvest,
                               id_institution_in       => CASE
                                                              WHEN l_exec_institution IS NOT NULL THEN
                                                               l_exec_institution
                                                              ELSE
                                                               i_prof.institution
                                                          END,
                               id_room_receive_tube_in => l_id_room,
                               flg_orig_harvest_in     => NULL,
                               rows_out                => l_rows_out);
            
                -- Harvest Data Governance Process
                g_error := 'CALL PROCESS_INSERT FOR HARVEST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                IF i_episode IS NOT NULL
                THEN
                    g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_PENDING';
                    pk_ia_event_lab.harvest_pending(i_id_harvest     => l_new_id_harvest,
                                                    i_id_institution => i_prof.institution,
                                                    i_flg_old_status => NULL);
                
                    -- Insert on Status Log Table
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_harvest_pending,
                                            i_id_record  => l_new_id_harvest,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                l_rows_out := NULL;
                -- Link Harvest Created to Lab Test Request
                g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                ts_analysis_harvest.ins(id_analysis_harvest_out => l_id_analysis_harvest,
                                        id_analysis_req_det_in  => i_analysis_req_det,
                                        id_harvest_in           => l_new_id_harvest,
                                        id_sample_recipient_in  => l_id_sample_recipient,
                                        num_recipient_in        => l_num_recipient,
                                        flg_status_in           => pk_lab_tests_constant.g_active,
                                        rows_out                => l_rows_out);
            
                -- Check if Barcode is to be generated by the External System
                IF l_generate_barcode = pk_lab_tests_constant.g_yes
                   AND i_episode IS NOT NULL
                THEN
                    g_error := 'Check GENERATE_BARCODE_HARVEST Configuration';
                    IF pk_sysconfig.get_config('GENERATE_BARCODE_IN_HARVEST', i_prof) = pk_lab_tests_constant.g_no
                    THEN
                        g_error := 'HASHMAP PARAMETERS';
                        l_hashmap('id_harvest') := table_varchar(to_char(l_new_id_harvest));
                    
                        g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_BARCODE_CODE';
                        IF NOT pk_ia_external_info.get_lab_barcode_code(i_prof    => i_prof,
                                                                        i_hashmap => l_hashmap,
                                                                        o_barcode => l_barcode,
                                                                        o_error   => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            END IF;
        
            -- Analysis Harvest Data Governance Process
            g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
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
                                              'CREATE_HARVEST_PENDING',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_harvest_pending;

    FUNCTION create_harvest_suspended
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_req IS
            SELECT ar.id_analysis_req, ar.id_episode, ar.id_patient
              FROM analysis_req_det ard, analysis_req ar
             WHERE ard.id_analysis_req_det = i_analysis_req_det
               AND ard.id_analysis_req = ar.id_analysis_req;
    
        l_analysis_req c_analysis_req%ROWTYPE;
    
        l_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
        l_harvest          table_number := table_number();
        l_body_location    table_number := table_number();
        l_laterality       table_varchar := table_varchar();
        l_barcode          table_varchar := table_varchar();
    
        l_new_id_harvest harvest.id_harvest%TYPE;
    
        l_rows_out table_varchar;
    
    BEGIN
    
        g_error := 'OPEN C_ANALYSIS_REQ';
        OPEN c_analysis_req;
        FETCH c_analysis_req
            INTO l_analysis_req;
        CLOSE c_analysis_req;
    
        g_error := 'SELECT ANALYSIS_HARVEST 1';
        SELECT h.id_harvest, h.id_body_part, h.flg_laterality, h.barcode
          BULK COLLECT
          INTO l_harvest, l_body_location, l_laterality, l_barcode
          FROM analysis_harvest ah, harvest h
         WHERE ah.id_analysis_req_det = i_analysis_req_det
           AND ah.id_harvest = h.id_harvest
           AND h.flg_status = pk_lab_tests_constant.g_harvest_suspended;
    
        FOR i IN 1 .. l_harvest.count
        LOOP
            g_error := 'SELECT ANALYSIS_HARVEST 2';
            SELECT ah.id_analysis_harvest
              INTO l_analysis_harvest
              FROM analysis_harvest ah
             WHERE ah.id_harvest = l_harvest(i)
               AND ah.id_analysis_req_det = i_analysis_req_det;
        
            l_rows_out := NULL;
            ts_analysis_harvest.del(id_analysis_harvest_in => l_analysis_harvest, rows_out => l_rows_out);
        
            g_error := 'CALL PROCESS_DELETE';
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            UPDATE grid_task_lab gtl
               SET gtl.id_harvest = NULL
             WHERE id_harvest = l_harvest(i);
        
            l_rows_out := NULL;
            ts_harvest.del(id_harvest_in => l_harvest(i), rows_out => l_rows_out);
        
            g_error := 'CALL PROCESS_DELETE';
            t_data_gov_mnt.process_delete(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.CREATE_HARVEST_PENDING';
            IF NOT pk_lab_tests_harvest_core.create_harvest_pending(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_patient          => l_analysis_req.id_patient,
                                                                    i_episode          => l_analysis_req.id_episode,
                                                                    i_analysis_req     => l_analysis_req.id_analysis_req,
                                                                    i_analysis_req_det => i_analysis_req_det,
                                                                    i_body_location    => l_body_location(i),
                                                                    i_laterality       => l_laterality(i),
                                                                    o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'SELECT HARVEST BARCODE';
            SELECT id_harvest
              INTO l_new_id_harvest
              FROM (SELECT h.id_harvest
                      FROM analysis_harvest ah, harvest h
                     WHERE ah.id_analysis_req_det = i_analysis_req_det
                       AND ah.id_harvest = h.id_harvest
                       AND h.flg_status = pk_lab_tests_constant.g_harvest_pending
                     ORDER BY h.dt_harvest_reg_tstz DESC)
             WHERE rownum = 1;
        
            l_rows_out := NULL;
        
            g_error := 'UPDATE HARVEST BARCODE';
            ts_harvest.upd(id_harvest_in => l_new_id_harvest,
                           barcode_in    => l_barcode(i),
                           barcode_nin   => FALSE,
                           rows_out      => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('BARCODE'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
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
                                              'CREATE_HARVEST_SUSPENDED',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END create_harvest_suspended;

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN harvest.id_episode%TYPE,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number, --5
        i_analysis_req_det          IN table_table_number,
        i_body_location             IN table_number,
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --15
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE, --20
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        i_revised_by                IN professional.id_professional%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req     table_number;
        l_analysis_req_det table_number;
        l_analysis_harvest table_number;
    
        l_barcode VARCHAR2(200 CHAR);
    
    BEGIN
        -- Check and validate input array's data
        IF i_harvest.count = 0
        THEN
            g_error := 'I_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_analysis_harvest.count = 0
        THEN
            g_error := 'I_ANALYSIS_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_analysis_req_det.count = 0
        THEN
            g_error := 'I_ANALYSIS_REQ_DET parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_harvest.count != i_analysis_harvest.count
           OR i_harvest.count != i_analysis_req_det.count
        THEN
            g_error := 'I_HARVEST array has different number of elements than I_ANALYSIS_HARVEST or I_ANALYSIS_REQ_DET';
            RAISE g_other_exception;
        END IF;
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            -- Convert arrays of arrays to array
            g_error            := 'Convert I_ANALYSIS_REQ_DET array of arrays to array';
            l_analysis_req_det := table_number();
            IF i_analysis_req_det(i).count > 0
            THEN
                FOR j IN i_analysis_req_det(i).first .. i_analysis_req_det(i).last
                LOOP
                    l_analysis_req_det.extend;
                    l_analysis_req_det(j) := i_analysis_req_det(i) (j);
                END LOOP;
            END IF;
        
            g_error            := 'Convert I_ANALYSIS_HARVEST array of arrays to array';
            l_analysis_harvest := table_number();
            IF i_analysis_harvest(i).count > 0
            THEN
                FOR j IN i_analysis_harvest(i).first .. i_analysis_harvest(i).last
                LOOP
                    l_analysis_harvest.extend;
                    l_analysis_harvest(j) := i_analysis_harvest(i) (j);
                END LOOP;
            END IF;
        
            IF pk_sysconfig.get_config('GENERATE_BARCODE_HARVEST', i_prof) = pk_lab_tests_constant.g_yes
            THEN
                BEGIN
                    SELECT h.barcode
                      INTO l_barcode
                      FROM harvest h
                     WHERE h.id_harvest = i_harvest(i)
                       AND h.barcode IS NOT NULL;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'No barcode from external system';
                        RAISE g_other_exception;
                END;
            END IF;
        
            IF i_harvest.count != i_analysis_harvest.count
               OR i_harvest.count != i_analysis_req_det.count
            THEN
                g_error := 'I_HARVEST array has different number of elements than I_ANALYSIS_HARVEST or I_ANALYSIS_REQ_DET';
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_COLLECT';
            IF NOT pk_lab_tests_harvest_core.set_harvest_collect(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_episode                   => i_episode,
                                                            i_harvest                   => i_harvest(i),
                                                            i_analysis_harvest          => l_analysis_harvest,
                                                            i_analysis_req_det          => l_analysis_req_det,
                                                            i_body_location             => i_body_location(i),
                                                            i_laterality                => CASE
                                                                                               WHEN i_laterality IS NOT NULL
                                                                                                    AND i_laterality.count > 0 THEN
                                                                                                i_laterality(i)
                                                                                               ELSE
                                                                                                NULL
                                                                                           END,
                                                            i_collection_method         => i_collection_method(i),
                                                            i_specimen_condition        => CASE
                                                                                               WHEN i_specimen_condition IS NOT NULL
                                                                                                    AND i_specimen_condition.count > 0 THEN
                                                                                                i_specimen_condition(i)
                                                                                               ELSE
                                                                                                NULL
                                                                                           END,
                                                            i_collection_room           => i_collection_room(i),
                                                            i_lab                       => i_lab(i),
                                                            i_exec_institution          => i_exec_institution(i),
                                                            i_sample_recipient          => i_sample_recipient(i),
                                                            i_num_recipient             => i_num_recipient(i),
                                                            i_collected_by              => i_collected_by(i),
                                                            i_collection_time           => i_collection_time(i),
                                                            i_collection_amount         => i_collection_amount(i),
                                                            i_collection_transportation => i_collection_transportation(i),
                                                            i_notes                     => i_notes(i),
                                                            i_flg_rep_collection        => i_flg_rep_collection,
                                                            i_rep_coll_reason           => i_rep_coll_reason,
                                                            i_flg_orig_harvest          => i_flg_orig_harvest,
                                                            i_revised_by                => i_revised_by,
                                                            o_error                     => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            SELECT t1.id_analysis_req
              BULK COLLECT
              INTO l_analysis_req
              FROM (SELECT COUNT(1) id_analysis_req_det_count, ard.id_analysis_req
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req_det IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                        *
                                                         FROM TABLE(l_analysis_req_det) t)
                       AND ard.flg_status IN
                           (pk_lab_tests_constant.g_analysis_toexec, pk_lab_tests_constant.g_analysis_collected)
                     GROUP BY ard.id_analysis_req) t1,
                   (SELECT COUNT(1) id_analysis_req_det_count, ard.id_analysis_req
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req_det IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                        *
                                                         FROM TABLE(l_analysis_req_det) t)
                       AND ard.flg_status != pk_lab_tests_constant.g_analysis_cancel
                     GROUP BY ard.id_analysis_req) t2
             WHERE t1.id_analysis_req_det_count = t2.id_analysis_req_det_count
               AND t1.id_analysis_req = t2.id_analysis_req;
        
            IF l_analysis_req IS NOT NULL
            THEN
                FOR i IN 1 .. l_analysis_req.count
                LOOP
                    g_error := 'CALL TO PK_IA_EVENT_LAB.ANALYSIS_ORDER_COLLECTED';
                    pk_ia_event_lab.analysis_order_collected(i_id_analysis_req => l_analysis_req(i),
                                                             i_id_institution  => i_prof.institution);
                
                END LOOP;
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
                                              'SET_HARVEST_COLLECT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_collect;

    FUNCTION set_harvest_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number, --5
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE, --10
        i_collection_room           IN VARCHAR2,
        i_lab                       IN analysis_room.id_room%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE, --15
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE,
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE, --20
        i_flg_rep_collection        IN VARCHAR2,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        i_revised_by                IN professional.id_professional%TYPE DEFAULT NULL,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_room(l_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE) IS
            SELECT ar.id_room, ard.id_analysis
              FROM analysis_room ar, analysis a, analysis_req_det ard, room r, department d
             WHERE ard.id_analysis_req_det = l_analysis_req_det
               AND a.id_analysis = ard.id_analysis
               AND ar.id_analysis = a.id_analysis
               AND ar.flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube
               AND ar.flg_available = pk_lab_tests_constant.g_available
               AND ar.flg_default = pk_lab_tests_constant.g_yes
               AND r.id_room = ar.id_room
               AND d.id_department = r.id_department
               AND ar.id_institution = i_prof.institution;
    
        CURSOR c_mov_recipient(l_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE) IS
            SELECT nvl(ais.flg_mov_recipient, pk_lab_tests_constant.g_yes) flg_mov_recipient, ais.harvest_instructions
              FROM analysis_req_det ard, analysis_instit_soft ais
             WHERE ard.id_analysis_req_det = l_analysis_req_det
               AND ais.id_analysis = ard.id_analysis
               AND ais.flg_type IN (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
               AND ais.id_institution = i_prof.institution
               AND ais.id_software = i_prof.software
               AND ais.flg_available = pk_lab_tests_constant.g_available;
    
        CURSOR c_barcode IS
            SELECT h.barcode
              FROM harvest h
             WHERE h.id_harvest = i_harvest
               AND h.barcode IS NOT NULL
               AND rownum = 1;
    
        l_patient    patient.id_patient%TYPE;
        l_visit      visit.id_visit%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_flg_type   episode.id_epis_type%TYPE;
        l_flg_status episode.flg_status%TYPE;
        l_id_room    epis_info.id_room%TYPE;
    
        l_prof_cat_type category.flg_type%TYPE;
    
        l_prof_dep_clin_serv harvest.prof_dep_clin_serv%TYPE;
    
        l_id_analysis_req analysis_req.id_analysis_req%TYPE;
        l_id_analysis     analysis_req_det.id_analysis%TYPE;
        l_flg_time        analysis_req_det.flg_time_harvest%TYPE;
    
        l_sample_recipient analysis_harvest.id_sample_recipient%TYPE;
        l_num_recipient    analysis_harvest.num_recipient%TYPE;
    
        l_harvest_status        harvest.flg_status%TYPE;
        l_dt_lab_reception_tstz harvest.dt_lab_reception_tstz%TYPE;
        l_id_prof_receive_tube  harvest.id_prof_receive_tube%TYPE;
    
        l_flg_execute          analysis_instit_soft.flg_execute%TYPE;
        l_flg_mov_recipient    analysis_instit_soft.flg_mov_recipient%TYPE;
        l_harvest_instructions analysis_instit_soft.harvest_instructions%TYPE;
    
        l_room_default analysis_room.id_room%TYPE;
        l_room_prev    analysis_room.id_room%TYPE;
    
        l_desc_room           VARCHAR2(1000 CHAR);
        l_dt_entrance_room    VARCHAR2(100 CHAR);
        l_dt_last_interaction VARCHAR2(100 CHAR);
        l_dt_movement         VARCHAR2(100 CHAR);
    
        l_generate_barcode sys_config.value%TYPE := pk_sysconfig.get_config('GENERATE_BARCODE_IN_HARVEST', i_prof);
        l_barcode          VARCHAR2(50 CHAR);
        l_hashmap          pk_ia_external_info.tt_table_varchar;
    
        l_harvest    harvest.id_harvest%TYPE;
        l_dt_harvest harvest.dt_begin_harvest%TYPE;
    
        l_status analysis_req_det.flg_status%TYPE;
    
        l_continue   BOOLEAN;
        l_technician BOOLEAN;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_error        := 'Initialize Variables';
        l_continue     := TRUE;
        g_sysdate_tstz := current_timestamp;
    
        -- Get Patient and Visit ID 
        g_error := 'Get PATIENT and VISIT';
        SELECT e.id_patient, e.id_visit
          INTO l_patient, l_visit
          FROM episode e
         WHERE e.id_episode = i_episode
           FOR UPDATE;
    
        -- Get Prof Category
        g_error         := 'Get PROF_CAT_TYPE';
        l_prof_cat_type := pk_prof_utils.get_category(i_lang, i_prof);
    
        -- Check actual pacient location 
        g_error := 'CALL PK_VISIT.GET_EPIS_INFO';
        IF NOT pk_visit.get_epis_info(i_lang                => i_lang,
                                      i_id_episode          => i_episode,
                                      i_prof                => i_prof,
                                      o_flg_type            => l_flg_type,
                                      o_flg_status          => l_flg_status,
                                      o_id_room             => l_id_room,
                                      o_desc_room           => l_desc_room,
                                      o_dt_entrance_room    => l_dt_entrance_room,
                                      o_dt_last_interaction => l_dt_last_interaction,
                                      o_dt_movement         => l_dt_movement,
                                      o_error               => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_continue
        THEN
            -- Check if it is a repeat harvest
            g_error := 'Check if it is a repeat harvest';
            IF i_flg_rep_collection = pk_lab_tests_constant.g_yes
            THEN
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_REPEAT';
                IF NOT pk_lab_tests_harvest_core.set_harvest_repeat(i_lang                      => i_lang,
                                                                    i_prof                      => i_prof,
                                                                    i_patient                   => l_patient,
                                                                    i_visit                     => l_visit,
                                                                    i_episode                   => i_episode,
                                                                    i_harvest                   => i_harvest,
                                                                    i_analysis_harvest          => i_analysis_harvest,
                                                                    i_analysis_req_det          => i_analysis_req_det,
                                                                    i_body_location             => i_body_location,
                                                                    i_laterality                => i_laterality,
                                                                    i_collection_method         => i_collection_method,
                                                                    i_specimen_condition        => i_specimen_condition,
                                                                    i_collection_room           => i_collection_room,
                                                                    i_lab                       => i_lab,
                                                                    i_exec_institution          => i_exec_institution,
                                                                    i_sample_recipient          => i_sample_recipient,
                                                                    i_num_recipient             => i_num_recipient,
                                                                    i_collected_by              => i_collected_by,
                                                                    i_collection_time           => i_collection_time,
                                                                    i_collection_amount         => i_collection_amount,
                                                                    i_collection_transportation => i_collection_transportation,
                                                                    i_notes                     => i_notes,
                                                                    i_rep_coll_reason           => i_rep_coll_reason,
                                                                    i_flg_orig_harvest          => i_flg_orig_harvest,
                                                                    o_error                     => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            ELSE
                -- Check if Barcode is to be generated at the harvest time
                IF l_generate_barcode = pk_lab_tests_constant.g_yes
                THEN
                    g_error := 'OPEN C_BARCODE';
                    OPEN c_barcode;
                    FETCH c_barcode
                        INTO l_barcode;
                    CLOSE c_barcode;
                
                    IF l_barcode IS NULL
                    THEN
                        g_error := 'Check HARVEST_BARCODE_INTERFACE Configuration';
                        IF pk_sysconfig.get_config('GENERATE_BARCODE_HARVEST', i_prof) = pk_lab_tests_constant.g_yes
                        THEN
                            g_error := 'HASHMAP PARAMETERS';
                            l_hashmap('id_harvest') := table_varchar(to_char(i_harvest));
                        
                            g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_BARCODE_CODE Interfaces';
                            IF NOT pk_ia_external_info.get_lab_barcode_code(i_prof    => i_prof,
                                                                            i_hashmap => l_hashmap,
                                                                            o_barcode => l_barcode,
                                                                            o_error   => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    
                        -- When Interfaces function fails, the barcode ALERT should be created
                        IF l_barcode IS NULL
                        THEN
                            g_error := 'CALL PK_BARCODE.GENERATE_BARCODE';
                            IF NOT pk_barcode.generate_barcode(i_lang         => i_lang,
                                                               i_barcode_type => 'H',
                                                               i_institution  => i_prof.institution,
                                                               i_software     => i_prof.software,
                                                               o_barcode      => l_barcode,
                                                               o_error        => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    END IF;
                END IF; -- Create Barcode
            
                -- Update lab tests request data
                FOR i IN 1 .. i_analysis_req_det.count
                LOOP
                    BEGIN
                        SELECT ar.id_analysis_req
                          INTO l_id_analysis_req
                          FROM analysis_req_det ard, analysis_req ar
                         WHERE ard.id_analysis_req_det = i_analysis_req_det(i)
                           AND ard.id_analysis_req = ar.id_analysis_req
                           AND ar.flg_status != pk_lab_tests_constant.g_analysis_ongoing;
                    
                        g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_HISTORY';
                        IF NOT pk_lab_tests_core.set_lab_test_history(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_analysis_req     => l_id_analysis_req,
                                                                      i_analysis_req_det => i_analysis_req_det,
                                                                      o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    EXCEPTION
                        WHEN no_data_found THEN
                            g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_HISTORY';
                            IF NOT pk_lab_tests_core.set_lab_test_history(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_analysis_req     => NULL,
                                                                          i_analysis_req_det => i_analysis_req_det,
                                                                          o_error            => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                    END;
                
                    -- Check if ANALYSIS_HARVEST needs to be updated
                    g_error := 'Get ANALYSIS_HARVEST, ID_SAMPLE_RECIPIENT and NUM_RECIPIENT';
                    SELECT ah.id_sample_recipient, ah.num_recipient
                      INTO l_sample_recipient, l_num_recipient
                      FROM analysis_harvest ah
                     WHERE ah.id_analysis_harvest = i_analysis_harvest(i);
                
                    IF l_sample_recipient != i_sample_recipient
                       OR l_num_recipient != i_num_recipient
                    THEN
                    
                        -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table        
                        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                        IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_harvest          => NULL,
                                                                             i_analysis_harvest => i_analysis_harvest(i),
                                                                             o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        -- Update ANALYSIS_HARVEST data
                        g_error := 'CALL TS_ANALYSIS_HARVEST.UPD';
                        ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i),
                                                id_sample_recipient_in => i_sample_recipient,
                                                num_recipient_in       => i_num_recipient,
                                                rows_out               => l_rows_out);
                    
                        -- Harvest Data Governance Process
                        g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_table_name   => 'ANALYSIS_HARVEST',
                                                      i_list_columns => table_varchar('ID_SAMPLE_RECIPIENT',
                                                                                      'NUM_RECIPIENT'),
                                                      i_rowids       => l_rows_out,
                                                      o_error        => o_error);
                    END IF;
                
                    BEGIN
                        SELECT h.id_harvest
                          INTO l_harvest
                          FROM analysis_harvest ah, harvest h
                         WHERE ah.id_analysis_req_det = i_analysis_req_det(i)
                           AND ah.id_harvest != i_harvest
                           AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                           AND ah.id_harvest = h.id_harvest
                           AND h.flg_status IN
                               (pk_lab_tests_constant.g_harvest_pending, pk_lab_tests_constant.g_harvest_waiting)
                           AND rownum = 1
                         ORDER BY h.dt_begin_harvest;
                    
                        l_status := pk_lab_tests_constant.g_analysis_oncollection;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_status := pk_lab_tests_constant.g_analysis_toexec;
                    END;
                
                    l_rows_out := NULL;
                    -- Update ANALYSIS_REQ_DET status to Executed            
                    g_error := 'CALL TS_ANALYSIS_REQ_DET.UPD';
                    ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det(i),
                                            flg_status_in          => l_status,
                                            id_prof_last_update_in => i_prof.id,
                                            dt_last_update_tstz_in => g_sysdate_tstz,
                                            rows_out               => l_rows_out);
                
                    g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ_DET';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ANALYSIS_REQ_DET',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    g_error := 'CALL PK_LAB_TESTS_EXTERNAL_API_DB.UPDATE_TDE_TASK_STATE';
                    IF NOT pk_lab_tests_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                              i_prof         => i_prof,
                                                                              i_lab_test_req => i_analysis_req_det(i),
                                                                              i_flg_action   => l_status,
                                                                              o_error        => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- Insert on status log table
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => l_status,
                                            i_id_record  => i_analysis_req_det(i),
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- Remove ALERT's when they are behind schedule
                    l_sys_alert_event.id_sys_alert := 4;
                    l_sys_alert_event.id_episode   := i_episode;
                    l_sys_alert_event.id_record    := i_analysis_req_det(i);
                
                    g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- Update ANALYSIS_REQ status to Executed     
                    g_error := 'UPDATE ANALYSIS_REQ';
                    SELECT ard.id_analysis_req, ard.flg_time_harvest
                      INTO l_id_analysis_req, l_flg_time
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req_det = i_analysis_req_det(i);
                
                    l_rows_out := NULL;
                    g_error    := 'CALL TS_ANALYSIS_REQ.UPD';
                    ts_analysis_req.upd(flg_status_in          => pk_lab_tests_constant.g_analysis_ongoing,
                                        id_prof_last_update_in => i_prof.id,
                                        dt_last_update_tstz_in => g_sysdate_tstz,
                                        where_in               => 'id_analysis_req = ' || l_id_analysis_req ||
                                                                  ' AND flg_status != ''' ||
                                                                  pk_lab_tests_constant.g_analysis_ongoing || '''',
                                        rows_out               => l_rows_out);
                
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_analysis_ongoing,
                                            i_id_record  => l_id_analysis_req,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_req,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    g_error := 'Open C_MOV_RECIPIENT Cursor';
                    OPEN c_mov_recipient(i_analysis_req_det(i));
                    FETCH c_mov_recipient
                        INTO l_flg_mov_recipient, l_harvest_instructions;
                    CLOSE c_mov_recipient;
                
                    -- The destination room is always the room selected in the harvest
                    IF l_flg_mov_recipient = pk_lab_tests_constant.g_yes
                    THEN
                        -- Check if the lab tests tubes need to be transported by the auxiliary
                        g_error := 'Open C_ROOM Cursor';
                        OPEN c_room(i_analysis_req_det(i));
                        FETCH c_room
                            INTO l_room_default, l_id_analysis;
                        g_found := c_room%FOUND;
                        CLOSE c_room;
                    
                        IF NOT g_found
                        THEN
                            g_error_code := 'ANALYSIS_M009';
                            g_error      := REPLACE(pk_message.get_message(i_lang, 'ANALYSIS_M009'),
                                                    '@1',
                                                    l_id_analysis);
                            RAISE g_user_exception;
                        END IF;
                    
                        -- If the room to where the tube must be transported is not the room where the collect is 
                        -- performed (actual pacient location)
                        -- OR
                        -- If it is different from the configured room for the previous lab test
                        -- then the specimen collection is not finished
                        IF (l_room_default != nvl(l_room_prev, l_room_default) OR l_room_default != l_id_room)
                        THEN
                            l_harvest_status := pk_lab_tests_constant.g_harvest_collected;
                        ELSIF (nvl(pk_sysconfig.get_config('HARVEST_FINISH_TRANSPORT_LABTECH', i_prof),
                                   pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_no)
                        THEN
                            l_harvest_status := pk_lab_tests_constant.g_harvest_collected;
                        END IF;
                    
                        l_room_prev := l_room_default;
                    
                        IF l_flg_time = pk_lab_tests_constant.g_flg_time_e
                           AND l_harvest_status = pk_lab_tests_constant.g_harvest_collected
                        THEN
                            l_sys_alert_event.id_sys_alert := 5;
                            l_sys_alert_event.id_episode   := i_episode;
                            l_sys_alert_event.id_record    := i_harvest;
                            l_sys_alert_event.dt_record    := g_sysdate_tstz;
                            l_sys_alert_event.replace1     := pk_sysconfig.get_config('ALERT_HARVEST_MOV_TIMEOUT',
                                                                                      i_prof.institution,
                                                                                      i_prof.software);
                        
                            g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT - ALERTA 5';
                            IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_sys_alert_event => l_sys_alert_event,
                                                                    i_flg_type_dest   => 'C',
                                                                    o_error           => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        ELSE
                            l_sys_alert_event.id_sys_alert := 5;
                            l_sys_alert_event.id_episode   := i_episode;
                            l_sys_alert_event.id_record    := i_harvest;
                        
                            g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT - ALERTA 5';
                            IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                                    i_prof            => i_prof,
                                                                    i_sys_alert_event => l_sys_alert_event,
                                                                    o_error           => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    ELSE
                        l_harvest_status := pk_lab_tests_constant.g_harvest_finished;
                    END IF;
                END LOOP;
            
                -- Data Governance for ANALYSIS_REQ
                g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ';
                t_data_gov_mnt.process_update(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_REQ',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                -- IF the professional category is Lab Test Technician, then there is no need to transport
                -- i_prof_cat_type = 'T'
                IF (l_prof_cat_type = pk_alert_constant.g_cat_type_technician AND
                   nvl(pk_sysconfig.get_config('HARVEST_FINISH_TRANSPORT_LABTECH', i_prof),
                        pk_lab_tests_constant.g_yes) = pk_lab_tests_constant.g_yes)
                THEN
                    l_technician            := TRUE;
                    l_dt_lab_reception_tstz := g_sysdate_tstz;
                    l_id_prof_receive_tube  := i_prof.id;
                ELSE
                    l_technician            := FALSE;
                    l_dt_lab_reception_tstz := NULL;
                    l_id_prof_receive_tube  := NULL;
                END IF;
            
                -- Update HARVEST  
                -- Process current HARVEST to HARVEST_HIST table        
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_harvest          => i_harvest,
                                                                     i_analysis_harvest => NULL,
                                                                     o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_prof_dep_clin_serv := pk_prof_utils.get_prof_dcs(profissional(nvl(i_collected_by, i_prof.id),
                                                                                i_prof.institution,
                                                                                i_prof.software));
            
                g_error := 'Update HARVEST';
                IF l_harvest_status != pk_lab_tests_constant.g_harvest_collected
                THEN
                    l_rows_out := NULL;
                    g_error    := 'CALL TS_HARVEST.UPD';
                    ts_harvest.upd(id_harvest_in            => i_harvest,
                                   id_patient_in            => l_patient,
                                   id_episode_in            => i_episode,
                                   id_visit_in              => l_visit,
                                   id_prof_harvest_in       => nvl(i_collected_by, i_prof.id),
                                   prof_dep_clin_serv_in    => l_prof_dep_clin_serv,
                                   dt_harvest_reg_tstz_in   => g_sysdate_tstz,
                                   flg_status_in            => pk_lab_tests_constant.g_harvest_finished,
                                   id_body_part_in          => i_body_location,
                                   flg_collection_method_in => i_collection_method,
                                   id_room_harvest_in       => CASE
                                                                   WHEN pk_utils.is_number(i_collection_room) =
                                                                        pk_lab_tests_constant.g_yes THEN
                                                                    nvl(i_collection_room, l_id_room)
                                                                   ELSE
                                                                    NULL
                                                               END,
                                   flg_col_inst_in          => CASE
                                                                   WHEN pk_utils.is_number(i_collection_room) =
                                                                        pk_lab_tests_constant.g_yes THEN
                                                                    NULL
                                                                   ELSE
                                                                    i_collection_room
                                                               END,
                                   id_prof_receive_tube_in  => i_prof.id,
                                   id_room_receive_tube_in  => i_lab,
                                   id_institution_in        => CASE
                                                                   WHEN i_exec_institution IS NOT NULL THEN
                                                                    i_exec_institution
                                                                   ELSE
                                                                    i_prof.institution
                                                               END,
                                   num_recipient_in         => i_num_recipient,
                                   dt_harvest_tstz_in       => nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_collection_time, NULL),
                                                                   g_sysdate_tstz),
                                   amount_in                => i_collection_amount,
                                   id_prof_mov_tube_in      => i_prof.id,
                                   flg_mov_tube_in          => i_collection_transportation,
                                   notes_in                 => i_notes,
                                   harvest_instructions_in  => l_harvest_instructions,
                                   id_revised_by_in         => i_revised_by,
                                   barcode_in               => l_barcode,
                                   dt_mov_begin_tstz_in     => g_sysdate_tstz,
                                   dt_lab_reception_tstz_in => g_sysdate_tstz,
                                   flg_print_in             => 'S', -- If flg_print does not have any value, proceed with S (Screen not shown)
                                   flg_orig_harvest_in      => i_flg_orig_harvest,
                                   rows_out                 => l_rows_out);
                
                    g_error := 'CALL PROCESS_UPDATE for Harvest';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    -- Insert on status log table
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_harvest_finished,
                                            i_id_record  => i_harvest,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                ELSE
                
                    l_rows_out := NULL;
                    g_error    := 'CALL TS_HARVEST.UPD';
                    ts_harvest.upd(id_harvest_in             => i_harvest,
                                   id_patient_in             => l_patient,
                                   id_episode_in             => i_episode,
                                   id_visit_in               => l_visit,
                                   id_prof_harvest_in        => nvl(i_collected_by, i_prof.id),
                                   prof_dep_clin_serv_in     => l_prof_dep_clin_serv,
                                   dt_harvest_reg_tstz_in    => g_sysdate_tstz,
                                   flg_status_in             => pk_lab_tests_constant.g_harvest_collected,
                                   id_body_part_in           => i_body_location,
                                   flg_collection_method_in  => i_collection_method,
                                   id_room_harvest_in        => CASE
                                                                    WHEN pk_utils.is_number(i_collection_room) =
                                                                         pk_lab_tests_constant.g_yes THEN
                                                                     nvl(i_collection_room, l_id_room)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   flg_col_inst_in           => CASE
                                                                    WHEN pk_utils.is_number(i_collection_room) =
                                                                         pk_lab_tests_constant.g_yes THEN
                                                                     NULL
                                                                    ELSE
                                                                     i_collection_room
                                                                END,
                                   id_prof_receive_tube_in   => l_id_prof_receive_tube,
                                   id_prof_receive_tube_nin  => FALSE,
                                   id_room_receive_tube_in   => i_lab,
                                   id_institution_in         => CASE
                                                                    WHEN i_exec_institution IS NOT NULL THEN
                                                                     i_exec_institution
                                                                    ELSE
                                                                     i_prof.institution
                                                                END,
                                   num_recipient_in          => i_num_recipient,
                                   dt_harvest_tstz_in        => nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                  i_prof,
                                                                                                  i_collection_time,
                                                                                                  NULL),
                                                                    g_sysdate_tstz),
                                   amount_in                 => i_collection_amount,
                                   id_prof_mov_tube_in       => i_prof.id,
                                   flg_mov_tube_in           => i_collection_transportation,
                                   notes_in                  => i_notes,
                                   harvest_instructions_in   => l_harvest_instructions,
                                   id_revised_by_in          => i_revised_by,
                                   id_revised_by_nin         => FALSE,
                                   barcode_in                => l_barcode,
                                   dt_mov_begin_tstz_in      => g_sysdate_tstz,
                                   dt_lab_reception_tstz_in  => l_dt_lab_reception_tstz,
                                   dt_lab_reception_tstz_nin => FALSE,
                                   flg_orig_harvest_in       => i_flg_orig_harvest,
                                   rows_out                  => l_rows_out);
                
                    g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_COLLECTED';
                    pk_ia_event_lab.harvest_collected(i_id_harvest     => i_harvest,
                                                      i_id_institution => i_prof.institution,
                                                      i_flg_old_status => pk_lab_tests_constant.g_harvest_pending);
                
                    -- Insert on status log table
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_harvest_collected,
                                            i_id_record  => i_harvest,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    IF l_technician
                    THEN
                        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.UPDATE_HARVEST';
                        IF NOT pk_lab_tests_harvest_core.update_harvest(i_lang             => i_lang,
                                                                        i_prof             => i_prof,
                                                                        i_harvest          => table_number(i_harvest),
                                                                        i_status           => table_varchar(pk_lab_tests_constant.g_harvest_collected),
                                                                        i_collected_by     => NULL,
                                                                        i_collection_time  => NULL,
                                                                        i_flg_orig_harvest => i_flg_orig_harvest,
                                                                        o_error            => o_error)
                        THEN
                            -- Process should proceed
                            NULL;
                        END IF;
                    END IF;
                END IF;
            
                -- Validate if this harvest is to be for Exterior Workflow
                FOR i IN 1 .. i_analysis_req_det.count
                LOOP
                    -- If specimen collection is 'F' and to be executed on 'Exterior'
                    -- then the status of it should be '(X) Exterior'
                    SELECT h.flg_status
                      INTO l_harvest_status
                      FROM harvest h
                     WHERE h.id_harvest = i_harvest;
                
                    SELECT ais.flg_execute, ais.flg_mov_recipient, ar.id_episode
                      INTO l_flg_execute, l_flg_mov_recipient, l_episode
                      FROM analysis_instit_soft ais, analysis_req_det ard, analysis_req ar
                     WHERE ard.id_analysis_req_det = i_analysis_req_det(i)
                       AND ard.id_analysis_req = ar.id_analysis_req
                       AND ard.id_analysis = ais.id_analysis
                       AND ard.id_sample_type = ais.id_sample_type
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software
                       AND ais.flg_available = pk_lab_tests_constant.g_available;
                
                    IF l_status != pk_lab_tests_constant.g_analysis_oncollection
                    THEN
                        IF (((l_harvest_status = pk_lab_tests_constant.g_harvest_finished OR
                           l_harvest_status = pk_lab_tests_constant.g_harvest_transp) AND
                           l_flg_execute = pk_lab_tests_constant.g_no) OR
                           (l_harvest_status = pk_lab_tests_constant.g_harvest_collected AND
                           l_flg_mov_recipient = pk_lab_tests_constant.g_no AND
                           l_flg_execute = pk_lab_tests_constant.g_no) OR
                           (i_exec_institution IS NOT NULL AND i_exec_institution != i_prof.institution))
                        THEN
                            l_rows_out := NULL;
                            g_error    := 'CALL TS_ANALYSIS_REQ_DET.UPD';
                            ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det(i),
                                                    flg_status_in          => pk_lab_tests_constant.g_analysis_exterior,
                                                    id_prof_last_update_in => i_prof.id,
                                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                                    rows_out               => l_rows_out);
                        
                            -- Insert on status log table
                            g_error := 'CALL T_TI_LOG.INS_LOG';
                            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => l_episode,
                                                    i_flg_status => pk_lab_tests_constant.g_analysis_exterior,
                                                    i_id_record  => i_analysis_req_det(i),
                                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                                    o_error      => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_REQ_DET';
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'ANALYSIS_REQ_DET',
                                                          i_rowids     => l_rows_out,
                                                          o_error      => o_error);
                        
                            l_rows_out := NULL;
                            g_error    := 'CALL TS_HARVEST.UPD';
                            ts_harvest.upd(id_harvest_in             => i_harvest,
                                           flg_status_in             => pk_lab_tests_constant.g_harvest_collected,
                                           id_prof_mov_tube_in       => NULL,
                                           dt_mov_begin_tstz_in      => NULL,
                                           id_prof_receive_tube_in   => NULL,
                                           dt_lab_reception_tstz_in  => NULL,
                                           id_prof_mov_tube_nin      => FALSE,
                                           dt_mov_begin_tstz_nin     => FALSE,
                                           id_prof_receive_tube_nin  => FALSE,
                                           dt_lab_reception_tstz_nin => FALSE,
                                           rows_out                  => l_rows_out);
                        
                            g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'HARVEST',
                                                          i_rowids     => l_rows_out,
                                                          o_error      => o_error);
                        
                            -- Insert on status log table
                            g_error := 'CALL T_TI_LOG.INS_LOG';
                            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                    i_prof       => i_prof,
                                                    i_id_episode => i_episode,
                                                    i_flg_status => pk_lab_tests_constant.g_harvest_collected,
                                                    i_id_record  => i_harvest,
                                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                                    o_error      => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        
                            g_error := 'CALL TO PK_IA_EVENT_LAB.ANALYSIS_REQUEST_EXTERNAL_NEW';
                            pk_ia_event_lab.analysis_request_external_new(i_id_analysis_req_det => i_analysis_req_det(i),
                                                                          i_id_institution      => i_prof.institution,
                                                                          i_flg_old_status      => l_status);
                        END IF;
                    END IF;
                
                    g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
                    IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                      i_prof             => i_prof,
                                                                      i_patient          => l_patient,
                                                                      i_episode          => i_episode,
                                                                      i_analysis_req     => NULL,
                                                                      i_analysis_req_det => i_analysis_req_det(i),
                                                                      o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    BEGIN
                        SELECT h.id_harvest
                          INTO l_harvest
                          FROM analysis_harvest ah, harvest h
                         WHERE ah.id_analysis_req_det = i_analysis_req_det(i)
                           AND ah.id_harvest != i_harvest
                           AND ah.id_harvest = h.id_harvest
                           AND h.flg_status = pk_lab_tests_constant.g_harvest_waiting
                           AND rownum = 1
                         ORDER BY nvl(h.dt_harvest_tstz, h.dt_begin_harvest);
                    
                        SELECT pk_date_utils.add_to_ltstz(g_sysdate_tstz, aci.interval, 'MINUTE')
                          INTO l_dt_harvest
                          FROM (SELECT aci.interval, row_number() over(ORDER BY aci.order_collection) rn
                                  FROM analysis_req_det        ard,
                                       analysis_instit_soft    ais,
                                       analysis_collection     ac,
                                       analysis_collection_int aci
                                 WHERE ard.id_analysis_req_det = i_analysis_req_det(i)
                                   AND ard.id_analysis = ais.id_analysis
                                   AND ard.id_sample_type = ais.id_sample_type
                                   AND ais.id_institution = i_prof.institution
                                   AND ais.id_software = i_prof.software
                                   AND ais.flg_available = pk_lab_tests_constant.g_available
                                   AND ais.flg_type IN
                                       (pk_lab_tests_constant.g_analysis_can_req, pk_lab_tests_constant.g_analysis_exec)
                                   AND ais.id_analysis_instit_soft = ac.id_analysis_instit_soft
                                   AND ac.flg_available = pk_lab_tests_constant.g_available
                                   AND ac.flg_status = pk_lab_tests_constant.g_active
                                   AND ac.id_analysis_collection = aci.id_analysis_collection
                                   AND aci.flg_available = pk_lab_tests_constant.g_available) aci
                         WHERE rn = (SELECT COUNT(h.id_harvest) + 1
                                       FROM analysis_harvest ah, harvest h
                                      WHERE ah.id_analysis_req_det = i_analysis_req_det(i)
                                        AND ah.id_harvest = h.id_harvest
                                        AND h.flg_status IN (pk_lab_tests_constant.g_harvest_collected,
                                                             pk_lab_tests_constant.g_harvest_transp,
                                                             pk_lab_tests_constant.g_harvest_finished));
                    
                        l_rows_out := NULL;
                        g_error    := 'UPDATE HARVEST';
                        ts_harvest.upd(id_harvest_in       => l_harvest,
                                       flg_status_in       => pk_lab_tests_constant.g_harvest_pending,
                                       dt_begin_harvest_in => l_dt_harvest,
                                       rows_out            => l_rows_out);
                    
                        g_error := 'CALL PROCESS_UPDATE';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'HARVEST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    
                        g_error := 'CALL T_TI_LOG.INS_LOG';
                        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => i_episode,
                                                i_flg_status => pk_lab_tests_constant.g_harvest_pending,
                                                i_id_record  => l_harvest,
                                                i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                                o_error      => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END LOOP;
            
                g_error := 'CALL PK_VISIT.UPDATE_EPIS_INFO';
                IF NOT
                    pk_visit.upd_epis_info_analysis(i_lang                   => i_lang,
                                                    i_id_episode             => i_episode,
                                                    i_id_prof                => i_prof,
                                                    i_dt_first_analysis_exec => pk_date_utils.date_send_tsz(i_lang,
                                                                                                            g_sysdate_tstz,
                                                                                                            i_prof),
                                                    i_dt_first_analysis_req  => NULL,
                                                    i_prof_cat_type          => pk_prof_utils.get_category(i_lang, i_prof),
                                                    o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => i_episode,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_user_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              g_error_code,
                                              g_error,
                                              '',
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HARVEST_COLLECT',
                                              'U',
                                              '',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HARVEST_COLLECT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_collect;

    FUNCTION set_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN analysis_req_det.id_analysis_req_det%TYPE,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis_harvest IS
            SELECT DISTINCT ah.*
              FROM analysis_harvest ah
             WHERE ah.id_harvest = i_harvest;
    
        l_analysis_harvest analysis_harvest%ROWTYPE;
    
        l_next_aharv      analysis_harvest.id_analysis_harvest%TYPE;
        l_episode         harvest.id_episode%TYPE;
        l_analysis_req    analysis_req_det.id_analysis_req%TYPE;
        l_status          VARCHAR2(2 CHAR);
        l_dt_harvest_tstz harvest.dt_harvest_tstz%TYPE;
    
        l_alert_exists    NUMBER;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        SELECT seq_analysis_harvest.nextval
          INTO l_next_aharv
          FROM dual;
    
        OPEN c_analysis_harvest;
        FETCH c_analysis_harvest
            INTO l_analysis_harvest;
        CLOSE c_analysis_harvest;
    
        g_error := 'MERGE INTO ANALYSIS_HARVEST';
        ts_analysis_harvest.upd(id_harvest_in  => i_harvest,
                                id_harvest_nin => FALSE,
                                where_in       => ' id_analysis_req_det = ' || i_analysis_req_det,
                                rows_out       => l_rows_out);
    
        IF l_rows_out IS NULL
           OR l_rows_out.count = 0
        THEN
            ts_analysis_harvest.ins(id_analysis_harvest_in => l_next_aharv,
                                    id_analysis_req_det_in => i_analysis_req_det,
                                    id_harvest_in          => i_harvest,
                                    id_sample_recipient_in => l_analysis_harvest.id_sample_recipient,
                                    num_recipient_in       => l_analysis_harvest.num_recipient,
                                    flg_status_in          => l_analysis_harvest.flg_status,
                                    rows_out               => l_rows_out);
        END IF;
    
        g_error := 'CALL PROCESS_UPDATE';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_HARVEST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        SELECT h.id_episode, h.flg_status
          INTO l_episode, l_status
          FROM harvest h
         WHERE h.id_harvest = i_harvest;
    
        IF l_status = pk_lab_tests_constant.g_harvest_collected
        THEN
            -- inserir em log de estados
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_episode,
                                    i_flg_status => pk_lab_tests_constant.g_analysis_toexec,
                                    i_id_record  => i_analysis_req_det,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_rows_out := NULL;
            g_error    := 'UPDATE HARVEST';
            ts_harvest.upd(flg_status_in => pk_lab_tests_constant.g_harvest_collected,
                           where_in      => 'id_harvest = ' || i_harvest || '
           AND flg_status != ''' || pk_lab_tests_constant.g_harvest_collected || '''',
                           rows_out      => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- inserir em log de estados
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_episode,
                                    i_flg_status => pk_lab_tests_constant.g_harvest_collected,
                                    i_id_record  => i_harvest,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_COLLECTED';
            pk_ia_event_lab.harvest_collected(i_id_harvest     => i_harvest,
                                              i_id_institution => i_prof.institution,
                                              i_flg_old_status => l_status);
        
            IF l_rows_out IS NOT NULL
               AND l_rows_out.count > 0
            THEN
                SELECT dt_harvest_tstz
                  INTO l_dt_harvest_tstz
                  FROM harvest
                 WHERE ROWID IN (SELECT /*+opt_estimate (table t rows=1)*/
                                  *
                                   FROM TABLE(l_rows_out) t);
            END IF;
        
            BEGIN
                SELECT 1
                  INTO l_alert_exists
                  FROM sys_alert_event sae
                 WHERE sae.id_sys_alert = 5
                   AND sae.id_episode = l_episode
                   AND sae.id_record = i_harvest
                   AND sae.id_institution = i_prof.institution
                   AND sae.id_software = i_prof.software;
            EXCEPTION
                WHEN no_data_found THEN
                    l_alert_exists := 0;
            END;
        
            IF l_alert_exists = 0
            THEN
                l_sys_alert_event.id_sys_alert    := 5;
                l_sys_alert_event.id_software     := i_prof.software;
                l_sys_alert_event.id_institution  := i_prof.institution;
                l_sys_alert_event.id_episode      := l_episode;
                l_sys_alert_event.id_record       := i_harvest;
                l_sys_alert_event.dt_record       := l_dt_harvest_tstz;
                l_sys_alert_event.id_professional := NULL;
                l_sys_alert_event.id_room         := NULL;
                l_sys_alert_event.replace1        := pk_sysconfig.get_config('ALERT_HARVEST_MOV_TIMEOUT',
                                                                             i_prof.institution,
                                                                             i_prof.software);
            
                --Insere evento na tabela de alertas
                g_error := 'INSERT INTO SYS_ALERT_EVENT';
                IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        i_flg_type_dest   => 'C',
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        
            g_error := 'GET_REQ_FROM_DET';
            SELECT ard.id_analysis_req, ard.flg_status
              INTO l_analysis_req, l_status
              FROM analysis_req_det ard
             WHERE ard.id_analysis_req_det = i_analysis_req_det;
        
            l_rows_out := NULL;
            g_error    := 'UPDATE ANALYSIS_REQ_DET';
            ts_analysis_req_det.upd(id_analysis_req_det_in => i_analysis_req_det,
                                    flg_status_in          => pk_lab_tests_constant.g_analysis_toexec,
                                    id_prof_last_update_in => i_prof.id,
                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                    rows_out               => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ_DET',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.ANALYSIS_REQUEST_IN_PROGRESS';
            pk_ia_event_lab.analysis_request_in_progress(i_id_analysis_req_det => i_analysis_req_det,
                                                         i_id_institution      => i_prof.institution,
                                                         i_flg_old_status      => l_status);
        
            g_error := 'CALL TO PK_LAB_TESTS_EXTERNAL_API_DB.UPDATE_TDE_TASK_STATE';
            IF NOT pk_lab_tests_external_api_db.update_tde_task_state(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_lab_test_req => i_analysis_req_det,
                                                                      i_flg_action   => pk_lab_tests_constant.g_analysis_toexec,
                                                                      o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_rows_out := NULL;
            g_error    := 'UPDATE ANALYSIS_REQ';
            ts_analysis_req.upd(flg_status_in => pk_lab_tests_constant.g_analysis_toexec,
                                where_in      => 'id_analysis_req = ' || l_analysis_req || ' AND flg_status != ''' ||
                                                 pk_lab_tests_constant.g_analysis_toexec || '''',
                                rows_out      => l_rows_out);
        
            g_error := 'CALL PROCESS_UPDATE';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'ANALYSIS_REQ',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- inserir em log de estados
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => l_episode,
                                    i_flg_status => pk_lab_tests_constant.g_analysis_toexec,
                                    i_id_record  => l_analysis_req,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_req,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        g_error := 'CALL TO PK_VISIT.UPDATE_EPIS_INFO';
        IF NOT pk_visit.upd_epis_info_analysis(i_lang                   => i_lang,
                                               i_id_episode             => l_episode,
                                               i_id_prof                => i_prof,
                                               i_dt_first_analysis_exec => pk_date_utils.date_send_tsz(i_lang,
                                                                                                       current_timestamp,
                                                                                                       i_prof),
                                               i_dt_first_analysis_req  => NULL,
                                               i_prof_cat_type          => pk_tools.get_prof_cat(i_prof),
                                               o_error                  => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
        IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_patient          => NULL,
                                                          i_episode          => l_episode,
                                                          i_analysis_req     => l_analysis_req,
                                                          i_analysis_req_det => i_analysis_req_det,
                                                          o_error            => o_error)
        THEN
            RAISE g_other_exception;
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
                                              'SET_HARVEST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest;

    FUNCTION set_harvest_history
    (
        i_lang             IN language.id_language%TYPE, --1
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        i_analysis_harvest IN analysis_harvest.id_analysis_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        IF i_harvest IS NOT NULL
        THEN
            -- Insert into Harvest Hist
            g_error := 'INSERT INTO HARVEST_HIST';
            INSERT INTO harvest_hist
                (dt_harvest_hist,
                 id_harvest,
                 id_harvest_group,
                 id_patient,
                 id_episode,
                 id_visit,
                 flg_status,
                 id_prof_harvest,
                 prof_dep_clin_serv,
                 dt_harvest_reg_tstz,
                 dt_harvest_tstz,
                 dt_begin_harvest,
                 num_recipient,
                 barcode,
                 id_body_part,
                 flg_laterality,
                 flg_col_inst,
                 id_room_harvest,
                 id_institution,
                 id_episode_write,
                 flg_mov_tube,
                 id_prof_mov_tube,
                 dt_mov_begin_tstz,
                 dt_lab_reception_tstz,
                 id_prof_receive_tube,
                 id_room_receive_tube,
                 flg_collection_method,
                 id_specimen_condition,
                 amount,
                 notes,
                 harvest_instructions,
                 id_revised_by,
                 flg_print,
                 flg_chargeable,
                 flg_orig_harvest,
                 id_rep_coll_reason,
                 id_prof_cancels,
                 dt_cancel_tstz,
                 id_cancel_reason,
                 notes_cancel)
                (SELECT g_sysdate_tstz,
                        h.id_harvest,
                        h.id_harvest_group,
                        h.id_patient,
                        h.id_episode,
                        h.id_visit,
                        h.flg_status,
                        h.id_prof_harvest,
                        h.prof_dep_clin_serv,
                        h.dt_harvest_reg_tstz,
                        h.dt_harvest_tstz,
                        h.dt_begin_harvest,
                        h.num_recipient,
                        h.barcode,
                        h.id_body_part,
                        h.flg_laterality,
                        h.flg_col_inst,
                        h.id_room_harvest,
                        h.id_institution,
                        h.id_episode_write,
                        h.flg_mov_tube,
                        h.id_prof_mov_tube,
                        h.dt_mov_begin_tstz,
                        h.dt_lab_reception_tstz,
                        h.id_prof_receive_tube,
                        h.id_room_receive_tube,
                        h.flg_collection_method,
                        h.id_specimen_condition,
                        h.amount,
                        h.notes,
                        h.harvest_instructions,
                        h.id_revised_by,
                        h.flg_print,
                        h.flg_chargeable,
                        h.flg_orig_harvest,
                        h.id_rep_coll_reason,
                        h.id_prof_cancels,
                        h.dt_cancel_tstz,
                        h.id_cancel_reason,
                        h.notes_cancel
                   FROM harvest h
                  WHERE h.id_harvest = i_harvest);
        END IF;
    
        IF i_analysis_harvest IS NOT NULL
        THEN
            -- Insert into Analysis Harvest Hist
            g_error := 'INSERT INTO ANALYSIS_HARVEST_HIST';
            INSERT INTO analysis_harvest_hist
                (dt_analysis_harvest,
                 id_analysis_harvest,
                 id_analysis_req_det,
                 id_harvest,
                 id_analysis_req_par,
                 id_sample_recipient,
                 num_recipient,
                 flg_status)
                (SELECT g_sysdate_tstz,
                        ah.id_analysis_harvest,
                        ah.id_analysis_req_det,
                        ah.id_harvest,
                        ah.id_analysis_req_par,
                        ah.id_sample_recipient,
                        ah.num_recipient,
                        ah.flg_status
                   FROM analysis_harvest ah
                  WHERE ah.id_analysis_harvest = i_analysis_harvest);
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
                                              'SET_HARVEST_HISTORY',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_history;

    FUNCTION set_harvest_edit
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_harvest                   IN table_number,
        i_analysis_harvest          IN table_table_number,
        i_body_location             IN table_number, --5
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --10
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar, --15
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_harv_num_recipient  harvest.num_recipient%TYPE;
        l_notes               harvest.notes%TYPE;
        l_sample_recipient    analysis_harvest.id_sample_recipient%TYPE;
        l_aharv_num_recipient analysis_harvest.num_recipient%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
    
        -- Check and validate input array's data
        IF i_harvest.count = 0
        THEN
            g_error := 'I_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_analysis_harvest.count = 0
        THEN
            g_error := 'I_ANALYSIS_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_collection_time.count = 0
        THEN
            g_error := 'I_COLLECTION_TIME parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_lab.count = 0
        THEN
            g_error := 'I_LAB parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_sample_recipient.count = 0
        THEN
            g_error := 'I_SAMPLE_RECIPIENT parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_num_recipient.count = 0
        THEN
            g_error := 'I_NUM_RECIPIENT parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_notes.count = 0
        THEN
            g_error := 'I_NOTES parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_harvest.count != i_analysis_harvest.count
           OR i_analysis_harvest.count != i_collection_time.count
           OR i_collection_time.count != i_lab.count
           OR i_sample_recipient.count != i_num_recipient.count
           OR i_num_recipient.count != i_notes.count
        THEN
            g_error := 'Arrays have has different number of elements';
            RAISE g_other_exception;
        END IF;
    
        -- Process each harvest    
        FOR i IN 1 .. i_harvest.count
        LOOP
            IF i_harvest(i) IS NULL
            THEN
                g_error := 'I_HARVEST(' || i || ') parameter has no ID';
                RAISE g_other_exception;
            END IF;
        
            -- Check if HARVEST needs to be updated
            g_error := 'Get HARVEST, NUM_RECIPIENT, NOTES';
            SELECT h.num_recipient, h.notes
              INTO l_harv_num_recipient, l_notes
              FROM harvest h
             WHERE h.id_harvest = i_harvest(i);
        
            -- Process current HARVEST to HARVEST_HIST table        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
            IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_harvest          => i_harvest(i),
                                                                 i_analysis_harvest => NULL,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Update HARVEST
            g_error := 'Update HARVEST';
            ts_harvest.upd(id_harvest_in            => i_harvest(i),
                           id_body_part_in          => i_body_location(i),
                           id_body_part_nin         => FALSE,
                           flg_laterality_in        => CASE
                                                           WHEN i_laterality IS NOT NULL
                                                                AND i_laterality.count > 0 THEN
                                                            i_laterality(i)
                                                           ELSE
                                                            NULL
                                                       END,
                           flg_laterality_nin       => FALSE,
                           flg_collection_method_in => i_collection_method(i),
                           id_specimen_condition_in => CASE
                                                           WHEN i_specimen_condition IS NOT NULL
                                                                AND i_specimen_condition.count > 0 THEN
                                                            i_specimen_condition(i)
                                                           ELSE
                                                            NULL
                                                       END,
                           id_room_harvest_in       => CASE
                                                           WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                pk_lab_tests_constant.g_yes THEN
                                                            i_collection_room(i)
                                                           ELSE
                                                            NULL
                                                       END,
                           flg_col_inst_in          => CASE
                                                           WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                pk_lab_tests_constant.g_yes THEN
                                                            NULL
                                                           ELSE
                                                            i_collection_room(i)
                                                       END,
                           id_room_receive_tube_in  => i_lab(i),
                           id_institution_in        => CASE
                                                           WHEN i_exec_institution(i) IS NULL THEN
                                                            i_prof.institution
                                                           ELSE
                                                            i_exec_institution(i)
                                                       END,
                           num_recipient_in         => i_num_recipient(i),
                           amount_in                => i_collection_amount(i),
                           amount_nin               => FALSE,
                           flg_mov_tube_in          => i_collection_transportation(i),
                           notes_in                 => i_notes(i),
                           flg_orig_harvest_in      => i_flg_orig_harvest,
                           rows_out                 => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- Process ANALYSIS_HARVEST records
            FOR j IN 1 .. i_analysis_harvest(i).count
            LOOP
            
                IF i_analysis_harvest(i) (j) IS NULL
                THEN
                    g_error := 'I_ANALYSIS_HARVEST(' || i || ')(' || j || ') parameter has no ID';
                    RAISE g_other_exception;
                END IF;
            
                -- Check if ANALYSIS_HARVEST needs to be updated
                g_error := 'Get ANALYSIS_HARVEST, ID_SAMPLE_RECIPIENT and NUM_RECIPIENT';
                SELECT ah.id_sample_recipient, ah.num_recipient
                  INTO l_sample_recipient, l_aharv_num_recipient
                  FROM analysis_harvest ah
                 WHERE ah.id_analysis_harvest = i_analysis_harvest(i) (j);
            
                -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table        
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_harvest          => NULL,
                                                                     i_analysis_harvest => i_analysis_harvest(i) (j),
                                                                     o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Update ANALYSIS_HARVEST data
                g_error    := 'CALL TS_ANALYSIS_HARVEST.UPD';
                l_rows_out := NULL;
                ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i) (j),
                                        id_sample_recipient_in => i_sample_recipient(i),
                                        num_recipient_in       => i_num_recipient(i),
                                        rows_out               => l_rows_out);
            
                -- Harvest Data Governance Process
                g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_HARVEST',
                                              i_list_columns => table_varchar('ID_SAMPLE_RECIPIENT', 'NUM_RECIPIENT'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            END LOOP;
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
                                              'SET_HARVEST_EDIT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_edit;

    FUNCTION set_harvest_combine
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN table_number, --5
        i_analysis_harvest          IN table_table_number,
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE, --10
        i_exec_institution          IN harvest.id_institution%TYPE,
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --15
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN VARCHAR2,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE DEFAULT 'A',
        o_harvest                   OUT harvest.id_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_harvest          harvest.id_harvest%TYPE;
        l_harvest_group    harvest.id_harvest_group%TYPE;
        l_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
        l_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
    
        -- Check and validate input array's data
        IF i_harvest.count = 0
        THEN
            g_error := 'I_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_analysis_harvest.count = 0
        THEN
            g_error := 'I_ANALYSIS_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_harvest.count != i_analysis_harvest.count
        THEN
            g_error := 'I_HARVEST array has different number of elements than I_ANALYSIS_HARVEST';
            RAISE g_other_exception;
        END IF;
    
        -- Process each harvest    
        FOR i IN 1 .. i_harvest.count
        LOOP
            IF i_harvest(i) IS NULL
            THEN
                g_error := 'I_HARVEST(' || i || ') parameter has no ID';
                RAISE g_other_exception;
            END IF;
        
            -- Process current HARVEST to HARVEST_HIST table        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
            IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_harvest          => i_harvest(i),
                                                                 i_analysis_harvest => NULL,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Set HARVEST status to Inactive
            g_error := 'Set HARVEST status to Inactive';
            ts_harvest.upd(id_harvest_in => i_harvest(i),
                           flg_status_in => pk_lab_tests_constant.g_harvest_inactive,
                           rows_out      => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('FLG_STATUS'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => pk_lab_tests_constant.g_harvest_inactive,
                                    i_id_record  => i_harvest(i),
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Process ANALYSIS_HARVEST records
            FOR j IN 1 .. i_analysis_harvest(i).count
            LOOP
            
                IF i_analysis_harvest(i) (j) IS NULL
                THEN
                    g_error := 'I_ANALYSIS_HARVEST(' || i || ')(' || j || ') parameter has no ID';
                    RAISE g_other_exception;
                END IF;
            
                -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_harvest          => NULL,
                                                                     i_analysis_harvest => i_analysis_harvest(i) (j),
                                                                     o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_rows_out := NULL;
                -- Set ANALYSIS_HARVEST status to Inactive
                g_error := 'Set ANALYSIS_HARVEST status to Inactive';
                ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i) (j),
                                        flg_status_in          => pk_lab_tests_constant.g_inactive,
                                        rows_out               => l_rows_out);
            
                -- Harvest Data Governance Process
                g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_HARVEST',
                                              i_list_columns => table_varchar('FLG_STATUS'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            END LOOP;
        END LOOP;
    
        -- Get new ID_HARVEST_GROUP
        g_error := 'Get new ID_HARVEST_GROUP';
        SELECT seq_harvest_group.nextval
          INTO l_harvest_group
          FROM dual;
    
        -- create NEW pending harvest
        l_rows_out := NULL;
    
        g_error := 'CALL TS_HARVEST.INS';
        ts_harvest.ins(id_harvest_out           => l_harvest,
                       id_harvest_group_in      => l_harvest_group,
                       id_patient_in            => i_patient,
                       id_episode_in            => i_episode,
                       id_visit_in              => pk_visit.get_visit(i_episode, o_error),
                       flg_status_in            => pk_lab_tests_constant.g_harvest_pending,
                       dt_harvest_reg_tstz_in   => g_sysdate_tstz,
                       flg_collection_method_in => i_collection_method,
                       id_specimen_condition_in => i_specimen_condition,
                       id_room_harvest_in       => CASE
                                                       WHEN pk_utils.is_number(i_collection_room) =
                                                            pk_lab_tests_constant.g_yes THEN
                                                        i_collection_room
                                                       ELSE
                                                        NULL
                                                   END,
                       flg_col_inst_in          => CASE
                                                       WHEN pk_utils.is_number(i_collection_room) =
                                                            pk_lab_tests_constant.g_yes THEN
                                                        NULL
                                                       ELSE
                                                        i_collection_room
                                                   END,
                       id_room_receive_tube_in  => i_lab,
                       id_institution_in        => i_exec_institution,
                       num_recipient_in         => i_num_recipient,
                       dt_harvest_tstz_in       => nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_collection_time, NULL),
                                                       g_sysdate_tstz),
                       amount_in                => i_collection_amount,
                       flg_mov_tube_in          => i_collection_transportation,
                       notes_in                 => i_notes,
                       flg_orig_harvest_in      => i_flg_orig_harvest,
                       rows_out                 => l_rows_out);
    
        -- Harvest Data Governance Process
        g_error := 'CALL PROCESS_INSERT FOR HARVEST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'HARVEST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        o_harvest := l_harvest;
    
        -- Insert on Status Log Table
        g_error := 'CALL T_TI_LOG.INS_LOG';
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => i_episode,
                                i_flg_status => pk_lab_tests_constant.g_harvest_pending,
                                i_id_record  => l_harvest,
                                i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        -- Create new ANALYSIS_HARVEST records for the new HARVEST
        FOR i IN 1 .. i_harvest.count
        LOOP
            FOR j IN 1 .. i_analysis_harvest(i).count
            LOOP
                -- Get ID_ANALYSIS_REQ_DET
                g_error := 'Get ID_ANALYSIS_REQ_DET';
                SELECT ah.id_analysis_req_det
                  INTO l_analysis_req_det
                  FROM analysis_harvest ah
                 WHERE ah.id_analysis_harvest = i_analysis_harvest(i) (j);
            
                l_rows_out := NULL;
                -- Link Harvest Created to Lab Test Request
                g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                ts_analysis_harvest.ins(id_analysis_harvest_out => l_analysis_harvest,
                                        id_analysis_req_det_in  => l_analysis_req_det,
                                        id_harvest_in           => l_harvest,
                                        id_sample_recipient_in  => i_sample_recipient,
                                        num_recipient_in        => i_num_recipient,
                                        flg_status_in           => pk_lab_tests_constant.g_active,
                                        rows_out                => l_rows_out);
            
                -- Analysis Harvest Data Governance Process
                g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
                -- Create relation between Original Analysis Harvest and the New Ones Combined
                g_error := 'Create relation between original analysis Harvest and the new ones Combined';
                INSERT INTO analysis_harv_comb_div
                    (dt_comb_div, id_analysis_harv_orig, id_analysis_harv_dest, flg_comb_div)
                VALUES
                    (g_sysdate_tstz,
                     i_analysis_harvest(i) (j),
                     l_analysis_harvest,
                     pk_lab_tests_constant.g_aharvest_combined);
            END LOOP;
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
                                              'SET_HARVEST_COMBINE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_combine;

    FUNCTION set_harvest_repeat
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_visit                     IN visit.id_visit%TYPE,
        i_episode                   IN episode.id_episode%TYPE, --5
        i_harvest                   IN harvest.id_harvest%TYPE,
        i_analysis_harvest          IN table_number,
        i_analysis_req_det          IN table_number,
        i_body_location             IN harvest.id_body_part%TYPE,
        i_laterality                IN harvest.flg_laterality%TYPE, --10
        i_collection_method         IN harvest.flg_collection_method%TYPE,
        i_specimen_condition        IN harvest.id_specimen_condition%TYPE,
        i_collection_room           IN VARCHAR2,
        i_lab                       IN harvest.id_room_receive_tube%TYPE,
        i_exec_institution          IN harvest.id_institution%TYPE, --15
        i_sample_recipient          IN sample_recipient.id_sample_recipient%TYPE,
        i_num_recipient             IN harvest.num_recipient%TYPE,
        i_collected_by              IN harvest.id_prof_harvest%TYPE,
        i_collection_time           IN VARCHAR2,
        i_collection_amount         IN harvest.amount%TYPE, --20
        i_collection_transportation IN harvest.flg_mov_tube%TYPE,
        i_notes                     IN harvest.notes%TYPE,
        i_rep_coll_reason           IN repeat_collection_reason.id_rep_coll_reason%TYPE,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_new_id_harvest  harvest.id_harvest%TYPE;
        l_harvest_group   harvest.id_harvest_group%TYPE;
        l_harvest_barcode harvest.barcode%TYPE;
    
        l_new_id_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
    
        -- Get Current ID_HARVEST_GROUP and BARCODE
        g_error := 'Get Current ID_HARVEST_GROUP and BARCODE';
        SELECT h.id_harvest_group, h.barcode
          INTO l_harvest_group, l_harvest_barcode
          FROM harvest h
         WHERE h.id_harvest = i_harvest;
    
        ---    
        -- Create new HARVEST
        g_error := 'CALL TS_HARVEST.INS';
        ts_harvest.ins(id_harvest_out           => l_new_id_harvest,
                       id_harvest_group_in      => l_harvest_group,
                       id_patient_in            => i_patient,
                       id_episode_in            => i_episode,
                       id_visit_in              => i_visit,
                       id_prof_harvest_in       => nvl(i_collected_by, i_prof.id),
                       dt_harvest_reg_tstz_in   => g_sysdate_tstz,
                       flg_status_in            => pk_lab_tests_constant.g_harvest_repeated,
                       id_body_part_in          => i_body_location,
                       flg_laterality_in        => i_laterality,
                       flg_collection_method_in => i_collection_method,
                       id_specimen_condition_in => i_specimen_condition,
                       id_room_harvest_in       => CASE
                                                       WHEN pk_utils.is_number(i_collection_room) =
                                                            pk_lab_tests_constant.g_yes THEN
                                                        i_collection_room
                                                       ELSE
                                                        NULL
                                                   END,
                       flg_col_inst_in          => CASE
                                                       WHEN pk_utils.is_number(i_collection_room) =
                                                            pk_lab_tests_constant.g_yes THEN
                                                        NULL
                                                       ELSE
                                                        i_collection_room
                                                   END,
                       id_room_receive_tube_in  => i_lab,
                       id_institution_in        => CASE
                                                       WHEN i_exec_institution IS NOT NULL THEN
                                                        i_exec_institution
                                                       ELSE
                                                        i_prof.institution
                                                   END,
                       num_recipient_in         => i_num_recipient,
                       dt_harvest_tstz_in       => nvl(pk_date_utils.get_string_tstz(i_lang, i_prof, i_collection_time, NULL),
                                                       g_sysdate_tstz),
                       amount_in                => i_collection_amount,
                       id_prof_mov_tube_in      => i_prof.id,
                       flg_mov_tube_in          => i_collection_transportation,
                       notes_in                 => i_notes,
                       barcode_in               => l_harvest_barcode,
                       dt_mov_begin_tstz_in     => g_sysdate_tstz,
                       dt_lab_reception_tstz_in => g_sysdate_tstz,
                       id_prof_receive_tube_in  => i_prof.id,
                       -- If flg_print does not have any value, proceed with S (Screen not shown)
                       flg_print_in          => 'S',
                       flg_orig_harvest_in   => i_flg_orig_harvest,
                       id_rep_coll_reason_in => i_rep_coll_reason,
                       rows_out              => l_rows_out);
    
        -- Harvest Data Governance Process
        g_error := 'CALL PROCESS_INSERT FOR HARVEST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'HARVEST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        -- Insert on Status Log Table
        g_error := 'CALL T_TI_LOG.INS_LOG';
        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                i_prof       => i_prof,
                                i_id_episode => i_episode,
                                i_flg_status => pk_lab_tests_constant.g_harvest_repeated,
                                i_id_record  => l_new_id_harvest,
                                i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_rows_out := NULL;
        -- Link Harvest Created to Lab Test Request
        FOR i IN 1 .. i_analysis_harvest.count
        LOOP
            -- Link Harvest Created to Lab Test Request
            g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
            ts_analysis_harvest.ins(id_analysis_harvest_out => l_new_id_analysis_harvest,
                                    id_analysis_req_det_in  => i_analysis_req_det(i),
                                    id_harvest_in           => l_new_id_harvest,
                                    id_sample_recipient_in  => i_sample_recipient,
                                    num_recipient_in        => i_num_recipient,
                                    flg_status_in           => pk_lab_tests_constant.g_active,
                                    rows_out                => l_rows_out);
        END LOOP;
    
        -- Analysis Harvest Data Governance Process
        g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANALYSIS_HARVEST',
                                      i_rowids     => l_rows_out,
                                      o_error      => o_error);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HARVEST_REPEAT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_repeat;

    FUNCTION set_harvest_divide
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_analysis_harvest          IN table_table_number, --5
        i_flg_divide                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number,
        i_exec_institution          IN table_number, --10
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collection_time           IN table_varchar,
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar, --15
        i_notes                     IN table_varchar,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_harvest            harvest.id_harvest%TYPE;
        l_origin_id_harvest     harvest.id_harvest%TYPE;
        l_new_id_harvest        harvest.id_harvest%TYPE;
        l_harvest_group         harvest.id_harvest_group%TYPE;
        l_id_room_harvest       harvest.id_room_harvest%TYPE;
        l_harvest_num_recipient harvest.num_recipient%TYPE;
        l_harvest_notes         harvest.notes%TYPE;
    
        l_new_id_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
        l_sample_recipient        analysis_harvest.id_sample_recipient%TYPE;
        l_aharv_num_recipient     analysis_harvest.num_recipient%TYPE;
    
        l_id_analysis_req_det analysis_req_det.id_analysis_req_det%TYPE;
    
        l_divide_all BOOLEAN;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
        l_divide_all   := TRUE;
    
        -- Validate input parameters
        -- Check if array have elements
        IF i_analysis_harvest.count = 0
        THEN
            g_error := 'I_ANALYSIS_HARVEST parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_flg_divide.count = 0
        THEN
            g_error := 'I_FLG_DIVIDE parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_collection_room.count = 0
        THEN
            g_error := 'I_COLLECTION_ROOM parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_sample_recipient.count = 0
        THEN
            g_error := 'I_SAMPLE_RECIPIENT parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        IF i_num_recipient.count = 0
        THEN
            g_error := 'I_NUM_RECIPIENT parameter has no data';
            RAISE g_other_exception;
        END IF;
    
        -- Check if the array's have the same number of elements    
        IF i_analysis_harvest.count != i_flg_divide.count
           OR i_flg_divide.count != i_collection_room.count
           OR i_collection_room.count != i_sample_recipient.count
           OR i_sample_recipient.count != i_num_recipient.count
        THEN
            g_error := 'Input arrays has different number of elements';
            RAISE g_other_exception;
        END IF;
    
        -- Process each analysis_harvest array
        FOR i IN 1 .. i_analysis_harvest.count
        LOOP
        
            IF i_analysis_harvest(i).count = 0
            THEN
                g_error := 'I_ANALYSIS_HARVEST(' || i || ') array has no data';
                RAISE g_other_exception;
            END IF;
        
            IF i_flg_divide(i) IS NULL
            THEN
                g_error := 'I_FLG_DIVIDE(' || i || ') parameter has no data';
                RAISE g_other_exception;
            END IF;
        
            IF i_sample_recipient(i) IS NULL
            THEN
                g_error := 'I_SAMPLE_RECIPIENT(' || i || ')  parameter has no data';
                RAISE g_other_exception;
            END IF;
        
            IF i_num_recipient(i) IS NULL
            THEN
                g_error := 'I_NUM_RECIPIENT(' || i || ')  parameter has no data';
                RAISE g_other_exception;
            END IF;
        
            -- Check if this harvest is to be divided
            IF i_flg_divide(i) = pk_lab_tests_constant.g_yes
            THEN
            
                -- Process ANALYSIS_HARVEST records
                FOR j IN 1 .. i_analysis_harvest(i).count
                LOOP
                
                    IF i_analysis_harvest(i) (j) IS NULL
                    THEN
                        g_error := 'I_ANALYSIS_HARVEST(' || i || ')(' || j || ') parameter has no ID';
                        RAISE g_other_exception;
                    END IF;
                
                    SELECT ah.id_analysis_req_det, ah.id_harvest
                      INTO l_id_analysis_req_det, l_id_harvest
                      FROM analysis_harvest ah
                     WHERE ah.id_analysis_harvest = i_analysis_harvest(i) (j);
                
                    l_origin_id_harvest := l_id_harvest;
                
                    -- Set current ANALYSIS_HARVEST to Inactive
                    -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table
                    g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                    IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                         i_prof             => i_prof,
                                                                         i_harvest          => NULL,
                                                                         i_analysis_harvest => i_analysis_harvest(i) (j),
                                                                         o_error            => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    -- Set ANALYSIS_HARVEST status to Inactive
                    g_error := 'Set ANALYSIS_HARVEST status to Inactive';
                    ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i) (j),
                                            flg_status_in          => pk_lab_tests_constant.g_inactive,
                                            rows_out               => l_rows_out);
                
                    -- Harvest Data Governance Process
                    g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ANALYSIS_HARVEST',
                                                  i_list_columns => table_varchar('FLG_STATUS'),
                                                  i_rowids       => l_rows_out,
                                                  o_error        => o_error);
                
                    -- Create new HARVEST
                    -- Get new ID_HARVEST_GROUP
                    g_error := 'Get new ID_HARVEST_GROUP';
                    SELECT seq_harvest_group.nextval
                      INTO l_harvest_group
                      FROM dual;
                
                    l_rows_out := NULL;
                    -- Create New Harvest
                    g_error := 'CALL TS_HARVEST.INS';
                    ts_harvest.ins(id_harvest_out           => l_new_id_harvest,
                                   id_harvest_group_in      => l_harvest_group,
                                   id_patient_in            => i_patient,
                                   id_episode_in            => i_episode,
                                   id_visit_in              => pk_visit.get_visit(i_episode, o_error),
                                   flg_status_in            => pk_lab_tests_constant.g_harvest_pending,
                                   dt_harvest_reg_tstz_in   => g_sysdate_tstz,
                                   flg_collection_method_in => i_collection_method(i),
                                   id_room_harvest_in       => CASE
                                                                   WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                        pk_lab_tests_constant.g_yes THEN
                                                                    i_collection_room(i)
                                                                   ELSE
                                                                    NULL
                                                               END,
                                   flg_col_inst_in          => CASE
                                                                   WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                        pk_lab_tests_constant.g_yes THEN
                                                                    NULL
                                                                   ELSE
                                                                    i_collection_room(i)
                                                               END,
                                   id_room_receive_tube_in  => i_lab(i),
                                   id_institution_in        => i_exec_institution(i),
                                   num_recipient_in         => i_num_recipient(i),
                                   dt_harvest_tstz_in       => nvl(pk_date_utils.get_string_tstz(i_lang,
                                                                                                 i_prof,
                                                                                                 i_collection_time(i),
                                                                                                 NULL),
                                                                   g_sysdate_tstz),
                                   amount_in                => i_collection_amount(i),
                                   flg_mov_tube_in          => i_collection_transportation(i),
                                   notes_in                 => i_notes(i),
                                   flg_orig_harvest_in      => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                                   rows_out                 => l_rows_out);
                
                    -- Harvest Data Governance Process
                    g_error := 'CALL PROCESS_INSERT FOR HARVEST';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    -- Insert on Status Log Table
                    g_error := 'CALL T_TI_LOG.INS_LOG';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_harvest_pending,
                                            i_id_record  => l_new_id_harvest,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    l_rows_out := NULL;
                    -- Link Harvest Created to Lab Test Request
                
                /* g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                                    ts_analysis_harvest.ins(id_analysis_harvest_out => l_new_id_analysis_harvest,
                                                            id_analysis_req_det_in  => l_id_analysis_req_det,
                                                            id_harvest_in           => l_new_id_harvest,
                                                            id_sample_recipient_in  => i_sample_recipient(i),
                                                            num_recipient_in        => i_num_recipient(i),
                                                            flg_status_in           => pk_lab_tests_constant.g_active,
                                                            rows_out                => l_rows_out);
                                
                                    -- Analysis Harvest Data Governance Process
                                    g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_table_name => 'ANALYSIS_HARVEST',
                                                                  i_rowids     => l_rows_out,
                                                                  o_error      => o_error);
                                
                                    -- Create relation between Original Analysis Harvest and the New Ones Combined
                                    g_error := 'Create relation between original analysis Harvest and the new ones Combined';
                                    INSERT INTO analysis_harv_comb_div
                                        (dt_comb_div, id_analysis_harv_orig, id_analysis_harv_dest, flg_comb_div)
                                    VALUES
                                        (g_sysdate_tstz,
                                         i_analysis_harvest(i) (j),
                                         l_new_id_analysis_harvest,
                                         pk_lab_tests_constant.g_aharvest_divided);*/
                END LOOP;
            ELSE
            
                --l_divide_all := FALSE;
            
                -- Process ANALYSIS_HARVEST records
                FOR j IN 1 .. i_analysis_harvest(i).count
                LOOP
                
                    --
                    -- Check if ANALYSIS_HARVEST needs to be updated
                    g_error := 'Get ANALYSIS_HARVEST, ID_SAMPLE_RECIPIENT and NUM_RECIPIENT';
                    SELECT ah.id_sample_recipient, ah.num_recipient
                      INTO l_sample_recipient, l_aharv_num_recipient
                      FROM analysis_harvest ah
                     WHERE ah.id_analysis_harvest = i_analysis_harvest(i) (j);
                
                    IF l_sample_recipient != i_sample_recipient(i)
                       OR l_aharv_num_recipient != i_num_recipient(i)
                    THEN
                        -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table
                        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                        IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_harvest          => NULL,
                                                                             i_analysis_harvest => i_analysis_harvest(i) (j),
                                                                             o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        l_rows_out := NULL;
                        -- Update ANALYSIS_HARVEST data
                        g_error := 'Update ANALYSIS_HARVEST data';
                        ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i) (j),
                                                id_sample_recipient_in => i_sample_recipient(i),
                                                num_recipient_in       => i_num_recipient(i),
                                                rows_out               => l_rows_out);
                    
                        -- Harvest Data Governance Process
                        g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                      i_prof         => i_prof,
                                                      i_table_name   => 'ANALYSIS_HARVEST',
                                                      i_list_columns => table_varchar('ID_SAMPLE_RECIPIENT',
                                                                                      'NUM_RECIPIENT'),
                                                      i_rowids       => l_rows_out,
                                                      o_error        => o_error);
                    
                    END IF;
                    -- Check if HARVEST needs to be updated
                    --
                    -- Get ID_HARVEST
                    g_error := 'Get ID_HARVEST';
                    SELECT h.id_harvest, h.id_room_harvest, h.num_recipient, h.notes
                      INTO l_id_harvest, l_id_room_harvest, l_harvest_num_recipient, l_harvest_notes
                      FROM analysis_harvest ah, harvest h
                     WHERE ah.id_analysis_harvest = i_analysis_harvest(i) (j)
                       AND h.id_harvest = ah.id_harvest;
                
                    ts_analysis_harvest.upd(id_analysis_harvest_in => i_analysis_harvest(i) (j),
                                            id_harvest_in          => l_new_id_harvest,
                                            rows_out               => l_rows_out);
                
                    -- Analysis Harvest Data Governance Process
                    g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                    t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'ANALYSIS_HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    g_error := 'Create relation between original analysis Harvest and the new ones Combined';
                    /*INSERT INTO analysis_harv_comb_div
                        (dt_comb_div, id_analysis_harv_orig, id_analysis_harv_dest, flg_comb_div)
                    VALUES
                        (g_sysdate_tstz,
                         i_analysis_harvest(i) (j),
                         l_new_id_analysis_harvest,
                         pk_lab_tests_constant.g_aharvest_divided);*/
                
                    IF ((pk_utils.is_number(i_collection_room(i)) = pk_lab_tests_constant.g_yes AND
                       i_collection_room(i) != l_id_room_harvest AND i_collection_room(i) IS NOT NULL) OR
                       (l_id_room_harvest IS NULL AND i_num_recipient(i) IS NOT NULL))
                       OR ((i_num_recipient(i) != l_harvest_num_recipient AND i_num_recipient(i) IS NOT NULL) OR
                       (l_harvest_num_recipient IS NULL AND i_num_recipient(i) IS NOT NULL))
                       OR ((i_notes(i) != l_harvest_notes AND i_notes(i) IS NOT NULL) OR
                       (l_harvest_notes IS NULL AND i_notes(i) IS NOT NULL))
                    THEN
                    
                        -- Process current HARVEST to HARVEST_HIST table        
                        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                        IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                             i_prof             => i_prof,
                                                                             i_harvest          => l_id_harvest,
                                                                             i_analysis_harvest => NULL,
                                                                             o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    
                        l_rows_out := NULL;
                        -- Update HARVEST data
                        g_error := 'Update HARVEST data';
                        ts_harvest.upd(id_harvest_in           => l_id_harvest,
                                       id_room_harvest_in      => CASE
                                                                      WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                           pk_lab_tests_constant.g_yes THEN
                                                                       i_collection_room(i)
                                                                      ELSE
                                                                       NULL
                                                                  END,
                                       flg_col_inst_in         => CASE
                                                                      WHEN pk_utils.is_number(i_collection_room(i)) =
                                                                           pk_lab_tests_constant.g_yes THEN
                                                                       NULL
                                                                      ELSE
                                                                       i_collection_room(i)
                                                                  END,
                                       id_room_receive_tube_in => i_lab(i),
                                       id_institution_in       => i_exec_institution(i),
                                       num_recipient_in        => i_num_recipient(i),
                                       amount_in               => i_collection_amount(i),
                                       flg_mov_tube_in         => i_collection_transportation(i),
                                       notes_in                => i_notes(i),
                                       notes_nin               => FALSE,
                                       rows_out                => l_rows_out);
                    
                        -- Harvest Data Governance Process
                        g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
                        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_table_name => 'HARVEST',
                                                      i_rowids     => l_rows_out,
                                                      o_error      => o_error);
                    END IF;
                END LOOP;
            END IF;
        END LOOP;
    
        -- Check if all harvest's where divided
        -- If so, the original one should be deactived
        IF l_divide_all
        THEN
            -- Set HARVEST status to Inactive
            --
            -- Process current HARVEST to HARVEST_HIST table        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
            IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_harvest          => l_id_harvest,
                                                                 i_analysis_harvest => NULL,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_rows_out := NULL;
            -- Set HARVEST status to Inactive
            g_error := 'Set HARVEST status to Inactive';
            ts_harvest.upd(id_harvest_in => l_origin_id_harvest,
                           flg_status_in => pk_lab_tests_constant.g_harvest_inactive,
                           rows_out      => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_UPDATE FOR HARVEST';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('FLG_STATUS'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => pk_lab_tests_constant.g_harvest_inactive,
                                    i_id_record  => l_origin_id_harvest,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
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
                                              'SET_HARVEST_DIVIDE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_divide;

    FUNCTION set_harvest_divide_and_collect
    (
        i_lang                      IN language.id_language%TYPE, --1
        i_prof                      IN profissional,
        i_patient                   IN patient.id_patient%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_harvest                   IN harvest.id_harvest%TYPE, --5
        i_analysis_harvest          IN table_table_number,
        i_analysis_req_det          IN table_table_number,
        i_flg_divide                IN table_varchar,
        i_flg_collect               IN table_varchar,
        i_body_location             IN table_number, --10
        i_laterality                IN table_varchar,
        i_collection_method         IN table_varchar,
        i_specimen_condition        IN table_number,
        i_collection_room           IN table_varchar,
        i_lab                       IN table_number, --15
        i_exec_institution          IN table_number,
        i_sample_recipient          IN table_number,
        i_num_recipient             IN table_number,
        i_collected_by              IN table_number,
        i_collection_time           IN table_varchar, --20
        i_collection_amount         IN table_varchar,
        i_collection_transportation IN table_varchar,
        i_notes                     IN table_varchar,
        i_flg_orig_harvest          IN harvest.flg_orig_harvest%TYPE,
        o_harvest                   OUT table_number, --25
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det table_number;
        l_analysis_harvest table_number;
        l_harvest          harvest.id_harvest%TYPE;
    
    BEGIN
        -- Input Array's validation are performed 
        -- in DIVIDE_HARVEST and COLLECT_HARVEST functions
        g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_DIVIDE';
        IF NOT pk_lab_tests_harvest_core.set_harvest_divide(i_lang                      => i_lang,
                                                            i_prof                      => i_prof,
                                                            i_patient                   => i_patient,
                                                            i_episode                   => i_episode,
                                                            i_analysis_harvest          => i_analysis_harvest,
                                                            i_flg_divide                => i_flg_divide,
                                                            i_collection_method         => i_collection_method,
                                                            i_collection_room           => i_collection_room,
                                                            i_lab                       => i_lab,
                                                            i_exec_institution          => i_exec_institution,
                                                            i_sample_recipient          => i_sample_recipient,
                                                            i_num_recipient             => i_num_recipient,
                                                            i_collection_time           => i_collection_time,
                                                            i_collection_amount         => i_collection_amount,
                                                            i_collection_transportation => i_collection_transportation,
                                                            i_notes                     => i_notes,
                                                            o_error                     => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        o_harvest := table_number();
    
        -- Process each harvest on array
        FOR i IN 1 .. i_analysis_harvest.count
        LOOP
            IF i_flg_divide(i) IS NULL
            THEN
                g_error := 'I_FLG_DIVIDE(' || i || ') parameter has no data';
                RAISE g_other_exception;
            END IF;
        
            IF i_flg_collect(i) IS NULL
            THEN
                g_error := 'I_FLG_COLLECT(' || i || ') parameter has no data';
                RAISE g_other_exception;
            END IF;
        
            -- Check if this harvest is to be collected
            g_error := 'Check if this harvest is to be collected';
            IF i_flg_collect(i) = pk_lab_tests_constant.g_yes
            THEN
            
                -- Check if this harvest was divided
                -- If so, new ID's should be retrieved
                g_error := 'Check if this harvest was divided';
                IF i_flg_divide(i) = pk_lab_tests_constant.g_yes
                THEN
                    l_analysis_harvest := table_number();
                    l_analysis_req_det := table_number();
                
                    l_analysis_harvest.extend;
                    l_analysis_req_det.extend;
                
                    -- Array with divide data, have only one element, the one to be divided 
                    g_error := 'Get new HARVEST, ANALYSIS_HARVEST and ANALYSIS_REQ_DET IDs';
                    SELECT ah.id_harvest, ah.id_analysis_harvest, ah.id_analysis_req_det
                      INTO l_harvest, l_analysis_harvest(1), l_analysis_req_det(1)
                      FROM analysis_harvest ah, analysis_harv_comb_div acd
                     WHERE acd.id_analysis_harv_orig IN
                           (SELECT *
                              FROM TABLE(i_analysis_harvest(i)))
                       AND acd.flg_comb_div = pk_lab_tests_constant.g_aharvest_divided
                       AND ah.id_analysis_harvest = acd.id_analysis_harv_dest;
                
                ELSE
                    g_error            := 'Use current HARVEST, ANALYSIS_HARVEST and ANALYSIS_REQ_DET IDs';
                    l_harvest          := i_harvest;
                    l_analysis_harvest := i_analysis_harvest(i);
                    l_analysis_req_det := i_analysis_req_det(i);
                END IF;
            
                -- Get new analysis_harvest Id's
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_COLLECT_HARVEST';
                IF NOT pk_lab_tests_harvest_core.set_harvest_collect(i_lang                      => i_lang,
                                                                i_prof                      => i_prof,
                                                                i_episode                   => i_episode,
                                                                i_harvest                   => l_harvest,
                                                                i_analysis_harvest          => l_analysis_harvest,
                                                                i_analysis_req_det          => l_analysis_req_det,
                                                                i_body_location             => i_body_location(i),
                                                                i_laterality                => CASE
                                                                                                   WHEN i_laterality IS NOT NULL
                                                                                                        AND i_laterality.count > 0 THEN
                                                                                                    i_laterality(i)
                                                                                                   ELSE
                                                                                                    NULL
                                                                                               END,
                                                                i_collection_method         => i_collection_method(i),
                                                                i_specimen_condition        => CASE
                                                                                                   WHEN i_specimen_condition IS NOT NULL
                                                                                                        AND i_specimen_condition.count > 0 THEN
                                                                                                    i_specimen_condition(i)
                                                                                                   ELSE
                                                                                                    NULL
                                                                                               END,
                                                                i_collection_room           => i_collection_room(i),
                                                                i_lab                       => i_lab(i),
                                                                i_exec_institution          => i_exec_institution(i),
                                                                i_sample_recipient          => i_sample_recipient(i),
                                                                i_num_recipient             => i_num_recipient(i),
                                                                i_collected_by              => i_collected_by(i),
                                                                i_collection_time           => i_collection_time(i),
                                                                i_collection_amount         => i_collection_amount(i),
                                                                i_collection_transportation => i_collection_transportation(i),
                                                                i_notes                     => i_notes(i),
                                                                i_flg_rep_collection        => pk_lab_tests_constant.g_no,
                                                                i_rep_coll_reason           => NULL,
                                                                i_flg_orig_harvest          => i_flg_orig_harvest,
                                                                o_error                     => o_error)
                
                THEN
                    RAISE g_other_exception;
                END IF;
            
                o_harvest.extend;
                o_harvest(o_harvest.count) := l_harvest;
            END IF; -- Check i_flg_collect
        END LOOP; -- Process each harvest array
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'SET_HARVEST_DIVIDE_AND_COLLECT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_divide_and_collect;

    FUNCTION set_harvest_questionnaire
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_analysis_req_det IN table_number,
        i_harvest          IN table_number,
        i_questionnaire    IN table_table_number,
        i_response         IN table_table_varchar,
        i_notes            IN table_table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_questionnaire table_number := table_number();
        l_response      table_varchar := table_varchar();
        l_notes         table_varchar := table_varchar();
    
        l_aux table_varchar2;
    
    BEGIN
    
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'LOOP I_ANALYSIS_REQ_DET';
        FOR i IN 1 .. i_analysis_req_det.count
        LOOP
        
            l_questionnaire := table_number();
            l_response      := table_varchar();
            l_notes         := table_varchar();
        
            FOR j IN i_questionnaire(i).first .. i_questionnaire(i).last
            LOOP
                l_questionnaire.extend;
                l_response.extend;
                l_notes.extend;
            
                l_questionnaire(j) := i_questionnaire(i) (j);
                l_response(j) := i_response(i) (j);
                l_notes(j) := i_notes(i) (j);
            END LOOP;
        
            g_error := 'LOOP L_QUESTIONNAIRE';
            FOR k IN 1 .. l_questionnaire.count
            LOOP
                IF l_response(k) IS NOT NULL
                THEN
                    l_aux := pk_utils.str_split(l_response(k), '|');
                
                    FOR x IN 1 .. l_aux.count
                    LOOP
                        g_error := 'INSERT INTO ANALYSIS_QUESTION_RESPONSE 1';
                        INSERT INTO analysis_question_response
                            (id_analysis_question_response,
                             id_episode,
                             id_analysis_req_det,
                             id_harvest,
                             id_questionnaire,
                             id_response,
                             notes,
                             id_prof_last_update,
                             dt_last_update_tstz)
                        VALUES
                            (seq_analysis_question_response.nextval,
                             i_episode,
                             i_analysis_req_det(i),
                             i_harvest(i),
                             l_questionnaire(k),
                             to_number(l_aux(x)),
                             l_notes(k),
                             i_prof.id,
                             g_sysdate_tstz);
                    END LOOP;
                ELSE
                    g_error := 'INSERT INTO ANALYSIS_QUESTION_RESPONSE 2';
                    INSERT INTO analysis_question_response
                        (id_analysis_question_response,
                         id_episode,
                         id_analysis_req_det,
                         id_harvest,
                         id_questionnaire,
                         id_response,
                         notes,
                         id_prof_last_update,
                         dt_last_update_tstz)
                    VALUES
                        (seq_analysis_question_response.nextval,
                         i_episode,
                         i_analysis_req_det(i),
                         i_harvest(i),
                         l_questionnaire(k),
                         NULL,
                         l_notes(k),
                         i_prof.id,
                         g_sysdate_tstz);
                END IF;
            END LOOP;
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
                                              'SET_HARVEST_QUESTIONNAIRE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_questionnaire;

    FUNCTION set_harvest_reject
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_harvest            IN table_number,
        i_cancel_reason      IN harvest.id_cancel_reason%TYPE,
        i_cancel_notes       IN harvest.notes_cancel%TYPE,
        i_specimen_condition IN harvest.id_specimen_condition%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis(l_harvest IN harvest.id_harvest%TYPE) IS
            SELECT ah.id_analysis_harvest,
                   ah.id_sample_recipient,
                   ah.num_recipient,
                   ard.id_analysis_req,
                   ard.id_analysis_req_det,
                   ard.flg_prn
              FROM analysis_harvest ah, analysis_req_det ard
             WHERE ah.id_harvest = l_harvest
               AND ah.flg_status = pk_lab_tests_constant.g_active
               AND ah.id_analysis_req_det = ard.id_analysis_req_det;
    
        l_harvest harvest%ROWTYPE;
    
        l_flg_status harvest.flg_status%TYPE;
    
        l_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
    
        l_new_id_harvest harvest.id_harvest%TYPE;
        l_harvest_group  harvest.id_harvest_group%TYPE;
    
        l_num_lab_tests           NUMBER;
        l_num_lab_tests_requested NUMBER;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        -- Workflow
        -- 1. Cancel Harvest
        -- 2. Create New Pending Harvest
        -- 3. Inactive lab tests requests linked to the harvest that was canceled
        -- 4. Create a new link between lab tests requests and the new harvest created
        -- 5. Update also ANALYSIS_REQ table if all lab tests are with status REQUESTED
        -- 6. Inactive current ANALYSIS_HARVEST linked to the canceled HARVEST
        -- 7. Link New Harvest Created to Lab Test Request
    
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            -- Check and validate input array's data
            g_error := 'Check I_HARVEST';
            IF i_harvest(i) IS NULL
            THEN
                g_error := 'I_HARVEST(' || i || ') parameter has no ID';
                RAISE g_other_exception;
            END IF;
        
            -- Cancel Harvest    
            --
            -- Process current HARVEST to HARVEST_HIST table        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
            IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_harvest          => i_harvest(i),
                                                                 i_analysis_harvest => NULL,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Cancel Harvest
            g_error := 'CALL TS_HARVEST.UPD';
            ts_harvest.upd(id_harvest_in            => i_harvest(i),
                           flg_status_in            => pk_lab_tests_constant.g_harvest_rejected,
                           id_specimen_condition_in => i_specimen_condition,
                           id_prof_cancels_in       => i_prof.id,
                           notes_cancel_in          => i_cancel_notes,
                           dt_cancel_tstz_in        => g_sysdate_tstz,
                           id_cancel_reason_in      => i_cancel_reason,
                           id_prof_cancels_nin      => FALSE,
                           notes_cancel_nin         => FALSE,
                           dt_cancel_tstz_nin       => FALSE,
                           id_cancel_reason_nin     => FALSE,
                           rows_out                 => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_UPDATE for HARVEST';
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => pk_lab_tests_constant.g_harvest_rejected,
                                    i_id_record  => i_harvest(i),
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Create new pending harvest
            --
            -- Get HARVEST number or recipients
            g_error := 'Get HARVEST number or recipients';
            SELECT h.num_recipient, h.id_body_part, h.id_room_harvest, h.id_room_receive_tube
              INTO l_harvest.num_recipient,
                   l_harvest.id_body_part,
                   l_harvest.id_room_harvest,
                   l_harvest.id_room_receive_tube
              FROM harvest h
             WHERE h.id_harvest = i_harvest(i);
        
            -- Get new ID_HARVEST_GROUP
            g_error := 'Get new ID_HARVEST_GROUP';
            SELECT seq_harvest_group.nextval
              INTO l_harvest_group
              FROM dual;
        
            SELECT t.flg_status
              INTO l_flg_status
              FROM (SELECT tl.flg_status
                      FROM ti_log tl
                     WHERE tl.id_record = i_harvest(i)
                       AND tl.flg_type = pk_lab_tests_constant.g_analysis_type_harv
                     ORDER BY tl.id_ti_log) t
             WHERE rownum = 1;
        
            l_rows_out := NULL;
            -- Create New Harvest
            g_error := 'CALL TS_HARVEST.INS';
            ts_harvest.ins(id_harvest_out           => l_new_id_harvest,
                           id_harvest_group_in      => l_harvest_group,
                           id_patient_in            => i_patient,
                           id_episode_in            => i_episode,
                           id_visit_in              => pk_visit.get_visit(i_episode, o_error),
                           flg_status_in            => l_flg_status,
                           dt_harvest_reg_tstz_in   => g_sysdate_tstz,
                           num_recipient_in         => l_harvest.num_recipient,
                           id_body_part_in          => l_harvest.id_body_part,
                           flg_laterality_in        => l_harvest.flg_laterality,
                           flg_collection_method_in => l_harvest.flg_collection_method,
                           id_room_harvest_in       => l_harvest.id_room_harvest,
                           id_institution_in        => l_harvest.id_institution,
                           id_room_receive_tube_in  => l_harvest.id_room_receive_tube,
                           flg_orig_harvest_in      => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                           rows_out                 => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_INSERT for HARVEST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => l_flg_status,
                                    i_id_record  => l_new_id_harvest,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Process lab tests requests linked to the harvest that was canceled
            -- Create a new link between lab tests requests and the new harvest created
            --
            FOR l_analysis IN c_analysis(i_harvest(i))
            LOOP
                l_rows_out := NULL;
                -- Set lab test requested to Request status
                g_error := 'CALL TS_ANALYSIS_REQ_DET.UPD';
                ts_analysis_req_det.upd(id_analysis_req_det_in => l_analysis.id_analysis_req_det,
                                        flg_status_in          => CASE
                                                                      WHEN l_analysis.flg_prn = pk_lab_tests_constant.g_yes THEN
                                                                       pk_lab_tests_constant.g_analysis_sos
                                                                      ELSE
                                                                       pk_lab_tests_constant.g_analysis_req
                                                                  END,
                                        id_prof_last_update_in => i_prof.id,
                                        dt_last_update_tstz_in => g_sysdate_tstz,
                                        rows_out               => l_rows_out);
            
                -- ANALYSIS_REQ_DET Data Governance Process
                g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ_DET';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_REQ_DET',
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_LAST_UPDATE',
                                                                              'DT_LAST_UPDATE_TSTZ'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            
                -- Insert on Status Log Table
                g_error := 'CALL T_TI_LOG.INS_LOG for ANALYSIS_REQ_DET';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_id_episode => i_episode,
                                   i_flg_status => CASE
                                                       WHEN l_analysis.flg_prn = pk_lab_tests_constant.g_yes THEN
                                                        pk_lab_tests_constant.g_analysis_sos
                                                       ELSE
                                                        pk_lab_tests_constant.g_analysis_req
                                                   END,
                                   i_id_record  => l_analysis.id_analysis_req_det,
                                   i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                   o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
                IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_patient          => NULL,
                                                                  i_episode          => i_episode,
                                                                  i_analysis_req     => l_analysis.id_analysis_req,
                                                                  i_analysis_req_det => l_analysis.id_analysis_req_det,
                                                                  o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Remove ALERT's when they are behind schedule
                l_sys_alert_event.id_sys_alert := 4;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := l_analysis.id_analysis_req_det;
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_sys_alert_event.id_sys_alert := 5;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := i_harvest(i);
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT - ALERTA 5';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Check if all lab tests are with status REQUESTED
                -- If so, update also ANALYSIS_REQ table
                --
                -- Get number of lab tests requested
                g_error := 'Total number of Lab Tests';
                BEGIN
                    SELECT COUNT(*) counter
                      INTO l_num_lab_tests
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = l_analysis.id_analysis_req;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_lab_tests := 0;
                END;
            
                -- Get number of lab tests requested with status as REQUESTED        
                g_error := 'Total number of Lab Tests Requested';
                BEGIN
                    SELECT COUNT(*) counter
                      INTO l_num_lab_tests_requested
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = l_analysis.id_analysis_req
                       AND ard.flg_status = pk_lab_tests_constant.g_analysis_req;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_lab_tests_requested := 0;
                END;
            
                IF (l_num_lab_tests = l_num_lab_tests_requested)
                THEN
                    -- Update ANALYSIS_REQ status to Requested
                    l_rows_out := NULL;
                    g_error    := 'CALL TS_ANALYSIS_REQ.UPD';
                    ts_analysis_req.upd(id_analysis_req_in => l_analysis.id_analysis_req,
                                        flg_status_in      => pk_lab_tests_constant.g_analysis_req,
                                        rows_out           => l_rows_out);
                
                    -- ANALYSIS_REQ Data Governance Process
                    g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ';
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ANALYSIS_REQ',
                                                  i_list_columns => table_varchar('FLG_STATUS'),
                                                  i_rowids       => l_rows_out,
                                                  o_error        => o_error);
                
                    -- Insert on Status Log Table            
                    g_error := 'CALL T_TI_LOG.INS_LOG for ANALYSIS_REQ';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_analysis_req,
                                            i_id_record  => l_analysis.id_analysis_req,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_req,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                -- Inactive current ANALYSIS_REQ_DET linked to the canceled HARVEST
                -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_harvest          => NULL,
                                                                     i_analysis_harvest => l_analysis.id_analysis_harvest,
                                                                     o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_rows_out := NULL;
                -- Set ANALYSIS_HARVEST status to Inactive
                g_error := 'Set ANALYSIS_HARVEST status to Inactive';
                ts_analysis_harvest.upd(id_analysis_harvest_in => l_analysis.id_analysis_harvest,
                                        flg_status_in          => pk_lab_tests_constant.g_inactive,
                                        rows_out               => l_rows_out);
            
                -- Harvest Data Governance Process
                g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_HARVEST',
                                              i_list_columns => table_varchar('FLG_STATUS'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            
                -- Link New Harvest Created to Lab Test Request
                -- Create new link
                g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                ts_analysis_harvest.ins(id_analysis_harvest_out => l_analysis_harvest,
                                        id_analysis_req_det_in  => l_analysis.id_analysis_req_det,
                                        id_harvest_in           => l_new_id_harvest,
                                        id_sample_recipient_in  => l_analysis.id_sample_recipient,
                                        num_recipient_in        => l_analysis.num_recipient,
                                        flg_status_in           => pk_lab_tests_constant.g_active,
                                        rows_out                => l_rows_out);
            
                -- Analysis Harvest Data Governance Process
                g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
            END LOOP;
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_CANCEL';
            pk_ia_event_lab.harvest_cancel(i_id_harvest     => i_harvest(i),
                                           i_id_institution => i_prof.institution,
                                           i_flg_old_status => l_flg_status);
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_PENDING';
            pk_ia_event_lab.harvest_pending(i_id_harvest     => l_new_id_harvest,
                                            i_id_institution => i_prof.institution,
                                            i_flg_old_status => NULL);
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
                                              'SET_HARVEST_REJECT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END set_harvest_reject;

    FUNCTION update_harvest
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN table_number,
        i_status           IN table_varchar,
        i_collected_by     IN table_number DEFAULT NULL,
        i_collection_time  IN table_varchar DEFAULT NULL,
        i_flg_orig_harvest IN harvest.flg_orig_harvest%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_harvest(l_harvest IN harvest.id_harvest%TYPE) IS
            SELECT h.flg_status, h.id_episode, h.flg_orig_harvest
              FROM harvest h
             WHERE h.id_harvest = l_harvest;
    
        CURSOR c_analysis_harvest(l_harvest IN harvest.id_harvest%TYPE) IS
            SELECT ah.id_analysis_req_det
              FROM analysis_harvest ah
             WHERE ah.id_harvest = l_harvest
               AND ah.flg_status = pk_lab_tests_constant.g_active;
    
        CURSOR c_room(l_harvest IN harvest.id_harvest%TYPE) IS
            SELECT ar.id_room
              FROM analysis_room ar, analysis_harvest ah, analysis_req_det ard
             WHERE ah.id_harvest = l_harvest
               AND ah.flg_status = pk_lab_tests_constant.g_active
               AND ah.id_analysis_req_det = ard.id_analysis_req_det
               AND ard.id_analysis = ar.id_analysis
               AND ard.id_sample_type = ar.id_sample_type
               AND ar.id_institution = i_prof.institution
               AND ar.flg_default = pk_lab_tests_constant.g_yes
               AND ar.flg_available = pk_lab_tests_constant.g_available
               AND ar.flg_type = pk_lab_tests_constant.g_arm_flg_type_room_tube;
    
        l_harvest c_harvest%ROWTYPE;
    
        l_flg_status_new harvest.flg_status%TYPE;
        l_room           analysis_room.id_room%TYPE;
        l_flg_status     analysis_req_det.flg_status%TYPE;
        l_episode        episode.id_episode%TYPE;
        l_flg_execute    analysis_instit_soft.flg_execute%TYPE;
    
        l_alert_exists    NUMBER;
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_processed VARCHAR2(1 CHAR);
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_harvest.count
        LOOP
        
            /*EMR-16045 - Flash could not solve, so solved this way */
            l_processed := pk_alert_constant.g_no;
        
            IF i > 1
            THEN
                FOR j IN 1 .. i - 1
                LOOP
                    IF i_harvest(i) = i_harvest(j)
                    THEN
                        l_processed := pk_alert_constant.g_yes;
                    END IF;
                END LOOP;
            
            END IF;
        
            IF l_processed = pk_alert_constant.g_no
            THEN
                g_error := 'OPEN C_HARVEST';
                OPEN c_harvest(i_harvest(i));
                FETCH c_harvest
                    INTO l_harvest;
                CLOSE c_harvest;
            
                IF i_status(i) = pk_lab_tests_constant.g_harvest_collected
                   AND l_harvest.flg_status != pk_lab_tests_constant.g_harvest_collected
                THEN
                    RETURN TRUE;
                ELSIF i_status(i) = pk_lab_tests_constant.g_harvest_repeated
                      AND l_harvest.flg_status != pk_lab_tests_constant.g_harvest_repeated
                THEN
                    RETURN TRUE;
                ELSIF i_status(i) IS NOT NULL
                      AND i_flg_orig_harvest = pk_lab_tests_constant.g_harvest_orig_harvest_i
                      AND l_harvest.flg_status != pk_lab_tests_constant.g_analysis_result
                      AND l_harvest.flg_status != pk_lab_tests_constant.g_analysis_read
                      AND l_harvest.flg_status != pk_lab_tests_constant.g_analysis_cancel
                THEN
                    l_flg_status_new := i_status(i);
                
                ELSIF i_status(i) IS NOT NULL
                      AND i_flg_orig_harvest = pk_lab_tests_constant.g_harvest_orig_harvest_i
                      AND (l_harvest.flg_status = pk_lab_tests_constant.g_analysis_result OR
                           l_harvest.flg_status = pk_lab_tests_constant.g_analysis_read OR
                           l_harvest.flg_status = pk_lab_tests_constant.g_analysis_cancel)
                THEN
                    l_flg_status_new := l_harvest.flg_status;
                ELSE
                    g_error          := 'GET STATUS';
                    l_flg_status_new := NULL;
                    --transition t to f
                    IF l_harvest.flg_status IN
                       (pk_lab_tests_constant.g_harvest_collected, pk_lab_tests_constant.g_harvest_repeated)
                    THEN
                        l_flg_status_new := pk_lab_tests_constant.g_harvest_transp;
                        --transition t to f
                    ELSIF l_harvest.flg_status = pk_lab_tests_constant.g_harvest_transp
                    THEN
                        l_flg_status_new := pk_lab_tests_constant.g_harvest_finished;
                        -- transition p to f
                    ELSIF l_harvest.flg_status = pk_lab_tests_constant.g_harvest_pending
                    THEN
                        l_flg_status_new := pk_lab_tests_constant.g_harvest_finished;
                    END IF;
                END IF;
            
                IF l_flg_status_new IS NOT NULL
                THEN
                    g_error := 'OPEN C_ROOM';
                    OPEN c_room(i_harvest(i));
                    FETCH c_room
                        INTO l_room;
                    g_found := c_room%NOTFOUND;
                    CLOSE c_room;
                
                    IF g_found
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    g_error := 'HARVEST';
                    ts_harvest.upd(id_harvest_in             => i_harvest(i),
                                   flg_status_in             => l_flg_status_new,
                                   dt_mov_begin_tstz_in      => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_transp THEN
                                                                     g_sysdate_tstz
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   id_prof_mov_tube_in       => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_transp THEN
                                                                     i_prof.id
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   dt_lab_reception_tstz_in  => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_finished THEN
                                                                     g_sysdate_tstz
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   id_prof_receive_tube_in   => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_finished THEN
                                                                     i_prof.id
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   id_room_receive_tube_in   => l_room,
                                   dt_harvest_tstz_in        => CASE
                                                                    WHEN i_collection_time IS NOT NULL
                                                                         AND i_collection_time.count > 0 THEN
                                                                     pk_date_utils.get_string_tstz(i_lang,
                                                                                                   i_prof,
                                                                                                   i_collection_time(i),
                                                                                                   NULL)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   id_prof_harvest_in        => CASE
                                                                    WHEN i_collected_by IS NOT NULL
                                                                         AND i_collected_by.count > 0 THEN
                                                                     i_collected_by(i)
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   dt_harvest_reg_tstz_in    => CASE
                                                                    WHEN l_harvest.flg_status = pk_lab_tests_constant.g_harvest_suspended THEN
                                                                     g_sysdate_tstz
                                                                    ELSE
                                                                     NULL
                                                                END,
                                   flg_orig_harvest_in       => CASE
                                                                    WHEN l_harvest.flg_orig_harvest IS NOT NULL THEN
                                                                     l_harvest.flg_orig_harvest
                                                                    ELSE
                                                                     nvl(l_harvest.flg_orig_harvest,
                                                                         pk_lab_tests_constant.g_harvest_orig_harvest_a)
                                                                END,
                                   dt_mov_begin_tstz_nin     => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_transp THEN
                                                                     FALSE
                                                                    ELSE
                                                                     TRUE
                                                                END,
                                   id_prof_mov_tube_nin      => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_transp THEN
                                                                     FALSE
                                                                    ELSE
                                                                     TRUE
                                                                END,
                                   dt_lab_reception_tstz_nin => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_finished THEN
                                                                     FALSE
                                                                    ELSE
                                                                     TRUE
                                                                END,
                                   id_prof_receive_tube_nin  => CASE l_flg_status_new
                                                                    WHEN pk_lab_tests_constant.g_harvest_finished THEN
                                                                     FALSE
                                                                    ELSE
                                                                     TRUE
                                                                END,
                                   id_room_receive_tube_nin  => FALSE,
                                   dt_harvest_reg_tstz_nin   => CASE
                                                                    WHEN l_harvest.flg_status = pk_lab_tests_constant.g_harvest_suspended THEN
                                                                     FALSE
                                                                    ELSE
                                                                     TRUE
                                                                END,
                                   rows_out                  => l_rows_out);
                
                    t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_table_name => 'HARVEST',
                                                  i_rowids     => l_rows_out,
                                                  o_error      => o_error);
                
                    -- inserir em log de estados
                    IF l_harvest.id_episode IS NOT NULL
                    THEN
                        IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                i_prof       => i_prof,
                                                i_id_episode => l_harvest.id_episode,
                                                i_flg_status => l_flg_status_new,
                                                i_id_record  => i_harvest(i),
                                                i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                                o_error      => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END IF;
            
                IF l_flg_status_new = pk_lab_tests_constant.g_harvest_collected
                THEN
                    l_sys_alert_event.id_sys_alert := 4;
                    l_sys_alert_event.id_episode   := l_harvest.id_episode;
                    l_sys_alert_event.id_record    := i_harvest(i);
                
                    g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT - ALERTA 4';
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                
                    BEGIN
                        SELECT 1
                          INTO l_alert_exists
                          FROM sys_alert_event sae
                         WHERE sae.id_sys_alert = 5
                           AND sae.id_episode = l_episode
                           AND sae.id_record = i_harvest(i)
                           AND sae.id_institution = i_prof.institution
                           AND sae.id_software = i_prof.software;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_alert_exists := 0;
                    END;
                
                    IF l_alert_exists = 0
                    THEN
                        l_sys_alert_event.id_sys_alert    := 5;
                        l_sys_alert_event.id_software     := i_prof.software;
                        l_sys_alert_event.id_institution  := i_prof.institution;
                        l_sys_alert_event.id_episode      := l_harvest.id_episode;
                        l_sys_alert_event.id_record       := i_harvest(i);
                        l_sys_alert_event.dt_record := CASE
                                                           WHEN i_collection_time IS NOT NULL
                                                                AND i_collection_time.count > 0 THEN
                                                            pk_date_utils.get_string_tstz(i_lang, i_prof, i_collection_time(i), NULL)
                                                           ELSE
                                                            NULL
                                                       END;
                        l_sys_alert_event.id_professional := i_prof.id;
                        l_sys_alert_event.id_room         := NULL;
                        l_sys_alert_event.replace1        := pk_sysconfig.get_config('ALERT_HARVEST_MOV_TIMEOUT',
                                                                                     i_prof.institution,
                                                                                     i_prof.software);
                    
                        g_error := 'CALL PK_ALERTS.INSERT_SYS_ALERT_EVENT - ALERTA 5';
                        IF NOT pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                                i_prof            => i_prof,
                                                                i_sys_alert_event => l_sys_alert_event,
                                                                i_flg_type_dest   => 'C',
                                                                o_error           => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                ELSE
                    l_sys_alert_event.id_sys_alert := 5;
                    l_sys_alert_event.id_episode   := l_harvest.id_episode;
                    l_sys_alert_event.id_record    := i_harvest(i);
                
                    g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT - ALERTA 5';
                    IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_sys_alert_event => l_sys_alert_event,
                                                            o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                g_error := 'CALL TO PK_VISIT.SET_FIRST_OBS';
                IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                              i_id_episode          => l_harvest.id_episode,
                                              i_pat                 => NULL,
                                              i_prof                => i_prof,
                                              i_prof_cat_type       => NULL,
                                              i_dt_last_interaction => g_sysdate_tstz,
                                              i_dt_first_obs        => g_sysdate_tstz,
                                              o_error               => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                FOR rec IN c_analysis_harvest(i_harvest(i))
                LOOP
                    SELECT ais.flg_execute, ar.id_episode, ard.flg_status
                      INTO l_flg_execute, l_episode, l_flg_status
                      FROM analysis_req_det ard, analysis_req ar, analysis_instit_soft ais
                     WHERE ard.id_analysis_req_det = rec.id_analysis_req_det
                       AND ard.id_analysis_req = ar.id_analysis_req
                       AND ard.id_analysis = ais.id_analysis
                       AND ard.id_sample_type = ais.id_sample_type
                       AND ais.flg_available = pk_lab_tests_constant.g_available
                       AND ais.id_institution = i_prof.institution
                       AND ais.id_software = i_prof.software;
                
                    IF l_flg_status NOT IN (pk_lab_tests_constant.g_analysis_result,
                                            pk_lab_tests_constant.g_analysis_read,
                                            pk_lab_tests_constant.g_analysis_cancel)
                    THEN
                        IF l_flg_status_new = pk_lab_tests_constant.g_harvest_finished
                           AND l_flg_execute = pk_lab_tests_constant.g_no
                        THEN
                            IF l_flg_status != pk_lab_tests_constant.g_analysis_exterior
                            THEN
                                g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_HISTORY';
                                IF NOT pk_lab_tests_core.set_lab_test_history(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_analysis_req     => NULL,
                                                                              i_analysis_req_det => table_number(rec.id_analysis_req_det),
                                                                              o_error            => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                        
                            l_rows_out := NULL;
                            g_error    := 'UPDATE ANALYSIS_REQ_DET';
                            ts_analysis_req_det.upd(id_analysis_req_det_in => rec.id_analysis_req_det,
                                                    flg_status_in          => pk_lab_tests_constant.g_analysis_exterior,
                                                    id_prof_last_update_in => i_prof.id,
                                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                                    rows_out               => l_rows_out);
                        
                            -- inserir em log de estados
                            IF rec.id_analysis_req_det IS NOT NULL
                            THEN
                                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => l_episode,
                                                        i_flg_status => pk_lab_tests_constant.g_analysis_exterior,
                                                        i_id_record  => rec.id_analysis_req_det,
                                                        i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                                        o_error      => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'ANALYSIS_REQ_DET',
                                                          i_rowids     => l_rows_out,
                                                          o_error      => o_error);
                        
                            g_error := 'CALL TO PK_IA_EVENT_LAB.ANALYSIS_REQUEST_EXTERNAL_NEW';
                            pk_ia_event_lab.analysis_request_external_new(i_id_analysis_req_det => rec.id_analysis_req_det,
                                                                          i_id_institution      => i_prof.institution,
                                                                          i_flg_old_status      => l_flg_status);
                        
                        ELSIF l_flg_status_new = pk_lab_tests_constant.g_harvest_finished
                        THEN
                            IF l_flg_status != pk_lab_tests_constant.g_analysis_toexec
                            THEN
                                g_error := 'CALL PK_LAB_TESTS_CORE.SET_LAB_TEST_HISTORY';
                                IF NOT pk_lab_tests_core.set_lab_test_history(i_lang             => i_lang,
                                                                              i_prof             => i_prof,
                                                                              i_analysis_req     => NULL,
                                                                              i_analysis_req_det => table_number(rec.id_analysis_req_det),
                                                                              o_error            => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                        
                            l_rows_out := NULL;
                            g_error    := 'UPDATE ANALYSIS_REQ_DET';
                            ts_analysis_req_det.upd(id_analysis_req_det_in => rec.id_analysis_req_det,
                                                    flg_status_in          => pk_lab_tests_constant.g_analysis_toexec,
                                                    id_prof_last_update_in => i_prof.id,
                                                    dt_last_update_tstz_in => g_sysdate_tstz,
                                                    rows_out               => l_rows_out);
                        
                            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                                          i_prof       => i_prof,
                                                          i_table_name => 'ANALYSIS_REQ_DET',
                                                          i_rowids     => l_rows_out,
                                                          o_error      => o_error);
                        
                            g_error := 'CALL TO PK_IA_EVENT_LAB.ANALYSIS_REQUEST_IN_PROGRESS';
                            pk_ia_event_lab.analysis_request_in_progress(i_id_analysis_req_det => rec.id_analysis_req_det,
                                                                         i_id_institution      => i_prof.institution,
                                                                         i_flg_old_status      => l_flg_status);
                        
                        END IF;
                    
                        g_error := 'PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
                        IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                          i_prof             => i_prof,
                                                                          i_patient          => NULL,
                                                                          i_episode          => l_harvest.id_episode,
                                                                          i_analysis_req     => NULL,
                                                                          i_analysis_req_det => rec.id_analysis_req_det,
                                                                          o_error            => o_error)
                        THEN
                            RAISE g_other_exception;
                        END IF;
                    END IF;
                END LOOP;
            
                IF l_flg_status_new = pk_lab_tests_constant.g_harvest_transp
                THEN
                    g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_TRANSPORT';
                    pk_ia_event_lab.harvest_transport(i_id_harvest     => i_harvest(i),
                                                      i_id_institution => i_prof.institution,
                                                      i_flg_old_status => l_harvest.flg_status);
                ELSIF l_flg_status_new = pk_lab_tests_constant.g_harvest_finished
                THEN
                    g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_END';
                    pk_ia_event_lab.harvest_end(i_id_harvest     => i_harvest(i),
                                                i_id_institution => i_prof.institution,
                                                i_flg_old_status => l_harvest.flg_status);
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
                                              'UPDATE_HARVEST',
                                              o_error);
            RETURN FALSE;
    END update_harvest;

    FUNCTION cancel_harvest
    (
        i_lang          IN language.id_language%TYPE, --1
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_episode       IN episode.id_episode%TYPE,
        i_harvest       IN table_number,
        i_cancel_reason IN harvest.id_cancel_reason%TYPE, --5
        i_cancel_notes  IN harvest.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_analysis(l_harvest IN harvest.id_harvest%TYPE) IS
            SELECT ah.id_analysis_harvest,
                   ah.id_sample_recipient,
                   ah.num_recipient,
                   ard.id_analysis_req,
                   ard.id_analysis_req_det,
                   ard.flg_prn
              FROM analysis_harvest ah, analysis_req_det ard
             WHERE ah.id_harvest = l_harvest
               AND ah.flg_status = pk_lab_tests_constant.g_active
               AND ah.id_analysis_req_det = ard.id_analysis_req_det;
    
        l_harvest harvest%ROWTYPE;
    
        l_flg_status harvest.flg_status%TYPE;
    
        l_analysis_harvest analysis_harvest.id_analysis_harvest%TYPE;
    
        l_new_id_harvest harvest.id_harvest%TYPE;
        l_harvest_group  harvest.id_harvest_group%TYPE;
    
        l_num_lab_tests           NUMBER;
        l_num_lab_tests_requested NUMBER;
    
        l_sys_alert_event sys_alert_event%ROWTYPE;
    
        l_rows_out table_varchar := table_varchar();
    
    BEGIN
    
        -- Workflow
        -- 1. Cancel Harvest
        -- 2. Create New Pending Harvest
        -- 3. Inactive lab tests requests linked to the harvest that was canceled
        -- 4. Create a new link between lab tests requests and the new harvest created
        -- 5. Update also ANALYSIS_REQ table if all lab tests are with status REQUESTED
        -- 6. Inactive current ANALYSIS_HARVEST linked to the canceled HARVEST
        -- 7. Link New Harvest Created to Lab Test Request
    
        -- Initialize Variables
        g_error        := 'Initialize Variables';
        g_sysdate_tstz := current_timestamp;
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            -- Check and validate input array's data
            g_error := 'Check I_HARVEST';
            IF i_harvest(i) IS NULL
            THEN
                g_error := 'I_HARVEST(' || i || ') parameter has no ID';
                RAISE g_other_exception;
            END IF;
        
            -- Cancel Harvest    
            --
            -- Process current HARVEST to HARVEST_HIST table        
            g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
            IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                 i_prof             => i_prof,
                                                                 i_harvest          => i_harvest(i),
                                                                 i_analysis_harvest => NULL,
                                                                 o_error            => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Cancel Harvest
            g_error := 'CALL TS_HARVEST.UPD';
            ts_harvest.upd(id_harvest_in        => i_harvest(i),
                           flg_status_in        => pk_lab_tests_constant.g_harvest_cancel,
                           id_prof_cancels_in   => i_prof.id,
                           notes_cancel_in      => i_cancel_notes,
                           dt_cancel_tstz_in    => g_sysdate_tstz,
                           id_cancel_reason_in  => i_cancel_reason,
                           id_prof_cancels_nin  => FALSE,
                           notes_cancel_nin     => FALSE,
                           dt_cancel_tstz_nin   => FALSE,
                           id_cancel_reason_nin => FALSE,
                           rows_out             => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_UPDATE for HARVEST';
            t_data_gov_mnt.process_update(i_lang         => i_lang,
                                          i_prof         => i_prof,
                                          i_table_name   => 'HARVEST',
                                          i_list_columns => table_varchar('FLG_STATUS',
                                                                          'ID_PROF_CANCELS',
                                                                          'NOTES_CANCEL',
                                                                          'DT_CANCEL_TSTZ',
                                                                          'ID_CANCEL_REASON'),
                                          i_rowids       => l_rows_out,
                                          o_error        => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => pk_lab_tests_constant.g_harvest_cancel,
                                    i_id_record  => i_harvest(i),
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            g_error := 'CALL PK_VISIT.SET_FIRST_OBS';
            IF NOT pk_visit.set_first_obs(i_lang                => i_lang,
                                          i_id_episode          => i_episode,
                                          i_pat                 => NULL,
                                          i_prof                => i_prof,
                                          i_prof_cat_type       => pk_prof_utils.get_category(i_lang, i_prof),
                                          i_dt_last_interaction => g_sysdate_tstz,
                                          i_dt_first_obs        => g_sysdate_tstz,
                                          o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Create new pending harvest
            --
            -- Get HARVEST number or recipients
            g_error := 'Get HARVEST number or recipients';
            SELECT h.num_recipient, h.id_body_part, h.id_room_harvest, h.id_room_receive_tube, h.barcode
              INTO l_harvest.num_recipient,
                   l_harvest.id_body_part,
                   l_harvest.id_room_harvest,
                   l_harvest.id_room_receive_tube,
                   l_harvest.barcode
              FROM harvest h
             WHERE h.id_harvest = i_harvest(i);
        
            -- Get new ID_HARVEST_GROUP
            g_error := 'Get new ID_HARVEST_GROUP';
            SELECT seq_harvest_group.nextval
              INTO l_harvest_group
              FROM dual;
        
            SELECT t.flg_status
              INTO l_flg_status
              FROM (SELECT tl.flg_status
                      FROM ti_log tl
                     WHERE tl.id_record = i_harvest(i)
                       AND tl.flg_type = pk_lab_tests_constant.g_analysis_type_harv
                     ORDER BY tl.id_ti_log) t
             WHERE rownum = 1;
        
            l_rows_out := NULL;
            -- Create New Harvest
            g_error := 'CALL TS_HARVEST.INS';
            ts_harvest.ins(id_harvest_out          => l_new_id_harvest,
                           id_harvest_group_in     => l_harvest_group,
                           id_patient_in           => i_patient,
                           id_episode_in           => i_episode,
                           id_visit_in             => pk_visit.get_visit(i_episode, o_error),
                           flg_status_in           => l_flg_status,
                           dt_harvest_reg_tstz_in  => g_sysdate_tstz,
                           num_recipient_in        => l_harvest.num_recipient,
                           barcode_in              => l_harvest.barcode,
                           id_body_part_in         => l_harvest.id_body_part,
                           id_room_harvest_in      => l_harvest.id_room_harvest,
                           id_institution_in       => l_harvest.id_institution,
                           id_room_receive_tube_in => l_harvest.id_room_receive_tube,
                           flg_orig_harvest_in     => pk_lab_tests_constant.g_harvest_orig_harvest_a,
                           rows_out                => l_rows_out);
        
            -- Harvest Data Governance Process
            g_error := 'CALL PROCESS_INSERT for HARVEST';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'HARVEST',
                                          i_rowids     => l_rows_out,
                                          o_error      => o_error);
        
            -- Insert on Status Log Table
            g_error := 'CALL T_TI_LOG.INS_LOG';
            IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                    i_prof       => i_prof,
                                    i_id_episode => i_episode,
                                    i_flg_status => l_flg_status,
                                    i_id_record  => l_new_id_harvest,
                                    i_flg_type   => pk_lab_tests_constant.g_analysis_type_harv,
                                    o_error      => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            -- Process lab tests requests linked to the harvest that was canceled
            -- Create a new link between lab tests requests and the new harvest created
            --
            FOR l_analysis IN c_analysis(i_harvest(i))
            LOOP
                l_rows_out := NULL;
                -- Set lab test requested to Request status
                g_error := 'CALL TS_ANALYSIS_REQ_DET.UPD';
                ts_analysis_req_det.upd(id_analysis_req_det_in => l_analysis.id_analysis_req_det,
                                        flg_status_in          => CASE
                                                                      WHEN l_analysis.flg_prn = pk_lab_tests_constant.g_yes THEN
                                                                       pk_lab_tests_constant.g_analysis_sos
                                                                      ELSE
                                                                       pk_lab_tests_constant.g_analysis_req
                                                                  END,
                                        id_prof_last_update_in => i_prof.id,
                                        dt_last_update_tstz_in => g_sysdate_tstz,
                                        rows_out               => l_rows_out);
            
                -- ANALYSIS_REQ_DET Data Governance Process
                g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ_DET';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_REQ_DET',
                                              i_list_columns => table_varchar('FLG_STATUS',
                                                                              'ID_PROF_LAST_UPDATE',
                                                                              'DT_LAST_UPDATE_TSTZ'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            
                -- Insert on Status Log Table
                g_error := 'CALL T_TI_LOG.INS_LOG for ANALYSIS_REQ_DET';
                IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                   i_prof       => i_prof,
                                   i_id_episode => i_episode,
                                   i_flg_status => CASE
                                                       WHEN l_analysis.flg_prn = pk_lab_tests_constant.g_yes THEN
                                                        pk_lab_tests_constant.g_analysis_sos
                                                       ELSE
                                                        pk_lab_tests_constant.g_analysis_req
                                                   END,
                                   i_id_record  => l_analysis.id_analysis_req_det,
                                   i_flg_type   => pk_lab_tests_constant.g_analysis_type_det,
                                   o_error      => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                g_error := 'CALL PK_LAB_TESTS_API_DB.SET_LAB_TEST_GRID_TASK';
                IF NOT pk_lab_tests_api_db.set_lab_test_grid_task(i_lang             => i_lang,
                                                                  i_prof             => i_prof,
                                                                  i_patient          => NULL,
                                                                  i_episode          => i_episode,
                                                                  i_analysis_req     => l_analysis.id_analysis_req,
                                                                  i_analysis_req_det => l_analysis.id_analysis_req_det,
                                                                  o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Remove ALERT's when they are behind schedule
                l_sys_alert_event.id_sys_alert := 4;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := l_analysis.id_analysis_req_det;
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_sys_alert_event.id_sys_alert := 5;
                l_sys_alert_event.id_episode   := i_episode;
                l_sys_alert_event.id_record    := i_harvest(i);
            
                g_error := 'CALL PK_ALERTS.DELETE_SYS_ALERT_EVENT - ALERTA 5';
                IF NOT pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_sys_alert_event => l_sys_alert_event,
                                                        o_error           => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                -- Check if all lab tests are with status REQUESTED
                -- If so, update also ANALYSIS_REQ table
                --
                -- Get number of lab tests requested
                g_error := 'Total number of Lab Tests';
                BEGIN
                    SELECT COUNT(*) counter
                      INTO l_num_lab_tests
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = l_analysis.id_analysis_req;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_lab_tests := 0;
                END;
            
                -- Get number of lab tests requested with status as REQUESTED        
                g_error := 'Total number of Lab Tests Requested';
                BEGIN
                    SELECT COUNT(*) counter
                      INTO l_num_lab_tests_requested
                      FROM analysis_req_det ard
                     WHERE ard.id_analysis_req = l_analysis.id_analysis_req
                       AND ard.flg_status = pk_lab_tests_constant.g_analysis_req;
                EXCEPTION
                    WHEN no_data_found THEN
                        l_num_lab_tests_requested := 0;
                END;
            
                IF (l_num_lab_tests = l_num_lab_tests_requested)
                THEN
                    -- Update ANALYSIS_REQ status to Requested
                    l_rows_out := NULL;
                    g_error    := 'CALL TS_ANALYSIS_REQ.UPD';
                    ts_analysis_req.upd(id_analysis_req_in => l_analysis.id_analysis_req,
                                        flg_status_in      => pk_lab_tests_constant.g_analysis_req,
                                        rows_out           => l_rows_out);
                
                    -- ANALYSIS_REQ Data Governance Process
                    g_error := 'CALL PROCESS_UPDATE for ANALYSIS_REQ';
                    t_data_gov_mnt.process_update(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_table_name   => 'ANALYSIS_REQ',
                                                  i_list_columns => table_varchar('FLG_STATUS'),
                                                  i_rowids       => l_rows_out,
                                                  o_error        => o_error);
                
                    -- Insert on Status Log Table            
                    g_error := 'CALL T_TI_LOG.INS_LOG for ANALYSIS_REQ';
                    IF NOT t_ti_log.ins_log(i_lang       => i_lang,
                                            i_prof       => i_prof,
                                            i_id_episode => i_episode,
                                            i_flg_status => pk_lab_tests_constant.g_analysis_req,
                                            i_id_record  => l_analysis.id_analysis_req,
                                            i_flg_type   => pk_lab_tests_constant.g_analysis_type_req,
                                            o_error      => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                -- Inactive current ANALYSIS_REQ_DET linked to the canceled HARVEST
                -- Process current ANALYSIS_HARVEST to ANALYSIS_HARVEST_HIST table
                g_error := 'CALL PK_LAB_TESTS_HARVEST_CORE.SET_HARVEST_HISTORY';
                IF NOT pk_lab_tests_harvest_core.set_harvest_history(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_harvest          => NULL,
                                                                     i_analysis_harvest => l_analysis.id_analysis_harvest,
                                                                     o_error            => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                l_rows_out := NULL;
                -- Set ANALYSIS_HARVEST status to Inactive
                g_error := 'Set ANALYSIS_HARVEST status to Inactive';
                ts_analysis_harvest.upd(id_analysis_harvest_in => l_analysis.id_analysis_harvest,
                                        flg_status_in          => pk_lab_tests_constant.g_inactive,
                                        rows_out               => l_rows_out);
            
                -- Harvest Data Governance Process
                g_error := 'CALL PROCESS_UPDATE FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_update(i_lang         => i_lang,
                                              i_prof         => i_prof,
                                              i_table_name   => 'ANALYSIS_HARVEST',
                                              i_list_columns => table_varchar('FLG_STATUS'),
                                              i_rowids       => l_rows_out,
                                              o_error        => o_error);
            
                -- Link New Harvest Created to Lab Test Request
                -- Create new link
                g_error := 'CALL TS_ANALYSIS_HARVEST.INS';
                ts_analysis_harvest.ins(id_analysis_harvest_out => l_analysis_harvest,
                                        id_analysis_req_det_in  => l_analysis.id_analysis_req_det,
                                        id_harvest_in           => l_new_id_harvest,
                                        id_sample_recipient_in  => l_analysis.id_sample_recipient,
                                        num_recipient_in        => l_analysis.num_recipient,
                                        flg_status_in           => pk_lab_tests_constant.g_active,
                                        rows_out                => l_rows_out);
            
                -- Analysis Harvest Data Governance Process
                g_error := 'CALL PROCESS_INSERT FOR ANALYSIS_HARVEST';
                t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_table_name => 'ANALYSIS_HARVEST',
                                              i_rowids     => l_rows_out,
                                              o_error      => o_error);
            
            END LOOP;
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_CANCEL';
            pk_ia_event_lab.harvest_cancel(i_id_harvest     => i_harvest(i),
                                           i_id_institution => i_prof.institution,
                                           i_flg_old_status => l_flg_status);
        
            g_error := 'CALL TO PK_IA_EVENT_LAB.HARVEST_PENDING';
            pk_ia_event_lab.harvest_pending(i_id_harvest     => l_new_id_harvest,
                                            i_id_institution => i_prof.institution,
                                            i_flg_old_status => NULL);
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
                                              'CANCEL_HARVEST',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END cancel_harvest;

    FUNCTION get_harvest_movement_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_visit c_visit%ROWTYPE;
    
        l_prof_cat_type category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
    
        l_nurse_permission     sys_config.value%TYPE := pk_sysconfig.get_config('FLG_NURSE_FINISH_TRANSP', i_prof);
        l_ancillary_permission sys_config.value%TYPE := pk_sysconfig.get_config('FLG_AUX_FINISH_TRANSP', i_prof);
    
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
    BEGIN
        g_error := 'OPEN c_inst';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT h.id_harvest,
                   h.flg_status,
                   substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               pk_lab_tests_constant.g_analysis_alias,
                                                                               'ANALYSIS.CODE_ANALYSIS.' ||
                                                                               h.id_analysis,
                                                                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                               h.id_sample_type,
                                                                               NULL) || '; '),
                          1,
                          length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      h.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      h.id_sample_type,
                                                                                      NULL) || '; ')) - 2) desc_analysis,
                   h.desc_recipient,
                   h.desc_room_origin,
                   h.desc_room_destination,
                   h.status_string,
                   MAX(h.avail_button_ok) avail_button_ok,
                   MAX(h.rank) rank
              FROM (SELECT DISTINCT h.id_harvest,
                                    h.flg_status,
                                    lte.id_analysis,
                                    lte.id_sample_type,
                                    pk_translation.get_translation(i_lang,
                                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                   ah.id_sample_recipient) desc_recipient,
                                    decode(h.id_room_harvest,
                                           NULL,
                                           pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst, i_lang),
                                           pk_translation.get_translation(i_lang,
                                                                          'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                          r1.id_department) || ' / ' ||
                                           nvl(r1.desc_room, pk_translation.get_translation(i_lang, r1.code_room))) desc_room_origin,
                                    pk_translation.get_translation(i_lang,
                                                                   'DEPARTMENT.CODE_DEPARTMENT.' || r2.id_department) ||
                                    ' / ' || nvl(r2.desc_room, pk_translation.get_translation(i_lang, r2.code_room)) desc_room_destination,
                                    pk_utils.get_status_string(i_lang,
                                                               i_prof,
                                                               pk_ea_logic_analysis.get_harvest_status_str(i_prof,
                                                                                                           lte.flg_time_harvest,
                                                                                                           h.flg_status,
                                                                                                           lte.dt_req,
                                                                                                           lte.dt_pend_req,
                                                                                                           decode(h.flg_status,
                                                                                                                  pk_lab_tests_constant.g_harvest_pending,
                                                                                                                  nvl(h.dt_begin_harvest,
                                                                                                                      lte.dt_target),
                                                                                                                  nvl(h.dt_harvest_reg_tstz,
                                                                                                                      h.dt_harvest_tstz)),
                                                                                                           'T'),
                                                               pk_ea_logic_analysis.get_harvest_status_msg(i_prof,
                                                                                                           lte.flg_time_harvest,
                                                                                                           h.flg_status,
                                                                                                           lte.dt_req,
                                                                                                           lte.dt_pend_req,
                                                                                                           decode(h.flg_status,
                                                                                                                  pk_lab_tests_constant.g_harvest_pending,
                                                                                                                  nvl(h.dt_begin_harvest,
                                                                                                                      lte.dt_target),
                                                                                                                  nvl(h.dt_harvest_reg_tstz,
                                                                                                                      h.dt_harvest_tstz)),
                                                                                                           'T'),
                                                               pk_ea_logic_analysis.get_harvest_status_icon(i_prof,
                                                                                                            lte.flg_time_harvest,
                                                                                                            h.flg_status,
                                                                                                            lte.dt_req,
                                                                                                            lte.dt_pend_req,
                                                                                                            decode(h.flg_status,
                                                                                                                   pk_lab_tests_constant.g_harvest_pending,
                                                                                                                   nvl(h.dt_begin_harvest,
                                                                                                                       lte.dt_target),
                                                                                                                   nvl(h.dt_harvest_reg_tstz,
                                                                                                                       h.dt_harvest_tstz)),
                                                                                                            'T'),
                                                               pk_ea_logic_analysis.get_harvest_status_flg(i_prof,
                                                                                                           lte.flg_time_harvest,
                                                                                                           h.flg_status,
                                                                                                           lte.dt_req,
                                                                                                           lte.dt_pend_req,
                                                                                                           decode(h.flg_status,
                                                                                                                  pk_lab_tests_constant.g_harvest_pending,
                                                                                                                  nvl(h.dt_begin_harvest,
                                                                                                                      lte.dt_target),
                                                                                                                  nvl(h.dt_harvest_reg_tstz,
                                                                                                                      h.dt_harvest_tstz)),
                                                                                                           'T')) status_string,
                                    decode(l_view_only_profile,
                                           pk_lab_tests_constant.g_yes,
                                           pk_lab_tests_constant.g_no,
                                           decode(lte.flg_status_det,
                                                  pk_lab_tests_constant.g_analysis_result,
                                                  pk_lab_tests_constant.g_no,
                                                  pk_lab_tests_constant.g_analysis_read,
                                                  pk_lab_tests_constant.g_no,
                                                  decode(h.flg_status,
                                                         pk_lab_tests_constant.g_harvest_cancel,
                                                         pk_lab_tests_constant.g_no,
                                                         pk_lab_tests_constant.g_harvest_finished,
                                                         pk_lab_tests_constant.g_no,
                                                         pk_lab_tests_constant.g_harvest_pending,
                                                         pk_lab_tests_constant.g_no,
                                                         pk_lab_tests_constant.g_harvest_transp,
                                                         decode(l_prof_cat_type,
                                                                pk_alert_constant.g_cat_type_doc,
                                                                pk_lab_tests_constant.g_yes,
                                                                pk_alert_constant.g_cat_type_nurse,
                                                                l_nurse_permission,
                                                                pk_alert_constant.g_cat_type_technician,
                                                                pk_lab_tests_constant.g_yes,
                                                                l_ancillary_permission),
                                                         pk_lab_tests_constant.g_yes))) avail_button_ok,
                                    decode(h.flg_status,
                                           pk_lab_tests_constant.g_harvest_collected,
                                           row_number()
                                           over(ORDER BY
                                                pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                coalesce(h.dt_harvest_tstz,
                                                         h.dt_begin_harvest,
                                                         lte.dt_pend_req,
                                                         lte.dt_target,
                                                         lte.dt_req)),
                                           pk_lab_tests_constant.g_harvest_transp,
                                           row_number()
                                           over(ORDER BY
                                                pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                coalesce(h.dt_harvest_tstz,
                                                         h.dt_begin_harvest,
                                                         lte.dt_pend_req,
                                                         lte.dt_target,
                                                         lte.dt_req)),
                                           row_number()
                                           over(ORDER BY
                                                pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                coalesce(h.dt_harvest_tstz,
                                                         h.dt_begin_harvest,
                                                         lte.dt_pend_req,
                                                         lte.dt_target,
                                                         lte.dt_req)) + 1000) rank
                      FROM lab_tests_ea lte, harvest h, analysis_harvest ah, room r1, room r2
                     WHERE lte.id_visit = l_visit.id_visit
                       AND (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e OR
                           (lte.flg_time_harvest IN
                           (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                           pk_date_utils.trunc_insttimezone(i_prof, lte.dt_target, NULL) =
                           pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)) OR
                           (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND lte.id_episode IS NOT NULL))
                       AND lte.flg_status_det NOT IN
                           (pk_lab_tests_constant.g_analysis_draft, pk_lab_tests_constant.g_analysis_cancel)
                       AND (lte.flg_orig_analysis IS NULL OR lte.flg_orig_analysis NOT IN ('M', 'O', 'S'))
                       AND lte.flg_col_inst = pk_lab_tests_constant.g_yes
                       AND (lte.flg_referral IS NULL OR lte.flg_referral = pk_lab_tests_constant.g_flg_referral_a OR
                           lte.flg_referral = pk_lab_tests_constant.g_flg_referral_r)
                       AND EXISTS
                     (SELECT 1
                              FROM analysis_instit_soft ais
                             WHERE ais.flg_mov_recipient = pk_lab_tests_constant.g_yes
                               AND ais.id_analysis = lte.id_analysis
                               AND ais.id_sample_type = lte.id_sample_type
                               AND ais.flg_type = pk_lab_tests_constant.g_analysis_can_req
                               AND ais.id_software = i_prof.software
                               AND ais.id_institution = i_prof.institution
                               AND ais.flg_available = pk_lab_tests_constant.g_available)
                       AND lte.id_analysis_req_det = ah.id_analysis_req_det
                       AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                       AND ah.id_harvest = h.id_harvest
                       AND h.flg_status != pk_lab_tests_constant.g_harvest_cancel
                       AND h.id_room_harvest = r1.id_room(+)
                       AND h.id_room_receive_tube = r2.id_room
                       AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                              FROM dual) = pk_alert_constant.g_yes) h
             GROUP BY h.id_harvest,
                      h.flg_status,
                      h.desc_recipient,
                      h.desc_room_origin,
                      h.desc_room_destination,
                      h.status_string
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_MOVEMENT_LISTVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_movement_listview;

    FUNCTION get_harvest_preview
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_analysis_req_det IN table_number,
        o_list             OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_msg_notes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M097');
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT h.id_harvest id_harvest,
                   lte.id_analysis_req_det id_analysis_req_det,
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                            NULL) desc_analysis,
                   pk_date_utils.date_char_tsz(i_lang,
                                               coalesce(h.dt_harvest_tstz,
                                                        h.dt_begin_harvest,
                                                        lte.dt_pend_req,
                                                        lte.dt_target,
                                                        lte.dt_req),
                                               i_prof.institution,
                                               i_prof.software) dt_reg,
                   pk_utils.get_status_string(i_lang,
                                              i_prof,
                                              pk_ea_logic_analysis.get_harvest_status_str(i_prof,
                                                                                          lte.flg_time_harvest,
                                                                                          h.flg_status,
                                                                                          lte.dt_req,
                                                                                          lte.dt_pend_req,
                                                                                          nvl(h.dt_begin_harvest,
                                                                                              lte.dt_target),
                                                                                          'H'),
                                              pk_ea_logic_analysis.get_harvest_status_msg(i_prof,
                                                                                          lte.flg_time_harvest,
                                                                                          h.flg_status,
                                                                                          lte.dt_req,
                                                                                          lte.dt_pend_req,
                                                                                          nvl(h.dt_begin_harvest,
                                                                                              lte.dt_target),
                                                                                          'H'),
                                              pk_ea_logic_analysis.get_harvest_status_icon(i_prof,
                                                                                           lte.flg_time_harvest,
                                                                                           h.flg_status,
                                                                                           lte.dt_req,
                                                                                           lte.dt_pend_req,
                                                                                           nvl(h.dt_begin_harvest,
                                                                                               lte.dt_target),
                                                                                           'H'),
                                              pk_ea_logic_analysis.get_harvest_status_flg(i_prof,
                                                                                          lte.flg_time_harvest,
                                                                                          h.flg_status,
                                                                                          lte.dt_req,
                                                                                          lte.dt_pend_req,
                                                                                          nvl(h.dt_begin_harvest,
                                                                                              lte.dt_target),
                                                                                          'H')) status_string,
                   decode(h.notes, '', '', l_msg_notes) msg_notes,
                   h.notes notes,
                   decode(lte.flg_status_det,
                          pk_lab_tests_constant.g_analysis_req,
                          decode(h.dt_begin_harvest,
                                 NULL,
                                 row_number()
                                 over(ORDER BY pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                      coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req) DESC),
                                 row_number()
                                 over(ORDER BY pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                      h.dt_begin_harvest)),
                          row_number()
                          over(ORDER BY pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                               coalesce(h.dt_harvest_tstz, h.dt_begin_harvest, lte.dt_pend_req, lte.dt_target, lte.dt_req))) rank
              FROM lab_tests_ea lte, analysis_harvest ah, harvest h
             WHERE lte.id_analysis_req_det IN (SELECT /*+opt_estimate (table t rows=1)*/
                                                *
                                                 FROM TABLE(i_analysis_req_det) t)
               AND (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e OR
                   (lte.flg_time_harvest IN (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                   pk_date_utils.trunc_insttimezone(i_prof, lte.dt_target, NULL) =
                   pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)) OR
                   (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND lte.id_episode IS NOT NULL))
               AND lte.flg_col_inst = pk_lab_tests_constant.g_yes
               AND lte.flg_status_det != pk_lab_tests_constant.g_analysis_wtg_tde
               AND (lte.flg_referral IS NULL OR lte.flg_referral = pk_lab_tests_constant.g_flg_referral_a OR
                   lte.flg_referral = pk_lab_tests_constant.g_flg_referral_r)
               AND lte.id_analysis_req_det = ah.id_analysis_req_det
               AND ((ah.flg_status = pk_lab_tests_constant.g_active) OR
                   (ah.flg_status = pk_lab_tests_constant.g_inactive AND
                   h.flg_status IN (pk_lab_tests_constant.g_harvest_cancel, pk_lab_tests_constant.g_harvest_rejected)))
               AND ah.id_harvest = h.id_harvest
               AND h.flg_status NOT IN
                   (pk_lab_tests_constant.g_harvest_suspended, pk_lab_tests_constant.g_harvest_inactive)
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_PREVIEW',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_preview;

    FUNCTION get_harvest_detail
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T045',
                                                        'LAB_TESTS_T047',
                                                        'LAB_TESTS_T174',
                                                        'LAB_TESTS_T192',
                                                        'LAB_TESTS_T194',
                                                        'LAB_TESTS_T030',
                                                        'LAB_TESTS_T028',
                                                        'LAB_TESTS_T056',
                                                        'LAB_TESTS_T057',
                                                        'LAB_TESTS_T058',
                                                        'LAB_TESTS_T205',
                                                        'LAB_TESTS_T187',
                                                        'LAB_TESTS_T059',
                                                        'LAB_TESTS_T241',
                                                        'LAB_TESTS_T238',
                                                        'LAB_TESTS_T060',
                                                        'LAB_TESTS_T061',
                                                        'LAB_TESTS_T195',
                                                        'LAB_TESTS_T062',
                                                        'LAB_TESTS_T198',
                                                        'LAB_TESTS_T228');
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M107');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT h.id_harvest,
                   l_msg_reg || ' ' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(h.id_prof_harvest, h.id_prof_cancels)) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           nvl(h.id_prof_harvest, h.id_prof_cancels),
                                                           nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                                           h.id_episode),
                          NULL,
                          '; ',
                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   nvl(h.id_prof_harvest, h.id_prof_cancels),
                                                                   nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                                                   h.id_episode) || '); ') ||
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                               i_prof.institution,
                                               i_prof.software) registry,
                   aa_code_messages('LAB_TESTS_T045') ||
                   substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               pk_lab_tests_constant.g_analysis_alias,
                                                                               'ANALYSIS.CODE_ANALYSIS.' ||
                                                                               ard.id_analysis,
                                                                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                               ard.id_sample_type,
                                                                               NULL) || '; '),
                          1,
                          length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      ard.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      ard.id_sample_type,
                                                                                      NULL) || '; ')) - 2) desc_analysis,
                   aa_code_messages('LAB_TESTS_T047') ||
                   pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang) desc_status,
                   decode(h.id_body_part,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T174') ||
                          pk_translation.get_translation(i_lang, 'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || h.id_body_part) ||
                          decode(h.flg_laterality,
                                 NULL,
                                 NULL,
                                 ' - ' || pk_sysdomain.get_domain('HARVEST.FLG_LATERALITY', h.flg_laterality, i_lang))) desc_body_location,
                   decode(h.flg_collection_method,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T192') ||
                          pk_sysdomain.get_domain(i_lang,
                                                  i_prof,
                                                  'HARVEST.FLG_COLLECTION_METHOD',
                                                  h.flg_collection_method,
                                                  NULL)) collection_method,
                   decode(h.id_specimen_condition,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T194') ||
                          pk_translation.get_translation(i_lang,
                                                         'ANALYSIS_SPECIMEN_CONDITION.CODE_SPECIMEN_CONDITION.' ||
                                                         h.id_specimen_condition)) specimen_condition,
                   decode(h.id_room_harvest,
                          NULL,
                          decode(h.flg_col_inst,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T030') ||
                                 pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst, i_lang)),
                          aa_code_messages('LAB_TESTS_T030') ||
                          nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_harvest),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))) collection_location,
                   aa_code_messages('LAB_TESTS_T028') ||
                   decode(nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_receive_tube),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube)),
                          NULL,
                          pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || h.id_institution),
                          nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_receive_tube),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube))) perform_location,
                   decode(ah.id_sample_recipient,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T056') ||
                          pk_translation.get_translation(i_lang,
                                                         'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                         ah.id_sample_recipient)) desc_tubes,
                   decode(h.num_recipient, NULL, NULL, aa_code_messages('LAB_TESTS_T057') || h.num_recipient) num_tubes,
                   decode(h.dt_harvest_tstz,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T058') ||
                          pk_date_utils.date_char_tsz(i_lang, h.dt_harvest_tstz, i_prof.institution, i_prof.software)) dt_harvest,
                   decode(h.amount,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T205') || h.amount || ' ' ||
                          pk_translation.get_translation(i_lang,
                                                         'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                         pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                     i_prof,
                                                                                                     ah.id_sample_recipient))) collection_amount,
                   decode(h.flg_mov_tube,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T187') ||
                          pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', h.flg_mov_tube, NULL)) harvest_transportation,
                   decode(h.notes, NULL, NULL, aa_code_messages('LAB_TESTS_T059') || h.notes) notes,
                   decode(h.harvest_instructions,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T241') || h.harvest_instructions) harvest_instructions,
                   decode(h.id_revised_by,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T238') ||
                          pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by)) revised_by,
                   decode(h.id_rep_coll_reason,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T060') ||
                          pk_translation.get_translation(i_lang,
                                                         'REPEAT_COLLECTION_REASON.CODE_REP_COLL_REASON.' ||
                                                         h.id_rep_coll_reason)) repeat_harvest_notes,
                   decode(h.id_cancel_reason,
                          NULL,
                          NULL,
                          decode(h.flg_status,
                                 pk_lab_tests_constant.g_harvest_rejected,
                                 aa_code_messages('LAB_TESTS_T195'),
                                 aa_code_messages('LAB_TESTS_T062')) ||
                          pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, h.id_cancel_reason)) cancel_reason,
                   decode(h.notes_cancel,
                          NULL,
                          NULL,
                          decode(h.flg_status,
                                 pk_lab_tests_constant.g_harvest_rejected,
                                 aa_code_messages('LAB_TESTS_T198'),
                                 aa_code_messages('LAB_TESTS_T061')) || h.notes_cancel) notes_cancel,
                   pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_reg_tstz, i_prof) dt_ord
              FROM harvest h, analysis_harvest ah, analysis_req_det ard
             WHERE h.id_harvest = i_harvest
               AND h.flg_status != pk_lab_tests_constant.g_harvest_inactive
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = ard.id_analysis_req_det
               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, ard.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes
             GROUP BY h.id_harvest,
                      h.dt_harvest_reg_tstz,
                      h.dt_cancel_tstz,
                      h.id_prof_harvest,
                      h.id_prof_cancels,
                      h.id_episode,
                      h.flg_status,
                      h.id_body_part,
                      h.flg_laterality,
                      h.flg_collection_method,
                      h.id_specimen_condition,
                      h.id_room_harvest,
                      h.flg_col_inst,
                      h.id_room_receive_tube,
                      h.id_institution,
                      ah.id_sample_recipient,
                      h.num_recipient,
                      h.dt_harvest_tstz,
                      h.amount,
                      h.flg_mov_tube,
                      h.notes,
                      h.harvest_instructions,
                      h.id_revised_by,
                      h.id_rep_coll_reason,
                      h.id_cancel_reason,
                      h.notes_cancel;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT id_harvest,
                   registry,
                   decode(rownum, 1, aa_code_messages('LAB_TESTS_T228') || chr(10), NULL) || chr(9) || chr(32) ||
                   chr(32) || desc_clinical_question desc_clinical_question,
                   desc_response
              FROM (SELECT aqr1.id_harvest,
                           l_msg_reg || ' ' || pk_prof_utils.get_name_signature(i_lang, i_prof, aqr.id_prof_last_update) ||
                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   aqr.id_prof_last_update,
                                                                   aqr.dt_last_update_tstz,
                                                                   aqr.id_episode),
                                  NULL,
                                  '; ',
                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           aqr.id_prof_last_update,
                                                                           aqr.dt_last_update_tstz,
                                                                           aqr.id_episode) || '); ') ||
                           pk_date_utils.date_char_tsz(i_lang,
                                                       aqr.dt_last_update_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) registry,
                           '<b>' ||
                           pk_mcdt.get_questionnaire_alias(i_lang,
                                                           i_prof,
                                                           'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || aqr1.id_questionnaire) ||
                           ':</b>' desc_clinical_question,
                           to_clob(decode(aqr.notes, NULL, aqr1.desc_response, aqr.notes)) desc_response
                      FROM (SELECT aqr.id_harvest,
                                   aqr.id_questionnaire,
                                   decode(aqr.id_response,
                                          NULL,
                                          '---',
                                          listagg(pk_mcdt.get_response_alias(i_lang,
                                                                             i_prof,
                                                                             'RESPONSE.CODE_RESPONSE.' || aqr.id_response),
                                                  '; ') within GROUP(ORDER BY aqr.id_response)) desc_response
                              FROM analysis_question_response aqr, harvest h
                             WHERE aqr.id_harvest = i_harvest
                               AND aqr.id_harvest = h.id_harvest
                               AND h.flg_status != pk_lab_tests_constant.g_harvest_inactive
                             GROUP BY aqr.id_harvest, aqr.id_questionnaire, aqr.id_response) aqr1,
                           analysis_question_response aqr
                     WHERE aqr.id_harvest = aqr1.id_harvest
                       AND aqr.id_questionnaire = aqr1.id_questionnaire
                     ORDER BY aqr.dt_last_update_tstz);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            RETURN FALSE;
    END get_harvest_detail;

    FUNCTION get_harvest_detail_history
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T045',
                                                        'LAB_TESTS_T047',
                                                        'LAB_TESTS_T174',
                                                        'LAB_TESTS_T175',
                                                        'LAB_TESTS_T192',
                                                        'LAB_TESTS_T193',
                                                        'LAB_TESTS_T030',
                                                        'LAB_TESTS_T082',
                                                        'LAB_TESTS_T028',
                                                        'LAB_TESTS_T081',
                                                        'LAB_TESTS_T056',
                                                        'LAB_TESTS_T057',
                                                        'LAB_TESTS_T058',
                                                        'LAB_TESTS_T241',
                                                        'LAB_TESTS_T242',
                                                        'LAB_TESTS_T238',
                                                        'LAB_TESTS_T243',
                                                        'LAB_TESTS_T205',
                                                        'LAB_TESTS_T209',
                                                        'LAB_TESTS_T187',
                                                        'LAB_TESTS_T188',
                                                        'LAB_TESTS_T059',
                                                        'LAB_TESTS_T060',
                                                        'LAB_TESTS_T061',
                                                        'LAB_TESTS_T062');
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M107');
        l_msg_del sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M106');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT h.id_harvest,
                   l_msg_reg || ' ' ||
                   pk_prof_utils.get_name_signature(i_lang, i_prof, nvl(h.id_prof_harvest, h.id_prof_cancels)) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           nvl(h.id_prof_harvest, h.id_prof_cancels),
                                                           nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                                           h.id_episode),
                          NULL,
                          '; ',
                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   nvl(h.id_prof_harvest, h.id_prof_cancels),
                                                                   nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                                                   h.id_episode) || '); ') ||
                   pk_date_utils.date_char_tsz(i_lang,
                                               nvl(h.dt_cancel_tstz, h.dt_harvest_reg_tstz),
                                               i_prof.institution,
                                               i_prof.software) registry,
                   aa_code_messages('LAB_TESTS_T045') ||
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || h.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || h.id_sample_type,
                                                            NULL) desc_analysis,
                   decode(cnt,
                          rn,
                          decode(h.flg_status,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T047') ||
                                 pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang)),
                          decode(h.flg_status,
                                 h.flg_status_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T047') || '�' ||
                                 decode(h.flg_status,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_STATUS', h.flg_status, NULL)) ||
                                 decode(h.flg_status_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T108') ||
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_STATUS',
                                                                h.flg_status_new,
                                                                NULL)))) desc_status,
                   decode(cnt,
                          rn,
                          decode(h.id_body_part,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T174') ||
                                 pk_translation.get_translation(i_lang,
                                                                'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || h.id_body_part)),
                          decode(h.id_body_part,
                                 h.id_body_part_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T175') || '�' ||
                                 decode(h.id_body_part,
                                        NULL,
                                        l_msg_del,
                                        pk_translation.get_translation(i_lang,
                                                                       'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' ||
                                                                       h.id_body_part)) ||
                                 decode(h.id_body_part_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T174') ||
                                        pk_translation.get_translation(i_lang,
                                                                       'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' ||
                                                                       h.id_body_part_new)))) desc_body_location,
                   decode(cnt,
                          rn,
                          decode(h.flg_collection_method,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T192') ||
                                 pk_sysdomain.get_domain(i_lang,
                                                         i_prof,
                                                         'HARVEST.FLG_COLLECTION_METHOD',
                                                         h.flg_collection_method,
                                                         NULL),
                                 pk_sysdomain.get_domain(i_lang,
                                                         i_prof,
                                                         'HARVEST.FLG_COLLECTION_METHOD',
                                                         h.flg_collection_method,
                                                         NULL)),
                          decode(h.flg_collection_method,
                                 h.flg_collection_method_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T193') || '�' ||
                                 decode(h.flg_collection_method,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_COLLECTION_METHOD',
                                                                h.flg_collection_method,
                                                                NULL)) ||
                                 decode(h.flg_collection_method_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T192') ||
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_COLLECTION_METHOD',
                                                                h.flg_collection_method_new,
                                                                NULL)),
                                 decode(h.flg_collection_method,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_COLLECTION_METHOD',
                                                                h.flg_collection_method,
                                                                NULL)) ||
                                 decode(h.flg_collection_method_new,
                                        NULL,
                                        NULL,
                                        '�' || pk_sysdomain.get_domain(i_lang,
                                                                       i_prof,
                                                                       'HARVEST.FLG_COLLECTION_METHOD',
                                                                       h.flg_collection_method_new,
                                                                       NULL)))) collection_method,
                   decode(cnt,
                          rn,
                          decode(h.id_room_harvest,
                                 NULL,
                                 decode(h.flg_col_inst,
                                        NULL,
                                        NULL,
                                        aa_code_messages('LAB_TESTS_T030') ||
                                        pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst, i_lang)),
                                 aa_code_messages('LAB_TESTS_T030') ||
                                 nvl((SELECT r.desc_room
                                       FROM room r
                                      WHERE r.id_room = h.id_room_harvest),
                                     pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))),
                          decode(h.id_room_harvest,
                                 NULL,
                                 decode(h.flg_col_inst,
                                        h.flg_col_inst_new,
                                        NULL,
                                        aa_code_messages('LAB_TESTS_T082') || '�' ||
                                        decode(h.flg_col_inst,
                                               NULL,
                                               l_msg_del,
                                               pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst, i_lang)) ||
                                        decode(h.flg_col_inst_new,
                                               NULL,
                                               NULL,
                                               chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T030') ||
                                               pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst_new, i_lang))),
                                 decode(h.id_room_harvest,
                                        h.id_room_harvest_new,
                                        NULL,
                                        aa_code_messages('LAB_TESTS_T082') || '�' ||
                                        decode(h.id_room_harvest,
                                               NULL,
                                               l_msg_del,
                                               nvl((SELECT r.desc_room
                                                     FROM room r
                                                    WHERE r.id_room = h.id_room_harvest),
                                                   pk_translation.get_translation(i_lang,
                                                                                  'ROOM.CODE_ROOM.' || h.id_room_harvest))) ||
                                        
                                        decode(h.id_room_harvest_new,
                                               NULL,
                                               NULL,
                                               chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T030') ||
                                               nvl((SELECT r.desc_room
                                                     FROM room r
                                                    WHERE r.id_room = h.id_room_harvest_new),
                                                   pk_translation.get_translation(i_lang,
                                                                                  'ROOM.CODE_ROOM.' || h.id_room_harvest_new)))))) collection_location,
                   decode(cnt,
                          rn,
                          decode(h.id_room_receive_tube,
                                 NULL,
                                 decode(h.id_institution,
                                        NULL,
                                        NULL,
                                        aa_code_messages('LAB_TESTS_T028') ||
                                        pk_translation.get_translation(i_lang,
                                                                       'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                       h.id_institution)),
                                 aa_code_messages('LAB_TESTS_T028') ||
                                 nvl((SELECT r.desc_room
                                       FROM room r
                                      WHERE r.id_room = h.id_room_receive_tube),
                                     pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube))),
                          decode(h.id_room_receive_tube,
                                 h.id_room_receive_tube_new,
                                 decode(h.id_institution,
                                        h.id_institution_new,
                                        NULL,
                                        aa_code_messages('LAB_TESTS_T081') || '�' ||
                                        decode(h.id_institution,
                                               NULL,
                                               l_msg_del,
                                               pk_translation.get_translation(i_lang,
                                                                              'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                              h.id_institution)) ||
                                        decode(h.id_institution_new,
                                               NULL,
                                               NULL,
                                               chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T028') ||
                                               pk_translation.get_translation(i_lang,
                                                                              'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                              h.id_institution_new))),
                                 aa_code_messages('LAB_TESTS_T081') || '�' ||
                                 decode(h.id_room_receive_tube,
                                        NULL,
                                        l_msg_del,
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_receive_tube),
                                            pk_translation.get_translation(i_lang,
                                                                           'ROOM.CODE_ROOM.' || h.id_room_receive_tube))) ||
                                 decode(h.id_room_receive_tube_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T028') ||
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_receive_tube_new),
                                            pk_translation.get_translation(i_lang,
                                                                           'ROOM.CODE_ROOM.' || h.id_room_receive_tube_new))))) perform_location,
                   decode(cnt,
                          rn,
                          decode(h.id_sample_recipient,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T056') ||
                                 pk_translation.get_translation(i_lang,
                                                                'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                h.id_sample_recipient)),
                          decode(h.id_sample_recipient,
                                 h.id_sample_recipient_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T098') || '�' ||
                                 decode(h.id_sample_recipient,
                                        NULL,
                                        l_msg_del,
                                        pk_translation.get_translation(i_lang,
                                                                       'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                       h.id_sample_recipient)) ||
                                 decode(h.id_sample_recipient_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T056') ||
                                        pk_translation.get_translation(i_lang,
                                                                       'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                       h.id_sample_recipient_new)))) desc_tubes,
                   decode(cnt,
                          rn,
                          decode(h.num_recipient, NULL, NULL, aa_code_messages('LAB_TESTS_T057') || h.num_recipient),
                          decode(h.num_recipient,
                                 h.num_recipient_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T099') || '�' ||
                                 decode(h.num_recipient, NULL, l_msg_del, h.num_recipient) ||
                                 decode(h.num_recipient_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T057') || h.num_recipient_new))) num_tubes,
                   decode(cnt,
                          rn,
                          decode(h.dt_harvest_tstz,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T058') ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_harvest_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          decode(h.dt_harvest_tstz,
                                 h.dt_harvest_tstz_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T100') || '�' ||
                                 decode(h.dt_harvest_tstz,
                                        NULL,
                                        l_msg_del,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_harvest_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software)) ||
                                 decode(h.dt_harvest_tstz_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T058') ||
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_harvest_tstz_new,
                                                                    i_prof.institution,
                                                                    i_prof.software)))) dt_harvest,
                   decode(cnt,
                          rn,
                          decode(h.amount,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T205') || h.amount || ' ' ||
                                 pk_translation.get_translation(i_lang,
                                                                'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                            i_prof,
                                                                                                            h.id_sample_recipient))),
                          decode(h.amount,
                                 h.amount_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T209') || '�' ||
                                 decode(h.amount,
                                        NULL,
                                        l_msg_del,
                                        h.amount || ' ' ||
                                        pk_translation.get_translation(i_lang,
                                                                       'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                       pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                                   i_prof,
                                                                                                                   h.id_sample_recipient))) ||
                                 decode(h.amount_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T205') || h.amount_new || ' ' ||
                                        pk_translation.get_translation(i_lang,
                                                                       'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                                       pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                                   i_prof,
                                                                                                                   h.id_sample_recipient))))) collection_amount,
                   decode(cnt,
                          rn,
                          decode(h.flg_mov_tube,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T187') ||
                                 pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', h.flg_mov_tube, NULL),
                                 pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', h.flg_mov_tube, NULL)),
                          decode(h.flg_mov_tube,
                                 h.flg_mov_tube_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T188') || '�' ||
                                 decode(h.flg_mov_tube,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_MOV_TUBE',
                                                                h.flg_mov_tube,
                                                                NULL)) ||
                                 decode(h.flg_mov_tube_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T187') ||
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_MOV_TUBE',
                                                                h.flg_mov_tube_new,
                                                                NULL)),
                                 decode(h.flg_mov_tube,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_MOV_TUBE',
                                                                h.flg_mov_tube,
                                                                NULL)) ||
                                 decode(h.flg_mov_tube_new,
                                        NULL,
                                        NULL,
                                        '�' || pk_sysdomain.get_domain(i_lang,
                                                                       i_prof,
                                                                       'HARVEST.FLG_MOV_TUBE',
                                                                       h.flg_mov_tube_new,
                                                                       NULL)))) harvest_transportation,
                   decode(cnt,
                          rn,
                          decode(h.notes, NULL, NULL, aa_code_messages('LAB_TESTS_T059') || h.notes),
                          decode(h.notes,
                                 h.notes_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T101') || '�' || decode(h.notes, NULL, l_msg_del, h.notes) ||
                                 decode(h.notes_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T059') || h.notes_new))) notes,
                   decode(cnt,
                          rn,
                          decode(h.harvest_instructions,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T241') || h.harvest_instructions),
                          decode(h.harvest_instructions,
                                 h.harvest_instructions_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T242') || '�' ||
                                 decode(h.harvest_instructions, NULL, l_msg_del, h.harvest_instructions) ||
                                 decode(h.harvest_instructions_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T241') ||
                                        h.harvest_instructions_new))) harvest_instructions,
                   decode(cnt,
                          rn,
                          decode(h.id_revised_by,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T238') ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by)),
                          decode(h.id_revised_by,
                                 h.id_revised_by_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T243') || '�' ||
                                 decode(pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by),
                                        NULL,
                                        l_msg_del,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by)) ||
                                 decode(h.id_revised_by_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T238') ||
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_revised_by_new)))) revised_by,
                   decode(cnt,
                          rn,
                          decode(h.id_rep_coll_reason,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T060') ||
                                 pk_translation.get_translation(i_lang,
                                                                'REPEAT_COLLECTION_REASON.CODE_REP_COLL_REASON.' ||
                                                                h.id_rep_coll_reason)),
                          decode(h.id_rep_coll_reason,
                                 h.id_rep_coll_reason_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T102') || '�' ||
                                 decode(h.id_rep_coll_reason,
                                        NULL,
                                        l_msg_del,
                                        pk_translation.get_translation(i_lang,
                                                                       'REPEAT_COLLECTION_REASON.CODE_REP_COLL_REASON.' ||
                                                                       h.id_rep_coll_reason)) ||
                                 decode(h.id_rep_coll_reason_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T060') ||
                                        pk_translation.get_translation(i_lang,
                                                                       'REPEAT_COLLECTION_REASON.CODE_REP_COLL_REASON.' ||
                                                                       h.id_rep_coll_reason_new)))) repeat_harvest_notes,
                   NULL cancel_reason,
                   NULL notes_cancel
              FROM (SELECT row_number() over(ORDER BY t.dt_harvest_hist DESC NULLS FIRST) rn,
                           MAX(rownum) over() cnt,
                           t.dt_harvest_hist,
                           t.id_analysis,
                           t.id_sample_type,
                           t.id_harvest,
                           first_value(t.id_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_harvest_new,
                           t.dt_harvest_reg_tstz,
                           first_value(t.dt_harvest_reg_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_harvest_reg_tstz_new,
                           t.dt_cancel_tstz,
                           first_value(t.dt_cancel_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_cancel_tstz_new,
                           t.id_prof_harvest,
                           first_value(t.id_prof_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_prof_harvest_new,
                           t.id_prof_cancels,
                           first_value(t.id_prof_cancels) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_prof_cancels_new,
                           t.id_episode,
                           t.flg_status,
                           first_value(t.flg_status) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_new,
                           t.id_body_part,
                           first_value(t.id_body_part) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_body_part_new,
                           t.flg_collection_method,
                           first_value(t.flg_collection_method) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_collection_method_new,
                           t.id_specimen_condition,
                           first_value(t.id_specimen_condition) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_specimen_condition_new,
                           t.id_room_harvest,
                           first_value(t.id_room_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_room_harvest_new,
                           t.flg_col_inst,
                           first_value(t.flg_col_inst) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_col_inst_new,
                           t.id_room_receive_tube,
                           first_value(t.id_room_receive_tube) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_room_receive_tube_new,
                           t.id_institution,
                           first_value(t.id_institution) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_institution_new,
                           t.id_sample_recipient,
                           first_value(t.id_sample_recipient) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_sample_recipient_new,
                           t.num_recipient,
                           first_value(t.num_recipient) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) num_recipient_new,
                           t.dt_harvest_tstz,
                           first_value(t.dt_harvest_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_harvest_tstz_new,
                           t.flg_mov_tube,
                           first_value(t.flg_mov_tube) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_mov_tube_new,
                           t.amount,
                           first_value(t.amount) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) amount_new,
                           t.notes,
                           first_value(t.notes) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) notes_new,
                           t.harvest_instructions,
                           first_value(t.harvest_instructions) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) harvest_instructions_new,
                           t.id_revised_by,
                           first_value(t.id_revised_by) over(PARTITION BY id_harvest ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_revised_by_new,
                           t.id_rep_coll_reason,
                           first_value(t.id_rep_coll_reason) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_rep_coll_reason_new,
                           t.id_cancel_reason,
                           first_value(t.id_cancel_reason) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_cancel_reason_new,
                           t.notes_cancel,
                           first_value(t.notes_cancel) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) notes_cancel_new
                      FROM (SELECT NULL dt_harvest_hist,
                                   ard.id_analysis,
                                   ard.id_sample_type,
                                   h.id_harvest,
                                   h.dt_harvest_reg_tstz,
                                   h.dt_cancel_tstz,
                                   h.id_prof_harvest,
                                   h.id_prof_cancels,
                                   h.id_episode,
                                   h.flg_status,
                                   h.id_body_part,
                                   h.flg_laterality,
                                   h.flg_collection_method,
                                   h.id_specimen_condition,
                                   h.id_room_harvest,
                                   h.flg_col_inst,
                                   h.id_room_receive_tube,
                                   h.id_institution,
                                   ah.id_sample_recipient,
                                   h.num_recipient,
                                   h.dt_harvest_tstz,
                                   h.amount,
                                   h.flg_mov_tube,
                                   h.notes,
                                   h.harvest_instructions,
                                   h.id_revised_by,
                                   h.id_rep_coll_reason,
                                   h.id_cancel_reason,
                                   h.notes_cancel
                              FROM harvest h, analysis_harvest ah, analysis_req_det ard
                             WHERE h.id_harvest = i_harvest
                               AND h.flg_status NOT IN (pk_lab_tests_constant.g_harvest_pending,
                                                        pk_lab_tests_constant.g_harvest_suspended,
                                                        pk_lab_tests_constant.g_harvest_inactive)
                               AND h.id_harvest = ah.id_harvest
                               AND ah.id_analysis_req_det = ard.id_analysis_req_det
                               AND ard.flg_status != pk_lab_tests_constant.g_analysis_cancel
                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                             i_prof,
                                                                                             ard.id_analysis)
                                      FROM dual) = pk_alert_constant.g_yes
                             GROUP BY ard.id_analysis,
                                      ard.id_sample_type,
                                      h.id_harvest,
                                      h.dt_harvest_reg_tstz,
                                      h.dt_cancel_tstz,
                                      h.id_prof_harvest,
                                      h.id_prof_cancels,
                                      h.id_episode,
                                      h.flg_status,
                                      h.id_body_part,
                                      h.flg_laterality,
                                      h.flg_collection_method,
                                      h.id_specimen_condition,
                                      h.id_room_harvest,
                                      h.flg_col_inst,
                                      h.id_room_receive_tube,
                                      h.id_institution,
                                      ah.id_sample_recipient,
                                      h.num_recipient,
                                      h.dt_harvest_tstz,
                                      h.amount,
                                      h.flg_mov_tube,
                                      h.notes,
                                      h.harvest_instructions,
                                      h.id_revised_by,
                                      h.id_rep_coll_reason,
                                      h.id_cancel_reason,
                                      h.notes_cancel
                            UNION ALL
                            SELECT hh.dt_harvest_hist,
                                   ard.id_analysis,
                                   ard.id_sample_type,
                                   hh.id_harvest,
                                   hh.dt_harvest_reg_tstz,
                                   hh.dt_cancel_tstz,
                                   hh.id_prof_harvest,
                                   hh.id_prof_cancels,
                                   hh.id_episode,
                                   hh.flg_status,
                                   hh.id_body_part,
                                   hh.flg_laterality,
                                   hh.flg_collection_method,
                                   hh.id_specimen_condition,
                                   hh.id_room_harvest,
                                   hh.flg_col_inst,
                                   hh.id_room_receive_tube,
                                   hh.id_institution,
                                   ahh.id_sample_recipient,
                                   hh.num_recipient,
                                   hh.dt_harvest_tstz,
                                   hh.amount,
                                   hh.flg_mov_tube,
                                   hh.notes,
                                   hh.harvest_instructions,
                                   hh.id_revised_by,
                                   hh.id_rep_coll_reason,
                                   hh.id_cancel_reason,
                                   hh.notes_cancel
                              FROM harvest_hist hh, analysis_harvest_hist ahh, analysis_req_det ard
                             WHERE hh.id_harvest = i_harvest
                               AND hh.flg_status NOT IN (pk_lab_tests_constant.g_harvest_pending,
                                                         pk_lab_tests_constant.g_harvest_suspended,
                                                         pk_lab_tests_constant.g_harvest_inactive)
                               AND hh.id_harvest = ahh.id_harvest
                               AND ahh.id_analysis_req_det = ard.id_analysis_req_det
                               AND ard.flg_status != pk_lab_tests_constant.g_analysis_cancel
                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                             i_prof,
                                                                                             ard.id_analysis)
                                      FROM dual) = pk_alert_constant.g_yes
                             GROUP BY hh.dt_harvest_hist,
                                      ard.id_analysis,
                                      ard.id_sample_type,
                                      hh.id_harvest,
                                      hh.dt_harvest_reg_tstz,
                                      hh.id_prof_harvest,
                                      hh.id_episode,
                                      hh.flg_status,
                                      hh.id_body_part,
                                      hh.flg_laterality,
                                      hh.flg_collection_method,
                                      hh.id_specimen_condition,
                                      hh.id_room_harvest,
                                      hh.flg_col_inst,
                                      hh.id_room_receive_tube,
                                      hh.id_institution,
                                      ahh.id_sample_recipient,
                                      hh.num_recipient,
                                      hh.dt_harvest_tstz,
                                      hh.amount,
                                      hh.flg_mov_tube,
                                      hh.notes,
                                      hh.harvest_instructions,
                                      hh.id_revised_by,
                                      hh.id_rep_coll_reason,
                                      hh.id_cancel_reason,
                                      hh.notes_cancel
                             ORDER BY dt_harvest_hist DESC NULLS FIRST) t
                     ORDER BY rn) h;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT id_harvest,
                   registry,
                   decode(rownum, 1, aa_code_messages('LAB_TESTS_T228') || chr(10), NULL) || chr(9) || chr(32) ||
                   chr(32) || desc_clinical_question desc_clinical_question,
                   desc_response
              FROM (SELECT aqr1.id_harvest,
                           l_msg_reg || ' ' || pk_prof_utils.get_name_signature(i_lang, i_prof, aqr.id_prof_last_update) ||
                           decode(pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   aqr.id_prof_last_update,
                                                                   aqr.dt_last_update_tstz,
                                                                   aqr.id_episode),
                                  NULL,
                                  '; ',
                                  ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                           i_prof,
                                                                           aqr.id_prof_last_update,
                                                                           aqr.dt_last_update_tstz,
                                                                           aqr.id_episode) || '); ') ||
                           pk_date_utils.date_char_tsz(i_lang,
                                                       aqr.dt_last_update_tstz,
                                                       i_prof.institution,
                                                       i_prof.software) registry,
                           '<b>' ||
                           pk_mcdt.get_questionnaire_alias(i_lang,
                                                           i_prof,
                                                           'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || aqr1.id_questionnaire) ||
                           ':</b>' desc_clinical_question,
                           to_clob(decode(aqr.notes, NULL, aqr1.desc_response, aqr.notes)) desc_response
                      FROM (SELECT aqr.id_harvest,
                                   aqr.id_questionnaire,
                                   decode(aqr.id_response,
                                          NULL,
                                          '---',
                                          listagg(pk_mcdt.get_response_alias(i_lang,
                                                                             i_prof,
                                                                             'RESPONSE.CODE_RESPONSE.' || aqr.id_response),
                                                  '; ') within GROUP(ORDER BY aqr.id_response)) desc_response
                              FROM analysis_question_response aqr, harvest h
                             WHERE aqr.id_harvest = i_harvest
                               AND aqr.id_harvest = h.id_harvest
                               AND h.flg_status != pk_lab_tests_constant.g_harvest_inactive
                             GROUP BY aqr.id_harvest, aqr.id_questionnaire, aqr.id_response) aqr1,
                           analysis_question_response aqr
                     WHERE aqr.id_harvest = aqr1.id_harvest
                       AND aqr.id_questionnaire = aqr1.id_questionnaire
                     ORDER BY aqr.dt_last_update_tstz);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_DETAIL_HISTORY',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            RETURN FALSE;
    END get_harvest_detail_history;

    FUNCTION get_harvest_movement_detail
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_harvest                  IN harvest.id_harvest%TYPE,
        i_flg_report               IN VARCHAR2 DEFAULT 'N',
        o_lab_test_harvest         OUT pk_types.cursor_type,
        o_lab_test_harvest_history OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T045',
                                                        'LAB_TESTS_T047',
                                                        'LAB_TESTS_T056',
                                                        'LAB_TESTS_T057',
                                                        'LAB_TESTS_T156',
                                                        'LAB_TESTS_T157',
                                                        'LAB_TESTS_T160',
                                                        'LAB_TESTS_T162',
                                                        'LAB_TESTS_T164',
                                                        'LAB_TESTS_T166',
                                                        'LAB_TESTS_T108',
                                                        'LAB_TESTS_T098',
                                                        'LAB_TESTS_T099',
                                                        'LAB_TESTS_T158',
                                                        'LAB_TESTS_T157',
                                                        'LAB_TESTS_T159',
                                                        'LAB_TESTS_T161',
                                                        'LAB_TESTS_T163',
                                                        'LAB_TESTS_T165',
                                                        'LAB_TESTS_T167');
    
        l_msg_reg sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M107');
        l_msg_del sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'COMMON_M106');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT h.id_harvest,
                   l_msg_reg || ' ' ||
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    coalesce(h.id_prof_receive_tube,
                                                             h.id_prof_mov_tube,
                                                             h.id_prof_harvest)) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           coalesce(h.id_prof_receive_tube,
                                                                    h.id_prof_mov_tube,
                                                                    h.id_prof_harvest),
                                                           coalesce(h.dt_lab_reception_tstz,
                                                                    h.dt_mov_begin_tstz,
                                                                    dt_harvest_reg_tstz),
                                                           h.id_episode),
                          NULL,
                          '; ',
                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   coalesce(h.id_prof_receive_tube,
                                                                            h.id_prof_mov_tube,
                                                                            h.id_prof_harvest),
                                                                   coalesce(h.dt_lab_reception_tstz,
                                                                            h.dt_mov_begin_tstz,
                                                                            dt_harvest_reg_tstz),
                                                                   h.id_episode) || '); ') ||
                   pk_date_utils.date_char_tsz(i_lang,
                                               coalesce(h.dt_lab_reception_tstz,
                                                        h.dt_mov_begin_tstz,
                                                        dt_harvest_reg_tstz),
                                               i_prof.institution,
                                               i_prof.software) registry,
                   decode(i_flg_report,
                          pk_lab_tests_constant.g_no,
                          aa_code_messages('LAB_TESTS_T045') ||
                          substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      ard.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      ard.id_sample_type,
                                                                                      NULL) || '; '),
                                 1,
                                 length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                             i_prof,
                                                                                             pk_lab_tests_constant.g_analysis_alias,
                                                                                             'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                             ard.id_analysis,
                                                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                             ard.id_sample_type,
                                                                                             NULL) || '; ')) - 2),
                          substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      ard.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      ard.id_sample_type,
                                                                                      NULL) || '; '),
                                 1,
                                 length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                             i_prof,
                                                                                             pk_lab_tests_constant.g_analysis_alias,
                                                                                             'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                             ard.id_analysis,
                                                                                             'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                             ard.id_sample_type,
                                                                                             NULL) || '; ')) - 2)) desc_analysis,
                   decode(i_flg_report,
                          pk_lab_tests_constant.g_no,
                          aa_code_messages('LAB_TESTS_T047') ||
                          pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang),
                          pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang)) desc_status,
                   decode(ah.id_sample_recipient,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T056') ||
                                 pk_translation.get_translation(i_lang,
                                                                'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                ah.id_sample_recipient),
                                 pk_translation.get_translation(i_lang,
                                                                'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                ah.id_sample_recipient))) desc_tubes,
                   decode(h.num_recipient,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T057') || h.num_recipient,
                                 h.num_recipient)) num_tubes,
                   decode(h.id_room_harvest,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T156') ||
                                 pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || r1.id_department) ||
                                 ' / ' || nvl(r1.desc_room, pk_translation.get_translation(i_lang, r1.code_room)),
                                 pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || r1.id_department) ||
                                 ' / ' || nvl(r1.desc_room, pk_translation.get_translation(i_lang, r1.code_room)))) desc_room_origin,
                   decode(h.id_room_receive_tube,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T157') ||
                                 pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || r2.id_department) ||
                                 ' / ' || nvl(r2.desc_room, pk_translation.get_translation(i_lang, r2.code_room)),
                                 pk_translation.get_translation(i_lang, 'DEPARTMENT.CODE_DEPARTMENT.' || r2.id_department) ||
                                 ' / ' || nvl(r2.desc_room, pk_translation.get_translation(i_lang, r2.code_room)))) desc_room_destination,
                   decode(h.id_prof_mov_tube,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T160') ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_mov_tube),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_mov_tube))) prof_movement,
                   decode(h.dt_mov_begin_tstz,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T162') ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_mov_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_mov_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software))) dt_movement,
                   decode(h.id_prof_receive_tube,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T164') ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_receive_tube),
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_receive_tube))) prof_receive,
                   decode(h.dt_lab_reception_tstz,
                          NULL,
                          NULL,
                          decode(i_flg_report,
                                 pk_lab_tests_constant.g_no,
                                 aa_code_messages('LAB_TESTS_T166') ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_lab_reception_tstz,
                                                             i_prof.institution,
                                                             i_prof.software),
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_lab_reception_tstz,
                                                             i_prof.institution,
                                                             i_prof.software))) dt_receive
              FROM harvest h, analysis_harvest ah, analysis_req_det ard, room r1, room r2
             WHERE h.id_harvest = i_harvest
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = ard.id_analysis_req_det
               AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
               AND h.id_room_harvest = r1.id_room(+)
               AND h.id_room_receive_tube = r2.id_room
               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, ard.id_analysis)
                      FROM dual) = pk_alert_constant.g_yes
             GROUP BY h.id_harvest,
                      h.id_episode,
                      h.flg_status,
                      ah.id_sample_recipient,
                      h.num_recipient,
                      h.id_room_harvest,
                      r1.desc_room,
                      r1.code_room,
                      h.id_room_receive_tube,
                      r1.id_department,
                      r2.desc_room,
                      r2.code_room,
                      r2.id_department,
                      h.id_prof_mov_tube,
                      h.dt_mov_begin_tstz,
                      h.id_prof_receive_tube,
                      h.dt_lab_reception_tstz,
                      h.id_prof_harvest,
                      h.dt_harvest_reg_tstz;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST_HISTORY';
        OPEN o_lab_test_harvest_history FOR
            SELECT h.id_harvest,
                   l_msg_reg || ' ' ||
                   pk_prof_utils.get_name_signature(i_lang,
                                                    i_prof,
                                                    coalesce(h.id_prof_receive_tube,
                                                             h.id_prof_mov_tube,
                                                             h.id_prof_harvest)) ||
                   decode(pk_prof_utils.get_spec_signature(i_lang,
                                                           i_prof,
                                                           coalesce(h.id_prof_receive_tube,
                                                                    h.id_prof_mov_tube,
                                                                    h.id_prof_harvest),
                                                           coalesce(h.dt_lab_reception_tstz,
                                                                    h.dt_mov_begin_tstz,
                                                                    dt_harvest_reg_tstz),
                                                           h.id_episode),
                          NULL,
                          '; ',
                          ' (' || pk_prof_utils.get_spec_signature(i_lang,
                                                                   i_prof,
                                                                   coalesce(h.id_prof_receive_tube,
                                                                            h.id_prof_mov_tube,
                                                                            h.id_prof_harvest),
                                                                   coalesce(h.dt_lab_reception_tstz,
                                                                            h.dt_mov_begin_tstz,
                                                                            dt_harvest_reg_tstz),
                                                                   h.id_episode) || '); ') ||
                   pk_date_utils.date_char_tsz(i_lang,
                                               coalesce(h.dt_lab_reception_tstz,
                                                        h.dt_mov_begin_tstz,
                                                        dt_harvest_reg_tstz),
                                               i_prof.institution,
                                               i_prof.software) registry,
                   aa_code_messages('LAB_TESTS_T045') ||
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || h.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || h.id_sample_type,
                                                            NULL) desc_analysis,
                   decode(cnt,
                          rn,
                          decode(h.flg_status,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T047') ||
                                 pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang)),
                          decode(h.flg_status,
                                 h.flg_status_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T047') || '�' ||
                                 decode(h.flg_status,
                                        NULL,
                                        l_msg_del,
                                        pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_STATUS', h.flg_status, NULL)) ||
                                 decode(h.flg_status_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T108') ||
                                        pk_sysdomain.get_domain(i_lang,
                                                                i_prof,
                                                                'HARVEST.FLG_STATUS',
                                                                h.flg_status_new,
                                                                NULL)))) desc_status,
                   decode(cnt,
                          rn,
                          decode(h.id_sample_recipient,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T056') ||
                                 pk_translation.get_translation(i_lang,
                                                                'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                h.id_sample_recipient)),
                          decode(h.id_sample_recipient,
                                 h.id_sample_recipient_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T098') || '�' ||
                                 decode(h.id_sample_recipient,
                                        NULL,
                                        l_msg_del,
                                        pk_translation.get_translation(i_lang,
                                                                       'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                       h.id_sample_recipient)) ||
                                 decode(h.id_sample_recipient_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T056') ||
                                        pk_translation.get_translation(i_lang,
                                                                       'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                       h.id_sample_recipient_new)))) desc_tubes,
                   decode(cnt,
                          rn,
                          decode(h.num_recipient, NULL, NULL, aa_code_messages('LAB_TESTS_T057') || h.num_recipient),
                          decode(h.num_recipient,
                                 h.num_recipient_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T099') || '�' ||
                                 decode(h.num_recipient, NULL, l_msg_del, h.num_recipient) ||
                                 decode(h.num_recipient_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T057') || h.num_recipient_new))) num_tubes,
                   decode(cnt,
                          rn,
                          decode(h.id_room_harvest,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T156') ||
                                 (SELECT pk_translation.get_translation(i_lang,
                                                                        'DEPARTMENT.CODE_DEPARTMENT.' || r.id_department)
                                    FROM room r
                                   WHERE r.id_room = h.id_room_harvest) || ' / ' ||
                                 nvl((SELECT r.desc_room
                                       FROM room r
                                      WHERE r.id_room = h.id_room_harvest),
                                     pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))),
                          decode(h.id_room_harvest,
                                 h.id_room_harvest_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T158') || '�' ||
                                 decode(h.id_room_harvest,
                                        NULL,
                                        l_msg_del,
                                        (SELECT pk_translation.get_translation(i_lang,
                                                                               'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                               r.id_department)
                                           FROM room r
                                          WHERE r.id_room = h.id_room_harvest) || ' / ' ||
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_harvest),
                                            pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))) ||
                                 decode(h.id_room_harvest_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T156') ||
                                        (SELECT pk_translation.get_translation(i_lang,
                                                                               'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                               r.id_department)
                                           FROM room r
                                          WHERE r.id_room = h.id_room_harvest_new) || ' / ' ||
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_harvest_new),
                                            pk_translation.get_translation(i_lang,
                                                                           'ROOM.CODE_ROOM.' || h.id_room_harvest_new))))) desc_room_origin,
                   decode(cnt,
                          rn,
                          decode(h.id_room_receive_tube,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T157') ||
                                 (SELECT pk_translation.get_translation(i_lang,
                                                                        'DEPARTMENT.CODE_DEPARTMENT.' || r.id_department)
                                    FROM room r
                                   WHERE r.id_room = h.id_room_receive_tube) || ' / ' ||
                                 nvl((SELECT r.desc_room
                                       FROM room r
                                      WHERE r.id_room = h.id_room_receive_tube),
                                     pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube))),
                          decode(h.id_room_receive_tube,
                                 h.id_room_receive_tube_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T159') || '�' ||
                                 decode(h.id_room_receive_tube,
                                        NULL,
                                        l_msg_del,
                                        (SELECT pk_translation.get_translation(i_lang,
                                                                               'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                               r.id_department)
                                           FROM room r
                                          WHERE r.id_room = h.id_room_receive_tube) || ' / ' ||
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_receive_tube),
                                            pk_translation.get_translation(i_lang,
                                                                           'ROOM.CODE_ROOM.' || h.id_room_receive_tube))) ||
                                 decode(h.id_room_receive_tube_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T157') ||
                                        (SELECT pk_translation.get_translation(i_lang,
                                                                               'DEPARTMENT.CODE_DEPARTMENT.' ||
                                                                               r.id_department)
                                           FROM room r
                                          WHERE r.id_room = h.id_room_receive_tube_new) || ' / ' ||
                                        nvl((SELECT r.desc_room
                                              FROM room r
                                             WHERE r.id_room = h.id_room_receive_tube_new),
                                            pk_translation.get_translation(i_lang,
                                                                           'ROOM.CODE_ROOM.' || h.id_room_receive_tube_new))))) desc_room_destination,
                   decode(cnt,
                          rn,
                          decode(h.id_prof_mov_tube,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T160') ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_mov_tube)),
                          decode(h.id_prof_mov_tube,
                                 h.id_prof_mov_tube_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T161') || '�' ||
                                 decode(h.id_prof_mov_tube,
                                        NULL,
                                        l_msg_del,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_mov_tube)) ||
                                 decode(h.id_prof_mov_tube_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T160') ||
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_mov_tube_new)))) prof_movement,
                   decode(cnt,
                          rn,
                          decode(h.dt_mov_begin_tstz,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T162') ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_mov_begin_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          decode(h.dt_mov_begin_tstz,
                                 h.dt_mov_begin_tstz_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T163') || '�' ||
                                 decode(h.dt_mov_begin_tstz,
                                        NULL,
                                        l_msg_del,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_mov_begin_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software)) ||
                                 decode(h.dt_mov_begin_tstz_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T162') ||
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_mov_begin_tstz_new,
                                                                    i_prof.institution,
                                                                    i_prof.software)))) dt_movement,
                   
                   decode(cnt,
                          rn,
                          decode(h.id_prof_receive_tube,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T164') ||
                                 pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_receive_tube)),
                          decode(h.id_prof_receive_tube,
                                 h.id_prof_receive_tube_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T165') || '�' ||
                                 decode(h.id_prof_receive_tube,
                                        NULL,
                                        l_msg_del,
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_receive_tube)) ||
                                 decode(h.id_prof_receive_tube_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T164') ||
                                        pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_receive_tube_new)))) prof_receive,
                   decode(cnt,
                          rn,
                          decode(h.dt_lab_reception_tstz,
                                 NULL,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T166') ||
                                 pk_date_utils.date_char_tsz(i_lang,
                                                             h.dt_lab_reception_tstz,
                                                             i_prof.institution,
                                                             i_prof.software)),
                          decode(h.dt_lab_reception_tstz,
                                 h.dt_lab_reception_tstz_new,
                                 NULL,
                                 aa_code_messages('LAB_TESTS_T167') || '�' ||
                                 decode(h.dt_lab_reception_tstz,
                                        NULL,
                                        l_msg_del,
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_lab_reception_tstz,
                                                                    i_prof.institution,
                                                                    i_prof.software)) ||
                                 decode(h.dt_lab_reception_tstz_new,
                                        NULL,
                                        NULL,
                                        chr(10) || chr(9) || aa_code_messages('LAB_TESTS_T166') ||
                                        pk_date_utils.date_char_tsz(i_lang,
                                                                    h.dt_lab_reception_tstz_new,
                                                                    i_prof.institution,
                                                                    i_prof.software)))) dt_receive
              FROM (SELECT row_number() over(ORDER BY t.dt_harvest_hist DESC NULLS FIRST) rn,
                           MAX(rownum) over() cnt,
                           t.dt_harvest_hist,
                           t.id_analysis,
                           t.id_sample_type,
                           first_value(t.id_analysis) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_analysis_new,
                           t.id_harvest,
                           t.id_episode,
                           first_value(t.id_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_harvest_new,
                           t.flg_status,
                           first_value(t.flg_status) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) flg_status_new,
                           t.id_sample_recipient,
                           first_value(t.id_sample_recipient) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_sample_recipient_new,
                           t.num_recipient,
                           first_value(t.num_recipient) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) num_recipient_new,
                           t.id_room_harvest,
                           first_value(t.id_room_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_room_harvest_new,
                           t.id_room_receive_tube,
                           first_value(t.id_room_receive_tube) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_room_receive_tube_new,
                           t.id_prof_mov_tube,
                           first_value(t.id_prof_mov_tube) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_prof_mov_tube_new,
                           t.dt_mov_begin_tstz,
                           first_value(t.dt_mov_begin_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_mov_begin_tstz_new,
                           t.id_prof_receive_tube,
                           first_value(t.id_prof_receive_tube) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_prof_receive_tube_new,
                           t.dt_lab_reception_tstz,
                           first_value(t.dt_lab_reception_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_lab_reception_tstz_new,
                           t.id_prof_harvest,
                           first_value(t.id_prof_harvest) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) id_prof_harvest_new,
                           t.dt_harvest_reg_tstz,
                           first_value(t.dt_harvest_reg_tstz) over(ORDER BY dt_harvest_hist rows BETWEEN 1 preceding AND CURRENT ROW) dt_harvest_reg_tstz_new
                      FROM (SELECT NULL dt_harvest_hist,
                                   ard.id_analysis,
                                   ard.id_sample_type,
                                   h.id_harvest,
                                   h.id_episode,
                                   h.flg_status,
                                   ah.id_sample_recipient,
                                   h.num_recipient,
                                   h.id_room_harvest,
                                   h.id_room_receive_tube,
                                   h.id_prof_mov_tube,
                                   h.dt_mov_begin_tstz,
                                   h.id_prof_receive_tube,
                                   h.dt_lab_reception_tstz,
                                   h.id_prof_harvest,
                                   h.dt_harvest_reg_tstz
                              FROM harvest h, analysis_harvest ah, analysis_req_det ard
                             WHERE h.id_harvest = i_harvest
                               AND h.flg_status != pk_lab_tests_constant.g_harvest_pending
                               AND h.id_harvest = ah.id_harvest
                               AND ah.flg_status != pk_lab_tests_constant.g_harvest_inactive
                               AND ah.id_analysis_req_det = ard.id_analysis_req_det
                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                             i_prof,
                                                                                             ard.id_analysis)
                                      FROM dual) = pk_alert_constant.g_yes
                             GROUP BY ard.id_analysis,
                                      ard.id_sample_type,
                                      h.id_harvest,
                                      h.id_episode,
                                      h.flg_status,
                                      ah.id_sample_recipient,
                                      h.num_recipient,
                                      h.id_room_harvest,
                                      h.id_room_receive_tube,
                                      h.id_prof_mov_tube,
                                      h.dt_mov_begin_tstz,
                                      h.id_prof_receive_tube,
                                      h.dt_lab_reception_tstz,
                                      h.id_prof_harvest,
                                      h.dt_harvest_reg_tstz
                            UNION ALL
                            SELECT hh.dt_harvest_hist,
                                   ard.id_analysis,
                                   ard.id_sample_type,
                                   hh.id_harvest,
                                   hh.id_episode,
                                   hh.flg_status,
                                   ahh.id_sample_recipient,
                                   hh.num_recipient,
                                   hh.id_room_harvest,
                                   hh.id_room_receive_tube,
                                   hh.id_prof_mov_tube,
                                   hh.dt_mov_begin_tstz,
                                   hh.id_prof_receive_tube,
                                   hh.dt_lab_reception_tstz,
                                   hh.id_prof_harvest,
                                   hh.dt_harvest_reg_tstz
                              FROM harvest_hist hh, analysis_harvest_hist ahh, analysis_req_det ard
                             WHERE hh.id_harvest = i_harvest
                               AND hh.flg_status != pk_lab_tests_constant.g_harvest_pending
                               AND hh.id_harvest = ahh.id_harvest
                               AND ahh.flg_status != pk_lab_tests_constant.g_harvest_inactive
                               AND ahh.id_analysis_req_det = ard.id_analysis_req_det
                               AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang,
                                                                                             i_prof,
                                                                                             ard.id_analysis)
                                      FROM dual) = pk_alert_constant.g_yes
                             GROUP BY hh.dt_harvest_hist,
                                      ard.id_analysis,
                                      ard.id_sample_type,
                                      hh.id_harvest,
                                      hh.id_episode,
                                      hh.flg_status,
                                      ahh.id_sample_recipient,
                                      hh.num_recipient,
                                      hh.id_room_harvest,
                                      hh.id_room_receive_tube,
                                      hh.id_prof_mov_tube,
                                      hh.dt_mov_begin_tstz,
                                      hh.id_prof_receive_tube,
                                      hh.dt_lab_reception_tstz,
                                      hh.id_prof_harvest,
                                      hh.dt_harvest_reg_tstz
                             ORDER BY dt_harvest_hist DESC NULLS FIRST) t
                     ORDER BY rn) h;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_MOVEMENT_DETAIL',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_harvest_history);
            RETURN FALSE;
    END get_harvest_movement_detail;

    FUNCTION get_harvest
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN harvest.id_harvest%TYPE,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T045',
                                                        'LAB_TESTS_T047',
                                                        'LAB_TESTS_T174',
                                                        'LAB_TESTS_T192',
                                                        'LAB_TESTS_T194',
                                                        'LAB_TESTS_T030',
                                                        'LAB_TESTS_T028',
                                                        'LAB_TESTS_T056',
                                                        'LAB_TESTS_T057',
                                                        'LAB_TESTS_T058',
                                                        'LAB_TESTS_T205',
                                                        'LAB_TESTS_T187',
                                                        'LAB_TESTS_T059',
                                                        'LAB_TESTS_T060',
                                                        'LAB_TESTS_T061',
                                                        'LAB_TESTS_T195',
                                                        'LAB_TESTS_T062',
                                                        'LAB_TESTS_T198');
    
    BEGIN
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT h.id_harvest,
                   pk_date_utils.date_char_tsz(i_lang, h.dt_harvest_reg_tstz, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, h.id_prof_harvest) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang,
                                                    i_prof,
                                                    h.id_prof_harvest,
                                                    h.dt_harvest_reg_tstz,
                                                    h.id_episode) prof_spec_reg,
                   aa_code_messages('LAB_TESTS_T045') ||
                   substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               pk_lab_tests_constant.g_analysis_alias,
                                                                               'ANALYSIS.CODE_ANALYSIS.' ||
                                                                               ard.id_analysis,
                                                                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                               ard.id_sample_type,
                                                                               NULL) || '; '),
                          1,
                          length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      ard.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      ard.id_sample_type,
                                                                                      NULL) || '; ')) - 2) desc_analysis,
                   aa_code_messages('LAB_TESTS_T047') ||
                   pk_sysdomain.get_domain('HARVEST.FLG_STATUS', h.flg_status, i_lang) desc_status,
                   decode(h.id_body_part,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T174') ||
                          pk_translation.get_translation(i_lang, 'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || h.id_body_part) ||
                          decode(h.flg_laterality,
                                 NULL,
                                 NULL,
                                 ' - ' || pk_sysdomain.get_domain('HARVEST.FLG_LATERALITY', h.flg_laterality, i_lang))) desc_body_location,
                   decode(h.flg_collection_method,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T192') ||
                          pk_sysdomain.get_domain(i_lang,
                                                  i_prof,
                                                  'HARVEST.FLG_COLLECTION_METHOD',
                                                  h.flg_collection_method,
                                                  NULL)) collection_method,
                   decode(h.id_specimen_condition,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T194') ||
                          pk_translation.get_translation(i_lang,
                                                         'ANALYSIS_SPECIMEN_CONDITION.CODE_SPECIMEN_CONDITION.' ||
                                                         h.id_specimen_condition)) specimen_condition,
                   decode(h.id_room_harvest,
                          NULL,
                          aa_code_messages('LAB_TESTS_T030') ||
                          pk_sysdomain.get_domain('HARVEST.FLG_COL_INST', h.flg_col_inst, i_lang),
                          aa_code_messages('LAB_TESTS_T030') ||
                          nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_harvest),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))) collection_location,
                   aa_code_messages('LAB_TESTS_T028') ||
                   decode(nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_receive_tube),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube)),
                          NULL,
                          pk_translation.get_translation(i_lang, 'AB_INSTITUTION.CODE_INSTITUTION.' || h.id_institution),
                          nvl((SELECT r.desc_room
                                FROM room r
                               WHERE r.id_room = h.id_room_receive_tube),
                              pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube))) perform_location,
                   aa_code_messages('LAB_TESTS_T056') ||
                   pk_translation.get_translation(i_lang,
                                                  'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || ah.id_sample_recipient) desc_tubes,
                   aa_code_messages('LAB_TESTS_T057') || h.num_recipient num_tubes,
                   aa_code_messages('LAB_TESTS_T058') ||
                   pk_date_utils.date_char_tsz(i_lang, h.dt_harvest_tstz, i_prof.institution, i_prof.software) dt_harvest,
                   decode(h.amount,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T205') || h.amount || ' ' ||
                          pk_translation.get_translation(i_lang,
                                                         'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                         pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                     i_prof,
                                                                                                     ah.id_sample_recipient))) collection_amount,
                   decode(h.flg_mov_tube,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T187') ||
                          pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', h.flg_mov_tube, NULL)) harvest_transportation,
                   decode(h.notes, NULL, NULL, aa_code_messages('LAB_TESTS_T059') || h.notes) notes,
                   decode(h.id_rep_coll_reason,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T060') ||
                          pk_translation.get_translation(i_lang,
                                                         'REPEAT_COLLECTION_REASON.CODE_REP_COLL_REASON.' ||
                                                         h.id_rep_coll_reason)) repeat_harvest_notes,
                   decode(h.id_cancel_reason,
                          NULL,
                          NULL,
                          decode(h.flg_status,
                                 pk_lab_tests_constant.g_harvest_rejected,
                                 aa_code_messages('LAB_TESTS_T195'),
                                 aa_code_messages('LAB_TESTS_T062')) ||
                          pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, h.id_cancel_reason)) cancel_reason,
                   decode(h.notes_cancel,
                          NULL,
                          NULL,
                          decode(h.flg_status,
                                 pk_lab_tests_constant.g_harvest_rejected,
                                 aa_code_messages('LAB_TESTS_T198'),
                                 aa_code_messages('LAB_TESTS_T061')) || h.notes_cancel) notes_cancel,
                   pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_reg_tstz, i_prof) dt_ord
              FROM harvest h, analysis_harvest ah, analysis_req_det ard
             WHERE h.id_harvest = i_harvest
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = ard.id_analysis_req_det
             GROUP BY h.id_harvest,
                      h.dt_harvest_reg_tstz,
                      h.id_prof_harvest,
                      h.id_episode,
                      h.flg_status,
                      h.id_body_part,
                      h.flg_laterality,
                      h.flg_collection_method,
                      h.id_specimen_condition,
                      h.id_room_harvest,
                      h.flg_col_inst,
                      h.id_room_receive_tube,
                      h.id_institution,
                      ah.id_sample_recipient,
                      h.num_recipient,
                      h.dt_harvest_tstz,
                      h.amount,
                      h.flg_mov_tube,
                      h.notes,
                      h.id_rep_coll_reason,
                      h.notes_cancel,
                      h.id_cancel_reason;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT aqr1.id_harvest,
                   '<b>' ||
                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                   i_prof,
                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' || aqr1.id_questionnaire) ||
                   ':</b>' desc_clinical_question,
                   to_clob(decode(aqr.notes, NULL, aqr1.desc_response, aqr.notes)) desc_response
              FROM (SELECT aqr.id_harvest,
                           aqr.id_questionnaire,
                           decode(aqr.id_response,
                                  NULL,
                                  '---',
                                  listagg(pk_mcdt.get_response_alias(i_lang,
                                                                     i_prof,
                                                                     'RESPONSE.CODE_RESPONSE.' || aqr.id_response),
                                          '; ') within GROUP(ORDER BY aqr.id_response)) desc_response
                      FROM analysis_question_response aqr, harvest h
                     WHERE aqr.id_harvest = i_harvest
                       AND aqr.id_harvest = h.id_harvest
                       AND h.flg_status != pk_lab_tests_constant.g_harvest_inactive
                     GROUP BY aqr.id_harvest, aqr.id_questionnaire, aqr.id_response) aqr1,
                   analysis_question_response aqr
             WHERE aqr.id_harvest = aqr1.id_harvest
               AND aqr.id_questionnaire = aqr1.id_questionnaire
             ORDER BY aqr.dt_last_update_tstz;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            RETURN FALSE;
    END get_harvest;

    FUNCTION get_harvest_barcode
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_harvest          IN harvest.id_harvest%TYPE,
        o_lab_test_harvest OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT h.id_harvest,
                   nvl(h.barcode, ard.barcode) barcode,
                   pk_date_utils.date_send_tsz(i_lang, h.dt_harvest_reg_tstz, i_prof) dt_ord,
                   CASE
                        WHEN ar.id_analysis_result IS NULL THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END flg_has_results
              FROM harvest h
              JOIN analysis_harvest ah
                ON ah.id_harvest = h.id_harvest
              JOIN analysis_req_det ard
                ON ard.id_analysis_req_det = ah.id_analysis_req_det
              LEFT JOIN analysis_result ar
                ON ar.id_analysis_req_det = ard.id_analysis_req_det
               AND ar.id_harvest = h.id_harvest
               AND ar.flg_status = pk_alert_constant.g_active
             WHERE h.id_harvest = i_harvest
             GROUP BY h.id_harvest, h.barcode, ard.barcode, h.dt_harvest_reg_tstz, ar.id_analysis_result;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_BARCODE',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_harvest);
            RETURN FALSE;
    END get_harvest_barcode;

    FUNCTION get_harvest_to_collect
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_harvest                     IN table_number,
        o_lab_test_order              OUT pk_types.cursor_type,
        o_lab_test_clinical_questions OUT pk_types.cursor_type,
        o_lab_test_harvest            OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_analysis_req_det table_number;
    
        TYPE t_code_messages IS TABLE OF VARCHAR2(1000 CHAR) INDEX BY sys_message.code_message%TYPE;
    
        aa_code_messages t_code_messages;
    
        va_code_messages table_varchar := table_varchar('LAB_TESTS_T045',
                                                        'LAB_TESTS_T012',
                                                        'LAB_TESTS_T048',
                                                        'LAB_TESTS_T033',
                                                        'LAB_TESTS_T241');
    
    BEGIN
    
        SELECT ah.id_analysis_req_det
          BULK COLLECT
          INTO l_analysis_req_det
          FROM analysis_harvest ah
         WHERE ah.id_harvest IN (SELECT /*+opt_estimate(table t rows=1)*/
                                  *
                                   FROM TABLE(i_harvest) t)
           AND ah.flg_status = pk_lab_tests_constant.g_active;
    
        g_error := 'GET MESSAGES';
        FOR i IN va_code_messages.first .. va_code_messages.last
        LOOP
            aa_code_messages(va_code_messages(i)) := '<b>' || pk_message.get_message(i_lang, va_code_messages(i)) ||
                                                     '</b> ';
        END LOOP;
    
        g_error := 'OPEN O_LAB_TEST_ORDER';
        OPEN o_lab_test_order FOR
            SELECT lte.id_analysis_req_det,
                   pk_date_utils.date_char_tsz(i_lang, lte.dt_req, i_prof.institution, i_prof.software) dt_reg,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, lte.id_prof_writes) prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, lte.id_prof_writes, lte.dt_req, lte.id_episode) prof_spec_reg,
                   aa_code_messages('LAB_TESTS_T045') ||
                   pk_lab_tests_utils.get_alias_translation(i_lang,
                                                            i_prof,
                                                            pk_lab_tests_constant.g_analysis_alias,
                                                            'ANALYSIS.CODE_ANALYSIS.' || lte.id_analysis,
                                                            'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' || lte.id_sample_type,
                                                            NULL) desc_analysis,
                   decode(pk_diagnosis.concat_diag(i_lang, NULL, lte.id_analysis_req_det, NULL, i_prof),
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T012') ||
                          pk_diagnosis.concat_diag(i_lang, NULL, lte.id_analysis_req_det, NULL, i_prof)) desc_diagnosis,
                   decode(lte.flg_priority,
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T048') ||
                          pk_sysdomain.get_domain(i_lang, i_prof, 'ANALYSIS_REQ_DET.FLG_URGENCY', lte.flg_priority, NULL)) priority,
                   decode(lte.notes_technician, NULL, NULL, aa_code_messages('LAB_TESTS_T033') || lte.notes_technician) notes,
                   decode(pk_lab_tests_utils.get_harvest_instructions(i_lang,
                                                                      i_prof,
                                                                      lte.id_analysis,
                                                                      lte.id_sample_type),
                          NULL,
                          NULL,
                          aa_code_messages('LAB_TESTS_T241') ||
                          pk_lab_tests_utils.get_harvest_instructions(i_lang,
                                                                      i_prof,
                                                                      lte.id_analysis,
                                                                      lte.id_sample_type)) harvest_instructions
              FROM harvest h, analysis_harvest ah, lab_tests_ea lte
             WHERE h.id_harvest IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(i_harvest) t)
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = lte.id_analysis_req_det;
    
        g_error := 'OPEN O_LAB_TEST_CLINICAL_QUESTIONS';
        OPEN o_lab_test_clinical_questions FOR
            SELECT id_analysis_req_det,
                   dt_reg,
                   prof_reg,
                   prof_spec_reg,
                   flg_time,
                   to_clob(listagg(desc_clinical_question, '') within GROUP(ORDER BY rank)) desc_clinical_question
              FROM (SELECT DISTINCT aqr.id_analysis_req_det,
                                    pk_date_utils.date_char_tsz(i_lang,
                                                                aqr.dt_last_update_tstz,
                                                                i_prof.institution,
                                                                i_prof.software) dt_reg,
                                    pk_prof_utils.get_name_signature(i_lang, i_prof, aqr.id_prof_last_update) prof_reg,
                                    pk_prof_utils.get_spec_signature(i_lang,
                                                                     i_prof,
                                                                     aqr.id_prof_last_update,
                                                                     aqr.dt_last_update_tstz,
                                                                     aqr.id_episode) prof_spec_reg,
                                    aqr1.flg_time,
                                    REPLACE(substr('<b>' ||
                                                   pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                   i_prof,
                                                                                   'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                   aqr1.id_questionnaire) || ':</b> ' ||
                                                   decode(aqr.notes,
                                                          NULL,
                                                          aqr1.desc_response,
                                                          pk_lab_tests_utils.get_lab_test_response(i_lang,
                                                                                                   i_prof,
                                                                                                   aqr.notes)) ||
                                                   chr(10),
                                                   1,
                                                   length('<b>' ||
                                                          pk_mcdt.get_questionnaire_alias(i_lang,
                                                                                          i_prof,
                                                                                          'QUESTIONNAIRE.CODE_QUESTIONNAIRE.' ||
                                                                                          aqr1.id_questionnaire) ||
                                                          ':</b> ' ||
                                                          decode(aqr.notes,
                                                                 NULL,
                                                                 aqr1.desc_response,
                                                                 pk_lab_tests_utils.get_lab_test_response(i_lang,
                                                                                                          i_prof,
                                                                                                          aqr.notes)) ||
                                                          chr(10)) - 1),
                                            ';',
                                            chr(10)) || chr(10) desc_clinical_question,
                                    pk_lab_tests_utils.get_lab_test_question_rank(i_lang,
                                                                                  i_prof,
                                                                                  ard.id_analysis,
                                                                                  ard.id_sample_type,
                                                                                  aqr1.id_questionnaire,
                                                                                  aqr1.flg_time) rank
                      FROM (SELECT aqr.id_analysis_req_det,
                                   aqr.id_questionnaire,
                                   decode(aqr.id_harvest,
                                          NULL,
                                          pk_lab_tests_constant.g_analysis_cq_on_order,
                                          pk_lab_tests_constant.g_analysis_cq_on_harvest) flg_time,
                                   decode(aqr.id_response,
                                          NULL,
                                          '---',
                                          listagg(pk_mcdt.get_response_alias(i_lang,
                                                                             i_prof,
                                                                             'RESPONSE.CODE_RESPONSE.' || aqr.id_response),
                                                  '; ') within GROUP(ORDER BY aqr.id_response)) desc_response
                              FROM analysis_question_response aqr
                             WHERE aqr.id_analysis_req_det IN
                                   (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(l_analysis_req_det) t)
                             GROUP BY aqr.id_analysis_req_det, aqr.id_harvest, aqr.id_questionnaire, aqr.id_response) aqr1,
                           analysis_question_response aqr,
                           analysis_req_det ard
                     WHERE aqr.id_analysis_req_det = aqr1.id_analysis_req_det
                       AND aqr.id_questionnaire = aqr1.id_questionnaire
                       AND aqr.id_analysis_req_det = ard.id_analysis_req_det)
             GROUP BY id_analysis_req_det, dt_reg, prof_reg, prof_spec_reg, flg_time
             ORDER BY dt_reg;
    
        g_error := 'OPEN O_LAB_TEST_HARVEST';
        OPEN o_lab_test_harvest FOR
            SELECT DISTINCT h.id_harvest,
                            h.id_body_part id_body_location,
                            h.flg_laterality flg_laterality,
                            pk_translation.get_translation(i_lang,
                                                           'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' || h.id_body_part) ||
                            decode(h.flg_laterality,
                                   NULL,
                                   NULL,
                                   ' - ' || pk_sysdomain.get_domain('HARVEST.FLG_LATERALITY', h.flg_laterality, i_lang)) desc_body_location,
                            h.flg_collection_method,
                            pk_sysdomain.get_domain(i_lang,
                                                    i_prof,
                                                    'HARVEST.FLG_COLLECTION_METHOD',
                                                    h.flg_collection_method,
                                                    NULL) collection_method,
                            h.id_specimen_condition,
                            pk_translation.get_translation(i_lang,
                                                           'ANALYSIS_SPECIMEN_CONDITION.CODE_SPECIMEN_CONDITION.' ||
                                                           h.id_specimen_condition) specimen_condition,
                            nvl(to_char(h.id_room_harvest), h.flg_col_inst) id_collection_location,
                            decode(h.id_room_harvest,
                                   NULL,
                                   pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_COL_INST', h.flg_col_inst, NULL),
                                   nvl((SELECT r.desc_room
                                         FROM room r
                                        WHERE r.id_room = h.id_room_harvest),
                                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_harvest))) collection_location,
                            decode(h.id_institution,
                                   i_prof.institution,
                                   pk_lab_tests_constant.g_arm_flg_type_room_tube,
                                   decode(h.id_institution, NULL, pk_lab_tests_constant.g_arm_flg_type_room_tube, 'E')) flg_type_lab,
                            decode(h.id_institution,
                                   i_prof.institution,
                                   h.id_room_receive_tube,
                                   decode(h.id_institution, NULL, h.id_room_receive_tube, h.id_institution)) id_laboratory,
                            decode(h.id_institution,
                                   i_prof.institution,
                                   nvl((SELECT r.desc_room
                                         FROM room r
                                        WHERE r.id_room = h.id_room_receive_tube),
                                       pk_translation.get_translation(i_lang, 'ROOM.CODE_ROOM.' || h.id_room_receive_tube)),
                                   decode(h.id_institution,
                                          NULL,
                                          nvl((SELECT r.desc_room
                                                FROM room r
                                               WHERE r.id_room = h.id_room_receive_tube),
                                              pk_translation.get_translation(i_lang,
                                                                             'ROOM.CODE_ROOM.' || h.id_room_receive_tube)),
                                          pk_translation.get_translation(i_lang,
                                                                         'AB_INSTITUTION.CODE_INSTITUTION.' ||
                                                                         h.id_institution))) desc_laboratory,
                            ah.id_sample_recipient,
                            pk_translation.get_translation(i_lang,
                                                           'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                           ah.id_sample_recipient) desc_recipient,
                            h.num_recipient,
                            h.amount collection_amount,
                            pk_translation.get_translation(i_lang,
                                                           'UNIT_MEASURE.CODE_UNIT_MEASURE.' ||
                                                           pk_lab_tests_utils.get_harvest_unit_measure(i_lang,
                                                                                                       i_prof,
                                                                                                       ah.id_sample_recipient)) unit_measure_amount,
                            h.flg_mov_tube,
                            pk_sysdomain.get_domain(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', h.flg_mov_tube, NULL) harvest_transportation,
                            h.notes,
                            decode(bpa.id_blood_product_analysis, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_revised
              FROM harvest h, analysis_harvest ah, blood_product_analysis bpa
             WHERE h.id_harvest IN (SELECT /*+opt_estimate(table t rows=1)*/
                                     *
                                      FROM TABLE(i_harvest) t)
               AND h.id_harvest = ah.id_harvest
               AND ah.id_analysis_req_det = bpa.id_analysis_req_det(+);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_TO_COLLECT',
                                              o_error);
            pk_types.open_my_cursor(o_lab_test_order);
            pk_types.open_my_cursor(o_lab_test_clinical_questions);
            pk_types.open_my_cursor(o_lab_test_harvest);
            RETURN FALSE;
    END get_harvest_to_collect;

    FUNCTION get_harvest_laboratory
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_coll_lab_room_instit t_coll_lab_room_instit := t_coll_lab_room_instit();
        l_obj_lab_room_instit  t_rec_lab_room_instit;
    
        l_lab_room_instit_src      pk_types.cursor_type;
        l_room_instit              tbl_temp.vc_1%TYPE;
        l_desc_room_instit         tbl_temp.vc_2%TYPE;
        l_institution_abbreviation tbl_temp.vc_3%TYPE;
        l_flg_type                 tbl_temp.vc_4%TYPE;
        l_rank                     tbl_temp.num_1%TYPE;
        l_flg_room_instit          tbl_temp.vc_5%TYPE;
        l_flg_default              tbl_temp.vc_6%TYPE;
        l_analysis_dummy           table_number;
        l_sample_type_dummy        table_number;
    
    BEGIN
    
        FOR l_analysis IN (SELECT /*+ opt_estimate(table t rows=1)*/
                            t.id_harvest,
                            CAST(COLLECT(to_number(t.id_analysis)) AS table_number) id_analysis,
                            CAST(COLLECT(to_number(t.id_sample_type)) AS table_number) id_sample_type
                             FROM TABLE(pk_lab_tests_harvest_core.tf_harvest_listview_base(i_lang, i_prof, i_episode)) t
                            WHERE t.id_harvest IN (SELECT /*+opt_estimate (table h rows=1)*/
                                                    *
                                                     FROM TABLE(i_harvest) h)
                            GROUP BY t.id_harvest)
        LOOP
            -- Laboratory (Room's and Institution's)
            g_error := 'CALL PK_LAB_TESTS_CORE.GET_LAB_TEST_LOCATION_LIST';
            IF NOT pk_lab_tests_core.get_lab_test_location_list(i_lang        => i_lang,
                                                                i_prof        => i_prof,
                                                                i_analysis    => l_analysis.id_analysis,
                                                                i_sample_type => l_analysis.id_sample_type,
                                                                i_flg_type    => NULL,
                                                                o_list        => l_lab_room_instit_src,
                                                                o_error       => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            LOOP
                FETCH l_lab_room_instit_src
                    INTO l_room_instit,
                         l_rank,
                         l_desc_room_instit,
                         l_flg_default,
                         l_flg_type,
                         l_analysis_dummy,
                         l_sample_type_dummy;
                EXIT WHEN l_lab_room_instit_src%NOTFOUND;
            
                l_coll_lab_room_instit.extend;
                l_obj_lab_room_instit := t_rec_lab_room_instit(l_analysis.id_harvest,
                                                               l_analysis.id_analysis,
                                                               l_room_instit,
                                                               l_desc_room_instit,
                                                               l_institution_abbreviation,
                                                               l_flg_type,
                                                               l_rank,
                                                               l_flg_room_instit,
                                                               l_flg_default);
            
                l_coll_lab_room_instit(l_coll_lab_room_instit.count) := l_obj_lab_room_instit;
            END LOOP;
        END LOOP;
    
        OPEN o_list FOR
            SELECT /*+ opt_estimate(table t rows=1)*/
             t.*
              FROM TABLE(l_coll_lab_room_instit) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_LABORATORY',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_laboratory;

    FUNCTION get_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_harvest IN table_number,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        OPEN o_list FOR
            SELECT /*+ opt_estimate(table t rows=1)*/
             id_harvest,
             CAST(COLLECT(to_number(id_sample_recipient)) AS table_number) id_sample_recipient,
             CAST(COLLECT((description)) AS table_varchar) desc_sample_recipient
              FROM TABLE(pk_lab_tests_harvest_core.tf_harvest_sample_recipient(i_lang,
                                                                               i_prof,
                                                                               (SELECT /*+ opt_estimate(table t rows=1)*/
                                                                                 CAST(COLLECT(to_number(t.id_harvest)) AS
                                                                                      table_number)
                                                                                  FROM TABLE(pk_lab_tests_harvest_core.tf_harvest_listview_base(i_lang,
                                                                                                                                                i_prof,
                                                                                                                                                i_episode)) t
                                                                                 WHERE t.id_harvest IN
                                                                                       (SELECT /*+opt_estimate (table h rows=1)*/
                                                                                         *
                                                                                          FROM TABLE(i_harvest) h)))) t
             GROUP BY id_harvest;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_SAMPLE_RECIPIENT',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_sample_recipient;

    FUNCTION get_harvest_barcode_for_print
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_harvest           IN table_number,
        o_printer           OUT VARCHAR2,
        o_codification_type OUT VARCHAR2,
        o_barcode           OUT VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_code    VARCHAR2(4000);
        l_barcode VARCHAR2(4000);
    
        l_hashmap pk_ia_external_info.tt_table_varchar;
    
    BEGIN
    
        g_error := 'GET PRINTER';
        SELECT t.cfg_type, t.cfg_printer, t.cfg_value
          INTO o_codification_type, o_printer, l_code
          FROM TABLE(pk_barcode.get_barcode_cfg_base(i_lang, i_prof, 'BARCODE_HARVEST')) t;
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            g_error := 'GET BARCODE CONFIG';
            IF pk_sysconfig.get_config('GENERATE_BARCODE_HARVEST', i_prof) = pk_lab_tests_constant.g_yes
            THEN
                g_error := 'HASHMAP PARAMETERS';
                l_hashmap('id_language') := table_varchar(to_char(i_lang));
                l_hashmap('id_harvest') := table_varchar(to_char(i_harvest(i)));
                l_hashmap('flg_type') := table_varchar('H');
            
                g_error := 'CALL TO PK_IA_EXTERNAL_INFO.GET_LAB_BARCODE';
                IF NOT pk_ia_external_info.get_lab_barcode(i_prof    => i_prof,
                                                           i_hashmap => l_hashmap,
                                                           o_barcode => l_barcode,
                                                           o_error   => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            
                o_barcode := o_barcode || l_barcode || chr(10);
            ELSE
                g_error   := 'CALL TO PK_LAB_TESTS_UTILS.GET_LAB_TEST_BARCODE';
                l_barcode := pk_lab_tests_utils.get_lab_test_barcode(i_lang         => i_lang,
                                                                     i_prof         => i_prof,
                                                                     i_analysis_req => NULL,
                                                                     i_harvest      => i_harvest(i),
                                                                     i_code         => l_code);
            
                o_barcode := o_barcode || l_barcode || chr(10);
            
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
                                              'GET_HARVEST_BARCODE_FOR_PRINT',
                                              o_error);
            RETURN FALSE;
    END get_harvest_barcode_for_print;

    FUNCTION get_harvest_order_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        CURSOR c_visit IS
            SELECT e.id_visit, e.id_epis_type
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_visit c_visit%ROWTYPE;
    
    BEGIN
    
        g_error := 'OPEN c_inst';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT h.id_harvest,
                   substr(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                               i_prof,
                                                                               pk_lab_tests_constant.g_analysis_alias,
                                                                               'ANALYSIS.CODE_ANALYSIS.' ||
                                                                               h.id_analysis,
                                                                               'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                               h.id_sample_type,
                                                                               NULL) || '; '),
                          1,
                          length(concatenate(pk_lab_tests_utils.get_alias_translation(i_lang,
                                                                                      i_prof,
                                                                                      pk_lab_tests_constant.g_analysis_alias,
                                                                                      'ANALYSIS.CODE_ANALYSIS.' ||
                                                                                      h.id_analysis,
                                                                                      'SAMPLE_TYPE.CODE_SAMPLE_TYPE.' ||
                                                                                      h.id_sample_type,
                                                                                      NULL) || '; ')) - 2) desc_analysis,
                   h.desc_body_location,
                   h.desc_recipient,
                   h.desc_room_destination,
                   MAX(h.rank) rank
              FROM (SELECT DISTINCT h.id_harvest,
                                    h.flg_status,
                                    lte.id_analysis,
                                    lte.id_sample_type,
                                    pk_translation.get_translation(i_lang,
                                                                   'BODY_STRUCTURE.CODE_BODY_STRUCTURE.' ||
                                                                   h.id_body_part) ||
                                    decode(h.flg_laterality,
                                           NULL,
                                           NULL,
                                           ' - ' ||
                                           pk_sysdomain.get_domain('HARVEST.FLG_LATERALITY', h.flg_laterality, i_lang)) desc_body_location,
                                    pk_translation.get_translation(i_lang,
                                                                   'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' ||
                                                                   ah.id_sample_recipient) desc_recipient,
                                    nvl((SELECT r.desc_room
                                          FROM room r
                                         WHERE r.id_room = h.id_room_receive_tube),
                                        pk_translation.get_translation(i_lang,
                                                                       'ROOM.CODE_ROOM.' || h.id_room_receive_tube)) desc_room_destination,
                                    decode(lte.flg_status_det,
                                           pk_lab_tests_constant.g_analysis_req,
                                           decode(h.dt_begin_harvest,
                                                  NULL,
                                                  row_number()
                                                  over(ORDER BY
                                                       pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                       coalesce(lte.dt_pend_req, lte.dt_target, lte.dt_req) DESC),
                                                  row_number()
                                                  over(ORDER BY
                                                       pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                       h.dt_begin_harvest)),
                                           row_number()
                                           over(ORDER BY
                                                pk_sysdomain.get_rank(i_lang, 'HARVEST.FLG_STATUS', h.flg_status),
                                                coalesce(h.dt_harvest_tstz,
                                                         h.dt_begin_harvest,
                                                         lte.dt_pend_req,
                                                         lte.dt_target,
                                                         lte.dt_req))) rank
                      FROM lab_tests_ea lte, harvest h, analysis_harvest ah
                     WHERE lte.id_visit = l_visit.id_visit
                       AND lte.flg_col_inst = pk_lab_tests_constant.g_yes
                       AND lte.id_analysis_req_det = ah.id_analysis_req_det
                       AND ah.id_harvest = h.id_harvest
                       AND h.flg_status = pk_lab_tests_constant.g_harvest_collected) h
             GROUP BY h.id_harvest, h.desc_body_location, h.desc_recipient, h.desc_room_destination
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_ORDER_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_order_list;

    FUNCTION get_harvest_method_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT val data, rank, desc_val label, NULL flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'HARVEST.FLG_COLLECTION_METHOD', NULL)) s
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_METHOD_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_method_list;

    FUNCTION get_harvest_transport_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'GET CURSOR';
        OPEN o_list FOR
            SELECT val data, rank, desc_val label, NULL flg_default
              FROM TABLE(pk_sysdomain.get_values_domain_pipelined(i_lang, i_prof, 'HARVEST.FLG_MOV_TUBE', NULL)) s
             ORDER BY rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_TRANSPORT_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_transport_list;

    FUNCTION get_harvest_reason_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'OPEN O_LIST';
        OPEN o_list FOR
            SELECT DISTINCT rcr.id_rep_coll_reason id_rep_coll_reason,
                            pk_translation.get_translation(i_lang, rcr.code_rep_coll_reason) rep_coll_reason_desc,
                            rcrd.rank
              FROM repeat_collection_reason rcr
              JOIN rep_collect_reason_dcs rcrd
                ON rcrd.id_rep_coll_reason = rcr.id_rep_coll_reason
             WHERE rcrd.id_institution IN (0, i_prof.institution)
               AND rcrd.id_software IN (0, i_prof.software)
               AND (rcrd.id_dep_clin_serv IS NULL OR
                   rcrd.id_dep_clin_serv IN
                   (SELECT pdcs.id_dep_clin_serv
                       FROM prof_dep_clin_serv pdcs
                      WHERE pdcs.id_professional = i_prof.id
                        AND pdcs.id_institution = i_prof.institution
                        AND pdcs.flg_status = pk_lab_tests_constant.g_selected))
               AND rcrd.flg_available = pk_alert_constant.g_yes
             ORDER BY rank ASC, rep_coll_reason_desc ASC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HARVEST_REASON_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_list);
            RETURN FALSE;
    END get_harvest_reason_list;

    FUNCTION tf_harvest_listview
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_harvest_listview IS
    
        l_harvest_combine_gap sys_config.value%TYPE := pk_sysconfig.get_config('HARVEST_COMBINE_GAP', i_prof);
    
        l_view_only_profile VARCHAR2(1 CHAR) := pk_prof_utils.check_has_functionality(i_lang,
                                                                                      i_prof,
                                                                                      'READ ONLY PROFILE');
    
        l_harvest_listview t_tbl_harvest_listview;
    
    BEGIN
    
        SELECT t_harvest_listview(t.id_harvest,
                                  t.id_analysis_harvest,
                                  t.id_analysis_req_det,
                                  t.id_analysis_req,
                                  t.id_analysis,
                                  t.id_sample_type,
                                  t.flg_status,
                                  t.harvest_num,
                                  t.flg_priority,
                                  t.id_sample_recipient,
                                  t.num_recipient,
                                  t.notes,
                                  t.id_body_location,
                                  t.flg_laterality,
                                  t.id_collection_location,
                                  t.flg_type_lab,
                                  t.id_laboratory,
                                  t.flg_clinical_question,
                                  t.min_dt_target,
                                  t.max_dt_target,
                                  t.avail_button_ok,
                                  t.avail_button_cancel,
                                  t.dt_target,
                                  t.dt_req,
                                  t.dt_pend_req,
                                  t.dt_begin_harvest,
                                  t.flg_time_harvest,
                                  t.rank,
                                  t.analysis_rank,
                                  t.harvest_rank)
          BULK COLLECT
          INTO l_harvest_listview
          FROM (SELECT h.id_harvest,
                       h.id_analysis_harvest,
                       h.id_analysis_req_det,
                       h.id_analysis_req,
                       h.id_analysis,
                       h.id_sample_type,
                       h.flg_status,
                       decode(COUNT(*) over(PARTITION BY h.id_analysis_req_det_min),
                              1,
                              to_char(dense_rank() over(ORDER BY h.min_dt_target, h.id_analysis_req_det_min)),
                              dense_rank()
                              over(ORDER BY h.min_dt_target, h.id_analysis_req_det_min) || '.' || row_number()
                              over(PARTITION BY h.min_dt_target, h.id_analysis_req_det_min ORDER BY rank)) harvest_num,
                       h.flg_priority,
                       h.id_sample_recipient,
                       h.num_recipient,
                       h.notes,
                       h.id_body_location,
                       h.flg_laterality,
                       h.id_collection_location,
                       h.flg_type_lab,
                       h.id_laboratory,
                       h.flg_clinical_question,
                       h.min_dt_target,
                       h.max_dt_target,
                       h.avail_button_ok,
                       h.avail_button_cancel,
                       h.rank,
                       dense_rank() over(ORDER BY h.min_dt_target, h.id_analysis_req_det_min) analysis_rank,
                       decode(COUNT(*) over(PARTITION BY h.id_analysis_req_det_min),
                              1,
                              0,
                              row_number() over(PARTITION BY h.min_dt_target, h.id_analysis_req_det_min ORDER BY rank)) harvest_rank,
                       h.dt_target,
                       h.dt_req,
                       h.dt_pend_req,
                       h.dt_begin_harvest,
                       h.flg_time_harvest
                  FROM (SELECT h.id_harvest,
                               CAST(COLLECT(to_number(h.id_analysis_harvest) ORDER BY h.dt_target, h.id_analysis_req_det) AS
                                    table_number) id_analysis_harvest,
                               CAST(COLLECT(to_number(h.id_analysis_req_det) ORDER BY h.dt_target, h.id_analysis_req_det) AS
                                    table_number) id_analysis_req_det,
                               CAST(COLLECT(to_number(h.id_analysis_req) ORDER BY h.dt_target, h.id_analysis_req_det) AS
                                    table_number) id_analysis_req,
                               CAST(COLLECT(to_number(h.id_analysis) ORDER BY h.dt_target, h.id_analysis_req_det) AS
                                    table_number) id_analysis,
                               CAST(COLLECT(to_number(h.id_sample_type) ORDER BY h.dt_target, h.id_analysis_req_det) AS
                                    table_number) id_sample_type,
                               MAX(h.flg_status) flg_status,
                               MIN(id_analysis_req_det) id_analysis_req_det_min,
                               MAX(h.flg_priority) flg_priority,
                               MAX(h.id_sample_recipient) id_sample_recipient,
                               MAX(h.num_recipient) num_recipient,
                               MAX(h.notes) notes,
                               MAX(h.id_body_location) id_body_location,
                               MAX(h.flg_laterality) flg_laterality,
                               MAX(h.id_collection_location) id_collection_location,
                               MAX(h.flg_type_lab) flg_type_lab,
                               MAX(h.id_laboratory) id_laboratory,
                               MAX(h.flg_clinical_question) flg_clinical_question,
                               nvl((MIN(h.dt_target) + numtodsinterval(-l_harvest_combine_gap, 'HOUR')),
                                   current_timestamp) min_dt_target,
                               nvl((MIN(h.dt_target) + numtodsinterval(l_harvest_combine_gap, 'HOUR')), current_timestamp) max_dt_target,
                               MAX(h.avail_button_ok) avail_button_ok,
                               MAX(h.avail_button_cancel) avail_button_cancel,
                               MAX(h.rank) rank,
                               MIN(h.dt_req) dt_req,
                               MIN(h.dt_pend_req) dt_pend_req,
                               MIN(h.dt_begin_harvest) dt_begin_harvest,
                               MIN(h.dt_target) dt_target,
                               MAX(h.flg_time_harvest) flg_time_harvest
                          FROM (SELECT /*+ opt_estimate(table t rows=1)*/
                                 t.id_harvest,
                                 t.id_analysis_harvest,
                                 t.id_analysis_req_det,
                                 t.id_analysis_req,
                                 t.id_analysis,
                                 t.id_sample_type,
                                 decode(t.id_rep_coll_reason, NULL, t.flg_status, pk_lab_tests_constant.g_harvest_repeated) flg_status,
                                 t.flg_priority,
                                 t.id_sample_recipient,
                                 t.num_recipient,
                                 t.notes,
                                 t.id_body_location,
                                 t.flg_laterality,
                                 t.id_collection_location,
                                 t.flg_type_lab,
                                 t.id_laboratory,
                                 decode(aq.id_analysis,
                                        NULL,
                                        pk_lab_tests_constant.g_no,
                                        decode((SELECT 1
                                                 FROM analysis_question_response aqr
                                                WHERE aqr.id_harvest = t.id_harvest
                                                  AND rownum = 1),
                                               1,
                                               pk_lab_tests_constant.g_no,
                                               pk_lab_tests_constant.g_yes)) flg_clinical_question,
                                 t.dt_target,
                                 decode(l_view_only_profile,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_no,
                                        decode(t.flg_status,
                                               pk_lab_tests_constant.g_harvest_waiting,
                                               pk_lab_tests_constant.g_no,
                                               pk_lab_tests_constant.g_harvest_cancel,
                                               pk_lab_tests_constant.g_no,
                                               pk_lab_tests_constant.g_harvest_rejected,
                                               pk_lab_tests_constant.g_no,
                                               pk_lab_tests_constant.g_harvest_repeated,
                                               pk_lab_tests_constant.g_no,
                                               decode(t.flg_status_det,
                                                      pk_lab_tests_constant.g_analysis_result,
                                                      decode((SELECT COUNT(1)
                                                               FROM analysis_harvest ah
                                                              WHERE ah.id_analysis_req_det = t.id_analysis_req_det),
                                                             1,
                                                             pk_lab_tests_constant.g_no,
                                                             decode(t.flg_status,
                                                                    pk_lab_tests_constant.g_harvest_pending,
                                                                    pk_lab_tests_constant.g_yes,
                                                                    pk_lab_tests_constant.g_no)),
                                                      pk_lab_tests_constant.g_analysis_read,
                                                      pk_lab_tests_constant.g_no,
                                                      pk_lab_tests_constant.g_yes))) avail_button_ok,
                                 decode(l_view_only_profile,
                                        pk_lab_tests_constant.g_yes,
                                        pk_lab_tests_constant.g_no,
                                        decode(t.flg_status_det,
                                               pk_lab_tests_constant.g_analysis_toexec,
                                               decode(t.flg_status,
                                                      pk_lab_tests_constant.g_harvest_collected,
                                                      pk_lab_tests_constant.g_yes,
                                                      pk_lab_tests_constant.g_harvest_transp,
                                                      pk_lab_tests_constant.g_yes,
                                                      pk_lab_tests_constant.g_no),
                                               pk_lab_tests_constant.g_no)) avail_button_cancel,
                                 row_number() over(ORDER BY t.id_harvest) rank,
                                 t.dt_req,
                                 t.dt_pend_req,
                                 t.dt_begin_harvest,
                                 t.flg_time_harvest
                                  FROM TABLE(pk_lab_tests_harvest_core.tf_harvest_listview_base(i_lang    => i_lang,
                                                                                                i_prof    => i_prof,
                                                                                                i_episode => i_episode)) t
                                  LEFT JOIN (SELECT DISTINCT aq.id_analysis, aq.id_sample_type
                                              FROM analysis_questionnaire aq
                                             WHERE aq.id_institution = i_prof.institution
                                               AND aq.flg_available = pk_lab_tests_constant.g_available
                                               AND aq.flg_time = pk_lab_tests_constant.g_analysis_cq_on_harvest
                                               AND EXISTS
                                             (SELECT /*+ no_unnest */
                                                     1
                                                      FROM questionnaire q
                                                     WHERE q.id_questionnaire = aq.id_questionnaire
                                                       AND q.flg_available = pk_lab_tests_constant.g_available)) aq
                                    ON t.id_analysis = aq.id_analysis
                                   AND t.id_sample_type = aq.id_sample_type) h
                         GROUP BY id_harvest) h) t;
    
        RETURN l_harvest_listview;
    
    END tf_harvest_listview;

    FUNCTION tf_harvest_listview_base
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_harvest_listview_base IS
    
        CURSOR c_visit IS
            SELECT e.id_visit
              FROM episode e
             WHERE e.id_episode = i_episode;
    
        l_visit visit.id_visit%TYPE;
    
        l_harvest_listview_base t_tbl_harvest_listview_base;
    
    BEGIN
    
        g_error := 'OPEN C_VISIT';
        OPEN c_visit;
        FETCH c_visit
            INTO l_visit;
        CLOSE c_visit;
    
        SELECT t_harvest_listview_base(t.id_harvest,
                                       t.id_analysis_harvest,
                                       t.id_analysis_req_det,
                                       t.id_analysis_req,
                                       t.id_analysis,
                                       t.id_sample_type,
                                       t.flg_status,
                                       t.flg_status_det,
                                       t.flg_priority,
                                       t.id_sample_recipient,
                                       t.num_recipient,
                                       t.notes,
                                       t.id_body_location,
                                       t.flg_laterality,
                                       t.id_collection_location,
                                       t.flg_type_lab,
                                       t.id_laboratory,
                                       t.dt_target,
                                       t.dt_req,
                                       t.dt_pend_req,
                                       t.dt_begin_harvest,
                                       t.flg_time_harvest,
                                       t.id_rep_coll_reason,
                                       t.rank)
          BULK COLLECT
          INTO l_harvest_listview_base
          FROM (SELECT h.id_harvest,
                       h.id_analysis_harvest,
                       h.id_analysis_req_det,
                       h.id_analysis_req,
                       h.id_analysis,
                       h.id_sample_type,
                       h.flg_status,
                       h.flg_status_det,
                       h.flg_priority,
                       h.id_sample_recipient,
                       h.num_recipient,
                       h.notes,
                       h.id_body_location,
                       h.flg_laterality,
                       h.id_collection_location,
                       h.flg_type_lab,
                       h.id_laboratory,
                       h.dt_target,
                       h.flg_time_harvest,
                       h.dt_req,
                       h.dt_pend_req,
                       h.dt_begin_harvest,
                       h.id_rep_coll_reason,
                       h.rank
                  FROM (SELECT h.id_harvest,
                               ah.id_analysis_harvest,
                               lte.id_analysis_req_det,
                               lte.id_analysis_req,
                               lte.id_analysis,
                               lte.id_sample_type,
                               decode(h.id_rep_coll_reason, NULL, h.flg_status, pk_lab_tests_constant.g_harvest_repeated) flg_status,
                               lte.flg_status_det,
                               lte.flg_priority,
                               ah.id_sample_recipient,
                               h.num_recipient,
                               h.notes,
                               h.id_body_part id_body_location,
                               h.flg_laterality flg_laterality,
                               nvl(to_char(h.id_room_harvest), h.flg_col_inst) id_collection_location,
                               decode(h.id_institution,
                                      i_prof.institution,
                                      pk_lab_tests_constant.g_arm_flg_type_room_tube,
                                      decode(h.id_institution, NULL, pk_lab_tests_constant.g_arm_flg_type_room_tube, 'E')) flg_type_lab,
                               decode(h.id_institution,
                                      i_prof.institution,
                                      h.id_room_receive_tube,
                                      decode(h.id_institution, NULL, h.id_room_receive_tube, h.id_institution)) id_laboratory,
                               lte.dt_target,
                               lte.flg_time_harvest,
                               lte.dt_req,
                               lte.dt_pend_req,
                               h.dt_begin_harvest,
                               h.id_rep_coll_reason,
                               row_number() over(ORDER BY h.id_harvest) rank
                          FROM lab_tests_ea lte
                         INNER JOIN analysis_harvest ah
                            ON lte.id_analysis_req_det = ah.id_analysis_req_det
                         INNER JOIN harvest h
                            ON h.id_harvest = ah.id_harvest
                         WHERE lte.id_visit = l_visit
                           AND (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_e OR
                               (lte.flg_time_harvest IN
                               (pk_lab_tests_constant.g_flg_time_b, pk_lab_tests_constant.g_flg_time_d) AND
                               pk_date_utils.trunc_insttimezone(i_prof, lte.dt_target, NULL) =
                               pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL)) OR
                               (lte.flg_time_harvest = pk_lab_tests_constant.g_flg_time_n AND lte.id_episode IS NOT NULL))
                           AND (lte.flg_orig_analysis IS NULL OR lte.flg_orig_analysis NOT IN ('M', 'O', 'S'))
                           AND lte.flg_col_inst = pk_lab_tests_constant.g_yes
                           AND lte.flg_status_det NOT IN
                               (pk_lab_tests_constant.g_analysis_draft, pk_lab_tests_constant.g_analysis_wtg_tde)
                           AND (lte.flg_referral IS NULL OR lte.flg_referral = pk_lab_tests_constant.g_flg_referral_a OR
                               lte.flg_referral = pk_lab_tests_constant.g_flg_referral_r)
                           AND ((ah.flg_status = pk_lab_tests_constant.g_active) OR
                               (ah.flg_status = pk_lab_tests_constant.g_inactive AND
                               h.flg_status IN
                               (pk_lab_tests_constant.g_harvest_cancel, pk_lab_tests_constant.g_harvest_rejected)))
                           AND h.flg_status NOT IN
                               (pk_lab_tests_constant.g_harvest_suspended, pk_lab_tests_constant.g_harvest_inactive)
                           AND (SELECT pk_lab_tests_utils.get_lab_test_access_permission(i_lang, i_prof, lte.id_analysis)
                                  FROM dual) = pk_alert_constant.g_yes) h) t;
    
        RETURN l_harvest_listview_base;
    
    END tf_harvest_listview_base;

    FUNCTION tf_harvest_sample_recipient
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_harvest IN table_number
    ) RETURN t_tbl_harvest_sample_recipient IS
    
        CURSOR c_id_analysis_instit_soft(l_harvest harvest.id_harvest%TYPE) IS
            SELECT /*+ opt_estimate(table t rows=1)*/
             ais.id_analysis_instit_soft
              FROM analysis_harvest ah, analysis_req_det ard, analysis_instit_soft ais
             WHERE ah.id_harvest = l_harvest
               AND ah.id_analysis_req_det = ard.id_analysis_req_det
               AND ard.id_analysis = ais.id_analysis
               AND ard.id_sample_type = ais.id_sample_type
               AND ais.flg_available = pk_lab_tests_constant.g_available
               AND ais.id_institution = i_prof.institution
               AND ais.id_software = i_prof.software;
    
        CURSOR c_sample_recipient(l_analysis_instit_soft analysis_instit_soft.id_analysis_instit_soft%TYPE) IS
            SELECT /*+ opt_estimate(table t rows=1)*/
             id_sample_recipient,
             pk_translation.get_translation(i_lang,
                                            'SAMPLE_RECIPIENT.CODE_SAMPLE_RECIPIENT.' || air.id_sample_recipient) desc_sample_recipient
              FROM analysis_instit_recipient air
             WHERE air.id_analysis_instit_soft = l_analysis_instit_soft;
    
        l_tbl_harvest_sample_recipient t_tbl_harvest_sample_recipient := t_tbl_harvest_sample_recipient();
    
        l_id_sample_recipient   table_number := table_number();
        l_sample_recipient_desc table_varchar := table_varchar();
    
        l_id_sample_recipient_aux   table_number := table_number();
        l_sample_recipient_desc_aux table_varchar := table_varchar();
    
        l_harvest              table_number := table_number();
        l_analysis_instit_soft table_number := table_number();
    
    BEGIN
    
        FOR i IN 1 .. i_harvest.count
        LOOP
            OPEN c_id_analysis_instit_soft(i_harvest(i));
            FETCH c_id_analysis_instit_soft BULK COLLECT
                INTO l_analysis_instit_soft;
            CLOSE c_id_analysis_instit_soft;
        
            FOR i IN 1 .. l_analysis_instit_soft.count
            LOOP
                l_id_sample_recipient_aux   := table_number();
                l_sample_recipient_desc_aux := table_varchar();
                l_harvest                   := table_number();
            
                OPEN c_sample_recipient(l_analysis_instit_soft(i));
            
                FETCH c_sample_recipient BULK COLLECT
                    INTO l_id_sample_recipient_aux, l_sample_recipient_desc_aux;
                CLOSE c_sample_recipient;
            
                IF i = 1
                THEN
                    l_id_sample_recipient   := l_id_sample_recipient_aux;
                    l_sample_recipient_desc := l_sample_recipient_desc_aux;
                END IF;
            
                l_id_sample_recipient   := l_id_sample_recipient MULTISET INTERSECT l_id_sample_recipient_aux;
                l_sample_recipient_desc := l_sample_recipient_desc MULTISET INTERSECT l_sample_recipient_desc_aux;
            END LOOP;
        
            FOR j IN 1 .. l_id_sample_recipient.count
            LOOP
                l_tbl_harvest_sample_recipient.extend;
                l_harvest.extend(l_id_sample_recipient.count);
                l_harvest(j) := i_harvest(i);
            
                l_tbl_harvest_sample_recipient(l_tbl_harvest_sample_recipient.last) := t_harvest_sample_recipient(l_id_sample_recipient(j),
                                                                                                                  l_sample_recipient_desc(j),
                                                                                                                  l_harvest(j));
            END LOOP;
        END LOOP;
    
        RETURN l_tbl_harvest_sample_recipient;
    
    END tf_harvest_sample_recipient;

    PROCEDURE init_params_lt_movement
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_patient          CONSTANT NUMBER(24) := 5;
        g_episode          CONSTANT NUMBER(24) := 6;
    
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_id_visit visit.id_visit%TYPE;
        o_error    t_error_out;
    BEGIN
    
        l_id_visit := pk_episode.get_id_visit(i_episode => i_context_ids(g_episode));
    
        pk_context_api.set_parameter('l_lang', l_lang);
        pk_context_api.set_parameter('l_prof_id', l_prof.id);
        pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
        pk_context_api.set_parameter('l_prof_software', l_prof.software);
        pk_context_api.set_parameter('l_id_visit', l_id_visit);
    
        CASE i_name
            WHEN 'l_lang' THEN
                o_num := l_lang;
            WHEN 'l_view_only_profile' THEN
                o_vc2 := pk_prof_utils.check_has_functionality(l_lang, l_prof, 'READ ONLY PROFILE');
            WHEN 'l_prof_cat_type' THEN
                o_vc2 := pk_prof_utils.get_category(l_lang, l_prof);
            WHEN 'l_nurse_permission' THEN
                o_vc2 := pk_sysconfig.get_config('FLG_NURSE_FINISH_TRANSP', l_prof);
            WHEN 'l_ancillary_permission' THEN
                o_vc2 := pk_sysconfig.get_config('FLG_AUX_FINISH_TRANSP', l_prof);
            ELSE
                NULL;
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_LAB_TESTS_HARVEST_CORE',
                                              i_function => 'INIT_PARAMS_LT_MOVEMENT',
                                              o_error    => o_error);
    END init_params_lt_movement;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_lab_tests_harvest_core;
/
