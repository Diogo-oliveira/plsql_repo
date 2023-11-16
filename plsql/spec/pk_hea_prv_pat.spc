/*-- Last Change Revision: $Rev: 1806730 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2017-11-14 16:45:58 +0000 (ter, 14 nov 2017) $*/

CREATE OR REPLACE PACKAGE pk_hea_prv_pat IS

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    g_inactive_pat CONSTANT VARCHAR2(1) := 'I';

    FUNCTION get_silhouette
    (
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR;

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;
    g_row patient%ROWTYPE := NULL;

    CURSOR ann_arr_cur IS
        SELECT a.id_announced_arrival, p.id_pre_hosp_accident, p.name, p.gender, p.age, p.dt_birth, pat.dt_deceased
          FROM announced_arrival a
         INNER JOIN episode e
            ON e.id_episode = a.id_episode
         INNER JOIN patient pat
            ON pat.id_patient = e.id_patient
         INNER JOIN pre_hosp_accident p
            ON a.id_pre_hosp_accident = p.id_pre_hosp_accident;
    TYPE ann_arr_pat_type IS TABLE OF ann_arr_cur%ROWTYPE;
    g_ann_arr_pat ann_arr_pat_type;
END;
/
