/*-- Last Change Revision: $Rev: 2017009 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-06-21 15:43:37 +0100 (ter, 21 jun 2022) $*/
CREATE OR REPLACE PACKAGE BODY pk_cdoc_filters IS

    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    k_yes CONSTANT VARCHAR2(0001 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0001 CHAR) := 'N';

    k_task_analysis CONSTANT VARCHAR2(0001 CHAR) := 'A';
    k_task_exam     CONSTANT VARCHAR2(0001 CHAR) := 'E';
    --k_task_harvest  CONSTANT VARCHAR2(0001 CHAR) := 'H';
    k_task_monitor CONSTANT VARCHAR2(0001 CHAR) := 'M';
    k_task_interv  CONSTANT VARCHAR2(0001 CHAR) := 'I';
    k_task_edu     CONSTANT VARCHAR2(0001 CHAR) := 'T';

    k_flg_state_disch       CONSTANT VARCHAR2(0001 CHAR) := 'X';
    k_flg_state_admin_disch CONSTANT VARCHAR2(0001 CHAR) := 'M';

    k_group_app_img_state_rank CONSTANT NUMBER := 10;

    k_view00 CONSTANT VARCHAR2(0100 CHAR) := '00_GROUP_ROW';
    k_view05 CONSTANT VARCHAR2(0100 CHAR) := '05_SINGLE_ROW';
    --k_view_between CONSTANT VARCHAR2(0100 CHAR) := '00_OUTP_BETWEEN';
    ---
    --k_view04 CONSTANT VARCHAR2(0100 CHAR) := 'VIEW04';
    --k_view03 CONSTANT VARCHAR2(0100 CHAR) := 'VIEW03';
    --k_view02 CONSTANT VARCHAR2(0100 CHAR) := 'VIEW02';
    --

    k_sched_canc CONSTANT VARCHAR2(0001 CHAR) := 'C';

    k_cat_type_nurse CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_cat_type_nurse;
    k_cat_type_doc   CONSTANT VARCHAR2(0100 CHAR) := pk_alert_constant.g_cat_type_doc;
    k_flg_doctor     CONSTANT VARCHAR2(0100 CHAR) := k_cat_type_doc;

    k_sort_type_los CONSTANT VARCHAR2(0100 CHAR) := pk_edis_proc.g_sort_type_los;

    --    k_show_in_tooltip CONSTANT VARCHAR2(0001 CHAR) := 'T';

    k_schdl_outp_state_domain  CONSTANT VARCHAR2(0100 CHAR) := 'SCHEDULE_OUTP.FLG_STATE';
    k_schdl_outp_status_domain CONSTANT VARCHAR2(0100 CHAR) := 'SCHEDULE.FLG_STATUS';

    k_domain_gender_abbrv CONSTANT VARCHAR2(0100 CHAR) := 'PATIENT.GENDER.ABBR';
    k_domain_sch_presence CONSTANT VARCHAR2(0100 CHAR) := 'SCH_GROUP.FLG_CONTACT_TYPE';

    k_analysis_exam_icon_grid_rank CONSTANT VARCHAR2(0100 CHAR) := 'ANALYSIS_EXAM_ICON_GRID_RANK';

    --Handoff responsabilities constants
    k_show_in_grid    CONSTANT VARCHAR2(0001 CHAR) := 'G';
    k_show_in_tooltip CONSTANT VARCHAR2(0001 CHAR) := 'T';

    k_resident        CONSTANT VARCHAR2(0001 CHAR) := 'R';
    k_sched_med_disch CONSTANT VARCHAR2(0001 CHAR) := 'D';

    --drl
    k_drl_presc_valid              CONSTANT VARCHAR2(0010 CHAR) := 'V';
    k_drl_presc_waiting_validation CONSTANT VARCHAR2(0010 CHAR) := 'W';
    k_drl_presc_cancelled          CONSTANT VARCHAR2(0010 CHAR) := 'C';

    --k_sort_mask    CONSTANT VARCHAR2(6) := '00000';
    k_six CONSTANT PLS_INTEGER := 6;
    --k_zero         CONSTANT PLS_INTEGER := 0;
    --k_one          CONSTANT PLS_INTEGER := 1;
    k_zero_varchar              CONSTANT VARCHAR2(1) := '0';
    k_sch_event_therap_decision CONSTANT NUMBER := 20;

    k_id_epis_type_edis CONSTANT NUMBER := 2;
    k_id_epis_type_inp  CONSTANT NUMBER := 5;
    k_id_epis_type_ubu  CONSTANT NUMBER := 9;
    k_epis_hhc_appoint  CONSTANT NUMBER := 50;

    FUNCTION do_discharge_dt_pend
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    --*****************************
    FUNCTION do_edis_dt_begin_sort
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    --************************************
    FUNCTION do_discharge_date
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    --************************************
    FUNCTION do_discharge_type
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    --************************************
    FUNCTION do_inp_flg_status
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    --********************************
    FUNCTION do_transfer_status_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_id    IN NUMBER,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    FUNCTION do_edis_dt_begin
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2;

    -- *****************************************
    FUNCTION do_get_status_icon_base
    (
        i_lang       IN NUMBER,
        i_mode       IN VARCHAR2,
        i_sch_status IN VARCHAR2,
        i_dsc_status IN VARCHAR2,
        i_flg_ehr    IN VARCHAR2,
        i_flg_state  IN VARCHAR2
    ) RETURN VARCHAR2;

    -- ************************************
    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    END iif;

    -- *************************************
    PROCEDURE inicialize IS
    BEGIN
        pk_alertlog.who_am_i(g_owner, g_package);
    END inicialize;

    --***********************************************
    FUNCTION clob_to_vc2
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_episode  IN NUMBER,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR(4000);
    BEGIN
    
        l_return := pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang        => i_lang,
                                                                                                i_prof        => i_prof,
                                                                                                i_id_episode  => i_id_episode,
                                                                                                i_id_schedule => i_id_schedule,
                                                                                                i_separator   => ';'),
                                                     4000);
    
        RETURN l_return;
    END clob_to_vc2;

    --*************************************
    FUNCTION convert_grid_str_to_sort(i_str IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_pos    NUMBER;
    BEGIN
    
        l_pos := instr(i_str, '|', 1);
        IF l_pos > 0
        THEN
            l_return := substr(i_str, l_pos, length(i_str));
        END IF;
    
        RETURN l_return;
    
    END convert_grid_str_to_sort;

    -- **********************************************************************
    FUNCTION get_prof_flg_mrp
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return              VARCHAR2(0010 CHAR);
        l_id_profile_template NUMBER;
    BEGIN
    
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        l_return := pk_prof_utils.get_flg_mrp(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_profile_template => l_id_profile_template);
    
        RETURN l_return;
    
    END get_prof_flg_mrp;

    -- ***********************************
    FUNCTION get_prof_dcs_allocated
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN table_number IS
        tbl_dcs table_number;
    BEGIN
    
        SELECT pdcs.id_dep_clin_serv
          BULK COLLECT
          INTO tbl_dcs
          FROM prof_dep_clin_serv pdcs
         WHERE pdcs.id_professional = i_prof.id
           AND pdcs.id_institution = i_prof.institution
           AND pdcs.flg_status = 'S';
    
        RETURN tbl_dcs;
    
    END get_prof_dcs_allocated;

    -- ***********************************
    FUNCTION get_aux_grid
    (
        i_lang IN NUMBER,
        i_prof IN profissional
    ) RETURN VARCHAR2 IS
        l_return              VARCHAR2(0010 CHAR);
        l_id_profile_template NUMBER;
        l_flg_show_all        VARCHAR2(0010 CHAR);
    BEGIN
    
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
        l_flg_show_all        := pk_sysconfig.get_config('SHOW_ALL_PATIENTS_AUX_GRID', i_prof);
    
        IF l_id_profile_template = 402
           AND l_flg_show_all = pk_alert_constant.g_no
        THEN
            l_return := pk_alert_constant.g_yes;
        ELSE
            l_return := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_return;
    
    END get_aux_grid;

    -- ***********************************

    -- ***********************************
    FUNCTION get_family_doctor(i_id_patient IN patient.id_patient%TYPE) RETURN NUMBER IS
        tbl_id   table_number;
        l_return NUMBER;
    BEGIN
        SELECT id_professional
          BULK COLLECT
          INTO tbl_id
          FROM ((SELECT pfp.id_professional, p.nick_name, 1, pfp.dt_begin_tstz dt_begin
                   FROM patient pat
                   JOIN pat_family_prof pfp
                     ON pfp.id_patient = pat.id_patient
                   JOIN professional p
                     ON p.id_professional = pfp.id_professional
                  WHERE pat.id_patient = i_id_patient
                    AND pfp.flg_status = 'A'
                 UNION ALL
                 SELECT pfp.id_professional, p.nick_name, 2, pfp.dt_begin_tstz dt_begin
                   FROM patient pat
                   JOIN pat_family_prof pfp
                     ON pfp.id_pat_family = pat.id_pat_family
                   JOIN professional p
                     ON p.id_professional = pfp.id_professional
                  WHERE pat.id_patient = i_id_patient) ORDER BY 3, dt_begin DESC);
    
        IF tbl_id.count > 0
        THEN
            l_return := tbl_id(1);
        END IF;
    
        RETURN l_return;
    
    END get_family_doctor;

    FUNCTION do_prof_in_charge
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_return        VARCHAR2(4000);
        l_bool          BOOLEAN;
        l_id_prof       NUMBER;
        l_id_prof_nurse NUMBER;
        l_id_patient    NUMBER;
        --l_id_doctor     NUMBER;
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
    
        l_category_type VARCHAR2(0100 CHAR);
        k_cat_type_nurse CONSTANT VARCHAR2(0001 CHAR) := 'N';
    
        --**********************************************
        FUNCTION get_category_type
        (
            i_lang    IN NUMBER,
            i_prof    IN profissional,
            i_id_prof IN NUMBER
        ) RETURN VARCHAR2 IS
            l_return   VARCHAR2(0010 CHAR);
            tbl_return table_varchar;
        BEGIN
        
            SELECT c.flg_type
              BULK COLLECT
              INTO tbl_return
              FROM prof_cat pc
              JOIN category c
                ON c.id_category = pc.id_category
             WHERE pc.id_professional = i_id_prof
               AND pc.id_institution = i_prof.institution;
        
            IF tbl_return.count > 0
            THEN
                l_return := tbl_return(1);
            END IF;
        
            RETURN l_return;
        
        END get_category_type;
    
        --******************************************************
        PROCEDURE get_info_episode(i_id_episode IN NUMBER) IS
            tbl_prof     table_number;
            tbl_nurse    table_number;
            tbl_schedule table_number;
        BEGIN
            SELECT id_first_nurse_resp, id_professional, id_schedule
              BULK COLLECT
              INTO tbl_nurse, tbl_prof, tbl_schedule
              FROM epis_info ei
             WHERE ei.id_episode = i_id_episode;
        
            IF tbl_nurse.count > 0
            THEN
                l_id_prof_nurse := tbl_nurse(1);
                l_id_prof       := coalesce(tbl_prof(1), l_id_prof_nurse);
                l_id_schedule   := tbl_schedule(1);
            END IF;
        
        END get_info_episode;
    
        -- *****************************************
        FUNCTION get_id_professional
        (
            i_id_prof  IN NUMBER,
            i_schedule IN NUMBER
        ) RETURN NUMBER IS
            l_return NUMBER;
            tbl_id   table_number;
        BEGIN
        
            l_return := i_id_prof;
        
            IF i_id_prof IS NULL
            THEN
            
                SELECT id_professional
                  BULK COLLECT
                  INTO tbl_id
                  FROM sch_resource sc
                 WHERE sc.id_schedule = i_schedule
                 ORDER BY sc.flg_leader DESC NULLS LAST;
            
                IF tbl_id.count > 0
                THEN
                    l_return := tbl_id(1);
                END IF;
            
            END IF;
        
            RETURN l_return;
        
        END get_id_professional;
    
    BEGIN
    
        l_id_episode := i_num01(1);
        l_id_patient := i_num01(2);
        --l_id_prof    := i_num01(3);
    
        get_info_episode(l_id_episode);
        --l_id_prof := coalesce(l_id_prof, l_id_prof_nurse);
        l_id_prof := get_id_professional(i_id_prof => l_id_prof, i_schedule => l_id_schedule);
    
        l_category_type := get_category_type(i_lang => i_lang, i_prof => i_prof, i_id_prof => l_id_prof);
    
        l_bool := (l_id_prof = nvl(l_id_prof_nurse, 0)) OR (l_category_type = k_cat_type_nurse);
    
        --        IF NOT l_bool
        IF NOT l_bool
        THEN
        
            l_bool := i_prof.software = pk_sysconfig.get_config('SOFTWARE_ID_CARE', i_prof);
            l_bool := l_bool AND (l_id_prof IS NULL);
        
            IF l_bool
            THEN
                l_id_prof := get_family_doctor(i_id_patient => l_id_patient);
            END IF;
        
            l_return := pk_prof_utils.get_name_signature(i_lang, i_prof, l_id_prof);
        
        END IF;
    
        RETURN l_return;
    
    END do_prof_in_charge;

    -- ***************************************************
    FUNCTION do_rank_acuity2
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_egoo            VARCHAR2(0100 CHAR);
        l_g_s             VARCHAR2(0100 CHAR);
        l_grid_origins    VARCHAR2(0100 CHAR);
        l_flg_no_color    VARCHAR2(0100 CHAR);
        l_search          NUMBER;
        l_return          NUMBER;
        l_id_triage_color NUMBER;
        l_id_origin       NUMBER;
    
        FUNCTION get_search(i_search IN NUMBER) RETURN NUMBER IS
            l_return NUMBER;
        BEGIN
        
            IF i_search = -1
            THEN
                l_return := 1;
            ELSE
                l_return := 0;
            END IF;
        
            RETURN l_return;
        
        END get_search;
    
    BEGIN
    
        l_egoo         := i_var01(1);
        l_grid_origins := i_var01(2);
        l_g_s          := i_var01(3);
    
        l_id_triage_color := i_num01(1);
        l_id_origin       := i_num01(2);
    
        l_flg_no_color := pk_edis_triage.get_flag_no_color(i_lang, i_prof, l_id_triage_color);
        l_search       := pk_utils.search_table_varchar(pk_utils.str_split_l(l_grid_origins, '|'), l_id_origin);
    
        IF l_egoo = k_yes
        THEN
            IF l_flg_no_color = l_g_s
            THEN
                l_return := 0;
            ELSE
                l_return := get_search(l_search);
            END IF;
        ELSE
            l_return := get_search(l_search);
        END IF;
    
        RETURN l_return;
    
    END do_rank_acuity2;

    -- ***************************************************
    FUNCTION do_rank_acuity3
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_flg_letter VARCHAR2(0100 CHAR);
        l_return     NUMBER;
        l_flg        VARCHAR2(0100 CHAR);
    BEGIN
    
        l_flg_letter := i_var01(1);
    
        l_flg := pk_edis_grid.orderby_flg_letter(i_prof);
    
        IF l_flg = k_yes
        THEN
        
            IF l_flg_letter = k_yes
            THEN
                l_return := 0;
            ELSE
                l_return := 1;
            END IF;
        ELSE
            l_return := NULL;
        END IF;
    
        RETURN l_return;
    
    END do_rank_acuity3;

    --**********************************************
    FUNCTION do_list_prof_name
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := 'Dr.Billy Jean, Dr. John Doe, Dr.Shaq';
        l_return := pk_hhc_core.get_hhc_professional(i_lang => i_lang, i_prof => i_prof, i_id_schedule => i_id_schedule);
    
        RETURN l_return;
    END do_list_prof_name;

    FUNCTION do_hhc_dt_visit
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return      VARCHAR2(1000 CHAR);
        l_dt_schedule schedule.dt_begin_tstz%TYPE;
    BEGIN
        SELECT x.dt_begin_tstz
          INTO l_dt_schedule
          FROM schedule x
         WHERE x.id_schedule = i_id_schedule;
    
        l_return := pk_date_utils.dt_chr_tsz(i_lang, l_dt_schedule, i_prof);
        RETURN l_return;
    
    END do_hhc_dt_visit;

    FUNCTION do_hhc_dt_visit_hour
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_schedule IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return      VARCHAR2(1000 CHAR);
        l_dt_schedule schedule.dt_begin_tstz%TYPE;
    BEGIN
        SELECT x.dt_begin_tstz
          INTO l_dt_schedule
          FROM schedule x
         WHERE x.id_schedule = i_id_schedule;
    
        l_return := pk_date_utils.date_char_hour_tsz(i_lang => i_lang,
                                                     i_date => l_dt_schedule,
                                                     i_inst => i_prof.institution,
                                                     i_soft => i_prof.software);
        RETURN l_return;
    
    END do_hhc_dt_visit_hour;

    FUNCTION do_map_hhc_visit_flg_state(
                                        --i_flg_state IN VARCHAR2
                                        i_lang       IN NUMBER,
                                        i_sch_status IN VARCHAR2,
                                        i_dsc_status IN VARCHAR2,
                                        i_flg_ehr    IN VARCHAR2,
                                        i_flg_state  IN VARCHAR2) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    
        --k_vis_state_flg_pending    CONSTANT VARCHAR2(0050 CHAR) := 'P';
        --k_vis_state_flg_scheduled  CONSTANT VARCHAR2(0050 CHAR) := 'A';
        --k_vis_state_flg_inprogress CONSTANT VARCHAR2(0050 CHAR) := 'T';
        --  CONSTANT VARCHAR2(0050 CHAR) := 'C';
    
        --k_vis_state_name_pending    CONSTANT VARCHAR2(0050 CHAR) := 'PENDING';
        --k_vis_state_name_scheduled  CONSTANT VARCHAR2(0050 CHAR) := 'SCHEDULED';
        --k_vis_state_name_inprogress CONSTANT VARCHAR2(0050 CHAR) := 'INPROGRESS';
        --k_vis_state_name_concluded  CONSTANT VARCHAR2(0050 CHAR) := 'CONCLUDED ';
    
    BEGIN
        /*
            CASE i_flg_state
                WHEN k_vis_state_flg_pending THEN
                    l_return := k_vis_state_name_pending;
                WHEN k_vis_state_flg_scheduled THEN
                    l_return := k_vis_state_name_scheduled;
                WHEN k_vis_state_flg_inprogress THEN
                    l_return := k_vis_state_name_inprogress;
                WHEN k_vis_state_flg_concluded THEN
                    l_return := k_vis_state_name_concluded;
                ELSE
                    l_return := NULL;
            END CASE;
        */
        l_return := do_get_status_icon_base(i_lang       => i_lang,
                                            i_mode       => 'INTERNAL',
                                            i_sch_status => i_sch_status,
                                            i_dsc_status => i_dsc_status,
                                            i_flg_ehr    => i_flg_ehr,
                                            i_flg_state  => i_flg_state);
    
        RETURN l_return;
    
    END do_map_hhc_visit_flg_state;

    -- ordering visit by state
    FUNCTION do_hhc_visit_flg_order
    (
        i_lang       IN NUMBER,
        i_sch_status IN VARCHAR2,
        i_dsc_status IN VARCHAR2,
        i_flg_ehr    IN VARCHAR2,
        i_flg_state  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
    
        l_return := do_get_status_icon_base(i_lang       => i_lang,
                                            i_mode       => 'ORDER',
                                            i_sch_status => i_sch_status,
                                            i_dsc_status => i_dsc_status,
                                            i_flg_ehr    => i_flg_ehr,
                                            i_flg_state  => i_flg_state);
    
        RETURN l_return;
    
    END do_hhc_visit_flg_order;

    -- ****************************************************
    FUNCTION do_desc_ana_exam_req
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_visit         NUMBER;
        l_prof_cat_type VARCHAR2(0200 CHAR);
        l_return        VARCHAR2(4000);
        l_return0       VARCHAR2(4000);
        l_return1       VARCHAR2(4000);
        l_return2       VARCHAR2(4000);
    BEGIN
    
        l_visit         := i_num01(1);
        l_prof_cat_type := i_var01(1);
    
        l_return0 := pk_grid.visit_grid_task_str_nc(i_lang, i_prof, l_visit, k_task_analysis, l_prof_cat_type);
    
        l_return1 := pk_grid.visit_grid_task_str_nc(i_lang, i_prof, l_visit, k_task_exam, l_prof_cat_type);
    
        l_return2 := pk_grid.get_prioritary_task(i_lang,
                                                 i_prof,
                                                 l_return0,
                                                 l_return1,
                                                 k_analysis_exam_icon_grid_rank,
                                                 k_flg_doctor);
    
        l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_return2);
    
        RETURN l_return;
    
    END do_desc_ana_exam_req;

    FUNCTION do_generic_presc
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_episode   NUMBER;
        l_flg_presc VARCHAR2(0050 CHAR) := i_var01(1);
        l_dt        VARCHAR2(0200 CHAR) := i_var01(2);
        l_return    VARCHAR2(4000);
        l_presc     VARCHAR2(4000);
    BEGIN
    
        l_episode   := i_num01(1);
        l_flg_presc := i_var01(1);
        l_dt        := i_var01(2);
    
        IF l_episode IS NOT NULL
        THEN
        
            IF l_flg_presc = k_yes
            THEN
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_dt);
            END IF;
        END IF;
    
        RETURN l_return;
    
    END do_generic_presc;

    -- **************************************
    FUNCTION do_extend_icon
    (
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid   VARCHAR2(0200 CHAR);
        l_id_group NUMBER;
        l_return   VARCHAR2(4000);
    BEGIN
        -- EB
        l_viewid   := i_var01(1);
        l_id_group := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                IF l_id_group IS NOT NULL
                THEN
                    l_return := 'ExtendIcon';
                END IF;
        END CASE;
    
        RETURN l_return;
    
    END do_extend_icon;

    -- **************************************
    FUNCTION do_flg_contact
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_patient NUMBER;
        l_viewid     VARCHAR2(0200 CHAR);
        l_return     VARCHAR2(4000);
    BEGIN
    
        l_viewid     := i_var01(1);
        l_id_patient := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_adt.is_contact(i_lang, i_prof, l_id_patient);
        END CASE;
    
        RETURN l_return;
    
    END do_flg_contact;

    -- **************************************
    FUNCTION do_flg_state
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_flg_status       VARCHAR2(0200 CHAR);
        l_flg_state        VARCHAR2(0200 CHAR);
        l_flg_ehr          VARCHAR2(0200 CHAR);
        l_viewid           VARCHAR2(0200 CHAR);
        l_id_dep_clin_serv NUMBER;
        l_return           VARCHAR2(4000);
    BEGIN
    
        l_flg_status       := i_var01(1);
        l_flg_state        := i_var01(2);
        l_flg_ehr          := i_var01(3);
        l_viewid           := i_var01(4);
        l_id_dep_clin_serv := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := 'A';
            
            ELSE
                -- case_02
                CASE l_flg_status
                    WHEN k_sched_canc THEN
                        l_return := l_flg_status;
                    ELSE
                        IF i_prof.software = pk_alert_constant.g_soft_home_care
                           AND l_flg_state = k_flg_state_admin_disch
                        THEN
                            l_flg_state := k_flg_state_disch;
                        END IF;
                        l_return := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
                        l_return := pk_grid.get_pre_nurse_appointment(i_lang,
                                                                      i_prof,
                                                                      l_id_dep_clin_serv,
                                                                      l_flg_ehr,
                                                                      l_return);
                END CASE;
                -- end_case_02
        END CASE;
    
        RETURN l_return;
    
    END do_flg_state;

    -- *******************************************************
    FUNCTION do_icon_contact_type
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_flg_group_header VARCHAR2(0200 CHAR);
        l_id_group         NUMBER;
        l_flg_contact_type VARCHAR2(0200 CHAR);
        l_return           VARCHAR2(4000);
    BEGIN
    
        l_flg_group_header := i_var01(1);
        l_id_group         := i_num01(1);
        l_flg_contact_type := i_var01(2);
    
        CASE l_flg_group_header
            WHEN k_yes THEN
                l_return := pk_grid_amb.get_group_presence_icon(i_lang, i_prof, l_id_group, k_no);
            ELSE
                l_return := pk_sysdomain.get_img(i_lang, k_domain_sch_presence, l_flg_contact_type);
        END CASE;
    
        RETURN l_return;
    
    END do_icon_contact_type;

    -- ****************************************
    FUNCTION do_img_state_between
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_flg_ehr         VARCHAR2(0050 CHAR);
        l_flg_state       VARCHAR2(0050 CHAR);
        l_epis_type_nurse VARCHAR2(0050 CHAR);
        l_code_domain     VARCHAR2(0200 CHAR);
    
        l_id_epis_type     NUMBER;
        l_id_dep_clin_serv NUMBER;
    
        l_return VARCHAR2(4000);
    BEGIN
    
        l_flg_ehr         := i_var01(1);
        l_flg_state       := i_var01(2);
        l_epis_type_nurse := i_var01(3);
    
        l_id_epis_type     := i_num01(1);
        l_id_dep_clin_serv := i_num01(2);
    
        IF l_id_epis_type = l_epis_type_nurse
        THEN
            l_code_domain := 'SCHEDULE_OUTP.FLG_NURSE_ACTION';
        ELSE
            l_code_domain := 'SCHEDULE_OUTP.FLG_STATE';
            l_flg_state   := pk_grid.get_pre_nurse_appointment(i_lang,
                                                               i_prof,
                                                               l_id_dep_clin_serv,
                                                               l_flg_ehr,
                                                               l_flg_state);
        END IF;
    
        l_return := pk_sysdomain.get_img(i_lang, l_code_domain, l_flg_state);
    
        RETURN l_return;
    
    END do_img_state_between;

    FUNCTION do_img_state
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_domain       sys_domain.code_domain%TYPE;
        l_domain_value sys_domain.desc_val%TYPE;
        l_epis_type    episode.id_epis_type%TYPE;
    
        l_epis_type_nurse sys_config.value%TYPE := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_viewid           VARCHAR2(0200 CHAR);
        l_flg_state        VARCHAR2(0200 CHAR);
        l_flg_ehr          VARCHAR2(0200 CHAR);
        l_flg_status       VARCHAR2(0200 CHAR);
        l_id_dep_clin_serv NUMBER;
        l_id_group         NUMBER;
        l_id_episode       NUMBER;
        l_return           VARCHAR2(4000);
        l_rank             VARCHAR2(02 CHAR) := pk_alert_constant.g_yes;
    
        l_error t_error_out;
    BEGIN
    
        l_viewid     := i_var01(1);
        l_flg_state  := i_var01(2);
        l_flg_ehr    := i_var01(3);
        l_flg_status := i_var01(4);
        IF i_var01.count > 4
        THEN
            l_rank := i_var01(5);
        END IF;
        l_id_dep_clin_serv := i_num01(1);
        l_id_group         := i_num01(2);
        l_id_episode       := i_num01(3);
    
        CASE l_viewid
        --WHEN k_view02 THEN
        --    l_return := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
        --    l_return := pk_grid.get_pre_nurse_appointment(i_lang, i_prof, l_id_dep_clin_serv, l_flg_ehr, l_return);
        --    l_return := pk_sysdomain.get_ranked_img(k_schdl_outp_state_domain, l_return, i_lang);
        
            WHEN k_view05 THEN
            
                IF l_flg_status = k_sched_canc
                THEN
                
                    IF l_rank = pk_alert_constant.g_yes
                    THEN
                        l_return := pk_sysdomain.get_ranked_img(k_schdl_outp_status_domain, l_flg_status, i_lang);
                    ELSE
                        l_return := pk_sysdomain.get_img(i_lang, k_schdl_outp_status_domain, l_flg_status);
                    END IF;
                
                ELSE
                    IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                                    i_id_epis   => l_id_episode,
                                                    o_epis_type => l_epis_type,
                                                    o_error     => l_error)
                    THEN
                        l_domain := k_schdl_outp_state_domain;
                    END IF;
                    IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
                       AND l_flg_state = k_flg_state_admin_disch
                    THEN
                        l_flg_state := k_flg_state_disch;
                    END IF;
                
                    l_return := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
                
                    IF l_epis_type <> pk_alert_constant.g_epis_type_home_health_care
                    THEN
                        l_return := pk_grid.get_pre_nurse_appointment(i_lang,
                                                                      i_prof,
                                                                      l_id_dep_clin_serv,
                                                                      l_flg_ehr,
                                                                      l_return);
                    
                    END IF;
                    IF l_epis_type = l_epis_type_nurse
                    THEN
                    
                        l_domain_value := pk_sysdomain.get_domain(i_lang     => i_lang,
                                                                  i_code_dom => pk_grid_amb.g_schdl_nurse_state_domain,
                                                                  i_val      => l_return);
                    
                        IF l_domain_value IS NOT NULL
                        THEN
                            l_domain := pk_grid_amb.g_schdl_nurse_state_domain;
                        ELSE
                            l_domain := k_schdl_outp_state_domain;
                        END IF;
                    ELSE
                    
                        l_domain := k_schdl_outp_state_domain;
                    
                    END IF;
                    IF l_rank = pk_alert_constant.g_yes
                    THEN
                        l_return := pk_sysdomain.get_ranked_img(l_domain, l_return, i_lang);
                    ELSE
                        l_return := pk_sysdomain.get_img(i_lang, l_domain, l_return);
                    END IF;
                END IF;
            
            WHEN k_view00 THEN
            
                l_return := pk_grid_amb.get_group_state_icon(i_lang, i_prof, l_id_group, pk_alert_constant.g_no);
            
            ELSE
                l_return := 'ERROR_TRANSFORM';
        END CASE;
    
        RETURN l_return;
    
    END do_img_state;

    --**********************************************************
    FUNCTION do_pat_name
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid      VARCHAR2(0200 CHAR);
        l_id_patient  NUMBER;
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
        l_viewid      := i_var01(1);
        l_id_patient  := i_num01(1);
        l_id_episode  := i_num01(2);
        l_id_schedule := i_num01(3);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
            ELSE
                l_return := pk_patient.get_pat_name(i_lang, i_prof, l_id_patient, l_id_episode, l_id_schedule);
        END CASE;
    
        RETURN l_return;
    
    END do_pat_name;

    --**********************************************
    FUNCTION do_pat_name_to_sort
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid      VARCHAR2(0200 CHAR);
        l_id_patient  NUMBER;
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
    
        l_viewid      := i_var01(1);
        l_id_patient  := i_num01(1);
        l_id_episode  := i_num01(2);
        l_id_schedule := i_num01(3);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := pk_message.get_message(i_lang, i_prof, 'SCH_T640');
            ELSE
                l_return := pk_patient.get_pat_name_to_sort(i_lang, i_prof, l_id_patient, l_id_episode, l_id_schedule);
        END CASE;
    
        RETURN upper(l_return);
    
    END do_pat_name_to_sort;

    -- ***********************
    FUNCTION do_num_clin_record
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid     VARCHAR2(0200 CHAR);
        l_id_episode NUMBER;
        l_return     VARCHAR2(4000);
    BEGIN
    
        l_viewid     := i_var01(1);
        l_id_episode := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_patient.get_alert_process_number(i_lang    => i_lang,
                                                                i_prof    => i_prof,
                                                                i_episode => l_id_episode);
        END CASE;
    
        RETURN l_return;
    
    END do_num_clin_record;

    -- ***************************
    FUNCTION do_pat_age
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid     VARCHAR2(0200 CHAR);
        l_id_patient NUMBER;
        l_return     VARCHAR2(4000);
    BEGIN
        l_viewid     := i_var01(1);
        l_id_patient := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_patient.get_pat_age(i_lang, l_id_patient, i_prof);
        END CASE;
    
        RETURN l_return;
    
    END do_pat_age;

    -- ***************************
    FUNCTION do_pat_age_to_sort
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid     VARCHAR2(0200 CHAR);
        l_id_patient NUMBER;
        l_return     VARCHAR2(4000);
        xpat         patient%ROWTYPE;
    BEGIN
        l_viewid     := i_var01(1);
        l_id_patient := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                IF l_id_patient IS NOT NULL
                THEN
                    l_return := pk_patient.get_pat_age_to_sort(i_patient => l_id_patient);
                END IF;
        END CASE;
    
        RETURN l_return;
    
    END do_pat_age_to_sort;

    FUNCTION do_pat_ndo
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid     VARCHAR2(0200 CHAR);
        l_id_patient NUMBER;
        l_return     VARCHAR2(4000);
    BEGIN
    
        l_viewid     := i_var01(1);
        l_id_patient := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_adt.get_pat_non_disc_options(i_lang, i_prof, l_id_patient);
        END CASE;
    
        RETURN l_return;
    
    END do_pat_ndo;

    -- *************************************************
    FUNCTION do_pat_nd_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid     VARCHAR2(0200 CHAR);
        l_id_patient NUMBER;
        l_return     VARCHAR2(4000);
    BEGIN
    
        l_viewid     := i_var01(1);
        l_id_patient := i_num01(1);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, l_id_patient);
        END CASE;
    
        RETURN l_return;
    
    END do_pat_nd_icon;

    -- *************************************************
    FUNCTION do_photo
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid      VARCHAR2(0200 CHAR);
        l_id_patient  NUMBER;
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
    
        l_viewid      := i_var01(1);
        l_id_patient  := i_num01(1);
        l_id_episode  := i_num01(2);
        l_id_schedule := i_num01(3);
    
        CASE l_viewid
            WHEN k_view00 THEN
                l_return := NULL;
            ELSE
                l_return := pk_patphoto.get_pat_photo(i_lang, i_prof, l_id_patient, l_id_episode, l_id_schedule);
        END CASE;
    
        RETURN l_return;
    
    END do_photo;

    -- *************************************************
    FUNCTION do_prof_follow_add
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_viewid        VARCHAR2(1000 CHAR);
        l_prof_cat_type VARCHAR2(1000 CHAR);
        l_handoff_type  VARCHAR2(1000 CHAR);
        l_flag          VARCHAR2(0001 CHAR);
    
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
        l_num         NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
    
        l_viewid        := i_var01(1);
        l_prof_cat_type := i_var01(2);
        l_handoff_type  := i_var01(3);
    
        l_id_episode  := i_num01(1);
        l_id_schedule := i_num01(2);
    
        CASE l_viewid
            WHEN k_view05 THEN
            
                l_num := pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                          i_prof,
                                                                                          l_id_episode,
                                                                                          l_prof_cat_type,
                                                                                          l_handoff_type,
                                                                                          k_yes),
                                                      i_prof.id);
            
                l_flag := iif(l_num = -1, k_yes, k_no);
            
                l_return := pk_prof_follow.get_follow_episode_by_me(i_prof, l_id_episode, l_id_schedule);
            
                l_return := iif(l_return = k_no, l_flag, k_no);
            
            ELSE
                l_return := k_no;
        END CASE;
    
        RETURN l_return;
    
    END do_prof_follow_add;

    --*************************************
    FUNCTION do_prof_follow_remove
    (
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_viewid      VARCHAR2(0200 CHAR);
        l_id_episode  NUMBER;
        l_id_schedule NUMBER;
        l_return      VARCHAR2(4000);
    BEGIN
    
        l_viewid      := i_var01(1);
        l_id_episode  := i_num01(1);
        l_id_schedule := i_num01(2);
    
        CASE l_viewid
            WHEN k_view05 THEN
                l_return := pk_prof_follow.get_follow_episode_by_me(i_prof, l_id_episode, l_id_schedule);
            ELSE
                l_return := k_no;
        END CASE;
    
        RETURN l_return;
    
    END do_prof_follow_remove;

    -- *************************************
    FUNCTION do_prof_team
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_show_resident_physician VARCHAR2(4000);
        l_handoff_type            VARCHAR2(4000);
        l_id_department           NUMBER;
        l_id_software             NUMBER;
        l_id_professional         NUMBER;
        l_id_first_nurse_resp     NUMBER;
        l_id_episode              NUMBER;
        l_return                  VARCHAR2(4000);
    BEGIN
    
        l_show_resident_physician := i_var01(1);
        l_handoff_type            := i_var01(2);
    
        l_id_department       := i_num01(1);
        l_id_software         := i_num01(2);
        l_id_professional     := i_num01(3);
        l_id_first_nurse_resp := i_num01(4);
        l_id_episode          := i_num01(5);
    
        l_return := pk_prof_teams.get_prof_current_team(i_lang,
                                                        i_prof,
                                                        l_id_department,
                                                        l_id_software,
                                                        l_id_professional,
                                                        l_id_first_nurse_resp);
    
        IF l_show_resident_physician = k_yes
        THEN
        
            l_return := pk_hand_off_core.get_resp_by_type_grid_str(i_lang,
                                                                   i_prof,
                                                                   l_id_episode,
                                                                   l_handoff_type,
                                                                   k_resident,
                                                                   'G');
        END IF;
    
        RETURN l_return;
    
    END do_prof_team;

    --**************************************
    FUNCTION do_desc_opinion_sort
    (
        i_lang          IN NUMBER,
        i_prof          IN profissional,
        i_opinion_state IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        l_pos    NUMBER;
    BEGIN
    
        l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, i_opinion_state);
        l_return := convert_grid_str_to_sort(i_str => l_return);
        RETURN l_return;
    
    END do_desc_opinion_sort;

    FUNCTION do_rank(i_var01 IN table_varchar) RETURN VARCHAR2 IS
        l_flg_state VARCHAR2(0100 CHAR);
        l_flg_ehr   VARCHAR2(0100 CHAR);
        l_return    VARCHAR2(4000);
    BEGIN
        l_flg_state := i_var01(1);
        l_flg_ehr   := i_var01(2);
    
        l_return := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
    
        l_return := iif(l_return = k_sched_med_disch, 2, 1);
    
        RETURN l_return;
    
    END do_rank;

    --***********************************************
    FUNCTION do_therapeutic_doctor
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number
    ) RETURN VARCHAR2 IS
        l_id_sch_event NUMBER;
        l_id_episode   NUMBER;
        l_id_schedule  NUMBER;
        l_return       VARCHAR2(4000);
    BEGIN
    
        l_id_sch_event := i_num01(1);
        l_id_episode   := i_num01(2);
        l_id_schedule  := i_num01(3);
    
        CASE l_id_sch_event
            WHEN k_sch_event_therap_decision THEN
                l_return := pk_therapeutic_decision.get_prof_name_resp(i_lang, i_prof, l_id_episode, l_id_schedule);
                l_return := '(' || l_return || ')';
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END do_therapeutic_doctor;

    --********************************************
    FUNCTION do_visit_reason
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_sch_event            NUMBER;
        l_id_episode              NUMBER;
        l_id_schedule             NUMBER;
        l_therap_decision_consult VARCHAR2(4000);
        l_reasongrid              VARCHAR2(4000);
        l_return                  VARCHAR2(4000);
    BEGIN
    
        l_id_sch_event := i_num01(1);
        l_id_episode   := i_num01(2);
        l_id_schedule  := i_num01(3);
    
        l_therap_decision_consult := i_var01(1);
        l_reasongrid              := i_var01(2);
    
        --case_02
        CASE l_id_sch_event
            WHEN k_sch_event_therap_decision THEN
                l_return := l_therap_decision_consult;
            ELSE
            
                --case_03
                CASE l_reasongrid
                    WHEN k_no THEN
                        l_return := NULL;
                    ELSE
                    
                        l_return := clob_to_vc2(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_id_episode  => l_id_episode,
                                                i_id_schedule => l_id_schedule);
                    
                END CASE;
                -- end case_03
        
        END CASE;
    
        RETURN l_return;
    
    END do_visit_reason;

    ------------------------------------------------------
    FUNCTION do_wr_call
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode                NUMBER;
        l_id_dcs_requested          NUMBER;
        l_waiting_room_available    VARCHAR2(0010 CHAR);
        l_waiting_room_sys_external VARCHAR2(0010 CHAR);
        l_flg_state                 VARCHAR2(0010 CHAR);
        l_flg_ehr                   VARCHAR2(0010 CHAR);
        l_return                    VARCHAR2(4000);
    BEGIN
    
        l_waiting_room_available    := i_var01(1);
        l_waiting_room_sys_external := i_var01(2);
        l_flg_state                 := i_var01(3);
        l_flg_ehr                   := i_var01(4);
        l_id_episode                := i_num01(1);
        l_id_dcs_requested          := i_num01(2);
    
        l_return := pk_wl_base.wr_call(i_prof, l_id_episode);

		/*
        l_return := pk_grid_amb.get_wr_call(i_lang                      => i_lang,
                                            i_prof                      => i_prof,
                                            i_waiting_room_available    => l_waiting_room_available,
                                            i_waiting_room_sys_external => l_waiting_room_sys_external,
                                            i_id_episode                => l_id_episode,
                                            i_flg_state                 => l_flg_state,
                                            i_flg_ehr                   => l_flg_ehr,
                                            i_id_dcs_requested          => l_id_dcs_requested);
		*/
        RETURN l_return;
    
    END do_wr_call;

    FUNCTION do_inp_grid_proc_monit_sts_str
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode NUMBER;
        l_id_visit   NUMBER;
        l_prof_cat   VARCHAR2(0010 CHAR);
    
        l_return VARCHAR2(4000);
    BEGIN
    
        l_id_episode := i_num01(2);
        l_id_visit   := i_num01(1);
        l_prof_cat   := i_var01(1);
    
        SELECT pk_grid.get_prioritary_task(i_lang,
                                           i_prof,
                                           pk_grid.get_prioritary_task(i_lang,
                                                                       i_prof,
                                                                       (pk_grid.get_prioritary_task(i_lang,
                                                                                                    i_prof,
                                                                                                    (pk_grid.get_prioritary_task(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 pk_grid.visit_grid_task_str(i_lang,
                                                                                                                                                             i_prof,
                                                                                                                                                             l_id_visit,
                                                                                                                                                             'I',
                                                                                                                                                             l_prof_cat),
                                                                                                                                 pk_grid.visit_grid_task_str(i_lang,
                                                                                                                                                             i_prof,
                                                                                                                                                             l_id_visit,
                                                                                                                                                             'M',
                                                                                                                                                             l_prof_cat),
                                                                                                                                 NULL,
                                                                                                                                 l_prof_cat,
                                                                                                                                 pk_alert_constant.g_yes)),
                                                                                                    (pk_grid.get_prioritary_task(i_lang,
                                                                                                                                 i_prof,
                                                                                                                                 pk_grid.visit_grid_task_str(i_lang,
                                                                                                                                                             i_prof,
                                                                                                                                                             l_id_visit,
                                                                                                                                                             'CO',
                                                                                                                                                             l_prof_cat),
                                                                                                                                 pk_grid.visit_grid_task_str(i_lang,
                                                                                                                                                             i_prof,
                                                                                                                                                             l_id_visit,
                                                                                                                                                             'MO',
                                                                                                                                                             l_prof_cat),
                                                                                                                                 NULL,
                                                                                                                                 l_prof_cat,
                                                                                                                                 pk_alert_constant.g_yes)),
                                                                                                    NULL,
                                                                                                    l_prof_cat)),
                                                                       (SELECT pk_grid.convert_grid_task_dates_to_str(i_lang,
                                                                                                                      i_prof,
                                                                                                                      g.nurse_activity)
                                                                          FROM grid_task g
                                                                         WHERE g.id_episode = l_id_episode),
                                                                       NULL,
                                                                       l_prof_cat),
                                           pk_grid.visit_grid_task_str(i_lang, i_prof, l_id_visit, 'T', l_prof_cat),
                                           NULL,
                                           l_prof_cat)
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    
    END do_inp_grid_proc_monit_sts_str;

    -- *****************************************

    FUNCTION do_order_without_triage
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN NUMBER IS
    
        l_return     NUMBER;
        l_sys_config sys_config.id_sys_config%TYPE;
        l_indice     NUMBER;
        l_config_origin CONSTANT sys_config.id_sys_config%TYPE := 'GRID_ORIGINS';
        g_grid_origins     sys_config.value%TYPE;
        g_tab_grid_origins table_varchar;
    
        l_id_origin       NUMBER;
        l_id_triage_color NUMBER;
    
    BEGIN
    
        l_id_origin       := i_num01(1);
        l_id_triage_color := i_num01(2);
    
        g_grid_origins     := pk_sysconfig.get_config(l_config_origin, i_prof);
        g_tab_grid_origins := pk_utils.str_split_l(g_grid_origins, '|');
        l_indice           := pk_utils.search_table_varchar(g_tab_grid_origins, l_id_origin);
    
        l_sys_config := pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', i_prof);
    
        l_return := iif(l_indice = -1, 1, 0);
    
        IF l_sys_config = 'Y'
        THEN
            IF pk_edis_triage.get_flag_no_color(i_lang, i_prof, l_id_triage_color) = 'S'
            THEN
                l_return := 0;
            END IF;
        END IF;
    
        RETURN l_return;
    END do_order_without_triage;

    FUNCTION do_fast_track_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_id_episode      NUMBER;
        l_id_fast_track   NUMBER;
        l_id_triage_color NUMBER;
        l_has_transfer    NUMBER;
    
        l_g_icon_ft          VARCHAR2(0010 CHAR);
        l_g_icon_ft_transfer VARCHAR2(0010 CHAR);
    
        l_type VARCHAR2(0010 CHAR);
    
        l_return VARCHAR2(4000);
    
    BEGIN
    
        l_id_episode      := i_num01(1);
        l_id_fast_track   := i_num01(2);
        l_id_triage_color := i_num01(3);
        l_has_transfer    := i_num01(4);
    
        l_g_icon_ft          := i_var01(1);
        l_g_icon_ft_transfer := i_var01(2);
    
        l_type := iif(l_has_transfer = 0, l_g_icon_ft, l_g_icon_ft_transfer);
    
        l_return := pk_fast_track.get_fast_track_icon(i_lang,
                                                      i_prof,
                                                      l_id_episode,
                                                      l_id_fast_track,
                                                      l_id_triage_color,
                                                      l_type,
                                                      l_has_transfer);
        RETURN l_return;
    
    END do_fast_track_icon;

    -- *****************************************

    FUNCTION do_oris_dt_pat_status
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN NUMBER IS
    
        l_return               NUMBER;
        l_flg_pat_status       VARCHAR2(3 CHAR) := i_var01(1);
        l_dt_interv_start_tstz VARCHAR2(50 CHAR) := i_var01(2);
        l_id_episode           NUMBER := i_num01(1);
    
    BEGIN
    
        SELECT pk_date_utils.date_send_tsz(i_lang,
                                           decode(l_flg_pat_status,
                                                  'S',
                                                  nvl(l_dt_interv_start_tstz,
                                                      (SELECT decode(ps.flg_pat_status,
                                                                     'L', --g_pat_status_l,
                                                                     ps.dt_status_tstz,
                                                                     'S', --g_pat_status_s,
                                                                     ps.dt_status_tstz,
                                                                     NULL) dt_status_tstz
                                                         FROM sr_pat_status ps
                                                        WHERE ps.id_episode = l_id_episode
                                                          AND ps.flg_pat_status = l_flg_pat_status
                                                          AND ps.dt_status_tstz =
                                                              (SELECT MAX(ps1.dt_status_tstz)
                                                                 FROM sr_pat_status ps1
                                                                WHERE ps1.id_episode = ps.id_episode
                                                                  AND ps1.flg_pat_status = ps.flg_pat_status))),
                                                  (SELECT decode(ps.flg_pat_status,
                                                                 'L', --g_pat_status_l,
                                                                 ps.dt_status_tstz,
                                                                 'S', --g_pat_status_s,
                                                                 ps.dt_status_tstz,
                                                                 NULL) dt_status_tstz
                                                     FROM sr_pat_status ps
                                                    WHERE ps.id_episode = l_id_episode
                                                      AND ps.flg_pat_status = l_flg_pat_status
                                                      AND ps.dt_status_tstz =
                                                          (SELECT MAX(ps1.dt_status_tstz)
                                                             FROM sr_pat_status ps1
                                                            WHERE ps1.id_episode = ps.id_episode
                                                              AND ps1.flg_pat_status = ps.flg_pat_status))),
                                           i_prof)
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    END do_oris_dt_pat_status;

    -- *****************************************

    FUNCTION do_oris_prof_follow_add
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN NUMBER IS
    
        l_return      NUMBER;
        l_id_episode  NUMBER := i_num01(1);
        l_id_schedule NUMBER := i_num01(2);
    
    BEGIN
    
        SELECT decode(pk_prof_follow.get_follow_episode_by_me(i_prof, l_id_episode, l_id_schedule),
                      pk_alert_constant.g_no,
                      decode(pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                                              i_prof,
                                                                                              l_id_episode,
                                                                                              pk_gridfilter.get_strings('l_prof_cat',
                                                                                                                        i_lang,
                                                                                                                        i_prof),
                                                                                              pk_gridfilter.get_strings('l_hand_off_type',
                                                                                                                        i_lang,
                                                                                                                        i_prof),
                                                                                              pk_alert_constant.g_yes),
                                                          i_prof.id),
                             -1,
                             pk_alert_constant.g_yes,
                             pk_alert_constant.g_no),
                      pk_alert_constant.g_no)
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    END do_oris_prof_follow_add;

    FUNCTION do_sw_visit_reason_sort
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob       CLOB;
        l_return         VARCHAR2(1000 CHAR);
        l_id_sofware     NUMBER := i_num01(1);
        l_id_episode     NUMBER := i_num01(2);
        l_id_schedule    NUMBER := i_num01(3);
        l_id_institution NUMBER := i_num01(4);
        l_id_software    NUMBER := i_num01(5);
        l_id_reason      NUMBER := i_num01(6);
    
        l_reasongrid      VARCHAR2(5 CHAR) := i_var01(1);
        l_flg_reason_type VARCHAR2(5 CHAR) := i_var01(2);
    
    BEGIN
    
        SELECT decode(l_id_sofware,
                      8, -- EDIS
                      pk_edis_grid.get_complaint_grid(i_lang, i_prof, l_id_episode),
                      11, -- INP
                      pk_edis_grid.get_complaint_grid(i_lang, i_prof, l_id_episode),
                      3, -- CARE
                      decode(l_reasongrid,
                             'N',
                             NULL,
                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                         profissional(i_prof.id,
                                                                                                                      l_id_institution,
                                                                                                                      l_id_software),
                                                                                                         l_id_episode,
                                                                                                         l_id_schedule),
                                                              4000)),
                      2, -- ORIS
                      pk_sr_clinical_info.get_proposed_surgery(i_lang, l_id_episode, i_prof, 'N'),
                      -- OUTP E PP
                      nvl((SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                               decode(l_flg_reason_type, 'C', l_id_reason, NULL)),
                                                           NULL,
                                                           ec.patient_complaint,
                                                           pk_translation.get_translation(i_lang,
                                                                                          'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                          nvl(ec.id_complaint,
                                                                                              decode(l_flg_reason_type,
                                                                                                     'C',
                                                                                                     l_id_reason,
                                                                                                     NULL)))) || '; '),
                                        1,
                                        length(concatenate(decode(nvl(ec.id_complaint,
                                                                      decode(l_flg_reason_type, 'C', l_id_reason, NULL)),
                                                                  NULL,
                                                                  ec.patient_complaint,
                                                                  pk_translation.get_translation(i_lang,
                                                                                                 'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                 nvl(ec.id_complaint,
                                                                                                     decode(l_flg_reason_type,
                                                                                                            'C',
                                                                                                            l_id_reason,
                                                                                                            NULL))) || '; '))) -
                                        length('; '))
                            FROM epis_complaint ec
                           WHERE ec.id_episode = l_id_episode
                             AND nvl(ec.flg_status, 'A') = 'A'),
                          decode(l_reasongrid,
                                 'Y',
                                 pk_complaint.get_reason_desc(i_lang,
                                                              profissional(i_prof.id, l_id_institution, l_id_software),
                                                              l_id_episode,
                                                              l_id_schedule))))
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('l_reasongrid - ' || l_reasongrid || 'l_flg_reason_type - ' || l_flg_reason_type ||
                                  'l_id_sofware - ' || l_id_sofware || 'l_id_episode - ' || l_id_episode ||
                                  'l_id_schedule - ' || l_id_schedule || 'l_id_institution - ' || l_id_institution ||
                                  'l_id_software - ' || l_id_software || 'l_id_reason - ' || l_id_reason);
    END do_sw_visit_reason_sort;

    FUNCTION do_social_worker_visit_reason
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN CLOB IS
    
        l_return         CLOB;
        l_id_sofware     NUMBER := i_num01(1);
        l_id_episode     NUMBER := i_num01(2);
        l_id_schedule    NUMBER := i_num01(3);
        l_id_institution NUMBER := i_num01(4);
        l_id_software    NUMBER := i_num01(5);
        l_id_reason      NUMBER := i_num01(6);
    
        l_reasongrid      VARCHAR2(5 CHAR) := i_var01(1);
        l_flg_reason_type VARCHAR2(5 CHAR) := i_var01(2);
    
    BEGIN
    
        SELECT decode(l_id_sofware,
                      8, -- EDIS
                      pk_edis_grid.get_complaint_grid(i_lang, i_prof, l_id_episode),
                      11, -- INP
                      pk_edis_grid.get_complaint_grid(i_lang, i_prof, l_id_episode),
                      3, -- CARE
                      decode(l_reasongrid,
                             'N',
                             NULL,
                             pk_string_utils.clob_to_varchar2(pk_clinical_info.get_epis_reason_for_visit(i_lang,
                                                                                                         profissional(i_prof.id,
                                                                                                                      l_id_institution,
                                                                                                                      l_id_software),
                                                                                                         l_id_episode,
                                                                                                         l_id_schedule),
                                                              4000)),
                      2, -- ORIS
                      pk_sr_clinical_info.get_proposed_surgery(i_lang, l_id_episode, i_prof, 'N'),
                      -- OUTP E PP
                      nvl((SELECT substr(concatenate(decode(nvl(ec.id_complaint,
                                                               decode(l_flg_reason_type, 'C', l_id_reason, NULL)),
                                                           NULL,
                                                           ec.patient_complaint,
                                                           pk_translation.get_translation(i_lang,
                                                                                          'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                          nvl(ec.id_complaint,
                                                                                              decode(l_flg_reason_type,
                                                                                                     'C',
                                                                                                     l_id_reason,
                                                                                                     NULL)))) || '; '),
                                        1,
                                        length(concatenate(decode(nvl(ec.id_complaint,
                                                                      decode(l_flg_reason_type, 'C', l_id_reason, NULL)),
                                                                  NULL,
                                                                  ec.patient_complaint,
                                                                  pk_translation.get_translation(i_lang,
                                                                                                 'COMPLAINT.CODE_COMPLAINT.' ||
                                                                                                 nvl(ec.id_complaint,
                                                                                                     decode(l_flg_reason_type,
                                                                                                            'C',
                                                                                                            l_id_reason,
                                                                                                            NULL))) || '; '))) -
                                        length('; '))
                            FROM epis_complaint ec
                           WHERE ec.id_episode = l_id_episode
                             AND nvl(ec.flg_status, 'A') = 'A'),
                          decode(l_reasongrid,
                                 'Y',
                                 pk_complaint.get_reason_desc(i_lang,
                                                              profissional(i_prof.id, l_id_institution, l_id_software),
                                                              l_id_episode,
                                                              l_id_schedule))))
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error('l_reasongrid - ' || l_reasongrid || 'l_flg_reason_type - ' || l_flg_reason_type ||
                                  'l_id_sofware - ' || l_id_sofware || 'l_id_episode - ' || l_id_episode ||
                                  'l_id_schedule - ' || l_id_schedule || 'l_id_institution - ' || l_id_institution ||
                                  'l_id_software - ' || l_id_software || 'l_id_reason - ' || l_id_reason);
    END do_social_worker_visit_reason;

    FUNCTION do_social_worker_fu_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_return            VARCHAR2(1000 CHAR);
        l_id_opinion        NUMBER := i_num01(1);
        l_id_episode_answer NUMBER := i_num01(2);
        l_id_prof_questions NUMBER := i_num01(3);
        l_e_id_institution  NUMBER := i_num01(4);
        l_e_id_software     NUMBER := i_num01(5);
    
        l_flg_state    VARCHAR2(5 CHAR) := i_var01(1);
        l_type_opinion VARCHAR2(5 CHAR) := i_var01(2);
        l_date         VARCHAR2(500 CHAR) := i_var01(3);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_id_opinion IS NULL THEN -- este episodio nao tem pedido parecer
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'I',
                                                         'N',
                                                         NULL,
                                                         NULL,
                                                         'DISCH_TRANSF_INST.FLG_STATUS',
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL)
                   WHEN l_id_opinion IS NOT NULL
                        AND l_id_episode_answer IS NULL
                        AND (l_flg_state = 'V' OR
                        (l_flg_state = 'R' AND
                        pk_opinion.check_approval_need(profissional(l_id_prof_questions,
                                                                          l_e_id_institution,
                                                                          l_e_id_software),
                                                             l_type_opinion) = 'N')) THEN --tem pedido de parecer aguardando aceitaçao
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'D',
                                                         NULL,
                                                         NULL,
                                                         l_date,
                                                         NULL,
                                                         NULL,
                                                         pk_alert_constant.g_color_red,
                                                         pk_alert_constant.g_color_null,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         current_timestamp)
                   WHEN l_id_opinion IS NOT NULL
                        AND l_id_episode_answer IS NULL
                        AND l_flg_state = 'R'
                        AND pk_opinion.check_approval_need(profissional(l_id_prof_questions,
                                                                        l_e_id_institution,
                                                                        l_e_id_software),
                                                           l_type_opinion) = 'Y' THEN
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'I',
                                                         'N',
                                                         NULL,
                                                         NULL,
                                                         'DISCH_TRANSF_INST.FLG_STATUS',
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL)
                   WHEN l_id_opinion IS NOT NULL
                        AND l_flg_state IN ('X', 'O') THEN
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'I',
                                                         'N',
                                                         NULL,
                                                         NULL,
                                                         'DISCH_TRANSF_INST.FLG_STATUS',
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL)
                   ELSE -- todos os outros casos sao pedidos cancelados rejeitados, concluidos, em andamento, etc.
                    pk_utils.get_status_string_immediate(i_lang,
                                                         i_prof,
                                                         'I',
                                                         l_flg_state,
                                                         NULL,
                                                         NULL,
                                                         'OPINION.FLG_STATE.REQUEST',
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL)
               END
          INTO l_return
          FROM dual;
    
        RETURN l_return;
    END do_social_worker_fu_icon;

    FUNCTION do_adm_professional
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob            CLOB;
        l_return              VARCHAR2(1000 CHAR);
        l_id_external_request NUMBER := i_num01(1);
        l_id_prof_requested   NUMBER := i_num01(2);
        l_id_consult_req      NUMBER := i_num01(3);
        l_id_professional     NUMBER := i_num01(4);
    
        l_sel_type     VARCHAR2(5 CHAR) := i_var01(1);
        l_sel_sub_type VARCHAR2(5 CHAR) := i_var01(2);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_sel_type IN ('I', 'E') THEN
                    NULL
                   WHEN l_sel_type IN ('R') THEN
                    nvl((SELECT pk_prof_utils.get_name_signature(i_lang,
                                                                profissional(i_prof.id,
                                                                             i_prof.institution,
                                                                             i_prof.software),
                                                                (SELECT pk_ref_dest_phy.get_suggested_physician(i_lang,
                                                                                                                profissional(i_prof.id,
                                                                                                                             i_prof.institution,
                                                                                                                             i_prof.software),
                                                                                                                l_id_external_request)
                                                                   FROM dual))
                          FROM dual),
                        (SELECT pk_message.get_message(i_lang,
                                                       profissional(i_prof.id, i_prof.institution, i_prof.software),
                                                       'FUTURE_EVENTS_T017')
                           FROM dual))
                   WHEN l_sel_sub_type = 'C1' THEN
                    nvl2(l_id_prof_requested,
                         (SELECT pk_prof_utils.get_name_signature(i_lang,
                                                                  profissional(i_prof.id,
                                                                               i_prof.institution,
                                                                               i_prof.software),
                                                                  l_id_prof_requested)
                            FROM dual),
                         (SELECT pk_events.get_fe_request_prof_str(i_lang,
                                                                   profissional(i_prof.id,
                                                                                i_prof.institution,
                                                                                i_prof.software),
                                                                   l_id_consult_req,
                                                                   'N')
                            FROM dual))
                   ELSE
                    (SELECT pk_prof_utils.get_name_signature(i_lang,
                                                             profissional(i_prof.id, i_prof.institution, i_prof.software),
                                                             l_id_professional)
                       FROM dual)
               END
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alertlog.log_error('l_id_external_request - ' || l_id_external_request || 'l_id_prof_requested - ' ||
                                  l_id_prof_requested || 'l_id_consult_req - ' || l_id_consult_req ||
                                  'l_id_professional - ' || l_id_professional || 'l_sel_type - ' || l_sel_type ||
                                  'l_sel_sub_type - ' || l_sel_sub_type);
    END do_adm_professional;

    FUNCTION do_adm_dt_request_desc
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob           CLOB;
        l_return             VARCHAR2(1000 CHAR);
        l_id_institution     NUMBER := i_num01(1);
        l_id_instit_requests NUMBER := i_num01(2);
    
        l_sel_type            VARCHAR2(5 CHAR) := i_var01(1);
        l_sel_sub_type        VARCHAR2(5 CHAR) := i_var01(2);
        l_dt_begin_tstz       VARCHAR2(50 CHAR) := i_var01(3);
        l_dt_schedule_tstz    VARCHAR2(50 CHAR) := i_var01(4);
        l_dt_last_update      VARCHAR2(50 CHAR) := i_var01(5);
        l_dt_consult_req_tstz VARCHAR2(50 CHAR) := i_var01(6);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_sel_type IN ('I', 'E') THEN
                    (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                     (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           l_id_institution,
                                                                                                           NULL),
                                                                                              nvl(l_dt_begin_tstz,
                                                                                                  l_dt_schedule_tstz))
                                                        FROM dual),
                                                     i_prof)
                       FROM dual)
                   WHEN l_sel_type IN ('R')
                        OR l_sel_type IS NULL THEN
                    NULL
                   WHEN l_sel_sub_type = 'C1' THEN
                    (SELECT pk_date_utils.date_char_hour_tsz(i_lang,
                                                             nvl(l_dt_last_update, l_dt_consult_req_tstz),
                                                             i_prof.institution,
                                                             i_prof.software)
                       FROM dual) || chr(10) || (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                                                 (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                                       l_id_instit_requests,
                                                                                                                                       NULL),
                                                                                                                          nvl(l_dt_last_update,
                                                                                                                              l_dt_consult_req_tstz))
                                                                                    FROM dual),
                                                                                 i_prof)
                                                   FROM dual)
                   ELSE
                    (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                     (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           l_id_instit_requests,
                                                                                                           NULL),
                                                                                              nvl(l_dt_last_update,
                                                                                                  l_dt_consult_req_tstz))
                                                        FROM dual),
                                                     i_prof)
                       FROM dual)
               END
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END do_adm_dt_request_desc;

    FUNCTION do_adm_status_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob           CLOB;
        l_return             VARCHAR2(1000 CHAR);
        l_decision_urg_level NUMBER := i_num01(1);
    
        l_sel_type            VARCHAR2(5 CHAR) := i_var01(1);
        l_sel_sub_type        VARCHAR2(5 CHAR) := i_var01(2);
        l_dt_req_tstz         consult_req.dt_consult_req_tstz%TYPE := i_var01(3);
        l_dt_begin_tstz       consult_req.dt_consult_req_tstz%TYPE := i_var01(4);
        l_dt_schedule_tstz    consult_req.dt_consult_req_tstz%TYPE := i_var01(5);
        l_flg_status          VARCHAR2(5 CHAR) := i_var01(6);
        l_dt_status_tstz      consult_req.dt_consult_req_tstz%TYPE := i_var01(7);
        l_dt_last_update      consult_req.dt_consult_req_tstz%TYPE := i_var01(8);
        l_dt_consult_req_tstz consult_req.dt_consult_req_tstz%TYPE := i_var01(9);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_sel_type IN ('I', 'E') THEN
                    (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'DI',
                                                                 'P',
                                                                 NULL,
                                                                 to_char(nvl(l_dt_req_tstz,
                                                                             nvl(l_dt_begin_tstz, l_dt_schedule_tstz)),
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                                 'CONSULT_REQ.FLG_STATUS',
                                                                 NULL,
                                                                 '0xC86464',
                                                                 '0xEBEBC8',
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 pk_sysdomain.get_domain(i_code_dom => 'CONSULT_REQ.FLG_STATUS',
                                                                                         i_val      => l_flg_status,
                                                                                         i_lang     => i_lang),
                                                                 NULL,
                                                                 current_timestamp)
                       FROM dual)
                   WHEN l_sel_type IN ('R') THEN
                    (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'DI',
                                                                 decode(l_flg_status,
                                                                        'A',
                                                                        to_char(nvl(l_decision_urg_level, 3)),
                                                                        l_flg_status),
                                                                 NULL,
                                                                 to_char(l_dt_status_tstz,
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                                 decode(l_flg_status,
                                                                        'A',
                                                                        'P1_TOSCHEDULE_GRID_ICON.1',
                                                                        'P1_EXTERNAL_REQUESl_flg_status'),
                                                                 NULL,
                                                                 '0xC86464',
                                                                 '0xEBEBC8',
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 current_timestamp)
                       FROM dual)
                   WHEN l_sel_type IS NULL THEN
                    NULL
                   WHEN l_sel_sub_type = 'C1' THEN
                    CASE
                        WHEN l_flg_status = 'C' THEN
                         (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                      i_prof,
                                                                      'I',
                                                                      l_flg_status,
                                                                      NULL,
                                                                      NULL,
                                                                      'CONSULT_REQ.FLG_STATUS',
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      pk_sysdomain.get_domain(i_code_dom => 'CONSULT_REQ.FLG_STATUS',
                                                                                              i_val      => l_flg_status,
                                                                                              i_lang     => i_lang),
                                                                      NULL,
                                                                      current_timestamp)
                            FROM dual)
                        WHEN l_flg_status = 'H' THEN
                         (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                      i_prof,
                                                                      'I',
                                                                      'H',
                                                                      NULL,
                                                                      NULL,
                                                                      'CONSULT_REQ.FLG_STATUS',
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      pk_sysdomain.get_domain(i_code_dom => 'CONSULT_REQ.FLG_STATUS',
                                                                                              i_val      => l_flg_status,
                                                                                              i_lang     => i_lang),
                                                                      NULL,
                                                                      NULL)
                            FROM dual)
                        ELSE
                         (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                      i_prof,
                                                                      'DI',
                                                                      'P',
                                                                      NULL,
                                                                      to_char(nvl(l_dt_last_update, l_dt_consult_req_tstz),
                                                                              pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                                      'CONSULT_REQ.FLG_STATUS',
                                                                      NULL,
                                                                      '0xC86464',
                                                                      '0xEBEBC8',
                                                                      NULL,
                                                                      NULL,
                                                                      NULL,
                                                                      pk_sysdomain.get_domain(i_code_dom => 'CONSULT_REQ.FLG_STATUS',
                                                                                              i_val      => l_flg_status,
                                                                                              i_lang     => i_lang),
                                                                      NULL,
                                                                      current_timestamp)
                            FROM dual)
                    END
                   ELSE
                    (SELECT pk_utils.get_status_string_immediate(i_lang,
                                                                 i_prof,
                                                                 'DI',
                                                                 'P',
                                                                 NULL,
                                                                 to_char(nvl(l_dt_last_update, l_dt_consult_req_tstz),
                                                                         pk_alert_constant.g_dt_yyyymmddhh24miss),
                                                                 'CONSULT_REQ.FLG_STATUS',
                                                                 NULL,
                                                                 '0xC86464',
                                                                 '0xEBEBC8',
                                                                 NULL,
                                                                 NULL,
                                                                 NULL,
                                                                 pk_sysdomain.get_domain(i_code_dom => 'CONSULT_REQ.FLG_STATUS',
                                                                                         i_val      => l_flg_status,
                                                                                         i_lang     => i_lang),
                                                                 NULL,
                                                                 current_timestamp)
                       FROM dual)
               END
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END do_adm_status_icon;

    FUNCTION do_adm_scheduled_desc
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob           CLOB;
        l_return             VARCHAR2(1000 CHAR);
        l_id_institution     NUMBER := i_num01(1);
        l_id_instit_requests NUMBER := i_num01(2);
    
        l_sel_type         VARCHAR2(5 CHAR) := i_var01(1);
        l_sel_sub_type     VARCHAR2(5 CHAR) := i_var01(2);
        l_dt_begin_tstz    consult_req.dt_consult_req_tstz%TYPE := i_var01(3);
        l_dt_schedule_tstz consult_req.dt_consult_req_tstz%TYPE := i_var01(4);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_sel_type IN ('I', 'E') THEN
                    (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                     (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           l_id_institution,
                                                                                                           NULL),
                                                                                              nvl(l_dt_begin_tstz,
                                                                                                  l_dt_schedule_tstz))
                                                        FROM dual),
                                                     i_prof)
                       FROM dual)
                   WHEN l_sel_type IN ('R')
                        OR l_sel_sub_type = 'C1'
                        OR l_sel_type IS NULL THEN
                    NULL
                   ELSE
                    (SELECT pk_date_utils.date_char_hour_tsz(i_lang, l_dt_begin_tstz, i_prof.institution, i_prof.software)
                       FROM dual) || chr(10) || (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                                                 (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                                       l_id_instit_requests,
                                                                                                                                       NULL),
                                                                                                                          l_dt_begin_tstz)
                                                                                    FROM dual),
                                                                                 i_prof)
                                                   FROM dual)
               END
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END do_adm_scheduled_desc;

    FUNCTION do_adm_proposed
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob           CLOB;
        l_return             VARCHAR2(1000 CHAR);
        l_id_institution     NUMBER := i_num01(1);
        l_id_instit_requests NUMBER := i_num01(2);
    
        l_sel_type VARCHAR2(5 CHAR) := i_var01(1);
        --l_sel_sub_type        VARCHAR2(5 CHAR) := i_var01(2);
        l_dt_begin_tstz       consult_req.dt_consult_req_tstz%TYPE := i_var01(3);
        l_dt_schedule_tstz    consult_req.dt_consult_req_tstz%TYPE := i_var01(4);
        l_dt_scheduled_tstz   consult_req.dt_consult_req_tstz%TYPE := i_var01(5);
        l_dt_begin_event      consult_req.dt_consult_req_tstz%TYPE := i_var01(6);
        l_dt_end_event        consult_req.dt_consult_req_tstz%TYPE := i_var01(7);
        l_dt_consult_req_tstz consult_req.dt_consult_req_tstz%TYPE := i_var01(8);
    
    BEGIN
    
        SELECT CASE
                   WHEN l_sel_type IN ('I') THEN
                    (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                     (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           l_id_institution,
                                                                                                           NULL),
                                                                                              nvl(l_dt_begin_tstz,
                                                                                                  l_dt_schedule_tstz))
                                                        FROM dual),
                                                     i_prof)
                       FROM dual)
                   WHEN l_sel_type IN ('E') THEN
                    (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                     (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                           l_id_institution,
                                                                                                           NULL),
                                                                                              l_dt_schedule_tstz)
                                                        FROM dual),
                                                     i_prof)
                       FROM dual)
                   WHEN l_sel_type IN ('R')
                        OR l_sel_type IS NULL THEN
                    NULL
                   ELSE
                    nvl((SELECT pk_date_utils.date_send_tsz(i_lang,
                                                           (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                 l_id_instit_requests,
                                                                                                                 NULL),
                                                                                                    nvl(l_dt_scheduled_tstz,
                                                                                                        nvl(l_dt_begin_event,
                                                                                                            l_dt_consult_req_tstz)))
                                                              FROM dual),
                                                           i_prof)
                          FROM dual),
                        nvl2(l_dt_end_event,
                             (SELECT pk_date_utils.dt_chr(i_lang,
                                                          (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                l_id_instit_requests,
                                                                                                                NULL),
                                                                                                   l_dt_begin_event)
                                                             FROM dual),
                                                          i_prof)
                                FROM dual) || ' ' || (SELECT pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T073')
                                                        FROM dual) || ' ' ||
                             (SELECT pk_date_utils.dt_chr(i_lang,
                                                          (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                l_id_instit_requests,
                                                                                                                NULL),
                                                                                                   l_dt_end_event)
                                                             FROM dual),
                                                          i_prof)
                                FROM dual),
                             (SELECT pk_date_utils.dt_chr(i_lang,
                                                          (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                l_id_instit_requests,
                                                                                                                NULL),
                                                                                                   l_dt_begin_event)
                                                             FROM dual),
                                                          i_prof)
                                FROM dual)))
               END
          INTO l_ret_clob
          FROM dual;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END do_adm_proposed;

    FUNCTION do_adm_request_date
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_ret_clob           CLOB;
        l_return             VARCHAR2(1000 CHAR);
        l_id_institution     NUMBER := i_num01(1);
        l_id_instit_requests NUMBER := i_num01(2);
        -- l_id_combination_spec   NUMBER := i_num01(3);
        l_id_combination_events NUMBER := i_num01(4);
    
        l_sel_type VARCHAR2(5 CHAR) := i_var01(1);
        --l_sel_sub_type      VARCHAR2(5 CHAR) := i_var01(2);
        l_dt_begin_tstz     consult_req.dt_consult_req_tstz%TYPE := i_var01(3);
        l_dt_schedule_tstz  consult_req.dt_consult_req_tstz%TYPE := i_var01(4);
        l_dt_scheduled_tstz consult_req.dt_consult_req_tstz%TYPE := i_var01(5);
        l_dt_begin_event    consult_req.dt_consult_req_tstz%TYPE := i_var01(6);
        l_dt_end_event      consult_req.dt_consult_req_tstz%TYPE := i_var01(7);
    
        l_msg_no_dependency sys_message.desc_message%TYPE := pk_message.get_message(i_lang,
                                                                                    i_prof,
                                                                                    'FUTURE_EVENTS_T074');
    
    BEGIN
    
        IF l_sel_type IS NOT NULL
        THEN
            SELECT (SELECT CASE
                               WHEN l_sel_type IN ('I') THEN
                                (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                                 (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                       l_id_institution,
                                                                                                                       NULL),
                                                                                                          nvl(l_dt_begin_tstz,
                                                                                                              l_dt_schedule_tstz))
                                                                    FROM dual),
                                                                 i_prof)
                                   FROM dual)
                               WHEN l_sel_type IN ('E') THEN
                                (SELECT pk_date_utils.dt_chr_tsz(i_lang,
                                                                 (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                       l_id_institution,
                                                                                                                       NULL),
                                                                                                          l_dt_schedule_tstz)
                                                                    FROM dual),
                                                                 i_prof)
                                   FROM dual)
                               WHEN l_sel_type IN ('R') THEN
                                NULL
                               ELSE
                                nvl((SELECT pk_date_utils.dt_chr(i_lang,
                                                                (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                      l_id_instit_requests,
                                                                                                                      NULL),
                                                                                                         nvl(l_dt_scheduled_tstz,
                                                                                                             l_dt_begin_event))
                                                                   FROM dual),
                                                                i_prof)
                                      FROM dual),
                                    nvl2(l_dt_end_event,
                                         (SELECT pk_date_utils.dt_chr(i_lang,
                                                                      (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                            l_id_instit_requests,
                                                                                                                            NULL),
                                                                                                               l_dt_begin_event)
                                                                         FROM dual),
                                                                      i_prof)
                                            FROM dual) || ' ' ||
                                         (SELECT pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T073')
                                            FROM dual) || ' ' || (SELECT pk_date_utils.dt_chr(i_lang,
                                                                                              (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                                                    l_id_instit_requests,
                                                                                                                                                    NULL),
                                                                                                                                       l_dt_end_event)
                                                                                                 FROM dual),
                                                                                              i_prof)
                                                                    FROM dual),
                                         (SELECT pk_date_utils.dt_chr(i_lang,
                                                                      (SELECT pk_date_utils.trunc_insttimezone(profissional(NULL,
                                                                                                                            l_id_instit_requests,
                                                                                                                            NULL),
                                                                                                               l_dt_begin_event)
                                                                         FROM dual),
                                                                      i_prof)
                                            FROM dual)))
                           END
                      FROM dual)
              INTO l_ret_clob
              FROM dual;
        
        ELSE
        
            SELECT nvl2(l_dt_schedule_tstz,
                        pk_date_utils.dt_chr(i_lang,
                                             pk_date_utils.trunc_insttimezone(profissional(NULL, l_id_institution, NULL),
                                                                              l_dt_begin_tstz),
                                             i_prof) || ' ' ||
                        (SELECT pk_message.get_message(i_lang, i_prof, 'FUTURE_EVENTS_T073')
                           FROM dual) || ' ' ||
                        pk_date_utils.dt_chr(i_lang,
                                             pk_date_utils.trunc_insttimezone(profissional(NULL, l_id_institution, NULL),
                                                                              l_dt_schedule_tstz),
                                             i_prof),
                        pk_date_utils.dt_chr(i_lang,
                                             pk_date_utils.trunc_insttimezone(profissional(NULL, l_id_institution, NULL),
                                                                              l_dt_begin_tstz),
                                             i_prof))
              INTO l_ret_clob
              FROM dual;
        END IF;
    
        l_return := pk_string_utils.clob_to_varchar2(i_clob => l_ret_clob, i_maxlenght_bytes => 1000);
    
        RETURN l_return;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
    END do_adm_request_date;

    FUNCTION do_internment
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        i_id_episode episode.id_episode%TYPE;
        l_return     VARCHAR2(1000 CHAR);
    BEGIN
    
        i_id_episode := i_num01(1);
    
        SELECT CASE
                   WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_INTERNMENT', i_prof) THEN
                    pk_message.get_message(i_lang, 'GRID_ADMIN_M001') || ' ' ||
                    pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                   WHEN drt.id_discharge_reason = pk_sysconfig.get_config('ID_DISCHARGE_CE', i_prof) THEN
                    pk_message.get_message(i_lang, 'GRID_ADMIN_M002') || ' ' ||
                    pk_translation.get_translation(i_lang, cs1.code_clinical_service)
                   WHEN drt.id_discharge_reason IN
                        (pk_sysconfig.get_config('ID_DISCHARGE_INSTIT', i_prof),
                         pk_sysconfig.get_config('ID_DISCHARGE_CS', i_prof)) THEN
                    pk_translation.get_translation(i_lang, i.code_institution)
                   ELSE
                    pk_translation.get_translation(i_lang, drn.code_discharge_reason)
               END
          INTO l_return
          FROM discharge d
          JOIN disch_reas_dest drt
            ON d.id_disch_reas_dest = drt.id_disch_reas_dest
          LEFT JOIN dep_clin_serv dcs1
            ON dcs1.id_dep_clin_serv = drt.id_dep_clin_serv
          LEFT JOIN discharge_reason drn
            ON drn.id_discharge_reason = drt.id_discharge_reason
          LEFT JOIN clinical_service cs1
            ON cs1.id_clinical_service = dcs1.id_clinical_service
          LEFT JOIN institution i
            ON i.id_institution = drt.id_institution
         WHERE d.id_episode = i_id_episode;
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END do_internment;

    FUNCTION do_appointment_type
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1000 CHAR);
    BEGIN
        SELECT pk_schedule.string_sch_type(i_lang => i_lang, i_dep_type => s.dep_type)
          INTO l_return
          FROM sch_event s
         WHERE s.id_sch_event = i_num01(1);
        RETURN l_return;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END do_appointment_type;

    FUNCTION do_can_cancel
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        l_return     VARCHAR2(1000 CHAR);
        l_can_cancel VARCHAR2(1);
    BEGIN
        l_can_cancel := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'CANCEL_EPISODE');
    
        SELECT decode(l_can_cancel,
                      pk_alert_constant.g_yes,
                      decode(pk_sysconfig.get_config('FLG_CANCEL_SCHEDULE', i_prof),
                             'Y',
                             decode(i_var01(1),
                                    pk_ehr_access.g_flg_ehr_normal,
                                    pk_alert_constant.g_no,
                                    pk_alert_constant.g_yes),
                             'N'),
                      pk_alert_constant.g_no)
          INTO l_return
          FROM dual;
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 'ERRO';
    END do_can_cancel;

    FUNCTION do_epis_hhc_req_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
    
        l_id_epis_hhc_req  epis_hhc_req.id_epis_hhc_req%TYPE := i_num01(1);
        l_flg_status       epis_hhc_req.flg_status%TYPE := i_var01(1);
        l_dt_request       v_epis_hhc_req_status.dt_status%TYPE;
        l_return           VARCHAR2(1000 CHAR);
        l_status_desc      VARCHAR2(4000 CHAR);
        epis_status_domain sys_domain.code_domain%TYPE := 'EPIS_HHC_REQ.FLG_STATUS';
    
    BEGIN
    
        l_status_desc := pk_sysdomain.get_domain(epis_status_domain, l_flg_status, i_lang);
    
        IF l_flg_status IN (pk_hhc_constant.k_hhc_req_status_part_approved,
                            pk_hhc_constant.k_hhc_req_status_in_eval,
                            pk_hhc_constant.k_hhc_req_status_approved,
                            pk_hhc_constant.k_hhc_req_status_in_progress,
                            pk_hhc_constant.k_hhc_req_status_rejected,
                            pk_hhc_constant.k_hhc_req_status_closed,
                            pk_hhc_constant.k_hhc_req_status_canceled,
                            pk_hhc_constant.k_hhc_req_status_discontinued,
                            pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm)
        THEN
            l_return := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_display_type => pk_alert_constant.g_display_type_icon,
                                                             i_flg_state    => l_flg_status,
                                                             i_tooltip_text => l_status_desc, --for tooltip
                                                             i_value_icon   => epis_status_domain);
        ELSIF l_flg_status = pk_hhc_constant.k_hhc_req_status_requested
        THEN
        
            l_dt_request := pk_hhc_core.get_dt_request(l_id_epis_hhc_req);
        
            l_return := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                             i_prof         => i_prof,
                                                             i_display_type => pk_alert_constant.g_display_type_date,
                                                             i_value_date   => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                                  l_dt_request,
                                                                                                                  pk_alert_constant.g_dt_yyyymmddhh24miss_tzr),
                                                             i_back_color   => pk_alert_constant.g_color_red,
                                                             i_icon_color   => pk_alert_constant.g_color_null,
                                                             i_tooltip_text => l_status_desc, --for tooltip
                                                             i_dt_server    => current_timestamp);
        
        ELSE
            --l_return := '|I|||CheckIcon|||||20191114115534|4|N';
            l_return := '';
        
        END IF;
        RETURN l_return;
    
    END do_epis_hhc_req_icon;
    -- *****************************************
    FUNCTION do_get_status_icon
    (
        i_lang       IN NUMBER,
        i_sch_status IN VARCHAR2,
        i_dsc_status IN VARCHAR2,
        i_flg_ehr    IN VARCHAR2,
        i_flg_state  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        k_sch_status_4_approval CONSTANT VARCHAR2(0050 CHAR) := pk_schedule.g_sched_status_pend_approval;
        --k_sch_status_approved   CONSTANT VARCHAR2(0050 CHAR) := pk_schedule.g_sched_status_scheduled;
        --k_sch_icon_inprogress   CONSTANT VARCHAR2(0050 CHAR) := 'WorkflowIcon';
        --k_sch_icon_concluded    CONSTANT VARCHAR2(0050 CHAR) := 'CheckIcon';
        --k_dsc_status_active     CONSTANT VARCHAR2(0050 CHAR) := pk_discharge.g_disch_flg_status_active;
        --k_dsc_status_cancel     CONSTANT VARCHAR2(0050 CHAR) := pk_discharge.g_disch_flg_status_cancel;
        --k_flg_ehr_agendado      CONSTANT VARCHAR2(0050 CHAR) := 'S';
        l_return     VARCHAR2(1000 CHAR);
        l_dsc_status VARCHAR2(0050 CHAR) := i_dsc_status;
    BEGIN
        /*
            l_dsc_status := coalesce(l_dsc_status, '-');
        
            IF i_flg_ehr = k_flg_ehr_agendado
            THEN
        
                l_return := pk_sysdomain.get_img(i_lang     => i_lang,
                                                 i_code_dom => 'SCHEDULE.FLG_STATUS',
                                                 i_val      => i_sch_status);
            
            ELSE
            
                IF l_dsc_status = k_dsc_status_active
                THEN
                    l_return := k_sch_icon_concluded;
                ELSE
                    l_return := k_sch_icon_inprogress;
                END IF;
            
            END IF;
        */
        l_return := do_get_status_icon_base(i_lang       => i_lang,
                                            i_mode       => 'ICON',
                                            i_sch_status => i_sch_status,
                                            i_dsc_status => i_dsc_status,
                                            i_flg_ehr    => i_flg_ehr,
                                            i_flg_state  => i_flg_state);
    
        RETURN l_return;
    
    END do_get_status_icon;

    -- ************************************************************
    FUNCTION get_room_row(i_room IN NUMBER) RETURN room%ROWTYPE IS
        xrow room%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO xrow
          FROM room x
         WHERE x.id_room = i_room;
    
        RETURN xrow;
    
    EXCEPTION
        WHEN OTHERS THEN
            xrow.id_room := i_room;
            RETURN xrow;
    END get_room_row;

    FUNCTION get_grid_task_stuff
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER,
        i_code    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        tbl_stuff table_varchar;
        l_return  VARCHAR2(0100 CHAR);
    BEGIN
    
        SELECT xsql.col_value
          BULK COLLECT
          INTO tbl_stuff
          FROM (SELECT CASE upper(i_code)
                           WHEN 'DESC_DRUG_PRESC' THEN
                            g.drug_presc
                           WHEN 'DESC_MOVEMENT' THEN
                            g.movement
                       END col_value
                  FROM grid_task g
                 WHERE g.id_episode = i_episode) xsql;
    
        IF tbl_stuff.count > 0
        THEN
            l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, tbl_stuff(1));
        END IF;
    
        RETURN l_return;
    
    END get_grid_task_stuff;

    FUNCTION get_count_hhc_req_by_patient(i_patient IN NUMBER) RETURN NUMBER IS
        l_count NUMBER;
    
    BEGIN
        SELECT COUNT(*)
          INTO l_count
          FROM v_epis_hhc_req req
          JOIN episode e
            ON e.id_episode = req.id_episode
          JOIN visit v
            ON v.id_visit = e.id_visit
         WHERE v.id_patient = i_patient
           AND req.flg_status IN (pk_hhc_constant.k_hhc_req_status_requested,
                                  pk_hhc_constant.k_hhc_req_status_part_approved,
                                  pk_hhc_constant.k_hhc_req_stauts_part_acc_wcm,
                                  pk_hhc_constant.k_hhc_req_status_in_eval,
                                  pk_hhc_constant.k_hhc_req_status_approved,
                                  pk_hhc_constant.k_hhc_req_status_in_progress);
        RETURN l_count;
    
    END get_count_hhc_req_by_patient;

    FUNCTION do_img_state_rank
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_domain       sys_domain.code_domain%TYPE;
        l_domain_value sys_domain.desc_val%TYPE;
        l_epis_type    episode.id_epis_type%TYPE;
    
        l_epis_type_nurse sys_config.value%TYPE := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', i_prof);
    
        l_viewid           VARCHAR2(0200 CHAR);
        l_flg_state        VARCHAR2(0200 CHAR);
        l_flg_ehr          VARCHAR2(0200 CHAR);
        l_flg_status       VARCHAR2(0200 CHAR);
        l_value            VARCHAR2(0200 CHAR);
        l_id_dep_clin_serv NUMBER;
        l_id_group         NUMBER;
        l_id_episode       NUMBER;
        l_return           NUMBER;
    
        l_error t_error_out;
    BEGIN
    
        l_viewid     := i_var01(1);
        l_flg_state  := i_var01(2);
        l_flg_ehr    := i_var01(3);
        l_flg_status := i_var01(4);
    
        l_id_dep_clin_serv := i_num01(1);
        l_id_group         := i_num01(2);
        l_id_episode       := i_num01(3);
    
        CASE l_viewid
        --WHEN k_view02 THEN
        --    l_return := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
        --    l_return := pk_grid.get_pre_nurse_appointment(i_lang, i_prof, l_id_dep_clin_serv, l_flg_ehr, l_return);
        --    l_return := pk_sysdomain.get_ranked_img(k_schdl_outp_state_domain, l_return, i_lang);
        
            WHEN k_view05 THEN
            
                IF l_flg_status = k_sched_canc
                THEN
                    l_return := pk_sysdomain.get_rank(i_lang, k_schdl_outp_status_domain, l_flg_status);
                
                ELSE
                    IF NOT pk_episode.get_epis_type(i_lang      => i_lang,
                                                    i_id_epis   => l_id_episode,
                                                    o_epis_type => l_epis_type,
                                                    o_error     => l_error)
                    THEN
                        l_domain := k_schdl_outp_state_domain;
                    END IF;
                
                    IF l_epis_type = pk_alert_constant.g_epis_type_home_health_care
                       AND l_flg_state = k_flg_state_admin_disch
                    THEN
                        l_flg_state := k_flg_state_disch;
                    END IF;
                
                    l_value := pk_grid.get_schedule_real_state(l_flg_state, l_flg_ehr);
                
                    IF l_epis_type <> pk_alert_constant.g_epis_type_home_health_care
                    THEN
                        l_value := pk_grid.get_pre_nurse_appointment(i_lang,
                                                                     i_prof,
                                                                     l_id_dep_clin_serv,
                                                                     l_flg_ehr,
                                                                     l_value);
                    
                    END IF;
                    IF l_epis_type = l_epis_type_nurse
                    THEN
                    
                        l_domain_value := pk_sysdomain.get_domain(i_lang     => i_lang,
                                                                  i_code_dom => pk_grid_amb.g_schdl_nurse_state_domain,
                                                                  i_val      => l_value);
                    
                        IF l_domain_value IS NOT NULL
                        THEN
                            l_domain := pk_grid_amb.g_schdl_nurse_state_domain;
                        ELSE
                            l_domain := k_schdl_outp_state_domain;
                        END IF;
                    ELSE
                    
                        l_domain := k_schdl_outp_state_domain;
                    
                    END IF;
                
                    l_return := pk_sysdomain.get_rank(i_lang, l_domain, l_value);
                
                END IF;
            
            WHEN k_view00 THEN
            
                l_return := k_group_app_img_state_rank;
            
            ELSE
                l_return := NULL;
        END CASE;
    
        RETURN l_return;
    
    END do_img_state_rank;
    -- ********************************************************************
    FUNCTION transform
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar
        
    ) RETURN VARCHAR2 IS
        l_return  VARCHAR2(4000);
        l_return0 VARCHAR2(4000);
        l_return1 VARCHAR2(4000);
        l_return2 VARCHAR2(4000);
        l_return3 VARCHAR2(4000);
        l_tmp     VARCHAR2(4000);
        --l_id_schedule         NUMBER;
        l_visit       NUMBER;
        l_episode     NUMBER;
        l_id_schedule NUMBER;
        l_patient     NUMBER;
        l_count       NUMBER;
        --l_patient          NUMBER;
        l_room             NUMBER;
        l_num              NUMBER;
        l_rank             NUMBER;
        l_id_dep_clin_serv NUMBER;
        --l_id_dcs_requested    NUMBER;
        l_id_nurse  NUMBER;
        l_id_origin NUMBER;
        l_id_prof   NUMBER;
        --l_id_group            NUMBER;
        --l_id_episode          NUMBER;
        l_urg_episode NUMBER;
    
        l_drug_presc VARCHAR2(1000 CHAR);
        l_array_num  table_number := table_number();
        l_array_vc2  table_varchar := table_varchar();
    
        l_flg_status VARCHAR2(0010 CHAR);
        l_flg_state  VARCHAR2(0010 CHAR);
    
        l_gender             VARCHAR2(0010 CHAR);
        l_str_monitor        VARCHAR2(1000 CHAR);
        l_str_interv         VARCHAR2(1000 CHAR);
        l_str_edu            VARCHAR2(1000 CHAR);
        l_str_icnp           VARCHAR2(1000 CHAR);
        l_str_nurse_act      VARCHAR2(1000 CHAR);
        l_priority_task_01   VARCHAR2(1000 CHAR);
        l_priority_task_02   VARCHAR2(1000 CHAR);
        l_hand_off_type      VARCHAR2(1000 CHAR);
        l_abbrv              VARCHAR2(1000 CHAR);
        l_complaint          VARCHAR2(4000 CHAR);
        l_data_true          VARCHAR2(1000 CHAR);
        l_data_false         VARCHAR2(1000 CHAR);
        l_exam               VARCHAR2(1000 CHAR);
        l_prof_cat_type      VARCHAR2(1000 CHAR);
        xroom                room%ROWTYPE;
        l_prof_cat           VARCHAR2(0100 CHAR);
        l_has_mrp_permission VARCHAR2(0010 CHAR);
        l_flg_ehr            VARCHAR2(0050 CHAR);
    
        k_hhc_requested     CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_requested;
        k_hhc_part_approved CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_part_approved;
        k_hhc_closed        CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_closed;
        k_hhc_canceled      CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_canceled;
        k_hhc_rejected      CONSTANT VARCHAR2(0010 CHAR) := pk_hhc_constant.k_hhc_req_status_rejected;
    
        FUNCTION visit_grid_task_str
        (
            i_visit    IN NUMBER,
            i_prof_cat IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(4000);
        BEGIN
        
            l_return := pk_grid.visit_grid_task_str(i_lang, i_prof, i_visit, k_task_analysis, i_prof_cat);
        
            RETURN l_return;
        
        END visit_grid_task_str;
    
        -----
        FUNCTION get_prioritary_task
        (
            i_mess1    IN VARCHAR2,
            i_mess2    IN VARCHAR2,
            i_domain   IN VARCHAR2,
            i_prof_cat IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(4000);
        BEGIN
        
            l_return := pk_grid.get_prioritary_task(i_lang, i_prof, i_mess1, i_mess2, i_domain, i_prof_cat);
        
            RETURN l_return;
        
        END get_prioritary_task;
    
    BEGIN
        --dbms_output.put_line('<<<<<<<<<<DO_TRANSFORM: ' || i_code || '>>>>>>>>>>>>>>>>>>>>>>>');
        -- case_01
        CASE upper(i_code)
            WHEN 'DISCHARGE_TYPE' THEN
                l_return := do_discharge_type(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_num01 => i_num01,
                                              i_var01 => i_var01);
            WHEN 'INP_FLG_STATUS' THEN
                l_return := do_inp_flg_status(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_num01 => i_num01,
                                              i_var01 => i_var01);
            WHEN 'DISCHARGE_DATE' THEN
                l_return := do_discharge_date(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_num01 => i_num01,
                                              i_var01 => i_var01);
            WHEN 'PENDING_DISCHARGE_DATE' THEN
                l_return := do_discharge_dt_pend(i_lang  => i_lang,
                                                 i_prof  => i_prof,
                                                 i_num01 => i_num01,
                                                 i_var01 => i_var01);
            
            WHEN 'TRANSFER_STATUS_ICON1' THEN
                l_return := do_transfer_status_icon(i_lang  => i_lang,
                                                    i_prof  => i_prof,
                                                    i_id    => 1,
                                                    i_num01 => i_num01,
                                                    i_var01 => i_var01);
            WHEN 'TRANSFER_STATUS_ICON2' THEN
                l_return := do_transfer_status_icon(i_lang  => i_lang,
                                                    i_prof  => i_prof,
                                                    i_id    => 2,
                                                    i_num01 => i_num01,
                                                    i_var01 => i_var01);
            WHEN 'EDIS_DT_BEGIN' THEN
                l_return := do_edis_dt_begin(i_lang => i_lang, i_prof => i_prof, i_num01 => i_num01, i_var01 => i_var01);
            
            WHEN 'EDIS_DT_BEGIN_SORT' THEN
                l_return := do_edis_dt_begin_sort(i_lang  => i_lang,
                                                  i_prof  => i_prof,
                                                  i_num01 => i_num01,
                                                  i_var01 => i_var01);
            
            WHEN 'PROF_IN_CHARGE' THEN
            
                l_return := do_prof_in_charge(i_lang  => i_lang,
                                              i_prof  => i_prof,
                                              i_num01 => i_num01,
                                              i_var01 => i_var01);
            WHEN 'HHC_SCHED_PROF' THEN
                l_id_schedule := i_num01(1);
                l_return      := do_list_prof_name(i_lang => i_lang, i_prof => i_prof, i_id_schedule => l_id_schedule);
            WHEN 'HHC_DT_VISIT' THEN
                l_id_schedule := i_num01(1);
                l_return      := do_hhc_dt_visit(i_lang => i_lang, i_prof => i_prof, i_id_schedule => l_id_schedule);
            
            WHEN 'HHC_DT_VISIT_HOUR' THEN
                l_id_schedule := i_num01(1);
                l_return      := do_hhc_dt_visit_hour(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_id_schedule => l_id_schedule);
            WHEN 'HHC_VISIT_ICON_STATUS' THEN
                l_flg_status := i_var01(1);
                l_tmp        := i_var01(2);
                l_flg_ehr    := i_var01(3);
                l_flg_state  := i_var01(4);
                l_return     := do_get_status_icon(i_lang       => i_lang,
                                                   i_sch_status => l_flg_status,
                                                   i_dsc_status => l_tmp,
                                                   i_flg_ehr    => l_flg_ehr,
                                                   i_flg_state  => l_flg_state);
            
            WHEN 'FLG_STATUS_INTERNAL' THEN
                l_flg_status := i_var01(1);
                l_tmp        := i_var01(2);
                l_flg_ehr    := i_var01(3);
                l_flg_state  := i_var01(4);
                --l_return     := do_map_hhc_visit_flg_state(i_flg_state => l_flg_status);
                l_return := do_map_hhc_visit_flg_state(i_lang       => i_lang,
                                                       i_sch_status => l_flg_status,
                                                       i_dsc_status => l_tmp,
                                                       i_flg_ehr    => l_flg_ehr,
                                                       i_flg_state  => l_flg_state);
            
            WHEN 'FLG_STATUS_ORDER' THEN
                l_flg_status := i_var01(1);
                l_tmp        := i_var01(2);
                l_flg_ehr    := i_var01(3);
                l_flg_state  := i_var01(4);
                --l_return     := do_map_hhc_visit_flg_state(i_flg_state => l_flg_status);
                l_return := do_hhc_visit_flg_order(i_lang       => i_lang,
                                                   i_sch_status => l_flg_status,
                                                   i_dsc_status => l_tmp,
                                                   i_flg_ehr    => l_flg_ehr,
                                                   i_flg_state  => l_flg_state);
            
            WHEN 'HHC_FLG_CANCEL' THEN
                l_flg_status         := i_var01(1);
                l_has_mrp_permission := i_var01(2);
            
                l_return := k_no;
                l_return := pk_hhc_core.check_if_prof_can_cancel(i_flg_status => l_flg_status,
                                                                 i_flg_mrp    => l_has_mrp_permission);
            
            WHEN 'HHC_FLG_EDIT' THEN
                l_flg_status         := i_var01(1);
                l_has_mrp_permission := i_var01(2);
            
                l_return := k_no;
                l_return := pk_hhc_core.check_if_prof_can_edit(i_flg_status => l_flg_status,
                                                               i_flg_mrp    => l_has_mrp_permission);
            
            WHEN 'HHC_FLG_DISCONTINUE' THEN
                l_flg_status         := i_var01(1);
                l_has_mrp_permission := i_var01(2);
            
                l_return := k_no;
                l_return := pk_hhc_core.check_if_prof_can_discon(i_flg_status => l_flg_status,
                                                                 i_flg_mrp    => l_has_mrp_permission);
            
            WHEN 'HHC_FLG_ADD' THEN
                l_patient            := i_num01(1);
                l_has_mrp_permission := i_var01(1);
            
                l_return := k_no;
                IF l_has_mrp_permission = k_yes
                THEN
                
                    l_count := get_count_hhc_req_by_patient(i_patient => l_patient);
                
                    IF l_count = 0
                    THEN
                        l_return := k_yes;
                    END IF;
                END IF;
            
            WHEN 'DESC_ANALYSIS_REQ' THEN
            
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                l_return   := visit_grid_task_str(l_visit, l_prof_cat);
            
            WHEN 'DESC_ANALYSIS_REQ_SORT' THEN
            
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                l_return   := visit_grid_task_str(l_visit, l_prof_cat);
                l_return   := convert_grid_str_to_sort(l_return);
            
            WHEN 'DESC_ANALYSIS_REQ_B' THEN
                l_visit         := i_num01(1);
                l_episode       := i_num01(2);
                l_prof_cat_type := i_var01(1);
            
                IF l_episode IS NOT NULL
                THEN
                    l_return := visit_grid_task_str(l_visit, l_prof_cat_type);
                END IF;
            
            WHEN 'DESC_DRUG_PRESC' THEN
                l_episode := i_num01(1);
                l_return  := get_grid_task_stuff(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => l_episode,
                                                 i_code    => i_code);
                l_return  := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_return);
            
            WHEN 'DESC_DRUG_PRESC_SORT' THEN
                l_episode := i_num01(1);
                l_return  := get_grid_task_stuff(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => l_episode,
                                                 i_code    => i_code);
                l_return  := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_return);
                l_return  := convert_grid_str_to_sort(l_return);
            
            WHEN 'DESC_DRUG_PRESC_B' THEN
            
                l_episode    := i_num01(1);
                l_drug_presc := i_var01(1);
            
                IF l_episode IS NOT NULL
                THEN
                    l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_drug_presc);
                END IF;
            
            WHEN 'DESC_GENERIC_PRESC' THEN
            
                IF i_var01(1) IS NOT NULL
                THEN
                    l_return := do_generic_presc(i_lang, i_prof, i_num01, i_var01);
                END IF;
            
            WHEN 'DESC_EXAM_REQ' THEN
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                l_return   := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_exam, l_prof_cat);
            
        --###############
            WHEN 'DESC_EXAM_REQ_B' THEN
                l_visit         := i_num01(1);
                l_episode       := i_num01(2);
                l_prof_cat_type := i_var01(1);
            
                IF l_episode IS NOT NULL
                THEN
                    l_return := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_exam, l_prof_cat_type);
                END IF;
            
            WHEN 'DESC_OTH_EXAM_REQ' THEN
            
                l_data_true  := i_var01(1);
                l_data_false := i_var01(2);
            
                l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            
                IF l_prof_cat = k_no
                THEN
                    l_exam := l_data_true;
                ELSE
                    l_exam := l_data_false;
                END IF;
            
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_exam);
            
            WHEN 'DESC_OTH_EXAM_REQ_SORT' THEN
            
                l_data_true  := i_var01(1);
                l_data_false := i_var01(2);
            
                l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            
                IF l_prof_cat = k_no
                THEN
                    l_exam := l_data_true;
                ELSE
                    l_exam := l_data_false;
                END IF;
            
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_exam);
                l_return := convert_grid_str_to_sort(l_return);
            
            WHEN 'DESC_EXAM_REQ_SORT' THEN
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
                l_return   := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_exam, l_prof_cat);
                l_return   := convert_grid_str_to_sort(l_return);
            
            WHEN 'DESC_IMG_EXAM_REQ' THEN
            
                l_data_true  := i_var01(1);
                l_data_false := i_var01(2);
            
                l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            
                IF l_prof_cat = k_no
                THEN
                    l_exam := l_data_true;
                ELSE
                    l_exam := l_data_false;
                END IF;
            
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_exam);
            
            WHEN 'DESC_IMG_EXAM_REQ_SORT' THEN
            
                l_data_true  := i_var01(1);
                l_data_false := i_var01(2);
            
                l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
            
                IF l_prof_cat = k_no
                THEN
                    l_exam := l_data_true;
                ELSE
                    l_exam := l_data_false;
                END IF;
            
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_exam);
                l_return := convert_grid_str_to_sort(l_return);
            
        --*******************************
        
            WHEN 'DESC_MONIT_INTERV_PRESC' THEN
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
            
                l_str_monitor := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_monitor, l_prof_cat);
                l_str_interv  := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_interv, l_prof_cat);
                l_str_edu     := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_edu, l_prof_cat);
            
                l_priority_task_01 := pk_grid.get_prioritary_task(i_lang,
                                                                  i_prof,
                                                                  l_str_interv,
                                                                  l_str_monitor,
                                                                  NULL,
                                                                  l_prof_cat);
                l_priority_task_02 := pk_grid.get_prioritary_task(i_lang,
                                                                  i_prof,
                                                                  l_priority_task_01,
                                                                  l_str_edu,
                                                                  NULL,
                                                                  l_prof_cat);
            
                l_return := l_priority_task_02;
            
            WHEN 'DESC_MONIT_INTERV_PRESC_SORT' THEN
                l_visit    := i_num01(1);
                l_prof_cat := pk_prof_utils.get_category(i_lang => i_lang, i_prof => i_prof);
            
                l_str_monitor := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_monitor, l_prof_cat);
                l_str_interv  := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_interv, l_prof_cat);
                l_str_edu     := pk_grid.visit_grid_task_str(i_lang, i_prof, l_visit, k_task_edu, l_prof_cat);
            
                l_priority_task_01 := pk_grid.get_prioritary_task(i_lang,
                                                                  i_prof,
                                                                  l_str_interv,
                                                                  l_str_monitor,
                                                                  NULL,
                                                                  l_prof_cat);
                l_priority_task_02 := pk_grid.get_prioritary_task(i_lang,
                                                                  i_prof,
                                                                  l_priority_task_01,
                                                                  l_str_edu,
                                                                  NULL,
                                                                  l_prof_cat);
            
                l_return := l_priority_task_02;
                l_return := convert_grid_str_to_sort(l_return);
            
            WHEN 'DESC_INTERV_PRESC' THEN
            
                l_str_interv    := i_var01(1); -- l_str_interv
                l_str_monitor   := i_var01(2); -- l_str_monitor
                l_str_edu       := i_var01(3); -- l_str_edu
                l_str_nurse_act := i_var01(4); -- l_str_nurse_act
                l_str_icnp      := i_var01(5); -- l_str_icnp
            
                -- get_prioritary_task( i_mess1 in varchar2, i_mess2 in varchar2, i_domain in varchar2, i_prof_cat in varchar2 )
            
                l_return0 := get_prioritary_task(l_str_interv, l_str_monitor, NULL, k_flg_doctor);
            
                l_return1 := get_prioritary_task(l_return0, l_str_edu, NULL, k_flg_doctor);
            
                l_return2 := get_prioritary_task(l_str_nurse_act, l_return1, NULL, k_flg_doctor);
            
                l_return3 := get_prioritary_task(l_str_icnp, l_return2, NULL, k_flg_doctor);
            
                l_return := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_return3);
            
            WHEN 'DESC_MOVEMENT' THEN
                l_episode := i_num01(1);
                l_return  := get_grid_task_stuff(i_lang    => i_lang,
                                                 i_prof    => i_prof,
                                                 i_episode => l_episode,
                                                 i_code    => i_code);
                l_return  := pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, l_return);
            
            WHEN 'DESC_ROOM' THEN
            
                l_room := i_num01(1);
                xroom  := get_room_row(l_room);
            
                IF xroom.desc_room_abbreviation IS NOT NULL
                THEN
                    l_return := xroom.desc_room_abbreviation;
                ELSE
                    l_return := pk_translation.get_translation(i_lang, xroom.code_abbreviation);
                
                    IF l_return IS NULL
                    THEN
                    
                        l_return := xroom.desc_room;
                    
                        IF l_return IS NULL
                        THEN
                            l_return := pk_translation.get_translation(i_lang, xroom.code_room);
                        END IF;
                    
                    END IF;
                
                END IF;
            
            WHEN 'DESC_OPINION_SORT' THEN
                l_return := i_var01(1);
                l_return := do_desc_opinion_sort(i_lang, i_prof, l_return);
                --pk_grid.convert_grid_task_dates_to_str(t.sys_lang, t.sys_lprof, t.opinion_state);
        
            WHEN 'GENDER' THEN
                l_gender := i_var01(1);
                l_return := pk_sysdomain.get_domain(k_domain_gender_abbrv, l_gender, i_lang);
            
            WHEN 'IMG_TRANSP' THEN
                l_flg_status := i_var01(1);
                l_rank       := pk_sysdomain.get_rank(i_lang, 'EPIS_INFO.FLG_STATUS', l_flg_status);
                l_tmp        := pk_sysdomain.get_img(i_lang, 'EPIS_INFO.FLG_STATUS', l_flg_status);
            
                l_return := to_char(l_rank);
                l_return := lpad(l_return, k_six, k_zero_varchar);
            
                l_return := l_return || l_tmp;
            
            WHEN 'NAME_NURSE_TOOLTIP' THEN
                l_episode  := i_num01(1);
                l_id_nurse := i_num01(2);
            
                pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
                l_return := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                  i_prof,
                                                                  k_cat_type_nurse,
                                                                  l_episode,
                                                                  l_id_nurse,
                                                                  l_hand_off_type,
                                                                  k_show_in_tooltip);
            
            WHEN 'PROF_FOLLOW_ADD' THEN
                l_episode := i_num01(1);
                l_tmp     := pk_prof_follow.get_follow_episode_by_me(i_prof, l_episode, -1);
            
                IF l_tmp = k_no
                THEN
                
                    -- init var
                    l_prof_cat := pk_prof_utils.get_category(i_lang, i_prof);
                    pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
                
                    l_array_num := pk_hand_off_api.get_responsibles_id(i_lang,
                                                                       i_prof,
                                                                       l_episode,
                                                                       l_prof_cat,
                                                                       l_hand_off_type);
                    l_num       := pk_utils.search_table_number(l_array_num, i_prof.id);
                
                    l_return := iif(l_num = -1, k_yes, k_no);
                
                ELSE
                    l_return := k_no;
                END IF;
            
            WHEN 'NAME_PROF' THEN
                l_episode := i_num01(1);
                l_id_prof := i_num01(2);
            
                pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
                l_return := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                  i_prof,
                                                                  k_cat_type_doc,
                                                                  l_episode,
                                                                  l_id_prof,
                                                                  l_hand_off_type,
                                                                  k_show_in_grid);
            
            WHEN 'NAME_PROF_TOOLTIP' THEN
                l_episode := i_num01(1);
                l_id_prof := i_num01(2);
            
                pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
                l_return := pk_hand_off_core.get_responsibles_str(i_lang,
                                                                  i_prof,
                                                                  k_cat_type_doc,
                                                                  l_episode,
                                                                  l_id_prof,
                                                                  l_hand_off_type,
                                                                  k_show_in_tooltip);
            
            WHEN 'RESP_ICONS' THEN
                l_episode := i_num01(1);
                pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
                l_array_vc2 := pk_hand_off_api.get_resp_icons(i_lang, i_prof, l_episode, l_hand_off_type);
                IF l_array_vc2.count > 0
                THEN
                    l_return := l_array_vc2(1);
                END IF;
            WHEN 'LOS' THEN
                l_episode := i_num01(1);
                l_return  := pk_edis_proc.get_los_duration(i_lang       => i_lang,
                                                           i_prof       => i_prof,
                                                           i_id_episode => l_episode);
            
            WHEN 'LOS_SORT' THEN
                l_episode := i_num01(1);
                l_return  := pk_edis_proc.get_formatted_string_for_sort(i_lang    => i_lang,
                                                                        i_prof    => i_prof,
                                                                        i_type    => k_sort_type_los,
                                                                        i_episode => l_episode);
            
            WHEN 'DESC_EPIS_ANAMNESIS' THEN
                l_id_origin   := i_num01(1);
                l_urg_episode := i_num01(2);
            
                l_abbrv     := pk_edis_grid.get_grid_origin_abbrev(i_lang, i_prof, l_id_origin);
                l_complaint := pk_edis_grid.get_complaint_grid(i_lang => i_lang,
                                                               i_prof => i_prof,
                                                               i_epis => l_urg_episode,
                                                               i_sep  => '; ');
            
                l_return := pk_string_utils.concat_if_exists(l_abbrv, l_complaint, ' / ');
            
            WHEN 'ORIGIN_ANAMN_FULL_DESC' THEN
                l_visit   := i_num01(1);
                l_episode := i_num01(2);
            
                l_return := pk_edis_grid.get_orig_anamn_desc(i_lang    => i_lang,
                                                             i_prof    => i_prof,
                                                             i_visit   => l_visit,
                                                             i_episode => l_episode,
                                                             i_sep     => '; ');
            
            WHEN 'CONS_TYPE' THEN
                l_id_dep_clin_serv := i_num01(1);
                l_return           := pk_hea_prv_aux.get_clin_service(i_lang, i_prof, l_id_dep_clin_serv);
            
            WHEN 'DESC_ANA_EXAM_REQ' THEN
                l_return := do_desc_ana_exam_req(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'EXTEND_ICON' THEN
                l_return := do_extend_icon(i_num01, i_var01);
            
            WHEN 'FLG_CONTACT' THEN
                l_return := do_flg_contact(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'FLG_STATE' THEN
                l_return := do_flg_state(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'ICON_CONTACT_TYPE' THEN
                l_return := do_icon_contact_type(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'IMG_STATE' THEN
                l_return := do_img_state(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'IMG_STATE_RANK' THEN
                l_return := do_img_state_rank(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_NAME' THEN
                l_return := do_pat_name(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_NAME_TO_SORT' THEN
                l_return := do_pat_name_to_sort(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'NUM_CLIN_RECORD' THEN
                l_return := do_num_clin_record(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_AGE' THEN
                l_return := do_pat_age(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_AGE_SORT' THEN
                l_return := do_pat_age_to_sort(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_NDO' THEN
                l_return := do_pat_ndo(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PAT_ND_ICON' THEN
                l_return := do_pat_nd_icon(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PHOTO' THEN
                l_return := do_photo(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PROF_FOLLOW_ADD_01' THEN
                l_return := do_prof_follow_add(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'PROF_FOLLOW_REMOVE' THEN
                l_return := do_prof_follow_remove(i_prof, i_num01, i_var01);
            
            WHEN 'PROF_TEAM' THEN
                l_return := do_prof_team(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'RANK' THEN
                l_return := do_rank(i_var01);
            
            WHEN 'THERAPEUTIC_DOCTOR' THEN
                l_return := do_therapeutic_doctor(i_lang, i_prof, i_num01);
            
            WHEN 'VISIT_REASON' THEN
                l_return := do_visit_reason(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'WR_CALL' THEN
                l_return := do_wr_call(i_lang, i_prof, i_num01, i_var01);
            WHEN 'FAST_TRACK_ICON' THEN
                l_return := do_fast_track_icon(i_lang, i_prof, i_num01, i_var01);
            WHEN 'ORDER_WITHOUT_TRIAGE' THEN
                l_return := do_order_without_triage(i_lang, i_prof, i_num01, i_var01);
            WHEN 'ORIS_DT_PAT_STATUS' THEN
                l_return := do_oris_dt_pat_status(i_lang, i_prof, i_num01, i_var01);
            WHEN 'ORIS_PROF_FOLLOW_ADD' THEN
                l_return := do_oris_prof_follow_add(i_lang, i_prof, i_num01, i_var01);
            WHEN 'SOCIAL_WORKER_FU_ICON' THEN
                l_return := do_social_worker_fu_icon(i_lang, i_prof, i_num01, i_var01);
            WHEN 'IMG_STATE_BETWEEN' THEN
                l_return := do_img_state_between(i_lang, i_prof, i_num01, i_var01);
            WHEN 'SOCIAL_WORKER_VISIT_REASON_SORT' THEN
                l_return := do_sw_visit_reason_sort(i_lang, i_prof, i_num01, i_var01);
            WHEN 'PROFESSIONAL' THEN
                l_return := do_adm_professional(i_lang, i_prof, i_num01, i_var01);
            WHEN 'DT_REQUEST_DESC' THEN
                l_return := do_adm_dt_request_desc(i_lang, i_prof, i_num01, i_var01);
            WHEN 'STATUS_ICON' THEN
                l_return := do_adm_status_icon(i_lang, i_prof, i_num01, i_var01);
            WHEN 'DT_SCHEDULED_DESC' THEN
                l_return := do_adm_scheduled_desc(i_lang, i_prof, i_num01, i_var01);
            WHEN 'DT_PROPOSED' THEN
                l_return := do_adm_proposed(i_lang, i_prof, i_num01, i_var01);
            WHEN 'REQUEST_DATE' THEN
                l_return := do_adm_request_date(i_lang, i_prof, i_num01, i_var01);
            WHEN 'INTERNMENT' THEN
                l_return := do_internment(i_lang, i_prof, i_num01, i_var01);
            WHEN 'APPOINTMENT_TYPE' THEN
                l_return := do_appointment_type(i_lang, i_prof, i_num01, i_var01);
            WHEN 'CAN_CANC' THEN
                l_return := do_can_cancel(i_lang, i_prof, i_num01, i_var01);
            WHEN 'RANK_ACUITY2' THEN
                l_return := do_rank_acuity2(i_lang, i_prof, i_num01, i_var01);
            WHEN 'RANK_ACUITY3' THEN
                l_return := do_rank_acuity3(i_lang, i_prof, i_num01, i_var01);
            WHEN 'EPIS_HHC_REQ_ICON' THEN
                l_return := do_epis_hhc_req_icon(i_lang, i_prof, i_num01, i_var01);
            WHEN 'INP_GRID_PROC_MONIT_STS_STR' THEN
                l_return := do_inp_grid_proc_monit_sts_str(i_lang, i_prof, i_num01, i_var01);
            
            WHEN 'DRL_PRESC_FLG_CANCEL' THEN
                l_flg_status := i_var01(1);
                IF l_flg_status IN (k_drl_presc_cancelled, k_drl_presc_valid)
                THEN
                    l_return := k_no;
                ELSE
                    l_return := k_yes;
                END IF;
            
            WHEN 'DRL_PRESC_FLG_EDIT' THEN
                l_flg_status := i_var01(1);
            
                IF l_flg_status IN (k_drl_presc_cancelled, k_drl_presc_valid, k_drl_presc_waiting_validation)
                THEN
                    l_return := k_no;
                ELSE
                    l_return := k_yes;
                END IF;
            ELSE
                l_return := NULL;
            
        END CASE; -- end case_01
    
        RETURN l_return;
    
    END transform;

    FUNCTION transform_clob
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_code  IN VARCHAR2,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN CLOB IS
        l_return CLOB;
    BEGIN
        CASE upper(i_code)
            WHEN 'SOCIAL_WORKER_VISIT_REASON' THEN
                l_return := do_social_worker_visit_reason(i_lang, i_prof, i_num01, i_var01);
            ELSE
                l_return := NULL;
        END CASE; -- end case_01
        RETURN l_return;
    END transform_clob;

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
    ) RETURN VARCHAR2 IS
        k_chr CONSTANT VARCHAR2(0010 CHAR) := ';' || chr(32);
        tbl_return table_varchar;
        l_return   VARCHAR2(4000);
    BEGIN
    
        SELECT substr(concatenate(decode(id_complaint, NULL, patient_complaint, desc_complaint) || xpl),
                      1,
                      length(concatenate(decode(id_complaint, NULL, patient_complaint, desc_complaint || xpl))) -
                      length(xpl))
          BULK COLLECT
          INTO tbl_return
          FROM (SELECT ec.id_complaint,
                       ec.patient_complaint,
                       pk_translation.get_translation(i_lang, c.code_complaint) desc_complaint,
                       k_chr xpl
                  FROM epis_complaint ec
                  JOIN complaint c
                    ON c.id_complaint = ec.id_complaint
                 WHERE ec.id_episode = i_episode
                   AND ec.flg_status = pk_alert_constant.g_active) cm;
    
        IF tbl_return.count > 0
        THEN
            l_return := tbl_return(1);
        END IF;
    
        RETURN l_return;
    
    END get_reason;

    PROCEDURE set_context_dates
    (
        i_dt_min IN VARCHAR2,
        i_amount IN NUMBER
    ) IS
    BEGIN
    
        pk_context_api.set_parameter('l_dt_min', i_dt_min);
        pk_context_api.set_parameter('amount', i_amount);
    
    END set_context_dates;
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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_hand_off_type          sys_config.value%TYPE;
        l_str_date               VARCHAR2(0050 CHAR);
        l_instr                  NUMBER;
        l_id_category            NUMBER;
        l_type_appointment       VARCHAR2(0002 CHAR);
        l_prof_cat_type          VARCHAR2(0002 CHAR);
        g_epis_type_nurse        VARCHAR2(0100 CHAR);
        g_domain_pat_gender_abbr VARCHAR2(0200 CHAR) := 'PATIENT.GENDER.ABBR';
        k_allow_my_room          VARCHAR2(1000 CHAR) := 'ALLOW_MY_ROOM_SPECIALITY_GRID_TYPE_APPOINT_EDITION';
        g_schdl_outp_sched_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_SCHED';
        g_domain_sch_presence     CONSTANT VARCHAR2(0200 CHAR) := 'SCH_GROUP.FLG_CONTACT_TYPE';
    g_epis_flg_appointment_type CONSTANT sys_domain.code_domain%TYPE := 'EPISODE.FLG_APPOINTMENT_TYPE';
        g_sys_config_wr           CONSTANT sys_config.id_sys_config%TYPE := 'WL_WAITING_ROOM_AVAILABLE';
        l_dt TIMESTAMP WITH LOCAL TIME ZONE;
    
        FUNCTION get_current_dt
        (
            i_lang IN NUMBER,
            i_prof IN profissional
        ) RETURN VARCHAR2 IS
            l_dt VARCHAR2(0100 CHAR);
        BEGIN
        
            l_dt := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            l_dt := substr(l_dt, 1, 8) || '000000';
        
            RETURN l_dt;
        
        END get_current_dt;
        -- *************************************************************
        PROCEDURE set_context_ids IS
            l_bool BOOLEAN;
            --l_context_keys table_number := table_number();
        BEGIN
        
            --l_bool := i_context_keys IS NOT NULL AND i_context_keys.count > 0;
        
            l_bool := TRUE; --i_context_keys.exists(1);
        
            IF l_bool
            THEN
            
                IF i_context_keys.exists(1)
                THEN
                    l_str_date := i_context_keys(1);
                ELSE
                    l_str_date := get_current_dt(g_lang, l_prof);
                END IF;
                pk_context_api.set_parameter('i_dt', l_str_date);
            
                IF i_context_keys.exists(2)
                THEN
                    l_type_appointment := i_context_keys(2);
                ELSE
                    l_type_appointment := 'D';
                END IF;
                pk_context_api.set_parameter('i_type_appointment', l_type_appointment);
            
                IF i_context_keys.exists(3)
                THEN
                    l_prof_cat_type := l_prof_cat_type;
                ELSE
                    l_prof_cat_type := 'D';
                END IF;
                pk_context_api.set_parameter('i_prof_cat_type', l_prof_cat_type);
            
            END IF;
        
        END set_context_ids;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
            pk_context_api.set_parameter('g_selected', pk_grid_amb.g_selected);
            pk_context_api.set_parameter('g_sched_status_cache', pk_schedule.g_sched_status_cache);
        
            IF i_context_keys.exists(1)
            THEN
                set_context_dates(i_context_keys(1), 1);
            ELSE
                set_context_dates(get_current_dt(g_lang, l_prof), 1);
            END IF;
        
            --dbms_output.put_line('DT_MIN:' || to_char(i_context_keys(1)));
        
            pk_context_api.set_parameter('g_epis_type_nurse', g_epis_type_nurse);
        
            IF (i_filter_name = 'OutpGrid_All')
               OR ((i_filter_name = 'ChangePatientHeaderAMB_MW') AND i_custom_filter IN (0, 2))
            THEN
                pk_context_api.set_parameter('filter_leader', 'Y');
            ELSE
                pk_context_api.set_parameter('filter_leader', NULL);
            END IF;
        END set_context;
    
    BEGIN
    
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', l_prof);
    
        --dbms_output.put_line('*****HAND_OFF_TYPE*****:' || l_hand_off_type);
    
        set_context();
    
        -- l_prof_cat_type
        set_context_ids();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'l_lang' THEN
                o_id := l_lang;
            when 'i_prof_id' then
                 o_id := l_prof.id;
            WHEN 'e_flg_status_p' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'e_flg_status_a' THEN
                o_vc2 := pk_alert_constant.g_flg_status_a;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'g_domain_pat_gender_abbr' THEN
                o_vc2 := g_domain_pat_gender_abbr;
            WHEN 'g_domain_sch_presence' THEN
                o_vc2 := g_domain_sch_presence;
            WHEN 'g_schdl_outp_sched_domain' THEN
                o_vc2 := g_schdl_outp_sched_domain;
            WHEN 'g_sched_scheduled' THEN
                o_vc2 := 'A';
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_handoff_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
            
                o_vc2 := l_hand_off_type;
            WHEN 'l_no_present_patient' THEN
                o_vc2 := pk_message.get_message(l_lang, 'THERAPEUTIC_DECISION_T017');
            WHEN 'l_prof_cat_type' THEN
                o_vc2 := l_prof_cat_type;
            WHEN 'l_show_resident_physician' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'GRIDS_SHOW_RESIDENT', i_prof => l_prof);
            WHEN 'l_type_appoint_edition' THEN
            
                o_vc2 := k_no;
            
                l_id_category := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            
                l_instr := instr(pk_sysconfig.get_config(k_allow_my_room, l_prof.institution, l_prof.software),
                                 '|' || l_id_category || '|');
            
                IF l_instr > 0
                THEN
                    o_vc2 := k_yes;
                END IF;
            
            WHEN 'cons_type' THEN
                o_vc2 := i_name;
            WHEN 'desc_ana_exam_req' THEN
                o_vc2 := i_name;
            WHEN 'desc_ana_exam_req' THEN
                o_vc2 := i_name;
            WHEN 'desc_drug_presc_b' THEN
                o_vc2 := i_name;
            WHEN 'desc_exam_req_b' THEN
                o_vc2 := i_name;
            WHEN 'desc_interv_presc' THEN
                o_vc2 := i_name;
            WHEN 'desc_room' THEN
                o_vc2 := i_name;
            WHEN 'extend_icon' THEN
                o_vc2 := i_name;
            WHEN 'flg_contact' THEN
                o_vc2 := i_name;
            WHEN 'flg_state' THEN
                o_vc2 := i_name;
            WHEN 'icon_contact_type' THEN
                o_vc2 := i_name;
            WHEN 'img_state' THEN
                o_vc2 := i_name;
            WHEN 'img_state_rank' THEN
                o_vc2 := i_name;
            WHEN 'pat_name' THEN
                o_vc2 := i_name;
            WHEN 'pat_name_to_sort' THEN
                o_vc2 := i_name;
            WHEN 'num_clin_record' THEN
                o_vc2 := i_name;
            WHEN 'pat_age' THEN
                o_vc2 := i_name;
            WHEN 'pat_nd_icon' THEN
                o_vc2 := i_name;
            WHEN 'photo' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_add_01' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_remove' THEN
                o_vc2 := i_name;
            WHEN 'prof_team' THEN
                o_vc2 := i_name;
            WHEN 'rank' THEN
                o_vc2 := i_name;
            WHEN 'therapeutic_doctor' THEN
                o_vc2 := i_name;
            WHEN 'visit_reason' THEN
                o_vc2 := i_name;
            WHEN 'wr_call' THEN
                o_vc2 := i_name;
                WHEN 'img_state_between' THEN
                o_vc2 := i_name;
                WHEN 'desc_generic_presc' THEN
                o_vc2 := i_name;
                WHEN 'epis_flg_appointment_type' THEN
                o_vc2 := g_epis_flg_appointment_type;
                WHEN 'pat_ndo' THEN
                o_vc2 := i_name;                                                
            WHEN 'l_dt_min' THEN
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => alert_context('l_dt_min'),
                                                        i_timezone  => '');
            
            WHEN 'l_dt_max' THEN
            
                l_dt   := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                                                     i_prof      => l_prof,
                                                                                                                                     i_timestamp => alert_context('l_dt_min'),
                                                        i_timezone  => '');
                l_dt   := pk_date_utils.add_days(i_lang => l_lang, i_prof => l_prof, i_date => l_dt, i_amount => 1);
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => l_dt, i_amount => -1, i_unit => 'SECOND');

            WHEN 'l_filter_name' THEN
                o_vc2 := i_filter_name;
            WHEN 'l_waiting_room_available' THEN
                o_vc2 := pk_sysconfig.get_config(g_sys_config_wr, l_prof);
            WHEN 'l_waiting_room_sys_external' THEN
                o_vc2 := pk_sysconfig.get_config('WAITING_ROOM_EXTERNAL_SYSTEM', l_prof);
            WHEN 'g_sched_no_show' THEN
                o_vc2 := 'B';
            WHEN 'g_sysdate_tstz' THEN
                o_tstz := current_timestamp;
            ELSE
                o_vc2  := i_name;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_amb;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_prof_cat                     category.flg_type%TYPE;
        l_hand_off_type                sys_config.value%TYPE;
        g_task_analysis                VARCHAR2(1) := 'A';
        g_task_exam                    VARCHAR2(1) := 'E';
        g_analysis_exam_icon_grid_rank sys_domain.code_domain%TYPE := 'ANALYSIS_EXAM_ICON_GRID_RANK';
        g_cat_type_doc                 VARCHAR2(1) := 'D';
        g_pat_status_pend              VARCHAR2(1) := 'A';
        --pat_status_pend                VARCHAR2(1) := 'A';
        --g_pat_status_l                 VARCHAR2(1) := 'L';
        --g_pat_status_s                 VARCHAR2(1) := 'S';
        --g_type_room                    VARCHAR2(1) := 'R';
        --flg_interv_start               VARCHAR2(10) := 'IC';
        --flg_status_a                   VARCHAR2(1) := 'A';
        g_active VARCHAR2(1) := 'A';
        --g_my_patients                  VARCHAR2(1) := 'P';
        --g_all_patients                 VARCHAR2(1) := 'A';
        --g_flg_pat_status               VARCHAR2(50) := 'SR_SURGERY_ROOM.FLG_PAT_STATUS';
        --prof_yn                        VARCHAR2(1) := 'Y';
        --value_01                       VARCHAR2(20) := 'A';
        l_str_date VARCHAR2(20);
        --l_sel_date                     TIMESTAMP;
        --l_interval                     NUMBER;
        l_limit_bp_transport sys_config.id_sys_config%TYPE := pk_sysconfig.get_config(i_prof    => l_prof,
                                                                                      i_code_cf => 'BLOOD_TRANSFUSION_TIME_LIMIT');
        g_error              VARCHAR2(250);
        o_error              t_error_out;
    
    BEGIN
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_prof_id', l_prof.id);
        pk_context_api.set_parameter('i_institution', l_prof.institution);
        pk_context_api.set_parameter('i_software', l_prof.software);
        pk_context_api.set_parameter('l_limit_bp_transport', l_limit_bp_transport);
        pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
        l_prof_cat := pk_edis_list.get_prof_cat(l_prof);
    
        IF i_context_keys.exists(1)
        THEN
            l_str_date := i_context_keys(1);
        ELSE
            l_str_date := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            l_str_date := substr(l_str_date, 1, 8) || '000000';
        
        END IF;
    
        pk_context_api.set_parameter('i_dt', l_str_date);
        g_error := 'PK_SR_GRID, Context of' || chr(10) || '*    i_lang:' || l_lang || chr(10) || '*    prof:(' ||
                   l_prof.id || ',' || l_prof.institution || ',' || l_prof.software || ')' || chr(10) || '*    i_dt:' ||
                   l_str_date;
    
        g_error := 'PK_SR_GRID, parameter:' || i_name || ' not found';
        CASE i_name
        
            WHEN 'flg_epis_disch' THEN
                o_vc2 := 'I';
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'i_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'i_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'g_prof_dep_status' THEN
                o_vc2 := 'S';
            WHEN 'dish_status' THEN
                o_vc2 := 'A';
            WHEN 'g_active' THEN
                o_vc2 := g_active;
            WHEN 'g_analysis_exam_icon_grid_rank' THEN
                o_vc2 := g_analysis_exam_icon_grid_rank;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := g_cat_type_doc;
            WHEN 'g_pat_status_pend' THEN
                o_vc2 := g_pat_status_pend;
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            WHEN 'l_hand_off_type' THEN
                o_vc2 := l_hand_off_type;
            WHEN 'l_prof_cat' THEN
                o_vc2 := l_prof_cat;
            WHEN 'l_dt_min' THEN
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => l_str_date,
                                                        i_timezone  => '');
            
            WHEN 'l_dt_max' THEN
            
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => pk_date_utils.add_days(i_lang   => l_lang,
                                                                                           i_prof   => l_prof,
                                                                                           i_date   => pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                                                     i_prof      => l_prof,
                                                                                                                                     i_timestamp => l_str_date,
                                                                                                                                     i_timezone  => ''),
                                                                                           i_amount => 1),
                                                     i_amount    => -1,
                                                     i_unit      => 'second');
            WHEN 'disch_status_p' THEN
                o_vc2 := 'P';
            ELSE
                g_error := 'ERROR, variable not expected:' || i_name;
                dbms_output.put_line(g_error);
                pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => 'ALERT',
                                                  i_package  => 'PK_SR_GRID',
                                                  i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                                  o_error    => o_error);
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_GRID',
                                              i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                              o_error    => o_error);
    END init_params_oris;

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
    * @author               Vítor Sá
    * @version              1.0
    * @since                2018/15/10
    */
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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_value VARCHAR2(1000 CHAR);
        l_prof_cat           VARCHAR2(1000 CHAR);
        l_triage_color_group NUMBER(24);
    
        FUNCTION get_triage_color_group
        (
            i_lang               IN NUMBER,
            i_triage_color_group IN NUMBER
        ) RETURN NUMBER IS
            l_tcg NUMBER;
        BEGIN
        
            IF i_triage_color_group > 0
            THEN
                l_tcg := i_triage_color_group;
            ELSE
                l_tcg := NULL;
            END IF;
        
            RETURN l_tcg;
        
        END get_triage_color_group;
        -- *************************************************************
        PROCEDURE set_context_ids IS
            l_bool BOOLEAN;
            --l_context_keys table_number := table_number();
        BEGIN
        
            --l_bool := i_context_keys IS NOT NULL AND i_context_keys.count > 0;
        
            l_bool := TRUE; --i_context_keys.exists(1);
        
            IF l_bool
            THEN
            
                IF i_context_keys.exists(1)
                THEN
                    l_triage_color_group := i_context_keys(1);
                    l_triage_color_group := get_triage_color_group(g_lang, l_triage_color_group);
                END IF;
                pk_context_api.set_parameter('i_triage_color_group', l_triage_color_group);
            
            END IF;
        
        END set_context_ids;
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', 8);
        
            pk_context_api.set_parameter('e_flg_status_a', pk_alert_constant.g_flg_status_a);
            pk_context_api.set_parameter('e_flg_status_p', pk_alert_constant.g_pending);
            pk_context_api.set_parameter('e_flg_status_c', pk_alert_constant.g_cancelled);
            pk_context_api.set_parameter('g_epis_status_inactive', 'I');
            pk_context_api.set_parameter('l_edis_timelimit', l_value);
                pk_context_api.set_parameter('id_epis_type', k_id_epis_type_edis);
            pk_context_api.set_parameter('e_flg_ehr', pk_alert_constant.g_flg_ehr_n);
        
        END set_context;
    BEGIN
    
        l_value := nvl(pk_sysconfig.get_config('EDIS_GRID_HOURS_LIMIT_SHOW_DISCH', l_prof), 12);
    
        set_context();
        set_context_ids();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'id_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := 8;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'id_epis_type' THEN
                o_id := k_id_epis_type_edis;
            WHEN 'l_sys_config' THEN
                o_id := pk_sysconfig.get_config(pk_inp_grid.g_cf_canc_epis_time, l_prof);
            WHEN 'e_flg_ehr' THEN
                o_vc2 := pk_alert_constant.g_flg_ehr_n;
            WHEN 'e_flg_status_p' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'e_flg_status_a' THEN
                o_vc2 := pk_alert_constant.g_flg_status_a;
            WHEN 'pat_name' THEN
                o_vc2 := i_name;
            WHEN 'pat_name_to_sort' THEN
                o_vc2 := i_name;
            WHEN 'los' THEN
                o_vc2 := i_name;
            WHEN 'los_sort' THEN
                o_vc2 := i_name;
            WHEN 'desc_room' THEN
                o_vc2 := i_name;
            WHEN 'prof_team' THEN
                o_vc2 := i_name;
            WHEN 'edis_grid_m003' THEN
                o_vc2 := i_name;
            WHEN 'pat_age' THEN
                o_vc2 := i_name;
            WHEN 'photo' THEN
                o_vc2 := i_name;
            WHEN 'desc_drug_presc_b' THEN
                o_vc2 := i_name;
            WHEN 'desc_monit_interv_presc' THEN
                o_vc2 := i_name;
            WHEN 'desc_epis_anamnesis' THEN
                o_vc2 := i_name;
            WHEN 'fast_track_icon' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_add_01' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_add' THEN
                o_vc2 := i_name;
            WHEN 'epis_info_flg_status' THEN
                o_vc2 := 'EPIS_INFO.FLG_STATUS';
            WHEN 'hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, o_vc2);
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := 'D';
            WHEN 'g_desc_grid' THEN
                o_vc2 := 'G';
            WHEN 'show_only_epis_resp' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => pk_hand_off_core.g_config_show_only_epis_resp,
                                                 i_prof    => l_prof);
            WHEN 'l_show_resident_physician' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'GRIDS_SHOW_RESIDENT', i_prof => l_prof);
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'format' THEN
                o_vc2 := 'T';
            WHEN 'g_sort_type_age' THEN
                o_vc2 := pk_edis_proc.g_sort_type_age;
            WHEN 'pad_length' THEN
                o_num := 6;
            WHEN 'pad_string' THEN
                o_vc2 := '0';
            WHEN 'g_sysdate_tstz' THEN
                o_tstz := current_timestamp;
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            WHEN 'flg_temp' THEN
                o_vc2 := 'N';
            WHEN 'g_task_analysis' THEN
                o_vc2 := 'A';
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'g_task_exam' THEN
                o_vc2 := 'E';
            WHEN 'g_icon_ft' THEN
                o_vc2 := 'F';
            WHEN 'g_icon_ft_transfer' THEN
                o_vc2 := 'T';
            WHEN 'g_ft_color' THEN
                o_vc2 := '0xFFFFFF';
            WHEN 'g_ft_triage_white' THEN
                o_vc2 := '0x787864';
            WHEN 'g_ft_status' THEN
                o_vc2 := 'A';
            WHEN 'l_egoo' THEN
                o_vc2 := pk_sysconfig.get_config('EDIS_GRID_ORIGIN_ORDER_WITHOUT_TRIAGE', l_prof);
            WHEN 'g_s' THEN
                o_vc2 := 'S';
            WHEN 'grid_origins' THEN
                o_vc2 := pk_sysconfig.get_config('GRID_ORIGINS', l_prof);
            WHEN 'g_epis_status_inactive' THEN
                o_vc2 := 'I';
            WHEN 'l_edis_timelimit' THEN
                o_vc2 := l_value;
            WHEN 'flg_nurse_categ' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'followed_by_me' THEN
                o_vc2 := 'Y';
            WHEN 'desc_img_exam_req' THEN
                o_vc2 := 'desc_img_exam_req';
            WHEN 'desc_oth_exam_req' THEN
                o_vc2 := 'desc_oth_exam_req';
            WHEN 'l_aux_grid' THEN
                o_vc2 := get_aux_grid(i_lang => l_lang, i_prof => l_prof);
            WHEN 'l_value_los' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'TRACKINGVIEW_GRAPHVIEW_ORDER_BY_LOS', i_prof => l_prof);
            WHEN 'l_prof_cat' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_edis;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        --l_prof_cat      category.flg_type%TYPE;
        l_hand_off_type    sys_config.value%TYPE;
        l_reason_grid      VARCHAR2(1);
        l_category         category.id_category%TYPE;
        l_type_opinion     opinion_type.id_opinion_type%TYPE;
        l_profile_template profile_template.id_profile_template%TYPE;
        l_epis_type        number;
    
        o_error t_error_out;
        g_error VARCHAR2(250);
    
        l_id_department NUMBER;
        l_flg_type      VARCHAR2(0200 CHAR);
        tbl_lov_die     table_varchar := table_varchar('LOV_DIE_INP', 'LOV_DIE_URG', 'LOV_DIE_OUTP', 'LOV_DIE_ORIS');
        tbl_epis_type   table_number  := table_number(             5,             2,              1,              4);
        tbl_flg_type    table_varchar := table_varchar('I', 'U', 'C', 'S');
    
        FUNCTION get_flg_type(i_tbl IN table_varchar) RETURN VARCHAR2 IS
            l_return VARCHAR2(0200 CHAR);
        BEGIN
        
            <<lup_thru_keys>>
            FOR i IN 1 .. i_context_keys.count
            LOOP
            
                <<lup_thru_die>>
                FOR j IN 1 .. tbl_lov_die.count
                LOOP
                
                    IF i_context_keys(i) = tbl_lov_die(j)
                    THEN
                        l_return := tbl_flg_type(j);
                        EXIT lup_thru_keys;
                    END IF;
                
                END LOOP;
            
            END LOOP lup_thru_keys;
        
            RETURN l_return;
        
        END get_flg_type;
    
        FUNCTION get_epis_type(i_tbl IN table_varchar) RETURN VARCHAR2 IS
            l_return VARCHAR2(0200 CHAR);
        BEGIN
        
            <<lup_thru_keys>>
            FOR i IN 1 .. i_context_keys.count
            LOOP
            
                <<lup_thru_die>>
                FOR j IN 1 .. tbl_lov_die.count
                LOOP
                
                    IF i_context_keys(i) = tbl_lov_die(j)
                    THEN
                        l_return := tbl_epis_type(j);
                        EXIT lup_thru_keys;
                    END IF;
                
                END LOOP;
            
            END LOOP lup_thru_keys;
        
            RETURN l_return;
        
        END get_epis_type;
    
    
        --**********************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
        
            pk_context_api.set_parameter('i_category', l_category);
            pk_context_api.set_parameter('i_profile_template', l_profile_template);
        
        END set_context;
    
        --*************************************
        FUNCTION get_type_opinion RETURN NUMBER IS
            l_return   NUMBER;
            tbl_return table_number;
        BEGIN
        
            SELECT otc.id_opinion_type
              BULK COLLECT
              INTO tbl_return
              FROM opinion_type_category otc
             WHERE ((otc.id_category = l_category AND otc.id_profile_template IS NULL) OR
                   (otc.id_profile_template = l_profile_template));
    
            IF tbl_return.count > 0
            THEN
                l_return := tbl_return(1);
            END IF;
        
            RETURN l_return;
        
        END get_type_opinion;
    
        PROCEDURE inicialize_code IS
    BEGIN
    
        pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
        l_reason_grid := pk_sysconfig.get_config('REASON_FOR_VISIT_GRID', l_prof);
        l_category    := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            l_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => l_prof);
        
        END inicialize_code;
    
    BEGIN
    
        inicialize_code();
    
        set_context();
    
        l_type_opinion := get_type_opinion();
    
        l_id_department := pk_filter_lov.get_lov_value(i_tbl_lov  => tbl_lov_die,
                                                       i_tbl_keys => i_context_keys,
                                                       i_tbl_vals => i_context_vals);
    
        IF l_id_department = -1
        THEN
            l_flg_type := get_flg_type(tbl_lov_die);
            l_epis_type := get_epis_type(tbl_lov_die);
        else
          l_flg_type := null;
        END IF;
    
        g_error := 'PK_SR_GRID, parameter:' || i_name || ' not found';
        CASE i_name
            when 'l_id_epis_type' then
                 o_id := l_epis_type;
            WHEN 'l_id_department' THEN
                o_id := l_id_department;
                dbms_output.put_line('ID_DEPARTMENT:' || o_id);
            WHEN 'l_flg_type' THEN
                o_vc2 := l_flg_type;
                dbms_output.put_line('ID_DEPARTMENT FLG_TYPE:' || o_vc2);
            WHEN 'l_lang' THEN
                o_vc2 := to_char(l_lang);
            WHEN 'l_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'i_institution' THEN
                o_vc2 := to_char(l_prof.institution);
            WHEN 'l_software' THEN
                o_vc2 := to_char(l_prof.software);
            WHEN 'l_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'i_prof_id' THEN
                o_vc2 := to_char(l_prof.id);
            WHEN 'l_hand_off_type' THEN
                o_vc2 := l_hand_off_type;
            WHEN 'l_reason_grid' THEN
                o_vc2 := l_reason_grid;
            WHEN 'l_type_opinion' THEN
                o_id := l_type_opinion;
            
            ELSE
                g_error := 'ERROR, variable not expected:' || i_name;
                dbms_output.put_line(g_error);
                pk_alert_exceptions.process_error(i_lang     => l_lang,
                                                  i_sqlcode  => SQLCODE,
                                                  i_sqlerrm  => SQLERRM,
                                                  i_message  => g_error,
                                                  i_owner    => 'ALERT',
                                                  i_package  => 'PK_SR_GRID',
                                                  i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                                  o_error    => o_error);
        END CASE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => l_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => 'ALERT',
                                              i_package  => 'PK_SR_GRID',
                                              i_function => 'INIT_PARAMS_PATIENTS_GRIDS',
                                              o_error    => o_error);
    END init_params_sws;

    FUNCTION get_epis_type
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional
    ) RETURN NUMBER IS
        l_ret NUMBER;
    BEGIN
        IF i_prof.software = pk_alert_constant.g_soft_edis
        THEN
            l_ret := k_id_epis_type_edis;
        ELSIF i_prof.software = pk_alert_constant.g_soft_ubu
        THEN
            l_ret := k_id_epis_type_ubu;
        ELSIF i_prof.software = pk_alert_constant.g_soft_inpatient
        THEN
            l_ret := k_id_epis_type_inp;
        END IF;
        RETURN l_ret;
    END get_epis_type;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_value VARCHAR2(1000 CHAR);
    
        l_epis_type     table_number;
        l_hand_off_type sys_config.value%TYPE;
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
        
            pk_context_api.set_parameter('e_flg_status_a', pk_alert_constant.g_flg_status_a);
            pk_context_api.set_parameter('e_flg_status_p', pk_alert_constant.g_pending);
            pk_context_api.set_parameter('e_flg_status_c', pk_alert_constant.g_cancelled);
            pk_context_api.set_parameter('g_epis_status_inactive', 'I');
            pk_context_api.set_parameter('l_edis_timelimit', l_value);
            IF l_prof.software = pk_alert_constant.g_soft_edis
            THEN
                pk_context_api.set_parameter('id_epis_type', k_id_epis_type_edis);
            ELSE
                IF l_prof.software = pk_alert_constant.g_soft_ubu
                THEN
                    pk_context_api.set_parameter('id_epis_type', k_id_epis_type_ubu);
                END IF;
            END IF;
            pk_context_api.set_parameter('e_flg_ehr', pk_alert_constant.g_flg_ehr_n);
            pk_context_api.set_parameter('ndays', 1);
        
        END set_context;
    BEGIN
    
        --l_value := nvl(pk_sysconfig.get_config('EDIS_GRID_HOURS_LIMIT_SHOW_DISCH', l_prof), 12);
    
        set_context();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'id_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'id_software' THEN
                o_id := l_prof.software;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'l_epis_type' THEN
                o_id := get_epis_type(l_lang, l_prof);
            WHEN 'l_sys_config' THEN
                o_id := pk_sysconfig.get_config(pk_inp_grid.g_cf_canc_epis_time, l_prof);
            WHEN 'e_flg_ehr' THEN
                o_vc2 := pk_alert_constant.g_flg_ehr_n;
            WHEN 'e_flg_status_p' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'e_flg_status_a' THEN
                o_vc2 := pk_alert_constant.g_flg_status_a;
            WHEN 'l_dt_med_24' THEN
                o_tstz := current_timestamp - numtodsinterval(1, 'DAY');
            WHEN 'g_epis_inactive' THEN
                o_vc2 := pk_alert_constant.g_inactive;
            WHEN 'g_epis_pending' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'g_false' THEN
                o_num := sys.diutil.bool_to_int(FALSE);
                --o_vc2 := 'F';
            WHEN 'tl_report' THEN
                o_vc2 := 'TL_REPORT';
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
            
                o_vc2 := l_hand_off_type;
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'i_my_patients' THEN
                o_vc2 := pk_alert_constant.g_no;
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_inactive_pat_edis;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        l_value VARCHAR2(1000 CHAR);
    
        l_epis_type     table_number;
        l_hand_off_type sys_config.value%TYPE;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
        
            pk_context_api.set_parameter('e_flg_status_a', pk_alert_constant.g_flg_status_a);
            pk_context_api.set_parameter('e_flg_status_p', pk_alert_constant.g_pending);
            pk_context_api.set_parameter('e_flg_status_c', pk_alert_constant.g_cancelled);
            pk_context_api.set_parameter('g_epis_status_inactive', 'I');
            pk_context_api.set_parameter('l_edis_timelimit', l_value);
            IF l_prof.software = pk_alert_constant.g_soft_edis
            THEN
                pk_context_api.set_parameter('id_epis_type', k_id_epis_type_edis);
            ELSE
                IF l_prof.software = pk_alert_constant.g_soft_ubu
                THEN
                    pk_context_api.set_parameter('id_epis_type', k_id_epis_type_ubu);
                END IF;
            END IF;
            pk_context_api.set_parameter('e_flg_ehr', pk_alert_constant.g_flg_ehr_n);
            pk_context_api.set_parameter('ndays', 1);
        
        END set_context;
    BEGIN
    
        --l_value := nvl(pk_sysconfig.get_config('EDIS_GRID_HOURS_LIMIT_SHOW_DISCH', l_prof), 12);
    
        set_context();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'id_institution' THEN
                o_id := l_prof.institution;
            WHEN 'id_software' THEN
                o_id := l_prof.software;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'l_epis_type' THEN
                o_id := get_epis_type(l_lang, l_prof);
            WHEN 'l_sys_config' THEN
                o_id := pk_sysconfig.get_config(pk_inp_grid.g_cf_canc_epis_time, l_prof);
            WHEN 'e_flg_ehr' THEN
                o_vc2 := pk_alert_constant.g_flg_ehr_n;
            WHEN 'e_flg_status_p' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'e_flg_status_a' THEN
                o_vc2 := pk_alert_constant.g_flg_status_a;
            WHEN 'l_dt_med_24' THEN
                o_tstz := current_timestamp - numtodsinterval(1, 'DAY');
            WHEN 'g_epis_inactive' THEN
                o_vc2 := pk_alert_constant.g_inactive;
            WHEN 'g_epis_pending' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'g_false' THEN
                o_num := sys.diutil.bool_to_int(FALSE);
                --o_vc2 := 'F';
            WHEN 'tl_report' THEN
                o_vc2 := 'TL_REPORT';
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
            
                o_vc2 := l_hand_off_type;
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'i_my_patients' THEN
                o_vc2 := pk_alert_constant.g_no;
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_inactive_pat_clin;

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
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF pk_utils.search_table_number(pk_hand_off_api.get_responsibles_id(i_lang,
                                                                            
                                                                            i_prof,
                                                                            i_id_episode,
                                                                            i_prof_cat_type,
                                                                            i_handoff_type,
                                                                            'Y'),
                                        i_prof.id) != -1
        THEN
            IF i_flg_leader = pk_alert_constant.g_yes
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        ELSE
            IF (i_id_prof_schedule = i_prof.id)
               OR
               (pk_prof_follow.get_follow_episode_by_me(i_prof, i_id_episode, i_id_schedule) = pk_alert_constant.g_yes)
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        END IF;
    END check_is_my_patient;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_date             CONSTANT NUMBER(24) := 1;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_hand_off_type sys_config.value%TYPE;
        l_str_date      VARCHAR2(0050 CHAR);
        l_instr         NUMBER;
        l_id_category   NUMBER;
        --l_type_appointment       VARCHAR2(0002 CHAR);
        l_prof_cat_type          VARCHAR2(0002 CHAR);
        g_epis_type_nurse        VARCHAR2(0100 CHAR);
        g_domain_pat_gender_abbr VARCHAR2(0200 CHAR) := 'PATIENT.GENDER.ABBR';
        k_allow_my_room          VARCHAR2(1000 CHAR) := 'ALLOW_MY_ROOM_SPECIALITY_GRID_TYPE_APPOINT_EDITION';
        g_schdl_outp_sched_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_SCHED';
        g_domain_sch_presence     CONSTANT VARCHAR2(0200 CHAR) := 'SCH_GROUP.FLG_CONTACT_TYPE';
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
            dbms_output.put_line('SET_CONTEXT' || i_name);
            pk_context_api.set_parameter('i_dt', l_str_date);
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
            pk_context_api.set_parameter('g_selected', pk_grid_amb.g_selected);
            pk_context_api.set_parameter('g_sched_status_cache', pk_schedule.g_sched_status_cache);
            pk_context_api.set_parameter('g_sched_canc', 'C');
            pk_context_api.set_parameter('g_epis_type_nurse', g_epis_type_nurse);
            set_context_dates(l_str_date, 1);
            pk_context_api.set_parameter('filter_leader', 'Y');
            --               alert.pk_cdoc_filters.set_context_dates('20190607105845', 1);
            --dbms_output.put_line('DT_MIN:' || to_char(i_context_keys(1)));
        
            /*   pk_context_api.set_parameter('i_lang', 8);
            pk_context_api.set_parameter('i_prof_id', profissional(7020000674731, 11111, 1).id);
            pk_context_api.set_parameter('i_institution', profissional(7020000674731, 11111, 1).institution);
            pk_context_api.set_parameter('i_software', profissional(7020000674731, 11111, 1).software);
            pk_context_api.set_parameter('g_selected', 'S');
            pk_context_api.set_parameter('g_sched_status_cache', 'V');
            pk_context_api.set_parameter('g_epis_type_nurse', 16);
            pk_context_api.set_parameter('g_sched_canc', 'C');
            alert.pk_cdoc_filters.set_context_dates('20190604105845', 1);*/
        
            -- Vars para reabs
            --
        
        END set_context;
    
        PROCEDURE set_context_rehab IS
            -- Rehab
            l_flg_sch_type_cr      schedule.flg_sch_type%TYPE := 'CR';
            l_epis_type_rehab_ap   epis_type.id_epis_type%TYPE := 25;
            l_show_med_disch       VARCHAR2(0200 CHAR);
            l_scfg_rehab_needs_sch VARCHAR2(0200 CHAR);
            l_dt_begin             TIMESTAMP(6) WITH LOCAL TIME ZONE;
            l_dt_end               TIMESTAMP(6) WITH LOCAL TIME ZONE;
            l_dt_today             TIMESTAMP(6) WITH LOCAL TIME ZONE;
            l_date_selected        VARCHAR2(20 CHAR);
            --l_date_selected_tstz   TIMESTAMP(6) WITH LOCAL TIME ZONE;
            l_sysdate_tstz TIMESTAMP(6) WITH LOCAL TIME ZONE;
            l_sysdate_char VARCHAR(50 CHAR);
        BEGIN
        
            pk_context_api.set_parameter('l_lang', l_lang);
            pk_context_api.set_parameter('l_prof_id', l_prof.id);
            pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
            pk_context_api.set_parameter('l_prof_software', pk_alert_constant.g_soft_rehab);
        
            pk_context_api.set_parameter('l_flg_sch_type_cr', l_flg_sch_type_cr);
            pk_context_api.set_parameter('l_epis_type_rehab_ap', l_epis_type_rehab_ap);
        
            l_show_med_disch := nvl(pk_sysconfig.get_config('SHOW_MEDICAL_DISCHARGED_GRID', l_prof),
                                    pk_alert_constant.g_yes);
            pk_context_api.set_parameter('l_show_med_disch', l_show_med_disch);
        
            l_scfg_rehab_needs_sch := pk_sysconfig.get_config('REHAB_NEEDS_SCHEDULE', l_prof);
            pk_context_api.set_parameter('l_scfg_rehab_needs_sch', l_scfg_rehab_needs_sch);
        
            l_dt_today := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp);
            pk_context_api.set_parameter('l_dt_today', l_dt_today);
        
            -- dates begin/ end
            l_sysdate_tstz := systimestamp;
            l_sysdate_char := pk_date_utils.date_send_tsz(l_lang, l_sysdate_tstz, l_prof);
        
            IF i_context_vals IS NOT NULL
            THEN
                l_date_selected := l_sysdate_char;
                IF i_context_vals.count > 0
                THEN
                    l_date_selected := i_context_vals(g_date);
                END IF;
            ELSE
                l_date_selected := l_sysdate_char;
            END IF;
        
            l_dt_begin := pk_date_utils.get_string_tstz(l_lang, l_prof, l_date_selected, NULL);
            --l_dt_end   := l_dt_begin + numtodsinterval(1, 'DAY') + numtodsinterval(-1, 'SECOND');
        
            DECLARE
                l_dt1 VARCHAR2(0050 CHAR);
                l_dt9 VARCHAR2(0050 CHAR);
            BEGIN
                l_dt1 := l_str_date;
                l_dt9 := l_str_date;
            
                --dbms_output.put_line('DT1:' || l_dt1);
                --dbms_output.put_line('DT9:' || l_dt9);
                pk_context_api.set_parameter('l_dt_begin', l_dt1);
                pk_context_api.set_parameter('l_dt_end', l_dt9);
            END;
        
        END set_context_rehab;
    
    BEGIN
        /*
        dbms_output.put_line('*****INIT*****:' || pk_utils.to_string(i_input => i_context_vals) || ' ** ' ||
                             pk_utils.to_string(i_input => i_context_ids));
                             */
        --l_str_date        := '20190705000000' ;
        l_str_date        := i_context_vals(g_date);
        g_epis_type_nurse := pk_sysconfig.get_config('ID_EPIS_TYPE_NURSE', l_prof);
    
        --dbms_output.put_line('*****i_name*****:' || i_name);
    
        set_context();
        set_context_rehab();
    
        CASE lower(i_name)
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'e_flg_status_p' THEN
                o_vc2 := pk_alert_constant.g_pending;
            WHEN 'e_flg_status_a' THEN
                o_vc2 := pk_alert_constant.g_flg_status_a;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'g_domain_pat_gender_abbr' THEN
                o_vc2 := g_domain_pat_gender_abbr;
            WHEN 'g_domain_sch_presence' THEN
                o_vc2 := g_domain_sch_presence;
            WHEN 'g_schdl_outp_sched_domain' THEN
                o_vc2 := g_schdl_outp_sched_domain;
            WHEN 'g_sched_scheduled' THEN
                o_vc2 := 'A';
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'l_handoff_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
            
                o_vc2 := l_hand_off_type;
            WHEN 'l_no_present_patient' THEN
                o_vc2 := pk_message.get_message(l_lang, 'THERAPEUTIC_DECISION_T017');
            WHEN 'l_prof_cat_type' THEN
                o_vc2 := l_prof_cat_type;
            WHEN 'l_type_appoint_edition' THEN
            
                o_vc2 := k_no;
            
                l_id_category := pk_prof_utils.get_id_category(i_lang => l_lang, i_prof => l_prof);
            
                l_instr := instr(pk_sysconfig.get_config(k_allow_my_room, l_prof.institution, l_prof.software),
                                 '|' || l_id_category || '|');
            
                IF l_instr > 0
                THEN
                    o_vc2 := k_yes;
                END IF;
            
            WHEN 'cons_type' THEN
                o_vc2 := i_name;
            WHEN 'desc_room' THEN
                o_vc2 := i_name;
            WHEN 'extend_icon' THEN
                o_vc2 := i_name;
            WHEN 'flg_contact' THEN
                o_vc2 := i_name;
            WHEN 'flg_state' THEN
                o_vc2 := i_name;
            WHEN 'icon_contact_type' THEN
                o_vc2 := i_name;
            WHEN 'img_state' THEN
                o_vc2 := i_name;
            WHEN 'pat_name' THEN
                o_vc2 := i_name;
            WHEN 'pat_name_to_sort' THEN
                o_vc2 := i_name;
            WHEN 'num_clin_record' THEN
                o_vc2 := i_name;
            WHEN 'pat_age' THEN
                o_vc2 := i_name;
            WHEN 'pat_nd_icon' THEN
                o_vc2 := i_name;
            WHEN 'photo' THEN
                o_vc2 := i_name;
            WHEN 'prof_team' THEN
                o_vc2 := i_name;
            WHEN 'rank' THEN
                o_vc2 := i_name;
            WHEN 'therapeutic_doctor' THEN
                o_vc2 := i_name;
            WHEN 'wr_call' THEN
                o_vc2 := i_name;
            WHEN 'internment' THEN
                o_vc2 := i_name;
            WHEN 'appointment_type' THEN
                o_vc2 := upper(i_name);
            WHEN 'l_flg_type_a' THEN
                o_vc2 := 'A';
            WHEN 'k_epis_inactive' THEN
                o_vc2 := 'I';
            WHEN 'l_dt_min' THEN
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => alert_context('l_dt_min'),
                                                        i_timezone  => '');
            
            WHEN 'l_dt_max' THEN
            
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => pk_date_utils.add_days(i_lang   => l_lang,
                                                                                           i_prof   => l_prof,
                                                                                           i_date   => pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                                                                                                     i_prof      => l_prof,
                                                                                                                                     i_timestamp => alert_context('l_dt_min'),
                                                                                                                                     i_timezone  => ''),
                                                                                           i_amount => 1),
                                                     i_amount    => -1,
                                                     i_unit      => 'SECOND');
            
        END CASE;
    
    END init_params_admin;

    FUNCTION get_hhc_episode(i_episode IN NUMBER) RETURN NUMBER IS
        tbl_episode       table_number;
        tbl_epis_type     table_number;
        l_epis_type       NUMBER;
        l_id_prev_episode NUMBER;
        l_return          NUMBER;
    BEGIN
    
        SELECT id_epis_type, id_prev_episode
          BULK COLLECT
          INTO tbl_epis_type, tbl_episode
          FROM episode
         WHERE id_episode = i_episode;
    
        IF tbl_epis_type.count > 0
        THEN
        
            l_epis_type       := tbl_epis_type(1);
            l_id_prev_episode := tbl_episode(1);
        
            CASE l_epis_type
                WHEN pk_hhc_constant.k_hhc_epis_type THEN
                    l_return := i_episode;
                WHEN pk_hhc_constant.k_hhc_epis_type_child THEN
                    l_return := l_id_prev_episode;
                ELSE
                    NULL;
            END CASE;
        
        END IF;
    
        RETURN l_return;
    
    END get_hhc_episode;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
        l_has_mrp_permission VARCHAR2(0010 CHAR);
    
        l_prof_has_mrp_permission VARCHAR2(0010 CHAR);
        g_domain_pat_gender_abbr  VARCHAR2(0200 CHAR) := 'PATIENT.GENDER.ABBR';
        l_count                   NUMBER;
        l_hhc_episode             NUMBER;
    
    BEGIN
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_episode' THEN
                o_id := l_episode;
            WHEN 'i_epis_hhc' THEN
                o_id := i_context_vals(1);
            WHEN 'i_patient' THEN
                o_id := l_patient;
            WHEN 'has_mrp_permission' THEN
                o_vc2 := get_prof_flg_mrp(i_lang => l_lang, i_prof => l_prof);
            WHEN 'g_domain_pat_gender_abbr' THEN
                o_vc2 := g_domain_pat_gender_abbr;
            WHEN 'flg_add' THEN
                o_vc2                := k_no;
                l_has_mrp_permission := get_prof_flg_mrp(i_lang => l_lang, i_prof => l_prof);
            
                IF l_has_mrp_permission = k_yes
                THEN
                
                    l_count := get_count_hhc_req_by_patient(i_patient => l_patient);
                
                    IF l_count = 0
                    THEN
                        o_vc2 := k_yes;
                    END IF;
                
                END IF;
            
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_hhc_req;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
    
        --FILTER_BIND
        l_hand_off_type          sys_config.value%TYPE;
        l_str_date               VARCHAR2(0050 CHAR);
        l_instr                  NUMBER;
        l_id_category            NUMBER;
        l_type_appointment       VARCHAR2(0002 CHAR);
        l_dt                     TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_cat_type          VARCHAR2(0002 CHAR);
        g_epis_type_nurse        VARCHAR2(0100 CHAR);
        g_domain_pat_gender_abbr VARCHAR2(0200 CHAR) := 'PATIENT.GENDER.ABBR';
        g_schdl_outp_sched_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_SCHED';
        g_domain_sch_presence     CONSTANT VARCHAR2(0200 CHAR) := 'SCH_GROUP.FLG_CONTACT_TYPE';
        g_schdl_outp_state_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_STATE';
    
        FUNCTION get_current_dt
        (
            i_lang IN NUMBER,
            i_prof IN profissional
        ) RETURN VARCHAR2 IS
            l_dt VARCHAR2(0100 CHAR);
        BEGIN
        
            l_dt := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            l_dt := substr(l_dt, 1, 8) || '000000';
        
            RETURN l_dt;
        
        END get_current_dt;
        -- *************************************************************
        PROCEDURE set_context_ids IS
            l_bool BOOLEAN;
            --l_context_keys table_number := table_number();
        BEGIN
        
            --l_bool := i_context_keys IS NOT NULL AND i_context_keys.count > 0;
        
            l_bool := TRUE; --i_context_keys.exists(1);
        
            IF l_bool
            THEN
            
                IF i_context_keys.exists(1)
                THEN
                    l_str_date := i_context_keys(1);
                ELSE
                    l_str_date := get_current_dt(g_lang, l_prof);
                END IF;
                pk_context_api.set_parameter('i_dt', l_str_date);
            
            END IF;
        
        END set_context_ids;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_institution', l_prof.institution);
            pk_context_api.set_parameter('i_software', l_prof.software);
            pk_context_api.set_parameter('g_selected', pk_grid_amb.g_selected);
            pk_context_api.set_parameter('g_sched_status_cache', pk_schedule.g_sched_status_cache);
        
            IF i_context_keys.exists(1)
            THEN
                set_context_dates(i_context_keys(1), 1);
            ELSE
                set_context_dates(get_current_dt(g_lang, l_prof), 1);
            END IF;
        
        END set_context;
    
    BEGIN
    
        set_context();
    
        set_context_ids();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'id_epis_hhc_appoint' THEN
                o_vc2 := k_epis_hhc_appoint;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_software' THEN
                o_id := l_prof.software;
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            WHEN 'g_domain_pat_gender_abbr' THEN
                o_vc2 := g_domain_pat_gender_abbr;
            WHEN 'g_domain_sch_presence' THEN
                o_vc2 := g_domain_sch_presence;
            WHEN 'g_schdl_outp_sched_domain' THEN
                o_vc2 := g_schdl_outp_sched_domain;
            WHEN 'g_sched_cancel' THEN
                o_vc2 := k_sched_canc;
            WHEN 'g_sched_scheduled' THEN
                o_vc2 := 'A';
            WHEN 'g_schdl_outp_state_domain' THEN
                o_vc2 := g_schdl_outp_state_domain;
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            WHEN 'i_prof_cat_type' THEN
                o_vc2 := pk_edis_list.get_prof_cat(l_prof);
            WHEN 'prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            WHEN 'l_handoff_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            WHEN 'l_no_present_patient' THEN
                o_vc2 := pk_message.get_message(l_lang, 'THERAPEUTIC_DECISION_T017');
            WHEN 'l_prof_cat_type' THEN
                o_vc2 := l_prof_cat_type;
            WHEN 'l_show_resident_physician' THEN
                o_vc2 := pk_sysconfig.get_config(i_code_cf => 'GRIDS_SHOW_RESIDENT', i_prof => l_prof);
            
            WHEN 'cons_type' THEN
                o_vc2 := i_name;
            WHEN 'desc_ana_exam_req' THEN
                o_vc2 := i_name;
            WHEN 'desc_drug_presc_b' THEN
                o_vc2 := i_name;
            WHEN 'desc_exam_req_b' THEN
                o_vc2 := i_name;
            WHEN 'desc_interv_presc' THEN
                o_vc2 := i_name;
            WHEN 'desc_room' THEN
                o_vc2 := i_name;
            WHEN 'extend_icon' THEN
                o_vc2 := i_name;
            WHEN 'flg_contact' THEN
                o_vc2 := i_name;
            WHEN 'flg_state' THEN
                o_vc2 := i_name;
            WHEN 'icon_contact_type' THEN
                o_vc2 := i_name;
            WHEN 'img_state' THEN
                o_vc2 := i_name;
            WHEN 'img_state_rank' THEN
                o_vc2 := i_name;
            WHEN 'pat_name' THEN
                o_vc2 := i_name;
            WHEN 'pat_name_to_sort' THEN
                o_vc2 := i_name;
            WHEN 'num_clin_record' THEN
                o_vc2 := i_name;
            WHEN 'pat_age' THEN
                o_vc2 := i_name;
            WHEN 'pat_nd_icon' THEN
                o_vc2 := i_name;
            WHEN 'photo' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_add_01' THEN
                o_vc2 := i_name;
            WHEN 'prof_follow_remove' THEN
                o_vc2 := i_name;
            WHEN 'prof_team' THEN
                o_vc2 := i_name;
            WHEN 'rank' THEN
                o_vc2 := i_name;
            WHEN 'therapeutic_doctor' THEN
                o_vc2 := i_name;
            WHEN 'visit_reason' THEN
                o_vc2 := i_name;
            
            WHEN 'l_dt_min' THEN
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => alert_context('l_dt_min'),
                                                        i_timezone  => '');
            
            WHEN 'l_dt_max' THEN
            
                l_dt := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                      i_prof      => l_prof,
                                                      i_timestamp => alert_context('l_dt_min'),
                                                      i_timezone  => '');
                l_dt := pk_date_utils.add_days(i_lang => l_lang, i_prof => l_prof, i_date => l_dt, i_amount => 1);
            
                o_tstz := pk_date_utils.add_to_ltstz(i_timestamp => l_dt, i_amount => -1, i_unit => 'SECOND');
            
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_hhc_app;

    -- *****************************************
    FUNCTION do_get_status_icon_base
    (
        i_lang       IN NUMBER,
        i_mode       IN VARCHAR2,
        i_sch_status IN VARCHAR2,
        i_dsc_status IN VARCHAR2,
        i_flg_ehr    IN VARCHAR2,
        i_flg_state  IN VARCHAR2
    ) RETURN VARCHAR2 IS
        k_sch_status_4_approval CONSTANT VARCHAR2(0050 CHAR) := pk_schedule.g_sched_status_pend_approval;
        k_sch_status_approved   CONSTANT VARCHAR2(0050 CHAR) := pk_schedule.g_sched_status_scheduled;
        k_sch_icon_inprogress   CONSTANT VARCHAR2(0050 CHAR) := 'WorkflowIcon';
        k_sch_icon_concluded    CONSTANT VARCHAR2(0050 CHAR) := 'CheckIcon';
        k_sch_icon_no_show      CONSTANT VARCHAR2(0050 CHAR) := 'AppointmentMissedIcon';
        k_dsc_status_active     CONSTANT VARCHAR2(0050 CHAR) := pk_discharge.g_disch_flg_status_active;
        k_dsc_status_cancel     CONSTANT VARCHAR2(0050 CHAR) := pk_discharge.g_disch_flg_status_cancel;
        k_flg_ehr_agendado      CONSTANT VARCHAR2(0050 CHAR) := 'S';
        k_flg_status_noshow schedule_outp.flg_state%TYPE := 'B';
        l_return            VARCHAR2(1000 CHAR);
        l_return1           VARCHAR2(1000 CHAR);
        l_return2           VARCHAR2(1000 CHAR);
        l_return3           VARCHAR2(1000 CHAR);
        l_dsc_status        VARCHAR2(0050 CHAR) := i_dsc_status;
    
        k_vis_state_flg_pending   CONSTANT VARCHAR2(0050 CHAR) := 'V';
        k_vis_state_flg_scheduled CONSTANT VARCHAR2(0050 CHAR) := 'A';
        --k_vis_state_flg_inprogress CONSTANT VARCHAR2(0050 CHAR) := 'T';
        --k_vis_state_flg_concluded  CONSTANT VARCHAR2(0050 CHAR) := 'C';
    
        k_vis_state_name_pending    CONSTANT VARCHAR2(0050 CHAR) := 'PENDING';
        k_vis_state_name_scheduled  CONSTANT VARCHAR2(0050 CHAR) := 'SCHEDULED';
        k_vis_state_name_inprogress CONSTANT VARCHAR2(0050 CHAR) := 'INPROGRESS';
        k_vis_state_name_concluded  CONSTANT VARCHAR2(0050 CHAR) := 'CONCLUDED';
        k_vis_state_name_noshow     CONSTANT VARCHAR2(0050 CHAR) := 'NO_SHOW';
    
    BEGIN
    
        l_dsc_status := coalesce(l_dsc_status, '-');
    
        IF i_flg_state = k_flg_status_noshow
        THEN
            l_return1 := k_sch_icon_no_show;
            l_return2 := k_vis_state_name_noshow;
            l_return3 := '410';
        ELSE
            IF i_flg_ehr = k_flg_ehr_agendado
            THEN
            
                l_return1 := pk_sysdomain.get_img(i_lang     => i_lang,
                                                  i_code_dom => 'SCHEDULE.FLG_STATUS',
                                                  i_val      => i_sch_status);
            
                CASE i_sch_status
                    WHEN k_vis_state_flg_pending THEN
                        l_return2 := k_vis_state_name_pending;
                        l_return3 := '100';
                    WHEN k_vis_state_flg_scheduled THEN
                        l_return2 := k_vis_state_name_scheduled;
                        l_return3 := '200';
                    ELSE
                        l_return2 := NULL;
                        l_return3 := NULL;
                END CASE;
            
            ELSE
                IF l_dsc_status = k_dsc_status_active
                THEN
                    l_return1 := k_sch_icon_concluded;
                    l_return2 := k_vis_state_name_concluded;
                    l_return3 := '400';
                ELSE
                    l_return1 := k_sch_icon_inprogress;
                    l_return2 := k_vis_state_name_inprogress;
                    l_return3 := '300';
                END IF;
            
            END IF;
        
        END IF;
    
        CASE i_mode
            WHEN 'ICON' THEN
                l_return := l_return1;
            WHEN 'INTERNAL' THEN
                l_return := l_return2;
            WHEN 'ORDER' THEN
                l_return := l_return3;
        END CASE;
    
        RETURN l_return;
    
    END do_get_status_icon_base;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        --FILTER_BIND
        l_hand_off_type          sys_config.value%TYPE;
        l_str_date               VARCHAR2(0050 CHAR);
        l_instr                  NUMBER;
        l_id_category            NUMBER;
        l_type_appointment       VARCHAR2(0002 CHAR);
        l_dt                     TIMESTAMP WITH LOCAL TIME ZONE;
        l_prof_cat_type          VARCHAR2(0002 CHAR);
        g_epis_type_nurse        VARCHAR2(0100 CHAR);
        g_domain_pat_gender_abbr VARCHAR2(0200 CHAR) := 'PATIENT.GENDER.ABBR';
        g_schdl_outp_sched_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_SCHED';
        g_domain_sch_presence     CONSTANT VARCHAR2(0200 CHAR) := 'SCH_GROUP.FLG_CONTACT_TYPE';
        g_schdl_outp_state_domain CONSTANT VARCHAR2(0200 CHAR) := 'SCHEDULE_OUTP.FLG_STATE';
    
        FUNCTION get_current_dt
        (
            i_lang IN NUMBER,
            i_prof IN profissional
        ) RETURN VARCHAR2 IS
            l_dt VARCHAR2(0100 CHAR);
        BEGIN
        
            l_dt := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
            l_dt := substr(l_dt, 1, 8) || '000000';
        
            RETURN l_dt;
        
        END get_current_dt;
    
        -- *************************************************************
        PROCEDURE set_dates IS
            l_bool     BOOLEAN;
            l_str_date VARCHAR2(0100 CHAR);
            --l_context_keys table_number := table_number();
        BEGIN
        
            l_str_date := get_current_dt(g_lang, l_prof);
        
            pk_context_api.set_parameter('l_dt_begin', l_str_date);
            pk_context_api.set_parameter('l_dt_end', l_str_date);
        
            dbms_output.put_line('-- CMF:' || alert_context('l_dt_begin'));
            dbms_output.put_line('-- CMF:' || alert_context('l_dt_end'));
        
        END set_dates;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('l_lang', l_lang);
            pk_context_api.set_parameter('l_prof_id', l_prof.id);
            pk_context_api.set_parameter('l_prof_institution', l_prof.institution);
            pk_context_api.set_parameter('l_prof_software', l_prof.software);
        
            dbms_output.put_line('-- CMF:' || alert_context('l_lang'));
            dbms_output.put_line('-- CMF:' || alert_context('l_prof_id'));
            dbms_output.put_line('-- CMF:' || alert_context('l_prof_institution'));
            dbms_output.put_line('-- CMF:' || alert_context('l_prof_software'));
        
        END set_context;
    
    BEGIN
    
        set_context();
    
        set_dates();
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_institution' THEN
                o_id := l_prof.institution;
                dbms_output.put_line('-- teste:' || l_prof.institution);
            WHEN 'i_software' THEN
                o_id := l_prof.software;
                dbms_output.put_line('-- teste:' || l_prof.software);
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_epis_unpayed;
	
    PROCEDURE init_params_drl_presc_req
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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        g_episode          CONSTANT NUMBER(24) := 5;
        g_patient          CONSTANT NUMBER(24) := 6;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
    
        l_lang    CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_patient CONSTANT patient.id_patient%TYPE := i_context_ids(g_patient);
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(g_episode);
    
    BEGIN
    
        CASE i_name
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            WHEN 'i_patient' THEN
                o_id := l_patient;
            
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_params_drl_presc_req;

    FUNCTION do_edis_dt_begin
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_has_transfer BOOLEAN;
        l_id_episode   NUMBER;
        l_d_flg_status VARCHAR2(0100 CHAR);
        xepis_info     epis_info%ROWTYPE;
        xepisode       episode%ROWTYPE;
        l_dt           TIMESTAMP WITH LOCAL TIME ZONE;
        l_return       VARCHAR2(0200 CHAR);
        --************
        FUNCTION get_epis_info(i_episode IN NUMBER) RETURN epis_info%ROWTYPE IS
            l_epis epis_info%ROWTYPE;
        BEGIN
            SELECT *
              INTO l_epis
              FROM epis_info
             WHERE id_episode = i_episode;
            RETURN l_epis;
        END get_epis_info;
        --***************
        FUNCTION get_episode(i_episode IN NUMBER) RETURN episode%ROWTYPE IS
            l_epis episode%ROWTYPE;
        BEGIN
            SELECT *
              INTO l_epis
              FROM episode
             WHERE id_episode = i_episode;
            RETURN l_epis;
        END get_episode;
    
    BEGIN
    
        l_id_episode   := i_num01(1); -- e.id_episode
        l_d_flg_status := i_var01(1); -- d.flg_status
    
        l_has_transfer := pk_transfer_institution.check_epis_transfer(l_id_episode) > 0;
        xepis_info     := get_epis_info(l_id_episode);
        xepisode       := get_episode(l_id_episode);
    
        <<do_flg_status>>CASE
            WHEN l_d_flg_status IS NULL THEN
            
                IF l_has_transfer
                THEN
                
                    l_dt := pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                          i_prof,
                                                                          l_id_episode);
                
                ELSE
                
                    l_dt := xepisode.dt_begin_tstz;
                    IF xepis_info.dt_first_inst_obs_tstz IS NOT NULL
                    THEN
                        l_dt := NULL;
                    END IF;
                
                END IF;
            
            WHEN l_d_flg_status = 'R' THEN
            
                <<do_flg_dt_obs>>
                IF xepis_info.dt_first_inst_obs_tstz IS NULL
                THEN
                    IF l_has_transfer
                    THEN
                        l_dt := pk_transfer_institution.get_grid_task_arrival(i_lang,
                                                                              i_prof,
                                                                              l_id_episode);
                    ELSE
                        l_dt := xepisode.dt_begin_tstz;
                    END IF;
                ELSE
                    l_dt := NULL;
                END IF;
            
            ELSE
                l_dt := NULL;
        END CASE do_flg_status;
    
        --l_return := pk_date_utils.date_send_tsz(i_lang, l_dt, i_prof);
        IF l_dt IS NOT NULL
        THEN
            l_return := pk_cdoc_filters.get_status_string(i_lang, i_prof, l_dt);
        END IF;
    
        RETURN l_return;
    
    END do_edis_dt_begin;

    FUNCTION get_admission_reas_dest(i_prof IN profissional) RETURN table_number IS
        tbl_dsc_dest table_number;
    BEGIN
    
        SELECT id_disch_reas_dest
          BULK COLLECT
          INTO tbl_dsc_dest
          FROM (SELECT drd.id_disch_reas_dest
                  FROM disch_reas_dest drd
                 WHERE EXISTS (SELECT 0
                          FROM profile_disch_reason pdr
                          JOIN discharge_flash_files dff
                            ON (dff.id_discharge_flash_files = pdr.id_discharge_flash_files)
                         WHERE pdr.id_discharge_reason = drd.id_discharge_reason
                           AND dff.flg_type = 'A')
                   AND drd.flg_active = pk_alert_constant.g_active
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = pk_alert_constant.g_soft_edis
                UNION
                SELECT drd.id_disch_reas_dest
                  FROM discharge_reason dr
                  JOIN disch_reas_dest drd
                    ON drd.id_discharge_reason = dr.id_discharge_reason
                 WHERE flg_available = pk_alert_constant.g_yes
                   AND drd.flg_active = pk_alert_constant.g_active
                   AND dr.flg_available = pk_alert_constant.g_yes
                   AND drd.id_instit_param = i_prof.institution
                   AND drd.id_software_param = pk_alert_constant.g_soft_edis
                   AND dr.file_to_execute = pk_discharge.g_disch_screen_disp_admit);
    
        RETURN tbl_dsc_dest;
    
    END get_admission_reas_dest;

    FUNCTION get_admission_time
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        tbl_reas   table_number;
        tbl_med    table_timestamp;
        tbl_pend   table_timestamp;
        tbl_status table_varchar;
        l_return   VARCHAR2(4000);
        l_dt       TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        tbl_reas := get_admission_reas_dest(i_prof => i_prof);
    
        SELECT /*+ OPT_ESTIMATE(TABLE t ROWS=1) */
         d.dt_med_tstz, d.dt_pend_tstz, d.flg_status
          BULK COLLECT
          INTO tbl_med, tbl_pend, tbl_status
          FROM discharge d
          JOIN (SELECT column_value id_disch_reas_dest
                  FROM TABLE(tbl_reas)) t
            ON t.id_disch_reas_dest = d.id_disch_reas_dest
         WHERE d.id_episode = i_episode
           AND d.flg_status IN ('A', 'P');
    
        IF tbl_status.count > 0
        THEN
            -- or pend or dt_med conforme flg_Status
            IF tbl_status(1) = 'A'
            THEN
                l_dt := tbl_med(1);
                --l_return := pk_date_utils.date_send_tsz(i_lang, tbl_med(1), i_prof);
            ELSE
                l_dt := tbl_pend(1);
                --l_return := pk_date_utils.date_send_tsz(i_lang, tbl_pend(1), i_prof);
            END IF;
        
            l_return := pk_cdoc_filters.get_status_string(i_lang, i_prof, l_dt);
        
        END IF;
    
        RETURN l_return;
    
    END get_admission_time;

    FUNCTION get_discharge_notes
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2 IS
    
        CURSOR dsc_c(i_episode IN NUMBER) IS
            SELECT e.flg_status flg_status_e, dd.follow_up_date_tstz, d.id_disch_reas_dest
              FROM episode e
              JOIN discharge d
                ON d.id_episode = e.id_episode
              JOIN discharge_detail dd
                ON dd.id_discharge = d.id_discharge
             WHERE d.flg_status IN ('A', 'P')
               AND e.id_episode = i_episode;
    
        TYPE type_dsc IS TABLE OF dsc_c%ROWTYPE;
        tbl_dsc type_dsc;
    
        l_return                 VARCHAR2(4000);
        l_label                  VARCHAR2(4000);
        l_dt_follow_up_date      VARCHAR2(4000);
        l_dt_mask_follow_up_date VARCHAR2(4000);
        l_hour_follow_up_date    VARCHAR2(4000);
        l_lf                     VARCHAR2(0010 CHAR) := chr(10);
        l_cat_type               VARCHAR2(0050 CHAR);
        l_edis_admission         VARCHAR2(0010 CHAR);
    
        k_pending CONSTANT VARCHAR2(0050 CHAR) := 'P';
    
        --********************************
        PROCEDURE process_label IS
        BEGIN
        
            IF tbl_dsc(1).follow_up_date_tstz IS NULL
            THEN
            
                l_cat_type := pk_edis_list.get_prof_cat(i_prof);
            
                l_label := pk_edis_grid.get_label_follow_up_date(i_lang,
                                                                 i_prof,
                                                                 tbl_dsc(1).id_disch_reas_dest,
                                                                 l_cat_type);
            
            ELSE
            
                l_label := pk_message.get_message(i_lang, 'EDIS_GRID_T054');
            
            END IF;
        
        END process_label;
    
        --*********************************
        PROCEDURE build_return IS
        BEGIN
        
            l_return := l_return || l_label;
            l_return := l_return || l_lf || l_dt_follow_up_date;
            l_return := l_return || l_lf || l_dt_mask_follow_up_date;
            l_return := l_return || l_lf || l_hour_follow_up_date;
        
        END build_return;
    
    BEGIN
    
        OPEN dsc_c(i_id_episode);
        FETCH dsc_c BULK COLLECT
            INTO tbl_dsc;
        CLOSE dsc_c;
    
        l_label             := NULL;
        l_dt_follow_up_date := NULL;
    
        IF tbl_dsc.count > 0
        THEN
        
            --IF tbl_dsc(1).flg_status_e = k_pending
            --THEN
        
            process_label();
        
            l_dt_follow_up_date := pk_date_utils.date_send_tsz(i_lang, tbl_dsc(1).follow_up_date_tstz, i_prof);
        
            l_dt_mask_follow_up_date := pk_date_utils.date_chr_short_read_tsz(i_lang,
                                                                              tbl_dsc(1).follow_up_date_tstz,
                                                                              i_prof);
        
            l_hour_follow_up_date := pk_date_utils.date_char_hour_tsz(i_lang,
                                                                      tbl_dsc(1).follow_up_date_tstz,
                                                                      i_prof.institution,
                                                                      i_prof.software);
        
            build_return();
        
            --END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_discharge_notes;

    --*****************************
    FUNCTION get_status_string
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
        k_display_type_date CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_display_type_date;
        k_date_mask         CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_dt_yyyymmddhh24miss_tzr;
        k_red               CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_color_red;
        k_color_null        CONSTANT VARCHAR2(0050 CHAR) := pk_alert_constant.g_color_null;
    
        l_status_desc VARCHAR2(1000 CHAR);
    
    BEGIN
        IF i_dt IS NOT NULL
        THEN
        l_status_desc := '';
    
        l_return := pk_utils.get_status_string_immediate(i_lang         => i_lang,
                                                         i_prof         => i_prof,
                                                         i_display_type => k_display_type_date,
                                                         i_value_date   => pk_date_utils.to_char_insttimezone(i_prof,
                                                                                                              i_dt,
                                                                                                              k_date_mask),
                                                         i_back_color   => pk_alert_constant.g_color_red,
                                                         i_icon_color   => pk_alert_constant.g_color_null,
                                                         i_tooltip_text => l_status_desc, --for tooltip
                                                         i_dt_server    => current_timestamp);
        end if;
    
        RETURN l_return;
    
    END get_status_string;

    --****************************************
    FUNCTION get_disch_time
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_flg_status_disch IN VARCHAR2,
        i_flag             IN VARCHAR2,
        i_dt               IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0500 CHAR);
    BEGIN
    
          IF i_flg_status_disch = i_flag
          THEN
              l_return := pk_cdoc_filters.get_status_string(i_lang, i_prof, i_dt);
          ELSE
              l_return := NULL;
          END IF;

        RETURN l_return;
    
    END get_disch_time;

    --****************************************
    FUNCTION get_disch_time_sort
    (
        i_lang             IN NUMBER,
        i_prof             IN profissional,
        i_flg_status_disch IN VARCHAR2,
        i_flag             IN VARCHAR2,
        i_dt               IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(0500 CHAR);
    BEGIN
    
        IF i_flg_status_disch = i_flag
        THEN
            l_return := pk_cdoc_filters.get_status_string(i_lang, i_prof, i_dt);
            l_return := convert_grid_str_to_sort(i_str => l_return);
        ELSE
            l_return := NULL;
        END IF;
    
        RETURN l_return;
    
    END get_disch_time_sort;

    FUNCTION get_admission_time_sort
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_cdoc_filters.get_admission_time(i_lang => i_lang, i_prof => i_prof, i_episode => i_episode);
        l_return := convert_grid_str_to_sort(i_str => l_return);
    
        RETURN l_return;
    
    END get_admission_time_sort;

    FUNCTION do_edis_dt_begin_sort
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := do_edis_dt_begin(i_lang => i_lang, i_prof => i_prof, i_num01 => i_num01, i_var01 => i_var01);
        l_return := convert_grid_str_to_sort(i_str => l_return);
    
        RETURN l_return;
    
    END do_edis_dt_begin_sort;

    FUNCTION get_transfer_status_icon_sort
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := pk_service_transfer.get_transfer_status_icon(i_lang, i_prof, i_id_episode, 'H');
        l_return := convert_grid_str_to_sort(i_str => l_return);
    
        RETURN l_return;
    
    END get_transfer_status_icon_sort;

    --********************************
    FUNCTION do_transfer_status_icon
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_id    IN NUMBER,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode NUMBER;
        l_id_view    NUMBER;
        l_flag       VARCHAR2(0050 CHAR);
        l_return     VARCHAR2(4000);
    BEGIN
    
        l_id_episode := i_num01(1);
        l_id_view    := i_num01(2);
    
        IF l_id_view = i_id
        THEN
        
            CASE l_id_view
                WHEN 1 THEN
                    l_flag := NULL;
                WHEN 2 THEN
                    l_flag := pk_service_transfer.g_transfer_flg_hospital_h;
                ELSE
                    l_flag := NULL;
            END CASE;
        
            l_return := pk_service_transfer.get_transfer_status_icon(i_lang, i_prof, l_id_episode, l_flag);
        
        END IF;
    
        RETURN l_return;
    
    END do_transfer_status_icon;

    FUNCTION do_discharge_date
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode NUMBER;
        l_return     VARCHAR2(4000);
        l_dt         TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
    
        l_id_episode := i_num01(1);
    
        l_dt := pk_discharge.get_discharge_date(i_lang, i_prof, l_id_episode);
        --l_flag := pk_inp_grid.get_discharge_flg(i_lang, i_prof, l_id_episode);
    
        l_return := pk_date_utils.dt_chr_tsz(i_lang, l_dt, i_prof);
    
        RETURN l_return;
    
    END do_discharge_date;

    FUNCTION do_discharge_dt_pend
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode NUMBER;
        l_return     VARCHAR2(4000);
        l_dt         TIMESTAMP WITH LOCAL TIME ZONE;
        tbl_dt       table_timestamp;
    BEGIN
    
        l_id_episode := i_num01(1);
    
        SELECT d.dt_pend_tstz
          BULK COLLECT
          INTO tbl_dt
          FROM discharge d
         WHERE d.id_episode = l_id_episode
           AND d.flg_status IN ('A', 'P');
    
        IF tbl_dt.count > 0
        THEN
            l_dt := tbl_dt(1);
        END IF;
    
        --l_return := pk_date_utils.dt_chr_tsz(i_lang, l_dt, i_prof);
    
        IF l_dt IS NOT NULL
        THEN
            l_return := pk_cdoc_filters.get_status_string(i_lang, i_prof, l_dt);
        END IF;
    
        RETURN l_return;
    
    END do_discharge_dt_pend;

    --************************************
    FUNCTION do_inp_flg_status
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode   NUMBER;
        l_return       VARCHAR2(4000);
        l_flg_status_e VARCHAR2(0500 CHAR);
        l_flg_status_d VARCHAR2(0050 CHAR);
    BEGIN
    
        l_id_episode   := i_num01(1);
        l_flg_status_e := i_var01(1);
    
        l_flg_status_d := pk_inp_grid.get_discharge_flg(i_lang, i_prof, l_id_episode);
        l_flg_status_e := pk_inp_grid.get_epis_status_icon(i_lang, i_prof, l_id_episode, l_flg_status_e, l_flg_status_d);
    
        RETURN l_flg_status_e;
    
    END do_inp_flg_status;

    FUNCTION do_discharge_type
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_num01 IN table_number,
        i_var01 IN table_varchar
    ) RETURN VARCHAR2 IS
        l_id_episode   NUMBER;
        l_return       VARCHAR2(4000);
        l_flg_status_e VARCHAR2(0050 CHAR);
        l_flg_status_d VARCHAR2(0050 CHAR);
    BEGIN
    
        l_id_episode   := i_num01(1);
        l_flg_status_e := i_var01(1);
    
        l_flg_status_d := pk_inp_grid.get_discharge_flg(i_lang, i_prof, l_id_episode);
        l_return       := pk_inp_grid.get_discharge_msg(i_lang, i_prof, l_id_episode, l_flg_status_d);
    
        RETURN l_return;
    
    END do_discharge_type;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        k_pos_episode      CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        l_msg        VARCHAR2(4000);
        l_id_episode NUMBER := -9999999;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('i_lang', l_lang);
            pk_context_api.set_parameter('i_prof_id', l_prof.id);
            pk_context_api.set_parameter('i_prof_institution', l_prof.institution);
            pk_context_api.set_parameter('i_prof_software', l_prof.software);
        
        END set_context;
    
    BEGIN
    
        set_context();
    
        /*
        IF i_context_vals.count > 0
        THEN
            l_id_episode := i_context_vals(k_pos_episode);
        END IF;
        */
        l_id_episode := i_context_ids(k_pos_episode);
    
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'l_notes_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'SOCIAL_T103');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg, i_is_report => 'N');
                o_vc2 := null;
            WHEN 'l_start_dt_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'SOCIAL_T104');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg, i_is_report => 'N');
                o_vc2 := null;
            WHEN 'l_time_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'SOCIAL_T105');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg, i_is_report => 'N');
                o_vc2 := null;
            WHEN 'l_next_dt_enable' THEN
                o_vc2 := pk_paramedical_prof_core.check_hospital_profile(i_prof => l_prof);
            WHEN 'l_next_dt_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'SOCIAL_T154');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg, i_is_report => 'N');
                o_vc2 := null;
            WHEN 'l_canc_rea_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'COMMON_M072');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg);
                o_vc2 := null;
            WHEN 'l_canc_not_title' THEN
                --l_msg := pk_message.get_message(l_lang, l_prof, 'COMMON_M073');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg);
                o_vc2 := null;
            WHEN 'i_episode' THEN
                o_id := l_id_episode;
            WHEN 'i_show_cancelled' THEN
                o_vc2 := 'Y';
            WHEN 'l_opinion_type' THEN
                o_vc2 := pk_paramedical_prof_core.get_id_opinion_type(i_lang    => l_lang,
                                                                      i_prof    => l_prof,
                                                                      i_episode => l_id_episode);
            when 'l_end_followup' then
                --l_msg := pk_message.get_message( l_lang, l_prof, 'PARAMEDICAL_T023');
                --o_vc2 := pk_paramedical_prof_core.format_str_header_w_colon(i_srt => l_msg, i_is_report => 'N');
                o_vc2 := null;
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_par_followup;

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
    ) IS
        g_lang             CONSTANT NUMBER(24) := 1;
        g_prof_id          CONSTANT NUMBER(24) := 2;
        g_prof_institution CONSTANT NUMBER(24) := 3;
        g_prof_software    CONSTANT NUMBER(24) := 4;
        k_pos_episode      CONSTANT NUMBER(24) := 5;
        l_lang             CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_prof             CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                                 i_context_ids(g_prof_institution),
                                                                 i_context_ids(g_prof_software));
        l_msg        VARCHAR2(4000);
        l_id_episode NUMBER := -9999999;
    
        -- ***************************************************
        PROCEDURE set_context IS
        BEGIN
        
            pk_context_api.set_parameter('ID_LANGUAGE', l_lang);
            pk_context_api.set_parameter('PROF_ID', l_prof.id);
            pk_context_api.set_parameter('PROF_ID_INSTITUTION', l_prof.institution);
            pk_context_api.set_parameter('PROF_ID_SOFTWARE', l_prof.software);
            pk_context_api.set_parameter('ID_EPISODE', l_id_episode);
        
        END set_context;
    
    BEGIN
    
        l_id_episode := i_context_ids(k_pos_episode);
        
        set_context();
		
        CASE lower(i_name)
            WHEN 'i_lang' THEN
                o_id := l_lang;
            WHEN 'l_msg_action' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M017') || ':';
            WHEN 'l_msg_order' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M018') || ':';
            WHEN 'l_msg_instr' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M019') || ':';
            WHEN 'l_msg_notes' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M020') || ':';
            WHEN 'l_msg_order_type' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M007');
            WHEN 'l_msg_ordered_by' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M005');
            WHEN 'l_msg_ordered_at' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'CO_SIGN_M027');
            ELSE
                o_vc2  := NULL;
                o_num  := NULL;
                o_id   := NULL;
                o_tstz := NULL;
        END CASE;
    
    END init_par_cosign;

    FUNCTION get_no_show(i_dt IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR2 IS
        l_return VARCHAR2(0050 CHAR) := 'N';
    BEGIN
    
        IF i_dt <= current_timestamp
        THEN
            l_return := 'Y';
        END IF;
    
        RETURN l_return;
    
    END get_no_show;

BEGIN
    inicialize();
END pk_cdoc_filters;
/
