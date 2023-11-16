declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'SPA_ALERT_298043';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE SPA_ALERT_298043';
            COMMIT;
        END IF;
END;
/
