CREATE OR REPLACE TRIGGER a_iu_discharge
    AFTER INSERT OR UPDATE ON discharge
    FOR EACH ROW
DECLARE

    -- Types of Discharges
    g_const_discharge_cancel     CONSTANT VARCHAR2(1) := 'C';
    g_const_discharge_type_phys  CONSTANT VARCHAR2(1) := 'D';
    g_const_discharge_type_nurse CONSTANT VARCHAR2(1) := 'N';
    g_const_discharge_type_thera CONSTANT VARCHAR2(1) := 'F';
    g_const_discharge_type_manch CONSTANT VARCHAR2(1) := 'T';
    g_const_discharge_type_nutri CONSTANT VARCHAR2(1) := 'U';
    g_const_discharge_type_case  CONSTANT VARCHAR2(1) := 'C';
    g_const_discharge_type_admin CONSTANT VARCHAR2(1) := 'M';
    g_const_status_pending       CONSTANT VARCHAR2(1) := 'P';
    g_const_status_active        CONSTANT VARCHAR2(1) := 'A';
    g_const_type_final           CONSTANT VARCHAR2(1) := 'F';

BEGIN

    IF (inserting)
    THEN
        CASE
        
            WHEN :new.flg_type_disch = g_const_discharge_type_phys THEN
                pk_ia_event_common.discharge_physician_new(i_id_discharge => :new.id_discharge);
                IF :new.flg_status = g_const_status_pending
                THEN
                    pk_ia_event_common.discharge_pending_new(i_id_discharge => :new.id_discharge);
                END IF;
            WHEN :new.flg_type_disch = g_const_discharge_type_nurse THEN
                pk_ia_event_common.discharge_nurse_new(i_id_discharge => :new.id_discharge);
            WHEN :new.flg_type_disch = g_const_discharge_type_admin THEN
                pk_ia_event_common.discharge_adm_new(i_id_discharge => :new.id_discharge);
            WHEN :new.flg_type_disch = g_const_discharge_type_thera THEN
                pk_ia_event_common.discharge_therapist_new(i_id_discharge => :new.id_discharge);
            WHEN :new.flg_type_disch = g_const_discharge_type_nutri THEN
                pk_ia_event_common.discharge_nutritionist_new(i_id_discharge => :new.id_discharge);
            WHEN :new.flg_type_disch IS NULL
                 AND :new.dt_med_tstz IS NOT NULL
                 AND :new.dt_admin_tstz IS NOT NULL THEN
                pk_ia_event_common.discharge_admin_phys_new(i_id_discharge => :new.id_discharge);
            WHEN :new.dt_pend_tstz IS NOT NULL
                 AND :new.flg_type_disch IS NULL
                 AND :new.flg_status = g_const_status_pending THEN
                pk_ia_event_common.discharge_pending_new(i_id_discharge => :new.id_discharge);
            WHEN :new.flg_type_disch IS NULL
                 AND :new.dt_med_tstz IS NOT NULL
                 AND :new.dt_admin_tstz IS NULL
                 AND :new.flg_type = g_const_type_final THEN
                pk_ia_event_common.discharge_physician_new(i_id_discharge => :new.id_discharge);
        END CASE;
    
    ELSIF (updating)
    THEN
        CASE
            WHEN :new.dt_med_tstz IS NOT NULL
                 AND :old.flg_status <> g_const_status_active
                 AND :new.flg_status = g_const_status_active THEN
                -- When updating to active
                pk_ia_event_common.discharge_physician_new(i_id_discharge => :new.id_discharge);
            WHEN nvl(:old.flg_status_adm, pk_alert_constant.g_inactive) <> pk_alert_constant.g_active
                 AND :new.flg_status_adm = pk_alert_constant.g_active THEN
                pk_ia_event_common.discharge_admin_aft_phy_new(i_id_discharge => :new.id_discharge); -- new admin discharge that preceed a medical discharge
            WHEN :old.flg_status <> g_const_discharge_cancel
                 AND :new.flg_status = g_const_discharge_cancel THEN
                -- When cancelling
                CASE
                    WHEN nvl(:old.flg_status_adm, pk_alert_constant.g_inactive) <> pk_alert_constant.g_cancelled
                         AND :new.flg_status_adm = pk_alert_constant.g_cancelled THEN
                        -- 2 in 1 discharge cancellation
                        pk_ia_event_common.discharge_admin_phys_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch = g_const_discharge_type_phys THEN
                        -- physician discharge cancellation 
                        pk_ia_event_common.discharge_physician_cancel(i_id_discharge => :new.id_discharge);
                        IF :old.flg_status = g_const_status_pending
                        THEN
                            -- pending discharge cancellation
                            pk_ia_event_common.discharge_pending_cancel(i_id_discharge => :new.id_discharge);
                        END IF;
                    WHEN :old.flg_type_disch = g_const_discharge_type_nurse THEN
                        -- nurse discharge cancellation
                        pk_ia_event_common.discharge_nurse_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch = g_const_discharge_type_admin THEN
                        -- admin discharge cancellation
                        pk_ia_event_common.discharge_adm_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch = g_const_discharge_type_thera THEN
                        -- therapist discharge cancellation
                        pk_ia_event_common.discharge_therapist_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch = g_const_discharge_type_nutri THEN
                        -- nutritionist discharge cancellation
                        pk_ia_event_common.discharge_nutritionist_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch IS NULL
                         AND :new.dt_pend_tstz IS NOT NULL THEN
                        -- pending discharge cancellation
                        pk_ia_event_common.discharge_pending_cancel(i_id_discharge => :new.id_discharge);
                    WHEN :old.flg_type_disch IS NULL
                         AND :new.dt_med_tstz IS NOT NULL
                         AND :new.dt_admin_tstz IS NULL
                         AND :new.flg_type = g_const_type_final THEN
                        -- physician discharge cancellation 
                        pk_ia_event_common.discharge_physician_cancel(i_id_discharge => :new.id_discharge);
                END CASE;
            WHEN nvl(:old.flg_status_adm, pk_alert_constant.g_inactive) <> pk_alert_constant.g_cancelled
                 AND :new.flg_status_adm = pk_alert_constant.g_cancelled THEN
                -- admin discharge that preceed a medical discharge cancellation
                pk_ia_event_common.discharge_admin_aft_phy_cancel(i_id_discharge => :new.id_discharge);
        END CASE;
    
    END IF;
EXCEPTION
    WHEN case_not_found THEN
        NULL;
END a_iu_discharge;
/
