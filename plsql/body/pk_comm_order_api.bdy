/*-- Last Change Revision: $Rev: 2026887 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:40:18 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE BODY pk_comm_order_api IS

    /* CAN'T TOUCH THIS */
    g_error   VARCHAR2(1000 CHAR);
    g_owner   VARCHAR2(30 CHAR);
    g_package VARCHAR2(30 CHAR);
    g_exception EXCEPTION;

    FUNCTION get_diagnosis_struct
    (
        i_id_episode      IN nurse_tea_req.id_episode%TYPE,
        i_alert_diagnosis IN alert_diagnosis.id_alert_diagnosis%TYPE,
        o_diag_struct     OUT CLOB
    ) RETURN BOOLEAN IS
    
        l_id_patient   patient.id_patient%TYPE;
        l_id_diagnosis alert_diagnosis.id_diagnosis%TYPE;
    
    BEGIN
    
        SELECT e.id_patient
          INTO l_id_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        SELECT ad.id_diagnosis
          INTO l_id_diagnosis
          FROM alert_diagnosis ad
         WHERE ad.id_alert_diagnosis = i_alert_diagnosis;
    
        o_diag_struct := '<EPIS_DIAGNOSES ID_PATIENT="' || l_id_patient || '" ID_EPISODE="' || i_id_episode ||
                         '" PROF_CAT_TYPE="D" FLG_TYPE="P" FLG_EDIT_MODE="" ID_CDR_CALL="">
                            <EPIS_DIAGNOSIS ID_EPIS_DIAGNOSIS="" ID_EPIS_DIAGNOSIS_HIST="" FLG_TRANSF_FINAL="">
                              <CANCEL_REASON ID_CANCEL_REASON="" FLG_CANCEL_DIFF_DIAG="" />
                              <DIAGNOSIS ID_DIAGNOSIS="' || l_id_diagnosis ||
                         '" ID_ALERT_DIAG="' || i_alert_diagnosis || '">
                                <DESC_DIAGNOSIS>undefined</DESC_DIAGNOSIS>
                                <DIAGNOSIS_WARNING_REPORT>Diagnosis with no form fields.</DIAGNOSIS_WARNING_REPORT>
                              </DIAGNOSIS>
                            </EPIS_DIAGNOSIS>
                            <GENERAL_NOTES ID="" ID_CANCEL_REASON="" />
                          </EPIS_DIAGNOSES>';
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            RETURN FALSE;
        
    END get_diagnosis_struct;

    /**
    * Creates an ongoing communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order              Array of communication order identifiers
    * @param   i_id_comm_order_type         Array of communication orders types identifiers
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)   
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_diagnosis                  Array of clinical indication information (diagnosis)
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   i_dt_begin_str               Array of start dates. Format YYYYMMDDhh24miss
    * @param   i_dt_order_str               Array of order dates. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Array of order professional identifiers
    * @param   i_id_order_type              Array of request order types (telephone, verbal, ...)
    * @param   o_id_comm_order_req          Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Diogo Oliveira
    * @since   23-10-2017
    */

    FUNCTION create_communication_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_comm_order        IN table_number,
        i_id_comm_order_type   IN table_number,
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_diagnosis            IN table_number,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        i_dt_begin_str         IN table_varchar,
        i_dt_order_str         IN table_varchar,
        i_id_prof_order        IN table_number,
        i_id_order_type        IN table_number,
        o_id_comm_order_req    OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis             table_clob := table_clob();
        l_patient               patient.id_patient%TYPE;
        l_clinical_purpose_desc table_clob := table_clob();
    
        l_task_list         pk_types.cursor_type;
        l_flg_warning_type  VARCHAR2(1);
        l_msg_title         VARCHAR2(1000);
        l_msg_body          VARCHAR2(1000);
        l_proc_start        VARCHAR2(1000);
        l_proc_end          VARCHAR2(1000);
        l_proc_refresh      VARCHAR2(1000);
        l_proc_next_start   VARCHAR2(1000);
        l_proc_next_end     VARCHAR2(1000);
        l_proc_next_refresh VARCHAR2(1000);
    
        l_cpoe_process cpoe_process.id_cpoe_process%TYPE;
        l_dummy_n      table_number := table_number();
    
    BEGIN
        l_dummy_n.extend(i_id_comm_order.count);
        FOR i IN i_id_comm_order.first .. i_id_comm_order.last
        LOOP
            --CHECK IF CPOE IS VALID
            IF NOT pk_cpoe.check_tasks_creation(i_lang              => i_lang,
                                                i_prof              => i_prof,
                                                i_episode           => i_id_episode,
                                                i_task_type         => table_number(46),
                                                i_dt_start          => table_varchar(i_dt_begin_str(i)),
                                                i_dt_end            => table_varchar(NULL),
                                                i_task_id           => table_varchar(i_id_comm_order(i)),
                                                i_tab_type          => NULL,
                                                o_task_list         => l_task_list,
                                                o_flg_warning_type  => l_flg_warning_type,
                                                o_msg_title         => l_msg_title,
                                                o_msg_body          => l_msg_body,
                                                o_proc_start        => l_proc_start,
                                                o_proc_end          => l_proc_end,
                                                o_proc_refresh      => l_proc_refresh,
                                                o_proc_next_start   => l_proc_next_start,
                                                o_proc_next_end     => l_proc_next_end,
                                                o_proc_next_refresh => l_proc_next_refresh,
                                                o_error             => o_error)
            THEN
                g_error := 'error found while calling pk_cpoe.check_tasks_creation function';
                RAISE g_exception;
            END IF;
        
            dbms_output.put_line(l_msg_title);
            dbms_output.put_line(l_msg_body);
        
            --CREATE CPOE PROCESS IF NEEDED  
            IF l_flg_warning_type = pk_cpoe.g_flg_warning_new_cpoe
            THEN
            
                IF NOT pk_cpoe.create_cpoe(i_lang              => i_lang,
                                           i_prof              => i_prof,
                                           i_episode           => i_id_episode,
                                           i_proc_start        => l_proc_start,
                                           i_proc_end          => l_proc_end,
                                           i_proc_next_start   => l_proc_next_start,
                                           i_proc_next_end     => l_proc_next_end,
                                           i_proc_next_refresh => l_proc_next_refresh,
                                           i_proc_type         => 'P',
                                           i_proc_refresh      => l_proc_refresh,
                                           o_cpoe_process      => l_cpoe_process,
                                           o_error             => o_error)
                THEN
                    g_error := 'error found while calling pk_cpoe.create_cpoe function';
                    RAISE g_exception;
                END IF;
            
            END IF;
        
            --CREATE DIAGNOSIS SCTRUCTURE
            l_diagnosis.extend;
            IF NOT get_diagnosis_struct(i_id_episode, i_diagnosis(i), l_diagnosis(i))
            THEN
                l_diagnosis(i) := NULL;
            END IF;
        
            --CREATE l_clinical_purpose_desc ARRAY
            l_clinical_purpose_desc.extend();
            l_clinical_purpose_desc(i) := NULL;
        
        END LOOP;
    
        SELECT e.id_patient
          INTO l_patient
          FROM episode e
         WHERE e.id_episode = i_id_episode;
    
        g_error := 'Error calling pk_comm_orders.create_comm_order_req_ong.';
        IF NOT pk_comm_orders.create_comm_order_req_ong(i_lang                    => i_lang,
                                                        i_prof                    => i_prof,
                                                        i_id_patient              => l_patient,
                                                        i_id_episode              => i_id_episode,
                                                        i_id_comm_order           => i_id_comm_order,
                                                        i_id_comm_order_type      => i_id_comm_order_type,
                                                        i_flg_free_text           => i_flg_free_text,
                                                        i_desc_comm_order         => i_desc_comm_order,
                                                        i_notes                   => i_notes,
                                                        i_clinical_indication     => l_diagnosis,
                                                        i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                                        i_clinical_purpose_desc   => table_varchar('Routine', NULL),
                                                        i_flg_priority            => i_flg_priority,
                                                        i_flg_prn                 => i_flg_prn,
                                                        i_prn_condition           => i_prn_condition,
                                                        i_dt_begin_str            => i_dt_begin_str,
                                                        i_dt_order_str            => i_dt_order_str,
                                                        i_id_prof_order           => i_id_prof_order,
                                                        i_id_order_type           => i_id_order_type,
                                                        i_task_duration           => l_dummy_n,
                                                        i_order_recurr            => l_dummy_n,
                                                        i_clinical_question       => NULL,
                                                        i_response                => NULL,
                                                        i_clinical_question_notes => NULL,
                                                        i_task_type               => NULL,
                                                        o_id_comm_order_req       => o_id_comm_order_req,
                                                        o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_comm_order_api',
                                              'create_communication_order',
                                              o_error);
        
            RETURN FALSE;
        
    END create_communication_order;

    /**
    * Updates a communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)  
    * @param   i_id_comm_order_req          Array of communication order request
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)   
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_diagnosis                  Array of clinical indication information (diagnosis)
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   i_dt_order_str               Array of order dates. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Array of order professional identifiers
    * @param   i_id_order_type              Array of request order types (telephone, verbal, ...)
    * @param   o_error                      Error information
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Diogo Oliveira
    * @since   23-10-2017
    */

    FUNCTION edit_communication_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_comm_order_req    IN table_number,
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_diagnosis            IN table_number,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        i_dt_order_str         IN table_varchar,
        i_id_prof_order        IN table_number,
        i_id_order_type        IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_diagnosis             table_clob := table_clob();
        l_clinical_purpose_desc table_varchar := table_varchar();
        l_id_episode            episode.id_episode%TYPE;
        l_dt_begin_str          table_varchar := table_varchar();
    
    BEGIN
    
        FOR i IN i_id_comm_order_req.first .. i_id_comm_order_req.last
        LOOP
            l_clinical_purpose_desc.extend();
            l_clinical_purpose_desc(i) := NULL;
        
            SELECT cor.id_episode
              INTO l_id_episode
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req(i);
        
            l_diagnosis.extend;
            IF NOT get_diagnosis_struct(l_id_episode, i_diagnosis(i), l_diagnosis(i))
            THEN
                l_diagnosis(i) := NULL;
            END IF;
        
            l_dt_begin_str.extend();
            l_dt_begin_str(i) := NULL;
        
        END LOOP;
    
        g_error := 'Error calling pk_comm_orders.update_comm_order_req.';
        IF NOT pk_comm_orders.update_comm_order_req(i_lang                    => i_lang,
                                                    i_prof                    => i_prof,
                                                    i_id_comm_order_req       => i_id_comm_order_req,
                                                    i_flg_free_text           => i_flg_free_text,
                                                    i_desc_comm_order         => i_desc_comm_order,
                                                    i_notes                   => i_notes,
                                                    i_clinical_indication     => l_diagnosis,
                                                    i_flg_clinical_purpose    => i_flg_clinical_purpose,
                                                    i_clinical_purpose_desc   => l_clinical_purpose_desc,
                                                    i_flg_priority            => i_flg_priority,
                                                    i_flg_prn                 => i_flg_prn,
                                                    i_prn_condition           => i_prn_condition,
                                                    i_dt_begin_str            => l_dt_begin_str,
                                                    i_dt_order_str            => i_dt_order_str,
                                                    i_id_prof_order           => i_id_prof_order,
                                                    i_id_order_type           => i_id_order_type,
                                                    i_task_duration           => table_number(NULL),
                                                    i_order_recurr            => table_number(NULL),
                                                    i_clinical_question       => table_table_number(NULL),
                                                    i_response                => table_table_varchar(NULL),
                                                    i_clinical_question_notes => table_table_varchar(NULL),
                                                    o_error                   => o_error)
        THEN
            RAISE g_exception;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_comm_order_api',
                                              'edit_communication_order',
                                              o_error);
        
            RETURN FALSE;
        
    END edit_communication_order;

    /**
    * This function ables the user to cancel communication orders according to CCH specifications.
    *
    * @param IN  i_lang               Language ID
    * @param IN  i_prof               Professional structure
    * @param IN  i_id_comm_order_req  ARRAY of communication order requests
    * @param IN  i_id_cancel_reason   ARRAY of cancel reasons
    * @param IN  i_cancel_notes       ARRAY of cancel notes  
    * @param OUT o_error              Error structure
    *
    * @return   BOOLEAN
    * 
    * @version  2.7.1.5
    * @since    2017/10/23
    * @author   Diogo Oliveira
    */

    FUNCTION cancel_communication_order
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_comm_order_req IN table_number,
        i_id_cancel_reason  IN table_number,
        i_cancel_notes      IN table_clob,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN IS
    
        l_id_episode episode.id_episode%TYPE;
    
    BEGIN
    
        g_error := 'Cancel communication order';
    
        FOR i IN i_id_comm_order_req.first .. i_id_comm_order_req.last
        LOOP
            SELECT cor.id_episode
              INTO l_id_episode
              FROM comm_order_req cor
             WHERE cor.id_comm_order_req = i_id_comm_order_req(i);
        
            IF NOT pk_comm_orders.set_action_cancel_discontinue(i_lang              => i_lang,
                                                                i_prof              => i_prof,
                                                                i_id_comm_order_req => table_number(i_id_comm_order_req(i)),
                                                                i_id_episode        => l_id_episode,
                                                                i_id_reason         => i_id_cancel_reason(i),
                                                                i_notes             => i_cancel_notes(i),
                                                                i_dt_order          => pk_date_utils.get_string_tstz(i_lang,
                                                                                                                     i_prof,
                                                                                                                     NULL,
                                                                                                                     NULL),
                                                                i_id_prof_order     => NULL,
                                                                i_id_order_type     => NULL,
                                                                o_error             => o_error)
            THEN
                RAISE g_exception;
            END IF;
        
        END LOOP;
    
        RETURN TRUE;
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_comm_order_api',
                                              'cancel_communication_order',
                                              o_error);
        
            RETURN FALSE;
    END cancel_communication_order;

    /**
    * CREATES or UPDATES an ongoing communication order request
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_episode                 Episode identifier
    * @param   i_id_comm_order_req          Array of communication order requests (Transactional values. Only to be used when editing records.)    
    * @param   i_id_comm_order              Array of communication order identifiers (Cannot be edited, therefore the parameter may be sent as null when editing.)
    * @param   i_id_comm_order_type         Array of communication orders types identifiers (Cannot be edited, therefore the parameter may be sent as null when editing.)
    * @param   i_flg_free_text              Array of flags indicating if this communication orders is free text
    * @param   i_desc_comm_order            Array of communication orders request description (in case of free text)   
    * @param   i_notes                      Array of communication orders request notes
    * @param   i_diagnosis                  Array of clinical indication information (alert diagnosis)
    * @param   i_flg_clinical_purpose       Array of flags that indicates the clinical purpose
    * @param   i_flg_priority               Array of flags that indicates the priority
    * @param   i_flg_prn                    Array of flags that indicates whether the communication orders is PRN or not
    * @param   i_prn_condition              Array of notes to indicate the PRN conditions
    * @param   i_dt_begin_str               Array of start dates. Format YYYYMMDDhh24miss. (Cannot be edited, therefore the parameter may be sent as null when editing.)
    * @param   i_dt_order_str               Array of order dates. Format YYYYMMDDhh24miss
    * @param   i_id_prof_order              Array of order professional identifiers
    * @param   i_id_order_type              Array of request order types (telephone, verbal, ...)
    * @param   o_id_comm_order_req          Array of communication orders request identifiers that were created or updated
    * @param   o_error                      Error information
    *
    * @value   i_flg_clinical_purpose       {*} N- None {*} P- Post-operative {*} PO- Pre-operative
    *                                       {*} R- Routine {*} C- Screening {*} S- Sudden deterioration
    *                                       {*} T- Therapy control {*} O- Other
    *
    * @value   i_flg_free_text              {*} Y- free text {*} N- otherwise
    * @value   i_flg_priority               {*} R- Routine {*} A- ASAP {*} S- STAT
    * @value   i_flg_prn                    {*} Y- is PRN {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  Diogo Oliveira
    * @since   23-10-2017
    */

    FUNCTION set_communication_order
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN nurse_tea_req.id_episode%TYPE,
        i_id_comm_order_req    IN table_number, --EXCLUSIVE FOR UPDATE    
        i_id_comm_order        IN table_number, --EXCLUSIVE FOR CREATION
        i_id_comm_order_type   IN table_number, --EXCLUSIVE FOR CREATION
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_diagnosis            IN table_number,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        i_dt_begin_str         IN table_varchar, --EXCLUSIVE FOR CREATION
        i_dt_order_str         IN table_varchar,
        i_id_prof_order        IN table_number,
        i_id_order_type        IN table_number,
        o_id_comm_order_req    OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
        IF i_id_comm_order_req(1) IS NOT NULL
        THEN
        
            IF NOT edit_communication_order(i_lang                 => i_lang,
                                            i_prof                 => i_prof,
                                            i_id_comm_order_req    => i_id_comm_order_req,
                                            i_flg_free_text        => i_flg_free_text,
                                            i_desc_comm_order      => i_desc_comm_order,
                                            i_notes                => i_notes,
                                            i_diagnosis            => i_diagnosis,
                                            i_flg_clinical_purpose => i_flg_clinical_purpose,
                                            i_flg_priority         => i_flg_priority,
                                            i_flg_prn              => i_flg_prn,
                                            i_prn_condition        => i_prn_condition,
                                            i_dt_order_str         => i_dt_order_str,
                                            i_id_prof_order        => i_id_prof_order,
                                            i_id_order_type        => i_id_order_type,
                                            o_error                => o_error)
            THEN
                g_error := 'Error calling edit_communication_order';
                RAISE g_exception;
            END IF;
        
        ELSE
            IF NOT create_communication_order(i_lang                 => i_lang,
                                              i_prof                 => i_prof,
                                              i_id_episode           => i_id_episode,
                                              i_id_comm_order        => i_id_comm_order,
                                              i_id_comm_order_type   => i_id_comm_order_type,
                                              i_flg_free_text        => i_flg_free_text,
                                              i_desc_comm_order      => i_desc_comm_order,
                                              i_notes                => i_notes,
                                              i_diagnosis            => i_diagnosis,
                                              i_flg_clinical_purpose => i_flg_clinical_purpose,
                                              i_flg_priority         => i_flg_priority,
                                              i_flg_prn              => i_flg_prn,
                                              i_prn_condition        => i_prn_condition,
                                              i_dt_begin_str         => i_dt_begin_str,
                                              i_dt_order_str         => i_dt_order_str,
                                              i_id_prof_order        => i_id_prof_order,
                                              i_id_order_type        => i_id_order_type,
                                              o_id_comm_order_req    => o_id_comm_order_req,
                                              o_error                => o_error)
            THEN
                g_error := 'Error calling create_communication_order';
                RAISE g_exception;
            END IF;
        END IF;
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN g_exception THEN
            pk_utils.undo_changes;
            pk_alert_exceptions.process_error(i_lang,
                                              SQLCODE,
                                              SQLERRM,
                                              g_error,
                                              'ALERT',
                                              'pk_comm_order_api',
                                              'set_communication_order',
                                              o_error);
        
            RETURN FALSE;
    END set_communication_order;

BEGIN

    /* CAN'T TOUCH THIS */
    /* Who am I */
    alertlog.pk_alertlog.who_am_i(owner => g_owner, name => g_package);
    /* Log init */
    alertlog.pk_alertlog.log_init(object_name => g_package);

END pk_comm_order_api;
/
