/*-- Last Change Revision: $Rev: 2028871 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:28 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_pre_hosp_accident IS

    -- Author  : ALEXANDRE.SANTOS
    -- Created : 08-05-2009 15:21:54
    -- Purpose : Manage Pre-Hospital accident data

    TYPE rec_vs_read IS RECORD(
        id_pre_hosp_accident pre_hosp_vs_read.id_pre_hosp_accident%TYPE,
        id_vital_sign_read   pre_hosp_vs_read.id_vital_sign_read%TYPE,
        id_vital_sign        vital_sign.id_vital_sign%TYPE,
        name_vs              pk_translation.t_desc_translation,
        id_vital_sign_desc   vital_sign_desc.id_vital_sign_desc%TYPE,
        VALUE                pk_translation.t_desc_translation,
        id_unit_measure      vs_soft_inst.id_unit_measure%TYPE,
        desc_unit_measure    pk_translation.t_desc_translation,
        val_min              vital_sign_unit_measure.val_min%TYPE,
        val_max              vital_sign_unit_measure.val_max%TYPE,
        rank                 vs_soft_inst.rank%TYPE);

    TYPE cursor_vs_read IS REF CURSOR RETURN rec_vs_read;
    TYPE table_vs_read IS TABLE OF rec_vs_read;

    g_usr_info_error EXCEPTION;
    g_lat_long_mask CONSTANT VARCHAR2(12) := 'FM999D999999';

    g_domain_patient_gender      CONSTANT sys_domain.code_domain%TYPE := 'PATIENT.GENDER';
    g_domain_flg_prot_device     CONSTANT sys_domain.code_domain%TYPE := 'PRE_HOSP_ACCIDENT.FLG_PROT_DEVICE';
    g_domain_flg_rta_pat_typ     CONSTANT sys_domain.code_domain%TYPE := 'PRE_HOSP_ACCIDENT.FLG_RTA_PAT_TYP';
    g_domain_flg_is_driv_own     CONSTANT sys_domain.code_domain%TYPE := 'PRE_HOSP_ACCIDENT.FLG_IS_DRIV_OWN';
    g_domain_flg_police_involved CONSTANT sys_domain.code_domain%TYPE := 'PRE_HOSP_ACCIDENT.FLG_POLICE_INVOLVED';
		
	g_code_ambulance CONSTANT	pre_hosp_accident.code_ambulance_trust%type := 'ALERT.PRE_HOSP_ACCIDENT.CODE_AMBULANCE_TRUST.';
  g_module CONSTANT varchar2 (20 char) := 'PRE_HOSP_ACCIDENT';
	
    g_pha_flg_rta_pat_typ_other CONSTANT pre_hosp_accident.flg_rta_pat_typ%TYPE := 'O';

    g_vs_soft_inst_aa CONSTANT vs_soft_inst.flg_view%TYPE := 'AA';

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
			  i_id_amb_trust_code in pre_hosp_accident.id_amb_trust_code%type,
				i_ambulance_trust in varchar2,
				
        i_flg_commit          IN BOOLEAN DEFAULT FALSE,
        o_pre_hosp_accident   OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
			  i_id_amb_trust_code in pre_hosp_accident.id_amb_trust_code%type,
				i_ambulance_trust in varchar2,				
        i_flg_commit          IN BOOLEAN DEFAULT FALSE,
        o_pre_hosp_accident   OUT pre_hosp_accident.id_pre_hosp_accident%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
			  i_id_amb_trust_code in pre_hosp_accident.id_amb_trust_code%type,
				i_ambulance_trust in varchar2,
				
        i_flg_commit          IN BOOLEAN DEFAULT FALSE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    PROCEDURE open_vs_read_cursor(i_cursor IN OUT cursor_vs_read);

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
    ) RETURN BOOLEAN;

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
    ) RETURN table_vs_read;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Returns the unit measure abreviation for latitude and longitude columns
    *
    * @param i_lang          The id language
    * @param i_prof          Professional, software and institution ids             
    *
    * @return                Returns the unit measure abreviation for latitude and longitude columns
    *
    * @author                Alexandre Santos
    * @version               1.0
    * @since                 2009/10/08
    ********************************************************************************************/
    FUNCTION get_long_lat_unit_mea_abrv
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN alert.profissional
    ) RETURN VARCHAR2;

    FUNCTION get_long_lat_unit_measure
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN alert.profissional,
        o_unit_measure OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;
END pk_pre_hosp_accident;
/
