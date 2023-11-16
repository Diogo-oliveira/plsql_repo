/*-- Last Change Revision: $Rev: 2028569 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:46:34 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_comm_order_api IS

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
        i_id_episode           IN nurse_tea_req.id_episode%TYPE, --EXCLUSIVE FOR CREATION
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
    ) RETURN BOOLEAN;

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
        i_id_comm_order        IN table_number, --exclusivo
        i_id_comm_order_type   IN table_number, --exclusivo
        i_flg_free_text        IN table_varchar,
        i_desc_comm_order      IN table_clob,
        i_notes                IN table_clob,
        i_diagnosis            IN table_number,
        i_flg_clinical_purpose IN table_varchar,
        i_flg_priority         IN table_varchar,
        i_flg_prn              IN table_varchar,
        i_prn_condition        IN table_clob,
        i_dt_begin_str         IN table_varchar, --exclusivo
        i_dt_order_str         IN table_varchar,
        i_id_prof_order        IN table_number,
        i_id_order_type        IN table_number,
        o_id_comm_order_req    OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

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
        i_id_comm_order_req    IN table_number, --exclusivo
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
    ) RETURN BOOLEAN;

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
    ) RETURN BOOLEAN;

END pk_comm_order_api;
/
