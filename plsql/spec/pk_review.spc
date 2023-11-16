/*-- Last Change Revision: $Rev: 1659058 $*/
/*-- Last Change by: $Author: mario.mineiro $*/
/*-- Date of last change: $Date: 2014-11-11 15:13:28 +0000 (ter, 11 nov 2014) $*/

CREATE OR REPLACE PACKAGE pk_review AS

    g_vaccines_context CONSTANT review_detail.flg_context%TYPE := 'VA';

    -- Public type declarations
    TYPE t_rec_review IS RECORD(
        id_record_area  review_detail.id_record_area%TYPE,
        flg_context     review_detail.flg_context%TYPE,
        dt_review       review_detail.dt_review%TYPE,
        prof_reg        professional.name%TYPE,
        prof_spec_reg   pk_translation.t_desc_translation,
        dt_reg          VARCHAR2(200 CHAR),
        dt_reg_str      VARCHAR2(200 CHAR),
        label_reviewed  sys_message.desc_message%TYPE,
        label_rev_notes sys_message.desc_message%TYPE,
        review_notes    review_detail.review_notes%TYPE,
        id_episode      review_detail.id_episode%TYPE);
    TYPE t_cur_reviews IS REF CURSOR RETURN t_rec_review;
    TYPE t_tab_reviews IS TABLE OF t_rec_review;

    SUBTYPE obj_name IS VARCHAR2(30);
    SUBTYPE debug_msg IS VARCHAR2(4000);

    /**
    * Creates a review for Problems, Allergies, Habits, Medication, Blood type,
    * Advanced directives or Past history.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_dt_review       date of review
    * @param i_review_notes    review notes (optional)
    * @param o_error           error message
    *
    * @author                  rui.baeta
    * @since                   2009-10-22
    * @version                 v2.5.0.7
    * @reason                  ALERT-870
    */
    FUNCTION set_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_dt_review      IN review_detail.dt_review%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a review for Problems, Allergies, Habits, Medication, Blood type,
    * Advanced directives or Past history.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_dt_review       date of review
    * @param i_review_notes    review notes (optional)
    * @param i_episode         episode identifier
    * @param i_flg_auto        reviewed automatically (Y/N)
    * @param o_error           error message
    *
    * @author                  Paulo teixeira
    * @since                   2010-10-26
    * @version                 v2.5.1.2
    * @reason                  ALERT-1090
    */
    FUNCTION set_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_dt_review      IN review_detail.dt_review%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a review for Problems, Allergies, Habits, Medication, Blood type,
    * Advanced directives or Past history.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_dt_review       date of review
    * @param i_review_notes    review notes (optional)
    * @param i_episode         episode identifier
    * @param i_flg_auto        reviewed automatically (Y/N)
    * @param i_revision        register revision
    * @param o_error           error message
    *
    * @author                  Filipe Machado
    * @since                   2010-10-29
    * @version                 v2.5.1.2
    * @reason                  ALERT-127537
    */
    FUNCTION set_review
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_dt_review      IN review_detail.dt_review%TYPE,
        i_review_notes   IN review_detail.review_notes%TYPE,
        i_episode        IN review_detail.id_episode%TYPE,
        i_flg_auto       IN review_detail.flg_auto%TYPE,
        i_revision       IN review_detail.revision%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Creates a review for Problems, Allergies, Habits, Medication, Blood type,
    * Advanced directives or Past history.
    *
    * @param i_lang            language id
    * @param i_prof            professional who is inserting this review
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_dt_review       date of review
    * @param i_review_notes    review notes (optional)
    * @param i_episode         episode identifier
    * @param i_flg_auto        reviewed automatically (Y/N)
    * @param i_revision        register revision
    * @param i_flg_problem_review        problem review
    * @param o_error           error message
    *
    * @author                  Paulo teixeira
    * @since                   2010-11-12
    * @version                 v2.5.1.2
    */
    FUNCTION set_review
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_record_area     IN review_detail.id_record_area%TYPE,
        i_flg_context        IN review_detail.flg_context%TYPE,
        i_dt_review          IN review_detail.dt_review%TYPE,
        i_review_notes       IN review_detail.review_notes%TYPE,
        i_episode            IN review_detail.id_episode%TYPE,
        i_flg_auto           IN review_detail.flg_auto%TYPE,
        i_revision           IN review_detail.revision%TYPE,
        i_flg_problem_review IN review_detail.flg_problem_review%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /**
    * Retrieves all reviews for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  rui.baeta
    * @since                   2009-10-22
    * @version                 v2.5.0.7
    * @reason                  ALERT-870
    */
    FUNCTION get_reviews_by_id
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        o_reviews        OUT t_cur_reviews,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves all reviews for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  group of record ids
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  rui.baeta
    * @since                   2009-10-22
    * @version                 v2.5.0.7
    * @reason                  ALERT-870
    */
    FUNCTION get_group_reviews_by_id
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN table_number,
        i_flg_context    IN review_detail.flg_context%TYPE,
        o_reviews        OUT t_cur_reviews,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves the last profile_template review for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    * (Based on get_group_reviews_by_id)
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  group of record ids
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH')
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  Alexandre Santos
    * @since                   2011-05-31
    * @version                 2.6.1.1
    * @reason                  ALERT-41412
    */
    FUNCTION get_greviews_by_pt_last_dt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN table_number,
        i_flg_context    IN review_detail.flg_context%TYPE,
        o_reviews        OUT t_cur_reviews,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Retrieves all reviews for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    * and for a given profile template
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_id_prof_templ   profile template id
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  Alexandre Santos
    * @since                   2011-05-31
    * @version                 2.6.1.1
    * @reason                  ALERT-41412
    */
    FUNCTION get_reviews_by_pt
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_id_prof_templ  IN profile_template.id_profile_template%TYPE,
        o_reviews        OUT t_cur_reviews,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    
    /**
    * Verify if a record had already been reviewed in a given episode
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    * @param i_cat_types       List of categories flg_types to consider in the check 
    *
    * @return                  Y - the record was reviewed by some professional in the given episode. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION check_reviewed_record
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE,
        i_cat_types      IN table_varchar
    ) RETURN VARCHAR2;
    --
    /**
    * Get the professional that performed the last review of a record.
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    *
    * @return                  Y - the record was reviewed by some professional in the given episode. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION get_last_review_prof
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE
    ) RETURN review_detail.id_professional%TYPE;
    
    /**
    * Get the date in which was performed the last review
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  record id
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH', 'TM')
    *
    * @return                  Y - the record was reviewed by some professional in the given episode. N-otherwise.    
    *
    * @author                  Sofia Mendes
    * @since                   28-Feb-2012
    * @version                 v2.6.2
    */
    FUNCTION get_last_review_date
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN review_detail.id_record_area%TYPE,
        i_flg_context    IN review_detail.flg_context%TYPE
    ) RETURN review_detail.dt_review%TYPE;

    g_package_owner CONSTANT obj_name := 'ALERT';
    g_package_name  CONSTANT obj_name := pk_alertlog.who_am_i();

    FUNCTION get_review_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN NUMBER,
        i_flg_context    IN review_detail.flg_context%TYPE,
        o_reviews        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    --review context for each area
    FUNCTION get_problems_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_allergies_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_habits_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_medication_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_blood_type_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_adv_directives_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_past_history_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_past_history_ft_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_vital_signs_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_reported_med_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_med_reconcile_context RETURN review_detail.flg_context%TYPE;
    FUNCTION get_template_context RETURN review_detail.flg_context%TYPE;
END;
/
