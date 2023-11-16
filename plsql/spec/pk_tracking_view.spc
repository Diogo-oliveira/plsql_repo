/*-- Last Change Revision: $Rev: 2029018 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:19 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_tracking_view IS

    -- Author  : João Eiras
    -- Created : 26-03-2007 8:57:36
    -- Purpose : EDIS Tracking View Package

    /*
    * This function reads all the necessary information in order to fill the EDIS Tracking View grid
    * (non-anonymous mode)
    *
    * @author João Eiras
    *
    * @version 2.4.4
    *
    * @param i_lang language's id
    * @param i_instituition target institution's id
    * @param i_room selected room's id. Optional
    * @param i_flg_view View's type. valroes possiveis V1, V2
    * @param o_rows results cursor
    * @param o_dt_server server date
    * @param o_error error message
    *
    * @value i_flg_view {*} 'V1' first view {*} 'V2' second view
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_edis_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR2,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * This function reads all the necessary information in order to fill the Tracking View grid
    * (non-anonymous mode)
    *
    * @author Fábio Oliveira
    *
    * @version 2.5
    *
    * @param i_lang language's id
    * @param i_prof professional info
    * @param i_room selected room's id. Optional
    * @param i_flg_view View's type. valroes possiveis V1, V2
    * @param o_rows results cursor
    * @param o_dt_server server date
    * @param o_error error message
    *
    * @value i_flg_view {*} 'V1' first view {*} 'V2' second view
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_edis_epis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_room      IN room.id_room%TYPE,
        i_flg_view  IN VARCHAR2,
        o_rows      OUT pk_types.cursor_type,
        o_dt_server OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * This function reads all the necessary information in order to fill the Tracking View grid
    * (anonymous mode)
    *
    * @author Fábio Oliveira
    *
    * @version 2.5
    *
    * @param i_lang language's id
    * @param i_instituition target institution's id
    * @param i_room selected room's id. Optional
    * @param i_flg_view View's type. valroes possiveis V1, V2
    * @param o_rows results cursor
    * @param o_dt_server server date
    * @param o_error error message
    *
    * @value i_flg_view {*} 'V1' first view {*} 'V2' second view
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_edis_epis_out
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR2,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * This function reads all the necessary information in order to fill the INP Tracking View grid
    *
    * @author João Eiras
    *
    * @version 2.4.4
    *
    * @param i_lang language's id
    * @param i_instituition target institution's id
    * @param i_room selected room's id. Optional
    * @param i_flg_view View's type. valroes possiveis V1, V2
    * @param o_rows results cursor
    * @param o_dt_server server date
    * @param o_error error message
    *
    * @value i_flg_view {*} 'V1' first view {*} 'V2' second view
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_inp_epis
    (
        i_lang          IN language.id_language%TYPE,
        i_institution   IN institution.id_institution%TYPE,
        i_room          IN room.id_room%TYPE,
        i_flg_view      IN VARCHAR,
        i_id_department IN department.id_department%TYPE,
        o_rows          OUT pk_types.cursor_type,
        o_dt_server     OUT VARCHAR2,
        o_label         OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lists all emergency rooms showing the number of patients currently inside them.
    *
    * @param i_lang language's id
    * @param i_instituition target institution's id
    * @param o_rows results cursor
    * @param o_error error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_edis_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_all_edis_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * Lists all inpatient rooms showing the number of patients currently inside them.
    *
    * @param i_lang language's id
    * @param i_instituition target institution's id
    * @param o_rows results cursor
    * @param o_error error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_all_inp_rooms_pats
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_department  IN department.id_department%TYPE,
        o_rows        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lists all the triage colors and the quantity of patients for each in the selected room
    *
    * @param i_lang         language's id
    * @param i_instituition target institution's id
    * @param i_software     software's id (for selecting the correct triage colors)
    * @param i_room         selected room's id
    * @param o_head_col     results cursor
    * @param o_error        error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_chart_header
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_head_col    OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lists all the emergency episodes in a given room in order to show in a vertical time graph
    *
    * @param i_lang         language's id
    * @param i_instituition target institution's id
    * @param i_software     software's id
    * @param i_room         selected room's id
    * @param o_grid         results cursor
    * @param o_error        error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_chart_all_pat_edis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lists all the inpatient episodes in a given room in order to show in a vertical time graph
    *
    * @param i_lang         language's id
    * @param i_instituition target institution's id
    * @param i_software     software's id
    * @param i_room         selected room's id
    * @param o_grid         results cursor
    * @param o_error        error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_chart_all_pat_inp
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        i_prof        IN profissional,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Lists all the inpatient episodes in a given room in order to show in a vertical time graph
    *
    * @param i_lang         language's id
    * @param i_instituition target institution's id
    * @param i_software     software's id
    * @param i_room         selected room's id
    * @param o_grid         results cursor
    * @param o_error        error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_chart_all_pat_inp
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_sr_grid_tracking_view
    (
        i_lang         IN language.id_language%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_room         IN VARCHAR2,
        i_pat_states   IN VARCHAR2,
        i_page         IN NUMBER,
        i_id_room      IN room.id_room%TYPE,
        i_waiting_room IN VARCHAR2,
        o_grid         OUT pk_types.cursor_type,
        o_room_list    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Returns a room's name
    *
    * @param i_lang         language's id
    * @param i_room         selected room's id
    * @param o_room_desc room's name
    * @param o_error        error message
    *
    * @return success (true) or fail (false)
    *
    */

    FUNCTION get_room_desc
    (
        i_lang      IN language.id_language%TYPE,
        i_room      IN room.id_room%TYPE,
        o_room_desc OUT VARCHAR2,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    -- Auxiliary functions

    /*
    * Formats the text to be included in the column "Destination"
    *
    * @param i_lang            language's id
    * @param i_prof            professional's related data (ID, Institution and Software)
    * @param i_episode         Episode ID
    * @param i_disch_reas_dest Discharge reason and destination ID
    * @param i_flg_status      Discharge status
    *
    * @return Formatted text (discharge department or consultation specialties)
    *
    * @author  José Silva
    * @since   27-09-2010
    * @version 2.5.0.7.8
    *
    */

    FUNCTION get_epis_destination
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_disch_reas_dest IN epis_info.id_disch_reas_dest%TYPE,
        i_flg_status      IN epis_info.flg_dsch_status%TYPE
    ) RETURN VARCHAR2;

    /*
    * Formats analysis information to show on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_row  (TRACKING_BOARD_EA rowid) most urgent analysis in the specified state
    *
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author Alexandre Santos
    *
    * @version 2.6.1.2
    *
    */

    FUNCTION get_epis_lab_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2;

    /*
    * Formats exams information to show on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_row  (TRACKING_BOARD_EA rowid) most urgent exams in the specified state
    *
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author Alexandre Santos
    *
    * @version 2.6.1.2
    *
    */

    FUNCTION get_epis_exam_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2;

    /*
    * Formats exams information to show on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_row  (TRACKING_BOARD_EA rowid) most urgent exams in the specified state
    *
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author Teresa Coutinho
    *
    * @version 2.6.3.8.2 - UK request
    *
    */

    FUNCTION get_epis_oth_exam_desc
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_row  IN ROWID
    ) RETURN VARCHAR2;

    /*
    * Returns episode's monitorizations information like it will be shown on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_episode episode's id from which the data will be gathered
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author João Eiras
    *
    * @version 2.4.4
    *
    */

    FUNCTION get_epis_monit_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*
    * Returns episode's drug prescriptions information like it will be shown on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_episode episode's id from which the data will be gathered
    * @param i_external_tr external tracking view (Y) Yes (N) No
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author João Eiras
    *
    * @version 2.4.4
    *
    */

    FUNCTION get_epis_drug_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_external_tr IN VARCHAR2
    ) RETURN VARCHAR2;

    /*
    * Returns episode's procedures and wounds information like it will be shown on Tracking View.
    *
    * @param i_lang language's id
    * @param i_prof professional's related data (ID, Institution and Software)
    * @param i_episode episode's id from which the data will be gathered
    * @return information with the folowing format: DATE|TYPE|COLOR|TEXT/ICON_NAME[;...]
    *
    * @author João Eiras
    *
    * @version 2.4.4
    *
    */

    FUNCTION get_epis_interv_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /*
    * Calls PK_MESSAGE.GET_MESSAGE_ARRAY. This is only an interface function as PK_MESSAGE is not a public service
    *
    * @param i_lang language's id
    * @param i_code_msg_arr Array containing the required messages codes
    *
    * @param o_desc_msg_arr Response array containing the messages
    * @return success (true) or fail (false)
    *
    * @author João Eiras
    *
    * @version 2.4.2
    *
    */

    FUNCTION get_message_array
    (
        i_lang         IN NUMBER,
        i_code_msg_arr IN table_varchar,
        o_desc_msg_arr OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    /*
    * Calls PK_SYSCONFIG.GET_CONFIG. This is only an interface function as PK_SYSCONFIG is not a public service
    *
    * @param i_code_cf config id
    * @param i_institution institution for where the configuration is to be retrieved
    *
    * @param o_msg_cf Response containing the configured value
    * @return success (true) or fail (false)
    *
    * @author Fábio Oliveira
    *
    * @version 2.5
    *
    */

    FUNCTION get_config
    (
        i_code_cf     IN VARCHAR2,
        i_institution IN NUMBER,
        o_msg_cf      OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Calls PK_EDIS_GRID.GET_GRID_LABELS. This is only an interface function as PK_EDIS_GRID is not a public service
    *   
    * @param i_lang                   language IDn
    * @param i_prof                   professional, software and institution ids
    * @param o_label_tb_name_col      Tracking view: label for the patient's name column showing origin or chief complaint
    * @param o_label_responsibles     Label for the patient's responsibles, showing medical teams or the resident physician
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *
    * @author                         José Brito
    * @version                        2.6.0.5
    * @since                          2011/01/26
    */

    FUNCTION get_grid_labels
    (
        i_lang               IN language.id_language%TYPE,
        i_institution        IN NUMBER,
        o_label_tb_name_col  OUT VARCHAR2,
        o_label_responsibles OUT VARCHAR2
    ) RETURN BOOLEAN;

    /*
    * Returns all available icons for VIP patients
    *
    * @param i_lang                language id
    * @param o_vip_icons           Cursor with VIP icons
    * @param o_error               Error out        
    * @return                      true (sucess), false (error)
    *
    * @author                      Luís Maia
    * @since                       2010/01/25
    * @version                     2.6
    */

    FUNCTION get_vip_icons
    (
        i_lang      IN language.id_language%TYPE,
        o_vip_icons OUT NOCOPY pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    /*
    * Calls PK_SYSCONFIG.GET_CONFIG. This is only an interface function as PK_SYSCONFIG is not a public service
    *
    * @param i_code_cf config id
    * @param i_institution institution for where the configuration is to be retrieved
    *
    * @param o_msg_cf Response containing the configured value
    * @return success (true) or fail (false)
    *
    * @author Elisabete Bugalho
    *
    * @version 2.6.1.13
    *
    */

    FUNCTION get_config
    (
        i_code_cf     IN table_varchar,
        i_institution IN NUMBER,
        i_software    IN NUMBER,
        o_msg_cf      OUT pk_types.cursor_type
    ) RETURN BOOLEAN;

    FUNCTION get_chart_all_pat_edis
    (
        i_lang        IN language.id_language%TYPE,
        i_institution IN institution.id_institution%TYPE,
        i_software    IN software.id_software%TYPE,
        i_room        IN room.id_room%TYPE,
        o_grid        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_epis_destination_int
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_disch_reas_dest IN epis_info.id_disch_reas_dest%TYPE,
        i_flg_status      IN epis_info.flg_dsch_status%TYPE,
        o_dest_partial    OUT table_varchar,
        o_dest_full       OUT table_varchar,
        o_disch           OUT VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_status_string
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_display_type IN VARCHAR2,
        i_value_date   IN VARCHAR2,
        i_value_icon   IN VARCHAR2,
        i_color        IN VARCHAR2,
        i_shortcut     IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2;

    /*
    * Verify if flg_letter is to be used in the ORDER BY clause.
    *   
    * @param i_prof                   professional, software and institution ids
    *
    * @return                         'Y' is to be used, 'N' otherwise
    *                        
    * @author                         Alexandre Santos
    * @version                        1.0 
    * @since                          2009/05/14
    */

    FUNCTION orderby_flg_letter(i_prof IN profissional) RETURN VARCHAR2;

    PROCEDURE init_params_patient_grids
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    g_package_owner VARCHAR2(50 CHAR);
    g_package_name  VARCHAR2(50 CHAR);

    g_user_exception  EXCEPTION;
    g_other_exception EXCEPTION;
    g_error      VARCHAR2(4000);
    g_error_code VARCHAR2(100);

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_found        BOOLEAN;
    g_cf_pat_gender_abbr CONSTANT sys_config.id_sys_config%TYPE := 'PATIENT.GENDER.ABBR';
    g_icon_ft            CONSTANT VARCHAR2(1) := 'F';
    g_icon_ft_transfer   CONSTANT VARCHAR2(1) := 'T';
    g_desc_header        CONSTANT VARCHAR2(1) := 'H';
    g_desc_grid          CONSTANT VARCHAR2(1) := 'G';
    g_ft_color           CONSTANT VARCHAR2(200) := '0xFFFFFF';
    g_ft_triage_white    CONSTANT VARCHAR2(200) := '0x787864';
    g_ft_status          CONSTANT VARCHAR2(1) := 'A';
    --Handoff responsabilities constants
    g_show_in_grid    CONSTANT VARCHAR2(1) := 'G';
    g_show_in_tooltip CONSTANT VARCHAR2(1) := 'T';
END pk_tracking_view;
/
