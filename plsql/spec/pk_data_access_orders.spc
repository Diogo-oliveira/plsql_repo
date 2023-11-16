CREATE OR REPLACE PACKAGE pk_data_access_orders IS

    FUNCTION get_blood_bank
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL
    ) RETURN t_table_blood_products;

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

    FUNCTION get_catheterization
    (
        i_institution IN institution.id_institution%TYPE DEFAULT NULL,
        i_dt_ini      IN VARCHAR2 DEFAULT NULL,
        i_dt_end      IN VARCHAR2 DEFAULT NULL,
        i_data        IN table_varchar DEFAULT NULL
    ) RETURN t_table_surgery;

    FUNCTION get_laparoscopy
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

END pk_data_access_orders;
/
