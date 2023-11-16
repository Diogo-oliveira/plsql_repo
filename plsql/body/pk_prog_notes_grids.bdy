/*-- Last Change Revision: $Rev: 2052338 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2022-12-06 16:08:06 +0000 (ter, 06 dez 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_prog_notes_grids IS

    -- Private type declarations
    TYPE t_dblock_ctx IS RECORD(
        id_epis_pn       epis_pn.id_epis_pn%TYPE, --note identifier
        data_blocks_note t_coll_dblock, -- all the data blocks configured for this note type
        id_pn_soap_block pn_soap_block.id_pn_soap_block%TYPE, --soap block id
        dblocks          table_number, --list of the data blocks configured to the id_pn_soap_block
        filled_dblocks   table_number --data blocks with text in the current note        
        );

    --calculated one time by soap block
    g_dblock_ctx t_dblock_ctx;

    -- Private constant declarations  
    -- Private variable declarations
    -- Function and procedure implementations  

    /**
    * Adds a new value to a table_number object
    *
    * @param   io_table_1                    Table that will have the new value
    * @param   i_value_1                     New value
    * @param   io_table_2                    Table that will have the new value
    * @param   i_value_2                     New value
    * @param   io_table_3                    Table that will have the new value
    * @param   i_value_3                     New value
    * @param   io_table_4                    Table that will have the new value
    * @param   i_value_4                     New value
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   07-Feb-2011
    */
    PROCEDURE add_4_values
    (
        io_table_1      IN OUT table_varchar,
        i_value_1       IN VARCHAR2,
        io_table_2      IN OUT table_varchar,
        i_value_2       IN VARCHAR2,
        io_table_3      IN OUT table_clob,
        i_value_3       IN CLOB,
        io_table_4      IN OUT table_varchar,
        i_value_4       IN VARCHAR2,
        i_flg_data_type IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_note
    ) IS
    BEGIN
        io_table_1.extend();
        io_table_1(io_table_1.count) := i_value_1;
    
        io_table_2.extend();
        io_table_2(io_table_2.count) := i_value_2;
    
        io_table_3.extend();
        io_table_3(io_table_3.count) := i_value_3;
    
        io_table_4.extend();
        io_table_4(io_table_4.count) := CASE
                                            WHEN g_report_scope = pk_alert_constant.g_yes THEN
                                             i_flg_data_type
                                            ELSE
                                             ''
                                        END || i_value_4;
    
    END add_4_values;

    /**
      * Returns the addendums data.
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
      * @param I_FILTER                 Filter by a listed interval of dates    
      * @param o_addendums              Addendums data
    * @param o_comments         Comments data
      * @param o_error                  error
      *
      * @return                         false if errors occur, true otherwise
      *
      * @author               Sofia Mendes
      * @version               2.6.0.5
      * @since                31-Jan-2011
      */
    FUNCTION get_addendums
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_ids_epis_pn IN table_number,
        i_search      IN VARCHAR2 DEFAULT NULL,
        o_addendums   OUT NOCOPY pk_types.cursor_type,
        o_comments    OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_addendum_title sys_message.desc_message%TYPE;
    BEGIN
        l_addendum_title := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_prog_notes_constants.g_sm_addendum);
    
        g_error := 'GET addendums DATA';
        pk_alertlog.log_debug(g_error);
        OPEN o_addendums FOR
            SELECT tt.id_epis_pn_addendum addendum_id,
                   tt.id_epis_pn note_id,
                   tt.flg_status addendum_flg_status,
                   CASE
                        WHEN tt.flg_status_available = pk_alert_constant.g_yes THEN
                         pk_prog_notes_constants.g_open_parenthesis ||
                         pk_sysdomain.get_domain(pk_prog_notes_constants.g_sd_add_flg_status, tt.flg_status, i_lang) ||
                         pk_prog_notes_constants.g_close_parenthesis
                        ELSE
                         ''
                    END addendum_status_desc,
                   tt.prof_signature addendum_prof_signature,
                   flg_change addendum_flg_ok,
                   flg_change addendum_flg_cancel,
                   l_addendum_title addendum_title,
                   pk_prog_notes_utils.highlight_searched_text(tt.pn_addendum, i_search) addendum_text
            --the no_merge hint is used here because of an ORACLE bug (till 10g, in 11g it is not needed the hint)
            --if no hint is used the columns flg_change and nr_addendums used more that one time in the select above
            -- do not have the correct values              
              FROM (SELECT /*+no_merge*/ /*+opt_estimate(table,t_notes_type,scale_rows=0.0000001)*/
                     epa.id_epis_pn_addendum,
                     epa.id_epis_pn,
                     epa.flg_status,
                     epa.pn_addendum,
                     pk_prog_notes_utils.get_signature(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_episode          => epn.id_episode,
                                                       i_id_prof_create      => epa.id_professional,
                                                       i_dt_create           => epa.dt_addendum,
                                                       i_id_prof_last_update => epa.id_prof_last_update,
                                                       i_dt_last_update      => epa.dt_last_update,
                                                       i_id_prof_sign_off    => epa.id_prof_signoff,
                                                       i_dt_sign_off         => epa.dt_signoff,
                                                       i_id_prof_cancel      => epa.id_prof_cancel,
                                                       i_dt_cancel           => epa.dt_cancel,
                                                       i_id_dictation_report => epn.id_dictation_report,
                                                       i_id_software         => epn.id_software) prof_signature,
                     decode(pk_prog_notes_utils.check_change_addendum(i_lang,
                                                                      i_prof,
                                                                      epa.flg_status,
                                                                      epa.id_epis_pn_addendum),
                            1,
                            pk_alert_constant.g_yes,
                            pk_alert_constant.g_no) flg_change,
                     epa.dt_addendum,
                     t_notes_type.flg_status_available
                      FROM epis_pn_addendum epa
                      JOIN epis_pn epn
                        ON epn.id_epis_pn = epa.id_epis_pn
                      JOIN (SELECT /*+ OPT_ESTIMATE (TABLE T ROWS=1)*/
                            column_value id_epis_pn
                             FROM TABLE(i_ids_epis_pn) t) tids
                        ON tids.id_epis_pn = epn.id_epis_pn
                      LEFT OUTER JOIN TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang, i_prof, epn.id_episode, NULL, NULL, NULL, NULL, NULL, NULL, epn.id_pn_note_type, pk_prog_notes_constants.g_pn_flg_scope_notetype_n, epn.id_software)) t_notes_type
                        ON epn.id_pn_note_type = t_notes_type.id_pn_note_type
                     WHERE epa.flg_type = pk_prog_notes_constants.g_epa_flg_type_addendum
                       AND epa.flg_status IN (pk_prog_notes_constants.g_addendum_status_d,
                                              pk_prog_notes_constants.g_addendum_status_s,
                                              pk_prog_notes_constants.g_addendum_status_f)) tt
             ORDER BY tt.dt_addendum DESC;
    
        l_addendum_title := pk_message.get_message(i_lang      => i_lang,
                                                   i_code_mess => pk_prog_notes_constants.g_sm_pn_comments);
    
        g_error := 'GET comments DATA';
        pk_alertlog.log_debug(g_error);
        OPEN o_comments FOR
            SELECT /*+OPT_ESTIMATE(TABLE t_notes_type ROWS=1)*/
             epa.id_epis_pn_addendum addendum_id,
             epa.id_epis_pn note_id,
             NULL addendum_flg_status,
             NULL addendum_status_desc,
             pk_prog_notes_utils.get_signature(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_episode          => ep.id_episode,
                                               i_id_prof_create      => epa.id_professional,
                                               i_dt_create           => epa.dt_addendum,
                                               i_id_prof_last_update => epa.id_prof_last_update,
                                               i_dt_last_update      => epa.dt_last_update,
                                               i_id_prof_sign_off    => epa.id_prof_signoff,
                                               i_dt_sign_off         => epa.dt_signoff,
                                               i_id_prof_cancel      => epa.id_prof_cancel,
                                               i_dt_cancel           => epa.dt_cancel,
                                               i_id_dictation_report => ep.id_dictation_report,
                                               i_id_software         => ep.id_software) addendum_prof_signature,
             pk_alert_constant.g_no addendum_flg_ok,
             pk_alert_constant.g_no addendum_flg_cancel,
             l_addendum_title addendum_title,
             pk_prog_notes_utils.highlight_searched_text(epa.pn_addendum, i_search) addendum_text
              FROM epis_pn_addendum epa
              JOIN epis_pn ep
                ON epa.id_epis_pn = ep.id_epis_pn
              JOIN (SELECT /*+OPT_ESTIMATE(TABLE t ROWS=1)*/
                     column_value
                      FROM TABLE(i_ids_epis_pn) t) tids
                ON ep.id_epis_pn = tids.column_value
              LEFT JOIN TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang, i_prof, ep.id_episode, NULL, NULL, NULL, NULL, NULL, NULL, ep.id_pn_note_type, pk_prog_notes_constants.g_pn_flg_scope_notetype_n, ep.id_software)) t_notes_type
                ON ep.id_pn_note_type = t_notes_type.id_pn_note_type
             WHERE epa.flg_type = pk_prog_notes_constants.g_epa_flg_type_comment
             ORDER BY epa.dt_addendum DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_comments);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ADDENDUMS',
                                              o_error);
        
            RETURN FALSE;
    END get_addendums;

    /**
    * Returns the description of the nr of addendums of a note.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_nr_addendums           Nr of addendums. It only gets the descrptive if the nr of addendums had already been calculated    
    * @param i_id_epis_pn             note id       
    *
    * @return                         description
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                14-Feb-2011
    */
    FUNCTION get_nr_addendums_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_nr_addendums   IN PLS_INTEGER DEFAULT NULL,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_has_status IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_desc         VARCHAR2(1000 CHAR) := NULL;
        l_nr_addendums PLS_INTEGER;
        l_error        t_error_out;
    BEGIN
        IF (i_nr_addendums IS NULL)
        THEN
            l_nr_addendums := pk_prog_notes_utils.get_nr_addendums_state(i_lang,
                                                                         i_prof,
                                                                         i_id_epis_pn,
                                                                         NULL,
                                                                         table_varchar(pk_prog_notes_constants.g_addendum_status_d,
                                                                                       pk_prog_notes_constants.g_addendum_status_s,
                                                                                       pk_prog_notes_constants.g_addendum_status_f));
        ELSE
            l_nr_addendums := i_nr_addendums;
        END IF;
    
        IF (l_nr_addendums <> 0)
        THEN
            g_error := 'GET addendums DATA';
            pk_alertlog.log_debug(g_error);
            l_desc := CASE
                          WHEN i_flg_has_status = pk_alert_constant.g_yes THEN
                           ' - '
                          ELSE
                           NULL
                      END || l_nr_addendums || ' ' || CASE
                          WHEN l_nr_addendums = 1 THEN
                           pk_message.get_message(i_lang, pk_prog_notes_constants.g_sm_addendum_m)
                          ELSE
                           pk_message.get_message(i_lang, pk_prog_notes_constants.g_sm_addenda)
                      END;
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
                                              'GET_NR_ADDENDUMS_DESC',
                                              l_error);
        
            RETURN NULL;
    END get_nr_addendums_desc;

    /**********************************************************************************************
    * Get the start and end dates of a given time period (ex. TODAY, LASTYEAR,...)    
    *
    * @param i_lang                   the id language
    * @param i_prof                   professional, software and institution ids    
    * @param i_scale                  Time Scale: THISYEAR, THISMONTH, THISWEEK   
    *                                             TODAY, LASTDAY 
    *                                             LASTWEEK, LASTMONTH, LASTYEAR
    * @param o_start_date             Time interval start date
    * @param o_end_date               Time interval end date
    * @param o_error                  Error message
    *
    * @return                         TRUE if sucess, FALSE otherwise
    *                        
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          02-Feb-2011 
    **********************************************************************************************/
    FUNCTION get_scale_dates_map
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_scale      IN NUMBER,
        o_start_date OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date   OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scale_str VARCHAR2(30);
    BEGIN
        l_scale_str := CASE i_scale
                           WHEN 1 THEN
                            NULL
                           WHEN 2 THEN
                            pk_date_utils.g_scale_lastyear
                           WHEN 3 THEN
                            pk_date_utils.g_scale_thisyear
                           WHEN 4 THEN
                            pk_date_utils.g_scale_lastmonth
                           WHEN 5 THEN
                            pk_date_utils.g_scale_thismonth
                           WHEN 6 THEN
                            pk_date_utils.g_scale_lastweek
                           WHEN 7 THEN
                            pk_date_utils.g_scale_thisweek
                           WHEN 8 THEN
                            pk_date_utils.g_scale_lastday
                           WHEN 9 THEN
                            pk_date_utils.g_scale_today
                           WHEN 11 THEN
                            pk_date_utils.g_scale_last48h
                           WHEN 12 THEN
                            pk_date_utils.g_scale_last24h
                           ELSE
                            NULL
                       END;
    
        IF (l_scale_str IS NULL)
        THEN
            o_start_date := NULL;
            o_end_date   := NULL;
        ELSE
            g_error := 'CALL pk_date_utils.get_scale_dates.  i_scale: ' || l_scale_str;
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_scale_dates(i_lang       => i_lang,
                                                 i_prof       => i_prof,
                                                 i_scale      => l_scale_str,
                                                 o_start_date => o_start_date,
                                                 o_end_date   => o_end_date,
                                                 o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'GET_SCALE_DATES_MAP',
                                              o_error);
            RETURN FALSE;
    END get_scale_dates_map;

    /**
        * Given a term to search, returns the correspondent matches from the tables EPIS_PN_DET, EPIS_PN_SIGNOFF and EPIS_PN_ADDENDUM.
        * @param      i_lang                   Language for translation (not in use)
        * @param      i_search                 The string to be searched
        *
        * @author     Pedro Pinheiro
        * @version    2.6.0.5
        * @since      15-Feb-2011
    */

    FUNCTION search_epis_note
    (
        i_lang       IN language.id_language%TYPE,
        i_search     IN VARCHAR2,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN table_t_epis_note IS
    
        l_out_rec      table_t_epis_note := table_t_epis_note(NULL);
        l_sql          VARCHAR2(4000);
        l_search       VARCHAR2(400) := TRIM(i_search);
        l_extra_search VARCHAR2(200 CHAR);
        l_id_patient   VARCHAR2(50 CHAR);
        l_id_episode   VARCHAR2(50 CHAR);
    
        l_use_lucene_cache CONSTANT VARCHAR(1 CHAR) := pk_sysconfig.get_config('PROGRESS_NOTES_SEARCH_CACHE',
                                                                               profissional(0, 0, 0));
        l_endsession VARCHAR2(1000 CHAR);
    BEGIN
    
        IF l_use_lucene_cache = pk_prog_notes_constants.g_no
        THEN
            l_endsession := dbms_java.endsession;
        END IF;
    
        l_sql := 'SELECT t_epis_note(id_epis_pn, note, position, relevance)
                    FROM (SELECT t1.*, rownum position
                            FROM (SELECT *
                                    FROM (SELECT 
                                           epd.id_epis_pn id_epis_pn, epd.pn_note note, rownum relevance
                                            FROM epis_pn_det epd
                                            JOIN epis_pn epn ON epn.id_epis_pn = epd.id_epis_pn
                                                            AND epn.flg_status IN (''D'', ''F'')
                                                            AND epd.flg_status = ''A''
                                            WHERE lcontains(epd.pn_note, :l_search, 1) > 0
                                           UNION ALL
                                            SELECT 
                                             eps.id_epis_pn id_epis_pn, eps.pn_signoff_note note, rownum relevance
                                              FROM epis_pn_signoff eps
                                              JOIN epis_pn epn ON epn.id_epis_pn = eps.id_epis_pn
                                                              AND epn.flg_status IN (''S'', ''M'', ''T'')
                                              WHERE lcontains(eps.pn_signoff_note, :l_search, 1) > 0
                                           UNION ALL
                                            SELECT 
                                             epa.id_epis_pn, epa.pn_addendum note, rownum relevance
                                              FROM epis_pn_addendum epa
                                              JOIN epis_pn epn ON epn.id_epis_pn = epa.id_epis_pn
                                                              AND epn.flg_status IN (''S'', ''M'')
                                                              AND epa.flg_status IN (''D'', ''S'')
                                              WHERE lcontains(epa.pn_addendum, :l_search, 1) > 0
                                           UNION ALL
                                            SELECT /*+ opt_estimate(table epdt rows=1) */
                                                   epd.id_epis_pn id_epis_pn, epdt.pn_note note, epdt.relevance relevance
                                               FROM (SELECT epdt.*, rownum relevance 
                                                       FROM epis_pn_det_task epdt
                                                      WHERE lcontains(epdt.pn_note, :l_search, 1) > 0 
                                                        AND epdt.flg_status = ''A'' ) epdt
                                               JOIN epis_pn_det epd on epd.id_epis_pn_det = epdt.id_epis_pn_det
                                               JOIN epis_pn epn ON epn.id_epis_pn = epd.id_epis_pn
                                                                AND epn.flg_status IN (''D'', ''F'')
                                                                AND epd.flg_status = ''A'') t
                                      ORDER BY relevance DESC) t1)';
    
        /* ALERT-301415 - Ignore special charactes */
        l_search := TRIM(regexp_replace(l_search, '\:', ' '));
        l_search := TRIM(regexp_replace(l_search, '\.', ' '));
        l_search := TRIM(regexp_replace(l_search, '\;', ' '));
        l_search := TRIM(regexp_replace(l_search, '\s{1,}\($', ' '));
    
        IF NOT (regexp_like(l_search, '^"') AND regexp_like(l_search, '"$'))
        THEN
            l_search := regexp_replace(lower(l_search), '[[:space:]]+', ' OR ');
        END IF;
    
        /* ALERT-287976: The duplication of function pk_lucene.escape_special_characters is intensional.
        The first call results in an invalid search string due the two invalid charaters ("?), so needs to
        call one more time the same function to "clean" the resultant invalid string search         
        */
        l_search := pk_lucene.escape_special_characters(l_search, pk_prog_notes_constants.g_yes);
        l_search := pk_lucene.escape_special_characters(l_search, pk_prog_notes_constants.g_yes);
    
        IF i_id_patient IS NOT NULL
        THEN
            IF i_id_patient < 0
            THEN
                l_id_patient := regexp_replace(to_char(i_id_patient), '^\-', '\-');
            ELSE
                l_id_patient := to_char(i_id_patient);
            END IF;
        
            l_extra_search := 'id_patient:(' || l_id_patient || ') AND ';
        END IF;
    
        IF i_id_episode IS NOT NULL
        THEN
            IF i_id_episode < 0
            THEN
                l_id_episode := regexp_replace(to_char(i_id_episode), '^\-', '\-');
            ELSE
                l_id_episode := to_char(i_id_episode);
            END IF;
        
            l_extra_search := l_extra_search || ' id_episode:(' || l_id_episode || ') AND ';
        END IF;
    
        IF l_search IS NOT NULL
        THEN
            l_search := l_extra_search || '(' || l_search || ')';
        
            EXECUTE IMMEDIATE l_sql BULK COLLECT
                INTO l_out_rec
                USING l_search, l_search, l_search, l_search;
        ELSE
            RETURN NULL;
        END IF;
    
        RETURN l_out_rec;
    END search_epis_note;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area internal name. Ex: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note    
    * @param i_flg_desc_order         Y-Should be used descending order by date. N-Should be read the configuration order
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a listed interval of dates
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_flg_scope      IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e,
        i_area           IN pn_area.internal_name%TYPE,
        i_flg_desc_order IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        --
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        --
        i_search       IN VARCHAR2,
        i_filter       IN VARCHAR2,
        i_flg_category IN VARCHAR2 DEFAULT NULL,
        --
        o_note_ids OUT NOCOPY table_number,
        o_error    OUT t_error_out
    ) RETURN BOOLEAN IS
        l_order_by         VARCHAR2(5 CHAR) := pk_prog_notes_constants.g_order_by_desc;
        l_search           VARCHAR2(4000 CHAR) := NULL;
        l_start_date       TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_end_date         TIMESTAMP(6) WITH LOCAL TIME ZONE;
        l_area_confs       t_rec_area;
        l_id_patient       patient.id_patient%TYPE;
        l_filter_date      pn_note_type.id_pn_note_type%TYPE;
        l_filter_note_type pn_note_type.id_pn_note_type%TYPE;
        l_filter_group     pn_note_type.id_pn_note_type%TYPE;
        l_filter_type      VARCHAR2(30 CHAR);
        l_filter_id        pn_note_type.id_pn_note_type%TYPE;
        l_sep              pn_note_type.id_pn_note_type%TYPE;
        l_pn_area          table_varchar := table_varchar();
        l_id_category      table_number;
    BEGIN
        IF (i_id_patient IS NULL)
        THEN
            l_id_patient := pk_episode.get_id_patient(i_episode => i_id_episode);
        ELSE
            l_id_patient := i_id_patient;
        END IF;
    
        IF (i_flg_desc_order = pk_alert_constant.g_no OR i_flg_desc_order IS NULL)
        THEN
            --Should be read the configuration order
            g_error := 'CALL pk_progress_notes_upd.tf_pn_area. i_area: ' || i_area;
            pk_alertlog.log_debug(g_error);
            l_area_confs := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_id_episode       => i_id_episode,
                                                                i_id_market        => NULL,
                                                                i_id_department    => NULL,
                                                                i_id_dep_clin_serv => NULL,
                                                                i_area             => i_area,
                                                                i_episode_software => NULL);
        
            l_order_by := l_area_confs.data_sort_summary;
        ELSE
            l_order_by := pk_prog_notes_constants.g_order_by_desc;
        END IF;
    
        IF i_search IS NOT NULL
        THEN
            l_search := pk_utils.remove_upper_accentuation(i_search);
        END IF;
    
        l_sep := instr(i_filter, pk_prog_notes_constants.g_sep);
        IF l_sep = 0
        THEN
            l_filter_date      := 10;
            l_filter_note_type := NULL;
            l_filter_group     := NULL;
        ELSE
            l_filter_type := substr(i_filter, 1, l_sep - 1);
        
            BEGIN
                l_filter_id := substr(i_filter, l_sep + 1);
            EXCEPTION
                WHEN OTHERS THEN
                    l_filter_date      := 10;
                    l_filter_note_type := NULL;
                    l_filter_group     := NULL;
            END;
        
            IF l_filter_type = pk_prog_notes_constants.g_filter_all
               AND l_filter_id = pk_prog_notes_constants.g_all
            THEN
                l_filter_date      := 10;
                l_filter_note_type := NULL;
                l_filter_group     := NULL;
            ELSE
                CASE
                    WHEN l_filter_type = pk_prog_notes_constants.g_dates THEN
                        l_filter_date := l_filter_id;
                    
                    WHEN l_filter_type = pk_prog_notes_constants.g_note_type THEN
                        l_filter_note_type := l_filter_id;
                    
                    WHEN l_filter_type = pk_prog_notes_constants.g_note_type_group THEN
                        l_filter_group := l_filter_id;
                    
                    ELSE
                        l_filter_date      := 10;
                        l_filter_note_type := NULL;
                        l_filter_group     := NULL;
                END CASE;
            END IF;
        END IF;
    
        IF (l_filter_date = 10)
        THEN
            l_start_date := NULL;
            l_end_date   := NULL;
        ELSE
            g_error := 'CALL get_scale_dates_map. i_filter: ' || l_filter_date;
            pk_alertlog.log_debug(g_error);
            IF NOT get_scale_dates_map(i_lang       => i_lang,
                                       i_prof       => i_prof,
                                       i_scale      => l_filter_date,
                                       o_start_date => l_start_date,
                                       o_end_date   => l_end_date,
                                       o_error      => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF i_flg_category IS NOT NULL
        THEN
            IF i_flg_category = 'F'
            THEN
                /*  SELECT a.internal_name
                 BULK COLLECT
                 INTO l_pn_area
                 FROM pn_area a
                WHERE a.id_category IN ();*/
                l_pn_area := table_varchar(pk_prog_notes_constants.g_area_dpn,
                                           pk_prog_notes_constants.g_area_rpn,
                                           pk_prog_notes_constants.g_area_psypn,
                                           pk_prog_notes_constants.g_area_cdcpn,
                                           pk_prog_notes_constants.g_area_mtpn,
                                           pk_prog_notes_constants.g_area_rehabpn,
                                           pk_prog_notes_constants.g_area_rcpn,
                                           pk_prog_notes_constants.g_area_swpn,
                                           pk_prog_notes_constants.g_area_dia,
                                           pk_prog_notes_constants.g_area_ria,
                                           pk_prog_notes_constants.g_area_psyia,
                                           pk_prog_notes_constants.g_area_cdcia,
                                           pk_prog_notes_constants.g_area_swia,
                                           pk_prog_notes_constants.g_area_rehabia);
            ELSE
                SELECT id_category
                  BULK COLLECT
                  INTO l_id_category
                  FROM category c
                 WHERE c.flg_type = i_flg_category;
                SELECT a.internal_name
                  BULK COLLECT
                  INTO l_pn_area
                  FROM pn_area a
                 WHERE a.id_category IN (SELECT /*+opt_estimate (table t rows=1)*/
                                          *
                                           FROM TABLE(l_id_category) t);
            END IF;
        ELSE
            l_pn_area.extend;
            l_pn_area(l_pn_area.last) := i_area;
        END IF;
    
        g_error := 'GET CURSOR o_note_ids';
        pk_alertlog.log_debug(g_error);
        IF l_search IS NULL
        THEN
        
            SELECT id
              BULK COLLECT
              INTO o_note_ids
              FROM (SELECT *
                      FROM ((SELECT rownum rn2, t_sorted.*
                               FROM (SELECT decode(l_order_by, pk_prog_notes_constants.g_order_by_desc, 1, -1) *
                                            (current_timestamp - t_internal.dt_pn_date) AS sortcolumn,
                                            rownum rn,
                                            t_internal.*
                                       FROM (SELECT epn.id_epis_pn id,
                                                    epn.flg_status,
                                                    CASE
                                                         WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c THEN
                                                          1
                                                         ELSE
                                                          0
                                                     END status_sort,
                                                    epn.dt_pn_date
                                               FROM epis_pn epn
                                              INNER JOIN episode epi
                                                 ON epi.id_episode = epn.id_episode
                                             --filter by the configured notes by of the current area
                                              INNER JOIN pn_area pna
                                                 ON epn.id_pn_area = pna.id_pn_area
                                              WHERE pna.internal_name IN (SELECT /*+opt_estimate (table a rows=10)*/
                                                                           column_value
                                                                            FROM TABLE(l_pn_area) a) --i_area
                                                AND (epn.id_episode = i_id_episode OR
                                                    i_flg_scope = pk_prog_notes_constants.g_flg_scope_p)
                                                AND epi.id_patient = l_id_patient
                                                AND (epn.id_epis_pn = i_id_epis_pn OR i_id_epis_pn IS NULL)
                                                   --filter by date
                                                AND (l_start_date IS NULL OR
                                                    (epn.dt_pn_date >= l_start_date AND epn.dt_pn_date < l_end_date))
                                                   --filter by NOTE_TYPE
                                                AND (l_filter_note_type IS NULL OR epn.id_pn_note_type = l_filter_note_type)
                                                   --filter by NOTE_TYPE_GROUP
                                                AND (l_filter_group IS NULL OR
                                                    epn.id_pn_note_type IN
                                                    (SELECT pnt.id_pn_note_type
                                                        FROM pn_note_type pnt
                                                       WHERE pnt.id_pn_note_type_group = l_filter_group))) t_internal
                                      ORDER BY status_sort, sortcolumn) t_sorted) t)
                     WHERE (i_start_record IS NULL OR
                           (rn2 BETWEEN i_start_record + 1 AND (i_start_record + i_num_records))));
        
        ELSE
        
            SELECT id
              BULK COLLECT
              INTO o_note_ids
              FROM (SELECT *
                      FROM ((SELECT rownum rn2, t_sorted.*
                               FROM (SELECT decode(l_order_by, pk_prog_notes_constants.g_order_by_desc, 1, -1) *
                                            (current_timestamp - t_internal.dt_pn_date) AS sortcolumn,
                                            rownum rn,
                                            t_internal.*
                                       FROM (SELECT /*+opt_estimate (table t rows=10)*/
                                              epn.id_epis_pn id,
                                              epn.flg_status,
                                              CASE
                                                   WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c THEN
                                                    1
                                                   ELSE
                                                    0
                                               END status_sort,
                                              epn.dt_pn_date
                                               FROM epis_pn epn
                                              INNER JOIN TABLE(pk_prog_notes_grids.search_epis_note(i_lang, l_search, l_id_patient, i_id_episode)) t
                                                 ON t.id_epis_pn = epn.id_epis_pn
                                              INNER JOIN episode epi
                                                 ON epi.id_episode = epn.id_episode
                                             --filter by the configured notes by of the current area
                                              INNER JOIN pn_area pna
                                                 ON epn.id_pn_area = pna.id_pn_area
                                              WHERE pna.internal_name IN (SELECT /*+opt_estimate (table a rows=10)*/
                                                                           column_value
                                                                            FROM TABLE(l_pn_area) a) --i_area
                                                AND (epn.id_episode = i_id_episode OR
                                                    i_flg_scope = pk_prog_notes_constants.g_flg_scope_p)
                                                AND epi.id_patient = l_id_patient
                                                AND (epn.id_epis_pn = i_id_epis_pn OR i_id_epis_pn IS NULL)
                                                   --filter by date
                                                AND (l_start_date IS NULL OR
                                                    (epn.dt_pn_date >= l_start_date AND epn.dt_pn_date < l_end_date))
                                                   --filter by NOTE_TYPE
                                                AND (l_filter_note_type IS NULL OR epn.id_pn_note_type = l_filter_note_type)
                                                   --filter by NOTE_TYPE_GROUP
                                                AND (l_filter_group IS NULL OR
                                                    epn.id_pn_note_type IN
                                                    (SELECT pnt.id_pn_note_type
                                                        FROM pn_note_type pnt
                                                       WHERE pnt.id_pn_note_type_group = l_filter_group))) t_internal
                                      ORDER BY status_sort, sortcolumn) t_sorted) t)
                     WHERE (i_start_record IS NULL OR
                           (rn2 BETWEEN i_start_record + 1 AND (i_start_record + i_num_records))));
        
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
                                              'GET_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_notes;

    /********************************************************************************************
    * Returns Number of records to display in each page
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)    
    * @param I_ID_EPISODE            Episode identifier
    * @param I_AREA                  Area Internal Name
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        err_general_exception EXCEPTION;
        l_pn_area t_rec_area;
    BEGIN
        g_error   := 'Call PK_PROG_NOTES_CORE.GET_AREA_CONFIG';
        l_pn_area := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_episode       => i_id_episode,
                                                         i_id_market        => NULL,
                                                         i_id_department    => NULL,
                                                         i_id_dep_clin_serv => NULL,
                                                         i_area             => i_area,
                                                         i_episode_software => NULL);
    
        --If nothing configured
        IF l_pn_area.id_pn_area IS NULL
        THEN
            RAISE err_general_exception;
        END IF;
    
        o_num_records := l_pn_area.nr_rec_page_summary;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
        WHEN err_general_exception THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_num_page_records',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_num_page_records;

    /*******************************************************************************************************************************************
    * get_epis_pnotes_count          Get number of all notes of the given type associated with the current episode.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode             ID_EPISODE identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area internal name
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter 
    * @param o_num_epis_pn            Returns the number of records for the search criteria
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_epis_pnotes_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_patient  IN patient.id_patient%TYPE DEFAULT NULL,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_scope   IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e,
        i_area        IN pn_area.internal_name%TYPE,
        i_search      IN VARCHAR2,
        i_filter      IN VARCHAR2,
        o_num_epis_pn OUT NUMBER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
    
        IF NOT get_notes(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_id_episode   => i_id_episode,
                         i_id_patient   => i_id_patient,
                         i_id_epis_pn   => i_id_epis_pn,
                         i_flg_scope    => i_flg_scope,
                         i_area         => i_area,
                         i_start_record => NULL,
                         i_num_records  => NULL,
                         i_search       => i_search,
                         i_filter       => i_filter,
                         o_note_ids     => l_note_ids,
                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_note_ids IS NOT NULL)
        THEN
            o_num_epis_pn := l_note_ids.count;
        ELSE
            o_num_epis_pn := 0;
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
                                              'GET_EPIS_HIDRICS_COUNT',
                                              o_error);
        
            o_num_epis_pn := 0;
            RETURN FALSE;
    END get_epis_pnotes_count;

    /**
    * This functions receives the note text and if the data block refers to one that has parents concatenates
    * the data block desc and indent the note text
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_data_block          Data block id
    * @param i_pn_note                Note text 
    * @param i_id_pn_soap_block       soap block id
    * @param i_id_pn_note_type        Note Type identifier
    * @param i_market                 Market id
    * @param i_pos_nr                 Position nr
    * @param i_id_pn_note             Note id
    * @param i_id_episode             Episode id
    * @param i_id_dep_clin_serv       Dep_clin_serv id
    * @param i_id_department          Department id
    * @param i_id_episode             Episode id
    * @param i_id_software            Software id
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          08-Feb-2011
    */
    FUNCTION get_data_blocks_txt
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_data_block    IN epis_pn_det.id_pn_data_block%TYPE,
        i_pn_note          IN epis_pn_det.pn_note%TYPE,
        i_id_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_pos_nr           IN PLS_INTEGER,
        i_id_pn_note       IN epis_pn.id_epis_pn%TYPE,
        i_id_dep_clin_serv IN epis_pn.id_dep_clin_serv%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_episode       IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_software      IN software.id_software%TYPE,
        i_bold_dblock      IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search       IN table_varchar DEFAULT NULL
    ) RETURN CLOB IS
        l_error                t_error_out;
        l_levels               table_number;
        l_flg_show_title       table_varchar;
        l_data_block_descs     table_varchar;
        l_pn_desc              VARCHAR2(1000 CHAR);
        l_note                 CLOB;
        l_count_sblock_childs  PLS_INTEGER := 0;
        l_dblock_pos           PLS_INTEGER := 1;
        l_parent_dblock_pos    PLS_INTEGER := 1;
        l_parents              table_number := table_number();
        l_pos_nr               PLS_INTEGER;
        l_found_previous_child BOOLEAN := FALSE;
        j                      NUMBER;
        l_num_no_title         NUMBER := 0;
        l_add_enter            VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_data_block_no_title  table_number;
    BEGIN
    
        --set global structure if necessary            
        IF (g_dblock_ctx.id_epis_pn <> i_id_pn_note OR g_dblock_ctx.id_epis_pn IS NULL)
        THEN
            g_dblock_ctx.id_epis_pn := i_id_pn_note;
        
            g_error := 'CALL pk_progress_notes_upd.tf_data_blocks: i_id_market: ' || i_id_market ||
                       ' i_id_department: ' || i_id_department || ' i_id_dep_clin_serv: ' || i_id_dep_clin_serv ||
                       ' i_id_pn_note_type: ' || i_id_pn_note_type;
            pk_alertlog.log_debug(g_error);
        
            SELECT t_rec_dblock(id_pn_soap_block,
                                id_pn_data_block,
                                flg_type,
                                data_area,
                                id_doc_area,
                                code_pn_data_block,
                                id_department,
                                id_dep_clin_serv,
                                flg_import,
                                flg_select,
                                flg_scope,
                                dblock_count,
                                flg_actions_available,
                                id_swf_file_viewer,
                                flg_line_on_boxes,
                                gender,
                                age_min,
                                age_max,
                                flg_pregnant,
                                flg_outside_period,
                                days_available_period,
                                flg_mandatory,
                                flg_cp_no_changes_import,
                                flg_import_date,
                                id_sys_button_viewer,
                                flg_group_on_import,
                                rank,
                                flg_wf_viewer,
                                id_pndb_parent,
                                flg_struct_type,
                                flg_show_title,
                                flg_show_sub_title,
                                flg_data_removable,
                                auto_pop_exec_prof_cat,
                                id_summary_page,
                                flg_focus,
                                flg_editable,
                                flg_group_select_filter,
                                id_task_type_ftxt,
                                flg_order_type,
                                flg_signature,
                                flg_min_value,
                                flg_default_value,
                                flg_max_value,
                                flg_format,
                                flg_validation,
                                id_pndb_related,
                                value_viewer,
                                file_name,
                                file_extension,
                                id_mtos_score,
                                min_days_period,
                                max_days_period,
                                default_days_period,
                                flg_exc_sum_page_da,
                                flg_group_type,
                                desc_function)
              BULK COLLECT
              INTO g_dblock_ctx.data_blocks_note
              FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof            => i_prof,
                                                              i_market          => i_id_market,
                                                              i_department      => i_id_department,
                                                              i_dcs             => i_id_dep_clin_serv,
                                                              i_id_pn_note_type => i_id_pn_note_type,
                                                              i_id_episode      => i_id_episode,
                                                              i_software        => i_id_software,
                                                              i_flg_search      => i_flg_search)) t
             WHERE t.flg_struct_type <> pk_prog_notes_constants.g_struct_type_import_i;
        
            g_dblock_ctx.filled_dblocks := table_number();
        END IF;
    
        --get data block descriptions and its parents
        g_error := 'GET data block descs. i_id_data_block: ' || i_id_data_block || ' i_id_pn_soap_block: ' ||
                   i_id_pn_soap_block;
        pk_alertlog.log_debug(g_error);
        SELECT t.level_nr,
               flg_show_title,
               decode(t.rn,
                      1,
                      '  ' || decode(i_bold_dblock,
                                     pk_alert_constant.get_yes,
                                     '<b>' || t.desc_data_block || '</b>',
                                     t.desc_data_block),
                      '  ' || t.desc_data_block)
          BULK COLLECT
          INTO l_levels, l_flg_show_title, l_data_block_descs
          FROM (SELECT level_nr, id_pn_data_block, id_pndb_parent, flg_show_title, desc_data_block, rownum rn
                  FROM (SELECT /*+ OPT_ESTIMATE (TABLE pdb ROWS=1)*/
                         LEVEL level_nr,
                         pdb.id_pn_data_block,
                         pdb.id_pndb_parent,
                         pdb.flg_show_title,
                         --change translation to sys_message start
                         --pk_translation.get_translation(i_lang, pdb.code_pn_data_block) desc_data_block
                         pk_message.get_message(i_lang, i_prof, pdb.code_pn_data_block) desc_data_block
                        --change translation to sys_message end
                          FROM TABLE(g_dblock_ctx.data_blocks_note) pdb
                        CONNECT BY PRIOR pdb.id_pndb_parent = pdb.id_pn_data_block
                         START WITH pdb.id_pn_data_block = i_id_data_block
                                AND pdb.id_pn_soap_block = i_id_pn_soap_block
                         ORDER BY LEVEL DESC)
                 WHERE level_nr < 3) t;
    
        IF (l_data_block_descs.count > 0 AND TRIM(l_data_block_descs(1)) IS NOT NULL)
        THEN
            IF (g_dblock_ctx.id_pn_soap_block <> i_id_pn_soap_block OR g_dblock_ctx.id_pn_soap_block IS NULL)
            THEN
            
                g_dblock_ctx.id_pn_soap_block := i_id_pn_soap_block;
            
                --get all data blocks configured for the given soap block, to check the position of the i_id_data_block
                -- this is useful to check if it is the first child (it is necessary to show the parent description)
                SELECT db.id_pn_data_block
                  BULK COLLECT
                  INTO g_dblock_ctx.dblocks
                  FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                         t.id_pn_data_block, rownum rank
                          FROM TABLE(g_dblock_ctx.data_blocks_note) t
                         WHERE t.id_pn_soap_block = i_id_pn_soap_block
                         ORDER BY rank) db;
            
            END IF;
            SELECT id_pn_data_block
              BULK COLLECT
              INTO l_data_block_no_title
              FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                     t.id_pn_data_block, rownum rank
                      FROM TABLE(g_dblock_ctx.data_blocks_note) t
                     WHERE t.id_pn_soap_block = i_id_pn_soap_block
                       AND t.flg_show_title = pk_alert_constant.g_no
                     ORDER BY rank) db;
        
            --set structure with the list of the data blocks with text
            g_dblock_ctx.filled_dblocks.extend(1);
            g_dblock_ctx.filled_dblocks(g_dblock_ctx.filled_dblocks.last) := i_id_data_block;
        
            l_dblock_pos := pk_utils.search_table_number(i_table => g_dblock_ctx.dblocks, i_search => i_id_data_block);
        
            -- if the soap block has several data blocks and the current data block is not the 1st one
            IF (g_dblock_ctx.dblocks.count > 1 AND l_dblock_pos > 1)
            THEN
                SELECT /*+ OPT_ESTIMATE (TABLE p ROWS=1)*/
                 p.id_pndb_parent
                  BULK COLLECT
                  INTO l_parents
                  FROM TABLE(g_dblock_ctx.data_blocks_note) p
                 WHERE p.id_pn_data_block IN (i_id_data_block, g_dblock_ctx.dblocks(l_dblock_pos - 1));
            
                IF (l_parents(1) IS NULL OR l_parents(2) IS NULL OR l_parents(1) <> l_parents(2))
                THEN
                    l_pos_nr := 1;
                ELSE
                    --if the current data block has the same parent as the previous data block
                    IF (l_parents(1) = l_parents(2))
                    THEN
                        IF (g_dblock_ctx.filled_dblocks.exists(1) AND g_dblock_ctx.filled_dblocks.count > 1)
                        THEN
                            --check if there is some child of the same parent filled
                            --check if there is some filled position between the parent and the actual data block
                            l_parent_dblock_pos := pk_utils.search_table_number(i_table  => g_dblock_ctx.dblocks,
                                                                                i_search => l_parents(1));
                        
                            IF (l_dblock_pos > l_parent_dblock_pos + 1)
                            THEN
                                FOR l_db_indx IN l_parent_dblock_pos + 1 .. l_dblock_pos - 1
                                LOOP
                                    IF (pk_utils.search_table_number(i_table  => g_dblock_ctx.filled_dblocks,
                                                                     i_search => g_dblock_ctx.dblocks(l_db_indx)) <> -1)
                                    THEN
                                        l_found_previous_child := TRUE;
                                    END IF;
                                END LOOP;
                            
                            END IF;
                        END IF;
                    END IF;
                
                    IF (l_found_previous_child = TRUE)
                    THEN
                        l_pos_nr := 2;
                    ELSE
                        l_pos_nr := 1;
                    END IF;
                END IF;
            ELSE
                --1st data block of the soap block
                l_pos_nr := i_pos_nr;
            END IF;
        
            -- if only one level exists on the hierarchy check if there is more than one 
            -- data area in the soap block          
            IF (l_levels.count > 0 AND l_levels(1) = 1)
            THEN
                l_count_sblock_childs := g_dblock_ctx.dblocks.count;
            END IF;
        
            g_error := 'l_pos_nr: ' || l_pos_nr;
            pk_alertlog.log_debug(g_error);
            IF (l_pos_nr > 1 AND i_pos_nr > 1)
            THEN
                --it should not be shown the main data block title when the soap block has several levels. 
                --It is shown in the 1st position
                l_data_block_descs := pk_utils.remove_element(i_input => l_data_block_descs, i_pos_to_remove => 1);
                l_pn_desc          := chr(10) || chr(10) ||
                                      pk_utils.concat_table(i_tab => l_data_block_descs, i_delim => chr(10));
            
                IF l_flg_show_title.exists(l_pos_nr)
                   AND l_flg_show_title(l_pos_nr) = pk_alert_constant.get_no
                THEN
                    l_data_block_descs := pk_utils.remove_element(i_input         => l_data_block_descs,
                                                                  i_pos_to_remove => l_pos_nr);
                    l_pn_desc          := ' ';
                END IF;
            
            ELSE
            
                IF l_data_block_descs.count > 0
                THEN
                    j := 1;
                    FOR i IN l_data_block_descs.first .. l_data_block_descs.last
                    LOOP
                        IF l_flg_show_title(i) = pk_alert_constant.g_no
                        THEN
                            IF l_data_block_no_title.count > 0
                            THEN
                                FOR l IN l_data_block_no_title.first .. l_data_block_no_title.last
                                LOOP
                                    IF l_data_block_no_title(l) = i_id_data_block
                                    THEN
                                        l_num_no_title := l;
                                    END IF;
                                END LOOP;
                                IF l_num_no_title = l_data_block_no_title.count
                                THEN
                                    l_add_enter := pk_alert_constant.g_yes;
                                END IF;
                            END IF;
                            l_data_block_descs := pk_utils.remove_element(i_input         => l_data_block_descs,
                                                                          i_pos_to_remove => j,
                                                                          i_replace_enter => l_add_enter);
                        
                        ELSE
                            j := j + 1;
                        END IF;
                    END LOOP;
                END IF;
                IF l_data_block_descs.count > 0
                THEN
                
                    l_pn_desc := CASE
                                     WHEN l_dblock_pos > 1
                                          AND i_pos_nr > 1 THEN
                                      chr(10) --|| chr(10)
                                 END || pk_utils.concat_table(i_tab => l_data_block_descs, i_delim => chr(10));
                ELSE
                    l_pn_desc := ' ';
                END IF;
            END IF;
            IF l_data_block_descs.count > 0
            THEN
                IF l_data_block_descs(1) IS NOT NULL
                THEN
                    l_pn_desc := l_pn_desc || chr(10); --  || chr(10)
                END IF;
            ELSE
                l_pn_desc := ' ';
            END IF;
        ELSIF (NOT l_data_block_descs.exists(1))
        THEN
            --if it is a data block that it is not configured any more in the note
            l_pn_desc := pk_progress_notes_upd.get_block_area_desc(i_lang             => i_lang,
                                                                   i_prof             => i_prof,
                                                                   i_id_pn_data_block => i_id_data_block);
        
            l_note := chr(10) || l_pn_desc || chr(10) ||
                      REPLACE(asciistr(chr(32) || chr(32)) || REPLACE(i_pn_note, chr(13), chr(10)),
                              chr(10),
                              asciistr(chr(10) || chr(32) || chr(32)));
        
        END IF;
    
        IF l_levels.count > 0
           AND l_levels(1) > 1
           OR l_count_sblock_childs > 1
           OR ((l_flg_show_title.exists(1) AND l_flg_show_title(1) = pk_alert_constant.get_yes) OR
           NOT l_flg_show_title.exists(1))
        THEN
            g_error := 'REPLACE new lines in CLOBs';
            pk_alertlog.log_debug(g_error);
            l_note := to_clob(l_pn_desc);
            IF (l_levels.count > 0 AND l_levels(1) = 1)
            THEN
                IF (TRIM(l_pn_desc) IS NULL)
                THEN
                    l_note := REPLACE(asciistr(chr(32) || chr(32) || chr(32) || chr(32)) ||
                                      REPLACE(i_pn_note, chr(13), chr(10)),
                                      chr(10),
                                      asciistr(chr(10) || chr(32) || chr(32) || chr(32) || chr(32)));
                ELSE
                    dbms_lob.append(dest_lob => l_note,
                                    src_lob  => REPLACE(asciistr(chr(32) || chr(32) || chr(32) || chr(32)) ||
                                                        REPLACE(i_pn_note, chr(13), chr(10)),
                                                        chr(10),
                                                        asciistr(chr(10) || chr(32) || chr(32) || chr(32) || chr(32))));
                END IF;
            
            ELSE
                dbms_lob.append(dest_lob => l_note,
                                src_lob  => REPLACE(asciistr(chr(32) || chr(32) || chr(32) || chr(32)) || chr(32) ||
                                                    chr(32) || REPLACE(i_pn_note, chr(13), chr(10)),
                                                    chr(10),
                                                    asciistr(chr(10) || chr(32) || chr(32) || chr(32) || chr(32) ||
                                                             chr(32) || chr(32))));
            
            END IF;
        
        ELSIF l_levels.count > 0
        THEN
            l_note := REPLACE(asciistr(chr(32) || chr(32)) || REPLACE(i_pn_note, chr(13), chr(10)),
                              chr(10),
                              asciistr(chr(10) || chr(32) || chr(32)));
        END IF;
    
        RETURN l_note;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DATA_BLOCKS_TXT',
                                              l_error);
        
            RETURN NULL;
    END get_data_blocks_txt;

    /**
    * Returns the concatenated text of all tasks associated to an epis_pn_det, based on a history time.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn_det         PN Detail ID   
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since               08-Feb-2011
    */
    FUNCTION get_tasks_concat_hist
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det_hist.id_epis_pn_det%TYPE,
        i_dt_hist        IN epis_pn_det_task_hist.dt_epis_pn_det_task_hist%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        l_error t_error_out;
        l_text  CLOB;
    BEGIN
        g_error := 'GET tasks concatenated texts. i_id_epis_pn_det: ' || i_id_epis_pn_det;
        pk_alertlog.log_debug(g_error);
        SELECT pk_utils.concat_table_clob(CAST(MULTISET
                                               (SELECT pk_string_utils.trim_empty_lines_end(epdt.pn_note)
                                                  FROM epis_pn_det_task_hist epdt
                                                 WHERE epdt.id_epis_pn_det = i_id_epis_pn_det
                                                   AND epdt.flg_status =
                                                       pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                   AND epdt.dt_epis_pn_det_task_hist = i_dt_hist
                                                 ORDER BY epdt.rank_task,
                                                          decode(epdt.id_parent,
                                                                 NULL,
                                                                 epdt.dt_task,
                                                                 (SELECT epdt_par.dt_task
                                                                    FROM epis_pn_det_task_hist epdt_par
                                                                   WHERE epdt_par.id_epis_pn_det_task = epdt.id_parent
                                                                     AND epdt_par.flg_status =
                                                                         pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                                     AND epdt_par.dt_epis_pn_det_task_hist = i_dt_hist)) DESC,
                                                          decode(epdt.id_parent,
                                                                 NULL,
                                                                 epdt.dt_last_update,
                                                                 (SELECT epdt_par.dt_last_update
                                                                    FROM epis_pn_det_task_hist epdt_par
                                                                   WHERE epdt_par.id_epis_pn_det_task = epdt.id_parent
                                                                     AND epdt_par.flg_status =
                                                                         pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                                     AND epdt_par.dt_epis_pn_det_task_hist = i_dt_hist)) DESC,
                                                          decode(epdt.id_parent, NULL, NULL, epdt.dt_task) DESC NULLS FIRST,
                                                          decode(epdt.id_parent, NULL, NULL, epdt.dt_last_update) DESC NULLS FIRST) AS
                                               table_clob),
                                          pk_prog_notes_constants.g_enter || pk_prog_notes_constants.g_enter)
          INTO l_text
          FROM dual;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_tasks_concat_hist',
                                              l_error);
        
            RETURN NULL;
    END get_tasks_concat_hist;

    /**
    * Returns the concatenated text containing all texts that compose a soap block section.
    * Get the actual data (can not be used for history data).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode identifier
    * @param i_id_epis_pn             Note id
    * @param i_id_soap_block          Soap block id    
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_market              Market id
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          08-Feb-2011
    */
    FUNCTION get_block_concat_txt
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_soap_block   IN epis_pn_det.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_dblock_exclude  IN table_number DEFAULT NULL,
        i_bold_dblock     IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_note_dash       IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search      IN table_varchar DEFAULT NULL
    ) RETURN CLOB IS
        l_error               t_error_out;
        l_text                CLOB;
        l_msg                 CLOB;
        l_msg_chief_complaint CLOB;
    BEGIN
        g_error := 'GET block concatenated texts. i_id_epis_pn: ' || i_id_epis_pn || '; i_id_soap_block: ' ||
                   i_id_soap_block || '; i_id_pn_note_type: ' || i_id_pn_note_type;
        pk_alertlog.log_debug(g_error);
    
        l_msg                 := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_FT_MSG_01') AS CLOB);
        l_msg_chief_complaint := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_CC_MSG_01') AS CLOB);
        SELECT pk_utils.concat_table_clob(CAST(MULTISET
                                               (SELECT get_data_blocks_txt(i_lang,
                                                                           i_prof,
                                                                           t_internal.id_pn_data_block,
                                                                           t_internal.pn_note,
                                                                           t_internal.id_pn_soap_block,
                                                                           t_internal.id_pn_note_type,
                                                                           i_id_market,
                                                                           rownum,
                                                                           t_internal.id_epis_pn,
                                                                           t_internal.id_dep_clin_serv,
                                                                           t_internal.id_department,
                                                                           i_id_episode,
                                                                           t_internal.id_software,
                                                                           i_bold_dblock,
                                                                           i_flg_search)
                                                  FROM (SELECT /*+ OPT_ESTIMATE (TABLE db ROWS=1)*/
                                                         CASE
                                                              WHEN i_note_dash = pk_alert_constant.g_yes
                                                                   AND epd.id_pn_data_block =
                                                                   pk_prog_notes_constants.g_dblock_vital_sign_tb_143 THEN
                                                               pk_prog_notes_core.get_aggregated_text_clob(i_lang           => i_lang,
                                                                                                           i_prof           => i_prof,
                                                                                                           i_id_epis_pn_det => epd.id_epis_pn_det,
                                                                                                           i_note_dash      => i_note_dash)
                                                          
                                                              WHEN pk_prog_notes_utils.count_tasks(epd.id_epis_pn_det,
                                                                                                   table_varchar(pk_prog_notes_constants.g_epis_pn_det_flg_status_a)) > 0
                                                                   AND (epd.pn_note IS NULL OR length(epd.pn_note) = 0 OR
                                                                        db.flg_import IN
                                                                        (pk_prog_notes_constants.g_import_block)) THEN
                                                               CASE
                                                                   WHEN epd.id_pn_data_block =
                                                                        pk_prog_notes_constants.g_dblock_arabic_chief_compl THEN
                                                                    l_msg_chief_complaint
                                                                   ELSE
                                                                    pk_prog_notes_utils.get_tasks_concat(i_lang,
                                                                                                         i_prof,
                                                                                                         epd.id_epis_pn_det,
                                                                                                         i_flg_detail)
                                                               END
                                                              WHEN epd.id_pn_data_block =
                                                                   pk_prog_notes_constants.g_dblock_arabic_free_text
                                                              /*AND i_flg_detail = pk_alert_constant.g_yes*/
                                                               THEN
                                                               l_msg
                                                              ELSE
                                                               pk_string_utils.trim_empty_lines_end(epd.pn_note)
                                                          END pn_note,
                                                         epd.id_pn_data_block,
                                                         epd.id_pn_soap_block,
                                                         epn.id_pn_note_type,
                                                         epn.flg_status,
                                                         epn.id_epis_pn,
                                                         epn.id_episode,
                                                         epn.id_dep_clin_serv,
                                                         db.id_department,
                                                         epn.id_software
                                                          FROM epis_pn_det epd
                                                          JOIN epis_pn epn
                                                            ON epn.id_epis_pn = epd.id_epis_pn
                                                          LEFT JOIN dep_clin_serv dcs
                                                            ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
                                                          LEFT JOIN TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof, i_id_market, dcs.id_department, dcs.id_dep_clin_serv, i_id_pn_note_type, i_id_episode, NULL, epn.id_software, i_flg_search)) db
                                                            ON epd.id_pn_soap_block = db.id_pn_soap_block
                                                           AND db.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
                                                           AND db.id_department IN (0, dcs.id_department)
                                                           AND epd.id_pn_data_block = db.id_pn_data_block
                                                         WHERE epd.id_pn_soap_block = i_id_soap_block
                                                           AND (i_dblock_exclude IS NULL OR
                                                               epd.id_pn_data_block NOT IN
                                                               (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                                  column_value
                                                                   FROM TABLE(i_dblock_exclude) t))
                                                           AND epd.id_epis_pn = i_id_epis_pn
                                                           AND epd.flg_status =
                                                               pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                         ORDER BY db.rank) t_internal) AS table_clob),
                                          pk_prog_notes_constants.g_enter)
          INTO l_text
          FROM dual;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOCK_CONCAT_TXT',
                                              l_error);
        
            RETURN NULL;
    END get_block_concat_txt;

    /**
    * Returns the concatenated text containing all texts that compose a soap block section.
    * Get the history data (can not be used for actual data).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note id
    * @param i_id_soap_block          Soap block id    
    * @param i_id_pn_note_type        Note type identifier
    * @param i_id_market              Market id
    * @param i_dt_hist                History date
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         Clob with the soap block concatenated texts
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          08-Feb-2011
    */
    FUNCTION get_block_concat_txt_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn_hist.id_epis_pn%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_soap_block   IN epis_pn_det_hist.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_market       IN market.id_market%TYPE,
        i_dt_hist         IN epis_pn_hist.dt_epis_pn_hist%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        l_error               t_error_out;
        l_text                CLOB;
        l_msg_chief_complaint CLOB;
    BEGIN
        g_error := 'GET block concatenated texts. i_id_epis_pn: ' || i_id_epis_pn || '; i_id_soap_block: ' ||
                   i_id_soap_block || '; i_id_pn_note_type: ' || i_id_pn_note_type;
        pk_alertlog.log_debug(g_error);
        l_msg_chief_complaint := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_CC_MSG_01') AS CLOB);
        IF i_id_pn_note_type IN (pk_prog_notes_constants.g_note_type_arabic_ft,
                                 pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                 pk_prog_notes_constants.g_note_type_arabic_ft_sw)
           AND i_id_soap_block = 17
        THEN
            l_text := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_FT_MSG_01') AS CLOB);
        ELSIF i_id_pn_note_type IN (pk_prog_notes_constants.g_note_psych_assess)
              AND i_id_soap_block = 3026
        THEN
            l_text := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_CC_MSG_01') AS CLOB);
        ELSE
        
            SELECT pk_utils.concat_table_clob(CAST(MULTISET
                                                   (SELECT get_data_blocks_txt(i_lang,
                                                                               i_prof,
                                                                               t_internal.id_pn_data_block,
                                                                               t_internal.pn_note,
                                                                               t_internal.id_pn_soap_block,
                                                                               t_internal.id_pn_note_type,
                                                                               i_id_market,
                                                                               rownum,
                                                                               t_internal.id_epis_pn,
                                                                               t_internal.id_dep_clin_serv,
                                                                               t_internal.id_department,
                                                                               t_internal.id_episode,
                                                                               t_internal.id_software)
                                                      FROM (SELECT /*+ OPT_ESTIMATE (TABLE db ROWS=1)*/
                                                             CASE
                                                                  WHEN epd.id_pn_data_block =
                                                                       pk_prog_notes_constants.g_dblock_arabic_chief_compl THEN
                                                                   l_msg_chief_complaint
                                                                  ELSE
                                                                   CASE
                                                                       WHEN pk_prog_notes_utils.count_tasks(epd.id_epis_pn_det,
                                                                                                            table_varchar(pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                                                                                                          pk_prog_notes_constants.g_epis_pn_det_flg_status_r)) > 0
                                                                            AND (epd.pn_note IS NULL OR length(epd.pn_note) = 0 OR
                                                                                 db.flg_import IN
                                                                                 (pk_prog_notes_constants.g_import_block)) THEN
                                                                       
                                                                        get_tasks_concat_hist(i_lang,
                                                                                              i_prof,
                                                                                              epd.id_epis_pn_det,
                                                                                              epd.dt_epis_pn_det_hist,
                                                                                              i_flg_detail)
                                                                   
                                                                       ELSE
                                                                        epd.pn_note
                                                                   END
                                                              END pn_note,
                                                             epd.id_pn_data_block,
                                                             epd.id_pn_soap_block,
                                                             epn.id_pn_note_type,
                                                             epn.flg_status,
                                                             epn.id_epis_pn,
                                                             epn.id_episode,
                                                             epn.id_dep_clin_serv,
                                                             db.id_department,
                                                             epn.id_software
                                                              FROM epis_pn_det_hist epd
                                                              JOIN epis_pn_hist epn
                                                                ON epn.id_epis_pn = epd.id_epis_pn
                                                              LEFT JOIN dep_clin_serv dcs
                                                                ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
                                                              LEFT JOIN TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof, i_id_market, dcs.id_department, dcs.id_dep_clin_serv, i_id_pn_note_type, i_id_episode, NULL, epn.id_software)) db
                                                                ON epd.id_pn_soap_block = db.id_pn_soap_block
                                                               AND db.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
                                                               AND db.id_department IN (0, dcs.id_department)
                                                               AND epd.id_pn_data_block = db.id_pn_data_block
                                                             WHERE epd.id_pn_soap_block = i_id_soap_block
                                                               AND epd.id_epis_pn = i_id_epis_pn
                                                               AND epd.dt_epis_pn_det_hist = i_dt_hist
                                                               AND epn.dt_epis_pn_hist = i_dt_hist
                                                               AND epd.flg_status =
                                                                   pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                             ORDER BY db.rank) t_internal) AS table_clob),
                                              pk_prog_notes_constants.g_enter)
              INTO l_text
              FROM dual;
        
        END IF;
    
        RETURN l_text;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_BLOCK_CONCAT_TXT_HIST',
                                              l_error);
        
            RETURN NULL;
    END get_block_concat_txt_hist;

    /**
    * Returns the block texts associated to a note (grouped by soap data block). 
    * Returns an unsorted collection.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_ids               List of notes identifiers
    * @param i_note_status            Notes statuses   
    * @param i_market                 id market
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    * @param i_soap_blocks            List of soap blocks to be considered
    *
    * @return                         Texts info
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts_unsorted
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_note_ids       IN table_number,
        i_note_status    IN table_varchar,
        i_market         IN market.id_market%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_soap_blocks    IN table_number DEFAULT NULL,
        i_dblock_exclude IN table_number DEFAULT NULL,
        i_bold_dblock    IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_note_dash      IN VARCHAR2 DEFAULT pk_alert_constant.get_no,
        i_flg_search     IN table_varchar DEFAULT NULL
    ) RETURN t_table_rec_pn_texts IS
        l_table_texts t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_error       t_error_out;
    BEGIN
    
        g_error := 'OPEN o_notes_texts';
        pk_alertlog.log_debug(g_error);
        SELECT t_rec_pn_texts(ttexts.id_epis_pn,
                              ttexts.id_pn_note_type,
                              ttexts.id_pn_soap_block,
                              NULL,
                              pk_progress_notes_upd.get_soap_block_desc(i_lang, i_prof, ttexts.id_pn_soap_block),
                              pk_progress_notes_upd.get_soap_block_desc_hist(i_lang, i_prof, ttexts.id_pn_soap_block),
                              NULL,
                              NULL,
                              ttexts.note_txt,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL,
                              NULL)
          BULK COLLECT
          INTO l_table_texts
          FROM (
                --sign off and temporarily saved records
                SELECT eps.pn_signoff_note note_txt, eps.id_pn_soap_block, eps.id_epis_pn, epn.id_pn_note_type
                  FROM epis_pn_signoff eps
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = eps.id_epis_pn
                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE ts ROWS=1)*/
                         column_value flg_status
                          FROM TABLE(i_note_status) ts) tst
                    ON tst.flg_status = epn.flg_status
                 WHERE epn.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                           column_value
                                            FROM TABLE(i_note_ids) t)
                   AND epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                          pk_prog_notes_constants.g_epis_pn_flg_submited,
                                          pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
                   AND (i_soap_blocks IS NULL OR
                       eps.id_pn_soap_block IN (SELECT column_value
                                                   FROM TABLE(i_soap_blocks)))
                UNION ALL
                -- in case of cancellation after a just save
                SELECT eps.pn_signoff_note note_txt, eps.id_pn_soap_block, eps.id_epis_pn, epn.id_pn_note_type
                  FROM epis_pn_signoff eps
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = eps.id_epis_pn
                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE ts ROWS=1)*/
                         column_value flg_status
                          FROM TABLE(i_note_status) ts) tst
                    ON tst.flg_status = epn.flg_status
                 WHERE epn.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                           column_value
                                            FROM TABLE(i_note_ids) t)
                   AND epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c
                   AND EXISTS (SELECT 1
                          FROM epis_pn_hist eph
                         WHERE eph.id_epis_pn = epn.id_epis_pn
                           AND eph.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_t)
                   AND (i_soap_blocks IS NULL OR
                       eps.id_pn_soap_block IN (SELECT column_value
                                                   FROM TABLE(i_soap_blocks)))
                UNION ALL
                --drafts
                SELECT get_block_concat_txt(i_lang,
                                             i_prof,
                                             epn.id_epis_pn,
                                             epn.id_episode,
                                             epd.id_pn_soap_block,
                                             epn.id_pn_note_type,
                                             i_market,
                                             i_flg_detail,
                                             i_dblock_exclude,
                                             i_bold_dblock,
                                             i_note_dash,
                                             i_flg_search) note_txt,
                        epd.id_pn_soap_block id_pn_soap_block,
                        epn.id_epis_pn id_epis_pn,
                        epn.id_pn_note_type
                  FROM epis_pn_det epd
                  JOIN epis_pn epn
                    ON epn.id_epis_pn = epd.id_epis_pn
                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE ts ROWS=1)*/
                         column_value flg_status
                          FROM TABLE(i_note_status) ts) tst
                    ON tst.flg_status = epn.flg_status
                
                 WHERE epn.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                           column_value
                                            FROM TABLE(i_note_ids) t)
                      
                   AND epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_c,
                                          pk_prog_notes_constants.g_epis_pn_flg_submited,
                                          pk_prog_notes_constants.g_epis_pn_flg_draftsubmit,
                                          pk_prog_notes_constants.g_epis_pn_flg_for_review)
                   AND (i_soap_blocks IS NULL OR
                       epd.id_pn_soap_block IN (SELECT column_value
                                                   FROM TABLE(i_soap_blocks)))
                   AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                   AND (epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                           pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                           pk_prog_notes_constants.g_epis_pn_flg_submited,
                                           pk_prog_notes_constants.g_epis_pn_flg_draftsubmit,
                                           pk_prog_notes_constants.g_epis_pn_flg_for_review) OR
                       (epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c AND NOT EXISTS
                        (SELECT 1
                            FROM epis_pn_hist eph
                           WHERE eph.id_epis_pn = epn.id_epis_pn
                             AND eph.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_t)))
                 GROUP BY epn.id_epis_pn, epd.id_pn_soap_block, epn.id_pn_note_type, epn.id_episode) ttexts;
    
        RETURN l_table_texts;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_note_block_texts_unsorted',
                                              l_error);
        
            RETURN NULL;
    END get_note_block_texts_unsorted;

    /**
    * Returns the block texts associated to a note (grouped by soap data block).
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_ids               List of notes identifiers
    * @param i_note_status            Notes statuses   
    * @param i_show_title             T-shows the title; B-shows the soap block date; All-shows the both   
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    * @param i_soap_blocks            List of soap blocks to be considered
    *
    * @return                         Texts info
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_note_ids        IN table_number,
        i_note_status     IN table_varchar,
        i_show_title      IN VARCHAR2,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_soap_blocks     IN table_number DEFAULT NULL,
        i_soap_blocks_nin IN table_number DEFAULT NULL,
        i_flg_search      IN table_varchar DEFAULT NULL
    ) RETURN t_table_rec_pn_texts IS
        l_table_texts             t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_error                   t_error_out;
        l_market                  market.id_market%TYPE;
        l_pn_soap_block_nin       table_number;
        l_pn_soap_block_nin_count NUMBER(12);
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        IF i_soap_blocks_nin IS NOT NULL
           AND i_soap_blocks_nin.exists(1)
        THEN
            l_pn_soap_block_nin := i_soap_blocks_nin;
        ELSE
            l_pn_soap_block_nin := table_number();
        END IF;
        l_pn_soap_block_nin_count := l_pn_soap_block_nin.count;
    
        g_error := 'GET notes texts';
        pk_alertlog.log_debug(g_error);
        SELECT /*+ OPT_ESTIMATE (TABLE sb ROWS=1)*/
         t_rec_pn_texts(ttexts.id_epis_pn,
                        ttexts.id_note_type,
                        ttexts.id_pn_soap_block,
                        NULL,
                        decode(sb.flg_show_title, pk_prog_notes_constants.g_no, NULL, ttexts.soap_block_desc),
                        pk_progress_notes_upd.get_soap_block_desc_hist(i_lang, i_prof, ttexts.id_pn_soap_block),
                        NULL,
                        NULL,
                        ttexts.soap_block_txt,
                        NULL,
                        sb.rank,
                        NULL,
                        NULL,
                        NULL,
                        NULL)
          BULK COLLECT
          INTO l_table_texts
          FROM (SELECT /*+ OPT_ESTIMATE (TABLE tb ROWS=1)*/
                 tb.id_note         id_epis_pn,
                 tb.id_soap_block   id_pn_soap_block,
                 tb.soap_block_desc,
                 tb.soap_block_txt,
                 tb.id_note_type
                  FROM TABLE(get_note_block_texts_unsorted(i_lang        => i_lang,
                                                           i_prof        => i_prof,
                                                           i_note_ids    => i_note_ids,
                                                           i_note_status => i_note_status,
                                                           i_market      => l_market,
                                                           i_flg_detail  => i_flg_detail,
                                                           i_soap_blocks => i_soap_blocks,
                                                           i_flg_search  => i_flg_search)) tb
                 WHERE l_pn_soap_block_nin_count = 0
                    OR tb.id_soap_block NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                 column_value
                                                  FROM TABLE(l_pn_soap_block_nin) t)) ttexts
          JOIN epis_pn epn
            ON epn.id_epis_pn = ttexts.id_epis_pn
          LEFT JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_sblock(i_prof, epn.id_episode, l_market, dcs.id_department, epn.id_dep_clin_serv, epn.id_pn_note_type, epn.id_software)) sb
            ON sb.id_pn_soap_block = ttexts.id_pn_soap_block
           AND sb.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND sb.id_department IN (0, dcs.id_department)
         WHERE ((i_show_title IN (pk_prog_notes_constants.g_show_block_b, pk_prog_notes_constants.g_show_all)) OR
               (i_show_title = pk_prog_notes_constants.g_show_title_t AND
               check_data_block_type(i_lang, i_prof, epn.id_episode, epn.id_pn_note_type, sb.id_pn_soap_block) =
               pk_alert_constant.g_yes))
         ORDER BY sb.rank;
    
        RETURN l_table_texts;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_note_block_texts',
                                              l_error);
        
            RETURN NULL;
    END get_note_block_texts;

    /**
    * Returns the data block texts associated to a note.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_note_ids               List of notes identifiers
    * @param i_note_status            Notes statuses    
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          26-Jan-2011
    */
    FUNCTION get_note_dblock_texts
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_note_id         IN epis_pn.id_epis_pn%TYPE,
        i_note_status     IN epis_pn.flg_status%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_rec_pn_texts IS
        l_market              market.id_market%TYPE;
        l_tab_texts           t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_error               t_error_out;
        l_msg_chief_complaint CLOB;
    
    BEGIN
        l_market              := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_msg_chief_complaint := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_CC_MSG_01') AS CLOB);
    
        g_error := 'GET data block info';
        pk_alertlog.log_debug(g_error);
        SELECT /*+ OPT_ESTIMATE (TABLE db ROWS=1)*/ /*+ OPT_ESTIMATE (TABLE sb ROWS=1)*/
         t_rec_pn_texts(epd.id_epis_pn,
                         epn.id_pn_note_type,
                         epd.id_pn_soap_block,
                         epd.id_pn_data_block,
                         pk_progress_notes_upd.get_soap_block_desc(i_lang, i_prof, epd.id_pn_soap_block),
                         pk_progress_notes_upd.get_soap_block_desc_hist(i_lang, i_prof, epd.id_pn_soap_block),
                         pk_progress_notes_upd.get_block_area_desc(i_lang, i_prof, epd.id_pn_data_block),
                         pk_progress_notes_upd.get_block_area_desc_hist(i_lang, i_prof, epd.id_pn_data_block),
                         NULL,
                         
                         CASE
                             WHEN epd.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_chief_compl THEN
                              l_msg_chief_complaint
                             ELSE
                              CASE
                                  WHEN pk_prog_notes_utils.count_tasks(epd.id_epis_pn_det,
                                                                       table_varchar(pk_prog_notes_constants.g_epis_pn_det_flg_status_a)) > 0
                                       AND (epd.pn_note IS NULL OR length(epd.pn_note) = 0 OR
                                            db.flg_import IN (pk_prog_notes_constants.g_import_block)) THEN
                                   pk_prog_notes_utils.get_tasks_concat(i_lang, i_prof, epd.id_epis_pn_det, i_flg_detail)
                                  ELSE
                                   epd.pn_note
                              END
                         END,
                         
                         sb.rank,
                         epd.flg_status,
                         db.rank,
                         NULL,
                         NULL)
          BULK COLLECT
          INTO l_tab_texts
          FROM epis_pn_det epd
          JOIN epis_pn epn
            ON epn.id_epis_pn = epd.id_epis_pn
          LEFT JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof, l_market, dcs.id_department, dcs.id_dep_clin_serv, i_id_pn_note_type, i_id_episode, NULL, epn.id_software)) db
            ON epd.id_pn_soap_block = db.id_pn_soap_block
           AND db.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND db.id_department IN (0, dcs.id_department)
           AND epd.id_pn_data_block = db.id_pn_data_block
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_sblock(i_prof, epn.id_episode, l_market, dcs.id_department, dcs.id_dep_clin_serv, epn.id_pn_note_type, epn.id_software)) sb
            ON sb.id_pn_soap_block = db.id_pn_soap_block
           AND sb.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND sb.id_department IN (0, dcs.id_department)
         WHERE epd.id_epis_pn = i_note_id
           AND epn.flg_status = i_note_status
           AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
         ORDER BY sb.rank, db.rank;
    
        RETURN l_tab_texts;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTE_DBLOCK_TEXTS',
                                              l_error);
        
            RETURN NULL;
    END get_note_dblock_texts;

    /**
    * Returns the data block texts associated to a note. HISTORY data
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_note_id                List of notes identifiers
    * @param i_note_status            Notes statuses    
    * @param i_dt_hist            
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise 
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          26-Jan-2011
    */
    FUNCTION get_note_dblock_texts_hist
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_note_id         IN epis_pn.id_epis_pn%TYPE,
        i_note_status     IN epis_pn.flg_status%TYPE,
        i_dt_hist         IN epis_pn_hist.dt_epis_pn_hist%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_detail      IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_rec_pn_texts IS
        l_market              market.id_market%TYPE;
        l_tab_texts           t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_error               t_error_out;
        l_msg_chief_complaint CLOB;
    
    BEGIN
        l_market              := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_msg_chief_complaint := CAST(pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_CC_MSG_01') AS CLOB);
    
        g_error := 'Get data block history info';
        pk_alertlog.log_debug(g_error);
        SELECT /*+ OPT_ESTIMATE (TABLE db ROWS=1)*/ /*+ OPT_ESTIMATE (TABLE sb ROWS=1)*/
         t_rec_pn_texts(epd.id_epis_pn,
                         epn.id_pn_note_type,
                         epd.id_pn_soap_block,
                         epd.id_pn_data_block,
                         nvl(pk_progress_notes_upd.get_block_area_desc(i_lang, i_prof, epd.id_pn_data_block),
                             pk_progress_notes_upd.get_soap_block_desc(i_lang, i_prof, epd.id_pn_soap_block)),
                         nvl(pk_progress_notes_upd.get_block_area_desc_hist(i_lang, i_prof, epd.id_pn_data_block),
                             pk_progress_notes_upd.get_soap_block_desc_hist(i_lang, i_prof, epd.id_pn_soap_block)),
                         pk_progress_notes_upd.get_block_area_desc(i_lang, i_prof, epd.id_pn_data_block),
                         pk_progress_notes_upd.get_block_area_desc_hist(i_lang, i_prof, epd.id_pn_data_block),
                         NULL,
                         
                         CASE
                             WHEN epd.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_chief_compl THEN
                              l_msg_chief_complaint
                             ELSE
                              CASE
                                  WHEN pk_prog_notes_utils.count_tasks(epd.id_epis_pn_det,
                                                                       table_varchar(pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                                                                     pk_prog_notes_constants.g_epis_pn_det_flg_status_r)) > 0
                                       AND (epd.pn_note IS NULL OR length(epd.pn_note) = 0 OR
                                            db.flg_import IN (pk_prog_notes_constants.g_import_block)) THEN
                                   get_tasks_concat_hist(i_lang, i_prof, epd.id_epis_pn_det, epd.dt_epis_pn_det_hist, i_flg_detail)
                                  ELSE
                                   epd.pn_note
                              END
                         END,
                         sb.rank,
                         epd.flg_status,
                         db.rank,
                         NULL,
                         NULL)
          BULK COLLECT
          INTO l_tab_texts
          FROM epis_pn_det_hist epd
          JOIN epis_pn_hist epn
            ON epn.id_epis_pn = epd.id_epis_pn
           AND epn.dt_epis_pn_hist = i_dt_hist
          LEFT JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof, l_market, dcs.id_department, dcs.id_dep_clin_serv, i_id_pn_note_type, i_id_episode, NULL, epn.id_software)) db
            ON epd.id_pn_soap_block = db.id_pn_soap_block
           AND db.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND db.id_department IN (0, dcs.id_department)
           AND epd.id_pn_data_block = db.id_pn_data_block
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_sblock(i_prof, epn.id_episode, l_market, dcs.id_department, dcs.id_dep_clin_serv, epn.id_pn_note_type, epn.id_software)) sb
            ON sb.id_pn_soap_block = db.id_pn_soap_block
           AND sb.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND sb.id_department IN (0, dcs.id_department)
         WHERE epd.id_epis_pn = i_note_id
           AND epn.flg_status = i_note_status
           AND epd.dt_epis_pn_det_hist = i_dt_hist
           AND epn.dt_epis_pn_hist = i_dt_hist
           AND epd.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
        
         ORDER BY sb.rank, db.rank;
    
        RETURN l_tab_texts;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTE_DBLOCK_TEXTS_HIST',
                                              l_error);
        
            RETURN NULL;
    END get_note_dblock_texts_hist;

    /**
    * Returns the block texts associated to a note (grouped by soap data block) in the history tables.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_id                Note identifier
    * @param i_dt_hist                History date
    * @param i_show_title             T-shows the title; B-shows the soap block date; All-shows the both
    * @param i_flg_detail             Y- detail screen: should be added the template name in the templates related tasks
    *                                 N-otherwise     
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_block_texts_hist
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_note_id    IN epis_pn_hist.id_epis_pn%TYPE,
        i_dt_hist    IN epis_pn_hist.dt_epis_pn_hist%TYPE,
        i_show_title IN VARCHAR2,
        i_flg_detail IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN t_table_rec_pn_texts IS
        l_market      market.id_market%TYPE;
        l_table_texts t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_error       t_error_out;
    BEGIN
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'Get note block texts info';
        pk_alertlog.log_debug(g_error);
        SELECT /*+ OPT_ESTIMATE (TABLE sb ROWS=1)*/
         t_rec_pn_texts(epn.id_epis_pn,
                        epn.id_pn_note_type,
                        ttexts.id_pn_soap_block,
                        NULL,
                        pk_progress_notes_upd.get_soap_block_desc(i_lang, i_prof, ttexts.id_pn_soap_block),
                        pk_progress_notes_upd.get_soap_block_desc_hist(i_lang, i_prof, ttexts.id_pn_soap_block),
                        NULL,
                        NULL,
                        ttexts.note_txt,
                        NULL,
                        sb.rank,
                        NULL,
                        NULL,
                        NULL,
                        NULL)
          BULK COLLECT
          INTO l_table_texts
          FROM (SELECT eps.pn_signoff_note note_txt, eps.id_pn_soap_block, eps.id_epis_pn
                  FROM epis_pn_signoff_hist eps
                  JOIN epis_pn_hist epn
                    ON epn.id_epis_pn = eps.id_epis_pn
                   AND epn.dt_epis_pn_hist = eps.dt_epis_pn_signoff_hist
                 WHERE epn.id_epis_pn = i_note_id
                   AND epn.flg_status IN
                       (pk_prog_notes_constants.g_epis_pn_flg_status_s, pk_prog_notes_constants.g_epis_pn_flg_status_t)
                   AND eps.dt_epis_pn_signoff_hist = i_dt_hist
                UNION ALL
                SELECT eps.pn_signoff_note note_txt, eps.id_pn_soap_block, eps.id_epis_pn
                  FROM epis_pn_signoff eps
                  JOIN epis_pn_hist epn
                    ON epn.id_epis_pn = eps.id_epis_pn
                 WHERE epn.id_epis_pn = i_note_id
                   AND epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                          pk_prog_notes_constants.g_epis_pn_flg_status_f)
                   AND epn.dt_epis_pn_hist = i_dt_hist
                   AND NOT EXISTS
                 (SELECT 1
                          FROM epis_pn_signoff_hist eps
                          JOIN epis_pn_hist epn
                            ON epn.id_epis_pn = eps.id_epis_pn
                           AND epn.dt_epis_pn_hist = eps.dt_epis_pn_signoff_hist
                         WHERE epn.id_epis_pn = i_note_id
                           AND epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_f)
                           AND eps.dt_epis_pn_signoff_hist = i_dt_hist)
                UNION ALL
                SELECT get_block_concat_txt_hist(i_lang,
                                                 i_prof,
                                                 epn2.id_epis_pn,
                                                 epn2.id_episode,
                                                 epd2.id_pn_soap_block,
                                                 epn2.id_pn_note_type,
                                                 l_market,
                                                 epn2.dt_epis_pn_hist,
                                                 i_flg_detail) note_txt,
                       epd2.id_pn_soap_block block_id,
                       epn2.id_epis_pn note_id
                  FROM epis_pn_det_hist epd2
                  JOIN epis_pn_hist epn2
                    ON epn2.id_epis_pn = epd2.id_epis_pn
                 WHERE epn2.id_epis_pn = i_note_id
                   AND epn2.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                           pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                           pk_prog_notes_constants.g_epis_pn_flg_submited,
                                           pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                           pk_prog_notes_constants.g_epis_pn_flg_status_f)
                   AND epd2.dt_epis_pn_det_hist = i_dt_hist
                   AND epn2.dt_epis_pn_hist = i_dt_hist
                   AND epd2.flg_status = pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                 GROUP BY epn2.id_epis_pn,
                          epn2.id_episode,
                          epd2.id_pn_soap_block,
                          epn2.id_pn_note_type,
                          epn2.dt_epis_pn_hist) ttexts
          JOIN epis_pn_hist epn
            ON epn.id_epis_pn = ttexts.id_epis_pn
           AND epn.dt_epis_pn_hist = i_dt_hist
          LEFT JOIN dep_clin_serv dcs
            ON dcs.id_dep_clin_serv = epn.id_dep_clin_serv
          LEFT JOIN TABLE(pk_progress_notes_upd.tf_sblock(i_prof, epn.id_episode, l_market, dcs.id_department, dcs.id_dep_clin_serv, epn.id_pn_note_type, epn.id_software)) sb
            ON sb.id_pn_soap_block = ttexts.id_pn_soap_block
           AND sb.id_dep_clin_serv IN (0, -1, epn.id_dep_clin_serv)
           AND sb.id_department IN (0, dcs.id_department)
         WHERE ((i_show_title IN (pk_prog_notes_constants.g_show_block_b, pk_prog_notes_constants.g_show_all)) OR
               (i_show_title = pk_prog_notes_constants.g_show_title_t AND
               check_data_block_type(i_lang, i_prof, epn.id_episode, epn.id_pn_note_type, sb.id_pn_soap_block) =
               pk_alert_constant.g_yes))
         ORDER BY sb.rank;
    
        RETURN l_table_texts;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_note_block_texts_HIST',
                                              l_error);
        
            RETURN NULL;
    END get_note_block_texts_hist;

    /**
    * Returns the notes texts with the empty blocks.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note identifier
    * @param i_id_note_type           Note type identifier
    * @param i_note_flg_status        Note status flg
    * @param i_area                   Area name. Ex: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note   
    * Can be null in the sign-off confirmation screen 
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @dependencies                   Sign off screen without just save in function get_signoff_note_text (carefull without being a strong cursor o_notes_texts)
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_texts_empty
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_id_note_type    IN epis_pn.id_pn_note_type%TYPE,
        i_note_flg_status IN epis_pn.flg_status%TYPE,
        o_notes_texts     OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_market          market.id_market%TYPE;
        l_all_soap_blocks tab_soap_blocks;
    BEGIN
    
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'CALL pk_progress_notes_upd.get_soap_blocks_list. i_id_episode: ' || i_id_episode ||
                   '; l_id_note_type: ' || i_id_note_type;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_progress_notes_upd.get_soap_blocks_list(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_episode         => i_id_episode,
                                                          i_id_pn_note_type => i_id_note_type,
                                                          i_id_epis_pn      => i_id_epis_pn,
                                                          o_soap_blocks     => l_all_soap_blocks,
                                                          o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'Open o_notes_texts';
        pk_alertlog.log_debug(g_error);
        OPEN o_notes_texts FOR
            SELECT /*+ OPT_ESTIMATE (TABLE sb ROWS=1)*/
             i_id_epis_pn note_id,
             tblocks.id_pn_soap_block block_id,
             decode(tblocks.flg_show_title,
                    pk_prog_notes_constants.g_yes,
                    nvl(ttexts.soap_block_desc,
                        pk_progress_notes_upd.get_soap_block_desc(i_lang, i_prof, tblocks.id_pn_soap_block)),
                    NULL) block_title,
             ttexts.soap_block_txt block_text,
             check_data_block_type(i_lang, i_prof, i_id_episode, i_id_note_type, tblocks.id_pn_soap_block) block_editable,
             CASE
                  WHEN instr(ttexts.soap_block_txt, '[B|ID_TASK:') = 0 THEN
                   pk_alert_constant.g_no
                  ELSE
                   pk_alert_constant.g_yes
              END is_templ_bl
              FROM (SELECT /*+ OPT_ESTIMATE (TABLE tb ROWS=1)*/
                     tb.id_note, tb.id_soap_block id_pn_soap_block, tb.soap_block_desc, tb.soap_block_txt
                      FROM TABLE(pk_prog_notes_grids.get_note_block_texts_unsorted(i_lang,
                                                                                   i_prof,
                                                                                   table_number(i_id_epis_pn),
                                                                                   table_varchar(i_note_flg_status),
                                                                                   l_market)) tb) ttexts
              FULL OUTER JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                t.id_pn_soap_block, t.flg_show_title, rownum rank
                                 FROM TABLE(l_all_soap_blocks) t) tblocks
                ON tblocks.id_pn_soap_block = ttexts.id_pn_soap_block
             ORDER BY tblocks.rank;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_TEXTS_EMPTY',
                                              o_error);
        
            RETURN FALSE;
        
    END get_notes_texts_empty;

    /**
    * Returns the notes texts without the empty blocks
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_note_ids              Note identifiers
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_texts_no_empty
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_note_ids    IN table_number,
        i_search      IN VARCHAR2,
        o_notes_texts OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL get_note_block_texts';
        pk_alertlog.log_debug(g_error);
        OPEN o_notes_texts FOR
            SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
             t.id_note note_id,
             t.id_soap_block block_id,
             t.soap_block_desc block_title,
             pk_prog_notes_utils.highlight_searched_text(t.soap_block_txt, i_search) block_text,
             check_data_block_type(i_lang, i_prof, i_id_episode, t.id_note_type, t.id_soap_block) block_editable,
             CASE
                  WHEN instr(t.soap_block_txt, '[B|ID_TASK:') = 0 THEN
                   pk_alert_constant.g_no
                  ELSE
                   pk_alert_constant.g_yes
              END is_templ_bl
              FROM TABLE(get_note_block_texts(i_lang,
                                              i_prof,
                                              i_note_ids,
                                              
                                              table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                            pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                            pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                                            pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                            --
                                                            pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                            pk_prog_notes_constants.g_epis_pn_flg_draftsubmit,
                                                            pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                            --
                                                            pk_prog_notes_constants.g_epis_pn_flg_status_t),
                                              pk_prog_notes_constants.g_show_all)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_TEXTS_NO_EMPTY',
                                              o_error);
        
            RETURN FALSE;
        
    END get_notes_texts_no_empty;

    /**
    * Returns the note text block (grouped by soap block) to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note identifier
    * @param i_note_ids               Note identifiers
    * @param i_area                   Area name. Ex: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note   
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_texts
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        i_search      IN VARCHAR2,
        i_note_ids    IN table_number,
        i_flg_config  IN VARCHAR2 DEFAULT NULL,
        o_notes_texts OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_show_empty      pn_note_type_mkt.flg_show_empty_blocks%TYPE;
        l_note_flg_status epis_pn.flg_status%TYPE;
        l_id_note_type    pn_note_type.id_pn_note_type%TYPE;
    
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_software      software.id_software%TYPE;
    
        l_no_data_found EXCEPTION;
    
        l_pn_note_type t_rec_note_type;
    BEGIN
        IF (i_id_epis_pn IS NOT NULL AND i_search IS NULL AND
           i_flg_config = pk_prog_notes_constants.g_flg_config_signoff)
        THEN
            --in the sign-off confirmation screen it is configurable if it should appear
            --all the blocks configured for the given type of note or it only appears the soap blocks
            -- that already has some text.   
            SELECT e.flg_status, e.id_pn_note_type, e.id_dep_clin_serv, e.id_software
              INTO l_note_flg_status, l_id_note_type, l_id_dep_clin_serv, l_id_software
              FROM epis_pn e
              LEFT JOIN dep_clin_serv dcs
                ON dcs.id_dep_clin_serv = e.id_dep_clin_serv
             WHERE e.id_epis_pn = i_id_epis_pn;
        
            --Call PK_PROG_NOTES_CORE.GET_NOTE_TYPE_CONFIG
            g_error := 'CALL pk_prog_notes_utils.get_note_type_config: l_id_note_type: ' || l_id_note_type ||
                       ' i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            l_pn_note_type := pk_prog_notes_utils.get_note_type_config(i_lang                => i_lang,
                                                                       i_prof                => i_prof,
                                                                       i_id_episode          => i_id_episode,
                                                                       i_id_profile_template => NULL,
                                                                       i_id_market           => NULL,
                                                                       i_id_department       => NULL,
                                                                       i_id_dep_clin_serv    => l_id_dep_clin_serv,
                                                                       i_id_epis_pn          => NULL,
                                                                       i_id_pn_note_type     => l_id_note_type,
                                                                       i_software            => l_id_software);
        
            --If nothing configured
            IF l_pn_note_type.id_pn_note_type IS NOT NULL
            THEN
                l_show_empty := l_pn_note_type.flg_show_empty_blocks;
            END IF;
        
            IF (l_show_empty = pk_alert_constant.g_yes)
            THEN
                g_error := 'CALL get_notes_texts_empty. i_id_epis_pn: ' || i_id_epis_pn;
                pk_alertlog.log_debug(g_error);
                IF NOT get_notes_texts_empty(i_lang            => i_lang,
                                             i_prof            => i_prof,
                                             i_id_episode      => i_id_episode,
                                             i_id_epis_pn      => i_id_epis_pn,
                                             i_id_note_type    => l_id_note_type,
                                             i_note_flg_status => l_note_flg_status,
                                             o_notes_texts     => o_notes_texts,
                                             o_error           => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
        END IF;
    
        IF (i_id_epis_pn IS NULL OR (i_id_epis_pn IS NOT NULL AND i_search IS NOT NULL) OR
           l_show_empty = pk_alert_constant.g_no OR
           (i_flg_config IS NULL OR i_flg_config <> pk_prog_notes_constants.g_flg_config_signoff))
        THEN
            g_error := 'CALL get_notes_texts_no_empty. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            IF NOT get_notes_texts_no_empty(i_lang        => i_lang,
                                            i_prof        => i_prof,
                                            i_id_episode  => i_id_episode,
                                            i_note_ids    => i_note_ids,
                                            i_search      => i_search,
                                            o_notes_texts => o_notes_texts,
                                            o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_TEXTS',
                                              o_error);
        
            RETURN FALSE;
        
    END get_notes_texts;

    /**
    * Returns the notes data to the summary grid [information relative to all the note]
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_note_ids               Note ids list
    * @param i_area                   Area name. Ex: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note   
    * Can be null in the sign-off confirmation screen 
    * @param o_data                   notes data        
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_data
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_note_ids   IN table_number,
        i_area       IN pn_area.internal_name%TYPE,
        o_data       OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_ready_only VARCHAR(1 CHAR);
        l_no_data_found EXCEPTION;
        l_id_patient patient.id_patient%TYPE;
    BEGIN
    
        l_ready_only := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'READ ONLY PROFILE');
    
        SELECT id_patient
          INTO l_id_patient
          FROM episode
         WHERE id_episode = i_id_episode;
    
        g_error := 'GET NOTES DATA';
        pk_alertlog.log_debug(g_error);
        OPEN o_data FOR
            SELECT id_epis_pn note_id,
                   pk_date_utils.dt_chr_tsz(i_lang, dt_pn_date, i_prof.institution, i_prof.software) note_short_date,
                   pk_date_utils.date_char_hour_tsz(i_lang, dt_pn_date, i_prof.institution, i_prof.software) note_short_hour,
                   id_pn_note_type id_note_type,
                   type_desc note_type_desc,
                   flg_status note_flg_status,
                   CASE
                        WHEN pk_prog_notes_utils.check_has_status(i_lang                 => i_lang,
                                                                  i_prof                 => i_prof,
                                                                  i_flg_status_available => flg_status_available,
                                                                  i_flg_status           => flg_status) =
                             pk_alert_constant.g_yes THEN
                        
                         pk_prog_notes_constants.g_open_parenthesis || status_desc ||
                         pk_prog_notes_constants.g_close_parenthesis
                        ELSE
                         NULL
                    END note_flg_status_desc,
                   --future note show proposed description
                   CASE
                        WHEN flg_edit_condition = pk_prog_notes_constants.g_flg_edit_util_now
                             AND flg_edit = pk_alert_constant.g_no THEN
                         pk_sysdomain.get_domain(pk_prog_notes_constants.g_sd_note_flg_status,
                                                 pk_prog_notes_cal_condition.g_proposed,
                                                 i_lang)
                        ELSE
                         NULL
                    END note_info_desc,
                   prof_signature note_prof_signature,
                   id_prof,
                   flg_change note_flg_ok,
                   decode(flg_change,
                          pk_alert_constant.g_yes,
                          pk_prog_notes_utils.get_flg_cancel(i_lang       => i_lang,
                                                             i_prof       => i_prof,
                                                             i_pn_status  => flg_status,
                                                             i_flg_cancel => flg_cancel,
                                                             i_flg_submit => flg_submit),
                          flg_change) note_flg_cancel,
                   get_nr_addendums_desc(i_lang, i_prof, nr_addendums, NULL, pk_alert_constant.g_yes) note_nr_addendums,
                   CASE
                        WHEN flg_edit = pk_alert_constant.g_no THEN
                         pk_alert_constant.g_no
                        ELSE
                         pk_alert_constant.g_yes
                    END flg_editable,
                   flg_write,
                   id_epis_pn viewer_category,
                   viewer_category_desc,
                   CASE
                        WHEN id_sys_shortcut IS NOT NULL
                             AND pk_access.verify_shortcut(i_lang     => i_lang,
                                                           i_prof     => i_prof,
                                                           i_patient  => l_id_patient,
                                                           i_episode  => i_id_episode,
                                                           i_shortcut => id_sys_shortcut) > 0 THEN
                         id_sys_shortcut
                        ELSE
                         NULL
                    END id_sys_shortcut
            --the no_merge hint is used here because of an ORACLE bug (till 10g, in 11g it is not needed the hint)
            --if no hint is used the columns flg_change and nr_addendums used more that one time in the select above
            -- do not have the correct values
              FROM (SELECT /*+no_merge*/
                     epn.id_epis_pn,
                     epn.dt_pn_date,
                     epn.id_pn_note_type,
                     pk_prog_notes_utils.get_note_type_desc(i_lang,
                                                            i_prof,
                                                            epn.id_pn_note_type,
                                                            pk_prog_notes_constants.g_flg_code_note_type_desc_d) type_desc,
                     epn.flg_status,
                     pk_sysdomain.get_domain(pk_prog_notes_constants.g_sd_note_flg_status, epn.flg_status, i_lang) status_desc,
                     t_notes_type.flg_edit_condition,
                     decode(pk_prog_notes_utils.check_change_note(i_lang,
                                                                  i_prof,
                                                                  epn.flg_status,
                                                                  epn.id_epis_pn,
                                                                  t_notes_type.flg_write,
                                                                  t_notes_type.flg_dictation_editable,
                                                                  t_notes_type.flg_edit_other_prof,
                                                                  t_notes_type.flg_submit),
                            1,
                            pk_alert_constant.g_yes,
                            pk_alert_constant.g_no) flg_change,
                     decode(t_notes_type.flg_write,
                            pk_alert_constant.g_no,
                            pk_alert_constant.g_no,
                            t_notes_type.flg_cancel) flg_cancel,
                     pk_prog_notes_utils.get_signature(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_episode          => epn.id_episode,
                                                        i_id_prof_create      => epn.id_prof_create,
                                                        i_dt_create           => epn.dt_create,
                                                        i_id_prof_last_update => epn.id_prof_last_update,
                                                        i_dt_last_update      => epn.dt_last_update,
                                                        i_id_prof_sign_off    => epn.id_prof_signoff,
                                                        i_dt_sign_off         => epn.dt_signoff,
                                                        i_id_prof_cancel      => epn.id_prof_cancel,
                                                        i_dt_cancel           => epn.dt_cancel,
                                                        i_id_dictation_report => epn.id_dictation_report,
                                                        i_has_addendums       => CASE
                                                                                     WHEN pk_prog_notes_utils.get_nr_addendums_state(i_lang,
                                                                                                                                     i_prof,
                                                                                                                                     epn.id_epis_pn,
                                                                                                                                     NULL,
                                                                                                                                     table_varchar(pk_prog_notes_constants.g_addendum_status_d,
                                                                                                                                                   pk_prog_notes_constants.g_addendum_status_s,
                                                                                                                                                   pk_prog_notes_constants.g_addendum_status_c)) > 0 THEN
                                                                                      pk_alert_constant.g_yes
                                                                                     ELSE
                                                                                      pk_alert_constant.g_no
                                                                                 END,
                                                        i_id_software         => epn.id_software,
                                                        i_id_prof_reviewed    => nvl(epn.id_prof_last_update,
                                                                                     epn.id_prof_create),
                                                        i_dt_reviewed         => epn.dt_reviewed,
                                                        i_id_prof_submit      => epn.id_prof_submit,
                                                        i_dt_submit           => epn.dt_submit,
                                                        i_epis_pn             => epn.id_epis_pn) prof_signature,
                     
                     pk_prog_notes_utils.get_prof_signature(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => epn.id_episode,
                                                            i_id_prof_create      => epn.id_prof_create,
                                                            i_dt_create           => epn.dt_create,
                                                            i_id_prof_last_update => epn.id_prof_last_update,
                                                            i_dt_last_update      => epn.dt_last_update,
                                                            i_id_prof_sign_off    => epn.id_prof_signoff,
                                                            i_dt_sign_off         => epn.dt_signoff,
                                                            i_id_prof_cancel      => epn.id_prof_cancel,
                                                            i_dt_cancel           => epn.dt_cancel,
                                                            i_id_prof_reviewed    => nvl(epn.id_prof_last_update,
                                                                                         epn.id_prof_create),
                                                            i_dt_reviewed         => epn.dt_reviewed) id_prof,
                     pk_prog_notes_utils.get_nr_addendums_state(i_lang,
                                                                i_prof,
                                                                epn.id_epis_pn,
                                                                NULL,
                                                                table_varchar(pk_prog_notes_constants.g_addendum_status_d,
                                                                              pk_prog_notes_constants.g_addendum_status_s,
                                                                              pk_prog_notes_constants.g_addendum_status_f)) nr_addendums,
                     nvl(t_notes_type.flg_edit_after_disch, pk_alert_constant.g_no) flg_edit_after_disch,
                     decode(l_ready_only,
                            pk_alert_constant.g_yes,
                            pk_alert_constant.g_no,
                            nvl(t_notes_type.flg_write, pk_alert_constant.g_no)) flg_write,
                     pk_message.get_message(i_lang, i_prof, pnnt.code_pn_note_type) viewer_category_desc,
                     t_notes_type.flg_status_available,
                     t_notes_type.flg_submit,
                     pk_prog_notes_utils.get_flg_editable(i_lang                 => i_lang,
                                                          i_prof                 => i_prof,
                                                          i_id_episode           => i_id_episode,
                                                          i_id_epis_pn           => epn.id_epis_pn,
                                                          i_editable_nr_min      => t_notes_type.editable_nr_min,
                                                          i_flg_edit_after_disch => t_notes_type.flg_edit_after_disch,
                                                          i_flg_synchronized     => t_notes_type.flg_synchronized,
                                                          i_id_pn_note_type      => t_notes_type.id_pn_note_type,
                                                          i_flg_edit_only_last   => t_notes_type.flg_edit_only_last,
                                                          i_flg_edit_condition   => t_notes_type.flg_edit_condition) flg_edit,
                     a.id_sys_shortcut
                      FROM epis_pn epn
                     INNER JOIN pn_note_type pnnt
                        ON epn.id_pn_note_type = pnnt.id_pn_note_type
                     INNER JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                 column_value epis_note_id, rownum rank
                                  FROM TABLE(i_note_ids) t) tids
                        ON tids.epis_note_id = epn.id_epis_pn
                      LEFT OUTER JOIN TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang, i_prof, epn.id_episode, NULL, NULL, NULL, NULL, NULL, table_varchar(i_area), NULL, pk_prog_notes_constants.g_pn_flg_scope_area_a, epn.id_software)) t_notes_type
                        ON epn.id_pn_note_type = t_notes_type.id_pn_note_type
                      JOIN pn_area a
                        ON epn.id_pn_area = a.id_pn_area
                     ORDER BY tids.rank);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data); -- ver onde recebe a info para ver onde filtrar e pnde vai buscar o dblock para fazer decode
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_DATA',
                                              o_error);
        
            RETURN FALSE;
    END get_notes_data;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_id_epis_pn             Note identifier
    * @param i_area                   Area name. Ex: 
    *                                       HP - histoy and physician
    *                                       PN-Progress Note   
    * Can be null in the sign-off confirmation screen 
    * @param i_flg_desc_order         Y-Should be used descending order by date. N-Should be read the configuration order
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a listed interval of dates
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_core
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE DEFAULT NULL,
        i_flg_scope      IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_area           IN pn_area.internal_name%TYPE,
        i_flg_desc_order IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        --
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        --
        i_search IN VARCHAR2,
        i_filter IN VARCHAR2,
        --
        i_flg_config   IN VARCHAR2 DEFAULT NULL,
        i_flg_category IN VARCHAR2 DEFAULT NULL,
        o_data         OUT NOCOPY pk_types.cursor_type,
        o_notes_texts  OUT NOCOPY pk_types.cursor_type,
        o_note_ids     OUT NOCOPY table_number,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_no_data_found EXCEPTION;
    BEGIN
    
        g_error := 'CALL get_notes. i_area: ' || i_area || ' i_start_record: ' || i_start_record || ' i_num_records: ' ||
                   i_num_records || ' i_search: ' || i_search || 'i_filter: ' || i_filter;
        pk_alertlog.log_debug(g_error);
    
        IF NOT get_notes(i_lang           => i_lang,
                         i_prof           => i_prof,
                         i_id_episode     => i_id_episode,
                         i_id_patient     => i_id_patient,
                         i_id_epis_pn     => i_id_epis_pn,
                         i_flg_scope      => i_flg_scope,
                         i_area           => i_area,
                         i_flg_desc_order => i_flg_desc_order,
                         i_start_record   => i_start_record,
                         i_num_records    => i_num_records,
                         i_search         => i_search,
                         i_filter         => i_filter,
                         i_flg_category   => i_flg_category,
                         o_note_ids       => o_note_ids,
                         o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_notes_data. i_id_episode: ' || i_id_episode || ' i_area: ' || i_area;
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_data(i_lang       => i_lang,
                              i_prof       => i_prof,
                              i_id_episode => i_id_episode,
                              i_note_ids   => o_note_ids,
                              i_area       => i_area,
                              o_data       => o_data,
                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_notes_texts. i_id_episode: ' || i_id_episode || ' i_id_epis_pn: ' || i_id_epis_pn;
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_texts(i_lang        => i_lang,
                               i_prof        => i_prof,
                               i_id_episode  => i_id_episode,
                               i_id_epis_pn  => i_id_epis_pn,
                               i_search      => i_search,
                               i_note_ids    => o_note_ids,
                               i_flg_config  => i_flg_config,
                               o_notes_texts => o_notes_texts,
                               o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_data_found THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_CORE',
                                              o_error);
        
            RETURN FALSE;
    END get_notes_core;

    /**
    * Returns the notes to the summary grid.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier. Mandatory
    * @param i_id_patient             patient identifier
    * @param i_flg_scope              E-episode; P-patient
    * @param i_area                   Area name. Ex:
    *                                       HP - histoy and physician
    *                                       PN-Progress Note    
    * @param i_flg_desc_order         Y-Should be used descending order by date. N-Should be read the configuration order
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param I_SEARCH                 keyword to Search for
    * @param I_FILTER                 Filter by a listed interval of dates
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note
    * @param o_addendums              Addendums data
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_id_patient     IN patient.id_patient%TYPE,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_scope      IN VARCHAR2,
        i_area           IN pn_area.internal_name%TYPE,
        i_flg_desc_order IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        --
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        --
        i_search       IN VARCHAR2,
        i_filter       IN VARCHAR2,
        i_flg_category IN VARCHAR2 DEFAULT NULL,
        --
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_notes_texts OUT NOCOPY pk_types.cursor_type,
        o_addendums   OUT NOCOPY pk_types.cursor_type,
        o_comments    OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL get_notes_core';
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_core(i_lang           => i_lang,
                              i_prof           => i_prof,
                              i_id_episode     => i_id_episode,
                              i_id_patient     => i_id_patient,
                              i_flg_scope      => i_flg_scope,
                              i_id_epis_pn     => i_id_epis_pn,
                              i_area           => i_area,
                              i_flg_desc_order => i_flg_desc_order,
                              --
                              i_start_record => i_start_record,
                              i_num_records  => i_num_records,
                              --
                              i_search       => i_search,
                              i_filter       => i_filter,
                              i_flg_category => i_flg_category,
                              --
                              o_data        => o_data,
                              o_notes_texts => o_notes_texts,
                              o_note_ids    => l_note_ids,
                              o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL get_addendums';
        pk_alertlog.log_debug(g_error);
        IF NOT get_addendums(i_lang        => i_lang,
                             i_prof        => i_prof,
                             i_ids_epis_pn => l_note_ids,
                             i_search      => i_search,
                             o_addendums   => o_addendums,
                             o_comments    => o_comments,
                             o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_addendums);
            pk_types.open_my_cursor(i_cursor => o_comments);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
        
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_PROG_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_epis_prog_notes;

    /**
    * Returns the note info.
    * Function to the sign-off screen.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note Id     
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_epis_prog_notes
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        i_flg_config  IN VARCHAR2 DEFAULT NULL,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_notes_texts OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_note_ids table_number;
    BEGIN
        g_error := 'CALL get_epis_prog_notes. i_id_epis_pn: ' || i_id_epis_pn;
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_core(i_lang         => i_lang,
                              i_prof         => i_prof,
                              i_id_episode   => i_id_episode,
                              i_id_epis_pn   => i_id_epis_pn,
                              i_area         => NULL,
                              i_start_record => NULL,
                              i_num_records  => NULL,
                              i_search       => NULL,
                              i_filter       => NULL,
                              i_flg_config   => i_flg_config,
                              o_data         => o_data,
                              o_notes_texts  => o_notes_texts,
                              o_note_ids     => l_note_ids,
                              o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_types.open_my_cursor(i_cursor => o_notes_texts);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_EPIS_PROG_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_epis_prog_notes;

    /**
    * Returns the note cancel info info and signature.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             episode id
    * @param i_id_prof_create         Creation profesisonal 
    * @param i_dt_create              Creation date
    * @param i_id_prof_last_update    Professional that performed the last update
    * @param i_dt_last_update         Last update date
    * @param i_id_prof_signoff        Signed-off professional
    * @param i_dt_signoff             Sign-off date
    * @param i_id_prof_cancel         Cancelation professional
    
    * @param o_flg_types              Flg_type output list
    * @param o_flg_types              Flg_type output list
    * @param o_labels                 Labels output list  
    * @param io_data                  Clob notes
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_hist_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN epis_pn.id_episode%TYPE,
        i_id_prof_create      IN epis_pn.id_prof_create%TYPE,
        i_dt_create           IN epis_pn.dt_create%TYPE,
        i_id_prof_last_update IN epis_pn.id_prof_last_update%TYPE,
        i_dt_last_update      IN epis_pn.dt_last_update%TYPE,
        i_id_prof_signoff     IN epis_pn.id_prof_signoff%TYPE,
        i_dt_signoff          IN epis_pn.dt_signoff%TYPE,
        i_id_prof_cancel      IN epis_pn.id_prof_cancel%TYPE,
        i_dt_cancel           IN epis_pn.dt_cancel%TYPE,
        io_flg_types          IN OUT NOCOPY table_varchar,
        io_labels             IN OUT NOCOPY table_varchar,
        io_data               IN OUT NOCOPY table_clob,
        io_status             IN OUT NOCOPY table_varchar,
        i_flg_status          IN epis_pn.flg_status%TYPE,
        i_id_dictation_report IN epis_pn.id_dictation_report%TYPE,
        i_flg_report_type     IN VARCHAR2 DEFAULT NULL,
        i_flg_history         IN VARCHAR2,
        i_has_addendums       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL,
        i_id_prof_reviewed    IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_prof_submit      IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_submit           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_screen          IN VARCHAR2 DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --signature
        add_4_values(io_table_1 => io_labels,
                     i_value_1  => NULL,
                     io_table_2 => io_flg_types,
                     i_value_2  => CASE
                                       WHEN i_flg_report_type IS NULL THEN
                                        pk_prog_notes_constants.g_signature_s
                                       ELSE
                                        pk_prog_notes_constants.g_signature_ss
                                   END,
                     io_table_3 => io_data,
                     i_value_3  => pk_prog_notes_utils.get_signature(i_lang                => i_lang,
                                                                     i_prof                => i_prof,
                                                                     i_id_episode          => i_id_episode,
                                                                     i_id_prof_create      => i_id_prof_create,
                                                                     i_dt_create           => i_dt_create,
                                                                     i_id_prof_last_update => i_id_prof_last_update,
                                                                     i_dt_last_update      => i_dt_last_update,
                                                                     i_id_prof_sign_off    => i_id_prof_signoff,
                                                                     i_dt_sign_off         => i_dt_signoff,
                                                                     i_id_prof_cancel      => i_id_prof_cancel,
                                                                     i_dt_cancel           => i_dt_cancel,
                                                                     i_id_dictation_report => i_id_dictation_report,
                                                                     i_flg_history         => i_flg_history,
                                                                     i_has_addendums       => i_has_addendums,
                                                                     i_id_software         => i_id_software,
                                                                     i_id_prof_reviewed    => i_id_prof_reviewed,
                                                                     i_dt_reviewed         => i_dt_reviewed,
                                                                     i_id_prof_submit      => i_id_prof_submit,
                                                                     i_dt_submit           => i_dt_submit,
                                                                     i_epis_pn             => i_epis_pn,
                                                                     i_flg_screen          => i_flg_screen),
                     io_table_4 => io_status,
                     i_value_4  => i_flg_status);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HIST_SIGNATURE',
                                              o_error);
        
            RETURN FALSE;
    END get_hist_signature;

    /**
    * Returns the note cancel info info and signature.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_info              Note data
    * @param i_detail_labels          Detail labels list    
    * @param i_set_signature          Y-include the signature. N-otherwise
    * @param o_flg_types              Flg_type output list
    * @param o_flg_types              Flg_type output list
    * @param o_labels                 Labels output list  
    * @param io_data                  Clob notes
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */

    FUNCTION get_cancel_info_and_sign
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status          IN epis_pn.flg_status%TYPE,
        i_id_cancel_reason    IN epis_pn.id_cancel_reason%TYPE,
        i_cancel_notes        IN epis_pn.notes_cancel%TYPE,
        i_id_episode          IN epis_pn.id_episode%TYPE,
        i_id_prof_create      IN epis_pn.id_prof_create%TYPE,
        i_dt_create           IN epis_pn.dt_create%TYPE,
        i_id_prof_last_update IN epis_pn.id_prof_last_update%TYPE,
        i_dt_last_update      IN epis_pn.dt_last_update%TYPE,
        i_id_prof_signoff     IN epis_pn.id_prof_signoff%TYPE,
        i_dt_signoff          IN epis_pn.dt_signoff%TYPE,
        i_id_prof_cancel      IN epis_pn.id_prof_cancel%TYPE,
        i_dt_cancel           IN epis_pn.dt_cancel%TYPE,
        i_detail_labels       IN table_varchar,
        i_set_signature       IN VARCHAR2,
        i_id_dictation_report IN epis_pn.id_dictation_report%TYPE,
        io_flg_types          IN OUT NOCOPY table_varchar,
        io_labels             IN OUT NOCOPY table_varchar,
        io_data               IN OUT NOCOPY table_clob,
        io_status             IN OUT NOCOPY table_varchar,
        i_flg_report_type     IN VARCHAR2 DEFAULT NULL,
        i_flg_history         IN VARCHAR2,
        i_has_addendums       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL,
        i_id_prof_reviewed    IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_prof_submit      IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_submit           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_flg_screen          IN VARCHAR2 DEFAULT NULL,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --Cancellation info
        IF i_flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c
        THEN
            IF i_id_cancel_reason IS NOT NULL
            THEN
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => i_detail_labels(2),
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_content_c,
                             io_table_3 => io_data,
                             i_value_3  => pk_cancel_reason.get_cancel_reason_desc(i_lang             => i_lang,
                                                                                   i_prof             => i_prof,
                                                                                   i_id_cancel_reason => i_id_cancel_reason),
                             io_table_4 => io_status,
                             i_value_4  => i_flg_status);
            END IF;
        
            IF i_cancel_notes IS NOT NULL
            THEN
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => i_detail_labels(3),
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_content_c,
                             io_table_3 => io_data,
                             i_value_3  => i_cancel_notes,
                             io_table_4 => io_status,
                             i_value_4  => i_flg_status);
            END IF;
        END IF;
    
        IF (i_set_signature = pk_alert_constant.g_yes)
        THEN
            --signature
            g_error := 'CALL get_hist_signature';
            pk_alertlog.log_debug(g_error);
            IF NOT get_hist_signature(i_lang                => i_lang,
                                      i_prof                => i_prof,
                                      i_id_episode          => i_id_episode,
                                      i_id_prof_create      => i_id_prof_create,
                                      i_dt_create           => i_dt_create,
                                      i_id_prof_last_update => i_id_prof_last_update,
                                      i_dt_last_update      => i_dt_last_update,
                                      i_id_prof_signoff     => i_id_prof_signoff,
                                      i_dt_signoff          => i_dt_signoff,
                                      i_id_prof_cancel      => i_id_prof_cancel,
                                      i_dt_cancel           => i_dt_cancel,
                                      io_flg_types          => io_flg_types,
                                      io_labels             => io_labels,
                                      io_data               => io_data,
                                      io_status             => io_status,
                                      i_flg_status          => i_flg_status,
                                      i_id_dictation_report => i_id_dictation_report,
                                      i_flg_report_type     => i_flg_report_type,
                                      i_flg_history         => i_flg_history,
                                      i_has_addendums       => i_has_addendums,
                                      i_id_software         => i_id_software,
                                      i_id_prof_reviewed    => i_id_prof_reviewed,
                                      i_dt_reviewed         => i_dt_reviewed,
                                      i_id_prof_submit      => i_id_prof_submit,
                                      i_dt_submit           => i_dt_submit,
                                      i_epis_pn             => i_epis_pn,
                                      i_flg_screen          => i_flg_screen,
                                      o_error               => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
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
                                              'GET_CANCEL_INFO_AND_SIGN',
                                              o_error);
        
            RETURN FALSE;
    END get_cancel_info_and_sign;

    /**
    * Get history status of a record (note or addendum^).    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_flg_status             status of the note or addendum
    * @param i_code_domain            Code domain to be used to get the description of the status
    * @param i_status_desc            Status description, if it was already calculated
    * @param i_str_to_append          string to append to the status description
    * @param i_flg_report_type        report type
    * @param i_pn_note_type_cfg       Configs according to the note type
    * @param io_flg_types             Flg types list
    * @param io_labels                Labels list    
    * @param io_data                  Values list
    * @param io_status                Status list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                04-Feb-2011
    */
    FUNCTION get_hist_status
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_status       IN epis_pn.flg_status%TYPE,
        i_code_domain      IN sys_domain.code_domain%TYPE DEFAULT NULL,
        i_status_desc      IN sys_domain.desc_val%TYPE DEFAULT NULL,
        i_str_to_append    IN VARCHAR2 DEFAULT NULL,
        i_flg_report_type  IN VARCHAR2 DEFAULT NULL,
        i_pn_note_type_cfg IN t_rec_note_type,
        io_flg_types       IN OUT NOCOPY table_varchar,
        io_labels          IN OUT NOCOPY table_varchar,
        io_data            IN OUT NOCOPY table_clob,
        io_status          IN OUT NOCOPY table_varchar,
        i_flg_data_type    IN VARCHAR2 DEFAULT 'N',
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        -- to the reports the status and the nr of addendums is sent in the same output line concatenated
        --status        
        add_4_values(io_table_1      => io_labels,
                     i_value_1       => NULL,
                     io_table_2      => io_flg_types,
                     i_value_2       => CASE
                                            WHEN i_flg_report_type IS NULL
                                                 AND i_str_to_append IS NOT NULL THEN
                                            
                                             CASE
                                                 WHEN i_flg_status IN
                                                      (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                       pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                       pk_prog_notes_constants.g_epis_pn_flg_for_review) THEN
                                                  pk_prog_notes_constants.g_status_strwl
                                                 ELSE
                                                  pk_prog_notes_constants.g_status_stbwl
                                             END
                                            ELSE
                                             CASE
                                                 WHEN i_flg_status IN
                                                      (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                       pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                       pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                       pk_prog_notes_constants.g_epis_pn_flg_for_review) THEN
                                                  pk_prog_notes_constants.g_status_str
                                                 ELSE
                                                  pk_prog_notes_constants.g_status_stb
                                             END
                                        END,
                     io_table_3      => io_data,
                     i_value_3       => CASE
                                            WHEN i_status_desc IS NOT NULL THEN
                                             i_status_desc
                                            ELSE
                                             CASE
                                                 WHEN i_flg_report_type IS NULL THEN
                                                  pk_prog_notes_constants.g_open_parenthesis ||
                                                  pk_sysdomain.get_domain(i_code_domain, i_flg_status, i_lang) ||
                                                  pk_prog_notes_constants.g_close_parenthesis
                                                 ELSE
                                                  pk_prog_notes_constants.g_open_parenthesis ||
                                                  pk_sysdomain.get_domain(i_code_domain, i_flg_status, i_lang) ||
                                                  pk_prog_notes_constants.g_close_parenthesis || i_str_to_append
                                             END
                                        END,
                     io_table_4      => io_status,
                     i_value_4       => i_flg_status,
                     i_flg_data_type => i_flg_data_type);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HIST_STATUS',
                                              o_error);
        
            RETURN FALSE;
    END get_hist_status;

    /**
    * Returns the detail title of the note (date; status; nr addenduns).    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_info              note record
    * @param i_show_title             T-shows the title; B-shows the soap block date   
    * @param i_pn_note_type_cfg       Configs according to the note type
    * @param io_flg_types             Format types
    * @param io_labels                Labels    
    * @param io_status                Status of the note or addendum. Depends on the data being refered to an adendum or a note.
    * @param io_status                Status of the note or addendum. Depends on the data being refered to an adendum or a note.
    * @param io_data                  Texts/contents
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_hist_note_title
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_note_info         IN t_rec_epis_pn_hist,
        i_show_title        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_flg_screen        IN VARCHAR2,
        i_pn_note_type_cfg  IN t_rec_note_type,
        i_flg_get_addendums IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        io_flg_types        IN OUT NOCOPY table_varchar,
        io_labels           IN OUT NOCOPY table_varchar,
        io_status           IN OUT NOCOPY table_varchar,
        io_data             IN OUT NOCOPY table_clob,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nr_addendums_desc VARCHAR2(1000 CHAR) := NULL;
        l_flg_has_status    VARCHAR2(1 CHAR);
    BEGIN
        IF (i_show_title IN (pk_prog_notes_constants.g_show_title_t, pk_prog_notes_constants.g_show_all))
        THEN
            --main title: date  
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => pk_date_utils.dt_chr_tsz(i_lang,
                                                                i_note_info.dt_pn_date,
                                                                i_prof.institution,
                                                                i_prof.software),
                         io_table_2 => io_flg_types,
                         i_value_2  => CASE
                                           WHEN i_flg_report_type IS NULL THEN
                                            pk_prog_notes_constants.g_title_t
                                           ELSE
                                            pk_prog_notes_constants.g_main_title
                                       END,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => io_status,
                         i_value_4  => i_note_info.flg_status);
        
            l_flg_has_status := pk_prog_notes_utils.check_has_status(i_lang                 => i_lang,
                                                                     i_prof                 => i_prof,
                                                                     i_flg_status_available => i_pn_note_type_cfg.flg_status_available,
                                                                     i_flg_status           => i_note_info.flg_status);
        
            --title
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => pk_date_utils.date_char_hour_tsz(i_lang,
                                                                        i_note_info.dt_pn_date,
                                                                        i_prof.institution,
                                                                        i_prof.software) || ' - ' ||
                                       pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_id_pn_note_type    => i_note_info.id_note_type,
                                                                              i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d),
                         io_table_2 => io_flg_types,
                         i_value_2  => CASE
                                           WHEN l_flg_has_status = pk_alert_constant.g_no THEN
                                            pk_prog_notes_constants.g_title_t
                                           ELSE
                                            pk_prog_notes_constants.g_title_tnl
                                       END,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => io_status,
                         i_value_4  => i_note_info.flg_status);
        
            IF (i_flg_screen = pk_prog_notes_constants.g_detail_screen_d)
            THEN
                l_nr_addendums_desc := get_nr_addendums_desc(i_lang,
                                                             i_prof,
                                                             NULL,
                                                             i_note_info.id_epis_pn,
                                                             l_flg_has_status);
            END IF;
        
            IF (l_flg_has_status = pk_alert_constant.g_yes)
            THEN
                --status
                -- to the reports the status and the nr of addendums is sent in the same output line
                g_error := 'CALL get_hist_status';
                pk_alertlog.log_debug(g_error);
                IF NOT get_hist_status(i_lang             => i_lang,
                                       i_prof             => i_prof,
                                       i_flg_status       => i_note_info.flg_status,
                                       i_code_domain      => pk_prog_notes_constants.g_sd_note_flg_status,
                                       i_str_to_append    => l_nr_addendums_desc,
                                       i_flg_report_type  => i_flg_report_type,
                                       i_pn_note_type_cfg => i_pn_note_type_cfg,
                                       io_flg_types       => io_flg_types,
                                       io_labels          => io_labels,
                                       io_data            => io_data,
                                       io_status          => io_status,
                                       o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            --the nr of addendums to the detail and history screen
            IF (i_flg_report_type IS NULL AND l_nr_addendums_desc IS NOT NULL AND
               i_flg_get_addendums = pk_alert_constant.g_yes)
            THEN
                --title
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => l_nr_addendums_desc,
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_title_t,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => io_status,
                             i_value_4  => i_note_info.flg_status);
            END IF;
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
                                              'get_hist_note_title',
                                              o_error);
        
            RETURN FALSE;
    END get_hist_note_title;

    FUNCTION get_prof_review
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_prof_reviewed IN epis_pn.id_prof_reviewed%TYPE,
        i_dt_reviewed      IN epis_pn.dt_reviewed%TYPE,
        io_flg_types       IN OUT NOCOPY table_varchar,
        io_labels          IN OUT NOCOPY table_varchar,
        io_data            IN OUT NOCOPY table_clob,
        io_status          IN OUT NOCOPY table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_label_review sys_message.desc_message%TYPE := pk_message.get_message(i_lang      => i_lang,
                                                                               i_code_mess => pk_prog_notes_constants.g_sm_doctor_reviewed);
    BEGIN
        --signature
        add_4_values(io_table_1 => io_labels,
                     i_value_1  => l_label_review,
                     io_table_2 => io_flg_types,
                     i_value_2  => pk_prog_notes_constants.g_sub_title_content_stc,
                     io_table_3 => io_data,
                     i_value_3  => l_label_review || ' ' ||
                                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                                    i_prof    => i_prof,
                                                                    i_prof_id => i_id_prof_reviewed),
                     io_table_4 => io_status,
                     i_value_4  => i_id_prof_reviewed);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_prof_review',
                                              o_error);
        
            RETURN FALSE;
        
    END get_prof_review;
    /**
    * Returns the note info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_episode                episode identifier
    * @param i_id_epis_pn             Note Id     
    * @param i_show_title             T-shows the title; B-shows the soap block date; All-shows the both
    * @param i_pn_note_type_cfg       Configs according to the note type
    * @param o_data                   notes data
    * @param o_notes_texts            Texts that compose the note    
    * @param o_status                 Status of the note or addendum. Depends on the data being refered to an adendum or a note.
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_note_detail
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_note_info         IN t_rec_epis_pn_hist,
        i_flg_screen        IN VARCHAR2,
        i_detail_labels     IN table_varchar,
        i_flg_report_type   IN VARCHAR2,
        i_show_title        IN VARCHAR2,
        i_has_addendums     IN VARCHAR2,
        i_pn_note_type_cfg  IN t_rec_note_type,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_flg_get_addendums IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        i_flg_search        IN table_varchar DEFAULT NULL,
        o_flg_types         OUT table_varchar,
        o_labels            OUT table_varchar,
        o_status            OUT table_varchar,
        io_data             IN OUT NOCOPY table_clob,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_NOTE_DETAIL';
        l_note_id   epis_pn.id_epis_pn%TYPE;
        c_addendums pk_types.cursor_type;
        c_comments  pk_types.cursor_type;
    
        l_addendum_id          epis_addendum.id_epis_addendum%TYPE;
        l_addendum_status      epis_addendum.flg_status%TYPE;
        l_addendum_status_desc pk_translation.t_desc_translation;
        l_addendum_signature   pk_translation.t_desc_translation;
        l_flg_ok               VARCHAR2(1);
        l_flg_cancel           VARCHAR2(1);
        l_addendum_title       pk_translation.t_desc_translation;
        l_addendum_text        epis_pn_addendum.pn_addendum%TYPE;
    
        l_notes_texts    t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_flg_has_status VARCHAR2(1 CHAR);
    
        l_task_type_test    NUMBER;
        l_id_note_type_test NUMBER;
        l_id_soap_test      NUMBER;
    
    BEGIN
        o_labels    := table_varchar();
        o_flg_types := table_varchar();
        o_status    := table_varchar();
    
        g_error := 'CALL get_hist_note_title';
        pk_alertlog.log_debug(g_error);
        IF NOT get_hist_note_title(i_lang              => i_lang,
                                   i_prof              => i_prof,
                                   i_note_info         => i_note_info,
                                   i_show_title        => i_show_title,
                                   i_flg_report_type   => i_flg_report_type,
                                   i_flg_screen        => i_flg_screen,
                                   i_pn_note_type_cfg  => i_pn_note_type_cfg,
                                   i_flg_get_addendums => i_flg_get_addendums,
                                   io_flg_types        => o_flg_types,
                                   io_labels           => o_labels,
                                   io_status           => o_status,
                                   io_data             => io_data,
                                   o_error             => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --notes clobs
        --actual note
        IF (i_note_info.flg_history = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL get_note_block_texts';
            pk_alertlog.log_debug(g_error);
            l_notes_texts := get_note_block_texts(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_note_ids        => table_number(i_note_info.id_epis_pn),
                                                  i_note_status     => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_status_c,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                                                     pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                  i_show_title      => i_show_title,
                                                  i_flg_detail      => pk_alert_constant.g_yes,
                                                  i_soap_blocks     => CASE
                                                                           WHEN i_pn_soap_block_in IS NULL THEN
                                                                            NULL
                                                                           WHEN i_pn_soap_block_in.count = 0 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_pn_soap_block_in
                                                                       END,
                                                  i_soap_blocks_nin => CASE
                                                                           WHEN i_pn_soap_block_nin IS NULL THEN
                                                                            NULL
                                                                           WHEN i_pn_soap_block_nin.count = 0 THEN
                                                                            NULL
                                                                           ELSE
                                                                            i_pn_soap_block_nin
                                                                       END,
                                                  i_flg_search      => i_flg_search);
        ELSE
            g_error := 'CALL get_note_block_texts_hist';
            pk_alertlog.log_debug(g_error);
            l_notes_texts := get_note_block_texts_hist(i_lang       => i_lang,
                                                       i_prof       => i_prof,
                                                       i_note_id    => i_note_info.id_epis_pn,
                                                       i_dt_hist    => i_note_info.dt_hist,
                                                       i_show_title => i_show_title,
                                                       i_flg_detail => pk_alert_constant.g_yes);
        END IF;
    
        FOR k IN 1 .. l_notes_texts.count
        LOOP
            IF dbms_lob.substr(l_notes_texts(k).soap_block_txt,
                               1,
                               dbms_lob.getlength(l_notes_texts(k).soap_block_txt) - 1) <> ' '
            THEN
                l_notes_texts(k).soap_block_txt := l_notes_texts(k).soap_block_txt || chr(10);
            END IF;
            IF l_notes_texts(k).id_note_type IN (pk_prog_notes_constants.g_note_type_arabic_ft,
                                 pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                 pk_prog_notes_constants.g_note_type_arabic_ft_sw)
                AND l_notes_texts(k).id_soap_block = 17
            THEN
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => l_notes_texts(k).soap_block_desc,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_sub_title_arabic,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => o_status,
                             i_value_4  => i_note_info.flg_status);
            
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => NULL,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_sub_title_content_arabic,
                             io_table_3 => io_data,
                             i_value_3  => l_notes_texts(k).soap_block_txt,
                             io_table_4 => o_status,
                             i_value_4  => i_note_info.flg_status);
            ELSE
            
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => l_notes_texts(k).soap_block_desc,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_sub_title_st,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => o_status,
                             i_value_4  => i_note_info.flg_status);
            
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => NULL,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_sub_title_content_stc,
                             io_table_3 => io_data,
                             i_value_3  => l_notes_texts(k).soap_block_txt,
                             io_table_4 => o_status,
                             i_value_4  => i_note_info.flg_status);
            END IF;
        
        END LOOP;
    
        IF i_note_info.id_prof_reviewed IS NOT NULL
           AND i_note_info.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_submited
        --  AND i_flg_screen <> pk_prog_notes_constants.g_detail_screen_d
        THEN
            IF NOT get_prof_review(i_lang             => i_lang,
                                   i_prof             => i_prof,
                                   i_id_prof_reviewed => i_note_info.id_prof_reviewed,
                                   i_dt_reviewed      => i_note_info.dt_reviewed,
                                   io_flg_types       => o_flg_types,
                                   io_labels          => o_labels,
                                   io_status          => o_status,
                                   io_data            => io_data,
                                   o_error            => o_error)
            THEN
                RAISE g_exception;
            END IF;
            NULL;
        END IF;
        --Cancellation info and signature
        g_error := 'CALL get_cancel_info_and_sign';
        pk_alertlog.log_debug(g_error);
        IF NOT get_cancel_info_and_sign(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_flg_status          => i_note_info.flg_status,
                                        i_id_cancel_reason    => i_note_info.id_cancel_reason,
                                        i_cancel_notes        => i_note_info.cancel_notes,
                                        i_id_episode          => i_note_info.id_episode,
                                        i_id_prof_create      => i_note_info.id_prof_create,
                                        i_dt_create           => i_note_info.dt_create,
                                        i_id_prof_last_update => i_note_info.id_prof_last_update,
                                        i_dt_last_update      => i_note_info.dt_last_update,
                                        i_id_prof_signoff     => i_note_info.id_prof_signoff,
                                        i_dt_signoff          => i_note_info.dt_signoff,
                                        i_id_prof_cancel      => i_note_info.id_prof_cancel,
                                        i_dt_cancel           => i_note_info.dt_cancel,
                                        i_detail_labels       => i_detail_labels,
                                        i_set_signature       => pk_alert_constant.g_yes,
                                        i_id_dictation_report => i_note_info.id_dictation_report,
                                        io_flg_types          => o_flg_types,
                                        io_labels             => o_labels,
                                        io_data               => io_data,
                                        io_status             => o_status,
                                        i_flg_report_type     => i_flg_report_type,
                                        i_flg_history         => i_note_info.flg_history,
                                        i_has_addendums       => i_has_addendums,
                                        i_id_software         => i_note_info.id_software,
                                        i_id_prof_reviewed    => nvl(i_note_info.id_prof_last_update,
                                                                     i_note_info.id_prof_create),
                                        i_dt_reviewed         => i_note_info.dt_reviewed,
                                        i_id_prof_submit      => i_note_info.id_prof_submit,
                                        i_dt_submit           => i_note_info.dt_submit,
                                        i_flg_screen          => i_flg_screen,
                                        o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_flg_screen = pk_prog_notes_constants.g_detail_screen_d AND i_flg_get_addendums = pk_alert_constant.g_yes)
        THEN
            --Adendums
            g_error := 'CALL get_addendums. i_id_episode: ' || i_note_info.id_episode || '; i_ids_epis_pn: ' ||
                       i_note_info.id_epis_pn;
            pk_alertlog.log_debug(g_error);
            IF NOT get_addendums(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_ids_epis_pn => table_number(i_note_info.id_epis_pn),
                                 o_addendums   => c_addendums,
                                 o_comments    => c_comments,
                                 o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            LOOP
                FETCH c_addendums
                    INTO l_addendum_id,
                         l_note_id,
                         l_addendum_status,
                         l_addendum_status_desc,
                         l_addendum_signature,
                         l_flg_ok,
                         l_flg_cancel,
                         l_addendum_title,
                         l_addendum_text;
                EXIT WHEN c_addendums%NOTFOUND;
            
                l_flg_has_status := pk_prog_notes_utils.check_has_status(i_lang                 => i_lang,
                                                                         i_prof                 => i_prof,
                                                                         i_flg_status_available => i_pn_note_type_cfg.flg_status_available,
                                                                         i_flg_status           => i_note_info.flg_status);
            
                --title
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => l_addendum_title,
                             io_table_2      => o_flg_types,
                             i_value_2       => CASE
                                                    WHEN l_flg_has_status = pk_alert_constant.g_no THEN
                                                     pk_prog_notes_constants.g_title_t
                                                    ELSE
                                                     pk_prog_notes_constants.g_title_tnl
                                                END,
                             io_table_3      => io_data,
                             i_value_3       => NULL,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            
                IF (l_flg_has_status = pk_alert_constant.g_yes)
                THEN
                    --status                   
                    g_error := 'CALL get_hist_status';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_hist_status(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_flg_status       => l_addendum_status,
                                           i_status_desc      => l_addendum_status_desc,
                                           i_pn_note_type_cfg => i_pn_note_type_cfg,
                                           io_flg_types       => o_flg_types,
                                           io_labels          => o_labels,
                                           io_data            => io_data,
                                           io_status          => o_status,
                                           i_flg_data_type    => pk_prog_notes_constants.g_addendum,
                                           o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                --text
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => NULL,
                             io_table_2      => o_flg_types,
                             i_value_2       => pk_prog_notes_constants.g_sub_title_content_stc,
                             io_table_3      => io_data,
                             i_value_3       => l_addendum_text,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            
                --signature
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => NULL,
                             io_table_2      => o_flg_types,
                             i_value_2       => pk_prog_notes_constants.g_signature_s,
                             io_table_3      => io_data,
                             i_value_3       => l_addendum_signature,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            
            END LOOP;
            -- Comments
            FETCH c_comments
                INTO l_addendum_id,
                     l_note_id,
                     l_addendum_status,
                     l_addendum_status_desc,
                     l_addendum_signature,
                     l_flg_ok,
                     l_flg_cancel,
                     l_addendum_title,
                     l_addendum_text;
        
            IF c_comments%ROWCOUNT > 0
            THEN
                --title
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => l_addendum_title,
                             io_table_2      => o_flg_types,
                             i_value_2       => pk_prog_notes_constants.g_title_t,
                             io_table_3      => io_data,
                             i_value_3       => NULL,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            
                --text
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => NULL,
                             io_table_2      => o_flg_types,
                             i_value_2       => pk_prog_notes_constants.g_sub_title_content_stc,
                             io_table_3      => io_data,
                             i_value_3       => l_addendum_text,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            
                --signature
                add_4_values(io_table_1      => o_labels,
                             i_value_1       => NULL,
                             io_table_2      => o_flg_types,
                             i_value_2       => pk_prog_notes_constants.g_signature_s,
                             io_table_3      => io_data,
                             i_value_3       => l_addendum_signature,
                             io_table_4      => o_status,
                             i_value_4       => l_addendum_status,
                             i_flg_data_type => pk_prog_notes_constants.g_addendum);
            END IF;
        
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
    END get_note_detail;

    /**
    * Returns the addendums history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_detail_status_label    detail status label   
    * @param i_hist_status_label      history status label   
    * @param i_code_domain            code domain of the status
    * @param i_val_actual             Sys_domain actual value
    * @param i_val_previous           Sys_domain previous value
    * @param i_status_actual          Actual status
    * @param i_status_previous        Previous status
    * @param i_flg_status_available   Y-status are available in the note. N-Otherwise
    * @param o_labels                 Labels output list
    * @param io_data                  Clob values list
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                04-Feb-2011
    */
    FUNCTION get_hist_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_detail_status_label  IN sys_message.desc_message%TYPE,
        i_hist_status_label    IN sys_message.desc_message%TYPE,
        i_code_domain          IN sys_domain.code_domain%TYPE,
        i_val_actual           IN sys_domain.val%TYPE,
        i_val_previous         IN sys_domain.val%TYPE,
        i_status_actual        IN epis_pn_addendum.flg_status%TYPE,
        i_flg_status_available IN pn_note_type_mkt.flg_status_available%TYPE,
        io_flg_types           IN OUT NOCOPY table_varchar,
        io_labels              IN OUT NOCOPY table_varchar,
        io_data                IN OUT NOCOPY table_clob,
        io_status              IN OUT NOCOPY table_varchar,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --new value
        add_4_values(io_table_1 => io_labels,
                     i_value_1  => i_hist_status_label,
                     io_table_2 => io_flg_types,
                     i_value_2  => pk_prog_notes_constants.g_new_content_n,
                     io_table_3 => io_data,
                     i_value_3  => pk_sysdomain.get_domain(i_code_dom => i_code_domain,
                                                           i_val      => i_val_actual,
                                                           i_lang     => i_lang),
                     io_table_4 => io_status,
                     i_value_4  => i_status_actual);
    
        IF (i_flg_status_available = pk_alert_constant.g_yes)
        THEN
            --old value
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => i_detail_status_label,
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_content_c,
                         io_table_3 => io_data,
                         i_value_3  => pk_sysdomain.get_domain(i_code_dom => i_code_domain,
                                                               i_val      => i_val_previous,
                                                               i_lang     => i_lang),
                         io_table_4 => io_status,
                         i_value_4  => i_status_actual);
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
                                              'GET_HIST_STATUS',
                                              o_error);
        
            RETURN FALSE;
    END get_hist_status;

    /**
    * Returns the addendums history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             note id    
    * @param i_flg_status             note status
    * @param i_date                   note date
    * @param i_labels                 line labels
    * @param i_flg_types              line status
    * @param i_status                 line statuses
    * @param io_tab_hist              History info list
    * @param io_note_ids              Note ids list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                04-Feb-2011
    */
    FUNCTION get_hist_line
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        i_flg_status IN epis_pn.flg_status%TYPE,
        i_date       IN epis_pn.dt_pn_date%TYPE,
        i_labels     IN table_varchar,
        i_flg_types  IN table_varchar,
        i_status     IN table_varchar,
        io_tab_hist  IN OUT NOCOPY t_table_history,
        io_note_ids  IN OUT table_number,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        io_tab_hist.extend;
        io_tab_hist(io_tab_hist.count) := t_rec_history(id_rec     => i_id_epis_pn,
                                                        flg_status => i_flg_status,
                                                        date_rec   => i_date,
                                                        tbl_labels => i_labels,
                                                        tbl_types  => i_flg_types,
                                                        tbl_status => i_status);
    
        FOR ind IN 1 .. i_labels.count
        LOOP
            io_note_ids.extend();
            io_note_ids(io_note_ids.last) := i_id_epis_pn;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_hist_line',
                                              o_error);
        
            RETURN FALSE;
    END get_hist_line;

    /**
    * Returns the diferrence between two records texts of addenduns history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_actual_row             Actual info    
    * @param i_previous_row           Previous info
    * @param i_hist_labels            History labels
    * @param o_flg_types              Types output list
    * @param o_labels                 Labels output list
    * @param io_data                  Clob values list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                04-Feb-2011
    */
    FUNCTION get_dif_addendum
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_actual_row   IN t_rec_epis_pn_hist,
        i_previous_row IN t_rec_epis_pn_hist,
        i_hist_labels  IN table_varchar,
        io_data        IN OUT NOCOPY table_clob,
        io_flg_types   IN OUT NOCOPY table_varchar,
        io_labels      IN OUT NOCOPY table_varchar,
        io_status      IN OUT NOCOPY table_varchar,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --in the just save: it is possible to edit the texts. So, it is necessaru to check if theu were edited
        IF (dbms_lob.compare(i_actual_row.pn_addendum, i_previous_row.pn_addendum) <> 0)
        THEN
            IF (i_actual_row.flg_status <> i_previous_row.flg_status)
            THEN
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => NULL,
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_line,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => io_status,
                             i_value_4  => i_actual_row.flg_status);
            ELSE
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => CASE i_actual_row.flg_record_type
                                               WHEN pk_prog_notes_constants.g_epa_flg_type_comment THEN
                                                i_hist_labels(13)
                                               ELSE
                                                i_hist_labels(9)
                                           END,
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_title_t,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => io_status,
                             i_value_4  => i_actual_row.flg_status);
            END IF;
        
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => CASE i_actual_row.flg_record_type
                                           WHEN pk_prog_notes_constants.g_epa_flg_type_comment THEN
                                            i_hist_labels(12)
                                           ELSE
                                            i_hist_labels(8)
                                       END,
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_new_content_n,
                         io_table_3 => io_data,
                         i_value_3  => i_actual_row.pn_addendum,
                         io_table_4 => io_status,
                         i_value_4  => i_actual_row.flg_status);
            --
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => CASE i_actual_row.flg_record_type
                                           WHEN pk_prog_notes_constants.g_epa_flg_type_comment THEN
                                            i_hist_labels(11)
                                           ELSE
                                            i_hist_labels(5)
                                       END,
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_content_c,
                         io_table_3 => io_data,
                         i_value_3  => i_previous_row.pn_addendum,
                         io_table_4 => io_status,
                         i_value_4  => i_actual_row.flg_status);
        
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
                                              'get_dif_addendum',
                                              o_error);
        
            RETURN FALSE;
    END get_dif_addendum;

    /**
    * Returns the addendums history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             note id    
    * @param i_detail_labels          Detail labels
    * @param i_hist_labels            History labels
    * @param o_flg_types              Types output list
    * @param o_labels                 Labels output list
    * @param io_data                  Clob values list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                04-Feb-2011
    */
    FUNCTION get_addendum_history
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN epis_pn.id_episode%TYPE,
        i_actual_row    IN t_rec_epis_pn_hist,
        i_previous_row  IN t_rec_epis_pn_hist,
        i_detail_labels IN table_varchar,
        i_hist_labels   IN table_varchar,
        io_data         IN OUT NOCOPY table_clob,
        o_flg_types     OUT NOCOPY table_varchar,
        o_labels        OUT NOCOPY table_varchar,
        o_status        OUT NOCOPY table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_title_message sys_message.code_message%TYPE;
    BEGIN
        o_labels    := table_varchar();
        o_flg_types := table_varchar();
        o_status    := table_varchar();
    
        IF (i_actual_row.id_epis_pn_addendum = i_previous_row.id_epis_pn_addendum)
        THEN
            IF (i_actual_row.flg_status <> i_previous_row.flg_status)
            THEN
                --addendum sign-off
                IF (i_actual_row.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_s AND
                   i_previous_row.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_s)
                THEN
                    l_title_message := i_hist_labels(6);
                    --addendum cancellation
                ELSIF (i_actual_row.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_c AND
                      i_previous_row.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_d)
                THEN
                    l_title_message := i_hist_labels(7);
                END IF;
            
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => l_title_message,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_title_t,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => o_status,
                             i_value_4  => i_actual_row.flg_status);
            
                g_error := 'CALL get_hist_status';
                pk_alertlog.log_debug(g_error);
                IF NOT get_hist_status(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_detail_status_label  => i_detail_labels(1),
                                       i_hist_status_label    => i_hist_labels(1),
                                       i_code_domain          => pk_prog_notes_constants.g_sd_add_flg_status,
                                       i_val_actual           => i_actual_row.flg_status,
                                       i_val_previous         => i_previous_row.flg_status,
                                       i_status_actual        => i_actual_row.flg_status,
                                       i_flg_status_available => pk_alert_constant.g_yes, --the addenduns always has status
                                       io_flg_types           => o_flg_types,
                                       io_labels              => o_labels,
                                       io_data                => io_data,
                                       io_status              => o_status,
                                       o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                --in the just save: it is possible to edit the texts. So, it is necessary to check if they were edited
                IF NOT get_dif_addendum(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_actual_row   => i_actual_row,
                                        i_previous_row => i_previous_row,
                                        i_hist_labels  => i_hist_labels,
                                        io_data        => io_data,
                                        io_flg_types   => o_flg_types,
                                        io_labels      => o_labels,
                                        io_status      => o_status,
                                        o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                --set cancel info if necessary
                g_error := 'CALL get_cancel_info_and_sign';
                pk_alertlog.log_debug(g_error);
                IF NOT get_cancel_info_and_sign(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_flg_status          => i_actual_row.flg_status,
                                                i_id_cancel_reason    => i_actual_row.id_cancel_reason,
                                                i_cancel_notes        => i_actual_row.cancel_notes,
                                                i_id_episode          => i_id_episode,
                                                i_id_prof_create      => i_actual_row.id_prof_create,
                                                i_dt_create           => i_actual_row.dt_create,
                                                i_id_prof_last_update => i_actual_row.id_prof_last_update,
                                                i_dt_last_update      => i_actual_row.dt_last_update,
                                                i_id_prof_signoff     => i_actual_row.id_prof_signoff,
                                                i_dt_signoff          => i_actual_row.dt_signoff,
                                                i_id_prof_cancel      => i_actual_row.id_prof_cancel,
                                                i_dt_cancel           => i_actual_row.dt_cancel,
                                                i_detail_labels       => i_detail_labels,
                                                i_set_signature       => pk_alert_constant.g_no,
                                                i_id_dictation_report => pk_prog_notes_utils.get_dictation_report(i_lang       => i_lang,
                                                                                                                  i_prof       => i_prof,
                                                                                                                  i_id_epis_pn => i_actual_row.id_epis_pn),
                                                io_flg_types          => o_flg_types,
                                                io_labels             => o_labels,
                                                io_data               => io_data,
                                                io_status             => o_status,
                                                i_flg_history         => i_actual_row.flg_history,
                                                i_id_software         => i_actual_row.id_software,
                                                o_error               => o_error)
                THEN
                    RAISE g_exception;
                END IF;
                --addendum edition
            ELSE
                g_error := 'CALL get_dif_addendum';
                pk_alertlog.log_debug(g_error);
                IF NOT get_dif_addendum(i_lang         => i_lang,
                                        i_prof         => i_prof,
                                        i_actual_row   => i_actual_row,
                                        i_previous_row => i_previous_row,
                                        i_hist_labels  => i_hist_labels,
                                        io_data        => io_data,
                                        io_flg_types   => o_flg_types,
                                        io_labels      => o_labels,
                                        io_status      => o_status,
                                        o_error        => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF;
            --new addendum
        ELSE
            add_4_values(io_table_1 => o_labels,
                         i_value_1  => CASE i_actual_row.flg_record_type
                                           WHEN pk_prog_notes_constants.g_epa_flg_type_comment THEN
                                            i_hist_labels(11)
                                           ELSE
                                            i_hist_labels(5)
                                       END,
                         io_table_2 => o_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_title_t,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => o_status,
                         i_value_4  => i_actual_row.flg_status);
        
            add_4_values(io_table_1 => o_labels,
                         i_value_1  => CASE i_actual_row.flg_record_type
                                           WHEN pk_prog_notes_constants.g_epa_flg_type_comment THEN
                                            i_hist_labels(12)
                                           ELSE
                                            i_hist_labels(8)
                                       END,
                         io_table_2 => o_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_new_content_n,
                         io_table_3 => io_data,
                         i_value_3  => i_actual_row.pn_addendum,
                         io_table_4 => o_status,
                         i_value_4  => i_actual_row.flg_status);
        
        END IF;
    
        --signature
        g_error := 'CALL get_hist_signature';
        pk_alertlog.log_debug(g_error);
        IF NOT get_hist_signature(i_lang                => i_lang,
                                  i_prof                => i_prof,
                                  i_id_episode          => i_id_episode,
                                  i_id_prof_create      => i_actual_row.id_prof_create,
                                  i_dt_create           => i_actual_row.dt_create,
                                  i_id_prof_last_update => i_actual_row.id_prof_last_update,
                                  i_dt_last_update      => i_actual_row.dt_last_update,
                                  i_id_prof_signoff     => i_actual_row.id_prof_signoff,
                                  i_dt_signoff          => i_actual_row.dt_signoff,
                                  i_id_prof_cancel      => i_actual_row.id_prof_cancel,
                                  i_dt_cancel           => i_actual_row.dt_cancel,
                                  io_flg_types          => o_flg_types,
                                  io_labels             => o_labels,
                                  io_data               => io_data,
                                  io_status             => o_status,
                                  i_flg_status          => i_actual_row.flg_status,
                                  i_id_dictation_report => pk_prog_notes_utils.get_dictation_report(i_lang       => i_lang,
                                                                                                    i_prof       => i_prof,
                                                                                                    i_id_epis_pn => i_actual_row.id_epis_pn),
                                  i_flg_history         => i_actual_row.flg_history,
                                  i_id_software         => i_actual_row.id_software,
                                  o_error               => o_error)
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
                                              'get_addendum_history',
                                              o_error);
        
            RETURN FALSE;
    END get_addendum_history;

    /**
    * Returns the note history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_previous_info          Previous note information
    * @param i_actual_info            Actual note information    
    * @param i_detail_label           Detail label
    * @param i_hist_label             History label 
    * @param i_title_label            Title label  
    * @param i_show_edit_title        TRUE: The edition title should be shown. 
    *                                 FALSE: otherwise: the editions are shown together with other action
    * @param o_flg_types              Types output list
    * @param o_labels                 Labels output list
    * @param io_data                  Clob values list
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                10-Feb-2011
    */
    FUNCTION get_edition_dif
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_new_label       IN VARCHAR2,
        i_old_label       IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_show_edit_title IN VARCHAR2,
        io_flg_types      IN OUT NOCOPY table_varchar,
        io_labels         IN OUT NOCOPY table_varchar,
        io_data           IN OUT NOCOPY table_clob,
        io_status         IN OUT NOCOPY table_varchar,
        i_flg_status      IN epis_pn.flg_status%TYPE,
        i_nr_difs         IN PLS_INTEGER,
        i_actual_value    IN CLOB,
        i_previous_value  IN CLOB,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        --in the 1st difference set the title Edition
        IF (i_nr_difs = 0 AND i_show_edit_title = pk_alert_constant.g_yes)
        THEN
            --title
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                              i_prof               => i_prof,
                                                                              i_id_pn_note_type    => i_id_pn_note_type,
                                                                              i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_edit_e),
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_title_t,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => io_status,
                         i_value_4  => i_flg_status);
        END IF;
    
        IF (io_status.count > 1)
        THEN
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => NULL,
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_line,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => io_status,
                         i_value_4  => i_flg_status);
        END IF;
    
        --new value
        add_4_values(io_table_1 => io_labels,
                     i_value_1  => i_new_label, -- soap area desc ou soap block desc new
                     io_table_2 => io_flg_types,
                     i_value_2  => pk_prog_notes_constants.g_new_content_2_pts_nn,
                     io_table_3 => io_data,
                     i_value_3  => NULL,
                     io_table_4 => io_status,
                     i_value_4  => i_flg_status);
    
        add_4_values(io_table_1 => io_labels,
                     i_value_1  => NULL,
                     io_table_2 => io_flg_types,
                     i_value_2  => CASE
                                       WHEN i_id_pn_note_type IN
                                            (pk_prog_notes_constants.g_note_type_arabic_ft,
                                             pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                             pk_prog_notes_constants.g_note_type_arabic_ft_sw) THEN
                                        pk_prog_notes_constants.g_sub_title_content_stcra
                                       WHEN g_report_scope = pk_alert_constant.g_yes THEN
                                        pk_prog_notes_constants.g_sub_title_content_stcr
                                       ELSE
                                        pk_prog_notes_constants.g_sub_title_content_stc
                                   END,
                     io_table_3 => io_data,
                     i_value_3  => i_actual_value,
                     io_table_4 => io_status,
                     i_value_4  => i_flg_status);
    
        --old value      
        IF (i_previous_value IS NOT NULL)
        THEN
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => i_old_label,
                         io_table_2 => io_flg_types,
                         i_value_2  => pk_prog_notes_constants.g_content_2_pts_cc,
                         io_table_3 => io_data,
                         i_value_3  => NULL,
                         io_table_4 => io_status,
                         i_value_4  => i_flg_status);
        
            add_4_values(io_table_1 => io_labels,
                         i_value_1  => NULL,
                         io_table_2 => io_flg_types,
                         i_value_2  => CASE
                                           WHEN i_id_pn_note_type IN
                                                (pk_prog_notes_constants.g_note_type_arabic_ft,
                                                 pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                                 pk_prog_notes_constants.g_note_type_arabic_ft_sw) THEN
                                            pk_prog_notes_constants.g_sub_title_content_stcra
                                           WHEN g_report_scope = pk_alert_constant.g_yes THEN
                                            pk_prog_notes_constants.g_sub_title_content_stcr
                                           ELSE
                                            pk_prog_notes_constants.g_sub_title_content_stc
                                       END,
                         io_table_3 => io_data,
                         i_value_3  => i_previous_value,
                         io_table_4 => io_status,
                         i_value_4  => i_flg_status);
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
                                              'get_edition_dif',
                                              o_error);
        
            RETURN FALSE;
    END get_edition_dif;

    /**
    * Returns the note history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_actual_status     Note actual status
    * @param i_note_previous_status   Note previous status
    * @param i_hist_labels            History labels    
    * @param i_count_dif              Nr of differences detected in the note between the previous and the actual status     
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                11-Mar-2011
    */
    FUNCTION get_edit_without_changes
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_note_actual_status    IN epis_pn.flg_status%TYPE,
        i_note_actual_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_note_previous_status  IN epis_pn.flg_status%TYPE,
        i_hist_labels           IN table_varchar,
        i_count_dif             IN PLS_INTEGER,
        io_flg_types            IN OUT NOCOPY table_varchar,
        io_labels               IN OUT NOCOPY table_varchar,
        io_status               IN OUT NOCOPY table_varchar,
        io_data                 IN OUT NOCOPY table_clob,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --editions without changes
        IF (i_count_dif = 0)
        THEN
        
            IF ((i_note_actual_status = pk_prog_notes_constants.g_epis_pn_flg_status_t AND
               i_note_previous_status = pk_prog_notes_constants.g_epis_pn_flg_status_d) OR
               
               (i_note_actual_status = pk_prog_notes_constants.g_epis_pn_flg_status_d AND
               i_note_previous_status = pk_prog_notes_constants.g_epis_pn_flg_status_d) OR
               
               (i_note_actual_status = pk_prog_notes_constants.g_epis_pn_flg_status_f AND
               i_note_previous_status = pk_prog_notes_constants.g_epis_pn_flg_status_f) OR
               
               (i_note_actual_status = pk_prog_notes_constants.g_epis_pn_flg_status_t AND
               i_note_previous_status = pk_prog_notes_constants.g_epis_pn_flg_status_t))
            THEN
                --just save or edition without text changes
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                                  i_prof               => i_prof,
                                                                                  i_id_pn_note_type    => i_note_actual_note_type,
                                                                                  i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_edit_e),
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_title_t,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => io_status,
                             i_value_4  => i_note_actual_status);
            
                add_4_values(io_table_1 => io_labels,
                             i_value_1  => CASE
                                               WHEN i_note_actual_status = pk_prog_notes_constants.g_epis_pn_flg_status_t
                                                    AND i_note_previous_status = pk_prog_notes_constants.g_epis_pn_flg_status_d THEN
                                               
                                                i_hist_labels(3)
                                               ELSE
                                                i_hist_labels(4)
                                           END,
                             io_table_2 => io_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_sub_title_st,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => io_status,
                             i_value_4  => i_note_actual_status);
            END IF;
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
                                              'GET_EDIT_WITHOUT_CHANGES',
                                              o_error);
        
            RETURN FALSE;
    END get_edit_without_changes;

    /**
    * Returns the note history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_previous_info          Previous note information
    * @param i_actual_info            Actual note information    
    * @param i_detail_labels          Detail labels
    * @param i_hist_labels            History labels    
    * @param i_show_edit_title        TRUE: The edition title should be shown. 
    *                                 FALSE: otherwise: the editions are shown together with other action
    * @param o_flg_types              Types output list
    * @param o_labels                 Labels output list
    * @param io_data                  Clob values list
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_dif_notes_prev_act
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_previous_info    IN t_table_rec_pn_texts,
        i_actual_info      IN t_table_rec_pn_texts,
        i_show_edit_title  IN VARCHAR2,
        i_hist_labels      IN table_varchar,
        i_detail_labels    IN table_varchar,
        io_flg_types       IN OUT NOCOPY table_varchar,
        io_labels          IN OUT NOCOPY table_varchar,
        io_data            IN OUT NOCOPY table_clob,
        io_status          IN OUT NOCOPY table_varchar,
        i_flg_status       IN epis_pn.flg_status%TYPE,
        i_check_soap_block IN BOOLEAN DEFAULT TRUE,
        o_count_dif        OUT PLS_INTEGER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_DIF_NOTES_PREV_ACT';
    
        l_actual_block_ids      table_number := table_number();
        l_actual_data_block_ids table_number := table_number();
        l_index                 PLS_INTEGER;
        l_count_dif             PLS_INTEGER := 0;
        l_prev_indx             PLS_INTEGER := 1;
        l_actual_indx           PLS_INTEGER := 1;
        l_check_soap_block_rank BOOLEAN := i_check_soap_block;
    
        l_count PLS_INTEGER := 1;
    BEGIN
    
        WHILE (l_prev_indx <= i_previous_info.count OR l_actual_indx <= i_actual_info.count)
              AND l_count <= 100000
        LOOP
        
            --comparing the same soap or data block
            IF (i_previous_info.exists(l_prev_indx) AND i_actual_info.exists(l_actual_indx) AND
               --soap block comparison
               ((i_check_soap_block = TRUE AND i_previous_info(l_prev_indx).id_soap_block = i_actual_info(l_actual_indx).id_soap_block) OR
               --data block comparison
               (i_check_soap_block = FALSE AND i_previous_info(l_prev_indx).id_soap_block = i_actual_info(l_actual_indx).id_soap_block AND i_previous_info(l_prev_indx).id_soap_area = i_actual_info(l_actual_indx).id_soap_area)))
            THEN
            
                IF (
                   --soap blocks comparison
                    (i_check_soap_block = TRUE AND
                    dbms_lob.compare(REPLACE(i_previous_info(l_prev_indx).soap_block_txt, chr(13), chr(10)),
                                      REPLACE(i_actual_info(l_actual_indx).soap_block_txt, chr(13), chr(10))) <> 0) OR
                   --data blocks comparison
                    (i_check_soap_block = FALSE AND
                    dbms_lob.compare(i_previous_info(l_prev_indx).soap_area_txt,
                                      i_actual_info  (l_actual_indx).soap_area_txt) <> 0))
                THEN
                    g_error := 'CALL get_edition_dif 1';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_edition_dif(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_new_label       => coalesce(i_previous_info(l_prev_indx).soap_block_desc_new,
                                                                         i_previous_info(l_prev_indx).soap_area_desc_new,
                                                                         i_hist_labels(2)),
                                           i_old_label       => coalesce(i_previous_info(l_prev_indx).soap_block_desc,
                                                                         i_previous_info(l_prev_indx).soap_area_desc,
                                                                         i_detail_labels(4)),
                                           i_id_pn_note_type => i_previous_info(l_prev_indx).id_note_type,
                                           i_show_edit_title => i_show_edit_title,
                                           io_flg_types      => io_flg_types,
                                           io_labels         => io_labels,
                                           io_data           => io_data,
                                           io_status         => io_status,
                                           i_flg_status      => i_flg_status,
                                           i_nr_difs         => l_count_dif,
                                           i_actual_value    => nvl(i_actual_info(l_actual_indx).soap_block_txt,
                                                                    i_actual_info(l_actual_indx).soap_area_txt),
                                           i_previous_value  => nvl(i_previous_info(l_prev_indx).soap_block_txt,
                                                                    i_previous_info(l_prev_indx).soap_area_txt),
                                           o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_count_dif := l_count_dif + 1;
                END IF;
            
                --next record
                l_prev_indx   := l_prev_indx + 1;
                l_actual_indx := l_actual_indx + 1;
            ELSE
                --comparing diferent soap or data block  
            
                l_check_soap_block_rank := FALSE;
                IF (i_previous_info.exists(l_prev_indx))
                THEN
                    --if we are comparing by data block, but in this round we have different soap blocks 
                    --we have to consider the soap block ranks 
                    IF ((i_actual_info.exists(l_actual_indx) AND i_previous_info(l_prev_indx).id_soap_block <> i_actual_info(l_actual_indx).id_soap_block))
                    THEN
                        l_check_soap_block_rank := TRUE;
                    END IF;
                
                    SELECT t.id_soap_block, t.id_soap_area
                      BULK COLLECT
                      INTO l_actual_block_ids, l_actual_data_block_ids
                      FROM TABLE(i_actual_info) t;
                
                    -- the block was removed or added
                    --se o antigo estiver na lista de novos blocos foram acrescentados blocos
                    IF (i_check_soap_block = TRUE OR
                       --even though we are comparing by data block, when the soap blocks are diferent check 1st the soap block
                       l_check_soap_block_rank = TRUE)
                    THEN
                        l_index := pk_utils.search_table_number(i_table  => l_actual_block_ids,
                                                                i_search => i_previous_info(l_prev_indx).id_soap_block);
                    
                        --when the soap 
                        IF (l_index < l_prev_indx)
                        THEN
                            l_index := -3;
                        END IF;
                    ELSE
                        l_index := pk_utils.search_table_number(i_table  => l_actual_data_block_ids,
                                                                i_search => i_previous_info(l_prev_indx).id_soap_area);
                    END IF;
                ELSE
                    --new entries in the actual info
                    l_index := -2;
                END IF;
            
                IF (NOT i_actual_info.exists(l_actual_indx))
                THEN
                    l_index := -3;
                END IF;
            
                --the previous block text does not exists in the actual blocks, it was removed
                --if the pevious block rank is lower than the actual block rank show it now else show the actual first.
                IF (l_index = -3 OR
                   (l_index = -1 AND
                   ((l_check_soap_block_rank = TRUE AND i_previous_info(l_prev_indx).rank_soap_block <= i_actual_info(l_actual_indx).rank_soap_block) OR
                   (l_check_soap_block_rank = FALSE AND i_previous_info(l_prev_indx).rank_data_block <= i_actual_info(l_actual_indx).rank_data_block))))
                THEN
                    g_error := 'CALL get_edition_dif 2';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_edition_dif(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_new_label       => coalesce(i_previous_info(l_prev_indx).soap_block_desc_new,
                                                                         i_previous_info(l_prev_indx).soap_area_desc_new,
                                                                         i_hist_labels(2)),
                                           i_old_label       => coalesce(i_previous_info(l_prev_indx).soap_block_desc,
                                                                         i_previous_info(l_prev_indx).soap_area_desc,
                                                                         i_detail_labels(4)),
                                           i_id_pn_note_type => i_previous_info(l_prev_indx).id_note_type,
                                           i_show_edit_title => i_show_edit_title,
                                           io_flg_types      => io_flg_types,
                                           io_labels         => io_labels,
                                           io_data           => io_data,
                                           io_status         => io_status,
                                           i_flg_status      => i_flg_status,
                                           i_nr_difs         => l_count_dif,
                                           i_actual_value    => i_hist_labels(10),
                                           i_previous_value  => nvl(i_previous_info(l_prev_indx).soap_block_txt,
                                                                    i_previous_info(l_prev_indx).soap_area_txt),
                                           o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_count_dif := l_count_dif + 1;
                
                    --next record
                    l_prev_indx := l_prev_indx + 1;
                
                    --there is a new actual block with a lower rank than the previous block. Show it before the previous block
                ELSIF (l_index = -2 OR
                      (l_index = -1 AND
                      ((l_check_soap_block_rank = TRUE AND i_previous_info(l_prev_indx).rank_soap_block > i_actual_info(l_actual_indx).rank_soap_block) OR
                      (l_check_soap_block_rank = FALSE AND i_previous_info(l_prev_indx).rank_data_block > i_actual_info(l_actual_indx).rank_data_block))))
                THEN
                    --the actual value is new. show it
                    g_error := 'CALL get_edition_dif 3';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_edition_dif(i_lang            => i_lang,
                                           i_prof            => i_prof,
                                           i_new_label       => coalesce(i_actual_info(l_actual_indx).soap_block_desc_new,
                                                                         i_actual_info(l_actual_indx).soap_area_desc_new,
                                                                         i_hist_labels(2)),
                                           i_old_label       => NULL,
                                           i_id_pn_note_type => i_actual_info(l_actual_indx).id_note_type,
                                           i_show_edit_title => i_show_edit_title,
                                           io_flg_types      => io_flg_types,
                                           io_labels         => io_labels,
                                           io_data           => io_data,
                                           io_status         => io_status,
                                           i_flg_status      => i_flg_status,
                                           i_nr_difs         => l_count_dif,
                                           i_actual_value    => nvl(i_actual_info(l_actual_indx).soap_block_txt,
                                                                    i_actual_info(l_actual_indx).soap_area_txt),
                                           i_previous_value  => NULL,
                                           o_error           => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                
                    l_count_dif := l_count_dif + 1;
                
                    --next record
                    l_actual_indx := l_actual_indx + 1;
                ELSE
                    --new blocks in the actual result till l_index
                    IF (l_actual_indx <= (l_index - 1))
                    THEN
                        FOR i IN l_actual_indx .. (l_index - 1)
                        LOOP
                            g_error := 'CALL get_edition_dif 4';
                            pk_alertlog.log_debug(g_error);
                            IF NOT get_edition_dif(i_lang            => i_lang,
                                                   i_prof            => i_prof,
                                                   i_new_label       => coalesce(i_actual_info(l_actual_indx).soap_block_desc_new,
                                                                                 i_actual_info(l_actual_indx).soap_area_desc_new,
                                                                                 i_hist_labels(2)),
                                                   i_old_label       => coalesce(i_previous_info(l_prev_indx).soap_block_desc,
                                                                                 i_previous_info(l_prev_indx).soap_area_desc,
                                                                                 i_detail_labels(4)),
                                                   i_id_pn_note_type => i_previous_info(l_prev_indx).id_note_type,
                                                   i_show_edit_title => i_show_edit_title,
                                                   io_flg_types      => io_flg_types,
                                                   io_labels         => io_labels,
                                                   io_data           => io_data,
                                                   io_status         => io_status,
                                                   i_flg_status      => i_flg_status,
                                                   i_nr_difs         => l_count_dif,
                                                   i_actual_value    => nvl(i_actual_info(l_actual_indx).soap_block_txt,
                                                                            i_actual_info(l_actual_indx).soap_area_txt),
                                                   i_previous_value  => NULL,
                                                   o_error           => o_error)
                            THEN
                                RAISE g_exception;
                            END IF;
                        
                            l_count_dif := l_count_dif + 1;
                        
                            --next record
                            l_actual_indx := l_actual_indx + 1;
                        END LOOP;
                    END IF;
                
                END IF;
            END IF;
            l_count := l_count + 1;
        END LOOP;
    
        o_count_dif := l_count_dif;
    
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
    END get_dif_notes_prev_act;

    /**
    * Returns the diferences between the actual text soap blocks and the previous text soap blocks.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_note_actual_info       Actual note information
    * @param i_note_previous_info     Previous note status info (the previous info in the history from i_note_actual_info)
    * @param i_detail_labels          Detail labels
    * @param i_hist_labels            History labels
    * @param io_flg_types              Types output list
    * @param io_labels                 Labels output list
    * @param io_status                 Status of the note or addendum. Depends on the data being refered to an adendum or a note.
    * @param io_data                  Clob values list
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_diff_act_prev_block_txts
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_note_actual_info   IN t_rec_epis_pn_hist,
        i_note_previous_info IN t_rec_epis_pn_hist,
        i_note_prev_status   IN table_varchar,
        i_note_act_status    IN table_varchar,
        i_show_edit_title    IN VARCHAR2,
        i_detail_labels      IN table_varchar,
        i_hist_labels        IN table_varchar,
        io_flg_types         IN OUT NOCOPY table_varchar,
        io_labels            IN OUT NOCOPY table_varchar,
        io_status            IN OUT NOCOPY table_varchar,
        io_data              IN OUT NOCOPY table_clob,
        o_count_dif          OUT PLS_INTEGER,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_texts_prev t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_texts_act  t_table_rec_pn_texts := t_table_rec_pn_texts();
    BEGIN
        IF (i_note_previous_info.flg_history = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL get_signoff_block_txts. i_id_epis_pn: ' || i_note_previous_info.id_epis_pn;
        
            pk_alertlog.log_debug(g_error);
            l_texts_prev := get_note_block_texts(i_lang        => i_lang,
                                                 i_prof        => i_prof,
                                                 i_note_ids    => table_number(i_note_previous_info.id_epis_pn),
                                                 i_note_status => i_note_prev_status,
                                                 i_show_title  => pk_prog_notes_constants.g_show_all);
        
        ELSE
            g_error := 'CALL get_histsignoff_blocks. i_id_epis_pn: ' || i_note_actual_info.id_epis_pn;
            pk_alertlog.log_debug(g_error);
            l_texts_prev := get_note_block_texts_hist(i_lang       => i_lang,
                                                      i_prof       => i_prof,
                                                      i_note_id    => i_note_previous_info.id_epis_pn,
                                                      i_dt_hist    => i_note_previous_info.dt_hist,
                                                      i_show_title => pk_prog_notes_constants.g_show_all);
        
        END IF;
    
        IF (i_note_actual_info.flg_history = pk_alert_constant.g_no)
        THEN
            g_error := 'CALL get_note_block_texts. i_id_epis_pn: ' || i_note_actual_info.id_epis_pn;
            pk_alertlog.log_debug(g_error);
            l_texts_act := get_note_block_texts(i_lang        => i_lang,
                                                i_prof        => i_prof,
                                                i_note_ids    => table_number(i_note_actual_info.id_epis_pn),
                                                i_note_status => i_note_act_status,
                                                i_show_title  => pk_prog_notes_constants.g_show_all);
        
        ELSE
            g_error := 'CALL get_note_block_texts_hist';
            pk_alertlog.log_debug(g_error);
            l_texts_act := get_note_block_texts_hist(i_lang       => i_lang,
                                                     i_prof       => i_prof,
                                                     i_note_id    => i_note_actual_info.id_epis_pn,
                                                     i_dt_hist    => i_note_actual_info.dt_hist,
                                                     i_show_title => pk_prog_notes_constants.g_show_all);
        END IF;
    
        IF (l_texts_prev IS NOT NULL)
        THEN
            g_error := 'CALL get_dif_notes_prev_act';
            pk_alertlog.log_debug(g_error);
            IF NOT get_dif_notes_prev_act(i_lang            => i_lang,
                                          i_prof            => i_prof,
                                          i_previous_info   => l_texts_prev,
                                          i_actual_info     => l_texts_act,
                                          i_show_edit_title => i_show_edit_title,
                                          i_hist_labels     => i_hist_labels,
                                          i_detail_labels   => i_detail_labels,
                                          io_flg_types      => io_flg_types,
                                          io_labels         => io_labels,
                                          io_data           => io_data,
                                          io_status         => io_status,
                                          i_flg_status      => i_note_actual_info.flg_status,
                                          o_count_dif       => o_count_dif,
                                          o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
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
                                              'get_diff_act_prev_block_txts',
                                              o_error);
        
            RETURN FALSE;
    END get_diff_act_prev_block_txts;

    /**
    * Returns the note history info.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_note_actual_info       Actual note information
    * @param i_note_previous_info     Previous note status info (the previous info in the history from i_note_actual_info)
    * @param i_detail_labels          Detail labels
    * @param i_hist_labels            History labels
    * @param i_flg_check_addendums    TRUE-it is being processed the more recent info of the note. It is necessary to include the addendums info
    *                                 FALSE-otherwise
    * @param i_pn_note_type_cfg       Configs according to the note type
    * @param o_flg_types              Types output list
    * @param o_labels                 Labels output list
    * @param o_status                 Status of the note or addendum. Depends on the data being refered to an adendum or a note.
    * @param io_data                  Clob values list
    * @param o_notes_texts            Texts that compose the note    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_note_history
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_note_actual_info   IN t_rec_epis_pn_hist,
        i_note_previous_info IN t_rec_epis_pn_hist,
        i_detail_labels      IN table_varchar,
        i_hist_labels        IN table_varchar,
        i_pn_note_type_cfg   IN t_rec_note_type,
        o_flg_types          OUT NOCOPY table_varchar,
        o_labels             OUT NOCOPY table_varchar,
        o_status             OUT NOCOPY table_varchar,
        io_data              IN OUT NOCOPY table_clob,
        i_has_addendums      IN VARCHAR2,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_NOTE_HISTORY';
    
        l_texts_prev t_table_rec_pn_texts := t_table_rec_pn_texts();
        l_texts_act  t_table_rec_pn_texts := t_table_rec_pn_texts();
    
        l_count_dif          PLS_INTEGER;
        l_value              pk_translation.t_desc_translation;
        l_bool_execute       BOOLEAN;
        l_bool_validation_01 BOOLEAN;
        l_show_edit_title    VARCHAR2(0010 CHAR);
    
        k_epis_pn_flg_status_s      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_s;
        k_epis_pn_flg_submited      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_submited;
        k_epis_pn_flg_status_c      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_c;
        k_epis_pn_flg_draftsubmit   CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_draftsubmit;
        k_epis_pn_flg_status_d      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_d;
        k_epis_pn_flg_status_t      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_t;
        k_epis_pn_flg_status_m      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_m;
        k_epis_pn_flg_status_f      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_f;
        k_epis_pn_flg_status_review CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
        l_flg_status_act VARCHAR2(0010 CHAR);
        l_flg_status_prv VARCHAR2(0010 CHAR);
    
        tbl_flg_status table_varchar := table_varchar(k_epis_pn_flg_status_s,
                                                      k_epis_pn_flg_submited,
                                                      k_epis_pn_flg_status_c,
                                                      k_epis_pn_flg_draftsubmit,
                                                      k_epis_pn_flg_status_review);
    
        -- **************************************************************
        PROCEDURE process_stuff IS
        BEGIN
        
            l_texts_prev := get_note_dblock_texts_hist(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_episode      => i_id_episode,
                                                       i_note_id         => i_note_previous_info.id_epis_pn,
                                                       i_note_status     => l_flg_status_act,
                                                       i_dt_hist         => i_note_previous_info.dt_hist,
                                                       i_id_pn_note_type => i_note_previous_info.id_note_type,
                                                       i_flg_detail      => pk_alert_constant.g_yes);
        
            -- IF_22
            IF (i_note_actual_info.flg_history = pk_alert_constant.g_no)
            THEN
                g_error := 'CALL get_note_dblock_texts. i_note_id: ' || i_note_actual_info.id_epis_pn;
                pk_alertlog.log_debug(g_error);
                l_texts_act := get_note_dblock_texts(i_lang            => i_lang,
                                                     i_prof            => i_prof,
                                                     i_id_episode      => i_id_episode,
                                                     i_note_id         => i_note_actual_info.id_epis_pn,
                                                     i_note_status     => l_flg_status_act,
                                                     i_id_pn_note_type => i_note_actual_info.id_note_type,
                                                     i_flg_detail      => pk_alert_constant.g_yes);
            
            ELSE
                -- IF_22
            
                g_error := 'CALL get_note_dblock_texts_hist. i_note_ids: ' || i_note_previous_info.id_epis_pn;
                pk_alertlog.log_debug(g_error);
                l_texts_act := get_note_dblock_texts_hist(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_id_episode,
                                                          i_note_id         => i_note_actual_info.id_epis_pn,
                                                          i_note_status     => l_flg_status_act,
                                                          i_dt_hist         => i_note_actual_info.dt_hist,
                                                          i_id_pn_note_type => i_note_actual_info.id_note_type,
                                                          i_flg_detail      => pk_alert_constant.g_yes);
            END IF; -- IF_22
        
            -- IF_TXT_PREV
            IF (l_texts_prev IS NOT NULL)
            THEN
            
                g_error := 'CALL get_dif_notes_prev_act';
                pk_alertlog.log_debug(g_error);
                IF NOT get_dif_notes_prev_act(i_lang             => i_lang,
                                              i_prof             => i_prof,
                                              i_previous_info    => l_texts_prev,
                                              i_actual_info      => l_texts_act,
                                              i_show_edit_title  => pk_alert_constant.g_yes,
                                              i_detail_labels    => i_detail_labels,
                                              i_hist_labels      => i_hist_labels,
                                              io_flg_types       => o_flg_types,
                                              io_labels          => o_labels,
                                              io_data            => io_data,
                                              io_status          => o_status,
                                              i_flg_status       => l_flg_status_act,
                                              i_check_soap_block => FALSE,
                                              o_count_dif        => l_count_dif,
                                              o_error            => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF; -- IF_TXT_PREV
        
        END process_stuff;
        -- #############################################
    
    BEGIN
        o_labels    := table_varchar();
        o_flg_types := table_varchar();
        o_status    := table_varchar();
    
        l_flg_status_act := i_note_actual_info.flg_status;
        l_flg_status_prv := i_note_previous_info.flg_status;
    
        l_bool_validation_01 := l_flg_status_act = k_epis_pn_flg_draftsubmit AND
                                l_flg_status_prv = k_epis_pn_flg_submited;
        -- IF_00
        IF (l_flg_status_act <> l_flg_status_prv AND (NOT l_bool_validation_01))
        THEN
        
            -- IF_01
            IF l_flg_status_act MEMBER OF tbl_flg_status
            THEN
            
                --> D --> C   and M --> C
                -- only the status is required. 
                g_error := 'CALL pk_prog_notes_utils.get_note_type_desc. id_note_type: ' ||
                           i_note_actual_info.id_note_type || ' i_flg_code_note_type: ' || l_flg_status_act;
                l_value := pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                  i_prof               => i_prof,
                                                                  i_id_pn_note_type    => i_note_actual_info.id_note_type,
                                                                  i_flg_code_note_type => l_flg_status_act);
            
                --title    
                add_4_values(io_table_1 => o_labels,
                             i_value_1  => l_value,
                             io_table_2 => o_flg_types,
                             i_value_2  => pk_prog_notes_constants.g_title_t,
                             io_table_3 => io_data,
                             i_value_3  => NULL,
                             io_table_4 => o_status,
                             i_value_4  => l_flg_status_act);
            
                g_error := 'CALL get_hist_status';
                pk_alertlog.log_debug(g_error);
            
                -- IF_02
                IF NOT get_hist_status(i_lang                 => i_lang,
                                       i_prof                 => i_prof,
                                       i_detail_status_label  => i_detail_labels(1),
                                       i_hist_status_label    => i_hist_labels(1),
                                       i_code_domain          => pk_prog_notes_constants.g_sd_note_flg_status,
                                       i_val_actual           => l_flg_status_act,
                                       i_val_previous         => l_flg_status_prv,
                                       i_status_actual        => l_flg_status_act,
                                       i_flg_status_available => i_pn_note_type_cfg.flg_status_available,
                                       io_flg_types           => o_flg_types,
                                       io_labels              => o_labels,
                                       io_data                => io_data,
                                       io_status              => o_status,
                                       o_error                => o_error)
                THEN
                    RAISE g_exception;
                END IF; -- IF_02
            
            END IF; -- IF_01;
        
            -- IF_03
            l_bool_execute := FALSE;
            IF (l_flg_status_act = k_epis_pn_flg_status_s AND l_flg_status_prv = k_epis_pn_flg_status_d)
               OR (l_flg_status_act = k_epis_pn_flg_submited AND l_flg_status_prv = k_epis_pn_flg_status_d)
               OR (l_flg_status_act = k_epis_pn_flg_submited AND l_flg_status_prv = k_epis_pn_flg_draftsubmit)
               OR (l_flg_status_act = k_epis_pn_flg_status_s AND l_flg_status_prv = k_epis_pn_flg_status_t)
            THEN
            
                l_bool_execute    := TRUE;
                l_show_edit_title := pk_alert_constant.g_no;
                --> D --> T
            ELSIF (l_flg_status_act = k_epis_pn_flg_status_t AND l_flg_status_prv = k_epis_pn_flg_status_d)
            THEN
                l_bool_execute    := TRUE;
                l_show_edit_title := pk_alert_constant.g_yes;
            END IF; -- IF_03
        
            -- IF_BEXECUTE
            IF l_bool_execute
            THEN
            
                g_error := 'CALL get_diff_act_prev_block_txts';
                pk_alertlog.log_debug(g_error);
                IF NOT get_diff_act_prev_block_txts(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_note_actual_info   => i_note_actual_info,
                                                    i_note_previous_info => i_note_previous_info,
                                                    i_note_prev_status   => table_varchar(l_flg_status_prv),
                                                    i_note_act_status    => table_varchar(l_flg_status_act),
                                                    i_show_edit_title    => l_show_edit_title,
                                                    i_detail_labels      => i_detail_labels,
                                                    i_hist_labels        => i_hist_labels,
                                                    io_flg_types         => o_flg_types,
                                                    io_labels            => o_labels,
                                                    io_status            => o_status,
                                                    io_data              => io_data,
                                                    o_count_dif          => l_count_dif,
                                                    o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
            END IF; --IF_BEXECUTE
            -- D-V
            IF l_flg_status_act = k_epis_pn_flg_status_review
               AND l_flg_status_prv = k_epis_pn_flg_status_d
            THEN
                IF i_note_actual_info.id_prof_reviewed IS NOT NULL
                THEN
                    IF NOT get_prof_review(i_lang             => i_lang,
                                           i_prof             => i_prof,
                                           i_id_prof_reviewed => i_note_actual_info.id_prof_reviewed,
                                           i_dt_reviewed      => i_note_actual_info.dt_reviewed,
                                           io_flg_types       => o_flg_types,
                                           io_labels          => o_labels,
                                           io_status          => o_status,
                                           io_data            => io_data,
                                           o_error            => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            END IF;
        ELSE
            -- IF_00
        
            -- IF_04
            l_bool_execute := FALSE;
            IF l_flg_status_act IN (k_epis_pn_flg_status_t, k_epis_pn_flg_status_m)
            --OR l_bool_validation_01
            THEN
            
                g_error := 'CALL get_diff_act_prev_block_txts';
                pk_alertlog.log_debug(g_error);
                IF NOT get_diff_act_prev_block_txts(i_lang               => i_lang,
                                                    i_prof               => i_prof,
                                                    i_note_actual_info   => i_note_actual_info,
                                                    i_note_previous_info => i_note_previous_info,
                                                    i_note_prev_status   => table_varchar(l_flg_status_prv),
                                                    i_note_act_status    => table_varchar(l_flg_status_act),
                                                    i_show_edit_title    => pk_alert_constant.g_yes,
                                                    i_detail_labels      => i_detail_labels,
                                                    i_hist_labels        => i_hist_labels,
                                                    io_flg_types         => o_flg_types,
                                                    io_labels            => o_labels,
                                                    io_status            => o_status,
                                                    io_data              => io_data,
                                                    o_count_dif          => l_count_dif,
                                                    o_error              => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                -- D --> IF_04
            ELSIF l_flg_status_act IN (k_epis_pn_flg_status_d, k_epis_pn_flg_status_f, k_epis_pn_flg_draftsubmit)
                  OR l_bool_validation_01
            THEN
                l_bool_execute := TRUE;
            ELSIF l_flg_status_act = l_flg_status_prv
                  AND l_flg_status_prv = k_epis_pn_flg_status_review
            THEN
                l_bool_execute := TRUE;
            END IF; -- IF_04
        
            --- execute_stuff
            IF l_bool_execute
            THEN
                process_stuff();
            END IF;
        
        END IF; -- IF_00
        --in the edition, if the user inserts text and delete it again, he is allowed to confirm the note edition,
        --however there is no changes to be shown in the history
        g_error := 'CALL get_edit_without_changes';
        pk_alertlog.log_debug(g_error);
        IF NOT get_edit_without_changes(i_lang                  => i_lang,
                                        i_prof                  => i_prof,
                                        i_note_actual_status    => l_flg_status_act,
                                        i_note_actual_note_type => i_note_actual_info.id_note_type,
                                        i_note_previous_status  => l_flg_status_prv,
                                        i_hist_labels           => i_hist_labels,
                                        i_count_dif             => l_count_dif,
                                        io_flg_types            => o_flg_types,
                                        io_labels               => o_labels,
                                        io_status               => o_status,
                                        io_data                 => io_data,
                                        o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --Cancellation info and signature
        g_error := 'CALL get_cancel_info_and_sign';
        pk_alertlog.log_debug(g_error);
        IF NOT get_cancel_info_and_sign(i_lang                => i_lang,
                                        i_prof                => i_prof,
                                        i_flg_status          => l_flg_status_act,
                                        i_id_cancel_reason    => i_note_actual_info.id_cancel_reason,
                                        i_cancel_notes        => i_note_actual_info.cancel_notes, -------
                                        i_id_episode          => i_note_actual_info.id_episode,
                                        i_id_prof_create      => i_note_actual_info.id_prof_create,
                                        i_dt_create           => i_note_actual_info.dt_create,
                                        i_id_prof_last_update => i_note_actual_info.id_prof_last_update,
                                        i_dt_last_update      => i_note_actual_info.dt_last_update,
                                        i_id_prof_signoff     => i_note_actual_info.id_prof_signoff,
                                        i_dt_signoff          => i_note_actual_info.dt_signoff,
                                        i_id_prof_cancel      => i_note_actual_info.id_prof_cancel,
                                        i_dt_cancel           => i_note_actual_info.dt_cancel,
                                        i_detail_labels       => i_detail_labels,
                                        i_set_signature       => pk_alert_constant.g_yes,
                                        io_flg_types          => o_flg_types,
                                        io_labels             => o_labels,
                                        io_data               => io_data,
                                        io_status             => o_status,
                                        i_id_dictation_report => i_note_actual_info.id_dictation_report,
                                        i_flg_history         => i_note_actual_info.flg_history,
                                        i_has_addendums       => i_has_addendums,
                                        i_id_software         => i_note_actual_info.id_software,
                                        i_id_prof_reviewed    => nvl(i_note_actual_info.id_prof_last_update,
                                                                     i_note_actual_info.id_prof_create),
                                        i_dt_reviewed         => i_note_actual_info.dt_reviewed,
                                        i_id_prof_submit      => i_note_actual_info.id_prof_submit,
                                        i_dt_submit           => i_note_actual_info.dt_submit,
                                        i_epis_pn             => i_note_actual_info.id_epis_pn,
                                        o_error               => o_error)
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
    END get_note_history;

    /**
    * Returns the labels of the detail.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param o_detail_labels          List of the deatil labels    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_detail_labels
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_detail_labels OUT NOCOPY table_varchar,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_detail_labels := table_varchar();
    
        o_detail_labels.extend(4);
        o_detail_labels(1) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_status);
        o_detail_labels(2) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_canc_reason);
        o_detail_labels(3) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_canc_notes);
        o_detail_labels(4) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_note);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_DETAIL_LABELS',
                                              o_error);
        
            RETURN FALSE;
    END get_detail_labels;

    /**
    * Returns the labels to the history screen.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param o_hist_labels            List of the history labels    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_history_labels
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        o_hist_labels OUT NOCOPY table_varchar,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        o_hist_labels := table_varchar();
    
        o_hist_labels.extend(13);
        o_hist_labels(1) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_new_status);
        o_hist_labels(2) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_new_note);
        o_hist_labels(3) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_just_save);
        o_hist_labels(4) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_edit_without_ch);
        o_hist_labels(5) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_addendum);
        o_hist_labels(6) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_add_signoff);
        o_hist_labels(7) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_add_canc);
        o_hist_labels(8) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_add_new);
        o_hist_labels(9) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_add_edit);
        o_hist_labels(10) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_del_info);
        o_hist_labels(11) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_pn_comments);
        o_hist_labels(12) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_pn_comments_new);
        o_hist_labels(13) := pk_message.get_message(i_lang, i_prof, pk_prog_notes_constants.g_sm_pn_comments_edit);
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_HISTORY_LABELS',
                                              o_error);
        
            RETURN FALSE;
    END get_history_labels;

    /**
    * Returns the notes to the show in the history with pagging.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note identifier
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param o_note_info              List of records to be processed on history    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                26-Jan-2011
    */
    FUNCTION get_notes_hist_records
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_screen      IN VARCHAR2,
        i_id_epis_pn      IN table_number,
        i_start_record    IN NUMBER,
        i_num_records     IN NUMBER,
        i_flg_report_type IN VARCHAR2 DEFAULT NULL,
        o_hist_info       OUT NOCOPY tab_epis_pn_hist,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --get the note records
        g_error := 'GET HISTORY RECORDS.';
        pk_alertlog.log_debug(g_error);
        SELECT t.id_epis_pn,
               t.dt_hist,
               t.id_episode,
               t.flg_status,
               t.id_pn_note_type,
               t.id_dep_clin_serv,
               t.dt_pn_date,
               t.id_prof_create,
               t.dt_create,
               t.dt_last_update,
               t.id_prof_last_update,
               t.id_prof_signoff,
               t.dt_signoff,
               t.id_prof_cancel,
               t.dt_cancel,
               t.id_cancel_reason,
               t.notes_cancel,
               t.flg_history,
               t.flg_note,
               t.id_dictation_report,
               t.max_notes,
               id_epis_pn_addendum,
               pn_addendum,
               flg_record_type,
               t.id_software,
               id_prof_reviewed,
               dt_reviewed,
               id_prof_submit,
               dt_submit
          BULK COLLECT
          INTO o_hist_info
          FROM (SELECT MAX(rn) over() max_notes, t_int.*
                  FROM (SELECT rownum rn, t_internal.*
                          FROM (SELECT epa.id_epis_pn,
                                       current_timestamp dt_hist,
                                       NULL id_episode,
                                       epa.flg_status,
                                       NULL id_pn_note_type,
                                       NULL id_dep_clin_serv,
                                       NULL dt_pn_date,
                                       epa.id_professional id_prof_create,
                                       epa.dt_addendum dt_create,
                                       epa.dt_last_update,
                                       epa.id_prof_last_update,
                                       epa.id_prof_signoff,
                                       epa.dt_signoff,
                                       epa.id_prof_cancel,
                                       epa.dt_cancel,
                                       epa.id_cancel_reason,
                                       epa.notes_cancel,
                                       pk_alert_constant.g_no flg_history,
                                       NULL flg_note,
                                       NULL id_dictation_report,
                                       epa.id_epis_pn_addendum,
                                       epa.pn_addendum,
                                       epa.flg_type flg_record_type,
                                       epa.dt_addendum dt_sort,
                                       NULL id_software,
                                       NULL id_prof_reviewed,
                                       NULL dt_reviewed,
                                       NULL id_prof_submit,
                                       NULL dt_submit,
                                       CASE
                                            WHEN i_flg_report_type IS NULL THEN
                                             0
                                            ELSE
                                             epa.id_epis_pn
                                        END epis_pn_order
                                  FROM epis_pn_addendum epa
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_id_epis_pn) t1) tids
                                    ON tids.id_epis_pn = epa.id_epis_pn
                                 WHERE (i_flg_screen = pk_prog_notes_constants.g_hist_screen_h)
                                UNION ALL
                                SELECT eah.id_epis_pn,
                                       eah.dt_epis_addendum_hist dt_hist,
                                       NULL id_episode,
                                       eah.flg_status,
                                       NULL id_pn_note_type,
                                       NULL id_dep_clin_serv,
                                       NULL dt_pn_date,
                                       eah.id_professional id_prof_create,
                                       eah.dt_addendum dt_create,
                                       eah.dt_last_update,
                                       eah.id_prof_last_update,
                                       eah.id_prof_signoff,
                                       eah.dt_signoff,
                                       eah.id_prof_cancel,
                                       eah.dt_cancel,
                                       eah.id_cancel_reason,
                                       eah.notes_cancel,
                                       pk_alert_constant.g_yes flg_history,
                                       NULL flg_note,
                                       NULL id_dictation_report,
                                       eah.id_epis_pn_addendum,
                                       eah.pn_addendum,
                                       eah.flg_type flg_record_type,
                                       eah.dt_addendum dt_sort,
                                       NULL id_software,
                                       NULL id_prof_reviewed,
                                       NULL dt_reviewed,
                                       NULL id_prof_submit,
                                       NULL dt_submit,
                                       CASE
                                           WHEN i_flg_report_type IS NULL THEN
                                            0
                                           ELSE
                                            eah.id_epis_pn
                                       END epis_pn_order
                                  FROM epis_pn_addendum_hist eah
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_id_epis_pn) t1) tids
                                    ON tids.id_epis_pn = eah.id_epis_pn
                                 WHERE (i_flg_screen = pk_prog_notes_constants.g_hist_screen_h)
                                
                                UNION ALL
                                SELECT eph.id_epis_pn,
                                       eph.dt_epis_pn_hist dt_hist,
                                       eph.id_episode,
                                       eph.flg_status,
                                       eph.id_pn_note_type,
                                       eph.id_dep_clin_serv,
                                       eph.dt_pn_date,
                                       eph.id_prof_create,
                                       eph.dt_create,
                                       eph.dt_last_update,
                                       eph.id_prof_last_update,
                                       eph.id_prof_signoff,
                                       eph.dt_signoff,
                                       eph.id_prof_cancel,
                                       eph.dt_cancel,
                                       eph.id_cancel_reason,
                                       eph.notes_cancel,
                                       pk_alert_constant.g_yes flg_history,
                                       pk_alert_constant.g_yes flg_note,
                                       eph.id_dictation_report,
                                       NULL id_epis_pn_addendum,
                                       NULL pn_addendum,
                                       pk_prog_notes_constants.g_note flg_record_type,
                                       eph.dt_epis_pn_hist dt_sort,
                                       eph.id_software id_software,
                                       eph.id_prof_reviewed,
                                       eph.dt_reviewed,
                                       eph.id_prof_submit,
                                       eph.dt_submit,
                                       CASE
                                           WHEN i_flg_report_type IS NULL THEN
                                            0
                                           ELSE
                                            eph.id_epis_pn
                                       END epis_pn_order
                                  FROM epis_pn_hist eph
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_id_epis_pn) t1) tids
                                    ON tids.id_epis_pn = eph.id_epis_pn
                                 WHERE (i_flg_screen = pk_prog_notes_constants.g_hist_screen_h)
                                UNION ALL
                                SELECT epn.id_epis_pn,
                                       current_timestamp dt_hist,
                                       epn.id_episode,
                                       epn.flg_status,
                                       epn.id_pn_note_type,
                                       epn.id_dep_clin_serv,
                                       epn.dt_pn_date,
                                       epn.id_prof_create,
                                       epn.dt_create,
                                       epn.dt_last_update,
                                       epn.id_prof_last_update,
                                       epn.id_prof_signoff,
                                       epn.dt_signoff,
                                       epn.id_prof_cancel,
                                       epn.dt_cancel,
                                       epn.id_cancel_reason,
                                       epn.notes_cancel,
                                       pk_alert_constant.g_no flg_history,
                                       pk_alert_constant.g_yes flg_note,
                                       epn.id_dictation_report,
                                       NULL id_epis_pn_addendums,
                                       NULL pn_addendum,
                                       pk_prog_notes_constants.g_note flg_record_type,
                                       current_timestamp dt_sort,
                                       epn.id_software id_software,
                                       epn.id_prof_reviewed,
                                       epn.dt_reviewed,
                                       epn.id_prof_submit,
                                       epn.dt_submit,
                                       CASE
                                           WHEN i_flg_report_type IS NULL THEN
                                            0
                                           ELSE
                                            epn.id_epis_pn
                                       END epis_pn_order
                                  FROM epis_pn epn
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_id_epis_pn) t1) tids
                                    ON tids.id_epis_pn = epn.id_epis_pn
                                 ORDER BY epis_pn_order, flg_record_type, dt_sort DESC, dt_hist DESC) t_internal) t_int) t
         WHERE (i_start_record IS NULL OR (rn BETWEEN i_start_record + 1 AND (i_start_record + i_num_records + 1)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTES_HIST_RECORDS',
                                              o_error);
        
            RETURN FALSE;
    END get_notes_hist_records;

    FUNCTION get_note_record
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_screen   IN VARCHAR2,
        i_id_epis_pn   IN table_number,
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        o_hist_info    OUT NOCOPY tab_epis_pn_hist,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --get the note records
        g_error := 'GET NOTE RECORD.';
        pk_alertlog.log_debug(g_error);
        SELECT t.id_epis_pn,
               t.dt_hist,
               t.id_episode,
               t.flg_status,
               t.id_pn_note_type,
               t.id_dep_clin_serv,
               t.dt_pn_date,
               t.id_prof_create,
               t.dt_create,
               t.dt_last_update,
               t.id_prof_last_update,
               t.id_prof_signoff,
               t.dt_signoff,
               t.id_prof_cancel,
               t.dt_cancel,
               t.id_cancel_reason,
               t.notes_cancel,
               t.flg_history,
               t.flg_note,
               t.id_dictation_report,
               t.max_notes,
               NULL,
               pn_addendum,
               flg_record_type,
               t.id_software,
               id_prof_reviewed,
               dt_reviewed,
               id_prof_submit,
               dt_submit
          BULK COLLECT
          INTO o_hist_info
          FROM (SELECT MAX(rn) over() max_notes, t_int.*
                  FROM (SELECT rownum rn, t_internal.*
                          FROM (SELECT epn.id_epis_pn,
                                       current_timestamp              dt_hist,
                                       epn.id_episode,
                                       epn.flg_status,
                                       epn.id_pn_note_type,
                                       epn.id_dep_clin_serv,
                                       epn.dt_pn_date,
                                       epn.id_prof_create,
                                       epn.dt_create,
                                       epn.dt_last_update,
                                       epn.id_prof_last_update,
                                       epn.id_prof_signoff,
                                       epn.dt_signoff,
                                       epn.id_prof_cancel,
                                       epn.dt_cancel,
                                       epn.id_cancel_reason,
                                       epn.notes_cancel,
                                       pk_alert_constant.g_no         flg_history,
                                       pk_alert_constant.g_yes        flg_note,
                                       epn.id_dictation_report,
                                       NULL                           id_epis_pn_addendums,
                                       NULL                           pn_addendum,
                                       pk_prog_notes_constants.g_note flg_record_type,
                                       current_timestamp              dt_sort,
                                       epn.id_software                id_software,
                                       epn.id_prof_reviewed,
                                       epn.dt_reviewed,
                                       epn.id_prof_submit,
                                       epn.dt_submit
                                  FROM epis_pn epn
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_id_epis_pn) t1) tids
                                    ON tids.id_epis_pn = epn.id_epis_pn
                                 ORDER BY id_epis_pn, flg_record_type, dt_sort DESC, dt_hist DESC) t_internal) t_int) t
         WHERE (i_start_record IS NULL OR (rn BETWEEN i_start_record + 1 AND (i_start_record + i_num_records + 1)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_NOTE_RECORD',
                                              o_error);
        
            RETURN FALSE;
    END get_note_record;

    FUNCTION get_note_hist
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_flg_screen   IN VARCHAR2,
        i_id_epis_pn   IN table_number,
        i_start_record IN NUMBER,
        i_num_records  IN NUMBER,
        o_hist_info    OUT NOCOPY tab_epis_pn_hist,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --get the note records
        g_error := 'GET NOTE HISTORY';
        pk_alertlog.log_debug(g_error);
        SELECT t.id_epis_pn,
               t.dt_hist,
               t.id_episode,
               t.flg_status,
               t.id_pn_note_type,
               t.id_dep_clin_serv,
               t.dt_pn_date,
               t.id_prof_create,
               t.dt_create,
               t.dt_last_update,
               t.id_prof_last_update,
               t.id_prof_signoff,
               t.dt_signoff,
               t.id_prof_cancel,
               t.dt_cancel,
               t.id_cancel_reason,
               t.notes_cancel,
               t.flg_history,
               t.flg_note,
               t.id_dictation_report,
               t.max_notes,
               NULL,
               pn_addendum,
               flg_record_type,
               t.id_software,
               id_prof_reviewed,
               dt_reviewed,
               id_prof_submit,
               dt_submit
          BULK COLLECT
          INTO o_hist_info
          FROM (SELECT MAX(rn) over() max_notes, t_int.*
                  FROM (SELECT rownum rn, t_internal.*
                          FROM (SELECT *
                                  FROM (SELECT eph.id_epis_pn,
                                               eph.dt_epis_pn_hist            dt_hist,
                                               eph.id_episode,
                                               eph.flg_status,
                                               eph.id_pn_note_type,
                                               eph.id_dep_clin_serv,
                                               eph.dt_pn_date,
                                               eph.id_prof_create,
                                               eph.dt_create,
                                               eph.dt_last_update,
                                               eph.id_prof_last_update,
                                               eph.id_prof_signoff,
                                               eph.dt_signoff,
                                               eph.id_prof_cancel,
                                               eph.dt_cancel,
                                               eph.id_cancel_reason,
                                               eph.notes_cancel,
                                               pk_alert_constant.g_yes        flg_history,
                                               pk_alert_constant.g_yes        flg_note,
                                               eph.id_dictation_report,
                                               NULL                           id_epis_pn_addendum,
                                               NULL                           pn_addendum,
                                               pk_prog_notes_constants.g_note flg_record_type,
                                               eph.dt_epis_pn_hist            dt_sort,
                                               eph.id_software                id_software,
                                               eph.id_prof_reviewed,
                                               eph.dt_reviewed,
                                               eph.id_prof_submit,
                                               eph.dt_submit
                                          FROM epis_pn_hist eph
                                          JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                                column_value id_epis_pn
                                                 FROM TABLE(i_id_epis_pn) t1) tids
                                            ON tids.id_epis_pn = eph.id_epis_pn
                                        
                                         WHERE eph.flg_status IN
                                               (pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                pk_prog_notes_constants.g_epis_pn_flg_submited)
                                         ORDER BY eph.dt_epis_pn_hist DESC)
                                 WHERE rownum = 1) t_internal) t_int) t
         WHERE (i_start_record IS NULL OR (rn BETWEEN i_start_record + 1 AND (i_start_record + i_num_records + 1)));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'get_note_hist',
                                              o_error);
        
            RETURN FALSE;
    END get_note_hist;
    /*******************************************************************************************************************************************
    * get_notes_history_count          Get number of all records in history associated to a given note.
    * 
    * @param I_LANG                   Language ID for translations
    * @param I_PROF                   Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_epis_pn             Note identifier
    * @param o_num_records            The number of records in history + actual info
    * @param O_ERROR                  If an error accurs, this parameter will have information about the error
    * 
    * @value I_LANG                   {*} '1' PT {*} '2' EN {*} '3' ES {*} '4' NL {*} '5' IT {*} '6' FR {*} '11' PT-BR    
    
    * 
    * @return                        Returns TRUE if success, otherwise returns FALSE
    * 
    * @raises                         PL/SQL generic erro "OTHERS"
    *
    * @author                         Sofia Mendes
    * @version                        2.6.0.5
    * @since                          27-Jan-2011
    *******************************************************************************************************************************************/
    FUNCTION get_notes_history_count
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_hist_info tab_epis_pn_hist;
    BEGIN
        g_error := 'CALL get_notes_history.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_hist_records(i_lang         => i_lang,
                                      i_prof         => i_prof,
                                      i_flg_screen   => pk_prog_notes_constants.g_hist_screen_h,
                                      i_id_epis_pn   => table_number(i_id_epis_pn),
                                      i_start_record => NULL,
                                      i_num_records  => NULL,
                                      o_hist_info    => l_hist_info,
                                      o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_hist_info IS NOT NULL)
        THEN
            o_num_records := l_hist_info.count;
        ELSE
            o_num_records := 0;
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
                                              'get_notes_history_count',
                                              o_error);
        
            o_num_records := 0;
            RETURN FALSE;
    END get_notes_history_count;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param i_flg_report_type        Report type: C-complete; D-detailed
    * @param i_total_nr_records       Total nr of records in the grid
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_det_hist_internal
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN epis_pn.id_episode%TYPE,
        i_flg_screen        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_date_rep_config   IN sys_config.value%TYPE DEFAULT pk_prog_notes_constants.g_show_all,
        i_tab_epis_pn_hist  IN tab_epis_pn_hist,
        i_total_nr_records  IN PLS_INTEGER,
        i_num_records       IN NUMBER DEFAULT NULL,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_flg_search        IN table_varchar DEFAULT NULL,
        o_data              OUT NOCOPY pk_types.cursor_type,
        o_values            OUT NOCOPY table_clob,
        o_note_ids          OUT NOCOPY table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_NOTES_DET_HIST_INTERNAL';
        l_is_first_line BOOLEAN;
        l_detail_labels table_varchar := table_varchar();
        l_hist_labels   table_varchar := table_varchar();
        l_flg_types     table_varchar;
        l_labels        table_varchar;
        l_values        table_clob := table_clob();
        l_status        table_varchar;
    
        l_tab_hist      t_table_history := t_table_history();
        l_prev_id_note  epis_pn.id_epis_pn%TYPE;
        l_act_id_note   epis_pn.id_epis_pn%TYPE;
        l_has_addendums VARCHAR2(1 CHAR);
        l_pn_note_type  t_rec_note_type;
        l_id_software   software.id_software%TYPE;
    
    BEGIN
        o_values   := table_clob();
        o_note_ids := table_number();
    
        g_error := 'CALL get_detail_labels';
        pk_alertlog.log_debug(g_error);
        IF NOT
            get_detail_labels(i_lang => i_lang, i_prof => i_prof, o_detail_labels => l_detail_labels, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_flg_screen = pk_prog_notes_constants.g_hist_screen_h)
        THEN
            g_error := 'CALL get_history_labels';
            pk_alertlog.log_debug(g_error);
            IF NOT get_history_labels(i_lang        => i_lang,
                                      i_prof        => i_prof,
                                      o_hist_labels => l_hist_labels,
                                      o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
        g_error := 'l_tab_epis_pn_hist ' || i_tab_epis_pn_hist.count;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_tab_epis_pn_hist.count != 0
        THEN
            l_is_first_line := TRUE;
            l_prev_id_note  := NULL;
            l_act_id_note   := NULL;
            l_id_software   := NULL;
            FOR i IN i_tab_epis_pn_hist.first .. i_tab_epis_pn_hist.last
            LOOP
                --if we had already have the nr of records necessary to the current paging sheet 
                -- go ahead
                --this condition is necessary to do not show the detail record in each page
                IF (i_num_records IS NOT NULL AND i > i_num_records)
                THEN
                    EXIT;
                END IF;
            
                IF (i_tab_epis_pn_hist.exists(i + 1))
                THEN
                    l_prev_id_note := i_tab_epis_pn_hist(i + 1).id_epis_pn;
                    l_act_id_note  := i_tab_epis_pn_hist(i).id_epis_pn;
                    l_id_software  := i_tab_epis_pn_hist(i).id_software;
                END IF;
            
                IF ((l_prev_id_note <> l_act_id_note) OR l_is_first_line = TRUE)
                THEN
                    g_error := 'Call GET_NOTE_TYPE_CONFIG. l_act_id_note: ' || l_act_id_note;
                    pk_alertlog.log_debug(g_error);
                    l_pn_note_type := pk_prog_notes_utils.get_note_type_config(i_lang                => i_lang,
                                                                               i_prof                => i_prof,
                                                                               i_id_episode          => i_id_episode,
                                                                               i_id_profile_template => NULL,
                                                                               i_id_market           => NULL,
                                                                               i_id_department       => NULL,
                                                                               i_id_dep_clin_serv    => NULL,
                                                                               i_id_epis_pn          => CASE
                                                                                                            WHEN l_act_id_note IS NULL THEN
                                                                                                             CASE
                                                                                                                 WHEN i_tab_epis_pn_hist.exists(i) THEN
                                                                                                                  i_tab_epis_pn_hist(i).id_epis_pn
                                                                                                             
                                                                                                             END
                                                                                                            ELSE
                                                                                                             l_act_id_note
                                                                                                        END,
                                                                               i_id_pn_note_type     => NULL,
                                                                               i_software            => l_id_software);
                
                    --check if the note has addendums. This info is required because of the dictations: 
                    --in the dictations the note and addendum history is in the same table. So, even if we are in a actual note record, if note has addendums
                    --this corresponds to an history record in the dictations data model
                    l_has_addendums := CASE
                                           WHEN pk_prog_notes_utils.get_nr_addendums_state(i_lang,
                                                                                           i_prof,
                                                                                           l_act_id_note,
                                                                                           NULL,
                                                                                           table_varchar(pk_prog_notes_constants.g_addendum_status_d,
                                                                                                         pk_prog_notes_constants.g_addendum_status_s,
                                                                                                         pk_prog_notes_constants.g_addendum_status_c)) > 0 THEN
                                            pk_alert_constant.g_yes
                                           ELSE
                                            pk_alert_constant.g_no
                                       END;
                END IF;
            
                -- SHOW THE DETAIL BLOCK: detail screen OR the last record of the history screen
            
                --in the history with pagging it is only shown the 1st record 
                --detail in the last record of the last page
                IF ((
                   --when we are in the last page
                    (i = i_tab_epis_pn_hist.count AND i < i_total_nr_records) OR
                   --when it is the last note (all the records in the same page)
                    i = i_total_nr_records) OR
                   --in the report when changing notes
                   l_prev_id_note <> l_act_id_note)
                THEN
                    g_error := 'CALL get_note_detail';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_note_detail(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_note_info         => i_tab_epis_pn_hist(i),
                                           i_flg_screen        => i_flg_screen,
                                           i_detail_labels     => l_detail_labels,
                                           i_show_title        => i_date_rep_config,
                                           i_flg_report_type   => i_flg_report_type,
                                           i_has_addendums     => l_has_addendums,
                                           i_pn_note_type_cfg  => l_pn_note_type,
                                           i_pn_soap_block_in  => i_pn_soap_block_in,
                                           i_pn_soap_block_nin => i_pn_soap_block_nin,
                                           i_flg_search        => i_flg_search,
                                           o_flg_types         => l_flg_types,
                                           o_labels            => l_labels,
                                           o_status            => l_status,
                                           io_data             => l_values,
                                           o_error             => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                ELSE
                    --SHOWS AN HISTORY BLOCK: difference between two records
                
                    --NOTE HISTORY
                    IF (i_tab_epis_pn_hist(i + 1).flg_record_type = pk_prog_notes_constants.g_note AND i_tab_epis_pn_hist(i)
                       .flg_record_type = pk_prog_notes_constants.g_note)
                    THEN
                        --check difference between 2 note records
                        g_error := 'CALL get_note_history';
                        pk_alertlog.log_debug(g_error);
                        IF NOT get_note_history(i_lang               => i_lang,
                                                i_prof               => i_prof,
                                                i_id_episode         => i_id_episode,
                                                i_note_actual_info   => i_tab_epis_pn_hist(i),
                                                i_note_previous_info => i_tab_epis_pn_hist(i + 1),
                                                i_detail_labels      => l_detail_labels,
                                                i_hist_labels        => l_hist_labels,
                                                o_flg_types          => l_flg_types,
                                                o_labels             => l_labels,
                                                o_status             => l_status,
                                                io_data              => l_values,
                                                i_has_addendums      => l_has_addendums,
                                                i_pn_note_type_cfg   => l_pn_note_type,
                                                o_error              => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                        --ADDENDUM HISTORY
                    ELSIF (i_tab_epis_pn_hist(i)
                          .flg_record_type IN (pk_prog_notes_constants.g_epa_flg_type_addendum,
                                               pk_prog_notes_constants.g_epa_flg_type_comment))
                    THEN
                        --check difference between 2 addendum records
                        IF NOT get_addendum_history(i_lang          => i_lang,
                                                    i_prof          => i_prof,
                                                    i_id_episode    => i_id_episode,
                                                    i_actual_row    => i_tab_epis_pn_hist(i),
                                                    i_previous_row  => i_tab_epis_pn_hist(i + 1),
                                                    i_detail_labels => l_detail_labels,
                                                    i_hist_labels   => l_hist_labels,
                                                    io_data         => l_values,
                                                    o_flg_types     => l_flg_types,
                                                    o_status        => l_status,
                                                    o_labels        => l_labels,
                                                    o_error         => o_error)
                        THEN
                            RAISE g_exception;
                        END IF;
                    
                    END IF;
                
                END IF;
            
                IF (l_labels.count > 0)
                THEN
                    g_error := 'CALL get_hist_line';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_hist_line(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_epis_pn => i_tab_epis_pn_hist(i).id_epis_pn,
                                         i_flg_status => i_tab_epis_pn_hist(i).flg_status,
                                         i_date       => i_tab_epis_pn_hist(i).dt_pn_date,
                                         i_labels     => l_labels,
                                         i_flg_types  => l_flg_types,
                                         i_status     => l_status,
                                         io_tab_hist  => l_tab_hist,
                                         io_note_ids  => o_note_ids,
                                         o_error      => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                l_is_first_line := FALSE;
            
            END LOOP;
        END IF;
    
        g_error := 'OPEN O_HIST';
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        OPEN o_data FOR
            SELECT t.id_rec id_epis_pn,
                   pk_date_utils.date_send_tsz(i_lang, t.date_rec, i_prof) note_date,
                   t.flg_status note_flg_status,
                   t.tbl_labels labels,
                   t.tbl_types flg_types,
                   t.tbl_status flg_status
              FROM TABLE(l_tab_hist) t;
    
        FOR i IN 1 .. l_values.count
        LOOP
            IF instr(l_values(i), '[B|ID_TASK:') > 0
            THEN
                l_values(i) := pk_prog_notes_utils.get_bl_epis_documentation_clob(i_lang    => i_lang,
                                                                                  i_prof    => i_prof,
                                                                                  i_pn_note => l_values(i));
            END IF;
        
        END LOOP;
        o_values := l_values;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_notes_det_hist_internal;

    FUNCTION get_note_details
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_episode        IN epis_pn.id_episode%TYPE,
        i_tab_epis_pn_hist  IN tab_epis_pn_hist,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_flg_get_addendums IN VARCHAR DEFAULT pk_alert_constant.g_yes,
        i_flg_search        IN table_varchar DEFAULT NULL,
        o_details           OUT CLOB,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(30) := 'GET_NOTES_DETAILS';
        l_is_first_line BOOLEAN;
        l_hist_labels   table_varchar := table_varchar();
        l_flg_types     table_varchar;
        l_labels        table_varchar;
        l_values        table_clob := table_clob();
        l_status        table_varchar;
        l_tab_hist      t_table_history := t_table_history();
        l_prev_id_note  epis_pn.id_epis_pn%TYPE;
        l_act_id_note   epis_pn.id_epis_pn%TYPE;
        l_has_addendums VARCHAR2(1 CHAR);
        l_pn_note_type  t_rec_note_type;
        l_id_software   software.id_software%TYPE;
        l_data          pk_types.cursor_type;
        l_note_ids      table_number := table_number();
        l_details       table_table_varchar := table_table_varchar();
        l_details_label table_varchar := table_varchar();
    
    BEGIN
    
        g_error := 'CALL get_detail_labels';
        pk_alertlog.log_debug(g_error);
        IF NOT
            get_detail_labels(i_lang => i_lang, i_prof => i_prof, o_detail_labels => l_details_label, o_error => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'l_tab_epis_pn_hist ' || i_tab_epis_pn_hist.count;
        alertlog.pk_alertlog.log_info(text => g_error, object_name => g_package_name, sub_object_name => l_func_name);
        IF i_tab_epis_pn_hist.count != 0
        THEN
            l_is_first_line := TRUE;
            l_prev_id_note  := NULL;
            l_act_id_note   := NULL;
            l_id_software   := NULL;
            FOR i IN i_tab_epis_pn_hist.first .. i_tab_epis_pn_hist.last
            LOOP
            
                IF ((l_prev_id_note <> l_act_id_note) OR l_is_first_line = TRUE)
                THEN
                    g_error := 'Call GET_NOTE_TYPE_CONFIG. l_act_id_note: ' || l_act_id_note;
                    pk_alertlog.log_debug(g_error);
                    l_pn_note_type := pk_prog_notes_utils.get_note_type_config(i_lang                => i_lang,
                                                                               i_prof                => i_prof,
                                                                               i_id_episode          => i_id_episode,
                                                                               i_id_profile_template => NULL,
                                                                               i_id_market           => NULL,
                                                                               i_id_department       => NULL,
                                                                               i_id_dep_clin_serv    => NULL,
                                                                               i_id_epis_pn          => CASE
                                                                                                            WHEN l_act_id_note IS NULL THEN
                                                                                                             CASE
                                                                                                                 WHEN i_tab_epis_pn_hist.exists(i) THEN
                                                                                                                  i_tab_epis_pn_hist(i).id_epis_pn
                                                                                                             
                                                                                                             END
                                                                                                            ELSE
                                                                                                             l_act_id_note
                                                                                                        END,
                                                                               i_id_pn_note_type     => NULL,
                                                                               i_software            => l_id_software);
                
                    --check if the note has addendums. This info is required because of the dictations: 
                    --in the dictations the note and addendum history is in the same table. So, even if we are in a actual note record, if note has addendums
                    --this corresponds to an history record in the dictations data model
                    l_has_addendums := CASE
                                           WHEN pk_prog_notes_utils.get_nr_addendums_state(i_lang,
                                                                                           i_prof,
                                                                                           l_act_id_note,
                                                                                           NULL,
                                                                                           table_varchar(pk_prog_notes_constants.g_addendum_status_d,
                                                                                                         pk_prog_notes_constants.g_addendum_status_s,
                                                                                                         pk_prog_notes_constants.g_addendum_status_c)) > 0 THEN
                                            pk_alert_constant.g_yes
                                           ELSE
                                            pk_alert_constant.g_no
                                       END;
                END IF;
            
                g_error := 'CALL get_note_detail';
                pk_alertlog.log_debug(g_error);
                IF NOT get_note_detail(i_lang              => i_lang,
                                  i_prof              => i_prof,
                                  i_note_info         => i_tab_epis_pn_hist(i),
                                  i_flg_screen        => 'D',
                                  i_detail_labels     => l_details_label,
                                  i_show_title        => pk_prog_notes_constants.g_show_all,
                                  i_flg_report_type   => NULL,
                                  i_has_addendums     => CASE
                                                             WHEN i_flg_get_addendums = pk_alert_constant.g_no THEN
                                                              pk_alert_constant.g_no
                                                             ELSE
                                                              l_has_addendums
                                                         END,
                                  i_pn_note_type_cfg  => l_pn_note_type,
                                  i_pn_soap_block_in  => i_pn_soap_block_in,
                                  i_pn_soap_block_nin => i_pn_soap_block_nin,
                                  i_flg_get_addendums => i_flg_get_addendums,
                                  i_flg_search        => i_flg_search,
                                  o_flg_types         => l_flg_types,
                                  o_labels            => l_labels,
                                  o_status            => l_status,
                                  io_data             => l_values,
                                  o_error             => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                IF (l_labels.count > 0)
                THEN
                    g_error := 'CALL get_hist_line';
                    pk_alertlog.log_debug(g_error);
                    IF NOT get_hist_line(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_epis_pn => i_tab_epis_pn_hist(i).id_epis_pn,
                                         i_flg_status => i_tab_epis_pn_hist(i).flg_status,
                                         i_date       => i_tab_epis_pn_hist(i).dt_pn_date,
                                         i_labels     => l_labels,
                                         i_flg_types  => l_flg_types,
                                         i_status     => l_status,
                                         io_tab_hist  => l_tab_hist,
                                         io_note_ids  => l_note_ids,
                                         o_error      => o_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                l_is_first_line := FALSE;
            
            END LOOP;
        END IF;
    
        FOR i IN 1 .. l_values.count
        LOOP
            IF instr(l_values(i), '[B|ID_TASK:') > 0
            THEN
                l_values(i) := pk_prog_notes_utils.get_bl_epis_documentation_clob(i_lang    => i_lang,
                                                                                  i_prof    => i_prof,
                                                                                  i_pn_note => l_values(i));
            END IF;
        END LOOP;
    
        SELECT t.tbl_labels
          BULK COLLECT
          INTO l_details
          FROM TABLE(l_tab_hist) t;
    
        --Starts from the 4th position because it was decided that the review screen should only
        --present information starting from 'Date/Time'    
        FOR i IN 4 .. l_values.count - 1
        LOOP
            IF l_details(1) (i) IS NOT NULL
            THEN
                IF i = 4
                THEN
                    o_details := o_details || l_details(1) (i) || chr(10);
                ELSE
                    o_details := o_details || chr(10) || l_details(1) (i) || chr(10);
                END IF;
            
            END IF;
        
            IF l_values(i) IS NOT NULL
               AND l_values(i) <> ' '
            THEN
                IF i = 4
                THEN
                    o_details := o_details || l_values(i) || chr(10);
                ELSE
                    o_details := o_details || chr(10) || l_values(i) || chr(10);
                END IF;
            END IF;
        END LOOP;
    
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
    END get_note_details;

    /********************************************************************************************
    * Returns Number of records to display in each page. to be used on the history pagging
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode Identifier
    * @param I_AREA                  Area internal name description
    * @param O_NUM_RECORDS           number of records per page
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                         Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Sofia Mendes
    * @since                         28-Jan-2011
    * @version                       2.6.0.5
    ********************************************************************************************/
    FUNCTION get_num_page_records_hist
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_area        IN pn_area.internal_name%TYPE,
        o_num_records OUT PLS_INTEGER,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pn_area t_rec_area;
        err_general_exception EXCEPTION;
    BEGIN
        --Call pk_prog_notes_utils.tf_pn_area
        l_pn_area := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                         i_prof             => i_prof,
                                                         i_id_episode       => i_id_episode,
                                                         i_id_market        => NULL,
                                                         i_id_department    => NULL,
                                                         i_id_dep_clin_serv => NULL,
                                                         i_area             => i_area,
                                                         i_episode_software => NULL);
    
        --If nothing configured
        IF l_pn_area.id_pn_area IS NULL
        THEN
            RAISE err_general_exception;
        ELSE
            o_num_records := l_pn_area.nr_rec_page_hist;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            o_num_records := 0;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_num_records := 0;
            pk_alert_exceptions.reset_error_state;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'get_num_page_records_hist',
                                              o_error    => o_error);
            RETURN FALSE;
    END get_num_page_records_hist;

    /**
    * Returns the note detail or history.    
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure    
    * @param i_id_epis_pn             Note Id     
    * @param i_flg_screen             D- detail screen; H- History screen
    * @param i_flg_report_type        Report type: C-complete; D-detailed
    * @param i_date_rep_config        Indicates if the title should be shown. T-should be shown the title. 
    *                                                                         B-should be shown the soap block with the date
    *                                                                         A-should be shown the both things (title + date soap block)
    * @param I_START_RECORD           Paging - initial record number
    * @param I_NUM_RECORDS            Paging - number of records to display
    * @param o_data                   notes data (cursor with labels, format types, note id,...)
    * @param o_values                 Clobs values list    
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                03-Feb-2011
    */
    FUNCTION get_notes_det_history
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_ids_epis_pn       IN table_number,
        i_flg_screen        IN VARCHAR2,
        i_flg_report_type   IN VARCHAR2,
        i_date_rep_config   IN sys_config.value%TYPE DEFAULT pk_prog_notes_constants.g_show_all,
        i_start_record      IN NUMBER DEFAULT NULL,
        i_num_records       IN NUMBER DEFAULT NULL,
        i_pn_soap_block_in  IN table_number DEFAULT NULL,
        i_pn_soap_block_nin IN table_number DEFAULT NULL,
        i_flg_search        IN table_varchar DEFAULT NULL,
        o_data              OUT NOCOPY pk_types.cursor_type,
        o_values            OUT NOCOPY table_clob,
        o_note_ids          OUT NOCOPY table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'GET_NOTES_DET_HISTORY';
        l_tab_epis_pn_hist tab_epis_pn_hist;
        l_total_nr_records PLS_INTEGER;
        l_id_episode       epis_pn.id_episode%TYPE;
    BEGIN
        o_values   := table_clob();
        o_note_ids := table_number();
    
        --get the id_episode
        --all the notes belong to the same episode
        SELECT epn.id_episode
          INTO l_id_episode
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_ids_epis_pn(1);
    
        --in the history screen there is paging
        g_error := 'CALL get_notes_history.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_notes_hist_records(i_lang            => i_lang,
                                      i_prof            => i_prof,
                                      i_flg_screen      => i_flg_screen,
                                      i_id_epis_pn      => i_ids_epis_pn,
                                      i_start_record    => i_start_record,
                                      i_num_records     => i_num_records,
                                      i_flg_report_type => i_flg_report_type,
                                      o_hist_info       => l_tab_epis_pn_hist,
                                      o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_tab_epis_pn_hist IS NOT NULL AND l_tab_epis_pn_hist.exists(1))
        THEN
            l_total_nr_records := l_tab_epis_pn_hist(1).max_records_nr;
        END IF;
    
        IF (l_tab_epis_pn_hist IS NOT NULL AND l_tab_epis_pn_hist.exists(1))
        THEN
            g_error := 'CALL get_notes_det_hist_internal.';
            pk_alertlog.log_debug(g_error);
            IF NOT get_notes_det_hist_internal(i_lang              => i_lang,
                                               i_prof              => i_prof,
                                               i_id_episode        => l_id_episode,
                                               i_flg_screen        => i_flg_screen,
                                               i_flg_report_type   => i_flg_report_type,
                                               i_date_rep_config   => i_date_rep_config,
                                               i_tab_epis_pn_hist  => l_tab_epis_pn_hist,
                                               i_total_nr_records  => l_total_nr_records,
                                               i_num_records       => i_num_records,
                                               i_pn_soap_block_in  => i_pn_soap_block_in,
                                               i_pn_soap_block_nin => i_pn_soap_block_nin,
                                               i_flg_search        => i_flg_search,
                                               o_data              => o_data,
                                               o_values            => o_values,
                                               o_note_ids          => o_note_ids,
                                               o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_notes_det_history;

    FUNCTION get_note_review_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_ids_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_current_details  OUT CLOB,
        o_previous_details OUT CLOB,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name           VARCHAR2(30) := 'GET_NOTE_REVIEW_INFO';
        l_tab_epis_pn_current tab_epis_pn_hist;
        l_tab_epis_pn_hist    tab_epis_pn_hist;
        l_total_nr_records    PLS_INTEGER;
        l_id_episode          epis_pn.id_episode%TYPE;
    
    BEGIN
    
        SELECT epn.id_episode
          INTO l_id_episode
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_ids_epis_pn;
    
        --get current record
        g_error := 'CALL get_notes_history.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_note_record(i_lang         => i_lang,
                               i_prof         => i_prof,
                               i_flg_screen   => pk_prog_notes_constants.g_detail_screen_d,
                               i_id_epis_pn   => table_number(i_ids_epis_pn),
                               i_start_record => NULL,
                               i_num_records  => NULL,
                               o_hist_info    => l_tab_epis_pn_current,
                               o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_tab_epis_pn_current IS NOT NULL AND l_tab_epis_pn_current.exists(1))
        THEN
            g_error := 'CALL get_notes_det_hist_internal.';
            pk_alertlog.log_debug(g_error);
        
            IF NOT get_note_details(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_id_episode        => l_id_episode,
                                    i_tab_epis_pn_hist  => l_tab_epis_pn_current,
                                    i_pn_soap_block_in  => NULL,
                                    i_pn_soap_block_nin => NULL,
                                    i_flg_get_addendums => pk_alert_constant.g_no,
                                    o_details           => o_current_details,
                                    o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        --get previous record
        g_error := 'CALL get_notes_history.';
        pk_alertlog.log_debug(g_error);
        IF NOT get_note_hist(i_lang         => i_lang,
                             i_prof         => i_prof,
                             i_flg_screen   => pk_prog_notes_constants.g_detail_screen_d,
                             i_id_epis_pn   => table_number(i_ids_epis_pn),
                             i_start_record => NULL,
                             i_num_records  => NULL,
                             o_hist_info    => l_tab_epis_pn_hist,
                             o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_tab_epis_pn_hist IS NOT NULL AND l_tab_epis_pn_hist.exists(1))
        THEN
            g_error := 'CALL get_notes_det_hist_internal.';
            pk_alertlog.log_debug(g_error);
        
            IF NOT get_note_details(i_lang              => i_lang,
                                    i_prof              => i_prof,
                                    i_id_episode        => l_id_episode,
                                    i_tab_epis_pn_hist  => l_tab_epis_pn_hist,
                                    i_pn_soap_block_in  => NULL,
                                    i_pn_soap_block_nin => NULL,
                                    i_flg_get_addendums => pk_alert_constant.g_no,
                                    o_details           => o_previous_details,
                                    o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        IF o_previous_details IS NULL
        THEN
            o_previous_details := o_current_details;
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
    END get_note_review_info;

    /**
    * Get the notes history or detail.
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_epis_pn                Note id
    * @param   i_scope                     id_patient if i_flg_scope = 'P'
    *                                      id_visit if i_flg_scope = 'V'
    *                                      id_episode if i_flg_scope = 'E'
    * @param   i_flg_report_type           Report type: C-complete report; D-forensic report
    * @param   i_start_date                Start date to be considered
    * @param   i_end_date                  End date to be considered
    * @param   i_area                      Area name: HN: History and Physical notes; PN: Progress 
    * @param   o_data                      Data cursor. Labels, format types and status
    * @param   o_values                    Texts/contents
    * @param   o_note_ids                  Note identifiers
    * @param   o_error                     Error information
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version 2.6.0.5
    * @since   02-02-2011
    */
    FUNCTION get_rep_progress_notes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_epis_pn        IN epis_pn.id_epis_pn%TYPE,
        i_flg_scope         IN VARCHAR2,
        i_scope             IN NUMBER,
        i_flg_report_type   IN VARCHAR2,
        i_start_date        IN VARCHAR2,
        i_end_date          IN VARCHAR2,
        i_area              IN pn_area.internal_name%TYPE,
        i_pn_soap_block_in  IN table_number,
        i_pn_note_type_in   IN table_number,
        i_pn_soap_block_nin IN table_number,
        i_pn_note_type_nin  IN table_number,
        i_flg_search        IN table_varchar DEFAULT NULL,
        i_num_records       IN NUMBER DEFAULT NULL,
        o_data              OUT NOCOPY pk_types.cursor_type,
        o_values            OUT NOCOPY table_clob,
        o_note_ids          OUT NOCOPY table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REP_PROGRESS_NOTES';
        --
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_patient               patient.id_patient%TYPE;
        l_visit                 visit.id_visit%TYPE;
        l_episode               episode.id_episode%TYPE;
        l_note_ids              table_number := table_number();
        l_date_rep_config       sys_config.id_sys_config%TYPE;
        l_area_confs            t_rec_area;
        l_pn_note_type_in       table_number;
        l_pn_note_type_in_count NUMBER(12);
        --
        l_pn_note_type_nin       table_number;
        l_pn_note_type_nin_count NUMBER(12);
        --
        l_pn_soap_block_in       table_number;
        l_pn_soap_block_in_count NUMBER(12);
        --
        l_pn_soap_block_nin table_number;
    
        l_pn_soap_block_nin_count NUMBER(12);
    BEGIN
        g_report_scope := pk_alert_constant.g_yes;
    
        g_error := 'ANALYSING SCOPE TYPE: i_flg_scope: ' || i_flg_scope || '; i_scope: ' || i_scope;
        pk_alertlog.log_debug(g_error);
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_flg_scope,
                                              o_patient    => l_patient,
                                              o_visit      => l_visit,
                                              o_episode    => l_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_id_epis_pn IS NULL)
        THEN
        
            -- Convert start date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_start_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_start_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            -- Convert end date to timestamp
            g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
            pk_alertlog.log_debug(g_error);
            IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                 i_prof      => i_prof,
                                                 i_timestamp => i_end_date,
                                                 i_timezone  => NULL,
                                                 o_timestamp => l_end_date,
                                                 o_error     => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF i_pn_note_type_in IS NOT NULL
               AND i_pn_note_type_in.exists(1)
            THEN
                l_pn_note_type_in := i_pn_note_type_in;
            ELSE
                l_pn_note_type_in := table_number();
            END IF;
            l_pn_note_type_in_count := l_pn_note_type_in.count;
            --
            IF i_pn_note_type_nin IS NOT NULL
               AND i_pn_note_type_nin.exists(1)
            THEN
                l_pn_note_type_nin := i_pn_note_type_nin;
            ELSE
                l_pn_note_type_nin := table_number();
            END IF;
            l_pn_note_type_nin_count := l_pn_note_type_nin.count;
            --
            IF i_pn_soap_block_in IS NOT NULL
               AND i_pn_soap_block_in.exists(1)
            THEN
                l_pn_soap_block_in := i_pn_soap_block_in;
            ELSE
                l_pn_soap_block_in := table_number();
            END IF;
            l_pn_soap_block_in_count := l_pn_soap_block_in.count;
            --
            IF i_pn_soap_block_nin IS NOT NULL
               AND i_pn_soap_block_nin.exists(1)
            THEN
                l_pn_soap_block_nin := i_pn_soap_block_nin;
            ELSE
                l_pn_soap_block_nin := table_number();
            END IF;
            l_pn_soap_block_nin_count := l_pn_soap_block_nin.count;
        
            --get notes that match the time filters and the scope filters
            g_error := 'CALL GET note ids';
            pk_alertlog.log_debug(g_error);
            l_note_ids := tf_get_rep_progress_notes(i_id_episode              => l_episode,
                                                    i_id_patient              => l_patient,
                                                    i_id_visit                => l_visit,
                                                    i_flg_scope               => i_flg_scope,
                                                    i_area                    => i_area,
                                                    i_pn_soap_block_in_count  => l_pn_soap_block_in_count,
                                                    i_pn_soap_block_in        => l_pn_soap_block_in,
                                                    i_pn_soap_block_nin_count => l_pn_soap_block_nin_count,
                                                    i_pn_soap_block_nin       => l_pn_soap_block_nin,
                                                    i_pn_note_type_in_count   => l_pn_note_type_in_count,
                                                    i_pn_note_type_in         => l_pn_note_type_in,
                                                    i_pn_note_type_nin_count  => l_pn_note_type_nin_count,
                                                    i_pn_note_type_nin        => l_pn_note_type_nin,
                                                    i_start_date              => l_start_date,
                                                    i_end_date                => l_end_date,
                                                    i_num_records             => i_num_records);
        
        ELSE
            l_note_ids.extend(1);
            l_note_ids(1) := i_id_epis_pn;
        END IF;
    
        --get reports configs
        IF (i_flg_report_type IS NOT NULL)
        THEN
            g_error := 'CALL pk_progress_notes_upd.tf_pn_area. i_area: ' || i_area;
            pk_alertlog.log_debug(g_error);
            l_area_confs := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                                i_prof             => i_prof,
                                                                i_id_episode       => l_episode,
                                                                i_id_market        => NULL,
                                                                i_id_department    => NULL,
                                                                i_id_dep_clin_serv => NULL,
                                                                i_area             => i_area,
                                                                i_episode_software => NULL);
        
            l_date_rep_config := l_area_confs.flg_report_title_type;
        
        ELSE
            l_date_rep_config := pk_prog_notes_constants.g_show_all;
        END IF;
    
        IF (l_note_ids.exists(1))
        THEN
            g_error := 'CALL get_notes_det_history';
            pk_alertlog.log_debug(g_error);
            IF NOT get_notes_det_history(i_lang              => i_lang,
                                         i_prof              => i_prof,
                                         i_ids_epis_pn       => l_note_ids,
                                         i_flg_screen        => CASE i_flg_report_type
                                                                    WHEN pk_prog_notes_constants.g_report_complete_c THEN
                                                                     pk_prog_notes_constants.g_detail_screen_d
                                                                    WHEN pk_prog_notes_constants.g_report_detailed_d THEN
                                                                     pk_prog_notes_constants.g_hist_screen_h
                                                                END,
                                         i_flg_report_type   => i_flg_report_type,
                                         i_date_rep_config   => l_date_rep_config,
                                         i_pn_soap_block_in  => i_pn_soap_block_in,
                                         i_pn_soap_block_nin => i_pn_soap_block_nin,
                                         i_flg_search        => i_flg_search,
                                         o_data              => o_data,
                                         o_values            => o_values,
                                         o_note_ids          => o_note_ids,
                                         o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            pk_types.open_my_cursor(i_cursor => o_data);
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rep_progress_notes;

    /**************************************************************************
    * Check data block type
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_episode                Episode ID
    * @param i_id_pn_note_type        Note Type Identifier
    * @param i_id_pn_soap_block       Soap block ID
    * 
    * return                          If data block is current date type (Y) or not (N)                        
    *                                                                        
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/23                               
    **************************************************************************/
    FUNCTION check_data_block_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_episode          IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN VARCHAR2 IS
    
        l_flg_db_type table_varchar;
        l_func_name   VARCHAR2(30 CHAR) := 'CHECK_DATA_BLOCK_TYPE';
        l_editable    VARCHAR2(1 CHAR);
        l_error_out   t_error_out;
    
    BEGIN
    
        g_error := 'GET FLG_TYPE DATA BLOCKS';
        pk_alertlog.log_debug(g_error);
        l_flg_db_type := pk_progress_notes_upd.get_soap_blocks_type(i_lang             => i_lang,
                                                                    i_prof             => i_prof,
                                                                    i_episode          => i_episode,
                                                                    i_id_pn_note_type  => i_id_pn_note_type,
                                                                    i_id_pn_soap_block => i_id_pn_soap_block);
    
        -- check if there are data block with current date type
        FOR i IN 1 .. l_flg_db_type.count
        LOOP
            IF l_flg_db_type(i) = pk_prog_notes_constants.g_data_block_cdate
            THEN
                l_editable := pk_alert_constant.g_no;
            END IF;
        END LOOP;
    
        IF nvl(l_editable, pk_alert_constant.g_yes) != pk_alert_constant.g_no
        THEN
            l_editable := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_editable;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => l_error_out);
            RETURN NULL;
    END check_data_block_type;

    /**
    * Returns the note info for sign-off functionality when there is no just save screen
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              ANTONIO.NETO
    * @version                             2.6.2
    * @since                               19-Apr-2012
    */
    FUNCTION get_signoff_note_text
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_flg_edited      OUT table_varchar,
        o_pn_soap_block   OUT table_number,
        o_pn_signoff_note OUT table_clob,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_episode  epis_pn.id_episode%TYPE;
        l_data        pk_types.cursor_type;
        l_notes_texts pk_types.cursor_type;
        l_num_records PLS_INTEGER := 0;
    
        l_id_epis_pn       epis_pn.id_epis_pn%TYPE;
        l_id_pn_soap_block pn_soap_block.id_pn_soap_block%TYPE;
        l_soap_block_desc  pk_translation.t_desc_translation;
        l_soap_block_txt   CLOB;
        l_block_editable   VARCHAR2(1 CHAR);
        l_is_templ_bl      VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'GET Episode Identifier. i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.id_episode
          INTO l_id_episode
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        g_error := 'CALL get_epis_prog_notes. i_id_epis_pn: ' || i_id_epis_pn;
        pk_alertlog.log_debug(g_error);
        IF NOT get_epis_prog_notes(i_lang        => i_lang,
                                   i_prof        => i_prof,
                                   i_id_episode  => l_id_episode,
                                   i_id_epis_pn  => i_id_epis_pn,
                                   i_flg_config  => pk_prog_notes_constants.g_flg_config_signoff,
                                   o_data        => l_data,
                                   o_notes_texts => l_notes_texts,
                                   o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        o_flg_edited      := table_varchar();
        o_pn_soap_block   := table_number();
        o_pn_signoff_note := table_clob();
    
        g_error := 'FETCH CURSOR l_notes_texts';
        pk_alertlog.log_debug(g_error);
        LOOP
            FETCH l_notes_texts
                INTO l_id_epis_pn,
                     l_id_pn_soap_block,
                     l_soap_block_desc,
                     l_soap_block_txt,
                     l_block_editable,
                     l_is_templ_bl;
            EXIT WHEN l_notes_texts%NOTFOUND;
        
            --if there is text in the soap block add it
            IF l_soap_block_txt IS NOT NULL
            THEN
                l_num_records := l_num_records + 1;
            
                o_flg_edited.extend();
                o_pn_soap_block.extend();
                o_pn_signoff_note.extend();
            
                o_flg_edited(l_num_records) := pk_alert_constant.g_yes;
                o_pn_soap_block(l_num_records) := l_id_pn_soap_block;
                o_pn_signoff_note(l_num_records) := l_soap_block_txt;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_SIGNOFF_NOTE_TEXT',
                                              o_error);
        
            RETURN FALSE;
    END get_signoff_note_text;

    /**
    * Returns the last note info for edis summary grids
    *
    * @param      i_lang                   language identifier
    * @param      i_prof                   logged professional structure
    * @param      i_id_epis_pn             Note identifier
    *
    * @param      o_flg_edited             Indicate if the SOAP block was edited
    * @param      o_pn_soap_block          Soap Block array with ids
    * @param      o_pn_signoff_note        Notes array
    * @param      o_error                  error information
    *
    * @return                              false if errors occur, true otherwise
    *
    * @author                              Sofia Mendes
    * @version                             2.6.2
    * @since                               23-Jul-2013
    */
    FUNCTION get_last_note_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_software IN software.id_software%TYPE,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        o_note        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_LAST_NOTE_TEXT';
    
    BEGIN
        g_error := 'get_last_note_text. i_id_software: ' || i_id_software || ' i_id_episode: ' || i_id_episode ||
                   ' i_id_pn_area: ' || i_id_pn_area;
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        OPEN o_note FOR
            SELECT pk_utils.concat_table_clob(CAST(MULTISET
                                                   (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                     t.soap_block_desc || pk_prog_notes_constants.g_enter ||
                                                     t.soap_block_txt block_text
                                                      FROM TABLE(pk_prog_notes_grids.get_note_block_texts(i_lang,
                                                                                                          i_prof,
                                                                                                          table_number(t.id_epis_pn),
                                                                                                          table_varchar(t.flg_status),
                                                                                                          pk_prog_notes_constants.g_show_all)) t) AS
                                                   table_clob),
                                              pk_prog_notes_constants.g_enter || pk_prog_notes_constants.g_enter) note,
                   pk_prof_utils.get_name_signature(i_lang, i_prof, t.id_prof_create) name_prof,
                   pk_date_utils.dt_chr_tsz(i_lang, t.dt_pn_date, i_prof.institution, i_id_software) date_target,
                   pk_date_utils.date_char_hour_tsz(i_lang, t.dt_pn_date, i_prof.institution, i_id_software) hour_target
              FROM (SELECT row_number() over(PARTITION BY e.id_episode ORDER BY e.dt_pn_date DESC) rn, e.*
                      FROM epis_pn e
                     WHERE e.id_pn_area = i_id_pn_area
                       AND e.id_episode = i_id_episode
                       AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) t
             WHERE rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_LAST_NOTE_TEXT',
                                              o_error);
        
            RETURN FALSE;
    END get_last_note_text;

    FUNCTION get_notes_dashboard
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_title           OUT pk_types.cursor_type,
        o_note            OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_epis_pn       epis_pn.id_epis_pn%TYPE;
        l_market           market.id_market%TYPE;
        l_soap_blocks_desc table_varchar;
        l_soap_blocks_txt  table_clob;
        l_note_type_desc   pk_translation.t_desc_translation;
        l_prof_signature   CLOB;
    BEGIN
    
        BEGIN
            g_error := 'GET id_epis_pn for id_note_type: ' || i_id_pn_note_type || ' and id_episode: ' || i_id_episode;
            SELECT t.id_epis_pn, to_clob(t.prof_signature)
              INTO l_id_epis_pn, l_prof_signature
              FROM (SELECT row_number() over(PARTITION BY epn.id_episode ORDER BY epn.dt_pn_date DESC) rn,
                           epn.id_epis_pn,
                           pk_prog_notes_utils.get_signature(i_lang                => i_lang,
                                                             i_prof                => i_prof,
                                                             i_id_episode          => epn.id_episode,
                                                             i_id_prof_create      => epn.id_prof_create,
                                                             i_dt_create           => epn.dt_create,
                                                             i_id_prof_last_update => epn.id_prof_last_update,
                                                             i_dt_last_update      => epn.dt_last_update,
                                                             i_id_prof_sign_off    => epn.id_prof_signoff,
                                                             i_dt_sign_off         => epn.dt_signoff,
                                                             i_id_prof_cancel      => epn.id_prof_cancel,
                                                             i_dt_cancel           => epn.dt_cancel,
                                                             i_id_dictation_report => epn.id_dictation_report) prof_signature
                      FROM epis_pn epn
                     WHERE epn.id_pn_note_type = i_id_pn_note_type
                       AND epn.id_episode = i_id_episode
                       AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) t
             WHERE t.rn = 1;
        
            g_error          := 'CALL pk_prog_notes_utils.get_note_type_desc';
            l_note_type_desc := pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                       i_prof               => i_prof,
                                                                       i_id_pn_note_type    => i_id_pn_note_type,
                                                                       i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d);
        
        EXCEPTION
            WHEN no_data_found THEN
                l_id_epis_pn := NULL;
        END;
    
        IF l_id_epis_pn IS NOT NULL
        THEN
            g_error  := 'GET market id_institution:: ' || i_prof.institution;
            l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            g_error := 'GET soap_block_desc and soap_block_txt from id_epis_pn: ' || l_id_epis_pn;
            SELECT t.soap_block_desc, t.soap_block_txt
              BULK COLLECT
              INTO l_soap_blocks_desc, l_soap_blocks_txt
              FROM (SELECT 0 rank, l_note_type_desc soap_block_desc, l_prof_signature soap_block_txt
                      FROM dual
                    UNION ALL
                    SELECT /*+ opt_estimate(table tb rows=1) opt_estimate(table sb rows=2)*/
                     sb.rank, tb.soap_block_desc, tb.soap_block_txt
                      FROM TABLE(pk_prog_notes_grids.get_note_block_texts_unsorted(i_lang        => i_lang,
                                                                                   i_prof        => i_prof,
                                                                                   i_note_ids    => table_number(l_id_epis_pn),
                                                                                   i_note_status => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                                                                  pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                                                                                  pk_prog_notes_constants.g_epis_pn_flg_status_t),
                                                                                   i_market      => l_market,
                                                                                   --i_dblock_exclude => table_number(pk_prog_notes_constants.g_dblock_vital_sign_tb_143,pk_prog_notes_constants.g_dblock_vital_sign_22),
                                                                                   i_bold_dblock => pk_alert_constant.get_no,
                                                                                   i_note_dash   => pk_alert_constant.g_yes)) tb
                      JOIN epis_pn e
                        ON e.id_epis_pn = tb.id_note
                      LEFT JOIN dep_clin_serv dcs
                        ON dcs.id_dep_clin_serv = e.id_dep_clin_serv
                      LEFT JOIN TABLE(pk_progress_notes_upd.tf_sblock(i_prof, e.id_episode, l_market, dcs.id_department, e.id_dep_clin_serv, e.id_pn_note_type, e.id_software)) sb
                        ON sb.id_pn_soap_block = tb.id_soap_block
                       AND sb.id_dep_clin_serv IN (0, -1, e.id_dep_clin_serv)
                       AND sb.id_department IN (0, dcs.id_department)) t
             ORDER BY t.rank;
        
            g_error := 'OPEN o_title for soap_block_desc';
            OPEN o_title FOR
                SELECT column_value soap_block_desc
                  FROM TABLE(l_soap_blocks_desc);
        
            g_error := 'OPEN o_note for soap_block_txt';
            OPEN o_note FOR
                SELECT column_value soap_block_txt
                  FROM TABLE(l_soap_blocks_txt);
        
        ELSE
            pk_types.open_my_cursor(i_cursor => o_title);
            pk_types.open_my_cursor(i_cursor => o_note);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_title);
            pk_types.open_my_cursor(i_cursor => o_note);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'GET_NOTES_DASHBOARD',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_notes_dashboard;
    --
    /**
    * Returns the actions to be displayed in summary screen paging filter options.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_area                       Area name. Ex: HP - History and Physician Notes Screen
    *                                     PN - Progress Note Screen
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_pag_filter
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_area       IN pn_area.internal_name%TYPE,
        o_actions    OUT NOCOPY pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_default_action     action.internal_name%TYPE := NULL;
        l_dt_pn_date         epis_pn.dt_pn_date%TYPE;
        l_dt_temp            TIMESTAMP WITH LOCAL TIME ZONE;
        l_start_day_cur_week TIMESTAMP WITH LOCAL TIME ZONE;
        l_prev_week_start    TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate            TIMESTAMP WITH LOCAL TIME ZONE := current_timestamp;
        l_date_to_compare    TIMESTAMP WITH LOCAL TIME ZONE;
        l_area_confs         t_rec_area;
        l_all_option CONSTANT action.internal_name%TYPE := 'ALL';
        l_id_market           market.id_market%TYPE;
        l_id_episode_software software.id_software%TYPE;
        l_note_ids            table_number;
        l_id_pn_note_type     table_number;
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_ACTIONS_PAG_FILTER';
        l_pn_m046 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PN_M046');
        l_pn_m045 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PN_M045');
        l_pn_m044 sys_message.desc_message%TYPE := pk_message.get_message(i_lang, i_prof, 'PN_M044');
    BEGIN
        g_error := 'CALL pk_core.get_inst_mkt';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error := 'CALL pk_episode.get_episode_software';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        IF i_id_episode IS NOT NULL
        THEN
            IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_episode  => i_id_episode,
                                                   o_id_software => l_id_episode_software,
                                                   o_error       => o_error)
            THEN
                RAISE g_exception;
            END IF;
        END IF;
    
        g_error := 'CALL pk_prog_notes_utils.get_area_config';
        pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
        l_area_confs := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_episode       => i_id_episode,
                                                            i_id_market        => l_id_market,
                                                            i_id_department    => NULL,
                                                            i_id_dep_clin_serv => NULL,
                                                            i_area             => i_area,
                                                            i_episode_software => l_id_episode_software);
    
        l_default_action := l_all_option;
        IF (l_area_confs.summary_default_filter = pk_prog_notes_constants.g_filter_date)
        THEN
            --get the most recent note
            g_error := 'GET most recent note date. i_id_episode: ' || i_id_episode;
            pk_alertlog.log_debug(g_error);
            BEGIN
                IF 1 = 0
                THEN
                    SELECT dt_pn_date
                      INTO l_dt_pn_date
                      FROM (SELECT /*+ OPT_ESTIMATE (TABLE tconf ROWS=1)*/
                             e.dt_pn_date
                              FROM epis_pn e
                            --filter by the note types in the current area
                              JOIN TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang, i_prof, i_id_episode, NULL, l_id_market, NULL, NULL, NULL, table_varchar(i_area), NULL, pk_prog_notes_constants.g_pn_flg_scope_area_a, l_id_episode_software)) tconf
                                ON tconf.id_pn_note_type = e.id_pn_note_type
                             WHERE e.id_episode = i_id_episode
                            --AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                             ORDER BY e.dt_pn_date DESC)
                     WHERE rownum = 1;
                ELSE
                
                    SELECT MAX(ep.dt_pn_date)
                      INTO l_dt_pn_date
                      FROM epis_pn ep
                      JOIN pn_area pa
                        ON pa.id_pn_area = ep.id_pn_area
                     WHERE ep.id_episode = i_id_episode
                       AND pa.internal_name = i_area
                    --AND ep.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c
                    ;
                
                END IF;
            
            EXCEPTION
                WHEN no_data_found THEN
                    l_dt_pn_date := NULL;
            END;
        
            IF (l_dt_pn_date IS NOT NULL)
            THEN
            
                l_dt_temp := l_sysdate + numtodsinterval(-24, 'HOUR');
            
                IF (l_dt_pn_date >= l_dt_temp)
                THEN
                
                    --Last 24hours
                    l_default_action := pk_date_utils.g_scale_last24h;
                
                ELSE
                
                    l_dt_temp := l_sysdate + numtodsinterval(-48, 'HOUR');
                    IF (l_dt_pn_date >= l_dt_temp)
                    THEN
                        --Last 48hours
                        l_default_action := pk_date_utils.g_scale_last48h;
                    
                    ELSE
                    
                        l_start_day_cur_week := pk_date_utils.trunc_insttimezone(i_prof      => i_prof,
                                                                                 i_timestamp => l_sysdate,
                                                                                 i_format    => pk_date_utils.g_week_format);
                        l_start_day_cur_week := l_sysdate + numtodsinterval(-6, 'DAY');
                    
                        --**********************************************
                        IF (l_dt_pn_date >= l_start_day_cur_week)
                        THEN
                            --last_week
                            l_default_action := pk_date_utils.g_scale_lastweek;
                            -- more code commented in SVN
                        END IF;
                    END IF;
                END IF;
            
            END IF;
        END IF;
    
        IF NOT get_notes(i_lang         => i_lang,
                         i_prof         => i_prof,
                         i_id_episode   => i_id_episode,
                         i_id_patient   => NULL,
                         i_id_epis_pn   => NULL,
                         i_flg_scope    => pk_prog_notes_constants.g_flg_scope_e,
                         i_area         => i_area,
                         i_start_record => NULL,
                         i_num_records  => NULL,
                         i_search       => NULL,
                         i_filter       => 1,
                         o_note_ids     => l_note_ids,
                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT DISTINCT ep.id_pn_note_type
          BULK COLLECT
          INTO l_id_pn_note_type
          FROM epis_pn ep
         WHERE ep.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                  column_value id_epis_pn
                                   FROM TABLE(l_note_ids) t);
    
        g_error := 'GET CURSOR o_actions';
        pk_alertlog.log_debug(g_error);
        OPEN o_actions FOR
            SELECT aux.selected selected,
                   aux.desc_action desc_action,
                   aux.code_ux code_ux,
                   row_number() over(ORDER BY aux.rank, aux.desc_action) id_action,
                   aux.filter_field filter_field
              FROM (SELECT pk_prog_notes_constants.g_category_title code_ux,
                           NULL                                     filter_field,
                           l_pn_m046                                desc_action,
                           pk_alert_constant.g_no                   selected,
                           10                                       rank,
                           NULL                                     opt_rank
                      FROM dual
                    UNION ALL
                    SELECT pk_prog_notes_constants.g_category_text code_ux,
                           pk_prog_notes_constants.g_filter_all || pk_prog_notes_constants.g_sep ||
                           pk_prog_notes_constants.g_all filter_field,
                           l_pn_m045 desc_action,
                           CASE
                                WHEN l_default_action = l_all_option THEN
                                 pk_alert_constant.g_status_selected
                                ELSE
                                 pk_alert_constant.g_no
                            END selected,
                           20 rank,
                           NULL opt_rank
                      FROM dual
                    UNION ALL
                    SELECT aux2.code_ux, aux2.filter_field, aux2.desc_action, aux2.selected, aux2.rank, NULL opt_rank
                      FROM (SELECT pk_prog_notes_constants.g_category_text code_ux,
                                   CASE
                                        WHEN pnt.id_pn_note_type_group IS NULL THEN
                                         pk_prog_notes_constants.g_note_type || pk_prog_notes_constants.g_sep ||
                                         pnt.id_pn_note_type
                                        ELSE
                                         pk_prog_notes_constants.g_note_type_group || pk_prog_notes_constants.g_sep ||
                                         pnt.id_pn_note_type_group
                                    END filter_field,
                                   nvl(pk_translation.get_translation(i_lang, pntg.code_pn_note_type_group),
                                       pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type)) desc_action,
                                   pk_alert_constant.g_no selected,
                                   30 rank,
                                   NULL opt_rank,
                                   row_number() over(PARTITION BY nvl2(pnt.id_pn_note_type_group, pk_prog_notes_constants.g_note_type_group || pk_prog_notes_constants.g_sep || pnt.id_pn_note_type_group, pk_prog_notes_constants.g_note_type || pk_prog_notes_constants.g_sep || pnt.id_pn_note_type) ORDER BY pnt.id_pn_note_type) rn
                              FROM pn_note_type pnt
                              LEFT JOIN pn_note_type_group pntg
                                ON pntg.id_pn_note_type_group = pnt.id_pn_note_type_group
                             WHERE pnt.id_pn_note_type IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                            column_value
                                                             FROM TABLE(l_id_pn_note_type) t)) aux2
                     WHERE aux2.rn = 1
                    UNION ALL
                    SELECT pk_prog_notes_constants.g_category_title code_ux,
                           NULL                                     filter_field,
                           l_pn_m044                                desc_action,
                           pk_alert_constant.g_no                   selected,
                           40                                       rank,
                           NULL                                     opt_rank
                      FROM dual
                    UNION ALL
                    SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                     pk_prog_notes_constants.g_category_text code_ux,
                     pk_prog_notes_constants.g_dates || pk_prog_notes_constants.g_sep ||
                     decode(t.to_state, pk_alert_constant.g_no, 10, t.to_state) filter_field,
                     t.desc_action desc_action,
                     CASE
                         WHEN l_default_action IS NULL THEN
                          t.flg_default
                         WHEN l_default_action = t.action THEN
                          pk_alert_constant.g_status_selected
                         ELSE
                          pk_alert_constant.g_no
                     END selected,
                     50 rank,
                     a.rank opt_rank
                      FROM TABLE(pk_action.tf_get_actions_permissions(i_lang,
                                                                      i_prof,
                                                                      pk_prog_notes_constants.g_acs_pagging_filter,
                                                                      NULL)) t
                      JOIN action a
                        ON a.id_action = t.id_action) aux
             ORDER BY aux.rank, aux.opt_rank, aux.desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ACTIONS_PAG_FILTER',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_pag_filter;
    ------
    FUNCTION get_ordered_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_patient      IN patient.id_patient%TYPE,
        i_translate    IN VARCHAR2 DEFAULT NULL,
        i_viewer_area  IN VARCHAR2,
        i_episode      IN episode.id_episode%TYPE,
        o_ordered_list OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_desc_status VARCHAR2(4000) := '906362|I|||NotesWithoutSignOffIcon|||||||';
        l_task_title  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PN_M047');
    BEGIN
        g_error := 'OPEN CURSOR';
        OPEN o_ordered_list FOR
            SELECT aux.id_epis_pn id,
                   aux.descr code_description,
                   aux.descr description,
                   NULL title,
                   aux.dt_pn_date dt_req_tstz,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, aux.dt_pn_date, i_prof) dt_req,
                   NULL flg_status,
                   pk_prog_notes_constants.g_shift_summary_notes flg_type,
                   l_desc_status desc_status,
                   1 rank,
                   1 rank_order,
                   COUNT(0) over() num_count,
                   l_task_title task_title
              FROM (SELECT ep.id_epis_pn id_epis_pn,
                           pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type) descr,
                           ep.dt_pn_date dt_pn_date,
                           row_number() over(PARTITION BY pnt.id_pn_note_type ORDER BY ep.dt_pn_date DESC) rn
                      FROM epis_pn ep
                      JOIN pn_note_type pnt
                        ON pnt.id_pn_note_type = ep.id_pn_note_type
                       AND pnt.id_pn_note_type_group = pk_prog_notes_constants.g_id_pntg_shift_summary_notes
                     WHERE ep.id_episode = i_episode
                       AND ep.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_f) aux
             WHERE aux.rn = 1
             ORDER BY aux.dt_pn_date DESC;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              'GET_ORDERED_LIST',
                                              o_error);
            pk_types.open_my_cursor(o_ordered_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_ordered_list;

    FUNCTION get_ordered_list_detail
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_detail     OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_ORDERED_LIST_DETAIL';
    BEGIN
        g_error := 'OPEN o_detail FOR';
        OPEN o_detail FOR
            SELECT ep.id_epis_pn,
                   pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type) status_desc,
                   pk_prof_utils.get_name_signature(i_lang    => i_lang,
                                                    i_prof    => i_prof,
                                                    i_prof_id => nvl(ep.id_prof_last_update, ep.id_prof_create)) prof_name,
                   pk_date_utils.dt_chr_date_hour_tsz(i_lang, nvl(ep.dt_last_update, ep.dt_create), i_prof) dt_status_str,
                   NULL flg_nature_description
              FROM epis_pn ep
              JOIN pn_note_type pnt
                ON pnt.id_pn_note_type = ep.id_pn_note_type
             WHERE ep.id_epis_pn = i_id_epis_pn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(o_detail);
            RETURN FALSE;
    END get_ordered_list_detail;

    /* *
      * Returns list of summary notes with info for reports
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
    * @param i_ids_epis_pn        list of summary notes
    *
    * @param o_data                   final  cursor 
      *
      * @return                         description
      *
      * @author               Carlos FErreira
      * @version              2.7.1
      * @since                28-04-2017
      */
    FUNCTION get_notes_det_24h
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_tbl_episode IN table_number,
        i_ids_epis_pn IN table_number,
        i_start_date  TIMESTAMP WITH TIME ZONE,
        i_end_date    TIMESTAMP WITH TIME ZONE,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name        VARCHAR2(30) := 'GET_NOTES_DET_24H';
        l_tab_epis_pn_hist tab_epis_pn_hist;
        l_total_nr_records PLS_INTEGER;
        l_id_episode       epis_pn.id_episode%TYPE;
        nr_days            NUMBER;
        k_block_date CONSTANT NUMBER := pk_prog_notes_constants.g_sblock_cdate_6;
        k_block_text CONSTANT NUMBER := pk_prog_notes_constants.g_sblock_free_text_pn_17;
    
    BEGIN
    
        pk_context_api.set_parameter('i_lang', i_lang);
        pk_context_api.set_parameter('i_id_prof', i_prof.id);
        pk_context_api.set_parameter('i_id_institution', i_prof.institution);
        pk_context_api.set_parameter('i_id_software', i_prof.software);
        --pk_context_api.set_parameter('i_days_back', l_days);
    
        nr_days := round(CAST(i_end_date AS DATE) - CAST(i_start_date AS DATE));
    
        -- nr_days := extract(DAY FROM(i_end_date - i_start_date));
    
        --in the history screen there is paging
        g_error := 'CALL get_notes_history.';
        pk_alertlog.log_debug(g_error);
    
        OPEN o_data FOR
            SELECT
            --xxx.trunc_days, xxx.id_episode, xxx.dt_creation, xxx.dt_creation AT TIME ZONE 'ASIA/KUWAIT' dt_Creation_kw, xxx.dt_release,
             v.id_patient,
             xxx.rep_date,
             xxx.rep_date_9,
             xxx.dt_creation dt_alloc_1,
             xxx.dt_release dt_alloc_9,
             xfinal.rep_text,
             xfinal.dt_pn_date,
             pk_date_utils.date_send_tsz(i_lang => i_lang, i_date => xxx.rep_date, i_prof => i_prof) dt_serial,
             xxx.id_episode,
             xfinal.id_pn_note_type
              FROM (SELECT trunc_days rep_date,
                           bab.id_episode,
                           bab.dt_creation,
                           bab.dt_release,
                           trunc_days + numtodsinterval(1, 'DAY') - numtodsinterval(1, 'SECOND') rep_date_9
                      FROM (SELECT pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => i_end_date) +
                                   numtodsinterval(-level + 1, 'DAY') trunc_days
                              FROM dual
                            CONNECT BY LEVEL <= nr_days) all_days
                      LEFT JOIN (SELECT pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => ba.dt_creation) dt_creation_calc,
                                       ba.*
                                  FROM v_all_pat_bab_aux1 ba
                                 ORDER BY dt_creation DESC) bab
                    --  ON (all_days.trunc_days BETWEEN bab.dt_creation AND nvl(bab.dt_release, all_days.trunc_days))
                        ON (bab.dt_creation_calc <= all_days.trunc_days)
                       AND (bab.dt_release >= all_days.trunc_days OR bab.dt_release IS NULL)) xxx
              LEFT JOIN (SELECT xmain.texto rep_text, xmain.dt_pn_date, xmain.id_episode, xmain.id_pn_note_type
                           FROM (SELECT t.id_epis_pn,
                                        t.pn_note         texto,
                                        NULL              mydate,
                                        e.dt_pn_date,
                                        e.id_episode,
                                        e.id_pn_note_type
                                   FROM epis_pn e
                                   JOIN epis_pn_det t
                                     ON t.id_epis_pn = e.id_epis_pn
                                   JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/
                                         column_value id_epis_pn
                                          FROM TABLE(i_ids_epis_pn) t1) tids
                                     ON tids.id_epis_pn = e.id_epis_pn
                                  WHERE t.id_pn_soap_block = k_block_text
                                    AND rownum > 0) xmain
                           JOIN (SELECT t.id_epis_pn,
                                       NULL              texto,
                                       t.pn_note         mydate,
                                       e.dt_pn_date,
                                       e.id_episode,
                                       e.id_pn_note_type
                                  FROM epis_pn e
                                  JOIN epis_pn_det t
                                    ON t.id_epis_pn = e.id_epis_pn
                                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t2 ROWS=1)*/
                                        column_value id_epis_pn
                                         FROM TABLE(i_ids_epis_pn) t2) tidz
                                    ON tidz.id_epis_pn = e.id_epis_pn
                                 WHERE t.id_pn_soap_block = k_block_date
                                   AND rownum > 0) aux
                             ON aux.id_epis_pn = xmain.id_epis_pn) xfinal
                ON xfinal.id_episode = xxx.id_episode
                  --AND pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => xfinal.dt_pn_date) = xxx.rep_date
                  --AND xfinal.dt_pn_date BETWEEN xxx.dt_creation AND nvl(xxx.dt_release, xfinal.dt_pn_date)
               AND xfinal.dt_pn_date BETWEEN xxx.rep_date AND xxx.rep_date_9
              JOIN episode e
                ON e.id_episode = xxx.id_episode
              JOIN (SELECT /*+ OPT_ESTIMATE (TABLE t3 ROWS=1)*/
                     column_value id_episode
                      FROM TABLE(i_tbl_episode) t3) tbl_list
                ON tbl_list.id_episode = e.id_episode
              JOIN visit v
                ON v.id_visit = e.id_visit
             ORDER BY xxx.rep_date, e.id_episode, xfinal.dt_pn_date, xfinal.id_pn_note_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_package_owner,
                                              g_package_name,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_notes_det_24h;

    /* *
      * Returns list of summary notes id
      *
    * @param i_start_date             initial date
    * @param i_end_date               final date
    * @param i_tbl_episode            list of episode
      *
      * @return                         description
      *
      * @author               Carlos FErreira
      * @version              2.7.1
      * @since                28-04-2017
      */
    FUNCTION get_notes_id_24h
    (
        i_tbl_episode IN table_number,
        i_start_date  TIMESTAMP WITH TIME ZONE,
        i_end_date    TIMESTAMP WITH TIME ZONE
    ) RETURN table_number IS
        l_return table_number;
    
        tbl_note_type table_number := table_number(pk_prog_notes_constants.g_note_type_shif_summary_51,
                                                   pk_prog_notes_constants.g_note_type_shif_summary_52,
                                                   pk_prog_notes_constants.g_note_type_shif_summary_53);
    
    BEGIN
    
        SELECT id
          BULK COLLECT
          INTO l_return
          FROM (SELECT t_sorted.*
                  FROM (SELECT rownum rn, t_internal.dt_pn_date sortcolumn, t_internal.*
                          FROM (
                                /* END_SQL_N01  */
                                SELECT epn.id_epis_pn id, epn.flg_status, epn.dt_pn_date
                                  FROM epis_pn epn
                                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE tep ROWS=1) */
                                         column_value id_episode
                                          FROM TABLE(i_tbl_episode) tep) epi
                                    ON epi.id_episode = epn.id_episode
                                  JOIN (SELECT /*+ OPT_ESTIMATE(TABLE te ROWS=1) */
                                         column_value id_pn_note_type
                                          FROM TABLE(tbl_note_type) te) xtype
                                    ON xtype.id_pn_note_type = epn.id_pn_note_type
                                 WHERE 0 = 0
                                      --(i_start_date IS NULL OR epn.dt_pn_date >= i_start_date)
                                      --AND (i_end_date IS NULL OR epn.dt_pn_date < i_end_date)
                                   AND epn.flg_status != pk_prog_notes_constants.g_epis_pn_flg_status_c
                                /* END_SQL_N01  */
                                ) t_internal) t_sorted
                 ORDER BY t_sorted.sortcolumn DESC) xsql;
    
        RETURN l_return;
    
    END get_notes_id_24h;

    /* *
      * Returns shifts summary notes for the 24h
      *
      * @param i_lang                   language identifier
      * @param i_prof                   logged professional structure
    * @param i_start_date             initial date
    * @param i_end_date               final date
    * @param i_tbl_episode            list of episode
      *
      * @return                         description
      *
      * @author               Carlos FErreira
      * @version              2.7.1
      * @since                28-04-2017
      */
    FUNCTION get_rep_pn_24h
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_start_date  IN VARCHAR2,
        i_end_date    IN VARCHAR2,
        i_tbl_episode IN table_number,
        o_data        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30) := 'GET_REP_PN_24H';
        --
        l_start_date TIMESTAMP WITH TIME ZONE;
        l_end_date   TIMESTAMP WITH TIME ZONE;
    
        l_patient    patient.id_patient%TYPE;
        l_visit      visit.id_visit%TYPE;
        l_episode    episode.id_episode%TYPE;
        l_note_ids   table_number := table_number();
        l_area_confs t_rec_area;
    
    BEGIN
    
        --l_date_rep_config := pk_prog_notes_constants.g_show_all;
    
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_begin';
        pk_alertlog.log_debug(g_error);
        l_start_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                      i_prof      => i_prof,
                                                      i_timestamp => i_start_date,
                                                      i_timezone  => NULL);
    
        g_error := 'CALL GET_STRING_TSTZ FOR l_dt_end';
        pk_alertlog.log_debug(g_error);
        l_end_date := pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                    i_prof      => i_prof,
                                                    i_timestamp => i_end_date,
                                                    i_timezone  => NULL);
    
        --get notes that match the time filters and the scope filters
        g_error := 'CALL GET note ids';
        pk_alertlog.log_debug(g_error);
        l_note_ids := get_notes_id_24h(i_tbl_episode => i_tbl_episode,
                                       i_start_date  => l_start_date,
                                       i_end_date    => l_end_date);
    
        --        IF (l_note_ids.count > 0)        THEN
        g_error := 'CALL get_notes_det_history';
        pk_alertlog.log_debug(g_error);
        ---- other function similar but different   get_notes_det_pto
        IF NOT get_notes_det_24h(i_lang        => i_lang,
                                 i_prof        => i_prof,
                                 i_tbl_episode => i_tbl_episode,
                                 i_ids_epis_pn => l_note_ids,
                                 i_start_date  => l_start_date,
                                 i_end_date    => l_end_date,
                                 o_data        => o_data,
                                 o_error       => o_error)
        THEN
            RAISE g_exception;
        END IF;
        /*      
        ELSE
            pk_types.open_my_cursor(i_cursor => o_data);
        END IF;
        */
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_data);
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => l_func_name,
                                              o_error    => o_error);
            RETURN FALSE;
    END get_rep_pn_24h;

    FUNCTION tf_get_rep_progress_notes
    (
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_patient              IN patient.id_patient%TYPE,
        i_id_visit                IN visit.id_visit%TYPE,
        i_flg_scope               VARCHAR2,
        i_area                    IN pn_area.internal_name%TYPE,
        i_pn_soap_block_in_count  IN NUMBER,
        i_pn_soap_block_in        IN table_number,
        i_pn_soap_block_nin_count IN NUMBER,
        i_pn_soap_block_nin       IN table_number,
        i_pn_note_type_in_count   IN NUMBER,
        i_pn_note_type_in         IN table_number,
        i_pn_note_type_nin_count  IN NUMBER,
        i_pn_note_type_nin        IN table_number,
        i_start_date              IN TIMESTAMP WITH TIME ZONE,
        i_end_date                IN TIMESTAMP WITH TIME ZONE,
        i_num_records             IN NUMBER
    ) RETURN table_number IS
        l_out_rec        table_number := table_number(NULL);
        l_sql_header     VARCHAR2(1000 CHAR);
        l_sql_inner      VARCHAR2(1000 CHAR);
        l_sql_footer     VARCHAR2(1000 CHAR);
        l_sql_stmt       CLOB;
        l_curid          INTEGER;
        l_ret            INTEGER;
        l_cursor         pk_types.cursor_type;
        l_db_object_name VARCHAR2(30 CHAR) := 'TF_GET_REP_PROGRESS_NOTES';
    
    BEGIN
        l_curid := dbms_sql.open_cursor;
    
        l_sql_header := 'SELECT id
