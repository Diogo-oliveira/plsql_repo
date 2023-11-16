CREATE OR REPLACE VIEW V_EDIS_TEMP_ARGS AS
SELECT tt.vc_1 namespace, tt.vc_2 attribute, tt.vc_3 attr_value
  FROM tbl_temp tt;
