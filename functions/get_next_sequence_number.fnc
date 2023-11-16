CREATE OR REPLACE FUNCTION get_next_sequence_number
(
    i_lang        IN VARCHAR2,
    sequence_name IN VARCHAR2,
    return_number IN OUT NUMBER,
    o_error       IN OUT VARCHAR2
) RETURN BOOLEAN IS
    aux_sql VARCHAR2(750);
    g_error VARCHAR2(2000);
BEGIN
    aux_sql := 'SELECT ' || sequence_name || '.nextval from dual';
    g_error := 'GET EXECUTE IMMEDIATE';
    dbms_output.put_line(aux_sql);
    EXECUTE IMMEDIATE aux_sql
        INTO return_number;
    RETURN(TRUE);
EXCEPTION
    WHEN OTHERS THEN
        o_error := pk_message.get_message(i_lang,
                                          'COMMON_M001') || chr(10) || 'GET_NEXT_SEQUENCE_NUMBER / ' || g_error ||
                   ' / ' || SQLERRM;
    
        pk_alertlog.log_error(o_error);
        RETURN FALSE;
END get_next_sequence_number;
/
