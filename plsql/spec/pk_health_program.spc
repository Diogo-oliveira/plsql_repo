/*-- Last Change Revision: $Rev: 2028714 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:29 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_health_program IS

    /*******************************************************************************************
    * Retrieves a patient's health program data. If the health program identifier is NULL,
    * then it returns default values for a new inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param i_flg_action       action fired
    * @param o_hpg              cursor
    * @param o_min_dt           date domain left bound
    * @param o_max_dt           date domain right bound
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_flg_action     IN action.internal_name%TYPE,
        o_hpg            OUT pk_types.cursor_type,
        o_min_dt         OUT VARCHAR2,
        o_max_dt         OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieves a patient's health programs.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_hpgs             cursor (id, name, dt_begin, dt_end, state)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpgs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieves a history of operations made in a patient's health program.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_pat_hpg          patient health program identifier
    * @param o_desc             cursor
    * @param o_hist             cursor (info, details)
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_pat_hpg_hist
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        o_desc    OUT pk_types.cursor_type,
        o_hist    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieve available health programs,
    * signaling those which the patient can be subscribed to.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param o_avail            cursor
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION get_available_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_avail   OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Creates or edits a patient's health program inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param i_health_program   health program identifier
    * @param i_monitor_loc      monitor location flag
    * @param i_dt_begin         begin date
    * @param i_dt_end           end date
    * @param i_notes            record notes
    * @param i_action           action performed
    * @param i_origin           identify IF is pk_pregnancy call this function 
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION set_pat_hpg
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN patient.id_patient%TYPE,
        i_health_program IN health_program.id_health_program%TYPE,
        i_monitor_loc    IN pat_health_program.flg_monitor_loc%TYPE,
        i_dt_begin       IN VARCHAR2,
        i_dt_end         IN VARCHAR2,
        i_notes          IN pat_health_program.notes%TYPE,
        i_action         IN action.internal_name%TYPE,
        i_origin         IN VARCHAR2 DEFAULT NULL,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Cancels a patient's health program inscription.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_pat_hpg          pat health program identifier
    * @param i_motive           cancellation motive
    * @param i_notes            cancellation notes
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/04/15
    ********************************************************************************************/
    FUNCTION cancel_pat_hpg
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pat_hpg IN pat_health_program.id_pat_health_program%TYPE,
        i_motive  IN pat_health_program.id_cancel_reason%TYPE,
        i_notes   IN pat_health_program.cancel_notes%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Checks if an institution has health programs configured, if the professional is a
    * physician. If the professional is a nurse, then it also checks configuration
    * HEALTH_PROGRAMS_NURSE_PERMISSION, that allows nurses to change health programs.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_prof_cat         logged professional category
    * @param o_avail            'Y', if at least one health program is available, 'N' otherwise
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/05/06
    ********************************************************************************************/
    FUNCTION check_hpgs
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_prof_cat IN category.flg_type%TYPE,
        o_avail    OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************
    * Retrieves the health programs a patient is currently inscripted.
    *
    * @param i_lang             language identifier
    * @param i_prof             logged professional structure
    * @param i_patient          patient identifier
    * @param o_hpgs             cursor
    * @param o_error            error
    *
    * @return                   false if errors occur, true otherwise
    *
    * @raises
    *
    * @author                   Pedro Carneiro
    * @version                   1.0
    * @since                    2009/05/07
    ********************************************************************************************/
    FUNCTION get_pat_insc_hpgs
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        o_hpgs    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Get patient's health programs.
    *
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_exc_status   statuses list to exclude
    *
    * @return               health program identifiers list
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/10/30
    */
    FUNCTION get_pat_hpgs
    (
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_exc_status IN table_varchar := table_varchar()
    ) RETURN table_number;

    /**
    * Get health programs collection.
    * Used in periodic observations.
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_patient      patient identifier
    * @param i_exc_status   statuses list to exclude
    *
    * @return               health programs collection
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/11/12
    */
    FUNCTION get_pat_hpgs_coll
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_exc_status IN table_varchar := table_varchar()
    ) RETURN t_coll_sets;

    /**
    * Get monitoring location description.
    *
    * @param i_lang         language identifier
    * @param i_inst         institution identifier
    * @param i_domain       monitor location domain code
    * @param i_flg_mon_loc  monitor location flag
    *
    * @return               monitoring location description
    *
    * @author               Pedro Carneiro
    * @version               2.5
    * @since                2012/10/30
    */
    FUNCTION get_monitor_loc
    (
        i_lang        IN language.id_language%TYPE,
        i_inst        IN institution.id_institution%TYPE,
        i_domain      IN sys_domain.code_domain%TYPE,
        i_flg_mon_loc IN pat_health_program.flg_monitor_loc%TYPE
    ) RETURN sys_domain.desc_val%TYPE;

    g_error         VARCHAR2(4000);
    g_package_owner VARCHAR2(32);
    g_package_name  VARCHAR2(32);
    g_found         BOOLEAN;

    g_flg_yes     CONSTANT VARCHAR2(1) := pk_alert_constant.g_yes;
    g_flg_no      CONSTANT VARCHAR2(1) := pk_alert_constant.g_no;
    g_action_inc  CONSTANT action.internal_name%TYPE := 'ADD';
    g_action_new  CONSTANT action.internal_name%TYPE := 'NEW';
    g_action_edit CONSTANT action.internal_name%TYPE := 'EDIT';
    g_action_rem  CONSTANT action.internal_name%TYPE := 'REMOVE';

    g_flg_status_domain    CONSTANT sys_domain.code_domain%TYPE := 'PAT_HEALTH_PROGRAM.FLG_STATUS';
    g_flg_status_active    CONSTANT sys_domain.val%TYPE := 'A';
    g_flg_status_inactive  CONSTANT sys_domain.val%TYPE := 'I';
    g_flg_status_cancelled CONSTANT sys_domain.val%TYPE := 'C';

    g_flg_mon_domain_grid CONSTANT sys_domain.code_domain%TYPE := 'PAT_HEALTH_PROGRAM.FLG_MONITOR_LOC.GRID';
    g_flg_mon_domain_form CONSTANT sys_domain.code_domain%TYPE := 'PAT_HEALTH_PROGRAM.FLG_MONITOR_LOC.FORM';
    g_flg_mon_inst        CONSTANT sys_domain.val%TYPE := 'H';
    g_flg_mon_other       CONSTANT sys_domain.val%TYPE := 'O';

    g_flg_state_change CONSTANT pat_health_program_hist.flg_operation%TYPE := 'S';
    g_flg_edit         CONSTANT pat_health_program_hist.flg_operation%TYPE := 'E';
    g_flg_add          CONSTANT pat_health_program_hist.flg_operation%TYPE := 'A';
END pk_health_program;
/