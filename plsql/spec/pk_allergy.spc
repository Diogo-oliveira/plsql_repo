/*-- Last Change Revision: $Rev: 2028453 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:51 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_allergy IS

    SUBTYPE obj_name IS VARCHAR2(30 CHAR);
    SUBTYPE debug_msg IS VARCHAR2(200 CHAR);

    -- Public type declarations
    TYPE t_rec_allergy_unawareness IS RECORD(
        id_allergy_unawareness   allergy_unawareness.id_allergy_unawareness%TYPE,
        code_allergy_unawareness allergy_unawareness.code_allergy_unawareness%TYPE,
        type_unawareness         allergy_unawareness.code_unawareness_type%TYPE,
        flg_enabled              VARCHAR2(1 CHAR),
        flg_default              VARCHAR2(1 CHAR));

    TYPE t_coll_allergy_unawareness IS TABLE OF t_rec_allergy_unawareness;
    TYPE t_cur_allergy_unawareness IS REF CURSOR RETURN t_rec_allergy_unawareness;

    /**
     * This function cancels a patient allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  id_cancel_reason     Cancel reason ID
     * @param    IN  cancel_notes         Cancel notes
     * @param    IN  i_id_pat_allergy     Patient Allergy ID
     * @param    IN  o_error              Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.6.0
     * @since    2010-Mar-11
     * @alter    Jos?Brito
    */
    FUNCTION call_cancel_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason       IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes           IN pat_allergy.cancel_notes%TYPE,
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_cancel_reason       IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes           IN pat_allergy.cancel_notes%TYPE,
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_allergy_intf
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN table_number,
        i_id_cancel_reason IN table_number,
        i_cancel_notes     IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function cancels a patient allergy
    *
    * @param    IN  i_lang               Language ID
    * @param    IN  i_prof               Professional structure
    * @param    IN  id_cancel_reason     Cancel reason ID
    * @param    IN  cancel_notes         Cancel notes
    * @param    IN  i_id_pat_allergy     Patient Allergy ID
    * @param    IN  o_error              Error structure
    *
    * @return   BOOLEAN
    *
    * @version  2.5.1.2
    * @since    27-Oct-2010
    * @author   Filipe Machado
    */
    FUNCTION cancel_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pat_allergy   IN table_number,
        i_id_cancel_reason IN pat_allergy.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy.cancel_notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function cancels a patient allergy
     *
     * @param    IN  i_lang               Language ID
     * @param    IN  i_prof               Professional structure
     * @param    IN  i_id_unawareness     Unawareness Allergy ID
     * @param    IN  i_cancel_notes       Cancel notes
     * @param    OUT o_error              Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-21
     * @author   Thiago Brito
    */
    FUNCTION cancel_unawareness
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_unawareness   IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_id_cancel_reason IN pat_allergy_unawareness.id_cancel_reason%TYPE,
        i_cancel_notes     IN pat_allergy_unawareness.notes%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the number of active allergies related with
     * a patient.
     *
     * @param    IN  i_lang      Language ID
     * @param    IN  i_prof      Professional structure
     * @param    IN  i_patient   Patient ID
     * @param    IN  o_number    Quantity of known allergies
     * @param    IN  o_error     Error structure
     *
     * @return   INTEGER         Number of active allergies related with a patient
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_count_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_number  OUT NUMBER,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the number of active allergies related with
     * a patient.
     *
     * @param    IN  i_lang      Language ID
     * @param    IN  i_prof      Professional structure
     * @param    IN  i_patient   Patient ID
     * @param    IN  o_error     Error structure
     *
     * @return   INTEGER         Number of active allergies related with a patient
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_count_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN PLS_INTEGER;

    /**
     * This function is used to get the list of allergy by patient
     * to be used by the viewer
     *
     * @param    IN     i_lang       Language ID
     * @param    IN     i_prof       Professional structure
     * @param    IN     i_patient    Patient ID
     * @param    IN     i_episode    Episode ID
     * @param    OUT    o_allergy    Current allergies cursor
     * @param    OUT    o_error      Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Nov-02
     * @author   Thiago Brito
    */
    FUNCTION get_viewer_allergy_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_allergy_lst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        i_flg_filter  IN VARCHAR2,
        o_allergies   OUT t_tbl_allergies,
        o_filter_desc OUT sys_message.desc_message%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_allergy_lst
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    --
    FUNCTION get_unawareness_active
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_patient            IN patient.id_patient%TYPE,
        i_episode            IN episode.id_episode%TYPE,
        i_flg_filter         IN VARCHAR2,
        i_dt_begin           IN VARCHAR2,
        i_dt_end             IN VARCHAR2,
        o_unawareness_active OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --
    FUNCTION get_unawareness_outdated
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_flg_filter           Filter type,
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_unawareness_active   Active unawareness allergies cursor
     * @param    OUT    o_unawareness_outdated Outdated unawareness allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-May-02
     * @author   Rui Duarte
    */
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_filter_desc          OUT sys_message.desc_message%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_unawareness_active   Active unawareness allergies cursor
     * @param    OUT    o_unawareness_outdated Outdated unawareness allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        o_allergies            OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_flg_filter           Flag for filter (Reports only) (g_rep_type_patient, g_rep_type_episode, g_rep_type_visit)
     * @param    IN     i_dt_begin             Date begin
     * @param    IN     i_dt_end               Date end
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_unawareness_active   Active unawareness allergies cursor
     * @param    OUT    o_unawareness_outdated Outdated unawareness allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    02-Nov-2010
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_list_rep
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_flg_filter           IN VARCHAR2,
        i_dt_begin             IN VARCHAR2,
        i_dt_end               IN VARCHAR2,
        o_allergies            OUT pk_types.cursor_type,
        o_allergies_hist       OUT pk_types.cursor_type,
        o_allergies_rev        OUT pk_types.cursor_type,
        o_unawareness_active   OUT pk_types.cursor_type,
        o_unawareness_outdated OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of allergy per patient.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_episode              Episode ID
     * @param    IN     i_pat_allergy          Patient allergies
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    2010-Oct-26
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_review_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_episode     IN episode.id_episode%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the detail of an allergy for the review screen.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.7
     * @since    2009-Oct-28
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_rev_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_pat_allergy    IN patient.id_patient%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * This function returns all allergies that match the given allergy name
     *
    * @param    i_lang             Language id
    * @param    i_prof             Profissional, institution and software id's
    * @param    i_allergy_name     Allergy name to search for
    * @param    o_allergies        Output allergies cursor
    * @param    o_error            Error messages cursor
     *
    * @return   True if sucess, false otherwise
     *
     * @version  2.4.4
    * @since    01-Apr-2009
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_allergy_name  IN pk_translation.t_desc_translation,
        o_allergies     OUT pk_types.cursor_type,
        o_limit_message OUT sys_message.desc_message%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the prescription warning of all the allergies
     * passed by parameter
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-21
     * @author   Thiago Brito
    */
    FUNCTION get_prescription_warning
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_patient   IN patient.id_patient%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_allergies IN table_number,
        o_cursor       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function verifies if the table ALLERGY_INST_SOFT_MARKET has
     * data for the current market.
     *
     * @param    IN    i_market    Market Description (PT; NL; USA; ALL)
     *
     * @return   BOOLEAN
     *
     * @version  2.5.0.5
     * @since    2009-Jul-31
     * @author   Thiago Brito
    */
    FUNCTION get_default_allergy_market(i_market VARCHAR2) RETURN PLS_INTEGER;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_subset_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    IN     i_flg_freq             Indicates if only shows frequent allergies ('Y'-only frequent allergies; 'N'-all allergies)
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-Abr-12
     * @author   Luís Maia
    */
    FUNCTION get_allergy_type_subset_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the types of all the allergies.
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_id_patient           Patient ID
     * @param    IN     i_id_episode           Episode ID
     * @param    IN     i_allergy_parent       ID parent's allergy
     * @param    IN     i_level                Number of menu's levels
     * @param    OUT    o_allergies            Allergies cursor
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the detail of an allergy.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    IN     i_is_review        Boolean value
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @value    i_all                     {*} True  include all (creation, history, review)
     *                                     {*} False only creation   
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.5.0.7.5
     * @update   2009-Dec-09
     * @author   Filipe Machado
    */
    FUNCTION get_allergy_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the detail of an allergy.
     * 
     * @param    IN     i_lang             Language ID
     * @param    IN     i_prof             Professional structure
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    OUT    o_allergy_detail   Detail of an allergy
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
     *
     * @version  2.5.0.7.5
     * @update   2009-Dec-09
     * @author   Filipe Machado
    */

    FUNCTION get_allergy_detail
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy_detail OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function verifies if an allergy is already registered
     * for this patient.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    IN     i_id_patient       Patient ID
     * @param    OUT    o_cursor           Data cursor
     * @param    OUT    o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-27
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_dup_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN table_number,
        i_id_patient IN pat_allergy.id_patient%TYPE,
        o_cursor     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function return all the symptoms (history) associated with an allergy
     * in string format.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     *
     * @return   VARCHAR2
     *
     * @version  2.4.4
     * @since    2009-Apr-29
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_symptoms_hist_str
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy_hist.id_pat_allergy%TYPE,
        i_revision       IN pat_allergy_hist.revision%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function return all the symptoms associated with an allergy
     * in string format.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     *
     * @return   VARCHAR2
     *
     * @version  2.4.4
     * @since    2009-Mar-30
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_symptoms_str
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_revision       IN pat_allergy.revision%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_choices OUT t_cur_allergy_unawareness,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_notes                Notes
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_notes               OUT pat_allergy_unawareness.notes%TYPE,
        o_choices             OUT t_cur_allergy_unawareness,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function analysis the previous data registered in the PAT_ANALYSIS
     * table in order to find what of the following options will be
     * available:
     *
     * 1 - No allergy assessment
     * 2 - No known allergies
     * 3 - No known drug allergies
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_patient              Patient ID
     * @param    IN     i_pat_allergy_unaware  Patient Allergy Unawareness ID
     * @param    OUT    o_choices              Choices cursor
     * @param    OUT    o_notes                Notes
     * @param    OUT    o_error                Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unawareness_condition_edit
    (
        i_lang                IN language.id_language%TYPE,
        i_patient             IN patient.id_patient%TYPE,
        i_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_notes               OUT pat_allergy_unawareness.notes%TYPE,
        o_choices             OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function was developed in order to keep the table
     * PAT_ALLERGY_HIST up-to-date.
     * All changes performed at the table PAT_ALLERGY has to be
     * mirrored to the PAT_ALLERGY_HIST table.
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_pat_allergy   Patient Allergy ID
     * @param    IN OUT o_error            Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_history
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function ables the user to add more than one allergy at a time.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            ARRAY/Allergy start's year
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-07
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Flag nature
     * @param IN  i_dt_resolution         dt_resolution
     * @param OUT o_id_pat_allergy        ID pat allergy
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_problem_nc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_flg_nature          IN pat_allergy.flg_nature%TYPE,
        i_dt_resolution       IN pat_allergy.dt_resolution%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Flag nature
     * @param IN  i_dt_resolution         dt_resolution
     * @param OUT o_id_pat_allergy        ID pat allergy
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_problem
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN NUMBER,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_flg_nature          IN pat_allergy.flg_nature%TYPE,
        i_dt_resolution       IN pat_allergy.dt_resolution%TYPE,
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param IN  i_flg_cda_reconciliation Identifies allergy record origin Y- CDA, N-PFH
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.4.0.3
     * @since    2014-May-27
     * @author   Gisela Couto
    */
    FUNCTION set_allergy
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN pat_allergy.id_patient%TYPE,
        i_id_episode             IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy             IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy           IN pat_allergy.desc_allergy%TYPE,
        i_notes                  IN pat_allergy.notes%TYPE,
        i_flg_status             IN pat_allergy.flg_status%TYPE,
        i_flg_type               IN pat_allergy.flg_type%TYPE,
        i_flg_aproved            IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved           IN pat_allergy.desc_aproved%TYPE,
        i_year_begin             IN pat_allergy.year_begin%TYPE,
        i_id_symptoms            IN table_number,
        i_day_begin              IN pat_allergy.day_begin%TYPE,
        i_month_begin            IN pat_allergy.month_begin%TYPE,
        i_id_allergy_severity    IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit               IN pat_allergy.flg_edit%TYPE,
        i_desc_edit              IN pat_allergy.desc_edit%TYPE,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE,
        o_id_pat_allergy         OUT pat_allergy.id_pat_allergy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-07
     * @author   Thiago Brito
    */
    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_month_begin           Allergy start's month
     * @param IN  i_day_begin             Allergy start's day
     * @param IN  i_year_end              Allergy end year
     * @param IN  i_month_end             Allergy end month
     * @param IN  i_day_end               Allergy end day
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_flg_nature            Allergy Nature
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.0.3.4
     * @since    2010-Nov-24
     * @author   Rui Duarte
    */
    FUNCTION set_allergy_int
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_patient             IN pat_allergy.id_patient%TYPE,
        i_id_episode             IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy         IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy             IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy           IN pat_allergy.desc_allergy%TYPE,
        i_notes                  IN pat_allergy.notes%TYPE,
        i_flg_status             IN pat_allergy.flg_status%TYPE,
        i_flg_type               IN pat_allergy.flg_type%TYPE,
        i_flg_aproved            IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved           IN pat_allergy.desc_aproved%TYPE,
        i_year_begin             IN pat_allergy.year_begin%TYPE,
        i_month_begin            IN pat_allergy.month_begin%TYPE,
        i_day_begin              IN pat_allergy.day_begin%TYPE,
        i_year_end               IN pat_allergy.year_end%TYPE,
        i_month_end              IN pat_allergy.month_end%TYPE,
        i_day_end                IN pat_allergy.day_end%TYPE,
        i_id_symptoms            IN table_number,
        i_id_allergy_severity    IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit               IN pat_allergy.flg_edit%TYPE,
        i_desc_edit              IN pat_allergy.desc_edit%TYPE,
        i_flg_nature             IN pat_allergy.flg_nature%TYPE,
        i_dt_pat_allergy         IN pat_allergy.dt_pat_allergy_tstz%TYPE,
        i_cdr_call               IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_flg_cda_reconciliation IN pat_allergy.flg_cda_reconciliation%TYPE DEFAULT pk_alert_constant.g_no,
        o_id_pat_allergy         OUT pat_allergy.id_pat_allergy%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This functions sets a patient allergy as active
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_as_active
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN table_number,
        i_episode        IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This functions sets a patient allergy as inactive
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_as_inactive
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN table_number,
        i_episode        IN episode.id_episode%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This functions sets a patient allergy as "review"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy ID
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Oct-22
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_as_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function sets one or several patient allergies as "reviewed"
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_id_pat_allergy    Patient Allergy's ID's
     * @param OUT  o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.1.2
     * @since    19-Oct-2010
     * @author   Filipe Machado
    */
    FUNCTION set_allergy_as_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_id_pat_allergy IN table_number,
        i_review_notes   IN review_detail.review_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * This function is used to register an allergy unawareness.
    *
    * @param IN   i_lang              Language ID
    * @param IN   i_prof              Professional ID
    * @param IN   i_episode           Episode ID
    * @param IN   i_patient           Patient ID
    * @param IN   i_unawareness       Allergy Unawareness ID
    * @param IN   i_pat_unawareness   Pat Allergy Unawareness ID
    * @param IN   i_notes             Notes
    * @param OUT  o_error             Error structure
    * 
    * @return BOOLEAN
    */
    FUNCTION set_allergy_unawareness
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_unawareness     IN allergy_unawareness.id_allergy_unawareness%TYPE,
        i_pat_unawareness IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_notes           IN pat_allergy.notes%TYPE,
        o_error           OUT t_error_out
        
    ) RETURN BOOLEAN;

    /**
     * This function is used to register an allergy unawareness.
     *
     * @param IN   i_lang              Language ID
     * @param IN   i_prof              Professional ID
     * @param IN   i_episode           Episode ID
     * @param IN   i_patient           Patient ID
     * @param IN   i_unawareness       Allergy Unawareness ID
     * @param IN   i_pat_unawareness   Pat Allergy Unawareness ID
     * @param IN   i_notes             Notes
     * @param OUT  o_error             Error structure
     * 
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-30
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_unawareness_no_com
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_patient         IN patient.id_patient%TYPE,
        i_unawareness     IN allergy_unawareness.id_allergy_unawareness%TYPE,
        i_pat_unawareness IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_notes           IN pat_allergy.notes%TYPE,
        o_pat_unawareness OUT pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function verifies weather the patient has an previous allergy
     * registered or not .
     * It returns 1 if the patient HAS NO allergy and 0 if the patient already
     * has an allergy registered.
     * 
     * 1 - No allergy
     * 0 - The patient has at leat one allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_no_recorded_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER;

    /**
     * This function verifies if the patient has non-drug allergy only. This
     * function returns 1 if the patient has only non-drug allergy. If the patient
     * has no allergy or if he/she has one or more drug allergy registered then
     * the function returns 0.
     *
     * 1 - Only non-drug allergy
     * 0 - The patient has drug allergy or has no allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_non_drug_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER;

    /**
     * This function verifies if the patient has any drug allergy (only). It
     * returns 1 if the patient has at least one drug allergy and 0 if he/she
     * has no allergy or at least one non-drug allergy registered.
     *
     * 1 - Drug allergy (only)
     * 0 - No allergy or at least one non-drug allergy
     *
     * @param IN   i_patient  Patient ID
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-31
     * @author   Thiago Brito
    */
    FUNCTION exists_drug_allergy(i_patient IN patient.id_patient%TYPE) RETURN PLS_INTEGER;

    /**
     * This function returns the actions used to:
     *
     * 1) Add a New allergy
     * 2) Add a New record of allergy unawareness
     *
     * @param IN   i_lang     Language ID
     * @param IN   i_patient  Patient ID
     * @param OUT  o_cursor   Add actions cursor
     * @param OUT  o_error    Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_add_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_cursor  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Active
     * 2) Passive
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Status messages cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_status_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Allergy
     * 2) Adverse reaction
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Type messages cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_type_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function will return the following messages:
     *
     * 1 - If you document a given drug as an allergen in
     *     free text mode, the (allergy) decision support
     *     will not be activated when the physician is
     *     prescribing medication. Are you sure you want
     *     to continue?
     *
     * 2 - Any potential allergy will not be identified by the (allergy)
     *     decision support.
     *
     * @param    IN     i_lang             Language ID
     * @param    OUT    o_message_bold     Message 1
     * @param    OUT    o_message          Message 2
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_type_allergy_warning
    (
        i_lang         IN language.id_language%TYPE,
        o_message_bold OUT pk_types.cursor_type,
        o_message      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function will return the following messages:
     *
     * There is an active @1 prescription.
     * Are you sure you want to continue?
     *
     * The @1 will be replaced by the name of the allergy
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    OUT    o_message          Message
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN allergy.id_allergy%TYPE,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all data associated with an allergy.
     * 
     * @param    IN     i_lang              Language ID
     * @param    IN     i_id_pat_allergy    Patient Allergy ID
     * @param    OUT    o_allergy           Allergy
     * @param    OUT    o_allergy_symptoms  Allergy Symptoms
     * @param    OUT    o_error             Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy
    (
        i_lang             IN language.id_language%TYPE,
        i_id_pat_allergy   IN pat_allergy.id_pat_allergy%TYPE,
        o_allergy          OUT pk_types.cursor_type,
        o_allergy_symptoms OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function will return the following messages:
     *
     * Are you sure you want to cancel the @
     * allergy / adverse reaction record?
     *
     * The @ will be replaced by the name of the allergy
     *
     * @param    IN     i_lang             Language ID
     * @param    IN     i_id_allergy       Allergy ID
     * @param    OUT    o_title            Title
     * @param    OUT    o_message          Message
     * @param    OUT    o_error            Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_allergy_cancel_warning
    (
        i_lang       IN language.id_language%TYPE,
        i_id_allergy IN allergy.id_allergy%TYPE,
        o_title      OUT VARCHAR2,
        o_message    OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all data associated symptoms.
     * 
     * @param    IN     i_lang              Language ID
     * @param    IN     i_id_pat_allergy    Patient Allergy ID
     *
     * @return VARCHAR2
     *
     * @version  2.5.1.2
     * @since    2010-Oct-27
     * @author   Filipe Machado
    */
    FUNCTION get_symptoms
    (
        i_lang           IN language.id_language%TYPE,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE
    ) RETURN VARCHAR2;

    /**
     * This function will return the following messages:
     *
     * Are you sure you want to cancel the @
     * unawareness record?
     *
     * The @ will be replaced by the name of the allergy
     *
     * @param    IN     i_lang                         Language ID
     * @param    IN     i_id_allergy_unawareness       Allergy ID
     * @param    OUT    o_title                        Title
     * @param    OUT    o_message                      Message
     * @param    OUT    o_error                        Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito
    */
    FUNCTION get_unaware_cancel_warning
    (
        i_lang                   IN language.id_language%TYPE,
        i_id_allergy_unawareness IN allergy_unawareness.id_allergy_unawareness%TYPE,
        o_title                  OUT VARCHAR2,
        o_message                OUT VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns all symptoms registered in the data base
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Symptoms cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_symptoms_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Clinically documented
     * 2) Patient
     * 3) Escorter
     * 4) Family member
     * 5) Other
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  "Reported by" list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_font_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the list of "severities" registered in the DB
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Severity cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_severity_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Cancel
     * 2) Edit
     * 3) Show as active
     * 4) Show as inactive
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Actions cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_actions_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returs a list of editing reasons
     *
     * @param IN   i_lang    Language ID
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_edit_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Entered by error
     * 2) Wrong patient
     * 3) Other
     *
     * @param IN   i_lang    Language ID
     * @param IN   i_prof    Profissional
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_cancel_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the following values:
     *
     * 1) Entered by error
     * 2) Wrong patient
     * 3) Other
     *
     * @param IN   i_lang    Language ID
     * @param IN   i_prof    Profissional
     * @param OUT  o_cursor  Edit reasons list cursor
     * @param OUT  o_error   Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Mar-26
     * @author   Thiago Brito 
    */
    FUNCTION get_cancel_unaware_reason_list
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function returns the status message string for the allergy.
     * This function cannot be used by outside this package. This function
     * was not developed to access data base data directly. This function 
     * only build the string according to the i_flg_status and i_desc_status
     * parameters.
     *
     * @param  IN i_flg_status         Flag status
     * @param  IN i_desc_status        Status description (already translated)
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Apr-02
     * @author    Thiago Brito
    */
    FUNCTION get_status_string
    (
        i_flg_status  IN VARCHAR2,
        i_desc_status IN VARCHAR2
    ) RETURN VARCHAR2;

    /**
     * This function return the color's code according to the
     * allergy's status.
     *
     * @param i_flg_status
     *
     * @return VARCHAR2
     *
     * @version   2.4.4
     * @since     2009-Apr-08
     * @author    Thiago Brito
    */
    FUNCTION get_status_color(i_flg_status IN VARCHAR2) RETURN VARCHAR2;

    /*************************************************************************\
    * Name :                 get_count_and_first                              *
    * Description:           VIEWER API -> Returns ALLERGY total              *
    *                                      and first record                   *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_patient       Input - Patient ID                               *
    * @param o_num_occur     Output - Total patient allergies                 *
    * @param o_desc_first    Output - First allergy description               *
    * @param o_dt_first      Output - First allergy date,                     *
    *                                 according the sort criteria parameters  *
    *                                                                         *
    * @author                Nuno Miguel Ferreira                             *
    * @version               1.0                                              *
    * @since                 2008/11/13                                       *
    \*************************************************************************/
    FUNCTION get_count_and_first
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        o_num_occur  OUT NUMBER,
        o_desc_first OUT VARCHAR2,
        o_code       OUT VARCHAR2,
        o_dt_first   OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_dt_fmt     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************\
    * Name :                 get_ordered_list                                 *
    * Description:           VIEWER API -> Returns ALLERGIES ordered list     *
    *                                                                         *
    * @param i_lang          Input - Language ID                              *
    * @param i_prof          Input - Professional array                       *
    * @param i_patient       Input - Patient ID                               *
    * @param o_ordered_list  Output - Patient allergies list,                 *
    *                                 according the sort criteria parameters  *
    *                                                                         *
    * @author                Nuno Miguel Ferreira                             *
    * @version               1.0                                              *
    * @since                 2008/11/13                                       *
    \*************************************************************************/
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function verifies some inconsistencies through the registration
     * process of an unawareness
     *
     * @param IN   i_lang           Language ID
     * @param IN   i_prof           Professional (id, institution, software)
     * @param IN   i_patient        Patient ID
     * @param IN   i_unawareness    Unawareness ID (1: Unable to assess allergies;
     *                                              2: No known allergies;
     *                                              3: No known drug allergies)
     * @param OUT  o_msg            Message string
     * @param OUT  o_error          Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.5.0.4
     * @since    2009-Jul-13
     * @author   Thiago Brito 
    */
    FUNCTION get_popup_warning
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_unawareness IN allergy_unawareness.id_allergy_unawareness%TYPE,
        o_msg         OUT table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /** This function get the status of the review on the header
     *
     * @param    IN     i_lang                 Language ID
     * @param    IN     i_prof                 Professional structure
     * @param    IN     i_episode              Episode ID
     * @param    OUT    o_error                Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.5.1.2
     * @since    2010-Nov-02
     * @author   Filipe Machado
    */

    FUNCTION get_review_header_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_status  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    --

    /**
     * This function is used to build cancel description text
     *
     * @param IN   i_lang           Language ID
     * @param IN   i_prof           Professional (id, institution, software)
     * @param IN   i_pat_allergy    Array with pat_allergy identifiers
     * @param OUT  o_msg            Message string
     * @param OUT  o_error          Error structure
     *
     * @return BOOLEAN
     *
     * @version  2.6.1
     * @since    2011-FEV-04
     * @author   Rui Duarte
    */
    FUNCTION get_cancel_allergy_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_pat_allergy IN table_number,
        o_allergies   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    --

    PROCEDURE upd_viewer_ehr_ea;

    FUNCTION upd_viewer_ehr_ea_pat
    (
        i_lang              IN language.id_language%TYPE,
        i_table_id_patients IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is used to get the list of allergy per patient
     * and return: - the SNOWMED codes and descriptions of the allergy top parent,
     * the allergy severities and the allergy symptoms.
     * -the RXNorm code and description of the ingredients of the medication associated to the allergies
     *
     * DEPENDENCIES: REPORTS
     *
     * @param  i_lang  IN                      Language ID
     * @param  i_prof  IN                      Professional structure
     * @param  i_patient  IN                   Patient ID
     * @param  i_episode  IN                   Episode ID
     * @param  o_allergies  OUT                Allergies cursor
     * @param  o_error  OUT                    Error structure
     *
     * @return   BOOLEAN
     *
     * @version  2.6.0.5
     * @since    29-Abr-2011
     * @author   Sofia Mendes
    */
    FUNCTION get_allergy_list_cda
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_allergies  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns table function t_tbl_allergies that contains all information about patient allergies like : 
    * codes, descriptions, allergy severities and related symptoms
    * @param i_lang                     Language
    * @param i_prof                     Professional information
    * @param i_flg_filter               Used to filter data - 'A' -> filters by allergy
    *
    * @returns table function t_tbl_allergies
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          29-Jul-2014
    **********************************************************************************************/
    FUNCTION tf_allergy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_flg_filter IN VARCHAR2
    ) RETURN t_tbl_allergies;

    /********************************************************************************************
    * Returns information about patient allergies like : codes, descriptions, allergy severities and associated symptoms
    * @param i_lang                     Language
    * @param i_patient                  Patient Identification
    * @param i_scope                    Scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_scope                 Scope unique identifier | When scope is 'P' - id patient, 'E' - id_episode , 'V' - id_visit 
    * @param o_allergies_cda            t_tbl_allergies type returned with all information
    * @param o_error                    An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4
    * @since                          29-Jul-2014
    **********************************************************************************************/
    FUNCTION get_allergy_list_rec_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_patient       IN patient.id_patient%TYPE,
        i_scope         IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_allergies_cda OUT t_tbl_allergies,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * List associations between allergies and medication products.
    * Used for the CDA report.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_allergies    allergy identifiers list
    * @param o_allg_prod    data cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/10/17
    */
    FUNCTION get_products
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_allergies IN table_number,
        o_allg_prod OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get an allergy's records in the EHR (including severity).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               collection
    *
    * @author               Pedro Carneiro
    * @version               2.6.2
    * @since                2011/12/02
    */
    FUNCTION get_allergy_sever
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out;

    /**
    * This function splits a product allergy into its ingredients (when applicable)
    *
    * @param  i_lang    Language ID
    * @param  i_prof    Professional structure
    * @param  i_allergy Allergy ID
    *
    * @return allergy list (one per ingredient) plus the product allergy
    *
    * @version  2.6.2
    * @since    19-Jan-2012
    * @author   Jos?Silva
    */
    FUNCTION get_allergy_ingr_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_allergy IN allergy.id_allergy%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Checks the limit for displaying allergies when browsing in the different categories
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional, software and institution IDs
    * @param i_allergy_parent        Allergy parent ID
    * @param i_flg_freq              Frequent allergy flag
    * @param i_market                Market ID
    * @param i_inst                  Institution ID
    * @param i_soft                  Software ID
    * @param i_standard              Standard ID
    * @param o_limit_message         Returned message if limit is exceeded
    * @param o_error                 Error Message
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sérgio Dias
    * @version                  2.6.1.0.1
    * @since                    06-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_allergies_limit
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        i_market         IN market.id_market%TYPE,
        i_inst           IN institution.id_institution%TYPE,
        i_soft           IN software.id_software%TYPE,
        i_standard       IN sys_config.value%TYPE,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks the limit for displaying allergies when using the text search in the allergies screen
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional, software and institution IDs
    * @param i_search_pattern        Text value to be searched
    * @param i_market                Market ID
    * @param i_standard              Standard ID
    * @param o_limit_message         Returned message if limit is exceeded
    * @param o_error                 Error Message
    *
    * @return                   TRUE/FALSE
    *     
    * @author                   Sérgio Dias
    * @version                  2.6.1.0.1
    * @since                    06-May-2011
    *
    *********************************************************************************************/
    FUNCTION check_allergies_search_limit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_search_pattern   IN pk_translation.t_desc_translation,
        i_market           IN market.id_market%TYPE,
        i_institution      IN institution.id_institution%TYPE,
        i_software         IN software.id_software%TYPE,
        i_allergy_standard IN allergy.id_allergy_standard%TYPE,
        o_allergies        OUT pk_types.cursor_type,
        o_limit_message    OUT sys_message.desc_message%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This function is used to get the types of all the allergies.
    *
    * @param    IN     i_lang                 Language ID
    * @param    IN     i_prof                 Professional structure
    * @param    IN     i_id_patient           Patient ID
    * @param    IN     i_id_episode           Episode ID
    * @param    IN     i_allergy_parent       ID parent's allergy
    * @param    IN     i_level                Number of menu's levels
    * @param    IN     i_flg_freq             Indicates if only shows frequent allergies ('Y'-only frequent allergies; 'N'-all allergies)
    * @param    OUT    o_allergies            Allergies cursor
    * @param    OUT    o_error                Error structure
    *
    * @return   BOOLEAN
    *
    * @version  2.6.1.0.1
    * @since    06-May-2011
    * @author   Sergio Dias
    *********************************************************************************************/
    FUNCTION get_allergy_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_episode     IN episode.id_episode%TYPE,
        i_allergy_parent IN allergy_inst_soft_market.id_allergy_parent%TYPE,
        i_level          IN PLS_INTEGER,
        i_flg_freq       IN allergy_inst_soft_market.flg_freq%TYPE,
        o_select_level   OUT VARCHAR2,
        o_allergies      OUT pk_types.cursor_type,
        o_limit_message  OUT sys_message.desc_message%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function ables the user to add more than one allergy at a time.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_day_begin             ARRAY/Allergy start's day
     * @param IN  i_month_begin           ARRAY/Allergy start's month
     * @param IN  i_year_begin            ARRAY/Allergy start's year          
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.1.0.1
     * @since    2011-May-11
     * @author   Sergio Dias
    */
    FUNCTION set_allergy_array
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_day_begin           IN table_number,
        i_month_begin         IN table_number,
        i_year_begin          IN table_number,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function ables the user to add allergies according to CCH specifications.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ARRAY/ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            ARRAY/Allergy ID
     * @param IN  i_desc_allergy          ARRAY/If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 ARRAY/Allergy Notes
     * @param IN  i_flg_status            ARRAY/Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              ARRAY/Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           ARRAY/Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          ARRAY/If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_year_begin            ARRAY/Allergy start's year
     * @param IN  i_id_symptoms           ARRAY/Symptoms' date
     * @param IN  i_id_allergy_severity   ARRAY/Severity of the allergy
     * @param IN  i_flg_edit              ARRAY/Edit flag
     * @param IN  i_desc_edit             ARRAY/Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.4.4
     * @since    2009-Apr-01
     * @author   Thiago Brito
    */
    FUNCTION set_allergy_intf
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN table_number,
        i_date_occur          IN table_varchar,
        i_id_allergy          IN table_number,
        i_desc_allergy        IN table_varchar,
        i_notes               IN table_varchar,
        i_flg_status          IN table_varchar,
        i_flg_type            IN table_varchar,
        i_flg_aproved         IN table_varchar,
        i_desc_aproved        IN table_varchar,
        i_id_symptoms         IN table_table_number,
        i_id_allergy_severity IN table_number,
        i_flg_edit            IN table_varchar,
        i_desc_edit           IN table_varchar,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        o_id_pat_allergy      OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**
     * This function is can be used to INSERT/UPDATE a patient's allergy.
     *
     * @param IN  i_lang                  Language ID
     * @param IN  i_prof                  Professional structure
     * @param IN  i_id_patient            Patient ID
     * @param IN  i_id_episode            Episode ID
     * @param IN  i_id_pat_allergy        ID_PAT_ALLERGY: NULL to INSERT; NOT NULL to UPDATE
     * @param IN  i_id_allergy            Allergy ID
     * @param IN  i_desc_allergy          If 'Other' had been choosen for allergy then we need to save the text free allergy
     * @param IN  i_notes                 Allergy Notes
     * @param IN  i_flg_status            Allergy Status (A: Active; C: Cancelled; P: Passive; R: Resolved)
     * @param IN  i_flg_type              Allergy Type (A: Allergy; I: Adverse reaction)
     * @param IN  i_flg_aproved           Reporter (M: Clinically documented; U: Patient; E: Escorter; F: Family member; O: Other)
     * @param IN  i_desc_aproved          If 'Other' had been choosen then the user can input a text free description for "Reporter"
     * @param IN  i_day_begin             Allergy start's day
     * @param IN  i_month_begin           Allergy start's month
     * @param IN  i_year_begin            Allergy start's year
     * @param IN  i_id_symptoms           Symptoms' date
     * @param IN  i_id_allergy_severity   Severity of the allergy
     * @param IN  i_flg_edit              Edit flag
     * @param IN  i_desc_edit             Description: reason of the edit action
     * @param IN  i_cdr_call              Rule engine call identifier
     * @param OUT o_error                 Error structure
     * 
     * @return   BOOLEAN
     *
     * @version  2.6.1.0.1
     * @since    2011-May-11
     * @author   Sergio Dias
    */
    FUNCTION set_allergy
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_patient          IN pat_allergy.id_patient%TYPE,
        i_id_episode          IN pat_allergy.id_episode%TYPE,
        i_id_pat_allergy      IN pat_allergy.id_pat_allergy%TYPE,
        i_id_allergy          IN pat_allergy.id_allergy%TYPE,
        i_desc_allergy        IN pat_allergy.desc_allergy%TYPE,
        i_notes               IN pat_allergy.notes%TYPE,
        i_flg_status          IN pat_allergy.flg_status%TYPE,
        i_flg_type            IN pat_allergy.flg_type%TYPE,
        i_flg_aproved         IN pat_allergy.flg_aproved%TYPE,
        i_desc_aproved        IN pat_allergy.desc_aproved%TYPE,
        i_day_begin           IN pat_allergy.day_begin%TYPE,
        i_month_begin         IN pat_allergy.month_begin%TYPE,
        i_year_begin          IN pat_allergy.year_begin%TYPE,
        i_id_symptoms         IN table_number,
        i_id_allergy_severity IN pat_allergy.id_allergy_severity%TYPE,
        i_flg_edit            IN pat_allergy.flg_edit%TYPE,
        i_desc_edit           IN pat_allergy.desc_edit%TYPE,
        i_cdr_call            IN cdr_event.id_cdr_call%TYPE DEFAULT NULL, --ALERT-175003
        i_commit              IN VARCHAR2 DEFAULT 'Y',
        o_id_pat_allergy      OUT pat_allergy.id_pat_allergy%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dt_str
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_year_begin  IN NUMBER,
        i_month_begin IN NUMBER,
        i_day_begin   IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************
    * This Function validates if an allergy is a drug allergy 
    *
    * @param    IN  i_id_allergy     Allergy ID
    *
    * @return   varchar2 
    * 'M' -identifies that is a drug allergy
    * 'O'- Identifies that is otheer kind of allergy(not a drug one)
    *
    * 
    * @author   Pedro Fernandes 
    * @version  2.6.1.2
    * @since    2011-Jul-27
    */
    FUNCTION get_flg_is_drug_allergy(i_id_allergy IN allergy.id_allergy%TYPE) RETURN VARCHAR2;

    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_allergy       identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          2012/09/05 
    */
    FUNCTION get_desc_allergy
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_pat_allergy IN pat_allergy.id_pat_allergy%TYPE,
        i_desc_type      IN VARCHAR2
    ) RETURN CLOB;
    /**
    * Get task description.
    * Used for the task timeline easy access (HandP import mechanism).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_pat_allergy_unaware       identifier
    * @param i_desc_type    de4sc_type S-short/L-long
    *
    * @return               diet task description
    *
    * @author                         Paulo Teixeira
    * @version                        2.6.1.2
    * @since                          2012/09/05 
    */
    FUNCTION get_desc_allergy_unaware
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_pat_allergy_unaware IN pat_allergy_unawareness.id_pat_allergy_unawareness%TYPE,
        i_desc_type              IN VARCHAR2
    ) RETURN CLOB;

    /**
    * Get count allergie unawareness.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier 
    *
    * @return               -1 if there are no know allergie, 0 if no allergies , > 0 number of allergies
    *
    * @author               Elisabete Bugalho
    * @version              2.6.3.5
    * @since               2013/05/21
    */
    FUNCTION get_count_allergy_unawareness
    (
        i_lang    IN language.id_language%TYPE,
        i_patient IN patient.id_patient%TYPE,
        o_error   OUT t_error_out
    ) RETURN PLS_INTEGER;

    /********************************************************************************************
    * Allergies associated to a given list of episodes
    *
    * @param i_lang              language id
    * @param i_prof              professional, software and institution ids
    * @param i_episode           episode id        
    * @param o_allergy           array with info allergy
    *
    * @param o_error             Error message
    * @return                    true or false on success or error
    *
    * @author                    Sofia Mendes (code separated from pk_episode.get_summary_s function)
    * @since                     21/03/2013  
    ********************************************************************************************/
    FUNCTION get_allergies
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN table_number,
        i_patient IN patient.id_patient%TYPE,
        o_allergy OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get an allergy's records in the EHR (including severity).
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    *
    * @return               collection
    *
    * @author               Mário Mineiro
    * @version               2.6.3
    * @since                2014/01/13
    */
    FUNCTION get_allergy_cds
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN t_coll_cdr_api_out;

    /**
    * check if an allergy is from medication return 1 or 0
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_id_allergy   allergy identifier
    *
    * @return               number 1 or 0
    *
    * @author               Mário Mineiro
    * @version               2.6.3
    * @since                2014/01/13
    */
    FUNCTION check_allergy_med_cds
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_allergy IN allergy.id_allergy%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * Converts allergy concepts from/to some code.  
    * @param i_lang                     Language
    * @param i_source_codes             Codes to be mapped
    * @param i_source_coding_scheme     Type code (rxnorm - 6, snomed - 2)
    * @param i_target_coding_scheme     Allergy context (101 - id allergy, 103 - allergy type, 105 - reactions, 106 - severity)
    * @param o_target_codes             All Codes returned
    * @param o_target_display_names     All Code descriptions returned
    * @param o_error An error message to explain what went wrong if the execution fails.
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Gisela Couto
    * @version                        2.6.4.0.3
    * @since                          27-May-2014
    **********************************************************************************************/
    FUNCTION get_allergy_info_cs_cda
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_target_coding_scheme    IN VARCHAR2,
        i_target_coordinated_expr IN table_varchar,
        i_id_med_context          IN VARCHAR2 DEFAULT NULL,
        o_target_codes            OUT table_varchar,
        o_target_display_name     OUT table_varchar,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get drug allergy parents
    *
    * @return Array with drug allergy parents
    * 
    * @author                         Alexandre Santos
    * @version                        2.6.4
    * @since                          02-Jul-2014
    **********************************************************************************************/
    FUNCTION tf_drug_allergy_prts_cda RETURN table_varchar;
    /********************************************************************************************
    * get_viewer_allergy 
    *             
    * @param i_lang       language idenfier
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return True if succeded, false otherwise.
    * 
    * @author                         Paulo Teixeira  
    * @version                        2.6.5
    * @since                          2016-02-10
    **********************************************************************************************/
    FUNCTION get_viewer_allergy
    (
        i_lang       IN language.id_language%TYPE,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN pk_types.cursor_type;

    /********************************************************************************************
    * Get allergies viewer checklist 
    *             
    * @param i_lang       language idenfier
    * @param i_scope_type scope flag | 'P' - Patient, 'E' - Episode, 'V' - Visit 
    * @param i_id_patient patient idenfier
    * @param i_id_episode episode idenfier
    * @param o_flg_out    flag out 
    * @param o_error      t_error_out type error
    *
    * @return VARCHAR2  Viewer checklist status | 'N' - Not started , 'C' - Complete, 'O' - On going
    * 
    * @author                         Elisabete Bugalho
    * @version                        2.6.5
    * @since                          2016-10-25
    **********************************************************************************************/
    FUNCTION get_viewer_allergy_checklist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scope_type IN VARCHAR2,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get allergies for hand-off
    *             
    * @param i_lang                     language idenfier
    * @param i_id_patient               patient idenfier
    * @param o_allergies                cursor with allergies 
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Elisabete Bugalho
    * @version                          2.7.1
    * @since                            29-03-2017
    **********************************************************************************************/

    FUNCTION get_pat_allergies
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_flg_show_msg IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_allergies    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create default no know allergy for new patient
    *             
    * @param i_lang                     language idenfier
    * @param i_prof                     Professional structure
    * @param i_id_patient               patient idenfier
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Amanda Lee
    * @version                          2.7.1
    * @since                            04-10-2017
    **********************************************************************************************/

    FUNCTION create_default_allergy
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;


    /********************************************************************************************
    * Get allergy unawareness for patient
    *             
    * @param i_lang                     language idenfier
    * @param i_id_patient               patient idenfier
    * @param o_allergies                cursor with allergies unawareness
    * @param o_error                    t_error_out type error
    *
    * @return                           true/false
    * 
    * @author                           Adriana Ramos
    * @since                            05/07/2018
    **********************************************************************************************/

    FUNCTION get_pat_allergy_unawareness
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_patient   IN patient.id_patient%TYPE,
        o_allergies OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*************************************************************************\
    *  Global package constants                                               *
    \*************************************************************************/
    g_package_owner          CONSTANT obj_name := 'ALERT';
    g_package_name           CONSTANT obj_name := pk_alertlog.who_am_i();
    g_allergy_review_context CONSTANT VARCHAR2(2 CHAR) := pk_review.get_allergies_context();

    g_num_variables CONSTANT PLS_INTEGER := 10;

    g_pat_allergy_status  CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_STATUS';
    g_pat_allergy_type    CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_TYPE';
    g_pat_allergy_aproved CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_APROVED';
    g_pat_allergy_edit    CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY.FLG_EDIT';
    g_pat_allergy_unaware CONSTANT sys_domain.code_domain%TYPE := 'PAT_ALLERGY_UNAWARENESS.FLG_STATUS';

    g_pat_allergy_flg_active    CONSTANT pat_allergy.flg_status%TYPE := 'A';
    g_pat_allergy_flg_cancelled CONSTANT pat_allergy.flg_status%TYPE := 'C';
    g_pat_allergy_flg_passive   CONSTANT pat_allergy.flg_status%TYPE := 'P';
    g_pat_allergy_flg_resolved  CONSTANT pat_allergy.flg_status%TYPE := 'R';
    g_documented                CONSTANT pat_allergy.flg_status%TYPE := 'D';

    g_flg_type_allergy     CONSTANT pat_allergy.flg_type%TYPE := 'A';
    g_flg_type_adv_react   CONSTANT pat_allergy.flg_type%TYPE := 'I';
    g_flg_type_intolerance CONSTANT pat_allergy.flg_type%TYPE := 'T';
    g_flg_type_propensity  CONSTANT pat_allergy.flg_type%TYPE := 'P';

    g_flg_edit_other CONSTANT pat_allergy.flg_edit%TYPE := 'O';

    g_unawareness_active    CONSTANT pat_allergy_unawareness.flg_status%TYPE := 'A';
    g_unawareness_outdated  CONSTANT pat_allergy_unawareness.flg_status%TYPE := 'O';
    g_unawareness_cancelled CONSTANT pat_allergy_unawareness.flg_status%TYPE := 'C';

    g_new_allergy_adr CONSTANT action.id_action%TYPE := 213540;

    g_color_beige CONSTANT VARCHAR2(8) := '0xC6C9B3'; -- BEIGE
    g_font_p      CONSTANT VARCHAR2(50) := 'ViewerState'; -- PASSIVE
    g_font_o      CONSTANT VARCHAR2(50) := 'ViewerCancelState'; -- OTHERS

    g_unable_asess   CONSTANT allergy_unawareness.id_allergy_unawareness%TYPE := 1;
    g_no_known       CONSTANT allergy_unawareness.id_allergy_unawareness%TYPE := 2;
    g_no_known_drugs CONSTANT allergy_unawareness.id_allergy_unawareness%TYPE := 3;

    g_other_allergy         CONSTANT allergy.id_allergy%TYPE := -1;
    g_food_allergy          CONSTANT allergy.id_allergy%TYPE := 1;
    g_environment_allergy   CONSTANT allergy.id_allergy%TYPE := 2;
    g_drug_allergy          CONSTANT allergy_inst_soft_market.id_allergy_parent%TYPE := 8899;
    g_drug_com_id_allergy   CONSTANT allergy_inst_soft_market.id_allergy_parent%TYPE := 777000000;
    g_drug_id_allergy       CONSTANT allergy_inst_soft_market.id_allergy_parent%TYPE := 888000000;
    g_drug_class_id_allergy CONSTANT allergy_inst_soft_market.id_allergy_parent%TYPE := 999000000;

    g_default_market CONSTANT allergy_inst_soft_market.id_market%TYPE := 0;

    g_error VARCHAR2(1000 CHAR);
    g_found BOOLEAN;

    g_exception EXCEPTION;

    g_flg_allergy CONSTANT pat_allergy.flg_type%TYPE := 'A';

    -- Constants used for reports purpose (by episode; by visit; by patient)
    g_rep_type_patient CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_rep_type_visit   CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_rep_type_episode CONSTANT VARCHAR2(1 CHAR) := 'E';

    --CODING TYPES
    g_snowmed CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_rxnorm  CONSTANT VARCHAR2(1 CHAR) := 'R';

    -- Constants used for filtering allergies
    g_allergies_adverse_reactions CONSTANT VARCHAR2(2 CHAR) := 'A'; -- ALL ALLERGIES AND ADVERSE REACTIONS;
    g_medication_allergies        CONSTANT VARCHAR2(2 CHAR) := 'M'; -- MEDICATION ALLERGIES;
    g_active_allergies_adv_react  CONSTANT VARCHAR2(2 CHAR) := 'A1'; -- ACTIVE ALLERGIES AND ADVERSE REACTIONS;
    g_active_medication_allergies CONSTANT VARCHAR2(2 CHAR) := 'M1'; -- ACTIVE MEDICATION ALLERGIES;
    g_allergies                   CONSTANT VARCHAR2(2 CHAR) := 'A2'; -- ALLERGIES;
    g_adverse_reactions           CONSTANT VARCHAR2(2 CHAR) := 'A3'; -- ADVERSE REACTIONS. 

    -- Allergies display limit constants
    g_allergies_limit_exceeded CONSTANT sys_message.code_message%TYPE := 'ALLERGY_M065';
    g_default_limit            CONSTANT NUMBER := 5000; -- last resource limit used if an error happens while loading the limit from config table
    g_allergy_search_limit     CONSTANT sys_config.id_sys_config%TYPE := 'ALLERGY_SEARCH_LIMIT';

    --ALERT-146245 - New medication prescription tool integration with PFH
    g_allergy_presc_type CONSTANT sys_config.id_sys_config%TYPE := 'ALLERGY_PRESC_TYPE';

    g_scope_patient CONSTANT VARCHAR2(1) := 'P';
    g_scope_visit   CONSTANT VARCHAR2(1) := 'V';
    g_scope_episode CONSTANT VARCHAR2(1) := 'E';

    g_cs_id_allergy          CONSTANT VARCHAR2(5) := '101';
    g_cs_id_allergy_type     CONSTANT VARCHAR2(5) := '103';
    g_cs_id_allergy_reaction CONSTANT VARCHAR2(5) := '105';
    g_cs_id_allergy_severity CONSTANT VARCHAR2(5) := '106';

    g_allergy_label_record_origin CONSTANT VARCHAR(100) := 'ALLERGY_M066';
    g_allergy_desc_record_origin  CONSTANT VARCHAR(100) := 'ALLERGY_M067';

    g_allergy_from_cda_recon CONSTANT VARCHAR(1) := 'Y';

    g_reported_by_patient CONSTANT VARCHAR(1) := 'U';

END pk_allergy;
/
