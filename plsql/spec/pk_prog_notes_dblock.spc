/*-- Last Change Revision: $Rev: 2028893 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:48:36 +0100 (ter, 02 ago 2022) $*/
CREATE OR REPLACE PACKAGE pk_prog_notes_dblock AS

    TYPE t_rec_problems IS RECORD(
        desc_problem_all  CLOB,
        desc_status       sys_domain.desc_val%TYPE,
        prob_notes        pat_history_diagnosis.notes%TYPE,
        date_problem      VARCHAR2(30),
        date_problem_sort VARCHAR2(30),
        id_professional   professional.id_professional%TYPE,
        id_problem        pat_problem.id_pat_problem%TYPE,
        id_episode        episode.id_episode%TYPE);

    TYPE t_coll_problems IS TABLE OF t_rec_problems;

    /************************************************************************** 
    * get import data from past medical history
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID    
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.3s                      
    * @since                          10-Ock-2011                             
    **************************************************************************/
    FUNCTION get_import_past_hist_medical
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/07                                 
    **************************************************************************/

    FUNCTION get_import_vital_signs
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_scope               IN NUMBER,
        i_scope_type          IN VARCHAR2,
        i_pn_soap_block       IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block       IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date          IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date            IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_outside_period      IN VARCHAR2,
        i_id_pn_task_type     IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_import_date     IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_group_on_import IN pn_dblock_mkt.flg_group_on_import%TYPE,
        i_flg_type            IN pn_data_block.flg_type%TYPE,
        io_data_import        IN OUT t_coll_data_import,
        o_count_records       OUT NUMBER,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from obstetric history
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID  
    * @param i_id_doc_area            Documentation area ID                           
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/07                                 
    **************************************************************************/

    FUNCTION get_import_past_hist_obstetric
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_doc_area      IN doc_area.id_doc_area%TYPE,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_import_date  IN pn_dblock_mkt.flg_import_date%TYPE,
        i_begin_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_synchronized IN VARCHAR2,
        io_data_import     IN OUT t_coll_data_import,
        o_count_records    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from guidelines
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_import_guidelines
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from protocol
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_import_protocol
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from care plans
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_episode             Episode ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID 
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_ongoing            O-auto-populate the ongoing tasks. F-auto-populate the finalized tasks. N-otherwize
    
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/10                               
    **************************************************************************/
    FUNCTION get_import_care_plans
    
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN episode.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date      IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date        IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE,
        i_flg_ongoing     IN VARCHAR2,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * format information about care plan and tasks
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_id_care_plan           Care plan ID
    * @param i_flg_import_date  Y-date must be imported. N-otherwise
    *
    * return clob with information about care plan and task formatted 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/02/12                               
    **************************************************************************/
    FUNCTION get_format_string_care_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_care_plan    IN care_plan.id_care_plan%TYPE,
        i_flg_import_date IN pn_dblock_mkt.flg_import_date%TYPE
    ) RETURN CLOB;

    /**************************************************************************
    * format information about problems, allergies and habits
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID  
    * @param i_problem_desc           Problems' description
    * @param i_problem_status         Problems' status
    * @param i_problem_notes          Problems notes
    *
    * return clob with information about problems formatted 
    *                                                                         
    * @author                         Filipe Silva                            
    * @version                        2.6.0.5                                 
    * @since                          2011/03/09                               
    **************************************************************************/
    FUNCTION get_format_string_problems
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_problem_desc   IN CLOB,
        i_problem_status IN sys_domain.desc_val%TYPE,
        i_problem_notes  IN pat_history_diagnosis.notes%TYPE
    ) RETURN CLOB;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/

    FUNCTION get_import_h_and_p
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from vital signs
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data select s1.username || '@' || s1.machine || ' ( SID=' || s1.sid || ' )  is blocking ' || s2.username || '@' || s2.machine || ' ( SID=' || s2.sid || ' ) ' AS blocking_status from v$lock l1, v$session s1, v$lock l2, v$session s2 where s1.sid=l1.sid and s2.sid=l2.sid and l1.BLOCK=1 and l2.request > 0 and l1.id1 = l2.id1 and l2.id2 = l2.id2;
    * @param i_flg_filter             Filter to apply
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/

    FUNCTION get_import_single_page_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_scope         IN NUMBER,
        i_scope_type    IN VARCHAR2,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_filter    IN VARCHAR2,
        i_id_task_type  IN NUMBER DEFAULT pk_prog_notes_constants.g_task_single_page_note,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION is_technical_task
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN tl_task.id_tl_task%TYPE,
        i_id_task   IN NUMBER
    ) RETURN VARCHAR2;
    /**************************************************************************
    * get import data from the EA table corresponding to the given task type.
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID    
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_id_tasks               Task Ids: specific tasks to be synchronized
    * @param i_id_task_types          Task types IDs: specific task types to be synchronized
    * @param i_calc_task_descs        1-Calc the task descriptions. 0-Otherwise
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                        
    * @version                        2.6.1.2                            
    * @since                          2011/02/18                               
    **************************************************************************/
    FUNCTION get_import_from_ea
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_tasks        IN table_number,
        i_id_task_types   IN table_number,
        i_calc_task_descs IN PLS_INTEGER DEFAULT 1,
        i_epis_pn         IN epis_pn.id_epis_pn%TYPE,
        i_id_pn_note_type in pn_note_type.id_pn_note_type%type,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT PLS_INTEGER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.6.2                             
    * @since                          24-Sep-2012                            
    **************************************************************************/

    FUNCTION get_import_visit_info
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_scope                 IN NUMBER,
        i_scope_type            IN VARCHAR2,
        i_pn_soap_block         IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block         IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_description       IN VARCHAR2 DEFAULT NULL,
        i_description_condition IN VARCHAR2 DEFAULT NULL,
        io_data_import          IN OUT t_coll_data_import,
        o_count_records         OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * Get import data from child development and nutrition
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Anna Kurowska                     
    * @version                        2.6.3                            
    * @since                          30-Jan-2013                            
    **************************************************************************/
    FUNCTION get_import_child_dev_feed
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Function that indicate if the task type should be imported
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_tl_task             Task type ID
    * @param i_id_task                Task type transaccional ID
    *                                                                         
    * @author                         VAnessa Barsottelli
    * @version                        2.6.4                            
    * @since                          28-Out-2014                            
    **************************************************************************/
    FUNCTION check_import_task_type
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_tl_task IN task_timeline_ea.id_tl_task%TYPE,
        i_id_task    IN task_timeline_ea.id_task_refid%TYPE
    ) RETURN NUMBER;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.1.0                            
    * @since                          27/04/2017                            
    **************************************************************************/
    FUNCTION get_import_prof_resp
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_scope                   IN NUMBER,
        i_scope_type              IN VARCHAR2,
        i_pn_soap_block           IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block           IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type         IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_admitting_physician IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        io_data_import            IN OUT t_coll_data_import,
        o_count_records           OUT NUMBER,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data for document status
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Vanessa Barsottelli
    * @version                        2.7.1.0                            
    * @since                          06/06/2017                            
    **************************************************************************/
    FUNCTION get_import_doc_status
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get_import_patient_information
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Amanda Lee
    * @version                        2.7.1.0
    * @since                          29/09/2019
    **************************************************************************/
    FUNCTION get_import_patient_information
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get_import_vaccination
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.1.0
    * @since                          04/10/2019
    **************************************************************************/
    FUNCTION get_import_vaccination
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import attending physicians
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Webber Chiou
    * @version                        2.7.2.3
    * @since                          17/01/2018
    **************************************************************************/
    FUNCTION get_import_att_phy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    **************************************************************************/
    FUNCTION get_import_pmh_biometrics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from a note from another note type registered in the same episode
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_episode             Episode ID  
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_flg_filter             Filter to apply. 
    *                                 The syntax must be: id_pn_note_type-id_pn_data_block
    *                                 For instance: 2-20
    *                                 This means that will be imported the tasks from the last note with note_type =2 of the episode
    *                                 associated to the datablock 20
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.7                          
    * @since                          15-10-2017                       
    **************************************************************************/
    FUNCTION get_import_from_other_note
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_episode    IN episode.id_episode%TYPE,
        i_pn_soap_block IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_flg_filter    IN VARCHAR,
        io_data_import  IN OUT t_coll_data_import,
        o_count_records OUT NUMBER,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Performs some action before the records importation to the note. From instance copy the record to import
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_id_task                Task ID
    * @param i_id_task_type           Task type ID
    * @param i_id_episode             Episode ID
    * @param i_action                 Action to apply. 
    *        Ex: CPRN - copy the records from other note. to be used to copy templates from a datablock of other note
    * @param i_id_pn_note_type_action  Note type associated to the action (Note type associated to the records to be copied)
    * @param i_id_pn_data_block_action Data block associated to the action (Data block associated to the records to be copied)
    *
    * @param o_id_task_to_import      Id task to be imported. Ex. id of the copied template
    * @param o_error                  Error
    *                                                                         
    * @author                         Sofia Mendes                     
    * @version                        2.7                          
    * @since                          15-10-2017                       
    **************************************************************************/
    FUNCTION set_action_import_data
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_task                 IN epis_pn_det_task.id_task%TYPE,
        i_id_task_type            IN epis_pn_det_task.id_task_type%TYPE,
        i_id_episode              IN episode.id_episode%TYPE,
        i_action                  IN VARCHAR2,
        i_id_pn_note_type_action  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block_action IN pn_data_block.id_pn_data_block%TYPE,
        i_epis_pn                 IN epis_pn.id_epis_pn%TYPE,
        o_id_task_to_import       OUT epis_pn_det_task.id_task%TYPE,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * Import Complications and Diagnosis that intercepts the complication list
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Patient ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Pedro Teixeira
    * @version                        2.7
    * @since                          04/10/2017
    **************************************************************************/
    FUNCTION get_import_complications
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_related_data_from_ea
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_task              IN table_number,
        i_id_task_type_related IN task_timeline_ea.id_tl_task%TYPE,
        i_id_data_block        IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block        IN pn_soap_block.id_pn_soap_block%TYPE,
        i_id_note_type         IN pn_note_type.id_pn_note_type%TYPE,
        i_flg_action           IN VARCHAR2,
        o_id_task              OUT table_number,
        o_dt_task              OUT table_varchar,
        o_id_task_type         OUT table_number,
        o_note_task            OUT table_clob,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_data_block_txt
    (
        i_id_epis_pn    IN epis_pn.id_epis_pn%TYPE,
        i_id_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_soap_block IN pn_soap_block.id_pn_soap_block%TYPE
    ) RETURN CLOB;
    FUNCTION is_last_epis_pn
    (
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_pn_note_type  IN pn_note_type.id_pn_note_type%TYPE,
        i_id_pn_data_block IN pn_data_block.id_pn_data_block%TYPE,
        i_id_task_type     IN pn_dblock_ttp_mkt.id_task_type%TYPE,
        i_id_task          IN epis_pn_det_task.id_task%TYPE
    ) RETURN BOOLEAN;

    FUNCTION is_first_epis_pn
    (
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_pn_note_type IN pn_note_type.id_pn_note_type%TYPE
    ) RETURN BOOLEAN;
    ---

    /**************************************************************************
    * get_import_vs_by_view_date
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})    
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_id_pn_task_type        Task type
    * @param i_flg_view               Vital Sign view type
    * @param i_flg_first_record       Flg for first_record 
    * @param i_all_details            View all detail Y/N
    * @param i_interval               Interval to filter
    * @param io_data_import           Struct with data import information
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7
    * @since                          05/01/2018
    **************************************************************************/
    FUNCTION get_import_vs_by_view_date
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_scope            IN NUMBER,
        i_scope_type       IN VARCHAR2,
        i_pn_soap_block    IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block    IN pn_data_block.id_pn_data_block%TYPE,
        i_begin_date       IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_end_date         IN TIMESTAMP WITH LOCAL TIME ZONE DEFAULT NULL,
        i_id_pn_task_type  IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_view         IN vs_soft_inst.flg_view%TYPE,
        i_flg_first_record IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        i_all_details      IN VARCHAR2 DEFAULT pk_alert_constant.g_yes,
        i_interval         IN VARCHAR2 DEFAULT NULL,
        io_data_import     IN OUT t_coll_data_import,
        o_count_records    OUT NUMBER,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * get import data from episode transfer information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.2.3                             
    * @since                          18/01/2018                            
    **************************************************************************/
    FUNCTION get_import_transfer_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN NUMBER,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get_import_asse_score
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.2.3
    * @since                          13/1/2018
    **************************************************************************/
    FUNCTION get_import_asse_score
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import defult priority
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Webber Chiou
    * @version                        2.7.2.4
    * @since                          12/02/2018
    **************************************************************************/
    FUNCTION get_import_asse_priority
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import transfer out clinical service
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Lillian Lu
    * @version                        2.7.2.3
    * @since                          16/01/2018
    **************************************************************************/
    FUNCTION get_import_trans_cs_dest
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * check_reenter_icu
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7.2.3
    * @since                          17/1/2018
    **************************************************************************/
    FUNCTION check_reenter_icu
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get_cur_pre_icu_info
    * Get current and previous ICU info
    *
    * @param i_lang                   Language ID
    * @param i_prof                   Profissional ID
    * @param i_id_episode             Episode ID
    * @param i_id_patient             Patient ID
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *
    * @author                         Howard Cheng
    * @version                        2.7.2.3
    * @since                          17/1/2018
    **************************************************************************/
    FUNCTION get_cur_pre_icu_info
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.4.1                            
    * @since                ;          18/09/2018                            
    **************************************************************************/
    FUNCTION get_import_blood_type
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from visit information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Elisabete Bugalho                   
    * @version                        2.7.4.1                            
    * @since                          18/09/2018                            
    **************************************************************************/
    FUNCTION get_import_obstetric_index
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    FUNCTION get_import_current_pregnancy
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * get import data from house information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Diogo Oliveira                  
    * @version                        2.7.4.6                            
    * @since                          19/11/2018                            
    **************************************************************************/
    FUNCTION get_import_housing
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from socio-demographic information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Diogo Oliveira                  
    * @version                        2.7.4.6                            
    * @since                          19/11/2018                            
    **************************************************************************/
    FUNCTION get_import_soc_class
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /*
    * get import data from admissions days
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita                  
    * @version                        2.8.0.2                             
    * @since                          16-10-2020                            
    **/
    FUNCTION get_import_admission_days
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * get import data from household financial situation information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Diogo Oliveira                  
    * @version                        2.7.4.6                            
    * @since                          19/11/2018                            
    **************************************************************************/
    FUNCTION get_import_house_financial
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from household members information
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Diogo Oliveira                  
    * @version                        2.7.4.6                            
    * @since                          26/11/2018                            
    **************************************************************************/
    FUNCTION get_import_household
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_import_interv_plan
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    
    FUNCTION is_doc_area_sp_available
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_doc_area          IN doc_area.id_doc_area%TYPE,
        i_id_pn_note_type      IN pn_note_type.id_pn_note_type%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_summary_page      IN summary_page.id_summary_page%TYPE,
        i_flg_exc_sum_page_da IN VARCHAR2
    ) RETURN VARCHAR2;
    
    /**************************************************************************
    * get import data from patient identification
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_begin_date             Begin date
    * @param i_end_date               End date
    * @param i_outside_period         Get (Y) or not (N) records outside de period of time
    * @param i_id_pn_task_type        Task type
    * @param i_flg_import_date        Y-record date should be imported; N-otherwise
    * @param i_flg_group_on_import    D-records grouped by date
    * @param i_flg_type               Data block flg type. To distinguish the table from the text data block
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Vítor Sá                
    * @version                        2.7.5.3                             
    * @since                          24-04-2019                            
    **************************************************************************/
    FUNCTION get_pat_identification
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_scope                 IN NUMBER,
        i_scope_type            IN VARCHAR2,
        i_pn_soap_block         IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block         IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type       IN epis_pn_det_task.id_task_type%TYPE,
        i_flg_description       IN VARCHAR2,
        i_description_condition IN VARCHAR2,
        io_data_import          IN OUT t_coll_data_import,
        o_count_records         OUT NUMBER,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /**************************************************************************
    * get import data from grouped medication in last 24h
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita               
    * @version                        2.8.1.0                             
    * @since                          16-03-2020                            
    **************************************************************************/
    FUNCTION get_local_med_lastday
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;
    /**************************************************************************
    * get import data from grouped medication (antibiotics admin here)
    *                                                                         
    * @param i_lang                   Language ID                             
    * @param i_prof                   Profissional ID                         
    * @param i_scope                  Scope ID (Patient ID, Visit ID, Episode ID)    
    * @param i_scope_type             Scope type (by patient {P}, by visit {V}, by episode{E})
    * @param i_pn_soap_block          Soap block ID
    * @param i_pn_data_block          Data block ID
    * @param i_id_pn_task_type        Task type
    * @param io_data_import           Struct with data import information
    *
    * @param o_count_records          Number of records
    * @param o_error                  Error
    *                                                                         
    * @author                         Ana Moita               
    * @version                        2.8.1.0                             
    * @since                          16-03-2020                            
    **************************************************************************/
    FUNCTION get_local_med_antibiotics
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_scope           IN NUMBER,
        i_scope_type      IN VARCHAR2,
        i_pn_soap_block   IN pn_soap_block.id_pn_soap_block%TYPE,
        i_pn_data_block   IN pn_data_block.id_pn_data_block%TYPE,
        i_id_pn_task_type IN epis_pn_det_task.id_task_type%TYPE,
        io_data_import    IN OUT t_coll_data_import,
        o_count_records   OUT NUMBER,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    --
    g_package_owner VARCHAR2(50);
    g_package_name  VARCHAR2(50);

    g_other_exception EXCEPTION;
    g_error VARCHAR2(4000);
    g_limit NUMBER := 1000;

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_sysdate_char VARCHAR2(50);

END pk_prog_notes_dblock;
/
