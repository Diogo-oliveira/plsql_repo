CREATE OR REPLACE TRIGGER b_iu_disch_reas_status_val
    BEFORE INSERT OR UPDATE ON disch_reas_status_val
    FOR EACH ROW
DECLARE
    -- local variables here
    l_count       PLS_INTEGER;
    l_code_domain disch_reas_status.code_domain%TYPE;
BEGIN
    SELECT drs.code_domain
      INTO l_code_domain
      FROM disch_reas_status drs
     WHERE drs.id_disch_reas_status = :new.id_disch_reas_status;

    SELECT COUNT(*)
      INTO l_count
      FROM sys_domain sd
     WHERE sd.code_domain = l_code_domain
	 and domain_owner = pk_sysdomain.k_default_schema
       AND sd.val = :new.val;

    IF l_count = 0
    THEN
        raise_application_error(-20402, 'VAL: ' || :new.val || '; doesn''t exists on code_domain: ' || l_code_domain);
    END IF;
END b_iu_disch_reas_status_val;
/
