declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'A_274397_DOC_ELEMENT_QUALIF';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE A_274397_DOC_ELEMENT_QUALIF';
            COMMIT;
        END IF;
END;
/

declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'A_274397_DOC_ELEMENT_CRIT';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE A_274397_DOC_ELEMENT_CRIT';
            COMMIT;
        END IF;
END;
/

declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'A_274397_TRANSLATION_6';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE A_274397_TRANSLATION_6';
            COMMIT;
        END IF;
END;
/