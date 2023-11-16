-- CHANGED BY:  Rui Gomes
-- CHANGE DATE: 29/10/2014 14:56
-- CHANGE REASON: [ALERT-299659] new text field and state control
DECLARE
    x_lang       language.id_language%TYPE := 2;
    x_id_message pending_issue_message.id_pending_issue_message%TYPE := 255080;
    x_flg_from   VARCHAR2(1) := 'O';
    x_error      t_error_out;

    x_ret BOOLEAN;

BEGIN
    UPDATE pending_issue_message pim
       SET pim.msg_body =  pim.text
     WHERE (pim.id_pending_issue, pim.id_pending_issue_message) IN
           (SELECT pis.id_pending_issue, pis.id_pending_issue_message
              FROM pending_issue_sender pis);

-->t_tbl_msg|type
drop type t_tbl_msg;
-->t_rec_msg_type
drop type t_rec_msg;
END;
/
-- CHANGE END:  Rui Gomes

-- CHANGED BY: Paulo Teixeira
-- CHANGE DATE: 03/06/2016 11:30
-- CHANGE REASON: [ALERT-321393] 
BEGIN
    -- Call the procedure
    UPDATE grid_task gt
       SET gt.discharge_pend = NULL
     WHERE gt.discharge_pend IS NOT NULL;

    pk_data_gov_admin.grid_task_discharge_pend;
END;
/
-- CHANGE END: Paulo Teixeira