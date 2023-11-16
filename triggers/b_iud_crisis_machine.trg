CREATE OR REPLACE
TRIGGER B_IUD_CRISIS_MACHINE
 AFTER DELETE OR INSERT OR UPDATE
 ON CRISIS_MACHINE
-- PL/SQL Block
DECLARE
    w_result BOOLEAN;
    i_lang   NUMBER(1) := 2;
    o_error  VARCHAR2(4000);
		l_result NUMBER(1) := 0;
BEGIN
    w_result := pk_crisis_machine.set_crontab(1, l_result, o_error);
		
		if l_result != 1
		then
		   RAISE_APPLICATION_ERROR(-20000, 'URL return with error.');
		end if;
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line(substr(o_error, 1, 250));
        dbms_output.put_line('#' || SQLERRM);
END;
/


-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 03/10/2013 10:57
-- CHANGE REASON: [ALERT-266179] Crisis Machine frameword performance changes
CREATE OR REPLACE TRIGGER b_iud_crisis_machine
    AFTER DELETE OR INSERT OR UPDATE OF id_crisis_machine, id_act_interval ON crisis_machine
DECLARE
    o_error VARCHAR2(4000);
BEGIN
    pk_crisis_machine.set_crontab(o_error => o_error);

    alertlog.pk_alertlog.log_info(text            => 'B_IUD_CRISIS_MACHINE- alert_cm_jobs.xml generated',
                                  object_name     => 'PK_CRISIS_MACHINE',
                                  sub_object_name => 'B_IUD_CRISIS_MACHINE');
EXCEPTION
    WHEN OTHERS THEN
        alertlog.pk_alertlog.log_error(text            => 'B_IUD_CRISIS_MACHINE-' || SQLERRM,
                                       object_name     => 'PK_CRISIS_MACHINE',
                                       sub_object_name => 'B_IUD_CRISIS_MACHINE');
END;
/
-- CHANGE END: Gustavo Serrano

-- CHANGED BY: Gustavo Serrano
-- CHANGE DATE: 08/10/2013 12:30
-- CHANGE REASON: [ALERT-266177] Crisis Machine cleanup
BEGIN
		EXECUTE IMMEDIATE 'DROP TRIGGER b_iud_crisis_machine';
EXCEPTION
    WHEN OTHERS THEN
        dbms_output.put_line('drop TRIGGER b_iud_crisis_machine - Error (' || SQLCODE || '), resuming execution...');
END;
/
-- CHANGE END: Gustavo Serrano