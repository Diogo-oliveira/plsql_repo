-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 24/07/2014
-- CHANGE REASON: [ALERT-289057] Free text should not be mandatory for "Indication reconnue " justification
--
BEGIN
    pk_frmw_objects.insert_into_frmw_objects(i_owner             => 'ALERT',
                                             i_obj_name          => 'A289057_CANCEL_REA',
                                             i_obj_type          => 'TABLE',
                                             i_flg_category      => 'DPC',
                                             i_flg_alert_default => 'N',
                                             i_delete_script     => NULL,
                                             i_flg_default_child => 'N');
END;
/

CREATE TABLE a289057_cancel_rea
(
		id_cancel_reason NUMBER(24)
)
organization external
(
		DEFAULT directory DATA_IMP_DIR
		access parameters
		(
			records delimited by '\r\n' CHARACTERSET WE8MSWIN1252
			fields terminated by ';'
		)
		location('a289057_cancel_rea.csv')
)
reject limit 0;
-- CHANGE END: rui.mendonca