CREATE OR REPLACE PACKAGE pk_gridfilter IS

    /**
    * Package to support the creation of filter to be used in the grids
    * Jira issues: EMR-437, EMR-3039 EDIS, EMR-2532 ORIS, EMR-3204 OUTP
    * Flow to the creation
    * 1. Create a view to work as source
    * 2. Create script to call the methods below in this sequence
    *  2.1 create_custom_filter
    *  2.2 get_new_filter_alias
    *  2.3 insert_into_filter_field
    *  2.4 set_field_type
    *  2.5 assign_filter
    *  2.6 set_custom_filter_default
    *  2.7 setup_menu
    * 3. Translate the menus
    *
    * @author               Alexander Camilo
    * @version              1.0
    * @since                2018/05
    */

    -- Public variable declarations
    g_owner   VARCHAR2(0050);
    g_error   VARCHAR2(4000);
    g_package VARCHAR2(0050);

    g_discharge_active         VARCHAR2(0050);
    g_software_intern_name     VARCHAR2(0050);
    g_epis_flg_status_active   VARCHAR2(0050);
    g_epis_flg_status_inactive VARCHAR2(0050);
    g_epis_flg_status_temp     VARCHAR2(0050);
    g_epis_flg_status_canceled VARCHAR2(0050);
    g_active                   VARCHAR2(0050);

    -- FUNCTIONS
    FUNCTION get_strings
    (
        i_variable IN VARCHAR2,
        i_lang     IN language.id_language%TYPE := NULL,
        i_prof     IN profissional := NULL
    ) RETURN VARCHAR2;

    FUNCTION get_tstz
    (
        i_variable IN VARCHAR2,
        i_lang     IN language.id_language%TYPE := NULL,
        i_prof     IN profissional := NULL
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION get_filterdate
    (
        i_variable IN VARCHAR2,
        i_vc_date  IN VARCHAR2 := NULL,
        i_lang     IN NUMBER := NULL,
        i_prof     IN profissional := NULL
    ) RETURN VARCHAR2;

    FUNCTION get_reason
    (
        i_lang        IN language.id_language%TYPE,
        i_id_schedule IN schedule.id_schedule%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_config_id RETURN NUMBER;

    FUNCTION get_id_record
    (
        i_id_cust_filter IN NUMBER,
        i_filter_name    IN VARCHAR2
    ) RETURN NUMBER;

    FUNCTION get_custom_filter
    (
        i_id_cust_filter IN NUMBER,
        i_filter_name    IN VARCHAR2,
        i_rank           IN NUMBER := 0
    ) RETURN NUMBER;

    FUNCTION setup_menu
    (
        i_id_cust_filter IN NUMBER,
        i_id_config      IN NUMBER,
        i_filter_name    IN VARCHAR2,
        i_intern_menu_nm IN VARCHAR2,
        i_desc           IN VARCHAR2
    ) RETURN NUMBER;

    -- PROCEDURES
    PROCEDURE logme
    (
        funct IN VARCHAR2,
        itext IN VARCHAR2,
        i_brk IN NUMBER := 0
    );

    PROCEDURE showme;

    PROCEDURE assign_filter
    (
        p_filter_name    IN VARCHAR2,
        p_id_cust_filter IN NUMBER,
        p_id_field       IN NUMBER,
        p_descr          IN VARCHAR2,
        p_macros         IN table_varchar
    );

    PROCEDURE create_custom_filter
    (
        i_lang        IN NUMBER,
        i_filter_name IN VARCHAR2,
        i_id_cflist   IN table_number,
        i_cflist      IN table_varchar
    );

    PROCEDURE set_source_filter
    (
        i_filter_name IN VARCHAR2,
        i_screen_name IN VARCHAR2,
        i_package_nm  IN VARCHAR2 := $$PLSQL_UNIT,
        i_parse_yn    IN VARCHAR2 := 'Y'
    );

    PROCEDURE get_new_filter_alias
    (
        i_filter_name      IN VARCHAR2,
        i_id_custom_filter IN NUMBER := 0,
        i_new_alias        IN VARCHAR2
    );

    k_lf VARCHAR2(0010 CHAR) := chr(10);
    PROCEDURE setsql(i_sql IN VARCHAR2);

    PROCEDURE get_date_bounds
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_dt     IN VARCHAR2,
        o_dt_min OUT schedule_outp.dt_target_tstz%TYPE,
        o_dt_max OUT schedule_outp.dt_target_tstz%TYPE
    );

    PROCEDURE sequence_menus
    (
        i_filter_name        IN VARCHAR2,
        i_custom_filter_list IN table_number
    );

    PROCEDURE unassign_filter(i_filter_name IN VARCHAR2);
    -- Nurse Query    
    g_sql VARCHAR2(32000) := 'SELECT id_schedule     id_schedule,                    ' || k_lf ||
                             'id_episode               id_episode,                   ' || k_lf ||
                             'flg_rescheduled          flg_rescheduled,              ' || k_lf ||
                             'hour_interv_preview_send hour_interv_preview_send,     ' || k_lf ||
                             'hour_interv_preview      hour_interv_preview,          ' || k_lf ||
                             'hour_interv_start        hour_interv_start,            ' || k_lf ||
                             'desc_sched_room          desc_sched_room,              ' || k_lf ||
                             'room_status              room_status,                  ' || k_lf ||
                             'room_status_det          room_status_det,              ' || k_lf ||
                             'id_room                  id_room,                      ' || k_lf ||
                             'gender                   gender,                       ' || k_lf ||
                             'pat_age                  pat_age,                      ' || k_lf ||
                             'photo                    photo,                        ' || k_lf ||
                             'id_patient               id_patient,                   ' || k_lf ||
                             'pat_name                 pat_name,                     ' || k_lf ||
                             'name_pat_to_sort         name_pat_to_sort,             ' || k_lf ||
                             'pat_age_for_order_by     pat_age_for_order_by,         ' || k_lf ||
                             'pat_ndo                  pat_ndo,                      ' || k_lf ||
                             'pat_nd_icon              pat_nd_icon,                  ' || k_lf ||
                             'desc_intervention        desc_intervention,            ' || k_lf ||
                             'dt_server                dt_server,                    ' || k_lf ||
                             'desc_room                desc_room,                    ' || k_lf ||
                             'desc_drug_presc          desc_drug_presc,              ' || k_lf ||
                             'desc_exam_req            desc_exam_req,                ' || k_lf ||
                             'desc_analysis_req        desc_analysis_req,            ' || k_lf ||
                             'desc_analysis_exam_req   desc_analysis_exam_req,       ' || k_lf ||
                             'room_state               room_state,                   ' || k_lf ||
                             'hemo_req_status          hemo_req_status,              ' || k_lf ||
                             'material_req_status      material_req_status,          ' || k_lf ||
                             'pat_status               pat_status,                   ' || k_lf ||
                             'pat_status_det           pat_status_det,               ' || k_lf ||
                             'dt_room_status           dt_room_status,               ' || k_lf ||
                             'dt_pat_status            dt_pat_status,                ' || k_lf ||
                             'flg_surg_status          flg_surg_status,              ' || k_lf ||
                             'resp_icons               resp_icons,                   ' || k_lf ||
                             'prof_follow_add          prof_follow_add,              ' || k_lf ||
                             'prof_follow_remove       prof_follow_remove,           ' || k_lf ||
                             'desc_diagnosis           desc_diagnosis,               ' || k_lf ||
                             'prof_name                prof_name,                    ' || k_lf ||
                             'desc_obs                 desc_obs,                     ' || k_lf ||
                             'team_number              team_number,                  ' || k_lf ||
                             'desc_team                desc_team,                    ' || k_lf ||
                             'name_prof_tooltip        name_prof_tooltip             ' || k_lf ||
                             'FROM v_surgridnurse t                                  ' || k_lf ||
                             'JOIN (SELECT /*+ OPT_ESTIMATE(TABLE p ROWS=1) */ p.id_patient, p.position ' || k_lf ||
                             '        FROM TABLE(pk_adt.get_patients(:l_lang,  profissional(:l_prof_id,:l_institution,:l_software), :VALUE_01)) p ) ps ' || k_lf ||
                             '  ON ps.id_patient = t.id_patient ' || k_lf ||
                             'WHERE t.dt_server BETWEEN :l_dt_min AND :l_dt_max';

END pk_gridfilter;
/
