CREATE OR REPLACE PACKAGE BODY pk_todo_list_ux IS

    /******************************************************************************
    * Returns pending and depending tasks to show on To-Do List.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_pending         All pending tasks ("my pending tasks")
    * @param o_depending       All tasks depending on others
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-May-21
    *
    ******************************************************************************/
    FUNCTION get_todo_list
    (
        i_lang    IN language.id_language%TYPE,
        i_prof    IN profissional,
        o_pending OUT pk_types.cursor_type,
        o_error   OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_todo_list.get_todo_list(i_lang    => i_lang,
                                          i_prof    => i_prof,
                                          o_pending => o_pending,
                                          o_error   => o_error);
    
    END get_todo_list;

    /******************************************************************************
    * Returns all options displayed in the views button.
    *
    * @param i_lang            Professional preferred language
    * @param i_prof            Professional executing the action
    * @param o_list            View button options
    * @param o_error           Error message
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Jose Brito
    * @version                 0.1
    * @since                   2008-Nov-05
    *
    ******************************************************************************/
    FUNCTION get_todo_list_views
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_list  OUT pk_types.cursor_type,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_todo_list.get_todo_list_views(i_lang  => i_lang,
                                                i_prof  => i_prof,
                                                o_list  => o_list,
                                                o_error => o_error);
    
    END get_todo_list_views;

    --
    /******************************************************************************
    * Returns the to-do list task count
    *
    * @param i_lang            Language ID
    * @param i_prof            Professional info
    * @param o_count           Task count
    * @param o_error           Error information
    *
    * @return                  TRUE if succeeded, FALSE otherwise
    *
    * @author                  Sergio Dias
    * @version                 2.6.4.2.2
    * @since                   27-10-2014
    *
    ******************************************************************************/
    FUNCTION get_todo_list_count
    (
        i_lang  IN language.id_language%TYPE,
        i_prof  IN profissional,
        o_count OUT NUMBER,
        o_error OUT t_error_out
    ) RETURN BOOLEAN IS
    BEGIN
    
        RETURN pk_todo_list.get_todo_list_count(i_lang  => i_lang,
                                                i_prof  => i_prof,
                                                o_count => o_count,
                                                o_error => o_error);
    END get_todo_list_count;

BEGIN
    pk_alertlog.log_init(pk_alertlog.who_am_i);
END pk_todo_list_ux;
/
