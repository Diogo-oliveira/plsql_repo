/*-- Last Change Revision: $Rev: 2028638 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ea_logic_interv_icnp IS

    -- Author  : JOSE.BRITO
    -- Created : 07-10-2008 09:39:19
    -- Purpose : Easy access for nursing interventions

    /**
     * This procedure was created to calculate the status of a certain icnp_epis_intervention
     * status. Insted of doing this at SELECT time this function is suppose to
     * be used at INSERT and UPDATE time.
     *
     * @param     i_prof               Professional type.
     * @param     i_flg_status         Request's status  
     * @param     i_flg_type           The type of recurrence (in the old recurrence mechanism)
     * @param     i_flg_time           Execution type: in the (E)pisode, (B)etween episodes, (N)ext episode
     * @param     i_dt_next            Next execution's date
     * @param     i_dt_plan            Next execution's date 
     * @param     i_flg_prn            Flag that indicates if the intervention should only be executed only as 
     *                                 the situation demands.
     * @param     o_status_str         Request's status (in specific format)
     * @param     o_status_msg         Request's status message code
     * @param     o_status_icon        Request's status icon
     * @param     o_status_flg         Request's status flag (to return the icon)
     * 
     * @author Luis Oliveira
     * @since  14-Jun-2011
    */
    PROCEDURE get_icnp_interv_status
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE,
        o_status_str          OUT interv_icnp_ea.status_str%TYPE,
        o_status_msg          OUT interv_icnp_ea.status_msg%TYPE,
        o_status_icon         OUT interv_icnp_ea.status_icon%TYPE,
        o_status_flg          OUT interv_icnp_ea.status_flg%TYPE
    );

    /**
    * Updates the Easy Access table for nursing interventions - Table ICNP_EPIS_INTERVENTION
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author José Brito
    * @version 2.4.3-Denormalized
    * @since 2008/10/07
    */
    PROCEDURE set_icnp_epis_intervention
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    FUNCTION get_icnp_interv_status_str
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_icnp_interv_status_msg
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_icnp_interv_status_icon
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_icnp_interv_status_flg
    (
        i_prof                IN profissional,
        i_flg_status          IN interv_icnp_ea.flg_status%TYPE,
        i_flg_type            IN interv_icnp_ea.flg_type%TYPE,
        i_flg_time            IN interv_icnp_ea.flg_time%TYPE,
        i_dt_next             IN interv_icnp_ea.dt_next%TYPE,
        i_dt_plan             IN interv_icnp_ea.dt_plan%TYPE,
        i_flg_prn             IN interv_icnp_ea.flg_prn%TYPE,
        i_order_recurr_option IN order_recurr_option.id_order_recurr_option%TYPE
    ) RETURN VARCHAR2;

    /**
    * Updates the Easy Access table for nursing interventions - Table ICNP_EPIS_DIAGNOSIS
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author José Brito
    * @version 2.4.3-Denormalized
    * @since 2008/10/07
    */
    PROCEDURE set_icnp_epis_diagnosis
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
    * Updates the Easy Access table for nursing interventions - Table ICNP_INTERV_PLAN
    *
    * @param i_lang               Language.
    * @param i_prof               Logged professional.
    * @param i_event_type         Type of event (UPDATE, INSERT, etc)
    * @param i_rowids             List of ROWIDs belonging to the changed records.
    * @param i_list_columns       List of columns that were changed
    * @param i_source_table_name  Name of the table that was changed.
    * @param i_dg_table_name      Name of the Data Governance table.
    *
    * @author José Brito
    * @version 2.4.3-Denormalized
    * @since 2008/10/07
    */
    PROCEDURE set_icnp_interv_plan
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_grid_task_icnp
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_task_timeline_interv
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );

    PROCEDURE set_task_timeline_diag
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_event_type        IN VARCHAR2,
        i_rowids            IN table_varchar,
        i_source_table_name IN VARCHAR2,
        i_list_columns      IN table_varchar,
        i_dg_table_name     IN VARCHAR
    );
    ---------------------------------------- GLOBAL VALUES ----------------------------------------------

    /* Current timestamp */
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

    /* Error tracking */
    g_error VARCHAR2(4000);

    /* Invalid event type */
    g_excp_invalid_event_type EXCEPTION;

END pk_ea_logic_interv_icnp;
/
