


-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-7-6
-- CHANGED REASON: ALERT-320975

BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 's4u1_aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's4u1_allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's4u1_translation_16', i_owner => 'ALERT');
END;
/

-- CHANGE END: Joao Coutinho



-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-7-28
-- CHANGED REASON: ALERT-331101

BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u4_aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u4_allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u4_translation_6', i_owner => 'ALERT');
	pk_frmw_objects.set_category_dpc(i_obj_name => 's1u4_um', i_owner => 'ALERT');
END;
/

-- CHANGE END: Joao Coutinho

-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2017-9-21
-- CHANGED REASON: ALERT-332379

BEGIN
  PK_FRMW_OBJECTS.set_category_dpc(i_obj_name => 'C1_CAT_LOCALIDAD',i_owner => 'ALERT');
END;
/
-- CHANGE END: Ana Moita


-- CHANGED BY: Ana Moita
-- CHANGED DATE: 2017-9-27
-- CHANGED REASON: ALERT-332373

BEGIN
  PK_FRMW_OBJECTS.set_category_dpc(i_obj_name => 'C1_CAT_CP',i_owner => 'ALERT');
END;
/
-- CHANGE END: Ana Moita



-- CHANGED BY: Joao Coutinho
-- CHANGED DATE: 2017-10-19
-- CHANGED REASON: ALERT-333036

BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u5_aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u5_allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 's1u5_translation_6', i_owner => 'ALERT');
END;
/
-- CHANGE END: Joao Coutinho

-- CHANGED BY: Ricardo Meira
-- CHANGED DATE: 2018-02-08
-- CHANGED REASON: EMR-313
BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f12aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f12allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f12translation_8', i_owner => 'ALERT');
END;
/

-- CHANGE END: Ricardo Meira

-- CHANGED BY: rui.mendonca
-- CHANGE DATE: 19/10/2018 09:44
-- CHANGE REASON: [EMR-7725] [SE][SA] Update of VIDAL International VMP database
BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f13aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f13allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v7f13translation_8', i_owner => 'ALERT');
END;
/
-- CHANGE END: rui.mendonca


-- CHANGED BY: Rui Dagoberto
-- CHANGED DATE: 2019-4-18
-- CHANGED REASON: EMR-217

BEGIN
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v3f14aism', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v3f14allergy', i_owner => 'ALERT');
    pk_frmw_objects.set_category_dpc(i_obj_name => 'v3f14translation_17', i_owner => 'ALERT');
END;
/

-- CHANGE END: Rui Dagoberto
