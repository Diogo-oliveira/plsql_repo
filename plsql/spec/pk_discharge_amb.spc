/*-- Last Change Revision: $Rev: 1940587 $*/
/*-- Last Change by: $Author: cristina.oliveira $*/
/*-- Date of last change: $Date: 2020-03-16 15:17:31 +0000 (seg, 16 mar 2020) $*/

CREATE OR REPLACE PACKAGE pk_discharge_amb IS

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Sofia Mendes
    * @version                 2.6.0.3
    * @since                  29-Jun-2010
    */
    FUNCTION get_discharge
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        i_show_destiny   IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get an episode's discharge record history, for reports layer usage.
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

    /*
    * Get discharge data for the create/edit screen.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param o_discharge      discharge
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_edit
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_discharge IN discharge.id_discharge%TYPE,
        o_discharge OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Check if the CREATE button must be enabled
    * in the discharge screen.
    *
    * @param i_lang           language identifier
    * @param i_episode        episode identifier
    * @param o_create         'Y' to enable create, 'N' otherwise
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_discharge_create
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_create  OUT VARCHAR2,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Get necessary domains for discharge registration.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param o_destiny        discharge destinies
    * @param o_time_unit      time units
    * @param o_type_closure   type of closure
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION get_domains
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        o_destiny      OUT pk_types.cursor_type,
        o_time_unit    OUT pk_types.cursor_type,
        o_type_closure OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Set discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_prof_cat       logged professional category
    * @param i_discharge      discharge identifier
    * @param i_episode        episode identifier
    * @param i_dt_end         discharge date
    * @param i_disch_dest     discharge reason destiny identifier
    * @param i_notes          discharge notes_med
    * @param i_print_report   print report?
    * @param i_transaction    scheduler transaction identifier
    * @param o_reports_pat    report to print
    * @param o_flg_show       warm
    * @param o_msg_title      warn
    * @param o_msg_text       warn
    * @param o_button         warn
    * @param o_id_episode     created episode identifier
    * @param o_discharge      created discharge identifier
    * @param o_disch_detail   created discharge_detail identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/08
    */
    FUNCTION set_discharge
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_prof_cat         IN category.flg_type%TYPE,
        i_discharge        IN discharge.id_discharge%TYPE,
        i_episode          IN episode.id_episode%TYPE,
        i_dt_end           IN VARCHAR2,
        i_disch_dest       IN disch_reas_dest.id_disch_reas_dest%TYPE,
        i_notes            IN discharge.notes_med%TYPE,
        i_time_spent       IN discharge_detail.total_time_spent%TYPE,
        i_unit_measure     IN discharge_detail.id_unit_measure%TYPE,
        i_print_report     IN discharge_detail.flg_print_report%TYPE,
        i_transaction      IN VARCHAR2 := NULL,
        i_flg_type_closure IN discharge_detail.flg_type_closure%TYPE,
        o_reports_pat      OUT reports.id_reports%TYPE,
        o_flg_show         OUT VARCHAR2,
        o_msg_title        OUT VARCHAR2,
        o_msg_text         OUT VARCHAR2,
        o_button           OUT VARCHAR2,
        o_id_episode       OUT episode.id_episode%TYPE,
        o_discharge        OUT discharge.id_discharge%TYPE,
        o_disch_detail     OUT discharge_detail.id_discharge_detail%TYPE,
        o_disch_hist       OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist   OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Cancel discharge.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_discharge      discharge identifier
    * @param i_cancel_reason  cancel reason identifier
    * @param i_cancel_notes   cancel notes
    * @param i_transaction    scheduler transaction identifier
    * @param o_disch_hist     created discharge_hist identifier
    * @param o_disch_det_hist created discharge_detail_hist identifier
    * @param o_error          error message
    *
    * @return                 false if errors occur, true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/10
    */
    FUNCTION set_discharge_cancel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_cancel_reason  IN discharge.id_cancel_reason%TYPE,
        i_cancel_notes   IN discharge.notes_cancel%TYPE,
        i_transaction    IN VARCHAR2 := NULL,
        o_disch_hist     OUT discharge_hist.id_discharge_hist%TYPE,
        o_disch_det_hist OUT discharge_detail_hist.id_discharge_detail_hist%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Get an episode's discharges list. Specify the discharge
    * identifier to retrieve the history of its changes.
    *
    * @param i_lang           language identifier
    * @param i_prof           logged professional structure
    * @param i_episode        episode identifier
    * @param i_discharge      discharge identifier
    * @param i_show_cancelled set 'Y' to show cancelled records
    * @param o_discharge      discharges
    * @param o_discharge_prof discharges records info 
    * @param o_error          error
    *
    * @return                 false, if errors occur, or true otherwise
    *
    * @author                 Pedro Carneiro
    * @version                 2.6.0.1
    * @since                  2010/03/05
    */
    FUNCTION get_discharge_report
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_discharge      IN discharge.id_discharge%TYPE,
        i_show_cancelled IN VARCHAR2,
        o_discharge      OUT pk_types.cursor_type,
        o_discharge_prof OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE get_disch_type_closure_list
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        o_list OUT pk_types.cursor_type
    );
END pk_discharge_amb;
/
