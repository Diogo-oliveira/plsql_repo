/*-- Last Change Revision: $Rev: 2006807 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-01-26 15:42:16 +0000 (qua, 26 jan 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_review AS

    --private constants for review contextes
    g_problems_context        CONSTANT review_detail.flg_context%TYPE := 'PR';
    g_allergies_context       CONSTANT review_detail.flg_context%TYPE := 'AL';
    g_habits_context          CONSTANT review_detail.flg_context%TYPE := 'HA';
    g_medication_context      CONSTANT review_detail.flg_context%TYPE := 'ME';
    g_blood_type_context      CONSTANT review_detail.flg_context%TYPE := 'BT';
    g_adv_directives_context  CONSTANT review_detail.flg_context%TYPE := 'AD';
    g_past_history_context    CONSTANT review_detail.flg_context%TYPE := 'PH';
    g_past_history_context_ft CONSTANT review_detail.flg_context%TYPE := 'PT';
    g_vital_signs_context     CONSTANT review_detail.flg_context%TYPE := 'VS';
    g_reported_med_context    CONSTANT review_detail.flg_context%TYPE := 'RM';
    g_med_reconcile_context   CONSTANT review_detail.flg_context%TYPE := 'MR';
    g_template_context        CONSTANT review_detail.flg_context%TYPE := 'TM';

    --public getters for review contextes
    FUNCTION get_problems_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_problems_context;
    END get_problems_context;

    FUNCTION get_allergies_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_allergies_context;
    END get_allergies_context;

    FUNCTION get_habits_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_habits_context;
    END get_habits_context;

    FUNCTION get_medication_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_medication_context;
    END get_medication_context;

    FUNCTION get_blood_type_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_blood_type_context;
    END get_blood_type_context;

    FUNCTION get_adv_directives_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_adv_directives_context;
    END get_adv_directives_context;

    FUNCTION get_past_history_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_past_history_context;
    END get_past_history_context;

    FUNCTION get_past_history_ft_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_past_history_context_ft;
    END get_past_history_ft_context;

    FUNCTION get_vital_signs_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_vital_signs_context;
    END get_vital_signs_context;
    FUNCTION get_reported_med_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_reported_med_context;
    END get_reported_med_context;

    FUNCTION get_med_reconcile_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_med_reconcile_context;
    END get_med_reconcile_context;

    FUNCTION get_template_context RETURN review_detail.flg_context%TYPE IS
    BEGIN
        RETURN g_template_context;
    END get_template_context;

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
    ) RETURN BOOLEAN IS
        l_message            debug_msg;
        l_row_out            table_varchar;
        l_category           category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_flg_problem_review review_detail.flg_problem_review%TYPE;
        l_count              NUMBER(6);
    BEGIN
    
        IF l_category = 'D'
        THEN
            l_flg_problem_review := pk_alert_constant.g_yes;
        ELSE
            l_flg_problem_review := pk_alert_constant.g_no;
        END IF;
    
        l_message := 'INSERT REVIEW_DETAIL';
        SELECT COUNT(0)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_record_area = i_id_record_area
           AND rd.flg_context = i_flg_context
           AND rd.id_professional = i_prof.id
           AND rd.dt_review = i_dt_review;
    
        IF l_count = 0
        THEN
            ts_review_detail.ins(id_record_area_in     => i_id_record_area,
                                 flg_context_in        => i_flg_context,
                                 id_professional_in    => i_prof.id,
                                 review_notes_in       => i_review_notes,
                                 dt_review_in          => i_dt_review,
                                 flg_problem_review_in => l_flg_problem_review,
                                 rows_out              => l_row_out);
        
            l_message := 'PROCESS INSERT review_detail';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REVIEW_DETAIL',
                                          i_rowids     => l_row_out,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REVIEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_review;

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
    ) RETURN BOOLEAN IS
        l_message            debug_msg;
        l_row_out            table_varchar;
        l_category           category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_flg_problem_review review_detail.flg_problem_review%TYPE;
        l_count              NUMBER(6);
    BEGIN
    
        IF l_category = 'D'
        THEN
            l_flg_problem_review := pk_alert_constant.g_yes;
        ELSE
            l_flg_problem_review := pk_alert_constant.g_no;
        END IF;
    
        l_message := 'INSERT REVIEW_DETAIL';
        SELECT COUNT(0)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_record_area = i_id_record_area
           AND rd.flg_context = i_flg_context
           AND rd.id_professional = i_prof.id
           AND rd.dt_review = i_dt_review;
    
        IF l_count = 0
        THEN
            ts_review_detail.ins(id_record_area_in     => i_id_record_area,
                                 flg_context_in        => i_flg_context,
                                 id_professional_in    => i_prof.id,
                                 review_notes_in       => i_review_notes,
                                 dt_review_in          => i_dt_review,
                                 id_episode_in         => i_episode,
                                 flg_auto_in           => i_flg_auto,
                                 revision_in           => NULL,
                                 flg_problem_review_in => l_flg_problem_review,
                                 rows_out              => l_row_out);
        
            l_message := 'PROCESS INSERT review_detail';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REVIEW_DETAIL',
                                          i_rowids     => l_row_out,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REVIEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_review;

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
    ) RETURN BOOLEAN IS
        l_message            debug_msg;
        l_row_out            table_varchar;
        l_category           category.flg_type%TYPE := pk_prof_utils.get_category(i_lang, i_prof);
        l_flg_problem_review review_detail.flg_problem_review%TYPE;
        l_count              NUMBER(6);
    BEGIN
    
        IF l_category = 'D'
        THEN
            l_flg_problem_review := pk_alert_constant.g_yes;
        ELSE
            l_flg_problem_review := pk_alert_constant.g_no;
        END IF;
    
        l_message := 'INSERT REVIEW_DETAIL';
        SELECT COUNT(0)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_record_area = i_id_record_area
           AND rd.flg_context = i_flg_context
           AND rd.id_professional = i_prof.id
           AND rd.dt_review = i_dt_review;
    
        IF l_count = 0
        THEN
            ts_review_detail.ins(id_record_area_in     => i_id_record_area,
                                 flg_context_in        => i_flg_context,
                                 id_professional_in    => i_prof.id,
                                 review_notes_in       => i_review_notes,
                                 dt_review_in          => i_dt_review,
                                 id_episode_in         => i_episode,
                                 flg_auto_in           => i_flg_auto,
                                 revision_in           => i_revision,
                                 flg_problem_review_in => l_flg_problem_review,
                                 rows_out              => l_row_out);
        
            l_message := 'PROCESS INSERT review_detail';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REVIEW_DETAIL',
                                          i_rowids     => l_row_out,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REVIEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_review;

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
    ) RETURN BOOLEAN IS
        l_message debug_msg;
        l_row_out table_varchar;
        l_count   NUMBER(6);
    BEGIN
        l_message := 'INSERT REVIEW_DETAIL';
        SELECT COUNT(0)
          INTO l_count
          FROM review_detail rd
         WHERE rd.id_record_area = i_id_record_area
           AND rd.flg_context = i_flg_context
           AND rd.id_professional = i_prof.id
           AND rd.dt_review = i_dt_review;
    
        IF l_count = 0
        THEN
            ts_review_detail.ins(id_record_area_in     => i_id_record_area,
                                 flg_context_in        => i_flg_context,
                                 id_professional_in    => i_prof.id,
                                 review_notes_in       => i_review_notes,
                                 dt_review_in          => i_dt_review,
                                 id_episode_in         => i_episode,
                                 flg_auto_in           => i_flg_auto,
                                 revision_in           => i_revision,
                                 flg_problem_review_in => i_flg_problem_review,
                                 rows_out              => l_row_out);
        
            l_message := 'PROCESS INSERT review_detail';
            t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'REVIEW_DETAIL',
                                          i_rowids     => l_row_out,
                                          o_error      => o_error);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'SET_REVIEW',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_review;

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
    ) RETURN BOOLEAN IS
        l_message           debug_msg;
        l_label_reviewed_on sys_message.desc_message%TYPE;
        l_label_rev_notes   sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_message           := 'GET LABEL REVIEWED';
        l_label_reviewed_on := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M004');
        l_label_rev_notes   := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M005');
    
        l_message := 'OPEN O_REVIEWS FOR';
        OPEN o_reviews FOR
            SELECT rd.id_record_area,
                   rd.flg_context,
                   rd.dt_review,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, i_id_episode) AS prof_spec_reg,
                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_reg,
                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_reg_str,
                   l_label_reviewed_on label_reviewed,
                   l_label_rev_notes label_rev_notes,
                   NULL review_notes,
                   rd.id_episode
              FROM review_detail rd
             WHERE rd.id_record_area = i_id_record_area
               AND rd.flg_context = i_flg_context
             ORDER BY dt_review DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_REVIEWS_BY_ID',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_reviews);
            RETURN FALSE;
        
    END get_reviews_by_id;

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
    ) RETURN BOOLEAN IS
        l_message           debug_msg;
        l_label_reviewed_on sys_message.desc_message%TYPE;
        l_label_rev_notes   sys_message.desc_message%TYPE;
    
    BEGIN
    
        l_message           := 'GET LABEL REVIEWED';
        l_label_reviewed_on := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M004');
        l_label_rev_notes   := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M005');
    
        l_message := 'OPEN O_REVIEWS FOR';
        OPEN o_reviews FOR
            SELECT /*+ opt_estimate(table a rows=1) */
             rd.id_record_area,
             rd.flg_context,
             rd.dt_review,
             (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional)
                FROM dual) AS prof_reg,
             (SELECT pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, i_id_episode)
                FROM dual) AS prof_spec_reg,
             (SELECT pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software)
                FROM dual) AS dt_reg,
             (SELECT pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof)
                FROM dual) dt_reg_str,
             l_label_reviewed_on label_reviewed,
             l_label_rev_notes label_rev_notes,
             rd.review_notes,
             rd.id_episode
              FROM review_detail rd
              JOIN TABLE(i_id_record_area) a
                ON a.column_value = rd.id_record_area
             WHERE rd.flg_context = i_flg_context
             ORDER BY id_record_area DESC, dt_review DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GROUP_REVIEWS_BY_ID',
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(i_cursor => o_reviews);
            RETURN FALSE;
    END get_group_reviews_by_id;

    PROCEDURE open_my_cursor(i_cursor IN OUT t_cur_reviews) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_record_area,
                   NULL flg_context,
                   NULL dt_review,
                   NULL prof_reg,
                   NULL prof_spec_reg,
                   NULL dt_reg,
                   NULL dt_reg_str,
                   NULL label_reviewed,
                   NULL label_rev_notes,
                   NULL review_notes,
                   NULL id_episode
              FROM dual
             WHERE 1 = 0;
    END;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_GREVIEWS_BY_PT_LAST_DT';
        --
        l_message debug_msg;
    
        l_code_label_reviewed_on CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M004';
        l_code_label_rev_notes   CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M005';
        l_label_reviewed_on sys_message.desc_message%TYPE;
        l_label_rev_notes   sys_message.desc_message%TYPE;
    BEGIN
    
        l_message           := 'GET LABEL REVIEWED';
        l_label_reviewed_on := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_label_reviewed_on);
        l_label_rev_notes   := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_label_rev_notes);
        l_message           := 'OPEN O_REVIEWS FOR';
        OPEN o_reviews FOR
            SELECT b.id_record_area,
                   rd2.flg_context,
                   b.dt_review,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd2.id_professional) AS prof_reg,
                   pk_prof_utils.get_spec_signature(i_lang, i_prof, rd2.id_professional, b.dt_review, i_id_episode) AS prof_spec_reg,
                   pk_date_utils.date_char_tsz(i_lang, b.dt_review, i_prof.institution, i_prof.software) AS dt_reg,
                   pk_date_utils.date_send_tsz(i_lang, b.dt_review, i_prof) dt_reg_str,
                   l_label_reviewed_on label_reviewed,
                   l_label_rev_notes label_rev_notes,
                   rd2.review_notes,
                   rd2.id_episode
              FROM (SELECT a.id_record_area, a.id_profile_template, MAX(a.dt_review) dt_review
                      FROM (SELECT rd.id_record_area,
                                   nvl((SELECT pk_prof_utils.get_prof_profile_template(profissional(rd.id_professional,
                                                                                                   epis.id_institution,
                                                                                                   ei.id_software))
                                         FROM episode epis
                                         JOIN epis_info ei
                                           ON ei.id_episode = epis.id_episode
                                        WHERE epis.id_episode = i_id_episode),
                                       pk_alert_constant.g_profile_template_all) id_profile_template,
                                   rd.dt_review
                              FROM review_detail rd
                              JOIN TABLE(i_id_record_area) a
                                ON a.column_value = rd.id_record_area
                             WHERE rd.flg_context = i_flg_context) a
                     GROUP BY a.id_record_area, a.id_profile_template) b
              JOIN review_detail rd2
                ON rd2.id_record_area = b.id_record_area
               AND rd2.flg_context = i_flg_context
               AND rd2.dt_review = b.dt_review
             ORDER BY b.id_record_area DESC, b.dt_review DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            open_my_cursor(i_cursor => o_reviews);
            RETURN FALSE;
    END get_greviews_by_pt_last_dt;

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
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REVIEWS_BY_PT';
        --
        l_message debug_msg;
        --
        l_code_label_reviewed_on CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M004';
        l_code_label_rev_notes   CONSTANT sys_message.code_message%TYPE := 'DETAIL_COMMON_M005';
        l_label_reviewed_on sys_message.desc_message%TYPE;
        l_label_rev_notes   sys_message.desc_message%TYPE;
        --
        l_prof_temp profile_template.id_profile_template%TYPE;
        l_epis_inst institution.id_institution%TYPE;
        l_epis_soft software.id_software%TYPE;
    
    BEGIN
    
        l_message           := 'GET LABEL REVIEWED';
        l_label_reviewed_on := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_label_reviewed_on);
        l_label_rev_notes   := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => l_code_label_rev_notes);
    
        l_message := 'GET I_PROF PROFILE TEMPLATE';
        IF i_id_prof_templ IS NULL
        THEN
            l_prof_temp := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        ELSE
            l_prof_temp := i_id_prof_templ;
        END IF;
    
        l_message := 'GET EPISODE INST AND SOFT';
        BEGIN
            SELECT epis.id_institution, ei.id_software
              INTO l_epis_inst, l_epis_soft
              FROM episode epis
              JOIN epis_info ei
                ON ei.id_episode = epis.id_episode
             WHERE epis.id_episode = i_id_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_epis_inst := NULL;
                l_epis_soft := NULL;
        END;
    
        IF l_epis_inst IS NOT NULL
           AND l_epis_soft IS NOT NULL
        THEN
            l_message := 'OPEN O_REVIEWS(1) FOR';
            OPEN o_reviews FOR
                SELECT rd.id_record_area,
                       rd.flg_context,
                       rd.dt_review,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS prof_reg,
                       pk_prof_utils.get_spec_signature(i_lang, i_prof, rd.id_professional, rd.dt_review, i_id_episode) AS prof_spec_reg,
                       pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_reg,
                       pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_reg_str,
                       l_label_reviewed_on label_reviewed,
                       l_label_rev_notes label_rev_notes,
                       NULL review_notes,
                       rd.id_episode
                  FROM review_detail rd
                 WHERE rd.id_record_area = i_id_record_area
                   AND rd.flg_context = i_flg_context
                   AND pk_prof_utils.get_prof_profile_template(profissional(rd.id_professional,
                                                                            l_epis_inst,
                                                                            l_epis_soft)) = l_prof_temp
                 ORDER BY dt_review DESC;
        ELSE
            l_message := 'OPEN O_REVIEWS(2) FOR';
            open_my_cursor(i_cursor => o_reviews);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_alert_exceptions.reset_error_state;
            open_my_cursor(i_cursor => o_reviews);
            RETURN FALSE;
    END get_reviews_by_pt;

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
    ) RETURN VARCHAR2 IS
        l_message debug_msg;
    
        l_reviewed_epis VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_error         t_error_out;
    
    BEGIN
    
        BEGIN
            l_message := 'CHECK IF TASK WAS REVIEWED. i_id_episode: ' || i_id_episode || ' i_id_record_area: ' ||
                         i_id_record_area || ' i_flg_context: ' || i_flg_context;
            SELECT pk_alert_constant.g_yes
              INTO l_reviewed_epis
              FROM review_detail rd
             INNER JOIN prof_cat pc
                ON pc.id_professional = rd.id_professional
             INNER JOIN category cat
                ON cat.id_category = pc.id_category
             WHERE rd.id_record_area = i_id_record_area
               AND rd.flg_context = i_flg_context
               AND rd.id_episode = i_id_episode
               AND cat.flg_type IN (SELECT /*+ opt_estimate(table c rows=2) */
                                     column_value
                                      FROM TABLE(i_cat_types) c)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_reviewed_epis;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'CHECK_REVIEWED_RECORD',
                                              o_error    => l_error);
            RETURN pk_alert_constant.g_no;
        
    END check_reviewed_record;

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
    ) RETURN review_detail.id_professional%TYPE IS
    
        l_message debug_msg;
        l_id_prof professional.id_professional%TYPE;
    
    BEGIN
    
        BEGIN
            l_message := 'get_last_review_prof. i_id_episode: ' || i_id_episode || ' i_id_record_area: ' ||
                         i_id_record_area || ' i_flg_context: ' || i_flg_context;
        
            SELECT t.id_professional
              INTO l_id_prof
              FROM (SELECT row_number() over(PARTITION BY rd.id_record_area, rd.flg_context ORDER BY rd.dt_review DESC) rnl,
                           rd.id_professional
                      FROM review_detail rd
                     WHERE rd.id_record_area = i_id_record_area
                       AND rd.flg_context = i_flg_context
                       AND rd.id_episode = i_id_episode
                       AND rd.flg_auto = pk_alert_constant.g_no) t
             WHERE rnl = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_id_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_message := 'GET_LAST_REVIEW_PROF exception error: ' || SQLERRM;
            pk_alertlog.log_info(text            => l_message,
                                 object_name     => g_package_owner,
                                 sub_object_name => 'get_last_review_prof');
        
            RETURN NULL;
    END get_last_review_prof;

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
    ) RETURN review_detail.dt_review%TYPE IS
        l_message   debug_msg;
        l_dt_review review_detail.dt_review%TYPE;
    BEGIN
    
        BEGIN
            l_message := 'get_last_review_date. i_id_episode: ' || i_id_episode || ' i_id_record_area: ' ||
                         i_id_record_area || ' i_flg_context: ' || i_flg_context;
            SELECT t.dt_review
              INTO l_dt_review
              FROM (SELECT row_number() over(PARTITION BY rd.id_record_area, rd.flg_context ORDER BY rd.dt_review DESC) rnl,
                           rd.dt_review
                      FROM review_detail rd
                     WHERE rd.id_record_area = i_id_record_area
                       AND rd.flg_context = i_flg_context
                       AND rd.id_episode = i_id_episode
                       AND rd.flg_auto = pk_alert_constant.g_no) t
             WHERE rnl = 1;
        
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_dt_review;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            l_message := 'get_last_review_date exception error: ' || SQLERRM;
            pk_alertlog.log_info(text            => l_message,
                                 object_name     => g_package_owner,
                                 sub_object_name => 'get_last_review_date');
        
            RETURN NULL;
    END get_last_review_date;

    /**
    * Retrieves all reviews for a given Problem, Allergy, Habit, Medication, Blood type,
    * Advanced directive or Past history, ordered by date
    *
    * @param i_lang            language id
    * @param i_id_episode      episode id
    * @param i_id_record_area  group of record ids
    * @param i_flg_context     record context flag ('PR', 'AL', 'HA', 'ME', 'BT', 'AD', 'PH')
    * @param o_reviews         cursor for reviews
    * @param o_error           error message
    *
    * @author                  rui.baeta
    * @since                   2009-10-22
    * @version                 v2.5.0.7
    * @reason                  ALERT-870
    */
    FUNCTION get_review_status
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_record_area IN NUMBER,
        i_flg_context    IN review_detail.flg_context%TYPE,
        o_reviews        OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_message            debug_msg;
        l_label_reviewed_on  sys_message.desc_message%TYPE;
        l_label_rev_notes    sys_message.desc_message%TYPE;
        l_last_reviewed      VARCHAR2(200 CHAR);
        l_label_not_review   VARCHAR2(200 CHAR);
        l_label_review_visit VARCHAR2(200 CHAR);
        l_num                NUMBER;
    BEGIN
    
        l_message           := 'GET LABEL REVIEWED';
        l_label_reviewed_on := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M004');
        l_label_rev_notes   := pk_message.get_message(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_code_mess => 'DETAIL_COMMON_M005');
    
        l_last_reviewed      := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'DETAIL_COMMON_M020');
        l_label_not_review   := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'DETAIL_COMMON_M019');
        l_label_review_visit := pk_message.get_message(i_lang      => i_lang,
                                                       i_prof      => i_prof,
                                                       i_code_mess => 'DETAIL_COMMON_M021');
    
        l_message := 'OPEN O_REVIEWS FOR';
        SELECT COUNT(1)
          INTO l_num
          FROM review_detail rd
         WHERE rd.id_record_area = i_id_record_area
           AND rd.flg_context = i_flg_context
           AND rd.id_episode = i_id_episode;
    
        IF l_num > 0 -- review on this episode
        THEN
            OPEN o_reviews FOR
                SELECT *
                  FROM (SELECT rd.id_record_area,
                               rd.flg_context,
                               rd.dt_review,
                               pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS prof_reg,
                               pk_prof_utils.get_spec_signature(i_lang,
                                                                i_prof,
                                                                rd.id_professional,
                                                                rd.dt_review,
                                                                i_id_episode) AS prof_spec_reg,
                               pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_reg,
                               pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_reg_str,
                               l_label_review_visit || ' ' || l_label_rev_notes label_reviewed,
                               decode(rd.id_record_area, NULL, pk_alert_constant.g_no, pk_alert_constant.g_yes) flg_review,
                               l_last_reviewed || ' ' ||
                               pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || ' ' ||
                               pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software) last_review
                          FROM review_detail rd
                         WHERE rd.id_record_area = i_id_record_area
                           AND rd.flg_context = i_flg_context
                           AND rd.id_episode = i_id_episode
                         ORDER BY id_record_area DESC, dt_review DESC)
                 WHERE rownum = 1;
        ELSE
            SELECT COUNT(1)
              INTO l_num
              FROM review_detail rd
             WHERE rd.id_record_area = i_id_record_area
               AND rd.flg_context = i_flg_context;
            IF l_num > 0 -- review for this record not on this episode
            THEN
                OPEN o_reviews FOR
                    SELECT *
                      FROM (SELECT rd.id_record_area,
                                   rd.flg_context,
                                   rd.dt_review,
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, rd.id_professional) AS prof_reg,
                                   pk_prof_utils.get_spec_signature(i_lang,
                                                                    i_prof,
                                                                    rd.id_professional,
                                                                    rd.dt_review,
                                                                    i_id_episode) AS prof_spec_reg,
                                   pk_date_utils.date_char_tsz(i_lang, rd.dt_review, i_prof.institution, i_prof.software) AS dt_reg,
                                   pk_date_utils.date_send_tsz(i_lang, rd.dt_review, i_prof) dt_reg_str,
                                   l_label_review_visit || ' ' || l_label_not_review label_reviewed,
                                   pk_alert_constant.g_no flg_review,
                                   l_last_reviewed || ' ' ||
                                   pk_prof_utils.get_name_signature(i_lang, i_prof, id_professional) || ' ' ||
                                   pk_date_utils.date_char_tsz(i_lang, dt_review, i_prof.institution, i_prof.software) last_review
                              FROM review_detail rd
                             WHERE rd.id_record_area = i_id_record_area
                               AND rd.flg_context = i_flg_context
                             ORDER BY id_record_area DESC, dt_review DESC)
                     WHERE rownum = 1;
            ELSE
                -- not reviewed at all
                OPEN o_reviews FOR
                    SELECT i_id_record_area id_record_area,
                           i_flg_context flg_context,
                           NULL dt_review,
                           NULL prof_reg,
                           NULL prof_spec_reg,
                           NULL dt_reg,
                           NULL dt_reg_str,
                           l_label_review_visit || ' ' || l_label_not_review label_reviewed,
                           pk_alert_constant.g_no flg_review,
                           l_last_reviewed || ' ' last_review
                      FROM dual;
            END IF;
        
        END IF;
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            -- Unexpected error
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => l_message,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_GROUP_REVIEWS_BY_ID',
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_reviews);
            RETURN FALSE;
    END get_review_status;

BEGIN
    -- Log initialization.
    pk_alertlog.log_init(object_name => g_package_name);

END pk_review;
/
