/*-- Last Change Revision: $Rev: 2055768 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2023-02-23 15:11:25 +0000 (qui, 23 fev 2023) $*/

CREATE OR REPLACE PACKAGE pk_order_sets IS

    /**
    * Convert a clob to varchar2 and truncate it to the max size, adding ellipsis if necessary
    *
    * @param i_clob               clob value
    * @param i_max_size           max size
    *
    * @return  varchar2           varchar2 value
    *
    * @author  tiago.silva
    * @version 1.0
    * @since   05-06-2014
    */
    FUNCTION trunc_clob_to_varchar2
    (
        i_clob     IN CLOB,
        i_max_size IN NUMBER
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if "RECM/despachos" field must be available has an outside medication task detail for this institution market
    *
    * @param    I_LANG                     Preferred language ID
    * @param    I_PROF                     Object (ID of professional, ID of institution, ID of software)
    * @param    O_FLG_RECM_AVAIL           Indicates if "RECM/despachos" field must be available or not
    * @param    O_ERROR                    Error message
    *
    * @value    O_FLG_RECM_AVAIL           {*} 'Y' "RECM/despachos " field must be available
    *                                      {*} 'N' "RECM/despachos " field shouldn't be available
    *
    * @return   BOOLEAN                    false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/09/08
    ********************************************************************************************/
    FUNCTION check_recm_availability
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        o_flg_recm_avail OUT VARCHAR2,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if an order set task is available for the given software and institution
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASK_TYPE    Task type ID to verify if it is available
    *
    *
    * @return   VARCHAR2: 'Y' if task is available and 'N' otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/06
    ********************************************************************************************/
    FUNCTION check_order_set_task_avail
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN order_set_task_soft_inst.id_task_type%TYPE
    ) RETURN VARCHAR2;

    FUNCTION check_order_set_task_avail
    (
        i_lang         IN language.id_language%TYPE,
        i_professional IN professional.id_professional%TYPE,
        i_institution  IN institution.id_institution%TYPE,
        i_software     IN software.id_software%TYPE,
        i_task_type    IN order_set_task_soft_inst.id_task_type%TYPE
    ) RETURN VARCHAR2 result_cache;

    /**
    * Checks if the current order set already has an intake/output task
    * of the same type, in progress.
    *
    * @param   i_lang         Professional preferred language
    * @param   i_prof         Professional identification and its context (institution and software)
    * @param   i_id_order_set   Order Set ID
    * @param   i_acronym      Type of task being requested
    * @param   o_exists       Exists a task of the same type? (Y) Yes (N) No
    * @param   o_error        Error information
    *
    * @return  TRUE if successful, FALSE otherwise
    *
    * @author  Pedro Henriques
    * @version 2.6.5.3
    * @since   29-07-2016
    */

    FUNCTION check_os_existing_hidrics_task
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        i_acronym      IN hidrics_type.acronym%TYPE,
        o_exists       OUT VARCHAR2,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * return pre-selection value of an order set task
    *
    * @param    i_lang            preferred language ID
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_order_set_task  order set task ID
    *
    * @return   varchar2          order set task pre-selection value: (Y)es or (N)o
    *
    * @author                     Carlos Loureiro
    * @since                      22-AUG-2011
    ********************************************************************************************/
    FUNCTION get_task_presel
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * return pre-selection value of an order set process task
    *
    * @param    i_lang                    preferred language ID
    * @param    i_prof                    object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task  order set process task ID
    *
    * @return   varchar2                  order set process task pre-selection value: (Y)es or (N)o
    *
    * @author                             Tiago Silva
    * @since                              09-Jan-2013
    ********************************************************************************************/
    FUNCTION get_proc_task_presel
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * set pre-selection value of an order set task
    *
    * @param    i_lang                          preferred language ID
    * @param    i_prof                          object (id of professional, id of institution, id of software)
    * @param    i_order_set_task                list of order set task IDs
    * @param    i_flg_task_selected             task selection status
    * @param    o_updated_presel_tasks          cursor with updated information of the selected tasks
    *
    * @return   boolean                         false in case of error, otherwise tue
    *
    * @value    i_flg_task_selected             {*} 'Y' order set task selection is checked
    *                                           {*} 'N' order set task selection is unchecked
    *
    * @author                                   Carlos Loureiro
    * @since                                    23-AUG-2011
    ********************************************************************************************/
    FUNCTION set_task_presel
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_set_task       IN table_number,
        i_flg_task_selected    IN VARCHAR2,
        o_updated_presel_tasks OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set selection value of an order set process task
    *
    * @param    i_lang                          preferred language ID
    * @param    i_prof                          object (id of professional, id of institution, id of software)
    * @param    i_order_set_proc_task           list of order set process task IDs
    * @param    i_flg_task_selected             task selection status
    * @param    o_updated_presel_tasks          cursor with updated information of the selected tasks
    *
    * @return   boolean                         false in case of error, otherwise tue
    *
    * @value    i_flg_task_selected             {*} 'Y' order set task selection is checked
    *                                           {*} 'N' order set task selection is unchecked
    *
    * @author                                   Tiago Silva
    * @since                                    27-Jan-2014
    ********************************************************************************************/
    FUNCTION set_proc_task_presel
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_order_set_proc_task       IN table_number,
        i_flg_task_selected         IN VARCHAR2,
        o_updated_presel_proc_tasks OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * return the order set task type rank to use in order by clauses
    *
    * @param    i_lang            preferred language ID
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_id_task_type    task type id to get rank
    *
    * @return                     number: task type rank
    *
    * @author                     Carlos Loureiro
    * @version                    1.0
    * @since                      2009/07/30
    ********************************************************************************************/
    FUNCTION get_task_type_rank
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN order_set_task_soft_inst.id_task_type%TYPE
    ) RETURN order_set_task_soft_inst.rank%TYPE;

    /********************************************************************************************
    * Checks if a given task represents or can be considered as an episode
    *
    * @param    I_LANG                       Preferred language id
    * @param    I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param    I_DEPENDENCY_TYPE            Network array of relationships
    * @param    I_TASK_DEPENDENCY_FROM       Network array of task dependencies for the tasks where the dependency comes from
    * @param    I_TASK_DEPENDENCY_TO         Network array of task dependencies for the tasks where the dependency goes to
    * @param    I_ORDER_SET_TASK             Order Set task ID to check for
    * @param    I_TASK_TYPE                  Task type ID of the Order Set task to check for
    *
    * @RETURN   VARCHAR2                     {*} 'Y' the task represents or is considered an episode
    *                                        {*} 'N' the task is not an episode
    *
    * @author   Tiago Silva
    * @since    25-JUN-2010
    ********************************************************************************************/
    FUNCTION check_episode_support_task
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_dependency_type      IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_order_set_task       IN order_set_task.id_order_set_task%TYPE,
        i_task_type            IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Returns the order set task rank
    *
    * @param    I_TASK_RANKS     Array with all order set tasks ordered by rank
    * @param    I_ID_ORDER_SET   Order set task ID
    *
    * @return   NUMBER           Order set task rank
    *
    * @author   Tiago Silva
    * @since    2010/06/30
    ********************************************************************************************/
    FUNCTION get_task_rank
    (
        i_task_ranks     IN table_number,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * returns the type of a given order set task
    *
    * @param    i_lang            preferred language ID
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_order_set_task  order set task ID
    *
    * @return   number            task type
    *
    * @author   Tiago Silva
    * @since    2010/06/22
    ********************************************************************************************/
    FUNCTION get_odst_task_type
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN order_set_task.id_task_type%TYPE;

    /********************************************************************************************
    * returns the type of a given order set process task
    *
    * @param    i_lang                    preferred language ID
    * @param    i_prof                    object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task  order set process task ID
    *
    * @return   number                    task type
    *
    * @author   Tiago Silva
    * @since    2010/08/13
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_type
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN order_set_process_task.id_task_type%TYPE;

    /********************************************************************************************
    * returns the description of a given task detail value
    *
    * @param    i_lang              preferred language ID
    * @param    i_prof              object (id of professional, id of institution, id of software)
    * @param    i_episode           episode ID (may be not applicable in some cases)
    * @param    i_task_type         task type ID
    * @param    i_flg_detail_type   task detail type
    * @param    i_detail_nvalue     numeric value of the task detail
    * @param    i_detail_dvalue     date value of the task detail
    * @param    i_detail_vvalue     varchar value of the task detail
    *
    * @return   varchar2            task detail description
    *
    * @author                       Tiago Silva
    * @since                        2010/08/05
    ********************************************************************************************/
    FUNCTION get_task_detail_description
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_episode         IN episode.id_episode%TYPE,
        i_task_type       IN task_type.id_task_type%TYPE,
        i_flg_detail_type IN order_set_task_detail.flg_detail_type%TYPE,
        i_detail_nvalue   IN order_set_task_detail.nvalue%TYPE,
        i_detail_dvalue   IN order_set_task_detail.dvalue%TYPE,
        i_detail_vvalue   IN order_set_task_detail.vvalue%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Function used to replace dependencies references, existing in a string, by its task rank
    *
    * @param    I_LANG           Preferred language ID
    * @param    I_STR            String that constains the dependencies references to replace
    * @param    I_TASKS_RANK     Array that contains the rank of each order set task
    *
    * @RETURN   varchar2         new string
    *
    * @author   Tiago Silva
    * @since    28-JUN-2010
    ********************************************************************************************/
    FUNCTION replace_dependencies_refs_rank
    (
        i_lang       IN language.id_language%TYPE,
        i_str        sys_message.desc_message%TYPE,
        i_tasks_rank table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Returns string with intructions description of a specific task
    *
    * @param    I_LANG                Preferred language ID
    * @param    I_PROF                Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASKS            Task IDs
    * @param    I_FLG_PROCESS_TASKS   Indicate if task IDs belongs to an order set or an order set process
    *
    * @value    I_FLG_PROCESS_TASKS   {*} 'Y' task IDs belongs to an order set process {*} 'N' task IDs belongs to an order set
    *
    * @return   VARCHAR2: String with task instructions description
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/12
    ********************************************************************************************/
    FUNCTION get_task_instructions_desc
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_tasks          IN table_number,
        i_flg_process_tasks IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Returns string with the description of a specific task
    *
    * @param    I_LANG                      Preferred language ID
    * @param    I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASK                   Task ID
    * @param    I_ID_TASK_TYPE              Task type ID
    * @param    I_FLG_PROCESS_TASK          Indicate if task ID belongs to an order set or an order set process
    * @param    I_FLG_BOLD_TASK_TITLE       Indicate if the task title must be bold or not
    * @param    I_FLG_TASK_DESC_FORMAT      Indicate if the task description format
    * @param    I_FLG_SHOW_MANDATORY_SIGN   Indicate if the mandatory sign must be shown or not
    * @param    I_FLG_SHOW_TASK_NOTES       Flag that indicates if notes should appear under the task title or not
    *
    * @value    I_FLG_PROCESS_TASK          {*} 'Y' task ID belongs to an order set process
    *                                       {*} 'N' task ID belongs to an order set
    *
    * @value    I_FLG_BOLD_TASK_TITLE       {*} 'Y' task title in bold
    *                                       {*} 'N' task title without bold
    *
    * @value    I_FLG_TASK_DESC_FORMAT      {*} 'S' short task description format
    *                                       {*} 'E' extended task description format
    *                                       {*} 'D' detail task description format
    *
    * @value    I_FLG_SHOW_MANDATORY_SIGN   {*} 'Y' show mandatory sign
    *                                       {*} 'N' doesn't show mandatory sign
    *
    * @value    I_FLG_SHOW_TASK_NOTES       {*} 'Y' show task notes
    *                                       {*} 'N' hide task notes
    *
    * @return   VARCHAR2: String with task description
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/12
    ********************************************************************************************/
    FUNCTION get_task_desc
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_task                 IN order_set_task.id_order_set_task%TYPE,
        i_id_task_type            IN order_set_task.id_task_type%TYPE,
        i_flg_process_task        IN VARCHAR2,
        i_flg_bold_task_title     IN VARCHAR2,
        i_flg_task_desc_format    IN VARCHAR2,
        i_flg_show_mandatory_sign IN VARCHAR2,
        i_flg_show_task_notes     IN VARCHAR2 DEFAULT 'N'
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Returns the id of a specific task
    *
    * @param    I_LANG                      Preferred language ID
    * @param    I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ODST_PROC_TASK         Order set process task id
    * @param    I_ID_TASK_TYPE              Task type ID
    *
    * @return   Number: Task id
    *
    * @author   Tiago Silva
    * @since    22-May-2015
    ********************************************************************************************/
    FUNCTION get_task_id
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_odst_proc_task IN order_set_process_task.id_order_set_process_task%TYPE,
        i_id_task_type      IN order_set_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Returns an array with all descriptions of a specific task
    *
    * @param    I_LANG                      Preferred language ID
    * @param    I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASK                   Task ID
    * @param    I_ID_TASK_TYPE              Task type ID
    * @param    I_FLG_PROCESS_TASK          Indicate if task ID belongs to an order set or an order set process
    * @param    I_FLG_BOLD_TASK_TITLE       Indicate if the task title must be bold or not
    * @param    I_FLG_TASK_DESC_FORMAT      Indicate if the task description format
    * @param    I_FLG_SHOW_MANDATORY_SIGN   Indicate if the mandatory sign must be shown or not
    *
    * @value    I_FLG_PROCESS_TASK          {*} 'Y' task ID belongs to an order set process
    *                                       {*} 'N' task ID belongs to an order set
    *
    * @value    I_FLG_BOLD_TASK_TITLE       {*} 'Y' task title in bold
    *                                       {*} 'N' task title without bold
    *
    * @value    I_FLG_TASK_DESC_FORMAT      {*} 'S' short task description format
    *                                       {*} 'E' extended task description format
    *                                       {*} 'D' detail task description format
    *
    * @value    I_FLG_SHOW_MANDATORY_SIGN   {*} 'Y' show mandatory sign
    *                                       {*} 'N' doesn't show mandatory sign
    *
    * @return   VARCHAR2: String with task description
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2013/11/15
    ********************************************************************************************/
    FUNCTION get_task_desc_array
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_task                 IN order_set_task.id_order_set_task%TYPE,
        i_id_task_type            IN order_set_task.id_task_type%TYPE,
        i_flg_process_task        IN VARCHAR2,
        i_flg_bold_task_title     IN VARCHAR2,
        i_flg_task_desc_format    IN VARCHAR2,
        i_flg_show_mandatory_sign IN VARCHAR2
    ) RETURN t_tbl_odst_task;

    /********************************************************************************************
    *  Get all tasks descriptions of an order set for a specific task type
    *
    * @param    I_LANG           Preferred language ID
    * @param    I_PROF           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET   Order set ID
    * @param    I_TASK_TYPES     Task type IF
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/20
    ********************************************************************************************/
    FUNCTION get_tasks_desc_by_type
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set_task.id_order_set%TYPE,
        i_id_task_type IN order_set_task.id_task_type%TYPE
    ) RETURN CLOB;

    /********************************************************************************************
    *  Get all tasks descriptions of an order set process for a specific task type
    *
    * @param    I_LANG           Preferred language ID
    * @param    I_PROF           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET   Order set ID
    * @param    I_TASK_TYPES     Task type IF
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/20
    ********************************************************************************************/
    FUNCTION get_proc_tasks_desc_by_type
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process_task.id_order_set_process%TYPE,
        i_id_task_type         IN order_set_process_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Gets a link of an order set task
    *
    * @param    I_ID_ORDER_SET_TASK               Order set task ID
    * @param    I_FLG_TASK_LINK_TYPE TASK_TYPES   Type of the task link
    *
    * @return   NUMBER: task link ID
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/21
    ********************************************************************************************/
    FUNCTION get_odst_task_link
    (
        i_id_order_set_task     IN order_set_task_link.id_order_set_task%TYPE,
        i_id_flg_task_link_type IN order_set_task_link.flg_task_link_type%TYPE
    ) RETURN order_set_task_link.id_task_link%TYPE;

    /********************************************************************************************
    *  Gets all links of an order set task
    *
    * @param    I_LANG                    Preferred language ID
    * @param    I_PROF                    Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_TASKS      Array with order set task IDs
    * @param    O_ORDER_SET_TASK_LINKS    Cursor with all task links
    * @param    O_ERROR                   Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/07/17
    ********************************************************************************************/
    FUNCTION get_odst_task_links_all
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_tasks   IN table_number,
        o_order_set_task_links OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Gets the main task link type of an order set task
    *
    * @param    I_ID_ORDER_SET_TASK  Order set task ID
    *
    * @return   VARCHAR2: task link type
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/09/24
    ********************************************************************************************/
    FUNCTION get_odst_task_link_type(i_id_order_set_task IN order_set_task_link.id_order_set_task%TYPE)
        RETURN order_set_task_link.flg_task_link_type%TYPE;

    /********************************************************************************************
    *  Gets a detail value of an order set task
    *
    * @param    I_LANG                          Preferred language ID
    * @param    I_PROF                          Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_TASK             Order set task ID
    * @param    I_FLG_DETAIL_TYPE               Type of detail
    * @param    I_ID_ADVANCED_INPUT             Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD       Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD_DET   Advanced input field detail ID
    *
    * @value    I_FLG_VALUE_TYPE                {*} 'D' Date {*} 'N' Number {*} Varchar
    *
    * @return   VARCHAR: task detail value
    *
    * @author   Tiago Silva
    * @since    2010/08/11
    ********************************************************************************************/
    FUNCTION get_odst_task_det_val
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set_task           IN order_set_task_detail.id_order_set_task%TYPE,
        i_flg_detail_type             IN order_set_task_detail.flg_detail_type%TYPE,
        i_id_advanced_input           IN order_set_task_detail.id_advanced_input%TYPE,
        i_id_advanced_input_field     IN order_set_task_detail.id_advanced_input_field%TYPE,
        i_id_advanced_input_field_det IN order_set_task_detail.id_advanced_input_field_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Gets a detail value of an order set process task
    *
    * @param    I_LANG                          Preferred language ID
    * @param    I_PROF                          Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS_TASK     Order set process task ID
    * @param    I_FLG_DETAIL_TYPE               Type of detail
    * @param    I_ID_ADVANCED_INPUT             Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD       Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD_DET   Advanced input field detail ID
    *
    * @value    I_FLG_VALUE_TYPE    {*} 'D' Date {*} 'N' Number {*} Varchar
    *
    * @return   VARCHAR: task detail value
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/21
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_det_val
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set_process_task   IN order_set_process_task_det.id_order_set_process_task%TYPE,
        i_flg_detail_type             IN order_set_process_task_det.flg_detail_type%TYPE,
        i_id_advanced_input           IN order_set_process_task_det.id_advanced_input%TYPE,
        i_id_advanced_input_field     IN order_set_process_task_det.id_advanced_input_field%TYPE,
        i_id_advanced_input_field_det IN order_set_process_task_det.id_advanced_input_field_det%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * gets multiple values of an order set task detail
    *
    * @param    i_lang                        preferred language id
    * @param    i_prof                        object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task           order set task id
    * @param    i_flg_detail_type             type of detail
    * @param    o_nvalues                     number type values
    * @param    o_vvalues                     varchar type values
    * @param    o_dvalues                     date type values
    *
    * @author   Carlos Loureiro
    * @since    2012/04/18
    ********************************************************************************************/
    PROCEDURE get_odst_task_det_multi_val
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_order_set_task IN order_set_task_detail.id_order_set_task%TYPE,
        i_flg_detail_type   IN order_set_task_detail.flg_detail_type%TYPE,
        o_nvalues           OUT table_number,
        o_vvalues           OUT table_varchar,
        o_dvalues           OUT table_varchar
    );

    /********************************************************************************************
    *  Gets a link of an order set process task
    *
    * @param    I_ID_ORDER_SET_PROCESS_TASK       Order set process task ID
    * @param    I_FLG_TASK_LINK_TYPE TASK_TYPES   Type of the task link
    *
    * @return   NUMBER: task link ID
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/21
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_link
    (
        i_id_order_set_process_task IN order_set_process_task_link.id_order_set_process_task%TYPE,
        i_id_flg_task_link_type     IN order_set_process_task_link.flg_task_link_type%TYPE
    ) RETURN order_set_process_task_link.id_task_link%TYPE;

    /********************************************************************************************
    *  Gets the main task link type of an order set process task
    *
    * @param    I_ID_ORDER_SET_PROCESS_TASK   Order set process task ID
    *
    * @return   VARCHAR2: task link type
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/09/24
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_link_type(i_id_order_set_process_task IN order_set_process_task_link.id_order_set_process_task%TYPE)
        RETURN order_set_process_task_link.flg_task_link_type%TYPE;

    /********************************************************************************************
    * cancel all given order set process task requests
    *
    * @param    i_lang               preferred language id
    * @param    i_prof               object (id of professional, id of institution, id of software)
    * @param    i_id_patient         patient id
    * @param    i_id_episode         episode id
    * @param    i_id_proc_tasks      order set process task ids to be canceled
    * @param    i_id_cancel_reason   reason to cancel the tasks
    * @param    i_cancel_notes       cancel notes
    * @param    i_prof_order         ordering professional
    * @param    i_dt_order           request order date
    * @param    i_order_type         request order type
    * @param    o_error              error message
    *
    * @return   boolean: false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/07/31
    ********************************************************************************************/
    FUNCTION cancel_order_set_proc_tasks
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_patient       IN patient.id_patient%TYPE,
        i_id_episode       IN episode.id_episode%TYPE,
        i_id_proc_tasks    IN table_number,
        i_id_cancel_reason IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes     IN VARCHAR2,
        i_prof_order       IN order_set_process.id_prof_order%TYPE,
        i_dt_order         IN VARCHAR2,
        i_order_type       IN order_set_process.id_order_type%TYPE,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if an order set process task has conflicts
    *
    * @param    I_LANG           Preferred language ID
    * @param    I_PROF           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT     Patient ID
    * @param    I_ID_EPISODE     Episode ID
    * @param    I_ID_TASKS       Order set task ID
    * @param    I_ID_TASK_TYPE   Task type ID
    * @param    I_FLG_TASK_SCHEDULE   Flag that indicates if the task represents or can be considered an episode
    *
    * @return   VARCHAR2: Y in case of conflict and N otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/19
    ********************************************************************************************/
    FUNCTION check_order_set_task_conflict
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_patient        IN patient.id_patient%TYPE,
        i_id_episode        IN episode.id_episode%TYPE,
        i_id_task           IN order_set_task.id_order_set_task%TYPE,
        i_id_task_type      IN order_set_task.id_task_type%TYPE,
        i_flg_task_schedule IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get order set task status string. This functions is prepared to be used on a SQL statement.
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT        Patient ID
    * @param    I_ID_EPISODE        Episode ID
    * @param    I_ID_REQUEST        Task request ID
    * @param    I_ID_TASK_TYPE      Task type ID
    * @param    I_FLG_TASK_STATUS   Task status
    *
    * @return   VARCHAR2: Status string to be used by Flash
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/21
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_status_str
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_id_request      IN order_set_process_task.id_request%TYPE,
        i_id_task_type    IN order_set_process_task.id_task_type%TYPE,
        i_flg_task_status IN order_set_process.flg_status%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if an order set process task has conflicts considering its dependencies
    *
    * @param    I_LANG                     Preferred language ID
    * @param    I_PROF                     Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASK                  Order set task ID
    * @param    I_TASK_DEPENDENCIES        Array of task dependencies
    * @param    I_TASK_CONFLICTS           Array with the conflicts value of each task dependency
    * @param    I_DEPENDENCY_TYPE          Network array of relationships (start-2-start or finish-2-start)
    * @param    I_TASK_DEPENDENCY_FROM     Network array of task dependencies for the tasks where the dependency comes from
    * @param    I_TASK_DEPENDENCY_TO       Network array of task dependencies for the tasks where the dependency goes to
    * @param    I_TASK_TYPE_FROM           Network array of task types for the tasks where the dependency comes from
    * @param    I_TASK_TYPE_TO             Network array of task types for the tasks where the dependency goes to
    *
    * @return   VARCHAR2                   'Y' in case of conflict and 'N' otherwise
    *
    * @author   Tiago Silva
    * @since    2010/07/10
    ********************************************************************************************/
    FUNCTION check_task_depend_conflict
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_task              IN order_set_task.id_order_set_task%TYPE,
        i_task_dependencies    IN table_number,
        i_task_conflicts       IN table_varchar,
        i_dependency_type      IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Check if all mandatory fields of a given order set (process) task are filled.
    *
    * @param    I_LANG                Preferred language ID
    * @param    I_PROF                Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_TASKS            Order set (process) task ID
    * @param    I_ID_TASK_TYPE        Task type ID
    * @param    I_FLG_PROCESS_TASKS   Indicate if task IDs belongs to an order set or an order set process
    *
    * @value    I_FLG_PROCESS_TASKS   {*} 'Y' task IDs belongs to an order set process {*} 'N' task IDs belongs to an order set
    *
    * @return   VARCHAR2: Y in case of all mandatory fields are filled and N otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/27
    ********************************************************************************************/
    FUNCTION check_mandatory_fields
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_task           IN order_set_task.id_order_set_task%TYPE,
        i_id_task_type      IN order_set_task.id_task_type%TYPE,
        i_flg_process_tasks IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Get domain values for use permission field
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Order set ID
    * @param    O_ERROR           Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/07/28
    ********************************************************************************************/

    FUNCTION get_odst_permission_list
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_order_set    IN order_set.id_order_set%TYPE,
        i_permission_type IN VARCHAR2,
        o_error           OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    * Create a specific order set
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Identifier of the existing order set or NULL in case of a new order set
    * @param    I_FLG_DUPLICATE   Duplicate existing order set
    * @param    O_ID_ORDER_SET    Identifier of the order set created
    * @param    O_ERROR           Error message
    *
    * @value    I_FLG_DUPLICATE   {*} 'Y' Yes {*} 'N' No
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/04/29
    ********************************************************************************************/
    FUNCTION create_order_set
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_set  IN order_set.id_order_set%TYPE,
        i_flg_duplicate IN VARCHAR2,
        ---
        o_id_order_set OUT order_set.id_order_set%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set an order set as definitive
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Order set ID to set as definitive
    * @param    O_ERROR           Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/04/29
    ********************************************************************************************/
    FUNCTION set_order_set
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Cancel order set / mark as deleted
    *
    * @param    I_LANG            Preferred language ID
    * @param    I_PROF            Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET    Order set ID
    * @param    O_ERROR           Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/04/30
    ********************************************************************************************/
    FUNCTION cancel_order_set
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_order_set  IN order_set.id_order_set%TYPE,
        i_cancel_reason IN order_set.id_cancel_reason%TYPE,
        i_cancel_notes  IN order_set.notes_cancel%TYPE,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Set specific order set main attributes
    *
    * @param    I_LANG                       Preferred language ID
    * @param    I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET               Order set ID
    * @param    I_TITLE                      Order set title
    * @param    I_AUTHOR                     Order set author description
    * @param    I_FLG_TARGET_PROFESSIONALS   Type of professionals that can use the order set
    * @param    I_FLG_EDIT_PERMISSIONS       Type of professionals that can edit the order set
    * @param    I_LINK_ENVIRONMENT           Order set environment links
    * @param    I_LINK_SPECIALTY             Order set specialty links
    * @param    I_LINK_ORDER_SET_TYPE        Order set type links
    * @param    I_NOTES_GLOBAL               Order set global notes
    * @param    O_ERROR                      Error message
    *
    * @value    I_FLG_TARGET_PROFESSIONALS   {*} 'S' Professionals of the same specialty {*} 'N' No one else
    * @value    I_FLG_EDIT_PERMISSIONS       {*} 'S' Professionals of the same specialty {*} 'N' No one else
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION set_order_set_main_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_order_set             IN order_set.id_order_set%TYPE,
        i_title                    IN order_set.title%TYPE,
        i_author                   IN order_set.author_desc%TYPE,
        i_flg_target_professionals IN order_set.flg_target_professionals%TYPE,
        i_flg_edit_permissions     IN order_set.flg_edit_permissions%TYPE,
        i_link_environment         IN table_number,
        i_link_specialty           IN table_number,
        i_link_clinical_service    IN table_number,
        i_link_order_set_type      IN table_number,
        i_notes_global             IN order_set.notes_global%TYPE,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_set_main_info
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_order_set             IN order_set.id_order_set%TYPE,
        i_title                    IN order_set.title%TYPE,
        i_author                   IN order_set.author_desc%TYPE,
        i_flg_target_professionals IN order_set.flg_target_professionals%TYPE,
        i_flg_edit_permissions     IN order_set.flg_edit_permissions%TYPE,
        i_link_environment         IN table_number,
        i_link_specialty           IN table_number,
        i_link_clinical_service    IN table_number,
        i_link_order_set_type      IN table_number,
        i_notes_global             IN order_set.notes_global%TYPE,
        i_link_institution         IN table_number DEFAULT NULL,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_set_main_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_root_name            IN VARCHAR2,
        i_tbl_id_pk            IN table_number,
        i_tbl_data             IN table_varchar, ---
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_varchar, -- 
        i_tbl_val_clob         IN table_clob, --
        i_tbl_val_array        IN table_table_varchar DEFAULT NULL, --
        i_tbl_val_array_desc   IN table_table_varchar DEFAULT NULL, --
        o_id_order_set         OUT order_set.id_order_set%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set predefined tasks
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   professional structure
    * @param    i_order_set              order set id
    * @param    i_task_type              task type id
    * @param    i_predefined_tasks       array of predefined task ids
    * @param    o_order_set_tasks        cursor with new order set task ids
    * @partam   o_new_predefined_tasks   array of new predefined task ids
    * @param    o_error                  error structure for exception handling
    *
    * @return   boolean                  true on success, otherwise false
    *
    * @author                            Tiago Silva
    * @since                             03-JUL-2011
    ********************************************************************************************/
    FUNCTION set_predefined_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_set            IN order_set.id_order_set%TYPE,
        i_task_type            IN order_set_task.id_task_type%TYPE,
        i_predefined_tasks     IN table_number,
        o_order_set_tasks      OUT pk_types.cursor_type,
        o_new_predefined_tasks OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update order set tasks with new predefined task ids
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   professional structure
    * @param    i_order_set              order set id
    * @param    i_task_type              task type id
    * @param    i_order_set_tasks        order set task ids
    * @param    i_predefined_tasks       array of predefined task ids
    * @param    o_order_set_tasks        cursor with updated order set task ids
    * @partam   o_new_predefined_tasks   array of new predefined task ids
    * @param    o_error                  error structure for exception handling
    *
    * @return   boolean                  true on success, otherwise false
    *
    * @author                            Tiago Silva
    * @since                             03-JUL-2011
    ********************************************************************************************/
    FUNCTION update_predefined_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_set            IN order_set.id_order_set%TYPE,
        i_task_type            IN order_set_task.id_task_type%TYPE,
        i_order_set_tasks      IN table_number,
        i_predefined_tasks     IN table_number,
        o_order_set_tasks      OUT pk_types.cursor_type,
        o_new_predefined_tasks OUT table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update order set process tasks with new predefined task ids
    *
    * @param    i_lang                      preferred language id
    * @param    i_prof                      professional structure
    * @param    i_order_set_process         order set process id
    * @param    i_task_type                 task type id
    * @param    i_order_set_process_tasks   order set process task ids
    * @param    i_predefined_tasks          array of predefined task ids
    * @param    o_order_set_process_tasks   cursor with updated order set process task ids
    * @partam   o_new_predefined_tasks      array of new predefined task ids
    * @param    o_error                     error structure for exception handling
    *
    * @return   boolean                     true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                03-JUL-2011
    ********************************************************************************************/
    FUNCTION update_predefined_proc_tasks
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_order_set_process       IN order_set_process.id_order_set_process%TYPE,
        i_task_type               IN order_set_task.id_task_type%TYPE,
        i_order_set_process_tasks IN table_number,
        i_predefined_tasks        IN table_number,
        o_order_set_process_tasks OUT pk_types.cursor_type,
        o_new_predefined_tasks    OUT table_number,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Set order set tasks. This function allows to set several links for each selection
    *  made by user.
    *
    * @param    I_LANG                  Preferred language ID
    * @param    I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET          Order set ID
    * @param    I_ID_ORDER_SET_TASK     Array of order set task IDs (used when editing order set tasks)
    * @param    I_ID_TASK_LINKS         Task link IDs
    * @param    I_FLG_TASK_LINK_TYPE    Type of the task links
    * @param    I_ID_TASK_TYPE          Type of the order set tasks
    * @param    O_NEW_ORDER_SET_TASKS   Cursor with new order set tasks created
    * @param    O_ERROR                 Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION set_order_set_tasks
    (
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_id_order_set        IN order_set.id_order_set%TYPE,
        i_id_task_links       IN table_table_varchar,
        i_flg_task_link_type  IN table_table_varchar,
        i_id_task_type        IN order_set_task.id_task_type%TYPE,
        o_new_order_set_tasks OUT pk_types.cursor_type,
        o_error               OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
      * Get all Procedures request details of a procedure request
      *
      * @param    i_lang                  preferred language id
      * @param    i_prof                  object (id of professional, id of institution, id of software)
      * @param    i_proc_req            procedure request id
    * @param    o_proc_req_det        cursor with the procedure request details
      * @param    o_error                 error message
      *
      * @return   boolean                 false in case of error and true otherwise
      *
      * @author   Pedro Henriques
      * @since    2016/04/07
      ********************************************************************************************/
    FUNCTION get_procedure_req_det
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_procedure_req     IN table_number,
        o_procedure_req_det OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;
    /********************************************************************************************
    *  Delete order set tasks
    *
    * @param    I_LANG                 Preferred language ID
    * @param    I_PROF                 Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_TASKS   Order set task IDs to be deleted
    * @param    O_ERROR                Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION delete_order_set_tasks
    (
        i_lang               IN language.id_language%TYPE,
        i_prof               IN profissional,
        i_id_order_set_tasks IN table_number,
        o_error              OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * delete order set tasks when order set is in temporary state
    *
    * @param    i_lang                  preferred language ID
    * @param    i_prof                  object (id of professional, id of institution, id of software)
    * @param    i_order_set_proc_tasks  order set process task Ids to be deleted
    *
    * @return   boolean                 true or false on success or error
    *
    * @author   Tiago Silva
    * @since    02-Dec-2013
    ********************************************************************************************/
    FUNCTION delete_order_set_proc_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_order_set_proc_tasks IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Gets the list of order sets available on the tools area
    *
    * @param    I_LANG         Preferred language ID
    * @param    I_PROF         Object (ID of professional, ID of institution, ID of software)
    * @param    I_VALUE        Value to search for (order set title)
    * @param    O_ORDER_SETS   Cursor with all order sets
    * @param    O_ERROR        Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION get_order_set_list
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        o_order_sets OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get order set main attributes
    *
    * @param    I_LANG             Preferred language ID
    * @param    I_PROF             Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET     Order set ID
    * @param    O_ORDER_SET_INFO   Cursor with order set information
    * @param    O_ERROR            Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION get_order_set_main_info
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_order_set     IN order_set.id_order_set%TYPE,
        o_order_set_info   OUT pk_types.cursor_type,
        o_chief_complaints OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get list of order set types
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order set id
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Tiago Silva
    * @since                                   15-Out-2012
    ********************************************************************************************/
    FUNCTION get_order_set_type_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        i_flg_select   IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_error        OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    *  Get multichoice list for environment field
    *
    * @param    I_LANG                    Preferred language ID
    * @param    I_PROF                    Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET            Order set ID
    * @param    O_ERROR                   Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/02
    ********************************************************************************************/
    FUNCTION get_order_set_environment_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE DEFAULT NULL,
        i_institutions IN table_varchar,
        o_error        OUT t_error_out
    ) RETURN t_tbl_core_domain;

    /********************************************************************************************
    *  Get all Order sets task types available
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET           Order set ID
    * @param    O_ORDER_SET_TASK_TYPES   Cursor with all order sets task types
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/05
    ********************************************************************************************/
    FUNCTION get_order_set_task_type_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set         IN order_set.id_order_set%TYPE,
        o_order_set_task_types OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get dependency types to be used on the dependencies pop-up for a given order set task
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ORDER_SET_TASK        Order set task ID
    * @param    O_LIST              Cursor with the list of dependency types
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN:            false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2010/06/07
    ********************************************************************************************/
    FUNCTION get_dependency_types
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE,
        o_list           OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order set tasks that can be used as dependencies for a given order set task
    *
    * @param    I_LANG                  Preferred language ID
    * @param    I_PROF                  Object (ID of professional, ID of institution, ID of software)
    * @param    I_ORDER_SET_TASK        Order Set task ID
    * @param    I_DEPENDENCY_TYPE       Dependency type ID
    * @param    I_POPUP_DEPENDENCY_TYPE Array of pop-up dependency types (all pop-up dependencies except the one that is being edited)
    * @param    I_POPUP_DEPENDENCY      Array of pop-up task dependencies (all pop-up dependencies except the one that is being edited)
    * @param    I_TASKS_RANK            Array that contains the rank of each order set task (used to show the dependency number on the list)
    * @param    O_DEPENDENCIES_LIST     Cursor with order set task dependencies
    * @param    O_ERROR                 Error message
    *
    * @return   BOOLEAN:                false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2010/06/08
    ********************************************************************************************/
    FUNCTION get_task_dependencies_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_order_set_task        IN order_set_task.id_order_set_task%TYPE,
        i_dependency_type       IN order_set_task_dependency.id_relationship_type%TYPE,
        i_popup_dependency_type IN table_number,
        i_popup_dependency      IN table_number,
        i_tasks_rank            IN table_number,
        o_dependencies_list     OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all dependencies of an order set task
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ORDER_SET_TASK    Order set task ID
    * @param    I_TASKS_RANK        Array that contains the rank of each order set task (used to show the dependency number on the list)
    * @param    O_DEPENDENCIES      Cursor with order set task dependencies
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN:            false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2010/06/02
    ********************************************************************************************/
    FUNCTION get_odst_task_dependencies
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE,
        i_tasks_rank     IN table_number,
        o_dependencies   OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if all the dependencies of a given order set task are valid according to TDE rules
    *
    * @param    I_LANG                     Preferred language ID
    * @param    I_PROF                     Object (ID of professional, ID of institution, ID of software)
    * @param    I_ORDER_SET_TASK           Order Set task ID
    * @param    I_POPUP_DEPENDENCY_TYPE    Array of pop-up dependency types (all pop-up dependencies)
    * @param    I_POPUP_DEPENDENCY         Array of pop-up task dependencies (all pop-up dependencies)
    * @param    I_POPUP_LAG_MIN            Array of pop-up minimum lag time between tasks (all pop-up dependencies)
    * @param    I_POPUP_LAG_MAX            Array of pop-up maximum lag time between tasks (all pop-up dependencies)
    * @param    I_POPUP_LAG_UNIT_MEASURE   Array of pop-up lag time unit measure id (all pop-up dependencies)
    * @param    I_TASKS_RANK               Array that contains the rank of each order set task (used to show the dependency number on the tasks)
    * @param    O_FLG_CONFLICT             Conflict flag to indicate incompatible dependencies network
    * @param    O_MSG_TITLE                Pop-up message title for warnings
    * @param    O_MSG_BODY                 Pop up message body for warnings
    * @param    O_ERROR                    Error message
    *
    * @value    O_FLG_CONFLICT             {*} 'C' closed loop cycle through dependencies was found
    *                                      {*} 'E' from/to dependencies cannot be the equal in the same relationship
    *                                      {*} 'N' No conflicts detected
    *
    * @return   BOOLEAN                    false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/06/08
    ********************************************************************************************/
    FUNCTION check_task_dependencies
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_task         IN order_set_task.id_order_set_task%TYPE,
        i_popup_dependency_type  IN table_number,
        i_popup_dependency       IN table_number,
        i_popup_lag_min          IN table_number,
        i_popup_lag_max          IN table_number,
        i_popup_lag_unit_measure IN table_number,
        i_tasks_rank             IN table_number,
        o_flg_conflict           OUT VARCHAR,
        o_msg_title              OUT VARCHAR,
        o_msg_body               OUT VARCHAR,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set task dependencies
    *
    * @param    I_LANG               Preferred language id
    * @param    I_PROF               Object (ID of professional, ID of institution, ID of software)
    * @param    I_ORDER_SET          Order Set ID
    * @param    I_ORDER_SET_TASK     Order Set task ID
    * @param    I_DEPENDENCY_TYPE    Array of dependency types
    * @param    I_DEPENDENCY         Array of task dependencies
    * @param    I_LAG_MIN            Array of minimum lag time between tasks
    * @param    I_LAG_MAX            Array of maximum lag time between tasks
    * @param    I_LAG_UNIT_MEASURE   Array of lag time unit measure id
    * @param    O_ERROR              Error message
    *
    * @RETURN   BOOLEAN              False in case of error and true otherwise
    *
    * @author                        Tiago Silva
    * @since                         21-JUN-2010
    ********************************************************************************************/
    FUNCTION set_task_dependencies
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_order_set        IN order_set.id_order_set%TYPE,
        i_order_set_task   IN order_set_task.id_order_set_task%TYPE,
        i_dependency_type  IN table_number,
        i_dependency       IN table_number,
        i_lag_min          IN table_number,
        i_lag_max          IN table_number,
        i_lag_unit_measure IN table_number,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all Order sets tasks
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET      Order set ID
    * @param    O_ORDER_SET_TASKS   Cursor with all order set tasks
    * @param    O_TASKS_RANK        Array that contains the rank of each order set task
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/06
    ********************************************************************************************/
    FUNCTION get_order_set_tasks
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_order_set    IN order_set_task.id_order_set%TYPE,
        o_order_set_tasks OUT pk_types.cursor_type,
        o_tasks_rank      OUT table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order sets tasks details and associated advanced inputs
    *
    * @param    I_LANG                         Preferred language ID
    * @param    I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ADVANCED_INPUT            Advanced input ID (if null the advanced input structure is not returned)
    * @param    I_ID_ORDER_SET_TASKS           Array of order set tasks that share the same advanced input
    * @param    I_FLG_DETAIL_TYPE              Type of details for output (if null, all details are returned)
    * @param    O_FIELDS                       Cursor with all advanced input fields
    * @param    O_MULTICHOICE_FIELDS           Cursor with data for advanced input multichoice fields
    * @param    O_FIELDS_DET                   Cursor with advanced input fields details
    * @param    O_FIELDS_UNIT                  Cursor with advanced input fields units
    * @param    O_ORDER_SET_TASKS_DETAILS      Cursor with all order set tasks details
    * @param    O_ORDER_SET_TASKS_INSTR_DESC   Instructions descriptions
    * @param    O_ERROR                        Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/07
    ********************************************************************************************/
    FUNCTION get_order_set_tasks_details
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_id_advanced_input          IN advanced_input.id_advanced_input%TYPE,
        i_id_order_set_tasks         IN table_number,
        i_flg_detail_type            IN table_varchar,
        o_fields                     OUT pk_types.cursor_type,
        o_multichoice_fields         OUT pk_types.cursor_type,
        o_fields_det                 OUT pk_types.cursor_type,
        o_fields_units               OUT pk_types.cursor_type,
        o_order_set_tasks_details    OUT pk_types.cursor_type,
        o_order_set_tasks_instr_desc OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set tasks details (without transaction control parameter)
    *
    * @param    I_LANG                           Preferred language ID
    * @param    I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET                   Order set ID
    * @param    I_ID_ORDER_SET_TASKS             Array of order set tasks
    * @param    I_FLG_VALUE_TYPE                 Value type
    * @param    I_DVALUE                         Date value
    * @param    I_NVALUE                         Number value
    * @param    I_VVALUE                         Varchar value
    * @param    I_FLG_DETAIL_TYPE                Type of detail
    * @param    I_ID_ADVANCED_INPUT              Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field detail ID
    * @param    I_ID_UNIT_MEASURE                Unit measure ID
    * @param    O_DESC_UNION_TASK_INSTR          Descriptions union of all tasks instrutions
    * @param    O_UPDATED_TASKS_INSTRUCTIONS     Cursor with the tasks instructions descriptions that were updated
    * @param    O_UPDATED_SELECTED_TASKS_INFO    Cursor with updated information of the selected tasks
    * @param    O_ERROR                          Error message
    *
    * @value    I_FLG_VALUE_TYPE                 {*} 'D' Date {*} 'N' Number {*} Varchar
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/07
    ********************************************************************************************/
    FUNCTION set_order_set_tasks_details
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set                IN order_set.id_order_set%TYPE,
        i_id_order_set_tasks          IN table_number,
        i_flg_value_type              IN table_table_varchar,
        i_dvalue                      IN table_table_varchar,
        i_nvalue                      IN table_table_number,
        i_vvalue                      IN table_table_varchar,
        i_flg_detail_type             IN table_table_varchar,
        i_id_advanced_input           IN table_table_number,
        i_id_advanced_input_field     IN table_table_number,
        i_id_advanced_input_field_det IN table_table_number,
        i_id_unit_measure             IN table_table_number,
        o_desc_union_task_instr       OUT VARCHAR2,
        o_updated_tasks_instructions  OUT pk_types.cursor_type,
        o_updated_selected_tasks_info OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_set_tasks_instructions
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_root_name            IN VARCHAR2,
        i_tbl_id_pk            IN table_number,
        i_tbl_data             IN table_varchar,
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_table_varchar,
        i_tbl_val_clob         IN table_clob,
        i_tbl_value_mea        IN table_varchar,
        i_flg_origin           IN VARCHAR,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_set_request
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_order_set_process      IN order_set_process.id_order_set_process%TYPE,
        i_clinical_question_pk      IN table_number,
        i_clinical_question         IN table_varchar,
        i_response                  IN table_table_varchar,
        i_order_set_proc_tasks      IN table_number,
        i_order_set_proc_tasks_type IN table_number, ---definir com o ux os ids           
        i_cdr_call                  IN cdr_call.id_cdr_call%TYPE,
        i_flg_force                 IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_msg_warning               OUT VARCHAR2,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set tasks details (with transaction control parameter)
    *
    * @param    I_LANG                           Preferred language ID
    * @param    I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET                   Order set ID
    * @param    I_ID_ORDER_SET_TASKS             Array of order set tasks
    * @param    I_FLG_VALUE_TYPE                 Value type
    * @param    I_DVALUE                         Date value
    * @param    I_NVALUE                         Number value
    * @param    I_VVALUE                         Varchar value
    * @param    I_FLG_DETAIL_TYPE                Type of detail
    * @param    I_ID_ADVANCED_INPUT              Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field detail ID
    * @param    I_ID_UNIT_MEASURE                Unit measure ID
    * @param    I_FLG_PROCESS_DEPENDENCIES       Process dependencies (or not) according to new task details
    * @param    I_COMMIT                         Transaction control parameter
    * @param    O_UPDATED_TASKS_INSTRUCTIONS     Cursor with the tasks instructions descriptions that were updated
    * @param    O_UPDATED_SELECTED_TASKS_INFO    Cursor with updated information of the selected tasks
    * @param    O_ERROR                          Error message
    *
    * @value    I_FLG_VALUE_TYPE                 {*} 'D' Date {*} 'N' Number {*} Varchar
    * @value    I_COMMIT                         {*} 'Y' Commit transaction {*} 'N' Does not commit transaction
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/06/30
    ********************************************************************************************/
    FUNCTION set_odst_tasks_details_intern
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set                IN order_set.id_order_set%TYPE,
        i_id_order_set_tasks          IN table_number,
        i_flg_value_type              IN table_table_varchar,
        i_dvalue                      IN table_table_varchar,
        i_nvalue                      IN table_table_number,
        i_vvalue                      IN table_table_varchar,
        i_flg_detail_type             IN table_table_varchar,
        i_id_advanced_input           IN table_table_number,
        i_id_advanced_input_field     IN table_table_number,
        i_id_advanced_input_field_det IN table_table_number,
        i_id_unit_measure             IN table_table_number,
        i_flg_process_dependencies    IN VARCHAR2,
        i_commit                      IN VARCHAR2,
        o_updated_tasks_instructions  OUT pk_types.cursor_type,
        o_updated_selected_tasks_info OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Create a temporary order set process and associate it to the patient
    *
    * @param    I_LANG                      Preferred language ID
    * @param    I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET              Order set ID
    * @param    I_ID_ORDER_SET_TASKS        Selected order set tasks
    * @param    I_ID_EPISODE                Episode ID
    * @param    I_ID_PATIENT                Patient ID
    * @param    O_ID_ORDER_SET_PROCESS      Id of the order set process created
    * @param    O_FLG_EPISODES_ASSOCIATION  Flag that indicates if the set of selected tasks contains episode tasks and so it is necessary to show the episode association screen
    * @param    O_ERROR                     Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/13
    ********************************************************************************************/
    FUNCTION create_order_set_process
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_order_set             IN order_set_process.id_order_set%TYPE,
        i_id_order_set_tasks       IN table_number,
        i_id_episode               IN order_set_process.id_episode%TYPE,
        i_id_patient               IN order_set_process.id_patient%TYPE,
        o_id_order_set_process     OUT order_set_process.id_order_set_process%TYPE,
        o_flg_episodes_association OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Returns the description of an episode
    *
    * @param    I_LANG                   Preferred language ID for this professional
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_PATIENT                Patient ID
    * @param    I_EPISODE                Episode ID
    *
    * @return   VARCHAR2                 Episode description
    *
    * @author   Tiago Silva
    * @since    2010/07/13
    ********************************************************************************************/
    FUNCTION get_episode_desc
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    *  Get a list of existing episodes to associate with an order set episode task
    *
    * @param    I_LANG                    Preferred language ID for this professional
    * @param    I_PROF                    Object (ID of professional, ID of institution, ID of software)
    * @param    I_PATIENT                 Patient ID
    * @param    I_EPISODE                 Current episode ID
    * @param    I_ORDER_SET_PROCESS       Order set process ID
    * @param    I_ORDER_SET_PROCESS_TASK  Order set episode task ID (Order set process task ID)
    * @param    O_EPISODES_LIST           Cursor with the list of episodes
    * @param    O_ERROR                   Error message
    *
    * @return   BOOLEAN                   False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/07/28
    ********************************************************************************************/
    FUNCTION get_odst_proc_association_epis
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        i_patient IN patient.id_patient%TYPE,
        i_episode IN episode.id_episode%TYPE,
        --i_order_set_process    IN order_set_process.id_order_set_process%type,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE,
        o_episodes_list          OUT pk_types.cursor_type,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all episodes tasks of an order set process
    *
    * @param    I_LANG                   Preferred language ID for this professional
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_PATIENT                Patient ID
    * @param    I_EPISODE                Episode ID
    * @param    I_ORDER_SET_PROCESS      Order set process ID
    * @param    O_EPISODES_LIST          Cursor with list of order set process episodes
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN                  False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/07/11
    ********************************************************************************************/
    FUNCTION get_order_set_proc_episodes
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_patient           IN patient.id_patient%TYPE,
        i_episode           IN episode.id_episode%TYPE,
        i_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_episodes_list     OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Associate an order set process task to an episode
    *
    * @param    i_lang                        Preferred language id
    * @param    i_prof                        Object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task      Order set process task ID that will be associated to the episode task
    * @param    i_episode_task                Episode task ID that will be associated to the order set process task
    * @param    i_flg_new_epis_req            Flag that indicates if this is an association with a new or an existing episode
    * @param    o_error                       Error message
    *
    * @value    i_flg_new_epis_req            {*} 'Y' Association of a new episode
    *                                         {*} 'N' Association of an existing episode
    *
    * @return   Boolean                       False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/07/11
    ********************************************************************************************/
    FUNCTION set_order_set_proc_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE,
        i_episode_task           IN order_set_process_task.id_request%TYPE,
        i_flg_new_epis_req       IN VARCHAR2,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Delete association of an order set process task to an episode
    *
    * @param    i_lang                        Preferred language id
    * @param    i_prof                        Object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task      Order set process task ID from which will be deleted the episode association
    * @param    o_error                       Error message
    *
    * @return   Boolean                       False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2010/07/11
    ********************************************************************************************/
    FUNCTION del_order_set_proc_episode
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE,
        o_error                  OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Check if it is possible to cancel an order set process
    *
    * @param      I_LANG                       Preferred language ID for this professional
    * @param      I_PROF                       Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                 Episode ID
    * @param      I_ID_ORDER_SET_PROCESS       Order set process ID
    *
    * @return     VARCHAR2:                    'Y': order set can be canceled, 'N' order set cannot be canceled
    *
    * @author     Tiago Silva
    * @version    1.0
    * @since      2010/04/28
    */
    FUNCTION check_cancel_order_set_proc
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE
    ) RETURN VARCHAR2;

    /**
    *  Check if a given order set process needs co-sign to be canceled
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                Episode ID
    * @param      I_ID_ORDER_SET_PROCESS      Order set process ID
    * @param      O_ERROR                     Error message
    *
    * @return     VARCHAR2:                   'Y': needs co-sign ; 'N' otherwise
    *
    * @author     Tiago Silva
    * @since      2015/03/24
    */
    FUNCTION check_cancel_odst_proc_cosign
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_flg_needs_cosign     OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /**
    *  Check if a given a list of order set tasks need co-sign to be canceled
    *
    * @param      I_LANG                      Preferred language ID for this professional
    * @param      I_PROF                      Object (ID of professional, ID of institution, ID of software)
    * @param      I_ID_EPISODE                Episode ID
    * @param      I_ID_ORDER_SET_PROC_TASKS   Array of order set process tasks
    * @param      O_ERROR                     Error message
    *
    * @return     VARCHAR2:                   'Y': needs co-sign ; 'N' otherwise
    *
    * @author     Tiago Silva
    * @since      2015/04/21
    */
    FUNCTION check_canc_odst_prc_tsk_cosign
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_episode              IN episode.id_episode%TYPE,
        i_id_order_set_proc_tasks IN table_number,
        o_flg_needs_cosign        OUT VARCHAR2,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if it's possible to cancel an order set process task or not
    *
    * @param    i_lang                      preferred language id
    * @param    i_prof_id                   professional id
    * @param    i_prof_inst                 institution id
    * @param    i_prof_soft                 software id
    * @param    i_episode                   episode ID
    * @param    i_order_set_process_task    order set process task id
    *
    * @return   boolean                     true on success, otherwise false
    *
    * @author                               Tiago Silva
    * @since                                12-AUG-2011
    ********************************************************************************************/
    FUNCTION check_cancel_odst_proc_task
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof_id                IN professional.id_professional%TYPE,
        i_prof_inst              IN institution.id_institution%TYPE,
        i_prof_soft              IN software.id_software%TYPE,
        i_episode                IN episode.id_episode%TYPE,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2 result_cache;

    /********************************************************************************************
    * cancel order set process / mark as deleted
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_id_patient             patient id
    * @param    i_id_episode             episode id
    * @param    i_id_order_set_process   order set id
    * @param    i_id_cancel_reason       reason to cancel the tasks
    * @param    i_cancel_notes           cancel notes
    * @param    i_prof_order             ordering professional
    * @param    i_dt_order               request order date
    * @param    i_order_type             request order type
    * @param    o_error                  error message
    *
    * @return   boolean: false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/13
    ********************************************************************************************/
    FUNCTION cancel_order_set_process
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        i_id_cancel_reason     IN cancel_reason.id_cancel_reason%TYPE,
        i_cancel_notes         IN order_set_process.cancel_notes%TYPE,
        i_prof_order           IN order_set_process.id_prof_order%TYPE,
        i_dt_order             IN VARCHAR2,
        i_order_type           IN order_set_process.id_order_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * convert order set task type id to a cpoe task type id
    *
    * @param    i_order_set_task_type    task type used in order sets
    *
    * @return   number                   task type used in cpoe
    *
    * @author                            Carlos Loureiro
    * @since                             21-Sep-2011
    ********************************************************************************************/
    FUNCTION get_cpoe_task_type(i_order_set_task_type IN task_type.id_task_type%TYPE)
        RETURN cpoe_task_type.id_task_type%TYPE;

    /********************************************************************************************
    * gets a detail value of an order set process task without data transformation
    *
    * @param    i_lang                          preferred language id
    * @param    i_prof                          object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_process_task     order set process task id
    * @param    i_flg_detail_type               type of detail
    * @param    i_id_advanced_input_field       advanced input field id
    *
    * @return   varchar2                        task detail value
    *
    * @author                                   Carlos Loureiro
    * @since                                    16-NOV-2011
    ********************************************************************************************/
    FUNCTION get_proc_task_detail_value
    (
        i_id_order_set_process_task IN order_set_process_task_det.id_order_set_process_task%TYPE,
        i_flg_detail_type           IN order_set_process_task_det.flg_detail_type%TYPE,
        i_id_advanced_input_field   IN order_set_process_task_det.id_advanced_input_field%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Check if the tasks of an order set are in accordance with CPOE parameters.
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_EPISODE             Episode ID
    * @param    I_ID_ORDER_SET_PROCESS   Order set process ID to set as definitive
    * @param    O_TASK_LIST              List of tasks, according to cpoe confirmation grid
    * @param    O_FLG_WARNING_TYPE       Warning type flag
    * @param    O_MSG_TITLE              Message title, according to warning type flag
    * @param    O_MSG_BODY               Message body, according to warning type flag
    * @param    O_PROC_START             CPOE process start timestamp (for new cpoe process)
    * @param    O_PROC_END               CPOE process end timestamp (for new cpoe process)
    * @param    O_PROC_REFRESH           CPOE refresh to draft prescription timestamp (for new cpoe process)
    * @param    O_ERROR                  Error message
    *
    * @value    O_FLG_WARNING_TYPE       {*} 'O' timestamps out of bounds
    *                                    {*} 'C' confirm cpoe creation
    *                                    {*} NULL proceed task creation, without warnings
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/11/30
    ********************************************************************************************/
    FUNCTION check_cpoe_task_creation
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_task_list            OUT pk_types.cursor_type,
        o_flg_warning_type     OUT VARCHAR2,
        o_msg_title            OUT VARCHAR2,
        o_msg_body             OUT VARCHAR2,
        o_proc_start           OUT VARCHAR2,
        o_proc_end             OUT VARCHAR2,
        o_proc_refresh         OUT VARCHAR2,
        o_proc_next_start      OUT VARCHAR2,
        o_proc_next_end        OUT VARCHAR2,
        o_proc_next_refresh    OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if an order set process task should be discarded considering its dependencies
    *
    * @param    i_lang                     preferred language id
    * @param    i_prof                     professional structure
    * @param    i_id_task                  order set task id
    * @param    i_task_dependencies        array of task dependencies
    * @param    i_task_flg_discard         array with the discard values of each task dependency
    * @param    i_dependency_type          network array of relationships (start-2-start or finish-2-start)
    * @param    i_task_dependency_from     network array of task dependencies for the tasks where the dependency comes from
    * @param    i_task_dependency_to       network array of task dependencies for the tasks where the dependency goes to
    * @param    i_task_type_from           network array of task types for the tasks where the dependency comes from
    * @param    i_task_type_to             network array of task types for the tasks where the dependency goes to
    *
    * @return   VARCHAR2                   'Y' task discarded and 'N' task not discarded
    *
    * @author                              Tiago Silva
    * @since                               08-JUL-2011
    ********************************************************************************************/
    FUNCTION check_discard_task_depend
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_task              IN order_set_task.id_order_set_task%TYPE,
        i_task_dependencies    IN table_number,
        i_task_flg_discard     IN table_varchar,
        i_dependency_type      IN table_number,
        i_task_dependency_from IN table_number,
        i_task_dependency_to   IN table_number,
        i_task_type_from       IN table_number,
        i_task_type_to         IN table_number
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * Set tasks discarded by clinical decision rule engine answer
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   professional structure
    * @param    i_id_order_set_process   order set process id
    * @param    i_discarded_tasks        array of discarded tasks (order set process task ids)
    * @param    o_error                  error structure for exception handling
    *
    * @return   boolean                  true on success, otherwise false
    *
    * @author                            Tiago Silva
    * @since                             01-JUL-2011
    ********************************************************************************************/
    FUNCTION set_cdr_discarded_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        i_discarded_tasks      IN table_number,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Reset all order set process tasks marked as discarded
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   professional structure
    * @param    i_id_order_set_process   order set process id
    * @param    o_error                  error structure for exception handling
    *
    * @return   boolean                  true on success, otherwise false
    *
    * @author                            Tiago Silva
    * @since                             01-JUL-2011
    ********************************************************************************************/
    FUNCTION reset_discarded_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get list of accepted and discarded tasks of an order set process
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   professional structure
    * @param    i_id_order_set_process   order set process id
    * @param    o_accepted_tasks         cursor with accepted tasks
    * @param    o_discarded_tasks        cursor with discarded tasks
    * @param    o_flg_prompt             flag that indicates if any prompt should be shown or not (and which is the prompt type)
    * @param    o_error                  error structure for exception handling
    *
    * @value    o_flg_prompt             {*} 'N' should not be shown any prompt
    *                                    {*} 'P' show order set partial request prompt
    *                                    {*} 'R' show order set request problem prompt
    *
    * @return   boolean                  true on success, otherwise false
    *
    * @author                            Tiago Silva
    * @since                             01-JUL-2011
    ********************************************************************************************/
    FUNCTION get_accept_and_discard_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_accepted_tasks       OUT pk_types.cursor_type,
        o_discarded_tasks      OUT pk_types.cursor_type,
        o_flg_prompt           OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set an order set process as definitive
    *
    * @param    i_lang                     preferred language id
    * @param    i_prof                     object (id of professional, id of institution, id of software)
    * @param    i_id_patient               patient id
    * @param    i_id_episode               episode id
    * @param    i_id_order_set_process     order set process id to set as definitive
    * @param    i_clinical_question_ospt   clinical question tasks (order set process task id)
    * @param    i_clinical_question_id     clinical question id
    * @param    i_clinical_question_answer clinical question answer
    * @param    i_clinical_question_notes  clinical question notes
    * @param    i_cdr_call                 clinical decision rules call id
    * @param    o_error                    error message
    *
    * @return   boolean                    false in case of error and true otherwise
    *
    * @author                              Tiago Silva
    * @since                               13-May-2008
    ********************************************************************************************/
    FUNCTION set_order_set_process
    (
        i_lang                     IN language.id_language%TYPE,
        i_prof                     IN profissional,
        i_id_patient               IN patient.id_patient%TYPE,
        i_id_episode               IN episode.id_episode%TYPE,
        i_id_order_set_process     IN order_set_process.id_order_set_process%TYPE,
        i_clinical_question_ospt   IN table_number,
        i_clinical_question_id     IN table_table_number,
        i_clinical_question_answer IN table_table_varchar,
        i_clinical_question_notes  IN table_table_varchar,
        i_cdr_call                 IN cdr_call.id_cdr_call%TYPE,
        i_flg_force                IN VARCHAR2 DEFAULT pk_alert_constant.g_no,
        o_msg_warning              OUT VARCHAR2,
        o_error                    OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_set_diagnosis
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_episode   IN episode.id_episode%TYPE,
        i_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get all frequent order sets that can be applied to the patient
    *
    * @param    I_LANG         Preferred language ID
    * @param    I_PROF         Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT   Patient ID
    * @param    I_ID_EPISODE   Episode ID
    * @param    i_flg_filter   order sets filter
    * @param    i_value        value to search for
    * @param    O_ORDER_SETS   Table with all order sets
    * @param    O_ERROR        Error message
    *
    * @value    i_flg_filter   {*} 'C' filtered by chief complaint
    *                          {*} 'F' all frequent protocols
    *
    * @return   boolean        false in case of error and true otherwise
    *
    * @author                  Tiago Silva
    * @since                   14-May-2008
    ********************************************************************************************/
    FUNCTION get_odst_frequent_search_int
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_flg_filter IN VARCHAR2,
        i_value      IN VARCHAR2
    ) RETURN t_tbl_odst_frequent;

    /********************************************************************************************
    * get all frequent order sets that can be applied to the patient
    *
    * @param    I_LANG         Preferred language ID
    * @param    I_PROF         Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT   Patient ID
    * @param    I_ID_EPISODE   Episode ID
    * @param    i_flg_filter   order sets filter
    * @param    i_value        value to search for
    * @param    O_ORDER_SETS   Cursor with all order sets
    * @param    O_ERROR        Error message
    *
    * @value    i_flg_filter   {*} 'C' filtered by chief complaint
    *                          {*} 'F' all frequent protocols
    *
    * @return   boolean        false in case of error and true otherwise
    *
    * @author                  Tiago Silva
    * @since                   14-May-2008
    ********************************************************************************************/
    FUNCTION get_order_set_frequent_search
    (
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        i_id_patient    IN patient.id_patient%TYPE,
        i_id_episode    IN episode.id_episode%TYPE,
        i_flg_filter    IN VARCHAR2,
        i_value         IN VARCHAR2,
        o_order_sets    OUT pk_types.cursor_type,
        o_change_filter OUT VARCHAR2,
        o_error         OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order sets that can be applied to the patient
    *
    * @param    I_LANG         Preferred language ID
    * @param    I_PROF         Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT   Patient ID
    * @param    I_ID_EPISODE   Episode ID
    * @param    I_VALUE        Value to search for (order set title)
    * @param    O_ORDER_SETS   Cursor with all order sets
    * @param    O_FLG_SHOW     Indicates if a message should be displayed
    * @param    O_MSG          Message to be displayed
    * @param    O_MSG_TITLE    Message title
    * @param    O_BUTTON       Buttons that should appear on the message
    * @param    O_ERROR        Error message
    *
    * @value    O_FLG_SHOW     {*} 'Y' Show message {*} 'N' Don't show the message
    * @value    O_BUTTON       {*} 'N' No button {*} 'R' Read button {*} 'C' Confirm button
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/14
    ********************************************************************************************/
    FUNCTION get_order_set_search
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        i_value      IN VARCHAR2,
        o_order_sets OUT pk_types.cursor_type,
        o_flg_show   OUT VARCHAR2,
        o_msg        OUT VARCHAR2,
        o_msg_title  OUT VARCHAR2,
        o_button     OUT VARCHAR2,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order sets tasks that belongs to a given order set
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET      Order set ID
    * @param    I_ID_PATIENT        Patient ID
    * @param    I_ID_EPISODE        Episode ID
    * @param    I_VALUE             Value to search for (task description)
    * @param    O_ORDER_SET_TASKS   Cursor with all order set tasks
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/14
    ********************************************************************************************/
    FUNCTION get_order_set_tasks_search
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_id_order_set    IN order_set.id_order_set%TYPE,
        i_id_patient      IN patient.id_patient%TYPE,
        i_id_episode      IN episode.id_episode%TYPE,
        i_value           IN VARCHAR2,
        o_order_set_tasks OUT pk_types.cursor_type,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get episode diagnoses (differential diagnoses) to be associated with Order Set tasks
    *
    * @param    I_LANG              Preferred language ID
    * @param    I_PROF              Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT        Patient ID
    * @param    I_ID_EPISODE        Episode ID
    * @param    O_EPIS_DIAGS        Cursor with all episode diagnoses
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/01/26
    ********************************************************************************************/
    FUNCTION get_order_set_epis_diagnoses
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_id_patient IN patient.id_patient%TYPE,
        i_id_episode IN episode.id_episode%TYPE,
        o_epis_diags OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get global notes, additional information and co-sign information of a given order set
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS   Order set process ID
    * @param    O_ORDER_SET_INFO         Cursor with order set process notes and information
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/14
    ********************************************************************************************/
    FUNCTION get_order_set_proc_info_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_order_set_info       OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Set specific order set process global notes, additional information and co-sign information
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS   Order set process ID
    * @param    I_NOTES_GLOBAL           Order set process global notes
    * @param    I_PROF_ORDER             Ordering professional
    * @param    I_DT_ORDER               Request order date
    * @param    I_ORDER_TYPE             Request order type
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/14
    ********************************************************************************************/
    FUNCTION set_order_set_proc_info_notes
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        i_notes_global         IN order_set_process.notes_global%TYPE,
        i_prof_order           IN order_set_process.id_prof_order%TYPE,
        i_dt_order             IN VARCHAR2,
        i_order_type           IN order_set_process.id_order_type%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Check if a given task type needs co-sign to be canceled
    *
    * @param    I_LANG                        Preferred language ID
    * @param    I_PROF_ID                     Professional ID
    * @param    I_PROF_INST                   Institution ID
    * @param    I_PROF_SOFT                   Software ID
    * @param    I_EPISODE                     Episode ID
    * @param    I_TASK_TYPE                   Task type ID
    * @param    I_ID_ORDER_SET_PROCESS_TASK   Order Set process task id
    *
    * @return   VARCHAR2                      Y - needs co-sign; N - otherwise
    *
    * @author   Tiago Silva
    * @since    2015/03/20
    ********************************************************************************************/
    FUNCTION check_cancel_task_needs_cosign
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof_id                   IN professional.id_professional%TYPE,
        i_prof_inst                 IN institution.id_institution%TYPE,
        i_prof_soft                 IN software.id_software%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_id_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE DEFAULT NULL,
        i_task_type                 IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 result_cache;

    /********************************************************************************************
    * Check if a given task type needs co-sign to be ordered
    *
    * @param    I_LANG                        Preferred language ID
    * @param    I_PROF_ID                     Professional ID
    * @param    I_PROF_INST                   Institution ID
    * @param    I_PROF_SOFT                   Software ID
    * @param    I_EPISODE                     Episode ID
    * @param    I_TASK_TYPE                   Task type ID
    * @param    I_ID_ORDER_SET_PROCESS_TASK   Order Set process task id
    *
    * @return   VARCHAR2                      Y - needs co-sign; N - otherwise
    *
    * @author   Tiago Silva
    * @since    2015/03/18
    ********************************************************************************************/
    FUNCTION check_order_task_needs_cosign
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof_id                   IN professional.id_professional%TYPE,
        i_prof_inst                 IN institution.id_institution%TYPE,
        i_prof_soft                 IN software.id_software%TYPE,
        i_episode                   IN episode.id_episode%TYPE,
        i_id_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE DEFAULT NULL,
        i_task_type                 IN task_type.id_task_type%TYPE
    ) RETURN VARCHAR2 result_cache;

    /********************************************************************************************
    * get all tasks of a given order set process
    *
    * @param    i_lang                        preferred language id
    * @param    i_prof                        object (id of professional, id of institution, id of software)
    * @param    i_episode                     episode id
    * @param    i_id_order_set_process        order set process id
    * @param    o_order_set_proc_tasks        cursor with all tasks of the order set process
    * @param    o_order_set_proc_tasks_rank   array with process tasks rank
    * @param    o_error                       error message
    *
    * @return   boolean                       false in case of error and true otherwise
    *
    * @author                                 Tiago Silva
    * @since                                  15-May-2008
    ********************************************************************************************/
    FUNCTION get_order_set_proc_tasks
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_episode                   IN episode.id_episode%TYPE,
        i_id_order_set_process      IN order_set_process_task.id_order_set_process%TYPE,
        o_order_set_proc_tasks      OUT pk_types.cursor_type,
        o_order_set_proc_tasks_rank OUT table_number,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order set process tasks details and associated advanced inputs
    *
    * @param    I_LANG                         Preferred language ID
    * @param    I_PROF                         Object (ID of professional, ID of institution, ID of software)
    * @PARAM    I_EPISODE                      Episode ID
    * @param    I_ID_ADVANCED_INPUT            Advanced input ID (if null the advanced input structure is not returned)
    * @param    I_ID_ORDER_SET_PROC_TASKS      Array of order set process tasks that share the same advanced input
    * @param    I_FLG_DETAIL_TYPE              Type of details for output (if null, all details are returned)
    * @param    O_FIELDS                       Cursor with all advanced input fields
    * @param    O_MULTICHOICE_FIELDS           Cursor with data for advanced input multichoice fields
    * @param    O_FIELDS_DET                   Cursor with advanced input fields details
    * @param    O_FIELDS_UNIT                  Cursor with advanced input fields units
    * @param    O_ODST_PROC_TASKS_DETAILS      Cursor with all order set process tasks details
    * @param    O_ODST_PROC_TASKS_INSTR_DESC   Instructions descriptions
    * @param    O_ERROR                        Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/16
    ********************************************************************************************/
    FUNCTION get_order_set_proc_tasks_det
    (
        i_lang                       IN language.id_language%TYPE,
        i_prof                       IN profissional,
        i_episode                    IN episode.id_episode%TYPE,
        i_id_advanced_input          IN advanced_input.id_advanced_input%TYPE,
        i_id_order_set_proc_tasks    IN table_number,
        i_flg_detail_type            IN table_varchar,
        o_fields                     OUT pk_types.cursor_type,
        o_multichoice_fields         OUT pk_types.cursor_type,
        o_fields_det                 OUT pk_types.cursor_type,
        o_fields_units               OUT pk_types.cursor_type,
        o_odst_proc_tasks_details    OUT pk_types.cursor_type,
        o_odst_proc_tasks_instr_desc OUT VARCHAR2,
        o_error                      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set process tasks details (without transaction control parameter)
    *
    * @param    I_LANG                           Preferred language ID
    * @param    I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS           Order set process ID
    * @param    I_ID_ORDER_SET_PROC_TASKS        Array of order set process tasks
    * @param    I_FLG_VALUE_TYPE                 Value type
    * @param    I_DVALUE                         Date value
    * @param    I_NVALUE                         Number value
    * @param    I_VVALUE                         Varchar value
    * @param    I_FLG_DETAIL_TYPE                Type of detail
    * @param    I_ID_ADVANCED_INPUT              Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field detail ID
    * @param    I_ID_UNIT_MEASURE                Unit measure ID
    * @param    O_DESC_UNION_TASK_INSTR          Descriptions union of all tasks instrutions
    * @param    O_UPDATED_TASKS_INSTRUCTIONS     Cursor with the tasks instructions descriptions that were updated
    * @param    O_UPDATED_SELECTED_TASKS_INFO    Cursor with updated information of the selected tasks
    * @param    O_ERROR                          Error message
    *
    * @value    I_FLG_VALUE_TYPE    {*} 'D' Date {*} 'N' Number {*} Varchar
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/16
    ********************************************************************************************/
    FUNCTION set_order_set_proc_tasks_det
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set_process        IN order_set_process.id_order_set_process%TYPE,
        i_id_order_set_proc_tasks     IN table_number,
        i_flg_value_type              IN table_table_varchar,
        i_dvalue                      IN table_table_varchar,
        i_nvalue                      IN table_table_number,
        i_vvalue                      IN table_table_varchar,
        i_flg_detail_type             IN table_table_varchar,
        i_id_advanced_input           IN table_table_number,
        i_id_advanced_input_field     IN table_table_number,
        i_id_advanced_input_field_det IN table_table_number,
        i_id_unit_measure             IN table_table_number,
        o_desc_union_task_instr       OUT VARCHAR2,
        o_updated_tasks_instructions  OUT pk_types.cursor_type,
        o_updated_selected_tasks_info OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION set_order_set_proc_main_info
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_root_name            IN VARCHAR2,
        i_tbl_id_pk            IN table_number,
        i_tbl_data             IN table_varchar, ---
        i_tbl_ds_internal_name IN table_varchar,
        i_tbl_real_val         IN table_varchar, -- 
        i_tbl_val_clob         IN table_clob, --
        i_tbl_val_array        IN table_table_varchar DEFAULT NULL, --
        i_tbl_val_array_desc   IN table_table_varchar DEFAULT NULL, --
        o_id_order_set_process OUT order_set_process.id_order_set_process%TYPE,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set order set process tasks details (with transaction control parameter)
    *
    * @param    I_LANG                           Preferred language ID
    * @param    I_PROF                           Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS           Order set process ID
    * @param    I_ID_ORDER_SET_PROC_TASKS        Array of order set process tasks
    * @param    I_FLG_VALUE_TYPE                 Value type
    * @param    I_DVALUE                         Date value
    * @param    I_NVALUE                         Number value
    * @param    I_VVALUE                         Varchar value
    * @param    I_FLG_DETAIL_TYPE                Type of detail
    * @param    I_ID_ADVANCED_INPUT              Advanced input ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field ID
    * @param    I_ID_ADVANCED_INPUT_FIELD        Advanced input field detail ID
    * @param    I_ID_UNIT_MEASURE                Unit measure ID
    * @param    I_COMMIT                         Transaction control parameter
    * @param    O_UPDATED_TASKS_INSTRUCTIONS     Cursor with the tasks instructions descriptions that were updated
    * @param    O_UPDATED_SELECTED_TASKS_INFO    Cursor with updated information of the selected tasks
    * @param    O_ERROR                          Error message
    *
    * @value    I_FLG_VALUE_TYPE                 {*} 'D' Date {*} 'N' Number {*} Varchar
    * @value    I_COMMIT                         {*} 'Y' Commit transaction {*} 'N' Does not commit transaction
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2009/06/30
    ********************************************************************************************/
    FUNCTION set_odst_proc_tasks_det_intern
    (
        i_lang                        IN language.id_language%TYPE,
        i_prof                        IN profissional,
        i_id_order_set_process        IN order_set_process.id_order_set_process%TYPE,
        i_id_order_set_proc_tasks     IN table_number,
        i_flg_value_type              IN table_table_varchar,
        i_dvalue                      IN table_table_varchar,
        i_nvalue                      IN table_table_number,
        i_vvalue                      IN table_table_varchar,
        i_flg_detail_type             IN table_table_varchar,
        i_id_advanced_input           IN table_table_number,
        i_id_advanced_input_field     IN table_table_number,
        i_id_advanced_input_field_det IN table_table_number,
        i_id_unit_measure             IN table_table_number,
        i_commit                      IN VARCHAR2,
        o_updated_tasks_instructions  OUT pk_types.cursor_type,
        o_updated_selected_tasks_info OUT pk_types.cursor_type,
        o_error                       OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all order set process tasks applied to the patient
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_PATIENT             Patient ID
    * @param    I_ID_EPISODE             Episode ID
    * @param    I_SEARCH_VALUE           Value to search for
    * @param    O_ORDER_SET_PROC_TASKS   Cursor with all order set process tasks
    * @param    DT_SERVER                Current server time
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/16
    ********************************************************************************************/
    FUNCTION get_applied_order_set_tasks
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN order_set_process.id_patient%TYPE,
        i_id_episode           IN order_set_process.id_episode%TYPE,
        i_search_value         IN VARCHAR2,
        o_order_set_proc_tasks OUT pk_types.cursor_type,
        dt_server              OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all order set processes applied to the patient
    *
    * @param    i_lang                   preferred language id
    * @param    i_prof                   object (id of professional, id of institution, id of software)
    * @param    i_id_patient             patient id
    * @param    i_id_episode             episode id
    * @param    i_search_value           value to search for
    * @param    o_order_set_procs        cursor with all order set processes
    * @param    o_order_set_procs_tasks  cursor with all order set tasks from all processes
    * @param    o_error                  error message
    *
    * @return   boolean                  false in case of error and true otherwise
    *
    * @author                            Tiago Silva
    * @since                             16-May-2008
    ********************************************************************************************/
    FUNCTION get_applied_order_sets
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_patient            IN order_set_process.id_patient%TYPE,
        i_id_episode            IN order_set_process.id_episode%TYPE,
        i_search_value          IN VARCHAR2,
        o_order_set_procs       OUT pk_types.cursor_type,
        o_order_set_procs_tasks OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    *  Get all details of an order set process
    *
    * @param    I_LANG                   Preferred language ID
    * @param    I_PROF                   Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_PROCESS   Order set process ID
    * @param    O_ORDER_SET_PROC_INFO    Cursor with all info of the order set process
    * @param    O_ORDER_SET_PROC_TASKS   Cursor with all tasks of the order set process
    * @param    O_ORDER_SET_ORIG_INFO    Cursor with all info of the original order set
    * @param    O_ORDER_SET_ORIG_TASKS   Cursor with all tasks of the original order set
    * @param    O_ERROR                  Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/19
    ********************************************************************************************/
    FUNCTION get_order_set_details
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        o_order_set_proc_info  OUT pk_types.cursor_type,
        o_order_set_proc_tasks OUT pk_types.cursor_type,
        o_order_set_orig_info  OUT pk_types.cursor_type,
        o_order_set_orig_tasks OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * check if an order set task is available for the given software and institution
    *
    * @param    i_lang            preferred language id
    * @param    i_prof            object (id of professional, id of institution, id of software)
    * @param    i_id_task_type    task type id to verify if it is available
    *
    * @return   number            task type parent id
    *
    * @author                     Carlos Loureiro
    * @since                      06-JUL-2010
    ********************************************************************************************/
    FUNCTION get_task_type_parent
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task_type IN order_set_task_soft_inst.id_task_type%TYPE
    ) RETURN order_set_task_soft_inst.id_task_type_parent%TYPE;

    /********************************************************************************************
    * get all complaints that can be associated to the order sets
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order set id
    * @param      i_value                      search string
    * @param      o_complaints                 cursor with all complaints that can be associated to the order sets
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   02-Dec-2010
    ********************************************************************************************/
    FUNCTION get_complaint_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        i_value        IN VARCHAR2,
        o_complaints   OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get selected reasons for visit associated to a specific order set
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order set id
    * @param      o_reasons                    cursor with all selected reasons for visit associated to order set
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Pedro Portas
    * @since                                   05-May-2014
    ********************************************************************************************/
    FUNCTION get_reasons_for_visit
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_reasons      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all diagnoses/clinical indications associated to the order set
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order set id
    * @param      o_diagnoses                  cursor with all diagnoses associated to the order set
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Tiago Silva
    * @since                                   12-Out-2012
    ********************************************************************************************/
    FUNCTION get_diagnoses_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_diagnoses    OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all diagnoses/clinical indications associated to the order set process
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_patient                 patient id
    * @param      i_id_episode                 episode id
    * @param      i_id_order_set_process       order set process id
    * @param      o_diagnoses                  cursor with all diagnoses associated to the order set process
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Tiago Silva
    * @since                                   17-Out-2012
    ********************************************************************************************/
    FUNCTION get_proc_diagnoses_list
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_id_patient           IN patient.id_patient%TYPE,
        i_id_episode           IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set%TYPE,
        o_diagnoses            OUT pk_types.cursor_type,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all filters for frequent order sets screen
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    patient id
    * @param      i_episode                    episode id
    * @param      o_filters                    cursor with all filters for frequent order sets screen
    * @param      o_order_sets                 cursor with order sets of the default filter
    
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   02-Dec-2010
    ********************************************************************************************/
    FUNCTION get_order_set_filters
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_patient    IN patient.id_patient%TYPE,
        i_episode    IN episode.id_episode%TYPE,
        o_filters    OUT pk_types.cursor_type,
        o_order_sets OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set complaints
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order_set id
    * @param      i_link_complaint             array with complaints
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Carlos Loureiro
    * @since                                   07-Dec-2010
    ********************************************************************************************/
    FUNCTION set_order_set_chief_complaint
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_order_set   IN order_set.id_order_set%TYPE,
        i_link_complaint IN table_number,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set reasons for visit
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_id_order_set               order_set id
    * @param      i_link_reason_visit          array with ids of reasons for visits
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Pedro Portas
    * @since                                   28-Apr-2014
    ********************************************************************************************/
    FUNCTION set_order_set_reason_for_visit
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_order_set      IN order_set.id_order_set%TYPE,
        i_link_reason_visit IN table_number,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set diagnoses/clinical indications
    *
    * @param      i_lang               preferred language id for this professional
    * @param      i_prof               object (id of professional, id of institution, id of software)
    * @param      i_id_order_set       order_set id
    * @param      i_diagnoses          order set clinical indications/diagnoses
    * @param      o_error              error message
    *
    * @return     boolean              true or false on success or error
    *
    * @author                          Tiago Silva
    * @since                           16-Out-2012
    ********************************************************************************************/
    FUNCTION set_order_set_diagnoses
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        i_diagnoses    IN CLOB,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * set order set process diagnoses/clinical indications
    *
    * @param      i_lang                       preferred language id for this professional
    * @param      i_prof                       object (id of professional, id of institution, id of software)
    * @param      i_patient                    Patient id
    * @param      i_episode                    Episode id
    * @param      i_id_order_set_process       order_set process id
    * @param      i_diagnoses                  order set process clinical indications/diagnoses
    * @param      o_error                      error message
    *
    * @return     boolean                      true or false on success or error
    *
    * @author                                  Tiago Silva
    * @since                                   17-Out-2012
    ********************************************************************************************/
    FUNCTION set_order_set_proc_diagnoses
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_patient              IN patient.id_patient%TYPE,
        i_episode              IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process.id_order_set_process%TYPE,
        i_diagnoses            IN CLOB,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get all clinical questions
    *
    * @param    i_lang                        preferred language id
    * @param    i_prof                        object (id of professional, id of institution, id of software)
    * @param    i_id_patient                  patient id
    * @param    i_id_episode                  episode id
    * @param    i_id_order_set_process        temporary order set process id
    * @param    i_order_set_proc_tasks_rank   array with process tasks rank
    * @param    o_order_set_proc_tasks        cursor with all order set process tasks that have clinical questions
    * @param    o_clinical_questions          cursor with all clinical questions associated with order set tasks
    * @param    o_error                       error message
    *
    * @return   boolean                       false in case of error and true otherwise
    *
    * @author                                 Carlos Loureiro
    * @since                                  21-Dec-2010
    ********************************************************************************************/
    FUNCTION get_clinical_questions
    (
        i_lang                      IN language.id_language%TYPE,
        i_prof                      IN profissional,
        i_id_patient                IN patient.id_patient%TYPE,
        i_id_episode                IN episode.id_episode%TYPE,
        i_id_order_set_process      IN order_set_process.id_order_set_process%TYPE,
        i_order_set_proc_tasks_rank IN table_number,
        o_order_set_proc_tasks      OUT pk_types.cursor_type,
        o_clinical_questions        OUT pk_types.cursor_type,
        o_error                     OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * get task type icon
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_task_type           task type id
    * @param    i_id_task             task id (order set id or order set process id)
    * @param    i_flg_process_task    indicate if task id belongs to an order set or an order set process
    * @param    i_flg_episode         indicate if is an episode task or not
    *
    * @value    i_flg_process_task    {*} 'Y' order set process task
    *                                 {*} 'N' order set task
    *
    * @value    i_flg_episode         {*} 'Y' task is an episode
    *                                 {*} 'N' task is not an episode
    *
    * @return   varchar2              task type's icon name
    *
    * @author                         Carlos Loureiro
    * @since                          25-JUL-2011
    ********************************************************************************************/
    FUNCTION get_task_type_icon
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN task_type.id_task_type%TYPE,
        i_id_task          IN order_set_task.id_order_set_task%TYPE,
        i_flg_process_task IN VARCHAR2,
        i_flg_episode      IN VARCHAR2
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get original task type ID used internally by the requested task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_task_type           task type id
    * @param    i_id_task             task id (order set id or order set process id)
    * @param    i_flg_process_task    indicate if task id belongs to an order set or an order set process
    * @param    i_flg_episode         indicate if is an episode task or not
    *
    * @value    i_flg_process_task    {*} 'Y' order set process task
    *                                 {*} 'N' order set task
    *
    * @value    i_flg_episode         {*} 'Y' task is an episode
    *                                 {*} 'N' task is not an episode
    *
    * @return   number                 original task type ID
    *
    * @author                         Carlos Loureiro
    * @since                          25-JUL-2011
    ********************************************************************************************/
    FUNCTION get_task_type_source
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_task_type        IN task_type.id_task_type%TYPE,
        i_id_task          IN order_set_task.id_order_set_task%TYPE,
        i_flg_process_task IN VARCHAR2,
        i_flg_episode      IN VARCHAR2
    ) RETURN NUMBER;
    /********************************************************************************************
    * get order set process task background color to be presented in the instructions field
    *
    * @param    i_lang         preferred language id
    * @param    i_prof         object (id of professional, id of institution, id of software)
    * @param    i_task_type    task type id
    * @param    i_id_task      task id (order set id or order set process id)
    *
    * @return   varchar2       task background color
    *
    * @author                  Tiago Silva
    * @since                   15-Jan-2014
    ********************************************************************************************/
    FUNCTION get_proc_tsk_instr_bg_color
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        i_id_task   IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * get order set process task background alpha to be presented in the instructions field
    *
    * @param    i_lang         preferred language id
    * @param    i_prof         object (id of professional, id of institution, id of software)
    * @param    i_task_type    task type id
    * @param    i_id_task      task id (order set id or order set process id)
    *
    * @return   varchar2       task background color
    *
    * @author                  Tiago Silva
    * @since                   15-Jan-2014
    ********************************************************************************************/
    FUNCTION get_proc_tsk_instr_bg_alpha
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        i_id_task   IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * checks if a task type is controlled in the task type data model or not
    *
    * @param    i_task_type                id task type
    *
    * @return   varchar2                   modular workflow flag (Y-supported
    *
    * @value    check_modular_task_type    {*} 'Y' modular workflow is supported
    *                                      {*} 'N' modular workflow is not supported
    *
    * @author   Tiago Silva
    * @since    19-Jul-2011
    ********************************************************************************************/
    FUNCTION check_modular_task_type(i_task_type task_type.id_task_type%TYPE) RETURN VARCHAR2;

    /********************************************************************************************
    * update new task reference in all order sets that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * update new task process reference in all order set processes that are using the old reference
    *
    * @param       i_lang                    preferred language id for this professional
    * @param       i_prof                    professional structure
    * @param       i_task_type               task type id
    * @param       i_task_ref_old            old task reference (the one that should be updated)
    * @param       i_task_ref_new            new task reference
    * @param       o_error                   error message
    *
    * @return      boolean                   true or false on success or error
    *
    * @author                                Carlos Loureiro
    * @since                                 19-SEP-2011
    ********************************************************************************************/
    FUNCTION update_task_proc_reference
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_task_type    IN task_type.id_task_type%TYPE,
        i_task_ref_old IN order_set_task_link.id_task_link%TYPE,
        i_task_ref_new IN order_set_task_link.id_task_link%TYPE,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * returns string with the description of a specific task
    *
    * @param    i_lang                      preferred language id
    * @param    i_prof                      object (id of professional, id of institution, id of software)
    * @param    i_id_task                   task id
    * @param    i_id_task_type              task type id
    *
    * @return   varchar2:                   string with task description
    *
    * @author                               Carlos Loureiro
    * @since                                25-MAY-2012
    ********************************************************************************************/
    FUNCTION get_group_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_task      IN order_set_task.id_order_set_task%TYPE,
        i_id_task_type IN order_set_task.id_task_type%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * returns group description for a given order set process task
    *
    * @param    i_lang                    preferred language id
    * @param    i_prof                    object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task  order set process task ID
    *
    * @return   varchar2:                 string with task group description
    *
    * @author                             Tiago Silva
    * @since                              05-SEP-2013
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_group_desc
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * returns task group tooltip for a given order set process task
    *
    * @param    i_lang                    preferred language id
    * @param    i_prof                    object (id of professional, id of institution, id of software)
    * @param    i_order_set_process_task  order set process task ID
    *
    * @return   varchar2:                 string with task group tooltip
    *
    * @author                             Tiago Silva
    * @since                              26-AUG-2013
    ********************************************************************************************/
    FUNCTION get_odst_proc_tsk_grp_tooltip
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * returns group rank for a given order set process task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task   order set process task ID
    *
    * @return   varchar2:             string with task group rank
    *
    * @author                         Tiago Silva
    * @since                          05-SEP-2013
    ********************************************************************************************/
    FUNCTION get_odst_proc_task_group_rank
    (
        i_lang                   IN language.id_language%TYPE,
        i_prof                   IN profissional,
        i_order_set_process_task IN order_set_process_task.id_order_set_process_task%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * returns group description for a given order set task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task   order set task ID
    *
    * @return   varchar2:             string with task group description
    *
    * @author                         Tiago Silva
    * @since                          05-JUN-2013
    ********************************************************************************************/
    FUNCTION get_order_set_task_group_desc
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * returns task group tooltip for a given order set task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task   order set task ID
    *
    * @return   varchar2:             string with task group tooltip
    *
    * @author                         Tiago Silva
    * @since                          26-AUG-2014
    ********************************************************************************************/
    FUNCTION get_order_set_tsk_grp_tooltip
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN VARCHAR2;

    /********************************************************************************************
    * returns group rank for a given order set task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task   order set task ID
    *
    * @return   varchar2:             string with task group rank
    *
    * @author                         Tiago Silva
    * @since                          05-JUN-2013
    ********************************************************************************************/
    FUNCTION get_order_set_task_group_rank
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN NUMBER;

    /********************************************************************************************
    * returns list of group ids for a given order set task
    *
    * @param    i_lang                preferred language id
    * @param    i_prof                object (id of professional, id of institution, id of software)
    * @param    i_id_order_set_task   order set task ID
    *
    * @return   table_number          list of task group ids
    *
    * @author                         Tiago Silva
    * @since                          30-AUG-2013
    ********************************************************************************************/
    FUNCTION get_order_set_task_group_ids
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_order_set_task IN order_set_task.id_order_set_task%TYPE
    ) RETURN table_number;

    /********************************************************************************************
    * Get all lab test request details of a lab test request
    *
    * @param    i_lang                  preferred language id
    * @param    i_prof                  object (id of professional, id of institution, id of software)
    * @param    i_lab_test_req          lab test request id
    * @param    o_lab_test_req_det      cursor with the lab test request details
    * @param    o_error                 error message
    *
    * @return   boolean                 false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2013/01/10
    ********************************************************************************************/
    FUNCTION get_lab_test_req_det
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_lab_test_req     IN table_number,
        o_lab_test_req_det OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_lab_test_access_permission
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_order_set_task IN order_set_task.id_order_set_task%TYPE,
        i_flg_type          IN group_access.flg_type%TYPE DEFAULT pk_lab_tests_constant.g_infectious_diseases_orders
    ) RETURN VARCHAR2;

    FUNCTION get_epis_hidrics
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_epis_hidrics IN epis_hidrics.id_epis_hidrics%TYPE,
        o_epis_hid     OUT NOCOPY pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all exam request details of a exam request
    *
    * @param    i_lang                  preferred language id
    * @param    i_prof                  object (id of professional, id of institution, id of software)
    * @param    i_exam_req              exam request id
    * @param    o_exam_req_det          cursor with the exam request details
    * @param    o_error                 error message
    *
    * @return   boolean                 false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2013/01/10
    ********************************************************************************************/
    FUNCTION get_exam_req_det
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_exam_req     IN table_number,
        o_exam_req_det OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Set task groups for a list of order set tasks
    *
    * @param    i_lang                 preferred language id
    * @param    i_prof                 object (id of professional, id of institution, id of software)
    * @param    i_order_set_tasks      list of order set tasks
    * @param    i_task_groups          list of task groups
    * @param    o_error                error message
    *
    * @return   boolean                false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2013/06/03
    ********************************************************************************************/
    FUNCTION set_tasks_groups
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_order_set_tasks IN table_number,
        i_task_groups     IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Remove all task groups of a list of order set tasks
    *
    * @param    i_lang                 preferred language id
    * @param    i_prof                 object (id of professional, id of institution, id of software)
    * @param    i_order_set_tasks      list of order set tasks
    * @param    o_error                error message
    *
    * @return   boolean                false in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2013/06/03
    ********************************************************************************************/
    FUNCTION remove_tasks_groups
    (
        i_lang            IN language.id_language%TYPE,
        i_prof            IN profissional,
        i_order_set_tasks IN table_number,
        o_error           OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_hdrcs_tsk_tp_by_tsk_ty(i_task_type task_type.id_task_type%TYPE) RETURN NUMBER;

    /********************************************************************************************
    *  Gets the list of order sets available on the tools area that could be used as originals to copy tasks
    *
    * @param    I_LANG         Preferred language ID
    * @param    I_PROF         Object (ID of professional, ID of institution, ID of software)
    * @param    I_VALUE        Value to search for (order set title)
    * @param    O_ORDER_SETS   Cursor with all order sets
    * @param    O_ERROR        Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2013/09/02
    ********************************************************************************************/
    FUNCTION get_order_sets_to_copy
    (
        i_lang       IN language.id_language%TYPE,
        i_prof       IN profissional,
        i_value      IN VARCHAR2,
        o_order_sets OUT pk_types.cursor_type,
        o_error      OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Get all tasks that belongs to a given order set used as original to make copies to other order sets
    *
    * @param    I_LANG               Preferred language ID
    * @param    I_PROF               Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_ORIG  Order set ID (origin)
    * @param    I_ID_ORDER_SET_DEST  Order set ID (destination)
    * @param    I_VALUE             Value to search for (task description)
    * @param    O_ORDER_SET_TASKS   Cursor with all order set tasks
    * @param    O_ERROR             Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @version  1.0
    * @since    2008/05/14
    ********************************************************************************************/
    FUNCTION get_order_set_tasks_to_copy
    (
        i_lang              IN language.id_language%TYPE,
        i_prof              IN profissional,
        i_id_order_set_orig IN order_set.id_order_set%TYPE,
        i_id_order_set_dest IN order_set.id_order_set%TYPE,
        i_value             IN VARCHAR2,
        o_order_set_tasks   OUT pk_types.cursor_type,
        o_error             OUT t_error_out
    ) RETURN BOOLEAN;

    /********************************************************************************************
    * Copy order set tasks from other order sets to a given order set
    *
    * @param    I_LANG                     Preferred language ID
    * @param    I_PROF                     Object (ID of professional, ID of institution, ID of software)
    * @param    I_ID_ORDER_SET_DEST        Order set destination ID
    * @param    I_ORDER_SET_TASKS_TO_COPY  Array of order set task ids to copy (can be from different order sets)
    * @param    O_NEW_ORDER_SET_TASKS      Cursor with new order set tasks ids
    * @param    O_ERROR                    Error message
    *
    * @return   BOOLEAN: False in case of error and true otherwise
    *
    * @author   Tiago Silva
    * @since    2013/09/04
    ********************************************************************************************/
    FUNCTION copy_tasks_to_order_set
    (
        i_lang                    IN language.id_language%TYPE,
        i_prof                    IN profissional,
        i_id_order_set_dest       IN order_set.id_order_set%TYPE,
        i_order_set_tasks_to_copy IN table_number,
        o_new_order_set_tasks     OUT pk_types.cursor_type,
        o_error                   OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_os_generic_task_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_order_set_bo_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_order_set_fo_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_os_monitoring_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_os_appointment_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_os_discharge_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_os_personalised_diet_form_values
    (
        i_lang           IN NUMBER,
        i_prof           IN profissional,
        i_episode        IN NUMBER,
        i_patient        IN NUMBER,
        i_action         IN NUMBER,
        i_root_name      IN VARCHAR2,
        i_curr_component IN NUMBER,
        i_idx            IN NUMBER DEFAULT 1,
        i_tbl_id_pk      IN table_number,
        i_tbl_mkt_rel    IN table_number,
        i_tbl_int_name   IN table_varchar,
        i_value          IN table_table_varchar,
        i_value_mea      IN table_table_varchar,
        i_value_desc     IN table_table_varchar,
        i_tbl_data       IN table_table_varchar,
        i_value_clob     IN table_clob,
        o_error          OUT t_error_out
    ) RETURN t_tbl_ds_get_value;

    FUNCTION get_odst_diagnosis_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_reason_for_visit_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_order_set_type_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_institution_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_department_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_clin_serv_desc
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_odst_detail
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_order_set IN order_set.id_order_set%TYPE,
        o_detail    OUT pk_types.cursor_type,
        o_error     OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION tf_get_odst_tasks_details
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set_task.id_order_set%TYPE
    ) RETURN t_table_osdt_task;

    PROCEDURE get_os_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    PROCEDURE get_os_epi_init_parameters
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_os_actions_bo
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_actions      OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_services_list
    (
        i_lang     IN language.id_language%TYPE,
        i_prof     IN profissional,
        i_tbl_dept IN table_varchar
    ) RETURN t_tbl_core_domain;

    FUNCTION check_order_set_co_sign
    (
        i_lang                 IN language.id_language%TYPE,
        i_prof                 IN profissional,
        i_episode              IN episode.id_episode%TYPE,
        i_id_order_set_process IN order_set_process_task.id_order_set_process%TYPE,
        o_co_sign_needed       OUT VARCHAR2,
        o_error                OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_flg_has_clin_quest
    (
        i_lang      IN language.id_language%TYPE,
        i_prof      IN profissional,
        i_task_type IN task_type.id_task_type%TYPE,
        i_id_task   IN order_set_task.id_order_set_task%TYPE
    ) RETURN VARCHAR2;

    FUNCTION get_full_items_by_screen
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_patient     IN NUMBER,
        i_episode     IN NUMBER,
        i_screen_name IN VARCHAR2,
        i_action      IN NUMBER,
        o_components  OUT t_clin_quest_table,
        o_ds_target   OUT t_clin_quest_target_table,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN;

    PROCEDURE init_params_complaint
    (
        i_filter_name   IN VARCHAR2,
        i_custom_filter IN NUMBER,
        i_context_ids   IN table_number,
        i_context_keys  IN table_varchar DEFAULT NULL,
        i_context_vals  IN table_varchar,
        i_name          IN VARCHAR2,
        o_vc2           OUT VARCHAR2,
        o_num           OUT NUMBER,
        o_id            OUT NUMBER,
        o_tstz          OUT TIMESTAMP WITH LOCAL TIME ZONE
    );

    FUNCTION get_order_set_type_list
    (
        i_lang           IN language.id_language%TYPE,
        i_prof           IN profissional,
        i_id_order_set   IN order_set.id_order_set%TYPE,
        o_order_set_type OUT pk_types.cursor_type,
        o_error          OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_odst_edit_permission_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_values       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_odst_use_permission_list
    (
        i_lang         IN language.id_language%TYPE,
        i_prof         IN profissional,
        i_id_order_set IN order_set.id_order_set%TYPE,
        o_values       OUT pk_types.cursor_type,
        o_error        OUT t_error_out
    ) RETURN BOOLEAN;

    FUNCTION get_order_set_environment_list
    (
        i_lang                  IN language.id_language%TYPE,
        i_prof                  IN profissional,
        i_id_order_set          IN order_set.id_order_set%TYPE,
        o_order_set_environment OUT pk_types.cursor_type,
        o_error                 OUT t_error_out
    ) RETURN BOOLEAN;
    ---------------------------------------------------------------------------------------------------------------------------
    ---------------------------------------------------------------------------------------------------------------------------

    -- General declarations
    g_active               CONSTANT VARCHAR2(1 CHAR) := 'A';
    g_inactive             CONSTANT VARCHAR2(1 CHAR) := 'I';
    g_available            CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_not_available        CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_yes                  CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_no                   CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_selected             CONSTANT VARCHAR2(1 CHAR) := 'Y';
    g_not_selected         CONSTANT VARCHAR2(1 CHAR) := 'N';
    g_all_institution      CONSTANT institution.id_institution%TYPE := 0;
    g_all_software         CONSTANT software.id_software%TYPE := 0;
    g_all_markets          CONSTANT market.id_market%TYPE := 0;
    g_all_profile_template CONSTANT profile_template.id_profile_template%TYPE := 0;
    g_separator            CONSTANT VARCHAR2(2) := '; ';
    g_separator2           CONSTANT VARCHAR2(2) := ', ';

    -- Prescription configurations
    g_config_prescription_type CONSTANT sys_domain.code_domain%TYPE := 'PRESCRIPTION_TYPE';
    g_drug                     CONSTANT VARCHAR2(1 CHAR) := 'M';

    -- Diagnosis configurations
    --g_config_epis_diags_other  CONSTANT sys_config.id_sys_config%TYPE := 'PERMISSION_FOR_OTHER_DIAGNOSIS';
    g_config_auto_fill_diag   CONSTANT sys_config.id_sys_config%TYPE := 'ORDER_SETS_AUTO_FILL_CLINICAL_INDICATION';
    g_epis_diags_flg_type_def CONSTANT epis_diagnosis.flg_type%TYPE := 'D';

    -- Messages
    g_message_all              CONSTANT sys_message.code_message%TYPE := 'COMMON_M014';
    g_message_add              CONSTANT sys_message.code_message%TYPE := 'ORDER_SET_M005';
    g_message_day              CONSTANT sys_message.code_message%TYPE := 'COMMON_M019';
    g_message_days             CONSTANT sys_message.code_message%TYPE := 'COMMON_M020';
    g_message_search_diags     CONSTANT sys_message.code_message%TYPE := 'ORDER_SET_M008';
    g_message_multiple_val     CONSTANT sys_message.code_message%TYPE := 'ORDER_SET_M009';
    g_message_na               CONSTANT sys_message.code_message%TYPE := 'COMMON_M036';
    g_message_order_set_tasks  CONSTANT sys_message.code_message%TYPE := 'ORDER_SET_M020';
    g_message_reason_for_visit CONSTANT sys_message.code_message%TYPE := 'ORDER_SET_M027';

    -- Task details
    g_task_det_adv_input          CONSTANT order_set_task_detail.flg_detail_type%TYPE := 'A';
    g_adv_input_field_selected    CONSTANT order_set_task_detail.id_advanced_input_field%TYPE := 90;
    g_task_det_value_type_number  CONSTANT order_set_task_detail.flg_value_type%TYPE := 'N';
    g_task_det_value_type_varchar CONSTANT order_set_task_detail.flg_value_type%TYPE := 'V';
    g_task_det_value_type_date    CONSTANT order_set_task_detail.flg_value_type%TYPE := 'D';

    -- Task descriptions formats
    g_task_desc_short_format    CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_task_desc_extended_format CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_task_desc_detail_format   CONSTANT VARCHAR2(1 CHAR) := 'D';

    -- Task detail types
    g_tsk_det_type_follow_in     CONSTANT sys_domain.val%TYPE := 'U'; -- Discharge instructions: follow-up in
    g_tsk_det_type_follow_with   CONSTANT sys_domain.val%TYPE := 'F'; -- Discharge instructions: follow-up with
    g_tsk_det_type_prof          CONSTANT sys_domain.val%TYPE := 'P'; -- Professional
    g_tsk_det_type_diag          CONSTANT sys_domain.val%TYPE := 'M'; -- Diagnosis
    g_tsk_det_type_inp_adm       CONSTANT sys_domain.val%TYPE := 'O'; -- Inpatient: indication for admission
    g_tsk_det_type_surg_proc     CONSTANT sys_domain.val%TYPE := 'J'; -- Inpatient: surgical procedure
    g_tsk_det_type_appoint_locat CONSTANT sys_domain.val%TYPE := 'L'; -- Appointment: location
    g_tsk_det_type_appoint_type  CONSTANT sys_domain.val%TYPE := 'B'; -- Appointment: type of appointment
    g_tsk_det_type_place_serv    CONSTANT sys_domain.val%TYPE := 'K'; -- Lab test: place of service

    -- Task link types
    g_task_link_null         CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'N';
    g_task_link_analysis     CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'A';
    g_task_link_exam         CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'E';
    g_task_link_group        CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'G';
    g_task_link_codification CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'C';
    g_task_link_predefined   CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'P';
    g_task_link_clin_serv    CONSTANT order_set_task_link.flg_task_link_type%TYPE := 'L';

    -- Task link types weights
    g_task_link_null_weight     CONSTANT NUMBER := 2;
    g_task_link_analysis_weight CONSTANT NUMBER := 2;
    g_task_link_exam_weight     CONSTANT NUMBER := 2;
    g_task_link_group_weight    CONSTANT NUMBER := 1;

    -- subjects for actions
    g_action_order_set_exec CONSTANT action.subject%TYPE := 'ORDER_SETS_EXECUTE';

    -- Domains
    g_odst_target_profs_domain    CONSTANT sys_domain.code_domain%TYPE := 'ORDER_SET.FLG_TARGET_PROFESSIONALS';
    g_odst_edit_perms_domain      CONSTANT sys_domain.code_domain%TYPE := 'ORDER_SET.FLG_EDIT_PERMISSIONS';
    g_odst_ptsk_flg_status_domain CONSTANT sys_domain.code_domain%TYPE := 'ORDER_SET_PROCESS_TASK.FLG_STATUS';
    g_odst_tsk_flg_status_domain  CONSTANT sys_domain.code_domain%TYPE := 'ORDER_SET_PROCESS.FLG_STATUS';
    g_dependency_episode_domain   CONSTANT sys_domain.code_domain%TYPE := 'DEPENDENCY_EPISODE';
    g_odst_tsks_order_stat_domain CONSTANT sys_domain.code_domain%TYPE := 'ORDER_SET_TASKS_ORDER_STATUS';

    -- Domain values
    -- 'EXAM_REC.FLG_TYPE' and 'MONITORIZATION.FLG_TIME' domain values
    g_flg_time_epis CONSTANT sys_domain.val%TYPE := 'E';
    g_flg_time_next CONSTANT sys_domain.val%TYPE := 'N';
    g_flg_time_btw  CONSTANT sys_domain.val%TYPE := 'B';

    -- Order set tasks
    g_odst_task_group_appoints     CONSTANT order_set_task.id_task_type%TYPE := 1;
    g_odst_task_followup_appoint   CONSTANT order_set_task.id_task_type%TYPE := 2;
    g_odst_task_specialty_appoint  CONSTANT order_set_task.id_task_type%TYPE := 3;
    g_odst_task_consult            CONSTANT order_set_task.id_task_type%TYPE := 4;
    g_odst_task_discharge_instruct CONSTANT order_set_task.id_task_type%TYPE := 5;
    g_odst_task_image_exam         CONSTANT order_set_task.id_task_type%TYPE := 7;
    g_odst_task_other_exam         CONSTANT order_set_task.id_task_type%TYPE := 8;
    g_odst_task_monitoring         CONSTANT order_set_task.id_task_type%TYPE := 9;
    g_odst_task_procedure          CONSTANT order_set_task.id_task_type%TYPE := 43;
    g_odst_task_analysis           CONSTANT order_set_task.id_task_type%TYPE := 11;
    g_odst_task_local_drug         CONSTANT order_set_task.id_task_type%TYPE := 13; -- old medication task type: do not use!
    g_odst_task_ext_drug           CONSTANT order_set_task.id_task_type%TYPE := 15; -- old medication task type: do not use!
    g_odst_task_predef_diet        CONSTANT order_set_task.id_task_type%TYPE := 22;
    g_odst_task_appoint_social     CONSTANT order_set_task.id_task_type%TYPE := 28;
    g_odst_task_appoint_nurse      CONSTANT order_set_task.id_task_type%TYPE := 29;
    g_odst_task_appoint_medical    CONSTANT order_set_task.id_task_type%TYPE := 30;
    g_odst_task_appoint_nutrition  CONSTANT order_set_task.id_task_type%TYPE := 31;
    g_odst_task_appoint_psychology CONSTANT order_set_task.id_task_type%TYPE := 32;
    g_odst_task_appoint_rehabilit  CONSTANT order_set_task.id_task_type%TYPE := 33;
    g_odst_task_inpatient          CONSTANT order_set_task.id_task_type%TYPE := 34;
    g_odst_task_inp_surg           CONSTANT order_set_task.id_task_type%TYPE := 35;
    g_odst_task_group_episodes     CONSTANT order_set_task.id_task_type%TYPE := 36;
    g_odst_task_inpatient_ptbr     CONSTANT order_set_task.id_task_type%TYPE := 40;
    g_odst_task_inp_surg_ptbr      CONSTANT order_set_task.id_task_type%TYPE := 41;
    g_odst_task_patient_education  CONSTANT order_set_task.id_task_type%TYPE := 42;
    g_odst_task_medication         CONSTANT order_set_task.id_task_type%TYPE := 51;
    g_odst_task_instit_diet        CONSTANT order_set_task.id_task_type%TYPE := 53;
    g_odst_task_ivfluid_new        CONSTANT order_set_task.id_task_type%TYPE := 55; -- old medication task type: do not use!
    g_odst_task_ivfluid            CONSTANT order_set_task.id_task_type%TYPE := 56; -- old medication task type: do not use!
    g_odst_task_ivfluid_most_freq  CONSTANT order_set_task.id_task_type%TYPE := 57; -- old medication task type: do not use!
    g_odst_task_comm_order         CONSTANT order_set_task.id_task_type%TYPE := 83;
    g_odst_task_supplies           CONSTANT order_set_task.id_task_type%TYPE := 96;
    g_odst_task_surg_supplies      CONSTANT order_set_task.id_task_type%TYPE := 97;
    g_odst_task_medical_order      CONSTANT order_set_task.id_task_type%TYPE := 147;

    g_odst_task_intake_output    CONSTANT order_set_task.id_task_type%TYPE := 106;
    g_odst_task_intake           CONSTANT order_set_task.id_task_type%TYPE := 107;
    g_odst_task_urinary_output   CONSTANT order_set_task.id_task_type%TYPE := 109;
    g_odst_task_drainage_records CONSTANT order_set_task.id_task_type%TYPE := 110;
    g_odst_task_all_output       CONSTANT order_set_task.id_task_type%TYPE := 111;
    g_odst_task_irrigation       CONSTANT order_set_task.id_task_type%TYPE := 112;
    g_odst_task_bp               CONSTANT order_set_task.id_task_type%TYPE := 131;

    -- Order set additional information
    g_order_set_add_info_yes CONSTANT VARCHAR2(1 CHAR) := 'Y';

    -- Order set edit permissions
    g_order_set_edit_perm_none CONSTANT order_set.flg_edit_permissions%TYPE := 'N';
    g_order_set_edit_perm_spec CONSTANT order_set.flg_edit_permissions%TYPE := 'S';
    g_order_set_edit_perm_cat  CONSTANT order_set.flg_edit_permissions%TYPE := 'C';
    g_order_set_edit_perm_all  CONSTANT order_set.flg_edit_permissions%TYPE := 'A';

    -- Order set target professionals
    g_order_set_target_profs_none CONSTANT order_set.flg_edit_permissions%TYPE := 'N';
    g_order_set_target_profs_spec CONSTANT order_set.flg_edit_permissions%TYPE := 'S';
    g_order_set_target_profs_cat  CONSTANT order_set.flg_edit_permissions%TYPE := 'C';
    g_order_set_target_profs_all  CONSTANT order_set.flg_edit_permissions%TYPE := 'A';

    -- Order set links
    g_order_set_link_envi         CONSTANT order_set_link.flg_link_type%TYPE := 'E';
    g_order_set_link_spec         CONSTANT order_set_link.flg_link_type%TYPE := 'S';
    g_order_set_link_chief_compl  CONSTANT order_set_link.flg_link_type%TYPE := 'C';
    g_order_set_link_reason_visit CONSTANT order_set_link.flg_link_type%TYPE := 'R';
    g_order_set_link_odst_type    CONSTANT order_set_link.flg_link_type%TYPE := 'T';
    g_order_set_link_institution  CONSTANT order_set_link.flg_link_type%TYPE := 'I';
    g_order_set_link_clin_serv    CONSTANT order_set_link.flg_link_type%TYPE := 'D';

    -- Order set types
    g_order_set_type_mng CONSTANT sys_list.id_sys_list%TYPE := 11513;
    g_order_set_type_prv CONSTANT sys_list.id_sys_list%TYPE := 11514;
    g_order_set_type_scr CONSTANT sys_list.id_sys_list%TYPE := 11515;
    g_order_set_type_trt CONSTANT sys_list.id_sys_list%TYPE := 11516;

    -- Frequent order set filter types
    g_order_set_filter_chief_compl CONSTANT VARCHAR2(1 CHAR) := 'C';
    g_order_set_filter_diagnosis   CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_order_set_filter_frequent    CONSTANT VARCHAR2(1 CHAR) := 'F';
    g_order_set_filter_odst_type   CONSTANT VARCHAR2(1 CHAR) := 'O';
    g_order_set_filter_odst_mng    CONSTANT VARCHAR2(1 CHAR) := 'M';
    g_order_set_filter_odst_prv    CONSTANT VARCHAR2(1 CHAR) := 'P';
    g_order_set_filter_odst_scr    CONSTANT VARCHAR2(1 CHAR) := 'S';
    g_order_set_filter_odst_trt    CONSTANT VARCHAR2(1 CHAR) := 'T';

    -- Order set process states
    g_order_set_proc_temp        CONSTANT order_set_process.flg_status%TYPE := 'T';
    g_order_set_proc_finished    CONSTANT order_set_process.flg_status%TYPE := 'F';
    g_order_set_proc_canceled    CONSTANT order_set_process.flg_status%TYPE := 'C';
    g_order_set_proc_running     CONSTANT order_set_process.flg_status%TYPE := 'R';
    g_order_set_proc_interrupted CONSTANT order_set_process.flg_status%TYPE := 'I';

    -- Order set process task states
    g_order_set_proc_tsk_temp     CONSTANT order_set_process_task.flg_status%TYPE := 'T';
    g_order_set_proc_tsk_finished CONSTANT order_set_process_task.flg_status%TYPE := 'F';
    g_order_set_proc_tsk_canceled CONSTANT order_set_process_task.flg_status%TYPE := 'C';
    g_order_set_proc_tsk_running  CONSTANT order_set_process_task.flg_status%TYPE := 'R';

    -- scheduled message to be used by task status icons
    g_order_set_proc_tsk_sched_msg CONSTANT sys_message.code_message%TYPE := 'ICON_T056';

    -- Weights of order set process task states
    g_odst_proc_tsk_temp_weight CONSTANT NUMBER := 4;
    g_odst_proc_tsk_run_weight  CONSTANT NUMBER := 3;
    g_odst_proc_tsk_fin_weight  CONSTANT NUMBER := 2;
    g_odst_proc_tsk_can_weight  CONSTANT NUMBER := 1;

    -- Order set states
    g_order_set_temp       CONSTANT order_set.flg_status%TYPE := 'T';
    g_order_set_finished   CONSTANT order_set.flg_status%TYPE := 'F';
    g_order_set_deleted    CONSTANT order_set.flg_status%TYPE := 'C';
    g_order_set_deprecated CONSTANT order_set.flg_status%TYPE := 'D';

    -- Order set edit options
    g_order_set_editable   CONSTANT VARCHAR2(1 CHAR) := 'E';
    g_order_set_duplicable CONSTANT VARCHAR2(1 CHAR) := 'D';
    g_order_set_viewable   CONSTANT VARCHAR2(1 CHAR) := 'V';

    -- Dependencies from episodes (CODE_DOMAIN = 'DEPENDENCY_EPISODE')
    g_depend_current_epis CONSTANT sys_domain.val%TYPE := '-1';
    g_depend_future_epis  CONSTANT sys_domain.val%TYPE := '-2';

    -- Order set process task discard type
    g_task_not_discard     CONSTANT order_set_process_task.flg_discard_type%TYPE := 'N';
    g_task_discard_cdr     CONSTANT order_set_process_task.flg_discard_type%TYPE := 'C';
    g_task_discard_depends CONSTANT order_set_process_task.flg_discard_type%TYPE := 'D';

    -- modular workflow task type
    g_modular_workflow_support    CONSTANT task_type.flg_modular_workflow%TYPE := 'Y';
    g_modular_workflow_no_support CONSTANT task_type.flg_modular_workflow%TYPE := 'N';

    -- context areas
    g_context_order_set_tools CONSTANT VARCHAR2(30 CHAR) := 'ORDER_SET_TOOLS';
    g_context_order_set_ehr   CONSTANT VARCHAR2(30 CHAR) := 'ORDER_SET_EHR';

    --Order set action
    g_order_set_edit         CONSTANT NUMBER := 1426;
    g_order_set_duplicate    CONSTANT NUMBER := 1427;
    g_order_set_bo_edit_task CONSTANT NUMBER := 1655;
    g_order_set_fo_request   CONSTANT NUMBER := 1806;

    --Order set origin (B-Backoffice/F-Front office)
    g_backoffice_origin  CONSTANT VARCHAR2(1 CHAR) := 'B';
    g_frontoffice_origin CONSTANT VARCHAR2(1 CHAR) := 'F';

    -- Exception for dml errors
    dml_errors EXCEPTION;
    PRAGMA EXCEPTION_INIT(dml_errors, -24381);

    --the product can be prescribed but only with cosign
    g_allowed_with_cosign CONSTANT pk_types.t_flg_char := 'C';

    g_sysdate_tstz TIMESTAMP WITH LOCAL TIME ZONE;
    g_other_exception EXCEPTION;

END pk_order_sets;
/
