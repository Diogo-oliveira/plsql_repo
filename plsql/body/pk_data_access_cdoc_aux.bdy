CREATE OR REPLACE PACKAGE BODY pk_data_access_cdoc_aux IS

    FUNCTION get_cols_inp_base RETURN table_varchar IS
        tbl_columns table_varchar := table_varchar(q'[select]',
                                                   q'[ t_rec_data_inpatient_base(]',
                                                   q'[  id_institution     => xsql.id_institution]',
                                                   q'[,id_software            => ( select pk_data_access_cdoc.get_soft_by_epis_type( xsql.id_epis_type, xsql.id_institution ) from dual )]',
                                                   q'[, id_episode     => xsql.id_episode]',
                                                   q'[, id_prev_episode     => xsql.id_prev_episode]',
                                                   q'[, id_prev_epis_type     => xsql.id_prev_epis_type]',
                                                   q'[, id_prof_discharge    => xsql.id_prof_med  ]',
                                                   q'[, dt_epis_dt_begin_tstz => xsql.dt_epis_begin_tstz ]',
                                                   q'[, dt_vis_dt_begin_tstz  => xsql.dt_vis_begin_tstz ]',
                                                   q'[, dt_discharge     => xsql.dt_med_tstz]',
                                                   q'[, dt_discharge_pend  => xsql.dt_pend_tstz]',
                                                   q'[, dis_flg_status     => xsql.dis_flg_status]',
                                                   q'[, id_discharge_destination     => xsql.id_disch_reas_dest]',
                                                   q'[, id_habit       => null]',
                                                   q'[, id_patient     => xsql.id_patient]',
                                                   -- first treating service
                                                   q'[, id_first_dep_clin_serv => xsql.id_first_dep_clin_serv]',
                                                   q'[, id_department_f        => xsql.id_department_f]',
                                                   q'[, code_department_f      => xsql.code_department_f]',
                                                   q'[, id_clinical_service_f  => xsql.id_clinical_service_f]',
                                                   q'[, code_clinical_service_f=> xsql.code_clinical_service_f]',
                                                   -- current treating service
                                                   q'[, id_dep_clin_serv       => xsql.id_dep_clin_serv]',
                                                   q'[, id_department_c        => xsql.id_department_c]',
                                                   q'[, code_department_c      => xsql.code_department_c]',
                                                   q'[, id_clinical_service_c  => xsql.id_clinical_service_c]',
                                                   q'[, code_clinical_service_c=> xsql.code_clinical_service_c]',
                                                   -- instant localization
                                                   q'[, id_department_now     => xsql.id_department_now]',
                                                   q'[, code_department_now   => xsql.code_department_now]',
                                                   q'[, id_room_now           => xsql.id_room_now]',
                                                   q'[, code_room_now         => xsql.code_room_now]',
                                                   -- bed localization
                                                   q'[, id_bed_alloc          => xsql.id_bed_alloc]',
                                                   q'[, code_bed_alloc        => xsql.code_bed_alloc]',
                                                   q'[, id_room_alloc         => xsql.id_room_alloc]',
                                                   q'[, code_room_alloc       => xsql.code_room_alloc]',
                                                   q'[, id_department_alloc   => xsql.id_department_alloc]',
                                                   q'[, code_department_alloc => xsql.code_department_alloc]',
                                                   --
                                                   q'[, DT_LAST_UPDATE_TSTZ   => coalesce( xsql.update_time, xsql.create_time) ]',
                                                   q'[, flg_ehr       => xsql.flg_ehr]',
                                                   q'[)]');
    BEGIN
        RETURN tbl_columns;
    END get_cols_inp_base;

    FUNCTION get_from_inp_base RETURN table_varchar IS
        tbl_from table_varchar := table_varchar(q'[from ( ]',
                                                q'[select ]',
                                                q'[e.id_episode, ]',
                                                q'[e.id_institution, ]',
                                                q'[e.id_epis_type, ]',
                                                q'[e.id_prev_episode, ]',
                                                q'[e.id_prof_med, ]',
                                                q'[e_prev.id_epis_type id_prev_epis_type, ]',
                                                q'[e.dt_epis_begin_tstz, ]',
                                                q'[e.dt_vis_begin_tstz, ]',
                                                q'[e.dt_med_tstz, ]',
                                                q'[e.dt_pend_tstz, ]',
                                                q'[e.dis_flg_status, ]',
                                                q'[e.id_disch_reas_dest,]',
                                                q'[e.id_patient,]',
                                                q'[e.update_time,]',
                                                q'[e.create_time,]',
                                                -- first treating service
                                                q'[ei.id_first_dep_clin_serv,]',
                                                q'[d_f.id_department id_department_f,]',
                                                q'[d_f.code_department code_department_f,]',
                                                q'[cs_f.id_clinical_service id_clinical_service_f,]',
                                                q'[cs_f.code_clinical_service code_clinical_service_f,]',
                                                -- current treating service
                                                q'[ei.id_dep_clin_serv,]',
                                                q'[d_c.id_department id_department_c,]',
                                                q'[d_c.code_department code_department_c,]',
                                                q'[cs_c.id_clinical_service id_clinical_service_c,]',
                                                q'[cs_c.code_clinical_service code_clinical_service_c,]',
                                                -- instant localization
                                                q'[d_now.id_department id_department_now,]',
                                                q'[d_now.code_department code_department_now,]',
                                                q'[r_now.id_room id_room_now,]',
                                                q'[r_now.code_room code_room_now,]',
                                                -- bed localization
                                                q'[b_alloc.id_bed id_bed_alloc,]',
                                                q'[b_alloc.code_bed code_bed_alloc,]',
                                                q'[r_alloc.id_room id_room_alloc,]',
                                                q'[r_alloc.code_room code_room_alloc,]',
                                                q'[d_alloc.id_department id_department_alloc,]',
                                                q'[d_alloc.code_department code_department_alloc,]',
                                                q'[e.flg_ehr ]',
                                                q'[from (]',
                                                q'[  select ]',
                                                q'[  e1.id_episode, ]',
                                                q'[  e1.id_visit,]',
                                                q'[  v1.id_institution, ]',
                                                q'[  e1.id_epis_type, ]',
                                                q'[  e1.id_prev_episode, ]',
                                                q'[  dis.id_prof_med, ]',
                                                q'[  e1.dt_begin_tstz dt_epis_begin_tstz, ]',
                                                q'[  v1.dt_begin_tstz dt_vis_begin_tstz, ]',
                                                q'[  dis.dt_med_tstz, ]',
                                                q'[  dis.dt_pend_tstz, ]',
                                                q'[  dis.flg_status dis_flg_status, ]',
                                                q'[  dis.id_disch_reas_dest,]',
                                                q'[  v1.id_patient,]',
                                                q'[  e1.update_time,]',
                                                q'[  e1.create_time, ]',
                                                q'[  e1.flg_ehr ]',
                                                q'[  from episode e1]',
                                                q'[  join visit v1 on v1.id_visit = e1.id_visit]',
                                                q'[  join discharge dis on dis.id_episode = e1.id_episode and dis.flg_status != 'C']',
                                                q'[  where e1.id_epis_type = 5]',
                                                --q'[  and v1.id_institution = :i_institution]',
                                                q'[  and dis.dt_med_tstz between :l_dt_ini and :l_dt_end]',
                                                q'[  and e1.flg_status not in ( 'C') ]',
                                                q'[  and e1.flg_ehr not in ( 'E') ]',
                                                q'[  union all]',
                                                q'[  select ]',
                                                q'[  e2.id_episode, ]',
                                                q'[  e2.id_visit,]',
                                                q'[  v2.id_institution, ]',
                                                q'[  e2.id_epis_type, ]',
                                                q'[  e2.id_prev_episode, ]',
                                                q'[  null id_prof_med, ]',
                                                q'[  e2.dt_begin_tstz dt_epis_begin_tstz, ]',
                                                q'[  v2.dt_begin_tstz dt_vis_begin_tstz, ]',
                                                q'[  null dt_med_tstz, ]',
                                                q'[  null dt_pend_tstz, ]',
                                                q'[  null dis_flg_status, ]',
                                                q'[  null id_disch_reas_dest,]',
                                                q'[  v2.id_patient,]',
                                                q'[  e2.update_time,]',
                                                q'[  e2.create_time,]',
                                                q'[ e2.flg_ehr]',
                                                q'[  from episode e2]',
                                                q'[  join visit v2 on v2.id_visit = e2.id_visit]',
                                                q'[  where e2.id_epis_type = 5]',
                                                q'[  and e2.flg_status = 'A']',
                                                q'[  and e2.flg_ehr not in ( 'E') ]',
                                                q'[  and not exists ( select 1 from discharge dx where dx.id_episode = e2.id_episode and dx.flg_status != 'C' )]',
                                                --q'[  and v2.id_institution = :i_institution]',
                                                q'[  ) e]',
                                                q'[join epis_info ei on ei.id_episode = e.id_episode]',
                                                q'[left join episode e_prev on e_prev.id_episode = e.id_prev_episode]',
                                                -- instant localization
                                                q'[left join room r_now on r_now.id_room = ei.id_room]',
                                                q'[left join department d_now on d_now.id_department = r_now.id_department]',
                                                -- bed localization
                                                q'[left join bed b_alloc on b_alloc.id_bed = ei.id_bed]',
                                                q'[left join room r_alloc on r_alloc.id_room = b_alloc.id_room]',
                                                q'[left join department d_alloc on d_alloc.id_department = r_alloc.id_department]',
                                                -- current treating service
                                                q'[join dep_clin_serv dcs_c on ei.id_dep_clin_serv = dcs_c.id_dep_clin_serv]',
                                                q'[join department d_c on d_c.id_department = dcs_c.id_department]',
                                                q'[join clinical_service cs_c on cs_c.id_clinical_service = dcs_c.id_clinical_service]',
                                                -- first treating service
                                                q'[join dep_clin_serv dcs_f on ei.id_first_dep_clin_serv = dcs_f.id_dep_clin_serv]',
                                                q'[join department d_f on d_f.id_department = dcs_f.id_department]',
                                                q'[join clinical_service cs_f on cs_f.id_clinical_service = dcs_f.id_clinical_service]',
                                                q'[) xsql]');
    BEGIN
        RETURN tbl_from;
    END get_from_inp_base;

    --*********************************************
    PROCEDURE print_sql(i_tbl IN table_varchar) IS
    BEGIN
    
        FOR i IN 1 .. i_tbl.count
        LOOP
        
            dbms_output.put_line(i_tbl(i));
        
        END LOOP;
    
    END print_sql;

    --*********************************************
    PROCEDURE print_cols_inp_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_inp_base();
        print_sql(tbl_sql);
    END print_cols_inp_base;

    --*********************************************
    PROCEDURE print_from_inp_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_from_inp_base();
        print_sql(tbl_sql);
    END print_from_inp_base;
    --*********************************************
    PROCEDURE print_all_inp_base IS
    BEGIN
        print_cols_inp_base();
        print_from_inp_base();
    END print_all_inp_base;

    --******************************************
    FUNCTION get_cols_outp_base RETURN table_varchar IS
        tbl_columns table_varchar := table_varchar('SELECT',
                                                   'T_REC_DATA_OUTPATIENT_BASE(',
                                                   'id_institution        => i.id_institution,',
                                                   'code_institution      => i.code_institution,',
                                                   'so_flg_state          => so.flg_state,',
                                                   'flg_sched             => so.flg_sched,',
                                                   'flg_ehr               => e.flg_ehr,',
                                                   'id_epis_type          => e.id_epis_type,',
                                                   'dis_flg_status        => dis.flg_status,',
                                                   'dis_dt_pend_tstz      => dis.dt_pend_tstz,',
                                                   'dis_flg_type          => dis.flg_type,',
                                                   'flg_contact_type      => sg.flg_contact_type,',
                                                   'id_patient            => v.id_patient,',
                                                   'id_episode            => e.id_episode,',
                                                   'patient_complaint     => ec.patient_complaint,',
                                                   'code_complaint        => c.code_complaint,',
                                                   'ei_id_professional    => ei.id_professional,',
                                                   'ps_id_professional    => ps.id_professional,',
                                                   'id_prof_discharge     => dis.id_prof_med,',
                                                   'dt_discharge          => dis.dt_med_tstz,',
                                                   'dt_examinat           => ei.dt_init,',
                                                   'dt_visit              => so.dt_target_tstz,',
                                                   'appointment_type      => se.id_sch_event,',
                                                   'appointment_type_code => se.code_sch_event,',
                                                   'discharge_destination => drd.id_discharge_dest,',
                                                   'discharge_status      => ddh.flg_pat_condition,',
                                                   'clinical_service      => ei.id_dep_clin_serv,',
                                                   'dt_first_obs          => ei.dt_first_obs_tstz,',
                                                   'dt_last_update_tstz   => coalesce( e.update_time, e.create_time)',
                                                   ')');
    BEGIN
        RETURN tbl_columns;
    END get_cols_outp_base;

    --****************************************
    FUNCTION get_from_outp_base RETURN table_varchar IS
        tbl_from table_varchar := table_varchar(q'[FROM schedule_outp so]',
                                                q'[JOIN schedule s ON s.id_schedule =so.id_schedule  and s.flg_status NOT IN ('C', 'D', 'V')]',
                                                q'[join epis_info ei on ei.id_schedule=so.id_schedule and ei.id_software= so.id_software]',
                                                q'[join episode e ON ei.id_episode = e.id_episode]',
                                                q'[JOIN visit v ON v.id_visit = e.id_visit]',
                                                q'[JOIN sch_group sg ON sg.id_schedule = s.id_schedule and sg.id_patient = v.id_patient]',
                                                q'[JOIN institution i ON i.id_institution = v.id_institution]',
                                                q'[JOIN sch_event se ON s.id_sch_event = se.id_sch_event]',
                                                q'[LEFT JOIN sch_prof_outp ps ON ps.id_schedule_outp = so.id_schedule_outp]',
                                                q'[LEFT JOIN epis_complaint ec ON ec.id_episode = e.id_episode]',
                                                q'[LEFT JOIN complaint c ON c.id_complaint = ec.id_complaint]',
                                                q'[LEFT JOIN discharge dis ON dis.id_episode = e.id_episode AND dis.flg_status != 'C']',
                                                q'[LEFT JOIN discharge_detail_hist ddh ON dis.id_discharge = ddh.id_discharge]',
                                                q'[LEFT JOIN disch_reas_dest drd ON drd.id_disch_reas_dest = dis.id_disch_reas_dest]');
    BEGIN
        RETURN tbl_from;
    END get_from_outp_base;

    --*********************************************
    PROCEDURE print_cols_outp_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_outp_base();
        print_sql(tbl_sql);
    END print_cols_outp_base;

    --*********************************************
    PROCEDURE print_from_outp_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_outp_base();
        print_sql(tbl_sql);
    END print_from_outp_base;

    --*********************************************
    PROCEDURE print_all_outp_base IS
    BEGIN
        print_cols_inp_base();
        print_from_inp_base();
    END print_all_outp_base;

    FUNCTION get_cols_edis_base RETURN table_varchar IS
        tbl_columns table_varchar := table_varchar(q'[select]',
                                                   q'[t_rec_data_emergency_base(]',
                                                   q'[ id_institution         => v.id_institution]',
                                                   q'[,id_patient             => v.id_patient]',
                                                   q'[,id_episode             => e.id_episode]',
                                                   q'[,id_next_episode        => ex.id_episode]',
                                                   q'[,flg_status             => e.flg_status]',
                                                   q'[,dt_discharge           => dis.dt_med_tstz]',
                                                   --************************
                                                   q'[,dis_flg_status         => dis.flg_status]',
                                                   q'[,dis_flg_type           => dis.flg_type]',
                                                   q'[,dis_dt_pend_tstz       => dis.dt_pend_tstz]',
                                                   --***********************
                                                   q'[,dt_examination         => ei.dt_first_obs_tstz]',
                                                   q'[,dt_triage              => e.dt_end_tstz]',
                                                   q'[,dt_visit               => v.dt_begin_tstz]',
                                                   q'[,arrival_method         => eadt.id_transp_entity]',
                                                   q'[,discharge_destination  => drd.id_discharge_dest]',
                                                   q'[,discharge_status       => disd.flg_pat_condition]',
                                                   q'[,id_prof_discharge      => dis.id_prof_med]',
                                                   q'[,id_habit               => null]',
                                                   q'[,id_epis_triage         => e.id_epis_triage]',
                                                   q'[,code_triage_color      => tc.code_triage_color]',
                                                   q'[,flg_type               => tcg.flg_type]',
                                                   q'[,code_accuity           => tc.code_accuity]',
                                                   q'[,id_triage_type         => tc.id_triage_type]',
                                                   q'[,id_triage_color        => tc_orig.id_triage_color]',
                                                   q'[,id_epis_triage_first   => e2.id_epis_triage]',
                                                   q'[,code_triage_color_first => tc2.code_triage_color]',
                                                   q'[,flg_type_first          => tcg2.flg_type]',
                                                   q'[,code_accuity_first     => tc2.code_accuity]',
                                                   q'[,id_triage_type_first   => tc2.id_triage_type]',
                                                   q'[,id_triage_color_first  => tc_orig2.id_triage_color]',
                                                   q'[,id_software            => ( select pk_data_access_cdoc.get_soft_by_epis_type( e.id_epis_type, v.id_institution ) from dual )]',
                                                   q'[,patient_complaint      => null]',
                                                   q'[,code_complaint         => null]',
                                                   q'[,dt_complaint           => null]',
                                                   q'[,dt_last_update_tstz    => coalesce( e.update_time, e.create_time)]',
                                                   q'[)]');
    
    BEGIN
        RETURN tbl_columns;
    END get_cols_edis_base;

    FUNCTION get_from_edis_base RETURN table_varchar IS
        tbl_from table_varchar := table_varchar(q'[from epis_info ei]',
                                                q'[join ( ]',
                                                q'[select ]',
                                                q'[  ee1.id_episode]',
                                                q'[, ee1.id_visit]',
                                                q'[, ee1.flg_status]',
                                                q'[, ee1.id_epis_type]',
                                                q'[, ee1.update_time]',
                                                q'[, ee1.create_time]',
                                                q'[, ee1.dt_begin_tstz]',
                                                q'[, et1.dt_end_tstz]',
                                                q'[, et1.id_epis_triage]',
                                                q'[, et1.id_triage_color]',
                                                q'[, et1.id_triage_color_orig]',
                                                q'[,row_number() over(partition by ee1.id_episode order by et1.dt_end_tstz desc ) rn]',
                                                q'[from episode ee1]',
                                                q'[left join epis_triage et1 on et1.id_episode = ee1.id_episode]',
                                                q'[where ee1.id_epis_type = 2]',
                                                q'[and ee1.flg_status != 'C']',
                                                q'[and ee1.dt_begin_tstz between :l_dt_ini and :l_dt_end]',
                                                q'[) e on e.id_episode = ei.id_episode and e.rn = 1]',
                                                --*********************
                                                q'[join ( select ]',
                                                q'[  ee2.id_episode]',
                                                q'[, ee2.id_visit]',
                                                q'[, ee2.flg_status]',
                                                q'[, ee2.id_epis_type]',
                                                q'[, ee2.update_time]',
                                                q'[, ee2.create_time]',
                                                q'[, ee2.dt_begin_tstz]',
                                                q'[, et2.dt_end_tstz]',
                                                q'[, et2.id_epis_triage]',
                                                q'[, et2.id_triage_color]',
                                                q'[, et2.id_triage_color_orig]',
                                                q'[,row_number() over(partition by ee2.id_episode order by et2.dt_end_tstz asc ) rn2]',
                                                q'[from episode ee2]',
                                                q'[left join epis_triage et2 on et2.id_episode = ee2.id_episode]',
                                                q'[where ee2.id_epis_type = 2]',
                                                q'[and ee2.flg_status != 'C']',
                                                q'[and ee2.dt_begin_tstz between :l_dt_ini and :l_dt_end]',
                                                q'[) e2 on e2.id_episode = e.id_episode and e2.rn2 = 1]',
                                                --***************************************************
                                                q'[join visit v on v.id_visit = e.id_visit]',
                                                q'[left join episode_adt eadt on eadt.id_episode = e.id_episode]',
                                                q'[left join admission_adt adt on adt.id_episode_adt = eadt.id_episode_adt]',
                                                q'[left join admission_edis eadt on eadt.id_admission_edis = adt.id_admission_adt]',
                                                q'[left join episode ex on ex.id_prev_episode = e.id_episode and ex.id_visit = e.id_visit and ex.id_epis_type =5]',
                                                q'[left join triage_color tc on tc.id_triage_color = e.id_triage_color]',
                                                q'[left JOIN triage_color_group tcg ON tcg.id_triage_color_group = tc.id_triage_color_group]',
                                                --************
                                                q'[left join triage_color tc2 on tc2.id_triage_color = e2.id_triage_color]',
                                                q'[left JOIN triage_color_group tcg2 ON tcg2.id_triage_color_group = tc2.id_triage_color_group]',
                                                --***************
                                                q'[left join discharge dis on dis.id_episode = e.id_episode and dis.flg_status != 'C']',
                                                q'[left join discharge_detail disd on disd.id_discharge = dis.id_discharge]',
                                                q'[left join disch_reas_dest drd on drd.id_disch_reas_dest = dis.id_disch_reas_dest]',
                                                q'[LEFT JOIN triage_color tc_orig ON tc_orig.id_triage_color = e.id_triage_color_orig]',
                                                q'[LEFT JOIN triage_color tc_orig2 ON tc_orig2.id_triage_color = e2.id_triage_color_orig]');
    
    BEGIN
        RETURN tbl_from;
    END get_from_edis_base;

    --*********************************************
    PROCEDURE print_cols_edis_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_edis_base();
        print_sql(tbl_sql);
    END print_cols_edis_base;

    --*********************************************
    PROCEDURE print_from_edis_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_edis_base();
        print_sql(tbl_sql);
    END print_from_edis_base;

    --*********************************************
    PROCEDURE print_all_edis_base IS
    BEGIN
        print_cols_edis_base();
        print_from_edis_base();
    END print_all_edis_base;

    FUNCTION get_cols_consult_base RETURN table_varchar IS
        tbl_cols table_varchar := table_varchar(q'[select t_rec_data_consult_base(]',
                                                q'[ ID_OPINION       => op.ID_OPINION    ]',
                                                q'[,ID_EPISODE             => op.ID_EPISODE         ]',
                                                q'[,ID_EPIS_TYPE           => ee.ID_EPIS_TYPE       ]',
                                                q'[,ID_INSTITUTION         => vi.ID_INSTITUTION     ]',
                                                q'[,FLG_STATE              => op.FLG_STATE          ]',
                                                q'[,ID_PROF_QUESTIONS      => op.ID_PROF_QUESTIONS  ]',
                                                q'[,ID_PROF_QUESTIONED     => op.ID_PROF_QUESTIONED ]',
                                                q'[,ID_SPECIALITY          => op.ID_SPECIALITY      ]',
                                                q'[,DT_PROBLEM_TSTZ        => op.DT_PROBLEM_TSTZ    ]',
                                                q'[,DT_CANCEL_TSTZ         => op.DT_CANCEL_TSTZ     ]',
                                                q'[,STATUS_FLG             => op.STATUS_FLG         ]',
                                                q'[,FLG_TYPE               => op.FLG_TYPE           ]',
                                                q'[,ID_CANCEL_REASON       => op.ID_CANCEL_REASON   ]',
                                                q'[,ID_PATIENT             => op.ID_PATIENT         ]',
                                                q'[,ID_OPINION_TYPE        => op.ID_OPINION_TYPE    ]',
                                                q'[,ID_CLINICAL_SERVICE    => op.ID_CLINICAL_SERVICE]',
                                                q'[,DT_APPROVED            => op.DT_APPROVED        ]',
                                                q'[,ID_PROF_APPROVED       => op.ID_PROF_APPROVED   ]',
                                                q'[,FLG_AUTO_FOLLOW_UP     => op.FLG_AUTO_FOLLOW_UP ]',
                                                q'[,ID_PROF_CANCEL         => op.ID_PROF_CANCEL     ]',
                                                q'[,FLG_PRIORITY           => op.FLG_PRIORITY       ]',
                                                q'[)]');
    BEGIN
        RETURN tbl_cols;
    END get_cols_consult_base;

    --********************************************
    FUNCTION get_from_consult_base RETURN table_varchar IS
        tbl_from table_varchar := table_varchar(q'[from opinion op]',
                                                q'[join episode ee on ee.id_episode = op.id_episode]',
                                                q'[join visit vi on vi.id_visit = ee.id_visit]',
                                                q'[where op.flg_state != 'C']',
                                                q'[and op.dt_problem_tstz between :l_dt_ini and :l_dt_end]',
                                                q'[and op.id_opinion_type is null]');
    BEGIN
        RETURN tbl_from;
    END get_from_consult_base;

    --**************************************
    PROCEDURE print_cols_consult_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_consult_base();
        print_sql(tbl_sql);
    END print_cols_consult_base;

    --**************************************
    PROCEDURE print_from_consult_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_from_consult_base();
        print_sql(tbl_sql);
    END print_from_consult_base;

    --*********************************************
    PROCEDURE print_all_consult_base IS
    BEGIN
        print_cols_consult_base();
        print_from_consult_base();
    END print_all_consult_base;

    FUNCTION get_cols_transfer_base RETURN table_varchar IS
        tbl_cols table_varchar := table_varchar(q'[select t_rec_data_transfer_base(]',
                                                q'[ id_institution       => v.id_institution]',
                                                q'[,id_episode               => epr.id_episode]',
                                                q'[,id_prof_req              => epr.id_prof_req]',
                                                q'[,dt_request_tstz          => epr.dt_request_tstz]',
                                                q'[,flg_type                 => epr.flg_type]',
                                                q'[,flg_status               => epr.flg_status]',
                                                q'[,id_clinical_service_orig => epr.id_clinical_service_orig]',
                                                q'[,id_department_orig       => epr.id_department_orig]',
                                                q'[)]');
    BEGIN
        RETURN tbl_cols;
    END get_cols_transfer_base;

    --********************************************
    FUNCTION get_from_transfer_base RETURN table_varchar IS
        tbl_from table_varchar := table_varchar(q'[from epis_prof_resp epr]',
                                                q'[join episode e on e.id_episode = epr.id_episode]',
                                                q'[join visit v on v.id_visit = e.id_visit]',
                                                q'[join clinical_service cs on cs.id_clinical_service = epr.id_clinical_service_orig]',
                                                q'[where epr.flg_transf_type = 'S']',
                                                q'[and epr.flg_status not in ( 'X', 'C' )]',
                                                q'[AND e.flg_ehr = 'N']',
                                                q'[and e.id_epis_type = 5]',
                                                q'[and epr.dt_request_tstz between :l_dt_ini and :l_dt_end]'
                                                --,q'[and v.id_institution = :l_id_institution]'
                                                );
    BEGIN
        RETURN tbl_from;
    END get_from_transfer_base;

    --**************************************
    PROCEDURE print_cols_transfer_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_cols_transfer_base();
        print_sql(tbl_sql);
    END print_cols_transfer_base;

    --**************************************
    PROCEDURE print_from_transfer_base IS
        tbl_sql table_varchar := table_varchar();
    BEGIN
        tbl_sql := get_from_transfer_base();
        print_sql(tbl_sql);
    END print_from_transfer_base;

    --*********************************************
    PROCEDURE print_all_transfer_base IS
    BEGIN
        print_cols_transfer_base();
        print_from_transfer_base();
    END print_all_transfer_base;

END pk_data_access_cdoc_aux;
