BEGIN
    -- Create sequence 
execute immediate    'CREATE sequence seq_clin_record_history minvalue 1 maxvalue 999999999999 START WITH 1 increment BY 1 cache 500';
EXCEPTION
    WHEN OTHERS THEN
        NULL;
END;

/




