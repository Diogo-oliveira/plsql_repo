CREATE OR REPLACE VIEW V_DOC_ACTIVITY_LOG AS
SELECT
   da.id_doc_external,
   de.id_patient,
   da.dt_operation,
   do.operation_name,
   nvl(de.doc_oid, s.value || '.' || da.id_doc_external) doc_oid
FROM
   sys_config s,
   doc_activity da
INNER JOIN doc_operation_conf doc
   ON da.id_doc_operation_conf = doc.id_doc_operation_config
INNER JOIN doc_external de
   ON da.id_doc_external = de.id_doc_external
INNER JOIN doc_operation do
   ON doc.operation_name = do.operation_name
   AND do.operation_name IN ('VIEW', 'TRANSMIT', 'DOWNLOAD')
WHERE
       da.flg_status in ('S')
   AND s.id_sys_config = 'ALERT_OID_HIE_DOC_EXTERNAL'
ORDER BY da.dt_operation desc;
