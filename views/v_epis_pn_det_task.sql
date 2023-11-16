CREATE OR REPLACE VIEW v_epis_pn_det_task AS
  select ID_EPIS_PN_DET_TASK,ID_EPIS_PN_DET,ID_TASK,ID_TASK_TYPE, pn_note, FLG_STATUS from epis_pn_det_task ;
