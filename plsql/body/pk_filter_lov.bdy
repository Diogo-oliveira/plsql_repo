/*-- Last Change Revision: $Rev: 2055616 $*/
/*-- Last Change by: $Author: pedro.henriques $*/
/*-- Date of last change: $Date: 2023-02-22 15:27:24 +0000 (qua, 22 fev 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_filter_lov IS

    k_package_name CONSTANT t_low_char := 'PK_FILTER_LOV';
    --k_package_owner             CONSTANT t_low_char := 'ALERT';
    k_list_prof_departments        CONSTANT t_low_char := pk_filter_teams.k_list_prof_departments;
    k_list_pha_cars                CONSTANT t_low_char := pk_filter_teams.k_list_pha_cars;
    k_list_pha_depts               CONSTANT t_low_char := pk_filter_teams.k_list_pha_depts;
    k_list_doc_archive             CONSTANT t_low_char := pk_filter_teams.k_list_doc_archive;
    k_list_lab_tests_origin        CONSTANT t_low_char := pk_filter_teams.k_list_lab_tests_origin;
    k_list_imaging_exams_origin    CONSTANT t_low_char := pk_filter_teams.k_list_imaging_exams_origin;
    k_list_other_exams_origin      CONSTANT t_low_char := pk_filter_teams.k_list_other_exams_origin;
    k_list_rehab_treats_appoint    CONSTANT t_low_char := pk_filter_teams.k_list_rehab_treats_appoint;
    k_list_paramedic_appont        CONSTANT t_low_char := pk_filter_teams.k_list_paramedic_appont;
    k_list_rehab_appont            CONSTANT t_low_char := pk_filter_teams.k_list_rehab_appont;
    k_list_prof_cs                 CONSTANT t_low_char := pk_filter_teams.k_list_prof_cs;
    k_list_p1_type_request         CONSTANT t_low_char := pk_filter_teams.k_list_p1_type_request;
    k_list_mcdt_lab_codification   CONSTANT t_low_char := pk_filter_teams.k_list_mcdt_lab_codification;
    k_list_mcdt_exam_codification  CONSTANT t_low_char := pk_filter_teams.k_list_mcdt_exam_codification;
    k_list_mcdt_proc_codification  CONSTANT t_low_char := pk_filter_teams.k_list_mcdt_proc_codification;
    k_list_mcdt_rehab_codification CONSTANT t_low_char := pk_filter_teams.k_list_mcdt_rehab_codification;
    k_list_prof_dept_oris          CONSTANT t_low_char := pk_filter_teams.k_list_prof_dept_oris;
    k_list_prof_dept_outp          CONSTANT t_low_char := pk_filter_teams.k_list_prof_dept_outp;
    k_list_prof_dept_inp           CONSTANT t_low_char := pk_filter_teams.k_list_prof_dept_inp;
    k_list_prof_dept_edis          CONSTANT t_low_char := pk_filter_teams.k_list_prof_dept_edis;
    k_list_prof_dept               CONSTANT t_low_char := pk_filter_teams.k_list_prof_dept;
    k_list_order_sets              CONSTANT t_low_char := pk_filter_teams.k_list_order_sets;
    k_list_complaint_os_clin_serv  CONSTANT t_low_char := pk_filter_teams.k_list_complaint_os_clin_serv;
    --k_list_department_type         CONSTANT t_low_char := pk_filter_teams.k_list_department_type;
    ------------------------------------------------
    k_menu_pharm_concluded_disp CONSTANT t_low_char := pk_filter_teams.k_menu_pharm_concluded_disp;
    k_menu_active_medication    CONSTANT t_low_char := pk_filter_teams.k_menu_active_medication;

    -- ***************************************************************
    FUNCTION execute_list
    (
        i_lang            IN NUMBER,
        i_prof            IN profissional,
        i_id_episode      IN NUMBER,
        i_id_patient      IN NUMBER,
        i_list            IN VARCHAR2,
        i_tbl_par_name    IN table_varchar,
        i_tbl_par_value   IN table_varchar,
        i_flg_default_use IN VARCHAR2 DEFAULT 'N'
    ) RETURN t_tbl_filter_list IS
        tbl_list t_tbl_filter_list;
    BEGIN
    
        CASE i_list
            WHEN k_list_prof_departments THEN
                tbl_list := pk_filter_teams.get_prof_departments(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_pha_cars THEN
                tbl_list := pk_filter_teams.get_pha_cars(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_pha_depts THEN
                tbl_list := pk_filter_teams.get_pha_depts(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_doc_archive THEN
                tbl_list := pk_filter_teams.get_doc_archive_list(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_lab_tests_origin THEN
                tbl_list := pk_filter_teams.get_exams_origin_list(i_lang   => i_lang,
                                                                  i_prof   => i_prof,
                                                                  i_origin => i_list);
            WHEN k_list_imaging_exams_origin THEN
                tbl_list := pk_filter_teams.get_exams_origin_list(i_lang   => i_lang,
                                                                  i_prof   => i_prof,
                                                                  i_origin => i_list);
            WHEN k_list_other_exams_origin THEN
                tbl_list := pk_filter_teams.get_exams_origin_list(i_lang   => i_lang,
                                                                  i_prof   => i_prof,
                                                                  i_origin => i_list);
            WHEN k_list_rehab_treats_appoint THEN
                tbl_list := pk_filter_teams.get_rehab_origin_list(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_paramedic_appont THEN
                tbl_list := pk_filter_teams.get_paramedic_appoint_list(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_rehab_appont THEN
                tbl_list := pk_filter_teams.get_rehab_appoint_list(i_lang => i_lang, i_prof => i_prof);
            WHEN k_list_prof_cs THEN
                tbl_list := pk_filter_teams.get_clinical_services(i_lang       => i_lang,
                                                                  i_prof       => i_prof,
                                                                  i_id_patient => i_id_patient,
                                                                  i_id_episode => i_id_episode);
            WHEN k_list_p1_type_request THEN
                tbl_list := pk_filter_teams.get_p1_type_request(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_id_patient,
                                                                i_id_episode => i_id_episode);
            WHEN k_list_mcdt_lab_codification THEN
                tbl_list := pk_filter_teams.get_mcdt_lab_codification(i_lang       => i_lang,
                                                                      i_prof       => i_prof,
                                                                      i_id_patient => i_id_patient,
                                                                      i_id_episode => i_id_episode);
            WHEN k_list_mcdt_exam_codification THEN
                tbl_list := pk_filter_teams.get_mcdt_exam_codification(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_patient => i_id_patient,
                                                                       i_id_episode => i_id_episode);
            WHEN k_list_mcdt_proc_codification THEN
                tbl_list := pk_filter_teams.get_mcdt_proc_codification(i_lang       => i_lang,
                                                                       i_prof       => i_prof,
                                                                       i_id_patient => i_id_patient,
                                                                       i_id_episode => i_id_episode);
            WHEN k_list_mcdt_rehab_codification THEN
                tbl_list := pk_filter_teams.get_mcdt_rehab_codification(i_lang       => i_lang,
                                                                        i_prof       => i_prof,
                                                                        i_id_patient => i_id_patient,
                                                                        i_id_episode => i_id_episode);
            WHEN k_list_prof_dept_oris THEN
                tbl_list := pk_filter_teams.get_prof_dept(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_grp_identifier      => k_list_prof_dept_oris,
                                                          i_department_flg_type => 'S',
                                                          i_flg_use_all         => pk_alert_constant.g_yes);
            WHEN k_list_prof_dept_outp THEN
                tbl_list := pk_filter_teams.get_prof_dept(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_grp_identifier      => k_list_prof_dept_outp,
                                                          i_department_flg_type => 'C',
                                                          i_flg_use_all         => pk_alert_constant.g_yes);
            WHEN k_list_prof_dept_inp THEN
                tbl_list := pk_filter_teams.get_prof_dept(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_grp_identifier      => k_list_prof_dept_inp,
                                                          i_department_flg_type => 'I',
                                                          i_flg_use_all         => pk_alert_constant.g_yes);
            WHEN k_list_prof_dept_edis THEN
                tbl_list := pk_filter_teams.get_prof_dept(i_lang                => i_lang,
                                                          i_prof                => i_prof,
                                                          i_grp_identifier      => k_list_prof_dept_edis,
                                                          i_department_flg_type => 'U',
                                                          i_flg_use_all         => pk_alert_constant.g_yes);
            WHEN k_list_prof_dept THEN
                tbl_list := pk_filter_teams.get_prof_dept(i_lang           => i_lang,
                                                          i_prof           => i_prof,
                                                          i_grp_identifier => k_list_prof_dept,
                                                          i_flg_use_all    => pk_alert_constant.g_yes,
                                                          i_tbl_par_name   => i_tbl_par_name,
                                                          i_tbl_par_value  => i_tbl_par_value);
            WHEN 'LOV_DIE_INP' THEN
                tbl_list := pk_filter_teams.get_departments(i_lang => i_lang, i_prof => i_prof, i_grp => 'LOV_DIE_INP');
            WHEN 'LOV_DIE_URG' THEN
                tbl_list := pk_filter_teams.get_departments(i_lang => i_lang, i_prof => i_prof, i_grp => 'LOV_DIE_URG');
            WHEN 'LOV_DIE_OUTP' THEN
                tbl_list := pk_filter_teams.get_departments(i_lang => i_lang, i_prof => i_prof, i_grp => 'LOV_DIE_OUTP');
            WHEN 'LOV_DIE_ORIS' THEN
                tbl_list := pk_filter_teams.get_departments(i_lang => i_lang, i_prof => i_prof, i_grp => 'LOV_DIE_ORIS');
            WHEN 'ALERTS_GROUP' THEN
                tbl_list := pk_filter_teams.get_alert_group(i_lang => i_lang, i_prof => i_prof, i_grp => i_list);
            WHEN k_list_order_sets THEN
                tbl_list := pk_filter_teams.get_order_sets_list(i_lang       => i_lang,
                                                                i_prof       => i_prof,
                                                                i_id_patient => i_id_patient,
                                                                i_id_episode => i_id_episode);
            WHEN k_list_complaint_os_clin_serv THEN
                pk_alertlog.log_error('Tavares');
                BEGIN
                    pk_alertlog.log_error(' - ' || i_tbl_par_value(1));
                EXCEPTION
                    WHEN OTHERS THEN
                        NULL;
                END;
                tbl_list := pk_filter_teams.get_complaint_os_clin_serv_list(i_lang       => i_lang,
                                                                            i_prof       => i_prof,
                                                                            i_id_patient => i_id_patient,
                                                                            i_id_episode => i_id_episode,
                                                                            i_order_set  => to_number(i_tbl_par_value(1)));
            ELSE
                tbl_list := t_tbl_filter_list();
        END CASE;
    
        RETURN tbl_list;
    
    END execute_list;

    --***********************************************
    FUNCTION get_desc_menu
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_menu_function IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        err_no_menu_function EXCEPTION;
    BEGIN
    
        IF i_menu_function IS NULL
        THEN
            RAISE err_no_menu_function;
        END IF;
    
        --*********************************
        CASE i_menu_function
            WHEN 'SAMPLE_DESC' THEN
                l_return := pk_filter_teams.get_desc_menu_sample(i_lang, i_prof);
            WHEN k_menu_pharm_concluded_disp THEN
                l_return := pk_filter_teams.get_desc_concluded_disp(i_lang, i_prof);
            WHEN k_menu_active_medication THEN
                l_return := pk_filter_teams.get_desc_active_medication(i_lang, i_prof);
            ELSE
                l_return := '<NO_MENU_FUNC_DECLARED>';
        END CASE;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN err_no_menu_function THEN
            RETURN NULL;
    END get_desc_menu;

    --*****************************
    FUNCTION get_lov_value
    (
        i_tbl_lov  IN table_varchar,
        i_tbl_keys IN table_varchar,
        i_tbl_vals IN table_varchar
    ) RETURN VARCHAR2 IS
        l_compare BOOLEAN;
        l_return  VARCHAR2(4000);
    BEGIN
    
        IF i_tbl_keys.exists(1)
        THEN
        
            <<lup_thru_possible_lov>>
            FOR i IN 1 .. i_tbl_lov.count
            LOOP
            
                <<lup_thru_keys_used>>
                FOR j IN 1 .. i_tbl_keys.count
                LOOP
                
                    -- Is this a wanted LOV??
                    l_compare := i_tbl_lov(i) = i_tbl_keys(j);
                
                    IF l_compare
                    THEN
                    
                        -- yes, so get the value at matching position
                        l_return := i_tbl_vals(j);
                    
                        -- and exit 
                        EXIT lup_thru_possible_lov;
                    
                    END IF;
                
                END LOOP lup_thru_keys_used;
            
            END LOOP lup_thru_possible_lov;
        
        END IF;
    
        RETURN l_return;
    
    END get_lov_value;

BEGIN
    pk_alertlog.log_init(k_package_name);
END pk_filter_lov;
/
