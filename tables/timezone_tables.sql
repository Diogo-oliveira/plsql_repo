--Rui Batista 2007/08/21
--Implementação da Timezone
alter table epis_risk_factor add (dt_epis_risk_factor_tstz timestamp with local time zone);
alter table epis_risk_factor add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN epis_risk_factor.dt_epis_risk_factor_tstz IS 'Data do registo' ;
COMMENT ON COLUMN epis_risk_factor.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table epis_protocols add (dt_actv_tstz timestamp with local time zone);
alter table epis_protocols add (dt_inactv_tstz timestamp with local time zone);
COMMENT ON COLUMN epis_protocols.dt_actv_tstz IS 'Data da última activação';
COMMENT ON COLUMN epis_protocols.dt_inactv_tstz IS 'Data da última desactivação'; 

alter table hcn_eval add (dt_eval_tstz timestamp with local time zone);
alter table hcn_eval add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN hcn_eval.dt_eval_tstz IS 'Data da avaliação (só pode haver uma activa por dia para cada episódio)' ;
COMMENT ON COLUMN hcn_eval.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table hcn_eval_det add (dt_aloc_prof_tstz timestamp with local time zone);
alter table hcn_eval_det add (dt_reg_tstz timestamp with local time zone);
alter table hcn_eval_det add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN hcn_eval_det.dt_aloc_prof_tstz IS 'Data em que o profissional está alocado' ;
COMMENT ON COLUMN hcn_eval_det.dt_reg_tstz IS 'Data em que foi feita a alocação' ;
COMMENT ON COLUMN hcn_eval_det.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table hcn_pat_det add (dt_status_tstz timestamp with local time zone);
alter table hcn_pat_det add (dt_reg_tstz timestamp with local time zone);
alter table hcn_pat_det add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN hcn_pat_det.dt_status_tstz IS 'Data do estado' ;
COMMENT ON COLUMN hcn_pat_det.dt_reg_tstz IS 'Data do registo' ;
COMMENT ON COLUMN hcn_pat_det.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table match_epis add (dt_match_tstz timestamp with local time zone);
COMMENT ON COLUMN match_epis.dt_match_tstz IS 'Data em que o match foi feito' ;

alter table room_scheduled add (dt_room_scheduled_tstz timestamp with local time zone);
alter table room_scheduled add (dt_start_tstz timestamp with local time zone);
alter table room_scheduled add (dt_end_tstz timestamp with local time zone);
alter table room_scheduled add (dt_room_scheduled_tstz timestamp with local time zone);
alter table room_scheduled add (dt_start_tstz timestamp with local time zone);
alter table room_scheduled add (dt_end_tstz timestamp with local time zone);

alter table schedule_sr add (dt_target_tstz timestamp with local time zone);
alter table schedule_sr add (dt_interv_preview_tstz timestamp with local time zone);
alter table schedule_sr add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN schedule_sr.dt_target_tstz IS 'Data de agendamento da cirurgia';
COMMENT ON COLUMN schedule_sr.dt_interv_preview_tstz IS 'Data prevista de realização da intervenção. pode não estar preenchido, nos casos em que o agendamento ainda não tenha sido efetuado (episódios temporários). ' ;
COMMENT ON COLUMN schedule_sr.dt_cancel_tstz IS 'Data de cancelamento';

alter table schedule_sr_det add (dt_reg_tstz timestamp with local time zone);
alter table schedule_sr_det add (dt_target_tstz timestamp with local time zone);
alter table schedule_sr_det add (dt_interv_preview_tstz timestamp with local time zone);
alter table schedule_sr_det add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN schedule_sr_det.dt_reg_tstz IS 'Data em que o agendamento foi alterado';
COMMENT ON COLUMN schedule_sr_det.dt_target_tstz IS 'Data de agendamento da cirurgia';
COMMENT ON COLUMN schedule_sr_det.dt_interv_preview_tstz IS 'Data prevista de realização da intervenção. pode não estar preenchido, nos casos em que o agendamento ainda não tenha sido efetuado (episódios temporários). ' ;
COMMENT ON COLUMN schedule_sr_det.dt_cancel_tstz IS 'Data de cancelamento';

