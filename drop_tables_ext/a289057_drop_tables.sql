-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 24/07/2014
-- CHANGE REASON: [ALERT-289057] Free text should not be mandatory for "Indication reconnue " justification
--
BEGIN
    pk_frmw_objects.set_category_dpc(i_owner => 'ALERT', i_obj_name => 'A289057_CANCEL_REA');
END;
/

DROP TABLE a289057_cancel_rea;
-- CHANGE END: rui.mendonca