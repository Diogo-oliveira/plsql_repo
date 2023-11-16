/*-- Last Change Revision: $Rev: 2028455 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:45:52 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_announced_arrival IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 11-05-2009 17:11:11
    -- Purpose : Manage announced arrival data

    -- Global constants
    g_aa_arrival_status_e CONSTANT VARCHAR2(1) := 'E'; --Expected
    g_aa_arrival_status_a CONSTANT VARCHAR2(1) := 'A'; --Arrived
    g_aa_arrival_status_c CONSTANT VARCHAR2(1) := 'C'; --Cancelled

    g_code_no_specialist CONSTANT sys_message.code_message%TYPE := 'COMMON_M043';

    g_aa_action_arrival CONSTANT action.internal_name%TYPE := 'PAT_ARRIVAL';

    g_aa_action_edit        CONSTANT action.internal_name%TYPE := 'EDIT';
    g_aa_action_arrival_adt CONSTANT action.internal_name%TYPE := 'PAT_ARRIVAL_ADT';
    g_aa_action_cancel_conf CONSTANT action.internal_name%TYPE := 'CANCEL_CONF';
    g_aa_action_cancel_aa   CONSTANT action.internal_name%TYPE := 'CANCEL_AA';
    g_aa_action_associate   CONSTANT action.internal_name%TYPE := 'ASSOCIATE';

    TYPE rec_announced_arrival IS RECORD(
        id_announced_arrival_hist NUMBER(24),
        id_announced_arrival      NUMBER(24),
        id_pre_hosp_accident      NUMBER(24),
        pat_name                  VARCHAR2(1000 CHAR),
        gender                    VARCHAR2(1000 CHAR),
        dt_birth_chr              VARCHAR2(1000 CHAR),
        age                       VARCHAR2(1000 CHAR),
        address                   VARCHAR2(1000 CHAR),
        city                      VARCHAR2(200 CHAR),
        pat_zip_code              VARCHAR2(30 CHAR),
        dt_accident               VARCHAR2(1000 CHAR),
        type_injury               VARCHAR2(200 CHAR),
        condition                 VARCHAR2(200 CHAR),
        referred_by               VARCHAR2(200 CHAR),
        id_speciality             NUMBER(12),
        desc_speciality           VARCHAR2(1000 CHAR),
        id_clinical_service       NUMBER(12),
        desc_clinical_service     VARCHAR2(1000 CHAR),
        id_ed_physician           NUMBER(24),
        ed_physician_name         VARCHAR2(1000 CHAR),
        dt_expected_arrival       VARCHAR2(1000 CHAR),
        id_cancel_reason          NUMBER(24),
        cancel_reason             VARCHAR2(1000 CHAR),
        cancel_notes              VARCHAR2(1000 CHAR),
        flg_status                VARCHAR2(1),
        desc_status               VARCHAR2(1000 CHAR),
        dt_report_mka             VARCHAR2(1000 CHAR),
        cpa_code                  VARCHAR2(30 CHAR),
        amb_trust_code            VARCHAR2(1000 CHAR),
        transport_number          VARCHAR2(30 CHAR),
        acc_zip_code              VARCHAR2(30 CHAR),
        latitude                  VARCHAR2(1000 CHAR),
        longitude                 VARCHAR2(1000 CHAR),
        dt_ride_out               VARCHAR2(1000 CHAR),
        dt_arrival                VARCHAR2(1000 CHAR),
        mech_injury               VARCHAR2(200 CHAR),
        dt_drv_away               VARCHAR2(1000 CHAR),
        flg_prot_device           VARCHAR2(2 CHAR),
        desc_prot_device          VARCHAR2(1000 CHAR),
        flg_rta_pat_typ           VARCHAR2(2 CHAR),
        desc_rta_pat_typ          VARCHAR2(4000 CHAR),
        flg_is_driv_own           VARCHAR2(1 CHAR),
        desc_is_driv_own          VARCHAR2(1000 CHAR),
        flg_police_involved       VARCHAR2(1 CHAR),
        desc_police_involved      VARCHAR2(1000 CHAR),
        police_num                VARCHAR2(200 CHAR),
        police_station            VARCHAR2(200 CHAR),
        police_accident_num       VARCHAR2(200 CHAR));

    TYPE rec_ann_arriv_hist IS RECORD(
        prev_ann_arriv_hist  announced_arrival_hist.id_announced_arrival_hist%TYPE,
        prev_pha             announced_arrival_hist.id_pre_hosp_accident%TYPE,
        curr_ann_arriv_hist  announced_arrival_hist.id_announced_arrival_hist%TYPE,
        curr_pha             announced_arrival_hist.id_pre_hosp_accident%TYPE,
        id_episode           announced_arrival_hist.id_episode%TYPE,
        dt_announced_arrival announced_arrival_hist.dt_announced_arrival%TYPE,
        id_prof_create       pre_hosp_accident.id_prof_create%TYPE,
        flg_status           announced_arrival_hist.flg_status%TYPE,
        desc_status          sys_domain.desc_val%TYPE,
        cancel_reason        translation.desc_lang_1%TYPE,
        cancel_notes         announced_arrival_hist.cancel_notes%TYPE);

    TYPE table_ann_arriv_hist IS TABLE OF rec_ann_arriv_hist;

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
        WITH LOCAL TIME ZONE;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN VARCHAR2;
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
    ) RETURN VARCHAR2;
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
    /*FUNCTION get_ann_arrival_int
    (
        i_lang              IN language.id_language%TYPE,
        i_prof_id           IN professional.id_professional%TYPE,
        i_prof_inst         IN institution.id_institution%TYPE,
        i_prof_sw           IN software.id_software%TYPE,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        o_ann_arrival       OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;*/
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
        o_announced_arrival   OUT announced_arrival.id_announced_arrival%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
        
        o_error OUT t_error_out
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    /*
    --ALERT-277593 no commit allowed - invoked by ADT
    FUNCTION set_pat_arrival
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_announced_arrival IN announced_arrival.id_announced_arrival%TYPE,
        i_patient           IN patient.id_patient%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    */
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
    ) RETURN BOOLEAN;
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
    ) RETURN BOOLEAN;
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
    FUNCTION get_ann_arrival_id(i_episode IN episode.id_episode%TYPE) RETURN announced_arrival.id_announced_arrival%TYPE;
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
    ) RETURN announced_arrival.id_announced_arrival%TYPE;
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
        RETURN announced_arrival.flg_status%TYPE; --
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
    FUNCTION get_ann_arrival_status(i_episode IN episode.id_episode%TYPE) RETURN announced_arrival.flg_status%TYPE;
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
        WITH LOCAL TIME ZONE;
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    );

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
    );

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN VARCHAR2;

    /********************************************************************************************
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Gets the patient address
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids             
    * @param i_patient                Patient identifier                                           
    *                                                                                                
    * @return                         patient address
    * 
    * @author  Elisabete Bugalho 
    * @version 2.6.3
    * @since   22-07-2013
    **********************************************************************************************/
    FUNCTION get_pat_address
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE
    ) RETURN VARCHAR2;

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
    ) RETURN BOOLEAN;

END pk_announced_arrival;
/
