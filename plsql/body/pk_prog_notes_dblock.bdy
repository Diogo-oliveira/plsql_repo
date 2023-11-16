/*-- Last Change Revision: $Rev: 2055250 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-02-14 15:24:02 +0000 (ter, 14 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_prog_notes_dblock AS

    g_exception EXCEPTION;

    /************************************************************************** 
    * get import data from past medical history
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID    
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.3s                      
    * @since                          10-Ock-2011                             
    **************************************************************************/
    FUNCTION get_import_past_hist_medical
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_PAST_HIST_MEDICAL';
        --Past history medical
        l_past_med                   pk_types.cursor_type;
        l_num_records                NUMBER := 0;
        l_id_episode                 episode.id_episode%TYPE;
        l_id_epis_diagnosis          epis_diagnosis.id_epis_diagnosis%TYPE;
        l_id_surgery_record          sr_surgery_record.id_surgery_record%TYPE;
        l_dt_register                pk_translation.t_desc_translation;
        l_nick_name                  pk_translation.t_desc_translation;
        l_desc_past_hist_all         pk_translation.t_desc_translation;
        l_flg_current_episode        VARCHAR2(1 CHAR);
        l_dt_register_chr            pk_translation.t_desc_translation;
        l_dt_pat_hist_diagnosis_tstz epis_diagnosis.dt_confirmed_tstz%TYPE;
        l_id_professional            professional.id_professional%TYPE;
        l_status_diagnosis           epis_diagnosis.flg_status%TYPE;
    
        l_id_task          epis_pn_det_task.id_task%TYPE;
        l_id_task_type     epis_pn_det_task.id_task_type%TYPE;
        l_dt_register_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        g_error := 'CALL PK_PAST_HISTORY.GET_PAST_HIST_MEDICAL FUNCTION i_id_episode: ' || i_id_episode ||
                   ' i_id_patient: ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_past_history.get_past_med_others(i_lang       => i_lang,
                                                   i_prof       => i_prof,
                                                   i_episode    => i_id_episode,
                                                   i_patient    => i_id_patient,
                                                   i_start_date => i_begin_date,
                                                   i_end_date   => i_end_date,
                                                   o_past_med   => l_past_med,
                                                   o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCH CURSOR';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_past_med
                INTO l_id_episode,
                     l_id_epis_diagnosis,
                     l_id_surgery_record,
                     l_dt_register,
                     l_nick_name,
                     l_desc_past_hist_all,
                     l_flg_current_episode,
                     l_dt_register_chr,
                     l_dt_pat_hist_diagnosis_tstz,
                     l_id_professional,
                     l_status_diagnosis;
            EXIT WHEN l_past_med%NOTFOUND;
        
            IF (l_status_diagnosis != pk_past_history.g_pat_hist_diag_canceled OR l_status_diagnosis IS NULL)
            THEN
            
                IF (l_id_epis_diagnosis IS NOT NULL)
                THEN
                    l_id_task      := l_id_epis_diagnosis;
                    l_id_task_type := pk_prog_notes_constants.g_task_ph_medical_diag;
                ELSE
                    l_id_task      := l_id_surgery_record;
                    l_id_task_type := pk_prog_notes_constants.g_task_ph_medical_surg;
                END IF;
            
                l_desc_past_hist_all := pk_string_utils.trim_empty_lines(i_text => l_desc_past_hist_all);
            
                l_dt_register_tstz := pk_date_utils.get_string_tstz(i_lang, i_prof, l_dt_register, NULL);
            
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_desc_past_hist_all,
                                                                     l_desc_past_hist_all,
                                                                     l_dt_register_chr,
                                                                     l_dt_register_tstz,
                                                                     l_id_professional,
                                                                     l_id_task,
                                                                     l_id_task_type,
                                                                     NULL,
                                                                     NULL,
                                                                     l_id_episode, --13                                                                     
                                                                     NULL,
                                                                     l_dt_register_tstz,
                                                                     pk_prog_notes_constants.g_task_not_applicable_n,
                                                                     pk_alert_constant.g_yes,
                                                                     NULL,
                                                                     nvl(l_dt_pat_hist_diagnosis_tstz,
                                                                         l_dt_register_tstz),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
                l_num_records := l_num_records + 1;
            END IF;
        
        END LOOP;
    
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
        
    END get_import_past_hist_medical;

    /**************************************************************************
    * get import data from the EA table corresponding to the given task type.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task                Task reference ID
    * @param i_id_task_type           Task type ID
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block ID
    * @param i_dt_register            Task registration date ID
    * @param i_desc                   Task description
    * @param i_id_prof_req            Prof id that requested the task
    * @param i_flg_import_date        Y-Task date should be imported together with the text
    * @param i_flg_group_on_import    D- records should be grouped by Date. N-No group
    * @param i_id_episode             Episode identifier
    * @param i_id_group               Group identifier
    * @param i_dt_last_update         Last update date of the task
    * @param i_rank                   Task rank. 1 - initial value; 2 - penultimate value; 3 - last value -> 
    *                                 position of the table when using the table format
    * @param i_flg_type               DT block flg_type
    * @param i_vs_desc                Vital sign description
    * @param i_table_position         Table column position
    * @param io_data_import           Struct with data import information
    * @param io_count_records         Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION set_rec_to_struct_vs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_task             IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_type        IN task_timeline_ea.id_tl_task%TYPE,
        i_id_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_dt_register         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_desc                IN VARCHAR2,
        i_id_prof_req         IN task_timeline_ea.id_prof_req%TYPE,
        i_flg_import_date     IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_group_on_import IN pn_dblock_mkt.flg_group_on_import%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_group            IN NUMBER,
        i_dt_last_update      IN task_timeline_ea.dt_last_update%TYPE,
        i_rank                IN task_timeline_ea.rank%TYPE,
        i_flg_type            IN pn_data_block.flg_type%TYPE,
        i_vs_desc             IN pk_translation.t_desc_translation,
        i_table_position      IN epis_pn_det_task.table_position%TYPE,
        io_data_import        IN OUT t_coll_data_import,
        io_count_records      IN OUT PLS_INTEGER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30 CHAR) := 'SET_REC_TO_STRUCT_VS';
        l_dt_reg        pk_translation.t_desc_translation;
        l_desc          CLOB;
    BEGIN
    
        g_error := 'SET TASK TO IMPORT STRUCTURE. id_task: ' || i_id_task || ' id_tl_task: ' || i_id_task_type ||
                   ' i_id_pn_data_block: ' || i_id_pn_data_block || ' i_id_pn_soap_block: ' || i_id_pn_soap_block ||
                   ' i_id_prof_req: ' || i_id_prof_req || ' i_flg_import_date: ' || i_flg_import_date;
        pk_alertlog.log_debug(g_error);
        IF (i_id_task IS NOT NULL)
        THEN
        
            IF (i_flg_type = pk_prog_notes_constants.g_data_block_text)
            THEN
                l_desc := i_vs_desc || pk_prog_notes_constants.g_colon || i_desc;
            ELSE
                l_desc := i_desc;
            
            END IF;
        
            l_dt_reg := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                    i_date => i_dt_register,
                                                    i_inst => i_prof.institution,
                                                    i_soft => i_prof.software);
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_id_pn_soap_block,
                                                                 i_id_pn_data_block,
                                                                 l_desc,
                                                                 l_desc,
                                                                 l_dt_reg,
                                                                 i_dt_register,
                                                                 i_id_prof_req,
                                                                 i_id_task,
                                                                 i_id_task_type,
                                                                 NULL,
                                                                 i_rank, --11: rank                                                                 
                                                                 i_id_episode,
                                                                 NULL,
                                                                 i_dt_register,
                                                                 pk_prog_notes_constants.g_task_ongoing_o,
                                                                 pk_alert_constant.g_yes,
                                                                 NULL,
                                                                 i_dt_last_update,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_flg_group_on_import,
                                                                 i_dt_register,
                                                                 pk_prog_notes_utils.get_hour_group_id(i_lang => i_lang,
                                                                                                       i_prof => i_prof,
                                                                                                       i_date => i_dt_register), --id_group_import
                                                                 NULL, --pk_prog_notes_constants.g_vital_sign_desc_code || i_id_group,
                                                                 pk_prog_notes_utils.get_hour_desc_group(i_lang => i_lang,
                                                                                                         i_prof => i_prof,
                                                                                                         i_date => i_dt_register),
                                                                 NULL,
                                                                 NULL,
                                                                 '; ',
                                                                 i_id_group,
                                                                 i_table_position,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
        
            io_count_records := io_count_records + 1;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
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
    END set_rec_to_struct_vs;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/07                                 
    **************************************************************************/

    FUNCTION get_import_vital_signs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_scope               IN NUMBER,
        i_scope_type          IN VARCHAR2,
        i_pn_soap_block       IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block       IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_outside_period      IN VARCHAR2,
        i_id_pn_task_type     IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_import_date     IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_group_on_import IN pn_dblock_mkt.flg_group_on_import%TYPE,
        i_flg_type            IN pn_data_block.flg_type%TYPE,
        io_data_import        IN OUT t_coll_data_import,
        o_count_records       OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_vs          pk_vital_sign.t_cur_vital_signs;
        l_tbl_vital_signs pk_vital_sign.t_coll_vital_signs;
        l_view            VARCHAR2(2 CHAR) := 'V2';
        l_rank            vs_soft_inst.rank%TYPE;
        l_function_name   VARCHAR2(30 CHAR) := 'GET_IMPORT_VITAL_SIGNS';
        l_count           NUMBER;
        l_check           NUMBER;
    BEGIN
    
        g_error := 'CALL PK_VITAL_SIGN.GET_VITAL_SIGNS_LIST FUNCTION';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_vital_sign.get_vital_signs_list(i_lang           => i_lang,
                                                  i_prof           => i_prof,
                                                  i_scope          => i_scope,
                                                  i_scope_type     => i_scope_type,
                                                  i_begin_date     => i_begin_date,
                                                  i_end_date       => i_end_date,
                                                  i_outside_period => i_outside_period,
                                                  i_flg_view       => l_view,
                                                  o_list           => l_cur_vs,
                                                  o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCH CURSOR FOR VITAL SIGNS';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_cur_vs BULK COLLECT
                INTO l_tbl_vital_signs LIMIT g_limit;
        
            FOR i IN 1 .. l_tbl_vital_signs.count
            LOOP
            
                SELECT COUNT(1)
                  INTO l_count
                  FROM vs_soft_inst vsi
                 WHERE vsi.id_vital_sign = l_tbl_vital_signs(i).id_vital_sign
                   AND vsi.id_software = i_prof.software
                   AND vsi.id_institution = i_prof.institution
                   AND vsi.flg_view NOT IN ('PT', 'PG');
            
                IF l_count > 0
                THEN
                    l_check := 0;
                    FOR j IN 1 .. io_data_import.count
                    LOOP
                        IF (io_data_import(j)
                           .id_task IN (l_tbl_vital_signs(i).id_vital_sign_read_4,
                                        l_tbl_vital_signs(i).id_vital_sign_read_1,
                                        l_tbl_vital_signs(i).id_vital_sign_read_2) AND io_data_import(j)
                           .id_task_type IN
                            (pk_prog_notes_constants.g_task_vital_signs, pk_prog_notes_constants.g_task_biometrics))
                        THEN
                            IF io_data_import(j).id_task_type = i_id_pn_task_type
                            THEN
                                l_check := 1;
                                EXIT;
                            END IF;
                        END IF;
                    END LOOP;
                
                    IF l_check = 0
                    THEN
                        g_error := 'call  pk_vital_sign.get_vital_sign_view_rank';
                        pk_alertlog.log_info(text            => g_error,
                                             object_name     => g_package_name,
                                             sub_object_name => l_function_name);
                        l_rank := pk_vital_sign.get_vital_sign_view_rank(i_lang          => i_lang,
                                                                         i_prof          => i_prof,
                                                                         i_id_vital_sign => l_tbl_vital_signs(i).id_vital_sign,
                                                                         i_flg_view      => l_view);
                    
                        --initial value
                        IF (i_flg_type = pk_prog_notes_constants.g_dblock_table OR
                           (i_flg_type IS NULL AND l_tbl_vital_signs(i).id_vital_sign_read_4 IS NOT NULL))
                        THEN
                            g_error := 'CALL set_rec_to_struct_vs initial value';
                            pk_alertlog.log_debug(g_error);
                            IF NOT set_rec_to_struct_vs(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_task             => l_tbl_vital_signs(i).id_vital_sign_read_4,
                                                        i_id_task_type        => i_id_pn_task_type,
                                                        i_id_pn_data_block    => i_pn_data_block,
                                                        i_id_pn_soap_block    => i_pn_soap_block,
                                                        i_dt_register         => l_tbl_vital_signs(i).dt_reg_4,
                                                        i_desc                => TRIM(pk_string_utils.trim_empty_lines(i_text => l_tbl_vital_signs(i).vs_description_4)),
                                                        i_id_prof_req         => l_tbl_vital_signs(i).id_professional_4,
                                                        i_flg_import_date     => i_flg_import_date,
                                                        i_flg_group_on_import => i_flg_group_on_import,
                                                        i_id_episode          => l_tbl_vital_signs(i).id_episode_4,
                                                        i_id_group            => l_tbl_vital_signs(i).id_vital_sign,
                                                        i_dt_last_update      => l_tbl_vital_signs(i).dt_last_upd_4,
                                                        i_rank                => l_rank,
                                                        i_flg_type            => i_flg_type,
                                                        i_vs_desc             => TRIM(l_tbl_vital_signs(i).vs_desc),
                                                        i_table_position      => 1,
                                                        io_data_import        => io_data_import,
                                                        io_count_records      => o_count_records,
                                                        o_error               => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                    
                        IF (i_flg_type = pk_prog_notes_constants.g_data_block_text OR
                           (l_tbl_vital_signs(i).id_vital_sign_read_1 <> l_tbl_vital_signs(i).id_vital_sign_read_4 OR l_tbl_vital_signs(i).id_vital_sign_read_4 IS NULL))
                        THEN
                            --Ultimate vital sign reading 
                            g_error := 'CALL set_rec_to_struct_vs ultimate reading';
                            pk_alertlog.log_debug(g_error);
                            IF NOT set_rec_to_struct_vs(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_task             => l_tbl_vital_signs(i).id_vital_sign_read_1,
                                                        i_id_task_type        => i_id_pn_task_type,
                                                        i_id_pn_data_block    => i_pn_data_block,
                                                        i_id_pn_soap_block    => i_pn_soap_block,
                                                        i_dt_register         => l_tbl_vital_signs(i).dt_reg_1,
                                                        i_desc                => TRIM(pk_string_utils.trim_empty_lines(i_text => l_tbl_vital_signs(i).vs_description_1)),
                                                        i_id_prof_req         => l_tbl_vital_signs(i).id_professional_1,
                                                        i_flg_import_date     => i_flg_import_date,
                                                        i_flg_group_on_import => i_flg_group_on_import,
                                                        i_id_episode          => l_tbl_vital_signs(i).id_episode_1,
                                                        i_id_group            => l_tbl_vital_signs(i).id_vital_sign,
                                                        i_dt_last_update      => l_tbl_vital_signs(i).dt_last_upd_1,
                                                        i_rank                => l_rank,
                                                        i_flg_type            => i_flg_type,
                                                        i_vs_desc             => TRIM(l_tbl_vital_signs(i).vs_desc),
                                                        i_table_position      => 3,
                                                        io_data_import        => io_data_import,
                                                        io_count_records      => o_count_records,
                                                        o_error               => o_error)
                            THEN
                                RAISE g_other_exception;
                            END IF;
                        END IF;
                        IF (i_flg_type = pk_prog_notes_constants.g_dblock_table)
                        THEN
                            --IF (l_tbl_vital_signs(i).id_vital_sign <> 30)
                            --THEN
                            --Height: should only be considered the last reading
                            --penultimate vital sign reading
                            IF ((l_tbl_vital_signs(i).id_vital_sign_read_2 <> l_tbl_vital_signs(i).id_vital_sign_read_1 OR l_tbl_vital_signs(i).id_vital_sign_read_1 IS NULL) AND
                               (i_flg_type = pk_prog_notes_constants.g_data_block_text OR
                               (l_tbl_vital_signs(i).id_vital_sign_read_2 <> l_tbl_vital_signs(i).id_vital_sign_read_4 OR l_tbl_vital_signs(i).id_vital_sign_read_4 IS NULL)))
                            THEN
                                g_error := 'CALL set_rec_to_struct_vs';
                                pk_alertlog.log_debug(g_error);
                                IF NOT set_rec_to_struct_vs(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_task             => l_tbl_vital_signs(i).id_vital_sign_read_2,
                                                            i_id_task_type        => i_id_pn_task_type,
                                                            i_id_pn_data_block    => i_pn_data_block,
                                                            i_id_pn_soap_block    => i_pn_soap_block,
                                                            i_dt_register         => l_tbl_vital_signs(i).dt_reg_2,
                                                            i_desc                => TRIM(l_tbl_vital_signs(i).vs_description_2),
                                                            i_id_prof_req         => l_tbl_vital_signs(i).id_professional_2,
                                                            i_flg_import_date     => i_flg_import_date,
                                                            i_flg_group_on_import => i_flg_group_on_import,
                                                            i_id_episode          => l_tbl_vital_signs(i).id_episode_2,
                                                            i_id_group            => l_tbl_vital_signs(i).id_vital_sign,
                                                            i_dt_last_update      => l_tbl_vital_signs(i).dt_last_upd_2,
                                                            i_rank                => l_rank,
                                                            i_flg_type            => i_flg_type,
                                                            i_vs_desc             => TRIM(l_tbl_vital_signs(i).vs_desc),
                                                            i_table_position      => 2,
                                                            io_data_import        => io_data_import,
                                                            io_count_records      => o_count_records,
                                                            o_error               => o_error)
                                THEN
                                    RAISE g_other_exception;
                                END IF;
                            END IF;
                            --END IF;
                        END IF;
                    END IF;
                END IF;
            
            END LOOP;
            EXIT WHEN l_cur_vs%NOTFOUND;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_vital_signs;

    /**************************************************************************
    * get import data from obstetric history
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID  
    * @param i_id_doc_area            Documentation area ID                           
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/07                                 
    **************************************************************************/

    FUNCTION get_import_past_hist_obstetric
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_doc_area      IN doc_area.id_doc_area%TYPE,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_import_date  IN pn_dblock_mkt.flg_import_date%TYPE,
        i_begin_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_synchronized IN VARCHAR2,
        io_data_import     IN OUT t_coll_data_import,
        o_count_records    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_patient            patient.id_patient%TYPE;
        l_id_visit              visit.id_visit%TYPE;
        l_id_episode            episode.id_episode%TYPE;
        l_cur_doc_area_val_preg pk_pregnancy.p_doc_area_val_doc_cur_ph;
        l_doc_area_register     pk_pregnancy.t_cur_doc_area_pregnancy_ph;
        l_tbl_pregnancy         pk_pregnancy.t_coll_doc_area_pregnancy_ph;
        l_num_records           NUMBER := 0;
        l_function_name         VARCHAR2(30 CHAR) := 'GET_IMPORT_PAST_HIST_OBSTETRIC';
        l_dt_register_tstz      TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_last_update_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'CALL PK_PREGNANCY.GET_SUM_PAGE_DOC_AR_PAST_PREG';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_pregnancy.get_sum_page_doc_ar_past_preg(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_episode           => i_id_episode,
                                                          i_pat               => l_id_patient,
                                                          i_doc_area          => i_id_doc_area,
                                                          i_start_date        => i_begin_date,
                                                          i_end_date          => i_end_date,
                                                          o_doc_area_register => l_doc_area_register,
                                                          o_doc_area_val      => l_cur_doc_area_val_preg,
                                                          o_error             => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        g_error := 'FETCH CURSOR FOR PREGNANCY';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_doc_area_register BULK COLLECT
                INTO l_tbl_pregnancy LIMIT g_limit;
        
            FOR i IN 1 .. l_tbl_pregnancy.count
            LOOP
                IF l_tbl_pregnancy(i).flg_status != pk_pregnancy_core.g_pat_pregn_cancel --verificar
                THEN
                    l_tbl_pregnancy(i).notes := pk_string_utils.trim_empty_lines(i_text => l_tbl_pregnancy(i).notes);
                
                    l_dt_register_tstz    := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           l_tbl_pregnancy(i).dt_register,
                                                                           NULL);
                    l_dt_last_update_tstz := pk_date_utils.get_string_tstz(i_lang,
                                                                           i_prof,
                                                                           l_tbl_pregnancy(i).dt_last_update,
                                                                           NULL);
                
                    io_data_import.extend;
                    io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                         i_pn_data_block,
                                                                         l_tbl_pregnancy(i).notes,
                                                                         l_tbl_pregnancy(i).notes,
                                                                         l_tbl_pregnancy(i).dt_register_chr,
                                                                         l_dt_register_tstz,
                                                                         l_tbl_pregnancy(i).id_professional,
                                                                         l_tbl_pregnancy(i).id_epis_documentation,
                                                                         pk_prog_notes_constants.g_task_ph_obstetric_hist,
                                                                         NULL,
                                                                         (l_tbl_pregnancy(i).n_pregnancy) * -1, --rank
                                                                         l_tbl_pregnancy(i).id_episode, --13                                                                         
                                                                         NULL,
                                                                         l_dt_register_tstz,
                                                                         pk_prog_notes_constants.g_task_ongoing_o,
                                                                         pk_alert_constant.g_yes,
                                                                         NULL,
                                                                         CASE
                                                                         --WHEN i_flg_synchronized = pk_alert_constant.g_no THEN                                                                         
                                                                             WHEN pk_utils.str_token_find(i_string => i_flg_synchronized,
                                                                                                          i_token  => pk_alert_constant.g_no,
                                                                                                          i_sep    => pk_prog_notes_constants.g_sep) =
                                                                                  pk_alert_constant.g_yes THEN
                                                                              l_dt_last_update_tstz
                                                                             ELSE
                                                                              NULL
                                                                         END,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL, --28
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL);
                    l_num_records := l_num_records + 1;
                END IF;
            END LOOP;
            EXIT WHEN l_doc_area_register%NOTFOUND;
        END LOOP;
    
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_past_hist_obstetric;

    /**************************************************************************
    * get import data from selection list option in reported medication functionality
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param io_data_import           Struct with data import information
    * @param io_count_records         Number of records
    *
    * @param o_error                  Error
    *                                                                         
    * @author                         Luis Maia
    * @version                        2.6.2
    * @since                          2012/01/25
    **************************************************************************/
    FUNCTION get_import_med_selection_list
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        io_count_records  IN OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_num_records   NUMBER := 1;
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_MED_SELECTION_LIST';
        l_dt_reg        pk_translation.t_desc_translation;
        --
        l_id_review        PLS_INTEGER;
        l_code_review      PLS_INTEGER;
        l_task_description CLOB;
        l_id_prof_create   professional.id_professional%TYPE;
        l_dt_create        TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_last_update   TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_info_source       CLOB;
        l_pat_not_take      CLOB;
        l_pat_take          CLOB;
        l_notes             CLOB;
        label_pat_take      sys_message.desc_message%TYPE;
        label_pat_not_take  sys_message.desc_message%TYPE;
        label_info_source   sys_message.desc_message%TYPE;
        label_notes         sys_message.desc_message%TYPE;
        l_func_name         VARCHAR2(50 CHAR) := 'get_import_med_selection_list';
        tb_task_description table_varchar := table_varchar();
    BEGIN
    
        g_error := 'PK_API_PFH_CLINDOC_IN.GET_LIST_PRESC_PREVIOUS. i_id_episode: ' || i_id_episode || ' i_id_patient: ' ||
                   i_id_patient || ' i_pn_soap_block: ' || i_pn_soap_block || ' i_pn_data_block: ' || i_pn_data_block ||
                   ' i_begin_date: ' || CAST(i_begin_date AS VARCHAR2) || ' i_end_date: ' ||
                   CAST(i_end_date AS VARCHAR2);
        pk_alertlog.log_debug(g_error);
        --
        IF NOT pk_api_pfh_in.get_last_review(i_lang           => i_lang,
                                             i_prof           => i_prof,
                                             i_id_episode     => i_id_episode,
                                             i_id_patient     => i_id_patient,
                                             i_dt_begin       => i_begin_date,
                                             i_dt_end         => i_end_date,
                                             o_id_review      => l_id_review,
                                             o_code_review    => l_code_review,
                                             o_review_desc    => l_task_description,
                                             o_dt_create      => l_dt_create,
                                             o_dt_update      => l_dt_last_update,
                                             o_id_prof_create => l_id_prof_create,
                                             o_info_source    => l_info_source,
                                             o_pat_not_take   => l_pat_not_take,
                                             o_pat_take       => l_pat_take,
                                             o_notes          => l_notes)
        THEN
            RETURN FALSE;
        END IF;
    
        IF l_code_review IS NOT NULL
           OR l_task_description IS NOT NULL
           OR l_info_source IS NOT NULL
           OR l_pat_not_take IS NOT NULL
           OR l_pat_take IS NOT NULL
           OR l_notes IS NOT NULL
        
        THEN
            l_dt_reg := pk_date_utils.date_char_tsz(i_lang, l_dt_create, i_prof.institution, i_prof.software);
        
            pk_api_pfh_in.pat_take_not_take_label(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  o_pat_take     => label_pat_take,
                                                  o_pat_not_take => label_pat_not_take,
                                                  o_info_source  => label_info_source,
                                                  o_notes        => label_notes);
        
            IF l_task_description IS NOT NULL
            THEN
                tb_task_description.extend;
                tb_task_description(tb_task_description.count) := l_task_description;
            END IF;
        
            IF l_pat_take IS NOT NULL
            THEN
                tb_task_description.extend;
                tb_task_description(tb_task_description.count) := label_pat_take || ': ' || l_pat_take;
            END IF;
        
            IF l_pat_not_take IS NOT NULL
            THEN
                tb_task_description.extend;
                tb_task_description(tb_task_description.count) := label_pat_not_take || ': ' || l_pat_not_take;
            END IF;
        
            IF l_info_source IS NOT NULL
            THEN
                tb_task_description.extend;
                tb_task_description(tb_task_description.count) := label_info_source || ': ' || l_info_source;
            END IF;
        
            IF l_notes IS NOT NULL
            THEN
                tb_task_description.extend;
                tb_task_description(tb_task_description.count) := label_notes || ': ' || l_notes;
            END IF;
        
            l_task_description := pk_utils.concat_table(tb_task_description, '; ', 1, -1);
            l_task_description := pk_string_utils.trim_empty_lines(i_text => l_task_description);
        
            pk_alertlog.log_info(text            => 'l_task_description:' || l_task_description,
                                 object_name     => g_package_name,
                                 sub_object_name => l_func_name);
        
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_task_description,
                                                                 l_task_description,
                                                                 l_dt_reg,
                                                                 l_dt_create,
                                                                 l_id_prof_create,
                                                                 l_id_review,
                                                                 pk_prog_notes_constants.g_task_reported_medic,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_episode, --12                                                                 
                                                                 NULL,
                                                                 l_dt_create,
                                                                 pk_prog_notes_constants.g_task_ongoing_o,
                                                                 pk_alert_constant.g_yes,
                                                                 NULL,
                                                                 l_dt_last_update,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
        END IF;
        io_count_records := io_count_records + l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_med_selection_list;

    /**************************************************************************
    * get import data from guidelines
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_import_guidelines
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_guideline pk_api_guidelines.t_cur_applied_guidelines;
        l_tbl_guideline pk_api_guidelines.t_tbl_applied_guidelines;
        l_num_records   NUMBER := 0;
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_GUIDELINES';
        l_dt_reg        pk_translation.t_desc_translation;
        l_desc          CLOB;
    BEGIN
        g_error := 'CALL PK_API_GUIDELINES.GET_APPLIED_GUIDELINES_LIST';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_api_guidelines.get_applied_guidelines_list(i_lang            => i_lang,
                                                             i_prof            => i_prof,
                                                             i_patient         => i_id_patient,
                                                             i_episode         => i_id_episode,
                                                             i_flg_status      => CASE i_flg_ongoing
                                                                                      WHEN
                                                                                       pk_prog_notes_constants.g_task_ongoing_o THEN
                                                                                       pk_guidelines.g_process_running
                                                                                      WHEN
                                                                                       pk_prog_notes_constants.g_task_finalized_f THEN
                                                                                       pk_guidelines.g_guideline_finished
                                                                                      ELSE
                                                                                       NULL
                                                                                  END,
                                                             o_guidelines_list => l_cur_guideline,
                                                             o_error           => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            g_error := 'FETCH GUIDELINE CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH l_cur_guideline BULK COLLECT
                INTO l_tbl_guideline LIMIT g_limit;
        
            FOR i IN 1 .. l_tbl_guideline.count
            LOOP
            
                IF (l_tbl_guideline(i).guideline_date >= nvl(i_begin_date, l_tbl_guideline(i).guideline_date) AND l_tbl_guideline(i)
                   .guideline_date <= nvl(i_end_date, l_tbl_guideline(i).guideline_date))
                
                THEN
                    l_dt_reg := pk_date_utils.date_char_tsz(i_lang,
                                                            l_tbl_guideline(i).guideline_date,
                                                            i_prof.institution,
                                                            i_prof.software);
                
                    l_desc := l_tbl_guideline(i).guideline_title || ' ' || l_tbl_guideline(i).guideline_type;
                
                    l_desc := pk_string_utils.trim_empty_lines(i_text => l_desc);
                
                    io_data_import.extend;
                    io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                         i_pn_data_block,
                                                                         l_desc,
                                                                         l_desc,
                                                                         l_dt_reg,
                                                                         l_tbl_guideline                          (i).guideline_date,
                                                                         l_tbl_guideline                          (i).id_professional,
                                                                         l_tbl_guideline                          (i).id_guideline_process,
                                                                         pk_prog_notes_constants.g_task_guidelines,
                                                                         NULL,
                                                                         NULL,
                                                                         i_id_episode, --12                                                                        
                                                                         NULL,
                                                                         l_tbl_guideline                          (i).guideline_date,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         l_tbl_guideline                          (i).dt_last_update,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL);
                
                    l_num_records := l_num_records + 1;
                END IF;
            END LOOP;
            EXIT WHEN l_cur_guideline%NOTFOUND;
        END LOOP;
    
        g_error         := 'l_count';
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_guidelines;

    /**************************************************************************
    * get import data from protocol
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_import_protocol
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_protocol  pk_api_protocol.t_cur_applied_protocols;
        l_tbl_protocol  pk_api_protocol.t_tbl_applied_protocols;
        l_num_records   NUMBER := 0;
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_PROTOCOL';
        l_dt_reg        pk_translation.t_desc_translation;
        l_desc          CLOB;
    BEGIN
        g_error := 'CALL PK_API_PROTOCOL.GET_APPLIED_PROTOCOLS_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT
            pk_api_protocol.get_applied_protocols_list(i_lang           => i_lang,
                                                       i_prof           => i_prof,
                                                       i_patient        => i_id_patient,
                                                       i_episode        => i_id_episode,
                                                       i_flg_status     => CASE i_flg_ongoing
                                                                               WHEN pk_prog_notes_constants.g_task_ongoing_o THEN
                                                                                pk_protocol.g_process_running
                                                                               WHEN pk_prog_notes_constants.g_task_finalized_f THEN
                                                                                pk_protocol.g_process_finished
                                                                               ELSE
                                                                                NULL
                                                                           END,
                                                       o_protocols_list => l_cur_protocol,
                                                       o_error          => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            g_error := 'FETCH PROTOCOL CURSOR';
            pk_alertlog.log_debug(g_error);
            FETCH l_cur_protocol BULK COLLECT
                INTO l_tbl_protocol LIMIT g_limit;
        
            FOR i IN 1 .. l_tbl_protocol.count
            LOOP
            
                IF (l_tbl_protocol(i).protocol_date >= nvl(i_begin_date, l_tbl_protocol(i).protocol_date) AND l_tbl_protocol(i)
                   .protocol_date <= nvl(i_end_date, l_tbl_protocol(i).protocol_date))
                
                THEN
                    l_dt_reg := pk_date_utils.date_char_tsz(i_lang,
                                                            l_tbl_protocol(i).protocol_date,
                                                            i_prof.institution,
                                                            i_prof.software);
                
                    l_desc := l_tbl_protocol(i).protocol_title || ' ' || l_tbl_protocol(i).protocol_type;
                
                    l_desc := pk_string_utils.trim_empty_lines(i_text => l_desc);
                
                    io_data_import.extend;
                    io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                         i_pn_data_block,
                                                                         l_desc,
                                                                         l_desc,
                                                                         l_dt_reg,
                                                                         l_tbl_protocol                         (i).protocol_date,
                                                                         l_tbl_protocol                         (i).id_professional,
                                                                         l_tbl_protocol                         (i).id_protocol_process,
                                                                         pk_prog_notes_constants.g_task_protocol,
                                                                         NULL,
                                                                         NULL,
                                                                         i_id_episode, --12                                                                            
                                                                         NULL,
                                                                         l_tbl_protocol                         (i).protocol_date,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         l_tbl_protocol                         (i).dt_last_update,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL);
                
                    l_num_records := l_num_records + 1;
                END IF;
            END LOOP;
            EXIT WHEN l_cur_protocol%NOTFOUND;
        END LOOP;
    
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_protocol;

    /**************************************************************************
    * get import data from care plans
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/10                               
    **************************************************************************/
    FUNCTION get_import_care_plans
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN episode.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_cur_care_plan pk_care_plans_api_db.t_cur_care_plan;
        l_tbl_care_plan pk_care_plans_api_db.t_tbl_care_plan;
        l_num_records   NUMBER := 0;
        l_function_name VARCHAR2(30 CHAR) := 'GET_IMPORT_CARE_PLANS';
        l_exception EXCEPTION;
        l_dt_reg pk_translation.t_desc_translation;
        l_desc   CLOB := NULL;
    BEGIN
    
        g_error := 'CALL PK_CARE_PLANS_API_DB.GET_CARE_PLAN';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_care_plans_api_db.get_care_plan(i_lang       => i_lang,
                                                  i_prof       => i_prof,
                                                  i_id_patient => i_id_patient,
                                                  i_flg_status => CASE i_flg_ongoing
                                                                      WHEN pk_prog_notes_constants.g_task_ongoing_o THEN
                                                                       pk_care_plans.g_inprogress
                                                                      WHEN pk_prog_notes_constants.g_task_finalized_f THEN
                                                                       pk_care_plans.g_finished
                                                                      ELSE
                                                                       NULL
                                                                  END,
                                                  o_care_plan  => l_cur_care_plan,
                                                  o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            g_error := 'FETCH CURSOR FOR CARE PLAN';
            pk_alertlog.log_debug(g_error);
            FETCH l_cur_care_plan BULK COLLECT
                INTO l_tbl_care_plan LIMIT g_limit;
        
            l_num_records := l_num_records + l_tbl_care_plan.count;
            FOR i IN 1 .. l_tbl_care_plan.count
            LOOP
            
                IF (l_tbl_care_plan(i).dt_begin >= nvl(i_begin_date, l_tbl_care_plan(i).dt_begin) AND l_tbl_care_plan(i)
                   .dt_begin <= nvl(i_end_date, l_tbl_care_plan(i).dt_begin))
                THEN
                    l_dt_reg := pk_date_utils.date_char_tsz(i_lang,
                                                            l_tbl_care_plan(i).dt_care_plan,
                                                            i_prof.institution,
                                                            i_prof.software);
                    l_desc   := get_format_string_care_plan(i_lang            => i_lang,
                                                            i_prof            => i_prof,
                                                            i_id_care_plan    => l_tbl_care_plan(i).id_care_plan,
                                                            i_flg_import_date => i_flg_import_date);
                
                    l_desc := pk_string_utils.trim_empty_lines(i_text => l_desc);
                
                    IF l_desc IS NULL
                    THEN
                        l_desc := l_tbl_care_plan(i).name;
                    END IF;
                
                    io_data_import.extend;
                    io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                         i_pn_data_block,
                                                                         l_tbl_care_plan                          (i).name,
                                                                         l_desc,
                                                                         l_dt_reg,
                                                                         l_tbl_care_plan                          (i).dt_care_plan,
                                                                         l_tbl_care_plan                          (i).id_prof,
                                                                         l_tbl_care_plan                          (i).id_care_plan,
                                                                         pk_prog_notes_constants.g_task_care_plans,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL, --13                                                                         
                                                                         NULL,
                                                                         l_tbl_care_plan                          (i).dt_care_plan,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         l_tbl_care_plan                          (i).dt_last_update,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL,
                                                                         NULL);
                
                END IF;
            END LOOP;
            EXIT WHEN l_cur_care_plan%NOTFOUND;
        END LOOP;
    
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_care_plans;

    /**************************************************************************
    * format information about care plan and tasks
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_care_plan           Care plan ID
    * @param i_flg_import_date  Y-date must be imported. N-otherwise
    *
    * return clob with information about care plan and task formatted 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_format_string_care_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_care_plan    IN care_plan.id_care_plan%TYPE,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE
    ) RETURN CLOB IS
    
        l_string              CLOB;
        l_first_record        BOOLEAN := TRUE;
        l_cur_care_plan_tasks pk_care_plans_api_db.t_cur_care_plan_tasks;
        l_tbl_care_plan_tasks pk_care_plans_api_db.t_tbl_care_plan_tasks;
        l_error               t_error_out;
    
    BEGIN
    
        g_error := 'CALL PK_CARE_PLANS_API_DB.GET_CARE_PLAN_TASKS';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_care_plans_api_db.get_care_plan_tasks(i_lang            => i_lang,
                                                        i_prof            => i_prof,
                                                        i_id_care_plan    => i_id_care_plan,
                                                        o_care_plan_tasks => l_cur_care_plan_tasks,
                                                        o_error           => l_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        LOOP
            g_error := 'FETCH CURSOR FOR CARE PLAN';
            pk_alertlog.log_debug(g_error);
            FETCH l_cur_care_plan_tasks BULK COLLECT
                INTO l_tbl_care_plan_tasks LIMIT g_limit;
        
            l_string := l_string || l_tbl_care_plan_tasks(1).name;
        
            l_string := l_string || CASE
                            WHEN l_tbl_care_plan_tasks(1).goals IS NOT NULL THEN
                             chr(10) || pk_prog_notes_constants.g_space || l_tbl_care_plan_tasks(1).goals || chr(10)
                            ELSE
                             chr(10)
                        END;
        
            g_error := 'BUILD STRING WITH CARE PLAN TASKS';
            pk_alertlog.log_debug(g_error);
            FOR i IN 1 .. l_tbl_care_plan_tasks.count
            LOOP
                IF NOT l_first_record
                THEN
                    l_string := l_string || chr(10);
                END IF;
            
                l_string := l_string || CASE
                                WHEN l_tbl_care_plan_tasks(i).task_instructions IS NOT NULL
                                      AND l_tbl_care_plan_tasks(i).notes IS NOT NULL THEN
                                 pk_prog_notes_constants.g_space || l_tbl_care_plan_tasks(i).task_name ||
                                 pk_prog_notes_constants.g_flg_sep || l_tbl_care_plan_tasks(i).task_instructions ||
                                 pk_prog_notes_constants.g_flg_sep || l_tbl_care_plan_tasks(i).notes
                                WHEN l_tbl_care_plan_tasks(i).task_instructions IS NOT NULL
                                      AND l_tbl_care_plan_tasks(i).notes IS NULL THEN
                                 pk_prog_notes_constants.g_space || l_tbl_care_plan_tasks(i).task_name ||
                                 pk_prog_notes_constants.g_flg_sep || l_tbl_care_plan_tasks(i).task_instructions
                                WHEN l_tbl_care_plan_tasks(i).task_instructions IS NULL
                                      AND l_tbl_care_plan_tasks(i).notes IS NOT NULL THEN
                                 pk_prog_notes_constants.g_space || l_tbl_care_plan_tasks(i).task_name ||
                                 pk_prog_notes_constants.g_flg_sep || l_tbl_care_plan_tasks(i).notes
                                WHEN l_tbl_care_plan_tasks(i).task_instructions IS NULL
                                      AND l_tbl_care_plan_tasks(i).notes IS NULL THEN
                                 pk_prog_notes_constants.g_space || l_tbl_care_plan_tasks(i).task_name
                            END;
            
                l_first_record := FALSE;
            
            END LOOP;
            EXIT WHEN l_cur_care_plan_tasks%NOTFOUND;
        END LOOP;
    
        RETURN l_string;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_format_string_care_plan;

    /**************************************************************************
    * format information about problems, allergies and habits
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_problem_desc           Problems' description
    * @param i_problem_status         Problems' status
    * @param i_problem_notes          Problems notes
    *
    * return clob with information about problems formatted 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/09                               
    **************************************************************************/
    FUNCTION get_format_string_problems
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_problem_desc   IN CLOB,
        i_problem_status IN sys_domain.desc_val%TYPE,
        i_problem_notes  IN pat_history_diagnosis.notes%TYPE
    ) RETURN CLOB IS
    
        l_string CLOB;
    
    BEGIN
        IF i_problem_status IS NOT NULL
        THEN
            l_string := i_problem_desc || pk_prog_notes_constants.g_comma || i_problem_status;
        ELSE
            l_string := i_problem_desc;
        END IF;
        IF i_problem_notes IS NOT NULL
        THEN
            l_string := l_string || pk_prog_notes_constants.g_comma || i_problem_notes;
        END IF;
    
        RETURN l_string;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_format_string_problems;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/

    FUNCTION get_import_h_and_p
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_table_rec_pn_texts t_table_rec_pn_texts;
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
        l_pn_texts_count     PLS_INTEGER;
        l_note               CLOB;
    
        l_func_name VARCHAR2(18 CHAR) := 'GET_IMPORT_H_AND_P';
    BEGIN
        --get last signed H&P note  
        g_error := 'CALL k_prog_notes_utils.get_last_note_by_area';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_utils.get_last_note_by_area(i_lang        => i_lang,
                                                         i_prof        => i_prof,
                                                         i_scope       => i_scope,
                                                         i_scope_type  => i_scope_type,
                                                         i_id_pn_area  => 1,
                                                         i_note_status => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                        pk_prog_notes_constants.g_epis_pn_flg_status_f),
                                                         o_id_epis_pn  => l_id_epis_pn,
                                                         o_error       => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (l_id_epis_pn IS NOT NULL)
        THEN
            --get the texts for each soap block of the note
            g_error := 'CALL pk_prog_notes_grids.get_note_block_texts';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
            l_table_rec_pn_texts := pk_prog_notes_grids.get_note_block_texts(i_lang        => i_lang,
                                                                             i_prof        => i_prof,
                                                                             i_note_ids    => table_number(l_id_epis_pn),
                                                                             i_note_status => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                                            pk_prog_notes_constants.g_epis_pn_flg_status_f),
                                                                             i_show_title  => pk_prog_notes_constants.g_show_all,
                                                                             i_flg_detail  => pk_alert_constant.g_no,
                                                                             i_soap_blocks => table_number(43,
                                                                                                           7,
                                                                                                           8,
                                                                                                           9,
                                                                                                           10,
                                                                                                           11,
                                                                                                           12,
                                                                                                           13,
                                                                                                           17) --TODO???!!!
                                                                             );
        
            l_pn_texts_count := l_table_rec_pn_texts.count;
        
            --concat the note texts
            FOR i IN 1 .. l_pn_texts_count
            LOOP
                l_note := l_note || CASE
                              WHEN l_note IS NOT NULL THEN
                               pk_prog_notes_constants.g_new_line || pk_prog_notes_constants.g_new_line
                              ELSE
                               NULL
                          END || l_table_rec_pn_texts(i).soap_block_desc || pk_prog_notes_constants.g_new_line || l_table_rec_pn_texts(i).soap_block_txt;
            END LOOP;
        
            IF (l_note IS NOT NULL)
            THEN
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_note,
                                                                     l_note,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     pk_prog_notes_constants.g_task_handp,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL, --13                                                                         
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
            
                o_count_records := 1;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_h_and_p;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data select s1.username || '@' || s1.machine || ' ( SID=' || s1.sid || ' )  is blocking ' || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status from v$lock l1, v$session s1, v$lock l2, v$session s2 where s1.sid=l1.sid and s2.sid=l2.sid and l1.BLOCK=1 and l2.request > 0 and l1.id1 = l2.id1 and l2.id2 = l2.id2;
    * @param i_flg_filter             Filter to apply
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/

    FUNCTION get_import_single_page_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_filter    IN VARCHAR2,
        i_id_task_type  IN NUMBER DEFAULT pk_prog_notes_constants.g_task_single_page_note,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_table_rec_pn_texts t_table_rec_pn_texts;
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
        l_pn_texts_count     PLS_INTEGER;
        l_note               CLOB;
    
        l_func_name       VARCHAR2(50 CHAR) := 'GET_IMPORT_SINGLE_PAGE_NOTE';
        l_soap_blocks     table_number := table_number();
        l_filter_list     table_varchar := table_varchar();
        l_id_pn_area      pn_area.id_pn_area%TYPE;
        l_soap_blocks_lst table_varchar := table_varchar();
        --l_data_block       pn_data_block.id_pn_data_block%TYPE;
        l_soap_block_count PLS_INTEGER;
        l_filter           pk_translation.t_desc_translation;
        l_id_pn_note_type  pn_note_type.id_pn_note_type%TYPE;
        l_data_blocks_lst  table_varchar := table_varchar();
        l_data_blocks      table_number := table_number();
    BEGIN
    
        IF instr(i_flg_filter, pk_prog_notes_constants.g_action_cp_note_from_note_tp) > 0
        THEN
            BEGIN
                l_filter_list     := pk_string_utils.str_split(i_list => i_flg_filter, i_delim => '-');
                l_filter          := l_filter_list(1);
                l_id_pn_note_type := to_number(l_filter_list(2));
                l_soap_blocks     := NULL;
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        
        ELSIF (instr(i_flg_filter, pk_prog_notes_constants.g_action_copy_note) > 0 OR
              instr(i_flg_filter, pk_prog_notes_constants.g_action_copy_note_no_title) > 0)
        THEN
            BEGIN
                l_filter_list := pk_string_utils.str_split(i_list => i_flg_filter, i_delim => '-');
                l_filter      := l_filter_list(1);
                l_id_pn_area  := to_number(l_filter_list(2));
                IF (l_filter_list.exists(3))
                THEN
                    l_soap_blocks_lst := pk_string_utils.str_split(i_list => l_filter_list(3), i_delim => ';');
                
                    l_soap_block_count := l_soap_blocks_lst.count;
                    FOR i IN 1 .. l_soap_block_count
                    LOOP
                        l_soap_blocks.extend;
                        l_soap_blocks(i) := to_number(l_soap_blocks_lst(i));
                    END LOOP;
                ELSE
                    l_soap_blocks := NULL;
                END IF;
            
                IF (l_filter_list.exists(4))
                THEN
                    l_data_blocks_lst := pk_string_utils.str_split(i_list => l_filter_list(4), i_delim => ';');
                    FOR i IN 1 .. l_data_blocks_lst.count
                    LOOP
                        l_data_blocks.extend;
                        l_data_blocks(i) := to_number(l_data_blocks_lst(i));
                    END LOOP;
                END IF;
            
            EXCEPTION
                WHEN OTHERS THEN
                    NULL;
            END;
        END IF;
    
        IF l_id_pn_area IS NOT NULL
        THEN
            --get last signed H&P note  
            g_error := 'CALL k_prog_notes_utils.get_last_note_by_area';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_prog_notes_utils.get_last_note_by_area(i_lang        => i_lang,
                                                             i_prof        => i_prof,
                                                             i_scope       => i_scope,
                                                             i_scope_type  => i_scope_type,
                                                             i_id_pn_area  => l_id_pn_area,
                                                             i_note_status => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                            pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                            pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                            pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                                                            pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                                                            pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                             o_id_epis_pn  => l_id_epis_pn,
                                                             o_error       => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        ELSIF l_id_pn_note_type IS NOT NULL
        THEN
            IF NOT pk_prog_notes_utils.get_last_note_by_note_type(i_lang            => i_lang,
                                                                  i_prof            => i_prof,
                                                                  i_scope           => i_scope,
                                                                  i_scope_type      => i_scope_type,
                                                                  i_id_pn_note_type => l_id_pn_note_type,
                                                                  i_note_status     => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                                     pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                                                                     pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                                                                     pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                                  o_id_epis_pn      => l_id_epis_pn,
                                                                  o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        IF (l_id_epis_pn IS NOT NULL)
        THEN
            IF (l_data_blocks.count > 0)
            THEN
                FOR i IN 1 .. l_data_blocks.count
                LOOP
                    l_note := l_note || CASE
                                  WHEN l_note IS NOT NULL THEN
                                   pk_prog_notes_constants.g_new_line
                              END || get_data_block_txt(i_id_epis_pn    => l_id_epis_pn,
                                                        i_id_data_block => l_data_blocks(i),
                                                        i_id_soap_block => l_soap_blocks(1));
                END LOOP;
            ELSE
                --get the texts for each soap block of the note
                g_error := 'CALL pk_prog_notes_grids.get_note_block_texts';
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_table_rec_pn_texts := pk_prog_notes_grids.get_note_block_texts(i_lang        => i_lang,
                                                                                 i_prof        => i_prof,
                                                                                 i_note_ids    => table_number(l_id_epis_pn),
                                                                                 i_note_status => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                                                pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                                                pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                                                pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                                                                                pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                                                                                pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                                                 i_show_title  => pk_prog_notes_constants.g_show_all,
                                                                                 i_flg_detail  => pk_alert_constant.g_no,
                                                                                 i_soap_blocks => l_soap_blocks);
            
                l_pn_texts_count := l_table_rec_pn_texts.count;
            
                --concat the note texts
                FOR i IN 1 .. l_pn_texts_count
                LOOP
                    l_note := l_note || CASE
                                  WHEN l_note IS NOT NULL THEN
                                   pk_prog_notes_constants.g_new_line || pk_prog_notes_constants.g_new_line
                                  ELSE
                                   NULL
                              END || CASE
                                  WHEN l_filter = pk_prog_notes_constants.g_action_copy_note
                                       OR l_filter = pk_prog_notes_constants.g_action_cp_note_from_note_tp THEN
                                   l_table_rec_pn_texts(i).soap_block_desc || pk_prog_notes_constants.g_new_line
                                  ELSE
                                   NULL
                              END || l_table_rec_pn_texts(i).soap_block_txt;
                END LOOP;
            
            END IF;
        
            IF (l_note IS NOT NULL)
            THEN
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_note,
                                                                     l_note,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     nvl(i_id_task_type,
                                                                         pk_prog_notes_constants.g_task_single_page_note),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL, --13                                                                         
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
            
                o_count_records := 1;
            END IF;
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_single_page_note;

    /**************************************************************************
    * get import data from the EA table corresponding to the given task type.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task                Task reference ID
    * @param i_id_task_type           Task type ID
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block ID
    * @param i_dt_register            Task registration date ID
    * @param i_code_description       Translation code for task description
    * @param i_id_prof_req            Prof id that requested the task
    * @param i_flg_import_date        Y-Task date should be imported together with the text
    * @param i_code_description       Translation code for task description
    * @param i_universal_desc_clob    Large Description created by the user
    * @param i_id_episode             Episode Id
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_id_group_import        ID to be used to group info when importing by import screen
    * @param i_code_desc_group        Title of the group   
    * @param i_id_sub_group_import    ID to be used to group info when importing by import screen
    * @param i_code_desc_sub_group    Title of the group    
    * @param i_id_task_aggregator     Task Aggregator identifier
    * @param i_id_doc_area            Documentation Area identifier
    * @param i_dt_last_update         Last update date of the task
    * @param i_id_parent_comments     Parent task identifier. To associate a comment to a task
    * @param i_flg_has_notes          There is comments on the task 
    * @param i_calc_task_descs        1-Calc the task descriptions. 0-Otherwise
    * @param i_flg_show_sub_title     Y-show the subtitle (for templates: template name).N-otherwise   
    * @param i_flg_status             Status of the task    
    * @param i_id_sample_type         Sample type id. Only used for analysis results to join to the sub group desc
    * @param i_code_desc_sample_type Sample type code desc. Only used for analysis results to join to the sub group desc
    * @param io_data_import           Struct with data import information
    * @param io_count_records         Number of records
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION set_rec_to_struct
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN patient.id_patient%TYPE,
        i_id_task                IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_type           IN task_timeline_ea.id_tl_task%TYPE,
        i_id_pn_data_block       IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block       IN pn_soap_block.id_pn_soap_block%TYPE,
        i_dt_register            IN task_timeline_ea.dt_req%TYPE,
        i_code_description       IN task_timeline_ea.code_description%TYPE,
        i_universal_desc_clob    IN task_timeline_ea.universal_desc_clob%TYPE,
        i_id_prof_req            IN task_timeline_ea.id_prof_req%TYPE,
        i_flg_import_date        IN pn_dblock_mkt.flg_import_date%TYPE,
        i_id_episode             IN episode.id_episode%TYPE,
        i_flg_group_on_import    IN pn_dblock_mkt.flg_group_on_import%TYPE,
        i_id_group_import        IN NUMBER,
        i_code_desc_group        IN VARCHAR2,
        i_id_sub_group_import    IN NUMBER,
        i_code_desc_sub_group    IN VARCHAR2,
        i_flg_sos                IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin               IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator     IN task_timeline_ea.id_task_aggregator%TYPE,
        i_flg_ongoing            IN task_timeline_ea.flg_ongoing%TYPE,
        i_flg_normal             IN task_timeline_ea.flg_normal%TYPE,
        i_id_prof_exec           IN task_timeline_ea.id_prof_exec%TYPE,
        i_id_doc_area            IN task_timeline_ea.id_doc_area%TYPE,
        i_dt_last_update         IN task_timeline_ea.dt_last_update%TYPE,
        i_id_parent_comments     IN task_timeline_ea.id_parent_comments%TYPE,
        i_flg_has_notes          IN task_timeline_ea.flg_has_comments%TYPE,
        i_dt_task                IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_calc_task_descs        IN PLS_INTEGER,
        i_flg_show_sub_title     IN pn_dblock_mkt.flg_show_sub_title%TYPE,
        i_rank_task              IN task_timeline_ea.rank%TYPE,
        i_id_prof_review         IN epis_pn_det_task.id_prof_review%TYPE,
        i_dt_review              IN epis_pn_det_task.dt_review%TYPE,
        i_code_status            IN task_timeline_ea.code_status%TYPE,
        i_flg_status             IN task_timeline_ea.flg_status_req%TYPE,
        i_end_date               IN task_timeline_ea.dt_end%TYPE,
        i_id_task_notes          IN task_timeline_ea.id_task_notes%TYPE,
        i_id_sample_type         IN task_timeline_ea.id_sample_type%TYPE,
        i_code_desc_sample_type  IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description        IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition  IN pn_dblock_ttp_mkt.description_condition%TYPE,
        i_code_desc_group_parent IN VARCHAR2,
        i_instructions_hash      IN task_timeline_ea.instructions_hash%TYPE,
        i_flg_group_type         IN pn_dblock_mkt.flg_group_type%TYPE,
        io_data_import           IN OUT t_coll_data_import,
        io_count_records         IN OUT PLS_INTEGER,
        io_tasks_groups_by_type  IN OUT NOCOPY pk_prog_notes_types.t_tasks_groups_by_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name VARCHAR2(30 CHAR) := 'SET_REC_TO_STRUCT';
        l_dt_req        VARCHAR2(4000);
        l_desc          CLOB;
        l_detailed_desc CLOB;
    
        l_active       VARCHAR(1 CHAR);
        l_grouped_task VARCHAR2(1 CHAR);
    
    BEGIN
    
        g_error := 'SET TASK TO IMPORT STRUCTURE. id_task: ' || i_id_task || ' id_tl_task: ' || i_id_task_type ||
                   ' i_id_pn_data_block: ' || i_id_pn_data_block || ' i_id_pn_soap_block: ' || i_id_pn_soap_block ||
                   ' i_code_description: ' || i_code_description || ' i_id_prof_req: ' || i_id_prof_req ||
                   ' i_flg_import_date: ' || i_flg_import_date;
        pk_alertlog.log_debug(g_error);
        io_data_import.extend;
    
        --check if the aggregated tasks still are active
        g_error := 'call pk_prog_notes_in.check_active_aggregation';
        pk_alertlog.log_debug(g_error);
        l_active := pk_prog_notes_in.check_active_aggregation(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_id_task_type       => i_id_task_type,
                                                              i_id_task_aggregator => i_id_task_aggregator);
    
        IF (l_active = pk_prog_notes_constants.g_yes)
        THEN
            l_dt_req := pk_date_utils.date_char_tsz(i_lang, i_dt_register, i_prof.institution, i_prof.software);
        
            IF (i_calc_task_descs = 1)
            THEN
            
                IF (i_description_condition IS NULL)
                THEN
                    g_error := 'CALL pk_prog_notes_utils.get_task_groups_by_type. i_id_task_type: ' || i_id_task_type;
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_prog_notes_utils.get_task_groups_by_type(i_lang                  => i_lang,
                                                                       i_prof                  => i_prof,
                                                                       i_id_task_type          => i_id_task_type,
                                                                       i_id_task               => i_id_task,
                                                                       i_id_task_notes         => i_id_task_notes,
                                                                       io_tasks_groups_by_type => io_tasks_groups_by_type,
                                                                       o_grouped_task          => l_grouped_task,
                                                                       o_error                 => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                ELSE
                    l_grouped_task := pk_alert_constant.g_no;
                END IF;
            
                IF (l_grouped_task = pk_alert_constant.g_no)
                THEN
                    g_error := 'call pk_prog_notes_utils.get_task_descs';
                    pk_alertlog.log_debug(g_error);
                    IF NOT pk_prog_notes_utils.get_task_descs(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_id_episode            => i_id_episode,
                                                              i_id_patient            => i_id_patient,
                                                              i_id_task_type          => i_id_task_type,
                                                              i_id_task               => i_id_task,
                                                              i_code_description      => i_code_description,
                                                              i_universal_desc_clob   => i_universal_desc_clob,
                                                              i_flg_sos               => i_flg_sos,
                                                              i_dt_begin              => i_dt_begin,
                                                              i_id_task_aggregator    => i_id_task_aggregator,
                                                              i_id_doc_area           => i_id_doc_area,
                                                              i_code_status           => i_code_status,
                                                              i_flg_status            => i_flg_status,
                                                              i_end_date              => i_end_date,
                                                              i_dt_req                => i_dt_register,
                                                              i_id_task_notes         => i_id_task_notes,
                                                              i_code_desc_sample_type => i_code_desc_sample_type,
                                                              i_flg_description       => i_flg_description,
                                                              i_description_condition => i_description_condition,
                                                              o_short_desc            => l_desc,
                                                              o_detailed_desc         => l_detailed_desc,
                                                              o_error                 => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
            END IF;
            IF l_desc IS NULL
               AND i_id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_chief_compl
            THEN
                g_error := 'call pk_prog_notes_utils.get_task_descs';
                pk_alertlog.log_debug(g_error);
                IF NOT pk_prog_notes_utils.get_task_descs(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => i_id_episode,
                                                          i_id_patient            => i_id_patient,
                                                          i_id_task_type          => i_id_task_type,
                                                          i_id_task               => i_id_task,
                                                          i_code_description      => i_code_description,
                                                          i_universal_desc_clob   => i_universal_desc_clob,
                                                          i_flg_sos               => i_flg_sos,
                                                          i_dt_begin              => i_dt_begin,
                                                          i_id_task_aggregator    => i_id_task_aggregator,
                                                          i_id_doc_area           => i_id_doc_area,
                                                          i_code_status           => i_code_status,
                                                          i_flg_status            => i_flg_status,
                                                          i_end_date              => i_end_date,
                                                          i_dt_req                => i_dt_register,
                                                          i_id_task_notes         => i_id_task_notes,
                                                          i_code_desc_sample_type => i_code_desc_sample_type,
                                                          i_flg_description       => i_flg_description,
                                                          i_description_condition => i_description_condition,
                                                          o_short_desc            => l_desc,
                                                          o_detailed_desc         => l_detailed_desc,
                                                          o_error                 => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
                IF l_desc IS NULL
                THEN
                    RETURN TRUE;
                END IF;
            END IF;
            io_data_import(io_data_import.last) := t_data_import(i_id_pn_soap_block,
                                                                 i_id_pn_data_block,
                                                                 l_desc, -- task description to the import screen
                                                                 l_detailed_desc, -- task that will appear in the more information in case there is not detailed developed yet
                                                                 l_dt_req,
                                                                 i_dt_register,
                                                                 i_id_prof_req,
                                                                 i_id_task,
                                                                 i_id_task_type,
                                                                 CASE
                                                                     WHEN i_id_task_type IN
                                                                          (pk_prog_notes_constants.g_task_templates,
                                                                           pk_prog_notes_constants.g_task_ph_templ,
                                                                           pk_prog_notes_constants.g_task_templates_other_note) THEN
                                                                      pk_touch_option.g_flg_tab_origin_epis_doc
                                                                     ELSE
                                                                      NULL
                                                                 END,
                                                                 i_rank_task, --11                                                                 
                                                                 i_id_episode,
                                                                 i_id_task_aggregator,
                                                                 i_dt_register,
                                                                 i_flg_ongoing,
                                                                 i_flg_normal,
                                                                 i_id_prof_exec,
                                                                 i_dt_last_update,
                                                                 i_id_parent_comments,
                                                                 i_flg_has_notes,
                                                                 i_dt_task,
                                                                 i_flg_show_sub_title,
                                                                 i_flg_group_on_import,
                                                                 i_dt_register,
                                                                 i_id_group_import,
                                                                 i_code_desc_group,
                                                                 NULL,
                                                                 i_id_sub_group_import,
                                                                 i_code_desc_sub_group,
                                                                 NULL --TODO: ver separator
                                                                ,
                                                                 NULL,
                                                                 NULL,
                                                                 i_code_description,
                                                                 i_universal_desc_clob,
                                                                 i_flg_sos,
                                                                 i_dt_begin,
                                                                 i_id_doc_area,
                                                                 i_id_prof_review,
                                                                 i_dt_review,
                                                                 i_code_status,
                                                                 i_end_date,
                                                                 i_id_task_notes,
                                                                 i_flg_status,
                                                                 i_id_sample_type,
                                                                 i_code_desc_sample_type,
                                                                 i_flg_description,
                                                                 i_description_condition,
                                                                 i_code_desc_group_parent,
                                                                 i_instructions_hash,
                                                                 i_flg_group_type);
        
            io_count_records := io_count_records + 1;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
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
    END set_rec_to_struct;

    /**************************************************************************
    * Gets the tasks descriptions by group of tasks.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_episode             Episode Identifier
    * @param i_id_patient             Patient ID
    * @param io_data_import           Struct with data import information
    * @param i_tasks_groups_by_type   Lists of tasks by task type
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_import_group_descs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_tasks_groups_by_type IN pk_prog_notes_types.t_tasks_groups_by_type,
        io_data_import         IN OUT NOCOPY t_coll_data_import,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_IMPORT_GROUP_DESCS';
    
        l_tasks_descs_by_type pk_prog_notes_types.t_tasks_descs_by_type;
        l_import_count        PLS_INTEGER;
        l_desc                CLOB;
        l_desc_long           CLOB;
    BEGIN
    
        g_error := 'CALL pk_prog_notes_utils.get_group_descriptions';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_prog_notes_in.get_group_descriptions(i_lang                 => i_lang,
                                                       i_prof                 => i_prof,
                                                       i_id_episode           => i_id_episode,
                                                       i_id_patient           => i_id_patient,
                                                       i_tasks_groups_by_type => i_tasks_groups_by_type,
                                                       o_tasks_descs_by_type  => l_tasks_descs_by_type,
                                                       o_error                => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        l_import_count := io_data_import.count;
    
        FOR i IN 1 .. l_import_count
        LOOP
            IF (io_data_import(i).id_task_notes IS NOT NULL)
            THEN
                l_desc      := io_data_import(i).task_description;
                l_desc_long := io_data_import(i).task || pk_prog_notes_constants.g_enter;
            ELSE
                l_desc      := NULL;
                l_desc_long := NULL;
            END IF;
        
            g_error := 'CALL pk_prog_notes_utils.get_import_group_desc. id_task_type: ' || io_data_import(i).id_task_type ||
                       ' id_task: ' || io_data_import(i).id_task;
            pk_alertlog.log_info(text => g_error, object_name => g_package_owner, sub_object_name => l_func_name);
            IF NOT pk_prog_notes_utils.get_import_group_desc(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_tasks_descs_by_type => l_tasks_descs_by_type,
                                                             i_id_task_type        => io_data_import(i).id_task_type,
                                                             i_id_task             => io_data_import(i).id_task,
                                                             i_id_task_notes       => io_data_import(i).id_task_notes,
                                                             i_flg_show_sub_title  => io_data_import(i).flg_show_sub_title,
                                                             io_desc               => l_desc,
                                                             io_desc_long          => l_desc_long,
                                                             o_error               => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            IF (l_desc IS NOT NULL OR l_desc_long IS NOT NULL)
            THEN
                IF (l_desc IS NOT NULL)
                THEN
                    io_data_import(i).task_description := l_desc;
                    --io_data_import(i).rank := 
                END IF;
                io_data_import(i).task := l_desc_long;
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
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_import_group_descs;

    FUNCTION is_technical_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN tl_task.id_tl_task%TYPE,
        i_id_task   IN NUMBER
    ) RETURN VARCHAR2 IS
        l_id_exam_req exam_req_det.id_exam_req_det%TYPE;
        l_return      VARCHAR2(1 CHAR);
    BEGIN
        IF i_task_type IN
           (pk_prog_notes_constants.g_task_img_exams_req, pk_prog_notes_constants.g_task_other_exams_req)
        THEN
            l_return := pk_exams_external_api_db.check_technical_exam(i_lang         => i_lang,
                                                                      i_prof         => i_prof,
                                                                      i_exam_req_det => i_id_task);
        ELSIF i_task_type IN (pk_prog_notes_constants.g_task_exam_results,
                              pk_prog_notes_constants.g_task_img_exam_results,
                              pk_prog_notes_constants.g_task_oth_exam_results)
        THEN
        
            BEGIN
                SELECT er.id_exam_req_det
                  INTO l_id_exam_req
                  FROM exam_result er
                 WHERE er.id_exam_result = i_id_task;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_exam_req := NULL;
            END;
        
            IF l_id_exam_req IS NOT NULL
            THEN
                l_return := pk_exams_external_api_db.check_technical_exam(i_lang         => i_lang,
                                                                          i_prof         => i_prof,
                                                                          i_exam_req_det => l_id_exam_req);
            ELSE
                l_return := pk_prog_notes_constants.g_no;
            END IF;
        
        ELSIF i_task_type = pk_prog_notes_constants.g_task_procedures
        THEN
            l_return := pk_procedures_external_api_db.check_technical_procedure(i_lang             => i_lang,
                                                                                i_prof             => i_prof,
                                                                                i_interv_presc_det => i_id_task);
        ELSE
            l_return := pk_prog_notes_constants.g_no;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'N';
    END is_technical_task;

    FUNCTION is_doc_area_sp_available
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_doc_area         IN doc_area.id_doc_area%TYPE,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_summary_page     IN summary_page.id_summary_page%TYPE,
        i_flg_exc_sum_page_da IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_id_market   market.id_market%TYPE;
        l_id_doc_area table_number;
        l_ret         VARCHAR2(1 CHAR);
    BEGIN
        IF i_flg_exc_sum_page_da IS NULL
        THEN
            BEGIN
                SELECT pk_alert_constant.g_yes
                  INTO l_ret
                  FROM summary_page_section sps
                 WHERE sps.id_doc_area = i_id_doc_area
                   AND sps.id_summary_page = i_id_summary_page;
            EXCEPTION
                WHEN no_data_found THEN
                    l_ret := pk_alert_constant.g_no;
            END;
        ELSE
            l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
             id_doc_area
              BULK COLLECT
              INTO l_id_doc_area
              FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof             => i_prof,
                                                              i_market           => l_id_market,
                                                              i_department       => NULL,
                                                              i_dcs              => NULL,
                                                              i_id_pn_note_type  => i_id_pn_note_type,
                                                              i_id_episode       => i_id_episode,
                                                              i_id_pn_data_block => NULL,
                                                              i_software         => NULL)) t
             WHERE t.id_summary_page = i_id_summary_page
               AND id_doc_area IS NOT NULL;
            BEGIN
                SELECT pk_alert_constant.g_no
                  INTO l_ret
                  FROM summary_page_section sps
                 WHERE sps.id_doc_area IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                            column_value
                                             FROM TABLE(l_id_doc_area) t)
                   AND sps.id_summary_page = i_id_summary_page
                   AND sps.id_doc_area = i_id_doc_area;
            EXCEPTION
                WHEN no_data_found THEN
                    BEGIN
                        SELECT pk_alert_constant.g_yes
                          INTO l_ret
                          FROM summary_page_section sps
                         WHERE sps.id_doc_area = i_id_doc_area
                           AND sps.id_summary_page = i_id_summary_page;
                    EXCEPTION
                        WHEN no_data_found THEN
                            l_ret := pk_alert_constant.g_no;
                    END;
            END;
        
        END IF;
        RETURN l_ret;
    END is_doc_area_sp_available;

    /**************************************************************************
    * get import data from the EA table corresponding to the given task type.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_tasks               Task Ids: specific tasks to be synchronized
    * @param i_id_task_types          Task types IDs: specific task types to be synchronized
    * @param i_calc_task_descs        1-Calc the task descriptions. 0-Otherwise
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_import_from_ea
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_tasks        IN table_number,
        i_id_task_types   IN table_number,
        i_calc_task_descs IN PLS_INTEGER DEFAULT 1,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT PLS_INTEGER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name      VARCHAR2(30 CHAR) := 'GET_IMPORT_FROM_EA';
        l_outside_task_type  table_number;
        r_tmp_pn_configs     tmp_pn_configs%ROWTYPE;
        l_num_rep_medication PLS_INTEGER := 0;
        l_yes CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_no  CONSTANT VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    
        l_id_tasks             table_number := i_id_tasks;
        l_id_task_types        table_number := i_id_task_types;
        l_tasks_groups_by_type pk_prog_notes_types.t_tasks_groups_by_type;
        l_id_task              epis_pn_det_task.id_task%TYPE;
    BEGIN
    
        IF (i_id_tasks IS NULL OR NOT i_id_tasks.exists(1))
        THEN
            l_id_tasks := NULL;
        END IF;
    
        IF (i_id_task_types IS NULL OR NOT i_id_task_types.exists(1))
        THEN
            l_id_task_types := NULL;
        END IF;
    
        o_count_records := 0;
    
   /*            FOR i IN (SELECT *
                    FROM tmp_pn_configs)
        LOOP
            pk_alertlog.log_info(text            => ' ID_TASK_TYPE:' || i.id_task_type || ' ID_PN_DATA_BLOCK:' ||
                                                    i.id_pn_data_block || ' ID_PN_SOAP_BLOCK:' || i.id_pn_soap_block ||
                                                    ' ID_DOC_AREA:' || i.id_doc_area || ' ID_PATIENT:' || i.id_patient ||
                                                    ' ID_VISIT:' || i.id_visit || ' ID_EPISODE:' || i.id_episode ||
                                                    ' DT_BEGIN:' || i.dt_begin || ' DT_END:' || i.dt_end ||
                                                    ' FLG_OUTSIDE_PERIOD:' || i.flg_outside_period ||
                                                    ' FLG_IMPORT_DATE:' || i.flg_import_date || ' FLG_GROUP_ON_IMPORT:' ||
                                                    i.flg_group_on_import || ' FLG_SYNCHRONIZED:' || i.flg_synchronized ||
                                                    ' FLG_ONGOING:' || i.flg_ongoing || ' FLG_NORMAL:' || i.flg_normal ||
                                                    ' AUTO_POP_EXEC_PROF_CAT:' || i.auto_pop_exec_prof_cat ||
                                                    ' FLG_FIRST_RECORD:' || i.flg_first_record || ' LAST_NOTE_DATE:' ||
                                                    i.last_note_date || ' FLG_COMMENTS:' || i.flg_comments ||
                                                    ' FLG_SINCE_LAST:' || i.flg_since_last || ' FLG_ONG_EXEC:' ||
                                                    i.flg_ong_exec || ' FLG_NO_NOTE_SL:' || i.flg_no_note_sl ||
                                                    ' ID_SUMMARY_PAGE:' || i.id_summary_page ||
                                                    ' FLG_ACTIONS_AVAILABLE:' || i.flg_actions_available ||
                                                    ' FLG_SHOW_SUB_TITLE:' || i.flg_show_sub_title ||
                                                    ' FLG_REVIEWED_INFO:' || i.flg_reviewed_info || ' FLG_MED_FILTER:' ||
                                                    i.flg_med_filter || ' FLG_LAST_N_RECORDS:' || i.flg_last_n_records ||
                                                    ' LAST_N_RECORDS_NR:' || i.last_n_records_nr || ' REVIEW_CONTEXT:' ||
                                                    i.review_context || ' ID_TASK:' || i.id_task || ' REVIEW_CAT:' ||
                                                    i.review_cat || ' FLG_TECHNICAL:' || i.flg_technical ||
                                                    ' DAYS_AVAILABLE_PERIOD:' || i.days_available_period ||
                                                    ', FLG_TYPE: ' || i.flg_type || ',action:' || i.action,
                                 object_name     => g_package_name,
                                 sub_object_name => l_function_name);
        END LOOP;*/
    
        /*   IF l_id_tasks.exists(1)
        THEN
            FOR i IN 1 .. l_id_tasks.count
            LOOP
                pk_alertlog.log_info(text            => 'l_id_tasks:' || l_id_tasks(i),
                                     object_name     => g_package_name,
                                     sub_object_name => l_function_name);
            END LOOP;
        END IF;
        
        IF i_id_task_types.exists(1)
        THEN
            FOR i IN 1 .. i_id_task_types.count
            LOOP
                pk_alertlog.log_info(text            => 'i_id_task_types:' || i_id_task_types(i),
                                     object_name     => g_package_name,
                                     sub_object_name => l_function_name);
            END LOOP;
        END IF;*/
    
        g_error := 'GET TASKS from EA';
        pk_alertlog.log_debug(g_error);
        FOR rec IN (SELECT t_ttea.*
                      FROM (
                             --in this case should be displayed the items which has no groups
                             SELECT tmp.id_pn_soap_block,
                                     tmp.id_pn_data_block,
                                     t.dt_import,
                                     t.dt_task,
                                     t.id_prof_req,
                                     t.id_task id_task,
                                     t.id_tl_task,
                                     t.code_description,
                                     tmp.flg_import_date,
                                     t.id_episode,
                                     tmp.flg_group_on_import,
                                     t.id_group_import,
                                     t.code_desc_group,
                                     t.dt_execution,
                                     t.id_sub_group_import,
                                     t.code_desc_sub_group,
                                     t.flg_sos,
                                     t.dt_begin,
                                     t.id_task_aggregator,
                                     t.flg_ongoing,
                                     t.flg_normal,
                                     t.id_prof_exec,
                                     tmp.flg_first_record,
                                     tmp.flg_last_n_records,
                                     tmp.last_n_records_nr,
                                     t.id_doc_area,
                                     t.dt_last_update,
                                     t.id_parent_comments,
                                     tmp.flg_show_sub_title,
                                     t.rank,
                                     t.id_sample_type,
                                     t.code_desc_sample_type,
                                     tmp.flg_description,
                                     tmp.description_condition,
                                     t.code_desc_group_parent,
                                     instructions_hash,
                                     tmp.flg_group_type,
                                     row_number() over(PARTITION BY t.id_tl_task ORDER BY t.dt_task ASC) rn,
                                     row_number() over(PARTITION BY t.id_tl_task, tmp.id_pn_soap_block, tmp.id_pn_data_block ORDER BY t.dt_task DESC) rnl,
                                     row_number() over(PARTITION BY t.id_tl_task, tmp.id_pn_soap_block, tmp.id_pn_data_block, t.id_doc_area ORDER BY t.dt_task DESC) rn_area,
                                     row_number() over(PARTITION BY t.id_tl_task, t.id_sub_group_import ORDER BY t.dt_task DESC) rnlsg,
                                     row_number() over(PARTITION BY t.id_tl_task, t.id_group_import ORDER BY t.dt_task DESC) rnlg,
                                     t.universal_desc_clob,
                                     t.flg_has_notes,
                                     t.id_prof_review,
                                     t.dt_review,
                                     t.code_status,
                                     t.dt_end,
                                     t.id_task_notes,
                                     t.flg_status_req,
                                     tmp.action,
                                     tmp.id_pn_note_type_action,
                                     tmp.id_pn_data_block_action
                             
                               FROM v_pn_tasks t
                              INNER JOIN tmp_pn_configs tmp
                                 ON tmp.id_task_type = t.id_tl_task
                                AND (tmp.dt_begin IS NULL OR
                                    pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_id_episode  => t.id_episode,
                                                                        i_id_task     => t.id_task,
                                                                        i_id_tl_task  => t.id_tl_task,
                                                                        i_dt_task_str => tmp.flg_dt_task) >= tmp.dt_begin)
                                AND (tmp.dt_end IS NULL OR
                                    pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                        i_prof        => i_prof,
                                                                        i_id_episode  => t.id_episode,
                                                                        i_id_task     => t.id_task,
                                                                        i_id_tl_task  => t.id_tl_task,
                                                                        i_dt_task_str => tmp.flg_dt_task) <= tmp.dt_end)
                                AND t.id_patient = tmp.id_patient
                                AND (t.id_visit = nvl(tmp.id_visit, t.id_visit) OR t.id_visit IS NULL)
                                AND (t.id_episode = nvl(tmp.id_episode, t.id_episode) OR t.id_episode IS NULL)
                                AND (tmp.id_task = t.id_task OR tmp.id_task IS NULL)
                                AND (l_id_tasks IS NULL OR
                                    (t.id_task IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                                     column_value
                                                      FROM TABLE(l_id_tasks) t)) OR
                                    (t.id_parent_task_refid IN ((SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                                                  column_value
                                                                   FROM TABLE(l_id_tasks) t))))
                                AND (l_id_task_types IS NULL OR
                                    (t.id_tl_task IN (SELECT column_value
                                                         FROM TABLE(l_id_task_types))))
                                   --For surgery request on follow up appointments
                                AND (CASE
                                        WHEN instr(tmp.flg_ongoing, pk_prog_notes_constants.g_ongoing_q) > 0 THEN
                                         CASE
                                             WHEN pk_date_utils.to_char_insttimezone(i_lang, i_prof, t.dt_begin, 'DD-MM-YYYY') >=
                                                  to_char(SYSDATE, 'DD-MM-YYYY') THEN
                                              1
                                             ELSE
                                              0
                                         END
                                        ELSE
                                         1
                                    END) = 1
                                   --
                                AND (instr(tmp.flg_ongoing, t.flg_ongoing) > 0 OR
                                    tmp.flg_ongoing = pk_prog_notes_constants.g_task_not_applicable_n)
                                   --For invasive tasks and chest X Ray exams
                                AND (tmp.flg_technical = pk_prog_notes_constants.g_task_not_applicable_n OR
                                    (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_invasive_u AND
                                    t.flg_technical = l_yes AND
                                    (instr(tmp.flg_ongoing, pk_prog_notes_constants.g_auto_pop_invasive_u) > 0 OR
                                    t.flg_ongoing = pk_prog_notes_constants.g_finalized_f)) OR
                                    (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_chest_xr AND
                                    t.flg_technical = 'X') OR
                                    (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_exam_pathology_pt AND
                                    t.flg_technical = 'P'))
                                   -- For relevant
                                AND (tmp.flg_relevant = pk_prog_notes_constants.g_task_not_applicable_n OR
                                    (tmp.flg_relevant = pk_prog_notes_constants.g_auto_pop_relevant_j AND
                                    (nvl(t.flg_relevant, l_no) = l_yes OR
                                    pk_prog_notes_dblock.is_technical_task(i_lang      => i_lang,
                                                                              i_prof      => i_prof,
                                                                              i_task_type => t.id_tl_task,
                                                                              i_id_task   => t.id_task) = l_yes)))
                                AND (t.flg_has_notes = tmp.flg_comments OR
                                    tmp.flg_comments = pk_prog_notes_constants.g_task_comments_na_i)
                                   -- For stat orders
                                AND ((t.flg_stat IN (pk_prog_notes_constants.g_yes, pk_prog_notes_constants.g_priority_u) AND
                                    tmp.flg_stat = pk_prog_notes_constants.g_stat) OR
                                    (t.flg_stat IN (pk_prog_notes_constants.g_yes, pk_prog_notes_constants.g_priority_u) AND
                                    tmp.flg_stat = pk_prog_notes_constants.g_stat_result) OR
                                    tmp.flg_stat = pk_prog_notes_constants.g_task_not_applicable_n)
                                   --
                                AND (t.flg_normal = tmp.flg_normal OR
                                    tmp.flg_normal = pk_prog_notes_constants.g_task_not_applicable_n)
                                AND (tmp.auto_pop_exec_prof_cat IS NULL OR
                                    t.prof_cat IN
                                    (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                       column_value
                                        FROM TABLE(pk_string_utils.str_split_pos(i_list => tmp.auto_pop_exec_prof_cat)) t))
                                   --
                                AND ((tmp.flg_since_last = pk_prog_notes_constants.g_auto_pop_since_last_p AND
                                    t.dt_task >= nvl(tmp.last_note_date, t.dt_task)) OR
                                    (tmp.flg_since_last = pk_prog_notes_constants.g_task_not_applicable_n))
                                   --Finalized records + Ongoing records with at least one completed execution 
                                   --since the update/creation time of the last note
                                AND (tmp.flg_ong_exec = pk_prog_notes_constants.g_auto_pop_ong_exec_c AND
                                    ((t.dt_last_execution >= nvl(tmp.last_note_date, t.dt_last_execution) AND
                                    t.flg_ongoing = pk_prog_notes_constants.g_task_ongoing_o) OR
                                    t.flg_ongoing = pk_prog_notes_constants.g_task_finalized_f) OR
                                    (tmp.flg_ong_exec = pk_prog_notes_constants.g_task_not_applicable_n))
                                   
                                AND (((tmp.flg_no_note_sl = pk_prog_notes_constants.g_auto_pop_no_note_sl_b AND
                                    t.dt_task >= nvl(tmp.last_note_date, t.dt_task)) OR
                                    (t.flg_has_notes = pk_alert_constant.g_no)) OR
                                    (tmp.flg_no_note_sl = pk_prog_notes_constants.g_task_not_applicable_n))
                                   -- filter by reviewed info in the episode
                                AND ((tmp.flg_reviewed_info = pk_prog_notes_constants.g_auto_pop_reviewed_v AND
                                    pk_prog_notes_in.check_reviewed_record(i_lang         => i_lang,
                                                                             i_prof         => i_prof,
                                                                             i_id_episode   => i_id_episode,
                                                                             i_id_patient   => tmp.id_patient,
                                                                             i_id_task      => t.id_task,
                                                                             i_id_task_type => t.id_tl_task,
                                                                             i_flg_context  => tmp.review_context,
                                                                             i_review_cat   => tmp.review_cat) =
                                    pk_alert_constant.g_yes) OR
                                    (tmp.flg_reviewed_info = pk_prog_notes_constants.g_task_not_applicable_n))
                                   -- Ambulatory prescriptions not originated from home medication prescriptions
                                AND ((tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_no_new_presc_k AND
                                    (NOT EXISTS
                                     (SELECT 1
                                          FROM v_pn_tasks v
                                         WHERE v.id_task_refid = t.id_parent_med
                                           AND v.id_tl_task IN
                                               (pk_prog_notes_constants.g_task_medrec_cont_home_hm,
                                                pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm))))
                                    -- Continue at home that do not generated new prescriptions
                                    OR (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_no_new_presc_z AND
                                    (NOT EXISTS
                                     (SELECT 1
                                             FROM v_pn_tasks v
                                            WHERE v.id_parent_med = t.id_task_refid
                                              AND v.id_tl_task = (pk_prog_notes_constants.g_task_amb_medication))))
                                    
                                    --  Ambulatory prescriptions originated from continue at home
                                    OR
                                    (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_new_prescs_h AND
                                    (EXISTS
                                     (SELECT 1
                                          FROM v_pn_tasks v
                                         WHERE v.id_task_refid = t.id_parent_med
                                           AND v.id_tl_task IN (pk_prog_notes_constants.g_task_medrec_cont_home_hm))))
                                    --
                                    OR
                                    (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_new_prescs_x AND
                                    (EXISTS
                                     (SELECT 1
                                          FROM v_pn_tasks v
                                         WHERE v.id_task_refid = t.id_parent_med
                                           AND v.id_tl_task IN (pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm))))
                                    
                                    --  Finalized records without any child execution performed by a professional from physician category 
                                    -- (To be used in the procedures requests: the request is the parent and each execution is a child record)
                                    -- for procedures executions     
                                    OR (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_fin_execs_e AND
                                    (NOT EXISTS (SELECT 1
                                                        FROM v_pn_tasks v
                                                       WHERE v.id_ref_group = t.id_task_refid
                                                         AND v.id_tl_task = (pk_prog_notes_constants.g_task_procedures_exec)
                                                         AND pk_prof_utils.get_category(i_lang,
                                                                                        profissional(v.id_prof_exec,
                                                                                                     i_prof.institution,
                                                                                                     i_prof.software)) =
                                                             pk_alert_constant.g_cat_type_doc)))
                                    --Records from current institution                      
                                    OR (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_current_institution AND
                                    i_prof.institution = t.id_institution)
                                    --Records from external institution          
                                    OR (tmp.flg_med_filter = pk_prog_notes_constants.g_auto_pop_ext_institution AND
                                    i_prof.institution <> t.id_institution)
                                    
                                    OR (tmp.flg_med_filter = pk_prog_notes_constants.g_task_not_applicable_n))
                                   -- exclude recurrence records
                                AND (NOT (t.id_ref_group IS NOT NULL AND t.id_task_aggregator IS NOT NULL AND
                                     tmp.flg_group_on_import = pk_alert_constant.g_yes))
                                   
                                   --exclude monitoring records
                                AND t.id_tl_task <> pk_prog_notes_constants.g_task_monitoring
                                   --summary pages and id_doc_areas
                                AND (t.id_doc_area IS NULL OR t.id_doc_area = tmp.id_doc_area OR
                                    (tmp.id_summary_page IS NOT NULL AND
                                    (t.id_doc_area IS NOT NULL AND
                                    ((t.id_doc_area = tmp.id_doc_area) OR (tmp.id_doc_area IS NULL))) AND
                                    is_doc_area_sp_available(i_lang                => i_lang,
                                                               i_prof                => i_prof,
                                                               i_id_doc_area         => t.id_doc_area,
                                                               i_id_pn_note_type     => i_id_pn_note_type,
                                                               i_id_episode          => i_id_episode,
                                                               i_id_summary_page     => tmp.id_summary_page,
                                                               i_flg_exc_sum_page_da => tmp.flg_exc_sum_page_da) = l_yes))
                                   -- MTOS SCORE
                                AND (tmp.id_mtos_score IS NULL OR t.id_group_import = tmp.id_mtos_score)
                                   -- split body diagram types
                                AND ((t.flg_type = pk_diagram_new.g_flg_type_others AND
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_bd_others) > 0) OR
                                    (t.flg_type = pk_diagram_new.g_flg_type_neur_assessm AND
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_bd_neur_assessm) > 0) OR
                                    (t.flg_type = pk_diagram_new.g_flg_type_drainage AND
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_bd_drain) > 0) OR
                                    --
                                    tmp.flg_type IS NULL OR
                                    --
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_b_streptococcus) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_b_streptococcus) OR
                                    
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_b_chemo) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_b_chemo) OR
                                    --
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_antibiotic) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_antibiotic) OR
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_non_antibiotic) > 0 AND
                                    (t.flg_type = pk_alert_constant.g_no OR
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_chemotherapy)) OR
                                    --
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_restraint_order) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_restraint_order) OR
                                    
                                    --
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_chemotherapy) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_auto_pop_chemotherapy) OR
                                    ---
                                    (t.id_task = pk_prog_notes_constants.g_task_medic_here AND
                                    tmp.flg_type = pk_prog_notes_constants.g_auto_pop_bd_medical_needs) OR
                                    -- MISS: Modified Injury Severity Score
                                    (t.id_group_import = pk_sev_scores_constant.g_id_score_isstw AND -- ISS for TW: MISS
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_miss) > 0) OR
                                    -- Procedures
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_procedure_gen) > 0 AND
                                    (t.flg_type = pk_prog_notes_constants.g_category_type_p OR t.flg_type IS NULL)) OR
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_procedure_reh) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_category_type_reh) OR
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_procedure_dent) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_category_type_dent) OR
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_procedure_obs) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_category_type_obs) OR
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_auto_pop_procedure_oth) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_category_type_oth) OR
                                    -- opinion
                                    (instr(tmp.flg_type, pk_prog_notes_constants.g_replied_opinion) > 0 AND
                                    t.flg_type = pk_prog_notes_constants.g_replied_opinion) OR
                                    (t.flg_type = 'P' AND
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_primary_diagnosis) > 0) OR
                                    (t.flg_type = 'S' AND
                                    instr(tmp.flg_type, pk_prog_notes_constants.g_secondary_diagnosis) > 0))
                                   
                                   -- Episode problem 
                                AND (t.id_tl_task <> pk_prog_notes_constants.g_task_problems_episode OR
                                    (t.id_tl_task = pk_prog_notes_constants.g_task_problems_episode AND
                                    t.flg_outdated <> 1))
                             
                             UNION ALL
                             SELECT tgroup.*,
                                     row_number() over(PARTITION BY tgroup.id_tl_task ORDER BY tgroup.dt_last_update ASC) rn,
                                     row_number() over(PARTITION BY tgroup.id_tl_task, tgroup.id_pn_soap_block, tgroup.id_pn_data_block ORDER BY tgroup.dt_last_update DESC) rnl,
                                     row_number() over(PARTITION BY tgroup.id_tl_task, tgroup.id_pn_soap_block, tgroup.id_pn_data_block, tgroup.id_doc_area ORDER BY tgroup.dt_last_update DESC) rn_area,
                                     NULL rnlsg,
                                     NULL rnlg,
                                     NULL universal_desc_clob,
                                     NULL flg_has_notes,
                                     NULL id_prof_review,
                                     NULL dt_review,
                                     NULL code_status,
                                     NULL dt_end,
                                     NULL id_task_notes,
                                     NULL flg_status_req,
                                     NULL action,
                                     NULL id_pn_note_type_action,
                                     NULL id_pn_data_block_action
                             --in case of groups the universal_desc_clob is returned as null because if one day we use this field with group
                             --we'll have to join the several universal_desc_clob of the group in some way
                              FROM ( --in this case should only be displayed the groups without aggreagtors (ex: Monitorizations)
                                     SELECT tmp.id_pn_soap_block,
                                             tmp.id_pn_data_block,
                                             t.dt_import,
                                             NULL dt_task,
                                             t.id_prof_req,
                                             t.id_ref_group id_task,
                                             decode(t.id_tl_task,
                                                    pk_prog_notes_constants.g_task_lab,
                                                    pk_prog_notes_constants.g_task_lab_recur,
                                                    pk_prog_notes_constants.g_task_img_exams_req,
                                                    pk_prog_notes_constants.g_task_img_exam_recur,
                                                    pk_prog_notes_constants.g_task_other_exams_req,
                                                    pk_prog_notes_constants.g_task_other_exams_recur,
                                                    id_tl_task) id_tl_task,
                                             decode(t.id_tl_task,
                                                    pk_prog_notes_constants.g_task_monitoring,
                                                    NULL,
                                                    t.code_description) code_description,
                                             tmp.flg_import_date,
                                             t.id_episode,
                                             tmp.flg_group_on_import,
                                             t.id_group_import,
                                             t.code_desc_group,
                                             t.dt_execution,
                                             t.id_sub_group_import,
                                             t.code_desc_sub_group,
                                             t.flg_sos,
                                             decode(t.id_task_aggregator, NULL, t.dt_begin) dt_begin,
                                             t.id_task_aggregator,
                                             NULL flg_ongoing,
                                             NULL flg_normal,
                                             NULL id_prof_exec,
                                             tmp.flg_first_record,
                                             tmp.flg_last_n_records,
                                             tmp.last_n_records_nr,
                                             t.id_doc_area,
                                             MAX(t.dt_last_update) dt_last_update,
                                             t.id_parent_comments,
                                             tmp.flg_show_sub_title,
                                             NULL rank,
                                             NULL id_sample_type,
                                             NULL code_desc_sample_type,
                                             tmp.flg_description,
                                             tmp.description_condition,
                                             t.code_desc_group_parent,
                                             instructions_hash,
                                             tmp.flg_group_type
                                       FROM v_pn_tasks t
                                      INNER JOIN tmp_pn_configs tmp
                                         ON tmp.id_task_type = t.id_tl_task
                                        AND (tmp.dt_begin IS NULL OR pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                                                        i_prof        => i_prof,
                                                                                                        i_id_episode  => t.id_episode,
                                                                                                        i_id_task     => t.id_task,
                                                                                                        i_id_tl_task  => t.id_tl_task,
                                                                                                        i_dt_task_str => tmp.flg_dt_task) >=
                                            tmp.dt_begin)
                                        AND (tmp.dt_end IS NULL OR pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                                                      i_prof        => i_prof,
                                                                                                      i_id_episode  => t.id_episode,
                                                                                                      i_id_task     => t.id_task,
                                                                                                      i_id_tl_task  => t.id_tl_task,
                                                                                                      i_dt_task_str => tmp.flg_dt_task) <=
                                            tmp.dt_end)
                                        AND t.id_patient = tmp.id_patient
                                        AND t.id_visit = nvl(tmp.id_visit, t.id_visit)
                                        AND t.id_episode = nvl(tmp.id_episode, t.id_episode)
                                        AND t.id_ref_group IS NOT NULL
                                        AND t.id_task_aggregator IS NULL
                                           --AND tmp.flg_actions_available = pk_alert_constant.g_no
                                           --the monitoring records are aggregated by id_ref_group
                                           -- this should be reviewed when the vital signs are erformulated
                                        AND t.id_tl_task = pk_prog_notes_constants.g_task_monitoring
                                        AND t.flg_status_req <> pk_monitorization.g_monit_status_draft -- REMOVE DRAFT MONITORIN
                                        AND (t.id_doc_area IS NULL OR t.id_doc_area = tmp.id_doc_area OR
                                            (tmp.id_summary_page IS NOT NULL AND pk_summary_page.is_doc_area_in_summary_page(i_lang            => i_lang,
                                                                                                                              i_prof            => i_prof,
                                                                                                                              i_id_doc_area     => t.id_doc_area,
                                                                                                                              i_id_summary_page => tmp.id_summary_page) =
                                            l_yes))
                                     
                                      GROUP BY tmp.id_pn_soap_block,
                                                tmp.id_pn_data_block,
                                                t.dt_import,
                                                t.id_prof_req,
                                                t.id_ref_group,
                                                t.id_tl_task,
                                                decode(t.id_tl_task,
                                                       pk_prog_notes_constants.g_task_monitoring,
                                                       NULL,
                                                       t.code_description),
                                                tmp.flg_import_date,
                                                t.id_episode,
                                                tmp.flg_group_on_import,
                                                t.id_group_import,
                                                t.code_desc_group,
                                                t.dt_execution,
                                                t.id_sub_group_import,
                                                t.code_desc_sub_group,
                                                t.flg_sos,
                                                decode(t.id_task_aggregator, NULL, t.dt_begin),
                                                t.id_task_aggregator,
                                                tmp.flg_first_record,
                                                tmp.flg_last_n_records,
                                                tmp.last_n_records_nr,
                                                tmp.last_n_records_nr,
                                                t.id_doc_area,
                                                t.id_parent_comments,
                                                tmp.flg_show_sub_title,
                                                tmp.flg_description,
                                                tmp.description_condition,
                                                code_desc_group_parent,
                                                instructions_hash,
                                                tmp.flg_group_type
                                     UNION ALL
                                     --in this case should only be displayed the groups with aggreagtors (ex: Lab Order with recurrence)
                                     SELECT tmp.id_pn_soap_block,
                                             tmp.id_pn_data_block,
                                             MIN(t.dt_import) dt_import,
                                             NULL dt_task,
                                             t.id_prof_req,
                                             t.id_ref_group id_task,
                                             decode(t.id_tl_task,
                                                    pk_prog_notes_constants.g_task_lab,
                                                    pk_prog_notes_constants.g_task_lab_recur,
                                                    pk_prog_notes_constants.g_task_img_exams_req,
                                                    pk_prog_notes_constants.g_task_img_exam_recur,
                                                    pk_prog_notes_constants.g_task_other_exams_req,
                                                    pk_prog_notes_constants.g_task_other_exams_recur,
                                                    id_tl_task) id_tl_task,
                                             t.code_description,
                                             tmp.flg_import_date,
                                             t.id_episode,
                                             tmp.flg_group_on_import,
                                             t.id_group_import,
                                             t.code_desc_group,
                                             t.dt_execution,
                                             t.id_sub_group_import,
                                             t.code_desc_sub_group,
                                             t.flg_sos,
                                             decode(t.id_task_aggregator, NULL, t.dt_begin) dt_begin,
                                             t.id_task_aggregator,
                                             NULL flg_ongoing,
                                             NULL flg_normal,
                                             NULL id_prof_exec,
                                             tmp.flg_first_record,
                                             tmp.flg_last_n_records,
                                             tmp.last_n_records_nr,
                                             t.id_doc_area,
                                             MAX(t.dt_last_update) dt_last_update,
                                             t.id_parent_comments,
                                             tmp.flg_show_sub_title,
                                             NULL rank,
                                             t.id_sample_type,
                                             t.code_desc_sample_type,
                                             tmp.flg_description,
                                             tmp.description_condition,
                                             t.code_desc_group_parent,
                                             instructions_hash,
                                             flg_group_type
                                       FROM v_pn_tasks t
                                      INNER JOIN tmp_pn_configs tmp
                                         ON tmp.id_task_type = t.id_tl_task
                                        AND (tmp.dt_begin IS NULL OR pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                                                        i_prof        => i_prof,
                                                                                                        i_id_episode  => t.id_episode,
                                                                                                        i_id_task     => t.id_task,
                                                                                                        i_id_tl_task  => t.id_tl_task,
                                                                                                        i_dt_task_str => tmp.flg_dt_task) >=
                                            tmp.dt_begin)
                                        AND (tmp.dt_end IS NULL OR pk_prog_notes_utils.get_pn_dt_task(i_lang        => i_lang,
                                                                                                      i_prof        => i_prof,
                                                                                                      i_id_episode  => t.id_episode,
                                                                                                      i_id_task     => t.id_task,
                                                                                                      i_id_tl_task  => t.id_tl_task,
                                                                                                      i_dt_task_str => tmp.flg_dt_task) <=
                                            tmp.dt_end)
                                        AND t.id_patient = tmp.id_patient
                                        AND t.id_visit = nvl(tmp.id_visit, t.id_visit)
                                        AND t.id_episode = nvl(tmp.id_episode, t.id_episode)
                                        AND t.id_ref_group IS NOT NULL
                                        AND t.id_task_aggregator IS NOT NULL
                                        AND tmp.flg_group_on_import = pk_alert_constant.g_yes
                                           --For invasive tasks
                                        AND (tmp.flg_technical = pk_prog_notes_constants.g_task_not_applicable_n OR
                                            (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_invasive_u AND
                                            t.flg_technical = l_yes AND
                                            (instr(tmp.flg_ongoing, pk_prog_notes_constants.g_auto_pop_invasive_u) > 0 OR
                                            t.flg_ongoing = pk_prog_notes_constants.g_finalized_f)) OR
                                            (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_chest_xr AND
                                            t.flg_technical = 'X'))
                                           --For x-ray chest image results tasks
                                           /*AND (tmp.flg_technical = pk_prog_notes_constants.g_task_not_applicable_n OR
                                           (tmp.flg_technical = pk_prog_notes_constants.g_auto_pop_chest_xr AND
                                           t.flg_technical = 'X'))*/
                                           --For relevant tasks
                                        AND (tmp.flg_relevant = pk_prog_notes_constants.g_task_not_applicable_n OR
                                            (tmp.flg_relevant = pk_prog_notes_constants.g_auto_pop_relevant_j AND
                                            (nvl(t.flg_relevant, l_no) = l_yes OR
                                            pk_prog_notes_dblock.is_technical_task(i_lang      => i_lang,
                                                                                      i_prof      => i_prof,
                                                                                      i_task_type => t.id_tl_task,
                                                                                      i_id_task   => t.id_task) = l_yes)))
                                        AND (t.id_doc_area IS NULL OR t.id_doc_area = tmp.id_doc_area OR
                                            (tmp.id_summary_page IS NOT NULL AND pk_summary_page.is_doc_area_in_summary_page(i_lang            => i_lang,
                                                                                                                              i_prof            => i_prof,
                                                                                                                              i_id_doc_area     => t.id_doc_area,
                                                                                                                              i_id_summary_page => tmp.id_summary_page) =
                                            l_yes))
                                      GROUP BY tmp.id_pn_soap_block,
                                                tmp.id_pn_data_block,
                                                t.id_prof_req,
                                                t.id_ref_group,
                                                t.id_tl_task,
                                                t.code_description,
                                                tmp.flg_import_date,
                                                t.id_episode,
                                                tmp.flg_group_on_import,
                                                t.id_group_import,
                                                t.code_desc_group,
                                                t.dt_execution,
                                                t.id_sub_group_import,
                                                t.code_desc_sub_group,
                                                t.flg_sos,
                                                decode(t.id_task_aggregator, NULL, t.dt_begin),
                                                t.id_task_aggregator,
                                                tmp.flg_first_record,
                                                tmp.flg_last_n_records,
                                                tmp.last_n_records_nr,
                                                t.id_doc_area,
                                                t.id_parent_comments,
                                                tmp.flg_show_sub_title,
                                                t.id_sample_type,
                                                t.code_desc_sample_type,
                                                tmp.flg_description,
                                                tmp.description_condition,
                                                code_desc_group_parent,
                                                instructions_hash,
                                                flg_group_type) tgroup) t_ttea
                     WHERE (t_ttea.flg_first_record = pk_alert_constant.g_no OR
                           t_ttea.flg_first_record = pk_alert_constant.g_yes AND t_ttea.rn = 1)
                       AND (t_ttea.flg_last_n_records = pk_alert_constant.g_no OR
                           (t_ttea.flg_last_n_records = pk_prog_notes_constants.g_auto_pop_last_record_l AND
                           t_ttea.rnl <= t_ttea.last_n_records_nr) OR
                           (t_ttea.flg_last_n_records = pk_prog_notes_constants.g_auto_pop_last_rec_subg_s AND
                           t_ttea.rnlsg <= t_ttea.last_n_records_nr) OR
                           (t_ttea.flg_last_n_records = pk_prog_notes_constants.g_auto_pop_last_rec_gr_g AND
                           t_ttea.rnlg <= t_ttea.last_n_records_nr) OR
                           (t_ttea.flg_last_n_records = pk_prog_notes_constants.g_auto_pop_last_record_area AND
                           t_ttea.rn_area <= t_ttea.last_n_records_nr))
                       AND check_import_task_type(i_lang, i_prof, t_ttea.id_tl_task, t_ttea.id_task) = 1
                     ORDER BY t_ttea.id_pn_soap_block, t_ttea.id_pn_data_block, t_ttea.id_tl_task)
        LOOP
        
            /*            pk_alertlog.log_info(text            => 'LOOP task: ' || rec.id_tl_task || ' data: ' ||
                                                    rec.id_pn_data_block || ' soap: ' || rec.id_pn_soap_block,
                                 object_name     => g_package_name,
                                 sub_object_name => l_function_name);
            */
            --when flg_action is not 'N' check the apropriate action to perform over the task begin imported
            IF (rec.action IS NOT NULL)
            THEN
                g_error := 'Call set_action_import_data';
                IF NOT set_action_import_data(i_lang                    => i_lang,
                                              i_prof                    => i_prof,
                                              i_id_task                 => rec.id_task,
                                              i_id_task_type            => rec.id_tl_task,
                                              i_id_episode              => i_id_episode,
                                              i_action                  => rec.action,
                                              i_id_pn_note_type_action  => rec.id_pn_note_type_action,
                                              i_id_pn_data_block_action => rec.id_pn_data_block_action,
                                              i_epis_pn                 => i_epis_pn,
                                              o_id_task_to_import       => l_id_task,
                                              o_error                   => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSE
                l_id_task := rec.id_task;
            END IF;
        
            IF (l_id_task IS NOT NULL)
            THEN
                g_error := 'CALL set_rec_to_struct';
                --        pk_alertlog.log_debug(g_error);
                IF NOT set_rec_to_struct(i_lang                   => i_lang,
                                         i_prof                   => i_prof,
                                         i_id_patient             => i_id_patient,
                                         i_id_task                => l_id_task,
                                         i_id_task_type           => rec.id_tl_task,
                                         i_id_pn_data_block       => rec.id_pn_data_block,
                                         i_id_pn_soap_block       => rec.id_pn_soap_block,
                                         i_dt_register            => rec.dt_import,
                                         i_code_description       => rec.code_description,
                                         i_universal_desc_clob    => rec.universal_desc_clob,
                                         i_id_prof_req            => rec.id_prof_req,
                                         i_flg_import_date        => rec.flg_import_date,
                                         i_id_episode             => rec.id_episode,
                                         i_flg_group_on_import    => rec.flg_group_on_import,
                                         i_id_group_import        => rec.id_group_import,
                                         i_code_desc_group        => rec.code_desc_group,
                                         i_id_sub_group_import    => rec.id_sub_group_import,
                                         i_code_desc_sub_group    => rec.code_desc_sub_group,
                                         i_flg_sos                => rec.flg_sos,
                                         i_dt_begin               => rec.dt_begin,
                                         i_id_task_aggregator     => rec.id_task_aggregator,
                                         i_flg_ongoing            => rec.flg_ongoing,
                                         i_flg_normal             => rec.flg_normal,
                                         i_id_prof_exec           => rec.id_prof_exec,
                                         i_id_doc_area            => rec.id_doc_area,
                                         i_dt_last_update         => rec.dt_last_update,
                                         i_id_parent_comments     => rec.id_parent_comments,
                                         i_flg_has_notes          => rec.flg_has_notes,
                                         i_dt_task                => rec.dt_task,
                                         i_calc_task_descs        => i_calc_task_descs,
                                         i_flg_show_sub_title     => rec.flg_show_sub_title,
                                         i_rank_task              => rec.rank,
                                         io_data_import           => io_data_import,
                                         io_count_records         => o_count_records,
                                         io_tasks_groups_by_type  => l_tasks_groups_by_type,
                                         i_id_prof_review         => rec.id_prof_review,
                                         i_dt_review              => rec.dt_review,
                                         i_code_status            => rec.code_status,
                                         i_flg_status             => rec.flg_status_req,
                                         i_end_date               => rec.dt_end,
                                         i_id_task_notes          => rec.id_task_notes,
                                         i_id_sample_type         => rec.id_sample_type,
                                         i_code_desc_sample_type  => rec.code_desc_sample_type,
                                         i_flg_description        => rec.flg_description,
                                         i_description_condition  => rec.description_condition,
                                         i_code_desc_group_parent => rec.code_desc_group_parent,
                                         i_instructions_hash      => rec.instructions_hash,
                                         i_flg_group_type         => rec.flg_group_type,
                                         o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END IF;
        END LOOP;
    
        --check the areas configured to have an outside period that does not have any record in the previous get
        g_error := 'GET areas that need to get data from the outside period ';
        --      pk_alertlog.log_debug(g_error);
        SELECT tc.id_task_type
          BULK COLLECT
          INTO l_outside_task_type
          FROM tmp_pn_configs tc
         WHERE tc.flg_outside_period = pk_alert_constant.g_yes
           AND NOT EXISTS (SELECT *
                  FROM TABLE(io_data_import) t
                 WHERE t.id_task_type = tc.id_task_type);
    
        DELETE FROM tbl_temp;
        insert_tbl_temp(i_num_1 => l_outside_task_type);
    
        IF (l_outside_task_type IS NOT NULL AND l_outside_task_type.exists(1))
        THEN
            g_error := 'GET outside period records';
            --           pk_alertlog.log_debug(g_error);
            FOR rec IN (SELECT *
                          FROM (SELECT *
                                  FROM (SELECT rank() over(PARTITION BY ttea.id_tl_task ORDER BY ttea.dt_task DESC) rank_line,
                                               ttea.dt_task,
                                               ttea.dt_import,
                                               ttea.id_prof_req,
                                               nvl(ttea.id_ref_group, ttea.id_task) id_task,
                                               ttea.id_tl_task,
                                               ttea.code_description,
                                               tmp.id_pn_data_block,
                                               tmp.id_pn_soap_block,
                                               tmp.flg_import_date,
                                               ttea.id_episode,
                                               tmp.flg_group_on_import,
                                               ttea.id_group_import,
                                               ttea.code_desc_group,
                                               ttea.id_sub_group_import,
                                               ttea.code_desc_sub_group,
                                               ttea.flg_sos,
                                               decode(ttea.id_task_aggregator, NULL, ttea.dt_begin) dt_begin,
                                               ttea.id_task_aggregator,
                                               ttea.flg_ongoing,
                                               ttea.flg_normal,
                                               ttea.id_prof_exec,
                                               ttea.universal_desc_clob,
                                               ttea.id_doc_area,
                                               ttea.dt_last_update,
                                               ttea.id_parent_comments,
                                               ttea.flg_has_notes,
                                               tmp.flg_show_sub_title,
                                               ttea.rank,
                                               ttea.id_prof_review,
                                               ttea.dt_review,
                                               ttea.code_status,
                                               ttea.dt_end,
                                               ttea.id_task_notes,
                                               ttea.flg_status_req,
                                               ttea.id_sample_type,
                                               ttea.code_desc_sample_type,
                                               tmp.flg_description,
                                               tmp.description_condition,
                                               ttea.code_desc_group_parent,
                                               instructions_hash,
                                               tmp.flg_group_type
                                          FROM v_pn_tasks ttea
                                          JOIN tmp_pn_configs tmp
                                            ON tmp.id_task_type = ttea.id_tl_task
                                           AND ttea.id_patient = tmp.id_patient
                                           AND ttea.id_visit = nvl(tmp.id_visit, ttea.id_visit)
                                           AND ttea.id_episode = nvl(tmp.id_episode, ttea.id_episode)
                                           AND ttea.id_ref_group IS NULL
                                          JOIN tbl_temp tasks
                                            ON tasks.num_1 = ttea.id_tl_task
                                           AND tasks.num_1 = tmp.id_task_type
                                           AND (ttea.id_doc_area IS NULL OR ttea.id_doc_area = tmp.id_doc_area))
                                 WHERE rank_line = 1
                                UNION ALL
                                --in case should only be displayed the groups (ex: Monitorizations)
                                SELECT *
                                  FROM (SELECT rank() over(PARTITION BY t.id_tl_task ORDER BY t.dt_task DESC) rank_line,
                                               t.*
                                          FROM (SELECT DISTINCT ttea.dt_task,
                                                                ttea.dt_import,
                                                                ttea.id_prof_req,
                                                                ttea.id_ref_group id_task,
                                                                decode(ttea.id_tl_task,
                                                                       pk_prog_notes_constants.g_task_lab,
                                                                       pk_prog_notes_constants.g_task_lab_recur,
                                                                       pk_prog_notes_constants.g_task_img_exams_req,
                                                                       pk_prog_notes_constants.g_task_img_exam_recur,
                                                                       pk_prog_notes_constants.g_task_other_exams_req,
                                                                       pk_prog_notes_constants.g_task_other_exams_recur,
                                                                       ttea.id_tl_task) id_tl_task,
                                                                decode(ttea.id_tl_task,
                                                                       pk_prog_notes_constants.g_task_monitoring,
                                                                       NULL,
                                                                       ttea.code_description) code_description,
                                                                tmp.id_pn_data_block,
                                                                tmp.id_pn_soap_block,
                                                                tmp.flg_import_date,
                                                                ttea.id_episode,
                                                                tmp.flg_group_on_import,
                                                                ttea.id_group_import,
                                                                ttea.code_desc_group,
                                                                ttea.id_sub_group_import,
                                                                ttea.code_desc_sub_group,
                                                                ttea.flg_sos,
                                                                ttea.dt_begin,
                                                                ttea.id_task_aggregator,
                                                                ttea.flg_ongoing,
                                                                ttea.flg_normal,
                                                                ttea.id_prof_exec,
                                                                NULL universal_desc_clob,
                                                                ttea.id_doc_area,
                                                                ttea.dt_last_update,
                                                                ttea.id_parent_comments,
                                                                ttea.flg_has_notes,
                                                                tmp.flg_show_sub_title,
                                                                NULL rank,
                                                                NULL id_prof_review,
                                                                NULL dt_review,
                                                                NULL code_status,
                                                                NULL dt_end,
                                                                NULL id_task_notes,
                                                                NULL flg_status_req,
                                                                NULL id_sample_type,
                                                                NULL code_desc_sample_type,
                                                                tmp.flg_description,
                                                                tmp.description_condition,
                                                                ttea.code_desc_group_parent,
                                                                instructions_hash,
                                                                tmp.flg_group_type
                                                  FROM v_pn_tasks ttea
                                                  JOIN tmp_pn_configs tmp
                                                    ON tmp.id_task_type = ttea.id_tl_task
                                                   AND ttea.id_patient = tmp.id_patient
                                                   AND ttea.id_visit = nvl(tmp.id_visit, ttea.id_visit)
                                                   AND ttea.id_episode = nvl(tmp.id_episode, ttea.id_episode)
                                                   AND ttea.id_ref_group IS NOT NULL
                                                  JOIN tbl_temp tasks
                                                    ON tasks.num_1 = ttea.id_tl_task
                                                   AND tasks.num_1 = tmp.id_task_type) t)
                                 WHERE rank_line = 1)
                         ORDER BY id_tl_task)
            LOOP
                g_error := 'CALL set_rec_to_struct';
                --                pk_alertlog.log_debug(g_error);
                IF NOT set_rec_to_struct(i_lang                   => i_lang,
                                         i_prof                   => i_prof,
                                         i_id_patient             => i_id_patient,
                                         i_id_task                => rec.id_task,
                                         i_id_task_type           => rec.id_tl_task,
                                         i_id_pn_data_block       => rec.id_pn_data_block,
                                         i_id_pn_soap_block       => rec.id_pn_soap_block,
                                         i_dt_register            => rec.dt_import,
                                         i_code_description       => rec.code_description,
                                         i_universal_desc_clob    => rec.universal_desc_clob,
                                         i_id_prof_req            => rec.id_prof_req,
                                         i_flg_import_date        => rec.flg_import_date,
                                         i_flg_group_on_import    => rec.flg_group_on_import,
                                         i_id_episode             => rec.id_episode,
                                         i_id_group_import        => rec.id_group_import,
                                         i_code_desc_group        => rec.code_desc_group,
                                         i_id_sub_group_import    => rec.id_sub_group_import,
                                         i_code_desc_sub_group    => rec.code_desc_sub_group,
                                         i_flg_sos                => rec.flg_sos,
                                         i_dt_begin               => rec.dt_begin,
                                         i_id_task_aggregator     => rec.id_task_aggregator,
                                         i_flg_ongoing            => rec.flg_ongoing,
                                         i_flg_normal             => rec.flg_normal,
                                         i_id_prof_exec           => rec.id_prof_exec,
                                         i_id_doc_area            => rec.id_doc_area,
                                         i_dt_last_update         => rec.dt_last_update,
                                         i_id_parent_comments     => rec.id_parent_comments,
                                         i_flg_has_notes          => rec.flg_has_notes,
                                         i_dt_task                => rec.dt_task,
                                         i_calc_task_descs        => i_calc_task_descs,
                                         i_flg_show_sub_title     => rec.flg_show_sub_title,
                                         i_rank_task              => rec.rank,
                                         i_id_prof_review         => rec.id_prof_review,
                                         i_dt_review              => rec.dt_review,
                                         i_code_status            => rec.code_status,
                                         i_flg_status             => rec.flg_status_req,
                                         i_end_date               => rec.dt_end,
                                         i_id_task_notes          => rec.id_task_notes,
                                         i_id_sample_type         => rec.id_sample_type,
                                         i_code_desc_sample_type  => rec.code_desc_sample_type,
                                         i_flg_description        => rec.flg_description,
                                         i_description_condition  => rec.description_condition,
                                         i_code_desc_group_parent => rec.code_desc_group_parent,
                                         i_instructions_hash      => rec.instructions_hash,
                                         i_flg_group_type         => rec.flg_group_type,
                                         io_data_import           => io_data_import,
                                         io_count_records         => o_count_records,
                                         io_tasks_groups_by_type  => l_tasks_groups_by_type,
                                         o_error                  => o_error)
                THEN
                    RAISE g_other_exception;
                END IF;
            END LOOP;
        END IF;
    
        BEGIN
            g_error := 'get the config to the reported medication';
            --           alertlog.pk_alertlog.log_debug(g_error);
            SELECT tc.*
              INTO r_tmp_pn_configs
              FROM tmp_pn_configs tc
             WHERE tc.id_task_type = pk_prog_notes_constants.g_task_reported_medic
               AND tc.id_task IS NULL
               AND rownum = 1;
        
            g_error := 'call to pk_prog_notes_dblock.get_import_reported_medication';
            alertlog.pk_alertlog.log_debug(g_error);
            IF NOT get_import_med_selection_list(i_lang            => i_lang,
                                                 i_prof            => i_prof,
                                                 i_id_episode      => nvl(r_tmp_pn_configs.id_episode, i_id_episode),
                                                 i_id_patient      => r_tmp_pn_configs.id_patient,
                                                 i_pn_soap_block   => r_tmp_pn_configs.id_pn_soap_block,
                                                 i_pn_data_block   => r_tmp_pn_configs.id_pn_data_block,
                                                 i_begin_date      => r_tmp_pn_configs.dt_begin,
                                                 i_end_date        => r_tmp_pn_configs.dt_end,
                                                 i_flg_import_date => r_tmp_pn_configs.flg_import_date,
                                                 io_data_import    => io_data_import,
                                                 io_count_records  => o_count_records,
                                                 o_error           => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        IF (i_calc_task_descs = 1)
        THEN
            g_error := 'CALL GET_IMPORT_GROUP_DESCS';
            pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_function_name);
            IF NOT get_import_group_descs(i_lang                 => i_lang,
                                          i_prof                 => i_prof,
                                          i_id_episode           => i_id_episode,
                                          i_id_patient           => i_id_patient,
                                          io_data_import         => io_data_import,
                                          i_tasks_groups_by_type => l_tasks_groups_by_type,
                                          o_error                => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
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
    END get_import_from_ea;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Paulo Teixeira                   
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/
    FUNCTION get_import_visit_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_scope                 IN NUMBER,
        i_scope_type            IN VARCHAR2,
        i_pn_soap_block         IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block         IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL,
        io_data_import          IN OUT t_coll_data_import,
        o_count_records         OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note       CLOB;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_IMPORT_VISIT_INFO';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get visit info
        g_error := 'CALL k_prog_notes_utils.get_last_note_by_area';
        pk_alertlog.log_debug(g_error);
        IF i_id_pn_task_type = pk_prog_notes_constants.g_task_visit_info_amb
        THEN
            l_note := pk_prog_notes_in.get_visit_info_amb(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => l_id_episode,
                                                          i_flg_description       => i_flg_description,
                                                          i_description_condition => i_description_condition);
        ELSIF i_id_pn_task_type = pk_prog_notes_constants.g_task_visit_info_inp
        THEN
            l_note := pk_prog_notes_in.get_visit_info_inp(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => l_id_episode,
                                                          i_flg_description       => i_flg_description,
                                                          i_description_condition => i_description_condition);
        ELSIF i_id_pn_task_type = pk_prog_notes_constants.g_task_visit_info_edis
        THEN
            l_note := pk_prog_notes_in.get_visit_info_edis(i_lang                  => i_lang,
                                                           i_prof                  => i_prof,
                                                           i_id_episode            => l_id_episode,
                                                           i_flg_description       => i_flg_description,
                                                           i_description_condition => i_description_condition);
        END IF;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_visit_info;

    /*
    * get import data from admissions days
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita                  
    * @version                        2.8.0.2                             
    * @since                          16-10-2020                            
    */
    FUNCTION get_import_admission_days
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note       VARCHAR2(4000 CHAR);
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_IMPORT_ADMISSION_DAYS';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get admission days
        g_error := 'CALL k_prog_notes_utils.get_admission_days';
        pk_alertlog.log_debug(g_error);
    
        l_note := pk_prog_notes_in.get_admission_days(i_lang => i_lang, i_prof => i_prof, i_id_episode => l_id_episode);
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_admission_days;
    /**************************************************************************
    * Get import data from child development and nutrition
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Anna Kurowska                     
    * @version                        2.6.3                            
    * @since                          30-Jan-2013                            
    **************************************************************************/
    FUNCTION get_import_child_dev_feed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      CLOB;
        l_flg_type  child_feed_dev.flg_type%TYPE;
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_CHILD_DEV_FEED';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
    
        -- check flg_type value
        IF i_id_pn_task_type = pk_prog_notes_constants.g_task_dev_first_yr
        THEN
            l_flg_type := pk_child.g_dev;
        ELSIF i_id_pn_task_type = pk_prog_notes_constants.g_task_nutr_first_yr
        THEN
            l_flg_type := pk_child.g_food;
        END IF;
    
        g_error := 'CALL pk_child.get_child_det_desc';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_child.get_child_det_desc(i_lang       => i_lang,
                                           i_prof       => i_prof,
                                           i_id_patient => i_id_patient,
                                           i_flg_type   => l_flg_type,
                                           o_desc       => l_note,
                                           o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_child_dev_feed;

    /**************************************************************************
    * Function that indicate if the task type should be imported
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_tl_task             Task type ID
    * @param i_id_task                Task type transaccional ID
    *                                                                         
    * @author                         VAnessa Barsottelli
    * @version                        2.6.4                            
    * @since                          28-Out-2014                            
    **************************************************************************/
    FUNCTION check_import_task_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task    IN task_timeline_ea.id_task_refid%TYPE
    ) RETURN NUMBER IS
        l_count NUMBER(12);
    BEGIN
        CASE
            WHEN i_id_tl_task IN
                 (pk_prog_notes_constants.g_task_diagnosis,
                  pk_prog_notes_constants.g_task_final_diag /*,
                                                                                                                                                                                                                      pk_prog_notes_constants.g_task_problems_diag*/) THEN
                --Diagnosis
                SELECT COUNT(1)
                  INTO l_count
                  FROM TABLE(pk_terminology_search.tf_get_valid_diagnoses(i_lang               => i_lang,
                                                                          i_prof               => i_prof,
                                                                          i_tbl_epis_diagnosis => table_number(i_id_task)));
            
            WHEN i_id_tl_task = pk_prog_notes_constants.g_task_ph_cong_anomalies THEN
                --Congenital anomalies (birth history)
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT COUNT(1)
                          FROM TABLE(pk_terminology_search.tf_get_valid_cong_anomalies(i_lang                  => i_lang,
                                                                                       i_prof                  => i_prof,
                                                                                       i_tbl_transaccional_ids => table_number(i_id_task)))
                        UNION ALL
                        SELECT 1
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_pat_history_diagnosis = i_id_task
                           AND phd.id_diagnosis IN (pk_past_history.g_diag_none,
                                                    pk_past_history.g_diag_non_remark,
                                                    pk_past_history.g_diag_unknown));
            WHEN i_id_tl_task = pk_prog_notes_constants.g_task_ph_medical_hist THEN
                --Past medical history
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT COUNT(1)
                          FROM TABLE(pk_terminology_search.tf_get_valid_past_medical_hist(i_lang                  => i_lang,
                                                                                          i_prof                  => i_prof,
                                                                                          i_tbl_transaccional_ids => table_number(i_id_task)))
                        UNION ALL
                        SELECT 1
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_pat_history_diagnosis = i_id_task
                           AND phd.id_diagnosis IN (pk_past_history.g_diag_none,
                                                    pk_past_history.g_diag_non_remark,
                                                    pk_past_history.g_diag_unknown));
            WHEN i_id_tl_task = pk_prog_notes_constants.g_task_ph_surgical_hist THEN
                --Surgical history
                SELECT COUNT(1)
                  INTO l_count
                  FROM (SELECT COUNT(1)
                          FROM TABLE(pk_terminology_search.tf_get_valid_past_surgic_hist(i_lang                  => i_lang,
                                                                                         i_prof                  => i_prof,
                                                                                         i_tbl_transaccional_ids => table_number(i_id_task)))
                        UNION ALL
                        SELECT 1
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_pat_history_diagnosis = i_id_task
                           AND phd.id_diagnosis IN (pk_past_history.g_diag_none,
                                                    pk_past_history.g_diag_non_remark,
                                                    pk_past_history.g_diag_unknown));
            WHEN i_id_tl_task = pk_prog_notes_constants.g_task_problems THEN
                --Problems
                SELECT COUNT(*)
                  INTO l_count
                  FROM (SELECT 1
                          FROM TABLE(pk_terminology_search.tf_get_valid_problems(i_lang                  => i_lang,
                                                                                 i_prof                  => i_prof,
                                                                                 i_tbl_transaccional_ids => table_number(i_id_task)))
                        UNION ALL
                        SELECT 1
                          FROM pat_history_diagnosis phd
                         WHERE phd.id_pat_history_diagnosis = i_id_task);
            ELSE
                l_count := 1;
        END CASE;
    
        IF l_count > 1
        THEN
            l_count := 1;
        END IF;
    
        RETURN l_count;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 1;
    END check_import_task_type;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.1.0                            
    * @since                          27/04/2017                            
    **************************************************************************/
    FUNCTION get_import_prof_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_scope                   IN NUMBER,
        i_scope_type              IN VARCHAR2,
        i_pn_soap_block           IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block           IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type         IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_admitting_physician IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        io_data_import            IN OUT t_coll_data_import,
        o_count_records           OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_prof_resp       VARCHAR2(4000 CHAR);
        l_id_patient      patient.id_patient%TYPE;
        l_id_visit        visit.id_visit%TYPE;
        l_id_episode      episode.id_episode%TYPE;
        l_func_name       VARCHAR2(25 CHAR) := 'GET_IMPORT_PROF_RESP';
        l_id_professional epis_info.id_professional%TYPE;
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        IF (i_flg_admitting_physician = pk_alert_constant.g_yes)
           AND i_prof.software <> pk_alert_constant.g_soft_outpatient
        THEN
            g_error := 'CALL k_prog_notes_utils.get_admission_prof_resp';
            pk_alertlog.log_debug(g_error);
        
            l_prof_resp := pk_hand_off_core.get_admission_prof_resp(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => l_id_episode);
        ELSE
            g_error           := 'CALL pk_episode.get_epis_prof';
            l_id_professional := pk_episode.get_epis_prof(i_lang => i_lang, i_prof => i_prof, i_episode => l_id_episode);
            IF l_id_professional = '-1'
               OR l_id_episode IS NULL
            THEN
                l_prof_resp := NULL;
            ELSE
                l_prof_resp := pk_prof_utils.get_detail_signature(i_lang                => i_lang,
                                                                  i_prof                => i_prof,
                                                                  i_id_episode          => l_id_episode,
                                                                  i_date_last_change    => NULL, -- current_timestamp,
                                                                  i_id_prof_last_change => l_id_professional);
            END IF;
        
        END IF;
        IF (l_prof_resp IS NOT NULL or i_flg_admitting_physician= pk_alert_constant.g_no)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_prof_resp,
                                                                 l_prof_resp,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 l_id_episode,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_prof_resp;

    FUNCTION get_import_doc_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message   VARCHAR2(4000 CHAR);
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_DOC_STATUS';
    BEGIN
    
        g_error := 'GET SYS_MESSAGE';
        pk_alertlog.log_debug(g_error);
    
        l_message := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T135');
    
        IF (l_message IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_message,
                                                                 l_message,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_doc_status;

    /**************************************************************************
    * get_import_patient_information
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7.1.0
    * @since                          29/09/2019
    **************************************************************************/
    FUNCTION get_import_patient_information
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(50 CHAR) := 'GET_IMPORT_PATIENT_INFORMATION';
        l_title_code     VARCHAR2(50 CHAR) := 'PATIENT_INFO_TITLE_';
        l_title_colon    VARCHAR2(2 CHAR) := ': ';
        l_note           VARCHAR2(300 CHAR);
        l_phone_type     NUMBER := 12; --phone number
        l_dt_task        TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_admission_date VARCHAR2(50 CHAR);
        l_admi_date      TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_allergy_list   VARCHAR2(1000 CHAR);
        l_no_known       NUMBER(1) := 0;
    
    BEGIN
    
        g_error := 'GET PATIENT DATA: id_episode=' || i_id_episode || ', i_id_patient=' || i_id_patient ||
                   ', i_pn_soap_block=' || i_pn_soap_block || ', i_pn_data_block=' || i_pn_data_block ||
                   ', i_id_pn_task_type=' || i_id_pn_task_type;
        pk_alertlog.log_debug(g_error);
    
        g_error := 'Get admisstion date';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_hea_prv_epis.get_admission_date_report(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_id_episode   => i_id_episode,
                                                         i_id_schedule  => NULL,
                                                         o_adm_date     => l_admi_date,
                                                         o_adm_date_str => l_admission_date)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Get allergy list';
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT pk_utils.concat_table(CAST(COLLECT(desc_allergy) AS table_varchar), pk_prog_notes_constants.g_comma)
              INTO l_allergy_list
              FROM (SELECT pk_utils.concat_table(CAST(COLLECT(pa.allergen) AS table_varchar),
                                                 pk_prog_notes_constants.g_comma) desc_allergy,
                           type_reaction
                      FROM TABLE(pk_allergy.tf_allergy(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_patient    => i_id_patient,
                                                       i_flg_filter => pk_allergy.g_flg_type_allergy)) pa
                     WHERE pa.flg_status = pk_allergy.g_pat_allergy_flg_active
                     GROUP BY type_reaction);
        EXCEPTION
            -- record not found on easy access table. Search in all content
            WHEN no_data_found THEN
                l_allergy_list := NULL;
                g_error        := 'Get allergy no data';
                pk_alertlog.log_debug(g_error);
        END;
    
        g_error := 'Check no known allergy';
        pk_alertlog.log_debug(g_error);
        SELECT COUNT(1)
          INTO l_no_known
          FROM pat_allergy_unawareness pau
         WHERE pau.id_patient = i_id_patient
           AND pau.flg_status = pk_allergy.g_unawareness_active
           AND pau.id_allergy_unawareness IN (pk_allergy.g_no_known);
        IF l_allergy_list IS NULL
           AND l_no_known > 0
        THEN
            l_allergy_list := pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => 'ALLERGY_T027');
        END IF;
    
        SELECT (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'NAME')
                  FROM dual) || l_title_colon || p.name || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'MRN')
                  FROM dual) || l_title_colon || pi.alert_process_number || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'ADM_DATE')
                  FROM dual) || l_title_colon || l_admission_date || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'BED_NUMBER')
                  FROM dual) || l_title_colon ||
               decode(b.id_bed, NULL, NULL, pk_translation.get_translation(2, b.code_bed)) || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'BIRTHDAY')
                  FROM dual) || l_title_colon || pk_date_utils.date_chr_short_read(i_lang, p.dt_birth, i_prof) ||
               chr(10) || (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'SEX')
                             FROM dual) || l_title_colon ||
               pk_sysdomain.get_domain('PATIENT.GENDER', nvl(p.gender, NULL), i_lang) || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'PHONE')
                  FROM dual) || l_title_colon || cp.phone_number || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'ADDRESS')
                  FROM dual) || l_title_colon || ca.address_line1 || chr(10) ||
               (SELECT pk_message.get_message(i_lang, i_prof, l_title_code || 'ADR')
                  FROM dual) || l_title_colon || l_allergy_list
          INTO l_note
          FROM patient p
          JOIN episode e
            ON p.id_patient = e.id_patient
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
          LEFT JOIN bed b
            ON ei.id_bed = b.id_bed
           AND ei.id_room = b.id_room
          LEFT JOIN contact c
            ON c.id_contact_entity = p.id_person
          LEFT JOIN (SELECT *
                       FROM contact_phone cp
                      WHERE cp.id_contact_type = l_phone_type) cp
            ON c.id_contact = cp.id_contact
          LEFT JOIN contact_address ca
            ON c.id_contact = ca.id_contact_address
          LEFT JOIN pat_identifier pi
            ON p.id_patient = pi.id_patient
         WHERE p.id_patient = i_id_patient
           AND e.id_episode = i_id_episode
           AND pi.id_institution = i_prof.institution;
    
        pk_alertlog.log_debug('l_note=' || l_note);
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_patient_information;

    /**************************************************************************
    * get_import_vacciniation
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.1.0
    * @since                          29/09/2017
    **************************************************************************/
    FUNCTION get_import_vaccination
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      CLOB;
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_VACCINATION';
    
    BEGIN
    
        g_error := 'Call pk_immunization_core.get_vaccination_info';
        pk_alertlog.log_debug(g_error);
    
        l_note := pk_immunization_core.get_vaccination_info(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_patient => i_id_patient);
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_vaccination;

    /**************************************************************************
    * get import attending physicians
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Webber Chiou
    * @version                        2.7.1.0
    * @since                          17/01/2018
    **************************************************************************/
    FUNCTION get_import_att_phy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      VARCHAR2(4000 CHAR);
        l_func_name VARCHAR2(50 CHAR) := 'GET_IMPORT_ATTENDING_PHYSICIANS';
        l_lf CONSTANT VARCHAR2(2 CHAR) := chr(10);
    BEGIN
    
        g_error := 'GET_IMPORT_ATTENDING_PHYSICIANS';
        pk_alertlog.log_debug(g_error);
    
        l_note := pk_hand_off_core.get_attending_physicians(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_episode => i_id_episode);
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_att_phy;

    /**************************************************************************
    * Import Past medical history Biometrics
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Pedro Teixeira
    * @version                        2.7
    * @since                          04/10/2017
    **************************************************************************/
    FUNCTION get_import_pmh_biometrics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      VARCHAR2(4000 CHAR);
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_PMH_BIOMETRICS';
    
        l_title_colon CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_lf          CONSTANT VARCHAR2(2 CHAR) := chr(10);
    
        l_view          vs_soft_inst.flg_view%TYPE := 'N1';
        l_percentile_vs pk_types.cursor_type;
    
        l_vs_desc    table_varchar := table_varchar();
        l_value      table_number := table_number();
        l_value_high table_number := table_number();
        l_value_low  table_number := table_number();
    BEGIN
        -----------------------------------------------------------------
        -- get percentile vital signs
        IF NOT pk_percentile.get_percentile_vs(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_patient       => i_id_patient,
                                               i_flg_view      => l_view,
                                               o_percentile_vs => l_percentile_vs,
                                               o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        FETCH l_percentile_vs BULK COLLECT
            INTO l_vs_desc, l_value, l_value_high, l_value_low;
        CLOSE l_percentile_vs;
    
        -----------------------------------------------------------------
        -- if l_vs_desc is empty (no vital sign to show) then exit
        IF NOT (nvl(cardinality(l_vs_desc), 0) > 0)
        THEN
            RETURN TRUE;
        END IF;
    
        -- fill l_note with vital sign information
        FOR i IN l_vs_desc.first .. l_vs_desc.last
        LOOP
            l_note := l_note || l_vs_desc(i) || l_title_colon || nvl(l_value_low(i), l_value(i)) || l_lf;
        END LOOP;
    
        -----------------------------------------------------------------
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_pmh_biometrics;

    /**************************************************************************
    * get import data from a note from another note type registered in the same episode
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID  
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_filter             Filter to apply. 
    *                                 The syntax must be: id_pn_note_type-id_pn_data_block
    *                                 For instance: 2-20
    *                                 This means that will be imported the tasks from the last note with note_type =2 of the episode
    *                                 associated to the datablock 20
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.7                          
    * @since                          15-10-2017                       
    **************************************************************************/
    FUNCTION get_import_from_other_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_filter    IN VARCHAR,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name              VARCHAR2(50 CHAR) := 'GET_IMPORT_FROM_OTHER_NOTE';
        l_filter_list            table_varchar := table_varchar();
        l_id_pn_note_type_to_imp NUMBER;
        l_id_pn_dblock_imp       NUMBER;
        l_wrong_filter_syntax_exc EXCEPTION;
    
    BEGIN
        g_error := 'GET_IMPORT_FROM_OTHER_NOTE / i_id_episode:' || i_id_episode || 'i_flg_filter: ' || i_flg_filter ||
                   ' i_pn_soap_block: ' || i_pn_soap_block || ' i_pn_data_block: ' || i_pn_data_block;
        IF (i_flg_filter IS NOT NULL)
        THEN
            BEGIN
                l_filter_list            := pk_string_utils.str_split(i_list => i_flg_filter, i_delim => '-');
                l_id_pn_note_type_to_imp := to_number(l_filter_list(1));
                l_id_pn_dblock_imp       := to_number(l_filter_list(2));
            EXCEPTION
                WHEN OTHERS THEN
                    --DO not import any data
                    RETURN TRUE;
            END;
        
            FOR rec IN (SELECT epdt.id_task, epdt.pn_note, epdt.flg_table_origin, epdt.id_task_type
                          FROM epis_pn_det_task epdt
                          JOIN epis_pn_det epd
                            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                          JOIN epis_pn epn
                            ON epn.id_epis_pn = epd.id_epis_pn
                         WHERE epn.id_pn_note_type = l_id_pn_note_type_to_imp
                           AND epn.id_episode = i_id_episode
                           AND epd.id_pn_data_block = l_id_pn_dblock_imp
                           AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                           AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c)
            LOOP
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     rec.pn_note,
                                                                     rec.pn_note,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     rec.id_task,
                                                                     rec.id_task_type, --pk_prog_notes_constants.g_task_templates_other_note,
                                                                     rec.flg_table_origin,
                                                                     NULL,
                                                                     NULL, --13                                                                         
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
            
                o_count_records := 1;
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_from_other_note;

    /**************************************************************************
    * Performs some action before the records importation to the note. From instance copy the record to import
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_task                Task ID
    * @param i_id_task_type           Task type ID
    * @param i_id_episode             Episode ID
    * @param i_action                 Action to apply. 
    *        Ex: CPRN - copy the records from other note. to be used to copy templates from a datablock of other note
    * @param i_id_pn_note_type_action  Note type associated to the action (Note type associated to the records to be copied)
    * @param i_id_pn_data_block_action Data block associated to the action (Data block associated to the records to be copied)
    *
    * @param o_id_task_to_import      Id task to be imported. Ex. id of the copied template
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.7                          
    * @since                          15-10-2017                       
    **************************************************************************/
    FUNCTION set_action_import_data
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_task                 IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type            IN epis_pn_det_task.id_task_type%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_action                  IN VARCHAR2,
        i_id_pn_note_type_action  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block_action IN pn_data_block.id_pn_data_block%TYPE,
        i_epis_pn                 IN epis_pn.id_epis_pn%TYPE,
        o_id_task_to_import       OUT epis_pn_det_task.id_task%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_func_name          VARCHAR2(50 CHAR) := 'SET_ACTION_IMPORT_DATA';
        l_scores             table_number;
        l_task_exist_in_note VARCHAR2(1char);
        l_id_task            NUMBER(24);
        l_cp_note_type       NUMBER := 0;
        l_id_epis_pn         epis_pn.id_epis_pn%TYPE;
    
        FUNCTION is_task_on_last_note
        (
            i_id_task_to_import IN epis_pn_det_task.id_task%TYPE,
            i_id_epis_pn        IN epis_pn.id_epis_pn%TYPE
        ) RETURN BOOLEAN IS
            l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
        BEGIN
        
            SELECT id_epis_pn_det_task
              INTO l_id_epis_pn_det_task
              FROM (SELECT epdt.id_epis_pn_det_task
                      FROM epis_pn epn
                      JOIN epis_pn_det epd
                        ON epd.id_epis_pn = epn.id_epis_pn
                      JOIN epis_pn_det_task epdt
                        ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                     WHERE epn.id_pn_note_type = i_id_pn_note_type_action
                       AND epn.id_episode = i_id_episode
                       AND epd.id_pn_data_block = i_id_pn_data_block_action
                       AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                       AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                       AND epdt.id_task = i_id_task_to_import
                       AND epdt.id_task_type = i_id_task_type
                       AND (epn.id_epis_pn = i_id_epis_pn OR i_id_epis_pn IS NULL)
                     ORDER BY epn.dt_create DESC)
             WHERE rownum < 2;
        
            IF (l_id_epis_pn_det_task IS NOT NULL)
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        
        EXCEPTION
            WHEN no_data_found THEN
                RETURN FALSE;
            
        END is_task_on_last_note;
    BEGIN
        g_error := 'SET_ACTION_IMPORT_DATA / i_id_task:' || i_id_task || ' i_id_task_type: ' || i_id_task_type ||
                   ' i_id_episode: ' || i_id_episode || ' i_action: ' || i_action || ' i_id_pn_note_type_action: ' ||
                   i_id_pn_note_type_action || ' i_id_pn_data_block_action: ' || i_id_pn_data_block_action;
        pk_alertlog.log_debug(g_error);
        --1. check if the i_id_task is associated to the pretended note type and data block
        BEGIN
            SELECT CASE
                       WHEN COUNT(1) > 0 THEN
                        pk_alert_constant.g_yes
                       ELSE
                        pk_alert_constant.g_no
                   END
              INTO l_task_exist_in_note
              FROM epis_pn_det_task epdt
              JOIN epis_pn_det epd
                ON epd.id_epis_pn_det = epdt.id_epis_pn_det
              JOIN epis_pn epn
                ON epn.id_epis_pn = epd.id_epis_pn
             WHERE epn.id_pn_note_type = i_id_pn_note_type_action
               AND epn.id_episode = i_id_episode
               AND epd.id_pn_data_block = i_id_pn_data_block_action
               AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
               AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
               AND epdt.id_task = i_id_task
               AND epdt.id_task_type = i_id_task_type
               AND (epn.id_epis_pn <> i_epis_pn OR i_epis_pn IS NULL);
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        --2. Apply the action
        IF (l_task_exist_in_note = pk_alert_constant.g_yes AND
           i_action = pk_prog_notes_constants.g_action_copy_record_from_note)
        THEN
            IF (i_id_task_type = pk_prog_notes_constants.g_task_templates)
            THEN
                g_error := 'CALL pk_presc_core.set_copy_template. i_id_episode: ' || i_id_episode || ' i_id_task: ' ||
                           i_id_task;
                IF NOT pk_prog_notes_core.set_copy_template(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_episode            => i_id_episode,
                                                            i_prof_cat_type         => pk_tools.get_prof_cat(i_prof),
                                                            i_id_task               => i_id_task,
                                                            o_id_epis_documentation => o_id_task_to_import,
                                                            o_id_epis_scales_score  => l_scores,
                                                            o_error                 => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            ELSIF i_id_task_type = pk_prog_notes_constants.g_task_diagnosis
                  OR i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint
            THEN
                o_id_task_to_import := i_id_task;
            ELSE
                --it is not supposed to performed a specific action for this task type (like a copy) so it will be imported the same task associated  to the original note
                o_id_task_to_import := i_id_task;
            
            END IF;
        ELSIF (l_task_exist_in_note = pk_alert_constant.g_yes AND
              i_action = pk_prog_notes_constants.g_action_cp_rec_from_same_note)
        THEN
            IF (i_id_task_type = pk_prog_notes_constants.g_task_templates)
            THEN
                g_error := 'CALL pk_prog_notes_core.set_copy_template. i_id_episode: ' || i_id_episode ||
                           ' i_id_task: ' || i_id_task;
                IF i_id_pn_note_type_action IS NOT NULL
                THEN
                    IF NOT pk_prog_notes_utils.get_last_note_by_note_type(i_lang            => i_lang,
                                                                          i_prof            => i_prof,
                                                                          i_scope           => i_id_episode,
                                                                          i_scope_type      => pk_prog_notes_constants.g_flg_scope_e,
                                                                          i_id_pn_note_type => i_id_pn_note_type_action,
                                                                          i_note_status     => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                                             pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                                             pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                                             pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                                                                             pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                                                                             pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                                          o_id_epis_pn      => l_id_epis_pn,
                                                                          o_error           => o_error)
                    THEN
                        RAISE g_other_exception;
                    END IF;
                END IF;
            
                IF NOT (is_task_on_last_note(i_id_task_to_import => i_id_task, i_id_epis_pn => l_id_epis_pn))
                THEN
                    o_id_task_to_import := NULL;
                ELSE
                
                    IF NOT pk_prog_notes_core.set_copy_template(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_id_episode            => i_id_episode,
                                                                i_prof_cat_type         => pk_tools.get_prof_cat(i_prof),
                                                                i_id_task               => i_id_task,
                                                                o_id_epis_documentation => o_id_task_to_import,
                                                                o_id_epis_scales_score  => l_scores,
                                                                o_error                 => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            ELSIF (i_id_task_type = pk_prog_notes_constants.g_task_body_diagram)
            THEN
            
                IF NOT is_last_epis_pn(i_id_episode       => i_id_episode,
                                       i_id_pn_note_type  => i_id_pn_note_type_action,
                                       i_id_pn_data_block => i_id_pn_data_block_action,
                                       i_id_task_type     => i_id_task_type,
                                       i_id_task          => i_id_task)
                THEN
                    o_id_task_to_import := NULL;
                ELSE
                    o_id_task_to_import := i_id_task;
                END IF;
            
            ELSE
                --it is not supposed to performed a specific action for this task type (like a copy) so it will be imported the same task associated  to the original note
                o_id_task_to_import := i_id_task;
            END IF;
        ELSIF i_action = pk_prog_notes_constants.g_action_copy_record_from_note
              AND (i_id_task_type = pk_prog_notes_constants.g_task_diagnosis OR
              i_id_task_type = pk_prog_notes_constants.g_task_chief_complaint)
        THEN
            o_id_task_to_import := NULL;
        ELSIF (instr(i_action, pk_prog_notes_constants.g_action_copy_record_from_note) > 0 AND
              length(i_action) > length(pk_prog_notes_constants.g_action_copy_record_from_note))
        THEN
            IF (i_id_task_type = pk_prog_notes_constants.g_task_templates)
            THEN
                l_cp_note_type := to_number(substr(i_action,
                                                   length(pk_prog_notes_constants.g_action_copy_record_from_note) + 1,
                                                   length(i_action) -
                                                   length(pk_prog_notes_constants.g_action_copy_record_from_note)));
            
                IF is_first_epis_pn(i_id_episode => i_id_episode, i_id_pn_note_type => l_cp_note_type)
                THEN
                    IF l_task_exist_in_note = pk_alert_constant.g_yes
                    THEN
                        IF NOT pk_prog_notes_core.set_copy_template(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_episode            => i_id_episode,
                                                                    i_prof_cat_type         => pk_tools.get_prof_cat(i_prof),
                                                                    i_id_task               => i_id_task,
                                                                    o_id_epis_documentation => o_id_task_to_import,
                                                                    o_id_epis_scales_score  => l_scores,
                                                                    o_error                 => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                ELSE
                    IF NOT is_last_epis_pn(i_id_episode       => i_id_episode,
                                           i_id_pn_note_type  => i_id_pn_note_type_action,
                                           i_id_pn_data_block => i_id_pn_data_block_action,
                                           i_id_task_type     => i_id_task_type,
                                           i_id_task          => i_id_task)
                    THEN
                        o_id_task_to_import := NULL;
                    ELSE
                        IF NOT pk_prog_notes_core.set_copy_template(i_lang                  => i_lang,
                                                                    i_prof                  => i_prof,
                                                                    i_id_episode            => i_id_episode,
                                                                    i_prof_cat_type         => pk_tools.get_prof_cat(i_prof),
                                                                    i_id_task               => i_id_task,
                                                                    o_id_epis_documentation => o_id_task_to_import,
                                                                    o_id_epis_scales_score  => l_scores,
                                                                    o_error                 => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_action_import_data;

    /**************************************************************************
    * Import Complications and Diagnosis that intercepts the complication list
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Patient ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Pedro Teixeira
    * @version                        2.7
    * @since                          04/10/2017
    **************************************************************************/
    FUNCTION get_import_complications
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_COMPLICATIONS';
    
        l_complications   pk_types.cursor_type;
        l_id_concept_term table_number := table_number();
        l_compl_desc      table_varchar := table_varchar();
        l_compl_code      table_varchar := table_varchar();
        l_dt_create       table_timestamp_tstz := table_timestamp_tstz();
        l_note            VARCHAR2(4000 CHAR);
        l_num_records     NUMBER := 0;
    BEGIN
        g_error := 'CALL PK_API_PROTOCOL.GET_APPLIED_PROTOCOLS_LIST';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_complication.get_complication_and_diag(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_episode    => i_id_episode,
                                                         i_id_patient    => i_id_patient,
                                                         o_complications => l_complications,
                                                         o_error         => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        FETCH l_complications BULK COLLECT
            INTO l_id_concept_term, l_compl_desc, l_compl_code, l_dt_create;
        CLOSE l_complications;
    
        IF l_id_concept_term.exists(1)
        THEN
            FOR i IN l_id_concept_term.first .. l_id_concept_term.last
            LOOP
                -- if term code is not found in complication description the add it
                IF instr(l_compl_desc(i), l_compl_code(i)) = 0
                THEN
                    l_note := l_compl_desc(i) || ' (' || l_compl_code(i) || ')';
                ELSE
                    l_note := l_compl_desc(i);
                END IF;
            
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_note,
                                                                     l_note,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     l_id_concept_term(i),
                                                                     i_id_pn_task_type,
                                                                     NULL,
                                                                     NULL, -- rank 
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     l_dt_create(i),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
            
                l_num_records := l_num_records + 1;
            END LOOP;
        END IF;
    
        o_count_records := l_num_records;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_import_complications;

    FUNCTION get_related_data_from_ea
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_task              IN table_number,
        i_id_task_type_related IN task_timeline_ea.id_tl_task%TYPE,
        i_id_data_block        IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block        IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type         IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_action           IN VARCHAR2,
        o_id_task              OUT table_number,
        o_dt_task              OUT table_varchar,
        o_id_task_type         OUT table_number,
        o_note_task            OUT table_clob,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(23 CHAR) := 'GET_REVIEW_DATA_FROM_EA';
        l_task_desc               CLOB;
        l_tbl_task_desc           table_clob;
        l_t_coll_dblock_task_type t_coll_dblock_task_type;
    BEGIN
        g_error := 'GET review data from ea. i_id_task_type: ' || i_id_task_type_related || ' i_id_task: ' ||
                   pk_utils.concat_table(i_id_task);
        --     pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        SELECT t2.id_task, t2.dt_task, t2.id_tl_task
          BULK COLLECT
          INTO o_id_task, o_dt_task, o_id_task_type
          FROM (SELECT t.id_task, t.dt_task, t.id_tl_task
                  FROM v_pn_tasks t
                 WHERE t.id_task_related IN (SELECT /*+ opt_estimate(table,t,scale_rows=0.0000001) */
                                              column_value
                                               FROM TABLE(i_id_task) t)
                   AND t.id_tl_task = i_id_task_type_related
                   AND i_id_episode IS NULL
                UNION
                SELECT t.id_task, t.dt_task, t.id_tl_task
                  FROM v_pn_tasks t
                 WHERE t.id_task_related IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                              column_value
                                               FROM TABLE(i_id_task) t)
                   AND t.id_tl_task = i_id_task_type_related
                      
                   AND (i_id_episode IS NOT NULL AND t.id_episode = i_id_episode)
                UNION
                SELECT t.id_task, t.dt_task, t.id_tl_task
                  FROM v_pn_tasks t
                 WHERE t.id_task IN (SELECT /*+opt_estimate(table,t,scale_rows=0.0000001)*/
                                      column_value
                                       FROM TABLE(i_id_task) t)
                   AND t.id_tl_task = i_id_task_type_related
                   AND i_flg_action = pk_prog_notes_constants.g_flg_action_import
                   AND (i_id_episode IS NOT NULL AND t.id_episode = i_id_episode)) t2;
    
        g_error := 'CALL pk_prog_notes_upd.tf_dblock_task_type. i_id_pn_note_type: ' || i_id_note_type ||
                   ' i_id_task_type: ' || i_id_task_type_related || ' i_id_pn_data_block: ' || i_id_data_block ||
                   ' i_id_pn_soap_block: ' || i_id_soap_block;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
    
        l_t_coll_dblock_task_type := pk_progress_notes_upd.tf_dblock_task_type(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_episode       => i_id_episode,
                                                                               i_id_market        => NULL,
                                                                               i_id_department    => NULL,
                                                                               i_id_dep_clin_serv => NULL,
                                                                               i_id_pn_note_type  => i_id_note_type,
                                                                               i_software         => NULL,
                                                                               i_id_task_type     => i_id_task_type_related,
                                                                               i_id_pn_data_block => i_id_data_block,
                                                                               i_id_pn_soap_block => i_id_soap_block);
    
        IF o_id_task IS NOT NULL
           AND o_id_task.exists(1)
        THEN
            l_tbl_task_desc := table_clob();
            FOR i IN o_id_task.first .. o_id_task.last
            LOOP
                g_error := 'get_detailed_desc_all. i_id_pn_task_type: ' || i_id_task_type_related || ' i_id_task: ' ||
                           o_id_task(i);
                pk_alertlog.log_debug(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_task_desc := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_episode            => i_id_episode,
                                                                      i_id_task_type          => i_id_task_type_related,
                                                                      i_id_task               => o_id_task(i),
                                                                      i_universal_description => NULL,
                                                                      i_short_desc            => NULL,
                                                                      i_code_description      => NULL,
                                                                      i_flg_description       => l_t_coll_dblock_task_type(1).flg_description,
                                                                      i_description_condition => l_t_coll_dblock_task_type(1).description_condition);
            
                l_tbl_task_desc.extend;
                l_tbl_task_desc(l_tbl_task_desc.last) := l_task_desc;
            END LOOP;
            o_note_task := l_tbl_task_desc;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_related_data_from_ea;

    FUNCTION get_data_block_txt
    (
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN CLOB IS
        l_data_block_text epis_pn_det.pn_note%TYPE;
        l_dblock_text_lst table_clob := table_clob();
    
    BEGIN
        SELECT nvl(et.pn_note, e.pn_note)
          BULK COLLECT
          INTO l_dblock_text_lst
          FROM epis_pn_det e
          LEFT JOIN epis_pn_det_task et
            ON (et.id_epis_pn_det = e.id_epis_pn_det AND et.flg_status = pk_alert_constant.g_active)
         WHERE e.id_epis_pn = i_id_epis_pn
           AND e.id_pn_data_block = i_id_data_block
           AND e.id_pn_soap_block = i_id_soap_block
           AND e.flg_status = pk_alert_constant.g_active;
    
        FOR i IN 1 .. l_dblock_text_lst.count
        LOOP
            l_data_block_text := l_data_block_text || CASE
                                     WHEN l_data_block_text IS NOT NULL THEN
                                      pk_prog_notes_constants.g_new_line || pk_prog_notes_constants.g_new_line
                                 END || l_dblock_text_lst(i);
        END LOOP;
    
        RETURN l_data_block_text;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_data_block_txt;

    FUNCTION is_last_epis_pn
    (
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task_type     IN pn_dblock_ttp_mkt.id_task_type%TYPE,
        i_id_task          IN epis_pn_det_task.id_task%TYPE
    ) RETURN BOOLEAN IS
        l_id_epis_pn     epis_pn.id_epis_pn%TYPE;
        l_id_epis_pn_tst epis_pn.id_epis_pn%TYPE;
    BEGIN
        SELECT id_epis_pn
          INTO l_id_epis_pn
          FROM (SELECT epn.id_epis_pn
                  FROM epis_pn epn
                  JOIN epis_pn_det epd
                    ON epd.id_epis_pn = epn.id_epis_pn
                  JOIN epis_pn_det_task epdt
                    ON epdt.id_epis_pn_det = epd.id_epis_pn_det
                 WHERE epn.id_pn_note_type = i_id_pn_note_type
                   AND epn.id_episode = i_id_episode
                   AND epd.id_pn_data_block = i_id_pn_data_block
                   AND epdt.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                   AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                   AND epdt.id_task = i_id_task
                   AND epdt.id_task_type = i_id_task_type
                 ORDER BY epn.dt_create DESC)
         WHERE rownum < 2;
    
        SELECT id_epis_pn
          INTO l_id_epis_pn_tst
          FROM (SELECT e.id_epis_pn
                  FROM epis_pn e
                 WHERE e.id_episode = i_id_episode
                   AND e.id_pn_note_type = i_id_pn_note_type
                 ORDER BY e.dt_create DESC)
         WHERE rownum < 2;
    
        IF (l_id_epis_pn = l_id_epis_pn_tst)
        THEN
            RETURN TRUE;
        ELSE
            RETURN FALSE;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN FALSE;
    END is_last_epis_pn;

    FUNCTION is_first_epis_pn
    (
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN BOOLEAN IS
        l_id_epis_pn epis_pn.id_epis_pn%TYPE;
    BEGIN
        SELECT id_epis_pn
          INTO l_id_epis_pn
          FROM (SELECT epn.id_epis_pn
                  FROM epis_pn epn
                 WHERE epn.id_pn_note_type = i_id_pn_note_type
                   AND epn.id_episode = i_id_episode
                   AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                 ORDER BY epn.dt_create ASC)
         WHERE rownum < 2;
    
        IF (l_id_epis_pn IS NOT NULL AND l_id_epis_pn > 0)
        THEN
            RETURN FALSE;
        ELSE
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
    END is_first_epis_pn;
    -----

    /**************************************************************************
    * get_import_vs_by_view_date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})    
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_id_pn_task_type        Task type
    * @param i_flg_view               Vital Sign view type
    * @param i_flg_first_record       Flg for first_record 
    * @param i_all_details            View all detail Y/N
    * @param i_interval               Interval to filter
    * @param io_data_import           Struct with data import information
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7
    * @since                          05/01/2018
    **************************************************************************/
    FUNCTION get_import_vs_by_view_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_pn_task_type  IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_view         IN vs_soft_inst.flg_view%TYPE,
        i_flg_first_record IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_all_details      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_interval         IN VARCHAR2 DEFAULT NULL,
        io_data_import     IN OUT t_coll_data_import,
        o_count_records    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_patient       patient.id_patient%TYPE;
        l_id_episode       episode.id_episode%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_rn               table_number := table_number();
        l_id_vsr           table_number := table_number();
        l_vs_desc          table_varchar := table_varchar();
        l_vs_value         table_varchar := table_varchar();
        l_vs               table_varchar := table_varchar();
        l_dt_vsr           table_timestamp := table_timestamp();
        l_task_id          table_number := table_number();
        l_dt_task_register table_timestamp := table_timestamp();
        l_id_fetus         table_number := table_number();
        l_note             VARCHAR2(4000 CHAR) := '';
        l_num              INTEGER := 0;
        l_dt_begin         VARCHAR2(50 CHAR) := NULL;
        l_dt_end           VARCHAR2(50 CHAR) := NULL;
        l_func_name        VARCHAR2(50 CHAR) := 'GET_IMPORT_VS_BY_VIEW_DATE';
        l_colon   CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_colon;
        l_newline CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_new_line;
        l_space   CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_space;
    
        l_decimal_symbol CONSTANT sys_config.value%TYPE := pk_sysconfig.get_config(i_code_cf   => 'DECIMAL_SYMBOL',
                                                                                   i_prof_inst => i_prof.institution,
                                                                                   i_prof_soft => i_prof.software);
    
        l_flg_use_vs     VARCHAR2(1 CHAR);
        l_flg_show_fetus VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_vs_description VARCHAR2(2000 CHAR);
        l_id_fetus_prev  NUMBER;
        l_fetus_val      NUMBER;
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        l_dt_begin := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_begin_date,
                                                      i_timezone  => NULL);
    
        g_error := 'CALL GET_STRING_TSTZ FOR i_end_date';
        pk_alertlog.log_debug(g_error);
        l_dt_end := pk_date_utils.get_timestamp_str(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_end_date,
                                                    i_timezone  => NULL);
    
        IF i_flg_view IS NULL
        THEN
            l_flg_use_vs := pk_alert_constant.g_no;
        ELSE
            IF i_flg_view = pk_prog_notes_constants.g_vs_view_pt
            THEN
                l_flg_show_fetus := pk_alert_constant.g_yes;
            END IF;
            l_flg_use_vs := pk_alert_constant.g_yes;
        END IF;
    
        SELECT id_vsr,
               vital_sign_desc,
               value_desc,
               dt_vsr,
               decode(l_flg_show_fetus, pk_alert_constant.g_no, rn, rn_fetus),
               id_fetus_number
          BULK COLLECT
          INTO l_id_vsr, l_vs_desc, l_vs_value, l_dt_vsr, l_rn, l_id_fetus
          FROM (SELECT c.id_vital_sign_read id_vsr,
                       pk_vital_sign.get_vs_desc(i_lang => i_lang, i_vital_sign => c.id_vital_sign) AS vital_sign_desc,
                       pk_vital_sign_core.get_vs_value(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_patient          => l_id_patient,
                                                       i_id_episode          => c.id_episode,
                                                       i_id_vital_sign       => c.id_vital_sign,
                                                       i_id_vital_sign_desc  => c.id_vital_sign_desc,
                                                       i_dt_vital_sign_read  => c.dt_vital_sign_read,
                                                       i_id_unit_measure_vsr => c.id_unit_measure_vsr,
                                                       i_id_unit_measure_vsi => c.id_unit_measure_vsi,
                                                       i_value               => c.value,
                                                       i_decimal_symbol      => l_decimal_symbol,
                                                       i_relation_domain     => c.relation_domain,
                                                       i_dt_registry         => c.dt_registry) || ' ' ||
                       (SELECT pk_translation.get_translation(i_lang, um.code_unit_measure)
                          FROM unit_measure um
                         WHERE um.id_unit_measure = decode(c.vital_sign_scale,
                                                           NULL,
                                                           c.id_unit_measure_vsr,
                                                           (SELECT vsse.id_unit_measure
                                                              FROM vital_sign_scales_element vsse
                                                             WHERE vsse.id_vital_sign_scales = c.vital_sign_scale
                                                               AND rownum = 1))) AS value_desc,
                       c.dt_vital_sign_read dt_vsr,
                       row_number() over(PARTITION BY c.dt_vital_sign_read ORDER BY c.rank) rn,
                       row_number() over(PARTITION BY c.dt_vital_sign_read ORDER BY c.id_fetus_number) rn_fetus,
                       id_fetus_number
                  FROM TABLE(pk_vital_sign_core.get_vital_sign_records(i_lang              => i_lang,
                                                                       i_prof              => i_prof,
                                                                       i_flg_view          => i_flg_view,
                                                                       i_all_details       => i_all_details,
                                                                       i_scope             => i_scope,
                                                                       i_scope_type        => i_scope_type,
                                                                       i_interval          => i_interval,
                                                                       i_dt_begin          => l_dt_begin,
                                                                       i_dt_end            => l_dt_end,
                                                                       i_flg_use_soft_inst => l_flg_use_vs,
                                                                       i_flg_include_fetus => l_flg_show_fetus)) c
                 WHERE c.flg_state = pk_alert_constant.g_active)
         ORDER BY dt_vsr, decode(l_flg_show_fetus, pk_alert_constant.g_no, rn, rn_fetus);
    
        -- fill l_note with vital sign information
        IF l_id_vsr.exists(1)
        THEN
            FOR i IN l_id_vsr.first .. l_id_vsr.last
            LOOP
                IF l_rn(i) = 1
                THEN
                    l_num := l_num + 1;
                    IF l_vs.count < l_num
                    THEN
                        l_vs.extend;
                        l_task_id.extend;
                        l_dt_task_register.extend;
                    END IF;
                
                    l_vs_description := '(' || pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                           i_date => l_dt_vsr(i),
                                                                           i_inst => i_prof.institution,
                                                                           i_soft => i_prof.software) || ')' ||
                                        l_newline;
                    IF l_flg_show_fetus = pk_alert_constant.g_yes
                       AND l_id_fetus(i) = 0
                    THEN
                        l_vs_description := l_vs_description ||
                                            pk_sysdomain.get_domain('WOMAN_HEALTH.VS_TYPE', l_id_fetus(i), i_lang) ||
                                            l_newline;
                    
                    ELSIF l_flg_show_fetus = pk_alert_constant.g_yes
                          AND l_id_fetus(i) > 0
                    THEN
                        l_vs_description := l_vs_description ||
                                            pk_sysdomain.get_domain('WOMAN_HEALTH.VS_TYPE', 1, i_lang) || l_space ||
                                            l_id_fetus(i) || l_newline;
                    END IF;
                    l_vs_description := l_vs_description || l_vs_desc(i) || l_colon || l_vs_value(i) || l_newline;
                
                    l_vs(l_num) := l_vs_description;
                    /*'(' || pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                                      i_date => l_dt_vsr(i),
                                                                      i_inst => i_prof.institution,
                                                                      i_soft => i_prof.software) || ')' || l_newline ||
                    l_vs_desc(i) || l_colon || l_vs_value(i) || l_newline;*/
                    l_task_id(l_num) := l_id_vsr(i);
                    l_dt_task_register(l_num) := l_dt_vsr(i);
                
                ELSE
                    IF l_id_fetus_prev <> l_id_fetus(i)
                       AND l_flg_show_fetus = pk_alert_constant.g_yes
                    THEN
                        IF l_id_fetus(i) > 0
                        THEN
                            l_fetus_val := 1;
                        ELSE
                            l_fetus_val := 0;
                        END IF;
                        l_vs(l_num) := l_vs(l_num) ||
                                       pk_sysdomain.get_domain('WOMAN_HEALTH.VS_TYPE', l_fetus_val, i_lang);
                        IF l_id_fetus(i) > 0
                        THEN
                            l_vs(l_num) := l_vs(l_num) || l_space || l_id_fetus(i) || l_newline;
                        END IF;
                    END IF;
                    l_vs(l_num) := l_vs(l_num) || l_vs_desc(i) || l_colon || l_vs_value(i) || l_newline;
                END IF;
                l_id_fetus_prev := l_id_fetus(i);
            END LOOP;
        
        END IF;
    
        IF l_vs.exists(1)
        THEN
            <<i_loop>>
            FOR i IN l_vs.first .. l_vs.last
            LOOP
                l_note := l_vs(i);
            
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_note,
                                                                     l_note,
                                                                     NULL,
                                                                     l_dt_task_register(i),
                                                                     NULL,
                                                                     l_task_id(i),
                                                                     i_id_pn_task_type,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
                EXIT i_loop WHEN i_flg_first_record = pk_alert_constant.g_yes;
                o_count_records := o_count_records + 1;
            END LOOP;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_vs_by_view_date;
    -----------
    /**************************************************************************
    * get import data from episode transfer information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.2.3                             
    * @since                          18/01/2018                            
    **************************************************************************/
    FUNCTION get_import_transfer_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN NUMBER,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note       CLOB;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'get_import_transfer_info';
    BEGIN
    
        g_error := 'CALL pk_episode.get_episode_transfer_sp';
        pk_alertlog.log_debug(g_error);
    
        l_note := pk_episode.get_episode_transfer_sp(i_lang => i_lang, i_prof => i_prof, i_id_episode => i_id_episode);
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_transfer_info;

    /**************************************************************************
    * get_import_asse_score
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.2.3
    * @since                          13/1/2018
    **************************************************************************/
    FUNCTION get_import_asse_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      VARCHAR2(4000 CHAR);
        l_func_name VARCHAR2(25 CHAR) := 'GET_IMPORT_ASSE_SCORE';
    
        l_title_colon CONSTANT VARCHAR2(2 CHAR) := ': ';
        l_lf          CONSTANT VARCHAR2(2 CHAR) := chr(10);
        --variables for pregnancy delivery
        l_doc_area_partogram    CONSTANT doc_area.id_doc_area%TYPE := 1048;
        l_elem_int_name_newborn CONSTANT doc_element.internal_name%TYPE := 'Peso (Kg)';
        --variables for NIHSS
        l_doc_area_nihss        CONSTANT doc_area.id_doc_area%TYPE := 36030;
        l_elem_int_name_nihss   CONSTANT doc_element.internal_name%TYPE := 'INT_NIHSS';
        l_elem_int_name_snihss5 CONSTANT doc_element.internal_name%TYPE := 'INT_SNIHSS5';
    
        -- GCS
        l_glasgowtotal vital_sign_read.value%TYPE;
        -- GA
        l_ga_desc VARCHAR2(20 CHAR);
        -- BBW
        l_bbw_value vital_sign_read.value%TYPE;
        -- NIHSS
        l_nihss_value VARCHAR2(10 CHAR);
        -- sNIHSS-5
        l_snihss5_value VARCHAR2(10 CHAR);
        -- ISS
        l_iss_value VARCHAR2(3 CHAR);
    
    BEGIN
        g_error := 'GET_IMPORT_ASSE_SCORE';
        pk_alertlog.log_debug(g_error);
    
        -- GCS
        l_glasgowtotal := pk_vital_sign.get_glasgowtotal_value(i_vital_sign         => pk_vital_sign.g_vs_glasgowtotal,
                                                               i_patient            => i_id_patient,
                                                               i_episode            => NULL, -- not to sepecify episode id
                                                               i_dt_vital_sign_read => NULL);
    
        IF l_glasgowtotal IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M049') || l_title_colon ||
                      l_glasgowtotal || l_lf;
        END IF;
    
        -- GA, BBW
        IF NOT pk_delivery.get_newborn_delivery_weeks(i_lang    => i_lang,
                                                      i_prof    => i_prof,
                                                      i_patient => i_id_patient,
                                                      o_ga_age  => l_ga_desc,
                                                      o_error   => o_error)
        THEN
            RAISE g_exception;
        END IF;
        IF l_ga_desc IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M050') || l_title_colon ||
                      l_ga_desc || l_lf;
        END IF;
    
        l_bbw_value := pk_unit_measure.get_unit_mea_conversion(i_value         => pk_vital_sign.get_vs_read_value(i_lang       => i_lang,
                                                                                                                  i_prof       => i_prof,
                                                                                                                  i_patient    => i_id_patient,
                                                                                                                  i_episode    => i_id_episode,
                                                                                                                  i_vital_sign => pk_vital_sign.g_vs_birth_weight),
                                                               i_unit_meas     => pk_vital_sign.get_vs_um_inst(pk_vital_sign.g_vs_birth_weight,
                                                                                                               i_prof.institution,
                                                                                                               i_prof.software),
                                                               i_unit_meas_def => pk_unit_measure.g_um_kilogram);
        IF l_bbw_value IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M051') || l_title_colon ||
                      l_bbw_value || pk_prog_notes_constants.g_space ||
                      pk_unit_measure.get_unit_measure_description(i_lang         => i_lang,
                                                                   i_prof         => i_prof,
                                                                   i_unit_measure => pk_unit_measure.g_um_kilogram) || l_lf;
        END IF;
    
        -- NIHSS
        l_nihss_value := pk_touch_option.get_template_value(i_lang               => i_lang,
                                                            i_prof               => i_prof,
                                                            i_patient            => NULL,
                                                            i_episode            => i_id_episode,
                                                            i_doc_area           => l_doc_area_nihss,
                                                            i_epis_documentation => NULL,
                                                            i_doc_int_name       => NULL,
                                                            i_element_int_name   => l_elem_int_name_nihss,
                                                            i_show_internal      => NULL,
                                                            i_scope_type         => 'E',
                                                            i_mask               => NULL,
                                                            i_field_type         => NULL);
        IF l_nihss_value IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M052') || l_title_colon ||
                      l_nihss_value || l_lf;
        END IF;
        -- sNIHSS-5
        l_snihss5_value := pk_touch_option.get_template_value(i_lang               => i_lang,
                                                              i_prof               => i_prof,
                                                              i_patient            => NULL,
                                                              i_episode            => i_id_episode,
                                                              i_doc_area           => l_doc_area_nihss,
                                                              i_epis_documentation => NULL,
                                                              i_doc_int_name       => NULL,
                                                              i_element_int_name   => l_elem_int_name_snihss5,
                                                              i_show_internal      => NULL,
                                                              i_scope_type         => 'E',
                                                              i_mask               => NULL,
                                                              i_field_type         => NULL);
        IF l_snihss5_value IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M053') || l_title_colon ||
                      l_snihss5_value || l_lf;
        END IF;
        -- ISS
        l_iss_value := pk_sev_scores_core.get_last_sev_score_total(i_lang          => i_lang,
                                                                   i_prof          => i_prof,
                                                                   i_id_episode    => i_id_episode,
                                                                   i_mtos_score    => pk_sev_scores_constant.g_id_score_isstw,
                                                                   i_internal_name => pk_sev_scores_constant.g_param_type_msts);
        IF l_iss_value IS NOT NULL
        THEN
            l_note := l_note || pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M054') || l_title_colon ||
                      l_iss_value;
        END IF;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_asse_score;

    /**************************************************************************
    * get import default priority
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Webber Chiou
    * @version                        2.7.2.4
    * @since                          13/02/2018
    **************************************************************************/
    FUNCTION get_import_asse_priority
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      VARCHAR2(4000 CHAR);
        l_id_option sys_config.value%TYPE := pk_sysconfig.get_config('MULTICHOICE_DEFAULT_PRIORITY', i_prof);
        l_func_name VARCHAR2(50 CHAR) := 'GET_IMPORT_DEFAULT_PRORITY';
    BEGIN
    
        g_error := 'CALL pk_api_multichoice.get_multichoice_option_desc';
        pk_alertlog.log_debug(g_error);
    
        l_note := pk_api_multichoice.get_multichoice_option_desc(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_id_option => l_id_option);
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_asse_priority;

    /**************************************************************************
    * get import transfer out clinical service
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.2.3
    * @since                          16/01/2018
    **************************************************************************/
    FUNCTION get_import_trans_cs_dest
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_clin_service pk_translation.t_desc_translation;
        l_id_patient   patient.id_patient%TYPE;
        l_id_visit     visit.id_visit%TYPE;
        l_id_episode   episode.id_episode%TYPE;
        l_func_name    VARCHAR2(30 CHAR) := 'GET_IMPORT_TRANS_CS_DEST';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get clinical service destination
        g_error := 'CALL pk_hand_off_core.get_last_trans_cs_dest';
        pk_alertlog.log_debug(g_error);
    
        l_clin_service := pk_hand_off_core.get_last_transf_cs(i_lang    => i_lang,
                                                              i_prof    => i_prof,
                                                              i_episode => l_id_episode);
    
        IF (l_clin_service IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_clin_service,
                                                                 l_clin_service,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_trans_cs_dest;

    /**************************************************************************
    * check_reenter_icu
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7.2.3
    * @since                          17/1/2018
    **************************************************************************/
    FUNCTION check_reenter_icu
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note      VARCHAR2(4000 CHAR);
        l_func_name VARCHAR2(25 CHAR) := 'CHECK_REENTER_ICU';
        l_count     NUMBER(3) := 0;
    BEGIN
        IF pk_bmng.check_reenter_icu(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode)
        THEN
            l_note := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M004');
        ELSE
            l_note := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M005');
        END IF;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END check_reenter_icu;

    /**************************************************************************
    * get_cur_pre_icu_info
    * Get current and previous icu info
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7.2.3
    * @since                          17/1/2018
    **************************************************************************/
    FUNCTION get_cur_pre_icu_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note                  VARCHAR2(4000 CHAR);
        l_func_name             VARCHAR2(25 CHAR) := 'GET_CP_ICU_INFO';
        l_current_icu_in_tstz   TIMESTAMP WITH LOCAL TIME ZONE;
        l_previous_icu_in_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_previous_icu_out_tstz TIMESTAMP WITH LOCAL TIME ZONE;
        l_colon   CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_colon;
        l_space   CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_space;
        l_newline CONSTANT VARCHAR2(2 CHAR) := pk_prog_notes_constants.g_new_line;
        l_pre_in_desc      VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M006');
        l_pre_out_desc     VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M007');
        l_day_desc1        VARCHAR2(200 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                        i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M008');
        l_day_desc2        VARCHAR2(50 CHAR) := pk_message.get_message(i_lang      => i_lang,
                                                                       i_code_mess => 'ICU_ASSESSMENT_SUMMARY.M009');
        l_icu_io_date_note VARCHAR2(100 CHAR);
        l_diff             INTERVAL DAY TO SECOND;
        l_diff_num         NUMBER;
    BEGIN
    
        IF pk_bmng.check_reenter_icu(i_lang => i_lang, i_prof => i_prof, i_episode => i_id_episode)
        THEN
            l_current_icu_in_tstz := pk_bmng.get_last_icu_in_date(i_lang    => i_lang,
                                                                  i_prof    => i_prof,
                                                                  i_episode => i_id_episode);
        
            IF NOT pk_bmng.get_previous_icu_io_date(i_lang         => i_lang,
                                                    i_prof         => i_prof,
                                                    i_episode      => i_id_episode,
                                                    o_icu_in_date  => l_previous_icu_in_tstz,
                                                    o_icu_out_date => l_previous_icu_out_tstz,
                                                    o_error        => o_error)
            THEN
                RAISE g_other_exception;
            END IF;
        
            l_diff     := l_current_icu_in_tstz - l_previous_icu_out_tstz;
            l_diff_num := extract(DAY FROM l_diff);
            l_note     := l_pre_in_desc || l_colon || l_space ||
                          pk_date_utils.date_char_tsz(i_lang,
                                                      l_previous_icu_in_tstz,
                                                      i_prof.institution,
                                                      i_prof.software) || l_newline || l_pre_out_desc || l_colon ||
                          l_space || pk_date_utils.date_char_tsz(i_lang,
                                                                 l_previous_icu_out_tstz,
                                                                 i_prof.institution,
                                                                 i_prof.software) || l_newline || l_day_desc1 ||
                          l_colon || l_space || l_diff_num || l_space || l_day_desc2;
        ELSE
            l_note := NULL;
        END IF;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_cur_pre_icu_info;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.4.1                            
    * @since                          18/09/2018                            
    **************************************************************************/
    FUNCTION get_import_blood_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_blood_type VARCHAR2(4000 CHAR);
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_IMPORT_PROF_RESP';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL k_prog_notes_utils.get_admission_prof_resp';
        pk_alertlog.log_debug(g_error);
    
        l_blood_type := pk_hea_prv_aux.get_blood_type(i_lang => i_lang, i_prof => i_prof, i_id_patient => l_id_patient);
        IF (l_blood_type IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_blood_type,
                                                                 l_blood_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_blood_type;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.4.1                            
    * @since                          18/09/2018                            
    **************************************************************************/
    FUNCTION get_import_obstetric_index
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_obst_index VARCHAR2(4000 CHAR);
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_IMPORT_PROF_RESP';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL k_prog_notes_utils.get_admission_prof_resp';
        pk_alertlog.log_debug(g_error);
    
        l_obst_index := pk_pregnancy.get_obstetric_index(i_lang, i_prof, l_id_patient);
    
        IF (l_obst_index IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_obst_index,
                                                                 l_obst_index,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_obstetric_index;
    /**************************************************************************
    * get import data from current pregnacy
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita                   
    * @version                        2.8                            
    * @since                          18/08/2021                            
    **************************************************************************/
    FUNCTION get_import_current_pregnancy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_current_preg CLOB := NULL;
        l_id_patient        patient.id_patient%TYPE;
        l_id_visit          visit.id_visit%TYPE;
        l_id_episode        episode.id_episode%TYPE;
        l_func_name         VARCHAR2(25 CHAR) := 'GET_IMPORT_PROF_RESP';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get current pregnancy desc
        g_error := 'CALL pk_pregnancy.get_sp_current_pregnacy';
        pk_alertlog.log_debug(g_error);
    
        l_desc_current_preg := pk_pregnancy.get_sp_current_pregnacy(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_episode => l_id_episode,
                                                                    i_pat     => l_id_patient);
    
        IF (l_desc_current_preg IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_desc_current_preg,
                                                                 l_desc_current_preg,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_current_pregnancy;

    FUNCTION get_import_housing
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_housing    VARCHAR2(4000 CHAR);
        l_id_home    home.id_home%TYPE;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_IMPORT_HOUSING';
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL pk_social.get_home_summary_page';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_social.get_home_summary_page(i_lang       => i_lang,
                                               i_prof       => i_prof,
                                               i_id_patient => l_id_patient,
                                               o_id_home    => l_id_home,
                                               o_home_desc  => l_housing)
        THEN
        
            RAISE g_other_exception;
        END IF;
    
        IF (l_housing IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_housing,
                                                                 l_housing,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 l_id_home,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_housing;

    FUNCTION get_import_soc_class
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_soc_class            VARCHAR2(4000 CHAR);
        l_id_patient           patient.id_patient%TYPE;
        l_id_visit             visit.id_visit%TYPE;
        l_id_episode           episode.id_episode%TYPE;
        l_func_name            VARCHAR2(25 CHAR) := 'GET_IMPORT_SOC_CLASS';
        l_id_pat_fam_soc_class pat_fam_soc_class_hist.id_pat_fam_soc_class_hist%TYPE;
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL pk_social.get_soc_class_summary_page';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_social.get_soc_class_summary_page(i_lang                 => i_lang,
                                                    i_prof                 => i_prof,
                                                    i_id_patient           => l_id_patient,
                                                    o_id_pat_fam_soc_class => l_id_pat_fam_soc_class,
                                                    o_pat_fam_soc_desc     => l_soc_class)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (l_soc_class IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_soc_class,
                                                                 l_soc_class,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 l_id_pat_fam_soc_class,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_soc_class;

    FUNCTION get_import_house_financial
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_house_financial    VARCHAR2(4000 CHAR);
        l_id_patient         patient.id_patient%TYPE;
        l_id_visit           visit.id_visit%TYPE;
        l_id_episode         episode.id_episode%TYPE;
        l_func_name          VARCHAR2(30 CHAR) := 'GET_IMPORT_HOUSE_FINANCIAL';
        l_id_family_monetary family_monetary.id_family_monetary%TYPE;
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL pk_social.get_house_fin_summary_page';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_social.get_house_fin_summary_page(i_lang           => i_lang,
                                                    i_prof           => i_prof,
                                                    i_id_patient     => l_id_patient,
                                                    o_id_fam_mon     => l_id_family_monetary,
                                                    o_house_fin_desc => l_house_financial)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF (l_house_financial IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_house_financial,
                                                                 l_house_financial,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 l_id_family_monetary,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_house_financial;

    FUNCTION get_import_household
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_household      table_varchar;
        l_tbl_id_patient table_number;
        l_id_patient     patient.id_patient%TYPE;
        l_id_visit       visit.id_visit%TYPE;
        l_id_episode     episode.id_episode%TYPE;
        l_func_name      VARCHAR2(25 CHAR) := 'GET_IMPORT_HOUSEHOLD';
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL pk_social.get_household_summary_page';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_social.get_household_summary_page(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_id_patient         => l_id_patient,
                                                    o_tbl_id_patient     => l_tbl_id_patient,
                                                    o_tbl_household_desc => l_household)
        THEN
            RAISE g_other_exception;
        END IF;
    
        IF l_household.exists(1)
        THEN
            FOR i IN l_household.first .. l_household.last
            LOOP
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_household(i),
                                                                     l_household(i),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     l_tbl_id_patient(i),
                                                                     i_id_pn_task_type,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
                o_count_records := i;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_household;

    FUNCTION get_import_interv_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_interv_plan table_varchar;
        l_id_patient  patient.id_patient%TYPE;
        l_id_visit    visit.id_visit%TYPE;
        l_id_episode  episode.id_episode%TYPE;
        l_func_name   VARCHAR2(25 CHAR) := 'GET_IMPORT_INTERV_PLAN';
    
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get prof resp
        g_error := 'CALL pk_social.get_interv_plan_summary_page';
        pk_alertlog.log_debug(g_error);
    
        l_interv_plan := pk_social.get_interv_plan_summary_page(i_lang, i_prof, l_id_patient);
    
        IF l_interv_plan.exists(1)
        THEN
            FOR i IN l_interv_plan.first .. l_interv_plan.last
            LOOP
                io_data_import.extend;
                io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                     i_pn_data_block,
                                                                     l_interv_plan(i),
                                                                     l_interv_plan(i),
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     i_id_pn_task_type,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL,
                                                                     NULL);
                o_count_records := i;
            END LOOP;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_import_interv_plan;

    /**************************************************************************
    * get import data from patient identification
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Vítor Sá                
    * @version                        2.7.5.3                             
    * @since                          24-04-2019                            
    **************************************************************************/
    FUNCTION get_pat_identification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_scope                 IN NUMBER,
        i_scope_type            IN VARCHAR2,
        i_pn_soap_block         IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block         IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2,
        io_data_import          IN OUT t_coll_data_import,
        o_count_records         OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note       CLOB;
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_func_name  VARCHAR2(25 CHAR) := 'GET_PAT_IDENTIFICATION';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get pat identification
        g_error := 'CALL k_prog_notes_in.get_pat_identification';
        pk_alertlog.log_debug(g_error);
        l_note := pk_prog_notes_in.get_pat_identification(i_lang                  => i_lang,
                                                          i_prof                  => i_prof,
                                                          i_id_episode            => l_id_episode,
                                                          i_flg_description       => i_flg_description,
                                                          i_description_condition => i_description_condition);
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL, --13                                                                         
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_pat_identification;
    /**************************************************************************
    * get import data from grouped medication in last 24h
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita               
    * @version                        2.8.1.0                             
    * @since                          16-03-2020                            
    **************************************************************************/
    FUNCTION get_local_med_lastday
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note             CLOB;
        l_id_patient       patient.id_patient%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_id_episode       episode.id_episode%TYPE;
        l_med_hours        NUMBER(24) := 24;
        l_grouped_products t_tbl_prescs_grouped_by_prod;
        l_lf CONSTANT VARCHAR2(2 CHAR) := chr(10);
        l_func_name VARCHAR2(25 CHAR) := 'GET_LOCAL_MED_LASTDAY';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get medication administered here in last 24h 
        g_error := 'CALL pk_api_pfh_in.get_prescs_grouped_by';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_api_pfh_in.get_prescs_grouped_by_prod(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_episode       => l_id_episode,
                                                        i_flg_antibiotic   => pk_prog_notes_constants.g_no,
                                                        i_last_x_h         => l_med_hours,
                                                        o_grouped_products => l_grouped_products,
                                                        o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT l_grouped_products.count > 0
        THEN
            RETURN TRUE;
        END IF;
    
        FOR i IN l_grouped_products.first .. l_grouped_products.last
        LOOP
            l_note := l_note || l_grouped_products(i).medication_name || l_lf || l_grouped_products(i).presc_interval_descr || l_lf;
        END LOOP;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_local_med_lastday;

    /**************************************************************************
    * get import data from grouped medication (antibiotics admin here)
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita               
    * @version                        2.8.1.0                             
    * @since                          16-03-2020                            
    **************************************************************************/
    FUNCTION get_local_med_antibiotics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note             CLOB;
        l_id_patient       patient.id_patient%TYPE;
        l_id_visit         visit.id_visit%TYPE;
        l_id_episode       episode.id_episode%TYPE;
        l_med_hours        NUMBER(24) := NULL;
        l_grouped_products t_tbl_prescs_grouped_by_prod;
        l_lf CONSTANT VARCHAR2(2 CHAR) := chr(10);
        l_func_name VARCHAR2(25 CHAR) := 'GET_LOCAL_MED_LASTDAY';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_other_exception;
        END IF;
    
        --get medication administered here (antibiotics)
        g_error := 'CALL pk_api_pfh_in.get_local_med_antibiotics';
        pk_alertlog.log_debug(g_error);
    
        IF NOT pk_api_pfh_in.get_prescs_grouped_by_prod(i_lang             => i_lang,
                                                        i_prof             => i_prof,
                                                        i_id_episode       => l_id_episode,
                                                        i_flg_antibiotic   => pk_prog_notes_constants.g_yes,
                                                        i_last_x_h         => l_med_hours,
                                                        o_grouped_products => l_grouped_products,
                                                        o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF NOT l_grouped_products.count > 0
        THEN
            RETURN TRUE;
        END IF;
    
        FOR i IN l_grouped_products.first .. l_grouped_products.last
        LOOP
            l_note := l_note || l_grouped_products(i).medication_name || l_lf || l_grouped_products(i).presc_interval_descr || l_lf;
        END LOOP;
    
        IF (l_note IS NOT NULL)
        THEN
            io_data_import.extend;
            io_data_import(io_data_import.last) := t_data_import(i_pn_soap_block,
                                                                 i_pn_data_block,
                                                                 l_note,
                                                                 l_note,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 i_id_pn_task_type,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 NULL);
            o_count_records := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_other_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_local_med_antibiotics;
BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
END pk_prog_notes_dblock;
/
