DECLARE
		e_already_dropped EXCEPTION;

		PRAGMA EXCEPTION_INIT(e_already_dropped, -904);
BEGIN
		--Fill ID_CONTEXT_NEW
		EXECUTE IMMEDIATE 'UPDATE epis_comp_detail ecd
													SET ecd.id_context_new = nvl(ecd.id_context_new, to_char(ecd.id_context))
												WHERE ecd.id_context IS NOT NULL';

    COMMIT;
EXCEPTION
		WHEN e_already_dropped THEN
				dbms_output.put_line('Migration script has already been run in the past.');
END;
/
