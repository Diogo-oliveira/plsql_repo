create or replace view v_all_messages as
SELECT pim.id_pending_issue thread_id,
       pim.id_pending_issue_message msg_id,
       pim.title subject,
       pim.text body,
       decode(pis.flg_sender, 'P', pi.id_patient, pi.id_professional) id_sender,
       decode(pis.flg_sender, 'P', pi.id_professional, pi.id_patient) id_receiver,
       pi.flg_status thread_status,
       pis.flg_status_sender msg_status_sender,
       pis.flg_status_receiver msg_status_receiver,
       pim.thread_level,
       pim.dt_creation,
       pis.flg_sender,
       pis.representative_tag
  FROM pending_issue pi
 INNER JOIN pending_issue_message pim
    ON (pim.id_pending_issue = pi.id_pending_issue)
 INNER JOIN pending_issue_sender pis
    ON (pis.id_pending_issue = pi.id_pending_issue AND pis.id_pending_issue_message = pim.id_pending_issue_message);

CREATE OR REPLACE VIEW V_ALL_MESSAGES AS
SELECT pim.id_pending_issue thread_id,
       pim.id_pending_issue_message msg_id,
       pim.title subject,
       pim.msg_body body,
       decode(pis.flg_sender, 'P', pi.id_patient, pi.id_professional) id_sender,
       decode(pis.flg_sender, 'P', pi.id_professional, pi.id_patient) id_receiver,
       pi.flg_status thread_status,
       pis.flg_status_sender msg_status_sender,
       pis.flg_status_receiver msg_status_receiver,
       pim.thread_level,
       pim.dt_creation,
       pis.flg_sender,
       pis.representative_tag
  FROM pending_issue pi
 INNER JOIN pending_issue_message pim
    ON (pim.id_pending_issue = pi.id_pending_issue)
 INNER JOIN pending_issue_sender pis
    ON (pis.id_pending_issue = pi.id_pending_issue AND pis.id_pending_issue_message = pim.id_pending_issue_message);