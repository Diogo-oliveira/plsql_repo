/*-- Last Change Revision: $Rev: 1850754 $*/
/*-- Last Change by: $Author: ana.matos $*/
/*-- Date of last change: $Date: 2018-07-05 15:20:59 +0100 (qui, 05 jul 2018) $*/

CREATE OR REPLACE PACKAGE pk_api_patient_education IS

    /**
    * This function ables the user to add a new patient education record according to CCH specifications.
    *
    * @param IN  i_lang               Language ID
    * @param IN  i_prof               Professional structure
    * @param IN  i_id_episode         ID EPISODE
    * @param IN  i_nurse_tea_req      ARRAY of ID_NURSE_TEA_REQ (When null => New record / When not null => Edit record)
    * @param IN  i_id_nurse_topic     ARRAY of id_nurse_topic
    * @param IN  i_diagnoses          ARRAY of diagnosis (ID_ALERT_DIAGNOSIS)
    * @param IN  i_to_be_performed    ARRAY chars to identify the time of execution ('E'-Current Episode/'B'-Untill next episode/'N'-Next episode)
    * @param IN  i_start_date         ARRAY of start dates
    * @param IN  i_notes              ARRAY of notes
    * @param IN  i_description        ARRAY of descriptions for the patient education
    * @param IN  i_order_recurr_freq  ARRAY of frequencies to execute the patient education (order_recurr_option)
    * @param IN  i_occurrences        ARRAY of number of occurences
    * @param IN  i_duration           ARRAY of duration of the patient education
    * @param IN  i_unit_meas_duration ARRAY of unit measures of duration of the patient education
    * @param IN  i_end_date           ARRAY of end dates
    * @param OUT o_id_nurse_tea_req   ARRAY of transactional records created   
    * @param OUT o_id_nurse_tea_topic
    * @param OUT o_title_topic
    * @param OUT o_desc_diagnosis      
    * @param OUT o_error              Error structure
    *
    * @return   BOOLEAN
    * 
    * @version  2.7.1.5
    * @since    2017/10/18
    * @author   Diogo Oliveira
    */

    FUNCTION set_patient_education
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_episode         IN nurse_tea_req.id_episode%TYPE,
        i_nurse_tea_req      IN table_number, --transacional
        i_id_nurse_topic     IN table_number,
        i_diagnosis          IN table_number, --tratar dos diagnósticos
        i_to_be_performed    IN table_varchar,
        i_start_date         IN table_varchar,
        i_notes              IN table_varchar,
        i_description        IN table_clob,
        i_order_recurr_freq  IN table_number,
        i_occurrences        IN table_number,
        i_duration           IN table_number,
        i_unit_meas_duration IN table_number,
        i_end_date           IN table_varchar,
        o_id_nurse_tea_req   OUT table_number,
        o_id_nurse_tea_topic OUT table_number,
        o_title_topic        OUT table_varchar,
        o_desc_diagnosis     OUT table_varchar,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION cancel_patient_education
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_nurse_tea_req IN table_number,
        i_id_cancel_reason IN table_number,
        i_cancel_notes     IN table_varchar,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient education for CDA section that are active or pending: Instructions, Goals
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_pat_edu_cda           Cursor with infomation about patient education for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        CRISTINA.OLIVEIRA
    * @version                       2.6.4
    * @since                         2014/05/23 
    */
    FUNCTION get_pat_education_cda
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_type_scope  IN VARCHAR2,
        i_id_scope    IN NUMBER,
        o_pat_edu_cda OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Gets patient education for Instructions CDA section that are executed with free text
    *
    * @param i_lang                  Language ID
    * @param i_prof                  Professional ID
    * @param i_scope                 ID for scope type
    * @param i_scope_type            Scope type (E)pisode/(V)isit/(P)atient
    * @param o_pat_edu_instr         Cursor with infomation about patient education for the given scope
    * @param o_error                 Error message
    *
    * @return                        True on success, false otherwise
    *                        
    * @author                        CRISTINA.OLIVEIRA
    * @version                       2.6.4
    * @since                         2014/10/15 
    */
    FUNCTION get_pat_educa_instruct_cda
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_type_scope    IN VARCHAR2,
        i_id_scope      IN NUMBER,
        o_pat_edu_instr OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_exception EXCEPTION;
    g_error VARCHAR2(4000);

END pk_api_patient_education;
/
