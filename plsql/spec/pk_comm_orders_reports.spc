/*-- Last Change Revision: $Rev: 1918471 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2019-09-30 16:29:44 +0100 (seg, 30 set 2019) $*/

CREATE OR REPLACE PACKAGE pk_comm_orders_reports IS

    -- Author  : ANA.MONTEIRO
    -- Created : 03-03-2014 16:45:36
    -- Purpose :     

    /**
    * Gets communication order requests to be shown in detail screen
    *
    * @param   i_lang                       Professional preferred language
    * @param   i_prof                       Professional identification and its context (institution and software)    
    * @param   i_id_episode                 Episode identifier
    * @param   i_flg_scope                  Scope
    * @param   i_flg_show_history           Flag to indicate if history is shown
    * @param   i_flg_show_cancel            Flag to indicate if cancelled communication order requests are shown
    * @param   o_title_info                 Communication order request status and title descriptions
    * @param   o_detail_info                Communication order request information
    * @param   o_error                      Error information
    *
    * @value   i_flg_scope                  {*} P- patient {*} E- episode {*} V- visit
    * @value   i_flg_show_history           {*} Y- show history {*} N- otherwise
    * @value   i_flg_show_cancel            {*} Y- show cancelled records {*} N- otherwise
    *
    * @return  boolean                      True on sucess, otherwise false
    *
    * @author  ana.monteiro
    * @version 1.0
    * @since   24-02-2014
    */
    FUNCTION get_comm_orders_req_detail
    (
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_id_episode       IN comm_order_req.id_episode%TYPE,
        i_flg_scope        IN VARCHAR2,
        i_flg_show_history IN VARCHAR2,
        i_flg_show_cancel  IN VARCHAR2,
        i_id_task_type     IN task_type.id_task_type%TYPE,
        o_title_info       OUT pk_types.cursor_type,
        o_detail_info      OUT pk_types.cursor_type,
        o_error            OUT t_error_out
    ) RETURN BOOLEAN;

END pk_comm_orders_reports;
/
