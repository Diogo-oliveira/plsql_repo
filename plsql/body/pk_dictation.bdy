/*-- Last Change Revision: $Rev: 2026960 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:33 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_dictation AS

    /********************************************************************************************
    * Create/update the Progress Note associated with the Dictation
    *
    * @param i_lang                  language identifier
    * @param i_prof                  professional, software, institution
    * @param i_id_dictation_report   dictation identifier
    * @param i_work_type             work type identifier
    * @param i_report_status         Dictation status (0- preliminary report, 2- Signed-off)
    * @param i_id_episode            episode identifier
    * @param i_dt_pn_date            report information
    * @param i_pn_note               transcribed date
    * @param i_id_professional       signoff date
    * @param i_prof_signoff          Professional ID that performed the sign-off
    * @param i_signoff_date          Sign-off date
    * @param i_last_update_date      Last update date
    *
    * @return o_error
    *
    * @return  true or false on success or error
    * @author  Rui Batista
    * @version 1.0
    * @since  2011/02/16
    **********************************************************************************************/

    FUNCTION set_prog_note
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_dictation_report IN dictation_report.id_dictation_report%TYPE,
        i_work_type           IN work_type.id_work_type%TYPE,
        i_report_status       IN dictation_report.report_status%TYPE,
        i_id_episode          IN episode.id_episode%TYPE,
        i_dt_pn_date          IN epis_pn.dt_pn_date%TYPE,
        i_pn_note             IN epis_pn_det.pn_note%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        i_prof_signoff        IN professional.id_professional%TYPE,
        i_signoff_date        IN epis_pn.dt_signoff%TYPE,
        i_last_update_date    IN dictation_report.last_update_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pn_flg_status   epis_pn.flg_status%TYPE;
        l_id_pn_note_type epis_pn.id_pn_note_type%TYPE;
        l_current_date    TIMESTAMP WITH LOCAL TIME ZONE;
        l_datablock_dictation_hp CONSTANT pn_data_block.id_pn_data_block%TYPE := 96;
        l_soapblock_dictation_hp CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 19;
        l_datablock_dictation_pn CONSTANT pn_data_block.id_pn_data_block%TYPE := 92;
        l_soapblock_dictation_pn CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 17;
        l_datablock_date         CONSTANT pn_data_block.id_pn_data_block%TYPE := 47;
        l_soapblock_date         CONSTANT pn_soap_block.id_pn_soap_block%TYPE := 6;
    
        l_pn_note_type_hp CONSTANT pn_note_type.id_pn_note_type%TYPE := 8;
        l_pn_note_type_pn CONSTANT pn_note_type.id_pn_note_type%TYPE := 7;
    
        l_id_epis_pn epis_pn.id_epis_pn%TYPE;
    
        l_epis_pn_addendum     epis_pn_addendum.id_epis_pn_addendum%TYPE;
        l_epis_pn              epis_pn.id_epis_pn%TYPE;
        l_out_epis_pn_addendum epis_pn_addendum.id_epis_pn_addendum%TYPE;
    
        l_pn_data_block table_number;
        l_pn_soap_block table_number;
        l_id_tasks      table_number;
        l_pn_note       table_clob;
        l_note_date     VARCHAR2(50 CHAR);
    
    BEGIN
    
        --fill data block information
        l_note_date := pk_date_utils.date_char_tsz(i_lang => i_lang,
                                                   i_date => i_dt_pn_date,
                                                   i_inst => i_prof.institution,
                                                   i_soft => i_prof.software);
    
        l_id_tasks := table_number(NULL, NULL);
        l_pn_note  := table_clob(l_note_date, i_pn_note);
    
        l_current_date := current_timestamp;
    
        --Determine the note status based on the dictation status
        IF nvl(i_report_status, 0) = 0
        THEN
            --Draft
            l_pn_flg_status := pk_prog_notes_constants.g_epis_pn_flg_status_d;
        ELSIF nvl(i_report_status, 0) = 2
        THEN
            --Signed-off
            l_pn_flg_status := pk_prog_notes_constants.g_epis_pn_flg_status_s;
        END IF;
    
        --Determine de Note type based on the dictation work type
        IF nvl(i_work_type, 0) = 20
        THEN
            --H&P
            l_id_pn_note_type := l_pn_note_type_hp;
        
            l_pn_data_block := table_number(l_datablock_date, l_datablock_dictation_hp);
            l_pn_soap_block := table_number(l_soapblock_date, l_soapblock_dictation_hp);
        ELSE
            --Progress Note
            l_id_pn_note_type := l_pn_note_type_pn;
        
            l_pn_data_block := table_number(l_datablock_date, l_datablock_dictation_pn);
            l_pn_soap_block := table_number(l_soapblock_date, l_soapblock_dictation_pn);
        END IF;
    
        IF nvl(i_report_status, 0) IN (0, 2)
        THEN
            --If is a progress note...        
            g_error := 'Create new PN';
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => 'PK_DICTATION',
                                           sub_object_name => 'INSERT_DICTATION_REPORT');
        
            IF NOT pk_prog_notes_core.set_save_def_note(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_epis_pn             => NULL,
                                                        i_id_dictation_report => i_id_dictation_report,
                                                        i_id_episode          => i_id_episode,
                                                        i_pn_flg_status       => l_pn_flg_status,
                                                        i_id_pn_note_type     => l_id_pn_note_type,
                                                        i_dt_pn_date          => i_dt_pn_date,
                                                        i_id_dep_clin_serv    => NULL,
                                                        i_id_pn_data_block    => l_pn_data_block,
                                                        i_id_pn_soap_block    => l_pn_soap_block,
                                                        i_id_task             => l_id_tasks,
                                                        i_id_task_type        => l_id_tasks,
                                                        i_pn_note             => l_pn_note,
                                                        i_id_professional     => i_id_professional,
                                                        i_dt_create           => i_dt_pn_date,
                                                        i_dt_last_update      => nvl(i_last_update_date, l_current_date),
                                                        i_dt_sent_to_hist     => nvl(i_last_update_date, l_current_date),
                                                        i_id_prof_sign_off    => i_prof_signoff,
                                                        i_dt_sign_off         => i_signoff_date,
                                                        o_id_epis_pn          => l_id_epis_pn,
                                                        o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        ELSIF nvl(i_report_status, 0) IN (3, 4)
        THEN
            --If is a progress note addendum get the progress note addendum ID, if exists
            BEGIN
                SELECT epa.id_epis_pn, epa.id_epis_pn_addendum
                  INTO l_epis_pn, l_epis_pn_addendum
                  FROM epis_pn_addendum epa
                 WHERE epa.flg_type = pk_prog_notes_constants.g_epa_flg_type_addendum
                   AND epa.id_epis_pn IN (SELECT ep.id_epis_pn
                                            FROM epis_pn ep
                                           WHERE ep.id_dictation_report = i_id_dictation_report);
            EXCEPTION
                WHEN no_data_found THEN
                    --Addendum doesn't exists yet
                    l_epis_pn_addendum := NULL;
                    l_epis_pn          := NULL;
                WHEN too_many_rows THEN
                    g_error := 'Too many addendums for ID_DICTATION_REPORT = ' || to_char(i_id_dictation_report);
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => 'PK_DICTATION',
                                                   sub_object_name => 'INSERT_DICTATION_REPORT');
                    RETURN FALSE;
                WHEN OTHERS THEN
                    g_error := 'Error found getting the addendum ID for ID_DICTATION_REPORT = ' ||
                               to_char(i_id_dictation_report);
                    alertlog.pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => 'PK_DICTATION',
                                                   sub_object_name => 'INSERT_DICTATION_REPORT');
                    RETURN FALSE;
            END;
        
            --Get the progress note ID. IT MUST EXIST!!!
            IF l_epis_pn IS NULL
            THEN
                BEGIN
                    SELECT ep.id_epis_pn
                      INTO l_epis_pn
                      FROM epis_pn ep
                     WHERE ep.id_dictation_report = i_id_dictation_report;
                EXCEPTION
                    WHEN no_data_found THEN
                        g_error := 'Error: Progress Note ID not found for ID_DICTATION_REPORT = ' ||
                                   to_char(i_id_dictation_report);
                        alertlog.pk_alertlog.log_debug(text            => g_error,
                                                       object_name     => 'PK_DICTATION',
                                                       sub_object_name => 'INSERT_DICTATION_REPORT');
                        RETURN FALSE;
                    
                    WHEN OTHERS THEN
                        g_error := 'Error getting the Progress Note ID for ID_DICTATION_REPORT = ' ||
                                   to_char(i_id_dictation_report);
                        alertlog.pk_alertlog.log_debug(text            => g_error,
                                                       object_name     => 'PK_DICTATION',
                                                       sub_object_name => 'INSERT_DICTATION_REPORT');
                        RETURN FALSE;
                END;
            END IF;
        
            --Create ou update addendum
            g_error := 'Create addendum for ID_DICTATION_REPORT = ' || to_char(i_id_dictation_report);
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => 'PK_DICTATION',
                                           sub_object_name => 'INSERT_DICTATION_REPORT');
            IF NOT pk_prog_notes_core.set_pn_addendum_internal(i_lang                => i_lang,
                                                               i_prof                => profissional(i_id_professional,
                                                                                                     i_prof.institution,
                                                                                                     i_prof.software),
                                                               i_id_epis_pn          => l_epis_pn,
                                                               i_id_epis_pn_addendum => l_epis_pn_addendum,
                                                               i_pn_addendum         => i_pn_note,
                                                               i_dt_addendum         => i_dt_pn_date,
                                                               i_last_update_date    => i_last_update_date,
                                                               o_epis_pn_addendum    => l_out_epis_pn_addendum,
                                                               o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
            --if the addendum is already signed-off
            IF nvl(i_report_status, 0) = 4
            THEN
                g_error := 'Sign-off the addendum for ID_DICTATION_REPORT = ' || to_char(i_id_dictation_report);
                alertlog.pk_alertlog.log_debug(text            => g_error,
                                               object_name     => 'PK_DICTATION',
                                               sub_object_name => 'INSERT_DICTATION_REPORT');
                IF NOT pk_prog_notes_core.set_signoff_addendum(i_lang             => i_lang,
                                                               i_prof             => profissional(i_prof_signoff,
                                                                                                  i_prof.institution,
                                                                                                  i_prof.software),
                                                               i_id_epis_pn       => l_epis_pn,
                                                               i_epis_pn_addendum => l_epis_pn_addendum,
                                                               i_pn_addendum      => i_pn_note,
                                                               i_dt_signoff       => i_signoff_date,
                                                               i_flg_just_save    => 'N',
                                                               i_flg_edited       => 'N',
                                                               i_flg_hist         => 'N',
                                                               o_epis_pn_addendum => l_out_epis_pn_addendum,
                                                               o_error            => o_error)
                THEN
                    RETURN FALSE;
                END IF;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DICTATION',
                                              'SET_PROG_NOTE',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;
    /********************************************************************************************
    * insert the dictation report in the plan area
    *
    * @param i_language                 language identifier
    * @param i_professional             professional identifier
    * @param i_institution              institution identifier
    * @param i_software                 software identifier
    * @param i_external                 external identifier
    * @param i_patient                  patient identifier
    * @param i_episode                  episode identifier
    * @param i_work_type                work type identifier
    * @param i_report_status            report status
    * @param i_report_information       report information
    * @param i_prof_dictated            professional dictated identifier
    * @param i_prof_transcribed         professional transcribed identifier
    * @param i_prof_signoff             professional sign-off identifier
    * @param i_dictated_date            dictation date
    * @param i_transcribed_date         transcribed date
    * @param i_signoff_date             signoff date
    * @param i_last_update_date         last update date
    *
    * @return o_id_dictation_report     dictation report identifier
    * @return o_error
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/04/27
    **********************************************************************************************/
    FUNCTION insert_dictation_report
    (
        i_language            IN language.id_language%TYPE,
        i_professional        IN professional.id_professional%TYPE,
        i_institution         IN institution.id_institution%TYPE,
        i_software            IN software.id_software%TYPE,
        i_external            IN dictation_report.id_external%TYPE,
        i_patient             IN dictation_report.id_patient%TYPE,
        i_episode             IN dictation_report.id_episode%TYPE,
        i_work_type           IN dictation_report.id_work_type%TYPE,
        i_report_status       IN dictation_report.report_status%TYPE,
        i_report_information  IN dictation_report.report_information%TYPE,
        i_prof_dictated       IN dictation_report.id_prof_dictated%TYPE,
        i_prof_transcribed    IN dictation_report.id_prof_transcribed%TYPE,
        i_prof_signoff        IN dictation_report.id_prof_signoff%TYPE,
        i_dictated_date       IN dictation_report.dictated_date%TYPE,
        i_transcribed_date    IN dictation_report.transcribed_date%TYPE,
        i_signoff_date        IN dictation_report.signoff_date%TYPE,
        i_last_update_date    IN dictation_report.last_update_date%TYPE,
        o_id_dictation_report OUT dictation_report.id_dictation_report%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids table_varchar;
    
    BEGIN
    
        g_error := 'GET SEQ_DICTATION_REPORT.NEXTVAL';
        SELECT ts_dictation_report.next_key
          INTO o_id_dictation_report
          FROM dual;
    
        g_error := 'INSERT INTO DICTATION REPORT';
        ts_dictation_report.ins(id_dictation_report_in => o_id_dictation_report,
                                id_external_in         => i_external,
                                id_patient_in          => i_patient,
                                id_episode_in          => i_episode,
                                id_work_type_in        => i_work_type,
                                report_status_in       => i_report_status,
                                report_information_in  => i_report_information,
                                id_prof_dictated_in    => i_prof_dictated,
                                id_prof_transcribed_in => i_prof_transcribed,
                                id_prof_signoff_in     => i_prof_signoff,
                                dictated_date_in       => i_dictated_date,
                                transcribed_date_in    => i_transcribed_date,
                                signoff_date_in        => i_signoff_date,
                                last_update_date_in    => i_last_update_date,
                                rows_out               => l_rowids);
    
        t_data_gov_mnt.process_insert(i_lang       => i_language,
                                      i_prof       => profissional(i_professional, i_institution, i_software),
                                      i_table_name => 'DICTATION_REPORT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --If is a dictation for a Progress Note or H&P then create a new note 
        g_error := 'Create new PN. Call to set_prog_note';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => 'PK_DICTATION',
                                       sub_object_name => 'INSERT_DICTATION_REPORT');
        IF nvl(i_work_type, 0) IN (20, 21, 22, 23)
        THEN
            IF NOT set_prog_note(i_lang                => i_language,
                                 i_prof                => profissional(i_professional, i_institution, i_software),
                                 i_id_dictation_report => o_id_dictation_report,
                                 i_work_type           => i_work_type,
                                 i_report_status       => i_report_status,
                                 i_id_episode          => i_episode,
                                 i_dt_pn_date          => i_dictated_date,
                                 i_pn_note             => i_report_information,
                                 i_id_professional     => i_prof_dictated,
                                 i_prof_signoff        => i_prof_signoff,
                                 i_signoff_date        => i_signoff_date,
                                 i_last_update_date    => i_last_update_date,
                                 o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DICTATION',
                                              'INSERT_DICTATION_REPORT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * update the dictation report in the plan area
    *
    * @param i_language                 language identifier
    * @param i_professional             professional identifier
    * @param i_institution              institution identifier
    * @param i_software                 software identifier
    * @param i_external                 external identifier
    * @param i_work_type                work type identifier
    * @param i_report_status            report status
    * @param i_report_information       report information
    * @param i_prof_dictated            professional dictated identifier
    * @param i_prof_transcribed         professional transcribed identifier
    * @param i_prof_signoff             professional sign-off identifier
    * @param i_dictated_date            dictation date
    * @param i_transcribed_date         transcribed date
    * @param i_signoff_date             signoff date
    * @param i_last_update_date         last update date
    *
    * @return o_error
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/04/27
    **********************************************************************************************/
    FUNCTION update_dictation_report
    (
        i_language           IN language.id_language%TYPE,
        i_professional       IN professional.id_professional%TYPE,
        i_institution        IN institution.id_institution%TYPE,
        i_software           IN software.id_software%TYPE,
        i_external           IN dictation_report.id_external%TYPE,
        i_work_type          IN dictation_report.id_work_type%TYPE,
        i_report_status      IN dictation_report.report_status%TYPE,
        i_report_information IN dictation_report.report_information%TYPE,
        i_prof_dictated      IN dictation_report.id_prof_dictated%TYPE,
        i_prof_transcribed   IN dictation_report.id_prof_transcribed%TYPE,
        i_prof_signoff       IN dictation_report.id_prof_signoff%TYPE,
        i_dictated_date      IN dictation_report.dictated_date%TYPE,
        i_transcribed_date   IN dictation_report.transcribed_date%TYPE,
        i_signoff_date       IN dictation_report.signoff_date%TYPE,
        i_last_update_date   IN dictation_report.last_update_date%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_rowids_hist           table_varchar;
        l_rowids                table_varchar;
        v_dictation_report_hist dictation_report_hist%ROWTYPE;
    
        CURSOR c_dictation_report(l_id dictation_report.id_external%TYPE) IS
            SELECT dr.id_dictation_report,
                   dr.id_patient,
                   dr.id_episode,
                   dr.id_work_type,
                   dr.report_status,
                   dr.report_information,
                   dr.id_prof_dictated,
                   dr.id_prof_transcribed,
                   dr.id_prof_signoff,
                   dr.dictated_date,
                   dr.transcribed_date,
                   dr.signoff_date,
                   dr.last_update_date
              FROM dictation_report dr
             WHERE dr.id_external = l_id;
    
    BEGIN
    
        g_error := 'OPEN CURSOR C_DICTATION_REPORT';
        OPEN c_dictation_report(i_external);
        FETCH c_dictation_report
            INTO v_dictation_report_hist.id_dictation_report,
                 v_dictation_report_hist.id_patient,
                 v_dictation_report_hist.id_episode,
                 v_dictation_report_hist.id_work_type,
                 v_dictation_report_hist.report_status,
                 v_dictation_report_hist.report_information,
                 v_dictation_report_hist.id_prof_dictated,
                 v_dictation_report_hist.id_prof_transcribed,
                 v_dictation_report_hist.id_prof_signoff,
                 v_dictation_report_hist.dictated_date,
                 v_dictation_report_hist.transcribed_date,
                 v_dictation_report_hist.signoff_date,
                 v_dictation_report_hist.last_update_date;
        g_found := c_dictation_report%NOTFOUND;
        CLOSE c_dictation_report;
    
        g_error := 'INSERT INTO DICTATION REPORT HIST';
        ts_dictation_report_hist.ins(id_dictation_report_hist_in => ts_dictation_report_hist.next_key,
                                     id_external_in              => i_external,
                                     id_dictation_report_in      => v_dictation_report_hist.id_dictation_report,
                                     id_patient_in               => v_dictation_report_hist.id_patient,
                                     id_episode_in               => v_dictation_report_hist.id_episode,
                                     id_work_type_in             => v_dictation_report_hist.id_work_type,
                                     report_status_in            => v_dictation_report_hist.report_status,
                                     report_information_in       => v_dictation_report_hist.report_information,
                                     id_prof_dictated_in         => v_dictation_report_hist.id_prof_dictated,
                                     id_prof_transcribed_in      => v_dictation_report_hist.id_prof_transcribed,
                                     id_prof_signoff_in          => v_dictation_report_hist.id_prof_signoff,
                                     dictated_date_in            => v_dictation_report_hist.dictated_date,
                                     transcribed_date_in         => v_dictation_report_hist.transcribed_date,
                                     signoff_date_in             => v_dictation_report_hist.signoff_date,
                                     last_update_date_in         => v_dictation_report_hist.last_update_date,
                                     rows_out                    => l_rowids_hist);
    
        t_data_gov_mnt.process_insert(i_lang       => i_language,
                                      i_prof       => profissional(i_professional, i_institution, i_software),
                                      i_table_name => 'DICTATION_REPORT_HIST',
                                      i_rowids     => l_rowids_hist,
                                      o_error      => o_error);
    
        g_error := 'UPDATE DICTATION REPORT';
        ts_dictation_report.upd(id_work_type_in        => i_work_type,
                                report_status_in       => i_report_status,
                                report_information_in  => i_report_information,
                                id_prof_dictated_in    => i_prof_dictated,
                                id_prof_transcribed_in => i_prof_transcribed,
                                id_prof_signoff_in     => i_prof_signoff,
                                id_prof_signoff_nin    => FALSE,
                                dictated_date_in       => i_dictated_date,
                                dictated_date_nin      => FALSE,
                                transcribed_date_in    => i_transcribed_date,
                                transcribed_date_nin   => FALSE,
                                signoff_date_in        => i_signoff_date,
                                signoff_date_nin       => FALSE,
                                last_update_date_in    => i_last_update_date,
                                last_update_date_nin   => FALSE,
                                where_in               => 'id_external = ' || i_external,
                                rows_out               => l_rowids);
    
        t_data_gov_mnt.process_update(i_lang       => i_language,
                                      i_prof       => profissional(i_professional, i_institution, i_software),
                                      i_table_name => 'DICTATION_REPORT',
                                      i_rowids     => l_rowids,
                                      o_error      => o_error);
    
        --If is a dictation for a Progress Note or H&P then create a new note 
        g_error := 'Create new PN. Call to set_prog_note';
        alertlog.pk_alertlog.log_debug(text            => g_error,
                                       object_name     => 'PK_DICTATION',
                                       sub_object_name => 'INSERT_DICTATION_REPORT');
        IF nvl(i_work_type, 0) IN (20, 21)
        THEN
            IF NOT set_prog_note(i_lang                => i_language,
                                 i_prof                => profissional(i_professional, i_institution, i_software),
                                 i_id_dictation_report => v_dictation_report_hist.id_dictation_report,
                                 i_work_type           => i_work_type,
                                 i_report_status       => i_report_status,
                                 i_id_episode          => v_dictation_report_hist.id_episode,
                                 i_dt_pn_date          => i_dictated_date,
                                 i_pn_note             => i_report_information,
                                 i_id_professional     => i_prof_dictated,
                                 i_prof_signoff        => i_prof_signoff,
                                 i_signoff_date        => i_signoff_date,
                                 i_last_update_date    => i_last_update_date,
                                 o_error               => o_error)
            THEN
                RETURN FALSE;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DICTATION',
                                              'UPDATE_DICTATION_REPORT',
                                              o_error);
            pk_utils.undo_changes;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * check if a dictation report already exists
    *
    * @param i_external                 external identifier
    *
    * @return o_flg_exists              Yes or No if exists external identifier
    * @return o_id_dictation_report     dictation report identifier
    *
    * @return  true or false on success or error
    * @author  Paulo Teixeira
    * @version 1.0
    * @since  2010/04/27
    **********************************************************************************************/
    FUNCTION get_dictation_report
    (
        i_external            IN dictation_report.id_external%TYPE,
        o_flg_exists          OUT VARCHAR2,
        o_id_dictation_report OUT dictation_report.id_dictation_report%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        o_flg_exists := pk_alert_constant.g_no;
        g_error      := 'GET DICTATION REPORT';
    
        SELECT DISTINCT pk_alert_constant.g_yes, dr.id_dictation_report
          INTO o_flg_exists, o_id_dictation_report
          FROM dictation_report dr
         WHERE dr.id_external = i_external;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            o_flg_exists          := pk_alert_constant.g_no;
            o_id_dictation_report := NULL;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Get the dictation's transcribe date and professional and last update date
    *
    * @param i_lang                 language id
    * @param i_dictation_report     Dictation report id
    *
    * @param o_id_prof_transcribed Transcription professional id
    * @param o_transcribed_date    Transcription date
    * @param o_last_update_date    Last update date
    * @param o_dictated_date       Dictated date
    * @param o_signoff_date        Sign-off date
    * @param o_error               Error information
    *
    * @return  true or false on success or error
    * @author  Rui Batista
    * @version 1.0
    * @since  2011/02/17
    **********************************************************************************************/
    FUNCTION get_transcribe_info
    (
        i_lang                IN language.id_language%TYPE,
        i_dictation_report    IN dictation_report.id_dictation_report%TYPE,
        o_id_prof_transcribed OUT dictation_report.id_prof_transcribed%TYPE,
        o_transcribed_date    OUT dictation_report.transcribed_date%TYPE,
        o_last_update_date    OUT dictation_report.last_update_date%TYPE,
        o_dictated_date       OUT dictation_report.dictated_date%TYPE,
        o_signoff_date        OUT dictation_report.signoff_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --Get the Transcription information
        g_error := 'Get the Transcription information';
        SELECT id_prof_transcribed, transcribed_date, last_update_date, dr.signoff_date, dr.dictated_date
          INTO o_id_prof_transcribed, o_transcribed_date, o_last_update_date, o_signoff_date, o_dictated_date
          FROM dictation_report dr
         WHERE id_dictation_report = i_dictation_report;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_prof_transcribed := NULL;
            o_transcribed_date    := NULL;
            o_last_update_date    := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DICTATION',
                                              'GET_TRANSCRIBE_INFO',
                                              o_error);
            RETURN FALSE;
    END get_transcribe_info;

    /********************************************************************************************
    * Get the dictation's transcribe date and professional and last update date from the dictations history
    *
    * @param i_lang                 language id
    * @param i_dictation_report     Dictation report id
    * @param i_dt_last_update       Last update date
    * @param i_signoff_date         Sign-off date
    * @param i_dictated_date        Dictated date
    *
    * @param o_id_prof_transcribed Transcription professional id
    * @param o_transcribed_date    Transcription date
    * @param o_last_update_date    Last update date
    * @param o_dictated_date       Dictated date
    * @param o_signoff_date        Sign-off date
    * @param o_error               Error information
    *
    * @return  true or false on success or error
    * @author  Sofia Mendes
    * @version 2.6.0.5.2
    * @since  02-Mar-2011
    **********************************************************************************************/
    FUNCTION get_transcribe_info_hist
    (
        i_lang                IN language.id_language%TYPE,
        i_dictation_report    IN dictation_report.id_dictation_report%TYPE,
        i_dt_last_update      IN dictation_report.last_update_date%TYPE,
        i_signoff_date        IN dictation_report.signoff_date%TYPE,
        i_dictated_date       IN dictation_report.dictated_date%TYPE,
        o_id_prof_transcribed OUT dictation_report.id_prof_transcribed%TYPE,
        o_transcribed_date    OUT dictation_report.transcribed_date%TYPE,
        o_last_update_date    OUT dictation_report.last_update_date%TYPE,
        o_dictated_date       OUT dictation_report.dictated_date%TYPE,
        o_signoff_date        OUT dictation_report.signoff_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --Get the Transcription information
        g_error := 'Get the Transcription information';
        SELECT id_prof_transcribed, transcribed_date, last_update_date, dr.signoff_date, dr.dictated_date
          INTO o_id_prof_transcribed, o_transcribed_date, o_last_update_date, o_signoff_date, o_dictated_date
          FROM dictation_report_hist dr
         WHERE id_dictation_report = i_dictation_report
           AND (i_dt_last_update IS NULL OR dr.last_update_date = i_dt_last_update)
           AND (i_signoff_date IS NULL OR dr.signoff_date = i_signoff_date)
           AND (i_dictated_date IS NULL OR dr.dictated_date = i_dictated_date)
           AND rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_prof_transcribed := NULL;
            o_transcribed_date    := NULL;
            o_last_update_date    := NULL;
            RETURN TRUE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_DICTATION',
                                              'GET_TRANSCRIBE_INFO',
                                              o_error);
            RETURN FALSE;
    END get_transcribe_info_hist;

END pk_dictation;
/
