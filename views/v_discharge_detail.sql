-->V_DISCHARGE_DETAIL
CREATE OR REPLACE VIEW V_DISCHARGE_DETAIL AS
SELECT id_discharge_detail,
       id_discharge,
       flg_pat_condition,
       id_transport_type,
       id_disch_rea_transp_ent_inst,
       flg_caretaker,
       caretaker_notes,
       flg_follow_up_by,
       follow_up_notes,
       flg_written_notes,
       flg_voluntary,
       flg_pat_report,
       flg_transfer_form,
       id_prof_admitting,
       id_dep_clin_serv_admiting,
       flg_summary_report,
       flg_autopsy_consent,
       autopsy_consent_desc,
       flg_orgn_dntn_info,
       orgn_dntn_info,
       flg_examiner_notified,
       examiner_notified_info,
       flg_orgn_dntn_form_complete,
       flg_ama_form_complete,
       flg_lwbs_form_complete,
       notes,
       prof_admitting_desc,
       dep_clin_serv_admiting_desc,
       mse_type,
       flg_surgery,
       follow_up_date_tstz,
       date_surgery_tstz,
       flg_print_report,
       followup_count,
       total_time_spent,
       id_unit_measure,
       id_transfer_diagnosis,
       flg_inst_transfer,
       flg_inst_transfer_status,
       id_epis_diagnosis,
       dti_notes,
       flg_autopsy,
       (SELECT admission_orders
          FROM (SELECT ddh.admission_orders,
                       id_discharge,
                       row_number() over(PARTITION BY ddh.id_discharge ORDER BY ddh.dt_created_hist DESC) rn
                  FROM discharge_detail_hist ddh)
         WHERE rn = 1
           AND id_discharge = dd.id_discharge) admission_orders
  FROM discharge_detail dd;
