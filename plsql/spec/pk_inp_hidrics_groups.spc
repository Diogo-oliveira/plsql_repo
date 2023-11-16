/*-- Last Change Revision: $Rev: 1510000 $*/
/*-- Last Change by: $Author: sofia.mendes $*/
/*-- Date of last change: $Date: 2013-10-03 08:20:55 +0100 (qui, 03 out 2013) $*/
CREATE OR REPLACE PACKAGE pk_inp_hidrics_groups IS

    -- Author  : SOFIA.MENDES
    -- Created : 05-09-2013 08:50:07
    -- Purpose : This packages contains the intake and output logic associated with groups

    /*******************************************************************************************************************************************
    * set_hidrics_group               Creates a new hidrics group
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE that should be associated with current request
    * @param i_epis_hidrics           Epis hidrics id
    * @param i_epis_hidrics_line      Epis hidrics line ID
    * @param i_group_desc             Group description
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.3.8
    * @since                          2013/09/05
    *******************************************************************************************************************************************/
    FUNCTION set_irrigation_group
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics          IN epis_hidrics.id_epis_hidrics%TYPE,
        i_epis_hidrics_line     IN table_number,
        i_id_epis_hidrics_group IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * set_hidrics_group               Creates a new hidrics group
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param I_EPISODE                ID_EPISODE that should be associated with current request
    * @param i_epis_hidrics           Epis hidrics id
    * @param i_epis_hidrics_line      Epis hidrics line ID
    * @param i_group_desc             Group description
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.3.8
    * @since                          2013/09/05
    *******************************************************************************************************************************************/
    FUNCTION set_hidrics_group
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN table_number,
        i_group_desc            IN epis_hidrics_group.group_desc%TYPE,
        i_id_epis_hidrics_group IN epis_hidrics_group.id_epis_hidrics_group%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets ways, locations, fluids ans characterization cursors used to fill multichoice lists for irrigation:
    * input parameter and output parameter
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_epis_hid                  Epis hidrics id
    * @param   i_hid_flg_type              Hidrics flg_type (Administration or Elimination)
    * Intake
    * @param   i_way_int                   Way id intake
    * @param   i_body_part_int             Body part id intake
    * @param   i_body_side_int             Body side id intake
    * @param   i_hidrics_int               Hidric id intake
    * @param   i_hidrics_charact_int       Hidric charateristic id intake
    * @param   i_flg_bodypart_ftxt_int     Y- the body part was defined by free text. N-otherwise intake
    * @param   i_old_hidrics_int           Id hidrics of the registry being edited intake
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_int          Y - the nr of occurrences has been filled by the user; N - otherwise
    * Output
    * @param   i_way_out                   Way id output
    * @param   i_body_part_out             Body part id output
    * @param   i_body_side_out             Body side id output
    * @param   i_hidrics_out               Hidric id output
    * @param   i_hidrics_charact_out       Hidric charateristic id output
    * @param   i_flg_bodypart_ftxt_out     Y- the body part was defined by free text output. N-otherwise intake
    * @param   i_old_hidrics_out           Id hidrics of the registry being edited output
    *                                      To be used in the editions only.
    * @param   i_flg_nr_times_out          Y - the nr of occurrences has been filled by the user; N - otherwise
    *
    * @param   i_flg_irrigation_block      I-Intake (only the intake content should be calculate); O-Output (only the output content should be calculate)
    *                                      A-All. Null also returns all the intake and output contents
    *
    * @param   o_ways_int                  ways cursor intake
    * @param   o_body_parts_int            body parts cursor intake
    * @param   o_body_side_int             body parts cursor intake
    * @param   o_hidrics_int               hidrics cursor intake
    * @param   o_hidrics_chars_int         hidrics cursor intake
    * @param   o_hidrics_devices_int       hidrics cursor intake
    *
    * @param   o_ways_out                  ways cursor output 
    * @param   o_body_parts_out            body parts cursor output
    * @param   o_body_side_out             body parts cursor output
    * @param   o_hidrics_out               hidrics cursor output
    * @param   o_hidrics_chars_out         hidrics cursor output
    * @param   o_hidrics_devices_out       hidrics cursor output
    *
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.3.8
    * @since   06-09-2013
    */
    FUNCTION get_lists_irrigations
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hid     IN epis_hidrics.id_epis_hidrics%TYPE,
        i_hid_flg_type IN hidrics.flg_type%TYPE,
        --intake
        i_way_int               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_int         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_int         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_int           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_int   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_int IN VARCHAR2,
        i_device_int            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_int       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        --output
        i_way_out               IN way.id_way%TYPE DEFAULT NULL,
        i_body_part_out         IN hidrics_location.id_body_part%TYPE DEFAULT NULL,
        i_body_side_out         IN hidrics_location.id_body_side%TYPE DEFAULT NULL,
        i_hidrics_out           IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_hidrics_charact_out   IN table_number DEFAULT NULL,
        i_flg_bodypart_ftxt_out IN VARCHAR2,
        i_device_out            IN hidrics_device.id_hidrics_device%TYPE DEFAULT NULL,
        i_old_hidrics_out       IN hidrics.id_hidrics%TYPE DEFAULT NULL,
        i_flg_nr_times_out      IN hidrics.flg_nr_times%TYPE DEFAULT NULL,
        --
        i_flg_irrigation_block IN VARCHAR2 DEFAULT NULL,
        -- intake
        o_ways_int          OUT pk_types.cursor_type,
        o_body_parts_int    OUT pk_types.cursor_type,
        o_body_side_int     OUT pk_types.cursor_type,
        o_hidrics_int       OUT pk_types.cursor_type,
        o_hidrics_chars_int OUT pk_types.cursor_type,
        --output
        o_ways_out            OUT pk_types.cursor_type,
        o_body_parts_out      OUT pk_types.cursor_type,
        o_body_side_out       OUT pk_types.cursor_type,
        o_hidrics_out         OUT pk_types.cursor_type,
        o_hidrics_chars_out   OUT pk_types.cursor_type,
        o_hidrics_devices_out OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * Gets the description of hidrics/ways and locations of all the lines of a group
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_epis_hidrics_group  Epis hidrics group ID
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.3.8
    * @since                          2013/09/23
    *******************************************************************************************************************************************/
    FUNCTION get_hidrics_group_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_hidrics_group IN epis_hidrics_group.id_epis_hidrics_group%TYPE
    ) RETURN pk_translation.t_desc_translation;

    /*******************************************************************************************************************************************
    * cancel_group_line_association   Cancel groups association to the line and cancels the group if no active lines are associated to the group
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_epis_hidrics_line      Epis hidrics line ID
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.3.8
    * @since                          2013/09/24
    *******************************************************************************************************************************************/
    FUNCTION cancel_group_line_association
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * reactive_group_line_assoc   Sets as active an association between a line and a group
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_epis_hidrics_line      Epis hidrics line ID
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @author                         Sofia Mendes
    * @version                        2.5.3.8
    * @since                          2013/09/24
    *******************************************************************************************************************************************/
    FUNCTION reactive_group_line_assoc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_epis_hidrics_line IN epis_hidrics_line.id_epis_hidrics_line%TYPE,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /*******************************************************************************************************************************************
    * get_groups_total                Get the totals of all the groups in the given epis_hidrics
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_tbl_hidrics_request    List with the epis_hidrics to be returned to the grid
    * @param O_EPIS_HID               Cursor that returns hidrics
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR
    * 
    * @return                         Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    * 
    * @author                         Emilia Taborda
    * @version                        0.1
    * @since                          2006/11/21
    *
    * @author                         Sofia Mendes
    * @version                        2.6.3.8.2
    * @since                          2013/10/01
    *******************************************************************************************************************************************/
    FUNCTION get_groups_total
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_tbl_hidrics_request IN t_tbl_hidrics_request,
        o_group_totals        OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(200 CHAR);
    g_package_name  VARCHAR2(200 CHAR);

    g_error VARCHAR2(2000);
    g_exception EXCEPTION;
END pk_inp_hidrics_groups;
/
