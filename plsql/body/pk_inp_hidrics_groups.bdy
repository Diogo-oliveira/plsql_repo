/*-- Last Change Revision: $Rev: 1733592 $*/
/*-- Last Change by: $Author: vanessa.barsottelli $*/
/*-- Date of last change: $Date: 2016-04-18 12:19:01 +0100 (seg, 18 abr 2016) $*/
CREATE OR REPLACE PACKAGE BODY pk_inp_hidrics_groups IS

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(20 CHAR) := 'SET_IRRIGATION_GROUP';
    BEGIN
        g_error := 'CALL set_hidrics_group. ' || ' i_epis_hidrics: ' || i_epis_hidrics;
        pk_alertlog.log_debug(g_error);
        IF NOT set_hidrics_group(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_epis_hidrics_line     => i_epis_hidrics_line,
                                 i_group_desc            => NULL,
                                 i_id_epis_hidrics_group => i_id_epis_hidrics_group,
                                 o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_irrigation_group;

    /*******************************************************************************************************************************************
    * Check if already exists a group with the current lines
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
    * @version                        2.6.3.8.1
    * @since                          2013/09/18
    *******************************************************************************************************************************************/
    FUNCTION get_existing_group
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_epis_hidrics_line     IN table_number,
        o_id_epis_hidrics_group OUT epis_hidrics_group.id_epis_hidrics_group%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name   VARCHAR2(20 CHAR) := 'GET_EXISTING_GROUP';
        l_lines_count PLS_INTEGER;
    BEGIN
        l_lines_count := i_epis_hidrics_line.count;
    
        g_error := 'Check if a group already exists with the current lines';
        pk_alertlog.log_debug(g_error);
        SELECT id_epis_hidrics_group
          INTO o_id_epis_hidrics_group
          FROM (SELECT /*+opt_estimate(table,ehl,scale_rows=2)*/
                 ehlg.id_epis_hidrics_group
                  FROM epis_hd_line_group ehlg
                  JOIN TABLE(i_epis_hidrics_line) ehl
                    ON ehl.column_value = ehlg.id_epis_hidrics_line
                 GROUP BY ehlg.id_epis_hidrics_group
                HAVING COUNT(1) = l_lines_count) t
         WHERE rownum = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_id_epis_hidrics_group := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_existing_group;

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
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(20 CHAR) := 'SET_HIDRICS_GROUP';
        l_id_epis_hd_group epis_hidrics_group.id_epis_hidrics_group%TYPE;
        l_lines_count      PLS_INTEGER;
    BEGIN
        IF (i_id_epis_hidrics_group IS NULL)
        THEN
            g_error := 'CALL get_existing_group';
            pk_alertlog.log_debug(g_error);
            IF NOT get_existing_group(i_lang                  => i_lang,
                                      i_prof                  => i_prof,
                                      i_epis_hidrics_line     => i_epis_hidrics_line,
                                      o_id_epis_hidrics_group => l_id_epis_hd_group,
                                      o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF (l_id_epis_hd_group IS NULL)
        THEN
            l_id_epis_hd_group := seq_epis_hidrics_group.nextval;
        
            --create the group
            g_error := 'CALL ts_epis_hidrics_group';
            pk_alertlog.log_debug(g_error);
            ts_epis_hidrics_group.ins(id_epis_hidrics_group_in => l_id_epis_hd_group,
                                      group_desc_in            => i_group_desc,
                                      flg_status_in            => pk_alert_constant.g_active);
        
            l_lines_count := i_epis_hidrics_line.count;
        
            FOR i IN 1 .. l_lines_count
            LOOP
                g_error := 'CALL ts_epis_hidrics_group';
                pk_alertlog.log_debug(g_error);
                ts_epis_hd_line_group.ins(id_epis_hidrics_group_in    => l_id_epis_hd_group,
                                          id_epis_hidrics_line_in     => i_epis_hidrics_line(i),
                                          id_epis_hdl_group_child_in  => NULL,
                                          flg_show_parameters_grid_in => pk_alert_constant.g_yes,
                                          flg_status_in               => pk_alert_constant.g_active);
            
            END LOOP;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END set_hidrics_group;

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
    ) RETURN BOOLEAN IS
        l_func_name             VARCHAR2(30 CHAR) := 'GET_LISTS_IRRIGATIONS';
        l_hidrics_devices_dummy pk_types.cursor_type;
        l_flg_nr_times_dummy    hidrics.flg_nr_times%TYPE;
    
        l_episode      episode.id_episode%TYPE;
        l_hidrics_type hidrics_type.id_hidrics_type%TYPE;
        c_input  CONSTANT VARCHAR2(1char) := 'I';
        c_output CONSTANT VARCHAR2(1char) := 'O';
        c_all    CONSTANT VARCHAR2(1char) := 'A';
    BEGIN
        --if it is an irrigation and an Intake and Output
        -- it is necessary to get data from Irrigations hidrics type
        g_error := 'GET ID_EPIS AND ID_HID_TYPE';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        SELECT eh.id_episode, eh.id_hidrics_type
          INTO l_episode, l_hidrics_type
          FROM epis_hidrics eh
         WHERE eh.id_epis_hidrics = i_epis_hid;
    
        g_error := 'CALL pk_inp_hidrics.get_hidric_type. i_hid_flg_type: ' || i_hid_flg_type;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        l_hidrics_type := pk_inp_hidrics.get_hidric_type(i_lang    => i_lang,
                                                         i_prof    => i_prof,
                                                         i_acronym => i_hid_flg_type);
    
        IF (nvl(i_flg_irrigation_block, c_all) IN (c_input, c_all))
        THEN
            g_error := 'call pk_inp_hidrics.get_multichoice_lists for intake records';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_inp_hidrics.get_multichoice_lists(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_epis_hid              => i_epis_hid,
                                                        i_episode               => l_episode,
                                                        i_hid_flg_type          => pk_inp_hidrics_constant.g_hidrics_flg_type_a,
                                                        i_hidrics_type          => l_hidrics_type,
                                                        i_way                   => i_way_int,
                                                        i_body_part             => i_body_part_int,
                                                        i_body_side             => i_body_side_int,
                                                        i_hidrics               => i_hidrics_int,
                                                        i_hidrics_charact       => i_hidrics_charact_int,
                                                        i_flg_bodypart_freetext => i_flg_bodypart_ftxt_int,
                                                        i_device                => i_device_int,
                                                        i_old_hidrics           => i_old_hidrics_int,
                                                        i_flg_nr_times          => l_flg_nr_times_dummy,
                                                        o_ways                  => o_ways_int,
                                                        o_body_parts            => o_body_parts_int,
                                                        o_body_side             => o_body_side_int,
                                                        o_hidrics               => o_hidrics_int,
                                                        o_hidrics_chars         => o_hidrics_chars_int,
                                                        o_hidrics_devices       => l_hidrics_devices_dummy,
                                                        o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_body_parts_int);
            pk_types.open_my_cursor(o_body_side_int);
            pk_types.open_my_cursor(o_hidrics_int);
            pk_types.open_my_cursor(o_hidrics_chars_int);
            pk_types.open_my_cursor(o_ways_int);
            pk_types.open_my_cursor(l_hidrics_devices_dummy);
        END IF;
    
        IF (nvl(i_flg_irrigation_block, c_all) IN (c_output, c_all))
        THEN
            g_error := 'call pk_inp_hidrics.get_multichoice_lists for output records';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_inp_hidrics.get_multichoice_lists(i_lang                  => i_lang,
                                                        i_prof                  => i_prof,
                                                        i_epis_hid              => i_epis_hid,
                                                        i_hid_flg_type          => pk_inp_hidrics_constant.g_hidrics_flg_type_e,
                                                        i_episode               => l_episode,
                                                        i_hidrics_type          => l_hidrics_type,
                                                        i_way                   => i_way_out,
                                                        i_body_part             => i_body_part_out,
                                                        i_body_side             => i_body_side_out,
                                                        i_hidrics               => i_hidrics_out,
                                                        i_hidrics_charact       => i_hidrics_charact_out,
                                                        i_flg_bodypart_freetext => i_flg_bodypart_ftxt_out,
                                                        i_device                => i_device_out,
                                                        i_old_hidrics           => i_old_hidrics_out,
                                                        i_flg_nr_times          => i_flg_nr_times_out,
                                                        o_ways                  => o_ways_out,
                                                        o_body_parts            => o_body_parts_out,
                                                        o_body_side             => o_body_side_out,
                                                        o_hidrics               => o_hidrics_out,
                                                        o_hidrics_chars         => o_hidrics_chars_out,
                                                        o_hidrics_devices       => o_hidrics_devices_out,
                                                        o_error                 => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(o_body_parts_out);
            pk_types.open_my_cursor(o_body_side_out);
            pk_types.open_my_cursor(o_hidrics_out);
            pk_types.open_my_cursor(o_hidrics_chars_out);
            pk_types.open_my_cursor(o_ways_out);
            pk_types.open_my_cursor(o_hidrics_devices_out);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_body_parts_int);
            pk_types.open_my_cursor(o_body_side_int);
            pk_types.open_my_cursor(o_hidrics_int);
            pk_types.open_my_cursor(o_hidrics_chars_int);
            pk_types.open_my_cursor(o_ways_int);
            pk_types.open_my_cursor(l_hidrics_devices_dummy);
        
            pk_types.open_my_cursor(o_body_parts_out);
            pk_types.open_my_cursor(o_body_side_out);
            pk_types.open_my_cursor(o_hidrics_out);
            pk_types.open_my_cursor(o_hidrics_chars_out);
            pk_types.open_my_cursor(o_ways_out);
            pk_types.open_my_cursor(o_hidrics_devices_out);
        
            RETURN FALSE;
    END get_lists_irrigations;

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
    ) RETURN pk_translation.t_desc_translation IS
        l_func_name     VARCHAR2(25 CHAR) := 'GET_HIDRICS_GROUP_DESC';
        l_desc          pk_translation.t_desc_translation;
        l_error         t_error_out;
        l_desc_location pk_translation.t_desc_translation;
    BEGIN
        IF (i_id_epis_hidrics_group IS NOT NULL)
        THEN
            FOR rec IN (SELECT ehl.id_epis_hidrics_line
                          FROM epis_hd_line_group ehlg
                          JOIN epis_hidrics_line ehl
                            ON ehl.id_epis_hidrics_line = ehlg.id_epis_hidrics_line
                          JOIN hidrics h
                            ON h.id_hidrics = ehl.id_hidrics
                         WHERE ehlg.id_epis_hidrics_group = i_id_epis_hidrics_group
                           AND ehlg.flg_status = pk_alert_constant.g_active
                         ORDER BY h.flg_type)
            LOOP
                g_error := 'Get line description: id_epis_hidrics_group: ' || i_id_epis_hidrics_group ||
                           ' id_epis_hidrics_line: ' || rec.id_epis_hidrics_line;
                pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
                l_desc_location := pk_inp_hidrics.get_hidrics_location_grid(i_lang              => i_lang,
                                                                            i_prof              => i_prof,
                                                                            i_epis_hidrics_line => rec.id_epis_hidrics_line) (1);
            
                l_desc := l_desc || /*chr(10) ||*/
                          pk_inp_hidrics.get_hidrics_way(i_lang, i_prof, rec.id_epis_hidrics_line) || ' / ' || CASE
                              WHEN l_desc_location IS NOT NULL THEN
                               l_desc_location || ' / '
                              ELSE
                               NULL
                          END || pk_inp_hidrics.get_hidrics_desc(i_lang, i_prof, rec.id_epis_hidrics_line) || chr(10);
            END LOOP;
        END IF;
    
        RETURN l_desc;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_hidrics_group_desc;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'CANCEL_GROUP_LINE_ASSOCIATION';
    BEGIN
        g_error := 'Cancel groups associations to line. i_epis_hidrics_line: ' || i_epis_hidrics_line;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        UPDATE epis_hd_line_group ehlg
           SET ehlg.flg_status = pk_alert_constant.g_cancelled
         WHERE ehlg.id_epis_hidrics_line = i_epis_hidrics_line;
    
        --check if there is some group associated the line being cancelled that stays without any active line
        g_error := 'Cancel groups. i_epis_hidrics_line: ' || i_epis_hidrics_line;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        UPDATE epis_hidrics_group ehg
           SET ehg.flg_status = pk_alert_constant.g_cancelled
         WHERE ehg.id_epis_hidrics_group IN
               (SELECT ehg1.id_epis_hidrics_group
                  FROM epis_hd_line_group ehlg1
                  JOIN epis_hidrics_group ehg1
                    ON ehg1.id_epis_hidrics_group = ehlg1.id_epis_hidrics_group
                  JOIN epis_hidrics_line ehl1
                    ON ehl1.id_epis_hidrics_line = ehlg1.id_epis_hidrics_line
                 WHERE ehlg1.id_epis_hidrics_line = i_epis_hidrics_line
                   AND NOT EXISTS (SELECT 1
                          FROM epis_hd_line_group ehlg
                          JOIN epis_hidrics_group ehg
                            ON ehg.id_epis_hidrics_group = ehlg.id_epis_hidrics_group
                          JOIN epis_hidrics_line ehl
                            ON ehl.id_epis_hidrics_line = ehlg.id_epis_hidrics_line
                         WHERE ehg.id_epis_hidrics_group = ehg1.id_epis_hidrics_group
                           AND ehl.flg_status <> pk_inp_hidrics_constant.g_epis_hidric_c));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END cancel_group_line_association;

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
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(30 CHAR) := 'REACTIVE_GROUP_LINE_ASSOC';
    BEGIN
        g_error := 'Cancel groups associations to line. i_epis_hidrics_line: ' || i_epis_hidrics_line;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        UPDATE epis_hd_line_group ehlg
           SET ehlg.flg_status = pk_alert_constant.g_active
         WHERE ehlg.id_epis_hidrics_line = i_epis_hidrics_line;
    
        --check if there is some group associated the line being cancelled that stays without any active line
        g_error := 'Cancel groups. i_epis_hidrics_line: ' || i_epis_hidrics_line;
        pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        UPDATE epis_hidrics_group ehg
           SET ehg.flg_status = pk_alert_constant.g_active
         WHERE ehg.id_epis_hidrics_group IN
               (SELECT ehg1.id_epis_hidrics_group
                  FROM epis_hd_line_group ehlg1
                  JOIN epis_hidrics_group ehg1
                    ON ehg1.id_epis_hidrics_group = ehlg1.id_epis_hidrics_group
                  JOIN epis_hidrics_line ehl1
                    ON ehl1.id_epis_hidrics_line = ehlg1.id_epis_hidrics_line
                 WHERE ehlg1.id_epis_hidrics_line = i_epis_hidrics_line
                   AND EXISTS (SELECT 1
                          FROM epis_hd_line_group ehlg
                          JOIN epis_hidrics_group ehg
                            ON ehg.id_epis_hidrics_group = ehlg.id_epis_hidrics_group
                          JOIN epis_hidrics_line ehl
                            ON ehl.id_epis_hidrics_line = ehlg.id_epis_hidrics_line
                         WHERE ehg.id_epis_hidrics_group = ehg1.id_epis_hidrics_group
                           AND ehl.flg_status <> pk_inp_hidrics_constant.g_epis_hidric_c));
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END reactive_group_line_assoc;

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
    ) RETURN BOOLEAN IS
        l_desc_total_irrigation CONSTANT sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'HIDRICS_T138');
    BEGIN
        g_error := 'Open o_group_totals';
        OPEN o_group_totals FOR
            SELECT t.id_epis_hidrics,
                   '<b>' || l_desc_total_irrigation || ' (' ||
                   (SELECT pk_inp_hidrics.get_hidrics_um(i_lang, i_prof, t.id_epis_hidrics)
                      FROM dual) || ')' || ':</b> ' ||
                   pk_inp_hidrics_groups.get_hidrics_group_desc(i_lang                  => i_lang,
                                                                i_prof                  => i_prof,
                                                                i_id_epis_hidrics_group => t.id_epis_hidrics_group)
                   
                   total_desc,
                   pk_utils.number_to_char(i_prof,
                   pk_inp_hidrics.get_hidrics_total_balance(i_lang,
                                                            i_prof,
                                                            t.id_epis_hidrics,
                                                            NULL,
                                                            NULL,
                                                            pk_inp_hidrics_constant.g_grid_type_f,
                                                            NULL,
                                                            NULL,
                                                            current_timestamp,
                                                            pk_inp_hidrics_constant.g_element_total,
                                                            pk_alert_constant.g_yes,
                                                            t.id_epis_hidrics_group,
                                                            ehb.dt_open_tstz)) || ' ' ||
                   (SELECT pk_inp_hidrics.get_hidrics_um(i_lang, i_prof, t.id_epis_hidrics)
                      FROM dual) total_value
              FROM (SELECT /*+opt_estimate (table t rows=0.1)*/
                    DISTINCT eh.id_epis_hidrics, ehlg.id_epis_hidrics_group
                      FROM epis_hidrics eh
                      JOIN epis_hidrics_line ehl
                        ON ehl.id_epis_hidrics = eh.id_epis_hidrics
                      JOIN epis_hd_line_group ehlg
                        ON ehlg.id_epis_hidrics_line = ehl.id_epis_hidrics_line
                      JOIN(TABLE(i_tbl_hidrics_request)) t
                        ON t.id_epis_hidrics = eh.id_epis_hidrics
                      JOIN hidrics_type ht
                        ON eh.id_hidrics_type = ht.id_hidrics_type
                    --only the irrigations totals are shown in the requests screen viewer               
                     WHERE ht.acronym = pk_inp_hidrics_constant.g_hid_type_g) t
             INNER JOIN epis_hidrics_balance ehb
                ON (t.id_epis_hidrics = ehb.id_epis_hidrics)
             WHERE (SELECT pk_inp_hidrics.get_most_recent_ehb_id(t.id_epis_hidrics)
                      FROM dual) = ehb.id_epis_hidrics_balance
             ORDER BY id_epis_hidrics;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_GROUPS_TOTAL',
                                              o_error);
        
            pk_types.open_my_cursor(o_group_totals);
            RETURN FALSE;
    END get_groups_total;

BEGIN
    -- Initialization
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);
    --
--g_sysdate_tstz := current_timestamp;
--
END pk_inp_hidrics_groups;
/
