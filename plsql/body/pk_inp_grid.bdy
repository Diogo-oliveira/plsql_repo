/*-- Last Change Revision: $Rev: 2027258 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:41:39 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_inp_grid AS

    FUNCTION get_diagnosis_grid
    (
        i_lang            IN NUMBER,
        i_id_professional IN NUMBER,
        i_id_institution  IN NUMBER,
        i_id_software     IN NUMBER,
        i_id_episode      IN NUMBER
    ) RETURN VARCHAR2 IS
	
        l_return VARCHAR2(4000);
    BEGIN
    
        l_return := get_diagnosis_grid(i_lang, profissional(i_id_professional, i_id_institution, 11), i_id_episode);
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diagnosis_grid;

    /******************************************************************************/
    FUNCTION get_diagnosis_grid
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_episode IN NUMBER
    ) RETURN VARCHAR2 IS
    
        --JOSE SILVA 12-03-2007 novas variaveis locais
        l_c_dia pk_types.cursor_type;
        l_ret   BOOLEAN;
        TYPE t_l_diagnosis_name IS TABLE OF VARCHAR2(4000);
        l_diagnosis_name t_l_diagnosis_name;
        TYPE t_l_flg_status IS TABLE OF epis_diagnosis.flg_status%TYPE;
        l_flg_status t_l_flg_status;
        TYPE t_l_dt_epis_diagnosis_str IS TABLE OF VARCHAR2(50);
        l_dt_epis_diagnosis_str t_l_dt_epis_diagnosis_str;
        l_rowcount              NUMBER;
        l_count                 NUMBER;
        l_err_struct            t_error_out;
    
        x_return VARCHAR2(4000);
        error_get_epis_diagnosis EXCEPTION;
    BEGIN
    
        --JOSE SILVA 12-03-2007 chamar a função get_epis_diagnosis em vez de definir o select do cursor
        l_ret := pk_inp_episode.get_epis_diagnosis(i_lang, i_prof, i_id_episode, l_c_dia, l_err_struct);
        IF l_ret = FALSE
        THEN
            RAISE error_get_epis_diagnosis;
        END IF;
    
        FETCH l_c_dia BULK COLLECT
            INTO l_flg_status, l_diagnosis_name, l_dt_epis_diagnosis_str;
        l_rowcount := l_c_dia%ROWCOUNT;
        CLOSE l_c_dia;
    
        l_count := 0;
        LOOP
            l_count := l_count + 1;
            IF x_return IS NOT NULL
            THEN
                x_return := x_return || ', ' || l_diagnosis_name(l_count);
            ELSE
                x_return := l_diagnosis_name(l_count);
            END IF;
        
            EXIT WHEN l_count = l_rowcount;
        END LOOP;
    
        RETURN x_return;
    
    EXCEPTION
        --JOSE SILVA 09-03-2007 nova excepção
        WHEN error_get_epis_diagnosis THEN
            RETURN NULL;
        WHEN OTHERS THEN
            RETURN NULL;
    END get_diagnosis_grid;
    --##############################################################################

    /******************************************************************************
    NAME: GET_ALL_INPATIENTS
    CREATION INFO: CARLOS FERREIRA 2006/09/18
    GOAL: GET INTERNMENTS ACCORDING TO PARAMETER.
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    * Dependencies: Reports team
    *********************************************************************************/
    FUNCTION get_all_inpatients
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_id_patient IN NUMBER,
        i_flg_which  IN VARCHAR2,
        o_grid       OUT pk_types.cursor_type,
        o_anamnesis  OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_internal_error EXCEPTION;
    BEGIN
    
        OPEN o_grid FOR
            SELECT epi.id_episode,
                   epi.id_visit id_visit,
                   pk_translation.get_translation(i_lang, dpt.code_department) || chr(32) || '(' || /*chr(32) ||*/
                   nvl(pk_translation.get_translation(i_lang, cli.code_clinical_service), '...') || /*chr(32) ||*/
                   ')' desc_specialty,
                   NULL desc_diagnosis,
                   pk_inp_util.least_length(pk_translation.get_translation(i_lang, ist.code_institution),
                                            ist.abbreviation,
                                            25) desc_institution,
                   pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_begin,
                   --Sofia Mendes(3-12-2009): create function to the discharge date
                   pk_date_utils.dt_chr_tsz(i_lang,
                                            pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode),
                                            i_prof) dt_discharge,
                   epi.flg_status,
                   pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epi.id_episode) desc_diagnosis,
                   --Sofia Mendes(3-12-2009): create function to the discharge_type
                   get_discharge_msg(i_lang, i_prof, epi.id_episode, NULL) discharge_type,
                   -- END
                   decode(epi.flg_status,
                          g_epis_flg_status_active,
                          pk_sysdomain.get_img(i_lang, 'INP_INTERNMENT.ACTIVE', g_epis_flg_status_active), -- 'ONCOURSE'),
                          g_epis_flg_status_temp,
                          pk_sysdomain.get_img(i_lang, 'INP_INTERNMENT.ACTIVE', g_epis_flg_status_temp), --'ONCOURSE'),
                          g_epis_flg_status_canceled,
                          pk_sysdomain.get_img(i_lang, 'INP_INTERNMENT.CANCELED', g_epis_flg_status_canceled), --'CANCELED'),
                          g_epis_flg_status_inactive,
                          pk_sysdomain.get_img(i_lang, 'INP_INTERNMENT.ENDED', g_epis_flg_status_inactive)) img,
                   --SM:
                   nvl(r.desc_room, pk_translation.get_translation(i_lang, r.code_room)) AS desc_room,
                   nvl(b.desc_bed, pk_translation.get_translation(i_lang, b.code_bed)) AS desc_bed,
                   
                   CASE
                        WHEN EXISTS (SELECT *
                                FROM schedule_sr ssr
                               WHERE ssr.id_episode = (SELECT e.id_episode
                                                         FROM episode e
                                                        WHERE e.id_visit = epi.id_visit
                                                          AND e.id_epis_type = g_sr_epis_type
                                                          AND rownum = 1)) THEN
                         pk_alert_constant.g_yes
                        ELSE
                         pk_alert_constant.g_no
                    END AS has_surgery,
                   epi.id_prev_episode,
                   epi.flg_compulsory,
                   pk_sysdomain.get_domain(i_lang => i_lang, i_val => epi.flg_compulsory, i_code_dom => 'YES_NO') desc_flg_compulsory,
                   decode(epi.id_compulsory_reason,
                          NULL,
                          '',
                          -1,
                          pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, epi.id_compulsory_reason) ||
                          ' - ' || epi.compulsory_reason,
                          pk_api_multichoice.get_multichoice_option_desc(i_lang, i_prof, epi.id_compulsory_reason)) desc_id_compulsory_reason
            -- END
              FROM episode epi
             INNER JOIN department dpt
                ON epi.id_department = dpt.id_department
             INNER JOIN clinical_service cli
                ON epi.id_clinical_service = cli.id_clinical_service
             INNER JOIN institution ist
                ON epi.id_institution = ist.id_institution
               AND ist.id_institution = i_prof.institution
             INNER JOIN epis_info ei
                ON epi.id_episode = ei.id_episode
              LEFT OUTER JOIN room r
                ON ei.id_room = r.id_room
              LEFT OUTER JOIN bed b
                ON ei.id_bed = b.id_bed
             WHERE epi.id_patient = i_id_patient
               AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_scheduled)
               AND epi.id_epis_type = g_inp_epis_type
               AND ((nvl(i_flg_which, 'ALL') = 'ALL') OR
                   (nvl(i_flg_which, 'ALL') = 'CUR' AND epi.flg_status = g_epis_active) OR
                   (nvl(i_flg_which, 'ALL') = 'PRV' AND epi.flg_status != g_epis_active))
            --NEW SM
             ORDER BY epi.flg_status DESC, epi.dt_begin_tstz DESC;
    
        g_error := 'CALL pk_clinical_info.get_anamnesis_pat for id_patient: ' || i_id_patient;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_clinical_info.get_anamnesis_pat(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_id_patient   => i_id_patient,
                                                  i_id_epis_type => g_inp_epis_type,
                                                  i_flg_which    => i_flg_which,
                                                  o_anamnesis    => o_anamnesis,
                                                  o_error        => o_error)
        THEN
            RAISE l_internal_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_ALL_PATIENTS',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            pk_types.open_my_cursor(o_anamnesis);
            RETURN FALSE;
    END get_all_inpatients;
    -- ##################################################################################################

    FUNCTION get_grid_all_pat_aux
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        /******************************************************************************
        OBJECTIVO:   GRELHA DO AUXILIAR
        PARAMETROS:
        ENTRADA:
                I_LANG - LÍNGUA REGISTADA COMO PREFERÊNCIA DO PROFISSIONAL
                I_PROF - ID DO PROF Q ACEDE
        
        SAIDA:  O_GRID - ARRAY
                O_ERROR - ERRO
        
        CRIAÇÃO: SS 2006/11/08
        NOTAS:
        *********************************************************************************/
    
        l_prof_cat          category.flg_type%TYPE;
        l_date_lesser_limit TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_hand_off_type sys_config.value%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        g_error        := 'GET G_SYSDATE';
        g_sysdate      := SYSDATE;
        g_sysdate_tstz := current_timestamp;
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, g_sysdate_tstz, i_prof);
        --
        g_error := 'GET CURSOR O_GRID';
        --
        l_prof_cat := pk_edis_list.get_prof_cat(i_prof);
    
        -- LMAIA INPATIENT 28-10-2008
        l_date_lesser_limit := pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                               current_timestamp,
                                                                                               NULL),
                                                              1);
        --
        OPEN o_grid FOR
            SELECT pat.id_patient,
                   pk_sysdomain.get_domain(g_cf_pat_gender_abbr, pat.gender, i_lang) gender,
                   epis.id_episode,
                   epis.id_visit id_visit,
                   pk_date_utils.date_send_tsz(i_lang, epis.dt_begin_tstz, i_prof) dt_begin,
                   pk_patient.get_pat_age(i_lang,
                                          pat.dt_birth,
                                          pat.dt_deceased,
                                          pat.age,
                                          i_prof.institution,
                                          i_prof.software) pat_age,
                   pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, -- campo para ordenação unicamente
                   pk_date_utils.date_char_hour_tsz(i_lang, epis.dt_begin_tstz, i_prof.institution, i_prof.software) dt_efectiv,
                   pk_date_utils.get_elapsed_tsz(i_lang, epis.dt_begin_tstz, g_sysdate_tstz) date_send,
                   nvl(nvl(ro.desc_room_abbreviation, pk_translation.get_translation(i_lang, ro.code_abbreviation)),
                       nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room))) desc_room,
                   nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                   decode(bd.code_bed,
                          NULL,
                          NULL,
                          nvl(pk_translation.get_translation(i_lang, dpt.abbreviation),
                              pk_translation.get_translation(i_lang, dpt.code_department))) desc_service,
                   pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs,
                   lpad(to_char(sd.rank), g_six, g_zero_varchar) || sd.img_name img_transp,
                   pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, ei.id_episode, NULL) photo,
                   'N' flg_temp,
                   g_sysdate_char dt_server,
                   decode(epis.flg_status, g_epis_active, '', '') desc_temp,
                   pk_grid.convert_grid_task_str(i_lang, i_prof, gt.drug_transp) desc_drug_req, --SS: TAREFA DE TRANSPORTE DE MEDICAMENTOS (NÃO EXISTE NO PK_EDIS_GRID)
                   pk_grid.convert_grid_task_dates_to_str(i_lang, i_prof, gt.movement) desc_movement,
                   pk_grid.visit_grid_task_str(i_lang, i_prof, epis.id_visit, g_task_harvest, l_prof_cat) desc_harvest,
                   gt.hemo_req,
                   gt.supplies desc_supplies,
                   dpt.rank dep_rank,
                   ro.rank room_rank,
                   bd.rank bed_rank,
                   nvl2(bd.id_bed, g_one, g_zero) allocated,
                   pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat,
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, epis.id_patient, epis.id_episode) name_pat_to_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
                   -- Display number of responsible PHYSICIANS for the episode, 
                   -- if institution is using the multiple hand-off mechanism,
                   -- along with the name of the main responsible for the patient.
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 g_show_in_grid)
                      FROM dual) name_prof,
                   -- Only display the name of the responsible nurse, for all hand-off mechanisms
                   pk_prof_utils.get_nickname(i_lang, ei.id_first_nurse_resp) name_nurse,
                   -- Display text in tooltips
                   -- 1) Responsible physician(s)
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_doc,
                                                                 epis.id_episode,
                                                                 ei.id_professional,
                                                                 l_hand_off_type,
                                                                 g_show_in_tooltip)
                      FROM dual) name_prof_tooltip,
                   -- 2) Responsible nurse
                   (SELECT pk_hand_off_core.get_responsibles_str(i_lang,
                                                                 i_prof,
                                                                 pk_alert_constant.g_cat_type_nurse,
                                                                 epis.id_episode,
                                                                 ei.id_first_nurse_resp,
                                                                 l_hand_off_type,
                                                                 g_show_in_tooltip)
                      FROM dual) name_nurse_tooltip,
                   pk_hand_off_api.get_resp_icons(i_lang, i_prof, epis.id_episode, l_hand_off_type) resp_icons
              FROM epis_info ei
             INNER JOIN episode epis
                ON ei.id_episode = epis.id_episode
             INNER JOIN patient pat
                ON epis.id_patient = pat.id_patient
              LEFT OUTER JOIN professional p
                ON ei.id_professional = p.id_professional
              LEFT OUTER JOIN professional pn
                ON ei.id_first_nurse_resp = pn.id_professional
             INNER JOIN grid_task gt
                ON epis.id_episode = gt.id_episode
               AND (gt.movement IS NOT NULL OR gt.harvest IS NOT NULL OR gt.drug_transp IS NOT NULL OR
                   gt.supplies IS NOT NULL OR gt.hemo_req IS NOT NULL)
             INNER JOIN sys_domain sd
                ON ei.flg_status = sd.val
               AND sd.code_domain = g_cf_epis_status
               AND sd.domain_owner = pk_sysdomain.k_default_schema
               AND sd.id_language = i_lang
              LEFT OUTER JOIN bed bd
                ON ei.id_bed = bd.id_bed
              LEFT OUTER JOIN room ro
                ON bd.id_room = ro.id_room
              LEFT OUTER JOIN department dpt
                ON ro.id_department = dpt.id_department
             WHERE (epis.flg_ehr = g_flg_ehr_normal OR
                   epis.flg_ehr = g_flg_ehr_scheduled AND epis.dt_begin_tstz < l_date_lesser_limit)
               AND pk_episode.get_soft_by_epis_type(epis.id_epis_type, i_prof.institution) = i_prof.software
               AND epis.id_epis_type = g_inp_epis_type
               AND epis.id_institution = i_prof.institution
               AND epis.flg_status = g_epis_flg_status_active
               AND ei.id_dep_clin_serv IN (SELECT dcs1.id_dep_clin_serv
                                             FROM prof_dep_clin_serv pdc1
                                            INNER JOIN dep_clin_serv dcs1
                                               ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                            INNER JOIN department dpt
                                               ON dcs1.id_department = dpt.id_department
                                              AND pdc1.id_institution = i_prof.institution
                                              AND instr(dpt.flg_type, 'I') > 0
                                            WHERE pdc1.flg_status = g_selected)
             ORDER BY epis.dt_begin_tstz,
                      allocated,
                      dep_rank,
                      desc_service,
                      room_rank,
                      desc_room,
                      bed_rank,
                      desc_bed,
                      name_pat_to_sort;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_GRID_ALL_PAT_AUX',
                                                       o_error);
        
            pk_alert_exceptions.reset_error_state;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        
    END;

    /********************************************************************************************
    * Returns episode status icon.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    * @param i_epis_flg_status       episode status   
    * @param i_flg_dsch_status       discharge status   
    *
    * @return                        Status icon
    *
    * @author                        Sofia Mendes (separated from get_grid_all_pat_adm frunction)
    * @version                       2.5.0.7
    * @since                         07/12/2009
    ********************************************************************************************/
    FUNCTION get_epis_status_icon
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_epis_flg_status IN episode.flg_status%TYPE,
        i_flg_dsch_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_msg   VARCHAR2(4000);
    
        l_mask_xx               VARCHAR2(50);
        l_inp_grid_admin_icon_i VARCHAR2(0500);
        l_inp_grid_admin_icon_t VARCHAR2(0500);
        l_inp_grid_admin_icon_d VARCHAR2(0500);
        l_inp_grid_admin_icon_p VARCHAR2(0500);
        l_inp_grid_admin_icon_a VARCHAR2(0500);
        l_inp_grid_admin_icon_c VARCHAR2(0500);
        l_inp_grid_admin_icon_r VARCHAR2(0500);
        l_created               VARCHAR2(1 CHAR);
        l_bed_mandatory         VARCHAR2(1 CHAR) := pk_sysconfig.get_config('INP_ADMISSION_DISCH_BED_MANDATORY', i_prof);
        l_reg_admission         VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_has_bed               VARCHAR2(1 CHAR);
    BEGIN
        l_mask_xx               := '';
        l_inp_grid_admin_icon_i := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'I') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'I', i_lang);
        l_inp_grid_admin_icon_t := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'T') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'T', i_lang);
        l_inp_grid_admin_icon_d := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'D') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'D', i_lang);
        l_inp_grid_admin_icon_p := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'P') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'P', i_lang);
        l_inp_grid_admin_icon_a := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'A') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'A', i_lang);
        l_inp_grid_admin_icon_c := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'C') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'C', i_lang);
    
        --l_inp_grid_admin_icon_r := '|' || l_mask_xx || '|I|X|WaitingForAdministrativeProcessIcon';
        l_inp_grid_admin_icon_r := '|I|||' || pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'R') || '||||||||' ||
                                   pk_sysdomain.get_domain('INP_GRID_ADMIN_ICON', 'R', i_lang);
    
        SELECT pk_discharge.check_created_epis_on_disch(i_id_episode, e.id_prev_episode),
               pk_bmng.check_bed_inp_department(ei.id_bed)
          INTO l_created, l_has_bed
          FROM episode e
          JOIN epis_info ei
            ON e.id_episode = ei.id_episode
         WHERE e.id_episode = i_id_episode;
    
        IF l_created = pk_alert_constant.g_yes
           AND l_bed_mandatory = pk_alert_constant.g_yes
           AND l_has_bed = pk_alert_constant.g_no
        THEN
            l_reg_admission := pk_alert_constant.g_yes;
        END IF;
        g_error := 'CALC DISCHARGE TYPE with id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        SELECT decode(i_epis_flg_status,
                       g_epis_flg_status_canceled,
                       l_inp_grid_admin_icon_c,
                       decode((SELECT COUNT(0)
                                FROM episode e
                               WHERE e.id_episode = i_id_episode
                                 AND e.dt_begin_tstz > current_timestamp),
                              0,
                              CASE
                                  WHEN i_flg_dsch_status IS NULL
                                       OR i_flg_dsch_status = g_discharge_schedule_flg THEN
                                   (decode((SELECT COUNT(0)
                                             FROM movement m
                                            WHERE m.id_episode = i_id_episode
                                              AND m.flg_status = g_status_movement_t),
                                           1,
                                           l_inp_grid_admin_icon_t,
                                           decode((SELECT COUNT(*)
                                                    FROM transfer_institution ti
                                                   WHERE ti.id_episode = i_id_episode
                                                     AND ti.id_institution_dest = i_prof.institution
                                                     AND ti.flg_status = pk_transfer_institution.g_transfer_inst_transp),
                                                  0,
                                                  --When user is not in the destiny institution
                                                  decode((SELECT COUNT(*) --User is in origin institution?
                                                           FROM transfer_institution ti
                                                          WHERE ti.id_episode = i_id_episode
                                                            AND ti.id_institution_origin = i_prof.institution
                                                            AND ti.flg_status = pk_transfer_institution.g_transfer_inst_transp),
                                                         0,
                                                         decode(l_reg_admission,
                                                                pk_alert_constant.g_yes,
                                                                l_inp_grid_admin_icon_r,
                                                                l_inp_grid_admin_icon_i), --When user is not in the origin institution
                                                         l_inp_grid_admin_icon_t), --When user is in the origin institution
                                                  l_inp_grid_admin_icon_a))) --When user is in the destiny institution
                              --When episode has discharge defined
                                  ELSE
                                   decode(i_flg_dsch_status,
                                          g_disch_flg_status_active,
                                          l_inp_grid_admin_icon_d, --Active discharge
                                          l_inp_grid_admin_icon_p) --Pendent discharge
                              END,
                              --When episode is in the future
                              l_inp_grid_admin_icon_a)) flg_status
          INTO l_msg
          FROM dual;
    
        RETURN l_msg;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHARGE_MSG',
                                              l_error);
            RETURN NULL;
    END get_epis_status_icon;

    /******************************************************************************
    NAME: GET_GRID_ALL_PAT_ADM
    CREATION INFO: CARLOS FERREIRA 2006/12/09
    GOAL: GET INTERNMENTS ACCORDING TO PARAMETER.
    NOTAS:
    
    PARAMETERS:
    -------------------------------------------------------------------------------
    | PARAMETER NAME   |   DATATYPE             | I/O |      DESCRIPTION          |
    -------------------------------------------------------------------------------
    -------------------------------------------------------------------------------
    
    *********************************************************************************/
    FUNCTION get_grid_all_pat_adm
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_epis_c_display NUMBER(24);
        l_hand_off_type  sys_config.value%TYPE;
        l_disch_shortcut sys_shortcut.id_sys_shortcut%TYPE;
        l_shortcut_error EXCEPTION;
        l_bed_mandatory VARCHAR2(1 CHAR) := pk_sysconfig.get_config('INP_ADMISSION_DISCH_BED_MANDATORY', i_prof);
    
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        -- Obter período definido pela instituição para mostrar episódios cancelados
        l_epis_c_display := pk_sysconfig.get_config(g_cf_canc_epis_time, i_prof);
    
        g_sysdate_char := pk_date_utils.date_send_tsz(i_lang, current_timestamp, i_prof);
    
        --Get shortcut for Register Discharge
        g_error := 'Call PK_ACCESS.GET_ID_SHORTCUT';
        pk_alertlog.log_debug(g_error);
        IF NOT pk_access.get_id_shortcut(i_lang        => i_lang,
                                         i_prof        => i_prof,
                                         i_intern_name => g_discharge_shortcut,
                                         o_id_shortcut => l_disch_shortcut,
                                         o_error       => o_error)
        THEN
            RAISE l_shortcut_error;
        END IF;
    
        --l_comm := 'OPEN CURSOR ALL PATIENTS';
        OPEN o_grid FOR
            SELECT to_char(rownum, g_sort_mask) serv_rank,
                   wnd.*,
                   --Sofia Mendes(3-12-2009): create function to the discharge_type
                   get_discharge_msg(i_lang, i_prof, wnd.id_episode, wnd.flg_discharge) discharge_type,
                   decode((SELECT COUNT(*)
                             FROM episode e
                            WHERE e.id_episode = wnd.id_episode
                              AND e.dt_begin_tstz > current_timestamp),
                           0,
                           CASE
                               WHEN wnd.flg_discharge IS NULL
                                    OR wnd.flg_discharge = g_discharge_schedule_flg THEN
                                (decode((SELECT COUNT(*)
                                          FROM movement m
                                         WHERE m.id_episode = wnd.id_episode
                                           AND m.flg_status = g_status_movement_t),
                                        1,
                                        'T',
                                        decode((SELECT COUNT(*)
                                                 FROM transfer_institution ti
                                                WHERE ti.id_episode = wnd.id_episode
                                                  AND ti.id_institution_dest = i_prof.institution
                                                  AND ti.flg_status = pk_transfer_institution.g_transfer_inst_transp),
                                               0,
                                               decode((SELECT COUNT(*) --User is in origin institution?
                                                        FROM transfer_institution ti
                                                       WHERE ti.id_episode = wnd.id_episode
                                                         AND ti.id_institution_origin = i_prof.institution
                                                         AND ti.flg_status = pk_transfer_institution.g_transfer_inst_transp),
                                                      0,
                                                      decode(pk_discharge.check_created_epis_on_disch(wnd.id_episode,
                                                                                                      wnd.id_prev_episode),
                                                             pk_alert_constant.g_yes,
                                                             decode(pk_bmng.check_bed_inp_department(wnd.id_bed),
                                                                    pk_alert_constant.g_yes,
                                                                    decode(l_bed_mandatory, pk_alert_constant.g_yes, 'R', 'I')),
                                                             'I'), --When user is not in the origin institution
                                                      'T'),
                                               'A')))
                               ELSE
                                decode(wnd.flg_dsch_status, g_disch_flg_status_active, 'D', 'P')
                           END,
                           'A') flg_status_letter,
                   get_epis_status_icon(i_lang, i_prof, wnd.id_episode, wnd.flg_status_e, wnd.flg_discharge) flg_status,
                   --inter-hospital transfer
                   desc_pat_transfer,
                   desc_pend_time_discharge,
                   desc_time_discharge,
                   g_sysdate_char           dt_server,
                   l_disch_shortcut         disch_shortcut
              FROM (SELECT epi.id_episode id_episode,
                           epi.id_prev_episode id_prev_episode,
                           epo.id_bed id_bed,
                           epi.id_visit id_visit,
                           epi.id_patient id_patient,
                           nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                           nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                           -- INP LMAIA 17-03-2009
                           -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
                            decode(bd.code_bed,
                                   NULL,
                                   NULL,
                                   nvl(pk_translation.get_translation(i_lang, dpb.abbreviation),
                                       pk_translation.get_translation(i_lang, dpb.code_department))) desc_service,
                            --pk_translation.get_translation(i_lang, dpt.code_department) desc_service,
                            -- END
                            pk_sysdomain.get_domain(g_cf_pat_gender_abbr, pat.gender, i_lang) gender,
                            pk_patient.get_pat_age(i_lang,
                                                   pat.dt_birth,
                                                   pat.dt_deceased,
                                                   pat.age,
                                                   i_prof.institution,
                                                   i_prof.software) pat_age,
                            pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, -- campo para ordenação unicamente
                            pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epi.id_episode, NULL) photo,
                            pk_translation.get_translation(i_lang, dpt.code_department) desc_service_name,
                            pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_specialty,
                            pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof.institution, i_prof.software) dt_admission,
                            pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                            pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_service_specialty,
                            dpb.rank dep_rank,
                            ro.rank room_rank,
                            bd.rank bed_rank,
                            nvl2(bd.id_bed, g_one, g_zero) allocated,
                            -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                            pk_visit.check_flg_cancel(i_lang, i_prof, epi.id_episode) flg_cancel,
                            -- José Brito 22/04/2008 Devolver FLG_STATUS para indicar estado do episódio
                            epi.flg_status flg_status_e,
                            -- Forçar os cancelados a surgir em último
                            decode(epi.flg_status, g_epis_flg_status_canceled, g_one, g_zero) status_rank,
                            --Sofia Mendes(3-12-2009): create function to the discharge date
                            pk_date_utils.dt_chr_tsz(i_lang,
                                                     pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode),
                                                     i_prof) discharge_date,
                            get_discharge_flg(i_lang, i_prof, epi.id_episode) flg_discharge,
                            epo.flg_dsch_status,
                            pk_patient.get_pat_name(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat,
                            pk_patient.get_pat_name_to_sort(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat_to_sort,
                            pk_adt.get_pat_non_disc_options(i_lang, i_prof, epi.id_patient) pat_ndo,
                            pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epi.id_patient) pat_nd_icon,
                            pk_hand_off_api.get_resp_icons(i_lang, i_prof, epi.id_episode, l_hand_off_type) resp_icons,
                            --Icons to show in inter-hospital transfer patients to show on the grid (Antonio.Neto [ALERT-28312])
                            pk_service_transfer.get_transfer_status_icon(i_lang, i_prof, epi.id_episode, NULL) desc_pat_transfer,
                            -- pending discharge
                            decode(d.flg_status,
                                   pk_edis_grid.g_discharge_flg_status_pend,
                                   pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof),
                                   NULL) desc_pend_time_discharge,
                            -- discharge
                            decode(d.flg_status,
                                   pk_edis_grid.g_discharge_flg_status_active,
                                   pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof),
                                   NULL) desc_time_discharge,
                            pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_order,
                            epo.flg_unknown temp_episode,
                            pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_admission_str,
                            decode(pk_service_transfer.get_transfer_status_icon(i_lang, i_prof, epi.id_episode, NULL),
                                   NULL,
                                   0,
                                   decode(bd.id_bed, NULL, 1, 0)) rank_transfer
                     -- END
                     
                       FROM episode epi
                      INNER JOIN patient pat
                         ON epi.id_patient = pat.id_patient
                      INNER JOIN epis_info epo
                         ON epi.id_episode = epo.id_episode
                     -- JOSE SILVA 15-03-2007 outer join para mostrar também os pacientes sem sala
                       LEFT OUTER JOIN bed bd
                         ON epo.id_bed = bd.id_bed
                       LEFT OUTER JOIN room ro
                         ON bd.id_room = ro.id_room
                     
                      INNER JOIN department dpt
                         ON epi.id_department = dpt.id_department
                        AND instr(dpt.flg_type, 'I') > 0
                     
                      INNER JOIN clinical_service cli
                         ON epi.id_clinical_service = cli.id_clinical_service
                       LEFT OUTER JOIN department dpb
                         ON ro.id_department = dpb.id_department
                       LEFT OUTER JOIN (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                                         FROM discharge
                                        WHERE flg_status IN (pk_edis_grid.g_discharge_flg_status_active,
                                                             pk_edis_grid.g_discharge_flg_status_pend)) d
                         ON epi.id_episode = d.id_episode
                      WHERE epi.id_epis_type = g_inp_epis_type
                           -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                           -- Luís Maia 28-10-2008.
                           -- Nas grelhas de trabalho doINPATIENT deverão ser visualizados os episódios com flg_ehr IN ('N', 'S'),
                           -- de forma a que se possa trabalhar sobre os episódios NORMAIS e os episódios AGENDADOS (no passado).
                        AND (epi.flg_ehr = g_flg_ehr_normal)
                           -- José Brito 21/04/2008: Mostrar episódios activos e os cancelados dentro do período definido pela instituição
                        AND epi.flg_status IN (g_epis_flg_status_active, g_epis_flg_status_canceled)
                           -- INPATIENT LMAIA 28-08-2008
                        AND (epi.flg_status = g_epis_flg_status_active OR
                            pk_date_utils.add_days_to_tstz(epi.dt_cancel_tstz, l_epis_c_display / 24) >
                            current_timestamp AND epi.dt_cancel_tstz IS NOT NULL)
                           --END
                        AND epi.dt_begin_tstz < pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                                current_timestamp,
                                                                                                                NULL),
                                                                               1)
                           
                        AND epi.id_institution = i_prof.institution
                           
                           -- JOSE SILVA 15-03-2007 verificar as especialidades alocadas ao administrativo
                        AND epo.id_dep_clin_serv IN (SELECT dcs1.id_dep_clin_serv
                                                       FROM prof_dep_clin_serv pdc1
                                                      INNER JOIN dep_clin_serv dcs1
                                                         ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                                      INNER JOIN department dpt
                                                         ON dpt.id_department = dcs1.id_department
                                                        AND dpt.id_institution = i_prof.institution
                                                        AND instr(dpt.flg_type, 'I') > 0
                                                        AND instr(dpt.flg_type, 'O') < 1
                                                      WHERE pdc1.flg_status = g_selected
                                                        AND pdc1.id_professional = i_prof.id)
                     
                     --List of inter-hospital transfer patients to show on the grid (Antonio.Neto [ALERT-28312])
                     UNION ALL
                     --
                     SELECT epi.id_episode id_episode,
                            epi.id_prev_episode id_prev_episode,
                            epo.id_bed id_bed,
                            epi.id_visit id_visit,
                            epi.id_patient id_patient,
                            nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                            nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                            -- INP LMAIA 17-03-2009
                            -- Created this field to return the bed and room service during INP grid's reformulation in FIX 2.4.3.21
                           decode(bd.code_bed,
                                  NULL,
                                  NULL,
                                  nvl(pk_translation.get_translation(i_lang, dpb.abbreviation),
                                      pk_translation.get_translation(i_lang, dpb.code_department))) desc_service,
                           --pk_translation.get_translation(i_lang, dpt.code_department) desc_service,
                           -- END
                           pk_sysdomain.get_domain(g_cf_pat_gender_abbr, pat.gender, i_lang) gender,
                           pk_patient.get_pat_age(i_lang,
                                                  pat.dt_birth,
                                                  pat.dt_deceased,
                                                  pat.age,
                                                  i_prof.institution,
                                                  i_prof.software) pat_age,
                           pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, -- campo para ordenação unicamente
                           pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epi.id_episode, NULL) photo,
                           pk_translation.get_translation(i_lang, dpt.code_department) desc_service_name,
                           pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_specialty,
                           pk_date_utils.dt_chr_tsz(i_lang, epi.dt_begin_tstz, i_prof.institution, i_prof.software) dt_admission,
                           pk_translation.get_translation(i_lang, dpt.code_department) || '|' ||
                           pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_service_specialty,
                           dpb.rank dep_rank,
                           ro.rank room_rank,
                           bd.rank bed_rank,
                           nvl2(bd.id_bed, g_one, g_zero) allocated,
                           -- José Brito 22/04/2008 Devolver FLG_CANCEL que indica se o episódio é temporário e se pode ser cancelado
                           pk_visit.check_flg_cancel(i_lang, i_prof, epi.id_episode) flg_cancel,
                           -- José Brito 22/04/2008 Devolver FLG_STATUS para indicar estado do episódio
                           epi.flg_status flg_status_e,
                           -- Forçar os cancelados a surgir em último
                           decode(epi.flg_status, g_epis_flg_status_canceled, g_one, g_zero) status_rank,
                           --Sofia Mendes(3-12-2009): create function to the discharge date
                           pk_date_utils.dt_chr_tsz(i_lang,
                                                    pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode),
                                                    i_prof) discharge_date,
                           get_discharge_flg(i_lang, i_prof, epi.id_episode) flg_discharge,
                           epo.flg_dsch_status,
                           pk_patient.get_pat_name(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat,
                           pk_patient.get_pat_name_to_sort(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat_to_sort,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epi.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epi.id_patient) pat_nd_icon,
                           pk_hand_off_api.get_resp_icons(i_lang, i_prof, epi.id_episode, l_hand_off_type) resp_icons,
                           --Icons to show in inter-hospital transfer patients to show on the grid (Antonio.Neto [ALERT-28312])
                           pk_service_transfer.get_transfer_status_icon(i_lang,
                                                                        i_prof,
                                                                        epi.id_episode,
                                                                        pk_service_transfer.g_transfer_flg_hospital_h) desc_pat_transfer,
                           -- pending discharge
                           decode(d.flg_status,
                                  pk_edis_grid.g_discharge_flg_status_pend,
                                  pk_date_utils.date_send_tsz(i_lang, nvl(d.dt_med_tstz, d.dt_pend_tstz), i_prof),
                                  NULL) desc_pend_time_discharge,
                           -- discharge
                           decode(d.flg_status,
                                  pk_edis_grid.g_discharge_flg_status_active,
                                  pk_date_utils.date_send_tsz(i_lang, d.dt_med_tstz, i_prof),
                                  NULL) desc_time_discharge,
                           pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_order,
                           epo.flg_unknown temp_episode,
                           pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_admission_str,
                           decode(pk_service_transfer.get_transfer_status_icon(i_lang,
                                                                               i_prof,
                                                                               epi.id_episode,
                                                                               pk_service_transfer.g_transfer_flg_hospital_h),
                                  NULL,
                                  0,
                                  decode(bd.id_bed, NULL, 1, 0)) rank_transfer
                    
                    -- END
                      FROM transfer_institution ti
                     INNER JOIN episode epi
                        ON ti.id_episode = epi.id_episode
                     INNER JOIN patient pat
                        ON epi.id_patient = pat.id_patient
                     INNER JOIN epis_info epo
                        ON epi.id_episode = epo.id_episode
                    -- JOSE SILVA 15-03-2007 outer join para mostrar também os pacientes sem sala
                      LEFT OUTER JOIN bed bd
                        ON epo.id_bed = bd.id_bed
                      LEFT OUTER JOIN room ro
                        ON bd.id_room = ro.id_room
                    
                     INNER JOIN department dpt
                        ON epi.id_department = dpt.id_department
                       AND instr(dpt.flg_type, 'I') > 0
                    
                      LEFT OUTER JOIN clinical_service cli
                        ON epi.id_clinical_service = cli.id_clinical_service
                      LEFT OUTER JOIN department dpb
                        ON ro.id_department = dpb.id_department
                      LEFT OUTER JOIN (SELECT flg_status, dt_med_tstz, dt_pend_tstz, id_episode
                                        FROM discharge
                                       WHERE flg_status IN (pk_edis_grid.g_discharge_flg_status_active,
                                                            pk_edis_grid.g_discharge_flg_status_pend)) d
                        ON epi.id_episode = d.id_episode
                     WHERE epi.id_epis_type = g_inp_epis_type
                          -- Sílvia Freitas 27/05/2008 Filtrar os episódios para não trazer do tipo EHR
                          -- Luís Maia 28-10-2008.
                          -- Nas grelhas de trabalho doINPATIENT deverão ser visualizados os episódios com flg_ehr IN ('N', 'S'),
                          -- de forma a que se possa trabalhar sobre os episódios NORMAIS e os episódios AGENDADOS (no passado).
                       AND (epi.flg_ehr = g_flg_ehr_normal)
                          -- José Brito 21/04/2008: Mostrar episódios activos e os cancelados dentro do período definido pela instituição
                       AND epi.flg_status IN (g_epis_flg_status_active, g_epis_flg_status_canceled)
                          -- INPATIENT LMAIA 28-08-2008
                       AND (epi.flg_status = g_epis_flg_status_active OR
                           pk_date_utils.add_days_to_tstz(epi.dt_cancel_tstz, l_epis_c_display / 24) >
                           current_timestamp AND epi.dt_cancel_tstz IS NOT NULL)
                          --END
                       AND epi.dt_begin_tstz < pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(i_prof,
                                                                                                               current_timestamp,
                                                                                                               NULL),
                                                                              1)
                          
                          -- JOSE SILVA 15-03-2007 verificar as especialidades alocadas ao administrativo
                       AND ti.id_dep_clin_serv IN (SELECT dcs1.id_dep_clin_serv
                                                     FROM prof_dep_clin_serv pdc1
                                                    INNER JOIN dep_clin_serv dcs1
                                                       ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
                                                    INNER JOIN department dpt
                                                       ON dpt.id_department = dcs1.id_department
                                                      AND dpt.id_institution = i_prof.institution
                                                      AND instr(dpt.flg_type, 'I') > 0
                                                      AND instr(dpt.flg_type, 'O') < 1
                                                    WHERE pdc1.flg_status = g_selected
                                                      AND pdc1.id_professional = i_prof.id)
                       AND (ti.id_institution_dest = i_prof.institution AND
                           ti.flg_status = pk_transfer_institution.g_transfer_inst_transp)
                     ORDER BY status_rank,
                              rank_transfer            DESC,
                              desc_time_discharge      NULLS LAST,
                              desc_pend_time_discharge NULLS LAST,
                              allocated,
                              dep_rank,
                              desc_service,
                              room_rank,
                              desc_room,
                              bed_rank,
                              desc_bed,
                              name_pat_to_sort) wnd;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_GRID_PAT_ADM',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
        
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
        
    END get_grid_all_pat_adm;
    -- ###########################################################################

    /********************************************************************************************
    *  Get grid task str. For the prescription profile the monitoring and positioning shortcuts
    *  should not be returned 
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids    
    * @param I_STR                     GRID_TASK text
    * @param I_POSITION                Position of the date field
    * @param i_id_profile_template     Profile template identifier
    
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *    
    * @author                          Sofia Mendes
    * @version                         2.6.0.1
    * @since                           22-10-2009
    **********************************************************************************************/
    FUNCTION get_grid_task_str
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_str                 IN VARCHAR2,
        i_position            IN NUMBER DEFAULT g_grid_task_def_pos
    ) RETURN VARCHAR2 IS
        l_aux2 VARCHAR2(3000);
    BEGIN
        g_error := 'CALL PK_GRID.CONVERT_GRID_TASK_STR';
        pk_alertlog.log_debug(g_error);
    
        l_aux2 := pk_grid.convert_grid_task_dates_to_str(i_lang => i_lang, i_prof => i_prof, i_str => i_str);
    
        IF (i_id_profile_template = g_phy_presc_profile)
        THEN
            g_error := 'CALL PK_UTILS.STR_SPLIT_FIRST FOR ' || l_aux2;
            pk_alertlog.log_debug(g_error);
            l_aux2 := pk_utils.str_split_first(i_list => l_aux2, i_delim => g_grid_task_delimiter);
        END IF;
    
        RETURN l_aux2;
    EXCEPTION
        WHEN OTHERS THEN
            alertlog.pk_alertlog.log_error(SQLERRM);
            RETURN NULL;
    END get_grid_task_str;

    /********************************************************************************************
    * Checks if the episode has a discharge. 
    * If professional is doctor checks if there is a doctor discharge
    * If professional is nurse checks if there is a nurse discharge
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    *
    * @RETURN  'Y' - there is a discharge; 'N' - otherwise
    * @author  Sofia Mendes
    * @version 2.5.0.7
    * @since   28-10-2009
    **********************************************************************************************/
    FUNCTION check_discharge_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN discharge.flg_type_disch%TYPE IS
        l_flg_type_disch discharge.flg_type_disch%TYPE;
        l_flg_status     discharge.flg_status%TYPE;
        l_category       category.id_category%TYPE := NULL;
        l_status         VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
    
        g_error := 'GET discharge type with id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT flg_type_disch, flg_status
              INTO l_flg_type_disch, l_flg_status
              FROM (SELECT d.*, row_number() over(PARTITION BY d.id_episode ORDER BY d.dt_med_tstz DESC) rn
                      FROM discharge d
                     WHERE d.id_episode = i_id_episode)
             WHERE rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_type_disch := NULL;
        END;
    
        IF (l_flg_type_disch IS NOT NULL AND l_flg_status = pk_discharge.g_disch_flg_active)
        THEN
            g_error := 'GET prof category; i_id_prof: ' || i_prof.id;
            pk_alertlog.log_debug(g_error);
            SELECT pc.id_category
              INTO l_category
              FROM prof_cat pc
             INNER JOIN category ct
                ON pc.id_category = ct.id_category
               AND ct.flg_available = pk_alert_constant.g_yes
             WHERE pc.id_professional = i_prof.id
               AND pc.id_institution = i_prof.institution;
        
            IF (l_category = 1 AND l_flg_type_disch = pk_discharge.g_doctor)
            THEN
                l_status := pk_alert_constant.g_no;
            ELSIF (l_category = 2 AND l_flg_type_disch = pk_discharge.g_nurse)
            THEN
                l_status := pk_alert_constant.g_no;
            ELSE
                l_status := pk_alert_constant.g_yes;
            END IF;
        ELSE
            l_status := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_status;
    END check_discharge_type;

    /********************************************************************************************
    * Get the schedule status.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    * @param   i_id_schedule Schedule identifier
    *
    * @RETURN  EPISODe schedule flg_status
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   28-Jun-2011
    **********************************************************************************************/
    FUNCTION get_wl_sch_status
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN wtl_epis.id_episode%TYPE,
        i_id_schedule IN wtl_epis.id_schedule%TYPE
    ) RETURN wtl_epis.flg_status%TYPE IS
        l_flg_status wtl_epis.flg_status%TYPE;
    BEGIN
    
        g_error := 'GET wtl_epis sch flg_status with id_episode: ' || i_id_episode || ' i_id_schedule: ' ||
                   i_id_schedule;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT we.flg_status
              INTO l_flg_status
              FROM wtl_epis we
             WHERE we.id_episode = i_id_episode
               AND we.id_schedule = i_id_schedule
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                BEGIN
                    g_error := 'GET wtl_epis sch flg_status from history with id_episode';
                    pk_alertlog.log_debug(g_error);
                    SELECT flg_status
                      INTO l_flg_status
                      FROM (SELECT weh.flg_status
                              FROM wtl_epis_hist weh
                             WHERE weh.id_episode = i_id_episode
                               AND weh.id_schedule = i_id_schedule
                             ORDER BY weh.dt_wtl_epis_hist DESC)
                     WHERE rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        l_flg_status := NULL;
                END;
        END;
    
        RETURN l_flg_status;
    END get_wl_sch_status;

    /********************************************************************************************
    * Get the schedule status.
    *
    * @param   I_LANG language associated to the professional executing the request
    * @param   I_PROF  professional, institution and software ids
    * @param   I_ID_EPISODE Episode identifier    
    *
    * @RETURN  EPISODe schedule flg_status
    * @author  Sofia Mendes
    * @version 2.6.1.1
    * @since   28-Jun-2011
    **********************************************************************************************/
    FUNCTION get_sch_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN wtl_epis.id_episode%TYPE
    ) RETURN wtl_epis.flg_status%TYPE IS
        l_flg_status wtl_epis.flg_status%TYPE;
    BEGIN
        g_error := 'GET wtl_epis flg_status with id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT we.flg_status
              INTO l_flg_status
              FROM wtl_epis we
             WHERE we.id_episode = i_id_episode
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_status := NULL;
        END;
    
        RETURN l_flg_status;
    END get_sch_status;

    /********************************************************************************************
    *  Returns the information to fill the patients grid. Only the scheduled episodes are shown.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_obs                 OBS or non OBS services
    * @param o_grid                    Episodes information and the assotiated tasks
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         
    * @since                           20-10-2009
    **********************************************************************************************/
    FUNCTION get_scheduled_episodes
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_profile IN VARCHAR2,
        i_dcs     table_number,
        i_view    view_option.screen_identifier%TYPE,
        o_grid    OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_date_lesser_limit TIMESTAMP WITH LOCAL TIME ZONE;
        l_date_upper_limit  TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_current_date_trunc TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_mask_xx               VARCHAR2(0050);
        l_inp_grid_admin_icon_p VARCHAR2(0050);
        l_inp_grid_admin_icon_d VARCHAR2(0050);
        l_inp_grid_admin_icon_i VARCHAR2(0050);
        l_inp_grid_admin_icon_n VARCHAR2(0050);
        l_inp_grid_admin_icon_a VARCHAR2(0050);
        l_inp_grid_admin_icon_c VARCHAR2(0050);
        l_hand_off_type         sys_config.value%TYPE;
    
        l_scheduler_exists sys_config.value%TYPE;
        l_canc_msg         sys_message.desc_message%TYPE;
        l_rescheduled_msg  sys_message.desc_message%TYPE;
        l_no_show_msg      sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'CALL pk_hand_off_core.get_hand_off_type';
        pk_alertlog.log_debug(g_error);
        pk_hand_off_core.get_hand_off_type(i_lang, i_prof, l_hand_off_type);
    
        l_mask_xx               := 'xxxxxxxxxxxxxx';
        l_inp_grid_admin_icon_i := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'I');
        l_inp_grid_admin_icon_a := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'A');
        l_inp_grid_admin_icon_p := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'P');
        l_inp_grid_admin_icon_d := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'D');
        l_inp_grid_admin_icon_n := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'N');
        l_inp_grid_admin_icon_c := '|' || l_mask_xx || '|I|X|' ||
                                   pk_sysdomain.get_img(i_lang, 'INP_GRID_ADMIN_ICON', 'C');
    
        pk_date_utils.set_dst_time_check_off;
        g_error := 'TRUNC CURRENT_TIMESTAMP';
        pk_alertlog.log_debug(g_error);
        l_current_date_trunc := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp, NULL);
    
        IF (i_view = 'AG1')
        THEN
            --agendados para hoje
            g_error := 'LESSER DATE IS TRUCATED CURRENT_TIMESTAMP';
            pk_alertlog.log_debug(g_error);
            l_date_lesser_limit := l_current_date_trunc;
        
            g_error := 'UPPER DATE IS TRUCATED CURRENT_TIMESTAMP+1';
            pk_alertlog.log_debug(g_error);
            l_date_upper_limit := pk_date_utils.add_days_to_tstz(l_current_date_trunc, 1);
        ELSE
            -- agendados no futuro
            g_error := 'LESSER DATE IS TRUCATED CURRENT_TIMESTAMP+1';
            pk_alertlog.log_debug(g_error);
            l_date_lesser_limit := pk_date_utils.add_days_to_tstz(l_current_date_trunc, 1);
        
            g_error := 'UPPER DATE IS TRUCATED CURRENT_TIMESTAMP PLUS CONFIGURED NUMBER OF DAYS';
            pk_alertlog.log_debug(g_error);
            l_date_upper_limit := pk_date_utils.add_days_to_tstz(l_date_lesser_limit,
                                                                 pk_sysconfig.get_config('EPISODES_TIMEFRAME', i_prof));
        END IF;
        pk_date_utils.set_dst_time_check_on;
    
        g_error := 'CALL PK_DATE_UTILS.DATE_SEND TO CURRENT_TIMESTAMP';
        pk_alertlog.log_debug(g_error);
    
        l_scheduler_exists := pk_sysconfig.get_config(i_code_cf => 'ADMISSION_SCHEDULER_EXISTS', i_prof => i_prof);
    
        IF (l_scheduler_exists = pk_alert_constant.g_yes)
        THEN
            l_canc_msg        := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_SCH_GRID_M001');
            l_rescheduled_msg := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_SCH_GRID_M002');
            l_no_show_msg     := pk_message.get_message(i_lang => i_lang, i_code_mess => 'INP_SCH_GRID_M003');
        
            g_error := 'OPEN O_GRID CURSOR;  REGISTRAR';
            pk_alertlog.log_debug(g_error);
            OPEN o_grid FOR
                SELECT wnd2.*,
                       CASE
                            WHEN wnd2.flg_ehr = g_flg_ehr_scheduled THEN
                             CASE
                                 WHEN wtl_epis_flg_status IN
                                      (pk_wtl_prv_core.g_wtl_epis_st_no_show, pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule) THEN
                                  decode(cancel_reason_desc,
                                         NULL,
                                         REPLACE(l_canc_msg, '@1', ''),
                                         REPLACE(l_canc_msg, '@1', '(' || cancel_reason_desc || ')'))
                                 ELSE
                                  NULL
                             END
                        END cancel_desc
                  FROM (SELECT to_char(rownum, g_sort_mask) serv_rank,
                               wnd.*,
                               get_discharge_msg(i_lang, i_prof, wnd.id_episode, wnd.flg_discharge) discharge_type,
                               
                               CASE
                                    WHEN wnd.flg_ehr = g_flg_ehr_normal THEN
                                     decode(flg_discharge,
                                            g_discharge_flg_status_p,
                                            l_inp_grid_admin_icon_p,
                                            g_discharge_flg_status_a,
                                            l_inp_grid_admin_icon_d,
                                            l_inp_grid_admin_icon_i)
                                    ELSE
                                     CASE
                                         WHEN sch_status = 'C'
                                              AND wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_no_show THEN
                                          l_inp_grid_admin_icon_n
                                         WHEN sch_status = 'C'
                                              AND wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule THEN
                                          l_inp_grid_admin_icon_c
                                         ELSE
                                          CASE
                                              WHEN wnd.flg_ehr = g_flg_ehr_scheduled THEN
                                               l_inp_grid_admin_icon_a
                                          
                                          END
                                     END
                                END AS flg_status,
                               --campo para a formatação (esbatido dos cancelados)
                               CASE
                                    WHEN wnd.flg_ehr = g_flg_ehr_normal THEN
                                     g_rgt_flg_status_letter
                                    ELSE
                                     CASE
                                         WHEN sch_status = 'C'
                                              AND wnd.flg_ehr = g_flg_ehr_scheduled THEN
                                          g_cnc_flg_status_letter
                                         ELSE
                                          g_sch_flg_status_letter
                                     
                                     END
                                END AS flg_status_letter,
                               --flg_status to be used to compare the status with the legend icons
                               CASE
                                    WHEN wnd.flg_ehr = g_flg_ehr_normal THEN
                                     g_rgt_flg_status_letter
                                    ELSE
                                     CASE
                                         WHEN sch_status = 'C'
                                              AND wnd.flg_ehr = g_flg_ehr_scheduled
                                              AND wnd.wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_no_show THEN
                                          g_cnc_flg_status_letter
                                         WHEN sch_status = 'C'
                                              AND wnd.flg_ehr = g_flg_ehr_scheduled
                                              AND wnd.wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule THEN
                                          g_cncsch_flg_status_letter
                                         ELSE
                                          g_sch_flg_status_letter
                                     
                                     END
                                END AS flg_status_multi,
                               CASE
                                    WHEN wnd.flg_ehr = g_flg_ehr_scheduled THEN
                                     CASE
                                         WHEN wnd.wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_no_show THEN
                                          l_no_show_msg
                                         WHEN wnd.wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule
                                             /*AND pk_schedule_inp.check_reschedule(i_lang, i_prof, wnd.id_scheduled) =
                                             pk_alert_constant.g_yes*/
                                              AND get_sch_status(i_lang, i_prof, wnd.id_episode) =
                                              pk_wtl_prv_core.g_wtl_epis_st_schedule
                                         
                                          THEN
                                          l_rescheduled_msg
                                         WHEN wnd.wtl_epis_flg_status = pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule THEN
                                          NULL --cancel reason
                                     END
                                END cancel_reason_desc
                        
                          FROM (SELECT /*+opt_estimate(table,tdcs,scale_rows=0.001)*/
                                 epi.id_episode id_episode,
                                 epi.id_visit id_visit,
                                 'N' flg_cancel,
                                 epi.id_patient id_patient,
                                 nvl(bd1.desc_bed, pk_translation.get_translation(i_lang, bd1.code_bed)) desc_bed,
                                 nvl(rs.desc_room, pk_translation.get_translation(i_lang, rs.code_room)) desc_room,
                                 /*                                 decode(bd.code_bed,
                                 NULL,
                                 NULL,
                                 nvl(pk_translation.get_translation(i_lang, dpb.abbreviation),
                                     pk_translation.get_translation(i_lang, dpb.code_department))) desc_service,*/
                                 nvl2(nvl(bd.code_bed, bd1.code_bed),
                                      nvl(pk_translation.get_translation(i_lang, ds.abbreviation),
                                          pk_translation.get_translation(i_lang, ds.code_department)),
                                      NULL) desc_service,
                                 pk_patient.get_gender(i_lang, pat.gender) gender,
                                 pk_patient.get_pat_age(i_lang,
                                                        pat.dt_birth,
                                                        pat.dt_deceased,
                                                        pat.age,
                                                        i_prof.institution,
                                                        i_prof.software) pat_age,
                                 pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, -- campo para ordenação unicamente
                                 pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epi.id_episode, NULL) photo,
                                 pk_translation.get_translation(i_lang, dpt.code_department) desc_service_name,
                                 pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_specialty,
                                 decode(i_view,
                                         'AG1',
                                         CASE
                                             WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                              pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof)
                                         END,
                                         pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof)) dt_admission,
                                 decode(i_view,
                                         'AG1',
                                         CASE
                                             WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                              pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof)
                                         END,
                                         pk_date_utils.date_send_tsz(i_lang, s.dt_begin_tstz, i_prof)) expected_admission_date,
                                 dpb.rank dep_rank,
                                 ro.rank room_rank,
                                 bd.rank bed_rank,
                                 pk_date_utils.dt_chr_tsz(i_lang,
                                                          pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode),
                                                          i_prof) discharge_date,
                                 get_discharge_flg(i_lang, i_prof, epi.id_episode) flg_discharge,
                                 s.id_schedule AS id_scheduled,
                                 s.flg_status AS sch_status,
                                 epi.flg_ehr,
                                 nvl((SELECT pk_translation.get_translation(i_lang, ty1.code_epis_type)
                                       FROM episode epi1
                                      INNER JOIN epis_type ty1
                                         ON epi1.id_epis_type = ty1.id_epis_type
                                      WHERE epi1.id_episode = epi.id_prev_episode),
                                     pk_translation.get_translation(i_lang, g_inp_epis_type_code)) origin,
                                 pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epi.id_episode) desc_diagnosis,
                                 pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs,
                                 pk_patient.get_pat_name(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat,
                                 pk_patient.get_pat_name_to_sort(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat_to_sort,
                                 pk_adt.get_pat_non_disc_options(i_lang, i_prof, epi.id_patient) pat_ndo,
                                 pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epi.id_patient) pat_nd_icon,
                                 CASE
                                      WHEN ei.dt_last_interaction_tstz > epi.dt_begin_tstz THEN
                                       pk_alert_constant.get_yes
                                      ELSE
                                       pk_alert_constant.g_no
                                  END flg_has_records,
                                 epi.dt_begin_tstz,
                                 pk_hand_off_api.get_resp_icons(i_lang, i_prof, epi.id_episode, l_hand_off_type) resp_icons,
                                 get_wl_sch_status(i_lang, i_prof, epi.id_episode, s.id_schedule) wtl_epis_flg_status,
                                 ei.flg_unknown temp_episode,
                                 decode(i_view,
                                         'AG1',
                                         CASE
                                             WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                              pk_date_utils.dt_chr_tsz(i_lang,
                                                                       epi.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)
                                         END,
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  epi.dt_begin_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software)) dt_admission_ux,
                                 decode(i_view,
                                         'AG1',
                                         CASE
                                             WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                              pk_date_utils.dt_chr_tsz(i_lang,
                                                                       s.dt_begin_tstz,
                                                                       i_prof.institution,
                                                                       i_prof.software)
                                         END,
                                         pk_date_utils.dt_chr_tsz(i_lang,
                                                                  s.dt_begin_tstz,
                                                                  i_prof.institution,
                                                                  i_prof.software)) expected_admission_date_ux
                                  FROM episode epi
                                  JOIN patient pat
                                    ON epi.id_patient = pat.id_patient
                                  JOIN epis_info ei
                                    ON epi.id_episode = ei.id_episode
                                  LEFT JOIN bed bd
                                    ON bd.id_bed = ei.id_bed
                                  LEFT JOIN room ro
                                    ON ro.id_room = bd.id_room
                                  LEFT JOIN department dpb
                                    ON dpb.id_department = ro.id_department
                                  LEFT JOIN dep_clin_serv dcs
                                    ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                                  LEFT JOIN department dpt
                                    ON dpt.id_department = epi.id_department
                                   AND instr(dpt.flg_type, 'I') > 0
                                  LEFT JOIN department dpt_dcs
                                    ON dcs.id_department = dpt_dcs.id_department
                                  LEFT JOIN clinical_service cli
                                    ON cli.id_clinical_service = epi.id_clinical_service
                                  JOIN v_schedule_beds s
                                    ON s.id_episode = epi.id_episode
                                
                                  LEFT JOIN schedule_bed sbd
                                    ON sbd.id_schedule = ei.id_schedule
                                  LEFT JOIN bed bd1
                                    ON bd1.id_bed = sbd.id_bed
                                  LEFT JOIN room rs
                                    ON rs.id_room = bd1.id_room
                                  LEFT JOIN department ds
                                    ON rs.id_department = ds.id_department
                                  JOIN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                        column_value
                                         FROM TABLE(i_dcs) t) tdcs
                                    ON tdcs.column_value = ei.id_dep_clin_serv
                                 WHERE epi.id_epis_type = g_inp_epis_type
                                   AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_scheduled)
                                   AND epi.flg_status = g_epis_flg_status_active
                                   AND dpt_dcs.id_institution = i_prof.institution
                                   AND s.dt_begin_tstz >= l_date_lesser_limit
                                   AND s.dt_begin_tstz < l_date_upper_limit
                                   AND s.id_schedule =
                                       pk_schedule_inp.get_last_schedule_id(i_lang,
                                                                            i_prof,
                                                                            epi.id_episode,
                                                                            l_date_lesser_limit,
                                                                            l_date_upper_limit)) wnd
                         ORDER BY dep_rank, desc_service, room_rank, desc_room, bed_rank, desc_bed, name_pat_to_sort) wnd2
                 ORDER BY flg_status_letter;
        ELSE
            -- PT MARKET
            g_error := 'OPEN O_GRID CURSOR;  REGISTRAR';
            pk_alertlog.log_debug(g_error);
            OPEN o_grid FOR
                SELECT to_char(rownum, g_sort_mask) serv_rank,
                       wnd.*,
                       get_discharge_msg(i_lang, i_prof, wnd.id_episode, wnd.flg_discharge) discharge_type,
                       CASE
                            WHEN sch_status = 'C' THEN
                             l_inp_grid_admin_icon_n
                            ELSE
                             CASE
                                 WHEN wnd.flg_ehr = g_flg_ehr_scheduled THEN
                                  l_inp_grid_admin_icon_a
                                 ELSE
                                  CASE
                                      WHEN wnd.flg_ehr = g_flg_ehr_normal THEN
                                       decode(flg_discharge,
                                              g_discharge_flg_status_p,
                                              l_inp_grid_admin_icon_p,
                                              g_discharge_flg_status_a,
                                              l_inp_grid_admin_icon_d,
                                              l_inp_grid_admin_icon_i)
                                  END
                             END
                        END AS flg_status,
                       CASE
                            WHEN sch_status = 'C' THEN
                             g_cnc_flg_status_letter
                            ELSE
                             CASE
                                 WHEN wnd.flg_ehr = g_flg_ehr_scheduled THEN
                                  g_sch_flg_status_letter
                                 ELSE
                                  CASE
                                      WHEN wnd.flg_ehr = g_flg_ehr_normal THEN
                                       g_rgt_flg_status_letter
                                  END
                             END
                        END AS flg_status_letter,
                       decode(i_view,
                               'AG1',
                               CASE
                                   WHEN wnd.flg_ehr <> g_flg_ehr_scheduled THEN
                                    dt_begin_epis_str
                               END,
                               dt_begin_epis_str) dt_admission,
                       decode(i_view,
                               'AG1',
                               CASE
                                   WHEN wnd.flg_ehr <> g_flg_ehr_scheduled THEN
                                    dt_begin_epis_str
                               END,
                               dt_begin_epis_str) expected_admission_date
                  FROM (SELECT epi.id_episode id_episode,
                               epi.id_visit id_visit,
                               'N' flg_cancel,
                               epi.id_patient id_patient,
                               nvl(bd.desc_bed, pk_translation.get_translation(i_lang, bd.code_bed)) desc_bed,
                               nvl(ro.desc_room, pk_translation.get_translation(i_lang, ro.code_room)) desc_room,
                               decode(bd.code_bed,
                                      NULL,
                                      NULL,
                                      nvl(pk_translation.get_translation(i_lang, dpb.abbreviation),
                                          pk_translation.get_translation(i_lang, dpb.code_department))) desc_service,
                               pk_patient.get_gender(i_lang, pat.gender) gender,
                               pk_patient.get_pat_age(i_lang,
                                                      pat.dt_birth,
                                                      pat.dt_deceased,
                                                      pat.age,
                                                      i_prof.institution,
                                                      i_prof.software) pat_age,
                               pk_patient.get_julian_age(i_lang, pat.dt_birth, pat.age) pat_age_for_order_by, -- campo para ordenação unicamente
                               pk_patphoto.get_pat_photo(i_lang, i_prof, pat.id_patient, epi.id_episode, NULL) photo,
                               pk_translation.get_translation(i_lang, dpt.code_department) desc_service_name,
                               pk_translation.get_translation(i_lang, cli.code_clinical_service) desc_specialty,
                               
                               pk_date_utils.date_send_tsz(i_lang, epi.dt_begin_tstz, i_prof) dt_begin_epis_str,
                               dpb.rank dep_rank,
                               ro.rank room_rank,
                               bd.rank bed_rank,
                               pk_date_utils.dt_chr_tsz(i_lang,
                                                        pk_discharge.get_discharge_date(i_lang, i_prof, epi.id_episode),
                                                        i_prof) discharge_date,
                               get_discharge_flg(i_lang, i_prof, epi.id_episode) flg_discharge,
                               NULL AS id_scheduled,
                               NULL AS sch_status,
                               epi.flg_ehr,
                               nvl((SELECT pk_translation.get_translation(i_lang, ty1.code_epis_type)
                                     FROM episode epi1
                                    INNER JOIN epis_type ty1
                                       ON epi1.id_epis_type = ty1.id_epis_type
                                    WHERE epi1.id_episode = epi.id_prev_episode),
                                   pk_translation.get_translation(i_lang, g_inp_epis_type_code)) origin,
                               pk_inp_grid.get_diagnosis_grid(i_lang, i_prof, epi.id_episode) desc_diagnosis,
                               pk_date_utils.date_send_tsz(i_lang, ei.dt_first_obs_tstz, i_prof) dt_first_obs,
                               pk_patient.get_pat_name(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat,
                               pk_patient.get_pat_name_to_sort(i_lang, i_prof, epi.id_patient, epi.id_episode) name_pat_to_sort,
                               pk_adt.get_pat_non_disc_options(i_lang, i_prof, epi.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epi.id_patient) pat_nd_icon,
                               CASE
                                    WHEN ei.dt_last_interaction_tstz > epi.dt_begin_tstz THEN
                                     pk_alert_constant.get_yes
                                    ELSE
                                     pk_alert_constant.g_no
                                END flg_has_records,
                               epi.dt_begin_tstz,
                               pk_hand_off_api.get_resp_icons(i_lang, i_prof, epi.id_episode, l_hand_off_type) resp_icons,
                               ei.flg_unknown temp_episode,
                               decode(i_view,
                                       'AG1',
                                       CASE
                                           WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     epi.dt_begin_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software)
                                       END,
                                       pk_date_utils.dt_chr_tsz(i_lang,
                                                                epi.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)) dt_admission_ux,
                               decode(i_view,
                                       'AG1',
                                       CASE
                                           WHEN epi.flg_ehr <> g_flg_ehr_scheduled THEN
                                            pk_date_utils.dt_chr_tsz(i_lang,
                                                                     epi.dt_begin_tstz,
                                                                     i_prof.institution,
                                                                     i_prof.software)
                                       END,
                                       pk_date_utils.dt_chr_tsz(i_lang,
                                                                epi.dt_begin_tstz,
                                                                i_prof.institution,
                                                                i_prof.software)) expected_admission_date_ux
                          FROM episode epi
                          JOIN patient pat
                            ON epi.id_patient = pat.id_patient
                          JOIN epis_info ei
                            ON epi.id_episode = ei.id_episode
                          LEFT JOIN bed bd
                            ON bd.id_bed = ei.id_bed
                          LEFT JOIN room ro
                            ON ro.id_room = bd.id_room
                          LEFT JOIN department dpb
                            ON dpb.id_department = ro.id_department
                          LEFT JOIN dep_clin_serv dcs
                            ON dcs.id_dep_clin_serv = ei.id_dep_clin_serv
                          LEFT JOIN department dpt
                            ON dpt.id_department = epi.id_department
                           AND instr(dpt.flg_type, 'I') > 0
                          LEFT JOIN department dpt_dcs
                            ON dcs.id_department = dpt_dcs.id_department
                          LEFT JOIN clinical_service cli
                            ON cli.id_clinical_service = epi.id_clinical_service
                          JOIN schedule_inp_bed sib
                            ON sib.id_episode = epi.id_episode
                         WHERE epi.id_epis_type = g_inp_epis_type
                           AND (epi.flg_ehr = g_flg_ehr_normal OR epi.flg_ehr = g_flg_ehr_scheduled)
                           AND epi.flg_status = g_epis_flg_status_active
                           AND dpt_dcs.id_institution = i_prof.institution
                           AND ei.id_dep_clin_serv IN (SELECT /*+opt_estimate(table,t,scale_rows=1)*/
                                                        *
                                                         FROM TABLE(i_dcs) t)
                           AND epi.dt_begin_tstz >= l_date_lesser_limit
                           AND epi.dt_begin_tstz < l_date_upper_limit
                         ORDER BY dep_rank, desc_service, room_rank, desc_room, bed_rank, desc_bed, name_pat_to_sort) wnd
                 ORDER BY flg_status_letter;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_SCHEDULED_EPISODES',
                                                       o_error);
            pk_alert_exceptions.reset_error_state;
            pk_date_utils.set_dst_time_check_on;
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_scheduled_episodes;

    /********************************************************************************************
    *  Returns the information to fill the patients grid. Only the scheduled episodes are shown.
    *
    * @param i_lang                    language id
    * @param i_prof                    professional, software and institution ids
    * @param i_flg_obs                 OBS or non OBS services
    * @param o_grid                    Episodes information and the assotiated tasks
    * @param o_error                   Error message
    * @return                          true (sucess), false (error)
    *
    * @author                          Carlos Ferreira
    * @version                         1.0
    * @since                           18-09-2006
    **********************************************************************************************/
    FUNCTION get_scheduled_episodes
    (
        i_lang  IN NUMBER,
        i_prof  IN profissional,
        i_view  IN view_option.screen_identifier%TYPE,
        o_grid  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_profile VARCHAR2(0050);
    
        CURSOR c_cat IS
            SELECT cat.*
              FROM category cat
             INNER JOIN prof_cat pct
                ON cat.id_category = pct.id_category
             WHERE pct.id_professional = i_prof.id
               AND pct.id_institution = i_prof.institution;
    
        l_dcs table_number;
    BEGIN
    
        g_error := 'GET DEP_CLIN_SERVS';
    
        SELECT dcs1.id_dep_clin_serv
          BULK COLLECT
          INTO l_dcs
          FROM prof_dep_clin_serv pdc1
         INNER JOIN dep_clin_serv dcs1
            ON pdc1.id_dep_clin_serv = dcs1.id_dep_clin_serv
         INNER JOIN department dpt
            ON dcs1.id_department = dpt.id_department
           AND dpt.id_institution = i_prof.institution
           AND instr(dpt.flg_type, 'I') > 0
         WHERE pdc1.flg_status = g_selected
           AND pdc1.id_professional = i_prof.id;
    
        g_error := 'OPEN CURSOR ALL PATIENTS';
    
        FOR cat IN c_cat
        LOOP
            l_profile := cat.flg_type;
        END LOOP;
    
        g_error := 'CALL get_scheduled_episodes: profile: ' || l_profile || '  view: ';
        pk_alertlog.log_debug(g_error);
        IF NOT get_scheduled_episodes(i_lang, i_prof, l_profile, l_dcs, i_view, o_grid, o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.reset_error_state;
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_SCHECULED_EPISODES',
                                                       o_error);
            pk_types.open_my_cursor(o_grid);
            RETURN FALSE;
    END get_scheduled_episodes;

    /********************************************************************************************
    * Returns the discharge type message: indicated if it is an active, 
    *                                pending or predicted discharge.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    * @param i_flg_dsch_status       Flg discharge status P-pending, A-sctive, S-expected discharge
    *
    * @return                        Discharge type message
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_msg
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_dsch_status IN discharge.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_msg   VARCHAR2(4000);
    BEGIN
        IF (i_flg_dsch_status IS NULL)
        THEN
            g_error := 'CALC DISCHARGE TYPE with id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            BEGIN
                SELECT decode(dch.flg_status,
                               g_discharge_flg_status_p,
                               pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_p),
                               g_discharge_flg_status_a,
                               CASE
                                   WHEN pk_discharge_core.check_admin_discharge(i_lang,
                                                                                i_prof,
                                                                                dch.id_discharge,
                                                                                dch.flg_status_adm) = pk_alert_constant.g_no
                                        AND dch.dt_med_tstz IS NOT NULL THEN
                                    pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_a)
                                   ELSE
                                    pk_message.get_message(i_lang, i_prof, g_desc_disch_flg_status_adm)
                               END,
                               '')
                  INTO l_msg
                  FROM discharge dch
                 WHERE dch.id_episode = i_id_episode
                   AND dch.flg_status <> pk_discharge.g_disch_flg_status_reopen
                   AND dch.flg_status <> pk_discharge.g_disch_flg_status_cancel
                   AND rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    SELECT pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_s)
                      INTO l_msg
                      FROM discharge_schedule ds
                     WHERE ds.id_episode = i_id_episode
                       AND ds.flg_status = 'Y'
                       AND rownum = 1;
            END;
        ELSE
            g_error := 'CALC DISCHARGE TYPE with id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            SELECT decode(i_flg_dsch_status,
                          g_discharge_flg_status_p,
                          pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_p),
                          g_discharge_flg_status_a,
                          pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_a),
                          g_discharge_schedule_flg,
                          pk_message.get_message(i_lang, i_prof, g_desc_discharge_flg_status_s),
                          '')
              INTO l_msg
              FROM dual;
        END IF;
    
        RETURN l_msg;
    EXCEPTION
        WHEN no_data_found THEN
            l_msg := '';
            RETURN l_msg;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHARGE_MSG',
                                              l_error);
            RETURN NULL;
    END get_discharge_msg;

    /********************************************************************************************
    * Returns the discharge type: P-pending discharge, A-active discharge, S-expected discharge, 
    *                             null - no discharge
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    * @param i_episode               episode identifier    
    *
    * @return                        Discharge type message
    *
    * @author                        Sofia Mendes
    * @version                       2.5.0.7
    * @since                         03/12/2009
    ********************************************************************************************/
    FUNCTION get_discharge_flg
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN discharge.flg_status%TYPE IS
        l_error t_error_out;
        l_msg   discharge.flg_status%TYPE;
    BEGIN
        g_error := 'CALC DISCHARGE TYPE with id_episode: ' || i_id_episode;
        pk_alertlog.log_debug(g_error);
        BEGIN
            SELECT decode(dch.flg_status,
                          g_discharge_flg_status_p,
                          g_discharge_flg_status_p,
                          g_discharge_flg_status_a,
                          g_discharge_flg_status_a,
                          nvl2((SELECT MAX(ds.dt_discharge_schedule)
                                 FROM discharge_schedule ds
                                WHERE ds.id_episode = i_id_episode
                                  AND ds.flg_status = pk_alert_constant.g_yes),
                               g_desc_discharge_flg_status_s,
                               ''))
              INTO l_msg
              FROM discharge dch
             WHERE dch.id_episode = i_id_episode
               AND dch.flg_status <> pk_discharge.g_disch_flg_status_reopen
               AND dch.flg_status <> pk_discharge.g_disch_flg_status_cancel;
        EXCEPTION
            WHEN no_data_found THEN
                SELECT g_discharge_schedule_flg
                  INTO l_msg
                  FROM discharge_schedule ds
                 WHERE ds.id_episode = i_id_episode
                   AND ds.flg_status = pk_alert_constant.g_yes
                   AND rownum = 1;
        END;
        RETURN l_msg;
    EXCEPTION
        WHEN no_data_found THEN
            l_msg := NULL;
            RETURN l_msg;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DISCHARGE_MSG',
                                              l_error);
            RETURN NULL;
    END get_discharge_flg;

    /********************************************************************************************
    * Returns  label related to the risk assessment column 
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure    
    *
    * @return                        Discharge type message
    *
    * @author                        Filipe Silva
    * @version                       2.6.1.2
    * @since                         19/07/2011
    ********************************************************************************************/
    FUNCTION get_risk_label
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        o_risk_label OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_doc_area    doc_area.id_doc_area%TYPE;
        l_templates   pk_types.cursor_type;
        l_id_template doc_template.id_doc_template%TYPE;
    
    BEGIN
        g_error := 'GET RISK DOC_AREA';
        pk_alertlog.log_debug(g_error);
        l_doc_area := pk_sysconfig.get_config('RISK_DOC_AREA', i_prof);
    
        g_error := 'GET RISK TEMPLATE';
        pk_alertlog.log_debug(g_error);
    
        IF l_doc_area IS NOT NULL
        THEN
            BEGIN
                SELECT pk_translation.get_translation(i_lang, d.code_doc_area)
                  INTO o_risk_label
                  FROM doc_area d
                 WHERE d.id_doc_area = l_doc_area;
            EXCEPTION
                WHEN OTHERS THEN
                    o_risk_label := '';
            END;
        END IF;
        /*       IF NOT pk_touch_option.get_doc_template(i_lang, i_prof, NULL, NULL, l_doc_area, NULL, l_templates, o_error)
            THEN
                o_risk_label := '';
            ELSE
                FETCH l_templates
                    INTO l_id_template, o_risk_label;
                CLOSE l_templates;
            END IF;
        */
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_ret := pk_alert_exceptions.process_error(i_lang,
                                                       SQLCODE,
                                                       SQLERRM,
                                                       g_error,
                                                       g_package_owner,
                                                       g_package_name,
                                                       'GET_RISK_LABEL',
                                                       o_error);
            RETURN FALSE;
    END get_risk_label;

    PROCEDURE init_params_patient_grids
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
        k_episode          CONSTANT NUMBER(24) := 5;
    
        l_prof CONSTANT profissional := profissional(i_context_ids(g_prof_id),
                                                     i_context_ids(g_prof_institution),
                                                     i_context_ids(g_prof_software));
        l_lang CONSTANT language.id_language%TYPE := i_context_ids(g_lang);
        l_hand_off_type sys_config.value%TYPE;
        l_episode CONSTANT episode.id_episode%TYPE := i_context_ids(k_episode);
    
        l_days              sys_config.value%TYPE;
        l_scheduler_exists  sys_config.value%TYPE;
        l_date_lesser_limit TIMESTAMP WITH TIME ZONE;
        l_upper_limit_cfg   sys_config.value%TYPE;
        l_mask_xx CONSTANT VARCHAR2(100) := 'xxxxxxxxxxxxxx';
        l_num_days         number := 0;
        l_num_hours        number := 0;
         
        --  l_inp_grid_icon_status_str CONSTANT VARCHAR2(100) := '|' || l_mask_xx || '|I|X|';
        l_inp_grid_icon_status_str CONSTANT VARCHAR2(100) := '|I|' || l_mask_xx || '||';
        k_prof_depts_lov           CONSTANT VARCHAR(32 CHAR) := 'PROF_DEPARTMENTS';
        l_prof_depts_lov_idx NUMBER(24);
        k_department_all CONSTANT NUMBER := 0;
        l_disp_time_interval NUMBER(24);
        l_id_shortcut        sys_shortcut.id_sys_shortcut%TYPE;
    
        l_time VARCHAR2(0200 CHAR);
    
        l_error t_error_out;
    
        PROCEDURE set_day_and_hour_range IS
            l_bool BOOLEAN;
            l_day  NUMBER;
            l_hour NUMBER;
        BEGIN
        
            l_bool := i_filter_name = 'INPGridAllPatients';
            l_bool := l_bool AND i_custom_filter IN (53, 54, 55, 56);
            IF l_bool
            THEN
            
                -- day_range
                CASE i_custom_filter
                    WHEN 53 THEN
                        l_day  := 0;
                        l_hour := 0;
                    WHEN 54 THEN
                        l_day  := 1;
                        l_hour := 0;
                    WHEN 55 THEN
                        l_day  := 1;
                        l_hour := 8;
                    WHEN 56 THEN
                        l_day  := 1;
                        l_hour := 16;
                END CASE;
            end if;
                pk_context_api.set_parameter('l_day_range', l_day);
                pk_context_api.set_parameter('l_hour_range', l_hour);
                dbms_output.put_line('DAY:' || l_day);
                dbms_output.put_line('HOUR:' || l_hour);
            
            l_bool := i_filter_name = 'INPGridAllPatients';
            l_bool := l_bool AND i_custom_filter IN (49, 50, 51, 52);
            IF l_bool
            THEN
            
                -- day_range
                CASE i_custom_filter
                    WHEN 49 THEN
                        l_num_days  := 0;
                        l_num_hours  := 0;
                    WHEN 50 THEN
                        l_num_days  := 1;
                        l_num_hours  := 0;
                    WHEN 51 THEN
                        l_num_days  := 1;
                        l_num_hours  := 8;
                    WHEN 52 THEN
                        l_num_days  := 1;
                        l_num_hours  := 16;
                END CASE;
            
                pk_context_api.set_parameter('i_num_days', l_num_days);
                pk_context_api.set_parameter('i_num_hours', l_num_hours);
            
            END IF;
        
        END set_day_and_hour_range;
    
    BEGIN
    
        l_days := nvl(pk_sysconfig.get_config('FILTER_EPIS_INTO_SERVICE_FRAME', l_prof), 0);
    
        pk_context_api.set_parameter('i_lang', l_lang);
        pk_context_api.set_parameter('i_id_prof', l_prof.id);
        pk_context_api.set_parameter('i_id_institution', l_prof.institution);
        pk_context_api.set_parameter('i_id_software', l_prof.software);
        pk_context_api.set_parameter('i_days_back', l_days);
    
        l_scheduler_exists := nvl(pk_sysconfig.get_config('ADMISSION_SCHEDULER_EXISTS', l_prof), 'N');
        pk_context_api.set_parameter('i_scheduler_exists', l_scheduler_exists);
    
        IF NOT pk_access.preload_shortcuts(i_lang    => l_lang,
                                           i_prof    => l_prof,
                                           i_screens => table_varchar('NURSE_EVALUATION'),
                                           o_error   => l_error)
        THEN
            l_id_shortcut := NULL;
        END IF;
        l_id_shortcut := pk_access.get_shortcut('NURSE_EVALUATION');
    
        set_day_and_hour_range();
    
        CASE i_name
            WHEN 'i_episode' THEN
                o_id := l_episode;
            
            WHEN 'g_cat_type_doc' THEN
                o_vc2 := pk_alert_constant.g_cat_type_doc;
            
            WHEN 'g_cat_type_nurse' THEN
                o_vc2 := pk_alert_constant.g_cat_type_nurse;
            
            WHEN 'g_cf_pat_gender_abbr' THEN
                o_vc2 := g_cf_pat_gender_abbr;
            
            WHEN 'g_phy_presc_profile' THEN
                o_id := g_phy_presc_profile;
            
            WHEN 'g_show_in_grid' THEN
                o_vc2 := g_show_in_grid;
            
            WHEN 'g_show_in_tooltip' THEN
                o_vc2 := g_show_in_tooltip;
            
            WHEN 'g_six' THEN
                o_id := g_six;
            
            WHEN 'g_task_analysis' THEN
                o_vc2 := g_task_analysis;
            
            WHEN 'g_task_harvest' THEN
                o_vc2 := g_task_harvest;
            
            WHEN 'g_task_exam' THEN
                o_vc2 := g_task_exam;
            
            WHEN 'g_zero_varchar' THEN
                o_vc2 := g_zero_varchar;
            
            WHEN 'i_lang' THEN
                o_id := l_lang;
            
            WHEN 'i_my_patients' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'i_prof_cat' THEN
                o_vc2 := pk_prof_utils.get_category(i_lang => l_lang, i_prof => l_prof);
            
            WHEN 'i_prof_id' THEN
                o_id := l_prof.id;
            
            WHEN 'i_prof_institution' THEN
                o_id := l_prof.institution;
            
            WHEN 'i_prof_software' THEN
                o_id := l_prof.software;
            
            WHEN 'l_hand_off_type' THEN
                pk_hand_off_core.get_hand_off_type(l_lang, l_prof, l_hand_off_type);
                o_vc2 := l_hand_off_type;
            
            WHEN 'l_sys_config' THEN
                o_id := pk_sysconfig.get_config(g_cf_canc_epis_time, l_prof);
            
            WHEN 'g_task_monitor' THEN
                o_vc2 := g_task_monitor;
            
            WHEN 'g_task_interv' THEN
                o_vc2 := g_task_interv;
            
            WHEN 'g_task_comm_order' THEN
                o_vc2 := 'CO';
            
            WHEN 'current_timestamp' THEN
                o_tstz := current_timestamp;
            
            WHEN 'g_epis_flg_status_active' THEN
                o_vc2 := g_epis_flg_status_active;
            
            WHEN 'g_flg_ehr_normal' THEN
                o_vc2 := g_flg_ehr_normal;
            
            WHEN 'g_flg_ehr_scheduled' THEN
                o_vc2 := g_flg_ehr_scheduled;
            
            WHEN 'g_inp_epis_type' THEN
                o_id := g_inp_epis_type;
            
            WHEN 'g_no' THEN
                o_vc2 := pk_alert_constant.g_no;
            
            WHEN 'g_yes' THEN
                o_vc2 := pk_alert_constant.g_yes;
            
            WHEN 'g_one' THEN
                o_id := g_one;
            
            WHEN 'g_selected' THEN
                o_vc2 := g_selected;
            
            WHEN 'g_sysdate_char' THEN
                o_vc2 := pk_date_utils.date_send_tsz(l_lang, current_timestamp, l_prof);
            
            WHEN 'g_zero' THEN
                o_id := g_zero;
            
            WHEN 'epis_type_5' THEN
                o_vc2 := pk_translation.get_translation(l_lang, 'EPIS_TYPE.CODE_EPIS_TYPE.5');
            
            WHEN 'prof_profile_template' THEN
                o_num := pk_prof_utils.get_prof_profile_template(l_prof);
            
            WHEN 'add_days_to_current' THEN
                o_tstz := pk_date_utils.add_days_to_tstz(pk_date_utils.trunc_insttimezone(l_prof,
                                                                                          current_timestamp,
                                                                                          'DD'),
                                                         1);
            WHEN 'g_task_edu' THEN
                o_vc2 := g_task_edu;
                
            WHEN 'g_cnc_flg_status_letter' THEN
                o_vc2 := g_cnc_flg_status_letter;
            
            WHEN 'g_cncsch_flg_status_letter' THEN
                o_vc2 := g_cncsch_flg_status_letter;
            
            WHEN 'g_discharge_flg_status_a' THEN
                o_vc2 := g_discharge_flg_status_a;
            
            WHEN 'g_discharge_flg_status_p' THEN
                o_vc2 := g_discharge_flg_status_p;
            
            WHEN 'g_flg_ehr_scheduled' THEN
                o_vc2 := g_flg_ehr_scheduled;
            
            WHEN 'g_inp_epis_type_code' THEN
                o_vc2 := g_inp_epis_type_code;
            
            WHEN 'g_rgt_flg_status_letter' THEN
                o_vc2 := g_rgt_flg_status_letter;
            
            WHEN 'g_sch_flg_status_letter' THEN
                o_vc2 := g_sch_flg_status_letter;
            
            WHEN 'g_wtl_epis_st_cancel_schedule' THEN
                o_vc2 := pk_wtl_prv_core.g_wtl_epis_st_cancel_schedule;
            
            WHEN 'g_wtl_epis_st_no_show' THEN
                o_vc2 := pk_wtl_prv_core.g_wtl_epis_st_no_show;
            
            WHEN 'g_wtl_epis_st_schedule' THEN
                o_vc2 := pk_wtl_prv_core.g_wtl_epis_st_schedule;
            
            WHEN 'i_view' THEN
                o_vc2 := 'AG2';
            
            WHEN 'l_canc_msg' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'INP_SCH_GRID_M001');
            
            WHEN 'l_date_lesser_limit' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                o_tstz              := l_date_lesser_limit;
            
            WHEN 'l_date_upper_limit' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                o_tstz              := pk_date_utils.add_days_to_tstz(l_date_lesser_limit, 1);
            
            WHEN 'l_date_upper_limit_cfg' THEN
                l_date_lesser_limit := pk_date_utils.trunc_insttimezone(l_prof, current_timestamp, 'DD');
                l_upper_limit_cfg   := nvl(pk_sysconfig.get_config('EPISODES_TIMEFRAME', l_prof), 15);
                o_tstz              := pk_date_utils.add_days_to_tstz(l_date_lesser_limit, l_upper_limit_cfg);
            
            WHEN 'l_inp_grid_admin_icon_a' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'A');
            
            WHEN 'l_inp_grid_admin_icon_c' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'C');
            
            WHEN 'l_inp_grid_admin_icon_d' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'D');
            
            WHEN 'l_inp_grid_admin_icon_i' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'I');
            
            WHEN 'l_inp_grid_admin_icon_n' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'N');
            
            WHEN 'l_inp_grid_admin_icon_p' THEN
                o_vc2 := l_inp_grid_icon_status_str || pk_sysdomain.get_img(l_lang, 'INP_GRID_ADMIN_ICON', 'P');
            
            WHEN 'l_no_show_msg' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'INP_SCH_GRID_M003');
            
            WHEN 'l_rescheduled_msg' THEN
                o_vc2 := pk_message.get_message(i_lang => l_lang, i_code_mess => 'INP_SCH_GRID_M002');
            
            WHEN 'l_disch_epis_time' THEN
                o_id := nvl(pk_sysconfig.get_config(g_cf_disch_epis_time, l_prof), 0);
            WHEN 'g_epis_flg_status_inactive' THEN
                o_vc2 := g_epis_flg_status_inactive;
            
            WHEN 'g_adm_disch_bed' THEN
                o_vc2 := pk_sysconfig.get_config('INP_ADMISSION_DISCH_BED_MANDATORY', l_prof);
                
            WHEN 'i_sys_shortcut' THEN
                o_id := l_id_shortcut;
            WHEN 'l_today' THEN
                l_time := to_char(current_timestamp, 'YYYYMMDD') || '000000';
                o_tstz := pk_date_utils.get_string_tstz(i_lang      => l_lang,
                                                        i_prof      => l_prof,
                                                        i_timestamp => l_time,
                                                        i_timezone  => NULL);
            
        END CASE;
    END init_params_patient_grids;

    FUNCTION get_pats_from_pref_dept
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        o_cursor OUT pk_types.cursor_type,
        o_error  OUT t_error_out
    ) RETURN BOOLEAN IS
        k_filter_name   CONSTANT VARCHAR2(0200 CHAR) := 'INPGridAllPatients';
        k_first_row     CONSTANT NUMBER := 1;
        k_custom_filter CONSTANT NUMBER := 7;
    
        i_episode          episode.id_episode%TYPE := NULL;
        i_patient          patient.id_patient%TYPE := NULL;
        i_context          table_varchar := table_varchar();
        i_context_keys     table_varchar := table_varchar();
        i_filter           custom_filter.filter_name%TYPE;
        i_custom_filter    custom_filter.id_custom_filter%TYPE;
        i_first_element    NUMBER;
        i_order_aliases    table_varchar := table_varchar();
        i_order_directions table_varchar := table_varchar();
        i_text_search_id   custom_filter_field.id_filter_field%TYPE := NULL;
        i_text_search_val  VARCHAR2(0100 CHAR) := NULL;
        i_page_size        custom_filter.page_size%TYPE;
        i_tbl_field        table_table_varchar := table_table_varchar();
        i_tbl_value        table_table_varchar;
        -------------------------------------------
        o_page_size          NUMBER;
        o_flg_search_needed  VARCHAR2(0050 CHAR);
        o_id_cstm_executed   NUMBER;
        o_custom_filter_desc custom_filter.custom_filter_name%TYPE;
        o_text_search_desc   VARCHAR2(1000 CHAR);
        o_num_results        NUMBER;
        l_bool               BOOLEAN;
    BEGIN
    
        i_filter        := k_filter_name;
        i_custom_filter := k_custom_filter;
        i_first_element := k_first_row;
    
        l_bool := pk_core_filters.run_filter_search(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_episode          => i_episode,
                                                    i_patient          => i_patient,
                                                    i_context          => i_context,
                                                    i_context_keys     => i_context_keys,
                                                    i_filter           => i_filter,
                                                    i_custom_filter    => i_custom_filter,
                                                    i_first_element    => i_first_element,
                                                    i_order_aliases    => i_order_aliases,
                                                    i_order_directions => i_order_directions,
                                                    i_text_search_id   => i_text_search_id,
                                                    i_text_search_val  => i_text_search_val,
                                                    i_page_size        => i_page_size,
                                                    i_tbl_field        => i_tbl_field,
                                                    i_tbl_value        => i_tbl_value,
                                                    --o_page_size          => o_page_size,
                                                    o_flg_search_needed  => o_flg_search_needed,
                                                    o_text_search_desc   => o_text_search_desc,
                                                    o_id_cstm_executed   => o_id_cstm_executed,
                                                    o_custom_filter_desc => o_custom_filter_desc,
                                                    o_num_results        => o_num_results,
                                                    o_error              => o_error,
                                                    o_cursor             => o_cursor);
    
        RETURN l_bool;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_PATS_FROM_PREF_DEPT',
                                              o_error);
            pk_types.open_my_cursor(o_cursor);
            RETURN FALSE;
        
    END get_pats_from_pref_dept;

-- ***************************************************************************
-- *********************************  CONSTRUCTOR  ***************************
-- ***************************************************************************
BEGIN
    g_owner   := 'ALERT';
    g_package := 'PK_INP_GRID';

    g_software_intern_name     := 'INP';
    g_epis_flg_status_active   := 'A';
    g_epis_flg_status_inactive := 'I';
    g_epis_flg_status_temp     := 'T';
    g_epis_flg_status_canceled := 'C';
    g_discharge_active         := 'A';

    g_epis_active    := 'A';
    g_epis_cancelled := 'C';

    g_diet_requested := 'R';

    g_inp_epis_type := 5;
    g_sr_epis_type  := 4;

    g_selected := 'S';

    g_status_movement_t := 'T';

    g_disch_flg_status_active := 'A';
    g_disch_flg_status_pend   := 'P';
    g_disch_flg_status_cancel := 'C';
    g_disch_flg_status_reopen := 'R';

    g_epis_flg_type_def := 'D';

    g_cat_doctor := 'D';
    g_cat_nurse  := 'N';

    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_inp_grid;
/
