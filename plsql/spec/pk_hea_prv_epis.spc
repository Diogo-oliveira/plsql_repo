CREATE OR REPLACE PACKAGE pk_hea_prv_epis IS

    -- Log initialization.
    /* Stores log error messages. */
    g_error VARCHAR2(4000);

    /* Stores the package name. */
    g_package_name VARCHAR2(32);
    /* Message code for an unexpected exception. */
    g_msg_common_m001 CONSTANT VARCHAR2(11) := 'COMMON_M001';

    g_found BOOLEAN;
    g_exception EXCEPTION;

    g_row_e  episode%ROWTYPE;
    g_row_ei epis_info%ROWTYPE;
    g_row_s  schedule%ROWTYPE;
    g_row_so schedule_outp%ROWTYPE;
    g_row_sr schedule_sr%ROWTYPE;
    g_row_sc sch_resource%ROWTYPE;
    g_row_sg sch_group%ROWTYPE;

    g_lang                  language.id_language%TYPE;
    g_prof                  profissional;
    g_compl_diag            VARCHAR2(32767);
    g_info_adic             VARCHAR2(32767);
    g_desc_anamnesis        VARCHAR2(32767);
    g_anamnesis_prof        VARCHAR2(32767);
    g_desc_triage           VARCHAR2(32767);
    g_triage_prof           VARCHAR2(32767);
    g_compl_pain            VARCHAR2(32767);
    g_dt_register           episode.dt_begin_tstz%TYPE;
    g_dt_first              epis_info.dt_first_obs_tstz%TYPE;
    g_epis_number_available VARCHAR2(1 CHAR);
    g_epis_number           VARCHAR2(32767);
    g_clin_record           VARCHAR2(32767);
    g_disp_date             VARCHAR2(32767);
    g_disp_label            VARCHAR2(32767);
    g_surg_prof             VARCHAR2(32767);
    g_surg_prof_spec_inst   VARCHAR2(32767);
    g_ehr_access            VARCHAR2(1);
    g_id_child_episode      episode.id_episode%TYPE;

    g_hea_epis_conf CONSTANT sys_config.id_sys_config%TYPE := 'HEA_EPIS_CONF';
    g_retval         BOOLEAN;
    g_cat_type_nurse category.flg_type%TYPE := 'N';

    g_epis_nhs_info        VARCHAR2(32767);
    g_epis_nhs_info_style  VARCHAR2(32767);
    g_epis_nhs_info_status VARCHAR2(32);

    g_epis_nhs_number            VARCHAR2(32767);
    g_epis_nhs_number_style      VARCHAR2(32767);
    g_epis_nhs_number_status     VARCHAR2(32);
    g_epis_health_plan_info      VARCHAR2(32767);
    g_ehp_info_style             VARCHAR2(32767);
    g_ehp_info_status            VARCHAR2(32);
    g_epis_nhs_tooltip_info      VARCHAR2(32767);
    g_epis_nhs_tt_info_style     VARCHAR2(32767);
    g_epis_nhs_tt_info_status    VARCHAR2(32);
    g_ehp_tooltip_info           VARCHAR2(32767);
    g_ehp_tooltip_info_style     VARCHAR2(32767);
    g_ehp_tooltip_info_status    VARCHAR2(32767);
    g_epis_health_plan_number    VARCHAR2(32767);
    g_ehp_number_style           VARCHAR2(32767);
    g_ehp_number_status          VARCHAR2(32);
    g_epis_health_plan_available VARCHAR2(32767);

    g_pat_ges_available   VARCHAR2(1 CHAR);
    g_pat_ges_pathologies table_varchar;

    g_unverified CONSTANT VARCHAR2(10) := 'UNVERIFIED';
    g_valid      CONSTANT VARCHAR2(5) := 'VALID';
    g_invalid    CONSTANT VARCHAR2(7) := 'INVALID';

    /**
    * Resets all the variables.
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    PROCEDURE reset_var;

    /**
    * Returns the label for 'Process'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_process
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Episode'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_epis
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for EDIS 'Location'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Room time'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_room_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Total time'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_total_time
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Location'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_location_service
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Schedule'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_schedule
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Register'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_register
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for 'Waiting'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_waiting
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the label for ORIS 'Estimated duration'
    *
    * @param i_lang                Language Id
    * @param i_prof                Professional Id
    *
    * @return                      The label
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_surg_est_dur
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;

    /**
    * Returns the episode value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_child_episode     Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_schedule          Schedule Id
    * @param i_id_epis_type         Episode type Id
    * @param i_id_institution       Institution Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    * @param o_data_rec             Tag's data
    *
    * @return                       The episode value
    *
    * @author   Joao Sa
    * @version  2.7.1
    * @since    2017/03/08
    */
    FUNCTION get_value_html
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_child_episode  IN episode.id_episode%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_flg_area          IN sys_application_area.flg_area%TYPE,
        i_tag               IN header_tag.internal_name%TYPE,
        o_data_rec          OUT t_rec_header_data
    ) RETURN BOOLEAN;

    /**
    * Returns the episode value for the tag given as parameter.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_patient           Patient Id
    * @param i_id_episode           Episode Id
    * @param i_id_child_episode     Child Episode Id: to be used when the header is shown info about the parent and the child episode
    * @param i_id_schedule          Schedule Id
    * @param i_id_epis_type         Episode type Id
    * @param i_id_institution       Institution Id
    * @param i_flg_area             System application area flag
    * @param i_tag                  Tag to be replaced
    *
    * @return                       The episode value
    *
    * @author   Eduardo Lourenco
    * @version  2.5
    * @since    2009/03/04
    */
    FUNCTION get_value
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_child_episode  IN episode.id_episode%TYPE,
        i_id_schedule       IN schedule.id_schedule%TYPE,
        i_id_epis_type      IN epis_type.id_epis_type%TYPE,
        i_id_pat_identifier IN pat_identifier.id_pat_identifier%TYPE,
        i_flg_area          IN sys_application_area.flg_area%TYPE,
        i_tag               IN header_tag.internal_name%TYPE
    ) RETURN VARCHAR2;

    /**
    * Returns the episode admission date.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param o_adm_date             Admissiondate
    *
    * @return                       boolean
    *
    * @author   Rui Spratley
    * @version  2.5.1
    * @since    2010/09/03
    */
    --This function was included in spec for reports use

    FUNCTION get_admission_date_report
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_id_schedule  IN schedule.id_schedule%TYPE,
        o_adm_date     OUT TIMESTAMP WITH LOCAL TIME ZONE,
        o_adm_date_str OUT VARCHAR2
    ) RETURN BOOLEAN;

    /**
    * Returns the episode's responsibles.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_patient           Schedule Id
    * @param o_resp_doctor          Responsible doctor
    * @param o_resp_doctor_spec     Responsible doctor's specialty
    * @param o_resp_nurse           Responsible nurse
    * @param o_resp_nurse_spec      Responsible nurse's specialty
    *
    * @return                       boolean
    *
    * @author   Goncalo Almeida
    * @version  2.6.1
    * @since    2011/07/01
    */
    FUNCTION get_epis_responsibles
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_patient       IN patient.id_patient%TYPE,
        o_resp_doctor      OUT VARCHAR,
        o_resp_doctor_spec OUT VARCHAR,
        o_resp_nurse       OUT VARCHAR,
        o_resp_nurse_spec  OUT VARCHAR,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_resp_doctor
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR;
	
	 /**
    * Returns the episode complaint or diagnoses.
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param i_id_schedule          Schedule Id
    * @param i_flg_area             System application area flag
    * @param o_diagnosis            the diagnostic or chief complaint
    *
    * @return                       The episode value
    *
    * @author   Fábio Martins
    * @version  2.7
    * @since    2018/02/21
    */
    FUNCTION get_diagnosis_or_complaint
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE,
        i_flg_area    IN sys_application_area.flg_area%TYPE,
        o_diagnosis   OUT VARCHAR,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns the episode location (new).
    *
    * @param i_lang                 Language Id
    * @param i_prof                 Logged professional
    * @param i_id_episode           Episode Id
    * @param o_location             Location
    *
    * @return                       true or false
    *
    * @author   Fábio Martins
    * @version  2.7
    * @since    2018/02/22
    */
    FUNCTION get_location_new
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        o_location   OUT VARCHAR
    ) RETURN BOOLEAN;

    FUNCTION get_admission_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

END pk_hea_prv_epis;
/
