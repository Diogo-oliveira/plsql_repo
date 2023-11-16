declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'A_274650_DOC_ELEMENT_CRIT';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE A_274650_DOC_ELEMENT_CRIT';
            COMMIT;
        END IF;
END;
/

declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'A_274650_DOC_ELEMENT';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE A_274650_DOC_ELEMENT';
            COMMIT;
        END IF;
END;
/