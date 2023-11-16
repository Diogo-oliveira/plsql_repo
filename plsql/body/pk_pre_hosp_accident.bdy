/*-- Last Change Revision: $Rev: 2027505 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:42:26 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_pre_hosp_accident IS
    -- Private constants 
    g_pre_hosp_status_a CONSTANT VARCHAR2(1) := 'A';
    g_pre_hosp_status_i CONSTANT VARCHAR2(1) := 'I';
    g_pre_hosp_status_c CONSTANT VARCHAR2(1) := 'C';

    g_pre_hosp_vs_read_status_a CONSTANT VARCHAR2(1) := 'A';
    g_pre_hosp_vs_read_status_i CONSTANT VARCHAR2(1) := 'I';

    g_new_line CONSTANT CHAR(1) := chr(13);

    g_debug_log_level CONSTANT NUMBER := 60;

    -- Private variables
    g_pck_name  VARCHAR2(32) := 'PK_PRE_HOSP_ACCIDENT';
    g_pck_owner VARCHAR2(32) := 'ALERT';
    g_is_to_log BOOLEAN := FALSE;

    g_error        VARCHAR2(4000);
    g_log          VARCHAR2(4000);
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
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_date: ' || to_char(i_date, 'YYYY-MM-DD HH24:MI:SS');
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'SET TIME';
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
    * Create new record with accident data
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
    * @param i_flg_mech_inj           flag mechanism of injury
    * @param i_mech_injury            information about mechanism of injury
    * @param i_dt_drv_away            moment of driving away with the patient
    * @param i_episode                episode id or -1 if doesn't exists
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_pre_hosp_accident      id_pre_hosp_accident of the new record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION create_pre_hosp_acc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN alert.profissional,
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
        i_flg_commit          IN BOOLEAN DEFAULT FALSE,
        o_pre_hosp_accident   OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CREATE_PRE_HOSP_ACC';
        l_rows      table_varchar;
        l_id_software NUMBER;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_dt_accident: ' || i_dt_accident || g_new_line || --
                     '- i_name: ' || i_name || g_new_line || --
                     '- i_gender: ' || i_gender || g_new_line || --
                     '- i_dt_birth: ' || i_dt_birth || g_new_line || --
                     '- i_age: ' || to_char(i_age) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode) || g_new_line;
        
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || '- i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'INSERT PRE_HOSP_ACCIDENT';
        l_id_software := i_prof.software;
        IF i_prof.software = 39
        THEN
            l_id_software := 8;
        END IF;
        ts_pre_hosp_accident.ins(id_institution_in       => i_prof.institution,
                                 id_software_in          => l_id_software,
                                 dt_accident_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_accident,
                                                                                          NULL),
                                 dt_report_mka_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_report_mka,
                                                                                          NULL),
                                 cpa_code_in             => i_cpa_code,
                                 transport_number_in     => i_transport_number,
                                 acc_zip_code_in         => i_acc_zip_code,
                                 latitude_in             => i_latitude,
                                 longitude_in            => i_longitude,
                                 dt_ride_out_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_ride_out,
                                                                                          NULL),
                                 dt_arrival_in           => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_arrival,
                                                                                          NULL),
                                 flg_mech_inj_in         => i_flg_mech_inj,
                                 mech_injury_in          => i_mech_injury,
                                 dt_drv_away_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_drv_away,
                                                                                          NULL),
                                 flg_status_in           => g_pre_hosp_status_a,
                                 id_prof_create_in       => i_prof.id,
                                 dt_pre_hosp_accident_in => g_sysdate_tstz,
                                 id_episode_in           => i_episode,
                                 flg_prot_device_in      => i_flg_prot_device,
                                 flg_rta_pat_typ_in      => i_flg_rta_pat_typ,
                                 rta_pat_typ_ft_in       => i_rta_pat_typ_ft,
                                 flg_is_driv_own_in      => i_flg_is_driv_own,
                                 flg_police_involved_in  => i_flg_police_involved,
                                 police_num_in           => i_police_num,
                                 police_station_in       => i_police_station,
                                 police_accident_num_in  => i_police_accident_num,
                                 id_amb_trust_code_in    => i_id_amb_trust_code,
                                 --  ambulance_trust_in => i_ambulance_trust,
                                 rows_out => l_rows);
    
        g_error := 'VALIDATE INSERTED ROW';
        IF (l_rows.count != 1)
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        ELSE
            SELECT pha.id_pre_hosp_accident
              INTO o_pre_hosp_accident
              FROM pre_hosp_accident pha
             WHERE ROWID = l_rows(1);
        END IF;
    
        pk_translation.insert_translation_trs(i_lang   => i_lang,
                                              i_code   => g_code_ambulance || o_pre_hosp_accident,
                                              i_desc   => i_ambulance_trust,
                                              i_module => g_module);
        g_error := 'INSERT VS READ';
        IF NOT (create_vs_read(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_pre_hosp_accident => o_pre_hosp_accident,
                               i_episode           => i_episode,
                               i_vs_id             => i_vs_id,
                               i_vs_val            => i_vs_val,
                               i_unit_meas         => i_unit_meas,
                               o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
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
    END create_pre_hosp_acc;
    --
    /**********************************************************************************************
    * Invalidate the i_pre_hosp_accident and creates a new pre_hosp_accident returning the new key
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident of the record to invalidate
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
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_pre_hosp_accident      id_pre_hosp_accident of the created record
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION set_pre_hosp_acc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN alert.profissional,
        i_pre_hosp_accident   IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
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
        
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_pre_hosp_accident OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'SET_PRE_HOSP_ACC';
        l_flg_status pre_hosp_accident.flg_status%TYPE;
        l_code_msg   sys_message.code_message%TYPE;
        l_error_msg  sys_message.desc_message%TYPE;
    BEGIN
        g_error := 'GET RECORD STATUS';
        SELECT flg_status
          INTO l_flg_status
          FROM pre_hosp_accident pha
         WHERE pha.id_pre_hosp_accident = i_pre_hosp_accident;
    
        g_error := 'VALIDATE STATUS';
        IF l_flg_status != g_pre_hosp_status_a
        THEN
            l_code_msg  := 'ANN_ARRIV_MSG065';
            l_error_msg := pk_message.get_message(i_lang, i_prof, i_code_mess => l_code_msg);
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || g_new_line || l_error_msg);
            RAISE g_usr_info_error;
        END IF;
    
        g_error := 'INVALIDATE PRE_HOSP_ACCIDENT';
        ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => i_pre_hosp_accident,
                                 flg_status_in           => g_pre_hosp_status_i,
                                 dt_pre_hosp_accident_in => g_sysdate_tstz);
    
        g_error := 'CANCEL PRE_HOSP_VS_READ';
        IF NOT (cancel_vs_read(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_pre_hosp_accident => i_pre_hosp_accident,
                               o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
        g_error := 'INS NEW PRE_HOSP_ACCIDENT';
        IF NOT (pk_pre_hosp_accident.create_pre_hosp_acc(i_lang => i_lang,
                                                         
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
                                                         i_episode             => i_episode,
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
                                                         
                                                         i_flg_commit        => FALSE,
                                                         o_pre_hosp_accident => o_pre_hosp_accident,
                                                         o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_usr_info_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_code_msg,
                                              l_error_msg,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_utils.undo_changes;
            RAISE g_usr_info_error;
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
    END set_pre_hosp_acc;
    --
    /**********************************************************************************************
    * Updates accident data
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident of the record to update
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
    * @param i_flg_prot_device        Protection device in situ: BS - Baby seat; CR - Child restraint; H - Helmet; SB - Seat belt; N - None; U - Unknown    
    * @param i_flg_rta_pat_typ        RTA patient type: D - Driver; P - Passenger; C - Cyclist; PD - Pedestrian; O - Other    
    * @param i_rta_pat_typ_ft         Free text of FLG_RTA_PAT_TYP = O     
    * @param i_flg_is_driv_own        Is the driver the owner? Y - Yes; N - No    
    * @param i_flg_police_involved    Police involved? Y - Yes; N - No
    * @param i_police_num             Police ID
    * @param i_police_station         Police station
    * @param i_police_accident_num    Police accident number
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION set_pre_hosp_acc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN alert.profissional,
        i_pre_hosp_accident   IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
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
        i_flg_commit          IN BOOLEAN DEFAULT FALSE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name  VARCHAR2(30) := 'SET_PRE_HOSP_ACC';
        l_flg_status pre_hosp_accident.flg_status%TYPE;
        l_code_msg   sys_message.code_message%TYPE;
        l_error_msg  sys_message.desc_message%TYPE;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_dt_accident: ' || i_dt_accident || g_new_line || --
                     '- i_dt_arrival: ' || i_dt_arrival || g_new_line || --
                     '- i_name: ' || i_name || g_new_line || --
                     '- i_gender: ' || i_gender || g_new_line || --
                     '- i_dt_birth: ' || i_dt_birth || g_new_line || --
                     '- i_age: ' || to_char(i_age) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode) || g_new_line;
        
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || '- i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'GET RECORD STATUS';
        SELECT flg_status
          INTO l_flg_status
          FROM pre_hosp_accident pha
         WHERE pha.id_pre_hosp_accident = i_pre_hosp_accident;
    
        g_error := 'VALIDATE STATUS';
        IF l_flg_status != g_pre_hosp_status_a
        THEN
            l_code_msg  := 'ANN_ARRIV_MSG065';
            l_error_msg := pk_message.get_message(i_lang, i_prof, i_code_mess => l_code_msg);
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || g_new_line || l_error_msg);
            RAISE g_usr_info_error;
        END IF;
    
        g_error := 'UPDATE PRE_HOSP_ACCIDENT';
        ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => i_pre_hosp_accident,
                                 dt_accident_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_accident,
                                                                                          NULL),
                                 dt_accident_nin         => FALSE,
                                 dt_report_mka_in        => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_report_mka,
                                                                                          NULL),
                                 dt_report_mka_nin       => FALSE,
                                 cpa_code_in             => i_cpa_code,
                                 cpa_code_nin            => FALSE,
                                 transport_number_in     => i_transport_number,
                                 transport_number_nin    => FALSE,
                                 acc_zip_code_in         => i_acc_zip_code,
                                 acc_zip_code_nin        => FALSE,
                                 latitude_in             => i_latitude,
                                 latitude_nin            => FALSE,
                                 longitude_in            => i_longitude,
                                 longitude_nin           => FALSE,
                                 dt_ride_out_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_ride_out,
                                                                                          NULL),
                                 dt_ride_out_nin         => FALSE,
                                 dt_arrival_in           => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_arrival,
                                                                                          NULL),
                                 dt_arrival_nin          => FALSE,
                                 flg_mech_inj_in         => i_flg_mech_inj,
                                 flg_mech_inj_nin        => FALSE,
                                 mech_injury_in          => i_mech_injury,
                                 mech_injury_nin         => FALSE,
                                 dt_drv_away_in          => pk_date_utils.get_string_tstz(i_lang,
                                                                                          i_prof,
                                                                                          i_dt_drv_away,
                                                                                          NULL),
                                 dt_drv_away_nin         => FALSE,
                                 id_prof_create_in       => i_prof.id,
                                 dt_pre_hosp_accident_in => g_sysdate_tstz,
                                 id_episode_in           => i_episode,
                                 flg_prot_device_in      => i_flg_prot_device,
                                 flg_rta_pat_typ_in      => i_flg_rta_pat_typ,
                                 rta_pat_typ_ft_in       => i_rta_pat_typ_ft,
                                 flg_is_driv_own_in      => i_flg_is_driv_own,
                                 flg_police_involved_in  => i_flg_police_involved,
                                 police_num_in           => i_police_num,
                                 police_station_in       => i_police_station,
                                 police_accident_num_in  => i_police_accident_num,
                                 id_amb_trust_code_in    => i_id_amb_trust_code
                                 --    ambulance_trust_in=> i_ambulance_trust
                                 );
    
        g_error := 'UPDATE VS READ';
        IF NOT (set_vs_read(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_pre_hosp_accident => i_pre_hosp_accident,
                            i_episode           => i_episode,
                            i_vs_id             => i_vs_id,
                            i_vs_val            => i_vs_val,
                            i_unit_meas         => i_unit_meas,
                            o_error             => o_error))
        THEN
            l_code_msg  := o_error.ora_sqlcode;
            l_error_msg := o_error.ora_sqlerrm;
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || g_new_line || l_code_msg || ': ' || l_error_msg);
            RAISE g_usr_info_error;
        END IF;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_usr_info_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_code_msg,
                                              l_error_msg,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_utils.undo_changes;
            RAISE g_usr_info_error;
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
    END set_pre_hosp_acc;
    --
    /**********************************************************************************************
    * Cancel accident data
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident of the record to cancel
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION cancel_pre_hosp_acc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_PRE_HOSP_ACC';
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs:' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_accident: ' || to_char(i_pre_hosp_accident) || g_new_line;
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || '- i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'CANCEL PRE_HOSP_ACCIDENT';
        ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => i_pre_hosp_accident,
                                 flg_status_in           => g_pre_hosp_status_c,
                                 id_prof_create_in       => i_prof.id,
                                 dt_pre_hosp_accident_in => g_sysdate_tstz);
    
        g_error := 'CANCEL PRE_HOSP_VS_READ';
        IF NOT (cancel_vs_read(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_pre_hosp_accident => i_pre_hosp_accident,
                               o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
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
    END cancel_pre_hosp_acc;
    --
    /**********************************************************************************************
    * Get accident data
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    * @param o_pre_hosp_accident      cursor with pre-hosp data
    * @param o_pre_hosp_vs_read       cursor with vs read data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION get_pre_hosp_acc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_pre_hosp_accident OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_PRE_HOSP_ACC';
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs:' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_accident: ' || to_char(i_pre_hosp_accident);
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error                  := 'GET LAT LONG UNIT MEASURE';
        g_long_lat_unit_mea_abrv := pk_pre_hosp_accident.get_long_lat_unit_mea_abrv(i_lang, i_prof);
    
        g_error := 'GET PRE_HOSP_ACCIDENT';
        OPEN o_pre_hosp_accident FOR
            SELECT name,
                   pat_ndo,
                   pat_nd_icon,
                   gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', gender, i_lang) desc_gender,
                   pk_date_utils.date_send(i_lang, dt_birth, i_prof) dt_birth,
                   pk_patient.get_pat_age(i_lang, dt_birth, age, i_prof.institution, i_prof.software) age,
                   address,
                   city,
                   pat_zip_code,
                   dt_report_mka,
                   cpa_code,
                   transport_number,
                   acc_zip_code,
                   latitude,
                   longitude,
                   dt_ride_out,
                   dt_arrival,
                   flg_mech_inj,
                   desc_flg_mech_inj,
                   mech_injury,
                   dt_drv_away,
                   flg_status,
                   dt_pre_hosp_accident,
                   id_prof_create,
                   prof_create_name,
                   spec_create,
                   dt_accident,
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
                   police_accident_num,
                   id_amb_trust_code,
                   ambulance_trust
              FROM (SELECT nvl(TRIM(pk_patient.get_pat_name(i_lang, i_prof, aa.id_patient, epis.id_episode)), pha.name) name,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, aa.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
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
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_report_mka, i_prof) dt_report_mka,
                           pha.cpa_code,
                           pha.transport_number,
                           pha.acc_zip_code,
                           pk_utils.to_str(pha.latitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                           pk_utils.to_str(pha.longitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_ride_out, i_prof) dt_ride_out,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_arrival, i_prof) dt_arrival,
                           pha.flg_mech_inj,
                           pk_sysdomain.get_domain('PRE_HOSP_ACCIDENT.FLG_MECH_INJ', pha.flg_mech_inj, i_lang) desc_flg_mech_inj,
                           pha.mech_injury,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_drv_away, i_prof) dt_drv_away,
                           pha.flg_status,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_pre_hosp_accident, i_prof) dt_pre_hosp_accident,
                           pha.id_prof_create,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pha.id_prof_create) prof_create_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pha.id_prof_create,
                                                            pha.dt_pre_hosp_accident,
                                                            pha.id_episode) spec_create,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_accident, i_prof) dt_accident,
                           g_long_lat_unit_mea_abrv long_lat_unit_mea_abrv,
                           decode(pk_patient.get_prof_resp(i_lang, i_prof, aa.id_patient, epis.id_episode),
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
                           pha.police_accident_num,
                           pha.id_amb_trust_code,
                           decode(pha.id_amb_trust_code,
                                  NULL,
                                  pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(i_code_mess => pha.code_ambulance_trust)),
                                  pk_sys_list.get_sys_list_value_desc(i_lang, i_prof, pha.id_amb_trust_code)) ambulance_trust
                      FROM pre_hosp_accident pha
                      JOIN announced_arrival aa
                        ON pha.id_pre_hosp_accident = aa.id_pre_hosp_accident
                      LEFT JOIN episode epis
                        ON epis.id_episode = pha.id_episode
                     WHERE pha.id_pre_hosp_accident = i_pre_hosp_accident);
    
        IF NOT (get_vs_read(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_pre_hosp_accident => i_pre_hosp_accident,
                            o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                            o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
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
            pk_types.open_my_cursor(o_pre_hosp_accident);
            pk_types.open_my_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_pre_hosp_acc;
    --
    /**********************************************************************************************
    * Get accident data for an episode
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_episode                episode ID
    * @param o_pre_hosp_accident      cursor with pre-hosp data
    * @param o_pre_hosp_vs_read       cursor with vs read data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         José Silva
    * @version                        1.0 
    * @since                          2009/07/04
    **********************************************************************************************/
    FUNCTION get_epis_pre_hosp_acc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_episode           IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_pre_hosp_accident OUT pk_types.cursor_type,
        o_pre_hosp_vs_read  OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'GET_EPIS_PRE_HOSP_ACC';
        l_pre_hosp_acc_list table_number;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs:' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode);
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error                  := 'GET LAT LONG UNIT MEASURE';
        g_long_lat_unit_mea_abrv := pk_pre_hosp_accident.get_long_lat_unit_mea_abrv(i_lang, i_prof);
    
        g_error := 'GET PRE_HOSP_ACCIDENT';
        OPEN o_pre_hosp_accident FOR
            SELECT id_pre_hosp_accident,
                   name,
                   pat_ndo,
                   pat_nd_icon,
                   gender,
                   pk_sysdomain.get_domain('PATIENT.GENDER', gender, i_lang) desc_gender,
                   pk_date_utils.dt_chr(i_lang, dt_birth, i_prof) dt_birth_chr,
                   pk_date_utils.date_send(i_lang, dt_birth, i_prof) dt_birth,
                   pk_patient.get_pat_age(i_lang, dt_birth, age, i_prof.institution, i_prof.software) age,
                   pk_announced_arrival.get_formated_age(i_lang, i_prof, dt_birth, age) pha_age,
                   address,
                   city,
                   pat_zip_code,
                   dt_accident_chr,
                   dt_accident,
                   flg_status,
                   dt_pre_hosp_accident_chr,
                   dt_pre_hosp,
                   id_prof_create,
                   prof_create_name,
                   dt_report_mka_chr,
                   dt_report_mka,
                   cpa_code,
                   transport_number,
                   acc_zip_code,
                   latitude,
                   longitude,
                   dt_ride_out_chr,
                   dt_ride_out,
                   dt_arrival_chr,
                   dt_arrival,
                   flg_mech_inj,
                   desc_flg_mech_inj,
                   mech_injury,
                   dt_drv_away_chr,
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
                   police_accident_num,
                   id_amb_trust_code,
                   ambulance_trust
              FROM (SELECT pha.id_pre_hosp_accident,
                           nvl(TRIM(pk_patient.get_pat_name(i_lang, i_prof, epis.id_patient, epis.id_episode)), pha.name) name,
                           pk_adt.get_pat_non_disc_options(i_lang, i_prof, epis.id_patient) pat_ndo,
                           pk_adt.get_pat_non_disclosure_icon(i_lang, i_prof, epis.id_patient) pat_nd_icon,
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
                           pk_date_utils.date_char_tsz(i_lang, pha.dt_accident, i_prof.institution, i_prof.software) dt_accident_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_accident, i_prof) dt_accident,
                           pha.flg_status,
                           pk_date_utils.date_char_tsz(i_lang,
                                                       pha.dt_pre_hosp_accident,
                                                       i_prof.institution,
                                                       i_prof.software) dt_pre_hosp_accident_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_pre_hosp_accident, i_prof) dt_pre_hosp,
                           dt_pre_hosp_accident,
                           pha.id_prof_create,
                           pk_prof_utils.get_name_signature(i_lang, i_prof, pha.id_prof_create) prof_create_name,
                           pk_prof_utils.get_spec_signature(i_lang,
                                                            i_prof,
                                                            pha.id_prof_create,
                                                            pha.dt_pre_hosp_accident,
                                                            pha.id_episode) spec_create,
                           pk_date_utils.date_char_tsz(i_lang, pha.dt_report_mka, i_prof.institution, i_prof.software) dt_report_mka_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_report_mka, i_prof) dt_report_mka,
                           pha.cpa_code,
                           pha.transport_number,
                           pha.acc_zip_code,
                           pk_utils.to_str(pha.latitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) latitude,
                           pk_utils.to_str(pha.longitude, i_prof, pk_pre_hosp_accident.g_lat_long_mask) longitude,
                           pk_date_utils.date_char_tsz(i_lang, pha.dt_ride_out, i_prof.institution, i_prof.software) dt_ride_out_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_ride_out, i_prof) dt_ride_out,
                           pk_date_utils.date_char_tsz(i_lang, pha.dt_arrival, i_prof.institution, i_prof.software) dt_arrival_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_arrival, i_prof) dt_arrival,
                           pha.flg_mech_inj,
                           pk_sysdomain.get_domain('PRE_HOSP_ACCIDENT.FLG_MECH_INJ', pha.flg_mech_inj, i_lang) desc_flg_mech_inj,
                           pha.mech_injury,
                           pk_date_utils.date_char_tsz(i_lang, pha.dt_drv_away, i_prof.institution, i_prof.software) dt_drv_away_chr,
                           pk_date_utils.date_send_tsz(i_lang, pha.dt_drv_away, i_prof) dt_drv_away,
                           g_long_lat_unit_mea_abrv long_lat_unit_mea_abrv,
                           decode(pk_patient.get_prof_resp(i_lang, i_prof, epis.id_patient, epis.id_episode),
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
                           pha.police_accident_num,
                           pha.id_amb_trust_code,
                           decode(pha.id_amb_trust_code,
                                  NULL,
                                  pk_string_utils.clob_to_sqlvarchar2(pk_translation.get_translation_trs(i_code_mess => pha.code_ambulance_trust)),
                                  pk_sys_list.get_sys_list_value_desc(i_lang, i_prof, pha.id_amb_trust_code)) ambulance_trust
                    
                      FROM pre_hosp_accident pha
                      JOIN announced_arrival aa
                        ON pha.id_pre_hosp_accident = aa.id_pre_hosp_accident
                      LEFT JOIN episode epis
                        ON epis.id_episode = pha.id_episode
                     WHERE pha.id_episode = i_episode
                       AND pha.flg_status IN (g_pre_hosp_status_a, g_pre_hosp_status_i))
             ORDER BY flg_status, dt_pre_hosp_accident DESC;
    
        g_error := 'GET ALL PRE_HOSP_ACC';
        SELECT id_pre_hosp_accident
          BULK COLLECT
          INTO l_pre_hosp_acc_list
          FROM pre_hosp_accident p
         WHERE p.id_episode = i_episode
           AND p.flg_status IN (g_pre_hosp_status_a, g_pre_hosp_status_i);
    
        g_error := 'GET VS READ';
        IF NOT (pk_pre_hosp_accident.get_vs_read(i_lang              => i_lang,
                                                 i_prof              => i_prof,
                                                 i_pre_hosp_acc_list => l_pre_hosp_acc_list,
                                                 o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                                                 o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
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
            pk_types.open_my_cursor(o_pre_hosp_accident);
            pk_types.open_my_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_epis_pre_hosp_acc;

    --
    /**********************************************************************************************
    * Inserts VS accident reads
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    * @param i_episode                episode id or -1 if doesn't exists
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs read inserted id's
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION create_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_vs_read.id_pre_hosp_accident%TYPE,
        i_episode           IN vital_sign_read.id_episode%TYPE,
        i_vs_id             IN table_number,
        i_vs_val            IN table_number,
        i_unit_meas         IN table_number,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name       VARCHAR2(30) := 'CREATE_VS_READ';
        l_vital_sign_read table_number;
        l_call_set_vs     BOOLEAN := FALSE;
        l_dt_registry     VARCHAR2(20 CHAR);
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_accident: ' || to_char(i_pre_hosp_accident) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode) || g_new_line;
        
            IF (i_vs_id IS NOT NULL)
            THEN
                g_log := g_log || '- i_vs_id: ' || pk_utils.concat_table(i_vs_id) || g_new_line;
            ELSE
                g_log := g_log || '- i_vs_id: ' || g_new_line;
            END IF;
            IF (i_vs_val IS NOT NULL)
            THEN
                g_log := g_log || '- i_vs_val: ' || pk_utils.concat_table(i_vs_id) || g_new_line;
            ELSE
                g_log := g_log || '- i_vs_val: ' || g_new_line;
            END IF;
            IF (i_unit_meas IS NOT NULL)
            THEN
                g_log := g_log || '- i_unit_meas: ' || pk_utils.concat_table(i_unit_meas) || g_new_line;
            ELSE
                g_log := g_log || '- i_unit_meas: ' || g_new_line;
            END IF;
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || '- i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'VALIDATE IF THERE ARE VALUES TO INSERT';
        IF (i_vs_val IS NOT NULL AND i_vs_val.count > 0)
        THEN
            FOR i IN 1 .. i_vs_val.count
            LOOP
                IF i_vs_val(i) IS NOT NULL
                THEN
                    l_call_set_vs := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        IF (l_call_set_vs)
        THEN
            g_error := 'INSERT VS_READ';
            IF NOT (pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                      i_episode            => nvl(i_episode, -1),
                                                      i_prof               => i_prof,
                                                      i_pat                => NULL,
                                                      i_vs_id              => i_vs_id,
                                                      i_vs_val             => i_vs_val,
                                                      i_id_monit           => NULL,
                                                      i_unit_meas          => i_unit_meas,
                                                      i_vs_scales_elements => table_number(),
                                                      i_notes              => NULL,
                                                      i_prof_cat_type      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                         i_prof => i_prof),
                                                      i_dt_vs_read         => table_varchar(),
                                                      i_epis_triage        => NULL,
                                                      i_unit_meas_convert  => i_unit_meas,
                                                      o_vital_sign_read    => l_vital_sign_read,
                                                      o_dt_registry        => l_dt_registry,
                                                      o_error              => o_error))
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_call_error;
            END IF;
        
            g_error := 'INS VS_READS INTO PRE_HOSP_VS_READ';
            IF (l_vital_sign_read IS NOT NULL AND l_vital_sign_read.count > 0)
            THEN
                g_error := 'START LOOP';
                FOR i IN 1 .. l_vital_sign_read.count
                LOOP
                    IF l_vital_sign_read(i) IS NOT NULL
                    THEN
                        g_error := 'INSERT PRE_HOSP_VS_READ';
                        ts_pre_hosp_vs_read.ins(id_pre_hosp_accident_in => i_pre_hosp_accident,
                                                id_vital_sign_read_in   => l_vital_sign_read(i),
                                                flg_status_in           => g_pre_hosp_vs_read_status_a);
                    END IF;
                END LOOP;
            ELSE
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_call_error;
            END IF;
        END IF;
    
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
    END create_vs_read;
    --
    /**********************************************************************************************
    * Update VS accident reads
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    * @param i_episode                episode id or -1 if doesn't exists
    * @param i_vs_id                  list of vital signs id's
    * @param i_vs_val                 list of vital signs values
    * @param i_unit_meas              list of unit measures
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION set_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_vs_read.id_pre_hosp_accident%TYPE,
        i_episode           IN vital_sign_read.id_episode%TYPE,
        i_vs_id             IN table_number,
        i_vs_val            IN table_number,
        i_unit_meas         IN table_number,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'SET_VS_READ';
        l_pre_hosp_vs_read pre_hosp_vs_read.id_pre_hosp_accident%TYPE;
        l_vital_sign_read  table_number;
        l_flg_status       pre_hosp_accident.flg_status%TYPE;
        l_code_msg         sys_message.code_message%TYPE;
        l_error_msg        sys_message.desc_message%TYPE;
        l_call_set_vs      BOOLEAN := FALSE;
        l_dt_registry      VARCHAR2(20 CHAR);
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_accident: ' || to_char(i_pre_hosp_accident) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode) || g_new_line;
        
            IF (i_vs_id IS NOT NULL)
            THEN
                g_log := g_log || '- i_vs_id: ' || pk_utils.concat_table(i_vs_id) || g_new_line;
            ELSE
                g_log := g_log || '- i_vs_id: ' || g_new_line;
            END IF;
            IF (i_vs_val IS NOT NULL)
            THEN
                g_log := g_log || '- i_vs_val: ' || pk_utils.concat_table(i_vs_id) || g_new_line;
            ELSE
                g_log := g_log || '- i_vs_val: ' || g_new_line;
            END IF;
            IF (i_unit_meas IS NOT NULL)
            THEN
                g_log := g_log || '- i_unit_meas: ' || pk_utils.concat_table(i_unit_meas) || g_new_line;
            ELSE
                g_log := g_log || '- i_unit_meas: ' || g_new_line;
            END IF;
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || '- i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'GET ID_PRE_HOSP_VS_READ';
        SELECT phr.id_pre_hosp_accident
          INTO l_pre_hosp_vs_read
          FROM pre_hosp_vs_read phr
         WHERE phr.id_pre_hosp_accident = i_pre_hosp_accident
           AND rownum = 1;
    
        g_error := 'GET RECORD STATUS';
        SELECT flg_status
          INTO l_flg_status
          FROM pre_hosp_accident pha
         WHERE pha.id_pre_hosp_accident = i_pre_hosp_accident;
    
        g_error := 'VALIDATE STATUS';
        IF l_flg_status != g_pre_hosp_status_a
        THEN
            l_code_msg  := 'ANN_ARRIV_MSG065';
            l_error_msg := pk_message.get_message(i_lang, i_prof, i_code_mess => l_code_msg);
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error || g_new_line || l_error_msg);
            RAISE g_usr_info_error;
        END IF;
    
        g_error := 'CANCEL VS_READ';
        IF NOT (cancel_vs_read(i_lang              => i_lang,
                               i_prof              => i_prof,
                               i_pre_hosp_accident => i_pre_hosp_accident,
                               o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
        g_error := 'VALIDATE IF THERE ARE VALUES TO INSERT';
        IF (i_vs_val IS NOT NULL AND i_vs_val.count > 0)
        THEN
            FOR i IN 1 .. i_vs_val.count
            LOOP
                IF i_vs_val(i) IS NOT NULL
                THEN
                    l_call_set_vs := TRUE;
                    EXIT;
                END IF;
            END LOOP;
        END IF;
    
        IF (l_call_set_vs)
        THEN
            g_error := 'INSERT VS_READ';
            IF NOT (pk_vital_sign.set_epis_vital_sign(i_lang               => i_lang,
                                                      i_episode            => nvl(i_episode, -1),
                                                      i_prof               => i_prof,
                                                      i_pat                => NULL,
                                                      i_vs_id              => i_vs_id,
                                                      i_vs_val             => i_vs_val,
                                                      i_id_monit           => NULL,
                                                      i_unit_meas          => i_unit_meas,
                                                      i_notes              => NULL,
                                                      i_vs_scales_elements => table_number(),
                                                      i_prof_cat_type      => pk_prof_utils.get_category(i_lang => i_lang,
                                                                                                         i_prof => i_prof),
                                                      i_dt_vs_read         => table_varchar(),
                                                      i_epis_triage        => NULL,
                                                      i_unit_meas_convert  => i_unit_meas,
                                                      o_vital_sign_read    => l_vital_sign_read,
                                                      o_dt_registry        => l_dt_registry,
                                                      o_error              => o_error))
            THEN
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_call_error;
            END IF;
        
            g_error := 'INS VS_READS INTO PRE_HOSP_VS_READ';
            IF (l_vital_sign_read IS NOT NULL AND l_vital_sign_read.count > 0)
            THEN
                g_error := 'START LOOP';
                FOR i IN 1 .. l_vital_sign_read.count
                LOOP
                    g_error := 'INSERT PRE_HOSP_VS_READ';
                    ts_pre_hosp_vs_read.ins(id_pre_hosp_accident_in => i_pre_hosp_accident,
                                            id_vital_sign_read_in   => l_vital_sign_read(i),
                                            flg_status_in           => g_pre_hosp_vs_read_status_a);
                END LOOP;
            ELSE
                pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
                RAISE e_call_error;
            END IF;
        END IF;
    
        IF i_flg_commit
        THEN
            COMMIT;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_usr_info_error THEN
            pk_alert_exceptions.process_error(i_lang,
                                              l_code_msg,
                                              l_error_msg,
                                              '',
                                              g_pck_owner,
                                              g_pck_name,
                                              l_func_name,
                                              'D',
                                              o_error);
            pk_utils.undo_changes;
            RAISE g_usr_info_error;
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
    END set_vs_read;
    --
    /**********************************************************************************************
    * Cancel VS accident reads
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION cancel_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_vs_read.id_pre_hosp_accident%TYPE,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'CANCEL_VS_READ';
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_accident: ' || to_char(i_pre_hosp_accident) || g_new_line;
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y';
            ELSE
                g_log := g_log || ' - INPUT PARAM - i_flg_commit: N';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'GET VS_READ_IDs';
        UPDATE pre_hosp_vs_read phr
           SET phr.flg_status = g_pre_hosp_vs_read_status_i
         WHERE phr.id_pre_hosp_accident = i_pre_hosp_accident
           AND phr.flg_status = g_pre_hosp_vs_read_status_a;
    
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
    END cancel_vs_read;
    --
    PROCEDURE open_vs_read_cursor(i_cursor IN OUT cursor_vs_read) IS
    BEGIN
        IF i_cursor%ISOPEN
        THEN
            CLOSE i_cursor;
        END IF;
    
        OPEN i_cursor FOR
            SELECT NULL id_pre_hosp_accident,
                   NULL id_vital_sign_read,
                   NULL id_vital_sign,
                   NULL id_vital_sign_desc,
                   NULL name_vs,
                   NULL VALUE,
                   NULL id_unit_measure,
                   NULL desc_unit_measure,
                   NULL val_min,
                   NULL val_max,
                   NULL rank
              FROM dual
             WHERE 1 = 0;
    END open_vs_read_cursor;
    --
    /**********************************************************************************************
    * Get VS accident reads
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION get_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_vs_read.id_pre_hosp_accident%TYPE,
        o_pre_hosp_vs_read  OUT cursor_vs_read,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name         VARCHAR2(30) := 'GET_VS_READ';
        l_pre_hosp_acc_list table_number := table_number(i_pre_hosp_accident);
    BEGIN
        g_error := 'GET PRE_HOSP_VS_READ';
        IF NOT (get_vs_read(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_pre_hosp_acc_list => l_pre_hosp_acc_list,
                            o_pre_hosp_vs_read  => o_pre_hosp_vs_read,
                            o_error             => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
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
            open_vs_read_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vs_read;
    --
    /**********************************************************************************************
    * Get VS accident reads
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_accident      id_pre_hosp_accident
    *
    * @return                         Table with Pre-Hosp vital sign read data
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2011/08/26
    **********************************************************************************************/
    FUNCTION get_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_accident IN pre_hosp_vs_read.id_pre_hosp_accident%TYPE
    ) RETURN table_vs_read IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_VS_READ';
        --
        c_pre_hosp_vs_read cursor_vs_read;
        l_error            t_error_out;
        --
        l_tbl_vs_read table_vs_read := NULL;
    BEGIN
        g_error := 'GET PRE_HOSP_VS_READ';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        IF NOT (get_vs_read(i_lang              => i_lang,
                            i_prof              => i_prof,
                            i_pre_hosp_accident => i_pre_hosp_accident,
                            o_pre_hosp_vs_read  => c_pre_hosp_vs_read,
                            o_error             => l_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
            RAISE e_call_error;
        END IF;
    
        g_error := 'FILL O_TBL_STEPS';
        alertlog.pk_alertlog.log_debug(text => g_error, object_name => g_pck_name, sub_object_name => l_func_name);
        FETCH c_pre_hosp_vs_read BULK COLLECT
            INTO l_tbl_vs_read;
        CLOSE c_pre_hosp_vs_read;
    
        RETURN l_tbl_vs_read;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_error(l_func_name || ' - ' || g_error);
            RETURN NULL;
    END get_vs_read;
    --
    /**********************************************************************************************
    * Get VS accident reads for each id_pre_hosp_accident in the list i_pre_hosp_acc_list
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_pre_hosp_acc_list      list of id_pre_hosp_accident
    * @param o_pre_hosp_vs_read       cursor with pre-hosp vs data
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/08
    **********************************************************************************************/
    FUNCTION get_vs_read
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_pre_hosp_acc_list IN table_number,
        o_pre_hosp_vs_read  OUT cursor_vs_read,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_VS_READ';
        --
        l_vs_glasgow_total CONSTANT vital_sign.id_vital_sign%TYPE := 18;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line;
        
            IF (i_pre_hosp_acc_list IS NOT NULL)
            THEN
                g_log := g_log || '- i_pre_hosp_acc_list: ' || pk_utils.concat_table(i_pre_hosp_acc_list);
            ELSE
                g_log := g_log || '- i_pre_hosp_acc_list: ';
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'GET PRE_HOSP_VS_READ';
 OPEN o_pre_hosp_vs_read FOR
            SELECT t.id_pre_hosp_accident,
                   t.id_vital_sign_read,
                   t.id_vital_sign,
                   pk_translation.get_translation(i_lang, t.code_vital_sign) name_vs,
                   t.id_vital_sign_desc,
                   decode(nvl(t.value, -999),
                          -999,
                          pk_vital_sign.get_vs_alias(i_lang,
                                                     t.gender,
                                                     nvl(t.age,
                                                         nvl(trunc(months_between(SYSDATE, t.dt_birth) / 12, 0),
                                                             nvl(t.pat_age,
                                                                 trunc(months_between(SYSDATE, t.pat_dt_birth) / 12, 0)))),
                                                     t.code_vital_sign_desc),
                          decode(t.vsr_id_unit_measure,
                                 t.vsi_id_unit_measure,
                                 pk_utils.to_str(t.value, i_prof),
                                 nvl(to_char(pk_unit_measure.get_unit_mea_conversion(t.value,
                                                                                     t.vsr_id_unit_measure,
                                                                                     t.vsi_id_unit_measure)),
                                     pk_utils.to_str(t.value, i_prof)))) VALUE,
                   t.vsi_id_unit_measure,
                   pk_vital_sign.get_vital_sign_unit_measure(i_lang,
                                                             nvl(t.vsr_id_unit_measure, t.vsi_id_unit_measure),
                                                             t.id_vs_scales_element) desc_unit_measure,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang => i_lang,
                                                               i_prof => i_prof,
                                                               i_id_vital_sign => t.id_vital_sign,
                                                               i_id_unit_measure => nvl(t.vsr_id_unit_measure,
                                                                                        t.vsi_id_unit_measure),
                                                               i_id_institution => i_prof.institution,
                                                               i_id_software => i_prof.software,
                                                               i_age => pk_patient.get_pat_age(i_lang,
                                                                                                           NULL,
                                                                                                           NULL,
                                                                                                           NULL,
                                                                                                           'MONTHS',
                                                                                                           t.id_patient))
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang => i_lang,
                                                               i_prof => i_prof,
                                                               i_id_vital_sign => t.id_vital_sign,
                                                               i_id_unit_measure => nvl(t.vsr_id_unit_measure,
                                                                                        t.vsi_id_unit_measure),
                                                               i_id_institution => i_prof.institution,
                                                               i_id_software => i_prof.software,
                                                               i_age => pk_patient.get_pat_age(i_lang,
                                                                                                           NULL,
                                                                                                           NULL,
                                                                                                           NULL,
                                                                                                           'MONTHS',
                                                                                                           t.id_patient))
                      FROM dual) val_max,
                   t.rank
              FROM (SELECT phr.id_pre_hosp_accident,
                           phr.id_vital_sign_read,
                           vs.id_vital_sign,
                           vs.code_vital_sign,
                           vsr.id_vital_sign_desc,
                           vsr.value,
                           pha.gender,
                           pha.age,
                           pha.dt_birth,
                           pat.age pat_age,
                           pat.dt_birth pat_dt_birth,
                           vsd.code_vital_sign_desc,
                           vsr.id_unit_measure vsr_id_unit_measure,
                           vsi.id_unit_measure vsi_id_unit_measure,
                           vsr.id_vs_scales_element,
                           pat.id_patient,
                           vsi.rank
                      FROM pre_hosp_vs_read phr
                     INNER JOIN pre_hosp_accident pha
                        ON phr.id_pre_hosp_accident = pha.id_pre_hosp_accident
                      LEFT JOIN episode epi
                        ON epi.id_episode = pha.id_episode
                      LEFT JOIN patient pat
                        ON pat.id_patient = epi.id_patient
                     INNER JOIN vital_sign_read vsr
                        ON phr.id_vital_sign_read = vsr.id_vital_sign_read
                     INNER JOIN vital_sign vs
                        ON vsr.id_vital_sign = vs.id_vital_sign
                      LEFT JOIN vital_sign_desc vsd
                        ON vsr.id_vital_sign_desc = vsd.id_vital_sign_desc
                      LEFT JOIN vs_soft_inst vsi
                        ON vsr.id_vital_sign = vsi.id_vital_sign
                       AND vsi.id_software IN (0, i_prof.software)
                       AND vsi.id_institution IN (0, i_prof.institution)
                       AND vsi.flg_view = g_vs_soft_inst_aa
                     WHERE phr.id_pre_hosp_accident IN (SELECT /*+ opt_estimate(table t rows=1) */
                                                         *
                                                          FROM TABLE(i_pre_hosp_acc_list) t)
                       AND vs.id_vital_sign != l_vs_glasgow_total
                       AND rownum > 0) t
             WHERE pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) = 0
            --vs_soft_inst
            UNION
            SELECT aux.id_pre_hosp_accident,
                   NULL id_vital_sign_read,
                   vsi.id_vital_sign,
                   pk_translation.get_translation(i_lang, vs.code_vital_sign) name_vs,
                   NULL id_vital_sign_desc,
                   NULL VALUE,
                   vsi.id_unit_measure,
                   pk_vital_sign.get_vital_sign_unit_measure(i_lang, vsi.id_unit_measure, NULL) desc_unit_measure,
                   (SELECT pk_vital_sign_core.get_vsum_val_min(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => vsi.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => NULL)
                      FROM dual) val_min,
                   (SELECT pk_vital_sign_core.get_vsum_val_max(i_lang            => i_lang,
                                                               i_prof            => i_prof,
                                                               i_id_vital_sign   => vs.id_vital_sign,
                                                               i_id_unit_measure => vsi.id_unit_measure,
                                                               i_id_institution  => i_prof.institution,
                                                               i_id_software     => i_prof.software,
                                                               i_age             => NULL)
                      FROM dual) val_max,
                   vsi.rank
              FROM vs_soft_inst vsi,
                   vital_sign vs,
                   (SELECT /*+ opt_estimate(table t rows=1) */
                     column_value id_pre_hosp_accident
                      FROM TABLE(i_pre_hosp_acc_list) t) aux
             WHERE vsi.flg_view = g_vs_soft_inst_aa
               AND vsi.id_vital_sign NOT IN
                   (SELECT vsr.id_vital_sign
                      FROM pre_hosp_vs_read phvsr
                      JOIN vital_sign_read vsr
                        ON phvsr.id_vital_sign_read = vsr.id_vital_sign_read
                       AND pk_delivery.check_vs_read_from_fetus(vsr.id_vital_sign_read) = 0
                     WHERE phvsr.id_pre_hosp_accident = aux.id_pre_hosp_accident)
               AND vsi.id_vital_sign != 18
               AND vs.id_vital_sign = vsi.id_vital_sign
               AND vs.flg_available = pk_alert_constant.g_yes
            --glasgow total
            UNION
            SELECT t.id_pre_hosp_accident,
                   NULL id_vital_sign_read,
                   t.id_vital_sign_parent id_vital_sign,
                   pk_translation.get_translation(i_lang, t.code_vital_sign) name_vs,
                   NULL id_vital_sign_desc,
                   pk_utils.to_str(SUM(t.value), i_prof) VALUE,
                   NULL id_unit_measure,
                   NULL desc_unit_measure,
                   NULL val_min,
                   NULL val_max,
                   30 rank
              FROM (SELECT phvr.id_pre_hosp_accident,
                           vr.id_vital_sign_parent,
                           vs.code_vital_sign,
                           vsd.value,
                           vsr.id_vital_sign_read
                      FROM pre_hosp_vs_read phvr
                      JOIN vital_sign_read vsr
                        ON vsr.id_vital_sign_read = phvr.id_vital_sign_read
                      JOIN vital_sign_relation vr
                        ON vr.id_vital_sign_detail = vsr.id_vital_sign
                      JOIN vital_sign_desc vsd
                        ON vsd.id_vital_sign_desc = vsr.id_vital_sign_desc
                      JOIN vital_sign vs
                        ON vs.id_vital_sign = vr.id_vital_sign_parent
                     WHERE phvr.id_pre_hosp_accident IN
                           (SELECT /*+ opt_estimate(table t rows=1) */
                             *
                              FROM TABLE(i_pre_hosp_acc_list) t)
                       AND vr.relation_domain = pk_alert_constant.g_vs_rel_sum
                       AND rownum > 0) t
             WHERE pk_delivery.check_vs_read_from_fetus(t.id_vital_sign_read) = 0
             GROUP BY t.id_pre_hosp_accident,
                      t.id_vital_sign_parent,
                      pk_translation.get_translation(i_lang, t.code_vital_sign)
             ORDER BY id_pre_hosp_accident DESC, rank, name_vs;    
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
        
            open_vs_read_cursor(o_pre_hosp_vs_read);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_vs_read;
    --
    /********************************************************************************************
    * Returns the vital signs detail for a certain view
    *
    * @param i_lang          The id language
    * @param i_prof          Professional, software and institution ids             
    * @param i_flg_view      Vital sign view option. AA - To get announced arrival vital signs;
    * @param o_vital_signs   Vital signs detail list
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               1.0
    * @since                 2009/08/27
    ********************************************************************************************/
    FUNCTION get_vs_header
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN alert.profissional,
        i_flg_view    IN vs_soft_inst.flg_view%TYPE,
        o_vital_signs OUT pk_vital_sign.t_cur_vs_header,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'GET_VS_HEADER';
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_flg_view: ' || i_flg_view;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error := 'GET CURSOR O_VITAL_SIGNS';
        IF NOT (pk_vital_sign.get_vs_header(i_lang     => i_lang,
                                            i_prof     => i_prof,
                                            i_flg_view => i_flg_view,
                                            o_sign_v   => o_vital_signs,
                                            o_error    => o_error))
        THEN
            pk_alertlog.log_debug(l_func_name || ' - ' || g_error);
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
            pk_vital_sign.open_my_cursor(i_cursor => o_vital_signs);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END;

    /********************************************************************************************
    * Returns the unit measure abreviation for latitude and longitude columns
    *
    * @param i_lang                  The id language
    * @param i_prof                  Professional, software and institution ids             
    *
    * @return                        Returns the unit measure abreviation for latitude and longitude columns
    *
    * @author                Alexandre Santos
    * @version               1.0
    * @since                 2009/10/08
    ********************************************************************************************/
    FUNCTION get_long_lat_unit_mea_abrv
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN alert.profissional
    ) RETURN VARCHAR2 IS
        l_func_name         VARCHAR2(30) := 'GET_LONG_LAT_UNIT_MEA_ABRV';
        l_id_unit_measure   unit_measure.id_unit_measure%TYPE;
        l_unit_measure_abrv pk_translation.t_desc_translation;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        l_id_unit_measure := pk_sysconfig.get_config('ANN_ARRIV_UNIT_MEAS_LAT_LONG', i_prof);
    
        IF (l_id_unit_measure IS NOT NULL)
        THEN
            l_unit_measure_abrv := pk_unit_measure.get_uom_abbreviation(i_lang, i_prof, l_id_unit_measure);
        ELSE
            l_unit_measure_abrv := '';
        END IF;
    
        RETURN l_unit_measure_abrv;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN '';
    END get_long_lat_unit_mea_abrv;
    --  
    FUNCTION get_long_lat_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        o_unit_measure OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_unit_measure_abrv pk_translation.t_desc_translation;
        l_func_name         VARCHAR2(30) := 'GET_LONG_LAT_UNIT_MEASURE';
    BEGIN
        g_error             := 'GET UNIT MEASURE';
        l_unit_measure_abrv := pk_pre_hosp_accident.get_long_lat_unit_mea_abrv(i_lang => i_lang, i_prof => i_prof);
    
        o_unit_measure := l_unit_measure_abrv;
    
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
    END get_long_lat_unit_measure;

    FUNCTION set_ann_arriv_hist_int
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        i_ann_arrival  IN announced_arrival.id_announced_arrival%TYPE, --announced_arrival id of the definitive episode
        i_pre_hosp_acc IN pre_hosp_accident.id_pre_hosp_accident%TYPE, --pre_hosp_accident id of the most recent pre_hosp_accident
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'SET_ANN_ARRIV_HIST_INT';
        --
        l_ann_arrival_hist ts_announced_arrival_hist.announced_arrival_hist_tc;
        l_rows             table_varchar;
        --
        l_curr_pre_hosp_acc pre_hosp_accident.id_pre_hosp_accident%TYPE;
    BEGIN
        --Verify if current pre_hosp_accident is equal i_pre_hosp_acc
        BEGIN
            SELECT aa.id_pre_hosp_accident
              INTO l_curr_pre_hosp_acc
              FROM announced_arrival aa
             WHERE aa.id_announced_arrival = i_ann_arrival;
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'ANN_ARRIV WITH NO PRE_HOSP_ACCIDENT';
                RAISE e_call_error;
        END;
    
        BEGIN
            g_error := 'GET CURR ANN_ARRIV';
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
                   aa.dt_announced_arrival
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
                   l_ann_arrival_hist(1).dt_announced_arrival
              FROM announced_arrival aa
             WHERE aa.id_pre_hosp_accident = l_curr_pre_hosp_acc;
        
            g_error := 'SET ANN_ARRIV_HIST';
            l_rows  := table_varchar();
            ts_announced_arrival_hist.ins(rows_in => l_ann_arrival_hist, rows_out => l_rows);
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'PRE_HOSP_ACCIDENT DOESN''T EXIST';
                RAISE e_call_error;
        END;
    
        IF l_curr_pre_hosp_acc != i_pre_hosp_acc
        THEN
            g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
            UPDATE announced_arrival aa
               SET aa.id_pre_hosp_accident = i_pre_hosp_acc
             WHERE aa.id_announced_arrival = i_ann_arrival
               AND aa.id_pre_hosp_accident = l_curr_pre_hosp_acc;
        
            g_error := 'GET CURR ANN_ARRIV';
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
                   aa.dt_announced_arrival
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
                   l_ann_arrival_hist(1).dt_announced_arrival
              FROM announced_arrival aa
             WHERE aa.id_pre_hosp_accident = i_pre_hosp_acc;
        
            g_error := 'SET ANN_ARRIV_HIST';
            l_rows  := table_varchar();
            ts_announced_arrival_hist.ins(rows_in => l_ann_arrival_hist, rows_out => l_rows);
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END set_ann_arriv_hist_int;

    /**********************************************************************************************
    * Invalidates the current pre_hosp_accident and inserts a new one
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_ann_arrival            announced_arrival id of the definitive episode
    * @param i_pre_hosp_acc           pre_hosp_accident id of the most recent pre_hosp_accident
    * @param i_flg_commit             true if is to commit data, otherwise false
    * @param o_pre_hosp_accident      new id_pre_hosp_accident
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/11
    **********************************************************************************************/
    FUNCTION set_pre_hosp_hist
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN alert.profissional,
        i_ann_arrival       IN announced_arrival.id_announced_arrival%TYPE DEFAULT NULL,
        i_pre_hosp_acc      IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
        i_flg_commit        IN BOOLEAN DEFAULT FALSE,
        i_vs_read           IN table_number DEFAULT NULL,
        o_pre_hosp_accident OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'SET_PRE_HOSP_HIST';
        l_rows          table_varchar;
        l_pre_hosp_hist ts_pre_hosp_accident.pre_hosp_accident_tc;
        --
        l_vs_read    table_number;
        rows_vsr_out table_varchar := table_varchar();
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_ann_arrival: ' || to_char(i_ann_arrival) || g_new_line || --
                     '- i_pre_hosp_acc: ' || to_char(i_pre_hosp_acc) || g_new_line;
        
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y' || g_new_line;
            ELSE
                g_log := g_log || '- i_flg_commit: N' || g_new_line;
            END IF;
        
            IF i_vs_read IS NULL
            THEN
                g_log := g_log || '- i_vs_read: NULL';
            ELSE
                g_log := g_log || '- i_vs_read: ' || to_char(i_vs_read.count);
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        IF i_ann_arrival IS NOT NULL
        THEN
            g_error := 'SET ANN_ARRIV HIST';
            IF NOT (set_ann_arriv_hist_int(i_lang         => i_lang,
                                           i_prof         => i_prof,
                                           i_ann_arrival  => i_ann_arrival,
                                           i_pre_hosp_acc => i_pre_hosp_acc,
                                           o_error        => o_error))
            THEN
                RAISE e_call_error;
            END IF;
        END IF;
    
        g_error             := 'GET PRE_HOSP NEXT KEY';
        o_pre_hosp_accident := ts_pre_hosp_accident.next_key;
    
        g_error := 'GET VS READ';
        IF i_vs_read IS NULL
        THEN
            --used by announced arrival when patient arrives or when canceling patient arrived
            g_error := 'GET PRE_HOSP_VSR';
            SELECT p.id_vital_sign_read
              BULK COLLECT
              INTO l_vs_read
              FROM pre_hosp_vs_read p
             WHERE p.id_pre_hosp_accident = i_pre_hosp_acc
               AND p.flg_status = g_pre_hosp_vs_read_status_a;
        ELSE
            l_vs_read := i_vs_read;
        END IF;
    
        g_error := 'GET PRE_HOSP ACC';
        SELECT o_pre_hosp_accident,
               p.id_institution,
               p.id_software,
               p.dt_accident,
               p.name,
               p.gender,
               p.dt_birth,
               p.age,
               p.address,
               p.city,
               p.pat_zip_code,
               p.dt_report_mka,
               p.cpa_code,
               p.transport_number,
               p.acc_zip_code,
               p.latitude,
               p.longitude,
               p.dt_ride_out,
               p.dt_arrival,
               p.flg_mech_inj,
               p.mech_injury,
               p.dt_drv_away,
               p.flg_status,
               i_prof.id,
               g_sysdate_tstz,
               p.id_episode,
               p.flg_prot_device,
               p.flg_rta_pat_typ,
               p.rta_pat_typ_ft,
               p.flg_is_driv_own,
               p.flg_police_involved,
               p.police_num,
               p.police_station,
               p.police_accident_num,
               p.id_amb_trust_code --,
        --   p.ambulance_trust
          INTO l_pre_hosp_hist(1).id_pre_hosp_accident,
               l_pre_hosp_hist(1).id_institution,
               l_pre_hosp_hist(1).id_software,
               l_pre_hosp_hist(1).dt_accident,
               l_pre_hosp_hist(1).name,
               l_pre_hosp_hist(1).gender,
               l_pre_hosp_hist(1).dt_birth,
               l_pre_hosp_hist(1).age,
               l_pre_hosp_hist(1).address,
               l_pre_hosp_hist(1).city,
               l_pre_hosp_hist(1).pat_zip_code,
               l_pre_hosp_hist(1).dt_report_mka,
               l_pre_hosp_hist(1).cpa_code,
               l_pre_hosp_hist(1).transport_number,
               l_pre_hosp_hist(1).acc_zip_code,
               l_pre_hosp_hist(1).latitude,
               l_pre_hosp_hist(1).longitude,
               l_pre_hosp_hist(1).dt_ride_out,
               l_pre_hosp_hist(1).dt_arrival,
               l_pre_hosp_hist(1).flg_mech_inj,
               l_pre_hosp_hist(1).mech_injury,
               l_pre_hosp_hist(1).dt_drv_away,
               l_pre_hosp_hist(1).flg_status,
               l_pre_hosp_hist(1).id_prof_create,
               l_pre_hosp_hist(1).dt_pre_hosp_accident,
               l_pre_hosp_hist(1).id_episode,
               l_pre_hosp_hist(1).flg_prot_device,
               l_pre_hosp_hist(1).flg_rta_pat_typ,
               l_pre_hosp_hist(1).rta_pat_typ_ft,
               l_pre_hosp_hist(1).flg_is_driv_own,
               l_pre_hosp_hist(1).flg_police_involved,
               l_pre_hosp_hist(1).police_num,
               l_pre_hosp_hist(1).police_station,
               l_pre_hosp_hist(1).police_accident_num,
               l_pre_hosp_hist(1).id_amb_trust_code --,
        --    l_pre_hosp_hist(1).ambulance_trust
          FROM pre_hosp_accident p
         WHERE p.id_pre_hosp_accident = i_pre_hosp_acc;
    
        g_error := 'INVALIDATE PRE_HOSP_ACC';
        ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => i_pre_hosp_acc, flg_status_in => g_pre_hosp_status_i);
    
        g_error := 'SET NEW PRE_HOSP_ACC';
        --   ts_pre_hosp_accident.ins(rows_in => l_pre_hosp_hist, rows_out => l_rows);
    
        ts_pre_hosp_accident.ins(id_pre_hosp_accident_in => l_pre_hosp_hist(1).id_pre_hosp_accident,
                                 id_institution_in       => l_pre_hosp_hist(1).id_institution,
                                 id_software_in          => l_pre_hosp_hist(1).id_software,
                                 dt_accident_in          => l_pre_hosp_hist(1).dt_accident,
                                 name_in                 => l_pre_hosp_hist(1).name,
                                 gender_in               => l_pre_hosp_hist(1).gender,
                                 dt_birth_in             => l_pre_hosp_hist(1).dt_birth,
                                 age_in                  => l_pre_hosp_hist(1).age,
                                 address_in              => l_pre_hosp_hist(1).address,
                                 city_in                 => l_pre_hosp_hist(1).city,
                                 pat_zip_code_in         => l_pre_hosp_hist(1).pat_zip_code,
                                 dt_report_mka_in        => l_pre_hosp_hist(1).dt_report_mka,
                                 cpa_code_in             => l_pre_hosp_hist(1).cpa_code,
                                 transport_number_in     => l_pre_hosp_hist(1).transport_number,
                                 acc_zip_code_in         => l_pre_hosp_hist(1).acc_zip_code,
                                 latitude_in             => l_pre_hosp_hist(1).latitude,
                                 longitude_in            => l_pre_hosp_hist(1).longitude,
                                 dt_ride_out_in          => l_pre_hosp_hist(1).dt_ride_out,
                                 dt_arrival_in           => l_pre_hosp_hist(1).dt_arrival,
                                 flg_mech_inj_in         => l_pre_hosp_hist(1).flg_mech_inj,
                                 mech_injury_in          => l_pre_hosp_hist(1).mech_injury,
                                 dt_drv_away_in          => l_pre_hosp_hist(1).dt_drv_away,
                                 flg_status_in           => l_pre_hosp_hist(1).flg_status,
                                 id_prof_create_in       => l_pre_hosp_hist(1).id_prof_create,
                                 dt_pre_hosp_accident_in => l_pre_hosp_hist(1).dt_pre_hosp_accident,
                                 id_episode_in           => l_pre_hosp_hist(1).id_episode,
                                 flg_prot_device_in      => l_pre_hosp_hist(1).flg_prot_device,
                                 flg_rta_pat_typ_in      => l_pre_hosp_hist(1).flg_rta_pat_typ,
                                 rta_pat_typ_ft_in       => l_pre_hosp_hist(1).flg_is_driv_own,
                                 flg_is_driv_own_in      => l_pre_hosp_hist(1).flg_is_driv_own,
                                 flg_police_involved_in  => l_pre_hosp_hist(1).flg_police_involved,
                                 police_num_in           => l_pre_hosp_hist(1).police_num,
                                 police_station_in       => l_pre_hosp_hist(1).police_station,
                                 police_accident_num_in  => l_pre_hosp_hist(1).police_accident_num,
                                 id_amb_trust_code_in    => l_pre_hosp_hist(1).id_amb_trust_code,
                                 rows_out                => l_rows);
    
        g_error := 'VALIDATE INS ROW';
        IF (l_rows.count != 1)
        THEN
            RAISE e_call_error;
        END IF;
    
        g_error := 'INS VS';
        FOR i IN 1 .. l_vs_read.count
        LOOP
            ts_pre_hosp_vs_read.ins(id_pre_hosp_accident_in => o_pre_hosp_accident,
                                    id_vital_sign_read_in   => l_vs_read(i),
                                    rows_out                => rows_vsr_out);
        END LOOP;
    
        g_error := 'INV OLD VS';
        IF NOT (pk_pre_hosp_accident.cancel_vs_read(i_lang              => i_lang,
                                                    i_prof              => i_prof,
                                                    i_pre_hosp_accident => i_pre_hosp_acc,
                                                    i_flg_commit        => i_flg_commit,
                                                    o_error             => o_error))
        THEN
            RAISE e_call_error;
        END IF;
    
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
    END set_pre_hosp_hist;

    FUNCTION get_pre_hosp_acc_id_by_epi_int(i_episode episode.id_episode%TYPE)
        RETURN pre_hosp_accident.id_pre_hosp_accident%TYPE IS
        l_func_name    VARCHAR2(30) := 'GET_PRE_HOSP_ACC_ID_BY_EPI_INT';
        l_pre_hosp_acc pre_hosp_accident.id_pre_hosp_accident%TYPE;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_episode: ' || to_char(i_episode);
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        SELECT p.id_pre_hosp_accident
          INTO l_pre_hosp_acc
          FROM pre_hosp_accident p
         WHERE p.id_episode = i_episode
           AND p.flg_status = g_pre_hosp_status_a;
    
        RETURN l_pre_hosp_acc;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_pre_hosp_acc_id_by_epi_int;

    /********************************************************************************************
    * Updates patient data
    *
    * @param i_lang          The id language
    * @param i_prof          Professional, software and institution ids
    * @param i_episode       episode id of the definitive episode
    * @param i_ann_arrival   announced_arrival id of the definitive episode
    * @param i_pre_hosp_acc  pre_hosp_accident id of the most recent pre_hosp_accident
    * @param i_name          patient name
    * @param i_gender        patient gender
    * @param i_dt_birth      patient birth date
    * @param i_age           patient age
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               1.0
    * @since                 2009/10/22
    ********************************************************************************************/
    FUNCTION update_patient
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        i_episode      IN pre_hosp_accident.id_episode%TYPE,
        i_ann_arrival  IN announced_arrival.id_announced_arrival%TYPE,
        i_pre_hosp_acc IN pre_hosp_accident.id_pre_hosp_accident%TYPE,
        i_name         IN pre_hosp_accident.name%TYPE,
        i_gender       IN pre_hosp_accident.gender%TYPE,
        i_dt_birth     IN pre_hosp_accident.dt_birth%TYPE,
        i_age          IN pre_hosp_accident.age%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'UPDATE_PATIENT';
        --
        l_pre_hosp_acc_new pre_hosp_accident.id_pre_hosp_accident%TYPE;
        --
        l_ann_arrival  announced_arrival.id_announced_arrival%TYPE;
        l_pre_hosp_acc announced_arrival.id_pre_hosp_accident%TYPE;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_pre_hosp_acc: ' || to_char(i_pre_hosp_acc);
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        IF i_ann_arrival IS NULL
           OR i_pre_hosp_acc IS NULL
        THEN
            BEGIN
                SELECT aa.id_announced_arrival, aa.id_pre_hosp_accident
                  INTO l_ann_arrival, l_pre_hosp_acc
                  FROM announced_arrival aa
                 WHERE aa.id_episode = i_episode;
            EXCEPTION
                WHEN no_data_found THEN
                    --if this happens then there is nothing to do
                    RETURN TRUE;
            END;
        ELSE
            l_ann_arrival  := i_ann_arrival;
            l_pre_hosp_acc := i_pre_hosp_acc;
        END IF;
    
        IF l_ann_arrival IS NOT NULL
           AND l_pre_hosp_acc IS NOT NULL
        THEN
            g_error := 'SET PRE_HOSP HIST';
            IF NOT pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_ann_arrival       => l_ann_arrival,
                                                          i_pre_hosp_acc      => l_pre_hosp_acc,
                                                          i_flg_commit        => FALSE, --COMMIT will be done by ADT
                                                          o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                          o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
            ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                     name_in                 => i_name,
                                     name_nin                => FALSE,
                                     gender_in               => i_gender,
                                     gender_nin              => FALSE,
                                     dt_birth_in             => i_dt_birth,
                                     dt_birth_nin            => FALSE,
                                     age_in                  => i_age,
                                     age_nin                 => FALSE,
                                     id_prof_create_in       => i_prof.id,
                                     dt_pre_hosp_accident_in => g_sysdate_tstz);
        
            g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
            UPDATE announced_arrival aa
               SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new, aa.dt_announced_arrival = g_sysdate_tstz
             WHERE aa.id_announced_arrival = l_ann_arrival
               AND aa.id_pre_hosp_accident = l_pre_hosp_acc;
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
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END update_patient;

    /********************************************************************************************
    * Updates patient data (This function is used by ADT team)
    *
    * @param i_lang          The id language
    * @param i_prof          Professional, software and institution ids             
    * @param i_patient       id patient
    * @param i_name          patient name
    * @param i_gender        patient gender
    * @param i_dt_birth      patient birth date
    * @param i_age           patient age
    * @param o_error         Error message
    *
    * @return                TRUE if sucess, FALSE otherwise
    *
    * @author                Alexandre Santos
    * @version               1.0
    * @since                 2009/10/22
    ********************************************************************************************/
    FUNCTION update_patient
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN alert.profissional,
        i_patient  IN patient.id_patient%TYPE,
        i_name     IN pre_hosp_accident.name%TYPE,
        i_gender   IN pre_hosp_accident.gender%TYPE,
        i_dt_birth IN VARCHAR2,
        i_age      IN pre_hosp_accident.age%TYPE,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'UPDATE_PATIENT';
        --
        l_pre_hosp_acc_new pre_hosp_accident.id_pre_hosp_accident%TYPE;
    BEGIN
        g_error := 'GET PATIENT ACTIVE ANN_ARRIV''s';
        FOR l_curr_value IN (SELECT aa.id_announced_arrival, aa.id_pre_hosp_accident
                               FROM pre_hosp_accident pha
                               JOIN announced_arrival aa
                                 ON aa.id_pre_hosp_accident = pha.id_pre_hosp_accident
                               JOIN episode epis
                                 ON epis.id_episode = pha.id_episode
                               JOIN patient p
                                 ON p.id_patient = epis.id_patient
                              WHERE p.id_patient = i_patient
                                AND pha.flg_status = g_pre_hosp_status_a
                                AND epis.flg_status IN
                                    (pk_alert_constant.g_epis_status_active, pk_alert_constant.g_epis_status_pendent)
                              ORDER BY pha.dt_pre_hosp_accident DESC)
        LOOP
            g_error := 'SET PRE_HOSP HIST';
            IF NOT pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                          i_prof              => i_prof,
                                                          i_ann_arrival       => l_curr_value.id_announced_arrival,
                                                          i_pre_hosp_acc      => l_curr_value.id_pre_hosp_accident,
                                                          i_flg_commit        => FALSE, --COMMIT will be done by ADT
                                                          o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                          o_error             => o_error)
            THEN
                RAISE e_call_error;
            END IF;
        
            ts_pre_hosp_accident.upd(id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                     name_in                 => i_name,
                                     name_nin                => FALSE,
                                     gender_in               => i_gender,
                                     gender_nin              => FALSE,
                                     dt_birth_in             => pk_date_utils.get_string_tstz(i_lang,
                                                                                              i_prof,
                                                                                              i_dt_birth,
                                                                                              NULL),
                                     dt_birth_nin            => FALSE,
                                     age_in                  => i_age,
                                     age_nin                 => FALSE,
                                     id_prof_create_in       => i_prof.id,
                                     dt_pre_hosp_accident_in => g_sysdate_tstz);
        
            g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
            UPDATE announced_arrival aa
               SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new, aa.dt_announced_arrival = g_sysdate_tstz
             WHERE aa.id_announced_arrival = l_curr_value.id_announced_arrival
               AND aa.id_pre_hosp_accident = l_curr_value.id_pre_hosp_accident;
        END LOOP;
    
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
    END update_patient;

    /********************************************************************************************
    * Associates vital signs reads with the pre_hosp_accident
    *
    * @param i_lang                  The id language
    * @param i_prof                  Professional, software and institution ids   
    * @param i_episode               id episode          
    * @param i_vs_read               Vital signs read id's
    * @param i_flg_commit            true if is to commit data, otherwise false
    * @param o_vs_read               Vital signs read id's associated with pre_hosp_accident
    * @param o_error                 Error message
    *
    * @return                        TRUE if sucess, FALSE otherwise
    *
    * @author                        Alexandre Santos
    * @version                       1.0
    * @since                         2009/10/22
    ********************************************************************************************/
    FUNCTION update_pre_hosp_vs
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN alert.profissional,
        i_episode    IN episode.id_episode%TYPE,
        i_vs_read    IN table_number,
        i_flg_commit IN BOOLEAN DEFAULT FALSE,
        o_vs_read    OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30) := 'UPDATE_PRE_HOSP_VS';
        --
        l_pre_hosp_acc_old      pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_pre_hosp_acc_new      pre_hosp_accident.id_pre_hosp_accident%TYPE;
        l_old_pre_hosp_accident pre_hosp_accident.id_pre_hosp_accident%TYPE;
        --
        l_aa_arrival_status_e CONSTANT VARCHAR2(1) := 'E'; --Expected
        l_id_ann_arrival announced_arrival.id_announced_arrival%TYPE;
        l_ann_arr_hist   announced_arrival_hist.id_announced_arrival_hist%TYPE;
        l_ann_arr_status announced_arrival.flg_status%TYPE;
        l_vs_read        table_number;
    BEGIN
        IF (g_is_to_log)
        THEN
            --Input Parameters
            g_log := l_func_name || ' - INPUT PARAMs: ' || g_new_line || --
                     '- i_lang: ' || to_char(i_lang) || g_new_line || --
                     '- i_prof: ' || to_char(i_prof.id) || ', ' || to_char(i_prof.institution) || ', ' ||
                     to_char(i_prof.software) || g_new_line || --
                     '- i_episode: ' || to_char(i_episode);
        
            IF i_flg_commit
            THEN
                g_log := g_log || '- i_flg_commit: Y' || g_new_line;
            ELSE
                g_log := g_log || '- i_flg_commit: N' || g_new_line;
            END IF;
        
            IF i_vs_read IS NULL
            THEN
                g_log := g_log || '- i_vs_read: NULL';
            ELSE
                g_log := g_log || '- i_vs_read: ' || to_char(i_vs_read.count);
            END IF;
        
            pk_alertlog.log_debug(g_log);
        END IF;
    
        g_error            := 'GET PRE_HOSP_ACC_ID';
        l_pre_hosp_acc_old := get_pre_hosp_acc_id_by_epi_int(i_episode => i_episode);
    
        g_error := 'GET ANN_ARRIV CURR STATUS';
        BEGIN
            SELECT aa.id_announced_arrival, aa.flg_status
              INTO l_id_ann_arrival, l_ann_arr_status
              FROM announced_arrival aa
             WHERE aa.id_pre_hosp_accident = l_pre_hosp_acc_old;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_ann_arrival := NULL;
                l_ann_arr_status := NULL;
        END;
    
        IF (l_id_ann_arrival IS NOT NULL AND l_ann_arr_status IS NOT NULL)
        THEN
            --1º Rule: The association with pre_hosp_accident must only be made when the announced arrival status is expected
            IF l_ann_arr_status = l_aa_arrival_status_e
            THEN
                --2º Rule: The only vital signs to associate are the ones that fulfill with this vs_soft_inst.flg_view = 'AA'
                g_error := 'GET ANN_ARRIV VS';
                SELECT vsr.id_vital_sign_read
                  BULK COLLECT
                  INTO l_vs_read
                  FROM vital_sign_read vsr
                  JOIN vs_soft_inst vsi
                    ON vsi.id_vital_sign = vsr.id_vital_sign
                 WHERE vsi.flg_view = 'AA'
                   AND vsr.id_vital_sign_read IN
                       (SELECT column_value id_vital_sign_read
                          FROM TABLE(i_vs_read)
                        UNION
                        SELECT vsr.id_vital_sign_read
                          FROM pre_hosp_accident pha
                          JOIN pre_hosp_vs_read phv
                            ON phv.id_pre_hosp_accident = pha.id_pre_hosp_accident
                          JOIN vital_sign_read vsr
                            ON vsr.id_vital_sign_read = phv.id_vital_sign_read
                         WHERE pha.id_pre_hosp_accident = l_pre_hosp_acc_old
                           AND pha.flg_status = g_pre_hosp_status_a
                           AND vsr.id_vital_sign NOT IN
                               (SELECT vsr2.id_vital_sign
                                  FROM TABLE(i_vs_read) c
                                  JOIN vital_sign_read vsr2
                                    ON c.column_value = vsr2.id_vital_sign_read));
            
                IF (l_vs_read.count > 0)
                THEN
                    g_error := 'SET PRE_HOSP HIST';
                    IF NOT pk_pre_hosp_accident.set_pre_hosp_hist(i_lang              => i_lang,
                                                                  i_prof              => i_prof,
                                                                  i_pre_hosp_acc      => l_pre_hosp_acc_old,
                                                                  i_flg_commit        => i_flg_commit,
                                                                  i_vs_read           => l_vs_read,
                                                                  o_pre_hosp_accident => l_pre_hosp_acc_new,
                                                                  o_error             => o_error)
                    THEN
                        RAISE e_call_error;
                    END IF;
                
                    g_error := 'INS ANN ARR HIST';
                    IF NOT (pk_announced_arrival.set_ann_arr_hist(i_lang                   => i_lang,
                                                                  i_announced_arrival      => l_id_ann_arrival,
                                                                  i_flg_commit             => FALSE,
                                                                  o_announced_arrival_hist => l_ann_arr_hist,
                                                                  o_pre_hosp_accident      => l_old_pre_hosp_accident,
                                                                  o_error                  => o_error))
                    THEN
                        RAISE e_call_error;
                    END IF;
                
                    g_error := 'UPD ANN ARRIVAL - PRE_HOSP ID';
                    UPDATE announced_arrival aa
                       SET aa.id_pre_hosp_accident = l_pre_hosp_acc_new
                     WHERE aa.id_announced_arrival = l_id_ann_arrival
                       AND aa.id_pre_hosp_accident = l_old_pre_hosp_accident;
                
                    ts_announced_arrival.upd(id_announced_arrival_in => l_id_ann_arrival,
                                             id_pre_hosp_accident_in => l_pre_hosp_acc_new,
                                             dt_announced_arrival_in => g_sysdate_tstz);
                
                    IF i_flg_commit
                    THEN
                        COMMIT;
                    END IF;
                END IF;
            END IF;
        END IF;
    
        o_vs_read := l_vs_read;
    
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
    END update_pre_hosp_vs;

BEGIN
    g_sysdate_tstz := current_timestamp;

    pk_alertlog.who_am_i(g_pck_owner, g_pck_name);
    pk_alertlog.log_init(g_pck_name);

    --The use of g_is_to_log is temporary. 
    --For performance reasons the input parameters concatenations and log are only done when the variable
    --g_is_to_log is true
    g_is_to_log := (pk_alertlog.get_log_level(g_pck_name) >= g_debug_log_level);
END pk_pre_hosp_accident;
/
