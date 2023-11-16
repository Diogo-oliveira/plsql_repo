/*-- Last Change Revision: $Rev: 2050738 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-22 15:28:22 +0000 (ter, 22 nov 2022) $*/

CREATE OR REPLACE PACKAGE pk_data_access IS

    k_default_software CONSTANT NUMBER := 0;

    PROCEDURE date_processing
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_dt_ini IN VARCHAR2,
        i_dt_end IN VARCHAR2,
        o_dt_ini OUT death_registry.dt_death%TYPE,
        o_dt_end OUT death_registry.dt_death%TYPE
    );

    FUNCTION get_process
    (
        i_patient     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2;

    FUNCTION get_death_diag_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emergency;

    FUNCTION get_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_inpatient;

    FUNCTION get_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_outpatient;

    FUNCTION get_surgery
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery;

    FUNCTION get_surgery_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_laparoscopy
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery;

    FUNCTION get_catheterization
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery;

    FUNCTION get_dialysis
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_dialysis;

    FUNCTION get_procedure
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_procedure;

    FUNCTION get_laboratory
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_laboratory;

    FUNCTION get_laboratory_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_radiology
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_radiology;

    FUNCTION get_radiology_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    FUNCTION get_blood_bank
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_blood_products;

    FUNCTION get_child_birth
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_data_child_birth;

    FUNCTION get_deaths
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_death;

    FUNCTION get_all_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_beds;

    FUNCTION get_total_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_total_beds;

    FUNCTION get_diag_final_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_diag_initial_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_diag_primary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION get_diag_secondary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2;

    FUNCTION array_to_var(i_tbl IN table_varchar) RETURN VARCHAR2;

    -- ************************************************
    FUNCTION get_emr_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient;

    -- ************************************************
    FUNCTION get_emr_outpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient_plus;

    -- ***************************************************************
    FUNCTION get_emr_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency;


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

    FUNCTION get_emr_transfer
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer;

    -- ***************************************************************
    FUNCTION get_emr_transfer_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer_plus;

END pk_data_access;
/
