/*-- Last Change Revision: $Rev: 2054563 $*/
/*-- Last Change by: $Author: elisabete.bugalho $*/
/*-- Date of last change: $Date: 2023-01-13 15:42:19 +0000 (sex, 13 jan 2023) $*/

CREATE OR REPLACE PACKAGE BODY pk_prog_notes_utils IS

    -- Private type declarations

    -- Private constant declarations

    -- Private variable declarations

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);

    k_yes           CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no            CONSTANT VARCHAR2(0010 CHAR) := 'N';
    k_transf_type   CONSTANT VARCHAR2(0010 CHAR) := 'O';
    k_flg_review    CONSTANT VARCHAR2(0010 CHAR) := 'R';
    k_flg_submit    CONSTANT VARCHAR2(0010 CHAR) := 'S';
    k_flg_no_submit CONSTANT VARCHAR2(0010 CHAR) := k_no;

    -- Function and procedure implementations

    FUNCTION get_flg_cancel
    (
        i_lang       IN NUMBER,
        i_prof       IN profissional,
        i_pn_status  IN VARCHAR2,
        i_flg_cancel IN VARCHAR2,
        i_flg_submit VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_return          VARCHAR2(0010 CHAR) := k_no;
        l_flg_submit_mode VARCHAR2(0010 CHAR);
        k_pn_flg_draft CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_d;
    BEGIN
    
        IF i_flg_cancel = k_yes
        THEN
            IF i_flg_submit = pk_alert_constant.g_yes
            THEN
                l_flg_submit_mode := get_flg_submit_mode(i_prof => i_prof);
            END IF;
            IF l_flg_submit_mode IN (k_flg_review, k_flg_submit)
            THEN
            
                l_return := k_yes;
                IF i_pn_status != k_pn_flg_draft
                THEN
                    l_return := k_no;
                END IF;
            ELSIF i_pn_status = pk_prog_notes_constants.g_epis_pn_flg_status_s
            THEN
                l_return := k_no;
            ELSIF i_pn_status != pk_prog_notes_constants.g_epis_pn_flg_status_c
            THEN
                l_return := i_flg_cancel;
            
            END IF;
        
        END IF;
    
        RETURN l_return;
    
    END get_flg_cancel;

    --------
    FUNCTION get_flg_ok
    (
        i_lang      IN NUMBER,
        i_prof      IN profissional,
        i_pn_status IN VARCHAR2,
        i_flg_ok    IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return          VARCHAR2(0010 CHAR);
        l_flg_submit_mode VARCHAR2(0010 CHAR);
        --k_pn_flg_submit      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_submited;
        --k_pn_flg_draftsubmit CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_draftsubmit;
        k_pn_flg_draft  CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_d;
        k_pn_flg_cancel CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_c;
        --k_pn_flg_4_review    CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
    
    BEGIN
    
        l_flg_submit_mode := get_flg_submit_mode(i_prof => i_prof);
    
        CASE l_flg_submit_mode
            WHEN k_flg_review THEN
            
                l_return := k_yes;
                IF i_pn_status != k_pn_flg_draft
                THEN
                    l_return := k_no;
                END IF;
            
            WHEN k_flg_submit THEN
            
                l_return := k_yes;
                IF i_pn_status = k_pn_flg_cancel
                THEN
                    l_return := k_no;
                END IF;
            
            ELSE
                l_return := i_flg_ok;
            
        END CASE;
    
        RETURN l_return;
    
    END get_flg_ok;

    /**
    * Returns the number of notes in a given status associated to an episode created by a given profesional.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_episode               episode identifier
    * @param i_flg_statuses          List of Notes statuses. D-draft; S-Signed-off; M-migrated; C-Cancelled; F-Finalized
    * @param i_note_types             Note types
    *
    * @return               nr of notes
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_nr_notes_state
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_flg_statuses IN table_varchar,
        i_note_types   IN table_number
    ) RETURN PLS_INTEGER IS
        l_nr_notes PLS_INTEGER := 0;
        l_error    t_error_out;
    BEGIN
        g_error := 'GET nr of notes: i_id_episode: ' || i_id_episode;
        SELECT COUNT(1)
          INTO l_nr_notes
          FROM epis_pn epn
         WHERE epn.id_episode = i_id_episode
           AND epn.id_pn_note_type IN (SELECT /*+ OPT_ESTIMATE (TABLE tt ROWS=1)*/
                                        column_value
                                         FROM TABLE(i_note_types) tt)
           AND epn.flg_status IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                   column_value
                                    FROM TABLE(i_flg_statuses) t);
    
        RETURN l_nr_notes;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NR_NOTES_STATE',
                                              l_error);
        
            RETURN 0;
    END get_nr_notes_state;

    /**
    * Returns the number of addendums in a given status associated to a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            Note identifier
    * @param i_id_prof_create        Professional that created the addendums
    * @param i_flg_statuses          List of addendums statuses. D-draft; S-Signed-off; C-Cancelled; F-Finalized    
    *
    * @return               Nr of addendums associated to the given note
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_nr_addendums_state
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn     IN epis_pn.id_epis_pn%TYPE,
        i_id_prof_create IN epis_pn.id_prof_create%TYPE,
        i_flg_statuses   IN table_varchar
    ) RETURN PLS_INTEGER IS
        l_nr_addendums PLS_INTEGER;
        l_error        t_error_out;
    BEGIN
        g_error := 'GET nr of adendums: i_id_epis_pn: ' || i_id_epis_pn || ' ; i_id_prof_create: ' || i_id_prof_create;
        SELECT COUNT(1)
          INTO l_nr_addendums
          FROM epis_pn_addendum epa
         WHERE epa.id_epis_pn = i_id_epis_pn
           AND (i_id_prof_create IS NULL OR epa.id_professional = i_id_prof_create)
           AND epa.flg_type = pk_prog_notes_constants.g_epa_flg_type_addendum
           AND epa.flg_status IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                   column_value
                                    FROM TABLE(i_flg_statuses) t);
    
        RETURN l_nr_addendums;
    
    EXCEPTION
        WHEN OTHERS THEN
            l_nr_addendums := 0;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NR_ADDENDUMS_STATE',
                                              l_error);
        
            RETURN l_nr_addendums;
    END get_nr_addendums_state;

    /**
    * Gets the professional that created a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier    
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_note_prof
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_prof_create%TYPE IS
        l_id_prof epis_pn.id_prof_create%TYPE;
        l_error   t_error_out;
    BEGIN
        g_error := 'GET id_prof_create: i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.id_prof_create
          INTO l_id_prof
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        RETURN l_id_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_PROF',
                                              l_error);
        
            RETURN NULL;
    END get_note_prof;

    /**
    * Gets the professional that created the addendum.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_addendum      Addendum identifier    
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_addendum_prof
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE
    ) RETURN epis_pn_addendum.id_professional%TYPE IS
        l_id_prof epis_pn.id_prof_create%TYPE;
        l_error   t_error_out;
    BEGIN
        g_error := 'GET id_prof_create: i_id_epis_addendum: ' || i_id_epis_addendum;
        SELECT epa.id_professional
          INTO l_id_prof
          FROM epis_pn_addendum epa
         WHERE epa.id_epis_pn_addendum = i_id_epis_addendum;
    
        RETURN l_id_prof;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ADDENDUM_PROF',
                                              l_error);
        
            RETURN NULL;
    END get_addendum_prof;

    /**
    * Get addendum for the sign-off screen
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_pn_addendum   Addendum ID
    *
    * @param   o_addendum           Addendum text
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   11-02-2011
    */
    FUNCTION get_pn_addendum
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_epis_pn_addendum IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_addendum         OUT NOCOPY pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Get addendum text for id_epis_pn_addendum = ' || to_char(i_epis_pn_addendum);
        OPEN o_addendum FOR
            SELECT pk_message.get_message(i_lang, 'PN_T007') title, pn_addendum
              FROM epis_pn_addendum
             WHERE id_epis_pn_addendum = i_epis_pn_addendum;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(i_cursor => o_addendum);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DATA_IMPORT',
                                              o_error);
        
            RETURN FALSE;
    END get_pn_addendum;

    /**
    * Gets the episode associated to the note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier    
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_episode
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_episode%TYPE IS
        l_id_episode epis_pn.id_episode%TYPE;
        l_error      t_error_out;
    BEGIN
        g_error := 'GET id_episode: i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.id_episode
          INTO l_id_episode
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        RETURN l_id_episode;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_EPISODE',
                                              l_error);
        
            RETURN NULL;
    END get_note_episode;

    /**************************************************************************
    * Get the date in wich the note was associated to the task.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_task                Task Id   
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_dt_creation            Creation date    
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          19-Mai-2011                                
    **************************************************************************/
    FUNCTION get_pn_insertion_date
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_task     IN epis_pn_det_task.id_task%TYPE,
        i_id_epis_pn  IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_dt_creation OUT NOCOPY epis_pn_det_task.dt_last_update%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET pn task insertion date from definitive table. i_id_task: ' || i_id_task || ', i_id_epis_pn: ' ||
                   i_id_epis_pn;
    
        BEGIN
            SELECT e.dt_last_update
              INTO o_dt_creation
              FROM epis_pn_det_task e
             INNER JOIN epis_pn_det epnd
                ON e.id_epis_pn_det = epnd.id_epis_pn_det
             WHERE e.id_task = i_id_task
               AND (epnd.id_epis_pn = i_id_epis_pn OR i_id_epis_pn IS NULL)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_dt_creation := NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PN_INSERTION_DATE',
                                              o_error);
            RETURN FALSE;
    END get_pn_insertion_date;

    /**
    * Get the progress notes's id_dep_clin_serv
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_epis_pn            Progress Note ID
    * @param   o_dep_clin_serv      Progress Note id_dep_clin_serv
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    *
    * @author  Rui Batista
    * @version 2.6.0.5
    * @since   21-02-2011
    */
    FUNCTION get_pn_dep_clin_serv
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_dep_clin_serv OUT NOCOPY dep_clin_serv.id_dep_clin_serv%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_PN_DEP_CLIN_SERV';
    BEGIN
        g_error := 'GET NOTE DEP_CLIN_SERV i_epis_pn: ' || i_epis_pn;
    
        SELECT id_dep_clin_serv
          INTO o_dep_clin_serv
          FROM epis_pn
         WHERE id_epis_pn = i_epis_pn;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'Could not determine the PN id_dep_clin_serv. id_epis_pn = ' || i_epis_pn;
            alertlog.pk_alertlog.log_debug(text            => g_error,
                                           object_name     => g_package,
                                           sub_object_name => 'GET_PN_DEP_CLIN_SERV');
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PN_DEP_CLIN_SERV',
                                              o_error);
        
            RETURN FALSE;
        
    END get_pn_dep_clin_serv;

    /**
    * Get the Progress Note status
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_epis_pn      Progress Notes ID
    *
    * @return  Varchar2        Progress Note status
    *
    * @author  RUI.BATISTA
    * @version <2.6.0.5>
    * @since   31-01-2011
    */
    FUNCTION get_pn_status
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2 IS
    
        l_pn_status epis_pn.flg_status%TYPE;
        l_error     t_error_out;
    
    BEGIN
    
        SELECT flg_status
          INTO l_pn_status
          FROM epis_pn
         WHERE id_epis_pn = i_epis_pn;
    
        RETURN l_pn_status;
    
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'Progress Note not found. ID_EPIS_PN: ' || i_epis_pn;
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PN_STATUS',
                                              o_error    => l_error);
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_PN_STATUS',
                                              o_error    => l_error);
            RETURN NULL;
    END get_pn_status;

    /**
    * Get just save status
    *
    * @param   i_lang             Professional preferred language
    * @param   i_prof             Professional identification and its context (institution and software)
    * @param   i_epis_pn          Progress note identifier
    *
    * @param   i_flg_just_save    Indicate if there is a just saved record (Y/N)
    * @param   o_error            Error information
    *
    * @return  Boolean
    *
    * @author  RUI.SPRATLEY
    * @version 2.6.0.5
    * @since   22-02-2011
    */
    FUNCTION get_flg_just_save
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_flg_just_save OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        CURSOR c_just_save IS
            SELECT COUNT(1)
              FROM epis_pn_signoff eps
             WHERE eps.id_epis_pn = i_epis_pn;
    
        l_counter PLS_INTEGER;
    BEGIN
        OPEN c_just_save;
        FETCH c_just_save
            INTO l_counter;
        CLOSE c_just_save;
    
        IF l_counter > 0
        THEN
            o_flg_just_save := 'Y';
        ELSE
            o_flg_just_save := 'N';
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
                                              i_function => 'get_flg_just_save',
                                              o_error    => o_error);
            o_flg_just_save := 'N';
            RETURN FALSE;
    END get_flg_just_save;

    /**
    * Gets the id_dictation report associated to a note.
    *
    * @param i_lang                  language identifier
    * @param i_prof                  logged professional structure
    * @param i_id_epis_pn            note identifier    
    *
    * @return               professional id
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_dictation_report
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.id_dictation_report%TYPE IS
        l_id_dictation_report epis_pn.id_dictation_report%TYPE;
        l_error               t_error_out;
    BEGIN
        g_error := 'GET id_dictation_report: i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.id_dictation_report
          INTO l_id_dictation_report
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        RETURN l_id_dictation_report;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_dictation_report',
                                              l_error);
        
            RETURN NULL;
    END get_dictation_report;

    /**
    * Counts the number of child records a parent has
    *
    * @param   i_pn_soap_block    Soap Block id
    * @param   i_pn_data_block    Data Block id
    * @param   i_data_block       Collection of import data
    * @param   i_data             Collection of work data
    *
    * @return                     Number of child records
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                14-02-2011
    */

    FUNCTION count_child
    (
        i_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_pn_data_block IN epis_pn_det.id_pn_data_block%TYPE, --parent
        i_data_block    IN t_coll_data_blocks,
        i_data          IN t_coll_pn_work_data
    ) RETURN PLS_INTEGER IS
        l_counter PLS_INTEGER;
    BEGIN
        g_error := 'Count child records';
    
        SELECT COUNT(1)
          INTO l_counter
          FROM TABLE(i_data) rb
         WHERE (rb.id_pn_soap_block, rb.id_pn_data_block) IN
               (SELECT imp.block_id id_pn_soap_block, imp.id_pn_data_block
                  FROM TABLE(i_data_block) imp
                 START WITH imp.id_pn_data_block = i_pn_data_block
                CONNECT BY PRIOR imp.id_pn_data_block = imp.id_pndb_parent)
           AND rb.flg_parent_imported = pk_alert_constant.g_yes
           AND rb.id_pn_soap_block = i_pn_soap_block;
    
        RETURN l_counter;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(text => g_error, object_name => g_package, sub_object_name => 'count_child');
            RETURN 0;
    END count_child;

    /**
    * Counts the number of child records a parent has (a import structrure parent)
    *
    * @param   i_pn_soap_block           Soap Block id
    * @param   i_pn_data_block           Data Block id    
    * @param   i_data_block              Collection of import data
    * @param   i_data                    Collection of work data
    *
    * @return                     Number of child records
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-01-2012
    */

    FUNCTION count_child_struct
    (
        i_pn_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_pn_data_block IN epis_pn_det.id_pn_data_block%TYPE, --parent        
        i_data_block    IN t_coll_data_blocks,
        i_data          IN t_coll_pn_work_data
    ) RETURN PLS_INTEGER IS
        l_counter PLS_INTEGER;
    BEGIN
        g_error := 'Count child records';
    
        SELECT COUNT(1)
          INTO l_counter
          FROM TABLE(i_data) rb
         WHERE (rb.id_pn_soap_block, rb.id_parent_struct_imp) IN
               (SELECT imp.block_id id_pn_soap_block, imp.id_pn_data_block
                  FROM TABLE(i_data_block) imp
                 WHERE imp.block_id = i_pn_soap_block
                 START WITH imp.id_pn_data_block = i_pn_data_block
                CONNECT BY PRIOR imp.id_pn_data_block = imp.id_pndb_parent);
    
        RETURN l_counter;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END count_child_struct;

    /**
    * Counts the number of epis_pn_det_task records
    *
    * @param   i_epis_pn          Epis Pn Id
    * @param   i_soap_block       Soap block id
    * @param   i_data_block       Data block id
    *
    * @return                     Epis_pn_det id
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                23-02-2011
    */

    FUNCTION get_epispn_det_by_block
    (
        i_epis_pn    IN epis_pn_det.id_epis_pn%TYPE,
        i_soap_block IN epis_pn_det.id_pn_soap_block%TYPE,
        i_data_block IN epis_pn_det.id_pn_data_block%TYPE
    ) RETURN NUMBER IS
    
        l_epis_pn_det epis_pn_det.id_epis_pn_det%TYPE;
    BEGIN
        g_error := 'Get value';
        BEGIN
            SELECT id_epis_pn_det
              INTO l_epis_pn_det
              FROM epis_pn_det ed
             WHERE ed.id_epis_pn = i_epis_pn
               AND ed.id_pn_soap_block = i_soap_block
               AND ed.id_pn_data_block = i_data_block
               AND ed.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                NULL;
        END;
    
        RETURN l_epis_pn_det;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alertlog.log_debug(text            => g_error,
                                  object_name     => g_package,
                                  sub_object_name => 'GET_EPISPN_DET_BY_BLOCK');
            RETURN NULL;
    END get_epispn_det_by_block;

    /**
    * Counts the number of epis_pn_det_task records
    *
    * @param   i_epis_pn_det      Epis Pn Det Id
    * @param   i_flg_status       Flg_status that should be considered
    *
    * @return                     Number of child records
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                23-02-2011
    */

    FUNCTION count_tasks
    (
        i_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_status  IN table_varchar
    ) RETURN PLS_INTEGER IS
        l_counter PLS_INTEGER;
    BEGIN
        g_error := 'Count nr of tasks';
    
        SELECT COUNT(1)
          INTO l_counter
          FROM epis_pn_det_task edt
         WHERE edt.id_epis_pn_det = i_epis_pn_det
           AND edt.flg_status IN (SELECT /*+ OPT_ESTIMATE (TABLE st ROWS=1)*/
                                   column_value
                                    FROM TABLE(i_flg_status) st);
    
        RETURN l_counter;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END count_tasks;

    /********************************************************************************************
    * Returns if the import should be available according to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier 
    * @param I_ID_EPISODE            Episode Identifier 
    * @param O_IMPORT_AVAIL          Y- the import is availabel. N-otherwise
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Ant? Neto
    * @since                         27-Jul-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_import_avail_config
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_import_avail    OUT NOCOPY pn_note_type_soft_inst.flg_import_first%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        err_general_exception EXCEPTION;
        l_pn_note_type t_rec_note_type;
    BEGIN
        g_error        := 'Call PK_PROG_NOTES_CORE.GET_NOTE_TYPE_CONFIG';
        l_pn_note_type := get_note_type_config(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_episode          => i_id_episode,
                                               i_id_profile_template => NULL,
                                               i_id_market           => NULL,
                                               i_id_department       => NULL,
                                               i_id_dep_clin_serv    => NULL,
                                               i_id_epis_pn          => NULL,
                                               i_id_pn_note_type     => i_id_pn_note_type,
                                               i_software            => NULL);
    
        --If nothing configured
        IF l_pn_note_type.id_pn_note_type IS NULL
        THEN
            o_import_avail := pk_alert_constant.g_no;
        ELSE
            o_import_avail := l_pn_note_type.flg_import_first;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_IMPORT_AVAIL_CONFIG',
                                              o_error);
            o_import_avail := pk_alert_constant.g_no;
            RETURN FALSE;
    END get_import_avail_config;

    /********************************************************************************************
    * Checks if the note is editable.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode            Episode ID
    * @param i_id_epis_pn            Note ID 
    * @param i_editable_nr_min       Nr of minutes to edit a note 
    * @param i_flg_edit_after_disch  Y-It is allowed to edit the note after the discharge. N-otherwise    
    * @param i_flg_synchronized      Y-Single page. N-single note
    * @param i_id_pn_note_type       Note type ID
    * @param i_flg_edit_only_last    Y-only the last active note is editable. N-otherwise
    *
    * @return                        Y-It is allowed to edit the note. N-It is not allowed to edit.
    *                                T-It is not allowed to edit except the free text records.
    *
    * @author                        Sofia Mendes
    * @since                         16-May-2012
    * @version                       2.6.2.1
    ********************************************************************************************/
    FUNCTION get_flg_editable
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_edit_after_disch IN pn_note_type_mkt.flg_edit_after_disch%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_edit_only_last   IN pn_note_type_mkt.flg_edit_only_last%TYPE,
        i_flg_edit_condition   IN pn_note_type_mkt.flg_edit_condition%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_error            t_error_out;
        l_editable_by_time PLS_INTEGER;
        l_editable         VARCHAR2(1 CHAR) := NULL;
    
        l_id_epis_pn epis_pn.id_epis_pn%TYPE;
        l_note_date  epis_pn.dt_create%TYPE;
        l_pn_date    epis_pn.dt_pn_date%TYPE;
    
        l_greater_than VARCHAR(001 CHAR) := 'G';
        l_is_dicharged VARCHAR2(1) := pk_alert_constant.g_no;
    BEGIN
        g_error            := 'CALL pk_prog_notes_utils.check_time_to_edit. i_id_epis_pn: ' || i_id_epis_pn ||
                              ' i_editable_nr_min: ' || i_editable_nr_min;
        l_editable_by_time := pk_prog_notes_utils.check_time_to_edit(i_lang             => i_lang,
                                                                     i_prof             => i_prof,
                                                                     i_id_episode       => i_id_episode,
                                                                     i_id_epis_pn       => i_id_epis_pn,
                                                                     i_editable_nr_min  => i_editable_nr_min,
                                                                     i_flg_synchronized => i_flg_synchronized,
                                                                     i_id_pn_note_type  => i_id_pn_note_type);
    
        --when it is only possible to edit the last note
        IF (i_flg_edit_only_last = pk_alert_constant.g_yes AND l_editable_by_time = 1)
        THEN
            g_error := 'CALL pk_prog_notes_utils.get_last_note_date. i_id_pn_note_type: ' || i_id_pn_note_type ||
                       ' i_id_episode: ' || i_id_episode;
            IF NOT pk_prog_notes_utils.get_last_note_date(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_id_episode,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          io_id_epis_pn     => l_id_epis_pn,
                                                          o_note_date       => l_note_date,
                                                          o_pn_date         => l_pn_date,
                                                          o_error           => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (l_id_epis_pn <> i_id_epis_pn)
            THEN
                l_editable := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        IF (l_editable <> pk_alert_constant.get_no OR l_editable IS NULL)
        THEN
            IF (l_editable_by_time = 1)
            THEN
                IF i_flg_edit_after_disch = pk_alert_constant.g_no
                THEN
                    g_error := 'CALL pk_discharge.get_epis_discharge_state';
                    IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_episode   => i_id_episode,
                                                                 o_discharge => l_is_dicharged,
                                                                 o_error     => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
                g_error    := 'CALL get_discharge_note_status. i_flg_edit_after_disch: ' || i_flg_edit_after_disch ||
                              ' l_is_dicharged: ' || l_is_dicharged;
                l_editable := get_discharge_note_status(i_flg_edit_after_disch, l_is_dicharged);
            ELSE
                l_editable := pk_prog_notes_constants.g_not_editable_by_time;
            END IF;
        END IF;
    
        -- Check note is future note, if it is future note, it will not editable.
        IF (i_flg_edit_condition = pk_prog_notes_constants.g_flg_edit_util_now)
        THEN
            l_id_epis_pn := i_id_epis_pn;
            IF NOT pk_prog_notes_utils.get_last_note_date(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_id_episode,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          io_id_epis_pn     => l_id_epis_pn,
                                                          o_note_date       => l_note_date,
                                                          o_pn_date         => l_pn_date,
                                                          o_error           => l_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF pk_date_utils.compare_dates_tsz(i_prof => i_prof, i_date1 => l_pn_date, i_date2 => current_timestamp) =
               l_greater_than
            THEN
                l_editable := pk_alert_constant.g_no;
            ELSE
                l_editable := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_editable;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FLG_EDITABLE',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END get_flg_editable;

    /********************************************************************************************
    * Returns the list of configs to the given note type.
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_NOTE_TYPE       Note Type Identifier 
    * @param I_ID_EPISODE            Episode Identifier 
    * @param i_id_epis_pn            Note Identifier
    * @param O_CONFIGS               Cursor with all the configs for the note type
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        Returns TRUE if success, otherwise returns FALSE
    *
    * @author                        Ant? Neto
    * @since                         03-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_note_type_configs
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        o_configs         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        err_general_exception EXCEPTION;
        l_pn_note_type t_rec_note_type;
        l_ready_only   VARCHAR2(1 CHAR);
        l_flg_submit   VARCHAR2(0010 CHAR);
        l_id_prof      sys_config.value%TYPE := pk_sysconfig.get_config('ID_PROF_UPGRADE', i_prof);
        -- ***************************************
        FUNCTION process_submit
        (
            i_prof       IN profissional,
            i_id_episode IN NUMBER,
            i_flg_submit IN VARCHAR2
        ) RETURN VARCHAR2 IS
            l_return VARCHAR2(0010 CHAR);
        BEGIN
        
            l_return := k_no;
            IF i_flg_submit = k_yes
            THEN
            
                l_return := is_prof_attending_phy(i_prof => i_prof, i_episode => i_id_episode);
            
            END IF;
        
            RETURN l_return;
        
        END process_submit;
    
    BEGIN
        g_error      := 'GET READY ONLY PROFILE';
        l_ready_only := pk_prof_utils.check_has_functionality(i_lang        => i_lang,
                                                              i_prof        => i_prof,
                                                              i_intern_name => 'READ ONLY PROFILE');
    
        g_error        := 'Call GET_NOTE_TYPE_CONFIG';
        l_pn_note_type := get_note_type_config(i_lang                => i_lang,
                                               i_prof                => i_prof,
                                               i_id_episode          => i_id_episode,
                                               i_id_profile_template => NULL,
                                               i_id_market           => NULL,
                                               i_id_department       => NULL,
                                               i_id_dep_clin_serv    => NULL,
                                               i_id_epis_pn          => NULL,
                                               i_id_pn_note_type     => i_id_pn_note_type,
                                               i_software            => NULL);
    
        l_flg_submit := process_submit(i_prof       => i_prof,
                                       i_id_episode => i_id_episode,
                                       i_flg_submit => l_pn_note_type.flg_submit);
    
        IF l_id_prof = -1
        THEN
            l_id_prof := NULL;
        END IF;
        OPEN o_configs FOR
            SELECT l_pn_note_type.id_pn_area id_pn_area,
                   l_pn_note_type.id_pn_note_type id_pn_note_type,
                   l_pn_note_type.rank rank,
                   l_pn_note_type.max_nr_notes max_nr_notes,
                   l_pn_note_type.max_nr_draft_notes max_nr_draft_notes,
                   l_pn_note_type.max_nr_draft_addendums max_nr_draft_addendums,
                   l_pn_note_type.flg_addend_other_prof flg_addend_other_prof,
                   l_pn_note_type.flg_show_empty_blocks flg_show_empty_blocks,
                   l_pn_note_type.flg_sign_off_login_avail flg_sign_off_login_avail,
                   l_pn_note_type.flg_last_24h flg_last_24h,
                   l_pn_note_type.flg_dictation_editable flg_dictation_editable,
                   l_pn_note_type.flg_clear_information flg_clear_information,
                   l_pn_note_type.flg_review_all flg_review_all,
                   l_pn_note_type.flg_import_first flg_import_first,
                   decode(l_ready_only, pk_alert_constant.g_yes, pk_alert_constant.g_no, l_pn_note_type.flg_write) flg_write,
                   l_pn_note_type.flg_copy_edit_replace flg_copy_edit_replace,
                   l_pn_note_type.gender gender,
                   l_pn_note_type.age_min age_min,
                   l_pn_note_type.age_max age_max,
                   l_pn_note_type.flg_expand_sblocks flg_expand_sblocks,
                   l_pn_note_type.flg_synchronized flg_synchronized,
                   l_pn_note_type.flg_show_import_menu flg_show_import_menu,
                   l_pn_note_type.flg_autopop_warning flg_autopop_warning,
                   l_pn_note_type.flg_discharge_warning flg_discharge_warning,
                   l_pn_note_type.flg_disch_warning_option flg_disch_warning_option,
                   l_pn_note_type.flg_review_warning flg_review_warning,
                   l_pn_note_type.flg_review_warn_option flg_review_warn_option,
                   l_pn_note_type.flg_import_warning flg_import_warning,
                   l_pn_note_type.flg_help_save flg_help_save,
                   l_pn_note_type.flg_save_only_screen flg_save_only_screen,
                   l_pn_note_type.flg_partial_warning flg_partial_warning,
                   l_pn_note_type.flg_remove_on_ok flg_remove_on_ok,
                   l_pn_note_type.flg_edit_only_last flg_edit_only_last,
                   l_pn_note_type.flg_status_available flg_status_available,
                   l_pn_note_type.flg_review_on_ok flg_review_on_ok,
                   l_pn_note_type.flg_partial_load flg_partial_load,
                   l_pn_note_type.flg_import_available flg_import_available,
                   l_pn_note_type.flg_sign_off flg_sign_off,
                   l_flg_submit flg_submit,
                   l_pn_note_type.flg_patient_id_warning flg_patient_id_warning,
                   l_id_prof id_prof_red,
                    l_pn_note_type.flg_show_free_text flg_show_free_text
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_configs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_TYPE_CONFIGS',
                                              o_error);
            RETURN FALSE;
    END get_note_type_configs;

    /**
    * Check if it is possible to change the addendum (edit,cancel,sig off)
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure   
    * @param i_flg_status_addendum     Addendum status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn_addendum     Selected addendum Id.
    *                                  If no note is selected this param should be null    
    *
    * @return               1-the note can be changed; 0-otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                28-Jan-2011
    */
    FUNCTION check_change_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status_addendum IN epis_pn_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_pn_addendum.id_epis_pn_addendum%TYPE
    ) RETURN PLS_INTEGER IS
        l_prof_create     epis_pn.id_prof_create%TYPE;
        l_change_addendum PLS_INTEGER := 1;
        l_error           t_error_out;
    BEGIN
        --the edition and cancellation is only allowed when the addendum status = Draft       
        IF (i_flg_status_addendum = pk_prog_notes_constants.g_addendum_status_d)
        THEN
        
            --the professional can only change/cancel/sign-off the addendums created by himself
            g_error       := 'CALL get_addendum_prof. i_id_epis_addendum: ' || i_id_epis_addendum;
            l_prof_create := get_addendum_prof(i_lang             => i_lang,
                                               i_prof             => i_prof,
                                               i_id_epis_addendum => i_id_epis_addendum);
            IF (l_prof_create <> i_prof.id)
            THEN
                l_change_addendum := 0;
            END IF;
        ELSE
            l_change_addendum := 0;
        END IF;
    
        RETURN l_change_addendum;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_CHANGE_ADDENDUM',
                                              l_error);
        
            RETURN 0;
    END check_change_addendum;

    /**
    * Check if it is possible to change the note (edit,cancel,sig off)
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure   
    * @param i_flg_status_note         Note status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null    
    * @param i_flg_write                  Y-The note type has write permissions. N-otherwise
    * @param i_flg_dictation_editable     Y-It is allowed to edit the dictations on app. N -otherwise
    * @param i_flg_edit_other_prof        Y-The note can be edited by a professional that does not create it. N-otherwise
    *
    * @return               1-the note can be changed; 0-otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                28-Jan-2011
    */

    FUNCTION get_flg_submit_mode(i_prof IN profissional) RETURN VARCHAR2 IS
        tbl_flag     table_varchar;
        l_return     VARCHAR2(0010 CHAR);
        l_id_profile NUMBER;
    
    BEGIN
    
        l_id_profile := pk_tools.get_prof_profile_template(i_prof => i_prof);
    
        SELECT flg_submit_mode
          BULK COLLECT
          INTO tbl_flag
          FROM profile_template t
         WHERE t.id_profile_template = l_id_profile;
    
        IF tbl_flag.count > 0
        THEN
            l_return := tbl_flag(1);
        END IF;
    
        RETURN l_return;
    
    END get_flg_submit_mode;

    FUNCTION check_change_note
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_flg_status_note        IN epis_pn.flg_status%TYPE,
        i_id_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_flg_write              IN pn_note_type_mkt.flg_write%TYPE,
        i_flg_dictation_editable IN pn_note_type_mkt.flg_dictation_editable%TYPE,
        i_flg_edit_other_prof    IN pn_note_type_mkt.flg_edit_other_prof%TYPE,
        i_flg_submit             IN pn_note_type_mkt.flg_submit%TYPE DEFAULT NULL
    ) RETURN PLS_INTEGER IS
        l_prof_create_note     epis_pn.id_prof_create%TYPE;
        l_change_note          PLS_INTEGER := 1;
        l_error                t_error_out;
        l_dictation_edit_avail sys_config.value%TYPE;
        l_id_dictation_report  epis_pn.id_dictation_report%TYPE;
        l_flg_profile          VARCHAR2(0010 CHAR);
    
        k_epis_pn_flg_for_review  CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
        k_epis_pn_flg_draftsubmit CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_draftsubmit;
        k_epis_pn_flg_submited    CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_submited;
    
        k_profile_for_review CONSTANT VARCHAR2(0010 CHAR) := 'R'; -- Flag from profile_template.flg_submit_mode
    
        --***********************************
        FUNCTION check_dictation RETURN NUMBER IS
            l_count  NUMBER;
            l_return NUMBER;
            k_default_change_note CONSTANT PLS_INTEGER := 1;
        BEGIN
        
            SELECT COUNT(*)
              INTO l_count
              FROM epis_pn epn
             WHERE epn.id_epis_pn = i_id_epis_pn
               AND epn.id_dictation_report IS NOT NULL;
        
            --it is configurable if the dictation notes can be editable in the aplication
            IF (l_count > 0)
            THEN
            
                l_dictation_edit_avail := i_flg_dictation_editable;
            
                IF (l_dictation_edit_avail = pk_alert_constant.g_no)
                THEN
                    l_return := 0;
                END IF;
            END IF;
        
            RETURN nvl(l_return, k_default_change_note);
        
        END check_dictation;
    
    BEGIN
    
        IF i_flg_write = pk_alert_constant.g_no
        THEN
            l_change_note := 2;
        ELSE
        
            --the edition and cancellation is only allowed when the note status = Draft or Finished
            IF (i_flg_status_note IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                      pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                      k_epis_pn_flg_for_review,
                                      k_epis_pn_flg_draftsubmit,
                                      k_epis_pn_flg_submited,
                                      pk_prog_notes_constants.g_epis_pn_flg_status_t))
            THEN
                --check if it was selected a dictation note
                g_error       := 'GET id_dictation_report. i_id_epis_pn: ' || i_id_epis_pn;
                l_change_note := check_dictation();
            
                IF (l_change_note = 1)
                THEN
                    IF (i_flg_edit_other_prof = pk_alert_constant.g_no)
                    THEN
                        --the professional can only change/cancel/sign-off the notes created by himself
                        g_error            := 'CALL get_note_prof. i_id_epis_pn: ' || i_id_epis_pn;
                        l_prof_create_note := get_note_prof(i_lang       => i_lang,
                                                            i_prof       => i_prof,
                                                            i_id_epis_pn => i_id_epis_pn);
                        IF (l_prof_create_note <> i_prof.id)
                        THEN
                            l_change_note := 0;
                        END IF;
                    END IF;
                
                END IF;
                IF i_flg_submit = pk_alert_constant.g_yes
                THEN
                    l_flg_profile := get_flg_submit_mode(i_prof => i_prof);
                
                    IF l_flg_profile = k_profile_for_review
                    THEN
                    
                        IF i_flg_status_note IN
                           (k_epis_pn_flg_for_review, k_epis_pn_flg_draftsubmit, k_epis_pn_flg_submited)
                        THEN
                            l_change_note := 0;
                        END IF;
                    
                    END IF;
                END IF;
                --l_change_note := 0;
            
            ELSE
                l_change_note := 0;
            END IF;
        END IF;
    
        RETURN l_change_note;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_CHANGE_NOTE',
                                              l_error);
        
            RETURN 0;
    END check_change_note;

    /**
    * Check if it is possible to create more addendums.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_draft_addendums
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'CALL check_max_addendums';
        IF NOT check_max_addendums(i_lang         => i_lang,
                                   i_prof         => i_prof,
                                   i_id_epis_pn   => i_id_epis_pn,
                                   i_flg_statuses => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d),
                                   o_create_avail => o_create_avail,
                                   o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_MAX_DRAFT_ADDENDUMS',
                                              o_error);
        
            RETURN FALSE;
    END check_max_draft_addendums;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode identifier
    * @param i_note_type                  Type of note id                                      
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_draft_notes
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN episode.id_episode%TYPE,
        i_note_type    IN pn_note_type.id_pn_note_type%TYPE,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        --if the maximun number of notes in the H&P is filled, the option 'Create note'
        -- should be unavailable
        g_error := 'CALL check_max_notes. i_sys_config_id: HP_MAX_NOTES; i_id_episode: ' || i_id_episode;
        IF NOT check_max_notes(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_id_episode      => i_id_episode,
                               i_flg_statuses    => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                  pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                                  pk_prog_notes_constants.g_epis_pn_flg_status_f),
                               i_flg_check_draft => pk_alert_constant.g_no,
                               i_note_type       => i_note_type,
                               o_create_avail    => o_create_avail,
                               o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (o_create_avail = 1)
        THEN
            --if the professional has draft notes in the episode check if it is allowed to create more draft notes        
            g_error := 'CALL check_max_notes. i_note_type: ' || i_note_type || '; i_id_episode: ' || i_id_episode;
            IF NOT check_max_notes(i_lang            => i_lang,
                                   i_prof            => i_prof,
                                   i_id_episode      => i_id_episode,
                                   i_flg_statuses    => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d),
                                   i_flg_check_draft => pk_alert_constant.g_yes,
                                   i_note_type       => i_note_type,
                                   o_create_avail    => o_create_avail,
                                   o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_MAX_DRAFT_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END check_max_draft_notes;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode identifier
    * @param i_flg_statuses               Notes Status list                                     
    * @param i_flg_check_draft            Y-check the maximum nr of draft notes. N-check the maximum nr of notes
    * @param i_note_types                 Note types
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_flg_statuses    IN table_varchar,
        i_flg_check_draft IN VARCHAR2,
        i_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        o_create_avail    OUT NOCOPY PLS_INTEGER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nr_notes      PLS_INTEGER;
        l_max_nr        PLS_INTEGER;
        l_note_type_row t_rec_note_type;
    BEGIN
        --get the nr of notes        
        g_error    := 'CALL get_nr_notes_state. i_id_episode: ' || i_id_episode;
        l_nr_notes := get_nr_notes_state(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_id_episode   => i_id_episode,
                                         i_flg_statuses => i_flg_statuses,
                                         i_note_types   => table_number(i_note_type));
    
        --get the configurated maximum value        
        g_error         := 'CALL get_note_type_config. i_note_type: ' || i_note_type;
        l_note_type_row := get_note_type_config(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_episode          => i_id_episode,
                                                i_id_profile_template => NULL,
                                                i_id_market           => NULL,
                                                i_id_department       => NULL,
                                                i_id_dep_clin_serv    => NULL,
                                                i_id_epis_pn          => NULL,
                                                i_id_pn_note_type     => i_note_type,
                                                i_software            => NULL);
    
        IF (i_flg_check_draft = pk_alert_constant.g_yes)
        THEN
            l_max_nr := l_note_type_row.max_nr_draft_notes;
        ELSE
            l_max_nr := l_note_type_row.max_nr_notes;
        END IF;
    
        --compare the values
        IF (l_nr_notes < l_max_nr OR l_max_nr IS NULL)
        THEN
            o_create_avail := 1;
        ELSE
            o_create_avail := 0;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_MAX_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END check_max_notes;

    /**
    * Check if it is possible to create more notes in some status/statuses.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param i_flg_statuses               Addendums Status list
    * @param o_create_avail               Y-It is possible to create more notes. N-otherwise.
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_max_addendums
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
        i_flg_statuses IN table_varchar,
        o_create_avail OUT NOCOPY PLS_INTEGER,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_nr_addendums  PLS_INTEGER;
        l_max_nr        PLS_INTEGER;
        l_note_type_row t_rec_note_type;
    BEGIN
        --get the nr of addendums        
        g_error        := 'CALL get_nr_addendums_state. i_id_epis_pn: ' || i_id_epis_pn;
        l_nr_addendums := get_nr_addendums_state(i_lang           => i_lang,
                                                 i_prof           => i_prof,
                                                 i_id_epis_pn     => i_id_epis_pn,
                                                 i_id_prof_create => i_prof.id,
                                                 i_flg_statuses   => i_flg_statuses);
    
        --the the configurated maximum value       
        g_error         := 'CALL get_note_type_config. i_id_epis_pn: ' || i_id_epis_pn;
        l_note_type_row := get_note_type_config(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_episode          => NULL,
                                                i_id_profile_template => NULL,
                                                i_id_market           => NULL,
                                                i_id_department       => NULL,
                                                i_id_dep_clin_serv    => NULL,
                                                i_id_epis_pn          => i_id_epis_pn,
                                                i_software            => NULL);
    
        l_max_nr := l_note_type_row.max_nr_draft_addendums;
    
        --compare the values
        IF (l_nr_addendums < l_max_nr OR l_max_nr IS NULL)
        THEN
            o_create_avail := 1;
        ELSE
            o_create_avail := 0;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_MAX_ADDENDUMS',
                                              o_error);
        
            RETURN FALSE;
    END check_max_addendums;

    /**
    * Check if it is possible to create more addendums.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.                                     
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_addendums
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_flg_show   OUT NOCOPY VARCHAR2,
        o_msg_title  OUT NOCOPY VARCHAR2,
        o_msg        OUT NOCOPY VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_create_addendum PLS_INTEGER := 1;
    BEGIN
        g_error := 'CALL check_max_addendums';
    
        --check the maximun nr of draft adendums
        g_error := 'CALL check_max_addendums. i_id_epis_pn: ' || i_id_epis_pn;
        IF NOT check_max_draft_addendums(i_lang         => i_lang,
                                         i_prof         => i_prof,
                                         i_id_epis_pn   => i_id_epis_pn,
                                         o_create_avail => l_create_addendum,
                                         o_error        => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_create_addendum = 1)
        THEN
            o_flg_show := pk_alert_constant.g_no;
        ELSE
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T017');
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M019');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            o_flg_show := pk_alert_constant.g_no;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_flg_show := pk_alert_constant.g_no;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_CREATE_ADDENDUMS',
                                              o_error);
        
            RETURN FALSE;
    END check_create_addendums;

    /**
    * Check if it is possible to create more notes.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 Episode identifier    
    * @param i_note_type                  Note type id
    * @param o_flg_show                   Y - It is necessary to show the popup.
    *                                     N - otherwise.                                     
    * @param o_msg_title                  Title
    * @param o_msg                        Message text
    * @param o_error                      error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                09-Feb-2011
    */
    FUNCTION check_create_notes
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_flg_show   OUT NOCOPY VARCHAR2,
        o_msg_title  OUT NOCOPY VARCHAR2,
        o_msg        OUT NOCOPY VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_create_note_avail PLS_INTEGER := 1;
    BEGIN
        --if the professional has draft notes in the episode check if it is allowed to create more draft notes        
        g_error := 'CALL check_max_notes. i_note_type: ' || i_note_type || '; i_id_episode: ' || i_id_episode;
        IF NOT check_max_notes(i_lang            => i_lang,
                               i_prof            => i_prof,
                               i_id_episode      => i_id_episode,
                               i_flg_statuses    => table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d),
                               i_flg_check_draft => pk_alert_constant.g_yes,
                               i_note_type       => i_note_type,
                               o_create_avail    => l_create_note_avail,
                               o_error           => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_create_note_avail = 1)
        THEN
            o_flg_show := pk_alert_constant.g_no;
        ELSE
            o_flg_show  := pk_alert_constant.g_yes;
            o_msg_title := REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_T016'),
                                   '@1',
                                   get_note_type_desc(i_lang               => i_lang,
                                                      i_prof               => i_prof,
                                                      i_id_pn_note_type    => i_note_type,
                                                      i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d));
            o_msg       := pk_message.get_message(i_lang => i_lang, i_code_mess => 'PN_M018');
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            o_flg_show := pk_alert_constant.g_no;
            RETURN FALSE;
        WHEN OTHERS THEN
            o_flg_show := pk_alert_constant.g_no;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_CREATE_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END check_create_notes;

    /**************************************************************************
    * When editing some data inserted by template validates
    * if the template was edited since the note creation date.
    * This is used because the physical exam template inserts vital signs values
    * and if the vital signs are edited in the vital signs area the template is updated.
    * However in the H&P appear the values inserted when the template was created. So,
    * when the user edits this template he should be notified that the template had been edited
    * after its insertion in the H&P area.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_epis_documentation  Epis documentation Id
    * @param i_id_epis_pn             Epis Progress Note Id
    * @param o_flg_edited             Y-the template was edited.
    *                                 N-otherwise    
    * @param o_error                  Error message
    *                                                                         
    * @author                         Sofia Mendes                       
    * @version                        2.6.1                                
    * @since                          19-Mai-2011                                
    **************************************************************************/
    FUNCTION check_show_edition_popup
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_epis_documentation IN epis_documentation.id_epis_documentation%TYPE,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        o_flg_show              OUT NOCOPY VARCHAR2,
        o_msg_title             OUT NOCOPY VARCHAR2,
        o_msg                   OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_dt_creation epis_pn_det_task.dt_last_update%TYPE;
    BEGIN
        g_error := 'CALL get_pn_insertion_date. i_id_epis_documentation: ' || i_id_epis_documentation;
        IF NOT get_pn_insertion_date(i_lang        => i_lang,
                                     i_prof        => i_prof,
                                     i_id_task     => i_id_epis_documentation,
                                     i_id_epis_pn  => i_id_epis_pn,
                                     o_dt_creation => l_dt_creation,
                                     o_error       => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        g_error := 'CALL pk_prog_notes_in.check_documentation_edition';
        IF NOT pk_prog_notes_in.check_documentation_edition(i_lang                  => i_lang,
                                                            i_prof                  => i_prof,
                                                            i_id_epis_documentation => i_id_epis_documentation,
                                                            i_dt_creation           => l_dt_creation,
                                                            o_flg_show              => o_flg_show,
                                                            o_msg_title             => o_msg_title,
                                                            o_msg                   => o_msg,
                                                            o_error                 => o_error)
        THEN
            RETURN FALSE;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_SHOW_EDITION_POPUP',
                                              o_error);
            RETURN FALSE;
    END check_show_edition_popup;

    /**
    * Returns the actions to be displayed in the 'ADD' button in the progress notes summary screens.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_episode                    episode identifier
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param i_flg_status_note            Selected note status.
    *                                     If no note is selected this param should be null
    * @param i_area                       HP - History and Physician Notes Screen
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
    FUNCTION get_actions_add_button
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_area            IN pn_area.internal_name%TYPE,
        o_actions         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_ACTIONS_ADD_BUTTON';
        l_create_addendum   PLS_INTEGER := 1;
        l_add_ad_other_prof sys_config.value%TYPE;
        l_prof_create_note  epis_pn.id_prof_create%TYPE;
        l_note_type_row     t_rec_note_type;
    
        l_pat_age    patient.age%TYPE := NULL;
        l_pat_gender patient.gender%TYPE := NULL;
    
        l_general_exception EXCEPTION;
    
        l_area     pn_area.internal_name%TYPE := i_area;
        l_prof_cat category.id_category%TYPE;
        l_no_area_exception EXCEPTION;
        l_flg_editable   VARCHAR2(1 CHAR);
        l_is_dicharged   VARCHAR2(1) := pk_alert_constant.g_no;
        l_pat_age_months NUMBER;
        l_id_patient     patient.id_patient%TYPE;
    
    BEGIN
        --in the discharge scren it is not sent the i_area and it is used the area in the pn_area to the 
        --current logged professional category
        IF (i_area IS NULL)
        THEN
            l_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'GET l_area. l_prof_cat: ' || l_prof_cat;
            BEGIN
                SELECT internal_name
                  INTO l_area
                  FROM (SELECT p.internal_name
                          FROM pn_area p
                         WHERE p.id_category = l_prof_cat
                           AND p.flg_type = 'S' --cv 
                         ORDER BY p.rank ASC)
                 WHERE rownum = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    g_error := 'NO l_area defined';
                    RAISE l_no_area_exception;
            END;
        
        END IF;
    
        g_error := 'CALL pk_discharge.get_epis_discharge_state';
        IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_episode   => i_id_episode,
                                                     o_discharge => l_is_dicharged,
                                                     o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
        --get patient age and gender
        g_error := 'Call PK_PATIENT.GET_PAT_INFO_BY_EPISODE';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang    => i_lang,
                                                  i_episode => i_id_episode,
                                                  o_gender  => l_pat_gender,
                                                  o_age     => l_pat_age)
        THEN
            RAISE l_general_exception;
        END IF;
    
        SELECT id_patient
          INTO l_id_patient
          FROM episode
         WHERE id_episode = i_id_episode;
        l_pat_age_months := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
    
        g_error         := 'CALL get_note_type_config. i_id_epis_pn: ' || i_id_epis_pn;
        l_note_type_row := get_note_type_config(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_episode          => i_id_episode,
                                                i_id_profile_template => NULL,
                                                i_id_market           => NULL,
                                                i_id_department       => NULL,
                                                i_id_dep_clin_serv    => NULL,
                                                i_id_epis_pn          => i_id_epis_pn,
                                                i_software            => NULL);
    
        g_error        := 'CALL pk_prog_notes_utils.get_flg_editable. i_id_epis_pn: ' || i_id_epis_pn;
        l_flg_editable := pk_prog_notes_utils.get_flg_editable(i_lang                 => i_lang,
                                                               i_prof                 => i_prof,
                                                               i_id_episode           => i_id_episode,
                                                               i_id_epis_pn           => i_id_epis_pn,
                                                               i_editable_nr_min      => l_note_type_row.editable_nr_min,
                                                               i_flg_edit_after_disch => l_note_type_row.flg_edit_after_disch,
                                                               i_flg_synchronized     => l_note_type_row.flg_synchronized,
                                                               i_id_pn_note_type      => l_note_type_row.id_pn_note_type,
                                                               i_flg_edit_only_last   => l_note_type_row.flg_edit_only_last,
                                                               i_flg_edit_condition   => l_note_type_row.flg_edit_condition);
    
        --if an note is selected the option 'Add Adendum' should only be active if 
        -- the note is signed-off
        IF ( /*i_flg_status_note IS NOT NULL*/
            l_flg_editable = pk_alert_constant.get_no OR
            i_flg_status_note = pk_prog_notes_constants.g_epis_pn_flg_status_s)
        THEN
            -- one professional can only create an addendum to a note create by another professional if a configuration exists 
            --allowing that     
            IF check_pn_with_patient_info(i_lang       => i_lang,
                                          i_pn_age_min => l_note_type_row.age_min,
                                          i_pn_age_max => l_note_type_row.age_max,
                                          i_pn_gender  => l_note_type_row.gender,
                                          i_pat_age    => l_pat_age_months,
                                          i_pat_gender => l_pat_gender) = pk_alert_constant.g_no
            THEN
                l_create_addendum := 0;
            ELSE
                l_add_ad_other_prof := l_note_type_row.flg_addend_other_prof;
            
                IF (l_add_ad_other_prof = pk_alert_constant.g_no)
                THEN
                    --if the professional that created the note is not the logged professional, he can not add adendums
                    l_prof_create_note := get_note_prof(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_epis_pn => i_id_epis_pn);
                    IF (l_prof_create_note <> i_prof.id)
                    THEN
                        l_create_addendum := 0;
                    END IF;
                
                END IF;
            END IF;
        
        ELSE
            l_create_addendum := 0;
        END IF;
    
        g_error := 'GET CURSOR o_actions. l_pat_age: ' || l_pat_age || ' l_pat_gender: ' || l_pat_gender;
        OPEN o_actions FOR
            SELECT *
              FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                     id_action,
                     id_parent,
                     level_nr,
                     from_state,
                     to_state,
                     desc_action,
                     icon,
                     flg_default,
                     action,
                     decode(action,
                            'ADD_ADDENDUM',
                            decode(l_create_addendum, 1, pk_alert_constant.g_active, pk_alert_constant.g_inactive)) flg_active,
                     NULL flg_type,
                     2 sort_rank,
                     NULL rank
                      FROM TABLE(pk_action.tf_get_actions(i_lang,
                                                          i_prof,
                                                          pk_prog_notes_constants.g_acs_add_button_add,
                                                          NULL)) t
                     WHERE (l_note_type_row.flg_sign_off = pk_alert_constant.g_yes OR
                           l_flg_editable = pk_alert_constant.g_no)
                    
                    UNION ALL
                    --note types configured to the current area
                    SELECT NULL          id_action,
                           NULL          id_parent,
                           NULL          level_nr,
                           NULL          from_state,
                           NULL          to_state,
                           t.desc_action,
                           NULL          icon,
                           NULL          flg_default,
                           t.action,
                           --if the maximun number of notes is reached, the option 'Create note'
                           -- should be unavailable
                           CASE
                               WHEN t.nr_notes >= t.max_nr_notes
                                    OR check_pn_with_patient_info(i_lang,
                                                                  t.age_min,
                                                                  t.age_max,
                                                                  t.gender,
                                                                  l_pat_age_months,
                                                                  l_pat_gender) = pk_alert_constant.g_no
                                    OR get_discharge_note_status(t.flg_edit_after_disch, l_is_dicharged) =
                                    pk_alert_constant.g_no THEN
                                pk_alert_constant.g_inactive
                               ELSE
                                pk_alert_constant.g_active
                           END flg_active,
                           t.note_type flg_type,
                           1 sort_rank,
                           t.rank
                      FROM (SELECT /*+ OPT_ESTIMATE (TABLE tt ROWS=1)*/
                             pk_message.get_message(i_lang, i_prof, nt.code_add_action) desc_action,
                             'ADD_NOTE' action,
                             tt.max_nr_notes,
                             tt.id_pn_note_type note_type,
                             get_nr_notes_state(i_lang,
                                                i_prof,
                                                i_id_episode,
                                                table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                              pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                              pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                              pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                              pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                              pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                              pk_prog_notes_constants.g_epis_pn_flg_draftsubmit),
                                                table_number(tt.id_pn_note_type)) nr_notes,
                             tt.rank,
                             tt.age_min,
                             tt.age_max,
                             tt.gender,
                             tt.flg_edit_after_disch
                              FROM TABLE(tf_pn_note_type(i_lang,
                                                         i_prof,
                                                         i_id_episode,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         table_varchar(l_area),
                                                         NULL,
                                                         pk_prog_notes_constants.g_pn_flg_scope_area_a,
                                                         NULL)) tt
                              JOIN pn_note_type nt
                                ON nt.id_pn_note_type = tt.id_pn_note_type
                             WHERE tt.flg_write = pk_alert_constant.g_yes
                               AND tt.flg_create_on_app = pk_alert_constant.g_yes) t)
             ORDER BY sort_rank, rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_area_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS_ADD_BUTTON',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS_ADD_BUTTON',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_add_button;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when a note is selected.
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_note         Note status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_pn                 Selected note Id.
    *                                     If no note is selected this param should be null
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION check_if_review_available(i_tbl IN t_coll_action) RETURN NUMBER IS
        l_count NUMBER;
        k_flg_review CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
        k_active     CONSTANT VARCHAR2(0010 CHAR) := 'A';
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM TABLE(i_tbl) xpto
         WHERE xpto.to_state = k_flg_review
           AND flg_active = k_active;
    
        RETURN(l_count);
    
    END check_if_review_available;

    FUNCTION get_flg_active
    (
        i_prof          IN profissional,
        i_pn_status     IN VARCHAR2,
        i_to_state      IN VARCHAR2,
        i_default_value IN VARCHAR2,
        i_flg_submit    VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        k_pn_flg_submit      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_submited;
        k_pn_flg_draftsubmit CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_draftsubmit;
        k_pn_flg_draft       CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_d;
        k_pn_flg_cancel      CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_status_c;
        k_pn_flg_4_review    CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
        k_not_visible        CONSTANT VARCHAR2(0010 CHAR) := 'N';
        l_flg_submit_mode VARCHAR2(0010 CHAR);
        l_return          VARCHAR2(0010 CHAR);
    BEGIN
    
        IF i_flg_submit = pk_alert_constant.g_yes
        THEN
            l_flg_submit_mode := get_flg_submit_mode(i_prof => i_prof);
        END IF;
        -- BEGIN CASE PROFILE
        CASE l_flg_submit_mode
            WHEN k_flg_review THEN
                -- BEGIN CASE_FLG_STATUS 1
                CASE
                    WHEN (i_pn_status = k_pn_flg_draft) THEN
                        l_return := pk_alert_constant.g_active;
                    ELSE
                        l_return := pk_alert_constant.g_inactive;
                END CASE;
                -- END CASE_FLG_STATUS 1
        
            WHEN k_flg_submit THEN
            
                -- BEGIN CASE_FLG_STATUS 2
                CASE
                    WHEN (i_pn_status = k_pn_flg_submit)
                         AND (i_to_state = i_pn_status) THEN
                        l_return := pk_alert_constant.g_inactive;
                    
                    WHEN (i_pn_status = k_pn_flg_draftsubmit)
                         AND (i_to_state = k_pn_flg_cancel) THEN
                        l_return := pk_alert_constant.g_inactive;
                    
                    WHEN (i_pn_status = k_pn_flg_submit)
                         AND (i_to_state = k_pn_flg_cancel) THEN
                        l_return := pk_alert_constant.g_inactive;
                    WHEN (i_pn_status = k_pn_flg_cancel) THEN
                        l_return := pk_alert_constant.g_inactive;
                    ELSE
                        l_return := pk_alert_constant.g_active;
                END CASE;
                -- END CASE_FLG_STATUS 2
            ELSE
                IF i_to_state IN (k_pn_flg_draftsubmit, k_pn_flg_submit)
                THEN
                    l_return := k_not_visible;
                ELSE
                    l_return := i_default_value;
                END IF;
        END CASE;
        -- END CASE PROFILE
    
        RETURN l_return;
    
    END get_flg_active;

    FUNCTION get_edit_submit_desc
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_id_action   IN NUMBER,
        i_action_name IN VARCHAR2,
        i_desc_action IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_return          VARCHAR2(4000);
        xrow              action%ROWTYPE;
        l_flg_submit_mode VARCHAR2(0010 CHAR);
        k_trl_sufix        CONSTANT VARCHAR2(0010 CHAR) := '.1';
        k_edit_action_name CONSTANT VARCHAR2(0100 CHAR) := 'ACTION_EDIT';
    BEGIN
    
        l_flg_submit_mode := get_flg_submit_mode(i_prof => i_prof);
    
        -- BEGIN CASE PROFILE
        CASE l_flg_submit_mode
            WHEN k_flg_review THEN
                l_return := i_desc_action;
            WHEN k_flg_submit THEN
            
                SELECT *
                  INTO xrow
                  FROM action x
                 WHERE x.id_action = i_id_action;
            
                l_return := nvl(pk_message.get_message(i_lang, i_prof, xrow.code_action || k_trl_sufix), i_desc_action);
                IF i_action_name = k_edit_action_name
                THEN
                
                    l_return := pk_message.get_message(i_lang, i_prof, xrow.code_action || k_trl_sufix);
                
                END IF;
            
            ELSE
                l_return := i_desc_action;
        END CASE;
    
        RETURN l_return;
    
    END get_edit_submit_desc;

    FUNCTION get_actions_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_status_note IN epis_pn.flg_status%TYPE,
        i_id_epis_pn      IN epis_pn.id_epis_pn%TYPE,
        o_actions         OUT NOCOPY pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_change_note PLS_INTEGER := 1;
        g_flg_no_write_permission CONSTANT NUMBER := 2; -- When there is no write permissions for note type
        l_note_type_row t_rec_note_type;
        tbl_action      t_coll_action := t_coll_action();
        k_flg_review  CONSTANT VARCHAR2(0010 CHAR) := pk_prog_notes_constants.g_epis_pn_flg_for_review;
        k_not_visible CONSTANT VARCHAR2(0010 CHAR) := 'N';
        l_return     NUMBER := 0;
        l_flg_status VARCHAR2(0010 CHAR);
    
    BEGIN
        g_error         := 'CALL get_note_type_config. i_id_epis_pn: ' || i_id_epis_pn;
        l_note_type_row := get_note_type_config(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_episode          => NULL,
                                                i_id_profile_template => NULL,
                                                i_id_market           => NULL,
                                                i_id_department       => NULL,
                                                i_id_dep_clin_serv    => NULL,
                                                i_id_epis_pn          => i_id_epis_pn,
                                                i_software            => NULL);
    
        g_error       := 'CALL check_change_note';
        l_change_note := check_change_note(i_lang                   => i_lang,
                                           i_prof                   => i_prof,
                                           i_flg_status_note        => i_flg_status_note,
                                           i_id_epis_pn             => i_id_epis_pn,
                                           i_flg_write              => l_note_type_row.flg_write,
                                           i_flg_dictation_editable => l_note_type_row.flg_dictation_editable,
                                           i_flg_edit_other_prof    => l_note_type_row.flg_edit_other_prof,
                                           i_flg_submit             => l_note_type_row.flg_submit);
    
        tbl_action := pk_action.tf_get_actions(i_lang, i_prof, pk_prog_notes_constants.g_acs_actions_button, NULL);
    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT xsql.id_action,
                   xsql.id_parent,
                   xsql.level_nr,
                   xsql.from_state,
                   xsql.to_state,
                   -------
                   pk_prog_notes_utils.get_edit_submit_desc(i_lang        => i_lang,
                                                            i_prof        => i_prof,
                                                            i_id_action   => xsql.id_action,
                                                            i_action_name => xsql.action,
                                                            i_desc_action => xsql.desc_action) desc_action,
                   ------
                   --xsql.desc_action,
                   xsql.icon,
                   xsql.flg_default,
                   xsql.action,
                   pk_prog_notes_utils.get_flg_active(i_prof,
                                                      i_flg_status_note,
                                                      xsql.to_state,
                                                      xsql.flg_active,
                                                      l_note_type_row.flg_submit) flg_active
            --xsql.flg_active flg_active
              FROM (SELECT t.id_action,
                           t.id_parent,
                           t.level_nr,
                           t.from_state,
                           t.to_state,
                           t.desc_action,
                           t.icon,
                           t.flg_default,
                           t.action,
                           -- decode(l_change_note, 1, pk_alert_constant.g_active, pk_alert_constant.g_inactive) flg_active
                           CASE
                                WHEN t.flg_active = k_not_visible THEN
                                 t.flg_active
                                WHEN l_change_note = 1 THEN
                                 t.flg_active
                                ELSE
                                 pk_alert_constant.g_inactive
                            END flg_active
                    --decode(l_change_note, 1, t.flg_active, pk_alert_constant.g_inactive) flg_active
                      FROM TABLE(tbl_action) t
                     WHERE l_change_note <> g_flg_no_write_permission
                       AND (l_note_type_row.flg_sign_off = pk_alert_constant.g_yes OR
                           (l_note_type_row.flg_sign_off = pk_alert_constant.g_no AND t.action <> 'ACTION_SIGN_OFF'))
                       AND NOT (l_note_type_row.flg_cancel = pk_alert_constant.g_no AND t.action = 'ACTION_CANCEL')
                    
                    ) xsql;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS_NOTES',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_notes;

    /**
    * Returns the actions to be displayed in the 'ACTIONS' button when an addendum is selected
    *
    *
    * @param i_lang                    language identifier
    * @param i_prof                    logged professional structure
    * @param i_flg_status_addendum     Addendum status: D-draft; S-signed-off; C-Cancelled; F-Finalized
    * @param i_id_epis_addendum        Addendum Id
    * @param o_actions                 actions data
    * @param o_error                   error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.0.5
    * @since                27-Jan-2011
    */
    FUNCTION get_actions_addendum
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_flg_status_addendum IN epis_pn_addendum.flg_status%TYPE,
        i_id_epis_addendum    IN epis_pn_addendum.id_epis_pn_addendum%TYPE,
        o_actions             OUT NOCOPY pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_change_addendum PLS_INTEGER;
        l_note_type_row   t_rec_note_type;
        l_id_epis_pn      epis_pn.id_epis_pn%TYPE;
    BEGIN
        BEGIN
            g_error := 'GET addendum note id. i_id_epis_addendum: ' || i_id_epis_addendum;
            SELECT epa.id_epis_pn
              INTO l_id_epis_pn
              FROM epis_pn_addendum epa
             WHERE epa.id_epis_pn_addendum = i_id_epis_addendum;
        EXCEPTION
            WHEN OTHERS THEN
                l_id_epis_pn := NULL;
        END;
    
        g_error         := 'CALL get_note_type_config. i_id_epis_pn: ' || l_id_epis_pn;
        l_note_type_row := get_note_type_config(i_lang                => i_lang,
                                                i_prof                => i_prof,
                                                i_id_episode          => NULL,
                                                i_id_profile_template => NULL,
                                                i_id_market           => NULL,
                                                i_id_department       => NULL,
                                                i_id_dep_clin_serv    => NULL,
                                                i_id_epis_pn          => l_id_epis_pn,
                                                i_software            => NULL);
    
        g_error           := 'CALL check_change_addendum';
        l_change_addendum := check_change_addendum(i_lang                => i_lang,
                                                   i_prof                => i_prof,
                                                   i_flg_status_addendum => i_flg_status_addendum,
                                                   i_id_epis_addendum    => i_id_epis_addendum);
    
        --the edition and cancellation is only allowed when the addendums status = Draft    
        g_error := 'GET CURSOR o_actions';
        OPEN o_actions FOR
            SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
             id_action,
             id_parent,
             level_nr,
             from_state,
             to_state,
             desc_action,
             icon,
             flg_default,
             action,
             decode(l_change_addendum, 1, pk_alert_constant.g_active, pk_alert_constant.g_inactive) flg_active
              FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, pk_prog_notes_constants.g_acs_actions_addendums, NULL)) t
             WHERE (l_note_type_row.flg_sign_off = pk_alert_constant.g_yes OR
                   (l_note_type_row.flg_sign_off = pk_alert_constant.g_no AND t.action <> 'ACTION_SIGN_OFF_ADDENDUM'));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS_ADDENDUM',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_actions_addendum;

    /**************************************************************************
    * Return functionality help 
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_doc_area            Documentation area ID
    * 
    * @param   o_text                 Cursor with functionality help       
    * @param   o_error                Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/17                                 
    **************************************************************************/

    FUNCTION get_section_help_text
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_doc_area IN doc_area.id_doc_area%TYPE,
        o_text        OUT NOCOPY pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_SECTION_HELP_TEXT';
        l_id_profile_template profile_template.id_profile_template%TYPE;
        l_screen_name         summary_page_section.screen_name%TYPE;
        l_id_doc_area         summary_page_section.id_doc_area%TYPE;
    
    BEGIN
    
        g_error := 'GET ID_PROFILE_TEMPLATE';
    
        l_id_profile_template := pk_prof_utils.get_prof_profile_template(i_prof => i_prof);
    
        g_error := 'GET SCREEN NAME FOR ID_DOC_AREA ' || i_id_doc_area;
    
        BEGIN
            SELECT sps.screen_name, sps.id_doc_area
              INTO l_screen_name, l_id_doc_area
              FROM summary_page_section sps
             INNER JOIN summary_page_access spa
                ON spa.id_summary_page_section = sps.id_summary_page_section
             WHERE sps.id_doc_area = i_id_doc_area
               AND id_profile_template = l_id_profile_template
               AND sps.screen_name IS NOT NULL
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_screen_name := NULL;
        END;
    
        --remove .swf of screen name to get the code functionality help
        l_screen_name := regexp_replace(l_screen_name, '.swf');
    
        IF l_screen_name = 'EvaluationToolsCreate'
        THEN
            l_screen_name := l_screen_name || '_' || to_char(l_id_doc_area);
        END IF;
    
        g_error := 'CALL PK_FUNC_HELP.GET_HELP_TEXT';
        IF NOT pk_func_help.get_help_text(i_lang      => i_lang,
                                          i_prof      => i_prof,
                                          i_code_help => l_screen_name,
                                          o_text      => o_text,
                                          o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_types.open_my_cursor(i_cursor => o_text);
            RETURN FALSE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => l_function_name,
                                              o_error    => o_error);
            pk_types.open_my_cursor(i_cursor => o_text);
            RETURN FALSE;
    END get_section_help_text;

    /**************************************************************************
    * Get the period of time ( begin date and end date) during which a record
    * is available (called by import screen)
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode Identifier
    * @param i_begin_date             Begin date
    * @param i_end_date               End date    
    * @param i_flg_synchronized       Y-If Data Blocks info is to be synchronized with the directed areas, other than templates. N-otherwise
    * @param i_import_screen          Y- We are in the import screen: we . Should opens directly the edit screen. N-otherwize
    * @param i_action                 A-Auto-population; I-import
    * @param i_data_blocks            Data blocks to be imported
    * @param i_id_epis_pn_det_task    Task Ids that have to be syncronized
    * @param i_id_epis_pn             Note id
    * @param i_id_pn_note_type        Note type id
    * @param i_dt_proposed            note proposed date
    *
    * @param o_begin_date             Begin date  
    * @param o_end_date               End date    
    * @param o_error                  Error message
    *
    * @value i_flg_synchronized       {*} 'Y'- Yes {*} 'N'- no
    *                                                                         
    * @author                         Sofia Mendes                          
    * @version                        2.6.1.2                            
    * @since                          23/09/2011                                 
    **************************************************************************/
    FUNCTION get_import_dates
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_synchronized    IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_import_screen       IN VARCHAR2,
        i_action              IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_action_import,
        i_data_blocks         IN t_rec_data_blocks,
        i_id_epis_pn_det_task IN table_number,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE,
        i_dt_proposed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_note_date           OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_begin_date          OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date            OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_function_name CONSTANT VARCHAR2(30 CHAR) := 'GET_IMPORT_DATES';
    
        l_begin_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date   TIMESTAMP WITH LOCAL TIME ZONE;
    BEGIN
        g_error := 'id_pn_data_block: ' || i_data_blocks.id_pn_data_block || ' i_begin_date: ' || i_begin_date ||
                   ', i_end_date: ' || i_end_date || ', i_id_episode: ' || i_id_episode || ', i_dt_proposed: ' ||
                   i_dt_proposed || ', i_flg_synchronized: ' || i_flg_synchronized ||
                   ', i_data_blocks.id_pn_task_type: ' || i_data_blocks.id_pn_task_type ||
                   ', i_data_blocks.days_available_period: ' || i_data_blocks.days_available_period ||
                   ', i_import_screen: ' || i_import_screen || ', flg_auto_populated:' ||
                   i_data_blocks.flg_auto_populated;
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package,
                             sub_object_name => l_function_name,
                             owner           => g_owner);
    
        g_error := 'CALL check_date_filter_base()';
        IF NOT check_date_filter_base(i_lang                  => i_lang,
                                 i_prof                  => i_prof,
                                 i_id_episode            => i_id_episode,
                                 i_flg_filter            => CASE
                                                                WHEN i_action = pk_prog_notes_constants.g_flg_action_autopop THEN
                                                                 CASE
                                                                     WHEN pk_utils.str_token_find(i_string => i_data_blocks.flg_auto_populated,
                                                                                                  i_token  => pk_alert_constant.g_no,
                                                                                                  i_sep    => pk_prog_notes_constants.g_sep) =
                                                                          pk_alert_constant.g_no THEN
                                                                      i_data_blocks.flg_auto_populated
                                                                     ELSE
                                                                      i_data_blocks.flg_synchronized
                                                                 END
                                                                ELSE
                                                                 i_data_blocks.flg_import_filter
                                                            END,
                                 i_id_pn_note_type       => i_id_pn_note_type,
                                 i_id_epis_pn            => i_id_epis_pn,
                                 i_id_epis_pn_det_task   => i_id_epis_pn_det_task,
                                 i_dt_proposed           => i_dt_proposed,
                                 i_days_available_period => nvl(i_data_blocks.days_available_period, 0),
                                 o_begin_date            => l_begin_date,
                                 o_end_date              => l_end_date,
                                 o_note_date             => o_note_date,
                                 o_error                 => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (i_import_screen = pk_alert_constant.g_yes)
        THEN
            IF i_flg_synchronized = pk_alert_constant.g_yes
               AND (i_data_blocks.flg_data_removable <> pk_prog_notes_constants.g_flg_remove_no_remove_n OR
               i_data_blocks.review_context IS NOT NULL)
            THEN
                o_begin_date := NULL;
                o_end_date   := NULL;
            ELSIF i_flg_synchronized = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL pk_prog_notes_core.get_epis_dt_begin. i_episode: ' || i_id_episode;
                IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                         i_prof          => i_prof,
                                                         i_id_episode    => i_id_episode,
                                                         o_dt_begin_tstz => o_end_date,
                                                         o_error         => o_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                o_begin_date := NULL;
            ELSE
                o_begin_date := l_begin_date;
                o_end_date   := l_end_date;
            END IF;
        ELSE
            o_begin_date := l_begin_date;
            o_end_date   := l_end_date;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_import_dates;

    FUNCTION has_history_by_epis_pn
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
        
    ) RETURN BOOLEAN IS
    
        l_ret   BOOLEAN;
        l_count NUMBER := 0;
    
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM epis_pn_hist e
         WHERE e.id_epis_pn = i_epis_pn;
    
        IF l_count > 0
        THEN
            l_ret := TRUE;
        ELSE
            l_ret := FALSE;
        END IF;
    
        RETURN l_ret;
    
    END has_history_by_epis_pn;

    /**
    * Get detail/history signature line
    *
    * @param   i_lang                      Professional preferred language
    * @param   i_prof                      Professional identification and its context (institution and software)
    * @param   i_id_episode                Episode id
    * @param   i_id_prof_create            Professional that created the registry
    * @param   i_dt_create                 Creation date
    * @param   i_id_prof_last_update       Professional id that performed the last change
    * @param   i_dt_last_update            Last update date    
    * @param   i_id_prof_sign_off          Professional that signed off
    * @param   i_dt_sign_off               Sign off date
    * @param   i_id_prof_cancel            Professional that cancelled the registry
    * @param   i_dt_cancel                 Cancelation date
    * @param   i_id_dictation_report       Dictation report id
    *
    * @return  TRUE if sucess, FALSE otherwise
    *
    * @author  Sofia Mendes
    * @version v2.6.0.5
    * @since   18-Jan-2011
    */
    FUNCTION get_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_prof_create      IN professional.id_professional%TYPE,
        i_dt_create           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_update IN professional.id_professional%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_sign_off    IN professional.id_professional%TYPE,
        i_dt_sign_off         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_dt_cancel           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_dictation_report IN dictation_report.id_dictation_report%TYPE DEFAULT NULL,
        i_flg_history         IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_has_addendums       IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_id_software         IN software.id_software%TYPE DEFAULT NULL,
        i_id_prof_reviewed    IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_prof_submit      IN professional.id_professional%TYPE DEFAULT NULL,
        i_dt_submit           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_epis_pn             IN epis_pn.id_epis_pn%TYPE,
        i_flg_screen          IN VARCHAR2 DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_desc_signature sys_message.desc_message%TYPE;
    
        l_date      TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof   professional.id_professional%TYPE;
        l_code_desc sys_message.code_message%TYPE;
    
        l_id_prof_transcribed dictation_report.id_prof_transcribed%TYPE;
        l_id_dictation_report dictation_report.transcribed_date%TYPE;
        l_last_update_date_dr dictation_report.last_update_date%TYPE;
        l_error               t_error_out;
        l_is_dictation        BOOLEAN := FALSE;
        l_dictated_date       dictation_report.dictated_date%TYPE;
        l_signoff_date        dictation_report.signoff_date%TYPE;
        l_action              VARCHAR2(1);
        l_action_sign_off  CONSTANT VARCHAR2(1) := 'S';
        l_action_insertion CONSTANT VARCHAR2(1) := 'I';
        l_action_update    CONSTANT VARCHAR2(1) := 'U';
    BEGIN
        IF (i_id_prof_cancel IS NOT NULL AND i_dt_cancel IS NOT NULL)
        THEN
            l_id_prof   := i_id_prof_cancel;
            l_date      := i_dt_cancel;
            l_code_desc := 'PN_M003';
        ELSIF (i_id_prof_sign_off IS NOT NULL AND i_dt_sign_off IS NOT NULL)
        THEN
            l_id_prof   := i_id_prof_sign_off;
            l_date      := i_dt_sign_off;
            l_code_desc := 'PN_M027';
            l_action    := l_action_sign_off;
        ELSIF (i_id_prof_submit IS NOT NULL AND i_dt_submit IS NOT NULL AND
              i_dt_submit >= nvl(i_dt_last_update, i_dt_submit))
        THEN
            l_id_prof   := i_id_prof_submit;
            l_date      := i_dt_submit;
            l_code_desc := 'PN_M057';
            l_action    := l_action_sign_off;
        ELSIF (i_id_prof_reviewed IS NOT NULL AND i_dt_reviewed IS NOT NULL AND
              i_dt_reviewed >= nvl(i_dt_last_update, i_dt_reviewed))
        THEN
            l_id_prof   := i_id_prof_reviewed;
            l_date      := i_dt_reviewed;
            l_code_desc := 'PN_M004';
            l_action    := l_action_update;
        ELSIF (i_id_prof_last_update IS NOT NULL AND i_dt_last_update IS NOT NULL AND
              (has_history_by_epis_pn(i_lang, i_prof, i_epis_pn) OR (i_flg_screen = 'D' OR i_flg_screen IS NULL)))
        THEN
            l_id_prof   := i_id_prof_last_update;
            l_date      := i_dt_last_update;
            l_code_desc := 'PN_M004';
            l_action    := l_action_update;
        ELSIF (i_id_prof_create IS NOT NULL AND i_dt_create IS NOT NULL)
        THEN
            l_id_prof   := i_id_prof_create;
            l_date      := i_dt_create;
            l_code_desc := 'PN_M001';
            l_action    := l_action_insertion;
        END IF;
    
        g_error          := 'CALL get_signature_text: i_id_prof: ' || l_id_prof;
        l_desc_signature := pk_inp_detail.get_signature(i_lang                => i_lang,
                                                        i_prof                => i_prof,
                                                        i_id_episode          => i_id_episode,
                                                        i_id_prof_last_change => l_id_prof,
                                                        i_date                => l_date,
                                                        i_code_desc           => l_code_desc,
                                                        i_id_software         => i_id_software);
    
        IF (i_id_dictation_report IS NOT NULL)
        THEN
            --it is necessary to get data from the dictation history if it is an action performed after the note created or 
            -- the actual state of the note and the note has addendums
            IF (i_flg_history = pk_alert_constant.g_yes OR i_has_addendums = pk_alert_constant.g_yes)
            THEN
                g_error := 'CALL pk_dictation.get_transcribe_info_hist. i_id_dictation_report: ' ||
                           i_id_dictation_report;
                IF NOT pk_dictation.get_transcribe_info_hist(i_lang                => i_lang,
                                                        i_dictation_report    => i_id_dictation_report,
                                                        i_dt_last_update      => CASE
                                                                                     WHEN l_action = l_action_update THEN
                                                                                      i_dt_last_update
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                        i_signoff_date        => CASE
                                                                                     WHEN l_action = l_action_sign_off THEN
                                                                                      i_dt_sign_off
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                        i_dictated_date       => CASE
                                                                                     WHEN l_action = l_action_insertion THEN
                                                                                      i_dt_create
                                                                                     ELSE
                                                                                      NULL
                                                                                 END,
                                                        o_id_prof_transcribed => l_id_prof_transcribed,
                                                        o_transcribed_date    => l_id_dictation_report,
                                                        o_last_update_date    => l_last_update_date_dr,
                                                        o_dictated_date       => l_dictated_date,
                                                        o_signoff_date        => l_signoff_date,
                                                        o_error               => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            
                --in case the note was created by interface ant it was updated in the application
                --there is no history in the dictation table
                IF (l_id_prof_transcribed IS NULL AND l_id_dictation_report IS NULL AND l_last_update_date_dr IS NULL AND
                   l_dictated_date IS NULL AND l_signoff_date IS NULL)
                THEN
                    g_error := 'CALL pk_dictation.get_transcribe_info. i_id_dictation_report: ' ||
                               i_id_dictation_report;
                    IF NOT pk_dictation.get_transcribe_info(i_lang                => i_lang,
                                                            i_dictation_report    => i_id_dictation_report,
                                                            o_id_prof_transcribed => l_id_prof_transcribed,
                                                            o_transcribed_date    => l_id_dictation_report,
                                                            o_last_update_date    => l_last_update_date_dr,
                                                            o_dictated_date       => l_dictated_date,
                                                            o_signoff_date        => l_signoff_date,
                                                            o_error               => l_error)
                    THEN
                        RAISE g_exception;
                    END IF;
                END IF;
            
            ELSE
                g_error := 'CALL pk_dictation.get_transcribe_info. i_id_dictation_report: ' || i_id_dictation_report;
                IF NOT pk_dictation.get_transcribe_info(i_lang                => i_lang,
                                                        i_dictation_report    => i_id_dictation_report,
                                                        o_id_prof_transcribed => l_id_prof_transcribed,
                                                        o_transcribed_date    => l_id_dictation_report,
                                                        o_last_update_date    => l_last_update_date_dr,
                                                        o_dictated_date       => l_dictated_date,
                                                        o_signoff_date        => l_signoff_date,
                                                        o_error               => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        END IF;
    
        IF ((l_action = l_action_insertion AND i_dt_create = l_dictated_date) OR
           (l_action = l_action_update AND i_dt_last_update = l_last_update_date_dr) OR
           (l_action = l_action_sign_off AND i_dt_sign_off = l_signoff_date))
        THEN
            l_is_dictation := TRUE;
        END IF;
    
        IF (l_is_dictation = TRUE)
        THEN
            g_error          := 'CALL get_signature_text: i_id_prof: ' || l_id_prof_transcribed;
            l_desc_signature := l_desc_signature || chr(10) ||
                                pk_inp_detail.get_signature(i_lang                => i_lang,
                                                            i_prof                => i_prof,
                                                            i_id_episode          => i_id_episode,
                                                            i_id_prof_last_change => l_id_prof_transcribed,
                                                            i_date                => l_id_dictation_report,
                                                            i_code_desc           => 'DICTATION_REPORT_002');
        END IF;
    
        RETURN l_desc_signature;
    
    END get_signature;

    /**
    * Check the note type.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_epis_pn                 Note identifier    
    *
    * @return               note type id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE DEFAULT NULL
    ) RETURN epis_pn.id_pn_note_type%TYPE IS
        l_id_pn_note_type epis_pn.id_pn_note_type%TYPE;
    BEGIN
    
        g_error := 'GET note type. i_id_epis_pn: ' || i_id_epis_pn;
        SELECT e.id_pn_note_type
          INTO l_id_pn_note_type
          FROM epis_pn e
         WHERE e.id_epis_pn = i_id_epis_pn;
    
        RETURN l_id_pn_note_type;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'NOTE TYPE not found i_id_epis_pn: ' || i_id_epis_pn;
        
            RETURN NULL;
    END get_note_type;

    /**
    * Get the note type description.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_pn_note_type            Note type description    
    * @param i_flg_code_note_type         Indicates the desired description    
    *
    * @return               note type desc
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_pn_note_type    IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_code_note_type IN VARCHAR2
    ) RETURN pk_translation.t_desc_translation IS
        l_desc_note_type pk_translation.t_desc_translation;
        l_error          t_error_out;
    BEGIN
    
        g_error := 'GET note type desc. i_id_pn_note_type: ' || i_id_pn_note_type;
        SELECT pk_message.get_message(i_lang,
                                      i_prof,
                                      decode(i_flg_code_note_type,
                                             pk_prog_notes_constants.g_flg_code_note_type_desc_d,
                                             nt.code_pn_note_type,
                                             pk_prog_notes_constants.g_flg_code_note_type_signoff_s,
                                             nt.code_sign_off_desc,
                                             pk_prog_notes_constants.g_flg_code_note_type_cancel_d,
                                             nt.code_cancel_desc,
                                             pk_prog_notes_constants.g_flg_code_note_type_edit_e,
                                             nt.code_edit_desc,
                                             pk_prog_notes_constants.g_flg_code_note_type_add_a,
                                             nt.code_add_action))
          INTO l_desc_note_type
          FROM pn_note_type nt
         WHERE nt.id_pn_note_type = i_id_pn_note_type;
    
        RETURN l_desc_note_type;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_TYPE_DESC',
                                              l_error);
        
            RETURN NULL;
    END get_note_type_desc;

    /**
    * Get note type configs.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_episode                 episode id
    * @param i_id_profile_template        profile template id
    * @param i_id_market                  Market id
    * @param i_id_department              Department id
    * @param i_id_category                Category id
    * @param i_id_dep_clin_serv           Dep_clin_serv id
    * @param i_id_epis_pn                 Note identifier    
    * @param i_area                       Area internal name
    * @param i_software                   Software ID
    *
    * @return               note type configs
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_note_type_config
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_profile_template IN profile_template.id_profile_template%TYPE,
        i_id_market           IN market.id_market%TYPE,
        i_id_department       IN department.id_department%TYPE,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_pn_note_type     IN pn_note_type.id_pn_note_type%TYPE DEFAULT NULL,
        i_software            IN software.id_software%TYPE
    ) RETURN t_rec_note_type IS
        l_id_pn_note_type epis_pn.id_pn_note_type%TYPE;
        l_error           t_error_out;
        l_note_type_row   t_rec_note_type;
        l_id_episode      episode.id_episode%TYPE;
    BEGIN
        IF (i_id_episode IS NULL AND i_id_epis_pn IS NOT NULL)
        THEN
            g_error      := 'CALL get_note_episode. i_id_epis_pn: ' || i_id_epis_pn;
            l_id_episode := get_note_episode(i_lang => i_lang, i_prof => i_prof, i_id_epis_pn => i_id_epis_pn);
        
        ELSE
            l_id_episode := i_id_episode;
        END IF;
    
        IF (i_id_pn_note_type IS NULL)
        THEN
            g_error           := 'CALL get_note_type. i_id_epis_pn: ' || i_id_epis_pn;
            l_id_pn_note_type := get_note_type(i_lang => i_lang, i_prof => i_prof, i_id_epis_pn => i_id_epis_pn);
        ELSE
            l_id_pn_note_type := i_id_pn_note_type;
        END IF;
    
        g_error := 'CALL pk_progress_notes_upd.tf_pn_note_type. i_id_episode: ' || i_id_episode ||
                   ' l_id_pn_note_type: ' || l_id_pn_note_type;
        SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
         t_rec_note_type(id_pn_area,
                         id_pn_note_type,
                         rank,
                         max_nr_notes,
                         max_nr_draft_notes,
                         max_nr_draft_addendums,
                         flg_addend_other_prof,
                         flg_show_empty_blocks,
                         flg_import_available,
                         flg_sign_off_login_avail,
                         flg_last_24h,
                         flg_dictation_editable,
                         flg_clear_information,
                         flg_review_all,
                         flg_edit_after_disch,
                         flg_import_first,
                         flg_write,
                         flg_copy_edit_replace,
                         gender,
                         age_min,
                         age_max,
                         flg_expand_sblocks,
                         flg_synchronized,
                         flg_show_import_menu,
                         flg_edit_other_prof,
                         flg_create_on_app,
                         flg_autopop_warning,
                         flg_discharge_warning,
                         flg_disch_warning_option,
                         flg_review_warning,
                         flg_review_warn_option,
                         flg_import_warning,
                         flg_help_save,
                         flg_edit_only_last,
                         flg_save_only_screen,
                         flg_status_available,
                         flg_partial_warning,
                         flg_remove_on_ok,
                         editable_nr_min,
                         flg_suggest_concept,
                         flg_review_on_ok,
                         flg_partial_load,
                         flg_viewer_type,
                         flg_sign_off,
                         flg_type,
                         flg_cancel,
                         flg_submit,
                         cal_delay_time,
                         cal_icu_delay_time,
                         flg_cal_time_filter,
                         flg_sync_after_disch,
                         flg_edit_condition,
                         flg_patient_id_warning,
                         flg_show_signature,
                         flg_show_free_text)
          INTO l_note_type_row
          FROM TABLE(tf_pn_note_type(i_lang                => i_lang,
                                     i_prof                => i_prof,
                                     i_id_episode          => l_id_episode,
                                     i_id_profile_template => i_id_profile_template,
                                     i_id_market           => i_id_market,
                                     i_id_department       => i_id_department,
                                     i_id_dep_clin_serv    => i_id_dep_clin_serv,
                                     i_id_category         => i_id_category,
                                     i_area                => NULL,
                                     i_id_note_type        => l_id_pn_note_type,
                                     i_flg_scope           => pk_prog_notes_constants.g_pn_flg_scope_notetype_n,
                                     i_software            => i_software)) t
         WHERE rownum = 1;
    
        RETURN l_note_type_row;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_TYPE_CONFIG',
                                              l_error);
        
            RETURN NULL;
    END get_note_type_config;

    /**
    * Get Area configs.
    *
    * @param i_lang                       Language identifier
    * @param i_prof                       Logged professional structure
    * @param i_id_episode                 Episode id
    * @param i_id_market                  Market id
    * @param i_id_department              Department id
    * @param i_id_dep_clin_serv           Dep_clin_serv id
    * @param i_area                       Area internal name
    * @param i_episode_software          Software ID associated to the episode
    *
    * @return                             Area configs
    *
    * @author                             Ant? Neto
    * @version                            2.6.1.2
    * @since                              28-Jul-2011
    */
    FUNCTION get_area_config
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_area             IN pn_area.internal_name%TYPE,
        i_episode_software IN software.id_software%TYPE
    ) RETURN t_rec_area IS
        l_error     t_error_out;
        l_coll_area t_coll_area;
    BEGIN
    
        g_error     := 'CALL pk_progress_notes_upd.tf_pn_area. i_id_episode: ' || i_id_episode || ' i_area: ' || i_area;
        l_coll_area := tf_pn_area(i_lang             => i_lang,
                                  i_prof             => i_prof,
                                  i_id_episode       => i_id_episode,
                                  i_id_market        => i_id_market,
                                  i_id_department    => i_id_department,
                                  i_id_dep_clin_serv => i_id_dep_clin_serv,
                                  i_area             => i_area,
                                  i_episode_software => i_episode_software);
    
        IF (l_coll_area.exists(1))
        THEN
            RETURN l_coll_area(1);
        ELSE
            RETURN NULL;
        END IF;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_AREA_CONFIG',
                                              l_error);
        
            RETURN NULL;
    END get_area_config;

    /********************************************************************************************
    * Checks if the Progress Note info (for Note Types or Data Blocks) is valid compared with Patient info
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PN_AGE_MIN            PN minimum age accepted
    * @param I_PN_AGE_MAX            PN maximum age accepted
    * @param I_PN_GENDER             PN gender accepted
    * @param I_PAT_AGE               Patient age
    * @param I_PAT_GENDER            Patient gender
    *
    * @return                        Returns 'Y' if validation passed, otherwise returns 'N'
    *
    * @author                        Ant? Neto
    * @since                         04-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION check_pn_with_patient_info
    (
        i_lang       IN language.id_language%TYPE,
        i_pn_age_min IN NUMBER,
        i_pn_age_max IN NUMBER,
        i_pn_gender  IN VARCHAR2,
        i_pat_age    IN patient.age%TYPE,
        i_pat_gender IN patient.gender%TYPE
    ) RETURN VARCHAR2 IS
        l_general_exception EXCEPTION;
        l_error t_error_out;
    BEGIN
    
        --check patient gender with the data of the progress note (note type or data block)
        g_error := 'Call PK_PATIENT.VALIDATE_PAT_GENDER';
        IF pk_patient.validate_pat_gender(i_pat_gender, i_pn_gender) = 0
        THEN
            RETURN pk_alert_constant.g_no;
        END IF;
    
        --check patient age with the PN age_min and age_max
        IF ((i_pn_age_min IS NULL OR i_pn_age_min <= i_pat_age) AND (i_pn_age_max IS NULL OR i_pn_age_max >= i_pat_age))
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
        --everything passed, so is a valid patient for th PN
        RETURN pk_alert_constant.g_yes;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_PN_WITH_PATIENT_INFO',
                                              l_error);
        
            RETURN pk_alert_constant.g_no;
    END check_pn_with_patient_info;

    /********************************************************************************************
    * Checks if patient has discharge (in episode) and if note type doesn't allow editions after discharge remove the permissions
    *
    * @param I_EDITABLE_AFTER_DISCHARGE      Flag Edition After Discharge from the note type
    * @param I_DISCH_STATUS                  Flag Discharge Status from the episode
    *
    * @return                                Returns 'Y' if Flag Edition After Discharge is ON (Y) or patient hasn't discharge, otherwise returns 'N'
    *
    * @author                                Ant? Neto
    * @since                                 05-Aug-2011
    * @version                               2.6.1.2
    ********************************************************************************************/
    FUNCTION get_discharge_note_status
    (
        i_editable_after_discharge IN VARCHAR2,
        i_is_dicharged             IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF (i_editable_after_discharge = pk_alert_constant.g_yes)
        THEN
            RETURN pk_prog_notes_constants.g_editable_all;
        ELSE
            IF (i_is_dicharged = pk_alert_constant.g_yes)
            THEN
                RETURN pk_alert_constant.g_no;
            ELSE
                RETURN pk_prog_notes_constants.g_editable_all;
            END IF;
        END IF;
    END get_discharge_note_status;

    /********************************************************************************************
    * Gets the Area Description by the Note Type ID or directly by the Area ID
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_ID_PN_NOTE_TYPE       Note Type identifier
    * @param I_ID_PN_AREA            Note Area identifier
    *
    * @return                        Area description
    *
    * @author                        Ant? Neto
    * @since                         08-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/
    FUNCTION get_area_desc_by_note_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_area      IN pn_area.id_pn_area%TYPE
    ) RETURN VARCHAR2 IS
        l_desc_area VARCHAR2(4000 CHAR);
        l_ids_not_defined EXCEPTION;
    BEGIN
        IF i_id_pn_area IS NULL
           AND i_id_pn_note_type IS NOT NULL
        THEN
            SELECT /*pk_translation.get_translation(i_lang, pna.code_pn_area)*/
             pk_message.get_message(i_lang, i_prof, pna.code_pn_area)
              INTO l_desc_area
              FROM pn_area pna
             WHERE pna.id_pn_area IN (SELECT /*+ OPT_ESTIMATE (TABLE tf ROWS=1)*/
                                       tf.id_pn_area
                                        FROM TABLE(tf_pn_note_type(i_lang,
                                                                   i_prof,
                                                                   i_id_episode,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   NULL,
                                                                   i_id_pn_note_type,
                                                                   pk_prog_notes_constants.g_pn_flg_scope_notetype_n,
                                                                   i_software => NULL)) tf)
               AND rownum = 1;
        ELSIF i_id_pn_area IS NOT NULL
        THEN
            SELECT /*pk_translation.get_translation(i_lang, pna.code_pn_area)*/
             pk_message.get_message(i_lang, i_prof, pna.code_pn_area)
              INTO l_desc_area
              FROM pn_area pna
             WHERE pna.id_pn_area = i_id_pn_area;
        ELSE
            g_error := 'Identifiers (i_id_pn_note_type, i_id_pn_area) not defined';
            RAISE l_ids_not_defined;
        END IF;
    
        RETURN l_desc_area;
    END get_area_desc_by_note_type;

    /********************************************************************************************
    * Get the software descrition (abbreviation) of the sw associated to the given episode
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        SW description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_epis_sw_abbr
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_software software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_desc  pk_translation.t_desc_translation;
        l_error t_error_out;
    BEGIN
        g_error := 'GET the sw description. i_id_episode: ' || i_id_episode;
        l_desc  := pk_message.get_message(i_lang,
                                          profissional(i_prof.id,
                                                       i_prof.institution,
                                                       nvl(i_id_software,
                                                           pk_episode.get_episode_software(i_lang       => i_lang,
                                                                                           i_prof       => i_prof,
                                                                                           i_id_episode => i_id_episode))),
                                          'IMAGE_T009');
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_SW_ABBR',
                                              l_error);
            RETURN NULL;
    END get_epis_sw_abbr;

    /********************************************************************************************
    * Get the software descrition of the sw associated to the given episode
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        SW description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_epis_sw_desc
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_desc       pk_translation.t_desc_translation;
        l_error      t_error_out;
        l_id_epis_sw software.id_software%TYPE;
    BEGIN
        g_error      := 'CALL pk_episode.get_episode_software. i_id_episode: ' || i_id_episode;
        l_id_epis_sw := pk_episode.get_episode_software(i_lang       => i_lang,
                                                        i_prof       => i_prof,
                                                        i_id_episode => i_id_episode);
    
        g_error := 'GET the sw description. i_id_episode: ' || i_id_episode;
        SELECT pk_translation.get_translation(i_lang, s.code_software)
          INTO l_desc
          FROM software s
         WHERE s.id_software = l_id_epis_sw;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_EPIS_SW_ABBR',
                                              l_error);
            RETURN NULL;
    END get_epis_sw_desc;

    /********************************************************************************************
    * Get the date description that appears on the notes viewer
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_EPISODE            Episode identifier
    * @param I_DATE                  Last update note date
    *
    * @return                        DAte description
    *
    * @author                        Sofia Mendes
    * @since                         13-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_viewer_date_desc
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_date        IN epis_pn.dt_create%TYPE,
        i_id_software software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_desc  pk_translation.t_desc_translation;
        l_error t_error_out;
    BEGIN
        g_error := 'GET the viewer date description. i_id_episode: ' || i_id_episode;
        l_desc  := pk_prog_notes_utils.get_epis_sw_abbr(i_lang        => i_lang,
                                                        i_prof        => i_prof,
                                                        i_id_episode  => i_id_episode,
                                                        i_id_software => i_id_software) || '; ' ||
                   pk_date_utils.date_char_tsz(i_lang, i_date, i_prof.institution, i_prof.software);
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_VIEWER_DATE_DESC',
                                              l_error);
            RETURN NULL;
    END get_viewer_date_desc;

    /********************************************************************************************
    * Get the note date to be considered on viewer. single page: last update date. Single note: note date
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_flg_synchronized      Y-Single page; N-Single note
    * @param i_dt_pn_date            Note date
    * @param i_dt_signoff            Signoff date
    * @param i_dt_last_update        Last update date
    * @param i_dt_create             
    *
    * @return                        DAte description
    *
    * @author                        Sofia Mendes
    * @since                         17-Jul-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_note_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_synchronized IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_dt_pn_date       IN epis_pn.dt_pn_date%TYPE,
        i_dt_signoff       IN epis_pn.dt_signoff%TYPE,
        i_dt_last_update   IN epis_pn.dt_last_update%TYPE,
        i_dt_create        IN epis_pn.dt_create%TYPE
    ) RETURN epis_pn.dt_create%TYPE IS
        l_error   t_error_out;
        l_dt_note epis_pn.dt_create%TYPE;
    BEGIN
        g_error := 'GET the note date. i_flg_synchronized: ' || i_flg_synchronized;
        --single page
        IF (i_flg_synchronized = pk_alert_constant.g_yes)
        THEN
            l_dt_note := coalesce(i_dt_signoff, i_dt_last_update, i_dt_create);
        ELSE
            --single note
            l_dt_note := i_dt_pn_date;
        END IF;
    
        RETURN l_dt_note;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_DATE',
                                              l_error);
            RETURN NULL;
    END get_note_date;

    /********************************************************************************************
    * Gets a summary of PN Notes for a Patient
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param I_ID_PN_AREA            Area Identifier to filter on    
    * @param I_SCOPE                 Scope ID
    *                                     E-Episode ID
    *                                     V-Visit ID
    *                                     P-Patient ID
    * @param I_SCOPE_TYPE            Scope type
    *                                     E-Episode
    *                                     V-Visit
    *                                     P-Patient
    * @param I_FLG_SCOPE             Flag to filter the scope
    *                                     S-Summary 1.st level (last Note)
    *                                     D-Detailed 2.nd level (Last Note by each Area)
    *                                     C-Complete 3.rd level (All Notes for Note Type selected)
    * @param I_INTERVAL             Interval to filter
    *                                     D-Last 24H
    *                                     W-Week
    *                                     M-Month
    *                                     A-All
    * @param O_DATA                  Cursor with PN Data to show
    * @param O_TITLE                 Variable that indicates the title that should appear on viewer
    * @param O_SCREEN_NAME           Variable that indicates the Area SWF Screen Name
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Ant? Neto
    * @since                         08-Aug-2011
    * @version                       2.6.1.2
    ********************************************************************************************/

    --ARGS: [8,[7020000760725,11111,36],null,7895565,"P","T",null,null]
    FUNCTION get_viewer_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_area      IN pn_area.id_pn_area%TYPE,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_flg_scope       IN VARCHAR2,
        i_interval        IN VARCHAR2,
        i_flg_viewer_type IN pn_note_type.flg_viewer_type%TYPE DEFAULT NULL,
        o_data            OUT NOCOPY pk_types.cursor_type,
        o_title           OUT NOCOPY sys_message.desc_message%TYPE,
        o_screen_name     OUT NOCOPY pn_area.screen_name%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_scope_not_valid EXCEPTION;
        l_epis_ids     t_coll_pn_vs_viewer;
        l_epis_ids_sel t_coll_pn_vs_viewer;
        l_id_epis_pn   epis_pn.id_epis_pn%TYPE;
        l_note_date    epis_pn.dt_pn_date%TYPE;
        l_tot_records  PLS_INTEGER;
        l_nr_records   PLS_INTEGER;
        l_title        VARCHAR2(200 CHAR);
    
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
        l_id_visit   visit.id_visit%TYPE;
    
        l_dt_begin TIMESTAMP WITH LOCAL TIME ZONE;
        l_dt_end   TIMESTAMP WITH LOCAL TIME ZONE;
    
        e_invalid_argument EXCEPTION;
        l_sd_flg_viewer_type sys_domain.code_domain%TYPE := 'PN_NOTE_TYPE.FLG_VIEWER_TYPE';
    BEGIN
        g_error := 'ANALYSING SCOPE TYPE';
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE e_invalid_argument;
        END IF;
    
        g_error := 'CALCULATE THE INTERVAL FOR DATES';
        CASE i_interval
            WHEN pk_prog_notes_constants.g_interval_last24h_d THEN
                --D-Last 24H
                l_dt_begin := pk_date_utils.add_days_to_tstz(current_timestamp, -1);
                l_dt_end   := current_timestamp;
            WHEN pk_prog_notes_constants.g_interval_week_w THEN
                --W-Week
                l_dt_begin := pk_date_utils.add_days_to_tstz(current_timestamp, -7);
                l_dt_end   := current_timestamp;
            WHEN pk_prog_notes_constants.g_interval_month_m THEN
                --M-Month
                l_dt_begin := pk_date_utils.non_ansi_add_months(i_lang         => i_lang,
                                                                i_prof         => i_prof,
                                                                i_date         => current_timestamp,
                                                                i_nr_of_months => -1,
                                                                o_error        => o_error);
                l_dt_end   := current_timestamp;
            ELSE
                --A-All or NULL
                l_dt_begin := NULL;
                l_dt_end   := NULL;
        END CASE;
    
        --Summary 1.st level (last Note)
        IF i_flg_scope = pk_prog_notes_constants.g_flg_scope_summary_s
        THEN
            --Get PN Identifiers
            g_error := 'Get PN Identifiers for the patient: ' || l_id_patient;
            SELECT t_rec_pn_vs_viewer(t_epn.id_epis_pn, NULL, NULL, NULL, t_epn.note_date)
              BULK COLLECT
              INTO l_epis_ids
              FROM (SELECT t.*, row_number() over(ORDER BY t.note_date DESC NULLS LAST) rn
                      FROM (SELECT epn.id_epis_pn,
                                   coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create) note_date
                              FROM epis_pn epn
                             INNER JOIN episode epis
                                ON epn.id_episode = epis.id_episode
                             WHERE epn.flg_status IN
                                   (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                    pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                    pk_prog_notes_constants.g_epis_pn_flg_submited,
                                    pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
                               AND epis.id_episode = nvl(l_id_episode, epis.id_episode)
                               AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                               AND epis.id_patient = l_id_patient) t
                     WHERE t.note_date BETWEEN nvl(l_dt_begin, t.note_date) AND nvl(l_dt_end, t.note_date)) t_epn
             ORDER BY t_epn.rn;
        
            l_tot_records := l_epis_ids.count;
            IF l_tot_records = 0
            THEN
                l_id_epis_pn := 0;
                l_note_date  := NULL;
            ELSE
                l_id_epis_pn := l_epis_ids(1).id_pn_vs;
                l_note_date  := l_epis_ids(1).note_date;
            END IF;
        
            g_error := 'Get Sys_message for Title';
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_prog_notes_constants.g_sm_notes);
        
            g_error := 'Get Data for Summary screen';
            OPEN o_data FOR
                SELECT get_area_desc_by_note_type(i_lang, i_prof, en.id_episode, en.id_pn_note_type, en.id_pn_area) desc_area,
                       NULL code_area,
                       l_tot_records num_records,
                       pk_prog_notes_utils.get_viewer_date_desc(i_lang,
                                                                i_prof,
                                                                en.id_episode,
                                                                l_note_date,
                                                                en.id_software) dt_changed_str,
                       pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type) note_desc,
                       pk_date_utils.date_send_tsz(i_lang, l_note_date, i_prof) changed_str,
                       l_note_date date_tstz,
                       en.id_epis_pn,
                       en.id_episode
                  FROM epis_pn en
                 INNER JOIN pn_note_type pnt
                    ON en.id_pn_note_type = pnt.id_pn_note_type
                 WHERE en.id_epis_pn = l_id_epis_pn;
        
            --Detailed 2.nd level (Last Note by each Area)
        ELSIF i_flg_scope = pk_prog_notes_constants.g_flg_scope_detail_d
        THEN
            --Get PN Identifiers
            g_error := 'Get PN Identifiers for the patient: ' || l_id_patient;
        
            SELECT t_rec_pn_vs_viewer(id_epis_pn,
                                       CASE
                                           WHEN rn <> 1 THEN
                                            0
                                           ELSE
                                            1
                                       END,
                                       id_pn_area,
                                       NULL,
                                       t_epnrn.note_date)
              BULK COLLECT
              INTO l_epis_ids
              FROM (SELECT t.*, row_number() over(PARTITION BY t.id_pn_area ORDER BY t.note_date DESC NULLS LAST) rn
                      FROM (SELECT epn.id_epis_pn,
                                   epn.id_pn_area,
                                   coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create) note_date
                              FROM epis_pn epn
                             INNER JOIN episode epis
                                ON epn.id_episode = epis.id_episode
                              JOIN pn_note_type nt
                                ON nt.id_pn_note_type = epn.id_pn_note_type
                               AND nt.flg_viewer_type = nvl(i_flg_viewer_type, nt.flg_viewer_type)
                             WHERE epn.flg_status IN
                                   (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                    pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                    pk_prog_notes_constants.g_epis_pn_flg_submited,
                                    pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
                               AND epis.id_episode = nvl(l_id_episode, epis.id_episode)
                               AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                               AND epis.id_patient = l_id_patient) t
                     WHERE t.note_date BETWEEN nvl(l_dt_begin, t.note_date) AND nvl(l_dt_end, t.note_date)
                     ORDER BY rn) t_epnrn
             ORDER BY rn,
                      CASE
                          WHEN rn <> 1 THEN
                           0
                          ELSE
                           1
                      END,
                      id_pn_area,
                      id_epis_pn;
        
            l_tot_records := l_epis_ids.count;
        
            l_epis_ids_sel := t_coll_pn_vs_viewer();
            IF l_tot_records = 0
            THEN
                l_epis_ids_sel.extend();
                l_epis_ids_sel(1) := t_rec_pn_vs_viewer(0, NULL, NULL, NULL, NULL);
            ELSE
            
                FOR i IN 1 .. l_tot_records
                LOOP
                    IF l_epis_ids(i).rank = 1
                    THEN
                        SELECT COUNT(t_ids.id_pn_vs)
                          INTO l_nr_records
                          FROM TABLE(l_epis_ids) t_ids
                         WHERE t_ids.id_group = l_epis_ids(i).id_group;
                    
                        l_epis_ids_sel.extend();
                        l_epis_ids_sel(i) := t_rec_pn_vs_viewer(l_epis_ids  (i).id_pn_vs,
                                                                i,
                                                                l_epis_ids  (i).id_group,
                                                                l_nr_records,
                                                                l_epis_ids  (i).note_date);
                    
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            g_error := 'Get Sys_message for Title';
            IF i_flg_viewer_type IS NULL
            THEN
                l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_prog_notes_constants.g_sm_notes);
            ELSE
                l_title := pk_sysdomain.get_domain(l_sd_flg_viewer_type, i_flg_viewer_type, i_lang);
            END IF;
        
            g_error := 'Get Data for Detailed screen';
            OPEN o_data FOR
                SELECT t_ids_sel.nr_records num_records,
                       pk_prog_notes_utils.get_viewer_date_desc(i_lang,
                                                                i_prof,
                                                                epn.id_episode,
                                                                t_ids_sel.note_date,
                                                                epn.id_software) dt_changed_str,
                       get_area_desc_by_note_type(i_lang, i_prof, epn.id_episode, NULL, t_ids_sel.id_group) desc_area,
                       t_ids_sel.id_group id_area,
                       pk_date_utils.date_send_tsz(i_lang, t_ids_sel.note_date, i_prof) changed_str,
                       epn.id_epis_pn,
                       epn.id_episode,
                       (SELECT pa.id_sys_shortcut
                          FROM pn_area pa
                         WHERE pa.id_pn_area = t_ids_sel.id_group) id_sys_shortcut
                  FROM TABLE(l_epis_ids_sel) t_ids_sel
                  JOIN epis_pn epn
                    ON t_ids_sel.id_pn_vs = epn.id_epis_pn
                  JOIN pn_note_type pnt
                    ON epn.id_pn_note_type = pnt.id_pn_note_type
                  JOIN pn_area a
                    ON a.id_pn_area = t_ids_sel.id_group
                 ORDER BY a.rank, t_ids_sel.rank;
            --------------------------------------------
            --group by flg_note_type
        ELSIF i_flg_scope = pk_prog_notes_constants.g_flg_scope_type_t
        THEN
            --Get PN Identifiers
            g_error := 'Get PN Identifiers for the patient: ' || l_id_patient;
        
            SELECT t_rec_pn_vs_viewer(id_epis_pn,
                                       CASE
                                           WHEN rn <> 1 THEN
                                            0
                                           ELSE
                                            1
                                       END,
                                       flg_viewer_type,
                                       NULL,
                                       t_epnrn.note_date)
              BULK COLLECT
              INTO l_epis_ids
              FROM (SELECT t.*,
                           row_number() over(PARTITION BY t.flg_viewer_type ORDER BY t.flg_viewer_type, t.note_date DESC NULLS LAST) rn
                      FROM (SELECT epn.id_epis_pn,
                                   pnt.flg_viewer_type flg_viewer_type,
                                   coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create) note_date
                              FROM epis_pn epn
                              JOIN episode epis
                                ON epn.id_episode = epis.id_episode
                              JOIN pn_note_type pnt
                                ON epn.id_pn_note_type = pnt.id_pn_note_type
                               AND pnt.flg_viewer_type = nvl(i_flg_viewer_type, pnt.flg_viewer_type)
                             WHERE epn.flg_status IN
                                   (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                    pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                    pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                    pk_prog_notes_constants.g_epis_pn_flg_submited,
                                    pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
                               AND epis.id_episode = nvl(l_id_episode, epis.id_episode)
                               AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                               AND epis.id_patient = l_id_patient) t
                     WHERE t.note_date BETWEEN nvl(l_dt_begin, t.note_date) AND nvl(l_dt_end, t.note_date)
                     ORDER BY rn) t_epnrn
             ORDER BY rn,
                      CASE
                          WHEN rn <> 1 THEN
                           0
                          ELSE
                           1
                      END,
                      flg_viewer_type,
                      id_epis_pn;
        
            l_tot_records := l_epis_ids.count;
        
            l_epis_ids_sel := t_coll_pn_vs_viewer();
            IF l_tot_records = 0
            THEN
                l_epis_ids_sel.extend();
                l_epis_ids_sel(1) := t_rec_pn_vs_viewer(0, NULL, NULL, NULL, NULL);
            ELSE
            
                FOR i IN 1 .. l_tot_records
                LOOP
                    IF l_epis_ids(i).rank = 1
                    THEN
                        SELECT COUNT(t_ids.id_pn_vs)
                          INTO l_nr_records
                          FROM TABLE(l_epis_ids) t_ids
                         WHERE t_ids.id_group = l_epis_ids(i).id_group;
                    
                        l_epis_ids_sel.extend();
                        l_epis_ids_sel(i) := t_rec_pn_vs_viewer(l_epis_ids  (i).id_pn_vs,
                                                                i,
                                                                l_epis_ids  (i).id_group,
                                                                l_nr_records,
                                                                l_epis_ids  (i).note_date);
                    
                    ELSE
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            g_error := 'Get Sys_message for Title';
            l_title := pk_message.get_message(i_lang => i_lang, i_code_mess => pk_prog_notes_constants.g_sm_notes);
        
            g_error := 'Get Data for Detailed screen';
            OPEN o_data FOR
                SELECT t_ids_sel.nr_records num_records,
                       pk_prog_notes_utils.get_viewer_date_desc(i_lang,
                                                                i_prof,
                                                                epn.id_episode,
                                                                t_ids_sel.note_date,
                                                                epn.id_software) dt_changed_str,
                       pk_sysdomain.get_domain(l_sd_flg_viewer_type, t_ids_sel.id_group, i_lang) desc_area,
                       t_ids_sel.id_group flg_viewer_type,
                       pk_date_utils.date_send_tsz(i_lang, t_ids_sel.note_date, i_prof) changed_str,
                       epn.id_epis_pn,
                       epn.id_episode
                  FROM TABLE(l_epis_ids_sel) t_ids_sel
                 INNER JOIN epis_pn epn
                    ON t_ids_sel.id_pn_vs = epn.id_epis_pn
                 INNER JOIN pn_note_type pnt
                    ON epn.id_pn_note_type = pnt.id_pn_note_type
                 ORDER BY t_ids_sel.rank;
            -------------------------------------------------------
        
            --Complete 3.rd level (All Notes for Note Type selected)
        ELSIF i_flg_scope = pk_prog_notes_constants.g_flg_scope_complete_c
        THEN
            g_error := 'Get Area description: ' || i_id_pn_area;
            l_title := get_area_desc_by_note_type(i_lang            => i_lang,
                                                  i_prof            => i_prof,
                                                  i_id_episode      => NULL,
                                                  i_id_pn_note_type => NULL,
                                                  i_id_pn_area      => i_id_pn_area);
        
            BEGIN
                g_error := 'Get Area screen name';
                SELECT pna.screen_name
                  INTO o_screen_name
                  FROM pn_area pna
                 WHERE pna.id_pn_area = i_id_pn_area;
            EXCEPTION
                WHEN no_data_found THEN
                    NULL;
            END;
        
            g_error := 'Get Data for Complete screen';
            OPEN o_data FOR
                SELECT pk_prog_notes_utils.get_viewer_date_desc(i_lang,
                                                                i_prof,
                                                                t.id_episode,
                                                                t.note_date,
                                                                t.id_software) dt_changed_str,
                       t.note_desc,
                       t.status_icon,
                       pk_date_utils.date_send_tsz(i_lang, t.note_date, i_prof) changed_str,
                       t.id_epis_pn,
                       t.id_episode,
                       t.id_pn_note_type
                  FROM (SELECT pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type) note_desc,
                               pk_sysdomain.get_img(i_lang,
                                                     pk_prog_notes_constants.g_sd_note_flg_status,
                                                     CASE
                                                         WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_f THEN
                                                          pk_prog_notes_constants.g_without_status
                                                         WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_for_review THEN
                                                          epn.flg_status
                                                         WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_submited THEN
                                                          epn.flg_status
                                                         WHEN epn.flg_status = pk_prog_notes_constants.g_epis_pn_flg_draftsubmit THEN
                                                          epn.flg_status
                                                         ELSE
                                                          decode(epn.flg_status,
                                                                 pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                                 epn.flg_status,
                                                                 pk_prog_notes_constants.g_epis_pn_flg_status_s)
                                                     END) status_icon,
                               epn.id_epis_pn,
                               epn.id_episode,
                               coalesce(epn.dt_signoff, epn.dt_last_update, epn.dt_pn_date, epn.dt_create) note_date,
                               epn.id_software,
                               epn.id_pn_note_type
                          FROM epis_pn epn
                          JOIN pn_note_type pnt
                            ON epn.id_pn_note_type = pnt.id_pn_note_type
                           AND pnt.flg_viewer_type = nvl(i_flg_viewer_type, pnt.flg_viewer_type)
                          JOIN episode epis
                            ON epn.id_episode = epis.id_episode
                         WHERE epn.flg_status IN (pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_t,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_m,
                                                  pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                  pk_prog_notes_constants.g_epis_pn_flg_for_review,
                                                  pk_prog_notes_constants.g_epis_pn_flg_submited,
                                                  pk_prog_notes_constants.g_epis_pn_flg_draftsubmit)
                           AND epis.id_episode = nvl(l_id_episode, epis.id_episode)
                           AND epis.id_visit = nvl(l_id_visit, epis.id_visit)
                           AND epis.id_patient = l_id_patient
                           AND epn.id_pn_area = i_id_pn_area) t
                 WHERE t.note_date BETWEEN nvl(l_dt_begin, t.note_date) AND nvl(l_dt_end, t.note_date)
                 ORDER BY t.note_date DESC;
        
            --Not in scope raise error
        ELSE
            g_error := 'Not a valid i_flg_scope (parameters accepted in (''S'',''D'',''C'',''T''))';
            RAISE l_scope_not_valid;
        END IF;
    
        o_title := l_title;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_data);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_VIEWER_NOTES',
                                              o_error);
            RETURN FALSE;
    END get_viewer_notes;

    /********************************************************************************************
    * Gets the Configurations of a PN Area
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_area                      Internal name of the Area to get Configurations
    * @param   i_episode_software          Software ID associated to the episode
    *                        
    * @return                              Returns the Area Configurations related to the specified profile
    * 
    * @author                              Ant? Neto
    * @version                             2.6.1.2
    * @since                               26-Jul-2011
    **********************************************************************************************/
    FUNCTION tf_pn_area
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_area             IN pn_area.internal_name%TYPE,
        i_episode_software IN software.id_software%TYPE
    ) RETURN t_coll_area IS
        l_pn_area t_coll_area;
    
        l_id_market        market.id_market%TYPE := i_id_market;
        l_id_department    department.id_department%TYPE := i_id_department;
        l_id_dep_clin_serv dep_clin_serv.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
    
        l_id_software_cfg          software.id_software%TYPE;
        l_id_department_cfg        department.id_department%TYPE;
        l_id_dep_clin_serv_cfg     dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_software_from_episode software.id_software%TYPE := i_episode_software;
        l_error                    t_error_out;
        e_general_exception EXCEPTION;
    BEGIN
    
        IF l_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_department := pk_progress_notes_upd.get_department(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        IF l_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        --get episode software
        IF i_episode_software IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            g_error := 'Call PK_EPISODE.GET_EPISODE_SOFTWARE';
            IF NOT pk_episode.get_episode_software(i_lang        => i_lang,
                                                   i_prof        => i_prof,
                                                   i_id_episode  => i_id_episode,
                                                   o_id_software => l_id_software_from_episode,
                                                   o_error       => l_error)
            THEN
                RAISE e_general_exception;
            END IF;
        END IF;
        IF (l_id_software_from_episode IS NULL)
        THEN
            l_id_software_from_episode := i_prof.software;
        END IF;
    
        BEGIN
            BEGIN
                --check the software that should be used to get the data (prof/note software or zero)            
                g_error := 'Get market to filter sblocks id_software: ' || l_id_software_from_episode;
                SELECT t.id_software, t.id_department, t.id_dep_clin_serv
                  INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
                  FROM (SELECT pasi.id_software,
                               pasi.id_department,
                               pasi.id_dep_clin_serv,
                               row_number() over(ORDER BY decode(pasi.id_software, l_id_software_from_episode, 1, 2), decode(pasi.id_department, l_id_department, 1, 2), decode(pasi.id_dep_clin_serv, l_id_dep_clin_serv, 1, 2)) line_number
                          FROM pn_area_soft_inst pasi
                         INNER JOIN pn_area pna
                            ON pasi.id_pn_area = pna.id_pn_area
                         WHERE pasi.id_software IN (0, l_id_software_from_episode)
                           AND pasi.id_department IN (0, l_id_department)
                           AND pasi.id_dep_clin_serv IN (0, -1, l_id_dep_clin_serv)
                           AND pasi.flg_available = pk_alert_constant.g_yes
                           AND pasi.id_institution = i_prof.institution
                           AND pna.internal_name = nvl(i_area, pna.internal_name)) t
                 WHERE line_number = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_id_software_cfg      := 0;
                    l_id_department_cfg    := 0;
                    l_id_dep_clin_serv_cfg := -1;
            END;
        
            SELECT t_rec_area(id_pn_area,
                              nr_rec_page_summary,
                              data_sort_summary,
                              nr_rec_page_hist,
                              flg_report_title_type,
                              summary_default_filter,
                              time_to_close_note,
                              time_to_start_docum,
                              flg_task,
                              id_report)
              BULK COLLECT
              INTO l_pn_area
              FROM (SELECT pnasi.id_pn_area,
                           pnasi.nr_rec_page_summary,
                           pnasi.data_sort_summary,
                           pnasi.nr_rec_page_hist,
                           pnasi.flg_report_title_type,
                           pnasi.summary_default_filter,
                           pnasi.time_to_close_note,
                           pnasi.time_to_start_docum,
                           pna.flg_task,
                           pnasi.id_report,
                           row_number() over(PARTITION BY pnasi.id_pn_area ORDER BY pnasi.id_software DESC NULLS LAST, pnasi.id_institution DESC NULLS LAST, pnasi.id_department DESC NULLS LAST, pnasi.id_dep_clin_serv DESC NULLS LAST) rn
                    
                      FROM pn_area_soft_inst pnasi
                     INNER JOIN pn_area pna
                        ON pnasi.id_pn_area = pna.id_pn_area
                     WHERE pnasi.id_institution = i_prof.institution
                       AND pnasi.id_software = l_id_software_cfg
                       AND (pnasi.id_department = l_id_department_cfg)
                       AND (pnasi.id_dep_clin_serv = l_id_dep_clin_serv_cfg)
                       AND pnasi.flg_available = pk_alert_constant.g_yes
                       AND pna.internal_name = nvl(i_area, pna.internal_name)) t
             WHERE t.rn = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_pn_area := NULL;
        END;
    
        IF l_pn_area.count < 1
        THEN
            IF l_id_market IS NULL
            THEN
                l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
            END IF;
        
            --check the market that should be used to get the data (institution market or zero)            
            g_error := 'Get market to filter sblocks i_market: ' || l_id_market;
            SELECT t.id_market, t.id_software
              INTO l_id_market, l_id_software_cfg
              FROM (SELECT m.id_market,
                           m.id_software,
                           row_number() over(ORDER BY decode(nvl(m.id_market, 0), l_id_market, 1, 2), decode(m.id_software, l_id_software_from_episode, 1, 2)) line_number
                      FROM pn_area_mkt m
                     INNER JOIN pn_area pna
                        ON m.id_pn_area = pna.id_pn_area
                     WHERE m.id_software IN (0, l_id_software_from_episode)
                       AND m.id_market IN (0, l_id_market)
                       AND pna.internal_name = nvl(i_area, pna.internal_name)) t
             WHERE line_number = 1;
        
            BEGIN
                SELECT t_rec_area(id_pn_area,
                                  nr_rec_page_summary,
                                  data_sort_summary,
                                  nr_rec_page_hist,
                                  flg_report_title_type,
                                  summary_default_filter,
                                  time_to_close_note,
                                  time_to_start_docum,
                                  flg_task,
                                  id_report)
                  BULK COLLECT
                  INTO l_pn_area
                  FROM (SELECT pnam.id_pn_area,
                               pnam.nr_rec_page_summary,
                               pnam.data_sort_summary,
                               pnam.nr_rec_page_hist,
                               pnam.flg_report_title_type,
                               pnam.summary_default_filter,
                               pnam.time_to_close_note,
                               pnam.time_to_start_docum,
                               pna.flg_task,
                               pnam.id_report,
                               row_number() over(PARTITION BY pnam.id_pn_area ORDER BY decode(pnam.id_market, l_id_market, 1, 2), decode(pnam.id_software, nvl(l_id_software_from_episode, i_prof.software), 1, 2)) rn
                        
                          FROM pn_area_mkt pnam
                         INNER JOIN pn_area pna
                            ON pnam.id_pn_area = pna.id_pn_area
                         WHERE pnam.id_software = l_id_software_cfg
                           AND pnam.id_market = l_id_market
                           AND pna.internal_name = nvl(i_area, pna.internal_name)) t
                 WHERE t.rn = 1;
            EXCEPTION
                WHEN no_data_found THEN
                    l_pn_area := NULL;
            END;
        END IF;
    
        RETURN l_pn_area;
    END tf_pn_area;

    /********************************************************************************************
    * Gets the Configurations of a PN Note Type
    *
    * @param   i_lang                      Language identifier
    * @param   i_prof                      Professional Identification
    * @param   i_id_profile_template       Logged professional profile
    * @param   i_episode                   Episode identifier
    * @param   i_id_market                 Market identifier
    * @param   i_id_department             Service identifier
    * @param   i_id_dep_clin_serv          Service/specialty identifier
    * @param   i_id_category               Prefessional Category identifier
    * @param   i_area                      Internal name of the Area to get Configurations
    * @param   i_id_note_type              Note Type identifier
    * @param   i_flg_scope                 Scope: A-Area; N-Note Type
    * @param   i_software                  Software ID
    *                        
    * @return                              Returns the Note Type Configurations related to the specified profile
    * 
    * @author                              Ant? Neto
    * @version                             2.6.1.2
    * @since                               26-Jul-2011
    **********************************************************************************************/
    FUNCTION tf_pn_note_type
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE DEFAULT NULL,
        i_id_profile_template IN profile_template.id_profile_template%TYPE DEFAULT NULL,
        i_id_market           IN market.id_market%TYPE DEFAULT NULL,
        i_id_department       IN department.id_department%TYPE DEFAULT NULL,
        i_id_dep_clin_serv    IN dep_clin_serv.id_dep_clin_serv%TYPE DEFAULT NULL,
        i_id_category         IN category.id_category%TYPE DEFAULT NULL,
        i_area                IN table_varchar,
        i_id_note_type        IN pn_note_type.id_pn_note_type%TYPE DEFAULT NULL,
        i_flg_scope           IN VARCHAR2,
        i_software            IN software.id_software%TYPE
    ) RETURN t_coll_note_type
        PIPELINED IS
    
        l_id_profile_template profile_template.id_profile_template%TYPE := i_id_profile_template;
        l_id_market           market.id_market%TYPE := i_id_market;
        l_id_department       department.id_department%TYPE := i_id_department;
        l_id_dep_clin_serv    dep_clin_serv.id_dep_clin_serv%TYPE := i_id_dep_clin_serv;
        l_id_category         category.id_category%TYPE := i_id_category;
    
        l_pn_note_type t_coll_note_type;
    
        l_pn_note_type_count PLS_INTEGER;
    
        l_id_software_cfg       software.id_software%TYPE;
        l_id_department_cfg     department.id_department%TYPE;
        l_id_dep_clin_serv_cfg  dep_clin_serv.id_dep_clin_serv%TYPE;
        l_id_software_from_prof software.id_software%TYPE := i_software;
        e_general_exception EXCEPTION;
        l_func_name CONSTANT VARCHAR2(16 CHAR) := 'TF_PN_NOTE_TYPE';
    BEGIN
        --get software
        IF i_software IS NULL
        THEN
            l_id_software_from_prof := i_prof.software;
        END IF;
    
        IF l_id_profile_template IS NULL
        THEN
            l_id_profile_template := pk_tools.get_prof_profile_template(i_prof => i_prof);
        END IF;
    
        IF (l_id_department IS NULL AND l_id_dep_clin_serv IS NOT NULL)
        THEN
            SELECT dcs.id_department
              INTO l_id_department
              FROM dep_clin_serv dcs
             WHERE dcs.id_dep_clin_serv = i_id_dep_clin_serv;
        END IF;
    
        IF l_id_department IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_department := pk_progress_notes_upd.get_department(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        IF l_id_dep_clin_serv IS NULL
           AND i_id_episode IS NOT NULL
        THEN
            l_id_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_id_episode, i_epis_pn => NULL);
        END IF;
    
        IF l_id_category IS NULL
        THEN
            l_id_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        END IF;
    
        BEGIN
            --check the software that should be used to get the data (prof/note software or zero)            
            g_error := 'Get market to filter sblocks id_software: ' || l_id_software_from_prof;
            SELECT t.id_software, t.id_department, t.id_dep_clin_serv
              INTO l_id_software_cfg, l_id_department_cfg, l_id_dep_clin_serv_cfg
              FROM (SELECT nts.id_software,
                           nts.id_department,
                           nts.id_dep_clin_serv,
                           row_number() over(ORDER BY decode(nts.id_software, l_id_software_from_prof, 1, 2), decode(nts.id_department, l_id_department, 1, 2), decode(nts.id_dep_clin_serv, l_id_dep_clin_serv, 1, 2)) line_number
                      FROM pn_note_type_soft_inst nts
                     INNER JOIN pn_area pna
                        ON nts.id_pn_area = pna.id_pn_area
                     WHERE nts.id_institution = i_prof.institution
                       AND ((nts.id_software IN (0, l_id_software_from_prof) AND
                           nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                           nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                       AND (nts.id_department IN (0, l_id_department))
                       AND (nts.id_dep_clin_serv IN (0, -1, l_id_dep_clin_serv))
                       AND ((nts.id_profile_template IN (0, l_id_profile_template) AND
                           nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                           nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                       AND ((nts.id_category IN (-1, l_id_category) AND
                           nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                           nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                       AND nts.flg_available = pk_alert_constant.g_yes
                       AND ((pna.internal_name IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                    t.column_value
                                                     FROM TABLE(i_area) t) AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_a) OR
                           (nts.id_pn_note_type = i_id_note_type AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_notetype_n) OR
                           (i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_f))
                    
                    ) t
             WHERE line_number = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_id_software_cfg      := 0;
                l_id_department_cfg    := 0;
                l_id_dep_clin_serv_cfg := -1;
        END;
    
        SELECT t_rec_note_type(id_pn_area,
                               id_pn_note_type,
                               rank,
                               max_nr_notes,
                               max_nr_draft_notes,
                               max_nr_draft_addendums,
                               flg_addend_other_prof,
                               flg_show_empty_blocks,
                               flg_import_available,
                               flg_sign_off_login_avail,
                               flg_last_24h,
                               flg_dictation_editable,
                               flg_clear_information,
                               flg_review_all,
                               flg_edit_after_disch,
                               flg_import_first,
                               flg_write,
                               flg_copy_edit_replace,
                               gender,
                               age_min,
                               age_max,
                               flg_expand_sblocks,
                               flg_synchronized,
                               flg_show_import_menu,
                               flg_edit_other_prof,
                               flg_create_on_app,
                               flg_autopop_warning,
                               flg_discharge_warning,
                               flg_disch_warning_option,
                               flg_review_warning,
                               flg_review_warn_option,
                               flg_import_warning,
                               flg_help_save,
                               flg_edit_only_last,
                               flg_save_only_screen,
                               flg_status_available,
                               flg_partial_warning,
                               flg_remove_on_ok,
                               editable_nr_min,
                               flg_suggest_concept,
                               flg_review_on_ok,
                               flg_partial_load,
                               flg_viewer_type,
                               flg_sign_off,
                               flg_type,
                               flg_cancel,
                               flg_submit,
                               cal_delay_time,
                               cal_icu_delay_time,
                               flg_cal_time_filter,
                               flg_sync_after_disch,
                               flg_edit_condition,
                               flg_patient_id_warning,
                               flg_show_signature,
                               flg_show_free_text)
          BULK COLLECT
          INTO l_pn_note_type
          FROM (SELECT nts.id_pn_area,
                       nts.id_pn_note_type,
                       nts.rank,
                       nts.max_nr_notes,
                       nts.max_nr_draft_notes,
                       nts.max_nr_draft_addendums,
                       nts.flg_addend_other_prof,
                       nts.flg_show_empty_blocks,
                       nts.flg_import_available,
                       nts.flg_sign_off_login_avail,
                       nts.flg_last_24h,
                       nts.flg_dictation_editable,
                       nts.flg_clear_information,
                       nts.flg_review_all,
                       nts.flg_edit_after_disch,
                       nts.flg_import_first,
                       nts.flg_write,
                       nts.flg_copy_edit_replace,
                       nts.gender,
                       nts.age_min,
                       nts.age_max,
                       nts.flg_expand_sblocks,
                       nts.flg_synchronized,
                       nts.flg_show_import_menu,
                       nts.flg_edit_other_prof,
                       nts.flg_create_on_app,
                       nts.flg_autopop_warning,
                       nts.flg_discharge_warning,
                       nts.flg_disch_warning_option,
                       nts.flg_review_warning,
                       nts.flg_review_warn_option,
                       nts.flg_import_warning,
                       nts.flg_help_save,
                       nts.flg_edit_only_last,
                       nts.flg_save_only_screen,
                       nts.flg_status_available,
                       nts.flg_partial_warning,
                       nts.flg_remove_on_ok,
                       nts.editable_nr_min,
                       nts.flg_suggest_concept,
                       nts.flg_review_on_ok,
                       nts.flg_partial_load,
                       pnt.flg_viewer_type,
                       flg_sign_off,
                       pnt.flg_type,
                       nts.flg_cancel,
                       nts.flg_submit,
                       NULL cal_delay_time,
                       NULL cal_icu_delay_time,
                       NULL flg_cal_time_filter,
                       nts.flg_sync_after_disch,
                       nts.flg_edit_condition,
                       nts.flg_patient_id_warning,
                       nts.flg_show_signature,
                       NTS.flg_show_free_text,
                       row_number() over(PARTITION BY nts.id_pn_area, nts.id_pn_note_type ORDER BY nts.id_software DESC, nts.id_institution DESC, nts.id_department DESC, nts.id_dep_clin_serv DESC, nts.id_profile_template DESC, nts.id_category DESC, nts.rank ASC NULLS LAST) rn
                  FROM pn_note_type_soft_inst nts
                 INNER JOIN pn_area pna
                    ON nts.id_pn_area = pna.id_pn_area
                 INNER JOIN pn_note_type pnt
                    ON pnt.id_pn_note_type = nts.id_pn_note_type
                 WHERE nts.id_institution = i_prof.institution
                   AND ((nts.id_software = l_id_software_cfg AND
                       nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                       nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                   AND (nts.id_department = l_id_department_cfg)
                   AND (nts.id_dep_clin_serv = l_id_dep_clin_serv_cfg)
                   AND ((nts.id_profile_template IN (0, l_id_profile_template) AND
                       nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                       nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                   AND ((nts.id_category IN (-1, l_id_category) AND
                       nts.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                       nts.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                   AND nts.flg_available = pk_alert_constant.g_yes
                   AND ((pna.internal_name IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                t.column_value
                                                 FROM TABLE(i_area) t) AND
                       i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_a) OR
                       (nts.id_pn_note_type = i_id_note_type AND
                       i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_notetype_n) OR
                       (i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_f))) t
         WHERE t.rn = 1;
    
        IF l_pn_note_type.count < 1
        THEN
        
            IF l_id_market IS NULL
            THEN
                l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
            END IF;
        
            --check the market that should be used to get the data (institution market or zero)            
            g_error := 'Get market to filter sblocks i_market: ' || l_id_market;
            SELECT t.id_market, t.id_software
              INTO l_id_market, l_id_software_cfg
              FROM (SELECT ntm.id_market,
                           ntm.id_software,
                           row_number() over(ORDER BY decode(nvl(ntm.id_market, 0), l_id_market, 1, 2), decode(ntm.id_software, l_id_software_from_prof, 1, 2)) line_number
                      FROM pn_note_type_mkt ntm
                     INNER JOIN pn_area pna
                        ON ntm.id_pn_area = pna.id_pn_area
                     WHERE ((ntm.id_software IN (0, l_id_software_from_prof) AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                       AND (ntm.id_market IN (0, l_id_market))
                       AND ((ntm.id_profile_template IN (0, l_id_profile_template) AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                       AND ((ntm.id_category IN (-1, l_id_category) AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                       AND ((pna.internal_name IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                    t.column_value
                                                     FROM TABLE(i_area) t) AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_a) OR
                           (ntm.id_pn_note_type = i_id_note_type AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_notetype_n) OR
                           (i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_f))) t
             WHERE line_number = 1;
        
            SELECT t_rec_note_type(id_pn_area,
                                   id_pn_note_type,
                                   rank,
                                   max_nr_notes,
                                   max_nr_draft_notes,
                                   max_nr_draft_addendums,
                                   flg_addend_other_prof,
                                   flg_show_empty_blocks,
                                   flg_import_available,
                                   flg_sign_off_login_avail,
                                   flg_last_24h,
                                   flg_dictation_editable,
                                   flg_clear_information,
                                   flg_review_all,
                                   flg_edit_after_disch,
                                   flg_import_first,
                                   flg_write,
                                   flg_copy_edit_replace,
                                   gender,
                                   age_min,
                                   age_max,
                                   flg_expand_sblocks,
                                   flg_synchronized,
                                   flg_show_import_menu,
                                   flg_edit_other_prof,
                                   flg_create_on_app,
                                   flg_autopop_warning,
                                   flg_discharge_warning,
                                   flg_disch_warning_option,
                                   flg_review_warning,
                                   flg_review_warn_option,
                                   flg_import_warning,
                                   flg_help_save,
                                   flg_edit_only_last,
                                   flg_save_only_screen,
                                   flg_status_available,
                                   flg_partial_warning,
                                   flg_remove_on_ok,
                                   editable_nr_min,
                                   flg_suggest_concept,
                                   flg_review_on_ok,
                                   flg_partial_load,
                                   flg_viewer_type,
                                   flg_sign_off,
                                   flg_type,
                                   flg_cancel,
                                   flg_submit,
                                   cal_delay_time,
                                   cal_icu_delay_time,
                                   flg_cal_time_filter,
                                   flg_sync_after_disch,
                                   flg_edit_condition,
                                   flg_patient_id_warning,
                                   flg_show_signature,
                                   flg_show_free_text)
              BULK COLLECT
              INTO l_pn_note_type
              FROM (SELECT ntm.id_pn_area,
                           ntm.id_pn_note_type,
                           ntm.rank,
                           ntm.max_nr_notes,
                           ntm.max_nr_draft_notes,
                           ntm.max_nr_draft_addendums,
                           ntm.flg_addend_other_prof,
                           ntm.flg_show_empty_blocks,
                           ntm.flg_import_available,
                           ntm.flg_sign_off_login_avail,
                           ntm.flg_last_24h,
                           ntm.flg_dictation_editable,
                           ntm.flg_clear_information,
                           ntm.flg_review_all,
                           ntm.flg_edit_after_disch,
                           ntm.flg_import_first,
                           ntm.flg_write,
                           ntm.flg_copy_edit_replace,
                           ntm.gender,
                           ntm.age_min,
                           ntm.age_max,
                           ntm.flg_expand_sblocks,
                           ntm.flg_synchronized,
                           ntm.flg_show_import_menu,
                           ntm.flg_edit_other_prof,
                           ntm.flg_create_on_app,
                           ntm.flg_autopop_warning,
                           ntm.flg_discharge_warning,
                           ntm.flg_disch_warning_option,
                           ntm.flg_review_warning,
                           ntm.flg_review_warn_option,
                           ntm.flg_import_warning,
                           ntm.flg_help_save,
                           ntm.flg_edit_only_last,
                           ntm.flg_save_only_screen,
                           ntm.flg_status_available,
                           ntm.flg_partial_warning,
                           ntm.flg_remove_on_ok,
                           ntm.editable_nr_min,
                           ntm.flg_suggest_concept,
                           ntm.flg_review_on_ok,
                           ntm.flg_partial_load,
                           pnt.flg_viewer_type,
                           ntm.flg_sign_off,                           ntm.flg_submit,

                           pnt.flg_type,
                           ntm.flg_cancel,
                           ntm.cal_delay_time,
                           ntm.cal_icu_delay_time,
                           ntm.flg_cal_time_filter,
                           ntm.flg_sync_after_disch,
                           ntm.flg_edit_condition,
                           ntm.flg_patient_id_warning flg_patient_id_warning,
                           flg_show_signature,
                           NTM.flg_show_free_text,
                           row_number() over(PARTITION BY ntm.id_pn_area, ntm.id_pn_note_type ORDER BY decode(ntm.id_market, l_id_market, 1, 2), decode(ntm.id_software, nvl(l_id_software_from_prof, i_prof.software), 1, 2), ntm.id_profile_template DESC, ntm.id_category DESC, ntm.rank ASC NULLS LAST) rn
                      FROM pn_note_type_mkt ntm
                     INNER JOIN pn_area pna
                        ON ntm.id_pn_area = pna.id_pn_area
                     INNER JOIN pn_note_type pnt
                        ON pnt.id_pn_note_type = ntm.id_pn_note_type
                     WHERE ((ntm.id_software = l_id_software_cfg AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_software_s) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_software_s)
                       AND (ntm.id_market IN (0, l_id_market))
                       AND ((ntm.id_profile_template IN (0, l_id_profile_template) AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_proftempl_p) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_proftempl_p)
                       AND ((ntm.id_category IN (-1, l_id_category) AND
                           ntm.flg_config_type = pk_prog_notes_constants.g_flg_config_type_category_c) OR
                           ntm.flg_config_type <> pk_prog_notes_constants.g_flg_config_type_category_c)
                       AND ((pna.internal_name IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                    t.column_value
                                                     FROM TABLE(i_area) t) AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_a) OR
                           (ntm.id_pn_note_type = i_id_note_type AND
                           i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_notetype_n) OR
                           (i_flg_scope = pk_prog_notes_constants.g_pn_flg_scope_area_f))) t
             WHERE t.rn = 1;
        END IF;
    
        l_pn_note_type_count := l_pn_note_type.count;
        FOR i IN 1 .. l_pn_note_type_count
        LOOP
            PIPE ROW(l_pn_note_type(i));
        END LOOP;
    
        RETURN;
    END tf_pn_note_type;

    /**
    * Get the max notes of all the note type of an area.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_area               Area internal name
    *
    * @param   o_area_max_notes     Area max notes
    * @param   o_error              Error information
    *
    * @return  Boolean              True: Sucess, False: Fail
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   18-08-2011
    */
    FUNCTION get_area_max_notes
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_episode     IN episode.id_episode%TYPE,
        i_area           IN pn_area.internal_name%TYPE,
        o_area_max_notes OUT NOCOPY PLS_INTEGER,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
        g_error := 'GET max notes by area. i_area: ' || i_area;
        SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
         SUM(max_nr_notes)
          INTO o_area_max_notes
          FROM TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang,
                                                         i_prof,
                                                         i_id_episode,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         NULL,
                                                         table_varchar(i_area),
                                                         NULL,
                                                         pk_prog_notes_constants.g_pn_flg_scope_area_a,
                                                         i_software => NULL)) t;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_AREA_MAX_NOTES',
                                              o_error);
        
            RETURN FALSE;
    END get_area_max_notes;

    /**
    * Get the ID_epis_pn_det_task of an imported record
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_episode         Note identifier
    * @param   i_id_epis_pn         Note identifier
    * @param   i_id_task            Task identifier
    * @param   i_id_task_aggregator Aggregator task identifier
    * @param   i_id_task_type            Task type identifier
    * @param   i_id_pn_data_block        Data block id
    * @param   i_id_pn_soap_block        Soap block id
    * @param   i_flg_only_active         Y-check only in the active records. N-check in all the records
    * @param   o_id_epis_pn_det_task     Id epis_pn_det_task
    * @param   o_flg_status              epis_pn_det_task status
    * @param   o_task_text               Text in the note
    * @param   o_dt_last_update_task     Last update date of the task
    * @param   o_dt_review_task          Review date
    * @param   o_rank_task               Task rank
    *
    * @return  Boolean             Success / Error
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   22-08-2011
    */
    FUNCTION get_imported_record
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_id_task             IN epis_pn_det_task.id_task%TYPE,
        i_id_task_aggregator  IN epis_pn_det_task.id_task_aggregator%TYPE,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_flg_only_active     IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_id_epis_pn_det_task OUT NOCOPY epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_task_text           OUT NOCOPY epis_pn_det_task.pn_note%TYPE,
        o_flg_status          OUT NOCOPY epis_pn_det_task.flg_status%TYPE,
        o_dt_last_update_task OUT NOCOPY epis_pn_det_task.dt_task%TYPE,
        o_dt_review_task      OUT NOCOPY epis_pn_det_task.dt_review%TYPE,
        o_rank_task           OUT NOCOPY epis_pn_det_task.rank_task%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'Check if the task had already been imported. i_id_task: ' || i_id_task || ' i_id_epis_pn: ' ||
                   i_id_epis_pn;
    
        IF (i_id_epis_pn IS NOT NULL)
        THEN
            IF (i_id_task IS NOT NULL)
            THEN
                g_error := 'Check if the task had already been imported. i_id_task: ' || i_id_task || ' i_id_epis_pn: ' ||
                           i_id_epis_pn;
            
                IF i_id_task_type IN
                   (pk_prog_notes_constants.g_task_vital_signs, pk_prog_notes_constants.g_task_biometrics)
                THEN
                    BEGIN
                        SELECT t.id_epis_pn_det_task, t.pn_note, t.flg_status, t.dt_task, t.dt_review, t.rank_task
                          INTO o_id_epis_pn_det_task,
                               o_task_text,
                               o_flg_status,
                               o_dt_last_update_task,
                               o_dt_review_task,
                               o_rank_task
                          FROM (SELECT e.id_epis_pn_det_task,
                                       e.pn_note,
                                       e.flg_status,
                                       e.dt_task,
                                       e.dt_review,
                                       e.rank_task
                                  FROM epis_pn_det_task e
                                  JOIN epis_pn_det epd
                                    ON epd.id_epis_pn_det = e.id_epis_pn_det
                                  JOIN epis_pn ep
                                    ON ep.id_epis_pn = epd.id_epis_pn
                                 WHERE e.id_task = i_id_task
                                   AND (i_id_task_aggregator IS NULL OR e.id_task_aggregator = i_id_task_aggregator)
                                   AND e.id_task_type IN (pk_prog_notes_constants.g_task_vital_signs,
                                                          pk_prog_notes_constants.g_task_biometrics)
                                   AND ep.id_epis_pn = i_id_epis_pn
                                   AND ep.id_episode = i_id_episode
                                   AND epd.id_pn_data_block = i_id_pn_data_block
                                   AND epd.id_pn_soap_block = i_id_pn_soap_block
                                   AND ((i_flg_only_active = pk_alert_constant.g_yes AND
                                       e.flg_status IN
                                       (pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                          pk_prog_notes_constants.g_epis_pn_det_sug_add_s)) OR
                                       i_flg_only_active = pk_alert_constant.g_no)
                                 ORDER BY flg_status) t
                        
                         WHERE rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                ELSE
                
                    BEGIN
                        SELECT t.id_epis_pn_det_task, t.pn_note, t.flg_status, t.dt_task, t.dt_review, t.rank_task
                          INTO o_id_epis_pn_det_task,
                               o_task_text,
                               o_flg_status,
                               o_dt_last_update_task,
                               o_dt_review_task,
                               o_rank_task
                          FROM (SELECT e.id_epis_pn_det_task,
                                       e.pn_note,
                                       e.flg_status,
                                       e.dt_task,
                                       e.dt_review,
                                       e.rank_task
                                  FROM epis_pn_det_task e
                                  JOIN epis_pn_det epd
                                    ON epd.id_epis_pn_det = e.id_epis_pn_det
                                  JOIN epis_pn ep
                                    ON ep.id_epis_pn = epd.id_epis_pn
                                 WHERE e.id_task = i_id_task
                                   AND (i_id_task_aggregator IS NULL OR e.id_task_aggregator = i_id_task_aggregator)
                                   AND e.id_task_type = i_id_task_type
                                   AND ep.id_epis_pn = i_id_epis_pn
                                   AND ep.id_episode = i_id_episode
                                   AND epd.id_pn_data_block = i_id_pn_data_block
                                   AND epd.id_pn_soap_block = i_id_pn_soap_block
                                   AND ((i_flg_only_active = pk_alert_constant.g_yes AND
                                       e.flg_status IN
                                       (pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                          pk_prog_notes_constants.g_epis_pn_det_sug_add_s)) OR
                                       i_flg_only_active = pk_alert_constant.g_no)
                                 ORDER BY flg_status) t
                        
                         WHERE rownum = 1;
                    
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                
                END IF;
            ELSE
                BEGIN
                    SELECT NULL, t.pn_note, t.flg_status, t.dt_pn, NULL, NULL
                      INTO o_id_epis_pn_det_task,
                           o_task_text,
                           o_flg_status,
                           o_dt_last_update_task,
                           o_dt_review_task,
                           o_rank_task
                      FROM (SELECT epd.pn_note, epd.flg_status, epd.dt_pn
                              FROM epis_pn_det epd
                            
                              JOIN epis_pn ep
                                ON ep.id_epis_pn = epd.id_epis_pn
                             WHERE ep.id_epis_pn = i_id_epis_pn
                               AND ep.id_episode = i_id_episode
                               AND epd.id_pn_data_block = i_id_pn_data_block
                               AND epd.id_pn_soap_block = i_id_pn_soap_block
                               AND ((i_flg_only_active = pk_alert_constant.g_yes AND
                                   ep.flg_status IN
                                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                      pk_prog_notes_constants.g_epis_pn_det_sug_add_s)) OR
                                   i_flg_only_active = pk_alert_constant.g_no)
                             ORDER BY flg_status) t
                    
                     WHERE rownum = 1;
                
                EXCEPTION
                    WHEN no_data_found THEN
                        NULL;
                END;
            END IF;
        
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_IMPORTED_RECORD',
                                              o_error);
        
            RETURN FALSE;
    END get_imported_record;

    /**
    * Validates if a record had already been imported.
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_episode         Episode identifier
    * @param   i_id_epis_pn         Note identifier
    * @param   i_id_task            Task identifier
    * @param   i_id_task_type            Task type identifier
    * @param   i_id_pn_data_block        Data block id
    * @param   i_id_pn_soap_block        Soap block id
    * @param   i_flg_only_active         Y-check only in the active records. N-check in all the records
    * @param   i_flg_syncronized         Y-Single page. N-Single note.
    *
    * @return  VARCHAR2             Y- the record had already been imported. N-otherwise.
    *
    * @author  Sofia Mendes
    * @version <2.6.1.2>
    * @since   22-08-2011
    */
    FUNCTION check_imported_record
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_id_task            IN epis_pn_det_task.id_task%TYPE,
        i_id_task_aggregator IN epis_pn_det_task.id_task_aggregator%TYPE,
        i_id_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_id_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_flg_only_active    IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN VARCHAR2 IS
        l_imported            VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE;
        l_error               t_error_out;
        l_dummy               epis_pn_det_task.pn_note%TYPE;
        l_status              epis_pn_det_task.flg_status%TYPE;
        l_dt_last_update_task epis_pn_det_task.dt_task%TYPE;
        l_dt_review_task      epis_pn_det_task.dt_review%TYPE;
        l_rank_task           epis_pn_det_task.rank_task%TYPE;
    BEGIN
        g_error := 'CALL get_imported_record. i_id_task: ' || i_id_task || ' i_id_epis_pn: ' || i_id_epis_pn;
        IF NOT get_imported_record(i_lang                => i_lang,
                                   i_prof                => i_prof,
                                   i_id_episode          => i_id_episode,
                                   i_id_epis_pn          => i_id_epis_pn,
                                   i_id_task             => i_id_task,
                                   i_id_task_aggregator  => i_id_task_aggregator,
                                   i_id_pn_data_block    => i_id_pn_data_block,
                                   i_id_pn_soap_block    => i_id_pn_soap_block,
                                   i_id_task_type        => i_id_task_type,
                                   i_flg_only_active     => i_flg_only_active,
                                   o_id_epis_pn_det_task => l_id_epis_pn_det_task,
                                   o_task_text           => l_dummy,
                                   o_flg_status          => l_status,
                                   o_dt_last_update_task => l_dt_last_update_task,
                                   o_dt_review_task      => l_dt_review_task,
                                   o_rank_task           => l_rank_task,
                                   o_error               => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_id_epis_pn_det_task IS NOT NULL OR l_status IS NOT NULL)
        THEN
            l_imported := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_imported;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_IMPORTED_RECORD',
                                              l_error);
        
            RETURN pk_alert_constant.g_no;
    END check_imported_record;

    /**
    * Get the import detail info: description of the task and signature
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_pn_task_type           Task type id
    * @param i_id_task                Task id
    * @param i_id_episode             Episode id: in which the task was requested
    * @param i_dt_register            Task registration date
    * @param i_prof_register          Professional that performed the request
    * @param i_id_data_block          Data block used to get description info
    * @param i_id_soap_block          Soap block used to get description info
    * @param i_id_note_type           Note type used to get description info
    *
    * @param o_task_desc              Task detailed description
    * @param o_signature              Signature
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          29-Set-2011
    */
    FUNCTION get_import_detail
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task       IN epis_pn_det_task.id_task%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_dt_register   IN VARCHAR2,
        i_prof_register IN professional.id_professional%TYPE,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        o_task_desc     OUT NOCOPY CLOB,
        o_signature     OUT NOCOPY VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name      VARCHAR2(20 CHAR) := 'GET_IMPORT_DETAIL';
        l_dt_register    TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_prof_review epis_pn_det_task.id_prof_review%TYPE;
        l_dt_review      epis_pn_det_task.dt_review%TYPE;
    
        l_date_signature TIMESTAMP WITH LOCAL TIME ZONE;
    
        l_prof_signature epis_pn_det_task.id_prof_last_update%TYPE;
        l_code_message   sys_message.code_message%TYPE;
    
        l_dt_last_update epis_pn_det_task.dt_last_update%TYPE;
    
        l_t_coll_dblock_task_type t_coll_dblock_task_type;
        l_flg_description         pn_dblock_ttp_mkt.flg_description%TYPE;
        l_description_condition   pn_dblock_ttp_mkt.description_condition%TYPE;
    BEGIN
        -- Convert start date to timestamp
        g_error := 'CALL GET_STRING_TSTZ FOR i_dt_register';
        IF NOT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                             i_prof      => i_prof,
                                             i_timestamp => i_dt_register,
                                             i_timezone  => NULL,
                                             o_timestamp => l_dt_register,
                                             o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_upd.tf_dblock_task_type. i_id_pn_note_type: ' || i_id_note_type ||
                   ' i_id_task_type: ' || i_id_task_type || ' i_id_pn_data_block: ' || i_id_data_block ||
                   ' i_id_pn_soap_block: ' || i_id_soap_block;
    
        l_t_coll_dblock_task_type := pk_progress_notes_upd.tf_dblock_task_type(i_lang             => i_lang,
                                                                               i_prof             => i_prof,
                                                                               i_id_episode       => i_id_episode,
                                                                               i_id_market        => NULL,
                                                                               i_id_department    => NULL,
                                                                               i_id_dep_clin_serv => NULL,
                                                                               i_id_pn_note_type  => i_id_note_type,
                                                                               i_software         => NULL,
                                                                               i_id_task_type     => i_id_task_type,
                                                                               i_id_pn_data_block => i_id_data_block,
                                                                               i_id_pn_soap_block => i_id_soap_block);
    
        g_error     := 'get_detailed_desc_all. i_id_pn_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task;
        o_task_desc := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                              i_prof                  => i_prof,
                                                              i_id_episode            => i_id_episode,
                                                              i_id_task_type          => i_id_task_type,
                                                              i_id_task               => i_id_task,
                                                              i_universal_description => NULL,
                                                              i_short_desc            => NULL,
                                                              i_code_description      => NULL,
                                                              i_flg_description       => l_t_coll_dblock_task_type(1).flg_description,
                                                              i_description_condition => l_t_coll_dblock_task_type(1).description_condition);
    
        g_error := 'CALL pk_prog_notes_utils.get_review_data_from_ea';
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package,
                             sub_object_name => l_func_name,
                             owner           => g_owner);
        IF NOT pk_prog_notes_utils.get_review_data_from_ea(i_lang           => i_lang,
                                                           i_prof           => i_prof,
                                                           i_id_task_type   => i_id_task_type,
                                                           i_id_task        => i_id_task,
                                                           o_id_prof_review => l_id_prof_review,
                                                           o_dt_review      => l_dt_review,
                                                           o_dt_last_update => l_dt_last_update,
                                                           o_error          => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_dt_register > l_dt_review OR l_dt_review IS NULL)
        THEN
            l_date_signature := l_dt_register;
            l_prof_signature := i_prof_register;
            l_code_message   := pk_prog_notes_constants.g_sm_registered;
        ELSE
            l_date_signature := l_dt_review;
            l_prof_signature := l_id_prof_review;
            l_code_message   := pk_prog_notes_constants.g_sm_reviewed;
        END IF;
    
        IF (l_date_signature IS NOT NULL)
        THEN
            g_error     := 'pk_inp_detail.get_signature. i_id_episode: ' || i_id_episode || ' i_dt_register: ' ||
                           i_dt_register || ' i_prof_register: ' || i_prof_register;
            o_signature := pk_inp_detail.get_signature(i_lang                => i_lang,
                                                       i_prof                => i_prof,
                                                       i_id_episode          => i_id_episode,
                                                       i_date                => l_date_signature,
                                                       i_id_prof_last_change => l_prof_signature,
                                                       i_code_desc           => l_code_message);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_IMPORT_DETAIL',
                                              o_error);
        
            RETURN FALSE;
    END get_import_detail;

    /**
    * Get the task descriptions.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type id
    * @param i_id_task                Task id
    * @param i_code_description       Code translation to the task description
    * @param i_universal_desc_clob    Large Description created by the user
    * @param i_flg_sos                Flag SOS/PRN
    * @param i_dt_begin               Begin Date of the task
    * @param i_id_doc_area            Documentation Area identifier
    * @param i_flg_status             Status of the task
    * @param i_code_desc_sample_type  Sample type code description
    * @param o_short_desc             Short description to the import last level
    * @param o_detailed_desc          Detailed desc for more info and note
    *
    * @return                         Task detailed description
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          09-Feb-2012
    */
    FUNCTION get_task_descs
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_id_patient            IN patient.id_patient%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_code_description      IN task_timeline_ea.code_description%TYPE,
        i_universal_desc_clob   IN task_timeline_ea.universal_desc_clob%TYPE,
        i_flg_sos               IN task_timeline_ea.flg_sos%TYPE,
        i_dt_begin              IN task_timeline_ea.dt_begin%TYPE,
        i_id_task_aggregator    IN task_timeline_ea.id_task_aggregator%TYPE,
        i_id_doc_area           IN task_timeline_ea.id_doc_area%TYPE,
        i_code_status           IN task_timeline_ea.code_status%TYPE,
        i_flg_status            IN task_timeline_ea.flg_status_req%TYPE,
        i_end_date              IN task_timeline_ea.dt_end%TYPE,
        i_dt_req                IN task_timeline_ea.dt_req%TYPE,
        i_id_task_notes         IN task_timeline_ea.id_task_notes%TYPE,
        i_code_desc_sample_type IN task_timeline_ea.code_desc_sample_type%TYPE,
        i_flg_description       IN pn_dblock_ttp_mkt.flg_description%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE,
        o_short_desc            OUT NOCOPY CLOB,
        o_detailed_desc         OUT NOCOPY CLOB,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20) := 'GET_TASK_DESCS';
    BEGIN
        g_error := 'call pk_prog_notes_in.get_task_description';
        IF NOT pk_prog_notes_in.get_task_description(i_lang                  => i_lang,
                                                     i_prof                  => i_prof,
                                                     i_id_episode            => i_id_episode,
                                                     i_id_patient            => i_id_patient,
                                                     i_id_task_type          => i_id_task_type,
                                                     i_id_task               => i_id_task,
                                                     i_code_description      => i_code_description,
                                                     i_universal_desc_clob   => i_universal_desc_clob,
                                                     i_flg_sos               => i_flg_sos,
                                                     i_dt_begin              => i_dt_begin,
                                                     i_id_task_aggregator    => i_id_task_aggregator,
                                                     i_id_doc_area           => i_id_doc_area,
                                                     i_code_status           => i_code_status,
                                                     i_flg_status            => i_flg_status,
                                                     i_end_date              => i_end_date,
                                                     i_dt_req                => i_dt_req,
                                                     i_id_task_notes         => i_id_task_notes,
                                                     i_code_desc_sample_type => i_code_desc_sample_type,
                                                     i_flg_description       => i_flg_description,
                                                     i_description_condition => i_description_condition,
                                                     o_short_desc            => o_short_desc,
                                                     o_detailed_desc         => o_detailed_desc)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (o_detailed_desc IS NULL OR dbms_lob.compare(o_detailed_desc, empty_clob()) = 0)
        THEN
            g_error         := 'call pk_prog_notes_in.get_detailed_desc_all';
            o_detailed_desc := pk_prog_notes_in.get_detailed_desc_all(i_lang                  => i_lang,
                                                                      i_prof                  => i_prof,
                                                                      i_id_episode            => i_id_episode,
                                                                      i_id_task_type          => i_id_task_type,
                                                                      i_id_task               => i_id_task,
                                                                      i_universal_description => i_universal_desc_clob,
                                                                      i_short_desc            => o_short_desc,
                                                                      i_code_description      => i_code_description,
                                                                      i_flg_description       => i_flg_description,
                                                                      i_description_condition => i_description_condition);
        
            IF o_detailed_desc IS NULL
               OR dbms_lob.compare(o_detailed_desc, empty_clob()) = 0
            THEN
                o_detailed_desc := o_short_desc;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TASK_DESCS',
                                              o_error);
        
            RETURN FALSE;
    END get_task_descs;

    /**
    * Returns the data blocks array from definitive table
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_epis_pn             Note identifier
    * @param i_id_pn_soap_block       Soap blocks ID
    * @param o_data_blocks            Data blocks array
    * @param o_soap_blocks            Soap blocks array
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Rui Spratley
    * @version              2.6.0.5
    * @since                01-03-2011
    */

    FUNCTION get_notes_list
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_soap_block IN table_number,
        o_data_blocks      OUT NOCOPY table_number,
        o_soap_blocks      OUT NOCOPY table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_pn_soap_block table_number;
    BEGIN
    
        IF (i_id_pn_soap_block IS NULL OR NOT i_id_pn_soap_block.exists(1))
        THEN
            l_id_pn_soap_block := NULL;
        ELSE
            l_id_pn_soap_block := i_id_pn_soap_block;
        END IF;
    
        g_error := 'GET notes list. i_id_epis_pn: ' || i_id_epis_pn;
        SELECT DISTINCT id_pn_data_block, id_pn_soap_block
          BULK COLLECT
          INTO o_data_blocks, o_soap_blocks
          FROM (SELECT epdw.id_pn_data_block, epdw.id_pn_soap_block
                  FROM epis_pn_det epdw
                 WHERE epdw.id_epis_pn = i_id_epis_pn
                   AND (l_id_pn_soap_block IS NULL OR
                       epdw.id_pn_soap_block IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                                   column_value
                                                    FROM TABLE(l_id_pn_soap_block) t))
                   AND epdw.flg_status IN (pk_prog_notes_constants.g_epis_pn_det_flg_status_a,
                                           pk_prog_notes_constants.g_epis_pn_det_sug_add_s));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTES_LIST',
                                              o_error);
        
            RETURN FALSE;
    END get_notes_list;

    /**
    * Returns the child task types associated to the given data block
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_id_market              Market ID
    * @param i_id_department          Department ID
    * @param i_id_dep_clin_serv       Dep_clin_serv ID
    * @param i_id_pn_data_block       Data block ID
    * @param i_id_pn_soap_block       Soap block ID
    * @param i_id_task_type_prt       Task type parent Id
    * @param i_software               Software ID
    * @param o_task_types             Task types list
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.1.2
    * @since                01-09-2011
    */

    FUNCTION get_dblock_task_types
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_market        IN market.id_market%TYPE,
        i_id_department    IN department.id_department%TYPE,
        i_id_dep_clin_serv IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_software         IN software.id_software%TYPE,
        i_id_task_type_prt IN tl_task.id_parent%TYPE,
        i_id_task_related  IN table_number DEFAULT NULL,
        o_task_types       OUT NOCOPY table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id_task_related table_number;
    BEGIN
        g_error := 'GET DBLOCKS TASK TYPES';
    
        IF i_id_task_related IS NOT NULL
           AND i_id_task_related.exists(1)
           AND i_id_task_related(1) IS NOT NULL
        THEN
            l_id_task_related := i_id_task_related;
        ELSE
            l_id_task_related := NULL;
        END IF;
    
        SELECT /*+DYNAMIC_SAMPLING (dbtt 2)*/
         dbtt.id_task_type
          BULK COLLECT
          INTO o_task_types
          FROM TABLE(pk_progress_notes_upd.tf_dblock_task_type(i_lang,
                                                               i_prof,
                                                               i_id_episode,
                                                               i_id_market,
                                                               i_id_department,
                                                               i_id_dep_clin_serv,
                                                               i_id_pn_note_type,
                                                               i_software)) dbtt
         WHERE (dbtt.task_type_id_parent = i_id_task_type_prt OR i_id_task_type_prt IS NULL)
           AND dbtt.id_pn_data_block = i_id_pn_data_block
           AND dbtt.id_pn_soap_block = i_id_pn_soap_block
           AND (l_id_task_related IS NULL OR
               dbtt.id_task_type IN (SELECT /*+opt_estimate(table t rows=1)*/
                                       column_value
                                        FROM TABLE(l_id_task_related) t));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DBLOCK_TASK_TYPES',
                                              o_error);
        
            RETURN FALSE;
    END get_dblock_task_types;

    /**
    * Get the data block type.
    *
    * @param i_lang                       language identifier
    * @param i_prof                       logged professional structure
    * @param i_id_pn_data_block                 Note identifier    
    *
    * @return               note type id
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since                27-Jul-2011
    */
    FUNCTION get_data_block_type
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN pn_data_block.flg_type%TYPE IS
        l_flg_type pn_data_block.flg_type%TYPE;
        l_error    t_error_out;
    BEGIN
        SELECT p.flg_type
          INTO l_flg_type
          FROM pn_data_block p
         WHERE p.id_pn_data_block = i_id_pn_data_block;
    
        RETURN l_flg_type;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DATA_BLOCK_TYPE',
                                              l_error);
        
            RETURN NULL;
    END get_data_block_type;

    /**
    * Returns the Child tasks from i_id_task_type. If there is no childs it is returned the parent in this list.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type identifier
    * @param o_task_types             Child tasks from i_id_task_type. 
    * @param o_nr_task_types          Nr of task types
    *                                 If there is no childs it is returned the parent in this list.
    * @param o_error                  error
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                17-Nov-2011
    */

    FUNCTION get_child_task_types
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_task_type  IN tl_task.id_tl_task%TYPE,
        o_task_types    OUT NOCOPY table_number,
        o_nr_task_types OUT PLS_INTEGER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_CHILD_TASK_TYPES';
    BEGIN
    
        g_error := 'GET CHILD TASK TYPES FROM PARENT: ' || i_id_task_type;
        SELECT id_tl_task
          BULK COLLECT
          INTO o_task_types
          FROM (SELECT tt.id_tl_task
                  FROM tl_task tt
                 WHERE tt.id_parent = i_id_task_type);
    
        o_nr_task_types := o_task_types.count;
    
        --if there is no childs consider the parent task
        IF (o_nr_task_types = 0)
        THEN
            o_task_types.extend(1);
            o_task_types(1) := i_id_task_type;
            o_nr_task_types := 1;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_task_types := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_child_task_types;

    /**
    * Returns the parent data block that does not belong to the import structure data block types.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblokcs                Data blocks info
    * @param i_id_pn_data_block       Data block to search for parent
    * @param i_id_pn_soap_block       Soap block to search for parent
    *
    * @return                         Parent of the i_id_pn_data_block that does not belong to the import structure type
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                23-Jan-2012
    */

    FUNCTION get_parent_no_struct
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_data_blocks,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN pn_data_block.id_pn_data_block%TYPE IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_PARENT_NO_STRUCT';
        l_error     t_error_out;
        l_id_parent pn_data_block.id_pn_data_block%TYPE;
    BEGIN
    
        g_error := 'GET ID PARENT. i_id_pn_data_block: ' || i_id_pn_data_block;
    
        SELECT id_pn_data_block
          INTO l_id_parent
          FROM (SELECT id_pn_data_block
                  FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                         t.id_pn_data_block, t.id_pndb_parent, t.flg_type, LEVEL lv
                          FROM TABLE(i_dblocks) t
                         WHERE t.flg_type NOT IN (pk_prog_notes_constants.g_dblock_strut_date,
                                                  pk_prog_notes_constants.g_dblock_strut_group,
                                                  pk_prog_notes_constants.g_dblock_strut_subgroup)
                           AND t.block_id = i_id_pn_soap_block
                        CONNECT BY PRIOR t.id_pndb_parent = t.id_pn_data_block
                         START WITH t.id_pn_data_block = i_id_pn_data_block)
                 ORDER BY lv ASC)
         WHERE rownum = 1;
    
        RETURN l_id_parent;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN NULL;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_parent_no_struct;

    /**
    * Returns the nr of childs that a given data block has
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblokcs                Data blocks info
    * @param i_id_prt_data_block      Parent Data block to search for nr of childs
    * @param i_id_pn_soap_block       Soap block id
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_count_childs
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_dblocks           IN t_coll_data_blocks,
        i_id_prt_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block  IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_COUNT_CHILDS';
        l_error t_error_out;
        l_count PLS_INTEGER;
    BEGIN
    
        g_error := 'Count the nr of childs of. i_id_prt_data_block: ' || i_id_prt_data_block;
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                 t.id_pn_data_block
                  FROM TABLE(i_dblocks) t
                 WHERE t.id_pndb_parent = i_id_prt_data_block
                   AND t.block_id = i_id_pn_soap_block);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_count_childs;

    /**
    * Returns the nr of records childs of the import structure data block
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_data                   Imported data
    * @param i_id_prt_data_block      Parent Data block to search for nr of childs
    * @param i_id_pn_soap_block       Soap block ID
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_count_nr_records
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_data              IN t_coll_pn_work_data,
        i_id_prt_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block  IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN PLS_INTEGER IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_COUNT_NR_RECORDS';
        l_error t_error_out;
        l_count PLS_INTEGER;
    BEGIN
    
        g_error := 'Count the nr of childs of. i_id_prt_data_block: ' || i_id_prt_data_block;
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                 t.id_pn_data_block
                  FROM TABLE(i_data) t
                 WHERE t.id_parent_struct_imp = i_id_prt_data_block
                   AND t.id_pn_soap_block = i_id_pn_soap_block);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_count_nr_records;

    /**
    * Calculates the id_data_block to the used when replacing import structure by imported data.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_parent_no_struct    Parent data block (not considering import structure dblocks)
    * @param i_dblock_flg_type        Generic data block type (Date, group or sub-group) to be replaced by import data
    * @param i_id_dblock_parent       Parent data block
    * @param i_id_pn_soap_block       Soap block id
    * @param i_date                   Imported date
    * @param i_id_sub_group           Imported group
    * @param i_id_sub_sub_group       Imported sub-group
    * @param o_id_pn_data_block       Data block ID
    * @param o_id_dblock_no_checksum  String used to generate the data block ID
    *
    * @return                         false if errors occur, true otherwise
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_id_data_block_imp
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_parent_no_struct   IN pn_data_block.id_pn_data_block%TYPE,
        i_dblock_flg_type       IN pn_data_block.flg_type%TYPE,
        i_id_dblock_parent      IN pk_translation.t_desc_translation,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_date                  IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_sub_group          IN NUMBER,
        i_id_sub_sub_group      IN NUMBER,
        o_id_pn_data_block      OUT NOCOPY pn_data_block.id_pn_data_block%TYPE,
        o_id_dblock_no_checksum OUT NOCOPY pk_translation.t_desc_translation,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'GET_ID_DATA_BLOCK_IMP';
    
        l_separator CONSTANT VARCHAR2(1 CHAR) := '-';
    BEGIN
    
        g_error := 'Calc id_pn_data_block. i_id_parent_no_struct: ' || i_id_parent_no_struct || ' i_dblock_flg_type: ' ||
                   i_dblock_flg_type;
    
        o_id_dblock_no_checksum := i_id_pn_soap_block || l_separator || i_id_dblock_parent || l_separator;
    
        IF (i_dblock_flg_type = pk_prog_notes_constants.g_dblock_strut_date)
        THEN
            IF (i_date IS NOT NULL)
            THEN
                o_id_dblock_no_checksum := o_id_dblock_no_checksum || substr(pk_date_utils.date_send_tsz(i_date => i_date,
                                                                                                         i_lang => i_lang,
                                                                                                         i_prof => i_prof),
                                                                             1,
                                                                             8);
            ELSE
                o_id_dblock_no_checksum := o_id_dblock_no_checksum || l_separator || l_separator || l_separator ||
                                           l_separator || l_separator || l_separator || l_separator || l_separator ||
                                           l_separator;
            END IF;
        
        ELSIF (i_dblock_flg_type = pk_prog_notes_constants.g_dblock_strut_group)
        THEN
            o_id_dblock_no_checksum := o_id_dblock_no_checksum || i_id_sub_group;
        ELSE
            o_id_dblock_no_checksum := o_id_dblock_no_checksum || i_id_sub_sub_group;
        END IF;
    
        o_id_pn_data_block := dbms_utility.get_hash_value(o_id_dblock_no_checksum, 1, power(2, 30));
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_id_data_block_imp;

    /**
    * Calculates the id_data_block parent to the used when replacing import structure by imported data.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_parent_dblock       Parent data block (not considering import structure dblocks)
    * @param i_prev_id_data_block     Previsous data block (new parent)    
    * @param i_prev_dblock_str        Previsous data block (new parent) in str format
    * @param o_id_parent              Calculated id_pn_data_block
    * @param o_id_parent_str          Calculated id_pn_data_block in str format
    *
    * @return                         Calculated id_pn_data_block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_id_dblock_prt_imp
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_parent_dblock   IN pn_data_block.id_pndb_parent%TYPE,
        i_prev_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_prev_dblock_str    IN pk_translation.t_desc_translation,
        o_id_parent          OUT NOCOPY pn_data_block.id_pn_data_block%TYPE,
        o_id_parent_str      OUT NOCOPY pk_translation.t_desc_translation,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'GET_ID_DBLOCK_PRT_IMP';
    BEGIN
    
        g_error := 'Calc id_parent of the dta block. i_prev_id_data_block: ' || i_prev_id_data_block ||
                   ' i_id_parent_dblock: ' || i_id_parent_dblock;
    
        IF (pk_prog_notes_utils.get_data_block_type(i_lang             => i_lang,
                                                    i_prof             => i_prof,
                                                    i_id_pn_data_block => i_id_parent_dblock) IN
           (pk_prog_notes_constants.g_dblock_strut_date,
             pk_prog_notes_constants.g_dblock_strut_group,
             pk_prog_notes_constants.g_dblock_strut_subgroup))
        THEN
            o_id_parent     := i_prev_id_data_block;
            o_id_parent_str := i_prev_dblock_str;
        ELSE
            o_id_parent     := i_id_parent_dblock;
            o_id_parent_str := to_char(i_id_parent_dblock);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_id_dblock_prt_imp;

    /**
    * Checks if the data block i_id_pn_data_block exists in the list i_dblocks
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_pn_data_block       Data block to search for
    * @param i_id_pn_soap_block       Soap block to search for
    * @param i_id_dblock_parent       Parent Data block
    * @param i_dblokcs                Data blocks info
    
    *
    * @return                         Nr of childs of the given data block
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION check_exists_data_block
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_dblock_parent IN pn_data_block.id_pndb_parent%TYPE,
        i_dblocks          IN t_coll_data_blocks
    ) RETURN PLS_INTEGER IS
        l_func_name CONSTANT VARCHAR2(23 CHAR) := 'CHECK_EXISTS_DATA_BLOCK';
        l_error t_error_out;
        l_count PLS_INTEGER;
    BEGIN
    
        g_error := 'Checks if exists. i_id_pn_data_block: ' || i_id_pn_data_block;
    
        SELECT COUNT(1)
          INTO l_count
          FROM (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                 t.id_pn_data_block
                  FROM TABLE(i_dblocks) t
                 WHERE t.id_pn_data_block = i_id_pn_data_block
                   AND t.block_id = i_id_pn_soap_block
                   AND t.id_pndb_parent = i_id_dblock_parent);
    
        RETURN l_count;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END check_exists_data_block;

    /**
    * Gets the description to an import structure data block.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_dblock_flg_type        Generic data block type (Date, group or sub-group) to be replaced by import data
    * @param i_date_desc              Date description
    * @param i_sub_group_title        Sub group description
    * @param i_sub_sub_group_title    Sub sub group description
    *
    * @return                         Import struct data block desc
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                24-Jan-2012
    */

    FUNCTION get_imp_dblock_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_dblock_flg_type     IN pn_data_block.flg_type%TYPE,
        i_date_desc           IN pk_translation.t_desc_translation,
        i_sub_group_title     IN pk_translation.t_desc_translation,
        i_sub_sub_group_title IN pk_translation.t_desc_translation
    ) RETURN pk_translation.t_desc_translation IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_IMP_DBLOCK_DESC';
        l_error t_error_out;
        l_desc  pk_translation.t_desc_translation;
    BEGIN
    
        g_error := 'Get import structure data block desc. i_dblock_flg_type: ' || i_dblock_flg_type;
    
        l_desc := CASE i_dblock_flg_type
                      WHEN pk_prog_notes_constants.g_dblock_strut_date THEN
                       CASE
                           WHEN i_date_desc IS NOT NULL THEN
                            i_date_desc
                           ELSE
                            pk_message.get_message(i_code_mess => 'PN_M029', i_lang => i_lang)
                       END
                      WHEN pk_prog_notes_constants.g_dblock_strut_group THEN
                       CASE
                           WHEN i_sub_group_title IS NOT NULL THEN
                           
                            i_sub_group_title
                           ELSE
                            pk_message.get_message(i_code_mess => 'COMMON_M018', i_lang => i_lang)
                       END
                      ELSE
                       CASE
                           WHEN i_sub_sub_group_title IS NOT NULL THEN
                           
                            i_sub_sub_group_title
                           ELSE
                            pk_message.get_message(i_code_mess => 'PN_M031', i_lang => i_lang)
                       END
                  END;
    
        RETURN l_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
        
            RETURN NULL;
    END get_imp_dblock_desc;

    /**
    * Checks if the i_data_block exists in the list of data blocks
    *
    * @param i_table                  Data blocks info list
    * @param i_id_pn_data_block       data block identifier 
    *    
    *
    * @return                        -1: soap block not found; Otherwise: index of the soap block in the given list
    *
    * @author               Sofia Mendes
    * @version               2.6.1.3
    * @since                25-Jan-2012
    */
    FUNCTION search_tab_data_blocks
    (
        i_table      IN t_coll_data_blocks,
        i_data_block IN NUMBER
    ) RETURN NUMBER IS
        l_indice   NUMBER;
        l_nr_elems PLS_INTEGER;
    BEGIN
    
        l_indice := -1;
    
        l_nr_elems := i_table.count;
    
        FOR i IN 1 .. l_nr_elems
        LOOP
            IF i_table(i).id_pn_data_block = i_data_block
            THEN
                l_indice := i;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_indice;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END search_tab_data_blocks;

    /**
    * Gets the note ID associated to the given episode and note type
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_episode             Episode ID
    * @param i_id_pn_note_type        Note type ID
    * @param o_id_epis_pn             Note id, if exists one for the given episode and task type
    * @param i_id_pn_note_type        Error info
    *
    * @return                         Note id, if exists one for the given episode and task type
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                09-Feb-2012
    */

    FUNCTION get_note_id
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_id_epis_pn      OUT epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_NOTE_ID';
    BEGIN
        BEGIN
            g_error := 'GET NOTE ID. i_id_episode: ' || i_id_episode || ' i_id_pn_note_type: ' || i_id_pn_note_type;
            SELECT id_epis_pn
              INTO o_id_epis_pn
              FROM (SELECT epn.id_epis_pn
                      FROM epis_pn epn
                     WHERE epn.id_episode = i_id_episode
                       AND epn.id_pn_note_type = i_id_pn_note_type
                       AND epn.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_m
                     ORDER BY 1 DESC)
             WHERE rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                o_id_epis_pn := NULL;
        END;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
        
            RETURN FALSE;
    END get_note_id;

    /**
    *  Get the task text to be saved on note. Concats the title and subtitle if they exists
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_group_title            Title
    * @param i_group_sub_title        Sub title
    * @param i_group_sub_sub_title    Sub Sub title
    * @param i_task_desc              Original task description    
    *
    * @return                         Final task desc
    *
    * @author                         Sofia Mendes
    * @version                        2.6.1.2
    * @since                          07-Mar-2012
    */
    FUNCTION get_task_text
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_group_title         IN VARCHAR2,
        i_group_sub_title     IN VARCHAR2,
        i_group_sub_sub_title IN VARCHAR2,
        i_task_desc           IN CLOB
    ) RETURN CLOB IS
        l_task_desc CLOB;
        l_error     t_error_out;
    BEGIN
        g_error     := 'CALC task description. i_group_title: ' || i_group_title || ' i_group_sub_title: ' ||
                       i_group_sub_title;
        l_task_desc := CASE
                           WHEN i_group_title IS NOT NULL THEN
                            i_group_title || pk_prog_notes_constants.g_new_line
                           ELSE
                            NULL
                       END ||
                      
                       CASE
                           WHEN i_group_sub_title IS NOT NULL THEN
                            pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space || i_group_sub_title ||
                            pk_prog_notes_constants.g_new_line
                           
                            ||
                           
                            pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                            pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space
                           ELSE
                            NULL
                       END ||
                      
                       CASE
                           WHEN i_group_sub_title IS NULL
                                AND i_group_title IS NOT NULL THEN
                            pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                            pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space || i_task_desc ||
                            pk_prog_notes_constants.g_new_line ||
                           
                            CASE
                                WHEN i_group_sub_sub_title IS NOT NULL THEN
                                 pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                                 pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space || i_group_sub_sub_title ||
                                 pk_prog_notes_constants.g_new_line
                                
                                 ||
                                
                                 pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                                 pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                                 pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space
                                ELSE
                                 NULL
                            END
                           ELSE
                            i_task_desc
                       END;
    
        RETURN l_task_desc;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TASK_TEXT',
                                              l_error);
        
            RETURN NULL;
    END get_task_text;

    /**
    * Returns the template name in the templates related tasks.
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_coll_dblock_task_type  Data block task types info structure
    * @param i_id_pn_data_block       Data block Id    
    *
    * @return                         Y - If the task is to be synchronized immediately with the directed area 
    *                                 when is changed in the note. N- otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.1.2
    * @since               19-Sep-2011
    */
    FUNCTION get_flg_synch_area
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_coll_dblock_task_type IN t_coll_dblock_task_type,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN tl_task.flg_synch_area%TYPE IS
        l_error          t_error_out;
        l_flg_synch_area tl_task.flg_synch_area%TYPE;
    BEGIN
        g_error := 'GET FLG_SYNCH_AREA. i_id_pn_data_block: ' || i_id_pn_data_block;
        BEGIN
            SELECT /*+DYNAMIC_SAMPLING (dbt 1)*/
             dbt.flg_synch_area
              INTO l_flg_synch_area
              FROM TABLE(i_coll_dblock_task_type) dbt
             WHERE dbt.id_pn_data_block = i_id_pn_data_block
               AND rownum = 1;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_synch_area := pk_alert_constant.g_no;
        END;
    
        RETURN l_flg_synch_area;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_flg_synch_area',
                                              l_error);
        
            RETURN '';
    END get_flg_synch_area;

    /**
    * Get if a data block has action.
    *
    * @param i_lang                   Language identifier
    * @param i_prof                   Logged professional structure
    * @param i_episode                Episode ID
    * @param i_epis_pn                Epis pn ID 
    * @param i_pn_note_type           Note type ID 
    * @param i_pn_data_block          Data block ID 
    * @param i_id_task_type           Task type ID    
    *
    * @return o_flg_has_action        Y - If the data block has action
                                      N - If the data block doesn't have action
    *
    * @author                         Vanessa Barsottelli
    * @version                        2.6.4.2
    * @since                          19-Nov-2014
    */
    FUNCTION has_data_block_action
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_episode        IN episode.id_episode%TYPE,
        i_epis_pn        IN epis_pn.id_epis_pn%TYPE,
        i_pn_note_type   IN pn_note_type.id_pn_note_type%TYPE,
        i_pn_data_block  IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        o_flg_has_action OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'HAS_DATA_BLOCK_ACTION';
    
        l_market          market.id_market%TYPE;
        l_profile         profile_template.id_profile_template%TYPE;
        l_category        category.id_category%TYPE;
        l_department      department.id_department%TYPE;
        l_dep_clin_serv   dep_clin_serv.id_dep_clin_serv%TYPE;
        l_dblock_flg_type pn_data_block.flg_type%TYPE;
    BEGIN
        g_error := 'GET flg_type pn_data_block: ' || i_pn_data_block;
        SELECT d.flg_type
          INTO l_dblock_flg_type
          FROM pn_data_block d
         WHERE d.id_pn_data_block = i_pn_data_block;
    
        IF l_dblock_flg_type IN
           (pk_prog_notes_constants.g_dblock_free_text_w_save, pk_prog_notes_constants.g_data_block_action)
        THEN
            o_flg_has_action := pk_alert_constant.get_yes;
        ELSE
            g_error  := 'GET market';
            l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        
            g_error   := 'GET profile_template';
            l_profile := pk_tools.get_prof_profile_template(i_prof => i_prof);
        
            g_error    := 'GET category';
            l_category := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error      := 'GET department';
            l_department := pk_progress_notes_upd.get_department(i_episode => i_episode, i_epis_pn => i_epis_pn);
        
            g_error         := 'GET dep_clin_serv';
            l_dep_clin_serv := pk_progress_notes_upd.get_dep_clin_serv(i_episode => i_episode, i_epis_pn => i_epis_pn);
        
            g_error := 'GET o_flg_has_action';
            BEGIN
                SELECT decode(COUNT(1), 0, pk_alert_constant.get_no, pk_alert_constant.get_yes)
                  INTO o_flg_has_action
                  FROM TABLE(pk_progress_notes_upd.tf_button_blocks(i_prof            => i_prof,
                                                                    i_profile         => l_profile,
                                                                    i_category        => l_category,
                                                                    i_market          => l_market,
                                                                    i_department      => l_department,
                                                                    i_dcs             => l_dep_clin_serv,
                                                                    i_id_pn_note_type => i_pn_note_type,
                                                                    i_software        => i_prof.software)) t
                 INNER JOIN ( --Get task buttons task type
                             SELECT c.id_conf_button_block, t.id_tl_task, t.id_parent
                               FROM tl_task t
                              INNER JOIN conf_button_block c
                                 ON c.id_task_type = t.id_tl_task
                                 OR c.id_task_type = t.id_parent
                              WHERE (t.id_tl_task = i_id_task_type OR t.id_parent = i_id_task_type)
                                AND c.id_pn_data_block = i_pn_data_block
                                AND c.id_pn_group IS NULL
                             UNION ALL
                             --Get task type from pn_group
                             SELECT c.id_conf_button_block, t.id_tl_task, t.id_parent
                               FROM tl_task t
                              INNER JOIN pn_group_task_types gt
                                 ON gt.id_task_type = t.id_tl_task
                                 OR gt.id_task_type = t.id_parent
                              INNER JOIN conf_button_block c
                                 ON c.id_pn_group = gt.id_pn_group
                              WHERE (t.id_tl_task = i_id_task_type OR t.id_parent = i_id_task_type)
                                AND c.id_pn_data_block = i_pn_data_block
                                AND c.id_pn_group IS NOT NULL) b
                    ON b.id_conf_button_block = t.id_conf_button_block;
            EXCEPTION
                WHEN no_data_found THEN
                    o_flg_has_action := pk_alert_constant.get_no;
            END;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END has_data_block_action;

    /********************************************************************************************
    * get the actions available for a given record.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_episode                 episode id     
    * @param       i_id_task_type            Type of the task
    * @param       i_id_task                 Task reference ID    
    * @param       i_flg_review              Y-the review action should be available. N-otherwisse
    * @param       i_flg_remove              Y-the remove action should be available. N-otherwisse
    * @param       i_flg_review_all          Y-the review action should be available. N-otherwisse
    * @param       i_flg_table_origin        Table origin from templates
    * @param       i_flg_write               Y-it is allowed to write in the task data block. N-otherwisse
    * @param       i_flg_actions_available   Y-The area actions are available. N-otherwisse
    * @param       i_flg_editable            A-All editable; N-not editable; T-text editable
    * @param       i_flg_dblock_editable     Y- Tis data block has edition permission. N-Otherwise
    * @param       i_id_pn_note_type         Note type Id
    * @param       i_id_pn_data_block        Data block Id
    * @param       i_id_pn_soap_block        Soap block Id
    * @param       o_actions                 list of actions
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 19-Mar-2012
    ********************************************************************************************/
    FUNCTION get_actions
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_episode               IN episode.id_episode%TYPE,
        i_id_task_type          IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task               IN epis_pn_det_task.id_task%TYPE,
        i_flg_review            IN VARCHAR2,
        i_flg_remove            IN VARCHAR2,
        i_flg_review_all        IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_table_origin      IN epis_pn_det_task.flg_table_origin%TYPE,
        i_flg_actions_available IN pn_dblock_mkt.flg_actions_available%TYPE,
        i_flg_editable          IN VARCHAR2,
        i_flg_dblock_editable   IN pn_dblock_mkt.flg_editable%TYPE,
        i_id_pn_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        o_actions               OUT NOCOPY pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(11 CHAR) := 'GET_ACTIONS';
        l_exception EXCEPTION;
        l_task_actions          t_coll_action;
        l_coll_dblock_task_type t_coll_dblock_task_type;
        l_flg_review_avail      pn_dblock_ttp_mkt.flg_review_avail%TYPE;
        l_last_n_records_nr     pn_dblock_ttp_mkt.last_n_records_nr%TYPE;
        l_flg_has_action        VARCHAR2(1) := i_flg_actions_available;
    BEGIN
        --The availability of the actions and the buttons should be managed by configuration
        --Commented this validations otherwise it is not possible to have actions without having the shortcut
        /*IF (i_flg_actions_available = pk_alert_constant.g_yes AND
           i_flg_editable = pk_prog_notes_constants.g_editable_all AND
           i_flg_dblock_editable IN
           (pk_prog_notes_constants.g_editable_y, pk_prog_notes_constants.g_editable_to_review_k))
        THEN
        
            g_error := 'CALL has_button_action';
            pk_alertlog.log_debug(g_error, g_package);
            IF NOT has_data_block_action(i_lang           => i_lang,
                                         i_prof           => i_prof,
                                         i_episode        => i_episode,
                                         i_epis_pn        => NULL,
                                         i_pn_note_type   => i_id_pn_note_type,
                                         i_pn_data_block  => i_id_pn_data_block,
                                         i_id_task_type   => i_id_task_type,
                                         o_flg_has_action => l_flg_has_action,
                                         o_error          => o_error)
            THEN
                RAISE l_exception;
            END IF;
        END IF;*/
    
        IF (i_flg_dblock_editable IN (pk_prog_notes_constants.g_editable_y,
                                      pk_prog_notes_constants.g_editable_to_review_k,
                                      pk_prog_notes_constants.g_not_editable_dimmed_x,
                                      pk_prog_notes_constants.g_not_editable_n))
        THEN
            g_error                 := 'CALL pk_prog_notes_upd.tf_dblock_task_type. i_id_pn_note_type: ' ||
                                       i_id_pn_note_type || ' i_id_task_type: ' || i_id_task_type ||
                                       ' i_id_pn_data_block: ' || i_id_pn_data_block || ' i_id_pn_soap_block: ' ||
                                       i_id_pn_soap_block;
            l_coll_dblock_task_type := pk_progress_notes_upd.tf_dblock_task_type(i_lang             => i_lang,
                                                                                 i_prof             => i_prof,
                                                                                 i_id_episode       => i_episode,
                                                                                 i_id_market        => NULL,
                                                                                 i_id_department    => NULL,
                                                                                 i_id_dep_clin_serv => NULL,
                                                                                 i_id_pn_note_type  => i_id_pn_note_type,
                                                                                 i_software         => NULL,
                                                                                 i_id_task_type     => i_id_task_type,
                                                                                 i_id_pn_data_block => i_id_pn_data_block,
                                                                                 i_id_pn_soap_block => i_id_pn_soap_block);
        
            IF (l_coll_dblock_task_type IS NOT NULL AND l_coll_dblock_task_type.exists(1))
            THEN
                l_flg_review_avail  := l_coll_dblock_task_type(1).flg_review_avail;
                l_last_n_records_nr := l_coll_dblock_task_type(1).last_n_records_nr;
            END IF;
        
            IF l_flg_has_action = pk_alert_constant.g_yes
            THEN
                g_error := 'CALL get_task_actions';
                IF NOT pk_prog_notes_in.get_task_actions(i_lang              => i_lang,
                                                         i_prof              => i_prof,
                                                         i_episode           => i_episode,
                                                         i_task_type         => i_id_task_type,
                                                         i_id_task           => i_id_task,
                                                         i_flg_table_origin  => i_flg_table_origin,
                                                         i_flg_write         => pk_alert_constant.g_yes,
                                                         i_last_n_records_nr => l_last_n_records_nr,
                                                         o_task_actions      => l_task_actions,
                                                         o_error             => o_error)
                THEN
                    RAISE l_exception;
                END IF;
            END IF;
        
            g_error := 'get o_actions cursor with cpoe actions';
            OPEN o_actions FOR
            -- specific actions for the selected tasks
            -- returns external actions for tasks
                SELECT /*+ OPT_ESTIMATE (TABLE task_action ROWS=1)*/
                 task_action.id_action   AS id_action,
                 task_action.id_parent   AS id_parent,
                 task_action.level_nr    AS level_nr,
                 task_action.from_state  AS from_state,
                 task_action.to_state,
                 task_action.desc_action AS desc_action,
                 task_action.icon        AS icon,
                 task_action.flg_default AS flg_default,
                 task_action.action      AS action,
                 task_action.flg_active  AS flg_active,
                 NULL                    AS rank
                  FROM TABLE(l_task_actions) task_action
                --single page actions for the task selected
                UNION ALL
                SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                 id_action,
                 id_parent,
                 level_nr,
                 from_state,
                 to_state,
                 desc_action,
                 icon,
                 flg_default,
                 action,
                 CASE
                      WHEN i_flg_editable IN (pk_alert_constant.g_no, pk_prog_notes_constants.g_not_editable_by_time) THEN
                       pk_alert_constant.g_inactive
                      ELSE
                       decode(action,
                              pk_prog_notes_constants.g_act_remove,
                              decode(i_flg_remove,
                                     pk_alert_constant.g_yes,
                                     pk_alert_constant.g_active,
                                     pk_alert_constant.g_inactive),
                              pk_prog_notes_constants.g_act_review,
                              
                              CASE
                                  WHEN l_flg_review_avail = pk_alert_constant.g_yes
                                       AND
                                       check_is_task_with_review(i_lang => i_lang, i_prof => i_prof, i_id_task_type => i_id_task_type) =
                                       pk_alert_constant.g_yes THEN
                                   pk_alert_constant.g_active
                                  ELSE
                                   pk_alert_constant.g_inactive
                              END,
                              pk_prog_notes_constants.g_act_comment,
                              decode(i_id_task_type,
                                     pk_prog_notes_constants.g_task_lab_results,
                                     pk_alert_constant.g_active,
                                     pk_prog_notes_constants.g_task_exam_results,
                                     pk_alert_constant.g_active,
                                     pk_prog_notes_constants.g_task_medic_here,
                                     pk_alert_constant.g_active,
                                     pk_prog_notes_constants.g_task_procedures,
                                     decode(pk_procedures_external_api_db.check_procedure_revision(i_lang      => i_lang,
                                                                                                   i_prof      => i_prof,
                                                                                                   i_treatment => i_id_task),
                                            pk_alert_constant.g_yes,
                                            pk_alert_constant.g_active,
                                            pk_alert_constant.g_inactive))
                              
                              )
                  END flg_active,
                 NULL rank
                  FROM TABLE(pk_action.tf_get_actions(i_lang, i_prof, pk_prog_notes_constants.g_act_edit, NULL)) t
                 WHERE (( --
                        (i_flg_review_all = pk_alert_constant.g_no AND t.action <> pk_prog_notes_constants.g_act_review) OR
                        (i_flg_review_all = pk_alert_constant.g_yes AND
                        ((i_id_task_type <> pk_prog_notes_constants.g_task_reported_medic) OR
                        (i_id_task_type = pk_prog_notes_constants.g_task_reported_medic AND
                        t.action <> pk_prog_notes_constants.g_act_review))) --
                       ) AND ( --
                        (t.action = pk_prog_notes_constants.g_act_comment AND
                        i_id_task_type IN (pk_prog_notes_constants.g_task_lab_results,
                                                   pk_prog_notes_constants.g_task_exam_results,
                                                   pk_prog_notes_constants.g_task_medic_here,
                                                   pk_prog_notes_constants.g_task_procedures) AND
                        t.flg_active <> 'N') OR t.action <> pk_prog_notes_constants.g_act_comment --
                       ))
                    OR t.action = 'REMOVE_FROM_NOTE';
        ELSE
            pk_types.open_my_cursor(o_actions);
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            pk_types.open_my_cursor(o_actions);
            RETURN FALSE;
    END get_actions;

    /********************************************************************************************
    * Get the review context of a task type
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_task_type            Type of the task    
    * @param       o_review_context          Task type review context
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_task_review_context
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        o_review_context OUT NOCOPY tl_task.review_context%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET task type review context. i_id_task_type: ' || i_id_task_type;
        SELECT tt.review_context
          INTO o_review_context
          FROM tl_task tt
         WHERE tt.id_tl_task = i_id_task_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_TASK_REVIEW_CONTEXT',
                                              o_error);
            RETURN FALSE;
    END get_task_review_context;

    /********************************************************************************************
    * Check if it is a task with review
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_task_type            Type of the task    
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 17-Dec-2012
    ********************************************************************************************/
    FUNCTION check_is_task_with_review
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
    ) RETURN VARCHAR2 IS
        l_review_context tl_task.review_context%TYPE;
        l_review         VARCHAR2(1 CHAR);
        l_error          t_error_out;
    BEGIN
        g_error := 'CALL get_task_review_context: ' || i_id_task_type;
        IF NOT get_task_review_context(i_lang           => i_lang,
                                       i_prof           => i_prof,
                                       i_id_task_type   => i_id_task_type,
                                       o_review_context => l_review_context,
                                       o_error          => l_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_review_context IS NULL)
        THEN
            l_review := pk_alert_constant.g_no;
        ELSE
            l_review := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_review;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'check_is_task_with_review',
                                              l_error);
            RETURN NULL;
    END check_is_task_with_review;

    /********************************************************************************************
    * Get the configs associated to the area.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_area                    Area internal name    
    * @param       o_area_configs            Area configs
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_area_configs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_area         IN pn_area.internal_name%TYPE,
        i_id_episode   IN episode.id_episode%TYPE,
        o_area_configs OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_area_confs t_rec_area;
        l_id_report  pn_area.id_report%TYPE;
    BEGIN
    
        g_error      := 'CALL pk_prog_notes_utils.get_area_config';
        l_area_confs := pk_prog_notes_utils.get_area_config(i_lang             => i_lang,
                                                            i_prof             => i_prof,
                                                            i_id_episode       => i_id_episode,
                                                            i_id_market        => NULL,
                                                            i_id_department    => NULL,
                                                            i_id_dep_clin_serv => NULL,
                                                            i_area             => i_area,
                                                            i_episode_software => NULL);
    
        l_id_report := l_area_confs.id_report;
    
        g_error := 'GET the area name. i_area: ' || i_area;
        OPEN o_area_configs FOR
            SELECT --pk_translation.get_translation(i_lang, pa.code_pn_area) area_desc,
             pa.cancel_reason_note,
             pa.cancel_reason_addendum,
             pa.stext_addendum_create,
             pa.stext_addendum_cancel,
             pa.stext_note_cancel,
             nvl(l_id_report, pa.id_report) id_report
              FROM pn_area pa
             WHERE pa.internal_name = i_area;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_AREA_CONFIGS',
                                              o_error);
            RETURN FALSE;
    END get_area_configs;

    /********************************************************************************************
    * Get the name of the note type.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_area                    Area internal name    
    * @param       o_desc                    Description of the note type
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 12-Abr-2012
    ********************************************************************************************/
    FUNCTION get_note_type_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_desc            OUT NOCOPY VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET note type desc. i_id_pn_note_type: ' || i_id_pn_note_type;
        SELECT pk_message.get_message(i_lang, i_prof, pnt.code_pn_note_type)
          INTO o_desc
          FROM pn_note_type pnt
         WHERE pnt.id_pn_note_type = i_id_pn_note_type;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_TYPE_DESC',
                                              o_error);
            RETURN FALSE;
    END get_note_type_desc;

    /********************************************************************************************
    * Get the date of the last note of the given note type to the given episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_pn_note_type         Note type ID
    * @param       o_note_date               Date of the last note
    * @param       o_id_epis_pn              Note Id
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_last_note_date
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        io_id_epis_pn     IN OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_note_date       OUT NOCOPY epis_pn.dt_pn_date%TYPE,
        o_pn_date         OUT NOCOPY epis_pn.dt_pn_date%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET last note date. i_id_pn_note_type: ' || i_id_pn_note_type || ' i_id_episode: ' || i_id_episode;
        SELECT t.dt_note, t.dt_pn, t.id_epis_pn
          INTO o_note_date, o_pn_date, io_id_epis_pn
          FROM (SELECT nvl(e.dt_last_update, e.dt_create) dt_note,
                       nvl(e.dt_pn_date, e.dt_create) dt_pn,
                       e.id_epis_pn,
                       row_number() over(PARTITION BY e.id_episode, e.id_pn_note_type ORDER BY e.dt_pn_date DESC) rn
                  FROM epis_pn e
                 WHERE e.id_episode = i_id_episode
                   AND (io_id_epis_pn IS NULL OR e.id_epis_pn = io_id_epis_pn)
                   AND e.id_pn_note_type = i_id_pn_note_type
                   AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) t
         WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_note_date := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            o_note_date := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_LAST_NOTE_DATE',
                                              o_error);
            RETURN FALSE;
    END get_last_note_date;

    /********************************************************************************************
    * Get the date of the last note of the given note type to the given episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_flg_status_available    Y-The status should be available. N-otherwise
    * @param       i_flg_status              Note status
    *
    * @return      varchar2                   Y-The status should be shown. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION check_has_status
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_flg_status_available IN pn_note_type_mkt.flg_status_available%TYPE,
        i_flg_status           IN epis_pn.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_status VARCHAR2(1 CHAR) := pk_alert_constant.g_yes;
        l_error  t_error_out;
    BEGIN
    
        IF (i_flg_status_available = pk_alert_constant.g_no)
        THEN
            IF (i_flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c)
            THEN
                l_status := pk_alert_constant.g_no;
            END IF;
        END IF;
    
        RETURN l_status;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_HAS_STATUS',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END check_has_status;

    /********************************************************************************************
    * Checks if a task has some active action or not.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_flg_import              B-import in block. N-otherwise
    * @param       i_id_pn_note_type         Note type ID
    * @param       i_flg_dblock_type         Data block flg_type
    *
    * @return      varchar2                   Y-There is some action available over the task. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_flg_no_action
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_flg_editable    IN VARCHAR2,
        i_flg_dblock_type IN pn_data_block.flg_type%TYPE
    ) RETURN VARCHAR2 IS
        l_error t_error_out;
        l_res   VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        g_error := 'i_flg_editable: ' || i_flg_editable;
        IF i_flg_editable IN (pk_alert_constant.g_no, pk_prog_notes_constants.g_not_editable_by_time)
           AND i_flg_dblock_type NOT IN (pk_prog_notes_constants.g_data_block_free_text,
                                         pk_prog_notes_constants.g_data_block_cdate,
                                         pk_prog_notes_constants.g_data_block_date_time)
        THEN
            l_res := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_FLG_NO_ACTION',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END get_flg_no_action;

    /********************************************************************************************
    * Checks if the given note (i_id_epis_pn) is the most recente note create in the note area.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    *
    * @return      varchar2                   Y-The given note is the most recent one of that area. N-otherwise
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION check_more_recent_note
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN VARCHAR2 IS
        l_error             t_error_out;
        l_id_epis_pn_recent epis_pn.id_epis_pn%TYPE;
        l_id_pn_area        pn_area.id_pn_area%TYPE;
    BEGIN
        g_error := 'GET NOTE AREA: i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.id_pn_area
          INTO l_id_pn_area
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        g_error := 'GET MOST RECENT NOTE. i_id_episode: ' || i_id_episode || ' l_id_pn_area: ' || l_id_pn_area;
        SELECT id_epis_pn
          INTO l_id_epis_pn_recent
          FROM (SELECT epn.id_epis_pn, row_number() over(PARTITION BY epn.id_pn_area ORDER BY epn.dt_pn_date DESC) rn
                  FROM epis_pn epn
                 WHERE epn.id_episode = i_id_episode
                   AND epn.id_pn_area = l_id_pn_area)
         WHERE rn = 1;
    
        g_error := 'CHECK most recent note: l_id_epis_pn_recent: ' || l_id_epis_pn_recent;
        IF (l_id_epis_pn_recent = i_id_epis_pn)
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_MORE_RECENT_NOTE',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END check_more_recent_note;

    /********************************************************************************************
    * Get the note creation date.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_epis_pn              Note id
    * @param       o_note_date               Note date
    * @param       o_error                   Error info
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION get_note_creation_date
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_note_date  OUT epis_pn.dt_pn_date%TYPE,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        g_error := 'GET NOTE DATE: i_id_epis_pn: ' || i_id_epis_pn;
        SELECT epn.dt_create
          INTO o_note_date
          FROM epis_pn epn
         WHERE epn.id_epis_pn = i_id_epis_pn;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_note_date := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_NOTE_CREATION_DATE',
                                              o_error);
            RETURN FALSE;
    END get_note_creation_date;

    /********************************************************************************************
    * Check if it is possible to edit the note.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_editable_nr_min         Nr of minutes that the professional has to edit the note since its creation.
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_pn_note_type         Note type ID
    *
    * @return      varchar2                   1-editable. 0-not editable
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION check_time_to_edit
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min  IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_synchronized IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN PLS_INTEGER IS
        l_error        t_error_out;
        l_pn_note_date epis_pn.dt_pn_date%TYPE;
    
        l_limit_date TIMESTAMP WITH LOCAL TIME ZONE;
        l_res        PLS_INTEGER := 1;
    
        l_id_epis_pn epis_pn.id_epis_pn%TYPE := i_id_epis_pn;
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_TIME_TO_EDIT';
    BEGIN
        IF (i_editable_nr_min IS NOT NULL)
        THEN
            IF (i_id_epis_pn IS NULL AND i_flg_synchronized = pk_alert_constant.g_yes)
            THEN
                --autodiscover the note ID                -
                g_error := 'CALL pk_prog_notes_utils.get_note_id. i_id_episode: ' || i_id_episode ||
                           ' i_id_pn_note_type: ' || i_id_pn_note_type;
                IF NOT pk_prog_notes_utils.get_note_id(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_episode      => i_id_episode,
                                                       i_id_pn_note_type => i_id_pn_note_type,
                                                       o_id_epis_pn      => l_id_epis_pn,
                                                       o_error           => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF (l_id_epis_pn IS NOT NULL)
            THEN
                g_error := 'CALL get_note_date. ';
                IF NOT get_note_creation_date(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_id_epis_pn => i_id_epis_pn,
                                              o_note_date  => l_pn_note_date,
                                              o_error      => l_error)
                THEN
                    RAISE g_exception;
                END IF;
            END IF;
        
            IF (l_pn_note_date IS NOT NULL)
            THEN
                g_error      := 'CALL pk_date_utils.add_to_ltstz';
                l_limit_date := pk_date_utils.add_to_ltstz(i_timestamp => l_pn_note_date,
                                                           i_amount    => i_editable_nr_min,
                                                           i_unit      => 'MINUTE');
            
                IF (l_limit_date < current_date)
                THEN
                    l_res := 0;
                END IF;
            END IF;
        END IF;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'CHECK_TIME_TO_EDIT',
                                              l_error);
            RETURN pk_alert_constant.g_no;
    END check_time_to_edit;

    /********************************************************************************************
    * Get Dep_clin_ser from note or episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Note id
    * @param       o_id_dep_clin_serv        Dep_clin_serv ID
    * @param       o_error                   Error info
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 30-Abr-2012
    ********************************************************************************************/
    FUNCTION get_dep_clin_serv
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_epis_pn       IN epis_pn.id_epis_pn%TYPE,
        o_id_dep_clin_serv OUT epis_pn.id_dep_clin_serv%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(17 CHAR) := 'GET_DEP_CLIN_SERV';
    BEGIN
        g_error := 'GET DEP_CLIN_SERV: i_id_epis_pn: ' || i_id_epis_pn;
        IF (i_id_epis_pn IS NOT NULL)
        THEN
            g_error := 'CALL pk_prog_notes_utils.get_pn_dep_clin_serv';
            IF NOT pk_prog_notes_utils.get_pn_dep_clin_serv(i_lang          => i_lang,
                                                            i_prof          => i_prof,
                                                            i_epis_pn       => i_id_epis_pn,
                                                            o_dep_clin_serv => o_id_dep_clin_serv,
                                                            o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
        ELSE
            g_error := 'CALL pk_episode.get_epis_dep_clin_serv: i_id_episode: ' || i_id_episode;
            IF NOT pk_episode.get_epis_dep_clin_serv(i_lang             => i_lang,
                                                     i_prof             => i_prof,
                                                     i_episode          => i_id_episode,
                                                     o_id_dep_clin_serv => o_id_dep_clin_serv,
                                                     o_error            => o_error)
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
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_dep_clin_serv;

    /********************************************************************************************
    * Check if it is necessary to auto-populate or syncronize the note.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_editable_nr_min         Nr of minutes that the professional has to edit the note since its creation.
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_pn_note_type         Note type ID
    * @param       i_id_epis_pn_det_task     Epis_pn_det_task ids list
    * @param       o_error                   Error info
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 29-May-2012
    ********************************************************************************************/
    FUNCTION check_synchronization_needed
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn_det_task  IN table_number,
        i_flg_sync_after_disch IN pn_note_type_mkt.flg_sync_after_disch%TYPE DEFAULT pk_alert_constant.g_no,
        o_flg_synch            OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(28 CHAR) := 'CHECK_SYNCHRONIZATION_NEEDED';
        l_flg_status episode.flg_status%TYPE;
    BEGIN
        --if the episode is inactive do not synchronize the note
        g_error := 'Call pk_episode.get_flg_status. i_id_episode: ' || i_id_episode;
        IF NOT pk_episode.get_flg_status(i_lang       => i_lang,
                                         i_prof       => i_prof,
                                         i_id_episode => i_id_episode,
                                         o_flg_status => l_flg_status,
                                         o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        IF (l_flg_status = pk_alert_constant.g_inactive AND
           nvl(i_flg_sync_after_disch, pk_alert_constant.g_no) = pk_alert_constant.g_no)
        THEN
            o_flg_synch := 0;
        ELSE
            g_error := 'Check synch needed: i_id_epis_pn: ' || i_id_epis_pn || ' i_editable_nr_min: ' ||
                       i_editable_nr_min;
            --the note is only sncronized if the edition time had not expired
            IF (i_editable_nr_min IS NOT NULL AND i_id_epis_pn IS NOT NULL)
            THEN
            
                g_error := 'CALL pk_prog_notes_utils.check_time_to_edit';
                IF pk_prog_notes_utils.check_time_to_edit(i_lang             => i_lang,
                                                          i_prof             => i_prof,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_epis_pn       => i_id_epis_pn,
                                                          i_editable_nr_min  => i_editable_nr_min,
                                                          i_flg_synchronized => i_flg_synchronized,
                                                          i_id_pn_note_type  => i_id_pn_note_type) = 1
                THEN
                    o_flg_synch := 1;
                ELSE
                    o_flg_synch := 0;
                END IF;
            ELSE
                o_flg_synch := 1;
            END IF;
        
            IF i_id_epis_pn_det_task IS NOT NULL
               AND i_id_epis_pn_det_task.exists(1)
               AND i_id_epis_pn_det_task(1) IS NOT NULL
            THEN
                o_flg_synch := 1;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_synchronization_needed;

    /********************************************************************************************
    * Get the auto-population type.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_epis_pn              Epis pn ID
    * @param       i_flg_synchronized        Y-Single page. N-single note
    * @param       i_id_epis_pn_det_task     Epis_pn_det_task IDs list
    * @param       i_flg_search_dblock       Types of Data Blocks to search on records
    *
    * @return      varchar2                   R-synchronizing only a record
                                              A-auto-population    
                                              C-synchonize all records in the note
    *
    * @author                                Sofia Mendes
    * @since                                 29-May-2012
    ********************************************************************************************/
    FUNCTION get_autopop_type_flg
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_epis_pn          IN epis_pn.id_epis_pn%TYPE,
        i_flg_synchronized    IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_id_epis_pn_det_task IN table_number,
        i_flg_search_dblock   IN VARCHAR2
    ) RETURN VARCHAR2 IS
        l_error      t_error_out;
        l_flg_search VARCHAR2(1 CHAR);
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_AUTOPOP_TYPE_FLG';
    BEGIN
        --in notes, the auto-population is only performed when the note is created,
        --in the editions only synchronization is allowed, if configured
        --if a more recent note exists, no auto-population nor synchronization is performed
    
        IF (i_id_epis_pn_det_task IS NOT NULL AND i_id_epis_pn_det_task.exists(1) AND
           i_id_epis_pn_det_task(1) IS NOT NULL)
        THEN
            --when synchronized a record only, when it is performed an action
            l_flg_search := pk_prog_notes_constants.g_synch_dblocks_r;
        ELSE
        
            IF (i_flg_synchronized = pk_alert_constant.g_no)
            THEN
                IF (i_flg_search_dblock = pk_prog_notes_constants.g_auto_pop_dblocks_a AND i_id_epis_pn IS NULL)
                THEN
                    l_flg_search := i_flg_search_dblock;
                ELSE
                    --in note edition there is no auto-population, it is only syncronized records, if configured
                    l_flg_search := pk_prog_notes_constants.g_synch_dblocks_c;
                
                END IF;
            ELSE
                l_flg_search := i_flg_search_dblock;
            END IF;
            --l_flg_search := i_flg_search_dblock;
        
        END IF;
    
        RETURN l_flg_search;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_autopop_type_flg;

    /**
    * Get the list of tasks and data blocks that should be imported
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_id_pn_group        Group Id    
    * @param   o_id_task_types      Task types associated to the given group
    * @param   o_error              Error information
    *
    * @return  Boolean        True: Sucess, False: Fail
    * 
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   01-Jun-2012
    */
    FUNCTION get_task_types_from_group
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_pn_group   IN pn_group.id_pn_group%TYPE,
        o_id_task_types OUT table_number,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'GET_TASK_TYPES_FROM_GROUP';
    BEGIN
        g_error := 'GET TASK TYPES FROM GROUP. i_id_pn_group: ' || i_id_pn_group;
        SELECT pgtt.id_task_type
          BULK COLLECT
          INTO o_id_task_types
          FROM pn_group_task_types pgtt
         WHERE pgtt.id_pn_group = i_id_pn_group;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_task_types_from_group;

    /**
    * Get the id_epis_pn_det_task that corresponds to the given id_task and id_task_type 
    * considering the given data strucutre
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_tbl_tasks          Tasks info structure    
    * @param   i_id_task            Task id to look for
    * @param   i_id_task_type       Task type id to look for
    * @param   i_id_epis_pn_det     Task type id to look for
    *
    * @return  Boolean        True: Sucess, False: Fail
    * 
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   01-Jun-2012
    */
    FUNCTION get_id_epis_pn_det_task
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_tbl_tasks      IN pk_prog_notes_types.t_table_tasks,
        i_id_task        IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type   IN epis_pn_det_task.id_task_type%TYPE,
        i_id_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE
    ) RETURN epis_pn_det_task.id_epis_pn_det_task%TYPE IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'GET_ID_EPIS_PN_DET_TASK';
        l_id_epis_pn_det_task epis_pn_det_task.id_epis_pn_det_task%TYPE := NULL;
        l_error               t_error_out;
        l_id                  epis_pn_det_task.id_epis_pn_det_task%TYPE;
    BEGIN
        l_id := i_tbl_tasks.first;
        LOOP
            EXIT WHEN l_id IS NULL;
        
            IF (i_tbl_tasks(l_id).id_task = i_id_task AND i_tbl_tasks(l_id).id_task_type = i_id_task_type AND i_tbl_tasks(l_id)
               .id_epis_pn_det = i_id_epis_pn_det)
            THEN
                l_id_epis_pn_det_task := l_id;
                EXIT;
            END IF;
        
            l_id := i_tbl_tasks.next(l_id);
        END LOOP;
    
        RETURN l_id_epis_pn_det_task;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_id_epis_pn_det_task;

    /**
    * Get the id_epis_pn_det_task that corresponds to the given id_task and id_task_type 
    * considering the given data strucutre
    *
    * @param   i_lang               Professional preferred language
    * @param   i_prof               Professional identification and its context (institution and software)
    * @param   i_tbl_tasks          Tasks info structure    
    * @param   i_id_task_type       Task type id to look for
    * @param   i_id_epis_pn_det     Task type id to look for
    * @param   i_flg_task_parent    Y-id_epis_pn_det_task. N-id_Task
    * @param   o_id_task            Task id
    * @param   o_id_epis_pn_det_task Epis_pn_det_task
    *
    * @return  Boolean        True: Sucess, False: Fail
    * 
    * @author Sofia Mendes
    * @version 2.6.2
    * @since   01-Jun-2012
    */
    FUNCTION get_ids_from_struct
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_tbl_tasks           IN pk_prog_notes_types.t_table_tasks,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_epis_pn_det      IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_task_parent     IN VARCHAR2,
        i_id_task_parent      IN epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_id_task             OUT epis_pn_det_task.id_task%TYPE,
        o_id_epis_pn_det_task OUT epis_pn_det_task.id_epis_pn_det_task%TYPE,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(25 CHAR) := 'GET_IDS_FROM_STRUCT';
    BEGIN
        g_error := 'GET epis_pn_det_task. i_id_task_parent' || i_id_task_parent || ' i_id_task_type: ' ||
                   i_id_task_type;
        IF (i_flg_task_parent = pk_alert_constant.g_yes AND i_tbl_tasks.exists(i_id_task_parent))
        THEN
            o_id_task             := i_tbl_tasks(i_id_task_parent).id_task;
            o_id_epis_pn_det_task := i_id_task_parent;
        
        ELSE
            IF (i_flg_task_parent = pk_alert_constant.g_no)
            THEN
                g_error               := 'CALL pk_prog_notes_utils.get_id_epis_pn_det_task';
                o_id_epis_pn_det_task := get_id_epis_pn_det_task(i_lang           => i_lang,
                                                                 i_prof           => i_prof,
                                                                 i_tbl_tasks      => i_tbl_tasks,
                                                                 i_id_task        => i_id_task_parent,
                                                                 i_id_task_type   => i_id_task_type,
                                                                 i_id_epis_pn_det => i_id_epis_pn_det);
            
                o_id_task := i_id_task_parent;
            END IF;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_ids_from_struct;

    /**************************************************************************
    * get task set id to be used as the group of tasks to get the descriptions.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    *
    * @value id_task_set            Task set id
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_task_set_to_group_descs
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE
    ) RETURN PLS_INTEGER IS
        l_function_name CONSTANT VARCHAR2(27 CHAR) := 'get_task_set_to_group_descs';
        l_id_task_set PLS_INTEGER;
        l_error       t_error_out;
    BEGIN
        IF (i_id_task_type IN (pk_prog_notes_constants.g_task_medic_here,
                               pk_prog_notes_constants.g_task_reported_medic,
                               pk_prog_notes_constants.g_task_home_med_chinese))
        THEN
            l_id_task_set := pk_prog_notes_constants.g_medication;
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_medrec_cont_home_hm,
                                  pk_prog_notes_constants.g_task_medrec_cont_hospital_hm,
                                  pk_prog_notes_constants.g_task_medrec_discontinue_hm,
                                  pk_prog_notes_constants.g_task_medrec_cont_home_lm,
                                  pk_prog_notes_constants.g_task_medrec_cont_hospital_lm,
                                  pk_prog_notes_constants.g_task_medrec_discontinue_lm,
                                  pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm,
                                  pk_prog_notes_constants.g_task_amb_medication))
        THEN
            l_id_task_set := pk_prog_notes_constants.g_med_rec;
        ELSIF (i_id_task_type IN (pk_prog_notes_constants.g_task_templates,
                                  pk_prog_notes_constants.g_task_ph_templ,
                                  pk_prog_notes_constants.g_task_procedures_exec,
                                  pk_prog_notes_constants.g_task_templates_other_note))
        THEN
            l_id_task_set := pk_prog_notes_constants.g_templates;
        ELSE
            l_id_task_set := i_id_task_type;
        END IF;
    
        RETURN l_id_task_set;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_function_name,
                                              l_error);
            RETURN NULL;
    END get_task_set_to_group_descs;

    /**************************************************************************
    * Aggregate the groups of tasks, to use to calculate the descritions in a group
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task reference ID
    * @param i_id_task_notes          Task associated to the notes field (epis_documentation for procedures
    *                                 executions tasks)
    * @param io_tasks_groups_by_type  Tasks by type structure
    * @param o_grouped_task           Y-Task which description is calculated in group. N-otherwise
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_task_groups_by_type
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_task_type          IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task               IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_notes         IN task_timeline_ea.id_task_notes%TYPE,
        io_tasks_groups_by_type IN OUT NOCOPY pk_prog_notes_types.t_tasks_groups_by_type,
        o_grouped_task          OUT NOCOPY VARCHAR2,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_function_name CONSTANT VARCHAR2(23 CHAR) := 'get_task_groups_by_type';
        l_id_task_set PLS_INTEGER;
    BEGIN
        IF i_id_task_type IN (pk_prog_notes_constants.g_task_medic_here,
                              pk_prog_notes_constants.g_task_reported_medic,
                              pk_prog_notes_constants.g_task_home_med_chinese,
                              pk_prog_notes_constants.g_task_amb_medication,
                              pk_prog_notes_constants.g_task_medrec_cont_home_hm,
                              pk_prog_notes_constants.g_task_medrec_cont_hospital_hm,
                              pk_prog_notes_constants.g_task_medrec_discontinue_hm,
                              pk_prog_notes_constants.g_task_medrec_cont_home_lm,
                              pk_prog_notes_constants.g_task_medrec_cont_hospital_lm,
                              pk_prog_notes_constants.g_task_medrec_discontinue_lm,
                              pk_prog_notes_constants.g_task_templates,
                              pk_prog_notes_constants.g_task_templates_other_note,
                              pk_prog_notes_constants.g_task_ph_templ,
                              pk_prog_notes_constants.g_task_procedures_exec,
                              pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm)
        THEN
        
            g_error       := 'CALL pk_prog_notes_utils.get_task_set_to_group_descs';
            l_id_task_set := pk_prog_notes_utils.get_task_set_to_group_descs(i_lang         => i_lang,
                                                                             i_prof         => i_prof,
                                                                             i_id_task_type => i_id_task_type);
        
            IF (NOT io_tasks_groups_by_type.exists(l_id_task_set))
            THEN
                io_tasks_groups_by_type(l_id_task_set) := table_number();
            END IF;
        
            IF (i_id_task_type = pk_prog_notes_constants.g_task_procedures_exec)
            THEN
                io_tasks_groups_by_type(l_id_task_set).extend;
                io_tasks_groups_by_type(l_id_task_set)(io_tasks_groups_by_type(l_id_task_set).last) := i_id_task_notes;
                o_grouped_task := pk_alert_constant.g_no;
            ELSE
                io_tasks_groups_by_type(l_id_task_set).extend;
                io_tasks_groups_by_type(l_id_task_set)(io_tasks_groups_by_type(l_id_task_set).last) := i_id_task;
                o_grouped_task := pk_alert_constant.g_yes;
            END IF;
        ELSE
            o_grouped_task := pk_alert_constant.g_no;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_function_name,
                                              o_error);
            RETURN FALSE;
    END get_task_groups_by_type;

    /**
    * Returns the concatenated text of all tasks associated to an epis_pn_det.
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
    FUNCTION get_tasks_concat
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_epis_pn_det IN epis_pn_det.id_epis_pn_det%TYPE,
        i_flg_detail     IN VARCHAR2 DEFAULT pk_alert_constant.g_no
    ) RETURN CLOB IS
        l_error t_error_out;
        l_text  CLOB;
    BEGIN
    
        g_error := 'GET tasks concatenated texts. i_id_epis_pn_det: ' || i_id_epis_pn_det;
        SELECT pk_utils.concat_table_clob(CAST(MULTISET
                                               (SELECT CASE
                                                        --templates bilaterais            
                                                            WHEN i_flg_detail = pk_alert_constant.g_no
                                                                 AND
                                                                 epdt.id_task_type IN
                                                                 (pk_prog_notes_constants.g_task_templates,
                                                                  pk_prog_notes_constants.g_task_templates_other_note)
                                                                 AND pk_touch_option_out.has_layout(i_epis_documentation => epdt.id_task) =
                                                                 pk_alert_constant.g_yes THEN
                                                             to_clob('[B|ID_TASK:' || epdt.id_task || ']')
                                                            WHEN i_flg_detail = pk_alert_constant.g_no
                                                                 AND
                                                                 epdt.id_task_type IN
                                                                 (pk_prog_notes_constants.g_task_templates,
                                                                  pk_prog_notes_constants.g_task_templates_other_note)
                                                                 AND pk_touch_option_out.has_layout(i_epis_documentation => epdt.id_task) =
                                                                 pk_alert_constant.g_no THEN
                                                             to_clob(epdt.pn_note) -- || pk_prog_notes_constants.g_enter
                                                            ELSE
                                                             to_clob(decode(epd.id_pn_data_block,
                                                                            pk_prog_notes_constants.g_dblock_vital_sign_tb_143,
                                                                            pk_vital_sign.get_vs_desc(i_lang       => i_lang,
                                                                                                      i_vital_sign => epdt.id_group_table,
                                                                                                      i_short_desc => pk_alert_constant.get_yes) || ': ' ||
                                                                            epdt.pn_note,
                                                                            epdt.pn_note))
                                                        END pn_note
                                                  FROM epis_pn_det_task epdt
                                                  JOIN epis_pn_det epd
                                                    ON epd.id_epis_pn_det = epdt.id_epis_pn_det
                                                 WHERE epdt.id_epis_pn_det = i_id_epis_pn_det
                                                   AND epdt.flg_status =
                                                       pk_prog_notes_constants.g_epis_pn_det_flg_status_a
                                                 ORDER BY epdt.rank_task,
                                                          decode(epdt.id_parent,
                                                                 NULL,
                                                                 epdt.dt_task,
                                                                 (SELECT epdt_par.dt_task
                                                                    FROM epis_pn_det_task epdt_par
                                                                   WHERE epdt_par.id_epis_pn_det_task = epdt.id_parent
                                                                     AND epdt_par.flg_status =
                                                                         pk_prog_notes_constants.g_epis_pn_det_flg_status_a)) DESC,
                                                          decode(epdt.id_parent,
                                                                 NULL,
                                                                 epdt.dt_last_update,
                                                                 (SELECT epdt_par.dt_last_update
                                                                    FROM epis_pn_det_task epdt_par
                                                                   WHERE epdt_par.id_epis_pn_det_task = epdt.id_parent
                                                                     AND epdt_par.flg_status =
                                                                         pk_prog_notes_constants.g_epis_pn_det_flg_status_a)) DESC,
                                                          decode(epdt.id_parent, NULL, NULL, epdt.dt_task) DESC NULLS FIRST,
                                                          decode(epdt.id_parent, NULL, NULL, epdt.dt_last_update) DESC NULLS FIRST) AS
                                               table_clob),
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
                                              g_owner,
                                              g_package,
                                              'get_tasks_concat',
                                              l_error);
        
            RETURN NULL;
    END get_tasks_concat;

    /**************************************************************************
    * Get the data block configs record
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_dblocks                Data blocks configs
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block id
    * @param o_rec_dblock             Data block cfgs record 
    *                                 be aggregated in one free text
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_dblock_cfgs_rec
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_dblock,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        o_rec_dblock       OUT NOCOPY t_rec_dblock,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_DBLOCK_CFGS_REC';
        l_dblocks_count PLS_INTEGER;
    BEGIN
        g_error := 'GET dblock_cfgs_rec. i_id_pn_data_block: ' || i_id_pn_data_block || ' i_id_pn_soap_block: ' ||
                   i_id_pn_soap_block;
    
        l_dblocks_count := i_dblocks.count;
    
        FOR i IN 1 .. l_dblocks_count
        LOOP
            IF (i_dblocks(i)
               .id_pn_data_block = i_id_pn_data_block AND i_dblocks(i).id_pn_soap_block = i_id_pn_soap_block)
            THEN
                o_rec_dblock := i_dblocks(i);
                EXIT;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_dblock_cfgs_rec;

    /**************************************************************************
    * Get the task type configs record
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_coll_dblock_task_type  Task types configs
    * @param i_id_pn_data_block       Data block id
    * @param i_id_pn_soap_block       Soap block id
    * @param i_id_task_type           Task type ID
    * @param o_rec_dblock             Data block cfgs record 
    *                                 be aggregated in one free text
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2                           
    * @since                          15-Oct-2012                               
    **************************************************************************/
    FUNCTION get_task_type_cfgs_rec
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_coll_dblock_task_type IN t_coll_dblock_task_type,
        i_id_pn_data_block      IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_task_type          IN tl_task.id_tl_task%TYPE,
        o_rec_dblock_task_type  OUT NOCOPY t_rec_dblock_task_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_TASK_TYPE_CFGS_REC';
        l_count_task_types PLS_INTEGER;
    BEGIN
        l_count_task_types := i_coll_dblock_task_type.count;
    
        g_error := 'GET task type configs. id_task_type: ' || i_id_task_type;
        FOR k IN 1 .. l_count_task_types
        LOOP
            IF (i_coll_dblock_task_type(k)
               .id_task_type = i_id_task_type AND i_coll_dblock_task_type(k).id_pn_data_block = i_id_pn_data_block AND i_coll_dblock_task_type(k)
               .id_pn_soap_block = i_id_pn_soap_block)
            THEN
                o_rec_dblock_task_type := i_coll_dblock_task_type(k);
                EXIT;
            END IF;
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_task_type_cfgs_rec;

    /**************************************************************************
    * Get the vital signs group description to be used in the second level of text aggregation
    * (Hour)
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_date                   Record date    
    * @param o_desc_group             Hour group desc
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_hour_desc_group
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_HOUR_DESC_GROUP';
        l_error t_error_out;
    BEGIN
        g_error := 'CALL pk_date_utils.to_char_insttimezone';
        RETURN pk_date_utils.to_char_insttimezone(i_prof => i_prof, i_timestamp => i_date, i_mask => 'HH24MI');
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_hour_desc_group;

    /**************************************************************************
    * Get the vital signs group ID to the hour level of aggregation.
    * Transforms the hour in a number to be used as the group id.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_date                   Record date    
    * @param o_error                  Error
    *
    * @return hour group id
    *                                                                       
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_hour_group_id
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_date IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'GET_HOUR_GROUP_ID';
        l_error t_error_out;
    BEGIN
        g_error := 'CALL pk_date_utils.to_char_insttimezone';
        RETURN to_number(pk_date_utils.to_char_insttimezone(i_prof      => i_prof,
                                                            i_timestamp => i_date,
                                                            i_mask      => 'HH24MI'));
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_hour_group_id;

    /**************************************************************************
    * Get the data used to aggregate the data.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task ID
    * @param i_id_task_aggregator     Aggregator Id to be used in case of recurrence records
    * @param i_id_patient             Patient Id
    * @param   o_dt_group_import    Aggregation info: Date: 1st aggregation level
    * @param   o_id_group_import    Aggregation info: Group: 2nd aggregation level
    * @param   o_code_desc_group    Aggregation info: Group desc
    * @param   o_id_sub_group_import Aggregation info: Sub-Group: 3rd aggregation level
    * @param   o_code_desc_sub_group Aggregation info: Sub-Group desc
    * @param   o_id_sample_type      Sample type id. Only used for analysis results to join to the sub group desc
    * @param   o_code_desc_sample_type Sample type code desc. Only used for analysis results to join to the sub group desc
    * @param   o_id_prof_task          Professional that performed the task
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_aggregation_data_from_ea
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_task_type           IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task                IN task_timeline_ea.id_task_refid%TYPE,
        i_id_task_aggregator     IN task_timeline_ea.id_task_aggregator%TYPE,
        i_id_patient             IN patient.id_patient%TYPE,
        i_flg_group_type         IN VARCHAR2 DEFAULT NULL,
        i_dt_task                IN VARCHAR2,
        o_dt_group_import        OUT NOCOPY epis_pn_det_task.dt_group_import%TYPE,
        o_id_group_import        OUT NOCOPY epis_pn_det_task.id_group_import%TYPE,
        o_code_desc_group        OUT NOCOPY epis_pn_det_task.code_desc_group%TYPE,
        o_desc_group             OUT NOCOPY VARCHAR2,
        o_id_sub_group_import    OUT NOCOPY epis_pn_det_task.id_sub_group_import%TYPE,
        o_code_desc_sub_group    OUT NOCOPY epis_pn_det_task.code_desc_sub_group%TYPE,
        o_id_sample_type         OUT NOCOPY epis_pn_det_task.id_sample_type%TYPE,
        o_code_desc_sample_type  OUT NOCOPY epis_pn_det_task.code_desc_sample_type%TYPE,
        o_id_prof_task           OUT NOCOPY epis_pn_det_task.id_prof_task%TYPE,
        o_code_desc_group_parent OUT NOCOPY epis_pn_det_task.code_desc_group_parent%TYPE,
        o_instructions_hash      OUT NOCOPY epis_pn_det_task.instructions_hash%TYPE,
        --   O_ID_PARENT OUT NOCOPY EPIS_PN_DET_TASK.ID_PARENT%TYPE,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(28 CHAR) := 'get_aggregation_data_from_ea';
    
    BEGIN
        IF i_id_task_type IN (pk_prog_notes_constants.g_task_lab_recur,
                              pk_prog_notes_constants.g_task_img_exam_recur,
                              pk_prog_notes_constants.g_task_other_exams_recur)
        THEN
            g_error := 'GET data from ea. i_id_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task ||
                       ' i_id_task_aggregator: ' || i_id_task_aggregator || ' i_dt_task:' || i_dt_task;
            IF i_flg_group_type = 'I'
               AND i_dt_task IS NOT NULL
               AND i_id_task_type = pk_prog_notes_constants.g_task_lab_recur
            THEN
                SELECT tt.dt_import,
                       tt.id_group_import,
                       tt.code_desc_group,
                       tt.id_sub_group_import,
                       tt.code_desc_sub_group,
                       tt.id_sample_type,
                       tt.code_desc_sample_type,
                       tt.id_prof_req,
                       tt.code_desc_group_parent,
                       instructions_hash
                  INTO o_dt_group_import,
                       o_id_group_import,
                       o_code_desc_group,
                       o_id_sub_group_import,
                       o_code_desc_sub_group,
                       o_id_sample_type,
                       o_code_desc_sample_type,
                       o_id_prof_task,
                       o_code_desc_group_parent,
                       o_instructions_hash
                  FROM (SELECT t.dt_import dt_import,
                               t.id_group_import,
                               t.code_desc_group,
                               t.id_sub_group_import,
                               t.code_desc_sub_group,
                               t.id_sample_type,
                               t.code_desc_sample_type,
                               t.id_prof_req,
                               t.code_desc_group_parent,
                               t.instructions_hash,
                               t.id_task
                          FROM v_pn_tasks t
                         WHERE t.id_ref_group = i_id_task
                           AND t.id_task_aggregator = i_id_task_aggregator
                           AND t.id_patient = i_id_patient
                              /*  AND t.dt_import = CAST((SELECT pk_date_utils.get_string_tstz(i_lang      => i_lang,
                                                                 i_prof      => i_prof,
                                                                 i_timestamp => i_dt_task,
                                                                 i_timezone  => NULL)
                              FROM dual) AS TIMESTAMP WITH LOCAL TIME ZONE)    */
                           AND pk_date_utils.date_send_tsz(i_lang, t.dt_import, i_prof) = i_dt_task
                           AND t.id_tl_task = decode(i_id_task_type,
                                                     pk_prog_notes_constants.g_task_lab_recur,
                                                     pk_prog_notes_constants.g_task_lab,
                                                     i_id_task_type)) tt
                 WHERE rownum = 1;
            ELSE
                SELECT tt.dt_import,
                       tt.id_group_import,
                       tt.code_desc_group,
                       tt.id_sub_group_import,
                       tt.code_desc_sub_group,
                       tt.id_sample_type,
                       tt.code_desc_sample_type,
                       tt.id_prof_req,
                       tt.code_desc_group_parent,
                       instructions_hash
                  INTO o_dt_group_import,
                       o_id_group_import,
                       o_code_desc_group,
                       o_id_sub_group_import,
                       o_code_desc_sub_group,
                       o_id_sample_type,
                       o_code_desc_sample_type,
                       o_id_prof_task,
                       o_code_desc_group_parent,
                       o_instructions_hash
                  FROM (SELECT MIN(t.dt_import) dt_import,
                               t.id_group_import,
                               t.code_desc_group,
                               t.id_sub_group_import,
                               t.code_desc_sub_group,
                               t.id_sample_type,
                               t.code_desc_sample_type,
                               t.id_prof_req,
                               t.code_desc_group_parent,
                               t.instructions_hash
                          FROM v_pn_tasks t
                         WHERE t.id_ref_group = i_id_task
                           AND t.id_task_aggregator = i_id_task_aggregator
                           AND t.id_patient = i_id_patient
                              
                           AND t.id_tl_task = decode(i_id_task_type,
                                                     pk_prog_notes_constants.g_task_lab_recur,
                                                     pk_prog_notes_constants.g_task_lab,
                                                     
                                                     pk_prog_notes_constants.g_task_img_exam_recur,
                                                     pk_prog_notes_constants.g_task_img_exams_req,
                                                     
                                                     pk_prog_notes_constants.g_task_other_exams_recur,
                                                     pk_prog_notes_constants.g_task_other_exams_req,
                                                     
                                                     i_id_task_type)
                         GROUP BY t.id_prof_req,
                                  t.id_ref_group,
                                  t.id_tl_task,
                                  t.code_description,
                                  -- t.id_episode,
                                  t.id_group_import,
                                  t.code_desc_group,
                                  t.dt_execution,
                                  t.id_sub_group_import,
                                  t.code_desc_sub_group,
                                  t.flg_sos,
                                  decode(t.id_task_aggregator, NULL, t.dt_begin),
                                  t.id_task_aggregator,
                                  t.id_doc_area,
                                  t.id_parent_comments,
                                  t.id_sample_type,
                                  t.code_desc_sample_type,
                                  code_desc_group_parent,
                                  instructions_hash) tt
                 WHERE rownum = 1;
            
            END IF;
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_vital_signs,
                                 pk_prog_notes_constants.g_task_biometrics,
                                 pk_prog_notes_constants.g_task_vital_signs_view_date)
        THEN
            --TODO: IN pckg   
            g_error := 'pk_vital_sign.get_id_vital_sign. i_id_vital_sign_read: ' || i_id_task;
            IF NOT pk_vital_sign.get_vital_sign_date(i_lang                    => i_lang,
                                                     i_prof                    => i_prof,
                                                     i_id_vital_sign_read      => i_id_task,
                                                     o_dt_vital_sign_read_tstz => o_dt_group_import,
                                                     o_error                   => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            g_error           := 'CALL get_hour_group_id';
            o_id_group_import := get_hour_group_id(i_lang => i_lang, i_prof => i_prof, i_date => o_dt_group_import);
        ELSE
        
            g_error := 'GET data from ea. i_id_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task;
            BEGIN
                SELECT t.dt_import,
                       t.id_group_import,
                       t.code_desc_group,
                       t.id_sub_group_import,
                       t.code_desc_sub_group,
                       t.id_sample_type,
                       t.code_desc_sample_type,
                       t.id_prof_req,
                       t.code_desc_group_parent,
                       t.instructions_hash
                  INTO o_dt_group_import,
                       o_id_group_import,
                       o_code_desc_group,
                       o_id_sub_group_import,
                       o_code_desc_sub_group,
                       o_id_sample_type,
                       o_code_desc_sample_type,
                       o_id_prof_task,
                       o_code_desc_group_parent,
                       o_instructions_hash
                  FROM v_pn_tasks t
                 WHERE t.id_task = i_id_task
                   AND t.id_tl_task = i_id_task_type;
            EXCEPTION
                WHEN no_data_found THEN
                    o_dt_group_import        := NULL;
                    o_id_group_import        := NULL;
                    o_code_desc_group        := NULL;
                    o_id_sub_group_import    := NULL;
                    o_code_desc_sub_group    := NULL;
                    o_id_sample_type         := NULL;
                    o_code_desc_sample_type  := NULL;
                    o_code_desc_group_parent := NULL;
                    o_instructions_hash      := NULL;
            END;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_aggregation_data_from_ea;

    /**************************************************************************
    * Get the description of the 2nd level of aggregation
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_dt_group_import    Aggregation info: Date: 1st aggregation level
    * @param i_code_desc_group    Aggregation info: Group desc
    *
    * @return         Aggregation info: 2nd level desc
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_group_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_id_task_type           IN task_timeline_ea.id_tl_task%TYPE,
        i_dt_group_import        IN epis_pn_det_task.dt_group_import%TYPE,
        i_code_desc_group        IN epis_pn_det_task.code_desc_group%TYPE,
        i_code_desc_group_parent IN epis_pn_det_task.code_desc_group_parent%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(14 CHAR) := 'GET_GROUP_DESC';
        l_desc_group pk_translation.t_desc_translation;
    BEGIN
        IF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab,
                               pk_prog_notes_constants.g_task_lab_results,
                               pk_prog_notes_constants.g_task_lab_recur,
                               pk_prog_notes_constants.g_task_img_exams_req,
                               pk_prog_notes_constants.g_task_other_exams_req,
                               pk_prog_notes_constants.g_task_exam_results,
                               pk_prog_notes_constants.g_task_img_exam_recur))
        THEN
            l_desc_group := CASE
                                WHEN i_code_desc_group IS NOT NULL THEN
                                 CASE
                                     WHEN i_code_desc_group_parent IS NOT NULL THEN
                                      pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_desc_group_parent) || ', ' ||
                                      pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_desc_group)
                                     ELSE
                                      pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_desc_group)
                                 END
                                ELSE
                                 NULL
                            END;
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_vital_signs,
                                 pk_prog_notes_constants.g_task_biometrics,
                                 pk_prog_notes_constants.g_task_vital_signs_view_date)
        THEN
            --todo: este formato de data n?tem o 'h'
            g_error      := 'GET HOUR DESC';
            l_desc_group := pk_string_utils.surround(i_string  => pk_date_utils.get_hour_short(i_lang      => i_lang,
                                                                                               i_prof      => i_prof,
                                                                                               i_timestamp => i_dt_group_import),
                                                     i_pattern => pk_string_utils.g_pattern_parenthesis);
        
        END IF;
    
        RETURN l_desc_group;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR calculating group desc';
            RETURN NULL;
    END get_group_desc;

    /**************************************************************************
    * Get the description of the 3rd level of aggregation
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_code_desc_sub_group    Aggregation info: Sub Group desc code translation
    * @param i_code_desc_sample_type  Sample type code desc. Only used for analysis results to join to the sub group desc
    *
    * @return         Aggregation info: 2nd level desc
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_sub_group_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_code_desc_sub_group   IN epis_pn_det_task.code_desc_sub_group%TYPE,
        i_code_desc_sample_type IN epis_pn_det_task.code_desc_sample_type%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(18 CHAR) := 'GET_SUB_GROUP_DESC';
        l_desc_sub_group pk_translation.t_desc_translation;
    BEGIN
        IF (i_code_desc_sub_group IS NOT NULL)
        THEN
            l_desc_sub_group := pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_desc_sub_group) || CASE
                                    WHEN i_code_desc_sample_type IS NOT NULL THEN
                                     pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_hifen ||
                                     pk_prog_notes_constants.g_space ||
                                     pk_translation.get_translation(i_lang => i_lang, i_code_mess => i_code_desc_sample_type)
                                    ELSE
                                     ''
                                END;
        END IF;
    
        RETURN l_desc_sub_group;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR calculating sub group desc';
            RETURN NULL;
    END get_sub_group_desc;

    /**************************************************************************
    * Get the title to the 1st level of aggregation by date.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_dt_group_import        Aggregation info: Date: 1st aggregation level
    * @param o_date_title             Aggregation info: Date desc desc
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_date_aggr_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task_type    IN task_timeline_ea.id_tl_task%TYPE,
        i_dt_group_import IN epis_pn_det_task.dt_group_import%TYPE,
        o_date_title      OUT NOCOPY VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(19 CHAR) := 'get_date_aggr_desc';
        l_code_sm_group_title sys_message.code_message%TYPE;
        l_date_aggr           VARCHAR2(200 CHAR);
    BEGIN
        IF i_id_task_type = pk_prog_notes_constants.g_task_exam_results
        THEN
            l_code_sm_group_title := pk_prog_notes_constants.g_sm_exec_dt;
        ELSIF i_id_task_type = pk_prog_notes_constants.g_task_lab_results
        THEN
            l_code_sm_group_title := pk_prog_notes_constants.g_sm_collect_dt;
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_lab,
                                 pk_prog_notes_constants.g_task_lab_recur,
                                 pk_prog_notes_constants.g_task_img_exams_req,
                                 pk_prog_notes_constants.g_task_other_exams_req,
                                 pk_prog_notes_constants.g_task_img_exam_recur,
                                 pk_prog_notes_constants.g_task_other_exams_recur)
        THEN
            l_code_sm_group_title := pk_prog_notes_constants.g_sm_requested_dt;
        END IF;
        IF i_id_task_type = pk_prog_notes_constants.g_task_lab_results
        THEN
            l_date_aggr := pk_date_utils.dt_chr_date_hour_tsz(i_lang => i_lang,
                                                              i_date => i_dt_group_import,
                                                              i_inst => i_prof.institution,
                                                              i_soft => i_prof.software);
        
        ELSE
            l_date_aggr := pk_date_utils.dt_chr_tsz(i_lang => i_lang,
                                                    i_date => i_dt_group_import,
                                                    i_inst => i_prof.institution,
                                                    i_soft => i_prof.software);
        
        END IF;
        o_date_title := CASE
                            WHEN l_code_sm_group_title IS NOT NULL
                                 AND i_dt_group_import IS NOT NULL THEN
                             REPLACE(pk_message.get_message(i_lang => i_lang, i_code_mess => l_code_sm_group_title),
                                     pk_prog_notes_constants.g_replace_1,
                                     l_date_aggr)
                            WHEN i_dt_group_import IS NOT NULL THEN
                             l_date_aggr
                            ELSE
                             NULL
                        END;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_date_aggr_desc;

    /**************************************************************************
    * Separator to separate the different record values in the text aggregations.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_id_sub_group_import    Sub group id: indicates if the 3rd aggregation level exists
    * @param o_separator              Aggregation info: separator
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_txt_aggr_separator
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_task_type        IN task_timeline_ea.id_tl_task%TYPE,
        i_prev_task           IN epis_pn_det_task.pn_note%TYPE,
        i_id_sub_group_import IN epis_pn_det_task.id_sub_group_import%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_TXT_AGGR_SEPARATOR';
        l_separator VARCHAR2(20 CHAR);
    BEGIN
        IF (i_id_task_type IN (pk_prog_notes_constants.g_task_lab,
                               pk_prog_notes_constants.g_task_lab_results,
                               pk_prog_notes_constants.g_task_lab_recur,
                               pk_prog_notes_constants.g_task_img_exams_req,
                               pk_prog_notes_constants.g_task_other_exams_req,
                               pk_prog_notes_constants.g_task_exam_results,
                               pk_prog_notes_constants.g_task_img_exam_recur))
        THEN
            IF (i_prev_task IS NOT NULL OR i_id_sub_group_import IS NULL)
            THEN
                l_separator := pk_prog_notes_constants.g_new_line;
            END IF;
        
            IF (i_id_sub_group_import IS NULL)
            THEN
                l_separator := l_separator || pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space;
            ELSE
                l_separator := l_separator || pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space ||
                               pk_prog_notes_constants.g_space || pk_prog_notes_constants.g_space;
            END IF;
        
        ELSIF i_id_task_type IN (pk_prog_notes_constants.g_task_vital_signs,
                                 pk_prog_notes_constants.g_task_biometrics,
                                 pk_prog_notes_constants.g_task_vital_signs_view_date)
        THEN
            IF (i_prev_task IS NOT NULL)
            THEN
                l_separator := pk_prog_notes_constants.g_semicolon;
            END IF;
        END IF;
    
        RETURN l_separator;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR getting the separator';
        
            RETURN NULL;
    END get_txt_aggr_separator;

    /**************************************************************************
    * Get the title to the 1st level of aggregation by date.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param o_flg_ea                 Y- Task date comes from EA; N- Task data comes from API
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          19-Sep-2012                            
    **************************************************************************/
    FUNCTION get_task_flg_ea
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN task_timeline_ea.id_tl_task%TYPE,
        o_flg_ea       OUT NOCOPY tl_task.flg_ea%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(15 CHAR) := 'GET_TASK_FLG_EA';
    BEGIN
        g_error := 'GET flg_ea. i_id_task_type: ' || i_id_task_type;
        SELECT tt.flg_ea
          INTO o_flg_ea
          FROM tl_task tt
         WHERE tt.id_tl_task = i_id_task_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            o_flg_ea := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_task_flg_ea;

    /********************************************************************************************
    * Get the last note to the given area acoording to the given statuses.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_scope                   Scope ID (Patient ID, Visit ID)
    * @param       i_scope_type              Scope type (by patient {P}, by visit {V})    
    * @param       i_id_pn_area              PN area ID
    * @param       i_note_status             Notes statuses   
    * @param       o_id_epis_pn              Note ID
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Sofia Mendes
    * @since                                 23-Abr-2012
    ********************************************************************************************/
    FUNCTION get_last_note_by_area
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_scope       IN NUMBER,
        i_scope_type  IN VARCHAR2,
        i_id_pn_area  IN pn_area.id_pn_area%TYPE,
        i_note_status IN table_varchar,
        o_id_epis_pn  OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'GET_LAST_NOTE_BY_AREA';
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        g_error := 'CALL pk_touch_option.get_scope_vars. i_scope: ' || i_scope || ' i_scope_type: ' || i_scope_type;
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'GET last note date. i_id_pn_area: ' || i_id_pn_area || ' l_id_patient: ' || l_id_patient ||
                   ' l_id_visit: ' || l_id_visit || ' l_id_episode: ' || l_id_episode;
        SELECT t.id_epis_pn
          INTO o_id_epis_pn
          FROM (SELECT e.id_epis_pn,
                       e.id_pn_area,
                       row_number() over(PARTITION BY e.id_episode, e.id_pn_area ORDER BY e.dt_pn_date DESC) rn
                  FROM epis_pn e
                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE ts ROWS=1)*/
                        column_value flg_status
                         FROM TABLE(i_note_status) ts) tst
                    ON tst.flg_status = e.flg_status
                  JOIN episode epi
                    ON epi.id_episode = e.id_episode
                 WHERE e.id_pn_area = i_id_pn_area
                   AND epi.id_patient = l_id_patient
                   AND (epi.id_visit = l_id_visit OR l_id_visit IS NULL)
                   AND (epi.id_episode = l_id_episode OR l_id_episode IS NULL)) t
         WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_epis_pn := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            o_id_epis_pn := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_last_note_by_area;

    /**************************************************************************
    * Calculated if the record was modified in the current data syncronization.
    * In the SPSummary it is always saved permanently in the synch, so it is not
    * needed to mark as modified
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_pn_note                Task text
    * @param i_dt_pn                  Det date
    * @param i_dt_last_update_task    Task last update date in the note
    * @param i_dt_last_update         Last update of the note (update in the current synch)
    * @param i_flg_syncronized        Y-SPSummary; N-SPNote
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2                           
    * @since                          27-Sep-2012                             
    **************************************************************************/
    FUNCTION get_flg_modified
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_pn_note             IN epis_pn_det_task.pn_note%TYPE,
        i_dt_pn               IN epis_pn_det.dt_pn%TYPE,
        i_dt_last_update_task IN epis_pn_det_task.dt_last_update%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_flg_syncronized     IN pn_note_type_mkt.flg_synchronized%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(16 CHAR) := 'GET_FLG_MODIFIED';
        l_flg_modified VARCHAR2(1 CHAR);
    BEGIN
        IF (i_flg_syncronized = pk_alert_constant.g_no)
        THEN
            IF (i_pn_note IS NULL)
            THEN
                IF (i_dt_pn = i_dt_last_update)
                THEN
                    l_flg_modified := pk_alert_constant.g_yes;
                ELSE
                    l_flg_modified := pk_alert_constant.g_no;
                END IF;
            
            ELSE
                IF i_dt_last_update_task = i_dt_last_update
                THEN
                    l_flg_modified := pk_alert_constant.g_yes;
                ELSE
                    l_flg_modified := pk_alert_constant.g_no;
                END IF;
            END IF;
        
        ELSE
            l_flg_modified := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_flg_modified;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'ERROR getting the l_flg_modified';
        
            RETURN NULL;
    END get_flg_modified;

    /********************************************************************************************
    * Gets the dynamic note type configs. FLG_import_available and flg_editable
    *
    * @param I_LANG                  Language ID for translations
    * @param I_PROF                  Professional vector of information (professional ID, institution ID, software ID)
    * @param i_id_episode            Episode ID    
    * @param i_id_epis_pn            Note id   
    * @param i_id_pn_note_type       Note type ID    
    * @param i_flg_import_available  Configuration regarding import availability
    * @param i_editable_nr_min       Nr of min to edit the note (if aplicable)
    * @param i_flg_edit_after_disch  Y-Editable after discharge. N-Otherwise
    * @param i_flg_synchronized      Y- SPSummary; N-SPNote
    * @param i_flg_edit_only_last    Y-only the last active note is editable. N-otherwise
    * @param o_flg_editable          Y-It is allowed to edit the note. N-It is not allowed to edit.
    *                                T-It is not allowed to edit except the free text records.
    * @param O_ERROR                 If an error accurs, this parameter will have information about the error
    *
    * @return                        false if errors occur, true otherwise
    *
    * @author                        Sofia Mendes
    * @since                         02-Oct-2012
    * @version                       2.6.2
    ********************************************************************************************/
    FUNCTION get_dynamic_note_type_cfgs
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_epis_pn           IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_import_available IN pn_note_type_mkt.flg_import_available%TYPE,
        i_editable_nr_min      IN pn_note_type_mkt.editable_nr_min%TYPE,
        i_flg_edit_after_disch IN pn_note_type_mkt.flg_edit_after_disch%TYPE,
        i_flg_synchronized     IN pn_note_type_mkt.flg_synchronized%TYPE,
        i_flg_edit_only_last   IN pn_note_type_mkt.flg_edit_only_last%TYPE,
        o_flg_editable         OUT NOCOPY VARCHAR2,
        o_configs              OUT NOCOPY pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_flg_import_active pn_note_type_mkt.flg_import_available%TYPE;
        l_func_name CONSTANT VARCHAR(26 CHAR) := 'GET_DYNAMIC_NOTE_TYPE_CFGS';
        l_number_records NUMBER;
    BEGIN
        g_error        := 'CALL pk_prog_notes_utils.get_flg_editable. i_id_pn_note_type: ' || i_id_pn_note_type;
        o_flg_editable := pk_prog_notes_utils.get_flg_editable(i_lang                 => i_lang,
                                                               i_prof                 => i_prof,
                                                               i_id_episode           => i_id_episode,
                                                               i_id_epis_pn           => i_id_epis_pn,
                                                               i_editable_nr_min      => i_editable_nr_min,
                                                               i_flg_edit_after_disch => i_flg_edit_after_disch,
                                                               i_flg_synchronized     => i_flg_synchronized,
                                                               i_id_pn_note_type      => i_id_pn_note_type,
                                                               i_flg_edit_only_last   => i_flg_edit_only_last);
    
        g_error          := 'CALL GET_NUMBER_IMPORTED_BLOCKS';
        l_number_records := get_number_imported_blocks(i_id_epis_pn => i_id_epis_pn);
    
        g_error             := 'CALL FLG_IMPORT_AVAILABLE';
        l_flg_import_active := CASE
                                   WHEN o_flg_editable IN
                                        (pk_alert_constant.g_no, pk_prog_notes_constants.g_not_editable_by_time) THEN
                                    pk_alert_constant.g_no
                                   WHEN i_flg_import_available = pk_prog_notes_constants.g_import_exclusive
                                        AND l_number_records > 0 THEN
                                    pk_alert_constant.g_no
                                   ELSE
                                    i_flg_import_available
                               END;
    
        g_error := 'Open o_configs cursor';
        OPEN o_configs FOR
            SELECT l_flg_import_active flg_import_active, o_flg_editable flg_editable
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_types.open_my_cursor(o_configs);
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_dynamic_note_type_cfgs',
                                              o_error);
            RETURN FALSE;
    END get_dynamic_note_type_cfgs;

    /**************************************************************************
    * Gets the tasks descriptions by group of tasks.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_tasks_descs_by_type    Task descriptions struct
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task id
    * @param i_id_task_notes          Task associated to the template notes.
    * @param i_flg_show_sub_title     Y-the sub title should be visible. N-otherwise
    * @param o_error                  Error
    *
    * @value i_flg_has_notes          {*} 'Y'- Has comments {*} 'N'- otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_import_group_desc
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_tasks_descs_by_type IN pk_prog_notes_types.t_tasks_descs_by_type,
        i_id_task_type        IN epis_pn_det_task.id_task_type%TYPE,
        i_id_task             IN epis_pn_det_task.id_task%TYPE,
        i_id_task_notes       IN task_timeline_ea.id_task_notes%TYPE,
        i_flg_show_sub_title  IN pn_dblock_mkt.flg_show_sub_title%TYPE,
        io_desc               IN OUT NOCOPY CLOB,
        io_desc_long          IN OUT NOCOPY CLOB,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(21 CHAR) := 'GET_IMPORT_GROUP_DESC';
    
        l_id_task_set PLS_INTEGER;
        l_id_task     epis_pn_det_task.id_task%TYPE;
    BEGIN
        IF (i_id_task_type IN (pk_prog_notes_constants.g_task_medic_here,
                               pk_prog_notes_constants.g_task_reported_medic,
                               pk_prog_notes_constants.g_task_home_med_chinese,
                               pk_prog_notes_constants.g_task_templates,
                               pk_prog_notes_constants.g_task_templates_other_note,
                               pk_prog_notes_constants.g_task_ph_templ,
                               pk_prog_notes_constants.g_task_amb_medication,
                               pk_prog_notes_constants.g_task_medrec_cont_home_hm,
                               pk_prog_notes_constants.g_task_medrec_cont_hospital_hm,
                               pk_prog_notes_constants.g_task_medrec_discontinue_hm,
                               pk_prog_notes_constants.g_task_medrec_cont_home_lm,
                               pk_prog_notes_constants.g_task_medrec_cont_hospital_lm,
                               pk_prog_notes_constants.g_task_medrec_discontinue_lm,
                               pk_prog_notes_constants.g_task_procedures_exec,
                               pk_prog_notes_constants.g_task_medrec_mod_cont_home_hm))
        THEN
            g_error       := 'CALL pk_prog_notes_utils.get_task_set_to_group_descs';
            l_id_task_set := pk_prog_notes_utils.get_task_set_to_group_descs(i_lang         => i_lang,
                                                                             i_prof         => i_prof,
                                                                             i_id_task_type => i_id_task_type);
        
            IF (i_tasks_descs_by_type.exists(l_id_task_set))
            THEN
                IF (i_tasks_descs_by_type(l_id_task_set).exists(i_id_task))
                THEN
                    l_id_task := i_id_task;
                ELSIF (i_tasks_descs_by_type(l_id_task_set).exists(i_id_task_notes))
                THEN
                    l_id_task := i_id_task_notes;
                ELSE
                    l_id_task := NULL;
                END IF;
            
                IF (l_id_task IS NOT NULL)
                THEN
                    IF (i_flg_show_sub_title = pk_alert_constant.g_yes)
                    THEN
                        g_error := 'CALC description with title';
                        io_desc := io_desc || i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc;
                    
                        io_desc_long := io_desc_long || i_tasks_descs_by_type(l_id_task_set)(l_id_task)
                                       .task_title || pk_prog_notes_constants.g_new_line ||
                                        nvl(i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc_long,
                                            i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc);
                    ELSE
                        g_error      := 'CALC description';
                        io_desc      := io_desc || i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc;
                        io_desc_long := io_desc_long ||
                                        nvl(i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc_long,
                                            i_tasks_descs_by_type(l_id_task_set)(l_id_task).task_desc);
                    END IF;
                END IF;
            END IF;
        ELSE
            io_desc      := NULL;
            io_desc_long := NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_import_group_desc;

    /**************************************************************************
    * Check if the task should stay selected in the import screen when the user selects all
    * the group of tasks, according to the configuration by status.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_flg_task_stauts         Task status
    * @param i_flg_group_select_filter Config that status should appear selected in group selection
    *
    * @return varchar2                 {*} 'Y'- Task selected {*} 'N'- Task unselected
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2                            
    * @since                          04-Oct-2012                             
    **************************************************************************/
    FUNCTION get_flg_select_by_status
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_flg_task_stauts         IN task_timeline_ea.flg_ongoing%TYPE,
        i_flg_group_select_filter IN pn_dblock_mkt.flg_group_select_filter%TYPE
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(24 CHAR) := 'GET_FLG_SELECT_BY_STATUS';
    BEGIN
        IF i_flg_group_select_filter = pk_alert_constant.g_no
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            IF (instr(i_flg_group_select_filter, i_flg_task_stauts) > 0)
            THEN
                RETURN pk_alert_constant.g_yes;
            ELSE
                RETURN pk_alert_constant.g_no;
            END IF;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_flg_select_by_status exception error: ' || SQLERRM;
            RETURN pk_alert_constant.g_no;
    END get_flg_select_by_status;

    /**
    * checks if the record should be auto-suggested to the user or it should be saved in the note.
    *
    * @param i_current_episode             Current episode ID
    * @param i_imported_episode            Episode in which was created the imported task
    * @param i_flg_review                  Y - the review is available on page/note. N-otherwise
    * @param i_flg_review_avail            Y - the review is available for the current task type. N-otherwise
    * @param i_flg_auto_populated          Y-The data block is filled automatically with the existing info. N-otherwise
    * @param i_flg_reviewed_epis           Y -The task had already been reviewed in the current episode
    * @param i_review_context              Context of revision. If it is filled the task requires revision.
    * @param i_id_task_type                Task type Id
    * @param i_flg_new                     Y-new record; N-record already in the page/note
    * @param i_flg_import                  T-import in text; B-import in block
    * @param i_flg_synch_db                Y-Synchronizable area. N-othwerwise
    * @param i_flg_suggest_concept         Concept to determine the suggested records.
    * @param i_flg_editable                Y-Editable record; N-otherwise
    * @param i_flg_status                  Record flg status
    *
    * @return                 Y-The record must be auto-suggested to the user. N-otherwise     
    *
    * @author               Sofia Mendes
    * @version              2.6.2
    * @since                28-02-2012
    */
    FUNCTION get_auto_suggested_flg
    (
        i_current_episode     IN episode.id_episode%TYPE,
        i_imported_episode    IN episode.id_episode%TYPE,
        i_flg_review          IN pn_note_type_mkt.flg_review_all%TYPE,
        i_flg_review_avail    IN pn_dblock_ttp_mkt.flg_review_avail%TYPE,
        i_flg_auto_populated  IN pn_dblock_ttp_mkt.flg_auto_populated%TYPE,
        i_flg_reviewed_epis   IN VARCHAR2,
        i_review_context      IN tl_task.review_context%TYPE,
        i_id_task_type        IN tl_task.id_tl_task%TYPE,
        i_flg_new             IN VARCHAR2,
        i_flg_import          IN pn_dblock_mkt.flg_import%TYPE,
        i_flg_synch_db        IN pn_dblock_ttp_mkt.flg_synchronized%TYPE,
        i_flg_suggest_concept IN pn_note_type_mkt.flg_suggest_concept%TYPE,
        i_flg_editable        IN pn_dblock_mkt.flg_editable%TYPE,
        i_flg_status          IN epis_pn_det_task.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_res VARCHAR2(1 CHAR);
    BEGIN
        g_error := 'CHECKS IF RECORD SHOULD BE SUGGESTED. i_flg_auto_populated: ' || i_flg_auto_populated ||
                   ' i_flg_reviewed_epis: ' || i_flg_reviewed_epis || ' i_review_context: ' || i_review_context ||
                   ' i_current_episode: ' || i_current_episode || ' i_imported_episode : ' || i_imported_episode;
    
        --in the single page summary is considered the review concept to the suggested records
        --IF (i_flg_synchronized = pk_alert_constant.g_yes)
        IF (i_flg_suggest_concept = pk_prog_notes_constants.g_suggest_review_r)
        THEN
        
            IF (i_flg_review = pk_alert_constant.g_yes AND i_flg_review_avail = pk_alert_constant.g_yes)
            THEN
                --when checking only if it is necessary to review the task in the current epis in order to save it in the note
                -- the i_flg_auto_populated should be sent as null
                --IF (i_flg_auto_populated <> pk_alert_constant.g_no OR i_flg_auto_populated IS NULL)
                IF (pk_utils.str_token_find(i_string => i_flg_auto_populated,
                                            i_token  => pk_alert_constant.g_no,
                                            i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_no OR
                   i_flg_auto_populated IS NULL)
                THEN
                    --if the task had already been reviewed in the current episode, it will be saved in the note -> no need for further review
                    IF (i_flg_reviewed_epis = pk_alert_constant.g_yes)
                    THEN
                        l_res := pk_alert_constant.g_no;
                    
                        --not reviewed task: this task type needs review. So, auto-suggests the task
                    ELSIF (i_review_context IS NOT NULL OR
                          i_id_task_type = pk_prog_notes_constants.g_task_reported_medic)
                    THEN
                        l_res := pk_alert_constant.g_yes;
                    
                        --not reviewed task: the task does not need review, save it in the note
                    ELSE
                        l_res := pk_alert_constant.g_no;
                    END IF;
                ELSE
                    l_res := pk_alert_constant.g_no;
                END IF;
            ELSE
                l_res := pk_alert_constant.g_no;
            END IF;
        
            --in the single note is considered as suggested the auto-populated-records that are not texts
        ELSIF (i_flg_suggest_concept = pk_prog_notes_constants.g_suggest_p)
        THEN
            /*IF (i_flg_new = pk_alert_constant.g_yes AND i_flg_auto_populated <> pk_alert_constant.g_no AND
            i_flg_import = pk_prog_notes_constants.g_import_block AND i_flg_synch_db = pk_alert_constant.g_no)*/
            IF (i_flg_new = pk_alert_constant.g_yes AND
               pk_utils.str_token_find(i_string => i_flg_auto_populated,
                                        i_token  => pk_alert_constant.g_no,
                                        i_sep    => pk_prog_notes_constants.g_sep) = 'N' AND
               i_flg_import = pk_prog_notes_constants.g_import_block AND i_flg_synch_db = pk_alert_constant.g_no)
            THEN
                l_res := pk_alert_constant.g_yes;
            ELSE
                l_res := pk_alert_constant.g_no;
            END IF;
            -- Editable records
        ELSIF (i_flg_suggest_concept = pk_prog_notes_constants.g_suggest_edit_e)
        THEN
            IF (i_flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_s)
            THEN
                l_res := pk_alert_constant.g_yes;
            ELSE
                IF (i_flg_editable = pk_prog_notes_constants.g_editable_to_review_k AND
                   i_flg_new = pk_alert_constant.g_yes)
                THEN
                    l_res := pk_alert_constant.g_yes;
                ELSE
                    l_res := pk_alert_constant.g_no;
                END IF;
            END IF;
        END IF;
    
        RETURN l_res;
    
    END get_auto_suggested_flg;

    /**************************************************************************
    * Indicates if should be shown the signature in the current record.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_flg_suggested          Y-suggested record. N-definitive record
    * @param i_id_prof_reg            Professional id that registered the record
    * @param i_flg_import_date        Y-should be shown the signature config. N-otherwise
    * @param i_dblock_data_area       Data block area
    * @param i_flg_import             B-block importable. T -text importable
    * @param i_flg_signature          Y-show signature if applicable. N-No show signature
    *
    * @return varchar2                 {*} 'Y'- Record with signature {*} 'N'- Otherwise
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2                            
    * @since                          23-Oct-2012                             
    **************************************************************************/
    FUNCTION get_flg_show_signature
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_flg_suggested    IN VARCHAR2,
        i_id_prof_reg      IN professional.id_professional%TYPE,
        i_flg_import_date  IN pn_dblock_mkt.flg_import_date%TYPE,
        i_dblock_data_area IN pn_data_block.data_area%TYPE,
        i_flg_import       IN pn_dblock_mkt.flg_import%TYPE,
        i_flg_signature    IN pn_dblock_mkt.flg_signature%TYPE DEFAULT 'Y'
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'GET_FLG_SHOW_SIGNATURE';
        l_res VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        g_error := 'get_flg_show_signature. i_flg_suggested: ' || i_flg_suggested || ' i_id_prof_reg: ' ||
                   i_id_prof_reg || ' i_flg_import_date: ' || i_flg_import_date || ' i_flg_signature: ' ||
                   i_flg_signature;
        IF i_flg_signature = pk_alert_constant.g_no
        THEN
            l_res := pk_alert_constant.g_no;
        ELSE
            IF (i_flg_import = pk_prog_notes_constants.g_import_text)
            THEN
                l_res := pk_alert_constant.g_no;
            ELSIF (i_flg_suggested = pk_alert_constant.g_yes)
            THEN
                l_res := pk_alert_constant.g_yes;
            ELSIF (i_prof.id <> i_id_prof_reg AND
                  i_dblock_data_area NOT IN
                  (pk_prog_notes_constants.g_data_block_cdate_cd,
                    pk_prog_notes_constants.g_data_block_eddate_edd,
                    pk_prog_notes_constants.g_data_block_arrivaldt_adt,
                    pk_prog_notes_constants.g_data_block_cdate_ddt))
            THEN
                l_res := pk_alert_constant.g_yes;
            ELSIF (i_flg_import_date = pk_alert_constant.g_yes)
            THEN
                l_res := pk_alert_constant.g_yes;
            ELSE
                l_res := pk_alert_constant.g_yes;
            END IF;
        END IF;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_flg_show_signature exception error: ' || SQLERRM;
            RETURN NULL;
    END get_flg_show_signature;

    /********************************************************************************************
    *  Append the elements of one t_table_tasks table to another.
    *
    * @param i_lang                     Language identifier
    * @param i_prof                     Professional
    * @param i_table_to_append          Table to be appended        
    * @param io_total_table             Table with all the appended values    
    * @param o_error                    Error
    *
    * @return                          true (sucess), false (error)
    *
    * @author                          Sofia Mendes
    * @version                         2.6.2.3
    * @since                           13-Nov-2012
    **********************************************************************************************/
    FUNCTION append_tables_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_table_to_append IN pk_prog_notes_types.t_table_tasks,
        io_total_table    IN OUT pk_prog_notes_types.t_table_tasks,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_id epis_pn_det_task.id_epis_pn_det_task%TYPE;
    BEGIN
        IF (i_table_to_append IS NOT NULL)
        THEN
        
            l_id := i_table_to_append.first;
        
            LOOP
                EXIT WHEN l_id IS NULL;
                io_total_table(l_id) := i_table_to_append(l_id);
            
                l_id := i_table_to_append.next(l_id);
            END LOOP;
        
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'APPEND_TABLES_TASKS',
                                              o_error);
            RETURN FALSE;
    END append_tables_tasks;

    /**************************************************************************
    * Get the professional and date of review used to aggregate the data.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_task_type           Task type ID
    * @param i_id_task                Task ID
    * @param   i_id_prof_review     Professional that performed the last review of the record
    * @param   i_dt_review          Date in which was performed the last review of the record    
    * @param o_error                  Error
    *
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2.3                          
    * @since                          13-Nov-2012                               
    **************************************************************************/
    FUNCTION get_review_data_from_ea
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_task_type   IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task        IN task_timeline_ea.id_task_refid%TYPE,
        o_id_prof_review OUT NOCOPY task_timeline_ea.id_prof_review%TYPE,
        o_dt_review      OUT NOCOPY task_timeline_ea.dt_review%TYPE,
        o_dt_last_update OUT NOCOPY task_timeline_ea.dt_last_update%TYPE,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(23 CHAR) := 'GET_REVIEW_DATA_FROM_EA';
    BEGIN
        g_error := 'GET review data from ea. i_id_task_type: ' || i_id_task_type || ' i_id_task: ' || i_id_task;
        SELECT t.id_prof_review, t.dt_review, t.dt_last_update
          INTO o_id_prof_review, o_dt_review, o_dt_last_update
          FROM v_pn_tasks t
         WHERE t.id_task = i_id_task
           AND t.id_tl_task = i_id_task_type;
    
        RETURN TRUE;
    EXCEPTION
        WHEN no_data_found THEN
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_review_data_from_ea;

    /**************************************************************************
    * Calculates the signature to be shown in the creation/edition screen for each record.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_episode             Episode ID
    * @param i_id_prof_last_upd       Last update professional
    * @param i_dt_last_upd            Last update date
    * @param i_id_prof_review         Professional that performed the last review of the record
    * @param i_dt_review              Date in which was performed the last review of the record
    * @param i_flg_show_signature     Y-the signature should be shown. N-otherwise
    *
    * @return varchar2                 signature text
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.2.3                            
    * @since                          14-Nov-2012                             
    **************************************************************************/
    FUNCTION get_signature
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN episode.id_episode%TYPE,
        i_id_prof_last_upd   IN professional.id_professional%TYPE,
        i_dt_last_upd        IN epis_pn.dt_last_update%TYPE,
        i_id_prof_review     IN professional.id_professional%TYPE,
        i_dt_review          IN epis_pn.dt_last_update%TYPE,
        i_flg_show_signature IN VARCHAR2,
        i_id_pn_task_type    IN epis_pn_det_task.id_task_type%TYPE DEFAULT NULL
    ) RETURN VARCHAR2 IS
        l_func_name CONSTANT VARCHAR2(13 CHAR) := 'GET_SIGNATURE';
        l_res             pk_translation.t_desc_translation;
        l_id_professional professional.id_professional%TYPE;
        l_dt_reg          epis_pn.dt_last_update%TYPE;
        l_code_message    sys_message.code_message%TYPE;
    
    BEGIN
        g_error := 'get_signature. i_flg_show_signature: ' || i_flg_show_signature || ' i_id_prof_last_upd: ' ||
                   i_id_prof_last_upd || ' i_id_episode: ' || i_id_episode || 'i_id_prof_review: ' || i_id_prof_review ||
                   ' i_dt_last_upd: ' || to_char(i_dt_last_upd) || ' i_dt_review: ' || to_char(i_dt_review);
    
        IF (i_flg_show_signature = pk_alert_constant.g_yes)
        THEN
            IF (i_dt_last_upd > i_dt_review OR i_dt_review IS NULL)
            THEN
                l_id_professional := i_id_prof_last_upd;
                l_dt_reg          := i_dt_last_upd;
                l_code_message    := pk_prog_notes_constants.g_sm_registered;
            ELSE
                l_id_professional := i_id_prof_review;
                l_dt_reg          := i_dt_review;
                l_code_message    := pk_prog_notes_constants.g_sm_reviewed;
            END IF;
        
            l_res := pk_inp_detail.get_signature(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_episode          => i_id_episode,
                                                 i_id_prof_last_change => l_id_professional,
                                                 i_date                => l_dt_reg,
                                                 i_code_desc           => l_code_message,
                                                 i_flg_show_sw         => pk_alert_constant.g_no);
        END IF;
    
        RETURN l_res;
    
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'get_signature exception error: ' || SQLERRM;
            pk_alertlog.log_info(text => g_error, object_name => g_package, sub_object_name => l_func_name);
            RETURN NULL;
    END get_signature;

    /**
    * Indicates if the current task type should be synchronized with the original area
    *
    * @param i_lang                   language identifier
    * @param i_prof                   logged professional structure
    * @param i_id_task_type           Task type ID
    *
    * @return                         Y - If the task is to be synchronized immediately with the directed area 
    *                                 when is changed in the note. N- otherwise
    *
    * @author               Sofia Mendes
    * @version               2.6.3.2
    * @since               23-Jan-2012
    */
    FUNCTION get_flg_synch_area
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN tl_task.id_tl_task%TYPE
    ) RETURN tl_task.flg_synch_area%TYPE IS
        l_error          t_error_out;
        l_flg_synch_area tl_task.flg_synch_area%TYPE;
    BEGIN
        g_error := 'GET FLG_SYNCH_AREA. i_id_task_type: ' || i_id_task_type;
        BEGIN
            SELECT t.flg_synch_area
              INTO l_flg_synch_area
              FROM tl_task t
             WHERE t.id_tl_task = i_id_task_type;
        EXCEPTION
            WHEN no_data_found THEN
                l_flg_synch_area := pk_alert_constant.g_no;
        END;
    
        RETURN l_flg_synch_area;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'get_flg_synch_area',
                                              l_error);
        
            RETURN '';
    END get_flg_synch_area;
    /**
    * get_ds_id_prof_signoff
    *
    * @param i_id_episode             episode ID
    *
    * @return                         id_prof_signoff
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_ds_id_prof_signoff(i_id_episode IN epis_pn.id_episode%TYPE) RETURN epis_pn.id_prof_signoff%TYPE IS
        l_id_prof_signoff epis_pn.id_prof_signoff%TYPE;
    BEGIN
        g_error := 'get_ds_id_prof_signoff i_id_episode=' || i_id_episode;
    
        SELECT id_prof_signoff
          INTO l_id_prof_signoff
          FROM (SELECT ep.id_prof_signoff, row_number() over(ORDER BY ep.dt_signoff DESC) linenumber
                  FROM epis_pn ep
                 WHERE ep.id_episode = i_id_episode
                   AND ep.id_pn_area = pk_prog_notes_constants.g_area_disch_4
                   AND ep.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_s)
         WHERE linenumber = 1;
    
        RETURN l_id_prof_signoff;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ds_id_prof_signoff;

    /**
    * get_single_page_indicators
    *
    * @param i_id_episode             episode ID
    * @param i_id_pn_area             pn_area ID
    * @param i_flg_status             flg_status 
    *
    * @return                         Y/N
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_single_page_indicators
    (
        i_id_episode IN epis_pn.id_episode%TYPE,
        i_id_pn_area epis_pn.id_pn_area%TYPE,
        i_flg_status epis_pn.flg_status%TYPE
    ) RETURN VARCHAR2 IS
        l_return VARCHAR2(1 CHAR);
        l_count  NUMBER(12);
    BEGIN
        g_error := 'get_SINGLE_PAGE_INDICATORS i_id_episode=' || i_id_episode || ' i_id_pn_area=' || i_id_pn_area ||
                   ' i_flg_status= ' || i_flg_status;
    
        SELECT COUNT(1)
          INTO l_count
          FROM epis_pn ep
         WHERE ep.id_episode = i_id_episode
           AND ep.id_pn_area = i_id_pn_area
           AND ep.flg_status = i_flg_status
           AND rownum = 1;
    
        IF l_count > 0
        THEN
            l_return := pk_alert_constant.g_yes;
        ELSE
            l_return := pk_alert_constant.g_no;
        END IF;
    
        RETURN l_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END get_single_page_indicators;
    /**
    * get_ds_dt_signoff
    *
    * @param i_id_episode             episode ID
    *
    * @return                         id_prof_signoff
    *
    * @author               Paulo Teixeira
    * @version               2.6.3.2
    * @since               5-Fev-2012
    */
    FUNCTION get_ds_dt_signoff(i_id_episode IN epis_pn.id_episode%TYPE) RETURN epis_pn.dt_signoff%TYPE IS
        l_dt_signoff epis_pn.dt_signoff%TYPE;
    BEGIN
        g_error := 'get_dt_signoff i_id_episode=' || i_id_episode;
    
        SELECT dt_signoff
          INTO l_dt_signoff
          FROM (SELECT ep.dt_signoff, row_number() over(ORDER BY ep.dt_signoff DESC) linenumber
                  FROM epis_pn ep
                 WHERE ep.id_episode = i_id_episode
                   AND ep.id_pn_area = pk_prog_notes_constants.g_area_disch_4
                   AND ep.flg_status = pk_prog_notes_constants.g_epis_pn_flg_status_s)
         WHERE linenumber = 1;
    
        RETURN l_dt_signoff;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_ds_dt_signoff;

    /*
    * Function to highlight the searched text
    *
    * @param i_text             Full text to be searched
    * @param i_search           Text to search
    *
    * @return                   Returns the searched text highlighted (bold and italic)
    *
    * @author                   Vanessa Barsottelli
    * @version                  2.6.3
    * @since                    15-Jan-2014
    */
    FUNCTION highlight_searched_text
    (
        i_text   IN CLOB,
        i_search IN VARCHAR2
    ) RETURN CLOB IS
        l_text          CLOB := i_text;
        l_search        VARCHAR2(4000 CHAR);
        l_search_no_sc  table_varchar;
        l_text_original table_varchar;
        l_text_no_sc    table_varchar;
    BEGIN
    
        IF i_search IS NOT NULL
        THEN
            --If the search string is between "" then search only for the specific word/phrase 
            --Otherwise search for all occurrenses
            IF regexp_like(i_search, '^"')
               AND regexp_like(i_search, '"$')
            THEN
                --Get the string between "" and escape reserved characters
                l_search := substr(i_search, 2, length(i_search) - 2);
                l_search := regexp_replace(l_search, '([][)(}{.$*+?,|^\])', '\\\1');
                l_text   := regexp_replace(i_text,
                                           '((^|\s)' || l_search || '(\s|[[:punct:]]|$))',
                                           '<b><i>' || '\1' || '</i></b>',
                                           1,
                                           0,
                                           'i');
            ELSE
                --Get the words to be seached
                l_search       := regexp_replace(regexp_replace(TRIM(i_search), '[^a-zA-Z0-9.-]', ' '), '[.]$', '');
                l_search_no_sc := pk_string_utils.str_split(pk_utils.remove_upper_accentuation(l_search), ' ');
            
                --Get the original text without repetitions and non-alphanumeric (,;:) 
                SELECT DISTINCT regexp_replace(regexp_replace(column_value, '[^a-zA-Z0-9.-]', ''), '[.]$', '')
                  BULK COLLECT
                  INTO l_text_original
                  FROM TABLE(pk_utils.split_clob(l_text, ' '));
            
                --Get the original text without special characters
                SELECT pk_utils.remove_upper_accentuation(column_value)
                  BULK COLLECT
                  INTO l_text_no_sc
                  FROM TABLE(l_text_original);
            
                FOR i IN 1 .. l_text_no_sc.count
                LOOP
                    FOR j IN 1 .. l_search_no_sc.count
                    LOOP
                        --highlight the word only if it starts with the searched string
                        IF instr(l_text_no_sc(i), l_search_no_sc(j)) = 1
                        THEN
                            l_text := regexp_replace(l_text,
                                                     l_text_original(i),
                                                     '<b><i>' || l_text_original(i) || '</i></b>');
                        END IF;
                    END LOOP;
                END LOOP;
            END IF;
        
        END IF;
    
        RETURN l_text;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'highlight_searched_text exception error: ' || SQLERRM;
            pk_alertlog.log_info(text            => g_error,
                                 object_name     => g_package,
                                 sub_object_name => 'HIGHLIGHT_SEARCHED_TEXT');
            RETURN l_text;
    END highlight_searched_text;

    FUNCTION get_pn_episode
    (
        i_table_name user_tables.table_name%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN episode.id_episode%TYPE IS
        l_id_episode episode.id_episode%TYPE;
        l_id_epis_pn epis_pn.id_epis_pn%TYPE;
    BEGIN
    
        IF i_table_name IN ('EPIS_PN_SIGNOFF', 'EPIS_PN_ADDENDUM', 'EPIS_PN_DET')
        THEN
        
            SELECT id_episode
              INTO l_id_episode
              FROM epis_pn
             WHERE id_epis_pn = i_id_epis_pn;
        
        ELSIF i_table_name = 'EPIS_PN_DET_TASK'
        THEN
        
            SELECT DISTINCT epn.id_epis_pn
              INTO l_id_epis_pn
              FROM epis_pn_det_task epdt
              JOIN epis_pn_det epd
                ON epd.id_epis_pn_det = epdt.id_epis_pn_det
              JOIN epis_pn epn
                ON epn.id_epis_pn = epd.id_epis_pn
             WHERE epdt.id_epis_pn_det = i_id_epis_pn;
        
            SELECT id_episode
              INTO l_id_episode
              FROM epis_pn
             WHERE id_epis_pn = l_id_epis_pn;
        
        END IF;
    
        RETURN l_id_episode;
    END get_pn_episode;

    FUNCTION get_pn_patient
    (
        i_table_name user_tables.table_name%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN patient.id_patient%TYPE IS
        l_id_patient patient.id_patient%TYPE;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        IF i_table_name IN ('EPIS_PN_SIGNOFF', 'EPIS_PN_ADDENDUM', 'EPIS_PN_DET')
        THEN
        
            l_id_episode := get_pn_episode(i_table_name, i_id_epis_pn);
        
            SELECT id_patient
              INTO l_id_patient
              FROM episode
             WHERE id_episode = l_id_episode;
        
        ELSIF i_table_name = 'EPIS_PN_DET_TASK'
        THEN
        
            l_id_episode := get_pn_episode('EPIS_PN_DET_TASK', i_id_epis_pn);
        
            SELECT id_patient
              INTO l_id_patient
              FROM episode
             WHERE id_episode = l_id_episode;
        END IF;
    
        RETURN l_id_patient;
    
    END get_pn_patient;

    /*
    * Function to check if epis_pn exists (if the note was saved)
    *
    * @param i_id_epis_pn       id_epis_pn to search for
    *
    * @return                   Returns 'Y' if exists 'N' if not
    *
    * @author                   Nuno Alves
    * @version                  2.6.4.3
    * @since                    13-Jan-2015
    */
    FUNCTION check_epis_pn(i_id_epis_pn IN epis_pn.id_epis_pn%TYPE) RETURN CHAR IS
        l_has_epis_pn CHAR(1);
    BEGIN
        BEGIN
            SELECT pk_alert_constant.g_yes
              INTO l_has_epis_pn
              FROM epis_pn ep
             WHERE ep.id_epis_pn = i_id_epis_pn;
        EXCEPTION
            WHEN no_data_found THEN
                l_has_epis_pn := pk_alert_constant.g_no;
        END;
        RETURN l_has_epis_pn;
    END check_epis_pn;
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
        l_data               pk_types.cursor_type;
        l_text_blocks        pk_types.cursor_type;
        l_text_comments      pk_types.cursor_type;
        l_suggested          pk_types.cursor_type;
        l_configs            pk_types.cursor_type;
        l_data_blocks        pk_types.cursor_type;
        l_buttons            pk_types.cursor_type;
        l_cancelled          pk_types.cursor_type;
        l_doc_reg            pk_types.cursor_type;
        l_doc_val            pk_types.cursor_type;
        l_template_layouts   pk_types.cursor_type;
        l_doc_area_component pk_types.cursor_type;
    
    BEGIN
    
        g_error := 'CALL pk_prog_notes_core.get_work_notes_core';
        IF NOT pk_prog_notes_core.get_notes_core(i_lang                => i_lang,
                                                 i_prof                => i_prof,
                                                 i_id_episode          => i_id_episode,
                                                 i_id_epis_pn          => NULL,
                                                 i_id_pn_note_type     => i_id_pn_note_type,
                                                 i_id_epis_pn_det_task => table_number(),
                                                 i_id_pn_soap_block    => table_number(),
                                                 o_data                => l_data,
                                                 o_text_blocks         => l_text_blocks,
                                                 o_text_comments       => l_text_comments,
                                                 o_suggested           => l_suggested,
                                                 o_configs             => l_configs,
                                                 o_data_blocks         => l_data_blocks,
                                                 o_buttons             => l_buttons,
                                                 o_cancelled           => l_cancelled,
                                                 o_doc_reg             => l_doc_reg,
                                                 o_doc_val             => l_doc_val,
                                                 o_template_layouts    => l_template_layouts,
                                                 o_doc_area_component  => l_doc_area_component,
                                                 o_error               => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error := 'CALL pk_prog_notes_grids.get_notes_dashboard i_id_episode: ' || i_id_episode ||
                   ' i_id_pn_note_type:' || i_id_pn_note_type;
        IF NOT pk_prog_notes_grids.get_notes_dashboard(i_lang            => i_lang,
                                                       i_prof            => i_prof,
                                                       i_id_episode      => i_id_episode,
                                                       i_id_pn_note_type => i_id_pn_note_type,
                                                       o_title           => o_title,
                                                       o_note            => o_note,
                                                       o_error           => o_error)
        THEN
            RAISE g_exception;
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
                                              i_function => 'GET_NOTES_DASHBOARD',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_notes_dashboard;
    /**
    * Returns the info (labels & sample text) to prof grid popup
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param i_note_type    note type ID
    * @param o_info         labels for popup
    * @paramo_sample_text   sample text
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                27-04-2016
    */
    FUNCTION get_note_grid_info
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_episode     IN episode.id_episode%TYPE,
        i_note_type   IN pn_note_type.id_pn_note_type%TYPE,
        o_info        OUT pk_types.cursor_type,
        o_data_blocks OUT pk_types.cursor_type,
        o_sample_text OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(20 CHAR) := 'GET_NOTE_GRID_INFO';
        l_market           market.id_market%TYPE;
        l_sample_text_code pn_data_block.sample_text_code%TYPE;
        l_patient          patient.id_patient%TYPE;
        l_note_type_desc   pk_translation.t_desc_translation;
        l_configs_ctx      pk_prog_notes_types.t_configs_ctx;
    BEGIN
        g_error  := 'GET ID_MARKET';
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        g_error       := 'CALL RESET_CONTEXT';
        l_configs_ctx := pk_progress_notes_upd.reset_ctx(i_prof             => i_prof,
                                                         i_episode          => i_episode,
                                                         i_id_pn_note_type  => i_note_type,
                                                         i_epis_pn          => NULL,
                                                         i_id_dep_clin_serv => NULL);
    
        g_error := 'CALL PK_PROGRESS_NOTES_UPD.GET_ALL_BLOCKS';
        pk_progress_notes_upd.get_all_blocks(i_prof => i_prof, io_configs_ctx => l_configs_ctx);
    
        g_error := 'CALL PK_PROGRESS_NOTES_UPD.GET_DYNAMIC_DATA_BLOCKS';
        pk_progress_notes_upd.get_dynamic_data_blocks(i_lang        => i_lang,
                                                      i_prof        => i_prof,
                                                      i_episode     => i_episode,
                                                      i_data_blocks => l_configs_ctx.data_blocks,
                                                      i_task_types  => l_configs_ctx.task_types,
                                                      o_data_blocks => o_data_blocks);
    
        g_error := 'GET SAMPLE_TEXT_CODE';
        SELECT d.sample_text_code
          INTO l_sample_text_code
          FROM TABLE(l_configs_ctx.data_blocks) dmkt
          JOIN pn_data_block d
            ON d.id_pn_data_block = dmkt.id_pn_data_block
         WHERE d.flg_type = pk_prog_notes_constants.g_data_block_free_text;
    
        g_error := 'GET ID_PATIENT';
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_episode;
    
        g_error := 'CALL PK_SAMPLE_TEXT.GET_SAMPLE_TEXT';
        IF NOT pk_sample_text.get_sample_text(i_lang             => i_lang,
                                              i_sample_text_type => l_sample_text_code,
                                              i_patient          => l_patient,
                                              i_prof             => i_prof,
                                              o_sample_text      => o_sample_text,
                                              o_error            => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        g_error          := 'GET PN_NOTE_TYPE DESCRIPTION';
        l_note_type_desc := pk_prog_notes_utils.get_note_type_desc(i_lang               => i_lang,
                                                                   i_prof               => i_prof,
                                                                   i_id_pn_note_type    => i_note_type,
                                                                   i_flg_code_note_type => pk_prog_notes_constants.g_flg_code_note_type_desc_d);
    
        g_error := 'OPEN o_info CURSOR';
        OPEN o_info FOR
            SELECT REPLACE(pk_message.get_message(i_lang, pk_prog_notes_constants.g_sm_nurse_grid_title),
                           pk_prog_notes_constants.g_replace_1,
                           l_note_type_desc) title,
                   pk_message.get_message(i_lang, pk_prog_notes_constants.g_sm_datetime) datetime
              FROM dual;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_owner,
                                              i_package  => g_package,
                                              i_function => 'GET_NOTE_GRID_INFO',
                                              o_error    => o_error);
        
            RETURN FALSE;
    END get_note_grid_info;
    /**
    * Returns the actions to be displayed in the 'ACTIONS' button from prof grids
    *
    *
    * @param i_lang         language identifier
    * @param i_prof         logged professional structure
    * @param i_episode      episode identifier
    * @param o_actions      actions data
    * @param o_error        error
    *
    * @return               false if errors occur, true otherwise
    *
    * @author               Vanessa Barsottelli
    * @version              2.6.5
    * @since                26-04-2016
    */
    FUNCTION get_prof_grid_actions
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        o_actions OUT NOCOPY pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
        l_pat_age    patient.age%TYPE := NULL;
        l_pat_gender patient.gender%TYPE := NULL;
        l_pn_area    table_varchar;
        l_prof_cat   category.id_category%TYPE;
        l_no_area_exception EXCEPTION;
        l_id_market      market.id_market%TYPE := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_is_dicharged   VARCHAR2(1) := pk_alert_constant.g_no;
        l_pat_age_months NUMBER;
        l_id_patient     patient.id_patient%TYPE;
    
    BEGIN
    
        g_error := 'CALL pk_discharge.get_epis_discharge_state';
        IF NOT pk_discharge.get_epis_discharge_state(i_lang      => i_lang,
                                                     i_prof      => i_prof,
                                                     i_episode   => i_episode,
                                                     o_discharge => l_is_dicharged,
                                                     o_error     => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        --get patient age and gender
        g_error := 'Call PK_PATIENT.GET_PAT_INFO_BY_EPISODE';
        IF NOT pk_patient.get_pat_info_by_episode(i_lang    => i_lang,
                                                  i_episode => i_episode,
                                                  o_gender  => l_pat_gender,
                                                  o_age     => l_pat_age)
        THEN
            RAISE g_exception;
        END IF;
        SELECT id_patient
          INTO l_id_patient
          FROM episode
         WHERE id_episode = i_episode;
        l_pat_age_months := pk_patient.get_pat_age(i_lang, NULL, NULL, NULL, 'MONTHS', l_id_patient);
    
        BEGIN
            l_prof_cat := pk_prof_utils.get_id_category(i_lang => i_lang, i_prof => i_prof);
        
            g_error := 'GET l_area. l_prof_cat: ' || l_prof_cat;
            SELECT p.internal_name
              BULK COLLECT
              INTO l_pn_area
              FROM pn_area p
             WHERE p.id_category = l_prof_cat;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error := 'NO l_area defined';
                RAISE l_no_area_exception;
        END;
    
        g_error := 'GET CURSOR o_actions. l_pat_age: ' || l_pat_age || ' l_pat_gender: ' || l_pat_gender;
        OPEN o_actions FOR
            WITH notes AS
             (SELECT t.note_type                id_action,
                     -1                         id_parent,
                     NULL                       level_nr,
                     NULL                       from_state,
                     t.internal_name            to_state,
                     t.desc_action              desc_action,
                     NULL                       icon,
                     NULL                       flg_default,
                     t.action                   action,
                     pk_alert_constant.g_active flg_active,
                     t.rank
                FROM (SELECT /*+ OPT_ESTIMATE (TABLE tt ROWS=1)*/
                       pn.internal_name,
                       pk_message.get_message(i_lang, i_prof, nt.code_pn_note_type) desc_action,
                       'ADD_NOTE' action,
                       tt.max_nr_notes,
                       tt.id_pn_note_type note_type,
                       get_nr_notes_state(i_lang,
                                          i_prof,
                                          i_episode,
                                          table_varchar(pk_prog_notes_constants.g_epis_pn_flg_status_d,
                                                        pk_prog_notes_constants.g_epis_pn_flg_status_s,
                                                        pk_prog_notes_constants.g_epis_pn_flg_status_f,
                                                        pk_prog_notes_constants.g_epis_pn_flg_status_t),
                                          table_number(tt.id_pn_note_type)) nr_notes,
                       tt.rank,
                       tt.age_min,
                       tt.age_max,
                       tt.gender,
                       tt.flg_edit_after_disch
                        FROM TABLE(tf_pn_note_type(i_lang,
                                                   i_prof,
                                                   i_episode,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   NULL,
                                                   l_pn_area,
                                                   NULL,
                                                   pk_prog_notes_constants.g_pn_flg_scope_area_a,
                                                   NULL)) tt
                        JOIN pn_note_type nt
                          ON nt.id_pn_note_type = tt.id_pn_note_type
                        JOIN pn_area pn
                          ON pn.id_pn_area = tt.id_pn_area
                       WHERE tt.flg_write = pk_alert_constant.g_yes
                         AND tt.flg_create_on_app = pk_alert_constant.g_yes
                         AND nt.flg_type = pk_prog_notes_constants.g_pn_flg_scope_area_f
                         AND (SELECT check_note_type_free_text(i_prof             => i_prof,
                                                               i_market           => l_id_market,
                                                               i_department       => NULL,
                                                               i_dcs              => NULL,
                                                               i_id_pn_note_type  => nt.id_pn_note_type,
                                                               i_id_episode       => i_episode,
                                                               i_id_pn_data_block => NULL,
                                                               i_software         => i_prof.software)
                                FROM dual) = pk_alert_constant.g_yes) t
               WHERE (t.max_nr_notes IS NULL OR t.nr_notes < t.max_nr_notes)
                 AND check_pn_with_patient_info(i_lang, t.age_min, t.age_max, t.gender, l_pat_age_months, l_pat_gender) =
                     pk_alert_constant.g_yes
                 AND get_discharge_note_status(t.flg_edit_after_disch, l_is_dicharged) =
                     pk_prog_notes_constants.g_editable_all)
            
            SELECT -1 id_action,
                   NULL id_parent,
                   NULL level_nr,
                   NULL from_state,
                   NULL to_state,
                   pk_message.get_message(i_lang, i_prof, 'PN_M043') desc_action,
                   NULL icon,
                   NULL flg_default,
                   'ADD_NOTE_TITLE' action,
                   pk_alert_constant.g_active flg_active,
                   -1 rank
              FROM dual
             WHERE EXISTS (SELECT 1
                      FROM notes)
            UNION ALL
            SELECT id_action,
                   id_parent,
                   level_nr,
                   from_state,
                   to_state,
                   desc_action,
                   icon,
                   flg_default,
                   action,
                   flg_active,
                   rank
              FROM notes
             ORDER BY rank, desc_action;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN l_no_area_exception THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_ACTIONS_ADD_BUTTON',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_PROF_GRID_ACTIONS',
                                              o_error);
        
            pk_types.open_my_cursor(o_actions);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_prof_grid_actions;
    /**
    * check_note_type_free_text
    *
    * @param i_prof                logged professional structure
    * @param i_market              market identifier
    * @param i_department          service identifier
    * @param i_dcs                 service/specialty identifier
    * @param i_id_pn_note_type     Note type identifier
    * @param i_id_episode          Episode identifier
    * @param i_id_pn_data_block    Data Block Identifier
    * @param i_software            Software ID
    *
    * @return                      configured soap and data blocks ordered collection
    *
    * @author                      Pedro Carneiro
    * @version                     2.6.0.5.2
    * @since                       2011/01/27
    */
    FUNCTION check_note_type_free_text
    (
        i_prof             IN profissional,
        i_market           IN market.id_market%TYPE,
        i_department       IN department.id_department%TYPE,
        i_dcs              IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_software         IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_data_area table_varchar;
        l_ret       VARCHAR2(1 CHAR);
    BEGIN
    
        SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
         t.data_area
          BULK COLLECT
          INTO l_data_area
          FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof             => i_prof,
                                                          i_market           => i_market,
                                                          i_department       => i_department,
                                                          i_dcs              => i_dcs,
                                                          i_id_pn_note_type  => i_id_pn_note_type,
                                                          i_id_episode       => i_id_episode,
                                                          i_id_pn_data_block => i_id_pn_data_block,
                                                          i_software         => i_software)) t;
    
        IF l_data_area.count <> 2
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSIF pk_utils.search_table_varchar(i_table => l_data_area, i_search => 'CD') = -1
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSIF pk_utils.search_table_varchar(i_table => l_data_area, i_search => 'FT') = -1
        THEN
            l_ret := pk_alert_constant.g_no;
        ELSE
            l_ret := pk_alert_constant.g_yes;
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END;
    --
    FUNCTION get_bl_epis_documentation_ids(i_pn_note epis_pn_det.pn_note%TYPE) RETURN table_number IS
        nr    NUMBER(12);
        aux   epis_pn_det.pn_note%TYPE := i_pn_note;
        l_ret table_number := table_number();
    BEGIN
        nr := regexp_count(aux, '\[B\|ID_TASK:');
        l_ret.extend(nr);
        FOR i IN 1 .. nr
        LOOP
            aux := substr(aux, instr(aux, '[B|ID_TASK:') + 11);
            l_ret(i) := to_number(substr(aux, 0, instr(aux, ']') - 1));
        END LOOP;
    
        RETURN l_ret;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN table_number();
    END get_bl_epis_documentation_ids;
    --
    FUNCTION get_bl_epis_documentation_clob
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_pn_note epis_pn_det.pn_note%TYPE
    ) RETURN CLOB IS
        nr                      NUMBER(12);
        aux                     epis_pn_det.pn_note%TYPE := i_pn_note;
        l_ret                   CLOB := i_pn_note;
        l_id_epis_documentation epis_documentation.id_epis_documentation%TYPE;
        finds                   VARCHAR2(200 CHAR);
        replaces                CLOB;
    BEGIN
        nr := regexp_count(aux, '\[B\|ID_TASK:');
        FOR i IN 1 .. nr
        LOOP
            aux                     := substr(aux, instr(aux, '[B|ID_TASK:') + 11);
            l_id_epis_documentation := to_number(substr(aux, 0, instr(aux, ']') - 1));
            finds                   := '[B|ID_TASK:' || l_id_epis_documentation || ']';
            replaces                := pk_touch_option_core.get_plain_text_entry(i_lang               => i_lang,
                                                                                 i_prof               => i_prof,
                                                                                 i_epis_documentation => l_id_epis_documentation);
            l_ret                   := REPLACE(l_ret, finds, replaces);
        END LOOP;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_bl_epis_documentation_clob;

    FUNCTION has_soap_mandatory_block
    (
        i_prof            IN profissional,
        i_soap_block      IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_market          IN market.id_market%TYPE,
        i_department      IN department.id_department%TYPE,
        i_dcs             IN dep_clin_serv.id_dep_clin_serv%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_software        IN software.id_software%TYPE
    ) RETURN VARCHAR2 IS
        l_tbl table_number;
    BEGIN
        SELECT 1
          BULK COLLECT
          INTO l_tbl
          FROM TABLE(pk_progress_notes_upd.tf_data_blocks(i_prof            => i_prof,
                                                          i_market          => i_market,
                                                          i_department      => i_department,
                                                          i_dcs             => i_dcs,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          i_id_episode      => i_id_episode,
                                                          i_software        => i_software)) t
         WHERE t.id_pn_soap_block = i_soap_block
           AND t.flg_mandatory = pk_alert_constant.g_yes;
    
        IF l_tbl.count > 0
        THEN
            RETURN pk_alert_constant.g_yes;
        ELSE
            RETURN pk_alert_constant.g_no;
        END IF;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
    END has_soap_mandatory_block;

    FUNCTION get_doc_status_list
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT NOCOPY pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
        l_sm_yes sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PN_T135');
        l_sm_no  sys_message.desc_message%TYPE := pk_message.get_message(i_lang, 'PN_T143');
    BEGIN
    
        g_error := 'GET CURSOR o_list';
        OPEN o_list FOR
            SELECT l_sm_yes label, 'Y' data
              FROM dual
            UNION ALL
            SELECT l_sm_no label, 'N' data
              FROM dual;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DOC_STATUS_LIST',
                                              o_error);
        
            pk_types.open_my_cursor(o_list);
            pk_alert_exceptions.reset_error_state;
            RETURN FALSE;
    END get_doc_status_list;

    FUNCTION get_prof_signature
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_episode          IN episode.id_episode%TYPE,
        i_id_prof_create      IN professional.id_professional%TYPE,
        i_dt_create           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_last_update IN professional.id_professional%TYPE,
        i_dt_last_update      IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_sign_off    IN professional.id_professional%TYPE,
        i_dt_sign_off         IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_cancel      IN professional.id_professional%TYPE,
        i_dt_cancel           IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_id_prof_reviewed    IN professional.id_professional%TYPE,
        i_dt_reviewed         IN TIMESTAMP WITH LOCAL TIME ZONE --, 
        --    i_id_prof_submit  professional.id_professional%TYPE,
        --     i_dt_submit         IN TIMESTAMP WITH LOCAL TIME ZONE
    ) RETURN NUMBER IS
        l_id_prof professional.id_professional%TYPE;
    BEGIN
        IF (i_id_prof_cancel IS NOT NULL AND i_dt_cancel IS NOT NULL)
        THEN
            l_id_prof := i_id_prof_cancel;
        ELSIF (i_id_prof_sign_off IS NOT NULL AND i_dt_sign_off IS NOT NULL)
        THEN
            l_id_prof := i_id_prof_sign_off;
            --     ELSIF (i_id_prof_submit IS NOT NULL AND i_dt_submit IS NOT NULL)
            --       THEN
            --           l_id_prof := i_id_prof_submit;            
        ELSIF (i_id_prof_reviewed IS NOT NULL AND i_dt_reviewed IS NOT NULL)
        THEN
            l_id_prof := i_id_prof_reviewed;
        ELSIF (i_id_prof_last_update IS NOT NULL AND i_dt_last_update IS NOT NULL)
        THEN
            l_id_prof := i_id_prof_last_update;
        ELSIF (i_id_prof_create IS NOT NULL AND i_dt_create IS NOT NULL)
        THEN
            l_id_prof := i_id_prof_create;
        END IF;
        RETURN l_id_prof;
    END get_prof_signature;

    -- ************************************************
    -- If returns N, no button SUBMIT.
    -- if returns R, professional is NOT attending phys of current episode. button SUBMIT ON
    -- if returns S, professional IS attending phys of current episode. button SUBMIT ON
    -- ************************************************
    FUNCTION is_prof_attending_phy
    (
        i_prof    IN profissional,
        i_episode IN NUMBER
    ) RETURN VARCHAR2 IS
        l_return              VARCHAR2(0010 CHAR);
        l_id_profile_template NUMBER;
        xrow                  profile_template%ROWTYPE;
    BEGIN
    
        xrow := pk_prof_utils.get_profile_info(i_prof => i_prof);
    
        IF xrow.flg_submit_mode IS NOT NULL
        THEN
            l_return := xrow.flg_submit_mode;
        ELSE
            l_return := k_flg_review;
        END IF;
    
        RETURN l_return;
    
    END is_prof_attending_phy;

    FUNCTION get_dblock_sblock
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_dblocks          IN t_coll_dblock,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE
    ) RETURN NUMBER IS
        l_func_name CONSTANT VARCHAR2(22 CHAR) := 'get_dblock_sblock';
        l_dblocks_count    PLS_INTEGER;
        l_id_pn_soap_block NUMBER;
        l_error            t_error_out;
    BEGIN
        g_error := 'GET dblock_cfgs_rec. i_id_pn_data_block: ' || i_id_pn_data_block;
    
        l_dblocks_count := i_dblocks.count;
    
        FOR i IN 1 .. l_dblocks_count
        LOOP
            IF (i_dblocks(i).id_pn_data_block = i_id_pn_data_block)
            THEN
                l_id_pn_soap_block := i_dblocks(i).id_pn_soap_block;
                EXIT;
            END IF;
        END LOOP;
    
        RETURN l_id_pn_soap_block;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_dblock_sblock;

    FUNCTION get_number_imported_blocks(i_id_epis_pn IN epis_pn.id_epis_pn%TYPE) RETURN NUMBER IS
        l_number_records NUMBER;
    
    BEGIN
    
        SELECT COUNT(epdt.id_epis_pn_det_task)
          INTO l_number_records
          FROM epis_pn_det_task epdt
         INNER JOIN epis_pn_det epd
            ON epd.id_epis_pn_det = epdt.id_epis_pn_det
         INNER JOIN epis_pn ep
            ON ep.id_epis_pn = epd.id_epis_pn
         WHERE ep.id_epis_pn = i_id_epis_pn;
    
        RETURN l_number_records;
    
    END get_number_imported_blocks;

    /**************************************************************************
    **************************************************************************/
    FUNCTION check_iss_diag_validation
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE,
        o_msg_type   OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_ISS_DIAG_VALIDATION';
    
        l_iss_tt_num NUMBER := 0; -- Modified Injury Severity Score (ISS)
        l_dd_tt_num  NUMBER := 0; -- Discharge Diagnosis
    
        -----------------------------------------------------
        FUNCTION get_pn_task_type_num
        (
            i_id_epis_pn   IN epis_pn.id_epis_pn%TYPE,
            i_id_task_type IN epis_pn_det_task.id_task_type%TYPE
        ) RETURN NUMBER IS
            l_counter NUMBER;
        BEGIN
            SELECT COUNT(1)
              INTO l_counter
              FROM epis_pn ep
              JOIN epis_pn_det epd
                ON epd.id_epis_pn = ep.id_epis_pn
              JOIN epis_pn_det_task epdt
                ON epdt.id_epis_pn_det = epd.id_epis_pn_det
             WHERE ep.id_epis_pn = i_id_epis_pn
               AND ep.flg_status != pk_prog_notes_constants.g_epis_pn_flg_status_c
               AND epd.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND epdt.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND epdt.id_task_type = i_id_task_type;
        
            RETURN nvl(l_counter, 0);
        END;
        -----------------------------------------------------
    BEGIN
        l_iss_tt_num := get_pn_task_type_num(i_id_epis_pn, pk_prog_notes_constants.g_task_mtos_score);
        l_dd_tt_num  := get_pn_task_type_num(i_id_epis_pn, pk_prog_notes_constants.g_task_final_diag);
    
        -- has DD ? missing ISS
        -- has ISS ? missing DD
        -- has ISS with value x ? missing DD y
        IF l_dd_tt_num > 0
           AND l_iss_tt_num = 0 -- UC2 & UC3: has DD ? missing ISS
        THEN
            NULL;
        ELSIF l_iss_tt_num > 0
              AND l_dd_tt_num = 0 -- UC4: has ISS ? missing DD
        THEN
            NULL;
        ELSIF l_iss_tt_num > 0
              AND l_dd_tt_num = 0 -- UC5: has ISS ? missing DD
        -- and ISS value > 16
        THEN
            NULL;
        END IF;
    
        RETURN TRUE;
    EXCEPTION
        --WHEN no_data_found THEN
        --    RETURN TRUE;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_iss_diag_validation;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_calendar_date_control  Calendar control N:Next week, P:Previous week
                                      null: Current week
    * @param i_current_date           Calendar control (2017-12-01)
                                      null: Current date
    *
    * @param o_note_lists             cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-11-24                       
    **************************************************************************/
    FUNCTION get_days_in_current_week
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_calendar_date_control IN VARCHAR2 DEFAULT NULL,
        i_current_date          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        o_calendar_period       OUT VARCHAR,
        o_begin_date            OUT VARCHAR2,
        o_end_date              OUT VARCHAR2,
        o_current_date_num      OUT NUMBER,
        o_calendar_dates        OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name     VARCHAR2(50 CHAR) := 'GET_DAYS_IN_CURRENT_WEEK';
        l_current_date  TIMESTAMP WITH TIME ZONE;
        l_fd_of_week    TIMESTAMP WITH LOCAL TIME ZONE;
        l_begin_date    TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date      TIMESTAMP WITH LOCAL TIME ZONE;
        l_one_week      NUMBER(1) := 7;
        l_previous_date VARCHAR2(1 CHAR) := 'P';
        l_next_date     VARCHAR2(1 CHAR) := 'N';
        l_current       VARCHAR2(1 CHAR) := 'C';
    
        l_cal_fd_monday         CONSTANT VARCHAR2(1 CHAR) := 'M';
        l_cal_fd_sunday         CONSTANT VARCHAR2(1 CHAR) := 'S';
        l_sysconf_name_of_fdate CONSTANT VARCHAR2(30 CHAR) := 'CALENDAR_VIEW_F_DATE_OF_WEEK';
    
        l_date_format sys_config.value%TYPE;
        l_fd_format   sys_config.value%TYPE;
        l_cal_fd      NUMBER;
    
    BEGIN
        l_cal_fd := pk_prog_notes_cal_condition.get_first_date_of_week(i_prof => i_prof);
    
        g_error := 'l_cal_fd:' || l_cal_fd || ' i_current_date:' || i_current_date;
    
        IF i_current_date IS NULL
        THEN
            l_current_date := current_timestamp;
        ELSIF i_calendar_date_control = l_previous_date
        THEN
            l_current_date := i_current_date - numtodsinterval(1, 'DAY');
        ELSIF i_calendar_date_control = l_next_date
        THEN
            l_current_date := i_current_date + numtodsinterval(1, 'DAY') + numtodsinterval(l_cal_fd, 'DAY');
        ELSIF i_calendar_date_control = l_current
        THEN
            l_current_date := i_current_date;
        END IF;
    
        l_fd_of_week := pk_date_utils.trunc_insttimezone(i_prof, l_current_date, 'IW');
    
        l_begin_date := l_fd_of_week - numtodsinterval(l_cal_fd, 'DAY');
        o_begin_date := pk_date_utils.date_send_tsz(i_lang, l_begin_date, i_prof);
    
        l_end_date := l_fd_of_week + numtodsinterval(6 - l_cal_fd, 'DAY');
        o_end_date := pk_date_utils.date_send_tsz(i_lang, l_end_date, i_prof);
    
        o_calendar_period := pk_prog_notes_cal_condition.get_period(i_lang       => i_lang,
                                                                    i_prof       => i_prof,
                                                                    i_begin_date => l_begin_date,
                                                                    i_end_date   => l_end_date);
    
        OPEN o_calendar_dates FOR
            SELECT pk_prog_notes_cal_condition.get_name_of_date(i_lang     => i_lang,
                                                                i_prof     => i_prof,
                                                                i_date     => dt1,
                                                                i_dt_begin => l_begin_date) day_desc
              FROM (SELECT l_begin_date - numtodsinterval(1, 'DAY') + numtodsinterval(LEVEL, 'DAY') dt1
                      FROM dual
                    CONNECT BY LEVEL <= l_one_week);
        BEGIN
        
            SELECT diff_var
              INTO o_current_date_num
              FROM (SELECT dt1,
                           CASE
                                WHEN pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => dt1) =
                                     pk_date_utils.trunc_insttimezone(i_prof => i_prof, i_timestamp => current_timestamp) THEN
                                 rownum
                                ELSE
                                 0
                            END diff_var
                      FROM (SELECT l_begin_date - numtodsinterval(1, 'DAY') + numtodsinterval(LEVEL, 'DAY') dt1
                              FROM dual
                            CONNECT BY LEVEL <= l_one_week))
             WHERE diff_var > 0;
        EXCEPTION
            WHEN no_data_found THEN
                o_current_date_num := NULL;
        END;
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_days_in_current_week;

    /********************************************************************************************
    * Get the days  between the given two notes to the given note type and episode.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_id_episode              Episode ID
    * @param       i_id_pn_note_type         Note type ID
    * @param       o_start_date              last note date
    * @param       o_end_date                current note date
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Lillian Lu
    * @since                                 2017/12/10
    ********************************************************************************************/
    FUNCTION get_days_between_notes
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        o_start_date      OUT epis_pn.dt_create%TYPE,
        o_end_date        OUT epis_pn.dt_create%TYPE,
        o_error           OUT t_error_out
    ) RETURN NUMBER IS
        l_note_count NUMBER(24);
        l_note_date  table_timestamp := table_timestamp();
        l_days       NUMBER(24);
    BEGIN
        g_error := 'GET get_days_between_notes. i_id_pn_note_type: ' || i_id_pn_note_type || ' i_id_episode: ' ||
                   i_id_episode;
    
        SELECT COUNT(1)
          INTO l_note_count
          FROM epis_pn e
         WHERE e.id_episode = i_id_episode
           AND e.id_pn_note_type = i_id_pn_note_type
           AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c;
    
        IF l_note_count > 1
        THEN
            SELECT t.dt_note
              BULK COLLECT
              INTO l_note_date
              FROM (SELECT nvl(e.dt_pn_date, e.dt_create) dt_note,
                           row_number() over(PARTITION BY e.id_episode, e.id_pn_note_type ORDER BY e.dt_pn_date DESC) rn
                      FROM epis_pn e
                     WHERE e.id_episode = i_id_episode
                       AND e.id_pn_note_type = i_id_pn_note_type
                       AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) t
             WHERE t.rn <= 2;
            o_start_date := l_note_date(2);
            o_end_date   := l_note_date(1);
        
        ELSE
            g_error := 'CALL pk_prog_notes_core.get_epis_dt_begin. i_episode: ' || i_id_episode;
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_id_episode,
                                                     o_dt_begin_tstz => o_start_date,
                                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
            IF l_note_count = 1
            THEN
                SELECT t.dt_note
                  INTO o_end_date
                  FROM (SELECT nvl(e.dt_pn_date, e.dt_create) dt_note,
                               row_number() over(PARTITION BY e.id_episode, e.id_pn_note_type ORDER BY e.dt_pn_date DESC) rn
                          FROM epis_pn e
                         WHERE e.id_episode = i_id_episode
                           AND e.id_pn_note_type = i_id_pn_note_type
                           AND e.flg_status <> pk_prog_notes_constants.g_epis_pn_flg_status_c) t
                 WHERE t.rn = 1;
            ELSE
                o_end_date := current_timestamp;
            END IF;
        END IF;
        l_days := pk_date_utils.diff_timestamp(o_end_date, o_start_date);
        RETURN l_days;
    
    EXCEPTION
        WHEN no_data_found THEN
            RETURN 0;
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              'GET_DAYS_BETWEEN_NOTES',
                                              o_error);
            RETURN NULL;
    END get_days_between_notes;

    /**************************************************************************
    * get notes data, use id_note_type to get note data
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_area                   pn_area internal name
    *
    * @param o_def_viewer_parameter   cursor with the information for timeline
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2017-12-27
    **************************************************************************/
    FUNCTION get_calendar_def_viewer
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_area                 IN VARCHAR2,
        o_def_viewer_parameter OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name VARCHAR2(50 CHAR) := 'GET_CALENDAR_DEF_VIEWER';
    BEGIN
        g_error := 'Get current date';
        OPEN o_def_viewer_parameter FOR
            SELECT pa.id_pn_area id_pn_area, pa.id_sys_shortcut id_sys_shortcut
              FROM pn_area pa
             WHERE pa.internal_name = i_area;
    
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
            pk_utils.undo_changes;
            RETURN FALSE;
    END get_calendar_def_viewer;

    /**************************************************************************
    * get delay time, input i_pn_note_type to get delay time of each pn_note_type
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_note_type           pn_note_type ID
    * @param i_is_in_icu              is this pn_note_type for icu
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18                   
    **************************************************************************/
    FUNCTION get_delay_time_by_note
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_is_in_icu    IN VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
    
        l_id_market  market.id_market%TYPE;
        l_delay_time NUMBER(4) := NULL;
        l_func_name  VARCHAR2(30 CHAR) := 'get_delay_time_by_note';
    
    BEGIN
    
        g_error     := 'CALL get_delay_time_by_note';
        l_id_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        BEGIN
            SELECT CASE
                        WHEN i_is_in_icu = pk_alert_constant.g_no THEN
                         nt.cal_delay_time
                        WHEN i_is_in_icu = pk_alert_constant.g_yes THEN
                         nt.cal_icu_delay_time
                    END delay_time
              INTO l_delay_time
              FROM (SELECT *
                      FROM TABLE (SELECT pk_prog_notes_utils.tf_pn_note_type(i_lang                => i_lang,
                                                                             i_prof                => i_prof,
                                                                             i_id_profile_template => pk_prof_utils.get_prof_profile_template(i_prof),
                                                                             i_id_market           => l_id_market,
                                                                             i_area                => NULL,
                                                                             i_id_note_type        => i_pn_note_type,
                                                                             i_flg_scope           => 'N',
                                                                             i_software            => i_prof.software)
                                    FROM dual)) nt;
        
        EXCEPTION
            WHEN no_data_found THEN
                g_error      := 'delay time not set';
                l_delay_time := NULL;
        END;
    
        RETURN l_delay_time;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := g_error || ' SQLCODE:' || SQLCODE || ', SQLERRM:' || SQLERRM;
            RETURN NULL;
    END get_delay_time_by_note;

    /**************************************************************************
    * get time-to-close of note
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_episode                Episode ID
    * @param i_epis_pn                epis_pn ID
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18                   
    **************************************************************************/
    FUNCTION gen_time_to_close
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_episode      IN episode.id_episode%TYPE,
        i_pn_note_type IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN INTERVAL DAY TO SECOND IS
        l_end_time      INTERVAL DAY TO SECOND;
        l_is_icu        VARCHAR2(1 CHAR);
        l_time_to_close NUMBER(4);
        l_func_name     VARCHAR2(30 CHAR) := 'gen_time_to_close';
    BEGIN
        g_error := 'CALL get_end_task_time, i_episode: ' || i_episode;
    
        l_is_icu        := pk_bmng.check_patient_in_icu(i_lang, i_prof, i_episode);
        l_time_to_close := get_delay_time_by_note(i_lang         => i_lang,
                                                  i_prof         => i_prof,
                                                  i_pn_note_type => i_pn_note_type,
                                                  i_is_in_icu    => l_is_icu);
    
        l_end_time := numtodsinterval(l_time_to_close, 'minute');
    
        RETURN l_end_time;
    EXCEPTION
        WHEN no_data_found THEN
            g_error := 'SQLCODE:' || SQLCODE || ', SQLERRM:' || SQLERRM;
        
            RETURN NULL;
    END gen_time_to_close;

    /**************************************************************************
    * get this note should be finish time
    * 
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_episode                Episode ID
    * @param i_epis_pn                epis_pn ID
    *
    * @author                         Kelsey Lai
    * @version                        2.7.2
    * @since                          2017-12-18                   
    **************************************************************************/
    FUNCTION get_end_task_time
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_episode IN episode.id_episode%TYPE,
        i_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE IS
        l_func_name     VARCHAR2(30 CHAR) := 'get_end_task_time';
        l_end_task_time TIMESTAMP WITH LOCAL TIME ZONE;
        l_sysdate_tstz  TIMESTAMP WITH LOCAL TIME ZONE;
        l_id_market     market.id_market%TYPE;
        l_prof_temp     profile_template.id_profile_template%TYPE;
    BEGIN
        g_error := 'CALL get_end_task_time, i_episode: ' || i_episode;
    
        l_sysdate_tstz := current_timestamp;
        l_id_market    := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
        l_prof_temp    := pk_prof_utils.get_prof_profile_template(i_prof);
        BEGIN
            SELECT t.dt_start_tstz + gen_time_to_close(i_lang, i_prof, t.id_episode, t.id_pn_note_type)
              INTO l_end_task_time
              FROM (SELECT CASE
                                WHEN nt.flg_cal_time_filter = 'A' THEN
                                 e.dt_begin_tstz
                                WHEN nt.flg_cal_time_filter = 'EN' THEN
                                 epn.dt_pn_date
                                WHEN nt.flg_cal_time_filter = 'EC' THEN
                                 epn.dt_create
                            END dt_start_tstz,
                           epn.id_episode,
                           epn.id_pn_note_type
                      FROM episode e
                     INNER JOIN epis_pn epn
                        ON e.id_episode = epn.id_episode
                      JOIN (SELECT /*+opt_estimate (table xtbl rows=1)*/
                            xtbl.*
                           
                             FROM TABLE(pk_prog_notes_utils.tf_pn_note_type(i_lang                => i_lang,
                                                                            i_prof                => i_prof,
                                                                            i_id_profile_template => l_prof_temp,
                                                                            i_id_market           => l_id_market,
                                                                            i_area                => table_varchar('HP',
                                                                                                                   'PN'),
                                                                            i_flg_scope           => 'A',
                                                                            i_software            => i_prof.software)) xtbl) nt
                    
                        ON nt.id_pn_note_type = epn.id_pn_note_type
                     WHERE e.id_episode = i_episode
                       AND epn.id_epis_pn = i_epis_pn) t;
        EXCEPTION
            WHEN no_data_found THEN
                g_error         := 'flg_cal_time_filter is not set';
                l_end_task_time := NULL;
        END;
    
        IF (l_end_task_time IS NULL)
        THEN
            SELECT nvl(epn.dt_pn_date, l_sysdate_tstz) + numtodsinterval(nvl(nt.time_to_close_note, 0), 'minute')
              INTO l_end_task_time
              FROM episode e
             INNER JOIN epis_pn epn
                ON e.id_episode = epn.id_episode
              JOIN TABLE (SELECT /*+opt_estimate(table nt rows=1)*/
                           pk_prog_notes_utils.tf_pn_area(i_lang,
                                                          i_prof,
                                                          epn.id_episode,
                                                          NULL,
                                                          NULL,
                                                          epn.id_dep_clin_serv,
                                                          NULL,
                                                          NULL)
                            FROM dual) nt
                ON nt.id_pn_area = epn.id_pn_area
             WHERE e.id_episode = i_episode
               AND epn.id_epis_pn = i_epis_pn;
        END IF;
        RETURN l_end_task_time;
    EXCEPTION
        WHEN OTHERS THEN
            g_error := 'SQLCODE:' || SQLCODE || ', SQLERRM:' || SQLERRM;
        
            RETURN NULL;
    END get_end_task_time;

    /**************************************************************************
    * get notes proposed date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_epis_pn             Epis_pn ID
    *
    * @author                         Amanda Lee
    * @version                        2.7
    * @since                          2018-01-04
    **************************************************************************/
    FUNCTION get_note_dt_proposed
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_episode IN episode.id_episode%TYPE,
        i_id_epis_pn IN epis_pn.id_epis_pn%TYPE
    ) RETURN epis_pn.dt_proposed%TYPE IS
        l_func_name   VARCHAR2(50 CHAR) := 'GET_NOTE_DT_PROPOSED';
        l_dt_proposed epis_pn.dt_proposed%TYPE;
    BEGIN
        g_error := 'Get proposed date';
    
        SELECT ep.dt_proposed
          INTO l_dt_proposed
          FROM epis_pn ep
         WHERE ep.id_epis_pn = i_id_epis_pn
           AND ep.id_episode = i_id_episode;
    
        RETURN l_dt_proposed;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_note_dt_proposed;

    /********************************************************************************************
    * Get the last note to the given note type acoording to the given statuses.
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional id structure
    * @param       i_scope                   Scope ID (Patient ID, Visit ID)
    * @param       i_scope_type              Scope type (by patient {P}, by visit {V})
    * @param       i_id_pn_note_type         PN note type ID
    * @param       i_note_status             Notes statuses
    * @param       o_id_epis_pn              Note ID
    * @param       o_error                   error message
    *
    * @return      boolean                   true on sucess, otherwise false
    *
    * @author                                Amanda Lee
    * @since                                 2018-01-08
    ********************************************************************************************/
    FUNCTION get_last_note_by_note_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE,
        i_note_status     IN table_varchar,
        o_id_epis_pn      OUT NOCOPY epis_pn.id_epis_pn%TYPE,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(28 CHAR) := 'GET_LAST_NOTE_BY_NOTE_TYPE';
        l_id_patient patient.id_patient%TYPE;
        l_id_visit   visit.id_visit%TYPE;
        l_id_episode episode.id_episode%TYPE;
    BEGIN
        g_error := 'CALL pk_touch_option.get_scope_vars. i_scope: ' || i_scope || ' i_scope_type: ' || i_scope_type;
        IF NOT pk_touch_option.get_scope_vars(i_lang       => i_lang,
                                              i_prof       => i_prof,
                                              i_scope      => i_scope,
                                              i_scope_type => i_scope_type,
                                              o_patient    => l_id_patient,
                                              o_visit      => l_id_visit,
                                              o_episode    => l_id_episode,
                                              o_error      => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        SELECT t.id_epis_pn
          INTO o_id_epis_pn
          FROM (SELECT e.id_epis_pn,
                       e.id_pn_note_type,
                       row_number() over(PARTITION BY e.id_episode, e.id_pn_note_type ORDER BY e.dt_pn_date DESC) rn
                  FROM epis_pn e
                  JOIN (SELECT /*+ OPT_ESTIMATE (TABLE ts ROWS=1)*/
                        column_value flg_status
                         FROM TABLE(i_note_status) ts) tst
                    ON tst.flg_status = e.flg_status
                  JOIN episode epi
                    ON epi.id_episode = e.id_episode
                 WHERE e.id_pn_note_type = i_id_pn_note_type
                   AND epi.id_patient = l_id_patient
                   AND e.dt_pn_date <= current_timestamp
                   AND (epi.id_visit = l_id_visit OR l_id_visit IS NULL)
                   AND (epi.id_episode = l_id_episode OR l_id_episode IS NULL)) t
         WHERE t.rn = 1;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN no_data_found THEN
            o_id_epis_pn := NULL;
            RETURN TRUE;
        WHEN OTHERS THEN
            o_id_epis_pn := NULL;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_last_note_by_note_type;

    /**************************************************************************
     * Returns the blocks related in the note (Used for autopopulate this block)
     *
     * @param i_lang         language identifier
     * @param i_prof         logged professional structure
     * @param i_id_sblock    List of soap block 
     * @param i_configs_ctx  Type with all note configurations
     * @param io_sblocks     List os soap blocks
     * @param io_dblocks     List os data blocks
     * @param o_error        error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Elisabete Bugalho
     * @version              2.7.2.4
     * @since                02/02/2018
    **************************************************************************/
    FUNCTION get_related_blocks
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_sblock   IN table_number,
        i_configs_ctx IN pk_prog_notes_types.t_configs_ctx,
        io_sblocks    IN OUT table_number,
        io_dblocks    IN OUT table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(28 CHAR) := 'GET_RELATED_BLOCKS';
        l_sblock table_number;
        l_dblock table_number;
    BEGIN
    
        SELECT db.id_pn_soap_block, db.id_pn_data_block
          BULK COLLECT
          INTO l_sblock, l_dblock
          FROM (SELECT /*+opt_estimate(table t rows=1)*/
                 t.id_pn_soap_block, t.id_pn_data_block
                  FROM TABLE(i_configs_ctx.data_blocks) t
                 WHERE t.id_pndb_related IS NOT NULL) db
          JOIN TABLE(i_configs_ctx.soap_blocks) sb
            ON db.id_pn_soap_block = sb.id_pn_soap_block
        /*         WHERE (i_id_sblock IS NULL OR
        sb.id_pn_soap_block IN (SELECT \*+opt_estimate(table tsb rows=1)*\
                                  column_value
                                   FROM TABLE(i_id_sblock) tsb))*/
        ;
    
        io_sblocks := io_sblocks MULTISET UNION l_sblock;
        io_dblocks := io_dblocks MULTISET UNION l_dblock;
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_related_blocks;

    /**************************************************************************
     * Check note, begin/end date
     *
     * @param i_lang                     language identifier
     * @param i_prof                     logged professional structure
     * @param i_id_episode               episode id
     * @param i_flg_filter               date filter condition
     * @param i_id_pn_note_type          pn note type
     * @param i_id_epis_pn               episode pn note id
     * @param i_id_epis_pn_det_task      episode note det task array
     * @param i_dt_proposed              proposed date
     * @param i_days_available_period    available date period
     * @param o_note_date
     * @param o_begin_date
     * @param o_end_date
     * @param o_error                    error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Lillian Lu
     * @version              2.7.3.2
     * @since                04/17/2018
    **************************************************************************/
    FUNCTION check_date_filter_base
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_episode            IN episode.id_episode%TYPE,
        i_flg_filter            IN pn_dblock_ttp_mkt.flg_auto_populated%TYPE,
        i_id_pn_note_type       IN pn_note_type.id_pn_note_type%TYPE,
        i_id_epis_pn            IN epis_pn.id_epis_pn%TYPE DEFAULT NULL,
        i_id_epis_pn_det_task   IN table_number,
        i_dt_proposed           IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_days_available_period IN pn_dblock_mkt.days_available_period%TYPE,
        o_begin_date            OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_end_date              OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_note_date             OUT NOCOPY TIMESTAMP WITH LOCAL TIME ZONE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'CHECK_DATE_FILTER_BASE';
        l_calc_last_date        PLS_INTEGER := 0;
        l_calc_date_period      PLS_INTEGER := 0;
        l_id_epis_pn            epis_pn.id_epis_pn%TYPE;
        l_pn_date               epis_pn.dt_pn_date%TYPE;
        l_begin_date            TIMESTAMP WITH LOCAL TIME ZONE;
        l_end_date              TIMESTAMP WITH LOCAL TIME ZONE;
        l_flg_technical         VARCHAR2(10 CHAR);
        l_days_available_period pn_dblock_mkt.days_available_period%TYPE := i_days_available_period;
    BEGIN
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_auto_pop_since_last_p,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
        
            IF (i_id_epis_pn_det_task IS NULL OR NOT i_id_epis_pn_det_task.exists(1))
            THEN
                l_calc_last_date := 1;
            END IF;
        
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_auto_pop_ong_exec_c,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
        
            IF (i_id_epis_pn_det_task IS NULL OR NOT i_id_epis_pn_det_task.exists(1))
            THEN
                l_calc_last_date := 1;
            END IF;
        
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_auto_pop_no_note_sl_b,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
        
            IF (i_id_epis_pn_det_task IS NULL OR NOT i_id_epis_pn_det_task.exists(1))
            THEN
                l_calc_last_date := 1;
            END IF;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_date_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_last_date   := 1;
            l_calc_date_period := 1;
            l_id_epis_pn       := i_id_epis_pn;
            l_flg_technical    := pk_prog_notes_constants.g_date_filter;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_event_date_o_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_last_date   := 1;
            l_calc_date_period := 1;
            l_id_epis_pn       := i_id_epis_pn;
            l_flg_technical    := pk_prog_notes_constants.g_event_date_o_filter;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_event_date_b_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_last_date   := 1;
            l_calc_date_period := 1;
            l_id_epis_pn       := i_id_epis_pn;
            l_flg_technical    := pk_prog_notes_constants.g_event_date_b_filter;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_note_date_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_flg_technical         := pk_prog_notes_constants.g_note_date_filter;
            l_days_available_period := pk_prog_notes_utils.get_days_between_notes(i_lang            => i_lang,
                                                                                  i_prof            => i_prof,
                                                                                  i_id_episode      => i_id_episode,
                                                                                  i_id_pn_note_type => i_id_pn_note_type,
                                                                                  o_start_date      => l_begin_date,
                                                                                  o_end_date        => l_end_date,
                                                                                  o_error           => o_error);
            o_note_date             := l_begin_date;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_admission_date_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_date_period := 1;
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_id_episode,
                                                     o_dt_begin_tstz => o_note_date,
                                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_flg_technical := pk_prog_notes_constants.g_admission_date_filter;
        END IF;
    
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_admission_date_b_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_date_period := 1;
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_id_episode,
                                                     o_dt_begin_tstz => o_note_date,
                                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_flg_technical := pk_prog_notes_constants.g_admission_date_b_filter;
        END IF;
        IF (pk_utils.str_token_find(i_string => i_flg_filter,
                                    i_token  => pk_prog_notes_constants.g_admission_dt_filter,
                                    i_sep    => pk_prog_notes_constants.g_sep) = pk_alert_constant.g_yes)
        THEN
            l_calc_date_period := 0;
            IF NOT pk_episode.get_epis_dt_begin_tstz(i_lang          => i_lang,
                                                     i_prof          => i_prof,
                                                     i_id_episode    => i_id_episode,
                                                     o_dt_begin_tstz => o_note_date,
                                                     o_error         => o_error)
            THEN
                RAISE g_exception;
            END IF;
            l_flg_technical := pk_prog_notes_constants.g_admission_dt_filter;
        END IF;
        IF (l_calc_last_date = 1)
        THEN
            g_error := 'CALL pk_prog_notes_utils.get_last_note_date. i_id_pn_note_type: ' || i_id_pn_note_type ||
                       ' i_id_episode: ' || i_id_episode;
            IF NOT pk_prog_notes_utils.get_last_note_date(i_lang            => i_lang,
                                                          i_prof            => i_prof,
                                                          i_id_episode      => i_id_episode,
                                                          i_id_pn_note_type => i_id_pn_note_type,
                                                          io_id_epis_pn     => l_id_epis_pn,
                                                          o_note_date       => o_note_date,
                                                          o_pn_date         => l_pn_date,
                                                          o_error           => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
            IF (l_flg_technical = pk_prog_notes_constants.g_date_filter)
            THEN
                o_note_date := nvl(l_pn_date, current_timestamp);
            END IF;
        
            IF ((l_flg_technical = pk_prog_notes_constants.g_event_date_o_filter) OR
               (l_flg_technical = pk_prog_notes_constants.g_event_date_b_filter))
            THEN
                IF i_id_epis_pn IS NOT NULL
                THEN
                    o_note_date := l_pn_date;
                ELSE
                    o_note_date := nvl(i_dt_proposed, current_timestamp);
                END IF;
            END IF;
        END IF;
    
        IF nvl(i_days_available_period, 0) != 0
        THEN
            IF (l_calc_date_period = 1)
            THEN
                l_begin_date := pk_date_utils.add_to_ltstz(i_timestamp => o_note_date,
                                                           i_amount    => -i_days_available_period);
                IF (l_flg_technical = pk_prog_notes_constants.g_admission_date_filter)
                THEN
                    l_end_date := pk_date_utils.trunc_insttimezone(i_prof, o_note_date) + numtodsinterval(1, 'DAY');
                ELSE
                    l_end_date := o_note_date;
                END IF;
            ELSE
                l_begin_date := pk_date_utils.add_days_to_tstz(current_timestamp, -i_days_available_period);
                l_end_date   := current_timestamp;
            END IF;
        
        ELSE
            IF (l_calc_date_period = 1)
            THEN
                IF (l_flg_technical = pk_prog_notes_constants.g_admission_date_filter)
                THEN
                    l_begin_date := o_note_date;
                    l_end_date   := (pk_date_utils.trunc_insttimezone(i_prof, o_note_date) + numtodsinterval(1, 'DAY'));
                ELSIF (l_flg_technical = pk_prog_notes_constants.g_event_date_o_filter)
                THEN
                    l_begin_date := pk_date_utils.trunc_insttimezone(i_prof, o_note_date);
                    l_end_date   := pk_date_utils.trunc_insttimezone(i_prof, o_note_date) + numtodsinterval(1, 'DAY');
                
                ELSIF (l_flg_technical = pk_prog_notes_constants.g_admission_dt_filter)
                THEN
                    l_begin_date := o_note_date;
                    l_end_date   := current_timestamp;
                ELSE
                    l_begin_date := NULL;
                    l_end_date   := o_note_date;
                END IF;
            END IF;
        
        END IF;
    
        o_begin_date := l_begin_date;
        o_end_date   := l_end_date;
    
        g_error := 'o_begin_date: ' || o_begin_date || ', o_end_date: ' || o_end_date || ', i_days_available_period: ' ||
                   i_days_available_period || ', l_pn_date: ' || l_pn_date || ', o_note_date: ' || o_note_date ||
                   ', i_flg_filter: ' || i_flg_filter || ', i_id_episode: ' || i_id_episode || ', i_id_pn_note_type: ' ||
                   i_id_pn_note_type || ', l_flg_technical: ' || l_flg_technical || ', i_dt_proposed: ' ||
                   i_dt_proposed || ', i_id_episode: ' || i_id_episode;
        pk_alertlog.log_info(text            => g_error,
                             object_name     => g_package,
                             sub_object_name => l_func_name,
                             owner           => g_owner);
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END check_date_filter_base;

    /**************************************************************************
     * Returns the datablock flg_description and description_condition
     *
     * @param i_lang                  language identifier
     * @param i_prof                  logged professional structure
     * @param i_id_note_type          note type id
     * @param i_id_sblock             soap block id
     * @param i_id_dblock             data block id
     * @param i_id_task               task id
     * @param o_flg_description       flg_description
     * @param o_description_condition description_conditionn
     * @param o_error                 error
     *
     * @return               false if errors occur, true otherwise
     *
     * @author               Amanda Lee
     * @version              2.7.3.3
     * @since                2018-05-02
    **************************************************************************/
    FUNCTION get_data_block_desc_condition
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_note_type          IN pn_note_type.id_pn_note_type%TYPE,
        i_id_sblock             IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_dblock             IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task               IN tl_task.id_tl_task%TYPE,
        o_flg_description       OUT pn_dblock_ttp_mkt.flg_description%TYPE,
        o_description_condition OUT pn_dblock_ttp_mkt.description_condition%TYPE,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_NOTE_DESCRIPTION_CONDITION';
        l_market market.id_market%TYPE;
    BEGIN
        g_error  := 'GET ID_MARKET';
        l_market := pk_core.get_inst_mkt(i_id_institution => i_prof.institution);
    
        SELECT flg_description, description_condition
          INTO o_flg_description, o_description_condition
          FROM (SELECT pdtm.flg_description,
                       pdtm.description_condition,
                       row_number() over(ORDER BY decode(pdtm.id_software, i_prof.software, 1, 2), decode(pdtm.id_market, l_market, 1, 2)) line_number
                  FROM pn_dblock_ttp_mkt pdtm
                 WHERE pdtm.id_pn_note_type = i_id_note_type
                   AND pdtm.id_pn_soap_block = i_id_sblock
                   AND pdtm.id_pn_data_block = i_id_dblock
                   AND pdtm.id_task_type = i_id_task
                   AND pdtm.id_market IN (l_market, 0)
                   AND pdtm.id_software IN (i_prof.software, 0))
         WHERE line_number = 1;
    
        RETURN TRUE;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              o_error);
            RETURN FALSE;
    END get_data_block_desc_condition;

    /**
    * GET Task date from task_timeline_ea by market
    *
    * @param i_lang           Language identifier
    * @param i_prof           Logged professional structure
    * @param i_id_episode     Episode id
    * @param i_id_task        Task id
    * @param i_id_tl_task     Task type id
    * @param i_dt_task_str    Task date configuration string
    *
    * @return                 Task date
    *
    * @raises                 PL/SQL generic error "OTHERS"
    *
    * @author               Lillian Lu
    * @version              2.7.3.5
    * @since                2018-06-04
    */
    FUNCTION get_pn_dt_task
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_episode  IN episode.id_episode%TYPE,
        i_id_task     IN v_pn_tasks.id_task%TYPE,
        i_id_tl_task  IN tl_task.id_tl_task%TYPE,
        i_dt_task_str IN VARCHAR2
    ) RETURN v_pn_tasks.dt_task%TYPE IS
        l_func_name CONSTANT VARCHAR2(30 CHAR) := 'GET_PN_DT_TASK';
        l_error t_error_out;
    
        l_dt_task     v_pn_tasks.dt_task%TYPE;
        l_sql_aux     VARCHAR2(1000 CHAR);
        l_sql_dt_task VARCHAR2(200 CHAR);
        k_mark        VARCHAR(200 CHAR) := '#DT_TASK2';
    
        FUNCTION get_valid_dt_task_str(i_dt_task_str IN VARCHAR2) RETURN VARCHAR2 IS
            l_ret      VARCHAR2(200 CHAR);
            l_tbl_date table_varchar;
            l_count    NUMBER(3);
            k_owner    VARCHAR2(10 CHAR) := 'ALERT';
            k_table    VARCHAR2(20 CHAR) := 'V_PN_TASKS';
        BEGIN
            l_tbl_date := pk_string_utils.str_split(i_list => i_dt_task_str, i_delim => pk_prog_notes_constants.g_sep);
            FOR i IN 1 .. l_tbl_date.count
            LOOP
                SELECT COUNT(*)
                  INTO l_count
                  FROM dba_tab_columns x
                 WHERE x.owner = k_owner
                   AND x.table_name = k_table
                   AND column_name = l_tbl_date(i);
                IF l_count > 0
                THEN
                    IF l_ret IS NULL
                    THEN
                        l_ret := l_tbl_date(i);
                    ELSE
                        l_ret := l_ret || pk_prog_notes_constants.g_comma || l_tbl_date(i);
                    END IF;
                END IF;
            END LOOP;
            RETURN l_ret;
        END get_valid_dt_task_str;
    BEGIN
    
        l_sql_aux := 'SELECT ' || k_mark ||
                     ' FROM v_pn_tasks WHERE id_episode = :1 AND id_tl_task = :2 AND id_task = :3';
    
        IF i_dt_task_str IS NOT NULL
        THEN
            l_sql_dt_task := get_valid_dt_task_str(upper(i_dt_task_str));
            IF instr(l_sql_dt_task, pk_prog_notes_constants.g_comma) > 0
            THEN
                l_sql_dt_task := 'coalesce(' || l_sql_dt_task || ')';
            END IF;
        ELSE
            l_sql_dt_task := 'DT_TASK';
        END IF;
    
        l_sql_aux := REPLACE(srcstr => l_sql_aux, oldsub => k_mark, newsub => l_sql_dt_task);
    
        EXECUTE IMMEDIATE l_sql_aux
            INTO l_dt_task
            USING i_id_episode, i_id_tl_task, i_id_task;
    
        RETURN l_dt_task;
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              g_owner,
                                              g_package,
                                              l_func_name,
                                              l_error);
            RETURN NULL;
    END get_pn_dt_task;

    FUNCTION ins_prof_access_exception
    (
        i_id_prof_access_exception IN table_number,
        i_id_institution           IN table_number,
        i_id_profile_template      IN profile_template.id_profile_template%TYPE
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        IF i_id_prof_access_exception.count = i_id_institution.count
        THEN
            <<lup_thru_regs>>
            FOR i IN 1 .. i_id_prof_access_exception.count
            LOOP
                BEGIN
                    INSERT INTO profile_templ_access_exception
                        (id_prof_templ_access_exception,
                         id_profile_template,
                         flg_type,
                         id_institution,
                         rank,
                         id_sys_button_prop,
                         flg_create,
                         flg_cancel,
                         flg_search,
                         flg_print,
                         flg_ok,
                         flg_detail,
                         flg_content,
                         flg_help,
                         id_sys_shortcut,
                         id_software,
                         id_shortcut_pk,
                         id_software_context,
                         -- flg_graph,
                         -- flg_vision,
                         -- flg_digital,
                         flg_freq,
                         flg_no,
                         position,
                         toolbar_level,
                         flg_action,
                         flg_view)
                    VALUES
                        (i_id_prof_access_exception(i),
                         i_id_profile_template,
                         'R',
                         i_id_institution(i),
                         NULL,
                         22262085,
                         'A',
                         'A',
                         'A',
                         'A',
                         'A',
                         'A',
                         'A',
                         'A',
                         NULL,
                         1,
                         NULL,
                         NULL,
                         -- 'N',
                         --'A',
                         --'N',
                         'N',
                         'N',
                         NULL,
                         NULL,
                         'I',
                         'N');
                EXCEPTION
                    WHEN OTHERS THEN
                        dbms_output.put_line(SQLERRM || ' - i_id_prof_access_exception: ' ||
                                             i_id_prof_access_exception(i));
                END;
            END LOOP lup_thru_regs;
            RETURN TRUE;
        
        ELSE
            dbms_output.put_line('Different array sizes.');
            RETURN FALSE;
        END IF;
    
    END ins_prof_access_exception;

    FUNCTION has_arabic_fields(i_note_ids IN table_number) RETURN VARCHAR2 IS
    
        l_arabic_field table_clob;
        l_ret          VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
    BEGIN
        IF i_note_ids.exists(1)
        THEN
        
            SELECT e.pn_note
              BULK COLLECT
              INTO l_arabic_field
              FROM epis_pn_det e
             WHERE e.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_free_text
               AND e.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND e.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                     column_value
                                      FROM TABLE(i_note_ids) t)
             ORDER BY e.create_time DESC;
        END IF;
        IF l_arabic_field.count > 0
        THEN
            l_ret := pk_alert_constant.g_yes;
        END IF;
        RETURN l_ret;
    END has_arabic_fields;

    FUNCTION has_arabic_note
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_area      IN VARCHAR2,
        i_flg_scope IN VARCHAR2 DEFAULT pk_prog_notes_constants.g_flg_scope_e
    ) RETURN VARCHAR2 IS
        l_ret          VARCHAR2(1 CHAR) := pk_alert_constant.g_no;
        l_ids          table_number;
        l_notes_id     table_number;
        l_num          NUMBER;
        l_arabic_field table_clob;
        l_id_patient   patient.id_patient%TYPE;
    BEGIN
        l_id_patient := pk_episode.get_id_patient(i_episode => i_episode);
    
        SELECT e.id_epis_pn
          BULK COLLECT
          INTO l_ids
          FROM epis_pn e
          JOIN pn_area a
            ON e.id_pn_area = a.id_pn_area
          JOIN episode epi
            ON epi.id_episode = e.id_episode
         WHERE (e.id_episode = i_episode OR i_flg_scope = pk_prog_notes_constants.g_flg_scope_p)
           AND epi.id_patient = l_id_patient
           AND e.flg_status != pk_alert_constant.g_cancelled
           AND a.internal_name = i_area
           AND e.id_pn_note_type IN (pk_prog_notes_constants.g_note_type_arabic_ft,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_sw,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_vn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_ia,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_cdc_pn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_rc_pn,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_rc_vn);
        IF l_ids.count > 0
        THEN
            l_ret := has_arabic_fields(i_note_ids => l_ids);
        
        END IF;
    
        RETURN l_ret;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN pk_alert_constant.g_no;
        
    END has_arabic_note;

    PROCEDURE get_arabic_fields
    (
        i_note_ids     IN table_number,
        o_arabic_field OUT table_clob
    ) IS
    
        l_arabic_field table_clob;
    
    BEGIN
        IF i_note_ids.exists(1)
        THEN
            SELECT e.pn_note
              BULK COLLECT
              INTO l_arabic_field
              FROM epis_pn_det e
             WHERE e.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_free_text
               AND e.flg_status IN
                   (pk_prog_notes_constants.g_epis_pn_det_flg_status_a, pk_prog_notes_constants.g_epis_pn_det_sug_add_s)
               AND e.id_epis_pn IN (SELECT /*+ OPT_ESTIMATE (TABLE t ROWS=1)*/
                                     column_value
                                      FROM TABLE(i_note_ids) t)
             ORDER BY e.create_time DESC;
        END IF;
        o_arabic_field := l_arabic_field;
    END get_arabic_fields;

    PROCEDURE get_arabic_row_ids
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_values  IN table_clob,
        o_row_ids OUT table_number
    ) IS
    
        l_row_ids table_number := table_number();
        l_msg     VARCHAR2(4000 CHAR) := pk_message.get_message(i_lang => i_lang, i_code_mess => 'ARABIC_FT_MSG_01');
    BEGIN
    
        /*SELECT tt.row_id
        BULK COLLECT
        INTO l_row_ids
        FROM (SELECT ROWID row_id
                FROM TABLE(i_values) t
               WHERE substr(column_value, 0) = l_msg) tt;*/
        IF i_values.exists(1)
        THEN
            FOR i IN 1 .. i_values.count
            LOOP
            
                IF upper(i_values(i)) LIKE upper('%' || l_msg || '%')
                THEN
                    l_row_ids.extend;
                    l_row_ids(l_row_ids.last) := i;
                END IF;
            END LOOP;
        END IF;
        o_row_ids := l_row_ids;
    END get_arabic_row_ids;

    PROCEDURE get_arabic_fields_one_cursor
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_note_ids        IN table_number,
        i_flg_report_type IN VARCHAR2 DEFAULT NULL,
        io_values         IN OUT table_clob
    ) IS
        l_distinct_note_ids table_number;
        l_row_ids           table_number;
    BEGIN
    
        get_arabic_row_ids(i_lang, i_prof, io_values, l_row_ids);
    
        SELECT DISTINCT (e.id_epis_pn)
          BULK COLLECT
          INTO l_distinct_note_ids
          FROM epis_pn e
         WHERE e.id_epis_pn IN (SELECT column_value
                                  FROM TABLE(i_note_ids))
           AND e.id_pn_note_type IN (pk_prog_notes_constants.g_note_type_arabic_ft,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_psy,
                                     pk_prog_notes_constants.g_note_type_arabic_ft_sw);
    
        IF l_distinct_note_ids.exists(1)
        THEN
            IF (i_flg_report_type IS NULL OR i_flg_report_type = pk_prog_notes_constants.g_report_complete_c)
            THEN
                FOR i IN 1 .. l_distinct_note_ids.count
                LOOP
                    BEGIN
                        SELECT e.pn_note
                          INTO io_values(l_row_ids(i))
                          FROM epis_pn_det e
                         WHERE e.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_free_text
                           AND e.id_epis_pn = l_distinct_note_ids(i);
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END LOOP;
            ELSE
                FOR i IN 1 .. l_distinct_note_ids.count
                LOOP
                    BEGIN
                        SELECT eh.pn_note
                          INTO io_values(l_row_ids(i))
                          FROM epis_pn_det e
                          JOIN epis_pn_det_hist eh
                            ON (e.id_epis_pn = eh.id_epis_pn AND e.id_pn_data_block = eh.id_pn_data_block)
                         WHERE e.id_pn_data_block = pk_prog_notes_constants.g_dblock_arabic_free_text
                           AND e.id_epis_pn = l_distinct_note_ids(i)
                           AND rownum = 1
                         ORDER BY eh.dt_pn ASC;
                    EXCEPTION
                        WHEN no_data_found THEN
                            NULL;
                    END;
                END LOOP;
            END IF;
        END IF;
    END get_arabic_fields_one_cursor;

    FUNCTION get_note_by_area
    (
        i_lang IN language.id_language%TYPE,
        i_prof IN profissional,
        i_area IN pn_area.internal_name%TYPE
    ) RETURN table_number IS
        l_note    table_number;
        l_market  NUMBER;
        l_id_area table_number;
    BEGIN
    
        SELECT p.id_pn_area
          BULK COLLECT
          INTO l_id_area
          FROM pn_area p
         WHERE p.internal_name = i_area;
    
        SELECT n.id_pn_note_type
          BULK COLLECT
          INTO l_note
          FROM pn_note_type_soft_inst n
         WHERE n.id_institution = i_prof.institution
           AND n.id_pn_area IN (SELECT column_value
                                  FROM TABLE(l_id_area))
           AND n.id_software = i_prof.software;
    
        IF NOT (l_note.exists(1))
        THEN
        
            SELECT n.id_pn_note_type
              BULK COLLECT
              INTO l_note
              FROM pn_note_type_soft_inst n
             WHERE n.id_institution = i_prof.institution
               AND n.id_pn_area IN (SELECT column_value
                                      FROM TABLE(l_id_area))
               AND n.id_software = -1;
        
        END IF;
    
        IF NOT (l_note.exists(1))
        THEN
        
            l_market := pk_prof_utils.get_prof_market(i_prof => i_prof);
        
            SELECT n.id_pn_note_type
              BULK COLLECT
              INTO l_note
              FROM pn_note_type_mkt n
             WHERE n.id_market IN l_market
               AND n.id_pn_area IN (SELECT column_value
                                      FROM TABLE(l_id_area))
               AND n.id_software IN i_prof.software;
        
        END IF;
    
        IF NOT (l_note.exists(1))
        THEN
            SELECT n.id_pn_note_type
              BULK COLLECT
              INTO l_note
              FROM pn_note_type_mkt n
             WHERE n.id_market IN (l_market, 0)
               AND n.id_pn_area IN (SELECT column_value
                                      FROM TABLE(l_id_area))
               AND n.id_software IN (i_prof.software, 0);
        
        END IF;
    
        RETURN l_note;
    END get_note_by_area;

    FUNCTION get_note_type_by_area
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_area       IN pn_area.internal_name%TYPE DEFAULT NULL,
        i_id_episode IN episode.id_episode%TYPE
    ) RETURN t_tbl_note_type_area IS
    
        l_tbl_note_type_area t_tbl_note_type_area;
    
    BEGIN
    
        SELECT t_rec_note_type_area(id_pn_note_type, note_desc, id_pn_area, dt_event)
          BULK COLLECT
          INTO l_tbl_note_type_area
          FROM (SELECT ep.id_pn_note_type,
                       ep.id_pn_area,
                       pk_message.get_message(i_lang => i_lang, i_prof => i_prof, i_code_mess => n.code_pn_note_type) note_desc,
                       ep.dt_create dt_event,
                       row_number() over(PARTITION BY ep.id_pn_area, ep.id_pn_note_type ORDER BY ep.dt_create) rn
                  FROM epis_pn ep
                  JOIN pn_note_type n
                    ON ep.id_pn_note_type = n.id_pn_note_type
                 WHERE ep.id_episode = i_id_episode
                   AND ep.id_pn_area IN
                       (SELECT a.id_pn_area
                          FROM pn_area a
                         WHERE a.internal_name = i_area
                           AND i_area IS NOT NULL
                        UNION
                        SELECT a.id_pn_area
                          FROM pn_area a
                         WHERE a.internal_name IN (pk_prog_notes_constants.g_area_pn,
                                                   pk_prog_notes_constants.g_area_dpn,
                                                   pk_prog_notes_constants.g_area_phan,
                                                   pk_prog_notes_constants.g_area_rpn,
                                                   pk_prog_notes_constants.g_area_psypn,
                                                   pk_prog_notes_constants.g_area_cdcpn,
                                                   pk_prog_notes_constants.g_area_rehabpn,
                                                   pk_prog_notes_constants.g_area_mtpn,
                                                   pk_prog_notes_constants.g_area_rcpn,
                                                   pk_prog_notes_constants.g_area_swpn)
                           AND i_area IS NULL)
                   AND ((ep.id_software IN i_prof.software AND i_area IS NOT NULL) OR i_area IS NULL)
                   AND flg_status NOT IN (pk_prog_notes_constants.g_epis_pn_flg_status_c)) t
         WHERE t.rn = 1;
    
        RETURN l_tbl_note_type_area;
    END get_note_type_by_area;

    FUNCTION get_dblock_description
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_desc_function IN pn_dblock_mkt.desc_function%TYPE,
        i_id_episode    IN episode.id_episode%TYPE
    ) RETURN VARCHAR2 IS
        l_description VARCHAR2(200 CHAR);
        l_duration    NUMBER;
    BEGIN
        CASE i_desc_function
            WHEN 'EVOLUTION_DAYS' THEN
                l_duration := pk_edis_proc.get_los_duration_number(i_lang       => i_lang,
                                                                   i_prof       => i_prof,
                                                                   i_id_episode => i_id_episode);
            
                l_description := pk_message.get_message(i_lang      => i_lang,
                                                        i_prof      => i_prof,
                                                        i_code_mess => 'PROGRESS_NOTES_T153');
                l_description := REPLACE(l_description, '@1', trunc(l_duration));
        END CASE;
    
        RETURN l_description;
    EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
    END get_dblock_description;
BEGIN
    -- Initialization

    /* CAN'T TOUCH THIS */
    /* Who am I */
    pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    pk_alertlog.log_init(object_name => g_package);
END pk_prog_notes_utils;
/
