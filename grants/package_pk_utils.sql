

  GRANT EXECUTE ON ALERT.PK_UTILS TO ALERT_VIEWER;



  GRANT EXECUTE ON ALERT.PK_UTILS TO ALERT_VIEWER;

--RS 2007/08/08
EXEC Dbms_Java.Grant_Permission('ALERT', 'SYS:java.lang.RuntimePermission', 'writeFileDescriptor', '');

EXEC Dbms_Java.Grant_Permission('ALERT', 'SYS:java.lang.RuntimePermission', 'readFileDescriptor', '');

-- CHANGED BY:   Telmo Castro
-- CHANGE DATE:  09-03-2009
-- CHANGE REASON: ALERT-19390
grant execute on alert.pk_utils to finger_db;
--END

GRANT EXECUTE ON ALERT.PK_UTILS TO ALERT_VIEWER;

