/*-- Last Change Revision: $Rev: 2027276 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:43 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_search AS
    /******************************************************************************
       NAME:       PK_INP_SEARCH
       PURPOSE:
    
       REVISIONS:
       Ver        Date        Author           Description
       ---------  ----------  ---------------  ------------------------------------
       1.0        08-11-2006             1. Created this package body.
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal clínico (médicos e enfermeiros)
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
               I_CRIT_VAL - Lista de valores dos critérios de pesquisa
             I_INSTIT - Instituição
             I_EPIS_TYPE - Tipo de consulta
             I_DT - Data a pesquisar. Se for null assume a data de sistema
               I_PROF - ID do profissional q regista
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                Saida:   O_PAT - Doentes activos
                 O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
             O_ERROR - Erro
    
      CRIAÇÃO: SS 2006/11/08
      NOTAS: Igual à função do PK_EDIS_PROC mas sem EPIS_ANAMNESIS, EDIS_TRIAGE e TRIAGE_COLOR mas com BED e ROOM
    
    ******************************************************************************/

    FUNCTION get_pat_criteria_active_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(32000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(50);
        --
        l_ret      BOOLEAN;
        l_prof_cat category.flg_type%TYPE;
    
        CURSOR c_prof_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
    
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
    
    BEGIN
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_inp_grid.g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        xpl     := '''';
        g_error := 'INICIO:';
    
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        g_error := 'L_LIMIT:';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof  := 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')';
    
        g_error := 'GET PROF CAT';
        OPEN c_prof_cat;
        FETCH c_prof_cat
            INTO l_prof_cat;
        CLOSE c_prof_cat;
    
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
            
                g_error := 'GET CRITERIA CONDITION:';
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        -- JS, 2007-09-07 - Timezone
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                g_error := 'SET L_WHERE';
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'SET WHERE 2';
        id_doc  := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext  := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        --
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || ' FROM EPISODE EPIS, EPIS_INFO EI,PATIENT PAT, DISCHARGE D, ' ||
                   'CLIN_RECORD CR, DEPARTMENT DPT, CLINICAL_SERVICE CS, ' || 'PROFESSIONAL P, ' ||
                   'EPIS_EXT_SYS EES, PAT_SOC_ATTRIBUTES PSA , PAT_DOC PD ' ||
                   ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE(+) ' ||
                   ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' || ' AND EI.ID_SOFTWARE= :1 ' ||
                   ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE ' ||
                   ' AND EPIS.ID_INSTITUTION=:2 ' || ' AND EPIS.ID_PATIENT=PAT.ID_PATIENT  ' ||
                   ' AND EPIS.ID_DEPARTMENT = DPT.ID_DEPARTMENT ' || ' AND EPIS.FLG_EHR IN (''N'') ' ||
                   ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || ' AND D.FLG_STATUS (+)<>''' ||
                   pk_discharge_core.g_disch_status_cancel || '''' || ' AND D.FLG_STATUS (+)<>''' ||
                   pk_discharge_core.g_disch_status_reopen || '''' || --
                   ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' ||
                  --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
                   ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' ||
                   ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION(+) = :3 ' ||
                   ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT ' || ' AND CR.ID_INSTITUTION(+) =:4 ' ||
                   ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || ' AND EES.ID_EXTERNAL_SYS(+) = :5 ' ||
                   ' AND EES.ID_INSTITUTION(+) = :6 ' || ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT  ' ||
                   ' AND PD.ID_DOC_TYPE(+) = :7 ' --
                   || l_where;
    
        --
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.software, i_prof.institution, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT to_char(rownum, ''00000'') serv_rank,' || chr(32) || 'wnd.* ' || chr(32) || 'FROM (SELECT DECODE( D.DT_MED_TSTZ, NULL, NULL, Pk_Message.GET_MESSAGE(' || i_lang || ', ''INP_MAIN_GRID_DISCHARGE_FLAG'')) FLAG_DISCHARGE, ' || --
         ' CR.NUM_CLIN_RECORD,EPIS.ID_EPISODE,PAT.ID_PATIENT, pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'',PAT.GENDER,' || i_lang || ') GENDER,  ' || --
         'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --         
         'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by,' || 'pk_patphoto.get_pat_photo(' || i_lang || ', ' || 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), pat.id_patient, epis.id_episode, null) PHOTO,' || --
         'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE, ' || --         
        
         '''' || g_sysdate_char || ''' DT_SERVER, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ') DT_BEGIN, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EI.DT_FIRST_OBS_TSTZ, ' || l_prof || ') DT_FIRST_OBS, ' || --
         'PK_DATE_UTILS.GET_ELAPSED_TSZ(' || i_lang || ',EPIS.DT_BEGIN_TSTZ, CURRENT_TIMESTAMP) DATE_SEND,' || --
         'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_EFECTIV, ' || --
         'PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE,' || i_prof.id || ') FLG_TEMP,' || --
         'DECODE(EPIS.FLG_STATUS, ''' || g_epis_active || ''', '''',DECODE(PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE, ' || i_prof.id || --
         '),''Y'', PK_MESSAGE.GET_MESSAGE(' || i_lang || ', ''COMMON_M012''), '''')) DESC_TEMP,' || --
         'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME  IMG_TRANSP,' || --
        -- José Brito 24/04/2008 DESC_ROOM estava repetido        
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.DRUG_PRESC) DESC_DRUG_PRESC, ' || --
        -- INP LMAIA 17-03-2009
        -- INPATIENT Grid's reformulation in FIX 2.4.3.21
        -- 'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.INTERVENTION) DESC_INTERV_PRESC,  ' || --
        -- 'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.MONITORIZATION) DESC_MONITORIZATION,' || --
         'pk_grid.get_prioritary_task(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
				  pk_grid.get_prioritary_task( ' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                 pk_grid.get_prioritary_task( ' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
                           pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
                             epis.id_visit,''' || pk_inp_grid.g_task_interv || ''',''' || l_prof_cat || '''),
                           pk_inp_grid.get_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),                           
                           ''' || pk_prof_utils.get_prof_profile_template(i_prof) || ''',
                           pk_grid.visit_grid_task_str_nc(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                                                          
                                                          epis.id_visit,
                                                          ''' || pk_inp_grid.g_task_monitor || ''',''' || l_prof_cat || '''))
                                                          , NULL, ' || g_pl || l_prof_cat || g_pl || '),
             
            pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.NURSE_ACTIVITY), NULL, ' || g_pl || l_prof_cat || g_pl || '),
				  pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ''' || pk_inp_grid.g_task_edu || ''',''' || l_prof_cat || '''), NULL, ' || g_pl || l_prof_cat || g_pl || ')
        desc_monit_interv_presc, ' || --
        --END
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.MOVEMENT) DESC_MOVEMENT,' || --
         'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_analysis || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') desc_analysis_req, ' || 'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_exam || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') desc_exam_req, ' || 'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_harvest || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') DESC_HARVEST, ' || --
         'pk_inp_grid.get_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),' || pk_inp_grid.g_phy_presc_profile || ', GT.POSITIONING)  DESC_POSITIONING,' || --
         'pk_inp_grid.get_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
         pk_prof_utils.get_prof_profile_template(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), 
         pk_inp_hidrics_pbl.get_hidrics_reg(' || i_lang || ',PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),epis.id_visit), null) desc_hidrics_reg,' ||
        
         'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.SCALE_VALUE)          DESC_SCALE_VALUE,' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.NURSE_ACTIVITY)       DESC_NURSE_ACTIVITY,' || --
        
         'PK_INP_GRID.GET_DIAGNOSIS_GRID( ' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE ) DESC_DIAGNOSIS,' || --         
         'NVL(BD.DESC_BED, Pk_Translation.GET_TRANSLATION(' || i_lang || ', BD.CODE_BED)) DESC_BED, ' || --
         'NVL(nvl(ro.desc_room_abbreviation, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ABBREVIATION)), nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ROOM))) DESC_ROOM, ' || --
        -- INP LMAIA 17-03-2009
        -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
         'DECODE(BD.CODE_BED, NULL, NULL, ' || --
         'nvl(pk_translation.get_translation(' || i_lang || ', dpt2.abbreviation),
                 pk_translation.get_translation(' || i_lang || ', dpt2.code_department))) desc_service, ' || --
        --
         'nvl((SELECT pk_translation.get_translation(' || i_lang || ', ty1.code_epis_type)
                   FROM episode epi1, epis_type ty1
                  WHERE epi1.id_epis_type = ty1.id_epis_type
                    AND epi1.id_episode = epis.id_prev_episode),
                 pk_translation.get_translation(' || i_lang || ', ''' || g_inp_epis_type_code || ''')) origin,' || --
        -- END        
        --jose silva 19-03-2007 valores de defeito para pacientes sem serviço
         'NVL((DPT.RANK*100000),0)+ NVL((RO.RANK * 1000 ),0) + NVL(BD.RANK, 99 )   RANK,' || --
        -- José Brito 18/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
         'pk_visit.check_flg_cancel(' || i_lang || ', ' || l_prof || ', epis.id_episode) flg_cancel, ' || 'EPIS.DT_BEGIN_TSTZ, ' ||
        --
        
        --
         ' (SELECT pk_hand_off_core.get_responsibles_str(' || i_lang || ',' || l_prof || ',''' || pk_alert_constant.g_cat_type_doc || ''', epis.id_episode, ei.id_professional, ''' || l_hand_off_type || ''', ''G'')' || 'FROM dual) name_prof,' || ' (SELECT pk_hand_off_core.get_responsibles_str(' || i_lang || ',' || l_prof || ',''' || pk_alert_constant.g_cat_type_doc || ''', epis.id_episode, ei.id_professional, ''' || l_hand_off_type || ''',''' || g_show_in_tooltip || ''')' || 'FROM dual) name_prof_tooltip,' || ' pk_prof_utils.get_nickname(' || i_lang || ', ei.id_first_nurse_resp) name_nurse,' || ' (SELECT pk_hand_off_core.get_responsibles_str(' || i_lang || ',' || l_prof || ',''' || pk_alert_constant.g_cat_type_nurse || ''', epis.id_episode, ei.id_first_nurse_resp, ''' || l_hand_off_type || ''',''' || g_show_in_tooltip || ''')' || 'FROM dual) name_nurse_tooltip,' ||
        --
        
         '  pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat,' || '  pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat_to_sort,
					 pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_ndo,
					 pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_nd_icon,' || --
         ' pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || l_prof || ', epis.id_episode,''' || l_hand_off_type || ''') resp_icons, ' || --
        -- INP AN add service/institution transfer icon 22-Mar-2011 [ALERT-28312]
         'pk_service_transfer.get_transfer_status_icon(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE, NULL) desc_pat_transfer,' || --
         'decode(DISCH.flg_status, ' || xpl || g_epis_pend || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', nvl(DISCH.dt_med_tstz, DISCH.dt_pend_tstz), PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_pend_time_discharge,' || -- 
         'decode(DISCH.flg_status, ' || xpl || g_epis_active || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', DISCH.dt_med_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_time_discharge, ' || --
        l_disch_shortcut || ' disch_shortcut ' || chr(32) || --
         ', (SELECT alert_process_number FROM pat_identifier pi WHERE pi.id_patient = (SELECT e.id_patient FROM episode e WHERE e.id_episode = epis.id_episode) AND pi.id_institution = nvl(' || i_prof.institution || ', 0) and pi.flg_status= ''' || pk_alert_constant.g_active || ''') alert_process_number, ' || 'pat.identity_code pat_code, ' || 'pk_edis_proc.get_los_duration(i_lang =>' || i_lang || ', i_prof => ' || l_prof || ', i_id_episode => epis.id_episode) los, ' || 'pk_date_utils.date_hour_chr_tsz(i_lang => ' || i_lang || ', i_date => epis.dt_begin_tstz, i_prof => ' || l_prof || ') dt_admission, ' || 'ei.id_professional id_professional, ' || 'pk_hea_prv_epis.get_resp_doctor(' || i_lang || ', ' || l_prof || ', epis.id_episode, null) epis_resp_doctor, ' || 'pk_edis_proc.get_los_duration_number(i_lang =>' || i_lang || ', i_prof => ' || l_prof || ', i_id_episode => epis.id_episode) length_of_stay, ' || 'pk_date_utils.dt_chr_tsz(i_lang=>' || i_lang || ' ,i_date => pk_discharge.get_discharge_date(' || i_lang || ', ' || l_prof || ', epis.id_episode), i_prof=> ' || l_prof || ') discharge_date, ' || 'pk_prof_utils.get_prof_inst_mec_num(i_lang => ' || i_lang || ' , i_prof => ' || 'PROFISSIONAL(ei.id_professional,' || i_prof.institution || ',' || i_prof.software || ')) num_mecan' || ' FROM EPISODE EPIS, EPIS_INFO EI, PATIENT PAT,DISCHARGE D, ' || 'DEPARTMENT DPT, DEPARTMENT DPT2, ' || 'CLIN_RECORD CR, CLINICAL_SERVICE CS, ' || --
         ' EPIS_EXT_SYS EES,' || --
         'PAT_SOC_ATTRIBUTES PSA, GRID_TASK GT, ROOM RO, SYS_DOMAIN SD, BED BD, ' || 'PROFESSIONAL P ' || --
        -- INP AN add discharge icon 25-Mar-2011 [ALERT-28312]
         ', (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                      FROM discharge
                     WHERE flg_status IN (' || xpl || pk_edis_grid.g_discharge_flg_status_active || xpl || ', ' || xpl || pk_edis_grid.g_discharge_flg_status_pend || xpl || ')) DISCH ' || --
         ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE ' || --
         ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' || --
         ' AND BD.ID_BED(+) = EI.ID_BED' || --
         ' AND RO.ID_ROOM(+) = BD.ID_ROOM' || --  
         ' AND DISCH.ID_EPISODE (+) = EPIS.ID_EPISODE' || chr(32) || --     
         ' AND EI.ID_SOFTWARE=' || i_prof.software || --
         ' AND DPT.ID_DEPARTMENT = EPIS.ID_DEPARTMENT' || --
         ' AND EPIS.FLG_EHR IN (''N'') ' || --
         ' AND EPIS.ID_INSTITUTION=' || i_prof.institution || --
         ' AND EPIS.ID_PATIENT=PAT.ID_PATIENT ' || --
         ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE ' || ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || '''' || --         
        --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
         ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' || ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT' || --
         ' AND PSA.ID_INSTITUTION(+) = ' || i_prof.institution || --
         ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
        --' AND CR.ID_INSTIT_ENROLED(+) = ' || i_prof.institution || --
         ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
         ' AND SD.VAL(+)=EI.FLG_STATUS' || --
         ' AND SD.CODE_DOMAIN(+)=''EPIS_INFO.FLG_STATUS''' || --
         ' and sd.domain_owner(+) = ' || '''' || pk_sysdomain.k_default_schema || '''' || ' AND SD.ID_LANGUAGE(+) = ' || i_lang || --
         ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_INSTITUTION(+) = ' || i_prof.institution || --
         ' AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_EXTERNAL_SYS(+) = ' || id_ext ||
        -- LMAIA 17-03-2009 Added JOIN to identify service responsable for current bed
         ' AND DPT2.ID_DEPARTMENT(+) = RO.ID_DEPARTMENT' || --
        -- END
         ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' || --
         ' AND ROWNUM < ' || l_limit || -- 
        l_where || --
         ' ORDER BY desc_service, desc_room, desc_bed) wnd' || chr(32) || ' ORDER BY wnd.DT_BEGIN_TSTZ';
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang,
                                                 i_prof,
                                                 g_package_name,
                                                 'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                                 o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_clin;

    /**********************************************************************************************
    * Search of active patients to the activity therapist
    *
    * @param i_lang                          Language ID
    * @param I_ID_SYS_BTN_CRIT               List of the search criteria IDs
    * @param I_CRIT_VAL                      List of the search criteria values
    * @param I_INSTIT                        Institution
    * @param I_EPIS_TYPE                     Episode type
    * @param I_DT                            Date to be searched. If it is null the system date is assumed
    * @param I_PROF                          Professional ID
    * @param I_PROF_CAT_TYPE                 Professional category type, as it is returned in PK_LOGIN.GET_PROF_PREF
    * @param O_PAT                           Active patients
    * @param O_MESS_NO_RESULT                Message to be shown when the search does not return results
    * @param O_ERROR                         Error
    *
    * @return                                Success / fail
    *
    * @author                                Sofia Mendes
    * @version                               2.6.0.3
    * @since                                 20-Mai-2010 
    * Similar to the functionget_pat_criteria_active_clin to the activity therapist
    **********************************************************************************************/
    FUNCTION get_pat_criteria_active_at
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(32000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(50);
        --
        l_ret      BOOLEAN;
        l_prof_cat category.flg_type%TYPE;
    
        CURSOR c_prof_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
    
    BEGIN
        xpl            := '''';
        g_error        := 'INICIO:';
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        --
        g_error := 'L_LIMIT:';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof  := 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')';
    
        g_error := 'GET PROF CAT';
        OPEN c_prof_cat;
        FETCH c_prof_cat
            INTO l_prof_cat;
        CLOSE c_prof_cat;
    
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
            
                g_error := 'GET CRITERIA CONDITION:';
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        -- JS, 2007-09-07 - Timezone
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                g_error := 'SET L_WHERE';
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'SET WHERE 2';
        id_doc  := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext  := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        --
    
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(epis.id_episode) ' || --
                   '  FROM episode            epis, ' || --
                   '       epis_info          ei, ' || --
                   '       patient            pat, ' || --
                   '       discharge          d, ' || --
                   '       professional       p, ' || --
                   '       speciality         sp, ' || --
                   '       clin_record        cr, ' || --
                   '       department         dpt, ' || --
                   '       clinical_service   cs, ' || --
                   '       epis_ext_sys       ees, ' || --
                   '       pat_soc_attributes psa, ' || --
                   '       pat_doc            pd ' || --
                   ' WHERE epis.id_episode = ei.id_episode(+) ' || --
                   '   AND epis.id_clinical_service = cs.id_clinical_service ' || --
                   '   AND ei.id_software = :1 ' || --
                   '   AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = ei.id_software ' || --
                   '   AND epis.id_institution = :2 ' || --
                   '   AND epis.id_patient = pat.id_patient ' || --
                   '   AND epis.id_department = dpt.id_department ' || --
                   '   AND epis.flg_ehr = ''N'' ' || --
                   '   AND d.id_episode(+) = epis.id_episode ' || --
                   '   AND d.flg_status(+) != ''' || pk_discharge_core.g_disch_status_cancel || '''' || --
                   '   AND d.flg_status(+) != ''' || pk_discharge_core.g_disch_status_reopen || '''' || --
                   '   AND p.id_professional(+) = ei.id_professional ' || --
                   '   AND epis.flg_status IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ') ' || -- LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
                   '   AND sp.id_speciality(+) = p.id_speciality ' || --
                   '   AND psa.id_patient(+) = pat.id_patient ' || --
                   '   AND psa.id_institution(+) = :3 ' || --
                   '   AND cr.id_patient(+) = pat.id_patient ' || --
                   '   AND cr.id_institution(+) = :4 ' || --
                   '   AND ees.id_episode(+) = epis.id_episode ' || --
                   '   AND ees.id_external_sys(+) = :5 ' || --
                   '   AND ees.id_institution(+) = :6 ' || --
                   '   AND pd.id_patient(+) = pat.id_patient ' || --
                   '   AND pd.id_doc_type(+) = :7 ' || l_where;
    
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING pk_alert_constant.g_soft_inpatient, i_prof.institution, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
    
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
    
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT to_char(rownum, ''00000'') serv_rank, ' || --
         '       decode(wnd.id_opinion, ' || --
         '              NULL, ' || --
         '              pk_message.get_message(' || i_lang || ', ''' || pk_act_therap_constant.g_msg_na || '''), ' || --
         '              pk_date_utils.date_char_hour_tsz(' || i_lang || ', wnd.next_enc_tstz, ' || i_prof.institution || ', ' || i_prof.software || ')) dt_next_hour, ' || --
         '       pk_date_utils.dt_chr_tsz(' || i_lang || ', wnd.next_enc_tstz, ' || i_prof.institution || ', ' || i_prof.software || ') dt_next_date, ' || --
         '       pk_inp_grid.get_discharge_msg(' || i_lang || ', ' || l_prof || ', wnd.id_episode_origin, NULL) discharge_desc, ' || --
         '       pk_date_utils.dt_chr_tsz(' || i_lang || ', wnd.dt_discharge, ' || l_prof || ') discharge_date_desc, ' || --
         '       wnd.* ' || --
         '  FROM (SELECT cr.num_clin_record, ' || --
         '               epis.id_episode id_episode_origin, ' || --
         '               pat.id_patient, ' || --
         '               pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'', pat.gender, ' || i_lang || ') gender, ' || --
         '               pk_patient.get_pat_age(' || i_lang || ', ' || --
         '                                      pat.dt_birth, ' || --
         '                                      pat.dt_deceased, ' || --
         '                                      pat.age, ' || --
         '                                      ' || i_prof.institution || ', ' || --
         '                                      ' || i_prof.software || ') pat_age, ' || --
         '               pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by, ' || --
         '               pk_patphoto.get_pat_photo(' || i_lang || ', ' || --
         '                                         profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || '), ' || --
         '                                         pat.id_patient, ' || --
         '                                         epis.id_episode, ' || --
         '                                         NULL) photo, ' || --
         '               p.nick_name name_prof, ' || --
         '               ''' || g_sysdate_char || ''' dt_server, ' || --
         '               pk_date_utils.date_send_tsz(' || i_lang || ', epis.dt_begin_tstz, ' || l_prof || ') dt_begin, ' || --
         '               pk_date_utils.get_elapsed_tsz(' || i_lang || ', epis.dt_begin_tstz, current_timestamp) date_send, ' || --
         '               nvl(bd.desc_bed, pk_translation.get_translation(' || i_lang || ', bd.code_bed)) desc_bed, ' || --
         '               nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(' || i_lang || ', ro.code_abbreviation)), ' || --
         '                   nvl(ro.desc_room, pk_translation.get_translation(' || i_lang || ', ro.code_room))) desc_room, ' || --
         '               decode(bd.code_bed, ' || -- INP LMAIA 17-03-2009 Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
         '                      NULL, ' || --
         '                      NULL, ' || --
         '                      nvl(pk_translation.get_translation(' || i_lang || ', dpt2.abbreviation), ' || --
         '                          pk_translation.get_translation(' || i_lang || ', dpt2.code_department))) desc_service, ' || --
         '               nvl((dpt.rank * 100000), 0) + nvl((ro.rank * 1000), 0) + nvl(bd.rank, 99) rank, ' || -- jose silva 19-03-2007 valores de defeito para pacientes sem serviço
         '               pk_visit.check_flg_cancel(' || i_lang || ', ' || l_prof || ', epis.id_episode) flg_cancel, ' || -- José Brito 18/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
         '               epis.dt_begin_tstz, ' || --
         '               pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', epis.id_patient, epis.id_episode) name_pat, ' || --
         '               pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', epis.id_patient, epis.id_episode) name_pat_to_sort, ' || --
         '               pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', epis.id_patient) pat_ndo, ' || --
         '               pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', epis.id_patient) pat_nd_icon, ' || --
         '               op.id_opinion, ' || -- Sofia Mendes 07-05-2010 activity theraphy request
         '               decode(op.id_opinion, ' || --
         '                      NULL, ' || --
         '                      pk_message.get_message(' || i_lang || ', ''' || pk_act_therap_constant.g_msg_na || '''), ' || --
         '                      pk_prof_utils.get_spec_signature(' || i_lang || ', ' || --
         '                                                       ' || l_prof || ', ' || --
         '                                                       op.id_prof_questions, ' || --
         '                                                       op.dt_last_update, ' || --
         '                                                       op.id_episode)) origin, ' || --
         '               decode(op.id_opinion, ' || --
         '                      NULL, ' || --
         '                      NULL, ' || --
         '                      pk_prof_utils.get_name_signature(' || i_lang || ', ' || l_prof || ', op.id_prof_questions)) origin_prof, ' || --
         '               decode(op.id_opinion, ' || --
         '                      NULL, ' || --
         '                      pk_message.get_message(' || i_lang || ', ''' || pk_act_therap_constant.g_msg_na || '''), ' || --
         '                      decode(op.id_episode_answer, ' || --
         '                             NULL, ' || --
         '                             pk_prof_utils.get_name_signature(' || i_lang || ', ' || l_prof || ', op.id_prof_questioned), ' || --
         '                             pk_prof_utils.get_name_signature(' || i_lang || ', ' || --
         '                                                              ' || l_prof || ', ' || --
         '                                                              (SELECT epii.id_professional ' || --
         '                                                                 FROM epis_info epii ' || --
         '                                                                WHERE epii.id_episode = op.id_episode_answer)))) resp_prof_name, ' || --
         '               decode(op.id_episode_answer, ' || --
         '                      NULL, ' || --
         '                      decode(op.id_prof_questioned, ' || --
         '                             NULL, ' || --
         '                             NULL, ' || --
         '                             pk_message.get_message(' || i_lang || ', ''' || pk_act_therap_constant.g_msg_requested_to || ''')), ' || --
         '                      NULL) responsable_desc, ' || --
         '               decode(op.id_opinion, ' || --
         '                      NULL, ' || --
         '                      pk_message.get_message(' || i_lang || ', ''' || pk_act_therap_constant.g_msg_na || '''), ' || --
         '                      pk_supplies_external_api_db.get_has_supplies_desc(' || i_lang || ', ' || l_prof || ', op.id_episode_answer)) return_desc, ' || --
         '               pk_paramedical_prof_core.get_dt_next_enc(op.id_episode_answer) next_enc_tstz, ' || --
         '               pk_activity_therapist.get_req_status_str(' || i_lang || ', ' || l_prof || ', op.flg_state, op.dt_last_update) desc_status, ' || --
         '               pk_discharge.get_discharge_date(' || i_lang || ', ' || l_prof || ', epis.id_episode) dt_discharge, ' || --
         '               op.flg_state, ' || --
         '               pk_opinion.check_approval_need(profissional(op.id_prof_questions, ' || i_prof.institution || ', ' || i_prof.software || '), ' || --
         '                                              ' || pk_act_therap_constant.g_at_opinion_type || ') flg_needs_approval, ' || --
         '               op.id_episode_answer id_episode ' || --
         '          FROM episode epis, ' || --
         '               epis_info ei, ' || --
         '               patient pat, ' || --
         '               discharge d, ' || --
         '               professional p, ' || --
         '               department dpt, ' || --
         '               department dpt2, ' || --
         '               clin_record cr, ' || --
         '               clinical_service cs, ' || --
         '               epis_ext_sys ees, ' || --
         '               pat_soc_attributes psa, ' || --
         '               pat_doc pd, ' || --
         '               room ro, ' || --
         '               bed bd, ' || -- Sofia Mendes 07-05-2010 activity theraphy request
         '               (SELECT * ' || --
         '                  FROM opinion o ' || --
         '                 WHERE o.id_opinion_type = 4 ' || --
         '                   AND o.flg_state IN (''' || pk_opinion.g_opinion_req || ''', ' || --
         '                                       ''' || pk_opinion.g_opinion_approved || ''', ' || --
         '                                       ''' || pk_opinion.g_opinion_accepted || ''')) op ' || --
         '         WHERE epis.id_episode = ei.id_episode ' || --
         '           AND epis.id_clinical_service = cs.id_clinical_service ' || --
         '           AND bd.id_bed(+) = ei.id_bed ' || --
         '           AND ro.id_room(+) = bd.id_room ' || --
         '           AND ei.id_software = ' || pk_alert_constant.g_soft_inpatient || --
         '           AND dpt.id_department = epis.id_department ' || --
         '           AND epis.flg_ehr = ''N'' ' || --
         '           AND epis.id_institution = ' || i_prof.institution || ' ' || --
         '           AND epis.id_patient = pat.id_patient ' || --
         '           AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, epis.id_institution) = ei.id_software ' || --
         '           AND d.id_episode(+) = epis.id_episode ' || --
         '           AND d.flg_status(+) != ''' || pk_discharge_core.g_disch_status_cancel || '''' || --
         '           AND d.flg_status(+) != ''' || pk_discharge_core.g_disch_status_reopen || '''' || --
         '           AND p.id_professional(+) = ei.id_professional ' || --
         '           AND epis.flg_status IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ') ' || -- LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
         '           AND psa.id_patient(+) = pat.id_patient ' || --
         '           AND psa.id_institution(+) = ' || i_prof.institution || ' ' || --
         '           AND cr.id_patient(+) = pat.id_patient ' || --
         '           AND cr.id_institution(+) = ' || i_prof.institution || ' ' || --
         '           AND ees.id_episode(+) = epis.id_episode ' || --
         '           AND ees.id_institution(+) = ' || i_prof.institution || ' ' || --
         '           AND ees.id_external_sys(+) = ' || id_ext || --
         '           AND pd.id_patient(+) = pat.id_patient ' || --
         '           AND pd.id_doc_type(+) = ' || id_doc || --
         '           AND dpt2.id_department(+) = ro.id_department ' || -- LMAIA 17-03-2009 Added JOIN to identify service responsable for current bed
         '           AND op.id_episode(+) = epis.id_episode ' || --
         '           AND rownum < ' || l_limit || l_where || --
         '         ORDER BY desc_service, desc_room, desc_bed) wnd ' || --
         ' ORDER BY wnd.dt_begin_tstz ';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang,
                                                 i_prof,
                                                 g_package_name,
                                                 'GET_PAT_CRITERIA_ACTIVE_CLIN',
                                                 o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_CLIN', o_error);
            pk_types.open_my_cursor(o_pat);
            --RETURN FALSE;
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE_AT',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_at;

    -- ###################################################################################

    /******************************************************************************
       OBJECTIVO:   Efectuar pesquisa de doentes ACTIVOS, de acordo com os critérios seleccionados ,
                    para pessoal AUXILIAR.
       PARAMETROS:  Entrada: I_LANG - Língua registada como preferência do profissional
               I_ID_SYS_BTN_CRIT - Lista de ID'S de critérios de pesquisa.
               I_CRIT_VAL - Lista de valores dos critérios de pesquisa
             I_INSTIT - Instituição
             I_EPIS_TYPE - Tipo de consulta
             I_DT - Data a pesquisar. Se for null assume a data de sistema
               I_PROF - ID do profissional q regista
             I_PROF_CAT_TYPE - Tipo de categoria do profissional, tal
                       como é retornada em PK_LOGIN.GET_PROF_PREF
                Saida:   O_PAT - Doentes activos
                 O_MESS_NO_RESULT - Mensagem quando a pesquisa não devolver resultados
             O_ERROR - Erro
    
      CRIAÇÃO: SS 2006/11/08
      NOTAS: Igual à função do PK_EDIS_PROC mas sem EPIS_ANAMNESIS, EDIS_TRIAGE e TRIAGE_COLOR mas com BED e ROOM
    *********************************************************************************/
    FUNCTION get_pat_criteria_active_aux
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(32000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        l_ret        BOOLEAN;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(50);
        --
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
    
    BEGIN
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_inp_grid.g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        xpl            := '''';
        g_error        := 'BEGINING...';
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        l_prof         := 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')';
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
            
                g_error := 'SET CRITERIAS:' || i || ' count:' || i_id_sys_btn_crit.count;
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        -- JS, 2007-09-07 - Timezone
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'SET CONFIGS';
        id_doc  := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext  := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        -- 
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || ' FROM EPISODE EPIS, ' || 'EPIS_INFO EI, DISCHARGE D,' || --'EPIS_TYPE ET,' ||
                   'PATIENT PAT,' || 'PROFESSIONAL P,' || 'SPECIALITY SP,' || 'CLIN_RECORD CR, ' ||
                   'CLINICAL_SERVICE CS,' || 'EPIS_EXT_SYS EES, ' || 'PAT_SOC_ATTRIBUTES PSA , ' || 'PAT_DOC PD, ' ||
                   'DEPARTMENT    DPT ' || ' WHERE EI.ID_SOFTWARE         = :1 ' || --I_PROF.SOFTWARE
                   ' AND EPIS.ID_EPISODE          = EI.ID_EPISODE(+) ' ||
                   ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' ||
                  --  ' AND EI.ID_DEP_CLIN_SERV      = DCS.ID_DEP_CLIN_SERV' ||
                  -- <DENORM_EPISODE_JOSE_BRITO>
                   ' AND EPIS.ID_DEPARTMENT        = DPT.ID_DEPARTMENT' ||
                   ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE ' ||
                   ' AND EPIS.ID_INSTITUTION         = :2 ' || --I_PROF.INSTITUTION
                   ' AND EPIS.ID_PATIENT             = PAT.ID_PATIENT  ' ||
                   ' AND D.ID_EPISODE(+)          = EPIS.ID_EPISODE ' || --
                   ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' || --
                   ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || '''' || --
                   ' AND EPIS.FLG_EHR             IN (''N'') ' || ' AND P.ID_PROFESSIONAL(+)     = EI.ID_PROFESSIONAL ' ||
                  --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
                   ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' || --G_EPIS_ACTIVE e G_EPIS_PEND
                  -- || ' AND EPIS.FLG_STATUS          = ' || xpl || g_epis_active || xpl || --G_EPIS_ACTIVE
                  --
                   ' AND SP.ID_SPECIALITY(+)      = P.ID_SPECIALITY ' ||
                   ' AND PSA.ID_PATIENT (+)       = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION (+)   = :3 ' ||
                   ' AND CR.ID_PATIENT(+)         = PAT.ID_PATIENT ' || ' AND CR.ID_INSTITUTION(+)     = :4 ' || --I_PROF.INSTITUTION
                   ' AND EES.ID_EPISODE(+)        = EPIS.ID_EPISODE ' || ' AND EES.ID_EXTERNAL_SYS(+)   = :5 ' || --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :2, :1) '||
                   ' AND EES.ID_INSTITUTION(+)    = :6 ' || --||I_PROF.INSTITUTION|| 
                   ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT  ' || ' AND PD.ID_DOC_TYPE(+) = :4 ' || l_where;
        --
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.software, i_prof.institution, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT gt.hemo_req, CR.NUM_CLIN_RECORD,EPIS.ID_EPISODE,PAT.ID_PATIENT, pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'',PAT.GENDER,' || i_lang || ') GENDER,  ' || --         
         'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --       
         'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by,' || 'pk_patphoto.get_pat_photo(' || i_lang || ', ' || 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), pat.id_patient, epis.id_episode, null) PHOTO,' || --
         'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE, ' || --
        --'P.NICK_NAME NAME_PROF,PN.NICK_NAME NAME_NURSE, ' || 
         '''' || g_sysdate_char || ''' DT_SERVER, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ') DT_BEGIN, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EI.DT_FIRST_OBS_TSTZ, ' || l_prof || ') DT_FIRST_OBS, ' || --
         'PK_DATE_UTILS.GET_ELAPSED_TSZ(' || i_lang || ',EPIS.DT_BEGIN_TSTZ, CURRENT_TIMESTAMP) DATE_SEND,' || --
         'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_EFECTIV, ' || --
         'PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE,' || i_prof.id || ') FLG_TEMP,' || --
         'DECODE(EPIS.FLG_STATUS, ''' || g_epis_active || ''', '''',DECODE(PK_SAVE.CHECK_EXIST_REC_TEMP(' || i_lang || ', EPIS.ID_EPISODE, ' || i_prof.id || '),''Y'', PK_MESSAGE.GET_MESSAGE(' || i_lang || ', ''COMMON_M012''), '''')) DESC_TEMP,' || --
         'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME  IMG_TRANSP,' || --
         'NVL(nvl(ro.desc_room_abbreviation, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ABBREVIATION)), nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ROOM))) DESC_ROOM,' || --
        
         'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.DRUG_TRANSP) DESC_DRUG_REQ,  ' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.MOVEMENT) DESC_MOVEMENT,' || --        
         'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_harvest || g_pl || ', ' || g_pl || i_prof_cat_type || g_pl || ') DESC_HARVEST, ' || --
        
        --'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', SP.CODE_SPECIALITY) DESC_SPEC_PROF, ' || --
        --'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', SN.CODE_SPECIALITY) DESC_SPEC_NURSE, ' || --
         'NVL(BD.DESC_BED, Pk_Translation.GET_TRANSLATION(' || i_lang || ', BD.CODE_BED)) DESC_BED, ' || --
         'NVL(nvl(ro.desc_room_abbreviation, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ABBREVIATION)), nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION(' || i_lang || ', RO.CODE_ROOM))) DESC_ROOM, ' || --
        -- <DENORM_EPISODE_JOSE_BRITO>
         'gt.supplies DESC_SUPPLIES,' || --
        -- INP AN add service/institution transfer icon 22-Mar-2011 [ALERT-28312]
         'pk_service_transfer.get_transfer_status_icon(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE, NULL) desc_pat_transfer,' || -- 
         'decode(DISCH.flg_status, ' || xpl || g_epis_pend || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', nvl(DISCH.dt_med_tstz, DISCH.dt_pend_tstz), PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_pend_time_discharge,' || -- 
         'decode(DISCH.flg_status, ' || xpl || g_epis_active || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', DISCH.dt_med_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_time_discharge,' || --
        l_disch_shortcut || ' disch_shortcut,' || chr(32) || -- 
         '  pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat,' || --
         '  pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat_to_sort,
					 pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_ndo,
					 pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_nd_icon, ' || ' pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || l_prof || ', epis.id_episode,''' || l_hand_off_type || ''') resp_icons ' || --            
         ' FROM EPISODE EPIS, EPIS_INFO EI, ' || ' PATIENT PAT,DISCHARGE D,  ' ||
        --'PROFESSIONAL P, SPECIALITY SP,' || 'PROFESSIONAL PN, SPECIALITY SN,' || 
         'CLIN_RECORD CR, CLINICAL_SERVICE CS, EPIS_EXT_SYS EES,' || --
         'PAT_SOC_ATTRIBUTES PSA, PAT_DOC PD, GRID_TASK GT, ROOM RO, SYS_DOMAIN SD, BED BD, ' || --
         'EPIS_INFO EPO,' || --
        -- jose silva 27-03-2007 tabela de documentos - doc_external
         ' DEPARTMENT    DPT ' || --
        -- INP AN add discharge icon 25-Mar-2011 [ALERT-28312]
         ', (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                      FROM discharge
                     WHERE flg_status IN (' || xpl || pk_edis_grid.g_discharge_flg_status_active || xpl || ', ' || xpl || pk_edis_grid.g_discharge_flg_status_pend || xpl || ')) DISCH ' || --
         ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE ' || --
        -- <DENORM RicardoNunoAlmeida>
         'AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EPO.ID_SOFTWARE ' || 'AND EPIS.ID_EPISODE      = EPO.ID_EPISODE' || chr(32) || --    
         ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' || --
         ' AND EPIS.ID_DEPARTMENT = DPT.ID_DEPARTMENT' || --
         ' AND BD.ID_BED(+) = EI.ID_BED' || --
         ' AND RO.ID_ROOM(+) = BD.ID_ROOM' || --  
         ' AND DISCH.ID_EPISODE (+) = EPIS.ID_EPISODE' || chr(32) || --      
         ' AND EI.ID_SOFTWARE=' || i_prof.software || --        
        --
         ' AND EPIS.ID_INSTITUTION=' || i_prof.institution || --
         ' AND EPIS.ID_PATIENT=PAT.ID_PATIENT ' || --
        --
         ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || '''' || --
         ' AND EPIS.FLG_EHR IN (''N'') ' ||
        --' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' || --
        --' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY' || --
        --' AND PN.ID_PROFESSIONAL(+)=EI.ID_FIRST_NURSE_RESP ' || --
        --' AND SN.ID_SPECIALITY(+) = PN.ID_SPECIALITY' || --
        --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
         ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' || --G_EPIS_ACTIVE e G_EPIS_PEND
        -- ' AND EPIS.FLG_STATUS = ''' || g_epis_active || '''' || --
        --
         ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT' || --
         ' AND PSA.ID_INSTITUTION (+) = ' || i_prof.institution || --
         ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
         ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
         ' AND SD.VAL(+)=EI.FLG_STATUS' || --
         ' AND SD.CODE_DOMAIN(+)=''EPIS_INFO.FLG_STATUS''' || --
         ' and sd.domain_owner(+) = ' || '''' || pk_sysdomain.k_default_schema || '''' || ' AND SD.ID_LANGUAGE(+) = ' || i_lang || --
         ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_INSTITUTION(+) = ' || i_prof.institution || --
         ' AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_EXTERNAL_SYS(+) = ' || id_ext || --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'','||I_PROF.INSTITUTION||', '||I_PROF.SOFTWARE||' ) '||
         ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
         ' AND PD.ID_DOC_TYPE(+) = ' || id_doc || --
         ' AND ROWNUM < ' || l_limit || --
        l_where || --
         ' ORDER BY EPIS.DT_BEGIN_TSTZ';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_AUX', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_AUX', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE_AUX',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_aux;

    -- ****************************************************************************
    /*
    update:
    20-03-2007: jose silva Retornar as salas onde está localizada a cama
    */
    FUNCTION get_pat_criteria_active_adm
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_pat             OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(32000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(0500);
        l_ret        BOOLEAN;
    
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
    
    BEGIN
    
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_inp_grid.g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        xpl := '''';
    
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        -- JS, 2007-09-07 - Timezone
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        --
        id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        --
        l_prof := 'PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
        --
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || ' FROM EPISODE EPIS, ' || 'EPIS_INFO EI, ' ||
                   'DEPARTMENT    DPT,' || 'PATIENT PAT,' || 'DISCHARGE D, ' || 'PROFESSIONAL P,' || 'SPECIALITY SP,' ||
                   'CLIN_RECORD CR, ' || 'CLINICAL_SERVICE CS,' || 'EPIS_EXT_SYS EES, ' || 'PAT_SOC_ATTRIBUTES PSA, ' ||
                   'PAT_DOC PD ' || ' WHERE EI.ID_SOFTWARE         = :1 ' || --I_PROF.SOFTWARE
                   ' AND EPIS.ID_DEPARTMENT       = DPT.ID_DEPARTMENT' ||
                   ' AND EPIS.ID_EPISODE          = EI.ID_EPISODE ' ||
                   ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' ||
                  --' AND ET.ID_EPIS_TYPE          = EPIS.ID_EPIS_TYPE ' || 
                  -- José Brito 17/07/2008 Não mostrar episódios de OBS nos resultados da pesquisa de activos
                   ' AND EPIS.ID_EPIS_TYPE = DECODE((SELECT PK_INP_EPISODE.CHECK_OBS_EPISODE(' || i_lang || ', ' ||
                   l_prof || ', EPIS.ID_EPISODE) FROM DUAL), 0, EPIS.ID_EPIS_TYPE, NULL)' ||
                  --
                   ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE' ||
                  -- LMAIA 17-03-2009 Previous function guarantee that OBS episodes are not returned in Inpatient ADM search.                 
                   ' AND EPIS.ID_INSTITUTION         = :2 ' || --I_PROF.INSTITUTION
                   ' AND EPIS.ID_PATIENT             = PAT.ID_PATIENT  ' ||
                   ' AND D.ID_EPISODE(+)          = EPIS.ID_EPISODE ' ||
                   ' AND P.ID_PROFESSIONAL(+)     = EI.ID_PROFESSIONAL ' ||
                  --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
                   ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' || --G_EPIS_ACTIVE e G_EPIS_PEND
                  --
                   ' AND SP.ID_SPECIALITY(+)      = P.ID_SPECIALITY ' || ' AND EPIS.FLG_EHR IN (''N'') ' ||
                   ' AND PSA.ID_PATIENT (+)       = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION (+)   = :3 ' ||
                   ' AND CR.ID_PATIENT(+)         = PAT.ID_PATIENT ' || ' AND CR.ID_INSTITUTION(+)     = :4 ' || --I_PROF.INSTITUTION
                   ' AND EES.ID_EPISODE(+)        = EPIS.ID_EPISODE ' || ' AND EES.ID_EXTERNAL_SYS(+)   = :5 ' || --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :2, :1) '||
                   ' AND EES.ID_INSTITUTION(+)    = :6 ' || --||I_PROF.INSTITUTION||
                   ' AND PD.ID_PATIENT(+)  = PAT.ID_PATIENT  ' || ' AND d.flg_status(+) <> ' || xpl ||
                   g_disch_flg_status_reopen || xpl || chr(32) || --
                   ' AND d.flg_status(+) <> ' || xpl || g_disch_flg_status_cancel || xpl || chr(32) ||
                   ' AND PD.ID_DOC_TYPE(+) = :7 ' || l_where;
    
        --
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.software, i_prof.institution, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_PAT';
        OPEN o_pat FOR 'SELECT to_char(rownum, ''00000'') serv_rank,' || chr(32) ||
        --Sofia Mendes (7-12-2009) episode status in a function
         'pk_inp_grid.get_epis_status_icon(' || i_lang || ', ' || l_prof || ', wnd.ID_EPISODE,wnd.flg_status_e,wnd.flg_discharge) flg_status,' || chr(32) || 'pk_inp_grid.get_discharge_msg(' || i_lang || ',' || l_prof || ', wnd.id_episode, wnd.flg_discharge) discharge_type,' || chr(32) || 'wnd.* ' || chr(32) ||
        --
         'FROM (SELECT EPIS.ID_EPISODE ID_EPISODE,' || chr(32) || --
         'EPIS.ID_PATIENT ID_PATIENT,' || chr(32) || ----'V.ID_PATIENT ID_PATIENT,' || chr(32) || --
         'NVL(BD.DESC_BED, Pk_Translation.GET_TRANSLATION( ' || i_lang || ', BD.CODE_BED)) DESC_BED, ' || chr(32) || --
         'nvl(ro.desc_room, Pk_Translation.GET_TRANSLATION( ' || i_lang || ', RO.CODE_ROOM)) DESC_ROOM,' || chr(32) || --
        -- INP LMAIA 17-03-2009
        -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
         'DECODE(BD.CODE_BED, NULL, NULL, ' || --
         'nvl(pk_translation.get_translation(' || i_lang || ', dpt2.abbreviation),
                                 pk_translation.get_translation(' || i_lang || ', dpt2.code_department))) desc_service,' || chr(32) || --
        --
         'nvl((SELECT pk_translation.get_translation(' || i_lang || ', ty1.code_epis_type)
                   FROM episode epi1, epis_type ty1
                  WHERE epi1.id_epis_type = ty1.id_epis_type
                    AND epi1.id_episode = epis.id_prev_episode),
                 pk_translation.get_translation(' || i_lang || ', ''' || g_inp_epis_type_code || ''')) origin,' || --       
        -- END
         'pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'',PAT.GENDER,' || i_lang || ') GENDER,' || chr(32) || --             
         'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || chr(32) || --       
         'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by,' || 'pk_patphoto.get_pat_photo(' || i_lang || ', ' || 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), pat.id_patient, epis.id_episode, null) PHOTO,' || chr(32) || --                 
         'Pk_Translation.GET_TRANSLATION( ' || i_lang || ', DPT.CODE_DEPARTMENT)  DESC_SERVICE_NAME,' || chr(32) || --
         'Pk_Translation.GET_TRANSLATION( ' || i_lang || ', CLI.CODE_CLINICAL_SERVICE) DESC_SPECIALTY,' || chr(32) || --
         'Pk_Date_Utils.DT_CHR_TSZ( ' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ' )  DT_ADMISSION,' || chr(32) || --
         'pk_date_utils.dt_chr_tsz(' || i_lang || ', pk_discharge.get_discharge_date(' || i_lang || ',' || l_prof || ',EPIS.ID_EPISODE),' || l_prof || ') discharge_date,' || chr(32) ||
        -- José Brito 18/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
         'pk_visit.check_flg_cancel(' || i_lang || ', ' || l_prof || ',epis.id_episode) flg_cancel, ' || chr(32) || --
        --
         'pk_inp_grid.get_discharge_flg(' || i_lang || ',' || l_prof || ', EPIS.ID_EPISODE) flg_discharge,' || chr(32) || 'EPIS.FLG_STATUS flg_status_e' || chr(32) || ',
				 pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat,
				 pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat_to_sort,
					 pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_ndo,
					 pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_nd_icon,' || ' pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || l_prof || ', epis.id_episode,''' || l_hand_off_type || ''') resp_icons ' || --      
        -- INP AN add service/institution transfer icon 22-Mar-2011 [ALERT-28312]
         ', pk_service_transfer.get_transfer_status_icon(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE, NULL) desc_pat_transfer,' || -- 
         'decode(DISCH.flg_status, ' || xpl || g_epis_pend || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', nvl(DISCH.dt_med_tstz, DISCH.dt_pend_tstz), PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_pend_time_discharge,' || -- 
         'decode(DISCH.flg_status, ' || xpl || g_epis_active || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', DISCH.dt_med_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_time_discharge,' --
        || xpl || g_sysdate_char || xpl || ' dt_server,' --
        || l_disch_shortcut || ' disch_shortcut' || chr(32) || --   
         ' FROM EPISODE EPIS,' || chr(32) || 'EPIS_EXT_SYS EES,' || chr(32) || --
         'PATIENT PAT,' || chr(32) || 'EPIS_INFO EPO,' || chr(32) || --
         'DEPARTMENT DPT,' || chr(32) || 'DEPARTMENT DPT2,' || chr(32) || 'CLINICAL_SERVICE CLI,' || chr(32) || 'CLIN_RECORD CR ,' || chr(32) || --
         'PAT_DOC PD ,' || chr(32) || 'PAT_SOC_ATTRIBUTES PSA,' || chr(32) || 'DISCHARGE DCH,' || chr(32) || --
         'BED BD,' || chr(32) || 'ROOM RO,' || chr(32) || ----
         'PROFESSIONAL P, PROFESSIONAL PN ' || chr(32) || --
        -- INP AN add discharge icon 25-Mar-2011 [ALERT-28312]
         ', (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                      FROM discharge
                     WHERE flg_status IN (' || xpl || pk_edis_grid.g_discharge_flg_status_active || xpl || ', ' || xpl || pk_edis_grid.g_discharge_flg_status_pend || xpl || ')) DISCH ' || --
        -- José Brito 17/07/2008 Não mostrar episódios de OBS nos resultados da pesquisa de activos
         ' WHERE EPIS.ID_EPIS_TYPE = DECODE(PK_INP_EPISODE.CHECK_OBS_EPISODE(' || i_lang || ', ' || l_prof || ', EPIS.ID_EPISODE), 0, ' || g_inp_epis_type || ', NULL)' || chr(32) || --
        --
        -- LMAIA 10-03-2009 Previous function guarantee that OBS episodes are not returned in Inpatient ADM search.
        --' AND EPIS.FLG_TYPE            = ' || xpl || g_epis_flg_type_def || xpl || 
         'AND EPIS.ID_EPISODE     = EES.ID_EPISODE(+)' || chr(32) || --
         'AND DISCH.ID_EPISODE (+) = EPIS.ID_EPISODE' || chr(32) || --
         'AND EES.ID_INSTITUTION(+)=' || i_prof.institution || chr(32) || --
         'AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || chr(32) || --
         'AND CR.ID_INSTITUTION(+) =' || i_prof.institution || chr(32) || --
         'AND EPIS.ID_EPISODE      = DCH.ID_EPISODE(+)' || chr(32) || --
         'AND dch.flg_status(+) <> ' || xpl || g_disch_flg_status_reopen || xpl || chr(32) || --
         'AND dch.flg_status(+) <> ' || xpl || g_disch_flg_status_cancel || xpl || chr(32) || --          
        --         'AND ( DCH.FLG_STATUS IN (' || xpl || g_disch_flg_status_active || xpl || ', ' || xpl || g_disch_flg_status_pend || xpl || ') OR DCH.FLG_STATUS IS NULL ) ' || chr(32) || --
        --LMAIA 28-10-2008 (Os pendentes também deverão ser retornados)
         ' AND EPIS.FLG_STATUS          IN (' || xpl || g_epis_active || xpl || ', ' || xpl || g_epis_pend || xpl || ')' || chr(32) || --G_EPIS_ACTIVE e G_EPIS_PEND
        --  'AND EPIS.FLG_STATUS      = ' || xpl || g_epis_active || xpl || chr(32) || --
        --
        -- <DENORM_EPISODE_JOSE_BRITO>
        --
        --
         'AND EPIS.ID_PATIENT       = PAT.ID_PATIENT' || chr(32) || --
         'AND EPIS.ID_INSTITUTION = ' || i_prof.institution || chr(32) || --
        --
        -- <DENORM RicardoNunoAlmeida>
         'AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EPO.ID_SOFTWARE ' || 'AND EPIS.ID_EPISODE      = EPO.ID_EPISODE' || chr(32) || --
         'AND EPO.ID_BED           = BD.ID_BED(+)' || chr(32) || --
         'AND RO.ID_ROOM(+) = BD.ID_ROOM' || chr(32) || --
         'AND EPIS.FLG_EHR IN (''N'') ' || --
         'AND EES.ID_EXTERNAL_SYS(+) = ' || id_ext || chr(32) || --
         'AND PSA.ID_PATIENT(+)    = PAT.ID_PATIENT' || chr(32) || --
         'AND PSA.ID_INSTITUTION(+) = ' || i_prof.institution || chr(32) || --
         'AND P.ID_PROFESSIONAL(+) = EPO.ID_PROFESSIONAL' || chr(32) || --
         'AND PN.ID_PROFESSIONAL(+) = EPO.ID_FIRST_NURSE_RESP' || chr(32) || --        
         'AND EPIS.ID_DEPARTMENT    = DPT.ID_DEPARTMENT' || chr(32) || --
         'AND INSTR(DPT.FLG_TYPE(+), ' || xpl || 'I' || xpl || ') > 0' || chr(32) || ' AND PD.ID_PATIENT(+)   = PAT.ID_PATIENT ' || chr(32) || --
         'AND PD.ID_DOC_TYPE(+)  = ' || id_doc || chr(32) || --
         'AND EPIS.ID_CLINICAL_SERVICE = CLI.ID_CLINICAL_SERVICE' || chr(32) || --
        -- LMAIA 17-03-2009
         'AND DPT2.ID_DEPARTMENT(+) = RO.ID_DEPARTMENT' || chr(32) || --
        --END
         ' AND ROWNUM < ' || l_limit || --
        l_where || --
         ' ORDER BY EPIS.DT_BEGIN_TSTZ) wnd ';
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_ADM', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_PAT_CRITERIA_ACTIVE_ADM', o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PAT_CRITERIA_ACTIVE_ADM',
                                              o_error);
            pk_types.open_my_cursor(o_pat);
            RETURN FALSE;
    END get_pat_criteria_active_adm;

    -- ##########################################################################
    /******************************************************************************
    * Returns the registrar's search results for cancelled episodes in ALERT® Inpatient.
    * 
    * @param i_lang              Professional preferred language
    * @param i_id_sys_btn_crit   Search criteria ID's
    * @param i_crit_val          Search criteria values
    * @param i_instit            Institution to search
    * @param i_epis_type         Type of the episode
    * @param i_dt                Search date
    * @param i_prof              Professional info. 
    * @param i_prof_cat_type     Professional category
    * @param o_flg_show          
    * @param o_msg               
    * @param o_msg_title         
    * @param o_button            
    * @param o_epis_cancel       Results list
    * @param o_mess_no_result    Message to show when there's no results
    * @param o_error             Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito [based on GET_PAT_CRITERIA_ACTIVE_ADM by José Silva]
    * @version                 0.1
    * @since                   2008-Apr-23
    *
    ******************************************************************************/
    FUNCTION get_epis_cancelled
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(4000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(0500);
        l_mask_xx    VARCHAR2(0050);
        l_ret        BOOLEAN;
    
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
    
    BEGIN
    
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_inp_grid.g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        xpl       := '''';
        l_mask_xx := 'xxxxxxxxxxxxxx';
    
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
        --
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        l_prof := 'PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')';
    
        --
        id_doc := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        --ID_EPIS_TYPE 
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || ' FROM EPISODE EPIS, ' || 'EPIS_INFO EI, ' || --'EPIS_TYPE ET,' ||
                   'DEPARTMENT    DPT,' || 'PATIENT PAT,' || 'DISCHARGE D, ' || 'PROFESSIONAL P,' || 'SPECIALITY SP,' ||
                   'CLIN_RECORD CR, ' || 'CLINICAL_SERVICE CS,' || 'EPIS_EXT_SYS EES, ' || 'PAT_SOC_ATTRIBUTES PSA, ' ||
                   'PAT_DOC PD ' || ' WHERE EI.ID_SOFTWARE         = :1 ' || --I_PROF.SOFTWARE
                   ' AND EPIS.ID_DEPARTMENT        = DPT.ID_DEPARTMENT' ||
                   ' AND EPIS.ID_EPISODE          = EI.ID_EPISODE ' ||
                   ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' ||
                  --' AND ET.ID_EPIS_TYPE          = EPIS.ID_EPIS_TYPE ' || 
                   ' AND EPIS.ID_EPIS_TYPE = DECODE(PK_INP_EPISODE.CHECK_OBS_EPISODE(' || i_lang || ', ' || l_prof ||
                   ', EPIS.ID_EPISODE), 0, ' || g_inp_epis_type || ', NULL)' || chr(32) || --
                  --' AND EPIS.FLG_TYPE            = ' || xpl || g_epis_flg_type_def || xpl ||
                   ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE ' ||
                   ' AND EPIS.ID_INSTITUTION         = :2 ' || --I_PROF.INSTITUTION
                   ' AND EPIS.ID_PATIENT             = PAT.ID_PATIENT  ' ||
                   ' AND D.ID_EPISODE(+)          = EPIS.ID_EPISODE ' ||
                   ' AND P.ID_PROFESSIONAL(+)     = EI.ID_PROFESSIONAL ' || ' AND EPIS.FLG_STATUS          = ' || xpl ||
                   g_epis_canceled || xpl || ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY ' ||
                   ' AND PSA.ID_PATIENT (+)       = PAT.ID_PATIENT ' || ' AND PSA.ID_INSTITUTION (+)   = :3 ' ||
                   ' AND CR.ID_PATIENT(+)         = PAT.ID_PATIENT ' || ' AND CR.ID_INSTITUTION(+)     = :4 ' || --I_PROF.INSTITUTION
                   ' AND EES.ID_EPISODE(+)        = EPIS.ID_EPISODE ' || ' AND EES.ID_EXTERNAL_SYS(+)   = :5 ' || --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :2, :1) '||
                   ' AND EES.ID_INSTITUTION(+)    = :6 ' || --||I_PROF.INSTITUTION||
                   ' AND EPIS.FLG_EHR IN (''N'') ' || ' AND PD.ID_PATIENT(+)  = PAT.ID_PATIENT  ' ||
                   ' AND d.flg_status(+) <> ' || xpl || g_disch_flg_status_reopen || xpl || chr(32) || --
                   ' AND d.flg_status(+) <> ' || xpl || g_disch_flg_status_cancel || xpl || chr(32) || --                  
                   ' AND PD.ID_DOC_TYPE(+) = :7 ' || l_where;
        --
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.software, i_prof.institution, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_EPIS_CANCEL';
        OPEN o_epis_cancel FOR 'SELECT to_char(rownum, ''00000'') serv_rank,' || chr(32) ||
        --Sofia Mendes (7-12-2009) episode status in a function
         'pk_inp_grid.get_epis_status_icon(' || i_lang || ', ' || l_prof || ', wnd.ID_EPISODE,wnd.flg_status_e,wnd.flg_discharge) flg_status,' || chr(32) || 'pk_inp_grid.get_discharge_msg(' || i_lang || ',' || l_prof || ', wnd.id_episode, wnd.flg_discharge) discharge_type,' || chr(32) || 'wnd.* ' || chr(32) || 'FROM (SELECT EPIS.ID_EPISODE ID_EPISODE,' || chr(32) || --
         'EPIS.ID_PATIENT ID_PATIENT,' || chr(32) || 'NULL DESC_BED, ' || chr(32) || -- cancelled episodes must not have an associated bed
         'NULL DESC_ROOM,' || chr(32) || -- 
        -- INP LMAIA 17-03-2009
        -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
         'NULL desc_service, ' || chr(32) || --
         'Pk_Translation.GET_TRANSLATION( ' || i_lang || ', DPT.CODE_DEPARTMENT)  DESC_SERVICE_NAME,' || chr(32) || --
        --
         'nvl((SELECT pk_translation.get_translation(' || i_lang || ', ty1.code_epis_type)
                   FROM episode epi1, epis_type ty1
                  WHERE epi1.id_epis_type = ty1.id_epis_type
                    AND epi1.id_episode = epis.id_prev_episode),
                 pk_translation.get_translation(' || i_lang || ', ''' || g_inp_epis_type_code || ''')) origin,' || --
        -- END 
         'pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'',PAT.GENDER,' || i_lang || ') GENDER,' || chr(32) || --         
         'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || chr(32) || --
         'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by,' || 'pk_patphoto.get_pat_photo(' || i_lang || ', ' || 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), pat.id_patient, epis.id_episode, null) PHOTO,' || chr(32) || --
         'Pk_Translation.GET_TRANSLATION( ' || i_lang || ', CLI.CODE_CLINICAL_SERVICE) DESC_SPECIALTY,' || chr(32) || --
         'Pk_Date_Utils.DT_CHR_TSZ( ' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ' )  DT_ADMISSION,' || chr(32) || --        
         'pk_date_utils.dt_chr_tsz(' || i_lang || ', pk_discharge.get_discharge_date(' || i_lang || ',' || l_prof || ',EPIS.ID_EPISODE),' || l_prof || ') discharge_date,' || chr(32) ||
        --estado do episódio
        xpl || '|' || xpl || ' || ' || xpl || l_mask_xx || xpl || ' || ' || xpl || '|I|X|' || xpl || ' || ' || chr(32) || --
         'pk_sysdomain.get_img(' || i_lang || ',''INP_GRID_ADMIN_ICON'',''C'')' || ' FLG_STATUS, ' || chr(32) || --
         'EPIS.FLG_STATUS FLG_STATUS_E,' || chr(32) || --
         'pk_inp_grid.get_discharge_flg(' || i_lang || ',' || l_prof || ', EPIS.ID_EPISODE) flg_discharge,' || chr(32) || 'EPIS.DT_BEGIN_TSTZ, ' || chr(32) || --
         'pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat,' || --
         'pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat_to_sort,
					 pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_ndo,
					 pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_nd_icon, ' || ' pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || l_prof || ', epis.id_episode,''' || l_hand_off_type || ''') resp_icons, ' || --
        -- INP AN add service/institution transfer icon 22-Mar-2011 [ALERT-28312]
         'pk_service_transfer.get_transfer_status_icon(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE, NULL) desc_pat_transfer,' || --
         'decode(DISCH.flg_status, ' || xpl || g_epis_pend || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', nvl(DISCH.dt_med_tstz, DISCH.dt_pend_tstz), PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_pend_time_discharge,' || --
         'decode(DISCH.flg_status, ' || xpl || g_epis_active || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', DISCH.dt_med_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_time_discharge,' || -- 
        xpl || g_sysdate_char || xpl || ' dt_server,' || -- 
        l_disch_shortcut || ' disch_shortcut ' || chr(32) || --
         'FROM EPISODE EPIS,' || chr(32) || --
         'EPIS_EXT_SYS EES,' || chr(32) || --
         'PATIENT PAT,' || chr(32) || --
         'EPIS_INFO EPO,' || chr(32) || --
         'DEPARTMENT DPT,' || chr(32) || --
         'CLINICAL_SERVICE CLI,' || chr(32) || --
         'CLIN_RECORD CR ,' || chr(32) || --
         'PAT_DOC PD ,' || chr(32) || --
         'PAT_SOC_ATTRIBUTES PSA,' || chr(32) || --        
         'PROFESSIONAL P, PROFESSIONAL PN ' || chr(32) || --
        -- INP AN add discharge icon 25-Mar-2011 [ALERT-28312]
         ', (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                      FROM discharge
                     WHERE flg_status IN (' || xpl || pk_edis_grid.g_discharge_flg_status_active || xpl || ', ' || xpl || pk_edis_grid.g_discharge_flg_status_pend || xpl || ')) DISCH ' || --
         ' WHERE EPIS.ID_EPIS_TYPE = ' || g_inp_epis_type || chr(32) || --
         ' AND EPIS.ID_EPIS_TYPE = DECODE(PK_INP_EPISODE.CHECK_OBS_EPISODE(' || i_lang || ', ' || l_prof || ', EPIS.ID_EPISODE), 0, ' || g_inp_epis_type || ', NULL)' || chr(32) || --
         'AND EPIS.ID_EPISODE     = EES.ID_EPISODE(+)' || chr(32) || --
         'AND EES.ID_INSTITUTION(+)=' || i_prof.institution || chr(32) || --
         'AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || chr(32) || --
         'AND CR.ID_INSTITUTION(+) =' || i_prof.institution || chr(32) || --
         'AND DISCH.ID_EPISODE (+) = EPIS.ID_EPISODE' || chr(32) || --        
         'AND EPIS.FLG_EHR IN (''N'') ' || --        
         'AND EPIS.FLG_STATUS      = ' || xpl || g_epis_canceled || xpl || chr(32) || --
        -- <DENORM_EPISODE_JOSE_BRITO>
        --
         'AND EPIS.ID_PATIENT       = PAT.ID_PATIENT' || chr(32) || --
         'AND EPIS.ID_INSTITUTION = ' || i_prof.institution || chr(32) || --
        --
        --
        -- <DENORM RicardoNunoAlmeida>
         'AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EPO.ID_SOFTWARE ' || 'AND EPIS.ID_EPISODE      = EPO.ID_EPISODE' || chr(32) || --
        --
         'AND EPIS.ID_EPISODE      = EPO.ID_EPISODE' || chr(32) || --
         'AND EES.ID_EXTERNAL_SYS(+) = ' || id_ext || chr(32) || --
         'AND PSA.ID_PATIENT(+)    = PAT.ID_PATIENT' || chr(32) || --
         'AND PSA.ID_INSTITUTION(+) = ' || i_prof.institution || chr(32) || --
         'AND P.ID_PROFESSIONAL(+) = EPO.ID_PROFESSIONAL' || chr(32) || --
         'AND PN.ID_PROFESSIONAL(+) = EPO.ID_FIRST_NURSE_RESP' || chr(32) || --        
         'AND EPIS.ID_DEPARTMENT    = DPT.ID_DEPARTMENT(+)' || chr(32) || --
         'AND INSTR(DPT.FLG_TYPE(+), ' || xpl || 'I' || xpl || ') > 0' || chr(32) || ' AND PD.ID_PATIENT(+)   = PAT.ID_PATIENT ' || chr(32) || --
         'AND PD.ID_DOC_TYPE(+)  = ' || id_doc || chr(32) || --
         'AND EPIS.ID_CLINICAL_SERVICE = CLI.ID_CLINICAL_SERVICE(+)' || chr(32) || --
         ' AND ROWNUM < ' || l_limit || --
        l_where || --
         ' ORDER BY desc_service, desc_room, desc_bed) wnd ' || chr(32) || 'ORDER BY wnd.DT_BEGIN_TSTZ';
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_CANCELLED', o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_CANCELLED', o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN FALSE;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_CANCELLED',
                                              o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN FALSE;
    END get_epis_cancelled;

    --
    /******************************************************************************
    * Returns the physician's search results for cancelled episodes in ALERT® Inpatient.
    * 
    * @param i_lang              Professional preferred language
    * @param i_id_sys_btn_crit   Search criteria ID's
    * @param i_crit_val          Search criteria values
    * @param i_instit            Institution to search
    * @param i_epis_type         Type of the episode
    * @param i_dt                Search date
    * @param i_prof              Professional info. 
    * @param i_prof_cat_type     Professional category
    * @param o_flg_show          
    * @param o_msg               
    * @param o_msg_title         
    * @param o_button             
    * @param o_epis_cancel       Results list
    * @param o_mess_no_result    Message to show when there's no results
    * @param o_error             Error message
    * 
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  José Brito [based on GET_PAT_CRITERIA_ACTIVE_CLIN]
    * @version                 0.1
    * @since                   2008-Apr-24
    *
    ******************************************************************************/
    FUNCTION get_epis_cancelled_clin
    (
        i_lang            IN language.id_language%TYPE,
        i_id_sys_btn_crit IN table_number,
        i_crit_val        IN table_varchar,
        i_instit          IN institution.id_institution%TYPE,
        i_epis_type       IN schedule_outp.id_epis_type%TYPE,
        i_dt              IN VARCHAR2,
        i_prof            IN profissional,
        i_prof_cat_type   IN category.flg_type%TYPE,
        o_flg_show        OUT VARCHAR2,
        o_msg             OUT VARCHAR2,
        o_msg_title       OUT VARCHAR2,
        o_button          OUT VARCHAR2,
        o_epis_cancel     OUT pk_types.cursor_type,
        o_mess_no_result  OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_where      VARCHAR2(32000);
        v_where_cond VARCHAR2(32000);
        l_count      NUMBER;
        l_limit      sys_config.desc_sys_config%TYPE;
        aux_sql      VARCHAR2(32000);
        id_doc       sys_config.value%TYPE;
        id_ext       sys_config.value%TYPE;
        xpl          VARCHAR2(0050);
        l_prof       VARCHAR2(250);
        --
        l_prof_cat category.flg_type%TYPE;
        l_ret      BOOLEAN;
    
        CURSOR c_prof_cat IS
            SELECT c.flg_type
              FROM prof_cat pc, category c
             WHERE pc.id_category = c.id_category
               AND pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
    
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
    
    BEGIN
    
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => pk_inp_grid.g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        xpl            := '''';
        g_error        := 'INICIO:';
        o_flg_show     := 'N';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        g_error := 'L_LIMIT:';
        l_limit := pk_sysconfig.get_config('NUM_RECORD_SEARCH', i_prof);
        l_prof  := 'profissional(' || i_prof.id || ', ' || i_prof.institution || ', ' || i_prof.software || ')';
    
        g_error := 'GET PROF CAT';
        OPEN c_prof_cat;
        FETCH c_prof_cat
            INTO l_prof_cat;
        CLOSE c_prof_cat;
    
        --
        --Obtem mensagem a mostrar quando a pesquisa não devolver dados
        o_mess_no_result := pk_message.get_message(i_lang, 'COMMON_M015');
    
        l_where := NULL;
        --
    
        FOR i IN 1 .. i_id_sys_btn_crit.count
        LOOP
            --Lê critérios de pesquisa e preenche cláusula WHERE
            g_error      := 'SET WHERE';
            v_where_cond := NULL;
            --
            IF i_id_sys_btn_crit(i) IS NOT NULL
               AND i_crit_val(i) != '-1'
            THEN
            
                g_error := 'GET CRITERIA CONDITION:';
                IF NOT pk_search.get_criteria_condition(i_lang,
                                                        i_prof,
                                                        i_id_sys_btn_crit(i),
                                                        REPLACE(i_crit_val(i), '''', '%'),
                                                        v_where_cond,
                                                        o_error)
                THEN
                    RETURN FALSE;
                END IF;
                --
                g_error := 'SET L_WHERE';
                l_where := l_where || v_where_cond;
            END IF;
        END LOOP;
    
        g_error := 'SET WHERE 2';
        id_doc  := pk_sysconfig.get_config('DOC_TYPE_ID', i_prof.institution, i_prof.software);
        id_ext  := pk_sysconfig.get_config('ID_EXTERNAL_SYS', i_prof.institution, i_prof.software);
        --
        g_error := 'GET COUNT';
        aux_sql := 'SELECT COUNT(EPIS.ID_EPISODE) ' || ' FROM EPISODE EPIS, EPIS_INFO EI, PATIENT PAT,' ||
                   'DISCHARGE D, ' || --EPIS_TYPE ET,
                   'PROFESSIONAL P,SPECIALITY SP,CLIN_RECORD CR, DEPARTMENT DPT, CLINICAL_SERVICE CS,' ||
                   'EPIS_EXT_SYS EES, PAT_SOC_ATTRIBUTES PSA , PAT_DOC PD ' ||
                   ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE(+) ' ||
                   ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' ||
                  --' AND ET.ID_EPIS_TYPE=EPIS.ID_EPIS_TYPE ' || 
                   ' AND EI.ID_SOFTWARE= :1 ' || --I_PROF.SOFTWARE
                   ' AND EPIS.ID_INSTITUTION=:2 ' || --I_PROF.INSTITUTION
                   ' AND EPIS.ID_PATIENT=PAT.ID_PATIENT  ' || ' AND EPIS.ID_DEPARTMENT = DPT.ID_DEPARTMENT ' ||
                   ' AND EI.ID_SOFTWARE = :3 ' || --I_PROF.SOFTWARE
                   ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = EI.ID_SOFTWARE ' ||
                   ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
                   ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' || --
                   ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || '''' || --
                  --' AND EPIS.FLG_EHR IN (''N'') ' || 
                   ' AND EPIS.FLG_STATUS IN (' || xpl || g_epis_canceled || xpl || ') ' ||
                   ' AND P.ID_PROFESSIONAL(+) = EI.ID_PROFESSIONAL' || -- LMAIA 13-08-2008 (para que os episódios 'S' vindos do OUTP sejam apresentados
                   ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY ' || ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT ' ||
                   ' AND PSA.ID_INSTITUTION(+) = :4 ' || ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT ' ||
                   ' AND CR.ID_INSTITUTION(+) =:5 ' || --I_PROF.INSTITUTION
                   ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || ' AND EES.ID_EXTERNAL_SYS(+) = :6 ' || --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'', :2, :1) '||
                   ' AND EES.ID_INSTITUTION(+) = :7 ' || --||I_PROF.INSTITUTION||
                   ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT  ' || ' AND PD.ID_DOC_TYPE(+) = :8 ' || l_where;
    
        --
        g_error := 'GET EXECUTE IMMEDIATE';
        EXECUTE IMMEDIATE aux_sql
            INTO l_count
            USING i_prof.software, i_prof.institution, i_prof.software, i_prof.institution, i_prof.institution, id_ext, i_prof.institution, id_doc;
        --
        IF l_count > l_limit
        THEN
            RAISE pk_search.e_overlimit;
        END IF;
        --
        IF l_count = 0
        THEN
            RAISE pk_search.e_noresults;
        END IF;
    
        g_error := 'GET CURSOR O_EPIS_CANCEL';
        OPEN o_epis_cancel FOR 'SELECT to_char(rownum, ''00000'') serv_rank,' || chr(32) || 'wnd.* ' || chr(32) || 'FROM (SELECT DECODE( D.DT_MED_TSTZ, NULL, NULL, Pk_Message.GET_MESSAGE(' || i_lang || ', ''INP_MAIN_GRID_DISCHARGE_FLAG'')) FLAG_DISCHARGE, ' || --
         ' CR.NUM_CLIN_RECORD,EPIS.ID_EPISODE,PAT.ID_PATIENT, pk_sysdomain.get_domain(''PATIENT.GENDER.ABBR'',PAT.GENDER,' || i_lang || ') GENDER,  ' || --             
         'PK_PATIENT.GET_PAT_AGE(' || i_lang || ', PAT.dt_birth, pat.dt_deceased, pat.age, ' || i_prof.institution || ', ' || i_prof.software || ') PAT_AGE, ' || --
         'pk_patient.get_julian_age(' || i_lang || ', pat.dt_birth, pat.age) pat_age_for_order_by,' || 'pk_patphoto.get_pat_photo(' || i_lang || ', ' || 'profissional(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), pat.id_patient, epis.id_episode, null) PHOTO,' || --
         'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', CS.CODE_CLINICAL_SERVICE) CONS_TYPE, ' || --
         'P.NICK_NAME NAME_PROF,PN.NICK_NAME NAME_NURSE, ' || '''' || g_sysdate_char || ''' DT_SERVER, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || l_prof || ') DT_BEGIN, ' || --
         'PK_DATE_UTILS.DATE_SEND_TSZ(' || i_lang || ', EI.DT_FIRST_OBS_TSTZ, ' || l_prof || ') DT_FIRST_OBS, ' || --
         'PK_DATE_UTILS.GET_ELAPSED_TSZ(' || i_lang || ',EPIS.DT_BEGIN_TSTZ, CURRENT_TIMESTAMP) DATE_SEND,' || --
         'PK_DATE_UTILS.DATE_CHAR_HOUR_TSZ(' || i_lang || ', EPIS.DT_BEGIN_TSTZ, ' || i_prof.institution || ', ' || i_prof.software || ') DT_EFECTIV, ' || --
         'NULL FLG_TEMP, ' || --
         'NULL DESC_TEMP, ' || --
         'LPAD(TO_CHAR(SD.RANK), 6, ''0'')||SD.IMG_NAME  IMG_TRANSP,' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.DRUG_PRESC) DESC_DRUG_PRESC, ' || --
        -- INP LMAIA 17-03-2009
        -- INPATIENT Grid's reformulation in FIX 2.4.3.21
        -- 'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.INTERVENTION) DESC_INTERV_PRESC,  ' || --
        -- 'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.MONITORIZATION) DESC_MONITORIZATION,' || --
         'pk_grid.get_prioritary_task(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
				  pk_grid.get_prioritary_task(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
				         pk_grid.get_prioritary_task( ' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
                           pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
                             epis.id_visit,''' || pk_inp_grid.g_task_interv || ''',''' || l_prof_cat || '''),                                               
                             pk_inp_grid.get_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                             ''' || pk_prof_utils.get_prof_profile_template(i_prof) || ''',
                           pk_grid.visit_grid_task_str_nc(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),
                                                          
                                                          epis.id_visit,
                                                          ''' || pk_inp_grid.g_task_monitor || ''',''' || l_prof_cat || '''))
                                                          , NULL, ' || g_pl || l_prof_cat || g_pl || '),
						    pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.NURSE_ACTIVITY)
								, NULL, ' || g_pl || l_prof_cat || g_pl || '),
				    pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ''' || pk_inp_grid.g_task_edu || ''',''' || l_prof_cat || '''), NULL, ' || g_pl || l_prof_cat || g_pl || ')	
				 	desc_monit_interv_presc, ' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.MOVEMENT) DESC_MOVEMENT,' || --
         'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_analysis || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') desc_analysis_req, ' || --
         'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_exam || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') desc_exam_req, ' || --
         'pk_grid.visit_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.id_visit, ' || g_pl || g_task_harvest || g_pl || ', ' || g_pl || l_prof_cat || g_pl || ') DESC_HARVEST, ' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.POSITIONING)          DESC_POSITIONING,' || --
         'pk_inp_grid.get_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), 
         pk_prof_utils.get_prof_profile_template(PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), 
         pk_inp_hidrics_pbl.get_hidrics_reg(' || i_lang || ',PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '),epis.id_visit), null) desc_hidrics_reg,' ||
        
         'pk_grid.convert_grid_task_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.SCALE_VALUE)          DESC_SCALE_VALUE,' || --
         'pk_grid.convert_grid_task_dates_to_str(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), GT.NURSE_ACTIVITY)       DESC_NURSE_ACTIVITY,' || --
         'PK_INP_GRID.GET_DIAGNOSIS_GRID( ' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE ) DESC_DIAGNOSIS,' || --
         'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', SP.CODE_SPECIALITY) DESC_SPEC_PROF, ' || --
         'PK_TRANSLATION.GET_TRANSLATION(' || i_lang || ', SN.CODE_SPECIALITY) DESC_SPEC_NURSE, ' || --
        -- INP LMAIA 17-03-2009
        -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
         'NULL DESC_SERVICE, ' || --
         'nvl((SELECT pk_translation.get_translation(' || i_lang || ', ty1.code_epis_type)
                   FROM episode epi1, epis_type ty1
                  WHERE epi1.id_epis_type = ty1.id_epis_type
                    AND epi1.id_episode = epis.id_prev_episode),
                 pk_translation.get_translation(' || i_lang || ', ''' || g_inp_epis_type_code || ''')) origin,' || --
        -- END
         'NULL DESC_BED, ' || --
         'NULL DESC_ROOM, ' || --
         'EPIS.FLG_STATUS FLG_STATUS_E,' || --
        --jose silva 19-03-2007 valores de defeito para pacientes sem serviço
         ' NVL((DPT.RANK*100000),0)+99   RANK,' || --
         'EPIS.DT_BEGIN_TSTZ, ' || --
         ' pk_patient.get_pat_name(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat, ' || --
         ' pk_patient.get_pat_name_to_sort(' || i_lang || ', ' || l_prof || ', EPIS.id_patient, EPIS.id_episode) name_pat_to_sort,
					 pk_adt.get_pat_non_disc_options(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_ndo,
					 pk_adt.get_pat_non_disclosure_icon(' || i_lang || ', ' || l_prof || ', EPIS.id_patient) pat_nd_icon, ' || --
         ' pk_hand_off_api.get_resp_icons(' || i_lang || ', ' || l_prof || ', epis.id_episode,''' || l_hand_off_type || ''') resp_icons,' ||
        -- INP AN add service/institution transfer icon 22-Mar-2011 [ALERT-28312]
         'pk_service_transfer.get_transfer_status_icon(' || i_lang || ', PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || '), EPIS.ID_EPISODE, NULL) desc_pat_transfer,' || --
         'decode(DISCH.flg_status, ' || xpl || g_epis_pend || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', nvl(DISCH.dt_med_tstz, DISCH.dt_pend_tstz), PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_pend_time_discharge,' || --
         'decode(DISCH.flg_status, ' || xpl || g_epis_active || xpl || ', pk_date_utils.date_send_tsz(' || i_lang || ', DISCH.dt_med_tstz, PROFISSIONAL(' || i_prof.id || ',' || i_prof.institution || ',' || i_prof.software || ')), NULL) desc_time_discharge,' || --
        l_disch_shortcut || ' disch_shortcut' || chr(32) || --
         ' FROM EPISODE EPIS, EPIS_INFO EI,  PATIENT PAT, ' || ' DISCHARGE D, ' || 'PROFESSIONAL P, SPECIALITY SP,' || 'PROFESSIONAL PN, SPECIALITY SN,' || --
         'DEPARTMENT DPT, ' || 'CLIN_RECORD CR, CLINICAL_SERVICE CS, ' || --
         ' EPIS_EXT_SYS EES,' || --
         'PAT_SOC_ATTRIBUTES PSA, PAT_DOC PD, GRID_TASK GT, SYS_DOMAIN SD ' || --ROOM RO, BED BD'
        -- INP AN add discharge icon 25-Mar-2011 [ALERT-28312]
         ', (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                      FROM discharge
                     WHERE flg_status IN (' || xpl || pk_edis_grid.g_discharge_flg_status_active || xpl || ', ' || xpl || pk_edis_grid.g_discharge_flg_status_pend || xpl || ')) DISCH ' || --
         ' WHERE EPIS.ID_EPISODE = EI.ID_EPISODE (+)' || --
         ' AND EPIS.ID_CLINICAL_SERVICE = CS.ID_CLINICAL_SERVICE ' || --
         ' AND EI.ID_SOFTWARE=' || i_prof.software || --
         ' AND DPT.ID_DEPARTMENT = EPIS.ID_DEPARTMENT' || --
         ' AND EPIS.ID_INSTITUTION=' || i_prof.institution || --
         ' AND EPIS.ID_PATIENT=PAT.ID_PATIENT ' || --
         ' AND EI.Id_Professional = P.ID_PROFESSIONAL(+) ' || ' AND pk_episode.get_soft_by_epis_type(EPIS.id_epis_type, EPIS.ID_INSTITUTION) = ' || i_prof.software || ' AND D.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_cancel || '''' || --
         ' AND D.FLG_STATUS (+)<>''' || pk_discharge_core.g_disch_status_reopen || '''' || --
         ' AND SP.ID_SPECIALITY(+) = P.ID_SPECIALITY' || --
         ' AND PN.ID_PROFESSIONAL(+)=EI.ID_FIRST_NURSE_RESP ' || --
         ' AND SN.ID_SPECIALITY(+) = PN.ID_SPECIALITY' || --
         ' AND EPIS.FLG_STATUS IN (' || g_pl || g_epis_canceled || g_pl || ')' || --
         ' AND PSA.ID_PATIENT (+) = PAT.ID_PATIENT' || --
         ' AND PSA.ID_INSTITUTION (+) = ' || i_prof.institution || --
         ' AND CR.ID_PATIENT(+) = PAT.ID_PATIENT' || --
         ' AND CR.ID_INSTIT_ENROLED(+) = ' || i_prof.institution || --
         ' AND CR.ID_INSTITUTION(+) =' || i_prof.institution || --
         ' AND DISCH.ID_EPISODE (+) = EPIS.ID_EPISODE' || chr(32) || --
         ' AND SD.VAL(+)=EI.FLG_STATUS' || --
         ' AND SD.CODE_DOMAIN(+)=''EPIS_INFO.FLG_STATUS''' || --
         ' and sd.domain_owner(+) = ' || '''' || pk_sysdomain.k_default_schema || '''' || ' AND SD.ID_LANGUAGE(+) = ' || i_lang || --
         ' AND EES.ID_EPISODE(+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_INSTITUTION(+) = ' || i_prof.institution || --
         ' AND GT.ID_EPISODE (+) = EPIS.ID_EPISODE ' || --
         ' AND EES.ID_EXTERNAL_SYS(+) = ' || id_ext ||
        --PK_SYSCONFIG.GET_CONFIG(''ID_EXTERNAL_SYS'','||I_PROF.INSTITUTION||', '||I_PROF.SOFTWARE||' ) '||
         ' AND PD.ID_PATIENT(+) = PAT.ID_PATIENT ' || --
         ' AND PD.ID_DOC_TYPE(+) = ' || id_doc || --
         ' AND ROWNUM < ' || l_limit || -- 
        l_where || --
         ' ORDER BY desc_service, desc_room, desc_bed) wnd ' || chr(32) || 'ORDER BY wnd.DT_BEGIN_TSTZ';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN pk_search.e_overlimit THEN
            l_ret := pk_search.overlimit_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_CANCELLED_CLIN', o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN FALSE;
        
        WHEN pk_search.e_noresults THEN
            l_ret := pk_search.noresult_handler(i_lang, i_prof, g_package_name, 'GET_EPIS_CANCELLED_CLIN', o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN l_ret;
        
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_CANCELLED_CLIN',
                                              o_error);
            pk_types.open_my_cursor(o_epis_cancel);
            RETURN FALSE;
    END get_epis_cancelled_clin;

-- **********************************************************************************
BEGIN

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

    g_epis_active   := 'A';
    g_epis_inactive := 'I';
    g_epis_canceled := 'C';
    g_epis_pend     := 'P'; -- LMAIA INPATIENT 28-10-2008

    --jose silva 27-03-2007 nova variavel global
    g_doc_active := 'A';

    g_pl := '''';

    --
    g_diag_flg_type := 'D';
    --
    g_epis_diag_co  := 'F';
    g_inp_epis_type := 5;

    g_status_movement_t := 'T';

    g_cat_doctor := 'D';
    g_cat_nurse  := 'N';

    g_epis_flg_type_def := 'D';

END pk_inp_search;
/