alter table sr_equip_kit add (create_date_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_equip_kit.adw_last_update IS 'Data da última alteração' ;
COMMENT ON COLUMN sr_equip_kit.create_date_tstz IS 'Data de criação do kit' ;

alter table sr_epis_interv_desc add (dt_interv_desc_tstz timestamp with local time zone);
alter table sr_epis_interv_desc add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_epis_interv_desc.id_sr_intervention IS 'ID da intervenção cirúrgica' ;
COMMENT ON COLUMN sr_epis_interv_desc.dt_interv_desc_tstz IS 'Data da inserção da descrição' ;
COMMENT ON COLUMN sr_epis_interv_desc.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table sr_epis_interv add (dt_req_tstz timestamp with local time zone);
alter table sr_epis_interv add (dt_interv_start_tstz timestamp with local time zone);
alter table sr_epis_interv add (dt_interv_end_tstz timestamp with local time zone);
alter table sr_epis_interv add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_epis_interv.dt_req_tstz IS 'Data da requisição' ;
COMMENT ON COLUMN sr_epis_interv.dt_interv_start_tstz IS 'Data de início da intervenção' ;
COMMENT ON COLUMN sr_epis_interv.dt_interv_end_tstz IS 'Data de fim da intervenção' ;
COMMENT ON COLUMN sr_epis_interv.dt_cancel_tstz IS 'Data de cancelamento' ;

alter table sr_chklist_manual add (dt_manual_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_chklist_manual.dt_manual_tstz IS 'Data da actualização da checklist';

alter table sr_chklist_det add (chklist_date_tstz timestamp with local time zone);
alter table sr_chklist_det add (chklist_verify_date_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_chklist_det.chklist_date_tstz IS 'Data de cumprimento da checklist';
COMMENT ON COLUMN sr_chklist_det.chklist_verify_date_tstz IS 'Data da verificação do cumprimento da checklist';

alter table sr_surgery_time_det add (dt_surgery_time_det_tstz timestamp with local time zone);
alter table sr_surgery_time_det add (dt_reg_tstz timestamp with local time zone);
alter table sr_surgery_time_det add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_surgery_time_det.dt_surgery_time_det_tstz IS 'Data do tempo operatório';
COMMENT ON COLUMN sr_surgery_time_det.dt_reg_tstz IS 'Data do registo';
COMMENT ON COLUMN sr_surgery_time_det.dt_cancel_tstz IS 'Data em que o registo foi cancelado';

alter table sr_interv_desc add (dt_interv_desc_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_interv_desc.id_sr_intervention IS 'ID da intervenção cirúrgica';
COMMENT ON COLUMN sr_interv_desc.id_language IS 'ID do idioma em que a descrição foi inserida';
COMMENT ON COLUMN sr_interv_desc.adw_last_update IS 'Data da última alteração';
COMMENT ON COLUMN sr_interv_desc.dt_interv_desc_tstz IS 'Data da inserção da descrição';

alter table sr_pat_status add (dt_status_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_pat_status.dt_status_tstz IS 'Data do estado';

alter table sr_pat_status_notes add (dt_reg_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_pat_status_notes.dt_reg_tstz IS 'Data de registo das notas' ;

alter table sr_pat_status_period add (dt_reg_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_pat_status_period.dt_reg_tstz IS 'Data do registo';

alter table sr_posit_req add (dt_posit_req_tstz timestamp with local time zone);
alter table sr_posit_req add (dt_cancel_tstz timestamp with local time zone);
alter table sr_posit_req add (dt_exec_tstz timestamp with local time zone);
alter table sr_posit_req add (dt_verify_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_posit_req.dt_posit_req_tstz IS 'Data em que foi requisitado' ;
COMMENT ON COLUMN sr_posit_req.dt_cancel_tstz IS 'Data de cancelamento' ;
COMMENT ON COLUMN sr_posit_req.dt_exec_tstz IS 'Data de execução' ;
COMMENT ON COLUMN sr_posit_req.dt_verify_tstz IS 'Data de verificação' ;

alter table sr_prof_recov_schd add (dt_start_tstz timestamp with local time zone);
alter table sr_prof_recov_schd add (dt_end_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_prof_recov_schd.id_institution IS 'ID da instituição' ;
COMMENT ON COLUMN sr_prof_recov_schd.dt_start_tstz IS 'Data de início da alocação' ;
COMMENT ON COLUMN sr_prof_recov_schd.dt_end_tstz IS 'Data de fim de alocação' ;

alter table sr_prof_team_det add (dt_begin_tstz timestamp with local time zone);
alter table sr_prof_team_det add (dt_end_tstz timestamp with local time zone);
alter table sr_prof_team_det add (dt_reg_tstz timestamp with local time zone);
alter table sr_prof_team_det add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_prof_team_det.id_professional IS 'ID do profissional';
COMMENT ON COLUMN sr_prof_team_det.id_prof_team_leader IS 'ID do responsável de equipa';
COMMENT ON COLUMN sr_prof_team_det.dt_begin_tstz IS 'Data de início de participação na intervenção';
COMMENT ON COLUMN sr_prof_team_det.dt_end_tstz IS 'Data de fim de participação na intervenção';
COMMENT ON COLUMN sr_prof_team_det.dt_reg_tstz IS 'Data da última alteração no registo';
COMMENT ON COLUMN sr_prof_team_det.dt_cancel_tstz IS 'Data de cancelamento do registo';
COMMENT ON COLUMN sr_prof_team_det.id_category_sub IS 'Id da sub-categoria do profissional';
COMMENT ON COLUMN sr_prof_team_det.id_prof_team IS 'ID da equipa de cirurgia';

alter table sr_receive add (dt_receive_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_receive.dt_receive_tstz IS 'Data de criação do registo';

alter table sr_reserv_req add (dt_req_tstz timestamp with local time zone);
alter table sr_reserv_req add (dt_exec_tstz timestamp with local time zone);
alter table sr_reserv_req add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_reserv_req.id_sr_intervention IS 'ID da intervenção cirúrgica';
COMMENT ON COLUMN sr_reserv_req.dt_req_tstz IS 'Data de requisição';
COMMENT ON COLUMN sr_reserv_req.dt_exec_tstz IS 'Data de execução';
COMMENT ON COLUMN sr_reserv_req.dt_cancel_tstz IS 'Data de cancelamento';

alter table sr_room_status add (dt_status_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_room_status.dt_status_tstz IS 'Data de início do estado';

alter table sr_surgery_rec_det add (dt_reg_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_surgery_rec_det.dt_reg_tstz IS 'Data do registo de intervenção';

alter table sr_surgery_record add (dt_anest_start_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_anest_end_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_sr_entry_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_sr_exit_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_room_entry_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_room_exit_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_rcv_entry_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_rcv_exit_tstz timestamp with local time zone);
alter table sr_surgery_record add (dt_cancel_tstz timestamp with local time zone);
COMMENT ON COLUMN sr_surgery_record.id_sr_intervention IS 'ID da intervenção cirúrgica';
COMMENT ON COLUMN sr_surgery_record.dt_anest_start_tstz IS 'Data / hora de início da anestesia';
COMMENT ON COLUMN sr_surgery_record.dt_anest_end_tstz IS 'Data / hora do fim da anestesia';
COMMENT ON COLUMN sr_surgery_record.dt_sr_entry_tstz IS 'Data / hora de entrada do paciente no bloco operatório';
COMMENT ON COLUMN sr_surgery_record.dt_sr_exit_tstz IS 'Data / hora de saída do paciente do bloco operatório';
COMMENT ON COLUMN sr_surgery_record.dt_room_entry_tstz IS 'Data / hora de entrada do paciente na sala operatória';
COMMENT ON COLUMN sr_surgery_record.dt_room_exit_tstz IS 'Data / hora de saída do paciente da sala operatória';
COMMENT ON COLUMN sr_surgery_record.dt_rcv_entry_tstz IS 'Data / hora de entrada do paciente na sala de recobro';
COMMENT ON COLUMN sr_surgery_record.dt_rcv_exit_tstz IS 'Data / hora de saída do paciente da sala de recobro';
COMMENT ON COLUMN sr_surgery_record.dt_cancel_tstz IS 'Data de cancelamento';
