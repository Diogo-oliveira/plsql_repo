CREATE OR REPLACE PACKAGE BODY pk_filter_teams IS

    k_package_name CONSTANT t_low_char := 'PK_FILTER_TEAMS';
    --k_package_owner             CONSTANT t_low_char := 'ALERT';

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
    ) RETURN t_tbl_filter_list IS
    
        --k_db_object_name CONSTANT user_objects.object_name%TYPE := 'GET_PROF_DEPARTMENTS';
        tbl_dept t_tbl_filter_list;
        --l_error  t_error_out;
        --l_str t_big_byte;
    BEGIN
    
        --l_str := 'CALL get_prof_departments(i_lang => ' || i_lang || ', i_prof => profissional(' || i_prof.id || ', ' ||
        --         i_prof.institution || ', ' || i_prof.software || '))';
        SELECT t_row_filter_list(i_grp_identifier, q.id_department, q.desc_department, 1)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT subq.id_department,
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => subq.code_department) desc_department,
                       subq.rank,
                       subq.rank_all
                  FROM (SELECT DISTINCT d.id_department, d.code_department, d.rank, 2 rank_all
                          FROM prof_dep_clin_serv pdcs
                          JOIN dep_clin_serv dcs
                            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                          JOIN department d
                            ON dcs.id_department = d.id_department
                         WHERE pdcs.id_professional = i_prof.id
                           AND pdcs.flg_status = pk_alert_constant.g_status_selected
                           AND d.id_institution = i_prof.institution
                           AND pdcs.id_institution = i_prof.institution
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND dcs.flg_available = pk_alert_constant.g_yes
                        UNION ALL
                        SELECT d.id_department, d.code_department, d.rank, 1 rank_all
                          FROM department d
                         WHERE d.id_department = 0) subq) q
         ORDER BY q.rank_all /*, q.rank*/, q.desc_department;
    
        RETURN tbl_dept;
    END get_prof_departments;

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
    ) RETURN t_tbl_filter_list IS
    
        tbl_dept              t_tbl_filter_list;
        l_department_flg_type department.flg_type%TYPE := i_department_flg_type;
        l_tbl_index           NUMBER := 0;
    
        l_counter NUMBER;
    BEGIN
        IF i_department_flg_type IS NULL
           AND i_tbl_par_name.exists(1)
        THEN
            l_tbl_index := pk_utils.search_table_varchar(i_table => i_tbl_par_name, i_search => k_list_department_type);
        
            IF l_tbl_index != -1
               AND l_tbl_index IS NOT NULL
            THEN
                l_department_flg_type := i_tbl_par_value(l_tbl_index);
            END IF;
        ELSE
            l_department_flg_type := i_department_flg_type;
        END IF;
    
        IF l_department_flg_type IS NULL
        THEN
            l_department_flg_type := 'I';
        END IF;
    
        -------------------------------------------------------------------------------
        SELECT COUNT(DISTINCT d.id_department)
          INTO l_counter
          FROM prof_dep_clin_serv pdcs
          JOIN dep_clin_serv dcs
            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
          JOIN department d
            ON dcs.id_department = d.id_department
           AND instr(d.flg_type, l_department_flg_type) > 0
         WHERE pdcs.flg_status = pk_alert_constant.g_status_selected
           AND d.id_institution = i_prof.institution
           AND pdcs.id_institution = i_prof.institution
           AND d.flg_available = pk_alert_constant.g_yes
           AND dcs.flg_available = pk_alert_constant.g_yes;
        -- pdcs.id_professional = i_prof.id
    
        -------------------------------------------------------------------------------
        SELECT t_row_filter_list(i_grp_identifier,
                                 q.id_department,
                                 pk_translation.get_translation(i_lang => i_lang, i_code_mess => q.code_department),
                                 q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT DISTINCT d.id_department, d.code_department, d.rank, 2 rank_all
                  FROM prof_dep_clin_serv pdcs
                  JOIN dep_clin_serv dcs
                    ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                  JOIN department d
                    ON dcs.id_department = d.id_department
                   AND instr(d.flg_type, l_department_flg_type) > 0
                 WHERE pdcs.flg_status = pk_alert_constant.g_status_selected
                   AND d.id_institution = i_prof.institution
                   AND pdcs.id_institution = i_prof.institution
                   AND d.flg_available = pk_alert_constant.g_yes
                   AND dcs.flg_available = pk_alert_constant.g_yes
                UNION ALL
                SELECT d.id_department, d.code_department, d.rank, 1 rank_all
                  FROM department d
                 WHERE d.id_department = 0
                   AND i_flg_use_all = pk_alert_constant.g_yes
                   AND l_counter > 0) q
         ORDER BY q.rank_all,
                  q.rank,
                  pk_translation.get_translation(i_lang => i_lang, i_code_mess => q.code_department);
        -- pdcs.id_professional = i_prof.id
    
        RETURN tbl_dept;
    END;

    FUNCTION get_pha_cars
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
    BEGIN
    
        RETURN pk_api_pfh_in.get_pha_cars(i_lang => i_lang, i_prof => i_prof);
    
    END get_pha_cars;

    FUNCTION get_pha_depts
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
    BEGIN
    
        RETURN pk_api_pfh_in.get_pha_depts(i_lang => i_lang, i_prof => i_prof);
    
    END get_pha_depts;

    FUNCTION get_doc_archive_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
        tbl_dept t_tbl_filter_list;
    BEGIN
    
        SELECT t_row_filter_list(k_list_doc_archive, q.id, q.desc_arch, q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT 4 id, pk_message.get_message(i_lang, 'COMMON_M014') desc_arch, 1 rank
                  FROM dual
                UNION ALL
                SELECT 5 id, pk_message.get_message(i_lang, 'ADMINISTRATOR_T074') desc_arch, 2 rank
                  FROM dual
                UNION ALL
                SELECT 6 id, pk_message.get_message(i_lang, 'DETAIL_COMMON_M003') desc_arch, 3 rank
                  FROM dual) q
         ORDER BY q.rank, q.desc_arch;
        RETURN tbl_dept;
    END get_doc_archive_list;

    FUNCTION get_exams_origin_list
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_origin IN VARCHAR2
    ) RETURN t_tbl_filter_list IS
        tbl_dept t_tbl_filter_list;
    BEGIN
    
        SELECT t_row_filter_list(i_origin, q.id, q.desc_arch, q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT 0 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.0') desc_arch, 1 rank
                  FROM dual
                UNION ALL
                SELECT 2 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.2') desc_arch, 2 rank
                  FROM dual
                UNION ALL
                SELECT 5 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.5') desc_arch, 2 rank
                  FROM dual
                UNION ALL
                SELECT 1 id, pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.1') desc_arch, 2 rank
                  FROM dual
                UNION ALL
                SELECT 4 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.4') desc_arch, 2 rank
                  FROM dual
                UNION ALL
                SELECT 12 id, pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.16') desc_arch, 2 rank
                  FROM dual
                 WHERE i_origin = k_list_lab_tests_origin
                UNION ALL
                SELECT 13 id, pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.15') desc_arch, 2 rank
                  FROM dual
                 WHERE i_origin = k_list_imaging_exams_origin
                UNION ALL
                SELECT 21 id, pk_translation.get_translation(i_lang, 'AB_SOFTWARE.CODE_SOFTWARE.25') desc_arch, 2 rank
                  FROM dual
                 WHERE i_origin = k_list_other_exams_origin
                UNION ALL
                SELECT 50 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.50') desc_arch, 2 rank
                  FROM dual) q
         ORDER BY q.rank, q.desc_arch;
        RETURN tbl_dept;
    END get_exams_origin_list;

    FUNCTION get_rehab_origin_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
        tbl_dept t_tbl_filter_list;
    BEGIN
    
        SELECT t_row_filter_list(k_list_rehab_treats_appoint, q.id, q.desc_arch, q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT 0 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.0') desc_arch, 1 rank
                  FROM dual
                UNION ALL
                SELECT a.id_software id, pk_translation.get_translation(i_lang, a.code_software) desc_arch, 2 rank
                  FROM software a
                 WHERE id_software IN (1, 11, 36, 8)) q
         ORDER BY q.rank, q.desc_arch;
        RETURN tbl_dept;
    END get_rehab_origin_list;

    FUNCTION get_paramedic_appoint_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
        tbl_dept t_tbl_filter_list;
    BEGIN
    
        SELECT t_row_filter_list(k_list_paramedic_appont, q.id, q.desc_arch, q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT 0 id, pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.0') desc_arch, 1 rank
                  FROM dual
                UNION ALL
                SELECT 1 id, pk_message.get_message(i_lang, 'PARAMEDIC_APPOINTMENTS_AMB') desc_arch, 1 rank
                  FROM dual
                UNION ALL
                SELECT 50 id, pk_message.get_message(i_lang, 'PARAMEDIC_APPOINTMENTS_HHC') desc_arch, 2 rank
                  FROM dual) q
         ORDER BY q.rank, q.desc_arch;
        RETURN tbl_dept;
    END get_paramedic_appoint_list;

    FUNCTION get_rehab_appoint_list
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN t_tbl_filter_list IS
        tbl_dept t_tbl_filter_list;
    BEGIN
    
        SELECT t_row_filter_list(k_list_rehab_appont, q.id, q.desc_arch, q.rank)
          BULK COLLECT
          INTO tbl_dept
          FROM (SELECT pk_rehab.g_filter_lov_all id,
                       pk_translation.get_translation(i_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.0') desc_arch,
                       1 rank
                  FROM dual
                UNION ALL
                SELECT pk_rehab.g_filter_lov_outp id,
                       pk_message.get_message(i_lang, 'PARAMEDIC_APPOINTMENTS_AMB') desc_arch,
                       1 rank
                  FROM dual
                UNION ALL
                SELECT pk_rehab.g_filter_lov_hhc id,
                       pk_message.get_message(i_lang, 'PARAMEDIC_APPOINTMENTS_HHC') desc_arch,
                       2 rank
                  FROM dual) q
         ORDER BY q.rank, q.desc_arch;
        RETURN tbl_dept;
    END get_rehab_appoint_list;

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
    ) RETURN t_tbl_filter_list IS
    
        tbl_clinical_services t_tbl_filter_list;
        k_config_cs           sys_config.desc_sys_config%TYPE := pk_sysconfig.get_config('COMPLAINT_CS_FILTER', i_prof);
        l_id_department       dep_clin_serv.id_department%TYPE;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE;
        l_clinical_service    dep_clin_serv.id_clinical_service%TYPE;
        l_error               t_error_out;
    BEGIN
    
        IF k_config_cs = pk_complaint.g_comp_filter_e
        THEN
        
            IF NOT pk_episode.get_epis_clin_serv(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_episode   => i_id_episode,
                                                 o_clin_serv => l_clinical_service,
                                                 o_error     => l_error)
            THEN
                RETURN NULL;
            END IF;
        ELSIF k_config_cs = pk_complaint.g_comp_filter_pp --professional preferences
        THEN
            IF NOT pk_prof_utils.get_prof_default_dcs(i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      i_software         => i_prof.software,
                                                      o_id_dep_clin_serv => l_id_dep_clin_serv,
                                                      o_department       => l_id_department,
                                                      o_clinical_service => l_clinical_service,
                                                      o_error            => l_error)
            THEN
                RETURN NULL;
            END IF;
        END IF;
        SELECT t_row_filter_list(k_list_prof_cs, q.id_clinical_service, q.desc_clicnical_service, q.rank)
          BULK COLLECT
          INTO tbl_clinical_services
          FROM (SELECT subq.id_clinical_service,
                       pk_translation.get_translation(i_lang => i_lang, i_code_mess => subq.code_clinical_service) desc_clicnical_service,
                       subq.rank,
                       subq.rank_all
                  FROM (SELECT DISTINCT cs.id_clinical_service,
                                        cs.code_clinical_service,
                                        decode(cs.id_clinical_service, l_clinical_service, 0, 0) rank,
                                        cs.rank rank_all
                          FROM prof_dep_clin_serv pdcs
                          JOIN dep_clin_serv dcs
                            ON pdcs.id_dep_clin_serv = dcs.id_dep_clin_serv
                          JOIN department d
                            ON dcs.id_department = d.id_department
                          JOIN clinical_service cs
                            ON dcs.id_clinical_service = cs.id_clinical_service
                          JOIN software_dept sdt
                            ON sdt.id_dept = d.id_dept
                         WHERE pdcs.id_professional = i_prof.id
                           AND pdcs.flg_status = pk_alert_constant.g_status_selected
                           AND d.id_institution = i_prof.institution
                           AND pdcs.id_institution = i_prof.institution
                           AND sdt.id_software = i_prof.software
                           AND cs.flg_available = pk_alert_constant.g_yes
                           AND d.flg_available = pk_alert_constant.g_yes
                           AND dcs.flg_available = pk_alert_constant.g_yes
                        UNION
                        SELECT cs.id_clinical_service, cs.code_clinical_service, 0, cs.rank
                          FROM clinical_service cs
                         WHERE cs.id_clinical_service = l_clinical_service
                           AND l_clinical_service != -1) subq) q
         ORDER BY /*q.rank_all, q.rank,*/ q.desc_clicnical_service ASC;
    
        RETURN tbl_clinical_services;
    END get_clinical_services;

    FUNCTION get_p1_type_request
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_p1_type_request, z.rank, z.desc_type_request, z.rank)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT q.desc_type_request, q.rank
                  FROM (SELECT DISTINCT a.flg_type,
                                        pk_sysdomain.get_domain(i_code_dom => 'P1_EXTERNAL_REQUEST.FLG_TYPE',
                                                                i_val      => a.flg_type,
                                                                i_lang     => i_lang) desc_type_request,
                                        pk_sysdomain.get_rank(i_lang     => i_lang,
                                                              i_code_dom => 'P1_EXTERNAL_REQUEST.FLG_TYPE',
                                                              i_val      => a.flg_type) rank
                          FROM p1_external_request a
                         WHERE a.id_patient = i_id_patient) q) z
         ORDER BY z.rank;
        RETURN tbl_p1_type_request;
    END get_p1_type_request;

    FUNCTION get_mcdt_exam_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_mcdt_exam_codification, z.id_action, z.desc_action, z.rank)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT q.id_action, q.desc_action, q.rank
                  FROM (SELECT to_char(cis.id_codification) id_action,
                               'D' id_parent,
                               NULL to_state,
                               pk_translation.get_translation(i_lang,
                                                              'CODIFICATION.CODE_CODIFICATION.' || cis.id_codification) desc_action,
                               NULL icon,
                               pk_lab_tests_constant.g_no flg_default,
                               pk_lab_tests_constant.g_active flg_active,
                               NULL action,
                               NULL rank
                          FROM codification_instit_soft cis
                         WHERE cis.id_institution = i_prof.institution
                           AND cis.id_software = i_prof.software
                           AND cis.flg_available = pk_exam_constant.g_available
                           AND cis.flg_use_on_referral = pk_exam_constant.g_available
                           AND EXISTS (SELECT 1
                                  FROM exam_codification ec,
                                       (SELECT e.id_exam
                                          FROM exam e, exam_dep_clin_serv edcs
                                         WHERE e.flg_available = pk_exam_constant.g_available
                                           AND edcs.flg_type = pk_exam_constant.g_exam_can_req
                                           AND edcs.id_software = i_prof.software
                                           AND edcs.id_institution = i_prof.institution) edcs
                                 WHERE cis.id_codification = ec.id_codification
                                   AND ec.flg_available = pk_exam_constant.g_available
                                   AND ec.id_exam = edcs.id_exam)) q) z
         ORDER BY z.desc_action;
        RETURN tbl_p1_type_request;
    END get_mcdt_exam_codification;

    FUNCTION get_mcdt_proc_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_mcdt_proc_codification, z.id_action, z.desc_action, z.rank)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT q.id_action, q.desc_action, q.rank
                  FROM (SELECT to_char(cis.id_codification) id_action,
                               'D' id_parent,
                               NULL to_state,
                               pk_translation.get_translation(i_lang,
                                                              'CODIFICATION.CODE_CODIFICATION.' || cis.id_codification) desc_action,
                               NULL icon,
                               pk_lab_tests_constant.g_no flg_default,
                               pk_lab_tests_constant.g_active flg_active,
                               NULL action,
                               NULL rank
                          FROM codification_instit_soft cis
                         WHERE cis.id_institution = i_prof.institution
                           AND cis.id_software = i_prof.software
                           AND cis.flg_available = pk_procedures_constant.g_available
                           AND cis.flg_use_on_referral = pk_procedures_constant.g_available
                           AND EXISTS (SELECT 1
                                  FROM interv_codification ic,
                                       (SELECT idcs.id_intervention
                                          FROM interv_dep_clin_serv idcs
                                         WHERE idcs.flg_type = pk_procedures_constant.g_interv_can_req
                                           AND idcs.id_software = i_prof.software
                                           AND idcs.id_institution = i_prof.institution
                                        /*AND idcs. = pk_procedures_constant.g_available*/
                                        ) ais
                                 WHERE cis.id_codification = ic.id_codification
                                   AND ic.flg_available = pk_procedures_constant.g_available
                                   AND ic.id_intervention = ais.id_intervention)) q) z
         ORDER BY z.desc_action;
        RETURN tbl_p1_type_request;
    END get_mcdt_proc_codification;

    FUNCTION get_mcdt_rehab_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_mcdt_rehab_codification, z.id_action, z.desc_action, z.rank)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT q.id_action, q.desc_action, q.rank
                  FROM (SELECT to_char(cis.id_codification) id_action,
                               'D' id_parent,
                               NULL to_state,
                               pk_translation.get_translation(i_lang,
                                                              'CODIFICATION.CODE_CODIFICATION.' || cis.id_codification) desc_action,
                               NULL icon,
                               pk_lab_tests_constant.g_no flg_default,
                               pk_lab_tests_constant.g_active flg_active,
                               NULL action,
                               NULL rank
                          FROM codification_instit_soft cis
                         WHERE cis.id_institution = i_prof.institution
                           AND cis.id_software = i_prof.software
                           AND cis.flg_available = pk_procedures_constant.g_available
                           AND cis.flg_use_on_referral = pk_procedures_constant.g_available
                           AND EXISTS (SELECT 1
                                  FROM interv_codification ic
                                 INNER JOIN pk_rehab.find_rehab_interv(i_prof.institution, i_prof.software) ri
                                    ON ri.id_intervention = ic.id_intervention
                                 INNER JOIN rehab_inst_soft ris
                                    ON ris.id_rehab_area_interv = ri.id_rehab_area_interv
                                 WHERE cis.id_codification = ic.id_codification
                                   AND ris.id_institution = i_prof.institution
                                   AND ris.id_software = i_prof.software
                                   AND ic.flg_available = pk_procedures_constant.g_available)) q) z
         ORDER BY z.desc_action;
        RETURN tbl_p1_type_request;
    END get_mcdt_rehab_codification;

    FUNCTION get_mcdt_lab_codification
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_mcdt_lab_codification, z.id_action, z.desc_action, z.rank)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT q.id_action, q.desc_action, q.rank
                  FROM (SELECT to_char(cis.id_codification) id_action,
                               'D' id_parent,
                               NULL to_state,
                               pk_translation.get_translation(i_lang,
                                                              'CODIFICATION.CODE_CODIFICATION.' || cis.id_codification) desc_action,
                               NULL icon,
                               pk_lab_tests_constant.g_no flg_default,
                               pk_lab_tests_constant.g_active flg_active,
                               NULL action,
                               NULL rank
                          FROM codification_instit_soft cis
                         WHERE cis.id_institution = i_prof.institution
                           AND cis.id_software = i_prof.software
                           AND cis.flg_available = pk_lab_tests_constant.g_available
                           AND cis.flg_use_on_referral = pk_lab_tests_constant.g_available
                           AND EXISTS (SELECT 1
                                  FROM analysis_codification ac,
                                       (SELECT id_analysis, id_sample_type
                                          FROM analysis_instit_soft
                                         WHERE flg_type = pk_lab_tests_constant.g_analysis_can_req
                                           AND id_software = i_prof.software
                                           AND id_institution = i_prof.institution
                                           AND flg_available = pk_lab_tests_constant.g_available) ais
                                 WHERE cis.id_codification = ac.id_codification
                                   AND ac.flg_available = pk_lab_tests_constant.g_available
                                   AND ac.id_analysis = ais.id_analysis
                                   AND ac.id_sample_type = ais.id_sample_type)) q) z
         ORDER BY z.desc_action;
        RETURN tbl_p1_type_request;
    END get_mcdt_lab_codification;

    -- sample function for desc menu function
    FUNCTION get_desc_menu_sample
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
    BEGIN
        RETURN '<NO_MENU_FUNC_DECLARED>';
    END get_desc_menu_sample;

    /********************************************************************************************
    * @author  Pedro Teixeira
    * @since   27/05/2022
    ********************************************************************************************/
    FUNCTION get_desc_concluded_disp
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_disp_time_interval    NUMBER(24) := pk_sysconfig.get_config('DISPENSED_TIME_INTERVAL', i_prof);
        l_concluded_disp_string sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                        i_prof,
                                                                                        'RECENTLY_CONCLUDED_DISPENSES');
    BEGIN
    
        RETURN REPLACE(l_concluded_disp_string, '@1', l_disp_time_interval);
    END get_desc_concluded_disp;

    /********************************************************************************************
    * @author  Sofia Mendes
    * @since   21/06/2022
    ********************************************************************************************/
    FUNCTION get_desc_active_medication
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_active_med_time_interval NUMBER(24) := pk_sysconfig.get_config('MED_CONCL_DESCON_TIME_HR', i_prof);
        l_active_med_string        sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                           i_prof,
                                                                                           'PRESC_ACTIVE_MED_FILTER');
    BEGIN
    
        RETURN REPLACE(l_active_med_string, '@1', l_active_med_time_interval);
    END get_desc_active_medication;

    --***********************************************************
    FUNCTION get_departments
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_grp  IN VARCHAR2
    ) RETURN t_tbl_filter_list IS
        tbl_department t_tbl_filter_list;
        l_error        t_error_out;
        tbl_flg_type   table_varchar := table_varchar('I', 'U', 'C', 'S');
        l_flg_type     VARCHAR2(0010 CHAR);
    
        --***************************
        FUNCTION set_flg_type(i_grp IN VARCHAR2) RETURN VARCHAR2 IS
            l_flg_type VARCHAR2(0010 CHAR);
        BEGIN
        
            CASE i_grp
                WHEN 'LOV_DIE_INP' THEN
                    l_flg_type := 'I';
                WHEN 'LOV_DIE_URG' THEN
                    l_flg_type := 'U';
                WHEN 'LOV_DIE_OUTP' THEN
                    l_flg_type := 'C';
                WHEN 'LOV_DIE_ORIS' THEN
                    l_flg_type := 'S';
                ELSE
                    l_flg_type := NULL;
            END CASE;
        
            RETURN l_flg_type;
        
        END set_flg_type;
    
    BEGIN
    
        l_flg_type := set_flg_type(i_grp);
    
        SELECT t_row_filter_list(grp_identifier => i_grp,
                                 id_list        => xdep.id_department,
                                 desc_list      => xdep.desc_department,
                                 order_rank     => xdep.rank)
          BULK COLLECT
          INTO tbl_department
          FROM (SELECT d.id_department,
                       pk_translation.get_translation(i_lang, d.code_department) desc_department,
                       d.rank
                  FROM department d
                 WHERE d.id_institution = i_prof.institution
                   AND d.flg_available = 'Y'
                   AND (instr(d.flg_type, l_flg_type) > 0)
                   AND l_flg_type IS NOT NULL
                UNION ALL
                SELECT -1,
                       pk_translation.get_translation(i_lang, 'FILTER_MENU.CODE_MENU.1238') desc_department,
                       -10 rank
                  FROM dual d) xdep
         ORDER BY xdep.rank, xdep.desc_department;
    
        RETURN tbl_department;
    
    END get_departments;

    --***********************************************************
    FUNCTION get_alert_group
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_grp  IN VARCHAR2
    ) RETURN t_tbl_filter_list IS
        tbl_alerts t_tbl_filter_list;
        l_error    t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(grp_identifier => i_grp,
                                 id_list        => sat.id_sys_alert_type,
                                 desc_list      => sat.alert_desc,
                                 order_rank     => sat.rank)
          BULK COLLECT
          INTO tbl_alerts
          FROM (SELECT satt.id_sys_alert_type,
                       pk_translation.get_translation(i_lang, satt.code_sys_alert_type) alert_desc,
                       satt.rank
                  FROM sys_alert_type satt) sat
         ORDER BY sat.rank, sat.alert_desc;
    
        RETURN tbl_alerts;
    
    END get_alert_group;

    FUNCTION get_order_sets_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_order_sets, z.id_order_set_process, z.title, rownum)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM (SELECT odst_proc.id_order_set_process, odst.title, rownum rank
                  FROM order_set odst
                 INNER JOIN order_set_process odst_proc
                    ON (odst.id_order_set = odst_proc.id_order_set)
                 WHERE odst_proc.id_patient = i_id_patient
                   AND pk_episode.get_id_visit(i_id_episode) = pk_episode.get_id_visit(odst_proc.id_episode)
                   AND odst_proc.flg_status != 'T'
                 ORDER BY upper(odst.title)) z;
    
        RETURN tbl_p1_type_request;
    END get_order_sets_list;

    FUNCTION get_complaint_os_clin_serv_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_order_set  IN order_set.id_order_set%TYPE
    ) RETURN t_tbl_filter_list IS
    
        tbl_p1_type_request t_tbl_filter_list;
    
        l_error t_error_out;
    BEGIN
    
        SELECT t_row_filter_list(k_list_complaint_os_clin_serv,
                                 cs.id_clinical_service,
                                 pk_translation.get_translation(i_lang, cs.code_clinical_service),
                                 rownum)
          BULK COLLECT
          INTO tbl_p1_type_request
          FROM dep_clin_serv dcs
          JOIN clinical_service cs
            ON cs.id_clinical_service = dcs.id_clinical_service
          JOIN order_set_link ost_lnk
            ON ost_lnk.id_link = dcs.id_dep_clin_serv
           AND ost_lnk.flg_link_type = 'D'
         WHERE ost_lnk.id_order_set = i_order_set;
    
        RETURN tbl_p1_type_request;
    END get_complaint_os_clin_serv_list;

BEGIN
    pk_alertlog.log_init(k_package_name);
END pk_filter_teams;
/
