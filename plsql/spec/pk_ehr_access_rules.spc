/*-- Last Change Revision: $Rev: 2028673 $*/
/*-- Last Change by: $Author: mario.fernandes $*/
/*-- Date of last change: $Date: 2022-08-02 18:47:15 +0100 (ter, 02 ago 2022) $*/

CREATE OR REPLACE PACKAGE pk_ehr_access_rules AS
    /**
    * This package encloses all EHR access rules.
    *
    * @since 2008-05-13
    * @author rui.baeta
    */

    /**
    * Rule number 2: Checks weather there is any open episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_ongoing_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 3: Checks weather there is any scheduled episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_scheduled_episode_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 4: Checks weather there is any requested episode for this professional, in his/her environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_requested_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 1 and 5: Checks weather there is authorization from the institution for this professional to access EHR through 'break the glass'.
    * This is a "constant function" as it always returns true. The idea is to customize institution authorization in tables
    * EHR_ACCESS_PROFILE_RULE and/or EHR_ACCESS_PROF_RULE, selecting the intended rule: ckeck_inst_authorization_true or  ckeck_inst_authorization_false.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      always returns true.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_inst_authorization_true
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 1 and 5: Checks weather there is authorization from the institution for this professional to access EHR through 'break the glass'.
    * This is a "constant function" as it always returns false. The idea is to customize institution authorization in tables
    * EHR_ACCESS_PROFILE_RULE and/or EHR_ACCESS_PROF_RULE, selecting the intended rule: ckeck_inst_authorization_true or  ckeck_inst_authorization_false.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      always returns false.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_inst_authorization_false
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 6: Checks weather there is any previous (inactive) episode for this professional.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_previous_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 7: Checks weather there is any scheduled episode for this professional, in the institution environment.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_scheduled_episode_inst
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 8: Checks weather this professional is trying to (legally) reopen an episode.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION ckeck_reopen_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 2: Checks weather if an episode is active and not assigned to any professional instead of the current one
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2009-02-06
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION ckeck_active_episode_with_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 11: Checks weather if an episode is inactive and not assigned to any professional instead of the current one
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2009-02-09
    * @version v2.4.3
    * @author sergio.santos
    */
    FUNCTION ckeck_inactive_episode_with_me
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 13: Checks weather if an episode is signed-off
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2010-10-25
    * @version v2.5.1.2
    * @author sergio.santos
    */
    FUNCTION ckeck_signed_off_episode
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Generic rule: always returns true. Input arguments are ignored.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      true
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION return_true
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 9: Checks if this patient doesnt have clinical information or appointments (episode/schedule)
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * 
    * @param return  flag that tells if the patient doesnt has clinical info (Y - doesnt have
    *                                                                         N - the patient has clinical info)
    *
    * @since 2008-05-28
    * @version v2.4.3
    * @author Sérgio Santos
    */
    FUNCTION ckeck_pat_empty_clin_info
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Generic rule: always returns false. Input arguments are ignored.
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    *                                                                                              N - episode will NOT be reopened - default)
    * @return                      false
    *
    * @since 2008-05-13
    * @version v2.4.3
    * @author rui.baeta
    */
    FUNCTION return_false
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 14: Meaningfull use - Check if the professional has Emergency access on active episodes
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2011-05-07
    * @version v2.6.1.0.1
    * @author sergio.santos
    */
    FUNCTION ckeck_emerg_access
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;

    /**
    * Rule number 15: Meaningfull use - Check if the professional has Emergency access on active episodes (BTG)
    *
    * @param i_lang                language preference
    * @param i_prof                professional identification
    * @param i_id_patient          patient id that this professional wants to access to.
    * @param i_flg_episode_reopen  flag that tells if an episode is to be reopened (used in EDIS) (Y - episode will be reopened
    * @param i_episode             episode id
    *
    * @return                      true if access is granted; false otherwise.
    *
    * @since 2011-05-07
    * @version v2.6.1.0.1
    * @author sergio.santos
    */
    FUNCTION ckeck_emerg_access_phase2
    (
        i_lang               IN LANGUAGE.id_language%TYPE,
        i_prof               IN profissional,
        i_id_patient         IN patient.id_patient%TYPE,
        i_flg_episode_reopen IN VARCHAR2,
        i_id_episode         IN episode.id_episode%TYPE
    ) RETURN BOOLEAN;
    ----------
    g_error        VARCHAR2(32767);
    g_sysdate      DATE;
    g_sysdate_tstz TIMESTAMP WITH TIME ZONE;
    g_found        BOOLEAN;

    g_no  CONSTANT VARCHAR2(1) := pk_ehr_access.g_no;
    g_yes CONSTANT VARCHAR2(1) := pk_ehr_access.g_yes;

    g_flg_ehr_normal    CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_n;
    g_flg_ehr_ehr       CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_e;
    g_flg_ehr_scheduled CONSTANT VARCHAR2(1) := pk_visit.g_flg_ehr_s;

    g_epis_active    CONSTANT episode.flg_status%TYPE := 'A';
    g_epis_cancelled CONSTANT episode.flg_status%TYPE := 'C';
    g_epis_inactive  CONSTANT episode.flg_status%TYPE := 'I';
    g_epis_pending   CONSTANT episode.flg_status%TYPE := 'P';
END pk_ehr_access_rules;
/
