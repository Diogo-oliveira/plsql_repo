CREATE OR REPLACE PACKAGE pk_filter_teams IS

    SUBTYPE t_big_byte IS pk_types.t_big_byte;
    SUBTYPE t_huge_byte IS pk_types.t_huge_byte;
    SUBTYPE t_hug_byte IS pk_types.t_huge_byte;

    SUBTYPE t_big_char IS pk_types.t_big_char;
    SUBTYPE t_med_char IS pk_types.t_med_char;
    SUBTYPE t_low_char IS pk_types.t_low_char;
    SUBTYPE t_flg_char IS pk_types.t_flg_char;

    SUBTYPE t_timestamp IS pk_types.t_timestamp;

    SUBTYPE t_category IS pk_types.t_category;

    SUBTYPE t_msg_char IS pk_types.t_msg_char;

    SUBTYPE t_low_num IS pk_types.t_low_num;
    SUBTYPE t_med_num IS pk_types.t_med_num;
    SUBTYPE t_big_num IS pk_types.t_big_num;
    SUBTYPE t_pls_num IS PLS_INTEGER;

    k_list_prof_departments        CONSTANT t_low_char := 'PROF_DEPARTMENTS';
    k_list_pha_cars                CONSTANT t_low_char := 'PHA_CARS';
    k_list_pha_depts               CONSTANT t_low_char := 'PHA_DEPTS';
    k_list_doc_archive             CONSTANT t_low_char := 'DOC_ARCHIVE';
    k_list_lab_tests_origin        CONSTANT t_low_char := 'LAB_TESTS_ORIGIN';
    k_list_imaging_exams_origin    CONSTANT t_low_char := 'IMAGING_EXAMS_ORIGIN';
    k_list_other_exams_origin      CONSTANT t_low_char := 'OTHER_EXAMS_ORIGIN';
    k_list_rehab_treats_appoint    CONSTANT t_low_char := 'REHAB_TREATS_AND_APPOINT';
    k_list_paramedic_appont        CONSTANT t_low_char := 'PARAMEDIC_APPOINTMENTS';
    k_list_rehab_appont            CONSTANT t_low_char := 'REHAB_APPOINTMENTS';
    k_list_prof_cs                 CONSTANT t_low_char := 'PROF_CLINICAL_SERVICE';
    k_list_p1_type_request         CONSTANT t_low_char := 'P1_TYPE_REQUEST';
    k_list_mcdt_lab_codification   CONSTANT t_low_char := 'LAB_CODIFICATION_LOV';
    k_list_mcdt_exam_codification  CONSTANT t_low_char := 'EXAM_CODIFICATION_LOV';
    k_list_mcdt_proc_codification  CONSTANT t_low_char := 'PROC_CODIFICATION_LOV';
    k_list_mcdt_rehab_codification CONSTANT t_low_char := 'REHAB_CODIFICATION_LOV';
    k_list_prof_dept_oris          CONSTANT t_low_char := 'PROF_DEPT_ORIS';
    k_list_prof_dept_outp          CONSTANT t_low_char := 'PROF_DEPT_OUTP';
    k_list_prof_dept_inp           CONSTANT t_low_char := 'PROF_DEPT_INP';
    k_list_prof_dept_edis          CONSTANT t_low_char := 'PROF_DEPT_EDIS';
    k_list_prof_dept               CONSTANT t_low_char := 'PROF_DEPT';
    k_list_department_type         CONSTANT t_low_char := 'DEPARTMENT_TYPE';
    k_list_order_sets              CONSTANT t_low_char := 'ORDER_SETS_BY_TYPE';
    k_list_complaint_os_clin_serv  CONSTANT t_low_char := 'COMPLAINT_OS_CLINICAL_SERVICE_LOV';
    ------------------------------------------------
    k_menu_pharm_concluded_disp CONSTANT t_low_char := 'RECENTLY_CONCLUDED_DISPENSES';
    k_menu_active_medication    CONSTANT t_low_char := 'ACTIVE_MEDICATION';

    /********************************************************************************************
    * Returns the list of departments to which a professional belongs
    *
    * @param  i_lang          Language id
    * @param  i_prof          Professional
    *
    * @return t_tbl_filter_list        list of values
    *
    * @author  rui.mendonca
    * @version 2.6.5.2
    * @since   01/06/2016
    ********************************************************************************************/
    FUNCTION get_prof_departments
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_grp_identifier IN VARCHAR DEFAULT k_list_prof_departments
    ) RETURN t_tbl_filter_list;

    /********************************************************************************************
    * Returns the list of departments based on professional and flg_type
    *
    * @param  i_lang          Language id
    * @param  i_prof          Professional
    *
    * @return t_tbl_filter_list        list of values
    *
    * @author  Pedro Teixeira
    * @since   27/04/2022
    ********************************************************************************************/
    FUNCTION get_prof_dept
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_grp_identifier      IN VARCHAR,
        i_department_flg_type IN department.flg_type%TYPE DEFAULT NULL,
        i_flg_use_all         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_tbl_par_name        IN table_varchar DEFAULT table_varchar(),
        i_tbl_par_value       IN table_varchar DEFAULT table_varchar()
    ) RETURN t_tbl_filter_list;

    FUNCTION get_pha_cars
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION get_pha_depts
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION get_doc_archive_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION get_exams_origin_list
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_origin IN VARCHAR2
    ) RETURN t_tbl_filter_list;

    FUNCTION get_rehab_origin_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION get_paramedic_appoint_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    FUNCTION get_rehab_appoint_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list;

    /********************************************************************************************
    * Returns the list of departments to which a professional belongs
    *
    * @param  i_lang          Language id
    * @param  i_prof          Professional
    *
    * @return t_tbl_filter_list        list of values
    *
    * @author  Elisabete Bugalho
    * @version 2.8.2.0
    * @since   09/2020
    ********************************************************************************************/
    FUNCTION get_clinical_services
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_p1_type_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_mcdt_exam_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_mcdt_proc_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_mcdt_rehab_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_mcdt_lab_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_desc_menu_sample
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * @author  Pedro Teixeira
    * @since   27/05/2022
    ********************************************************************************************/
    FUNCTION get_desc_concluded_disp
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * @author  Sofia Mendes
    * @since   21/06/2022
    ********************************************************************************************/
    FUNCTION get_desc_active_medication
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2;

    --***********************************************************
    FUNCTION get_departments
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_grp  IN VARCHAR2
    ) RETURN t_tbl_filter_list;

    --***********************************************************
    FUNCTION get_alert_group
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_grp  IN VARCHAR2
    ) RETURN t_tbl_filter_list;

    FUNCTION get_order_sets_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list;

    FUNCTION get_complaint_os_clin_serv_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_order_set  IN order_set.id_order_set%TYPE
    ) RETURN t_tbl_filter_list;

END pk_filter_teams;
/
