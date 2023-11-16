CREATE OR REPLACE PROCEDURE log_this
(
    i_package  IN VARCHAR2,
    i_function IN VARCHAR2,
    i_message  IN VARCHAR2
) IS
    CURSOR c_get_log IS
        SELECT VALUE
          FROM sys_config sc
         WHERE sc.id_sys_config = 'LOG.' || upper(i_package) || '.' || upper(i_function);
    g_debug_on VARCHAR2(200);
BEGIN
    OPEN c_get_log;
    FETCH c_get_log
        INTO g_debug_on;
    CLOSE c_get_log;
    IF g_debug_on = 'Y'
    THEN
        pk_alertlog.log_debug(i_message);
    END IF;
END;

/
