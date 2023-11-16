CREATE OR REPLACE
TRIGGER b_u_sys_alert_config
    BEFORE UPDATE OF flg_duplicate ON sys_alert_config
    FOR EACH ROW

DECLARE
    c_aux  pk_types.cursor_type;
    c_epis pk_types.cursor_type;

    l_sql              VARCHAR2(2000);
    l_epis             VARCHAR2(2000);
    l_instit_soft      VARCHAR2(100) := '';
    l_flg_first        NUMBER DEFAULT 0;
    l_id_sys_alert_evt sys_alert_event.id_sys_alert_event%TYPE;
    l_id_episode       sys_alert_event.id_episode%TYPE;

BEGIN
    -- Se configuração é 0 então actualiza para todos.
    pk_alertlog.log_init(pk_alertlog.who_am_i);

    IF :OLD.id_software != 0
    THEN
        l_instit_soft := ' and id_software = ' || :OLD.id_software;
    END IF;

    IF :OLD.id_institution != 0
    THEN
        l_instit_soft := l_instit_soft || ' and id_institution = ' || :OLD.id_institution;
    END IF;

    l_epis := 'select distinct sae.id_episode from sys_alert_event sae where sae.id_sys_alert =' || :OLD.id_sys_alert ||
              l_instit_soft;

    OPEN c_epis FOR l_epis;
    LOOP
        FETCH c_epis
            INTO l_id_episode;
        EXIT WHEN c_epis%NOTFOUND;

        l_sql := 'select id_sys_alert_event ' || 'from sys_alert_event ' || 'where id_sys_alert = ' ||
                 :OLD.id_sys_alert || ' and id_episode = ' || l_id_episode || l_instit_soft;

/*        IF :OLD.id_profile_template != 0
        THEN
            l_sql := l_sql ||
                     ' and id_professional in (select ppt.id_professional from prof_profile_template ppt where ppt.id_profile_template = ' ||
                     :OLD.id_profile_template || l_instit_soft || ')';
        END IF;*/

        l_sql := l_sql || ' order by dt_record';

        --    dbms_output.put_line('SQL:');
        --    dbms_output.put_line(l_sql);
        --pk_alertlog.log_debug('Updating record id_epis - ' || l_id_episode, 'ALERT15');
        OPEN c_aux FOR l_sql;
        LOOP
            FETCH c_aux
                INTO l_id_sys_alert_evt;
            EXIT WHEN c_aux%NOTFOUND;

            IF :NEW.flg_duplicate = 'N'
            THEN
                -- The first (oldest) is set o 'Y'
                IF l_flg_first = 0
                THEN
                    UPDATE sys_alert_event
                       SET flg_visible = 'Y'
                     WHERE id_sys_alert_event = l_id_sys_alert_evt
                       AND flg_visible = 'N';
                    -- The other are set to 'N'
                    l_flg_first := 1;
                ELSE
                    UPDATE sys_alert_event
                       SET flg_visible = 'N'
                     WHERE id_sys_alert_event = l_id_sys_alert_evt
                       AND flg_visible = 'Y';
                END IF;
            ELSE
                UPDATE sys_alert_event
                   SET flg_visible = 'Y'
                 WHERE id_sys_alert_event = l_id_sys_alert_evt
                   AND flg_visible = 'N';
            END IF;
            --pk_alertlog.log_debug('Updating record id_sys_alert_evt - ' || l_id_sys_alert_evt, 'ALERT15');
        END LOOP;
        CLOSE c_aux;
        l_flg_first := 0;
    END LOOP;
    CLOSE c_epis;

END of_clause;
/
