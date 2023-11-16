CREATE OR REPLACE PACKAGE pk_backoffice AS

    g_sysdate DATE;
    g_error   VARCHAR2(2000);
    g_found   BOOLEAN;

    g_exam_freq   exam_dep_clin_serv.flg_type%TYPE;
    g_diag_freq   diagnosis_dep_clin_serv.flg_type%TYPE;
    g_drug_freq   drug_dep_clin_serv.flg_type%TYPE;
    g_interv_freq interv_dep_clin_serv.flg_type%TYPE;
    g_flg_avail   institution.flg_available%TYPE;
    g_active      prof_institution.flg_state%TYPE;

    g_cat_type_doc  category.flg_type%TYPE;
    g_cat_type_nurs category.flg_type%TYPE;
    g_cat_type_tec  category.flg_type%TYPE;
    g_cat_type_adm  category.flg_type%TYPE;
    g_cat_type_farm category.flg_type%TYPE;
    g_cat_type_oth  category.flg_type%TYPE;

    g_status_pdcs_s prof_dep_clin_serv.flg_status%TYPE;

    g_selected              VARCHAR2(1);
    g_reopen_epis           sys_config.value%TYPE;
    g_flg_available         VARCHAR2(1);
    g_exam_avail            exam.flg_available%TYPE;
    g_prof_flg_state_active professional.flg_state%TYPE;

    g_alert_institution institution.id_institution%TYPE;
    g_id_portugal       country.id_country%TYPE;

    g_profile_template_available  profile_template.flg_available%TYPE;
    g_profile_template_cost_avlbl VARCHAR2(1);
    g_profile_template_desc_avlbl profile_template_desc.flg_available%TYPE;
    g_product_purchasable_avlbl   VARCHAR2(1);
    g_product_purch_cost_avlbl    VARCHAR2(1);
    g_product_purch_type          VARCHAR2(1);
    g_profile_template_pay_type   VARCHAR2(1);
    g_profile_template_free_type  VARCHAR2(1);
    g_profile_template_type       VARCHAR2(1);
    g_license_available           VARCHAR2(1);
    g_license_cancel              VARCHAR2(1);
    g_license_waiting             VARCHAR2(1);
    g_trans_status_available      VARCHAR2(1);
    g_payment_future_yes          VARCHAR2(1);
    g_payment_future_no           VARCHAR2(1);
    g_flg_not_setupfee            VARCHAR2(1);

    g_trans_status_waiting VARCHAR2(1);
    g_trans_status_avlbl   VARCHAR2(1);

    g_flg_icon_active   VARCHAR2(1);
    g_flg_icon_inactive VARCHAR2(1);

    g_currency_available currency.flg_available%TYPE;

    g_exception EXCEPTION;

    g_bulk_fetch_rows NUMBER;

    g_flg_montlhy_payment    VARCHAR2(30);
    g_flg_biannually_payment VARCHAR2(30);
    g_flg_annually_payment   VARCHAR2(30);

    g_montlhy_payment    NUMBER;
    g_biannually_payment NUMBER;
    g_annually_payment   NUMBER;

    g_flg_nonclinical profile_template.flg_group%TYPE;

    g_status_i VARCHAR2(1);
    g_status_a VARCHAR2(1);
    g_status_s VARCHAR2(1);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_all CONSTANT NUMBER(2) := -10;

    g_todosprofs CONSTANT VARCHAR2(8) := 'SCH_T209';

    g_series_active        VARCHAR2(1);
    g_series_suspended     VARCHAR2(1);
    g_series_inactive      VARCHAR2(1);
    g_series_edit          VARCHAR2(1);
    g_series_no            VARCHAR2(1);
    g_series_pending       VARCHAR2(1);
    g_series_concluded     VARCHAR2(1);
    g_series_can_desc      VARCHAR2(1);
    g_series_can           VARCHAR2(1);
    g_series_desc          VARCHAR2(1);
    g_series_available     VARCHAR2(1);
    g_series_edit_msg      VARCHAR2(18);
    g_series_na_msg        VARCHAR2(18);
    g_series_from_msg      VARCHAR2(18);
    g_series_to_msg        VARCHAR2(18);
    g_series_avai_perc     VARCHAR2(25);
    g_series_mask          VARCHAR2(18);
    g_series_domain        VARCHAR2(17);
    g_series_not_valid_msg VARCHAR(18);

    g_missing_translation CONSTANT VARCHAR2(25) := 'Missing translation for: ';

    g_package_owner VARCHAR2(10) := 'ALERT';
    g_package_name  VARCHAR2(30) := 'PK_BACKOFFICE';

    --Accounts
    g_account_type_p      accounts.flg_type%TYPE;
    g_account_type_i      accounts.flg_type%TYPE;
    g_account_type_b      accounts.flg_type%TYPE;
    g_account_multichoice accounts.fill_type%TYPE;
    g_account_prof_adeli  accounts.id_account%TYPE;
    g_account_prof_drass  accounts.id_account%TYPE;
    g_account_prof_stud   accounts.id_account%TYPE;
    g_account_inst_finess accounts.id_account%TYPE;
    g_account_inst_siren  accounts.id_account%TYPE;
    g_account_inst_siret  accounts.id_account%TYPE;
    g_account_inst_rpps   accounts.id_account%TYPE;

    -- professional history auxiliar constants
    g_prof_hist_oper_c CONSTANT professional_hist.operation_type%TYPE := 'C';
    g_prof_hist_oper_r CONSTANT professional_hist.operation_type%TYPE := 'R';
    g_prof_hist_oper_u CONSTANT professional_hist.operation_type%TYPE := 'U';

    g_config_bleep_timeout CONSTANT sys_config.id_sys_config%TYPE := 'BLEEP_TIMEOUT';

    g_config_contact      CONSTANT VARCHAR2(0200 CHAR) := 'PROF_CONTACT_VALIDATIONS';
    g_config_phone_length CONSTANT VARCHAR2(0200 CHAR) := 'PROF_PHONE_LENGTH';
    g_config_email_regexp CONSTANT VARCHAR2(0200 CHAR) := 'PROF_EMAIL_REGEXP';

    g_field_separator CONSTANT VARCHAR2(1 CHAR) := '+';

    TYPE t_rec_serie IS RECORD(
        id_series       series.id_series%TYPE,
        starting_number series.starting_number%TYPE,
        current_number  pat_pregnancy_code.code_number%TYPE,
        ending_number   series.ending_number%TYPE,
        series_year     series.series_year%TYPE,
        mask            sys_config.value%TYPE,
        code_state      geo_state.code_state%TYPE);

    FUNCTION get_prof_template
    (
        i_lang     IN language.id_language%TYPE,
        i_flg_type IN profile_template.flg_type%TYPE,
        i_prof_adm IN profissional,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_template_det
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_detail  OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professional_state_list
    (
        i_lang       IN language.id_language%TYPE,
        o_prof_state OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof_adm IN profissional,
        o_list     OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_software_list
    (
        i_lang  IN language.id_language%TYPE,
        i_inst  IN institution.id_institution%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_info           OUT pk_types.cursor_type,
        o_dep            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_clin_serv
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        i_id_dep  IN department.id_department%TYPE,
        o_dcs     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_cat           IN category.id_category%TYPE,
        i_num_mecan        IN prof_institution.num_mecan%TYPE,
        i_id_language      IN language.id_language%TYPE,
        i_state            IN prof_institution.flg_state%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        i_cat_sub          IN category_sub.id_category_sub%TYPE,
        i_num_order        IN professional.num_order%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_institution_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_institution.id_professional%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_flg_state       IN prof_institution.flg_state%TYPE,
        i_num_mecan       IN prof_institution.num_mecan%TYPE,
        o_flg_state       OUT prof_institution.flg_state%TYPE,
        o_icon            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_template_list
    (
        i_lang        IN language.id_language%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_inst        IN prof_profile_template.id_institution%TYPE,
        i_soft        IN prof_profile_template.id_software%TYPE,
        o_avail_templ OUT pk_types.cursor_type,
        o_sel_templ   OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_template
    (
        i_lang    IN language.id_language%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        i_inst    IN prof_profile_template.id_institution%TYPE,
        i_soft    IN prof_profile_template.id_software%TYPE,
        o_templ   OUT pk_types.cursor_type,
        o_soft    OUT prof_profile_template.id_software%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_template_list
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_inst             IN table_number,
        i_soft             IN table_number,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_templ            IN table_number,
        i_commit_at_end    IN BOOLEAN,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_instit_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN professional.id_professional%TYPE,
        o_info  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_photo
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_photo OUT VARCHAR2,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_cat_sub_list
    (
        i_lang  IN language.id_language%TYPE,
        i_cat   IN category.id_category%TYPE,
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_service
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        i_dep   IN dept.id_dept%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_functionality
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Aplication Functionalities filtered by professional category
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_software           Software ID
    * @param i_id_professional       Professional ID
    * @param i_id_professional       Institution ID
    * @param o_list                  Cursor with funcionalities list
    * @param o_error                 Error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2010/01/04
    ********************************************************************************************/
    FUNCTION get_soft_functionality
    (
        i_lang            IN language.id_language%TYPE,
        i_id_software     IN sys_functionality.id_software%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_func
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_func.id_professional%TYPE,
        i_id_institution  IN prof_func.id_institution%TYPE,
        i_id_software     IN software.id_software%TYPE,
        o_prof_func       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_func
    (
        i_lang            IN language.id_language%TYPE DEFAULT NULL,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_args            IN table_table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_func_all
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN prof_func.id_professional%TYPE,
        i_institution     IN table_number,
        i_func            IN table_number,
        i_change          IN table_varchar,
        i_commit_at_end   IN BOOLEAN,
        o_id_prof_func    OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_title_list
    (
        i_lang  IN language.id_language%TYPE,
        o_title OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_desc           IN VARCHAR2,
        i_flg_type       IN institution.flg_type%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_barcode        IN institution.barcode%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_location       IN institution.location%TYPE,
        i_ine_location   IN institution.ine_location%TYPE,
        i_id_parent      IN institution.id_parent%TYPE,
        i_phone_number   IN institution.phone_number%TYPE,
        i_ext_code       IN institution.ext_code%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_institution    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_list
    (
        i_lang      IN language.id_language%TYPE,
        i_flg_type  IN institution.flg_type%TYPE,
        o_inst_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_institution_state
    (
        i_lang          IN language.id_language%TYPE,
        i_id_insitution IN institution.id_institution%TYPE,
        i_flg_state     IN institution.flg_available%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dept
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN dept.id_dept%TYPE,
        i_desc           IN VARCHAR2,
        i_id_institution IN dept.id_institution%TYPE,
        i_abbreviation   IN dept.abbreviation%TYPE,
        i_software       IN table_number,
        i_change         IN table_varchar,
        i_def_priority   IN dept.flg_priority%TYPE,
        i_collection_by  IN dept.flg_collection_by%TYPE,
        o_id_dept        OUT dept.id_dept%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        i_search         IN VARCHAR2,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Department Software
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_dept               Department ID
    * @param i_id_institution        Institution ID
    * @param o_software_desc         Associated softwares description 
    * @param o_software_list         Software list
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/05
    ********************************************************************************************/
    FUNCTION get_dept_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN dept.id_dept%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        o_software_desc  OUT VARCHAR2,
        o_software_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_department
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        o_department    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the information for a given service
    *
    * @param      i_lang                     Language identification
    * @param      i_id_department            Department identification
    * @param      o_department               Cursor with Department information
    * @param      o_error                    Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Orlando Antunes
    * @version                         2.6.0.3
    * @since                           2010/04/28
    **********************************************************************************************/
    FUNCTION get_department
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE,
        o_department    OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Institution Service OR Update Institution Service Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_DEPARTMENT                      Service identification
    * @param      I_ID_INSTITUTION                     Institution identification
    * @param      I_DESC                               Service description
    * @param      I_ABBREVIATION                       Abreviation
    * @param      I_FLG_TYPE                           Type: C - Outpatient, U - Emergency department, I - Inpatient, S - Operating Room, 
                                                             A - Analysis lab., P - Clinical patalogy lab., T - Pathological anatomy lab, 
                                                             R - Radiology, F - Pharmacy. 
                                                             It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    * @param      I_ID_DEPT                            Daepartment identification
    * @param      I_FLG_DEFAULT                        Default department: Y - Yes; N - No
    * @param      O_ID_DEPARTMENT                      Department identification
    * @param      O_ERROR                              Error
    *
    * @value       I_FLG_TYPE                          {*} 'C' Outpatient {*} 'U' Emergency department {*} 'I' Inpatient {*} 'S' Operating Room 
                                                       {*} 'A' Analysis lab. {*} 'P' Clinical patalogy lab. {*} 'T' Pathological anatomy lab 
                                                       {*} 'R' Radiology {*} 'F' Pharmacy. It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    *
    * @value      I_FLG_DEFAULT                        {*} 'Y' Yes {*} 'N' No                                     
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/03/21
    */
    FUNCTION set_department
    (
        i_lang               IN language.id_language%TYPE,
        i_id_department      IN department.id_department%TYPE,
        i_id_institution     IN department.id_institution%TYPE,
        i_desc               IN VARCHAR2,
        i_abbreviation       IN department.abbreviation%TYPE,
        i_flg_type           IN department.flg_type%TYPE,
        i_id_dept            IN department.id_dept%TYPE,
        i_flg_default        IN department.flg_default%TYPE,
        i_def_priority       IN department.flg_priority%TYPE,
        i_collection_by      IN department.flg_collection_by%TYPE,
        i_floors_institution IN table_number,
        i_change             IN table_varchar,
        o_id_department      OUT department.id_department%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Institution Service OR Update Institution Service Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_DEPARTMENT                      Service identification
    * @param      I_ID_INSTITUTION                     Institution identification
    * @param      I_DESC                               Service description
    * @param      I_ABBREVIATION                       Abreviation
    * @param      I_FLG_TYPE                           Type: C - Outpatient, U - Emergency department, I - Inpatient, S - Operating Room, 
                                                             A - Analysis lab., P - Clinical patalogy lab., T - Pathological anatomy lab, 
                                                             R - Radiology, F - Pharmacy. 
                                                             It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    * @param      I_ID_DEPT                            Daepartment identification
    * @param      I_FLG_DEFAULT                        Default department: Y - Yes; N - No
    * @param      O_ID_DEPARTMENT                      Department identification
    * @param      O_ERROR                              Error
    *
    * @value       I_FLG_TYPE                          {*} 'C' Outpatient {*} 'U' Emergency department {*} 'I' Inpatient {*} 'S' Operating Room 
                                                       {*} 'A' Analysis lab. {*} 'P' Clinical patalogy lab. {*} 'T' Pathological anatomy lab 
                                                       {*} 'R' Radiology {*} 'F' Pharmacy. It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    *
    * @value      I_FLG_DEFAULT                        {*} 'Y' Yes {*} 'N' No                                     
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/03/21
    */
    FUNCTION set_department
    (
        i_lang               IN language.id_language%TYPE,
        i_id_department      IN department.id_department%TYPE,
        i_id_institution     IN department.id_institution%TYPE,
        i_desc               IN VARCHAR2,
        i_abbreviation       IN department.abbreviation%TYPE,
        i_flg_type           IN department.flg_type%TYPE,
        i_id_dept            IN department.id_dept%TYPE,
        i_flg_default        IN department.flg_default%TYPE,
        i_def_priority       IN department.flg_priority%TYPE,
        i_collection_by      IN department.flg_collection_by%TYPE,
        i_floors_institution IN table_number,
        i_change             IN table_varchar,
        i_id_admission_type  IN admission_type.id_admission_type%TYPE,
        i_admission_time     IN VARCHAR2,
        o_id_department      OUT department.id_department%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    --

    FUNCTION get_department_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dept_department_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_department_type_list
    (
        i_lang            IN language.id_language%TYPE,
        o_department_type OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_department_default
    (
        i_lang              IN language.id_language%TYPE,
        i_id_dept           IN department.id_dept%TYPE,
        i_id_department_old IN department.id_department%TYPE,
        i_id_department_new IN department.id_department%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dep_clin_serv_new
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_department_ins   IN table_number,
        i_id_clin_service_ins IN table_number,
        i_id_department_del   IN table_number,
        i_id_clin_service_del IN table_number,
        o_id_dep_clin_serv    OUT table_number,
        o_id_department       OUT table_number,
        o_id_clin_serv        OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN table_number,
        i_id_clin_service  IN table_number,
        i_change           IN table_varchar,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN dep_clin_serv.id_department%TYPE,
        o_rel           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clin_serv_list
    (
        i_lang      IN language.id_language%TYPE,
        o_clin_serv OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_room_dep_clin_serv
    (
        i_lang               IN language.id_language%TYPE,
        i_id_room            IN room_dep_clin_serv.id_room%TYPE,
        i_dep_clin_serv      IN table_number,
        o_room_dep_clin_serv OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_room
    (
        i_lang              IN language.id_language%TYPE,
        i_id_room           IN room.id_room%TYPE,
        i_flg_prof          IN room.flg_prof%TYPE,
        i_id_department     IN room.id_department%TYPE,
        i_desc              IN VARCHAR2,
        i_flg_recovery      IN room.flg_recovery%TYPE,
        i_flg_lab           IN room.flg_lab%TYPE,
        i_flg_wait          IN room.flg_wait%TYPE,
        i_flg_wl            IN room.flg_wl%TYPE,
        i_flg_transp        IN room.flg_transp%TYPE,
        i_code_abbreviation IN room.code_abbreviation%TYPE,
        o_id_room           OUT room.id_room%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_room_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room_dep_clin_serv
    (
        i_lang               IN language.id_language%TYPE,
        i_id_room            IN room_dep_clin_serv.id_room%TYPE,
        o_dep_clin_serv_list OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_institution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN prof_institution.id_professional%TYPE,
        o_inst            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_cat_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cat   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_personal_data
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_prof            IN professional.id_professional%TYPE,
        i_id_institution     IN prof_institution.id_institution%TYPE,
        o_prof_personal_data OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_adress_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN prof_institution.id_institution%TYPE,
        o_prof_adress_data OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_professional_data
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_prof                IN professional.id_professional%TYPE,
        i_id_institution         IN prof_institution.id_institution%TYPE,
        o_prof_professional_data OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_contact_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_prof           IN professional.id_professional%TYPE,
        i_id_institution    IN prof_institution.id_institution%TYPE,
        o_prof_contact_data OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_general_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        o_inst_general_data OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_adress_data
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_institution   IN institution.id_institution%TYPE,
        o_inst_adress_data OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_adm_data
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_adm_data  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_license_data
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_institution    IN institution.id_institution%TYPE,
        o_inst_license_data OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_list
    (
        i_lang            IN language.id_language%TYPE,
        i_flg_type        IN institution.flg_type%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_currency_list
    (
        i_lang     IN language.id_language%TYPE,
        o_currency OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_language_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        o_language OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_type_list
    (
        i_lang      IN language.id_language%TYPE,
        o_inst_type OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_group_list
    (
        i_lang       IN language.id_language%TYPE,
        o_group_type OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_type_licenses
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professional_licenses
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN category.flg_type%TYPE,
        i_search         IN VARCHAR2,
        o_prof_lic_list  OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_profile_licenses
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_prof_lic_list  OUT pk_types.cursor_type,
        o_total_lic      OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Get Institution Attributes
    * Retorna os detalhes de uma instituição.
    * 
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      O_INST_ATTR                Cursor com a informação dos detalhes da instituição
    * @param      O_INST_AFFILIATIONS        Cursor com a informação das afiliações da instituição
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2009/03/05
    */
    FUNCTION get_institution_attributes
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_inst_attr         OUT pk_types.cursor_type,
        o_inst_affiliations OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_institution_data
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_inst_att        IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang       IN institution_language.id_institution_language%TYPE,
        i_desc               IN VARCHAR2,
        i_id_parent          IN institution.id_parent%TYPE,
        i_flg_type           IN institution.flg_type%TYPE,
        i_tax                IN inst_attributes.social_security_number%TYPE,
        i_abbreviation       IN institution.abbreviation%TYPE,
        i_pref_lang          IN institution_language.id_language%TYPE,
        i_currency           IN inst_attributes.id_currency%TYPE,
        i_phone_number       IN institution.phone_number%TYPE,
        i_fax                IN institution.fax_number%TYPE,
        i_email              IN inst_attributes.email%TYPE,
        i_adress             IN institution.address%TYPE,
        i_location           IN institution.location%TYPE,
        i_geo_state          IN institution.district%TYPE,
        i_zip_code           IN institution.zip_code%TYPE,
        i_country            IN inst_attributes.id_country%TYPE,
        i_location_tax       IN inst_attributes.id_location_tax%TYPE,
        i_lic_model          IN inst_attributes.license_model%TYPE,
        i_pay_sched          IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt            IN inst_attributes.payment_options%TYPE,
        i_flg_available      IN institution.flg_available%TYPE,
        i_id_tz_region       IN institution.id_timezone_region%TYPE,
        i_id_market          IN market.id_market%TYPE,
        i_contact_det        IN ab_institution.contact_detail%TYPE,
        i_commit_at_end      IN BOOLEAN,
        i_clues              IN inst_attributes.clues%TYPE,
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE,
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE,
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_website            IN inst_attributes.website%TYPE,
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_administrator
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_prof           IN profissional,
        o_inst_admin     OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_institution_administrator
    (
        i_lang          IN language.id_language%TYPE,
        i_software      IN software.id_software%TYPE,
        i_id_prof       IN professional.id_professional%TYPE,
        i_id_inst       IN institution.id_institution%TYPE,
        i_name          IN professional.name%TYPE,
        i_title         IN professional.title%TYPE,
        i_nick_name     IN professional.nick_name%TYPE,
        i_gender        IN professional.gender%TYPE,
        i_dt_birth      IN VARCHAR2,
        i_email         IN professional.email%TYPE,
        i_work_phone    IN professional.num_contact%TYPE,
        i_cell_phone    IN professional.cell_phone%TYPE,
        i_fax           IN professional.fax%TYPE,
        i_first_name    IN professional.first_name%TYPE,
        i_parent_name   IN professional.parent_name%TYPE,
        i_middle_name   IN professional.middle_name%TYPE,
        i_last_name     IN professional.last_name%TYPE,
        i_id_cat        IN category.id_category%TYPE,
        i_commit_at_end IN BOOLEAN,
        o_id_prof       OUT professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_license
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_lic       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_licensing_model_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_payment_opt_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_payment_schedule_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_change_details
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN institution.id_institution%TYPE,
        o_inst_general_attr_list OUT pk_types.cursor_type,
        o_inst_admin_attr_list   OUT pk_types.cursor_type,
        o_inst_license_attr_list OUT pk_types.cursor_type,
        o_inst_title_list        OUT pk_types.cursor_type,
        o_inst_affiliations      OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_in_use_licenses
    (
        i_lang       IN language.id_language%TYPE,
        i_id_prof    IN professional.id_professional%TYPE,
        o_in_use     OUT NUMBER,
        o_not_in_use OUT NUMBER,
        o_cancelled  OUT NUMBER,
        o_waiting    OUT NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional attributes
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_prof_attr           Cursor with profissional attributes
    * @param o_prof_affiliations   Cursor with profissional affiliations
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     1.0
    * @since                       2009/09/22
    ********************************************************************************************/
    FUNCTION get_professional_attributes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_professional   IN professional.id_professional%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_prof_attr         OUT pk_types.cursor_type,
        o_prof_affiliations OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_change_details
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN institution.id_institution%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_title           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Set Professional
    * Insere profissional ou actualiza detalhes se já existir
    *
    * @param      I_LANG                     Identificação do Idioma
    * @param      I_ID_INSTITUTION           Identificação da Instituição
    * @param      I_ID_PROF                  Identificação do Profissional
    * @param      I_TITLE                    Título
    * @param      I_FIRST_NAME               Primeiro nome
    * @param      I_MIDDLE_NAME              Nomes do meio
    * @param      I_LAST_NAME                Último nome
    * @param      I_NICK_NAME                Nome abreviado
    * @param      I_INITIALS                 Iniciais do nome
    * @param      I_DT_BIRTH                 Data de nascimento
    * @param      I_GENDER                   Sexo
    * @param      I_MARITAL_STATUS           Estado civil
    * @param      I_ID_CATEGORY              Identificador da categoria
    * @param      I_ID_SPECIALITY            Identificador da especialidade
    * @param      I_NUM_ORDER                Número da ordem
    * @param      I_UPIN                     UPIN
    * @param      I_DEA                      DEA
    * @param      I_ID_CAT_SURGERY           Identificador da categoria em cirurgia
    * @param      I_NUM_MECAN                Número mecanográfico
    * @param      I_ID_LANG                  Identificador da língua
    * @param      I_FLG_STATE                Estado
    * @param      I_ADDRESS                  Morada
    * @param      I_CITY                     Localidade
    * @param      I_DISTRICT                 Concelho
    * @param      I_ZIP_CODE                 Código postal
    * @param      I_ID_COUNTRY               Identificador do país
    * @param      I_WORK_PHONE               Telefone do trabalho
    * @param      I_NUM_CONTACT              Telefone de casa
    * @param      I_CELL_PHONE               Telemóvel
    * @param      I_FAX                      Fax
    * @param      I_EMAIL                    E-mail
    * @param      O_ID_PROF                  Identificador do Profissional criado
    * @param      o_id_lang                  OUT Professional Language 
    * @param      O_ERROR                    Erro
    *
    * @return     boolean
    * @author     Eduardo Lourenco - EL
    * @version    0.1
    * @since      2007/07/24
    */
    FUNCTION set_professional
    (
        i_lang                    IN language.id_language%TYPE,
        i_id_institution          IN institution.id_institution%TYPE,
        i_id_prof                 IN professional.id_professional%TYPE,
        i_title                   IN professional.title%TYPE,
        i_first_name              IN professional.first_name%TYPE,
        i_middle_name             IN professional.middle_name%TYPE,
        i_last_name               IN professional.last_name%TYPE,
        i_nick_name               IN professional.nick_name%TYPE,
        i_initials                IN professional.initials%TYPE,
        i_dt_birth                IN VARCHAR2,
        i_gender                  IN professional.gender%TYPE,
        i_marital_status          IN professional.marital_status%TYPE,
        i_id_category             IN category.id_category%TYPE,
        i_id_speciality           IN professional.id_speciality%TYPE,
        i_id_scholarship          IN professional.id_scholarship%TYPE,
        i_num_order               IN professional.num_order%TYPE,
        i_upin                    IN professional.upin%TYPE,
        i_dea                     IN professional.dea%TYPE,
        i_id_cat_surgery          IN category.id_category%TYPE,
        i_num_mecan               IN prof_institution.num_mecan%TYPE,
        i_id_lang                 IN prof_preferences.id_language%TYPE,
        i_flg_state               IN prof_institution.flg_state%TYPE,
        i_address                 IN professional.address%TYPE,
        i_city                    IN professional.city%TYPE,
        i_district                IN professional.district%TYPE,
        i_zip_code                IN professional.zip_code%TYPE,
        i_id_country              IN professional.id_country%TYPE,
        i_work_phone              IN professional.work_phone%TYPE,
        i_num_contact             IN professional.num_contact%TYPE,
        i_cell_phone              IN professional.cell_phone%TYPE,
        i_fax                     IN professional.fax%TYPE,
        i_email                   IN professional.email%TYPE,
        i_commit_at_end           IN BOOLEAN,
        i_id_road                 IN professional.id_road%TYPE,
        i_entity                  IN professional.id_entity%TYPE,
        i_jurisdiction            IN professional.id_jurisdiction%TYPE,
        i_municip                 IN professional.id_municip%TYPE,
        i_localidad               IN professional.id_localidad%TYPE,
        i_id_postal_code_rb       IN professional.id_postal_code_rb%TYPE,
        i_parent_name             IN professional.parent_name%TYPE,
        i_first_name_sa           IN professional.first_name_sa%TYPE,
        i_parent_name_sa          IN professional.parent_name_sa%TYPE,
        i_middle_name_sa          IN professional.middle_name_sa%TYPE,
        i_last_name_sa            IN professional.last_name_sa%TYPE,
        i_agrupacion              IN professional.id_agrupacion%TYPE,
        i_adress_type             IN professional.adress_type%TYPE DEFAULT NULL,
        i_bleep_num               IN professional.bleep_number%TYPE DEFAULT NULL,
        i_suffix                  IN professional.suffix%TYPE DEFAULT NULL,
        i_county                  IN professional.county%TYPE DEFAULT NULL,
        i_other_adress            IN professional.address_other_name%TYPE DEFAULT NULL,
        i_contact_det             IN prof_institution.contact_detail%TYPE DEFAULT NULL,
        i_doc_ident_type          IN prof_doc.id_doc_type%TYPE,
        i_doc_ident_num           IN prof_doc.value%TYPE,
        i_doc_ident_val           IN VARCHAR2,
        i_tin                     IN professional.taxpayer_number%TYPE,
        i_clinical_name           IN professional.clinical_name%TYPE,
        i_prof_spec_id            IN table_number,
        i_prof_spec_ballot        IN table_varchar,
        i_prof_spec_id_university IN table_number,
        i_agrupacion_instit_id    IN professional.id_agrupacion_instit%TYPE,
        o_id_prof                 OUT professional.id_professional%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_specialities
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_prof_id IN NUMBER,
        o_list    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION user_exists
    (
        i_lang      IN language.id_language%TYPE,
        i_desc_user IN ab_user_info.login%TYPE,
        o_flg_value OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************/
    FUNCTION get_profile_tmpl_cost_list
    (
        i_user                   IN profissional,
        i_id_language            IN language.id_language%TYPE,
        i_id_software            IN profile_template.id_software%TYPE,
        o_profile_tmpl_cost_list OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter a informação e preços dos perfis a vender para um determinado software
       PARAMETROS:  Entrada: i_user - ID do utilizador
                             i_id_software - identificador do software
                             i_id_institution - ID da instituição
                             o_product_list - lista de profiles e preços
                    Saida:   O_ERROR - erro
    
       CRIAÇÃO: JVB 2007-07-20
       REVISÕES:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        2007-07-20  Vilas Boas       Criação
    *********************************************************************************/

    FUNCTION get_all_license_list
    (
        i_user             IN profissional,
        i_id_language      IN language.id_language%TYPE,
        o_all_license_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * GET UNATTRIBUTED LICENSES 
    *
    * @param i_user                        profissional (id,institution, software)
    * @param i_id_language                 id_language 
    * @param o_unattribute_license_list    List of unattributed licenses
    * @param o_error                       Error
    *
    *
    * @return                              true or false on success or error
    *
    * @author                              Sérgio Monteiro
    * @version                             1.0
    * @since                               2008/11/23
    ********************************************************************************************/

    FUNCTION get_unattribute_license_list
    (
        i_user                     IN profissional,
        i_id_language              IN language.id_language%TYPE,
        o_unattribute_license_list OUT pk_types.cursor_type,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;
    /******************************************************************************
       OBJECTIVO:   Obter todas as licenças de uma instituição que ainda não estão atribuidas a nenhum profissional
       PARAMETROS:  Entrada: i_user - ID do utilizador
                             i_id_institution - ID da instituição
                             o_unattribute_license_list - lista de licensas
                    Saida:   O_ERROR - erro
    
       CRIAÇÃO: JVB 2007-07-20
       REVISÕES:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        2007-07-20  Vilas Boas       Criação
    *********************************************************************************/

    FUNCTION set_main_facility
    (
        i_lang        IN language.id_language%TYPE,
        i_id_old_main IN institution.id_institution%TYPE,
        i_id_new_main IN institution.id_institution%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_assigned_specialities
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_specialities    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_profiles
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_profile    OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_user_license
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_license      IN NUMBER,
        i_commit_at_end   IN BOOLEAN,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Association of a license to a user
    *
    * @param i_lang                   Language ID
    * @param i_id_professional        Professional ID
    * @param i_id_license             License ID
    
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @since                          2007/07/27
    **********************************************************************************************/

    FUNCTION get_all_payment
    (
        i_lang    IN language.id_language%TYPE,
        i_user    IN profissional,
        o_payment OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all payments (even if they weren't made)
    *
    * @param i_lang                   Language ID
    * @param i_id_professional        Professional ID
    
    * @param o_payment                Payment return cursor   
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @since                          2007/07/28
    **********************************************************************************************/

    FUNCTION get_payment_det
    (
        i_lang           IN language.id_language%TYPE,
        i_user           IN profissional,
        i_cart_id        IN VARCHAR2,
        o_payment_det    OUT pk_types.cursor_type,
        o_sub_total      OUT NUMBER,
        o_sub_total_desc OUT VARCHAR2,
        o_tax            OUT NUMBER,
        o_tax_desc       OUT VARCHAR2,
        o_total          OUT NUMBER,
        o_total_desc     OUT VARCHAR2,
        o_num            OUT NUMBER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get detail for a payment
    *
    * @param i_lang                   Language ID
    * @param i_id_professional        Professional ID
    * @param i_cart_id                Cart ID
    
    * @param o_payment_det            Payment detail return cursor   
    * @param o_license_det            License detail return cursor   
    * @param o_error                  Error message
                        
    * @return                         true or false on success or error
    * 
    * @author                         Rui de Sousa Neves
    * @since                          2007/07/29
    **********************************************************************************************/

    FUNCTION get_prof_photo_url
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    FUNCTION find_professionals
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_name           IN professional.name%TYPE,
        i_dt_birth       IN VARCHAR,
        i_gender         IN professional.gender%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_id_license     IN NUMBER,
        o_prof_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_profile_template_lcs
    (
        i_user                  IN profissional,
        i_language              IN language.id_language%TYPE,
        i_id_profile_templ_list IN table_number,
        i_profile_templ_num     IN table_number,
        i_payment_schedule_list IN table_varchar,
        i_flg_status            IN VARCHAR2,
        o_id_license            OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Criar ou fazer update de uma licensa
       PARAMETROS:  Entrada: i_user - ID do utilizador
                             i_id_product_purchasable - id do produto comprado
                             i_cart_id - identificador da compra
                             o_id_payment - id do pagamento
                    Saida:   O_ERROR - erro
    
       CRIAÇÃO: JVB 2007-07-30
       REVISÕES:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        2007-07-30  Vilas Boas       Criação
    *********************************************************************************/

    FUNCTION get_license_details
    (
        i_lang            IN language.id_language%TYPE,
        i_id_license      IN NUMBER,
        i_id_professional IN professional.id_professional%TYPE,
        o_lic             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************/
    FUNCTION cartid_generator
    (
        i_user     IN profissional,
        i_language IN language.id_language%TYPE,
        o_cartid   OUT VARCHAR2,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   devolver um identificador único
       PARAMETROS:  Entrada: i_user - ID do utilizador
                             O_CARTID - cartid
                             O_ERROR - erro
    
       CRIAÇÃO: JVB 2007-07-30
       REVISÕES:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        2007-07-30  Vilas Boas       Criaçao
    *********************************************************************************/

    FUNCTION set_payment
    (
        i_user            IN profissional,
        i_language        IN language.id_language%TYPE,
        i_id_license_list IN table_number,
        i_cart_id         IN VARCHAR2,
        i_auth_mode       IN sys_config.value%TYPE,
        i_test_mode       IN sys_config.value%TYPE,
        i_trans_status    IN sys_config.value%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /******************************************************************************
       OBJECTIVO:   Pagar licenças
       PARAMETROS:  Entrada: i_user - ID do utilizador
                             i_id_license_list - id das licenças
                             i_id_currency - identificador da moeda em que é efectuado o pagamento
                             i_cart_id - identificador da compra
                             i_auth_mode - Modo da transação (Imediato ou Futuro)
                             i_test_mode - Modo de funcionamento do pagamento na WorldPay
                             i_trans_status - estado da transferencia
                    Saida:   O_ERROR - erro
    
       CRIAÇÃO: JVB 2007-07-30
       REVISÕES:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        2007-07-30  Vilas Boas       Criação
    *********************************************************************************/

    FUNCTION set_license_info
    (
        i_lang             IN language.id_language%TYPE,
        i_id_license       IN NUMBER,
        i_note             IN VARCHAR2,
        i_payment_schedule IN sys_domain.val%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_assigned_profiles
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_license
    (
        i_lang       IN language.id_language%TYPE,
        i_id_license IN NUMBER,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_specialties
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_specialities
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN NUMBER,
        i_prof_spec_id            IN table_number,
        i_prof_spec_ballot        IN table_varchar,
        i_prof_spec_id_university IN table_number,
        o_spec_main               OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION remove_professional
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION remove_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_software_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN software_institution.id_institution%TYPE,
        i_soft           IN table_number,
        o_id_soft_inst   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_software
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_service_default
    (
        i_lang        IN language.id_language%TYPE,
        i_id_services IN table_number,
        i_flg_default IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION unsubscribe_inst_license
    (
        i_lang    IN language.id_language%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_header
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_license      IN NUMBER,
        o_adm             OUT pk_types.cursor_type,
        o_inst            OUT pk_types.cursor_type,
        o_prof            OUT pk_types.cursor_type,
        o_lic             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_prof
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_inst_profile    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_spec
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_inst_spec       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_currency_desc
    (
        i_user          IN profissional,
        i_language      IN language.id_language%TYPE,
        o_currency_desc OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_license_cat
    (
        i_lang       IN language.id_language%TYPE,
        i_id_license IN NUMBER,
        o_lic_cat    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION unsubscribe_inst
    (
        i_lang    IN language.id_language%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        o_inst_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_professional_nolicense
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_type       IN category.flg_type%TYPE,
        i_search         IN VARCHAR2,
        o_prof_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_inst_prof
    (
        i_lang    IN language.id_language%TYPE,
        i_id_inst IN institution.id_institution%TYPE,
        i_id_prof IN professional.id_professional%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_institution_list_nolicense
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_flg_type  IN institution.flg_type%TYPE,
        o_inst_list OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_change_details_nolic
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_institution         IN institution.id_institution%TYPE,
        o_inst_general_attr_list OUT pk_types.cursor_type,
        o_inst_admin_attr_list   OUT pk_types.cursor_type,
        o_inst_title_list        OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_header_nolicense
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_adm             OUT pk_types.cursor_type,
        o_inst            OUT pk_types.cursor_type,
        o_prof            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_possible_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_institution_data_nolicense
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_id_inst_att        IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang       IN institution_language.id_institution_language%TYPE,
        i_desc               IN VARCHAR2,
        i_id_parent          IN institution.id_parent%TYPE,
        i_flg_type           IN institution.flg_type%TYPE,
        i_tax                IN inst_attributes.social_security_number%TYPE,
        i_abbreviation       IN institution.abbreviation%TYPE,
        i_pref_lang          IN institution_language.id_language%TYPE,
        i_currency           IN inst_attributes.id_currency%TYPE,
        i_phone_number       IN institution.phone_number%TYPE,
        i_fax                IN institution.fax_number%TYPE,
        i_email              IN inst_attributes.email%TYPE,
        i_adress             IN institution.address%TYPE,
        i_location           IN institution.location%TYPE,
        i_geo_state          IN institution.district%TYPE,
        i_zip_code           IN institution.zip_code%TYPE,
        i_country            IN inst_attributes.id_country%TYPE,
        i_flg_available      IN institution.flg_available%TYPE,
        i_id_tz_region       IN institution.id_timezone_region%TYPE,
        i_contact_det        IN ab_institution.contact_detail%TYPE,
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_currency_desc
    (
        i_value       IN NUMBER,
        i_id_currency IN currency.id_currency%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_timezone_region_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_possible_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * A função devolve o valor do imposto a cobrar consoante a instituição e país da mesma
    *
    * @param i_user      profissional que efectua o pedido
    * @param i_language  lingua do profissional
    * @param o_tax       valor do imposto
    * @param o_error     erro
    *
    * @return            Return boolean
    * 
    * @author            José Vilas Boas
    * @version           1.0
    * @since             2007/09/04
       ********************************************************************************************/
    FUNCTION get_tax
    (
        i_user     IN profissional,
        i_language IN language.id_language%TYPE,
        o_tax      OUT NUMBER,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_room_task_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_date_received
    (
        i_lang     IN language.id_language%TYPE,
        i_str_date IN VARCHAR2
    ) RETURN DATE;

    FUNCTION get_date_to_be_sent
    (
        i_lang IN language.id_language%TYPE,
        i_date IN DATE
    ) RETURN VARCHAR2;

    FUNCTION get_room_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_cur             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_service_spec_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_institutiton IN institution.id_institution%TYPE,
        i_id_room         IN room.id_room%TYPE,
        o_cur             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION assign_room_service
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_room     IN table_number,
        i_id_srv_spec IN table_number,
        i_flg_values  IN table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_cur     OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_service_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institutiton IN institution.id_institution%TYPE,
        o_cur             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_room_type_list
    (
        i_lang  IN language.id_language%TYPE,
        o_cur   OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_room
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_room           IN room.id_room%TYPE,
        i_room_name         IN VARCHAR2,
        i_id_service        IN department.id_department%TYPE,
        i_flg_types         IN table_varchar,
        i_flg_available     IN room.flg_available%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        o_id_room           OUT room.id_room%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_room
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_room           IN room.id_room%TYPE,
        i_room_name         IN VARCHAR2,
        i_abbreviation      IN VARCHAR2,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        i_capacity          IN room.capacity%TYPE,
        i_rank              IN room.rank%TYPE,
        o_id_room           OUT room.id_room%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION delete_room
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_room IN room.id_room%TYPE,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_inst_and_admin
    (
        i_lang               IN language.id_language%TYPE,
        i_id_institution     IN institution.id_institution%TYPE,
        i_clues              IN inst_attributes.clues%TYPE,
        i_id_inst_att        IN inst_attributes.id_inst_attributes%TYPE,
        i_id_inst_lang       IN institution_language.id_institution_language%TYPE,
        i_desc               IN VARCHAR2,
        i_id_parent          IN institution.id_parent%TYPE,
        i_flg_type           IN institution.flg_type%TYPE,
        i_tax                IN inst_attributes.social_security_number%TYPE,
        i_abbreviation       IN institution.abbreviation%TYPE,
        i_pref_lang          IN institution_language.id_language%TYPE,
        i_currency           IN inst_attributes.id_currency%TYPE,
        i_phone_number       IN institution.phone_number%TYPE,
        i_fax                IN institution.fax_number%TYPE,
        i_email              IN inst_attributes.email%TYPE,
        i_health_license     IN inst_attributes.health_license%TYPE,
        i_address            IN institution.address%TYPE,
        i_location           IN institution.location%TYPE,
        i_geo_state          IN institution.district%TYPE,
        i_flg_street_type    IN inst_attributes.flg_street_type%TYPE,
        i_street_name        IN inst_attributes.street_name%TYPE,
        i_outdoor_number     IN inst_attributes.outdoor_number%TYPE,
        i_indoor_number      IN inst_attributes.indoor_number%TYPE,
        i_id_settlement_type IN inst_attributes.id_settlement_type%TYPE,
        i_id_settlement_name IN inst_attributes.id_settlement_name%TYPE,
        i_id_entity          IN inst_attributes.id_entity%TYPE,
        i_id_municip         IN inst_attributes.id_municip%TYPE,
        i_id_localidad       IN inst_attributes.id_localidad%TYPE,
        i_id_postal_code     IN inst_attributes.id_postal_code%TYPE,
        i_zip_code           IN institution.zip_code%TYPE,
        i_country            IN inst_attributes.id_country%TYPE,
        i_jurisdiction       IN inst_attributes.jurisdiction%TYPE,
        i_location_tax       IN inst_attributes.id_location_tax%TYPE,
        i_lic_model          IN inst_attributes.license_model%TYPE,
        i_pay_sched          IN inst_attributes.payment_schedule%TYPE,
        i_pay_opt            IN inst_attributes.payment_options%TYPE,
        i_flg_available      IN institution.flg_available%TYPE,
        i_id_tz_region       IN institution.id_timezone_region%TYPE,
        i_id_market          IN market.id_market%TYPE,
        i_contact_det        IN ab_institution.contact_detail%TYPE,
        
        i_software    IN software.id_software%TYPE,
        i_id_prof     IN professional.id_professional%TYPE,
        i_id_inst     IN institution.id_institution%TYPE,
        i_name        IN professional.name%TYPE,
        i_title       IN professional.title%TYPE,
        i_nick_name   IN professional.nick_name%TYPE,
        i_gender      IN professional.gender%TYPE,
        i_dt_birth    IN VARCHAR2,
        i_prof_email  IN professional.email%TYPE,
        i_work_phone  IN professional.num_contact%TYPE,
        i_cell_phone  IN professional.cell_phone%TYPE,
        i_prof_fax    IN professional.fax%TYPE,
        i_first_name  IN professional.first_name%TYPE,
        i_parent_name IN professional.parent_name%TYPE,
        i_middle_name IN professional.middle_name%TYPE,
        i_last_name   IN professional.last_name%TYPE,
        i_id_cat      IN category.id_category%TYPE,
        
        o_id_institution     OUT institution.id_institution%TYPE,
        o_id_inst_attributes OUT inst_attributes.id_inst_attributes%TYPE,
        o_id_inst_lang       OUT institution_language.id_institution_language%TYPE,
        o_id_prof            OUT professional.id_professional%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_prof_and_license
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nick_name      IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN VARCHAR2,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_upin           IN professional.upin%TYPE,
        i_dea            IN professional.dea%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        i_num_mecan      IN prof_institution.num_mecan%TYPE,
        i_id_lang        IN prof_preferences.id_language%TYPE,
        i_flg_state      IN prof_institution.flg_state%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_id_license     IN NUMBER,
        o_id_prof        OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_tpl_list_and_prof_func_all
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_inst             IN table_number,
        i_soft             IN table_number,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_templ            IN table_number,
        
        i_prof         IN profissional,
        i_func         IN table_number,
        i_change       IN table_varchar,
        o_id_prof_func OUT table_number,
        o_error        OUT t_error_out
        
    ) RETURN BOOLEAN;

    FUNCTION get_summary_gen_inf
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_cur_t1         OUT pk_types.cursor_type,
        o_cur_t2         OUT pk_types.cursor_type,
        o_cur_t3         OUT pk_types.cursor_type,
        o_cur_d1         OUT pk_types.cursor_type,
        o_cur_d2         OUT pk_types.cursor_type,
        o_cur_d3         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_dept_srv
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_cur            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_summary_rooms
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_cur            OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_next_value
    (
        i_table_name     IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN NUMBER;

    FUNCTION table_varchar_string
    (
        i_tab       IN table_varchar,
        i_delim     IN VARCHAR2 DEFAULT '|',
        i_start_off IN NUMBER DEFAULT 1,
        i_length    IN NUMBER DEFAULT -1
    ) RETURN VARCHAR2;

    FUNCTION get_prof_profile_template
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        o_id_profile_template OUT prof_profile_template.id_profile_template%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Facility number of licenses
    *
    * @param i_prof              Object (professional ID, institution ID, software ID)
    * @param i_lang              Prefered language ID
    * @param o_license_num       Number of licenses
    * @param o_error             Error
    *
    * @return                    true or false on success or error
    *
    * @author                    JVB
    * @version                   1.0
    * @since                     2007/11/21
    **********************************************************************************************/
    FUNCTION get_license_num
    (
        i_prof        IN profissional,
        i_lang        IN language.id_language%TYPE,
        o_license_num OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Facility number of licenses
    *
    * @param i_prof              Object (professional ID, institution ID, software ID)
    * @param i_lang              Prefered language ID
    * @param o_license_num       Number of licenses
    * @param o_error             Error
    *
    * @return                    true or false on success or error
    *
    * @author                    JVB
    * @version                   1.0
    * @since                     2007/11/21
    **********************************************************************************************/
    FUNCTION get_license_num
    (
        i_prof IN profissional,
        i_lang IN language.id_language%TYPE
    ) RETURN NUMBER;

    /**********************************************************************************************
    * Value to pay for licenses
    *
    * @param i_prof              Object (professional ID, institution ID, software ID)
    * @param i_lang              Prefered language ID
    * @param i_id_software       Software ID
    * @param i_id_product_list   Products ID
    * @param i_product_num       Number of products
    * @param i_product_type      Product type
    * @param i_payment_schedule  Payment schedule
    * @param o_license_cost_list Product list
    * @param o_sub_total         Sub total
    * @param o_sub_total_desc    Sub total description
    * @param o_tax               Tax
    * @param o_tax_desc          Tax description
    * @param o_total             Total
    * @param o_total_desc        Total description
    * @param o_setupfee          Setupfee
    * @param o_setupfee_desc     Setupfee description
    * @param o_error             Error
    *
    * @return                    true or false on success or error
    *
    * @author                    JVB
    * @version                   1.0
    * @since                     2007/12/04
    **********************************************************************************************/
    FUNCTION get_product_cost_list
    (
        i_prof              IN profissional,
        i_lang              IN language.id_language%TYPE,
        i_id_software       IN profile_template.id_software%TYPE,
        i_id_product_list   IN table_number,
        i_product_num       IN table_number,
        i_product_type      IN table_varchar,
        i_payment_schedule  IN table_varchar,
        o_license_cost_list OUT pk_types.cursor_type,
        o_sub_total         OUT NUMBER,
        o_sub_total_desc    OUT VARCHAR2,
        o_tax               OUT NUMBER,
        o_tax_desc          OUT VARCHAR2,
        o_total             OUT NUMBER,
        o_total_desc        OUT VARCHAR2,
        o_setupfee          OUT NUMBER,
        o_setupfee_desc     OUT VARCHAR2,
        o_qty               OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**********************************************************************************************
    * Value to pay for licenses
    *
    * @param i_prof              Object (professional ID, institution ID, software ID)
    * @param i_lang              Preferred language ID
    * @param i_id_software       Software ID
    * @param o_product_list      Product list
    * @param o_error             Error
    *
    * @return                    true or false on success or error
    *
    * @author                    JVB
    * @version                   1.0
    * @since                     2007/12/04
    **********************************************************************************************/
    FUNCTION get_product_list
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_id_software  IN profile_template.id_software%TYPE,
        o_product_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Number of profile licenses 
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_lang                   Preferred language ID
    * @param i_id_profile_template    Profile ID
    * @param o_license_num            Number of profiles
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         JVB
    * @version                        1.0
    * @since                          2007/11/29
    ********************************************************************************************/
    FUNCTION get_inst_lic_num
    (
        i_prof                IN profissional,
        i_lang                IN language.id_language%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        o_license_num         OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Number of profile licenses at the facility
    *
    * @param i_prof                   Object (professional ID, institution ID, software ID)
    * @param i_lang                   Preferred language ID
    * @param i_id_institution         Institution ID
    * @param i_id_product_purchasable Product ID
    * @param o_product_num            Number of products
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         JVB
    * @version                        1.0
    * @since                          2007/12/03
    ********************************************************************************************/
    FUNCTION get_inst_pro_num
    (
        i_prof                   IN profissional,
        i_lang                   IN language.id_language%TYPE,
        i_id_product_purchasable IN NUMBER,
        o_product_num            OUT NUMBER,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create/update licenses
    *
    * @param i_prof                   Profissional ID
    * @param i_lang                   Preferred language ID
    * @param i_id_product_purch_list  Product list
    * @param i_product_purch_num      Number of linceses
    * @param i_id_institution         Institution ID
    * @param o_id_license             Licenses
    * @param o_error                  Error
    *
    * @return                         true or false on success or error
    *
    * @author                         JVB
    * @version                        1.0
    * @since                          2007/12/04
    ********************************************************************************************/
    FUNCTION set_product_purch_lcs
    (
        i_prof                  IN profissional,
        i_lang                  IN language.id_language%TYPE,
        i_id_product_purch_list IN table_number,
        i_product_purch_num     IN table_number,
        i_payment_schedule_list IN table_varchar,
        o_id_license            OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Suggest username
    *
    * @param i_lang          Preferred language ID
    * @param i_first_name    First name
    * @param i_middle_name   Middle name
    * @param i_last_name     Last name
    * @param o_user_desc     Username
    * @param o_error         Error
    *
    * @return                true or false on success or error
    *
    * @author                JVB
    * @version               1.0
    * @since                 2007/12/17
    ********************************************************************************************/
    FUNCTION suggest_user
    (
        i_lang        IN language.id_language%TYPE,
        i_first_name  IN professional.first_name%TYPE,
        i_middle_name IN professional.middle_name%TYPE,
        i_last_name   IN professional.last_name%TYPE,
        o_user_desc   OUT ab_user_info.login%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get alerts for a specific profile
    *
    * @param i_lang                  Preferred language ID
    * @param i_id_institution        Institution ID
    * @param i_id_software           Software ID    
    * @param i_id_profile_template   Profile ID
    * @param i_id_professional       Professional ID
    * @param o_list                  Alerts
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    * 
    *
    * @author                        JS
    * @version                       0.1
    * @since                         2008/03/11
    ********************************************************************************************/
    FUNCTION get_profile_sys_alert
    (
        i_lang                IN language.id_language%TYPE,
        i_id_institution      IN institution.id_institution%TYPE,
        i_id_software         IN software.id_software%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_professional     IN professional.id_professional%TYPE,
        o_list                OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get professional assigned profiles at the facility
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_id_software      Software ID
    * @param o_templ            Profiles
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2007/12/27
    ********************************************************************************************/
    FUNCTION get_profile_template_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN prof_profile_template.id_institution%TYPE,
        i_id_software    IN prof_profile_template.id_software%TYPE,
        o_templ          OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get list of professionals for a given institution, software and profile
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_id_software      Software ID
    * @param i_id_prof_template profile ID
    * @param o_profs            output list
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    * @author                   Telmo Castro
    * @version                  2.4.3
    * @since                    29-04-2008
    ********************************************************************************************/
    FUNCTION get_profile_profs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_institution   IN prof_profile_template.id_institution%TYPE,
        i_id_software      IN prof_profile_template.id_software%TYPE,
        i_id_prof_template IN prof_profile_template.id_profile_template%TYPE,
        i_dummy            IN NUMBER,
        o_profs            OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Insert/delete professional alerts
    *
    * @param i_lang                 Preferred language ID
    * @param i_id_professional      Professional ID
    * @param i_id_institution       Institution ID
    * @param i_software             Softwares
    * @param i_profile              Profiles
    * @param i_id_sys_alert         Alerts
    * @param i_id_sys_alert_change  Change in alert
    * @param o_id_sys_alert_prof    Alerts ID's
    * @param o_error                Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2007/12/27
    ********************************************************************************************/
    FUNCTION set_prof_sys_alert
    (
        i_lang                IN language.id_language%TYPE,
        i_id_professional     IN sys_alert_prof.id_professional%TYPE,
        i_id_institution      IN sys_alert_prof.id_institution%TYPE,
        i_software            IN table_number,
        i_profile             IN table_number,
        i_id_sys_alert        IN table_number,
        i_id_sys_alert_change IN table_varchar,
        o_id_sys_alert_prof   OUT table_number,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get professional assigned softwares at the facility
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_id_institution   Institution ID
    * @param o_prof_list        Softwares
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2007/12/27
    ********************************************************************************************/
    FUNCTION get_assigned_profiles_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_list       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional alerts
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_id_professional  Professional ID
    * @param o_list             Alerts
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2007/12/27
    ********************************************************************************************/
    FUNCTION get_prof_sys_alert
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN sys_alert_config.id_institution%TYPE,
        i_id_professional IN sys_alert_prof.id_professional%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Profiles
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_id_software      Software ID
    * @param i_id_professional  Professional ID
    * @param o_templ            Profiles
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JS
    * @version                  0.1
    * @since                    2008/03/11
    ********************************************************************************************/
    FUNCTION get_prof_profile_alerts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN prof_profile_template.id_institution%TYPE,
        i_id_software     IN prof_profile_template.id_software%TYPE,
        i_id_professional IN prof_profile_template.id_professional%TYPE,
        o_templ           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Departments and Services tasks
    *
    * @param i_lang         Preferred language ID
    * @param o_list         Tasks
    * @param o_error        Error
    *
    * @return               true or false on success or error
    * 
    *
    * @author               EL
    * @version              0.1
    * @since                2008/01/16
    ********************************************************************************************/
    FUNCTION get_dept_serv_task_list
    (
        i_lang  IN language.id_language%TYPE,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Room State List
    *
    * @param i_lang          Preferred language ID
    * @param o_room_state    State list
    * @param o_error         Error
    *
    * @return                true or false on success or error
    * 
    *
    * @author                JTS
    * @version               0.1
    * @since                 2008/01/16
    ********************************************************************************************/
    FUNCTION get_room_state_list
    (
        i_lang       IN language.id_language%TYPE,
        o_room_state OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Department Service List 
    *
    * @param i_lang             Preferred language ID
    * @param i_id_dept          Department ID
    * @param o_department_list  Services
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2008/02/07
    ********************************************************************************************/
    FUNCTION get_service_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        o_department_list OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Relation(Service/Clinical Service) Information
    *
    * @param i_lang          Preferred language ID
    * @param i_id_dept       Department ID
    * @param i_id_department Service ID
    * @param o_dcs           Clinical services
    * @param o_error         Error
    *
    * @return                true or false on success or error
    * 
    *
    * @author                JTS
    * @version               0.1
    * @since                 2008/02/07
    ********************************************************************************************/
    FUNCTION get_dep_clin_serv_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_dept       IN dept.id_dept%TYPE,
        i_id_department IN dep_clin_serv.id_department%TYPE,
        o_dcs           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set professional accounts information
    *
    * @param i_lang                  Preferred language ID
    * @param i_id_professional       Professional ID
    * @param i_accounts              Account ID's Array
    * @param i_accounts_values       Account Values Array
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    * 
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/26
    ********************************************************************************************/
    FUNCTION set_prof_accounts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_accounts        IN table_number,
        i_accounts_values IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get professional accounts information
    *
    * @param i_lang                  Preferred language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution
    * @param o_prof_accounts         Professional affiliations
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    * 
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2009/09/22
    ********************************************************************************************/
    FUNCTION get_prof_accounts
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_accounts   OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Departmwent Room list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_department         Service ID
    * @param o_room_list             Room List
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/05/28
    ********************************************************************************************/
    FUNCTION get_room_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        o_room_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param o_list                  USF List
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/30
    ********************************************************************************************/
    FUNCTION get_usf_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF Teams list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_usf                USF ID
    * @param i_id_professional       Professional ID
    * @param o_list                  USF List
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/30
    ********************************************************************************************/
    FUNCTION get_usf_team_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_usf          IN institution.id_institution%TYPE,
        i_id_professional IN prof_team_det.id_professional%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF Team detail
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_usf                USF ID
    * @param i_id_prof_team          USF team ID
    * @param i_id_professional       Professional ID
    * @param o_usf_team_cat_list     USF Categoey List
    * @param o_usf_team_prof_list    USF Team members
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/30
    ********************************************************************************************/
    FUNCTION get_usf_team_detail
    (
        i_lang               IN language.id_language%TYPE,
        i_id_usf             IN institution.id_institution%TYPE,
        i_id_prof_team       IN prof_team_det.id_prof_team%TYPE,
        i_id_professional    IN professional.id_professional%TYPE,
        o_usf_team_cat_list  OUT pk_types.cursor_type,
        o_usf_team_prof_list OUT pk_types.cursor_type,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set professional teams information
    *
    * @param i_lang                  Preferred language ID
    * @param i_id_professional       Professional ID
    * @param i_prof_teams            Team ID's Array
    * @param i_select                Selected Value Array
    * @param o_error                 Error
    *
    * @return                        true or false on success or error
    * 
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/30
    ********************************************************************************************/
    FUNCTION set_prof_usf_teams
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_prof_teams      IN table_number,
        i_select          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Institution Team list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param o_list                  USF List
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/05/31
    ********************************************************************************************/
    FUNCTION get_inst_team_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF Team Detail
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_prof_team          Team ID
    * @param o_team                  Team information
    * @param o_team_cat              Team categories list
    * @param o_team_prof             Team professionals list
    * @param o_team_spec             Team specialties list
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/01
    ********************************************************************************************/
    FUNCTION get_usf_team
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof_team IN prof_team.id_prof_team%TYPE,
        o_team         OUT pk_types.cursor_type,
        o_team_cat     OUT pk_types.cursor_type,
        o_team_prof    OUT pk_types.cursor_type,
        o_team_spec    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF Professionals list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_prof_team          Team ID
    * @param i_categories            Array of Categories ID's
    * @param i_spec                  Array of specialties ID's
    * @param i_search                Professional search
    * @param o_prof                  Professionals list
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/01
    ********************************************************************************************/
    FUNCTION get_usf_prof_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_prof_team   IN prof_team.id_prof_team%TYPE,
        i_categories     IN table_number,
        i_spec           IN table_number,
        i_search         IN VARCHAR2,
        o_prof           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create/Edit Team
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof_team          Team ID
    * @param i_id_usf                USF ID
    * @param i_prof_team_name        Prof team name
    * @param i_categories            Array with team categories
    * @param i_categries_select      Array with team categories selection
    * @param i_prof                  Array with professional ID's
    * @param i_prof_select           Array with professional selection
    * @param i_spec                  Array with specialties ID's
    * @param i_spec_select           Array with specialties selection
    * @param o_id_prof_team          Prof Team ID
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/01
    ********************************************************************************************/
    FUNCTION set_usf_team
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof_team     IN prof_team.id_prof_team%TYPE,
        i_id_usf           IN institution.id_institution%TYPE,
        i_prof_team_name   IN prof_team.prof_team_name%TYPE,
        i_categories       IN table_number,
        i_categries_select IN table_varchar,
        i_prof             IN table_number,
        i_prof_select      IN table_varchar,
        i_spec             IN table_number,
        i_spec_select      IN table_varchar,
        o_id_prof_team     OUT prof_team.id_prof_team%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional USF
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param o_usf                   USF Information
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/01
    ********************************************************************************************/
    FUNCTION get_professional_usf
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_usf             OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set USF Teams state
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof_team             Array of Team ID's
    * @param i_flg_state             Array of Teams sate
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/06/02
    ********************************************************************************************/
    FUNCTION set_usf_team_state
    (
        i_lang      IN language.id_language%TYPE,
        i_prof_team IN table_number,
        i_flg_state IN table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Consult Clincal Services
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_prof_team          Team ID
    * @param o_clin_serv             Consult Clincal Services
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/04
    ********************************************************************************************/
    FUNCTION get_team_clin_serv_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_prof_team   IN prof_team.id_prof_team%TYPE,
        o_clin_serv      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Professional USF list
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_professional       Professional ID
    * @param o_list                  USF List
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/04
    ********************************************************************************************/
    FUNCTION get_prof_usf_list
    (
        i_lang            IN language.id_language%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_list            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * USF Team Detail
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof_team          Team ID
    * @param o_team                  Team information
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        JTS
    * @version                       0.1
    * @since                         2008/06/19
    ********************************************************************************************/
    FUNCTION get_usf_team_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_id_prof_team IN prof_team.id_prof_team%TYPE,
        o_team         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * SET TEMPORARY PROFESSIONAL
    *
    * @param i_lang                  Prefered language ID
    * @param i_login                 Professional Login 
    * @param i_pass                  Professional pass
    * @param i_name                  Professional name
    * @param i_nick_name             Professional nick name
    * @param i_gender                Professional gender
    * @param i_secret_answ           Professional secret answer
    * @param i_secret_quest          Professional secret question
    * @param i_commit_at_end         Do the commit at the end of the function TRUE=do commit; FALSE = do not commit
    * @param o_id_professional       Professional ID    
    * @param o_error                 Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Sérgio Monteiro
    * @version                       0.1
    * @since                         2008/11/15
    ********************************************************************************************/

    FUNCTION set_temporary_user
    (
        i_lang            IN language.id_language%TYPE,
        i_login           IN ab_user_info.login%TYPE,
        i_pass            IN VARCHAR2,
        i_name            IN professional.name%TYPE,
        i_nick_name       IN professional.nick_name%TYPE,
        i_gender          IN professional.gender%TYPE,
        i_secret_answ     IN VARCHAR2,
        i_secret_quest    IN NUMBER,
        i_commit_at_end   IN BOOLEAN,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get_user_status
    *
    * @param i_lang                  Prefered language ID
    * @param i_user                  User ID
     *
    *
    * @return                        true or false on success or error
    *
    * @author                        Susana Silva
    * @version                       2.4.4
    * @since                         2008/12/03
      ********************************************************************************************/

    FUNCTION get_user_status
    (
        i_lang IN language.id_language%TYPE,
        i_user IN professional.id_professional%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
     * GET_PROFESSIONAL_AGE
    *
    * @param i_lang                  Prefered language ID
    * @param i_dt_birth              Birthday date
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Susana Silva
    * @version                       2.4.4
    * @since                         2008/12/03
      ********************************************************************************************/

    FUNCTION get_professional_age
    (
        i_lang     IN language.id_language%TYPE,
        i_dt_birth IN professional.dt_birth%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * SET LICENSES
    *
    * @param i_lang                     Prefered language ID
    * @param i_id_institution           id institution
    * @param i_id_product_purchasable   id for the product purchasable (billing or adw)
    * @param i_id_professional          Professional id
    * @param i_dt_expire                expire date   
    * @param i_flg_status               license status
    * @param i_payment_schedule         payment schedule A- anual B-biannual
    * @param i_notes_license            notes for the  licenses
    * @param i_dt_purchase              dt of purchase
    * @param i_id_profile_template_desc id_profile template desc    
    * @param i_dt_expire_tstz           date of expire_tstz    
    * @param i_dt_purchase_tstz         date of purchase_tstz    
    * @param o_error                    Error
    *
    *
    * @return                        true or false on success or error
    *
    * @author                        Sérgio Monteiro
    * @version                       0.1
    * @since                         2008/11/15
    ********************************************************************************************/

    FUNCTION set_licenses
    (
        i_lang                     IN language.id_language%TYPE,
        i_id_institution           IN license.id_institution%TYPE,
        i_id_product_purchasable   IN license.id_product_purchasable%TYPE,
        i_id_professional          IN license.id_professional%TYPE,
        i_dt_expire                IN license.dt_expire%TYPE,
        i_flg_status               IN license.flg_status%TYPE,
        i_payment_schedule         IN license.payment_schedule%TYPE,
        i_notes_license            IN license.notes_license%TYPE,
        i_dt_purchase              IN license.dt_purchase%TYPE,
        i_id_profile_template_desc IN license.id_profile_template_desc%TYPE,
        i_dt_expire_tstz           IN license.dt_expire_tstz%TYPE,
        i_dt_purchase_tstz         IN license.dt_purchase_tstz%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create institution via ALERT® ONLINE
    *
    * @param i_lang                  Prefered language ID
    * @param i_flg_type_inst         Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_id_country            Institution ID country
    * @param i_inst_name             Institution name
    * @param i_inst_address          Institution address
    * @param i_inst_zipcode          Institution zipcode
    * @param i_inst_phone            Institution phone
    * @param i_inst_fax              Institution fax
    * @param i_inst_email            Institution email
    * @param i_inst_currency         Institution prefered currency
    * @param i_inst_timezone         Institution timezendo ID    
    * @param i_inst_acronym          Institution acronym
    * @param i_market                Market id
    * @param o_id_institution        institution ID created
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Sérgio Monteiro
    * @version                     0.1
    * @since                       2008/12/03
    ********************************************************************************************/

    FUNCTION set_institution_data_online
    (
        i_lang           IN language.id_language%TYPE,
        i_flg_type_inst  IN institution.flg_type%TYPE,
        i_id_country     IN inst_attributes.id_country%TYPE,
        i_inst_name      IN pk_translation.t_desc_translation,
        i_inst_address   IN institution.address%TYPE,
        i_inst_zipcode   IN institution.zip_code%TYPE,
        i_inst_phone     IN institution.phone_number%TYPE,
        i_inst_fax       IN institution.fax_number%TYPE,
        i_inst_email     IN inst_attributes.email%TYPE,
        i_inst_currency  IN inst_attributes.id_currency%TYPE,
        i_inst_timezone  IN institution.id_timezone_region%TYPE,
        i_inst_acronym   IN institution.abbreviation%TYPE,
        i_market         IN market.id_market%TYPE,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
        
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * GET USER FUNTIONALITY 
    *
    * @param i_id_category                  Prefered language ID
     *
    *
    * @return                      true or false on success or error
    *
    * @author                      Susana Silva
    * @version                     0.1
    * @since                       2008/12/06
    ********************************************************************************************/

    FUNCTION get_user_funtionality
    (
        i_id_category    IN category.id_category%TYPE,
        i_id_software    IN software.id_software%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_user        IN ab_user_info.id_ab_user_info%TYPE
    ) RETURN VARCHAR;

    /********************************************************************************************
    * Get a list off the markets for a specific country
    *
    * @param i_lang                Prefered language ID
    * @param i_id_country          Institution country ID
    * @param o_market              Market List cursor
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2008/12/09
    ********************************************************************************************/

    FUNCTION get_market_list
    (
        i_lang       IN language.id_language%TYPE,
        i_id_country IN country.id_country%TYPE,
        o_market     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the software available for the institution, including the "All" softwares clause
    *
    * @param i_lang                            Prefered language ID
    * @param i_id_institution                  Institution ID    
    * @param o_software                        Software ID
    * @param o_error                           Error
    *
    *
    * @return                                  true or false on success or error
    *
    * @author                                  Sérgio Cunha
    * @version                                 0.1
    * @since                                   2009/01/27
    ********************************************************************************************/
    FUNCTION get_institution_software_all
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_software       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       17/02/2009
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang        IN language.id_language%TYPE,
        i_code_domain sys_domain.code_domain%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Appointment Department List 
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param o_dept_list        Departments cursor
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/03/04
    ********************************************************************************************/
    FUNCTION get_appointment_dept_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN dept.id_institution%TYPE,
        o_dept_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Appointment Service List 
    *
    * @param i_lang             Preferred language ID
    * @param i_id_dept          Department ID
    * @param o_service_list     Services cursor
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/03/04
    ********************************************************************************************/
    FUNCTION get_appointment_service_list
    (
        i_lang         IN language.id_language%TYPE,
        i_id_dept      IN dept.id_dept%TYPE,
        o_service_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Relation(Service/Clinical Service) Previous nurse contact information
    *
    * @param i_lang          Preferred language ID
    * @param i_id_dept       Department ID
    * @param i_id_department Service ID
    * @param o_dcs           Clinical services
    * @param o_error         Error
    *
    * @return                true or false on success or error
    * 
    *
    * @author                JTS
    * @version               0.1
    * @since                 2009/03/04
    ********************************************************************************************/
    FUNCTION get_dcs_nurse_pre_list
    (
        i_lang          IN language.id_language%TYPE,
        i_id_dept       IN dept.id_dept%TYPE,
        i_id_department IN dep_clin_serv.id_department%TYPE,
        o_dcs           OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update Relation(Service/Clinical Service) Previous nurse contact information
    *
    * @param i_lang             Preferred language ID
    * @param i_dcs              Relation(Service/Clinical Service) ID's
    * @param i_nurse_pre        Previous nurse contact indication
    * @param o_dcs              Relation(Service/Clinical Service) ID's
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/03/04
    ********************************************************************************************/
    FUNCTION set_dcs_nurse_pre
    (
        i_lang      IN language.id_language%TYPE,
        i_dcs       IN table_number,
        i_nurse_pre IN table_varchar,
        o_dcs       OUT table_number,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set institution affiliations values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_institution   Institution ID
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_inst_affiliations
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_accounts       IN table_number,
        i_values         IN table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Professional affiliations values
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    * 
    *
    * @author                   JTS
    * @version                  0.1
    * @since                    2009/03/05
    ********************************************************************************************/
    FUNCTION set_prof_affiliations
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_institution     IN table_number,
        i_accounts        IN table_number,
        i_values          IN table_varchar,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institutions Country affiliations
    *
    * @param i_lang                Preferred language ID
    * @param i_id_institution      Institution ID
    * @param i_id_country          Country ID
    * @param o_inst_affiliations   Affiliations cursor
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_inst_ctry_affiliations
    (
        i_lang              IN language.id_language%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        i_id_country        IN country.id_country%TYPE,
        o_inst_affiliations OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional Category affiliations
    *
    * @param i_lang                Preferred language ID
    * @param i_id_professional     Professional ID
    * @param i_id_category         Category ID
    * @param o_prof_affiliations   Affiliations cursor
    * @param o_error               Error
    *
    * @return                      true or false on success or error
    * 
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/03/05
    ********************************************************************************************/
    FUNCTION get_prof_cat_affiliations
    (
        i_lang              IN language.id_language%TYPE,
        i_id_professional   IN professional.id_professional%TYPE,
        i_id_category       IN category.id_category%TYPE,
        i_id_institution    IN institution.id_institution%TYPE,
        o_prof_affiliations OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the market associated with a given instituition
    *
    * @param i_lang              Language
    * @param i_id_institution    Professional array
    *
    * @param o_id_market         Market id 
    * @param o_error             Error information
    
    * @return                    Return BOOLEAN 
    *
    * @author                    Sérgio Cunha
    * @version                   2.5
    * @since                     25/05/2009
    ********************************************************************************************/
    FUNCTION get_institution_market
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_market         OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the color associated to a given dep_clin_serv
    *
    * @param i_lang              Language
    * @param i_prof              Professional array
    * @param i_id_institution    Institution ID
    * @param i_dcs               Dep_clin_serv ID
    * @param o_color             Color 
    * @param o_error             Error information
    
    * @return                    Return BOOLEAN 
    *
    * @author                    Sérgio Cunha
    * @version                   2.5.0.4
    * @since                     05/06/2009
    ********************************************************************************************/
    FUNCTION get_dcs_color
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_color          OUT sch_color.color_hex%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get the info associated to a given dep_clin_serv
    *
    * @param i_lang              Language
    * @param i_prof              Professional array
    * @param i_id_institution    Institution ID
    * @param i_dcs               Dep_clin_serv ID
    * @param o_dcs_info          Dep_clin_serv info
    * @param o_dcs_pre_exams     Dep_clin_serv pre exams
    * @param o_error             Error information
    
    * @return                    Return BOOLEAN 
    *
    * @author                    Sérgio Cunha
    * @version                   2.5.0.4
    * @since                     05/06/2009
    ********************************************************************************************/
    FUNCTION get_dcs_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_dcs_info       OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set the edited info to a given dep_clin_serv
    *
    * @param i_lang              Language
    * @param i_prof              Professional array
    * @param i_id_institution    Institution ID
    * @param i_dcs               Dep_clin_serv ID
    * @param i_color             Color (Hex)
    * @param i_desc_code         Dep_clin_serv description
    * @param i_flg_nurse_pre     Dep_clin_serv info
    * @param i_flg_coding        Dep_clin_serv coding info
    * @param o_error             Error information
    
    * @return                    Return BOOLEAN 
    *
    * @author                    Sérgio Cunha
    * @version                   2.5.0.4
    * @since                     05/06/2009
    ********************************************************************************************/
    FUNCTION set_dcs_info
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        i_dcs            IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_color          IN sch_color.color_hex%TYPE,
        i_flg_nurse_pre  IN dep_clin_serv.flg_nurse_pre%TYPE,
        i_flg_coding     IN dep_clin_serv.flg_coding%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get State List
    *
    * @param i_lang                Prefered language ID
    * @param i_code_domain         Code to obtain Options
    * @param i_code_message        Code message to be at 1st position of list
    * @param i_val                 Val to Code message to be at 1st position of list
    * @param o_list                List od states
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      SC
    * @version                     0.1
    * @since                       17/02/2009
    ********************************************************************************************/
    FUNCTION get_message_state_list
    (
        i_lang         IN language.id_language%TYPE,
        i_code_domain  sys_domain.code_domain%TYPE,
        i_code_message sys_message.code_message%TYPE,
        i_val          sys_message.flg_type%TYPE,
        o_list         OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Room Slot
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional identification
    * @param i_dep_clin_serv       Service/Speciality identification
    * @param o_room                Room Output
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Susana Silva
    * @version                     2.5.0.4
    * @since                       21/07/2009
    ********************************************************************************************/

    FUNCTION get_room_slot
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_room          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional attributes from USA
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_prof_attr           Cursor with profissional attributes
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/09/22
    ********************************************************************************************/
    FUNCTION get_prof_attributes_usa
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Professional attributes
    *
    * @param i_lang                Prefered language ID
    * @param i_prof                Professional type (ID, INST, SOFTWARE)
    * @param i_id_professional     Professional ID
    * @param i_id_institution      Institution ID
    * @param o_prof_attr           Cursor with profissional attributes
    * @param o_error               Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/09/22
    ********************************************************************************************/
    FUNCTION get_prof_attributes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Get Professional attributes (CDA)
      *
      * @param i_lang                Prefered language ID
      * @param i_prof                Professional type (ID, INST, SOFTWARE)
      * @param i_id_professional     Professional ID
      * @param i_id_institution      Institution ID
      * @param o_prof_attr           Cursor with profissional attributes
      * @param o_error               Error
      *
      *
      * @return                      true or false on success or error
      *
      * @author                      André Silva
    * @version             2.7.0.0
      * @since                       2016/12/21
      ********************************************************************************************/
    FUNCTION get_prof_attributes_cda
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_attr       OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Institution Country ID
    *
    * @param i_lang                Prefered language ID
    * @param i_id_institution      Institution ID
    * @param O_error               Error
    *
    *
    * @return                      Country ID
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/09/22
    ********************************************************************************************/
    FUNCTION get_institution_country
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN inst_attributes.id_country%TYPE;

    /********************************************************************************************
    * Find a professional based on accounts values
    *
    * @param i_lang                  Prefered language ID
    * @param i_accounts              Accounts ID's
    * @param i_accounts_val          Accounts values
    * @param o_professional          Professional ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2009/12/12
    ********************************************************************************************/

    FUNCTION get_id_professional
    (
        i_lang         IN language.id_language%TYPE,
        i_accounts     IN table_number,
        i_accounts_val IN table_varchar,
        o_professional OUT professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Find an institution based on accounts values
    *
    * @param i_lang                  Prefered language ID
    * @param i_accounts              Accounts ID's
    * @param i_accounts_val          Accounts values
    * @param o_institution           Institution ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2009/12/12
    ********************************************************************************************/

    FUNCTION get_id_institution
    (
        i_lang         IN language.id_language%TYPE,
        i_accounts     IN table_number,
        i_accounts_val IN table_varchar,
        o_institution  OUT professional.id_professional%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Update/insert information for an external user
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_title                 Professional Title
    * @param i_first_name            Professional first name
    * @param i_middle_name           Professional middle name
    * @param i_last_name             Professional last name
    * @param i_nickname              Professional Nickname
    * @param i_initials              Professional initials
    * @param i_dt_birth              Professional Date of Birth
    * @param i_gender                Professioanl gender
    * @param i_marital_status        Professional marital status
    * @param i_id_speciality         Professional specialty
    * @param i_num_order             Professional license number
    * @param i_address               Professional adress
    * @param i_city                  Professional city
    * @param i_district              Professional district
    * @param i_zip_code              Professional zip code
    * @param i_id_country            Professional cpuntry
    * @param i_phone                 Professional phone
    * @param i_mobile_phone          Professional mobile phone
    * @param i_fax                   Professional fax
    * @param i_email                 Professional email
    * @param o_professional          Professional ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION set_ext_professional
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_title          IN professional.title%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_parent_name    IN professional.parent_name%TYPE,
        i_middle_name    IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE,
        i_nickname       IN professional.nick_name%TYPE,
        i_initials       IN professional.initials%TYPE,
        i_dt_birth       IN professional.dt_birth%TYPE,
        i_gender         IN professional.gender%TYPE,
        i_marital_status IN professional.marital_status%TYPE,
        i_id_speciality  IN professional.id_speciality%TYPE,
        i_num_order      IN professional.num_order%TYPE,
        i_address        IN professional.address%TYPE,
        i_city           IN professional.city%TYPE,
        i_district       IN professional.district%TYPE,
        i_zip_code       IN professional.zip_code%TYPE,
        i_id_country     IN professional.id_country%TYPE,
        i_phone          IN professional.work_phone%TYPE,
        i_num_contact    IN professional.num_contact%TYPE,
        i_mobile_phone   IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_commit_at_end  IN BOOLEAN,
        o_professional   OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create/Update external institution
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_institution        Institution ID
    * @param i_id_inst_att           Institution Attibutes ID
    * @param i_desc                  Institution name
    * @param i_id_parent             Parent Institution ID
    * @param i_flg_type              Flag type for institution - H - Hospital, C - Primary Care, P - Private Practice
    * @param i_abbreviation          Institution abbreviation
    * @param i_phone_number          Institution phone
    * @param i_fax                   Institution fax
    * @param i_email                 Institution email
    * @param i_ext_code              Institution Code
    * @param i_adress                Institution address
    * @param i_location              Institution location
    * @param i_district              Institution district
    * @param i_zip_code              Institution zip code
    * @param i_country               Institution Country ID
    * @param i_flg_available         Available - Y - Yes, N - No 
    * @param i_id_tz_region          Institution timezone ID    
    * @param i_id_market             Institution Market id
    * @param i_commit_at_end         Commit changes in this function - Y - Yes, N - No 
    * @param o_id_institution        institution ID
    * @param o_error                 error    
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION set_ext_institution
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_inst_att    IN inst_attributes.id_inst_attributes%TYPE,
        i_desc           IN VARCHAR2,
        i_id_parent      IN institution.id_parent%TYPE,
        i_flg_type       IN institution.flg_type%TYPE,
        i_abbreviation   IN institution.abbreviation%TYPE,
        i_phone_number   IN institution.phone_number%TYPE,
        i_fax            IN institution.fax_number%TYPE,
        i_email          IN inst_attributes.email%TYPE,
        i_ext_code       IN institution.ext_code%TYPE,
        i_adress         IN institution.address%TYPE,
        i_location       IN institution.location%TYPE,
        i_district       IN institution.district%TYPE,
        i_zip_code       IN institution.zip_code%TYPE,
        i_country        IN inst_attributes.id_country%TYPE,
        i_flg_available  IN institution.flg_available%TYPE,
        i_id_tz_region   IN institution.id_timezone_region%TYPE,
        i_id_market      IN market.id_market%TYPE,
        i_commit_at_end  IN BOOLEAN,
        o_id_institution OUT institution.id_institution%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Institution Professional state
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_flg_state             Professional state
    * @param i_num_mecan             Mecan. Number
    * @param o_flg_state             Professional state
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION set_prof_institution
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_institution.id_professional%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_flg_state       IN prof_institution.flg_state%TYPE,
        i_num_mecan       IN prof_institution.num_mecan%TYPE,
        o_flg_state       OUT prof_institution.flg_state%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Institution Professional Category
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_prof               Professional ID
    * @param i_id_institution        Institution ID
    * @param i_id_category           Professional Category
    * @param i_id_cat_surgery        Professional Category In Surgery
    * @param i_commit_at_end         Commit changes in this function - Y - Yes, N - No 
    * @param o_id_prof               Professional state
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2009/12/14
    ********************************************************************************************/
    FUNCTION set_prof_cat
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_category    IN category.id_category%TYPE,
        i_id_cat_surgery IN category.id_category%TYPE,
        i_commit_at_end  IN BOOLEAN,
        o_id_prof        OUT professional.id_professional%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Find an institution based on accounts values
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param o_username              Username
    * @param o_error                 error    
    *
    *
    * @return                      Professional Username
    *
    * @author                      Tércio Soares
    * @version                     0.1
    * @since                       2010/01/06
    ********************************************************************************************/
    FUNCTION get_prof_username
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        o_username        OUT ab_user_info.login%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Department Floors
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_department         Service ID
    * @param i_id_institution        Institution ID
    * @param o_floors_desc           Associated floors description 
    * @param o_floors_list           Floors list
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2010/03/01
    ********************************************************************************************/
    FUNCTION get_floors_department
    (
        i_lang           IN language.id_language%TYPE,
        i_id_department  IN department.id_department%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_floors_desc    OUT VARCHAR2,
        o_floors_list    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. get_floors_institution
    * 
    * @param i_lang                    Language identification
    * @param i_id_department           Department id
    * @param o_id_floors_institution   id_floors_institution list
    * @param o_error                   Error
    *
    * @return                          True or False
    *
    * @raises                          PL/SQL generic error "OTHERS"
    *
    * @author                          Amanda Lee
    * @version                         2.7.3.6
    * @since                           2018/06/20
    */
    FUNCTION get_floors_institution
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_department         IN floors_department.id_department%TYPE,
        o_id_floors_institution OUT table_number,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get Room Floors List
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_department         Service ID
    * @param i_id_institution        Institution ID
    * @param i_id_room               Room ID
    * @param o_floors_desc           Associated floors description 
    * @param o_floors_list           Floors list
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2010/03/01
    ********************************************************************************************/
    FUNCTION get_room_floors_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_department  IN department.id_department%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_room        IN room.id_room%TYPE,
        o_floors_desc    OUT VARCHAR2,
        o_floors_list    OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Institution Professional Preferences
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_id_language           Language ID
    * @param i_commit_at_end         Commit changes in this function - Y - Yes, N - No 
    * @param o_id_professional       Professional ID
    * @param o_error                 Error
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.3.4
    * @since                       2010/10/15
    ********************************************************************************************/
    FUNCTION set_prof_preferences
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        i_id_language     IN prof_preferences.id_language%TYPE,
        i_commit_at_end   IN BOOLEAN,
        o_id_professional OUT professional.id_professional%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Professional institution relations (internal or external)
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_institutions          Institution ID's
    * @param i_flg_state             Professional status in institutions
    * @param i_num_mecan             Mecan. Number's
    * @param i_dt_begin_tstz         Begin dates
    * @param i_dt_end_tstz           End dates
    * @param i_flg_external          External relation? Y - External, N- internal
    * @param i_commit_at_end         Commit changes in this function - Y - Yes, N - No
    * @param o_prof_institutions     Professional/institution relation id's
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.4
    * @since                       2010/11/22
    ********************************************************************************************/
    FUNCTION set_prof_institutions
    (
        i_lang              IN language.id_language%TYPE,
        i_id_professional   IN prof_institution.id_professional%TYPE,
        i_institutions      IN table_number,
        i_flg_state         IN table_varchar,
        i_num_mecan         IN table_varchar,
        i_dt_begin_tstz     IN table_timestamp,
        i_dt_end_tstz       IN table_timestamp,
        i_flg_external      IN prof_institution.flg_external%TYPE,
        i_commit_at_end     IN BOOLEAN,
        o_prof_institutions OUT table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set Institution Professional state
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_flg_state             Professional state
    * @param i_num_mecan             Mecan. Number
    * @param i_dt_begin_tstz         Begin date
    * @param i_dt_end_tstz           End date
    * @param i_flg_external          External professional? Y - Yes, N - No
    * @param o_prof_institution      Professional/institution relation ID
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     2.6.0.4
    * @since                       2010/11/22
    ********************************************************************************************/
    FUNCTION set_prof_institution
    (
        i_lang             IN language.id_language%TYPE,
        i_id_professional  IN prof_institution.id_professional%TYPE,
        i_id_institution   IN prof_institution.id_institution%TYPE,
        i_flg_state        IN prof_institution.flg_state%TYPE,
        i_num_mecan        IN prof_institution.num_mecan%TYPE,
        i_dt_begin_tstz    IN prof_institution.dt_begin_tstz%TYPE,
        i_dt_end_tstz      IN prof_institution.dt_end_tstz%TYPE,
        i_flg_external     IN prof_institution.flg_external%TYPE,
        o_prof_institution OUT prof_institution.id_prof_institution%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /************************************************************************************************************ 
    * Returns the description for a sys_domain
    *
    * @param      i_id_institution                  Institution ID
    *
    * @return     Language Full Description
    * @author     Mauro Sousa
    * @version    0.1
    * @since      2011/02/08
    ***********************************************************************************************************/
    FUNCTION get_institution_language
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    /************************************************************************************************************ 
    * Returns the description for a sys_domain
    *
    * @param      i_id_professional            Professional ID
    * @param      i_id_institution             Institution ID
    *
    * @return     Language Full Description
    * @author     Mauro Sousa
    * @version    0.1
    * @since      2011/02/09
    ***********************************************************************************************************/
    FUNCTION get_prof_language
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get sis pre natal current serie
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_serie
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN t_rec_serie;

    /********************************************************************************************
    * Get sis pre natal active serie
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  Series List
    * @param o_msg                   Message of % available 
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_serie
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Checks if a number is contained inside one of the institution series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_current_number        Series number that will be assessed
    * @param i_code_state            State code
    * @param i_geo_state             State ID
    *
    * @return                        this sisprenatal code is contained in the serie? (Y)es or (N)o
    *
    * @author                        José Silva
    * @version                       2.5.1.9
    * @since                         2011/11/17
    ********************************************************************************************/
    FUNCTION check_inst_serie_number
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_current_number IN series.current_number%TYPE,
        i_code_state     IN geo_state.code_state%TYPE,
        i_geo_state      IN geo_state.id_geo_state%TYPE,
        i_code_year      IN series.series_year%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get sis pre natal active serie current number
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_serie_current_number
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_code_state      IN geo_state.code_state%TYPE,
        i_year            IN series.series_year%TYPE,
        i_starting_number IN series.starting_number%TYPE,
        i_ending_number   IN series.ending_number%TYPE
    ) RETURN series.current_number%TYPE;

    /********************************************************************************************
    * Set sis pre natal active serie current number
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_code_state            Country state code
    * @param i_year                  Series year
    * @param i_current_number        Series current number
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_serie_current_number
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_code_state     IN geo_state.code_state%TYPE,
        i_year           IN series.series_year%TYPE,
        i_current_number IN series.current_number%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get states of a country
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_state_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Creates/Edit a new series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_series             Series ID
    * @param i_code_state            Official code state
    * @param i_year                  Series Year
    * @param i_starting_number       Series starting number
    * @param i_ending_number         Series ending number
    * @param i_flg_status            Series status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_pre_natal_serie
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_series       IN series.id_series%TYPE,
        i_id_geo_state    IN geo_state.id_geo_state%TYPE,
        i_year            IN series.series_year%TYPE,
        i_starting_number IN series.starting_number%TYPE,
        i_current_number  IN series.current_number%TYPE,
        i_ending_number   IN series.ending_number%TYPE,
        o_msg             OUT sys_message.desc_message%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Sets pre natal series status
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_series             Series ID
    * @param i_flg_status            Series status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION set_pre_natal_serie_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_flg_status IN series.flg_status%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get next series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_next_id_series        Series next ID
    * @param o_current_year          Current year
    * @param o_msg_atributed         Message attributed numbers (N/A)
    * @param o_msg_available         Message available numbers (N/A)
    * @param o_flg_status            Series flag status
    * @param o_desc_status           Series desc status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_next_pre_natal_serie
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_next_id_series OUT series.id_series%TYPE,
        o_current_year   OUT series.series_year%TYPE,
        o_msg_atributed  OUT sys_message.desc_message%TYPE,
        o_msg_available  OUT sys_message.desc_message%TYPE,
        o_code_state     OUT geo_state.code_state%TYPE,
        o_desc_state     OUT pk_translation.t_desc_translation,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get pre natal series available status
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  List of status
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_series_available_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_list       OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get sis pre natal series
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  Series List
    * @param o_msg                   Message of % available 
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_pre_natal_series_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_msg   OUT sys_message.desc_message%TYPE,
        o_mask  OUT sys_config.value%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get pre natal series available actions
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param o_list                  List of actions
    * @param o_error                 error
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_series_actions
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_series  IN series.id_series%TYPE,
        i_subject    IN action.subject%TYPE,
        i_from_state IN action.from_state%TYPE,
        o_actions    OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * This procedure performs cpoe specific tasks (to be called by an oracle job)
    *
    * @return                        true or false on success or error
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    PROCEDURE series_job_validator;

    /********************************************************************************************
    * Get geo_state table id
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_code_state            List of actions
    *
    * @return                        id_geo_state
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/07
    ********************************************************************************************/
    FUNCTION get_geo_state_id
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_code_state IN geo_state.code_state%TYPE
    ) RETURN geo_state.id_geo_state%TYPE;

    /********************************************************************************************
    * Get code_state from geo_state table
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional ID
    * @param i_id_geo_state          Geo state ID 
    *
    * @return                        code_state
    *
    * @author                        Álvaro Vasconcelos   
    * @version                       2.5.1.5
    * @since                         2011/04/29
    ********************************************************************************************/
    FUNCTION get_code_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_geo_state IN geo_state.code_state%TYPE
    ) RETURN geo_state.code_state%TYPE;
    /********************************************************************************************
    * Set Institution Professional state
    *
    * @param i_lang                  Prefered language ID
    * @param i_id_professional       Professional ID
    * @param i_id_institution        Institution ID
    * @param i_flg_state             Professional state
    * @param i_num_mecan             Mecan. Number
    * @param o_flg_state             Professional state
    * @param o_icon                  Professional state icon
    *
    *
    * @return                      true or false on success or error
    *
    * @author                      JTS
    * @version                     0.1
    * @since                       2008/06/02
    ********************************************************************************************/
    FUNCTION set_intf_prof_inst_state
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN prof_institution.id_professional%TYPE,
        i_id_institution  IN prof_institution.id_institution%TYPE,
        i_flg_state       IN prof_institution.flg_state%TYPE,
        i_num_mecan       IN prof_institution.num_mecan%TYPE,
        o_flg_state       OUT prof_institution.flg_state%TYPE,
        o_icon            OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************ 
    * Returns the professional name formated
    *
    * @param      i_id_prof            Profissional type
    *
    * @return     Professional Name Formated
    * @author     RMGM
    * @version    2.6.0.5
    * @since      2012/01/11
    ***********************************************************************************************************/
    FUNCTION get_prof_name_formated
    (
        i_prof           IN table_number,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN table_varchar;
    /************************************************************************************************************ 
    * Returns True or False
    *
    * @param      i_id_professional     Professional id (if null update all in the institution)
    * @param      i_id_institution      Institution Id (mandatory)
    * @param      o_profs               output cursor with professional ids
    * @param      o_error               error
    *
    * @return     Boolean 1-true; 2-false;
    * @author     RMGM
    * @version    2.6.0.5
    * @since      2012/01/11
    ***********************************************************************************************************/
    FUNCTION set_prof_name_formated
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_profs           OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /************************************************************************************************************ 
    * Returns Formated complete name according to configured pattern in institution
    *
    * @param       i_lang                     Log Language
    * @param      i_id_institution      Institution Id (mandatory)
    * @param      i_first_name           first name
    * @param      i_midle_name           first name
    * @param      i_last_name           last name
    * @param      o_error               error
    *
    * @return     Formated complete name
    * @author     RMGM
    * @version    2.6.0.5
    * @since      2012/01/11
    ***********************************************************************************************************/
    FUNCTION create_name_formated
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_first_name     IN professional.first_name%TYPE,
        i_parent_name    IN professional.parent_name%TYPE,
        i_midle_name     IN professional.middle_name%TYPE,
        i_last_name      IN professional.last_name%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get Professional CAB CONV (FR Market)
    *
    * @param i_lang                Preferred language ID
    * @param i_prof                Professional Data Type
    *
    * @return                      String with Identifier
    * 
    *
    * @author                      RMGM
    * @version                     0.1
    * @since                       2012/09/18
    ********************************************************************************************/
    FUNCTION get_cab_conv_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR2;
    FUNCTION get_domain_desc_str
    (
        i_code_domain IN sys_domain.code_domain%TYPE,
        i_value       IN prof_accounts.value%TYPE,
        i_lang        IN language.id_language%TYPE
    ) RETURN VARCHAR2;
    /************************************************************************************************************ 
    * Returns True or False
    *
    * @param       i_lang                     Log Language
    * @param      i_id_department             Service ID
    * @param      i_floors_institution        Floors Institution to relate to service array
    * @param      i_change                    Array indexed to floors_institution showing if we remove or add association
    * @param      o_error                     error
    *
    * @return     Boolean 1-true; 0-false;
    * @author     RMGM
    * @version    2.6.3
    * @since      2013/02/26
    ***********************************************************************************************************/
    FUNCTION set_department_floors
    (
        i_lang               IN language.id_language%TYPE,
        i_id_department      IN department.id_department%TYPE,
        i_floors_institution IN table_number,
        i_change             IN table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_department_floors
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_department        IN department.id_department%TYPE,
        i_floors_institution   IN table_number,
        i_change               IN table_varchar,
        o_id_floors_department OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*********************************************************************************************
    * Get decoded description for professional title
    *
    * @param i_lang                     Aplication language ID
    * @param i_title                    Professional Title recorded value   
    *
    * @return                           Decoded description
    *
    * @author                           RMGM
    * @version                          2.5.2.7
    * @since                            2013/01/18
    ********************************************************************************************/
    FUNCTION get_prof_title_desc
    (
        i_lang  IN language.id_language%TYPE,
        i_title IN professional.title%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Set Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION set_professional_br
    (
        i_lang               IN language.id_language%TYPE,
        i_id_prof            IN professional.id_professional%TYPE,
        i_id_cpf             IN professional.id_cpf%TYPE,
        i_id_cns             IN professional.id_cns%TYPE,
        i_mother_name        IN professional.mother_name%TYPE,
        i_father_name        IN professional.father_name%TYPE,
        i_id_gstate_birth    IN professional.id_geo_state_birth%TYPE,
        i_id_city_birth      IN professional.id_district_birth%TYPE,
        i_code_race          IN professional.code_race%TYPE,
        i_code_school        IN professional.code_scoolarship%TYPE,
        i_flg_in_school      IN professional.flg_in_school%TYPE,
        i_code_logr          IN professional.code_logr_type%TYPE,
        i_door_num           IN professional.door_number%TYPE,
        i_address_ext        IN professional.address_extension%TYPE,
        i_id_gstate_adress   IN professional.id_geo_state_adress%TYPE,
        i_id_city_adress     IN professional.id_district_adress%TYPE,
        i_adress_area        IN professional.adress_area%TYPE,
        i_code_banq          IN professional.code_banq%TYPE,
        i_desc_agency        IN professional.desc_banq_ag%TYPE,
        i_banq_account       IN professional.id_banq_account%TYPE,
        i_code_certif        IN professional.code_certificate%TYPE,
        i_balcon_certif      IN professional.desc_balcony%TYPE,
        i_book_certif        IN professional.desc_book%TYPE,
        i_page_certif        IN professional.desc_page%TYPE,
        i_term_certif        IN professional.desc_term%TYPE,
        i_date_certif        IN VARCHAR2,
        i_id_document        IN professional.id_document%TYPE,
        i_balcon_doc         IN professional.code_emitant_cert%TYPE,
        i_id_gstate_doc      IN professional.id_geo_state_doc%TYPE,
        i_date_doc           IN VARCHAR2,
        i_code_crm           IN professional.code_emitant_crm%TYPE,
        i_id_gstate_crm      IN professional.id_geo_state_crm%TYPE,
        i_code_family_status IN professional.code_family_status%TYPE,
        i_code_doc_type      IN professional.code_doc_type%TYPE,
        i_prof_ocp           IN professional.id_prof_formation%TYPE,
        i_other_doc_desc     IN professional.other_doc_desc%TYPE,
        i_healht_plan        IN professional.id_health_plan%TYPE,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION get_professional_br
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN institution.id_institution%TYPE,
        o_prof_br         OUT pk_types.cursor_type,
        o_prof_inst_br    OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_id_professional  Professional ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param i_values           Affiliations Values
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/12
    ********************************************************************************************/
    FUNCTION check_prof_br_uk_data
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_cpf          IN professional.id_cpf%TYPE,
        i_id_ident        IN professional.id_document%TYPE,
        i_emitant_id      IN professional.code_emitant_cert%TYPE,
        i_id_gstate_doc   IN professional.id_geo_state_doc%TYPE,
        i_code_crm        IN professional.code_emitant_crm%TYPE,
        i_id_gstate_crm   IN professional.id_geo_state_crm%TYPE,
        i_num_order       IN professional.num_order%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional Bond domain BR Fields (SBIS)
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional array ID
    * @param i_level            Bond level (1 bond, 2 type, 3 subtype)
    * @param i_bond_id          Parent id, null when level = 1
    * @param o_res_list         cursor with ordered results
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *    
    * @author                   RMGM
    * @version                  0.1
    * @since                    2013/11/14
    ********************************************************************************************/
    FUNCTION get_bond_values
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_level    IN NUMBER DEFAULT 1,
        i_bond_id  IN NUMBER DEFAULT NULL,
        o_res_list OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN;
    -- desc_bond_subtype
    FUNCTION get_bond_subt_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN translation.desc_lang_1%TYPE;
    FUNCTION get_bond_subt_id
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN professional_bond.id_bond%TYPE;
    -- desc_bond_type
    FUNCTION get_bond_type_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN translation.desc_lang_1%TYPE;
    FUNCTION get_bond_type_id
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN professional_bond.id_bond%TYPE;
    -- desc_bond
    FUNCTION get_bond_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN translation.desc_lang_1%TYPE;
    FUNCTION get_bond_id
    (
        i_lang       IN language.id_language%TYPE,
        i_id_bond_st IN professional_bond.id_bond%TYPE
    ) RETURN professional_bond.id_bond%TYPE;
    --decode levels of stored value
    FUNCTION get_bond_levels(i_last IN professional_bond.id_bond%TYPE) RETURN NUMBER;

    FUNCTION check_prof_acount_value
    (
        i_value           IN prof_accounts.value%TYPE,
        i_account         IN prof_accounts.id_account%TYPE,
        i_institution     IN prof_accounts.id_institution%TYPE,
        i_id_professional IN prof_accounts.id_professional%TYPE
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Professional CBO ID
    *
    * @param i_lang                  Prefered language ID
    * @param i_prof                  Professional Type Identifier
    * @param o_error                 error
    *
    * @return                        CBO code
    *
    * @author                        Rui Gomes
    * @version                       2.5.2.7
    * @since                         2013/01/28
    ********************************************************************************************/
    FUNCTION get_prof_cbo_id
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_error OUT t_error_out
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_institution            Institution ID
    * @param i_id_professional        Professional ID
    * @param o_prof_id_list           List of professionals ids
    * @param o_prof_desc_list         list of professional names indexed to ids
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION get_serv_prof_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        i_flg_type       IN department_resp_prof.flg_type%TYPE,
        o_prof_id_list   OUT table_number,
        o_prof_desc_list OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Set list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_id_professional        Professional ID
    * @param i_prof_id_list           List of professionals ids
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION set_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id_list  IN table_number,
        i_prof_service  IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if a professional is already responsible for a service
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION check_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if a professional is already responsible for a service and return identifier char
    *
    * @param i_lang                   Preferred language ID for this professional
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION check_serv_prof_resp_chr
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE
    ) RETURN VARCHAR;
    /********************************************************************************************
    * Set list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION set_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete responsible professional in a service context
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION delete_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN professional.id_professional%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Delete a list of responsible professionals in a service context
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/10
    **********************************************************************************************/
    FUNCTION delete_serv_prof_resp
    (
        i_lang          IN language.id_language%TYPE,
        i_id_department IN department.id_department%TYPE,
        i_prof_id       IN table_number,
        i_prof_service  IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get a list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_serv_physician_list
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        o_prof_list      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get list of professional physicians in a service context to turn as responsible
    *
    * @param i_lang                   Preferred language ID for this professional    
    * @param i_id_department          Service ID
    * @param i_prof_id                Professional id list
    * @param o_error                  Error Message ID
    *
    * @return                         true or false
    *
    * @author                         RMGM
    * @version                        2.6.3
    * @since                          2014/02/11
    **********************************************************************************************/
    FUNCTION get_service_responsible_map
    (
        i_lang            IN language.id_language%TYPE,
        i_id_dept         IN dept.id_dept%TYPE,
        i_id_professional IN department.id_department%TYPE,
        o_result_list     OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Institution accounts values
    *
    * @param i_lang             Preferred language ID
    * @param i_institution      Institution ID's
    * @param i_accounts         Affiliations ID's
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2012/02/17
    ********************************************************************************************/
    FUNCTION get_inst_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Get Professional account values
    *
    * @param i_lang             Preferred language ID
    * @param i_prof_id          Professional ID
    * @param i_institution      Institution ID
    * @param i_accounts         Affiliations ID
    * @param o_error            Error
    *
    * @return                   true or false on success or error
    *
    *
    * @author                   RMGM
    * @version                  0.1
    * @since                    2012/02/17
    ********************************************************************************************/
    FUNCTION get_prof_account_val
    (
        i_lang        IN language.id_language%TYPE,
        i_prof_id     IN professional.id_professional%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_account     IN accounts.id_account%TYPE,
        o_error       OUT t_error_out
    ) RETURN VARCHAR2;
    /*
    Method that returns scholarship list of values by market and language translation
    */
    FUNCTION get_scholarship_mkt
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        o_schol_res      OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_scholarship_group
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_institution       IN institution.id_institution%TYPE,
        i_id_scholarship_group IN professional.id_agrupacion%TYPE,
        o_list                 OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************
    * Method to create professional specializations/ affiliations string
    *
    * i_lang                        language identifier
    * i_id_professional             professional list
    * i_id_institution              institution identifier
    *
    * return varchar
    *
    ******************************************************/
    FUNCTION get_prof_resp_af_data
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN table_number,
        i_id_institution  IN institution.id_institution%TYPE
    ) RETURN VARCHAR2;
    /********************************************************************************************
    * Returns the Professional facility IDentifier (Mecanografic number)
    *
    * @param      i_lang                     Language identification
    * @param      i_prof                     Professional identification Array
    * @param      o_mec_num                  Identifier output
    * @param      o_error                    Error
    *
    * @return                         true or false on success or error
    *
    * @author                          Rui Gomes
    * @version                         2.6.4.1
    * @since                           2014/07/08
    **********************************************************************************************/
    FUNCTION get_prof_inst_mec_num
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_flg_active IN VARCHAR2 DEFAULT NULL,
        o_mec_num    OUT prof_institution.num_mecan%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Institution National identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @param i_id_prefix        National Id context
    *
    * @return                   Value
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_inst_finess
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN VARCHAR;
    /********************************************************************************************
    * Get Institution National identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @param i_id_prefix        National Id context
    *
    * @return                   Value
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_inst_natid
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar;
    /********************************************************************************************
    * Get Professional National identifier
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @param i_id_prefix        National Id context
    *
    * @return                   Value
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_prof_natid
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN table_varchar;
    /********************************************************************************************
    * Get VHIF data
    *
    * @param i_lang             Preferred language ID
    * @param i_prof             Professional Array
    * @param i_inst_nat_prefix  National institution Id context
    * @param i_prof_nat_prefix  National Professional Id context
    * @o_prof_name              professional name
    * @o_prof_spec              professional Speciality
    * @o_prof_role              professional Role
    * @o_prof_idnat             professional National identifier
    * @o_inst_type              Institution Type
    * @o_inst_serial            Institution Serial
    * @o_inst_idnat             Institution National identifier
    * @o_prod_vers              alert version
    * @o_sw_name                software Name,
    * @o_sw_cert_id             Software certification identifier
    *
    * @return                   True or False
    *
    * @author                   RMGM
    * @version                  2.6.4.2
    * @since                    2014/09/23
    ********************************************************************************************/
    FUNCTION get_prof_vhif_data
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_prof_name   OUT professional.name%TYPE,
        o_prof_spec   OUT speciality.id_content%TYPE,
        o_prof_role   OUT category.id_content%TYPE,
        o_prof_idnat  OUT table_varchar,
        o_inst_type   OUT institution.flg_type%TYPE,
        o_inst_serial OUT institution.id_institution%TYPE,
        o_inst_idnat  OUT table_varchar,
        o_prod_vers   OUT alert_version.version%TYPE,
        o_sw_name     OUT software.intern_name%TYPE,
        o_sw_cert_id  OUT sys_config.value%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get Operation identifier in professional History
    *
    * @param i_id_professional  Professional identifier
    *
    * @return                   Operation Identifier
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/03
    ********************************************************************************************/
    FUNCTION get_prof_hist_pk(i_id_professional IN professional.id_professional%TYPE) RETURN NUMBER;
    /********************************************************************************************
    * Insert New Professional information in History table
    *
    * @param i_id_professional  Professional identifier
    * @param i_operation_type   type of operation being made (C - create; U - update; R - removal)
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/03
    ********************************************************************************************/
    PROCEDURE ins_professional_hist
    (
        i_id_professional IN professional.id_professional%TYPE,
        i_operation_type  IN professional_hist.operation_type%TYPE
    );
    /********************************************************************************************
    * Insert New Professional information in History table
    *
    * @param i_id_professional  List of Professional identifiers
    * @param i_operation_type   type of operation being made (C - create; U - update; R - removal)
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/03
    ********************************************************************************************/
    PROCEDURE ins_professional_hist
    (
        i_tbl_professional IN table_number,
        i_operation_type   IN professional_hist.operation_type%TYPE
    );

    PROCEDURE ins_prof_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN prof_doc.id_institution%TYPE,
        i_doc_type        IN prof_doc.id_doc_type%TYPE,
        i_doc_num         IN prof_doc.value%TYPE,
        i_doc_ident_val   IN VARCHAR2
    );

    PROCEDURE upd_prof_doc
    (
        i_lang            IN language.id_language%TYPE,
        i_id_professional IN professional.id_professional%TYPE,
        i_id_institution  IN prof_doc.id_institution%TYPE,
        i_doc_type        IN prof_doc.id_doc_type%TYPE,
        i_doc_num         IN prof_doc.value%TYPE,
        i_doc_ident_val   IN VARCHAR2
    );

    FUNCTION get_prof_doc_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Check if bleep number is valid according to institution configuration
    *
    * @param i_lang             Application language
    * @param i_prof          Professional identifier
    *
    * @return                   True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/04
    ********************************************************************************************/
    FUNCTION is_bleep_valid
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get prof_institution PK id
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_flg_sate        State of the professional in institution
    *            
    * @Return                  prof_institution PK
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION get_prof_institution_pk
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_flg_sate       IN prof_institution.flg_state%TYPE DEFAULT 'A'
    ) RETURN prof_institution.id_prof_institution%TYPE;
    /********************************************************************************************
    * Set contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param i_work_phone      Work phone Number value
    * @param i_home_phone      Home phone Number value
    * @param i_cell_phone      Celular phone Number value
    * @param i_fax             Fax Number value
    * @param i_email           Email adress value
    * @param i_bleep           Bleep number value
    * @param i_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION set_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_work_phone     IN professional.work_phone%TYPE,
        i_home_phone     IN professional.num_contact%TYPE,
        i_cell_phone     IN professional.cell_phone%TYPE,
        i_fax            IN professional.fax%TYPE,
        i_email          IN professional.email%TYPE,
        i_bleep          IN professional.bleep_number%TYPE,
        i_contact_det    IN prof_institution.contact_detail%TYPE,
        i_commit_trs     IN BOOLEAN DEFAULT TRUE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    * Get contact fields for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_id_prof         Professional identifier
    * @param i_id_institution  Institution identifier
    * @param o_work_phone      Work phone Number value
    * @param o_home_phone      Home phone Number value
    * @param o_cell_phone      Celular phone Number value
    * @param o_fax             Fax Number value
    * @param o_email           Email adress value
    * @param o_bleep           Bleep number value
    * @param o_contact_det     other contact details info
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    * @author                   RMGM
    * @version                  2.6.4
    * @since                    2015/03/05
    ********************************************************************************************/
    FUNCTION get_prof_contacts
    (
        i_lang           IN language.id_language%TYPE,
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN prof_institution.id_institution%TYPE,
        i_req_date       IN professional_hist.dt_operation%TYPE DEFAULT NULL,
        o_work_phone     OUT professional.work_phone%TYPE,
        o_home_phone     OUT professional.num_contact%TYPE,
        o_cell_phone     OUT professional.cell_phone%TYPE,
        o_fax            OUT professional.fax%TYPE,
        o_email          OUT professional.email%TYPE,
        o_bleep          OUT professional.bleep_number%TYPE,
        o_contact_det    OUT prof_institution.contact_detail%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get work phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.work_phone
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_work_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.work_phone%TYPE;

    /********************************************************************************************
    * Get home  phone contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.num_contact
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_home_phone_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.num_contact%TYPE;

    /********************************************************************************************
    * Get bleep number   contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/10
    ********************************************************************************************/

    FUNCTION get_prof_bleep_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.bleep_number%TYPE;

    /********************************************************************************************
    * Get cell number contact for professional
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_req_date        Date to get data from (null or default gets last data inputed)
    *            
    * @Return                   professional.bleep_number
    *
    * @author                   Joana Madureira Barroso
    * @version                  2.6.5
    * @since                    2015/04/14
    ********************************************************************************************/

    FUNCTION get_prof_cell_number_contact
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_req_date IN professional_hist.dt_operation%TYPE DEFAULT NULL
    ) RETURN professional.cell_phone%TYPE;

    /********************************************************************************************
    * Get all professionals (except responsible) allocated for a department
    *
    * @param i_lang            Prefered language ID
    * @param i_prof            Professional Array Identifier
    * @param i_id_department   Department identifier
    *
    * @param o_prof_id_list    List of professionals ids
    * @param o_prof_desc_list  list of professional names indexed to ids
    * @param o_error           Error object
    *
    * @author                  GS
    * @version                 2.6.5
    * @since                   2015/05/12
    ********************************************************************************************/
    FUNCTION get_serv_prof_not_responsible
    (
        i_lang           IN language.id_language%TYPE,
        i_id_institution IN institution.id_institution%TYPE,
        i_id_department  IN department.id_department%TYPE,
        o_prof_id_list   OUT table_number,
        o_prof_desc_list OUT table_varchar,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Function that return the flg_type department
    ** @param i_lang        the id language
    * @param i_prof         professional, software and institution ids
    * @param i_id_department department id
    **/
    FUNCTION get_department_type
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_id_department IN department.id_department%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_inst_field
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_id_institution IN NUMBER,
        i_field          IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_professional_br_report
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_id_prof IN professional.id_professional%TYPE,
        o_prof    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate email structure
    *
    * @param i_prof            Professional
    * @param i_email           Email adress value 
    *            
    * @Return                  True or False
    *
    * @author                   André Silva
    * @version                  2.7.1
    * @since                    2017/10/13
    ********************************************************************************************/
    FUNCTION validate_email
    (
        i_prof  IN profissional,
        i_email IN professional.email%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_name_translation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_name       IN name_translation.ocidental_name%TYPE,
        i_type       IN NUMBER,
        o_name_trans OUT name_translation.ocidental_name%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Validate phone number structure
    *
    * @param i_prof            Professional
    * @param i_work_phone      Work phone Number value
    * @param i_home_phone      Home phone Number value
    *            
    * @Return                  True or False
    *
    * @author                   André Silva
    * @version                  2.7.1
    * @since                    2017/10/13
    ********************************************************************************************/
    FUNCTION validate_phones
    (
        i_prof       IN profissional,
        i_work_phone IN professional.work_phone%TYPE,
        i_home_phone IN professional.num_contact%TYPE
    ) RETURN BOOLEAN;

    FUNCTION get_agrupacion
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Get all dep_clin_serv id to a Professional
    *
    * @param i_id_prof                  Professional identification
    * @param i_id_institution           Institution identification
    *
    * @return                           table_number of id_dep_clin_serv
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION get_prof_dcs
    (
        i_id_prof        IN professional.id_professional%TYPE,
        i_id_institution IN institution.id_institution%TYPE
    ) RETURN table_number;

    /**
    * Public Function. Get all dep_clin_serv id to a Professional
    *
    * @param i_lang                     Language identification
    * @param i_id_prof                  Professional identification
    * @param i_id_institution           Institution identification
    * @param o_id_dep_clin_serv         dep_clin_serv id list
    * @param o_error                    Error
    *
    * @return                           True or False
    *
    * @raises                           PL/SQL generic error "OTHERS"
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION get_prof_dcs
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Associate Specialties to a Professional without commit
    *
    * @param I_LANG                     Language identification
    * @param I_ID_PROF                  Professional identification
    * @param i_id_institution           Institution identification
    * @param i_id_dep_clin_serv         Relation between departments and clinical services
    * @param i_flg                      Flag
    * @param O_ERROR                    Error
    *
    * @value i_flg                      {*} 'Y' yes {*} 'N' No
    *
    * @return                           boolean
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/15
    */
    FUNCTION set_prof_specialties_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_prof          IN professional.id_professional%TYPE,
        i_id_institution   IN institution.id_institution%TYPE,
        i_id_dep_clin_serv IN table_number,
        i_flg              IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert room history record
    *
    * @param i_lang                      Language identification
    * @param i_prof                      Professional data
    * @param i_id_room                   Room ID (not null only for the edit operation)
    * @param i_room_name                 Room name
    * @param i_abbreviation              Room abbreviation
    * @param i_category                  Room category
    * @param i_room_type                 Room type
    * @param i_room_service              select room service
    * @param i_flg_selected_spec         Flag that indicates the type of selection of specialties
    * @param i_floors_department         Floors_department id
    * @param i_state                     Room's state
    * @param i_capacity                  Room's patient capacity
    * @param i_rank                      Room's rank
    * @param o_id_room_hist              Room's change_hist id
    * @param o_error                     Error
    *
    * @value i_category                 {*} 'P' l_flg_prof=Y {*} 'R' l_flg_recovery=Y
    *                                   {*} 'L' l_flg_lab=Y  {*} 'W' l_flg_wait=Y
    *                                   {*} 'C' l_flg_wl=Y   {*} 'T' l_flg_transp=Y
    *                                   {*} 'I' l_flg_icu=Y
    * 
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.5
    * @since                            2018/06/05
    */
    FUNCTION set_room_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_room           IN room.id_room%TYPE,
        i_room_name         IN VARCHAR2,
        i_abbreviation      IN VARCHAR2,
        i_category          IN table_varchar,
        i_room_type         IN room_type.id_room_type%TYPE,
        i_room_service      IN room.id_department%TYPE,
        i_flg_selected_spec IN room.flg_selected_specialties%TYPE,
        i_floors_department IN floors_department.id_floors_department%TYPE,
        i_state             IN room.flg_available%TYPE,
        i_capacity          IN room.capacity%TYPE,
        i_rank              IN room.rank%TYPE,
        o_id_room_hist      OUT room_hist.id_room_hist%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Insert New Relation Room/Dep Clinical Service
    *
    * @param i_lang                         Preferred language ID for this professional
    * @param i_prof                         Object (professional ID, institution ID, software ID)
    * @param i_id_room                      Room id
    * @param i_id_room_hist                 Room hist id
    * @param i_bed                          Bed id
    * @param i_bed_name                     Bed name
    * @param i_bed_type                     Bed type
    * @param i_bed_flg_selected_spec        Flg indicating the type of selection of specialties
    * @param i_bed_flg_available            Flg_bed_status
    * @param i_flg_parameterization_type    Type of parameterization used to create this data
    *
    * @value i_flg_selected_spec            {*} 'A' All {*} 'N' None {*} 'O' Other
    * @value i_bed_flg_available            {*} 'A' Active {*} 'I' Inactive
    * @value i_flg_parameterization_type    {*} 'C' configurations team {*} 'B' backoffice
    *
    * @return                               true or false on success or error
    *
    * @raises                               PL/SQL generic error "OTHERS"
    *
    * @author                               Amanda Lee
    * @version                              2.7.3.6
    * @since                                2018/06/14
    */
    FUNCTION set_bed_hist
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_room                   IN room.id_room%TYPE,
        i_id_room_hist              IN room_hist.id_room_hist%TYPE,
        i_id_bed                    IN bed.id_bed%TYPE,
        i_bed_name                  IN pk_translation.t_desc_translation,
        i_bed_type                  IN bed_type.id_bed_type%TYPE,
        i_bed_flg_selected_spec     IN VARCHAR2,
        i_bed_flg_available         IN bed.flg_available%TYPE,
        i_flg_bed_status            IN VARCHAR2,
        i_flg_parameterization_type IN bed.flg_parameterization_type%TYPE,
        o_id_bed_hist               OUT bed_hist.id_bed_hist%TYPE,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Insert the history of the bed_dep_clin_serv
    *
    * @param i_lang                     Preferred language ID for this professional
    * @param i_id_bed_hist              Bed ID History
    * @param i_id_bed                   Bed ID
    * @param o_error                    Error
    *
    * @return                           true or false on success or error
    *
    * @author                           Amanda Lee
    * @version                          2.7.3.6
    * @since                            2018/06/14
    */
    FUNCTION set_bed_dcs_hist
    (
        i_lang          IN language.id_language%TYPE,
        i_id_bed        IN bed.id_bed%TYPE,
        i_dep_clin_serv IN table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Institution Service OR Update Institution Service Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_DEPARTMENT                      Service identification
    * @param      I_ID_INSTITUTION                     Institution identification
    * @param      I_DESC                               Service description
    * @param      I_ABBREVIATION                       Abreviation
    * @param      I_FLG_TYPE                           Type: C - Outpatient, U - Emergency department, I - Inpatient, S - Operating Room, 
                                                             A - Analysis lab., P - Clinical patalogy lab., T - Pathological anatomy lab, 
                                                             R - Radiology, F - Pharmacy. 
                                                             It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    * @param      I_ID_DEPT                            Daepartment identification
    * @param      I_FLG_DEFAULT                        Default department: Y - Yes; N - No
    * @param      i_flg_available                      Department i_flg_available
    * @param      O_ID_DEPARTMENT                      Department identification
    * @param      o_id_floors_department               floors_department list
    * @param      O_ERROR                              Error
    *
    * @value       I_FLG_TYPE                          {*} 'C' Outpatient {*} 'U' Emergency department {*} 'I' Inpatient {*} 'S' Operating Room 
                                                       {*} 'A' Analysis lab. {*} 'P' Clinical patalogy lab. {*} 'T' Pathological anatomy lab 
                                                       {*} 'R' Radiology {*} 'F' Pharmacy. It may contain combinations (eg AP - Analyses of clinical pathology lab.)
    *
    * @value      I_FLG_DEFAULT                        {*} 'Y' Yes {*} 'N' No                                     
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/03/21
    */
    FUNCTION set_department_no_commit
    (
        i_lang                 IN language.id_language%TYPE,
        i_id_department        IN department.id_department%TYPE,
        i_id_institution       IN department.id_institution%TYPE,
        i_desc                 IN VARCHAR2,
        i_abbreviation         IN department.abbreviation%TYPE,
        i_flg_type             IN department.flg_type%TYPE,
        i_id_dept              IN department.id_dept%TYPE,
        i_flg_default          IN department.flg_default%TYPE,
        i_def_priority         IN department.flg_priority%TYPE,
        i_collection_by        IN department.flg_collection_by%TYPE,
        i_flg_available        IN department.flg_available%TYPE DEFAULT NULL,
        i_floors_institution   IN table_number,
        i_change               IN table_varchar,
        i_id_admission_type    IN admission_type.id_admission_type%TYPE,
        i_admission_time       IN VARCHAR2,
        o_id_department        OUT department.id_department%TYPE,
        o_id_floors_department OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /** @headcom
    * Public Function. Insert New Relation Department/Clinical Service Room OR Update Relation Department/Clinical Service Room Information
    *
    * @param      I_LANG                               Language identification
    * @param      I_ID_ROOM                            Room identification
    * @param      I_ID_DEP_CLIN_SERV                   Department/clinical service identification 
    * @param      O_ID_ROOM_DEP_CLIN_SERV              Cursor with rooms of departments/clinical services information
    * @param      O_ERROR                              Error 
    *
    * @return     boolean
    * @author     Tércio Soares - JTS
    * @version    0.1
    * @since      2007/04/23
    */
    FUNCTION set_room_dcs_no_commit
    (
        i_lang               IN language.id_language%TYPE,
        i_id_room            IN room_dep_clin_serv.id_room%TYPE,
        i_dep_clin_serv      IN table_number,
        o_room_dep_clin_serv OUT table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_current_id_room_hist(i_id_room IN room.id_room%TYPE) RETURN NUMBER;

    FUNCTION set_bed
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_room               IN room.id_room%TYPE,
        i_id_bed                IN bed.id_bed%TYPE,
        i_bed_name              IN pk_translation.t_desc_translation,
        i_bed_type              IN bed_type.id_bed_type%TYPE,
        i_bed_flg_selected_spec IN VARCHAR2,
        i_bed_flg_available     IN bed.flg_available%TYPE,
        i_bed_date              IN VARCHAR2 DEFAULT NULL,
        o_id_bed                OUT bed.id_bed%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_bed_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_id_bed        IN bed_dep_clin_serv.id_bed%TYPE,
        i_dep_clin_serv IN table_number,
        ---o_bed_dep_clin_serv OUT table_number,
        o_error OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_clinical_service_list
    (
        i_lang                     IN language.id_language%TYPE,
        o_id_clinical_service_list OUT table_number,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. set dep_clin_serv
    * 
    * @param i_lang                    Language identification
    * @param i_id_department           Insert department id
    * @param i_id_clin_service         Insert clinical service id list
    * @param o_id_dep_clin_serv        dep_clin_serv id list
    * @param o_error                   Error
    *
    * @return                          True or False
    *
    * @raises                          PL/SQL generic error "OTHERS"
    *
    * @author                          Amanda Lee
    * @version                         2.7.3.6
    * @since                           2018/06/20
    */
    FUNCTION set_dep_clin_serv_no_commit
    (
        i_lang             IN language.id_language%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_clin_service  IN table_number,
        o_id_dep_clin_serv OUT table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Create or update dept
    *
    * @param i_lang                      Language identification
    * @param i_id_dept                   Dept id
    * @param i_desc                      Dept name
    * @param i_id_institution            Institution identification
    * @param i_abbreviation              Department abbreviation
    * @param i_flg_available             Record availability
    * @param i_software                  Software identification
    * @param i_change                    Change
    * @param o_id_dept                   Dept id
    * @param o_error                     Error
    *
    * @value i_change                    {*} 'Y' Yes {*} 'N' No
    * @value i_flg_available             {*} 'Y' yes {*} 'N' No
    *
    *
    * @return                            true or false on success or error
    *
    * @raises                            PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                            Kelsey Lai
    * @version                           2.7.3.6
    * @since                             2018/06/19
    */
    FUNCTION set_dept_no_commit
    (
        i_lang           IN language.id_language%TYPE,
        i_id_dept        IN dept.id_dept%TYPE,
        i_dept_desc      IN VARCHAR2,
        i_id_institution IN dept.id_institution%TYPE,
        i_abbreviation   IN dept.abbreviation%TYPE,
        i_flg_available  IN dept.flg_available%TYPE DEFAULT NULL,
        i_software       IN table_number,
        i_change         IN table_varchar,
        o_id_dept        OUT dept.id_dept%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Create or update building
    *
    * @param i_lang                      Language identification
    * @param i_id_building               Building id
    * @param i_building_desc             Building name
    * @param i_id_institution            Institution id
    * @param i_flg_available             Record availability
    * @param o_id_building               Building id
    * @param o_error                     Error
    *
    * @return                            true or false on success or error
    *
    * @raises                            PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                            Kelsey Lai
    * @version                           2.7.3.5
    * @since                             2018/06/19
    */
    FUNCTION set_building
    (
        i_lang           IN language.id_language%TYPE,
        i_id_building    IN building.id_building%TYPE,
        i_building_desc  IN VARCHAR2,
        i_id_institution IN institution.id_institution%TYPE,
        i_flg_available  IN building.flg_available%TYPE DEFAULT NULL,
        o_id_building    OUT building.id_building%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. Create or update floors
    *
    * @param i_lang                     Language identification
    * @param i_id_floors                Floors id
    * @param i_rank                     Rank
    * @param i_image_plant              Contains imagem plant swf file
    * @param i_id_institution           Institution id
    * @param i_id_building              Building id
    * @param i_flg_available            Record availability
    * @param o_id_floors                Floors's id
    * @param o_id_floors_institution    Floors_institution id
    * @param o_error                    Error
    *
    * @value i_flg_available            {*} 'Y' yes {*} 'N' No
    *
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Kelsey Lai
    * @version                          2.7.3.5
    * @since                            2018/06/19
    */
    FUNCTION set_floors
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_floors             IN floors.id_floors%TYPE,
        i_rank                  IN floors.rank%TYPE DEFAULT 0,
        i_image_plant           IN floors.image_plant%TYPE,
        i_floors_desc           IN VARCHAR2,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_building           IN building.id_building%TYPE,
        i_flg_available         IN floors.flg_available%TYPE DEFAULT NULL,
        o_id_floors             OUT floors.id_floors%TYPE,
        o_id_floors_institution OUT floors_institution.id_floors_institution%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Public Function. insert or update floors_institution
    *
    * @param i_lang                     Language identification
    * @param i_id_floors_institution    Floors_institution id
    * @param i_id_floors                Floors id
    * @param i_id_institution           Institution id
    * @param i_id_building              Building id
    * @param i_flg_available            Record availability
    * @param o_id_floors_institution    Floors_institution id
    * @param o_error                    Error
    *
    * @value i_flg_available            {*} 'Y' yes {*} 'N' No
    *
    * @return                           true or false on success or error
    *
    * @raises                           PL/SQL generic error "OTHERS" and "user define"
    *
    * @author                           Kelsey Lai
    * @version                          2.7.3.5
    * @since                            2018/06/19
    */
    FUNCTION set_floors_institution
    (
        i_lang                  IN language.id_language%TYPE,
        i_id_floors_institution IN floors_institution.id_floors_institution%TYPE,
        i_id_floors             IN floors.id_floors%TYPE,
        i_id_institution        IN institution.id_institution%TYPE,
        i_id_building           IN floors_institution.id_building%TYPE,
        i_flg_available         IN floors_institution.flg_available%TYPE DEFAULT NULL,
        o_id_floors_institution OUT floors_institution.id_floors_institution%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_func_all
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_prof_func OUT table_varchar,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_inst_adress
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_institution IN institution.id_institution%TYPE,
        o_inst_address   OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_prof_id_by_doc_type
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_doc_type    IN prof_doc.id_doc_type%TYPE,
        i_doc_value   IN prof_doc.value%TYPE,
        i_institution IN NUMBER,
        o_prof        OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_profs_by_dcs
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        o_profs         OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set bleep information for professional in institution
    *
    * @param i_lang            Application Language
    * @param i_prof            Professional identifier
    * @param i_work_phone      Work phone Number value
    * @param i_cell_phone      Celular phone Number value
    * @param i_bleep           Bleep number value
    * @param o_error           Error object    
    *            
    * @Return                  True or False
    *
    ********************************************************************************************/
    FUNCTION set_prof_bleep_info
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_work_phone IN professional.work_phone%TYPE,
        i_cell_phone IN professional.cell_phone%TYPE,
        i_bleep      IN professional.bleep_number%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    my_exception EXCEPTION;

END;
/
