CREATE OR REPLACE VIEW V_XDS_DOCUMENT_CONF_CODE AS
SELECT xdc.id_xds_document_sub_conf_code id_xds_document_sub_conf_level,
       xdc.id_xds_document_submission id_xds_document_submission,
       xdc.conf_code code_conf_level,
       xdc.desc_conf_code desc_code_conf_level,
       xdc.coding_schema coding_schema
  FROM xds_document_sub_conf_code xdc;