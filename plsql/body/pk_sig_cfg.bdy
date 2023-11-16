CREATE OR REPLACE PACKAGE BODY pk_sig_cfg IS

    --k_cud_insert CONSTANT VARCHAR2(0001 CHAR) := 'C';
    k_cud_update CONSTANT VARCHAR2(0001 CHAR) := 'U';
    k_cud_delete CONSTANT VARCHAR2(0001 CHAR) := 'D';
    --k_cud_active CONSTANT VARCHAR2(0001 CHAR) := 'A';

    k_yes CONSTANT VARCHAR2(0010 CHAR) := 'Y';
    k_no  CONSTANT VARCHAR2(0010 CHAR) := 'N';

    k_flg_status_active CONSTANT VARCHAR2(0010 CHAR) := 'A';
    k_flg_status_cancel CONSTANT VARCHAR2(0010 CHAR) := 'C';

    FUNCTION iif
    (
        i_bool  IN BOOLEAN,
        i_true  IN VARCHAR2,
        i_false IN VARCHAR2
    ) RETURN VARCHAR2 IS
    BEGIN
    
        IF i_bool
        THEN
            RETURN i_true;
        ELSE
            RETURN i_false;
        END IF;
    
    END iif;

    --*******************************************************
    PROCEDURE ins_prof_sig
    (
        i_row IN prof_signature%ROWTYPE,
        o_id  OUT NUMBER
    ) IS
        l_row prof_signature%ROWTYPE;
    BEGIN
    
        l_row              := i_row;
        l_row.id_signature := seq_signature.nextval;
        l_row.flg_status   := k_flg_status_active;
    
        INSERT INTO prof_signature
            (id_professional,
             id_signature,
             flg_type,
             dt_creation,
             id_prof_creation,
             sig_name,
             sig_image,
             sig_filename,
             sig_prof_name,
             sig_order_type,
             sig_order_nr,
             sig_address,
             flg_status,
             sig_obs,
             id_cancel_reason)
        VALUES
            (l_row.id_professional,
             l_row.id_signature,
             l_row.flg_type,
             current_timestamp,
             l_row.id_prof_creation,
             l_row.sig_name,
             l_row.sig_image,
             l_row.sig_filename,
             l_row.sig_prof_name,
             l_row.sig_order_type,
             l_row.sig_order_nr,
             l_row.sig_address,
             l_row.flg_status,
             l_row.sig_obs,
             l_row.id_cancel_reason);
    
        --set_history(k_cud_insert, l_row);
    
        o_id := l_row.id_signature;
    
    END ins_prof_sig;

    --*******************************************************
    PROCEDURE ins_active_prof_sig(i_row IN prof_signature%ROWTYPE) IS
    BEGIN
    
        INSERT INTO prof_active_signature
            (id_professional, id_signature, dt_creation, id_prof_creation)
        VALUES
            (i_row.id_professional, i_row.id_signature, current_timestamp, i_row.id_prof_creation);
    
        --set_history(k_cud_active, i_row);
        --set_history(k_cud_update, i_row);
    
    END ins_active_prof_sig;

    --*******************************************
    PROCEDURE del_active_sig(i_id_prof IN NUMBER) IS
    BEGIN
    
        DELETE prof_active_signature
         WHERE id_professional = i_id_prof;
    
    END del_active_sig;

    FUNCTION get_active_signature(i_prof_id IN NUMBER) RETURN prof_active_signature%ROWTYPE IS
        l_count NUMBER;
        l_row   prof_active_signature%ROWTYPE;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_active_signature
         WHERE id_professional = i_prof_id;
    
        IF l_count > 0
        THEN
            SELECT *
              INTO l_row
              FROM prof_active_signature
             WHERE id_professional = i_prof_id;
        END IF;
    
        RETURN l_row;
    
    END get_active_signature;

    --***************************************
    PROCEDURE ins_active_sig
    (
        i_id_prof IN NUMBER,
        i_id_sig  IN NUMBER
    ) IS
        l_row prof_signature%ROWTYPE;
        l_old_row    prof_signature%ROWTYPE;
        l_active_row prof_active_signature%ROWTYPE;
        b_save_old   BOOLEAN;
    
        --**********************************
        FUNCTION get_old_active_sig RETURN prof_signature%ROWTYPE IS
            l_old_row prof_signature%ROWTYPE;
    BEGIN
    
            l_active_row := get_active_signature(i_id_prof);
    
            IF l_active_row.id_signature IS NOT NULL
            THEN
            
                b_save_old := l_active_row.id_signature != i_id_sig;
                IF b_save_old
                THEN
                    l_old_row := get_prof_signature(i_prof => i_id_prof, i_sig => l_active_row.id_signature);
                END IF;
            
            END IF;
        
            RETURN l_old_row;
        
        END get_old_active_sig;
    
        --*****************************
        PROCEDURE save_old_hist(i_old_row IN prof_signature%ROWTYPE) IS
            --l_id NUMBER;
        BEGIN
        
            IF b_save_old
            THEN
                set_history(k_cud_update, i_old_row);
            END IF;
        
        END save_old_hist;
    
    BEGIN
    
        -- get current signature
        l_old_row := get_old_active_sig();
    
        -- clean current signature
        del_active_sig(i_id_prof => i_id_prof);
    
        -- get new signatue
        l_row := get_prof_signature(i_prof => i_id_prof, i_sig => i_id_sig);
    
        -- save new signature
        ins_active_prof_sig(i_row => l_row);
        set_history(k_cud_update, l_row);
    
        save_old_hist(l_old_row);
    
    END ins_active_sig;

    --*******************************************************
    PROCEDURE ins_prof_sig_h
    (
        i_mode IN VARCHAR2,
        i_row  IN prof_signature%ROWTYPE
    ) IS
        l_bool     BOOLEAN;
        l_flg_pref VARCHAR2(0010 CHAR);
    BEGIN
    
        l_bool     := is_record_preferential(i_row.id_professional, i_row.id_signature);
        l_flg_pref := iif(l_bool, k_yes, k_no);
    
        INSERT INTO prof_signature_h
            (id_prof_signature_h,
             id_professional,
             id_signature,
             flg_type,
             dt_creation,
             id_prof_creation,
             sig_name,
             sig_image,
             sig_filename,
             flg_cud,
             sig_prof_name,
             sig_order_type,
             sig_order_nr,
             sig_address,
             flg_status,
             flg_pref,
             sig_obs,
             id_cancel_reason)
        VALUES
            (seq_prof_signature_h.nextval,
             i_row.id_professional,
             i_row.id_signature,
             i_row.flg_type,
             current_timestamp,
             i_row.id_prof_creation,
             i_row.sig_name,
             i_row.sig_image,
             i_row.sig_filename,
             i_mode,
             i_row.sig_prof_name,
             i_row.sig_order_type,
             i_row.sig_order_nr,
             i_row.sig_address,
             i_row.flg_status,
             l_flg_pref,
             i_row.sig_obs,
             i_row.id_cancel_reason);
    
    END ins_prof_sig_h;

    --************************************
    PROCEDURE del_prof_signature(i_row IN prof_signature%ROWTYPE) IS
    BEGIN
    
        DELETE prof_signature ps
         WHERE ps.id_professional = i_row.id_professional
           AND ps.id_signature = i_row.id_signature;
    
        set_history(k_cud_delete, i_row);
    
    END del_prof_signature;

    PROCEDURE upd_prof_sig(i_row IN prof_signature%ROWTYPE) IS
    BEGIN
    
        UPDATE prof_signature ps
           SET ps.sig_name       = i_row.sig_name,
               ps.sig_image      = i_row.sig_image,
               ps.sig_filename   = i_row.sig_filename,
               ps.sig_prof_name  = i_row.sig_prof_name,
               ps.sig_order_type = i_row.sig_order_type,
               ps.sig_order_nr   = i_row.sig_order_nr,
               ps.sig_address    = i_row.sig_address
         WHERE ps.id_professional = i_row.id_professional
           AND ps.id_signature = i_row.id_signature;
    
        --set_history(k_cud_update, i_row);
    
    END upd_prof_sig;

    --*********************************
    PROCEDURE set_history
    (
        i_cud IN VARCHAR2,
        i_row IN prof_signature%ROWTYPE
    ) IS
    BEGIN
        ins_prof_sig_h(i_cud, i_row);
    END set_history;

    FUNCTION get_prof_signature
    (
        i_prof IN NUMBER,
        i_sig  IN NUMBER
    ) RETURN prof_signature%ROWTYPE IS
        l_row prof_signature%ROWTYPE;
    BEGIN
    
        SELECT *
          INTO l_row
          FROM prof_signature
         WHERE id_signature = i_sig
           AND id_professional = i_prof;
    
        RETURN l_row;
    
    END get_prof_signature;

    PROCEDURE cancel_signature
    (
        i_prof             IN NUMBER,
        i_sig              IN NUMBER,
        i_id_cancel_reason IN NUMBER
    ) IS
        l_row prof_signature%ROWTYPE;
    BEGIN
    
        IF i_sig IS NOT NULL
        THEN
        
            l_row                  := get_prof_signature(i_prof, i_sig);
            l_row.flg_status := k_flg_status_cancel;
            l_row.id_cancel_reason := i_id_cancel_reason;
        
            UPDATE prof_signature ps
               SET flg_status = l_row.flg_status, id_cancel_reason = i_id_cancel_reason
             WHERE id_signature = i_sig
               AND id_professional = i_prof;
        
            set_history(k_cud_update, l_row);
        
        END IF;
    
    END cancel_signature;

    FUNCTION is_record_preferential
    (
        i_prof IN NUMBER,
        i_sig  IN NUMBER
    ) RETURN BOOLEAN IS
        l_count NUMBER;
    BEGIN
    
        SELECT COUNT(*)
          INTO l_count
          FROM prof_active_signature
         WHERE id_professional = i_prof
           AND id_signature = i_sig;
    
        RETURN(l_count > 0);
    
    END is_record_preferential;

END pk_sig_cfg;
