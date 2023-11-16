declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'a_286721_doc_element_crit';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE a_286721_doc_element_crit';
            COMMIT;
        END IF;
END;
/

declare valor number;
BEGIN
    SELECT COUNT(*)
    INTO valor
    FROM all_all_tables t
    WHERE t.table_name = 'a_286721_doc_element';
        IF valor >= 1
        THEN
            EXECUTE IMMEDIATE 'drop TABLE a_286721_doc_element';
            COMMIT;
        END IF;
END;
/
