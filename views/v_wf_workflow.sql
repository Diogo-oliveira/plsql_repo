CREATE OR REPLACE VIEW V_WF_WORKFLOW AS
SELECT id_workflow,
       internal_name,
       description
  FROM wf_workflow;
