/*-- Last Change Revision: $Rev: 1990194 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2021-05-25 15:54:21 +0100 (ter, 25 mai 2021) $*/

CREATE OR REPLACE PACKAGE BODY pk_hea_prv_pat IS

    g_flg_origin VARCHAR2(1 CHAR);
    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var IS
    BEGIN
        g_row.id_patient := NULL;
    END;

    /**
    * Fetchs all the variables for the patient if they have not been fetched yet.
    *
    * @param i_id_patient Patient Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var(i_id_patient IN patient.id_patient%TYPE) IS
    BEGIN
        IF g_row.id_patient IS NULL
           OR g_row.id_patient != i_id_patient
        THEN
            g_error := 'SELECT * INTO g_row_pat FROM patient';
            pk_alertlog.log_debug(g_error);
            SELECT *
              INTO g_row
              FROM patient p
             WHERE p.id_patient = i_id_patient;
        END IF;
    END;

    /**
    * Fetchs all the variables for the patient if they have not been fetched yet.
    *
    * @param i_id_announced_arrival Announced arrival Id
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE check_var_ann_arr(i_id_announced_arrival announced_arrival.id_announced_arrival%TYPE) IS
    BEGIN
        IF g_ann_arr_pat IS NULL
           OR g_ann_arr_pat.count = 0
           OR g_ann_arr_pat(1).id_announced_arrival IS NULL
           OR g_ann_arr_pat(1).id_announced_arrival != i_id_announced_arrival
        THEN
            g_error := 'SELECT * INTO g_ann_arr_pat FROM announced_arrival';
            pk_alertlog.log_debug(g_error);
            SELECT a.id_announced_arrival, p.id_pre_hosp_accident, p.name, p.gender, p.age, p.dt_birth, pat.dt_deceased
              BULK COLLECT
              INTO g_ann_arr_pat
              FROM announced_arrival a
             INNER JOIN episode e
                ON e.id_episode = a.id_episode
             INNER JOIN patient pat
                ON pat.id_patient = e.id_patient
             INNER JOIN pre_hosp_accident p
                ON a.id_pre_hosp_accident = p.id_pre_hosp_accident
             WHERE a.id_announced_arrival = i_id_announced_arrival;
        END IF;
    END;

    /**
    * Returns the patient name
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_announced_arrival Announced arrival id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_name
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
    
        l_inactive sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'HEADER_EA_T008');
    
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            check_var(i_id_patient);
        
            IF (g_row.flg_status = g_inactive_pat)
            THEN
                RETURN(pk_patient.get_pat_name(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule) || ' (' ||
                       l_inactive || ')');
            ELSE
                RETURN pk_patient.get_pat_name(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule);
            END IF;
        ELSIF i_id_announced_arrival IS NOT NULL
        THEN
            check_var_ann_arr(i_id_announced_arrival);
            RETURN g_ann_arr_pat(1).name;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient birth date
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_announced_arrival Announced arrival id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_birth_date
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
        l_birth VARCHAR2(100);
    BEGIN
        IF pk_sysconfig.get_config('SHOW_DT_BIRTH_HEADER', i_prof) = pk_alert_constant.g_no
        THEN
            RETURN NULL;
        ELSE
            IF i_id_patient IS NOT NULL
            THEN
                check_var(i_id_patient);
                l_birth := pk_date_utils.date_chr_short_read(i_lang, g_row.dt_birth, i_prof);
            ELSIF i_id_announced_arrival IS NOT NULL
            THEN
                check_var_ann_arr(i_id_announced_arrival);
                l_birth := pk_date_utils.date_chr_short_read(i_lang, g_ann_arr_pat(1).dt_birth, i_prof);
            END IF;
        
            IF l_birth IS NOT NULL
            THEN
                RETURN pk_message.get_message(i_lang, i_prof, 'HEADER_M017') || ' ' || l_birth;
            ELSE
                RETURN NULL;
            END IF;
        END IF;
    END;

    /**
    * Returns the patient gender
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_announced_arrival Announced arrival id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_gender
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            check_var(i_id_patient);
            RETURN pk_patient.get_gender(i_lang, g_row.gender);
        ELSIF i_id_announced_arrival IS NOT NULL
        THEN
            check_var_ann_arr(i_id_announced_arrival);
            RETURN pk_patient.get_gender(i_lang, g_ann_arr_pat(1).gender);
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient age
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_announced_arrival Announced arrival id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_age
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            check_var(i_id_patient);
            RETURN pk_patient.get_pat_age(i_lang,
                                          g_row.dt_birth,
                                          g_row.dt_deceased,
                                          g_row.age,
                                          i_prof.institution,
                                          i_prof.software);
        
        ELSIF i_id_announced_arrival IS NOT NULL
        THEN
            check_var_ann_arr(i_id_announced_arrival);
            RETURN pk_patient.get_pat_age(i_lang,
                                          g_ann_arr_pat     (1).dt_birth,
                                          g_ann_arr_pat     (1).dt_deceased,
                                          g_ann_arr_pat     (1).age,
                                          i_prof.institution,
                                          i_prof.software);
        ELSE
            RETURN NULL;
        END IF;
    
    END;

    /**
    * Returns the patient pregnancy weeks
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_preg_weeks
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_weeks VARCHAR2(32);
        l_error t_error_out;
    BEGIN
        IF NOT pk_woman_health.get_pregnancy_weeks(i_lang, i_prof, i_id_patient, l_weeks, l_error)
        THEN
            RAISE g_exception;
        ELSE
            RETURN l_weeks;
        END IF;
    END;

    /**
    * Returns the patient gender, age and pregnanc weeks.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_announced_arrival Announced arrival id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_gender_age_preg_weeks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL
    ) RETURN VARCHAR IS
    
        l_gender    VARCHAR2(10 CHAR);
        l_age       VARCHAR2(10 CHAR);
        l_preg_weks VARCHAR2(10 CHAR);
        l_ret       VARCHAR2(100 CHAR);
    
    BEGIN
    
        l_gender := get_gender(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
    
        IF pk_sysconfig.get_config('DEFAULT_PAT_AGE_DISPLAY', i_prof) = pk_alert_constant.g_no
        THEN
            l_age := NULL;
        ELSE
            l_age := get_age(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
        END IF;
    
        IF i_id_patient IS NOT NULL
        THEN
            l_preg_weks := get_preg_weeks(i_lang, i_prof, i_id_patient);
        END IF;
    
        l_ret := l_gender;
    
        IF l_age IS NOT NULL
        THEN
            l_ret := l_ret || '/' || l_age;
        END IF;
    
        IF l_preg_weks IS NOT NULL
        THEN
            l_ret := l_ret || ' / ' || l_preg_weks;
        END IF;
    
        RETURN l_ret;
    END;

    /**
    * Returns the shortcut for the pregnancy button.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_shortcut_preg_death
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
        l_preg_weks VARCHAR2(10);
        l_status    episode.flg_status%TYPE;
    
        l_is_sign_off VARCHAR2(1);
        l_error       t_error_out;
    BEGIN
        IF i_prof.software IN (15, 16, 25, 33, 36, 47, pk_alert_constant.g_soft_social) -- Technicians and therapist don't have this area.
        THEN
            RETURN NULL;
        END IF;
        IF --is_deceased(i_lang, i_prof, i_id_patient) OR
         pk_tools.get_prof_profile_template(i_prof) IN (655, 665, 119, 120, 44, 45)
        THEN
            RETURN NULL; -- Change to the correct shortcut
        ELSE
            l_preg_weks := get_preg_weeks(i_lang, i_prof, i_id_patient);
            IF l_preg_weks IS NOT NULL
            THEN
                IF i_id_episode IS NOT NULL
                THEN
                    IF NOT pk_sign_off.get_epis_sign_off_state(i_lang     => i_lang,
                                                               i_prof     => i_prof,
                                                               i_episode  => i_id_episode,
                                                               o_sign_off => l_is_sign_off,
                                                               o_error    => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    IF l_is_sign_off = pk_alert_constant.g_yes
                    THEN
                        RETURN NULL; --no shortcut in the sign off area
                    END IF;
                
                    SELECT e.flg_status
                      INTO l_status
                      FROM episode e
                     WHERE e.id_episode = i_id_episode;
                    IF l_status = pk_alert_constant.g_cancelled
                    THEN
                        -- if it is a cancelled episode, there is no such area.
                        RETURN NULL;
                    END IF;
                END IF;
                RETURN 634;
            END IF;
        END IF;
        RETURN NULL;
    END;

    /**
    * Returns the age in months.
    *
    * @param i_dt_birth             The birth date
    * @param i_age                  The age in years
    *
    * @return                       the age in months.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/09/09
    */
    FUNCTION get_age_in_months
    (
        i_dt_birth patient.dt_birth%TYPE,
        i_age      patient.age%TYPE
    ) RETURN NUMBER IS
    BEGIN
        IF i_dt_birth IS NULL
        THEN
            IF i_age IS NULL
            THEN
                RAISE g_exception;
            ELSE
                RETURN 12 * i_age;
            END IF;
        ELSE
            RETURN trunc(months_between(SYSDATE, i_dt_birth));
        END IF;
    END;

    /**
    * Returns the age in years.
    *
    * @param i_dt_birth             The birth date
    * @param i_age                  The age in years (may not exist)
    *
    * @return                       the age in years.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/09/09
    */
    FUNCTION get_age_in_years
    (
        i_dt_birth patient.dt_birth%TYPE,
        i_age      patient.age%TYPE
    ) RETURN NUMBER IS
    BEGIN
        IF i_dt_birth IS NULL
        THEN
            IF i_age IS NULL
            THEN
                RAISE g_exception;
            ELSE
                RETURN i_age;
            END IF;
        ELSE
            RETURN trunc(months_between(SYSDATE, i_dt_birth) / 12);
        END IF;
    END;

    /**
    * Returns the adult silhouette string given the gender of the patient.
    */
    FUNCTION get_adult_silhouette_str(i_gender IN patient.gender%TYPE) RETURN VARCHAR IS
    BEGIN
        IF i_gender NOT IN ('M', 'F', 'A', 'B')
        THEN
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteUndeterminedSex';
            ELSE
                RETURN 'SilhouetteU';
            END IF;
        ELSIF i_gender IN ('M', 'A')
        THEN
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteMale';
            ELSE
                RETURN 'SilhouetteM';
            END IF;
        ELSE
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteFemale';
            ELSE
                RETURN 'SilhouetteF';
            END IF;
        END IF;
    END;

    /**
    * Returns the child silhouette string given the gender of the patient.
    */
    FUNCTION get_child_silhouette_str(i_gender IN patient.gender%TYPE) RETURN VARCHAR IS
    BEGIN
        IF i_gender NOT IN ('M', 'F', 'A', 'B')
        THEN
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteUndeterminedSex';
            ELSE
                RETURN 'SilhouetteU';
            END IF;
        ELSIF i_gender IN ('M', 'A')
        THEN
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteMaleChild';
            ELSE
                RETURN 'SilhouetteCM';
            END IF;
        ELSE
            IF g_flg_origin = 'G'
            THEN
                RETURN 'SilhouetteFemaleChild';
            ELSE
                RETURN 'SilhouetteCF';
            END IF;
        
        END IF;
    END;

    /**
    * Returns the baby silhouette string.
    */
    FUNCTION get_baby_silhouette_str RETURN VARCHAR IS
    BEGIN
        IF g_flg_origin = 'G'
        THEN
            RETURN 'SilhouetteInfant';
        ELSE
            RETURN 'SilhouetteB';
        END IF;
    END;

    /**
    * Returns the silhouette of the patient given the age and the gender.
    *
    * @param i_gender                  The gender
    * @param i_age_available           If the age is available
    * @param i_lim_child_age_available If there is a limit for child age
    * @param i_lim_baby_age_available  If there is a limit for baby age
    * @param i_age_in_years            The age is years
    * @param i_lim_child_age_in_years  The limit of child age in years
    * @param i_age_in_months           The age is months
    * @param i_lim_baby_age_in_months  The limit of baby age in months
    *
    * @return                          the silhouette of the patient
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/09/09
    */
    FUNCTION get_silhouette_by_gender_age
    (
        i_gender                  IN patient.gender%TYPE,
        i_age_available           BOOLEAN,
        i_lim_child_age_available BOOLEAN,
        i_lim_baby_age_available  BOOLEAN,
        i_age_in_years            NUMBER,
        i_lim_child_age_in_years  NUMBER,
        i_age_in_months           NUMBER,
        i_lim_baby_age_in_months  NUMBER
    ) RETURN VARCHAR IS
    BEGIN
        IF NOT i_age_available
        THEN
            RETURN get_adult_silhouette_str(i_gender);
        ELSIF NOT i_lim_child_age_available
        THEN
            IF NOT i_lim_baby_age_available
            THEN
                RETURN get_adult_silhouette_str(i_gender);
            ELSIF i_age_in_months > i_lim_baby_age_in_months
            THEN
                RETURN get_adult_silhouette_str(i_gender);
            ELSE
                RETURN get_baby_silhouette_str();
            END IF;
        ELSE
            IF i_age_in_years > i_lim_child_age_in_years
            THEN
                RETURN get_adult_silhouette_str(i_gender);
            ELSIF NOT i_lim_baby_age_available
            THEN
                RETURN get_child_silhouette_str(i_gender);
            ELSE
                IF i_age_in_months > i_lim_baby_age_in_months
                THEN
                    RETURN get_child_silhouette_str(i_gender);
                ELSE
                    RETURN get_baby_silhouette_str();
                END IF;
            END IF;
        END IF;
    END;

    /**
    * Returns the silhouette of the patient 
    *
    * @param i_prof          Professional
    *
    * @return                the silhouette of the patient
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/09/09
    */
    FUNCTION get_silhouette(i_prof IN profissional) RETURN VARCHAR IS
        l_age_in_months           NUMBER;
        l_age_in_years            NUMBER;
        l_lim_child_age_in_years  NUMBER;
        l_lim_baby_age_in_months  NUMBER;
        l_age_available           BOOLEAN := TRUE;
        l_lim_child_age_available BOOLEAN := TRUE;
        l_lim_baby_age_available  BOOLEAN := TRUE;
    BEGIN
        BEGIN
            l_age_in_months := get_age_in_months(g_row.dt_birth, g_row.age);
            l_age_in_years  := get_age_in_years(g_row.dt_birth, g_row.age);
        EXCEPTION
            WHEN OTHERS THEN
                l_age_available := FALSE;
        END;
    
        BEGIN
            l_lim_child_age_in_years := to_number(pk_sysconfig.get_config('LIM_CHILD_AGE', i_prof));
            IF l_lim_child_age_in_years IS NULL
            THEN
                l_lim_child_age_available := FALSE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_lim_child_age_available := FALSE;
        END;
    
        BEGIN
            l_lim_baby_age_in_months := to_number(pk_sysconfig.get_config('LIM_BABY_AGE', i_prof));
            IF l_lim_baby_age_in_months IS NULL
            THEN
                l_lim_baby_age_available := FALSE;
            END IF;
        EXCEPTION
            WHEN OTHERS THEN
                l_lim_baby_age_available := FALSE;
        END;
    
        RETURN get_silhouette_by_gender_age(g_row.gender,
                                            l_age_available,
                                            l_lim_child_age_available,
                                            l_lim_baby_age_available,
                                            l_age_in_years,
                                            l_lim_child_age_in_years,
                                            l_age_in_months,
                                            l_lim_baby_age_in_months);
    END;

    /**
    * Returns the patient photo or silhuette.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
            l_icon_patient_hea CONSTANT VARCHAR2(40 CHAR) := 'ContactCreation';
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            check_var(i_id_patient);
                    IF pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => i_id_patient) = pk_alert_constant.g_yes
            THEN
                RETURN l_icon_patient_hea;
                else
            RETURN nvl(pk_patphoto.get_pat_photo_header(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule),
                       get_silhouette(i_prof));
                       end if;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient health plan.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_health_plan
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_patient IS NOT NULL
           OR i_id_episode IS NOT NULL
        THEN
            RETURN pk_hea_prv_aux.get_health_plan(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule);
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient number for 'Sistem Nacional de Saude'.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           episode Id
    * @param i_id_schedule          schedule Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_sns
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patient  IN patient.id_patient%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            RETURN pk_hea_prv_aux.get_sns(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule);
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient 'Regime Especial de Comparticipa??o M?dica' and 
    * 'No drug allergies' if none.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_recm_no_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            RETURN pk_hea_prv_aux.get_recm_no_allergies(i_lang, i_prof, i_id_patient);
        ELSE
            RETURN NULL;
        END IF;
    END;
    FUNCTION get_allergies
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_flg_type   IN VARCHAR2
    ) RETURN VARCHAR IS
        l_ret             pk_translation.t_desc_translation;
        l_error           t_error_out;
        l_count_allergies NUMBER;
        l_status          VARCHAR2(20 CHAR) := 'URGENT';
    BEGIN
    
        IF i_id_patient IS NOT NULL
        THEN
            l_count_allergies := pk_allergy.get_count_allergy(i_lang, i_id_patient, l_error);
            IF l_count_allergies > 0
            THEN
                IF i_flg_type = 'S'
                THEN
                    l_ret := l_status;
                ELSE
                    l_ret := pk_message.get_message(i_lang, i_prof, 'EDIS_ID_M004');
                END IF;
            ELSE
                g_error := 'GET NKDA TEXT';
                IF i_flg_type <> 'S'
                THEN
                
                    IF NOT pk_episode.get_nkda_label(i_lang, i_prof, i_id_patient, l_ret, l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
                --  RETURN pk_hea_prv_aux.get_recm_no_allergies(i_lang, i_prof, i_id_patient);
            END IF;
            RETURN l_ret;
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_allergies;

    /**
    * Check if the patient is deceased.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       True if the patient is dead. False otherwise.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION is_deceased
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            check_var(i_id_patient);
            RETURN g_row.dt_deceased IS NOT NULL;
        ELSE
            RETURN FALSE;
        END IF;
    END;

    /**
    * Returns the icon if the patient has twin brother.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_twin
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_twin person.flg_multiple_birth%TYPE;
    BEGIN
        SELECT prs.flg_multiple_birth
          INTO l_twin
          FROM patient p
          JOIN person prs
            ON p.id_person = prs.id_person
         WHERE p.id_patient = i_id_patient;
        IF l_twin IS NOT NULL
           AND l_twin <> 'NMB'
        THEN
            RETURN 'HeaderTwinsIcon';
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END get_twin;

    /**
    * Returns the icon if the patient has companion.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_companion
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        -- Not yet developed
        RETURN NULL; --'HeaderEscortIcon';
    END;

    /**
    * Returns the icon if the patient has any infectious disease.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_infect
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_headervirusicon sys_message.desc_message%TYPE;
        l_flg_infective   viewer_ehr_ea.flg_infective%TYPE;
    BEGIN
        l_headervirusicon := 'HeaderVirusIcon';
        SELECT flg_infective
          INTO l_flg_infective
          FROM viewer_ehr_ea v
         WHERE v.id_patient = i_id_patient;
    
        IF l_flg_infective = pk_alert_constant.get_yes
        THEN
            RETURN l_headervirusicon;
        END IF;
    
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * Returns the icon if the patient is victim of abuse.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_victim
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_headerviolenceicon sys_message.desc_message%TYPE;
        l_flg_exclamation    viewer_ehr_ea.flg_exclamation%TYPE;
    BEGIN
        l_headerviolenceicon := 'HeaderViolenceIcon';
    
        SELECT flg_exclamation
          INTO l_flg_exclamation
          FROM viewer_ehr_ea v
         WHERE v.id_patient = i_id_patient;
    
        IF l_flg_exclamation = pk_alert_constant.get_yes
        THEN
            RETURN l_headerviolenceicon;
        END IF;
    
        RETURN NULL;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END;

    /**
    * Returns the patient photo timestamp.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_photo_timestamp
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
        l_timestamp VARCHAR(50);
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            IF pk_patphoto.check_blob(i_id_patient) = 'N'
            THEN
                RETURN '';
            ELSE
                SELECT pk_date_utils.date_send_tsz(i_lang, pp.dt_photo_tstz, i_prof)
                  INTO l_timestamp
                  FROM pat_photo pp
                 WHERE pp.id_patient = i_id_patient;
                RETURN l_timestamp;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END;

    /**
    * Returns the patient designated provider
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The patient value
    *
    * @author   Paulo teixeira
    * @version  2.5.1.2
    * @since    2010/10/25
    */
    FUNCTION get_designated_provider_label
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        IF pk_patient.get_designated_provider(i_lang, i_prof, i_id_patient, i_id_episode) IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_message.get_message(i_lang, i_prof, 'LABEL_DESIG_PROVIDER');
        END IF;
    END;
    /**
    * Returns the patient designated provider
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    *
    * @return                       The patient value
    *
    * @author   Paulo teixeira
    * @version  2.5.1.2
    * @since    2010/10/25
    */
    FUNCTION get_designated_provider
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR IS
    BEGIN
        RETURN pk_patient.get_designated_provider(i_lang, i_prof, i_id_patient, i_id_episode);
    END;

    /********************************************************************************************** 
    * Returns if tooltip for contact patient is available
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         Y/N
    *
    * @raises
    *
    * @author                         Elisabete Bugalho
    * @since                          2011/11/15
    **********************************************************************************************/
    FUNCTION get_contact_icon_available
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            RETURN pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient);
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    END get_contact_icon_available;

    /********************************************************************************************** 
    * Returns if tooltip for contact patient is available
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         Y/N
    *
    * @raises
    *
    * @author                         Elisabete Bugalho
    * @since                          2011/11/15
    **********************************************************************************************/
    FUNCTION get_contact_icon_name
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_icon_patient_hea CONSTANT VARCHAR2(40 CHAR) := 'ContactCreation';
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            IF pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient) = pk_alert_constant.g_yes
            THEN
                RETURN l_icon_patient_hea;
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END get_contact_icon_name;

    /********************************************************************************************** 
    * Returns if tooltip for contact patient is available
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         Y/N
    *
    * @raises
    *
    * @author                         Elisabete Bugalho
    * @since                          2011/11/15
    **********************************************************************************************/
    FUNCTION get_contact_icon_info
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_icon_message CONSTANT VARCHAR2(40 CHAR) := 'COMMON_';
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            IF pk_adt.is_contact(i_lang => i_lang, i_prof => i_prof, i_patient => i_patient) = pk_alert_constant.g_yes
            THEN
                RETURN pk_message.get_message(i_lang, 'COMMON_T026');
            ELSE
                RETURN NULL;
            END IF;
        ELSE
            RETURN NULL;
        END IF;
    END get_contact_icon_info;

    /********************************************************************************************** 
    * Returns civil ID availability for patient - Return only data for doc_type 1035 (B.I.)
    * Should validate sys_config to verify if this is applicable to this market
    * 
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         Civil ID for patient
    *
    * @author                         Daniel Ferreira
    * @since                          2015/06/23
    **********************************************************************************************/
    FUNCTION get_civil_id_available
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
        l_identification_number doc_external.num_doc%TYPE;
        l_config_available      sys_config.value%TYPE;
    BEGIN
        IF i_patient IS NOT NULL
        THEN
            l_config_available := pk_sysconfig.get_config(i_code_cf => 'HEADER_CIVIL_ID_AVAILABLE', i_prof => i_prof);
        
            IF l_config_available = pk_alert_constant.g_yes
            THEN
                l_identification_number := pk_adt.get_identification_doc(i_lang       => i_lang,
                                                                         i_prof       => i_prof,
                                                                         i_id_patient => i_patient);
            
                IF l_identification_number IS NOT NULL
                THEN
                    RETURN pk_alert_constant.g_yes;
                ELSE
                    RETURN pk_alert_constant.g_no;
                END IF;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    END get_civil_id_available;

    /********************************************************************************************** 
    * Returns civil ID for patient - Return only data for doc_type 1035 (B.I.)
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         Civil ID for patient
    *
    * @author                         Daniel Ferreira
    * @since                          2015/06/23
    **********************************************************************************************/
    FUNCTION get_civil_id
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_patient IS NOT NULL
           AND (get_civil_id_available(i_lang, i_prof, i_patient) = pk_alert_constant.g_yes)
        THEN
            RETURN pk_adt.get_identification_doc(i_lang => i_lang, i_prof => i_prof, i_id_patient => i_patient);
        ELSE
            RETURN NULL;
        END IF;
    END get_civil_id;

    /**
    * Returns civil ID label - Return only data for doc_type 1035 (B.I.)
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_patient                id patient    
    *
    * @return                         String
    *
    * @author                         Ana Matos
    * @since                          2016/02/16
    */
    FUNCTION get_civil_id_label
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
        l_msg sys_message.desc_message%TYPE;
    
    BEGIN
    
        IF get_civil_id_available(i_lang, i_prof, i_patient) = pk_alert_constant.g_yes
        THEN
            l_msg := pk_message.get_message(i_lang, i_prof, 'ID_PATIENT_CIVILID') || ':';
        ELSE
            l_msg := NULL;
        END IF;
    
        RETURN l_msg;
    
    END get_civil_id_label;

    /**
    * Returns the patient value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_announced_arrival Announced arrival id
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data   
    *
    * @return                       The patient value
    *
    * @author   Joao Sa             
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile           IN profile_template.id_profile_template%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_tag                  IN header_tag.internal_name%TYPE,
        o_data_rec             OUT t_rec_header_data
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
    
        l_data_rec t_rec_header_data := t_rec_header_data(NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL,
                                                          NULL);
    
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_patient IS NULL
           AND i_id_announced_arrival IS NULL
        THEN
            RETURN FALSE;
        END IF;
        CASE i_tag
            WHEN 'PAT_NAME' THEN
                l_data_rec.text := get_name(i_lang,
                                            i_prof,
                                            i_id_patient,
                                            i_id_episode,
                                            i_id_schedule,
                                            i_id_announced_arrival);
            WHEN 'PAT_BIRTH_DT' THEN
                l_data_rec.text := get_birth_date(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
            WHEN 'PAT_PHOTO' THEN
                l_data_rec.source      := get_photo(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule);
                l_data_rec.description := get_photo_timestamp(i_lang, i_prof, i_id_patient);
            WHEN 'PAT_GENDER' THEN
                l_data_rec.text := get_gender(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
            WHEN 'PAT_AGE' THEN
                l_data_rec.text := get_age(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
            WHEN 'PAT_PREG_WEEKS' THEN
                l_data_rec.text := get_preg_weeks(i_lang, i_prof, i_id_patient);
            WHEN 'PAT_SNS' THEN
                l_data_rec.text := get_sns(i_lang, i_prof, i_id_patient, i_id_episode, i_id_schedule);
            WHEN 'PAT_RECM_NO_ALLERGY_MED' THEN
                l_data_rec.text   := get_allergies(i_lang, i_prof, i_id_patient, 'L');
                l_data_rec.status := get_allergies(i_lang, i_prof, i_id_patient, 'S');
            WHEN 'PAT_GENDER_AGE_PREG_WEEKS' THEN
                l_data_rec.text     := get_gender_age_preg_weeks(i_lang, i_prof, i_id_patient, i_id_announced_arrival);
                l_data_rec.shortcut := get_shortcut_preg_death(i_lang, i_prof, i_id_patient, i_id_episode);
            WHEN 'PAT_TWIN' THEN
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(get_twin(i_lang, i_prof, i_id_patient)); -- EMR-463
            WHEN 'PAT_COMPANION' THEN
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(get_companion(i_lang, i_prof, i_id_patient)); -- EMR-463
            WHEN 'PAT_INFECT' THEN
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(get_infect(i_lang, i_prof, i_id_patient)); -- EMR-463
            WHEN 'PAT_VICTIM' THEN
                l_data_rec.icon := pk_hea_prv_ehr.set_icon_prefix(get_victim(i_lang, i_prof, i_id_patient)); -- EMR-463
            WHEN 'PAT_DESIG_PROVIDER' THEN
                l_data_rec.text := get_designated_provider(i_lang, i_prof, i_id_patient, i_id_episode);
            WHEN 'LABEL_DESIG_PROVIDER' THEN
                l_data_rec.text := get_designated_provider_label(i_lang, i_prof, i_id_patient, i_id_episode);
            WHEN 'CONTACT_ICON_TOOLTIP_AVAILABLE' THEN
                l_data_rec.text := get_contact_icon_available(i_lang, i_prof, i_id_patient);
            WHEN 'CONTACT_ICON_TOOLTIP' THEN
                l_data_rec.text         := get_contact_icon_info(i_lang, i_prof, i_id_patient);
                l_data_rec.tooltip_text := l_data_rec.text;
                l_data_rec.tooltip_icon := get_contact_icon_name(i_lang, i_prof, i_id_patient);
            WHEN 'CIVIL_ID_TITLE' THEN
                l_data_rec.text := get_civil_id_label(i_lang, i_prof, i_id_patient);
            WHEN 'CIVIL_ID_VALUE' THEN
                l_data_rec.text := get_civil_id(i_lang, i_prof, i_id_patient);
            ELSE
                RETURN FALSE;
        END CASE;
    
        o_data_rec := l_data_rec;
        RETURN TRUE;
    END;

    /**
    * Returns the patient value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Professional Id
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_announced_arrival Announced arrival id
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The patient value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_profile           IN profile_template.id_profile_template%TYPE,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_schedule          IN schedule.id_schedule%TYPE,
        i_id_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_tag                  IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name VARCHAR2(64) := 'GET_VALUE';
        l_ret       BOOLEAN;
        l_tag       header_tag.internal_name%TYPE;
        l_data_rec  t_rec_header_data;
    BEGIN
        g_error := g_package_name || ' ' || l_func_name || ' ' || i_tag;
        pk_alertlog.log_debug(g_error);
        IF i_id_patient IS NULL
           AND i_id_announced_arrival IS NULL
        THEN
            RETURN NULL;
        END IF;
    
        -- Translate old tags to html version
        CASE i_tag
            WHEN 'CONTACT_ICON_TOOLTIP_ICON' THEN
                l_tag := 'CONTACT_ICON_TOOLTIP';
            WHEN 'CONTACT_ICON_TOOLTIP_INFO' THEN
                l_tag := 'CONTACT_ICON_TOOLTIP';
            WHEN 'PAT_PHOTO_TIMESTAMP' THEN
                l_tag := 'PAT_PHOTO';
            WHEN 'PAT_SHORTCUT_PREG_DEATH' THEN
                l_tag := 'PAT_GENDER_AGE_PREG_WEEKS';
            ELSE
                l_tag := i_tag;
        END CASE;
    
        l_ret := get_value_html(i_lang,
                                i_prof,
                                i_id_profile,
                                i_id_patient,
                                i_id_episode,
                                i_id_schedule,
                                i_id_announced_arrival,
                                l_tag,
                                l_data_rec);
    
        CASE i_tag
            WHEN 'PAT_NAME' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_HAS_ARABIC_NAME' THEN
                RETURN pk_adt.has_other_names(i_patient => i_id_patient);
            WHEN 'PAT_BIRTH_DT' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_PHOTO' THEN
                RETURN l_data_rec.source;
            WHEN 'PAT_GENDER' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_AGE' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_PREG_WEEKS' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_SNS' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_RECM_NO_ALLERGY_MED' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_GENDER_AGE_PREG_WEEKS' THEN
                RETURN l_data_rec.text;
            WHEN 'PAT_SHORTCUT_PREG_DEATH' THEN
                RETURN l_data_rec.shortcut;
            WHEN 'PAT_TWIN' THEN
                RETURN l_data_rec.icon;
            WHEN 'PAT_COMPANION' THEN
                RETURN l_data_rec.icon;
            WHEN 'PAT_INFECT' THEN
                RETURN l_data_rec.icon;
            WHEN 'PAT_VICTIM' THEN
                RETURN l_data_rec.icon;
            WHEN 'PAT_PHOTO_TIMESTAMP' THEN
                RETURN l_data_rec.description;
            WHEN 'PAT_DESIG_PROVIDER' THEN
                RETURN l_data_rec.text;
            WHEN 'LABEL_DESIG_PROVIDER' THEN
                RETURN l_data_rec.text;
            WHEN 'CONTACT_ICON_TOOLTIP_AVAILABLE' THEN
                RETURN l_data_rec.text;
            WHEN 'CONTACT_ICON_TOOLTIP_ICON' THEN
                RETURN l_data_rec.icon;
            WHEN 'CONTACT_ICON_TOOLTIP_INFO' THEN
                RETURN l_data_rec.text;
            WHEN 'CIVIL_ID_TITLE' THEN
                RETURN l_data_rec.text;
            WHEN 'CIVIL_ID_VALUE' THEN
                RETURN l_data_rec.text;
            WHEN 'CIVIL_ID_AVAILABLE' THEN
                RETURN get_civil_id_available(i_lang, i_prof, i_id_patient);
            ELSE
                RETURN NULL;
        END CASE;
        RETURN NULL;
    END;

    FUNCTION get_silhouette
    (
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR IS
    
    BEGIN
        IF i_id_patient IS NOT NULL
        THEN
            g_flg_origin := 'G';
            check_var(i_id_patient);
            RETURN get_silhouette(i_prof);
        END IF;
        RETURN NULL;
    END get_silhouette;

BEGIN

    g_package_name := pk_alertlog.who_am_i;
    pk_alertlog.log_init(g_package_name);
END;
/
