/*-- Last Change Revision: $Rev: 2028603 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:49 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_dictation AS

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
        o_dictated_date out dictation_report.dictated_date%TYPE,
        o_signoff_date out dictation_report.signoff_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    
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
        o_dictated_date out dictation_report.dictated_date%TYPE,
        o_signoff_date out dictation_report.signoff_date%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    g_error VARCHAR2(4000 CHAR);
    g_found BOOLEAN;

END pk_dictation;
/
