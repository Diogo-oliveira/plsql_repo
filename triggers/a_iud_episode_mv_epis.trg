CREATE OR REPLACE
TRIGGER A_IUD_EPISODE_MV_EPIS
 AFTER INSERT OR UPDATE OR DELETE
 ON EPISODE
BEGIN
    pk_episode.update_mv_episodes();
EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error(SQLERRM, 'A_IUD_EPISODE_MV_EPIS');
END;
/


-- cmf 16-11-2009
drop trigger A_IUD_EPISODE_MV_EPIS;