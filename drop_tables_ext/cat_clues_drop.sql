-- cat_clues_drop
begin
    pk_frmw_build.set_dt_lease(i_owner => 'ALERT', i_obj_name => 'CAT_CLUES');
EXCEPTION
   WHEN OTHERS THEN
	   NULL;
end;
/

BEGIN
   EXECUTE IMMEDIATE 'DROP TABLE CAT_CLUES';
EXCEPTION
   WHEN OTHERS THEN
	   NULL;
END;
/