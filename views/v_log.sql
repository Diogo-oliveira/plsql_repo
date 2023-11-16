CREATE OR REPLACE VIEW V_LOG AS
SELECT lsection,
       ltexte,
       luser,
       llevel,
       decode(llevel, 10, 'OFF', 20, 'FATAL', 30, 'ERROR', 40, 'WARN', 50, 'INFO', 60, 'DEBUG', 70, 'ALL') TYPE,
       CASE WHEN llevel <= 30 THEN 'Y' ELSE 'N' END is_error,
       ldate,
       lhsecs,
       id
  FROM tlog
 ORDER BY ldate DESC;
 