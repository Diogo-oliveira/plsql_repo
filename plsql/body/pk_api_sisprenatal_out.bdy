/*-- Last Change Revision: $Rev: 2026735 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:44 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_api_sisprenatal_out IS

    -- Private variable declarations


    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    -- Function and procedure implementations
    
    /** PRIVATE PROCEDURE
    * Get the profissional object that will be used across the export methods
    *
    * @param   i_institution      institution ID
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   24-11-2011
    */
    PROCEDURE prv_set_profissional(i_institution IN institution.id_institution%TYPE) IS 
    BEGIN
        g_prof := profissional(0, i_institution, g_soft_sisprenatal);
        
    END prv_set_profissional;
    
    /** PRIVATE PROCEDURE
    * Set the session global variables
    *
    * @param   i_name_archive      archive name
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   25-11-2011
    */
    PROCEDURE prv_set_patient_list(i_name_archive IN VARCHAR2, i_pat_list IN t_tab_sisprenatal_pat_list) IS 
    BEGIN
        CASE i_name_archive
          WHEN pk_types_sisprenatal.g_arch_cadgest 
            THEN g_pat_list_cadgest := i_pat_list;
          WHEN pk_types_sisprenatal.g_arch_regcons 
            THEN g_pat_list_regcons := i_pat_list;
          WHEN pk_types_sisprenatal.g_arch_regvac 
            THEN g_pat_list_regvac := i_pat_list;
          WHEN pk_types_sisprenatal.g_arch_regexa 
            THEN g_pat_list_regexa := i_pat_list;
          WHEN pk_types_sisprenatal.g_arch_reginco 
            THEN g_pat_list_reginco := i_pat_list;
          WHEN pk_types_sisprenatal.g_arch_regint 
            THEN g_pat_list_regint := i_pat_list;
            
        END CASE;
    END prv_set_patient_list;
    
    /** PRIVATE PROCEDURE
    * Set the session global variable with the institution ID
    *
    * @param   i_institution      institution ID
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   20-12-2011
    */
    PROCEDURE prv_set_institution_id(i_institution IN institution.id_institution%TYPE) IS 
    BEGIN
        g_institution := i_institution;
    END prv_set_institution_id;

    /**
    * Get the list of patients that will be exported to the archive (both ALERT and SAIS)
    *
    * @param   i_institution               Institution ID
    * @param   i_name_archive              Archive that will use this patient universe: available values are list in the globals g_arch_*
    *
    * @return  patient mapping list
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   15-11-2011
    */
    FUNCTION get_patient_list
    (
        i_institution    IN institution.id_institution%TYPE,
        i_name_archive   IN VARCHAR2
    ) RETURN t_tab_sisprenatal_pat_list IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_PATIENT_LIST';
        l_error     t_error_out;
    
        l_patient       table_number;
        l_pat_pregnancy table_number;
        l_scope         VARCHAR2(1 CHAR);
        l_institution   institution.id_institution%TYPE;
        l_record        t_rec_sisprenatal_pat_list;
        l_pat_list      t_tab_sisprenatal_pat_list;
        l_count         NUMBER := 1;
        
        CURSOR c_pat_list IS
          SELECT pat.id_patient,
                 pk_patient.get_pat_ext_sys(g_lang, g_prof, g_ext_sys_sais, pat.id_patient, g_prof.institution) id_pat_sais,
                 pat_pregn.id_pat_pregnancy
            FROM (SELECT column_value id_patient, rownum nrow
                     FROM TABLE(l_patient)) pat
            JOIN (SELECT column_value id_pat_pregnancy, rownum nrow
                      FROM TABLE(l_pat_pregnancy)) pat_pregn ON pat_pregn.nrow = pat.nrow
           ORDER BY pat.nrow;
    
    BEGIN
        prv_set_profissional(i_institution);
        
        l_pat_list := t_tab_sisprenatal_pat_list();
        
        g_error := 'GET EXPORT SCOPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_name_archive = pk_types_sisprenatal.g_arch_cadgest
        THEN
            l_scope := g_sisprenatal_in;
        ELSIF i_name_archive IN (pk_types_sisprenatal.g_arch_regcons, pk_types_sisprenatal.g_arch_regvac, pk_types_sisprenatal.g_arch_regexa)
        THEN
            -- These archives export all pregnancies regardless of the SISPRENATAL code
            l_scope := NULL;
            l_institution := g_prof.institution;
        ELSIF i_name_archive = pk_types_sisprenatal.g_arch_reginco
        THEN
            l_scope := g_sisprenatal_out;
            l_institution := g_prof.institution;
        ELSIF i_name_archive = pk_types_sisprenatal.g_arch_regint
        THEN
            l_scope := g_sisprenatal_int;
            l_institution := g_prof.institution;
        ELSE
          -- if this export doesnt have scope then the patient list is empty
          RETURN l_pat_list;
        END IF;
        
        g_error := 'CALL TO PK_PREGNANCY_API';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF NOT pk_pregnancy_api.get_pat_sisprenatal(i_lang          => g_lang,
                                                    i_prof          => g_prof,
                                                    i_scope         => l_scope,
                                                    i_institution   => l_institution,
                                                    o_patient       => l_patient,
                                                    o_pat_pregnancy => l_pat_pregnancy,
                                                    o_error         => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'FETCH AND RETURN DATA';
        FOR r_pat_list IN c_pat_list
        LOOP  
            
            IF r_pat_list.id_pat_sais IS NOT NULL
            THEN
              l_record := t_rec_sisprenatal_pat_list(r_pat_list.id_patient, r_pat_list.id_pat_sais, r_pat_list.id_pat_pregnancy);
              
              l_pat_list.EXTEND;
              l_pat_list(l_count) := l_record;
              l_count := l_count + 1;
            END IF;
          
        END LOOP;
        
        -- SET THE GLOBAL VARIABLES THAT WILL BE USED ALONG THE SESSION
        prv_set_patient_list(i_name_archive, l_pat_list);
        prv_set_institution_id(i_institution);
          
        RETURN l_pat_list;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_patient_list;
    
    /**
    * Get the information to save in the CADGES record
    *
    * @return  CADGES information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   18-11-2011
    */
    FUNCTION get_cadges RETURN pk_types_sisprenatal.tb_rec_cadges
        PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_CADGES';
        l_error t_error_out;
    
        l_record pk_types_sisprenatal.rec_cadges;
    
        CURSOR c_cadges IS
            SELECT /*+opt_estimate(table pat rows=10)*/
                   pat.id_pat_alert,
                   pk_pregnancy_api.get_pregn_first_epis(g_lang, g_prof, pat.id_pat_alert, pp.dt_init_pregnancy) id_first_epis,
                   pk_pregnancy_api.get_serialized_code(g_lang, g_prof, pat.id_pat_pregnancy) cod_gest,
                   pk_pregnancy_api.get_dt_lmp_pregn(g_lang, g_prof, pat.id_pat_pregnancy) d_dum,
                   pk_pregnancy_api.get_pregn_dt_first_epis(g_lang, g_prof, pat.id_pat_pregnancy) d_consulta 
              FROM TABLE(g_pat_list_cadgest) pat
              JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy;
    
    BEGIN
    
        prv_set_profissional(g_institution);
    
        g_error := 'GET CADGES RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR r_cadges IN c_cadges
        LOOP
            l_record.id_pat_alert := r_cadges.id_pat_alert;
            l_record.id_epis_sais := pk_episode.get_epis_ext_sys(g_lang, g_prof, g_ext_sys_sais, r_cadges.id_first_epis, g_prof.institution);
            l_record.id_epis_prof := pk_hand_off.get_prof_resp(i_lang          => g_lang,
                                                               i_prof          => g_prof,
                                                               i_episode       => r_cadges.id_first_epis,
                                                               i_flg_type      => pk_hand_off.g_flg_type_d,
                                                               i_hand_off_type => pk_hand_off.g_handoff_normal,
                                                               i_flg_profile   => NULL,
                                                               i_id_speciality => NULL);
            l_record.cod_gest     := r_cadges.cod_gest;
            l_record.d_consulta   := r_cadges.d_consulta;
            l_record.d_dum        := r_cadges.d_dum;
        
            PIPE ROW(l_record);
        
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_cadges;
    
    /**
    * Get the information to save in the REGINCO record
    *
    * @return  REGINCO information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   18-11-2011
    */
    FUNCTION get_reginco RETURN pk_types_sisprenatal.tb_rec_reginco
      PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REGINCO';
        l_error     t_error_out;
        
        l_record  pk_types_sisprenatal.rec_reginco;
        
        CURSOR c_reginco IS 
          SELECT rownum seq, t.*
            FROM (SELECT /*+opt_estimate(table pat rows=10)*/
                         pat.id_pat_alert,
                         pk_pregnancy_api.get_serialized_code(g_lang, g_prof, pat.id_pat_pregnancy) cod_gest,
                         CAST((pk_date_utils.trunc_insttimezone(g_prof, MIN(epis.dt_begin_tstz))) AS DATE) dia_data
                    FROM TABLE(g_pat_list_reginco) pat
                    JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy
                    JOIN episode epis ON epis.id_patient = pat.id_pat_alert
                                     AND epis.id_institution = g_prof.institution
                   WHERE epis.dt_begin_tstz > pp.dt_init_pregnancy
                   GROUP BY pat.id_pat_alert, pat.id_pat_pregnancy) t;
    
    BEGIN
        
        prv_set_profissional(g_institution);
        
        g_error := 'GET REGINCO RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);

        FOR r_reginco IN c_reginco
        LOOP  
            l_record.reginco      := r_reginco.seq;
            l_record.id_pat_alert := r_reginco.id_pat_alert;
            l_record.cod_gest     := r_reginco.cod_gest;
            l_record.dia_data     := r_reginco.dia_data;

          PIPE ROW(l_record);
          
        END LOOP;
          
          RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_reginco;
    
    /**
    * Get the information to save in the REGCONS record
    *
    * @return  REGCONS information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   21-11-2011
    */
    FUNCTION get_regcons RETURN pk_types_sisprenatal.tb_rec_regcons
      PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REGCONS';
        l_error t_error_out;
    
        l_record pk_types_sisprenatal.rec_regcons;
    
        CURSOR c_regcons IS
            SELECT /*+opt_estimate(table pat rows=10)*/
                   rownum seq,
                   pat.id_pat_alert,
                   epis.id_episode,
                   pk_pregnancy_api.get_serialized_code(g_lang, g_prof, pat.id_pat_pregnancy) cod_gest,
                   pk_pregnancy_api.get_pregn_episode_type(g_lang,
                                                           g_prof,
                                                           pp.dt_intervention,
                                                           pp.flg_status,
                                                           epis.dt_begin_tstz,
                                                           epis.dt_end_tstz) cn_cons,
                   pk_pregnancy_api.get_pregn_early_puerperal(g_lang, g_prof, pp.dt_init_pregnancy, pp.dt_intervention) cn_flag,
                   pk_pregnancy_api.get_pregn_inter_type(g_lang, g_prof, pat.id_pat_pregnancy, pp.flg_status) cn_inter,
                   pk_pregnancy_api.get_pregn_gest_risk(g_lang, g_prof, pat.id_pat_alert) cn_arisco,
                   pk_pregnancy_api.get_pregn_location_code(g_lang, g_prof, pp.flg_desc_intervention) cn_tparto,
                   pk_pregnancy_api.get_pregn_birthtype_code(g_lang, g_prof, pp.id_pat_pregnancy) cn_tparto_2,
                   CAST((pk_date_utils.trunc_insttimezone(g_prof, epis.dt_begin_tstz)) AS DATE) dia_data
              FROM TABLE(g_pat_list_regcons) pat
              JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy
              JOIN episode epis ON epis.id_patient = pat.id_pat_alert
                               AND epis.flg_status <> pk_alert_constant.g_cancelled
                               AND epis.dt_begin_tstz > pp.dt_init_pregnancy
                               AND epis.id_institution = g_institution;
    
    BEGIN
    
        prv_set_profissional(g_institution);
        
        g_error := 'GET REGCONS RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR r_regcons IN c_regcons
        LOOP
            l_record.regcons      := r_regcons.seq;
            l_record.id_pat_alert := r_regcons.id_pat_alert;
            l_record.id_epis_sais := pk_episode.get_epis_ext_sys(g_lang, g_prof, g_ext_sys_sais, r_regcons.id_episode, g_prof.institution);
            l_record.id_epis_prof := pk_hand_off.get_prof_resp(i_lang          => g_lang,
                                                               i_prof          => g_prof,
                                                               i_episode       => r_regcons.id_episode,
                                                               i_flg_type      => pk_hand_off.g_flg_type_d,
                                                               i_hand_off_type => pk_hand_off.g_handoff_normal,
                                                               i_flg_profile   => NULL,
                                                               i_id_speciality => NULL);
            l_record.cod_gest     := r_regcons.cod_gest;
            l_record.cn_cons      := r_regcons.cn_cons;
            l_record.cn_flag      := r_regcons.cn_flag;
            l_record.cn_inter     := r_regcons.cn_inter;
            l_record.cn_arisco    := r_regcons.cn_arisco;
            l_record.cn_tparto    := r_regcons.cn_tparto;
            l_record.cn_tparto_2  := r_regcons.cn_tparto_2;
            l_record.dia_data     := r_regcons.dia_data;
            PIPE ROW(l_record);
        
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_regcons;
    
    /**
    * Get the information to save in the REGVAC record
    *
    * @return  REGVAC information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regvac RETURN pk_types_sisprenatal.tb_rec_regvac
      PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REGVAC';
        l_error t_error_out;
    
        l_record      pk_types_sisprenatal.rec_regvac;
        l_def_vacc    CONSTANT VARCHAR2(50) :=  'VACCINE_TETANUS';
        l_def_vc_vaci CONSTANT VARCHAR2(50) :=  'VC_VACI';
    
        CURSOR c_regvac IS
           SELECT rownum seq,
                  id_pat_alert,
                  cod_gest,
                  pk_pregnancy_api.get_pregn_vacc_doses(g_lang,
                                                        g_prof,
                                                        id_pat_alert,
                                                        l_def_vacc,
                                                        l_def_vc_vaci,
                                                        g_vacc_id_code) vc_vaci,
                  vc_dose,
                  dia_data
             FROM (SELECT id_pat_alert,
                          pk_pregnancy_api.get_serialized_code(g_lang, g_prof, id_pat_pregnancy) cod_gest,
                          pk_pregnancy_api.get_pregn_vacc_doses(g_lang,
                                                                g_prof,
                                                                id_pat_alert,
                                                                l_def_vacc,
                                                                l_def_vc_vaci,
                                                                g_vacc_dose_code) vc_dose,
                          CAST((pk_date_utils.trunc_insttimezone(g_prof, dt_epis_begin)) AS DATE) dia_data
                     FROM (SELECT /*+opt_estimate(table pat rows=10)*/
                                  pat.id_pat_alert,
                                  pat.id_pat_pregnancy,
                                  MIN(epis.dt_begin_tstz) dt_epis_begin
                             FROM TABLE(g_pat_list_regvac) pat
                             JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy
                             JOIN episode epis ON epis.id_patient = pat.id_pat_alert
                                                AND epis.id_institution = g_prof.institution
                            WHERE epis.dt_begin_tstz > pp.dt_init_pregnancy
                         GROUP BY pat.id_pat_alert, pat.id_pat_pregnancy)) tab_vac;
    
    BEGIN
    
        prv_set_profissional(g_institution);
        
        g_error := 'GET REGVAC RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR r_regvac IN c_regvac
        LOOP
            l_record.regvac       := r_regvac.seq;
            l_record.id_pat_alert := r_regvac.id_pat_alert;
            l_record.cod_gest     := r_regvac.cod_gest;
            l_record.vc_vaci      := r_regvac.vc_vaci;
            l_record.vc_dose      := r_regvac.vc_dose;
            l_record.dia_data     := r_regvac.dia_data;

            PIPE ROW(l_record);
        
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_regvac;
    
    /**
    * Get the information to save in the REGEXA record
    *
    * @return  REGEXA information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regexa RETURN pk_types_sisprenatal.tb_rec_regexa
      PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REGEXA';
        l_error t_error_out;
    
        l_record     pk_types_sisprenatal.rec_regexa;
        l_tab_map    table_map_lab_tests;
        l_tab_fields table_varchar;
    
        CURSOR c_regexa IS
            SELECT rownum seq,
             id_pat_alert,
             pk_pregnancy_api.get_serialized_code(g_lang, g_prof, id_pat_pregnancy) cod_gest,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(1)).id_contents,
                                                 l_tab_map(l_tab_fields(1)).export_value) ex_abo,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(2)).id_contents,
                                                 l_tab_map(l_tab_fields(2)).export_value) ex_vdrl,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(3)).id_contents,
                                                 l_tab_map(l_tab_fields(3)).export_value) ex_urina,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(4)).id_contents,
                                                 l_tab_map(l_tab_fields(4)).export_value) ex_glice,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(5)).id_contents,
                                                 l_tab_map(l_tab_fields(5)).export_value) ex_hb,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(6)).id_contents,
                                                 l_tab_map(l_tab_fields(6)).export_value) ex_ht,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(7)).id_contents,
                                                 l_tab_map(l_tab_fields(7)).export_value) ex_hiv,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(8)).id_contents,
                                                 l_tab_map(l_tab_fields(8)).export_value) ex_flag1,
             pk_pregnancy_api.get_pregn_lab_code(g_lang,
                                                 g_prof,
                                                 id_pat_alert,
                                                 dt_init_pregnancy,
                                                 l_tab_map(l_tab_fields(9)).id_contents,
                                                 l_tab_map(l_tab_fields(9)).export_value) ex_flag2,
             CAST((pk_date_utils.trunc_insttimezone(g_prof, dt_epis_begin)) AS DATE) dia_data
              FROM (SELECT /*+opt_estimate(table pat rows=10)*/
                           pat.id_pat_alert,
                           pat.id_pat_pregnancy,
                           pp.dt_init_pregnancy,
                           MIN(epis.dt_begin_tstz) dt_epis_begin
                      FROM TABLE(g_pat_list_regexa) pat
                      JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy
                      JOIN episode epis ON epis.id_patient = pat.id_pat_alert
                                       AND epis.id_institution = g_prof.institution
                     WHERE epis.dt_begin_tstz > pp.dt_init_pregnancy
                     GROUP BY pat.id_pat_alert, pat.id_pat_pregnancy, pp.dt_init_pregnancy);
    
    BEGIN
    
        prv_set_profissional(g_institution);
    
        l_tab_fields := table_varchar('EX_ABO',
                                      'EX_VDRL',
                                      'EX_URINA',
                                      'EX_GLICE',
                                      'EX_HB',
                                      'EX_HT',
                                      'EX_HIV',
                                      'EX_FLAG1',
                                      'EX_FLAG2');
    
        g_error := 'GET MAPPING VALUES';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        FOR i IN 1 .. l_tab_fields.COUNT
        LOOP
           IF NOT pk_pregnancy_api.get_pregn_lab_ids(i_lang             => g_lang,
                                                     i_prof             => g_prof,
                                                     i_def_lab          => l_tab_fields(i),
                                                     o_id_contents      => l_tab_map(l_tab_fields(i)).id_contents,
                                                     o_code_sisprenatal => l_tab_map(l_tab_fields(i)).export_value,
                                                     o_error            => l_error)
           THEN
               RAISE g_exception;
           END IF;
           
        END LOOP;
    
        g_error := 'GET REGEXA RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR r_regexa IN c_regexa
        LOOP
            l_record.regexa       := r_regexa.seq;
            l_record.id_pat_alert := r_regexa.id_pat_alert;
            l_record.cod_gest     := r_regexa.cod_gest;
            --
            l_record.ex_abo   := r_regexa.ex_abo;
            l_record.ex_vdrl  := r_regexa.ex_vdrl;
            l_record.ex_urina := r_regexa.ex_urina;
            l_record.ex_glice := r_regexa.ex_glice;
            l_record.ex_hb    := r_regexa.ex_hb;
            l_record.ex_ht    := r_regexa.ex_ht;
            l_record.ex_hiv   := r_regexa.ex_hiv;
            l_record.ex_flag1 := r_regexa.ex_flag1;
            l_record.ex_flag2 := r_regexa.ex_flag2;
            l_record.dia_data := r_regexa.dia_data;
        
            PIPE ROW(l_record);
        
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_regexa;
    
    /**
    * Get the information to save in the REGINT record
    *
    * @return  REGINT information (pipelined)
    *
    * @author  JOSE.SILVA
    * @version 2.5.1.9
    * @since   22-11-2011
    */
    FUNCTION get_regint RETURN pk_types_sisprenatal.tb_rec_regint
      PIPELINED IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REGINT';
        l_error t_error_out;
    
        l_record pk_types_sisprenatal.rec_regint;
    
        CURSOR c_regint IS
            SELECT /*+opt_estimate(table pat rows=10)*/
             rownum seq,
             pat.id_pat_alert,
             epis.id_episode,
             pk_pregnancy_api.get_serialized_code(g_lang, g_prof, pat.id_pat_pregnancy) cod_gest,
             pk_pregnancy_api.get_pregn_dt_first_epis(g_lang, g_prof, pat.id_pat_pregnancy) d_consulta,
             pk_pregnancy_api.get_pregn_dt_last_epis(g_lang, g_prof, pat.id_pat_pregnancy) d_consulta_ultima,
             pk_pregnancy_api.get_dt_lmp_pregn(g_lang, g_prof, pat.id_pat_pregnancy) d_dum,
             pk_pregnancy_api.get_pregn_episode_type(g_lang,
                                                     g_prof,
                                                     pp.dt_intervention,
                                                     pp.flg_status,
                                                     epis.dt_begin_tstz,
                                                     epis.dt_end_tstz) cn_cons,
             pk_pregnancy_api.get_pregn_inter_type(g_lang, g_prof, pat.id_pat_pregnancy, pp.flg_status) cn_inter,
             pp.dt_intervention d_inter
              FROM TABLE(g_pat_list_regint) pat
              JOIN pat_pregnancy pp ON pp.id_pat_pregnancy = pat.id_pat_pregnancy
              JOIN episode epis ON epis.id_patient = pat.id_pat_alert
                               AND epis.flg_status <> pk_alert_constant.g_cancelled
                               AND epis.dt_begin_tstz > pp.dt_intervention
                               AND epis.id_institution = g_institution;
    
    BEGIN
    
        prv_set_profissional(g_institution);
    
        g_error := 'GET REGINT RECORD';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
    
        FOR r_regint IN c_regint
        LOOP
            l_record.regint       := r_regint.seq;
            l_record.id_pat_alert := r_regint.id_pat_alert;
            l_record.id_epis_sais := pk_episode.get_epis_ext_sys(g_lang, g_prof, g_ext_sys_sais, r_regint.id_episode, g_prof.institution);
            l_record.id_epis_prof := pk_hand_off.get_prof_resp(i_lang          => g_lang,
                                                               i_prof          => g_prof,
                                                               i_episode       => r_regint.id_episode,
                                                               i_flg_type      => pk_hand_off.g_flg_type_d,
                                                               i_hand_off_type => pk_hand_off.g_handoff_normal,
                                                               i_flg_profile   => NULL,
                                                               i_id_speciality => NULL);
            l_record.cod_gest     := r_regint.cod_gest;
            --
            l_record.d_consulta        := r_regint.d_consulta;
            l_record.d_consulta_ultima := r_regint.d_consulta_ultima;
            l_record.d_dum             := r_regint.d_dum;
            l_record.cn_cons           := r_regint.cn_cons;
            l_record.cn_inter          := r_regint.cn_inter;
            l_record.d_inter           := CAST((pk_date_utils.trunc_insttimezone(g_prof, r_regint.d_inter)) AS DATE);
        
            PIPE ROW(l_record);
        
        END LOOP;
    
        RETURN;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => g_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => l_error);
            raise_application_error(-20001, 'Error in function ' || l_func_name || '. Log ID: ' || l_error.log_id);
    END get_regint;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);
END pk_api_sisprenatal_out;
/
