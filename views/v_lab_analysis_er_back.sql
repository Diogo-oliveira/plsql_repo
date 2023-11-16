create or replace view v_lab_analysis_er_back as
(select distinct 'OUTP' origem, pat.name desc_patient, an.desc_translation desc_exam, '' desc_room, 
             e.id_episode, an.id_room, -1 id_request, h.id_harvest, 
             'SCE' episode_type, 999 episode_rank,
    decode( req.flg_time, 'E', 
             decode(h.dt_harvest, null, pk_date_utils.get_elapsed_abs_er(min(nvl(req.dt_begin, req.dt_req))), null),
             pk_message.get_message(1, 'ICON_T056')) dt_request_elapsed,
             decode(h.dt_mov_begin, null, pk_date_utils.get_elapsed_abs_er(h.dt_harvest),null) dt_harvest_elapsed, 
             decode(h.dt_lab_reception,null,pk_date_utils.get_elapsed_abs_er(h.dt_mov_begin),null) dt_transport_elapsed, 
             decode(req.flg_status,'F',null,pk_date_utils.get_elapsed_abs_er(h.dt_lab_reception)) dt_execute_elapsed, 
             '' dt_complete_elapsed, 
             decode(h.dt_harvest, null, req.dt_begin, null) dt_request, 
             decode(h.dt_mov_begin, null, h.dt_harvest, null) dt_harvest, 
             decode(h.dt_lab_reception, null, h.dt_mov_begin, null) dt_transport,
             decode(req.flg_status,'F',to_date(null),h.dt_lab_reception) dt_execute, 
             to_date(null) dt_complete , AN.ID_PROFESSIONAL ID_PROFESSIONAL                                                       
from episode e, visit v, patient pat, 
          analysis_req req, 
         analysis_req_det reqd,                   
         analysis_harvest ah, harvest h,                   
    (
 select ex.ID_ANALYSIS, ex.id_sample_recipient, ar.id_room, pk_translation.get_translation(1,  t.code_sample_recipient) desc_translation, PES.VALUE ID_PROFESSIONAL
      from ANALYSIS EX, ANALYSIS_ROOM AR, 
    SAMPLE_RECIPIENT T, 
   prof_ext_sys pes, prof_room pr
     where  pr.ID_PROFESSIONAL = pes.ID_PROFESSIONAL
   and AR.ID_ROOM  = pr.ID_ROOM     
     AND EX.ID_ANALYSIS = AR.ID_ANALYSIS
     and t.id_sample_recipient = ex.id_sample_recipient
       ) an  
where req.flg_status NOT IN ('C', 'F')
and (( ( (req.flg_time = 'E' AND REQ.DT_BEGIN IS NOT NULL)
or        (req.flg_time = 'B' and trunc(req.dt_begin) = trunc(sysdate)))
and     reqd.flg_status in ('D', 'R'))
or  reqd.flg_status = 'E')
and reqd.id_analysis =an.id_analysis
and reqd.id_analysis_req = req.id_analysis_req
and e.id_episode=req.id_episode      
and e.id_epis_type = 1 
and v.id_visit = e.id_visit
and pat.id_patient = v.id_patient             
and ah.id_analysis_req_det(+) = reqd.id_analysis_req_det
and h.id_harvest(+)= ah.id_harvest    
group by pat.name, an.desc_translation, 
  e.id_episode, an.id_room, h.id_harvest, req.flg_time, h.dt_harvest,
  h.dt_mov_begin, h.dt_lab_reception, req.flg_status, req.dt_begin, AN.ID_PROFESSIONAL)
