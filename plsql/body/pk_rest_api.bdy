/*-- Last Change Revision: $Rev: 1974510 $*/
/*-- Last Change by: $Author: diogo.oliveira $*/
/*-- Date of last change: $Date: 2020-12-17 09:31:59 +0000 (qui, 17 dez 2020) $*/

CREATE OR REPLACE PACKAGE BODY pk_rest_api IS

    -- Private variable declarations
    k_http_header_id_professional CONSTANT VARCHAR2(15 CHAR) := 'id_professional';
    k_http_header_id_language     CONSTANT VARCHAR2(11 CHAR) := 'id_language';
    k_http_header_id_software     CONSTANT VARCHAR2(11 CHAR) := 'id_software';
    k_http_header_id_institution  CONSTANT VARCHAR2(14 CHAR) := 'id_institution';
    k_http_header_id_transaction  CONSTANT VARCHAR2(14 CHAR) := 'id_transaction';
    k_http_header_content_tpye    CONSTANT VARCHAR2(12 CHAR) := 'Content-Type';

    k_rest_hosts      CONSTANT sys_config.id_sys_config%TYPE := 'REST_HOSTS';
    k_rest_protocol   CONSTANT sys_config.id_sys_config%TYPE := 'REST_PROTOCOL';
    k_rest_retry_time CONSTANT sys_config.id_sys_config%TYPE := 'REST_RETRY_TIME';

    k_status_success         CONSTANT VARCHAR2(7 CHAR) := 'SUCCESS';
    k_status_code_success    CONSTANT NUMBER := 200;
    k_status_code_no_content CONSTANT NUMBER := 204;

    k_http_post CONSTANT VARCHAR2(4 CHAR) := 'POST';
    k_http_put  CONSTANT VARCHAR2(4 CHAR) := 'PUT';

    k_active   CONSTANT VARCHAR2(1 CHAR) := 'Y';
    k_inactive CONSTANT VARCHAR2(1 CHAR) := 'N';

    PROCEDURE get_transaction_and_host
    (
        i_transaction   IN VARCHAR2,
        o_transactionid OUT VARCHAR2,
        o_host          OUT VARCHAR2
    ) IS
    
        l_aux table_varchar;
    
    BEGIN
    
        SELECT pk_utils.str_split_c(p_list => i_transaction)
          INTO l_aux
          FROM dual;
    
        o_host          := l_aux(1);
        o_transactionid := l_aux(2);
    
    END get_transaction_and_host;

    FUNCTION make_rest_request
    (
        i_url         IN VARCHAR2,
        i_http_method IN VARCHAR2,
        i_lang        IN language.id_language%TYPE,
        i_body        IN CLOB DEFAULT NULL,
        o_data        OUT CLOB,
        o_error       OUT t_error_out
    ) RETURN BOOLEAN IS
    
    BEGIN
    
        g_error := 'Error connecting to REST SERVICE ' || i_url;
        o_data  := apex_web_service.make_rest_request(p_url => i_url, p_http_method => i_http_method, p_body => i_body);
    
        RETURN TRUE;
    
    EXCEPTION
        WHEN OTHERS THEN
            pk_alert_exceptions.process_error(i_lang     => i_lang,
                                              i_sqlcode  => SQLCODE,
                                              i_sqlerrm  => SQLERRM,
                                              i_message  => g_error,
                                              i_owner    => g_package_owner,
                                              i_package  => g_package_name,
                                              i_function => 'MAKE_REST_REQUEST',
                                              o_error    => o_error);
            RETURN FALSE;
    END make_rest_request;

    FUNCTION get_fo_bl_host
    (
        i_prof          IN profissional,
        i_hostnames     IN table_varchar,
        i_port          IN NUMBER,
        i_context_group IN VARCHAR2,
        i_fail_hostname IN table_varchar
    ) RETURN VARCHAR2 IS
        PRAGMA AUTONOMOUS_TRANSACTION;
    
        TYPE r_fo_bl_hosts_type IS RECORD(
            id_fo_bl_hosts fo_bl_hosts.id_fo_bl_hosts%TYPE,
            hostname       fo_bl_hosts.hostname%TYPE,
            port           fo_bl_hosts.hostname%TYPE,
            context_group  fo_bl_hosts.context_group%TYPE,
            status         fo_bl_hosts.status%TYPE,
            last_called    fo_bl_hosts.last_called%TYPE,
            update_time    fo_bl_hosts.update_time%TYPE);
    
        TYPE fo_bl_hosts_type IS VARRAY(10) OF r_fo_bl_hosts_type;
    
        l_list_hostnames fo_bl_hosts_type := fo_bl_hosts_type();
        --cursor
        CURSOR c_hosts IS
            SELECT f.id_fo_bl_hosts, f.hostname, f.port, f.context_group, f.status, f.last_called, f.update_time
              FROM fo_bl_hosts f
             WHERE f.hostname IN (SELECT column_value
                                    FROM TABLE(i_hostnames) xhostnames)
               AND f.port = i_port
               AND f.context_group = i_context_group
             ORDER BY f.hostname;
    
        TYPE fo_bl_hosts_cursor_type IS TABLE OF c_hosts%ROWTYPE;
        --record
        r_host              fo_bl_hosts_cursor_type := fo_bl_hosts_cursor_type();
        l_count             INTEGER;
        l_i                 INTEGER;
        l_diff_seconds      INTEGER;
        l_found_last_called BOOLEAN := FALSE;
        l_looped_hosts      BOOLEAN := FALSE;
        l_last_called_index INTEGER;
        --Change this for sysConfig
        l_retry_time      INTEGER;
        l_hostname_return fo_bl_hosts.hostname%TYPE;
        l_fo_bl_host_seq  fo_bl_hosts.id_fo_bl_hosts%TYPE;
    
        PROCEDURE add_fo_bl_hosts_type
        (
            i_id_fo_bl_hosts IN fo_bl_hosts.id_fo_bl_hosts%TYPE,
            i_hostname       IN fo_bl_hosts.hostname%TYPE,
            i_port           IN fo_bl_hosts.port%TYPE,
            i_context_group  IN fo_bl_hosts.context_group%TYPE,
            i_status         IN fo_bl_hosts.status%TYPE,
            i_last_called    IN fo_bl_hosts.last_called%TYPE,
            i_update_time    IN fo_bl_hosts.update_time%TYPE,
            i_list_hostnames IN OUT fo_bl_hosts_type
        ) IS
        BEGIN
            i_list_hostnames.extend;
            i_list_hostnames(i_list_hostnames.count).id_fo_bl_hosts := i_id_fo_bl_hosts;
            i_list_hostnames(i_list_hostnames.count).hostname := i_hostname;
            i_list_hostnames(i_list_hostnames.count).port := i_port;
            i_list_hostnames(i_list_hostnames.count).context_group := i_context_group;
            i_list_hostnames(i_list_hostnames.count).status := i_status;
            i_list_hostnames(i_list_hostnames.count).last_called := i_last_called;
            i_list_hostnames(i_list_hostnames.count).update_time := i_update_time;
        END add_fo_bl_hosts_type;
    
    BEGIN
    
        --How many seconds should i wait to get the lock on the table?
        LOCK TABLE fo_bl_hosts IN EXCLUSIVE MODE wait 5;
        l_retry_time := to_number(pk_sysconfig.get_config(k_rest_retry_time, i_prof));
        OPEN c_hosts;
        -- GET all the records to varray variable  
        FETCH c_hosts BULK COLLECT
            INTO r_host;
        CLOSE c_hosts;
    
        IF r_host.count = 0
        THEN
            FOR i IN 1 .. i_hostnames.count
            LOOP
                l_fo_bl_host_seq := seq_fo_bl_hosts.nextval;
                INSERT INTO fo_bl_hosts
                    (id_fo_bl_hosts, hostname, port, context_group, update_time)
                VALUES
                    (l_fo_bl_host_seq, i_hostnames(i), i_port, i_context_group, systimestamp);
            
                add_fo_bl_hosts_type(i_id_fo_bl_hosts => l_fo_bl_host_seq,
                                     i_hostname       => i_hostnames(i),
                                     i_port           => i_port,
                                     i_context_group  => i_context_group,
                                     i_status         => 'Y',
                                     i_last_called    => 'N',
                                     i_update_time    => systimestamp,
                                     i_list_hostnames => l_list_hostnames);
            END LOOP;
        ELSE
            FOR i IN 1 .. r_host.count
            LOOP
                add_fo_bl_hosts_type(i_id_fo_bl_hosts => r_host(i).id_fo_bl_hosts,
                                     i_hostname       => r_host(i).hostname,
                                     i_port           => r_host(i).port,
                                     i_context_group  => r_host(i).context_group,
                                     i_status         => r_host(i).status,
                                     i_last_called    => r_host(i).last_called,
                                     i_update_time    => r_host(i).update_time,
                                     i_list_hostnames => l_list_hostnames);
            END LOOP;
        END IF;
    
        l_count := l_list_hostnames.count;
        -- Inactive host that have failed previous and activate the ones that have failed more then the retry time and get the last called host successfuly  
        FOR i IN 1 .. l_count
        LOOP
            IF i_fail_hostname IS NOT NULL
               AND i_fail_hostname.count > 0
            THEN
                FOR j IN 1 .. i_fail_hostname.count
                LOOP
                    IF i_fail_hostname(j) = l_list_hostnames(i).hostname
                    THEN
                        l_list_hostnames(i).status := k_inactive;
                        l_list_hostnames(i).update_time := systimestamp;
                        EXIT;
                    END IF;
                END LOOP;
            END IF;
        
            SELECT extract(DAY FROM diff) * 24 * 60 * 60 + extract(hour FROM diff) * 60 * 60 +
                   extract(minute FROM diff) * 60 + round(extract(SECOND FROM diff))
              INTO l_diff_seconds
              FROM (SELECT systimestamp - to_timestamp(l_list_hostnames(i).update_time) diff
                      FROM dual);
        
            IF l_diff_seconds > l_retry_time
            THEN
                l_list_hostnames(i).update_time := systimestamp;
                l_list_hostnames(i).status := k_active;
            END IF;
        
            IF NOT l_found_last_called
               AND l_list_hostnames(i).last_called = 'Y'
            THEN
                l_found_last_called := TRUE;
            ELSIF l_found_last_called
                  AND l_list_hostnames(i).last_called = 'Y'
            THEN
                l_list_hostnames(i).last_called := 'N';
            END IF;
        
            IF l_list_hostnames(i).last_called = 'Y'
            THEN
                l_last_called_index := i;
                l_list_hostnames(i).last_called := 'N';
            END IF;
        END LOOP;
    
        -- GET the next host to be called. IF there isn't any available host return null  
        IF l_last_called_index IS NULL
        THEN
            l_i := 1;
        ELSIF l_last_called_index + 1 > l_count
        THEN
            l_i := 1;
        ELSE
            l_i := l_last_called_index + 1;
        END IF;
    
        WHILE TRUE
        LOOP
            IF l_i = l_last_called_index
               AND l_looped_hosts
               OR (l_looped_hosts AND l_i > l_count)
            THEN
                EXIT;
            END IF;
        
            IF l_i > l_count
               AND NOT l_looped_hosts
            THEN
                l_i            := 1;
                l_looped_hosts := TRUE;
            END IF;
        
            IF l_list_hostnames(l_i).status = 'Y'
            THEN
                l_hostname_return := l_list_hostnames(l_i).hostname;
                l_list_hostnames(l_i).last_called := 'Y';
                l_list_hostnames(l_i).update_time := systimestamp;
                EXIT;
            ELSE
                l_i := l_i + 1;
            END IF;
        END LOOP;
    
        -- Updates the records at fo_bl_hosts tables 
        FORALL i IN 1 .. l_count
            UPDATE fo_bl_hosts f
               SET f.last_called = l_list_hostnames(i).last_called,
                   f.status      = l_list_hostnames(i).status,
                   f.update_time = l_list_hostnames(i).update_time
             WHERE f.id_fo_bl_hosts = l_list_hostnames(i).id_fo_bl_hosts;
    
        COMMIT;
    
        RETURN l_hostname_return;
    
    EXCEPTION
        WHEN OTHERS THEN
            --dbms_output.put_line('Exception thrown');
            ROLLBACK;
            RETURN NULL;
    END get_fo_bl_host;

    FUNCTION handle_internal_response
    (
        i_clob   IN CLOB,
        o_status OUT VARCHAR2,
        o_data   OUT json_element_t,
        o_error  OUT json_array_t
    ) RETURN BOOLEAN IS
    
        l_json_object json_object_t;
    
    BEGIN
    
        IF i_clob IS json
        THEN
            l_json_object := json_object_t.parse(i_clob);
        
            o_data   := l_json_object.get(key => 'data');
            o_error  := l_json_object.get_array(key => 'errors');
            o_status := l_json_object.get_string(key => 'status');
        
            IF o_status != k_status_success
            THEN
                pk_alertlog.log_error('MAKE INTERNAL REST REQUEST ERROR => ' || o_error.to_string());
            
                RETURN FALSE;
            
            END IF;
        ELSIF apex_web_service.g_status_code != k_status_code_success
              AND apex_web_service.g_status_code != k_status_code_no_content
        THEN
            pk_alertlog.log_error('MAKE INTERNAL REST REQUEST STATUS ERROR => ' || apex_web_service.g_status_code);
        
            RETURN FALSE;
        
        END IF;
    
        RETURN TRUE;
    
    END handle_internal_response;

    PROCEDURE set_headers
    (
        i_prof         IN profissional,
        i_lang         IN language.id_language%TYPE,
        i_transaction  IN VARCHAR2 DEFAULT NULL,
        i_content_type IN VARCHAR2 DEFAULT NULL
    ) IS
    
        l_i NUMBER := 1;
    
    BEGIN
    
        apex_web_service.g_request_headers.delete();
        IF i_prof IS NOT NULL
        THEN
            apex_web_service.g_request_headers(l_i).name := k_http_header_id_professional;
            apex_web_service.g_request_headers(l_i).value := i_prof.id;
            l_i := l_i + 1;
        
            apex_web_service.g_request_headers(l_i).name := k_http_header_id_language;
            apex_web_service.g_request_headers(l_i).value := i_lang;
            l_i := l_i + 1;
        
            apex_web_service.g_request_headers(l_i).name := k_http_header_id_software;
            apex_web_service.g_request_headers(l_i).value := i_prof.software;
            l_i := l_i + 1;
        
            apex_web_service.g_request_headers(l_i).name := k_http_header_id_institution;
            apex_web_service.g_request_headers(l_i).value := i_prof.institution;
            l_i := l_i + 1;
        END IF;
    
        IF i_transaction IS NOT NULL
        THEN
            apex_web_service.g_request_headers(l_i).name := k_http_header_id_transaction;
            apex_web_service.g_request_headers(l_i).value := i_transaction;
            l_i := l_i + 1;
        END IF;
    
        IF i_content_type IS NOT NULL
        THEN
            apex_web_service.g_request_headers(l_i).name := k_http_header_content_tpye;
            apex_web_service.g_request_headers(l_i).value := i_content_type;
        END IF;
    
    END set_headers;

    PROCEDURE get_rest_configs
    (
        i_prof                IN profissional,
        i_application_context IN VARCHAR2,
        i_application_port    IN VARCHAR2,
        o_hosts               OUT table_varchar,
        o_port                OUT NUMBER,
        o_context             OUT VARCHAR2
    ) IS
    
        l_hosts         table_varchar;
        l_rest_protocol sys_config.value%TYPE;
        l_i             INTEGER;
    
    BEGIN
    
        o_context       := pk_sysconfig.get_config(i_application_context, i_prof);
        o_port          := to_number(pk_sysconfig.get_config(i_application_port, i_prof));
        l_rest_protocol := pk_sysconfig.get_config(k_rest_protocol, i_prof);
    
        SELECT pk_utils.str_split_c(p_list => pk_sysconfig.get_config(k_rest_hosts, i_prof))
          INTO l_hosts
          FROM dual;
    
        FOR l_i IN 1 .. l_hosts.count
        LOOP
            l_hosts(l_i) := l_rest_protocol || '://' || l_hosts(l_i);
        
        END LOOP;
    
        o_hosts := l_hosts;
    
    END get_rest_configs;

    FUNCTION get_transaction_id
    (
        i_hosts         IN table_varchar,
        i_port          IN NUMBER,
        i_context_group IN VARCHAR2,
        i_service       IN VARCHAR2,
        i_http_method   IN VARCHAR2,
        i_lang          IN language.id_language%TYPE,
        i_prof          IN profissional,
        o_transaction   OUT VARCHAR2,
        o_status        OUT VARCHAR2,
        o_data          OUT json_element_t,
        o_error         OUT json_array_t
    ) RETURN BOOLEAN IS
    
        l_clob             CLOB;
        l_result           BOOLEAN := FALSE;
        l_host             fo_bl_hosts.hostname%TYPE;
        l_uri              VARCHAR2(200 CHAR) := ':' || i_port || i_context_group || i_service;
        l_url              VARCHAR2(250 CHAR);
        l_failed_hostnames table_varchar := table_varchar();
        l_i                INTEGER := 1;
        l_error            t_error_out;
    
    BEGIN
    
        set_headers(i_prof => i_prof, i_lang => i_lang, i_transaction => NULL, i_content_type => NULL);
    
        l_host := get_fo_bl_host(i_prof          => i_prof,
                                 i_hostnames     => i_hosts,
                                 i_port          => i_port,
                                 i_context_group => i_context_group,
                                 i_fail_hostname => NULL);
    
        WHILE l_host IS NOT NULL
        LOOP
            l_url := l_host || l_uri;
        
            IF make_rest_request(i_url         => l_url,
                                 i_http_method => i_http_method,
                                 i_lang        => i_lang,
                                 i_body        => NULL,
                                 o_data        => l_clob,
                                 o_error       => l_error)
            THEN
                --dbms_output.put_line('HOST USED: ' || l_host);
                l_result      := TRUE;
                o_transaction := l_host || ':' || i_port || i_context_group;
                l_host        := NULL;
            ELSE
                l_failed_hostnames.extend;
                l_failed_hostnames(l_i) := l_host;
                l_i := l_i + 1;
                l_host := get_fo_bl_host(i_prof          => i_prof,
                                         i_hostnames     => i_hosts,
                                         i_port          => i_port,
                                         i_context_group => i_context_group,
                                         i_fail_hostname => l_failed_hostnames);
            END IF;
        END LOOP;
    
        IF l_result = TRUE
        THEN
            IF handle_internal_response(i_clob => l_clob, o_status => o_status, o_data => o_data, o_error => o_error)
            THEN
                o_transaction := o_transaction || ',' ||
                                 REPLACE(srcstr => o_data.to_string, oldsub => '"', newsub => '');
                RETURN TRUE;
            ELSE
                RETURN FALSE;
            END IF;
        END IF;
    
        RETURN l_result;
    
    END get_transaction_id;

    FUNCTION gettransactionid
    (
        i_lang                IN NUMBER,
        i_prof                IN profissional,
        i_application_context IN VARCHAR2,
        i_application_port    IN VARCHAR2,
        o_transaction         OUT VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_hosts       table_varchar;
        l_port        NUMBER;
        l_context     VARCHAR2(50 CHAR);
        l_http_method VARCHAR2(4 CHAR) := k_http_post;
        l_service     VARCHAR2(250 CHAR) := '/internal/transaction/';
    
        l_status VARCHAR2(50 CHAR);
        l_data   json_element_t;
    
        l_error json_array_t;
    
    BEGIN
    
        get_rest_configs(i_prof, i_application_context, i_application_port, l_hosts, l_port, l_context);
    
        RETURN pk_rest_api.get_transaction_id(i_hosts         => l_hosts,
                                              i_port          => l_port,
                                              i_context_group => l_context,
                                              i_service       => l_service,
                                              i_http_method   => l_http_method,
                                              i_lang          => i_lang,
                                              i_prof          => i_prof,
                                              o_transaction   => o_transaction,
                                              o_status        => l_status,
                                              o_data          => l_data,
                                              o_error         => l_error);
    
    END gettransactionid;

    FUNCTION make_internal_rest_request
    (
        i_host_transaction IN VARCHAR2,
        i_service          IN VARCHAR2,
        i_http_method      IN VARCHAR2,
        i_content_type     IN VARCHAR2 DEFAULT NULL,
        i_lang             IN language.id_language%TYPE,
        i_prof             IN profissional,
        i_body             IN CLOB DEFAULT NULL,
        o_status           OUT VARCHAR2,
        o_data             OUT json_element_t,
        o_error            OUT json_array_t
    ) RETURN BOOLEAN IS
    
        l_clob          CLOB;
        l_result        BOOLEAN := FALSE;
        l_url           VARCHAR2(250 CHAR);
        l_error         t_error_out;
        l_host          VARCHAR2(200 CHAR);
        l_transactionid VARCHAR2(50 CHAR);
    
    BEGIN
    
        get_transaction_and_host(i_transaction   => i_host_transaction,
                                 o_transactionid => l_transactionid,
                                 o_host          => l_host);
    
        l_url := l_host || i_service;
        set_headers(i_prof         => i_prof,
                    i_lang         => i_lang,
                    i_transaction  => l_transactionid,
                    i_content_type => i_content_type);
    
        l_result := make_rest_request(i_url         => l_url,
                                      i_http_method => i_http_method,
                                      i_lang        => i_lang,
                                      i_body        => i_body,
                                      o_data        => l_clob,
                                      o_error       => l_error);
    
        IF l_result = TRUE
        THEN
            RETURN handle_internal_response(i_clob   => l_clob,
                                            o_status => o_status,
                                            o_data   => o_data,
                                            o_error  => o_error);
        END IF;
    
        RETURN l_result;
    
    END make_internal_rest_request;

    FUNCTION make_internal_rest_request
    (
        i_application_context IN VARCHAR2,
        i_application_port    IN VARCHAR2,
        i_service             IN VARCHAR2,
        i_http_method         IN VARCHAR2,
        i_content_type        IN VARCHAR2 DEFAULT NULL,
        i_lang                IN language.id_language%TYPE,
        i_prof                IN profissional,
        i_body                IN CLOB DEFAULT NULL,
        o_status              OUT VARCHAR2,
        o_data                OUT json_element_t,
        o_error               OUT json_array_t
    ) RETURN BOOLEAN IS
    
        l_clob             CLOB;
        l_result           BOOLEAN := FALSE;
        l_url              VARCHAR2(250 CHAR);
        l_error            t_error_out;
        l_host             VARCHAR2(200 CHAR);
        --l_transactionid    VARCHAR2(50 CHAR);
        l_hosts            table_varchar;
        l_port             NUMBER;
        l_context          VARCHAR2(50 CHAR);
        l_uri              VARCHAR2(200 CHAR);
        l_failed_hostnames table_varchar := table_varchar();
        l_i                INTEGER := 1;
    
    BEGIN
    
        get_rest_configs(i_prof, i_application_context, i_application_port, l_hosts, l_port, l_context);
    
        l_uri := ':' || l_port || l_context || i_service;
    
        set_headers(i_prof => i_prof, i_lang => i_lang, i_transaction => NULL, i_content_type => i_content_type);
    
        l_host := get_fo_bl_host(i_prof          => i_prof,
                                 i_hostnames     => l_hosts,
                                 i_port          => l_port,
                                 i_context_group => l_context,
                                 i_fail_hostname => NULL);
    
        WHILE l_host IS NOT NULL
        LOOP
            l_url := l_host || l_uri;
            IF make_rest_request(i_url         => l_url,
                                 i_http_method => i_http_method,
                                 i_lang        => i_lang,
                                 i_body        => NULL,
                                 o_data        => l_clob,
                                 o_error       => l_error)
            THEN
                --dbms_output.put_line('HOST USED: ' || l_host);
                l_result := TRUE;
                l_host   := NULL;
            ELSE
                l_failed_hostnames.extend;
                l_failed_hostnames(l_i) := l_host;
                l_i := l_i + 1;
                l_host := get_fo_bl_host(i_prof          => i_prof,
                                         i_hostnames     => l_hosts,
                                         i_port          => l_port,
                                         i_context_group => l_context,
                                         i_fail_hostname => l_failed_hostnames);
            END IF;
        END LOOP;
    
        IF l_result = TRUE
        THEN
            RETURN handle_internal_response(i_clob   => l_clob,
                                            o_status => o_status,
                                            o_data   => o_data,
                                            o_error  => o_error);
        END IF;
    
        RETURN l_result;
    
    END make_internal_rest_request;

    FUNCTION convert_timestamp(i_timestamp IN TIMESTAMP WITH LOCAL TIME ZONE) RETURN VARCHAR2 IS
    
    BEGIN
    
        IF i_timestamp IS NOT NULL
        THEN
            RETURN to_char(i_timestamp, 'YYYYMMDDHH24MISS');
        ELSE
            RETURN NULL;
        END IF;
    
    END convert_timestamp;

    FUNCTION begintransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_host          VARCHAR2(200 CHAR);
        l_transactionid VARCHAR2(50 CHAR);
        l_http_method   VARCHAR2(4 CHAR) := k_http_put;
        l_service       VARCHAR2(250 CHAR);
    
        l_status VARCHAR2(50 CHAR);
        l_data   json_element_t;
    
        l_error json_array_t;
    
    BEGIN
    
        get_transaction_and_host(i_transaction => i_transaction, o_transactionid => l_transactionid, o_host => l_host);
    
        l_service := '/internal/transaction/' || l_transactionid || '/begin';
    
        RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                      i_service          => l_service,
                                                      i_http_method      => l_http_method,
                                                      i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_status           => l_status,
                                                      o_data             => l_data,
                                                      o_error            => l_error);
    
    END begintransaction;

    FUNCTION committransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_host          VARCHAR2(200 CHAR);
        l_transactionid VARCHAR2(50 CHAR);
        l_http_method   VARCHAR2(4 CHAR) := k_http_put;
        l_service       VARCHAR2(250 CHAR);
    
        l_status VARCHAR2(50 CHAR);
        l_data   json_element_t;
    
        l_error json_array_t;
    
    BEGIN
    
        get_transaction_and_host(i_transaction => i_transaction, o_transactionid => l_transactionid, o_host => l_host);
    
        l_service := '/internal/transaction/' || l_transactionid || '/commit';
    
        RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                      i_service          => l_service,
                                                      i_http_method      => l_http_method,
                                                      i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_status           => l_status,
                                                      o_data             => l_data,
                                                      o_error            => l_error);
    
    END committransaction;

    FUNCTION rollbacktransaction
    (
        i_lang        IN NUMBER,
        i_prof        IN profissional,
        i_transaction IN VARCHAR2
    ) RETURN BOOLEAN IS
    
        l_host          VARCHAR2(200 CHAR);
        l_transactionid VARCHAR2(50 CHAR);
        l_http_method   VARCHAR2(4 CHAR) := k_http_put;
        l_service       VARCHAR2(250 CHAR);
    
        l_status VARCHAR2(50 CHAR);
        l_data   json_element_t;
    
        l_error json_array_t;
    
    BEGIN
    
        get_transaction_and_host(i_transaction => i_transaction, o_transactionid => l_transactionid, o_host => l_host);
    
        l_service := '/internal/transaction/' || l_transactionid || '/rollback';
    
        RETURN pk_rest_api.make_internal_rest_request(i_host_transaction => i_transaction,
                                                      i_service          => l_service,
                                                      i_http_method      => l_http_method,
                                                      i_lang             => i_lang,
                                                      i_prof             => i_prof,
                                                      o_status           => l_status,
                                                      o_data             => l_data,
                                                      o_error            => l_error);
    
    END rollbacktransaction;

BEGIN

    pk_alertlog.who_am_i(g_package_owner, g_package_name);
    pk_alertlog.log_init(g_package_name);

END pk_rest_api;
/
