/*-- Last Change Revision: $Rev: 2027030 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:46 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_ea_logic_grids IS

    -- Private global variables declaration
    g_current_timestamp TIMESTAMP(6) WITH LOCAL TIME ZONE;

    g_prof_category category.flg_type%TYPE;

    -- Private function and procedure implementations
    FUNCTION upsert_on_grids_ea
    (
        i_lang             IN language.id_language%TYPE,
        i_grids_ea_records IN ts_grids_ea.grids_ea_tc,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'UPSERT_ON_GRIDS_EA';
    
        l_rows table_varchar;
    
    BEGIN
    
        FOR i IN i_grids_ea_records.first .. i_grids_ea_records.last
        LOOP
            ts_grids_ea.upd(id_episode_in               => i_grids_ea_records(i).id_episode,
                            id_visit_in                 => i_grids_ea_records(i).id_visit,
                            id_clinical_service_in      => i_grids_ea_records(i).id_clinical_service,
                            episode_flg_status_in       => i_grids_ea_records(i).episode_flg_status,
                            id_epis_type_in             => i_grids_ea_records(i).id_epis_type,
                            barcode_in                  => i_grids_ea_records(i).barcode,
                            id_prof_cancel_in           => i_grids_ea_records(i).id_prof_cancel,
                            flg_type_in                 => i_grids_ea_records(i).flg_type,
                            id_prev_episode_in          => i_grids_ea_records(i).id_prev_episode,
                            dt_begin_tstz_in            => i_grids_ea_records(i).dt_begin_tstz,
                            dt_end_tstz_in              => i_grids_ea_records(i).dt_end_tstz,
                            dt_cancel_tstz_in           => i_grids_ea_records(i).dt_cancel_tstz,
                            id_fast_track_in            => i_grids_ea_records(i).id_fast_track,
                            flg_ehr_in                  => i_grids_ea_records(i).flg_ehr,
                            id_patient_in               => i_grids_ea_records(i).id_patient,
                            id_department_in            => i_grids_ea_records(i).id_department,
                            id_institution_in           => i_grids_ea_records(i).id_institution,
                            id_bed_in                   => i_grids_ea_records(i).id_bed,
                            id_room_in                  => i_grids_ea_records(i).id_room,
                            id_professional_in          => i_grids_ea_records(i).id_professional,
                            norton_in                   => i_grids_ea_records(i).norton,
                            flg_hydric_in               => i_grids_ea_records(i).flg_hydric,
                            flg_wound_in                => i_grids_ea_records(i).flg_wound,
                            epis_info_companion_in      => i_grids_ea_records(i).epis_info_companion,
                            flg_unknown_in              => i_grids_ea_records(i).flg_unknown,
                            desc_info_in                => i_grids_ea_records(i).desc_info,
                            id_schedule_in              => i_grids_ea_records(i).id_schedule,
                            id_first_nurse_resp_in      => i_grids_ea_records(i).id_first_nurse_resp,
                            epis_info_flg_status_in     => i_grids_ea_records(i).epis_info_flg_status,
                            id_dep_clin_serv_in         => i_grids_ea_records(i).id_dep_clin_serv,
                            id_first_dep_clin_serv_in   => i_grids_ea_records(i).id_first_dep_clin_serv,
                            dt_first_obs_tstz_in        => i_grids_ea_records(i).dt_first_obs_tstz,
                            dt_first_nurse_obs_tstz_in  => i_grids_ea_records(i).dt_first_nurse_obs_tstz,
                            triage_acuity_in            => i_grids_ea_records(i).triage_acuity,
                            triage_color_text_in        => i_grids_ea_records(i).triage_color_text,
                            triage_rank_acuity_in       => i_grids_ea_records(i).triage_rank_acuity,
                            triage_flg_letter_in        => i_grids_ea_records(i).triage_flg_letter,
                            id_triage_color_in          => i_grids_ea_records(i).id_triage_color,
                            id_software_in              => i_grids_ea_records(i).id_software,
                            episode_companion_in        => i_grids_ea_records(i).episode_companion,
                            dt_first_inst_obs_tstz_in   => i_grids_ea_records(i).dt_first_inst_obs_tstz,
                            dt_dg_last_update_in        => g_current_timestamp,
                            id_announced_arrival_in     => i_grids_ea_records(i).id_announced_arrival,
                            flg_has_stripes_in          => i_grids_ea_records(i).flg_has_stripes,
                            id_fast_track_er_law_in     => i_grids_ea_records(i).id_fast_track_er_law,
                            flg_has_transfer_in         => i_grids_ea_records(i).flg_has_transfer,
                            id_visit_nin                => FALSE,
                            id_clinical_service_nin     => FALSE,
                            episode_flg_status_nin      => FALSE,
                            id_epis_type_nin            => FALSE,
                            barcode_nin                 => FALSE,
                            id_prof_cancel_nin          => FALSE,
                            flg_type_nin                => FALSE,
                            id_prev_episode_nin         => FALSE,
                            dt_begin_tstz_nin           => FALSE,
                            dt_end_tstz_nin             => FALSE,
                            dt_cancel_tstz_nin          => FALSE,
                            id_fast_track_nin           => FALSE,
                            flg_ehr_nin                 => FALSE,
                            id_patient_nin              => FALSE,
                            id_department_nin           => FALSE,
                            id_institution_nin          => FALSE,
                            id_bed_nin                  => FALSE,
                            id_room_nin                 => FALSE,
                            id_professional_nin         => FALSE,
                            norton_nin                  => FALSE,
                            flg_hydric_nin              => FALSE,
                            flg_wound_nin               => FALSE,
                            epis_info_companion_nin     => FALSE,
                            flg_unknown_nin             => FALSE,
                            desc_info_nin               => FALSE,
                            id_schedule_nin             => FALSE,
                            id_first_nurse_resp_nin     => FALSE,
                            epis_info_flg_status_nin    => FALSE,
                            id_dep_clin_serv_nin        => FALSE,
                            id_first_dep_clin_serv_nin  => FALSE,
                            dt_first_obs_tstz_nin       => FALSE,
                            dt_first_nurse_obs_tstz_nin => FALSE,
                            triage_acuity_nin           => FALSE,
                            triage_color_text_nin       => FALSE,
                            triage_rank_acuity_nin      => FALSE,
                            triage_flg_letter_nin       => FALSE,
                            id_triage_color_nin         => FALSE,
                            id_software_nin             => FALSE,
                            episode_companion_nin       => FALSE,
                            dt_first_inst_obs_tstz_nin  => FALSE,
                            dt_dg_last_update_nin       => FALSE,
                            id_announced_arrival_nin    => FALSE,
                            flg_has_stripes_nin         => TRUE, -- Keep previous value if NULL is sent
                            id_fast_track_er_law_nin    => FALSE,
                            flg_has_transfer_nin        => FALSE,
                            rows_out                    => l_rows);
        
            IF (NOT l_rows.exists(1))
               OR (l_rows.count = 0)
            THEN
                ts_grids_ea.ins(id_episode_in              => i_grids_ea_records(i).id_episode,
                                id_visit_in                => i_grids_ea_records(i).id_visit,
                                id_clinical_service_in     => i_grids_ea_records(i).id_clinical_service,
                                episode_flg_status_in      => i_grids_ea_records(i).episode_flg_status,
                                id_epis_type_in            => i_grids_ea_records(i).id_epis_type,
                                barcode_in                 => i_grids_ea_records(i).barcode,
                                id_prof_cancel_in          => i_grids_ea_records(i).id_prof_cancel,
                                flg_type_in                => i_grids_ea_records(i).flg_type,
                                id_prev_episode_in         => i_grids_ea_records(i).id_prev_episode,
                                dt_begin_tstz_in           => i_grids_ea_records(i).dt_begin_tstz,
                                dt_end_tstz_in             => i_grids_ea_records(i).dt_end_tstz,
                                dt_cancel_tstz_in          => i_grids_ea_records(i).dt_cancel_tstz,
                                id_fast_track_in           => i_grids_ea_records(i).id_fast_track,
                                flg_ehr_in                 => i_grids_ea_records(i).flg_ehr,
                                id_patient_in              => i_grids_ea_records(i).id_patient,
                                id_department_in           => i_grids_ea_records(i).id_department,
                                id_institution_in          => i_grids_ea_records(i).id_institution,
                                id_bed_in                  => i_grids_ea_records(i).id_bed,
                                id_room_in                 => i_grids_ea_records(i).id_room,
                                id_professional_in         => i_grids_ea_records(i).id_professional,
                                norton_in                  => i_grids_ea_records(i).norton,
                                flg_hydric_in              => i_grids_ea_records(i).flg_hydric,
                                flg_wound_in               => i_grids_ea_records(i).flg_wound,
                                epis_info_companion_in     => i_grids_ea_records(i).epis_info_companion,
                                flg_unknown_in             => i_grids_ea_records(i).flg_unknown,
                                desc_info_in               => i_grids_ea_records(i).desc_info,
                                id_schedule_in             => i_grids_ea_records(i).id_schedule,
                                id_first_nurse_resp_in     => i_grids_ea_records(i).id_first_nurse_resp,
                                epis_info_flg_status_in    => i_grids_ea_records(i).epis_info_flg_status,
                                id_dep_clin_serv_in        => i_grids_ea_records(i).id_dep_clin_serv,
                                id_first_dep_clin_serv_in  => i_grids_ea_records(i).id_first_dep_clin_serv,
                                dt_first_obs_tstz_in       => i_grids_ea_records(i).dt_first_obs_tstz,
                                dt_first_nurse_obs_tstz_in => i_grids_ea_records(i).dt_first_nurse_obs_tstz,
                                triage_acuity_in           => i_grids_ea_records(i).triage_acuity,
                                triage_color_text_in       => i_grids_ea_records(i).triage_color_text,
                                triage_rank_acuity_in      => i_grids_ea_records(i).triage_rank_acuity,
                                triage_flg_letter_in       => i_grids_ea_records(i).triage_flg_letter,
                                id_triage_color_in         => i_grids_ea_records(i).id_triage_color,
                                id_software_in             => i_grids_ea_records(i).id_software,
                                episode_companion_in       => i_grids_ea_records(i).episode_companion,
                                dt_first_inst_obs_tstz_in  => i_grids_ea_records(i).dt_first_inst_obs_tstz,
                                dt_dg_last_update_in       => g_current_timestamp,
                                id_announced_arrival_in    => i_grids_ea_records(i).id_announced_arrival,
                                flg_has_stripes_in         => CASE i_grids_ea_records(i).dt_first_obs_tstz
                                                                  WHEN NULL THEN
                                                                   pk_alert_constant.g_yes
                                                                  ELSE
                                                                   pk_alert_constant.g_no
                                                              END,
                                id_fast_track_er_law_in    => i_grids_ea_records(i).id_fast_track_er_law,
                                flg_has_transfer_in        => i_grids_ea_records(i).flg_has_transfer);
            END IF;
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END upsert_on_grids_ea;

    FUNCTION insert_valid_from_episode
    (
        i_lang   IN language.id_language%TYPE,
        i_rowids IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_grids_ea_records ts_grids_ea.grids_ea_tc;
    
        l_function_name CONSTANT VARCHAR2(30) := 'INSERT_VALID_FROM_EPISODE';
    
        e_exception EXCEPTION;
    
    BEGIN
    
        IF i_rowids.exists(1)
           AND i_rowids.count > 0
        THEN
            g_error := 'SELECT EPISODE ROWIDS';
            SELECT /*+rule*/
             epis.id_episode,
             epis.id_visit,
             epis.id_clinical_service,
             epis.flg_status episode_flg_status,
             epis.id_epis_type,
             epis.companion episode_companion,
             epis.barcode,
             epis.id_prof_cancel,
             epis.flg_type,
             epis.id_prev_episode,
             epis.dt_begin_tstz,
             epis.dt_end_tstz,
             epis.dt_cancel_tstz,
             epis.id_fast_track,
             epis.flg_ehr,
             epis.id_patient,
             epis.id_department,
             epis.id_institution,
             ei.id_bed,
             ei.id_room,
             ei.id_professional,
             ei.norton,
             ei.flg_hydric,
             ei.flg_wound,
             ei.companion epis_info_companion,
             ei.flg_unknown,
             ei.desc_info,
             ei.id_schedule,
             ei.id_first_nurse_resp,
             ei.flg_status epis_info_flg_status,
             ei.id_dep_clin_serv,
             ei.id_first_dep_clin_serv,
             ei.dt_first_obs_tstz,
             ei.dt_first_nurse_obs_tstz,
             ei.dt_first_inst_obs_tstz,
             ei.triage_acuity,
             ei.triage_color_text,
             ei.triage_rank_acuity,
             ei.triage_flg_letter,
             ei.id_triage_color,
             ei.id_software,
             '' create_user,
             '' create_time,
             '' create_institution,
             '' update_user,
             '' update_time,
             '' update_institution,
             g_current_timestamp,
             pk_announced_arrival.get_ann_arrival_id(epis.id_institution,
                                                     ei.id_software,
                                                     epis.id_episode,
                                                     ei.flg_unknown) id_announced_arrival,
             -- "NULL" if 1st observation date is filled in, will keep the previous value in "flg_has_stripes".
             nvl2(ei.dt_first_obs_tstz, NULL, pk_alert_constant.g_yes) flg_has_stripes,
             decode(epis.id_fast_track,
                    NULL,
                    pk_epis_er_law_api.get_fast_track_id(epis.id_episode, epis.id_fast_track),
                    NULL) id_fast_track_er_law,
             pk_transfer_institution.check_epis_transfer(epis.id_episode) flg_has_transfer
              BULK COLLECT
              INTO l_grids_ea_records
              FROM episode epis
              JOIN epis_info ei
                ON (epis.id_episode = ei.id_episode)
             WHERE epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
               AND epis.flg_ehr != 'E'
               AND epis.rowid IN (SELECT column_value
                                    FROM TABLE(i_rowids));
        
            IF l_grids_ea_records.exists(1)
            THEN
                IF NOT
                    upsert_on_grids_ea(i_lang => i_lang, i_grids_ea_records => l_grids_ea_records, o_error => o_error)
                THEN
                    RAISE e_exception;
                END IF;
            END IF;
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END insert_valid_from_episode;

    FUNCTION delete_from_idepisode
    (
        i_lang       IN language.id_language%TYPE,
        i_idepisodes IN table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'DELETE_FROM_IDEPISODE';
    
    BEGIN
    
        IF i_idepisodes.exists(1)
        THEN
            FOR i IN i_idepisodes.first .. i_idepisodes.last
            LOOP
                ts_grids_ea.del(id_episode_in => i_idepisodes(i));
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END delete_from_idepisode;

    FUNCTION filter_episodes_to_delete
    (
        i_lang                 IN language.id_language%TYPE,
        i_rowids               IN table_varchar,
        o_rowids_to_delete     OUT table_varchar,
        o_idepisodes_to_delete OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'FILTER_EPISODES_TO_DELETE';
    
    BEGIN
    
        o_idepisodes_to_delete := table_number();
        o_rowids_to_delete     := table_varchar();
    
        SELECT /*+RULE*/
         epis.id_episode, epis.rowid
          BULK COLLECT
          INTO o_idepisodes_to_delete, o_rowids_to_delete
          FROM episode epis
          JOIN epis_info ei
            ON (epis.id_episode = ei.id_episode)
          JOIN grids_ea gea
            ON (gea.id_episode = epis.id_episode)
         WHERE epis.rowid IN (SELECT column_value
                                FROM TABLE(i_rowids))
           AND (epis.flg_status NOT IN (pk_alert_constant.g_active, pk_alert_constant.g_pending) OR epis.flg_ehr = 'E');
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END filter_episodes_to_delete;

    FUNCTION insert_valid_from_epis_info
    (
        i_lang   IN language.id_language%TYPE,
        i_rowids IN table_varchar,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'INSERT_VALID_FROM_EPIS_INFO';
    
        l_grids_ea_records ts_grids_ea.grids_ea_tc;
    
        e_exception EXCEPTION;
    
    BEGIN
    
        IF i_rowids.exists(1)
           AND i_rowids.count > 0
        THEN
        
            g_error := 'SELECT EPIS_INFO ROWIDS';
            SELECT /*+rule*/
             epis.id_episode,
             epis.id_visit,
             epis.id_clinical_service,
             epis.flg_status episode_flg_status,
             epis.id_epis_type,
             epis.companion episode_companion,
             epis.barcode,
             epis.id_prof_cancel,
             epis.flg_type,
             epis.id_prev_episode,
             epis.dt_begin_tstz,
             epis.dt_end_tstz,
             epis.dt_cancel_tstz,
             epis.id_fast_track,
             epis.flg_ehr,
             epis.id_patient,
             epis.id_department,
             epis.id_institution,
             ei.id_bed,
             ei.id_room,
             ei.id_professional,
             ei.norton,
             ei.flg_hydric,
             ei.flg_wound,
             ei.companion epis_info_companion,
             ei.flg_unknown,
             ei.desc_info,
             ei.id_schedule,
             ei.id_first_nurse_resp,
             ei.flg_status epis_info_flg_status,
             ei.id_dep_clin_serv,
             ei.id_first_dep_clin_serv,
             ei.dt_first_obs_tstz,
             ei.dt_first_nurse_obs_tstz,
             ei.dt_first_inst_obs_tstz,
             ei.triage_acuity,
             ei.triage_color_text,
             ei.triage_rank_acuity,
             ei.triage_flg_letter,
             ei.id_triage_color,
             ei.id_software,
             '' create_user,
             '' create_time,
             '' create_institution,
             '' update_user,
             '' update_time,
             '' update_institution,
             g_current_timestamp,
             pk_announced_arrival.get_ann_arrival_id(epis.id_institution,
                                                     ei.id_software,
                                                     epis.id_episode,
                                                     ei.flg_unknown) id_announced_arrival,
             -- Value of "flg_has_stripes" changes to "N" only if professional category is allowed to update DT_FIRST_OBS
             -- and if DT_FIRST_OBS is not null.
             decode((SELECT COUNT(*)
                      FROM dual
                     WHERE (pk_visit.check_first_obs_category(i_lang, g_prof_category) = pk_alert_constant.g_yes OR
                           (ei.flg_dsch_status = 'R' AND
                           pk_transfer_institution.check_epis_transfer(ei.id_episode) = 0))
                       AND ei.dt_first_obs_tstz IS NOT NULL),
                    1,
                    pk_alert_constant.g_no,
                    -- Check if DT_FIRST_OBS was cleared (e.g. when cancelling episode responsability).
                    -- Otherwise, send "NULL" to keep previous value.
                    decode((SELECT COUNT(*)
                             FROM dual
                            WHERE ei.dt_first_obs_tstz IS NULL),
                           1,
                           pk_alert_constant.g_yes,
                           NULL)) flg_has_stripes,
             decode(epis.id_fast_track,
                    NULL,
                    pk_epis_er_law_api.get_fast_track_id(epis.id_episode, epis.id_fast_track),
                    NULL) id_fast_track_er_law,
             pk_transfer_institution.check_epis_transfer(epis.id_episode) flg_has_transfer
              BULK COLLECT
              INTO l_grids_ea_records
              FROM episode epis
              JOIN epis_info ei
                ON (epis.id_episode = ei.id_episode)
             WHERE epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
               AND epis.flg_ehr != 'E'
               AND ei.rowid IN (SELECT column_value
                                  FROM TABLE(i_rowids));
        
            IF l_grids_ea_records.exists(1)
            THEN
                IF NOT
                    upsert_on_grids_ea(i_lang => i_lang, i_grids_ea_records => l_grids_ea_records, o_error => o_error)
                THEN
                    RAISE e_exception;
                END IF;
            END IF;
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
    END insert_valid_from_epis_info;

    FUNCTION filter_epis_info_to_delete
    (
        i_lang                 IN language.id_language%TYPE,
        i_rowids               IN table_varchar,
        o_rowids_to_delete     OUT table_varchar,
        o_idepisodes_to_delete OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'FILTER_EPISODES_TO_DELETE';
    
    BEGIN
    
        o_idepisodes_to_delete := table_number();
        o_rowids_to_delete     := table_varchar();
    
        IF i_rowids.exists(1)
           AND i_rowids.count > 0
        THEN
            SELECT /*+rule*/
             epis.id_episode, epis.rowid
              BULK COLLECT
              INTO o_idepisodes_to_delete, o_rowids_to_delete
              FROM episode epis
              JOIN epis_info ei
                ON (epis.id_episode = ei.id_episode)
              JOIN grids_ea gea
                ON (gea.id_episode = epis.id_episode)
             WHERE ei.rowid IN (SELECT column_value
                                  FROM TABLE(i_rowids))
               AND (epis.flg_status NOT IN (pk_alert_constant.g_active, pk_alert_constant.g_pending) OR
                   epis.flg_ehr = 'E');
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
                                              i_function => l_function_name,
                                              o_error    => o_error);
        
            RETURN FALSE;
        
    END filter_epis_info_to_delete;

    -- Function and procedure implementations
    /**
    * Procedure that processes an update event on EPISODE
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Fábio Oliveira
    * @version 2.5.0.5
    * @since   03/09/2009
    */
    PROCEDURE set_episode
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'SET_EPISODE';
    
        l_rowids_remain        table_varchar;
        l_rowids_to_delete     table_varchar;
        l_idepisodes_to_delete table_number;
        l_episodes_to_delete   ts_episode.episode_tc;
    
        l_error t_error_out;
    
    BEGIN
    
        g_current_timestamp := current_timestamp;
        g_prof_category     := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        pk_alertlog.log_debug('Processing insert on EPISODE: ' || l_function_name, g_package_name, l_function_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPISODE',
                                                 i_expected_dg_table_name => 'GRIDS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar())
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        pk_alertlog.log_debug('Arguments validated: ' || l_function_name, g_package_name, l_function_name);
        IF i_rowids.count > 0
        THEN
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                IF NOT insert_valid_from_episode(i_lang, i_rowids, l_error)
                THEN
                    RAISE e_update_error;
                END IF;
                pk_alertlog.log_debug('Insert on EPISODE processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
                  OR i_event_type = t_data_gov_mnt.g_event_merge
            THEN
                IF NOT filter_episodes_to_delete(i_lang, i_rowids, l_rowids_to_delete, l_idepisodes_to_delete, l_error)
                THEN
                    RAISE e_filter_error;
                END IF;
            
                IF NOT delete_from_idepisode(i_lang, l_idepisodes_to_delete, l_error)
                THEN
                    RAISE e_update_error;
                END IF;
            
                IF l_rowids_to_delete.count != i_rowids.count
                THEN
                    l_rowids_remain := i_rowids MULTISET except l_rowids_to_delete;
                    IF NOT insert_valid_from_episode(i_lang, l_rowids_remain, l_error)
                    THEN
                        RAISE e_update_error;
                    END IF;
                END IF;
                pk_alertlog.log_debug('Update on EPISODE processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_episodes_to_delete := ts_episode.get_data_rowid_pat(rows_in => i_rowids);
                IF l_episodes_to_delete.exists(1)
                THEN
                    FOR i IN l_episodes_to_delete.first .. l_episodes_to_delete.last
                    LOOP
                        ts_grids_ea.del(id_episode_in => l_episodes_to_delete(i).id_episode);
                    END LOOP;
                END IF;
                pk_alertlog.log_debug('Delete on EPISODE processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN e_update_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'UPDATE ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN ERROR OCCURRED WHEN UPDATING GRIDS_EA');
        WHEN e_filter_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INTERNAL ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN INTERNAL ERROR OCCURRED');
    END set_episode;

    /**
    * Procedure that processes an update event on EPIS_INFO
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Fábio Oliveira
    * @version 2.5.0.5
    * @since   03/09/2009
    */
    PROCEDURE set_epis_info
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'SET_EPIS_INFO';
    
        l_rowids_remain        table_varchar;
        l_rowids_to_delete     table_varchar;
        l_idepisodes_to_delete table_number;
        l_epis_info_to_delete  ts_epis_info.epis_info_tc;
    
        l_error t_error_out;
    
    BEGIN
    
        g_current_timestamp := current_timestamp;
        g_prof_category     := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        pk_alertlog.log_debug('Processing insert on EPIS_INFO: ' || l_function_name, g_package_name, l_function_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'EPIS_INFO',
                                                 i_expected_dg_table_name => 'GRIDS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar())
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        pk_alertlog.log_debug('Arguments validated: ' || l_function_name, g_package_name, l_function_name);
        IF i_rowids.count > 0
        THEN
            IF i_event_type = t_data_gov_mnt.g_event_insert
            THEN
                IF NOT insert_valid_from_epis_info(i_lang, i_rowids, l_error)
                THEN
                    RAISE e_update_error;
                END IF;
                pk_alertlog.log_debug('Insert on EPIS_INFO processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_update
                  OR i_event_type = t_data_gov_mnt.g_event_merge
            THEN
                IF NOT filter_epis_info_to_delete(i_lang, i_rowids, l_rowids_to_delete, l_idepisodes_to_delete, l_error)
                THEN
                    RAISE e_filter_error;
                END IF;
            
                IF NOT delete_from_idepisode(i_lang, l_idepisodes_to_delete, l_error)
                THEN
                    RAISE e_update_error;
                END IF;
            
                IF l_rowids_to_delete.count != i_rowids.count
                THEN
                    l_rowids_remain := i_rowids MULTISET except l_rowids_to_delete;
                    IF NOT insert_valid_from_epis_info(i_lang, l_rowids_remain, l_error)
                    THEN
                        RAISE e_update_error;
                    END IF;
                END IF;
                pk_alertlog.log_debug('Update on EPIS_INFO processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            
            ELSIF i_event_type = t_data_gov_mnt.g_event_delete
            THEN
                l_epis_info_to_delete := ts_epis_info.get_data_rowid_pat(rows_in => i_rowids);
                IF l_epis_info_to_delete.exists(1)
                THEN
                    FOR i IN l_epis_info_to_delete.first .. l_epis_info_to_delete.last
                    LOOP
                        ts_grids_ea.del(id_episode_in => l_epis_info_to_delete(i).id_episode);
                    END LOOP;
                END IF;
                pk_alertlog.log_debug('Delete on EPIS_INFO processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN e_update_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'UPDATE ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN ERROR OCCURRED WHEN UPDATING GRIDS_EA');
        WHEN e_filter_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INTERNAL ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN INTERNAL ERROR OCCURRED');
    END set_epis_info;

    /**
    * Procedure that processes an update event on ANNOUNCED_ARRIVAL
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  Alexandre Santos
    * @version 2.5.0.7
    * @since   27/10/2009
    */
    PROCEDURE set_announced_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'SET_ANNOUNCED_ARRIVAL';
    
        l_grids_ea_records ts_grids_ea.grids_ea_tc;
    
        e_exception EXCEPTION;
    
        l_error t_error_out;
    
    BEGIN
    
        g_current_timestamp := current_timestamp;
        g_prof_category     := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        pk_alertlog.log_debug('Processing insert on ANNOUNCED_ARRIVAL: ' || l_function_name,
                              g_package_name,
                              l_function_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'ANNOUNCED_ARRIVAL',
                                                 i_expected_dg_table_name => 'GRIDS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar())
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        pk_alertlog.log_debug('Arguments validated: ' || l_function_name, g_package_name, l_function_name);
        IF i_rowids.exists(1)
           AND i_rowids.count > 0
        THEN
            IF i_event_type IN
               (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_merge)
            THEN
                g_error := 'SELECT EPIS_INFO ROWIDS';
                SELECT /*+RULE*/
                 epis.id_episode,
                 epis.id_visit,
                 epis.id_clinical_service,
                 epis.flg_status episode_flg_status,
                 epis.id_epis_type,
                 epis.companion episode_companion,
                 epis.barcode,
                 epis.id_prof_cancel,
                 epis.flg_type,
                 epis.id_prev_episode,
                 epis.dt_begin_tstz,
                 epis.dt_end_tstz,
                 epis.dt_cancel_tstz,
                 epis.id_fast_track,
                 epis.flg_ehr,
                 epis.id_patient,
                 epis.id_department,
                 epis.id_institution,
                 ei.id_bed,
                 ei.id_room,
                 ei.id_professional,
                 ei.norton,
                 ei.flg_hydric,
                 ei.flg_wound,
                 ei.companion epis_info_companion,
                 ei.flg_unknown,
                 ei.desc_info,
                 ei.id_schedule,
                 ei.id_first_nurse_resp,
                 ei.flg_status epis_info_flg_status,
                 ei.id_dep_clin_serv,
                 ei.id_first_dep_clin_serv,
                 ei.dt_first_obs_tstz,
                 ei.dt_first_nurse_obs_tstz,
                 ei.dt_first_inst_obs_tstz,
                 ei.triage_acuity,
                 ei.triage_color_text,
                 ei.triage_rank_acuity,
                 ei.triage_flg_letter,
                 ei.id_triage_color,
                 ei.id_software,
                 '' create_user,
                 '' create_time,
                 '' create_institution,
                 '' update_user,
                 '' update_time,
                 '' update_institution,
                 g_current_timestamp,
                 pk_announced_arrival.get_ann_arrival_id(epis.id_institution,
                                                         ei.id_software,
                                                         epis.id_episode,
                                                         ei.flg_unknown,
                                                         aa.id_announced_arrival,
                                                         aa.flg_status) id_announced_arrival,
                 -- "NULL" if 1st observation date is filled in, will keep the previous value in "flg_has_stripes".
                 nvl2(ei.dt_first_obs_tstz, NULL, pk_alert_constant.g_yes) flg_has_stripes,
                 decode(epis.id_fast_track,
                        NULL,
                        pk_epis_er_law_api.get_fast_track_id(epis.id_episode, epis.id_fast_track),
                        NULL) id_fast_track_er_law,
                 pk_transfer_institution.check_epis_transfer(epis.id_episode) flg_has_transfer
                  BULK COLLECT
                  INTO l_grids_ea_records
                  FROM announced_arrival aa
                  JOIN episode epis
                    ON (epis.id_episode = aa.id_episode)
                  JOIN epis_info ei
                    ON (epis.id_episode = ei.id_episode)
                 WHERE aa.rowid IN (SELECT column_value
                                      FROM TABLE(i_rowids))
                   AND epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                   AND epis.flg_ehr != 'E';
            
                IF l_grids_ea_records.exists(1)
                THEN
                    IF NOT upsert_on_grids_ea(i_lang             => i_lang,
                                              i_grids_ea_records => l_grids_ea_records,
                                              o_error            => l_error)
                    THEN
                        RAISE e_exception;
                    END IF;
                END IF;
            
                pk_alertlog.log_debug('Insert/Update on ANNOUNCED_ARRIVAL processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN e_update_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'UPDATE ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN ERROR OCCURRED WHEN UPDATING GRIDS_EA');
        WHEN e_filter_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INTERNAL ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN INTERNAL ERROR OCCURRED');
    END set_announced_arrival;

    /**
    * Procedure that processes an update event on TRANSFER_INSTITUTION
    *
    * @param   i_lang                Language ID
    * @param   i_prof                Professional context information
    * @value   i_event_type          Type of update event
    * @param   i_rowids              Table containing updated rowids
    * @param   i_source_table_name   Updated table name
    * @param   i_list_columns        Table containing updated table columns
    * @param   i_dg_table_name       Listening table ('GRIDS_EA')
    *
    * @author  José Brito
    * @version 2.5.1
    * @since   16-May-2011
    */
    PROCEDURE set_transfer_institution
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    ) IS
    
        l_function_name CONSTANT VARCHAR2(30) := 'SET_TRANSFER_INSTITUTION';
    
        l_grids_ea_records ts_grids_ea.grids_ea_tc;
    
        e_exception EXCEPTION;
        l_error     t_error_out;
    
    BEGIN
    
        g_current_timestamp := current_timestamp;
        g_prof_category     := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
    
        pk_alertlog.log_debug('Processing insert on TRANSFER_INSTITUTION: ' || l_function_name,
                              g_package_name,
                              l_function_name);
        IF NOT t_data_gov_mnt.validate_arguments(i_rowids                 => i_rowids,
                                                 i_source_table_name      => i_source_table_name,
                                                 i_dg_table_name          => i_dg_table_name,
                                                 i_expected_table_name    => 'TRANSFER_INSTITUTION',
                                                 i_expected_dg_table_name => 'GRIDS_EA',
                                                 i_list_columns           => i_list_columns,
                                                 i_expected_columns       => table_varchar())
        THEN
            RAISE t_data_gov_mnt.g_excp_invalid_arguments;
        END IF;
    
        pk_alertlog.log_debug('Arguments validated: ' || l_function_name, g_package_name, l_function_name);
        IF i_rowids.exists(1)
           AND i_rowids.count > 0
        THEN
            IF i_event_type IN
               (t_data_gov_mnt.g_event_insert, t_data_gov_mnt.g_event_update, t_data_gov_mnt.g_event_merge)
            THEN
                g_error := 'SELECT EPIS_INFO ROWIDS';
                SELECT /*+RULE*/
                 epis.id_episode,
                 epis.id_visit,
                 epis.id_clinical_service,
                 epis.flg_status episode_flg_status,
                 epis.id_epis_type,
                 epis.companion episode_companion,
                 epis.barcode,
                 epis.id_prof_cancel,
                 epis.flg_type,
                 epis.id_prev_episode,
                 epis.dt_begin_tstz,
                 epis.dt_end_tstz,
                 epis.dt_cancel_tstz,
                 epis.id_fast_track,
                 epis.flg_ehr,
                 epis.id_patient,
                 epis.id_department,
                 epis.id_institution,
                 ei.id_bed,
                 ei.id_room,
                 ei.id_professional,
                 ei.norton,
                 ei.flg_hydric,
                 ei.flg_wound,
                 ei.companion epis_info_companion,
                 ei.flg_unknown,
                 ei.desc_info,
                 ei.id_schedule,
                 ei.id_first_nurse_resp,
                 ei.flg_status epis_info_flg_status,
                 ei.id_dep_clin_serv,
                 ei.id_first_dep_clin_serv,
                 ei.dt_first_obs_tstz,
                 ei.dt_first_nurse_obs_tstz,
                 ei.dt_first_inst_obs_tstz,
                 ei.triage_acuity,
                 ei.triage_color_text,
                 ei.triage_rank_acuity,
                 ei.triage_flg_letter,
                 ei.id_triage_color,
                 ei.id_software,
                 '' create_user,
                 '' create_time,
                 '' create_institution,
                 '' update_user,
                 '' update_time,
                 '' update_institution,
                 g_current_timestamp,
                 pk_announced_arrival.get_ann_arrival_id(epis.id_institution,
                                                         ei.id_software,
                                                         epis.id_episode,
                                                         ei.flg_unknown) id_announced_arrival,
                 -- If transfer is finalized, set "flg_has_stripes" as "Y". Otherwise, "NULL" allows to keep previous value.
                 decode(ti.flg_status, pk_transfer_institution.g_transfer_inst_fin, pk_alert_constant.g_yes, NULL) flg_has_stripes,
                 decode(epis.id_fast_track,
                        NULL,
                        pk_epis_er_law_api.get_fast_track_id(epis.id_episode, epis.id_fast_track),
                        NULL) id_fast_track_er_law,
                 pk_transfer_institution.check_epis_transfer(epis.id_episode) flg_has_transfer
                  BULK COLLECT
                  INTO l_grids_ea_records
                  FROM transfer_institution ti
                  JOIN episode epis
                    ON (epis.id_episode = ti.id_episode)
                  JOIN epis_info ei
                    ON (epis.id_episode = ei.id_episode)
                 WHERE ti.rowid IN (SELECT column_value
                                      FROM TABLE(i_rowids))
                   AND epis.flg_status IN (pk_alert_constant.g_active, pk_alert_constant.g_pending)
                   AND epis.flg_ehr != 'E';
            
                IF l_grids_ea_records.exists(1)
                THEN
                    IF NOT upsert_on_grids_ea(i_lang             => i_lang,
                                              i_grids_ea_records => l_grids_ea_records,
                                              o_error            => l_error)
                    THEN
                        RAISE e_exception;
                    END IF;
                END IF;
            
                pk_alertlog.log_debug('Insert/Update on ANNOUNCED_ARRIVAL processed successfully: ' || l_function_name,
                                      g_package_name,
                                      l_function_name);
            ELSE
                RAISE t_data_gov_mnt.g_excp_invalid_arguments;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN e_update_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'UPDATE ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN ERROR OCCURRED WHEN UPDATING GRIDS_EA');
        WHEN e_filter_error THEN
            pk_alert_exceptions.raise_error(error_name_in => 'INTERNAL ERROR',
                                            text_in       => '[PK_EA_LOGIC_GRIDS] AN INTERNAL ERROR OCCURRED');
    END set_transfer_institution;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_ea_logic_grids;
/
