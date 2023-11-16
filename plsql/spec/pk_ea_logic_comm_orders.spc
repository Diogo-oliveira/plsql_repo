/*-- Last Change Revision: $Rev: 2028632 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:01 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_comm_orders IS

    -- Purpose : Communication orders easy access database package

    /**
    * Get the concept path based on its hierarchy
    *
    * @param i_lang                   Professional preferred language    
    * @param i_id_concept_version     Concept version ID
    * @param i_id_inst_owner          Concept version institution owner
    * @param i_id_concept_type        Concept type ID
    * @param i_id_concept_type        Task type identifier
    *
    * @return                         The concept path description
    *
    * @author                         Tiago Silva    (Updated by Humberto Cardoso)
    * @version                        2.6.4          (Updated in 2.8.0.0)        
    * @since                          29/Apr/2014    (Updated in 2019/09/02)   
    */
    FUNCTION get_concept_path_desc
    (
        i_lang               IN language.id_language%TYPE,
        i_id_concept_version IN concept_version.id_concept_version%TYPE,
        i_id_inst_owner      IN concept_version.id_inst_owner%TYPE,
        i_id_concept_type    IN concept_type.id_concept_type%TYPE,
        i_id_task_type       IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /**
    * Load concept types ids for communication orders
    *
    * @param i_ids_task_types         List of task types identifiers to filter. If null, is not filtred
    * @param i_ids_concept_types      List of concept types identifiers to filter. If null, is not filtred
    * @param o_ids_task_types         List of all task types identifiers that are compatible with the filters.
    * @param o_ids_concept_types      List of all concept types identifiers that are compatible with the filters.
    *
    * @author                         Humberto Cardoso
    * @version                        2.8.0.0
    * @since                          2019/09/02
    */
    PROCEDURE load_concept_types_task_types
    (
        i_ids_task_types    IN table_number DEFAULT NULL,
        i_ids_concept_types IN table_number DEFAULT NULL,
        o_ids_task_types    OUT NOCOPY table_number,
        o_ids_concept_types OUT NOCOPY table_number
    );

    /**
    * Procedure to populate EA table
    *
    * @param i_id_concept_version     Institution tp rebuild the EA
    * @param i_ids_softwares          List of softwares to rebuild the EA
    * @param i_ids_task_types         List of task types identifiers to filter. If null, is not filtred
    * @param i_ids_concept_types      List of concept types identifiers to filter. If null, is not filtred
    *
    * @author                         Tiago Silva   (Updated by Humberto Cardoso)
    * @version                        2.6.3         (Updated in 2.8.0.0)
    * @since                          2014/02/14    (Updated in 2019/09/02) 
    */
    PROCEDURE populate_ea
    (
        i_id_institution    IN NUMBER,
        i_ids_softwares     IN table_number,
        i_ids_task_types    IN table_number DEFAULT NULL,
        i_ids_concept_types IN table_number DEFAULT NULL
    );

    /**
    * Procedure to populate EA table for a specific term and concept type
    * Used to create communication orders by interface.
    *
    * @param i_id_institution             Institution identifier
    * @param i_id_software                Software identifier
    * @param i_id_terminology_version     Terminology version identifier
    * @param i_id_concept_term            Concept term identifier
    * @param i_id_concept_type            Concept type identifier
    *
    * @author                             Humberto Cardoso
    * @version                            2.7.x
    * @since                              
    */
    PROCEDURE populate_ea
    (
        i_id_institution         IN NUMBER,
        i_id_software            IN NUMBER,
        i_id_terminology_version IN NUMBER,
        i_id_concept_term        IN NUMBER,
        i_id_concept_type        IN NUMBER
        
    );

    /**
    * Process insert/update events on Patient education into TASK_TIMELINE_EA.
    *
    * @param   i_lang                  Professional preferred language
    * @param   i_prof                  Professional identification and its context (institution and software)
    * @param   i_event_type            Event type
    * @param   i_rowids                Changed records rowids list
    * @param   i_src_table             Source table name
    * @param   i_list_columns          Changed column names list
    * @param   i_dg_table              Easy access table name
    *
    * @author  ANA.MONTEIRO
    * @version 2.6.3
    * @since   05-03-2014
    */
    PROCEDURE set_task_timeline
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_event_type   IN VARCHAR2,
        i_rowids       IN table_varchar,
        i_src_table    IN VARCHAR2,
        i_list_columns IN table_varchar,
        i_dg_table     IN VARCHAR2
    );

    PROCEDURE get_comm_order_plan_status
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE,
        o_status_str    OUT VARCHAR2,
        o_status_msg    OUT VARCHAR2,
        o_status_icon   OUT VARCHAR2,
        o_status_flg    OUT VARCHAR2
    );

    FUNCTION get_comm_order_plan_status_flg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_comm_order_plan_stat_icon
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_comm_order_plan_status_msg
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_comm_order_plan_status_str
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_flg_status    IN comm_order_plan.flg_status%TYPE,
        i_dt_plan       IN comm_order_plan.dt_plan_tstz%TYPE,
        i_dt_take       IN comm_order_plan.dt_take_tstz%TYPE,
        i_task_duration IN comm_order_req.task_duration%TYPE,
        i_req_status    IN comm_order_req.id_comm_order_req%TYPE
    ) RETURN VARCHAR2;

    PROCEDURE set_grid_task
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE ins_grid_task
    (
        i_lang   IN language.id_language%TYPE,
        i_prof   IN profissional,
        i_rowids IN table_varchar
    );

    PROCEDURE ins_grid_task_epis
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_episode   IN grid_task.id_episode%TYPE,
        i_id_task_type IN task_type.id_task_type%TYPE
    );

    PROCEDURE get_data_rowid
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_table_name IN VARCHAR,
        i_rowids     IN table_varchar,
        o_rowids     OUT table_varchar
    );

    /********************************************************************************************/
    /********************************************************************************************/
    /********************************************************************************************/

    --generic types definition
    SUBTYPE t_huge_byte IS pk_types.t_huge_byte; --32767
    SUBTYPE t_big_byte IS pk_types.t_big_byte; --4000

    SUBTYPE t_big_char IS pk_types.t_big_char; --1000
    SUBTYPE t_med_char IS pk_types.t_med_char; --500
    SUBTYPE t_low_char IS pk_types.t_low_char; --100
    SUBTYPE t_flg_char IS pk_types.t_flg_char; --1

    SUBTYPE t_low_num IS pk_types.t_low_num; --NUMBER(06);
    SUBTYPE t_med_num IS pk_types.t_med_num; --NUMBER(12);
    SUBTYPE t_big_num IS pk_types.t_big_num; --NUMBER(24);

    -- Public constant declarations
    k_yes                CONSTANT t_low_char := 'Y';
    k_no                 CONSTANT t_low_char := 'N';
    k_pref_term_str      CONSTANT t_low_char := 'PREFERRED_TERM';
    k_category_minus_one CONSTANT t_low_num := -1;
    k_lang               CONSTANT t_low_num := 2;

END pk_ea_logic_comm_orders;
/
