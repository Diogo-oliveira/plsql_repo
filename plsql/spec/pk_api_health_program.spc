/*-- Last Change Revision: $Rev: 690743 $*/
/*-- Last Change by: $Author: pedro.carneiro $*/
/*-- Date of last change: $Date: 2010-09-22 10:34:29 +0100 (qua, 22 set 2010) $*/

CREATE OR REPLACE PACKAGE pk_api_health_program IS

    /**
    * Retrieve available health programs,
    * signaling those which the patient can be subscribed to.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param o_avail        cursor
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION get_available_hpgs
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_avail   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates or edits a patient's health program inscription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_health_program health program identifier
    * @param i_monitor_loc  monitor location flag
    * @param i_dt_begin     begin date
    * @param i_dt_end       end date
    * @param i_notes        record notes
    * @param i_action       action performed
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION set_pat_hpg
    (
        i_lang           IN LANGUAGE.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_monitor_loc    IN pat_health_program.flg_monitor_loc%TYPE,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_notes          IN pat_health_program.notes%TYPE,
        i_action         IN action.internal_name%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Cancels a patient's health program inscription.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_pat_hpg      pat health program identifier
    * @param i_motive       cancellation motive
    * @param i_notes        cancellation notes
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Pedro Carneiro
    * @version               2.5.1.1
    * @since                2010/09/22
    */
    FUNCTION cancel_pat_hpg
    (
        i_lang    IN LANGUAGE.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        i_motive  IN pat_health_program.id_cancel_reason%TYPE,
        i_notes   IN pat_health_program.cancel_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

END pk_api_health_program;
/
