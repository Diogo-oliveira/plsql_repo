CREATE OR REPLACE TRIGGER B_IUD_PAT_PREGNANCY
    BEFORE UPDATE ON PAT_PREGNANCY
    FOR EACH ROW
-- PL/SQL Block

DECLARE
    CURSOR c_pph_seq IS
        SELECT seq_pat_pregnancy_hist.NEXTVAL
          FROM dual;

    l_seq_pph pat_pregnancy_hist.id_pat_pregnancy_hist%TYPE;

BEGIN
    IF updating
    THEN
        OPEN c_pph_seq;
        FETCH c_pph_seq
            INTO l_seq_pph;
        CLOSE c_pph_seq;
        --Insert previous data in the table PAT_PREGNANCY_HIST
        INSERT INTO PAT_PREGNANCY_HIST
            (id_pat_pregnancy_hist,
             id_pat_pregnancy,
             dt_pat_pregnancy,
             id_patient,
             id_professional,
             dt_last_menstruation,
             dt_prob_delivery,
             dt_pdel_correct,
             flg_immun_diagnosis,
             dt_immun_diagnosis,
             first_fetal_mov,
             first_fetal_cardiac,
             weight_before_pregn,
             flg_multiple,
             n_pregnancy,
             dt_childbirth,
             flg_childbirth_type,
             n_children,
             flg_urine_preg_test,
             dt_urine_preg_test,
             flg_hemat_preg_test,
             dt_hemat_preg_test,
             flg_antigl_aft_chb,
             flg_antigl_aft_abb,
             contrac_method,
             contrac_method_last,
             dt_contrac_meth_begin,
             dt_contrac_meth_end,
             flg_abbort,
             father_name,
             dt_father_birth,
             father_age,
             blood_group_father,
             blood_rhesus_father,
             flg_antigl_need,
             flg_status,
             id_occupation_father,
             flg_abortion_type,
             dt_abortion,
             gestation_time,
             flg_ectopic_pregnancy,
             dt_pat_pregnancy_tstz)
        VALUES
            (l_seq_pph,
             :OLD.id_pat_pregnancy,
             :OLD.dt_pat_pregnancy,
             :OLD.id_patient,
             :OLD.id_professional,
             :OLD.dt_last_menstruation,
             :OLD.dt_prob_delivery,
             :OLD.dt_pdel_correct,
             :OLD.flg_immun_diagnosis,
             :OLD.dt_immun_diagnosis,
             :OLD.first_fetal_mov,
             :OLD.first_fetal_cardiac,
             :OLD.weight_before_pregn,
             :OLD.flg_multiple,
             :OLD.n_pregnancy,
             :OLD.dt_childbirth,
             :OLD.flg_childbirth_type,
             :OLD.n_children,
             :OLD.flg_urine_preg_test,
             :OLD.dt_urine_preg_test,
             :OLD.flg_hemat_preg_test,
             :OLD.dt_hemat_preg_test,
             :OLD.flg_antigl_aft_chb,
             :OLD.flg_antigl_aft_abb,
             :OLD.contrac_method,
             :OLD.contrac_method_last,
             :OLD.dt_contrac_meth_begin,
             :OLD.dt_contrac_meth_end,
             :OLD.flg_abbort,
             :OLD.father_name,
             :OLD.dt_father_birth,
             :OLD.father_age,
             :OLD.blood_group_father,
             :OLD.blood_rhesus_father,
             :OLD.flg_antigl_need,
             :OLD.flg_status,
             :OLD.id_occupation_father,
             :OLD.flg_abortion_type,
             :OLD.dt_abortion,
             :OLD.gestation_time,
             :OLD.flg_ectopic_pregnancy,
             :OLD.dt_pat_pregnancy_tstz);
    END IF;
END;
/
