/*-- Last Change Revision: $Rev: 2026672 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:31 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_dictation AS

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
    FUNCTION api_insert_dictation_report
    (
        i_language            IN LANGUAGE.id_language%TYPE,
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
    BEGIN
        IF NOT pk_dictation.insert_dictation_report(i_language            => i_language,
                                                    i_professional        => i_professional,
                                                    i_institution         => i_institution,
                                                    i_software            => i_software,
                                                    i_external            => i_external,
                                                    i_patient             => i_patient,
                                                    i_episode             => i_episode,
                                                    i_work_type           => i_work_type,
                                                    i_report_status       => i_report_status,
                                                    i_report_information  => i_report_information,
                                                    i_prof_dictated       => i_prof_dictated,
                                                    i_prof_transcribed    => i_prof_transcribed,
                                                    i_prof_signoff        => i_prof_signoff,
                                                    i_dictated_date       => i_dictated_date,
                                                    i_transcribed_date    => i_transcribed_date,
                                                    i_signoff_date        => i_signoff_date,
                                                    i_last_update_date    => i_last_update_date,
                                                    o_id_dictation_report => o_id_dictation_report,
                                                    o_error               => o_error)
        THEN
            RETURN FALSE;
        ELSE
            COMMIT;
            RETURN TRUE;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_DICTATION',
                                              'API_INSERT_DICTATION_REPORT',
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
    FUNCTION api_update_dictation_report
    (
        i_language           IN LANGUAGE.id_language%TYPE,
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
    BEGIN
        IF NOT pk_dictation.update_dictation_report(i_language           => i_language,
                                                    i_professional       => i_professional,
                                                    i_institution        => i_institution,
                                                    i_software           => i_software,
                                                    i_external           => i_external,
                                                    i_work_type          => i_work_type,
                                                    i_report_status      => i_report_status,
                                                    i_report_information => i_report_information,
                                                    i_prof_dictated      => i_prof_dictated,
                                                    i_prof_transcribed   => i_prof_transcribed,
                                                    i_prof_signoff       => i_prof_signoff,
                                                    i_dictated_date      => i_dictated_date,
                                                    i_transcribed_date   => i_transcribed_date,
                                                    i_signoff_date       => i_signoff_date,
                                                    i_last_update_date   => i_last_update_date,
                                                    o_error              => o_error)
        THEN
            RETURN FALSE;
        ELSE
            COMMIT;
            RETURN TRUE;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_language,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'PK_API_DICTATION',
                                              'API_UPDATE_DICTATION_REPORT',
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
    FUNCTION api_get_dictation
    (
        i_external            IN dictation_report.id_external%TYPE,
        o_flg_exists          OUT VARCHAR2,
        o_id_dictation_report OUT dictation_report.id_dictation_report%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        IF NOT pk_dictation.get_dictation_report(i_external            => i_external,
                                                 o_flg_exists          => o_flg_exists,
                                                 o_id_dictation_report => o_id_dictation_report)
        THEN
            RETURN FALSE;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
    END;

END pk_api_dictation;
/
