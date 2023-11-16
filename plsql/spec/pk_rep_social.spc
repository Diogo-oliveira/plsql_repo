/*-- Last Change Revision: $Rev: 1895303 $*/
/*-- Last Change by: $Author: nuno.coelho $*/
/*-- Date of last change: $Date: 2019-02-28 11:26:36 +0000 (qui, 28 fev 2019) $*/

CREATE OR REPLACE PACKAGE pk_rep_social IS

    /**
    * Get an episode's follow up notes list.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_follow_up_prof follow up notes records info
    * @param o_follow_up    follow up notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/02
    */
    FUNCTION get_followup_notes_rep
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
		i_show_cancelled IN VARCHAR2 DEFAULT NULL,
        o_follow_up_prof OUT pk_types.cursor_type,
        o_follow_up      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get an episode's discharge record history.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      actual episode identifier
    * @param o_discharge    discharges
    * @param o_discharge_prof discharges records info
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.1
    * @since                2011/03/09
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get the EHR social summary.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_labels       labels
    * @param o_episodes_det episodes
    * @param o_diagnosis    social diagnoses
    * @param o_interv_plan  social intervention plans
    * @param o_follow_up    follow up notes
    * @param o_soc_report   social report
    * @param o_soc_request  previous encounters data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2012/06/12
    */
    FUNCTION get_social_summary_ehr_rep
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        o_labels       OUT pk_types.cursor_type,
        o_episodes_det OUT pk_types.cursor_type,
        o_diagnosis    OUT pk_types.cursor_type,
        o_interv_plan  OUT pk_types.cursor_type,
        o_follow_up    OUT pk_types.cursor_type,
        o_soc_report   OUT pk_types.cursor_type,
        o_soc_request  OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

END pk_rep_social;
/
