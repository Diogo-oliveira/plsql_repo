/*-- Last Change Revision: $Rev: 2028973 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:49:03 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_sev_scores_constant IS

    -- Author  : JOSE.SILVA
    -- Created : 08-09-2010
    -- Purpose : This package should have all constants used in Severity Scores functionality.

    -- Status
    g_flg_status_a CONSTANT epis_mtos_score.flg_status%TYPE := 'A';
    g_flg_status_o CONSTANT epis_mtos_score.flg_status%TYPE := 'O';
    g_flg_status_c CONSTANT epis_mtos_score.flg_status%TYPE := 'C';
    -- Score ID's
    g_id_score_gcs            CONSTANT mtos_score.id_mtos_score%TYPE := 1;
    g_id_score_pts            CONSTANT mtos_score.id_mtos_score%TYPE := 2;
    g_id_score_rts            CONSTANT mtos_score.id_mtos_score%TYPE := 3;
    g_id_score_iss            CONSTANT mtos_score.id_mtos_score%TYPE := 4;
    g_id_score_triss          CONSTANT mtos_score.id_mtos_score%TYPE := 5;
    g_id_score_crib           CONSTANT mtos_score.id_mtos_score%TYPE := 8;
    g_id_score_saps2          CONSTANT mtos_score.id_mtos_score%TYPE := 9;
    g_id_score_snap           CONSTANT mtos_score.id_mtos_score%TYPE := 10;
    g_id_score_sofa           CONSTANT mtos_score.id_mtos_score%TYPE := 11;
    g_id_score_tiss_28        CONSTANT mtos_score.id_mtos_score%TYPE := 12;
    g_id_score_tiss_76        CONSTANT mtos_score.id_mtos_score%TYPE := 13;
    g_id_score_apache2        CONSTANT mtos_score.id_mtos_score%TYPE := 14;
    g_id_score_apache3        CONSTANT mtos_score.id_mtos_score%TYPE := 15;
    g_id_score_aldrete        CONSTANT mtos_score.id_mtos_score%TYPE := 16;
    g_id_score_crib2          CONSTANT mtos_score.id_mtos_score%TYPE := 17;
    g_id_score_o2grad         CONSTANT mtos_score.id_mtos_score%TYPE := 20;
    g_id_score_oxigen         CONSTANT mtos_score.id_mtos_score%TYPE := 25;
    g_id_score_curb65         CONSTANT mtos_score.id_mtos_score%TYPE := 18;
    g_id_score_curb65_1       CONSTANT mtos_score.id_mtos_score%TYPE := 30;
    g_id_score_isstw          CONSTANT mtos_score.id_mtos_score%TYPE := 37;
    g_id_score_tw_head        CONSTANT mtos_score.id_mtos_score%TYPE := 38;
    g_id_score_tw_face        CONSTANT mtos_score.id_mtos_score%TYPE := 39;
    g_id_score_tw_chest       CONSTANT mtos_score.id_mtos_score%TYPE := 40;
    g_id_score_tw_abdomen     CONSTANT mtos_score.id_mtos_score%TYPE := 41;
    g_id_score_tw_extremities CONSTANT mtos_score.id_mtos_score%TYPE := 42;
    g_id_score_tw_external    CONSTANT mtos_score.id_mtos_score%TYPE := 43;
    g_id_score_tw_dao         CONSTANT mtos_score.id_mtos_score%TYPE := 44;
    g_id_score_si_it_is       CONSTANT mtos_score.id_mtos_score%TYPE := 45;
    g_id_score_prism          CONSTANT mtos_score.id_mtos_score%TYPE := 46;
    g_id_score_sofa_tw        CONSTANT mtos_score.id_mtos_score%TYPE := 47;
    g_id_score_vte            CONSTANT mtos_score.id_mtos_score%TYPE := 49;
    g_id_score_timi           CONSTANT mtos_score.id_mtos_score%TYPE := '48';
    g_id_score_stemi          CONSTANT mtos_score.id_mtos_score%TYPE := '51';
    g_id_score_nstemi         CONSTANT mtos_score.id_mtos_score%TYPE := '50';
    g_id_score_apache_tw      CONSTANT mtos_score.id_mtos_score%TYPE := '52';

    -- Score types
    g_flg_score_gcs        CONSTANT mtos_score.flg_score_type%TYPE := 'GCS';
    g_flg_score_pts        CONSTANT mtos_score.flg_score_type%TYPE := 'PTS';
    g_flg_score_rts        CONSTANT mtos_score.flg_score_type%TYPE := 'RTS';
    g_flg_score_iss        CONSTANT mtos_score.flg_score_type%TYPE := 'ISS';
    g_flg_score_isstw      CONSTANT mtos_score.flg_score_type%TYPE := 'ISSTW';
    g_flg_score_triss      CONSTANT mtos_score.flg_score_type%TYPE := 'TRISS';
    g_flg_score_tiss_28    CONSTANT mtos_score.flg_score_type%TYPE := 'TISS_28';
    g_flg_score_tiss_76    CONSTANT mtos_score.flg_score_type%TYPE := 'TISS_76';
    g_flg_score_sofa       CONSTANT mtos_score.flg_score_type%TYPE := 'SOFA';
    g_flg_score_aldrete    CONSTANT mtos_score.flg_score_type%TYPE := 'ALDRETE';
    g_flg_score_crib       CONSTANT mtos_score.flg_score_type%TYPE := 'CRIB';
    g_flg_score_crib2      CONSTANT mtos_score.flg_score_type%TYPE := 'CRIB_II';
    g_flg_score_oi         CONSTANT mtos_score.flg_score_type%TYPE := 'OI';
    g_flg_score_snap       CONSTANT mtos_score.flg_score_type%TYPE := 'SNAP';
    g_flg_score_saps2      CONSTANT mtos_score.flg_score_type%TYPE := 'SAPS_II';
    g_flg_score_o2grd      CONSTANT mtos_score.flg_score_type%TYPE := 'O2_GRD';
    g_flg_score_apache2    CONSTANT mtos_score.flg_score_type%TYPE := 'APACHE_II';
    g_flg_score_apache3    CONSTANT mtos_score.flg_score_type%TYPE := 'APACHE_III';
    g_flg_score_curb65     CONSTANT mtos_score.flg_score_type%TYPE := 'CURB_65';
    g_flg_score_curb65_1   CONSTANT mtos_score.flg_score_type%TYPE := 'CURB_65_I';
    g_flg_score_news       CONSTANT mtos_score.flg_score_type%TYPE := 'NEWS';
    g_flg_score_parkland   CONSTANT mtos_score.flg_score_type%TYPE := 'PARKLAND';
    g_flg_score_head_tw    CONSTANT mtos_score.flg_score_type%TYPE := 'HEAD_TW';
    g_flg_score_face_tw    CONSTANT mtos_score.flg_score_type%TYPE := 'FACE';
    g_flg_score_chest_tw   CONSTANT mtos_score.flg_score_type%TYPE := 'CHEST_TW';
    g_flg_score_abdomen_tw CONSTANT mtos_score.flg_score_type%TYPE := 'ABDOMEN_TW';
    g_flg_score_extre_tw   CONSTANT mtos_score.flg_score_type%TYPE := 'EXTRE_TW';
    g_flg_score_exter_tw   CONSTANT mtos_score.flg_score_type%TYPE := 'EXTER_TW';
    g_flg_score_doa_tw     CONSTANT mtos_score.flg_score_type%TYPE := 'DOA_TW';
    g_flg_score_si_it_is   CONSTANT mtos_score.flg_score_type%TYPE := 'SI_IT_IS';
    g_flg_score_prism      CONSTANT mtos_score.flg_score_type%TYPE := 'PRISM';
    g_flg_score_sofa_tw    CONSTANT mtos_score.flg_score_type%TYPE := 'SOFA_TW';
    g_flg_score_vte        CONSTANT mtos_score.flg_score_type%TYPE := 'VTE';
    g_flg_score_timi       CONSTANT mtos_score.flg_score_type%TYPE := 'TIMI';
    g_flg_score_stemi      CONSTANT mtos_score.flg_score_type%TYPE := 'STEMI';
    g_flg_score_nstemi     CONSTANT mtos_score.flg_score_type%TYPE := 'UA_STEMI';
    g_flg_score_apache_tw  CONSTANT mtos_score.flg_score_type%TYPE := 'APACHE_TW';

    -- Param types
    g_param_type_age           CONSTANT mtos_param.internal_name%TYPE := 'PAT_AGE';
    g_param_type_gcs_eyes      CONSTANT mtos_param.internal_name%TYPE := 'G_EYES';
    g_param_type_gcs_verbal    CONSTANT mtos_param.internal_name%TYPE := 'G_VERBAL';
    g_param_type_gcs_motor     CONSTANT mtos_param.internal_name%TYPE := 'G_MOTOR';
    g_param_type_rts_total     CONSTANT mtos_param.internal_name%TYPE := 'RTS_TOTAL';
    g_param_type_o2grd_paco2   CONSTANT mtos_param.internal_name%TYPE := 'PACO2_O2GRADIENT';
    g_param_type_o2grd_pao2    CONSTANT mtos_param.internal_name%TYPE := 'PAO2_O2GRADIENT';
    g_param_type_o2grd_fio2    CONSTANT mtos_param.internal_name%TYPE := 'FIO2_O2GRADIENT';
    g_param_type_apache2_oxi   CONSTANT mtos_param.internal_name%TYPE := 'FIO2_O2_APACHE_II';
    g_param_type_oi_paw        CONSTANT mtos_param.internal_name%TYPE := 'PRESSURE_OI';
    g_param_type_oi_pao2       CONSTANT mtos_param.internal_name%TYPE := 'PAO2_OI';
    g_param_type_oi_fio2       CONSTANT mtos_param.internal_name%TYPE := 'FIO2_OI';
    g_param_type_snap_oi       CONSTANT mtos_param.internal_name%TYPE := 'OI_TOTAL';
    g_param_type_tiss28_total  CONSTANT mtos_param.internal_name%TYPE := 'TISS_28_TOTAL';
    g_param_type_tiss28_nc     CONSTANT mtos_param.internal_name%TYPE := 'TISS_28_NURSE_CARE';
    g_param_type_triss_total_p CONSTANT mtos_param.internal_name%TYPE := 'TRISS_TOTAL_P';
    g_param_type_triss_total_b CONSTANT mtos_param.internal_name%TYPE := 'TRISS_TOTAL_B';
    g_param_type_tiss76_total  CONSTANT mtos_param.internal_name%TYPE := 'TISS_76_TOTAL';
    g_param_type_aldrete_total CONSTANT mtos_param.internal_name%TYPE := 'ALDRETE_TOTAL';
    g_param_type_crib2_dr      CONSTANT mtos_param.internal_name%TYPE := 'DEATH_RATE_CRIB_II';
    g_param_type_apache3_eyes  CONSTANT mtos_param.internal_name%TYPE := 'EYES_OPEN_APACHE_III';
    g_param_type_apache3_verb  CONSTANT mtos_param.internal_name%TYPE := 'VERBAL_APACHE_III';
    g_param_type_apache3_motor CONSTANT mtos_param.internal_name%TYPE := 'MOTOR_APACHE_III';
    g_param_type_apache3_pco2  CONSTANT mtos_param.internal_name%TYPE := 'PCO2_APACHE_III';
    g_param_type_apache3_ph    CONSTANT mtos_param.internal_name%TYPE := 'PH_APACHE_III';
    g_param_type_apache3_temp  CONSTANT mtos_param.internal_name%TYPE := 'TEMPERATURE_APACHE_III';
    g_param_type_apache2_dr    CONSTANT mtos_param.internal_name%TYPE := 'DEATH_RATE_APACHE_II';
    g_param_type_cur65_total   CONSTANT mtos_param.internal_name%TYPE := 'TOTAL_CURB_65';
    g_param_type_cur65_total_1 CONSTANT mtos_param.internal_name%TYPE := 'TOTAL_CURB_65_I';
    g_param_type_news          CONSTANT mtos_param.internal_name%TYPE := 'TOTAL_NEWS_SCORE';
    g_param_type_msts          CONSTANT mtos_param.internal_name%TYPE := 'MSTS';
    g_param_type_sofa_tw_mr    CONSTANT mtos_param.internal_name%TYPE := 'SOFA_MORTALITY_RATE';
    g_param_type_apache_tw     CONSTANT mtos_param.internal_name%TYPE := 'APACHE_RISK';
    g_param_apache_tw_total    CONSTANT mtos_param.internal_name%TYPE := 'APACHE_TOTAL';
    g_param_type_timi_risk     CONSTANT mtos_param.internal_name%TYPE := 'STEMI_TIMI_RISK';

    -- Fill type
    g_flg_fill_type_m CONSTANT mtos_param.flg_fill_type%TYPE := 'M'; -- Multichoice
    g_flg_fill_type_n CONSTANT mtos_param.flg_fill_type%TYPE := 'N'; -- Number
    g_flg_fill_type_l CONSTANT mtos_param.flg_fill_type%TYPE := 'L'; -- Locked, not editable
    g_flg_fill_type_t CONSTANT mtos_param.flg_fill_type%TYPE := 'T'; -- Total score
    g_flg_fill_type_r CONSTANT mtos_param.flg_fill_type%TYPE := 'R'; -- Radio button
    g_flg_fill_type_p CONSTANT mtos_param.flg_fill_type%TYPE := 'P'; -- SCALES (PAIN) button
    g_flg_fill_type_s CONSTANT mtos_param.flg_fill_type%TYPE := 'S'; -- Multichoice with multiple selection
    g_flg_fill_type_f CONSTANT mtos_param.flg_fill_type%TYPE := 'F'; -- Free text
    --Scores help
    g_sev_score_help_list    CONSTANT VARCHAR2(1 CHAR) := 'L';
    g_sev_score_help_edition CONSTANT VARCHAR2(1 CHAR) := 'E';
    -- ISS Maximum score and values
    g_iss_max_score_value CONSTANT NUMBER(6) := 6;
    g_iss_max_total_value CONSTANT NUMBER(6) := 75;
    -- TRISS / ANNOUNCED ARRIVAL
    g_parameter_bz           CONSTANT mtos_multiplier.flg_parameter%TYPE := 'BZ';
    g_parameter_ai           CONSTANT mtos_multiplier.flg_parameter%TYPE := 'AI';
    g_parameter_vs           CONSTANT mtos_multiplier.flg_parameter%TYPE := 'VS';
    g_multiplier_normal      CONSTANT mtos_multiplier.flg_multiplier_type%TYPE := 'N';
    g_multiplier_blunt       CONSTANT mtos_multiplier.flg_multiplier_type%TYPE := 'B';
    g_multiplier_penetrating CONSTANT mtos_multiplier.flg_multiplier_type%TYPE := 'P';
    g_vital_sign_info_value  CONSTANT VARCHAR2(1 CHAR) := 'V';
    g_vital_sign_info_um     CONSTANT VARCHAR2(1 CHAR) := 'U';
    --TISS_28
    g_nurse_care_um         CONSTANT unit_measure.id_unit_measure%TYPE := 7712;
    g_nurse_care_multiplier CONSTANT NUMBER := 10.6;
    -- CRIB II
    g_parameter_cz   CONSTANT mtos_multiplier.flg_parameter%TYPE := 'CZ';
    g_id_crib2_total CONSTANT mtos_param.id_mtos_param%TYPE := 575;
    g_pat_gender_m   CONSTANT patient.gender%TYPE := 'M';
    g_pat_gender_f   CONSTANT patient.gender%TYPE := 'F';
    --APACHE II
    g_id_apache2_temp      CONSTANT mtos_param.id_mtos_param%TYPE := 405;
    g_id_apache2_fio2      CONSTANT mtos_param.id_mtos_param%TYPE := 409;
    g_id_apache2_total     CONSTANT mtos_param.id_mtos_param%TYPE := 422;
    g_id_apache2_o2gr_fio2 CONSTANT mtos_param.id_mtos_param%TYPE := 425;
    g_parameter_dz         CONSTANT mtos_multiplier.flg_parameter%TYPE := 'DZ';
    g_o2grd_fio2_1         CONSTANT mtos_param.id_mtos_param%TYPE := 583;
    g_o2grd_fio2_2         CONSTANT mtos_param.id_mtos_param%TYPE := 584;
    g_o2grd_fio2_3         CONSTANT mtos_param.id_mtos_param%TYPE := 585;
    g_o2grd_fio2_4         CONSTANT mtos_param.id_mtos_param%TYPE := 586;
    g_o2grd_fio2_5         CONSTANT mtos_param.id_mtos_param%TYPE := 587;
    g_o2grd_fio2_6         CONSTANT mtos_param.id_mtos_param%TYPE := 588;
    g_o2grd_fio2_7         CONSTANT mtos_param.id_mtos_param%TYPE := 589;
    g_o2grd_fio2_8         CONSTANT mtos_param.id_mtos_param%TYPE := 590;
    --APACHE III
    g_id_eyes_open                CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1030;
    g_id_motor_obeys_verbal       CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1036;
    g_id_motor_localizes_pain     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1037;
    g_id_motor_flexion_withdrawal CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1038;
    g_id_motor_no_response        CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1039;
    g_id_verbal_oriented          CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1032;
    g_id_verbal_confused          CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1033;
    g_id_verbal_inapp_words       CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1034;
    g_id_verbal_no_response       CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1035;
    g_vs_ph                       CONSTANT vital_sign.id_vital_sign%TYPE := 16;
    --SI_IT_IS
    g_mtos_group_sev_illness   CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 15;
    g_mtos_group_int_treatment CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 16;
    g_mtos_group_int_service   CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 17;
    --PRISM
    g_param_age        CONSTANT mtos_param.id_mtos_param%TYPE := 1017;
    g_param_neonate    CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1774;
    g_param_infant     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1775;
    g_param_child      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1776;
    g_param_adolescent CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1777;
    g_age_neonate      CONSTANT vital_sign_unit_measure.age_min%TYPE := 1; --1 MONTH
    g_age_infant       CONSTANT vital_sign_unit_measure.age_min%TYPE := 12; --12 MONTHS
    g_age_child        CONSTANT vital_sign_unit_measure.age_min%TYPE := 144; --144 MONTHS 
    -- SOFA_TW
    g_sofa_tw_respiratory    CONSTANT mtos_param.id_mtos_param%TYPE := 1036;
    g_sofa_tw_glasgow        CONSTANT mtos_param.id_mtos_param%TYPE := 1037;
    g_sofa_tw_liver          CONSTANT mtos_param.id_mtos_param%TYPE := 1039;
    g_sofa_tw_coagulation    CONSTANT mtos_param.id_mtos_param%TYPE := 1040;
    g_sofa_tw_renal          CONSTANT mtos_param.id_mtos_param%TYPE := 1041;
    g_sofa_tw_fio2_um        CONSTANT vital_sign_read.id_unit_measure%TYPE := 9;
    g_sofa_tw_pao2_um        CONSTANT vital_sign_read.id_unit_measure%TYPE := 1149;
    g_sofa_tw_liver_um       CONSTANT vital_sign_read.id_unit_measure%TYPE := 76123;
    g_sofa_tw_coagulation_um CONSTANT vital_sign_read.id_unit_measure%TYPE := 23501;
    g_sofa_tw_renal_um       CONSTANT vital_sign_read.id_unit_measure%TYPE := 76123;
    --
    g_sofa_tw_respiratory_1 CONSTANT mtos_param.id_mtos_param%TYPE := 1818;
    g_sofa_tw_respiratory_2 CONSTANT mtos_param.id_mtos_param%TYPE := 1819;
    g_sofa_tw_respiratory_3 CONSTANT mtos_param.id_mtos_param%TYPE := 1820;
    g_sofa_tw_respiratory_4 CONSTANT mtos_param.id_mtos_param%TYPE := 1821;
    g_sofa_tw_respiratory_5 CONSTANT mtos_param.id_mtos_param%TYPE := 1822;
    --
    g_sofa_tw_glasgow_1 CONSTANT mtos_param.id_mtos_param%TYPE := 1823;
    g_sofa_tw_glasgow_2 CONSTANT mtos_param.id_mtos_param%TYPE := 1824;
    g_sofa_tw_glasgow_3 CONSTANT mtos_param.id_mtos_param%TYPE := 1825;
    g_sofa_tw_glasgow_4 CONSTANT mtos_param.id_mtos_param%TYPE := 1826;
    g_sofa_tw_glasgow_5 CONSTANT mtos_param.id_mtos_param%TYPE := 1827;
    --
    g_sofa_tw_liver_1 CONSTANT mtos_param.id_mtos_param%TYPE := 1833;
    g_sofa_tw_liver_2 CONSTANT mtos_param.id_mtos_param%TYPE := 1834;
    g_sofa_tw_liver_3 CONSTANT mtos_param.id_mtos_param%TYPE := 1835;
    g_sofa_tw_liver_4 CONSTANT mtos_param.id_mtos_param%TYPE := 1836;
    g_sofa_tw_liver_5 CONSTANT mtos_param.id_mtos_param%TYPE := 1837;
    --
    g_sofa_tw_coagulation_1 CONSTANT mtos_param.id_mtos_param%TYPE := 1838;
    g_sofa_tw_coagulation_2 CONSTANT mtos_param.id_mtos_param%TYPE := 1839;
    g_sofa_tw_coagulation_3 CONSTANT mtos_param.id_mtos_param%TYPE := 1840;
    g_sofa_tw_coagulation_4 CONSTANT mtos_param.id_mtos_param%TYPE := 1841;
    g_sofa_tw_coagulation_5 CONSTANT mtos_param.id_mtos_param%TYPE := 1842;
    --
    g_sofa_tw_renal_1 CONSTANT mtos_param.id_mtos_param%TYPE := 1843;
    g_sofa_tw_renal_2 CONSTANT mtos_param.id_mtos_param%TYPE := 1844;
    g_sofa_tw_renal_3 CONSTANT mtos_param.id_mtos_param%TYPE := 1845;
    g_sofa_tw_renal_4 CONSTANT mtos_param.id_mtos_param%TYPE := 1846;
    g_sofa_tw_renal_5 CONSTANT mtos_param.id_mtos_param%TYPE := 1847;
    --VTE
    g_vte_param_age       CONSTANT mtos_param.id_mtos_param%TYPE := 1048;
    g_vte_age_over_70     CONSTANT mtos_param.id_mtos_param%TYPE := 1858;
    g_vte_age_under_70    CONSTANT mtos_param.id_mtos_param%TYPE := 1859;
    g_vte_param_bmi       CONSTANT mtos_param.id_mtos_param%TYPE := 1052;
    g_vte_bmi_ref_value   CONSTANT vital_sign_read.value%TYPE := 30;
    g_vte_bmi_ref_um      CONSTANT vital_sign_read.id_unit_measure%TYPE := 10574;
    g_vte_val_bmi_yes     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1866;
    g_vte_val_bmi_no      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1867;
    g_vte_param_platelets CONSTANT mtos_param.id_mtos_param%TYPE := 1055;
    g_vte_plat_ref_value  CONSTANT vital_sign_read.value%TYPE := 50000;
    g_vte_plat_ref_um     CONSTANT vital_sign_read.id_unit_measure%TYPE := 23501;
    g_vte_val_plat_yes    CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1872;
    g_vte_val_plat_no     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 1873;
    --
    -- TIMI
    -- stemi
    g_stemi_param_age_64_74      CONSTANT mtos_param.id_mtos_param%TYPE := 1095;
    g_stemi_param_age_75         CONSTANT mtos_param.id_mtos_param%TYPE := 1096;
    g_stemi_param_diabetes       CONSTANT mtos_param.id_mtos_param%TYPE := 1097;
    g_stemi_param_systolic       CONSTANT mtos_param.id_mtos_param%TYPE := 1098;
    g_stemi_param_heart_rate     CONSTANT mtos_param.id_mtos_param%TYPE := 1099;
    g_stemi_param_killip         CONSTANT mtos_param.id_mtos_param%TYPE := 1100;
    g_stemi_param_weight         CONSTANT mtos_param.id_mtos_param%TYPE := 1101;
    g_stemi_value_yes_64_74      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2032;
    g_stemi_value_no_64_74       CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2033;
    g_stemi_value_yes_75         CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2034;
    g_stemi_value_no_75          CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2035;
    g_stemi_value_yes_diabetes   CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2036;
    g_stemi_value_no_diabetes    CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2037;
    g_stemi_value_yes_systolic   CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2038;
    g_stemi_value_no_systolic    CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2039;
    g_stemi_value_yes_heart_rate CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2040;
    g_stemi_value_no_heart_rate  CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2041;
    g_stemi_value_yes_killip     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2042;
    g_stemi_value_no_killip      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2043;
    g_stemi_value_yes_weight     CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2044;
    g_stemi_value_no_weight      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2045;
    --
    --APACHE_TW
    g_mtos_group_oxigenation      CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 40;
    g_mtos_group_physio           CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 34;
    g_mtos_group_chronic          CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 42;
    g_mtos_group_apache_sr        CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 41;
    g_mtos_group_apache_diagnosis CONSTANT mtos_score_group.id_mtos_score_group%TYPE := 43;
    g_flg_latest                  CONSTANT VARCHAR2(1) := 'L';
    g_flg_latest_harvest          CONSTANT VARCHAR2(24) := 'L_HARVEST';
    g_apache_age                  CONSTANT mtos_param.id_mtos_param%TYPE := 1067;
    g_apache_sisto_min            CONSTANT mtos_param.id_mtos_param%TYPE := 1111;
    g_apache_sisto_max            CONSTANT mtos_param.id_mtos_param%TYPE := 1113;
    g_apache_diast_min            CONSTANT mtos_param.id_mtos_param%TYPE := 1109;
    g_apache_diast_max            CONSTANT mtos_param.id_mtos_param%TYPE := 1112;
    g_apache_gcs                  CONSTANT mtos_param.id_mtos_param%TYPE := 1108;
    g_apache_fio2_1               CONSTANT mtos_param.id_mtos_param%TYPE := 1114;
    g_apache_fio2_2               CONSTANT mtos_param.id_mtos_param%TYPE := 1117;
    g_apache_fio2_3               CONSTANT mtos_param.id_mtos_param%TYPE := 1120;
    g_apache_fio2_4               CONSTANT mtos_param.id_mtos_param%TYPE := 1123;
    g_apache_fio2_5               CONSTANT mtos_param.id_mtos_param%TYPE := 1126;
    g_apache_diagnosis            CONSTANT mtos_param.id_mtos_param%TYPE := 1139;	
    g_apache_planned_surgery      CONSTANT mtos_param_value.id_mtos_param_value%TYPE := 2078;
    --
    g_format_decimal1_mask CONSTANT VARCHAR2(30) := '990D9';
    g_format_decimal3_mask CONSTANT VARCHAR2(30) := '990D000';
    -- Score relations
    g_score_rel_parent CONSTANT mtos_score_relation.flg_relation%TYPE := 'P';
    --
    g_trauma_alert CONSTANT sys_alert.id_sys_alert%TYPE := 65;
    -- Patient age in months
    g_age_months CONSTANT VARCHAR2(10 CHAR) := 'MONTHS';
    -- Parkland unit measure base
    g_id_unit_measure_kg CONSTANT unit_measure.id_unit_measure%TYPE := 10;

    g_flg_param_task_vital_sign CONSTANT mtos_param_task.flg_param_task_type%TYPE := 'VS';
    g_task_analysis_parameter   CONSTANT mtos_param_task.flg_param_task_type%TYPE := 'AP';

    g_condition_max      CONSTANT VARCHAR2(3) := 'MAX';
    g_condition_max_harvest CONSTANT VARCHAR2(24) := 'MAX_HARVEST';
    g_condition_min      CONSTANT VARCHAR2(3) := 'MIN';
    g_condition_min_harvest CONSTANT VARCHAR2(24) := 'MIN_HARVEST';
	g_condition_most_recent CONSTANT VARCHAR2(3) := 'REC';	
    g_greater_than       CONSTANT VARCHAR2(2) := '>';
    g_greater_equal_than CONSTANT VARCHAR2(2) := '>=';
    g_less_equal_than    CONSTANT VARCHAR2(2) := '<=';
    g_less_than          CONSTANT VARCHAR2(2) := '<';

    /* Package name */
    g_package_name  VARCHAR2(32);
    g_package_owner VARCHAR2(32);

END pk_sev_scores_constant;
/