FROM (SELECT * FROM ((SELECT t_sorted.*
FROM (SELECT 1 * (current_timestamp - t_internal.dt_pn_date) AS sortcolumn, rownum rn, t_internal.*
FROM (SELECT epn.id_epis_pn id, epn.flg_status, CASE WHEN epn.flg_status = ''' ||
                        pk_prog_notes_constants.g_epis_pn_flg_status_c ||
                        ''' THEN 1 ELSE 0 END status_sort, epn.dt_pn_date FROM epis_pn epn INNER JOIN (SELECT e.id_episode FROM episode e
WHERE e.id_episode = :i_id_episode AND e.id_patient = :i_id_patient AND :i_flg_scope = ''' ||
                        pk_alert_constant.g_scope_type_episode || '''
UNION ALL SELECT e.id_episode FROM episode e WHERE e.id_patient = :i_id_patient  AND :i_flg_scope = ''' ||
                        pk_alert_constant.g_scope_type_patient || '''
UNION ALL SELECT e.id_episode  FROM episode e  WHERE e.id_visit = :i_id_visit  AND e.id_patient = :i_id_patient AND :i_flg_scope = ''' ||
                        pk_alert_constant.g_scope_type_visit ||
                        ''') epi
ON epi.id_episode = epn.id_episode INNER JOIN pn_area pna ON epn.id_pn_area = pna.id_pn_area WHERE pna.internal_name = :i_area';
    
        --i_pn_soap_block_in_count
        IF i_pn_soap_block_in_count > 0
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND EXISTS (SELECT 1 FROM epis_pn_det epd WHERE epd.id_epis_pn = epn.id_epis_pn
AND epd.id_pn_soap_block IN (SELECT /*+ OPT_ESTIMATE (TABLE t1 ROWS=1)*/ column_value FROM TABLE(:i_pn_soap_block_in) t1))';
        END IF;
    
        --i_pn_soap_block_nin_count
        IF i_pn_soap_block_nin_count > 0
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND EXISTS (SELECT 1 FROM epis_pn_det epd WHERE epd.id_epis_pn = epn.id_epis_pn
AND epd.id_pn_soap_block NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t2 ROWS=1)*/ column_value FROM TABLE(:i_pn_soap_block_nin) t2))';
        END IF;
    
        --i_pn_note_type_in_count
        IF i_pn_note_type_in_count > 0
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND epn.id_pn_note_type IN (SELECT /*+ OPT_ESTIMATE (TABLE t3 ROWS=1)*/ column_value  FROM TABLE(:i_pn_note_type_in) t3)';
        END IF;
    
        --i_pn_note_type_nin_count
        IF i_pn_note_type_nin_count > 0
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND epn.id_pn_note_type NOT IN (SELECT /*+ OPT_ESTIMATE (TABLE t4 ROWS=1)*/ column_value FROM TABLE(:i_pn_note_type_nin) t4)';
        END IF;
    
        --i_start_date
        IF i_start_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner ||
                           ' AND epn.dt_pn_date >= cast(:i_start_date as TIMESTAMP WITH LOCAL TIME ZONE) ';
        END IF;
    
        --i_end_date
        IF i_end_date IS NOT NULL
        THEN
            l_sql_inner := l_sql_inner || ' AND epn.dt_pn_date < cast(:i_end_date as TIMESTAMP WITH LOCAL TIME ZONE) ';
        END IF;
    
        l_sql_footer := '  ) t_internal
ORDER BY status_sort, sortcolumn) t_sorted) t))';
    
        IF i_num_records IS NOT NULL
        THEN
            l_sql_footer := l_sql_footer || ' WHERE rownum <= :i_num_records';
        END IF;
    
        l_sql_stmt := to_clob(l_sql_header || l_sql_inner || l_sql_footer);
        --dbms_output.put_line(dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        pk_alertlog.log_debug(object_name     => g_package_name,
                              sub_object_name => l_db_object_name,
                              text            => dbms_lob.substr(l_sql_stmt, 4000, 1));
    
        dbms_sql.parse(l_curid, l_sql_stmt, dbms_sql.native);
    
        dbms_sql.bind_variable(l_curid, 'i_id_patient', i_id_patient);
        dbms_sql.bind_variable(l_curid, 'i_id_episode', i_id_episode);
        dbms_sql.bind_variable(l_curid, 'i_id_visit', i_id_visit);
        dbms_sql.bind_variable(l_curid, 'i_flg_scope', i_flg_scope);
        dbms_sql.bind_variable(l_curid, 'i_area', i_area);
    
        IF i_pn_soap_block_in_count > 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_pn_soap_block_in', i_pn_soap_block_in);
        END IF;
    
        IF i_pn_soap_block_nin_count > 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_pn_soap_block_nin', i_pn_soap_block_nin);
        END IF;
    
        IF i_pn_note_type_in_count > 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_pn_note_type_in', i_pn_note_type_in);
        END IF;
    
        IF i_pn_note_type_nin_count > 0
        THEN
            dbms_sql.bind_variable(l_curid, 'i_pn_note_type_nin', i_pn_note_type_nin);
        END IF;
    
        IF i_start_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_start_date', i_start_date);
        END IF;
    
        IF i_end_date IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_end_date', i_end_date);
        END IF;
    
        IF i_num_records IS NOT NULL
        THEN
            dbms_sql.bind_variable(l_curid, 'i_num_records', i_num_records);
        END IF;
    
        l_ret := dbms_sql.execute(l_curid);
    
        l_cursor := dbms_sql.to_refcursor(l_curid);
    
        FETCH l_cursor BULK COLLECT
            INTO l_out_rec;
    
        RETURN l_out_rec;
    END tf_get_rep_progress_notes;

BEGIN
    -- Log initialization.
    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_prog_notes_grids;
/
