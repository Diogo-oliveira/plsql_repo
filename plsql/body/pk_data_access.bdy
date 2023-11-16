/*-- Last Change Revision: $Rev: 2050733 $*/
/*-- Last Change by: $Author: carlos.ferreira $*/
/*-- Date of last change: $Date: 2022-11-22 15:26:24 +0000 (ter, 22 nov 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_data_access IS

    FUNCTION get_death_diag_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_diag_death_icd_code(i_episode);
    
    END get_death_diag_icd_code;

    FUNCTION get_process
    (
        i_patient     IN NUMBER,
        i_institution IN NUMBER
    ) RETURN VARCHAR2 IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_process(i_patient => i_patient, i_institution => i_institution);
    
    END get_process;

    FUNCTION process_base_date
    (
        i_lang IN NUMBER,
        i_prof IN profissional,
        i_dt   IN VARCHAR2
    ) RETURN death_registry.dt_death%TYPE IS
    
        l_return death_registry.dt_death%TYPE;
    
    BEGIN
    
        l_return := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                  i_prof      => i_prof,
                                                  i_timestamp => i_dt,
                                                  i_timezone  => '',
                                                  i_mask      => 'yyyy-mm-dd');
    
        l_return := pk_date_utils.trunc_insttimezone(i_prof, l_return);
    
        RETURN l_return;
    
    END process_base_date;

    PROCEDURE date_processing
    (
        i_lang   IN NUMBER,
        i_prof   IN profissional,
        i_dt_ini IN VARCHAR2,
        i_dt_end IN VARCHAR2,
        o_dt_ini OUT death_registry.dt_death%TYPE,
        o_dt_end OUT death_registry.dt_death%TYPE
    ) IS
    
        l_dt_ini death_registry.dt_death%TYPE;
        l_dt_end death_registry.dt_death%TYPE;
    
    BEGIN
    
        IF i_dt_ini IS NOT NULL
        THEN
            l_dt_ini := process_base_date(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_ini);
            l_dt_ini := pk_date_utils.trunc_insttimezone(i_prof, l_dt_ini);
        ELSE
            l_dt_ini := pk_date_utils.trunc_insttimezone(i_prof, current_timestamp);
            l_dt_ini := l_dt_ini - numtodsinterval(1, 'DAY');
        END IF;
    
        IF i_dt_end IS NOT NULL
        THEN
            l_dt_end := process_base_date(i_lang => i_lang, i_prof => i_prof, i_dt => i_dt_end);
        ELSE
            l_dt_end := current_timestamp;
        END IF;
    
        l_dt_end := pk_date_utils.trunc_insttimezone(i_prof, l_dt_end);
        l_dt_end := l_dt_end + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND');
    
        o_dt_ini := l_dt_ini;
        o_dt_end := l_dt_end;
    
    END date_processing;

    FUNCTION get_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emergency IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emergency(i_institution => i_institution,
                                                 i_dt_ini      => i_dt_ini,
                                                 i_dt_end      => i_dt_end);
    
    END get_emergency;

    FUNCTION get_emr_emergency
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_emergency(i_institution => i_institution,
                                                     i_dt_ini      => i_dt_ini,
                                                     i_dt_end      => i_dt_end);
    
    END get_emr_emergency;

    FUNCTION get_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_inpatient IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_inpatient(i_institution => i_institution,
                                                 i_dt_ini      => i_dt_ini,
                                                 i_dt_end      => i_dt_end);
    
    END get_inpatient;

    FUNCTION get_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_outpatient IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_outpatient(i_institution => i_institution,
                                                  i_dt_ini      => i_dt_ini,
                                                  i_dt_end      => i_dt_end);
    
    END get_outpatient;

    FUNCTION get_emr_outpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_outpatient(i_institution => i_institution,
                                                      i_dt_ini      => i_dt_ini,
                                                      i_dt_end      => i_dt_end);
    
    END get_emr_outpatient;

    FUNCTION get_emr_outpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_outpatient_plus IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_outpatient_plus(i_institution => i_institution,
                                                           i_dt_ini      => i_dt_ini,
                                                           i_dt_end      => i_dt_end);
    
    END get_emr_outpatient_plus;

    FUNCTION get_surgery
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_surgery(i_institution => i_institution,
                                                 i_dt_ini      => i_dt_ini,
                                                 i_dt_end      => i_dt_end,
                                                 i_data        => i_data);
    
    END get_surgery;

    FUNCTION get_surgery_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_surgery_count(i_institution => i_institution,
                                                       i_dt_ini      => i_dt_ini,
                                                       i_dt_end      => i_dt_end,
                                                       i_data        => i_data);
    
    END get_surgery_count;

    FUNCTION get_laparoscopy
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery AS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_laparoscopy(i_institution => i_institution,
                                                     i_dt_ini      => i_dt_ini,
                                                     i_dt_end      => i_dt_end,
                                                     i_data        => i_data);
    
    END get_laparoscopy;

    FUNCTION get_catheterization
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery AS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_catheterization(i_institution => i_institution,
                                                         i_dt_ini      => i_dt_ini,
                                                         i_dt_end      => i_dt_end,
                                                         i_data        => i_data);
    END get_catheterization;

    FUNCTION get_dialysis
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_dialysis IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_dialysis(i_institution => i_institution,
                                                  i_dt_ini      => i_dt_ini,
                                                  i_dt_end      => i_dt_end,
                                                  i_data        => i_data);
    
    END get_dialysis;

    FUNCTION get_procedure
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_procedure IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_procedure(i_institution => i_institution,
                                                   i_dt_ini      => i_dt_ini,
                                                   i_dt_end      => i_dt_end);
    
    END get_procedure;

    FUNCTION get_laboratory
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_laboratory IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_laboratory(i_institution => i_institution,
                                                    i_dt_ini      => i_dt_ini,
                                                    i_dt_end      => i_dt_end);
    
    END get_laboratory;

    FUNCTION get_laboratory_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_laboratory_count(i_institution => i_institution,
                                                          i_dt_ini      => i_dt_ini,
                                                          i_dt_end      => i_dt_end);
    
    END get_laboratory_count;

    FUNCTION get_radiology
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_radiology IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_radiology(i_institution => i_institution,
                                                   i_dt_ini      => i_dt_ini,
                                                   i_dt_end      => i_dt_end);
    
    END get_radiology;

    FUNCTION get_radiology_count
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_radiology_count(i_institution => i_institution,
                                                         i_dt_ini      => i_dt_ini,
                                                         i_dt_end      => i_dt_end);
    
    END get_radiology_count;

    FUNCTION get_blood_bank
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_blood_products IS
    
    BEGIN
    
        RETURN pk_data_access_orders.get_blood_bank(i_institution => i_institution,
                                                    i_dt_ini      => i_dt_ini,
                                                    i_dt_end      => i_dt_end);
    
    END get_blood_bank;

    FUNCTION get_child_birth
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_data_child_birth IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_child_birth(i_institution => i_institution,
                                                   i_dt_ini      => i_dt_ini,
                                                   i_dt_end      => i_dt_end);
    
    END get_child_birth;

    --**********************************************************
    -- select * from table(pk_data_access.get_list_deaths( 11111, '01-09-2018', '30-09-2019' ))
    --************************************************************

    FUNCTION get_deaths
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_death IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_deaths(i_institution => i_institution,
                                              i_dt_ini      => i_dt_ini,
                                              i_dt_end      => i_dt_end);
    
    END get_deaths;

    FUNCTION get_all_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_beds IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_all_beds(i_institution => i_institution);
    
    END get_all_beds;

    FUNCTION get_total_beds(i_institution IN institution.id_institution%TYPE DEFAULT NULL) RETURN t_table_bmng_total_beds IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_total_beds(i_institution => i_institution);
    
    END get_total_beds;

    FUNCTION get_diag_final_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_diag_final_icd_code(i_episode => i_episode);
    
    END get_diag_final_icd_code;

    FUNCTION get_diag_initial_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_diag_initial_icd_code(i_episode => i_episode);
    
    END get_diag_initial_icd_code;

    FUNCTION get_diag_primary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_diag_primary_icd_code(i_episode => i_episode);
    
    END get_diag_primary_icd_code;

    FUNCTION get_diag_secondary_icd_code(i_episode IN NUMBER) RETURN VARCHAR2 IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_diag_secondary_icd_code(i_episode => i_episode);
    
    END get_diag_secondary_icd_code;

    FUNCTION array_to_var(i_tbl IN table_varchar) RETURN VARCHAR2 IS
    
        k_hard_limit CONSTANT NUMBER := 4000;
        k_more       CONSTANT VARCHAR2(0050 CHAR) := '(...)';
        k_sep        CONSTANT VARCHAR2(0050 CHAR) := '|';
        k_max_byte   CONSTANT NUMBER := k_hard_limit - lengthb(k_sep) - lengthb(k_more);
        l_return VARCHAR2(4000);
    
        l_sep VARCHAR2(0010 CHAR);
        l_len NUMBER := 0;
    
    BEGIN
    
        <<lup_thru_elements>>
        FOR i IN 1 .. i_tbl.count
        LOOP
        
            l_sep := k_sep;
            IF i = 1
            THEN
                l_sep := '';
            END IF;
        
            l_len := 0;
            l_len := l_len + coalesce(lengthb(l_return), 0);
            l_len := l_len + coalesce(lengthb(l_sep), 0);
            l_len := l_len + lengthb(i_tbl(i));
        
            IF l_len < k_max_byte
            THEN
            
                l_return := l_return || l_sep || i_tbl(i);
            ELSE
                l_return := l_return || k_more;
                EXIT lup_thru_elements;
            END IF;
        
        END LOOP lup_thru_elements;
    
        RETURN l_return;
    
    END array_to_var;

    FUNCTION get_emr_emergency_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_emergency_plus IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_emergency_plus(i_institution => i_institution,
                                                          i_dt_ini      => i_dt_ini,
                                                          i_dt_end      => i_dt_end);
    
    END get_emr_emergency_plus;

    FUNCTION get_emr_inpatient_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient_plus IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_inpatient_plus(i_institution => i_institution,
                                                          i_dt_ini      => i_dt_ini,
                                                          i_dt_end      => i_dt_end);
    
    END get_emr_inpatient_plus;

    FUNCTION get_emr_inpatient
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_inpatient IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_inpatient(i_institution => i_institution,
                                                           i_dt_ini      => i_dt_ini,
                                                           i_dt_end      => i_dt_end);
    
    END get_emr_inpatient;

    FUNCTION get_emr_consult
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult IS
    
    BEGIN

        RETURN pk_data_access_cdoc.get_emr_consult(i_institution => i_institution,
                                                      i_dt_ini      => i_dt_ini,
                                                      i_dt_end      => i_dt_end);

    END get_emr_consult;

    -- ***************************************************************
    FUNCTION get_emr_consult_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_consult_plus IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_consult_plus(i_institution => i_institution,
                                                        i_dt_ini      => i_dt_ini,
                                                        i_dt_end      => i_dt_end);
    
    END get_emr_consult_plus;

    FUNCTION get_emr_transfer
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer IS
    
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_transfer(i_institution => i_institution,
                                                    i_dt_ini      => i_dt_ini,
                                                    i_dt_end      => i_dt_end);
    
    END get_emr_transfer;

    -- ***************************************************************
    FUNCTION get_emr_transfer_plus
    (
        i_institution IN NUMBER DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_tbl_data_emr_transfer_plus IS
    BEGIN
    
        RETURN pk_data_access_cdoc.get_emr_transfer_plus(i_institution => i_institution,
                                                         i_dt_ini      => i_dt_ini,
                                                         i_dt_end      => i_dt_end);
    
    END get_emr_transfer_plus;

END pk_data_access;
/
