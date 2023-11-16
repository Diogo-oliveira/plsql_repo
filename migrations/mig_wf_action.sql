-- CHANGED BY: Ana Monteiro
-- CHANGE DATE: 05/11/2010 14:53
-- CHANGE REASON: [ALERT-137811] ALERT_75390 Possibilidade do médico hospital encaminhar o pedido para o administrativo hospital

--1- criacao de tabela de backup
CREATE TABLE wf_action_bck AS 
 SELECT *
   FROM wf_action;

--2- alteracoes a tabela
alter table WF_ACTION add ID_WORKFLOW_ACTION NUMBER(24);
comment on column WF_ACTION.ID_WORKFLOW_ACTION is 'Workflow action identifier';

alter table WF_ACTION add constraint WAN_WTS_FK foreign key (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION)
  references WF_TRANSITION (ID_WORKFLOW, ID_STATUS_BEGIN, ID_STATUS_END, ID_WORKFLOW_ACTION);

--3- script de migracao de dados    
UPDATE wf_action a
 SET id_workflow_action = (SELECT id_workflow_action
 FROM wf_transition w
WHERE a.id_workflow = w.id_workflow
                                AND a.id_status_begin = w.id_status_begin
                                AND a.id_status_end = w.id_status_end
                                --AND w.flg_auto_transition = 'N'
                                AND id_workflow_action != 34);
-- CHANGE END: Ana Monteiro