/*-- Last Change Revision: $Rev: 2026648 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:39:27 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_announced_arrival IS
    -- Private constants
    --g_aa_arr_epi_type_c CONSTANT VARCHAR2(1) := 'C'; --Created (OLD: used in V1 of ann_arrival)
    --g_aa_arr_epi_type_m CONSTANT VARCHAR2(1) := 'M'; --Merged (OLD: used in V1 of ann_arrival)
    g_aa_arr_epi_type_a CONSTANT VARCHAR2(1) := 'A'; --Episode created in conjunction with the ann pat
    g_aa_arr_epi_type_p CONSTANT VARCHAR2(1) := 'P'; --Episode created before the ann pat

    g_total_min_in_day CONSTANT NUMBER := 24 * 60;

    g_alert_type_add CONSTANT VARCHAR2(1) := 'A';
    g_alert_type_rem CONSTANT VARCHAR2(1) := 'R';

    g_pre_hosp_status_a CONSTANT VARCHAR2(1) := 'A';
    g_pre_hosp_status_i CONSTANT VARCHAR2(1) := 'I';

    g_pre_hosp_vs_read_status_a CONSTANT VARCHAR2(1) := 'A';

    g_care_stage_expected          CONSTANT sys_config.id_sys_config%TYPE := 'ANN_ARRIV_INITIAL_CARE_STAGE';
    g_care_stage_def_epis_arrived  CONSTANT sys_config.id_sys_config%TYPE := 'ANN_ARRIV_CARE_STAGE_DEF_EPI';
    g_care_stage_temp_epis_arrived CONSTANT sys_config.id_sys_config%TYPE := 'ANN_ARRIV_CARE_STAGE_TMP_EPI';

    g_flg_screen_d CONSTANT VARCHAR2(1) := 'D';
    g_flg_screen_h CONSTANT VARCHAR2(1) := 'H';

    g_hist_curr_val CONSTANT PLS_INTEGER := -1;

    g_domain_ann_arriv_status CONSTANT sys_domain.code_domain%TYPE := 'ANNOUNCED_ARRIVAL.FLG_STATUS';

    g_frm_pre_hospital CONSTANT VARCHAR2(30) := 'PREHOSPITAL_FORM';
    g_frm_report       CONSTANT VARCHAR2(30) := 'REPORT_FORM';

    g_list_ambulance_trust CONSTANT VARCHAR2(30) := 'PRE_HOSP_AMBULANCE_TRUST';

    g_fld_patient_name            CONSTANT VARCHAR2(30) := 'PATIENT_NAME';
    g_fld_patient_gender          CONSTANT VARCHAR2(30) := 'PATIENT_GENDER';
    g_fld_patient_birthday        CONSTANT VARCHAR2(30) := 'PATIENT_BIRTHDAY';
    g_fld_patient_age             CONSTANT VARCHAR2(30) := 'PATIENT_AGE';
    g_fld_patient_address         CONSTANT VARCHAR2(30) := 'PATIENT_ADDRESS';
    g_fld_patient_city            CONSTANT VARCHAR2(30) := 'PATIENT_CITY';
    g_fld_patient_postcode        CONSTANT VARCHAR2(30) := 'PATIENT_POSTCODE';
    g_fld_arrival_acident_time    CONSTANT VARCHAR2(30) := 'ARRIVAL_ACIDENT_TIME';
    g_fld_arrival_problem         CONSTANT VARCHAR2(30) := 'ARRIVAL_PROBLEM';
    g_fld_arrival_condition       CONSTANT VARCHAR2(30) := 'ARRIVAL_CONDITION';
    g_fld_arrival_refby           CONSTANT VARCHAR2(30) := 'ARRIVAL_REFBY';
    g_fld_arrival_specialty       CONSTANT VARCHAR2(30) := 'ARRIVAL_SPECIALTY';
    g_fld_arrival_clinserv        CONSTANT VARCHAR2(30) := 'ARRIVAL_CLINSERV';
    g_fld_arrival_physician       CONSTANT VARCHAR2(30) := 'ARRIVAL_PHYSICIAN';
    g_fld_arrival_expect_time     CONSTANT VARCHAR2(30) := 'ARRIVAL_EXPECT_TIME';
    g_fld_bystander_emdc_time     CONSTANT VARCHAR2(30) := 'BYSTANDER_EMDC_TIME';
    g_fld_bystander_emdc_code     CONSTANT VARCHAR2(30) := 'BYSTANDER_EMDC_CODE';
    g_fld_bystander_amb_ride      CONSTANT VARCHAR2(30) := 'BYSTANDER_AMB_RIDE';
    g_fld_bystander_postcode      CONSTANT VARCHAR2(30) := 'BYSTANDER_POSTCODE';
    g_fld_bystander_latitude      CONSTANT VARCHAR2(30) := 'BYSTANDER_LATITUDE';
    g_fld_bystander_longitude     CONSTANT VARCHAR2(30) := 'BYSTANDER_LONGITUDE';
    g_fld_transport_ride_out      CONSTANT VARCHAR2(30) := 'TRANSPORT_RIDE_OUT';
    g_fld_transport_arrival       CONSTANT VARCHAR2(30) := 'TRANSPORT_ARRIVAL';
    g_fld_triage_injury_mech      CONSTANT VARCHAR2(30) := 'TRIAGE_INJURY_MECH';
    g_fld_medtreat_away_time      CONSTANT VARCHAR2(30) := 'MEDTREAT_AWAY_TIME';
    g_fld_rtc_flg_prot_device     CONSTANT VARCHAR2(30) := 'RTC_FLG_PROT_DEVICE';
    g_fld_rtc_flg_rta_pat_typ     CONSTANT VARCHAR2(30) := 'RTC_FLG_RTA_PAT_TYP';
    g_fld_rtc_flg_is_driv_own     CONSTANT VARCHAR2(30) := 'RTC_FLG_IS_DRIV_OWN';
    g_fld_rtc_flg_police_involved CONSTANT VARCHAR2(30) := 'RTC_FLG_POLICE_INVOLVED';
    g_fld_rtc_police_num          CONSTANT VARCHAR2(30) := 'RTC_POLICE_NUM';
    g_fld_rtc_police_station      CONSTANT VARCHAR2(30) := 'RTC_POLICE_STATION';
    g_fld_rtc_police_accident_num CONSTANT VARCHAR2(30) := 'RTC_POLICE_ACCIDENT_NUM';
    g_fld_vital_signs             CONSTANT VARCHAR2(30) := 'VITAL_SIGNS';
    g_fld_ambulance_trust         CONSTANT VARCHAR2(30) := 'AMB_TRUST_CODE';

    -- Private variables
    g_pck_owner VARCHAR2(32) := 'ALERT';
    g_pck_name  VARCHAR2(32) := 'PK_ANNOUNCED_ARRIVAL';

    g_error        VARCHAR2(4000);
    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;

    g_long_lat_unit_mea_abrv pk_translation.t_desc_translation;

    -- Private exceptions
    e_call_error EXCEPTION;

    /**********************************************************************************************
    * Returns the package time
    *
    * @return                         Package time
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/08/25
    **********************************************************************************************/
    FUNCTION get_pck_time RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
    BEGIN
        RETURN g_sysdate_tstz;
    END;

    /**********************************************************************************************
    * Sets the package time. All inserts and updates of this package will use this time.
    *
    * @param i_lang                   the id language
    * @param i_date                   timestamp. if this value is null the package time will be set with the current_timestamp value
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/08/25
    **********************************************************************************************/
    FUNCTION set_pck_time
    (
        i_lang  IN language.id_language%TYPE,
        i_date  IN TIMESTAMP WITH LOCAL TIME ZONE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_PCK_TIME';
    BEGIN
        --Input Parameters
        pk_alertlog.log_debug(l_func_name || ' - INPUT PARAM - i_date: ' || to_char(i_date, 'YYYY-MM-DD HH24:MI:SS'));
    
        g_error := 'SET TIME';
        pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
        IF i_date IS NULL
        THEN
            g_sysdate_tstz := current_timestamp;
        ELSE
            g_sysdate_tstz := i_date;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END set_pck_time;

    /**********************************************************************************************
    * Set alert
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_professional           alert professional id
    * @param i_replace1               expected time of arrival
    * @param i_replace2               type of injury
    * @param i_type                   operation type: A - add, R- remove        
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_alert
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_episode           IN episode.id_episode%TYPE DEFAULT -1,
        i_professional      IN professional.id_professional%TYPE,
        i_dt_record         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_replace1          IN VARCHAR2 DEFAULT NULL,
        i_replace2          IN VARCHAR2 DEFAULT NULL,
        i_type              IN VARCHAR2,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ret             BOOLEAN;
        l_sys_alert_event sys_alert_event%ROWTYPE;
        l_sys_alert       NUMBER(24) := 63;
        l_alert_event_row sys_alert_event%ROWTYPE;
        l_patient         patient.id_patient%TYPE;
        l_visit           visit.id_visit%TYPE := -1;
    BEGIN
        IF i_type = g_alert_type_add
        THEN
        
            SELECT id_patient
              INTO l_patient
              FROM announced_arrival
             WHERE id_announced_arrival = i_announced_arrival;
        
            BEGIN
                SELECT id_visit
                  INTO l_visit
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_visit := -1;
            END;
        
            l_alert_event_row.id_sys_alert    := l_sys_alert;
            l_alert_event_row.id_software     := i_prof.software;
            l_alert_event_row.id_institution  := i_prof.institution;
            l_alert_event_row.id_episode      := nvl(i_episode, -1);
            l_alert_event_row.id_patient      := l_patient;
            l_alert_event_row.id_visit        := nvl(l_visit, -1);
            l_alert_event_row.id_record       := i_announced_arrival;
            l_alert_event_row.dt_record       := i_dt_record;
            l_alert_event_row.id_professional := i_professional;
            l_alert_event_row.replace1        := i_replace1;
            l_alert_event_row.replace2        := i_replace2;
        
            l_ret := pk_alerts.insert_sys_alert_event(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_sys_alert_event => l_alert_event_row,
                                                      i_flg_type_dest   => 'C',
                                                      o_error           => o_error);
        ELSIF i_type = g_alert_type_rem
        THEN
            l_sys_alert_event.id_sys_alert    := l_sys_alert;
            l_sys_alert_event.id_record       := i_announced_arrival;
            l_sys_alert_event.id_professional := i_professional;
        
            l_ret := pk_alerts.delete_sys_alert_event(i_lang            => i_lang,
                                                      i_prof            => i_prof,
                                                      i_sys_alert_event => l_sys_alert_event,
                                                      o_error           => o_error);
        END IF;
    
        RETURN l_ret;
    END set_alert;
    --
    /**********************************************************************************************
    * Saves announced arrival history
    *
    * @param i_lang                   the id language
    * @param i_announced_arrival      announced arrival id
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_announced_arrival_hist id_announced_arrival_hist of the new record
    * @param o_pre_hosp_accident      id_pre_hosp_accident of the changed announced arrival
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_ann_arr_hist
    (
        i_lang                   IN language.id_language%TYPE,
        i_announced_arrival      IN announced_arrival.id_announced_arrival%TYPE,
        i_flg_commit             IN BOOLEAN DEFAULT FALSE,
        o_announced_arrival_hist OUT announced_arrival_hist.id_announced_arrival_hist%TYPE,
        o_pre_hosp_accident      OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'SET_ANN_ARR_HIST';
        l_rows             table_varchar;
        l_ann_arrival_hist ts_announced_arrival_hist.announced_arrival_hist_tc;
    BEGIN
        g_error := 'GET ANN_ARRIV';
        SELECT ts_announced_arrival_hist.next_key,
               aa.id_announced_arrival,
               aa.id_pre_hosp_accident,
               aa.id_episode,
               aa.type_injury,
               aa.condition,
               aa.referred_by,
               aa.id_speciality,
               aa.id_ed_physician,
               aa.dt_expected_arrival,
               aa.flg_status,
               aa.dt_announced_arrival,
               aa.id_cancel_reason,
               aa.cancel_notes,
               aa.id_patient
          INTO l_ann_arrival_hist(1).id_announced_arrival_hist,
               l_ann_arrival_hist(1).id_announced_arrival,
               l_ann_arrival_hist(1).id_pre_hosp_accident,
               l_ann_arrival_hist(1).id_episode,
               l_ann_arrival_hist(1).type_injury,
               l_ann_arrival_hist(1).condition,
               l_ann_arrival_hist(1).referred_by,
               l_ann_arrival_hist(1).id_speciality,
               l_ann_arrival_hist(1).id_ed_physician,
               l_ann_arrival_hist(1).dt_expected_arrival,
               l_ann_arrival_hist(1).flg_status,
               l_ann_arrival_hist(1).dt_announced_arrival,
               l_ann_arrival_hist(1).id_cancel_reason,
               l_ann_arrival_hist(1).cancel_notes,
               l_ann_arrival_hist(1).id_patient
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        g_error := 'SET ANN_ARRIV_HIST';
        ts_announced_arrival_hist.ins(rows_in => l_ann_arrival_hist, rows_out => l_rows);
    
        g_error := 'VALIDATE INS ROW';
        IF (l_rows.count != 1)
        THEN
            RAISE e_call_error;
        END IF;
    
        SELECT aah.id_announced_arrival_hist
          INTO o_announced_arrival_hist
          FROM announced_arrival_hist aah
         WHERE ROWID = l_rows(1);
    
        o_pre_hosp_accident := l_ann_arrival_hist(1).id_pre_hosp_accident;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            IF i_flg_commit
            THEN
                pk_utils.undo_changes;
            END IF;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ann_arr_hist;
    --
    /**********************************************************************************************
    * Get list of patients with announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_ann_arrival_list       cursor with announced arrival data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_ann_arrival_grid
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        o_ann_arrival_list OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_ANN_ARRIVAL_GRID';
        l_time_limit    NUMBER;
        l_cancel_msg    sys_message.code_message%TYPE;
        l_no_specialist sys_message.desc_message%TYPE;
        l_id_software number;
    BEGIN
        g_error      := 'GET TIME_LIMIT';
        l_time_limit := to_number(pk_sysconfig.get_config('ANN_ARRIV_TIME_LIMIT', i_prof));
    
        g_error         := 'GET CANCEL MSG';
        l_cancel_msg    := pk_message.get_message(i_lang, 'ANN_ARRIV_MSG008');
        l_no_specialist := pk_message.get_message(i_lang, g_code_no_specialist);
    
        g_error := 'GET ANN_ARRIVAL_GRID';
        l_id_software := i_prof.software;
        if i_prof.software = 39 then
          l_id_software := 8;
        end if;
        OPEN o_ann_arrival_list FOR
            SELECT arr.id_announced_arrival,
                   arr.id_pre_hosp_accident,
                   arr.id_episode,
                   arr.id_patient,
                   arr.flg_epi_type,
                   arr.dt_accident,
                   arr.hour_accident,
                   nvl(TRIM(pk_patient.get_pat_name(i_lang, i_prof, arr.id_patient, arr.id_episode)), arr.name) name,
                   -- ALERT-102882 Patient name used for sorting
                   pk_patient.get_pat_name_to_sort(i_lang, i_prof, arr.id_patient, arr.id_episode, NULL) name_pat_sort,
                   pk_adt.get_pat_non_disc_options(i_lang, i_prof, arr.id_patient) pat_ndo,
                   pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, arr.id_patient) pat_nd_icon,
                   
                   nvl((SELECT pk_patient.get_gender(i_lang, p.gender)
                         FROM patient p
                        WHERE p.id_patient = arr.id_patient),
                       arr.gender) gender,
                   nvl((SELECT pk_patient.get_pat_age(i_lang, p.dt_birth, p.age, i_prof.institution, i_prof.software)
                         FROM patient p
                        WHERE p.id_patient = arr.id_patient),
                       arr.age) age,
                   arr.type_injury,
                   arr.condition,
                   arr.referred_by,
                   arr.id_speciality,
                   arr.desc_speciality,
                   arr.id_ed_physician,
                   arr.ed_physician_name,
                   arr.dt_expected_arr,
                   arr.hour_expected_arr,
                   arr.dt_arr,
                   arr.hour_arr,
                   arr.flg_status,
                   arr.desc_status,
                   decode(arr.flg_status, g_aa_arrival_status_c, l_cancel_msg, NULL) cancel_text,
                   arr.prev_status,
                   pk_sysdomain.get_domain(g_domain_ann_arriv_status, arr.prev_status, i_lang) prev_desc_status,
                   arr.flg_unknown,
                   arr.flg_resp_prof,
                   pk_adt.is_contact(i_lang, i_prof, arr.id_patient) flg_contact,
                   transport_number
              FROM (SELECT aa.id_announced_arrival,
                           aa.id_pre_hosp_accident,
                           aa.id_episode,
                           aa.id_patient,
                           aa.flg_epi_type,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, pha.dt_accident, i_prof) dt_accident,
                           pk_date_utils.date_char_hour_tsz(i_lang, pha.dt_accident, i_prof.institution, i_prof.software) hour_accident,
                           pha.name,
                           pk_patient.get_gender(i_lang, pha.gender) gender,
                           pk_patient.get_pat_age(i_lang, pha.dt_birth, pha.age, i_prof.institution, i_prof.software) age,
                           aa.type_injury,
                           aa.condition,
                           aa.referred_by,
                           aa.id_speciality,
                           nvl2(aa.id_speciality,
                                pk_translation.get_translation(i_lang, sp.code_speciality),
                                pk_translation.get_translation(i_lang, cs.code_clinical_service)) desc_speciality,
                           aa.id_ed_physician,
                           decode(aa.id_speciality,
                                  NULL,
                                  (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, aa.id_ed_physician)
                                     FROM dual),
                                  nvl2(aa.id_ed_physician,
                                       (SELECT pk_prof_utils.get_name_signature(i_lang, i_prof, aa.id_ed_physician)
                                          FROM dual),
                                       l_no_specialist)) ed_physician_name,
                           aa.dt_expected_arrival,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, aa.dt_expected_arrival, i_prof) dt_expected_arr,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            aa.dt_expected_arrival,
                                                            i_prof.institution,
                                                            i_prof.software) hour_expected_arr,
                           pha.dt_pre_hosp_accident dt_arrival_to_hosp,
                           pk_date_utils.date_chr_short_read_tsz(i_lang, pha.dt_pre_hosp_accident, i_prof) dt_arr,
                           pk_date_utils.date_char_hour_tsz(i_lang,
                                                            pha.dt_pre_hosp_accident,
                                                            i_prof.institution,
                                                            i_prof.software) hour_arr,
                           aa.flg_status,
                           pk_sysdomain.get_domain(g_domain_ann_arriv_status, aa.flg_status, i_lang) desc_status,
                           pk_announced_arrival.get_ann_arr_prev_status(aa.id_announced_arrival) prev_status,
                           epis.flg_unknown,
                           decode(pk_patient.get_prof_resp(i_lang, i_prof, aa.id_patient, epis.id_episode),
                                  pk_adt.g_true,
                                  pk_alert_constant.g_yes,
                                  pk_alert_constant.g_no) flg_resp_prof,
                           pha.transport_number
                      FROM announced_arrival aa
                     INNER JOIN pre_hosp_accident pha
                        ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
                      LEFT JOIN speciality sp
                        ON aa.id_speciality = sp.id_speciality
                      LEFT JOIN clinical_service cs
                        ON aa.id_clinical_service = cs.id_clinical_service
                    --Not all ann_arriv records had a associated episode (1 version)
                      LEFT JOIN v_episode_act epis
                        ON epis.id_episode = aa.id_episode
                     WHERE ((aa.flg_status = g_aa_arrival_status_e AND
                           (pk_date_utils.add_days_to_tstz(aa.dt_expected_arrival, l_time_limit / (g_total_min_in_day)) >=
                           g_sysdate_tstz OR aa.dt_expected_arrival IS NULL)) OR
                           (aa.flg_status = g_aa_arrival_status_a AND NOT EXISTS
                            (SELECT 'X'
                                FROM discharge d
                               WHERE d.id_episode = aa.id_episode
                                 AND d.flg_status = pk_discharge.g_disch_flg_active)) OR
                           (aa.flg_status = g_aa_arrival_status_c AND
                           (pk_date_utils.add_days_to_tstz(aa.dt_announced_arrival,
                                                             l_time_limit / (g_total_min_in_day)) >= g_sysdate_tstz)))
                       AND pha.id_institution IN (0, i_prof.institution)
                       AND pha.id_software IN (0, l_id_software)
                          --ALERT-291134
                       AND nvl(aa.flg_epi_type, g_aa_arr_epi_type_a) != g_aa_arr_epi_type_p) arr
             ORDER BY decode(nvl(arr.flg_status, 'NULL'),
                             g_aa_arrival_status_e,
                             'A',
                             'NULL',
                             'B',
                             g_aa_arrival_status_a,
                             'C',
                             g_aa_arrival_status_c,
                             'D'),
                      decode(arr.flg_status,
                             g_aa_arrival_status_e,
                             arr.dt_expected_arrival,
                             g_aa_arrival_status_a,
                             arr.dt_arrival_to_hosp,
                             g_aa_arrival_status_c,
                             decode(arr.prev_status,
                                    g_aa_arrival_status_e,
                                    arr.dt_expected_arrival,
                                    g_aa_arrival_status_a,
                                    arr.dt_arrival_to_hosp)) ASC,
                      name;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_grid;
    --
    /**********************************************************************************************
    * Get current data for a given announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_episode                episode id
    * @param o_ann_arrival_list       cursor with announced arrival data
    * @param o_pre_hosp_accident      cursor with pre-hosp accident data
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs reads data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_ann_arrival_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL,
        i_episode           IN episode.id_episode%TYPE DEFAULT NULL,
        o_ann_arrival_list  OUT pk_types.cursor_type,
        o_pre_hosp_accident OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ANN_ARRIVAL_INT';
        --
        l_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
    BEGIN
        g_error := 'VERIFY ID_ANN_ARR OR ID_EPIS';
        IF (i_announced_arrival IS NULL AND i_episode IS NULL)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET ID_PRE_HOSP_ACCIDENT';
        BEGIN
            SELECT aa.id_pre_hosp_accident
              INTO l_pre_hosp_accident
              FROM announced_arrival aa
             WHERE (aa.id_announced_arrival = i_announced_arrival OR i_announced_arrival IS NULL)
               AND (aa.id_episode = i_episode OR i_episode IS NULL);
        EXCEPTION
            WHEN no_data_found THEN
                l_pre_hosp_accident := NULL;
        END;
    
        g_error := 'GET ANN_ARRIVAL';
        OPEN o_ann_arrival_list FOR
            SELECT aa.id_announced_arrival,
                   aa.id_pre_hosp_accident,
                   aa.id_episode,
                   aa.id_patient,
                   aa.flg_epi_type,
                   aa.type_injury,
                   aa.condition,
                   aa.referred_by,
                   aa.id_speciality,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                   aa.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                   aa.id_ed_physician,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, aa.id_ed_physician) ed_physician_name,
                   pk_date_utils.date_char_tsz(i_lang, aa.dt_expected_arrival, i_prof.institution, i_prof.software) dt_expected_chr,
                   pk_date_utils.date_send_tsz(i_lang, aa.dt_expected_arrival, i_prof) dt_expected_arr,
                   aa.flg_status,
                   pk_sysdomain.get_domain(g_domain_ann_arriv_status, aa.flg_status, i_lang) desc_status
              FROM announced_arrival aa
             INNER JOIN pre_hosp_accident pha
                ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
              LEFT JOIN speciality sp
                ON aa.id_speciality = sp.id_speciality
              LEFT JOIN clinical_service cs
                ON aa.id_clinical_service = cs.id_clinical_service
             WHERE (aa.id_announced_arrival = i_announced_arrival OR i_announced_arrival IS NULL)
               AND (aa.id_episode = i_episode OR i_episode IS NULL)
               AND pha.id_institution = i_prof.institution
               AND pha.id_software = i_prof.software
            UNION
            SELECT aah.id_announced_arrival,
                   pha.id_pre_hosp_accident,
                   aah.id_episode,
                   aah.id_patient,
                   aah.flg_epi_type,
                   aah.type_injury,
                   aah.condition,
                   aah.referred_by,
                   aah.id_speciality,
                   pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                   aah.id_clinical_service,
                   pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clin_serv,
                   aah.id_ed_physician,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, aah.id_ed_physician) ed_physician_name,
                   pk_date_utils.date_char_tsz(i_lang, aah.dt_expected_arrival, i_prof.institution, i_prof.software) dt_expected_chr,
                   pk_date_utils.date_send_tsz(i_lang, aah.dt_expected_arrival, i_prof) dt_expected_arr,
                   aah.flg_status,
                   pk_sysdomain.get_domain(g_domain_ann_arriv_status, aah.flg_status, i_lang) desc_status
              FROM pre_hosp_accident pha
              LEFT JOIN announced_arrival_hist aah
                ON aah.id_pre_hosp_accident = pha.id_pre_hosp_accident
              LEFT JOIN speciality sp
                ON aah.id_speciality = sp.id_speciality
              LEFT JOIN clinical_service cs
                ON aah.id_clinical_service = cs.id_clinical_service
             WHERE (pha.id_episode = i_episode AND i_announced_arrival IS NULL)
               AND pha.id_institution = i_prof.institution
               AND pha.id_software = i_prof.software
               AND pha.flg_status IN (g_pre_hosp_status_a, g_pre_hosp_status_i);
    
        g_error := 'GET PRE_HOSP_ACCIDENT';
        IF (i_episode IS NULL)
        THEN
            --If i_episode is null means that is being called from announced_arrival grid
            IF NOT (pk_pre_hosp_accident.get_pre_hosp_acc(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_pre_hosp_accident => l_pre_hosp_accident,
                                                          o_pre_hosp_accident => o_pre_hosp_accident,
                                                          o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                                          o_error             => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        ELSE
            --otherwise is being called from enside patient area
            IF NOT (pk_pre_hosp_accident.get_epis_pre_hosp_acc(i_lang              => i_lang,
                                                               i_prof              => i_prof,
                                                               i_episode           => i_episode,
                                                               o_pre_hosp_accident => o_pre_hosp_accident,
                                                               o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                                               o_error             => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_types.open_my_cursor(o_pre_hosp_accident);
            pk_types.open_my_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_int;
    --
    /**********************************************************************************************
    * Get current and history data for a given announced arrival (by record or by episode)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_episode                episode id
    * @param o_ann_arrival            cursor with all announced arrival data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/07/01
    **********************************************************************************************/
    FUNCTION get_ann_arrival_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_ann_arrival       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_ANN_ARRIVAL_INT';
        l_prof          profissional;
        l_no_specialist sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'SET L_PROF';
        l_prof  := profissional(i_prof_id, i_prof_inst, i_prof_sw);
    
        l_no_specialist := pk_message.get_message(i_lang, g_code_no_specialist);
    
        g_error                  := 'GET LAT LONG UNIT MEASURE';
        g_long_lat_unit_mea_abrv := pk_pre_hosp_accident.get_long_lat_unit_mea_abrv(i_lang, l_prof);
    
        IF i_announced_arrival IS NOT NULL
           OR i_episode IS NOT NULL
        THEN
            g_error := 'GET ANN_ARRIVAL_GRID';
            OPEN o_ann_arrival FOR
                SELECT id_pre_hosp_accident,
                       name,
                       pat_ndo,
                       pat_nd_icon,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_patient_gender, gender, i_lang) gender,
                       pk_date_utils.dt_chr(i_lang, dt_birth, l_prof) dt_birth_chr,
                       get_formated_age(i_lang, l_prof, dt_birth, age) age,
                       address,
                       city,
                       pat_zip_code,
                       dt_accident,
                       dt_time_accident,
                       hour_time_accident,
                       type_injury,
                       condition,
                       referred_by,
                       id_speciality,
                       desc_speciality,
                       id_clinical_service,
                       desc_clinical_service,
                       id_ed_physician,
                       ed_physician_name,
                       dt_expected_arrival,
                       dt_expected_arr,
                       hour_expected_arr,
                       id_cancel_reason,
                       cancel_reason,
                       cancel_notes,
                       flg_status,
                       desc_status,
                       dt_created,
                       dt_created_chr,
                       dt_timestamp,
                       id_prof_create,
                       prof_create_name,
                       dt_report_mka,
                       cpa_code,
                       transport_number,
                       acc_zip_code,
                       latitude,
                       longitude,
                       dt_ride_out,
                       dt_arrival,
                       mech_injury,
                       dt_drv_away,
                       long_lat_unit_mea_abrv,
                       flg_resp_prof,
                       flg_prot_device,
                       desc_prot_device,
                       flg_rta_pat_typ,
                       desc_rta_pat_typ,
                       flg_is_driv_own,
                       desc_is_driv_own,
                       flg_police_involved,
                       desc_police_involved,
                       police_num,
                       police_station,
                       police_accident_num
                  FROM (SELECT pha.id_pre_hosp_accident,
                               nvl(TRIM(pk_patient.get_pat_name(i_lang, l_prof, aa.id_patient, epis.id_episode)),
                                   pha.name) name,
                               pk_adt.get_pat_non_disc_options(i_lang, l_prof, aa.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, l_prof, aa.id_patient) pat_nd_icon,
                               
                               nvl((SELECT pk_patient.get_gender(i_lang, p.gender)
                                     FROM patient p
                                    WHERE p.id_patient = aa.id_patient),
                                   pha.gender) gender,
                               nvl((SELECT p.dt_birth
                                     FROM patient p
                                    WHERE p.id_patient = aa.id_patient),
                                   pha.dt_birth) dt_birth,
                               nvl((SELECT p.age
                                     FROM patient p
                                    WHERE p.id_patient = aa.id_patient),
                                   pha.age) age,
                               nvl(pk_announced_arrival.get_pat_address(i_lang, l_prof, aa.id_patient), pha.address) address,
                               pha.city,
                               pha.pat_zip_code,
                               pha.dt_accident,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, pha.dt_accident, l_prof) dt_time_accident,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                pha.dt_accident,
                                                                l_prof.institution,
                                                                l_prof.software) hour_time_accident,
                               aa.type_injury,
                               aa.condition,
                               aa.referred_by,
                               aa.id_speciality,
                               pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                               aa.id_clinical_service,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                               aa.id_ed_physician,
                               nvl2(aa.id_ed_physician,
                                    pk_prof_utils.get_name_signature(i_lang, l_prof, aa.id_ed_physician),
                                    l_no_specialist) ed_physician_name,
                               aa.dt_expected_arrival,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, aa.dt_expected_arrival, l_prof) dt_expected_arr,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                aa.dt_expected_arrival,
                                                                l_prof.institution,
                                                                l_prof.software) hour_expected_arr,
                               aa.id_cancel_reason,
                               pk_cancel_reason.get_cancel_reason_desc(i_lang, l_prof, aa.id_cancel_reason) cancel_reason,
                               aa.cancel_notes,
                               aa.flg_status,
                               pk_sysdomain.get_domain(g_domain_ann_arriv_status, aa.flg_status, i_lang) desc_status,
                               aa.dt_announced_arrival dt_created,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, aa.dt_announced_arrival, l_prof) dt_created_chr,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                aa.dt_announced_arrival,
                                                                l_prof.institution,
                                                                l_prof.software) hour_created_chr,
                               pk_date_utils.date_send_tsz(i_lang, aa.dt_announced_arrival, l_prof) dt_timestamp,
                               get_formated_date(i_lang, l_prof, aa.dt_announced_arrival) dt_timestamp_chr,
                               pha.id_prof_create,
                               pk_prof_utils.get_name_signature(i_lang, l_prof, pha.id_prof_create) prof_create_name,
                               get_formated_date(i_lang, l_prof, pha.dt_report_mka) dt_report_mka,
                               pha.cpa_code,
                               pha.transport_number,
                               pha.acc_zip_code,
                               pk_utils.to_str(pha.latitude, l_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                               pk_utils.to_str(pha.longitude, l_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                               get_formated_date(i_lang, l_prof, pha.dt_ride_out) dt_ride_out,
                               get_formated_date(i_lang, l_prof, pha.dt_arrival) dt_arrival,
                               pha.mech_injury,
                               get_formated_date(i_lang, l_prof, pha.dt_drv_away) dt_drv_away,
                               g_long_lat_unit_mea_abrv long_lat_unit_mea_abrv,
                               decode(pk_patient.get_prof_resp(i_lang, l_prof, aa.id_patient, epis.id_episode),
                                      pk_adt.g_true,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) flg_resp_prof,
                               pha.flg_prot_device,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_prot_device,
                                                       pha.flg_prot_device,
                                                       i_lang) desc_prot_device,
                               pha.flg_rta_pat_typ,
                               decode(pha.flg_rta_pat_typ,
                                      pk_pre_hosp_accident.g_pha_flg_rta_pat_typ_other,
                                      pha.rta_pat_typ_ft,
                                      pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_rta_pat_typ,
                                                              pha.flg_rta_pat_typ,
                                                              i_lang)) desc_rta_pat_typ,
                               pha.flg_is_driv_own,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_is_driv_own,
                                                       pha.flg_is_driv_own,
                                                       i_lang) desc_is_driv_own,
                               pha.flg_police_involved,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_police_involved,
                                                       pha.flg_police_involved,
                                                       i_lang) desc_police_involved,
                               pha.police_num,
                               pha.police_station,
                               pha.police_accident_num
                          FROM announced_arrival aa
                         INNER JOIN pre_hosp_accident pha
                            ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
                          LEFT JOIN speciality sp
                            ON aa.id_speciality = sp.id_speciality
                          LEFT JOIN clinical_service cs
                            ON aa.id_clinical_service = cs.id_clinical_service
                          LEFT JOIN episode epis
                            ON epis.id_episode = aa.id_episode
                         WHERE aa.id_announced_arrival = nvl(i_announced_arrival, aa.id_announced_arrival)
                           AND (aa.id_episode = i_episode OR i_episode IS NULL)
                        UNION
                        SELECT pha.id_pre_hosp_accident,
                               decode(pk_adt.call_show_patient_info(i_lang,
                                                                    aah.id_patient,
                                                                    pk_patient.get_prof_resp(i_lang,
                                                                                             l_prof,
                                                                                             aah.id_patient,
                                                                                             epis.id_episode)),
                                      pk_adt.g_true,
                                      pha.name,
                                      pk_patient.get_pat_name(i_lang, l_prof, aah.id_patient, epis.id_episode)) name,
                               pk_adt.get_pat_non_disc_options(i_lang, l_prof, aah.id_patient) pat_ndo,
                               pk_adt.get_pat_non_disclosure_icon(i_lang, l_prof, aah.id_patient) pat_nd_icon,
                               nvl((SELECT pk_patient.get_gender(i_lang, p.gender)
                                     FROM patient p
                                    WHERE p.id_patient = aah.id_patient),
                                   pha.gender) gender,
                               nvl((SELECT p.dt_birth
                                     FROM patient p
                                    WHERE p.id_patient = aah.id_patient),
                                   pha.dt_birth) dt_birth,
                               nvl((SELECT p.age
                                     FROM patient p
                                    WHERE p.id_patient = aah.id_patient),
                                   pha.age) age,
                               nvl(pk_announced_arrival.get_pat_address(i_lang, l_prof, aah.id_patient), pha.address) address,
                               pha.city,
                               pha.pat_zip_code,
                               pha.dt_accident,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, pha.dt_accident, l_prof) dt_time_accident,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                pha.dt_accident,
                                                                l_prof.institution,
                                                                l_prof.software) hour_time_accident,
                               aah.type_injury,
                               aah.condition,
                               aah.referred_by,
                               aah.id_speciality,
                               pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                               aah.id_clinical_service,
                               pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                               aah.id_ed_physician,
                               nvl2(aah.id_ed_physician,
                                    pk_prof_utils.get_name_signature(i_lang, l_prof, aah.id_ed_physician),
                                    l_no_specialist) ed_physician_name,
                               aah.dt_expected_arrival,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, aah.dt_expected_arrival, l_prof) dt_expected_arr,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                aah.dt_expected_arrival,
                                                                l_prof.institution,
                                                                l_prof.software) hour_expected_arr,
                               aah.id_cancel_reason,
                               pk_cancel_reason.get_cancel_reason_desc(i_lang, l_prof, aah.id_cancel_reason) cancel_reason,
                               aah.cancel_notes,
                               aah.flg_status,
                               pk_sysdomain.get_domain(g_domain_ann_arriv_status, aah.flg_status, i_lang) desc_status,
                               aah.dt_announced_arrival dt_created,
                               pk_date_utils.date_chr_short_read_tsz(i_lang, aah.dt_announced_arrival, l_prof) dt_created_chr,
                               pk_date_utils.date_char_hour_tsz(i_lang,
                                                                aah.dt_announced_arrival,
                                                                l_prof.institution,
                                                                l_prof.software) hour_created_chr,
                               pk_date_utils.date_send_tsz(i_lang, aah.dt_announced_arrival, l_prof) dt_timestamp,
                               get_formated_date(i_lang, l_prof, aah.dt_announced_arrival) dt_timestamp_chr,
                               pha.id_prof_create,
                               pk_prof_utils.get_name_signature(i_lang, l_prof, pha.id_prof_create) prof_create_name,
                               get_formated_date(i_lang, l_prof, pha.dt_report_mka) dt_report_mka,
                               pha.cpa_code,
                               pha.transport_number,
                               pha.acc_zip_code,
                               pk_utils.to_str(pha.latitude, l_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                               pk_utils.to_str(pha.longitude, l_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                               get_formated_date(i_lang, l_prof, pha.dt_ride_out) dt_ride_out,
                               get_formated_date(i_lang, l_prof, pha.dt_arrival) dt_arrival,
                               pha.mech_injury,
                               get_formated_date(i_lang, l_prof, pha.dt_drv_away) dt_drv_away,
                               g_long_lat_unit_mea_abrv long_lat_unit_mea_abrv,
                               decode(pk_patient.get_prof_resp(i_lang, l_prof, aah.id_patient, epis.id_episode),
                                      pk_adt.g_true,
                                      pk_alert_constant.g_yes,
                                      pk_alert_constant.g_no) flg_resp_prof,
                               pha.flg_prot_device,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_prot_device,
                                                       pha.flg_prot_device,
                                                       i_lang) desc_prot_device,
                               pha.flg_rta_pat_typ,
                               decode(pha.flg_rta_pat_typ,
                                      pk_pre_hosp_accident.g_pha_flg_rta_pat_typ_other,
                                      pha.rta_pat_typ_ft,
                                      pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_rta_pat_typ,
                                                              pha.flg_rta_pat_typ,
                                                              i_lang)) desc_rta_pat_typ,
                               pha.flg_is_driv_own,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_is_driv_own,
                                                       pha.flg_prot_device,
                                                       i_lang) desc_is_driv_own,
                               pha.flg_police_involved,
                               pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_police_involved,
                                                       pha.flg_prot_device,
                                                       i_lang) desc_police_involved,
                               pha.police_num,
                               pha.police_station,
                               pha.police_accident_num
                          FROM announced_arrival_hist aah
                         INNER JOIN pre_hosp_accident pha
                            ON aah.id_pre_hosp_accident = pha.id_pre_hosp_accident
                          LEFT JOIN speciality sp
                            ON aah.id_speciality = sp.id_speciality
                          LEFT JOIN clinical_service cs
                            ON aah.id_clinical_service = cs.id_clinical_service
                          LEFT JOIN episode epis
                            ON epis.id_episode = aah.id_episode
                         WHERE aah.id_announced_arrival = nvl(i_announced_arrival, aah.id_announced_arrival)
                           AND (i_episode IS NULL OR aah.dt_announced_arrival <=
                               (SELECT MAX(aah2.dt_announced_arrival)
                                                        FROM announced_arrival_hist aah2
                                                       WHERE aah2.id_announced_arrival = aah.id_announced_arrival
                                                         AND aah2.id_episode = i_episode)))
                 ORDER BY id_pre_hosp_accident DESC, dt_created DESC;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_int;
    --
    /**********************************************************************************************
    * Get announced arrival record
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival_hist announced arrival hist id
    * @param i_pre_hosp_accident      pre hospital accident id
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2011/08/01
    **********************************************************************************************/
    FUNCTION get_ann_arrival_rec
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_announced_arrival_hist IN announced_arrival_hist.id_announced_arrival_hist%TYPE,
        i_pre_hosp_accident      IN announced_arrival.id_pre_hosp_accident%TYPE
    ) RETURN pk_announced_arrival.rec_announced_arrival IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_REC';
        --
        l_space CONSTANT VARCHAR2(1) := ' ';
        --
        l_ret pk_announced_arrival.rec_announced_arrival;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        g_error := 'GET LONG AND LAT UNIT MEAS ABREV';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        g_long_lat_unit_mea_abrv := pk_pre_hosp_accident.get_long_lat_unit_mea_abrv(i_lang, i_prof);
    
        g_error := 'GET ANNOUNCED_ARRIVAL RECORD';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        SELECT i_announced_arrival_hist id_announced_arrival_hist,
               t.id_announced_arrival,
               t.id_pre_hosp_accident,
               t.pat_name,
               pk_sysdomain.get_domain('PATIENT.GENDER', gender, i_lang) desc_gender,
               pk_date_utils.dt_chr(i_lang, dt_birth, i_prof) dt_birth_chr,
               pk_patient.get_pat_age(i_lang, dt_birth, age, i_prof.institution, i_prof.software) age,
               
               t.address,
               t.city,
               t.pat_zip_code,
               t.dt_accident,
               t.type_injury,
               t.condition,
               t.referred_by,
               t.id_speciality,
               t.desc_speciality,
               t.id_clinical_service,
               t.desc_clinical_service,
               t.id_ed_physician,
               t.ed_physician_name,
               t.dt_expected_arrival,
               t.id_cancel_reason,
               t.cancel_reason,
               t.cancel_notes,
               t.flg_status,
               t.desc_status,
               t.dt_report_mka,
               t.cpa_code,
               t.ambulance_trust,
               t.transport_number,
               t.acc_zip_code,
               decode(t.latitude, NULL, NULL, t.latitude || l_space || g_long_lat_unit_mea_abrv) latitude,
               decode(t.longitude, NULL, NULL, t.longitude || l_space || g_long_lat_unit_mea_abrv) longitude,
               t.dt_ride_out,
               t.dt_arrival,
               t.mech_injury,
               t.dt_drv_away,
               t.flg_prot_device,
               t.desc_prot_device,
               t.flg_rta_pat_typ,
               t.desc_rta_pat_typ,
               t.flg_is_driv_own,
               t.desc_is_driv_own,
               t.flg_police_involved,
               t.desc_police_involved,
               t.police_num,
               t.police_station,
               t.police_accident_num
          INTO l_ret
          FROM (SELECT aa.id_announced_arrival,
                       aa.id_pre_hosp_accident,
                       
                       nvl(TRIM(pk_patient.get_pat_name(i_lang, i_prof, aa.id_patient, aa.id_episode)), pha.name) pat_name,
                       nvl((SELECT pk_patient.get_gender(i_lang, p.gender)
                             FROM patient p
                            WHERE p.id_patient = aa.id_patient),
                           pha.gender) gender,
                       nvl((SELECT p.dt_birth
                             FROM patient p
                            WHERE p.id_patient = aa.id_patient),
                           pha.dt_birth) dt_birth,
                       nvl((SELECT p.age
                             FROM patient p
                            WHERE p.id_patient = aa.id_patient),
                           pha.age) age,
                       nvl(pk_announced_arrival.get_pat_address(i_lang, i_prof, aa.id_patient), pha.address) address,
                       pha.city,
                       pha.pat_zip_code,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_accident) dt_accident,
                       aa.type_injury,
                       aa.condition,
                       aa.referred_by,
                       aa.id_speciality,
                       pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                       aa.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                       aa.id_ed_physician,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, aa.id_ed_physician) ed_physician_name,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, aa.dt_expected_arrival) dt_expected_arrival,
                       aa.id_cancel_reason,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, aa.id_cancel_reason) cancel_reason,
                       aa.cancel_notes,
                       aa.flg_status,
                       pk_sysdomain.get_domain(g_domain_ann_arriv_status, aa.flg_status, i_lang) desc_status,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_report_mka) dt_report_mka,
                       pha.cpa_code,
                       decode(pha.id_amb_trust_code,
                              NULL,
                              pk_translation.get_translation_trs(i_code_mess => pha.code_ambulance_trust),
                              pk_sys_list.get_sys_list_value_desc(i_lang, i_prof, pha.id_amb_trust_code)) ambulance_trust,
                       pha.transport_number,
                       pha.acc_zip_code,
                       pk_utils.to_str(pha.latitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                       pk_utils.to_str(pha.longitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_ride_out) dt_ride_out,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_arrival) dt_arrival,
                       pha.mech_injury,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_drv_away) dt_drv_away,
                       pha.flg_prot_device,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_prot_device,
                                               pha.flg_prot_device,
                                               i_lang) desc_prot_device,
                       pha.flg_rta_pat_typ,
                       decode(pha.flg_rta_pat_typ,
                              pk_pre_hosp_accident.g_pha_flg_rta_pat_typ_other,
                              pha.rta_pat_typ_ft,
                              pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_rta_pat_typ,
                                                      pha.flg_rta_pat_typ,
                                                      i_lang)) desc_rta_pat_typ,
                       pha.flg_is_driv_own,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_is_driv_own,
                                               pha.flg_is_driv_own,
                                               i_lang) desc_is_driv_own,
                       pha.flg_police_involved,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_police_involved,
                                               pha.flg_police_involved,
                                               i_lang) desc_police_involved,
                       pha.police_num,
                       pha.police_station,
                       pha.police_accident_num
                  FROM announced_arrival aa
                 INNER JOIN pre_hosp_accident pha
                    ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
                  LEFT JOIN speciality sp
                    ON aa.id_speciality = sp.id_speciality
                  LEFT JOIN clinical_service cs
                    ON aa.id_clinical_service = cs.id_clinical_service
                  LEFT JOIN episode epis
                    ON epis.id_episode = aa.id_episode
                 WHERE aa.id_pre_hosp_accident = i_pre_hosp_accident
                   AND i_announced_arrival_hist = g_hist_curr_val
                UNION ALL
                SELECT aah.id_announced_arrival,
                       aah.id_pre_hosp_accident,
                       nvl(TRIM(pk_patient.get_pat_name(i_lang, i_prof, aah.id_patient, aah.id_episode)), pha.name) pat_name,
                       nvl((SELECT pk_patient.get_gender(i_lang, p.gender)
                             FROM patient p
                            WHERE p.id_patient = aah.id_patient),
                           pha.gender) gender,
                       nvl((SELECT p.dt_birth
                             FROM patient p
                            WHERE p.id_patient = aah.id_patient),
                           pha.dt_birth) dt_birth,
                       nvl((SELECT p.age
                             FROM patient p
                            WHERE p.id_patient = aah.id_patient),
                           pha.age) age,
                       nvl(pk_announced_arrival.get_pat_address(i_lang, i_prof, aah.id_patient), pha.address) address,
                       pha.city,
                       pha.pat_zip_code,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_accident) dt_accident,
                       aah.type_injury,
                       aah.condition,
                       aah.referred_by,
                       aah.id_speciality,
                       pk_translation.get_translation(i_lang, sp.code_speciality) desc_speciality,
                       aah.id_clinical_service,
                       pk_translation.get_translation(i_lang, cs.code_clinical_service) desc_clinical_service,
                       aah.id_ed_physician,
                       pk_prof_utils.get_name_signature(i_lang, i_prof, aah.id_ed_physician) ed_physician_name,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, aah.dt_expected_arrival) dt_expected_arrival,
                       aah.id_cancel_reason,
                       pk_cancel_reason.get_cancel_reason_desc(i_lang, i_prof, aah.id_cancel_reason) cancel_reason,
                       aah.cancel_notes,
                       aah.flg_status,
                       pk_sysdomain.get_domain(g_domain_ann_arriv_status, aah.flg_status, i_lang) desc_status,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_report_mka) dt_report_mka,
                       pha.cpa_code,
                       decode(pha.id_amb_trust_code,
                              NULL,
                              pk_translation.get_translation_trs(i_code_mess => pha.code_ambulance_trust),
                              pk_sys_list.get_sys_list_value_desc(i_lang, i_prof, pha.id_amb_trust_code)) ambulance_trust,
                       pha.transport_number,
                       pha.acc_zip_code,
                       pk_utils.to_str(pha.latitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                       pk_utils.to_str(pha.longitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_ride_out) dt_ride_out,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_arrival) dt_arrival,
                       pha.mech_injury,
                       pk_announced_arrival.get_formated_date(i_lang, i_prof, pha.dt_drv_away) dt_drv_away,
                       pha.flg_prot_device,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_prot_device,
                                               pha.flg_prot_device,
                                               i_lang) desc_prot_device,
                       pha.flg_rta_pat_typ,
                       decode(pha.flg_rta_pat_typ,
                              pk_pre_hosp_accident.g_pha_flg_rta_pat_typ_other,
                              pha.rta_pat_typ_ft,
                              pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_rta_pat_typ,
                                                      pha.flg_rta_pat_typ,
                                                      i_lang)) desc_rta_pat_typ,
                       pha.flg_is_driv_own,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_is_driv_own,
                                               pha.flg_is_driv_own,
                                               i_lang) desc_is_driv_own,
                       pha.flg_police_involved,
                       pk_sysdomain.get_domain(pk_pre_hosp_accident.g_domain_flg_police_involved,
                                               pha.flg_police_involved,
                                               i_lang) desc_police_involved,
                       pha.police_num,
                       pha.police_station,
                       pha.police_accident_num
                  FROM announced_arrival_hist aah
                 INNER JOIN pre_hosp_accident pha
                    ON aah.id_pre_hosp_accident = pha.id_pre_hosp_accident
                  LEFT JOIN speciality sp
                    ON aah.id_speciality = sp.id_speciality
                  LEFT JOIN clinical_service cs
                    ON aah.id_clinical_service = cs.id_clinical_service
                  LEFT JOIN episode epis
                    ON epis.id_episode = aah.id_episode
                 WHERE aah.id_announced_arrival_hist = i_announced_arrival_hist
                   AND i_announced_arrival_hist != g_hist_curr_val) t;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arrival_rec;
    --
    /**********************************************************************************************
    * Get current data for a given announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param o_ann_arrival_list       cursor with announced arrival data
    * @param o_pre_hosp_accident      cursor with pre-hosp accident data
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs reads data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_ann_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        o_ann_arrival_list  OUT pk_types.cursor_type,
        o_pre_hosp_accident OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ANN_ARRIVAL';
    BEGIN
        IF NOT get_ann_arrival_int(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_announced_arrival => i_announced_arrival,
                                   o_ann_arrival_list  => o_ann_arrival_list,
                                   o_pre_hosp_accident => o_pre_hosp_accident,
                                   o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                   o_error             => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_types.open_my_cursor(o_pre_hosp_accident);
            pk_types.open_my_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival;
    --
    /**********************************************************************************************
    * Get current announced arrival data for a certain episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode id
    * @param o_ann_arrival_list       cursor with announced arrival data
    * @param o_pre_hosp_accident      cursor with pre-hosp accident data
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs reads data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_ann_arrival_by_epi
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN episode.id_episode%TYPE,
        o_ann_arrival_list  OUT pk_types.cursor_type,
        o_pre_hosp_accident OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ANN_ARRIVAL_BY_EPI';
    BEGIN
        IF NOT get_ann_arrival_int(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_episode           => i_episode,
                                   o_ann_arrival_list  => o_ann_arrival_list,
                                   o_pre_hosp_accident => o_pre_hosp_accident,
                                   o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                   o_error             => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_types.open_my_cursor(o_pre_hosp_accident);
            pk_types.open_my_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_by_epi;
    --
    /**********************************************************************************************
    * Get current and history data for a given announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param o_ann_arrival_list       cursor with all announced arrival data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION get_ann_arrival_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        o_ann_arrival_list  OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_ANN_ARRIVAL_HIST';
        --
        l_pre_hosp_acc_list table_number;
    BEGIN
    
        g_error := 'GET ANN ARR';
        IF NOT get_ann_arrival_int(i_lang              => i_lang,
                                   i_prof_id           => i_prof.id,
                                   i_prof_inst         => i_prof.institution,
                                   i_prof_sw           => i_prof.software,
                                   i_announced_arrival => i_announced_arrival,
                                   i_episode           => NULL,
                                   o_ann_arrival       => o_ann_arrival_list,
                                   o_error             => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'GET ALL PRE_HOSP_ACC';
        SELECT id_pre_hosp_accident
          BULK COLLECT
          INTO l_pre_hosp_acc_list
          FROM (SELECT aa.id_pre_hosp_accident
                  FROM announced_arrival aa
                 WHERE aa.id_announced_arrival = i_announced_arrival
                UNION
                SELECT aah.id_pre_hosp_accident
                  FROM announced_arrival_hist aah
                 WHERE aah.id_announced_arrival = i_announced_arrival);
    
        g_error := 'GET VS READ';
        IF NOT (pk_pre_hosp_accident.get_vs_read(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_pre_hosp_acc_list => l_pre_hosp_acc_list,
                                                 o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                                 o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_ann_arrival_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_hist;
    --
    /**********************************************************************************************
    * Formats the date to show on screen and on reports
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_date                   date
    *
    * @return                         formated date
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_formated_date
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF i_date IS NULL
        THEN
            RETURN NULL;
        ELSE
            RETURN pk_date_utils.date_chr_short_read_tsz(i_lang, i_date, i_prof) || ' ' || pk_date_utils.date_char_hour_tsz(i_lang,
                                                                                                                            i_date,
                                                                                                                            i_prof.institution,
                                                                                                                            i_prof.software);
        END IF;
    END;
    --
    /**********************************************************************************************
    * Formats the date of birth/age to show on screen and on reports
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_dt_birth               date of birth
    * @param i_age                    age
    *
    * @return                         formated age
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/07/03
    **********************************************************************************************/
    FUNCTION get_formated_age
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_dt_birth IN DATE,
        i_age      IN NUMBER
    ) RETURN VARCHAR2 IS
        l_months NUMBER;
        l_days   NUMBER;
        l_age    VARCHAR2(50);
    BEGIN
        IF (i_dt_birth IS NULL AND i_age IS NULL)
        THEN
            RETURN NULL;
        END IF;
    
        IF (i_dt_birth IS NOT NULL)
        THEN
            l_months := months_between(SYSDATE, i_dt_birth);
            l_days   := (SYSDATE - i_dt_birth);
        ELSE
            l_months := i_age * 12;
        END IF;
    
        IF l_months < 1
        THEN
            l_age := trunc(l_days) || ' ' || pk_message.get_message(i_lang, 'DAY_DESC');
        ELSIF l_months < 36
        THEN
            l_age := trunc(l_months) || ' ' || pk_message.get_message(i_lang, 'MONTH_DESC');
        ELSE
            l_age := trunc(l_months / 12) || ' ' || pk_message.get_message(i_lang, 'YEAR_DESC');
        END IF;
    
        RETURN l_age;
    END get_formated_age;
    --
    /**********************************************************************************************
    * Creates a new episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                patient id
    * @param i_name                   name
    * @param i_gender                 gender
    * @param i_dt_birth               date of birth
    * @param i_age                    age
    * @param o_episode                created episode id
    * @param o_ora_sqlcode            code error
    * @param o_ora_sqlerrm            error message
    * @param o_err_desc               error description
    * @param o_err_action             error action
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/10/28
    **********************************************************************************************/
    FUNCTION create_episode_int
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_name        IN pre_hosp_accident.name%TYPE,
        i_gender      IN pre_hosp_accident.gender%TYPE,
        i_dt_birth    IN pre_hosp_accident.dt_birth%TYPE,
        i_age         IN pre_hosp_accident.age%TYPE,
        o_episode     OUT episode.id_episode%TYPE,
        o_ora_sqlcode OUT VARCHAR2,
        o_ora_sqlerrm OUT VARCHAR2,
        o_err_desc    OUT VARCHAR2,
        o_err_action  OUT VARCHAR2
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_EPISODE_INT';
        --
        l_episode_exception EXCEPTION;
        l_patient_exception EXCEPTION;
        --
        l_error t_error_out;
    BEGIN
        g_error   := 'CREATE EPISODE TEMP';
        o_episode := pk_visit.create_episode_temp(i_lang           => i_lang,
                                                  i_id_prof        => i_prof.id,
                                                  i_id_institution => i_prof.institution,
                                                  i_id_software    => i_prof.software,
                                                  i_id_patient     => i_patient,
                                                  o_ora_sqlcode    => o_ora_sqlcode,
                                                  o_ora_sqlerrm    => o_ora_sqlerrm,
                                                  o_err_desc       => o_err_desc,
                                                  o_err_action     => o_err_action);
    
        IF (o_episode = -1)
        THEN
            RAISE l_episode_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            DECLARE
                l_error_in t_error_in := t_error_in();
                l_ret      BOOLEAN;
            BEGIN
                l_error_in.set_all(i_lang,
                                   o_ora_sqlcode,
                                   o_err_desc,
                                   g_error,
                                   g_pck_owner,
                                   g_pck_name,
                                   l_func_name,
                                   o_ora_sqlcode,
                                   'U');
                l_ret := pk_alert_exceptions.process_error(l_error_in, l_error);
            
                -- Fill error information for JDBC
                o_ora_sqlcode := l_error.ora_sqlcode;
                o_ora_sqlerrm := l_error.ora_sqlerrm;
                o_err_desc    := l_error.err_desc;
                o_err_action  := l_error.err_action;
            
                RETURN FALSE; -- Required by ADT/Coding: do NOT return boolean values!!
            END;
        WHEN l_patient_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_error.ora_sqlcode,
                                              l_error.err_desc,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
        
            -- Fill error information for JDBC
            o_ora_sqlcode := l_error.ora_sqlcode;
            o_ora_sqlerrm := l_error.ora_sqlerrm;
            o_err_desc    := l_error.err_desc;
            o_err_action  := l_error.err_action;
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              l_error);
        
            -- Fill error information for JDBC
            o_ora_sqlcode := l_error.ora_sqlcode;
            o_ora_sqlerrm := l_error.ora_sqlerrm;
            o_err_desc    := l_error.err_desc;
            o_err_action  := l_error.err_action;
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_episode_int;
    --
    /**********************************************************************************************
    * Create new record with announced arrival data
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids     
    * @param i_name                   patient name
    * @param i_gender                 patient gender
    * @param i_dt_birth               patient birth date
    * @param i_age                    patient age
    * @param i_address                patient address
    * @param i_city                   patient city
    * @param i_pat_zip_code           patient address zip code
    * @param i_dt_report_mka          moment of report to MKA
    * @param i_cpa_code               CPA code
    * @param i_transport_number       ambulance ride number
    * @param i_acc_zip_code           zip code where the accident took place
    * @param i_latitude               latitude
    * @param i_longitude              longitude
    * @param i_dt_ride_out            moment of ride out to the patient/incident
    * @param i_dt_arrival             moment of arrival at the patient/incident
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_dt_accident            time of accident        
    * @param i_type_injury            type of injury or problem
    * @param i_condition              patient condition
    * @param i_referred_by            who reported the accident
    * @param i_speciality             speciality od the emergency physician
    * @param i_ed_physician           emergency department physician
    * @param i_dt_expected_arrival    expected time of patient arrival
    * @param i_patient                id_patient - when the patient and episode are going to be created
    * @param i_episode                id_episode - when the patent and episode already exists and we are going to register history of pre_hosp
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param o_announced_arrival      id_announced_arrival of the new record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION create_ann_arrival_int
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_name                IN pre_hosp_accident.name%TYPE,
        i_gender              IN pre_hosp_accident.gender%TYPE,
        i_dt_birth            IN VARCHAR2,
        i_age                 IN pre_hosp_accident.age%TYPE,
        i_address             IN pre_hosp_accident.address%TYPE,
        i_city                IN pre_hosp_accident.city%TYPE,
        i_pat_zip_code        IN pre_hosp_accident.pat_zip_code%TYPE,
        i_dt_report_mka       IN VARCHAR2,
        i_cpa_code            IN pre_hosp_accident.cpa_code%TYPE,
        i_transport_number    IN pre_hosp_accident.transport_number%TYPE,
        i_acc_zip_code        IN pre_hosp_accident.acc_zip_code%TYPE,
        i_latitude            IN pre_hosp_accident.latitude%TYPE,
        i_longitude           IN pre_hosp_accident.longitude%TYPE,
        i_dt_ride_out         IN VARCHAR2,
        i_dt_arrival          IN VARCHAR2,
        i_dt_drv_away         IN VARCHAR2,
        i_flg_mech_inj        IN pre_hosp_accident.flg_mech_inj%TYPE,
        i_mech_injury         IN pre_hosp_accident.mech_injury%TYPE,
        i_vs_id               IN table_number,
        i_vs_val              IN table_number,
        i_unit_meas           IN table_number,
        i_dt_accident         IN VARCHAR2,
        i_type_injury         IN announced_arrival.type_injury%TYPE,
        i_condition           IN announced_arrival.condition%TYPE,
        i_referred_by         IN announced_arrival.referred_by%TYPE,
        i_speciality          IN announced_arrival.id_speciality%TYPE,
        i_clinical_service    IN announced_arrival.id_clinical_service%TYPE,
        i_ed_physician        IN announced_arrival.id_ed_physician%TYPE,
        i_dt_expected_arrival IN VARCHAR2,
        i_patient             IN patient.id_patient%TYPE,
        i_episode             IN episode.id_episode%TYPE,
        i_flg_prot_device     IN pre_hosp_accident.flg_prot_device%TYPE,
        i_flg_rta_pat_typ     IN pre_hosp_accident.flg_rta_pat_typ%TYPE,
        i_rta_pat_typ_ft      IN pre_hosp_accident.rta_pat_typ_ft%TYPE,
        i_flg_is_driv_own     IN pre_hosp_accident.flg_is_driv_own%TYPE,
        i_flg_police_involved IN pre_hosp_accident.flg_police_involved%TYPE,
        i_police_num          IN pre_hosp_accident.police_num%TYPE,
        i_police_station      IN pre_hosp_accident.police_station%TYPE,
        i_police_accident_num IN pre_hosp_accident.police_accident_num%TYPE,
        i_id_amb_trust_code   IN pre_hosp_accident.id_amb_trust_code%TYPE,
        i_ambulance_trust     IN VARCHAR2,
        
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'CREATE_ANN_ARRIVAL_INT';
        l_rows_ann_arriv    table_varchar;
        l_announced_arrival announced_arrival.id_announced_arrival%TYPE;
        l_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_flg_status        announced_arrival.flg_status%TYPE;
        l_patient           patient.id_patient%TYPE;
        --
        l_flg_epi_type announced_arrival.flg_epi_type%TYPE;
        l_episode      announced_arrival.id_episode%TYPE;
        l_flg_stage    care_stage.flg_stage%TYPE;
        l_date         VARCHAR2(50);
        --
        l_episode_exception EXCEPTION;
        l_ora_sqlcode VARCHAR2(200);
        l_ora_sqlerrm VARCHAR2(4000);
        l_err_desc    VARCHAR2(4000);
        l_err_action  VARCHAR2(4000);
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        IF (i_patient IS NULL AND i_episode IS NOT NULL)
        THEN
            l_flg_epi_type := g_aa_arr_epi_type_p;
            l_episode      := i_episode;
            l_flg_status   := pk_announced_arrival.g_aa_arrival_status_a;
        
            g_error := 'GET EPIS ID_PATIENT';
            BEGIN
                SELECT e.id_patient
                  INTO l_patient
                  FROM episode e
                 WHERE e.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    RAISE e_call_error;
            END;
        
        ELSIF (i_patient IS NOT NULL AND i_episode IS NULL)
        THEN
            --  l_flg_epi_type := g_aa_arr_epi_type_a;
        
            l_flg_status := pk_announced_arrival.g_aa_arrival_status_e;
            l_patient    := i_patient;
            /*            g_error := 'CREATE EPISODE TEMP';
            IF NOT create_episode_int(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_patient     => i_patient,
                                      i_name        => i_name,
                                      i_gender      => i_gender,
                                      i_dt_birth    => pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_birth, NULL),
                                      i_age         => i_age,
                                      o_episode     => l_episode,
                                      o_ora_sqlcode => l_ora_sqlcode,
                                      o_ora_sqlerrm => l_ora_sqlerrm,
                                      o_err_desc    => l_err_desc,
                                      o_err_action  => l_err_action)
            THEN
                RAISE l_episode_exception;
            END IF;*/
        ELSE
            g_error := 'PAT AND EPI BOTH FILLED OR BOTH NULL';
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET NEW ID_PRE_HOSP_VS_READ';
        SELECT seq_announced_arrival.nextval
          INTO l_announced_arrival
          FROM dual;
    
        g_error := 'INS ANNOUNCED_ARRIVAL';
        ts_announced_arrival.ins(id_announced_arrival_in => l_announced_arrival,
                                 id_pre_hosp_accident_in => -1,
                                 id_episode_in           => l_episode,
                                 flg_epi_type_in         => l_flg_epi_type,
                                 type_injury_in          => i_type_injury,
                                 condition_in            => i_condition,
                                 referred_by_in          => i_referred_by,
                                 id_speciality_in        => i_speciality,
                                 id_clinical_service_in  => i_clinical_service,
                                 id_ed_physician_in      => i_ed_physician,
                                 dt_expected_arrival_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_expected_arrival,
                                                                                          NULL),
                                 flg_status_in           => l_flg_status,
                                 dt_announced_arrival_in => g_sysdate_tstz,
                                 id_patient_in           => l_patient,
                                 rows_out                => l_rows_ann_arriv);
    
        g_error := 'VALIDATE INSERTED ROW';
        IF (l_rows_ann_arriv.count != 1)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'INS PRE_HOSP_ACCIDENT';
        IF NOT (pk_pre_hosp_accident.create_pre_hosp_acc(i_lang                => i_lang,
                                                         i_prof                => i_prof,
                                                         i_dt_accident         => i_dt_accident,
                                                         i_name                => i_name,
                                                         i_gender              => i_gender,
                                                         i_dt_birth            => i_dt_birth,
                                                         i_age                 => i_age,
                                                         i_address             => i_address,
                                                         i_city                => i_city,
                                                         i_pat_zip_code        => i_pat_zip_code,
                                                         i_dt_report_mka       => i_dt_report_mka,
                                                         i_cpa_code            => i_cpa_code,
                                                         i_transport_number    => i_transport_number,
                                                         i_acc_zip_code        => i_acc_zip_code,
                                                         i_latitude            => i_latitude,
                                                         i_longitude           => i_longitude,
                                                         i_dt_ride_out         => i_dt_ride_out,
                                                         i_dt_arrival          => i_dt_arrival,
                                                         i_flg_mech_inj        => i_flg_mech_inj,
                                                         i_mech_injury         => i_mech_injury,
                                                         i_dt_drv_away         => i_dt_drv_away,
                                                         i_episode             => l_episode,
                                                         i_vs_id               => i_vs_id,
                                                         i_vs_val              => i_vs_val,
                                                         i_unit_meas           => i_unit_meas,
                                                         i_flg_prot_device     => i_flg_prot_device,
                                                         i_flg_rta_pat_typ     => i_flg_rta_pat_typ,
                                                         i_rta_pat_typ_ft      => i_rta_pat_typ_ft,
                                                         i_flg_is_driv_own     => i_flg_is_driv_own,
                                                         i_flg_police_involved => i_flg_police_involved,
                                                         i_police_num          => i_police_num,
                                                         i_police_station      => i_police_station,
                                                         i_police_accident_num => i_police_accident_num,
                                                         i_id_amb_trust_code   => i_id_amb_trust_code,
                                                         i_ambulance_trust     => i_ambulance_trust,
                                                         
                                                         i_flg_commit => FALSE,
                                                         
                                                         o_pre_hosp_accident => l_pre_hosp_accident,
                                                         o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'UPDATE ANNOUNCED_ARRIVAL WITH PRE_HOSP KEY';
        UPDATE announced_arrival aa
           SET aa.id_pre_hosp_accident = l_pre_hosp_accident
         WHERE aa.id_announced_arrival = l_announced_arrival
           AND aa.id_pre_hosp_accident = -1;
    
        g_error := 'PROCESS_INSERT ANN_ARRIV';
        --The process insert is only done here because when creating pre_hosp_accident it calls set_first_obs
        --and this must only be done after the creation of ann_arriv
        t_data_gov_mnt.process_insert(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows_ann_arriv,
                                      o_error      => o_error);
    
        g_error     := 'GET INITIAL CARE STAGE';
        l_flg_stage := pk_sysconfig.get_config(g_care_stage_expected, i_prof);
    
        g_error := 'SET CARE STAGE';
        --        IF NOT (pk_patient_tracking.set_care_stage_no_commit(i_lang      => i_lang,
        --                                                             i_prof      => i_prof,
        --                                                             i_episode   => l_episode,
        --                                                             i_flg_stage => l_flg_stage,
        ----                                                             o_date      => l_date,
        --                                                             o_error     => o_error))
        --        THEN
        --            RAISE e_call_error;
        --        END IF;
    
        g_error := 'INS ALERT';
        IF i_ed_physician IS NOT NULL
        THEN
            IF NOT
                set_alert(i_lang              => i_lang,
                          i_prof              => i_prof,
                          i_announced_arrival => l_announced_arrival,
                          i_episode           => l_episode,
                          i_professional      => i_ed_physician,
                          i_dt_record         => pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_expected_arrival, NULL),
                          i_replace1          => i_type_injury,
                          i_type              => g_alert_type_add,
                          o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        o_announced_arrival := l_announced_arrival;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_ora_sqlcode,
                                              l_ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_ann_arrival_int;
    --
    /**********************************************************************************************
    * Create new record with announced arrival data (Used by flash on announced arrival grid)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_name                   patient name
    * @param i_gender                 patient gender
    * @param i_dt_birth               patient birth date
    * @param i_age                    patient age
    * @param i_address                patient address
    * @param i_city                   patient city
    * @param i_pat_zip_code           patient address zip code
    * @param i_dt_report_mka          moment of report to MKA
    * @param i_cpa_code               CPA code
    * @param i_transport_number       ambulance ride number
    * @param i_acc_zip_code           zip code where the accident took place
    * @param i_latitude               latitude
    * @param i_longitude              longitude
    * @param i_dt_ride_out            moment of ride out to the patient/incident
    * @param i_dt_arrival             moment of arrival at the patient/incident
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_dt_accident            time of accident        
    * @param i_type_injury            type of injury or problem
    * @param i_condition              patient condition
    * @param i_referred_by            who reported the accident
    * @param i_speciality             speciality od the emergency physician
    * @param i_ed_physician           emergency department physician
    * @param i_dt_expected_arrival    expected time of patient arrival
    * @param i_patient                id_patient
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param o_announced_arrival      id_announced_arrival of the new record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION create_ann_arrival_by_pat
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_name                IN pre_hosp_accident.name%TYPE,
        i_gender              IN pre_hosp_accident.gender%TYPE,
        i_dt_birth            IN VARCHAR2,
        i_age                 IN pre_hosp_accident.age%TYPE,
        i_address             IN pre_hosp_accident.address%TYPE,
        i_city                IN pre_hosp_accident.city%TYPE,
        i_pat_zip_code        IN pre_hosp_accident.pat_zip_code%TYPE,
        i_dt_report_mka       IN VARCHAR2,
        i_cpa_code            IN pre_hosp_accident.cpa_code%TYPE,
        i_transport_number    IN pre_hosp_accident.transport_number%TYPE,
        i_acc_zip_code        IN pre_hosp_accident.acc_zip_code%TYPE,
        i_latitude            IN pre_hosp_accident.latitude%TYPE,
        i_longitude           IN pre_hosp_accident.longitude%TYPE,
        i_dt_ride_out         IN VARCHAR2,
        i_dt_arrival          IN VARCHAR2,
        i_dt_drv_away         IN VARCHAR2,
        i_flg_mech_inj        IN pre_hosp_accident.flg_mech_inj%TYPE,
        i_mech_injury         IN pre_hosp_accident.mech_injury%TYPE,
        i_vs_id               IN table_number,
        i_vs_val              IN table_number,
        i_unit_meas           IN table_number,
        i_dt_accident         IN VARCHAR2,
        i_type_injury         IN announced_arrival.type_injury%TYPE,
        i_condition           IN announced_arrival.condition%TYPE,
        i_referred_by         IN announced_arrival.referred_by%TYPE,
        i_speciality          IN announced_arrival.id_speciality%TYPE,
        i_clinical_service    IN announced_arrival.id_clinical_service%TYPE,
        i_ed_physician        IN announced_arrival.id_ed_physician%TYPE,
        i_dt_expected_arrival IN VARCHAR2,
        i_patient             IN patient.id_patient%TYPE,
        i_flg_prot_device     IN pre_hosp_accident.flg_prot_device%TYPE,
        i_flg_rta_pat_typ     IN pre_hosp_accident.flg_rta_pat_typ%TYPE,
        i_rta_pat_typ_ft      IN pre_hosp_accident.rta_pat_typ_ft%TYPE,
        i_flg_is_driv_own     IN pre_hosp_accident.flg_is_driv_own%TYPE,
        i_flg_police_involved IN pre_hosp_accident.flg_police_involved%TYPE,
        i_police_num          IN pre_hosp_accident.police_num%TYPE,
        i_police_station      IN pre_hosp_accident.police_station%TYPE,
        i_police_accident_num IN pre_hosp_accident.police_accident_num%TYPE,
        i_id_amb_trust_code   IN pre_hosp_accident.id_amb_trust_code%TYPE,
        i_ambulance_trust     IN VARCHAR2,
        
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_ANN_ARRIVAL_BY_PAT';
        l_episode_exception EXCEPTION;
    BEGIN
        IF NOT create_ann_arrival_int(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_name                => i_name,
                                      i_gender              => i_gender,
                                      i_dt_birth            => i_dt_birth,
                                      i_age                 => i_age,
                                      i_address             => i_address,
                                      i_city                => i_city,
                                      i_pat_zip_code        => i_pat_zip_code,
                                      i_dt_report_mka       => i_dt_report_mka,
                                      i_cpa_code            => i_cpa_code,
                                      i_transport_number    => i_transport_number,
                                      i_acc_zip_code        => i_acc_zip_code,
                                      i_latitude            => i_latitude,
                                      i_longitude           => i_longitude,
                                      i_dt_ride_out         => i_dt_ride_out,
                                      i_dt_arrival          => i_dt_arrival,
                                      i_dt_drv_away         => i_dt_drv_away,
                                      i_flg_mech_inj        => i_flg_mech_inj,
                                      i_mech_injury         => i_mech_injury,
                                      i_vs_id               => i_vs_id,
                                      i_vs_val              => i_vs_val,
                                      i_unit_meas           => i_unit_meas,
                                      i_dt_accident         => i_dt_accident,
                                      i_type_injury         => i_type_injury,
                                      i_condition           => i_condition,
                                      i_referred_by         => i_referred_by,
                                      i_speciality          => i_speciality,
                                      i_clinical_service    => i_clinical_service,
                                      i_ed_physician        => i_ed_physician,
                                      i_dt_expected_arrival => i_dt_expected_arrival,
                                      i_patient             => i_patient,
                                      i_episode             => NULL,
                                      i_flg_prot_device     => i_flg_prot_device,
                                      i_flg_rta_pat_typ     => i_flg_rta_pat_typ,
                                      i_rta_pat_typ_ft      => i_rta_pat_typ_ft,
                                      i_flg_is_driv_own     => i_flg_is_driv_own,
                                      i_flg_police_involved => i_flg_police_involved,
                                      i_police_num          => i_police_num,
                                      i_police_station      => i_police_station,
                                      i_police_accident_num => i_police_accident_num,
                                      i_id_amb_trust_code   => i_id_amb_trust_code,
                                      i_ambulance_trust     => i_ambulance_trust,
                                      
                                      o_announced_arrival => o_announced_arrival,
                                      o_error             => o_error)
        THEN
            RAISE l_episode_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_ann_arrival_by_pat;
    --
    /**********************************************************************************************
    * Create new record with announced arrival data (Used by flash on patient area Pre-Hospital and Trauma)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_name                   patient name
    * @param i_gender                 patient gender
    * @param i_dt_birth               patient birth date
    * @param i_age                    patient age
    * @param i_address                patient address
    * @param i_city                   patient city
    * @param i_pat_zip_code           patient address zip code
    * @param i_dt_report_mka          moment of report to MKA
    * @param i_cpa_code               CPA code
    * @param i_ambulance_number       ambulance ride number
    * @param i_acc_zip_code           zip code where the accident took place
    * @param i_latitude               latitude
    * @param i_longitude              longitude
    * @param i_dt_ride_out            moment of ride out to the patient/incident
    * @param i_dt_arrival             moment of arrival at the patient/incident
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_episode                episode id or -1 if doesn't exists
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_type_injury            type of injury or problem
    * @param i_condition              patient condition
    * @param i_referred_by            who reported the accident
    * @param i_speciality             speciality od the emergency physician
    * @param i_ed_physician           emergency department physician
    * @param i_dt_expected_arrival    expected time of patient arrival
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param o_announced_arrival      id_announced_arrival of the new record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION create_ann_arrival_by_epi
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dt_accident         IN VARCHAR2,
        i_name                IN pre_hosp_accident.name%TYPE,
        i_gender              IN pre_hosp_accident.gender%TYPE,
        i_dt_birth            IN VARCHAR2,
        i_age                 IN pre_hosp_accident.age%TYPE,
        i_address             IN pre_hosp_accident.address%TYPE,
        i_city                IN pre_hosp_accident.city%TYPE,
        i_pat_zip_code        IN pre_hosp_accident.pat_zip_code%TYPE,
        i_dt_report_mka       IN VARCHAR2,
        i_cpa_code            IN pre_hosp_accident.cpa_code%TYPE,
        i_transport_number    IN pre_hosp_accident.transport_number%TYPE,
        i_acc_zip_code        IN pre_hosp_accident.acc_zip_code%TYPE,
        i_latitude            IN pre_hosp_accident.latitude%TYPE,
        i_longitude           IN pre_hosp_accident.longitude%TYPE,
        i_dt_ride_out         IN VARCHAR2,
        i_dt_arrival          IN VARCHAR2,
        i_flg_mech_inj        IN pre_hosp_accident.flg_mech_inj%TYPE,
        i_mech_injury         IN pre_hosp_accident.mech_injury%TYPE,
        i_dt_drv_away         IN VARCHAR2,
        i_episode             IN vital_sign_read.id_episode%TYPE,
        i_vs_id               IN table_number,
        i_vs_val              IN table_number,
        i_unit_meas           IN table_number,
        i_type_injury         IN announced_arrival.type_injury%TYPE,
        i_condition           IN announced_arrival.condition%TYPE,
        i_referred_by         IN announced_arrival.referred_by%TYPE,
        i_speciality          IN announced_arrival.id_speciality%TYPE,
        i_clinical_service    IN announced_arrival.id_clinical_service%TYPE,
        i_ed_physician        IN announced_arrival.id_ed_physician%TYPE,
        i_dt_expected_arrival IN VARCHAR2,
        i_flg_prot_device     IN pre_hosp_accident.flg_prot_device%TYPE,
        i_flg_rta_pat_typ     IN pre_hosp_accident.flg_rta_pat_typ%TYPE,
        i_rta_pat_typ_ft      IN pre_hosp_accident.rta_pat_typ_ft%TYPE,
        i_flg_is_driv_own     IN pre_hosp_accident.flg_is_driv_own%TYPE,
        i_flg_police_involved IN pre_hosp_accident.flg_police_involved%TYPE,
        i_police_num          IN pre_hosp_accident.police_num%TYPE,
        i_police_station      IN pre_hosp_accident.police_station%TYPE,
        i_police_accident_num IN pre_hosp_accident.police_accident_num%TYPE,
        i_id_amb_trust_code   IN pre_hosp_accident.id_amb_trust_code%TYPE,
        i_ambulance_trust     IN VARCHAR2,
        o_announced_arrival   OUT announced_arrival.id_announced_arrival%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_ANN_ARRIVAL_BY_EPI';
        l_episode_exception EXCEPTION;
    BEGIN
        IF NOT create_ann_arrival_int(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_name                => i_name,
                                      i_gender              => i_gender,
                                      i_dt_birth            => i_dt_birth,
                                      i_age                 => i_age,
                                      i_address             => i_address,
                                      i_city                => i_city,
                                      i_pat_zip_code        => i_pat_zip_code,
                                      i_dt_report_mka       => i_dt_report_mka,
                                      i_cpa_code            => i_cpa_code,
                                      i_transport_number    => i_transport_number,
                                      i_acc_zip_code        => i_acc_zip_code,
                                      i_latitude            => i_latitude,
                                      i_longitude           => i_longitude,
                                      i_dt_ride_out         => i_dt_ride_out,
                                      i_dt_arrival          => i_dt_arrival,
                                      i_dt_drv_away         => i_dt_drv_away,
                                      i_flg_mech_inj        => i_flg_mech_inj,
                                      i_mech_injury         => i_mech_injury,
                                      i_vs_id               => i_vs_id,
                                      i_vs_val              => i_vs_val,
                                      i_unit_meas           => i_unit_meas,
                                      i_dt_accident         => i_dt_accident,
                                      i_type_injury         => i_type_injury,
                                      i_condition           => i_condition,
                                      i_referred_by         => i_referred_by,
                                      i_speciality          => i_speciality,
                                      i_clinical_service    => i_clinical_service,
                                      i_ed_physician        => i_ed_physician,
                                      i_dt_expected_arrival => i_dt_expected_arrival,
                                      i_patient             => NULL,
                                      i_episode             => i_episode,
                                      i_flg_prot_device     => i_flg_prot_device,
                                      i_flg_rta_pat_typ     => i_flg_rta_pat_typ,
                                      i_rta_pat_typ_ft      => i_rta_pat_typ_ft,
                                      i_flg_is_driv_own     => i_flg_is_driv_own,
                                      i_flg_police_involved => i_flg_police_involved,
                                      i_police_num          => i_police_num,
                                      i_police_station      => i_police_station,
                                      i_police_accident_num => i_police_accident_num,
                                      i_id_amb_trust_code   => i_id_amb_trust_code,
                                      i_ambulance_trust     => i_ambulance_trust,
                                      o_announced_arrival   => o_announced_arrival,
                                      o_error               => o_error)
        THEN
            RAISE l_episode_exception;
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END create_ann_arrival_by_epi;
    --
    /**********************************************************************************************
    * Updates announced arrival data
    *
    * @param i_lang                   the id language
    * @param i_announced_arrival      announced arrival id
    * @param i_prof                   professional, software and institution ids             
    * @param i_name                   patient name
    * @param i_gender                 patient gender
    * @param i_dt_birth               patient birth date
    * @param i_age                    patient age
    * @param i_address                patient address
    * @param i_city                   patient city
    * @param i_pat_zip_code           patient address zip code
    * @param i_dt_report_mka          moment of report to MKA
    * @param i_cpa_code               CPA code
    * @param i_transport_number       ambulance ride number
    * @param i_acc_zip_code           zip code where the accident took place
    * @param i_latitude               latitude
    * @param i_longitude              longitude
    * @param i_dt_ride_out            moment of ride out to the patient/incident
    * @param i_dt_arrival             moment of arrival at the patient/incident
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_dt_accident            time of accident        
    * @param i_type_injury            type of injury or problem
    * @param i_condition              patient condition
    * @param i_referred_by            who reported the accident
    * @param i_speciality             speciality od the emergency physician
    * @param i_ed_physician           emergency department physician
    * @param i_dt_expected_arrival    expected time of patient arrival
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_ann_arrival
    (
        i_lang                IN language.id_language%TYPE,
        i_announced_arrival   IN announced_arrival.id_announced_arrival%TYPE,
        i_prof                IN profissional,
        i_name                IN pre_hosp_accident.name%TYPE,
        i_gender              IN pre_hosp_accident.gender%TYPE,
        i_dt_birth            IN VARCHAR2,
        i_age                 IN pre_hosp_accident.age%TYPE,
        i_address             IN pre_hosp_accident.address%TYPE,
        i_city                IN pre_hosp_accident.city%TYPE,
        i_pat_zip_code        IN pre_hosp_accident.pat_zip_code%TYPE,
        i_dt_report_mka       IN VARCHAR2,
        i_cpa_code            IN pre_hosp_accident.cpa_code%TYPE,
        i_transport_number    IN pre_hosp_accident.transport_number%TYPE,
        i_acc_zip_code        IN pre_hosp_accident.acc_zip_code%TYPE,
        i_latitude            IN pre_hosp_accident.latitude%TYPE,
        i_longitude           IN pre_hosp_accident.longitude%TYPE,
        i_dt_ride_out         IN VARCHAR2,
        i_dt_arrival          IN VARCHAR2,
        i_dt_drv_away         IN VARCHAR2,
        i_flg_mech_inj        IN pre_hosp_accident.flg_mech_inj%TYPE,
        i_mech_injury         IN pre_hosp_accident.mech_injury%TYPE,
        i_vs_id               IN table_number,
        i_vs_val              IN table_number,
        i_unit_meas           IN table_number,
        i_dt_accident         IN VARCHAR2,
        i_type_injury         IN announced_arrival.type_injury%TYPE,
        i_condition           IN announced_arrival.condition%TYPE,
        i_referred_by         IN announced_arrival.referred_by%TYPE,
        i_speciality          IN announced_arrival.id_speciality%TYPE,
        i_clinical_service    IN announced_arrival.id_clinical_service%TYPE,
        i_ed_physician        IN announced_arrival.id_ed_physician%TYPE,
        i_dt_expected_arrival IN VARCHAR2,
        i_flg_prot_device     IN pre_hosp_accident.flg_prot_device%TYPE,
        i_flg_rta_pat_typ     IN pre_hosp_accident.flg_rta_pat_typ%TYPE,
        i_rta_pat_typ_ft      IN pre_hosp_accident.rta_pat_typ_ft%TYPE,
        i_flg_is_driv_own     IN pre_hosp_accident.flg_is_driv_own%TYPE,
        i_flg_police_involved IN pre_hosp_accident.flg_police_involved%TYPE,
        i_police_num          IN pre_hosp_accident.police_num%TYPE,
        i_police_station      IN pre_hosp_accident.police_station%TYPE,
        i_police_accident_num IN pre_hosp_accident.police_accident_num%TYPE,
        i_id_amb_trust_code   IN pre_hosp_accident.id_amb_trust_code%TYPE,
        i_ambulance_trust     IN VARCHAR2,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(30) := 'SET_ANN_ARRIVAL';
        l_old_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_new_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_old_ed_physician      announced_arrival.id_ed_physician%TYPE;
        l_ann_arr_hist          announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_episode               announced_arrival.id_episode%TYPE;
        l_patient               patient.id_patient%TYPE;
        l_rows                  table_varchar;
        l_error EXCEPTION;
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'INS ANN ARR HIST';
        IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                      i_announced_arrival      => i_announced_arrival,
                                                      i_flg_commit             => FALSE,
                                                      o_announced_arrival_hist => l_ann_arr_hist,
                                                      o_pre_hosp_accident      => l_old_pre_hosp_accident,
                                                      o_error                  => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET ID_EPISODE AND ID_PATIENT';
        BEGIN
            SELECT aa.id_episode, aa.id_patient
              INTO l_episode, l_patient
              FROM announced_arrival aa
              LEFT JOIN episode epis
                ON epis.id_episode = aa.id_episode
             WHERE aa.id_announced_arrival = i_announced_arrival;
        EXCEPTION
            WHEN no_data_found THEN
                l_episode := -1;
                l_patient := NULL;
        END;
    
        g_error := 'UPD PRE_HOSP_ACCIDENT';
        IF NOT (pk_pre_hosp_accident.set_pre_hosp_acc(i_lang                => i_lang,
                                                      i_pre_hosp_accident   => l_old_pre_hosp_accident,
                                                      i_prof                => i_prof,
                                                      i_dt_accident         => i_dt_accident,
                                                      i_name                => i_name,
                                                      i_gender              => i_gender,
                                                      i_dt_birth            => i_dt_birth,
                                                      i_age                 => i_age,
                                                      i_address             => i_address,
                                                      i_city                => i_city,
                                                      i_pat_zip_code        => i_pat_zip_code,
                                                      i_dt_report_mka       => i_dt_report_mka,
                                                      i_cpa_code            => i_cpa_code,
                                                      i_transport_number    => i_transport_number,
                                                      i_acc_zip_code        => i_acc_zip_code,
                                                      i_latitude            => i_latitude,
                                                      i_longitude           => i_longitude,
                                                      i_dt_ride_out         => i_dt_ride_out,
                                                      i_dt_arrival          => i_dt_arrival,
                                                      i_flg_mech_inj        => i_flg_mech_inj,
                                                      i_mech_injury         => i_mech_injury,
                                                      i_dt_drv_away         => i_dt_drv_away,
                                                      i_episode             => l_episode,
                                                      i_vs_id               => i_vs_id,
                                                      i_vs_val              => i_vs_val,
                                                      i_unit_meas           => i_unit_meas,
                                                      i_flg_prot_device     => i_flg_prot_device,
                                                      i_flg_rta_pat_typ     => i_flg_rta_pat_typ,
                                                      i_rta_pat_typ_ft      => i_rta_pat_typ_ft,
                                                      i_flg_is_driv_own     => i_flg_is_driv_own,
                                                      i_flg_police_involved => i_flg_police_involved,
                                                      i_police_num          => i_police_num,
                                                      i_police_station      => i_police_station,
                                                      i_police_accident_num => i_police_accident_num,
                                                      i_id_amb_trust_code   => i_id_amb_trust_code,
                                                      i_ambulance_trust     => i_ambulance_trust,
                                                      i_flg_commit          => FALSE,
                                                      o_pre_hosp_accident   => l_new_pre_hosp_accident,
                                                      o_error               => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET OLD ED_PHYSICIAN';
        SELECT aa.id_ed_physician
          INTO l_old_ed_physician
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        IF l_old_ed_physician IS NOT NULL
        THEN
            g_error := 'REMOVE ALERT';
            IF NOT set_alert(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_announced_arrival => i_announced_arrival,
                             i_professional      => l_old_ed_physician,
                             i_type              => g_alert_type_rem,
                             o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        g_error := 'INS ALERT';
        IF i_ed_physician IS NOT NULL
        THEN
            IF NOT
                set_alert(i_lang              => i_lang,
                          i_prof              => i_prof,
                          i_announced_arrival => i_announced_arrival,
                          i_episode           => l_episode,
                          i_professional      => i_ed_physician,
                          i_dt_record         => pk_date_utils.get_string_tstz(i_lang, i_prof, i_dt_expected_arrival, NULL),
                          i_replace1          => i_type_injury,
                          i_type              => g_alert_type_add,
                          o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        g_error := 'UPD PRE_HOSP KEY';
        --O histórico é mantido na tabela announced_arrival_hist, logo actualizando-se a chave n??o se perde informa????o
        UPDATE announced_arrival aa
           SET aa.id_pre_hosp_accident = l_new_pre_hosp_accident
         WHERE aa.id_announced_arrival = i_announced_arrival
           AND aa.id_pre_hosp_accident = l_old_pre_hosp_accident;
    
        g_error := 'UPD ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                 id_pre_hosp_accident_in => l_new_pre_hosp_accident,
                                 type_injury_in          => i_type_injury,
                                 type_injury_nin         => FALSE,
                                 condition_in            => i_condition,
                                 condition_nin           => FALSE,
                                 referred_by_in          => i_referred_by,
                                 referred_by_nin         => FALSE,
                                 id_speciality_in        => i_speciality,
                                 id_speciality_nin       => FALSE,
                                 id_clinical_service_in  => i_clinical_service,
                                 id_clinical_service_nin => FALSE,
                                 id_ed_physician_in      => i_ed_physician,
                                 id_ed_physician_nin     => FALSE,
                                 dt_expected_arrival_in  => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_expected_arrival,
                                                                                          NULL),
                                 dt_expected_arrival_nin => FALSE,
                                 dt_announced_arrival_in => g_sysdate_tstz,
                                 rows_out                => l_rows);
    
        g_error := 'PROCESS_UPDATE ANN_ARRIV';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_pre_hosp_accident.g_usr_info_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ann_arrival;
    --
    /**********************************************************************************************
    * Updates announced arrival data - Pre-Hospital/Trauma screens
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_name                   patient name
    * @param i_gender                 patient gender
    * @param i_dt_birth               patient birth date
    * @param i_age                    patient age
    * @param i_address                patient address
    * @param i_city                   patient city
    * @param i_pat_zip_code           patient address zip code
    * @param i_dt_report_mka          moment of report to MKA
    * @param i_cpa_code               CPA code
    * @param i_transport_number       ambulance ride number
    * @param i_acc_zip_code           zip code where the accident took place
    * @param i_latitude               latitude
    * @param i_longitude              longitude
    * @param i_dt_ride_out            moment of ride out to the patient/incident
    * @param i_dt_arrival             moment of arrival at the patient/incident
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_episode                episode id or -1 if doesn't exists
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_pre_hosp_accident      id_pre_hosp_accident of the created record
    * @param o_error                  Error message
    * @param i_type_injury            type of injury or problem
    * @param i_condition              patient condition
    * @param i_referred_by            who reported the accident
    * @param i_speciality             speciality od the emergency physician
    * @param i_ed_physician           emergency department physician
    * @param i_dt_expected_arrival    expected time of patient arrival
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_ann_arrival_pre_hosp
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_announced_arrival   IN announced_arrival.id_announced_arrival%TYPE,
        i_dt_accident         IN VARCHAR2,
        i_name                IN pre_hosp_accident.name%TYPE,
        i_gender              IN pre_hosp_accident.gender%TYPE,
        i_dt_birth            IN VARCHAR2,
        i_age                 IN pre_hosp_accident.age%TYPE,
        i_address             IN pre_hosp_accident.address%TYPE,
        i_city                IN pre_hosp_accident.city%TYPE,
        i_pat_zip_code        IN pre_hosp_accident.pat_zip_code%TYPE,
        i_dt_report_mka       IN VARCHAR2,
        i_cpa_code            IN pre_hosp_accident.cpa_code%TYPE,
        i_transport_number    IN pre_hosp_accident.transport_number%TYPE,
        i_acc_zip_code        IN pre_hosp_accident.acc_zip_code%TYPE,
        i_latitude            IN pre_hosp_accident.latitude%TYPE,
        i_longitude           IN pre_hosp_accident.longitude%TYPE,
        i_dt_ride_out         IN VARCHAR2,
        i_dt_arrival          IN VARCHAR2,
        i_flg_mech_inj        IN pre_hosp_accident.flg_mech_inj%TYPE,
        i_mech_injury         IN pre_hosp_accident.mech_injury%TYPE,
        i_dt_drv_away         IN VARCHAR2,
        i_episode             IN vital_sign_read.id_episode%TYPE,
        i_vs_id               IN table_number,
        i_vs_val              IN table_number,
        i_unit_meas           IN table_number,
        i_type_injury         IN announced_arrival.type_injury%TYPE,
        i_condition           IN announced_arrival.condition%TYPE,
        i_referred_by         IN announced_arrival.referred_by%TYPE,
        i_speciality          IN announced_arrival.id_speciality%TYPE,
        i_clinical_service    IN announced_arrival.id_clinical_service%TYPE,
        i_ed_physician        IN announced_arrival.id_ed_physician%TYPE,
        i_dt_expected_arrival IN VARCHAR2,
        i_flg_prot_device     IN pre_hosp_accident.flg_prot_device%TYPE,
        i_flg_rta_pat_typ     IN pre_hosp_accident.flg_rta_pat_typ%TYPE,
        i_rta_pat_typ_ft      IN pre_hosp_accident.rta_pat_typ_ft%TYPE,
        i_flg_is_driv_own     IN pre_hosp_accident.flg_is_driv_own%TYPE,
        i_flg_police_involved IN pre_hosp_accident.flg_police_involved%TYPE,
        i_police_num          IN pre_hosp_accident.police_num%TYPE,
        i_police_station      IN pre_hosp_accident.police_station%TYPE,
        i_police_accident_num IN pre_hosp_accident.police_accident_num%TYPE,
        i_id_amb_trust_code   IN pre_hosp_accident.id_amb_trust_code%TYPE,
        i_ambulance_trust     IN VARCHAR2,
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_ANN_ARRIVAL_PRE_HOSP';
    BEGIN
        IF NOT (pk_announced_arrival.set_ann_arrival(i_lang                => i_lang,
                                                     i_announced_arrival   => i_announced_arrival,
                                                     i_prof                => i_prof,
                                                     i_name                => i_name,
                                                     i_gender              => i_gender,
                                                     i_dt_birth            => i_dt_birth,
                                                     i_age                 => i_age,
                                                     i_address             => i_address,
                                                     i_city                => i_city,
                                                     i_pat_zip_code        => i_pat_zip_code,
                                                     i_dt_report_mka       => i_dt_report_mka,
                                                     i_cpa_code            => i_cpa_code,
                                                     i_transport_number    => i_transport_number,
                                                     i_acc_zip_code        => i_acc_zip_code,
                                                     i_latitude            => i_latitude,
                                                     i_longitude           => i_longitude,
                                                     i_dt_ride_out         => i_dt_ride_out,
                                                     i_dt_arrival          => i_dt_arrival,
                                                     i_dt_drv_away         => i_dt_drv_away,
                                                     i_flg_mech_inj        => i_flg_mech_inj,
                                                     i_mech_injury         => i_mech_injury,
                                                     i_vs_id               => i_vs_id,
                                                     i_vs_val              => i_vs_val,
                                                     i_unit_meas           => i_unit_meas,
                                                     i_dt_accident         => i_dt_accident,
                                                     i_type_injury         => i_type_injury,
                                                     i_condition           => i_condition,
                                                     i_referred_by         => i_referred_by,
                                                     i_speciality          => i_speciality,
                                                     i_clinical_service    => i_clinical_service,
                                                     i_ed_physician        => i_ed_physician,
                                                     i_dt_expected_arrival => i_dt_expected_arrival,
                                                     i_flg_prot_device     => i_flg_prot_device,
                                                     i_flg_rta_pat_typ     => i_flg_rta_pat_typ,
                                                     i_rta_pat_typ_ft      => i_rta_pat_typ_ft,
                                                     i_flg_is_driv_own     => i_flg_is_driv_own,
                                                     i_flg_police_involved => i_flg_police_involved,
                                                     i_police_num          => i_police_num,
                                                     i_police_station      => i_police_station,
                                                     i_police_accident_num => i_police_accident_num,
                                                     i_id_amb_trust_code   => i_id_amb_trust_code,
                                                     i_ambulance_trust     => i_ambulance_trust,
                                                     o_error               => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN pk_pre_hosp_accident.g_usr_info_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              o_error.ora_sqlcode,
                                              o_error.ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ann_arrival_pre_hosp;
    --
    /**********************************************************************************************
    * Cancel patient arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_save_hist              True saves cancellation data in history, otherwise false
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION cancel_pat_arrival_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_save_hist         IN BOOLEAN DEFAULT TRUE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'CANCEL_PAT_ARRIVAL_INT';
        l_ann_arr_hist      announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_pre_hosp_acc_hist pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_pre_hosp_acc_new  pre_hosp_accident.id_pre_hosp_accident%TYPE;
    
        l_rows table_varchar;
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        IF (i_save_hist)
        THEN
            g_error := 'INS ANN ARR HIST';
            IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                          i_announced_arrival      => i_announced_arrival,
                                                          i_flg_commit             => FALSE,
                                                          o_announced_arrival_hist => l_ann_arr_hist,
                                                          o_pre_hosp_accident      => l_pre_hosp_acc_hist,
                                                          o_error                  => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        
            g_error := 'PRE_HOSP HIST';
            IF NOT (pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                           i_prof              => i_prof,
                                                           i_pre_hosp_acc      => l_pre_hosp_acc_hist,
                                                           i_flg_commit        => FALSE,
                                                           o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                           o_error             => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        IF (l_pre_hosp_acc_new IS NOT NULL)
        THEN
            g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
            UPDATE announced_arrival aa
               SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new
             WHERE aa.id_announced_arrival = i_announced_arrival
               AND aa.id_pre_hosp_accident = l_pre_hosp_acc_hist;
        END IF;
    
        g_error := 'UPD ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                 id_pre_hosp_accident_in => nvl(l_pre_hosp_acc_new, l_pre_hosp_acc_hist),
                                 flg_status_in           => g_aa_arrival_status_e,
                                 id_episode_in           => NULL,
                                 id_episode_nin          => FALSE,
                                 dt_announced_arrival_in => g_sysdate_tstz,
                                 rows_out                => l_rows);
    
        t_data_gov_mnt.process_update(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_table_name   => 'ANNOUNCED_ARRIVAL',
                                      i_rowids       => l_rows,
                                      o_error        => o_error,
                                      i_list_columns => table_varchar('ID_PRE_HOSP_ACCIDENT',
                                                                      'FLG_STATUS',
                                                                      'DT_ANNOUNCED_ARRIVAL'));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END cancel_pat_arrival_int;
    --
    /**********************************************************************************************
    * Cancel announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_cancel_reason          reason for cancellation
    * @param i_cancel_notes           cancellation notes
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION cancel_ann_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_cancel_reason     IN announced_arrival.id_cancel_reason%TYPE,
        i_cancel_notes      IN announced_arrival.cancel_notes%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'CANCEL_ANN_ARRIVAL';
        l_ann_arr_hist     announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_pre_hosp_acc_new pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_cur_status       announced_arrival.flg_status%TYPE;
        l_ed_physician     announced_arrival.id_ed_physician%TYPE;
        --
        l_episode       announced_arrival.id_episode%TYPE;
        l_patient       announced_arrival.id_patient%TYPE;
        l_cancel_type_a episode.flg_cancel_type%TYPE := 'A'; --(A) Cancelamento no ALERT?? (ADT inclu??do)
        --
        l_rows table_varchar;
        -- SCH 3.0 variable
        l_transaction_id VARCHAR2(4000);
    BEGIN
    
        -- gets a new transaction ID and begins the transaction (for the Scheduler 3.0 transactions)
        g_error          := 'CALL PK_SCHEDULE_API_UPSTREAM.BEGIN_NEW_TRANSACTION';
        l_transaction_id := pk_schedule_api_upstream.begin_new_transaction(l_transaction_id, i_prof);
    
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET CUR STATUS AND ED_PHYSICIAN';
        SELECT aa.flg_status, aa.id_ed_physician
          INTO l_cur_status, l_ed_physician
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        g_error := 'INS ANN ARR HIST';
        IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                      i_announced_arrival      => i_announced_arrival,
                                                      i_flg_commit             => FALSE,
                                                      o_announced_arrival_hist => l_ann_arr_hist,
                                                      o_pre_hosp_accident      => l_pre_hosp_acc_new,
                                                      o_error                  => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        -- IF CURRENT STATUS IS ARRIVED THEN CANCEL ARRIVAL FIRST
        IF l_cur_status = g_aa_arrival_status_a
        THEN
            g_error := 'CANCEL PAT ARRIVAL';
            IF NOT (cancel_pat_arrival_int(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_announced_arrival => i_announced_arrival,
                                           i_save_hist         => FALSE,
                                           o_error             => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        g_error := 'CANCEL PRE_HOSP_ACCIDENT';
        IF NOT (pk_pre_hosp_accident.cancel_pre_hosp_acc(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_pre_hosp_accident => l_pre_hosp_acc_new,
                                                         i_flg_commit        => FALSE,
                                                         o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'CANCEL ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                 id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                 id_cancel_reason_in     => i_cancel_reason,
                                 id_cancel_reason_nin    => FALSE,
                                 cancel_notes_in         => i_cancel_notes,
                                 cancel_notes_nin        => FALSE,
                                 flg_status_in           => g_aa_arrival_status_c,
                                 dt_announced_arrival_in => g_sysdate_tstz,
                                 rows_out                => l_rows);
    
        g_error := 'PROCESS_UPDATE ANN_ARRIV';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'REMOVE ALERT';
        IF NOT set_alert(i_lang              => i_lang,
                         i_prof              => i_prof,
                         i_announced_arrival => i_announced_arrival,
                         i_professional      => l_ed_physician,
                         i_type              => g_alert_type_rem,
                         o_error             => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'CANCEL EPISODE';
        SELECT aa.id_episode, aa.id_patient
          INTO l_episode, l_patient
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival
           AND aa.id_pre_hosp_accident = l_pre_hosp_acc_new;
    
        IF (l_episode IS NOT NULL)
        THEN
            IF NOT (pk_visit.call_cancel_episode(i_lang           => i_lang,
                                                 i_id_episode     => l_episode,
                                                 i_prof           => i_prof,
                                                 i_cancel_reason  => 'CANCELLED ANNOUNCED ARRIVAL',
                                                 i_cancel_type    => l_cancel_type_a,
                                                 i_transaction_id => l_transaction_id,
                                                 o_error          => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        --ALERT-271134 cancel announced arrival should cancel patient
        IF (l_patient IS NOT NULL)
           AND pk_adt.is_contact(i_lang, i_prof, l_patient) = pk_alert_constant.g_yes
        THEN
            IF NOT (pk_adt.set_patient_status(i_lang    => i_lang,
                                              i_prof    => i_prof,
                                              i_patient => l_patient,
                                              i_status  => pk_alert_constant.g_cancelled,
                                              o_error   => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        pk_schedule_api_upstream.do_commit(l_transaction_id, i_prof);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            -- will be needed when new scheduler is active  DO NOT REMOVE                                 
            pk_schedule_api_upstream.do_rollback(l_transaction_id, i_prof);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_ann_arrival;
    --
    /**********************************************************************************************
    * Confirm patient arrival - internal function
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_pre_hosp_accident      pre_hosp_accident id
    * @param i_episode                episode id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/11/05
    **********************************************************************************************/
    FUNCTION set_pat_arrival_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_pre_hosp_accident IN announced_arrival.id_pre_hosp_accident%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_PAT_ARRIV_INT';
        --
        l_epis_flg_unknown epis_info.flg_unknown%TYPE;
        l_flg_stage        care_stage.flg_stage%TYPE;
        l_care_stage_date  VARCHAR2(50);
    
        --
        l_ed_physician announced_arrival.id_ed_physician%TYPE;
        l_rows         table_varchar;
    BEGIN
        g_error := 'GET FLG_UNK';
        SELECT nvl(ei.flg_unknown, pk_alert_constant.g_no)
          INTO l_epis_flg_unknown
          FROM epis_info ei
         WHERE ei.id_episode = i_episode;
    
        g_error := 'GET INITIAL CARE STAGE';
        IF l_epis_flg_unknown = pk_alert_constant.g_yes
        THEN
            l_flg_stage := pk_sysconfig.get_config(g_care_stage_temp_epis_arrived, i_prof);
        ELSE
            l_flg_stage := pk_sysconfig.get_config(g_care_stage_def_epis_arrived, i_prof);
        END IF;
    
        g_error := 'SET CARE STAGE';
        IF NOT (pk_patient_tracking.set_care_stage_no_commit(i_lang      => i_lang,
                                                             i_prof      => i_prof,
                                                             i_episode   => i_episode,
                                                             i_flg_stage => l_flg_stage,
                                                             o_date      => l_care_stage_date,
                                                             o_error     => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'UPD ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                 id_pre_hosp_accident_in => i_pre_hosp_accident,
                                 flg_status_in           => g_aa_arrival_status_a,
                                 dt_announced_arrival_in => g_sysdate_tstz,
                                 rows_out                => l_rows);
    
        g_error := 'PROCESS_UPDATE ANN_ARRIV';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'GET ED_PHYSICIAN';
        SELECT aa.id_ed_physician
          INTO l_ed_physician
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        g_error := 'REMOVE ALERT';
        IF NOT set_alert(i_lang              => i_lang,
                         i_prof              => i_prof,
                         i_announced_arrival => i_announced_arrival,
                         i_professional      => l_ed_physician,
                         i_type              => g_alert_type_rem,
                         o_error             => o_error)
        THEN
            RAISE e_call_error;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_arrival_int;
    --
    /**********************************************************************************************
    * Confirm patient arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_patient                patient id - This field is only used to mantain compatebility with announced arrival first version
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_pat_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'SET_PAT_ARRIV';
        l_ann_arr_hist      announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_pre_hosp_acc_hist pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_pre_hosp_acc_new  pre_hosp_accident.id_pre_hosp_accident%TYPE;
        --
        l_name     pre_hosp_accident.name%TYPE;
        l_gender   pre_hosp_accident.gender%TYPE;
        l_dt_birth pre_hosp_accident.dt_birth%TYPE;
        l_age      pre_hosp_accident.age%TYPE;
        --
        l_id_patient patient.id_patient%TYPE;
        l_episode    announced_arrival.id_episode%TYPE;
        l_episode_exception EXCEPTION;
        l_ora_sqlcode VARCHAR2(200);
        l_ora_sqlerrm VARCHAR2(4000);
        l_err_desc    VARCHAR2(4000);
        l_err_action  VARCHAR2(4000);
        --
        CURSOR c_vs_read IS
            SELECT p.id_vital_sign_read
              FROM pre_hosp_vs_read p
             WHERE p.id_pre_hosp_accident = l_pre_hosp_acc_new
               AND p.flg_status = g_pre_hosp_vs_read_status_a;
        rows_vsr_out table_varchar := table_varchar();
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'VERIFY ANN_ARRIV EPISODE';
        BEGIN
            SELECT id_episode
              INTO l_episode
              FROM announced_arrival aa
             WHERE aa.id_announced_arrival = i_announced_arrival;
        EXCEPTION
            WHEN no_data_found THEN
                l_episode := NULL;
        END;
    
        IF (l_episode IS NULL AND i_patient IS NULL)
        THEN
            g_error := 'ANN ARRIV WITHOUT EPISODE';
            RAISE e_call_error;
        ELSIF (l_episode IS NULL AND i_patient IS NOT NULL)
        THEN
            g_error := 'GET PRE_HOSP PATIENT DATA';
            SELECT pha.name, pha.gender, pha.dt_birth, pha.age
              INTO l_name, l_gender, l_dt_birth, l_age
              FROM pre_hosp_accident pha
              JOIN announced_arrival aa
                ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
             WHERE aa.id_announced_arrival = i_announced_arrival;
        
            g_error := 'CREATE EPISODE TEMP';
            IF NOT create_episode_int(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_patient     => i_patient,
                                      i_name        => l_name,
                                      i_gender      => l_gender,
                                      i_dt_birth    => l_dt_birth,
                                      i_age         => l_age,
                                      o_episode     => l_episode,
                                      o_ora_sqlcode => l_ora_sqlcode,
                                      o_ora_sqlerrm => l_ora_sqlerrm,
                                      o_err_desc    => l_err_desc,
                                      o_err_action  => l_err_action)
            THEN
                RAISE l_episode_exception;
            END IF;
        END IF;
    
        g_error := 'INS ANN ARR HIST';
        IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                      i_announced_arrival      => i_announced_arrival,
                                                      i_flg_commit             => FALSE,
                                                      o_announced_arrival_hist => l_ann_arr_hist,
                                                      o_pre_hosp_accident      => l_pre_hosp_acc_hist,
                                                      o_error                  => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'CREATE PRE_HOSP HIST';
        IF NOT (pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_pre_hosp_acc      => l_pre_hosp_acc_hist,
                                                       i_flg_commit        => FALSE,
                                                       o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                       o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
        UPDATE announced_arrival aa
           SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new
         WHERE aa.id_announced_arrival = i_announced_arrival
           AND aa.id_pre_hosp_accident = l_pre_hosp_acc_hist;
    
        g_error := 'SET PAT ARRIVAL - INT';
        IF NOT (set_pat_arrival_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_announced_arrival => i_announced_arrival,
                                    i_pre_hosp_accident => l_pre_hosp_acc_new,
                                    i_episode           => l_episode,
                                    o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        IF (i_patient IS NOT NULL)
        THEN
            g_error := 'UPD ANNOUNCED_ARRIVAL EPI';
            ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                     id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                     flg_epi_type_in         => g_aa_arr_epi_type_a,
                                     id_episode_in           => l_episode);
        
            g_error := 'UPD PRE_HOSP_ACCIDENT EPI';
            ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => l_pre_hosp_acc_new, id_episode_in => l_episode);
        
            g_error := 'GET ID_PATIENT';
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = l_episode;
        
            g_error := 'UPD VS ID_EPISODE';
            FOR c_vs IN c_vs_read
            LOOP
                -- CHAMAR O UPDATE DO PACKAGE TS_VITAL_SIGN_READ
                ts_vital_sign_read.upd(id_vital_sign_read_in => c_vs.id_vital_sign_read,
                                       id_episode_in         => l_episode,
                                       id_episode_nin        => FALSE,
                                       id_patient_in         => l_id_patient,
                                       id_patient_nin        => FALSE,
                                       rows_out              => rows_vsr_out);
            END LOOP;
        
            -- CHAMAR PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'VITAL_SIGN_READ',
                                          i_rowids     => rows_vsr_out,
                                          o_error      => o_error);
        END IF;
    
        COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_ora_sqlcode,
                                              l_ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_arrival;
    --
    /**********************************************************************************************
    * Cancel patient arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION cancel_pat_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'CANCEL_PAT_ARRIVAL';
        l_ed_physician        announced_arrival.id_ed_physician%TYPE;
        l_dt_expected_arrival announced_arrival.dt_expected_arrival%TYPE;
        l_type_injury         announced_arrival.type_injury%TYPE;
        l_rows                table_varchar;
        l_date                VARCHAR2(50);
    BEGIN
    
        g_error := 'CANCEL PAT_ARR';
        IF NOT (cancel_pat_arrival_int(i_lang              => i_lang,
                                       i_prof              => i_prof,
                                       i_announced_arrival => i_announced_arrival,
                                       i_save_hist         => TRUE,
                                       o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'PROCESS_UPDATE ANN_ARRIV';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        g_error := 'GET ANN ARR DATA';
        SELECT aa.id_ed_physician, aa.dt_expected_arrival, aa.type_injury
          INTO l_ed_physician, l_dt_expected_arrival, l_type_injury
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        g_error := 'INS ALERT';
        IF l_ed_physician IS NOT NULL
        THEN
            IF NOT set_alert(i_lang              => i_lang,
                             i_prof              => i_prof,
                             i_announced_arrival => i_announced_arrival,
                             i_episode           => -1,
                             i_professional      => l_ed_physician,
                             i_dt_record         => l_dt_expected_arrival,
                             i_replace1          => l_type_injury,
                             i_type              => g_alert_type_add,
                             o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        --       COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END cancel_pat_arrival;

    /**********************************************************************************************
    * Confirm patient arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_patient                patient id - This field is only used to mantain compatebility with announced arrival first version
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_pat_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'SET_PAT_ARRIV';
        l_ann_arr_hist      announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_pre_hosp_acc_hist pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_pre_hosp_acc_new  pre_hosp_accident.id_pre_hosp_accident%TYPE;
        --
        l_name     pre_hosp_accident.name%TYPE;
        l_gender   pre_hosp_accident.gender%TYPE;
        l_dt_birth pre_hosp_accident.dt_birth%TYPE;
        l_age      pre_hosp_accident.age%TYPE;
        --
        l_id_patient patient.id_patient%TYPE;
        l_episode    announced_arrival.id_episode%TYPE;
        l_episode_exception EXCEPTION;
        l_ora_sqlcode VARCHAR2(200);
        l_ora_sqlerrm VARCHAR2(4000);
        l_err_desc    VARCHAR2(4000);
        l_err_action  VARCHAR2(4000);
        --
        CURSOR c_vs_read IS
            SELECT p.id_vital_sign_read
              FROM pre_hosp_vs_read p
             WHERE p.id_pre_hosp_accident = l_pre_hosp_acc_new
               AND p.flg_status = g_pre_hosp_vs_read_status_a;
        rows_vsr_out table_varchar := table_varchar();
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'VERIFY ANN_ARRIV EPISODE';
        BEGIN
            SELECT id_episode
              INTO l_episode
              FROM announced_arrival aa
             WHERE aa.id_announced_arrival = i_announced_arrival;
        EXCEPTION
            WHEN no_data_found THEN
                l_episode := NULL;
        END;
    
        IF (l_episode IS NULL AND i_patient IS NULL)
        THEN
            g_error := 'ANN ARRIV WITHOUT EPISODE';
            RAISE e_call_error;
        ELSIF (l_episode IS NULL AND i_patient IS NOT NULL AND i_episode IS NULL)
        THEN
            g_error := 'GET PRE_HOSP PATIENT DATA';
            SELECT pha.name, pha.gender, pha.dt_birth, pha.age
              INTO l_name, l_gender, l_dt_birth, l_age
              FROM pre_hosp_accident pha
              JOIN announced_arrival aa
                ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
             WHERE aa.id_announced_arrival = i_announced_arrival;
        
            g_error := 'CREATE EPISODE TEMP';
            IF NOT create_episode_int(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      i_patient     => i_patient,
                                      i_name        => l_name,
                                      i_gender      => l_gender,
                                      i_dt_birth    => l_dt_birth,
                                      i_age         => l_age,
                                      o_episode     => l_episode,
                                      o_ora_sqlcode => l_ora_sqlcode,
                                      o_ora_sqlerrm => l_ora_sqlerrm,
                                      o_err_desc    => l_err_desc,
                                      o_err_action  => l_err_action)
            THEN
                RAISE l_episode_exception;
            END IF;
        ELSIF (l_episode IS NULL AND i_patient IS NOT NULL AND i_episode IS NOT NULL)
        THEN
            l_episode := i_episode;
        END IF;
    
        g_error := 'INS ANN ARR HIST';
        IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                      i_announced_arrival      => i_announced_arrival,
                                                      i_flg_commit             => FALSE,
                                                      o_announced_arrival_hist => l_ann_arr_hist,
                                                      o_pre_hosp_accident      => l_pre_hosp_acc_hist,
                                                      o_error                  => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'CREATE PRE_HOSP HIST';
        IF NOT (pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_pre_hosp_acc      => l_pre_hosp_acc_hist,
                                                       i_flg_commit        => FALSE,
                                                       o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                       o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
        UPDATE announced_arrival aa
           SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new
         WHERE aa.id_announced_arrival = i_announced_arrival
           AND aa.id_pre_hosp_accident = l_pre_hosp_acc_hist;
    
        g_error := 'SET PAT ARRIVAL - INT';
        IF NOT (set_pat_arrival_int(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_announced_arrival => i_announced_arrival,
                                    i_pre_hosp_accident => l_pre_hosp_acc_new,
                                    i_episode           => l_episode,
                                    o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        IF (i_patient IS NOT NULL)
        THEN
            g_error := 'UPD ANNOUNCED_ARRIVAL EPI';
            ts_announced_arrival.upd(id_announced_arrival_in => i_announced_arrival,
                                     id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                     flg_epi_type_in         => g_aa_arr_epi_type_a,
                                     id_episode_in           => l_episode);
        
            g_error := 'UPD PRE_HOSP_ACCIDENT EPI';
            ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => l_pre_hosp_acc_new, id_episode_in => l_episode);
        
            g_error := 'GET ID_PATIENT';
            SELECT e.id_patient
              INTO l_id_patient
              FROM episode e
             WHERE e.id_episode = l_episode;
        
            g_error := 'UPD VS ID_EPISODE';
            FOR c_vs IN c_vs_read
            LOOP
                -- CHAMAR O UPDATE DO PACKAGE TS_VITAL_SIGN_READ
                ts_vital_sign_read.upd(id_vital_sign_read_in => c_vs.id_vital_sign_read,
                                       id_episode_in         => l_episode,
                                       id_episode_nin        => FALSE,
                                       id_patient_in         => l_id_patient,
                                       id_patient_nin        => FALSE,
                                       rows_out              => rows_vsr_out);
            END LOOP;
        
            -- CHAMAR PROCEDIMENTO PROCESS_INSERT DO PACKAGE T_DATA_GOV_MNT
            t_data_gov_mnt.process_update(i_lang       => i_lang,
                                          i_prof       => i_prof,
                                          i_table_name => 'VITAL_SIGN_READ',
                                          i_rowids     => rows_vsr_out,
                                          o_error      => o_error);
        END IF;
    
        --ALERT-277593 no commit allowed - invoked by ADT
        --COMMIT;
        RETURN TRUE;
    EXCEPTION
        WHEN l_episode_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_ora_sqlcode,
                                              l_ora_sqlerrm,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'U',
                                              o_error);
        
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_pat_arrival;

    --
    /********************************************************************************************
    * Function that updates the id_episode
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param i_episode       Definitive episode ID
    * @param i_episode_temp  Temporary episode ID
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/07/03
    ********************************************************************************************/
    FUNCTION match_announced_arrival
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_episode_temp IN episode.id_episode%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'MATCH_ANNOUNCED_ARRIVAL';
        --
        l_name     pre_hosp_accident.name%TYPE;
        l_gender   pre_hosp_accident.gender%TYPE;
        l_dt_birth pre_hosp_accident.dt_birth%TYPE;
        l_age      pre_hosp_accident.age%TYPE;
        --
        l_cfg_state_chg    sys_config.id_sys_config%TYPE := 'ANN_ARRIV_MATCH_STATE_CHANGE';
        l_state_should_chg sys_config.value%TYPE;
        --
        l_temp_announced_arrival announced_arrival.id_announced_arrival%TYPE;
        l_temp_ann_arriv_hist    announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_temp_pre_hosp_accident announced_arrival.id_pre_hosp_accident%TYPE;
        l_def_announced_arrival  announced_arrival.id_announced_arrival%TYPE;
        l_def_pre_hosp_accident  announced_arrival.id_pre_hosp_accident%TYPE;
        l_last_pre_hosp_accident announced_arrival.id_pre_hosp_accident%TYPE;
        l_cur_status             announced_arrival.flg_status%TYPE;
    BEGIN
        g_error := 'SET PK_PRE_HOSP_ACCIDENT TIME';
        IF NOT (pk_pre_hosp_accident.set_pck_time(i_lang => i_lang, i_date => g_sysdate_tstz, o_error => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'GET TEMP ANN_ARRIV';
        BEGIN
            SELECT aa.id_announced_arrival
              INTO l_temp_announced_arrival
              FROM announced_arrival aa
             WHERE aa.id_episode = i_episode_temp;
        EXCEPTION
            WHEN no_data_found THEN
                l_temp_announced_arrival := NULL;
        END;
    
        IF l_temp_announced_arrival IS NOT NULL
        THEN
            g_error := 'GET DEF PRE_HOSP';
            BEGIN
                SELECT aa.id_announced_arrival, aa.id_pre_hosp_accident
                  INTO l_def_announced_arrival, l_def_pre_hosp_accident
                  FROM announced_arrival aa
                 WHERE aa.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    l_def_announced_arrival := NULL;
                    l_def_pre_hosp_accident := NULL;
            END;
        
            --if l_def_pre_hosp_accident is not null, means that both episodes have pre_hosp data
            IF l_def_announced_arrival IS NOT NULL
            THEN
                g_error := 'SEND CURR TEMP ANN_ARRIV TO HIST';
                IF NOT pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                             i_announced_arrival      => l_temp_announced_arrival,
                                                             i_flg_commit             => FALSE,
                                                             o_announced_arrival_hist => l_temp_ann_arriv_hist,
                                                             o_pre_hosp_accident      => l_temp_pre_hosp_accident,
                                                             o_error                  => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            
                g_error := 'UPD ANN_ARRIV KEY';
                ts_announced_arrival_hist.upd(id_announced_arrival_in => l_def_announced_arrival,
                                              where_in                => 'id_announced_arrival = ' ||
                                                                         l_temp_announced_arrival);
            
                g_error := 'DEL ANN_ARRIV';
                ts_announced_arrival.del(id_announced_arrival_in => l_temp_announced_arrival,
                                         id_pre_hosp_accident_in => l_temp_pre_hosp_accident);
            
                g_error := 'FIND THE MOST RECENT PRE_HOSP';
                SELECT id_pre_hosp_accident
                  INTO l_last_pre_hosp_accident
                  FROM (SELECT pha.id_pre_hosp_accident,
                               row_number() over(ORDER BY pha.dt_pre_hosp_accident DESC) line_number
                          FROM pre_hosp_accident pha
                         WHERE pha.id_episode IN (i_episode, i_episode_temp))
                 WHERE line_number = 1;
            
                g_error := 'UPDATE FLG_STATUS OF PRE_HOSP_ACCIDENT';
                ts_pre_hosp_accident.upd(flg_status_in => g_pre_hosp_status_i,
                                         where_in      => 'id_pre_hosp_accident != ' || l_last_pre_hosp_accident || --
                                                          'and id_episode in (' || i_episode || ', ' || i_episode_temp || ')');
            END IF;
        END IF;
    
        g_error := 'UPD ANNOUNCED ARRIVAL';
        ts_announced_arrival.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        g_error := 'UPD ANNOUNCED ARRIVAL HIST';
        ts_announced_arrival_hist.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        g_error := 'UPD PRE_HOSP_ACCIDENT';
        ts_pre_hosp_accident.upd(id_episode_in => i_episode, where_in => 'id_episode = ' || i_episode_temp);
    
        BEGIN
            g_error := 'GET ANN ARRIV AND PRE_HOSP';
            SELECT aa.id_announced_arrival, aa.id_pre_hosp_accident, aa.flg_status
              INTO l_def_announced_arrival, l_def_pre_hosp_accident, l_cur_status
              FROM announced_arrival aa
             WHERE aa.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_def_announced_arrival := NULL;
                l_def_pre_hosp_accident := NULL;
        END;
    
        IF (l_def_announced_arrival IS NOT NULL AND l_def_pre_hosp_accident IS NOT NULL AND
           l_cur_status != g_aa_arrival_status_c)
        THEN
            g_error := 'GET PAT DATA';
            SELECT p.name, p.gender, p.dt_birth, p.age
              INTO l_name, l_gender, l_dt_birth, l_age
              FROM patient p
              JOIN episode epis
                ON epis.id_patient = p.id_patient
             WHERE epis.id_episode = i_episode;
        
            IF l_dt_birth IS NULL
               AND l_age IS NULL
            THEN
                SELECT p.dt_birth, p.age
                  INTO l_dt_birth, l_age
                  FROM patient p
                  JOIN episode epis
                    ON epis.id_patient = p.id_patient
                 WHERE epis.id_episode = i_episode_temp;
            END IF;
        
            g_error := 'UPD PRE_HOSP PAT DATA';
            IF NOT pk_pre_hosp_accident.update_patient(i_lang         => i_lang,
                                                       i_prof         => i_prof,
                                                       i_episode      => i_episode,
                                                       i_ann_arrival  => l_def_announced_arrival,
                                                       i_pre_hosp_acc => l_last_pre_hosp_accident,
                                                       i_name         => l_name,
                                                       i_gender       => l_gender,
                                                       i_dt_birth     => l_dt_birth,
                                                       i_age          => l_age,
                                                       o_error        => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
            g_error            := 'GET CFG ANN_ARRIV_MATCH_STATE_CHANGE';
            l_state_should_chg := pk_sysconfig.get_config(i_code_cf => l_cfg_state_chg, i_prof => i_prof);
        
            IF (l_state_should_chg = pk_alert_constant.g_yes)
            THEN
                g_error := 'SET PAT ARRIVAL - INT';
                IF NOT (set_pat_arrival_int(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_announced_arrival => l_def_announced_arrival,
                                            i_pre_hosp_accident => l_def_pre_hosp_accident,
                                            i_episode           => i_episode,
                                            o_error             => o_error))
                THEN
                    RAISE e_call_error;
                END IF;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END match_announced_arrival;
    --
    /********************************************************************************************
    * Get the announced arrival id for the given episode
    *
    * @param i_episode       Episode ID
    *
    * @return                id of the corresponding announced arrival; -1 if announced arrival does not exist for this episode
    *                        or NULL in case of error
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/10/21
    ********************************************************************************************/
    FUNCTION get_ann_arrival_id(i_episode IN episode.id_episode%TYPE) RETURN announced_arrival.id_announced_arrival%TYPE IS
        l_announced_arrival announced_arrival.id_announced_arrival%TYPE := NULL;
    BEGIN
        BEGIN
            SELECT aa.id_announced_arrival
              INTO l_announced_arrival
              FROM announced_arrival aa
             WHERE aa.id_episode = i_episode;
        EXCEPTION
            WHEN no_data_found THEN
                l_announced_arrival := -1;
        END;
    
        RETURN l_announced_arrival;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arrival_id;
    --
    /********************************************************************************************
    * Returns the id_announced_arrival if exists and if it's to be shown on the grids_ea
    *
    * @param i_lang          Language ID
    * @param i_prof_inst     institution id
    * @param i_prof_soft     software id
    * @param i_episode       Episode ID
    * @param i_flg_unknown   Y - is a temporary episode; N or null - is definitive episode
    *
    * @return                id_announced_arrival or -1 if ann_arriv does not exist or null if it's not to be shown
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/10/27
    ********************************************************************************************/
    FUNCTION get_ann_arrival_id
    (
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_soft         IN software.id_software%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_flg_unknown       IN epis_info.flg_unknown%TYPE,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE DEFAULT 0,
        i_flg_status        IN announced_arrival.flg_status%TYPE DEFAULT NULL
    ) RETURN announced_arrival.id_announced_arrival%TYPE IS
        l_cfg_show_episode  sys_config.value%TYPE := pk_sysconfig.get_config('ANN_ARRIV_SHOW_EPIS',
                                                                             i_prof_inst,
                                                                             i_prof_soft);
        l_announced_arrival announced_arrival.id_announced_arrival%TYPE;
        l_cur_status        announced_arrival.flg_status%TYPE := NULL;
        l_flg_unknown       epis_info.flg_unknown%TYPE;
    BEGIN
        l_flg_unknown := nvl(i_flg_unknown, pk_alert_constant.g_no);
        IF (i_announced_arrival = 0)
        THEN
            l_announced_arrival := pk_announced_arrival.get_ann_arrival_id(i_episode);
        ELSIF (i_announced_arrival IS NULL)
        THEN
            l_announced_arrival := -1;
        ELSE
            l_announced_arrival := i_announced_arrival;
        END IF;
    
        IF l_flg_unknown = pk_alert_constant.g_yes
           AND l_cfg_show_episode = pk_alert_constant.g_no
        THEN
            l_cur_status := nvl(i_flg_status, pk_announced_arrival.get_ann_arrival_status(i_episode));
        
            --l_cur_status is null when there isn't any ann_arrival episode
            IF l_cur_status IS NOT NULL
               AND l_cur_status != pk_announced_arrival.g_aa_arrival_status_a
            THEN
                l_announced_arrival := NULL;
            END IF;
        END IF;
    
        RETURN l_announced_arrival;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arrival_id;
    --
    /********************************************************************************************
    * Get the previous announced arrival status
    *
    * @param i_episode       Episode ID
    *
    * @return                id of the corresponding announced arrival previous status
    *                        or NULL if there isn't any previous status
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/11/02
    ********************************************************************************************/
    FUNCTION get_ann_arr_prev_status(i_ann_arriv IN announced_arrival.id_announced_arrival%TYPE)
        RETURN announced_arrival.flg_status%TYPE IS
        l_flg_status announced_arrival.flg_status%TYPE := NULL;
    BEGIN
        SELECT flg_status
          INTO l_flg_status
          FROM (SELECT aah.flg_status
                  FROM announced_arrival_hist aah
                 WHERE aah.id_announced_arrival = i_ann_arriv
                 ORDER BY aah.dt_announced_arrival DESC)
         WHERE rownum = 1;
    
        RETURN l_flg_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arr_prev_status;
    --
    /********************************************************************************************
    * Get the current announced arrival status
    *
    * @param i_episode       Episode ID
    *
    * @return                id of the corresponding announced arrival 
    *                        or NULL if the episode doesn't have an announced arrival
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/10/21
    ********************************************************************************************/
    FUNCTION get_ann_arrival_status(i_episode IN episode.id_episode%TYPE) RETURN announced_arrival.flg_status%TYPE IS
        l_flg_status announced_arrival.flg_status%TYPE := NULL;
    BEGIN
        SELECT aa.flg_status
          INTO l_flg_status
          FROM announced_arrival aa
         WHERE aa.id_episode = i_episode;
    
        RETURN l_flg_status;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arrival_status;
    --
    /********************************************************************************************
    * Get the expected arrival date
    *
    * @param i_episode       Episode ID
    *
    * @return                null or the expected arrival date
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/10/26
    ********************************************************************************************/
    FUNCTION get_expected_arrival_dt(i_episode IN episode.id_episode%TYPE) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_dt_expected_arrival announced_arrival.dt_expected_arrival%TYPE := NULL;
    BEGIN
        SELECT aa.dt_expected_arrival
          INTO l_dt_expected_arrival
          FROM announced_arrival aa
         WHERE aa.id_episode = i_episode;
    
        RETURN l_dt_expected_arrival;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_expected_arrival_dt;
    --
    /********************************************************************************************
    * Get the total number of expected patients
    *
    * @param i_lang          Language ID
    * @param i_prof          Professional
    * @param o_total_num     total number of expected patients
    * @param o_error         Error ocurred
    *
    * @return                False if an error ocurred and True if not
    *
    * @author                Alexandre Santos
    * @version               2.5
    * @since                 2009/10/28
    ********************************************************************************************/
    FUNCTION get_num_expected_ann_pat
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        o_total_num OUT NUMBER,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'GET_NUM_EXPECTED_ANN_PAT';
        l_time_limit NUMBER;
    BEGIN
        g_error      := 'GET TIME_LIMIT';
        l_time_limit := to_number(pk_sysconfig.get_config('ANN_ARRIV_TIME_LIMIT', i_prof));
    
        g_error := 'GET TOTAL NUM EXPECTED PATIENTS';
        SELECT COUNT(*)
          INTO o_total_num
          FROM announced_arrival aa
         INNER JOIN pre_hosp_accident pha
            ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
         WHERE aa.flg_status = g_aa_arrival_status_e
           AND (pk_date_utils.add_days_to_tstz(aa.dt_expected_arrival, l_time_limit / g_total_min_in_day) >=
               g_sysdate_tstz OR aa.dt_expected_arrival IS NULL)
           AND pha.id_institution IN (0, i_prof.institution)
           AND pha.id_software IN (0, i_prof.software);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_num_expected_ann_pat;

    /********************************************************************************************
    * Get form steps, sections, fields and vital signs
    *
    * @param   i_lang              Preferred language ID for this professional
    * @param   i_prof              Object (professional ID, institution ID, software ID)
    * @param   i_form_int_name     Form internal name
    * @param   o_desc_form         Form description message
    * @param   o_steps             Table with form steps
    * @param   o_sections          Table with step sections
    * @param   o_fields            Table with section fields
    * @param   o_vital_signs       Cursor with vital ann_arrival vital signs
    * @param   o_error             Error message
    *                        
    * @value   i_form_int_name     ANN_ARRIVAL_FORM - Announced arrival form
    *                              PREHOSPITAL_FORM - Pre hospital form
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_form_int
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_form_int_name IN pre_hosp_form.internal_name%TYPE,
        o_desc_form     OUT sys_message.desc_message%TYPE,
        o_steps         OUT pk_edis_types.cursor_step,
        o_sections      OUT pk_edis_types.cursor_section,
        o_fields        OUT pk_edis_types.cursor_field,
        o_vital_signs   OUT pk_vital_sign.t_cur_vs_header,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_FORM_INT';
        --
        l_one CONSTANT PLS_INTEGER := 1;
        l_two CONSTANT PLS_INTEGER := 2;
        --
        l_mark_all market.id_market%TYPE := 0;
        l_market   market.id_market%TYPE;
        --
        l_pre_hosp_form pre_hosp_form.id_pre_hosp_form%TYPE;
        l_step_mark     market.id_market%TYPE;
        l_step_inst     institution.id_institution%TYPE;
        l_tbl_steps     table_number;
        l_section_mark  market.id_market%TYPE;
        l_section_inst  institution.id_institution%TYPE;
        l_tbl_sections  table_number;
        l_field_mark    market.id_market%TYPE;
        l_field_inst    institution.id_institution%TYPE;
        l_tbl_fields    table_number;
        --
        l_external_excpt EXCEPTION;
        l_internal_excpt EXCEPTION;
        --
        PROCEDURE get_step_vars
        (
            i_pre_hosp_form IN pre_hosp_form.id_pre_hosp_form%TYPE,
            o_market        OUT market.id_market%TYPE,
            o_inst          OUT institution.id_institution%TYPE,
            o_tbl_steps     OUT table_number
        ) IS
            l_proc_name CONSTANT VARCHAR2(30) := 'GET_STEP_VARS';
        BEGIN
            g_error := 'Init';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
        
            g_error := 'GET ID_MARKET AND ID_INSTITUTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            BEGIN
                SELECT id_market, id_institution
                  INTO o_market, o_inst
                  FROM (SELECT phfs.id_market,
                               phfs.id_institution,
                               row_number() over(ORDER BY decode(phfs.id_market, l_market, l_one, l_two), decode(phfs.id_institution, i_prof.institution, l_one, l_two)) line_number
                          FROM pre_hosp_form_steps phfs
                          JOIN pre_hosp_step phs
                            ON phs.id_pre_hosp_step = phfs.id_pre_hosp_step
                         WHERE phs.flg_available = pk_alert_constant.g_yes
                           AND phfs.id_pre_hosp_form = i_pre_hosp_form
                           AND phfs.id_market IN (l_mark_all, l_market)
                           AND phfs.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution))
                 WHERE line_number = l_one;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'CFG_ERROR: INSTITUTION IS NULL';
                    RAISE l_internal_excpt;
            END;
        
            g_error := 'GET FORM STEPS ID''s';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            SELECT phs.id_pre_hosp_step
              BULK COLLECT
              INTO o_tbl_steps
              FROM pre_hosp_form_steps phfs
              JOIN pre_hosp_step phs
                ON phs.id_pre_hosp_step = phfs.id_pre_hosp_step
             WHERE phs.flg_available = pk_alert_constant.g_yes
               AND phfs.id_pre_hosp_form = i_pre_hosp_form
               AND phfs.id_market = o_market
               AND phfs.id_institution = o_inst;
        END get_step_vars;
        --
        PROCEDURE get_section_vars
        (
            i_pre_hosp_form IN pre_hosp_form.id_pre_hosp_form%TYPE,
            i_tbl_steps     IN table_number,
            o_market        OUT market.id_market%TYPE,
            o_inst          OUT institution.id_institution%TYPE,
            o_tbl_sections  OUT table_number
        ) IS
            l_proc_name CONSTANT VARCHAR2(30) := 'GET_SECTION_VARS';
        BEGIN
            g_error := 'Init';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
        
            g_error := 'GET ID_MARKET AND ID_INSTITUTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            BEGIN
                SELECT id_market, id_institution
                  INTO o_market, o_inst
                  FROM (SELECT phss.id_market,
                               phss.id_institution,
                               row_number() over(ORDER BY decode(phss.id_market, l_market, l_one, l_two), decode(phss.id_institution, i_prof.institution, l_one, l_two)) line_number
                          FROM pre_hosp_step_sections phss
                          JOIN pre_hosp_section phs
                            ON phs.id_pre_hosp_section = phss.id_pre_hosp_section
                         WHERE phs.flg_available = pk_alert_constant.g_yes
                           AND phss.id_pre_hosp_form = i_pre_hosp_form
                           AND phss.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                          column_value id_pre_hosp_step
                                                           FROM TABLE(i_tbl_steps) t)
                           AND phss.id_market IN (l_mark_all, l_market)
                           AND phss.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution))
                 WHERE line_number = l_one;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'CFG_ERROR: INSTITUTION IS NULL';
                    RAISE l_internal_excpt;
            END;
        
            g_error := 'GET STEP SECTIONS ID''s';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            SELECT phs.id_pre_hosp_section
              BULK COLLECT
              INTO o_tbl_sections
              FROM pre_hosp_step_sections phss
              JOIN pre_hosp_section phs
                ON phs.id_pre_hosp_section = phss.id_pre_hosp_section
             WHERE phs.flg_available = pk_alert_constant.g_yes
               AND phss.id_pre_hosp_form = i_pre_hosp_form
               AND phss.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              column_value id_pre_hosp_step
                                               FROM TABLE(i_tbl_steps) t)
               AND phss.id_market = o_market
               AND phss.id_institution = o_inst;
        END get_section_vars;
        --
        PROCEDURE get_field_vars
        (
            i_pre_hosp_form IN pre_hosp_form.id_pre_hosp_form%TYPE,
            i_tbl_steps     IN table_number,
            i_tbl_sections  IN table_number,
            o_market        OUT market.id_market%TYPE,
            o_inst          OUT institution.id_institution%TYPE,
            o_tbl_fields    OUT table_number
        ) IS
            l_proc_name CONSTANT VARCHAR2(30) := 'GET_FIELD_VARS';
        BEGIN
            g_error := 'Init';
            pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
        
            g_error := 'GET ID_MARKET AND ID_INSTITUTION';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            BEGIN
                SELECT id_market, id_institution
                  INTO o_market, o_inst
                  FROM (SELECT phsf.id_market,
                               phsf.id_institution,
                               row_number() over(ORDER BY decode(phsf.id_market, l_market, l_one, l_two), decode(phsf.id_institution, i_prof.institution, l_one, l_two)) line_number
                          FROM pre_hosp_section_fields phsf
                          JOIN pre_hosp_field phf
                            ON phf.id_pre_hosp_field = phsf.id_pre_hosp_field
                         WHERE phf.flg_available = pk_alert_constant.g_yes
                           AND phsf.id_pre_hosp_form = i_pre_hosp_form
                           AND phsf.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                          column_value id_pre_hosp_step
                                                           FROM TABLE(i_tbl_steps) t)
                           AND phsf.id_pre_hosp_section IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                             column_value id_pre_hosp_section
                                                              FROM TABLE(i_tbl_sections) t)
                           AND phsf.id_market IN (l_mark_all, l_market)
                           AND phsf.id_institution IN (pk_alert_constant.g_inst_all, i_prof.institution))
                 WHERE line_number = l_one;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'CFG_ERROR: INSTITUTION IS NULL';
                    RAISE l_internal_excpt;
            END;
        
            g_error := 'GET SECTION FIELDS ID''s';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            SELECT phf.id_pre_hosp_field
              BULK COLLECT
              INTO o_tbl_fields
              FROM pre_hosp_section_fields phsf
              JOIN pre_hosp_field phf
                ON phf.id_pre_hosp_field = phsf.id_pre_hosp_field
             WHERE phf.flg_available = pk_alert_constant.g_yes
               AND phsf.id_pre_hosp_form = i_pre_hosp_form
               AND phsf.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              column_value id_pre_hosp_step
                                               FROM TABLE(i_tbl_steps) t)
               AND phsf.id_pre_hosp_section IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                 column_value id_pre_hosp_section
                                                  FROM TABLE(i_tbl_sections) t)
               AND phsf.id_market = o_market
               AND phsf.id_institution = o_inst;
        END get_field_vars;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        g_error := 'GET ID_PRE_HOSP_FORM AND DESC_FORM USING FORM_INT_NAME: ' || i_form_int_name;
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        BEGIN
            SELECT phf.id_pre_hosp_form, pk_message.get_message(i_lang, phf.code_msg_pre_hosp_form)
              INTO l_pre_hosp_form, o_desc_form
              FROM pre_hosp_form phf
             WHERE phf.internal_name = i_form_int_name
               AND phf.flg_available = pk_alert_constant.g_yes;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'CFG_ERROR: FORM_INT_NAME "' || i_form_int_name || '" DOESN''T EXIST OR IS UNAVAILABLE';
                RAISE l_internal_excpt;
        END;
    
        g_error := 'GET MARKET ID';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_market := pk_utils.get_institution_market(i_lang => i_lang, i_id_institution => i_prof.institution);
    
        g_error := 'GET FORM STEP VARS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        get_step_vars(i_pre_hosp_form => l_pre_hosp_form,
                      o_market        => l_step_mark,
                      o_inst          => l_step_inst,
                      o_tbl_steps     => l_tbl_steps);
    
        g_error := 'OPEN CURSOR O_STEPS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_steps FOR
            SELECT phfs.id_pre_hosp_form,
                   phs.id_pre_hosp_step,
                   phs.internal_name step_int_name,
                   pk_message.get_message(i_lang, phs.code_msg_pre_hosp_step) desc_step,
                   phfs.flg_show_step_msg
              FROM pre_hosp_step phs
              JOIN pre_hosp_form_steps phfs
                ON phfs.id_pre_hosp_step = phs.id_pre_hosp_step
             WHERE phfs.id_pre_hosp_form = l_pre_hosp_form
               AND phfs.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              column_value id_pre_hosp_step
                                               FROM TABLE(l_tbl_steps) t)
               AND phfs.id_market = l_step_mark
               AND phfs.id_institution = l_step_inst
             ORDER BY phfs.rank, desc_step;
    
        g_error := 'GET STEP SECTION VARS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        get_section_vars(i_pre_hosp_form => l_pre_hosp_form,
                         i_tbl_steps     => l_tbl_steps,
                         o_market        => l_section_mark,
                         o_inst          => l_section_inst,
                         o_tbl_sections  => l_tbl_sections);
    
        g_error := 'OPEN CURSOR O_SECTIONS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_sections FOR
            SELECT phss.id_pre_hosp_form,
                   phss.id_pre_hosp_step,
                   phs.id_pre_hosp_section,
                   phs.internal_name section_int_name,
                   pk_message.get_message(i_lang, phs.code_msg_phosp_section) desc_section
              FROM pre_hosp_section phs
              JOIN pre_hosp_step_sections phss
                ON phss.id_pre_hosp_section = phs.id_pre_hosp_section
             WHERE phss.id_pre_hosp_form = l_pre_hosp_form
               AND phss.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              column_value id_pre_hosp_step
                                               FROM TABLE(l_tbl_steps) t)
               AND phss.id_pre_hosp_section IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                 column_value id_pre_hosp_section
                                                  FROM TABLE(l_tbl_sections) t)
               AND phss.id_market = l_section_mark
               AND phss.id_institution = l_section_inst
                  --I'm assuming that configuration of section visibility are according with mandatory fields
                  --Sections with mandatory fields must be visible
               AND phss.flg_visible = pk_alert_constant.g_yes
             ORDER BY (SELECT rank
                         FROM pre_hosp_form_steps phfs
                        WHERE phfs.id_pre_hosp_form = phss.id_pre_hosp_form
                          AND phfs.id_pre_hosp_step = phss.id_pre_hosp_step
                          AND phfs.id_market = l_step_mark
                          AND phfs.id_institution = l_step_inst),
                      phss.rank,
                      desc_section;
    
        g_error := 'GET SECTION FIELD VARS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        get_field_vars(i_pre_hosp_form => l_pre_hosp_form,
                       i_tbl_steps     => l_tbl_steps,
                       i_tbl_sections  => l_tbl_sections,
                       o_market        => l_field_mark,
                       o_inst          => l_field_inst,
                       o_tbl_fields    => l_tbl_fields);
    
        g_error := 'OPEN CURSOR O_FIELDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_fields FOR
            SELECT phsf.id_pre_hosp_form,
                   phsf.id_pre_hosp_step,
                   phsf.id_pre_hosp_section,
                   phf.id_pre_hosp_field,
                   phf.internal_name field_int_name,
                   pk_message.get_message(i_lang, phf.code_msg_pre_hosp_field) desc_field,
                   pk_message.get_message(i_lang, phf.code_msg_detail) desc_new_field,
                   --FLG_MANDATORY of PRE_HOSP_FIELD table prevails against the same field of PRE_HOSP_SECTION_FIELDS table
                   nvl(phf.flg_mandatory, phsf.flg_mandatory) flg_mandatory
              FROM pre_hosp_field phf
              JOIN pre_hosp_section_fields phsf
                ON phsf.id_pre_hosp_field = phf.id_pre_hosp_field
             WHERE phsf.id_pre_hosp_form = l_pre_hosp_form
               AND phsf.id_pre_hosp_step IN (SELECT /*+ opt_estimate(table t rows=1) */
                                              column_value id_pre_hosp_step
                                               FROM TABLE(l_tbl_steps) t)
               AND phsf.id_pre_hosp_section IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                 column_value id_pre_hosp_section
                                                  FROM TABLE(l_tbl_sections) t)
               AND phsf.id_pre_hosp_field IN (SELECT /*+ opt_estimate(table t rows=1) */
                                               column_value id_pre_hosp_field
                                                FROM TABLE(l_tbl_fields) t)
               AND phsf.id_market = l_field_mark
               AND phsf.id_institution = l_field_inst
                  --FLG_VISIBLE of PRE_HOSP_FIELD table prevails against the same field of PRE_HOSP_SECTION_FIELDS table
                  --I'm assuming that configuration of field visibility are according with mandatory fields
               AND nvl(phf.flg_visible, phsf.flg_visible) = pk_alert_constant.g_yes
             ORDER BY (SELECT rank
                         FROM pre_hosp_form_steps phfs
                        WHERE phfs.id_pre_hosp_form = phsf.id_pre_hosp_form
                          AND phfs.id_pre_hosp_step = phsf.id_pre_hosp_step
                          AND phfs.id_market = l_step_mark
                          AND phfs.id_institution = l_step_inst),
                      (SELECT rank
                         FROM pre_hosp_step_sections phss
                        WHERE phss.id_pre_hosp_form = phsf.id_pre_hosp_form
                          AND phss.id_pre_hosp_step = phsf.id_pre_hosp_step
                          AND phss.id_pre_hosp_section = phsf.id_pre_hosp_section
                          AND phss.id_market = l_section_mark
                          AND phss.id_institution = l_section_inst),
                      phsf.rank,
                      desc_field;
    
        g_error := 'GET ANN_ARRIV VITAL_SIGNS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT pk_pre_hosp_accident.get_vs_header(i_lang        => i_lang,
                                                  i_prof        => i_prof,
                                                  i_flg_view    => pk_pre_hosp_accident.g_vs_soft_inst_aa,
                                                  o_vital_signs => o_vital_signs,
                                                  o_error       => o_error)
        THEN
            RAISE l_external_excpt;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_external_excpt THEN
            pk_edis_types.open_my_cursor(o_steps);
            pk_edis_types.open_my_cursor(o_sections);
            pk_edis_types.open_my_cursor(o_fields);
            pk_vital_sign.open_my_cursor(o_vital_signs);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_edis_types.open_my_cursor(o_steps);
            pk_edis_types.open_my_cursor(o_sections);
            pk_edis_types.open_my_cursor(o_fields);
            pk_vital_sign.open_my_cursor(o_vital_signs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_form_int;

    /********************************************************************************************
    * Get form steps, sections, fields and vital signs
    *
    * @param   i_lang              Preferred language ID for this professional
    * @param   i_prof              Object (professional ID, institution ID, software ID)
    * @param   i_form_int_name     Form internal name
    * @param   o_desc_form         Form description message
    * @param   o_steps             Cursor with form steps
    * @param   o_sections          Cursor with step sections
    * @param   o_fields            Cursor with section fields
    * @param   o_vital_signs       Cursor with vital ann_arrival vital signs
    * @param   o_error             Error message
    *                        
    * @value   i_form_int_name     ANN_ARRIVAL_FORM - Announced arrival form
    *                              PREHOSPITAL_FORM - Pre hospital form
    *                        
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_form
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_form_int_name IN pre_hosp_form.internal_name%TYPE,
        o_desc_form     OUT sys_message.desc_message%TYPE,
        o_steps         OUT pk_edis_types.cursor_step,
        o_sections      OUT pk_edis_types.cursor_section,
        o_fields        OUT pk_edis_types.cursor_field,
        o_vital_signs   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_FORM';
        --
        l_external_excpt EXCEPTION;
    BEGIN
        g_error := 'CALL GET_FORM_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_form_int(i_lang          => i_lang,
                            i_prof          => i_prof,
                            i_form_int_name => i_form_int_name,
                            o_desc_form     => o_desc_form,
                            o_steps         => o_steps,
                            o_sections      => o_sections,
                            o_fields        => o_fields,
                            o_vital_signs   => o_vital_signs,
                            o_error         => o_error)
        THEN
            RAISE l_external_excpt;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_external_excpt THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_edis_types.open_my_cursor(o_steps);
            pk_edis_types.open_my_cursor(o_sections);
            pk_edis_types.open_my_cursor(o_fields);
            pk_types.open_my_cursor(o_vital_signs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_form;

    /********************************************************************************************
    * Returns a cursor of sys_domain elements
    *                                                                                                 
    * @param i_lang                   Language ID                                                     
    * @param i_prof                   Profissional ID                                                     
    * @param i_code_dom               Element domain     
    * @param o_data_mkt               Output cursor                                              
    * @param o_error                  Error object                                              
    *                                                    
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_multichoice_values
    (
        i_lang     IN sys_domain.id_language%TYPE,
        i_prof     IN profissional,
        i_code_dom IN sys_domain.code_domain%TYPE,
        o_data_mkt OUT pk_types.cursor_type,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_MULTICHOICE_VALUES';
        --
        l_external_excpt EXCEPTION;
    BEGIN
        g_error := 'CALL PK_SYSDOMAIN.GET_VALUES_DOMAIN';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF i_code_dom = g_list_ambulance_trust
        THEN
            IF NOT pk_sys_list.get_sys_list_values(i_lang          => i_lang,
                                                   i_prof          => i_prof,
                                                   i_internal_name => i_code_dom,
                                                   o_sql           => o_data_mkt,
                                                   o_error         => o_error)
            THEN
                RAISE l_external_excpt;
            END IF;
        
        ELSE
            IF NOT pk_sysdomain.get_values_domain(i_lang          => i_lang,
                                                  i_prof          => i_prof,
                                                  i_code_dom      => i_code_dom,
                                                  i_dep_clin_serv => NULL,
                                                  o_data_mkt      => o_data_mkt,
                                                  o_error         => o_error)
            THEN
                RAISE l_external_excpt;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_external_excpt THEN
            pk_types.open_my_cursor(o_data_mkt);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data_mkt);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_multichoice_values;

    /********************************************************************************************
    * Get announced arrival hist records
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_flg_screen             Returned info is for which screen?
    * @param i_start_record           Paging - initial record number
    * @param i_num_records            Paging - number of records to display
    *                        
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  Table with history records
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arriv_hist_int
    (
        i_lang              IN sys_domain.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_start_record      IN NUMBER,
        i_num_records       IN NUMBER
    ) RETURN pk_announced_arrival.table_ann_arriv_hist IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIV_HIST_INT';
        --
        l_one CONSTANT PLS_INTEGER := 1;
        l_two CONSTANT PLS_INTEGER := 2;
        --
        l_table pk_announced_arrival.table_ann_arriv_hist;
    BEGIN
        g_error := 'Init';
        pk_alertlog.log_info(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        g_error := 'GET HISTORY RECORDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        SELECT hst.prev_ann_arriv_hist,
               hst.prev_pha,
               hst.curr_ann_arriv_hist,
               hst.curr_pha,
               hst.id_episode,
               hst.dt_announced_arrival,
               hst.id_prof_create,
               hst.flg_status,
               hst.desc_status,
               hst.cancel_reason,
               hst.cancel_notes
          BULK COLLECT
          INTO l_table
          FROM (SELECT rownum rn,
                       int_hist.prev_ann_arriv_hist,
                       int_hist.prev_pha,
                       int_hist.curr_ann_arriv_hist,
                       int_hist.curr_pha,
                       int_hist.id_episode,
                       int_hist.dt_announced_arrival,
                       int_hist.id_prof_create,
                       int_hist.flg_status,
                       pk_sysdomain.get_domain(g_domain_ann_arriv_status, int_hist.flg_status, i_lang) desc_status,
                       int_hist.cancel_reason,
                       int_hist.cancel_notes
                  FROM (SELECT aux.prev_ann_arriv_hist,
                               (SELECT id_pre_hosp_accident
                                  FROM announced_arrival_hist a
                                 WHERE a.id_announced_arrival_hist = aux.prev_ann_arriv_hist) prev_pha,
                               aux.curr_ann_arriv_hist,
                               aux.id_pre_hosp_accident curr_pha,
                               aux.id_episode,
                               aux.dt_announced_arrival,
                               aux.id_prof_create,
                               aux.flg_status,
                               aux.cancel_reason,
                               aux.cancel_notes
                          FROM (SELECT lag(t.id_announced_arrival_hist) over(ORDER BY t.dt_announced_arrival, decode(t.id_announced_arrival_hist, g_hist_curr_val, l_one, l_two), t.id_announced_arrival_hist) prev_ann_arriv_hist,
                                       t.id_announced_arrival_hist curr_ann_arriv_hist,
                                       t.id_pre_hosp_accident,
                                       t.id_episode,
                                       t.dt_announced_arrival,
                                       pha.id_prof_create,
                                       t.flg_status,
                                       t.cancel_reason,
                                       t.cancel_notes
                                  FROM (SELECT g_hist_curr_val id_announced_arrival_hist,
                                               aa.dt_announced_arrival,
                                               aa.id_episode,
                                               aa.id_pre_hosp_accident,
                                               aa.flg_status,
                                               pk_translation.get_translation(i_lang      => i_lang,
                                                                              i_code_mess => (SELECT cr.code_cancel_reason
                                                                                                FROM cancel_reason cr
                                                                                               WHERE cr.id_cancel_reason =
                                                                                                     aa.id_cancel_reason)) cancel_reason,
                                               aa.cancel_notes
                                          FROM announced_arrival aa
                                         WHERE aa.id_announced_arrival = i_announced_arrival
                                           AND i_flg_screen IN (g_flg_screen_d, g_flg_screen_h)
                                        UNION ALL
                                        SELECT aah.id_announced_arrival_hist,
                                               aah.dt_announced_arrival,
                                               aah.id_episode,
                                               aah.id_pre_hosp_accident,
                                               aah.flg_status,
                                               pk_translation.get_translation(i_lang      => i_lang,
                                                                              i_code_mess => (SELECT cr.code_cancel_reason
                                                                                                FROM cancel_reason cr
                                                                                               WHERE cr.id_cancel_reason =
                                                                                                     aah.id_cancel_reason)) cancel_reason,
                                               aah.cancel_notes
                                          FROM announced_arrival_hist aah
                                         WHERE aah.id_announced_arrival = i_announced_arrival
                                           AND i_flg_screen = g_flg_screen_h) t
                                  JOIN pre_hosp_accident pha
                                    ON pha.id_pre_hosp_accident = t.id_pre_hosp_accident) aux) int_hist
                 ORDER BY int_hist.dt_announced_arrival DESC) hst
         WHERE (i_start_record IS NULL OR
               (hst.rn BETWEEN i_start_record + l_one AND (i_start_record + i_num_records + l_one)));
    
        RETURN l_table;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ann_arriv_hist_int;

    /********************************************************************************************
    * Get number of all records in history
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_form_int_name          Form internal name
    * @param i_flg_screen             Returned info is for which screen?
    * @param i_start_record           Paging - initial record number
    * @param i_num_records            Paging - number of records to display
    * @param o_ann_arriv_hist         Detail/History data                                              
    * @param o_error                  Error object                                              
    *                        
    * @value   i_form_int_name     ANN_ARRIVAL_FORM - Announced arrival form
    *                              PREHOSPITAL_FORM - Pre hospital form
    *                                                    
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arrival_hist_count
    (
        i_lang              IN sys_domain.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_flg_screen        IN VARCHAR2,
        o_num_records       OUT NUMBER,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_HIST_COUNT';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
        --
        l_tbl_ann_arriv_hist pk_announced_arrival.table_ann_arriv_hist;
    BEGIN
        g_error := 'CALL GET_ANN_ARRIV_HIST_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_tbl_ann_arriv_hist := get_ann_arriv_hist_int(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_announced_arrival => i_announced_arrival,
                                                       i_flg_screen        => i_flg_screen,
                                                       i_start_record      => NULL,
                                                       i_num_records       => NULL);
    
        IF (l_tbl_ann_arriv_hist IS NOT NULL)
        THEN
            o_num_records := l_tbl_ann_arriv_hist.count;
        ELSE
            o_num_records := l_zero;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_hist_count;

    /********************************************************************************************
    * Get detail and/or history data for a given announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_form_int_name          Form internal name
    * @param i_flg_screen             Returned info is for which screen?
    * @param i_start_record           Paging - initial record number
    * @param i_num_records            Paging - number of records to display
    * @param o_ann_arriv_hist         Detail/History data                                              
    * @param o_error                  Error object                                              
    *                        
    * @value   i_form_int_name     ANN_ARRIVAL_FORM - Announced arrival form
    *                              PREHOSPITAL_FORM - Pre hospital form
    *                                                    
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arrival_hist_int
    (
        i_lang              IN sys_domain.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_form_int_name     IN pre_hosp_form.internal_name%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_start_record      IN NUMBER,
        i_num_records       IN NUMBER,
        o_ann_arriv_hist    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_HIST_INT';
        --
        l_zero                   CONSTANT PLS_INTEGER := 0;
        l_one                    CONSTANT PLS_INTEGER := 1;
        l_space                  CONSTANT VARCHAR2(1) := ' ';
        l_code_msg_status        CONSTANT sys_message.code_message%TYPE := 'ANN_ARRIV_MSG077';
        l_code_msg_del_info      CONSTANT sys_message.code_message%TYPE := 'COMMON_M106';
        l_code_msg_new           CONSTANT sys_message.code_message%TYPE := 'ANN_ARRIV_MSG113';
        l_code_msg_cancel_reason CONSTANT sys_message.code_message%TYPE := 'ANN_ARRIV_MSG012';
        l_code_msg_cancel_notes  CONSTANT sys_message.code_message%TYPE := 'ANN_ARRIV_MSG013';
        --
        l_tbl_steps     pk_edis_types.table_step;
        l_tbl_sections  pk_edis_types.table_section;
        l_tbl_fields    pk_edis_types.table_field;
        l_tbl_vs_header pk_vital_sign.t_coll_vs_header;
        r_step          pk_edis_types.rec_step;
        r_section       pk_edis_types.rec_section;
        r_field         pk_edis_types.rec_field;
        r_vs_read       pk_vital_sign.t_rec_vs_header;
        --
        l_tbl_old_vs_read    pk_pre_hosp_accident.table_vs_read;
        r_old_vs_read        pk_pre_hosp_accident.rec_vs_read;
        l_tbl_new_vs_read    pk_pre_hosp_accident.table_vs_read;
        r_new_vs_read        pk_pre_hosp_accident.rec_vs_read;
        l_tbl_ann_arriv_hist pk_announced_arrival.table_ann_arriv_hist;
        r_ann_arriv_hist     pk_announced_arrival.rec_ann_arriv_hist;
        --
        l_section_title_added BOOLEAN;
        l_msg_status          sys_message.desc_message%TYPE;
        l_msg_del_info        sys_message.desc_message%TYPE;
        l_msg_new             sys_message.desc_message%TYPE;
        --
        l_msg_cancel_reason sys_message.desc_message%TYPE;
        l_msg_cancel_notes  sys_message.desc_message%TYPE;
        --
        l_aah_prev pk_announced_arrival.rec_announced_arrival;
        l_aah_curr pk_announced_arrival.rec_announced_arrival;
        --
        l_old_value VARCHAR2(1000 CHAR);
        l_new_value VARCHAR2(1000 CHAR);
        --
        l_external_excpt EXCEPTION;
        l_internal_excpt EXCEPTION;
        --
        --Get form steps, sections and fields cursors and return them as table objects
        PROCEDURE fill_form_tables
        (
            o_tbl_steps     OUT pk_edis_types.table_step,
            o_tbl_sections  OUT pk_edis_types.table_section,
            o_tbl_fields    OUT pk_edis_types.table_field,
            o_tbl_vs_header OUT pk_vital_sign.t_coll_vs_header
        ) IS
            l_proc_name CONSTANT VARCHAR2(30) := 'FILL_FORM_TABLES';
            --
            l_desc_form sys_message.desc_message%TYPE;
            c_steps     pk_edis_types.cursor_step;
            c_sections  pk_edis_types.cursor_section;
            c_fields    pk_edis_types.cursor_field;
            c_vs        pk_vital_sign.t_cur_vs_header;
        BEGIN
            g_error := 'CALL GET_FORM_INT';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            IF NOT get_form_int(i_lang          => i_lang,
                                i_prof          => i_prof,
                                i_form_int_name => i_form_int_name,
                                o_desc_form     => l_desc_form,
                                o_steps         => c_steps,
                                o_sections      => c_sections,
                                o_fields        => c_fields,
                                o_vital_signs   => c_vs,
                                o_error         => o_error)
            THEN
                RAISE l_external_excpt;
            END IF;
        
            g_error := 'FILL O_TBL_STEPS';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            FETCH c_steps BULK COLLECT
                INTO o_tbl_steps;
            CLOSE c_steps;
        
            g_error := 'FILL O_TBL_SECTIONS';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            FETCH c_sections BULK COLLECT
                INTO o_tbl_sections;
            CLOSE c_sections;
        
            g_error := 'FILL O_TBL_FIELDS';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            FETCH c_fields BULK COLLECT
                INTO o_tbl_fields;
            CLOSE c_fields;
        
            g_error := 'FILL O_TBL_VS_HEADER';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_proc_name);
            FETCH c_vs BULK COLLECT
                INTO o_tbl_vs_header;
            CLOSE c_vs;
        END fill_form_tables;
    
        --Function GET_FIELD_DIFF_VALUE returns TRUE if old and new value are different and must be shown otherwise returns FALSE
        FUNCTION get_field_diff_value
        (
            i_aah_prev       IN pk_announced_arrival.rec_announced_arrival,
            i_aah_curr       IN pk_announced_arrival.rec_announced_arrival,
            i_field_int_name IN pre_hosp_field.internal_name%TYPE,
            o_old_value      OUT VARCHAR2,
            o_new_value      OUT VARCHAR2
        ) RETURN BOOLEAN IS
            l_sub_func_name CONSTANT VARCHAR2(30) := 'GET_FIELD_DIFF_VALUE';
            --
            l_null_value CONSTANT VARCHAR2(10) := 'NULL_VALUE';
        BEGIN
            g_error := 'GET OLD AND NEW VALUE';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_sub_func_name);
            CASE i_field_int_name
                WHEN g_fld_patient_name THEN
                    o_old_value := i_aah_prev.pat_name;
                    o_new_value := i_aah_curr.pat_name;
                WHEN g_fld_patient_gender THEN
                    o_old_value := i_aah_prev.gender;
                    o_new_value := i_aah_curr.gender;
                WHEN g_fld_patient_birthday THEN
                    o_old_value := i_aah_prev.dt_birth_chr;
                    o_new_value := i_aah_curr.dt_birth_chr;
                WHEN g_fld_patient_age THEN
                    o_old_value := i_aah_prev.age;
                    o_new_value := i_aah_curr.age;
                WHEN g_fld_patient_address THEN
                    o_old_value := i_aah_prev.address;
                    o_new_value := i_aah_curr.address;
                WHEN g_fld_patient_city THEN
                    o_old_value := i_aah_prev.city;
                    o_new_value := i_aah_curr.city;
                WHEN g_fld_patient_postcode THEN
                    o_old_value := i_aah_prev.pat_zip_code;
                    o_new_value := i_aah_curr.pat_zip_code;
                WHEN g_fld_arrival_acident_time THEN
                    o_old_value := i_aah_prev.dt_accident;
                    o_new_value := i_aah_curr.dt_accident;
                WHEN g_fld_arrival_problem THEN
                    o_old_value := i_aah_prev.type_injury;
                    o_new_value := i_aah_curr.type_injury;
                WHEN g_fld_arrival_condition THEN
                    o_old_value := i_aah_prev.condition;
                    o_new_value := i_aah_curr.condition;
                WHEN g_fld_arrival_refby THEN
                    o_old_value := i_aah_prev.referred_by;
                    o_new_value := i_aah_curr.referred_by;
                WHEN g_fld_arrival_specialty THEN
                    o_old_value := i_aah_prev.desc_speciality;
                    o_new_value := i_aah_curr.desc_speciality;
                WHEN g_fld_arrival_clinserv THEN
                    o_old_value := i_aah_prev.desc_clinical_service;
                    o_new_value := i_aah_curr.desc_clinical_service;
                WHEN g_fld_arrival_physician THEN
                    o_old_value := i_aah_prev.ed_physician_name;
                    o_new_value := i_aah_curr.ed_physician_name;
                WHEN g_fld_arrival_expect_time THEN
                    o_old_value := i_aah_prev.dt_expected_arrival;
                    o_new_value := i_aah_curr.dt_expected_arrival;
                WHEN g_fld_bystander_emdc_time THEN
                    o_old_value := i_aah_prev.dt_report_mka;
                    o_new_value := i_aah_curr.dt_report_mka;
                WHEN g_fld_bystander_emdc_code THEN
                    o_old_value := i_aah_prev.cpa_code;
                    o_new_value := i_aah_curr.cpa_code;
                WHEN g_fld_ambulance_trust THEN
                    o_old_value := i_aah_prev.amb_trust_code;
                    o_new_value := i_aah_curr.amb_trust_code;
                WHEN g_fld_bystander_amb_ride THEN
                    o_old_value := i_aah_prev.transport_number;
                    o_new_value := i_aah_curr.transport_number;
                WHEN g_fld_bystander_postcode THEN
                    o_old_value := i_aah_prev.acc_zip_code;
                    o_new_value := i_aah_curr.acc_zip_code;
                WHEN g_fld_bystander_latitude THEN
                    o_old_value := i_aah_prev.latitude;
                    o_new_value := i_aah_curr.latitude;
                WHEN g_fld_bystander_longitude THEN
                    o_old_value := i_aah_prev.longitude;
                    o_new_value := i_aah_curr.longitude;
                WHEN g_fld_transport_ride_out THEN
                    o_old_value := i_aah_prev.dt_ride_out;
                    o_new_value := i_aah_curr.dt_ride_out;
                WHEN g_fld_transport_arrival THEN
                    o_old_value := i_aah_prev.dt_arrival;
                    o_new_value := i_aah_curr.dt_arrival;
                WHEN g_fld_triage_injury_mech THEN
                    o_old_value := i_aah_prev.mech_injury;
                    o_new_value := i_aah_curr.mech_injury;
                WHEN g_fld_medtreat_away_time THEN
                    o_old_value := i_aah_prev.dt_drv_away;
                    o_new_value := i_aah_curr.dt_drv_away;
                WHEN g_fld_rtc_flg_prot_device THEN
                    o_old_value := i_aah_prev.desc_prot_device;
                    o_new_value := i_aah_curr.desc_prot_device;
                WHEN g_fld_rtc_flg_rta_pat_typ THEN
                    o_old_value := i_aah_prev.desc_rta_pat_typ;
                    o_new_value := i_aah_curr.desc_rta_pat_typ;
                WHEN g_fld_rtc_flg_is_driv_own THEN
                    o_old_value := i_aah_prev.desc_is_driv_own;
                    o_new_value := i_aah_curr.desc_is_driv_own;
                WHEN g_fld_rtc_flg_police_involved THEN
                    o_old_value := i_aah_prev.desc_police_involved;
                    o_new_value := i_aah_curr.desc_police_involved;
                WHEN g_fld_rtc_police_num THEN
                    o_old_value := i_aah_prev.police_num;
                    o_new_value := i_aah_curr.police_num;
                WHEN g_fld_rtc_police_station THEN
                    o_old_value := i_aah_prev.police_station;
                    o_new_value := i_aah_curr.police_station;
                WHEN g_fld_rtc_police_accident_num THEN
                    o_old_value := i_aah_prev.police_accident_num;
                    o_new_value := i_aah_curr.police_accident_num;
                ELSE
                    g_error := 'FIELD "' || i_field_int_name || '" not found!!!';
                    pk_alertlog.log_debug(text            => g_error,
                                                   object_name     => g_pck_name,
                                                   sub_object_name => l_sub_func_name);
                    o_old_value := NULL;
                    o_new_value := NULL;
            END CASE;
        
            g_error := 'COMPARE VALUES';
            pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_sub_func_name);
            IF nvl(o_old_value, l_null_value) != nvl(o_new_value, l_null_value)
            THEN
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END get_field_diff_value;
    
        PROCEDURE add_section_title IS
        BEGIN
            IF NOT l_section_title_added
            THEN
                g_error := 'ADD SECTION TITLE';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                pk_edis_hist.add_value(i_label => r_section.desc_section,
                                       i_value => NULL,
                                       i_type  => pk_edis_hist.g_type_title);
            
                l_section_title_added := TRUE;
            END IF;
        END add_section_title;
    
        FUNCTION get_vs_label_new(i_label IN sys_message.desc_message%TYPE) RETURN sys_message.desc_message%TYPE IS
            l_one   CONSTANT PLS_INTEGER := 1;
            l_space CONSTANT VARCHAR2(1) := ' ';
        BEGIN
            RETURN i_label || l_space || l_msg_new;
        END get_vs_label_new;
    BEGIN
        g_error := 'GET MSG STATUS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_status := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_status);
    
        g_error := 'GET MSG DELETE INFORMATION';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_del_info := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_del_info);
    
        g_error := 'GET MSG NEW';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_new := pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_msg_new);
    
        g_error := 'GET MSG CANCEL';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_msg_cancel_reason := pk_message.get_message(i_lang, l_code_msg_cancel_reason);
        l_msg_cancel_notes  := pk_message.get_message(i_lang, l_code_msg_cancel_notes);
    
        g_error := 'CALL FILL_FORM_TABLES';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        -- Get form steps, sections and fields that are configured to be shown
        fill_form_tables(o_tbl_steps     => l_tbl_steps,
                         o_tbl_sections  => l_tbl_sections,
                         o_tbl_fields    => l_tbl_fields,
                         o_tbl_vs_header => l_tbl_vs_header);
    
        g_error := 'INITIALIZE HIST TABLE';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        -- Initialize history table
        pk_edis_hist.init_vars;
    
        g_error := 'CALL GET_ANN_ARRIV_HIST_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        l_tbl_ann_arriv_hist := get_ann_arriv_hist_int(i_lang              => i_lang,
                                                       i_prof              => i_prof,
                                                       i_announced_arrival => i_announced_arrival,
                                                       i_flg_screen        => i_flg_screen,
                                                       i_start_record      => i_start_record,
                                                       i_num_records       => i_num_records);
    
        g_error := 'SCROLL ANN_ARRIV HIST CURSOR';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
    
        IF l_tbl_ann_arriv_hist.exists(1)
        THEN
            -- Loop through all history records
            FOR h IN l_tbl_ann_arriv_hist.first .. l_tbl_ann_arriv_hist.last
            LOOP
                r_ann_arriv_hist := l_tbl_ann_arriv_hist(h);
            
                g_error := 'ADD NEW HIST LINE';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                -- Create a new line in history table with current history record 
                pk_edis_hist.add_line(i_history        => r_ann_arriv_hist.curr_ann_arriv_hist,
                                      i_dt_hist        => r_ann_arriv_hist.dt_announced_arrival,
                                      i_record_state   => r_ann_arriv_hist.flg_status,
                                      i_desc_rec_state => r_ann_arriv_hist.desc_status);
            
                g_error := 'CALL GET_ANN_ARRIVAL_REC - PREVIOUS RECORD';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                -- Get previous history record
                l_aah_prev := get_ann_arrival_rec(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_announced_arrival_hist => r_ann_arriv_hist.prev_ann_arriv_hist,
                                                  i_pre_hosp_accident      => r_ann_arriv_hist.prev_pha);
            
                g_error := 'CALL GET_ANN_ARRIVAL_REC - CURRENT RECORD';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                -- Get current history record
                l_aah_curr := get_ann_arrival_rec(i_lang                   => i_lang,
                                                  i_prof                   => i_prof,
                                                  i_announced_arrival_hist => r_ann_arriv_hist.curr_ann_arriv_hist,
                                                  i_pre_hosp_accident      => r_ann_arriv_hist.curr_pha);
            
                g_error := 'SCROLL STEPS TABLE';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                IF l_tbl_steps.exists(1)
                THEN
                    -- Loop through form steps
                    FOR i IN l_tbl_steps.first .. l_tbl_steps.last
                    LOOP
                        r_step := l_tbl_steps(i);
                    
                        -- NOTE: Step title isn't shown on detail independently to the r_step.flg_show_step_msg value
                    
                        g_error := 'SCROLL SECTIONS TABLE';
                        pk_alertlog.log_debug(text            => g_error,
                                                       object_name     => g_pck_name,
                                                       sub_object_name => l_func_name);
                        IF l_tbl_sections.exists(1)
                        THEN
                            -- Loop through step sections
                            FOR j IN l_tbl_sections.first .. l_tbl_sections.last
                            LOOP
                                r_section := l_tbl_sections(j);
                                -- Section title will be added only when at least one of section fields was changed
                                l_section_title_added := FALSE;
                            
                                -- Only consider sections of the current step
                                IF r_section.id_pre_hosp_step = r_step.id_pre_hosp_step
                                THEN
                                    g_error := 'SCROLL FIELDS TABLE';
                                    pk_alertlog.log_debug(text            => g_error,
                                                                   object_name     => g_pck_name,
                                                                   sub_object_name => l_func_name);
                                    IF l_tbl_fields.exists(1)
                                    THEN
                                        -- Loop through section fields
                                        FOR k IN l_tbl_fields.first .. l_tbl_fields.last
                                        LOOP
                                            r_field := l_tbl_fields(k);
                                        
                                            -- Only consider fields of current section and which value has changed
                                            IF r_field.id_pre_hosp_step = r_step.id_pre_hosp_step
                                               AND r_field.id_pre_hosp_section = r_section.id_pre_hosp_section
                                            THEN
                                                IF r_field.field_int_name != g_fld_vital_signs
                                                   AND get_field_diff_value(i_aah_prev       => l_aah_prev,
                                                                            i_aah_curr       => l_aah_curr,
                                                                            i_field_int_name => r_field.field_int_name,
                                                                            o_old_value      => l_old_value,
                                                                            o_new_value      => l_new_value)
                                                THEN
                                                    -- Add section title if it hasn't been done yet
                                                    add_section_title;
                                                
                                                    --Cases for possible changes:
                                                    -- OLD_VALUE: NULL;        NEW_VALUE: NOT NULL;    SHOW: desc_field;
                                                    -- OLD_VALUE: X;           NEW_VALUE: Y;           SHOW: desc_field and desc_new_field;
                                                    -- OLD_VALUE: NOT NULL;    NEW_VALUE: NULL;        SHOW: desc_field and desc_new_field; new_value = <informação apagada>
                                                
                                                    IF r_ann_arriv_hist.prev_ann_arriv_hist IS NOT NULL
                                                    THEN
                                                        g_error := 'ADD NEW VALUE';
                                                        pk_alertlog.log_debug(text            => g_error,
                                                                                       object_name     => g_pck_name,
                                                                                       sub_object_name => l_func_name);
                                                        -- Add new value to history table
                                                        pk_edis_hist.add_value(i_label => r_field.desc_new_field,
                                                                               i_value => nvl(l_new_value,
                                                                                              l_msg_del_info),
                                                                               i_type  => pk_edis_hist.g_type_new_content);
                                                    END IF;
                                                
                                                    IF r_ann_arriv_hist.prev_ann_arriv_hist IS NULL --First record value
                                                       OR l_old_value IS NOT NULL --It's not need to add old_value = NULL
                                                    THEN
                                                        g_error := 'ADD OLD VALUE';
                                                        pk_alertlog.log_debug(text            => g_error,
                                                                                       object_name     => g_pck_name,
                                                                                       sub_object_name => l_func_name);
                                                        -- Add old value to history table
                                                        pk_edis_hist.add_value(i_label => r_field.desc_field,
                                                                               i_value => CASE
                                                                                          --first record value
                                                                                              WHEN r_ann_arriv_hist.prev_ann_arriv_hist IS NULL THEN
                                                                                               l_new_value
                                                                                              ELSE
                                                                                               l_old_value
                                                                                          END,
                                                                               i_type  => pk_edis_hist.g_type_content);
                                                    END IF;
                                                ELSIF r_field.field_int_name = g_fld_vital_signs --Add all vital sign fields
                                                THEN
                                                    -- Get vital sign tables
                                                    IF r_ann_arriv_hist.prev_pha IS NOT NULL
                                                    THEN
                                                        g_error := 'GET VS_READ - OLD';
                                                        pk_alertlog.log_debug(text            => g_error,
                                                                                       object_name     => g_pck_name,
                                                                                       sub_object_name => l_func_name);
                                                        l_tbl_old_vs_read := pk_pre_hosp_accident.get_vs_read(i_lang              => i_lang,
                                                                                                              i_prof              => i_prof,
                                                                                                              i_pre_hosp_accident => r_ann_arriv_hist.prev_pha);
                                                    ELSE
                                                        l_tbl_old_vs_read := NULL;
                                                    END IF;
                                                
                                                    g_error := 'GET VS_READ - NEW';
                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                   object_name     => g_pck_name,
                                                                                   sub_object_name => l_func_name);
                                                    l_tbl_new_vs_read := pk_pre_hosp_accident.get_vs_read(i_lang              => i_lang,
                                                                                                          i_prof              => i_prof,
                                                                                                          i_pre_hosp_accident => r_ann_arriv_hist.curr_pha);
                                                
                                                    IF (l_tbl_old_vs_read IS NULL OR l_tbl_old_vs_read.count = l_zero)
                                                       AND (l_tbl_new_vs_read IS NOT NULL AND
                                                       l_tbl_new_vs_read.count > l_zero)
                                                    THEN
                                                        --Only new values are available this means that is the first record so show values as content (pk_edis_hist.g_type_content)
                                                        FOR l IN l_tbl_new_vs_read.first .. l_tbl_new_vs_read.last
                                                        LOOP
                                                            r_new_vs_read := l_tbl_new_vs_read(l);
                                                        
                                                            IF r_new_vs_read.value IS NOT NULL
                                                            THEN
                                                                -- Add section title if it hasn't been done yet
                                                                add_section_title;
                                                            
                                                                g_error := 'ADD VALUE';
                                                                pk_alertlog.log_debug(text            => g_error,
                                                                                               object_name     => g_pck_name,
                                                                                               sub_object_name => l_func_name);
                                                                -- Add value to history table as content
                                                                pk_edis_hist.add_value(i_label => r_new_vs_read.name_vs,
                                                                                       i_value => r_new_vs_read.value || --
                                                                                                  CASE
                                                                                                      WHEN r_new_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                       l_space || r_new_vs_read.desc_unit_measure
                                                                                                      ELSE
                                                                                                       NULL
                                                                                                  END,
                                                                                       i_type  => pk_edis_hist.g_type_content);
                                                            END IF;
                                                        END LOOP;
                                                    ELSIF (l_tbl_old_vs_read IS NOT NULL AND
                                                          l_tbl_old_vs_read.count > l_zero)
                                                          AND (l_tbl_new_vs_read IS NOT NULL AND
                                                          l_tbl_new_vs_read.count > l_zero)
                                                    THEN
                                                        IF l_tbl_vs_header.exists(1)
                                                        THEN
                                                            --Both values available, it's used VS_HEADER table loop through VS's
                                                            FOR l IN l_tbl_vs_header.first .. l_tbl_vs_header.last
                                                            LOOP
                                                                r_vs_read := l_tbl_vs_header(l);
                                                            
                                                                -- FIND CURRENT VS IN OLD VS TABLE
                                                                r_old_vs_read := NULL;
                                                                FOR m IN l_tbl_old_vs_read.first .. l_tbl_old_vs_read.last
                                                                LOOP
                                                                    IF l_tbl_old_vs_read(m)
                                                                     .id_vital_sign = r_vs_read.id_vital_sign
                                                                    THEN
                                                                        r_old_vs_read := l_tbl_old_vs_read(m);
                                                                        EXIT;
                                                                    END IF;
                                                                END LOOP;
                                                            
                                                                -- FIND CURRENT VS IN NEW VS TABLE
                                                                r_new_vs_read := NULL;
                                                                FOR m IN l_tbl_new_vs_read.first .. l_tbl_new_vs_read.last
                                                                LOOP
                                                                    IF l_tbl_new_vs_read(m)
                                                                     .id_vital_sign = r_vs_read.id_vital_sign
                                                                    THEN
                                                                        r_new_vs_read := l_tbl_new_vs_read(m);
                                                                        EXIT;
                                                                    END IF;
                                                                END LOOP;
                                                            
                                                                IF r_old_vs_read.value IS NULL
                                                                   AND r_new_vs_read.value IS NOT NULL
                                                                THEN
                                                                    -- Add section title if it hasn't been done yet
                                                                    add_section_title;
                                                                
                                                                    g_error := 'ADD VALUE';
                                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                                   object_name     => g_pck_name,
                                                                                                   sub_object_name => l_func_name);
                                                                    -- Add new value to history table as content
                                                                    pk_edis_hist.add_value(i_label => get_vs_label_new(i_label => r_new_vs_read.name_vs),
                                                                                           i_value => r_new_vs_read.value || --
                                                                                                      CASE
                                                                                                          WHEN r_new_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                           l_space || r_new_vs_read.desc_unit_measure
                                                                                                          ELSE
                                                                                                           NULL
                                                                                                      END,
                                                                                           i_type  => pk_edis_hist.g_type_new_content);
                                                                ELSIF r_old_vs_read.value IS NOT NULL
                                                                      AND r_new_vs_read.value IS NOT NULL
                                                                      AND r_old_vs_read.value != r_new_vs_read.value
                                                                THEN
                                                                    -- Add section title if it hasn't been done yet
                                                                    add_section_title;
                                                                
                                                                    g_error := 'ADD NEW VALUE';
                                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                                   object_name     => g_pck_name,
                                                                                                   sub_object_name => l_func_name);
                                                                    -- Add new value to history table
                                                                    pk_edis_hist.add_value(i_label => get_vs_label_new(i_label => r_new_vs_read.name_vs),
                                                                                           i_value => r_new_vs_read.value || --
                                                                                                      CASE
                                                                                                          WHEN r_new_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                           l_space || r_new_vs_read.desc_unit_measure
                                                                                                          ELSE
                                                                                                           NULL
                                                                                                      END,
                                                                                           i_type  => pk_edis_hist.g_type_new_content);
                                                                
                                                                    g_error := 'ADD OLD VALUE';
                                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                                   object_name     => g_pck_name,
                                                                                                   sub_object_name => l_func_name);
                                                                    -- Add old value to history table
                                                                    pk_edis_hist.add_value(i_label => r_old_vs_read.name_vs,
                                                                                           i_value => r_old_vs_read.value || --
                                                                                                      CASE
                                                                                                          WHEN r_old_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                           l_space || r_old_vs_read.desc_unit_measure
                                                                                                          ELSE
                                                                                                           NULL
                                                                                                      END,
                                                                                           i_type  => pk_edis_hist.g_type_content);
                                                                ELSIF r_old_vs_read.value IS NOT NULL
                                                                      AND r_new_vs_read.value IS NULL
                                                                THEN
                                                                    -- Add section title if it hasn't been done yet
                                                                    add_section_title;
                                                                
                                                                    g_error := 'ADD NEW VALUE';
                                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                                   object_name     => g_pck_name,
                                                                                                   sub_object_name => l_func_name);
                                                                    -- Add new value to history table
                                                                    pk_edis_hist.add_value(i_label => get_vs_label_new(i_label => r_old_vs_read.name_vs),
                                                                                           i_value => l_msg_del_info,
                                                                                           i_type  => pk_edis_hist.g_type_new_content);
                                                                
                                                                    g_error := 'ADD OLD VALUE';
                                                                    pk_alertlog.log_debug(text            => g_error,
                                                                                                   object_name     => g_pck_name,
                                                                                                   sub_object_name => l_func_name);
                                                                    -- Add old value to history table
                                                                    pk_edis_hist.add_value(i_label => r_old_vs_read.name_vs,
                                                                                           i_value => r_old_vs_read.value || --
                                                                                                      CASE
                                                                                                          WHEN r_old_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                           l_space || r_old_vs_read.desc_unit_measure
                                                                                                          ELSE
                                                                                                           NULL
                                                                                                      END,
                                                                                           i_type  => pk_edis_hist.g_type_content);
                                                                END IF;
                                                            END LOOP;
                                                        END IF;
                                                    ELSIF (l_tbl_old_vs_read IS NOT NULL AND
                                                          l_tbl_old_vs_read.count > l_zero)
                                                          AND (l_tbl_new_vs_read IS NULL OR
                                                          l_tbl_new_vs_read.count = l_zero)
                                                    THEN
                                                        -- Only old values are available this means that vital sign were delete
                                                        FOR l IN l_tbl_old_vs_read.first .. l_tbl_old_vs_read.last
                                                        LOOP
                                                            r_old_vs_read := l_tbl_old_vs_read(l);
                                                        
                                                            IF r_old_vs_read.value IS NOT NULL
                                                            THEN
                                                                -- Add section title if it hasn't been done yet
                                                                add_section_title;
                                                            
                                                                g_error := 'ADD NEW VALUE';
                                                                pk_alertlog.log_debug(text            => g_error,
                                                                                               object_name     => g_pck_name,
                                                                                               sub_object_name => l_func_name);
                                                                -- Add new value to history table
                                                                pk_edis_hist.add_value(i_label => get_vs_label_new(i_label => r_old_vs_read.name_vs),
                                                                                       i_value => l_msg_del_info,
                                                                                       i_type  => pk_edis_hist.g_type_new_content);
                                                            
                                                                g_error := 'ADD OLD VALUE';
                                                                pk_alertlog.log_debug(text            => g_error,
                                                                                               object_name     => g_pck_name,
                                                                                               sub_object_name => l_func_name);
                                                                -- Add old value to history table
                                                                pk_edis_hist.add_value(i_label => r_old_vs_read.name_vs,
                                                                                       i_value => r_old_vs_read.value || --
                                                                                                  CASE
                                                                                                      WHEN r_old_vs_read.desc_unit_measure IS NOT NULL THEN
                                                                                                       l_space || r_old_vs_read.desc_unit_measure
                                                                                                      ELSE
                                                                                                       NULL
                                                                                                  END,
                                                                                       i_type  => pk_edis_hist.g_type_content);
                                                            END IF;
                                                        END LOOP;
                                                    END IF;
                                                END IF;
                                            END IF;
                                        END LOOP;
                                    END IF;
                                END IF;
                            END LOOP;
                        END IF;
                    END LOOP;
                END IF;
                g_error := 'ADD RECORD STATUS AND SIGNATURE';
                pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
                -- Add record status
                -- Add signature of person which changed the record
            
                IF (r_ann_arriv_hist.cancel_reason IS NOT NULL)
                THEN
                    pk_edis_hist.add_value(i_label => NULL,
                                           i_value => l_msg_status || l_space || r_ann_arriv_hist.desc_status || chr(13) || --
                                                     
                                                      l_msg_cancel_reason || ':' || l_space ||
                                                      r_ann_arriv_hist.cancel_reason || chr(13) || l_msg_cancel_notes || ':' ||
                                                      l_space || r_ann_arriv_hist.cancel_notes || chr(13) ||
                                                      pk_edis_hist.get_signature(i_lang                => i_lang,
                                                                                 i_prof                => i_prof,
                                                                                 i_id_episode          => r_ann_arriv_hist.id_episode,
                                                                                 i_date                => r_ann_arriv_hist.dt_announced_arrival,
                                                                                 i_id_prof_last_change => r_ann_arriv_hist.id_prof_create),
                                           
                                           i_type => pk_edis_hist.g_type_signature);
                ELSE
                    pk_edis_hist.add_value(i_label => NULL,
                                           i_value => l_msg_status || l_space || r_ann_arriv_hist.desc_status || chr(13) || --
                                                      pk_edis_hist.get_signature(i_lang                => i_lang,
                                                                                 i_prof                => i_prof,
                                                                                 i_id_episode          => r_ann_arriv_hist.id_episode,
                                                                                 i_date                => r_ann_arriv_hist.dt_announced_arrival,
                                                                                 i_id_prof_last_change => r_ann_arriv_hist.id_prof_create),
                                           
                                           i_type => pk_edis_hist.g_type_signature);
                
                END IF;
            END LOOP;
        END IF;
        g_error := 'OPEN O_ANN_ARRIV_HIST CURSOR';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        OPEN o_ann_arriv_hist FOR
            SELECT t.id_history,
                   t.dt_history,
                   t.tbl_labels,
                   t.tbl_values,
                   t.tbl_types,
                   t.tbl_info_labels,
                   t.tbl_info_values
              FROM TABLE(pk_edis_hist.tf_hist) t;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ann_arriv_hist);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_hist_int;

    /********************************************************************************************
    * Get detail and/or history data for a given announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_announced_arrival      announced arrival id
    * @param i_form_int_name          Form internal name
    * @param i_flg_screen             Returned info is for which screen?
    * @param i_start_record           Paging - initial record number
    * @param i_num_records            Paging - number of records to display
    * @param o_ann_arriv_hist         Detail/History data                                              
    * @param o_error                  Error object                                              
    *                        
    * @value   i_form_int_name     ANN_ARRIVAL_FORM - Announced arrival form
    *                              PREHOSPITAL_FORM - Pre hospital form
    *                                                    
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arrival_hist
    (
        i_lang              IN sys_domain.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_form_int_name     IN pre_hosp_form.internal_name%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_start_record      IN NUMBER,
        i_num_records       IN NUMBER,
        o_ann_arriv_hist    OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_HIST';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_ANN_ARRIVAL_HIST_INT';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        IF NOT get_ann_arrival_hist_int(i_lang              => i_lang,
                                        i_prof              => i_prof,
                                        i_announced_arrival => i_announced_arrival,
                                        i_form_int_name     => i_form_int_name,
                                        i_flg_screen        => i_flg_screen,
                                        i_start_record      => i_start_record,
                                        i_num_records       => i_num_records,
                                        o_ann_arriv_hist    => o_ann_arriv_hist,
                                        o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_ann_arriv_hist);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ann_arriv_hist);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_hist;

    /********************************************************************************************
    * Get the announced arrival patient data, using the episode. 
    * The fields shown and their rank are those configured in the form "PREHOSPITAL_FORM"
    * (THIS FUNCTION IS ONLY USED BY: Reports Team)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                Episode id
    * @param i_flg_screen             Returned info is for which screen?
    * @param o_ann_arriv_det          Detail/History data                                              
    * @param o_error                  Error object                                              
    *                                                    
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arrival_det
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_flg_screen    IN VARCHAR2,
        o_ann_arriv_det OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_DET';
        --
        l_announced_arrival  announced_arrival.id_announced_arrival%TYPE;
        l_ann_arriv_has_data VARCHAR2(1);
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_ANNOUNCED_ARRIVAL.IS_PRE_HOSP_DATA_FILLED';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_announced_arrival.is_pre_hosp_data_filled(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_episode           => i_episode,
                                                            o_flg_has_data      => l_ann_arriv_has_data,
                                                            o_announced_arrival => l_announced_arrival,
                                                            o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_ann_arriv_has_data = pk_alert_constant.g_yes
        THEN
        
            g_error := 'CALL GET_ANN_ARRIVAL_HIST_INT';
            pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
            IF NOT get_ann_arrival_hist_int(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_announced_arrival => l_announced_arrival,
                                            i_form_int_name     => g_frm_pre_hospital,
                                            i_flg_screen        => i_flg_screen,
                                            i_start_record      => NULL,
                                            i_num_records       => NULL,
                                            o_ann_arriv_hist    => o_ann_arriv_det,
                                            o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_ann_arriv_det);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_ann_arriv_det);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ann_arriv_det);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_det;

    /********************************************************************************************
    * Get the announced arrival patient data, using the episode. 
    * The fields shown and their rank are those configured in the form "REPORT_FORM"
    * (THIS FUNCTION IS ONLY USED BY: Reports Team)
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                Episode id
    * @param i_flg_screen             Returned info is for which screen?
    * @param o_ann_arriv_rep          Detail/History data                                              
    * @param o_error                  Error object                                              
    *                                                    
    * @value   i_flg_screen        D - Detail screen                                            
    *                              H - History screen
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos 
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION get_ann_arrival_rep
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN announced_arrival.id_episode%TYPE,
        i_flg_screen    IN VARCHAR2,
        o_ann_arriv_rep OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ANN_ARRIVAL_REP';
        --
        l_announced_arrival  announced_arrival.id_announced_arrival%TYPE;
        l_ann_arriv_has_data VARCHAR2(1);
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_ANNOUNCED_ARRIVAL.IS_PRE_HOSP_DATA_FILLED';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_announced_arrival.is_pre_hosp_data_filled(i_lang              => i_lang,
                                                            i_prof              => i_prof,
                                                            i_episode           => i_episode,
                                                            o_flg_has_data      => l_ann_arriv_has_data,
                                                            o_announced_arrival => l_announced_arrival,
                                                            o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        IF l_ann_arriv_has_data = pk_alert_constant.g_yes
        THEN
            g_error := 'CALL GET_ANN_ARRIVAL_HIST_INT';
            pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
            IF NOT get_ann_arrival_hist_int(i_lang              => i_lang,
                                            i_prof              => i_prof,
                                            i_announced_arrival => l_announced_arrival,
                                            i_form_int_name     => g_frm_report,
                                            i_flg_screen        => i_flg_screen,
                                            i_start_record      => NULL,
                                            i_num_records       => NULL,
                                            o_ann_arriv_hist    => o_ann_arriv_rep,
                                            o_error             => o_error)
            THEN
                RAISE l_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_ann_arriv_rep);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_types.open_my_cursor(o_ann_arriv_rep);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_ann_arriv_rep);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ann_arrival_rep;

    /**
    * Encapsulates the logic of saving (create or update) a announced arrival patient
    * (CALLED BY: ADT TEAM)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_patient               Patient id - This arg should only be sent when you want to call the CREATE_ANN_ARRIVAL_BY_PAT
    * @param   i_params                XML with all input parameters
    * @param   o_announced_arrival     Announced arrival id 
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    * <ANNOUNCED_ARRIVAL ID_ANNOUNCED_ARRIVAL="" ID_EPISODE="">
    *   <!-- ID_EPISODE -> Only put this arg to substitute the old call to CREATE_ANN_ARRIVAL_BY_EPI - Creation in pre-hospital screen inside patient area -->
    *   <!-- ID_ANNOUNCED_ARRIVAL -> Only used when editing a existing recorded (Instead of calls to SET_ANN_ARRIVAL and SET_ANN_ARRIVAL_PRE_HOSP) -->
    *   <PATIENT NAME="" GENDER="" DT_BIRTH="" AGE="" ADDRESS="" CITY="" ZIP_CODE="" />
    *   <INCIDENT DT_ACCIDENT="" TYPE_INJURY="" CONDITION="" ZIP_CODE="" LATITUDE="" LONGITUDE="" />
    *   <REFERRAL_ARRIV REFERRED_BY="" SPECIALITY="" CLINICAL_SERVICE="" ED_PHYSICIAN="" DT_EXPECTED_ARRIVAL="" />
    *   <ACT_EMERG_SERV DT_REPORT_MKA="" CPA_CODE="" TRANSPORT_NUMBER="" DT_RIDE_OUT="" DT_ARRIVAL="" />
    *   <TRIAGE FLG_MECH_INJ="" MECH_INJURY_FT="" >
    *     <VITAL_SIGNS>
    *       <VITAL_SIGN ID="" VAL="" UNIT_MEAS="" />
    *     </VITAL_SIGNS>
    *   </TRIAGE>
    *   <TRANSFER_HOSP DT_DRV_AWAY="" />
    *   <RTC FLG_PROT_DEVICE="" FLG_RTA_PAT_TYPE="" RTA_PAT_TYPE_FT="" FLG_IS_DRIV_OWN="" FLG_POLICE_INVOLVED="" POLICE_NUM="" POLICE_STATION="" POLICE_ACCIDENT_NUM="" />
    * </ANNOUNCED_ARRIVAL>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    FUNCTION set_announced_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_params            IN CLOB,
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ANNOUNCED_ARRIVAL';
        --
        l_nls_num_char   CONSTANT VARCHAR2(30) := 'NLS_NUMERIC_CHARACTERS';
        l_cfg_dec_symbom CONSTANT sys_config.id_sys_config%TYPE := 'DECIMAL_SYMBOL';
        l_decimal_symbol  sys_config.value%TYPE;
        l_grouping_symbol VARCHAR2(1);
        l_back_nls        VARCHAR2(2);
        --
        CURSOR c_ann_arriv IS(
            SELECT a.id_announced_arrival,
                   a.id_episode,
                   --PATIENT
                   a.name,
                   a.gender,
                   a.dt_birth,
                   a.age,
                   a.address,
                   a.city,
                   a.zip_code,
                   --END_PATIENT
                   --INCIDENT
                   a.dt_accident,
                   a.type_injury,
                   a.condition,
                   a.acc_zip_code,
                   a.latitude,
                   a.longitude,
                   --END_INCIDENT
                   --REFERRAL_ARRIV
                   a.referred_by,
                   a.id_speciality,
                   a.id_clinical_service,
                   a.id_ed_physician,
                   a.dt_expected_arrival,
                   --END_REFERRAL_ARRIV
                   --ACT_EMERG_SERV
                   a.dt_report_mka,
                   a.cpa_code,
                   a.id_amb_trust_code,
                   a.ambulance_trust,
                   a.transport_number,
                   a.dt_ride_out,
                   a.dt_arrival,
                   --END_ACT_EMERG_SERV
                   --TRIAGE
                   a.flg_mech_inj,
                   a.mech_injury_ft,
                   extract(b.ann_arriv, '/ANNOUNCED_ARRIVAL/TRIAGE/VITAL_SIGNS') vital_signs,
                   --END_TRIAGE       
                   --TRANSFER_HOSP
                   a.dt_drv_away,
                   --END_TRANSFER_HOSP
                   --RTC
                   a.flg_prot_device,
                   a.flg_rta_pat_typ,
                   a.rta_pat_typ_ft,
                   a.flg_is_driv_own,
                   a.flg_police_involved,
                   a.police_num,
                   a.police_station,
                   a.police_accident_num
            --END_RTC
              FROM (SELECT VALUE(p) ann_arriv
                      FROM TABLE(xmlsequence(extract(xmltype(i_params), '/ANNOUNCED_ARRIVAL'))) p) b,
                   xmltable('/ANNOUNCED_ARRIVAL' passing b.ann_arriv columns --
                            "ID_ANNOUNCED_ARRIVAL" NUMBER(24) path '@ID_ANNOUNCED_ARRIVAL', --
                            "ID_EPISODE" NUMBER(24) path '@ID_EPISODE', --
                            --PATIENT
                            "NAME" VARCHAR2(200 CHAR) path 'PATIENT/@NAME', --
                            "GENDER" VARCHAR2(1 CHAR) path 'PATIENT/@GENDER', --
                            "DT_BIRTH" VARCHAR2(14 CHAR) path 'PATIENT/@DT_BIRTH', --
                            "AGE" NUMBER(6) path 'PATIENT/@AGE', --
                            "ADDRESS" VARCHAR2(1000 CHAR) path 'PATIENT/@ADDRESS', --
                            "CITY" VARCHAR2(200 CHAR) path 'PATIENT/@CITY', --
                            "ZIP_CODE" VARCHAR2(30 CHAR) path 'PATIENT/@ZIP_CODE', --
                            --END_PATIENT
                            --INCIDENT
                            "DT_ACCIDENT" VARCHAR2(14 CHAR) path 'INCIDENT/@DT_ACCIDENT', --
                            "TYPE_INJURY" VARCHAR2(200 CHAR) path 'INCIDENT/@TYPE_INJURY', --
                            "CONDITION" VARCHAR2(200 CHAR) path 'INCIDENT/@CONDITION', --
                            "ACC_ZIP_CODE" VARCHAR2(30 CHAR) path 'INCIDENT/@ZIP_CODE', --
                            "LATITUDE" NUMBER(9, 6) path 'INCIDENT/@LATITUDE', --
                            "LONGITUDE" NUMBER(9, 6) path 'INCIDENT/@LONGITUDE', --
                            --END_INCIDENT
                            --REFERRAL_ARRIV
                            "REFERRED_BY" VARCHAR2(200 CHAR) path 'REFERRAL_ARRIV/@REFERRED_BY', --
                            "ID_SPECIALITY" NUMBER(12) path 'REFERRAL_ARRIV/@SPECIALITY', --
                            "ID_CLINICAL_SERVICE" NUMBER(12) path 'REFERRAL_ARRIV/@CLINICAL_SERVICE', --
                            "ID_ED_PHYSICIAN" NUMBER(24) path 'REFERRAL_ARRIV/@ED_PHYSICIAN', --
                            "DT_EXPECTED_ARRIVAL" VARCHAR2(14 CHAR) path 'REFERRAL_ARRIV/@DT_EXPECTED_ARRIVAL', --
                            --END_REFERRAL_ARRIV
                            --ACT_EMERG_SERV
                            "DT_REPORT_MKA" VARCHAR2(14 CHAR) path 'ACT_EMERG_SERV/@DT_REPORT_MKA', --
                            "CPA_CODE" VARCHAR2(30 CHAR) path 'ACT_EMERG_SERV/@CPA_CODE', --
                            "ID_AMB_TRUST_CODE" NUMBER(24) path 'ACT_EMERG_SERV/@AMB_TRUST_CODE', --
                            "AMBULANCE_TRUST" VARCHAR2(200 CHAR) path 'ACT_EMERG_SERV/AMBULANCE_TRUST/.', --
                            "TRANSPORT_NUMBER" VARCHAR2(30 CHAR) path 'ACT_EMERG_SERV/@TRANSPORT_NUMBER', --
                            "DT_RIDE_OUT" VARCHAR2(14 CHAR) path 'ACT_EMERG_SERV/@DT_RIDE_OUT', --
                            "DT_ARRIVAL" VARCHAR2(14 CHAR) path 'ACT_EMERG_SERV/@DT_ARRIVAL', --
                            --END_ACT_EMERG_SERV
                            --TRIAGE
                            "FLG_MECH_INJ" VARCHAR2(2 CHAR) path 'TRIAGE/@FLG_MECH_INJ', --
                            "MECH_INJURY_FT" VARCHAR2(200 CHAR) path 'TRIAGE/@MECH_INJURY_FT', --
                            --END_TRIAGE
                            --TRANSFER_HOSP
                            "DT_DRV_AWAY" VARCHAR2(14 CHAR) path 'TRANSFER_HOSP/@DT_DRV_AWAY', --
                            --END_TRANSFER_HOSP
                            --RTC
                            "FLG_PROT_DEVICE" VARCHAR2(2 CHAR) path 'RTC/@FLG_PROT_DEVICE', --
                            "FLG_RTA_PAT_TYP" VARCHAR2(2 CHAR) path 'RTC/@FLG_RTA_PAT_TYPE', --
                            "RTA_PAT_TYP_FT" VARCHAR2(1000 CHAR) path 'RTC/@RTA_PAT_TYPE_FT', --
                            "FLG_IS_DRIV_OWN" VARCHAR2(1 CHAR) path 'RTC/@FLG_IS_DRIV_OWN', --
                            "FLG_POLICE_INVOLVED" VARCHAR2(1 CHAR) path 'RTC/@FLG_POLICE_INVOLVED', --
                            "POLICE_NUM" VARCHAR2(200 CHAR) path 'RTC/@POLICE_NUM', --
                            "POLICE_STATION" VARCHAR2(200 CHAR) path 'RTC/@POLICE_STATION', --
                            "POLICE_ACCIDENT_NUM" VARCHAR2(200 CHAR) path 'RTC/@POLICE_ACCIDENT_NUM' --
                            --END_RTC
                            ) a);
    
        r_ann_arriv c_ann_arriv%ROWTYPE;
        --
        l_vs_ids       table_number;
        l_vs_values    table_number;
        l_vs_unit_meas table_number;
        --
        l_exception EXCEPTION;
    BEGIN
        --ALERT-198369 - In this issue was reported a problem with the creation record date
        --This function is the entry point of all inserts/updates to the pre-hosp data, so it's only necessary to update here the
        --global var value
        g_sysdate_tstz := current_timestamp;
    
        g_error := 'GET DECIMAL SYMBOL';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        l_decimal_symbol := pk_sysconfig.get_config(l_cfg_dec_symbom, i_prof);
    
        g_error := 'SET GROUPING SYMBOL';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        IF l_decimal_symbol = ','
        THEN
            l_grouping_symbol := '.';
        ELSE
            l_grouping_symbol := ',';
        END IF;
    
        g_error := 'GET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        SELECT VALUE
          INTO l_back_nls
          FROM nls_session_parameters
         WHERE parameter = l_nls_num_char;
    
        g_error := 'SET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_decimal_symbol || l_grouping_symbol || '''';
    
        g_error := 'SCROLL THROUGH ALL PREGNANCIES EXAMS';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        FOR r_ann_arriv IN c_ann_arriv
        LOOP
            g_error := 'GET ALL PPRE_HOSP VS';
            pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
            SELECT a.id_vital_sign, a.value, a.id_unit_measure
              BULK COLLECT
              INTO l_vs_ids, l_vs_values, l_vs_unit_meas
              FROM (SELECT VALUE(b) vital_sign
                      FROM TABLE(xmlsequence(extract(r_ann_arriv.vital_signs, '/VITAL_SIGNS/*'))) b) c,
                   xmltable('/VITAL_SIGN' passing c.vital_sign columns --
                            "ID_VITAL_SIGN" NUMBER(24) path '@ID',
                            "VALUE" NUMBER(10, 3) path '@VAL',
                            "ID_UNIT_MEASURE" NUMBER(24) path '@UNIT_MEAS') a
             WHERE a.value IS NOT NULL;
        
            --Save rules:
            -- ID_ANNOUNCED_ARRIVAL IS NOT NULL -> CALL SET_ANN_ARRIVAL
            -- ID_PATIENT IS NOT NULL -> CALL CREATE_ANN_ARRIVAL_BY_PAT 
            -- ID_EPISODE IS NOT NULL -> CALL CREATE_ANN_ARRIVAL_BY_EPI
        
            IF r_ann_arriv.id_announced_arrival IS NOT NULL
            THEN
                IF NOT (pk_announced_arrival.set_ann_arrival(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_announced_arrival   => r_ann_arriv.id_announced_arrival,
                                                             i_name                => r_ann_arriv.name,
                                                             i_gender              => r_ann_arriv.gender,
                                                             i_dt_birth            => r_ann_arriv.dt_birth,
                                                             i_age                 => r_ann_arriv.age,
                                                             i_address             => r_ann_arriv.address,
                                                             i_city                => r_ann_arriv.city,
                                                             i_pat_zip_code        => r_ann_arriv.zip_code,
                                                             i_dt_accident         => r_ann_arriv.dt_accident,
                                                             i_type_injury         => r_ann_arriv.type_injury,
                                                             i_condition           => r_ann_arriv.condition,
                                                             i_acc_zip_code        => r_ann_arriv.acc_zip_code,
                                                             i_latitude            => r_ann_arriv.latitude,
                                                             i_longitude           => r_ann_arriv.longitude,
                                                             i_referred_by         => r_ann_arriv.referred_by,
                                                             i_speciality          => r_ann_arriv.id_speciality,
                                                             i_clinical_service    => r_ann_arriv.id_clinical_service,
                                                             i_ed_physician        => r_ann_arriv.id_ed_physician,
                                                             i_dt_expected_arrival => r_ann_arriv.dt_expected_arrival,
                                                             i_dt_report_mka       => r_ann_arriv.dt_report_mka,
                                                             i_cpa_code            => r_ann_arriv.cpa_code,
                                                             i_transport_number    => r_ann_arriv.transport_number,
                                                             i_dt_ride_out         => r_ann_arriv.dt_ride_out,
                                                             i_dt_arrival          => r_ann_arriv.dt_arrival,
                                                             i_flg_mech_inj        => r_ann_arriv.flg_mech_inj,
                                                             i_mech_injury         => r_ann_arriv.mech_injury_ft,
                                                             i_vs_id               => l_vs_ids,
                                                             i_vs_val              => l_vs_values,
                                                             i_unit_meas           => l_vs_unit_meas,
                                                             i_dt_drv_away         => r_ann_arriv.dt_drv_away,
                                                             i_flg_prot_device     => r_ann_arriv.flg_prot_device,
                                                             i_flg_rta_pat_typ     => r_ann_arriv.flg_rta_pat_typ,
                                                             i_rta_pat_typ_ft      => r_ann_arriv.rta_pat_typ_ft,
                                                             i_flg_is_driv_own     => r_ann_arriv.flg_is_driv_own,
                                                             i_flg_police_involved => r_ann_arriv.flg_police_involved,
                                                             i_police_num          => r_ann_arriv.police_num,
                                                             i_police_station      => r_ann_arriv.police_station,
                                                             i_police_accident_num => r_ann_arriv.police_accident_num,
                                                             i_id_amb_trust_code   => r_ann_arriv.id_amb_trust_code,
                                                             i_ambulance_trust     => r_ann_arriv.ambulance_trust,
                                                             o_error               => o_error))
                THEN
                    RAISE e_call_error;
                END IF;
            
                o_announced_arrival := r_ann_arriv.id_announced_arrival;
            ELSIF i_patient IS NOT NULL
            THEN
                IF NOT create_ann_arrival_int(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_name                => r_ann_arriv.name,
                                              i_gender              => r_ann_arriv.gender,
                                              i_dt_birth            => r_ann_arriv.dt_birth,
                                              i_age                 => r_ann_arriv.age,
                                              i_address             => r_ann_arriv.address,
                                              i_city                => r_ann_arriv.city,
                                              i_pat_zip_code        => r_ann_arriv.zip_code,
                                              i_dt_accident         => r_ann_arriv.dt_accident,
                                              i_type_injury         => r_ann_arriv.type_injury,
                                              i_condition           => r_ann_arriv.condition,
                                              i_acc_zip_code        => r_ann_arriv.acc_zip_code,
                                              i_latitude            => r_ann_arriv.latitude,
                                              i_longitude           => r_ann_arriv.longitude,
                                              i_referred_by         => r_ann_arriv.referred_by,
                                              i_speciality          => r_ann_arriv.id_speciality,
                                              i_clinical_service    => r_ann_arriv.id_clinical_service,
                                              i_ed_physician        => r_ann_arriv.id_ed_physician,
                                              i_dt_expected_arrival => r_ann_arriv.dt_expected_arrival,
                                              i_dt_report_mka       => r_ann_arriv.dt_report_mka,
                                              i_cpa_code            => r_ann_arriv.cpa_code,
                                              i_transport_number    => r_ann_arriv.transport_number,
                                              i_dt_ride_out         => r_ann_arriv.dt_ride_out,
                                              i_dt_arrival          => r_ann_arriv.dt_arrival,
                                              i_flg_mech_inj        => r_ann_arriv.flg_mech_inj,
                                              i_mech_injury         => r_ann_arriv.mech_injury_ft,
                                              i_vs_id               => l_vs_ids,
                                              i_vs_val              => l_vs_values,
                                              i_unit_meas           => l_vs_unit_meas,
                                              i_dt_drv_away         => r_ann_arriv.dt_drv_away,
                                              i_flg_prot_device     => r_ann_arriv.flg_prot_device,
                                              i_flg_rta_pat_typ     => r_ann_arriv.flg_rta_pat_typ,
                                              i_rta_pat_typ_ft      => r_ann_arriv.rta_pat_typ_ft,
                                              i_flg_is_driv_own     => r_ann_arriv.flg_is_driv_own,
                                              i_flg_police_involved => r_ann_arriv.flg_police_involved,
                                              i_police_num          => r_ann_arriv.police_num,
                                              i_police_station      => r_ann_arriv.police_station,
                                              i_police_accident_num => r_ann_arriv.police_accident_num,
                                              i_id_amb_trust_code   => r_ann_arriv.id_amb_trust_code,
                                              i_ambulance_trust     => r_ann_arriv.ambulance_trust,
                                              i_patient             => i_patient,
                                              i_episode             => NULL,
                                              o_announced_arrival   => o_announced_arrival,
                                              o_error               => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            ELSIF r_ann_arriv.id_episode IS NOT NULL
            THEN
                IF NOT create_ann_arrival_int(i_lang                => i_lang,
                                              i_prof                => i_prof,
                                              i_name                => r_ann_arriv.name,
                                              i_gender              => r_ann_arriv.gender,
                                              i_dt_birth            => r_ann_arriv.dt_birth,
                                              i_age                 => r_ann_arriv.age,
                                              i_address             => r_ann_arriv.address,
                                              i_city                => r_ann_arriv.city,
                                              i_pat_zip_code        => r_ann_arriv.zip_code,
                                              i_dt_accident         => r_ann_arriv.dt_accident,
                                              i_type_injury         => r_ann_arriv.type_injury,
                                              i_condition           => r_ann_arriv.condition,
                                              i_acc_zip_code        => r_ann_arriv.acc_zip_code,
                                              i_latitude            => r_ann_arriv.latitude,
                                              i_longitude           => r_ann_arriv.longitude,
                                              i_referred_by         => r_ann_arriv.referred_by,
                                              i_speciality          => r_ann_arriv.id_speciality,
                                              i_clinical_service    => r_ann_arriv.id_clinical_service,
                                              i_ed_physician        => r_ann_arriv.id_ed_physician,
                                              i_dt_expected_arrival => r_ann_arriv.dt_expected_arrival,
                                              i_dt_report_mka       => r_ann_arriv.dt_report_mka,
                                              i_cpa_code            => r_ann_arriv.cpa_code,
                                              i_transport_number    => r_ann_arriv.transport_number,
                                              i_dt_ride_out         => r_ann_arriv.dt_ride_out,
                                              i_dt_arrival          => r_ann_arriv.dt_arrival,
                                              i_flg_mech_inj        => r_ann_arriv.flg_mech_inj,
                                              i_mech_injury         => r_ann_arriv.mech_injury_ft,
                                              i_vs_id               => l_vs_ids,
                                              i_vs_val              => l_vs_values,
                                              i_unit_meas           => l_vs_unit_meas,
                                              i_dt_drv_away         => r_ann_arriv.dt_drv_away,
                                              i_flg_prot_device     => r_ann_arriv.flg_prot_device,
                                              i_flg_rta_pat_typ     => r_ann_arriv.flg_rta_pat_typ,
                                              i_rta_pat_typ_ft      => r_ann_arriv.rta_pat_typ_ft,
                                              i_flg_is_driv_own     => r_ann_arriv.flg_is_driv_own,
                                              i_flg_police_involved => r_ann_arriv.flg_police_involved,
                                              i_police_num          => r_ann_arriv.police_num,
                                              i_police_station      => r_ann_arriv.police_station,
                                              i_police_accident_num => r_ann_arriv.police_accident_num,
                                              i_id_amb_trust_code   => r_ann_arriv.id_amb_trust_code,
                                              i_ambulance_trust     => r_ann_arriv.ambulance_trust,
                                              i_patient             => NULL,
                                              i_episode             => r_ann_arriv.id_episode,
                                              o_announced_arrival   => o_announced_arrival,
                                              o_error               => o_error)
                THEN
                    RAISE e_call_error;
                END IF;
            END IF;
        END LOOP;
    
        g_error := 'SET NLS_NUMERIC_CHARACTERS';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        EXECUTE IMMEDIATE 'ALTER SESSION SET ' || l_nls_num_char || ' = ''' || l_back_nls || '''';
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_announced_arrival;

    /**
    * Encapsulates the logic of saving (create or update) a announced arrival patient
    * (CALLED BY: FLASH)
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_params                XML with all input parameters
    * @param   o_announced_arrival     Announced arrival id 
    * @param   o_error                 Error information
    *
    * @example i_params                Example of the possible XML passed in this variable
    * <ANNOUNCED_ARRIVAL ID_ANNOUNCED_ARRIVAL="" ID_EPISODE="">
    *   <!-- ID_EPISODE -> Only put this arg to substitute the old call to CREATE_ANN_ARRIVAL_BY_EPI - Creation in pre-hospital screen inside patient area -->
    *   <!-- ID_ANNOUNCED_ARRIVAL -> Only used when editing a existing recorded (Instead of calls to SET_ANN_ARRIVAL and SET_ANN_ARRIVAL_PRE_HOSP) -->
    *   <PATIENT NAME="" GENDER="" DT_BIRTH="" AGE="" ADDRESS="" CITY="" ZIP_CODE="" />
    *   <INCIDENT DT_ACCIDENT="" TYPE_INJURY="" CONDITION="" ZIP_CODE="" LATITUDE="" LONGITUDE="" />
    *   <REFERRAL_ARRIV REFERRED_BY="" SPECIALITY="" CLINICAL_SERVICE="" ED_PHYSICIAN="" DT_EXPECTED_ARRIVAL="" />
    *   <ACT_EMERG_SERV DT_REPORT_MKA="" CPA_CODE="" TRANSPORT_NUMBER="" DT_RIDE_OUT="" DT_ARRIVAL="" />
    *   <TRIAGE FLG_MECH_INJ="" MECH_INJURY_FT="" >
    *     <VITAL_SIGNS>
    *       <VITAL_SIGN ID="" VAL="" UNIT_MEAS="" />
    *     </VITAL_SIGNS>
    *   </TRIAGE>
    *   <TRANSFER_HOSP DT_DRV_AWAY="" />
    *   <RTC FLG_PROT_DEVICE="" FLG_RTA_PAT_TYPE="" RTA_PAT_TYPE_FT="" FLG_IS_DRIV_OWN="" FLG_POLICE_INVOLVED="" POLICE_NUM="" POLICE_STATION="" POLICE_ACCIDENT_NUM="" />
    * </ANNOUNCED_ARRIVAL>
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    FUNCTION set_announced_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_params            IN CLOB,
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ANNOUNCED_ARRIVAL';
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL PK_ANNOUNCED_ARRIVAL.SET_ANNOUNCED_ARRIVAL';
        pk_alertlog.log_debug(object_name => g_pck_name, sub_object_name => l_func_name, text => g_error);
        IF NOT pk_announced_arrival.set_announced_arrival(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_patient           => NULL,
                                                          i_params            => i_params,
                                                          o_announced_arrival => o_announced_arrival,
                                                          o_error             => o_error)
        THEN
            RAISE l_exception;
        END IF;
    
        COMMIT;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_announced_arrival;

    /**
    * Validates if section can be hidden
    *
    * @param   i_pre_hosp_form         Form id
    * @param   i_pre_hosp_step         Step id
    * @param   i_pre_hosp_section      Section id
    * @param   i_market                Market id 
    * @param   i_institution           Institution id
    * @param   i_flg_visible           Visibility value
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    PROCEDURE is_trg_ph_step_sect_val
    (
        i_pre_hosp_form    IN pre_hosp_step_sections.id_pre_hosp_form%TYPE,
        i_pre_hosp_step    IN pre_hosp_step_sections.id_pre_hosp_step%TYPE,
        i_pre_hosp_section IN pre_hosp_step_sections.id_pre_hosp_section%TYPE,
        i_market           IN pre_hosp_step_sections.id_market%TYPE,
        i_institution      IN pre_hosp_step_sections.id_institution%TYPE,
        i_flg_visible      IN pre_hosp_step_sections.flg_visible%TYPE
    ) IS
        l_count PLS_INTEGER;
    BEGIN
        IF i_flg_visible = pk_alert_constant.g_no
        THEN
            SELECT COUNT(*)
              INTO l_count
              FROM pre_hosp_section_fields p
              JOIN pre_hosp_field f
                ON f.id_pre_hosp_field = p.id_pre_hosp_field
             WHERE p.id_pre_hosp_form = i_pre_hosp_form
               AND p.id_pre_hosp_step = i_pre_hosp_step
               AND p.id_pre_hosp_section = i_pre_hosp_section
               AND p.id_market = i_market
               AND p.id_institution = i_institution
               AND nvl(f.flg_mandatory, p.flg_mandatory) = pk_alert_constant.g_yes;
        
            IF l_count > 0
            THEN
                raise_application_error(-20001,
                                        'Section with ID: ' || i_pre_hosp_section ||
                                        ' has one or more mandatory fields so it cannot be hidden.');
            END IF;
        END IF;
    END is_trg_ph_step_sect_val;

    /**
    * Validates if field can be hidden
    *
    * @param   i_pre_hosp_field        Field id
    * @param   i_flg_visible           Visibility value
    * @param   i_flg_mandatory         Mandatory
    *
    * @author  Alexandre Santos
    * @version v2.6.1.2
    * @since   01-08-2011
    */
    PROCEDURE is_trg_ph_sect_flds_val
    (
        i_pre_hosp_field IN pre_hosp_section_fields.id_pre_hosp_field%TYPE,
        i_flg_visible    IN pre_hosp_section_fields.flg_visible%TYPE,
        i_flg_mandatory  IN pre_hosp_section_fields.flg_mandatory%TYPE
    ) IS
        l_flg_visible   pre_hosp_field.flg_visible%TYPE;
        l_flg_mandatory pre_hosp_field.flg_mandatory%TYPE;
    BEGIN
        IF i_flg_visible = pk_alert_constant.g_no
        THEN
            SELECT nvl(f.flg_visible, i_flg_visible), nvl(f.flg_mandatory, i_flg_mandatory)
              INTO l_flg_visible, l_flg_mandatory
              FROM pre_hosp_field f
             WHERE f.id_pre_hosp_field = i_pre_hosp_field;
        
            IF l_flg_visible = pk_alert_constant.g_yes
            THEN
                raise_application_error(-20001, 'Field with ID: ' || i_pre_hosp_field || ' must be visible.');
            END IF;
        
            IF l_flg_mandatory = pk_alert_constant.g_yes
            THEN
                raise_application_error(-20001,
                                        'Field with ID: ' || i_pre_hosp_field ||
                                        ' is a mandatory field so it must be visible.');
            END IF;
        END IF;
    END is_trg_ph_sect_flds_val;

    /********************************************************************************************
    * Is print button active? 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_flg_print              tells if print button is available                                              
    * @param o_error                  Error object                                              
    *                                                    
    * @value   o_flg_print         Y - Is active                                            
    *                              N - Is disabled
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos 
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION is_print_button_act
    (
        i_lang      IN sys_domain.id_language%TYPE,
        i_prof      IN profissional,
        o_flg_print OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'IS_PRINT_BUTTON_ACT';
        --
        l_desc_form sys_message.desc_message%TYPE;
        c_steps     pk_edis_types.cursor_step;
        c_sections  pk_edis_types.cursor_section;
        c_fields    pk_edis_types.cursor_field;
        c_vs        pk_vital_sign.t_cur_vs_header;
        --
        l_tbl_fields pk_edis_types.table_field;
        --
        l_error t_error_out;
        --
        l_exception EXCEPTION;
    BEGIN
        g_error := 'CALL GET_FORM_INT';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT get_form_int(i_lang          => i_lang,
                            i_prof          => i_prof,
                            i_form_int_name => g_frm_report,
                            o_desc_form     => l_desc_form,
                            o_steps         => c_steps,
                            o_sections      => c_sections,
                            o_fields        => c_fields,
                            o_vital_signs   => c_vs,
                            o_error         => l_error)
        THEN
            RAISE l_exception;
        END IF;
    
        g_error := 'FILL O_TBL_FIELDS';
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        FETCH c_fields BULK COLLECT
            INTO l_tbl_fields;
        CLOSE c_fields;
    
        IF l_tbl_fields.count > 0
        THEN
            o_flg_print := pk_alert_constant.g_yes;
        ELSE
            o_flg_print := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN l_exception THEN
            --RTC is not configured so print button must be disabled
            o_flg_print := pk_alert_constant.g_no;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END is_print_button_act;

    /********************************************************************************************
    * Validates if episode has pre-hospital data filled 
    * USED BY: Reports team
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                professional, software and institution ids             
    * @param o_flg_has_data           tells if pre-hospital data is filled                                              
    * @param o_announced_arrival      Announced arrival id                                           
    * @param o_error                  Error object                                              
    *                                                    
    * @value   o_flg_has_data      Y - Has pre-hospital data                                            
    *                              N - Doesn't have pre-hospital data
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Alexandre Santos 
    * @version 2.6.2
    * @since   01-08-2011
    **********************************************************************************************/
    FUNCTION is_pre_hosp_data_filled
    (
        i_lang              IN sys_domain.id_language%TYPE,
        i_prof              IN profissional,
        i_episode           IN announced_arrival.id_episode%TYPE,
        o_flg_has_data      OUT VARCHAR2,
        o_announced_arrival OUT announced_arrival.id_announced_arrival%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'IS_PRE_HOSP_DATA_FILLED';
        --
        l_zero CONSTANT PLS_INTEGER := 0;
    BEGIN
        g_error := 'GET ANN_ARRIV DATA FOR ID_EPISODE: ' || i_episode;
        pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        SELECT aa.id_announced_arrival
          INTO o_announced_arrival
          FROM announced_arrival aa
         WHERE aa.id_episode = i_episode;
    
        IF o_announced_arrival IS NOT NULL
        THEN
            o_flg_has_data := pk_alert_constant.g_yes;
        ELSE
            o_flg_has_data := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            --Current episode hasn't pre-hospital data
            o_flg_has_data := pk_alert_constant.g_no;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            o_flg_has_data := NULL;
            pk_utils.undo_changes;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END is_pre_hosp_data_filled;

    /********************************************************************************************
    * Verify if an action is active/ inactive
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    *                                                                                                
    * @return  A (Active)/I(Inactive)
    * 
    * @author  Elisabete Bugalho 
    * @version 2.6.3
    * @since   22-07-2013
    **********************************************************************************************/
    FUNCTION get_action_status
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_action     IN action.internal_name%TYPE,
        i_from_state IN action.from_state%TYPE,
        i_status     IN announced_arrival.flg_status%TYPE,
        i_contact    IN patient.flg_origin%TYPE,
        i_external   IN VARCHAR2,
        i_episode    IN episode.id_episode%TYPE,
        i_confirm    IN VARCHAR2
    ) RETURN VARCHAR2 IS
    
    BEGIN
        IF i_status = g_aa_arrival_status_e
           AND i_contact = pk_alert_constant.g_yes
           AND i_action = g_aa_action_associate
        THEN
            RETURN pk_alert_constant.g_active;
        ELSIF i_status = g_aa_arrival_status_e
              AND i_action = g_aa_action_cancel_aa
        THEN
            RETURN pk_alert_constant.g_active;
        ELSIF i_status = g_aa_arrival_status_e
              AND i_external = pk_alert_constant.g_no
              AND i_action = g_aa_action_arrival_adt
              AND i_contact = pk_alert_constant.g_no
        THEN
            RETURN pk_alert_constant.g_active;
        ELSIF i_status = g_aa_arrival_status_e
              AND i_external = pk_alert_constant.g_yes
              AND i_action = g_aa_action_arrival
              AND (i_contact = pk_alert_constant.g_no OR
              (i_contact = pk_alert_constant.g_yes AND i_confirm = pk_alert_constant.g_yes))
        THEN
            RETURN pk_alert_constant.g_active;
        ELSIF i_status IN (g_aa_arrival_status_a, g_aa_arrival_status_e)
              AND i_action = g_aa_action_edit
        THEN
            RETURN pk_alert_constant.g_active;
        ELSIF i_status = g_aa_arrival_status_a
              AND i_action = g_aa_action_cancel_conf
        THEN
            IF pk_visit.check_flg_cancel(i_lang, i_prof, i_episode) = pk_alert_constant.get_yes
            THEN
                RETURN pk_alert_constant.g_active;
            ELSE
                RETURN pk_alert_constant.g_inactive;
            END IF;
        ELSE
            RETURN pk_alert_constant.g_inactive;
        END IF;
    END get_action_status;

    /********************************************************************************************
    * Gets the available actions for a announced arrival
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param o_announced_arrival      Announced arrival id                                           
    * @param o_error                  Error object                                              
    *                                                    
    * @value   o_actions              Cursor with available actions                                            
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Elisabete Bugalho 
    * @version 2.6.3
    * @since   22-07-2013
    **********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        o_actions           OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_ACTIONS';
        l_subject         action.subject%TYPE := 'ANNOUNCED_ARRIVAL';
        l_contact         patient.flg_origin%TYPE;
        l_status          announced_arrival.flg_status%TYPE;
        l_patient         announced_arrival.id_patient%TYPE;
        l_external_adt    sys_config.value%TYPE;
        l_confirm_patient sys_config.value%TYPE;
        l_id_episode      episode.id_episode%TYPE;
    BEGIN
    
        SELECT aa.flg_status, id_patient, id_episode
          INTO l_status, l_patient, l_id_episode
          FROM announced_arrival aa
         WHERE aa.id_announced_arrival = i_announced_arrival;
    
        l_contact         := pk_adt.is_contact(i_lang, i_prof, l_patient);
        l_external_adt    := pk_sysconfig.get_config(i_code_cf => 'EXTERNAL_SYSTEM_EXIST', i_prof => i_prof);
        l_confirm_patient := pk_sysconfig.get_config(i_code_cf => 'ANN_ARRIV_CONFIRM_CONTACT', i_prof => i_prof);
        OPEN o_actions FOR
            SELECT /*+opt_estimate(table,act,scale_rows=0.0001)*/
             act.id_action,
             act.id_parent,
             act.level_nr AS "LEVEL", --used to manage the shown' items by Flash
             act.from_state,
             act.to_state, --destination state flag
             act.desc_action, --action's description
             act.icon, --action's icon
             act.flg_default, --default action
             get_action_status(i_lang,
                               i_prof,
                               act.action,
                               from_state,
                               l_status,
                               l_contact,
                               l_external_adt,
                               l_id_episode,
                               l_confirm_patient) flg_active, --action's state
             act.action
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, l_subject, NULL)) act
             WHERE (l_external_adt = pk_alert_constant.g_yes AND action <> g_aa_action_arrival_adt)
                OR (l_external_adt = pk_alert_constant.g_no AND action <> g_aa_action_arrival);
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions;
    /****************
    ****************************************************************************
    * Set the associated patient 
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids   
    * @param i_patient_old            Contact patient 
    * @param i_patient_new            Patient id
    *                                                                                                
    * @return  true or False
    * 
    * @author  Elisabete Bugalho 
    * @version 2.6.3
    * @since   22-07-2013
    **********************************************************************************************/
    FUNCTION set_announced_arrival_pat
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient_old IN patient.id_patient%TYPE,
        i_patient_new IN patient.id_patient%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'SET_ANNOUNCED_ARRIVAL_PAT';
        l_rows              table_varchar;
        l_announced_arrival announced_arrival.id_announced_arrival%TYPE;
        l_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_pre_hosp_acc_hist pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_ann_arr_hist      announced_arrival_hist.id_announced_arrival_hist%TYPE;
    BEGIN
    
        g_error := 'VERIFY ID_ANN_ARRIVAL AND ID_PRE_HOSP_ACCIDENT';
        BEGIN
            SELECT aa.id_announced_arrival, id_pre_hosp_accident
              INTO l_announced_arrival, l_pre_hosp_accident
              FROM announced_arrival aa
             WHERE aa.id_patient = i_patient_old
               AND aa.flg_status = g_aa_arrival_status_e;
        
        EXCEPTION
            WHEN OTHERS THEN
                RETURN TRUE;
        END;
    
        g_error := 'INS ANN ARR HIST';
        IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                      i_announced_arrival      => l_announced_arrival,
                                                      i_flg_commit             => FALSE,
                                                      o_announced_arrival_hist => l_ann_arr_hist,
                                                      o_pre_hosp_accident      => l_pre_hosp_acc_hist,
                                                      o_error                  => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'UPD ANNOUNCED_ARRIVAL';
        ts_announced_arrival.upd(id_announced_arrival_in => l_announced_arrival,
                                 id_pre_hosp_accident_in => l_pre_hosp_accident,
                                 id_patient_in           => i_patient_new,
                                 rows_out                => l_rows);
    
        g_error := 'PROCESS_UPDATE ANN_ARRIV';
        t_data_gov_mnt.process_update(i_lang       => i_lang,
                                      i_prof       => i_prof,
                                      i_table_name => 'ANNOUNCED_ARRIVAL',
                                      i_rowids     => l_rows,
                                      o_error      => o_error);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
        
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        
    END set_announced_arrival_pat;

    FUNCTION get_pat_address
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2 IS
    
        l_address contact_address.address_line1%TYPE;
        l_dummy   VARCHAR2(200 CHAR);
        l_error   t_error_out;
    BEGIN
        IF NOT pk_adt.get_contact_info(i_lang     => i_lang,
                                       i_prof     => i_prof,
                                       i_patient  => i_patient,
                                       o_address  => l_address,
                                       o_location => l_dummy,
                                       o_regional => l_dummy,
                                       o_phone1   => l_dummy,
                                       o_phone2   => l_dummy,
                                       o_error    => l_error)
        THEN
            RETURN NULL;
        END IF;
        RETURN l_address;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pat_address;

    /********************************************************************************************
    * Returns a cursor of sys_list elements
    *                                                                                                 
    * @param i_lang                   Language ID                                                     
    * @param i_prof                   Profissional ID                                                     
    * @param i_internal_name          Group internal name      
    * @param o_data                   Output cursor                                              
    * @param o_error                  Error object                                              
    *                                                    
    *                                                                                                
    * @return  true or false on success or error
    * 
    * @author  Elisabete Bugalho
    * @version 2.6.3.8.5
    * @since   19-11-2013
    **********************************************************************************************/
    FUNCTION get_ambulance_values
    (
        i_lang          IN sys_domain.id_language%TYPE,
        i_prof          IN profissional,
        i_internal_name IN sys_list_group.internal_name%TYPE,
        o_data          OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_AMBULANCE_VALUES';
        l_external_excpt EXCEPTION;
    BEGIN
        IF NOT pk_sys_list.get_sys_list_values(i_lang          => i_lang,
                                               i_prof          => i_prof,
                                               i_internal_name => i_internal_name,
                                               o_sql           => o_data,
                                               o_error         => o_error)
        THEN
            RAISE l_external_excpt;
        END IF;
        RETURN TRUE;
    EXCEPTION
        WHEN l_external_excpt THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

BEGIN
    g_sysdate_tstz := current_timestamp;

    pk_alertlog.who_am_i(g_pck_owner, g_pck_name);
    pk_alertlog.log_init(g_pck_name);
END pk_announced_arrival;
/
