CREATE OR REPLACE PACKAGE pk_hhc_api IS

    -- Author  : VITOR.SA
    -- Created : 20/01/2020 14:48:50
    -- Purpose : hhc api

    FUNCTION get_approved_epis_hhc_req
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_tbl_inst          IN table_number,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_prof_requested IN epis_hhc_req.id_prof_manager%TYPE,
        i_age_min       IN NUMBER,
        i_age_max       IN NUMBER,
        i_gender        IN VARCHAR2,
        i_page          IN NUMBER DEFAULT 1,
        i_rows_per_page IN NUMBER DEFAULT 20,
        o_data          OUT t_wl_search_row_coll,
        o_row_count     OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hhc_process_with_team
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_patient        IN NUMBER,
        i_tbl_inst       IN table_number,
        o_id_hhc_episode OUT NUMBER,
        o_id_prof_team   OUT table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;
    
END pk_hhc_api;
/
