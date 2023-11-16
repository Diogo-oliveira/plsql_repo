/*-- Last Change Revision: $Rev: 2014043 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-05-11 12:02:10 +0100 (qua, 11 mai 2022) $*/

CREATE OR REPLACE PACKAGE pk_cdoc_filters IS

    -- ********************************************************************
    -- ********************************************************************
    -- ********************************************************************
    FUNCTION transform
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    FUNCTION transform_clob
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN CLOB;

    /**
    * Initialize parameters to be used in the grid query of AMB
    *
    * @param i_context_ids  identifier used in array of context
    * @param i_context_keys Content of the array context
    * @param i_context_vals Values  of the array context
    * @param i_name         variable for bind in the query
    * @param o_vc2          returned value if varchar
    * @param o_num          returned value if number
    * @param o_id           returned value if ID
    * @param o_tstz         returned value if date
    *
    * @author               Carlos Ferreira
    * @version              1.0
    * @since                2018/10/08
    */
    PROCEDURE init_params_amb
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_edis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_oris
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_sws
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    /**
    * Get reasons for given id_episode. Result concatenate in one line.
    *
    * @param i_lang         id_lang to use for translation
    * @param i_episode      id_episode to process
    *
    * @author               Carlos Ferreira
    * @version              1.0
    * @since                2018/10/08
    */

    FUNCTION get_reason
    (
        i_lang    IN NUMBER,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION check_is_my_patient
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_filter_name      IN VARCHAR2,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_schedule      IN epis_info.id_schedule%TYPE,
        i_prof_cat_type    IN category.flg_type%TYPE,
        i_handoff_type     IN VARCHAR2,
        i_id_prof_schedule IN sch_resource.id_professional%TYPE,
        i_flg_leader       IN VARCHAR2
    ) RETURN VARCHAR2;

    PROCEDURE set_context_dates
    (
        i_dt_min IN VARCHAR2,
        i_amount IN NUMBER
    );

    PROCEDURE init_params_admin
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );    

    PROCEDURE init_params_inactive_pat_edis
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_inactive_pat_clin
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_hhc_req
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE init_params_hhc_app
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION do_prof_in_charge
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    PROCEDURE init_params_epis_unpayed
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    --****************************************
    FUNCTION get_disch_time_sort
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_flg_status_disch IN VARCHAR2,
        i_flag             IN VARCHAR2,
        i_dt               IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_discharge_notes
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2;

    --*****************************
    FUNCTION get_status_string
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    --****************************************
    FUNCTION get_disch_time
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_flg_status_disch IN VARCHAR2,
        i_flag             IN VARCHAR2,
        i_dt               IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    -- ***********************************
    FUNCTION get_prof_dcs_allocated
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN table_number;

    FUNCTION get_admission_reas_dest(i_prof IN profissional) RETURN table_number;

    FUNCTION get_admission_time
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    PROCEDURE init_par_followup
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_admission_time_sort
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_transfer_status_icon_sort
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE init_par_cosign
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_no_show(i_dt IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR2;

END pk_cdoc_filters;
/
