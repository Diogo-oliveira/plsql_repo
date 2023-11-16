/*-- Last Change Revision: $Rev: 1939707 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2020-03-11 21:56:11 +0000 (qua, 11 mar 2020) $*/
CREATE OR REPLACE PACKAGE BODY pk_hhc_api IS

    -- Private variable declarations
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

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
    ) RETURN BOOLEAN IS
        --l_func_name CONSTANT VARCHAR2(25 CHAR) := 'get_approved_epis_hhc_req';
    BEGIN
    
        RETURN pk_hhc_core.get_approved_epis_hhc_req(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_tbl_inst          => i_tbl_inst,
                                                     i_id_patient        => i_id_patient,
                                                     i_id_prof_requested => i_id_prof_requested,
                                                     i_age_min       => i_age_min,
                                                     i_age_max       => i_age_max,
                                                     i_gender        => i_gender,
                                                     i_page          => i_page,
                                                     i_rows_per_page => i_rows_per_page,
                                                     o_data          => o_data,
                                                     o_row_count     => o_row_count,
                                                     o_error         => o_error);
    
    END get_approved_epis_hhc_req;

    FUNCTION get_hhc_process_with_team
    (
	i_lang           IN language.id_language%TYPE,
	i_prof           IN profissional,
	i_patient        IN NUMBER,
        i_tbl_inst       IN table_number,
	o_id_hhc_episode OUT NUMBER,
	o_id_prof_team   OUT table_number,
	o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
	tbl_team         table_number := table_number();
	l_id_hhc_episode NUMBER;
	l_id_hhc_req     epis_hhc_req.id_epis_hhc_req%TYPE;
    BEGIN

        IF pk_hhc_core.check_approved_request(i_patient => i_patient) = pk_alert_constant.g_yes
        THEN
	l_id_hhc_episode := pk_hhc_core.get_active_hhc_episode(i_patient => i_patient);

            --        l_id_hhc_req := pk_hhc_core.get_id_epis_hhc_req_by_epis(i_id_episode => l_id_hhc_episode);
	l_id_hhc_req := pk_hhc_core.get_id_hhc_req_by_epis(i_id_episode => l_id_hhc_episode);

	tbl_team := pk_hhc_core.get_team_id_professional(i_lang       => i_lang,
													 i_prof       => i_prof,
                                                         i_tbl_inst   => i_tbl_inst,
													 i_id_hhc_req => l_id_hhc_req);

	o_id_hhc_episode := l_id_hhc_episode;
	o_id_prof_team   := tbl_team;

        END IF;
    
	RETURN TRUE;

EXCEPTION
	WHEN OTHERS THEN
		pk_alert_exceptions.process_error(i_lang     => i_lang,
										  i_sqlcode  => SQLCODE,
										  i_sqlerrm  => SQLERRM,
										  i_message  => g_error,
										  i_owner    => g_owner,
										  i_package  => g_package,
										  i_function => 'get_hhc_process_with_team',
										  o_error    => o_error);
		RETURN FALSE;
END get_hhc_process_with_team;
    
BEGIN
    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_hhc_api;
/
