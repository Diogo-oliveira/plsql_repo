/*-- Last Change Revision: $Rev: 2050737 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-22 15:27:53 +0000 (ter, 22 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_data_access_cdoc IS

    k_bed_status_desc CONSTANT VARCHAR2(0050 CHAR) := 'DESC';
    k_bed_status_code CONSTANT VARCHAR2(0050 CHAR) := 'CODE';

    FUNCTION get_total_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_total_beds;

    FUNCTION get_all_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_beds;

    --************************************************************
    FUNCTION get_death_det_value
    (
        i_text              IN VARCHAR2,
        i_id_death_registry IN NUMBER,
        i_ds_component      IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_department
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER,
        i_mode IN VARCHAR2 DEFAULT 'DESC'
    ) RETURN VARCHAR2;

    FUNCTION get_process
    (
        i_patient     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2;

    -- ****************************************** 
    FUNCTION get_soft_by_epis_type
    (
        i_epis_type   IN NUMBER,
        i_institution IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_diag_death_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_deaths_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_death_base;

    FUNCTION get_deaths
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_death;


    FUNCTION get_child_birth_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_child_birth_base;

    FUNCTION get_child_birth
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_data_child_birth;


    FUNCTION get_patient_type_arabic
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_treatment_physicians
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_complaint_desc
    (
        i_lang              IN NUMBER,
        i_patient_complaint IN VARCHAR2,
        i_code_complaint    IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_triage_level
    (
        i_lang              IN NUMBER,
        i_prof              IN profissional,
        i_id_epis_triage    IN NUMBER,
        i_code_triage_color IN VARCHAR2,
        i_flg_type          IN VARCHAR2,
        i_code_accuity      IN VARCHAR2,
        i_id_triage_type    IN NUMBER,
        i_id_triage_color   NUMBER,
        i_msg               IN VARCHAR2
    ) RETURN VARCHAR2;


    FUNCTION is_unknown
    (
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_vs_pain
    (
        i_episode IN NUMBER,
        i_mode    IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION admission_reason(i_episode IN NUMBER) RETURN CLOB;

    FUNCTION get_origin
    (
        i_lang    IN NUMBER,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_admission_ward
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER
    ) RETURN VARCHAR2;


    FUNCTION get_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_outpatient;

    FUNCTION get_outpatient_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_outpatient_base;

    FUNCTION get_clinical_serv_desc
    (
        i_lang             IN NUMBER,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_mother_epis_doc_deliv_type
    (
        i_episode      IN NUMBER,
        i_pat_pregancy IN NUMBER
    ) RETURN NUMBER;

    FUNCTION get_discharge_destination
    (
        i_lang           IN NUMBER,
        i_id_destination IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION is_smoker(i_patient IN NUMBER) RETURN VARCHAR2;

    FUNCTION ifnull_tstz
    (
        i_episode IN NUMBER,
        i_date    IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    FUNCTION ifnull_vc2
    (
        i_episode IN NUMBER,
        i_value   IN VARCHAR2
    ) RETURN VARCHAR2;

    FUNCTION get_inst_name
    (
        i_lang IN NUMBER,
        i_inst IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_bed_status
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_flg_bed_ocupacity_status IN VARCHAR2,
        i_flg_bed_status           IN VARCHAR2,
        i_mode                     IN VARCHAR2 DEFAULT k_bed_status_desc
    ) RETURN VARCHAR2;

    FUNCTION format_date
    (
        i_prof IN profissional,
        i_dt   IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2;

    FUNCTION get_epis_doc_component_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL,
        i_is_bold            IN VARCHAR2 DEFAULT NULL,
        i_has_title          IN VARCHAR2 DEFAULT pk_alert_constant.g_yes
    ) RETURN VARCHAR2;

    FUNCTION get_trans_desc
    (
        i_lang             IN NUMBER,
        i_id_transp_entity IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_discharge_destination_desc
    (
        i_lang              IN NUMBER,
        i_id_discharge_dest IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_patient_type_desc
    (
        i_lang         IN NUMBER,
        i_patient_type IN VARCHAR2
    ) RETURN VARCHAR2;

    --****************************************************
    FUNCTION get_diag_secondary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;
    --****************************************************
    FUNCTION get_diag_primary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;
    --****************************************************
    FUNCTION get_diag_initial_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;
    --****************************************************
    FUNCTION get_diag_final_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_complaints
    (
        i_lang    IN language.id_language%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN CLOB;

    FUNCTION get_major_incident(i_id_episode IN NUMBER) RETURN VARCHAR2;
	
	--***************************************
    PROCEDURE date_processing
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_dt_ini IN VARCHAR2,
        i_dt_end IN VARCHAR2,
        o_dt_ini OUT death_registry.dt_death%TYPE,
        o_dt_end OUT death_registry.dt_death%TYPE
    );

    --******************************************************
    FUNCTION get_patient_docid
    (
        i_prof    IN profissional,
        i_patient IN NUMBER
    ) RETURN VARCHAR2;

    --**********************************
    FUNCTION get_arrival_method_id
    (
        i_id_arrival_method IN NUMBER,
        i_id_episode        IN NUMBER
    ) RETURN NUMBER;

    --************************************************************
    FUNCTION get_death_cause
    (
        i_motive            IN VARCHAR2,
        i_id_death_registry IN NUMBER
    ) RETURN VARCHAR2;

    --************************************************************
    FUNCTION get_death_place
    (
        i_place             IN VARCHAR2,
        i_id_death_registry IN NUMBER
    ) RETURN VARCHAR2;

    -- *************************
    FUNCTION get_treatment_physicians_id
    (
        i_lang    IN NUMBER,
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2;

    --****************************************
    FUNCTION get_emergency_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_emergency_base;

    -- ***************************************************************
    FUNCTION get_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emergency;

    --****************************************
    FUNCTION get_inpatient_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_inpatient_base;

    FUNCTION get_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_inpatient;

    --**********************************************
    FUNCTION get_birth_type
    (
        i_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_doc_int_name       IN documentation.internal_name%TYPE DEFAULT NULL
    ) RETURN VARCHAR2;

    FUNCTION set_mrn_null_on_unoccupied
    (
        i_code IN VARCHAR2,
        i_mrn  IN VARCHAR2
    ) RETURN VARCHAR2;

    -- ************************************************
    FUNCTION get_emr_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient;

    -- ***************************************************************
    FUNCTION get_emr_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency;

    -- ************************************************
    FUNCTION get_emr_outpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient_plus;

    --********************************************************
    FUNCTION get_outp_department
    (
        i_lang IN NUMBER,
        i_dcs  IN NUMBER
    ) RETURN VARCHAR2;

    --******************************************************************
    FUNCTION get_img_state
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_dcs       IN NUMBER,
        i_flg_ehr   IN VARCHAR2,
        i_flg_state IN VARCHAR2
    ) RETURN VARCHAR2;

    -- ***************************************************************
    FUNCTION get_emr_emergency_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency_plus;

    --****************************************
    FUNCTION get_emr_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient;

    --****************************************
    FUNCTION get_emr_inpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient_plus;

    FUNCTION get_disp_transf_reopen
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    --****************************************
    FUNCTION get_consult_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_consult_base;

    --****************************************
    FUNCTION get_emr_consult
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult;

    -- ***************************************************************
    FUNCTION get_emr_consult_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult_plus;

    --****************************************
    FUNCTION get_transfer_base
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_dt_end      IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN t_tbl_data_transfer_base;

    FUNCTION get_emr_transfer
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer;

    --****************************************
    FUNCTION get_emr_transfer_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer_plus;

END pk_data_access_cdoc;
/
