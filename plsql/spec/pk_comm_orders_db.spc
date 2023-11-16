/*-- Last Change Revision: $Rev: 2005972 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2022-01-20 16:59:36 +0000 (qui, 20 jan 2022) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders_db IS

    -- Author  : ANA.MONTEIRO
    -- Created : 05-03-2014 14:41:18
    -- Purpose : 

    /**
    * Gets communication order requests description, used for the task timeline easy access
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_comm_order_req          Communication order request identifier
    *
    * @return  clob                         Communication order request description
    *
    * @author  ana.monteiro
    * @since   06-03-2014
    */
    FUNCTION get_comm_order_req_desc
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_comm_order_req     IN comm_order_req.id_comm_order_req%TYPE,
        i_description_condition IN pn_dblock_ttp_mkt.description_condition%TYPE DEFAULT NULL,
        i_flg_desc_for_dblock   IN pk_types.t_flg_char DEFAULT NULL
    ) RETURN CLOB;

    /**
    * Gets communication order requests description.
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  clob                         Communication order request title
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_comm_order_req_title
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /**
    * Gets communication order requests instructions.
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  clob                         Communication order request instructions
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_comm_order_req_instr
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN CLOB;

    /**
    * Gets co-sign action description
    * Used by co-sign module
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_task                    Co-sign task identifier
    * @param   i_id_action                  Co-sign action identifier
    * @param   i_id_co_sign_hist            Co-sign history identifier
    *
    * @return  VARCHAR2                     Co-sign action description
    *
    * @author  ana.monteiro
    * @since   30-03-2015
    */
    FUNCTION get_cs_action_desc
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_task         IN co_sign.id_task%TYPE,
        i_id_action       IN co_sign.id_action%TYPE,
        i_id_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_cs_date_to_order
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN co_sign.id_task%TYPE,
        i_co_sign_hist IN co_sign_hist.id_co_sign_hist%TYPE
    ) RETURN TIMESTAMP
        WITH LOCAL TIME ZONE;

    /**
    * Informs communication orders module that a visit changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_visit_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * Informs communication orders module that an episode changed its status
    *
    * @param   i_lang                Professional preferred language
    * @param   i_prof                Professional identification and its context (institution and software)
    * @param   i_event_type          Type of event (UPDATE, INSERT, etc)
    * @param   i_rowids              List of ROWIDs belonging to the changed records.
    * @param   i_list_columns        List of columns that were changed
    * @param   i_source_table_name   Name of the table that was changed.
    * @param   i_dg_table_name       Name of the Data Governance table.
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   07-03-2014
    */
    PROCEDURE set_episode_status_trigger
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    /**
    * This function deletes all data related to a communication order request episode
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_id_patients                Array of patient identifiers
    * @param   i_id_episodes                Array of episode identifiers
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   21-03-2014
    */
    FUNCTION reset_comm_order_req
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_id_patients IN table_number,
        i_id_episodes IN table_number,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns communication orders list for the viewer
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_patient                    Patient identifier
    * @param   i_viewer_area                Viewer area
    * @param   i_episode                    Episode identifier
    * @param   o_list                       Cursor containing communication orders list
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   02-12-2014
    */
    FUNCTION get_comm_order_viewer_list
    (
        i_lang        IN language.id_language%TYPE,
        i_prof        IN profissional,
        i_patient     IN patient.id_patient%TYPE,
        i_viewer_area IN VARCHAR2,
        i_episode     IN episode.id_episode%TYPE,
        o_list        OUT pk_types.cursor_type,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    * Returns communication orders for a given episode
    * Used by grid summary screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)
    * @param   i_episode                    Episode identifier
    * @param   i_filter_tstz                Date to filter only the records with "end dates" > i_filter_tstz
    * @param   i_filter_status              Array with task status to consider along with i_filter_tstz
    * @param   o_comm_orders                Cursor containing the communication order requests of this episode
    * @param   o_error                      Error information
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @since   03-12-2014
    */
    FUNCTION get_comm_order_summ_grid
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_episode       IN episode.id_episode%TYPE,
        i_filter_tstz   IN TIMESTAMP WITH LOCAL TIME ZONE,
        i_filter_status IN table_number,
        o_comm_orders   OUT pk_types.cursor_type,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION inactivate_comm_order_tasks
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_inst      IN institution.id_institution%TYPE,
        o_has_error OUT BOOLEAN,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_db;
/
