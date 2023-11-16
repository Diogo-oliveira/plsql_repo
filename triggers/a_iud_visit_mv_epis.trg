CREATE OR REPLACE
TRIGGER A_IUD_VISIT_MV_EPIS
 AFTER INSERT OR UPDATE OR DELETE
 ON VISIT
BEGIN
    pk_episode.update_mv_episodes();
EXCEPTION
    WHEN OTHERS THEN
        pk_alertlog.log_error(SQLERRM, 'A_IUD_VISIT_MV_EPIS');
END;
/

-- cmf 16-11-2009
drop trigger A_IUD_VISIT_MV_EPIS;