/*-- Last Change Revision: $Rev: 1102422 $*/
/*-- Last Change by: $Author: paulo.teixeira $*/
/*-- Date of last change: $Date: 2011-09-26 10:37:22 +0100 (seg, 26 set 2011) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_paramedical AS
    /********************************************************************************************
    * insert the dictation report in the plan area
    *
    * @param i_language                 language identifier
    * @param i_professional             professional identifier
    * @param i_institution              institution identifier
    * @param i_software                 software identifier
    * @param i_id_patient               patient identifier
    * @param i_num_rooms                number of rooms
    * @param i_num_bedrooms             number of bedrooms
    * @param i_num_person_room          number of persons per room
    * @param i_flg_wc_type              wc type flag
    * @param i_flg_wc_location          wc location flag
    * @param i_flg_wc_out               wc out flag
    * @param i_flg_water_distrib        water distribution flag
    * @param i_flg_water_origin         water origin flag
    * @param i_flg_conserv              state of conservation flag
    * @param i_flg_owner                ownership flag
    * @param i_flg_hab_type             home type flag
    * @param i_flg_light                has light flag
    * @param i_flg_heat                 has heat flag
    * @param i_arquitect_barrier        arquitect barrier
    * @param i_dt_registry_tstz         record date
    * @param i_flg_hab_location         home location flag
    * @param i_notes                    notes
    * @param i_flg_water_treatment      water treatment flag
    * @param i_flg_garbage_dest         garbage destination flag
    * @param i_ft_wc_type               free text wc type
    * @param i_ft_wc_location           free text wc location
    * @param i_ft_wc_out                free text wc out
    * @param i_ft_water_distrib         free text water distribution
    * @param i_ft_water_origin          free text water origin
    * @param i_ft_conserv               free text state of conservation
    * @param i_ft_owner                 free text ownership
    * @param i_ft_garbage_dest          free text garbage destination
    * @param i_ft_hab_type              free text home type
    * @param i_ft_water_treatment       free text water treatment
    * @param i_ft_light                 free text has light
    * @param i_ft_heat                  free text has heat
    * @param i_ft_hab_location          free text home location
    * @param i_flg_bath                 flag bathtub
    * @param i_ft_bath                  free text bathtub
    * @param i_cancel_notes             cancel notes
    * @param i_id_cancel_reason         cancel_reason identifier    
    * @param i_commit                   do commit 'Y' or 'N'    
    *
    * @return o_id_home     dictation report identifier
    * @return o_error
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2011/08/30
    **********************************************************************************************/
    FUNCTION api_insert_home
    (
        i_language            IN language.id_language%TYPE,
        i_professional        IN professional.id_professional%TYPE,
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN software.id_software%TYPE,
        i_id_patient          IN patient.id_patient%TYPE,
        i_num_rooms           IN home.num_rooms%TYPE,
        i_num_bedrooms        IN home.num_bedrooms%TYPE,
        i_num_person_room     IN home.num_person_room%TYPE,
        i_flg_wc_type         IN home.flg_wc_type%TYPE,
        i_flg_wc_location     IN home.flg_wc_location%TYPE,
        i_flg_wc_out          IN home.flg_wc_out%TYPE,
        i_flg_water_distrib   IN home.flg_water_distrib%TYPE,
        i_flg_water_origin    IN home.flg_water_origin%TYPE,
        i_flg_conserv         IN home.flg_conserv%TYPE,
        i_flg_owner           IN home.flg_owner%TYPE,
        i_flg_hab_type        IN home.flg_hab_type%TYPE,
        i_flg_light           IN home.flg_light%TYPE,
        i_flg_heat            IN home.flg_heat%TYPE,
        i_arquitect_barrier   IN home.arquitect_barrier%TYPE,
        i_dt_registry_tstz    IN home.dt_registry_tstz%TYPE,
        i_flg_hab_location    IN home.flg_hab_location%TYPE,
        i_notes               IN home.notes%TYPE,
        i_flg_water_treatment IN home.flg_water_treatment%TYPE,
        i_flg_garbage_dest    IN home.flg_garbage_dest%TYPE,
        i_ft_wc_type          IN home.ft_wc_type%TYPE,
        i_ft_wc_location      IN home.ft_wc_location%TYPE,
        i_ft_wc_out           IN home.ft_wc_out%TYPE,
        i_ft_water_distrib    IN home.ft_water_distrib%TYPE,
        i_ft_water_origin     IN home.ft_water_origin%TYPE,
        i_ft_conserv          IN home.ft_conserv%TYPE,
        i_ft_owner            IN home.ft_owner%TYPE,
        i_ft_garbage_dest     IN home.ft_garbage_dest%TYPE,
        i_ft_hab_type         IN home.ft_hab_type%TYPE,
        i_ft_water_treatment  IN home.ft_water_treatment%TYPE,
        i_ft_light            IN home.ft_light%TYPE,
        i_ft_heat             IN home.ft_heat%TYPE,
        i_ft_hab_location     IN home.ft_hab_location%TYPE,
        i_flg_bath            IN home.flg_bath%TYPE,
        i_ft_bath             IN home.ft_bath%TYPE,
        i_cancel_notes        IN cancel_info_det.notes_cancel_short%TYPE,
        i_id_cancel_reason    IN cancel_reason.id_cancel_reason%TYPE,
        i_commit              IN VARCHAR2,
        o_id_home             OUT home.id_home%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pat_family      home.id_pat_family%TYPE;
        l_dt_registry_tstz   home.dt_registry_tstz%TYPE;
        l_id_home_hist       home_hist.id_home_hist%TYPE;
        l_dt_home_hist       home_hist.dt_home_hist%TYPE;
        l_flg_status         home_hist.flg_status%TYPE;
        l_id_home            home.id_home%TYPE;
        l_next               home_hist.id_home_hist%TYPE;
        l_rowids             table_varchar;
        l_cancel_info_det_id cancel_info_det.id_cancel_info_det%TYPE;
    BEGIN
    
        IF i_id_cancel_reason IS NULL
        THEN
            -- edited status
            l_flg_status := pk_alert_constant.g_flg_status_e;
        ELSE
            -- cancelled status
            l_flg_status := pk_alert_constant.g_flg_status_c;
        END IF;
    
        IF i_dt_registry_tstz IS NULL
        THEN
            g_error := 'i_dt_registry_tstz cannot be null';
            RAISE g_exception;
        END IF;
    
        IF i_id_patient IS NULL
        THEN
            g_error := 'i_id_patient cannot be null';
            RAISE g_exception;
        END IF;
    
        IF i_professional IS NULL
        THEN
            g_error := 'i_professional cannot be null';
            RAISE g_exception;
        END IF;
        -- get/create id_pat_family
        g_error := 'pk_social.set_pat_fam';
        IF NOT pk_social.set_pat_fam(i_lang       => i_language,
                                     i_id_pat     => i_id_patient,
                                     i_prof       => profissional(i_professional, i_institution, i_software),
                                     i_commit     => pk_alert_constant.g_no,
                                     o_id_pat_fam => l_id_pat_family,
                                     o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'get l_id_home, dt_registry_tstz';
        BEGIN
            SELECT id_home, dt_registry_tstz
              INTO l_id_home, l_dt_registry_tstz
              FROM (SELECT h.id_home id_home, h.dt_registry_tstz dt_registry_tstz
                      FROM home h
                     WHERE h.id_pat_family = l_id_pat_family
                     ORDER BY h.dt_registry_tstz DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_home          := NULL;
                l_dt_registry_tstz := NULL;
        END;
    
        IF l_id_home IS NULL
        THEN
            --insert home
            IF l_flg_status = pk_alert_constant.g_flg_status_c
            THEN
                g_error := 'first record cannot be cancelled';
                RAISE g_exception;
            END IF;
            g_error := 'ts_home.ins';
            ts_home.ins(id_pat_family_in       => l_id_pat_family,
                        id_professional_in     => i_professional,
                        num_rooms_in           => i_num_rooms,
                        num_bedrooms_in        => i_num_bedrooms,
                        num_person_room_in     => i_num_person_room,
                        flg_wc_type_in         => i_flg_wc_type,
                        flg_wc_location_in     => i_flg_wc_location,
                        flg_wc_out_in          => i_flg_wc_out,
                        flg_water_distrib_in   => i_flg_water_distrib,
                        flg_water_origin_in    => i_flg_water_origin,
                        flg_conserv_in         => i_flg_conserv,
                        flg_owner_in           => i_flg_owner,
                        flg_hab_type_in        => i_flg_hab_type,
                        flg_light_in           => i_flg_light,
                        flg_heat_in            => i_flg_heat,
                        arquitect_barrier_in   => i_arquitect_barrier,
                        dt_registry_tstz_in    => i_dt_registry_tstz,
                        flg_hab_location_in    => i_flg_hab_location,
                        notes_in               => i_notes,
                        flg_status_in          => pk_alert_constant.g_flg_status_a,
                        flg_water_treatment_in => i_flg_water_treatment,
                        flg_garbage_dest_in    => i_flg_garbage_dest,
                        ft_wc_type_in          => i_ft_wc_type,
                        ft_wc_location_in      => i_ft_wc_location,
                        ft_wc_out_in           => i_ft_wc_out,
                        ft_water_distrib_in    => i_ft_water_distrib,
                        ft_water_origin_in     => i_ft_water_origin,
                        ft_conserv_in          => i_ft_conserv,
                        ft_owner_in            => i_ft_owner,
                        ft_garbage_dest_in     => i_ft_garbage_dest,
                        ft_hab_type_in         => i_ft_hab_type,
                        ft_water_treatment_in  => i_ft_water_treatment,
                        ft_light_in            => i_ft_light,
                        ft_heat_in             => i_ft_heat,
                        ft_hab_location_in     => i_ft_hab_location,
                        flg_bath_in            => i_flg_bath,
                        ft_bath_in             => i_ft_bath,
                        id_home_out            => o_id_home,
                        rows_out               => l_rowids);
        
            g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON HOME';
            t_data_gov_mnt.process_insert(i_lang       => i_language,
                                          i_prof       => profissional(i_professional, i_institution, i_software),
                                          i_table_name => 'HOME',
                                          i_rowids     => l_rowids,
                                          o_error      => o_error);
            --insert home_hist
            g_error := 'pk_social.set_home_hist';
            IF NOT pk_social.set_home_hist(i_lang    => i_language,
                                           i_prof    => profissional(i_professional, i_institution, i_software),
                                           i_id_pat  => i_id_patient,
                                           i_id_home => o_id_home,
                                           o_error   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            -- already exists, update home
            IF l_dt_registry_tstz <= i_dt_registry_tstz
            THEN
                --new record date bigger then current reccord, update home, insert home_hist
                IF l_flg_status = pk_alert_constant.g_flg_status_c
                THEN
                    g_error := 'ts_cancel_info_det.ins';
                    ts_cancel_info_det.ins(id_prof_cancel_in      => i_professional,
                                           id_cancel_reason_in    => i_id_cancel_reason,
                                           dt_cancel_in           => i_dt_registry_tstz,
                                           notes_cancel_short_in  => i_cancel_notes,
                                           id_cancel_info_det_out => l_cancel_info_det_id,
                                           rows_out               => l_rowids);
                
                    g_error := 'UPDATES T_DATA_GOV_MNT-INSERT ON CANCEL_INFO_DET';
                    t_data_gov_mnt.process_insert(i_lang       => i_language,
                                                  i_prof       => profissional(i_professional, i_institution, i_software),
                                                  i_table_name => 'CANCEL_INFO_DET',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            
                g_error := 'ts_home.upd';
                ts_home.upd(id_home_in              => l_id_home,
                            id_professional_in      => i_professional,
                            num_rooms_in            => i_num_rooms,
                            num_bedrooms_in         => i_num_bedrooms,
                            num_person_room_in      => i_num_person_room,
                            flg_wc_type_in          => i_flg_wc_type,
                            flg_wc_location_in      => i_flg_wc_location,
                            flg_wc_out_in           => i_flg_wc_out,
                            flg_water_distrib_in    => i_flg_water_distrib,
                            flg_water_origin_in     => i_flg_water_origin,
                            flg_conserv_in          => i_flg_conserv,
                            flg_owner_in            => i_flg_owner,
                            flg_hab_type_in         => i_flg_hab_type,
                            flg_light_in            => i_flg_light,
                            flg_heat_in             => i_flg_heat,
                            arquitect_barrier_in    => i_arquitect_barrier,
                            dt_registry_tstz_in     => i_dt_registry_tstz,
                            flg_hab_location_in     => i_flg_hab_location,
                            notes_in                => i_notes,
                            flg_status_in           => l_flg_status,
                            id_cancel_info_det_in   => l_cancel_info_det_id,
                            flg_water_treatment_in  => i_flg_water_treatment,
                            flg_garbage_dest_in     => i_flg_garbage_dest,
                            ft_wc_type_in           => i_ft_wc_type,
                            ft_wc_location_in       => i_ft_wc_location,
                            ft_wc_out_in            => i_ft_wc_out,
                            ft_water_distrib_in     => i_ft_water_distrib,
                            ft_water_origin_in      => i_ft_water_origin,
                            ft_conserv_in           => i_ft_conserv,
                            ft_owner_in             => i_ft_owner,
                            ft_garbage_dest_in      => i_ft_garbage_dest,
                            ft_hab_type_in          => i_ft_hab_type,
                            ft_water_treatment_in   => i_ft_water_treatment,
                            ft_light_in             => i_ft_light,
                            ft_heat_in              => i_ft_heat,
                            ft_hab_location_in      => i_ft_hab_location,
                            flg_bath_in             => i_flg_bath,
                            ft_bath_in              => i_ft_bath,
                            id_professional_nin     => FALSE,
                            num_rooms_nin           => FALSE,
                            num_bedrooms_nin        => FALSE,
                            num_person_room_nin     => FALSE,
                            flg_wc_type_nin         => FALSE,
                            flg_wc_location_nin     => FALSE,
                            flg_wc_out_nin          => FALSE,
                            flg_water_distrib_nin   => FALSE,
                            flg_water_origin_nin    => FALSE,
                            flg_conserv_nin         => FALSE,
                            flg_owner_nin           => FALSE,
                            flg_hab_type_nin        => FALSE,
                            flg_light_nin           => FALSE,
                            flg_heat_nin            => FALSE,
                            arquitect_barrier_nin   => FALSE,
                            dt_registry_tstz_nin    => FALSE,
                            flg_hab_location_nin    => FALSE,
                            notes_nin               => FALSE,
                            flg_status_nin          => FALSE,
                            id_cancel_info_det_nin  => FALSE,
                            flg_water_treatment_nin => FALSE,
                            flg_garbage_dest_nin    => FALSE,
                            ft_wc_type_nin          => FALSE,
                            ft_wc_location_nin      => FALSE,
                            ft_wc_out_nin           => FALSE,
                            ft_water_distrib_nin    => FALSE,
                            ft_water_origin_nin     => FALSE,
                            ft_conserv_nin          => FALSE,
                            ft_owner_nin            => FALSE,
                            ft_garbage_dest_nin     => FALSE,
                            ft_hab_type_nin         => FALSE,
                            ft_water_treatment_nin  => FALSE,
                            ft_light_nin            => FALSE,
                            ft_heat_nin             => FALSE,
                            ft_hab_location_nin     => FALSE,
                            flg_bath_nin            => FALSE,
                            ft_bath_nin             => FALSE,
                            rows_out                => l_rowids);
                o_id_home := l_id_home;
            
                g_error := 't_data_gov_mnt.process_update';
                t_data_gov_mnt.process_update(i_lang       => i_language,
                                              i_prof       => profissional(i_professional, i_institution, i_software),
                                              i_table_name => 'HOME',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
                --Set history for home information
                g_error := 'pk_social.set_home_hist';
                IF NOT pk_social.set_home_hist(i_lang    => i_language,
                                               i_prof    => profissional(i_professional, i_institution, i_software),
                                               i_id_pat  => i_id_patient,
                                               i_id_home => o_id_home,
                                               o_error   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            ELSE
                --new record date smaller then current reccord, don't update home, update home_hist
                g_error := 'get l_id_home';
                BEGIN
                    --get the the older record in home_hist
                    SELECT id_home_hist, dt_home_hist
                      INTO l_id_home_hist, l_dt_home_hist
                      FROM (SELECT hh.id_home_hist id_home_hist, hh.dt_home_hist dt_home_hist
                              FROM home_hist hh
                             WHERE hh.id_pat_family = l_id_pat_family
                               AND hh.flg_status = pk_alert_constant.g_flg_status_a
                             ORDER BY hh.dt_home_hist ASC)
                     WHERE rownum = 1;
                EXCEPTION
                    WHEN OTHERS THEN
                        l_id_home_hist := NULL;
                        l_dt_home_hist := NULL;
                END;
            
                IF l_dt_home_hist >= i_dt_registry_tstz
                   AND l_id_home_hist IS NOT NULL
                THEN
                    --the new record is older than all the existing records, 
                    IF l_flg_status = pk_alert_constant.g_flg_status_c
                    THEN
                        g_error := 'first record cannot be cancelled';
                        RAISE g_exception;
                    END IF;
                    --insert the new with status created
                    l_flg_status := pk_alert_constant.g_flg_status_a;
                    --update the oldest flag status to edited 
                    g_error := 'ts_home_hist.upd';
                    ts_home_hist.upd(id_home_hist_in => l_id_home_hist,
                                     flg_status_in   => pk_alert_constant.g_flg_status_e,
                                     rows_out        => l_rowids);
                
                    g_error := 't_data_gov_mnt.process_update';
                    t_data_gov_mnt.process_update(i_lang       => i_language,
                                                  i_prof       => profissional(i_professional, i_institution, i_software),
                                                  i_table_name => 'HOME_HIST',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
            
                --cancel when status = 'C'
                IF l_flg_status = pk_alert_constant.g_flg_status_c
                THEN
                    g_error := 'ts_cancel_info_det.ins';
                    ts_cancel_info_det.ins(id_prof_cancel_in      => i_professional,
                                           id_cancel_reason_in    => i_id_cancel_reason,
                                           dt_cancel_in           => i_dt_registry_tstz,
                                           notes_cancel_short_in  => i_cancel_notes,
                                           id_cancel_info_det_out => l_cancel_info_det_id,
                                           rows_out               => l_rowids);
                
                    g_error := 't_data_gov_mnt.process_insert';
                    t_data_gov_mnt.process_insert(i_lang       => i_language,
                                                  i_prof       => profissional(i_professional, i_institution, i_software),
                                                  i_table_name => 'CANCEL_INFO_DET',
                                                  i_rowids     => l_rowids,
                                                  o_error      => o_error);
                END IF;
                g_error := 'ts_home_hist.ins';
                ts_home_hist.ins(id_home_in             => l_id_home,
                                 id_pat_family_in       => l_id_pat_family,
                                 id_professional_in     => i_professional,
                                 dt_registry_tstz_in    => i_dt_registry_tstz,
                                 num_rooms_in           => i_num_rooms,
                                 num_bedrooms_in        => i_num_bedrooms,
                                 num_person_room_in     => i_num_person_room,
                                 flg_wc_type_in         => i_flg_wc_type,
                                 flg_wc_out_in          => i_flg_wc_out,
                                 flg_heat_in            => i_flg_heat,
                                 flg_wc_location_in     => i_flg_wc_location,
                                 flg_water_origin_in    => i_flg_water_origin,
                                 flg_water_distrib_in   => i_flg_water_distrib,
                                 flg_conserv_in         => i_flg_conserv,
                                 flg_owner_in           => i_flg_owner,
                                 flg_hab_type_in        => i_flg_hab_type,
                                 flg_hab_location_in    => i_flg_hab_location,
                                 flg_light_in           => i_flg_light,
                                 arquitect_barrier_in   => i_arquitect_barrier,
                                 notes_in               => i_notes,
                                 flg_status_in          => l_flg_status,
                                 dt_home_hist_in        => i_dt_registry_tstz,
                                 id_cancel_info_det_in  => l_cancel_info_det_id,
                                 flg_water_treatment_in => i_flg_water_treatment,
                                 flg_garbage_dest_in    => i_flg_garbage_dest,
                                 ft_wc_type_in          => i_ft_wc_type,
                                 ft_wc_location_in      => i_ft_wc_location,
                                 ft_wc_out_in           => i_ft_wc_out,
                                 ft_water_distrib_in    => i_ft_water_distrib,
                                 ft_water_origin_in     => i_ft_water_origin,
                                 ft_conserv_in          => i_ft_conserv,
                                 ft_owner_in            => i_ft_owner,
                                 ft_garbage_dest_in     => i_ft_garbage_dest,
                                 ft_hab_type_in         => i_ft_hab_type,
                                 ft_water_treatment_in  => i_ft_water_treatment,
                                 ft_light_in            => i_ft_light,
                                 ft_heat_in             => i_ft_heat,
                                 ft_hab_location_in     => i_ft_hab_location,
                                 flg_bath_in            => i_flg_bath,
                                 ft_bath_in             => i_ft_bath,
                                 id_home_hist_out       => l_next,
                                 rows_out               => l_rowids);
            
                g_error := 'UPDATES t_data_gov_mnt.process_insert ON HOME_HIST';
                t_data_gov_mnt.process_insert(i_lang       => i_language,
                                              i_prof       => profissional(i_professional, i_institution, i_software),
                                              i_table_name => 'HOME_HIST',
                                              i_rowids     => l_rowids,
                                              o_error      => o_error);
            
            END IF;
        
        END IF;
    
        IF i_commit = pk_alert_constant.g_yes
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pk_owner,
                                              g_package_name,
                                              'API_INSERT_HOME',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END api_insert_home;

BEGIN
    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END pk_api_paramedical;
/
